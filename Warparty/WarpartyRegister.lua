-----------------------------------------------------------------------------------------------
-- Client Lua Script for Warparty Registration
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "GuildLib"
require "Unit"

-----------------------------------------------------------------------------------------------
-- WarpartyRegister Module Definition
-----------------------------------------------------------------------------------------------
local WarpartyRegister = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrDefaultText = CColor.new(135/255, 135/255, 135/255, 1.0)
local kcrHighlightedText = CColor.new(0, 1.0, 1.0, 1.0)

local ktResultString =
{
	[GuildLib.GuildResult_Success] 				= Apollo.GetString("Warparty_ResultSuccess"),
	[GuildLib.GuildResult_AtMaxGuildCount] 		= Apollo.GetString("Warparty_OnlyOneWarparty"),
	[GuildLib.GuildResult_InvalidGuildName] 	= Apollo.GetString("Warparty_InvalidName"),
	[GuildLib.GuildResult_GuildNameUnavailable] = Apollo.GetString("Warparty_NameUnavailable"),	-- Note - there are more reasons why it could be unavailble besides it being in use.
	[GuildLib.GuildResult_NotHighEnoughLevel] 	= Apollo.GetString("Warparty_InsufficientLevel"),
}

local crGuildNameLengthError = ApolloColor.new("AlertOrangeYellow")
local crGuildNameLengthGood = ApolloColor.new("UI_TextHoloBodyCyan")
local kstrAlreadyInGuild = Apollo.GetString("Warparty_AlreadyInWarparty")

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WarpartyRegister:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function WarpartyRegister:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegister OnLoad
-----------------------------------------------------------------------------------------------
function WarpartyRegister:OnLoad()
    self.xmlDoc = XmlDoc.CreateFromFile("WarpartyRegister.xml")
    self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function WarpartyRegister:OnDocumentReady()
    if self.xmlDoc == nil then
        return
    end

	Apollo.RegisterEventHandler("GuildResultInterceptResponse", 	"OnGuildResultInterceptResponse", self)
	Apollo.RegisterTimerHandler("ErrorMessageTimer", 				"OnErrorMessageTimer", self)
	Apollo.RegisterEventHandler("GenericEvent_RegisterWarparty", 	"OnWarpartyRegistration", self)
	Apollo.RegisterEventHandler("Event_ShowWarpartyInfo", 			"OnCancel", self)
	Apollo.RegisterEventHandler("LFGWindowHasBeenClosed", 			"OnCancel", self)

    -- load our forms
    self.wndMain = Apollo.LoadForm(self.xmlDoc, 			"WarpartyRegistrationForm", nil, self)
    self.xmlDoc = nil
    self.wndMain:Show(false)

	self.wndWarpartyName = self.wndMain:FindChild("WarpartyNameString")
	self.WndWarpartyNameLimit = self.wndMain:FindChild("WarpartyNameLimit")
	self.wndRegister = self.wndMain:FindChild("RegisterBtn")

	self.wndAlert = self.wndMain:FindChild("AlertMessage")

	self.tCreate = {}
	self.tCreate.strName = ""

	self:ResetOptions()
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegister Functions
-----------------------------------------------------------------------------------------------
function WarpartyRegister:OnWarpartyRegistration(tPos)
		-- Check to see if the player is already on an warparty of this type
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			Event_FireGenericEvent("Event_ShowWarpartyInfo")
			return
		end
	end

	self.wndMain:FindChild("WarpartyNameLabel"):SetText(Apollo.GetString("Warparty_NameYourWarparty"))

	self.wndRegister:Enable(true)
	self.wndMain:Show(true)
	self.wndMain:ToFront()
	self:Validate()
end

function WarpartyRegister:ResetOptions()
	self.tCreate.strName = ""
	self.wndAlert:Show(false)
	self.wndAlert:FindChild("MessageAlertText"):SetText("")
	self.wndAlert:FindChild("MessageBodyText"):SetText("")
	self.wndWarpartyName:SetText("")
	self:HelperClearFocus()
	self:Validate()
end

function WarpartyRegister:OnNameChanging(wndHandler, wndControl)
	self.tCreate.strName = self.wndWarpartyName:GetText()
	self:Validate()
end

