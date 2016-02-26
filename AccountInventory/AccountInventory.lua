-----------------------------------------------------------------------------------------------
-- Client Lua Script for AccountInventory
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "AccountItemLib"
require "CREDDExchangeLib"
require "FriendshipLib"

local AccountInventory = {}

local knBoomBoxItemId = 44359
local keCreddType = -1 * AccountItemLib.CodeEnumAccountCurrency.CREDD -- Negative to avoid collision with ID 1
local knMinGiftDays = 2
local ktResultErrorCodeStrings =
{
	[CREDDExchangeLib.CodeEnumAccountOperationResult.GenericFail] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.DBError] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidOffer] = "MarketplaceCredd_Error_InvalidOffer",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidPrice] = "MarketplaceCredd_Error_InvalidPrice",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NotEnoughCurrency] = "GenericError_Vendor_NotEnoughCash",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NeedTransaction] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidAccountItem] = "MarketplaceAuction_InvalidItem",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidPendingItem] = "MarketplaceAuction_InvalidItem",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidInventoryItem] = "MarketplaceAuction_InvalidItem",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoConnection] = "MarketplaceCredd_Error_Connection",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoCharacter] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.AlreadyClaimed] = "MarketplaceCredd_Error_AlreadyClaimed",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.MaxEntitlementCount] = "MarketplaceCredd_Error_MaxEntitlement",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoRegift] = "MarketplaceCredd_Error_CantGift",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoGifting] = "MarketplaceCredd_Error_CantGift",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidFriend] = "MarketplaceCredd_Error_InvalidFriend",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidCoupon] = "MarketplaceCredd_Error_InvalidCoupon",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.CannotReturn] = "MarketplaceCredd_Error_CantReturn",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.Prereq] = "MarketplaceCredd_Error_Prereq",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.CREDDExchangeNotLoaded] = "MarketplaceCredd_Error_Busy",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoCREDD] = "MarketplaceCredd_Error_NoCredd",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoMatchingOrder] = "MarketplaceCredd_Error_NoMatch",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidCREDDOrder] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.AlreadyClaimedMultiRedeem] = "AccountInventory_Error_AlreadyClaimedMultiRedeem",
}

local ktCurrencies =
{
	[AccountItemLib.CodeEnumAccountCurrency.CREDD] =
	{
		strTooltip = "AccountInventory_CreddTooltip",
		bShowInList = true,
	},
	[AccountItemLib.CodeEnumAccountCurrency.NameChange] =
	{
		strTooltip = "AccountInventory_NameChangeTooltip",
		bShowInList = true,
	},
	[AccountItemLib.CodeEnumAccountCurrency.RealmTransfer] =
	{
		strTooltip = "AccountInventory_RealmTransferTooltip",
		bShowInList = true,
	},
}

function AccountInventory:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}

    return o
end

function AccountInventory:Init()
    Apollo.RegisterAddon(self)
end

function AccountInventory:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AccountInventory.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function AccountInventory:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local nLastAccountBoundCount = self.nLastAccountBoundCount
	local tSave =
	{
		nLastAccountBoundCount = nLastAccountBoundCount,
	}
	return tSave
end

function AccountInventory:OnRestore(eType, tSavedData)
	if tSavedData then
		if tSavedData.tLocation then
			self.nLastAccountBoundCount = tSavedData.nLastAccountBoundCount
		end
	end
end

function AccountInventory:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 			"OnInterfaceMenuListHasLoaded", self)

	Apollo.RegisterEventHandler("ChangeWorld", 							"OnChangeWorld", self)
	Apollo.RegisterEventHandler("AccountInventoryWindowShow",			"OnAccountInventoryWindowShow", self)
	Apollo.RegisterEventHandler("ToggleAccountInventoryWindow",			"OnAccountInventoryToggle", self)
	Apollo.RegisterEventHandler("GenericEvent_ToggleAccountInventory", 	"OnAccountInventoryToggle", self)
	Apollo.RegisterEventHandler("AccountOperationResults", 				"OnAccountOperationResults", self) -- TODO

	Apollo.RegisterEventHandler("FriendshipRemove", 					"OnFriendshipRemove", self)

	Apollo.RegisterEventHandler("AccountPendingItemsUpdate", 			"RefreshInventory", self)
	Apollo.RegisterEventHandler("AccountInventoryUpdate", 				"RefreshInventory", self)
	Apollo.RegisterEventHandler("UpdateInventory", 						"RefreshInventory", self)
	Apollo.RegisterEventHandler("AchievementUpdated", 					"RefreshInventory", self)
	Apollo.RegisterEventHandler("PlayerLevelChange", 					"RefreshInventory", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 						"RefreshInventory", self)
	Apollo.RegisterEventHandler("PathLevelUp", 							"RefreshInventory", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged",				"RefreshInventory", self)
	
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate", 			"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", 			"OnEntitlementUpdate", self)

	Apollo.RegisterTimerHandler("AccountInventory_RefreshInventory",	"OnAccountInventory_RefreshInventory", self)
	Apollo.CreateTimer("AccountInventory_RefreshInventory", 5, false)
	Apollo.StopTimer("AccountInventory_RefreshInventory")

	self.bRefreshInventoryThrottle = false

	for idx, eAccountCurrencyType in pairs(AccountItemLib.CodeEnumAccountCurrency) do
		if ktCurrencies[eAccountCurrencyType] == nil then
			ktCurrencies[eAccountCurrencyType] = {}
		end

		ktCurrencies[eAccountCurrencyType].eType = eAccountCurrencyType

		local monObj = Money.new()
		monObj:SetAccountCurrencyType(eAccountCurrencyType)
		local denomInfo = monObj:GetDenomInfo()[1]
		ktCurrencies[eAccountCurrencyType].strIcon = denomInfo.strSprite
	end
end

function AccountInventory:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("AccountInv_TitleText")})
end

