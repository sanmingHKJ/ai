local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Network = GFScript("NetworkModule.Network")
local NetworkPacker = GFScript("NetworkModule.NetworkPacker")
local NetProto = GFScript("NetworkModule.NetProto")
local Profiler = GFScript("CoreModule.Profiler")
local NetworkDefines = GFScript("NetworkModule.NetworkDefines")

local NetworkSetup = {}

NetworkSetup.debug = false

--已经处理过的类不用重新处理
NetworkSetup.rpcCaches = {}

NetworkSetup.profilerEnabled = false

local hashCache = {}

--字符串哈希
local function HashString(str)
    if hashCache[str] then
        return hashCache[str]
    end
    local hash = Utils:HashString(str)
    hashCache[str] = hash
    return hash
end

--服务端广播客户端
local function SendRpc(netObj,includeSelf, rpcName, ...)
    --如果没有网络id，不广播
    if not netObj.netId then
        Log:Error("SendRpc netObj.netId = %s", tostring(netObj.netId))
        return
    end
    if not netObj:IsReady() then
        if NetworkSetup.debug then
            Log:Error("SendRpc netObj:IsReady() = %s rpcName : %s", tostring(netObj:IsReady()), rpcName)
        end
        return
    end
    local rpc = HashString(rpcName)
    local body = NetworkPacker:Pack(rpc, {...})
    body.nid = netObj.netId
    body.snid = netObj.subNetId
    if NetworkSetup.debug then
        body.rpcName = rpcName
    end
    netObj:SendToObservers(NetProto.RpcNetCode, body, includeSelf)
end

--服务端调用指定客户端，只能是拥有playerId的对象
local function SendTargetRpc(netObj, rpcName, ...)
    --如果没有网络id，不发送
    if not netObj.netId then
        Log:Error("SendTargetRpc netObj.netId = %s", tostring(netObj.netId))
        return
    end
    if not netObj:IsReady() then
        if NetworkSetup.debug then
            Log:Error("SendTargetRpc netObj:IsReady() = %s rpcName : %s", tostring(netObj:IsReady()), rpcName)
        end
        return
    end
    if not netObj:IsPlayer() then
        Log:Error("SendTargetRpc netObj:IsPlayer() = %s", tostring(netObj:IsPlayer()))
        return
    end
    local rpc = HashString(rpcName)
    local body = NetworkPacker:Pack(rpc, {...})
    body.nid = netObj.netId
    body.snid = netObj.subNetId
    if NetworkSetup.debug then
        body.rpcName = rpcName
    end
    local playerId = netObj:GetPlayerId()
    netObj:SendToClient(NetProto.RpcNetCode, body)
end

--客户端调用服务端
local function SendCmd(netObj, cmdName, ...)
    --如果没有网络id，不发送
    if not netObj.netId then
        Log:Error("SendCmd netObj.netId = %s", tostring(netObj.netId))
        return
    end
    if not netObj:IsReady() then
        if NetworkSetup.debug then
            Log:Error("SendCmd netObj:IsReady() = %s cmdName : %s", tostring(netObj:IsReady()), cmdName)
        end
        return
    end
    local rpc = HashString(cmdName)
    local body = NetworkPacker:Pack(rpc, {...})
    body.nid = netObj.netId
    body.snid = netObj.subNetId
    if NetworkSetup.debug then
        body.cmdName = cmdName
    end
    netObj:SendToServer(NetProto.RpcNetCode, body)
end

