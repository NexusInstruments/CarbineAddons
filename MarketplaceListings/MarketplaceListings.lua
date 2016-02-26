-----------------------------------------------------------------------------------------------
-- Client Lua Script for MarketplaceListings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Money"
require "MarketplaceLib"
require "CommodityOrder"
require "StorefrontLib"

local MarketplaceListings = {}
local knMTXUnlockBtnPadding = 12
local knAuctionItemTopContentPadding = 14
local knCommodityItemBottomContentSpacing = 50
local knAuctionItemBottomContentSpacing = 90

local ktTimeRemaining =
{
	[ItemAuction.CodeEnumAuctionRemaining.Expiring]		= Apollo.GetString("MarketplaceAuction_Expiring"),
	[ItemAuction.CodeEnumAuctionRemaining.LessThanHour]	= Apollo.GetString("MarketplaceAuction_LessThanHour"),
	[ItemAuction.CodeEnumAuctionRemaining.Short]		= Apollo.GetString("MarketplaceAuction_Short"),
	[ItemAuction.CodeEnumAuctionRemaining.Long]			= Apollo.GetString("MarketplaceAuction_Long"),
	[ItemAuction.CodeEnumAuctionRemaining.Very_Long]	= Apollo.GetString("MarketplaceAuction_VeryLong")
}

function MarketplaceListings:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MarketplaceListings:Init()
    Apollo.RegisterAddon(self)
end

function MarketplaceListings:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MarketplaceListings.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MarketplaceListings:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady",					"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",				"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("InterfaceMenu_ToggleMarketplaceListings", 	"OnToggle", self)
	Apollo.RegisterEventHandler("ToggleAuctionList", 						"OnToggle", self)

	Apollo.RegisterEventHandler("OwnedItemAuctions", 						"OnOwnedItemAuctions", self)
	Apollo.RegisterEventHandler("OwnedCommodityOrders", 					"OnOwnedCommodityOrders", self)
	Apollo.RegisterEventHandler("CREDDExchangeInfoResults", 				"OnCREDDExchangeInfoResults", self)

	Apollo.RegisterEventHandler("CommodityAuctionRemoved", 					"OnCommodityAuctionRemoved", self)
	Apollo.RegisterEventHandler("CommodityAuctionFilledPartial", 			"OnCommodityAuctionUpdated", self)
	Apollo.RegisterEventHandler("PostCommodityOrderResult", 				"OnPostCommodityOrderResult", self)

	Apollo.RegisterEventHandler("ItemAuctionWon", 							"OnItemAuctionRemoved", self)
	Apollo.RegisterEventHandler("ItemAuctionOutbid", 						"OnItemAuctionRemoved", self)
	Apollo.RegisterEventHandler("ItemAuctionExpired", 						"OnItemAuctionRemoved", self)
	Apollo.RegisterEventHandler("ItemCancelResult", 						"OnItemCancelResult", self)
	Apollo.RegisterEventHandler("ItemAuctionBidPosted", 					"OnItemAuctionUpdated", self)
	Apollo.RegisterEventHandler("PostItemAuctionResult", 					"OnItemAuctionResult", self)
	Apollo.RegisterEventHandler("ItemAuctionBidResult", 					"OnItemAuctionResult", self)
	
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",				"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",					"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",						"RequestData", self)

	Apollo.CreateTimer("MarketplaceUpdateTimer", 60, true)
	Apollo.StopTimer("MarketplaceUpdateTimer")

	self.tCurMaxSlots = { nOrderCount = 0, nAuctionCount = 0 }
	self.nPrevOrderCount = 0
	self.nOrderCount = 0
	self.tOrders = nil
	self.tPrevAuctionsCount = { nSell = 0, nBuy = 0 }
	self.tAuctionsCount = { nSell = 0, nBuy = 0 }
	self.tAuctions = nil
	self.nCreddListCount = 0
	self.tCreddList = nil
	self:RequestData()
end

function MarketplaceListings:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("InterfaceMenu_AuctionListings"), nSaveVersion = 4})
end

function MarketplaceListings:OnInterfaceMenuListHasLoaded()
	local tData = { "InterfaceMenu_ToggleMarketplaceListings", "", "Icon_Windows32_UI_CRB_InterfaceMenu_MarketplaceListings" }
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_AuctionListings"), tData)
	
	self:UpdateInterfaceMenuAlerts()
end

function MarketplaceListings:UpdateInterfaceMenuAlerts()
	local nTotal = self.nOrderCount + self.tAuctionsCount.nSell + self.tAuctionsCount.nBuy + self.nCreddListCount
	if nTotal <= 0 then
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AuctionListings"), {false, "", 0})
	else
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AuctionListings"), {true, "", nTotal})
	end
end

