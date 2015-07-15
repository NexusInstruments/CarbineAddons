-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingAlerts
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ChatSystemLib"
require "HousingLib"
require "ChatChannelLib"

local HousingAlerts = {}

local ktHousingSimpleResultStrings =
{
	[HousingLib.HousingResult_Decor_PrereqNotMet] 		= Apollo.GetString("HousingDecorate_NeedPrereq"),
	[HousingLib.HousingResult_Decor_CannotCreateDecor] 	= Apollo.GetString("HousingDecorate_FailedToCreate"),
	[HousingLib.HousingResult_Decor_CannotModifyDecor] 	= Apollo.GetString("HousingDecorate_FailedToModify"),
	[HousingLib.HousingResult_Decor_CannotDeleteDecor] 	= Apollo.GetString("HousingDecorate_FailedToDestroy"),
	[HousingLib.HousingResult_Decor_InvalidDecor] 		= Apollo.GetString("HousingDecorate_InvalidDecor"),
	[HousingLib.HousingResult_Decor_InvalidPosition] 	= Apollo.GetString("HousingDecorate_InvalidPosition"),
	[HousingLib.HousingResult_Decor_CannotAfford]		= Apollo.GetString("HousingDecorate_NotEnoughResources"),
	[HousingLib.HousingResult_Decor_ExceedsDecorLimit] 	= Apollo.GetString("HousingDecorate_LimitReached"),
	[HousingLib.HousingResult_Decor_CouldNotValidate] 	= Apollo.GetString("HousingDecorate_ActionFailed"),
	[HousingLib.HousingResult_Decor_MustBeUnique] 		= Apollo.GetString("HousingDecorate_UniqueDecor"),
	[HousingLib.HousingResult_Decor_CannotOwnMore] 		= Apollo.GetString("HousingDecorate_CannotOwnMore"),

    [HousingLib.HousingResult_InvalidPermissions]		= Apollo.GetString("HousingLandscape_NoPermissions"),
    [HousingLib.HousingResult_InvalidResidence]			= Apollo.GetString("HousingLandscape_UnknownResidence"),
    [HousingLib.HousingResult_Failed]					= Apollo.GetString("HousingLandscape_ActionFailed"),
	[HousingLib.HousingResult_Plug_PrereqNotMet] 		= Apollo.GetString("HousingLandscape_PrereqNotMet"),
	[HousingLib.HousingResult_Plug_InvalidPlug] 		= Apollo.GetString("HousingLandscape_InvalidPlug"),
    [HousingLib.HousingResult_Plug_CannotAfford]		= Apollo.GetString("HousingLandscape_NeedMoreResources"),
    [HousingLib.HousingResult_Plug_ModifyFailed]		= Apollo.GetString("HousingLandscape_ModifyFail"),
    [HousingLib.HousingResult_Plug_MustBeUnique]		= Apollo.GetString("HousingLandscape_UniqueFail"),
    [HousingLib.HousingResult_Plug_NotActive]			= Apollo.GetString("HousingLandscape_NotActive"),
    [HousingLib.HousingResult_Plug_CannotRotate]		= Apollo.GetString("HousingLandscape_ActionFailed"),
    [HousingLib.HousingResult_InvalidResidenceName] 	= Apollo.GetString("HousingLandscape_ActionFailed"), 		   
	[HousingLib.HousingResult_MustHaveResidenceName] 	= Apollo.GetString("Housing_MustHaveResidenceName"), 

	[HousingLib.HousingResult_Neighbor_NoPendingInvite] 	= Apollo.GetString("Neighbors_NoPendingInvites"),
	[HousingLib.HousingResult_Neighbor_RequestAccepted] 	= Apollo.GetString("Neighbors_RequestAcceptedSelf"),
	[HousingLib.HousingResult_Neighbor_RequestDeclined] 	= Apollo.GetString("Neighbors_RequestDeclinedSelf"),
	[HousingLib.HousingResult_Neighbor_PlayerNotAHomeowner]	= Apollo.GetString("Neighbors_NotAHomeownerSelf"), 	
	[HousingLib.HousingResult_Neighbor_InvalidNeighbor] 	= Apollo.GetString("Neighbors_InvalidPlayer"), 		
	[HousingLib.HousingResult_Neighbor_Full] 				= Apollo.GetString("Neighbors_YourNeighborListFull"),
	[HousingLib.HousingResult_Neighbor_PlayerIsIgnored] 	= Apollo.GetString("Neighbors_PlayerIsIgnored"), 		   
	[HousingLib.HousingResult_Neighbor_IgnoredByPlayer] 	= Apollo.GetString("Neighbors_IgnoredByPlayer"),
	[HousingLib.HousingResult_Neighbor_MissingEntitlement] 	= Apollo.GetString("Neighbors_MissingEntitlement"),
	[HousingLib.HousingResult_Neighbor_PrivilegeRestricted] = Apollo.GetString("Neighbors_PrivilegeRestricted"),
}
 
