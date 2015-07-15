-----------------------------------------------------------------------------------------------
-- Client Lua Script for ResourceConversion
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Tooltip"
require "XmlDoc"
require "Unit"
require "GameLib"

local ResourceConversion = {}
local kTickDuration = .25

function ResourceConversion:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ResourceConversion:Init()
    Apollo.RegisterAddon(self)
end

function ResourceConversion:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ResourceConversion.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function ResourceConversion:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
    Apollo.RegisterEventHandler("ResourceConversionOpen", 	"OnResourceConversionOpen", self)
	Apollo.RegisterEventHandler("UpdateInventory", 			"OnUpdateInventory", self)
	Apollo.RegisterEventHandler("ResourceConversionClose", 	"OnCloseBtn", self)
	
	self.wndMain = nil
	
	self.arConversionWindows = {}
end

function ResourceConversion:OnCloseBtn() -- Also WindowClosed and "ResourceConversionClose"
	Event_CancelConverting()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
	end
end

function ResourceConversion:OnUpdateInventory()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local nVScrollPos = self.wndMain:FindChild("ConversionContainer"):GetVScrollPos()
	self:OnResourceConversionOpen(self.wndMain:GetData())
	self.wndMain:FindChild("ConversionContainer"):SetVScrollPos(nVScrollPos)
end

function ResourceConversion:OnResourceConversionOpen(unitVendor)
	if self.wndMain then
		self.wndMain:Destroy()
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ResourceConversionForm", nil, self)
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("ResourceConversion_Title")})
	
	self.wndMain:FindChild("VendorName"):SetText(unitVendor:GetName())
	self.wndMain:SetData(unitVendor)
	
	-- Get the conversions the vendor has available
	local arVendorConversions = unitVendor:GetResourceConversions()
	
	if arVendorConversions then
		for idx, tConversion in ipairs(unitVendor:GetResourceConversions()) do
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ConversionItem", self.wndMain:FindChild("ConversionContainer"), self)
			wndCurr:FindChild("ConversionLeftEditBox"):SetData(wndCurr)
			wndCurr:FindChild("SliderLeft"):SetData(wndCurr)
			wndCurr:FindChild("SliderRight"):SetData(wndCurr)
			wndCurr:FindChild("ConversionBtn"):SetData(wndCurr)
			wndCurr:FindChild("MainSlider"):SetData(wndCurr)
			wndCurr:SetData(tConversion)
		
			-- source item (left)
			wndCurr:FindChild("ConversionIconLeft"):SetSprite(tConversion.itemSource:GetIcon())
			wndCurr:FindChild("ConversionIconLeftText"):SetText(tConversion.nSourceCount)
			wndCurr:FindChild("AmountPerTurnIn"):SetText(tConversion.nSourceCount)
			self:HelperBuildItemTooltip(wndCurr:FindChild("ConversionIconLeft"), tConversion.itemSource)
			
			-- target item...
			local strRightItem = ""
			-- ...or rep
			if tConversion.eType == Unit.CodeEnumResourceConversionType.Item2Rep then
				local idReputation = tConversion.idTtarget
				strRightItem = String_GetWeaselString(Apollo.GetString("ResourceConversion_ToRep"), tConversion.strName)
				wndCurr:FindChild("ConversionIconRightText"):SetText(tConversion.nTargetCount)
				wndCurr:FindChild("ConversionIconRight"):SetTooltip(String_GetWeaselString(Apollo.GetString("ResourceConversion_ToRep"), idReputation))
			else
				strRightItem = tConversion.itemTarget:GetName()
				wndCurr:FindChild("ConversionIconRight"):SetSprite(tConversion.itemTarget:GetIcon())
				wndCurr:FindChild("ConversionIconRightText"):SetText(tConversion.nTargetCount)
				self:HelperBuildItemTooltip(wndCurr:FindChild("ConversionIconRight"), tConversion.itemTarget)
			end
			
			wndCurr:FindChild("MainSlider"):SetMinMax(0, tConversion.nAvailableCount / tConversion.nSourceCount, 1)
			wndCurr:FindChild("MainSlider"):SetValue(0)
			wndCurr:FindChild("ConversionBtn"):Enable(false)
			wndCurr:FindChild("ConversionLeftEditBox"):SetText(0)
			
			-- count 			
			if tConversion.nAvailableCount > 0 then
				wndCurr:FindChild("SliderLeft"):Enable(false)
				wndCurr:FindChild("SliderRight"):Enable(true)
				wndCurr:FindChild("ConversionBlockerBlackFillIconContainer"):Show(false)
				wndCurr:FindChild("ConversionBlockerBlackFill"):Show(false)
				
				local tItemCount = GetPluralizeActor(tConversion.itemSource:GetName(), tConversion.nAvailableCount)
				
				wndCurr:FindChild("ConversionItemNames"):SetText(String_GetWeaselString(Apollo.GetString("ResourceConversion_AvailToConvert"), tItemCount))
				wndCurr:FindChild("ConversionItemResult"):SetText("")
			else
				wndCurr:FindChild("SliderLeft"):Enable(false)
				wndCurr:FindChild("SliderRight"):Enable(false)
				wndCurr:FindChild("ConversionBlockerBlackFillIconContainer"):Show(true)
				wndCurr:FindChild("ConversionBlockerBlackFill"):Show(true)
				wndCurr:FindChild("ConversionItemNames"):SetTextColor(ApolloColor.new("ff444444"))
				wndCurr:FindChild("ConversionItemNames"):SetText(String_GetWeaselString(Apollo.GetString("ResourceConversion_NotEnough"), tConversion.itemSource:GetName()))
				wndCurr:FindChild("ConversionItemResult"):SetText("")
			end
		end
		self.wndMain:FindChild("ConversionContainer"):ArrangeChildrenVert(0)
	end
