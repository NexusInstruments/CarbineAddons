-----------------------------------------------------------------------------------------------
-- Client Lua Script for CRB_NonCombatSpellbook
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Spell"
require "GameLib"
require "AbilityBook"
require "PlayerPathLib"

-----------------------------------------------------------------------------------------------
-- CRB_NonCombatSpellbook Module Definition
-----------------------------------------------------------------------------------------------
local CRB_NonCombatSpellbook = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local karTabTypes =
{
	Misc = 2,
	Cmd = 3
}

local karTabDragDropType =
{
	[karTabTypes.Misc] = "DDNonCombat",
	[karTabTypes.Cmd] = "DDGameCommand"
}

local ktCommandIds =
{
	GameLib.CodeEnumGameCommandType.GadgetAbility,
	GameLib.CodeEnumGameCommandType.DefaultAttack,
	GameLib.CodeEnumGameCommandType.ClassInnateAbility,
	GameLib.CodeEnumGameCommandType.ActivateTarget,
	GameLib.CodeEnumGameCommandType.FollowTarget,
	GameLib.CodeEnumGameCommandType.Sprint,
	GameLib.CodeEnumGameCommandType.ToggleWalk,
	GameLib.CodeEnumGameCommandType.Dismount,
	GameLib.CodeEnumGameCommandType.Vacuum,
	GameLib.CodeEnumGameCommandType.PathAction,
	GameLib.CodeEnumGameCommandType.ToggleScannerBot,
	GameLib.CodeEnumGameCommandType.Interact,
	GameLib.CodeEnumGameCommandType.DashForward,
	GameLib.CodeEnumGameCommandType.DashBackward,
	GameLib.CodeEnumGameCommandType.DashLeft,
	GameLib.CodeEnumGameCommandType.DashRight
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CRB_NonCombatSpellbook:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.arLists =
	{
		[karTabTypes.Misc] = {},
		[karTabTypes.Cmd] = {}
	}
	o.nSelectedTab = karTabTypes.Cmd

    return o
end

function CRB_NonCombatSpellbook:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- CRB_NonCombatSpellbook OnLoad
-----------------------------------------------------------------------------------------------
function CRB_NonCombatSpellbook:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CRB_NonCombatSpellbook.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CRB_NonCombatSpellbook:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 	"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 		"OnWindowManagementReady", self)
	
	Apollo.RegisterEventHandler("GenericEvent_OpenNonCombatSpellbook", "OnCRB_NonCombatSpellbookOn", self)
	Apollo.RegisterEventHandler("ToggleNonCombatSpellbook", "OnToggleNonCombatSpellbook", self)
	Apollo.RegisterEventHandler("AbilityBookChange", "OnAbilityBookChange", self)
	
	-- load our forms
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CRB_NonCombatSpellbookForm", nil, self)
	self.wndMain:Show(false)
	
	self.wndEntryContainer = self.wndMain:FindChild("EntriesContainer")
	self.wndEntryContainerMisc = self.wndMain:FindChild("EntriesContainerMisc")
	self.wndTabsContainer = self.wndMain:FindChild("TabsContainer")
	self.wndTabsContainer:FindChild("BankTabBtnMisc"):SetData(karTabTypes.Misc)
	self.wndTabsContainer:FindChild("BankTabBtnCmd"):SetData(karTabTypes.Cmd)
end

function CRB_NonCombatSpellbook:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("InterfaceMenu_NonCombatAbilities")})
end

function CRB_NonCombatSpellbook:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_NonCombatAbilities"), {"ToggleNonCombatSpellbook", "", "Icon_Windows32_UI_CRB_InterfaceMenu_NonCombatAbility"})
end

function CRB_NonCombatSpellbook:OnToggleNonCombatSpellbook()
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsVisible() then
		self.wndMain:Close()
	else
		self:OnCRB_NonCombatSpellbookOn()
	end
end

function CRB_NonCombatSpellbook:OnAbilityBookChange()
	if self.wndMain == nil or not self.wndMain:IsShown() then
		return
	end
	
	self:Redraw()
end

function CRB_NonCombatSpellbook:OnCRB_NonCombatSpellbookOn()
	self.nSelectedTab = self.nSelectedTab or karTabTypes.Cmd
	self:Redraw()
	self.wndMain:Show(true)
	self.wndMain:ToFront()
end

function CRB_NonCombatSpellbook:Redraw()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if not unitPlayer then
		return
	end
	
	self.arLists[karTabTypes.Misc] = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}
	self.arLists[karTabTypes.Cmd] = {}

	local ePlayerPath = GameLib.GetPlayerUnit():GetPlayerPathType()
	
	for idx, id in ipairs(ktCommandIds) do
		local bSkip = false
		if id == GameLib.CodeEnumGameCommandType.ToggleScannerBot then
			bSkip = ePlayerPath ~= PlayerPathLib.PlayerPathType_Scientist
		end
	
		if not bSkip then
			self.arLists[karTabTypes.Cmd][idx] = GameLib.GetGameCommand(id)
		end
	end

	self:ShowTab()
end

