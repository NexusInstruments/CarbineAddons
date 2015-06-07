-----------------------------------------------------------------------------------------------
-- Client Lua Script for CRB_ProgressLog
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"

local CRB_ProgressLog = {}

function CRB_ProgressLog:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CRB_ProgressLog:Init()
    Apollo.RegisterAddon(self)
end

function CRB_ProgressLog:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CRB_ProgressLog.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function CRB_ProgressLog:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)

	Apollo.RegisterEventHandler("ToggleCodex", "OnCRB_ProgressLogOn", self)
	Apollo.RegisterEventHandler("ToggleQuestLog", "ToggleQuestLog", self)
	Apollo.RegisterEventHandler("ToggleProgressLog", "OnCRB_ProgressLogOn", self)
	Apollo.RegisterEventHandler("ToggleChallengesWindow", "ToggleChallenges", self)
	Apollo.RegisterEventHandler("ToggleAchievementWindow", "ToggleAchievements", self)

	Apollo.RegisterEventHandler("ShowQuestLog", "ToggleQuestLogFromCall", self)
	Apollo.RegisterEventHandler("FloatTextPanel_ToggleAchievementWindow", "ToggleAchievementsWithData", self)
	Apollo.RegisterEventHandler("PlayerPathShow", "TogglePlayerPath", self)
	Apollo.RegisterEventHandler("PlayerPathShow_NoHide", "ShowPlayerPath", self )
	Apollo.RegisterEventHandler("ChallengesShow_NoHide", "ShowChallenges", self )

    g_wndProgressLog = Apollo.LoadForm(self.xmlDoc, "CRB_ProgressLogForm", nil, self)
	g_wndProgressLog:Show(false, true)

	self.xmlDoc = nil
	if self.locSavedLocation then
		g_wndProgressLog:MoveToLocation(self.locSavedLocation)
	end
    self.wndOptions = g_wndProgressLog:FindChild("FilterContainer")

	self.tContent = {}
	for idx = 1, 4 do
		self.tContent[idx] = g_wndProgressLog:FindChild("ContentWnd_" .. idx)
		self.tContent[idx]:Show(false)
	end

	Event_FireGenericEvent("ProgressLogLoaded")
	self.nLastSelection = -1
end

function CRB_ProgressLog:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = g_wndProgressLog, strName = Apollo.GetString("CRB_Codex"), nSaveVersion = 2})
end

function CRB_ProgressLog:OnCRB_ProgressLogOn() --general toggle
	if g_wndProgressLog:IsShown() then
		g_wndProgressLog:Show(false)
		Event_FireGenericEvent("CodexWindowHasBeenClosed")
	else
		Event_ShowTutorial(GameLib.CodeEnumTutorial.Codex)
		--g_wndProgressLog:Show(true) -- Don't turn on just yet, the other calls will toggle visibility.

		self.nLastSelection = self.nLastSelection or 1

		if self.nLastSelection == 1 then
			self:ToggleQuestLog()
		elseif self.nLastSelection == 2 then
			self:TogglePlayerPath()
		elseif self.nLastSelection == 3 then
			self:ToggleChallenges()
		elseif self.nLastSelection == 4 then
			self:ToggleAchievements()
		else self:ToggleQuestLog() end
	end
end

function CRB_ProgressLog:OnCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	g_wndProgressLog:Show(false)
	Event_FireGenericEvent("CodexWindowHasBeenClosed")
	Event_FireGenericEvent("PL_TabChanged")
end

function CRB_ProgressLog:ToggleQuestLog()
	if g_wndProgressLog:IsShown() and self.nLastSelection == 1 then
		g_wndProgressLog:Show(false)
		Event_FireGenericEvent("CodexWindowHasBeenClosed")
	else
		g_wndProgressLog:Show(true)
		g_wndProgressLog:ToFront()
		self.wndOptions:SetRadioSel("PLogOptions", 1)
		self:PLogOptionCheck(nil, nil, false)
	end
end

