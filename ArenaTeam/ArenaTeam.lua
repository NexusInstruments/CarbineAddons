-----------------------------------------------------------------------------------------------
-- Client Lua Script for Arena Team
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GuildLib"
require "GuildTypeLib"
require "GroupLib"
require "GameLib"

local ArenaTeam = {}

local ktTeamTypeToString =
{
	[GuildLib.GuildType_ArenaTeam_2v2] = Apollo.GetString("ArenaRoster_2v2"),
	[GuildLib.GuildType_ArenaTeam_3v3] = Apollo.GetString("ArenaRoster_3v3"),
	[GuildLib.GuildType_ArenaTeam_5v5] = Apollo.GetString("ArenaRoster_5v5"),
}

function ArenaTeam:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	self.eCurrentType = nil

    return o
end

function ArenaTeam:Init()
    Apollo.RegisterAddon(self)
end

function ArenaTeam:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ArenaTeam.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function ArenaTeam:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	-- Registering events with Apollo
	Apollo.RegisterEventHandler("Event_ShowArenaInfo", 				"OnShowArenaInfo", self)
	Apollo.RegisterEventHandler("GuildInvite", 						"OnGuildInvite", self)  -- notification you got a guild/circle invite
	Apollo.RegisterEventHandler("GuildResult", 						"OnGuildResult", self)  -- notification about an action that occured with the guild (Likely from self)
	Apollo.RegisterEventHandler("GuildRoster", 						"OnGuildRoster", self)  -- notification that a guild roster was recieved.
	Apollo.RegisterEventHandler("GuildLoaded", 						"OnGuildLoaded", self)  -- notification that your guild has loaded.
	Apollo.RegisterEventHandler("GuildPvp", 						"OnGuildPvp", self) -- notification that the pvp standings of the guild has changed.	
	Apollo.RegisterEventHandler("GuildMemberChange", 				"OnGuildMemberChange", self)  -- General purpose update method
	Apollo.RegisterEventHandler("GenericEvent_RegisterArenaTeam", 	"OnClose", self)
	
	self.timerArenaTeamUpdate = ApolloTimer.Create(30.0, true, "RequestUpdate", self)
	self.timerArenaTeamUpdate:Stop()

	-- loading windows
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ArenaTeamForm", nil, self)
	self.wndMain:Show(false, true)

	Apollo.RegisterEventHandler("WindowManagementReady", 			"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function ArenaTeam:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {wnd = self.wndMain, strName = Apollo.GetString("Guild_GuildTypeArena"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Guild_GuildTypeArena"), nSaveVersion=2})
end

function ArenaTeam:OnClose()
	self.eCurrentType = nil
	self.timerArenaTeamUpdate:Stop()
	self.wndMain:Close()
end

function ArenaTeam:RequestUpdate()
	if self.wndMain and self.wndMain:IsShown() then
		self.wndMain:GetData():RequestMembers()
	end
end

-----------------------------------------------------------------------------------------------
-- ArenaTeam Functions
-----------------------------------------------------------------------------------------------
function ArenaTeam:OnShowArenaInfo(eTeamType, tPos)
	
	-- Clear the window so we can reset the info
	self.wndMain:FindChild("RosterGrid"):DeleteAll() 
	
	
	local strType = ktTeamTypeToString[eTeamType]
	
	if not strType then
		self.wndMain:Show(false)
		return
	end
	
	self.eCurrentType = eTeamType

	-- Setting the header info
	local bGuildTableIsEmpty = true
	local strPlayerName = GameLib.GetPlayerUnit():GetName()
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == eTeamType then
			local strRank = Apollo.GetString("ArenaRoster_RankMember")			
			if guildCurr:GetMyRank() == 1 then
				strRank = Apollo.GetString("ArenaRoster_RankLeader")
			end
			self.wndMain:FindChild("SubHeader"):SetText(String_GetWeaselString(Apollo.GetString("ArenaRoster_SubHeader"), strType ,strRank))
			self.wndMain:FindChild("Header"):SetText(guildCurr:GetName())
			self.wndMain:SetData(guildCurr)
			self:UpdatePvpRating()
			guildCurr:RequestMembers()		

			-- Sets the roster window's position
			local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
			
			self.wndMain:Show(true)
			self.wndMain:ToFront()
			self.timerArenaTeamUpdate:Start()
			return
		end
	end
	-- you're not on a team
	self.wndMain:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Bottom Panel Roster Actions
-----------------------------------------------------------------------------------------------

