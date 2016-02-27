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
require "Episode"
require "Achievement"
require "AchievementsLib"
require "QuestLib"
require "QuestHub"
require "ContentFinderLib"

-----------------------------------------------------------------------------------------------
-- MatchMaker Module Definition
-----------------------------------------------------------------------------------------------
local MatchMaker = {}

local kstrConsoleAllowMercFilter	 	= "matching.mercenaryAllowed"
local kstrConsoleAllowWarpartyFilter 	= "matching.warpartyAllowed"
local kstrConsoleDoNotFindOthers		= "matching.doNotFindOthers"
local knRandomMatchIndex = 0
local knQuestTabId = -1

local ktItemQualityColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

local ktTypeNames = 
{
	[knQuestTabId]								= Apollo.GetString("CRB_Quests"),
	[MatchingGame.MatchType.Shiphand] 			= Apollo.GetString("MatchMaker_Shiphands"),
	[MatchingGame.MatchType.Adventure] 			= Apollo.GetString("MatchMaker_Adventures"),
	[MatchingGame.MatchType.Dungeon] 			= Apollo.GetString("CRB_Dungeons"),
	[MatchingGame.MatchType.Battleground]		= Apollo.GetString("MatchMaker_Battlegrounds"),
	[MatchingGame.MatchType.RatedBattleground] 	= Apollo.GetString("MatchMaker_Battlegrounds"),
	[MatchingGame.MatchType.Warplot] 			= Apollo.GetString("MatchMaker_Warplots"),
	[MatchingGame.MatchType.OpenArena] 			= Apollo.GetString("MatchMaker_Arenas"),
	[MatchingGame.MatchType.Arena] 				= Apollo.GetString("MatchMaker_Arenas"),
	[MatchingGame.MatchType.WorldStory]			= Apollo.GetString("QuestLog_WorldStory"),
}

-- Match Types need to correspond to ktPvPTypes and ktPvETypes (excluding quests)
local ktTypeIntros = 
{
	[MatchingGame.MatchType.Shiphand] 		= { 
		strBackground = "matchmaker:Matchmaker_BG_Expeditions",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Expeditions_GroupSize")), 
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_AvgDuration"), Apollo.GetString("MatchMaker_Expeditions_AvgDuration")),
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_RecVetILevel"), Apollo.GetString("MatchMaker_Expeditions_RecVetILevel")),
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Expeditions_Desc1"), 
			Apollo.GetString("MatchMaker_Expeditions_Desc2"), 
		},
	},
	[MatchingGame.MatchType.Adventure] 		= { 
		strBackground = "matchmaker:Matchmaker_BG_Adventures",	
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Adventures_GroupSize")), 
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_AvgDuration"), Apollo.GetString("MatchMaker_Adventures_AvgDuration")),
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_RecVetILevel"), Apollo.GetString("MatchMaker_Adventures_RecVetILevel")),
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Adventures_Desc1"), 
			Apollo.GetString("MatchMaker_Adventures_Desc2"), 
		},
	},
	[MatchingGame.MatchType.Dungeon] 		= { 
		strBackground = "matchmaker:Matchmaker_BG_Dungeons",	
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Dungeons_GroupSize")), 
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_AvgDuration"), Apollo.GetString("MatchMaker_Dungeons_AvgDuration")),
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_RecVetILevel"), Apollo.GetString("MatchMaker_Dungeons_RecVetILevel")),
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Dungeons_Desc1"), 
			Apollo.GetString("MatchMaker_Dungeons_Desc2"), 
		},
	},
	[MatchingGame.MatchType.WorldStory]		 = { 
		strBackground = "matchmaker:Matchmaker_BG_WorldStory",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_WorldStory_GroupSize")), 
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_AvgDuration"), Apollo.GetString("MatchMaker_WorldStory_AvgDuration")),
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_WorldStory_Desc1"), 
			Apollo.GetString("MatchMaker_WorldStory_Desc2"), 
		},
	},
	[MatchingGame.MatchType.Battleground] 	 = { 
		strBackground = "matchmaker:Matchmaker_BG_Battlegrounds",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Battlegrounds_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Battlegrounds_Desc1"), 
			Apollo.GetString("MatchMaker_Battlegrounds_Desc2"), 
		},
	},
	[MatchingGame.MatchType.Warplot] 		 = { 
		strBackground = "matchmaker:Matchmaker_BG_Warplots",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Warplots_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Warplots_Desc1"), 
			Apollo.GetString("MatchMaker_Warplots_Desc2"), 
		},
	},
	[MatchingGame.MatchType.OpenArena]  	= { 
		strBackground = "matchmaker:Matchmaker_BG_Arenas",	
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Arenas_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Arenas_Desc1"), 
			Apollo.GetString("MatchMaker_Arenas_Desc2"), 
		},
	},	
}


-- Numbers indicate sort order for tabs.  1 is quest
local ktPvETypes =
{
	[knQuestTabId]								= 1,
	[MatchingGame.MatchType.Shiphand] 			= 2,
	[MatchingGame.MatchType.Adventure] 			= 3,
	[MatchingGame.MatchType.Dungeon] 			= 4,
	[MatchingGame.MatchType.WorldStory]			= 5,
}

-- Numbers indicate sort order for tabs
local ktPvPTypes = 
{
	[MatchingGame.MatchType.Battleground]		= 1,
	[MatchingGame.MatchType.Warplot] 			= 2,
	[MatchingGame.MatchType.OpenArena] 			= 3,
}

local ktRatedPvPTypes =
{
	[MatchingGame.MatchType.RatedBattleground] 	= true,
	[MatchingGame.MatchType.Warplot] 			= true,
	[MatchingGame.MatchType.Arena] 				= true,
}

local ktRatedToNormal =
{
	[MatchingGame.MatchType.RatedBattleground] 	= MatchingGame.MatchType.Battleground,
	[MatchingGame.MatchType.Arena]				= MatchingGame.MatchType.OpenArena,
}

local ktPvPGuildRequired =
{
	[MatchingGame.MatchType.Arena] 				= true,
	[MatchingGame.MatchType.Warplot] 			= true,
}

local ktPvPGuildToTeamSize =
{
	[2]		= GuildLib.GuildType_ArenaTeam_2v2,
	[3] 	= GuildLib.GuildType_ArenaTeam_3v3,
	[5] 	= GuildLib.GuildType_ArenaTeam_5v5,
	[30] 	= GuildLib.GuildType_WarParty,
}

local ktEpisodeStateColors = 
{
	[Episode.EpisodeState_Unknown] 		= "UI_TextHoloBodyCyan",
	[Episode.EpisodeState_Mentioned] 	= "UI_TextHoloBody",
	[Episode.EpisodeState_Active] 		= "UI_TextHoloBody",
	[Episode.EpisodeState_Complete] 	= "UI_BtnTextGreenNormal",
}

local ktPvPRatingTypes =
{
	[MatchingGame.MatchType.Arena] =
	{
		[2] = MatchingGame.RatingType.Arena2v2,
		[3] = MatchingGame.RatingType.Arena3v3,
		[5] = MatchingGame.RatingType.Arena5v5,
	},
	
	[MatchingGame.MatchType.RatedBattleground] 		= MatchingGame.RatingType.RatedBattleground,
	[MatchingGame.MatchType.Warplot] 				= MatchingGame.RatingType.Warplot,
}

local ktLevelUpUnlockToMatchTypes =
{
	[GameLib.LevelUpUnlockType.Dungeon_New] 		= MatchingGame.MatchType.Dungeon,
	[GameLib.LevelUpUnlockType.Adventure_New] 		= MatchingGame.MatchType.Adventure,
	[GameLib.LevelUpUnlockType.Shiphand_New] 		= MatchingGame.MatchType.Shiphand,
	[GameLib.LevelUpUnlockType.PvP_Battleground] 	= MatchingGame.MatchType.RatedBattleground,
}

local keMasterTabs =
{
	["Suggested"] 	= 1,
	["PvE"]			= 2,
	["PvP"]			= 3,
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MatchMaker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here
	o.fTimeRemaining 	= 0
	o.fTimeInQueue 		= 0
	o.fCooldownTime 	= 0
	o.fDuelCountdown	= 0
	o.fDuelWarning		= 0

    return o
end

function MatchMaker:Init()
    Apollo.RegisterAddon(self)
end

function MatchMaker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MatchMaker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MatchMaker:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	-- Startup/Init
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 			"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("ToggleGroupFinder", 					"OnToggleMatchMaker", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	-- Match Queue
	Apollo.RegisterEventHandler("MatchingJoinQueue", 					"OnJoinQueue", self)
	Apollo.RegisterEventHandler("MatchingLeaveQueue", 					"OnLeaveQueue", self)
	Apollo.RegisterEventHandler("MatchingGameReady", 					"OnGameReady", self)
	Apollo.RegisterEventHandler("MatchingGamePendingUpdate", 			"DisplayPendingInfo", self)
	Apollo.RegisterEventHandler("MatchingCancelPendingGame",			"PendingGameCanceled", self)
	Apollo.RegisterEventHandler("MatchEntered", 						"OnMatchEntered", self)
	Apollo.RegisterEventHandler("MatchExited", 							"CleanUpAll", self)
	Apollo.RegisterEventHandler("MatchingEligibilityChanged", 			"RecalculateContents", self)
	Apollo.RegisterEventHandler("MatchLookingForReplacements",			"UpdateInMatchControls", self)
	Apollo.RegisterEventHandler("MatchStoppedLookingForReplacements", 	"UpdateInMatchControls", self)
	Apollo.RegisterEventHandler("MatchLeft", 							"UpdateInMatchControls", self)
	Apollo.RegisterEventHandler("UnitLevelChanged",						"OnUnitLevelChanged", self)
	
	self.timerQueue = ApolloTimer.Create(1.0, true, "OnQueueTimer", self)
	self.timerQueue:Stop()
	
	-- Role Check
	Apollo.RegisterEventHandler("MatchingRoleCheckStarted", 			"OnRoleCheck", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckHidden", 				"OnRoleCheckHidden", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckCanceled", 			"OnRoleCheckHidden", self)
	
	-- Voting
	Apollo.RegisterEventHandler("MatchVoteKickBegin", 					"OnVoteKickBegin", self)
	Apollo.RegisterEventHandler("MatchVoteKickEnd", 					"OnVoteKickEnd", self)
	Apollo.RegisterEventHandler("MatchVoteSurrenderBegin", 				"OnVoteSurrenderBegin", self)
	Apollo.RegisterEventHandler("MatchVoteSurrenderEnd", 				"OnVoteSurrenderEnd", self)
	
	-- Updating
	Apollo.RegisterEventHandler("GuildChange",							"OnUpdateGuilds", self)
	Apollo.RegisterEventHandler("CharacterCreated",						"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("Group_Join",							"OnUpdateGroup", self)
	Apollo.RegisterEventHandler("Group_Left",							"OnUpdateGroup", self)
	Apollo.RegisterEventHandler("ChangeWorld",							"OnClose", self)
	Apollo.RegisterEventHandler("AchievementGranted",					"UpdateAchievements", self)
	Apollo.RegisterEventHandler("PlayerLevelChange",					"OnPlayerLevelChange", self)
	
	-- Dueling
	Apollo.RegisterEventHandler("DuelStateChanged",						"OnDuelStateChanged", self)
	Apollo.RegisterEventHandler("DuelAccepted",							"OnDuelAccepted", self)
	Apollo.RegisterEventHandler("DuelLeftArea",							"OnDuelLeftArea", self)
	Apollo.RegisterEventHandler("DuelCancelWarning",					"OnDuelCancelWarning", self)

	--PremiumTierUpdates
	Apollo.RegisterEventHandler("PremiumTierChanged",					"UpdateTeamInfo", self)

	--StoreLinks
	Apollo.RegisterEventHandler("StoreLinksRefresh",					"RefreshStoreLink", self)

	-- Tutorial Anchor
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)
	
	-- Events from other addons
	Apollo.RegisterEventHandler("OpenContentFinderToUnlock",			"OnOpenContentFinderToUnlock", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_General",	"OnShowContentFinder", self)

	self.timerDuelCountdown = ApolloTimer.Create(1.0, true, "OnDuelCountdownTimer", self)
	self.timerDuelCountdown:Stop()

	self.timerDuelRangeWarning = ApolloTimer.Create(1.0, true, "OnDuelWarningTimer", self)
	self.timerDuelRangeWarning:Stop()
	
	self.timerNavPointNotification = ApolloTimer.Create(3.0, false, "HideNavPointNotification", self)
	self.timerNavPointNotification:Stop()
	
	self.tWndRefs = {}
	self.ePvETabSelected = nil
	self.ePvPTabSelected = nil
	self.arMatchesQueued = {}
	self.matchDisplayed = nil
	self.eSelectedMasterType = nil
	self.tSuggestedInfo = nil
	self.tHubList = {}
	self.tMatchList = {}
	self.arMatchesToQueue = {}

	self.tHasGuild = {}
	
	self:RefreshStoreLink()
	
	if MatchingGame.IsQueuedForMatching() or MatchingGame.IsQueuedAsGroup() or MatchingGame.IsGamePending() then
		self:OnJoinQueue()
	end
end

function MatchMaker:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CRB_ContentFinder"), nSaveVersion = 2})
end

function MatchMaker:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("CRB_ContentFinder"), {"ToggleGroupFinder", "GroupFinder", "Icon_Windows32_UI_CRB_InterfaceMenu_GroupFinder"})
end

function MatchMaker:OnToggleMatchMaker()
	if self.tWndRefs.wndMain then
		self:OnClose()
		Event_FireGenericEvent("LFGWindowHasBeenClosed")
	else
		self:OnMatchMakerOn()
	end
end

function MatchMaker:OnMatchMakerOn()
	if not self.tWndRefs.wndMain then
		self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "MatchMakerForm", nil, self)
		self.tWndRefs.wndMain:Invoke()
		self.tWndRefs.wndTeamBtn = self.tWndRefs.wndMain:FindChild("TeamBtn")
	end
	
	self:OnUpdateGuilds()
	self:BuildHubInfo()
	self:BuildMatchTable()

	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("CRB_ContentFinder")})
	
	local wndPvEList = self.tWndRefs.wndMain:FindChild("PvETab")	
	self:BuildTabs(wndPvEList, ktPvETypes)
	
	local wndPvPList = self.tWndRefs.wndMain:FindChild("PvPTab")
	self:BuildTabs(wndPvPList, ktPvPTypes)
	
	local wndHeaderBtns = self.tWndRefs.wndMain:FindChild("HeaderButtons")
	local wndSuggestedBtn = wndHeaderBtns:FindChild("SuggestedBtn")
	local wndPvEBtn = wndHeaderBtns:FindChild("PvEBtn")
	local wndPvPBtn = wndHeaderBtns:FindChild("PvPBtn")
	
	wndSuggestedBtn:SetData(keMasterTabs.Suggested)
	wndPvEBtn:SetData(keMasterTabs.PvE)
	wndPvPBtn:SetData(keMasterTabs.PvP)
	
	local nSeason = MatchingGame.GetSeasonForRatingType(MatchingGame.MatchType.Arena)
	local strLabel = Apollo.GetString("CRB_PVP")
	
	if nSeason > 0 then
		strLabel = String_GetWeaselString(Apollo.GetString("MatchMaker_PvPSeasonTitle"), nSeason)
	end
	
	wndPvPBtn:SetText(strLabel)
	
	if not self.tSuggestedInfo then
		self.tSuggestedInfo = ContentFinderLib.GetSuggestedContent()
	end
	
	if self.eSelectedMasterType == keMasterTabs.PvE then
		wndPvEBtn:SetCheck(true)
		self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
	elseif self.eSelectedMasterType == keMasterTabs.PvP then
		wndPvPBtn:SetCheck(true)
		self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
	else
		wndSuggestedBtn:SetCheck(true)
		self:OnSuggestedTabSelected(wndSuggestedBtn, wndSuggestedBtn)
	end
