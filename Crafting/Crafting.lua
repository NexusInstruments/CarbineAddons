-----------------------------------------------------------------------------------------------
-- Client Lua Script for Crafting
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "CraftingLib"

local Crafting = {}

local ktTutorialText =
{
	[1] = "Crafting_TutorialAmps",
	[2] = "Crafting_TutorialResult",
	[3] = "Crafting_TutorialPowerSwitch",
	[4] = "Crafting_TutorialChargeMeter",
	[5] = "Crafting_TutorialFailChargeMeter",
}

local karPowerCoreTierToString =
{
	[CraftingLib.CodeEnumTradeskillTier.Novice] 	= Apollo.GetString("CRB_Tradeskill_Quartz"),
	[CraftingLib.CodeEnumTradeskillTier.Apprentice] = Apollo.GetString("CRB_Tradeskill_Sapphire"),
	[CraftingLib.CodeEnumTradeskillTier.Journeyman] = Apollo.GetString("CRB_Tradeskill_Diamond"),
	[CraftingLib.CodeEnumTradeskillTier.Artisan] 	= Apollo.GetString("CRB_Tradeskill_Chrysalus"),
	[CraftingLib.CodeEnumTradeskillTier.Expert] 	= Apollo.GetString("CRB_Tradeskill_Starshard"),
}

function Crafting:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Crafting:Init()
	Apollo.RegisterAddon(self)
end

function Crafting:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Crafting.xml") -- QuestLog will always be kept in memory, so save parsing it over and over
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Crafting:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	--Apollo.RegisterEventHandler("WindowManagementReady", 						"OnWindowManagementReady", self) -- Temporarily disabled

	Apollo.RegisterEventHandler("GenericEvent_CraftingSummaryIsFinished", 				"OnCloseBtn", self)
	Apollo.RegisterEventHandler("GenericEvent_CraftingResume_CloseCraftingWindows",		"ExitAndReset", self)
	Apollo.RegisterEventHandler("GenericEvent_BotchCraft", 								"ExitAndReset", self)
	Apollo.RegisterEventHandler("GenericEvent_StopCircuitCraft",						"ExitAndReset", self)
	Apollo.RegisterEventHandler("GenericEvent_StartCircuitCraft",						"OnGenericEvent_StartCircuitCraft", self)
	Apollo.RegisterEventHandler("CraftingInterrupted",									"OnCraftingInterrupted", self)

	Apollo.RegisterEventHandler("P2PTradeInvite", 										"OnP2PTradeExitAndReset", self)
	Apollo.RegisterEventHandler("P2PTradeWithTarget", 									"OnP2PTradeExitAndReset", self)

	self.timerCraftingSation = ApolloTimer.Create(1.0, true, "OnCrafting_TimerCraftingStationCheck", self)

	self.timerBtn = ApolloTimer.Create(3.25, false, "OnCircuitCrafting_CraftBtnTimer", self)
	self.timerBtn:Stop()

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CraftingForm", nil, self)
	self.wndMain:Show(false, true)

	self.wndTutorialPopup = self.wndMain:FindChild("TutorialPopup")
	self.wndTutorialPopup:SetData(0)
	
	self.wndTutorialButton = self.wndMain:FindChild("ShowTutorialsBtn")

	self.luaSchematic = nil --Link to CircuitBoardSchematic.lua

	self:ExitAndReset()
end

function Crafting:OnWindowManagementReady()
	--Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("DialogResponse_CraftingStation")})
end