function MarketplaceListings:OnToggle()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
	else
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "MarketplaceListingsForm", nil, self)
		self.wndMTXSlotWarningContainer = self.wndMain:FindChild("MTXSlotWarningContainer")
		self.wndConfirmDelete = self.wndMain:FindChild("ConfirmBlocker")
		local nMainWidth = self.wndMain:GetWidth()
		self.wndMain:SetSizingMinimum(nMainWidth, 300)
		self.wndMain:SetSizingMaximum(nMainWidth, 1000)

		self.wndCreddHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndMain:FindChild("MainScroll"), self)
		self.wndCreddHeader:FindChild("HeaderItemBtn"):SetCheck(true)

		self.wndAuctionBuyHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndMain:FindChild("MainScroll"), self)
		self.wndAuctionBuyHeader:FindChild("HeaderItemBtn"):SetCheck(true)
		self.wndAuctionBuyHeader:FindChild("UnlockCommodityOrderSlotsBtn"):Destroy()

		self.wndAuctionSellHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndMain:FindChild("MainScroll"), self)
		self.wndAuctionSellHeader:FindChild("HeaderItemBtn"):SetCheck(true)
		self.wndAuctionSellHeader:FindChild("UnlockCommodityOrderSlotsBtn"):Destroy()

		self.wndCommodityBuyHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndMain:FindChild("MainScroll"), self)
		self.wndCommodityBuyHeader:FindChild("HeaderItemBtn"):SetCheck(true)
		self.wndCommodityBuyHeader:FindChild("UnlockAuctionAndBidsSlotsBtn"):Destroy()	

		self.wndCommoditySellHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndMain:FindChild("MainScroll"), self)
		self.wndCommoditySellHeader:FindChild("HeaderItemBtn"):SetCheck(true)
		self.wndCommoditySellHeader:FindChild("UnlockAuctionAndBidsSlotsBtn"):Destroy()

		self:ManangeWndAndRequestData()

		Apollo.StartTimer("MarketplaceUpdateTimer")
		Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = Apollo.GetString("InterfaceMenu_AuctionListings"), nSaveVersion = 5 })
		
		self:UpdateSlotNotification()
	end
end

function MarketplaceListings:OnDestroy()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
		Apollo.StopTimer("MarketplaceUpdateTimer")
	end
end

function MarketplaceListings:ManangeWndAndRequestData()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:FindChild("MainScroll"):Show(false)
		self.wndMain:FindChild("WaitScreen"):Show(true)
		for idx, wndCurr in pairs({ self.wndCreddHeader, self.wndAuctionBuyHeader, self.wndAuctionSellHeader, self.wndCommodityBuyHeader, self.wndCommoditySellHeader }) do
			wndCurr:FindChild("HeaderItemList"):DestroyChildren()
		end
	end

	self:RequestData()
	self.bRequestData = nil
end

function MarketplaceListings:RequestData()
	self.bRequestData = true
	MarketplaceLib.RequestOwnedCommodityOrders() -- Leads to OwnedCommodityOrders
	MarketplaceLib.RequestOwnedItemAuctions() -- Leads to OwnedItemAuctions
	CREDDExchangeLib.RequestExchangeInfo() -- Leads to OnCREDDExchangeInfoResults
end

function MarketplaceListings:RedrawData()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self.wndMain:FindChild("MainScroll"):Show(false)
	self.wndMain:FindChild("WaitScreen"):Show(true)
	for idx, wndCurr in pairs({ self.wndCreddHeader, self.wndAuctionBuyHeader, self.wndAuctionSellHeader, self.wndCommodityBuyHeader, self.wndCommoditySellHeader }) do
		wndCurr:FindChild("HeaderItemList"):DestroyChildren()
	end

	if self.tOrders ~= nil then
		self:OnOwnedCommodityOrders(self.tOrders)
	end
	if self.tAuctions ~= nil then
		self:OnOwnedItemAuctions(self.tAuctions)
	end
	if self.tCreddList ~= nil then
		self:OnCREDDExchangeInfoResults({}, self.tCreddList)
	end
end

function MarketplaceListings:OnOwnedItemAuctions(tAuctions)
	local nNewAuctions = 0
	local nNewBids = 0
	if tAuctions then
		for nIdx, aucCurrent in pairs(tAuctions) do
			if not aucCurrent:IsOwned() then
				nNewBids = nNewBids + 1
			else
				nNewAuctions = nNewAuctions + 1
			end
		end
	end
	self.tAuctionsCount = { nSell = nNewAuctions, nBuy = nNewBids}
	if nNewAuctions ~= self.tPrevAuctionsCount.nSell or nNewBids ~= self.tPrevAuctionsCount.nBuy then
		self:UpdateSlotNotification()
	end
	self.tAuctions = tAuctions
	if not self.bRequestData and not (self.wndMain and self.wndMain:IsValid()) then
		return
	end

	for nIdx, aucCurrent in pairs(tAuctions) do
		if aucCurrent and ItemAuction.is(aucCurrent) then
			if self.wndMain and self.wndMain:IsValid() then
				self:BuildAuctionOrder(nIdx, aucCurrent, aucCurrent:IsOwned() and self.wndAuctionSellHeader:FindChild("HeaderItemList") or self.wndAuctionBuyHeader:FindChild("HeaderItemList"))
			end
		end
	end
	
	if self.wndMain and self.wndMain:IsValid() then
		self:SharedDrawMain()
	end
end

