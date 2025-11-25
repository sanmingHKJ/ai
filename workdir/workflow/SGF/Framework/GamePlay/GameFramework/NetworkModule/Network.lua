local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Profiler = GFScript("CoreModule.Profiler")
local NetProto = GFScript("NetworkModule.NetProto")
local Players = game:GetService("Players")

local Network = {}
Network.RemoteEvent = script.RemoteEvent
-- Network.RemoteActorEvent = script.RemoteActorEvent
--网络延迟模拟
Network.networkDelayEnabled =  false
Network.networkMinDelay = 0.05
Network.networkMaxDelay = 0.1
Network.networkClientSequence = {}
Network.networkServerSequence = {}

--客户端回调
Network.ClientCallbacks = {}
--服务端回调
Network.ServerCallbacks = {}

--服务端协议回调
Network.ServerPreReciveCallback = nil
-- 客户端协议回调
Network.ClientPreReciveCallback = nil

--服务端actor回调
Network.ServerActorPreReciveCallback = nil
--客户端actor回调
Network.ClientActorPreReciveCallback = nil

--是否启用协议打印调试
Network.clientDebugEnabled = false
Network.serverDebugEnabled = false

--服务器错误回调
Network.errorCallback = nil
--是否启用错误回调
Network.errorCallbackEnabled = true

Network.clientCallbackAutoId = 10000
Network.serverCallbackAutoId = 10000

Network.profilerEnabled = false

--消息类型
local Msg = {
	Say = 1,
	Ping = 2,
	Error = 3,
}

Network.currentProtocolIndex = 0
Network.maxProtocolIndex = 10000000
Network.blockedIndices = {} -- 将存储 {active = true, minIndex = index, timeout = time} 的结构
Network.pendingMessages = {}

-- 修改阻塞相关函数
function Network:BlockProtocolIndex(index, timeout)
    timeout = timeout or 3 -- 默认3秒超时
    self.blockedIndices[index] = {
        active = true,
        minIndex = index,
        timeout = Utils:GetServerTime() + timeout
    }
end

function Network:UnblockProtocolIndex(index)
    self.blockedIndices[index] = nil
    self:ProcessPendingMessages()
end

function Network:IsBlocked(protocolIndex)
    local currentTime = Utils:GetServerTime()
    for index, blockInfo in pairs(self.blockedIndices) do
        -- 检查是否超时
        if blockInfo.active and currentTime > blockInfo.timeout then
            -- 超时自动解除阻塞
            self:UnblockProtocolIndex(index)
        else
            if blockInfo.active and protocolIndex >= blockInfo.minIndex then
                return true
            end
        end
    end
    return false
end

function Network:ProcessPendingMessages()
    local processed = {}
    for i, msgData in ipairs(self.pendingMessages) do
        if not self:IsBlocked(msgData.index) then
            self:ProcessClientMessage(msgData.msgid, msgData.bin)
            table.insert(processed, i)
        end
    end
    -- Remove processed messages in reverse order
    for i = #processed, 1, -1 do
        table.remove(self.pendingMessages, processed[i])
    end
end
--处理客户端消息
function Network:ProcessClientMessage(msgid, bin)
    if Network.ClientPreReciveCallback and Network.ClientPreReciveCallback(msgid, bin) then
        return
    end
	if self:IsActorMessage(msgid) then
		self:ProcessClientActorMessage(msgid, bin)
	else
		local pool = self.ClientCallbacks[msgid]
		if pool then
			for _, value in pairs(pool) do
				PCall(function()
					if value.obj then
						value.callback(value.obj, msgid, bin)
					else
						value.callback(msgid, bin)
					end
				end)
			end
		end
	end
end
--处理服务端消息
function Network:ProcessServerMessage(playerId, msgid, bin)
    if Network.ServerPreReciveCallback and Network.ServerPreReciveCallback(playerId, msgid, bin) then
        return
    end
	if self:IsActorMessage(msgid) then
		self:ProcessServerActorMessage(playerId, msgid, bin)
	else
		local pool = self.ServerCallbacks[msgid]
		if pool then
			for _, value in pairs(pool) do
				PCall(function()
					if value.obj then
						value.callback(value.obj, playerId, msgid, bin)
					else
						value.callback(playerId, msgid, bin)
					end
				end)
			end
		end
	end