function ArenaTeam:ResetRosterMemberButtons(bPreventClose)
	local wndRemoveBtn = self.wndMain:FindChild("RosterOptionBtnRemove")
	local wndDisband = self.wndMain:FindChild("RosterDisbandBtn")
	local wndLeave = self.wndMain:FindChild("RosterLeaveBtn")
	local wndAdd = self.wndMain:FindChild("RosterOptionBtnAdd")
	local wndInvite = self.wndMain:FindChild("RosterOptionBtnInvite")
	
	if not bPreventClose then
		self.wndMain:FindChild("AddMemberContainer"):Close()
		self.wndMain:FindChild("RemoveMemberContainer"):Close()
		self.wndMain:FindChild("DisbandContainer"):Close()
		self.wndMain:FindChild("LeaveContainer"):Close()
	end
	
	-- Defaults
	wndAdd:Show(false)
	wndRemoveBtn:Show(false)

	wndLeave:Show(true)
	wndInvite:Show(true)
	wndDisband:Show(false)
	
	-- Setting buttons based on rank and selected member
	local guildCurr = self.wndMain:FindChild("AddMemberEditBox"):GetData()
	if guildCurr and guildCurr:GetMyRank() then
		local wndRoster = self.wndMain:FindChild("RosterGrid")
		local tMyRankPermissions = guildCurr:GetRanks()[guildCurr:GetMyRank()]
		local bSomeRowIsPicked = wndRoster:GetCurrentRow()
		local tSelected = wndRoster:GetData()
		local bTargetIsUnderMyRank = bSomeRowIsPicked and guildCurr:GetMyRank() < tSelected.nRank
		local bValidUnit = bSomeRowIsPicked and tSelected.fLastOnline == 0 and tSelected.strName ~= GameLib.GetPlayerUnit():GetName()
		
		wndRemoveBtn:Enable(bSomeRowIsPicked and bTargetIsUnderMyRank)

		wndAdd:Show(tMyRankPermissions and tMyRankPermissions.bInvite)
		wndRemoveBtn:Show(tMyRankPermissions and tMyRankPermissions.bKick)

		wndDisband:Show(guildCurr:GetMyRank() == 1)
		wndLeave:Show(guildCurr:GetMyRank() ~= 1)
	
		local bCanInvite = not GroupLib.InGroup() or GroupLib.AmILeader() or GroupLib.GetGroupMember(1).bCanInvite
		wndInvite:Enable(bValidUnit and bCanInvite)	
	end
	
end

-- The buttons
function ArenaTeam:OnRosterAddMemberClick(wndHandler, wndControl)
	self:ResetRosterMemberButtons()
	if wndHandler:IsChecked() then
		self.wndMain:FindChild("AddMemberContainer"):Invoke()
		self.wndMain:FindChild("AddMemberEditBox"):SetFocus()
	else
		self.wndMain:FindChild("AddMemberContainer"):Close()
	end
end

function ArenaTeam:OnRosterRemoveMemberClick(wndHandler, wndControl)
	self:ResetRosterMemberButtons()
	local wndContainer = wndHandler:FindChild("RemoveMemberContainer")
	if wndHandler:IsChecked() then
		wndContainer:Invoke()
		wndContainer:FindChild("RemoveMemberLabel"):SetText(String_GetWeaselString(Apollo.GetString("ArenaRoster_KickLabel"), self.wndMain:FindChild("RosterGrid"):GetData().strName))
	else
		wndContainer:Close()
	end
end

-- The Pop Up Bubbles
function ArenaTeam:OnRosterAddMemberCloseBtn() -- The Window Close Event can also route here
	self.wndMain:FindChild("AddMemberEditBox"):SetText("")
	self.wndMain:FindChild("AddMemberContainer"):Close()
	self.wndMain:FindChild("RosterOptionBtnAdd"):SetCheck(false)
end

function ArenaTeam:OnRosterRemoveMemberCloseBtn()
	self.wndMain:FindChild("RemoveMemberContainer"):Close()
	self.wndMain:FindChild("RosterOptionBtnRemove"):SetCheck(false)
end

function ArenaTeam:OnRosterRemoveMemberYesClick(wndHandler, wndControl)
	if wndHandler and wndHandler:GetData() then -- wndHandler is 'RemoveMemberYesBtn' with data guildCurr
		wndHandler:GetData():Kick(self.wndMain:FindChild("RosterGrid"):GetData().strName)
	end
	self:OnRosterRemoveMemberCloseBtn()
