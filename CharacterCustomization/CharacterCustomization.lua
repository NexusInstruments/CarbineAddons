-----------------------------------------------------------------------------------------------
-- Client Lua Script for CharacterCustomization
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
 
-----------------------------------------------------------------------------------------------
-- CharacterCustomization Module Definition
-----------------------------------------------------------------------------------------------
local CharacterCustomization = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local knTokenItemId = 50763
local knStaticAnimationValue = 5612

local ktOverlayTypes =
{
	Purchase = 1,
	Cancel = 2,
	Code = 3,
}

local ktRaceStrings =
{
	[GameLib.CodeEnumRace.Human]	= Apollo.GetString("RaceHuman"),
	[GameLib.CodeEnumRace.Granok]	= Apollo.GetString("CRB_DemoCC_Granok"),
	[GameLib.CodeEnumRace.Aurin]	= Apollo.GetString("CRB_DemoCC_Aurin"),
	[GameLib.CodeEnumRace.Draken]	= Apollo.GetString("RaceDraken"),
	[GameLib.CodeEnumRace.Mechari]	= Apollo.GetString("RaceMechari"),
	[GameLib.CodeEnumRace.Mordesh]	= Apollo.GetString("CRB_Mordesh"),
	[GameLib.CodeEnumRace.Chua]		= Apollo.GetString("RaceChua"),
}

local ktGenderStrings =
{
	[Unit.CodeEnumGender.Male] 		= Apollo.GetString("CRB_Male"),
	[Unit.CodeEnumGender.Female] 	= Apollo.GetString("CRB_Female"),
}

local ktFactionStrings =
{
	[Unit.CodeEnumFaction.DominionPlayer] 	= Apollo.GetString("CRB_Dominion"),
	[Unit.CodeEnumFaction.ExilesPlayer] 	= Apollo.GetString("CRB_Exile"),
}

local ktFaceSliderIds =
{
	[1] 	= true,
	[21] 	= true,
	[22] 	= true,
}

