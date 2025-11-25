local Log = GFScript("CoreModule.Log")
local Json = GFScript("CoreModule.Json")
local Utils = GFScript("CoreModule.Utils")
local CloudService = game:GetService("CloudService")
local Database = {}

--数据缓存
Database.playerDataCache = {} --key:playerId, value:{key:value}

--初始化
function Database:Init(saveInterval)
end
--是否存在数据
function Database:HasData(playerId, name)
    if playerId == nil then
        Log:Error("playerId is nil")
        return false
    end
    local playerData = self.playerDataCache[playerId]
    if not playerData then
        return false
    end
    if not playerData[name] then
        return false
    end
    return true
end
--获取数据
function Database:GetData(playerId, name)
    if playerId == nil or name == nil then
        Log:Error("playerId or name is nil")
        return
    end
    local playerData = self.playerDataCache[playerId]
    if not playerData then
        Log:Error("playerData is nil! playerId = "..playerId)
        return
    end

    return playerData[name]
end
--设置数据
function Database:SetData(playerId, name, value, saveNow, callback)
    if playerId == nil or name == nil or value == nil then
        Log:Error("playerId or name or value is nil")
        return
    end
    local playerData = self.playerDataCache[playerId]
    if not playerData then
        playerData = {}
    end
    playerData[name] = value
    self.playerDataCache[playerId] = playerData
    if saveNow then
        self:SaveData(playerId, name, function()
            if callback then callback(true) end
        end)
    end
end
--请求数据
function Database:RequestData(playerId, name, version, callback)
    if playerId == nil then
        Log:Error("playerId is nil")
        return
    end
    local keyStr = "Player."..playerId .. "." .. name
	--请求云服数据
	CloudService:GetTableAsync(keyStr, function(status, value)
		if not status then
			Log:Error("RequestData Error! playerId = "..playerId)
            if callback then callback(false) end
			return
		end
        if type(value) == "string" then
            value = Json.encode(value)
        end
        if value.version ~= version then
            if callback then callback(false) end
			return
        end
        local playerData = self.playerDataCache[playerId]
        if not playerData then
            playerData = {}
        end
        playerData[name] = value
        self.playerDataCache[playerId] = playerData
		if callback then callback(true, value) end
	end)
end
--存储数据
function Database:SaveData(playerId, name, value, saveNow, callback)
    if playerId == nil or name == nil or value == nil then
        Log:Error("playerId or name or value is nil")
        return
    end
    local playerData = self.playerDataCache[playerId]
    if not playerData then
        playerData = {}
    end
    playerData[name] = value
    self.playerDataCache[playerId] = playerData

    if saveNow then
        local keyStr = "Player."..playerId .. "." .. name
        local data = value
        if type(value) == "string" then
            data = Json.encode(value)
        end
        
        CloudService:SetTableAsync(keyStr, data, function(status)
            if not status then
                Log:Error("SaveData Error! playerId = "..playerId)
            end
            if callback then callback(status) end
        end)
    end
end
--更新
function Database:Update(dt)
end

return Database