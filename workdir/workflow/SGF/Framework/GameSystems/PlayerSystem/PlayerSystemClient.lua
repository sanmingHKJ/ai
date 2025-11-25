--[[
    PlayerSystemClient.lua - 玩家系统（客户端）
    
    职责：
    1. 管理本地玩家数据缓存
    2. 发送玩家相关请求到服务端
    3. 接收服务端数据更新通知
    4. 触发UI更新事件
    
    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local PlayerSystemClient = {
    -- ========== 基础信息 ==========
    name = "PlayerSystemClient",
    version = "1.0.0",
    description = "玩家系统（客户端）",
    
    -- ========== 依赖声明 ==========
    dependencies = {},
    
    -- ========== 状态管理 ==========
    state = "uninitialized",
    
    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,
    
    -- ========== 配置 ==========
    config = {},
    
    -- ========== 数据 ==========
    data = {
        localPlayerData = nil,  -- 本地玩家数据
    },
    
    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

function PlayerSystemClient.new(sgf)
    local self = setmetatable({}, {__index = PlayerSystemClient})
    
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    
    self.data = {
        localPlayerData = nil
    }
    self.dependencies_cache = {}
    
    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function PlayerSystemClient:PreInit()
    self.log:info("PlayerSystemClient PreInit...")
    
    -- 注册事件监听器
    self:registerEventListeners()
    
    return true
end

function PlayerSystemClient:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("PlayerSystemClient already initialized")
        return false
    end
    
    self.log:info("PlayerSystemClient Init...")
    
    -- 注册网络消息处理
    self:registerNetworkHandlers()
    
    self.state = "initialized"
    return true
end

function PlayerSystemClient:PostInit()
    self.log:info("PlayerSystemClient PostInit...")
    return true
end

function PlayerSystemClient:Start()
    if self.state ~= "initialized" then
        self.log:error("PlayerSystemClient cannot start, state: " .. self.state)
        return false
    end
    
    self.log:info("PlayerSystemClient Start...")
    
    -- 请求玩家数据
    self:requestPlayerData()
    
    self.state = "started"
    return true
end

function PlayerSystemClient:Update(dt)
    -- 每帧更新逻辑（如果需要）
end

function PlayerSystemClient:Stop()
    self.log:info("PlayerSystemClient Stop...")
    self.state = "stopped"
    return true
end

-- ========================================
-- 事件监听
-- ========================================

function PlayerSystemClient:registerEventListeners()
    -- 客户端事件监听
    self.log:debug("PlayerSystemClient event listeners registered")
end

-- ========================================
-- 网络消息处理
-- ========================================

function PlayerSystemClient:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)


    if not NetworkHelper then
        self.log:error("NetworkHelper not found")
        return
    end
    
    -- 创建角色响应
    self:OnResponse(Protocol.ServerMSGID.PLAYER_CREATE_CHARACTER_RSP, function(msgid, data)
        self:onCreateCharacterResponse(data)
    end)
    
    -- 获取玩家数据响应
    self:OnResponse(Protocol.ServerMSGID.PLAYER_GET_DATA_RSP, function(msgid, data)
        self:onGetPlayerDataResponse(data)
    end)
    
    -- 玩家数据更新通知
    self:OnResponse(Protocol.ServerMSGID.PLAYER_DATA_UPDATE_NOTIFY, function(msgid, data)
        self:onPlayerDataUpdate(data)
    end)
    
    -- 玩家生命值更新通知
    self:OnResponse(Protocol.ServerMSGID.PLAYER_HEALTH_UPDATE_NOTIFY, function(msgid, data)
        self:onPlayerHealthUpdate(data)
    end)
    
    -- 玩家魔法值更新通知
    self:OnResponse(Protocol.ServerMSGID.PLAYER_MANA_UPDATE_NOTIFY, function(msgid, data)
        self:onPlayerManaUpdate(data)
    end)
    
    -- 玩家经验值更新通知
    self:OnResponse(Protocol.ServerMSGID.PLAYER_EXP_UPDATE_NOTIFY, function(msgid, data)
        self:onPlayerExpUpdate(data)
    end)
    
    -- 玩家升级响应
    self:OnResponse(Protocol.ServerMSGID.PLAYER_LEVEL_UP_RSP, function(msgid, data)
        self:onPlayerLevelUp(data)
    end)
    
    self.log:debug("PlayerSystemClient network handlers registered")
end

-- ========================================
-- 网络请求
-- ========================================

function PlayerSystemClient:requestCreateCharacter(characterName, classType)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
        self.log:info("Requesting create character: " .. characterName .. ", class: " .. classType)
    
    self:CallServer(Protocol.ClientMSGID.PLAYER_CREATE_CHARACTER_REQ, {
        characterName = characterName,
        classType = classType
    })
    
    return true
end

function PlayerSystemClient:requestPlayerData()
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
        self.log:debug("Requesting player data")
    
    self:CallServer(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, {})
    
    return true
end

function PlayerSystemClient:requestSavePlayerData()
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
        self.log:debug("Requesting save player data")
    
    self:CallServer(Protocol.ClientMSGID.PLAYER_SAVE_DATA_REQ, {})
    
    return true
end

-- ========================================
-- 网络响应处理
-- ========================================

function PlayerSystemClient:onCreateCharacterResponse(data)
    if data.success then
        self.log:info("Character created successfully")
        self.data.localPlayerData = data.playerData
        
        -- 触发事件
        local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
        self.events:emit(EventID.PlayerDataUpdated, {playerData = data.playerData})
    else
        self.log:error("Failed to create character")
    end
end

function PlayerSystemClient:onGetPlayerDataResponse(data)
    if data.success then
        self.log:debug("Player data received")
        self.data.localPlayerData = data.playerData
        
        -- 触发事件
        local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
        self.events:emit(EventID.PlayerDataUpdated, {playerData = data.playerData})
    else
        self.log:error("Failed to get player data")
    end
end

function PlayerSystemClient:onPlayerDataUpdate(data)
    self.log:debug("Player data updated")
    self.data.localPlayerData = data.playerData
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerDataUpdated, {playerData = data.playerData})
end

function PlayerSystemClient:onPlayerHealthUpdate(data)
    if not self.data.localPlayerData then return end
    
    self.data.localPlayerData.stats.currentHp = data.currentHp
    self.data.localPlayerData.stats.maxHp = data.maxHp
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerHealthUpdated, {
        currentHp = data.currentHp,
        maxHp = data.maxHp
    })
