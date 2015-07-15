-----------------------------------------------------------------------------------------------
-- Client Lua Script for PathFrame
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "AbilityBook"
require "GameLib"
require "PlayerPathLib"
require "Tooltip"
require "Unit"
 
-----------------------------------------------------------------------------------------------
-- PathFrame Module Definition
-----------------------------------------------------------------------------------------------
local PathFrame = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local knBottomPadding = 48 -- MUST MATCH XML
local knTopPadding = 48 -- MUST MATCH XML
local knPathLASIndex = 10

local knSaveVersion = 1
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PathFrame:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function PathFrame:Init()
    Apollo.RegisterAddon(self, nil, nil, {"ActionBarFrame", "Abilities"})
end 

-----------------------------------------------------------------------------------------------
-- PathFrame OnLoad
-----------------------------------------------------------------------------------------------
function PathFrame:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PathFrame.xml")
	
	self.nSelectedPathId = nil
	self.bHasPathAbilities = false
end

function PathFrame:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSavedData =
	{
		nSelectedPathId = self.nSelectedPathId,
		nSaveVersion = knSaveVersion,
	}

	return tSavedData
end

function PathFrame:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character or not tSavedData or not tSavedData.nSaveVersion or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	if tSavedData.nSelectedPathId then
		self.nSelectedPathId = tSavedData.nSelectedPathId
	end
end

function PathFrame:GetAsyncLoadStatus()
	if not (self.xmlDoc and self.xmlDoc:IsLoaded()) then
		return Apollo.AddonLoadStatus.Loading
	end	

	if not self.unitPlayer then
		self.unitPlayer = GameLib.GetPlayerUnit()
	end
	
	if not self.unitPlayer then
		return Apollo.AddonLoadStatus.Loading 
	end
	
	if not Tooltip and Tooltip.GetSpellTooltipForm then
		return Apollo.AddonLoadStatus.Loading
	end
	
	if self:OnAsyncLoad() then
		return Apollo.AddonLoadStatus.Loaded
	end
	
	return Apollo.AddonLoadStatus.Loading
end

function PathFrame:OnAsyncLoad()
	if not Apollo.GetAddon("ActionBarFrame") or not Apollo.GetAddon("Abilities") then
		return
	end
	
	Apollo.RegisterEventHandler("UnitEnteredCombat",						"OnUnitEnteredCombat", self)
	Apollo.RegisterEventHandler("ChangeWorld", 								"OnChangeWorld", self)
	Apollo.RegisterEventHandler("PlayerCreated", 							"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("CharacterCreated", 						"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("UpdatePathXp", 							"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("AbilityBookChange", 						"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences",	"DrawPathAbilityList", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)

	Apollo.RegisterTimerHandler("RefreshPathTimer", 						"DrawPathAbilityList", self)
	
	--Load Forms
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "PathFrameForm", "FixedHudStratum", self)
	
	self.wndMenu = Apollo.LoadForm(self.xmlDoc, "PathSelectionMenu", nil, self)
	self.wndMain:FindChild("PathOptionToggle"):AttachWindow(self.wndMenu)
	self.wndMenu:Show(false)
	
	if self.nSelectedPathId then
		local tAbilities = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)
		local bIsValidPathId = false
		
		for idx, tAbility in pairs(tAbilities) do
			if tAbility.bIsActive then
				bIsValidPathId = bIsValidPathId or tAbility.nId == self.nSelectedPathId
			end
		end
		
		self.nSelectedPathId = bIsValidPathId and self.nSelectedPathId or nil
	end
	
	self:DrawPathAbilityList()
	return true
end

-----------------------------------------------------------------------------------------------
-- PathFrame Functions
-----------------------------------------------------------------------------------------------
function PathFrame:DrawPathAbilityList()
	if not self.unitPlayer then
		return
	end
	
	local tAbilities = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)
	if not tAbilities then
		return	
	end
	
	local wndList = self.wndMenu:FindChild("Content")
	wndList:DestroyChildren()
	
	local nCount = 0
	local nListHeight = 0
	for _, tAbility in pairs(tAbilities) do
		if tAbility.bIsActive then
			local splCurr = tAbility.tTiers[tAbility.nCurrentTier].splObject
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "PathBtn", wndList, self)
			nCount = nCount + 1
			
			self.nSelectedPathId = self.nSelectedPathId and self.nSelectedPathId or tAbility.nId
			
			local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
			nListHeight = nListHeight + wndCurr:GetHeight()
			wndCurr:FindChild("PathBtnIcon"):SetSprite(splCurr:GetIcon())
			wndCurr:SetData(tAbility.nId)
			if Tooltip and Tooltip.GetSpellTooltipForm then
				wndCurr:SetTooltipDoc(nil)
				Tooltip.GetSpellTooltipForm(self, wndCurr, splCurr)
			end
		end
	end
	
	if self.nSelectedPathId ~= ActionSetLib.GetCurrentActionSet()[10] then
		self:HelperSetPathAbility(self.nSelectedPathId)
	end
	
	self.bHasPathAbilities = nCount > 0
	self.wndMain:FindChild("PathOptionToggle"):Enable(self.bHasPathAbilities)
	
	if self.bHasPathAbilities then
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
	
	local nHeight = wndList:ArrangeChildrenVert(0)
	local nLeft, nTop, nRight, nBottom = self.wndMenu:GetAnchorOffsets()
	self.wndMenu:SetAnchorOffsets(nLeft, nBottom - (nListHeight + knBottomPadding+knTopPadding), nRight, nBottom)