local ktHousingComplexResultStringIds =
{
	[HousingLib.HousingResult_Neighbor_Success] 			= Apollo.GetString("Neighbors_SuccessMsg"),
	[HousingLib.HousingResult_Neighbor_RequestTimedOut] 	= Apollo.GetString("Neighbors_RequestTimedOut"), 	
	[HousingLib.HousingResult_Neighbor_RequestAccepted] 	= Apollo.GetString("Neighbors_RequestAccepted"),
	[HousingLib.HousingResult_Neighbor_RequestDeclined] 	= Apollo.GetString("Neighbors_RequestDeclined"), 	
	[HousingLib.HousingResult_Neighbor_PlayerNotFound] 		= Apollo.GetString("Neighbors_PlayerNotFound"), 	
	[HousingLib.HousingResult_Neighbor_PlayerNotOnline] 	= Apollo.GetString("Neighbors_PlayerNotOnline"), 	
	[HousingLib.HousingResult_Neighbor_PlayerNotAHomeowner] = Apollo.GetString("Neighbors_NotAHomeowner"), 	
	[HousingLib.HousingResult_Neighbor_PlayerDoesntExist] 	= Apollo.GetString("Neighbors_PlayerDoesntExist"), 
	[HousingLib.HousingResult_Neighbor_InvalidNeighbor] 	= Apollo.GetString("Neighbors_InvalidNeighbor"), 	
	[HousingLib.HousingResult_Neighbor_AlreadyNeighbors] 	= Apollo.GetString("Neighbors_AlreadyNeighbors"),  
	[HousingLib.HousingResult_Neighbor_InvitePending] 		= Apollo.GetString("Neighbors_InvitePending"), 	
	[HousingLib.HousingResult_Neighbor_PlayerWrongFaction] 	= Apollo.GetString("Neighbors_DifferentFaction"), 
	[HousingLib.HousingResult_Neighbor_Full] 				= Apollo.GetString("Neighbors_NeighborListFull"), 
	[HousingLib.HousingResult_Neighbor_PlayerIsIgnored] 	= Apollo.GetString("Neighbors_PlayerIsIgnored"), 	
	[HousingLib.HousingResult_Neighbor_IgnoredByPlayer] 	= Apollo.GetString("Neighbors_IgnoredByPlayer"),
	[HousingLib.HousingResult_Neighbor_MissingEntitlement] 	= Apollo.GetString("Neighbors_MissingEntitlement"),
	[HousingLib.HousingResult_Visit_Private] 				= Apollo.GetString("Neighbors_PrivateResidence"), 
	[HousingLib.HousingResult_Visit_Ignored] 				= Apollo.GetString("Neighbors_IgnoredByHost"), 	
	[HousingLib.HousingResult_Visit_InvalidWorld] 			= Apollo.GetString("Neighbors_InvalidWorld"), 	
	[HousingLib.HousingResult_Visit_Failed] 				= Apollo.GetString("Neighbors_VisitFailed"), 		
}

function HousingAlerts:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function HousingAlerts:Init()
    Apollo.RegisterAddon(self)
end

function HousingAlerts:OnLoad()
	self.tIntercept = {}
	Apollo.RegisterEventHandler("HousingResult", "OnHousingResult", self) -- game client initiated events
	Apollo.RegisterEventHandler("HousingResultInterceptRequest", "OnHousingResultInterceptRequest", self) -- lua initiated events
end

-----------------------------------------------------------------------------------------------
-- HousingAlerts Event Handlers
-----------------------------------------------------------------------------------------------

function HousingAlerts:OnHousingResultInterceptRequest( wndIntercept, arResultSet )
	if arResultSet == nil and self.tIntercept.wndIntercept == wndIntercept then
		self.tIntercept = {}
		return
	end
	
	self.tIntercept.wndIntercept = wndIntercept
	self.tIntercept.arResultSet = arResultSet
end

function HousingAlerts:OnHousingResult( strName, eResult )
	local strAlertMessage = self:GenerateAlert( strName, eResult )

	if self:IsIntercepted( eResult ) then
		local wndIntercept = self.tIntercept.wndIntercept
		self.tIntercept = {}
		Event_FireGenericEvent("HousingResultInterceptResponse", eResult, wndIntercept, strAlertMessage )
	else
		local strWrapperId = "HousingList_Error"
		if HousingLib.IsWarplotResidence() then
			strWrapperId = "Warplot_Error"
		end
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, String_GetWeaselString(Apollo.GetString(strWrapperId), strAlertMessage), "")
	end
