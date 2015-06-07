require "Window"
require "Unit"


---------------------------------------------------------------------------------------------------
-- CRB_Cinematics module definition

local CRB_Cinematics = {}

---------------------------------------------------------------------------------------------------
-- local constants
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- CRB_Cinematics initialization
---------------------------------------------------------------------------------------------------
function CRB_Cinematics:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	-- initialize our variables

	-- return our object
	return o
end

---------------------------------------------------------------------------------------------------
function CRB_Cinematics:Init()

	Apollo.RegisterAddon(self)
end

---------------------------------------------------------------------------------------------------
-- CRB_Cinematics EventHandlers
---------------------------------------------------------------------------------------------------


function CRB_Cinematics:OnLoad()
	Apollo.RegisterEventHandler("CinematicsNotify", "OnCinematicsNotify", self)
	Apollo.RegisterEventHandler("CinematicsCancel", "OnCinematicsCancel", self)
	-- load our forms
	self.wndCin = Apollo.LoadForm("CRB_Cinematics.xml", "CinematicsWindow", nil, self)
	self.wndCin:Show(false)
end
	
---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

function CRB_Cinematics:OnCinematicsNotify(msg, param)
	-- save the parameter and show the window
	self.wndCin:FindChild("Message"):SetText(msg)
	self.wndCin:Show(true)
	self.param = param
end

function CRB_Cinematics:OnCinematicsCancel(param)
	-- save the parameter and show the window
	if param == self.param then
		self.wndCin:Show(false)
	end
end

function CRB_Cinematics:OnPlay()
	-- call back to the game with 
	Cinematics_Play(self.param)
	self.wndCin:Show(false)
end

function CRB_Cinematics:OnCancel()
	-- call back to the game with
	Cinematics_Cancel(self.param)
	self.wndCin:Show(false)
end

---------------------------------------------------------------------------------------------------
-- CRB_Cinematics instance
---------------------------------------------------------------------------------------------------
local CRB_CinematicsInst = CRB_Cinematics:new()
CRB_Cinematics:Init()



