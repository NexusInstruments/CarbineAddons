-----------------------------------------------------------------------------------------------
-- Client Lua Script for MatchMaker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "MatchingGame"
require "GameLib"
require "Unit"
require "GuildLib"
require "GuildTypeLib"
require "GroupLib"

-----------------------------------------------------------------------------------------------
-- MatchMaker Module Definition
-----------------------------------------------------------------------------------------------
local MatchMaker = {}

local karItemQualityColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

local kcrActiveColor				= CColor.new(1, 172/255, 0, 1)
local kcrInactiveColor				= CColor.new(47/2551, 148/255, 172/255, 1)
local kstrConsoleRealmFilter		= "matching.realmOnly"
local kstrConsoleAllowMercFilter	= "matching.mercenaryAllowed"
local kstrConsoleAllowWarpartyFilter= "matching.warpartyAllowed"
local kstrConsoleDoNotFindOthers	= "matching.doNotFindOthers"
local knSaveVersion = 1

-----------------------------------------------------------------------------------------------                 PublicEventType_Adventure_NorthernWilds);
-- Initialization
-----------------------------------------------------------------------------------------------
function MatchMaker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here
	--o.matchSelectedType = nil
	--o.matchSelectedDesc = nil
	o.fTimeRemaining 	= 0
	o.fTimeInQueue 		= 0
	o.fCooldownTime 	= 0
	o.fDuelCountdown	= 0
	o.fDuelWarning		= 0
	--o.myTeam = 0
	--o.myWarparty = 0
	o.eSelectedTab 		= MatchingGame.MatchType.Battleground
	o.eQueuedTab		= MatchingGame.MatchType.Battleground
	--o.matchQueued		= nil

	o.matchesSelected 	= {}
	o.matchesQueued		= {}

    return o
end

