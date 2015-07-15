--
-- CombatFloaterConfig.lua
--
-- Copyright NCsoft 2007
--

require "CombatFloaters"
require "GenericDialog"
require "Window"

---------------------------------------------------------------------------------------------------
--	CombatFloaterConfig_Init()
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Init()
	winCombatFloaterConfig = Apollo.LoadForm("UI\\CombatFloaterConfig.xml", "CombatFloaterConfig")
	winCombatFloaterConfigTree = winCombatFloaterConfig:FindChild("CombatFloaterConfig_Tree")
	
	local options = winCombatFloaterConfig:FindChild("CombatFloaterConfig_Options")
	winCombatFloaterConfigOptions = {}
	winCombatFloaterConfigOptions.faceToggle = options:FindChild("CombatFloaterConfig_Options_FontFaceToggle")
	winCombatFloaterConfigOptions.face = options:FindChild("CombatFloaterConfig_Options_FontFace")
	
	winCombatFloaterConfigOptions.face:DeleteAll()
	local fonts = Apollo.GetGameFonts()
	for index, font in pairs(fonts) do
		winCombatFloaterConfigOptions.face:AddItem(font.name, "", font.name)
	end
	
	--winCombatFloaterConfigOptions.sizeToggle = options:FindChild("CombatFloaterConfig_Options_FontSizeToggle")
	--winCombatFloaterConfigOptions.size = options:FindChild("CombatFloaterConfig_Options_FontSize")
	winCombatFloaterConfigOptions.colorToggle = options:FindChild("CombatFloaterConfig_Options_FontColorToggle")
	winCombatFloaterConfigOptions.color = options:FindChild("CombatFloaterConfig_Options_FontColor")
	--winCombatFloaterConfigOptions.flagsToggle = options:FindChild("CombatFloaterConfig_Options_FontFlagsToggle")
	--winCombatFloaterConfigOptions.flagsBold = options:FindChild("CombatFloaterConfig_Options_FontFlagsBold")
	--winCombatFloaterConfigOptions.flagsItalic = options:FindChild("CombatFloaterConfig_Options_FontFlagsItalic")
	--winCombatFloaterConfigOptions.flagsShadow = options:FindChild("CombatFloaterConfig_Options_FontFlagsShadow")
	--winCombatFloaterConfigOptions.flagsOutline = options:FindChild("CombatFloaterConfig_Options_FontFlagsOutline")
	
	winCombatFloaterConfigOptions.locationToggle = options:FindChild("CombatFloaterConfig_Options_LocationToggle")
	winCombatFloaterConfigOptions.location = options:FindChild("CombatFloaterConfig_Options_Location")
	winCombatFloaterConfigOptions.locationNode = options:FindChild("CombatFloaterConfig_Options_LocationNode")
	local nodes = CombatFloaters.GetAttachments()
	for index, node in pairs(nodes) do
		winCombatFloaterConfigOptions.locationNode:AddItem(node.name, "", node.ID)
	end
	
	winCombatFloaterConfigOptions.locationOffsetAngle = options:FindChild("CombatFloaterConfig_Options_LocationOffsetAngle")
	winCombatFloaterConfigOptions.locationOffsetDistance = options:FindChild("CombatFloaterConfig_Options_LocationOffsetDistance")
	winCombatFloaterConfigOptions.location:DeleteAll()
	local locations = CombatFloaters.GetLocations()
	for index, location in pairs(locations) do
		winCombatFloaterConfigOptions.location:AddItem(location.name, "", location.location)
	end
	
	local birthEffect = options:FindChild("CombatFloaterConfig_Options_BirthEffect")
	winCombatFloaterConfigOptions.birthToggle = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffectToggle")
	winCombatFloaterConfigOptions.birthDuration = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_Duration")
	winCombatFloaterConfigOptions.birthScaleToggle = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_ScaleToggle")
	winCombatFloaterConfigOptions.birthScaleStart = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_ScaleStart")
	winCombatFloaterConfigOptions.birthScaleEnd = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_ScaleEnd")
	winCombatFloaterConfigOptions.birthFadeToggle = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_FadeToggle")
	winCombatFloaterConfigOptions.birthFadeStart = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_FadeStart")
	winCombatFloaterConfigOptions.birthFadeEnd = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_FadeEnd")
	winCombatFloaterConfigOptions.birthTranslationToggle = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_TranslationToggle")
	winCombatFloaterConfigOptions.birthTranslationDirStart = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_VelocityDirectionStart")
	winCombatFloaterConfigOptions.birthTranslationDirEnd = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_VelocityDirectionEnd")
	winCombatFloaterConfigOptions.birthTranslationMagStart = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_VelocityMagnitudeStart")
	winCombatFloaterConfigOptions.birthTranslationMagEnd = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_VelocityMagnitudeEnd")
	winCombatFloaterConfigOptions.birthTranslationToggle = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_TranslationToggle")
	winCombatFloaterConfigOptions.birthAccelerationDirStart = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_AccelerationDirectionStart")
	winCombatFloaterConfigOptions.birthAccelerationDirEnd = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_AccelerationDirectionEnd")
	winCombatFloaterConfigOptions.birthAccelerationMagStart = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_AccelerationMagnitudeStart")
	winCombatFloaterConfigOptions.birthAccelerationMagEnd = birthEffect:FindChild("CombatFloaterConfig_Options_BirthEffect_AccelerationMagnitudeEnd")
	
	local lifeEffect = options:FindChild("CombatFloaterConfig_Options_LifeEffect")
	winCombatFloaterConfigOptions.lifeToggle = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffectToggle")
	winCombatFloaterConfigOptions.lifeDuration = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_Duration")
	winCombatFloaterConfigOptions.lifeScaleToggle = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_ScaleToggle")
	winCombatFloaterConfigOptions.lifeScaleStart = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_ScaleStart")
	winCombatFloaterConfigOptions.lifeScaleEnd = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_ScaleEnd")
	winCombatFloaterConfigOptions.lifeFadeToggle = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_FadeToggle")
	winCombatFloaterConfigOptions.lifeFadeStart = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_FadeStart")
	winCombatFloaterConfigOptions.lifeFadeEnd = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_FadeEnd")
	winCombatFloaterConfigOptions.lifeTranslationToggle = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_TranslationToggle")
	winCombatFloaterConfigOptions.lifeTranslationDirStart = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_VelocityDirectionStart")
	winCombatFloaterConfigOptions.lifeTranslationDirEnd = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_VelocityDirectionEnd")
	winCombatFloaterConfigOptions.lifeTranslationMagStart = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_VelocityMagnitudeStart")
	winCombatFloaterConfigOptions.lifeTranslationMagEnd = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_VelocityMagnitudeEnd")
	winCombatFloaterConfigOptions.lifeAccelerationDirStart = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_AccelerationDirectionStart")
	winCombatFloaterConfigOptions.lifeAccelerationDirEnd = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_AccelerationDirectionEnd")
	winCombatFloaterConfigOptions.lifeAccelerationMagStart = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_AccelerationMagnitudeStart")
	winCombatFloaterConfigOptions.lifeAccelerationMagEnd = lifeEffect:FindChild("CombatFloaterConfig_Options_LifeEffect_AccelerationMagnitudeEnd")
	
	local deathEffect = options:FindChild("CombatFloaterConfig_Options_DeathEffect")
	winCombatFloaterConfigOptions.deathToggle = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffectToggle")
	winCombatFloaterConfigOptions.deathDuration = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_Duration")
	winCombatFloaterConfigOptions.deathScaleToggle = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_ScaleToggle")
	winCombatFloaterConfigOptions.deathScaleStart = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_ScaleStart")
	winCombatFloaterConfigOptions.deathScaleEnd = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_ScaleEnd")
	winCombatFloaterConfigOptions.deathFadeToggle = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_FadeToggle")
	winCombatFloaterConfigOptions.deathFadeStart = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_FadeStart")
	winCombatFloaterConfigOptions.deathFadeEnd = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_FadeEnd")
	winCombatFloaterConfigOptions.deathTranslationToggle = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_TranslationToggle")
	winCombatFloaterConfigOptions.deathTranslationDirStart = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_VelocityDirectionStart")
	winCombatFloaterConfigOptions.deathTranslationDirEnd = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_VelocityDirectionEnd")
	winCombatFloaterConfigOptions.deathTranslationMagStart = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_VelocityMagnitudeStart")
	winCombatFloaterConfigOptions.deathTranslationMagEnd = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_VelocityMagnitudeEnd")
	winCombatFloaterConfigOptions.deathAccelerationDirStart = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_AccelerationDirectionStart")
	winCombatFloaterConfigOptions.deathAccelerationDirEnd = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_AccelerationDirectionEnd")
	winCombatFloaterConfigOptions.deathAccelerationMagStart = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_AccelerationMagnitudeStart")
	winCombatFloaterConfigOptions.deathAccelerationMagEnd = deathEffect:FindChild("CombatFloaterConfig_Options_DeathEffect_AccelerationMagnitudeEnd")
	
	winCombatFloaterMessageToggle = winCombatFloaterConfig:FindChild("CombatFloaterConfig_Message")
	winCombatFloaterMessage = {}
	local messageConfig = winCombatFloaterConfig:FindChild("CombatFloaterMessageConfig")
	winCombatFloaterMessage.source = messageConfig:FindChild("CombatFloaterMessageConfig_SourceGrid")
	winCombatFloaterMessage.add = messageConfig:FindChild("CombatFloaterMessageConfig_AddMessage")
	winCombatFloaterMessage.remove = messageConfig:FindChild("CombatFloaterMessageConfig_RemoveMessage")
	winCombatFloaterMessage.format = messageConfig:FindChild("CombatFloaterMessageConfig_MessageGrid")
	winCombatFloaterMessage.up = messageConfig:FindChild("CombatFloaterMessageConfig_MessageUp")
	winCombatFloaterMessage.down = messageConfig:FindChild("CombatFloaterMessageConfig_MessageDown")
	
	winCombatFloaterMessage.source:DeleteAll()
	for i, message in pairs(CombatFloaters.GetFormats()) do
		winCombatFloaterMessage.source:AddRow(message.name, "", message.format)
	end
		
	Apollo.RegisterEventHandler("CombatFloaters_Configure", "CombatFloaterConfig_Show")