function MarketplaceListings:OnOwnedCommodityOrders(tOrders)
	self.nOrderCount = 0
	if tOrders then
		self.nOrderCount = #tOrders
	end
	if self.nOrderCount ~= self.nPrevOrderCount then
		self:UpdateSlotNotification()
	end
	self.tOrders = tOrders
	if not (self.wndMain and self.wndMain:IsValid()) then
		return
	end

	for nIdx, tCurrOrder in pairs(tOrders) do
		if tCurrOrder:IsBuy() then
			self:BuildCommodityOrder(nIdx, tCurrOrder, self.wndCommodityBuyHeader:FindChild("HeaderItemList"))
		else
			self:BuildCommodityOrder(nIdx, tCurrOrder, self.wndCommoditySellHeader:FindChild("HeaderItemList"))
		end
	end

	self:SharedDrawMain()
end

function MarketplaceListings:OnCREDDExchangeInfoResults(arMarketStats, arOrders)
	self.nCreddListCount = 0
	if arOrders then
		self.nCreddListCount = #arOrders
	end
	self.tCreddList = arOrders
	if not self.bRequestData and not (self.wndMain and self.wndMain:IsValid()) then
		return
	end

	for nIdx, tCurrOrder in pairs(self.tCreddList) do
		if self.wndMain and self.wndMain:IsValid() then
			self:BuildCreddOrder(nIdx, tCurrOrder, self.wndCreddHeader:FindChild("HeaderItemList"))
		end
	end

	if self.wndMain and self.wndMain:IsValid() then
		self:SharedDrawMain()
	end
end

