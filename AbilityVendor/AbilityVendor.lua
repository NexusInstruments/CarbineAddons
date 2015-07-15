-----------------------------------------------------------------------------------------------
-- Client Lua Script for AbilityVendor
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "AbilityBook"
require "Tooltip"
require "Spell"
require "string"
require "math"
require "Sound"
require "Item"
require "Money"
require "AbilityBook"

local AbilityVendor = {}

local knVersion = 1

local ktstrEnumToString =
{
	[Spell.CodeEnumSpellTag.Assault] = "AbilityBuilder_Assault",
	[Spell.CodeEnumSpellTag.Support] = "AbilityBuilder_Support",
	[Spell.CodeEnumSpellTag.Utility] = "AbilityBuilder_Utility",
}

function AbilityVendor:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}

    return o
end

function AbilityVendor:Init()
    Apollo.RegisterAddon(self)
end

function AbilityVendor:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AbilityVendor.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function AbilityVendor:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("ToggleAbilitiesWindow", 				"OnAbilityVendorToggle", self)
	Apollo.RegisterEventHandler("AbilitiesWindowClose", 				"OnClose", self)

	Apollo.RegisterEventHandler("PlayerLevelChange", 					"RedrawAll", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", 				"RedrawAll", self)
	Apollo.RegisterEventHandler("CharacterEldanAugmentationsUpdated", 	"RedrawRespec", self)
end

function AbilityVendor:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local locWindowLocation = self.tWndRefs.wndMain and self.tWndRefs.wndMain:GetLocation() or self.locSavedWindowLoc

	local tSave = 
	{
		tLocation = locWindowLocation and locWindowLocation:ToTable() or nil,
		nVersion = knVersion,
	}
	
	return tSave
end

function AbilityVendor:OnRestore(eType, tSavedData)
	if tSavedData and tSavedData.nVersion  == knVersion then
		if tSavedData.tLocation then
			self.locSavedWindowLoc = WindowLocation.new(tSavedData.tLocation)
		end
	end
end

function AbilityVendor:OnClose(wndHandler, wndControl)
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		Event_CancelTraining()
		self.locSavedWindowLoc = self.tWndRefs.wndMain:GetLocation()
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
	end
end

function AbilityVendor:OnAbilityVendorToggle(bAtVendor)
	if not bAtVendor then
		return
	end

	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Close()
	else
		self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "AbilityVendorForm", nil, self)
	end

	self.tNextAbilityId = nil

	self.tWndRefs.wndBuyBtn = self.tWndRefs.wndMain:FindChild("BGBottom:BuyBtn")
	self.tWndRefs.wndBuyBtn:Enable(false)
	
	if self.locSavedWindowLoc then
		self.tWndRefs.wndMain:MoveToLocation(self.locSavedWindowLoc)
		self.locSavedWindowLoc = nil
	end

	self:RedrawAll()
end