function MatchMaker:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- MatchMaker OnLoad
-----------------------------------------------------------------------------------------------
function MatchMaker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MatchMaker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MatchMaker:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 			"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)

    Apollo.RegisterSlashCommand("checkrating", 							"OnCheckRating", self)
	Apollo.RegisterEventHandler("ToggleGroupFinder", 					"OnToggleMatchMaker", self)
	Apollo.RegisterEventHandler("MatchingJoinQueue", 					"OnJoinQueue", self)
	Apollo.RegisterEventHandler("MatchingLeaveQueue", 					"OnLeaveQueue", self)
	Apollo.RegisterEventHandler("MatchingGameReady", 					"OnGameReady", self)
	Apollo.RegisterEventHandler("MatchingGamePendingUpdate", 			"DisplayPendingInfo", self)
	Apollo.RegisterEventHandler("MatchingCancelPendingGame", 			"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchingAverageWaitTimeUpdated", 		"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchEntered", 						"OnMatchEntered", self)
	Apollo.RegisterEventHandler("MatchJoined", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchFinished", 						"RefreshStatus", self)
	Apollo.RegisterEventHandler("PVPMatchFinished", 					"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchExited", 							"OnMatchExited", self)
	Apollo.RegisterEventHandler("MatchLeft", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchingEligibilityChanged", 			"ReloadMaps", self)
	Apollo.RegisterEventHandler("Group_Add", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("Group_Join", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("Group_Remove", 						"RefreshStatus", self)
	Apollo.RegisterEventHandler("Group_Left", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("Group_MemberConnect", 					"RefreshStatus", self)
	Apollo.RegisterEventHandler("Group_MemberPromoted", 				"RefreshStatus", self)
	Apollo.RegisterEventHandler("Group_Updated", 						"RefreshStatus", self)
	Apollo.RegisterEventHandler("GuildQueueStateChanged", 				"RefreshStatus", self)
	Apollo.RegisterEventHandler("ChangeWorld",							"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckStarted", 			"OnRoleCheckStarted", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckHidden", 				"OnRoleCheckHidden", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckCanceled", 			"OnRoleCheckHidden", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 					"OnUnitPvpFlagsChanged", self)
	Apollo.RegisterEventHandler("GuildResult", 							"OnGuildResult", self)
	Apollo.RegisterEventHandler("GuildRoster", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("GuildLoaded", 							"RefreshStatus", self)
	Apollo.RegisterEventHandler("GuildMemberChange", 					"RefreshStatus", self)
	Apollo.RegisterEventHandler("GuildPvp",								"ReloadTeams", self)
	Apollo.RegisterEventHandler("Event_ArenaTeamCreatedOrDisbanded",	"OnArenaTeamAddedOrDisbanded", self)
	Apollo.RegisterEventHandler("Event_WarpartyCreatedOrDisbanded", 	"OnWarpartyAddedOrDisbanded", self)
	Apollo.RegisterEventHandler("MatchVoteKickBegin", 					"OnVoteKickBegin", self)
	Apollo.RegisterEventHandler("MatchVoteKickEnd", 					"OnVoteKickEnd", self)
	Apollo.RegisterEventHandler("MatchVoteSurrenderBegin", 				"OnVoteSurrenderBegin", self)
	Apollo.RegisterEventHandler("MatchVoteSurrenderEnd", 				"OnVoteSurrenderEnd", self)
	Apollo.RegisterEventHandler("MatchLookingForReplacements", 			"RefreshStatus", self)
	Apollo.RegisterEventHandler("MatchStoppedLookingForReplacements", 	"OnRoleCheckHidden", self)
	Apollo.RegisterEventHandler("PlayerLevelChange", 					"ReloadMaps", self)
	Apollo.RegisterEventHandler("UpdateGearScore", 						"OnPlayerChanged", self)
	Apollo.RegisterEventHandler("DuelStateChanged",						"OnDuelStateChanged", self)
	Apollo.RegisterEventHandler("DuelAccepted",							"OnDuelAccepted", self)
	Apollo.RegisterEventHandler("DuelLeftArea",							"OnDuelLeftArea", self)
	Apollo.RegisterEventHandler("DuelCancelWarning",					"OnDuelCancelWarning", self)
	Apollo.RegisterEventHandler("PvpRatingUpdated",						"ReloadMaps", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 					"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_General", 	"OnLevelUpUnlock_GroupFinder_General", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_Dungeons", 	"OnLevelUpUnlock_GroupFinder_Dungeons", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_Adventures", "OnLevelUpUnlock_GroupFinder_Adventures", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_Arenas", 	"OnLevelUpUnlock_GroupFinder_Arenas", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_Warplots", 	"OnLevelUpUnlock_GroupFinder_Warplots", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_PvP_Battleground",		"OnLevelUpUnlock_PvP_Battleground", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)

	--Apollo.RegisterTimerHandler("MatchTimer", 							"OnMatchTimer", self)
	--Apollo.RegisterTimerHandler("MatchPrecisionTimer", 					"StartMatchTimer", self)
    Apollo.RegisterTimerHandler("QueueTimer", 							"OnQueueTimer", self)
    Apollo.RegisterTimerHandler("CooldownTimer", 						"OnCooldownTimer", self)
	Apollo.RegisterTimerHandler("TeamUpdateTimer", 						"OnArenaTeamAddedOrDisbanded", self)
	Apollo.RegisterTimerHandler("WarpartyUpdateTimer",					"OnWarpartyAddedOrDisbanded", self)
	Apollo.RegisterTimerHandler("DuelCountdownTimer", 					"OnDuelCountdownTimer", self)
	Apollo.RegisterTimerHandler("DuelWarningTimer", 					"OnDuelWarningTimer", self)


    -- load our forms
    self.wndMain 					= Apollo.LoadForm(self.xmlDoc, "MatchMakerFrame", nil, self)
	self.wndModeList 				= self.wndMain:FindChild("ModeToggleList")
	self.wndModeListToggle 			= self.wndMain:FindChild("ModeToggle")

	self.wndModeListToggle:AttachWindow(self.wndModeList)

	self.wndModeContent 			= self.wndMain:FindChild("ModeContent")
	self.wndListParent 				= self.wndModeContent:FindChild("MatchListFrame")
	self.wndList 					= self.wndListParent:FindChild("MatchList")
	self.wndRole 					= self.wndModeContent:FindChild("RoleFrame")
	self.wndOthersFilterContainer	= self.wndModeContent:FindChild("OthersFrame")
	self.wndOthersFilter			= self.wndOthersFilterContainer:FindChild("OthersFilterBtn")
	self.wndMercFilterContainer     = self.wndModeContent:FindChild("MercenaryFrame")
	self.wndAllowMercFilter   		= self.wndMercFilterContainer:FindChild("AllowMercenaryBtn")
	self.wndAllowWarpartyFilter		= self.wndMercFilterContainer:FindChild("AllowWarpartyBtn")
	self.wndArenaTeams 				= self.wndModeContent:FindChild("ArenaTeamFrame")


	self.wndJoin 					= self.wndMain:FindChild("JoinBtn")
	self.wndJoinAsGroup 			= self.wndMain:FindChild("JoinAsGroupBtn")
	self.wndLeaveGame 				= self.wndMain:FindChild("LeaveMatchBtn")
	self.wndTeleportIntoGame 		= self.wndMain:FindChild("TeleportIntoMatchBtn")
	self.wndFindReplacements 		= self.wndMain:FindChild("FindReplacementsBtn")
	self.wndVoteDisband 			= self.wndMain:FindChild("VoteDisbandBtn")
	self.wndCancelReplacements 		= self.wndMain:FindChild("CancelReplacementsBtn")
	self.wndAltLeaveGame 			= self.wndMain:FindChild("AltLeaveMatchBtn")
	self.wndAltTeleportIntoGame 	= self.wndMain:FindChild("AltTeleportIntoMatchBtn")
	self.wndQueueInfo 				= self.wndMain:FindChild("MatchQueueInfo")
	self.wndTimeInQueue 			= self.wndQueueInfo:FindChild("TimeInQueue")
	self.wndAverageWaitTime 		= self.wndQueueInfo:FindChild("AverageWaitTime")
	self.wndListBlocker 			= self.wndListParent:FindChild("ListBlocker")
	self.wndFlagInfo 				= self.wndMain:FindChild("PvPInfo")
	self.wndFlagToggle 				= self.wndFlagInfo:FindChild("PvPToggleBtn")
	self.wndConfirmRole 			= Apollo.LoadForm(self.xmlDoc, "RoleConfirm", nil, self)
	self.wndAllyConfirm 			= Apollo.LoadForm(self.xmlDoc, "WaitingOnAllies", nil, self)
	self.wndAllyEnemyConfirm 		= Apollo.LoadForm(self.xmlDoc, "WaitingOnAlliesAndEnemies", nil, self)
	self.wndVoteKick 				= Apollo.LoadForm(self.xmlDoc, "VoteKick", nil, self)
	self.wndVoteSurrender			= Apollo.LoadForm(self.xmlDoc, "VoteSurrender", nil, self)
	self.wndDuelRequest				= Apollo.LoadForm(self.xmlDoc, "DuelRequest", nil, self)
	self.wndDuelWarning				= Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
	self.wndRoleBlocker				= self.wndRole:FindChild("RoleBlocker")
	self.wndMercFilterBlocker		= self.wndMercFilterContainer:FindChild("MercenaryBlocker")
	self.wndOthersFilterBlocker		= self.wndOthersFilterContainer:FindChild("OthersBlocker")
	
	self.wndJoinGame 				= Apollo.LoadForm(self.xmlDoc, "JoinGame", nil, self)
	self.nJoinGameLeft, self.nJoinGameTop, self.nJoinGameRight, self.nJoinGameBottom = self.wndJoinGame:GetAnchorOffsets()
	
	local wndWarning = self.wndJoinGame:FindChild("RatedWarning")
	self.nWarningHeight = self.nJoinGameTop > 0 and wndWarning:GetHeight() or wndWarning:GetHeight() * - 1

	self.wndMyRating 				= self.wndMain:FindChild("RatingWindow")
	self.wndMyRating:Show(false)

	self.wndMain:Show(false, true)
	self.wndJoinGame:Show(false, true)
	self.wndDuelRequest:Show(false, true)
	self.wndDuelWarning:Show(false, true)
	self.wndVoteSurrender:Show(false, true)
	self.wndVoteKick:Show(false, true)
	--self.wndQueueInfo:Show(false)
	self.wndListBlocker:Show(false)
	self.wndConfirmRole:Show(false, true)
	self.wndAllyConfirm:Show(false, true)
	self.wndAllyEnemyConfirm:Show(false, true)
	self.wndRoleBlocker:Show(false)
	self.wndOthersFilterBlocker:Show(false)
	self.wndMercFilterBlocker:Show(false)
	self.bInCombat = false
	
	self.wndJoinGame:FindChild("YesButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.MatchingGameRespondToPending, true)
	self.wndJoinGame:FindChild("NoButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.MatchingGameRespondToPending, false)

	self.tWarparty =
	{
		{
			strLabel 	= Apollo.GetString("MatchMaker_40v40"),
			bHasTeam 	= false,
			bIsLeader 	= false,
			strName 	= "",
			eGuildType 	= GuildLib.GuildType_WarParty,
			eRatingType = MatchingGame.RatingType.Warplot,
			strRating	= "0"
		}
	}

	self.tArenaTeams =
	{
		{
			strLabel 	= Apollo.GetString("ArenaRoster_2v2"),
			bHasTeam 	= false,
			bIsLeader 	= false,
			strName 	= "",
			eGuildType	= GuildLib.GuildType_ArenaTeam_2v2,
			eRatingType = MatchingGame.RatingType.Arena2v2,
			strRating 	= "0"
		},
		{
			strLabel 	= Apollo.GetString("ArenaRoster_3v3"),
			bHasTeam 	= false,
			bIsLeader 	= false,
			strName 	= "",
			eGuildType 	= GuildLib.GuildType_ArenaTeam_3v3,
			eRatingType = MatchingGame.RatingType.Arena3v3,
			strRating 	= "0"
		},
		{
			strLabel 	= Apollo.GetString("ArenaRoster_5v5"),
			bHasTeam 	= false,
			bIsLeader 	= false,
			strName 	= "",
			eGuildType 	= GuildLib.GuildType_ArenaTeam_5v5,
			eRatingType = MatchingGame.RatingType.Arena5v5,
			strRating 	= "0"
		}
	}


	self.tGroupFinderRoleButtons =
	{
		[MatchingGame.Roles.Tank] 	= self.wndRole:FindChild("TankBtn"),
		[MatchingGame.Roles.Healer] = self.wndRole:FindChild("HealerBtn"),
		[MatchingGame.Roles.DPS] 	= self.wndRole:FindChild("DPSBtn"),
	}

	self.tRoleCheckRoleButtons =
	{
		[MatchingGame.Roles.Tank] 	= self.wndConfirmRole:FindChild("TankBtn"),
		[MatchingGame.Roles.Healer] = self.wndConfirmRole:FindChild("HealerBtn"),
		[MatchingGame.Roles.DPS] 	= self.wndConfirmRole:FindChild("DPSBtn"),
	}

	if MatchingGame.IsInMatchingGame() == true then
		self.wndJoin:SetText(Apollo.GetString("MatchMaker_LeaveGame"))
	end

	if MatchingGame.IsGamePending() == true then
		self:OnGameReady()
	else
		self:DisplayPendingInfo()
	end

	if MatchingGame.IsRoleCheckActive() == true then
		self:OnRoleCheckStarted()
	end
end

function MatchMaker:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_GroupFinder"), {"ToggleGroupFinder", "GroupFinder", "Icon_Windows32_UI_CRB_InterfaceMenu_GroupFinder"})
end

function MatchMaker:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("InterfaceMenu_GroupFinder")})
end

-----------------------------------------------------------------------------------------------
-- MatchMaker Functions
-----------------------------------------------------------------------------------------------

function MatchMaker:OnLevelUpUnlock_GroupFinder_General()
	self:OnMatchMakerOn()
	self.wndMain:ToFront()
end

function MatchMaker:OnLevelUpUnlock_GroupFinder_Dungeons()
	self.eSelectedTab = MatchingGame.MatchType.Dungeon
	self:OnLevelUpUnlock_GroupFinder_General()
end

function MatchMaker:OnLevelUpUnlock_GroupFinder_Adventures()
	self.eSelectedTab = MatchingGame.MatchType.Adventure
	self:OnLevelUpUnlock_GroupFinder_General()
end

function MatchMaker:OnLevelUpUnlock_GroupFinder_Arenas()
	self.eSelectedTab = MatchingGame.MatchType.Arena
	self:OnLevelUpUnlock_GroupFinder_General()
end

function MatchMaker:OnLevelUpUnlock_GroupFinder_Warplots()
	self.eSelectedTab = MatchingGame.MatchType.Warplot
	self:OnLevelUpUnlock_GroupFinder_General()
end

function MatchMaker:OnLevelUpUnlock_PvP_Battleground()
	self.eSelectedTab = MatchingGame.MatchType.Battleground
	self:OnLevelUpUnlock_GroupFinder_General()
end

function MatchMaker:OnToggleMatchMaker()
	if self.wndMain:IsShown() then
		self.wndMain:Show(false)
		Event_FireGenericEvent("LFGWindowHasBeenClosed")
	else
		self:OnMatchMakerOn()
		self.wndMain:ToFront()
	end
end

function MatchMaker:ReloadMaps()
	if self.wndMain:IsShown() then
		self.matchesSelected = {}
		self:OnMatchMakerOn()
	end
end

function MatchMaker:ReloadTeams()
	if self.eSelectedTab == MatchingGame.MatchType.Arena then
		self:HelperConfigureListAndTeams(self.tArenaTeams, false)
	elseif self.eSelectedTab == MatchingGame.MatchType.Warplot then
		self:HelperConfigureListAndTeams(self.tWarparty, true)
	end
end

function MatchMaker:OnMatchMakerOn()
	self.wndList:DestroyChildren()
	self.wndMain:Show(true)
	self.wndModeList:Show(false)

	-- go to the correct tab
	if MatchingGame.IsInMatchingGame() and not MatchingGame.IsMatchingGameFinished() then
		local eMatchingGameType = MatchingGame.GetMatchingGameType()
		if eMatchingGameType ~= nil then
			self.eSelectedTab = eMatchingGameType
		end
		-- Public event types don't know if they're in rated or unrated matches.
		-- Check GameLib for a rated match and change the selected tab accordingly.
		if GameLib.InRatedPvpMatch() then
			self.eSelectedTab = MatchingGame.MatchType.Battleground and MatchingGame.MatchType.RatedBattleground or MatchingGame.MatchType.RatedArena
		end
	end

	local tGames = MatchingGame.GetAvailableMatchingGames(self.eSelectedTab)

	if tGames == nil then
		return
	end

	self:SetFlagToggleButton()

	if self.eSelectedTab == MatchingGame.MatchType.Battleground then
		local strMode = Apollo.GetString("MatchMaker_PracticeGrounds")
		self.wndModeListToggle:SetText(strMode)
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("BattlegroundBtn"))
		self:HelperConfigureListAndRealmSelect()
		self.wndListParent:FindChild("HeaderLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_AvailablePrepend"), strMode))
	elseif self.eSelectedTab == MatchingGame.MatchType.Arena then
		self.wndModeListToggle:SetText(Apollo.GetString("MatchMaker_Arenas"))
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("ArenaBtn"))
		self:HelperConfigureListAndTeams(self.tArenaTeams, false)
		self.wndListParent:FindChild("HeaderLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_AvailableArena")))
	elseif self.eSelectedTab == MatchingGame.MatchType.Dungeon then
		local strMode = Apollo.GetString("CRB_Dungeons")
		self.wndModeListToggle:SetText(strMode)
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("DungeonBtn"))
		self:HelperConfigureListAndRole()
		self.wndListParent:FindChild("HeaderLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_AvailablePrepend"), strMode))
	elseif self.eSelectedTab == MatchingGame.MatchType.Adventure then
		local strMode = Apollo.GetString("MatchMaker_Adventures")
		self.wndModeListToggle:SetText(strMode)
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("AdventureBtn"))
		self:HelperConfigureListAndRole()
		self.wndListParent:FindChild("HeaderLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_CurrentPrepend"), strMode))
	elseif self.eSelectedTab == MatchingGame.MatchType.Shiphand then
		local strMode = Apollo.GetString("MatchMaker_Shiphands")
		self.wndModeListToggle:SetText(strMode)
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("ShiphandBtn"))
		self:HelperConfigureListAndFindOthers()
		self.wndListParent:FindChild("HeaderLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_CurrentPrepend"), strMode))
	elseif self.eSelectedTab == MatchingGame.MatchType.Warplot then
		self.wndModeListToggle:SetText(Apollo.GetString("MatchMaker_Warplots"))
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("WarplotsBtn"))
		self:HelperConfigureListAndTeams(self.tWarparty, true)
		self.wndListParent:FindChild("HeaderLabel"):SetText(Apollo.GetString("MatchMaker_AvailableWarplots"))
	elseif self.eSelectedTab == MatchingGame.MatchType.RatedBattleground then
		local strMode = Apollo.GetString("CRB_Battlegrounds")
		self.wndModeListToggle:SetText(strMode)
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("RatedBattlegroundBtn"))
		self:HelperConfigureListAndRating()
		self.wndListParent:FindChild("HeaderLabel"):SetText(Apollo.GetString("MatchMaker_AvailableBGs"))
	elseif self.eSelectedTab == MatchingGame.MatchType.OpenArena then
		self.wndModeListToggle:SetText(Apollo.GetString("MatchMaker_OpenArenas"))
		self.wndModeList:SetRadioSelButton("PvpUI_TypeSelection", self.wndModeList:FindChild("OpenArenaBtn"))
		self:HelperConfigureListAndRealmSelect()
		self.wndListParent:FindChild("HeaderLabel"):SetText(Apollo.GetString("MatchMaker_AvailableOpenArenas"))
	end

	if self.wndRole:IsShown() then
		for idx, wndRoleBtn in pairs(self.tGroupFinderRoleButtons) do
			self.tGroupFinderRoleButtons[idx]:Enable(false)
		end

		local tEligibleRoles = MatchingGame.GetEligibleRoles()
		if tEligibleRoles ~= nil then
			for idx, eRole in ipairs(tEligibleRoles) do
				self.tGroupFinderRoleButtons[eRole]:Enable(true)
			end
		end

		local tSelectedRoles = MatchingGame.GetSelectedRoles()
		if tSelectedRoles and #tEligibleRoles > 0 then
			for idx, eRole in ipairs(tSelectedRoles) do
				if self.tGroupFinderRoleButtons[eRole]:IsEnabled() then
					self.tGroupFinderRoleButtons[eRole]:SetCheck(true)
					MatchingGame.SelectRole(eRole, true)
				else
					MatchingGame.SelectRole(eRole, false)
				end
			end
		end
	end

	local nNumberOfGames = #tGames
	for idx, matchGame in ipairs(tGames) do
		local bIsRandom = matchGame:IsRandom()
		local tRewards = matchGame:GetReward()
		
		--random counts as one entry so if greater than 2
		if not bIsRandom or (bIsRandom and nNumberOfGames > 2) then
			local strForm = tRewards and "RewardEntry" or "GameEntry"
			local wndEntry = Apollo.LoadForm(self.xmlDoc, strForm, self.wndList, self)
			--wndEntry:FindChild("MatchingGameSelectBtn"):SetText("  " .. matchGame:GetName())
			wndEntry:FindChild("MatchingGameLabel"):SetText(matchGame:GetName())
			wndEntry:FindChild("MatchingGameSelectBtn"):SetData(matchGame)
			wndEntry:FindChild("MatchingGameSelectBtn"):SetTooltip(matchGame:GetDescription())
			wndEntry:FindChild("EntryInfoBtn"):SetData(matchGame:GetDescription())
			
			if tRewards then
				wndEntry:FindChild("MatchingGameSelectBtn"):SetTooltip("")
				wndEntry:FindChild("Description"):SetText(matchGame:GetDescription())
				
				local strQualityColor = tRewards.itemReward and tRewards.itemReward:GetItemQuality() and karItemQualityColors[tRewards.itemReward:GetItemQuality()] or "UI_TextHoloBody"
				wndEntry:FindChild("RewardLabel"):SetTextColor(strQualityColor)
				wndEntry:FindChild("RewardLabel"):SetText(tRewards.itemReward:GetName())
				wndEntry:FindChild("RewardIcon"):GetWindowSubclass():SetItem(tRewards.itemReward)
				
				local nXp = tRewards.nXpEarned and tRewards.nXpEarned or 0
				wndEntry:FindChild("XpLabel"):SetText(tostring(Apollo.FormatNumber(nXp, 0, true)))
				
				wndEntry:FindChild("MainCashWindow"):SetMoneySystem(tRewards.monReward:GetMoneyType())
				wndEntry:FindChild("MainCashWindow"):SetAmount(tRewards.monReward:GetAmount(), true)
			end
		end
		
	end

	self:RefreshStatus()
	self.wndList:ArrangeChildrenVert()

	Event_ShowTutorial(GameLib.CodeEnumTutorial.GroupFinderMenu)