function AccountInventory:OnInterfaceMenuListHasLoaded()
	local strIcon = "Icon_Windows32_UI_CRB_InterfaceMenu_InventoryAccount"
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_AccountInventory"), {"GenericEvent_ToggleAccountInventory", "", strIcon})
	self:OnRefreshInterfaceMenuAlert()
end

function AccountInventory:OnRefreshInterfaceMenuAlert()
	local bShowHighlight = false
	local nAlertCount = 0 -- Escrow Only, Doesn't consider UI restrictions (e.g. no name)
	for idx, tPendingAccountItemGroup in pairs(AccountItemLib.GetPendingAccountItemGroups()) do
		nAlertCount = nAlertCount + #tPendingAccountItemGroup.items
	end

	for idx, tAccountItem in pairs(AccountItemLib.GetAccountItems()) do
		if tAccountItem.item and tAccountItem.item:GetItemId() == knBoomBoxItemId then
			nAlertCount = nAlertCount + 1
			if tAccountItem.cooldown and tAccountItem.cooldown == 0 then
				bShowHighlight = true -- Always highlight if a boom box is ready to go
			end
		end
	end

	if not bShowHighlight and self.nLastAccountBoundCount then
		bShowHighlight = self.nLastAccountBoundCount ~= nAlertCount
	end

	if nAlertCount == 0 then
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AccountInventory"), {false, "", 0})
	else
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AccountInventory"), {bShowHighlight, "", nAlertCount})
	end
	self.nLastAccountBoundCount = nAlertCount
end

function AccountInventory:OnAccountInventoryWindowShow()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		self:SetupMainWindow()
	else
		self.tWndRefs.wndMain:ToFront()
	end
	Sound.Play(Sound.PlayUIAccountInventoryOpen)
end

function AccountInventory:OnAccountInventoryToggle()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		self:SetupMainWindow()
		Sound.Play(Sound.PlayUIAccountInventoryOpen)
	else
		self.tWndRefs.wndMain:Close()
		Sound.Play(Sound.PlayUIAccountInventoryClose)
	end
end

function AccountInventory:OnClose(wndHandler, wndControl)
	if wndHandler == wndControl then
		if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
			self.tWndRefs.wndMain:Destroy()
			self.tWndRefs = {}
			AccountItemLib:MarkAllInventoryItemsAsSeen()
			AccountItemLib:MarkAllPendingItemsAsSeen()
		end
	end
	Sound.Play(Sound.PlayUIAccountInventoryClose)
end

function AccountInventory:OnChangeWorld()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Close()
	end
end

function AccountInventory:OnAccountOperationResults(eOperationType, eResult)
	local bSuccess = eResult == CREDDExchangeLib.CodeEnumAccountOperationResult.Ok
	local strMessage = ""
	if bSuccess then
		strMessage = Apollo.GetString("MarketplaceCredd_TransactionSuccess")
	elseif ktResultErrorCodeStrings[eResult] then
		strMessage = Apollo.GetString(ktResultErrorCodeStrings[eResult])
	else
		strMessage = Apollo.GetString("MarketplaceCredd_Error_GenericFail")
	end
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", strMessage)

	-- Immediately close if you redeemed CREDD, so we can see the spell effect
	if bSuccess and eOperationType == CREDDExchangeLib.CodeEnumAccountOperation.CREDDRedeem then
		if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
			self.tWndRefs.wndMain:Close()
		end
		return
	end
end

-----------------------------------------------------------------------------------------------
-- Main
-----------------------------------------------------------------------------------------------

function AccountInventory:SetupMainWindow()
	self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "AccountInventoryForm", nil, self)
	self.tWndRefs.wndMain:Invoke()
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("AccountInv_TitleText"), nSaveVersion = 2})
	Event_ShowTutorial(GameLib.CodeEnumTutorial.General_AccountServices)

	--Containers
	self.tWndRefs.wndInventory = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory")
	self.tWndRefs.wndInventoryGift = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGift")
	self.tWndRefs.wndInventoryClaimConfirm = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryClaimConfirm")
	self.tWndRefs.wndInventoryTakeConfirm = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryTakeConfirm")
	self.tWndRefs.wndInventoryRedeemCreddConfirm = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryRedeemCreddConfirm")
	self.tWndRefs.wndInventoryGiftConfirm = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGiftConfirm")
	self.tWndRefs.wndInventoryGiftReturnConfirm = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGiftReturnConfirm")

	--Inventory
	self.tWndRefs.wndInventoryContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container")
	self.tWndRefs.wndInventoryValidationNotification = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:ValidationNotification")
	self.tWndRefs.wndEscrowGridContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:EscrowGridContainer")
	self.tWndRefs.wndInventoryGridContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:InventoryGridContainer")
	self.tWndRefs.wndInventoryClaimBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:ClaimBtn")
	self.tWndRefs.wndInventoryNoClaimNotice = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:NoClaimNotice")
	self.tWndRefs.wndInventoryClaimHoldNotice = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:ClaimHoldNotice")
	self.tWndRefs.wndInventoryGiftBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:GiftBtn")
	self.tWndRefs.wndInventoryGiftTwoFactorNotice = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:GiftTwoFactorNotice")
	self.tWndRefs.wndInventoryGiftHoldNotice = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:GiftHoldNotice")
	self.tWndRefs.wndInventoryTakeBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:TakeBtn")
	self.tWndRefs.wndInventoryRedeemCreddBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:RedeemBtn")
	self.tWndRefs.wndInventoryReturnBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:ReturnBtn")
	self.tWndRefs.wndInventoryFilterMultiBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:InventoryFilterMultiBtn")
	self.tWndRefs.wndInventoryFilterLockedBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:InventoryFilterLockedBtn")

	--Inventory Confirm
	self.tWndRefs.wndPendingClaimContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryClaimConfirm:PendingClaimContainer")
	self.tWndRefs.wndInventoryTakeConfirmContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryTakeConfirm:TakeContainer")
	self.tWndRefs.wndInventoryCreddRedeemConfirmContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryRedeemCreddConfirm:RedeemContainer")

	--Inventory Gift
	self.tWndRefs.wndInventoryGiftFriendContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGift:FriendContainer")
	self.tWndRefs.wndInventoryGiftFriendSelectBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGift:GiftBtn")
	self.tWndRefs.wndInventoryGiftConfirmItemContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGiftConfirm:InventoryGiftConfirmItemContainer")
	self.tWndRefs.wndInventoryGiftReturnConfirmItemContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGiftReturnConfirm:InventoryGiftReturnContainer")

	self.tWndRefs.wndMain:SetSizingMinimum(700, 480)
	self.tWndRefs.wndMain:SetSizingMaximum(1920, 1080)
	self.tWndRefs.wndInventoryGift:Show(false, true)
	self.tWndRefs.wndInventoryTakeConfirm:Show(false, true)
	self.tWndRefs.wndInventoryGiftConfirm:Show(false, true)
	self.tWndRefs.wndInventoryClaimConfirm:Show(false, true)
	self.tWndRefs.wndInventoryGiftReturnConfirm:Show(false, true)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(false, true)
	self.tWndRefs.wndInventoryFilterMultiBtn:SetCheck(true)
	self.tWndRefs.wndInventoryFilterLockedBtn:SetCheck(true)

	self.unitPlayer = GameLib.GetPlayerUnit()

	self.bHasFraudCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) ~= 0
	self:RefreshInventory()
