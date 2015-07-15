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
��0�*���-R����_�tfF�3=�<�U䠃�^|���اz9]wki!-�}�W
G�����5^;���9�����UHT���1°���PQ���E�^�W�i�F���/(jozz��6��^�m�N��\��5�����9 �(�z����L���c���~�6���¬����8�e4C���i���Z����;�&Z���6�I���+��;e㏛d#�l��G2	�1��&�xz�I�^�a�8�d����H��6�d�w��r��)�4��F�ѝ��7�Ȋ7���L��t�� ��0m�;��aЏC�"�C�ߏ"1�������f_~�P�0��#�p>gH!p�w���v�$#L��~겙�#�}����;;,���X��'�8�@J/����=�^=G J<jR(��6��6�A�*��(0]�ei(e��*������p���̒�,ھ,��B��Ž�ȗ�m}�i܍����7�f5v�5�v��C���Y+��P9�<��B^���E�M�-��VӔN*�ma-�~�"���Y+�%-� �夁��?��r�c�em�oso�y�'0��os��,��[)�˦�h�)��1w�čnϚ������U9�ѝZ���J�`Ν�q�{��o�'��zݶ�ܳ��Bw�ƍn�Bςh36����(-��,J�ƍ���g�1Z*���V�*[��3ݴ)��R���b�>Ji����h�"i�R]���7��Z���E[#��iz��k��<Z�s_�R��om��_�z��j�﴿���2�b��.k�hU�r�JI��^*QWc���pZz�L �I��-��Z��g<��)�\2��dy8��j/��LJ�.��R��9��Hw���'l}� Hs�$�
v��U��s�l���ۙ�!�G�JT��s���ʴ���d*4�o8UsV7�z�*f�yE���u����Z]2h�;�Ӑa�Թn���������aqEX�S�::İm|�
B���aA��t0�1�4�e%0�c��������t�Qx����I�힅/sgAM����J4�� ����Z�u0<��W�az�������5��ޱ�H�]�$�I�z96��׷oh�ɍ�m���Q�u��~���(,�����t��/0Y~��z��.��j|��#�9����!�hn�Э�c�1YQ�v�`�����C�p(�,�<>�W/�F��v��:�l��(��c�j�Y��U��"�1c�ަ�u0�}ůi��&ΐ�լ��ū�Y�Z�~������A3�_Ǩՠ�*i-G��V5��Ұ��ϥg,�uϒ�4�A��g��%i�2��jc��!��g�ͱe���M���� U�5^�I3*�G�sm���� g���V���*���3g�he�e�
��GwLC��6��~��[#�8��E�ar&�i�SCh�țOu2�0�kv3�͜%"F)�K�F�*���]n~LM���*�gj�Q��f�G
Zk��m*�z*�����>����>~w�8����7��Նz��n
C�l���z��#��߻l�.��&5o�h��G}�J��e���u�k!�E��iY��W��k����Us�K�L�5�EXzxaU�����{����ʍ�c~U�$:��#9e������6�	!�ǊRVE�-kg�����ۊ�%1C�4��SS9� 3Ƨ��O+E�<�6%�h��l�ܺ �8Is|y���?���\k�0.���\1����d��<+NR�`<fO)|x��"PV�'fv7����x��	�;�=��io�n�1����*ĚB�X螺�Vқ���۾!�p�ܰ �σ)`�\>0|��)ҌOy���M2�dr�(��5��7��4�����[X;;�>���(o�-��U!"�"i*aV�P��J�*��@��p���mkP_f����מ��{��jh��e�A�(pA,چ1�{f���`,X@:Z�S�kTM[Z$�zm��N7����4��F�c�݁Ghŷ����30��
3D���R����<�i"R�(X� �Ā�B>��Ӕ�8��	�0JD/^�8��e/��DU��?���1I1r��9>�&E�V:7��ja_���Th�]& �]1�]}��H �tǴ9�@4�Au���Y׼�Q�u*�ToKg�n�Y����(���m}�Sq3w�1dw#�Q���hL$*F�0A);G�����l$>��?Z.3#9(�P��Oxi@���m�˃P���B(���+�.sU� !�6����1f�Ea�I����"Щ$�!c+�XG��!	������s����r��j]S��]�pl��';��%u�Q����cF5�c�W��w�d�/ZAta  a)�� ����vlor="ffffffff" TooltipColor="" ProcessRightClick="1" ContentId="0" IgnoreMouse="0" NewWindowDepth="1" Tooltip="" ContentType="GCBar">
            <Event Name="QueryBeginDragDrop" Function="OnBeginCmdDragDrop"/>
            <Event Name="GenerateTooltip" Function="OnGenerateTooltip"/>
        </Control>
        <Control Class="Window" LAnchorPoint="0" LAnchorOffset="0" TAnchorPoint="0" TAnchorOffset="0" RAnchorPoint="1" RAnchorOffset="0" BAnchorPoint="1" BAnchorOffset="0" RelativeToClient="1" Font="Default" Text="" BGColor="UI_WindowBGDefault" TextColor="UI_WindowTextDefault" Template="Default" TooltipType="OnCursor" Name="Window" TooltipColor="" Sprite="BK3:btnHolo_ListView_MidDisabled" Picture="1" IgnoreMouse="1"/>