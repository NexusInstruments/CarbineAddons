-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront/AddFunds.lua
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "AccountItemLib"
require "RewardTrackLib"
require "PetCustomizationLib"
require "GameLib"
require "Item"
require "Money"
require "RewardTrack"
require "PetFlair"
require "PetCustomization"
require "Unit"
require "Tooltip"
require "WindowLocation"
require "Sound"

local AddFunds = {} 

function AddFunds:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tDialogWndRefs = {}
	o.tFundsWndRefs = {}
	
	o.ktErrorMessages =
	{
		[StorefrontLib.CodeEnumStoreError.CatalogUnavailable] = Apollo.GetString("Storefront_ErrorCatalogUnavailable"),
		[StorefrontLib.CodeEnumStoreError.StoreDisabled] = Apollo.GetString("Storefront_ErrorStoreDisabled"),
		[StorefrontLib.CodeEnumStoreError.InvalidOffer] = Apollo.GetString("Storefront_ErrorInvalidOffer"),
		[StorefrontLib.CodeEnumStoreError.InvalidPrice] = Apollo.GetString("Storefront_ErrorInvalidPrice"),
		[StorefrontLib.CodeEnumStoreError.GenericFail] = Apollo.GetString("Storefront_ErrorGenericFail"),
		[StorefrontLib.CodeEnumStoreError.PurchasePending] = Apollo.GetString("Storefront_ErrorPurchasePending"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CartFraudFailure] = Apollo.GetString("Storefront_ErrorTransactionFailureContract"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CartPaymentFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InvalidCCExpirationDate] = Apollo.GetString("Storefront_ErrorCardExpired"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InvalidCreditCardNumber] = Apollo.GetString("Storefront_ErrorInvalidCard"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditCardExpired] = Apollo.GetString("Storefront_ErrorCardDeclinedExpired"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditCardDeclined] = Apollo.GetString("Storefront_ErrorCardDeclined"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditFloorExceeded] = Apollo.GetString("Storefront_ErrorCardLimits"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InventoryStatusFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_PaymentPostAuthFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_SubmitCartFailed] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PurchaseVelocityLimit] = Apollo.GetString("Storefront_ErrorVelocityFailure"),
	}
	
    return o
end

function AddFunds:Init()
    Apollo.RegisterAddon(self)
end

function AddFunds:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AddFunds.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function AddFunds:OnDocumentReady()
	Apollo.RegisterEventHandler("StoreCatalogReady", "OnStoreCatalogReady", self)
	
	-- Store UI Events
	Apollo.RegisterEventHandler("ShowDialog", "OnShowDialog", self)
	Apollo.RegisterEventHandler("CloseDialog", "OnCloseDialog", self)
	Apollo.RegisterEventHandler("ShowNeedsFunds", "OnShowNeedsFunds", self)
	Apollo.RegisterEventHandler("CloseNeedsFunds", "OnCloseNeedsFunds", self)
end



