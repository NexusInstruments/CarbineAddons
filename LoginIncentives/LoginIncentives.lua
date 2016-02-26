-----------------------------------------------------------------------------------------------
-- Client Lua Script for LoginIncentives
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "AccountItemLib"
require "LiveEventsLib"
require "StorefrontLib"
require "Tooltip"

local LoginIncentives = {} 

function LoginIncentives:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function LoginIncentives:Init()
    Apollo.RegisterAddon(self)
end
 
local knItemsPerRowMain 	= 5
-----------------------------------------------------------------------------------------------
-- LoginIncentives OnLoad
-----------------------------------------------------------------------------------------------
function LoginIncentives:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("LoginIncentives.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- LoginIncentives OnDocLoaded
-----------------------------------------------------------------------------------------------
function LoginIncentives:OnDocLoaded()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("OpenDailyLogin", "OnLoginIncentivesOn", self)
	Apollo.RegisterEventHandler("DailyLoginUpdate", "OnDailyLoginUpdate", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self)
	Apollo.RegisterEventHandler("PlayerEnteredWorld", "OnPlayerEnteredWorld", self)
	
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 	"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("InterfaceMenu_InvokeLoginIncentives", 	"OnLoginIncentivesOn", self)

	--Events
	Apollo.RegisterEventHandler("BonusEventsChanged", "DrawEventItemContainer", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "LoginIncentives", nil, self)
	self.arDailyLoginRewardWindows = {}
	self.arDailyLoginRewardsAvailable = AccountItemLib.GetDailyLoginRewardsAvailable()
	self.arAllDailyLoginRewards = AccountItemLib.GetDailyLoginRewards()
	self.bHaveRewards = #self.arDailyLoginRewardsAvailable > 0

end

function LoginIncentives:OnPlayerEnteredWorld()
	if self.bHaveRewards then
		self:ShowLoginNotifications()
	end
end

function LoginIncentives:OnInterfaceMenuListHasLoaded()
	if not self.bInterfaceMenuListLoaded then
		Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("LoginIncentives_DailyLogin"), { "InterfaceMenu_InvokeLoginIncentives", "", "Icon_Windows32_UI_CRB_InterfaceMenu_Gift" })
		self.bInterfaceMenuListLoaded = true
	end
end

function LoginIncentives:ShowLoginNotifications()
	if self.wndLoginIncentivesReminder then
		self.wndLoginIncentivesReminder:Destroy()
	end

	if self.wndFlare then
		self.wndFlare:Destroy()
	end

	self.wndLoginIncentivesReminder = Apollo.LoadForm(self.xmlDoc, "LoginIncentivesReminder", nil, self)
	self.wndFlare = Apollo.LoadForm(self.xmlDoc, "Flare", nil, self)

	self.timerShowFlare = ApolloTimer.Create(3.0, false, "OnShowFlare", self)
end

function LoginIncentives:OnLoginIncentivesOn()
	if self.wndMain:IsShown() then
		self.wndMain:Close()
		return
	end
	self.tSelectedRewards = {}
	self:DrawAll()
	self.wndMain:Invoke() -- show the window
end

function LoginIncentives:DrawAll()
	self:DrawReadyToClaimWindow()
	self:DrawItemContainer()
	self:DrawEventItemContainer()
end