end

function Network:GetNextProtocolIndex()
    self.currentProtocolIndex = self.currentProtocolIndex + 1
    if self.currentProtocolIndex > self.maxProtocolIndex then
        self.currentProtocolIndex = 1
    end
    return self.currentProtocolIndex
end

function Network:_FireClient(node, playerId, msgid, body)
    if Network.networkDelayEnabled then
        local data = {}
        data.delay = math.random(Network.networkMinDelay, Network.networkMaxDelay)
        data.delayEnd = Utils:GetServerTime() + data.delay
        data.msgid = msgid
        data.body = body
        data.playerId = playerId
        data.node = node
        table.insert(Network.networkClientSequence, data)
    else
        node:FireClient(playerId, msgid, body)
    end
end
function Network:_FireServer(node, msgid, body)
    if Network.networkDelayEnabled then
        local data = {}
        data.delay = math.random(Network.networkMinDelay, Network.networkMaxDelay)
        data.delayEnd = Utils:GetServerTime() + data.delay
        data.msgid = msgid
        data.body = body
        data.node = node
        table.insert(Network.networkServerSequence, data)
    else
        node:FireServer(msgid, body)
    end
end
local Callback = {}
function Callback.New(eventId, callback,obj)
	return {
		eventId = eventId,
		obj = obj,
		callback = callback
	}
end
--设置客户端事件回调，单播
function Network:ClientSetCallback(id, fun, obj)
	if Utils:IsClient() then
		local pool = self.ClientCallbacks[id]
		if nil == pool then
			pool = {}
			self.ClientCallbacks[id] = pool
		end

		for k,v in pairs(pool) do
			if (not v.obj or v.obj == obj) and v.callback == fun then
				Log:Error("message callback already exists")
				return
			end
		end

		local id = Network.clientCallbackAutoId
		table.insert(pool, Callback.New(id,fun,obj))
		Network.clientCallbackAutoId = Network.clientCallbackAutoId + 1
		return id
	else
		Log:Error("this is client script api")
	end
end
--移除客户端事件回调
function Network:ClientRemoveCallback(id, fun, obj)
	if Utils:IsClient() then
		local pool = self.ClientCallbacks[id]
		if nil ~= pool then
			for k,v in pairs(pool) do
				if (not v.obj or v.obj == obj) and v.callback == fun then
					table.remove(pool, k)
					return
				end
			end
		else
			Log:Error("Client Message Callback not exists, ClientMsgID : " .. id)
		end
	else
		Log:Error("this is client script api")
	end
end
function Network:ClientRemoveCallbackByEventId(eventId)
	for _, pool in pairs(self.ClientCallbacks) do
		for k, v in pairs(pool) do
			if v.eventId == eventId then
				table.remove(pool, k)
				return
			end
		end
	end
end
--设置服务端事件回调，单播
function Network:ServerSetCallback(id, fun, obj)
	if Utils:IsServer() then
		local msgPool = self.ServerCallbacks[id]
		if nil == msgPool then
			msgPool = {}
			self.ServerCallbacks[id] = msgPool
		end
		
		for k,v in pairs(msgPool) do
			if (not v.obj or v.obj == obj) and v.callback == fun then
				Log:Error("message callback already exists")
				return
			end
		end
		local id = Network.serverCallbackAutoId	
		table.insert(msgPool, Callback.New(id,fun,obj))
		Network.serverCallbackAutoId = Network.serverCallbackAutoId + 1
		return id
	else
		Log:Error("this is server script api")
	end 
end
--移除服务端回调
function Network:ServerRemoveCallback(id, fun, obj)
	if Utils:IsServer() then
		local msgPool = self.ServerCallbacks[id]
		if nil ~= msgPool then
			if nil ~= msgPool then
				for k,v in pairs(msgPool) do
					if(not v.obj or v.obj == obj) and v.callback == fun then
						table.remove(msgPool, k)
						return
					end
				end
			end
		else
			Log:Error("Client Message Callback not exists, ClientMsgID : " .. id)
		end
	else
		Log:Error("this is server script api")
	end