function Crafting:OnCrafting_TimerCraftingStationCheck() -- Hackish: These are async from the rest of the UI (and definitely can't handle data being set)
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:FindChild("NoStationBlocker"):Show(not CraftingLib.IsAtCraftingStation())
	end
end

function Crafting:OnGenericEvent_StartCircuitCraft(idSchematic)
	CraftingLib.ShowTradeskillTutorial()

	-- Check if it's a subschematic, if so use the parent instead.
	local tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
	if tSchematicInfo and tSchematicInfo.nParentSchematicId and tSchematicInfo.nParentSchematicId ~= 0 then
		idSchematic = tSchematicInfo.nParentSchematicId
		tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
	end

	self.wndMain:ToFront()
	self.wndMain:Show(true)
	self.wndMain:FindChild("NotKnownBlocker"):Show(false)
	self.wndMain:FindChild("NoMaterialsBlocker"):Show(false)
	self.wndMain:FindChild("PreviewOnlyBlocker"):Show(false)
	self.wndMain:FindChild("PreviewStartCraftBtn"):SetData(idSchematic)
	self.wndMain:FindChild("CraftButton"):SetData(idSchematic)

	if self.luaSchematic then
		self.luaSchematic:delete()
		self.luaSchematic = nil
	end

	if not tSchematicInfo then
		return
	end

	local bHasMaterials = true
	local tCurrentCraft = CraftingLib.GetCurrentCraft() -- Verify materials if a craft hasn't been started yet
	local bCurrentCraftStarted = tCurrentCraft and tCurrentCraft.nSchematicId == idSchematic

	if not tCurrentCraft or tCurrentCraft.nSchematicId ~= idSchematic then
		-- Materials
		self.wndMain:FindChild("NoMaterialsBlocker"):FindChild("NoMaterialsList"):DestroyChildren()
		for idx, tData in pairs(tSchematicInfo.tMaterials) do
			local nOwnedCount = tData.itemMaterial:GetBackpackCount() + tData.itemMaterial:GetBankCount()
			if tData.nAmount > nOwnedCount then
				bHasMaterials = false
			end

			local wndCurr = Apollo.LoadForm(self.xmlDoc, "RawMaterialsItem", self.wndMain:FindChild("NoMaterialsBlocker"):FindChild("NoMaterialsList"), self)
			wndCurr:FindChild("RawMaterialsIcon"):SetSprite(tData.itemMaterial:GetIcon())
			wndCurr:FindChild("RawMaterialsIcon"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nOwnedCount, tData.nAmount))
			wndCurr:FindChild("RawMaterialsNotEnough"):Show(tData.nAmount > nOwnedCount)
			Tooltip.GetItemTooltipForm(self, wndCurr, tData.itemMaterial, {bSelling = false})
		end

		-- Fake Material
		local tAvailableCores = CraftingLib.GetAvailablePowerCores(idSchematic)
		if tAvailableCores then -- Some crafts won't have power cores
			local nOwnedCount = 0
			for idx, tMaterial in pairs(tAvailableCores) do
				nOwnedCount = nOwnedCount + tMaterial:GetBackpackCount() + tMaterial:GetBankCount()
			end

			if nOwnedCount < 1 then
				bHasMaterials = false
			end

			local wndCurr = Apollo.LoadForm(self.xmlDoc, "RawMaterialsItem", self.wndMain:FindChild("NoMaterialsBlocker"):FindChild("NoMaterialsList"), self)
			wndCurr:FindChild("RawMaterialsIcon"):SetSprite("Icon_CraftingUI_Item_Crafting_PowerCore_Green")
			wndCurr:FindChild("RawMaterialsIcon"):SetText(String_GetWeaselString(Apollo.GetString("CRB_OutOfOne"), nOwnedCount))
			wndCurr:FindChild("RawMaterialsNotEnough"):Show(nOwnedCount < 1)

			local strTooltip = Apollo.GetString("CBCrafting_PowerCoreHelperTooltip")
			if tSchematicInfo and tSchematicInfo.eTier and karPowerCoreTierToString[tSchematicInfo.eTier] then
				strTooltip = String_GetWeaselString(Apollo.GetString("Tradeskills_AnyPowerCore"), karPowerCoreTierToString[tSchematicInfo.eTier])
			end
			wndCurr:SetTooltip(strTooltip)
		end
		self.wndMain:FindChild("NoMaterialsBlocker"):FindChild("NoMaterialsList"):ArrangeChildrenHorz(1)
	end

	if not tSchematicInfo.bIsKnown and not tSchematicInfo.bIsOneUse then
		self.wndMain:FindChild("NotKnownBlocker"):Show(true)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Locked"))
	elseif not bHasMaterials then
		self.wndMain:FindChild("NoMaterialsBlocker"):Show(true)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Preview"))
	elseif not bCurrentCraftStarted then
		self.wndMain:FindChild("PreviewOnlyBlocker"):Show(true)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Preview"))
	else
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Craft"))
	end

	self.luaSchematic = CircuitBoardSchematic:new()
	self.luaSchematic:Init(self, self.xmlDoc, self.wndMain, idSchematic, bCurrentCraftStarted, bHasMaterials)

	self:DrawTutorials(false)
	self.wndTutorialPopup:Show(false)
	Event_ShowTutorial(GameLib.CodeEnumTutorial.Crafting_UI_Tutorial)

	Sound.Play(Sound.PlayUIWindowCraftingOpen)