end

function ArenaTeam:OnAddMemberEditBoxReturn(wndHandler, wndControl, strText)
	if wndHandler and wndHandler:GetData() and string.len(strText) > 0 then -- wndHandler is 'AddMemberEditBox' with data guildCurr
		-- TODO: Additional string validation
		wndHandler:GetData():Invite(strText)
	end
	self:OnRosterAddMemberCloseBtn()
end

function ArenaTeam:OnAddMemberConfirmBtn(wndHandler, wndControl)
	local wndEditBox = wndHandler:GetParent():FindChild("AddMemberEditBox")
	if wndHandler and wndEditBox then

		if wndEditBox and wndEditBox:GetData() and string.len(wndEditBox:GetText()) > 0 then
			-- TODO: Additional string validation
			wndEditBox:GetData():Invite(wndEditBox:GetText())
		end
	end
	self:OnRosterAddMemberCloseBtn()
end

-- Disband/Leave functions
function ArenaTeam:OnConfirmDisbandBtn(wndHandler, wndControl)
	if wndHandler and wndHandler:GetData() then
		wndHandler:GetData():Disband()
	end
end

function ArenaTeam:OnDisbandContainerCloseBtn(wndHandler, wndControl)
	local wndDisband = self.wndMain:FindChild("RosterDisbandBtn")
	wndDisband:FindChild("DisbandContainer"):Show(false)
	wndDisband:SetCheck(false)
end

function ArenaTeam:OnConfirmLeaveBtn(wndHandler, wndControl)
	if wndHandler and wndHandler:GetData() then
		wndHandler:GetData():Leave()
	end
	self:OnLeaveContainerCloseBtn()
end

function ArenaTeam:OnLeaveContainerCloseBtn(wndHandler, wndControl)
	local wndLeave = self.wndMain:FindChild("RosterLeaveBtn")
	wndLeave:FindChild("LeaveContainer"):Show(false)
	wndLeave:SetCheck(false)
end

function ArenaTeam:OnRosterLeaveBtn(wndHandler, wndControl)
	self:ResetRosterMemberButtons()
	wndControl:FindChild("LeaveContainer"):Invoke()
end

function ArenaTeam:OnRosterDisbandBtn(wndHandler, wndControl)
	self:ResetRosterMemberButtons()
	wndControl:FindChild("DisbandContainer"):Invoke()
end

function ArenaTeam:OnInviteToGroupClick(wndHandler, wndControl)
	self:ResetRosterMemberButtons()
	local wndRoster = self.wndMain:FindChild("RosterGrid")
	local tSelected = wndRoster:GetData()
	
	if wndRoster:GetCurrentRow() and tSelected ~= nil then
		GroupLib.Invite(tSelected.strName)
	end
end

-----------------------------------------------------------------------------------------------
-- Roster Methods -- TODO: Move this into its own addon if it gets too large
-----------------------------------------------------------------------------------------------