end

function MatchMaker:BuildTabs(wndParent, tMatchTypes)
	local nTableSize = 0
	for eMatchType, nSortOrder in pairs(tMatchTypes) do
		nTableSize = nTableSize + 1
	end
	
	local fRightAnchor = 1/nTableSize
	for eMatchType, nSortOrder in pairs(tMatchTypes) do
		local wndCurrTab = Apollo.LoadForm(self.xmlDoc, "MatchTypeButton", wndParent, self)
		wndCurrTab:SetText(ktTypeNames[eMatchType])
		wndCurrTab:SetData(eMatchType)
		wndCurrTab:SetAnchorPoints(fRightAnchor * (tMatchTypes[eMatchType] - 1), 0, fRightAnchor * tMatchTypes[eMatchType], 1)
		
		if nSortOrder == 1 then
			wndCurrTab:ChangeArt("BK3:btnMetal_TabSub_Left")
		elseif nSortOrder == nTableSize then
			wndCurrTab:ChangeArt("BK3:btnMetal_TabSub_Right")
		end
	end
end

function MatchMaker:BuildHubInfo()
	self.tHubList = {}

	local unitPlayer = GameLib.GetPlayerUnit()
	local nZoneCount = 0
	for idx, epiKnown in pairs(QuestLib.GetAllEpisodes(true, true)) do
		local hubCurrent = epiKnown:GetHub()

		if hubCurrent then
			local strZone = hubCurrent:GetWorldZoneName()
			local strHub = hubCurrent:GetSubZoneName()
			local nLevel = epiKnown:GetConLevel()
	
			if strZone and strZone ~= "" then
				if not self.tHubList[strZone] then
					self.tHubList[strZone] = 
					{
						nTotal = 0,
						nCompleted = 0,
						nMinLevel = nLevel,
						nMaxLevel = nLevel,
						strZoneName = strZone,
						tHubInfo = {},
					}
				end

				if not self.tHubList[strZone].tHubInfo[strHub] then
					self.tHubList[strZone].tHubInfo[strHub] = 
					{
						nTotal = 0,
						nCompleted = 0,
						nMinLevel = nLevel,
						nMaxLevel = nLevel,
						arEpisodes = {},
					}
				end

				if self.tHubList[strZone].nMinLevel > nLevel then
					self.tHubList[strZone].nMinLevel = nLevel
				end

				if self.tHubList[strZone].nMaxLevel < nLevel then
					self.tHubList[strZone].nMaxLevel = nLevel
				end

				if self.tHubList[strZone].tHubInfo[strHub].nMinLevel > nLevel then
					self.tHubList[strZone].tHubInfo[strHub].nMinLevel = nLevel
				end

				if self.tHubList[strZone].tHubInfo[strHub].nMaxLevel < nLevel then
					self.tHubList[strZone].tHubInfo[strHub].nMaxLevel = nLevel
				end

				local eState = epiKnown:GetState()
				if eState == Episode.EpisodeState_Complete then
					self.tHubList[strZone].nCompleted = self.tHubList[strZone].nCompleted + 1
					self.tHubList[strZone].tHubInfo[strHub].nCompleted = self.tHubList[strZone].tHubInfo[strHub].nCompleted + 1
				end

				self.tHubList[strZone].nTotal = self.tHubList[strZone].nTotal + 1
				self.tHubList[strZone].tHubInfo[strHub].nTotal = self.tHubList[strZone].tHubInfo[strHub].nTotal + 1
				
				table.insert(self.tHubList[strZone].tHubInfo[strHub].arEpisodes, epiKnown)
			end
		end
	end
end

function MatchMaker:BuildMatchTable()
	self.tMatchList = {}

	for strIndex, eMatchType in pairs(MatchingGame.MatchType) do
		local eTypeIndex = eMatchType
		if ktRatedToNormal[eMatchType] then
			eTypeIndex = ktRatedToNormal[eMatchType]
		end
		
		if not self.tMatchList[eTypeIndex] then
			self.tMatchList[eTypeIndex] = {}
		end
		
		local bUseTeamSize = eMatchType == MatchingGame.MatchType.OpenArena or eMatchType == MatchingGame.MatchType.Arena or eMatchType == MatchingGame.MatchType.Warplot
		local nPlayerLevel = GameLib.GetPlayerLevel(true)

		for idx, matchGame in pairs(MatchingGame.GetMatchingGames(eMatchType, false, true)) do			
			if not ktRatedPvPTypes[eMatchType] and not matchGame:IsVeteran() then
				-- Arenas all use the same map, so we need to index them by team size
				local nIndex = matchGame:GetGameId()
				if bUseTeamSize then
					nIndex = matchGame:GetTeamSize()
				end
				
				local nLevelDiff = nPlayerLevel - matchGame:GetMinLevel()
				
				if nPlayerLevel <= matchGame:GetMaxLevel() then
					if not self.tMatchList[eTypeIndex][nIndex] then
						self.tMatchList[eTypeIndex][nIndex] = {}
					end
					
					if not self.tMatchList[eTypeIndex][nIndex].matchNormal then
						self.tMatchList[eTypeIndex][nIndex].matchNormal = matchGame
					elseif nLevelDiff >= 0 and nLevelDiff < nPlayerLevel - self.tMatchList[eTypeIndex][nIndex].matchNormal:GetMinLevel() then
						self.tMatchList[eTypeIndex][nIndex].matchNormal = matchGame
					end
				end
			end
		end

		local arVeteranGames = MatchingGame.GetMatchingGames(eMatchType, not ktRatedPvPTypes[eMatchType], true)
		for idx, matchVet in pairs(arVeteranGames) do
			local nIndex = matchVet:GetGameId()
			if bUseTeamSize then
				nIndex = matchVet:GetTeamSize()
			end
				
			local tMatchInfo = self.tMatchList[eTypeIndex][nIndex]
			if tMatchInfo then
				tMatchInfo.matchVet = matchVet
			else
				self.tMatchList[eTypeIndex][nIndex] = {matchVet = matchVet}
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Tab Selection
-----------------------------------------------------------------------------------------------

function MatchMaker:OnPvETabSelected(wndHandler, wndControl)
	local wndPvETab = self.tWndRefs.wndMain:FindChild("PvETab")
	
	self.eSelectedMasterType = wndHandler:GetData()
	
	wndPvETab:Show(true)
	self.tWndRefs.wndMain:FindChild("PvPTab"):Show(false)
	self.tWndRefs.wndMain:FindChild("SummaryTab"):Show(false)
	
	self.tWndRefs.wndMain:FindChild("TabContent"):Show(true)

	self.tWndRefs.wndMain:FindChild("BGArt"):SetWindowTemplate("Metal_Primary_Nav_SubNav")

	if self.ePvETabSelected and self.ePvETabSelected ~= knQuestTabId then
		local wndSelectedTab = wndPvETab:FindChildByUserData(self.ePvETabSelected)
		wndPvETab:SetRadioSelButton("MatchMakerPvETabGroup", wndSelectedTab)
		
		self:BuildMatchList(wndSelectedTab, wndSelectedTab)
	else
		wndPvETab:SetRadioSelButton("MatchMakerPvETabGroup", wndPvETab:FindChildByUserData(knQuestTabId))
		
		self:BuildQuestList()
		if self.tSuggestedInfo.tQuestInfo and self.tSuggestedInfo.tQuestInfo.hubSuggested then
			self:SetQuestTabContent(self.tHubList[self.tSuggestedInfo.tQuestInfo.hubSuggested:GetWorldZoneName()])
		end
	end
end

function MatchMaker:OnPvPTabSelected(wndHandler, wndControl)
	local wndPvPTab = self.tWndRefs.wndMain:FindChild("PvPTab")

	self.eSelectedMasterType = wndHandler:GetData()
	
	wndPvPTab:Show(true)
	self.tWndRefs.wndMain:FindChild("PvETab"):Show(false)
	self.tWndRefs.wndMain:FindChild("SummaryTab"):Show(false)
	
	self.tWndRefs.wndMain:FindChild("TabContent"):Show(true)
	self.tWndRefs.wndMain:FindChild("BGArt"):SetWindowTemplate("Metal_Primary_Nav_SubNav")
	
	local eSelectedTab = MatchingGame.MatchType.Battleground
	
	if self.ePvPTabSelected then
		eSelectedTab = self.ePvPTabSelected
	end
	
	local wndSelectedTab = wndPvPTab:FindChildByUserData(eSelectedTab)
	wndPvPTab:SetRadioSelButton("MatchMakerPvETabGroup", wndSelectedTab)
	
	self:BuildMatchList(wndSelectedTab, wndSelectedTab)
end

function MatchMaker:OnSuggestedTabSelected(wndHandler, wndControl)
	local wndSummaryTab = self.tWndRefs.wndMain:FindChild("SummaryTab")
	self.tWndRefs.wndMain:FindChild("PvETab"):Show(false)
	self.tWndRefs.wndMain:FindChild("PvPTab"):Show(false)
	wndSummaryTab:Show(true)
	
	self.tWndRefs.wndMain:FindChild("TabContent"):Show(false)
	
	self.eSelectedMasterType = wndHandler:GetData()
	
	local wndContent = wndSummaryTab:FindChild("Content")
	local wndContainer = wndContent:FindChild("ContentContainer")
	wndContainer:DestroyChildren()
	
	self.tWndRefs.wndMain:FindChild("BGArt"):SetWindowTemplate("Metal_Primary_Nav")
	
	if self.tSuggestedInfo.matchPvE then
		self:BuildSuggestedMatch(self.tSuggestedInfo.matchPvE)
	end
	
	if self.tSuggestedInfo.tQuestInfo then
		self:BuildSuggestedQuest(self.tSuggestedInfo.tQuestInfo)
	end
	
	if self.tSuggestedInfo.matchPvP then
		self:BuildSuggestedMatch(self.tSuggestedInfo.matchPvP)
	end
	
	local strText = ""
	if #wndContainer:GetChildren() <= 0 then
		strText = Apollo.GetString("Matching_NoContentFound")
		self.tWndRefs.wndMain:FindChild("HeaderButtons:PvEBtn"):Enable(false)
		self.tWndRefs.wndMain:FindChild("HeaderButtons:PvPBtn"):Enable(false)
	end
	
	wndContainer:SetText(strText)
	wndContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	
	self:UpdateInMatchControls()
end

function MatchMaker:UpdateInMatchControls()
	if not self.tWndRefs.wndMain then
		return
	end
	
	local wndSummaryTab = self.tWndRefs.wndMain:FindChild("SummaryTab")
	local wndContent = wndSummaryTab:FindChild("Content")
	
	local nLeft, nTop, nRight, nBottom = wndContent:GetOriginalLocation():GetOffsets()
	
	local wndOptions = wndSummaryTab:FindChild("InstanceOptions")

	if MatchingGame.IsInMatchingGame() then
		local matchInstance = MatchingGame.GetCurrentMatchingGame()
		wndOptions:Show(true)
		wndOptions:FindChild("InstanceTitle"):SetText(matchInstance:GetName())
		
		wndOptions:FindChild("VoteDisband"):Enable(MatchingGame.CanVoteSurrender())
		wndOptions:FindChild("FindReplacements"):Enable(MatchingGame.CanLookForReplacements())
		wndOptions:FindChild("CancelReplacements"):Enable(GroupLib.AmILeader())
		wndOptions:FindChild("TeleportToInstance"):Enable(not MatchingGame.IsInMatchingInstance())
		
		local bIsLookingForReplacements = MatchingGame.IsLookingForReplacements()
		wndOptions:FindChild("FindReplacements"):Show(not bIsLookingForReplacements)
		wndOptions:FindChild("CancelReplacements"):Show(bIsLookingForReplacements)
		
		nTop = nTop + wndOptions:GetHeight()
	else
		wndOptions:Show(false)
	end
	
	wndContent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

