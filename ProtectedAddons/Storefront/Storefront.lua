-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront
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

local Promise = {}

local PromisePending = 1
local PromiseFulfilled = 2
local PromiseRejected = 3

function Promise:new(o)
	o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
	o.eState = PromisePending
	o.arFulfilledCallbacks = {}
	o.arRejectedCallbacks = {}
	o.tValue = nil

    return o
end
function Promise:Fulfill(...)
	if self.eState == PromisePending then
		self.tValue = {...}
		self.eState = PromiseFulfilled
		
		for idx, fnCallback in pairs(self.arFulfilledCallbacks) do
			fnCallback(...)
		end
		
		self.arFulfilledCallbacks = {}
		self.arRejectedCallbacks = {}
	end
end
function Promise:Reject(...)
	if self.eState == PromisePending then
		self.tValue = {...}
		self.eState = PromiseRejected
		
		for idx, fnCallback in pairs(self.arRejectedCallbacks) do
			fnCallback(...)
		end
		
		self.arFulfilledCallbacks = {}
		self.arRejectedCallbacks = {}
	end
end
function Promise:Then(fnFulfilled, fnRejected)
	if fnFulfilled ~= nil then
		if self.eState == PromiseFulfilled then
			if self.tValue ~= nil then
				fnFulfilled(unpack(self.tValue))
			else
				fnFulfilled(nil)
			end
		elseif self.eState == PromisePending then
			table.insert(self.arFulfilledCallbacks, fnFulfilled)
		end
	end
	if fnRejected ~= nil then
		if self.eState == PromiseRejected then
			if self.tValue ~= nil then
				fnRejected(unpack(self.tValue))
			else
				fnRejected(nil)
			end
		elseif self.eState == PromisePending then
			table.insert(self.arRejectedCallbacks, fnRejected)
		end
	end
	
	return self
end
function Promise:Always(fnAlways)
	return self:Then(fnAlways, fnAlways)
end


local function AddGameEventCallback(strEventName, tSelf, fnCallback)
	if tSelf[strEventName] == nil then
		local tMetatable = { }
		tMetatable.__call = function(tTable, tCallSelf, ...)
			for idx, fnCallback in pairs(tTable) do
				fnCallback(...)
			end
		end
		tSelf[strEventName] = setmetatable({ }, tMetatable)
		Apollo.RegisterEventHandler(strEventName, strEventName, tSelf)
	end
	
	tSelf[strEventName][fnCallback] = fnCallback
end

local function RemoveGameEventCallback(strEventName, tSelf, fnCallback)
	if tSelf[strEventName] ~= nil then
		tSelf[strEventName][fnCallback] = nil
	end
end

local function PromiseFromGameEvent(strEventName, tSelf)
	local tSavedSelf = tSelf
	local tPromise = Promise:new()
	
	local fnCallback = function(...)
		tPromise:Fulfill(...)
	end
	
	AddGameEventCallback(strEventName, tSavedSelf, fnCallback)
	
	return tPromise:Always(function()
		RemoveGameEventCallback(strEventName, tSavedSelf, fnCallback)
	end)
end

local function WhenAllHelper(arArgs)
	local tDeferredPromise = Promise:new()
	local nTotal = #arArgs
	local nCompleted = 0
	local nRejected = 0
	local tReturnValues = {}
	
	local fnCheckComplete = function()
		if nCompleted == nTotal then
			if nRejected == 0 then
				tDeferredPromise:Fulfill(unpack(tReturnValues))
			else
				tDeferredPromise:Reject(unpack(tReturnValues))
			end
		end
	end
	
	for idx, oArg in pairs(arArgs) do
		if type(oArg) == "table" and getmetatable(oArg) == Promise then
			oArg:Always(function(...)
				nCompleted = nCompleted + 1
				if oArg.eState == PromiseRejected then
					nRejected = nRejected + 1
				end
				tReturnValues[idx] = {...}
				fnCheckComplete()
			end)
		else
			tReturnValues[idx] = {oArg}
			nCompleted = nCompleted + 1
		end
		fnCheckComplete()
	end
	
	return tDeferredPromise
end

local function WhenAll(...)
	return WhenAllHelper({...})
end


local Storefront = {} 

