-----------------------------------------------------------------------------------------------
-- Client Lua Script for NeedVsGreed
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Sound"

local NeedVsGreed = {}

local ktEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= ApolloColor.new("ItemQuality_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= ApolloColor.new("ItemQuality_Average"),
	[Item.CodeEnumItemQuality.Good] 			= ApolloColor.new("ItemQuality_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= ApolloColor.new("ItemQuality_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= ApolloColor.new("ItemQuality_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= ApolloColor.new("ItemQuality_Legendary"),
	[Item.CodeEnumItemQuality.Artifact]		 	= ApolloColor.new("ItemQuality_Artifact"),
}

function NeedVsGreed:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function NeedVsGreed:Init()
    Apollo.RegisterAddon(self)
end

function NeedVsGreed:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("NeedVsGreed.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function NeedVsGreed:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("LootRollUpdate",		"OnGroupLoot", self)
    Apollo.RegisterTimerHandler("WinnerCheckTimer", 	"OnOneSecTimer", self)
    Apollo.RegisterEventHandler("LootRollWon", 			"OnLootRollWon", self)
    Apollo.RegisterEventHandler("LootRollAllPassed", 	"OnLootRollAllPassed", self)

	Apollo.RegisterEventHandler("LootRollSelected", 	"OnLootRollSelected", self)
	Apollo.RegisterEventHandler("LootRollPassed", 		"OnLootRollPassed", self)
	Apollo.RegisterEventHandler("LootRoll", 			"OnLootRoll", self)

	--Apollo.RegisterEventHandler("GroupBagItemAdded", 	"OnGroupBagItemAdded", self) -- Appears deprecated

	Apollo.CreateTimer("WinnerCheckTimer", 1.0, false)
	Apollo.StopTimer("WinnerCheckTimer")
	self.wndMain = nil

	self.bTimerRunning = false
	self.tKnownLoot = nil
	self.tLootRolls = nil
	self.tMostRelevant = nil

	if GameLib.GetLootRolls() then
		self:OnGroupLoot()
	end
end

function NeedVsGreed:Close()
	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
	end
end

-----------------------------------------------------------------------------------------------
-- Main Draw Method
-----------------------------------------------------------------------------------------------
function NeedVsGreed:OnGroupLoot()
	if not self.bTimerRunning then
		Apollo.StartTimer("WinnerCheckTimer")
		self.bTimerRunning = true
	end
end

function NeedVsGreed:UpdateKnownLoot()
	self.tLootRolls = GameLib.GetLootRolls()
	if not self.tLootRolls or #self.tLootRolls <= 0 then
		self.tKnownLoot = nil
		self.tLootRolls = nil
		self.tMostRelevant = nil
		return
	end

	self.tKnownLoot = {}
	for idx, tCurrentElement in ipairs(self.tLootRolls) do
		self.tKnownLoot[tCurrentElement.nLootId] = tCurrentElement
	end

	if self.tMostRelevant then
		self.tMostRelevant = self.tKnownLoot[self.tMostRelevant.nLootId]
	end

	-- NOTE: self.tMostRelevant may have been set to nil above.
	if not self.tMostRelevant then
		for nLootId, tCurrentElement in pairs(self.tKnownLoot) do
			if not self.tMostRelevant or self.tMostRelevant.nTimeLeft > tCurrentElement.nTimeLeft then
				self.tMostRelevant = tCurrentElement
				--Print(math.floor(tCurrentElement.nTimeLeft / 1000))
			end
		end
	end
end

function NeedVsGreed:OnOneSecTimer()
	self:UpdateKnownLoot()

	if not self.tLootRolls and self.wndMain and self.wndMain:IsShown() then
		self:Close()
	end

	if self.tMostRelevant then
		self:DrawLoot(self.tMostRelevant, #self.tLootRolls)
	end

	-- Art based on anchor
	if self.wndMain and self.wndMain:IsValid() then
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect()
		if nLeft < 1 then
			self.wndMain:SetSprite("BK3:UI_BK3_Holo_Framing_2")
		else
			self.wndMain:SetSprite("BK3:UI_BK3_Holo_Framing_2")
		end
	end

	if self.tLootRolls and #self.tLootRolls > 0 then
		Apollo.StartTimer("WinnerCheckTimer")
	else
		self.bTimerRunning = false
	end
end

function NeedVsGreed:DrawLoot(tCurrentElement, nItemsInQueue)
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:GetData() then
		self:Close()
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "NeedVsGreedForm", nil, self)
		Sound.Play(Sound.PlayUIWindowNeedVsGreedOpen)
	end
	self.wndMain:SetData(tCurrentElement.nLootId)

	local itemCurrent = tCurrentElement.itemDrop
	local itemModData = tCurrentElement.tModData
	local tGlyphData = tCurrentElement.tSigilData
	self.wndMain:FindChild("LootTitle"):SetText(itemCurrent:GetName())
	self.wndMain:FindChild("LootTitle"):SetTextColor(ktEvalColors[itemCurrent:GetItemQuality()])
	self.wndMain:FindChild("GiantItemIcon"):SetData(itemCurrent)
	self.wndMain:FindChild("GiantItemIcon"):SetSprite(itemCurrent:GetIcon())
	self:HelperBuildItemTooltip(self.wndMain:FindChild("GiantItemIcon"), itemCurrent, itemModData, tGlyphData)

	if nItemsInQueue > 1 then -- Do items in queue
		self.wndMain:FindChild("ItemsInQueueIcon"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\">%s</P>", String_GetWeaselString(Apollo.GetString("NeedVsGreed_NumItems"), nItemsInQueue)))
		self.wndMain:FindChild("ItemsInQueueText"):SetText(nItemsInQueue)
	end
	self.wndMain:FindChild("ItemsInQueueIcon"):Show(nItemsInQueue > 1)
	self.wndMain:FindChild("NeedBtn"):Enable(GameLib.IsNeedRollAllowed(tCurrentElement.nLootId))

	-- TODO Timelimit
	local nTimeLeft = math.floor(tCurrentElement.nTimeLeft / 1000)
	self.wndMain:FindChild("TimeLeftText"):Show(true)

	local nTimeLeftSecs = nTimeLeft % 60
	local nTimeLeftMins = math.floor(nTimeLeft / 60)

	local strTimeLeft = tostring(nTimeLeftMins)
	if nTimeLeft < 0 then
		strTimeLeft = "0:00"
	elseif nTimeLeftSecs < 10 then
		strTimeLeft = strTimeLeft .. ":0" .. tostring(nTimeLeftSecs)
	else
		strTimeLeft = strTimeLeft .. ":" .. tostring(nTimeLeftSecs)
	end
	self.wndMain:FindChild("TimeLeftText"):SetText(strTimeLeft)
end

-----------------------------------------------------------------------------------------------
-- Chat Message Events
-----------------------------------------------------------------------------------------------

function NeedVsGreed:OnLootRollAllPassed(itemLooted)
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_EveryonePassed"), itemLooted:GetChatLinkString())
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function NeedVsGreed:OnLootRollWon(itemLoot, strWinner, bNeed)
	local strNeedOrGreed = nil
	if bNeed then
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_NeedRoll")
	else
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_GreedRoll")
	end
	
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_ItemWon"), strWinner, itemLoot:GetChatLinkString(), strNeedOrGreed)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function NeedVsGreed:OnLootRollSelected(itemLoot, strPlayer, bNeed)
	local strNeedOrGreed = nil
	if bNeed then
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_NeedRoll")
	else
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_GreedRoll")
	end

	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_LootRollSelected"), strPlayer, strNeedOrGreed, itemLoot:GetChatLinkString())
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function NeedVsGreed:OnLootRollPassed(itemLoot, strPlayer)
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_PlayerPassed"), strPlayer, itemLoot:GetChatLinkString())
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

function NeedVsGreed:OnLootRoll(itemLoot, strPlayer, nRoll, bNeed)
	local strNeedOrGreed = nil
	if bNeed then
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_NeedRoll")
	else
		strNeedOrGreed = Apollo.GetString("NeedVsGreed_GreedRoll")
	end
	
	local strResult = String_GetWeaselString(Apollo.GetString("NeedVsGreed_OnLootRoll"), strPlayer, nRoll, itemLoot:GetChatLinkString(), strNeedOrGreed)
	Event_FireGenericEvent("GenericEvent_LootChannelMessage", strResult)
end

-----------------------------------------------------------------------------------------------
-- Buttons
-----------------------------------------------------------------------------------------------

function NeedVsGreed:OnGiantItemIconMouseUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

function NeedVsGreed:OnNeedBtn(wndHandler, wndControl)
	GameLib.RollOnLoot(self.wndMain:GetData(), true)
	self:Close()
end

function NeedVsGreed:OnGreedBtn(wndHandler, wndControl)
	GameLib.RollOnLoot(self.wndMain:GetData(), false)
	self:Close()
end

function NeedVsGreed:OnPassBtn(wndHandler, wndControl)
	GameLib.PassOnLoot(self.wndMain:GetData())
	self:Close()
end

function NeedVsGreed:HelperBuildItemTooltip(wndArg, itemCurr, itemModData, tGlyphData)
	wndArg:SetTooltipDoc(nil)
	wndArg:SetTooltipDocSecondary(nil)
	local itemEquipped = itemCurr:GetEquippedItemForItemType()
	Tooltip.GetItemTooltipForm(self, wndArg, itemCurr, {bPrimary = true, bSelling = false, itemCompare = itemEquipped, itemModData = itemModData, tGlyphData = tGlyphData})
	--if itemEquipped then -- OLD
	--	Tooltip.GetItemTooltipForm(self, wndArg, itemEquipped, {bPrimary = false, bSelling = false, itemCompare = itemCurr})
	--end
end

local NeedVsGreedInst = NeedVsGreed:new()
NeedVsGreedInst:Init()
K��m���A�ӗ�z v�<o�%��ҁx�r���{?�o���M�1�?�&��L�g��F��L*y�3���y��U�o;���d���y��?��-�+����Fl��!�I�Z	�V�m�6��Ui��YS��}B�_ZM4<���Vx+w�߳os={O�ILyk`\���c��z�Kϝ�7�T/n`��v��FRBU�L����Zc���0�<)����jۂ����E�Jve�+/f�	('������g8�k��������fg�"o��zRB�3VܢH��'�T�q��0@e[k*X��a�P�`I��c#�T���C��u��->�0�
��j�f�LK���\|�	�ʠ�Q�kMA� T��m�յ�E)���4a�t�K�F�Sla�h;>ݡ.���z\� $��-Hu@M,��o��M���G���6������<���/p��͟ĩ��ع1�?)��40�`�//�(�' A�[-MB���Q}G	#�Z��%�1K��Q�r�PM�VgR����<�f"S"�^��q����`"*�ڵ8���C�z6����=y>�S%=��`G�+�&{b��.�����o��MbO=�o4�V�G�rnH���"�U�*��G��j�\�q�d�3ZtI�3l���3'Z�:@s�d2!�
�r"�����5Um4�>anb��tъ]'�j�e�j�X�2&ZӤ�I8��/�f�䏵~�I3���Z&̥�5]l��nP&��U^$1���!Q!�4	��=Fbu!�F>���&c&��%sU�o�|�^���1�����|�V�ډb;r7r�������)N�yӶ.-,�m*]���W��ԏB����ϰ�����,D*���h�G��i�|�VNFR#�"���]�DK����%M^��D(���2a�5��
?xd�Q��c���~��ޠ��!�n���3��� ��R��(��7�+�?(��ei�'�m~�h>��ᇧU��f�74���ѹo*jq�W\uGw��2�8d�-���<����(MP�<���vZk��/��b�w��#���/�m^<�}:2��@�ɐە�}����i ��bO\���n�� ��|�=�ť�@� h?��)��l�ZH�s�R��aC����Ĕe�����́�#��j_u;��;�[�i|九+L�������y�)����C��<�
D�ʼ��D�o��)�XC�B6CQ����d�Wc��4֦QA*�,Z�n�=fDf׹@4�tIV��s�9���mz��gJ2���$۩GX���I��œ�՗�4���-eF}pE�J&��H�б�K�7v��T�،��괫<�tA���F{^��G�  �	�� `�Q��yH��72ͻ��̅��l\;��=h��Zi#��������Y�%}9���የ��":R�F���:V��
��7��\X�>҄{x  -UUUt  t�� �v����   ����   �UU��  H��$    �UU�� ��m�'��  �WUU�F�$mc[?   TUUU�
��Ѭ�'    ����M��'O�$    ���� H�$I�$    ����            ����            ����            ����            ����            ����            ���� I�$I�$    ����%��I�$    ����^�p�I�$    ����wж��$    ����y ж��$    ����o�����$    ����B[?I�$    ���� ��$I�$    ����            ����            ����            ����            ����            ����            ����            ����            ���� I�$I�$    ����%��I�$    ����^�p�I�$    ����wж��$    ����y ж��$    ����o�����$    ����B[?I�$    ���� ��$I�$    ����            ����            ����            ����            ����            ����            ����            ����            ���� I�$I�$    ����%��I�$    ����^�p�I�$    ����wж��$    ����y ж��$    ����o�����$    ����B[?I�$    ���� ��$I�$    ����            ����            ����