-----------------------------------------------------------------------------------------------
-- Setting up Arena Controls
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildArenaControls()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(true)
	
	self.ePvPTabSelected = MatchingGame.MatchType.OpenArena
	
	local wndContent = self.tWndRefs.wndMain:FindChild("MatchContent")
	local wndControls = wndContent:FindChild("Controls")
	
	local wndSettings = wndControls:FindChild("PvESettings")
	local nLeft, nTop, nRight, nBottom = wndSettings:GetOriginalLocation():GetOffsets()
	wndSettings:SetAnchorOffsets(nLeft, nBottom, nRight, nBottom)
	
	local wndContainer = wndControls:FindChild("MasterList")
	local nListLeft, nListTop, nListRight, nListBottom = wndContainer:GetOriginalLocation():GetOffsets()
	wndContainer:SetAnchorOffsets(nListLeft, nListTop, nListRight, nBottom)
	
	wndContainer:DestroyChildren()
	
	local wndArenaList = Apollo.LoadForm(self.xmlDoc, "ArenaEntry", wndContainer, self)
	
	-- Set up Open Arenas
	local wndOpenArenas = wndArenaList:FindChild("OpenArenas")
	local tOpenArenaWindows =
	{
		[2] = wndOpenArenas:FindChild("2v2"),
		[3] = wndOpenArenas:FindChild("3v3"),
		[5] = wndOpenArenas:FindChild("5v5"),
	}
	
	local nPlayerLevel = GameLib.GetPlayerLevel(true)
	for nTeamSize, wndArena in pairs(tOpenArenaWindows) do	
		if self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchNormal then
			wndArena:SetData(self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchNormal)
			wndArena:FindChild("MatchSelection"):SetData(self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchNormal)
			wndArena:FindChild("MatchSelection"):Enable(self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchNormal:GetMinLevel() <= nPlayerLevel)
		else
			wndArena:FindChild("MatchSelection"):Enable(false)
		end
	end
	
	-- Set up Rated Arenas
	local wndRatedArenas = wndArenaList:FindChild("RatedArenas")
	local tRatedArenas =
	{
		[2] = wndRatedArenas:FindChild("2v2"),
		[3] = wndRatedArenas:FindChild("3v3"),
		[5] = wndRatedArenas:FindChild("5v5"),
	}
	
	for nTeamSize, wndRated in pairs(tRatedArenas) do
		if self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchVet then
			wndRated:SetData(self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchVet)
			wndRated:FindChild("MatchSelection"):SetData(self.tMatchList[MatchingGame.MatchType.OpenArena][nTeamSize].matchVet)
	
			local guildArenaTeam = self.tHasGuild[ktPvPGuildToTeamSize[nTeamSize]]
			if guildArenaTeam then
				wndRated:FindChild("MatchSelection"):Enable(true)
				wndRated:FindChild("MatchSelection"):SetTooltip("")
				wndRated:FindChild("TeamName"):Show(true)
				wndRated:FindChild("TeamName"):SetTextRaw(String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), guildArenaTeam:GetName()))
				wndRated:FindChild("Rating"):Show(true)
				wndRated:FindChild("Rating"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_Rating"), guildArenaTeam:GetPvpRatings().nRating))
			else
				wndRated:FindChild("MatchSelection"):Enable(false)
				wndRated:FindChild("MatchSelection"):SetTooltip(Apollo.GetString("MatchMaker_RatedArenaTeamReq"))
				wndRated:FindChild("TeamName"):Show(false)
				wndRated:FindChild("Rating"):Show(false)
			end
		end
	end
	
	local nIndex = nil
	
	for idx, tMatchInfo in pairs(tRatedArenas) do
		if not nIndex or nIndex > idx then
			nIndex = idx
		end
	end
	
	local matchDisplayed = self.tMatchList[MatchingGame.MatchType.OpenArena][nIndex].matchNormal
	
	if self.matchDisplayed then
		local eMatchType = self.matchDisplayed:GetType()
	
		if eMatchType == MatchingGame.MatchType.OpenArena or eMatchType == MatchingGame.MatchType.Arena then
			matchDisplayed = self.matchDisplayed
		end
	end
	
	wndControls:FindChild("MasterList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	self:ResizeBlocker()
	self:ValidateQueueButtons()
end

-----------------------------------------------------------------------------------------------
-- Setting up Warplot Controls
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildWarplotControls()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(true)
	
	local wndContent = self.tWndRefs.wndMain:FindChild("MatchContent")
	local wndControls = wndContent:FindChild("Controls")
	local matchWarplot = nil
	local nTeamSize = 0
	
	self.ePvPTabSelected = MatchingGame.MatchType.Warplot
	
	-- There should only be one
	for idx, tMatchInfo in pairs (self.tMatchList[MatchingGame.MatchType.Warplot]) do
		matchWarplot = tMatchInfo.matchVet
		nTeamSize = idx
	end
	
	self.arMatchesToQueue = {matchWarplot}
	
	local wndSettings = wndControls:FindChild("PvESettings")
	local nLeft, nTop, nRight, nBottom = wndSettings:GetOriginalLocation():GetOffsets()
	wndSettings:SetAnchorOffsets(nLeft, nBottom, nRight, nBottom)
	
	local wndContainer = wndControls:FindChild("MasterList")
	local nListLeft, nListTop, nListRight, nListBottom = wndContainer:GetOriginalLocation():GetOffsets()
	wndContainer:SetAnchorOffsets(nListLeft, nListTop, nListRight, nBottom)
	
	wndContainer:DestroyChildren()
	
	local bCanQueue = GameLib.GetPlayerLevel() >= matchWarplot:GetMinLevel()
	
	local wndWarplotSettings = Apollo.LoadForm(self.xmlDoc, "WarplotEntry", wndContainer, self)
	wndWarplotSettings:FindChild("Mercenary"):SetCheck(Apollo.GetConsoleVariable(kstrConsoleAllowMercFilter))
	wndWarplotSettings:FindChild("MercenaryContainer"):SetData(matchWarplot)

	if bCanQueue then
		wndWarplotSettings:FindChild("Mercenary"):Enable(true)
		wndWarplotSettings:FindChild("Mercenary"):SetTooltip("")
	else
		wndWarplotSettings:FindChild("Mercenary"):Enable(false)
		wndWarplotSettings:FindChild("Mercenary"):SetTooltip(String_GetWeaselString(Apollo.GetString("CRB_LevelReqParticipation"), matchWarplot:GetMinLevel(), Apollo.GetString("MatchMaker_Warplots")))
	end
	
	local guildWarparty = self.tHasGuild[ktPvPGuildToTeamSize[nTeamSize]]
	local bCanQueueWarparty = bCanQueue and guildWarparty and guildWarparty:GetRanks()[guildWarparty:GetMyRank()].bCanQueueTheWarparty
	
	wndWarplotSettings:FindChild("Warparty"):Enable(bCanQueueWarparty)
	wndWarplotSettings:FindChild("Warparty"):SetCheck(bCanQueueWarparty and Apollo.GetConsoleVariable(kstrConsoleAllowWarpartyFilter))
	wndWarplotSettings:FindChild("WarpartyContainer"):SetData(matchWarplot)
	
	self.matchDisplayed = matchWarplot

	self:ResizeBlocker()
	self:ValidateQueueButtons()
end

-----------------------------------------------------------------------------------------------
-- Non-Arenas, Warplots, or Quests (aka "the simple stuff")
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildMatchList(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:OnCloseMatchInfo()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(true)
	
	self.arMatchesToQueue = {}
	
	local eMatchType = wndHandler:GetData()
	
	if ktPvETypes[eMatchType] then
		self.ePvETabSelected = eMatchType
	else
		self.ePvPTabSelected = eMatchType
	end
	
	if eMatchType == knQuestTabId then
		self:BuildQuestList()
	elseif eMatchType == MatchingGame.MatchType.Warplot then
		self:BuildWarplotControls()
	elseif eMatchType == MatchingGame.MatchType.OpenArena or eMatchType == MatchingGame.MatchType.Arena then
		self:BuildArenaControls()
	else
		self:BuildMatchControls(eMatchType)
	end
	
	if eMatchType ~= knQuestTabId then
		self:BuildMatchIntro(eMatchType)
	end
end

function MatchMaker:BuildMatchIntro(eMatchType)
	if not ktTypeIntros[eMatchType] then
		return
	end
	
	local wndParent = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchTypeInfo")
	local wndTextContainer = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchTypeInfo:TextContainer")
	local strSprite = ktTypeIntros[eMatchType].strBackground
	
	wndParent:SetSprite(strSprite)
	wndTextContainer:FindChild("Title"):SetText(ktTypeNames[eMatchType])
	
	local strStats = ""
	local strDesc = ""
	if #ktTypeIntros[eMatchType].arStats > 0 then
		for idx, strStat in ipairs(ktTypeIntros[eMatchType].arStats) do
			strStats = string.format("<P Font=\"CRB_Header10\" TextColor=\"UI_TextHoloTitle\">%s</P><P Font=\"CRB_Header10\" TextColor=\"UI_TextHoloTitle\">%s</P>", strStats, strStat)
		end
	end
	
	wndTextContainer:FindChild("Stats"):SetAML(strStats)
	wndTextContainer:FindChild("Stats"):SetHeightToContentHeight()
	
	if #ktTypeIntros[eMatchType].arDescription > 0 then
		for idx, strParagraph in ipairs(ktTypeIntros[eMatchType].arDescription) do	
			strDesc = string.format("%s%s\n\n", strDesc, strParagraph)
		end
	end

	wndTextContainer:FindChild("Description"):SetText(strDesc)	
	wndTextContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:OnCloseMatchInfo()
	local wndInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo")
	
	if wndInfo:IsVisible() then
		local matchInfo = wndInfo:GetData()
		local wndMasterList = self.tWndRefs.wndMain:FindChild("MasterList")
		local matchSelected
		
		if matchInfo:IsRandom() then
			matchSelected = wndMasterList:FindChild("RightColumn"):FindChildByUserData(matchInfo)
		else
			matchSelected = wndMasterList:FindChildByUserData(matchInfo)
		end
		if matchSelected ~= nil then
			matchSelected:SetCheck(false)
		end
		wndInfo:Show(false)
	end 
end

function MatchMaker:GetSortedMatches(eMatchType)
	local arMatchOrder = {}
	if ktRatedToNormal[eMatchType] then
		eMatchType = ktRatedToNormal[eMatchType]
	end

	for idGame, tMatchInfo in pairs(self.tMatchList[eMatchType]) do
		if idGame ~= knRandomMatchIndex then
			table.insert(arMatchOrder, tMatchInfo)
		end
	end
	
	-- Sort the arrays for draw order
	local function fnMatchSort(tInfoA, tInfoB)
		local matchA = tInfoA.matchNormal
		local matchB = tInfoB.matchNormal
		
		if not matchA and not matchB then
			matchA = tInfoA.matchVet
			matchB = tInfoB.matchVet
		end
		
		-- If it's veteran only, then we want it after the list of normal / veteran combinations.  Otherwise, we want it sorted by min level.
		return matchB == nil or (matchA and matchB and matchA:GetMinLevel() < matchB:GetMinLevel()) or false
	end

	table.sort(arMatchOrder, fnMatchSort)
	return arMatchOrder
end

function MatchMaker:BuildMatchControls(eMatchType)
	-- Build the arrays of matches for the given type
	local arMatchOrder = self:GetSortedMatches(eMatchType)

	-- Clear the existing windows
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndContainer = wndControls:FindChild("MasterList")
	wndContainer:DestroyChildren()
	
	if GameLib.GetPlayerLevel(true) == GameLib.GetLevelCap() then
		local wndRandomHeader = self:BuildRandomHeader(eMatchType, wndContainer, arMatchOrder)
		if wndRandomHeader then
			local wndDropdown = wndRandomHeader:FindChild("ListDropdown")
			wndDropdown:SetCheck(true)
			self:ToggleMatchHeader(wndDropdown, wndDropdown)
		end
	end

	local wndMatchTypeContainer = self:BuildMatchTypeContainer(eMatchType, wndContainer, arMatchOrder)
	
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local wndDropdown = wndMatchTypeContainer:FindChild("ListDropdown")
	wndDropdown:SetCheck(true)
	self:ToggleMatchHeader(wndDropdown, wndDropdown)
	
	local wndSettings = wndControls:FindChild("PvESettings")
	local nLeft, nTop, nRight, nBottom = wndSettings:GetOriginalLocation():GetOffsets()
	local nNewTop = nTop
	
	local nListLeft, nListTop, nListRight, nListBottom = wndContainer:GetOriginalLocation():GetOffsets()
	local nNewListBottom = nListBottom
	
	if ktPvETypes[eMatchType] then
		local tValidRoles = {}

		local wndRoles = wndSettings:FindChild("CombatRole")
		for idx, eRole in pairs(MatchingGame.GetEligibleRoles()) do
			tValidRoles[eRole] = true
		end

		local wndRoleDPSBlock = wndRoles:FindChild("DPSBlock")
		local wndRoleDPS = wndRoles:FindChild("DPSBlock:DPS")
		local wndRoleHealerBlock = wndRoles:FindChild("HealerBlock")
		local wndRoleHealer = wndRoles:FindChild("HealerBlock:Healer")
		local wndRoleTankBlock = wndRoles:FindChild("TankBlock")
		local wndRoleTank = wndRoles:FindChild("TankBlock:Tank")
		
		if tValidRoles[MatchingGame.Roles.DPS] then
			wndRoleDPS:Enable(true)
		else
			wndRoleDPS:Enable(false)
			wndRoleDPS:SetTooltip(Apollo.GetString("MatchMaker_RoleClassReq"))
			wndRoleDPSBlock:FindChild("RoleIcon"):SetBGColor("UI_AlphaPercent30")
			wndRoleDPSBlock:FindChild("RoleLabel"):SetTextColor("UI_BtnTextGrayDisabled")
		end
		
		if tValidRoles[MatchingGame.Roles.Tank] then
			wndRoleTank:Enable(true)
		else
			wndRoleTank:Enable(false)
			wndRoleTank:SetTooltip(Apollo.GetString("MatchMaker_RoleClassReq"))
			wndRoleTankBlock:FindChild("RoleIcon"):SetBGColor("UI_AlphaPercent30")
			wndRoleTankBlock:FindChild("RoleLabel"):SetTextColor("UI_BtnTextGrayDisabled")
		end
		
		if tValidRoles[MatchingGame.Roles.Healer] then
			wndRoleHealer:Enable(true)
		else
			wndRoleHealer:Enable(false)
			wndRoleHealer:SetTooltip(Apollo.GetString("MatchMaker_RoleClassReq"))
			wndRoleHealerBlock:FindChild("RoleIcon"):SetBGColor("UI_AlphaPercent30")
			wndRoleHealerBlock:FindChild("RoleLabel"):SetTextColor("UI_BtnTextGrayDisabled")
		end

		local tSelectedRoles = {}
		for idx, eRole in pairs(MatchingGame.GetSelectedRoles()) do
			tSelectedRoles[eRole] = true
		end

		wndRoleDPS:SetCheck(tValidRoles[MatchingGame.Roles.DPS] and tSelectedRoles[MatchingGame.Roles.DPS])
		wndRoleHealer:SetCheck(tValidRoles[MatchingGame.Roles.Tank] and tSelectedRoles[MatchingGame.Roles.Tank])
		wndRoleTank:SetCheck(tValidRoles[MatchingGame.Roles.Healer] and tSelectedRoles[MatchingGame.Roles.Healer])

		wndRoleDPS:SetData(MatchingGame.Roles.DPS)
		wndRoleTank:SetData(MatchingGame.Roles.Tank)
		wndRoleHealer:SetData(MatchingGame.Roles.Healer)
		
		local wndShiphandOptions = wndSettings:FindChild("ShiphandOptions")
		if eMatchType == MatchingGame.MatchType.Shiphand or eMatchType == MatchingGame.MatchType.WorldStory then
			wndShiphandOptions:Show(true)
			wndShiphandOptions:FindChild("DontFindOthers"):SetCheck(Apollo.GetConsoleVariable(kstrConsoleDoNotFindOthers))
		else
			local nShiphandHeight = wndShiphandOptions:GetHeight()
			nNewTop = nTop + nShiphandHeight
			nNewListBottom = nListBottom + nShiphandHeight	
		end
		
		wndSettings:Show(true)
	else
		wndSettings:Show(false)
		nNewListBottom = nBottom
	end

	wndSettings:SetAnchorOffsets(nLeft, nNewTop, nRight, nBottom)
	wndContainer:SetAnchorOffsets(nListLeft, nListTop , nListRight, nNewListBottom)

	self:ResizeBlocker()
	self:ValidateQueueButtons()
end

function MatchMaker:BuildMatchTypeContainer(eMatchType, wndParent, arMatchOrder)
	local bHasNormal = false
	local bHasVet = false
	
	for idGame, tMatchInfo in pairs(self.tMatchList[eMatchType]) do		
		if tMatchInfo.matchNormal then
			bHasNormal = true
		end
		
		if tMatchInfo.matchVet then
			bHasVet = true
		end
	end

	local wndMatchTypeContainer = Apollo.LoadForm(self.xmlDoc, "MatchTypeContainer", wndParent, self)
	local wndSubTypeContainer = wndMatchTypeContainer:FindChild("MatchEntries")
	
	if GameLib.GetPlayerLevel(true) == GameLib.GetLevelCap() and bHasVet then
		self:BuildMatchTypeList(eMatchType, wndSubTypeContainer, arMatchOrder, true)
	end

	if bHasNormal then
		self:BuildMatchTypeList(eMatchType, wndSubTypeContainer, arMatchOrder, false)
	end
	
	wndSubTypeContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	return wndMatchTypeContainer
end

function MatchMaker:BuildMatchTypeList(eMatchType, wndParent, arMatchOrder, bIsVeteran)
	local wndHeader = Apollo.LoadForm(self.xmlDoc, "MatchSelectionParent", wndParent, self)
	local wndChildContainer = wndHeader:FindChild("MatchEntries")

	if bIsVeteran then
		for idx = 1, #arMatchOrder do
			self:BuildMatchButton(arMatchOrder[idx].matchVet, eType, wndChildContainer)
		end	
	else
		for idx = 1, #arMatchOrder do
			self:BuildMatchButton(arMatchOrder[idx].matchNormal, eType, wndChildContainer)
		end
	end	
	
	wndChildContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local nLeft, nTop, nRight, nBottom = wndChildContainer:GetOriginalLocation():GetOffsets()
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndHeader:GetOriginalLocation():GetOffsets()	
	local nHeightOffset = 0
	
	local arMatchWindows = wndChildContainer:GetChildren()
	nHeightOffset = #arMatchWindows * arMatchWindows[1]:GetHeight()
	
	wndHeader:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nParentBottom + nHeightOffset + nTop)
	wndChildContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightOffset)

	local wndTitle = wndHeader:FindChild("MatchBtn")
	
	if ktPvETypes[eMatchType] then
		local strBase = Apollo.GetString("MatchMaker_InstanceNormal")
		if bIsVeteran then
			strBase = Apollo.GetString("MatchMaker_Veteran")
		end

		wndTitle:SetText(String_GetWeaselString(strBase, ktTypeNames[eMatchType]))
	else
		wndTitle:SetText(ktTypeNames[eMatchType])
	end
	
	return wndBuildMatchTypeList
end

function MatchMaker:BuildRandomHeader(eMatchType, wndParent)
	if not self.tMatchList[eMatchType][knRandomMatchIndex] or not self.tMatchList[eMatchType][knRandomMatchIndex].matchVet then
		return
	end
	
	local matchRandom = self.tMatchList[eMatchType][knRandomMatchIndex].matchVet
	
	local wndRandomHeader = Apollo.LoadForm(self.xmlDoc, "MatchTypeContainer", wndParent, self)
	local wndDropdown = wndRandomHeader:FindChild("MatchEntries")
	wndRandomHeader:FindChild("ListDropdown"):SetText(Apollo.GetString("MatchMaker_BonusRewards"))
	
	local wndRandomEntry = Apollo.LoadForm(self.xmlDoc, "RandomSelection", wndDropdown, self)
	local wndSelection = wndRandomEntry:FindChild("MatchSelection")
	local wndTypeLabel = wndRandomEntry:FindChild("TypeLabel")
		
	wndSelection:SetData(matchRandom)
	wndTypeLabel:SetData(matchRandom)

	local tRewardInfo = matchRandom:GetReward()
	if tRewardInfo then
		local wndLabel = wndRandomEntry:FindChild("RewardLabel")
		local wndReward = wndRandomEntry:FindChild("RewardList")
		wndLabel:Show(true)
		wndReward:Show(true)

		if tRewardInfo.itemReward then
			local wndRewardItem = wndReward:FindChild("RewardItem")
			wndRewardItem:GetWindowSubclass():SetItem(tRewardInfo.itemReward)
			Tooltip.GetItemTooltipForm(self, wndRewardItem, tRewardInfo.itemReward, {})
			wndRewardItem:Show(true)
		end

		if tRewardInfo.nXpEarned and tRewardInfo.nXpEarned ~= 0 then
			local wndXPReward = wndReward:FindChild("XpReward")
			wndXPReward:SetTooltip(String_GetWeaselString(Apollo.GetString("CRB_XPAmount"), Apollo.FormatNumber(tRewardInfo.nXpEarned, 0, true)))
			wndXPReward:Show(true)
		end

		if tRewardInfo.monReward then
			local wndCashWindow = wndReward:FindChild("CashWindow")
			wndCashWindow:SetMoneySystem(tRewardInfo.monReward:GetMoneyType())
			wndCashWindow:SetAmount(tRewardInfo.monReward:GetAmount(), true)
			wndCashWindow:Show(true)
		end
	end
	
	wndTypeLabel:SetText(matchRandom:GetName())
	
	wndRandomHeader:SetData(knRandomMatchIndex)
	return wndRandomHeader
end

function MatchMaker:BuildMatchButton(matchGame, eMatchType, wndParent)
	if not matchGame then
		return
	end

	local wndOption = Apollo.LoadForm(self.xmlDoc, "MatchSelection", wndParent, self)
	local strText = matchGame:GetName()
	local nMinLevel = matchGame:GetMinLevel()
	local nMaxLevel = matchGame:GetMaxLevel()

	if nMinLevel > 0 then
		if nMinLevel == nMaxLevel or nMaxLevel == GameLib.GetLevelCap() then
			strText = strText .. " (" .. nMinLevel .. ")"
		else
			strText = strText .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), nMinLevel, nMaxLevel) .. ")"
		end
	end

	local wndInfoButton = wndOption:FindChild("MatchBtn")
	local wndSelection = wndOption:FindChild("SelectMatch")
	if GameLib.GetPlayerUnit():GetLevel() < nMinLevel then
		wndSelection:Enable(false)
		wndInfoButton:Enable(false)
		wndSelection:SetTooltip(Apollo.GetString("PrerequisiteComp_Level"))
	end

	wndInfoButton:SetText(strText)
	wndInfoButton:SetData(matchGame)
	wndSelection:SetData(matchGame)