function AbilityVendor:RedrawAll()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	local nPlayerLevel = GameLib.GetPlayerLevel()
	local nPlayerMoney = GameLib.GetPlayerCurrency():GetAmount()
	self.tWndRefs.wndMain:FindChild("BGBottom:BottomInfoInnerBG:CurrentCash"):SetAmount(nPlayerMoney, false)

	-- TEMP HACK, until we have filter
	local tHugeAbilityList =
	{
		[Spell.CodeEnumSpellTag.Assault] = {},
		[Spell.CodeEnumSpellTag.Support] = {},
		[Spell.CodeEnumSpellTag.Utility] = {},
	}
	for idx, tAbilityInfo in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Assault)) do
		tHugeAbilityList[Spell.CodeEnumSpellTag.Assault][idx] = tAbilityInfo
	end
	for idx, tAbilityInfo in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Support)) do
		tHugeAbilityList[Spell.CodeEnumSpellTag.Support][idx] = tAbilityInfo
	end
	for idx, tAbilityInfo in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Utility)) do
		tHugeAbilityList[Spell.CodeEnumSpellTag.Utility][idx] = tAbilityInfo
	end

	-- Build List
	local wndItemList = self.tWndRefs.wndMain:FindChild("ItemList")
	local nVScrollPos = wndItemList:GetVScrollPos()
	wndItemList:DestroyChildren()
	for eCategory, tFilteredAbilityList in pairs(tHugeAbilityList) do
		for idx, tBaseContainer in pairs(tFilteredAbilityList) do
			local tTierOne = tBaseContainer.tTiers[1]
			if not tBaseContainer.bIsActive and tTierOne.bCanPurchase then
				local wndCurr = Apollo.LoadForm(self.xmlDoc, "AbilityItem", wndItemList, self)
				local wndAbilityBtn = wndCurr:FindChild("AbilityItemBtn")
				local wndCost = wndAbilityBtn:FindChild("AbilityCostCash")
				local wndBlocker = wndCurr:FindChild("AbilityLockBlocker")
				local wndIcon = wndAbilityBtn:FindChild("AbilityIcon")
				
				wndCurr:SetData(tTierOne.nLevelReq) -- For sorting
				wndAbilityBtn:SetData(tTierOne.nId) -- For buy button
				wndIcon:SetSprite(tTierOne.splObject:GetIcon())
				wndAbilityBtn:FindChild("AbilityCategory"):SetText(Apollo.GetString(ktstrEnumToString[eCategory]))
				wndCost:SetAmount(tTierOne.nTrainingCost, true)
				wndCost:SetTextColor(tTierOne.nTrainingCost > nPlayerMoney and "UI_WindowTextRed" or "ffffffff")
				wndAbilityBtn:Enable(tTierOne.nLevelReq <= nPlayerLevel and tTierOne.nTrainingCost <= nPlayerMoney)

				if tTierOne.nLevelReq > nPlayerLevel then
					wndBlocker:Show(true)
					wndBlocker:SetTooltip(String_GetWeaselString(Apollo.GetString("ABV_UnlockLevel")..tTierOne.nLevelReq))
					wndAbilityBtn:FindChild("AbilityTitle"):SetText(String_GetWeaselString(Apollo.GetString("ABV_AbilityTitle"), tTierOne.strName, tTierOne.nLevelReq))
				else
					wndAbilityBtn:FindChild("AbilityTitle"):SetText(tTierOne.strName)
					Tooltip.GetSpellTooltipForm(self, wndIcon, tTierOne.splObject, {bTiers = true})
				end

				if self.tNextAbilityId and self.tNextAbilityId == tTierOne.nId then
					wndAbilityBtn:SetCheck(true)
					self.tWndRefs.wndBuyBtn:Enable(tTierOne.nLevelReq <= nPlayerLevel and tTierOne.nTrainingCost <= nPlayerMoney)
				end
			end
		end
	end

	-- Respec AMPs Item
	self:RedrawRespec()

	-- Sort
	wndItemList:ArrangeChildrenVert(0, function(a,b) return a:GetData() < b:GetData() end)
	wndItemList:SetVScrollPos(nVScrollPos)
	wndItemList:SetText(#wndItemList:GetChildren() == 0 and Apollo.GetString("AbilityBuilder_OutOfAbilities") or "")
end

function AbilityVendor:RedrawRespec()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	local nPlayerLevel = GameLib.GetPlayerLevel()
	local bAllPointsAvailable = AbilityBook.GetTotalPower() == AbilityBook.GetAvailablePower()
	local wndRespec = self.tWndRefs.wndMain:FindChild("ItemList:RespecAMPsItem")
	
	if not wndRespec or not wndRespec:IsValid() then
		wndRespec = Apollo.LoadForm(self.xmlDoc, "RespecAMPsItem", self.tWndRefs.wndMain:FindChild("ItemList"), self)
	end
	
	local wndRespecBtn = wndRespec:FindChild("RespecAMPsItemBtn")
	
	wndRespecBtn:SetData("RespecAMPsItemBtn")
	wndRespecBtn:Enable(nPlayerLevel >= 6 and not bAllPointsAvailable)	
	wndRespecBtn:FindChild("RespecAMPsSubtitle"):Show(bAllPointsAvailable)
	wndRespecBtn:FindChild("RespecAMPsTitle"):SetText(String_GetWeaselString(Apollo.GetString("ABV_RespecAmps"), nPlayerLevel < 6 and Apollo.GetString("ABV_Level6") or ""))
	
	wndRespec:SetData(9000) -- For sorting
	wndRespec:FindChild("RespecAMPsBlocker"):Show(nPlayerLevel < 6)
end

function AbilityVendor:OnBuyBtn(wndHandler, wndControl) -- BuyBtn
	if not wndHandler:GetData() then
		return
	end

	if wndHandler:GetData() == "RespecAMPsItemBtn" then
		AbilityBook.UpdateEldanAugmentationSpec(AbilityBook.GetCurrentSpec(), 0, {})
		AbilityBook.CommitEldanAugmentationSpec()
		self:OnClose()
		return
	end

	self.tNextAbilityId = nil
	local nAbilityIdToLearn = wndHandler:GetData()
	local tListOfItems = self.tWndRefs.wndMain:FindChild("ItemList"):GetChildren()

	for idx, wndCurr in pairs(tListOfItems) do
		if wndCurr:FindChild("AbilityItemBtn"):GetData() == nAbilityIdToLearn then
			local wndNextAbility = tListOfItems[idx + 1]
			local wndAbilityBtn = wndNextAbility:FindChild("AbilityItemBtn")
			if wndNextAbility and wndAbilityBtn and wndAbilityBtn:GetData() then
				self.tNextAbilityId = wndAbilityBtn:GetData()
			end
			break
		end
	end

	AbilityBook.ActivateSpell(nAbilityIdToLearn, true)
	self.tWndRefs.wndBuyBtn:SetData(self.tNextAbilityId)
end

function AbilityVendor:OnAbilityItemToggle(wndHandler, wndControl) -- AbilityItemBtn, data is abilityId
	local wndBuyBtn = self.tWndRefs.wndBuyBtn
	wndBuyBtn:SetData(wndHandler:GetData())
	wndBuyBtn:Enable(wndHandler:IsChecked())
end

local AbilityVendorInst = AbilityVendor:new()
AbilityVendorInst:Init()
Ïœ¿;1òw‡¦~
iÚ“®ŠÚ–Éª¾VÛökÂC
øøQ›N•*/í;vıÙIC!uÊ¦N¥}xöLaÁÏÜ>ƒSø‡™ş¿Ÿ>¡ÕR
kÀP›¶ïáıÂ±M°†bĞm7Ä	©uC eCK¼>±³Rô¦¥0/|™¾Öu6ş,•Òšdsæ™!”ŞgÌ|~»îãë81ë5)''èå!eÊâµ'AŠU¨#A7œL;6â&bû
9Ğ–­‚—ÖkÚäxjÂ8ôÓóNY&¸YÀÓ‚ÜÌ>/­*Ú•Ä†Ù)H§mÑã´òµ7ˆ(æ	`Dém'E|5 t×Qb}Ó«IÍÖ&‘ıÂ}Á—HÓ<uĞ	è{+*g(USç#oØsë¯x5wTì;"–k_]h-…j‡àõËÿ$)û.R–„×ßÏ¡Ú:çYÃl&UhŠ¬|‘A †
Õ·ôVò‰·)®’À¦m$¯Z\W”VÓ²sdõ1E5HRÿAÕH·Æ–¥EB=Ûb[B¼ ÷<“Ğ]5‘SBÆvlLP>ÿjŒîC’»ûP´º ÖØvŸì;ãw'9ù·)˜¦FK¶ëUL…‘ç©G¹¢IW!¯¡J‰t¬ªDŞæ¥0+êMWÏĞÍ7ÄKhWÏ{ÇûâAÿX±¦ØÑbœ+—$ã·ë1{m~°A«ÑZ‹éùÛ¸ùÇğ¿Í­Sôúr7GïL"¸ˆç£è¿–0Êky›¥ŸIÈeNä¦yÒ2Xöh5Û`9±ª¹ún@Õ~Ÿ¥F}½'¸§C]ôv}
‚·P!LuÛXß0“˜úWqûWoê]^¶ö5K=÷`ñô#K¯“HÃåæA”ÏSÁn:‰Ò/õ…–*FuæØöğiÅ±«™Bbj„¢Ÿ?àï·øMœ>ñ#’W¿èœñaìç=X}!àhÌúN`SgTŞ;9°ß„÷áâ-_¼Û¼ˆ°+0«^RtÕ2"›×5×º¦Âë¼Çÿ}H›Ç’òè!œ£WºÒàLóò537›l÷‹]¯©8©†VÌÊ,Pûd˜Î7q«¶ ÊÎÇ‘eI¹İTÆ3T=2ŞòŞº–¤7E=´¾GŞ>{ß’Õ”û Üá_Sú{ó].¹²Óøª·©VÖ¶*=£ÙSm½AìEºúØu¡|²!ëUENæZrßö~¯¾©gV&(=jßĞĞÄÌè7®¢ìÙ§P.ûÄ½ûó:Fõ¤I6]Xu6˜'r0$ºŸ4Ó‹!|™qPfÚŸoÙ Å®¨?gÎ7Uvm¬fÙføá5
öÈ,Ëë¡‰y«×Ìl±Æë¦¤U¾Y»å6İ§?pP9çüÆûdì©±^À~j•wRQ˜˜w?•Ñ¨Sr²gu1´Éìê²7mQk6éÖÜÈõÓ>¾±ÉÍ´QÜ)êŒ°qÆƒ®ËÑï»‘µõIktã£kW´PP²P;³ßÄ…A
ëá&uŸœüc=øÍö“Šv7uæ^ÔË‘¢ì«KşÂÊ>§µ[@’ğZå¯œ%œ«>DšğæÄ\%m[ø¼JŠêz'Kæäı0ß\XGå=(ÅOI†…F©0$k`m ­×oÍæÔ¸73ùaoÉk£ÈñÒyÂC»QÔ$ß‹<Ş&šŞ'=¶o$÷°ªNúé&Î¨R‰2ºŒÑq!GÏPÔ^QLêëa´­U
(àï_Z¹«®9¢YÇ²<E¿÷)OéÑµÚÅ WSÕ~ «+]>§{ 1Í!nÅDÙY=ÑPn‡¾Ù{²úÄ±‡İSM†u?aW{õFÈhõm)y7âó±c¨©ı¦Tûcr¯1™zHNyÂâ+ñøâêt~¼?Î88XFHgúËÙŞ©şk7ğ˜7UN8¾‹†
×3jÃ=Úèé—/APCà›ÕqÒÛmç}Ö´Ë´ yqù¸ÿÜØ¼¶@Ëµˆ60}’{²şôPÛæ%À*#Íy»Ô4ëQöŞfàfŠp»ÿÇ¿Ô&äL1É§bjåÌxì½ùş»óãÓÃw¯Ÿ<$[N‰¬Ê•¢èmRâI.jøŞqi‚ı]²ß
æ¥Àq‚Ğñ¿´I—­q-	få˜½_«O²¥>§¹¥<ƒ>Qøé‚6«·&jô¹]'NÙ  ÿFb°–]üR÷DÚ÷ê§Ú¢"ğa%æèqşó/*xÊÜã÷Áâ²Óg°* YñfKˆp…Îqã+Qe&“wuÒµjéÃ¨Á¯Dñ™w†§mnÔ-·]ß‡mØ]ÔşŞ?4gŒ>vs0r™ßÉ:ó=:Õd[¹©“y;º†RoFWa33Zb<AÅë?yíkAåŠ³Œ=u‘ÔH?ço¹ÎG§Îh»Ò´mt'jki¢‘¹m¥Üm=H3ê>Q5‹a¥›ç­¾ÿ2ç­z?W5à;<Ÿ1ƒÚuqv]¦èìŠÒ¦áBdgi^¡"ø#,£Ckª>‹8AŠTnóøK”âkB¥sĞe„a¦CÒtåuj0û–T2yşd´ôcÿPŞˆ3İGIõmIj²Xfî|â(Wôà6võIö
;¡4 ê•)?¼ÈËT=îÀ´+fñDØÄB FX¨ÖúzÄ›•ôx‹a€†/=/« «2Üˆ“éE¤ÛkQ½à	ö•ò¯m—qÕÙ§×Ë©Õ g¹µÎëøú—Ëœë_ëÁ?ÈË(/Çt6Œ?³Æ~[ÀÑ³–¥ß±V=²)u)FæÕpğÍôÅ7Û?à;F”êkF©r†7Yßtò´ƒÄ`îµ?oo­Y÷¬»Õ9&2¬\+ü½Høò«”XFŠáÒrèt¨íôÇèpóùx{{»>µk6h…öœ#ğ[NµŞl¼DV©4ø”ğ£À§èf
“~¿â*ºË(–úmı$¾µzK`yTÂ&†ë–œaEöF>!4Àrø¶–¼Ã‹1ÏiÌÌµGÀYµœ
2¨$Mæƒg›:zNƒÕÆÍdĞ·SGìôŞR˜kLœQ»[øŠÓİkTêÀBÿI€¹ê¨í~M9ilŞ;$ó· Vâ`£÷ªeß†/D*ù4Ğvv«>C§z JÉÁñ™+İ©åU‡7°ßÉì	•WLŒ@eÔÕÚÜabËtµÃÛ”9»û43M™
¢ŸÛÍåhu†O2œŸéSì/«¸B£Gîy,Lî8ûWêGg	CÓ­f;¾:•£Í'öæ
ˆC50åCH	­H~[²ı±«»´a;Íÿw~’X5Šÿ»gİnø~ub"’tûáiˆ,‡'«#mÚı èÙGö•şò,uĞú¦«ÈnR=21ÓãeefiL½0¿ëü
w‡6ğ>«’Ô˜6ˆÇZx»ôşPn·ÔÏÆ«‘\Ğ¹wØm“@ì~-^«ÉxGG<fqt‹!Œİ{
[¸½]æt›Æzú­c=²«X&PÉĞ>a	‘•v]P+ª{…w=¯ó#$eå4ì;Î´Xíêæ¯gj0?şh&«\{’Hd-“B–¶ióÇ›kLƒB§G]Kîm×²69Q´lÎJ_NKúışlTì{´Pdwk4ãT{äŒ|ÚÍ3Ø;ÂVOÈ¢Ù½ÇKæØÆP¤íø&¾F®=ë{_<RpŠíPû]^%aeÊ­?©tíyŒOå ƒ¶s'™¡NŒêÆx‡›oÎôğzÊç6:h˜v½bÚHN{©1#{ÁN˜ú°Ñœ–UòVh¸å/×¶üS¤5Ç¶µìÙñHÍóĞ”’KT¬˜9|øf};”aÿ&ßwÚ="0",  ,TòÙ  8•äp" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>