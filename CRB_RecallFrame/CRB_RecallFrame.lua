-----------------------------------------------------------------------------------------------
-- Client Lua Script for CRB_RecallFrame
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "HousingLib"
require "HousingLib"
require "Unit"
 
-----------------------------------------------------------------------------------------------
-- CRB_RecallFrame Module Definition
-----------------------------------------------------------------------------------------------
local CRB_RecallFrame = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local knBottomPadding = 30
local knTopPadding = 42
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CRB_RecallFrame:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CRB_RecallFrame:Init()
    Apollo.RegisterAddon(self, nil, nil, {"ActionBarFrame"})
end
 

-----------------------------------------------------------------------------------------------
-- CRB_RecallFrame OnLoad
-----------------------------------------------------------------------------------------------
function CRB_RecallFrame:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CRB_RecallFrame.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.bActionBarReady = false
	
	Apollo.RegisterEventHandler("ActionBarReady", "OnActionBarReady", self)
end

function CRB_RecallFrame:OnActionBarReady()
	self.bActionBarReady = true
	self:OnDocumentReady()
end

function CRB_RecallFrame:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	if not self.bActionBarReady or self.wndMain then
		return
	end
	
	self.bFormsLoaded = true
	Apollo.RegisterEventHandler("ChangeWorld", 					"OnChangeWorld", self)
	Apollo.RegisterEventHandler("HousingNeighborhoodRecieved", 	"OnNeighborhoodsUpdated", self)
	Apollo.RegisterEventHandler("GuildResult", 					"OnGuildResult", self)
	Apollo.RegisterEventHandler("AbilityBookChange", 			"OnAbilityBookChange", self)
	
	Apollo.RegisterEventHandler("CharacterCreated", 			"RefreshDefaultCommand", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", 	"RefreshDefaultCommand", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences","RefreshDefaultCommand", self)

	Apollo.RegisterTimerHandler("RefreshRecallTimer", 			"RefreshDefaultCommand", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)
	
	-- load our forms
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CRB_RecallFrameForm", "FixedHudStratum", self)
	self.wndMenu = Apollo.LoadForm(self.xmlDoc, "RecallSelectionMenu", nil, self)
	self.wndMain:FindChild("RecallOptionToggle"):AttachWindow(self.wndMenu)
    
	self:RefreshDefaultCommand()
end

-----------------------------------------------------------------------------------------------
-- CRB_RecallFrame Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

	
function CRB_RecallFrame:RefreshDefaultCommand()
	if GameLib.GetDefaultRecallCommand() == nil then
		self:ResetDefaultCommand()
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.BindPoint then
		if GameLib.HasBindPoint() == false then 	
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.House then
		if HousingLib.IsResidenceOwner() == false then 	
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Warplot then
		local bNeedsReset = true
		-- Determine if this player is in a WarParty
		for key, guildCurr in pairs(GuildLib.GetGuilds()) do
			if guildCurr:GetType() == GuildLib.GuildType_WarParty then
				bNeedsReset = false
				break
			end
		end
		if bNeedsReset then
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Illium then
		local bNeedsReset = false
		for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
			if not tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
				bNeedsReset = true
			end
		end
		if bNeedsReset then
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Thayd then
		local bNeedsReset = false
		for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
			if not tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
				bNeedsReset = true
			end
		end
		if bNeedsReset then
			self:ResetDefaultCommand()
		end
	end
	
	local bShowRecallBtn = false
	if GameLib.GetDefaultRecallCommand() ~= nil then
		if GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.BindPoint then
			if GameLib.HasBindPoint() then
				bShowRecallBtn = true
				self.wndMain:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.BindPoint)
			else
				bShowRecallBtn = false
			end
		elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.House then
			bShowRecallBtn = true
			self.wndMain:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.House)
		elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Warplot then
			bShowRecallBtn = true
			self.wndMain:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Warplot)
		elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Illium then
			bShowRecallBtn = true
			self.wndMain:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Illium)
		elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Thayd then
			bShowRecallBtn = true
			self.wndMain:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Thayd)
		end
	else
		bShowRecallBtn = false
	end
	
	if bShowRecallBtn then
		--Toggle Visibility based on ui preference
		local unitPlayer = GameLib.GetPlayerUnit()
		local nVisibility = Apollo.GetConsoleVariable("hud.SkillsBarDisplay")
		
		if nVisibility == 2 then --always off
			self.wndMain:Show(false)
		elseif nVisibility == 3 then --on in combat
			self.wndMain:Show(unitPlayer:IsInCombat())	
		elseif nVisibility == 4 then --on out of combat
			self.wndMain:Show(not unitPlayer:IsInCombat())
		else
			self.wndMain:Show(true)
		end
	else
		self.wndMain:Show(false)
	end
end

function CRB_RecallFrame:ResetDefaultCommand()
	local bHasWarplot = false
	-- Determine if this player is in a WarParty
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			bHasWarplot = true
			break
		end
	end
	
	local bHasIllium = false
	local bHasThyad = false
	for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
			bHasThyad = true
		end
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
			bHasIllium = true
		end
	end

	if GameLib.HasBindPoint() then 	
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.BindPoint)
	elseif HousingLib.IsResidenceOwner() == true then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.House)	
	elseif bHasWarplot then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.Warplot)
	elseif bHasIllium then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.Illium)
	elseif bHasThyad then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.Thayd)
	else
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.BindPoint)
	end
end