end

function MatchMaker:ToggleMatchHeader(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("MatchEntries")
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndParent:GetOriginalLocation():GetOffsets()
	
	local nHeightOffset = 0
	if wndHandler:IsChecked() then
		local arMatchGroupWindows = wndContainer:GetChildren()
		for idx = 1, #arMatchGroupWindows do
			nHeightOffset = nHeightOffset + arMatchGroupWindows[idx]:GetHeight()
		end
	end
	
	wndParent:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nParentBottom + nHeightOffset)
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndParent:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndContainer:Show(true)
end

function MatchMaker:UpdateAchievements()
	if not self.tWndRefs.wndMain or not self.matchDisplayed then
		return
	end

	local tCategoryInfo = AchievementsLib.GetCategoryForMatchingGame(self.matchDisplayed)
	
	if not tCategoryInfo then
		return
	end
	
	local arAchievements = AchievementsLib.GetAchievementsForCategory(tCategoryInfo.nCategoryId, true)
	
	local wndAchievementContainer = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo:Content:AchievementContainer")
	
	wndAchievementContainer:FindChild("CategoryName"):SetText(tCategoryInfo.strCategoryName)
	
	local wndProgress = wndAchievementContainer:FindChild("ProgressBG:AchievementProgress")
	wndProgress:SetMax(#arAchievements)
	
	local nCompleted = 0
	for idx = 1, #arAchievements do
		if arAchievements[idx]:IsComplete() then
			nCompleted = nCompleted + 1
		end
	end

	wndProgress:SetProgress(nCompleted)
end

function MatchMaker:OnPlayerLevelChange()
	self.tSuggestedInfo = ContentFinderLib.GetSuggestedContent()
	
	if self.tWndRefs.wndMain then
		self:BuildMatchTable()
		self:RecalculateContents()
		self:UpdateTeamInfo()
	end
end

function MatchMaker:RecalculateContents()
	if not self.tWndRefs.wndMain then
		return
	end
	
	if self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo"):IsShown() then
		self:SetMatchDetails(self.matchDisplayed)
	elseif self.eSelectedMasterType == keMasterTabs.Suggested then
		local wndSuggestedTab = self.tWndRefs.wndMain:FindChild("HeaderButtons:SuggestedBtn")
		self:OnSuggestedTabSelected(wndSuggestedTab, wndSuggestedTab)
	end
end

-----------------------------------------------------------------------------------------------
-- Match List button functionality
-----------------------------------------------------------------------------------------------
function MatchMaker:OnMatchChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local matchShown = wndHandler:GetData()

	self:SetMatchDetails(matchShown)
end

function MatchMaker:SetMatchDetails(matchSelected)
	local wndInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo")
	
	if not matchSelected then
		wndInfo:Show(false)
		return
	end
	
	self.matchDisplayed = matchSelected
	wndInfo:SetData(matchSelected)
	
	local eMatchType = matchSelected:GetType()
	
	local wndDetails = wndInfo:FindChild("Details")
	
	local strDetails = matchSelected:GetDescription()
	local nRecommendedItemLevel = matchSelected:GetRecommendedItemLevel()
	
	if matchSelected:IsRandom() and self.tMatchList ~= nil then
		local nMaxItemLevel = 0
		local bIsVet = matchSelected:IsVeteran() or ktRatedPvPTypes[eMatchType]
		local tSelectedMatches = {}
		if self.tMatchList[eMatchType] ~= nil then
			tSelectedMatches = self.tMatchList[eMatchType]
		end
		for idx, tMatches in pairs(tSelectedMatches) do
			local matchCurrent = tMatches.matchVet
			if not bIsVet and tMatches.matchNormal ~= nil then
				matchCurrent = tMatches.matchNormal
			end
			
			if matchCurrent ~= nil then
				local nCurrentRecommendedLevel = matchCurrent:GetRecommendedItemLevel()
				if nCurrentRecommendedLevel and nCurrentRecommendedLevel > nMaxItemLevel then
					nMaxItemLevel = nCurrentRecommendedLevel
				end
			end
		end
		
		nRecommendedItemLevel = nMaxItemLevel
	end

	if nRecommendedItemLevel ~= nil and nRecommendedItemLevel > 0 then
		local strTextColor = "UI_TextHoloBody"
		local nPlayerItemLevel = GameLib.GetPlayerUnit():GetEffectiveItemLevel()
		
		if nPlayerItemLevel and nRecommendedItemLevel > nPlayerItemLevel then
			strTextColor = "UI_WindowTextRed"
		end
		
		local strItemLevel = String_GetWeaselString(Apollo.GetString("MatchMaker_RecommendedItemLevel"), string.format("<T TextColor=\"%s\">%d</T>", strTextColor, nRecommendedItemLevel))		
		strDetails = strDetails .. "\n" .. strItemLevel
	end
	
	strDetails = string.format("<T Font=\"CRB_Interface10\" TextColor=\"UI_TextHoloBody\">%s</T>", strDetails)

	wndDetails:FindChild("Title"):SetText(matchSelected:GetName())
	wndDetails:FindChild("QueueLabel"):Show(matchSelected:IsQueued())
	
	local wndDescriptionText = wndDetails:FindChild("Description")
	local nOldHeight = wndDescriptionText:GetHeight()
	wndDescriptionText:SetAML(strDetails)
	
	local nNewWidth, nNewHeight = wndDescriptionText:SetHeightToContentHeight()	
	local nLeft, nTop, nRight, nBottom = wndDetails:GetAnchorOffsets()
	wndDetails:SetAnchorOffsets(nLeft, nTop, nRight, nTop + wndDetails:GetHeight() - (nOldHeight - nNewHeight))
	
	local wndRating = wndInfo:FindChild("PersonalRatingContainer")
	local eRatingType = ktPvPRatingTypes[eMatchType]
	if eMatchType == MatchingGame.MatchType.Arena then
		eRatingType = ktPvPRatingTypes[eMatchType][matchSelected:GetTeamSize()]
	end
	
	if eRatingType then
		local tRatingInfo = MatchingGame.GetPvpRating(eRatingType)
		
		if tRatingInfo then
			wndRating:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PersonalRating"), tRatingInfo.nRating))
			wndRating:Show(true)
		else
			wndRating:Show(false)
		end
	else
		wndRating:Show(false)
	end
	
	-- Set up rewards for random matches
	local tRewardInfo = matchSelected:GetReward()
	local wndRewardContainer = wndInfo:FindChild("RewardsContainer")
	if tRewardInfo then
		local wndRewardItem = wndRewardContainer:FindChild("RewardItem")
		if tRewardInfo.itemReward then
			local wndIcon = wndRewardItem:FindChild("Icon")
			wndIcon:GetWindowSubclass():SetItem(tRewardInfo.itemReward)
			Tooltip.GetItemTooltipForm(self, wndIcon, tRewardInfo.itemReward, {})
			
			local wndLabel = wndRewardItem:FindChild("Label")
			wndLabel:SetText(tRewardInfo.itemReward:GetName())
			wndLabel:SetTextColor(ktItemQualityColors[tRewardInfo.itemReward:GetItemQuality()])
			
			wndRewardItem:Show(true)
		else
			wndRewardItem:Show(false)
		end
		
		local wndXP = wndRewardContainer:FindChild("XPReward")
		if tRewardInfo.nXpEarned and tRewardInfo.nXpEarned > 0 then
			wndXP:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("CRB_XPAmount"), Apollo.FormatNumber(tRewardInfo.nXpEarned, 0, true)))
			wndXP:Show(true)
		else
			wndXP:Show(false)
		end
		
		local wndMoney = wndRewardContainer:FindChild("CashWindow")
		if tRewardInfo.monReward then
			wndMoney:SetAmount(tRewardInfo.monReward, true)
			wndMoney:Show(true)
		else
			wndMoney:Show(false)
		end
		
		wndRewardContainer:Show(true)
	else
		wndRewardContainer:Show(false)
	end
	
	-- Set up team info for Arenas and Warplots	
	self:UpdateTeamInfo()
	-- Update the achievements UI
	self:UpdateAchievements()
	
	wndInfo:FindChild("Content"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	wndInfo:Show(true)
end

function MatchMaker:UpdateTeamInfo()
	if not self.matchDisplayed or not self.tWndRefs.wndMain then
		return
	end
	
	local wndInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo")
	local wndTeam = wndInfo:FindChild("TeamContainer")
	local eMatchType = self.matchDisplayed:GetType()
	
	if ktPvPGuildRequired[eMatchType] then
		local wndTeam = wndInfo:FindChild("TeamContainer")
		local wndUpsellPlayerBtn = wndTeam:FindChild("UpsellPlayer")
		local wndCreateTeamBtn = wndTeam:FindChild("CreateTeam")
		local wndExistingTeam = wndTeam:FindChild("ExistingTeam")
		local wndTeamName = wndTeam:FindChild("TeamName")

		local eGuildType = ktPvPGuildToTeamSize[self.matchDisplayed:GetTeamSize()]
		local bCanCreate = GuildLib.CanCreate(eGuildType)
		local bHybridSystem = AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.Hybrid

		local guildShown = self.tHasGuild[eGuildType]
		if guildShown then
			wndExistingTeam:Show(true)
			wndCreateTeamBtn:Show(false)
			wndUpsellPlayerBtn:Show(false)

			local tMyRatingInfo = guildShown:GetMyPvpRatings()
			local tTeamRatingInfo = guildShown:GetPvpRatings()			
			local nTeamMatchesPlayed = tTeamRatingInfo.nWins + tTeamRatingInfo.nLosses + tTeamRatingInfo.nDraws
			local nMyGames = tMyRatingInfo.nWins + tMyRatingInfo.nLosses + tMyRatingInfo.nDraws
			local strPercent = String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor(tMyRatingInfo.fParticipation * 100))
			
			wndTeamName:SetText(guildShown:GetName())
			wndTeam:FindChild("Rating"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_Rating"), tTeamRatingInfo.nRating))
			wndTeam:FindChild("TeamPlayed"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_GamesPlayed"), nTeamMatchesPlayed))
			wndTeam:FindChild("PersonalPlayed"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_TeamParticipation"), nMyGames, strPercent))
			
			local wndRosterButton = wndTeam:FindChild("RosterButton")
			wndRosterButton:Show(true)
			wndRosterButton:SetData(guildShown:GetType())
			wndRosterButton:FindChild("SignatureValid"):Show(bHybridSystem and bCanCreate)
		else
			wndExistingTeam:Show(false)
	
			local strLabel = "Guild_GuildTypeWarparty"
			if eMatchType == MatchingGame.MatchType.Arena then
				strLabel = "Guild_GuildTypeArena"
			end
			wndTeamName:SetText(Apollo.GetString(strLabel))

			local strUpsellText = "Storefront_NavVip"
			if bHybridSystem then
				strUpsellText = "Storefront_NavSignature"
			end

			local bShowUpsell = not bCanCreate and GameLib.GetPlayerLevel(true) >= self.matchDisplayed:GetMinLevel()
			wndCreateTeamBtn:Show(not bShowUpsell)
			wndCreateTeamBtn:FindChild("SignaturePlayerValid"):Show(bHybridSystem)
			wndCreateTeamBtn:SetData(eGuildType)
			wndCreateTeamBtn:Enable(bCanCreate)

			wndUpsellPlayerBtn:Show(bShowUpsell)
			wndUpsellPlayerBtn:FindChild("SignatureBanner"):Show(bHybridSystem)
			wndUpsellPlayerBtn:SetText(String_GetWeaselString(Apollo.GetString("Matchmaker_PlayerTeamCreation"), Apollo.GetString(strUpsellText)))
			wndUpsellPlayerBtn:SetData(eGuildType)
			wndUpsellPlayerBtn:Enable(not bCanCreate and self.bStoreLinkValid)
		end
		
		wndTeam:Show(true)
	else
		wndTeam:Show(false)
	end
end

function MatchMaker:ToggleArenaQueueStatus(wndHandler, wndControl)
	self.arMatchesToQueue = {}
	self:UpdateQueueList(wndControl:GetData(), wndControl:IsChecked())
end

function MatchMaker:ToggleParentStatus(wndControl, wndHandler)
	if wndHandler ~= wndControl then
		return
	end
	
	local arMatchList = wndControl:GetParent():FindChild("MatchEntries"):GetChildren()
	local bIsSelected = wndControl:IsChecked()
	
	for idx, matchEntry in pairs(arMatchList) do
		local wndSelection = matchEntry:FindChild("SelectMatch")
		if wndSelection:IsEnabled() then
			wndSelection:SetCheck(bIsSelected)
			
			self:UpdateQueueList(wndSelection:GetData(), bIsSelected)
		end
	end
	
	if bIsSelected then
		self:ForceUncheckRandomQueue()
	end
end

function MatchMaker:ToggleRandomQueueStatus(wndControl, wndHandler)
	local matchSelected = wndControl:GetData()
	local eMatchType = matchSelected:GetType()
	
	self.arMatchesToQueue = {}
	self:UpdateQueueList(matchSelected, wndControl:IsChecked())
	
	local wndMasterList = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:MasterList")
	
	if wndControl:IsChecked() then
		for idx, wndHeader in pairs(wndMasterList:GetChildren()) do
			if wndHeader:GetData() ~= knRandomMatchIndex then
				for idx, wndParent in pairs(wndHeader:FindChild("MatchEntries"):GetChildren()) do
					local wndParentSelect = wndParent:FindChild("MatchSelection")
					wndParentSelect:SetCheck(false)
					self:ToggleParentStatus(wndParentSelect, wndParentSelect)
				end
			end
		end
	end
end

function MatchMaker:ToggleMatchQueueStatus(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local matchSelected = wndControl:GetData()
	local wndMatchList = nil
	
	local eMatchType = matchSelected:GetType()
	
	self:UpdateQueueList(matchSelected, wndControl:IsChecked())

	local wndMatchList = wndControl:GetParent():GetParent()
	local wndMatchParentSelection = wndMatchList:GetParent():FindChild("MatchSelection")
	
	local bAllChecked = true
	for idx, wndSelection in pairs(wndMatchList:GetChildren()) do
		bAllChecked = wndSelection:FindChild("SelectMatch"):IsChecked()
		
		if not bAllChecked then
			break
		end
	end
	
	wndMatchParentSelection:SetCheck(bAllChecked)
	
	if wndControl:IsChecked() then
		self:ForceUncheckRandomQueue()
	end
end

function MatchMaker:ForceUncheckRandomQueue()
	local wndMasterList = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:MasterList")
	for idx, wndHeader in pairs(wndMasterList:GetChildren()) do
		if wndHeader:GetData() == knRandomMatchIndex then
			for idx, wndParent in pairs(wndHeader:FindChild("MatchEntries"):GetChildren()) do
				local wndRandomSelect = wndParent:FindChild("MatchSelection")
				wndRandomSelect:SetCheck(false)
				self:UpdateQueueList(wndRandomSelect:GetData(), false)
			end
		end
	end
end

function MatchMaker:UpdateQueueList(matchUpdated, bShouldAdd)
	if bShouldAdd then
		table.insert(self.arMatchesToQueue, matchUpdated)
	elseif #self.arMatchesToQueue > 0 then
		for idx = 1, #self.arMatchesToQueue do
			if self.arMatchesToQueue[idx] == matchUpdated then
				table.remove(self.arMatchesToQueue, idx)
			end
		end
	end
	
	self:CheckQueueEligibility()
end

function MatchMaker:OnToggleCombatRole(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	MatchingGame.SelectRole(wndHandler:GetData(), wndHandler:IsChecked())

	self:ValidateQueueButtons()
end

function MatchMaker:OnShiphandOptionToggle(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Apollo.SetConsoleVariable(kstrConsoleDoNotFindOthers, wndHandler:IsChecked())
end

function MatchMaker:ToggleMercenaryQueue(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Apollo.SetConsoleVariable(kstrConsoleAllowMercFilter, wndHandler:IsChecked())
	
	self:CheckQueueEligibility()
end

function MatchMaker:ToggleWarpartyQueue(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	Apollo.SetConsoleVariable(kstrConsoleAllowWarpartyFilter, wndHandler:IsChecked())
	
	self:CheckQueueEligibility()
end

-----------------------------------------------------------------------------------------------
-- Queue button functionality
-----------------------------------------------------------------------------------------------
function MatchMaker:CheckQueueEligibility()
	local eType = nil
	if self.tWndRefs.wndMain:FindChild("HeaderButtons:PvPBtn"):IsChecked() then
		eType = self.ePvPTabSelected
	elseif self.tWndRefs.wndMain:FindChild("HeaderButtons:PvEBtn"):IsChecked() then
		eType = self.ePvETabSelected
	else
		return
	end
	
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndDefault = wndControls:FindChild("QueueControls:DefaultControls")
	
	if eType == MatchingGame.MatchType.OpenArena then
		if #self.arMatchesToQueue > 0 then
			eType = self.arMatchesToQueue[1]:GetType()
		end
	end
	
	local bSoloOnly = true
	for idx, matchSelected in pairs(self.arMatchesToQueue) do
		if matchSelected:GetTeamSize() > 1 or matchSelected:IsRandom() then
			bSoloOnly = false
			break
		end
	end
	
	local bValidRoleSelection = true
	if ktPvETypes[eType] and not bSoloOnly then
		bValidRoleSelection = #MatchingGame.GetSelectedRoles() > 0
	end
	
	local nWarpartyTeamSize = 0
	for idx, tMatchInfo in pairs(self.tMatchList[MatchingGame.MatchType.Warplot]) do
		matchWarplot = tMatchInfo.matchVet
		nWarpartyTeamSize = idx
	end

	local guildWarparty = self.tHasGuild[ktPvPGuildToTeamSize[nWarpartyTeamSize]]
	local bCanQueueAsWarparty = eType == MatchingGame.MatchType.Warplot and guildWarparty and guildWarparty:GetRanks()[guildWarparty:GetMyRank()].bCanQueueTheWarparty
	local bCanSoloQueue = (not ktPvPGuildRequired[eType] or (bCanQueueAsWarparty and Apollo.GetConsoleVariable(kstrConsoleAllowWarpartyFilter)) or (eType == MatchingGame.MatchType.Warplot and Apollo.GetConsoleVariable(kstrConsoleAllowMercFilter))) and bValidRoleSelection and #self.arMatchesToQueue > 0
	wndDefault:FindChild("SoloQueue"):Enable(bCanSoloQueue)

	local bCanJoinAsGroup = MatchingGame.CanQueueAsGroup() and not bSoloOnly
	
	if bCanJoinAsGroup then
		if eType ~= MatchingGame.MatchType.Warplot then
			for idx = 1, #self.arMatchesToQueue do
				bCanJoinAsGroup = self.arMatchesToQueue[idx]:DoesGroupMeetRequirements()
				
				if not bCanJoinAsGroup then
					break
				end
			end
		else
			bCanJoinAsGroup = Apollo.GetConsoleVariable(kstrConsoleAllowMercFilter)

			if not bCanJoinAsGroup then
				bCanJoinAsGroup = bCanQueueAsWarparty and Apollo.GetConsoleVariable(kstrConsoleAllowWarpartyFilter)
			end
		end
	end

	local wndGroupJoin = wndDefault:FindChild("GroupJoin")
	wndGroupJoin:Enable(bCanJoinAsGroup)
	
	local strButtonText = "MatchMaker_JoinAsGroup"
	
	if not MatchingGame.CanQueueAsGroup() then
		strButtonText = "Matchmaker_GroupNotEligible"
	end

	wndControls:FindChild("MasterListSelectBlocker"):Show(#self.arMatchesToQueue == 0)
	wndControls:FindChild("QueueControls:RoleSelectBlocker"):Show(not bValidRoleSelection)
	wndControls:FindChild("PvESettings:NoRoleBlocker"):Show(bSoloOnly)
		
	wndGroupJoin:SetText(Apollo.GetString(strButtonText))
end

function MatchMaker:ResizeBlocker()
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndBlocker = wndControls:FindChild("MasterListSelectBlocker")
	
	local nListLeft, nListTop, nListRight, nListBottom = wndControls:FindChild("MasterList"):GetAnchorOffsets()
	local nBlockerLeft, nBlockerTop, nBlockerRight, nBlockerBottom = wndBlocker:GetAnchorOffsets()
	local nNewBlockerTop = nBlockerTop

	wndBlocker:SetAnchorOffsets(nBlockerLeft, nListBottom - 25, nBlockerRight, nBlockerBottom)
end

function MatchMaker:ValidateQueueButtons()
	if not self.tWndRefs.wndMain then
		return
	end
	
	if MatchingGame.IsInMatchingGame() then
		self:EnterStateInMatchingGame()
	elseif MatchingGame.IsQueuedForMatching() then
		self:EnterStateInQueue()
	else
		self:EnterStateDefault()
	end
end

function MatchMaker:EnterStateDefault()
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:QueueControls")
	local wndQueuedIcon = self.tWndRefs.wndMain:FindChild("QueuedIcon")
	local wndDefault = wndControls:FindChild("DefaultControls")
	
	wndDefault:Show(true)
	wndControls:FindChild("QueuedControls"):Show(false)
	wndControls:FindChild("InMatchControls"):Show(false)
	wndQueuedIcon:Show(false)
	
	self:CheckQueueEligibility()
end

function MatchMaker:EnterStateInQueue()
	if not MatchingGame.IsQueuedForMatching() and not MatchingGame.IsQueuedAsGroup() then
		return
	end
	
	local wndQueuedIcon = self.tWndRefs.wndMain:FindChild("QueuedIcon")	
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:QueueControls")
	wndControls:FindChild("DefaultControls"):Show(false)
	wndControls:FindChild("QueuedControls"):Show(true)
	wndControls:FindChild("InMatchControls"):Show(false)
	wndQueuedIcon:Show(true)
end

function MatchMaker:EnterStateInMatchingGame()
	if not MatchingGame.IsInMatchingGame() then
		return
	end

	local wndQueuedIcon = self.tWndRefs.wndMain:FindChild("QueuedIcon")	
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:QueueControls")
	local wndInMatch = wndControls:FindChild("InMatchControls")
	wndControls:FindChild("DefaultControls"):Show(false)
	wndControls:FindChild("QueuedControls"):Show(false)
	wndQueuedIcon:Show(false)
	wndInMatch:Show(true)
end

function MatchMaker:OnUpdateGroup()
	if self.tWndRefs.wndMain then
		self:UpdateInMatchControls()
		self:ValidateQueueButtons()
	end
end

function MatchMaker:OnUnitLevelChanged(unitPlayer, nUnitID)
	if self.tWndRefs.wndMain and unitPlayer:IsInYourGroup() then
		self:ValidateQueueButtons()
	end
end

-----------------------------------------------------------------------------------------------
-- Setting up Quests
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildQuestList(wndHandler, wndControl)
	local wndQuestContent = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent")
	wndQuestContent:Show(true)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(false)
	
	self.ePvETabSelected = knQuestTabId
	
	local wndContainer = wndQuestContent:FindChild("ZoneList")
	local nPlayerLevel = GameLib.GetPlayerUnit():GetLevel()
	
	wndContainer:DestroyChildren()

	for strZone, tZoneInfo in pairs(self.tHubList) do
		local wndOption = Apollo.LoadForm(self.xmlDoc, "ModeEntry", wndContainer, self)
		local wndButton = wndOption:FindChild("ModeBtn")
	
		if tZoneInfo.nMinLevel == tZoneInfo.nMaxLevel then
			strText = strZone .. "\n(" .. tZoneInfo.nMinLevel .. ")"
		else
			strText = strZone .. "\n(" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), tZoneInfo.nMinLevel, tZoneInfo.nMaxLevel) .. ")"
		end
		
		if tZoneInfo.nMinLevel > nPlayerLevel then
			wndButton:Enable(false)
			wndOption:FindChild("Locked"):Show(true)
			wndOption:SetTooltip(Apollo.GetString("CRB_Locked"))
		end
		
		wndButton:SetText(strText)
		wndButton:SetData(tZoneInfo)

		wndOption:FindChild("CompletionPct"):SetText(math.floor((tZoneInfo.nCompleted / tZoneInfo.nTotal) * 100) .. "%")
		wndOption:FindChild("CompletionPct"):Show(true)
	end

	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:FindChild("ModeBtn"):GetData().nMinLevel < b:FindChild("ModeBtn"):GetData().nMinLevel end)
end

-----------------------------------------------------------------------------------------------
-- Quest Tab
-----------------------------------------------------------------------------------------------
function MatchMaker:OnQuestSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:SetQuestTabContent(wndHandler:GetData())
end

function MatchMaker:SetQuestTabContent(tHubs)
	if not tHubs then
		return
	end

	local wndQuestContent = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent")
	local wndContent =  wndQuestContent:FindChild("QuestContainer:Content")
	wndContent:DestroyChildren()

	for strHubName, tHubInfo in pairs(tHubs.tHubInfo) do
		local wndContainer = Apollo.LoadForm(self.xmlDoc, "QuestHubEntry", wndContent, self)

		if tHubInfo.nMinLevel == tHubInfo.nMaxLevel then
			strHubName = strHubName .. " (" .. tHubInfo.nMinLevel .. ")"
		else
			strHubName = strHubName .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), tHubInfo.nMinLevel, tHubInfo.nMaxLevel) .. ")"
		end

		wndContainer:FindChild("HeaderBtnText"):SetText(strHubName)

		local nPercent = (tHubInfo.nCompleted / tHubInfo.nTotal) * 100
		wndContainer:FindChild("CompletionPercent"):SetText(nPercent .. "%")

		wndContainer:FindChild("HeaderBtn"):SetData(tHubInfo)
	end

	wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:FindChild("HeaderBtn"):GetData().nMinLevel < b:FindChild("HeaderBtn"):GetData().nMinLevel end)
	wndQuestContent:FindChild("Title"):SetText(tHubs.strZoneName)
	wndQuestContent:Show(true)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(false)
	
	local wndAchievement = wndQuestContent:FindChild("ContentFooter:AchievementContainer")
	local wndProgress = wndAchievement:FindChild("ProgressBG:AchievementProgress")
	wndProgress:SetMax(tHubs.nTotal)
	wndProgress:SetProgress(tHubs.nCompleted)
	
	wndAchievement:FindChild("ProgressCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tHubs.nCompleted, tHubs.nTotal))
end

function MatchMaker:ExpandHub(wndHandler, wndControl)
	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("HeaderContainer")
	local tHubInfo = wndHandler:GetData()
	local nHubHeight = 0

	for idx, epiCurrent in pairs(tHubInfo.arEpisodes) do
		local wndEpisode = Apollo.LoadForm(self.xmlDoc, "EpisodeEntry", wndContainer, self)

		local eState = epiCurrent:GetState() 
		if eState == Episode.EpisodeState_Complete then
			wndEpisode:FindChild("CheckContainer"):SetSprite("CRB_DialogSprites:sprDialog_Icon_Check")
		end

		local wndTitle = wndEpisode:FindChild("Title")
		wndTitle:SetTextColor(ktEpisodeStateColors[eState])
		wndTitle:SetText(epiCurrent:GetTitle() .. " (" .. epiCurrent:GetConLevel() .. ")")
		
		local wndSummary = wndEpisode:FindChild("Summary")
		local strSummary = eState == Episode.EpisodeState_Complete and epiCurrent:GetSummary() or epiCurrent:GetDesc()
		wndSummary:SetAML("<T TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceMedium\">" .. strSummary .. "</T>")

		wndSummary:SetHeightToContentHeight()

		wndEpisode:FindChild("EpisodeSelection"):SetData(wndParent)
		wndEpisode:SetData(epiCurrent)

		if nHubHeight == 0 then
			nHubHeight = wndEpisode:GetHeight()
		end
	end

	self:ResizeExpandedHub(wndParent)
end

function MatchMaker:CollapseHub(wndHandler, wndControl)
	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("HeaderContainer")
	wndContainer:DestroyChildren()

	local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

	nLeft, nTop, nRight, nBottom = wndParent:GetOriginalLocation():GetOffsets()
	wndParent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

	local wndContent = wndParent:GetParent()
	wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	if wndContent:GetVScrollRange() == 0 then
		wndContent:SetVScrollPos(0)
	end
end

function MatchMaker:ResizeExpandedHub(wndHub)
	local wndContainer = wndHub:FindChild("HeaderContainer")
	
	local arEpisodes = wndContainer:GetChildren()
	local nHeight = arEpisodes[1]:GetHeight()

	if #arEpisodes > 1 then
		nHeight = wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData():GetConLevel() < b:GetData():GetConLevel() end)
	end
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)
	
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndHub:GetOriginalLocation():GetOffsets()
	local nBuffer = (nParentBottom - nParentTop) - nBottom

	wndHub:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nParentBottom + wndContainer:GetHeight() + nBuffer)
	
	wndHub:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:ExpandEpisode(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.wndSelectedEpisodeBtn then
		self:CollapseEpisode(self.wndSelectedEpisodeBtn, self.wndSelectedEpisodeBtn)
	end
	
	self.wndSelectedEpisode = wndHandler
	
	local wndEpisode = wndHandler:GetParent()
	local wndSummary = wndEpisode:FindChild("Summary")
	local nBuffer = wndEpisode:GetHeight() - wndEpisode:FindChild("Background"):GetHeight() + 8
	
	local nLeft, nTop, nRight, nBottom = wndEpisode:GetAnchorOffsets()
	wndEpisode:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + wndSummary:GetHeight() + nBuffer)
	
	wndSummary:Show(true)

	self:ResizeExpandedHub(wndHandler:GetData())
end

function MatchMaker:CollapseEpisode(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.wndSelectedEpisodeBtn = nil
	
	local wndEpisode = wndHandler:GetParent()
	
	local nLeft, nTop, nRight, nBottom = wndEpisode:GetOriginalLocation():GetOffsets()
	wndEpisode:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	
	wndEpisode:FindChild("Summary"):Show(false)
	
	self:ResizeExpandedHub(wndHandler:GetData())
	
	local wndContent = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent:QuestContainer:Content")
	
	if wndContent:GetVScrollRange() == 0 then
		wndContent:SetVScrollPos(0)
	end
end

-----------------------------------------------------------------------------------------------
-- Suggested Tab
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildSuggestedMatch(matchSuggested)
	if not matchSuggested then
		return
	end

	local wndMatch = Apollo.LoadForm(self.xmlDoc, "SuggestedListItem", self.tWndRefs.wndMain:FindChild("ContentContainer"), self)
	local eMatchType = matchSuggested:GetType()
	
	wndMatch:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("Archive_ZoneCategories"), (ktTypeNames[eMatchType] or ""), matchSuggested:GetName()))
	wndMatch:FindChild("InteractBtn"):SetData(matchSuggested)
	
	local wndDescription = wndMatch:FindChild("Description")
	wndDescription:SetText(matchSuggested:GetDescription())
	local nOldHeight = wndDescription:GetHeight()
	wndDescription:SetHeightToContentHeight()
	local nDelta = wndDescription:GetHeight() - nOldHeight

	local nLeft, nTop, nRight, nBottom = wndMatch:GetAnchorOffsets()
	wndMatch:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nDelta)