end

function Crafting:OnPreviewStartCraft(wndHandler, wndControl) -- PreviewStartCraftBtn, data is idSchematic
	local idSchematic = wndHandler:GetData()
	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if not tCurrentCraft or tCurrentCraft.nSchematicId == 0 then -- Start if it hasn't started already (i.e. just clicking craft button)
		CraftingLib.CraftItem(idSchematic)
	end

	self.wndMain:FindChild("PostCraftBlocker"):Show(false)
	Event_FireGenericEvent("GenericEvent_StartCircuitCraft", idSchematic)
end

function Crafting:OnCraftBtnClicked(wndHandler, wndControl) -- CraftButton, data is idSchematic
	if self.luaSchematic then
		local tCurrentCraft = CraftingLib.GetCurrentCraft()
		--if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 then
			local tSchematicInfo = CraftingLib.GetSchematicInfo(tCurrentCraft.nSchematicId)
			local tMicrochips, tThresholds = self.luaSchematic:HelperGetUserSelection()
			local tCraftInfo = CraftingLib.GetPreviewInfo(tSchematicInfo.nSchematicId, tMicrochips, tThresholds)
	
			-- Order is important, must clear first
			Event_FireGenericEvent("GenericEvent_ClearCraftSummary")
	
			-- Build summary screen list
			local strSummaryMsg = Apollo.GetString("CoordCrafting_LastCraftTooltip")
			for idx, tData in pairs(tSchematicInfo.tMaterials) do
				local itemCurr = tData.itemMaterial
				local tPluralName =
				{
					["name"] = itemCurr:GetName(),
					["count"] = tonumber(tData.nAmount)
				}
				strSummaryMsg = strSummaryMsg .. "\n" .. String_GetWeaselString(Apollo.GetString("CoordCrafting_SummaryCount"), tPluralName)
			end
			Event_FireGenericEvent("GenericEvent_CraftSummaryMsg", strSummaryMsg)
	
			-- Craft
			CraftingLib.CompleteCraft(tMicrochips, tThresholds)
	
			-- Post Craft Effects
			Event_FireGenericEvent("GenericEvent_StartCraftCastBar", self.wndMain:FindChild("PostCraftBlocker"):FindChild("CraftingSummaryContainer"), tCraftInfo.itemPreview)
			self.wndMain:FindChild("PostCraftBlocker"):FindChild("MouseBlockerBtn"):Show(true)
			self.wndMain:FindChild("PostCraftBlocker"):Show(true)
			self.timerBtn:Start()
	
			-- TODO Quick hack to remove tutorial arrows
			local wndTutorialArrow = self.wndMain:FindChild("SocketsLayer"):FindChild("Tutorial_SmallRightArrow") -- Unoptimized, can be anywhere
			if wndTutorialArrow then
				wndTutorialArrow:Destroy()
			end
		--end
	end
end

function Crafting:OnCraftingInterrupted()
	self.timerBtn:Stop()
	self.wndMain:FindChild("PostCraftBlocker"):Show(false)
	self.wndMain:FindChild("PostCraftBlocker"):FindChild("MouseBlockerBtn"):Show(false)
