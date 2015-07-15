-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingDatachron
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "HousingLib"
 
-----------------------------------------------------------------------------------------------
-- HousingDatachron Module Definition
-----------------------------------------------------------------------------------------------
local HousingDatachron = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrTitleEnabled = CColor.new(49/255, 252/255, 246/255, 1)
local kcrTitleDisabled = CColor.new(128/255, 64/255, 64/255, 1)
local kcrBodyEnabled = CColor.new(47/255, 148/255, 172/255, 1)
local kcrBodyDisabled = CColor.new(128/255, 0/255, 0/255, 1)

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function HousingDatachron:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	-- initialize our variables

    return o
end

function HousingDatachron:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- HousingDatachron OnLoad
-----------------------------------------------------------------------------------------------
function HousingDatachron:OnLoad()
	Apollo.RegisterEventHandler("Datachron_LoadHousingContent", 	"OnLoadFromDatachron", self)
end

function HousingDatachron:OnLoadFromDatachron()
	Apollo.RegisterEventHandler("HousingPanelControlOpen", 			"OnEnteredProperty", self)
	Apollo.RegisterEventHandler("HousingPanelControlClose", 		"OnLeftProperty", self)
	Apollo.RegisterEventHandler("HousingBuildComplete", 			"OnHousingBuildComplete", self)
	Apollo.RegisterEventHandler("HousingBuildStarted", 				"OnHousingBuildStarted", self)
	Apollo.RegisterEventHandler("HousingEnterEditMode", 			"OnEnterEditMode", self)

	Apollo.RegisterTimerHandler("DelayedHousingRestoreDatachron", 	"DelayedHousingRestoreDatachron", self)
	
	self.wndMain = Apollo.LoadForm("HousingDatachron.xml", "HousingDatachronWindow", g_wndDatachron:FindChild("HousingContainer"), self)
	self.wndHousingMode = self.wndMain:FindChild("HousingMenu")
	
	HousingLib.RefreshUI()
end

---------------------------------------------------------------------------------------------------
-- Housing Datachron Mode
---------------------------------------------------------------------------------------------------

function HousingDatachron:DelayedHousingRestoreDatachron()
	if not self.bRestoreDatachronAlready then
		self.bRestoreDatachronAlready = true
		Event_FireGenericEvent("GenericEvent_RestoreDatachron")
	end
end