local ktCustomizeBodyType = 
{
	[2] 	= true,
	[25] 	= true,
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CharacterCustomization:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CharacterCustomization:Init()
	local tDependencies = {}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CharacterCustomization OnLoad
-----------------------------------------------------------------------------------------------
function CharacterCustomization:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CharacterCustomization.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- CharacterCustomization OnDocLoaded
-----------------------------------------------------------------------------------------------
function CharacterCustomization:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		return
	end
	
	Apollo.RegisterEventHandler("ShowDye", "OnInit", self)
	Apollo.RegisterEventHandler("HideDye", "OnHideDye", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", "UpdateCost", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "UpdateCost", self)

	--ServiceTokenPrompt
	Apollo.RegisterEventHandler("ServiceTokenClosed_CharacterCustomization", "OnServiceTokenClosed_CharacterCustomization", self)

	
	-- by sequential index
	self.arCharacterBones = {}
	self.arCurrentCustomizationOptions = {}
	
	-- indexed by sliderIds
	self.tPreviousBones = {}
	self.tPreviousOptions = {}
	self.tOptionWindows = {}
	self.tBoneWindows = {}
	self.tChangedBones = {}
	
	self.tPreviousBonesHolder = {}
	
	--just for customization options, not bones
	self.tCustomizationCosts = {}
	
	self.wndBonePreviewItem = nil
	self.idSelectedCategory = nil

	self.bHideHelm = true
end

--Init
function CharacterCustomization:OnInit()
	if not GameLib.IsCharacterLoaded() or self.wndMain then
		return
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CharacterCustomization", nil, self)
	self.wndPreview = self.wndMain:FindChild("RightContent:Costume")	
	
	local unitPlayer = GameLib.GetPlayerUnit()	
	self.wndMain:FindChild("ToggleFlyout"):AttachWindow(self.wndMain:FindChild("PreviewChangesFlyout"))
	self.wndPreview:SetCostume(unitPlayer)
	self.wndPreview:SetModelSequence(knStaticAnimationValue)
	self:GetCharacterInfo()
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):DestroyChildren()
	
	local costumeDisplayed = CostumesLib.GetCostume(CostumesLib.GetCostumeIndex())
	local unitPlayer = GameLib.GetPlayerUnit()	
	self.itemDisplayedHelm = nil
	
	if costumeDisplayed then
		self.bEnableHelmSwap = costumeDisplayed:IsSlotVisible(GameLib.CodeEnumItemSlots.Head)
		self.itemDisplayedHelm = costumeDisplayed:GetSlotItem(GameLib.CodeEnumItemSlots.Head)
	end
	
	if not self.itemDisplayedHelm or not costumeDisplayed then
		for idx, itemEquipment in pairs(unitPlayer:GetEquippedItems()) do
			if itemEquipment:GetSlot() == GameLib.CodeEnumEquippedItems.Head then
				self.itemDisplayedHelm = itemEquipment
			end
		end
		
		self.bEnableHelmSwap = self.itemDisplayedHelm ~= nil
	end
	
	local wndHideHelm = self.wndMain:FindChild("RightContent:HideHelmBtn")
	wndHideHelm:Enable(self.bEnableHelmSwap)
	wndHideHelm:SetCheck(self.bHideHelm)
	
	if self.bEnableHelmSwap and self.bHideHelm then
		self:OnHideHelm()
	end
	
	self:ResetTabs()
	
	--Loads headers, followed by options within the headers
	self:LoadCustomizationHeaders()
	self:ResizePreview()
	self:UpdateCost()
	self.wndMain:Invoke()
end

function CharacterCustomization:GetCharacterInfo()
	self.arCharacterBones = self.wndPreview:GetBones()
	self.arCurrentCustomizationOptions = self.wndPreview:GetLooks()
end

function CharacterCustomization:LoadCustomizationHeaders()
	local wndCustomizationContainer = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer")
	
	Apollo.LoadForm(self.xmlDoc, "CodeCategoryHeader", wndCustomizationContainer, self)
	
	-- We want to make sure we're loading the Face and Face Customization first
	for idx, tCategory in pairs(self.arCurrentCustomizationOptions) do
		if ktFaceSliderIds[tCategory.sliderId] then
			self:LoadHeader(tCategory.sliderId, tCategory)
		
			local wndBoneHeader = Apollo.LoadForm(self.xmlDoc, "BoneCategoryHeader", wndCustomizationContainer, self)
			wndBoneHeader:FindChild("CategorySelectBtn"):SetText(Apollo.GetString("CharacterCustomize_CustomizeFace"))
			self.tBoneWindows = 
			{
				wndHeader = wndBoneHeader,
				tSliders = {},
			}
			
			for idx, tBone in pairs(self.arCharacterBones) do
				self.tPreviousBones[tBone.sliderId] = tBone.value
			end
		end
	end
	
	for idx, tCategory in pairs(self.arCurrentCustomizationOptions) do
		if not ktFaceSliderIds[tCategory.sliderId] then
			self:LoadHeader(tCategory.sliderId, tCategory)
		end
	end

	wndCustomizationContainer:ArrangeChildrenVert()
end

function CharacterCustomization:LoadHeader(idSlider, tCategory)
	local wndHeader = Apollo.LoadForm(self.xmlDoc, "CategoryHeader", self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"), self)
	
	if not self.nCategoryHeight then
		self.nCategoryHeight = wndHeader:GetHeight()
	end
	
	wndHeader:SetData(tCategory)
	wndHeader:FindChild("CategorySelectBtn"):SetData(idSlider)
	wndHeader:FindChild("CategorySelectBtn"):SetText(tCategory.name)
	
	self.tPreviousOptions[idSlider] = tCategory.valueIdx
	
	-- we want face options on top.

	self.tOptionWindows[idSlider] =
	{
		wndHeader = wndHeader,
		tOptions = {},
	}
end

-----------------------------------------------------------------------------------------------
-- Customization Options
-----------------------------------------------------------------------------------------------

function CharacterCustomization:LoadCustomizationOptions(wndCategoryHeader, tCategory)
	local wndContainer = wndCategoryHeader:FindChild("GroupContents")
	local unitPlayer = GameLib.GetPlayerUnit()
	
	wndContainer:DestroyChildren()
	
	for idx = 1, tCategory.count do
		local wndOption = Apollo.LoadForm(self.xmlDoc, "OptionItem", wndContainer, self)
		local wndOptionPreview = wndOption:FindChild("CostumeWindow")
		wndOptionPreview:SetCostume(unitPlayer)
		
		-- Use the correct values for the open category.
		for nLookIdx, tOptions in pairs(self.arCurrentCustomizationOptions) do
			nValue = nil
			if tOptions.sliderId ~= self.idSelectedCategory then
				nValue = tOptions.values[tOptions.valueIdx]
			else
				nValue = tCategory.values[idx]
			end
			
			wndOptionPreview:SetLook(tOptions.sliderId, nValue)
		end

		wndOptionPreview:SetCamera(ktCustomizeBodyType[tCategory.sliderId] and "Paperdoll" or "Portrait")
		
		wndOption:SetData(tCategory.values[idx])
		wndOption:FindChild("OptionBtn"):SetData(idx)
		
		if self.bEnableHelmSwap and self.wndMain:FindChild("RightContent:HideHelmBtn"):IsChecked() then
			wndOptionPreview:RemoveItem(GameLib.CodeEnumItemSlots.Head)
		end
		
		wndOptionPreview:SetAnimated(false)
		
		if self.tPreviousOptions[tCategory.sliderId] == idx then
			local tPixieOverlay =
			{
				strSprite = "bk3:UI_BK3_Options_Telegraph_Outline",
				loc = {fPoints = {0, 0, 1, 1}, nOffsets = {-6, -6, 5, 6}}
			}
			wndOptionPreview:AddPixie(tPixieOverlay)
		end
		
		local nOptionIdx = nil
		for idx, tOption in pairs(self.arCurrentCustomizationOptions) do
			if tOption.sliderId == tCategory.sliderId then
				nOptionIdx = idx
				break
			end
		end
		
		if nOptionIdx ~= nil and idx == self.arCurrentCustomizationOptions[nOptionIdx].valueIdx then
			wndOption:FindChild("OptionBtn"):SetCheck(true)
		end
		
		self.tOptionWindows[tCategory.sliderId].tOptions[idx] = wndOption
	end
	
	wndContainer:ArrangeChildrenTiles()
	wndContainer:Show(false)
end

function CharacterCustomization:OnCategoryCheck(wndHandler, wndControl)
	local wndParent = wndControl:GetParent()
	local tCategory = wndParent:GetData()
	
	self.idSelectedCategory = wndControl:GetData()
	
	self.wndPreview:SetCamera(ktCustomizeBodyType[tCategory.sliderId] and "Paperdoll" or "Portrait")

	self:LoadCustomizationOptions(wndParent, tCategory)
	
	wndParent:FindChild("GroupContents"):Invoke()
	self:ResizeTree()
	
	local wndSelectedOption = self.tOptionWindows[tCategory.sliderId].tOptions[tCategory.valueIdx]
	wndSelectedOption:FindChild("OptionBtn"):SetCheck(true)
	
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
	
end

function CharacterCustomization:OnCategoryUncheck(wndHandler, wndControl)
	self.wndMain:SetGlobalRadioSel("CharacterCustomization_SelectedOption", -1)
	self.idSelectedCategory = nil
	
	wndControl:GetParent():FindChild("GroupContents"):DestroyChildren()
	self:ResizeTree()
	
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end

function CharacterCustomization:OnOptionCheck(wndHandler, wndControl)
	local idSelectedOption = wndHandler:GetData()
	
	if not self.idSelectedCategory or not idSelectedOption then
		return
	end

	local wndHeader = self.tOptionWindows[self.idSelectedCategory].wndHeader
	local tOptions = wndHeader:GetData()
	tOptions.valueIdx = idSelectedOption
	
	self.wndPreview:SetLook(tOptions.sliderId, tOptions.values[tOptions.valueIdx])
	
	local wndCostPreview = self.tCustomizationCosts[tOptions.sliderId] and self.tCustomizationCosts[tOptions.sliderId].wndPreview or nil
	if self.tPreviousOptions[tOptions.sliderId] ~= idSelectedOption then
		local monCost = self.wndPreview:GetCostForCustomizationSelection(tOptions.sliderId, tOptions.values[idSelectedOption])
		
		if not wndCostPreview then
			wndCostPreview = Apollo.LoadForm(self.xmlDoc, "PreviewLineItem", self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"), self)
			wndCostPreview:FindChild("ListItemName"):SetText(tOptions.name)
			wndCostPreview:FindChild("UndoBtn"):SetData(tOptions.sliderId)
		end
		wndCostPreview:FindChild("CashWindow"):SetAmount(monCost, true)
		wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(true)
		self.tCustomizationCosts[tOptions.sliderId] = {strName = tOptions.name, monCost = monCost, wndPreview = wndCostPreview}
		
		if ktFaceSliderIds[tOptions.sliderId] then
			for idBone, nBoneValue in pairs(self.tPreviousBones) do
				if self.tPreviousBones[idBone] ~= 0 then
					self.tPreviousBonesHolder[idBone] = self.tPreviousBones[idBone]
				end
				self.tPreviousBones[idBone] = 0
				self.wndPreview:SetBone(idBone, 0)
			end
			
			for idBone, bChanged in pairs(self.tChangedBones) do
				self.tChangedBones[idBone] = false
			end
		end

		--If a new face style was selected, bones will be reset so clear bone preview entry.
		if ktFaceSliderIds[self.idSelectedCategory] and self.wndBonePreviewItem then
			self.wndBonePreviewItem:Destroy()
			self.wndBonePreviewItem = nil
			self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):ArrangeChildrenVert()
			self:CheckForBoneChanges()
		end

	elseif self.tCustomizationCosts[tOptions.sliderId] then
		if self.tCustomizationCosts[tOptions.sliderId].wndPreview then
			self.tCustomizationCosts[tOptions.sliderId].wndPreview:Destroy()
			self.tCustomizationCosts[tOptions.sliderId].wndPreview = nil
			wndCostPreview = nil
		end
		
		wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(false)
		self.tCustomizationCosts[tOptions.sliderId] = nil
		
		if ktFaceSliderIds[tOptions.sliderId] then
			for idBone, nBoneValue in pairs(self.tPreviousBones) do
				self.tPreviousBones[idBone] = self.tPreviousBonesHolder[idBone]
				self.wndPreview:SetBone(idBone, self.tPreviousBones[idBone])
				
				self.tChangedBones[idBone] = false
			end
			self.tPreviousBonesHolder = {}
		end
	end
	
	if wndCostPreview then
		wndCostPreview:GetParent():ArrangeChildrenVert()
	end

	self:ResizePreview()
	self:UpdateCost()
	self.arCurrentCustomizationOptions = self.wndPreview:GetLooks()
end

function CharacterCustomization:OnOptionUndo(wndHandler, wndControl)
	local idSlider = wndHandler:GetData()
	local wndHeader = nil
	if idSlider ~= -1 then
		local nOptionIdx = nil
		for idx, tOption in pairs(self.arCurrentCustomizationOptions) do
			if tOption.sliderId == idSlider then
				nOptionIdx = idx
			end
		end
		
		if idSlider == self.idSelectedCategory then
			self.wndMain:SetGlobalRadioSel("CharacterCustomization_SelectedOption", -1)
			self.tOptionWindows[idSlider].tOptions[self.tPreviousOptions[idSlider]]:FindChild("OptionBtn"):SetCheck(true)
		end
	
		self.arCurrentCustomizationOptions[nOptionIdx].valueIdx = self.tPreviousOptions[idSlider]
		self.wndPreview:SetLook(idSlider, self.arCurrentCustomizationOptions[nOptionIdx].values[self.arCurrentCustomizationOptions[nOptionIdx].valueIdx])
		
		self.tCustomizationCosts[idSlider] = nil
		
		wndHeader = self.tOptionWindows[idSlider].wndHeader
		wndHeader:SetData(self.arCurrentCustomizationOptions[nOptionIdx])
		
		wndHandler:GetParent():Destroy()
		self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):ArrangeChildrenVert()
	else
		for idx, tInfo in pairs(self.arCharacterBones) do
			if self.tChangedBones[tInfo.sliderId] then
				local wndUndoBtn = nil 
				if self.tBoneWindows.tSliders[tInfo.sliderId] then
					wndUndoBtn = self.tBoneWindows.tSliders[tInfo.sliderId]:FindChild("UndoBtn")
				end
				if wndUndoBtn then
					self:OnUndoBone(wndUndoBtn, wndUndoBtn)
				else
					self:ResetBone(tInfo.sliderId)
				end
			end
		end
		wndHeader = self.tBoneWindows.wndHeader
	end
	
	wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(false)
	self:UpdateCost()
	self:ResizePreview()
	
	self.arCurrentCustomizationOptions = self.wndPreview:GetLooks()
end

-----------------------------------------------------------------------------------------------
-- Bones!
-----------------------------------------------------------------------------------------------

function CharacterCustomization:LoadBoneCustomizationOption(wndCategoryHeader, strOptionWindow, tBone)
	local wndContainer = wndCategoryHeader:FindChild("GroupContents")
	
	local wndOption = Apollo.LoadForm(self.xmlDoc, strOptionWindow, wndContainer, self)
	wndOption:SetData(tBone)
	wndOption:FindChild("SliderContainer:SliderTitle"):SetText(tBone.name)
	
	local wndSlider = wndOption:FindChild("SliderContainer:SliderBar")
	wndSlider:SetData(tBone.sliderId)
	wndSlider:SetMinMax(-1, 1)
	
	wndOption:FindChild("UndoBtn"):Enable(self.tChangedBones[tBone.sliderId])
	
	self.tBoneWindows.tSliders[tBone.sliderId] = wndOption
	
	wndContainer:ArrangeChildrenVert()
	wndContainer:Show(false)
end

function CharacterCustomization:OnBoneCategoryCheck(wndHandler, wndControl)
	local wndContainer = wndControl:GetParent():FindChild("GroupContents")
	self.arCharacterBones = self.wndPreview:GetBones()
	
	for idx, tBone in pairs(self.arCharacterBones) do
		self:LoadBoneCustomizationOption(self.tBoneWindows.wndHeader, "BoneOptionItem", tBone)
	end
	
	for idx, tBone in pairs(self.arCharacterBones) do
		local wndBone = self.tBoneWindows.tSliders[tBone.sliderId]
		wndBone:FindChild("SliderContainer:SliderBar"):SetValue(tBone.value)
		wndBone:FindChild("SliderContainer:SliderValue"):SetText(string.format("%.2f", tBone.value))
	end
	
	self.wndPreview:SetCamera("Portrait")
	wndContainer:Invoke()
	self:ResizeTree()
	
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end

function CharacterCustomization:OnBoneChanged(wndHandler, wndControl)
	local nValue = wndHandler:GetValue()
	local idBone = wndHandler:GetData()
	local strCurrentValue = string.format("%.2f", nValue)
	
	wndHandler:GetParent():FindChild("SliderValue"):SetText(strCurrentValue)
	self.wndPreview:SetBone(idBone, nValue)
	wndHandler:GetParent():GetParent():FindChild("UndoBtn"):Enable(true)
	
	self.arCharacterBones = self.wndPreview:GetBones()
	
	self.tChangedBones[idBone] = self.tPreviousBones[idBone] ~= nValue

	self:SetBoneCostPreview()
	self:UpdateCost()
end

function CharacterCustomization:SetBoneCostPreview()
	local bBonesChanged = self:CheckForBoneChanges()
	
	if bBonesChanged and not self.wndBonePreviewItem then
		self.wndBonePreviewItem = Apollo.LoadForm(self.xmlDoc, "PreviewLineItem", self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"), self)
		self.wndBonePreviewItem:FindChild("ListItemName"):SetText(Apollo.GetString("CharacterCustomize_Bones"))
		self.wndBonePreviewItem:FindChild("CashWindow"):SetAmount(self.wndPreview:GetCostForBoneChanges(), true)
		
		-- Using -1 for the UndoBtn's data since bones do use the same set of sliderIds as other categories
		self.wndBonePreviewItem:FindChild("UndoBtn"):SetData(-1)		
	elseif not bBonesChanged and self.wndBonePreviewItem then
		self.wndBonePreviewItem:Destroy()
		self.wndBonePreviewItem = nil
	end
	self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):ArrangeChildrenVert()
	self:ResizePreview()
end

function CharacterCustomization:OnUndoBone(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("SliderContainer")
	local tBone = wndParent:GetData()
	
	wndContainer:FindChild("SliderBar"):SetValue(self.tPreviousBones[tBone.sliderId])
	wndContainer:FindChild("SliderValue"):SetText(string.format("%.2f", self.tPreviousBones[tBone.sliderId]))
	wndContainer:GetParent():FindChild("UndoBtn"):Enable(false)
	for idx, tBoneOption in pairs(self.arCharacterBones) do
		if tBone.sliderId == tBoneOption.sliderId then
			wndParent:SetData(tBoneOption)
		end
	end
	
	self:ResetBone(tBone.sliderId)
end

function CharacterCustomization:ResetBone(idSlider)
	if not idSlider then
		return
	end
	
	self.wndPreview:SetBone(idSlider, self.tPreviousBones[idSlider])
	self.arCharacterBones = self.wndPreview:GetBones()
	self.tChangedBones[idSlider] = false
	
	self:SetBoneCostPreview()	
	self:UpdateCost()
end

-----------------------------------------------------------------------------------------------
-- CostPreview Window
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnCostPreview(wndHandler, wndControl)
	local wndCostPreview = self.wndMain:FindChild("PreviewChangesFlyout")
	
	if wndCostPreview:IsShown() then
		wndCostPreview:Show(false)
	else
		wndCostPreview:Show(true)
	end
end
	
function CharacterCustomization:ResizePreview()
	local wndCostPreview = self.wndMain:FindChild("PreviewChangesFlyout")
	local wndContainer = wndCostPreview:FindChild("CostPreviewContainer")
	local arPreviewWindows = wndContainer:GetChildren()
	local bHasChanges = arPreviewWindows and #arPreviewWindows > 0
	
	local nContainerHeight = 0
	
	wndCostPreview:FindChild("NoChangesLabel"):Show(not bHasChanges)
	
	if bHasChanges then
		nContainerHeight = arPreviewWindows[1]:GetHeight() * #arPreviewWindows
	else
		--Create enough room to show the "no changes" label
		nContainerHeight = 34
	end		

	if not self.nHeightOfPreview then -- get the height just once
		local tOriginalOffsets = wndCostPreview:GetOriginalLocation():ToTable().nOffsets
		self.nHeightOfPreview = (tOriginalOffsets[4] - tOriginalOffsets[2])
	end
			
	local nLeft, nTop, nRight, nBottom = wndCostPreview:GetAnchorOffsets()
	wndCostPreview:SetAnchorOffsets(nLeft, nBottom - self.nHeightOfPreview - nContainerHeight, nRight, nBottom)
end

-----------------------------------------------------------------------------------------------
-- Buy Confirmation
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnPurchaseWithServiceTokens(wndHandler, wndControl)
	local wndConfirmationOverlay = self.wndMain:FindChild("ConfirmationOverlay")
	for idx, wndChild in pairs(wndConfirmationOverlay:GetChildren()) do
		wndChild:Show(false)
	end
	
	local tData = 
	{	
		wndParent = self.wndMain:FindChild("ConfirmationOverlay"),
		strEventName = "ServiceTokenClosed_CharacterCustomization",
		monCost = wndControl:GetData(),
		strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), Apollo.GetString("Costumes_CharacterChopShop")),
		tActionData =
		{
			GameLib.CodeEnumConfirmButtonType.CommitCustomizationChanges,
			self.wndPreview,
			true
		}
	}

	wndConfirmationOverlay:Show(true)
	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tData)