function MarketplaceListings:SharedDrawMain()
	local nNumChildren = #self.wndMain:FindChild("MainScroll"):GetChildren()

	self.wndMain:Invoke()
	self.wndMain:FindChild("MainScroll"):Show(true)
	self.wndMain:FindChild("WaitScreen"):Show(false)

	-- Resizing and coloring
	local tHeaders =
	{
		{ strTitleBegin = "Marketplace_CreddLimit",				wnd = self.wndCreddHeader, 			nLimit = 0 }, -- No limit for CREDD
		{ strTitleBegin = "Marketplace_AuctionLimitBuyBegin",	strTitleEnd = "Marketplace_AuctionLimitBuyEnd",	strColor = "white", 	wnd = self.wndAuctionBuyHeader, 	nLimit = MarketplaceLib.GetMaxBids() },
		{ strTitleBegin = "Marketplace_AuctionLimitBegin",		strTitleEnd = "Marketplace_LimitEnd",			strColor = "white", 	wnd = self.wndAuctionSellHeader,	nLimit = MarketplaceLib.GetMaxAuctions() },
		{ strTitleBegin = "Marketplace_CommodityLimitBuyBegin",	strTitleEnd = "Marketplace_LimitEnd",			strColor = "white", 	wnd = self.wndCommodityBuyHeader, 		nLimit = MarketplaceLib.GetMaxCommodityOrders() },
		{ strTitleBegin = "Marketplace_CommodityLimitBegin",	strTitleEnd = "Marketplace_LimitEnd",			strColor = "white", 	wnd = self.wndCommoditySellHeader, 		nLimit = MarketplaceLib.GetMaxCommodityOrders() },
	}
	
	local nLoyaltyAuctionCount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.LoyaltyExtraAuctions)
	local nLoyaltyCommodityCount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.LoyaltyExtraCommodityOrders)
	local nSignatureCount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.Signature)
	local nSignatureAuctionMaxCount = 0
	if nSignatureCount > 0 then
		nSignatureAuctionMaxCount = MarketplaceLib.GetSignatureAuctionsLimit() - nLoyaltyAuctionCount
	end
	local nSignatureCommodityMaxCount = 0
	if nSignatureCount > 0 then
		nSignatureCommodityMaxCount = MarketplaceLib.GetSignatureCommodityLimit() - nLoyaltyCommodityCount
	end
	local nExtraAuctionCount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.ExtraAuctions)
	local nExtraCommodityCount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.ExtraCommodityOrders)
	local nTotalAuctionCount = nSignatureAuctionMaxCount + nExtraAuctionCount + nLoyaltyAuctionCount
	local nTotalCommodityCount = nSignatureCommodityMaxCount + nExtraCommodityCount + nLoyaltyCommodityCount
	if nTotalAuctionCount > 0 then
		tHeaders[2].strColor = "yellow"
		tHeaders[3].strColor = "yellow"
	end
	if nTotalCommodityCount > 0 then
		tHeaders[4].strColor = "yellow"
		tHeaders[5].strColor = "yellow"
	end
	
	for idx, tHeaderData in pairs(tHeaders) do
		local wndCurr = tHeaderData.wnd
		local nChildren = #wndCurr:FindChild("HeaderItemList"):GetChildren()
		if nChildren == 0 then
			wndCurr:Show(false)
		else
			local nHeight = wndCurr:FindChild("HeaderItemList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
			wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nTop + (wndCurr:FindChild("HeaderItemBtn"):IsChecked() and nHeight + 40 or 80))
			wndCurr:FindChild("HeaderItemList"):Show(wndCurr:FindChild("HeaderItemBtn"):IsChecked())
			wndCurr:Show(true)
		end
		
		local strEnd = tHeaderData.strTitleEnd
		if strEnd ~= nil then
			strEnd = Apollo.GetString(strEnd)
		end
		local wndHeaderItemTitle = wndCurr:FindChild("HeaderItemTitle")
		local strText =  String_GetWeaselString(Apollo.GetString(tHeaderData.strTitleBegin), nChildren)
		if tHeaderData.nLimit > 0 then
			strTitle = string.format('<T Font="CRB_HeaderTiny" TextColor="white">%s</T><T Font="CRB_HeaderTiny" TextColor="%s">%d</T><T Font="CRB_HeaderTiny" TextColor="white">%s</T>', strText, tHeaderData.strColor, tHeaderData.nLimit, strEnd)
		else
			strTitle = string.format('<T Font="CRB_HeaderTiny" TextColor="white">%s</T>', strText)
		end

		wndHeaderItemTitle:SetAML(strTitle)
		local nWidth, nHeight = wndHeaderItemTitle:SetHeightToContentHeight()
		local tHeaderItemTitleLoc = wndHeaderItemTitle:GetOriginalLocation()
		local nLeft, nTop, nRight, nBottom = tHeaderItemTitleLoc:GetOffsets()
		local nLeftPoint, nTopPoint, nRightPoint, nBottomPoint = tHeaderItemTitleLoc:GetPoints()
		
		local nButtonWidth = 0
		local wndUnlockAuctionAndBidsBtn = self.wndAuctionBuyHeader:FindChild("UnlockAuctionAndBidsSlotsBtn")
		local wndUnlockCommodityBtn = self.wndAuctionBuyHeader:FindChild("UnlockCommodityOrderSlotsBtn")
		if wndUnlockCommodityBtn ~= nil and wndUnlockCommodityBtn:IsShown() then
			nButtonWidth = wndUnlockCommodityBtn:GetWidth()
		elseif wndUnlockAuctionAndBidsBtn ~= nil and wndUnlockAuctionAndBidsBtn:IsShown() then
			nButtonWidth = wndUnlockAuctionAndBidsBtn:GetWidth()
		end
		wndHeaderItemTitle:SetAnchorPoints(nLeftPoint, 0.5, nRightPoint, 0.5)
		wndHeaderItemTitle:SetAnchorOffsets(nLeft, -nHeight / 2, nRight - nButtonWidth, nHeight / 2)
	end

	self.wndMain:FindChild("MainScroll"):SetText(nNumChildren == 0 and Apollo.GetString("MarketplaceListings_NoActiveListings") or "")
	self.wndMain:FindChild("MainScroll"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MarketplaceListings:OnHeaderItemToggle(wndHandler, wndControl)
	self:SharedDrawMain()
end

-----------------------------------------------------------------------------------------------
-- Item Drawing
-----------------------------------------------------------------------------------------------

function MarketplaceListings:BuildAuctionOrder(nIdx, aucCurrent, wndParent)
	local tItem = aucCurrent:GetItem()
	local wndCurr = self:FactoryProduce(wndParent, "AuctionItem", aucCurrent)

	local bIsOwnAuction = aucCurrent:IsOwned()
	local nCount = aucCurrent:GetCount()
	local nBidAmount = aucCurrent:GetCurrentBid():GetAmount()
	local nMinBidAmount = aucCurrent:GetMinBid():GetAmount()
	local nBuyoutAmount = aucCurrent:GetBuyoutPrice():GetAmount()
	local strPrefix = bIsOwnAuction and Apollo.GetString("MarketplaceListings_AuctionPrefix") or Apollo.GetString("MarketplaceListings_BiddingPrefix")
	local eTimeRemaining = MarketplaceLib.kCommodityOrderListTimeDays

	if bIsOwnAuction then
		wndCurr:FindChild("AuctionTimeLeftText"):SetText(self:HelperFormatTimeString(aucCurrent:GetExpirationTime()))
		wndCurr:FindChild("ListExpiresIconRed"):Show(false)
		wndCurr:FindChild("ListExpiresIconGreen"):Show(true)
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	elseif eTimeRemaining == ItemAuction.CodeEnumAuctionRemaining.Very_Long then
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextRaw(String_GetWeaselString(Apollo.GetString("MarketplaceAuction_VeryLong"), kstrAuctionOrderDuration))
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
		wndCurr:FindChild("ListExpiresIconRed"):Show(false)
		wndCurr:FindChild("ListExpiresIconGreen"):Show(true)
	else
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextRaw(ktTimeRemaining[eTimeRemaining])
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextColor(ApolloColor.new("Reddish"))
		wndCurr:FindChild("ListExpiresIconRed"):Show(true)
		wndCurr:FindChild("ListExpiresIconGreen"):Show(false)
	end

	wndCurr:FindChild("AuctionCancelBtn"):SetData(aucCurrent)
	wndCurr:FindChild("AuctionCancelBtn"):Enable(nBidAmount == 0)
	wndCurr:FindChild("AuctionCancelBtn"):Show(bIsOwnAuction)
	wndCurr:FindChild("AuctionCancelBtnTooltipHack"):Show(bIsOwnAuction and nBidAmount ~= 0)
	wndCurr:FindChild("AuctionPrice"):SetAmount(nBidAmount, true) -- 2nd arg is bInstant
	wndCurr:FindChild("BuyoutPrice"):SetAmount(nBuyoutAmount, true) -- 2nd arg is bInstant
	wndCurr:FindChild("MinimumPrice"):SetAmount(nMinBidAmount, true) -- 2nd arg is bInstant
	wndCurr:FindChild("AuctionBigIcon"):SetSprite(tItem:GetIcon())
	wndCurr:FindChild("AuctionIconAmountText"):SetText(nCount == 1 and "" or nCount)
	wndCurr:FindChild("AuctionItemName"):SetText(String_GetWeaselString(strPrefix, tItem:GetName()))
	Tooltip.GetItemTooltipForm(self, wndCurr:FindChild("AuctionBigIcon"), tItem, {bPrimary = true, bSelling = false, itemCompare = tItem:GetEquippedItemForItemType()})

	wndCurr:FindChild("AuctionItemName"):SetHeightToContentHeight()
	local nAuctionItemNameHeight = wndCurr:FindChild("AuctionItemName"):GetHeight()
	local wndAucItemNameContain = wndCurr:FindChild("AuctionItemNameContainer")
	local nContainLeft, nContainTop, nContainRight, nContainBottom = wndAucItemNameContain:GetAnchorOffsets()
	wndAucItemNameContain:SetAnchorOffsets(nContainLeft, nContainTop, nContainRight, nContainTop + nAuctionItemNameHeight + knAuctionItemTopContentPadding)
	local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
	wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nAuctionItemNameHeight + knAuctionItemBottomContentSpacing)