end

function MatchMaker:BuildSuggestedQuest(tQuestInfo)
	local wndQuest = Apollo.LoadForm(self.xmlDoc, "SuggestedListItem", self.tWndRefs.wndMain:FindChild("ContentContainer"), self)
	wndQuest:FindChild("InteractBtn"):SetText(Apollo.GetString("CRB_Locate"))

	local wndDescription = wndQuest:FindChild("Description")
	if self.tSuggestedInfo.tQuestInfo.hubSuggested then
		wndQuest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("Archive_ZoneCategories"), Apollo.GetString("MatchMaker_QuestHub"), String_GetWeaselString(Apollo.GetString("CRB_ColonLabelValue"), tQuestInfo.hubSuggested:GetWorldZoneName(),tQuestInfo.hubSuggested:GetName())))
		wndDescription:SetText("")  -- hubSuggested:GetDescription() should replace this when it exists
		wndQuest:FindChild("InteractBtn"):SetData(tQuestInfo.hubSuggested)
	elseif self.tSuggestedInfo.tQuestInfo.epiSuggested then
		wndQuest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("Archive_ZoneCategories"), Apollo.GetString("MatchMaker_Episode"), tQuestInfo.epiSuggested:GetTitle()))
		wndQuest:FindChild("Description"):SetText(tQuestInfo.epiSuggested:GetSummary())
		wndQuest:FindChild("InteractBtn"):SetData(tQuestInfo.epiSuggested)
	elseif self.tSuggestedInfo.tQuestInfo.queSuggested then
		wndQuest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("Archive_ZoneCategories"), Apollo.GetString("Tooltips_Quest"), tQuestInfo.queSuggested:GetTitle()))
		wndQuest:FindChild("Description"):SetText(tQuestInfo.queSuggested:GetSummary())
		wndQuest:FindChild("InteractBtn"):SetData(tQuestInfo.queSuggested)
	end
	
	local nOldHeight = wndDescription:GetHeight()
	wndDescription:SetHeightToContentHeight()
	local nDelta = wndDescription:GetHeight() - nOldHeight

	local nLeft, nTop, nRight, nBottom = wndQuest:GetAnchorOffsets()
	wndQuest:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nDelta)
