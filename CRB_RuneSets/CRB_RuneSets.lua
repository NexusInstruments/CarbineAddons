-----------------------------------------------------------------------------------------------
-- Client Lua Script for CRB_RuneSets
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local CRB_RuneSets = {}

function CRB_RuneSets:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CRB_RuneSets:Init()
    Apollo.RegisterAddon(self)
end

function CRB_RuneSets:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CRB_RuneSets.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function CRB_RuneSets:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenu_ToggleSets", 	"RedrawSets", self)
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", 	"OnUpdateEvent", self)
	Apollo.RegisterEventHandler("ItemModified", 				"OnUpdateEvent", self)
	Apollo.RegisterEventHandler("ToggleCharacterWindow", 		"OnToggleCharacterWindow", self)
end

-----------------------------------------------------------------------------------------------
-- Sets
-----------------------------------------------------------------------------------------------

function CRB_RuneSets:RedrawSets(wndParent)
	if not self.wndMain or not self.wndMain:IsValid() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "CRB_RuneSetsForm", wndParent, self)
		if self.locSavedWindowLoc then
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
	end

	-- Sets from equipped items only
	local tListOfSets = {}
	local bHeaderBag = true -- TODO
	local bHeaderEquipped = true -- TODO
	for idx, itemCurr in pairs(CraftingLib.GetItemsWithRuneSlots(bHeaderEquipped, bHeaderBag)) do
		for idx2, tSetInfo in ipairs(itemCurr:GetSetBonuses()) do
			if tSetInfo and tSetInfo.strName and not tListOfSets[tSetInfo.strName] then
				tListOfSets[tSetInfo.strName] = tSetInfo
			end
		end
	end

	-- Current Runes
	for idx, itemRune in pairs(CraftingLib.GetValidRuneItems()) do
		local tMicrochipData = itemRune:GetMicrochipInfo()
		for idx, tSetInfo in pairs(tMicrochipData.tSet or {}) do
			if tSetInfo and tSetInfo.strName and not tListOfSets[tSetInfo.strName] then
				tSetInfo.nPower = 0 -- HACK
				tListOfSets[tSetInfo.strName] = tSetInfo
			end
		end
	end

	-- Draw sets now
	local strFullText = ""
	local kstrLineBreak = "<P Font=\"CRB_InterfaceLarge_B\" TextColor=\"0\">.</P>" -- TODO TEMP HACK
	for idx, tSetInfo in pairs(tListOfSets) do
		local strLocalSetText = string.format("<P Font=\"CRB_InterfaceLarge\" TextColor=\"UI_TextHoloTitle\">%s</P>",
		String_GetWeaselString(Apollo.GetString("EngravingStation_RuneSetText"), tSetInfo.strName, tSetInfo.nPower, tSetInfo.nMaxPower))

		local tBonuses = tSetInfo.arBonuses
		table.sort(tBonuses, function(a,b) return a.nPower < b.nPower end)

		for idx3, tBonusInfo in pairs(tBonuses) do
			-- tBonusInfo.active, tBonusInfo.power, tBonusInfo.spell:GetFlavor()
			local strLocalColor = tBonusInfo.bIsActive and "ItemQuality_Good" or "UI_TextHoloBody"
			strLocalSetText = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P><P TextColor=\"0\">.</P>", strLocalSetText, strLocalColor,
			String_GetWeaselString(Apollo.GetString("Tooltips_RuneDetails"), tBonusInfo.nPower, tBonusInfo.splBonus:GetName(), tBonusInfo.splBonus:GetFlavor() or ""))

		end

		strFullText = strFullText .. kstrLineBreak .. strLocalSetText
	end

	self.wndMain:FindChild("SetsListNormalText"):SetAML(strFullText)
	self.wndMain:FindChild("SetsListNormalText"):SetHeightToContentHeight()
	self.wndMain:FindChild("SetsListContainer"):RecalculateContentExtents()
	self.wndMain:FindChild("SetsListContainer"):ArrangeChildrenVert(0)
	self.wndMain:FindChild("SetsListEmptyText"):Show(strFullText == "")
end

function CRB_RuneSets:OnSetsClose(wndHandler, wndControl)
	if self.wndMain and self.wndMain:IsValid() then
		self.locSavedWindowLoc = self.wndMain:GetLocation()
		self.wndMain:Destroy()
	end
end

function CRB_RuneSets:OnUpdateEvent()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsVisible() then -- Will consider parents as well
		return
	end
	self:RedrawSets()
end

function CRB_RuneSets:OnToggleCharacterWindow()
	if not self.wndMain or not self.wndMain:IsValid() then -- Doesn't care about visibility (as it's false while being opened)
		return
	end
	self:RedrawSets()
end

local CRB_RuneSetsInst = CRB_RuneSets:new()
CRB_RuneSetsInst:Init()