end

function MarketplaceListings:BuildCommodityOrder(nIdx, aucCurrent, wndParent)
	local tItem = aucCurrent:GetItem()
	local wndCurr = self:FactoryProduce(wndParent, "CommodityItem", aucCurrent)

	-- Tint a different color if Buy
	local nCount = aucCurrent:GetCount()
	local strPrefix = aucCurrent:IsBuy() and Apollo.GetString("CRB_Buy") or Apollo.GetString("CRB_Sell")
	wndCurr:FindChild("CommodityCancelBtn"):SetData(aucCurrent)
	wndCurr:FindChild("CommodityBuyBG"):Show(aucCurrent:IsBuy())
	wndCurr:FindChild("CommoditySellBG"):Show(not aucCurrent:IsBuy())
	wndCurr:FindChild("CommodityBigIcon"):SetSprite(tItem:GetIcon())
	wndCurr:FindChild("CommodityIconAmountText"):SetText(nCount == 1 and "" or nCount)
	wndCurr:FindChild("CommodityItemName"):SetText(String_GetWeaselString(Apollo.GetString("MarketplaceListings_AuctionLabel"), strPrefix, tItem:GetName()))
	wndCurr:FindChild("CommodityPrice"):SetAmount(aucCurrent:GetPricePerUnit():GetAmount(), true) -- 2nd arg is bInstant
	wndCurr:FindChild("CommodityTimeLeftText"):SetText(self:HelperFormatTimeString(aucCurrent:GetExpirationTime()))
	Tooltip.GetItemTooltipForm(self, wndCurr:FindChild("CommodityBigIcon"), tItem, {bPrimary = true, bSelling = false, itemCompare = tItem:GetEquippedItemForItemType()})

	wndCurr:FindChild("CommodityItemName"):SetHeightToContentHeight()
	local CommodityItemNameHeight = wndCurr:FindChild("CommodityItemName"):GetHeight()
	local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
	if wndCurr:FindChild("CommodityItemName"):GetHeight() > 25 then
		local wndComItemNameContain = wndCurr:FindChild("CommodityItemNameContainer")
		local nContainLeft, nContainTop, nContainRight, nContainBottom = wndComItemNameContain:GetAnchorOffsets()
		wndComItemNameContain:SetAnchorOffsets(nContainLeft, nContainTop, nContainRight, nContainTop + CommodityItemNameHeight)
		wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nTop + CommodityItemNameHeight + knCommodityItemBottomContentSpacing)
	end

end

function MarketplaceListings:BuildCreddOrder(nIdx, aucCurrent, wndParent)
	local wndCurr = self:FactoryProduce(wndParent, "CreddItem", aucCurrent)
	wndCurr:FindChild("CreddCancelBtn"):SetData(aucCurrent)
	wndCurr:FindChild("CreddLabel"):SetText(aucCurrent:IsBuy() and Apollo.GetString("MarketplaceCredd_BuyLabel") or Apollo.GetString("MarketplaceCredd_SellLabel"))
	wndCurr:FindChild("CreddPrice"):SetAmount(aucCurrent:GetPrice(), true) -- 2nd arg is bInstant
	wndCurr:FindChild("CreddTimeLeftText"):SetText(self:HelperFormatTimeString(aucCurrent:GetExpirationTime()))
end

-----------------------------------------------------------------------------------------------
-- UI Interaction (mostly to cancel order)
-----------------------------------------------------------------------------------------------