end

function PathFrame:HelperSetPathAbility(nAbilityId)
	local tActionSet = ActionSetLib.GetCurrentActionSet()
	if not tActionSet or not nAbilityId then
		return false
	end
	
	tActionSet[knPathLASIndex] = nAbilityId
	local tResult = ActionSetLib.RequestActionSetChanges(tActionSet)

	if tResult.eResult ~= ActionSetLib.CodeEnumLimitedActionSetResult.Ok then
		return false
	end
	
	
	Event_FireGenericEvent("PathAbilityUpdated", nAbilityId)
	self.nSelectedPathId = nAbilityId
	
	return true
end

-----------------------------------------------------------------------------------------------
-- PathFrameForm Functions
-----------------------------------------------------------------------------------------------
function PathFrame:OnGenerateTooltip(wndControl, wndHandler, tType, arg1, arg2)
	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
	end
end

function PathFrame:OnPathOptionToggle(wndHandler, wndControl, eMouseButton)
	if wndControl:IsChecked() then
		self.wndMenu:Show(true)
		self.wndMenu:ToFront()
	else
		self.wndMenu:Show(false)
	end
end

function PathFrame:OnPathBtn(wndControl, wndHandler)
	local result = self:HelperSetPathAbility(wndControl:GetData())
	
	self.nSelectedPathId = result and wndControl:GetData() or nil
	
	self.wndMenu:Show(false)
end

function PathFrame:OnCloseBtn()
	self.wndMenu:Show(false)
end

function PathFrame:OnChangeWorld()
	self.wndMenu:Show(false)
end

function PathFrame:OnUnitEnteredCombat(unit, bIsInCombat)
	if unit ~= self.unitPlayer or not self.wndMain then
		return
	end
	
	self.wndMain:FindChild("PathOptionToggle"):Enable(not bIsInCombat and self.bHasPathAbilities)
end

function PathFrame:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor == GameLib.CodeEnumTutorialAnchor.Path then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
		
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	end
end

-----------------------------------------------------------------------------------------------
-- PathFrame Instance
-----------------------------------------------------------------------------------------------
local PathFrameInst = PathFrame:new()
PathFrameInst:Init()"/>
        </Control>
        <Control Class="Window" LAnchorPoint="0" LAnchorOffset="0" TAnchorPoint="0" TAnchorOffset="0" RAnchorPoint="1" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>
    </Form>
    <Form Class="Window" LAnchorPoint="0" LAnchorOffset="0" TAnchorPoint="0" TAnchorOffset="0" RAnchorPoint="1" RAnchorOffset="0" BAnchorPoint="0" BAnchorOffset="50" RelativeToClient="1" Font="Default" Text="" Template="Default" TooltipType="OnCursor" Name="GameCommandEntry" Border="0" Picture="0" SwallowMouseClicks="1" Moveable="0" Escapable="0" Overlapped="0" BGColor="ffffffff" TextColor="ffffffff" TooltipColor="" Tooltip="">
        <Control Class="Window" LAnchorPoint="0" LAnchorOffset="55" TAnchorPoint="0" TAnchorOffset="0" RAnchorPoint="1" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="CRB_InterfaceMedium_B" Text="" Template="Default" TooltipType="OnCursor" Name="Title" BGColor="ffffffff" TextColor="UI_TextHoloBody" TooltipColor="" TextId="Challenges_NoProgress" DT_RIGHT="0" DT_VCENTER="1"/>
        <Control Class="Window" LAnchorPoint="0" LAnchorOffset="5" TAnchorPoint="0" TAnchorOffset="5" RAnchorPoint="0" RAnchorOffset="45" BAnchorPoint="1" BAnchorOffset="-5" RelativeToClient="1" Font="Default" Text="" Template="Default" TooltipType="OnCursor" Name="IconBG" BGColor="ffffffff" TextColor="ffffffff" TooltipColor="" Border="0" IgnoreMouse="1" Picture="1" Sprite="CRB_Basekit:kitBase_HoloBlue_Tiny" NoClip="0" Visible="1" HideInEditor="0" TextId="" NewWindowDepth="1"/>
        <Control Class="ActionBarButton" Base="Button_ActionBarBlank" RelativeToClient="1" IfHoldNoSignal="1" DT_VCENTER="1" DT_CENTER="1" NeverBringToFront="0" Picture="1" WindowSoundTemplate="ActionBarButton" LAnchorPoint="0" LAnchorOffset="10" TAnchorPoint="0" TAnchorOffset="10" RAnchorPoint="0" RAnchorOffset="40" BAnchorPoint="0" BAnchorOffset="40" IgnoreTooltipDelay="0" TooltipType="OnCursor" Name="ActionBarButton" BGColor="ffffffff" TextColor="ffffffff" TooltipColor="" ProcessRightClick="1" ContentId="0" IgnoreMouse="0" NewWindowDepth="1" Tooltip="" ContentType="GCBar">
            <Event Name="QueryBeginDragDrop" Function="OnBeginCmdDragDrop"/>
            <Event Name="GenerateTooltip" Function="OnGenerateTooltip"/>
        </Control>
        <Control Class="Window" LAnchorPoint="0" LAnchorOffset="0" TAnchorPoint="0" TAnchorOffset="0" RAnchorPoint="1" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>