function Storefront:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	o.tNavCategoryWndRefs = {}
	o.tNavSubCategoryWndRefs = {}
	o.knEscapeKey = 27
	o.knNavigationTextPadding = 10
	o.knNavigationSubTextPadding = 3
	o.knLoyaltyPointProgressUpdateRate = 0.05
	o.bUpdateHistory = false
	
	o.karSignatureData =
	{
		{strFeature = Apollo.GetString("Storefront_SignatureAuctionHouse"), arFree = {Apollo.GetString("Storefront_SignatureAuctionHouseFreeA"), Apollo.GetString("Storefront_SignatureAuctionHouseFreeB")}, arSignature = {Apollo.GetString("Storefront_SignatureAuctionHouseSigA"), Apollo.GetString("Storefront_SignatureAuctionHouseSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureChallenges"), arFree = {Apollo.GetString("Storefront_SignatureChallengesFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureChallengesSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCircles"), arFree = {Apollo.GetString("Storefront_SignatureCirclesFreeA"), Apollo.GetString("Storefront_SignatureCirclesFreeB")}, arSignature = {Apollo.GetString("Storefront_SignatureCirclesSigA"), Apollo.GetString("Storefront_SignatureCirclesSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCircuitCrafting"), arFree = {Apollo.GetString("Storefront_SignatureCircuitCraftingFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureCircuitCraftingSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCommodities"), arFree = {Apollo.GetString("Storefront_SignatureCommoditiesFreeA"), Apollo.GetString("Storefront_SignatureCommoditiesFreeB")}, arSignature = {Apollo.GetString("Storefront_SignatureCommoditiesSigA"), Apollo.GetString("Storefront_SignatureCommoditiesSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCoordCrafting"), arFree = {Apollo.GetString("Storefront_SignatureCoordCraftingFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureCoordCraftingSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCurrency"), arFree = {Apollo.GetString("Storefront_SignatureCurrencyFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureCurrencySigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureGathering"), arFree = {Apollo.GetString("Storefront_SignatureGatheringFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureGatheringSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureGuilds"), arFree = {Apollo.GetString("Storefront_SignatureGuildsFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureGuildsSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureHoliday"), arFree = {Apollo.GetString("Storefront_SignatureHolidayFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureHolidaySigA")}},
		{strFeature = Apollo.GetString("CRB_OmniBits"), arFree = {Apollo.GetString("Storefront_SignatureOmnibitsFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureOmnibitsSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureQueue"), arFree = {Apollo.GetString("Storefront_SignatureQueueFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureQueueSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureArenaTeams"), arFree = {Apollo.GetString("Storefront_SignatureArenaTeamsFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureArenaTeamsSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureReputation"), arFree = {Apollo.GetString("Storefront_SignatureReputationFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureReputationSigA"), Apollo.GetString("Storefront_SignatureReputationSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureRestXp"), arFree = {Apollo.GetString("Storefront_SignatureRestXpFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureRestXpSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureWake"), arFree = {Apollo.GetString("Storefront_SignatureWakeFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureWakeSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureWarparties"), arFree = {Apollo.GetString("Storefront_SignatureWarpartiesFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureWarpartiesSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureXp"), arFree = {Apollo.GetString("Storefront_SignatureXpFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureXpSigA")}},
	}
	
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
	
	o.ktFlags =
	{
		[StorefrontLib.CodeEnumStoreDisplayFlag.New] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemGreen", strTooltip = Apollo.GetString("Storefront_OfferFlagNewTooltip") },
		[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemYellow", strTooltip = Apollo.GetString("Storefront_OfferFlagRecommendedTooltip") },
		[StorefrontLib.CodeEnumStoreDisplayFlag.Popular] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemRed", strTooltip = Apollo.GetString("Storefront_OfferFlagPopularTooltip") },
		[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemPurple", strTooltip = Apollo.GetString("Storefront_OfferFlagLimitedTimeTooltip") }
	}
	
	o.ktClassAnimation =
	{
		[GameLib.CodeEnumClass.Spellslinger] = { eStand = StorefrontLib.CodeEnumModelSequence.PistolsStand, eReady = StorefrontLib.CodeEnumModelSequence.PistolsReady },
		[GameLib.CodeEnumClass.Stalker] = { eStand = StorefrontLib.CodeEnumModelSequence.ClawsStand, eReady = StorefrontLib.CodeEnumModelSequence.ClawsReady },
		[GameLib.CodeEnumClass.Engineer] = { eStand = StorefrontLib.CodeEnumModelSequence.TwoHGunStand, eReady = StorefrontLib.CodeEnumModelSequence.HeavyGunReady },
		[GameLib.CodeEnumClass.Warrior] = { eStand = StorefrontLib.CodeEnumModelSequence.TwoHStand, eReady = StorefrontLib.CodeEnumModelSequence.TwoHReady },
		[GameLib.CodeEnumClass.Esper] = { eStand = StorefrontLib.CodeEnumModelSequence.DefaultStand, eReady = StorefrontLib.CodeEnumModelSequence.EsperReady },
		[GameLib.CodeEnumClass.Medic] = { eStand = StorefrontLib.CodeEnumModelSequence.ShockPaddlesStand, eReady = StorefrontLib.CodeEnumModelSequence.ShockPaddlesReady },
	}
	
	o.knPurchaseOfferResultsExpected = 2
	
	o.ktSoundLoyaltyMTXCosmicRewardsUnlock =
	{
		[1] = Sound.PlayUIMTXCosmicRewardsUnlock01,
		[2] = Sound.PlayUIMTXCosmicRewardsUnlock02,
		[3] = Sound.PlayUIMTXCosmicRewardsUnlock03,
		[4] = Sound.PlayUIMTXCosmicRewardsUnlock04,
		[5] = Sound.PlayUIMTXCosmicRewardsUnlock05,
	}
	
	o.ktSoundLoyaltyMTXLoyaltyBarHover =
	{
		[false] = Sound.PlayUIMTXLoyaltyBarTierHover,
		[true] = Sound.PlayUIMTXLoyaltyBarTierHoverTopTier,
	}
	
    return o
end

function Storefront:Init()
    Apollo.RegisterAddon(self)
end

function Storefront:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Storefront.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.ktSlotMapping =
	{
		[Item.CodeEnumItemType.HoverboardFront] = PetCustomizationLib.HoverboardSlot.Front,
		[Item.CodeEnumItemType.HoverboardBack] = PetCustomizationLib.HoverboardSlot.Back,
		[Item.CodeEnumItemType.HoverboardSides] = PetCustomizationLib.HoverboardSlot.Sides,
		[Item.CodeEnumItemType.MountFront] = PetCustomizationLib.MountSlot.Front,
		[Item.CodeEnumItemType.MountBack] = PetCustomizationLib.MountSlot.Back,
		[Item.CodeEnumItemType.MountLeft] = PetCustomizationLib.MountSlot.Left,
		[Item.CodeEnumItemType.MountRight] = PetCustomizationLib.MountSlot.Right,
	}
end

function Storefront:OnDocumentReady()
	Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self)
	Apollo.RegisterEventHandler("OpenStore", "OnOpenStore", self)
	Apollo.RegisterEventHandler("OpenStoreLinkSingle", "OnOpenStoreLinkSingle", self)
	Apollo.RegisterEventHandler("OpenStoreLinkCategory", "OnOpenStoreLinkCategory", self)
	Apollo.RegisterEventHandler("OpenSignature", "OnOpenSignature", self)
	Apollo.RegisterEventHandler("StoreClosed", "OnStoreClosed", self)
	
	Apollo.RegisterEventHandler("StoreCatalogReady", "OnStoreCatalogReady", self)
	Apollo.RegisterEventHandler("StorePurchaseHistoryReady", "OnHistoryReady", self)
	Apollo.RegisterEventHandler("StoreRealCurrencyPurchaseHistoryReady", "OnHistoryReady", self)
	Apollo.RegisterEventHandler("StoreError", "OnStoreError", self)
	Apollo.RegisterEventHandler("StoreCatalogUpdated", "OnStoreCatalogUpdated", self)
	
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "OnAccountCurrencyChanged", self)
	Apollo.RegisterEventHandler("AccountPendingItemsUpdate", "OnAccountPendingItemsUpdate", self)
	Apollo.RegisterEventHandler("RewardTrackActive", "OnRewardTrackActive", self)
	Apollo.RegisterEventHandler("RewardTrackUpdated", "OnRewardTrackUpdated", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", "OnEntitlementUpdate", self)

	self.timerBannerRotation = ApolloTimer.Create(10, true, "OnBannerRotationTimer", self)
	self.timerBannerRotation:Stop()
	
	self.timerSearch = ApolloTimer.Create(1.0, false, "OnSearchTimer", self)
	self.timerSearch:Stop()
	
	self.tSortingOptions = {}
	self.nFilterOptions = 0
	self.timerToMax = ApolloTimer.Create(1.0, false, "OnMaximumReached", self)
	self.timerToMax:Stop()

	local wndMain = Apollo.LoadForm(self.xmlDoc, "Layout", nil, self)
	self.tWndRefs.wndMain = wndMain
	
	-- Header
	self.wndHeader = wndMain:FindChild("Header")
	self.wndHeaderOmnibits = wndMain:FindChild("Header:Wallet:Currency:Omnibits")
	self.wndHeaderNCoins = wndMain:FindChild("Header:Wallet:Currency:NCoins")
	self.wndTopUpReminder = wndMain:FindChild("Header:Wallet:TopUpReminder")
	self.wndClaimBtn = wndMain:FindChild("Header:Wallet:ClaimBtn")
	
	-- Loyalty
	self.wndLoyalty = wndMain:FindChild("Header:Loyalty")
	self.wndLoyaltyPercent = wndMain:FindChild("Header:Loyalty:Percent")
	self.wndLoyaltyProgress = wndMain:FindChild("Header:Loyalty:LoyaltyProgress")
	self.wndLoyaltyExpandBtnIcon = wndMain:FindChild("Header:Loyalty:Icon")
	self.wndLoyaltyExpandBtnAnimation = wndMain:FindChild("Header:Loyalty:Animation")
	self.tWndRefs.wndLoyaltyProgressBar = wndMain:FindChild("ModelDialog:Loyalty:Right:ProgressBar:ProgressBar")
	self.tWndRefs.wndLoyaltyPointProgress = wndMain:FindChild("ModelDialog:Loyalty:Right:ProgressBar:LoyaltyPointProgress")
	self.tWndRefs.wndTier = wndMain:FindChild("ModelDialog:Loyalty:Left:Level:TierText")
	self.tWndRefs.wndTierPoints = wndMain:FindChild("ModelDialog:Loyalty:Left:Level:TierPoints")
	self.tWndRefs.wndTierIcon = wndMain:FindChild("ModelDialog:Loyalty:Left:Icon")
	self.tWndRefs.wndTierBody = wndMain:FindChild("ModelDialog:Loyalty:Left:Intro:Body")
	self.tWndRefs.wndNextTierBtn = wndMain:FindChild("ModelDialog:Loyalty:Left:Level:NextTierBtn")
	self.tWndRefs.wndPrevTierBtn = wndMain:FindChild("ModelDialog:Loyalty:Left:Level:PrevTierBtn")
	self.tWndRefs.wndLoyaltyPage = wndMain:FindChild("ModelDialog:Loyalty")
	self.tWndRefs.wndLoyaltyContentContainer = wndMain:FindChild("ModelDialog:Loyalty:Right:ContentContainer")
	
	-- Categories
	self.tWndRefs.wndNavigation = wndMain:FindChild("Navigation")
	
	-- Dialog
	self.tWndRefs.wndModelDialog = wndMain:FindChild("ModelDialog")
	
	-- Purchase
	self.tWndRefs.wndDialogPurchase = wndMain:FindChild("ModelDialog:PurchaseDialog")
	self.tWndRefs.wndDialogPurchaseFraming = wndMain:FindChild("ModelDialog:PurchaseDialog:Framing")
	self.tWndRefs.wndDialogPurchaseLeft = wndMain:FindChild("ModelDialog:PurchaseDialog:Left")
	self.tWndRefs.wndDialogPurchasePreview = wndMain:FindChild("ModelDialog:PurchaseDialog:Left:PreviewFrame")
	self.tWndRefs.wndDialogPurchaseDecor = wndMain:FindChild("ModelDialog:PurchaseDialog:Left:DecorFrame")
	self.tWndRefs.wndDialogPurchasePreviewOnMeBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Left:PreviewOnMeBtn")
	self.tWndRefs.wndDialogPurchasePreviewSheathedBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Left:PreviewSheathedBtn")
	
	-- Purchase Confirm
	self.tWndRefs.wndDialogPurchaseConfirm = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm")
	self.tWndRefs.wndDialogPurchaseConfirmSectionStack = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack")
	self.tWndRefs.wndDialogPurchaseConfirmItemName = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:ItemName")
	self.tWndRefs.wndDialogPurchaseConfirmBannerSection = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:BannerSection")
	self.tWndRefs.wndDialogPurchaseConfirmBannerContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:BannerSection:Container")
	self.tWndRefs.wndDialogPurchaseConfirmDescription = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:Description")
	self.tWndRefs.wndDialogPurchaseConfirmQuantitySection = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdown = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn:Dropdown")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityCostContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn:CostContainer")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityPrice1 = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn:CostContainer:Price1")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityPriceOr = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn:CostContainer:or")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityPrice2 = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn:CostContainer:Price2")
	self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:QuantitySection:QuantityDropdownBtn:Dropdown:DropDownContainer")
	self.tWndRefs.wndDialogPurchaseConfirmVariantSection = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:VariantSection")
	self.tWndRefs.wndDialogPurchaseConfirmVariantContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:VariantSection:Container")
	self.tWndRefs.wndDialogPurchaseConfirmBundleSection = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:BundleSection")
	self.tWndRefs.wndDialogPurchaseConfirmBundleContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SectionStack:BundleSection:Container")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency1Container = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency1 = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:CurrencyBtn:Price")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency1Btn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:CurrencyBtn")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency1DisabledTooltip = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:DisabledTooltip")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency2Container = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency2 = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:CurrencyBtn:Price")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency2Btn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:CurrencyBtn")
	self.tWndRefs.wndDialogPurchaseConfirmCurrency2DisabledTooltip = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:DisabledTooltip")
	self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltip = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:AlertClaimTooltip")
	self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltipBody = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:AlertClaimTooltip:Body")
	self.tWndRefs.wndDialogPurchaseConfirmSummaryContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer")
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterLabel = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:FundsAfterLabel")
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:FundsAfterValueNegative")
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:FundsAfterValue")
	self.tWndRefs.wndDialogPurchaseConfirmNotEnoughOmnibits = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:NotEnoughOmnibits")
	self.tWndRefs.wndDialogPurchaseConfirmNoCurrencySelected = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:NoCurrencySelected")
	self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:FinalizeBtn")
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterBG = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:SummaryContainer:FundsAfterBG")
	self.tWndRefs.wndDialogPurchaseConfirmDisclaimer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirm:Disclaimer")
	
	-- Purchase Confirmed
	self.tWndRefs.wndDialogPurchaseConfirmed = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed")
	self.tWndRefs.wndDialogPurchaseConfirmedSectionStack = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SectionStack")
	self.tWndRefs.wndDialogPurchaseConfirmedItemName = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SectionStack:ItemName")
	self.tWndRefs.wndDialogPurchaseConfirmedDescription = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SectionStack:Description")
	self.tWndRefs.wndDialogPurchaseConfirmedBundleSection = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SectionStack:BundleSection")
	self.tWndRefs.wndDialogPurchaseConfirmedBundleContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SectionStack:BundleSection:Container")
	self.tWndRefs.wndDialogPurchaseConfirmedCostLabel = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SummaryContainer:CostLabel")
	self.tWndRefs.wndDialogPurchaseConfirmedCostValue = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SummaryContainer:CostValue")
	self.tWndRefs.wndDialogPurchaseConfirmedFundsAfterLabel = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SummaryContainer:FundsAfterLabel")
	self.tWndRefs.wndDialogPurchaseConfirmedFundsAfterValue = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SummaryContainer:FundsAfterValue")
	self.tWndRefs.wndDialogPurchaseConfirmedClaimBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:SummaryContainer:ClaimBtn")
	self.tWndRefs.wndDialogPurchaseConfirmedDisclaimer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseConfirmed:Disclaimer")
	
	-- Purchase Confirmed Animation
	self.tWndRefs.wndDialogPurchaseConfirmedAnimation = wndMain:FindChild("ModelDialog:PurchaseDialog:PurchaseConfirmAnimation")
	self.tWndRefs.wndDialogPurchaseConfirmedAnimationInner = wndMain:FindChild("ModelDialog:PurchaseDialog:PurchaseConfirmAnimation:PurchaseConfirmAnimationInner")

	-- Purchase Needs Funds
	self.tWndRefs.wndDialogPurchaseNeedsFunds = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds")
	self.tWndRefs.wndDialogPurchaseNeedsFundsItemName = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SectionStack:ItemName")
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoice = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SectionStack:CurrencyChoice")
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoiceContainer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SectionStack:CurrencyChoice:PackageSelectionBtn:Expander:Container")
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SectionStack:CurrencyChoice:PackageSelectionBtn:Expander")
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SectionStack:CurrencyChoice:PackageSelectionBtn")
	self.tWndRefs.wndDialogPurchaseNeedsFundsCostLabel = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SummaryContainer:CostLabel")
	self.tWndRefs.wndDialogPurchaseNeedsFundsCostValue = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SummaryContainer:CostValue")
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterLabel = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SummaryContainer:FundsAfterLabel")
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValueNegative = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SummaryContainer:FundsAfterValueNegative")
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValue = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SummaryContainer:FundsAfterValue")
	self.tWndRefs.wndDialogPurchaseNeedsFundsFinalizeBtn = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:SummaryContainer:FinalizeBtn")
	self.tWndRefs.wndDialogPurchaseNeedsFundsDisclaimer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFunds:Disclaimer")
	
	-- Purchase Needs Funds No CC
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCC = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFundsNoCC")
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCItemName = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFundsNoCC:SectionStack:ItemName")
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsSectionNoneAvailableTitle = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFundsNoCC:SectionStack:FundsSection:NoneAvailableTitle")		
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsSectionNoneAvailable = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFundsNoCC:SectionStack:FundsSection:NoneAvailable")
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsDisclaimer = wndMain:FindChild("ModelDialog:PurchaseDialog:Right:PurchaseNeedsFundsNoCC:Disclaimer")	

	-- History
	self.tWndRefs.wndDialogHistory = wndMain:FindChild("ModelDialog:History")
	self.tWndRefs.wndDialogHistoryGrid = wndMain:FindChild("ModelDialog:History:Grid")
	self.tWndRefs.wndDialogHistoryEmptyLabel = wndMain:FindChild("ModelDialog:History:EmptyLabel")
	
	-- Add Funds
	self.tWndRefs.wndDialogAddFunds = wndMain:FindChild("ModelDialog:AddFunds")
	self.tWndRefs.wndDialogAddFundsFraming = wndMain:FindChild("ModelDialog:AddFunds:Framing")
	
	-- Add Funds Choice
	self.tWndRefs.wndDialogAddFundsChoice = wndMain:FindChild("ModelDialog:AddFunds:Choice")
	self.tWndRefs.wndDialogAddFundsCCOnFile = wndMain:FindChild("ModelDialog:AddFunds:Choice:CCOnFile")
	self.tWndRefs.wndDialogAddFundsContainer = wndMain:FindChild("ModelDialog:AddFunds:Choice:CCOnFile:CurrencyChoiceContainer")
	self.tWndRefs.wndDialogAddFundsFinalizeBtn = wndMain:FindChild("ModelDialog:AddFunds:Choice:CCOnFile:FinalizeBtn")
	self.tWndRefs.wndDialogAddFundsNoCCOnFile = wndMain:FindChild("ModelDialog:AddFunds:Choice:NoCCOnFile")
	
	-- Add Funds Confirmed
	self.tWndRefs.wndDialogAddFundsConfirmed = wndMain:FindChild("ModelDialog:AddFunds:Confirmed")
	self.tWndRefs.wndDialogAddFundsConfirmedAnimation = wndMain:FindChild("ModelDialog:AddFunds:Confirmed:PurchaseConfirmAnimation")
	self.tWndRefs.wndDialogAddFundsConfirmedAnimationInner = wndMain:FindChild("ModelDialog:AddFunds:Confirmed:PurchaseConfirmAnimation:PurchaseConfirmAnimationInner")
	
	-- Center
	self.tWndRefs.wndCenter = wndMain:FindChild("Center")
	
	-- Center Splash
	self.tWndRefs.wndSplash = wndMain:FindChild("Center:Splash")
	self.tWndRefs.wndSplashItems = wndMain:FindChild("Center:Splash:Items")
	self.tWndRefs.wndSplashBannerRotationContainer = wndMain:FindChild("Center:Splash:HeaderContent:RotatingBanner:BannerRotationContainer")
	self.tWndRefs.wndSplashRightTopBtn = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:TopBannerBtn")
	self.tWndRefs.wndSplashRightTopImage = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:ImageTop")
	self.tWndRefs.wndSplashRightTopLabel = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:LabelTop")
	self.tWndRefs.wndSplashRightBottomBtn = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:BottomBannerBtn")
	self.tWndRefs.wndSplashRightBottomImage = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:ImageBtm")
	self.tWndRefs.wndSplashRightBottomLabel = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:LabelBtm")
	
	-- Center Offer List
	self.tWndRefs.wndCenterContent = wndMain:FindChild("Center:Content")
	self.tWndRefs.wndCenterFilters = wndMain:FindChild("Center:Content:Filters")
	self.tWndRefs.wndCenterFiltersSortBtn = wndMain:FindChild("Center:Content:Filters:SortBtn")
	self.tWndRefs.wndCenterFiltersSortBtn:AttachWindow(self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander"))
	self.tWndRefs.wndCenterItemsContainer = wndMain:FindChild("Center:Content:Items")
	self.tWndRefs.wndCenterContentNoResultsDisplay = wndMain:FindChild("Center:Content:NoResultsDisplay")
	self.tWndRefs.wndFilterNewestBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:NewestBtn")
	self.tWndRefs.wndFilterRecommendedBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:RecommendedBtn")
	self.tWndRefs.wndFilterPopularBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:PopularBtn")
	self.tWndRefs.wndFilterLimitedTimeBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:LimitedTimeBtn")
	
	-- Center Signature
	self.tWndRefs.wndSignature = wndMain:FindChild("Center:Signature")
	self.tWndRefs.wndSignatureContainer = wndMain:FindChild("Center:Signature:Container")
	self.tWndRefs.wndSignatureHeader = wndMain:FindChild("Center:Signature:Container:Header")
	self.tWndRefs.wndSignatureDescription = wndMain:FindChild("Center:Signature:Container:Description")
	self.tWndRefs.wndSignatureSecondaryDescription = wndMain:FindChild("Center:Signature:Container:SecondaryDescription")
	self.tWndRefs.wndSignatureBuyNowBtn = wndMain:FindChild("Center:Signature:Container:BuyNowBtn")
	self.tWndRefs.wndSignatureTableContainer = wndMain:FindChild("Center:Signature:Container:TableContainer")
	
	-- Full Blocker
	self.tWndRefs.wndFullBlocker = wndMain:FindChild("ModelDialog_FullScreen")
	self.tWndRefs.wndFullBlockerPrompt = wndMain:FindChild("ModelDialog_FullScreen:Prompt")
	self.tWndRefs.wndFullBlockerPromptHeader = wndMain:FindChild("ModelDialog_FullScreen:Prompt:Header")
	self.tWndRefs.wndFullBlockerPromptBody = wndMain:FindChild("ModelDialog_FullScreen:Prompt:Body")
	self.tWndRefs.wndFullBlockerPromptConfimBtn = wndMain:FindChild("ModelDialog_FullScreen:Prompt:ConfimBtn")
	self.tWndRefs.wndFullBlockerDelaySpinner = wndMain:FindChild("ModelDialog_FullScreen:DelaySpinner")
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage = wndMain:FindChild("ModelDialog_FullScreen:DelaySpinner:BG:DelayMessage")
	
	-- Flyer Container
	self.tWndRefs.wndFlyerContainer = wndMain:FindChild("FlyerContainer")
	self.tWndRefs.wndFlyerContainerNCoin = wndMain:FindChild("FlyerContainer:NCoin")
	
	-- Data Setup
	local strSignatureDesc = String_GetWeaselString('<P TextColor="UI_TextHoloBody" Font="CRB_InterfaceLarge">$1n</P>', Apollo.GetString("Storefront_SignatureDescriptionA"))
	local strSecondarySignatureDesc = String_GetWeaselString('<P TextColor="UI_TextHoloBody" Font="CRB_InterfaceMedium">$1n</P>', Apollo.GetString("Storefront_SignatureDescriptionB"))
	self.tWndRefs.wndSignatureDescription:SetAML(strSignatureDesc)
	self.tWndRefs.wndSignatureSecondaryDescription:SetAML(strSecondarySignatureDesc)
	for idx, tEntry in pairs(self.karSignatureData) do
		local nLine = 1
		while tEntry.arFree[nLine] ~= nil or tEntry.arSignature[nLine] ~= nil do
			local wndEntry = Apollo.LoadForm(self.xmlDoc, "SignatureListItem", self.tWndRefs.wndSignatureTableContainer, self)
		
			if idx % 2 ~= 0 then
				wndEntry:FindChild("Column1BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_DarkSolid")
				wndEntry:FindChild("Column2BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_DarkSolid")
				wndEntry:FindChild("Column3BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_DarkGradient")
			else
				wndEntry:FindChild("Column1BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_LightSolid")
				wndEntry:FindChild("Column2BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_LightSolid")
				wndEntry:FindChild("Column3BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_LightGradient")
			end
			
			local wndColumn1Text = wndEntry:FindChild("Column1BG:Column1Text")
			if nLine == 1 then
				wndColumn1Text:SetAML(string.format('<P TextColor="UI_TextMetalBodyHighlight" Font="CRB_Interface10_B">%s</P>', tEntry.strFeature))
			end
			local nCol1Width, nCol1Height = wndColumn1Text:SetHeightToContentHeight()
			
			local wndColumn2Text = wndEntry:FindChild("Column2BG:Column2Text")
			if tEntry.arFree[nLine] ~= nil then
				local strAML = string.format('<P TextColor="UI_TextMetalBodyHighlight" Font="CRB_Interface10_B">%s</P>', tEntry.arFree[nLine])
				wndColumn2Text:SetAML(strAML)
			end
			local nCol2Width, nCol2Height = wndColumn2Text:SetHeightToContentHeight()
			
			local wndColumn3Text = wndEntry:FindChild("Column3BG:Column3Text")
			if tEntry.arSignature[nLine]  ~= nil then
				local strAML = string.format('<P TextColor="UI_TextHoloTitle" Font="CRB_Interface10_B">%s</P>', tEntry.arSignature[nLine])
				wndColumn3Text:SetAML(strAML)
			end
			local nCol3Width, nCol3Height = wndColumn3Text:SetHeightToContentHeight()
			
			local nHeight = math.ceil(math.max(wndEntry:GetHeight(), nCol1Height, nCol2Height, nCol3Height) / wndEntry:GetHeight()) * wndEntry:GetHeight()
			local nLeft, nTop, nRight, nBottom = wndEntry:GetAnchorOffsets()
			wndEntry:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
			
			nLine = nLine + 1
		end
	end
	
	local nHeight = self.tWndRefs.wndSignatureTableContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndSignatureContainer:GetAnchorOffsets()
	self.tWndRefs.wndSignatureContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + (nHeight - self.tWndRefs.wndSignatureTableContainer:GetHeight()))
	self.tWndRefs.wndSignature:RecalculateContentExtents()
	
	local wndContainer = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Container")
	wndContainer:FindChild("NCoinsPrice:UpBtn"):SetData({eCurrency = AccountItemLib.CodeEnumAccountCurrency.NCoins, bIncreasingOrder = true})
	wndContainer:FindChild("NCoinsPrice:DownBtn"):SetData({eCurrency = AccountItemLib.CodeEnumAccountCurrency.NCoins, bIncreasingOrder = false})
	wndContainer:FindChild("OmniBitsPrice:UpBtn"):SetData({eCurrency = AccountItemLib.CodeEnumAccountCurrency.Omnibits, bIncreasingOrder = true})
	wndContainer:FindChild("OmniBitsPrice:DownBtn"):SetData({eCurrency = AccountItemLib.CodeEnumAccountCurrency.Omnibits, bIncreasingOrder = false})
	
	self.tWndRefs.wndFilterNewestBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.New})
	self.tWndRefs.wndFilterRecommendedBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.Recommended})
	self.tWndRefs.wndFilterPopularBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.Popular})
	self.tWndRefs.wndFilterLimitedTimeBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime})
	
	self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownBtn:AttachWindow(self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdown)
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn:AttachWindow(self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander)
	
	if StorefrontLib.GetIsPTR() then
		self.wndHeaderNCoins:SetTooltip(Apollo.GetString("Storefront_NCoinsCurrencyToolipPTR"))
		self.wndHeaderOmnibits:SetTooltip(Apollo.GetString("Storefront_OmnibitsCurrencyToolipPTR"))
		self.tWndRefs.wndDialogPurchaseConfirmDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimerPTR"))
		self.tWndRefs.wndDialogPurchaseConfirmedDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimerPTR"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimerPTR"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimerPTR"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsSectionNoneAvailableTitle:SetText(Apollo.GetString("Storefront_PTRNCoinTopupHelperTitle"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsSectionNoneAvailable:SetText(Apollo.GetString("Storefront_NoCCOnFileHelperPTR"))
	else
		self.wndHeaderNCoins:SetTooltip(Apollo.GetString("Storefront_NCoinsCurrencyToolip"))
		self.wndHeaderOmnibits:SetTooltip(Apollo.GetString("Storefront_OmnibitsCurrencyToolip"))
		self.tWndRefs.wndDialogPurchaseConfirmDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimer"))
		self.tWndRefs.wndDialogPurchaseConfirmedDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimer"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimer"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimer"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsSectionNoneAvailableTitle:SetText(Apollo.GetString("Storefront_NCoinTopupHelperTitle"))
		self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsSectionNoneAvailable:SetText(Apollo.GetString("Storefront_NoCCOnFileHelper"))
	end

	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "NavPrimary", nil, self)
	self.knNavPrimaryDefaultHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
	
	self.timerLoyaltyPointProgressUpdate = ApolloTimer.Create(self.knLoyaltyPointProgressUpdateRate, true, "UpdateLoyaltyPointProgress", self)
	self.timerLoyaltyPointProgressUpdate:Stop()
	
	self.timerLoyaltyPointHeaderProgressUpdate = ApolloTimer.Create(self.knLoyaltyPointProgressUpdateRate, true, "UpdateLoyaltyPointHeaderProgress", self)
	self.timerLoyaltyPointHeaderProgressUpdate:Stop()

end

function Storefront:OnStoreClosed()
	Sound.Play(Sound.PlayUIMTXStoreClose)
end

function Storefront:OnOpenStore()
	self.tLastCategory = nil
	
	self:UpdateCurrency()
	self:UpdateClaimCount()

	self.nFilterOptions = 0
	self.tWndRefs.wndFilterNewestBtn:SetCheck(false)
	self.tWndRefs.wndFilterRecommendedBtn:SetCheck(false)
	self.tWndRefs.wndFilterPopularBtn:SetCheck(false)
	self.tWndRefs.wndFilterLimitedTimeBtn:SetCheck(false)
	
	self.nCurRewardTrackId = nil
	self.wndLoyaltyProgress:SetProgress(0)
	self:BuildLoyaltyWindow(RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty))
	
	self.tWndRefs.wndFullBlocker:Show(false)
	self.tWndRefs.wndModelDialog:Show(false)
	self.tWndRefs.wndCenter:Show(true)
	
	if not StorefrontLib.IsStoreReady() or StorefrontLib.IsStoreCatalogDirty() then
		self.tWndRefs.wndFullBlocker:Show(true)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
		self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_CatalogUpdateInProgress"))
		
		StorefrontLib.RequestCatalog()
		
		return
	end

	self:BuildSignaturePage()
	self:BuildNavigation()
	
	for idx, wndNav in pairs(self.tWndRefs.wndNavigation:GetChildren()) do
		local wndNavBtn = wndNav:FindChild("NavBtn")
		if wndNavBtn then
			wndNavBtn:SetCheck(self.tWndRefs.wndNavPrimaryHome == wndNavBtn)
		end
	end
	self:OnFeaturedCheck(self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"), self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"))
	
	StorefrontLib.RequestHistory()
	
	local nDesiredHeight = 550
	local nHeight = self.tWndRefs.wndDialogPurchase:GetHeight()
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndDialogPurchase:GetAnchorOffsets()
	if nHeight > nDesiredHeight then
		self.tWndRefs.wndDialogPurchase:SetAnchorPoints(0.5, 0.5, 0.5, 0.5)
		self.tWndRefs.wndDialogPurchase:SetAnchorOffsets(nLeft, -(nDesiredHeight / 2), nRight, nDesiredHeight / 2)
	--else
		--self.tWndRefs.wndDialogPurchase:MoveToLocation(self.tWndRefs.wndDialogPurchase:GetOriginalLocation())
	end
	Sound.Play(Sound.PlayUIMTXStoreOpen)
end

function Storefront:OnOpenStoreLinkSingle(nOfferGroupId, nVariant)
	local tOffer = StorefrontLib.GetOfferGroupInfo(nOfferGroupId)
	self:SetupOffer(tOffer, nVariant, 0)
	self.tWndRefs.wndModelDialog:Show(true)
end

function Storefront:OnOpenStoreLinkCategory(nCategoryId)
	self:ShowCategoryPage(nCategoryId)
end

function Storefront:OnOpenSignature()
	local wndNavBtn = self.tWndRefs.wndNavPrimarySignature:FindChild("NavBtn")
	self:OnSignatureCheck(wndNavBtn, wndNavBtn)
	wndNavBtn:SetCheck(true)
end

function Storefront:OnSystemKeyDown(iKey)
	if iKey == self.knEscapeKey then
		if self.tWndRefs.wndFullBlocker:IsShown() then
			-- Do nothing
		elseif self.tWndRefs.wndModelDialog:IsShown() then
			self.tWndRefs.wndModelDialog:Show(false)
		else
			CloseStore()
		end
	end
end

function Storefront:OnHistoryReady()
	if self.tWndRefs.wndDialogHistory:IsShown() then
		local nPos = self.tWndRefs.wndDialogHistoryGrid:GetVScrollPos()
		self:BuildHistory()
		self.tWndRefs.wndDialogHistoryGrid:SetVScrollPos(nPos)
	end
end

function Storefront:OnStoreCatalogUpdated()
	self.tWndRefs.wndFullBlocker:Show(true)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_CatalogUpdateInProgress"))
	
	if IsStoreOpen() then
		StorefrontLib.RequestCatalog()
	end
end

function Storefront:OnStoreCatalogReady()
	self.tWndRefs.wndFullBlocker:Show(false)

	-- Refresh navigation
	local strText = nil
	if self.tWndRefs.wndNavSearchEditBox ~= nil and self.tWndRefs.wndNavSearchEditBox:IsValid() then
		strText = self.tWndRefs.wndNavSearchEditBox:GetText()
	end
	
	if self.wndNavInUse ~= nil then
		if self.wndNavInUse == self.tWndRefs.wndNavPrimaryHome then
			self:BuildNavigation()
			local wndBtn = self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn")
			self:OnFeaturedCheck(wndBtn, wndBtn)
			wndBtn:SetCheck(true)
		elseif self.wndNavInUse == self.tWndRefs.wndNavPrimarySignature then
			self:BuildNavigation()
			local wndBtn = self.tWndRefs.wndNavPrimarySignature:FindChild("NavBtn")
			self:OnSignatureCheck(wndBtn, wndBtn)
			wndBtn:SetCheck(true)
		else
			local tCategoryId = self.wndNavInUse:FindChild("NavBtn"):GetData().nId
			local nSubCategoryId = nil
			if self.tLastCategory ~= nil then
				nSubCategoryId = self.tLastCategory.nId
			end
			
			self:BuildNavigation()
			
			if self.tNavCategoryWndRefs[tCategoryId] ~= nil then
				local wndPrimaryNavBtn = self.tNavCategoryWndRefs[tCategoryId]:FindChild("NavBtn")
				self:OnNavPrimaryCheck(wndPrimaryNavBtn, wndPrimaryNavBtn)
				wndPrimaryNavBtn:SetCheck(true)
			
				if nSubCategoryId ~= nil then
					if self.tNavSubCategoryWndRefs[nSubCategoryId] ~= nil then
						local wndSecondaryNavBtn = self.tNavSubCategoryWndRefs[nSubCategoryId]:FindChild("SecondaryNavBtn")
						self:OnNavSecondaryCheck(wndSecondaryNavBtn, wndSecondaryNavBtn)
						wndSecondaryNavBtn:SetCheck(true)
					else
						self.tLastCategory = nil
						self:OnStoreCatalogReadyFailedToRecover()
						return
					end
				end
			else
				self:OnStoreCatalogReadyFailedToRecover()
				return
			end
		end
	else
		self:BuildNavigation()
		
		if strText == nil or strText == "" then
			for idx, wndNav in pairs(self.tWndRefs.wndNavigation:GetChildren()) do
				local wndNavBtn = wndNav:FindChild("NavBtn")
				if wndNavBtn then
					wndNavBtn:SetCheck(self.tWndRefs.wndNavPrimaryHome == wndNavBtn)
				end
			end
			self:OnFeaturedCheck(self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"), self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"))
		end
	end
	
	-- Refresh search item grid
	if strText ~= nil and strText ~= "" and self.tWndRefs.wndCenterItemsContainer:IsShown() then
		self.tWndRefs.wndNavSearchEditBox:SetText(strText)
		self:SetupSearchItemPage()
		self.tWndRefs.wndCenterItemsContainer:SetVScrollPos(0)
	end
	
	-- Refresh dialog windows
	if self.tWndRefs.wndModelDialog:IsShown() then
		-- If viewing currency packages refresh currency packages
		if self.tWndRefs.wndDialogAddFunds:IsShown() then
			self:BuildFundsPackages()
			self.tWndRefs.wndDialogAddFundsContainer:SetVScrollPos(0)
		else
			self:OnStoreCatalogReadyFailedToRecover()
			return
		end
	end
	