end

function MatchMaker:OnRandomEntryMouseEnter(wndHandler, wndControl)
	local wnd = wndControl and wndControl:IsValid() and wndControl:FindChild("Rewards") or nil
	
	if not wnd or not wnd:IsValid() then return end
	
	wnd:FindChild("Rewards"):Show(true)
end

function MatchMaker:OnRandomEntryMouseExit(wndHandler, wndControl)
	local wnd = wndControl and wndControl:IsValid() and wndControl:FindChild("Rewards") or nil
	
	if not wnd or not wnd:IsValid() then return end
	
	wnd:FindChild("Rewards"):Show(false)
end

function MatchMaker:HelperConfigureListAndRealmSelect()
	local nLeft, nTop, nRight, nBottom = self.wndListParent:GetAnchorOffsets()
	local nLeft2, nTop2, nRight2, nBottom2 = self.wndMyRating:GetAnchorOffsets()
	self.wndListParent:SetAnchorOffsets(nLeft, nTop, nRight, nTop2)

	self.wndMyRating:FindChild("RatingValue"):SetText(math.floor(GameLib.GetGearScore()) or 0)
	self.wndMyRating:FindChild("RatingLabel"):SetText(Apollo.GetString("MatchMaker_GearScoreLabel"))

	self.wndArenaTeams:Show(false)
	self.wndRole:Show(false)
	self.wndOthersFilterContainer:Show(false)
	self.wndMercFilterContainer:Show(false)
	self.wndMyRating:Show(true)
end

function MatchMaker:HelperConfigureListAndRating()
	local nLeft, nTop, nRight, nBottom = self.wndListParent:GetAnchorOffsets()
	local nLeft2, nTop2, nRight2, nBottom2 = self.wndMyRating:GetAnchorOffsets()
	self.wndListParent:SetAnchorOffsets(nLeft, 0, nRight, nTop2)

	local tRating = MatchingGame.GetPvpRating(MatchingGame.RatingType.RatedBattleground)
	
	self.wndMyRating:FindChild("RatingValue"):SetText(tRating and tRating.nRating or Apollo.GetString("Challenges_NoProgress"))
	self.wndMyRating:FindChild("RatingLabel"):SetText(Apollo.GetString("MatchMaker_RatingLabelDefault"))

	self.wndArenaTeams:Show(false)
	self.wndRole:Show(false)
	self.wndOthersFilterContainer:Show(false)
	self.wndMercFilterContainer:Show(false)
	self.wndMyRating:Show(true)
end

function MatchMaker:HelperConfigureListAndRole() --dungeons & adventures
	local nLeft, nTop, nRight, nBottom = self.wndListParent:GetAnchorOffsets()
	local nLeftRealm, nTopRealm, nRightRealm, nBottomRealm = self.wndRole:GetAnchorOffsets()

	self.wndListParent:SetAnchorOffsets(nLeft, nBottomRealm, nRight,0)

	self.wndArenaTeams:Show(false)
	self.wndRole:Show(true)
	self.wndOthersFilterContainer:Show(false)
	self.wndMercFilterContainer:Show(false)
	self.wndMyRating:Show(false)
end


function MatchMaker:HelperConfigureListAndFindOthers() --shiphands
	local nLeft, nTop, nRight, nBottom = self.wndListParent:GetAnchorOffsets()
	local nLeftRealm, nTopRealm, nRightRealm, nBottomRealm = self.wndOthersFilterContainer:GetAnchorOffsets()

	self.wndListParent:SetAnchorOffsets(nLeft, nBottomRealm, nRight, 0)

	self.wndArenaTeams:Show(false)
	self.wndRole:Show(false)
	self.wndOthersFilterContainer:Show(true)
	self.wndMercFilterContainer:Show(false)
	self.wndMyRating:Show(false)
end

