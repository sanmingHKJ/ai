--Bridge.lua
local Bridge = {}
Bridge.RemoteEvent = script.RemoteEvent

Bridge.ClientMessageCallbackPools = {}
Bridge.ServerMessageCallbackPools = {}

local clientCallbackAutoId = 10000
local serverCallbackAutoId = 10000

local callback = {}
callback.new = function(eventId, callback)
	return {
		eventId = eventId,
		callback = callback,
		valid = true
	}
end

Bridge.RegisterClientMessageCallback = function(self, id, fun)
	if MS.RunService:IsServer() then
		local pool = Bridge.ClientMessageCallbackPools[id]
		if nil == pool then
			pool = {}
			Bridge.ClientMessageCallbackPools[id] = pool
		end
		
		if pool[fun] ~= nil and true == pool[fun].valid then
			print("message callback already exists")
		else
			local eventId = clientCallbackAutoId
			clientCallbackAutoId = clientCallbackAutoId + 1
			pool[fun] = callback.new(eventId, fun)
			return eventId
		end
	else
		print("RegisterClientMessageCallback:this is server script api")
	end
end

Bridge.RemoveClientMessageCallback = function(self, eventId)
	if MS.RunService:IsServer() then
		for _, pool in pairs(Bridge.ClientMessageCallbackPools) do
			for fun, callback in pairs(pool) do
				if callback.eventId == eventId then
					-- Remove from pool
					pool[fun] = nil
					return true
				end
			end
		end
		return false
	else
		print("RemoveClientMessageCallback:this is server script api")
		return false
	end
end

Bridge.CancelClientMessageCallback = function(self, id, fun)
	if MS.RunService:IsServer() then
		local pool = Bridge.ClientMessageCallbackPools[id]
		if nil ~= pool and nil ~= pool[fun] then
			pool[fun].valid = false
		else
			print("Client Message Callback not exists, ClientMsgID : " .. id)
		end
	else
		print("CancelClientMessageCallback:this is server script api")
	end
end

Bridge.RegisterServerMessageCallback = function(self, id, fun)
	if MS.RunService:IsClient() then
		local pool = Bridge.ServerMessageCallbackPools[id]
		if nil == pool then
			pool = {}
			Bridge.ServerMessageCallbackPools[id] = pool
		end

		if pool[fun] ~= nil then
			print("message callback already exists")
		else
			local eventId = serverCallbackAutoId
			serverCallbackAutoId = serverCallbackAutoId + 1
			pool[fun] = callback.new(eventId, fun)
			return eventId
		end
	else
		print("RegisterServerMessageCallback:this is client script api")
	end 
end

Bridge.RemoveServerMessageCallback = function(self, eventId)
	if MS.RunService:IsClient() then
		for _, pool in pairs(Bridge.ServerMessageCallbackPools) do
			for fun, callback in pairs(pool) do
				if callback.eventId == eventId then
					-- Remove from pool
					pool[fun] = nil
					return true
				end
			end
		end
		return false
	end
end

Bridge.CancelServerMessageCallback = function(self, id, fun)
	if MS.RunService:IsClient() then
		local pool = Bridge.ServerMessageCallbackPools[id]
		if nil ~= pool and nil ~= pool[fun] then
			pool[fun].valid = false
		else
			print("Server Message Callback not exists, ServerMsgID : " .. id)
		end
	else
		print("CancelServerMessageCallback:this is server script api")
	end
end

Bridge.BroadcastMessage = function(self, msgid, body)
	if MS.RunService:IsServer() then
		if msgid == nil then
			print("nil msgid");
			return
		end

		Bridge.RemoteEvent:fireAllClients(msgid, body or {})
	else 
		print("BroadcastMessage:this is server script api")
	end
end

Bridge.SendMessageToClient = function(self, playerId, msgid, body)
	if MS.RunService:IsServer() then
		if msgid == nil then
			print("nil msgid");
			return
		end
		Bridge.RemoteEvent:fireClient(playerId, msgid, body or {})
	else 
		print("SendMessageToClient:this is server script api")
	end
end

Bridge.SendMessageToServer = function(self, msgid, body)
	if MS.RunService:IsClient() then
		if msgid == nil then
			print("nil msgid");
			return
		end
		Bridge.RemoteEvent:fireServer(msgid, body or {})
	else 
		print("SendMessageToServer:this is client script api")
	end
end

if MS.RunService:IsClient() then
	Bridge.RemoteEvent.OnClientNotify:connect(function(msgid, bin)
		--print('temp',"OnClientNotify msgid : ", msgid, " , bin : ", bin or "")

		local pool = Bridge.ServerMessageCallbackPools[msgid] 
		if pool then
			for _, value in pairs(pool) do
				if value.valid then
					value.callback(msgid, bin)
				end
			end
		end
	end)
end

if MS.RunService:IsServer() then
	Bridge.RemoteEvent.OnServerNotify:connect(function(playerId, msgid, bin)
		--print('temp',"OnServerNotify msgid : ", msgid, " , bin : ", bin or "")
		local pool = Bridge.ClientMessageCallbackPools[msgid]
		if pool then
			for _, value in pairs(pool) do
				if value.valid then
					value.callback(playerId, msgid, bin)
				end
			end
		end
	end)
end

return Bridge