function AddFunds:OnStoreCatalogReady()
	if self.tDialogWndRefs.wndMain ~= nil and self.tDialogWndRefs.wndMain:IsValid() and self.tDialogWndRefs.wndMain:IsShown() then
		self:BuildFundsPackages()
		self.tDialogWndRefs.wndContainer:SetVScrollPos(0)
	end
	
	if self.tFundsWndRefs.wndNeedsFunds ~= nil and self.tFundsWndRefs.wndNeedsFunds:IsValid() and (self.tFundsWndRefs.wndNeedsFunds:IsShown() or self.tFundsWndRefs.wndNeedsFundsNoSource:IsShown()) then
		local arFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
		self.tFundsWndRefs.wndNeedsFunds:Show(#arFundPackages > 0)
		self.tFundsWndRefs.wndNeedsFundsNoSource:Show(#arFundPackages == 0)
		
		if #arFundPackages > 0 then
			self:PurchaseNeedMoreFunds()
			self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn:Enable(false)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Dialog
-----------------------------------------------------------------------------------------------

function AddFunds:OnCloseDialog()
	if self.tDialogWndRefs.wndMain ~= nil and self.tDialogWndRefs.wndMain:IsValid() then
		self.tDialogWndRefs.wndMain:Show(false)
	end
end

function AddFunds:OnShowDialog(strDialogName, wndParent)
	if strDialogName ~= "Funds" then
		if self.tDialogWndRefs.wndMain ~= nil and self.tDialogWndRefs.wndMain:IsValid() then
			self.tDialogWndRefs.wndMain:Show(false)
		end
		return
	end
	
	self:OnOpenAddFundsDialog(wndParent)
end

function AddFunds:OnOpenAddFundsDialog(wndParent)
	if self.tDialogWndRefs.wndMain == nil or not self.tDialogWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "AddFundsDialog", wndParent, self)
		self.tDialogWndRefs.wndMain = wndMain
		self.tDialogWndRefs.wndParent = wndParent
		
		self.tDialogWndRefs.wndFraming = wndMain:FindChild("Framing")
		
		-- Choice
		self.tDialogWndRefs.wndChoice = wndMain:FindChild("Choice")
		self.tDialogWndRefs.wndCCOnFile = wndMain:FindChild("Choice:CCOnFile")
		self.tDialogWndRefs.wndContainer = wndMain:FindChild("Choice:CCOnFile:CurrencyChoiceContainer")
		self.tDialogWndRefs.wndFinalizeBtn = wndMain:FindChild("Choice:CCOnFile:FinalizeBtn")
		self.tDialogWndRefs.wndNoCCOnFile = wndMain:FindChild("Choice:NoCCOnFile")
		
		-- Confirmed
		self.tDialogWndRefs.wndConfirmed = wndMain:FindChild("Confirmed")
		self.tDialogWndRefs.wndConfirmedAnimation = wndMain:FindChild("Confirmed:PurchaseConfirmAnimation")
		self.tDialogWndRefs.wndConfirmedAnimationInner = wndMain:FindChild("Confirmed:PurchaseConfirmAnimation:PurchaseConfirmAnimationInner")
	end
	
	self:BuildFundsPackages()
	
	self:ShowHelper(self.tDialogWndRefs.wndChoice)
	self.tDialogWndRefs.wndMain:Show(true)
end

function AddFunds:BuildFundsPackages()
	self.tDialogWndRefs.wndFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupBlue")

	self.tDialogWndRefs.wndContainer:DestroyChildren()
	local tFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
	for idx, tFundPackage in pairs(tFundPackages) do
		local wndFundPackage = Apollo.LoadForm(self.xmlDoc, "AddFundsEntry", self.tDialogWndRefs.wndContainer, self)
		
		local strCurrencyName = self:GetRealCurrencyNameFromEnum(tFundPackage.eRealCurrency)
		
		wndFundPackage:FindChild("Name"):SetText(tFundPackage.strPackageName)
		wndFundPackage:FindChild("Cost"):SetText(String_GetWeaselString("$1n$2c", strCurrencyName, tFundPackage.nPrice))
		wndFundPackage:FindChild("Btn"):SetData(tFundPackage)
	end
	self.tDialogWndRefs.wndContainer:ArrangeChildrenTiles()
	
	self.tDialogWndRefs.wndFinalizeBtn:Enable(false)
	
	self.tDialogWndRefs.wndCCOnFile:Show(#tFundPackages ~= 0)
	self.tDialogWndRefs.wndNoCCOnFile:Show(#tFundPackages == 0)
end

function AddFunds:ShowHelper(wndToShow)
	self.tDialogWndRefs.wndChoice:Show(self.tDialogWndRefs.wndChoice == wndToShow)
	self.tDialogWndRefs.wndConfirmed:Show(self.tDialogWndRefs.wndConfirmed == wndToShow)
end

function AddFunds:OnAddFundsCancelSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self.tDialogWndRefs.wndMain:Show(false)
	self.tDialogWndRefs.wndParent:Show(false)
	
	Event_FireGenericEvent("CloseDialog")
end

function AddFunds:OnAddFundsConfirmedSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self:BuildFundsPackages()
	self:ShowHelper(self.tDialogWndRefs.wndChoice)
end

function AddFunds:OnAddFundsFinalize(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	local promisePurchaseResult = Promise.New()
	PromiseFromGameEvent("StorePurchaseVirtualCurrencyPackageResult", self):Then(function(bSuccess, eError)
		if bSuccess then
			promisePurchaseResult:Resolve()
		else
			promisePurchaseResult:Reject(eError)
		end
	end)
	
	local this = self
	Promise.WhenAll(promisePurchaseResult, PromiseFromGameEvent("AccountCurrencyChanged", self))
	:Catch(function(eError)
		local strMessage
		if this.ktErrorMessages[eError] ~= nil then
			strMessage = this.ktErrorMessages[eError]
		else
			strMessage = Apollo.GetString("Storefront_PurchaseProblemGeneral")
		end
		
		Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedNCoin"), strMessage)
	end)
	:Then(function()
		Event_FireGenericEvent("HideFullDialog")
		self:ShowHelper(self.tDialogWndRefs.wndConfirmed)
		
		this.tDialogWndRefs.wndFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupGreen")
		this.tDialogWndRefs.wndConfirmedAnimation:SetSprite("BK3:UI_BK3_OutlineShimmer_anim_nocycle")
		this.tDialogWndRefs.wndConfirmedAnimationInner:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	end)
	
	Event_FireGenericEvent("RequestFullDialogSpinner", Apollo.GetString("Storefront_PurchaseInProgressThanks"))
	StorefrontLib.PurchaseVirtualCurrencyPackage(tData.nPackageId, tData.nPrice)
end

function AddFunds:OnAddFundsWebSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToAccountSettings()
end

function AddFunds:OnAddFundsFundPackageCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	self.tDialogWndRefs.wndDialogAddFundsFinalizeBtn:SetData(tData)
	self.tDialogWndRefs.wndDialogAddFundsFinalizeBtn:Enable(true)
end

---------------------------------------------------------------------------------------------------
-- Needs Funds
---------------------------------------------------------------------------------------------------

function AddFunds:OnCloseNeedsFunds()
	if self.tFundsWndRefs.wndNeedsFunds ~= nil and self.tFundsWndRefs.wndNeedsFunds:IsValid() then
		self.tFundsWndRefs.wndNeedsFunds:Show(false)
	end
	
	if self.tFundsWndRefs.wndNeedsFundsNoSource ~= nil and self.tFundsWndRefs.wndNeedsFundsNoSource:IsValid() then
		self.tFundsWndRefs.wndNeedsFundsNoSource:Show(false)
	end
end

function AddFunds:OnShowNeedsFunds(wndParent, tData)
	if self.tFundsWndRefs.wndNeedsFunds == nil or not self.tFundsWndRefs.wndNeedsFunds:IsValid() then
		self.tFundsWndRefs.wndParent = wndParent
		
		local wndNeedsFunds = Apollo.LoadForm(self.xmlDoc, "PurchaseNeedsFunds", wndParent, self)
		self.tFundsWndRefs.wndNeedsFunds = wndNeedsFunds
		
		
		self.tFundsWndRefs.wndCenterPurchaseNeedsFunds = wndNeedsFunds
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoiceContainer = wndNeedsFunds:FindChild("SummaryContainer:CurrencyChoice:PackageSelectionBtn:Expander:Container")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander = wndNeedsFunds:FindChild("SummaryContainer:CurrencyChoice:PackageSelectionBtn:Expander")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn = wndNeedsFunds:FindChild("SummaryContainer:CurrencyChoice:PackageSelectionBtn")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCostLabel = wndNeedsFunds:FindChild("SummaryContainer:CostLabel")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCostValue = wndNeedsFunds:FindChild("SummaryContainer:CostValue")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterLabel = wndNeedsFunds:FindChild("SummaryContainer:FundsAfterLabel")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValueNegative = wndNeedsFunds:FindChild("SummaryContainer:FundsAfterValueNegative")	
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue = wndNeedsFunds:FindChild("SummaryContainer:FundsAfterValue")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn = wndNeedsFunds:FindChild("SummaryContainer:FinalizeBtn")
		
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn:AttachWindow(self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander)
	end
	
	if self.tFundsWndRefs.wndNeedsFundsNoSource == nil or not self.tFundsWndRefs.wndNeedsFundsNoSource:IsValid() then
		local wndNeedsFundsNoSource = Apollo.LoadForm(self.xmlDoc, "PurchaseNeedsFundsNoSource", wndParent, self)
		self.tFundsWndRefs.wndNeedsFundsNoSource = wndNeedsFundsNoSource
		
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCC = wndNeedsFundsNoSource
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCItemName = wndNeedsFundsNoSource:FindChild("SectionStack:ItemName")
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCFundsSectionNoneAvailableTitle = wndNeedsFundsNoSource:FindChild("SectionStack:FundsSection:NoneAvailableTitle")		
		self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCFundsSectionNoneAvailable = wndNeedsFundsNoSource:FindChild("SectionStack:FundsSection:NoneAvailable")
		
		local arCurrencyActors =
		{
			{ key = "PremiumCurrency", name = self:GetCurrencyNameFromEnum(AccountItemLib.GetPremiumCurrency()) },
			{ key = "AlternativeCurrency", name = self:GetCurrencyNameFromEnum(AccountItemLib.GetAlternativeCurrency()) }
		}
		
		if StorefrontLib.GetIsPTR() then
			self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCFundsSectionNoneAvailableTitle:SetText(Apollo.GetString("Storefront_PTRNCoinTopupHelperTitle"))
			self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCFundsSectionNoneAvailable:SetText(Apollo.GetString("Storefront_NoCCOnFileHelperPTR"))
		else
			self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCFundsSectionNoneAvailableTitle:SetText(String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyTopupHelperTitle"), unpack(arCurrencyActors)))
			self.tFundsWndRefs.wndCenterPurchaseNeedsFundsNoCCFundsSectionNoneAvailable:SetText(Apollo.GetString("Storefront_NoCCOnFileHelper"))
		end
	end

	self.tFundsWndRefs.wndNeedsFunds:SetData(tData)
	
	local arFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
	self.tFundsWndRefs.wndNeedsFunds:Show(#arFundPackages > 0)
	self.tFundsWndRefs.wndNeedsFundsNoSource:Show(#arFundPackages == 0)
	
	if #arFundPackages > 0 then
		self:PurchaseNeedMoreFunds()
	end
end

function AddFunds:PurchaseNeedMoreFunds()
	local tData = self.tFundsWndRefs.wndNeedsFunds:GetData()
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice

	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	local monAfter = Money.new()
	monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
	monAfter:SetAmount(tData.tPrice.monPrice:GetAmount() - monBalance:GetAmount())
			
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoiceContainer:DestroyChildren()
	local tFundPackages = StorefrontLib.GetVirtualCurrencyPackages()

	for idx, tFundPackage in pairs(tFundPackages) do
		local wndFundPackage = Apollo.LoadForm(self.xmlDoc, "AddFundsEntrySlim", self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoiceContainer, self)
		wndFundPackage:SetData(tFundPackage)
		
		local wndBtn = wndFundPackage:FindChild("Btn")
		wndBtn:SetText(tFundPackage.strPackageName)
		wndBtn:SetData(tFundPackage)
		
		if tFundPackage.nCount < monAfter:GetAmount() then
			wndBtn:Enable(false)
			wndFundPackage:SetTooltip(Apollo.GetString("Storefront_AddFundsSlimDisableTooltip"))
		end
		
		local strCurrencyName = self:GetRealCurrencyNameFromEnum(tFundPackage.eRealCurrency)
		wndFundPackage:FindChild("Cost"):SetText(String_GetWeaselString("$1n$2c", strCurrencyName, tFundPackage.nPrice))
	end
	local nListHeight = self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoiceContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function (wndLeft, wndRight)
		return wndLeft:GetData().nCount < wndRight:GetData().nCount
	end)
	local nOldListHeight = self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoiceContainer:GetHeight()
	
	local nLeft, nTop, nRight, nBottom = self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander:GetAnchorOffsets()
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nListHeight - nOldListHeight)
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)

	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCostLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_TotalCost"), strCurrencyName))
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCostValue:SetAmount(tData.tPrice.monPrice, true)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_Remaining"), strCurrencyName))
	
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue:SetAmount(monAfter, true)
	
	local nWidth = self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue:GetDisplayWidth()
	local nFundsValueRight = math.abs(({self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue:GetAnchorOffsets()})[3]) --3 is the right offset
	local nLeft, nTop, nRight, nBottom = self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValueNegative:GetAnchorOffsets()
	nRight = -nWidth - nFundsValueRight
	nLeft = nRight - self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValueNegative:GetWidth()
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValueNegative:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValueNegative:Show(true)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue:SetTextColor("Reddish")

	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn:SetData(tData)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn:Enable(false)
	local nHeight = self.tFundsWndRefs.wndCenterPurchaseNeedsFunds:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = self.tFundsWndRefs.wndCenterPurchaseRight:GetAnchorOffsets()
	self.tFundsWndRefs.wndCenterPurchaseRight:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn:SetText("")
	self.tFundsWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()
	self.tFundsWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
end

function AddFunds:OnPurchaseNeedsFundsConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice
	local tFundPackage = tData.tFundPackage
	local nCategoryId = tData.nCategoryId
	
	
	local promiseFundsPurchaseResult = Promise.New()
	PromiseFromGameEvent("StorePurchaseVirtualCurrencyPackageResult", self):Then(function(bSuccess, eError)
		if bSuccess then
			promiseFundsPurchaseResult:Resolve()
		else
			promiseFundsPurchaseResult:Reject(eError)
		end
	end)
	
	local promisePurchaseResult = Promise.New()
	PromiseFromGameEvent("StorePurchaseOfferResult", self):Then(function(bSuccess)
		if bSuccess then
			promisePurchaseResult:Resolve()
		else
			promisePurchaseResult:Reject()
		end
	end)
	
	local this = self
	
	Promise.WhenAll(promiseFundsPurchaseResult, PromiseFromGameEvent("AccountCurrencyChanged", self))
	:Catch(function(eError)
		local strMessage
		if this.ktErrorMessages[eError] ~= nil then
			strMessage = this.ktErrorMessages[eError]
		else
			strMessage = Apollo.GetString("Storefront_PurchaseProblemGeneral")
		end
		
		Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedNCoin"), strMessage)
	end)
	:Then(function()
		StorefrontLib.PurchaseOffer(tData.tOfferInfo.nId, tData.tPrice.monPrice, tData.nCategoryId)
	end)
	:WhenAll(promisePurchaseResult, PromiseFromGameEvent("AccountCurrencyChanged", self, 2))
	:Then(function()
		Event_FireGenericEvent("HideFullDialog")
		Event_FireGenericEvent("PurchaseConfirmed", tData)
	end)
	:Catch(function()
		Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedDialogHeader"), Apollo.GetString("Storefront_PurchaseFailedDialogBody"))
		--this.tFundsWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = Storefront.OnStorePurchaseOfferFailureResultAccept })
	end)
	
	Event_FireGenericEvent("RequestFullDialogSpinner", Apollo.GetString("Storefront_PurchaseInProgressThanks"))
	StorefrontLib.PurchaseVirtualCurrencyPackage(tFundPackage.nPackageId, tFundPackage.nPrice)
end

function AddFunds:OnNeedFundsAddFundsFundPackageCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander:Show(false)
	
	local tFundPackage = wndControl:GetData()
	local tData = self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn:GetData()
	tData.tFundPackage = tFundPackage
	
	local strBtnText = String_GetWeaselString("$3n - $1n$2c", self:GetRealCurrencyNameFromEnum(tFundPackage.eRealCurrency), tFundPackage.nPrice, tFundPackage.strPackageName)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn:SetText(strBtnText)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValueNegative:Show(false)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue:SetTextColor("UI_TextHoloBodyCyan")


	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	local monAfter = Money.new()
	monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
	monAfter:SetAmount(monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount() + tFundPackage.nCount)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFundsAfterValue:SetAmount(monAfter, true)
	
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn:SetData(tData)
	self.tFundsWndRefs.wndCenterPurchaseNeedsFundsFinalizeBtn:Enable(true)
end

function AddFunds:OnPurchaseNeedsFundsNoCCWebSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToAccountSettings()
end

function AddFunds:OnContinueShoppingSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	Event_FireGenericEvent("RequestContinueShopping")
end



function AddFunds:GetRealCurrencyNameFromEnum(eRealCurrency)
	if eRealCurrency == StorefrontLib.CodeEnumRealCurrency.USD then
		return Apollo.GetString("Storefront_ExternalCurrency_USD")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.GBP then
		return  Apollo.GetString("Storefront_ExternalCurrency_GBP")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.EUR then
		return  Apollo.GetString("Storefront_ExternalCurrency_EUR")
	end
	
	return "?"
end

function AddFunds:GetCurrencyNameFromEnum(eCurrencyType)
	if eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
		if StorefrontLib.GetIsPTR() then
			return "PTR NCoin"
		end
	end

	local monTemp = Money.new()
	monTemp:SetAccountCurrencyType(eCurrencyType)
	return String_GetWeaselString(monTemp:GetDenomInfo()[1].strName)
end

local AddFundsInst = AddFunds:new()
AddFundsInst:Init()