function ArenaTeam:OnGuildRoster(guildCurr, tRoster)
	if guildCurr ~= self.wndMain:GetData() or #tRoster == 0 then 
		return
	end

	local tRanks = guildCurr:GetRanks()
	local wndGrid = self.wndMain:FindChild("RosterGrid")
	
	wndGrid:DeleteAll()
	
	-- TODO: enums
	local nSlots = 0 -- default is 2v2	
	local nSlotsMax = 3 -- default is 2v2
	if guildCurr:GetType() == GuildLib.GuildType_ArenaTeam_3v3 then
		nSlotsMax = 5
	elseif guildCurr:GetType() == GuildLib.GuildType_ArenaTeam_5v5 then
		nSlotsMax = 9
	end	

	for key, tCurr in pairs(tRoster) do
		local strIcon = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisibleNormal"
		if tCurr.nRank == 1 then -- Special icons for team leader
			strIcon = "CRB_Basekit:kitIcon_Holo_Profile"
		elseif tCurr.nRank == 2 then
			strIcon = "CRB_Basekit:kitIcon_Holo_Actions"
		end
		
		-- TODO: This should be an enum
		-- Setting class icons
		local strSpriteToUse = "CRB_GroupSprites:sprGrp_MFrameIcon_Axe"
		
		if tCurr.strClass == Apollo.GetString("ClassWarrior") then 
			strSpriteToUse = "Icon_Windows_UI_CRB_Warrior"
		elseif tCurr.strClass == Apollo.GetString("ClassEngineer") then 
			strSpriteToUse = "Icon_Windows_UI_CRB_Engineer"
		elseif tCurr.strClass == Apollo.GetString("ClassESPER") then 
			strSpriteToUse = "Icon_Windows_UI_CRB_Esper"
		elseif tCurr.strClass == Apollo.GetString("ClassMedic") then 
			strSpriteToUse = "Icon_Windows_UI_CRB_Medic"
		elseif tCurr.strClass == Apollo.GetString("ClassStalker") then 
			strSpriteToUse = "Icon_Windows_UI_CRB_Stalker"
		elseif tCurr.strClass == Apollo.GetString("ClassSpellslinger") then 
			strSpriteToUse = "Icon_Windows_UI_CRB_Spellslinger"
		end		
		

		local iCurrRow = wndGrid:AddRow("")
		local strFormatting = "<T Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">%s</T>" -- online 
		if tCurr.fLastOnline ~= 0 then -- offline
			strFormatting = "<T Font=\"CRB_InterfaceSmall\" TextColor=\"ff2f94ac\">%s</T>" 
		end
		
		-- Build the character's entry
		wndGrid:SetCellLuaData(iCurrRow, 1, tCurr)
		wndGrid:SetCellImage(iCurrRow, 1, strIcon)
		wndGrid:SetCellDoc(iCurrRow, 2, string.format(strFormatting, tCurr.strName))
		wndGrid:SetCellImage(iCurrRow, 3, strSpriteToUse)
		wndGrid:SetCellDoc(iCurrRow, 4, string.format(strFormatting, self:HelperConvertToTime(tCurr.fLastOnline)))	

		nSlots = nSlots+1		
	end
	
	-- Mark all the empty spots on the team
	if nSlotsMax - nSlots > 0 then
		for idx = 1, nSlotsMax - nSlots do
			local iCurrRow = wndGrid:AddRow("")
			wndGrid:SetCellDoc(iCurrRow, 2, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"ff237083\">%s</T>", Apollo.GetString("ArenaRoster_EmptySlot")))
			wndGrid:EnableRow(iCurrRow, false)
		end
	end
	
	-- Fill the rest of the space with blanks
	if 10 - nSlotsMax > 0 then
		for idx = nSlotsMax + 1, 10 do
			local iCurrRow = wndGrid:AddRow("")
			wndGrid:EnableRow(iCurrRow, false)
		end
	end	
	
	-- Setting child window data to the current guild
	self.wndMain:FindChild("AddMemberEditBox"):SetData(guildCurr)
	self.wndMain:FindChild("RemoveMemberYesBtn"):SetData(guildCurr)

	
	self.wndMain:FindChild("RosterLeaveBtn"):FindChild("ConfirmLeaveBtn"):SetData(guildCurr)
	self.wndMain:FindChild("RosterDisbandBtn"):FindChild("ConfirmDisbandBtn"):SetData(guildCurr)
	
	-- Set true to krevent closing to keep container open while members come online/offline
	self:ResetRosterMemberButtons(true)
	
	-- Maintain the state of the AddMemberContainer if already opened
	if self.wndMain:FindChild("RosterOptionBtnAdd"):IsChecked() then
		local wndAddMemberEditBox = self.wndMain:FindChild("AddMemberEditBox")
		local nStringLen = string.len(wndAddMemberEditBox:GetText())
		wndAddMemberEditBox:SetSel(nStringLen, nStringLen)
		self.wndMain:FindChild("AddMemberContainer"):Show(true)
	end
end

function ArenaTeam:OnRosterGridItemClick(wndControl, wndHandler, iRow, iCol)
	local wndRoster = self.wndMain:FindChild("RosterGrid")
	local wndData = wndRoster:GetCellData(iRow, 1)
	
	-- Deselect the item if it was already selected
	if wndRoster:GetData() == wndData then
		wndRoster:SetData(nil)
		wndRoster:SetCurrentRow(0)
	else
		wndRoster:SetData(wndData)
	end

	self:ResetRosterMemberButtons()
end

function ArenaTeam:OnGuildPvp(guildSelected)
	if guildSelected == self.wndMain:GetData() then
		self:UpdatePvpRating()
	end
end

function ArenaTeam:UpdatePvpRating()
	local guildSelected = self.wndMain:GetData()
	if guildSelected == nil then
		return
	end
	
	local tPvpRatings = guildSelected:GetPvpRatings()
	if tPvpRatings == nil then
		return
	end
	
	self.wndMain:FindChild("Header"):SetText(String_GetWeaselString(Apollo.GetString("Warparty_Rating"), guildSelected:GetName(), tPvpRatings.nRating))