end

function AccountInventory:OnInventoryCheck(wndHandler, wndControl, eMouseButton)
	self:OnInventoryUncheck()
	self.tWndRefs.wndInventory:Show(true)
end

function AccountInventory:OnInventoryUncheck(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryGift:Show(false)
	self.tWndRefs.wndInventoryGiftConfirm:Show(false)
	self.tWndRefs.wndInventoryClaimConfirm:Show(false)
	self.tWndRefs.wndInventoryTakeConfirm:Show(false)
	self.tWndRefs.wndInventoryGiftReturnConfirm:Show(false)
end

--[[
Inventory
]]--

function AccountInventory:HelperAddPendingSingleToContainer(wndParent, tPendingAccountItem)
	local strName = ""
	local strIcon = ""
	local strTooltip = ""
	local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tPendingAccountItem.prereqId) or nil
	local bShowLock = tPrereqInfo and not tPrereqInfo.bIsMet

	if tPendingAccountItem.item then
		strName = tPendingAccountItem.item:GetName()
		strIcon = tPendingAccountItem.item:GetIcon()
		-- No strTooltip Needed
	elseif tPendingAccountItem.entitlement and string.len(tPendingAccountItem.entitlement.name) > 0 then
		strName = String_GetWeaselString(Apollo.GetString("AccountInventory_EntitlementPrefix"), tPendingAccountItem.entitlement.name)
		if tPendingAccountItem.entitlement.maxCount > 1 then
			strName = String_GetWeaselString(Apollo.GetString("CRB_EntitlementCount"), strName, tPendingAccountItem.entitlement.count)
		end
		strIcon = tPendingAccountItem.entitlement.icon or strIcon
		strTooltip = tPendingAccountItem.entitlement.description
	elseif tPendingAccountItem.accountCurrency then
		strName = tPendingAccountItem.accountCurrency.monCurrency:GetMoneyString(false)
		strIcon = tPendingAccountItem.icon
		strTooltip = Apollo.GetString(ktCurrencies[tPendingAccountItem.accountCurrency.accountCurrencyEnum].strTooltip or "")
	else -- Error Case
		return
	end

	local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", wndParent, self)
	wndGroup:SetData({bIsGroup = false, tData = tPendingAccountItem})
	wndGroup:FindChild("ItemButton"):SetText(strName)
	wndGroup:FindChild("ItemIconGiftable"):Show(tPendingAccountItem.canGift)
	wndGroup:FindChild("NewItemRunner"):Show(tPendingAccountItem.bIsNew)
	local wndGroupContainer = wndGroup:FindChild("ItemContainer")
	local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroupContainer, self)
	wndObject:SetData(tPendingAccountItem)
	wndObject:FindChild("Name"):SetText("") -- Done at ItemButton if single, Only used by Groups
	wndObject:FindChild("Icon"):SetSprite(bShowLock and "CRB_AMPs:spr_AMPs_LockStretch_Blue" or strIcon)

	-- Icons for the number of redempetions / cooldowns
	if tPendingAccountItem.multiRedeem then -- Should be only multiRedeem
		local bShowCooldown = tPendingAccountItem.cooldown and tPendingAccountItem.cooldown > 0
		wndGroup:FindChild("ItemIconText"):Show(bShowCooldown)
		wndGroup:FindChild("ItemIconText"):SetText(bShowCooldown and self:HelperCooldown(tPendingAccountItem.cooldown) or "")
	end
	wndGroup:FindChild("ItemIconMultiClaim"):Show(tPendingAccountItem.multiRedeem)
	wndGroup:FindChild("ItemIconArrangeVert"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)

	-- Tooltip
	if bShowLock and tPrereqInfo.strText then
		wndObject:SetTooltip(tPrereqInfo.strText)
	elseif tPendingAccountItem.item then
		Tooltip.GetItemTooltipForm(self, wndObject, tPendingAccountItem.item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	else
		wndObject:SetTooltip(strTooltip or "")
	end

	local nHeightBuffer = wndGroup:GetHeight() - wndGroupContainer:GetHeight()
	local nHeight = wndGroup:FindChild("ItemContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = wndGroup:GetAnchorOffsets()
	wndGroup:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nHeightBuffer)
	
	wndParent:RecalculateContentExtents()
end

function AccountInventory:HelperAddPendingGroupToContainer(wndParent, tPendingAccountItemGroup)
	local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", wndParent, self)
	wndGroup:SetData({bIsGroup = true, tData = tPendingAccountItemGroup})
	wndGroup:FindChild("ItemButton"):SetText("")

	local bIsNew = false
	local bIsMultiRedeem = false
	
	local wndGroupContainer = wndGroup:FindChild("ItemContainer")
	for idx, tPendingAccountItem in pairs(tPendingAccountItemGroup.items) do
		local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroupContainer, self)
		wndObject:SetData(tPendingAccountItem)

		local strName = ""
		local strIcon = ""
		local strTooltip = ""
		local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tPendingAccountItem.prereqId) or nil
		local bShowLock = tPrereqInfo and not tPrereqInfo.bIsMet

		if tPendingAccountItem.item then
			strName = tPendingAccountItem.item:GetName()
			strIcon = tPendingAccountItem.item:GetIcon()
			-- No strTooltip Needed
		elseif tPendingAccountItem.entitlement and string.len(tPendingAccountItem.entitlement.name) > 0 then
			strName = tPendingAccountItem.entitlement.name
			if tPendingAccountItem.entitlement.maxCount > 1 then
				strName = String_GetWeaselString(Apollo.GetString("CRB_EntitlementCount"), strName, tPendingAccountItem.entitlement.count)
			end
			strIcon = tPendingAccountItem.entitlement.icon
			strTooltip = tPendingAccountItem.entitlement.description
		elseif tPendingAccountItem.accountCurrency then
			strName = tPendingAccountItem.accountCurrency.monCurrency:GetMoneyString(false)
			strIcon = ktCurrencies[tPendingAccountItem.accountCurrency.accountCurrencyEnum].strIcon or ""
			strTooltip = Apollo.GetString(ktCurrencies[tPendingAccountItem.accountCurrency.accountCurrencyEnum].strTooltip or "")
		else -- Error Case
			strName = Apollo.GetString("CRB_ModuleStatus_Invalid")
			strIcon = "BK3:UI_BK3_StoryPanelAlert_Icon"
		end
		wndObject:FindChild("Name"):SetText(strName)
		wndObject:FindChild("Icon"):SetSprite(bShowLock and "CRB_AMPs:spr_AMPs_LockStretch_Blue" or strIcon)
		bIsNew = bIsNew or tPendingAccountItem.bIsNew
		bIsMultiRedeem = bIsMultiRedeem or tPendingAccountItem.multiRedeem

		if tPendingAccountItemGroup.giftReturnTimeRemaining ~= nil and tPendingAccountItemGroup.giftReturnTimeRemaining > 0 then--Seconds
			local wndItemIconWasGifted = wndGroup:FindChild("ItemIconWasGifted")
			wndItemIconWasGifted:Show(true)

			local nSecs = tPendingAccountItemGroup.giftReturnTimeRemaining
			local nDays = math.floor(nSecs/ 86400)
			nSecs = nSecs - (nDays * 86400)

			local nHours = math.floor(nSecs/ 3600)
			nSecs = nSecs - (nHours * 3600)

			local nMins = math.floor(nSecs/ 60)
			nSecs = nSecs - (nMins * 60)

			local strTime = ""
			local strTimeColor = ""
			local strIcon = ""
			if nDays > 0 or nHours > 0 then
				strTime = String_GetWeaselString(Apollo.GetString("AccountInventory_TimeDayHour"), nDays, nHours)
				if nDays < knMinGiftDays or nDays == knMinGiftDays and nHours == 0 then
					strTimeColor = "UI_WindowTextRed"
					strIcon = "BK3:UI_BK3_AccountInv_GiftRed"
				else
					strTimeColor = "UI_WindowTitleYellow"
					strIcon = "BK3:UI_BK3_AccountInv_GiftYellow"
				end
			elseif nMins > 0 then
				strTime = String_GetWeaselString(Apollo.GetString("AccountInventory_TimeMin"), nMins)
				strIcon = "BK3:UI_BK3_AccountInv_GiftRed"
				strTimeColor = "UI_WindowTextRed"
			else
				strTime = String_GetWeaselString(Apollo.GetString("AccountInventory_TimeSec"), nSecs)
				strIcon = "BK3:UI_BK3_AccountInv_GiftRed"
				strTimeColor = "UI_WindowTextRed"
			end

			local wndTimer = wndItemIconWasGifted:FindChild("Timer")
			wndTimer:SetText(strTime)
			wndTimer:SetTextColor(strTimeColor)
			wndItemIconWasGifted:FindChild("Icon"):SetSprite(strIcon)
		end

		-- Tooltip
		if bShowLock then
			wndObject:SetTooltip(tPrereqInfo.strText)
		elseif tPendingAccountItem.item then
			Tooltip.GetItemTooltipForm(self, wndObject, tPendingAccountItem.item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		else
			wndObject:SetTooltip(strTooltip)
		end
	end
	
	wndGroup:FindChild("ItemIconGiftable"):Show(tPendingAccountItemGroup.canGift)
	wndGroup:FindChild("NewItemRunner"):Show(bIsNew)
	wndGroup:FindChild("ItemIconMultiClaim"):Show(bIsMultiRedeem)
	wndGroup:FindChild("ItemIconArrangeVert"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)

	if #wndGroupContainer:GetChildren() == 0 then -- Error Case
		wndGroup:Destroy()
		return
	end

	local nHeightBuffer = wndGroup:GetHeight() - wndGroupContainer:GetHeight()
	local nHeight = wndGroupContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = wndGroup:GetAnchorOffsets()
	wndGroup:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nHeightBuffer)
	
	wndParent:RecalculateContentExtents()