end

function Storefront:OnStoreCatalogReadyFailedToRecover()
	self:OnOpenStore()
	
	self.tWndRefs.wndFullBlocker:Show(true)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
	
	self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_CatalogUpdatedDialogHeader"))	
	self.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_CatalogUpdatedDialogBody"))
	self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
	Sound.Play(Sound.PlayUIMTXStorePurchaseFailed)

end

function Storefront:OnStorePurchaseOfferFailureResultAccept()
	local tData = self.tWndRefs.wndDialogPurchaseConfirm:GetData()
	self.tWndRefs.wndDialogPurchaseConfirmSectionStack:SetVScrollPos(0)
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
end

function Storefront:OnStoreError(eError)
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
	
	self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_GenericError"))
	if self.ktErrorMessages[eError] == nil then
		eError = StorefrontLib.CodeEnumStoreError.CatalogUnavailable
	end
	Sound.Play(Sound.PlayUIMTXStorePurchaseFailed)
	self.tWndRefs.wndFullBlockerPromptBody:SetText(self.ktErrorMessages[eError])
	self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = Storefront.OnStoreErrorAccept })
end

function Storefront:OnStoreErrorAccept()
	self:OnOpenStore()
end

function Storefront:OnAccountCurrencyChanged()
	self:UpdateCurrency()
end

function Storefront:OnAccountPendingItemsUpdate()
	self:UpdateClaimCount()

	-- TODO: Add self.wndClaimButton flash here
end

function Storefront:OnEntitlementUpdate(tEntitlementInfo)
	if tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.Signature and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.Free then
		return
	end
	
	self:BuildSignaturePage()
end

function Storefront:BuildSignaturePage()
	if AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.Signature) > 0 then
		self.tWndRefs.wndSignatureHeader:SetText(Apollo.GetString("Storefront_WelcomeSignaturePlayer"))
		self.tWndRefs.wndSignatureBuyNowBtn:Show(false)
	else
		self.tWndRefs.wndSignatureHeader:SetText(Apollo.GetString("Storefront_BecomeSignaturePlayer"))
		self.tWndRefs.wndSignatureBuyNowBtn:Show(true)
	end
end

function Storefront:HasDiscount(tOfferInfo)
	if tOfferInfo.tPrices == nil then
		return false
	end
	
	return (tOfferInfo.tPrices.tNCoins ~= nil and tOfferInfo.tPrices.tNCoins.nDiscountAmount ~= nil and tOfferInfo.tPrices.tNCoins.nDiscountAmount > 0)
				or (tOfferInfo.tPrices.tOmnibits ~= nil and tOfferInfo.tPrices.tOmnibits.nDiscountAmount ~= nil and tOfferInfo.tPrices.tOmnibits.nDiscountAmount > 0)
end

function Storefront:ConvertSecondsToTimeRemaining(fSeconds)
	local nDays = math.floor(fSeconds / 86400)
	local nHours = math.floor((fSeconds / 3600) - (nDays * 24))
	local nMins = math.floor((fSeconds / 60) - (nDays * 1440) - (nHours * 60))
	local nSecs = math.floor(fSeconds - (nDays * 86400) - (nHours * 3600) - (nMins * 60))
	
	local tFirstActor = nil
	local tSecondActor = nil
	
	if nDays > 0 then
		tFirstActor =
		{
			count = nDays,
			name = Apollo.GetString("CRB_Day")
		}
	end
	
	if nHours > 0 then
		local tHourActor =
		{
			count = nHours,
			name = Apollo.GetString("CRB_Hour")
		}
	
		if tFirstActor == nil then
			tFirstActor = tHourActor
		else
			tSecondActor = tHourActor
		end
	end
	
	if nMins > 0 then
		local tMinuteActor =
		{
			count = nMins,
			name = Apollo.GetString("CRB_Minute")
		}
		
		if tFirstActor == nil then
			tFirstActor = tMinuteActor
		elseif tSecondActor == nil then
			tSecondActor = tMinuteActor
		end
	end
	
	if nSecs > 0 or fSeconds == 0 then
		local tSecondsActor =
		{
			count = nSecs,
			name = Apollo.GetString("CRB_Second")
		}
		
		if tFirstActor == nil then
			tFirstActor = tSecondsActor
		elseif tSecondActor == nil then
			tSecondActor = tSecondsActor
		end
	end
	
	if tFirstActor ~= nil and tSecondActor ~= nil then
		return String_GetWeaselString(Apollo.GetString("Storefront_TimeRemainingPair"), tFirstActor, tSecondActor)
	end
	return String_GetWeaselString(Apollo.GetString("Storefront_TimeRemainingSingle"), tFirstActor)
end

function Storefront:BuildBannersForContainer(tOffer, tOfferInfo, wndBannerContainer)
	wndBannerContainer:DestroyChildren()

	if tOffer.tFlags.bLimitedTime then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("BabyPurple")
		wndBannerEntry:SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemPurple")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_LimitedTimeBanner"))
	end
	
	if tOffer.tFlags.bRecommended then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("DullYellow")
		wndBannerEntry:SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemYellow")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_OfferFlagRecommendedTooltip"))
	end
	
	if tOffer.tFlags.bNew then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("AquaGreen")
		wndBannerEntry:SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemGreen")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_OfferFlagNewTooltip"))
	end
	
	if tOffer.tFlags.bPopular then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("UI_BtnTextRedFlyby")
		wndBannerEntry:SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemRed")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_OfferFlagPopularTooltip"))
	end
	
	-- Sale
	local nLargestDiscount = 0
	local bHasDiscount = false
	
	-- NCoin
	if tOfferInfo.tPrices.tNCoins ~= nil then
		if tOfferInfo.tPrices.tNCoins.nDiscountAmount ~= nil then
			if tOfferInfo.tPrices.tNCoins.eDiscountType == StorefrontLib.CodeEnumStoreDiscountType.Percentage then
				nLargestDiscount = math.max(nLargestDiscount, tOfferInfo.tPrices.tNCoins.nDiscountAmount)
			end
			
			bHasDiscount = bHasDiscount or tOfferInfo.tPrices.tNCoins.nDiscountAmount > 0
		end
	end
	
	-- Omnibits
	if tOfferInfo.tPrices.tOmnibits ~= nil then
		if tOfferInfo.tPrices.tOmnibits.nDiscountAmount ~= nil then
			if tOfferInfo.tPrices.tOmnibits.eDiscountType == StorefrontLib.CodeEnumStoreDiscountType.Percentage then
				nLargestDiscount = math.max(nLargestDiscount, tOfferInfo.tPrices.tOmnibits.nDiscountAmount)
			end
			
			bHasDiscount = bHasDiscount or tOfferInfo.tPrices.tOmnibits.nDiscountAmount > 0
		end
	end
	
	if bHasDiscount then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("EggshellBlue")
		wndBannerEntry:SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemBlue")
		if nLargestDiscount > 0 then
			wndBannerEntry:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_DiscountBannerPrecent"), nLargestDiscount))
		else
			wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_DiscountBannerFlatAmount"))
		end
	end
end

function Storefront:SetupPriceContainer(wndPriceBG, tPrice)
	local nLargestDiscount = 0	

	local wndPrice = wndPriceBG:FindChild("Price")
	if tPrice ~= nil then
		wndPrice:SetAmount(tPrice.monPrice, true)
		
		local wndPriceBase = wndPriceBG:FindChild("PriceBase")
		local wndCrossOut = wndPriceBG:FindChild("CrossOut")
		
		if tPrice.nDiscountAmount ~= nil then
			if tPrice.eDiscountType == StorefrontLib.CodeEnumStoreDiscountType.Percentage then
				nLargestDiscount = tPrice.nDiscountAmount
			end
			
			wndPriceBase:SetAmount(tPrice.monBasePrice, true)
			
			wndPriceBase:Show(tPrice.nDiscountAmount > 0)
			wndCrossOut:Show(tPrice.nDiscountAmount > 0)
			local nWidth = (wndPriceBase:GetDisplayWidth() / 2)
			local nLeft, nTop, nRight, nBottom = wndCrossOut:GetAnchorOffsets()
			wndCrossOut:SetAnchorOffsets(nWidth * (-1), nTop, nWidth, nBottom)
		else
			wndPriceBase:Show(false)
			wndCrossOut:Show(false)
		end
		
		if not wndPriceBase:IsShown() then
			local nLeft, nTop, nRight, nBottom = wndPriceBG:GetAnchorOffsets()
			wndPriceBG:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - 20)
		end
	end
	wndPriceBG:Show(tPrice ~= nil)
	
	return nLargestDiscount
end