end

-----------------------------------------------------------------------------------------------
-- ArenaTeam Invite Window
-----------------------------------------------------------------------------------------------

function ArenaTeam:OnGuildInvite( strGuildName, strInvitorName, eGuildType )
	-- Defining text on the arena team invite
	if not ktTeamTypeToString[eGuildType] then
		return
	end
	
	local strType = ktTeamTypeToString[eGuildType]
	self.wndArenaTeamInvite = Apollo.LoadForm(self.xmlDoc, "ArenaTeamInviteConfirmation", nil, self)

	self.wndArenaTeamInvite:FindChild("ArenaTeamInviteLabel"):SetText(String_GetWeaselString(Apollo.GetString("ArenaRoster_InviteHeader"), strType, strGuildName, strInvitorName))
	self.wndArenaTeamInvite:Invoke()
end

function ArenaTeam:OnArenaTeamInviteAccept(wndHandler, wndControl)
	GuildLib.Accept()
	if self.wndArenaTeamInvite then
		self.wndArenaTeamInvite:Destroy()
	end
end

function ArenaTeam:OnReportArenaInviteSpamBtn(wndHandler, wndControl)
	Event_FireGenericEvent("GenericEvent_ReportPlayerArenaInvite")
	self.wndArenaTeamInvite:Destroy()
end

function ArenaTeam:OnDecline()
	GuildLib.Decline()
	if self.wndArenaTeamInvite then
		self.wndArenaTeamInvite:Destroy()
	end
end

-----------------------------------------------------------------------------------------------
-- Feedback Messages
-----------------------------------------------------------------------------------------------

function ArenaTeam:OnGuildMemberChange(guildCurr)
	if (guildCurr:GetType() == self.eCurrentType) and self.wndMain:IsShown() then
		self.wndMain:Show(false)
		self:OnShowArenaInfo(guildCurr:GetType())
	end
end

function ArenaTeam:OnGuildResult( guildTeam, strName, nRank, eResult )
	if guildTeam == nil or not guildTeam:IsArenaTeam() then
		return
	end
	
	if self.wndMain:IsShown() then -- TODO: TEMP, request members again on an update
		guildTeam:RequestMembers()
	end
	
	-- Reload UI when the player's status in the team changes
	if guildTeam and (guildTeam:GetType() == self.eCurrentType) then
		if eResult == GuildLib.GuildResult_YouJoined then
			self.wndMain:Show(false)
			self:OnShowArenaInfo(guildTeam:GetType())
		elseif eResult == GuildLib.GuildResult_YouQuit or eResult == GuildLib.GuildResult_KickedYou or eResult == GuildLib.GuildResult_GuildDisbanded then
			self.wndMain:Show(false)
		end
	end
end

function ArenaTeam:HelperConvertToTime(nDays)
	if nDays == 0 then 
		return Apollo.GetString("ArenaRoster_Online") 
	end 
	
	if nDays == nil then 
		return "" 
	end

	local tTimeInfo = {["name"] = "", ["count"] = nil}
	
	if nDays >= 365 then -- Years
		tTimeInfo["name"] = Apollo.GetString("CRB_Year")
		tTimeInfo["count"] = math.floor(nDays / 365)
	elseif nDays >= 30 then -- Months
		tTimeInfo["name"] = Apollo.GetString("CRB_Month")
		tTimeInfo["count"] = math.floor(nDays / 30)
	elseif nDays >= 7 then
		tTimeInfo["name"] = Apollo.GetString("CRB_Week")
		tTimeInfo["count"] = math.floor(nDays / 7)
	elseif nDays >= 1 then -- Days
		tTimeInfo["name"] = Apollo.GetString("CRB_Day")
		tTimeInfo["count"] = math.floor(nDays)
	else
		local fHours = nDays * 24
		local nHoursRounded = math.floor(fHours)
		local nMin = math.floor(fHours*60)
		
		if nHoursRounded > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Hour")
			tTimeInfo["count"] = nHoursRounded
		elseif nMin > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = nMin	
		else
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = 1
		end
	end
	
	return String_GetWeaselString(Apollo.GetString("CRB_TimeOffline"), tTimeInfo)
end

-----------------------------------------------------------------------------------------------
-- ArenaTeam Instance
-----------------------------------------------------------------------------------------------
local ArenaTeamInst = ArenaTeam:new()
ArenaTeamInst:Init()