function HousingDatachron:OnEnteredProperty(idPropertyInfo, idZone, bPlayerIsInside) -- TODO: Make sure housing mode is visible on-property
	if not HousingLib.IsHousingWorld() then
		self:OnLeftProperty()
		return
	end

	if not self.bAlreadyOnProperty then
		self.bAlreadyOnProperty = true
		self.wndHousingMode:FindChild("BtnHousingEdit"):SetCheck(false)
		HousingLib.SetEditMode(false)
		Sound.Play(Sound.PlayUI37OpenRemoteWindowDigital)
	end
	
	self.bIsWarplot = HousingLib.IsWarplotResidence()
	local bIsOwner = HousingLib.IsOnMyResidence()
	
	Apollo.CreateTimer("DelayedHousingRestoreDatachron", 1, false)

	-- Enable different buttons based on whether we're inside or outside
    self.wndHousingMode:FindChild("BtnHousingIntRemodel"):Show(bPlayerIsInside)
    self.wndHousingMode:FindChild("BtnHousingIntDecorate"):Show(bPlayerIsInside)
    self.wndHousingMode:FindChild("BtnHousingIntVendor"):Show(bPlayerIsInside)
    self.wndHousingMode:FindChild("BtnHousingIntList"):Show(bPlayerIsInside)

    self.wndHousingMode:FindChild("BtnHousingRemodel"):Show(not bPlayerIsInside and not self.bIsWarplot)
    self.wndHousingMode:FindChild("BtnHousingDecorate"):Show(not bPlayerIsInside)
    self.wndHousingMode:FindChild("BtnHousingVendor"):Show(not bPlayerIsInside)
    self.wndHousingMode:FindChild("BtnHousingLandscape"):Show(not bPlayerIsInside)
    self.wndHousingMode:FindChild("BtnHousingList"):Show(not bPlayerIsInside)

	self.wndHousingMode:FindChild("RecallActionBtn"):SetContentId(20)

	local tContentInfo = self.wndHousingMode:FindChild("RecallActionBtn"):GetContent()

	self.wndHousingMode:FindChild("HousingEscapeWnd"):Show(bPlayerIsInside and tContentInfo.spell ~= nil)
	self.wndHousingMode:FindChild("HousingEscapeExtWnd"):Show(not bPlayerIsInside and tContentInfo.spell ~= nil)

	local wndRemodel = self.wndHousingMode:FindChild("BtnHousingRemodel")
	local wndLandscape = self.wndHousingMode:FindChild("BtnHousingLandscape")
	
	if not self.bIsWarplot and not bIsOwner then
		-- Roomates can only modify interior & exterior decor, disable the remodel and landscape buttons
		wndRemodel:Enable(false)
		wndRemodel:FindChild("MainLabel"):SetTextColor(kcrTitleDisabled)
		wndRemodel:FindChild("SubLabel"):SetTextColor(kcrBodyDisabled)
		wndRemodel:FindChild("IconBack"):Show(false)
		wndRemodel:FindChild("Icon"):SetBGColor(kcrTitleDisabled)

		wndLandscape:Enable(false)
		wndLandscape:FindChild("MainLabel"):SetTextColor(kcrTitleDisabled)
		wndLandscape:FindChild("SubLabel"):SetTextColor(kcrBodyDisabled)
		wndLandscape:FindChild("IconBack"):Show(false)
		wndLandscape:FindChild("Icon"):SetBGColor(kcrTitleDisabled)
    elseif HousingLib.GetPlotCount() ~= 0 then

        local tPlot = HousingLib.GetPlot(1)
        local tBakedDecorList = HousingLib.GetBakedDecorDetails()
        local bHasBakedDecor = #tBakedDecorList > 0

		if not tPlot["isBuilding"] and bHasBakedDecor == true then
			wndRemodel:Enable(true)
			wndRemodel:FindChild("MainLabel"):SetTextColor(kcrTitleEnabled)
			wndRemodel:FindChild("SubLabel"):SetTextColor(kcrBodyEnabled)
			wndRemodel:FindChild("IconBack"):Show(true)
			wndRemodel:FindChild("Icon"):SetBGColor(CColor.new(128/255, 1, 1, 1))
        else
			wndRemodel:Enable(false)
			wndRemodel:FindChild("MainLabel"):SetTextColor(kcrTitleDisabled)
			wndRemodel:FindChild("SubLabel"):SetTextColor(kcrBodyDisabled)
			wndRemodel:FindChild("IconBack"):Show(false)
			wndRemodel:FindChild("Icon"):SetBGColor(kcrTitleDisabled)
		end

		self.wndHousingMode:FindChild("BtnHousingDecorate"):Enable(true)
        self.wndHousingMode:FindChild("BtnHousingVendor"):Enable(true)
        self.wndHousingMode:FindChild("BtnHousingList"):Enable(true)

		wndLandscape:Enable(true)
		wndLandscape:FindChild("MainLabel"):SetTextColor(kcrTitleEnabled)
		wndLandscape:FindChild("SubLabel"):SetTextColor(kcrBodyEnabled)
		wndLandscape:FindChild("IconBack"):Show(true)
		wndLandscape:FindChild("Icon"):SetBGColor(CColor.new(128/255, 1, 1, 1))
    end
end


--function HousingDatachron:OnGenerateTooltip(wndControl, wndHandler, tType, arg1, arg2)
--	Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
--end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnLeftProperty() --TODO:Make this automatic; should be, just can't test
	self.bAlreadyOnProperty = false
	self.wndHousingMode:FindChild("BtnHousingEdit"):SetCheck(false)
	
	--TODO should this be in datachron main?
end

function HousingDatachron:OnHousingBuildStarted(nPlot)
    if HousingLib.GetPlotCount() == 0 or nPlot ~= 1 then
        return
    end

	local wndRemodel = self.wndHousingMode:FindChild("BtnHousingRemodel")

    wndRemodel:Enable(false)
	wndRemodel:FindChild("MainLabel"):SetTextColor(kcrTitleDisabled)
	wndRemodel:FindChild("SubLabel"):SetTextColor(kcrBodyDisabled)
	wndRemodel:FindChild("IconBack"):Show(false)
	wndRemodel:FindChild("Icon"):SetBGColor(kcrTitleDisabled)
end