end
function Network:ServerRemoveCallbackByEventId(eventId)
	for _, pool in pairs(self.ServerCallbacks) do
		for k, v in pairs(pool) do
			if v.eventId == eventId then
				table.remove(pool, k)
				return
			end
		end
	end
end
--服务端广播消息
function Network:Broadcast(msgid, body)
	if Utils:IsServer() then
		if msgid == nil then
			Log:Error("nil msgid");
			return
		end
		--暂时全员广播
		local players = Players:GetPlayers()
		for i, v in ipairs(players) do
			self:SendToClient(v.UserId, msgid, body)
		end
		--self.RemoteEvent:FireAllClients(msgid, body)
	else 
		Log:Error("this is server script api")
	end
end
--服务端往指定玩家发送数据
function Network:SendToClient(playerId, msgid, body)
	if Utils:IsServer() then
		if msgid == nil then
			Log:Error("nil msgid");
			return
		end

		self:_FireClient(self.RemoteEvent, playerId, msgid, body)
	else 
		Log:Error("this is server script api")
	end
end
--向客户端发送错误信息
function Network:Say(msg)
	if Utils:IsServer() then
		self:Broadcast(Msg.Say, {msg = msg})
	else 
		Log:Error("this is server script api")
	end
end
--客户端往服务端发送数据
function Network:SendToServer(msgid, body)
	if Utils:IsClient() then
		if msgid == nil then
			Log:Error("nil msgid");
			return
		end
		self:_FireServer(self.RemoteEvent, msgid, body)
	else 
		Log:Error("this is client script api")
	end
end

function Network:Ping()
	if Utils:IsClient() then
		self:_FireServer(self.RemoteEvent, Msg.Ping, {ctime = Utils:GetSystemTime()})
	else 
		Log:Error("this is client script api")
	end
end

function Network:OnSPing(playerId, code, body)
	if Utils:IsServer() then
		local sbody = {
			ctime = body.ctime;
			stime = Utils:GetSystemTime();
		}
		self:_FireClient(self.RemoteEvent, playerId, code, sbody)
	else 
		Log:Error("this is server script api")
	end
end
function Network:OnCPing(code, body)
	local curTime = Utils:GetLocalTime()
	local roundTime = curTime - body.ctime

	local timeOffset = body.stime - curTime - roundTime / 2
    Utils:SetServerTimeOffset(timeOffset)

    Log:Error("Client Ping RoundTime:" .. tostring(roundTime))
end

function Network:OnSay(code, body)
	Log:Error("Server Say: " .. body.msg)
end
--发送错误信息
function Network:Error(msg, actor)
	if not Network.errorCallbackEnabled then
		return false
	end
	if actor then
		if actor:IsServer() then
			msg = actor:GetActorId() .. " Server Error: " .. msg
			if actor:IsPlayer() then
				self:SendToClient(actor:GetPlayerId(), Msg.Error, {msg = msg})
			else
				self:Broadcast(Msg.Error, {msg = msg})
			end
		else
			msg = actor:GetActorId() .. " Client Error: " .. msg
			self:PrintError(msg)
		end
	else
		if Utils:IsServerOnly() then
			msg = "Server Error: " .. msg
			self:Broadcast(Msg.Error, {msg = msg})
		elseif Utils:IsClientOnly() then
			msg = "Client Error: " .. msg
			self:PrintError(msg)
		elseif Utils:IsHost() then
			msg = "Host Error: " .. msg
			self:Broadcast(Msg.Error, {msg = msg})
		end
	end
	return true
end

function Network:OnError(code, body)
	self:PrintError(body.msg)
end

function Network:PrintError(msg)
	--Log:Error(msg)
	if Network.errorCallback then
		Network.errorCallback(msg)
	end
end

--设置错误回调
function Network:SetErrorCallback(callback)
	Network.errorCallback = callback
end

