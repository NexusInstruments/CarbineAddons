-----------------------------------------------------------------------------------------------
-- Client Lua Script for TradeskillContainer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local TradeskillContainer = {}

local knSaveVersion = 2

function TradeskillContainer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function TradeskillContainer:Init()
    Apollo.RegisterAddon(self)
end

function TradeskillContainer:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("TradeskillContainer.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function TradeskillContainer:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 	"OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 		"OnWindowManagementReady", self)

	Apollo.RegisterEventHandler("GenericEvent_OpenToSpecificSchematic", "OnOpenToSpecificSchematic", self) -- Not Used Yet
	Apollo.RegisterEventHandler("GenericEvent_OpenToSpecificTechTree", 	"OnOpenToSpecificTechTree", self)
	Apollo.RegisterEventHandler("GenericEvent_OpenToSearchSchematic", 	"OnOpenToSearchSchematic", self)

	Apollo.RegisterEventHandler("TradeskillLearnedFromTHOR", 			"OnAlwaysShowTradeskills", self)
	Apollo.RegisterEventHandler("TradeSkills_Learned", 					"OnAlwaysShowTradeskills", self)
	Apollo.RegisterEventHandler("AlwaysShowTradeskills",				"OnAlwaysShowTradeskills", self)
	Apollo.RegisterEventHandler("AlwaysHideTradeskills",				"OnAlwaysHideTradeskills", self)
	Apollo.RegisterEventHandler("ToggleTradeskills", 					"OnToggleTradeskills", self)
	Apollo.RegisterEventHandler("WorkOrderLocate", 						"OnLocateAchievement", self) -- Clicking a work order quest
	Apollo.RegisterEventHandler("FloatTextPanel_ToggleTechTreeWindow", 	"OnLocateAchievement", self) -- Clicking view btn on achievement notification

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "TradeskillContainerForm", nil, self)

	if self.wndMain == nil then
		return Apollo.AddonLoadStatus.LoadingError
	end

	self.wndMain:FindChild("ToggleSchematicsBtn"):AttachWindow(self.wndMain:FindChild("SchematicsMainForm"))
	self.wndMain:FindChild("ToggleAchievementBtn"):AttachWindow(self.wndMain:FindChild("AchievementsMainForm"))
	self.wndMain:FindChild("ToggleTalentsBtn"):AttachWindow(self.wndMain:FindChild("TalentsMainForm"))
	self.wndMain:FindChild("ToggleSchematicsBtn"):SetCheck(true)
	self.wndMain:Show(false, true)

	if self.locSavedWindowLoc then
		self.wndMain:MoveToLocation(self.locSavedWindowLoc)
	end
end

function TradeskillContainer:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_Tradeskills"), {"ToggleTradeskills", "Tradeskills", "Icon_Windows32_UI_CRB_InterfaceMenu_Tradeskills"})
end

function TradeskillContainer:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("CRB_Tradeskills")})
end

function TradeskillContainer:OnClose(wndHandler, wndControl)
	if wndHandler == wndControl then
		self.wndMain:Show(false)
	end
end

function TradeskillContainer:OnAlwaysShowTradeskills()
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	self.wndMain:ToFront()
	self.wndMain:Show(true)
	self:RedrawAll()
end

function TradeskillContainer:OnAlwaysHideTradeskills()
	self.wndMain:Show(false)
end

function TradeskillContainer:OnToggleTradeskills()
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	if self.wndMain:IsVisible() then
		self.wndMain:Close()
	else
		self.wndMain:Invoke()
		self:RedrawAll()
	end
end