end

function Crafting:OnCircuitCrafting_CraftBtnTimer()
	if self.luaSchematic and self.luaSchematic.tSchematicInfo then
		Event_FireGenericEvent("GenericEvent_StartCircuitCraft", self.luaSchematic.tSchematicInfo.nSchematicId)
	end
	self.wndMain:FindChild("PostCraftBlocker"):FindChild("MouseBlockerBtn"):Show(false)
end

function Crafting:OnCloseBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsVisible() then
		local tCurrentCraft = CraftingLib.GetCurrentCraft()
		if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 then
			Event_FireGenericEvent("GenericEvent_LootChannelMessage", Apollo.GetString("CoordCrafting_CraftingInterrupted"))
		end
		
		Event_FireGenericEvent("AlwaysShowTradeskills")
	end

	self:ExitAndReset()
end

function Crafting:ExitAndReset() -- Botch Craft calls this directly
	Event_CancelCrafting()

	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:FindChild("PostCraftBlocker"):Show(false)
		self.wndTutorialButton:SetCheck(false)
		self.wndMain:Close() -- Leads to OnCloseBtn
	end

	if self.luaSchematic then
		self.luaSchematic:delete()
		self.luaSchematic = nil
	end
end

function Crafting:OnP2PTradeExitAndReset()
	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 and self.wndMain and self.wndMain:IsValid() and self.wndMain:IsVisible() then
		self:ExitAndReset()
	end
end

-----------------------------------------------------------------------------------------------
-- Tutorials
-----------------------------------------------------------------------------------------------

function Crafting:OnShowTutorialsBtnToggle(wndHandler, wndControl)
	self:DrawTutorials(wndHandler:IsChecked())
end

function Crafting:DrawTutorials(bArgShow)
	for idx = 1, #ktTutorialText do
		local wndCurr = self.wndMain:FindChild("DynamicTutorial"..idx)
		if wndCurr then
			wndCurr:Show(bArgShow)
			wndCurr:SetData(idx)
		end
	end
end

function Crafting:OnTutorialItemBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl or not wndHandler:GetData() then
		return
	end

	local nLeft, nTop, nRight, nBottom = wndHandler:GetAnchorOffsets()
	self.wndTutorialPopup:SetAnchorOffsets(nRight, nBottom, nRight + self.wndTutorialPopup:GetWidth(), nBottom + self.wndTutorialPopup:GetHeight())
	self.wndTutorialPopup:FindChild("TutorialPopupText"):SetText(Apollo.GetString(ktTutorialText[wndHandler:GetData()]))
	self.wndTutorialPopup:Show(not self.wndTutorialPopup:IsShown())
end

function Crafting:OnTutorialPopupCloseBtn()
	self.wndTutorialPopup:Show(false)
end

