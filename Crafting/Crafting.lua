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
�F1�_�ŏ�3!&�1ė��oZ��Q}I�]K�͗��\b�@uͶn��!y�S�r'�Ӆ��X!���	�,��Y���y��"�X�|��G���XH�7������j��쏡�S���B*��H{�0�^)�f�_%L٨b�g���)h��e�o�������L�ʟ����`�� �P˔DeW���Ȁ���G
�o'��ߜsǇG`��aB�F
PJ�j�Pa�u��1�Qev���~T_K|���_0`��p���A��z�@�.��c�
�׷*�z3l�To���ȗ�)17�M͊��BL%���7V�$�����t:/�Ϊ7)U5g�~3n�M�o�O���eK�?�h�W&�Y�
��o����������z��Gh}��݊g}YA��O�O�𰲽U�]T�1����Q������?Y��&M�c/P����h�.�#�5Q���x�~v_�WU9~�q �Q��x�~�}��i�˜u��u|�7X��D��~?��s3I�KD�|����ߣ�.w$���R��C)��q��޺R��a>B���]`O���%b�Z��:ʏX�#�S�����)�f�.�zd�w�,��BA�۪�2�XA���G�u��u�������6���x����]`���ɤ�M֣�F�
�das�J��0����O݄���g?c$�Ӛni=���P>bD- �9�
V}2���yk����zG�����8��E���w��'}�ө}q��#�v��ˀ�N�������NR}�'�7p~�T�_ 5�t���+P�U*��1�
�~i�_l�,���AJO|�作�AZi��r����_Y�-��������\�z_�o�b;:gM+"lOP ��H��/h?�����/�|R��	�AX�~v�ݶ��LQ���$���p��B��`0���/?��_s�X���O��)�
��z�_��V�n�zQs�m�����̀p:��(?D��K��Ei�?�rs���B'V�Y��=�En�����t^��e�|���O4F����l�}�O�)���9�P;T�^�zA�'���1���	�s=:�-�ȷ���~�F �y���	��=?��R��Γ���������R��[_����אF%��)�V�ȅ�g#w��;���g��&p�ǟ�%��.��UO!߀��z�(���4���P^�Q}���zm�l���G������r��)�?���w&�Hy�^}���-[����ӳ��@�Y��f>o��ǣp=y�������I��x��1��w��>N�j��/������t�_��N� 3Љ��v��'��a�������t�=��Q��ԯ8?��u},�l�����_H~/F��>t
`�RӦ7�1�����4�__P��J�_T�/X��%�7��X��b�����)���Gw�KJ��X�6۫B��A�%���#�ޏ�%J���A��Y�{�L ���~�T�|CCL���'���4�@�s��T6��%jp�����/c�zwC~���P���T�I�Y�,s�h�v��5@�r9�
M�!{Y ��PP�o)Θ��1�����-�h��?�P���?��#��g~$�{�O�����aTx�	K�e~��P}f����TO4�e���q��>WEg�����s)�㭛Xo��r���`y�>���r�>��o����j��~�o��� 
$�Oh���Y,�����G5'��%��[9?o��[|@2ʓ�җ�����z�N�'~���f��%��~��J�k���?p��u��3'��Gt�'�A]4�?/�������ed(�ꅦ(}/���A���}T?-��F�Ax=��[�q.�ɿa�S�ͫ��8���0^v+�߱� ��?�穰�G��M����Ҩ��	�|_�����B !HS��⑪.�^>��<������i(�4���%�_&RY�-S��:�-��Q8.z����'���z�0b/\/�z�T��O&��N �����~�FԠv ~1]�a�|���hs�Ū���]��Sߧ��)� >�:����z�p`�9Y�������NA�|{E���:a�Gϻ)�,y:�|�$��$��P^}'�0��8�L�c@y�N�A��J!$����W"���h��WR=[ק�=N�W���a�_�W5q~K�z�7jղ^J<��%�W���ڔ�V~��/��������'�̟���Yx eV��شi>�2����M�����q�,<2�����I՚�m$�OC!�Q�Oѡ�����#�7/^����|����?y>|t`pP�1�|��̬�65:����՟Zϥ)�<��t}��'���׿B�o3��l�.'��،�k��=��:��L�ǘ��&��12U�*�ɦ�Y%6��=܍�����^u`F}���~?�^��33Λ��ƱY��#0�A���5:�^��Fx�(ߙQZg���zk+�b\-�q8����!s�x�4�|�cZ�dČ�j2�3����z�.p��?���i̪�&B;�Nx�����5U_��e Y/�Y�Y�7g��7�v\�[{�|����m��W��/Y(�#4i2`a�h��vW=r;�'�c�?��S�~_�3d=�}F�,Y�z7��s����=>�y����%,lL��`��!}����-}1���6��-O1k>�]��^�i�^��ӹ��1��-��V�^T�O��$���v�^�ת�n��=�zd����?%i�7���%�Y�vZ�0�߻�1����� R>���hK�Ӟ��/�
I�~(4�������1��:6��0XxD>|��3,��O�&1�o��7�i��2c��P���d�?!��,��ڧ�S;տ$�Q��ڟ5�~ڪo��m��휏L�"���Gr�vv=��?S��o���w�Uܑ�?�0�3��߻�ױ�O�r[�˪U�l�?39��zi?��t���;�F���