function TradeskillContainer:OnLocateAchievement(idSchematic, achData)
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	local tSchematicInfo = nil
	if idSchematic then
		tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
	end

	if tSchematicInfo and tSchematicInfo.nParentSchematicId then -- Replace sub variants with their parent, we will open to their parent's page
		idSchematic = tSchematicInfo.nParentSchematicId
	end

	if tSchematicInfo and tSchematicInfo.bIsKnown then
		--send to schematics
		self.wndMain:FindChild("SchematicsMainForm"):Show(true)
		self.wndMain:FindChild("AchievementsMainForm"):Show(false)
		self.wndMain:FindChild("TalentsMainForm"):Show(false)
		self.wndMain:FindChild("ToggleSchematicsBtn"):SetCheck(true)
		self.wndMain:FindChild("ToggleAchievementBtn"):SetCheck(false)
		self.wndMain:FindChild("ToggleTalentsBtn"):SetCheck(false)
		Event_FireGenericEvent("GenericEvent_InitializeSchematicsTree", self.wndMain:FindChild("SchematicsMainForm"), idSchematic, nil)
	elseif not tSchematicInfo or (tSchematicInfo and tSchematicInfo.achSource ) or achData then
		--send to techtree
		self.wndMain:FindChild("SchematicsMainForm"):Show(false)
		self.wndMain:FindChild("AchievementsMainForm"):Show(true)
		self.wndMain:FindChild("TalentsMainForm"):Show(false)
		self.wndMain:FindChild("ToggleSchematicsBtn"):SetCheck(false)
		self.wndMain:FindChild("ToggleAchievementBtn"):SetCheck(true)
		self.wndMain:FindChild("ToggleTalentsBtn"):SetCheck(false)
		Event_FireGenericEvent("GenericEvent_InitializeAchievementTree", self.wndMain:FindChild("AchievementsMainForm"), (tSchematicInfo and tSchematicInfo.achSource or achData))
	end
	self.wndMain:Invoke()
end

function TradeskillContainer:OnOpenToSpecificTechTree(achievementData)
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	self.wndMain:ToFront()
	self.wndMain:Show(true)
	self.wndMain:FindChild("SchematicsMainForm"):Show(false)
	self.wndMain:FindChild("AchievementsMainForm"):Show(true)
	self.wndMain:FindChild("TalentsMainForm"):Show(false)
	self.wndMain:FindChild("ToggleSchematicsBtn"):SetCheck(false)
	self.wndMain:FindChild("ToggleAchievementBtn"):SetCheck(true)
	self.wndMain:FindChild("ToggleTalentsBtn"):SetCheck(false)
	Event_FireGenericEvent("GenericEvent_InitializeAchievementTree", self.wndMain:FindChild("AchievementsMainForm"), achievementData)
	--self:RedrawAll()
end

function TradeskillContainer:OnOpenToSpecificSchematic(nSchematicId)
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	self.wndMain:ToFront()
	self.wndMain:Show(true)
	self.wndMain:FindChild("SchematicsMainForm"):Show(true)
	self.wndMain:FindChild("AchievementsMainForm"):Show(false)
	self.wndMain:FindChild("TalentsMainForm"):Show(false)
	self.wndMain:FindChild("ToggleSchematicsBtn"):SetCheck(true)
	self.wndMain:FindChild("ToggleAchievementBtn"):SetCheck(false)
	self.wndMain:FindChild("ToggleTalentsBtn"):SetCheck(false)
	Event_FireGenericEvent("GenericEvent_InitializeSchematicsTree", self.wndMain:FindChild("SchematicsMainForm"), nSchematicId, nil)
	--self:RedrawAll()
end

function TradeskillContainer:OnOpenToSearchSchematic(strQuery)
	if GameLib.GetPlayerUnit():IsCasting() then
		return
	end

	self.wndMain:ToFront()
	self.wndMain:Show(true)
	self.wndMain:FindChild("SchematicsMainForm"):Show(true)
	self.wndMain:FindChild("AchievementsMainForm"):Show(false)
	self.wndMain:FindChild("TalentsMainForm"):Show(false)
	self.wndMain:FindChild("ToggleSchematicsBtn"):SetCheck(true)
	self.wndMain:FindChild("ToggleAchievementBtn"):SetCheck(false)
	self.wndMain:FindChild("ToggleTalentsBtn"):SetCheck(false)
	Event_FireGenericEvent("GenericEvent_InitializeSchematicsTree", self.wndMain:FindChild("SchematicsMainForm"), nil, strQuery)
	--self:RedrawAll()
end

function TradeskillContainer:OnTopTabBtn(wndHandler, wndControl)
	self:RedrawAll()
end

function TradeskillContainer:RedrawAll()
	-- TODO: We can destroy AchievementsMainForm and SchematicsMainForm's children to save memory when it's closed (after X time)
	if self.wndMain:FindChild("ToggleSchematicsBtn"):IsChecked() then
		Event_FireGenericEvent("GenericEvent_InitializeSchematicsTree", self.wndMain:FindChild("SchematicsMainForm"))
	elseif self.wndMain:FindChild("ToggleAchievementBtn"):IsChecked() then
		Event_FireGenericEvent("GenericEvent_InitializeAchievementTree", self.wndMain:FindChild("AchievementsMainForm"))
	elseif self.wndMain:FindChild("ToggleTalentsBtn"):IsChecked() then
		Event_FireGenericEvent("GenericEvent_InitializeTradeskillTalents", self.wndMain:FindChild("TalentsMainForm"))
	end
