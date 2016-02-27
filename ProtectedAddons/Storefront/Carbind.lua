-----------------------------------------------------------------------------------------------
-- Client Lua Script for Carbind.lua
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

-- Prototype promises
Promise = {}
Promise.__index = Promise

local PromisePending = 1
local PromiseFulfilled = 2
local PromiseRejected = 3

function Promise.New()
    return setmetatable({
        eState = PromisePending,
        arFulfilledCallbacks = {},
        arRejectedCallbacks = {},
        tValue = nil
    }, Promise)
end
function Promise.Is(promise)
    return getmetatable(promise) == Promise
end

function Promise:IsFulfilled()
    return self.eState == PromiseFulfilled
end

function Promise:IsRejected()
    return self.eState == PromiseRejected
end

function Promise:IsPending()
    return self.eState == PromisePending
end


function Promise:Resolve(...)
    if self.eState == PromisePending then
        self.tValue = {...}
        self.eState = PromiseFulfilled

        for idx, fnCallback in pairs(self.arFulfilledCallbacks) do
            self.tValue = {fnCallback(unpack(self.tValue))}
        end

        self.arFulfilledCallbacks = {}
        self.arRejectedCallbacks = {}
    end
end
function Promise:Reject(...)
    if self.eState == PromisePending then
        self.tValue = {...}
        self.eState = PromiseRejected

        for idx, fnCallback in pairs(self.arRejectedCallbacks) do
            self.tValue = {fnCallback(unpack(self.tValue))}
        end

        self.arFulfilledCallbacks = {}
        self.arRejectedCallbacks = {}
    end
end
function Promise:Then(fnFulfilled, fnRejected)
    if fnFulfilled ~= nil then
        if self.eState == PromiseFulfilled then
            if self.tValue ~= nil then
                fnFulfilled(unpack(self.tValue))
            else
                fnFulfilled(nil)
            end
        elseif self.eState == PromisePending then
            table.insert(self.arFulfilledCallbacks, fnFulfilled)
        end
    end
    self:Catch(fnRejected)

    return self
end
function Promise:Catch(fnRejected)
    if fnRejected ~= nil then
        if self.eState == PromiseRejected then
            if self.tValue ~= nil then
                fnRejected(unpack(self.tValue))
            else
                fnRejected(nil)
            end
        elseif self.eState == PromisePending then
            table.insert(self.arRejectedCallbacks, fnRejected)
        end
    end

    return self
end

--[[
function CreateTimerProvider(this)
	return function(nDelaySeconds, fnCallback)
		local strCallbackName = "ApollTimer|" .. tostring(fnCallback)
        
		local timer = ApolloTimer.Create(nDelaySeconds, false, strCallbackName, this)
        timer:Stop()
        
        this[strCallbackName] = function(self, nTime)
            fnCallback(nTime)
            timer = nil
            this[strCallbackName] = nil
        end
		
		return timer
	end
end
function Promise:Delay(nDelaySeconds)
    local newPromise = Promise.New()
    local arguments

    local timer = TimerProvider(nDelaySeconds, function(nTime)
        newPromise:Resolve(unpack(arguments))
    end)
    self:Then(function(...)
        arguments = {...}
        timer:Start()
    end)

    return newPromise
end
]]--

local function WhenHelper(self, fnHelper, arguments)
    local deferredPromise = Promise.New()

    if self ~= nil then
        self:Then(function()
            fnHelper(deferredPromise, arguments)
        end)
    else
        fnHelper(deferredPromise, arguments)
    end

    return deferredPromise
end