local CraftingInst = Crafting:new()
CraftingInst:Init()
˜F1½_ğ°Å„3!&ã1Ä—Š‰oZçãQ}I‘]K«Í—Éß\b‹@uÍ¶n™ÿ!yæS¼r'ÉÓ…ú¶X!ÿÜâ	Ã,±êY¾µ†yŸ¢"ßXÇ|øG‘õßXHı7‚ş¾ÿ±ôjÂíì¡¼SÉú’B*şH{•0Ğ^)‰fª_%LÙ¨b®g“û)h¿ÅeÔoŒ‘€ù¹õLÌÊŸ¥éË`Ôæ ùPË”DeWÜúÈ€ŠøúG
Åo'ıŞßœsÇ‡G`…£aBëF
PJõj“Pa»u˜ø1ñ¹„QevìŸªù~T_K|ï“ù_0`Ü³pùåÍAØçzÛ@¾.ùócÈ
Ö×·*ùz3l©To²Ÿã£È—–)17ñMÍŠ§®BL%ÀÓü7Vî$şËõÄÁt:/¼Îª7)U5g½~3nñM”o«O·âÑeK™?®hĞW&ãYê
¥×o¡¢Éúø‚ÿ §Øz™ïƒGh}¢´İŠg}YA—ĞOˆO¡ğ°²½UÛ]Tö1Êû‹êQ¿’õÊöØ?YŸ°&Múc/PıœôÇhü.¼#ı5QÍøªxç~v_ÄWU9~Œq µQşá–xã~ü}¤iëËœu÷¯u|Š7X§ÔDüè~?˜ús3IŒKDâ|®—×Éß£ş.w$¢úRùñC)¡qõøŞºRŞïa>Bòôö]`O°ÑÃ%báZ”ÿ:ÊXş#ÊS²°Œä‹Ê)‚fÕ.§zdôwë,û³BAçÛª‡2ÑXAõ«£Güu²u¥’§­­¹ö6µ£¿x±‚¾…]`ùáÃÉ¤íMÖ£›FÇ
»das¹Jú›0û“æòOİ„ş«×g?c$ÊÓšni=ÿ´çP>bD- ã9”
V}2ú÷Øykı†çãzGÿ¡ŠòÇ8ÔEö¢ƒwĞÿ'}ƒÓ©}qêÉ#ÂvõéË€¡NÙÅõ˜÷Æ×NR}ä'Ë7p~ÉT¿_ 5Ët˜®÷+P„U*ç1¦
·~iÛ_lŸ,µ¡¾AJO|ä½œâAZi×ûrüâäŠ_Yò-¦úùˆÌï£ƒü\àz_œoáb;:gM+"lOP §HùÉ/h?òßó—¬ş/¡|RäÉ	AX ~väİ¶êÛLQ¤¾ä$Œ¤¯púˆB×í¬`0¯›¿/?šï©_sâX‹ÎO¼)Ê
æ½zñ¥_£óV³nïzQsõmòÇşë§Í€p:šš(?Dõ‚K±ƒEiÄ?‘rsı¦€B'VĞYÏ×=áEnï±ÿõµt^ßße|×¿ùO4FÏßıül±}òO‡)Œò9¢P;T¯^ zA®'§ù¹1Èş¾	”s=:‰-±È·õĞá’~òF ºy±­Â	¿û=?Íò‹R‹ıÎ“‡¹¾‘êõü¼Rª[_€ıƒçŒ×F%À„)¿VâÈ…êg#wãğ;À÷õg÷œ&p¥ÇŸ¡%ôë.ªÏUO!ß€ï ÿzâ(ùÿã4ßà¨ĞP^„Q}—âzml‰³ıGı‹òëİŞršñ)?µÃëw&å»HyÓ^}§ÜÏ-[’†ÆíÓ³ûˆ@­Y ¾f>oİÇÇ£p=y—Œ· ÄÑÿIŸÈxİ¯1·¬w§ı>NõjåØ/ƒ¾Áù×tŞ_üNñ 3Ğ‰¿¿v€æ'­÷a´Šöª¦útÂ=äÏQüíÔ¯8?¹u},‰lÑş­Õ_H~/F¼¹>t
`‰RÓ¦7Õ1æı”ÿ¹4ê__PÀñJª_Té/Xõ˜%Ä7ğ‘ïXù³b¥Ç¨Òß)•ùªGw¢KJ×ßX¢6Û«BŞÿAñ%ªê«×#‚Şæ%JõÏÍAŠ‡Yû{¶L ¿üà~æT¿|CCLö€ü'ßØ¡4ï@ısîâT6ŒÓ%jpåô¾/càzwC~«ÆúPŠö’TşIûY¢,s‚hÆvŸ£5@‘r9µ
Mí!{Y ‡¢PP¼o)Î˜…ê1ûåş“ã-ãh‚¸?¨P°ı†?¹ÿ#Àòg~$÷{Oúòç¿äıaTxó	Këe~¨æP}f³ÆõÖTO4eõ­¯qÃÑ>WEgŠùûóãs)ÿã­›Xoåær¾ş†`y¢>•ùÜrÿ>Îç†où×Ëõj¸©~µo”õí 
$OhÓõ¬Y,­±øåG5'åç%¦ó[9?o·â[|@2Ê“ÖÒ—Éû·¬zÖNÄ'~ÎşûfçÖ%ıú~îÕJ½kåÏÈ?pñøu“ù3'áîGt‰'ÁA]4Í?/õÇâ÷ô‚ê£ıed(ê…¦(}/ÏÚßAşçñ}T?-ëÅFæAx=å›×[óq.„É¿aùSüÍ«À¦8öŸí¥0^v+Øß± Çê?íç©°úGõÔMÌ“ûõÒ¨½Ø	É|_¼³ßÎúB !HS‚‹â‘ª.«^>œ¦<¶­ÛÓÇûi(4ª¿×%÷_&RY¾-Sûñ¨¾:˜-óï„Q8.z¤µßñ'©äÊzŒ0b/\/ÉzÀTŠ¹O&ÏÓN ¶ÅöÆä~ÌFÔ v ~1]aç|ŞÔ÷hs¼ÅªÄßç]ˆéSß§áö)œ >¿:‰ãıÉzæp`º9Y¯óÏàıÉóNAæ‹|{E³àı:aÚGÏ»)Š,y:é|ñ$¦Î$¶êP^}'ã°0ÆÓ8ßLßc@y‡N¥AôóJ!$ÓÆõòºŒW"Êı‰hºÌWR=[×§ü=N®W³ÏÆa_ˆW5q~K´zš7jÕ²^J<±©%™WóÉáÚ”ÄV~ï§ğ/ü­½«Şúßû'ó¯ÌŸ¿ñYx eVı”Ø´i>™2»şû‰M³ë¿Ñå»³qû,<2£ş‘ÇÌIÕšŸm$ŸOC!ÄQOÑ¡Ãùâáù#ë7/^œªÿ•|–¾Ÿ´?y>|t`pP™1ß|·òÌ¬ú65:ëùŸßÕŸZÏ¥)ü<õãt}¥'ŒŠ™×¿Båo3ğïlœ.'£øØŒòkÎï=˜:£üLîÇ˜®§&ü„12U *ëÉ¦ëY%6ïú=Ü£³¯¿«^u`F}²¬³~?«^™ã33Î›§øÆ±Yõ¦#0ıAª¶5:£^•÷Fxı(ß™QZgù‹Ézk+ßb\-ëq8¦îÇù!sËxà4æ|cZŞdÄŒşj2ÿ3³¿æŒåz˜.p·ò?³°iÌªÿ&B;ÕNxÆ÷¹¤ÿ5U_í“öe Y/­YñµY¿7gÉÛ7óv\ÿ[{·|‘ÀËñm²êW§Ç/Y(÷#4i2`aˆh–¿vW=r;·'óc´?œêS©~_Æ3d=«}Fş,Y¿z7¶Æsê‹¤ÿ=>yş…’û%,lLõ¿`¶¾!}ş·Û-}1óûô6ËŸ-O1k>Â]ò†¹^£iª^šëÓ¹¾¦1×Û-ûøV²^TÆOá$–ö¦vª^¹×ªœn—ç=Èzdë¼øõó¼?%iÒ7œïó%ë‘YŸvZò¶0­ß»°1«Œ½Ä R>ÄŠhKéÓ²ª/¦
I«~(4µ†ÚÃáéı1Ôî:6Ÿ°0XxD>|ü½3,’ÏOÖ&1×oÈù7…iÿº2c¿¡P…ìŸÒd?!äóª,ûµÚ§úS;Õ¿$¿QÁÚŸ5£~Úªo›ÂmÙíœLï¿"û³¾Grµvv=òø?Sœ¬oöÉÛwŞUÜ‘¬?¶0¨3æ‡Áß»ÿ×±¬Oîr[õËªUŸl?39õızi?ˆët…;¿Fõª„