Network:ClientSetCallback(Msg.Say, Network.OnSay, Network)
Network:ClientSetCallback(Msg.Error, Network.OnError, Network)
Network:ServerSetCallback(Msg.Ping, Network.OnSPing, Network)
Network:ClientSetCallback(Msg.Ping, Network.OnCPing, Network)
--更新
function Network:Update(dt)
	-- 检查阻塞超时
	local currentTime = Utils:GetServerTime()
	for index, blockInfo in pairs(self.blockedIndices) do
		if blockInfo.active and currentTime > blockInfo.timeout then
			self:UnblockProtocolIndex(index)
		end
	end

	if Network.networkDelayEnabled then
		for i, v in pairs(Network.networkClientSequence) do
			if Utils:GetServerTime() > v.delayEnd then
				table.remove(Network.networkClientSequence, i)
				v.node:FireClient(v.playerId, v.msgid, v.body)
			else
				break
			end
		end
		for i, v in pairs(Network.networkServerSequence) do
			if Utils:GetServerTime() > v.delayEnd then
				table.remove(Network.networkServerSequence, i)
				v.node:FireServer(v.msgid, v.body)
			else
				break
			end
		end
	end
end
--分发客户端事件
if Utils:IsClient() then
	Network.RemoteEvent.OnClientNotify:Connect(function(msgid, bin)
		if Network.clientDebugEnabled then
			Log:Debug("ClientReceive: ["..msgid.."] " .. Utils:T2S(bin))
		end
		
		local protocolIndex = Network:GetNextProtocolIndex()
		bin.protocolIndex = protocolIndex
		
		-- 检查是否被任何更小的 index 阻塞
		if Network:IsBlocked(protocolIndex) then
			-- 存储消息以供后续处理
			table.insert(Network.pendingMessages, {
				index = protocolIndex,
				msgid = msgid,
				bin = bin
			})
		else
			if Network.profilerEnabled then
				Profiler:Start("ClientReceive: ["..msgid.."] ",0.1)
			end
			-- 直接处理消息
			Network:ProcessClientMessage(msgid, bin)
			if Network.profilerEnabled then
				Profiler:Stop()
			end
		end
	end)
	-- Network.RemoteActorEvent.OnClientNotify:Connect(function(msgid, body)
	-- 	if Network.actorManager == nil then
	-- 		Network.actorManager = GFScript("ActorModule.ActorManager")
	-- 	end
	-- 	if Network.sceneManager == nil then
	-- 		Network.sceneManager = GFScript("ActorModule.SceneManager")
	-- 	end
	-- 	if Network.clientDebugEnabled then
	-- 		Log:Debug("ClientReceive: ["..msgid.."] " .. Utils:T2S(body))
	-- 	end
	-- 	if Network.profilerEnabled then	
	-- 		Profiler:Start("ClientReceive: ["..msgid.."] ",0.1)
	-- 	end
	-- 	if Network.ClientActorPreReciveCallback and Network.ClientActorPreReciveCallback(msgid, body) then
	-- 		if Network.profilerEnabled then
	-- 			Profiler:Stop()
	-- 		end
	-- 		return
	-- 	end
	-- 	if body.sceneId then
	-- 		local scene = Network.sceneManager:GetScene(body.sceneId)
	-- 		if scene then
	-- 			scene:ClientReciveData(msgid, body)
	-- 		end
	-- 	end
    --     local actor = Network.actorManager.clientActors[body.actorId]
    --     if actor then
    --         actor:ClientReciveData(msgid, body)
    --     end
	-- 	if Network.profilerEnabled then
	-- 		Profiler:Stop()
	-- 	end
	-- end)