function CRB_NonCombatSpellbook:ShowTab()
	self.wndEntryContainer:DestroyChildren()
	self.wndEntryContainerMisc:DestroyChildren()
			
	self.wndEntryContainer:Show(self.nSelectedTab == karTabTypes.Cmd)
	self.wndEntryContainerMisc:Show(self.nSelectedTab == karTabTypes.Misc)

	for idx, tData in pairs(self.arLists[self.nSelectedTab]) do
		if self.nSelectedTab == karTabTypes.Misc and tData.bIsActive then
			self:HelperCreateMiscEntry(tData)
		elseif self.nSelectedTab == karTabTypes.Cmd then
			self:HelperCreateGameCmdEntry(tData)
		end
	end

	local function SortFunction(a,b)
		local aData = a and a:GetData()
		local bData = b and b:GetData()
		if not aData and not bData then
			return true
		end
		return (aData.strName or aData.strName) < (bData.strName or bData.strName)
	end

	self.wndEntryContainer:ArrangeChildrenVert(0, SortFunction(a,b))
	self.wndEntryContainerMisc:ArrangeChildrenVert(0, SortFunction(a,b))
	self.wndEntryContainer:SetText(#self.wndEntryContainer:GetChildren() == 0 and Apollo.GetString("NCSpellbook_NoResultsAvailable") or "")
	self.wndEntryContainerMisc:SetText(#self.wndEntryContainerMisc:GetChildren() == 0 and Apollo.GetString("NCSpellbook_NoResultsAvailable") or "")

	
	for idx, wndTab in pairs(self.wndTabsContainer:GetChildren()) do
		wndTab:SetCheck(self.nSelectedTab == wndTab:GetData())
	end
end

function CRB_NonCombatSpellbook:HelperCreateMiscEntry(tData)
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "SpellEntry", self.wndEntryContainerMisc, self)
	wndEntry:SetData(tData)

	wndEntry:FindChild("Title"):SetText(tData.strName)
	wndEntry:FindChild("ActionBarButton"):SetContentId(tData.nId)
	wndEntry:FindChild("ActionBarButton"):SetData(tData.nId)
	wndEntry:FindChild("ActionBarButton"):SetSprite(tData.tTiers[tData.nCurrentTier].splObject:GetIcon())

	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetSpellTooltipForm(self, wndEntry, tData.tTiers[tData.nCurrentTier].splObject)
	end
end

function CRB_NonCombatSpellbook:HelperCreateGameCmdEntry(tData)
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "GameCommandEntry", self.wndEntryContainer, self)
	wndEntry:SetData(tData)
	
	wndEntry:FindChild("Title"):SetText(tData.strName)
	wndEntry:FindChild("ActionBarButton"):SetContentId(tData.nGameCommandId)
end

function CRB_NonCombatSpellbook:OnClose()
	self.wndMain:Show(false)
end

function CRB_NonCombatSpellbook:OnTabBtnCheck(wndHandler, wndControl, eMouseButton)
	self.nSelectedTab = wndControl:GetData()
	self:ShowTab()
end

---------------------------------------------------------------------------------------------------
-- SpellEntry Functions
---------------------------------------------------------------------------------------------------

function CRB_NonCombatSpellbook:OnBeginDragDrop(wndHandler, wndControl, x, y, bDragDropStarted)
	if wndHandler ~= wndControl then
		return false
	end
	local wndParent = wndControl:GetParent()

	Apollo.BeginDragDrop(wndParent, karTabDragDropType[self.nSelectedTab], wndParent:FindChild("ActionBarButton"):GetSprite(), wndParent:GetData().nId)

	return true
end

function CRB_NonCombatSpellbook:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
	if eType == Tooltip.TooltipGenerateType_GameCommand then
		local xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
		end
	elseif eType == Tooltip.TooltipGenerateType_Default then
		local wndParent = wndControl:GetParent()
		local tData = wndParent:GetData() or {}
		local splMount = GameLib.GetSpell(tData.tTiers[tData.nCurrentTier].nTierSpellId)
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetSpellTooltipForm(self, wndControl, splMount)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- GameCommandEntry Functions
---------------------------------------------------------------------------------------------------

function CRB_NonCombatSpellbook:OnBeginCmdDragDrop(wndHandler, wndControl, x, y, bDragDropStarted)
	if wndHandler ~= wndControl then
		return false
	end
	local wndParent = wndControl:GetParent()
	local tData = wndParent:GetData()

	local tGameCommand = GameLib.GetGameCommand(tData.nGameCommandId)
	local strIcon = tGameCommand.strIcon
	if tData.itemAbility then
		strIcon = tGameCommand.itemAbility:GetIcon()
	elseif tData.splAbility then
		strIcon = tGameCommand.splAbility:GetIcon()
	end
	
	Apollo.BeginDragDrop(wndParent, karTabDragDropType[self.nSelectedTab], strIcon, tData.nGameCommandId)
	return true
end

function CRB_NonCombatSpellbook:OnGenerateGameCmdTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local wndParent = wndControl:GetParent()
	local tData = wndParent:GetData()

	if tData.splAbility ~= nil then
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetSpellTooltipForm(self, wndControl, tData.splAbility)
		end
	else
		local xml = XmlDoc.new()
		xml:AddLine(wndParent:GetData().strName)
		wndControl:SetTooltipDoc(xml)
	end
end

local CRB_NonCombatSpellbookInst = CRB_NonCombatSpellbook:new()
CRB_NonCombatSpellbookInst:Init()