end

function MatchMaker:OnSuggestedInteract(wndControl, wndHandler)
	if wndControl ~= wndHandler then
		return
	end
	
	local oData = wndHandler:GetData()

	if MatchingGame.is(oData) then
		local eType = oData:GetType()
		if ktPvETypes[eType] then
			local wndPvEBtn = self.tWndRefs.wndMain:FindChild("PvEBtn")
			self.tWndRefs.wndMain:FindChild("HeaderButtons"):SetRadioSelButton("MatchMakerTabGroup", wndPvEBtn)
			self.ePvETabSelected = eType
			self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
		elseif ktPvPTypes[eType] or ktRatedPvPTypes[eType] then
			local wndPvPBtn = self.tWndRefs.wndMain:FindChild("PvPBtn")
			self.tWndRefs.wndMain:FindChild("HeaderButtons"):SetRadioSelButton("MatchMakerTabGroup", wndPvPBtn)
			
			if ktRatedToNormal[eType] then
				eType = ktRatedToNormal[eType]
			end
			
			self.ePvPTabSelected = eType
			self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
		end
		
		self:SetMatchDetails(oData)
	elseif QuestHub.is(oData) then
		local tLocation = oData:GetLocation()
		if tLocation then
			local tNavPoint = GameLib.GetNavPoint()
			if tNavPoint and tNavPoint.tPostion ~= tLocation then
				self:ShowNavPointNotification(tLocation, oData)
			else
				self:ConfirmNavPointChange(tLocation, oData)
			end
		end
	elseif Episode.is(oData) then
		local hubArea = oData:GetHub()

		if hubArea then
			local tLocation = hubArea:GetLocation()
			if tLocation then
				local tNavPoint = GameLib.GetNavPoint()
				if tNavPoint and tNavPoint.tPosition.x ~= tLocation.x and tNavPoint.tPosition.y ~= tLocation.y and tNavPoint.tPosition.z ~= tLocation.z then
					self:ShowNavPointNotification(tLocation, hubArea)
				else
					self:ConfirmNavPointChange(tLocation, hubArea)
				end
			end
		end
	end
