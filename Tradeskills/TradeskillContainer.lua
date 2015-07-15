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
ªªª Œ_ó± Ð¾ãXpK    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªªfE*   	fyM­Ç!F=­=¶)*FXsCÏf¿ªº(f%Ÿÿý(F%Ÿêß¨F%Ÿ»ß(F%Ÿ¿Ý(F%?ªŸ(f%ŸÿÝ®fŸ¯»()*F%ÍÁó§!FúhZž	féqZTfE8   o+.# ÿ÷Uo+Y%ð@ÀÕ4+½õ÷ÔQD+Xpb¢5¬"UUUøo+k"ÿUÿ o+k"ÿUÿ o+k"ÿUÿ o+k"ÿUÿ o+k"ÿUÿ o+k"ÿUÿ õ4¬"UUÕ/QD+%	ªõ4+~_ßO+9%$o+.# îÿ_    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª  Óò± ÖŠ,û:ïŽÈß‡Ùx_‘—GŸñ}?ÆÇ y˜±ïú?ö±“÷íÏþÄ¿7FzŽGaMæ»È¾SþþÞÌU¾ïñ±öo.ó×»YþþcqfÞ_´?o'½égo}fh0ãú®âøYˆ»¥Ÿÿ-ÀÛ?aÆõÁ¼s˜±ïú¿,ýŒó3®ßpá*Žq>Ü-ý¼À÷½ZÌU¾ïÕbÆõ.ì‹‡s¤ïûwK?ãþ	3n˜w3ÆýÓÔÏÜÎüç;Å½éçÎÀ 2 ÿd½ØÞÞŽG@lv|h›€ÖŒüa‡ï/ÚŸ_‡~ö~¯Ú¨0>ãpeôýÇGàß`égéo:9
Kœ}˜qg`zq8ü»[ú÷O˜•3SîÞí}g°ô3Î…%Î>ÌçÃÝÒÏ”ß§Rô3®Ï°å P>`Þ5"¹Øš|÷ô3îŸ0ãúWÆýÓ}þ|oèçvU?KÒoüUý<4xðõ³FÕÏ_Uõó r÷ï[?kTýLñÕ»¬Ÿ/ªú™eßzb˜=ª~TÆýÓÔÏUý|±ªŸ‡«úyh±ªŸ—Uý<´XÕÏƒÌª~Rü5èg´þó-ðN±ªŸUý|/²ªŸ‡«úypYÕÏC‹Uý<È¬êç!Å_ƒ~~  HÕÏ÷«úyH±ªŸ‡«úypYÕÏC‹Uý<È¬êç!Åw^?§”™‡¾~Nöêgi´ôWd-³âõ(†__>çeàÓÏØ]w[?ÿs÷ûÞúWöêçï~o°ôóõRDÆ=˜qý†ïfÙû¾ÔŒÈ»¬Ÿ—(úÑW¿áÊ]³Ñ× '–~Æù€×oØðn–q>Ü-ý|Ù«ŸWcî~K®¤°¯¾Ã…¯ÿJööã˜ÿ ëç?Ýmý¼DÑ¾úWÆýÓÕÏCxý:•o¿.ý¬ò­ñ×¥ŸU¾5V×Z|§ô³Ê·ÆêúÏC‹ÕõŸ›û­Ÿæ£uˆègfø•oƒaø¾Eý,ÐL—¯òÀùvâáÕÏ Ð,*ß“Ñ¦¿ú™*á$Š¯ÊwŠoM?“ãÓå©<pž5ëÖãô›_*ß.õÜ_ýLJ@LÇWå3®ýæzp(ÌVYe•UVYe•UVYå{ÑúÏ€Z¿îÿÙ¦uò•  •Gò± Š,X˜iÎ¾ÆàöÛ²TÞÖ×D¹ûKÚmd)ØÐBTïÓ{"NZžœÛnfÈ‘ÁÇRÈ¶žä#³R–dâý‘#´ê$38™M±E˜³ökÒãf[ÍæƒjñgÍŽÙd:¢¯X4ÀˆvÚª­ÓæjV%'TÂJšå‹·Ÿ³K¸íMé}~×¬kì¹Vz™•¼ÏÙ9{ÎÉÐN½ÞóéÜUì2ÓBÖß#I7]ÝÙÂß•CŸû%º‡«à®XLúŠg¶¿“îPosŽ–|öš ‘—š¹é‹ˆK‡OfH9íÌâ%Cñ'”qÚ	>>eï-íPçêi‰)uC¼8÷"%Æµs»	‹sÍÌYORöÈkcü:‚nÓJïvb¦ÿž„Mü~s"Ðññv)ýîô‹Iž×ÖÃÓ@á£Ó{•:7Y’P°"‹žä+Íðmiž¯Ùá¸ÆlÖŒKÞ5;×ØH´žùæ«M*‚¿lÐ¯Øá]›[¼Ts§Wf¬ç¹ÉÚÑôÜ€jÈ­søÿóóÿùùër»7¤m¯*š¹]Jßr©©fR²Û¹/Ý4Ò$