-----------------------------------------------------------------------------------------------
-- Client Lua Script for Credits
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Credits Module Definition
-----------------------------------------------------------------------------------------------
local Credits = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local kScrollPixelsPerSec = 100
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Credits:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Credits:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureButton, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Credits OnLoad
-----------------------------------------------------------------------------------------------
function Credits:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Credits.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Credits OnDocLoaded
-----------------------------------------------------------------------------------------------
function Credits:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "CreditsHolder", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.wndCredits = self.wndMain:FindChild("CreditsForm")
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterEventHandler("ShowCredits", "OnCreditsOn", self)

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- Credits Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/credits"
function Credits:OnCreditsOn()
	self.wndMain:Show(true) -- show the window
	self.wndCredits:DestroyChildren()
	
	self.tCredits = PreGameLib.GetCredits()
	if self.tCredits == nil then
		self.wndMain:Show(false, true)
	else
		self.nGroup = 1
		self.nPerson = 0
		self.tWindows = {}
		self:NextCredit()
	end
	
end

function Credits:NextCredit()
	local tMainClient = self.wndMain:GetClientRect()

	local tIdsToDestroy = {}
	for id,wnd in pairs(self.tWindows) do
		local loc = wnd:GetTransLocation()
		if loc:ToTable().nOffsets[4] < 0 then
			wnd:Destroy()
			tIdsToDestroy[id] = id
		end
	end
	for id,idx in pairs(tIdsToDestroy) do
		self.tWindows[id] = nil
	end
	
	local tGroup = self.tCredits[self.nGroup]
	if tGroup == nil then
		local fWait = tMainClient.nHeight / kScrollPixelsPerSec
		self.timer = ApolloTimer.Create(fWait, false, "CloseCredits", self)
		return
	end
	

		
	if self.nPerson == 0 then
		-- load up a group header
		local wnd = Apollo.LoadForm(self.xmlDoc, "CreditsHolder:CreditsForm:GroupHeader", self.wndCredits, self)
		wnd:SetText(tGroup.strGroupName)
		local tGroupClient = wnd:GetClientRect()
		
		local tLocBegin = {fPoints={0,0,1,0}, nOffsets={0, tMainClient.nHeight, 0, tMainClient.nHeight + tGroupClient.nHeight}}
		local tLocEnd = {fPoints={0,0,1,0}, nOffsets={0, -500, 0, -500 + tGroupClient.nHeight}}

		local locBegin = WindowLocation.new(tLocBegin)
		local locEnd = WindowLocation.new(tLocEnd)
		
		wnd:MoveToLocation(locBegin)
		wnd:TransitionMove(locEnd, tMainClient.nHeight / kScrollPixelsPerSec)
		
		local fWait = tGroupClient.nHeight / kScrollPixelsPerSec
		
		self.timer = ApolloTimer.Create(fWait, false, "NextCredit", self)
		self.nPerson = 1
		self.tWindows[wnd:GetId()] = wnd
		return
	end
	
	local tCredit = tGroup.arCredits[self.nPerson]
	if tCredit == nil then
		self.nPerson = 0
		self.nGroup = self.nGroup + 1
		self:NextCredit()
		return
	else
		if tCredit.strImage ~= "" then
			local wnd = Apollo.LoadForm(self.xmlDoc, "CreditsHolder:CreditsForm:ImageHolder", self.wndCredits, self)
			
			if tCredit.strImage == "CarbineLogo" then
				wnd:FindChild("ImageCarbineLogo"):Show(true)
			elseif tCredit.strImage == "NCSoftLogo" then
				wnd:FindChild("ImageNCSoftLogo"):Show(true)
			else
				local wndImg = wnd:FindChild("Image")
				wndImg:SetSprite(tCredit.strImage)
			end
	
			local tImageClient = wnd:GetClientRect()
			
			local tLocBegin = {fPoints={0,0,1,0}, nOffsets={0, tMainClient.nHeight, 0, tMainClient.nHeight + tImageClient .nHeight}}
			local tLocEnd = {fPoints={0,0,1,0}, nOffsets={0, -500, 0, -500 + tImageClient.nHeight}}
	
			local locBegin = WindowLocation.new(tLocBegin)
			local locEnd = WindowLocation.new(tLocEnd)
			
			wnd:MoveToLocation(locBegin)
			wnd:TransitionMove(locEnd, tMainClient.nHeight / kScrollPixelsPerSec)
			
			local fWait = tImageClient .nHeight / kScrollPixelsPerSec
			
			self.timer = ApolloTimer.Create(fWait, false, "NextCredit", self)
			self.nPerson = self.nPerson + 1
			self.tWindows[wnd:GetId()] = wnd
			return
		else
			local wnd = Apollo.LoadForm(self.xmlDoc, "CreditsHolder:CreditsForm:Person", self.wndCredits, self)
			local wndName = wnd:FindChild("Name")
			wndName:SetText(tCredit.strPersonName)
			local nMaxHeight = wndName:GetLocation():ToTable().nOffsets[4]
			for idx,strTitle in ipairs(tCredit.arTitles) do
				local wndTitle = wnd:FindChild("Title"..tostring(idx))
				if wndTitle ~= nil and (idx <= 1 or string.len(strTitle) > 0) then
					wndTitle:SetText(strTitle)
					nMaxHeight = wndTitle:GetLocation():ToTable().nOffsets[4]
				end
			end
			
			nMaxHeight = nMaxHeight + 2
			local tLocBegin = {fPoints={0,0,1,0}, nOffsets={0, tMainClient.nHeight, 0, tMainClient.nHeight + nMaxHeight}}
			local tLocEnd = {fPoints={0,0,1,0}, nOffsets={0, -500, 0, -500 + nMaxHeight}}
	
			local locBegin = WindowLocation.new(tLocBegin)
			local locEnd = WindowLocation.new(tLocEnd)
			
			wnd:MoveToLocation(locBegin)
			wnd:TransitionMove(locEnd, tMainClient.nHeight / kScrollPixelsPerSec)
			
			local fWait = nMaxHeight / kScrollPixelsPerSec
			
			self.timer = ApolloTimer.Create(fWait, false, "NextCredit", self)
			self.nPerson = self.nPerson + 1
			self.tWindows[wnd:GetId()] = wnd
			return
		end
	end