end

function AccountInventory:OnAccountInventory_RefreshInventory()
	Apollo.StopTimer("AccountInventory_RefreshInventory")
	self.bRefreshInventoryThrottle = false
end

function AccountInventory:RefreshInventory()
	if not self.bRefreshInventoryThrottle then
		self.bRefreshInventoryThrottle = true
		Apollo.StartTimer("AccountInventory_RefreshInventory")
		self:OnRefreshInterfaceMenuAlert() -- Happens even if wndMain hasn't loaded
	end

	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	local nInventoryGridScrollPos = self.tWndRefs.wndInventoryGridContainer:GetVScrollPos()
	local nEscrowGridScrollPos = self.tWndRefs.wndEscrowGridContainer:GetVScrollPos()
	self.tWndRefs.wndInventoryGridContainer:DestroyChildren()
	self.tWndRefs.wndEscrowGridContainer:DestroyChildren()

	-- Currencies
	for idx, tCurrData in pairs(ktCurrencies) do
		local monCurrency = AccountItemLib.GetAccountCurrency(tCurrData.eType)
		if not monCurrency:IsZero() and tCurrData.bShowInList then
			local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", self.tWndRefs.wndInventoryGridContainer, self)
			wndGroup:SetData(-1 * tCurrData.eType) -- Don't need to care about bIsGroup or anything
			wndGroup:FindChild("ItemButton"):SetText(monCurrency:GetMoneyString(false))

			local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroup:FindChild("ItemContainer"), self)
			wndObject:SetData(-1 * tCurrData.eType) -- To avoid collision with ID 1,2,3
			wndObject:FindChild("Name"):SetText("")
			wndObject:FindChild("Icon"):SetSprite(tCurrData.strIcon)
			wndObject:SetTooltip(Apollo.GetString(tCurrData.strTooltip or ""))
		end
	end

	-- Boom Boxes (Account Bound only, not Escrow)
	local nBoomBoxCount = 0
	local tBoomBoxData = nil
	local arAccountItems = AccountItemLib.GetAccountItems()
	for idx, tAccountItem in ipairs(arAccountItems) do
		if tAccountItem.item and tAccountItem.item:GetItemId() == knBoomBoxItemId then
			tBoomBoxData = tAccountItem
			nBoomBoxCount = nBoomBoxCount + 1
		end
	end

	if nBoomBoxCount > 0 then
		local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", self.tWndRefs.wndInventoryGridContainer, self)
		wndGroup:SetData({bIsGroup = false, tData = tBoomBoxData})
		wndGroup:FindChild("ItemButton"):SetText(String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_MultiItem"), nBoomBoxCount, tBoomBoxData.item:GetName()))
		wndGroup:FindChild("ItemIconText"):Show(tBoomBoxData.cooldown and tBoomBoxData.cooldown > 0)
		wndGroup:FindChild("ItemIconText"):SetText(tBoomBoxData.cooldown and self:HelperCooldown(tBoomBoxData.cooldown) or "")
		wndGroup:FindChild("ItemIconArrangeVert"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)

		local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroup:FindChild("ItemContainer"), self)
		wndObject:SetData(tBoomBoxData)
		wndObject:FindChild("Name"):SetText("")
		wndObject:FindChild("Icon"):SetSprite(tBoomBoxData.item:GetIcon())
	end

	-- Separator if we added at least one
	if next(self.tWndRefs.wndInventoryGridContainer:GetChildren()) then
		Apollo.LoadForm(self.xmlDoc, "InventoryHorizSeparator", self.tWndRefs.wndInventoryGridContainer, self)
	end

	-- Account Bound Inventory
	local bShowMulti = self.tWndRefs.wndInventoryFilterMultiBtn:IsChecked()
	local bShowLocked = self.tWndRefs.wndInventoryFilterLockedBtn:IsChecked()
	table.sort(arAccountItems, function(a,b) return a.index > b.index end)
	for idx, tAccountItem in ipairs(arAccountItems) do
		if not tAccountItem.item or tAccountItem.item:GetItemId() ~= knBoomBoxItemId then
			local bFilterFinalResult = bShowMulti or (not tAccountItem.multiRedeem) -- Bracket should be only multiRedeem
			if bFilterFinalResult and not bShowLocked then
				local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tAccountItem.prereqId) or nil
				bFilterFinalResult = not tPrereqInfo or tPrereqInfo.bIsMet
			end

			if bFilterFinalResult then
				self:HelperAddPendingSingleToContainer(self.tWndRefs.wndInventoryGridContainer, tAccountItem)
			end
		end
	end
	self.tWndRefs.wndInventoryGridContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.tWndRefs.wndInventoryGridContainer:SetVScrollPos(nInventoryGridScrollPos)

	-- Escrow Groups
	local bWasGifted = false
	local arAccountItemGroups = AccountItemLib.GetPendingAccountItemGroups()
	table.sort(arAccountItemGroups, 
		function(a,b) 
			if a.giftReturnTimeRemaining ~= nil and b.giftReturnTimeRemaining ~= nil then
				return a.index > b.index 
			elseif a.giftReturnTimeRemaining ~= nil then
				return true
			elseif b.giftReturnTimeRemaining ~= nil then
				return false
			end
			return a.index > b.index 
		end
		)
	for idx, tPendingAccountItemGroup in pairs(arAccountItemGroups) do
		if not bWasGifted and tPendingAccountItemGroup.giftReturnTimeRemaining ~= nil then
			bWasGifted = true
		elseif bWasGifted and tPendingAccountItemGroup.giftReturnTimeRemaining == nil then
			bWasGifted = false
			Apollo.LoadForm(self.xmlDoc, "InventoryHorizSeparator", self.tWndRefs.wndEscrowGridContainer, self)
		end
		self:HelperAddPendingGroupToContainer(self.tWndRefs.wndEscrowGridContainer, tPendingAccountItemGroup)
	end
	self.tWndRefs.wndEscrowGridContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.tWndRefs.wndEscrowGridContainer:SetVScrollPos(nEscrowGridScrollPos)

	self:UpdateValidationNotifications()
