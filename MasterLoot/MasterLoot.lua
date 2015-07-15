-----------------------------------------------------------------------------------------------
-- Client Lua Script for Masterloot
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"
require "GroupLib"
require "Item"
require "GameLib"

local MasterLoot = {}

local ktClassToIcon =
{
	[GameLib.CodeEnumClass.Medic]       	= "Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Esper]       	= "Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Warrior]     	= "Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Stalker]     	= "Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Engineer]    	= "Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger]  	= "Icon_Windows_UI_CRB_Spellslinger",
}

local karItemColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

function MasterLoot:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.tMasterLootItemWindows = {}
	o.tMasterLootLooterWindows = {}
	o.tLooterLootWindows = {}
	
	return o
end

function MasterLoot:Init()
	Apollo.RegisterAddon(self)
end

function MasterLoot:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MasterLoot.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MasterLoot:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", 		"OnWindowManagementReady", self)

	Apollo.RegisterEventHandler("MasterLootUpdate",				"OnMasterLootUpdate", self)
	Apollo.RegisterEventHandler("LootAssigned",					"OnLootAssigned", self)

	Apollo.RegisterEventHandler("Group_Left",					"OnGroup_Left", self) -- When you leave the group

	Apollo.RegisterEventHandler("GenericEvent_ToggleGroupBag", 	"OnToggleGroupBag", self)

	-- Master Looter Window
	self.wndMasterLoot = Apollo.LoadForm(self.xmlDoc, "MasterLootWindow", nil, self)
	self.wndMasterLoot:SetSizingMinimum(550, 310)
	if self.locSavedMasterWindowLoc then
		self.wndMasterLoot:MoveToLocation(self.locSavedMasterWindowLoc)
	end
	self.wndMasterLoot_ItemList = self.wndMasterLoot:FindChild("ItemList")
	self.wndMasterLoot_LooterList = self.wndMasterLoot:FindChild("LooterList")
	self.wndMasterLoot:Show(false)

	-- Looter Window
	self.wndLooter = Apollo.LoadForm(self.xmlDoc, "LooterWindow", nil, self)
	if self.locSavedLooterWindowLoc then
		self.wndLooter:MoveToLocation(self.locSavedLooterWindowLoc)
	end
	self.wndLooter_ItemList = self.wndLooter:FindChild("ItemList")
	self.wndLooter:Show(false)

	self.tOld_MasterLootList = {}
end

function MasterLoot:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMasterLoot, strName = Apollo.GetString("Group_MasterLoot"), nSaveVersion = 1 })
end

function MasterLoot:OnToggleGroupBag()
	self:OnMasterLootUpdate()
end

----------------------------

function MasterLoot:OnMasterLootUpdate()
	local tMasterLoot = GameLib.GetMasterLoot()

	local tMasterLootItemList = {}
	local tLooterItemList = {}

	-- Break items out into MasterLooter and Looter lists (which UI displays them)
	for idxNewItem, tCurNewItem in pairs(tMasterLoot) do
			table.insert(tCurNewItem.bIsMaster and tMasterLootItemList or tLooterItemList, tCurNewItem)
	end

	-- update lists with items
	if next(tMasterLootItemList) ~= nil then
		self:RefreshMasterLootItemList(tMasterLootItemList)
		if not self.wndMasterLoot:IsShown() then
			self.wndMasterLoot:Show(true)
		end
	end
	if next(tLooterItemList) ~= nil then
		self:RefreshLooterItemList(tLooterItemList)
		if not self.wndLooter:IsShown() then
			self.wndLooter:Show(true)
		end
	end
	
	-- hide empty windows
	if next(tMasterLootItemList) == nil then
		if self.wndMasterLoot:IsShown() then
			self.locSavedMasterWindowLoc = self.wndMasterLoot:GetLocation()
			self.wndMasterLoot:Show(false)
		end
	end
	
	if next(tLooterItemList) == nil then
		if self.wndLooter:IsShown() then
			self.locSavedLooterWindowLoc = self.wndLooter:GetLocation()
			self.wndLooter:Show(false)
		end
	end
end