end

local TradeskillContainerInst = TradeskillContainer:new()
TradeskillContainerInst:Init()
.wndMain:FindChild("HobbyMessage"):Show(true)
end

function TradeskillTrainer:OnLearnTradeskillBtn(wndHandler, wndControl)
	if not wndHandler or not wndHandler:GetData() then
		return
	end

	local nCurrentTradeskill = self.wndMain:FindChild("LearnTradeskillBtn"):GetData()
	local tCurrTradeskillInfo = CraftingLib.GetTradeskillInfo(nCurrentTradeskill)
		if not tCurrTradeskillInfo.bIsHarvesting then
			Event_FireGenericEvent("TradeskillLearnedFromTHOR")
		else
	end
	CraftingLib.LearnTradeskill(nCurrentTradeskill)
	self:OnClose()
end

function TradeskillTrainer:OnSwapTradeskillBtn(wndHandler, wndControl) --SwapTradeskillBtn1 or SwapTradeskillBtn2, data is nTradeskillId
	if not wndHandler or not wndHandler:GetData() then
		return
	end

	local nCurrentTradeskill = self.wndMain:FindChild("LearnTradeskillBtn"):GetData()
	local tCurrTradeskillInfo = CraftingLib.GetTradeskillInfo(nCurrentTradeskill)
		if not tCurrTradeskillInfo.bIsHarvesting then
			Event_FireGenericEvent("TradeskillLearnedFromTHOR")
		else
	end

	CraftingLib.LearnTradeskill(nCurrentTradeskill, wndHandler:GetData())
	self:OnClose()
end

local TradeskillTrainerInst = TradeskillTrainer:new()
TradeskillTrainerInst:Init()
���� �_� о�XpK    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����fE*   	fyM��!F=�=�)*FXsC�f���(f%���(F%��ߨF%���(F%���(F%?��(f%��ݮf���()*F%���!F�hZ�	f�qZTfE8   o+.# ��Uo+Y%�@��4+����QD+Xpb�5�"UUU�o+k"�U� o+k"�U� o+k"�U� o+k"�U� o+k"�U� o+k"�U� �4�"UU�/QD+%	��4+~_�O+9%$o+.# ��_    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����    ����  �� ��,�:��߇�x_��G��}?�Ǡy����?�������Ŀ7Fz��GaM�ȾS����U����o.�׻Y��cqf�_�?o'��go}fh0�����Y�������-��?a����s�����,���3��p�*�q>�-�����Z�U���b��.싇s����wK?��	3n�w3���������;Ž�����2 �d���ގG@lv|h��֌�a��/ڟ_�~�~�ڨ0>�pe���G��`�g�o:9
K�}�qg`zq8��[��O��3S���}g��3��%�>�������ߧR�3�ϰ� P>`�5"�ؚ|��3�0��W��ӝ}�|o��vU?K�o�U�<4x���F��_U��r��[?kT�L�ջ��/���e�zb�=�~T�����U�|������yh����U�<�X�σ̪~R�5�g���-�N���U�|/������ypY��C�U�<Ȭ��!�_�~~  H�����yH������ypY��C�U�<Ȭ��!�w^?�����~N��gi��Wd-���(�__�>�e�����]w[?�s����W����~o����RD�=�q���f���ԌȻ���(��W���]��� '�~����o��n�q>�-�|٫�Wc�~K������Å��J���� ��?�m��Dя��W�����Cx�:�o��.����ץ�U�5V�Z|���ʷ����C�����������u��g�f��o�a��E�,�L�����v���� �,*��Ѧ���*�$���w�oM?����<p�5�����_*�.��_�LJ@L�W�3���zp(�VYe�UVYe�UVY�{���πZ���٦u�  �G� �,X�iξ���ۏ�T���D��K�md)��BT��{"NZ���nf����Rȶ��#�R�d���#��$38�M�E���k��f[��j�g͎�d:��X4���vڪ���jV%'T�J�勷��K��M�}~��k�Vz�����9{���N�����U�2�B��#I7]���ߕC��%�����XL��g����Pos��|�������鋈��K�OfH9���%C�'�q�	>>e�-�P��i�)uC�8�"%Ƶs�	�s��YOR��kc��:�n�J�vb����M�~s"���v)���I�����@��{�:7Y�P�"���+��mi�����l���K�5;��H�����M*��lЯ��]�[�Ts�Wf������܀jȭs��������r�7�m�*��]J�r��fR�۹/�4�$