end

function CharacterCustomization:OnServiceTokenClosed_CharacterCustomization(strParent)
	if not self.wndMain then
		return
	end

	local wndServiceTokenParent = self.wndMain:FindChild(strParent)
	if wndServiceTokenParent then
		wndServiceTokenParent:Show(false)
	end
	
	self:OnPurchaseConfirm()
end

function CharacterCustomization:OnBuyBtn(wndHandler, wndControl)
	local tData = wndControl:GetData()
	local wndPurchaseConfirm = self.wndMain:FindChild("ConfirmationOverlay:PurchaseConfirmation")
	local wndPriceContainer = wndPurchaseConfirm:FindChild("LineItemContainer")
	wndPriceContainer:DestroyChildren()
	
	for idSlider, tCost in pairs(self.tCustomizationCosts) do
		local wndCostItem = Apollo.LoadForm(self.xmlDoc, "ConfirmationLineItem", wndPriceContainer, self)
		wndCostItem:FindChild("ListItemName"):SetText(tCost.strName)
		wndCostItem:FindChild("CashWindow"):SetAmount(tCost.monCost, true)
	end
	
	if self.wndBonePreviewItem then
		local wndCostItem = Apollo.LoadForm(self.xmlDoc, "ConfirmationLineItem", wndPriceContainer, self)
		local monCost = self.wndPreview:GetCostForBoneChanges()
		wndCostItem:FindChild("ListItemName"):SetText(Apollo.GetString("CharacterCustomize_Bones"))
		wndCostItem:FindChild("CashWindow"):SetAmount(monCost, true)
	end

	wndPriceContainer:ArrangeChildrenVert()

	local arPreviewEntries = wndPriceContainer:GetChildren()
	
	if arPreviewEntries and #arPreviewEntries > 0 then -- make sure the table exists
		local nPreviewLineItemHeight = arPreviewEntries[1]:GetHeight() --get height of first entry
		local nTotalLineItemHeight = #arPreviewEntries * nPreviewLineItemHeight -- height entries * single entry
		local tOffsets = wndPurchaseConfirm:GetOriginalLocation():ToTable().nOffsets
		
		wndPurchaseConfirm:SetAnchorOffsets(tOffsets[1], tOffsets[2] - (nTotalLineItemHeight / 2), tOffsets[3], tOffsets[4] + (nTotalLineItemHeight / 2))
	end
		
	local wndSubtotal = wndPurchaseConfirm:FindChild("TotalCost")
	wndSubtotal:SetAmount(tData.monCost, true)
	
	self:ToggleOverlay(ktOverlayTypes.Purchase, true)
