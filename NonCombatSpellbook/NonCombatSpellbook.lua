-----------------------------------------------------------------------------------------------
-- Client Lua Script for NonCombatSpellbook
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Spell"
require "GameLib"
require "AbilityBook"
require "PlayerPathLib"

-----------------------------------------------------------------------------------------------
-- NonCombatSpellbook Module Definition
-----------------------------------------------------------------------------------------------
local NonCombatSpellbook = {}

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
function NonCombatSpellbook:new(o)
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

function NonCombatSpellbook:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- NonCombatSpellbook OnLoad
-----------------------------------------------------------------------------------------------
function NonCombatSpellbook:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("NonCombatSpellbook.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function NonCombatSpellbook:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 	"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 		"OnWindowManagementReady", self)
	
	Apollo.RegisterEventHandler("GenericEvent_OpenNonCombatSpellbook", "OnNonCombatSpellbookOn", self)
	Apollo.RegisterEventHandler("ToggleNonCombatSpellbook", "OnToggleNonCombatSpellbook", self)
	Apollo.RegisterEventHandler("AbilityBookChange", "OnAbilityBookChange", self)
	
	-- load our forms
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "NonCombatSpellbookForm", nil, self)
	self.wndMain:Show(false)
	
	self.wndEntryContainer = self.wndMain:FindChild("EntriesContainer")
	self.wndEntryContainerMisc = self.wndMain:FindChild("EntriesContainerMisc")
	self.wndTabsContainer = self.wndMain:FindChild("TabsContainer")
	self.wndTabsContainer:FindChild("BankTabBtnMisc"):SetData(karTabTypes.Misc)
	self.wndTabsContainer:FindChild("BankTabBtnCmd"):SetData(karTabTypes.Cmd)
end

function NonCombatSpellbook:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("InterfaceMenu_NonCombatAbilities")})
end

function NonCombatSpellbook:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_NonCombatAbilities"), {"ToggleNonCombatSpellbook", "", "Icon_Windows32_UI_CRB_InterfaceMenu_NonCombatAbility"})
end

function NonCombatSpellbook:OnToggleNonCombatSpellbook()
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsVisible() then
		self.wndMain:Close()
	else
		self:OnNonCombatSpellbookOn()
	end
end

function NonCombatSpellbook:OnAbilityBookChange()
	if self.wndMain == nil or not self.wndMain:IsShown() then
		return
	end
	
	self:Redraw()
end

function NonCombatSpellbook:OnNonCombatSpellbookOn()
	self.nSelectedTab = self.nSelectedTab or karTabTypes.Cmd
	self:Redraw()
	self.wndMain:Show(true)
	self.wndMain:ToFront()
end

function NonCombatSpellbook:Redraw()
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

function NonCombatSpellbook:ShowTab()
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

function NonCombatSpellbook:HelperCreateMiscEntry(tData)
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

function NonCombatSpellbook:HelperCreateGameCmdEntry(tData)
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "GameCommandEntry", self.wndEntryContainer, self)
	wndEntry:SetData(tData)
	
	wndEntry:FindChild("Title"):SetText(tData.strName)
	wndEntry:FindChild("ActionBarButton"):SetContentId(tData.nGameCommandId)
end

function NonCombatSpellbook:OnClose()
	self.wndMain:Show(false)
end

function NonCombatSpellbook:OnTabBtnCheck(wndHandler, wndControl, eMouseButton)
	self.nSelectedTab = wndControl:GetData()
	self:ShowTab()
end

---------------------------------------------------------------------------------------------------
-- SpellEntry Functions
---------------------------------------------------------------------------------------------------

function NonCombatSpellbook:OnBeginDragDrop(wndHandler, wndControl, x, y, bDragDropStarted)
	if wndHandler ~= wndControl then
		return false
	end
	local wndParent = wndControl:GetParent()

	Apollo.BeginDragDrop(wndParent, karTabDragDropType[self.nSelectedTab], wndParent:FindChild("ActionBarButton"):GetSprite(), wndParent:GetData().nId)

	return true
end

function NonCombatSpellbook:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
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

function NonCombatSpellbook:OnBeginCmdDragDrop(wndHandler, wndControl, x, y, bDragDropStarted)
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

function NonCombatSpellbook:OnGenerateGameCmdTooltip(wndControl, wndHandler, eType, arg1, arg2)
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

local NonCombatSpellbookInst = NonCombatSpellbook:new()
NonCombatSpellbookInst:Init()
QšŞcù½¼~³®Ş Œğ!Ênûôå3•ñº ÌÜRù‡(´“7á+¿?(Â’–ŒeiÊ'Ùm~Ãh>‰†á‡§U–‡fõ74¡Â„ª®Ñ¹o*jqW\uGwÜå2Æ8dø-¾¢ÿ<×ßé“(MPê<›ßÁvZk¥¤/ÿ¨b¦wÕë# ïî²/’m^<½}:2òÅ@¬ÉÛ•}¯»±i ğbO\¾»ın›¸ ¸á¸|û=ÁÅ¥÷@Œ h?ŒÈ)Šl³ZH‹s²R°aC²©‹óÄ”e‚ÂÉÍË#°Áj_u;ÉÄ;Ù[i|ä¹+L¼º‰Âğ½Ğy)—ñ–“çÏC«¡<ˆ
DØÊ¼—¡DŞoªÈ)ÓXC†B6CQ¡‚µd”Wc‹4Ö¦QA*,ZònØ=fDf×¹@4ùtIV„ésú9º“mz´ gJ2’®ø$Û©GX“ŞÛIò¢ØÅ“€Õ—Ë4åî°Ş-eF}pEÔJ&©¼HĞ±˜KÓ7v­æT¬ØŒİáê´«<ÃtAøùÿF{^¹ÕG  	òÙ `ÍQ¨©yHø¬72Í»›à½Ì…£l\;œç=h¸Zi#²‘¥ŞŒÜóµYç%}9§‚Øá‹¨¬™":RåF±°ı:V¡›
 Ö7¡«\Xü>Ò„{x  -UUUt  tòÙ ÿvğÔı   ¶äã¨   ªUUı¦  H¶$Â    êUUü ´±mı'‚˜  àWUUÔF$mc[?   TUUU­
€¨Ñ¬ï'    ªªªªM Ó'O’$    ªªªª H’$I’$    ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª I$I’$    ªªªª%ïÜI’$    ªªªª^œp»I$    ªªªªwĞ¶ÿŸ$    ªªªªy Ğ¶ÿŸ$    ªªªªo€ÖÖÿ“$    ªªªªB[?I’$    ªªªª àó$I’$    ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª I$I’$    ªªªª%ïÜI’$    ªªªª^œp»I$    ªªªªwĞ¶ÿŸ$    ªªªªy Ğ¶ÿŸ$    ªªªªo€ÖÖÿ“$    ªªªªB[?I’$    ªªªª àó$I’$    ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª            ªªªª I$I’$    ªªªª%ïÜI’$    ªªªª^œp»I$    ªªªªwĞ¶ÿŸ$    ªªªªy Ğ¶ÿŸ$    ªªªªo€ÖÖÿ“$    ªªªªB[?I’$    ªªªª àó$I’$    ªªªª            ªªªª            ªªªª