function Storefront:BuildNavigation()
	self.tNavCategoryWndRefs = {}
	self.tWndRefs.wndNavigation:DestroyChildren()
	
	local wndSearch = Apollo.LoadForm(self.xmlDoc, "NavSearch", self.tWndRefs.wndNavigation, self)
	self.tWndRefs.wndNavSearch = wndSearch
	self.tWndRefs.wndNavSearchClearBtn = wndSearch:FindChild("ClearBtn")
	self.tWndRefs.wndNavSearchEditBox = wndSearch:FindChild("EditBox")
	
	local wndHome = Apollo.LoadForm(self.xmlDoc, "NavPrimarySingle", self.tWndRefs.wndNavigation, self)
	wndHome:FindChild("NavBtn"):SetText(Apollo.GetString("Storefront_NavFeatured"))
	wndHome:FindChild("NavBtn"):SetTooltip(Apollo.GetString("Storefront_NavFeatuedTooltip"))
	wndHome:FindChild("NavBtn"):RemoveEventHandler("ButtonCheck")
	wndHome:FindChild("NavBtn"):AddEventHandler("ButtonCheck", "OnFeaturedCheck")
	self.tWndRefs.wndNavPrimaryHome = wndHome:FindChild("NavBtn")
	
	local wndSignature = Apollo.LoadForm(self.xmlDoc, "NavPrimarySingle", self.tWndRefs.wndNavigation, self)
	wndSignature:FindChild("NavBtn"):SetText(Apollo.GetString("Storefront_NavSignature"))
	wndSignature:FindChild("NavBtn"):SetTooltip(Apollo.GetString("Storefront_NavSignatureTooltip"))
	wndSignature:FindChild("NavBtn"):RemoveEventHandler("ButtonCheck")
	wndSignature:FindChild("NavBtn"):AddEventHandler("ButtonCheck", "OnSignatureCheck")
	self.tWndRefs.wndNavPrimarySignature = wndSignature:FindChild("NavBtn")
	
	Apollo.LoadForm(self.xmlDoc, "NavPrimarySpacer", self.tWndRefs.wndNavigation, self)
	
	local arCategories = StorefrontLib.GetCategoryTree()	
	if #arCategories == 0 then
		-- No data yet
		self:OnStoreError(StorefrontLib.CodeEnumStoreError.CatalogUnavailable)
		return
	end
	
	self.tWndRefs.wndFullBlocker:Show(false)
	
	for idx, tCategory in pairs(arCategories) do
		if tCategory.bDisplayable then
			local wndPrimary = nil
			if #tCategory.tGroups > 0 then
				wndPrimary = Apollo.LoadForm(self.xmlDoc, "NavPrimary", self.tWndRefs.wndNavigation, self)
			else
				wndPrimary = Apollo.LoadForm(self.xmlDoc, "NavPrimarySingle", self.tWndRefs.wndNavigation, self)
			end
			
			self.tNavCategoryWndRefs[tCategory.nId] = wndPrimary
			
			local wndNavBtn = wndPrimary:FindChild("NavBtn")
			wndNavBtn:SetText(tCategory.strName)
			wndNavBtn:SetData(tCategory)
			wndNavBtn:SetTooltip(tCategory.strDescription)
		end
	end
	self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Storefront:BuildHistory()
	local wndGrid = self.tWndRefs.wndDialogHistoryGrid
	wndGrid:DeleteAll()
	
	local arHistory = StorefrontLib.GetPurchaseHistory()
	for idx, tPurchase in pairs(arHistory) do
		local iCurrRow = wndGrid:AddRow(tPurchase.strPurchaseId, nil, tPurchase)

		local strName = tPurchase.strName
		if tPurchase.bRefunded then
			strName = String_GetWeaselString(Apollo.GetString("Storefront_Refunded"), tPurchase.strName)
		end
		wndGrid:SetCellText(iCurrRow, 2, tPurchase.strName)
		wndGrid:SetCellText(iCurrRow, 3, tPurchase.strTimestamp)
		wndGrid:SetCellSortText(iCurrRow, 3, tPurchase.nTimestamp)
		
		if tPurchase.eRealCurrency == nil then
			local xml = XmlDoc.new()
			tPurchase.monPrice:AddToTooltip(xml, "", "UI_TextHoloBody", "Default", "Right")
			wndGrid:SetCellDoc(iCurrRow, 4, xml:ToString())
			wndGrid:SetCellSortText(iCurrRow, 4, tPurchase.monPrice:GetAmount())
		else
			local strCurrencyName = self:GetRealCurrencyNameFromEnum(tPurchase.eRealCurrency)
			wndGrid:SetCellText(iCurrRow, 4, String_GetWeaselString("$2n$1n", string.format("%.2f", tPurchase.nPrice), strCurrencyName))
			wndGrid:SetCellSortText(iCurrRow, 4, tPurchase.nPrice)
		end
	end

	wndGrid:SetSortColumn(3, false)
	
	self.tWndRefs.wndDialogHistoryEmptyLabel:Show(#arHistory == 0)
end

function Storefront:BuildFundsPackages()
	self:AddFundsDialogShowHelper(self.tWndRefs.wndDialogAddFundsChoice)
	self.tWndRefs.wndDialogAddFundsFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupBlue")

	self.tWndRefs.wndDialogAddFundsContainer:DestroyChildren()
	local tFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
	for idx, tFundPackage in pairs(tFundPackages) do
		local wndFundPackage = Apollo.LoadForm(self.xmlDoc, "AddFundsEntry", self.tWndRefs.wndDialogAddFundsContainer, self)
		
		local strCurrencyName = self:GetRealCurrencyNameFromEnum(tFundPackage.eRealCurrency)
		
		wndFundPackage:FindChild("Name"):SetText(tFundPackage.strPackageName)
		wndFundPackage:FindChild("Cost"):SetText(String_GetWeaselString("$1n$2c", strCurrencyName, tFundPackage.nPrice))
		wndFundPackage:FindChild("Btn"):SetData(tFundPackage)
	end
	self.tWndRefs.wndDialogAddFundsContainer:ArrangeChildrenTiles()
	
	self.tWndRefs.wndDialogAddFundsFinalizeBtn:Enable(false)
	
	self.tWndRefs.wndDialogAddFundsCCOnFile:Show(#tFundPackages ~= 0)
	self.tWndRefs.wndDialogAddFundsNoCCOnFile:Show(#tFundPackages == 0)
end

function Storefront:SetupPreviewWindow(wndContainer, tDisplayInfo, tItems)
	local wndPreviewFrame = wndContainer:FindChild("PreviewFrame")
	local wndDecorFrame = wndContainer:FindChild("DecorFrame")
	if tDisplayInfo ~= nil then
		local unitPlayer = GameLib.GetPlayerUnit()
	
		if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
			local tMannequins = StorefrontLib.GetMannequins()
			tDisplayInfo.idCreature = tMannequins.nMaleMannequinCreatureId
			
			if unitPlayer ~= nil and unitPlayer:IsValid() then
				if unitPlayer:GetRaceId() == GameLib.CodeEnumRace.Chua then
					if tDisplayInfo.nId % 2 == 0 then
						tDisplayInfo.idCreature = tMannequins.nFemaleMannequinCreatureId
					end
				else
					local eGender = unitPlayer:GetGender()
					if eGender == Unit.CodeEnumGender.Female then
						tDisplayInfo.idCreature = tMannequins.nFemaleMannequinCreatureId
					end
				end
			end
		end
		
		if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Creature
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
			wndPreviewFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndPreviewFrame:SetCostumeToCreatureId(tDisplayInfo.idCreature)
			wndPreviewFrame:ResetSpin()
			wndPreviewFrame:SetSpin(30)
			
			for _, tAccountItem in pairs(tItems) do
				if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
					wndPreviewFrame:SetItem(tAccountItem.item)
					
					if tAccountItem.item:GetItemFamily() == Item.CodeEnumItem2Family.Tool then
						wndPreviewFrame:SetToolEquipped(true)
					end
				end
			end
			
			if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
				if unitPlayer ~= nil and unitPlayer:IsValid() then
					self.tWndRefs.wndDialogPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eStand)
				end
			end
			
		elseif tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Decor then
			wndDecorFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndDecorFrame:SetDecorInfo(tDisplayInfo.idDecor)
			wndDecorFrame:ResetSpin()
			wndDecorFrame:SetSpin(30)
			
		elseif tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mount then
			wndPreviewFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndPreviewFrame:SetCostumeToCreatureId(tDisplayInfo.idCreature)
			
			if tDisplayInfo.bIsHoverboard then
				wndPreviewFrame:SetAttachment(PetCustomizationLib.HoverboardAttachmentPoint, tDisplayInfo.idPreviewHoverboardItemDisplay)
			end
			
			wndPreviewFrame:SetModelSequence(150)
			wndPreviewFrame:ResetSpin()
			wndPreviewFrame:SetSpin(30)
			
			for _, tAccountItem in pairs(tItems) do
				if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
					local eCurrSlot = self.ktSlotMapping[tAccountItem.item:GetItemType()]
					if eCurrSlot ~= nil then
						local custFlair = StorefrontLib.GetPetFlairUnlockedFromItem(tAccountItem.item)
						if custFlair ~= nil then
							wndPreviewFrame:SetAttachment(tDisplayInfo.custPetCustomization:GetPreviewAttachSlot(eCurrSlot), custFlair:GetItemDisplay(eCurrSlot))
						end
					end
				end
			end
			
		end
	end
	
	local bShowPreview = wndPreviewFrame ~= nil and wndPreviewFrame:IsValid() and tDisplayInfo ~= nil
		and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Creature
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mount)
	wndPreviewFrame:Show(bShowPreview)
	wndDecorFrame:Show(wndDecorFrame ~= nil and wndDecorFrame:IsValid() and tDisplayInfo ~= nil and tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Decor)
end

function Storefront:SetupCategoryItemPage(tCategory)
	self.tLastCategory = tCategory
	local tCategoryParameters = { tCategory = tCategory, strSearch = self.strSearchText }

	local arOffers = StorefrontLib.GetOfferGroupsForCategory(tCategoryParameters.tCategory.nId, self.tSortingOptions, self.nFilterOptions)
	
	self:SetupItemGrid(self.tWndRefs.wndCenterItemsContainer, arOffers, tCategory.nId)
	self.tWndRefs.wndCenterContentNoResultsDisplay:Show(#arOffers == 0)
end

function Storefront:SetupSearchItemPage()
	self.tLastCategory = nil
	local strText = self.tWndRefs.wndNavSearchEditBox:GetText()

	local arOffers = StorefrontLib.GetOfferGroupsForSearchStr(strText, self.tSortingOptions, self.nFilterOptions)
	
	self:SetupItemGrid(self.tWndRefs.wndCenterItemsContainer, arOffers, 0)
	self.tWndRefs.wndCenterContentNoResultsDisplay:Show(#arOffers == 0)
end

function Storefront:SetupItemGrid(wndContainer, arOffers, nCategoryId)
	wndContainer:DestroyChildren()
	
	if arOffers == nil then
		return
	end
	
	for idx, idOffer in pairs(arOffers) do
		local wndOffer = Apollo.LoadForm(self.xmlDoc, "Item", wndContainer, self)
		
		local tOffer = StorefrontLib.GetOfferGroupInfo(idOffer)
		local tOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, 1)
		
		wndOffer:FindChild("PreviewBtn"):SetData({ tOffer = tOffer, nCategoryId = nCategoryId })
		wndOffer:FindChild("BottomStack:ItemName"):SetText(tOffer.strName)
		
		local nDisplayInfoId = tOffer.nDisplayInfoOverride
		if nDisplayInfoId == 0 and tOfferInfo ~= nil and #tOfferInfo.tItems > 0 then
			nDisplayInfoId = tOfferInfo.tItems[1].nStoreDisplayInfoId
		end
		
		local tDisplayInfo = StorefrontLib.GetStoreDisplayInfo(nDisplayInfoId)
		self:SetupPreviewWindow(wndOffer:FindChild("PreviewBtn:ItemImage"), tDisplayInfo, tOfferInfo.tItems)
		
		-- Callout
		local wndItemCallout = wndOffer:FindChild("ItemCallout")
		if tOffer.tFlags.bLimitedTime then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].strTooltip)
			
		elseif tOffer.tFlags.bRecommended then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].strTooltip)
			
		elseif tOffer.tFlags.bNew then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].strTooltip)
			
		elseif tOffer.tFlags.bPopular then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].strTooltip)
			
		else
			wndItemCallout:Show(false)
		end
		
		local wndBottomStack = wndOffer:FindChild("BottomStack")
		if tOfferInfo ~= nil then
			local wndPriceContainer = wndBottomStack:FindChild("PriceContainer")
			
			local nLargestDiscount = 0
			
			-- Price NCoins
			nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price1BG"), tOfferInfo.tPrices.tNCoins))
			
			-- Price Omnibits
			nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price2BG"), tOfferInfo.tPrices.tOmnibits))
			
			wndPriceContainer:FindChild("or"):Show(tOfferInfo.tPrices.tNCoins ~= nil and tOfferInfo.tPrices.tOmnibits ~= nil)
			
			local wndDiscountCallout = wndOffer:FindChild("DiscountCallout")
			if nLargestDiscount > 0 then
				wndDiscountCallout:Show(true)
				wndDiscountCallout:SetText(String_GetWeaselString(Apollo.GetString("Storefront_DiscountCallout"), nLargestDiscount))
			else
				wndDiscountCallout:Show(false)
				
				if not self:HasDiscount(tOfferInfo) then
					local nLeft, nTop, nRight, nBottom = wndPriceContainer:GetAnchorOffsets()
					wndPriceContainer:SetAnchorOffsets(nLeft, nTop + 25, nRight, nBottom)
				end
			end
			
			wndPriceContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
		end
		
		wndBottomStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom)
		
		wndOffer:SetData({tOffer = tOffer, tOfferInfo = tOfferInfo, tDisplayInfo = tDisplayInfo, nCategoryId = nCategoryId})
	end
	
	wndContainer:ArrangeChildrenTiles()
end

function Storefront:CenterShowHelper(wndToShow)
	self.tWndRefs.wndSplash:Show(self.tWndRefs.wndSplash == wndToShow)
	self.tWndRefs.wndCenterContent:Show(self.tWndRefs.wndCenterContent == wndToShow)

	local bShowSignature = self.tWndRefs.wndSignature == wndToShow
	self.tWndRefs.wndSignature:Show(bShowSignature)
	if bShowSignature then
		Sound.Play(Sound.PlayUIMTXStoreSignatureScreen)
	end

	if self.tWndRefs.wndSplash ~= wndToShow then
		self.timerBannerRotation:Stop()
	end
end

function Storefront:DialogShowHelper(wndToShow)
	self.tWndRefs.wndDialogPurchase:Show(self.tWndRefs.wndDialogPurchase == wndToShow)	
	self.tWndRefs.wndDialogHistory:Show(self.tWndRefs.wndDialogHistory == wndToShow)
	self.tWndRefs.wndDialogAddFunds:Show(self.tWndRefs.wndDialogAddFunds == wndToShow)
	self.tWndRefs.wndLoyaltyPage:Show(self.tWndRefs.wndLoyaltyPage == wndToShow)
end

function Storefront:PurchaseDialogShowHelper(wndToShow)
	self.tWndRefs.wndDialogPurchaseConfirm:Show(self.tWndRefs.wndDialogPurchaseConfirm == wndToShow)
	self.tWndRefs.wndDialogPurchaseConfirmed:Show(self.tWndRefs.wndDialogPurchaseConfirmed == wndToShow)
	self.tWndRefs.wndDialogPurchaseNeedsFunds:Show(self.tWndRefs.wndDialogPurchaseNeedsFunds == wndToShow)
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCC:Show(self.tWndRefs.wndDialogPurchaseNeedsFundsNoCC == wndToShow)
end

function Storefront:AddFundsDialogShowHelper(wndToShow)
	self.tWndRefs.wndDialogAddFundsChoice:Show(self.tWndRefs.wndDialogAddFundsChoice == wndToShow)
	self.tWndRefs.wndDialogAddFundsConfirmed:Show(self.tWndRefs.wndDialogAddFundsConfirmed == wndToShow)
end

function Storefront:FullBlockerHelper(wndToShow)
	self.tWndRefs.wndFullBlockerPrompt:Show(self.tWndRefs.wndFullBlockerPrompt == wndToShow, true)
	self.tWndRefs.wndFullBlockerDelaySpinner:Show(self.tWndRefs.wndFullBlockerDelaySpinner == wndToShow, true)
end

function Storefront:GetCurrencyNameFromEnum(eCurrencyType)
	if eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
		return "Omnibits"
	elseif eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
		if StorefrontLib.GetIsPTR() then
			return "PTR NCoin"
		else
			return "NCoin"
		end
	end
	
	return "UNKNOWN"
end

function Storefront:GetRealCurrencyNameFromEnum(eRealCurrency)
	if eRealCurrency == StorefrontLib.CodeEnumRealCurrency.USD then
		return Apollo.GetString("Storefront_ExternalCurrency_USD")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.GBP then
		return  Apollo.GetString("Storefront_ExternalCurrency_GBP")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.EUR then
		return  Apollo.GetString("Storefront_ExternalCurrency_EUR")
	end
	
	return "?"
end

function Storefront:OnBannerRotationTimer()
	local arChildren = self.tWndRefs.wndSplashBannerRotationContainer:GetChildren()
	if #arChildren == 0 then
		return
	end

	self.nRotatingBannersIndex = self.nRotatingBannersIndex + 1
	if self.nRotatingBannersIndex > #arChildren then
		self.nRotatingBannersIndex = 1
	end

	local nWidth = arChildren[1]:GetWidth()
	self.tWndRefs.wndSplashBannerRotationContainer:SetHScrollPos(nWidth * (self.nRotatingBannersIndex - 1))
end

function Storefront:SetupFeatured()
	local tBanners = StorefrontLib.GetRotatingBannerProducts()
	
	self.tWndRefs.wndSplashBannerRotationContainer:DestroyChildren()
	
	for idx, tBanner in pairs(tBanners) do
		if tBanner.eLocation == StorefrontLib.BannerLocation.RotatingBanner then
			local wndBanner = Apollo.LoadForm(self.xmlDoc, "Banner", self.tWndRefs.wndSplashBannerRotationContainer, self)
			local wndBtn = wndBanner:FindChild("Btn")
			wndBtn:SetData(tBanner)
			wndBanner:FindChild("Image"):SetSprite(tBanner.strBannerAsset)
			local wndTextContainer = wndBanner:FindChild("TextContainer")
			wndTextContainer:FindChild("ItemTitle"):SetText(tBanner.strTitle)
			local wndBody = wndTextContainer:FindChild("Body")
			wndBody:SetAML(string.format('<P Align="Bottom" Font="CRB_InterfaceMedium" TextColor="UI_TextHoloBody">%s</P>', tBanner.strBody))
			wndBody:SetHeightToContentHeight()
			wndTextContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom)
			
		elseif tBanner.eLocation == StorefrontLib.BannerLocation.UpperRightBanner then
			self.tWndRefs.wndSplashRightTopImage:SetSprite(tBanner.strBannerAsset)
			self.tWndRefs.wndSplashRightTopLabel:SetText(tBanner.strTitle)
			self.tWndRefs.wndSplashRightTopBtn:SetData(tBanner)
		elseif tBanner.eLocation == StorefrontLib.BannerLocation.LowerRightBanner then
			self.tWndRefs.wndSplashRightBottomImage:SetSprite(tBanner.strBannerAsset)
			self.tWndRefs.wndSplashRightBottomLabel:SetText(tBanner.strTitle)
			self.tWndRefs.wndSplashRightBottomBtn:SetData(tBanner)
		end
	end
	
	self.tWndRefs.wndSplashBannerRotationContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	if #self.tWndRefs.wndSplashBannerRotationContainer:GetChildren() > 1 then
		self.timerBannerRotation:Start()
	else
		self.timerBannerRotation:Stop()
	end
	
	self.nRotatingBannersIndex = 0
	self:OnBannerRotationTimer()
	
	local arOffers = StorefrontLib.GetOfferGroupsForCategory(StorefrontLib.GetFeaturedCategoryId(), {}, 0)
	self:SetupItemGrid(self.tWndRefs.wndSplashItems, arOffers, StorefrontLib.GetFeaturedCategoryId())
	
	local nHeight = self.tWndRefs.wndSplashItems:ArrangeChildrenTiles()
	
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndSplashItems:GetAnchorOffsets()
	self.tWndRefs.wndSplashItems:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tWndRefs.wndSplash:RecalculateContentExtents()
end