function MarketplaceListings:OnCancelBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()

	self.wndConfirmDelete:Show(true)
	self.wndConfirmDelete:FindChild("CancelCommodityConfirmBtn"):Show(wndHandler:GetName() == "CommodityCancelBtn")
	self.wndConfirmDelete:FindChild("CancelAuctionConfirmBtn"):Show(wndHandler:GetName() == "AuctionCancelBtn")
	self.wndConfirmDelete:FindChild("CancelCREDDListingBtn"):Show(wndHandler:GetName() == "CreddCancelBtn")

	if wndHandler:GetName() == "CommodityCancelBtn" then
		self.wndConfirmDelete:FindChild("CancelCommodityConfirmBtn"):SetData(aucCurrent)
		self.wndConfirmDelete:FindChild("Title"):SetText(Apollo.GetString("MarketplaceListings_CancelCommodityConfirm"))

	elseif wndHandler:GetName() == "AuctionCancelBtn" then
		self.wndConfirmDelete:FindChild("CancelAuctionConfirmBtn"):SetData(aucCurrent)
		self.wndConfirmDelete:FindChild("Title"):SetText(Apollo.GetString("MarketplaceListings_CancelAuctionConfirm"))

	else
		self.wndConfirmDelete:FindChild("CancelCREDDListingBtn"):SetData(aucCurrent)
		self.wndConfirmDelete:FindChild("Title"):SetText(Apollo.GetString("MarketplaceListings_CancelCREDDConfirm"))
	end
end