end

function Credits:CloseCredits()
	self.wndMain:DestroyChildren()
	self.wndMain:Show(false)
end

-----------------------------------------------------------------------------------------------
-- CreditsForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Credits:OnOK()
	self.wndMain:Show(false) -- hide the window
end

-- when the Cancel button is clicked
function Credits:OnCancel()
	self.wndMain:Show(false) -- hide the window
end


-----------------------------------------------------------------------------------------------
-- Credits Instance
-----------------------------------------------------------------------------------------------
local CreditsInst = Credits:new()
CreditsInst:Init()
lient="1" Font="CRB_Interface12_B" Text="" Template="Default" TooltipType="OnCursor" Name="BottomText" BGColor="ffffffff" TextColor="UI_TextHoloTitle" TooltipColor="" TextId="Challenges_NoProgress" UseParentOpacity="1" IgnoreMouse="1" DT_CENTER="1" AutoScaleTextOff="1"/>
    </Form>
</Forms>
t ~= nil and strText ~= "" and strTextSubject ~= nil and strTextSubject ~= ""
	self.tWindowMap["OkBtn"]:Enable(bEnable)
	if bEnable then
		self.tWindowMap["OkBtn"]:SetActionData(GameLib.CodeEnumConfirmButtonType.SubmitSupportTicket, nCategory, nSubCategory, strTextSubject, strText)
	end

	if self.bIsBug ~= not self.tWindowMap["OkBtn"]:IsShown() then
		self.tWindowMap["OkBtn"]:Show(not self.bIsBug)
	end

	if self.bIsBug ~= self.tWindowMap["ConvertToBugBtn"]:IsShown() then
		self.tWindowMap["ConvertToBugBtn"]:Show(self.bIsBug)
	end
end

---------------------------------------------------------------------------------------------------
function PlayerTicketDialog:OnSupportTicketSubmitted(wndHandler, wndControl, eMouseButton)
	if self.bAddIgnore and self.strTarget then
		FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Ignore, self.strTarget) 
		Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("Social_AddedToIgnore"), self.strTarget))
		self.bAddIgnore = nil
		self.strTarget = nil
	end
	
	self:UpdateSubmitButton()
	self:ClearTextEntries()
	self.tWindowMap["Main"]:Close()
end

---------------------------------------------------------------------------------------------------
function PlayerTicketDialog:ClearTextEntries()
	self.tWindowMap["PlayerTicketTextEntry"]:SetText("")
	self.tWindowMap["PlayerTicketTextEntrySubject"]:SetText("")
end

---------------------------------------------------------------------------------------------------
function PlayerTicketDialog:OnConvertToBugBtn(wndHandler, wndControl, eMouseButton)
	if self.bIsBug then
		local strText = self.tWindowMap["PlayerTicketTextEntry"]:GetText()
		local strText = self.tWindowMap["PlayerTicketTextEntrySubject"]:GetText()
		Event_FireGenericEvent("TicketToBugDialog", strText, strTextSubject)
		self.bIsBug = false
	end

	self:UpdateSubmitButton()
	self:ClearTextEntries()
	self.tWindowMap["Main"]:Close()
end

---------------------------------------------------------------------------------------------------
function PlayerTicketDialog:OnCancelBtn(wndHandler, wndControl, eMouseButton)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self:ClearTextEntries()
	self.tWindowMap["Main"]:Show(false)
end

---------------------------------------------------------------------------------------------------
function PlayerTicketDialog:OnTextChanged()
	self:UpdateSubmitButton()
end

---------------------------------------------------------------------------------------------------
-- PlayerTicketDialog instance
---------------------------------------------------------------------------------------------------
local PlayerTicketDialogInst = PlayerTicketDialog:new()
PlayerTicketDialogInst:Init()
"38¾  ¾òû XpKX˜416" Stretchy="1" HotspotX="0" HotspotY="0" Duration="1.000" StartColor="ffffffff" EndColor="ffffffff"/>
    </Sprite>
    <Sprite Name="spr_BreakoutStun_ClockOrange" Cycle="1">
        <Frame Texture="UI\Assets\Textures\UI_CRB_HUD_Breakout.tga" x0="282" x1="282" x2="282" x3="282" x4="282" x5="315" y0="383" y1="383" y2="383" y3="383" y4="383" y5="416" Stretchy="1" HotspotX="0" HotspotY="0" Duration="1.000" StartColor="ffffffff" EndColor="ffffffff"/>
    </Sprite>
    <AutoButton Name="btn_BreakoutStun_Right" Texture="UI\Assets\Textures\UI_CRB_HUD_Breakout.tga" x0="247" x1="247" x2="247" x3="247" x4="247" x5="292" y0="247" y1="247" y2="247" y3="247" y4="247" y5="292" Stretchy="1" StateBits="19" Direction="Down"/>
    <AutoButton Name="btn_BreakoutStun_Left" Texture="UI\Assets\Textures\UI_CRB_HUD_Breakout.tga" x0="292" x1="292" x2="292" x3="292" x4