function Storefront:SetupOffer(tOffer, nVariant, nCategoryId)
	self.tWndRefs.wndDialogPurchaseFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupBlue")
	self:DialogShowHelper(self.tWndRefs.wndDialogPurchase)
	self:PurchaseDialogShowHelper(self.tWndRefs.wndDialogPurchaseConfirm)
	
	self.tWndRefs.wndDialogPurchaseConfirm:SetData({tOffer = tOffer, nVariant = nVariant, nCategoryId = nCategoryId})
	
	local tOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, nVariant)
	
	local tOfferCache = {}
	tOfferCache[nVariant] = tOfferInfo
	
	local nVariantQuantityCount = 0
	if #tOfferInfo.tItems > 0 then
		nVariantQuantityCount = tOfferInfo.tItems[1].nCount
	end
	
	-- Preview
	local nDisplayInfoId = tOffer.nDisplayInfoOverride
	if nDisplayInfoId == 0 and #tOfferInfo.tItems >= 1 then
		nDisplayInfoId = tOfferInfo.tItems[1].nStoreDisplayInfoId
	end
	local tDisplayInfo = StorefrontLib.GetStoreDisplayInfo(nDisplayInfoId)	
	self:SetupPreviewWindow(self.tWndRefs.wndDialogPurchaseLeft, tDisplayInfo, tOfferInfo.tItems)
	
	self.tWndRefs.wndDialogPurchasePreviewOnMeBtn:Show(tDisplayInfo ~= nil and tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin)
	self.tWndRefs.wndDialogPurchasePreviewOnMeBtn:SetCheck(true)
	self.tWndRefs.wndDialogPurchasePreviewOnMeBtn:SetData({tDisplayInfo = tDisplayInfo, tItems = tOfferInfo.tItems})
	
	self.tWndRefs.wndDialogPurchasePreviewSheathedBtn:Show(tDisplayInfo ~= nil and tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin)
	self.tWndRefs.wndDialogPurchasePreviewSheathedBtn:SetCheck(true)
	
	if tDisplayInfo ~= nil and tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
		local wndPreviewFrame = self.tWndRefs.wndDialogPurchaseLeft:FindChild("PreviewFrame")
		local unitPlayer = GameLib.GetPlayerUnit()
		
		wndPreviewFrame:SetCostume(unitPlayer)
		for _, tAccountItem in pairs(tOfferInfo.tItems) do
			if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
				wndPreviewFrame:SetItem(tAccountItem.item)
			end
		end
		
		self.tWndRefs.wndDialogPurchasePreview:SetSheathed(true)
		
		if unitPlayer ~= nil and unitPlayer:IsValid() then
			self.tWndRefs.wndDialogPurchasePreview:SetModelSequence(StorefrontLib.CodeEnumModelSequence.DefaultStand)
		end
	end
	
	-- Name
	self.tWndRefs.wndDialogPurchaseConfirmItemName:SetAML("<P Font=\"CRB_HeaderMedium\" TextColor=\"White\">"..tOfferInfo.strVariantName.."</P>")
	self.tWndRefs.wndDialogPurchaseConfirmItemName:SetHeightToContentHeight()
	
	-- Banners
	self:BuildBannersForContainer(tOffer, tOfferInfo, self.tWndRefs.wndDialogPurchaseConfirmBannerContainer)
		
	local nBannerContainerHeight = self.tWndRefs.wndDialogPurchaseConfirmBannerContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.tWndRefs.wndDialogPurchaseConfirmBannerSection:Show(nBannerContainerHeight > 0)
	if nBannerContainerHeight > 0 then
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndDialogPurchaseConfirmBannerSection:GetAnchorOffsets()
		nBottom = nBottom + nBannerContainerHeight - self.tWndRefs.wndDialogPurchaseConfirmBannerContainer:GetHeight()
		self.tWndRefs.wndDialogPurchaseConfirmBannerSection:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	end
	
	-- Description
	local nLargestDescriptionHeight = 0
	for idx=1, tOffer.nNumVariants do
		local tVariantOfferInfo = tOfferCache[idx]
		if tVariantOfferInfo == nil then
			tVariantOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
			tOfferCache[idx] = tVariantOfferInfo
		end
		
		self.tWndRefs.wndDialogPurchaseConfirmDescription:SetAML("<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloTitle\">"..tVariantOfferInfo.strVariantDescription.."</P>")
		local nWidth, nHeight = self.tWndRefs.wndDialogPurchaseConfirmDescription:SetHeightToContentHeight()
		nLargestDescriptionHeight = math.max(nLargestDescriptionHeight, nHeight)
	end
	self.tWndRefs.wndDialogPurchaseConfirmDescription:SetAML("<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloTitle\">"..tOfferInfo.strVariantDescription.."</P>")
	local nDescriptionWidth, nDescriptionHeight = self.tWndRefs.wndDialogPurchaseConfirmDescription:SetHeightToContentHeight()
	
	if nDescriptionHeight < nLargestDescriptionHeight then
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndDialogPurchaseConfirmDescription:GetAnchorOffsets()
		self.tWndRefs.wndDialogPurchaseConfirmDescription:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nLargestDescriptionHeight)
	end

	-- Claim Notice
	local bCantClaimCharacter = false
	local bCantClaimAccount = false
	local bCantClaimAccountPending = tOfferInfo.bAlreadyOwnPendingMultiRedeem
	
	for _, tAccountItem in pairs(tOfferInfo.tItems) do
		bCantClaimCharacter = bCantClaimCharacter or (tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.CharacterMaxed)
		bCantClaimAccount = bCantClaimAccount or (tAccountItem.eClaimState ~= nil
			and (tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxed or tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending))
		bCantClaimAccountPending = bCantClaimAccountPending or (tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending)
	end
	self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltip:Show(bCantClaimCharacter or bCantClaimAccount)
	if bCantClaimAccountPending then
		self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltipBody:SetText(Apollo.GetString("Storefront_AccountClaimLimitWithPendingNotice"))
	elseif bCantClaimAccount then
		self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltipBody:SetText(Apollo.GetString("Storefront_AccountClaimLimitNotice"))
	elseif tOfferInfo.bAlreadyOwnBoundMultiRedeem then
		self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltipBody:SetText(Apollo.GetString("Storefront_AlreadyOwnMultiRedeemNotice"))
	elseif bCantClaimCharacter then
		self.tWndRefs.wndDialogPurchaseConfirmAlertClaimTooltipBody:SetText(Apollo.GetString("Storefront_CharacterClaimLimitNotice"))
	end
	
	-- Quantity
	self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownBtn:SetCheck(false)
	self.tWndRefs.wndDialogPurchaseConfirmQuantitySection:Show(tOffer.nNumVariants > 1)
	if tOffer.nNumVariants > 1 then
		self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownContainer:DestroyChildren()
		
		local tQuantities = {}
		local nDifferentQuantitiesCount = 0
		for idx=1, tOffer.nNumVariants do
			local tQuantityOfferInfo = tOfferCache[idx]
			if tQuantityOfferInfo == nil then
				tQuantityOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
				tOfferCache[idx] = tQuantityOfferInfo
			end
			if tQuantityOfferInfo ~= nil and #tQuantityOfferInfo.tItems > 0 and #tOfferInfo.tItems > 0 and tQuantityOfferInfo.tItems[1].nId == tOfferInfo.tItems[1].nId then
				local nQuantityCount = tQuantityOfferInfo.tItems[1].nCount
				if tQuantities[nQuantityCount] == nil then
					tQuantities[nQuantityCount] = { tQuantityOfferInfo = tQuantityOfferInfo, nVariant = idx }
					 nDifferentQuantitiesCount = nDifferentQuantitiesCount + 1
				end
			end
		end
		
		if nDifferentQuantitiesCount > 1 then
			for nQuantityCount, tQuantity in pairs(tQuantities) do
				local tQuantityOfferInfo = tQuantity.tQuantityOfferInfo
				
				local wndQuantity = Apollo.LoadForm(self.xmlDoc, "QuantityDropdownItem", self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownContainer, self)
				wndQuantity:SetData(nQuantityCount)
				
				local wndItemBtn = wndQuantity:FindChild("ItemBtn")
				wndItemBtn:SetData({ tOffer = tOffer, nVariant = tQuantity.nVariant, nCategoryId = nCategoryId })
				wndItemBtn:SetText(nQuantityCount)
				wndItemBtn:SetCheck(nVariant == tQuantity.nVariant)
				
				-- Price NCoins
				local wndPrice1 = wndItemBtn:FindChild("CostContainer:Price1")
				if tQuantityOfferInfo.tPrices.tNCoins ~= nil then
					wndPrice1:SetAmount(tQuantityOfferInfo.tPrices.tNCoins.monPrice, true)
				end
				wndPrice1:Show(tQuantityOfferInfo.tPrices.tNCoins ~= nil)
				
				-- Price Omnibits
				local wndPrice2 = wndItemBtn:FindChild("CostContainer:Price2")
				if tQuantityOfferInfo.tPrices.tOmnibits ~= nil then
					wndPrice2:SetAmount(tQuantityOfferInfo.tPrices.tOmnibits.monPrice, true)
				end
				wndPrice2:Show(tQuantityOfferInfo.tPrices.tOmnibits ~= nil)
				
				wndItemBtn:FindChild("CostContainer:or"):Show(tQuantityOfferInfo.tPrices.tNCoins ~= nil and tQuantityOfferInfo.tPrices.tOmnibits ~= nil)
			end
		end
		
		local nQuantityHeight = self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
			return wndLeft:GetData() < wndRight:GetData()
		end)
		if nQuantityHeight == 0 then
			self.tWndRefs.wndDialogPurchaseConfirmQuantitySection:Show(false)
		else
			local nQuantityHeightChange = nQuantityHeight - self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownContainer:GetHeight()
			local nLeft, nTop, nRight, nButtom = self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdown:GetAnchorOffsets()
			self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nButtom + nQuantityHeightChange)
			
			self.tWndRefs.wndDialogPurchaseConfirmQuantityDropdownBtn:SetText(nVariantQuantityCount)
			
			-- Price NCoins
			if tOfferInfo.tPrices.tNCoins ~= nil then
				self.tWndRefs.wndDialogPurchaseConfirmQuantityPrice1:SetAmount(tOfferInfo.tPrices.tNCoins.monPrice, true)
			end
			self.tWndRefs.wndDialogPurchaseConfirmQuantityPrice1:Show(tOfferInfo.tPrices.tNCoins ~= nil)
			
			-- Price Omnibits
			if tOfferInfo.tPrices.tOmnibits ~= nil then
				self.tWndRefs.wndDialogPurchaseConfirmQuantityPrice2:SetAmount(tOfferInfo.tPrices.tOmnibits.monPrice, true)
			end
			self.tWndRefs.wndDialogPurchaseConfirmQuantityPrice2:Show(tOfferInfo.tPrices.tOmnibits ~= nil)
			
			self.tWndRefs.wndDialogPurchaseConfirmQuantityPriceOr:Show(tOfferInfo.tPrices.tNCoins ~= nil and tOfferInfo.tPrices.tOmnibits ~= nil)
		end
	end
	
	-- Variants
	self.tWndRefs.wndDialogPurchaseConfirmVariantSection:Show(tOffer.nNumVariants > 1)
	self.tWndRefs.wndDialogPurchaseConfirmVariantContainer:DestroyChildren()
	if tOffer.nNumVariants > 1 then
		local arVariants = {}
		for idx=1, tOffer.nNumVariants do
			local tVariantOfferInfo = tOfferCache[idx]
			if tVariantOfferInfo == nil then
				tVariantOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
				tOfferCache[idx] = tVariantOfferInfo
			end
			if tVariantOfferInfo ~= nil and #tVariantOfferInfo.tItems > 0 and tVariantOfferInfo.tItems[1].nCount == nVariantQuantityCount then
				table.insert(arVariants, { tVariantOfferInfo = tVariantOfferInfo, nVariant = idx })
			end
		end
	
		if #arVariants > 1 then
			for idx, tVariant in pairs(arVariants) do
				local tVariantOfferInfo = tVariant.tVariantOfferInfo
				local wndVariant = Apollo.LoadForm(self.xmlDoc, "VariantListItem", self.tWndRefs.wndDialogPurchaseConfirmVariantContainer, self)
				
				local tVariantDisplayInfo = nil
				if #tVariantOfferInfo.tItems >= 1 then
					tVariantDisplayInfo = StorefrontLib.GetStoreDisplayInfo(tVariantOfferInfo.tItems[1].nStoreDisplayInfoId)
				end
				self:SetupPreviewWindow(wndVariant, tVariantDisplayInfo, tVariantOfferInfo.tItems)
				
				local wndBtn = wndVariant:FindChild("Btn")
				wndBtn:SetData({ tOffer = tOffer, nVariant = tVariant.nVariant, nCategoryId = nCategoryId })
				wndBtn:SetCheck(tVariant.nVariant == nVariant)
				
				wndVariant:FindChild("Label"):SetText(tVariantOfferInfo.strVariantName)
				wndBtn:SetTooltip(tVariantOfferInfo.strVariantName)
			end
		end
		
		local nVariantHeight = self.tWndRefs.wndDialogPurchaseConfirmVariantContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		if nVariantHeight == 0 then
			self.tWndRefs.wndDialogPurchaseConfirmVariantSection:Show(false)
		end
	end
	
	-- Bundles
	self:SetupOfferBundles(tOffer, tOfferInfo, self.tWndRefs.wndDialogPurchaseConfirmBundleSection, self.tWndRefs.wndDialogPurchaseConfirmBundleContainer)
	
	-- Price NCoins
	if tOfferInfo.tPrices.tNCoins ~= nil then
		self.tWndRefs.wndDialogPurchaseConfirmCurrency1:SetAmount(tOfferInfo.tPrices.tNCoins.monPrice, true)
		self.tWndRefs.wndDialogPurchaseConfirmCurrency1Btn:SetCheck(false)
		self.tWndRefs.wndDialogPurchaseConfirmCurrency1Btn:SetData({ tOffer = tOffer, tOfferInfo = tOfferInfo, tPrice = tOfferInfo.tPrices.tNCoins, nVariant = nVariant, nCategoryId = nCategoryId })
		self.tWndRefs.wndDialogPurchaseConfirmCurrency1Btn:Enable(not bCantClaimAccount and not bCantClaimAccountPending)
	end
	self.tWndRefs.wndDialogPurchaseConfirmCurrency1Container:Show(tOfferInfo.tPrices.tNCoins ~= nil)
	self.tWndRefs.wndDialogPurchaseConfirmCurrency1DisabledTooltip:Show(bCantClaimAccount or bCantClaimAccountPending)
	
	-- Price Omnibits
	if tOfferInfo.tPrices.tOmnibits ~= nil then
		self.tWndRefs.wndDialogPurchaseConfirmCurrency2:SetAmount(tOfferInfo.tPrices.tOmnibits.monPrice, true)
		self.tWndRefs.wndDialogPurchaseConfirmCurrency2Btn:SetCheck(false)
		self.tWndRefs.wndDialogPurchaseConfirmCurrency2Btn:SetData({ tOffer = tOffer, tOfferInfo = tOfferInfo, tPrice = tOfferInfo.tPrices.tOmnibits, nVariant = nVariant, nCategoryId = nCategoryId })
		self.tWndRefs.wndDialogPurchaseConfirmCurrency2Btn:Enable(not bCantClaimAccount and not bCantClaimAccountPending and not tOfferInfo.bAlreadyOwnBoundMultiRedeem)
	end
	self.tWndRefs.wndDialogPurchaseConfirmCurrency2Container:Show(tOfferInfo.tPrices.tOmnibits ~= nil)
	self.tWndRefs.wndDialogPurchaseConfirmCurrency2DisabledTooltip:Show(bCantClaimAccount or bCantClaimAccountPending or tOfferInfo.bAlreadyOwnBoundMultiRedeem)
	
	self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:SetText(Apollo.GetString("Storefront_Purchase"))
	self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:Show(false)
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterBG:Show(false)
	
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterLabel:Show(false)
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:Show(false)
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative:Show(false)
	self.tWndRefs.wndDialogPurchaseConfirmNotEnoughOmnibits:Show(false)
	self.tWndRefs.wndDialogPurchaseConfirmNoCurrencySelected:Show(true)
	
	self.tWndRefs.wndDialogPurchaseConfirmSectionStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
end

function Storefront:SetupOfferBundles(tOffer, tOfferInfo, wndSection, wndContainer)
	local nDisplayInfosCount = 0
	local tDisplayInfos = {}
	for idx, nDisplayInfo in pairs(tOfferInfo.tDisplayInfos) do
		local tBundleDisplayInfo = StorefrontLib.GetStoreDisplayInfo(nDisplayInfo)
		
		tDisplayInfos[nDisplayInfo] = { nCount = 0, arItems = {}, strName = tBundleDisplayInfo.strName, tBundleDisplayInfo = tBundleDisplayInfo }
		nDisplayInfosCount = nDisplayInfosCount + 1
	end
	for idx, tAccountItem in pairs(tOfferInfo.tItems) do
		if tDisplayInfos[tAccountItem.nStoreDisplayInfoId] == nil then
			local tBundleDisplayInfo = StorefrontLib.GetStoreDisplayInfo(tAccountItem.nStoreDisplayInfoId)
		
			tDisplayInfos[tAccountItem.nStoreDisplayInfoId] = { nCount = 0, arItems = {}, tBundleDisplayInfo = tBundleDisplayInfo }
			nDisplayInfosCount = nDisplayInfosCount + 1
			
			if tAccountItem.item ~= nil then
				tDisplayInfos[tAccountItem.nStoreDisplayInfoId].strName = tAccountItem.item:GetName()
			elseif tAccountItem.monCurrency ~= nil then
				tDisplayInfos[tAccountItem.nStoreDisplayInfoId].strName = tAccountItem.monCurrency:GetTypeString()
			elseif tAccountItem.entitlement ~= nil then
				tDisplayInfos[tAccountItem.nStoreDisplayInfoId].strName = tAccountItem.entitlement.name
			end
		end
		
		local nCount = tAccountItem.nCount
		if tAccountItem.monCurrency ~= nil then
			nCount = nCount * tAccountItem.monCurrency:GetAmount()
		elseif tAccountItem.entitlement ~= nil then
			nCount = nCount * tAccountItem.entitlement.count
		end
		
		
		tDisplayInfos[tAccountItem.nStoreDisplayInfoId].nCount = nCount
		table.insert(tDisplayInfos[tAccountItem.nStoreDisplayInfoId].arItems, tAccountItem)
	end
	
	wndSection:Show(nDisplayInfosCount > 1)
	wndContainer:DestroyChildren()
	if nDisplayInfosCount > 1 then
		for nDisplayInfo, tInfo in pairs(tDisplayInfos) do
			local wndBundle = Apollo.LoadForm(self.xmlDoc, "BundleListItem", wndContainer, self)
			
			self:SetupPreviewWindow(wndBundle, tInfo.tBundleDisplayInfo, tInfo.arItems)
			
			local wndBtn = wndBundle:FindChild("Btn")
			wndBtn:SetData({ tBundleDisplayInfo = tInfo.tBundleDisplayInfo, tItems = tInfo.arItems, nCategoryId = nCategoryId })
			wndBtn:SetCheck((tOffer.nDisplayInfoOverride == 0 or tOffer.nDisplayInfoOverride == nDisplayInfo) and idx == 1)
			
			if tInfo.nCount > 1 then
				wndBundle:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_BundleEntryNameWithMultiple"), { name = tInfo.strName, count = tInfo.nCount }))
			else
				wndBundle:FindChild("Label"):SetText(String_GetWeaselString("$1n", tInfo.strName))
			end
		end
	
		local nTotalHeight = wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nPadding = wndSection:FindChild("Icon"):GetHeight()
		local nLeft, nTop, nRight, nBottom = wndSection:GetAnchorOffsets()
		wndSection:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTotalHeight + nPadding)
	end
end

function Storefront:PurchaseConfirmed(tData)
	self:PurchaseDialogShowHelper(self.tWndRefs.wndDialogPurchaseConfirmed)
	self.tWndRefs.wndDialogPurchaseFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupGreen")
	self.tWndRefs.wndDialogPurchaseConfirmedAnimation:SetSprite("BK3:UI_BK3_OutlineShimmer_anim_nocycle")
	self.tWndRefs.wndDialogPurchaseConfirmedAnimationInner:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	Sound.Play(Sound.PlayUIMTXStorePurchaseConfirmation)

	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice
	
	self.tWndRefs.wndDialogPurchaseConfirmedItemName:SetAML("<P Font=\"CRB_HeaderMedium\" TextColor=\"White\">"..tOfferInfo.strVariantName.."</P>")
	self.tWndRefs.wndDialogPurchaseConfirmedItemName:SetHeightToContentHeight()
	self.tWndRefs.wndDialogPurchaseConfirmedDescription:SetAML("<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloTitle\">"..tOfferInfo.strVariantDescription.."</P>")
	self.tWndRefs.wndDialogPurchaseConfirmedDescription:SetHeightToContentHeight()
	
	self.tWndRefs.wndDialogPurchaseConfirmedBundleSection:Show(false)
	
	-- Bundles
	self:SetupOfferBundles(tOffer, tOfferInfo, self.tWndRefs.wndDialogPurchaseConfirmedBundleSection, self.tWndRefs.wndDialogPurchaseConfirmedBundleContainer)
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndDialogPurchaseConfirmedCostLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_TotalCost"), strCurrencyName))
	self.tWndRefs.wndDialogPurchaseConfirmedCostValue:SetAmount(tData.tPrice.monPrice)
	self.tWndRefs.wndDialogPurchaseConfirmedFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_Remaining"), strCurrencyName))
	self.tWndRefs.wndDialogPurchaseConfirmedFundsAfterValue:SetAmount(monBalance)
	self.tWndRefs.wndDialogPurchaseConfirmedClaimBtn:SetData(tData)
	
	self.tWndRefs.wndDialogPurchaseConfirmedSectionStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
end

function Storefront:PurchaseNeedMoreFunds(tData)
	self:PurchaseDialogShowHelper(self.tWndRefs.wndDialogPurchaseNeedsFunds)
	self.tWndRefs.wndDialogPurchaseFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupRed")
	
	self.tWndRefs.wndDialogPurchaseNeedsFunds:SetData(tData)
	
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice

	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	local monAfter = Money.new()
	monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
	monAfter:SetAmount(tData.tPrice.monPrice:GetAmount() - monBalance:GetAmount())
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsItemName:SetAML("<P Font=\"CRB_HeaderMedium\" TextColor=\"White\">"..tOffer.strName.."</P>")
	self.tWndRefs.wndDialogPurchaseNeedsFundsItemName:SetHeightToContentHeight()
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn:SetText(Apollo.GetString("Storefront_NCoinPackages"))
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoiceContainer:DestroyChildren()
	local tFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
	for idx, tFundPackage in pairs(tFundPackages) do
		local wndFundPackage = Apollo.LoadForm(self.xmlDoc, "AddFundsEntrySlim", self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoiceContainer, self)
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
	local nListHeight = self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoiceContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function (wndLeft, wndRight)
		return wndLeft:GetData().nCount < wndRight:GetData().nCount
	end)
	local nOldListHeight = self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoiceContainer:GetHeight()
	
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander:GetAnchorOffsets()
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nListHeight - nOldListHeight)
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)

	self.tWndRefs.wndDialogPurchaseNeedsFundsCostLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_TotalCost"), strCurrencyName))
	self.tWndRefs.wndDialogPurchaseNeedsFundsCostValue:SetAmount(tData.tPrice.monPrice)
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_Remaining"), strCurrencyName))
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValue:SetAmount(monAfter, true)
	
	local nWidth = self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValue:GetDisplayWidth()
	local nFundsValueRight = math.abs(({self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValue:GetAnchorOffsets()})[3]) --3 is the right offset
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValueNegative:GetAnchorOffsets()
	
	nRight = -nWidth - nFundsValueRight
	nLeft = nRight - self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValueNegative:GetWidth()
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValueNegative:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValueNegative:Show(true)
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsFinalizeBtn:SetData(tData)
	self.tWndRefs.wndDialogPurchaseNeedsFundsFinalizeBtn:Enable(false)
