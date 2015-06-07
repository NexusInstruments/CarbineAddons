-----------------------------------------------------------------------------------------------
-- Client Lua Script for CRB_Stuck
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "HousingLib"

local CRB_Stuck = {}

function CRB_Stuck:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CRB_Stuck:Init()
    Apollo.RegisterAddon(self)
end

function CRB_Stuck:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CRB_Stuck.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CRB_Stuck:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
    Apollo.RegisterSlashCommand("stuck", 				"OnStuckToggle", self)
	Apollo.RegisterEventHandler("ToggleStuckWindow", 	"OnStuckToggle", self)

	Apollo.RegisterTimerHandler("Stuck_OneSecondTimer", "RedrawCooldowns", self)
	Apollo.CreateTimer("Stuck_OneSecondTimer", 1, false)
end


-----------------------------------------------------------------------------------------------
-- CRB_Stuck Functions
-----------------------------------------------------------------------------------------------

function CRB_Stuck:OnStuckToggle()
	if not self.wndMain or not self.wndMain:IsValid() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "CRB_StuckForm", nil, self)
		
		if self.locSavedWindowLoc then
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
		self:RedrawCooldowns()
	else
		self.wndMain:Show(not self.wndMain:IsShown())
		Apollo.StopTimer("Stuck_OneSecondTimer")
	end

end

function CRB_Stuck:RedrawCooldowns()
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
		local tCooldowns = GameLib.GetStuckCooldowns()
		local nBindTime = tCooldowns[GameLib.SupportStuckAction.RecallBind].fCooldownTime
		local nHomeTime = tCooldowns[GameLib.SupportStuckAction.RecallHouse].fCooldownTime
		self.wndMain:FindChild("BindButton"):Enable(nBindTime == 0)
		self.wndMain:FindChild("BindButton"):Show(GameLib.HasBindPoint())
		self.wndMain:FindChild("BindCooldownText"):SetText(self:HelperConvertTimeToString(nBindTime))
		self.wndMain:FindChild("HomeButton"):Enable(nHomeTime == 0)
		self.wndMain:FindChild("HomeButton"):Show(HousingLib.IsResidenceOwner())
		self.wndMain:FindChild("HomeCooldownText"):SetText(self:HelperConvertTimeToString(nHomeTime))
		self.wndMain:FindChild("ArrangeHorz"):ArrangeChildrenHorz(1)
		Apollo.StartTimer("Stuck_OneSecondTimer")
	end
end

function CRB_Stuck:HelperConvertTimeToString(nTime)
	return nTime == 0 and "" or string.format("%d:%.02d", math.floor(nTime / 60), nTime % 60)
end

-----------------------------------------------------------------------------------------------
-- CRB_StuckForm Functions
-----------------------------------------------------------------------------------------------

function CRB_Stuck:OnClose()
	if self.wndMain and self.wndMain:IsValid() then
		self.locSavedWindowLoc = self.wndMain:GetLocation()
		self.wndMain:Destroy()
		self.wndMain = nil
		Apollo.StopTimer("Stuck_OneSecondTimer")
	end
end

function CRB_Stuck:OnBind()
	GameLib.SupportStuck(GameLib.SupportStuckAction.RecallBind)
	self:OnClose()
end

function CRB_Stuck:OnHome()
	GameLib.SupportStuck(GameLib.SupportStuckAction.RecallHouse)
	self:OnClose()
end

function CRB_Stuck:OnPickDeath()
	if not self.wndConfirm or not self.wndConfirm:IsValid() then
		self.wndConfirm = Apollo.LoadForm(self.xmlDoc, "DeathConfirm", self.wndMain, self)
	end
	self.wndMain:FindChild("Blocker"):Show(true)

	local tCooldowns = GameLib.GetStuckCooldowns()
	if tCooldowns[GameLib.SupportStuckAction.RecallDeath].fCooldownTime == 0 then
		self.wndConfirm:FindChild("NoticeText"):SetText(Apollo.GetString("CRB_Stuck_Death_ConfirmFree"))
	else
		self.wndConfirm:FindChild("NoticeText"):SetText(Apollo.GetString("CRB_Stuck_Death_Confirm"))
	end
end

function CRB_Stuck:OnYes() -- After OnPickDeath
	GameLib.SupportStuck(GameLib.SupportStuckAction.RecallDeath)
	self:OnClose()
end

function CRB_Stuck:OnNo() -- After OnPickDeath
	self.wndMain:FindChild("Blocker"):Show(false)
	self.wndConfirm:Destroy()
end

local CRB_StuckInst = CRB_Stuck:new()
CRB_StuckInst:Init()