function HousingDatachron:OnHousingBuildComplete(nPlot)
    if HousingLib.GetPlotCount() == 0 or nPlot ~= 1 then
        return
    end

	local bIsOwner = HousingLib.IsOnMyResidence()
    local tBakedDecorList = HousingLib.GetBakedDecorDetails();
    local bHasBakedDecor = #tBakedDecorList > 0
	local wndRemodel = self.wndHousingMode:FindChild("BtnHousingRemodel")
	wndRemodel:Enable(false)

	if bIsOwner and bHasBakedDecor then
		wndRemodel:Enable(true)
		wndRemodel:FindChild("MainLabel"):SetTextColor(kcrTitleEnabled)
		wndRemodel:FindChild("SubLabel"):SetTextColor(kcrBodyEnabled)
		wndRemodel:FindChild("IconBack"):Show(true)
		wndRemodel:FindChild("Icon"):SetBGColor(CColor.new(128/255, 1, 1, 1))
	end
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingCustomize()
	Event_FireGenericEvent("DatachronRemodelBtn")
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnEnterEditMode()
    self.wndHousingMode:FindChild("BtnHousingEdit"):SetCheck(true)
    HousingLib.SetEditMode(true)
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingEditChecked()
    HousingLib.SetEditMode(true)
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingEditUnchecked()
    HousingLib.SetEditMode(false)
	Event_FireGenericEvent("HousingExitEditMode")
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingOptions()
	Event_FireGenericEvent("DatachronOptionsBtn")
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingLandscape()
	Event_FireGenericEvent("DatachronLandscapeBtn")
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingRemodel()
	Event_FireGenericEvent("DatachronRemodel2Btn")
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingDecorate()
	Event_FireGenericEvent("DatachronDecorateBtn", false)
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingVendor()
	Event_FireGenericEvent("DatachronDecorateBtn", true)
end

---------------------------------------------------------------------------------------------------
function HousingDatachron:OnHousingList()
	Event_FireGenericEvent("DatachronHousingListBtn")
end

-----------------------------------------------------------------------------------------------
-- HousingDatachron Instance
-----------------------------------------------------------------------------------------------
local HousingDatachronInst = HousingDatachron:new()
HousingDatachronInst:Init()
ïÔüœœ÷—„ıﬁ®Ω!mè(›ﬂ◊∫Xsõ[oúò®≠Ω€«É¡‡œ£/©èı|è˚Ö‘?û‘¶èí•ÙvÈ9Ì∆¶FØèœi‘ÛÇz›y-œœ“ÀcQQ¥d¸†‰»;Æ}Ï∏ﬁ"®ó»xΩuÂ9˙ˇ˝ﬁƒΩ~0êˆ~—òH/è^ëàÛ˝s⁄»~'~ø÷]ÊG/&ÓÔCæÉ¡`-±†ûoP-˜g∂%ÍS…x||·9≠«”∞!ïèk…¸ T~ûÊ58~Øx<¥;)ﬂËıÁ¥«µ»Áã‚|?s4Ã‘êÌÅ|É¡‡€ˇπûG∏ÁıÄÒpX<Gñ–G•«µõÈ¯¨·…àÇ≤Cıœ˚$Ò—Î◊‰eìœ√˘æSP72E´ﬁ«€Û—B»˜¡`0æSÌÅZ‚g€ÍŒi[∫®zÄvéﬂ#˚∏"æZ„|?#Ïc*∫ÎŒ-úòòÆU°ïΩâÒ{vkRìÃ°„É¡`—Ç˙ò?ü;ŒøµR= ïüêz@”≠äˇ$ﬂOÃ«[øÀJÜËØ{[ª'¸w{ˇ¡`0ìˆ €ä¯ôn˜€[®˘Üèk¥|‡–eØKsP±~4⁄ÖÛ}‰CŸeáÍékIæø ïÔÛêÔÉ¡`0<G,®ª˝FŒˇ$…œß∆Â˘Üﬂ.–“ÛêxÚ
Sœæ˝¿¿Læ˛â•Û∞tøÚ}0ÉÁ§ÔG…˘Üª5.$›Øw!µ_u∑ZZ∫v»Ò~èñÁŸèì¸?*d"¸›“c%o/å◊>¨JÊ˚oÊBæÉ¡`Á√Çzπ?≥ªÁŒ˝ˆ¬„„£…xˇ“{ı …ûHôOÿ≤âå–÷Æ»Å˘x¡`0˛˙œôd=`%v!$|	í˘Ü[˛“¬ÜñÊWÃdÌÃ¬3’/-åLˇà]y1±~õÜ•˛π≤?`0Éoﬁ…˘Ü[•Œ›˚∑Gü‘à≠idäñ∫ﬂZÏ¥ÂhÔˆˆÅ¡`0æı>úöo¯o≥|.Ñ^õGÊ#˛*F%'¸se{¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`0É¡`