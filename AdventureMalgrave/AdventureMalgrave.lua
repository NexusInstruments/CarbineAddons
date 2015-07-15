-----------------------------------------------------------------------------------------------
-- Client Lua Script for MalgraveAdventureResources
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

-----------------------------------------------------------------------------------------------
-- MalgraveAdventureResources Module Definition
-----------------------------------------------------------------------------------------------
local MalgraveAdventureResources = {}

local knSaveVersion = 2

function MalgraveAdventureResources:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here
	self.nFatigueMax = 75
	self.nFoodMax = 100
	self.nWaterMax = 100
	self.nFodderMax = 100
	self.nFatigueDisplayMax = 100
	self.nMembersMax = 30

    return o
end

function MalgraveAdventureResources:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return false
	end
	
	local tSave = 
	{
		tAdventureInfo = self.tAdventureInfo,
		nSaveVersion = knSaveVersion,
	}
	
	tSave.tAdventureInfo.nSaveVersion = knSaveVersion
	tSave.tAdventureInfo.nFatigueMax = self.nFatigueMax
	
	return tSave
end

function MalgraveAdventureResources:OnRestore(eType, tSavedData)
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end
	
	local bIsMalgraveAdventure = false
	local tActiveEvents = PublicEvent.GetActiveEvents()
	
	for idx, peEvent in pairs(tActiveEvents) do
		if peEvent:GetEventType() == PublicEvent.PublicEventType_Adventure_Malgrave then
			bIsMalgraveAdventure = true
			break
		end
	end
	
	self.tAdventureInfo = {}
	if bIsMalgraveAdventure and tSavedData and tSavedData.tAdventureInfo.bIsShown then
		self:Initialize()
		self:OnSet(tSavedData.nResourceMax, tSavedData.nFatigueMax)
		self:OnUpdate(tSavedData.tAdventureInfo.nFatigue, tSavedData.tAdventureInfo.nFood, tSavedData.tAdventureInfo.nWater, tSavedData.tAdventureInfo.nFodder, tSavedData.tAdventureInfo.nMembers)
	end
end

function MalgraveAdventureResources:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- MalgraveAdventureResources OnLoad
-----------------------------------------------------------------------------------------------
function MalgraveAdventureResources:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AdventureMalgrave.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function MalgraveAdventureResources:OnDocumentReady()
    Apollo.RegisterEventHandler("AdvMalgraveResourceSet", "OnSet", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnHide", self)
	Apollo.RegisterEventHandler("AdvMalgraveHideResource", "OnHide", self)
	Apollo.RegisterSlashCommand("malgraveres", "Initialize", self)
	Apollo.RegisterEventHandler("AdvMalgraveShowResource", "Initialize", self)
    Apollo.RegisterEventHandler("AdvMalgraveUpdateResource", "OnUpdate", self)
	
	if not self.tAdventureInfo then
		self.tAdventureInfo = {}
	end
end

function MalgraveAdventureResources:Initialize()
	if not self.wndMain or not self.wndMain:IsValid() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "MalgraveAdventureResourcesForm", nil, self)
		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Lore_Malgrave")})
		
		self.timerMaxProgressFalshIcon = ApolloTimer.Create(8, false, "OnMaxProgressFlashIcon", self)
		self.timerMaxProgressFalshIcon:Stop()
		self.wndMain:FindChild("LeftAssetCostume"):SetCostumeToCreatureId(19195) -- TODO Hardcoded
		self.wndMain:FindChild("LeftAssetCostume"):SetModelSequence(150)
	
		self.wndMain:Show(true)
		self.tAdventureInfo.bIsShown = true
	end
end

function MalgraveAdventureResources:OnHide()
	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
		self.tAdventureInfo.bIsShown = false
	end
end