end

function Storefront:PurchaseNeedMoreFundsNoCC(tData)
	self.tWndRefs.wndDialogPurchaseFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupRed")
	self:PurchaseDialogShowHelper(self.tWndRefs.wndDialogPurchaseNeedsFundsNoCC)
	
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCItemName:SetText(tOffer.strName)
	
	local strCurrencyName = "NCoin"
	
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCYourCurrencyLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_YourCurrencyType"), strCurrencyName))
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCYourCurrencyValue:SetAmount(monBalance)
	--self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCCostLabel:SetText(String_GetWeaselString("Total $1n Cost:", strCurrencyName))
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCCostValue:SetAmount(tData.tPrice.monPrice)
	self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_CurrencyAfterPurchase"), strCurrencyName))
	--self.tWndRefs.wndDialogPurchaseNeedsFundsNoCCFundsAfterValue:SetText((monBalance - tData.tPrice.monPrice))
end

function Storefront:UpdateCurrency()
	local monNCoins = StorefrontLib.GetBalance(AccountItemLib.CodeEnumAccountCurrency.NCoins)
	self.wndHeaderNCoins:SetAmount(monNCoins, true)
	self.wndHeaderOmnibits:SetAmount(StorefrontLib.GetBalance(AccountItemLib.CodeEnumAccountCurrency.Omnibits), true)
	self.wndTopUpReminder:Show(monNCoins:GetAmount() == 0)
end

function Storefront:UpdateClaimCount()
	local nCount = #AccountItemLib.GetPendingAccountItemGroups()
	
	self.wndClaimBtn:SetText(String_GetWeaselString(Apollo.GetString("Storefront_ClaimButtonCount"), nCount))
	self.wndClaimBtn:Enable(nCount > 0)
	
	if nCount > 0 then
		Sound.Play(Sound.PlayUIMTXStoreClaimCounter)
	end
end

---------------------------------------------------------------------------------------------------
-- NavSearch Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnSearchTimer()
	self.timerSearch:Stop()
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupSearchItemPage()
end

function Storefront:NavSearchTextChanged(wndHandler, wndControl, strText)
	if wndHandler ~= wndControl then
		return
	end
	
	if strText == nil or strText == "" then		
		self.timerSearch:Stop()
		
		self.tWndRefs.wndNavSearchClearBtn:Show(false)
		
		local wndNavBtn = self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn")
		self:OnFeaturedCheck(wndNavBtn, wndNavBtn)
		wndNavBtn:SetCheck(true)
		wndControl:SetFocus()
	else
		if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
			for idx, wndNav in pairs(self.tWndRefs.wndNavigation:GetChildren()) do
				local wndNavBtn = wndNav:FindChild("NavBtn")
				if wndNavBtn ~= nil and wndNavBtn:IsValid() then
					wndNavBtn:SetCheck(false)
				end
				local wndChildren = wndNav:FindChild("Children")
				if wndChildren ~= nil and wndChildren:IsValid() then
					wndChildren:DestroyChildren()
					wndNav:MoveToLocation(wndNav:GetOriginalLocation())
				end
			end
			self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end
		self.wndNavInUse = nil
	
		self.tWndRefs.wndNavSearchClearBtn:Show(true)
		self.timerSearch:Set(0.25)--Reset timer because player is still typing.
	end
end

function Storefront:NavSearchTextClearSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.timerSearch:Stop()
	
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:Show(false)
	
	local wndNavBtn = self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn")
	self:OnFeaturedCheck(wndNavBtn, wndNavBtn)
	wndNavBtn:SetCheck(true)
	wndNavBtn:SetFocus()
end

---------------------------------------------------------------------------------------------------
-- NavPrimary Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnNavPrimaryCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tCategory = tData
	
	local wndChildren = wndControl:GetParent():FindChild("Children")
	if wndChildren ~= nil then
		if next(wndChildren:GetChildren()) ~= nil then
			wndChildren:DestroyChildren()
		end
		
		for idx, tSubCategory in pairs(tCategory.tGroups) do
			if tSubCategory.bDisplayable then
				local wndCategory = Apollo.LoadForm(self.xmlDoc, "NavSecondary", wndChildren, self)
				self.tNavSubCategoryWndRefs[tSubCategory.nId] = wndCategory
				local wndNavBtn = wndCategory:FindChild("SecondaryNavBtn")
				wndNavBtn:SetText(tSubCategory.strName)
				wndNavBtn:SetData(tSubCategory)
				wndNavBtn:SetTooltip(tSubCategory.strDescription)
			end
		end
		
		local nHeight = wndChildren:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		local nLeft, nTop, nRight, nBottom = wndControl:GetParent():GetAnchorOffsets()
		wndControl:GetParent():SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + self.knNavPrimaryDefaultHeight + wndControl:GetParent():FindChild("Padding"):GetHeight())
		
		self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	self.wndNavInUse = wndControl
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupCategoryItemPage(tCategory)
	
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
end

function Storefront:OnNavPrimaryUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndChildren = wndControl:GetParent():FindChild("Children")
	
	if wndChildren ~= nil then
		wndChildren:DestroyChildren()
		self.tNavSubCategoryWndRefs = {}
		wndControl:GetParent():MoveToLocation(wndControl:GetParent():GetOriginalLocation())
		
		self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	
	self.wndNavInUse = nil
	
end

function Storefront:OnSignatureCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self:CenterShowHelper(self.tWndRefs.wndSignature)
	
	if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
		self.wndNavInUse:SetCheck(false)
	end
	self.wndNavInUse = wndControl
	
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
end

function Storefront:OnFeaturedCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self:CenterShowHelper(self.tWndRefs.wndSplash)
	self:SetupFeatured()
	
	if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
		self.wndNavInUse:SetCheck(false)
	end
	self.wndNavInUse = wndControl
	
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
end

---------------------------------------------------------------------------------------------------
-- NavSecondary Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnNavSecondaryCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tSubCategory = tData
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupCategoryItemPage(tSubCategory)
	
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
end

---------------------------------------------------------------------------------------------------
-- Item Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnOfferPreviewSignal(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()
	self.tWndRefs.wndDialogPurchaseConfirmSectionStack:SetVScrollPos(0)
	self:SetupOffer(tData.tOffer, 1, tData.nCategoryId)
	
	self.tWndRefs.wndModelDialog:Show(true)
end

function Storefront:OnOfferItemGenerateTooltip(wndHandler, wndControl, eToolTipType, x, y)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tDisplayInfo = tData.tDisplayInfo
	
	local wndTooltip = wndControl:LoadTooltipForm(self.xmlDoc, "ItemTooltip", self)
	
	wndTooltip:FindChild("Title"):SetAML("<P Font=\"CRB_HeaderSmall\" TextColor=\"White\">"..tOffer.strName.."</P>")
	wndTooltip:FindChild("Title"):SetHeightToContentHeight()
	wndTooltip:FindChild("Description"):SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloTitle\">"..tOffer.strDescription.."</P>")
	wndTooltip:FindChild("Description"):SetHeightToContentHeight()
	
	-- Callout
	local wndItemCallout = wndTooltip:FindChild("ItemCallout")
	if tOffer.tFlags.bLimitedTime then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].strTooltip)
		
	elseif tOffer.tFlags.bRecommended then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].strTooltip)
		
	elseif tOffer.tFlags.bNew then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].strTooltip)
		
	elseif tOffer.tFlags.bPopular then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].strTooltip)
		
	else
		wndItemCallout:Show(false)
	end
	
	-- Banners
	local wndBannerContainer = wndTooltip:FindChild("BannerContainer")
	self:BuildBannersForContainer(tOffer, tOfferInfo, wndBannerContainer)
	
	local nBannerContainerHeight = wndBannerContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndBannerContainer:Show(nBannerContainerHeight > 0)
	if nBannerContainerHeight > 0 then
		local nLeft, nTop, nRight, nBottom = wndBannerContainer:GetAnchorOffsets()
		wndBannerContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nBannerContainerHeight)
	end
	
	-- Price	
	local wndPriceContainer = wndTooltip:FindChild("PriceContainer")
	
	local nLargestDiscount = 0
	
	-- Price NCoins
	nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price1BG"), tOfferInfo.tPrices.tNCoins))
	
	-- Price Omnibits
	nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price2BG"), tOfferInfo.tPrices.tOmnibits))
	
	wndPriceContainer:FindChild("or"):Show(tOfferInfo.tPrices.tNCoins ~= nil and tOfferInfo.tPrices.tOmnibits ~= nil)
	
	if nLargestDiscount == 0 and not self:HasDiscount(tOfferInfo) then
		local nLeft, nTop, nRight, nBottom = wndPriceContainer:GetAnchorOffsets()
		wndPriceContainer:SetAnchorOffsets(nLeft, nTop + 25, nRight, nBottom)
	end
	
	wndPriceContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	
	-- Sizing
	local wndSectionStack = wndTooltip:FindChild("SectionStack")
	local nSectionStackHeight = wndSectionStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nSectionStackHeightChange = nSectionStackHeight - wndSectionStack:GetHeight()
	
	local nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
	wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nSectionStackHeightChange)
end

---------------------------------------------------------------------------------------------------
-- Layout Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnAccountInventorySignal(wndHandler, wndControl, eMouseButton)
	OpenAccountInventory()
end

function Storefront:OnDialogCancelSignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndModelDialog:Show(false)
end

function Storefront:OnBannerSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	if tData == nil then
		return
	end
	
	if tData.eBannerProductType == StorefrontLib.BannerPageType.Product
		or tData.eBannerProductType == StorefrontLib.BannerLocation.OfferGroup then
		
		self:SetupOffer(StorefrontLib.GetOfferGroupInfo(tData.nBannerProduct), 1, 0)
		self.tWndRefs.wndModelDialog:Show(true)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.SearchTerm then
		self.tWndRefs.wndNavSearchEditBox:SetText(tData.strBannerProduct)
		self:NavSearchTextChanged(self.tWndRefs.wndNavSearchEditBox, self.tWndRefs.wndNavSearchEditBox, tData.strBannerProduct)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.Category then
		self:ShowCategoryPage(tData.nBannerProduct)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.BrowserLink then
		StorefrontLib.OpenBannerBrowserLink(tData.nStoreBannerId)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.Signature then
		self:OnOpenSignature()
	end
end

function Storefront:ShowCategoryPage(nCategoryId)
	local bMatchedSubCategory = false
	for idx, tPrimaryCategory in pairs(StorefrontLib.GetCategoryTree()) do
		if tPrimaryCategory.nId == nCategoryId then
				
			if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
				self.wndNavInUse:SetCheck(false)
			end
			
			local wndPrimaryNavBtn = self.tNavCategoryWndRefs[tPrimaryCategory.nId]:FindChild("NavBtn")
			self:OnNavPrimaryCheck(wndPrimaryNavBtn, wndPrimaryNavBtn)
			wndPrimaryNavBtn:SetCheck(true)
				
			break
		end
			
		for idx, tSubCategory in pairs(tPrimaryCategory.tGroups) do
			if tSubCategory.nId == nCategoryId then
				bMatchedSubCategory = true
					
				if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
					self.wndNavInUse:SetCheck(false)
				end
					
				local wndPrimaryNavBtn = self.tNavCategoryWndRefs[tPrimaryCategory.nId]:FindChild("NavBtn")
				self:OnNavPrimaryCheck(wndPrimaryNavBtn, wndPrimaryNavBtn)
				wndPrimaryNavBtn:SetCheck(true)
					
				local wndSecondaryNavBtn = self.tNavSubCategoryWndRefs[tSubCategory.nId]:FindChild("SecondaryNavBtn")
				self:OnNavSecondaryCheck(wndSecondaryNavBtn, wndSecondaryNavBtn)
				wndSecondaryNavBtn:SetCheck(true)
					
				break
			end
		end
			
		if bMatchedSubCategory then
			break
		end
	end
end
-- Add funds
function Storefront:OnAddFundsSignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndModelDialog:Show(true)
	self:DialogShowHelper(self.tWndRefs.wndDialogAddFunds)
	
	self:BuildFundsPackages()
end

function Storefront:OnAddFundsCancelSignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndModelDialog:Show(false)
end

function Storefront:OnAddFundsFinalize(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	local tSelf = self
	WhenAll(PromiseFromGameEvent("StorePurchaseVirtualCurrencyPackageResult", self):Then(function(bSuccess, eError)
		if not bSuccess then
			tSelf:AccountCurrencyChanged()
		end
	end), PromiseFromGameEvent("AccountCurrencyChanged", self)):Then(function(tFundsResult)
		if tFundsResult[1] then --bSuccess
			tSelf.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
		
			tSelf.tWndRefs.wndModelDialog:Show(true)
			tSelf:DialogShowHelper(tSelf.tWndRefs.wndDialogAddFunds)
			tSelf:AddFundsDialogShowHelper(tSelf.tWndRefs.wndDialogAddFundsConfirmed)
			
			tSelf.tWndRefs.wndDialogAddFundsFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupGreen")
			tSelf.tWndRefs.wndDialogAddFundsConfirmedAnimation:SetSprite("BK3:UI_BK3_OutlineShimmer_anim_nocycle")
			tSelf.tWndRefs.wndDialogAddFundsConfirmedAnimationInner:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
			
			tSelf.bUpdateHistory = true
		else
			tSelf.tWndRefs.wndFullBlocker:Show(true)
			tSelf:FullBlockerHelper(tSelf.tWndRefs.wndFullBlockerPrompt)
			
			local strMessage
			local eError = tFundsResult[2] --eError
			if tSelf.ktErrorMessages[eError] ~= nil then
				strMessage = tSelf.ktErrorMessages[eError]
			else
				strMessage = Apollo.GetString("Storefront_PurchaseProblemGeneral")
			end
			
			tSelf.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_PurchaseFailedNCoin"))
			tSelf.tWndRefs.wndFullBlockerPromptBody:SetText(strMessage)
			tSelf.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
		end
	end)
	
	StorefrontLib.PurchaseVirtualCurrencyPackage(tData.nPackageId, tData.nPrice)
	
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_PurchaseInProgressThanks"))
end

function Storefront:OnAddFundsWebSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToAccountSettings()
end

-- Order History

function Storefront:OnPurchaseHistorySignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndModelDialog:Show(true)
	self:DialogShowHelper(self.tWndRefs.wndDialogHistory)

	if self.bUpdateHistory then
		StorefrontLib.RequestHistory()
		self.bUpdateHistory = false
	end
	
	self:BuildHistory()
end

function Storefront:OnHistoryCancelSignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndModelDialog:Show(false)
end

-- Sorting
function Storefront:ToggleSortCheckBox(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self.tSortingOptions =  wndControl:IsChecked() and wndControl:GetData() or {}
	self.nFilterOptions = wndControl:IsChecked() and wndControl:GetData() and wndControl:GetData().eDisplayFlag or 0

	if self.tLastCategory then
		self:SetupCategoryItemPage(self.tLastCategory)
	else
		self:SetupSearchItemPage()
	end
end

function Storefront:OnPurchaseWithCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	local tData = wndControl:GetData()
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)	
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_CurrencyAfterPurchase"), strCurrencyName))
	if monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount() >= 0 then
		local monAfter = Money.new()
		monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
		monAfter:SetAmount(monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount())
		
		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:SetAmount(monAfter, true)
		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:SetTextColor(ApolloColor.new("white"))

		
		self.tWndRefs.wndDialogPurchaseConfirmNotEnoughOmnibits:Show(false)
		self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:Show(true)
		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative:Show(false)
	else
		local monAfter = Money.new()
		monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
		monAfter:SetAmount(tData.tPrice.monPrice:GetAmount() - monBalance:GetAmount())

		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:SetAmount(monAfter, true)
		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:SetTextColor(ApolloColor.new("Reddish"))
		
		self.tWndRefs.wndDialogPurchaseConfirmNotEnoughOmnibits:Show(tData.tPrice.eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.Omnibits)
		self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:Show(tData.tPrice.eCurrencyType ~= AccountItemLib.CodeEnumAccountCurrency.Omnibits)
		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative:Show(true)
		
		local nWidth = self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:GetDisplayWidth()
		local nFundsValueRight = math.abs(({self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:GetAnchorOffsets()})[3]) --3 is the right offset
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative:GetAnchorOffsets()
		
		nRight = -nWidth - nFundsValueRight
		nLeft = nRight - self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative:GetWidth()
		
		self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValueNegative:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	end

	if tData.tPrice.eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
		self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:SetText(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithOmnibits")))
		self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithOmnibitsTooltip")))
	else
		self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:SetText(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithCurrency"), strCurrencyName))
	end

	self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:SetData(tData)
	self.tWndRefs.wndDialogPurchaseConfirmFinalizeBtn:Enable(true)
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterBG:Show(true)
	
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterLabel:Show(true)
	self.tWndRefs.wndDialogPurchaseConfirmFundsAfterValue:Show(true)
	self.tWndRefs.wndDialogPurchaseConfirmSummaryContainer:Show(true)
	
	self.tWndRefs.wndDialogPurchaseConfirmNoCurrencySelected:Show(false)
end

function Storefront:OnPurchaseConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	if monBalance:GetAmount() < tData.tPrice.monPrice:GetAmount() then
		if tData.tPrice.eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
			local tFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
			if #tFundPackages > 0 then
				self:PurchaseNeedMoreFunds(tData)
			else
				self:PurchaseNeedMoreFundsNoCC(tData)
			end
		else
			-- How did we get here?
		end
	else
		local tSelf = self
		WhenAll(PromiseFromGameEvent("StorePurchaseOfferResult", self):Then(function(bSuccess)
				if not bSuccess then
					tSelf:AccountCurrencyChanged()
				end
			end), PromiseFromGameEvent("AccountCurrencyChanged", self)):Then(function(tPurchaseResult)
			if tPurchaseResult[1] then -- bSuccess
				tSelf.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
				tSelf:PurchaseConfirmed(tData)
				
				tSelf.bUpdateHistory = true
			else
				tSelf.tWndRefs.wndFullBlocker:Show(true)
				tSelf:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
				
				tSelf.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_PurchaseFailedDialogHeader"))
				tSelf.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_PurchaseFailedDialogBody"))
				tSelf.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = Storefront.OnStorePurchaseOfferFailureResultAccept })
			end
		end)
		
		StorefrontLib.PurchaseOffer(tData.tOfferInfo.nId, tData.tPrice.monPrice, tData.nCategoryId)
		self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
		self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_PurchaseInProgressThanks"))
	end
end

function Storefront:OnPurchaseConfirmedSignal(wndHandler, wndControl, eMouseButton)
	OpenAccountInventory()
end

function Storefront:OnPurchaseConfirmedContinueSignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndModelDialog:Show(false)
end

function Storefront:OnPurchaseNeedsFundsNoCCWebSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToAccountSettings()
end

function Storefront:OnCloseStoreSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	CloseStore()
end

function Storefront:OnFullDialogPromptConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
	
	local tData = wndControl:GetData()
	if tData.fnCallback ~= nil then
		tData.fnCallback(self)
	end
end

function Storefront:OnSignatureBuySignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToSignatureOffer()
end

function Storefront:OnPreviewOnMeCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	self.tWndRefs.wndDialogPurchasePreview:SetCostume(unitPlayer)
	for _, tAccountItem in pairs(tData.tItems) do
		if tAccountItem.nStoreDisplayInfoId == tData.tDisplayInfo.nId and tAccountItem.item ~= nil then
			self.tWndRefs.wndDialogPurchasePreview:SetItem(tAccountItem.item)
		end
	end
	
	self.tWndRefs.wndDialogPurchasePreviewSheathedBtn:Show(true)
	self.tWndRefs.wndDialogPurchasePreviewSheathedBtn:SetCheck(true)
	self.tWndRefs.wndDialogPurchasePreview:SetSheathed(true)
	
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndDialogPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eStand)
	end