--注册全部处理函数
local function RegisterAllRpcHandlers(rpcTable, saveTable)
    if not saveTable.rpcHandlers then
        saveTable.rpcHandlers = {}
    end
    if not saveTable.cmdHandlers then
        saveTable.cmdHandlers = {}
    end

    -- 先收集所有需要处理的事件
    local rpcEvents = {}
    local orpcEvents = {}
    local cmdEvents = {}
    local trpcEvents = {}

    for k, v in pairs(rpcTable) do
        if type(v) == "function" then
            if not saveTable["__TRpc__"..k] and Utils:StartWith(k,"TRpc") then
                table.insert(trpcEvents, k)
            elseif not saveTable["__ORpc__"..k] and Utils:StartWith(k,"ORpc") then
                table.insert(orpcEvents, k)
            elseif not saveTable["__Rpc__"..k] and Utils:StartWith(k,"Rpc") then
                table.insert(rpcEvents, k)
            elseif not saveTable["__Cmd__"..k] and Utils:StartWith(k,"Cmd") then
                table.insert(cmdEvents, k)
            end
        end
    end

    -- 分别处理收集到的事件
    for _, k in ipairs(trpcEvents) do
        saveTable.rpcHandlers[HashString(k)] = rpcTable[k]
        saveTable[k] = function(t,...)
            if t:IsServer() then
                SendTargetRpc(t,k,...)
            else
                rpcTable[k](t,...)
            end
        end
        saveTable["__TRpc__"..k] = true
    end
    for _, k in ipairs(orpcEvents) do
        saveTable.rpcHandlers[HashString(k)] = rpcTable[k]
        saveTable[k] = function(t,...)
            if t:IsServer() then
                SendRpc(t, false, k, ...)
            else
                rpcTable[k](t,...)
            end
        end
        saveTable["__ORpc__"..k] = true
    end
    for _, k in ipairs(rpcEvents) do
        saveTable.rpcHandlers[HashString(k)] = rpcTable[k]
        saveTable[k] = function(t,...)
            if t:IsServer() then
                SendRpc(t, true, k, ...)
            else
                rpcTable[k](t,...)
            end
        end
        saveTable["__Rpc__"..k] = true
    end

    for _, k in ipairs(cmdEvents) do
        saveTable.cmdHandlers[HashString(k)] = rpcTable[k]
        saveTable[k] = function(t,...)
            if not t:IsServer() then
                SendCmd(t,k,...)
            else
                rpcTable[k](t,...)
            end
        end
        saveTable["__Cmd__"..k] = true
    end

    if rpcTable.super then
        RegisterAllRpcHandlers(rpcTable.super, saveTable)
    end
end

--安装RPC功能
function NetworkSetup:SetupRpc(netObj)
    if not netObj.IsServer then
        Log:Error("The object does not have a IsServer method : "..netObj.__cname)
        return
    end
    if not netObj.IsPlayer then
        Log:Error("The object does not have a IsPlayer method : "..netObj.__cname)
        return
    end
    if not netObj.GetPlayerId then
        Log:Error("The object does not have a GetPlayerId method : "..netObj.__cname)
        return
    end

    if not netObj.IsReady then
        Log:Error("The object does not have a IsReady method : "..netObj.__cname)
        return
    end

    local key = netObj.class.__cname
    if self.rpcCaches[key] then
        return
    end
    --添加默认函数
    
    --设置同步信息
    netObj.class.SyncVar = function(obj, name, value)
        if not value then
            value = obj[name]
        end
        if obj:IsServer() then
            if obj.syncMode == NetworkDefines.SyncMode.Owner then
                obj:TRpcSyncVar(name,value)
            else
                obj:RpcSyncVar(name,value)
            end
        else
            if obj.syncDirection == NetworkDefines.SyncDirection.ClientToServer then
                obj:CmdSyncVar(name,value)
            end
        end
    end
    netObj.class.CmdSyncVar = function(obj, name,value)
        obj[name] = value
        obj:RpcSyncVar(name,value)
    end
    netObj.class.RpcSyncVar = function(obj, name,value)
        obj[name] = value
    end 
    netObj.class.TRpcSyncVar = function(obj, name,value)
        obj[name] = value
    end 

    RegisterAllRpcHandlers(netObj.class,netObj.class)
    self.rpcCaches[key] = true
end

-------------------------------------------设置基础通讯-------------------------------------------

--已经处理过的类不用重新处理
NetworkSetup.globalCaches = {}
NetworkSetup.globalClientNetObjs = {}
NetworkSetup.globalServerNetObjs = {}

