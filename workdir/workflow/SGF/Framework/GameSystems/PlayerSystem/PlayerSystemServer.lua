--[[
    PlayerSystemServer.lua - 玩家系统（服务端）
    
    职责：
    1. 管理玩家基础数据（等级、经验、属性）
    2. 处理玩家创建、登录、登出
    3. 管理玩家状态（生命值、魔法值）
    4. 处理玩家升级逻辑
    5. 验证客户端请求
    
    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local PlayerSystemServer = {
    -- ========== 基础信息 ==========
    name = "PlayerSystemServer",
    version = "1.0.0",
    description = "玩家系统（服务端）",
    
    -- ========== 依赖声明 ==========
    dependencies = {
        "LevelSystemServer",
    },
    
    -- ========== 状态管理 ==========
    state = "uninitialized",
    
    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,
    
    -- ========== 配置 ==========
    config = {
        maxPlayers = 50,
        saveInterval = 60,  -- 自动保存间隔（秒）
    },
    
    -- ========== 数据 ==========
    data = {
        players = {},  -- [playerId] = PlayerData
    },
    
    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

--[[
    创建新实例
]]
function PlayerSystemServer.new(sgf)
    local self = setmetatable({}, {__index = PlayerSystemServer})
    
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    
    self.data = {
        players = {}
    }
    self.dependencies_cache = {}
    
    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function PlayerSystemServer:PreInit()
    self.log:info("PlayerSystemServer PreInit...")
    
    -- 注册事件监听器
    self:registerEventListeners()
    
    return true
end

function PlayerSystemServer:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("PlayerSystemServer already initialized")
        return false
    end
    
    self.log:info("PlayerSystemServer Init...")
    
    -- 加载配置
    self:loadConfig()
    
    -- 注册网络消息处理
    self:registerNetworkHandlers()
    
    self.state = "initialized"
    return true
end

function PlayerSystemServer:PostInit()
    self.log:info("PlayerSystemServer PostInit...")
    
    -- 获取依赖的其他系统
    self:resolveDependencies()
    
    return true
end

function PlayerSystemServer:Start()
    if self.state ~= "initialized" then
        self.log:error("PlayerSystemServer cannot start, state: " .. self.state)
        return false
    end
    
    self.log:info("PlayerSystemServer Start...")
    
    -- 启动自动保存定时器
    self:startAutoSave()
    
    self.state = "started"
    self.events:emit("PlayerSystemStarted", {timestamp = os.time()})
    
    return true
end

function PlayerSystemServer:Update(dt)
    -- 每帧更新逻辑（如果需要）
end

function PlayerSystemServer:Stop()
    self.log:info("PlayerSystemServer Stop...")
    
    -- 保存所有玩家数据
    self:saveAllPlayers()
    
    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function PlayerSystemServer:loadConfig()
    -- 从配置服务加载配置（如果有）
    self.log:debug("PlayerSystemServer config loaded")
end

function PlayerSystemServer:resolveDependencies()
    -- 获取LevelSystem引用
    if self.sgf.businessSystemManager then
        self.dependencies_cache.LevelSystem = self.sgf.businessSystemManager:get("LevelSystemServer")
        if self.dependencies_cache.LevelSystem then
            self.log:debug("PlayerSystemServer resolved dependency: LevelSystemServer")
        end
    end
end

-- ========================================
-- 事件监听
-- ========================================

function PlayerSystemServer:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    
    -- 监听玩家加入事件
    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)
    
    -- 监听玩家离开事件
    self.events:on(EventID.PlayerLeft, function(data)
        self:onPlayerLeft(data)
    end)
    
    self.log:debug("PlayerSystemServer event listeners registered")
end

-- ========================================
-- 网络消息处理
-- ========================================

function PlayerSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    if not NetworkHelper then
        self.log:error("NetworkHelper not found")
        return
    end
    
    -- 创建角色
    self:OnRequest(Protocol.ClientMSGID.PLAYER_CREATE_CHARACTER_REQ, function(userId, msgid, data)
        return self:handleCreateCharacter(userId, data)
    end)
    
    -- 获取玩家数据
    self:OnRequest(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, function(userId, msgid, data)
        return self:handleGetPlayerData(userId, data)
    end)
    
    -- 保存玩家数据
    self:OnRequest(Protocol.ClientMSGID.PLAYER_SAVE_DATA_REQ, function(userId, msgid, data)
        return self:handleSavePlayerData(userId, data)
    end)
    
    self.log:debug("PlayerSystemServer network handlers registered")
end

-- ========================================
-- 网络消息处理器
-- ========================================

function PlayerSystemServer:handleCreateCharacter(userId, data)
    local playerId = userId
    local characterName = data.characterName
    local classType = data.classType  -- "Warrior", "Mage", "Assassin"
    
    self.log:info("Creating character for player: " .. playerId .. ", class: " .. classType)
    
    -- 创建玩家数据
    local playerData = self:createPlayerData(playerId, characterName, classType)
    self.data.players[playerId] = playerData
    
    -- 发送响应
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_CREATE_CHARACTER_RSP, {
        success = true,
        playerData = playerData
    })
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerDataUpdated, {playerId = playerId, playerData = playerData})
    
    return true