end

function Storefront:OnPreviewOnMeUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	self:SetupPreviewWindow(self.tWndRefs.wndDialogPurchaseLeft, tData.tDisplayInfo, tData.tItems)
	self.tWndRefs.wndDialogPurchasePreviewSheathedBtn:Show(false)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndDialogPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eStand)
	end
end

function Storefront:OnPreviewSheathedCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndDialogPurchasePreview:SetSheathed(true)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndDialogPurchasePreview:SetModelSequence(StorefrontLib.CodeEnumModelSequence.DefaultStand)
	end
end

function Storefront:OnPreviewSheathedUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndDialogPurchasePreview:SetSheathed(false)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndDialogPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eReady)
	end
end

function Storefront:OnAddFundsConfirmedSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndModelDialog:Show(true)
	self:DialogShowHelper(self.tWndRefs.wndDialogAddFunds)
	
	self:BuildFundsPackages()
end

function Storefront:OnNCoinFlyerTransitionComplete(wndHandler, wndControl)
	self.tWndRefs.wndFlyerContainerNCoin:Show(false)
end

function Storefront:OnPurchaseNeedsFundsConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice
	local tFundPackage = tData.tFundPackage
	local nCategoryId = tData.nCategoryId
	
	local tSelf = self
	WhenAll(PromiseFromGameEvent("StorePurchaseVirtualCurrencyPackageResult", self):Then(function(bSuccess, eError)
		if not bSuccess then
			tSelf:AccountCurrencyChanged()
		end
	end), PromiseFromGameEvent("AccountCurrencyChanged", self)):Then(function(tFundsResult)
		if tFundsResult[1] then --bSuccess
			WhenAll(PromiseFromGameEvent("StorePurchaseOfferResult", tSelf):Then(function(bSuccess)
				if not bSuccess then
					tSelf:AccountCurrencyChanged()
				end
			end), PromiseFromGameEvent("AccountCurrencyChanged", tSelf)):Then(function(tPurchaseResult)
				if tPurchaseResult[1] then --bSuccess
					tSelf.tWndRefs.wndFullBlocker:Show(false)
					tSelf:PurchaseConfirmed(tData)
					
					tSelf.bUpdateHistory = true
				else
					tSelf.tWndRefs.wndFullBlocker:Show(true)
					tSelf:FullBlockerHelper(tSelf.tWndRefs.wndFullBlockerPrompt)
					
					tSelf.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_PurchaseFailedDialogHeader"))
					tSelf.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_PurchaseFailedDialogBody"))
					tSelf.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = Storefront.OnStorePurchaseOfferFailureResultAccept })
				end
			end)
			
			StorefrontLib.PurchaseOffer(tOfferInfo.nId, tPrice.monPrice, nCategoryId)
		else
			tSelf.tWndRefs.wndFullBlocker:Show(true)
			tSelf:FullBlockerHelper(tSelf.tWndRefs.wndFullBlockerPrompt)
			
			local strMessage
			local eError = tFundsResult[2] --eError
			if tSelf.ktErrorMessages[eError] ~= nil then
				strMessage = tSelf.ktErrorMessages[eError]
			else
				strMessage = Apollo.GetString("Storefront_PurchaseProblemGeneral")
			end
			
			tSelf.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_PurchaseFailedNCoin"))
			tSelf.tWndRefs.wndFullBlockerPromptBody:SetText(strMessage)
			tSelf.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
		end
	end)
	
	-- Start
	StorefrontLib.PurchaseVirtualCurrencyPackage(tFundPackage.nPackageId, tFundPackage.nPrice)
	
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_PurchaseInProgressThanks"))
end

---------------------------------------------------------------------------------------------------
-- VariantListItem Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnVariantListItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	local nHorzScroll = self.tWndRefs.wndDialogPurchaseConfirmVariantContainer:GetHScrollPos()
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
	self.tWndRefs.wndDialogPurchaseConfirmVariantContainer:SetHScrollPos(nHorzScroll)
end

---------------------------------------------------------------------------------------------------
-- QuantityDropdownItem Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnQuantityItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	local nHorzScroll = self.tWndRefs.wndDialogPurchaseConfirmVariantContainer:GetHScrollPos()
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
	self.tWndRefs.wndDialogPurchaseConfirmVariantContainer:SetHScrollPos(nHorzScroll)
end

---------------------------------------------------------------------------------------------------
-- BundleListItem Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnBundleListItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	self:SetupPreviewWindow(self.tWndRefs.wndDialogPurchaseLeft, tData.tBundleDisplayInfo, tData.tItems)
	
	
	if self.tWndRefs.wndDialogPurchasePreviewOnMeBtn:IsChecked()
		and tData.tBundleDisplayInfo ~= nil
		and tData.tBundleDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
		
		local wndPreviewFrame = self.tWndRefs.wndDialogPurchaseLeft:FindChild("PreviewFrame")
	
		wndPreviewFrame:SetCostume(GameLib.GetPlayerUnit())
		for _, tAccountItem in pairs(tData.tItems) do
			if tAccountItem.nStoreDisplayInfoId == tData.tBundleDisplayInfo.nId and tAccountItem.item ~= nil then
				wndPreviewFrame:SetItem(tAccountItem.item)
			end
		end
	end
	
	self.tWndRefs.wndDialogPurchasePreviewOnMeBtn:SetData({tDisplayInfo = tData.tBundleDisplayInfo, tItems = tData.tItems})
	self.tWndRefs.wndDialogPurchasePreviewOnMeBtn:Show(tData.tBundleDisplayInfo ~= nil and tData.tBundleDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin)
end

---------------------------------------------------------------------------------------------------
-- Loyalty Functions
---------------------------------------------------------------------------------------------------
function Storefront:OnRewardTrackActive(eNewType, rtNew, rtOld)
	if not self.tWndRefs.wndMain or eNewType ~= RewardTrackLib.CodeEnumRewardTrackType.Loyalty then
		return
	end
	
	self:UpdateRewardTrack(rtNew)
end

function Storefront:OnRewardTrackUpdated(rtUpdated)
	if not self.tWndRefs.wndMain or rtUpdated:GetType() ~= RewardTrackLib.CodeEnumRewardTrackType.Loyalty then
		return
	end
	
	self:UpdateRewardTrack(rtUpdated)
end

function Storefront:UpdateRewardTrack(rtUpdated)
	if rtUpdated:GetId() ~= self.wndLoyaltyExpandBtnIcon:GetData() then
		local nMaxProgress = self.wndLoyaltyProgress:GetMax()
		local nProgressTime = 0.5 * (nMaxProgress - self.wndLoyaltyProgress:GetProgress())
		self.wndLoyaltyProgress:SetProgress(nMaxProgress, nProgressTime)
		self.timerToMax:Set(nProgressTime, false, "OnMaximumReached")
	else
		local nCurProgress = rtUpdated:GetRewardPointsEarned()
		local nProgressTime = 2 * (nCurProgress - self.wndLoyaltyProgress:GetProgress())
		self.wndLoyaltyProgress:SetProgress(nCurProgress, math.abs(nProgressTime))
	end
	self:BuildLoyaltyWindow(rtUpdated)
	
	if self.tWndRefs.wndLoyaltyPage:IsShown() then
		self:SetLoyaltyPointProgress(self.nCurRewardPointsEarned)
		self:UpdateLoyaltyPointProgress()
	end
	self.timerLoyaltyPointHeaderProgressUpdate:Start()
end

function Storefront:BuildLoyaltyWindow(rtUpdated)
	if rtUpdated == nil then
		-- Something bad happened
		self:OnStoreError(StorefrontLib.CodeEnumStoreError.CatalogUnavailable)
		return
	end

	local arRewards = rtUpdated:GetAllRewards()
	local nRewardMax = arRewards[#arRewards].nCost
	
	self.nCurRewardPointsEarned = rtUpdated:GetRewardPointsEarned()
	
	local wndLoyaltyNumberComplete = self.wndLoyalty:FindChild("NumberComplete")
	local strNumberComplete = String_GetWeaselString(Apollo.GetString("Storefront_Fraction"), Apollo.FormatNumber(self.nCurRewardPointsEarned, 0, true), Apollo.FormatNumber(nRewardMax, 0, true))
	local strLoyaltyPercent = String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_AuctionhouseTax"), self.nCurRewardPointsEarned / nRewardMax * 100)
	
	wndLoyaltyNumberComplete:SetAML(string.format('<T Font=\"CRB_HeaderTiny\" TextColor=\"UI_TextMetalGoldHighlight\" >%s  </T><T Font=\"CRB_HeaderTiny\" TextColor=\"UI_TextMetalBodyHighlight\" >%s</T>', strNumberComplete, strLoyaltyPercent))

	self.wndLoyaltyProgress:SetMax(nRewardMax)
	if self.wndLoyaltyProgress:GetProgress() == 0 and self.nCurRewardPointsEarned ~= 0 then
		self.wndLoyaltyProgress:SetProgress(self.nCurRewardPointsEarned)
	end
	self.wndLoyaltyProgress:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_LoyaltyBarTooltip"), self.nCurRewardPointsEarned, nRewardMax))
	
	self.wndLoyaltyExpandBtnIcon:SetData(rtUpdated:GetId())
	self.wndLoyaltyExpandBtnIcon:SetSprite(rtUpdated:GetImageAssetPath())
	
	if self.nCurRewardTrackId == rtUpdated:GetId() then -- don't update milestones if the reward track hasn't changed
		return
	end
	
	self.nCurRewardTrackId = rtUpdated:GetId()
	
	local wndMilestoneContainer = self.wndLoyalty:FindChild("LoyaltyMilestoneContainer")
	wndMilestoneContainer:DestroyChildren()
	
	self.tMilestones = { }
	
	local nPreviousCost = 0
	local wndRewardPoint = nil
	for idx, tReward in pairs(arRewards) do
		local wndDropdown = nil
		if tReward.nCost ~= nPreviousCost then
			wndRewardPoint = Apollo.LoadForm(self.xmlDoc, "LoyaltyMilestone", wndMilestoneContainer, self)
			
			local nLeft, nTop, nRight, nBottom = wndRewardPoint:GetOriginalLocation():GetOffsets()
			nRight = self.wndLoyaltyProgress:GetWidth() / nRewardMax * tReward.nCost
			local nHalfWidth = wndRewardPoint:GetWidth() / 2.0
			self.tMilestones[tReward.nCost] = { }
			if idx == #arRewards then
				wndRewardPoint:FindChild("LoyaltyMilestoneIcon"):Destroy()
			else
				wndRewardPoint:FindChild("LoyaltyMilestoneFinalIcon"):Destroy()
				self.tMilestones[tReward.nCost].wndIcon = wndRewardPoint:FindChild("LoyaltyMilestoneIcon")
				self.tMilestones[tReward.nCost].wndAnimation = wndRewardPoint:FindChild("LoyaltyMilestoneAnimation")
				self.tMilestones[tReward.nCost].wndAnimation2 = wndRewardPoint:FindChild("LoyaltyMilestoneAnimation2")
				self.tMilestones[tReward.nCost].bAlreadyCompleted = false
			end
			
			self.tMilestones[tReward.nCost].eSound = self.ktSoundLoyaltyMTXCosmicRewardsUnlock[idx]
			
			wndRewardPoint:SetAnchorOffsets( nRight - nHalfWidth, nTop, nRight + nHalfWidth, nBottom)
			
			wndDropdown = wndRewardPoint:FindChild("RewardPointTooltip")
			wndDropdown:SetData(nRewardMax == tReward.nCost)
		else
			wndDropdown = wndRewardPoint:FindChild("RewardPointTooltip")
		end
		
		local wndPointHeader = wndDropdown:FindChild("Header")
		local wndTooltipContainer = wndDropdown:FindChild("TooltipContainer")
		
		-- Used for resizing later
		local nHeightDelta = wndDropdown:GetHeight() - wndPointHeader:GetHeight() - wndTooltipContainer:GetHeight()
		
		local strRewardHeader = String_GetWeaselString(Apollo.GetString("Storefront_PointsToUnlock"), tReward.nCost)
		if bIsClaimed then
			strRewardHeader = Apollo.GetString("Storefront_RewardClaimed")
		end
		wndPointHeader:SetText(strRewardHeader)
		
		for idx = 1, tReward.nNumRewardChoices do
			local wndTooltip = Apollo.LoadForm(self.xmlDoc, "RewardObject", wndTooltipContainer, self)
			local wndHeader = wndTooltip:FindChild("Header")
			local wndLabel = wndHeader:FindChild("RewardLabel")
			local wndItem = wndHeader:FindChild("ItemReward")
			local wndIcon = wndItem:FindChild("ItemIcon")
			local wndIconPadding = wndItem:FindChild("ItemStackCount")
			local nPadding = 8
			
			if tReward.tRewardChoices[idx].accountItemReward then
				if tReward.tRewardChoices[idx].accountItemReward.item then
					wndLabel:SetText(tReward.tRewardChoices[idx].accountItemReward.item:GetName())
					
					if wndIcon:GetData() == nil then
						wndIcon:GetWindowSubclass():SetItem(tReward.tRewardChoices[idx].accountItemReward.item)
						wndItem:Show(true)
					end
					
					local nStackCount = tReward.tRewardChoices[idx].accountItemReward.item:GetStackCount()
					if nStackCount > 1 then
						wndItem:FindChild("ItemStackCount"):SetText(nStackCount)
					end
				elseif tReward.tRewardChoices[idx].accountItemReward.entitlement then
					wndLabel:SetText(tReward.tRewardChoices[idx].accountItemReward.entitlement.name)
					
					if wndIcon:GetSprite() == "" and tReward.tRewardChoices[idx].accountItemReward.icon ~= "" then
						wndIcon:GetWindowSubclass():SetItem(nil)
						wndIcon:SetSprite(tReward.tRewardChoices[idx].accountItemReward.icon)
						wndItem:Show(true)
					end
				end
				
				local nLabelWidth, nLabelHeight = wndLabel:SetHeightToContentHeight()
				local nHeight = nLabelHeight + nPadding
				if wndIcon:IsShown() and nHeight < wndIconPadding:GetHeight() then
					nHeight = wndIconPadding:GetHeight()
				end

				
				local nOriginalHeaderBottom = ({wndHeader:GetOriginalLocation():GetOffsets()})[4]
				nLeft, nTop, nRight, nBottom = wndHeader:GetAnchorOffsets()
				wndHeader:SetAnchorOffsets(nLeft, nTop, nRight, math.max(nTop + nHeight, nOriginalHeaderBottom))
				
				local nTooltipHeight = wndHeader:GetHeight()
				nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
				wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTooltipHeight)
			end
		end
		
		local nContainerHeight = wndTooltipContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nDropdownHeight = nContainerHeight + wndPointHeader:GetHeight() + nHeightDelta
		
		local nDropdownLeft, nDropdownTop, nDropdownRight, nDropdownBottom = wndDropdown:GetAnchorOffsets()
		wndDropdown:SetAnchorOffsets(nDropdownLeft, nDropdownTop, nDropdownRight, nDropdownTop + nDropdownHeight)
		
		nPreviousCost = tReward.nCost
	end
	
	self:UpdateLoyaltyPointHeaderProgress()
end

function Storefront:OnMaximumReached()
	self:BuildLoyaltyWindow(RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty))
	self.wndLoyaltyProgress:SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
	self.wndLoyaltyExpandBtnAnimation:SetSprite("LoginIncentives:sprLoginIncentives_Burst")
end