function MalgraveAdventureResources:OnUpdate(nFatigue, nFood, nWater, nFodder, nMembers)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:Initialize()
	end
	
	local wndSubBars = self.wndMain:FindChild("SubBars")
	local wndFoodContainer = wndSubBars:FindChild("FoodBarBG")
	local wndWaterContainer = wndSubBars:FindChild("WaterBarBG")
	local wndFeedContainer = wndSubBars:FindChild("FeedBarBG")
	local wndFatigueContainer = self.wndMain:FindChild("FatigueBarBG")

	local tArgList = { nFood, nWater, nFodder }
	for idx, wndCurr in pairs({ wndFoodContainer:FindChild("FoodProgressBar"), wndWaterContainer:FindChild("WaterProgressBar"), wndFeedContainer:FindChild("FeedProgressBar") }) do
		local nNewValue = tArgList[idx]
		local nPrevValue = wndCurr:FindChild("ProgressFlashIcon"):GetData()
		if nPrevValue and nNewValue ~= 0 then
			self.timerMaxProgressFalshIcon:Start()

			wndCurr:FindChild("ProgressFlashIcon"):Show(nNewValue > nPrevValue or wndCurr:FindChild("ProgressFlashIcon"):IsShown())
			if nNewValue - nPrevValue > 0 then
				wndCurr:FindChild("ProgressFlashIcon"):SetText("+"..nNewValue - nPrevValue)
			end
		end
	end

	local nFatiguePercent = ((nFatigue / self.nFatigueMax) * 100)
	self:SetBarValueAndData(wndFoodContainer:FindChild("FoodProgressBar"), nFood, self.nFoodMax)
	self:SetBarValueAndData(wndWaterContainer:FindChild("WaterProgressBar"), nWater, self.nWaterMax)
	self:SetBarValueAndData(wndFeedContainer:FindChild("FeedProgressBar"), nFodder, self.nFodderMax)
	self:SetBarValueAndData(wndFatigueContainer:FindChild("FatigueProgressBar"), nFatiguePercent, self.nFatigueDisplayMax)
	wndFoodContainer:FindChild("FoodProgressText"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), nFood, self.nFoodMax))
	wndWaterContainer:FindChild("WaterProgressText"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), nWater, self.nWaterMax))
	wndFeedContainer:FindChild("FeedProgressText"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), nFodder, self.nFodderMax))
	wndFatigueContainer:FindChild("FatigueProgressText"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), nFatiguePercent))
	self.wndMain:FindChild("SurvivorCountText"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), nMembers, self.nMembersMax))
	
	self.tAdventureInfo.nFatigue = nFatigue
	self.tAdventureInfo.nFood = nFood
	self.tAdventureInfo.nWater = nWater
	self.tAdventureInfo.nFodder = nFodder
	self.tAdventureInfo.nMembers = nMembers
end

function MalgraveAdventureResources:OnSet(nMax, nFatigue)
	self.nFoodMax = nMax
	self.nWaterMax = nMax
	self.nFodderMax = nMax
	self.nFatigueMax = nFatigue
end

function MalgraveAdventureResources:SetBarValueAndData(wndBar, nValue, nMax)
	if nMax then
		wndBar:SetMax(nMax)
	end

	wndBar:SetProgress(nValue)
	wndBar:SetData(nValue)

	if wndBar:FindChild("ProgressFlashIcon") and not wndBar:FindChild("ProgressFlashIcon"):IsShown() then -- This will accumulate +1+1+1's into +3s
		wndBar:FindChild("ProgressFlashIcon"):SetData(nValue) -- Note fatigue bar doesn't save, but that's fine for now
	end
end

function MalgraveAdventureResources:OnMaxProgressFlashIcon()
	if self.wndMain and self.wndMain:IsValid() then
		self.timerMaxProgressFalshIcon:Stop()
		for idx, wndCurr in pairs({ self.wndMain:FindChild("SubBars:FoodBarBG:FoodProgressBar"), self.wndMain:FindChild("SubBars:WaterBarBG:WaterProgressBar"), self.wndMain:FindChild("SubBars:FeedBarBG:FeedProgressBar") }) do
			wndCurr:FindChild("ProgressFlashIcon"):Show(false)
			self:SetBarValueAndData(wndCurr, wndCurr:GetData()) -- After show false, will get ProgressFlashIcon's data too
		end
	end
end

-----------------------------------------------------------------------------------------------
-- MalgraveAdventureResources Instance
-----------------------------------------------------------------------------------------------
local MalgraveAdventureResourcesInst = MalgraveAdventureResources:new()
MalgraveAdventureResourcesInst:Init()
ient="1" IfHoldNoSignal="1" DT_VCENTER="1" DT_CENTER="1" LAnchorPoint="0.5" LAnchorOffset="-21" TAnchorPoint="0.5" TAnchorOffset="-28" RAnchorPoint="0.5" RAnchorOffset="15" BAnchorPoint="0.5" BAnchorOffset="20" NeverBringToFront="1" Picture="0" WindowSoundTemplate="ActionBarButton" BGColor="white" TextColor="white" IgnoreMouse="0" TooltipType="OnCursor" IgnoreTooltipDelay="1" TooltipColor="" DrawShortcutBottom="1">
            <Event Name="GenerateTooltip" Function="OnGenerateTooltip"/>
        </Control>
    </Form>
</Forms>
Id
	local wndBuyBtn = self.tWndRefs.wndBuyBtn
	wndBuyBtn:SetData(wndHandler:GetData())
	wndBuyBtn:Enable(wndHandler:IsChecked())