function LoginIncentives:DrawReadyToClaimWindow()
	self.nLoginDays = AccountItemLib.GetLoginDays()
	local wndReadyToClaim = self.wndMain:FindChild("ReadyToClaim")
	local wndAlreadyClaimed = self.wndMain:FindChild("AlreadyClaimed")
	self.wndMain:FindChild("TitleText"):SetText(String_GetWeaselString(Apollo.GetString("LoginIncentives_Title"), self.nLoginDays))
	
	local nNumRewards = #self.arDailyLoginRewardsAvailable
	self.bHaveRewards = nNumRewards > 0
	local wndClaimDailyBonusBtn = wndReadyToClaim:FindChild("ClaimBtn")

	wndReadyToClaim:Show(self.bHaveRewards)
	wndAlreadyClaimed:Show(not self.bHaveRewards)
	
	local wndItemContainer = wndReadyToClaim:FindChild("ItemContainer")
	wndItemContainer:DestroyChildren()

	local tLoginRewardData = self.arAllDailyLoginRewards[self.nLoginDays]--Get the latest reward first.
	local wndDailyLoginItem = Apollo.LoadForm(self.xmlDoc, "ReadyToClaimItem", wndItemContainer, self)
	
	local wndItemIcon = wndDailyLoginItem:FindChild("ItemIcon")
	if tLoginRewardData and tLoginRewardData.tReward.item then
		wndItemIcon:GetWindowSubclass():SetItem(tLoginRewardData.tReward.item)
		wndItemIcon:SetData(tLoginRewardData.tReward.item)
	end

	local bShowAlreadyClaimed = false
	local strText = Apollo.GetString("Contracts_ClaimReward")
	if nNumRewards > 1 then
		strText = String_GetWeaselString(Apollo.GetString("LoginIncentives_ClaimAllRewards"), nNumRewards)
	end

	if (not tLoginRewardData and nNumRewards <= 0) or (tLoginRewardData and tLoginRewardData.bRewarded) then
		strText = Apollo.GetString("LoginIncentives_Claimed")
		bShowAlreadyClaimed = true
	end

	wndDailyLoginItem:FindChild("AlreadyClaimed"):Show(bShowAlreadyClaimed)
	wndClaimDailyBonusBtn:SetText(strText)
end

function LoginIncentives:DrawItemContainer()
	local wndScrollingItems = self.wndMain:FindChild("ScrollingItems")
	wndScrollingItems:DestroyChildren()
	for idx, tDailyRewardData in pairs(self.arAllDailyLoginRewards) do
		self:HelperDrawRewardItem(tDailyRewardData, wndScrollingItems)
	end

	wndScrollingItems:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self:HelperShowCurrentItem(wndScrollingItems, knItemsPerRowMain)
end

function LoginIncentives:DrawEventItemContainer()
	local wndEventButtonContainer = self.wndMain:FindChild("EventButtonContainer")
	wndEventButtonContainer:DestroyChildren()

	--Create small btns
	local nNumEvents = 0
	local wndFirstEventBtn = nil
	for idx, tEventData in pairs(LiveEventsLib.GetBonusLiveEventList()) do
		local wndEventButton = Apollo.LoadForm(self.xmlDoc, "EventButton", wndEventButtonContainer, self)
		
		if not wndFirstEventBtn then
			wndFirstEventBtn = wndEventButton
		end

		wndEventButton:SetTooltip(tEventData:GetName())
		wndEventButton:FindChild("Icon"):SetSprite(tEventData:GetIcon())
		wndEventButton:FindChild("Button"):SetData(tEventData)
		nNumEvents = nNumEvents + 1
	end
	wndEventButtonContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	
	local bHaveEvents = nNumEvents > 0

	self.wndMain:FindChild("NoEventBlocker"):Show(not bHaveEvents)
	self.wndMain:FindChild("EventItemContainer"):Show(bHaveEvents)
	
	if wndFirstEventBtn then
		local wndBtn = wndFirstEventBtn:FindChild("Button")
		wndBtn:SetCheck(true)
		self:OnEventBtn(wndBtn, wndBtn)
	end
end

function LoginIncentives:DrawEventItem(tEventData)
	local wndEventItem = self.wndMain:FindChild("EventItem")
	local wndDescription = wndEventItem:FindChild("Description")
	wndDescription:SetAML("<P TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceMedium\">" .. tEventData:GetSummary() .. "</P>")
	wndDescription:SetHeightToContentHeight()
	wndEventItem:FindChild("DescriptionContainer"):RecalculateContentExtents()
	wndEventItem:FindChild("Title"):SetText(tEventData:GetName())
	wndEventItem:FindChild("Icon"):SetSprite(tEventData:GetIcon())
end