end

function AccountInventory:RefreshInventoryActions()
	local wndSelectedPendingItem
	for idx, wndPendingItem in pairs(self.tWndRefs.wndEscrowGridContainer:GetChildren()) do
		if wndPendingItem:FindChild("ItemButton") and wndPendingItem:FindChild("ItemButton"):IsChecked() then
			wndSelectedPendingItem = wndPendingItem
			break
		end
	end

	local wndSelectedItem
	for idx, wndItem in pairs(self.tWndRefs.wndInventoryGridContainer:GetChildren()) do
		if wndItem:FindChild("ItemButton") and wndItem:FindChild("ItemButton"):IsChecked() then -- Could be a divider
			wndSelectedItem = wndItem
			break
		end
	end

	local bPendingNeedsTwoFactorToGift = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.TwoStepVerification) <= 0
	local tSelectedPendingData = wndSelectedPendingItem ~= nil and wndSelectedPendingItem:GetData() or nil
	local tSelectedData = wndSelectedItem ~= nil and wndSelectedItem:GetData() or nil
	local bPendingCanClaim = tSelectedPendingData ~= nil and tSelectedPendingData.tData.canClaim
	local bPendingCanGift = tSelectedPendingData ~= nil and tSelectedPendingData.tData.canGift
	local bPendingCanReturn = tSelectedPendingData ~= nil and tSelectedPendingData.tData.canReturn
	
	self.tWndRefs.wndInventoryNoClaimNotice:Show(tSelectedPendingData ~= nil and not bPendingCanClaim and not self.bHasFraudCheck)
	self.tWndRefs.wndInventoryClaimHoldNotice:Show(tSelectedPendingData ~= nil and not bPendingCanClaim and self.bHasFraudCheck)
	self.tWndRefs.wndInventoryClaimBtn:Enable(bPendingCanClaim)
	self.tWndRefs.wndInventoryClaimBtn:SetData(tSelectedPendingData)

	self.tWndRefs.wndInventoryGiftBtn:Enable(bPendingCanGift and not bPendingNeedsTwoFactorToGift)
	self.tWndRefs.wndInventoryGiftBtn:SetData(tSelectedPendingData)
	self.tWndRefs.wndInventoryGiftBtn:Show(not bPendingCanReturn)
	self.tWndRefs.wndInventoryGiftTwoFactorNotice:Show(bPendingCanGift and bPendingNeedsTwoFactorToGift and not self.bHasFraudCheck)
	self.tWndRefs.wndInventoryGiftHoldNotice:Show(self.bHasFraudCheck)

	self.tWndRefs.wndInventoryReturnBtn:Enable(bPendingCanReturn)
	self.tWndRefs.wndInventoryReturnBtn:SetData(tSelectedPendingData)
	self.tWndRefs.wndInventoryReturnBtn:Show(bPendingCanReturn)

	-- Check if currency
	local bCanBeClaimed = true
	if tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and tSelectedData.tData.item and tSelectedData.tData.item:GetItemId() == knBoomBoxItemId then -- If BoomBox
		bCanBeClaimed = tSelectedData.tData.cooldown == 0
	elseif tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and type(tSelectedData.tData) == "number" then -- If Credd/NameChange/RealmTransfer
		bCanBeClaimed = tSelectedData.tData >= 0
	elseif tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData then
		bCanBeClaimed = true
	elseif tSelectedData and type(tSelectedData) == "number" then -- Redundant check if Credd/NameChange/RealmTransfer
		bCanBeClaimed = tSelectedData >= 0
	end

	-- It's an item, check pre-reqs
	if bCanBeClaimed and tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and tSelectedData.tData.prereqId > 0 then
		local tPrereqInfo = GameLib.GetPlayerUnit():GetPrereqInfo(tSelectedData.tData.prereqId)
		bCanBeClaimed = tPrereqInfo and tPrereqInfo.bIsMet and tSelectedData.tData.canClaim
	end

	self.tWndRefs.wndInventoryTakeBtn:Enable(tSelectedData and bCanBeClaimed)
	self.tWndRefs.wndInventoryTakeBtn:SetData(tSelectedData)
	self.tWndRefs.wndInventoryTakeBtn:Show(tSelectedData ~= keCreddType)
	self.tWndRefs.wndInventoryRedeemCreddBtn:Show(tSelectedData == keCreddType)