end

-----------------------------------------------------------------------------------------------
-- Conversion Item Increase/Decrease Buttons
-----------------------------------------------------------------------------------------------
function ResourceConversion:OnConversionAddBtn(wndHandler, wndControl)
	local wndConversionContainer = wndHandler:GetData()
	
	self:UpdateConversionWindow(wndConversionContainer, wndConversionContainer:FindChild("MainSlider"):GetValue() + 1)
end

function ResourceConversion:OnConversionSubBtn(wndHandler, wndControl)
	local wndConversionContainer = wndHandler:GetData()
	
	self:UpdateConversionWindow(wndConversionContainer, wndConversionContainer:FindChild("MainSlider"):GetValue() - 1)
end

---------------------------------------------------------------------------------------------------
-- Edit Box
---------------------------------------------------------------------------------------------------

function ResourceConversion:OnConversionLeftEditBoxChanged(wndHandler, wndControl, strNew)
	local wndConversionContainer = wndHandler:GetData()
	local nConversions = tonumber(strNew)
	local tConversionInfo = wndConversionContainer:GetData()
	self.bEditBoxUpdated = true
	
	if nConversions then
		if nConversions * tConversionInfo.nSourceCount > tConversionInfo.nAvailableCount then
			nConversions = tConversionInfo.nAvailableCount / tConversionInfo.nSourceCount
			self.bEditBoxUpdated = false
		elseif nConversions < 0 then
			nConversions = 0
			self.bEditBoxUpdated = false			
		end	
	end
	
	self:UpdateConversionWindow(wndConversionContainer, nConversions or 0)
end

---------------------------------------------------------------------------------------------------
-- Slider
---------------------------------------------------------------------------------------------------

function ResourceConversion:OnMainSliderChanged(wndHandler, wndControl, fValue) -- MainSlider
	local wndConversionContainer = wndHandler:GetData()
	
	self:UpdateConversionWindow(wndConversionContainer, fValue)
end

---------------------------------------------------------------------------------------------------
-- Main Update Function
---------------------------------------------------------------------------------------------------

function ResourceConversion:UpdateConversionWindow(wndConversionItem, nConversionCount)
	local wndLeftBtn = wndConversionItem:FindChild("SliderLeft")
	local wndRightBtn = wndConversionItem:FindChild("SliderRight")
	local tConversion = wndConversionItem:GetData()
	
	local nResourcesUsed = nConversionCount * tConversion.nSourceCount
	
	wndLeftBtn:Enable(nResourcesUsed > 0)
	wndRightBtn:Enable(nResourcesUsed < tConversion.nAvailableCount)
	wndConversionItem:FindChild("ConversionBtn"):Enable(nResourcesUsed > 0)
	
	if tonumber(wndConversionItem:FindChild("ConversionLeftEditBox"):GetText()) ~= nConversionCount then
		wndConversionItem:FindChild("ConversionLeftEditBox"):SetText(nConversionCount)
	end
	
	wndConversionItem:FindChild("MainSlider"):SetValue(nConversionCount)
	
	local strSourceName = ""
	if tConversion.eType == Unit.CodeEnumResourceConversionType.Item2Rep then
		strSourceName = tConversion.strName
	else
		strSourceName = tConversion.itemTarget:GetName()
	end
	
	local tSourceData = GetPluralizeActor(tConversion.itemSource:GetName(), tConversion.nAvailableCount)
	
	if nConversionCount == 0 then
		if tConversion.nAvailableCount > 0 then
			wndConversionItem:FindChild("ConversionItemNames"):SetText(String_GetWeaselString(Apollo.GetString("ResourceConversion_AvailToConvert"), tSourceData))
		else
			wndConversionItem:FindChild("ConversionItemNames"):SetText(String_GetWeaselString(Apollo.GetString("ResourceConversion_NotEnough"), tConversion.itemSource:GetName()))
		end
		wndConversionItem:FindChild("ConversionItemResult"):SetText("")
	else
		wndConversionItem:FindChild("ConversionItemNames"):SetText(String_GetWeaselString(Apollo.GetString("ResourceConversion_Converting"), nResourcesUsed, tConversion.nAvailableCount, tSourceData))
		wndConversionItem:FindChild("ConversionItemResult"):SetText(String_GetWeaselString(Apollo.GetString("ResourceConversion_Result"), Apollo.FormatNumber(nConversionCount * tConversion.nTargetCount, 0, true), strSourceName))
	end