function CRB_RecallFrame:OnGenerateTooltip(wndControl, wndHandler, tType, arg1, arg2)
	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
	end
end

-----------------------------------------------------------------------------------------------
-- CRB_RecallFrameForm Functions
-----------------------------------------------------------------------------------------------

function CRB_RecallFrame:OnRecallOptionToggle(wndHandler, wndControl, eMouseButton)
	if wndControl:IsChecked() then
		self:GenerateBindList()
	else
		self.wndMenu:Show(false)
	end
end

function CRB_RecallFrame:GenerateBindList()
	self.wndMenu:FindChild("Content"):DestroyChildren() -- todo: selectively destroy the list
	local nWndLeft, nWndTop, nWndRight, nWndBottom = self.wndMenu:GetAnchorOffsets()
	local nEntryHeight = 0
	local bHasBinds = false
	local bHasWarplot = false
	local guildCurr = nil
	
	-- todo: condense this 
	if GameLib.HasBindPoint() == true then
		--load recall
		local wndBind = Apollo.LoadForm(self.xmlDoc, "RecallEntry", self.wndMenu:FindChild("Content"), self)
		wndBind:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.BindPoint)
		wndBind:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.BindPoint)
		
		bHasBinds = true
		local nLeft, nTop, nRight, nBottom = wndBind:GetAnchorOffsets()
		nEntryHeight = nEntryHeight + (nBottom - nTop)
	end
	
	if HousingLib.IsResidenceOwner() == true then
		-- load house
		local wndHouse = Apollo.LoadForm(self.xmlDoc, "RecallEntry", self.wndMenu:FindChild("Content"), self)
		wndHouse:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.House)
		wndHouse:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.House)
		
		bHasBinds = true
		local nLeft, nTop, nRight, nBottom = wndHouse:GetAnchorOffsets()
		nEntryHeight = nEntryHeight + (nBottom - nTop)		
	end

	-- Determine if this player is in a WarParty
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			bHasWarplot = true
			break
		end
	end
	
	if bHasWarplot == true then
		-- load warplot
		local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallEntry", self.wndMenu:FindChild("Content"), self)
		wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Warplot)
		wndWarplot:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.Warplot)
		
		bHasBinds = true
		local nLeft, nTop, nRight, nBottom = wndWarplot:GetAnchorOffsets()
		nEntryHeight = nEntryHeight + (nBottom - nTop)	
	end
	
	local bIllium = false
	local bThayd = false
	
	for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
			bIllium = true
		end
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
			bThayd = true
		end
	end
	
	if bIllium then
		-- load capital
		local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallEntry", self.wndMenu:FindChild("Content"), self)
		wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Illium)
		wndWarplot:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.Illium)
		
		bHasBinds = true
		local nLeft, nTop, nRight, nBottom = wndWarplot:GetAnchorOffsets()
		nEntryHeight = nEntryHeight + (nBottom - nTop)
	end
	
	if bThayd then
		-- load capital
		local wndWarplot = Apollo.LoadForm(self.xmlDoc, "RecallEntry", self.wndMenu:FindChild("Content"), self)
		wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Thayd)
		wndWarplot:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.Thayd)		
		
		bHasBinds = true
		local nLeft, nTop, nRight, nBottom = wndWarplot:GetAnchorOffsets()
		nEntryHeight = nEntryHeight + (nBottom - nTop)
	end
	
	if bHasBinds == true then
		self.wndMenu:FindChild("Content"):SetText("")
		self.wndMenu:SetAnchorOffsets(nWndLeft, nWndBottom -(nEntryHeight + knBottomPadding+knTopPadding), nWndRight, nWndBottom)

		self.wndMenu:FindChild("Content"):ArrangeChildrenVert()
	end

	self.wndMenu:Show(true)
	self.wndMenu:ToFront()	
end

function CRB_RecallFrame:OnRecallBtn(wndControl, wndHandler)
	local nRecallCommand = wndControl:GetData()
	
	GameLib.SetDefaultRecallCommand(nRecallCommand)
	self.wndMain:FindChild("RecallActionBtn"):SetContentId(nRecallCommand)
	self.wndMenu:Show(false)
end

function CRB_RecallFrame:OnCloseBtn()
	self.wndMenu:Show(false)
end

function CRB_RecallFrame:OnChangeWorld()
	self.bHaveNeighborhoods = false
	self.wndMenu:Show(false)
end

function CRB_RecallFrame:OnGuildResult(guildCurr, strName, nRank, eResult) -- guild object, name string, Rank, result enum
	local bRefresh = false

	if eResult == GuildLib.GuildResult_GuildDisbanded then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_KickedYou then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_YouQuit then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_YouJoined then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_YouCreated then
		bRefresh = true
	end
				
	if bRefresh then
		self.wndMenu:Show(false)
		-- Process on the next frame.
		Apollo.CreateTimer("RefreshRecallTimer", 0.001, false)
	end
end

function CRB_RecallFrame:OnAbilityBookChange()
	self.wndMenu:Show(false)
	-- Process on the next frame.
	Apollo.CreateTimer("RefreshRecallTimer", 0.001, false)
end

function CRB_RecallFrame:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor == GameLib.CodeEnumTutorialAnchor.Recall then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	end
end

-----------------------------------------------------------------------------------------------
-- CRB_RecallFrame Instance
-----------------------------------------------------------------------------------------------
local CRB_RecallFrameInst = CRB_RecallFrame:new()
CRB_RecallFrameInst:Init()