end

function AccountInventory:OnPendingInventoryItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	local wndParent = wndControl:GetParent()
	local tAccountItemData = wndParent:GetData()
	if tAccountItemData and type(tAccountItemData) == "table" and tAccountItemData.tData.bIsNew then 
		wndParent:FindChild("NewItemRunner"):Show(false)
	end

	self:RefreshInventoryActions()
end

function AccountInventory:OnPendingInventoryItemUncheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventoryActions()
end

function AccountInventory:OnInventoryFilterToggle(wndHandler, wndControl)
	self.tWndRefs.wndInventoryGridContainer:SetVScrollPos(0)
	self.tWndRefs.wndInventoryGridContainer:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self:RefreshInventory()
end

function AccountInventory:OnPendingClaimBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventoryClaimConfirm:SetData(wndControl:GetData())
	self:RefreshPendingConfirm()

	self.tWndRefs.wndInventoryClaimConfirm:Show(true)
end

function AccountInventory:OnPendingGiftBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventoryGift:SetData(wndControl:GetData())
	self:RefreshInventoryGift()

	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryGift:Show(true)
end

function AccountInventory:OnInventoryTakeBtn(wndHandler, wndControl, eMouseButton)
	local tTakeData = wndHandler:GetData()
	self.tWndRefs.wndInventoryTakeConfirm:SetData(tTakeData)
	self.tWndRefs.wndInventoryTakeConfirmContainer:DestroyChildren()
	self.tWndRefs.wndInventoryTakeConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.AccountTakeItem, tTakeData.tData.index)

	self:HelperAddPendingSingleToContainer(self.tWndRefs.wndInventoryTakeConfirmContainer, tTakeData.tData)

	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryTakeConfirm:Show(true)

	for idx, wndCurr in pairs(self.tWndRefs.wndInventoryTakeConfirmContainer:GetChildren()) do
		wndCurr:Enable(false)
		if wndCurr:FindChild("ItemButton") then
			wndCurr:FindChild("ItemButton"):ChangeArt("CRB_DEMO_WrapperSprites:btnDemo_CharInvisible")
		end
	end
end