end

function PlayerSystemServer:handleGetPlayerData(userId, data)
    local playerId = userId
    local playerData = self.data.players[playerId]
    
    if not playerData then
        -- 如果没有数据，创建默认数据
        playerData = self:loadPlayerData(playerId)
        self.data.players[playerId] = playerData
    end
    
    -- 发送响应
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_GET_DATA_RSP, {
        success = true,
        playerData = playerData
    })
    
    return true
end

function PlayerSystemServer:handleSavePlayerData(userId, data)
    local playerId = userId
    
    -- 保存玩家数据
    local success = self:savePlayerData(playerId)
    
    -- 发送响应
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_SAVE_DATA_RSP, {
        success = success
    })
    
    return true
end

-- ========================================
-- 事件处理器
-- ========================================

function PlayerSystemServer:onPlayerJoined(data)
    local playerId = data.playerId
    self.log:info("Player joined: " .. playerId)
    
    -- 加载玩家数据
    local playerData = self:loadPlayerData(playerId)
    self.data.players[playerId] = playerData
    
    -- 通知客户端
    self:notifyPlayerDataUpdate(playerId)
end

function PlayerSystemServer:onPlayerLeft(data)
    local playerId = data.playerId
    self.log:info("Player left: " .. playerId)
    
    -- 保存玩家数据
    self:savePlayerData(playerId)
    
    -- 清理内存
    self.data.players[playerId] = nil
end

-- ========================================
-- 核心业务逻辑
-- ========================================

function PlayerSystemServer:createPlayerData(playerId, characterName, classType)
    -- 根据DATA_STRUCTURES.md定义创建玩家数据
    local classConfigs = {
        Warrior = {hp = 150, mp = 50, atk = 15, def = 12, spd = 8},
        Mage = {hp = 80, mp = 150, atk = 20, def = 6, spd = 10},
        Assassin = {hp = 100, mp = 80, atk = 18, def = 8, spd = 15}
    }
    
    local config = classConfigs[classType] or classConfigs.Warrior
    
    return {
        playerId = playerId,
        characterName = characterName,
        classType = classType,
        level = 1,
        exp = 0,
        gold = 100,
        stats = {
            maxHp = config.hp,
            currentHp = config.hp,
            maxMp = config.mp,
            currentMp = config.mp,
            attack = config.atk,
            defense = config.def,
            speed = config.spd
        },
        position = {x = 0, y = 0, z = 0},
        sceneId = "MainCity",
        combatState = "idle"
    }
end

function PlayerSystemServer:loadPlayerData(playerId)
    -- 从数据存储加载玩家数据
    -- 这里简化处理，实际应该从MiniWorld Studio的数据存储服务加载
    self.log:debug("Loading player data: " .. playerId)

    -- 如果没有数据，返回nil（需要创建角色）
    return nil
end