function LoginIncentives:HelperDrawRewardItem(tRewardAvailable, wndContainer)
	local wndDailyLoginItem = Apollo.LoadForm(self.xmlDoc, "DailyLoginItem", wndContainer, self)
	if not self.nItemHeight then
		self.nItemHeight = wndDailyLoginItem:GetHeight()
	end

	if tRewardAvailable.bRewarded then--Already claimed
		wndDailyLoginItem:FindChild("Day"):SetTextColor("UI_TextHoloBody")
		wndDailyLoginItem:FindChild("AlreadyClaimed"):Show(true)
	elseif tRewardAvailable.nLoginDay <= self.nLoginDays then--Not rewarded, and less then current day, means havent claimed for these rewards for a few days.
		wndDailyLoginItem:FindChild("ClaimIcon"):Show(true)
		wndDailyLoginItem:FindChild("Day"):SetTextColor("white")
		if tRewardAvailable.nLoginDay == self.nLoginDays then--Current Day
			self.tSelectedRewards[wndContainer:GetName()] = wndDailyLoginItem
		end
	elseif tRewardAvailable.eDailyLoginRewardTier == AccountItemLib.CodeEnumDailyLoginRewardTier.Milestone then
		wndDailyLoginItem:FindChild("MileStoneIcon"):Show(true)
		wndDailyLoginItem:FindChild("Day"):SetOpacity(0.75)
		wndDailyLoginItem:FindChild("ItemIcon"):SetOpacity(0.75)
		wndDailyLoginItem:SetData(true)
	else
		wndDailyLoginItem:FindChild("Day"):SetTextColor("UI_TextHoloTitle")
		wndDailyLoginItem:FindChild("ItemIcon"):SetOpacity(0.25)
		wndDailyLoginItem:FindChild("Day"):SetOpacity(0.25)
		wndDailyLoginItem:FindChild("FramingBottom"):SetOpacity(0.25)
	end
	
	wndDailyLoginItem:FindChild("Day"):SetText(String_GetWeaselString(Apollo.GetString("LoginIncentives_Day"), tRewardAvailable.nLoginDay))
	
	local wndItemIcon = wndDailyLoginItem:FindChild("ItemIcon")
	if tRewardAvailable.tReward.item then
		wndItemIcon:GetWindowSubclass():SetItem(tRewardAvailable.tReward.item)
	end
	wndItemIcon:SetData(tRewardAvailable.tReward.item)	
	return wndDailyLoginItem
end

function LoginIncentives:OnDailyLoginItemMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local bMilestone = wndHandler:GetData()
	if bMilestone then
		Sound.Play(Sound.PlayUILoginRewardsPurpleHover)
	end
end

function LoginIncentives:HelperShowCurrentItem(wndContainer, nItemsPerRow)
	local nOffset = self.nLoginDays % nItemsPerRow ~= 0 and self.nItemHeight or self.nItemHeight * 2
	local nPos = (self.nItemHeight  * (math.floor(self.nLoginDays / nItemsPerRow))) - nOffset
	wndContainer:SetVScrollPos(nPos)
end

function LoginIncentives:OnDailyLoginUpdate(nLoginDays, nNumberRewards)
	self.arDailyLoginRewardsAvailable = AccountItemLib.GetDailyLoginRewardsAvailable()
	self.arAllDailyLoginRewards = AccountItemLib.GetDailyLoginRewards()
	self.nLoginDays = nLoginDays
	self.bHaveRewards = nNumberRewards > 0

	if self.wndLoginIncentivesReminder then
		self.wndLoginIncentivesReminder:Show(false)
		self.wndFlare:Show(false)
	end

	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
		self:DrawAll()--Update the loging information that is displayed.
	elseif self.bHaveRewards then
		self:ShowLoginNotifications()
	end
end

-----------------------------------------------------------------------------------------------
-- LoginIncentivesForm Functions
-----------------------------------------------------------------------------------------------
function LoginIncentives:OnGenerateRewardItemTooltip(wndHandler, wndControl, eToolTipType, x, y)
	local itemReward = wndControl:GetData()
	if itemReward then--Some rewards don't have items
		local tPrimaryTooltipOpts =
		{
			bPrimary = true,
			itemCompare = itemReward:GetEquippedItemForItemType()
		}
		
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, itemReward, tPrimaryTooltipOpts)
		end
	end
end