end

function MatchMaker:OnEpisodeNavPoint(wndHandler, wndControl)
	local hubArea = wndHandler:GetParent():GetData():GetHub()
	
	if hubArea then
		local tLocation = hubArea:GetLocation()
		if tLocation then
			local tNavPoint = GameLib.GetNavPoint()
			if tNavPoint and tNavPoint.tPosition.x ~= tLocation.x and tNavPoint.tPosition.y ~= tLocation.y and tNavPoint.tPosition.z ~= tLocation.z then
				self:ShowNavPointNotification(tLocation, hubArea)
			else
				self:ConfirmNavPointChange(tLocation, hubArea)
			end
		end
	end
end

function MatchMaker:ShowNavPointNotification(tLocation, hubSelected)
	local wndBlocker = self.tWndRefs.wndMain:FindChild("NavPointBlocker")
	wndBlocker:Show(true)
	wndBlocker:FindChild("PointSetMessage"):Show(false)
	
	local wndConfirm = wndBlocker:FindChild("PointChangeConfirm")
	wndConfirm:Show(true)
	wndConfirm:FindChild("MessageText"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_NavPointUpdate"), hubSelected:GetName()))

	wndConfirm:FindChild("SetPointConfirm"):SetData({tLocation = tLocation, hubSelected = hubSelected})
end

function MatchMaker:ConfirmNavPointChange(tLocation, hubShown)
	
	GameLib.SetNavPoint(tLocation, hubShown:GetSubZoneId())
	GameLib.ShowNavPointHintArrow()
	
	local wndNavUpdateText = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent:QuestContainer:NavUpdateMessageText")
	wndNavUpdateText:Show(true)
	wndNavUpdateText:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_NavPointSet"), hubShown:GetName()))
	self.tWndRefs.wndMain:FindChild("NavPointBlocker"):Show(false)
	self.timerNavPointNotification:Start()
	
	local tNavPoint = GameLib.GetNavPoint()
	if tNavPoint then
		Event_FireGenericEvent("ContentFinder_OpenMapToNavPoint", tNavPoint.nMapZoneId)
	end
end

function MatchMaker:OnNavPointConfirm(wndHandler, wndControl)
	local tInfo = wndHandler:GetData()
	self:ConfirmNavPointChange(tInfo.tLocation, tInfo.hubSelected)
end

function MatchMaker:HideNavPointNotification(wndHandler, wndControl)
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent:QuestContainer:NavUpdateMessageText"):Show(false)
	self.tWndRefs.wndMain:FindChild("NavPointBlocker"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Queue Info
-----------------------------------------------------------------------------------------------
function MatchMaker:OnSoloQueue()
	if #self.arMatchesToQueue > 0 then
		MatchingGame.Queue(self.arMatchesToQueue)
	end
end

function MatchMaker:OnGroupQueue()
	if #self.arMatchesToQueue > 0 then
		MatchingGame.QueueAsGroup(self.arMatchesToQueue)
	end
end

function MatchMaker:OnJoinQueue()
	if not self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus = Apollo.LoadForm(self.xmlDoc, "QueueWindow", nil, self)
		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndQueueStatus, strName = Apollo.GetString("MatchMaker_QueueInformation")})
	end
	
	self.arMatchesQueued = MatchingGame.GetQueuedMatches()
	local wndQueueType = Apollo.LoadForm(self.xmlDoc, "QueueType", self.tWndRefs.wndQueueStatus:FindChild("Inset:QueueContainer"), self)

	for idx = 1, #self.arMatchesQueued do
		local matchQueued = self.arMatchesQueued[idx]
		
		local wndMatch = Apollo.LoadForm(self.xmlDoc, "QueuedMatchEntry", wndQueueType:FindChild("InQueue:MatchList"), self)
		local wndMatchName = wndMatch:FindChild("MatchName")
		
		wndMatchName:SetText(matchQueued:GetName())
		nNameWidth, nNameHeight = wndMatchName:SetHeightToContentHeight()
		nLeft, nTop, nRight, nBottom = wndMatch:GetAnchorOffsets()
		wndMatch:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nNameHeight)
	end
	
	if MatchingGame.IsQueuedAsGroup() then
		self:OnUpdateGroupQueueStatus()
		self.tWndRefs.wndQueueStatus:FindChild("LeaveButton"):SetText(Apollo.GetString("MatchMaker_LeaveGroupQueue"))
	end
	
	local wndTypeExpand = wndQueueType:FindChild("ExpandButton")
	wndQueueType:FindChild("ExpandButton"):SetCheck(true)
	self:ToggleQueuedMatchList(wndTypeExpand, wndTypeExpand)
	
	self:OnQueueTimer()
	
	self.timerQueue:Set(1.0, true)
	self.timerQueue:Start()
	
	if self.tWndRefs.wndMain then
		self:ValidateQueueButtons()
	end
end

function MatchMaker:OnUpdateGroupQueueStatus()
	if not self.tWndRefs.wndQueueStatus then
		return
	end
	
	if MatchingGame.IsQueuedAsGroup() then
		self.tWndRefs.wndQueueStatus:FindChild("LeaveButton"):Enable(GroupLib.AmILeader())
	end
end

function MatchMaker:OnLeaveQueueBtn(wndHandler, wndControl)
	if MatchingGame.IsQueuedAsGroup() then
		MatchingGame.LeaveMatchingQueueAsGroup()
	elseif MatchingGame.IsQueuedForMatching() then
		MatchingGame.LeaveMatchingQueue()
	end
end

function MatchMaker:OnLeaveQueue()
	if self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus:Destroy()
		self.tWndRefs.wndQueueStatus = nil
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("MatchMaker_QueueInformation")})
	end
	
	self.timerQueue:Stop()
	
	if self.tWndRefs.wndMain then
		self:ValidateQueueButtons()
	end
	
	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Close()
	end
	
	if self.tWndRefs.wndConfirmRole then
		self.tWndRefs.wndConfirmRole:Close()
	end
end

function MatchMaker:ToggleQueuedMatchList(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndParent = wndHandler:GetParent()
	local wndQueueType = wndParent:GetParent()
	local wndQueueContainer = wndParent:FindChild("MatchList")
	
	local nOldHeight = wndQueueContainer:GetHeight()
	local nNewHeight = wndQueueContainer:ArrangeChildrenVert()	
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndQueueType:GetOriginalLocation():GetOffsets()
	
	local nNewBottom = nParentBottom + (nNewHeight - nOldHeight)
	if not wndHandler:IsChecked() then
		nNewBottom = nParentBottom
	end
	
	wndQueueType:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nNewBottom)
	
	wndQueueType:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:OnQueueTimer()
	if not self.tWndRefs.wndQueueStatus then
		return
	end
	
	local wndQueueType = self.tWndRefs.wndQueueStatus:FindChild("Inset:QueueContainer:QueueType")
	local fTimeInQueue = MatchingGame.GetTimeInQueue()
	
	if self.arMatchesQueued and self.arMatchesQueued[1] and self.arMatchesQueued[1]:GetType() then
		wndQueueType:FindChild("Title"):SetText(ktTypeNames[self.arMatchesQueued[1]:GetType()])
	end
	
	local nEstimatedWait = MatchingGame.GetAverageWaitTime()
	local strWaitTime = Apollo.GetString("MatchMaker_UnknownTimer")
	if nEstimatedWait > 0 then
		strWaitTime = ConvertSecondsToTimer(nEstimatedWait)
	end
	
	local strLabel = String_GetWeaselString(Apollo.GetString("MatchMaker_TimeLabel"), ConvertSecondsToTimer(fTimeInQueue))
	wndQueueType:FindChild("InQueue:QueueTimeLabel"):SetText(strLabel)
	
	if self.tWndRefs.wndMain then
		local strButtonLabel = String_GetWeaselString(Apollo.GetString("MatchMaker_QueueStatus"), ConvertSecondsToTimer(fTimeInQueue))
		self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:QueueControls:QueuedControls:OpenStatus"):SetText(strButtonLabel)
	end	

	local strTooltip = string.format("%s\n%s", String_GetWeaselString(Apollo.GetString("MatchMaker_TimeLabel"), ConvertSecondsToTimer(fTimeInQueue)), strLabel)
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("CRB_ContentFinder"), {true, strTooltip})
end

function MatchMaker:OnShowQueueStatus()
	if self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus:Invoke()
	end
end

function MatchMaker:OnCloseQueueStatus()
	if self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- Match Ready
-----------------------------------------------------------------------------------------------
function MatchMaker:OnGameReady(bInProgress)
	if self.tWndRefs.wndQueueStatus then
		self:OnLeaveQueue()
	end
	
	if self.tWndRefs.wndJoinGame then
		return
	end
	
	self.tWndRefs.wndJoinGame = Apollo.LoadForm(self.xmlDoc, "JoinGame", nil, self)
	local strMessage = Apollo.GetString("MatchMaker_Group")	

	self.tWndRefs.wndJoinGame:FindChild("YesButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.MatchingGameRespondToPending, true)
	self.tWndRefs.wndJoinGame:FindChild("NoButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.MatchingGameRespondToPending, false)
	
	self.arMatchesQueued = MatchingGame.GetQueuedMatches()
	local eType = self.arMatchesQueued and self.arMatchesQueued[1] and self.arMatchesQueued[1]:GetType()

	if eType == MatchingGame.MatchType.Adventure then
		Sound.Play(Sound.PlayUIQueuePopsAdventure)
		strMessage = Apollo.GetString("MatchMaker_Group")
	elseif eType == MatchingGame.MatchType.Dungeon or eType == MatchingGame.MatchType.Shiphand then
		Sound.Play(Sound.PlayUIQueuePopsDungeon)
		strMessage = Apollo.GetString("MatchMaker_Group")
	else
		Sound.Play(Sound.PlayUIQueuePopsPvP)
		strMessage = Apollo.GetString("MatchMaker_Match")
	end
	
	if self.arMatchesQueued and #self.arMatchesQueued == 1 then
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_FoundSpecific"), self.arMatchesQueued[1]:GetName(), strMessage)
	else
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_Found"), strMessage)
	end

	if bInProgress then
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_InProgress"), strMessage)
	end

	self.tWndRefs.wndJoinGame:FindChild("Title"):SetText(strMessage)
	
	local nJoinLeft, nJoinTop, nJoinRight, nJoinBottom = self.tWndRefs.wndJoinGame:GetAnchorOffsets()
	local nWarningHeight = self.tWndRefs.wndJoinGame:FindChild("RatedWarning"):GetHeight()
	nWarningHeight = nJoinTop > 0 and nWarningHeight or nWarningHeight * - 1
	self.tWndRefs.wndJoinGame:SetAnchorOffsets(nJoinLeft, ktRatedPvPTypes[eType] and nJoinTop or nJoinTop - nWarningHeight, nJoinRight, nJoinBottom)
	
	self.tWndRefs.wndJoinGame:Invoke()
end

-----------------------------------------------------------------------------------------------
-- Clean Up
-----------------------------------------------------------------------------------------------

function MatchMaker:OnClose()
	Event_FireGenericEvent("LFGWindowHasBeenClosed")
	
	self.timerNavPointNotification:Stop()
	
	self.arMatchesToQueue = {}
	if self.tWndRefs.wndMain then
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs.wndMain = nil
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("CRB_ContentFinder")})
	end

	self.tSuggestedInfo = nil
end

function MatchMaker:CleanUpAll()
	self.timerQueue:Stop()
	self.timerNavPointNotification:Stop()
	for strIndex, wndStored in pairs(self.tWndRefs) do
		wndStored:Destroy()
		self.tWndRefs[strIndex] = nil
	end
end

-----------------------------------------------------------------------------------------------
-- Join Game
-----------------------------------------------------------------------------------------------
function MatchMaker:OnJoinGameClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Destroy()
		self.tWndRefs.wndJoinGame = nil
	end
end