function WarpartyRegister:Validate()
	local bIsTextValid = GameLib.IsTextValid(self.tCreate.strName, GameLib.CodeEnumUserText.GuildName, GameLib.CodeEnumUserTextFilterClass.Strict)
	local bValid = self:HelperCheckForEmptyString(self.tCreate.strName) and bIsTextValid

	self.wndRegister:Enable(bValid)
	self.wndMain:FindChild("ValidAlert"):Show(not bValid)
	

	local nNameLength = string.len(self.tCreate.strName or "")
	if nNameLength < 3 or nNameLength > GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName) then
		self.WndWarpartyNameLimit:SetTextColor(crGuildNameLengthError)
	else
		self.WndWarpartyNameLimit:SetTextColor(crGuildNameLengthGood)
	end

	self.WndWarpartyNameLimit:SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), nNameLength, GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName)))
end

function WarpartyRegister:HelperCheckForEmptyString(strText) -- make sure there's a valid string
	local strFirstChar
	local bHasText = false

	strFirstChar = string.find(strText, "%S")

	bHasText = strFirstChar ~= nil and string.len(strFirstChar) > 0
	return bHasText
end

function WarpartyRegister:HelperClearFocus(wndHandler, wndControl)
	self.wndWarpartyName:ClearFocus()
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegistrationForm Functions
-----------------------------------------------------------------------------------------------
function WarpartyRegister:OnRegisterBtn(wndHandler, wndControl)
	local tGuildInfo = self.tCreate

	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxGuildCount, GuildLib.GuildResult_InvalidGuildName,
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange, GuildLib.GuildResult_CannotCreateWhileInQueue }

	Event_FireGenericEvent("GuildResultInterceptRequest", GuildLib.GuildType_WarParty, self.wndMain, arGuldResultsExpected )

	GuildLib.Create(tGuildInfo.strName, GuildLib.GuildType_WarParty)
	self:HelperClearFocus()
	self.wndRegister:Enable(false)
	--NOTE: Requires a server response to progress
end

function WarpartyRegister:OnCancel(wndHandler, wndControl)
	self.wndMain:Show(false) -- hide the window
	self:HelperClearFocus()
	self:ResetOptions()
end

function WarpartyRegister:OnGuildResultInterceptResponse( guildCurr, eGuildType, eResult, wndRegistration, strAlertMessage )

	if eGuildType ~= GuildLib.GuildType_WarParty or wndRegistration ~= self.wndMain then
		return
	end

	if eResult == GuildLib.GuildResult_YouCreated or eResult == GuildLib.GuildResult_YouJoined then
		Event_FireGenericEvent("Event_ShowWarpartyInfo")
		self:OnCancel()
	end

	self.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("Warparty_Whoops"))
	Apollo.CreateTimer("ErrorMessageTimer", 3.00, false)
	self.wndAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
	self.wndAlert:Show(true)
end

function WarpartyRegister:OnErrorMessageTimer()
	self.wndAlert:Show(false)
	self.wndRegister:Enable(true) -- safe to assume since it was clicked once
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegister Instance
-----------------------------------------------------------------------------------------------
local WarpartyRegisterInst = WarpartyRegister:new()
WarpartyRegisterInst:Init()
-------------------------------------------------------

function WarpartyBattle:OnBossTokens( wndHandler, wndControl, eMouseButton )
	local wndBossToken = self.wndMain:FindChild("BossTokenEntries")
	local wndWarplotLayout = self.wndMain:FindChild("WarplotLayout")
	wndBossToken:Show(true)
	wndWarplotLayout:Show(false)
end

function WarpartyBattle:OnWarplotLayout( wndHandler, wndControl, eMouseButton  )
	local wndBossToken = self.wndMain:FindChild("BossTokenEntries")
	local wndWarplotLayout = self.wndMain:FindChild("WarplotLayout")
	wndBossToken:Show(false)
	wndWarplotLayout:Show(true)
	self:OnBattleStateChanged()
end