function MarketplaceListings:OnAuctionCancelConfirmBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()
	if not aucCurrent then
		return
	end
	aucCurrent:Cancel()
	self.wndMain:FindChild("MainScroll"):Show(false)
	self.wndMain:FindChild("RefreshBlocker"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	self.wndConfirmDelete:Show(false)
end

function MarketplaceListings:OnCommodityCancelConfirmBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()
	if not aucCurrent or not aucCurrent:IsPosted() then
		return
	end
	aucCurrent:Cancel()
	self.wndMain:FindChild("MainScroll"):Show(false)
	self.wndMain:FindChild("RefreshBlocker"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	self.wndConfirmDelete:Show(false)
end

function MarketplaceListings:OnCreddCancelConfirmBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()
	if not aucCurrent or not aucCurrent:IsPosted() then
		return
	end
	CREDDExchangeLib.CancelOrder(aucCurrent)
	self:ManangeWndAndRequestData()
	self.wndMain:FindChild("RefreshBlocker"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	self.wndConfirmDelete:Show(false)
end

function MarketplaceListings:OnCommodityItemSmallMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl and wndHandler:FindChild("CommodityCancelBtn") then
		wndHandler:FindChild("CommodityCancelBtn"):Show(true)
	end
end

function MarketplaceListings:OnCommodityItemSmallMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl and wndHandler:FindChild("CommodityCancelBtn") then
		wndHandler:FindChild("CommodityCancelBtn"):Show(false)
	end
end

-----------------------------------------------------------------------------------------------
-- Auction/Commodity update events
-----------------------------------------------------------------------------------------------

function MarketplaceListings:OnCommodityAuctionRemoved(eAuctionEventType, oRemoved)
	-- TODO
	--if eAuctionEventType == MarketplaceLib.AuctionEventType.Fill then
	--elseif eAuctionEventType == MarketplaceLib.AuctionEventType.Expire then
	--elseif eAuctionEventType == MarketplaceLib.AuctionEventType.Cancel then
	--end

	if self.tOrders ~= nil then
		for nIdx, tCurrOrder in ipairs(self.tOrders) do
			if tCurrOrder == oRemoved then
				table.remove(self.tOrders, nIdx)
				break
			end
		end
		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnCommodityAuctionUpdated(oUpdated)
	if self.tOrders ~= nil then
		local bFound = false
		for nIdx, tCurrOrder in ipairs(self.tOrders) do
			if tCurrOrder == oUpdated then
				self.tOrders[nIdx] = oUpdated
				bFound = true
			end
		end
		if not bFound then
			table.insert(self.tOrders, oUpdated)
		end

		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnPostCommodityOrderResult(eAuctionResult, oAdded)
	if eAuctionResult ~= MarketplaceLib.AuctionPostResult.Ok or not oAdded:IsPosted() then
		return
	end

	if self.tOrders == nil then
		self.tOrders = {}
	end

	self:OnCommodityAuctionUpdated(oAdded)
end

function MarketplaceListings:OnItemAuctionRemoved(aucRemoved)
	if self.tAuctions ~= nil then
		for nIdx, aucCurrent in ipairs(self.tAuctions) do
			if aucCurrent == aucRemoved then
				table.remove(self.tAuctions, nIdx)
				break
			end
		end
		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnItemCancelResult(eAuctionResult, aucRemoved)
	if eAuctionResult == MarketplaceLib.AuctionPostResult.AlreadyHasBid then
		Event_FireGenericEvent("GenericEvent_LootChannelMessage", Apollo.GetString("MarketplaceListings_CantCancelHasBid"))
	end

	if eAuctionResult ~= MarketplaceLib.AuctionPostResult.Ok then
		return
	end

	self:OnItemAuctionRemoved(aucRemoved)
end

function MarketplaceListings:OnItemAuctionUpdated(aucUpdated)
	if self.tAuctions ~= nil then
		local bFound = false
		for nIdx, aucCurrent in ipairs(self.tAuctions) do
			if aucCurrent == aucUpdated then
				self.tAuctions[nIdx] = aucUpdated
				bFound = true
			end
		end
		if not bFound then
			table.insert(self.tAuctions, aucUpdated)
		end

		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnItemAuctionResult(eAuctionResult, aucAdded)
	if eAuctionResult ~= MarketplaceLib.AuctionPostResult.Ok then
		return
	end

	if self.tAuctions == nil then
		self.tAuctions = {}
	end

	self:OnItemAuctionUpdated(aucAdded)
end

function MarketplaceListings:OnItemListingClose(wndHandler, wndControl)
	self.wndConfirmDelete:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Entitlement Updates
-----------------------------------------------------------------------------------------------

function MarketplaceListings:OnEntitlementUpdate(tEntitlementInfo)
	local bNotSignatureOrFree = tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.Signature and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.Free
	local bNotExtras = tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.ExtraAuctions and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.ExtraCommodityOrders
	local bNotLoyalty = tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.LoyaltyExtraAuctions and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.LoyaltyExtraCommodityOrders
	if not self.wndMain or (bNotSignatureOrFree and bNotExtras and bNotLoyalty) then
		return
	end
	self:UpdateSlotNotification()
end

function MarketplaceListings:UpdateSlotNotification()
	if not self.wndMain then
		return
	end
	
	self:RefreshStoreLink()
	local nMaxAuctionSlots = MarketplaceLib.GetMaxAuctions() 
	local nMaxOrderSlots = MarketplaceLib.GetMaxCommodityOrders()
	local bAuctionsChanged = self.tAuctionsCount.nSell ~= self.tPrevAuctionsCount.nSell or self.tAuctionsCount.nBuy ~= self.tPrevAuctionsCount.nBuy
	local bCommoditiesChanged = self.nOrderCount ~= self.nPrevOrderCount
	local bSellUpdated = self.tAuctionsCount and (nMaxAuctionSlots - self.tAuctionsCount.nSell) <= 0
	local bBuyUpdated = self.tAuctionsCount and (nMaxAuctionSlots - self.tAuctionsCount.nBuy) <= 0
	self.bAuctionsAndBidsFull = bSellUpdated or bBuyUpdated
	self.bCommodityOrdersFull = (nMaxOrderSlots - self.nOrderCount) <= 0
	local nAuctionsLimit = MarketplaceLib.GetAuctionsLimit()
	local nCommodityLimit = MarketplaceLib.GetCommodityLimit()
	local bDisplay = (self.bAuctionsAndBidsFull and nAuctionsLimit ~= nMaxAuctionSlots) or  (self.bCommodityOrdersFull and nCommodityLimit ~= nMaxOrderSlots)
	bDisplay = bDisplay and (self.bStoreLinkValid or self.bStoreLinkValidAuctionsExtras or self.bStoreLinkValidCommodityExtras)
	local wndMTXSlotNotify = self.wndMain:FindChild("MTX_SlotWarning")
	if not wndMTXSlotNotify then
		wndMTXSlotNotify = Apollo.LoadForm(self.xmlDoc, "MTX_SlotWarning", self.wndMTXSlotWarningContainer, self)
	end
	
	self.wndAuctionBuyHeader:FindChild("UnlockAuctionAndBidsSlotsBtn"):Show(self.bStoreLinkValidAuctionsExtras and nAuctionsLimit ~= nMaxAuctionSlots)
	self.wndAuctionSellHeader:FindChild("UnlockAuctionAndBidsSlotsBtn"):Show(self.bStoreLinkValidAuctionsExtras and nAuctionsLimit ~= nMaxAuctionSlots)
	self.wndCommodityBuyHeader:FindChild("UnlockCommodityOrderSlotsBtn"):Show(self.bStoreLinkValidCommodityExtras and nCommodityLimit ~= nMaxOrderSlots)
	self.wndCommoditySellHeader:FindChild("UnlockCommodityOrderSlotsBtn"):Show(self.bStoreLinkValidCommodityExtras and nCommodityLimit ~= nMaxOrderSlots)
	
	if bDisplay == wndMTXSlotNotify:IsShown() and not bAuctionsChanged and not bCommoditiesChanged and nMaxAuctionSlots == self.tCurMaxSlots.nAuctionCount and nMaxOrderSlots == self.tCurMaxSlots.nOrderCount then
		return
	end
	
	self.tPrevAuctionsCount = self.tAuctionsCount
	self.nPrevOrderCount = self.nOrderCount
	self.tCurMaxSlots.nAuctionCount = nMaxAuctionSlots
	self.tCurMaxSlots.nOrderCount = nMaxOrderSlots
	
	local wndWaitScreen = self.wndMain:FindChild("WaitScreen")
	local wndRefreshBlocker = self.wndMain:FindChild("RefreshBlocker")
	local wndMainScroll = self.wndMain:FindChild("MainScroll")
	local nLeft, nTop, nRight, nBottom = wndMainScroll:GetOriginalLocation():GetOffsets()
	local nWaitLeft, nWaitTop, nWaitRight, nWaitBottom = wndWaitScreen:GetOriginalLocation():GetOffsets()
	local nRefreshLeft, nRefreshTop, nRefreshRight, nRefreshBottom = wndRefreshBlocker:GetOriginalLocation():GetOffsets()
	local nMTXHeight = 0
	wndMTXSlotNotify:Show(bDisplay)
	
	if bDisplay then
		local nMTXLeft, nMTXTop, nMTXRight, nMTXBottom = wndMTXSlotNotify:GetOriginalLocation():GetOffsets()
		local wndMTXSlotNotifyTitle = wndMTXSlotNotify:FindChild("Title")
		local wndMTXSlotNotifyBody = wndMTXSlotNotify:FindChild("Body")
		
		local nSlotCount = not self.bStoreLinkValid and 0 or MarketplaceLib.GetSignatureAuctionsLimit() - nMaxAuctionSlots
		if nSlotCount <= 0 then
			local wndSignatureBtn = wndMTXSlotNotify:FindChild("SigPlayerBtn")
			wndSignatureBtn:Show(false)
			wndMTXSlotNotifyBody:SetAML("<P Font=\"CRB_InterfaceMedium\" Align=\"Center\" TextColor=\"UI_TextHoloBody\">"..Apollo.GetString("MarketplaceAuction_UnlockAdditionalSlotsGroups").."</P>")
			nMTXHeight = nMTXHeight - wndSignatureBtn:GetHeight() + knMTXUnlockBtnPadding
		else
			wndMTXSlotNotify:FindChild("SigPlayerBtn"):Show(true)
			wndMTXSlotNotifyBody:SetAML("<P Font=\"CRB_InterfaceMedium\" Align=\"Center\" TextColor=\"UI_TextHoloBody\">"..String_GetWeaselString(Apollo.GetString("MarketplaceAuction_BecomeSignatureOrUnlock"), tostring(nSlotCount)).."</P>")
		end
		
		local nMTXSlotNotifyHeight = wndMTXSlotNotify:GetData() 
		local nMTXSlotNotifyBodyHeight = wndMTXSlotNotifyBody:GetData()
		if nMTXSlotNotifyHeight == nil then
			nMTXSlotNotifyHeight = wndMTXSlotNotify:GetHeight()
			wndMTXSlotNotify:SetData(nMTXSlotNotifyHeight)
		end
		if nMTXSlotNotifyBodyHeight == nil then
			nMTXSlotNotifyBodyHeight = wndMTXSlotNotifyBody:GetHeight()
			wndMTXSlotNotifyBody:SetData(nMTXSlotNotifyBodyHeight)
		end
		nMTXHeight = nMTXHeight + nMTXSlotNotifyHeight
		wndMTXSlotNotify:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nMTXHeight)
		nMTXHeight = nMTXHeight - nMTXSlotNotifyBodyHeight
		local nWidth, nHeight = wndMTXSlotNotifyBody:SetHeightToContentHeight()
		nMTXHeight = nMTXHeight + nHeight
		wndMTXSlotNotify:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nMTXHeight)
	end
	
	wndMainScroll:SetAnchorOffsets(nLeft, nTop + nMTXHeight, nRight, nBottom)
	wndWaitScreen:SetAnchorOffsets(nWaitLeft, nWaitTop + nMTXHeight, nWaitRight, nWaitBottom)
	wndRefreshBlocker:SetAnchorOffsets(nRefreshLeft, nRefreshTop + nMTXHeight, nRefreshRight, nRefreshBottom)
end

-----------------------------------------------------------------------------------------------
-- Store Updates
-----------------------------------------------------------------------------------------------

function MarketplaceListings:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature) 
	self.bStoreLinkValidAuctionsExtras = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ExtraAuctionsAndBids) 
	self.bStoreLinkValidCommodityExtras = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ExtraCommodityOrders) 