function LoginIncentives:OnClaimBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperFinalizeClaimRewards()
	self.wndMain:FindChild("RefreshAnim"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
	self.wndMain:FindChild("ExplodeAnim"):SetSprite("sprLoginIncentives_Burst")
	self.wndMain:FindChild("ExplodeAnimSmaller"):SetSprite("sprLoginIncentives_Burst")
end

function LoginIncentives:HelperFinalizeClaimRewards()
	AccountItemLib.RequestDailyLoginRewards()--Will get DailyLoginUpdate event once the rewards have been claimed.
	self.bHaveRewards = false

	local wndMainSelectedItem = self.tSelectedRewards[self.wndMain:FindChild("ScrollingItems"):GetName()]
	if wndMainSelectedItem and wndMainSelectedItem:IsValid() then
		wndMainSelectedItem:FindChild("ClaimIcon"):Show(true)
	end
end

-- When the main cancel button is clicked.
function LoginIncentives:OnCancel()
	self.wndMain:Close()
end

function LoginIncentives:OnLoginIncentivesClosed(wndHandler, wndControl)
	if not self.bHaveRewards and self.wndLoginIncentivesReminder and self.wndFlare then
		self.wndLoginIncentivesReminder:Show(false)
		self.wndFlare:Show(false)
	end
end

function LoginIncentives:OnEventBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:DrawEventItem(wndControl:GetData())
end

function LoginIncentives:OnAccountInventoryOpen()
	Event_FireGenericEvent("AccountInventoryWindowShow")
end

-----------------------------------------------------------------------------------------------
-- Animating Login Incentives Reminder
-----------------------------------------------------------------------------------------------
function LoginIncentives:OnShowFlare()
	
	local wndSparkles = self.wndFlare:FindChild("Sparkles")
	self.wndFlare:Show(true)
	self.wndFlare:FindChild("IncentiveBtn"):Show(true)
	self.wndFlare:FindChild("Backdrop"):Show(true)
	wndSparkles:Show(true, false)
	
	local nLeft, nTop, nRight, nBottom = self.wndFlare:FindChild("Sparkles"):GetAnchorOffsets()
	local tLocDestination = WindowLocation.new({ fPoints = {0.5,0.5,0.5,0.5}, nOffsets = { -188,-64,144,57 }})
	wndSparkles:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	wndSparkles:TransitionMove(tLocDestination, 2.5)
	self.wndFlare:FindChild("BurstAnimation"):SetSprite("LoginIncentives:sprLoginIncentives_Burst")
	self.wndFlare:FindChild("BurstAnimationChild"):SetSprite("LoginIncentives:sprLoginIncentives_Burst")

	self.timerMoveFlareBtn = ApolloTimer.Create(2.5, false, "OnTransition", self)
	Sound.Play(Sound.PlayUILoginRewardsIconAppears)
end

function LoginIncentives:OnTransition()
	self.wndLoginIncentivesReminder:Show(true)
	self.wndFlare:FindChild("Backdrop"):Show(false)
	self.wndFlare:FindChild("Sparkles"):Show(false)
	self.wndFlare:FindChild("BurstAnimation"):Show(false)
	
	--Transition
	local locReminder = self.wndLoginIncentivesReminder:GetLocation()

	local nFlareHeight = self.wndFlare:GetHeight()
	local nFlareWidth = self.wndFlare:GetWidth()
	local nLeft, nTop, nRight, nBottom = locReminder:GetOffsets()
	local tNewOffsets = {nRight - nFlareWidth/2, nTop, nRight + nFlareWidth/2 , nBottom}

	local nLeftPoint, nTopPoint, nRightPoint, nBottomPoint = locReminder:GetPoints()
	local tLocDestination = WindowLocation.new({ fPoints = {nLeftPoint, nTopPoint, nRightPoint, nBottomPoint}, nOffsets = tNewOffsets})
	self.wndFlare:TransitionMove(tLocDestination, 2, Window.MoveMethod.EaseInOutExpo)
	Sound.Play(Sound.PlayUILoginRewardsIconTravel)
end

-----------------------------------------------------------------------------------------------
-- LoginIncentives Instance
-----------------------------------------------------------------------------------------------
local LoginIncentivesInst = LoginIncentives:new()
LoginIncentivesInst:Init()
