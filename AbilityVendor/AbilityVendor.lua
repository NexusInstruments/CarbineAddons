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
Ϝ�;1�w��~
iړ��ږɪ�V��k�C
��Q�N�*/�;v��IC!uʦN�}x�La���>��S������>��R
k�P�����±M��b�m7�	�uC�eCK�>��R���0/|���u6�,��Қds�!��g�|~����81�5)''��!e��'A�U�#A7�L;6�&b�
9������k��xj�8���NY&�Y�����>�/�*ڕĆٍ)H�m���7�(�	`D�m'E|5�t�Qb}ӫI��&���}��HӁ<u�	�{+*g(US�#o�s�x5wT�;"�k_]h-�j�����$)�.R����ϡ�:�Y�l&Uh��|�A��
���V�)����m$�Z\W�VӲsd�1E5HR�A�H�Ɩ�EB=�b[B� �<��]5�SB�vlLP>�j��C���P�� ��v��;�w'9��)��FK��UL���G��IW!��J�t��D��0+�MW���7�KhW�{���A�X����b�+��$��1{m~�A��Z���۸���ͭS��r7G�L"���迖0�ky���I�eN�y�2X�h5�`9�����n@�~��F}�'��C]�v}
��P!Lu�X�0���Wq�Wo�]^��5K=�`��#K��H���A��S�n:��/���*Fu����iű��B�bj����?���M�>�#�W���a��=X}!�h��N`SgT�;9�߄���-_�����+�0�^Rt�2"��5׺��라��}H�ǒ��!��W���L��537�l��]��8��V��,�P�d��7q�� ��ǑeI����T�3T=2��޺��7E=��G�>{ߒՔ� ��_S�{�].�������Vֶ*=��Sm�A�E���u�|�!�UEN�Zr߁�~���gV&(=j������7���٧P.�Ľ��:F��I6]Xu6�'r0$��4Ӌ!|�qPfڟ�o٠Ů�?g�7Uvm�f�f��5
�ȝ,�롉y���l��릤U�Y��6ݧ?pP9����d����^�~j�wRQ��w?�ѨSr�gu1����7mQk6������>���ʹQ�)��qƃ���ﻑ���Ikt�kW�P�P�P;��ąA
��&u���c=�����v7u��^�ˑ��K����>��[@��Z寜%��>D����\%m[��J��z'K���0�\XG�=(�OI��F�0$k`m ��o����73�ao�k����y�C�Q�$ߋ�<�&��'=�o$���N��&��R�2���q!G�P�^QL��a��U
(���_Z���9�Yǲ<E��)O�ѵ��� WS�~��+]>�{ 1�!n�D�Y=�P�n���{��ı��SM�u?aW{�F�h�m)y7��c����T�cr�1��zHNy��+����t~�?�88XFHg���ީ�k7�7U�N8���
�3j�=���/APC���q��m���}ִ˴ �yq����ؼ�@˵�60}�{���P��%�*#��y��4�Q��f�f�p��ǿ�&�L1ɧbj��x��������w��<$[N������mR�I.j���qi���]��
��q������I��q-	f嘽_�O��>���<�>Q��6��&j��]'N٠��Fb��]�R�D���ڢ"�a%��q��/*�x�������g�* Y�fK�p��q�+Qe&�wu�ҵj�è��D�w��mn�-�]߇m�]���?4g�>vs0r���:�=:�d[���y;���RoFWa33Zb<A��?y�kA劳�=u��H?�o��G��h�Ҵmt'jki���m��m=H�3�>�Q5�a��签�2�z?W5�;<�1��uqv]����Ҧ�Bdgi^�"�#,�Ck�>�8A�Tn��K��kB�s�e�a�C�t��uj0��T2y�d��c��Pވ3�GI�mIj�Xf�|�(W��6v�I�
;�4 �)?����T=���+f�D��B�FX���z����x�a��/=/� �2܈��E��kQ��	�����m�q�����˩ՠg�������˜�_��?��(/�t6�?��~[�ѳ���߱V=�)u)F��p����7�?�;F��kF�r�7Y��t��`�?oo�Y����9&2�\+��H��XF���r�t�����p��x{{�>�k6h����#�[N��l�DV�4������f
�~��*���(��m�$��zK�`yT�&�떜aE�F>!4�r����Ë1�i�̵G�Y��
2�$M�g�:zN����dзSG���R�kL�Q�[����kT��B�I����~M9il�;�$����V�`���e߆/D*�4�vv�>C�z�J���+ݩ�U�7����	�WL�@e����ab�t��۔9��43M�
�����hu�O2���S�/��B�G�y,L�8��W�Gg	Cӭf;�:����'��
�C50��CH	�H~[������a;��w~�X�5���g�n�~ub"�t��i�,�'��#m�� ��G�����,u�����nR=21��eefiL�0���
�w��6�>��Ԙ6���Zx���Pn���ƫ�\йw�m�@��~-^��xGG<fqt�!��{
[��]掞t��z��c=��X&P��>a	��v]P+�{�w=���#$e�4�;δX���gj�0?�h&�\{�Hd-�B��i�ǛkL�B�G]K�mײ69Q�l�J_NK�����lT�{�Pdwk4�T{��|��3�;�VOȢٽ�K���P���&�F�=�{_<R�p��P�]^%aeʭ?�t�y�O� ��s'��N���x��o���z��6:h�v�b�HN{�1#{�N���ќ�U�Vh��/׶�S�5������H�����KT��9|�f};�a�&�w�="0",  ,T��  8���p" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>