--注册全部处理函数
local function RegisterAllGlobalHandlers(evtTable, saveTable)
    
    -- 先收集所有需要处理的事件
    local callServerEvents = {}
    local callClientEvents = {}
    local broadcastEvents = {}
    
    for k, v in pairs(evtTable) do
        if type(v) == "function" then
            if Utils:StartWith(k,"CallServer_") and not saveTable["__CallServer__"..k] then
                callServerEvents[k] = v
            elseif Utils:StartWith(k,"CallClient_") and not saveTable["__CallClient__"..k] then
                callClientEvents[k] = v
            elseif Utils:StartWith(k,"Broadcast_") and not saveTable["__Broadcast__"..k] then
                broadcastEvents[k] = v
            end
        end
    end
    
    -- 分别处理收集到的事件
    for k, v in pairs(callServerEvents) do
        local evtName = k:sub(12)
        saveTable[k] = function(obj, ...)
            local body = NetworkPacker:Pack(HashString(evtName), {...})
            body.sessionId = obj:GetSessionId()
            netObj:SendToServer(NetProto.RequestNetCode, body)
        end
        saveTable["__CallServer__"..k] = true
    end
    
    for k, v in pairs(callClientEvents) do
        local evtName = k:sub(12)
        saveTable[k] = function(obj, ...)
            local body = NetworkPacker:Pack(HashString(evtName), {...})
            body.sessionId = obj:GetSessionId()
            netObj:SendToClient(NetProto.ResponseNetCode, body)
        end
        saveTable["__CallClient__"..k] = true
    end
    
    for k, v in pairs(broadcastEvents) do
        local evtName = k:sub(11)
        saveTable[k] = function(obj, ...)
            local body = NetworkPacker:Pack(HashString(evtName), {...})
            netObj:SendToAllClients(NetProto.ResponseNetCode, body)
        end
        saveTable["__Broadcast__"..k] = true
    end

    if evtTable.super then
        RegisterAllGlobalHandlers(evtTable.super, saveTable)
    end
end

local function RegisterAllGlobalListener(netObj, evtTable)
    if not netObj.responseHandlers then
        netObj.responseHandlers = {}
    end
    if not netObj.requestHandlers then
        netObj.requestHandlers = {}
    end
    
    -- 先收集所有需要处理的事件
    local responseEvents = {}
    local requestEvents = {}
    
    for k, v in pairs(evtTable) do
        if type(v) == "function" then
            if Utils:StartWith(k,"Response_") then
                responseEvents[k] = v
            elseif Utils:StartWith(k,"Request_") then
                requestEvents[k] = v
            end
        end
    end
    
    -- 分别处理收集到的事件
    for k, v in pairs(responseEvents) do
        local evtName = k:sub(10)
        netObj.responseHandlers[HashString(evtName)] = function(t,...)
            v(t, ...)
        end
    end
    for k, v in pairs(requestEvents) do
        local evtName = k:sub(9)
        netObj.requestHandlers[HashString(evtName)] = function(t,...)
            v(t, ...)
        end
    end

    if evtTable.super then
        RegisterAllGlobalListener(netObj, evtTable.super)
    end
end

