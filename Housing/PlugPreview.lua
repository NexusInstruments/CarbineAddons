-----------------------------------------------------------------------------------------------
-- Client Lua Script for PlugPreview
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "HousingLib"
 
-----------------------------------------------------------------------------------------------
-- PlugPreview Module Definition
-----------------------------------------------------------------------------------------------
local PlugPreview = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PlugPreview:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	-- initialize our variables
	o.plugItem = nil
	o.numScreenshots = 0
	o.currScreen = 0
    return o
end

function PlugPreview:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- PlugPreview OnLoad
-----------------------------------------------------------------------------------------------
function PlugPreview:OnLoad()
    -- Register events
	Apollo.RegisterEventHandler("PlugPreviewOpen", "OnOpenPreviewPlug", self)
	Apollo.RegisterEventHandler("PlugPreviewClose", "OnClosePlugPreviewWindow", self)
    
    -- load our forms
    self.winPlugPreview = Apollo.LoadForm("PlugPreview.xml", "PlugPreviewWindow", nil, self)
    self.winScreen = self.winPlugPreview:FindChild("Screenshot01")
    self.btnPrevious = self.winPlugPreview:FindChild("PreviousButton")
    self.btnNext = self.winPlugPreview:FindChild("NextButton")
end


-----------------------------------------------------------------------------------------------
-- PlugPreview Functions
-----------------------------------------------------------------------------------------------

function PlugPreview:OnOpenPreviewPlug(plugItemId)
    self.winPlugPreview:Show(true)
    local itemList = HousingLib.GetPlugItem(plugItemId)
    local ix, item
    for ix = 1, #itemList do
        item = itemList[ix]
        if item["id"] == plugItemId then
          self.plugItem = item
        end
    end

    self:ShowPlugPreviewWindow()
    self.winPlugPreview:ToFront()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:ShowPlugPreviewWindow()
    -- don't do any of this if the Housing List isn't visible
	if self.winPlugPreview:IsVisible() then
		self.numScreenshots = #self.plugItem["screenshots"]
	    self.currScreen = 1

        if self.numScreenshots > 1 then
            self.btnPrevious:Enable(true)
            self.btnNext:Enable(true)
        else
            self.btnPrevious:Enable(false)
            self.btnNext:Enable(false)
        end
	    
	    self:DrawScreenshot()
		return
	end
	
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnWindowClosed()
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or 
	--  hitting ESC or
	--  C++ calling Event_ClosePlugPreviewWindow()
	
	Sound.Play(Sound.PlayUIWindowClose)
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnClosePlugPreviewWindow()
	-- close the window which will trigger OnWindowClosed
	self.winPlugPreview:Close()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnNextButton()
    self.currScreen = self.currScreen + 1
    if self.currScreen > self.numScreenshots then
        self.currScreen = 1
    end
    
    self:DrawScreenshot()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnPreviousButton()
    self.currScreen = self.currScreen - 1
    if self.currScreen < 1 then
        self.currScreen = self.numScreenshots
    end
    
    self:DrawScreenshot()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:DrawScreenshot()
    if self.numScreenshots > 0 and self.plugItem ~= nil then
        local spriteList = self.plugItem["screenshots"]
        local sprite = spriteList[self.currScreen].sprite
        self.winScreen:SetSprite("ClientSprites:"..sprite)
    else
        self.winScreen:SetSprite("")
    end
end

---------------------------------------------------------------------------------------------------
function PlugPreview:GetItem(id, itemlist)
  local ix, item
  for ix = 1, #itemlist do
    item = itemlist[ix]
    if item["id"] == id then
      return item
    end
  end
  return nil
end

-----------------------------------------------------------------------------------------------
-- PlugPreview Instance
-----------------------------------------------------------------------------------------------
local PlugPreviewInst = PlugPreview:new()
PlugPreviewInst:Init()
ndHazardList:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndMain:GetAnchorOffsets()
		self.tWndRefs.wndMain:SetAnchorOffsets(nRight - nWidth, nTop, nRight, nBottom)
	end
end

function Hazards:OnHazardUpdate(idHazard, eHazardType, fMeterValue, fMaxValue, strTooltip)
	if self.tHazardWnds[idHazard] then
		-- find the progress bar and update the limits
		local wndProgressBar = self.tHazardWnds[idHazard].wndHazardProgress
		wndProgressBar:SetMax(fMaxValue)

		if fMaxValue == fMeterValue then
			wndProgressBar:SetProgress(fMaxValue - .001, fMaxValue)
		else
			wndProgressBar:SetProgress(fMeterValue, fMaxValue)
		end

		--Cut down to integers only; we assume this is out of 100

		if eHazardType ~= HazardsLib.HazardType_Timer then -- standard percent
			local strPercent = (fMeterValue / fMaxValue) * 100
			self.tHazardWnds[idHazard].wndNumberText:SetText(string.format("%.0f", strPercent))
		else
			local strTime = string.format("%d:%02d", math.floor(fMeterValue / 60), math.floor(fMeterValue % 60))
			self.tHazardWnds[idHazard].wndNumberText:SetText(strTime)
		end

		if strTooltip ~= nil then
			wndProgressBar:SetTooltip(strTooltip)
		end
	end
end

function Hazards:OnBreathChanged(nBreath)
	local idHazard = knBreathFakeId
	local eHazardType = HazardsLib.HazardType_Breath
	local nBreathMax = 100
	
	if nBreath == nBreathMax then
		self:OnHazardRemove(idHazard)
		return
	end
	
	if self.tHazardWnds[idHazard] == nil then
		self:BuildHazardWindow(idHazard, eHazardType)
	
		local tSprites = karBarSprites[eHazardType] or karBarSprites["default"]
	
		self.tHazardWnds[idHazard].wndIcon:SetSprite(tSprites.strIcon)
		self.tHazardWnds[idHazard].wndHazardProgress:SetFillSprite(tSprites.strFillColor)
		self.tHazardWnds[idHazard].wndHazardProgress:SetGlowSprite(tSprites.strEdgeColor)
		self.tHazardWnds[idHazard].wndIcon:SetTooltip(Apollo.GetString("CRB_Breath_"))
		
		local nWidth = self.tWndRefs.wndHazardList:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndMain:GetAnchorOffsets()
		self.tWndRefs.wndMain:SetAnchorOffsets(nRight - nWidth, nTop, nRight, nBottom)
	end
	
	self:OnHazardUpdate(idHazard, eHazardType, nBreath, nBreathMax, nil)
end

function Hazards:OnBreath_FlashEvent()
	if self.tHazardWnds[knBreathFakeId] ~= nil then
		self.tHazardWnds[knBreathFakeId].wndHazardsProgressFlash:SetSprite("SprintMeter:sprHazards_Flash")
	end
end


local HazardInst = Hazards:new()
HazardInst:Init()lertPopout"):Show(bToggle, not bToggle)
		self.wndMain:FindChild("AlertItemKeybind"):SetSprite(bToggle and "sprAlert_Square_Blue" or "sprAlert_Square_Black")
	end
end

local HUDInteractInst = HUDInteract:new()
HUDInteractInst:Init()
ö”