local function WhenAllHelper(deferredPromise, arArgs)
    local nTotal = #arArgs
    local nCompleted = 0
    local nRejected = 0
    local tReturnValues = {}

    local fnCheckComplete = function()
        if nCompleted == nTotal then
            if nRejected == 0 then
                deferredPromise:Resolve(unpack(tReturnValues))
            else
                deferredPromise:Reject(unpack(tReturnValues))
            end
        end
    end

    for idx, oArg in pairs(arArgs) do
        if type(oArg) == "table" and getmetatable(oArg) == Promise then
            local fnCallback = function(...)
                nCompleted = nCompleted + 1
                if oArg.eState == PromiseRejected then
                    nRejected = nRejected + 1
                end
                tReturnValues[idx] = {...}
                fnCheckComplete()
            end

            oArg:Then(fnCallback, fnCallback)
        else
            tReturnValues[idx] = {oArg}
            nCompleted = nCompleted + 1
        end
    end

    fnCheckComplete()
end

function Promise:WhenAll(...)
    return WhenHelper(self, WhenAllHelper, {...})
end

local function WhenAnyHelper(deferredPromise, arArgs)
    local nTotal = #arArgs
    local nRejected = 0
    local bCompleted = false
    local tReturnValues = {}

    local fnCheckComplete = function()
        if nRejected == nTotal then
            if not bCompleted then
                bCompleted = true
                deferredPromise:Reject(unpack(tReturnValues))
            end
        end
    end

    for idx, oArg in pairs(arArgs) do
        if Promise.Is(oArg) then
            oArg:Then(function(...)
                if not bCompleted then
                    bCompleted = true
                    deferredPromise:Resolve(...)
                end
            end, function(...)
                nRejected = nRejected + 1
                tReturnValues[idx] = {...}
                fnCheckComplete()
            end)
        else
            tReturnValues[idx] = {oArg}
        end
    end

    fnCheckComplete()
end

function Promise:WhenAny(...)
    return WhenHelper(self, WhenAnyHelper, {...})
end



function AddGameEventCallback(strEventName, tSelf, fnCallback)
	if tSelf[strEventName] == nil then
		local tMetatable = { }
		tMetatable.__call = function(tTable, tCallSelf, ...)
			for idx, fnCallback in pairs(tTable) do
				fnCallback(...)
			end
		end
		tSelf[strEventName] = setmetatable({ }, tMetatable)
		Apollo.RegisterEventHandler(strEventName, strEventName, tSelf)
	end
	
	tSelf[strEventName][fnCallback] = fnCallback
end

function RemoveGameEventCallback(strEventName, tSelf, fnCallback)
	if tSelf[strEventName] ~= nil then
		tSelf[strEventName][fnCallback] = nil
	end
end

function AddControlEventCallback(strEventName, tSelf, wnd, fnCallback)
	local strCallbackName = strEventName.." "..wnd:GetId()
	if tSelf[strCallbackName] == nil then
		local tMetatable =
		{
			__call = function(tTable, tCallSelf, ...)
				for idx, fnCallback in pairs(tTable) do
					fnCallback(...)
				end
			end
		}
		tSelf[strCallbackName] = setmetatable({ }, tMetatable)
		wnd:AddEventHandler(strEventName, strCallbackName)
	end
	
	tSelf[strCallbackName][fnCallback] = fnCallback
end

function RemoveControEventCallback(strEventName, tSelf, wnd, fnCallback)
	local strCallbackName = strEventName.." "..wnd:GetId()
	if tSelf[strCallbackName] ~= nil then
		tSelf[strCallbackName][fnCallback] = nil
	end
end


function PromiseFromGameEvent(strEventName, self, nCallCount)
    if nCallCount == nil then
        nCallCount = 1
    end

    local this = self
	local promise = Promise:New()
    local nCalls = 0
	
	local fnCallback = function(...)
        nCalls = nCalls + 1
        
        if nCalls >= nCallCount then
            promise:Resolve(...)
        end
	end
    local fnCleanup = function(...)
		RemoveGameEventCallback(strEventName, this, fnCallback)
        return ...
	end
	
	AddGameEventCallback(strEventName, this, fnCallback)
	
	return promise:Then(fnCleanup, fnCleanup)
end