function CRB_ProgressLog:ToggleQuestLogFromCall(idQuest) -- the log uses this event to update AND set a quest (if clicked from the tracker)
	if idQuest == nil then -- we only want calls that pop the log with a quest selected
		return
	end
	g_wndProgressLog:Show(true)
	g_wndProgressLog:ToFront()
	self.wndOptions:SetRadioSel("PLogOptions", 1)
	self:PLogOptionCheck(nil, nil, true) -- this will allow us to open the log, but not override a set quest
end

function CRB_ProgressLog:TogglePlayerPath()
	if g_wndProgressLog:IsShown() and self.nLastSelection == 2 then
		g_wndProgressLog:Show(false)
	else
		self:ShowPlayerPath()
	end
end

function CRB_ProgressLog:ShowPlayerPath()
	g_wndProgressLog:Show(true)
	g_wndProgressLog:ToFront()
	self.wndOptions:SetRadioSel("PLogOptions", 2)
	self:PLogOptionCheck(nil, nil, false)
end

function CRB_ProgressLog:ToggleChallenges()
	if g_wndProgressLog:IsShown() and self.nLastSelection == 3 then
		g_wndProgressLog:Show(false)
		Event_FireGenericEvent("CodexWindowHasBeenClosed")
	else
		g_wndProgressLog:Show(true)
		g_wndProgressLog:ToFront()
		self.wndOptions:SetRadioSel("PLogOptions", 3)
		self:PLogOptionCheck(nil, nil, false)
	end
end

function CRB_ProgressLog:ShowChallenges(clgReceived)
	g_wndProgressLog:Show(true)
	g_wndProgressLog:ToFront()
	self.wndOptions:SetRadioSel("PLogOptions", 3)
	self:PLogOptionCheck(nil, nil, false, clgReceived)
end

function CRB_ProgressLog:ToggleAchievements()
	if g_wndProgressLog:IsShown() and self.nLastSelection == 4 then
		g_wndProgressLog:Show(false)
		Event_FireGenericEvent("CodexWindowHasBeenClosed")
	else
		g_wndProgressLog:Show(true)
		g_wndProgressLog:ToFront()
		self.wndOptions:SetRadioSel("PLogOptions", 4)
		self:PLogOptionCheck(nil, nil, false)
	end
end

function CRB_ProgressLog:ToggleAchievementsWithData(achReceived)
	g_wndProgressLog:Show(true)
	g_wndProgressLog:ToFront()
	self.wndOptions:SetRadioSel("PLogOptions", 4)
	self:PLogOptionCheck(nil, nil, false, achReceived)
end

function CRB_ProgressLog:OnLargeTabBtn(wndHandler, wndControl, eMouseButton, bDoubleClick)
	if wndHandler == wndControl and wndHandler:IsChecked() and not bDoubleClick then
		self:PLogOptionCheck(wndHandler, wndControl, nil, nil)
	end
end

function CRB_ProgressLog:PLogOptionCheck(wndHandler, wndControl, bToggledFromCall, tUserData)
	local nPLogOption = self.wndOptions:GetRadioSel("PLogOptions")
	Event_FireGenericEvent("PL_TabChanged") -- stops anything going on in the window

	for idx = 1, 4 do
		self.tContent[idx]:Show(false)
	end

	if nPLogOption == 1 then --and not bToggledFromCall then
		Event_FireGenericEvent("ShowQuestLog")
	elseif nPLogOption == 2 then
		Event_FireGenericEvent("PL_TogglePlayerPath", tUserData)
	elseif nPLogOption == 3 then
		Event_FireGenericEvent("PL_ToggleChallengesWindow", tUserData)
	elseif nPLogOption == 4 then
		Event_FireGenericEvent("PL_ToggleAchievementWindow", tUserData)
	end

	self.nLastSelection = nPLogOption -- Save last selection
	self.tContent[nPLogOption]:Show(true)

	if not g_wndProgressLog:IsVisible() then -- in case it's responding to a key or Datachron toggle
		g_wndProgressLog:Show(true)
		g_wndProgressLog:ToFront()
	end
end

local CRB_ProgressLogInst = CRB_ProgressLog:new()
CRB_ProgressLogInst:Init()