function MasterLoot:RefreshMasterLootItemList(tMasterLootItemList)

	local nVPos = self.wndMasterLoot_ItemList:GetVScrollPos()
	local tIndexedList = {}
	
	for idx, tItem in ipairs (tMasterLootItemList) do
		tIndexedList[tItem.nLootId] = tItem
		
		local wndCurrentItem = self.tMasterLootItemWindows[tItem.nLootId]
		if wndCurrentItem == nil or not wndCurrentItem:IsValid() then
			wndCurrentItem = Apollo.LoadForm(self.xmlDoc, "ItemButton", self.wndMasterLoot_ItemList, self)
			self.tMasterLootItemWindows[tItem.nLootId] = wndCurrentItem
			
			wndCurrentItem:FindChild("ItemIcon"):GetWindowSubclass():SetItem(tItem.itemDrop)
			wndCurrentItem:FindChild("ItemName"):SetText(tItem.itemDrop:GetName())
			wndCurrentItem:FindChild("ItemName"):SetTextColor(karItemColors[tItem.itemDrop:GetItemQuality()])
			
			-- new item(s) show the window
			self.wndMasterLoot:Show(true)
		end
		
		wndCurrentItem:SetData(tItem)
		
		if wndCurrentItem:IsChecked() then
			self:RefreshMasterLootLooterList(tItem)
		end
	end
	
	for idx, wndItem in pairs(self.wndMasterLoot_ItemList:GetChildren()) do
		local tItem = wndItem:GetData()
		if tIndexedList[tItem.nLootId] ==  nil then
			wndItem:Destroy()
			self.tMasterLootItemWindows[tItem.nLootId] = nil
		end
	end

	self.wndMasterLoot_ItemList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndMasterLoot_ItemList:SetVScrollPos(nVPos)
	
end

function MasterLoot:RefreshMasterLootLooterList(tItem)
	if tItem == nil then
		self.wndMasterLoot:FindChild("Assignment"):Enable(false)
		for idx, wndLooter in pairs(self.wndMasterLoot_LooterList:GetChildren()) do
			wndLooter:Show(false)
		end
		return
	end
	
	local tValidLooters = {}
	
	for idx, unitLooter in pairs(tItem.tLooters) do
		local strName = unitLooter:GetName()
		tValidLooters[strName] = true
	
		local wndCurrentLooter = self.tMasterLootLooterWindows[strName]
		if wndCurrentLooter == nil or not wndCurrentLooter:IsValid() then
			wndCurrentLooter = Apollo.LoadForm(self.xmlDoc, "CharacterButton", self.wndMasterLoot_LooterList, self)
			wndCurrentLooter:SetName(strName)
			self.tMasterLootLooterWindows[strName] = wndCurrentLooter
		end
		
		wndCurrentLooter:Show(true)
		wndCurrentLooter:FindChild("CharacterName"):SetText(strName)
		wndCurrentLooter:FindChild("CharacterLevel"):SetText(unitLooter:GetBasicStats().nLevel)
		wndCurrentLooter:FindChild("ClassIcon"):SetSprite(ktClassToIcon[unitLooter:GetClassId()])
		wndCurrentLooter:Enable(true)
		
		local tData = { ["unitLooter"] = unitLooter, ["tItem"] = tItem }
		wndCurrentLooter:SetData(tData)
		
		if wndCurrentLooter:IsChecked() then
			self.wndMasterLoot:FindChild("Assignment"):SetData(tData)
			self.wndMasterLoot:FindChild("Assignment"):Enable(true)
		end
	end

	-- get out of range people
	if tItem.tLootersOutOfRange and next(tItem.tLootersOutOfRange) then
		for idx, strLooterOOR in pairs(tItem.tLootersOutOfRange) do
			tValidLooters[strLooterOOR] = true
		
			local wndCurrentLooter = self.tMasterLootLooterWindows[strLooterOOR]
			if wndCurrentLooter == nil or not wndCurrentLooter:IsValid() then
				wndCurrentLooter = Apollo.LoadForm(self.xmlDoc, "CharacterButton", self.wndMasterLoot_LooterList, self)
				wndCurrentLooter:SetName(strLooterOOR)
				self.tMasterLootLooterWindows[strLooterOOR] = wndCurrentLooter
			end
			
			wndCurrentLooter:Show(true)
			wndCurrentLooter:FindChild("CharacterName"):SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), strLooterOOR))
			wndCurrentLooter:FindChild("CharacterLevel"):SetText(nil)
			wndCurrentLooter:FindChild("ClassIcon"):SetSprite("CRB_GroupFrame:sprGroup_Disconnected")
			wndCurrentLooter:Enable(false)
			
			if wndCurrentLooter:IsChecked() then
				self.wndMasterLoot:FindChild("Assignment"):Enable(false)
			end
			wndCurrentLooter:SetCheck(false)
		end
	end
	
	for idx, wndLooter in pairs(self.wndMasterLoot_LooterList:GetChildren()) do
		local strName = wndLooter:GetName()
		if tValidLooters[strName] ==  nil then
			wndLooter:Destroy()
			self.tMasterLootLooterWindows[strName] = nil
		end
	end
	
	self.wndMasterLoot_LooterList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b)
		return a:FindChild("CharacterName"):GetText() < b:FindChild("CharacterName"):GetText()
	end)
end