function MatchMaker:DisplayPendingInfo()
	if self.tWndRefs.wndJoinGame then
		return
	end

	local tPendingInfo = MatchingGame.GetPendingInfo()

	if tPendingInfo.nPendingEnemies and tPendingInfo.nPendingEnemies > 0 then
		if not self.tWndRefs.wndAllyEnemyConfirm then
			self.tWndRefs.wndAllyEnemyConfirm = Apollo.LoadForm(self.xmlDoc, "WaitingOnAlliesAndEnemies", nil, self)
		end

		self.tWndRefs.wndAllyEnemyConfirm:FindChild("AllyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedAllies, tPendingInfo.nPendingAllies))
		self.tWndRefs.wndAllyEnemyConfirm:FindChild("EnemyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedEnemies, tPendingInfo.nPendingEnemies))
		self.tWndRefs.wndAllyEnemyConfirm:Invoke()
	elseif tPendingInfo.nPendingAllies and tPendingInfo.nPendingAllies > 0 then
		if not self.tWndRefs.wndAllyConfirm then
			self.tWndRefs.wndAllyConfirm = Apollo.LoadForm(self.xmlDoc, "WaitingOnAllies", nil, self)
		end

		self.tWndRefs.wndAllyConfirm:FindChild("AllyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedAllies, tPendingInfo.nPendingAllies))
		self.tWndRefs.wndAllyConfirm:Invoke()
	else
		if self.tWndRefs.wndAllyEnemyConfirm then
			self.tWndRefs.wndAllyEnemyConfirm:Destroy()
			self.tWndRefs.wndAllyEnemyConfirm = nil
		end

		if self.tWndRefs.wndAllyConfirm then
			self.tWndRefs.wndAllyConfirm:Destroy()
			self.tWndRefs.wndAllyConfirm = nil
		end
	end
end

function MatchMaker:PendingGameCanceled()
	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Close()
	end
	
	if self.tWndRefs.wndAllyEnemyConfirm then
		self.tWndRefs.wndAllyEnemyConfirm:Destroy()
		self.tWndRefs.wndAllyEnemyConfirm = nil
	end

	if self.tWndRefs.wndAllyConfirm then
		self.tWndRefs.wndAllyConfirm:Destroy()
		self.tWndRefs.wndAllyConfirm = nil
	end
	
	if MatchingGame.IsQueuedForMatching() then
		self:OnJoinQueue()
	end
end

function MatchMaker:OnMatchEntered()
	self.eSelectedMasterType = keMasterTabs.Suggested
	self:CleanUpAll()
end

-----------------------------------------------------------------------------------------------
-- Role Check
-----------------------------------------------------------------------------------------------
function MatchMaker:OnRoleCheck()
	self.tWndRefs.wndConfirmRole = Apollo.LoadForm(self.xmlDoc, "RoleConfirm", nil, self)

	local tRoleCheckButtons =
	{
		[MatchingGame.Roles.Tank] 	= self.tWndRefs.wndConfirmRole:FindChild("TankBtn"),
		[MatchingGame.Roles.Healer] = self.tWndRefs.wndConfirmRole:FindChild("HealerBtn"),
		[MatchingGame.Roles.DPS] 	= self.tWndRefs.wndConfirmRole:FindChild("DPSBtn"),
	}

	for eRole, wndButton in pairs(tRoleCheckButtons) do
		wndButton:Enable(false)
		wndButton:SetData(eRole)
	end

	for idx, eRole in pairs(MatchingGame.GetEligibleRoles()) do
		tRoleCheckButtons[eRole]:Enable(true)
	end

	local arSelectedRoles = MatchingGame.GetSelectedRoles()
	for idx, eRole in pairs(arSelectedRoles) do
		tRoleCheckButtons[eRole]:SetCheck(true)
	end
	
	self.tWndRefs.wndConfirmRole:FindChild("AcceptButton"):Enable(#arSelectedRoles > 0)
end

function MatchMaker:OnRoleCheckHidden()
	if self.tWndRefs.wndConfirmRole == nil then
		return
	end

	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnRoleCheckClosed()
	self.tWndRefs.wndConfirmRole:Destroy()
	self.tWndRefs.wndConfirmRole = nil
end

function MatchMaker:OnAcceptRole()
	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	if tSelectedRoles == nil then
		return
	end

	MatchingGame.ConfirmRole()
	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnCancelRole()
	MatchingGame.DeclineRoleCheck()
end

function MatchMaker:OnToggleRoleCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	MatchingGame.SelectRole(wndHandler:GetData(), wndHandler:IsChecked())

	local tSelectedRoles = MatchingGame.GetSelectedRoles()
	self.tWndRefs.wndConfirmRole:FindChild("AcceptButton"):Enable(#tSelectedRoles > 0)
end

-----------------------------------------------------------------------------------------------
-- In Match Functionality
-----------------------------------------------------------------------------------------------

function MatchMaker:OnLeaveGroupBtn(wndHandler, wndControl)
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

-----------------------------------------------------------------------------------------------
-- Voting
-----------------------------------------------------------------------------------------------
function MatchMaker:OnVoteDisbandBtn( wndHandler, wndControl, eMouseButton )
	MatchingGame.InitiateVoteToSurrender()
	self:UpdateInMatchControls()
end

function MatchMaker:OnVoteSurrenderBegin()
	if not self.tWndRefs.wndVoteSurrender or not self.tWndRefs.wndVoteSurrender:IsValid() then
		self.tWndRefs.wndVoteSurrender = Apollo.LoadForm(self.xmlDoc, "VoteSurrender", nil, self)
	end
	self.tWndRefs.wndVoteSurrender:Invoke()
	
	if MatchingGame.IsInPVPGame() then
		self.tWndRefs.wndVoteSurrender:FindChild("Title"):SetText(Apollo.GetString("MatchMaker_VoteSurrender"))
	else
		self.tWndRefs.wndVoteSurrender:FindChild("Title"):SetText(Apollo.GetString("MatchMaker_VoteDisband"))
	end
	
	self:UpdateInMatchControls()
end

function MatchMaker:OnVoteSurrenderEnd()
	if self.tWndRefs.wndVoteSurrender then
		self.tWndRefs.wndVoteSurrender:Close()
	end
	
	self:UpdateInMatchControls()
end

function MatchMaker:OnVoteSurrenderYes(wndHandler, wndControl)
	MatchingGame.CastVoteSurrender(true)
	self.tWndRefs.wndVoteSurrender:Close()
end

function MatchMaker:OnVoteSurrenderNo(wndHandler, wndControl)
	MatchingGame.CastVoteSurrender(false)
	self.tWndRefs.wndVoteSurrender:Close()
end

function MatchMaker:OnVoteSurrenderClosed(wndHandler, wndControl)
	self.tWndRefs.wndVoteSurrender:Destroy()
	self.tWndRefs.wndVoteSurrender = nil
end

function MatchMaker:OnVoteKickBegin(tPlayerInfo)
	if not self.tWndRefs.wndVoteKick or not self.tWndRefs.wndVoteKick:IsValid() then
		self.tWndRefs.wndVoteKick = Apollo.LoadForm(self.xmlDoc, "VoteKick", nil, self)
	end
	self.tWndRefs.wndVoteKick:Invoke()
	
	self.tWndRefs.wndVoteKick:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_VoteKick"), tPlayerInfo.strCharacterName))
end

function MatchMaker:OnVoteKickEnd()
	if self.tWndRefs.wndVoteKick then
		self.tWndRefs.wndVoteKick:Close()
	end
end

function MatchMaker:OnVoteKickYes(wndHandler, wndControl)
	MatchingGame.CastVoteKick(true)
	self.tWndRefs.wndVoteKick:Close()
end

function MatchMaker:OnVoteKickNo(wndHandler, wndControl)
	MatchingGame.CastVoteKick(false)
	self.tWndRefs.wndVoteKick:Close()
end

function MatchMaker:OnVoteKickClosed(wndHandler, wndControl)
	self.tWndRefs.wndVoteKick:Destroy()
	self.tWndRefs.wndVoteKick = nil
end

-----------------------------------------------------------------------------------------------
-- PvP Teams
-----------------------------------------------------------------------------------------------
function MatchMaker:OnUpdateGuilds()
	if not GameLib.GetPlayerUnit() then
		return
	end

	local arGuilds = GuildLib.GetGuilds()
	self.tHasGuild = {}
	
	for idx, guildCurr in pairs(arGuilds) do
		self.tHasGuild[guildCurr:GetType()] = guildCurr
	end
	
	self:UpdateTeamInfo()
	if self.tWndRefs.wndMain and self.matchDisplayed then
		local eMatchType = self.matchDisplayed:GetType()
		if eMatchType == MatchingGame.MatchType.Arena then
			self:BuildArenaControls()
		elseif eMatchType == MatchingGame.MatchType.Warplot then
			self:BuildWarplotControls()
		end
	end
end

function MatchMaker:OnTeamInfoBtn(wndHandler, wndControl)
	local eGuildType = wndControl:GetData()

	if eGuildType ~= nil then
		-- Position
		local tScreen = Apollo.GetDisplaySize()
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndMain:GetAnchorOffsets()
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

		if eGuildType == GuildLib.GuildType_WarParty then
			if self.tHasGuild[eGuildType] then
				Event_FireGenericEvent("Event_ShowWarpartyInfo", tPos)
			else
				Event_FireGenericEvent("GenericEvent_RegisterWarparty", tPos)
			end
		else
			if self.tHasGuild[eGuildType] then
				Event_FireGenericEvent("Event_ShowArenaInfo", eGuildType, tPos)
			else
				Event_FireGenericEvent("GenericEvent_RegisterArenaTeam", eGuildType, tPos)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- MatchMakerForm Functions
-----------------------------------------------------------------------------------------------

function MatchMaker:OnPendingGameResponded(wndHandler, wndControl, bResponse)
	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- Dueling
-----------------------------------------------------------------------------------------------

function MatchMaker:OnAcceptDuel(wndHandler, wndControl)
	GameLib.AcceptDuel()
	if self.tWndRefs.wndDuelRequest then
		self.tWndRefs.wndDuelRequest:Destroy()
		self.tWndRefs.wndDuelRequest = nil
	end
end

function MatchMaker:OnDeclineDuel(wndHandler, wndControl)
	GameLib.DeclineDuel()
	if self.tWndRefs.wndDuelRequest then
		self.tWndRefs.wndDuelRequest:Destroy()
		self.tWndRefs.wndDuelRequest = nil
	end
end

function MatchMaker:OnDuelStateChanged(eNewState, unitOpponent)
	
	if self.tWndRefs.wndDuelWarning then
		self.tWndRefs.wndDuelWarning:Destroy()
		self.tWndRefs.wndDuelWarning = nil
	end
	
	if eNewState == GameLib.CodeEnumDuelState.WaitingToAccept then
		if not self.tWndRefs.wndDuelRequest then
			self.tWndRefs["wndDuelRequest"] = Apollo.LoadForm(self.xmlDoc, "DuelRequest", nil, self)
		end
		self.tWndRefs.wndDuelRequest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_DuelPrompt"), unitOpponent:GetName()))
		self.tWndRefs.wndDuelRequest:Show(true)
		self.tWndRefs.wndDuelRequest:ToFront()
	else
		if self.tWndRefs.wndDuelRequest then
			self.tWndRefs.wndDuelRequest:Destroy()
			self.tWndRefs.wndDuelRequest = nil
		end
	end
	
end

function MatchMaker:OnDuelAccepted(fCountdownTime)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, String_GetWeaselString(Apollo.GetString("MatchMaker_DuelStartingTimer"), fCountdownTime), "")
	self.fDuelCountdown = fCountdownTime - 1

	self.timerDuelCountdown:Start()
end

function MatchMaker:OnDuelCountdownTimer()
	if self.fDuelCountdown <= 0 then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, Apollo.GetString("Matchmaker_DuelBegin"), "")
		self.timerDuelCountdown:Stop()
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, self.fDuelCountdown .. "...", "")
		self.fDuelCountdown = self.fDuelCountdown - 1
	end
end

function MatchMaker:OnDuelLeftArea(fTimeRemaining)
	if not self.tWndRefs.wndDuelWarning then
		self.tWndRefs["wndDuelWarning"] = Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
	end
	self.tWndRefs.wndDuelWarning:FindChild("Timer"):SetText(fTimeRemaining)
	self.tWndRefs.wndDuelWarning:Show(true)
	self.tWndRefs.wndDuelWarning:ToFront()
	self.fDuelWarning = fTimeRemaining -1
	
	self.timerDuelRangeWarning:Start()
end

function MatchMaker:OnDuelWarningTimer()
	if self.fDuelWarning <= 0 then
		if self.tWndRefs.wndDuelWarning then
			self.tWndRefs.wndDuelWarning:Destroy()
			self.tWndRefs.wndDuelWarning = nil
			self.timerDuelRangeWarning:Stop()
		end
	else
		if not self.tWndRefs.wndDuelWarning then
			self.tWndRefs["wndDuelWarning"] = Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
		end
		self.tWndRefs.wndDuelWarning:FindChild("Timer"):SetText(self.fDuelWarning)
		self.fDuelWarning = self.fDuelWarning - 1
	end
end

function MatchMaker:OnDuelCancelWarning()
	if self.tWndRefs.wndDuelWarning then
		self.tWndRefs.wndDuelWarning:Destroy()
		self.tWndRefs.wndDuelWarning = nil
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------

function MatchMaker:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.GroupFinder] = true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.GroupFinder] = self.tWndRefs.wndMain,
	}

	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

---------------------------------------------------------------------------------------------------
--Store Updates
---------------------------------------------------------------------------------------------------
function MatchMaker:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:UpdateTeamInfo()
end

function MatchMaker:OnUnlockBtn()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function MatchMaker:OnGenerateSignatureTooltip(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Tooltip.GetSignatureTooltipForm(self, wndControl, Apollo.GetString("MatchMaker_CreateATeam"))
end

-----------------------------------------------------------------------------------------------
-- Handlers for events from other addons
-----------------------------------------------------------------------------------------------
function MatchMaker:OnOpenContentFinderToUnlock(eLevelUpUnlockType, eLevelUpUnlock, nObjectId)
	if not self.tWndRefs.wndMain then
		self:OnMatchMakerOn()
	end
	
	local eMatchType = ktLevelUpUnlockToMatchTypes[eLevelUpUnlockType]
	local tMatchData = nil
	
	if ktRatedToNormal[eMatchType] then
		eMatchType = ktRatedToNormal[eMatchType]
	end
	
	-- find match data
	if self.tMatchList[eMatchType] then
		for idx, tMatch in pairs(self.tMatchList[eMatchType]) do
			if tMatch.matchNormal and tMatch.matchNormal:GetGameId() == nObjectId then
				self.matchDisplayed = tMatch.matchNormal
				self.ePvETabSelected = eType
				tMatchData = tMatch
				break
			elseif tMatch.matchVet and tMatch.matchVet:GetGameId() == nObjectId then
				self.matchDisplayed = tMatch.matchVet
				self.ePvPTabSelected = eType
				tMatchData = tMatch
				break
			end
		end
	end
	
	local wndPvEBtn = self.tWndRefs.wndMain:FindChild("PvEBtn")
	local wndPvPBtn = self.tWndRefs.wndMain:FindChild("PvPBtn")
	
	self.tWndRefs.wndMain:FindChild("SuggestedBtn"):SetCheck(false)
	wndPvEBtn:SetCheck(ktPvETypes[eMatchType])
	wndPvPBtn:SetCheck(not ktPvETypes[eMatchType])
		
	if ktPvETypes[eMatchType] then
		self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
	else
		self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
	end
end

function MatchMaker:OnShowContentFinder()
	if not self.tWndRefs.wndMain then
		self:OnMatchMakerOn()
	end
end

function MatchMaker:LinkToStore()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

---------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- MatchMaker Instance
-----------------------------------------------------------------------------------------------
local MatchMakerInst = MatchMaker:new()
MatchMakerInst:Init()