end

function MarketplaceListings:OnUnlockMoreSlots(bUnlockAuctionsAndBids)
	if self.bAuctionsAndBidsFull or bUnlockAuctionsAndBids == true then
		StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ExtraAuctionsAndBids)
	elseif self.bCommodityOrdersFull or bUnlockAuctionsAndBids == false then
		StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ExtraCommodityOrders)
	end
end

function MarketplaceListings:OnUnlockMoreAuctionAndBidsSlots()
	self:OnUnlockMoreSlots(true)
end

function MarketplaceListings:OnUnlockMoreCommodityOrderSlots()
	self:OnUnlockMoreSlots(false)
end

function MarketplaceListings:OnBecomeSignature()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function MarketplaceListings:OnGenerateSignatureTooltip(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	Tooltip.GetSignatureTooltipForm(self, wndControl, Apollo.GetString("Signature_ListingsTooltip"))
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function MarketplaceListings:HelperFormatTimeString(oExpirationTime)
	local strResult = ""
	local nInSeconds = math.floor(math.abs(Time.SecondsElapsed(oExpirationTime))) -- CLuaTime object
	local nHours = math.floor(nInSeconds / 3600)
	local nMins = math.floor(nInSeconds / 60 - (nHours * 60))

	if nHours > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("MarketplaceListings_Hours"), nHours)
	elseif nMins > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("MarketplaceListings_Minutes"), nMins)
	else
		strResult = Apollo.GetString("MarketplaceListings_LessThan1m")
	end
	return strResult
end

function MarketplaceListings:FactoryProduce(wndParent, strFormName, tObject) -- Using AuctionObjects
	local wnd = wndParent:FindChildByUserData(tObject)
	if not wnd then
		wnd = Apollo.LoadForm(self.xmlDoc, strFormName, wndParent, self)
		wnd:SetData(tObject)
	end
	return wnd
end

local MarketplaceListingsInst = MarketplaceListings:new()
MarketplaceListingsInst:Init()