end


-- Initialize this module
CombatFloaterConfig_Init()

---------------------------------------------------------------------------------------------------
--	CombatFloaterConfig_Show()
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Show()
	winCombatFloaterConfig:Show(true)
	CombatFloaterConfig_Refresh()
end


---------------------------------------------------------------------------------------------------
--	CombatFloaterConfig_Refresh()
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Refresh()
	winCombatFloaterConfigTree:DeleteAll()
	
	local nodes = CombatFloaters.GetNodes()
	
	for index, node in pairs(nodes) do
		local parent = nodes[ node.parent ]
		
		if parent and parent.treeNodeId then
			node.treeNodeId = winCombatFloaterConfigTree:AddNode(parent.treeNodeId, node.name, 0, node)
		else
			node.treeNodeId = winCombatFloaterConfigTree:AddNode(0, node.name, 0, node)
		end
	end
	
	local visibleNode = winCombatFloaterConfigTree:GetFirstVisibleNode()
	local data = winCombatFloaterConfigTree:GetNodeData(visibleNode)
	winCombatFloaterConfigTree:SelectNode(visibleNode)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_LoadNode(node)
	local data
	
	data = node.normal
	
	winCombatFloaterConfigOptions.faceToggle:SetCheck(data.useFontFace)
	winCombatFloaterConfigOptions.face:Enable(data.useFontFace)
	if data.useFontFace then
		winCombatFloaterConfigOptions.face:SelectItemByText(data.fontFace)
	end
	

	winCombatFloaterConfigOptions.colorToggle:SetCheck(data.useFontColor)
	winCombatFloaterConfigOptions.color:Enable(data.useFontColor)
	
	winCombatFloaterConfigOptions.locationToggle:SetCheck(data.useLocation)
	winCombatFloaterConfigOptions.location:Enable(data.useLocation)
	winCombatFloaterConfigOptions.locationOffsetAngle:Enable(data.useLocation)
	winCombatFloaterConfigOptions.locationOffsetDistance:Enable(data.useLocation)
	if data.useLocation then
		winCombatFloaterConfigOptions.location:SelectItemByData(data.location)
		winCombatFloaterConfigOptions.locationNode:SelectItemByData(data.attachment)
		winCombatFloaterConfigOptions.locationNode:Enable(data.location ~= CombatFloaters.CombatMessageLocation_Screen)
		winCombatFloaterConfigOptions.locationOffsetAngle:SetValue(data.locationAngle)
		winCombatFloaterConfigOptions.locationOffsetDistance:SetValue(data.locationDistance)
	end
	
	winCombatFloaterConfigOptions.birthToggle:SetCheck(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthDuration:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthScaleToggle:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthScaleStart:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthScaleEnd:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthFadeToggle:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthFadeStart:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthFadeEnd:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthTranslationToggle:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthTranslationDirStart:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthTranslationDirEnd:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthTranslationMagStart:Enable(data.useBirthEffect)
	winCombatFloaterConfigOptions.birthTranslationMagEnd:Enable(data.useBirthEffect)
	if data.useBirthEffect then
		winCombatFloaterConfigOptions.birthDuration:SetValue(data.birthDuration)

		winCombatFloaterConfigOptions.birthScaleToggle:SetCheck(data.birthEffect.useScale)
		winCombatFloaterConfigOptions.birthScaleStart:Enable(data.birthEffect.useScale)
		winCombatFloaterConfigOptions.birthScaleEnd:Enable(data.birthEffect.useScale)
		if data.birthEffect.useScale then
			winCombatFloaterConfigOptions.birthScaleStart:SetValue(data.birthEffect.scaleBegin)
			winCombatFloaterConfigOptions.birthScaleEnd:SetValue(data.birthEffect.scaleEnd)
		end
		
		winCombatFloaterConfigOptions.birthFadeToggle:SetCheck(data.birthEffect.useFade)
		winCombatFloaterConfigOptions.birthFadeStart:Enable(data.birthEffect.useFade)
		winCombatFloaterConfigOptions.birthFadeEnd:Enable(data.birthEffect.useFade)
		if data.birthEffect.useFade then
			winCombatFloaterConfigOptions.birthFadeStart:SetValue(data.birthEffect.alphaBegin)
			winCombatFloaterConfigOptions.birthFadeEnd:SetValue(data.birthEffect.alphaEnd)
		end
		
		winCombatFloaterConfigOptions.birthTranslationToggle:SetCheck(data.birthEffect.useTranslation)
		winCombatFloaterConfigOptions.birthTranslationDirStart:Enable(data.birthEffect.useTranslation)
		winCombatFloaterConfigOptions.birthTranslationDirEnd:Enable(data.birthEffect.useTranslation)
		winCombatFloaterConfigOptions.birthTranslationMagStart:Enable(data.birthEffect.useTranslation)
		winCombatFloaterConfigOptions.birthTranslationMagEnd:Enable(data.birthEffect.useTranslation)
		if data.birthEffect.useTranslation then
			winCombatFloaterConfigOptions.birthTranslationDirStart:SetValue(data.birthEffect.velocityDirectionMin)
			winCombatFloaterConfigOptions.birthTranslationDirEnd:SetValue(data.birthEffect.velocityDirectionMax)
			winCombatFloaterConfigOptions.birthTranslationMagStart:SetValue(data.birthEffect.velocityMagnitudeMin)
			winCombatFloaterConfigOptions.birthTranslationMagEnd:SetValue(data.birthEffect.velocityMagnitudeMax)
			
			winCombatFloaterConfigOptions.birthAccelerationDirStart:SetValue(data.birthEffect.accelDirectionMin)
			winCombatFloaterConfigOptions.birthAccelerationDirEnd:SetValue(data.birthEffect.accelDirectionMax)
			winCombatFloaterConfigOptions.birthAccelerationMagStart:SetValue(data.birthEffect.accelMagnitudeMin)
			winCombatFloaterConfigOptions.birthAccelerationMagEnd:SetValue(data.birthEffect.accelMagnitudeMax)
		end
	end
	
	
	winCombatFloaterConfigOptions.lifeToggle:SetCheck(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeDuration:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeScaleToggle:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeScaleStart:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeScaleEnd:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeFadeToggle:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeFadeStart:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeFadeEnd:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeTranslationToggle:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeTranslationDirStart:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeTranslationDirEnd:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeTranslationMagStart:Enable(data.useLifeEffect)
	winCombatFloaterConfigOptions.lifeTranslationMagEnd:Enable(data.useLifeEffect)
	if data.useLifeEffect then
		winCombatFloaterConfigOptions.lifeDuration:SetValue(data.lifeDuration)

		winCombatFloaterConfigOptions.lifeScaleToggle:SetCheck(data.lifeEffect.useScale)
		winCombatFloaterConfigOptions.lifeScaleStart:Enable(data.lifeEffect.useScale)
		winCombatFloaterConfigOptions.lifeScaleEnd:Enable(data.lifeEffect.useScale)
		if data.lifeEffect.useScale then
			winCombatFloaterConfigOptions.lifeScaleStart:SetValue(data.lifeEffect.scaleBegin)
			winCombatFloaterConfigOptions.lifeScaleEnd:SetValue(data.lifeEffect.scaleEnd)
		end
		
		winCombatFloaterConfigOptions.lifeFadeToggle:SetCheck(data.lifeEffect.useFade)
		winCombatFloaterConfigOptions.lifeFadeStart:Enable(data.lifeEffect.useFade)
		winCombatFloaterConfigOptions.lifeFadeEnd:Enable(data.lifeEffect.useFade)
		if data.lifeEffect.useFade then
			winCombatFloaterConfigOptions.lifeFadeStart:SetValue(data.lifeEffect.alphaBegin)
			winCombatFloaterConfigOptions.lifeFadeEnd:SetValue(data.lifeEffect.alphaEnd)
		end
		
		winCombatFloaterConfigOptions.lifeTranslationToggle:SetCheck(data.lifeEffect.useTranslation)
		winCombatFloaterConfigOptions.lifeTranslationDirStart:Enable(data.lifeEffect.useTranslation)
		winCombatFloaterConfigOptions.lifeTranslationDirEnd:Enable(data.lifeEffect.useTranslation)
		winCombatFloaterConfigOptions.lifeTranslationMagStart:Enable(data.lifeEffect.useTranslation)
		winCombatFloaterConfigOptions.lifeTranslationMagEnd:Enable(data.lifeEffect.useTranslation)
		if data.lifeEffect.useTranslation then
			winCombatFloaterConfigOptions.lifeTranslationDirStart:SetValue(data.lifeEffect.velocityDirectionMin)
			winCombatFloaterConfigOptions.lifeTranslationDirEnd:SetValue(data.lifeEffect.velocityDirectionMax)
			winCombatFloaterConfigOptions.lifeTranslationMagStart:SetValue(data.lifeEffect.velocityMagnitudeMin)
			winCombatFloaterConfigOptions.lifeTranslationMagEnd:SetValue(data.lifeEffect.velocityMagnitudeMax)
			
			winCombatFloaterConfigOptions.lifeAccelerationDirStart:SetValue(data.lifeEffect.accelDirectionMin)
			winCombatFloaterConfigOptions.lifeAccelerationDirEnd:SetValue(data.lifeEffect.accelDirectionMax)
			winCombatFloaterConfigOptions.lifeAccelerationMagStart:SetValue(data.lifeEffect.accelMagnitudeMin)
			winCombatFloaterConfigOptions.lifeAccelerationMagEnd:SetValue(data.lifeEffect.accelMagnitudeMax)
		end
	end	
		
	winCombatFloaterConfigOptions.deathToggle:SetCheck(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathDuration:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathScaleToggle:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathScaleStart:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathScaleEnd:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathFadeToggle:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathFadeStart:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathFadeEnd:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathTranslationToggle:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathTranslationDirStart:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathTranslationDirEnd:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathTranslationMagStart:Enable(data.useDeathEffect)
	winCombatFloaterConfigOptions.deathTranslationMagEnd:Enable(data.useDeathEffect)
	if data.useDeathEffect then
		winCombatFloaterConfigOptions.deathDuration:SetValue(data.deathDuration)

		winCombatFloaterConfigOptions.deathScaleToggle:SetCheck(data.deathEffect.useScale)
		winCombatFloaterConfigOptions.deathScaleStart:Enable(data.deathEffect.useScale)
		winCombatFloaterConfigOptions.deathScaleEnd:Enable(data.deathEffect.useScale)
		if data.deathEffect.useScale then
			winCombatFloaterConfigOptions.deathScaleStart:SetValue(data.deathEffect.scaleBegin)
			winCombatFloaterConfigOptions.deathScaleEnd:SetValue(data.deathEffect.scaleEnd)
		end
		
		winCombatFloaterConfigOptions.deathFadeToggle:SetCheck(data.deathEffect.useFade)
		winCombatFloaterConfigOptions.deathFadeStart:Enable(data.deathEffect.useFade)
		winCombatFloaterConfigOptions.deathFadeEnd:Enable(data.deathEffect.useFade)
		if data.deathEffect.useFade then
			winCombatFloaterConfigOptions.deathFadeStart:SetValue(data.deathEffect.alphaBegin)
			winCombatFloaterConfigOptions.deathFadeEnd:SetValue(data.deathEffect.alphaEnd)
		end
		
		winCombatFloaterConfigOptions.deathTranslationToggle:SetCheck(data.deathEffect.useTranslation)
		winCombatFloaterConfigOptions.deathTranslationDirStart:Enable(data.deathEffect.useTranslation)
		winCombatFloaterConfigOptions.deathTranslationDirEnd:Enable(data.deathEffect.useTranslation)
		winCombatFloaterConfigOptions.deathTranslationMagStart:Enable(data.deathEffect.useTranslation)
		winCombatFloaterConfigOptions.deathTranslationMagEnd:Enable(data.deathEffect.useTranslation)
		if data.deathEffect.useTranslation then
			winCombatFloaterConfigOptions.deathTranslationDirStart:SetValue(data.deathEffect.velocityDirectionMin)
			winCombatFloaterConfigOptions.deathTranslationDirEnd:SetValue(data.deathEffect.velocityDirectionMax)
			winCombatFloaterConfigOptions.deathTranslationMagStart:SetValue(data.deathEffect.velocityMagnitudeMin)
			winCombatFloaterConfigOptions.deathTranslationMagEnd:SetValue(data.deathEffect.velocityMagnitudeMax)
			
			winCombatFloaterConfigOptions.deathAccelerationDirStart:SetValue(data.deathEffect.accelDirectionMin)
			winCombatFloaterConfigOptions.deathAccelerationDirEnd:SetValue(data.deathEffect.accelDirectionMax)
			winCombatFloaterConfigOptions.deathAccelerationMagStart:SetValue(data.deathEffect.accelMagnitudeMin)
			winCombatFloaterConfigOptions.deathAccelerationMagEnd:SetValue(data.deathEffect.accelMagnitudeMax)
		end
	end	

	-- configure message information
	winCombatFloaterMessageToggle:SetCheck(data.useFormat)
	winCombatFloaterMessage.source:Enable(data.useFormat)
	winCombatFloaterMessage.add:Enable(data.useFormat)
	winCombatFloaterMessage.remove:Enable(data.useFormat)
	winCombatFloaterMessage.format:Enable(data.useFormat)
	winCombatFloaterMessage.up:Enable(data.useFormat)
	winCombatFloaterMessage.down:Enable(data.useFormat)
	
	-- clear last item clicked
	winCombatFloaterMessage.add:SetData(nil)
	winCombatFloaterMessage.remove:SetData(nil)
	winCombatFloaterMessage.up:SetData(nil)
	winCombatFloaterMessage.down:SetData(nil)

	if data.useFormat then
		-- repopulate the source window
		winCombatFloaterMessage.source:DeleteAll()
		for i, message in pairs(CombatFloaters.GetFormats()) do
			winCombatFloaterMessage.source:AddRow(message.name, "", message.format)
		end
		
		winCombatFloaterMessage.format:DeleteAll()
		for index, format in ipairs(data.format) do
			-- add format to the destination window
			winCombatFloaterMessage.format:AddRow(CombatFloaters.FormatDisplayName(format), "", format)
			-- remove format from the source window
			winCombatFloaterMessage.source:DeleteRowsByData(format)
		end
	end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_OnTreeSelectionChange(windowId, controlId, selectedNode, unselectedNode)
	local data = winCombatFloaterConfigTree:GetNodeData(selectedNode)
	if data then 
		CombatFloaterConfig_LoadNode(data)
	end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Close_OnPress(windowId, controlId)
	winCombatFloaterConfig:Show(false)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Message_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useFormat = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Message_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useFormat = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterMessageConfig_Source_SelectionChanged(windowId, controlId, newSelection, oldSelection)
	winCombatFloaterMessage.add:SetData(winCombatFloaterMessage.source:GetItemData(newSelection, 0))
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterMessageConfig_Message_SelectionChanged(windowId, controlId, newSelection, oldSelection)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	winCombatFloaterMessage.remove:SetData(winCombatFloaterMessage.format:GetItemData(newSelection, 0))
	
	winCombatFloaterMessage.up:Enable(newSelection ~= 0)
	winCombatFloaterMessage.up:SetData(newSelection + 1)
	winCombatFloaterMessage.down:Enable(node.format[newSelection + 2] ~= nil)
	winCombatFloaterMessage.down:SetData(newSelection + 1)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterMessageConfig_AddMessage_Pressed(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	local format = controlId:GetData()
	
	local node = data.normal

	node.useFormat = true
	for index = 1,CombatFloaters.CombatMessageStringCount() do
		if not node.format[index] or node.format[index] == CombatFloaters.CombatMessageString_None() then
			node.format[index] = format
			break
		end
	end
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterMessageConfig_RemoveMessage_Pressed(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	local format = controlId:GetData()
	
	local node = data.normal

	node.useFormat = true
	
	for index = 1,CombatFloaters.CombatMessageStringCount() do
		if node.format[index] == format then
			while node.format[index] do
				node.format[index] = node.format[index + 1]
				index = index + 1
			end
			break
		end
	end
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterMessageConfig_MessageUp_Pressed(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	local index = controlId:GetData()
	
	local node = data.normal

	node.useFormat = true
	local temp = node.format[index - 1]
	node.format[index - 1] = node.format[index]
	node.format[index] = temp
	
	-- Grids are 0 based while lua arrays are 1 based so this is the same as index - 1 - 1
	winCombatFloaterMessage.format:SelectCell(index - 2, 0)
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterMessageConfig_MessageDown_Pressed(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	local index = controlId:GetData()
	
	local node = data.normal

	node.useFormat = true
	local temp = node.format[index + 1]
	node.format[index + 1] = node.format[index]
	node.format[index] = temp
	
	-- Grids are 0 based while lua arrays are 1 based so this is the same as index + 1 - 1
	winCombatFloaterMessage.format:SelectCell(index, 0)
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontFaceToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useFontFace = true	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontFaceToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useFontFace = false	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontSizeToggle_OnCheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--	
--	local node = data.normal
--
--	node.useFontSize = true	
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontSizeToggle_OnUncheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--	
--	local node = data.normal
--
--	node.useFontSize = false	
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontColorToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useFontColor = true	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontColorToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useFontColor = false	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsToggle_OnCheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--	
--	local node = data.normal
--
--	node.useFontFlags = true	
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsToggle_OnUncheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--	
--	local node = data.normal
--
--	node.useFontFlags = false	
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontFace_Changed(windowId, controlId, selected, unselected)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	local fontFace = winCombatFloaterConfigOptions.face:GetDataFromIndex(selected)
	
	local node = data.normal

	node.useFontFace = true	
	node.fontFace = fontFace
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontSize_Changed(windowId, controlId, newValue, oldValue)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	node.useFontSize = true
--	node.fontSize = newValue
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontColor_Pressed(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal

	GenericDialog.ColorPicker(node.fontColor, CombatFloaterConfig_Options_FontColor_ColorPickerCallback, data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_FontColor_ColorPickerCallback(windowId, event, eventArgs, contextArray)
	if event == "ButtonSignal" and eventArgs[ "Button" ] == "DC_Ok" then
		local data = contextArray[ 1 ]
		
		local node = data.normal
		
		node.useFontColor = true
		node.fontColor = eventArgs[ "Value" ]
		
		CombatFloaters.SaveNode(data)
		CombatFloaterConfig_LoadNode(data)
	end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsBold_OnCheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontBold = true
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsBold_OnUncheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontBold = false
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsItalic_OnCheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontItalic = true
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsItalic_OnUncheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontItalic = false
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsShadow_OnCheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontShadow = true
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsShadow_OnUncheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontShadow = false
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsOutline_OnCheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontOutline = true
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--function CombatFloaterConfig_Options_FontFlagsOutline_OnUncheck(windowId, controlId)
--	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
--	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
--
--	local node = data.normal
--	
--	if not node.useFontFlags then
--		node.fontBold = false
--		node.fontItalic = false
--		node.fontShadow = false
--		node.fontOutline = false
--	end
--	
--	node.useFontFlags = true
--	node.fontOutline = false
--	
--	CombatFloaters.SaveNode(data)
--	CombatFloaterConfig_LoadNode(data)
--end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LocationToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal
	
	node.useLocation = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LocationToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal
	
	node.useLocation = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_Location_Changed(windowId, controlId, newSelection, oldSelection)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal
	
	node.useLocation = true
	node.location = ComboBoxGetDataFromIndex(winCombatFloaterConfigOptions.location, newSelection)
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LocationNode_Changed(windowId, controlId, newSelection, oldSelection)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal
	
	node.attachment = ComboBoxGetDataFromIndex(winCombatFloaterConfigOptions.locationNode, newSelection)
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LocationOffsetAngle_Changed(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal
	
	node.useLocation = true
	node.locationAngle = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LocationOffsetDistance_Changed(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)

	local node = data.normal
	
	node.useLocation = true
	node.locationDistance = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffectToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffectToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_ScaleToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.birthEffect.useScale = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_ScaleToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.birthEffect.useScale = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_FadeToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.birthEffect.useFade = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_FadeToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.birthEffect.useFade = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_TranslationToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.birthEffect.useTranslation = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_TranslationToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.birthEffect.useTranslation = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_DurationChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthDuration = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_ScaleStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useScale = true
	node.birthEffect.scaleBegin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_ScaleEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useScale = true
	node.birthEffect.scaleEnd = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_FadeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useFade = true
	node.birthEffect.alphaBegin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_FadeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useFade = true
	node.birthEffect.alphaEnd = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_VelocityDirectionStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.velocityDirectionMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_VelocityDirectionEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.velocityDirectionMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_VelocityMagnitudeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.velocityMagnitudeMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_VelocityMagnitudeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.velocityMagnitudeMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_AccelerationDirectionStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.accelDirectionMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_AccelerationDirectionEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.accelDirectionMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_AccelerationMagnitudeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.accelMagnitudeMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_BirthEffect_AccelerationMagnitudeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useBirthEffect = true
	node.birthEffect.useTranslation = true
	node.birthEffect.accelMagnitudeMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffectToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffectToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_ScaleToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.lifeEffect.useScale = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_ScaleToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.lifeEffect.useScale = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_FadeToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.lifeEffect.useFade = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_FadeToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.lifeEffect.useFade = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_TranslationToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.lifeEffect.useTranslation = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_TranslationToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.lifeEffect.useTranslation = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_DurationChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeDuration = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_ScaleStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useScale = true
	node.lifeEffect.scaleBegin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_ScaleEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useScale = true
	node.lifeEffect.scaleEnd = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_FadeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useFade = true
	node.lifeEffect.alphaBegin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_FadeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useFade = true
	node.lifeEffect.alphaEnd = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_VelocityDirectionStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.velocityDirectionMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_VelocityDirectionEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.velocityDirectionMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_VelocityMagnitudeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.velocityMagnitudeMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_VelocityMagnitudeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.velocityMagnitudeMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_AccelerationDirectionStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.accelDirectionMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_AccelerationDirectionEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.accelDirectionMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_AccelerationMagnitudeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.accelMagnitudeMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_LifeEffect_AccelerationMagnitudeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useLifeEffect = true
	node.lifeEffect.useTranslation = true
	node.lifeEffect.accelMagnitudeMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffectToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true	
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffectToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_ScaleToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.deathEffect.useScale = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_ScaleToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.deathEffect.useScale = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_FadeToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.deathEffect.useFade = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_FadeToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.deathEffect.useFade = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_TranslationToggle_OnCheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.deathEffect.useTranslation = true
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_TranslationToggle_OnUncheck(windowId, controlId)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.deathEffect.useTranslation = false
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_DurationChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathDuration = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_ScaleStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useScale = true
	node.deathEffect.scaleBegin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_ScaleEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useScale = true
	node.deathEffect.scaleEnd = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_FadeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useFade = true
	node.deathEffect.alphaBegin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_FadeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useFade = true
	node.deathEffect.alphaEnd = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_VelocityDirectionStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.velocityDirectionMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_VelocityDirectionEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.velocityDirectionMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_VelocityMagnitudeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.velocityMagnitudeMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_VelocityMagnitudeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.velocityMagnitudeMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_AccelerationDirectionStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.accelDirectionMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_AccelerationDirectionEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.accelDirectionMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_AccelerationMagnitudeStartChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.accelMagnitudeMin = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function CombatFloaterConfig_Options_DeathEffect_AccelerationMagnitudeEndChanged(windowId, controlId, newValue, oldValue)
	local selectedTreeNode = winCombatFloaterConfigTree:GetSelectedNode()
	local data = winCombatFloaterConfigTree:GetNodeData(selectedTreeNode)
	
	local node = data.normal

	node.useDeathEffect = true
	node.deathEffect.useTranslation = true
	node.deathEffect.accelMagnitudeMax = newValue
	
	CombatFloaters.SaveNode(data)
	CombatFloaterConfig_LoadNode(data)
end

---------------------------------------------------------------------------------------------------"249" y5="332" Stretchy="1" HotspotX="0" HotspotY="0" Duration="0.050" StartColor="fffff