-----------------------------------------------------------------------------------------------
-- Client Lua Script for $AddonName
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- $AddonName Module Definition
-----------------------------------------------------------------------------------------------
local $AddonName = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
--[optionList]
local kcrSelectedText = ApolloColor.new("UI_BtnTextHoloPressedFlyby")
local kcrNormalText = ApolloColor.new("UI_BtnTextHoloNormal")
--[/options]
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function $AddonName:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
--[optionList]
	o.tItems = {} -- keep track of all the list items
	o.wndSelectedListItem = nil -- keep track of which list item is currently selected
--[/option]

    return o
end

function $AddonName:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- $AddonName OnLoad
-----------------------------------------------------------------------------------------------
function $AddonName:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("$AddonName.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- $AddonName OnDocLoaded
-----------------------------------------------------------------------------------------------
function $AddonName:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "$AddonNameForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
--[optionList]
		-- item list
		self.wndItemList = self.wndMain:FindChild("ItemList")
--[/option]
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
--[optionSlashCommand]
		Apollo.RegisterSlashCommand("$SlashCommand", "On$AddonNameOn", self)
--[/option]

--[optionTimer][optionOneSec]
		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)
--[/option]
--[optionTimer][optionTenSec]
		self.timer = ApolloTimer.Create(10.0, true, "OnTimer", self)
--[/option]
--[optionTimer][optionCustom]
		self.timer = ApolloTimer.Create($TimerInterval, $TimerRepeat, "OnTimer", self)
--[/option]

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- $AddonName Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
--[optionSlashCommand][optionNoList]

-- on SlashCommand "/$SlashCommand"
function $AddonName:On$AddonNameOn()
	self.wndMain:Invoke() -- show the window
end
--[/option]
--[optionSlashCommand][optionList]

-- on SlashCommand "/$SlashCommand"
function $AddonName:On$AddonNameOn()
	self.wndMain:Invoke() -- show the window
	
	-- populate the item list
	self:PopulateItemList()
end
--[/option]
--[optionTimer]

-- on timer
function $AddonName:OnTimer()
	-- Do your timer-related stuff here.
end
--[/option]


-----------------------------------------------------------------------------------------------
-- $AddonNameForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function $AddonName:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function $AddonName:OnCancel()
	self.wndMain:Close() -- hide the window
end


--[optionList]
-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------
-- populate item list
function $AddonName:PopulateItemList()
	-- make sure the item list is empty to start with
	self:DestroyItemList()
	
    -- add 20 items
	for i = 1,20 do
        self:AddItem(i)
	end
	
	-- now all the item are added, call ArrangeChildrenVert to list out the list items vertically
	self.wndItemList:ArrangeChildrenVert()
end

-- clear the item list
function $AddonName:DestroyItemList()
	-- destroy all the wnd inside the list
	for idx,wnd in ipairs(self.tItems) do
		wnd:Destroy()
	end

	-- clear the list item array
	self.tItems = {}
	self.wndSelectedListItem = nil
end

-- add an item into the item list
function $AddonName:AddItem(i)
	-- load the window item for the list item
	local wnd = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndItemList, self)
	
	-- keep track of the window item created
	self.tItems[i] = wnd

	-- give it a piece of data to refer to 
	local wndItemText = wnd:FindChild("Text")
	if wndItemText then -- make sure the text wnd exist
		wndItemText:SetText("item " .. i) -- set the item wnd's text to "item i"
		wndItemText:SetTextColor(kcrNormalText)
	end
	wnd:SetData(i)
end

-- when a list item is selected
function $AddonName:OnListItemSelected(wndHandler, wndControl)
    -- make sure the wndControl is valid
    if wndHandler ~= wndControl then
        return
    end
    
    -- change the old item's text color back to normal color
    local wndItemText
    if self.wndSelectedListItem ~= nil then
        wndItemText = self.wndSelectedListItem:FindChild("Text")
        wndItemText:SetTextColor(kcrNormalText)
    end
    
	-- wndControl is the item selected - change its color to selected
	self.wndSelectedListItem = wndControl
	wndItemText = self.wndSelectedListItem:FindChild("Text")
    wndItemText:SetTextColor(kcrSelectedText)
    
	Print( "item " ..  self.wndSelectedListItem:GetData() .. " is selected.")
end


--[/option]
-----------------------------------------------------------------------------------------------
-- $AddonName Instance
-----------------------------------------------------------------------------------------------
local $AddonNameInst = $AddonName:new()
$AddonNameInst:Init()
on:SetTooltip(Apollo.GetString("CRB_Breath_"))
		
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