function MasterLoot:RefreshLooterItemList(tLooterItemList)

	local nVPos = self.wndLooter_ItemList:GetVScrollPos()
	local tIndexedList = {}

	for idx, tItem in pairs (tLooterItemList) do
		tIndexedList[tItem.nLootId] = tItem
	
		local wndCurrentItem = self.tLooterLootWindows[tItem.nLootId]
		if wndCurrentItem == nil or not wndCurrentItem:IsValid() then
			wndCurrentItem = Apollo.LoadForm(self.xmlDoc, "LooterItemButton", self.wndLooter_ItemList, self)
			self.tLooterLootWindows[tItem.nLootId] = wndCurrentItem
			
			wndCurrentItem:FindChild("ItemIcon"):GetWindowSubclass():SetItem(tItem.itemDrop)
			wndCurrentItem:FindChild("ItemName"):SetText(tItem.itemDrop:GetName())
			wndCurrentItem:FindChild("ItemName"):SetTextColor(karItemColors[tItem.itemDrop:GetItemQuality()])
			
			-- new item(s) show the window
			self.wndLooter:Show(true)
		end
		
		wndCurrentItem:SetData(tItem)
	end

	for idx, wndItem in pairs(self.wndLooter_ItemList:GetChildren()) do
		local tItem = wndItem:GetData()
		if tIndexedList[tItem.nLootId] ==  nil then
			wndItem:Destroy()
			self.tLooterLootWindows[tItem.nLootId] = nil
		end
	end
	
	self.wndLooter_ItemList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndLooter_ItemList:SetVScrollPos(nVPos)

end

----------------------------

function MasterLoot:OnGroup_Left()
	if self.wndMasterLoot:IsShown() then
		self:OnCloseMasterWindow()
	end
end

----------------------------

function MasterLoot:OnItemGenerateTooltip(wndHandler, wndControl, eToolTipType, x, y)
	if wndHandler ~= wndControl then
		return
	end

	local tItem = wndControl:GetData()	
	if Tooltip ~= nil and Tooltip.GetItemTooltipForm ~= nil then
		Tooltip.GetItemTooltipForm(self, wndControl, tItem.itemDrop, {bPrimary = true, bSelling = false, itemCompare = tItem.itemDrop:GetEquippedItemForItemType()})
	end
end

----------------------------

function MasterLoot:OnItemMouseButtonUp(wndHandler, wndControl, eMouseButton) -- Both LooterItemButton and ItemButton
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		local tItemInfo = wndHandler:GetData()
		if tItemInfo and tItemInfo.itemDrop then
			Event_FireGenericEvent("GenericEvent_ContextMenuItem", tItemInfo.itemDrop)
		end
	end
end

function MasterLoot:OnItemCheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		local tItemInfo = wndHandler:GetData()
		if tItemInfo and tItemInfo.bIsMaster then
			self:RefreshMasterLootLooterList(tItemInfo)
		end
	end
end

function MasterLoot:OnItemUncheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		self:RefreshMasterLootLooterList(nil)
	end
end
----------------------------

function MasterLoot:OnCharacterMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		local unitPlayer = wndControl:GetData() -- Potentially nil
		local strPlayer = wndHandler:FindChild("CharacterName"):GetText()
		if unitPlayer and unitPlayer.unitLooter then
			Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", wndHandler, strPlayer, unitPlayer.unitLooter)
		else
			Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, strPlayer)
		end
	end
end

function MasterLoot:OnCharacterCheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		local tData = wndControl:GetData()
		self.wndMasterLoot:FindChild("Assignment"):SetData(tData)
		self.wndMasterLoot:FindChild("Assignment"):Enable(true)
	end
end

----------------------------

function MasterLoot:OnCharacterUncheck(wndHandler, wndControl, eMouseButton)
	if eMouseButton ~= GameLib.CodeEnumInputMouse.Right then
		self.wndMasterLoot:FindChild("Assignment"):Enable(false)
	end
end

----------------------------