function AccountInventory:OnInventoryRedeemCreddBtn(wndHandler, wndControl, eMouseButton)
	local tCurrData = ktCurrencies[AccountItemLib.CodeEnumAccountCurrency.CREDD]
	self.tWndRefs.wndInventoryRedeemCreddConfirm:SetData(tCurrData)
	self.tWndRefs.wndInventoryCreddRedeemConfirmContainer:DestroyChildren()
	self.tWndRefs.wndInventoryRedeemCreddConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.AccountCreddRedeem)

	local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", self.tWndRefs.wndInventoryCreddRedeemConfirmContainer, self)
	wndGroup:SetData(-1 * tCurrData.eType)
	local monObj = Money.new()
	monObj:SetAccountCurrencyType(tCurrData.eType)
	monObj:SetAmount(1)
	wndGroup:FindChild("ItemButton"):SetText(monObj:GetMoneyString(false))

	local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroup:FindChild("ItemContainer"), self)
	wndObject:SetData(-1 * tCurrData.eType)
	wndObject:FindChild("Name"):SetText("")
	wndObject:FindChild("Icon"):SetSprite(tCurrData.strIcon)
	wndObject:SetTooltip(Apollo.GetString(tCurrData.strTooltip or ""))

	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(true)
end

function AccountInventory:OnPendingReturnBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventoryGiftReturnConfirm:SetData(wndControl:GetData())
	self:RefreshInventoryGiftReturnConfirm()

	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryGiftReturnConfirm:Show(true)
end

--[[
Inventory Claim Confirm
]]--

function AccountInventory:RefreshPendingConfirm()
	local tSelectedPendingData = self.tWndRefs.wndInventoryClaimConfirm:GetData()
	self.tWndRefs.wndPendingClaimContainer:DestroyChildren()

	local nIndex = tSelectedPendingData.tData.index
	local bIsGroup = tSelectedPendingData.bIsGroup

	self.tWndRefs.wndInventoryClaimConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.AccountClaimItem, nIndex, bIsGroup)

	if tSelectedPendingData.bIsGroup then
		self:HelperAddPendingGroupToContainer(self.tWndRefs.wndPendingClaimContainer, tSelectedPendingData.tData)
	else
		self:HelperAddPendingSingleToContainer(self.tWndRefs.wndPendingClaimContainer, tSelectedPendingData.tData)
	end

	for idx, wndCurr in pairs(self.tWndRefs.wndPendingClaimContainer:GetChildren()) do
		wndCurr:Enable(false)
		if wndCurr:FindChild("ItemButton") then
			wndCurr:FindChild("ItemButton"):ChangeArt("CRB_DEMO_WrapperSprites:btnDemo_CharInvisible")
		end
	end
end