end

---------------------------------------------------------------------------------------------------
-- Conversion Button
---------------------------------------------------------------------------------------------------

function ResourceConversion:OnConversionBtn(wndHandler, wndControl) -- ConversionBtn
	local wndConversionContainer = wndHandler:GetData()
	local tConversion = wndConversionContainer:GetData()
	local unitVendor = self.wndMain:GetData()
	unitVendor:ConvertResource(tConversion.idConversion, wndConversionContainer:FindChild("ConversionLeftEditBox"):GetText() * tConversion.nSourceCount)
end

---------------------------------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------------------------------

function ResourceConversion:HelperBuildItemTooltip(wndArg, itemCurr)
	wndArg:SetTooltipDoc(nil)
	wndArg:SetTooltipDocSecondary(nil)
	local itemEquipped = itemCurr:GetEquippedItemForItemType()
	Tooltip.GetItemTooltipForm(self, wndArg, itemCurr, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	if itemCurr then
		Tooltip.GetItemTooltipForm(self, wndArg, itemEquipped, {bPrimary = false, bSelling = false, itemCompare = itemCurr})
	end
end

local ResourceConversionInst = ResourceConversion:new()
ResourceConversionInst:Init()ı|/²ªŸ‡«úypYÕÏC‹Uı<È¬êç!Å_ƒ~~  HÕÏ÷«úyH±ªŸ‡«úypYÕÏC‹Uı<È¬êç!Åw^?§”™‡¾~Nöêgi´ôWd-³âõ(†__>çeàÓÏØ]w[?ÿs÷ûŞúWöêçï~o°ôóõRDÆ=˜qı†ïfÙû¾ÔŒÈ»¬Ÿ—(úÑW¿áÊ]³Ñ× '–~Æù€×oØğn–q>Ü-ı|Ù«ŸWcî~K®¤°¯¾Ã…¯ÿJööã˜ÿ ëç?İmı¼DÑ¾úWÆıÓÕÏCxı:•o¿.ı¬ò­ñ×¥ŸU¾5V×Z|§ô³Ê·ÆêúÏC‹ÕõŸ›û­Ÿæ£uˆègfø•oƒaø¾Eı,ĞL—¯òÀùvâáÕÏ Ğ,*ß“Ñ¦¿ú™*á$Š¯ÊwŠoM?“ãÓå©<p5ëÖãô›_*ß.õÜ_ıLJ@LÇWå3®ıæzp(ÌVYe•UVYe•UVYå{ÑúÏ€Z¿îÿÙ¦uò•  •Gò± Š,X˜iÎ¾ÆàöÛ²TŞÖ×D¹ûKÚmd)ØĞBTïÓ{"NZœÛnfÈ‘ÁÇRÈ¶ä#³R–dâı‘#´ê$38™M±E˜³ökÒãf[ÍæƒjñgÍÙd:¢¯X4ÀˆvÚª­ÓæjV%'TÂJšå‹·Ÿ³K¸íMé}~×¬kì¹Vz™•¼ÏÙ9{ÎÉĞN½ŞóéÜUì2ÓBÖß#I7]İÙÂß•CŸû%º‡«à®XLúŠg¶¿“îPos–|öš ‘—š¹é‹ˆK‡OfH9íÌâ%Cñ'”qÚ	>>eï-íPçêi‰)uC¼8÷"%Æµs»	‹sÍÌYORöÈkcü:‚nÓJïvb¦ÿ„Mü~s"Ğññv)ıîô‹I×ÖÃÓ@á£Ó{•:7Y’P°"‹ä+Íğmi¯Ùá¸ÆlÖŒKŞ5;×ØH´ùæ«M*‚¿lĞ¯Øá]›[¼Ts§Wf¬ç¹ÉÚÑôÜ€jÈ­søÿóóÿùùër»7¤m¯*š¹]Jßr©©fR²Û¹/İ4Ò$