function MasterLoot:OnAssignDown(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()

	GameLib.AssignMasterLoot(tData.tItem.nLootId, tData.unitLooter)
	self:RefreshMasterLootLooterList(nil)
end

----------------------------

function MasterLoot:OnCloseMasterWindow()
	self.locSavedMasterWindowLoc = self.wndMasterLoot:GetLocation()
	self.wndMasterLoot:Show(false)
end

------------------------------------

function MasterLoot:OnCloseLooterWindow()
	self.locSavedLooterWindowLoc = self.wndLooter:GetLocation()
	self.wndLooter:Show(false)
end

----------------------------

function MasterLoot:OnLootAssigned(objItem, strLooter)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", String_GetWeaselString(Apollo.GetString("CRB_MasterLoot_AssignMsg"), objItem:GetName(), strLooter))
end

local knSaveVersion = 1

function MasterLoot:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local locWindowMasterLoot = self.wndMasterLoot and self.wndMasterLoot:GetLocation() or self.locSavedMasterWindowLoc
	local locWindowLooter = self.wndLooter and self.wndLooter:GetLocation() or self.locSavedLooterWindowLoc

	local tSave =
	{
		tWindowMasterLocation = locWindowMasterLoot and locWindowMasterLoot:ToTable() or nil,
		tWindowLooterLocation = locWindowLooter and locWindowLooter:ToTable() or nil,
		nSaveVersion = knSaveVersion,
	}

	return tSave
end

function MasterLoot:OnRestore(eType, tSavedData)
	if tSavedData and tSavedData.nSaveVersion == knSaveVersion then

		if tSavedData.tWindowMasterLocation then
			self.locSavedMasterWindowLoc = WindowLocation.new(tSavedData.tWindowMasterLocation)
		end

		if tSavedData.tWindowLooterLocation then
			self.locSavedLooterWindowLoc = WindowLocation.new(tSavedData.tWindowLooterLocation )
		end

		local bShowWindow = #GameLib.GetMasterLoot() > 0
		if self.wndGroupBag and bShowWindow then
			self.wndGroupBag:Show(bShowWindow)
			self:RedrawMasterLootWindow()
		end
	end
end

local MasterLoot_Singleton = MasterLoot:new()
MasterLoot_Singleton:Init()
nt="1" TAnchorOffset="-73" RAnchorPoint="1" RAnchorOffset="-43" BAnchorPoint="1" BAnchorOffset="-47" DT_VCENTER="1" DT_CENTER="1" TooltipType="OnCursor" Name="SearchClearBtn" BGColor="white" TextColor="white" TooltipColor="" NormalTextColor="white" PressedTextColor="white" FlybyTextColor="white" PressedFlybyTextColor="white" DisabledTextColor="white" Visible="0" RelativeToClient="1" TransitionShowHide="1" HideInEditor="0">
            <Event Name="ButtonSignal" Function="OnSearchClearBtn"/>
        </Control>
        <Event Name="WindowShow" Function="OnListShow"/>
    </Form>
</Forms>
—Àí‘DòpüQîGÃ8]Æ'†ò„ÖA(ı≈t¬…e“˚Œ'v›(n®Dva–ÇŒ5?Ø(º^iP/Tnì} ≥¿< –pﬁ;Cñã¯5ÔFv¢ü`≈^|^bÑ#g,∫b?\é?zÉ.„∑É⁄Y˘˜Í‰„Ôè∞Ÿêx¸[ó˝v≥ñÊøÛÎÎ
Îó6Ωçœát8ŒÔ[
P'!>WôÁ§˚q]dƒØ7\Èª#°¿˘:z;Ÿk®‹èAa∏"yª/¬wó˘é|¬QÆœ{âàÔIÃŸh÷´	Ã”FΩÒ|ØVM#èΩ uªF‰Á€\∑Î5j¢Ôªø‡∏æ_D~©“Õ!~¨t˚yÙÌîBßx‡¯≠Ÿ†”Õè˙d_ô‚|Ã·"oÚ<ûò˜œ‚{ôä˙à“ “jΩ-ÎçΩ6÷%“Ë#ò8ó∆I—J2Ì˝æ:b&/ˆ†ÿ*ó§Ø¿Â¸!t?€ÉÆÿz˝∂EÿäÚÅ{Ä˙ÁÒ<#~ù–-I¡U¸ˇ∫*lZë]¯zh˙e…3∫‡Q∆˚#˙—·[~‡BGZ∑ÑÒª≈A9Úø}Œ£eËÔ·µIo"˛˝WÆ˚Ò˚∞#¿ﬁ !üWUÜºv%.<ÙÒ∞›"ª¿Ái∂åΩü?‚ÆøG<GﬁüuºÎ&6•ÔNÍÒµÑÇz|≥éº≈ÔÙ{RóóºÚÉÃw¬®/']èı\ßo$ÃŸ1}èı}£&Ò|≥!y<∑*ﬂß€jÂa◊ïra}zƒ{Î+'3qÓ≠#‰Áãà'KÙz‰–Ÿ	äÎ3ØÚ¸Ω∏_ÔyC|oFyÇ´…˙>H%™^OÚı6æwz›6Ωøπò¶◊»˜$k^St¡|∏˛˛¢ÿmE}E∂˘æƒ	y;≤É.Ár≠HÙ£xÅ¸8˜ˇŸÂ lÚÙê] ~@^QÙ≈ÏˇLÛG[‡I> +[Ã£"€ãd‹2Ûk q‚¸∑EG∞˝Äˇ>Äß}7…vc@q;Û’M