--安装全局事件功能
function NetworkSetup:SetupGlobal(netObj)
    if not netObj.GetPlayerId then
        Log:Error("The object does not have a GetPlayerId method : "..netObj.__cname)
        return
    end
    if not netObj.GetSessionId then
        Log:Error("The object does not have a GetSessionId method : "..netObj.__cname)
        return
    end
    if not netObj.CheckSession then
        Log:Error("The object does not have a CheckSession method : "..netObj.__cname)
        return
    end
    if not netObj.IsServer then
        Log:Error("The object does not have a IsServer method : "..netObj.__cname)
        return
    end
    local tempClass = netObj.class or netObj
    local key = tempClass.__cname
    if not self.globalCaches[key] then
        RegisterAllGlobalHandlers(tempClass,tempClass)
        self.globalCaches[key] = true
    end

    if netObj:IsServer() then
        self.globalServerNetObjs[netObj] = true
    else
        self.globalClientNetObjs[netObj] = true
    end

    RegisterAllGlobalListener(netObj, tempClass)

    --重写netObj的 OnDestructor
    local oldOnDelete = netObj.OnDestructor
    netObj.OnDestructor = function()
        if oldOnDelete then
            oldOnDelete(netObj)
        end
        --清理事件
        netObj.responseHandlers = nil
        netObj.requestHandlers = nil
        if netObj:IsServer() then
            self.globalServerNetObjs[netObj] = nil
        else
            self.globalClientNetObjs[netObj] = nil
        end
    end
end


Network.ClientActorPreReciveCallback = 
function(msgid, body)
    if NetProto.RpcNetCode == msgid then
        if NetworkSetup.profilerEnabled then
            Profiler:Start("ClientReceive: ["..msgid.."] "..tostring(body.rpcName),0.1)
        end
        local rpc, data = NetworkPacker:Unpack(body, false)
        local obj = NetworkPacker:UnpackObj(body, false)
        if obj and obj.rpcHandlers then
            local rpcHandler = obj.rpcHandlers[rpc]
            if rpcHandler then
                PCall(function()
                    rpcHandler(obj, unpack(data))
                end, obj)
            end
        else
            Log:Error("Can not find the object : "..body.nid.. " subNetId : " .. tostring(body.snid) .. " rpc : " .. tostring(body.rpcName))
        end 
        if NetworkSetup.profilerEnabled then
            Profiler:Stop()
        end
        return true
    elseif NetProto.ResponseNetCode == msgid then
        if NetworkSetup.profilerEnabled then
            Profiler:Start("ClientReceive: ["..msgid.."] ",0.1)
        end
        local response, data = NetworkPacker:Unpack(body, false)
        for netObj, _ in pairs(NetworkSetup.globalClientNetObjs) do
            if netObj:CheckSession(body.sessionId) then   
                local responseHandler = netObj.responseHandlers[response]
                if responseHandler then
                    PCall(function()
                        responseHandler(netObj, unpack(data))
                    end, netObj)
                end
            end
        end
        if NetworkSetup.profilerEnabled then
            Profiler:Stop()
        end
        return true
    end
    return false
end
Network.ServerActorPreReciveCallback = 
function(playerId, msgid, body)
    if NetProto.RpcNetCode == msgid then
        if NetworkSetup.profilerEnabled then
            Profiler:Start("ServerReceive: ["..msgid.."] "..tostring(body.cmdName),0.1)
        end
        local rpc, data = NetworkPacker:Unpack(body, true)
        local obj = NetworkPacker:UnpackObj(body, true)
        if obj then
            local cmdHandler = obj.cmdHandlers[rpc]
            if cmdHandler then
                PCall(function()
                    cmdHandler(obj, unpack(data))
                end, obj)
            end
        else
            Log:Error("Can not find the object : "..body.nid.. " subNetId : " .. tostring(body.snid) .. " cmd : " .. tostring(body.cmdName))
        end
        if NetworkSetup.profilerEnabled then
            Profiler:Stop()
        end
        return true
    elseif NetProto.RequestNetCode == msgid then
        if NetworkSetup.profilerEnabled then
            Profiler:Start("ServerReceive: ["..msgid.."] ",0.1)
        end
        local request, data = NetworkPacker:Unpack(body, true)
        for netObj, _ in pairs(NetworkSetup.globalServerNetObjs) do
            if netObj:CheckSession(body.sessionId) then
                local requestHandler = netObj.requestHandlers[request]
                if requestHandler then
                    PCall(function()
                        requestHandler(netObj, unpack(data))
                    end, netObj)
                end
            end
        end
        if NetworkSetup.profilerEnabled then
            Profiler:Stop()
        end
        return true
    end
    return false
end

return NetworkSetup