end

local AbilityVendorInst = AbilityVendor:new()
AbilityVendorInst:Init()
Ïœ¿;1òw‡¦~
iÚ“®ŠÚ–Éª¾VÛökÂC
øøQ›N•*/í;výÙIC!uÊ¦N¥}xöLaÁÏÜ>ƒSø‡™þ¿Ÿ>¡ÕR
kÀP›¶ïáýÂ±M°†bÐm7Ä	©uC eCK¼>±³Rô¦¥0/|™¾Öu6þ,•Òšdsæ™!”ÞgÌ|~»îãë81ë5)''èå!eÊâµ'AŠU¨#A7œL;6â&bû
9Ð–­‚—ÖkÚäxjÂ8ôÓóNY&¸YÀÓ‚ÜÌ>/­*Ú•Ä†Ù)H§mÑã´òµ7ˆ(æ	`Dém'E|5 t×Qb}Ó«IÍÖ&‘ýÂ}Á—HÓ<uÐ	è{+*g(USç#oØsë¯x5wTì;"–k_]h-…j‡àõËÿ$)û.R–„×ßÏ¡Ú:çYÃl&UhŠ¬|‘A †
Õ·ôVò‰·)®’À¦m$¯Z\W”VÓ²sdõ1E5HRÿAÕH·Æ–¥EB=Ûb[B¼ ÷<“Ð]5‘SBÆvlLP>ÿjŒîC’»ûP´º ÖØvŸì;ãw'9ù·)˜¦FK¶ëUL…‘ç©G¹¢IW!¯¡J‰t¬ªDÞæ¥0+êMWÏÐÍ7ÄKhWÏ{ÇûâAÿX±¦ØÑbœ+—$ã·ë1{m~°A«ÑZ‹éùÛ¸ùÇð¿Í­Sôúr7GïL"¸ˆç£è¿–0Êky›¥ŸIÈeNä¦yÒ2Xöh5Û`9Ž±ª¹ún@Õ~Ÿ¥F}½'¸§C]ôv}
‚·P!LuÛXß0“˜úWqûWoê]^¶ö5K=÷`ñôŽ#K¯“HÃåæA”ÏSÁn:‰Ò/õ…–*FuæØöðiÅ±«™BŽbj„Ž¢Ÿ?àï·øMœ>ñ#’W¿èœñaìç=X}!àhÌúN`SgTÞ;9°ß„÷áâ-_¼Û¼ˆ°+0«^RtÕ2"›×5×º¦Âë¼Çÿ}H›Ç’òè!œ£WºÒàLóò537›l÷‹]¯©8©†VÌÊ,Pûd˜Î7q«¶ ÊÎÇ‘eI¹ÝTÆ3T=2ÞòÞº–¤7E=´¾GÞ>{ß’Õ”û Üá_Sú{ó].¹²Óøª·©VÖ¶*=£ÙSm½AìEºúØu¡|²!ëUENæZrßö~¯¾©gV&(=jßÐÐÄÌè7®¢ìÙ§P.ûÄ½ûó:Fõ¤I6]Xu6˜'r0$ºŸ4Ó‹!|™qPfÚŸoÙ Å®¨?gÎ7Uvm¬fÙføá5
öÈ,Ëë¡‰y«×Ìl±Æë¦¤U¾Y»å6Ý§?pP9çüÆûdì©±^À~j•wRQ˜˜w?•Ñ¨Sr²gu1´Éìê²7mQk6éÖÜÈõÓ>¾±ÉÍ´QÜ)êŒ°qÆƒ®ËÑï»‘µõIktã£kW´PP²P;³ßÄ…A
ëá&uŸœüc=øÍö“Šv7uæ^ÔË‘¢ì«KþÂÊ>§µ[@’ðZå¯œ%œ«>DšðæÄ\%m[ø¼JŠêz'Kæäý0ß\XGå=(ÅOI†…F©0$k`m ­×oÍæÔ¸73ùaoÉk£ÈñÒyÂC»QÔ$ß‹<Þ&šÞ'=¶o$÷°ªNúé&Î¨R‰2ºŒÑq!GÏPÔ^QLêëa´­U
(žàï_Z¹«®9¢YÇ²<E¿÷)OéÑµŽÚÅ WSÕ~ «+]>§{ 1Í!nÅDÙY=ÑPn‡¾Ù{²úÄ±‡ÝSM†u?aW{õFÈhõm)y7âŽó±c¨©ý¦Tûcr¯1™zHNyÂâ+ñøâêt~¼?Î88XFHgúËÙÞ©þk7ð˜7UN8¾‹†
×3jÃ=Úèé—/APCà›ÕqÒÛmŽç}Ö´Ë´ žyqù¸ÿÜØ¼¶@Ëµˆ60}’{²þôPÛæ%À*#Íy»Ô4ëQöÞfàfŠp»ÿÇ¿Ô&äL1É§bjåÌxì½ùþ»óãÓÃw¯Ÿ<$[N‰¬Ê•¢èmRâI.jøžÞqi‚ý]²ß
æ¥Àq‚žÐñ¿´I—­q-	få˜½_«O²¥>§¹¥<ƒ>Qøé‚6«·&jô¹]'NÙ  ÿFb°–]üR÷DÚ÷ê§Ú¢"ða%æèqþó/*ŽxÊÜã÷Áâ²Óg°* YñfKˆp…Îqã+Qe&“wuŽÒµjéÃ¨Á¯Dñ™w†§mnÔ-·]ß‡mØ]ÔþÞ?4gŒ>vs0r™ßÉ:ó=:Õd[¹©“y;º†ŽRoFWa33Zb<AÅë?yíkAåŠ³Œ=u‘ÔH?ço¹ÎG§Îh»Ò´mt'jki¢‘¹m¥Üm=H3ê>žQ5‹a¥›ç­¾ÿ2ç­z?W5à;<Ÿ1ƒÚuqv]¦èìŠÒ¦áBdgi^¡"ø#,£Ckª>‹8AŠTnóøK”âkB¥sÐe„a¦CÒtåuj0û–T2yþd´ôcÿPÞˆ3ÝGIõmIj²Xfî|â(Wôà6võIö
;¡4 ê•)?Ž¼ÈËT=îÀ´+fñDØÄB FX¨ÖúzÄ›•ôx‹a€†/=/« «2Üˆ“éE¤ÛkQ½à	ö•Žò¯m—qÕÙ§Ž×Ë©Õ g¹µÎëøú—Ëœë_ëÁ?ÈË(/Çt6Œ?³Æ~[ÀÑ³Ž–¥ß±V=²)u)FæÕpðÍôÅ7Û?à;F”êkF©r†7Yßtò´ƒÄ`îµ?oo­Y÷¬»Õ9&2¬\+ü½Høò«”XFŠáÒrèt¨íôÇèpóùx{{»>µk6hž…öœ#ð[NµÞl¼DV©4ø”ð£À§èf
“~¿â*ºŽË(–úmý$¾µzKž`yTÂ&†ë–œaEöF>!4Àrø¶–¼Ã‹1ÏiÌÌµGÀYµœ
2¨$Mæƒg›:zNƒÕÆÍdÐ·SGìôÞR˜kLœQ»[øŠÓÝkTêÀBÿI€¹ê¨í~M9ilÞ;$ó· Vâ`£÷ªeß†/D*ù4Ðvv«>C§z JÉÁñ™+Ý©åU‡7°ßÉì	•WLŒ@eÔÕÚÜabËtµÃÛ”9»û43M™
¢ŸÛÍåhu†O2œŸéSì/«¸B£Gîy,Lî8ûWêGg	CÓ­f;¾:•£Í'öæ
ˆC50åžCH	­H~[²ý±«»´a;Íÿw~’X5Šÿ»gÝnø~ub"’tûáiˆ,‡'«Ž#mÚý èÙGö•þò,uÐú¦«ÈnR=21ÓãeefiL½0¿ëü
wŽ‡6ð>«’Ô˜6žˆÇZx»ôþPn·ÔÏÆ«‘\Ð¹wØm“@ì~-^«ÉxGG<fqt‹!ŒÝ{
[¸½]æŽžt›Æzú­c=²«X&PÉÐ>a	‘•v]P+ª{…w=¯ó#$eå4ì;Î´Xíêæ¯gj0?þh&«\{’Hd-“B–¶ióÇ›kLƒB§G]Kîm×²69Q´lÎJ_NKúýþŽlTì{´Pdwk4ãT{äŒ|ÚÍ3Ø;ÂVOÈ¢Ù½ÇKæØÆP¤íø&¾F®=ë{_<RŽpŠíPû]^%aeÊ­?©tíyŒOå ƒ¶s'™¡NŒêÆx‡›oÎôðzÊç6:h˜v½bÚHN{©1#{ÁN˜ú°Ñœ–UòVh¸å/×¶üS¤5Ç¶µìÙñHÍóÐ”’KT¬˜9|øf};”aÿ&ßwÚ="0",  ,TòÙ  8•äp" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>