end

-----------------------------------------------------------------------------------------------
-- HousingAlerts Functions
-----------------------------------------------------------------------------------------------

function HousingAlerts:IsIntercepted( eResult )
	if self.tIntercept == {} then
		return false
	end

	if self.tIntercept.arResultSet then
		for nIdx,eFilterResult in pairs(self.tIntercept.arResultSet) do
			if eFilterResult == eResult then
				-- match found
				return true
			end
		end
		-- match not found
		return false
	end

	-- no need to filter
	return false
end

function HousingAlerts:GenerateAlert( strName, eResult )
	local strResult = ktHousingSimpleResultStrings[eResult]
	local strComplexResult = ktHousingComplexResultStringIds[eResult]
	
	if not strResult then
		strResult = String_GetWeaselString(Apollo.GetString("Neighbors_UndefinedResult"), eResult) -- just in case
	end

	strName = tostring(strName or '') -- just in case.

	if string.len(strName) >= 1 and strComplexResult then
		strResult = String_GetWeaselString(strComplexResult, {strLiteral = strName})
	end
	
	return strResult
end

-----------------------------------------------------------------------------------------------
-- HousingAlerts Instance
-----------------------------------------------------------------------------------------------
local HousingAlertsInst = HousingAlerts:new()
HousingAlertsInst:Init()
²‘0Ó*ìè‹ˆ-Rô†°_ŒtfF3=—<ÒUä ƒæ^|ãã×Ø§z9]wki!-ğ}ÔW
GµÑø¡à5^;üâŞ9¬“×Ö®UHTéŞ1Â°œë”åPQ„òâE¤^©WÉi³F¸¾¾/(jozz¯Œ6ø^§m‚NÈÈ\ˆ…5›±º¢9 Æ(¨zÄöûÀL‘Ôòšcô¼~Ğ6­ê¹Â¬€§–»8ˆe4CîÌÉiº„šZ¿‰‰¸;¼&ZùûîŒ“6ÉIŠÒØ+©Ÿ;eã›d#†l‹G2	ã1ññ&™xzµI„^–aáº8ød£³ù‹H‘µ6êd”wÅÈr˜Ä)4·ÀFÑÑÎéŸ7ÁÈŠ7ÛÏßLÃüt’Û „Û0mš;õ¹aĞCñ"ÁC»ß"1æ™ôÖùõ‹f_~óPä0›#Õp>gH!pÎw“¢èvï$#L€~ê²™´#¤}ÆöçÁ;;,”×ÈX–Ï'ë8¨@J/’ı·ø=¹^=G J<jR(ªî…–’6ğ¤ì6A¾*éè¶(0]æei(eİò*Éõ²ˆ»Ép·…·Ì’¾,Ú¾,£ÛBİÈÅ½‚È—Šm}åiÜŒ¢Ëè7f5v©5îvÁ²C°¨ÊY+îëP9¥<’ÛB^­‹—EÜMç¸-¼VÓ”N*Åma-Ö~Ë"½ˆ–Y+Ú%-³ âå¤âê?Ûîrcöem–oso¶yİ'0ßÂos¯³,½ò[)©Ë¦÷hÑ)ÙÕ1wÆÄnÏšîü˜¹ïU9ºÑZòñ·ÀJı`Î±q£{µÊoß'ÍçzîŒ™İ¶­Ü³İÔBwÆÆnÚBÏ‚h36½ÅÙÚ(-€©,J»Æ†êägÚ1Z*ÿ™áV¥*[ªƒ3İ´)±ØRàÜb>JiÀ–êã¸hÛ"i×R]¼²š7¥ØZª‹×E[#âËiz­ëkÆê<Z¦s_£RªŸom³Ù_Üzû¾jËï´¿ÃÔ2ãb .k§hUórÛJI²“^*QWcú‹ŞpZzĞL õIŸ­-ô‹ğZ„™g<½æ)ˆ\2¿¸dy8åøj/€á¥LJ.™ÃRş¯9§ØHwãİ÷'l}É Hsñ$¯
vêUªÔsl•÷‡Û™ı!›G”JT„‡sñ¡ÿÀÊ´®šd*4®o8UsV7Æzˆ*f‘yE®Ì»uùÀ­ÔZ]2hÇ;¸ÓaœÔ¹n´ªí„Û£ø…ëaqEX…SÊ::Ä°m|´
B­‰ë³aAáít0£1‰4ğe%0€cş¥˜äú“°üt©Qx¬ÅËIÆí…/sgAM¨´ĞÀJ4ÙÛ ØŞÕ‘ZÙu0<ÈãŠWØaz¿Æäßúõ…5¼ÉŞ±çH‰]ô$ûI†z96€Ô×·ohºÉımÌÓ¥Q§uûí~ëÛ³(,ßïÿ•ƒt¤/0Y~Š•zıï.„›j|àíŠ#¨9¨·Ó!îhn¶Ğ­‚cèŸ1YQ”vÚ`¿§ÙØCåp(¨,î<>ÉW/‚Fø´vœŒ:“l»ô(™®c°jñY²U†Ê"Õ1c¼Ş¦áu0º}Å¯iõé&ÎóÕ¬µğ½Å«ÃY†Z¹~ÀŒŠ†ÎÄA3û_Ç¨Õ ´*i-G¬‚V5‹ÖÒ°µĞÏ¥g,üuÏ’ã4‘AÚùg°î™%iş2™òjc†ğ¬µ!¹ægÁÍ±e»µÀM¦õ˜ UÇ5^I3*‘GÓsm±¯¨µ g”•Vø‹“*ÖÆî3g×he“eÃ
¼GwLCû˜6›Å~ğŒ[#ï8ë¢ãEƒar&Íi…SChíÈ›Ou2Ö0ˆkv3ŒÍœ%"F)K™FÖ*¬ú¢]n~LMØêí*gjıQ‰ÿfÕG
Zk›„m*z*–×¦£½>ÕÑàò®>~w¨8¼ø¬¬7ÒÕ†z÷ê”n
CòlÆîÔzæê#¼Àß»ló.£Ô&5oíšh½ëG}³J·ùe¿‚¾u±k!äE‹•iYóúWÌ‚kÑÁµØUs³KØLğ5íEXzxaU¬ú„ñê{½ğÍÊïc~UÁ$:€Ä#9e®˜–ùÉÖ6ì	!ÇŠRVE”-kgçãÇÊÓÛŠ÷%1CÕ4¸âSS9° 3Æ§³üO+E–<Ì6%ÇhïÌlšÜº ±8Is|yşÉÅ?©øç\k†0.Ş÷¤\1 ç“ôÍd’ñ<+NR¹`<fO)|xò"PV„'fv7õŠæşx¬ğ	Œ;ñ=­âio³nö1ü„˜ˆ*ÄšBıXèºèVÒ›ş¢Û¾!å€pœÜ° ŠÏƒ)`€\>0|›í§)ÒŒOyü¦M2§dr (İÛ5”‹7µõ4²ğö€“[X;;Ÿ>‰™Ä(o†-õ‚U!"Ù"i*aV³PŸÜJØ*ÕÅ@”²p„©ÌmkP_f¿€Šª×ÃÓ{ÍàjhØeÂA›(pA,Ú†1ğ{føäñŠ’`,X@:Z€SŸkTM[Z$ÊzmñõN7Ï×ğË4¢·FÎc§İGhÅ·¾âÓç30Áè
3D»ˆR¹åü<ƒi"RÓ(Xæ ËÄ€ÍB>¢”Ó”¤8—ò	“0JD/^á8š·e/ÊÖDU×á?–®Ê1I1r‹‘9>‹&EªV:7§”ja_¨Š¼Thğ]& Æ]1ì]}øˆH ‘tÇ´9˜@4¢Au™ÑêY×¼ÒQãu*ÛToKg“nÜY€¯ƒ(ë³ò’m}Sq3w¢1dw#ŠQ ¾’hL$*F0A);GñÅø´l$>ªÖ?Z.3#9(˜P®áOxi@°ò–Úm­ËƒPµÛ÷B(½âö+á.sUë !Ø6‡µÀ¨1fšEaI– ¡Ô"Ğ©$Ô!c+XG‚!	„¾À£ó”sšÕ¾rßÇj]S¾‡]×plŞã±';‰Á%uQ¶ûÇî‹cF5»c¬W®ºw‡dÿ/ZAta  a)òÙ àÌèvlor="ffffffff" TooltipColor="" ProcessRightClick="1" ContentId="0" IgnoreMouse="0" NewWindowDepth="1" Tooltip="" ContentType="GCBar">
            <Event Name="QueryBeginDragDrop" Function="OnBeginCmdDragDrop"/>
            <Event Name="GenerateTooltip" Function="OnGenerateTooltip"/>
        </Control>
        <Control Class="Window" LAnchorPoint="0" LAnchorOffset="0" TAnchorPoint="0" TAnchorOffset="0" RAnchorPoint="1" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>