end
--分发服务端事件
if Utils:IsServer() then
	Network.RemoteEvent.OnServerNotify:Connect(function(playerId, msgid, bin)
		if Network.serverDebugEnabled then
			Log:Debug("ServerReceive: ["..msgid.."] ["..playerId.."] " .. Utils:T2S(bin))
		end

		if Network.profilerEnabled then
			Profiler:Start("ServerReceive: ["..msgid.."] ["..playerId.."] ",0.1)
		end

		Network:ProcessServerMessage(playerId, msgid, bin)

		if Network.profilerEnabled then
			Profiler:Stop()
		end
	end)
	-- Network.RemoteActorEvent.OnServerNotify:Connect(function(playerId, msgid, body)
	-- 	if Network.actorManager == nil then
	-- 		Network.actorManager = GFScript("ActorModule.ActorManager")
	-- 	end
	-- 	if Network.sceneManager == nil then
	-- 		Network.sceneManager = GFScript("ActorModule.SceneManager")
	-- 	end
	-- 	if Network.serverDebugEnabled then
	-- 		Log:Debug("ServerReceive: ["..msgid.."] ["..playerId.."] " .. Utils:T2S(body))
	-- 	end
	-- 	if Network.profilerEnabled then
	-- 		Profiler:Start("ServerReceive: ["..msgid.."] ["..playerId.."] ",0.1)
	-- 	end
	-- 	if Network.ServerActorPreReciveCallback and Network.ServerActorPreReciveCallback(playerId, msgid, body) then
	-- 		if Network.profilerEnabled then
	-- 			Profiler:Stop()
	-- 		end
	-- 		return
	-- 	end
		
	-- 	if body.sceneId then
	-- 		local scene = Network.sceneManager:GetScene(body.sceneId)
	-- 		if scene then
	-- 			scene:ServerReciveData(playerId, msgid, body)
	-- 		end
	-- 	end

    --     local actor = Network.actorManager.serverActors[body.actorId]
    --     if actor then
	-- 		--安全验证
	-- 		if actor:IsPlayer() and actor:GetPlayerId() ~= playerId then
				
	-- 		else
    --         	actor:ServerReciveData(msgid, body)
	-- 		end
    --     end
	-- 	if Network.profilerEnabled then
	-- 		Profiler:Stop()
	-- 	end
	-- end)
end


--处理客户端消息
function Network:ProcessClientActorMessage(msgid, body)
    if Network.actorManager == nil then
		Network.actorManager = GFScript("ActorModule.ActorManager")
	end
	if Network.sceneManager == nil then
		Network.sceneManager = GFScript("ActorModule.SceneManager")
	end
	if Network.clientDebugEnabled then
		Log:Debug("ClientReceive: ["..msgid.."] " .. Utils:T2S(body))
	end
	if Network.profilerEnabled then	
		Profiler:Start("ClientReceive: ["..msgid.."] ",0.1)
	end
	if Network.ClientActorPreReciveCallback and Network.ClientActorPreReciveCallback(msgid, body) then
		if Network.profilerEnabled then
			Profiler:Stop()
		end
		return
	end
	if body.sceneId then
		local scene = Network.sceneManager:GetScene(body.sceneId)
		if scene then
			scene:ClientReciveData(msgid, body)
		end
	end
	local actor = Network.actorManager.clientActors[body.actorId]
	if actor then
		actor:ClientReciveData(msgid, body)
	end
	if Network.profilerEnabled then
		Profiler:Stop()
	end
end
--处理服务端消息
function Network:ProcessServerActorMessage(playerId, msgid, body)
    if Network.actorManager == nil then
		Network.actorManager = GFScript("ActorModule.ActorManager")
	end
	if Network.sceneManager == nil then
		Network.sceneManager = GFScript("ActorModule.SceneManager")
	end
	if Network.serverDebugEnabled then
		Log:Debug("ServerReceive: ["..msgid.."] ["..playerId.."] " .. Utils:T2S(body))
	end
	if Network.profilerEnabled then
		Profiler:Start("ServerReceive: ["..msgid.."] ["..playerId.."] ",0.1)
	end
	if Network.ServerActorPreReciveCallback and Network.ServerActorPreReciveCallback(playerId, msgid, body) then
		if Network.profilerEnabled then
			Profiler:Stop()
		end
		return
	end
	
	if body.sceneId then
		local scene = Network.sceneManager:GetScene(body.sceneId)
		if scene then
			scene:ServerReciveData(playerId, msgid, body)
		end
	end

	local actor = Network.actorManager.serverActors[body.actorId]
	if actor then
		--安全验证
		if actor:IsPlayer() and actor:GetPlayerId() ~= playerId then
			
		else
			actor:ServerReciveData(msgid, body)
		end
	end
	if Network.profilerEnabled then
		Profiler:Stop()
	end
end

function Network:IsActorMessage(msgid)
    return msgid == NetProto.RpcNetCode or msgid == NetProto.ResponseNetCode or msgid == NetProto.RequestNetCode
end

return Network