---------------------------------------------------------------------------------------------------
-- BossTokenEntry Functions
---------------------------------------------------------------------------------------------------
function WarpartyBattle:OnGenerateTooltip(wndControl, wndHandler, eType, oArg1, oArg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemInstance then
		Tooltip.GetItemTooltipForm(self, wndControl, oArg1, {bPrimary = true})
	elseif eType == Tooltip.TooltipGenerateType_ItemData then
		Tooltip.GetItemTooltipForm(self, wndControl, oArg1, {bPrimary = true})
	elseif eType == Tooltip.TooltipGenerateType_GameCommand then
		xml = XmlDoc.new()
		xml:AddLine(oArg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Macro then
		xml = XmlDoc.new()
		xml:AddLine(oArg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		Tooltip.GetSpellTooltipForm(self, wndControl, oArg1)
	elseif eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(oArg2)
		wndControl:SetTooltipDoc(xml)
	end
end

-----------------------------------------------------------------------------------------------
-- WarpartyBattleInstance
-----------------------------------------------------------------------------------------------
local WarpartyBattleInst = WarpartyBattle:new()
WarpartyBattleInst:Init()

ñÿ Íò± ÖŠ,ÖŠ,    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª    ªªªª  Óò± ÖŠ,û:ïÈß‡Ùx_‘—GŸñ}?ÆÇ y˜±ïú?ö±“÷íÏşÄ¿7FzGaMæ»È¾SşşŞÌU¾ïñ±öo.ó×»YşşcqfŞ_´?o'½égo}fh0ãú®âøYˆ»¥Ÿÿ-ÀÛ?aÆõÁ¼s˜±ïú¿,ıŒó3®ßpá*q>Ü-ı¼À÷½ZÌU¾ïÕbÆõ.ì‹‡s¤ïûwK?ãş	3n˜w3ÆıÓÔÏÜÎüç;Å½éçÎÀ 2 ÿd½ØŞŞG@lv|h›€ÖŒüa‡ï/ÚŸ_‡~ö~¯Ú¨0>ãpeôıÇGàß`égéo:9
Kœ}˜qg`zq8ü»[ú÷O˜•3SîŞí}g°ô3Î…%Î>ÌçÃİÒÏ”ß§Rô3®Ï°å P>`Ş5"¹Øš|÷ô3îŸ0ãúWÆıÓ}ş|oèçvU?KÒoüUı<4xğõ³FÕÏ_Uõó r÷ï[?kTıLñÕ»¬Ÿ/ªú™eßzb˜=ª~TÆıÓÔÏUı|±ªŸ‡«úyh±ªŸ—Uı<´XÕÏƒÌª~Rü5èg´şó-ğN±ªŸUı|/²ªŸ‡«úypYÕÏC‹Uı<È¬êç!Å_ƒ~~  HÕÏ÷«úyH±ªŸ‡«úypYÕÏC‹Uı<È¬êç!Åw^?§”™‡¾~Nöêgi´ôWd-³âõ(†__>çeàÓÏØ]w[?ÿs÷ûŞúWöêçï~o°ôóõRDÆ=˜qı†ïfÙû¾ÔŒÈ»¬Ÿ—(úÑW¿áÊ]³Ñ× '–~Æù€×oØğn–q>Ü-ı|Ù«ŸWcî~K®¤°¯¾Ã…¯ÿJööã˜ÿ ëç?İmı¼DÑ¾úWÆıÓÕÏCxı:•o¿.ı¬ò­ñ×¥ŸU¾5V×Z|§ô³Ê·ÆêúÏC‹ÕõŸ›û­Ÿæ£uˆègfø•oƒaø¾Eı,ĞL—¯òÀùvâáÕÏ Ğ,*ß“Ñ¦¿ú™*á$Š¯ÊwŠoM?“ãÓå©<p5ëÖãô›_*ß.õÜ_ıLJ@LÇWå3®ıæzp(ÌVYe•UVYe•UVYå{ÑúÏ€Z¿îÿÙ¦uò•  •Gò± Š,X˜iÎ¾ÆàöÛ²TŞÖ×D¹ûKÚmd)ØĞBTïÓ{"NZœÛnfÈ‘ÁÇRÈ¶ä#³R–dâı‘#´ê$38™M±E˜³ökÒãf[ÍæƒjñgÍÙd:¢¯X4ÀˆvÚª­ÓæjV%'TÂJšå‹·Ÿ³K¸íMé}~×¬kì¹Vz™•¼ÏÙ9{ÎÉĞN½ŞóéÜUì2ÓBÖß#I7]İÙÂß•CŸû%º‡«à®XLúŠg¶¿“îPos–|öš ‘—š¹é‹ˆK‡OfH9íÌâ%Cñ'”qÚ	>>eï-íPçêi‰)uC¼8÷"%Æµs»	‹sÍÌYORöÈkcü:‚nÓJïvb¦ÿ„Mü~s"Ğññv)ıîô‹I×ÖÃÓ@á£Ó{•:7Y’P°"‹ä+Íğmi¯Ùá¸ÆlÖŒKŞ5;×ØH´ùæ«M*‚¿lĞ¯Øá]›[¼Ts§Wf¬ç¹ÉÚÑôÜ€jÈ­søÿóóÿùùër»7¤m¯*š¹]Jßr©©fR²Û¹/İ4Ò$