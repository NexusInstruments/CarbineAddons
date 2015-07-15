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