function MatchMaker:HelperConfigureListAndTeams(tTeam, bForWarplots)
	local nLeft, nTop, nRight , nBottom  = self.wndListParent:GetAnchorOffsets()
	local nLeftMerc, nTopMerc, nRightMerc, nBottomMerc = self.wndMercFilterContainer:GetAnchorOffsets()	
	local nLeftArena, nTopArena, nRightArena, nBottomArena = self.wndArenaTeams:GetAnchorOffsets()

	local kBaseArenaOffset = 1
	
	if bForWarplots then
		nBottomArena = kBaseArenaOffset + nBottomMerc + nBottomArena - nTopArena
		nTopArena = kBaseArenaOffset + nBottomMerc
	else
		nBottomArena = kBaseArenaOffset + nBottomArena - nTopArena
		nTopArena = kBaseArenaOffset
	end
	self.wndArenaTeams:SetAnchorOffsets(nLeft, nTopArena, nRight, nBottomArena)
	self.wndListParent:SetAnchorOffsets(nLeft, nBottomArena, nRight, 0)

	self.wndMercFilterContainer:Show(bForWarplots)
	self.wndArenaTeams:Show(true)
	self.wndRole:Show(false)
	self.wndOthersFilterContainer:Show(false)
	self.wndMyRating:Show(false)
	
	-- teams
	self.wndArenaTeams:FindChild("TeamList"):DestroyChildren()
	
	local bFound = false
	for idx, tInfo in pairs(tTeam) do

		for key, tCurrGuild in pairs(GuildLib.GetGuilds()) do
			if tCurrGuild:GetType() == tTeam[idx].eGuildType then
				tTeam[idx].bHasTeam = true
				tTeam[idx].bIsLeader = tCurrGuild:GetMyRank() == 1
				tTeam[idx].strName = tCurrGuild:GetName()

				local tRatings = tCurrGuild:GetPvpRatings()
				tTeam[idx].nRating = tRatings.nRating or 0

				bFound = true
			end
		end

		if not bFound then
			tTeam[idx].bHasTeam = false
			tTeam[idx].bIsLeader = false
			tTeam[idx].strName = ""
			tTeam[idx].nRating = 0
		end

		local wndEntry = Apollo.LoadForm(self.xmlDoc, "TeamEntry", self.wndArenaTeams:FindChild("TeamList"), self)
		wndEntry:FindChild("TeamRosterBtn"):SetData(tTeam[idx])
		wndEntry:FindChild("TypeLabel"):SetText(tTeam[idx].strLabel)
		wndEntry:FindChild("ArrowMark"):Show(true)

		local tRating = MatchingGame.GetPvpRating(tTeam[idx].eRatingType)
		wndEntry:FindChild("MyRatingValue"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_MyRating"), (tRating and tRating.nRating) or 0))

		if tTeam[idx].bIsLeader == true then -- leader (we can assume has)
			wndEntry:FindChild("LeaderMark"):Show(true)
			wndEntry:FindChild("TeamLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_TeamRating"), tTeam[idx].strName, tTeam[idx].nRating))
		elseif tTeam[idx].bHasTeam then -- has team
			wndEntry:FindChild("TeamLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_TeamRating"), tTeam[idx].strName, tTeam[idx].nRating))
		else
			wndEntry:FindChild("TeamLabel"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_RegisterATeam")))
			wndEntry:FindChild("ArrowMark"):Show(false)
		end
	end
	
	self.wndAllowWarpartyFilter:Enable(bFound)
	self.wndAllowWarpartyFilter:SetCheck(bFound)
	self.wndAllowMercFilter:SetCheck(not bFound)

	self.wndArenaTeams:FindChild("TeamList"):ArrangeChildrenVert()
end

function MatchMaker:OnClose()
	Event_FireGenericEvent("LFGWindowHasBeenClosed")
end

function MatchMaker:OnEnteredCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() then
		return false
	end

	self.bInCombat = bInCombat

	if self.wndMain:IsShown() then
		self:SetFlagToggleButton()
	end
end

function MatchMaker:OnPlayerChanged()
	if not self.wndMain:IsShown() then
		return
	end

	local tGames = MatchingGame.GetAvailableMatchingGames(self.eSelectedTab)
	if tGames == nil then
		return
	end

	self:RefreshStatus()
end


function MatchMaker:OnArenaTeamAddedOrDisbanded()
	if self.wndMain:IsShown() and self.eSelectedTab == MatchingGame.MatchType.Arena then
		self:HelperConfigureListAndTeams(self.tArenaTeams, false)
	end
end

function MatchMaker:OnWarpartyAddedOrDisbanded()
	if self.wndMain:IsShown() and self.eSelectedTab == MatchingGame.MatchType.Warplot then
		self:HelperConfigureListAndTeams(self.tWarparty, true)
	end
end


function MatchMaker:OnGuildResult(guildUpdated, strName, nRank, eResult)
	if guildUpdated == nil then
		return
	end

	if guildUpdated:IsArenaTeam() then
		-- Process on the next frame.
		Apollo.CreateTimer("TeamUpdateTimer", 0.001, false)
	end

	if guildUpdated:GetType() == GuildLib.GuildType_WarParty then
		-- Process on the next frame.
		Apollo.CreateTimer("WarpartyUpdateTimer", 0.001, false)
	end
end


function MatchMaker:RefreshStatus()
	if self.wndAllyConfirm:IsShown() or self.wndAllyEnemyConfirm:IsShown() then
		self:DisplayPendingInfo()
	end

	if self.wndJoinGame:IsShown() and not MatchingGame.IsGamePending() then
		self.wndJoinGame:Show(false)
	end

	if not MatchingGame.IsVoteSurrenderActive() then
		self.wndVoteSurrender:Show(false)
	end

	if not MatchingGame.IsVoteKickActive() then
		self.wndVoteKick:Show(false)
	end

	if not self.wndMain:IsShown() then
		return
	end

	local tChildren = self.wndList:GetChildren()
	if tChildren == nil then
		return
	end

	for idx, wndEntry in ipairs(tChildren) do
		local matchGame = wndEntry:FindChild("MatchingGameSelectBtn"):GetData()

		if matchGame ~= nil then
			wndEntry:FindChild("QueueLabel"):Show(matchGame:IsQueued())
			wndEntry:FindChild("MatchingGameSelectBtn"):Enable(not bQueued)

			wndEntry:FindChild("MatchingGameSelectBtn"):SetCheck(false)
			for strMatchName, oMatch in pairs(self.matchesSelected) do
				if oMatch == matchGame then
					wndEntry:FindChild("MatchingGameSelectBtn"):SetCheck(true)
					break
				end
			end

			--wndEntry:SetCheck(self.matchSelectedDesc == matchGame)
		end
	end

	Apollo.StopTimer("QueueTimer")
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_GroupFinder"), {false})

	local bIsQueued = MatchingGame.IsQueuedForMatching()
	self.wndTimeInQueue:SetText("")
	self.wndAverageWaitTime:SetText("")
	self.wndQueueInfo:FindChild("QueueStatus"):SetText("")
	self.wndQueueInfo:FindChild("QueueStatus"):SetTextColor(kcrInactiveColor)
	self.wndQueueInfo:FindChild("QueueType"):SetText("")
	self.wndQueueInfo:FindChild("LeaveQueueBtn"):Show(false)
	self.wndQueueInfo:FindChild("LabelType"):Show(false)
	self.wndQueueInfo:FindChild("LabelTime"):Show(false)
	self.wndQueueInfo:FindChild("LabelWaitTime"):Show(false)

	self.wndJoin:Show(true)
	self.wndJoinAsGroup:Show(true)
	self.wndLeaveGame:Show(false)
	self.wndTeleportIntoGame:Show(false)
	self.wndFindReplacements:Show(false)
	self.wndVoteDisband:Show(false)
	self.wndCancelReplacements:Show(false)
	self.wndAltLeaveGame:Show(false)
	self.wndAltTeleportIntoGame:Show(false)
	self.wndModeListToggle:Enable(true)

	self.wndAllowMercFilter:SetCheck(Apollo.GetConsoleVariable(kstrConsoleAllowMercFilter) or false)
	self.wndAllowWarpartyFilter:SetCheck(Apollo.GetConsoleVariable(kstrConsoleAllowWarpartyFilter) or false)
	self.wndOthersFilter:SetCheck(Apollo.GetConsoleVariable(kstrConsoleDoNotFindOthers) or false)

	local bWaitingForWarParty = false
	local bQueuedGuild = false

	if next(self.matchesQueued) == nil and bIsQueued then -- queued, but we don't know what for
		local tAllTypes =
		{
			MatchingGame.MatchType.Battleground,
			MatchingGame.MatchType.Arena,
			MatchingGame.MatchType.Dungeon,
			MatchingGame.MatchType.Adventure,
			MatchingGame.MatchType.Warplot,
			MatchingGame.MatchType.RatedBattleground,
			MatchingGame.MatchType.OpenArena
		}

		for key, nType in pairs(tAllTypes) do
			local tGames = MatchingGame.GetAvailableMatchingGames(nType)
			for key, matchGame in pairs(tGames) do
				if matchGame:IsQueued() == true then
					self.matchesQueued[matchGame:GetName()] = matchGame

					if matchGame:GetType() == MatchingGame.MatchType.Warplot then
						bWaitingForWarParty = not MatchingGame.IsWarpartyQueued()
						bQueuedGuild = MatchingGame.DoesRequestWarplotInit()
					end
				end
			end
		end
	end

	if bIsQueued then
		self.wndQueueInfo:FindChild("LabelType"):Show(true)
		self.wndQueueInfo:FindChild("LabelTime"):Show(true)
		self.wndQueueInfo:FindChild("LabelWaitTime"):Show(true)

		local nAverageWaitTime = MatchingGame.GetAverageWaitTime()
		local strWaitText = ""
		if nAverageWaitTime == 0 then
			strWaitText = Apollo.GetString("MatchMaker_UnknownTimer")
		else
			strWaitText = self:GetTimeString(MatchingGame.GetAverageWaitTime())
		end
		self.wndAverageWaitTime:SetText(strWaitText)
		self.fTimeInQueue = MatchingGame.GetTimeInQueue()

		self.wndTimeInQueue:SetText(self:GetTimeString(self.fTimeInQueue))
		self:StartQueueTimer()

		--See if we have more then one element in the table or just one element in the table
		local oFirstQueuedKey = next(self.matchesQueued)
		if oFirstQueuedKey ~= nil and next(self.matchesQueued, oFirstQueuedKey) ~= nil then
			self.wndQueueInfo:FindChild("QueueType"):SetText(Apollo.GetString("MatchMaker_QueuedForSeveral"))
		elseif next(self.matchesQueued) ~= nil then
			self.wndQueueInfo:FindChild("QueueType"):SetText(self.matchesQueued[oFirstQueuedKey]:GetName())
		end

		self.wndRole:FindChild("RoleHeaderLabel"):SetText(Apollo.GetString("MatchMaker_QueuedAs"))
	else
		self.wndRole:FindChild("RoleHeaderLabel"):SetText(Apollo.GetString("MatchMaker_SetRole"))
	end

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	if tSelectedRoles then
		for idx, eRole in ipairs(tSelectedRoles) do
			self.wndRoleBlocker:Show(bIsQueued)
			self.wndOthersFilterBlocker:Show(bIsQueued)
			self.wndMercFilterBlocker:Show(bIsQueued)
			--self.tGroupFinderRoleButtons[eRole]:Enable(bIsQueued == false)
		end
	end


	--if MatchingGame.CanLeaveQueueAsGroup() then
		--self.wndJoinAsGroup:Enable(true)
	if next(self.matchesSelected) ~= nil then
		local bDoesGroupMeetRequirements = true
		for strMatchName, oMatch in pairs(self.matchesSelected) do
			bDoesGroupMeetRequirements = bDoesGroupMeetRequirements and oMatch:DoesGroupMeetRequirements()
		end

		self.wndJoinAsGroup:Enable(bDoesGroupMeetRequirements and MatchingGame.CanQueueAsGroup() and not MatchingGame.IsRoleCheckActive())
	else
		self.wndJoinAsGroup:Enable(false)
	end

	self.wndModeListToggle:Enable(true)
	self.wndListBlocker:Show(false)

	local bQueuedSolo = bIsQueued and not MatchingGame.IsQueuedAsGroup()
	local bQueuedGroup = bIsQueued and MatchingGame.IsQueuedAsGroup()
	local bInGame = MatchingGame.IsInMatchingGame()
	local bInInstance = MatchingGame.IsInMatchingInstance()
	local bLeader = GroupLib.AmILeader()
	local bIsGameFinished = MatchingGame.IsMatchingGameFinished()

	if bInGame then
		--self.wndJoin:ChangeArt("CRB_Basekit:kitBtn_Metal_LargeRed")
		self.wndQueueInfo:FindChild("QueueStatus"):SetText(Apollo.GetString("MatchMaker_InGame"))
		self.wndQueueInfo:FindChild("QueueStatus"):SetTextColor(kcrActiveColor)
		self.wndJoin:Show(false)
		self.wndJoinAsGroup:Show(false)

		if bIsGameFinished then
			self.wndQueueInfo:FindChild("QueueStatus"):SetText(Apollo.GetString("Matchmaker_NotQueued"))
			self.wndQueueInfo:FindChild("QueueStatus"):SetTextColor(kcrInactiveColor)
			if bLeader then
				self.wndJoinAsGroup:Show(true)
				self.wndModeListToggle:Enable(true)
				self.wndListBlocker:Show(false)
			elseif not bInInstance then
				self.wndListBlocker:Show(true)
				self.wndListBlocker:SetText(Apollo.GetString("MatchMaker_CantQueueWhileGrouped"))
			end
			
			self.wndLeaveGame:Show(true)
		else
			local tMatchState = MatchingGame:GetPVPMatchState()
			local bCanDisband = not tMatchState -- Not in PvP.

			self.wndListBlocker:Show(true)
			self.wndListBlocker:SetText(Apollo.GetString("MatchMaker_CurrentlyInMatch"))

			self.wndModeListToggle:Enable(false)
			self.wndVoteDisband:Show(bCanDisband and not bLeader and GroupLib.GetMemberCount() > 1)
			self.wndVoteDisband:SetText(Apollo.GetString(self.eSelectedTab == MatchingGame.MatchType.Warplot and "MatchMaker_SurrenderMatch" or "MatchMaker_VoteDisband"))

			if not bInInstance then
				if bLeader and MatchingGame.CanLookForReplacements() then
					self.wndAltTeleportIntoGame:Show(true)
					self.wndFindReplacements:Show(true)
				elseif bLeader and MatchingGame.IsLookingForReplacements() then
					self.wndAltTeleportIntoGame:Show(true)
					self.wndCancelReplacements:Show(true)
				else
					self.wndTeleportIntoGame:Show(true)
				end
			elseif bLeader and MatchingGame.CanLookForReplacements() then
				self.wndAltLeaveGame:Show(true)
				self.wndFindReplacements:Show(true)
			elseif bLeader and MatchingGame.IsLookingForReplacements() then
				self.wndAltLeaveGame:Show(true)
				self.wndCancelReplacements:Show(true)
			else
				self.wndVoteDisband:Show(bCanDisband and GroupLib.GetMemberCount() > 1)
				self.wndAltLeaveGame:Show(true)
			end
		end
		self.wndJoin:SetText(Apollo.GetString("MatchMaker_LeaveGame"))
	else
		self.wndJoin:SetText(Apollo.GetString("CRB_JoinTheFight"))
	end

	-- we can be queued while in a game, so this needs to be a separate if-else block
	if bQueuedSolo then
		--self.wndJoin:SetText(Apollo.GetString("CRB_LeaveQueue"))
		--self.wndJoin:ChangeArt("CRB_Basekit:kitBtn_Metal_LargeRed")
		if bWaitingForWarParty then
			self.wndQueueInfo:FindChild("QueueStatus"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_SoloAppend"), MatchMaker_WaitingWarparty))
		else
			self.wndQueueInfo:FindChild("QueueStatus"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_SoloAppend"), Apollo.GetString("MatchMaker_InQueue")))
		end
		self.wndQueueInfo:FindChild("LeaveQueueBtn"):Show(true)
		self.wndQueueInfo:FindChild("LeaveQueueBtn"):Enable(true)
		if bQueuedGuild then
			self.wndQueueInfo:FindChild("LeaveQueueBtn"):SetText(Apollo.GetString("MatchMaker_LeaveGuildQueue"))
		else
			self.wndQueueInfo:FindChild("LeaveQueueBtn"):SetText(Apollo.GetString("MatchMaker_LeaveQueue"))
		end
		self.wndQueueInfo:FindChild("QueueStatus"):SetTextColor(kcrActiveColor)
	elseif bQueuedGroup then
		if bWaitingForWarParty then
			self.wndQueueInfo:FindChild("QueueStatus"):SetText(Apollo.GetString("Matchmaker_GroupAppend"), MatchMaker_WaitingWarparty)
		else
			self.wndQueueInfo:FindChild("QueueStatus"):SetText(String_GetWeaselString(Apollo.GetString("Matchmaker_GroupAppend"), Apollo.GetString("MatchMaker_InQueue")))
		end
		self.wndQueueInfo:FindChild("QueueStatus"):SetTextColor(kcrActiveColor)
		if MatchingGame.CanLeaveQueueAsGroup() then
			self.wndQueueInfo:FindChild("LeaveQueueBtn"):Show(true)
			self.wndQueueInfo:FindChild("LeaveQueueBtn"):Enable(true)
			if bQueuedGuild then
				self.wndQueueInfo:FindChild("LeaveQueueBtn"):SetText(Apollo.GetString("MatchMaker_LeaveGuildQueue"))
			else
				self.wndQueueInfo:FindChild("LeaveQueueBtn"):SetText(Apollo.GetString("MatchMaker_LeaveGroupQueue"))
			end
		end
	elseif not bInGame then
		self.wndQueueInfo:FindChild("QueueStatus"):SetText(Apollo.GetString("Matchmaker_NotQueued"))
	end

	self.wndQueueInfo:FindChild("LeaveQueueFraming"):Show(self.wndQueueInfo:FindChild("LeaveQueueBtn"):IsEnabled())

	self.wndJoin:Enable((not MatchingGame.IsQueuedAsGroup() and self.eSelectedTab ~= MatchingGame.MatchType.Arena
		and not bIsQueued and next(self.matchesSelected) ~= nil and not MatchingGame.IsRoleCheckActive()) or bInGame )
end

function MatchMaker:OnGameReady(bInProgress)
	local strMessage = Apollo.GetString("MatchMaker_Group")

	self:HelperFindMatchesQueued()

	local strFirstMatchName = next(self.matchesQueued)

	if strFirstMatchName then
		if self.eQueuedTab == MatchingGame.MatchType.Adventure then
			Sound.Play(Sound.PlayUIQueuePopsAdventure)
			strMessage = Apollo.GetString("MatchMaker_Group")
		elseif self.eQueuedTab == MatchingGame.MatchType.Dungeon then
			Sound.Play(Sound.PlayUIQueuePopsDungeon)
			strMessage = Apollo.GetString("MatchMaker_Group")
		else
			Sound.Play(Sound.PlayUIQueuePopsPvP)
			strMessage = Apollo.GetString("MatchMaker_Match")
		end
	end

	if bInProgress then
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_InProgress"), strMessage)
	end

	if strFirstMatchName and #self.matchesQueued == 1 then
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_FoundSpecific"), strFirstMatchName, strMessage)
	else
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_Found"), strMessage)
	end
	
	local bRatedMatch = 
		self.eQueuedTab == MatchingGame.MatchType.RatedArena or 
		self.eQueuedTab == MatchingGame.MatchType.RatedBattleground or 
		self.eQueuedTab == MatchingGame.MatchType.Warplot
	
	self.wndJoinGame:SetAnchorOffsets(
		self.nJoinGameLeft,
		bRatedMatch and self.nJoinGameTop or self.nJoinGameTop - self.nWarningHeight,
		self.nJoinGameRight,
		self.nJoinGameBottom
	)

	self.wndJoinGame:FindChild("Title"):SetText(strMessage)
	self.wndJoinGame:Show(true)
	self.wndJoinGame:ToFront()
end

function MatchMaker:OnJoinQueue()
	self:RefreshStatus()
	self:HelperFindMatchesQueued()

	if next(self.matchesQueued) ~= nil then
		self.eQueuedTab = self.matchesQueued[next(self.matchesQueued)]:GetType()
	end
end

function MatchMaker:OnLeaveQueue()
	self.wndConfirmRole:Show(false)
	self:RefreshStatus()
	self.matchesQueued = {}
end

function MatchMaker:OnVoteKickBegin(tPlayerInfo)
	self.wndVoteKick:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_VoteKick"), tPlayerInfo.strCharacterName))
	self.wndVoteKick:Show(true)
	self.wndVoteKick:ToFront()
end

function MatchMaker:OnVoteKickEnd()
	self.wndVoteKick:Show(false)
	self:RefreshStatus()
end

function MatchMaker:OnVoteSurrenderBegin()
	if MatchingGame.IsInPVPGame() then
		self.wndVoteSurrender:FindChild("Title"):SetText(Apollo.GetString("MatchMaker_VoteSurrender"))
	else
		self.wndVoteSurrender:FindChild("Title"):SetText(Apollo.GetString("MatchMaker_VoteDisband"))
	end
	self.wndVoteSurrender:Show(true)
	self.wndVoteSurrender:ToFront()
end

function MatchMaker:OnVoteSurrenderEnd()
	self.wndVoteSurrender:Show(false)
	self:RefreshStatus()
end

function MatchMaker:OnDuelStateChanged(eNewState, unitOpponent)
	self.wndDuelWarning:Show(false)
	if eNewState == GameLib.CodeEnumDuelState.WaitingToAccept then
		self.wndDuelRequest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_DuelPrompt"), unitOpponent:GetName()))
		self.wndDuelRequest:Show(true)
		self.wndDuelRequest:ToFront()
	else
		self.wndDuelRequest:Show(false)
	end
end

function MatchMaker:OnDuelAccepted(fCountdownTime)
	Print(String_GetWeaselString(Apollo.GetString("MatchMaker_DuelStartingTimer"), fCountdownTime))
	self.fDuelCountdown = fCountdownTime - 1
	self:StartDuelCountdownTimer()
end

function MatchMaker:OnDuelLeftArea(fTimeRemaining)
	self.wndDuelWarning:FindChild("Timer"):SetText(fTimeRemaining)
	self.wndDuelWarning:Show(true)
	self.wndDuelWarning:ToFront()
	self.fDuelWarning = fTimeRemaining - 1
	self:StartDuelWarningTimer()
end

function MatchMaker:OnDuelCancelWarning()
	self.wndDuelWarning:Show(false)
end

function MatchMaker:OnRoleCheckStarted()
	for idx, wndRoleBtn in pairs(self.tRoleCheckRoleButtons) do
		self.tRoleCheckRoleButtons[idx]:Enable(false)
	end

	local tEligibleRoles = MatchingGame.GetEligibleRoles()
	if tEligibleRoles ~= nil then
		for idx, eRole in ipairs(tEligibleRoles) do
			self.tRoleCheckRoleButtons[eRole]:Enable(true)
		end
	end

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	if tSelectedRoles ~= nil then
		for idx, eRole in ipairs(tSelectedRoles) do
			for idx, eRole in ipairs(tSelectedRoles) do
				self.tRoleCheckRoleButtons[eRole]:SetCheck(true)
			end
		end
		if #tSelectedRoles == 0 then
			-- if someone hasn't picked a role yet, they can't click accept
			self.wndConfirmRole:FindChild("AcceptButton"):Enable(false)
		end
	end

	self:RefreshStatus()
	self.wndConfirmRole:Show(true)
	self.wndConfirmRole:ToFront()
end

function MatchMaker:OnRoleCheckHidden()
	self.wndConfirmRole:Show(false)
	self:RefreshStatus()
end

function MatchMaker:OnAcceptRole()
	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	if tSelectedRoles == nil then
		return
	end

	MatchingGame.ConfirmRole()
end

function MatchMaker:OnCancelRole()
	MatchingGame.DeclineRoleCheck()
end

function MatchMaker:OnModeBtnCheck()
	self.wndModeList:Show(true)
end

function MatchMaker:OnModeBtnCheck()
	self.wndModeList:Show(false)
end

function MatchMaker:OnTeamRosterBtn(wndHandler, wndControl)

	local tTeam = wndControl:GetData()

	if tTeam ~= nil then
		-- Position
		local tScreen = Apollo.GetDisplaySize()
		local tPointer = Apollo.GetMouse()
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		local nMidpoint = (nRight - nLeft) / 2

		local tPos =
		{
			nX 			= nRight,
			nY 			= nTop,
			bDrawOnLeft = false
		}

		if nMidpoint + nLeft > (tScreen.nWidth / 2) then
			tPos.nX = nLeft
			tPos.bDrawOnLeft = true
		end

		if tTeam.eGuildType == GuildLib.GuildType_WarParty then
			if tTeam.bHasTeam == true then
				Event_FireGenericEvent("Event_ShowWarpartyInfo", tPos)
			else
				Event_FireGenericEvent("GenericEvent_RegisterWarparty", tPos)
			end
		else
			if tTeam.bHasTeam == true then
				Event_FireGenericEvent("Event_ShowArenaInfo", tTeam.eGuildType, tPos)
			else
				Event_FireGenericEvent("GenericEvent_RegisterArenaTeam", tTeam.eGuildType, tPos)
			end
		end
	end
end

function MatchMaker:OnEntryInfoCheck(wndHandler, wndControl)
	-- destroy previous
	if self.wndInfoPanel ~= nil and self.wndInfoPanel:IsShown() then
		self:OnEntryInfoUncheck()
	end

	if wndControl:GetData() == nil then
		return
	end

	local wndInfo = Apollo.LoadForm(self.xmlDoc, "MoreInfoPanel", nil, self)
	local nLeft, nTop, nRight, nBottom = wndInfo:GetAnchorOffsets()
	local nDescLeft, nDescTop, nDescRight, nDescBottom = wndInfo:FindChild("Description"):GetAnchorOffsets()
	local tPointer = Apollo.GetMouse()

	wndControl:AttachWindow(wndInfo)
	wndInfo:FindChild("Description"):SetText(wndControl:GetData())
	wndInfo:FindChild("Description"):SetHeightToContentHeight()

	local nDescLeft2, nDescTop2, nDescRight2, nDescBottom2 = wndInfo:FindChild("Description"):GetAnchorOffsets()
	nBottom = math.max(nBottom, nDescBottom2 + (nBottom - nDescBottom)) -- biggest; default or or what's used
	wndInfo:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

	nLeft, nTop, nRight, nBottom = wndInfo:GetAnchorOffsets()
	local nHalfHeight = (nBottom - nTop) / 2
	wndInfo:SetAnchorOffsets(tPointer.x + 15, tPointer.y - nHalfHeight, tPointer.x + nRight + 15, tPointer.y + nHalfHeight)

	self.wndInfoPanel = wndInfo
	wndControl:AttachWindow(wndInfo)
	wndInfo:SetData(wndControl) -- set the button to uncheck it
	wndInfo:ToFront()
	wndInfo:Show(true)
end

function MatchMaker:OnEntryInfoUncheck()
	if self.wndInfoPanel ~= nil then
		self.wndInfoPanel:Close()
		self.wndInfoPanel:Destroy()
		self.wndInfoPanel = nil
	end
end

function MatchMaker:OnMoreInfoPanelClosed(wndHandler, wndControl)
--[[	if wndControl:GetData() ~= nil then -- the linked button
		wndControl:GetData():SetCheck(false)
	end--]]
end


-----------------------------------------------------------------------------------------------
-- MatchMakerForm Functions
-----------------------------------------------------------------------------------------------

function MatchMaker:OnJoin()
	if next(self.matchesSelected) == nil then
		return
	end
	self.matchesQueued = {}

	for strMatchName, oMatch in pairs(self.matchesSelected) do
		self.matchesQueued[strMatchName] = oMatch
	end

	self.eQueuedTab = self.eSelectedTab

	MatchingGame.Queue(self.matchesSelected)
end

function MatchMaker:OnJoinAsGroup()
	if next(self.matchesSelected) == nil then
		return
	end
	self.matchesQueued = {}

	for strMatchName, oMatch in pairs(self.matchesSelected) do
		self.matchesQueued[strMatchName] = oMatch
	end

	if MatchingGame.CanQueueAsGroup() then
		MatchingGame.QueueAsGroup(self.matchesSelected)
		self.eQueuedTab = self.eSelectedTab
		return
	end
end

function MatchMaker:OnLeaveQueueBtn(wndHandler, wndControl)
	if MatchingGame.CanLeaveQueueAsGroup() then
		MatchingGame.LeaveMatchingQueueAsGroup()
	elseif 	MatchingGame.IsQueuedForMatching() then
		MatchingGame.LeaveMatchingQueue()
	end
end

function MatchMaker:OnLeaveMatchBtn(wndHandler, wndControl)
	if MatchingGame.IsInMatchingGame() then
		MatchingGame.LeaveMatchingGame()
	end
end

function MatchMaker:OnTeleportIntoMatchBtn(wndHandler, wndControl)
	if not MatchingGame.IsInMatchingInstance() then
		MatchingGame.TransferIntoMatchingGame()
	end
end

function MatchMaker:OnFindReplacementsBtn(wndHandler, wndControl)
	MatchingGame.LookForReplacements()
end

function MatchMaker:OnCancelReplacementsBtn(wndHandler, wndControl)
	MatchingGame.StopLookingForReplacements()
end

function MatchMaker:OnVoteDisbandBtn( wndHandler, wndControl, eMouseButton )
	MatchingGame.InitiateVoteToSurrender()
end

function MatchMaker:OnMatchingGameSelect(wndHandler, wndControl)
	--local parent = wnd:GetParent()
	local matchGame = wndControl:GetData()

	if matchGame:IsRandom() or matchGame:GetType() == MatchingGame.MatchType.Arena  or matchGame:GetType() == MatchingGame.MatchType.OpenArena then --If a random type match is selected, select no others
		self.matchesSelected = {}
	else --If a non random type match is selected, clear any random selections
		for strMatchName, oMatchGame in pairs(self.matchesSelected) do
			if oMatchGame:IsRandom() or oMatchGame:GetType() == MatchingGame.MatchType.Arena or oMatchGame:GetType() == MatchingGame.MatchType.Arena then
				self.matchesSelected[oMatchGame:GetName()] = nil
			end
		end
	end
	self.matchesSelected[matchGame:GetName()] = matchGame

	self:RefreshStatus()
	--self:OnMatchingGameOption(parent)
end

function MatchMaker:OnMatchingGameUnSelect(wndHandler, wndControl, eMouseButton)
	local matchGame = wndControl:GetData()

	self.matchesSelected[matchGame:GetName()] = nil
	self:RefreshStatus()
end

--[[function MatchMaker:OnMatchingGameOption(wnd, wndCtrl)
	local game = wnd:GetData()
	self.matchSelectedDesc = game
	self:RefreshStatus()
end--]]

function MatchMaker:OnPendingGameResponded(wndHandler, wndControl, bResponse)
	if not bResponse then
		self.eSelectedTab = self.eQueuedTab
		self:OnMatchMakerOn()
	else
		self:RefreshStatus()
	end
	
	self.wndJoinGame:Show(false)
end

function MatchMaker:OnVoteKickYes(wndHandler, wndControl)
	MatchingGame.CastVoteKick(true)
	self.wndVoteKick:Show(false)
end

function MatchMaker:OnVoteKickNo(wndHandler, wndControl)
	MatchingGame.CastVoteKick(false)
	self.wndVoteKick:Show(false)
end

function MatchMaker:OnVoteSurrenderYes(wndHandler, wndControl)
	MatchingGame.CastVoteSurrender(true)
	self.wndVoteSurrender:Show(false)
end

function MatchMaker:OnVoteSurrenderNo(wndHandler, wndControl)
	MatchingGame.CastVoteSurrender(false)
	self.wndVoteSurrender:Show(false)
end

function MatchMaker:OnAcceptDuel(wndHandler, wndControl)
	GameLib.AcceptDuel()
	self.wndDuelRequest:Show(false)
end

function MatchMaker:OnDeclineDuel(wndHandler, wndControl)
	GameLib.DeclineDuel()
	self.wndDuelRequest:Show(false)
end

function MatchMaker:OnSelectBattlegrounds(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.Battleground then
		return
	end

	self.matchesSelected = {}

	self.eSelectedTab = MatchingGame.MatchType.Battleground
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectArenas(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.Arena then
		return
	end
	
	self.matchesSelected = {}
	self.wndArenaTeams:FindChild("ArenaHeaderLabel"):SetText(Apollo.GetString("MatchMaker_MyArenaTeam"))
	self.eSelectedTab = MatchingGame.MatchType.Arena
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectDungeons(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.Dungeon then
		return
	end

	self.matchesSelected = {}

	self.eSelectedTab = MatchingGame.MatchType.Dungeon
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectAdventures(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.Adventure then
		return
	end

	self.matchesSelected = {}

	self.eSelectedTab = MatchingGame.MatchType.Adventure
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectShiphands(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.Shiphand then
		return
	end

	self.matchesSelected = {}

	self.eSelectedTab = MatchingGame.MatchType.Shiphand
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectWarplots(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.Warplot then
		return
	end

	self.matchesSelected = {}
	self.wndArenaTeams:FindChild("ArenaHeaderLabel"):SetText(Apollo.GetString("MatchMaker_MyWarparties"))
	self.eSelectedTab = MatchingGame.MatchType.Warplot
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectRatedBattlegrounds(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.RatedBattleground then
		return
	end

	self.matchesSelected = {}

	self.eSelectedTab = MatchingGame.MatchType.RatedBattleground
	self:OnMatchMakerOn()
end

function MatchMaker:OnSelectOpenArenas(wndHandler, wndControl)
	if self.eSelectedTab == MatchingGame.MatchType.OpenArena then
		return
	end

	self.matchesSelected = {}

	self.eSelectedTab = MatchingGame.MatchType.OpenArena
	self:OnMatchMakerOn()
end

function MatchMaker:OnOtherFilterChecked( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable(kstrConsoleDoNotFindOthers, true)
end

function MatchMaker:OnOtherFilterUnchecked( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable(kstrConsoleDoNotFindOthers, false)
end

function MatchMaker:OnAllowMercChecked( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable(kstrConsoleAllowMercFilter, true)
end

function MatchMaker:OnAllowMercUnchecked( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable(kstrConsoleAllowMercFilter, false)
end

function MatchMaker:OnAllowWarpartyChecked( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable(kstrConsoleAllowWarpartyFilter, true)
end

function MatchMaker:OnAllowWarpartyUnchecked( wndHandler, wndControl, eMouseButton )
	Apollo.SetConsoleVariable(kstrConsoleAllowWarpartyFilter, false)
end

function MatchMaker:OnTankChecked(wndHandler, wndControl)
	if wndHandler == self.tRoleCheckRoleButtons[MatchingGame.Roles.Tank] or wndHandler == self.tGroupFinderRoleButtons[MatchingGame.Roles.Tank] then
		self.tGroupFinderRoleButtons[MatchingGame.Roles.Tank]:SetCheck(true)
		self.tRoleCheckRoleButtons[MatchingGame.Roles.Tank]:SetCheck(true)
	end

	MatchingGame.SelectRole(MatchingGame.Roles.Tank, true)

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

function MatchMaker:OnTankUnchecked(wndHandler, wndControl)
	if wndHandler == self.tRoleCheckRoleButtons[MatchingGame.Roles.Tank] or wndHandler == self.tGroupFinderRoleButtons[MatchingGame.Roles.Tank] then
		self.tGroupFinderRoleButtons[MatchingGame.Roles.Tank]:SetCheck(false)
		self.tRoleCheckRoleButtons[MatchingGame.Roles.Tank]:SetCheck(false)
	end

	MatchingGame.SelectRole(MatchingGame.Roles.Tank, false)

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

function MatchMaker:OnHealerChecked(wndHandler, wndControl)
	if wndHandler == self.tRoleCheckRoleButtons[MatchingGame.Roles.Healer] or wndHandler == self.tGroupFinderRoleButtons[MatchingGame.Roles.Healer] then
		self.tGroupFinderRoleButtons[MatchingGame.Roles.Healer]:SetCheck(true)
		self.tRoleCheckRoleButtons[MatchingGame.Roles.Healer]:SetCheck(true)
	end

	MatchingGame.SelectRole(MatchingGame.Roles.Healer, true)

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

function MatchMaker:OnHealerUnchecked(wndHandler, wndControl)
	if wndHandler == self.tRoleCheckRoleButtons[MatchingGame.Roles.Healer] or wndHandler == self.tGroupFinderRoleButtons[MatchingGame.Roles.Healer] then
		self.tGroupFinderRoleButtons[MatchingGame.Roles.Healer]:SetCheck(false)
		self.tRoleCheckRoleButtons[MatchingGame.Roles.Healer]:SetCheck(false)
	end

	MatchingGame.SelectRole(MatchingGame.Roles.Healer, false)

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

function MatchMaker:OnDPSChecked(wndHandler, wndControl)
	if wndHandler == self.tRoleCheckRoleButtons[MatchingGame.Roles.DPS] or wndHandler == self.tGroupFinderRoleButtons[MatchingGame.Roles.DPS] then
		self.tGroupFinderRoleButtons[MatchingGame.Roles.DPS]:SetCheck(true)
		self.tRoleCheckRoleButtons[MatchingGame.Roles.DPS]:SetCheck(true)
	end

	MatchingGame.SelectRole(MatchingGame.Roles.DPS, true)

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

function MatchMaker:OnDPSUnchecked(wndHandler, wndControl)
	if wndHandler == self.tRoleCheckRoleButtons[MatchingGame.Roles.DPS] or wndHandler == self.tGroupFinderRoleButtons[MatchingGame.Roles.DPS] then
		self.tGroupFinderRoleButtons[MatchingGame.Roles.DPS]:SetCheck(false)
		self.tRoleCheckRoleButtons[MatchingGame.Roles.DPS]:SetCheck(false)
	end

	MatchingGame.SelectRole(MatchingGame.Roles.DPS, false)

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

-----------------------------------------------------------------------------------------------
-- PVP Functions
-----------------------------------------------------------------------------------------------

function MatchMaker:OnMatchEntered()
	self:RefreshStatus()
	self.wndMain:Show(false)
end

function MatchMaker:GetTimeString(fTimeInSeconds)
	local nMinutes = math.floor(fTimeInSeconds / 60)
	local nSeconds = math.floor(fTimeInSeconds % 60)
	if nSeconds < 10 then
		return nMinutes .. ":0" .. nSeconds
	end

	return nMinutes .. ":" .. nSeconds
end

--[[
function MatchMaker:StartMatchTimer()
	Apollo.CreateTimer("MatchTimer", 1.0, true)
	Apollo.StartTimer("MatchTimer")
end

function MatchMaker:OnMatchTimer()
	self.fTimeRemaining = self.fTimeRemaining - 1
end
--]]

function MatchMaker:OnMatchExited()
	self:RefreshStatus()
	self.wndMain:Show(false)
end

function MatchMaker:StartQueueTimer()
	Apollo.CreateTimer("QueueTimer", 1.0, true)
	Apollo.StartTimer("QueueTimer")
end

function MatchMaker:OnQueueTimer()
	self.fTimeInQueue = self.fTimeInQueue + 1
	self.wndTimeInQueue:SetText(self:GetTimeString(self.fTimeInQueue))

	local nAverageWaitTime = MatchingGame.GetAverageWaitTime()
	local strWaitText = nAverageWaitTime == 0 and Apollo.GetString("MatchMaker_UnknownTimer") or self:GetTimeString(nAverageWaitTime)
	local strTooltip = string.format(
		"%s %s\n%s %s",
		Apollo.GetString("MatchMaker_TimeLabel"),
		self:GetTimeString(self.fTimeInQueue),
		Apollo.GetString("MatchMaker_WaitTimeLabel"),
		strWaitText
	)

	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_GroupFinder"), {true, strTooltip})
end

function MatchMaker:OnTogglePvp()
	GameLib.TogglePvpFlags()
end

function MatchMaker:SetFlagToggleButton()
	if self.wndFlagToggle == nil then
		return
	end

	Apollo.StopTimer("CooldownTimer")
	local wndTxt = self.wndFlagInfo:FindChild("PvPStatus")

	local tFlagInfo = GameLib.GetPvpFlagInfo()
	if tFlagInfo.bIsFlagged then
		self.fCooldownTime = tFlagInfo.nCooldown
		if tFlagInfo.bIsForced then
			if GameLib.GetCurrentZonePvpRules() == GameLib.CodeEnumZonePvpRules.Sanctuary and GameLib.IsPvpServer() ~= true then
				wndTxt:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOff")))
			else
				wndTxt:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOn")))
			end

			wndTxt:SetTextColor(kcrInactiveColor)
			self.wndFlagToggle:SetText(Apollo.GetString("Matchmaker_Locked"))
		elseif tFlagInfo.nCooldown > 0 then
			local strFlagTimer = String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOn"))
			wndTxt:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_FlagTimeRemaining"), strFlagTimer, self:GetTimeString(self.fCooldownTime)))
			wndTxt:SetTextColor(kcrActiveColor)
			self.wndFlagToggle:SetText(Apollo.GetString("CRB_Cancel"))
			Apollo.CreateTimer("CooldownTimer", 1.0, true)
			Apollo.StartTimer("CooldownTimer")
		else
			wndTxt:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOn")))
			wndTxt:SetTextColor(kcrActiveColor)
			self.wndFlagToggle:SetText(Apollo.GetString("MatchMaker_TurnPvPOff"))
		end
	elseif tFlagInfo.bIsForced then
		wndTxt:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOff")))
		wndTxt:SetTextColor(kcrInactiveColor)
		self.wndFlagToggle:SetText(Apollo.GetString("Matchmaker_Locked"))
	else
		wndTxt:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOff")))
		wndTxt:SetTextColor(kcrInactiveColor)
		self.wndFlagToggle:SetText(Apollo.GetString("MatchMaker_TurnPvPOn"))
	end

	self.wndFlagToggle:Enable(not tFlagInfo.bIsForced)

	-- disabling for combat
	if self.bInCombat == true then
		self.wndFlagToggle:Enable(false)
		self.wndFlagToggle:SetText(Apollo.GetString("MatchMaker_PvPCombatLocked"))
	end
end

function MatchMaker:OnUnitPvpFlagsChanged(unitChanged)
	if not unitChanged:IsThePlayer() then
		return
	end

	self:SetFlagToggleButton()
end

function MatchMaker:OnCooldownTimer()
	if self.wndFlagToggle == nil or not self.wndFlagToggle:IsShown() then
		return
	end

	self.fCooldownTime = self.fCooldownTime - 1

	local strFlagTimer = String_GetWeaselString(Apollo.GetString("MatchMaker_PvPFlag"), Apollo.GetString("MatchMaker_FlagOn"))
	self.wndFlagInfo:FindChild("PvPStatus"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_FlagTimeRemaining"), strFlagTimer, self:GetTimeString(self.fCooldownTime)))
	self.wndFlagInfo:FindChild("PvPStatus"):SetTextColor(kcrActiveColor)

	if self.bInCombat == true then
		self.wndFlagToggle:SetText(Apollo.GetString("MatchMaker_PvPCombatLocked"))
	else
		self.wndFlagToggle:SetText(Apollo.GetString("CRB_Cancel"))
	end

	if self.fCooldownTime <= 0 then
		Apollo.StopTimer("CooldownTimer")
	end
end

function MatchMaker:StartDuelCountdownTimer()
	Apollo.CreateTimer("DuelCountdownTimer", 1.0, false)
	Apollo.StartTimer("DuelCountdownTimer")
end

function MatchMaker:OnDuelCountdownTimer()
	if self.fDuelCountdown <= 0 then
		Print(Apollo.GetString("Matchmaker_DuelBegin"))
	else
		Print(self.fDuelCountdown .. "...")
		self.fDuelCountdown = self.fDuelCountdown - 1;
		Apollo.StartTimer("DuelCountdownTimer")
	end
end

function MatchMaker:StartDuelWarningTimer()
	Apollo.CreateTimer("DuelWarningTimer", 1.0, false)
	Apollo.StartTimer("DuelWarningTimer")
end

function MatchMaker:OnDuelWarningTimer()
	if self.fDuelWarning <= 0 then
		self.wndDuelWarning:Show(false)
	else
		self.wndDuelWarning:FindChild("Timer"):SetText(self.fDuelWarning)
		self.fDuelWarning = self.fDuelWarning - 1;
		Apollo.StartTimer("DuelWarningTimer")
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------

function MatchMaker:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor ~= GameLib.CodeEnumTutorialAnchor.GroupFinder or not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local tRect = {}
	tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
	Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
end

---------------------------------------------------------------------------------------------------

function MatchMaker:DisplayPendingInfo()
	if self.wndJoinGame:IsShown() then
		return
	end

	local tPendingInfo = MatchingGame.GetPendingInfo()

	if tPendingInfo.nPendingEnemies and tPendingInfo.nPendingEnemies > 0 then
		self.wndAllyEnemyConfirm:FindChild("AllyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedAllies, tPendingInfo.nPendingAllies))
		self.wndAllyEnemyConfirm:FindChild("EnemyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedEnemies, tPendingInfo.nPendingEnemies))
		self.wndAllyEnemyConfirm:Invoke()
	elseif tPendingInfo.nPendingAllies and tPendingInfo.nPendingAllies > 0 then
		self.wndAllyConfirm:FindChild("AllyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedAllies, tPendingInfo.nPendingAllies))
		self.wndAllyConfirm:Invoke()
	else
		self.wndAllyConfirm:Show(false)
		self.wndAllyEnemyConfirm:Show(false)
	end
end

function MatchMaker:OnCheckRating(strCommand, strRatingType)
	strRatingType = Apollo.StringToLower(strRatingType)
	local tRating = nil

	if strRatingType == Apollo.GetString("ArenaRoster_2v2") then
		tRating = MatchingGame.GetPvpRating(MatchingGame.RatingType.Arena2v2)
	elseif strRatingType == Apollo.GetString("ArenaRoster_3v3") then
		tRating = MatchingGame.GetPvpRating(MatchingGame.RatingType.Arena3v3)
	elseif strRatingType == Apollo.GetString("ArenaRoster_5v5") then
		local tRating = MatchingGame.GetPvpRating(MatchingGame.RatingType.Arena5v5)
	elseif strRatingType == Apollo.GetString("MatchMaker_Battleground") then
		local tRating = MatchingGame.GetPvpRating(MatchingGame.RatingType.RatedBattleground)
	end

	if tRating ~= nil then
		Print(String_GetWeaselString(Apollo.GetString("Matchmaker_PersonalArenaRating"), strRatingType, tRating.nRating))
	end
end

function MatchMaker:HelperFindMatchesQueued()
	if next(self.matchesQueued) == nil then -- queued, but we don't know what for
		local tAllTypes =
		{
			MatchingGame.MatchType.Battleground,
			MatchingGame.MatchType.Arena,
			MatchingGame.MatchType.Dungeon,
			MatchingGame.MatchType.Adventure,
			MatchingGame.MatchType.Warplot,
			MatchingGame.MatchType.RatedBattleground,
			MatchingGame.MatchType.OpenArena
		}

		for key, nType in pairs(tAllTypes) do
			local tGames = MatchingGame.GetAvailableMatchingGames(nType)
			for key, matchGame in pairs(tGames) do
				if matchGame:IsQueued() == true then
					self.matchesQueued[matchGame:GetName()] = matchGame
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- MatchMaker Instance
-----------------------------------------------------------------------------------------------
local MatchMakerInst = MatchMaker:new()
MatchMakerInst:Init()
t$����ܯ>K~��B��,�v�{p�s=t�׿��X���w��G����N���ƮE�?Ħ\g*s3���|}uy���{ע��g�z�MYN9z1R�^����h�Ri)HK�*�|'�u�iI�O��Q�q�V��v�P(G�3���kr��/s���4�;�����ߝ2�Tn,��h���u]�<��r7cFX���J�����������>�p���[1������lٿ���]p�����♦��vv.F�F�v��j�-ƕҿ�4e����]��Δｭ�
2��].�-����nM�q�VȐ�M�:V�ɹba_�s�;�����~뭫A�������|��Ϟ9�_�lC����|��R6[��'�c�����W*��~�y�^�R�����q$�Q�%��*߇�rvt;qu><�8�`��*����[���-���'��NE��$5�o����byM^����r�O���t?u=�:�܋�4���<���|�Z�5�T���6���U��|�s�[�tK/j�5��*�'��Vs̓v ��/����K��ߏ��m��w[�Y2��'@�Z��'�S򼀃�?��/������
���p�'�?q���U~�N_�#�租S������U�����=Q?�`=�Y�����5��^}���+�|[_���#�!��+K�a=�ވrL��l��q�.��Z�FO�W�z/1[��Vw�<���ύ����p:�8b��q�<(_(亘���?����;������+�;��'J�Բ�U1����#���^���777�E������V���3K=Z(��H�A�n�$����R����t͔�sh�U�;}u����[\5d���;X�p}�#�LF��NMM��qѥ�B�@H������^�[�^O,�E�/l
i�uW��A�����Wƭ���N """⟞2��b$IK������r,q�ҏ��mJ����nY�~����T*���p�#�R￟�Ǘ�����8�C忺����~��X�v�#9C�7������
�x��6h�&V�
����}��Z�^_�6����#���g�ʸ�YZ�����hy&��s�.F�N�!�ӎӜJ&d��p�s�+I�70jϳ¢�?���⹤׵RZ=~�[V� �[��r�����X܍�R ���%�7k���/��4�xE���e���8�KlK��\�g�q��&z�N�����i{o����-�/^ϫ���?������W=���D���X�YH'���w����dD�Gu��|.z��򵌉�ĕ`���@�0��g��:���{е2.]mM�ɋ���O'Zjw��{_���A�]=��W�qIiy��5m�1�q)����[-�s����9���yX~/�~<P���z����Z;��ͤ�B�m�-�I{{�`��״z�����~��I{()��U�����d��*����R;v���nZ^RW���4u9c(ݔ�&!���R��]3˺|`���o�:!��jn���7""""�i+��/��L��\���/���w�[񯾪׷��Xѭ��\@��K��OƗ�����RK�	���E|���8���f�b4>��>�E�	�kQ?�\������R��n�o�+�E����Z+�/��}y�r����Ow�C�j�Og9��I�g;^ovd{�x^<�*�e�D9n�/}-�<�^p�w��Q'D�)K��R�,����G�ퟔG�* ���<�(��Ϛs�y�y=n[�H�Ov]W��D2�Jْ�_W��o�Q���_��y���+U ����/���zS=��?0���^��/����W~Vi��R��������Y��;w�~���,L'��L$��K�71��������]Y�\o[��u�y\ZYt�ͦ�]���oeI�O^��`�s�|�]:�x7.�Tܕq7K�ץܯ����9�R��x,k0�����q�������z�I�����I�n��y;�ﭥ�c�+�;u�������;(��T˓�J7w�c\Ժ9��]�ou�!��㏬���;���߾��w~W?������S�jI��;_��D�W�yP��{�������<ʤ﷛;����$y_r���V�W6"��3Mː���Е��l6�oK�ڛj���|��t8=�㈫�ٍގ������n��yW�e��D�N��8t���¤�#������?�A�������R��yC�7�(�9
���I�t���E�+��qRa?����<�B�����~G�s���0�߬���/#�z}���'g�h����0>}=ѻ�Y��-�|�]����
7���=�x0����ϯ�����N;���?�~�z~��[-�>��C/��~Y�W�O(��ﺓ֫Vc��ߵF���9�J��o��H�Q�z���