function PlayerSystemServer:savePlayerData(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then
        self.log:warning("No player data to save: " .. playerId)
        return false
    end

    -- 保存到数据存储
    -- 这里简化处理，实际应该保存到MiniWorld Studio的数据存储服务
    self.log:debug("Saving player data: " .. playerId)

    return true
end

function PlayerSystemServer:saveAllPlayers()
    self.log:info("Saving all player data...")

    for playerId, _ in pairs(self.data.players) do
        self:savePlayerData(playerId)
    end
end

function PlayerSystemServer:startAutoSave()
    -- 启动自动保存定时器
    -- 这里简化处理，实际应该使用定时器服务
    self.log:debug("Auto-save started")
end

-- ========================================
-- 玩家属性操作
-- ========================================

function PlayerSystemServer:updatePlayerHealth(playerId, delta)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.stats.currentHp = math.max(0, math.min(
        playerData.stats.maxHp,
        playerData.stats.currentHp + delta
    ))

    -- 通知客户端
    self:notifyPlayerHealthUpdate(playerId)

    -- 检查死亡
    if playerData.stats.currentHp <= 0 then
        self:onPlayerDied(playerId)
    end

    return true
end

function PlayerSystemServer:updatePlayerMana(playerId, delta)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.stats.currentMp = math.max(0, math.min(
        playerData.stats.maxMp,
        playerData.stats.currentMp + delta
    ))

    -- 通知客户端
    self:notifyPlayerManaUpdate(playerId)

    return true
end

function PlayerSystemServer:addExp(playerId, exp)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.exp = playerData.exp + exp

    -- 通知客户端
    self:notifyPlayerExpUpdate(playerId)

    -- 检查升级
    if self.dependencies_cache.LevelSystem then
        local levelSystem = self.dependencies_cache.LevelSystem
        if levelSystem:checkLevelUp(playerId, playerData.exp) then
            self:levelUp(playerId)
        end
    end

    return true
end

function PlayerSystemServer:levelUp(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.level = playerData.level + 1

    -- 提升属性
    local growthRate = 1.1
    playerData.stats.maxHp = math.floor(playerData.stats.maxHp * growthRate)
    playerData.stats.maxMp = math.floor(playerData.stats.maxMp * growthRate)
    playerData.stats.attack = math.floor(playerData.stats.attack * growthRate)
    playerData.stats.defense = math.floor(playerData.stats.defense * growthRate)
    playerData.stats.speed = math.floor(playerData.stats.speed * growthRate)

    -- 恢复生命和魔法
    playerData.stats.currentHp = playerData.stats.maxHp
    playerData.stats.currentMp = playerData.stats.maxMp

    self.log:info("Player " .. playerId .. " leveled up to " .. playerData.level)

    -- 通知客户端
    self:notifyPlayerLevelUp(playerId)

    return true
end

function PlayerSystemServer:onPlayerDied(playerId)
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerDied, {playerId = playerId})

    self.log:info("Player died: " .. playerId)
end

-- ========================================
-- 网络通知
-- ========================================

function PlayerSystemServer:notifyPlayerDataUpdate(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)

    if player and NetworkHelper then
        self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_DATA_UPDATE_NOTIFY, {
            playerData = playerData
        })
    end
end

function PlayerSystemServer:notifyPlayerHealthUpdate(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)

    if player and NetworkHelper then
        self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_HEALTH_UPDATE_NOTIFY, {
            currentHp = playerData.stats.currentHp,
            maxHp = playerData.stats.maxHp
        })
    end
end

function PlayerSystemServer:notifyPlayerManaUpdate(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)

    if player and NetworkHelper then
        self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_MANA_UPDATE_NOTIFY, {
            currentMp = playerData.stats.currentMp,
            maxMp = playerData.stats.maxMp
        })
    end
end

function PlayerSystemServer:notifyPlayerExpUpdate(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)

    if player and NetworkHelper then
        self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_EXP_UPDATE_NOTIFY, {
            exp = playerData.exp,
            level = playerData.level
        })
    end
end

function PlayerSystemServer:notifyPlayerLevelUp(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)

    if player and NetworkHelper then
        self:CallClient(playerId, Protocol.ServerMSGID.PLAYER_LEVEL_UP_RSP, {
            level = playerData.level,
            stats = playerData.stats
        })
    end

    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerLevelUp, {playerId = playerId, level = playerData.level})
end

-- ========================================
-- 公共API
-- ========================================

function PlayerSystemServer:getPlayerData(playerId)
    return self.data.players[playerId]
end

function PlayerSystemServer:isPlayerAlive(playerId)
    local playerData = self.data.players[playerId]
    return playerData and playerData.stats.currentHp > 0
end

return PlayerSystemServer