end

function CharacterCustomization:OnPurchaseConfirm(wndHandler, wndControl)
	local wndFooterContainer = self.wndMain:FindChild("Footer")

	self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):DestroyChildren()
	self.wndBonePreviewItem = nil
	self.tCustomizationCosts = {}
	self.tChangedBones = {}
	self:GetCharacterInfo()
	
	for idx, tBone in pairs(self.arCharacterBones) do
		self.tPreviousBones[tBone.sliderId] = tBone.value
	end
	
	for idx, tOption in pairs(self.arCurrentCustomizationOptions) do
		self.tPreviousOptions[tOption.sliderId] = tOption.valueIdx
	end
	
	if self.idSelectedCategory and self.tOptionWindows[self.idSelectedCategory] then
		local wndHeaderBtn = self.tOptionWindows[self.idSelectedCategory].wndHeader:FindChild("CategorySelectBtn")
		wndHeaderBtn:SetCheck(false)
		self:OnCategoryUncheck(wndHeaderBtn, wndHeaderBtn)
	end
	
	for idx, tWindowInfo in pairs(self.tOptionWindows) do
		tWindowInfo.wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(false)
	end
	
	self.wndMain:FindChild("RightContent:PurchaseConfirmFlash"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self:ToggleOverlay(ktOverlayTypes.Purchase, false)

	self:UpdateCost()
	self.wndMain:Close()
end

function CharacterCustomization:OnPurchaseCancel(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Purchase, false)
end

-----------------------------------------------------------------------------------------------
-- Close Confirmation
-----------------------------------------------------------------------------------------------
function CharacterCustomization:OnWindowClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.arCharacterBones = {}
	self.arCurrentCustomizationOptions = {}
	
	self.tPreviousBones = {}
	self.tPreviousOptions = {}
	self.tOptionWindows = {}
	self.tBoneWindows = {}
	self.tChangedBones = {}
	
	self.tPreviousBonesHolder = {}
	
	self.tCustomizationCosts = {}
	
	self.wndBonePreviewItem = nil
	self.idSelectedCategory = nil

	if self.wndMain then
		self:UndoAll()
		self.wndMain:Destroy()
		self.wndMain = nil
		self.wndPreview = nil
	end
	
	for idx, tCategory in pairs(self.arCurrentCustomizationOptions) do
		tCategory.valueIdx = self.tPreviousOptions[tCategory.sliderId]
	end

	Event_CancelDyeWindow()
end

function CharacterCustomization:OnCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local arChanges = self.wndMain and self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):GetChildren() or {}
	
	if self.wndMain and not self.wndMain:FindChild("ConfirmationOverlay"):IsShown() and (arChanges and #arChanges > 0 or self:CheckForBoneChanges()) then
		self:ToggleOverlay(ktOverlayTypes.Cancel, true)
	else
		self.wndMain:Close()
	end
end

function CharacterCustomization:OnCloseConfirm(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Cancel, false)
	self.wndMain:Close()
end

function CharacterCustomization:OnCloseCancel(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Cancel, false)
end

function CharacterCustomization:OnHideDye()
	if self.wndMain ~= nil then
		self.wndMain:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- Costume Window Controls
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnSheatheCheck(wndHandler, wndControl)
	self.wndPreview:SetSheathed(wndHandler:IsChecked())
end

---------------------------------------------------------------------------------------------------
-- Save/Load Code window
---------------------------------------------------------------------------------------------------

function CharacterCustomization:OnSaveLoadBtn( wndHandler, wndControl)
	local wndSaveLoadForm = self.wndMain:FindChild("ConfirmationOverlay:CharacterCode")
	self:ToggleOverlay(ktOverlayTypes.Code, true)
	wndSaveLoadForm:FindChild("EditBox"):SetText(self.wndPreview:GetSliderCodes())
end

function CharacterCustomization:OnLoadCode(wndHandler, wndControl)
	local wndSaveLoadForm = self.wndMain:FindChild("ConfirmationOverlay:CharacterCode")
	
	local strCodes = wndSaveLoadForm:FindChild("CodeFraming:EditBox"):GetText()
	local tResults = self.wndPreview:SetBySliderCodes(strCodes)
	
	local bFailed = false
	local strErrorText = ""
	
	if not tResults then
		strErrorText = Apollo.GetString("Pregame_InvalidCode")
		wndSaveLoadForm:FindChild("CodeErrorText"):SetText(strErrorText)
		return
	end
	
	if tResults.bUnsupportedVersion then
		strErrorText = Apollo.GetString("Pregame_OutdatedCode")
		wndSaveLoadForm:FindChild("CodeErrorText"):SetText(strErrorText)
		return
	end
	
	if tResults.bFactionDoesntMatch then
		bFailed = true
		strErrorText = strErrorText .. ktFactionStrings[tResults.nFaction] .. "    "
	end
	
	if tResults.bRaceDoesntMatch then
		bFailed = true
		strErrorText = strErrorText .. ktRaceStrings[tResults.nRace] .. "    "
	end
	
	if tResults.bGenderDoesntMatch then
		bFailed = true
		strErrorText = strErrorText .. ktGenderStrings[tResults.nGender]
	end
	
	if not bFailed then
		self:ToggleOverlay(ktOverlayTypes.Code, false)
		self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):DestroyChildren()
		self.tCustomizationCosts = {}
		self.tChangedBones = {}
		self.wndBonePreviewItem = nil
		self:ToggleOverlay(ktOverlayTypes.Code)
		self:GetCharacterInfo()
		
		for idx, tCategoryInfo in pairs(self.arCurrentCustomizationOptions) do
			if tCategoryInfo.valueIdx ~= self.tPreviousOptions[tCategoryInfo.sliderId] then
				local wndCostPreview = Apollo.LoadForm(self.xmlDoc, "PreviewLineItem", self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"), self)
				local monCost = self.wndPreview:GetCostForCustomizationSelection(tCategoryInfo.sliderId, tCategoryInfo.values[tCategoryInfo.valueIdx])
				wndCostPreview:FindChild("ListItemName"):SetText(tCategoryInfo.name)
				wndCostPreview:FindChild("UndoBtn"):SetData(tCategoryInfo.sliderId)
				wndCostPreview:FindChild("CashWindow"):SetAmount(monCost, true)
				self.tCustomizationCosts[tCategoryInfo.sliderId] = {strName = tCategoryInfo.name, monCost = monCost, wndPreview = wndCostPreview}
				self.tOptionWindows[tCategoryInfo.sliderId].wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(true)
			else
				self.tOptionWindows[tCategoryInfo.sliderId].wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(false)
			end
		end
		
		for idx, tBoneInfo in pairs(self.arCharacterBones) do
			if self.tBoneWindows.tSliders[tBoneInfo.sliderId] then
				self.tBoneWindows.tSliders[tBoneInfo.sliderId]:FindChild("SliderContainer:SliderBar"):SetValue(tBoneInfo.value)
				self.tBoneWindows.tSliders[tBoneInfo.sliderId]:FindChild("SliderContainer:SliderValue"):SetText(string.format("%.2f", tBoneInfo.value))
			end
			
			self.tChangedBones[tBoneInfo.sliderId] = self.tPreviousBones[tBoneInfo.sliderId] ~= tBoneInfo.value
		end
		
		local bBonesChanged = self:CheckForBoneChanges()
		
		if bBonesChanged then
			self.wndBonePreviewItem = Apollo.LoadForm(self.xmlDoc, "PreviewLineItem", self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"), self)
			self.wndBonePreviewItem:FindChild("ListItemName"):SetText(Apollo.GetString("CharacterCustomize_CustomizeFace"))
			self.wndBonePreviewItem:FindChild("CashWindow"):SetAmount(self.wndPreview:GetCostForBoneChanges(), true)
			self.wndBonePreviewItem:FindChild("UndoBtn"):SetData(-1)
		end
		
		self.tBoneWindows.wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(bBonesChanged)
		self:ReloadOpenCategory()
		self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):ArrangeChildrenVert()
		self:UpdateCost()
		self:ResizePreview()
	else
		wndSaveLoadForm:FindChild("CodeErrorText"):SetText(strErrorText)
	end		
end

function CharacterCustomization:OnCancelLoad(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Code, false)
end

-----------------------------------------------------------------------------------------------
-- Helpers?
-----------------------------------------------------------------------------------------------

function CharacterCustomization:ToggleOverlay(eConfirmationType, bShow)
	local wndOverlay = self.wndMain:FindChild("ConfirmationOverlay")
		
	wndOverlay:Show(bShow)
	wndOverlay:FindChild("PurchaseConfirmation"):Show(eConfirmationType == ktOverlayTypes.Purchase and bShow)
	wndOverlay:FindChild("CancelConfirmation"):Show(eConfirmationType == ktOverlayTypes.Cancel and bShow)
	wndOverlay:FindChild("CharacterCode"):Show(eConfirmationType == ktOverlayTypes.Code and bShow)
	
	local wndFooter = self.wndMain:FindChild("Footer")
	wndFooter:FindChild("CashBuyBtn"):Enable(not bShow)
	wndFooter:FindChild("PurchaseServiceTokens"):Enable(not bShow)
	
	wndFooter:FindChild("UndoAllBtn"):Enable(not bShow)
	wndFooter:FindChild("CostPreview:ToggleFlyout"):Enable(not bShow)
	self.wndMain:FindChild("PreviewChangesFlyout"):Show(false)
	
	if bShow and eConfirmationType == ktOverlayTypes.Purchase then
		wndOverlay:FindChild("ConfirmPurchaseBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.CommitCustomizationChanges, self.wndPreview, false)
	end
end

function CharacterCustomization:UpdateCost()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local monCostServiceTokens = self.wndPreview:GetTotalCustomizationCost(true)
	local wndFooter = self.wndMain:FindChild("Footer")
	local wndPurchaseServiceTokens = wndFooter:FindChild("PurchaseServiceTokens")
	self:HelperDrawCostBtn(wndPurchaseServiceTokens, monCostServiceTokens)
	
	wndPurchaseServiceTokens:SetData(monCostServiceTokens)

	local wndSubmit = wndFooter:FindChild("CashBuyBtn")
	local monCost = self.wndPreview:GetTotalCustomizationCost(false)
	self:HelperDrawCostBtn(wndSubmit, monCost)
	wndSubmit:SetData({monCost = monCost})
end

function CharacterCustomization:HelperDrawCostBtn(wndBtn, monCost)
	local wndCash = wndBtn:FindChild("TotalCost")
	wndCash:SetAmount(monCost)

	local bServiceToken = monCost:GetAccountCurrencyType() ~= 0
	local bHasChanges = monCost:GetAmount() > 0
	local bCanBuy = self.wndPreview and bHasChanges and 
		(monCost:GetMoneyType() == Money.CodeEnumCurrencyType.Credits and monCost:GetAmount() <= GameLib.GetPlayerCurrency():GetAmount() or monCost:GetAmount() <= AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken):GetAmount())

	local strColor = "UI_WindowTextDefault"
	if not bHasChanges then
		strColor = "ConTrivial"
	elseif not bCanBuy then
		strColor = "UI_WindowTextRed"
	end
	wndCash:SetTextColor(strColor)

	local nHalfDisplayWidth = wndCash:GetDisplayWidth() / 2
	local nLeft, nTop, nRight, nBottom = wndCash:GetAnchorOffsets()
	wndCash:SetAnchorOffsets(-nHalfDisplayWidth, nTop, nHalfDisplayWidth, nBottom)
	wndBtn:Enable(bHasChanges and (bCanBuy or bServiceToken))
end

function CharacterCustomization:ResizeTree()
	local wndLeftScroll = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer")
	local arHeaders = wndLeftScroll:GetChildren()
	local nHeaderHeight = arHeaders[1]:GetHeight()
	local nOpenIndex = nil

	for idx, wndCategory in pairs(arHeaders) do
		if wndCategory:GetName() ~= "CodeCategoryHeader" then
			local wndOptionContainer = wndCategory:FindChild("GroupContents")
			local wndTopButton = wndCategory:FindChild("CategorySelectBtn")
			local nCurrentCategoryOffset = 0
			
			if wndTopButton:IsChecked() and wndOptionContainer:IsShown() then
				local arOptions = wndOptionContainer:GetChildren()
				
				--Customization options are treated differently than Bone options
				if #arOptions > 0 then
					if arOptions[1]:GetName() == "OptionItem" then
						nCurrentCategoryOffset = arOptions[1]:GetHeight() * (math.ceil(#arOptions / 2))
					else
						nCurrentCategoryOffset = arOptions[1]:GetHeight() * #arOptions
					end

					if nCurrentCategoryOffset > 0 then
						nCurrentCategoryOffset = nCurrentCategoryOffset + 6
					end
					
					nOpenIndex = idx
				end
			end

			local nLeft, nTop, nRight, nBottom = wndOptionContainer:GetAnchorOffsets()
			wndOptionContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nCurrentCategoryOffset)
			wndOptionContainer:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
			
			local tOffset = wndCategory:GetOriginalLocation():ToTable().nOffsets
			wndCategory:SetAnchorOffsets(tOffset[1], tOffset[2], tOffset[3], tOffset[4] + nCurrentCategoryOffset)
		end
	end

	wndLeftScroll:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	if nOpenIndex then
		local nVScrollRange = wndLeftScroll:GetVScrollRange()
		local nHeaderTop = nHeaderHeight * (nOpenIndex - 1)
		wndLeftScroll:SetVScrollPos(nHeaderTop < nVScrollRange and nHeaderTop or nVScrollRange)
	end
end

function CharacterCustomization:CheckForBoneChanges()
	local bBonesChanged = false
	for idx, bHasChanged in pairs(self.tChangedBones) do
		if bHasChanged then
			bBonesChanged = true
		end
	end
	
	if self.tBoneWindows.wndHeader then
		self.tBoneWindows.wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(bBonesChanged)

		--Find the Face Style Header and show or hide the Bone clear Icon.
		for nIdCategory, bValue  in pairs (ktFaceSliderIds) do
			local tHeaderData = self.tOptionWindows[nIdCategory]
			if tHeaderData then
				tHeaderData.wndHeader:FindChild("BoneClearIcon"):Show(bBonesChanged)
			end
		end
	end
	
	return bBonesChanged
end

function CharacterCustomization:ReloadOpenCategory()
	if self.idSelectedCategory then
		local arCategoryWindows = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):GetChildren()
		local wndOpenHeader = nil
		
		for idx, wndHeader in pairs(arCategoryWindows) do
			if wndHeader:FindChild("CategorySelectBtn"):GetData() == self.idSelectedCategory then
				wndOpenHeader = wndHeader
			end
		end
		
		if wndOpenHeader then
			self:LoadCustomizationOptions(wndOpenHeader, wndOpenHeader:GetData())
			wndOpenHeader:FindChild("GroupContents"):Show(true)
		end
	end
end

function CharacterCustomization:OnGenerateIconTooltip(wndHandler, wndControl)
	Tooltip.GetItemTooltipForm(self, wndControl, Item.GetDataFromId(knTokenItemId), {})
end

function CharacterCustomization:UndoAll()
	if not self.wndMain then
		return
	end

	for idx, tInfo in pairs(self.tCustomizationCosts) do
		local wndOptionUndo = tInfo.wndPreview:FindChild("UndoBtn")
		self:OnOptionUndo(wndOptionUndo, wndOptionUndo)
	end
	
	if self.wndBonePreviewItem then
		local wndOptionUndo = self.wndBonePreviewItem:FindChild("UndoBtn")
		self:OnOptionUndo(wndOptionUndo, wndOptionUndo)
	end
end

-- Done to redraw characters
function CharacterCustomization:ResetTabs()
	if self.idSelectedCategory and self.tOptionWindows[self.idSelectedCategory] then
		local wndHeaderBtn = self.tOptionWindows[self.idSelectedCategory].wndHeader:FindChild("CategorySelectBtn")
		wndHeaderBtn:SetCheck(false)
		self:OnCategoryUncheck(wndHeaderBtn, wndHeaderBtn)
	end
end

function CharacterCustomization:OnHideHelm()
	self.bHideHelm = true
	self:ReloadOpenCategory()
	self.wndPreview:RemoveItem(GameLib.CodeEnumItemSlots.Head)
end

function CharacterCustomization:OnRestoreHelm()
	self.bHideHelm = false
	self:ReloadOpenCategory()
	self.wndPreview:SetItem(self.itemDisplayedHelm)
end

function CharacterCustomization:OnReloadPreviewWindow()
	for idx, tOption in pairs(self.arCurrentCustomizationOptions) do
		self.wndPreview:SetLook(tOption.sliderId, tOption.values[self.tPreviousOptions[tOption.sliderId]])
		self.wndPreview:SetLook(tOption.sliderId, tOption.values[tOption.valueIdx])
	end

	for idx, tOption in pairs(self.arCharacterBones) do
		self.wndPreview:SetBone(tOption.sliderId, tOption.value)
	end
end

-----------------------------------------------------------------------------------------------
-- CharacterCustomization Instance
-----------------------------------------------------------------------------------------------
local CharacterCustomizationInst = CharacterCustomization:new()
CharacterCustomizationInst:Init()