function AccountInventory:OnAccountPendingItemsClaimed(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryClaimConfirm:Show(false)
end

function AccountInventory:OnPendingConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryClaimConfirm:Show(false)
end

--[[
Inventory Take Confirm
]]--

function AccountInventory:OnAccountPendingItemTook(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryTakeConfirm:Show(false)
end

function AccountInventory:OnInventoryTakeConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryTakeConfirm:Show(false)
end

--[[
Inventory Credd Redeem Confirm
]]--

function AccountInventory:OnAccountCREDDRedeemed(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(false)
end

function AccountInventory:OnInventoryCreddRedeemConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(false)
end

--[[
Inventory Gift
]]--


function AccountInventory:OnFriendshipRemove()
	if not self.tWndRefs.wndInventoryGift or not self.tWndRefs.wndInventoryGift:IsValid() then
		return
	end
	self.tWndRefs.wndInventoryGift:Show(false)
end

function AccountInventory:RefreshInventoryGift()
	local tSelectedPendingData = self.tWndRefs.wndInventoryGift:GetData()

	self.tWndRefs.wndInventoryGiftFriendContainer:DestroyChildren()
	for idx, tFriend in pairs(FriendshipLib.GetAccountList()) do
		local wndFriend = Apollo.LoadForm(self.xmlDoc, "FriendForm", self.tWndRefs.wndInventoryGiftFriendContainer, self)
		wndFriend:SetData(tFriend)
		wndFriend:FindChild("FriendNote"):SetTooltip(tFriend.strPrivateNote or "")
		wndFriend:FindChild("FriendNote"):Show(string.len(tFriend.strPrivateNote or "") > 0)
		wndFriend:FindChild("FriendButton"):SetText(String_GetWeaselString(Apollo.GetString("AccountInventory_AccountFriendPrefix"), tFriend.strCharacterName))
	end
	for idx, tFriend in pairs(FriendshipLib.GetList()) do
		if tFriend.bFriend then -- Not Ignore or Rival
			local wndFriend = Apollo.LoadForm(self.xmlDoc, "FriendForm", self.tWndRefs.wndInventoryGiftFriendContainer, self)
			wndFriend:SetData(tFriend)
			wndFriend:FindChild("FriendNote"):SetTooltip(tFriend.strNote or "")
			wndFriend:FindChild("FriendNote"):Show(string.len(tFriend.strNote or "") > 0)
			wndFriend:FindChild("FriendButton"):SetText(tFriend.strCharacterName)
		end
	end
	-- TODO: Include the note as well

	self.tWndRefs.wndInventoryGiftFriendContainer:SetText(next(self.tWndRefs.wndInventoryGiftFriendContainer:GetChildren()) and "" or Apollo.GetString("AccountInventory_NoFriendsToGiftTo"))
	self.tWndRefs.wndInventoryGiftFriendContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self:RefreshInventoryGiftActions()
end

function AccountInventory:RefreshInventoryGiftActions()
	local wndSelectedFriend

	for idx, wndFriend in pairs(self.tWndRefs.wndInventoryGiftFriendContainer:GetChildren()) do
		if wndFriend:FindChild("FriendButton"):IsChecked() then
			wndSelectedFriend = wndFriend
			break
		end
	end

	self.tWndRefs.wndInventoryGiftFriendSelectBtn:Enable(wndSelectedFriend ~= nil)
end

function AccountInventory:OnFriendCheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventoryGiftActions()
end

function AccountInventory:OnFriendUncheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventoryGiftActions()
end

function AccountInventory:OnPendingSelectFriendGiftBtn(wndHandler, wndControl, eMouseButton)
	local tSelectedPendingData = self.tWndRefs.wndInventoryGift:GetData()

	local wndSelectedFriend
	for idx, wndFriend in pairs(self.tWndRefs.wndInventoryGiftFriendContainer:GetChildren()) do
		if wndFriend:FindChild("FriendButton"):IsChecked() then
			wndSelectedFriend = wndFriend
			break
		end
	end

	tSelectedPendingData.tFriend = wndSelectedFriend:GetData()
	self.tWndRefs.wndInventoryGiftConfirm:SetData(tSelectedPendingData)

	self:RefreshInventoryGiftConfirm()
	self.tWndRefs.wndInventoryGift:Show(false)
	self.tWndRefs.wndInventoryGiftConfirm:Show(true)
end

function AccountInventory:OnPendingGiftCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGift:Show(false)
end

--[[
Inventory Gift Confirm
]]--

function AccountInventory:RefreshInventoryGiftConfirm()
	local tSelectedData = self.tWndRefs.wndInventoryGiftConfirm:GetData()
	self.tWndRefs.wndInventoryGiftConfirmItemContainer:DestroyChildren()

	local nIndex = tSelectedData.tData.index
	local nFriendId = tSelectedData.tFriend.nId
	local bIsGroup = tSelectedData.bIsGroup
	self.tWndRefs.wndInventoryGiftConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.AccountGiftItem, nIndex, bIsGroup, nFriendId)

	if tSelectedData.bIsGroup then
		self:HelperAddPendingGroupToContainer(self.tWndRefs.wndInventoryGiftConfirmItemContainer, tSelectedData.tData)
	else
		self:HelperAddPendingSingleToContainer(self.tWndRefs.wndInventoryGiftConfirmItemContainer, tSelectedData.tData)
	end

	for idx, wndCurr in pairs(self.tWndRefs.wndInventoryGiftConfirmItemContainer:GetChildren()) do
		wndCurr:Enable(false)
		if wndCurr:FindChild("ItemButton") then
			wndCurr:FindChild("ItemButton"):ChangeArt("CRB_DEMO_WrapperSprites:btnDemo_CharInvisible")
			wndCurr:FindChild("ItemIconGiftable"):Show(false)
		end
	end
end

function AccountInventory:OnAccountPendingItemsGifted(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGiftConfirm:Show(false)
end

function AccountInventory:OnPendingGiftConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventoryGift:Show(true)
	self.tWndRefs.wndInventoryGiftConfirm:Show(false)
end

--[[
Inventory Gift Return Confirm
]]--

function AccountInventory:RefreshInventoryGiftReturnConfirm()
	local tSelectedData = self.tWndRefs.wndInventoryGiftReturnConfirm:GetData()
	self.tWndRefs.wndInventoryGiftReturnConfirmItemContainer:DestroyChildren()

	local nIndex = tSelectedData.tData.index
	local bIsGroup = tSelectedData.bIsGroup
	self.tWndRefs.wndInventoryGiftReturnConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.AccountGiftItemReturn, nIndex, bIsGroup)

	if tSelectedData.bIsGroup then
		self:HelperAddPendingGroupToContainer(self.tWndRefs.wndInventoryGiftReturnConfirmItemContainer, tSelectedData.tData)
	else
		self:HelperAddPendingSingleToContainer(self.tWndRefs.wndInventoryGiftReturnConfirmItemContainer, tSelectedData.tData)
	end

	for idx, wndCurr in pairs(self.tWndRefs.wndInventoryGiftConfirmItemContainer:GetChildren()) do
		wndCurr:Enable(false)
		if wndCurr:FindChild("ItemButton") then
			wndCurr:FindChild("ItemButton"):ChangeArt("CRB_DEMO_WrapperSprites:btnDemo_CharInvisible")
			wndCurr:FindChild("ItemIconGiftable"):Show(false)
		end
	end
end

function AccountInventory:OnAccountPendingItemsReturned(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGiftReturnConfirm:Show(false)
end

function AccountInventory:OnPendingGiftReturnConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGiftReturnConfirm:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Entitlement Updates
-----------------------------------------------------------------------------------------------

function AccountInventory:OnEntitlementUpdate(tEntitlementInfo)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() or tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.FraudCheck then
		return
	end
	
	self.bHasFraudCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) ~= 0
	self:UpdateValidationNotifications()
end

function AccountInventory:UpdateValidationNotifications()
	local wndInventoryContainer = self.tWndRefs.wndInventoryContainer
	local wndInventoryValidationNotification = self.tWndRefs.wndInventoryValidationNotification
	local nLeft, nTop, nRight, nBottom = wndInventoryContainer:GetOriginalLocation():GetOffsets()
	
	if not self.bHasFraudCheck and wndInventoryValidationNotification:IsShown() then
		wndInventoryValidationNotification:Show(false)
		wndInventoryContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
		
	elseif self.bHasFraudCheck and not wndInventoryValidationNotification:IsShown() then
		local nHeight = wndInventoryValidationNotification:GetHeight()
		wndInventoryContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - nHeight)
		wndInventoryValidationNotification:Show(true)
	end
	
	self:RefreshInventoryActions()
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function AccountInventory:HelperCooldown(nRawTime)
	local strResult = Apollo.GetString("CRB_LessThan1M")
	local nSeconds = math.floor(nRawTime / 1000)
	local nMinutes = math.floor(nSeconds / 60)
	local nHours = math.floor(nSeconds / 3600)
	local nDays = math.floor(nSeconds / 86400)

	if nDays > 1 then
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Days"), nDays)
	elseif nHours > 1 then
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Hours"), nHours)
	elseif nMinutes > 1 then
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Minutes"), nMinutes)
	end

	return strResult
end

local AccountInventoryInst = AccountInventory:new()
AccountInventoryInst:Init()