end

function PlayerSystemClient:onPlayerManaUpdate(data)
    if not self.data.localPlayerData then return end
    
    self.data.localPlayerData.stats.currentMp = data.currentMp
    self.data.localPlayerData.stats.maxMp = data.maxMp
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerManaUpdated, {
        currentMp = data.currentMp,
        maxMp = data.maxMp
    })
end

function PlayerSystemClient:onPlayerExpUpdate(data)
    if not self.data.localPlayerData then return end
    
    self.data.localPlayerData.exp = data.exp
    self.data.localPlayerData.level = data.level
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerExpUpdated, {
        exp = data.exp,
        level = data.level
    })
end

function PlayerSystemClient:onPlayerLevelUp(data)
    if not self.data.localPlayerData then return end
    
    self.data.localPlayerData.level = data.level
    self.data.localPlayerData.stats = data.stats
    
    self.log:info("Player leveled up to " .. data.level)
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerLevelUp, {
        level = data.level,
        stats = data.stats
    })
end

-- ========================================
-- 公共API
-- ========================================

function PlayerSystemClient:getLocalPlayerData()
    return self.data.localPlayerData
end

function PlayerSystemClient:getPlayerLevel()
    return self.data.localPlayerData and self.data.localPlayerData.level or 0
end

function PlayerSystemClient:getPlayerHealth()
    if not self.data.localPlayerData then return 0, 0 end
    return self.data.localPlayerData.stats.currentHp, self.data.localPlayerData.stats.maxHp
end

function PlayerSystemClient:getPlayerMana()
    if not self.data.localPlayerData then return 0, 0 end
    return self.data.localPlayerData.stats.currentMp, self.data.localPlayerData.stats.maxMp
end

return PlayerSystemClient

