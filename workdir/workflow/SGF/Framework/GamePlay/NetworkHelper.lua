local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local Network = GFScript("NetworkModule.Network")

local NetworkHelper = {}


function NetworkHelper:RegisterNetObj(netObj)
    if not netObj then
        Log:Error("netObj is nil")
        return
    end
    -- if not netObj.CheckSession then
    --     Log:Error("netObj.CheckSession is nil")
    --     return
    -- end

    if netObj.__registerNetObj then
        Log:Error("netObj has been registered")
        return
    end
    netObj.__registerNetObj = true

    netObj.serverNetEvents = {}
    netObj.clientNetEvents = {}
    netObj.requestNetEvents = {}
    netObj.responseNetEvents = {}
    if not netObj.CallServer then
        netObj.CallServer = function(self, msgid, body)
            Network:SendToServer(msgid, body)
        end
    end
    if not netObj.CallClient then
        netObj.CallClient = function(self, playerId, msgid, body)
            Network:SendToClient(playerId, msgid, body)
        end
    end
    if not netObj.Broadcast then
        netObj.Broadcast = function(self, msgid, body)
            Network:Broadcast(msgid, body)
        end
    end

    if not netObj.OnRequest then
        netObj.OnRequest = function(self, msgid, func)
            if not self.requestNetEvents then
                Log:Error("netObj.requestNetEvents is nil")
                return
            end
            if self.requestNetEvents[msgid] then
                Log:Error("msgid:"..msgid.." has been registered")
                return
            end
            local eventId = Network:ServerSetCallback(msgid, function(userId, msgid, data)
                if not netObj.__sleepNetCallback then
                    if netObj.CheckSession then
                        if netObj:CheckSession(userId) then
                            func(userId, msgid, data)
                        end
                    else
                        func(userId, msgid, data)
                    end
                end
            end)
            if eventId then
                table.insert(netObj.clientNetEvents, eventId)
            end

            self.requestNetEvents[msgid] = func
        end
    end
    if not netObj.OnResponse then
        netObj.OnResponse = function(self, msgid, func)
            if not self.responseNetEvents then
                Log:Error("netObj.responseNetEvents is nil")
                return
            end
            if self.responseNetEvents[msgid] then
                Log:Error("msgid:"..msgid.." has been registered")
                return
            end
            local eventId = Network:ClientSetCallback(msgid, function(msgid, data)
                if not netObj.__sleepNetCallback then
                    if netObj.CheckSession then
                        if (netObj.GetPlayerId and netObj:CheckSession(netObj:GetPlayerId())) or not netObj.GetPlayerId then
                            func(msgid, data)
                        end
                    else
                        func(msgid, data)
                    end
                end
            end)
            if eventId then
                table.insert(netObj.serverNetEvents, eventId)
            end
            self.responseNetEvents[msgid] = func
        end
    end
    if netObj.__sleepNetCallback == nil then
        netObj.__sleepNetCallback = false
    end
    if not netObj.SleepNetCallback then
        netObj.SleepNetCallback = function()
            netObj.__sleepNetCallback = true
        end
    end
    if not netObj.WakeNetCallback then
        netObj.WakeNetCallback = function()
            netObj.__sleepNetCallback = false
        end
    end
end

function NetworkHelper:UnregisterNetObj(netObj)
    if not netObj or not netObj.__registerNetObj then
        return
    end
    
    if netObj.clientNetEvents then
        for _, eventId in ipairs(netObj.clientNetEvents) do
            Network:RemoveServerCallback(eventId)
        end
    end
    if netObj.serverNetEvents then
        for _, eventId in ipairs(netObj.serverNetEvents) do
            Network:RemoveClientCallback(eventId)
        end
    end

    netObj.serverNetEvents = nil
    netObj.clientNetEvents = nil
    netObj.requestNetEvents = nil
    netObj.responseNetEvents = nil
    netObj.__registerNetObj = nil
end

return NetworkHelper    