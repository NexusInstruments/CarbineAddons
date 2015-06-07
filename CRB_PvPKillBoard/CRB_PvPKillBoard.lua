-----------------------------------------------------------------------------------------------
-- Client Lua Script for CRB_PvPKillBoard
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "MatchingGame"
 
-----------------------------------------------------------------------------------------------
-- CRB_PvPKillBoard Module Definition
-----------------------------------------------------------------------------------------------
local CRB_PvPKillBoard = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ktClassSprites =
{
	[GameLib.CodeEnumClass.Warrior] 			= "ClientSprites:Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] 			= "ClientSprites:Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Esper]				= "ClientSprites:Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Medic]				= "ClientSprites:Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] 			= "ClientSprites:Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Spellslinger]	 	= "ClientSprites:Icon_Windows_UI_CRB_Spellslinger"
}

local kstrCreatureSprite = "CRB_GuildSprites:sprGuild_Skull"
local kstrFallSprite = "CRB_GuildSprites:sprGuild_Skull"
local kstrDrownSprite = "CRB_GuildSprites:sprGuild_Skull"

local kcrBlue = ApolloColor.new("UI_TextHoloBodyHighlight")
local kcrRed = ApolloColor.new("ConTough")
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CRB_PvPKillBoard:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.tWndRefs = {}

    return o
end

function CRB_PvPKillBoard:Init()
    Apollo.RegisterAddon(self)
end
 
-----------------------------------------------------------------------------------------------
-- CRB_PvPKillBoard OnLoad
-----------------------------------------------------------------------------------------------
function CRB_PvPKillBoard:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CRB_PvPKillBoard.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CRB_PvPKillBoard:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
    -- Register handlers for events, slash commands and timer, etc.
	Apollo.RegisterEventHandler("PvpKillNotification", "OnPvpKillNotification", self)
	Apollo.RegisterEventHandler("MatchEntered", "OnPVPMatchEntered", self)
	Apollo.RegisterEventHandler("MatchExited", "OnPVPMatchExited", self)
    Apollo.RegisterSlashCommand("killboard", "OnCRB_PvPKillBoardOn", self)

	-- Maybe the UI reloaded so be sure to check if we are in a match already
	if MatchingGame:IsInMatchingGame() then
		local tMatchState = MatchingGame:GetPVPMatchState()

		if tMatchState ~= nil then
			self:OnPVPMatchEntered()
		end
	end
end

-----------------------------------------------------------------------------------------------
-- CRB_PvPKillBoard Events
-----------------------------------------------------------------------------------------------
function CRB_PvPKillBoard:OnPvpKillNotification(strVictimName, eReason, strKillerName, eKillerClass, eVictimTeam)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndContainer then
		return
	end

	local wndEntry = Apollo.LoadForm(self.xmlDoc, "KillEntry", self.tWndRefs.wndContainer, self)
	local wndKillerNameLabel = wndEntry:FindChild("KillerNameLabel")
	local wndVictimNameLabel = wndEntry:FindChild("VictimNamelabel")
	
	if eReason == MatchingGame.PvpDeathReason.KilledByPlayer then
		wndEntry:FindChild("Icon"):SetBGColor(ApolloColor.new("white"))
		wndEntry:FindChild("Icon"):SetSprite(ktClassSprites[eKillerClass])
	elseif eReason == MatchingGame.PvpDeathReason.KilledByCreature then
		wndEntry:FindChild("Icon"):SetBGColor(ApolloColor.new("ConTough"))
		wndEntry:FindChild("Icon"):SetSprite(kstrCreatureSprite)
	elseif eReason == MatchingGame.PvpDeathReason.Falling then
		wndEntry:FindChild("Icon"):SetBGColor(ApolloColor.new("ConTough"))
		wndEntry:FindChild("Icon"):SetSprite(kstrFallSprite)
	elseif eReason == MatchingGame.PvpDeathReason.Drowning then
		wndEntry:FindChild("Icon"):SetBGColor(ApolloColor.new("ConTough"))
		wndEntry:FindChild("Icon"):SetSprite(kstrDrownSprite)
	end
	
	local crKiller = nil
	local crVictim = nil	
	
	if eVictimTeam == MatchingGame.Team.Team1 then
		crKiller = kcrBlue
		crVictim = kcrRed
	else
		crKiller = kcrRed
		crVictim = kcrBlue
	end 
	
	wndKillerNameLabel:SetTextColor(crKiller)
	wndVictimNameLabel:SetTextColor(crVictim)
	
	wndKillerNameLabel:SetText(" " .. strKillerName or "")
	self:HelperSizeLabelWindowToText(wndKillerNameLabel)
	
	wndVictimNameLabel:SetText(strVictimName or "")
	
	wndEntry:ArrangeChildrenHorz(0)
	
	self.tWndRefs.wndContainer:ArrangeChildrenVert(1)
	self.tWndRefs.wndContainer:SetVScrollPos(self.tWndRefs.wndContainer:GetVScrollRange())
end

function CRB_PvPKillBoard:OnPVPMatchEntered()
	if not MatchingGame.IsInPVPGame() then
		return
	end

	self:Initialize()
end

function CRB_PvPKillBoard:OnPVPMatchExited()
	self:Cleanup()
end

-----------------------------------------------------------------------------------------------
-- CRB_PvPKillBoard Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/killboard"
function CRB_PvPKillBoard:OnCRB_PvPKillBoardOn()
	if not MatchingGame.IsInPVPGame() then
		return
	end

	self.tWndRefs.wndExpanded:Show(true)
end

function CRB_PvPKillBoard:Initialize()
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Destroy()
	end
	
	self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "CRB_PvPKillBoardForm", nil, self)
	self.tWndRefs.wndExpanded = self.tWndRefs.wndMain:FindChild("ExpandedContents")
	self.tWndRefs.wndContainer = self.tWndRefs.wndMain:FindChild("KillContainer")
	
	self.tWndRefs.wndExpanded:Show(false)
end

function CRB_PvPKillBoard:Cleanup()
	if self.tWndRefs.wndMain then
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
	end
end

function CRB_PvPKillBoard:HelperSizeLabelWindowToText(wndLabel)
	local nLeft, nTop, nRight, nBottom = wndLabel:GetAnchorOffsets()
	wndLabel:SetAnchorOffsets(nLeft, nTop, nLeft+Apollo.GetTextWidth("CRB_InterfaceLarge_O", wndLabel:GetText()), nBottom)
end

---------------------------------------------------------------------------------------------------
-- CRB_PvPKillBoardForm Functions
---------------------------------------------------------------------------------------------------

function CRB_PvPKillBoard:OnMinimizedExpandClick( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndExpanded:Show(not self.tWndRefs.wndExpanded:IsShown())
end

-----------------------------------------------------------------------------------------------
-- CRB_PvPKillBoard Instance
-----------------------------------------------------------------------------------------------
local CRB_PvPKillBoardInst = CRB_PvPKillBoard:new()
CRB_PvPKillBoardInst:Init()