function Storefront:ShowMilestoneTooltip(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndTooltip = wndHandler:FindChild("RewardPointTooltip")
		if not wndTooltip:IsShown() then
			wndTooltip:Show(true)
			Sound.Play(self.ktSoundLoyaltyMTXLoyaltyBarHover[wndTooltip:GetData()])
		end
	end
end

function Storefront:HideMilestoneTooltip(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("RewardPointTooltip"):Show(false)
	end
end

function Storefront:OnToggleLoyalty(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local bModelDialogShown = self.tWndRefs.wndModelDialog:IsShown()
	self.tWndRefs.wndModelDialog:Show(not bModelDialogShown)
	self.tWndRefs.wndFullBlocker:Show(false)
	if not bModelDialogShown then
		self:ResetLoyaltyPointProgress()
		self:DialogShowHelper(self.tWndRefs.wndLoyaltyPage)
		self:BuildLoyaltyPage(RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty))
		if self.tWndRefs.wndFullBlocker:IsShown() then
			self.tWndRefs.wndModelDialog:Show(false)
		end
	end	
end

function Storefront:BuildLoyaltyPage(rtUpdated)
	if rtUpdated == nil then
		-- Display error
		self.tWndRefs.wndFullBlocker:Show(true)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
		self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogHeader"))
		self.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogBody"))
		self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
		return
	end
	
	local arRewards = rtUpdated:GetAllRewards()
	if arRewards == nil then
		-- Display error
		self.tWndRefs.wndFullBlocker:Show(true)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
		self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogHeader"))
		self.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogBody"))
		self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
		return
	end
	
	self.rtCurrent = rtUpdated
	
	self.tWndRefs.wndNextTierBtn:Enable(self.rtCurrent:GetChild() ~= nil)
	self.tWndRefs.wndPrevTierBtn:Enable(self.rtCurrent:GetParent() ~= nil)
	
	self.tWndRefs.wndTier:SetText(String_GetWeaselString(Apollo.GetString("Storefront_TierNum"), self.rtCurrent:GetName()))
	self.tWndRefs.wndTierPoints:SetText(String_GetWeaselString(Apollo.GetString("Storefront_LoyaltyPoints"), Apollo.FormatNumber(self.nCurRewardPointsEarned, 0, true)))
	
	self.tWndRefs.wndLoyaltyContentContainer:DestroyChildren()
	
	self.tLoyaltyExpandedItemWindows = { }
	self.tRewardStyles = 
	{ 
		tRewards = { },
		tDefault = 
		{
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneBlue", 
			strBackgroundColor = "UI_AlphaPercent25", 
			strTextColor = "UI_TextHoloBodyCyan", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Upcoming",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemRed",
		},
		tComplete = 
		{
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneGreen", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_WindowTitleYellow", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Complete",
			strBurstSprite = "sprMM_QuestZonePulseNoCycle",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemGreen",
		},
		tFinalRewardDefault = 
		{ 
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneBlueComplete", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_TextHoloBodyHighlight", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Upcoming",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemRed",
		},
		tFinalRewardCurrent = 
		{ 
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneGreenComplete", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_WindowTitleYellow", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Complete",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemGreen",
		},
		tFinalRewardComplete = 
		{ 
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneGreenComplete", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_WindowTitleYellow", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Active",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemYellow",
		},
	}
	
	local arIconWindows = { } -- needed to quickly get and reuse existing windows
	for idx, tReward in pairs(arRewards) do
		local wndLoyaltyExpandedItem = self.tLoyaltyExpandedItemWindows["LoyaltyExpandedItem" .. tReward.nCost] -- reuse windows if they exist
		if wndLoyaltyExpandedItem == nil then -- if not then add them
			wndLoyaltyExpandedItem = Apollo.LoadForm(self.xmlDoc, "LoyaltyExpandedItem", self.tWndRefs.wndLoyaltyContentContainer, self)
			self.tLoyaltyExpandedItemWindows["LoyaltyExpandedItem" .. tReward.nCost] = wndLoyaltyExpandedItem
		end
		
		local wndLoyaltyItemContainer = wndLoyaltyExpandedItem:FindChild("ItemContainer")
		
		if self.tRewardStyles.tRewards[tReward.nCost] == nil then -- don't overwrite existing windows
			arIconWindows = { }
		end
		local nIconWindowCount = #arIconWindows -- get count current count, if it has windows and it can
		for nIdx, tReward in pairs(tReward.tRewardChoices) do
			local wndLoyaltyExpandedIcons = Apollo.LoadForm(self.xmlDoc, "LoyaltyExpandedIcons", wndLoyaltyItemContainer, self)
			
			local wndItemIcon = wndLoyaltyExpandedIcons:FindChild("ItemIcon")
			
			if tReward.accountItemReward.item then
				wndItemIcon:GetWindowSubclass():SetItem(tReward.accountItemReward.item)
				if Tooltip ~= nil and Tooltip.GetItemTooltipForm ~= nil then
					Tooltip.GetItemTooltipForm(self, wndItemIcon, tReward.accountItemReward.item, {bPrimary = true, bSelling = false, itemCompare = nil})
				end
				
			elseif tReward.accountItemReward.entitlement then
				if tReward.accountItemReward.icon ~= "" then
					wndItemIcon:GetWindowSubclass():SetItem(nil)
					wndItemIcon:SetSprite(tReward.accountItemReward.icon)
					self:BuildEntitlementTooltip(wndItemIcon, tReward.accountItemReward.entitlement)
				end
				
			end
			
			arIconWindows[nIconWindowCount + nIdx] = { }
			arIconWindows[nIconWindowCount + nIdx].wndBackground = wndLoyaltyExpandedIcons:FindChild("Background")
			arIconWindows[nIconWindowCount + nIdx].wndIcon = wndItemIcon
		end
		
		local wndLoyaltyPts = wndLoyaltyExpandedItem:FindChild("LoyaltyPoints")
		wndLoyaltyPts:SetText(Apollo.FormatNumber(tReward.nCost, 0, true))
		
		self.tRewardStyles.tRewards[tReward.nCost] = 
		{ 
			wndLoyaltyExpandedItem = wndLoyaltyExpandedItem, 
			wndBackground = wndLoyaltyExpandedItem:FindChild("Background"),
			wndMilestoneRunner = wndLoyaltyExpandedItem:FindChild("MilestoneRunner"),
			wndIndicator = wndLoyaltyExpandedItem:FindChild("Indicator"),
			wndBurst = wndLoyaltyExpandedItem:FindChild("Burst"),
			wndLoyaltyPoints = wndLoyaltyExpandedItem:FindChild("LoyaltyPoints"),
			bLast = idx == #arRewards,
			arChildren = arIconWindows,
			bAlreadyCompleted = false,
			eSound = self.ktSoundLoyaltyMTXCosmicRewardsUnlock[idx]
		}
		
		wndLoyaltyItemContainer:ArrangeChildrenVert()
	end
	
	self:SetLoyaltyPointProgress(self.rtCurrent:GetRewardPointsEarned())
	
	-- Resize reward columns to match progress bar
	local tLoyaltyItemContainers = self.tWndRefs.wndLoyaltyContentContainer:GetChildren()
	local nLoyaltyItemContainers = #tLoyaltyItemContainers
	if nLoyaltyPtsEarned == nil then
		nLoyaltyPtsEarned = 0
		bShowProgressBar = false
	end
	for idx, wndLoyaltyExpandedItem in ipairs(tLoyaltyItemContainers) do
		local nLeft, nTop, nRight, nBottom = wndLoyaltyExpandedItem:GetAnchorOffsets()
		local nLoyaltyExpandedItemWidth = self.tWndRefs.wndLoyaltyProgressBar:GetWidth() /  nLoyaltyItemContainers
		wndLoyaltyExpandedItem:SetAnchorOffsets(nLeft, nTop, nLeft + nLoyaltyExpandedItemWidth, nBottom)
	end
	
	self:UpdateLoyaltyPointProgress()
	
	self.tWndRefs.wndLoyaltyContentContainer:ArrangeChildrenHorz()
end

function Storefront:OnNextTier(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(0) -- Need to empty the progress bar
	self:BuildLoyaltyPage(self.rtCurrent:GetChild())
end

function Storefront:OnPrevTier(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:BuildLoyaltyPage(self.rtCurrent:GetParent())
end

function Storefront:BuildEntitlementTooltip(wndParent, tEntitlement)
	local wndEntitlementTooltip = wndParent:LoadTooltipForm(self.xmlDoc, "EntitlementTooltip", self)
	local wndEntitlementTooltipContainer = wndEntitlementTooltip:FindChild("Container")
	local wndEntitlementName = wndEntitlementTooltipContainer:FindChild("Name")
	local wndEntitlementDescription = wndEntitlementTooltipContainer:FindChild("Description")
	
	local nHeight = wndEntitlementTooltip:GetHeight()
	local nContainerHeight = wndEntitlementTooltipContainer:GetHeight()
	local nHeightPadding = nHeight - nContainerHeight
	
	wndEntitlementName:SetText(tEntitlement.name)
	wndEntitlementName:SetHeightToContentHeight()
	wndEntitlementDescription:SetText(tEntitlement.description)
	wndEntitlementDescription:SetHeightToContentHeight()
	
	local nLeft, nTop, nRight, nBottom = wndEntitlementTooltip:GetAnchorOffsets()
	
	nContainerHeight = wndEntitlementTooltipContainer:ArrangeChildrenVert()
	wndEntitlementTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nHeightPadding + nContainerHeight)
end

function Storefront:SetLoyaltyPointProgress(nPoints)
	local nCurrentProgress = self.tWndRefs.wndLoyaltyProgressBar:GetProgress()
	local nRewardTrackId = self.rtCurrent:GetId()
	
	local arRewards = self.rtCurrent:GetAllRewards()
	local bShowProgressBar = true
	if nPoints == nil then
		nPoints = 0
		bShowProgressBar = false
	end
	local nMaxPts = arRewards[#arRewards].nCost
	
	-- Calculate the fill rate per second of the progress bar
	local tLoyaltyItemContainers = self.tWndRefs.wndLoyaltyContentContainer:GetChildren()
	local nLoyaltyItemContainers = #tLoyaltyItemContainers
	local nLoyaltyItemProgressBarConstant = 2.5
	if nLoyaltyItemContainers == 0 then	-- can't divide by zero
		nLoyaltyItemContainers = 1
	end
	local nProgressRate = (nMaxPts / nLoyaltyItemContainers) * nLoyaltyItemProgressBarConstant
	
	-- Initial values of progress bar for animated progress
	self.tWndRefs.wndLoyaltyProgressBar:SetMax(nMaxPts)
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(nCurrentProgress)
	
	local nPercentCompleted = nPoints / nMaxPts
	local nProgressBarWidth = self.tWndRefs.wndLoyaltyProgressBar:GetWidth()
	
	-- Reset progress bar points display
	local tLoyaltyPointProgressLoc = self.tWndRefs.wndLoyaltyPointProgress:GetOriginalLocation()
	local nLeft, nTop, nRight, nBottom = tLoyaltyPointProgressLoc:GetOffsets()
	local nPntLeft, nPntTop, nPntRight, nPntBottom = tLoyaltyPointProgressLoc:GetPoints()
	self.tWndRefs.wndLoyaltyPointProgress:SetText(Apollo.FormatNumber(nCurrentProgress, 0, true))
	self.tWndRefs.wndLoyaltyPointProgress:SetData(nPoints)
	
	local nLoyaltyPointProgPos = nProgressBarWidth * nPercentCompleted
	
	self.tWndRefs.wndTierIcon:SetSprite(self.rtCurrent:GetImageAssetPath())
	
	if self.nCurRewardTrackId ~= nRewardTrackId then
		nProgressRate = nil
		nPercentCompleted = 1
		nLoyaltyPointProgPos = nProgressBarWidth * nPercentCompleted
		self.tWndRefs.wndLoyaltyPointProgress:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	else 
		self.tWndRefs.wndLoyaltyPointProgress:SetAnchorOffsets(self.tWndRefs.wndLoyaltyPointProgress:GetAnchorOffsets())
		local tLoc = WindowLocation.new({ fPoints = { nPntLeft, nPntTop, nPntRight, nPntBottom }, nOffsets = { nLeft + nLoyaltyPointProgPos, nTop, nRight + nLoyaltyPointProgPos, nBottom }})
		self.tWndRefs.wndLoyaltyPointProgress:TransitionMove(tLoc, math.abs(nPoints - nCurrentProgress) / nProgressRate)
		self.timerLoyaltyPointProgressUpdate:Start()
	end
	if not bShowProgressBar then --Progress bar isn't shown on future tiers
		self.tWndRefs.wndTierIcon:SetBGColor("UI_AlphaBlackPercent50")
		self.tWndRefs.wndTierIcon:FindChild("LockIcon"):Show(true)
		self.tWndRefs.wndTierBody:SetText(Apollo.GetString("Storefront_CosmicPointTierLocked"))
		self.tWndRefs.wndTierBody:SetTextColor("Reddish")
	else
		self.tWndRefs.wndTierIcon:SetBGColor("white")
		self.tWndRefs.wndTierIcon:FindChild("LockIcon"):Show(false)
		self.tWndRefs.wndTierBody:SetText(Apollo.GetString("Storefront_CosmicPointsDescription"))
		self.tWndRefs.wndTierBody:SetTextColor("UI_TextHoloBodyCyan")
	end
	self.tWndRefs.wndLoyaltyProgressBar:Show(bShowProgressBar)
	self.tWndRefs.wndLoyaltyProgressBar:EnableGlow(self.nCurRewardTrackId == nRewardTrackId)
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(nPoints, nProgressRate)
	self.tWndRefs.wndLoyaltyPointProgress:Show(self.nCurRewardTrackId == nRewardTrackId)
end

function Storefront:ResetLoyaltyPointProgress()
	local rtCurrent = self.rtCurrent
	if rtCurrent == nil then
		rtCurrent = RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty)
	end
	local nRewardPointsEarned = self.nCurRewardPointsEarned
	if nRewardPointsEarned == nil then
		nRewardPointsEarned = rtCurrent:GetRewardPointsEarned()
	end
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndLoyaltyPointProgress:GetOriginalLocation():GetOffsets()
	self.tWndRefs.wndLoyaltyPointProgress:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	self.tWndRefs.wndLoyaltyPointProgress:SetText("0")
	self.tWndRefs.wndLoyaltyPointProgress:SetData(nRewardPointsEarned)
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(0)
end

function Storefront:UpdateLoyaltyPointProgress(nTimeMS)
	local nProgress = self.tWndRefs.wndLoyaltyProgressBar:GetProgress()
	self.tWndRefs.wndLoyaltyPointProgress:SetText(Apollo.FormatNumber(nProgress, 0, true))
	
	local nLoyaltyPtsEarned = self.tWndRefs.wndLoyaltyPointProgress:GetData()
	
	local tLoyaltyItemContainers = self.tRewardStyles.tRewards
	
	local bHasProgress = self.tWndRefs.wndLoyaltyProgressBar:IsShown()
	for nRewardCost, tLoyaltyExpandedItem in pairs(tLoyaltyItemContainers) do
		local bCurComplete = nProgress >= nRewardCost
		local bLastRewards = tLoyaltyExpandedItem.bLast

		local wndLoyaltyExpandedItemBackground = tLoyaltyExpandedItem.wndBackground
		local bAlreadyCompleted = tLoyaltyExpandedItem.bAlreadyCompleted
		if bCurComplete and bHasProgress and not bAlreadyCompleted then -- Should update the background, icons, and text
			Sound.Play(tLoyaltyExpandedItem.eSound)
			if bLastRewards then -- Is on the final reward column
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tFinalRewardComplete.strIndicatorSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tFinalRewardComplete.strBackgroundSprite)
			else
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tComplete.strIndicatorSprite)
				tLoyaltyExpandedItem.wndBurst:SetSprite(self.tRewardStyles.tComplete.strBurstSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tComplete.strBackgroundSprite)
			end
			tLoyaltyExpandedItem.wndLoyaltyPoints:SetTextColor(self.tRewardStyles.tComplete.strTextColor)
			wndLoyaltyExpandedItemBackground:SetBGColor(self.tRewardStyles.tComplete.strBackgroundColor)
			
			for nIdx, tLoyaltyExpandedIcons in ipairs(tLoyaltyExpandedItem.arChildren) do
				local wndLoyaltyExpandedIconsBG = tLoyaltyExpandedIcons.wndBackground
				local wndLoyaltyExpandedIconsItemIcon = tLoyaltyExpandedIcons.wndIcon
				
				local strSprite = self.tRewardStyles.tComplete.strIconSprite
				if bLastRewards then
					strSprite = self.tRewardStyles.tFinalRewardComplete.strIconSprite
				end
				wndLoyaltyExpandedIconsBG:SetSprite(strSprite)
				wndLoyaltyExpandedIconsItemIcon:SetBGColor(self.tRewardStyles.tComplete.strBackgroundColor)
				wndLoyaltyExpandedIconsBG:SetBGColor(self.tRewardStyles.tComplete.strBackgroundColor)
			end
			tLoyaltyExpandedItem.bAlreadyCompleted = true
			
		elseif not bCurComplete and (bAlreadyCompleted or bLastRewards) then
			if bLastRewards then -- Is on the final reward column
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tFinalRewardDefault.strIndicatorSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tFinalRewardDefault.strBackgroundSprite)
				tLoyaltyExpandedItem.wndMilestoneRunner:Show(true)
				
				tLoyaltyExpandedItem.wndLoyaltyPoints:SetTextColor(self.tRewardStyles.tFinalRewardDefault.strTextColor)
				wndLoyaltyExpandedItemBackground:SetBGColor(self.tRewardStyles.tFinalRewardDefault.strBackgroundColor)
			else
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tDefault.strIndicatorSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tDefault.strBackgroundSprite)
				
				tLoyaltyExpandedItem.wndLoyaltyPoints:SetTextColor(self.tRewardStyles.tDefault.strTextColor)
				wndLoyaltyExpandedItemBackground:SetBGColor(self.tRewardStyles.tDefault.strBackgroundColor)
			end
			
			for nIdx, tLoyaltyExpandedIcons in ipairs(tLoyaltyExpandedItem.arChildren) do
				local wndLoyaltyExpandedIconsBG = tLoyaltyExpandedIcons.wndBackground
				local wndLoyaltyExpandedIconsItemIcon = tLoyaltyExpandedIcons.wndIcon
				
				wndLoyaltyExpandedIconsBG:SetSprite(self.tRewardStyles.tDefault.strIconSprite)
				wndLoyaltyExpandedIconsItemIcon:SetBGColor(self.tRewardStyles.tDefault.strBackgroundColor)
				wndLoyaltyExpandedIconsBG:SetBGColor(self.tRewardStyles.tDefault.strBackgroundColor)
			end
			tLoyaltyExpandedItem.bAlreadyCompleted = false
		end
	end
	
	if nProgress == nLoyaltyPtsEarned then
		self.timerLoyaltyPointProgressUpdate:Stop()
	end
end

function Storefront:UpdateLoyaltyPointHeaderProgress(nTimeMS)
	local nProgress = self.wndLoyaltyProgress:GetProgress()
	
	for nCost, tMilestone in pairs(self.tMilestones) do
		if nProgress >= nCost and not tMilestone.bAlreadyCompleted then
			if tMilestone.wndIcon ~= nil then
				tMilestone.wndIcon:SetSprite("MTX:UI_BK3_MTX_LoyaltyBarMilestoneCompleted")
			end
			if nProgress >= self.nCurRewardPointsEarned then
				if tMilestone.wndAnimation ~= nil then
					tMilestone.wndAnimation:SetSprite("LoginIncentives:sprLoginIncentives_Burst")
					tMilestone.wndAnimation2:SetSprite("CRB_Anim_WindowBirth:Burst_Open")
				end
				Sound.Play(tMilestone.eSound)
			end
			tMilestone.bAlreadyCompleted = true
		elseif nProgress < nCost and tMilestone.bAlreadyCompleted then
			if tMilestone.wndIcon ~= nil then
				tMilestone.wndIcon:SetSprite("MTX:UI_BK3_MTX_LoyaltyBarMilestone")
			end
			tMilestone.bAlreadyCompleted = false
		end
	end
	
	if nProgress == self.nCurRewardPointsEarned then
		self.timerLoyaltyPointHeaderProgressUpdate:Stop()
	end
end

---------------------------------------------------------------------------------------------------
-- AddFundsEntry Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnAddFundsFundPackageCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	self.tWndRefs.wndDialogAddFundsFinalizeBtn:SetData(tData)
	self.tWndRefs.wndDialogAddFundsFinalizeBtn:Enable(true)
end

---------------------------------------------------------------------------------------------------
-- AddFundsEntrySlim Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnNeedFundsAddFundsFundPackageCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionExpander:Show(false)
	
	local tFundPackage = wndControl:GetData()
	local tData = self.tWndRefs.wndDialogPurchaseNeedsFundsFinalizeBtn:GetData()
	tData.tFundPackage = tFundPackage
	
	local strBtnText = String_GetWeaselString("$3n - $1n$2c", self:GetRealCurrencyNameFromEnum(tFundPackage.eRealCurrency), tFundPackage.nPrice, tFundPackage.strPackageName)
	self.tWndRefs.wndDialogPurchaseNeedsFundsCurrencyChoicePackageSelectionBtn:SetText(strBtnText)
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValueNegative:Show(false)
	
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)

	local monAfter = Money.new()
	monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
	monAfter:SetAmount(monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount() + tFundPackage.nCount)
	self.tWndRefs.wndDialogPurchaseNeedsFundsFundsAfterValue:SetAmount(monAfter, true)
	
	self.tWndRefs.wndDialogPurchaseNeedsFundsFinalizeBtn:SetData(tData)
	self.tWndRefs.wndDialogPurchaseNeedsFundsFinalizeBtn:Enable(true)
end

local StorefrontInst = Storefront:new()
StorefrontInst:Init()
