--[[
    CombatSystemServer.lua - 战斗系统（服务端）
    
    职责：
    1. 管理战斗流程（回合制）
    2. 处理战斗行动（攻击、技能、道具、逃跑）
    3. 计算伤害和效果
    4. 管理战斗AI
    
    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local CombatSystemServer = {
    name = "CombatSystemServer",
    version = "1.0.0",
    description = "战斗系统（服务端）",
    dependencies = {"PlayerSystemServer"},
    state = "uninitialized",
    sgf = nil,
    log = nil,
    events = nil,
    config = {},
    data = {
        activeCombats = {},  -- [combatId] = CombatData
    },
    dependencies_cache = {},
}

function CombatSystemServer.new(sgf)
    local self = setmetatable({}, {__index = CombatSystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    self.data = {activeCombats = {}}
    self.dependencies_cache = {}
    return self
end

function CombatSystemServer:PreInit()
    self.log:info("CombatSystemServer PreInit...")
    self:registerEventListeners()
    return true
end

function CombatSystemServer:Init()
    if self.state ~= "uninitialized" then
        return false
    end
    self.log:info("CombatSystemServer Init...")
    self:registerNetworkHandlers()
    self.state = "initialized"
    return true
end

function CombatSystemServer:PostInit()
    self.log:info("CombatSystemServer PostInit...")
    self:resolveDependencies()
    return true
end

function CombatSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("CombatSystemServer Start...")
    self.state = "started"
    return true
end

function CombatSystemServer:Update(dt)
    -- 更新所有战斗状态
    for combatId, combat in pairs(self.data.activeCombats) do
        self:updateCombat(combat, dt)
    end
end

function CombatSystemServer:Stop()
    self.log:info("CombatSystemServer Stop...")
    self.state = "stopped"
    return true
end

function CombatSystemServer:registerEventListeners()
    self.log:debug("CombatSystemServer event listeners registered")
end

function CombatSystemServer:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
    end
end

function CombatSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    if not NetworkHelper then
        self.log:error("NetworkHelper not found")
        return
    end
    
    -- 开始战斗
    self:OnRequest(Protocol.ClientMSGID.COMBAT_START_REQ, function(userId, msgid, data)
        return self:handleStartCombat(player, data)
    end)
    
    -- 战斗行动
    self:OnRequest(Protocol.ClientMSGID.COMBAT_ACTION_REQ, function(userId, msgid, data)
        return self:handleCombatAction(player, data)
    end)
    
    self.log:debug("CombatSystemServer network handlers registered")
end

-- 开始战斗
function CombatSystemServer:handleStartCombat(player, data)
    local playerId = player.UserId
    local enemyId = data.enemyId or "Slime"
    
    self.log:info("Starting combat for player: " .. playerId .. " vs " .. enemyId)
    
    -- 创建战斗数据
    local combatId = "combat_" .. playerId .. "_" .. os.time()
    local combatData = self:createCombatData(combatId, playerId, enemyId)
    self.data.activeCombats[combatId] = combatData
    
    -- 发送响应
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    NetworkHelper:sendToClient(player, Protocol.ServerMSGID.COMBAT_START_RSP, {
        success = true,
        combatId = combatId,
        combatData = combatData
    })
    
    -- 触发事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.CombatStarted, {combatId = combatId, playerId = playerId})
    
    return true
end

-- 处理战斗行动
function CombatSystemServer:handleCombatAction(player, data)
    local playerId = player.UserId
    local combatId = data.combatId
    local actionType = data.actionType  -- "attack", "skill", "item", "flee"
    
    local combat = self.data.activeCombats[combatId]
    if not combat then
        self.log:error("Combat not found: " .. combatId)
        return false
    end
    
    self.log:info("Combat action: " .. actionType .. " by player: " .. playerId)
    
    -- 执行玩家行动
    local result = self:executeAction(combat, "player", actionType, data)
    
    -- 发送响应
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    
    NetworkHelper:sendToClient(player, Protocol.ServerMSGID.COMBAT_ACTION_RSP, {
        success = true,
        result = result
    })
    
    -- 检查战斗是否结束
    if combat.enemy.currentHp <= 0 then
        self:endCombat(combat, "victory")
    elseif combat.player.currentHp <= 0 then
        self:endCombat(combat, "defeat")
    else
        -- 敌人回合
        self:enemyTurn(combat)
    end
    
    return true
end

-- 创建战斗数据
function CombatSystemServer:createCombatData(combatId, playerId, enemyId)
    local playerSystem = self.dependencies_cache.PlayerSystem
    local playerData = playerSystem:getPlayerData(playerId)
    
    -- 简化的敌人数据
    local enemyData = {
        id = enemyId,
        name = enemyId,
        level = playerData.level,
        maxHp = 50 + playerData.level * 10,
        currentHp = 50 + playerData.level * 10,
        attack = 10 + playerData.level * 2,
        defense = 5 + playerData.level,
        speed = 8
    }
    
    return {
        combatId = combatId,
        playerId = playerId,
        player = {
            currentHp = playerData.stats.currentHp,
            maxHp = playerData.stats.maxHp,
            currentMp = playerData.stats.currentMp,
            maxMp = playerData.stats.maxMp,
            attack = playerData.stats.attack,
            defense = playerData.stats.defense,
            speed = playerData.stats.speed
        },
        enemy = enemyData,
        turn = 1,
        currentActor = "player",
        status = "active"
    }
end

-- 执行行动
function CombatSystemServer:executeAction(combat, actor, actionType, data)
    if actionType == "attack" then
        return self:executeAttack(combat, actor)
    elseif actionType == "flee" then
        return self:executeFlee(combat)
    end
    
    return {success = false, message = "Unknown action"}
end

-- 执行攻击
function CombatSystemServer:executeAttack(combat, actor)
    local attacker, defender
    
    if actor == "player" then
        attacker = combat.player
        defender = combat.enemy
    else
        attacker = combat.enemy
        defender = combat.player
    end
    
    -- 简单的伤害计算
    local damage = math.max(1, attacker.attack - defender.defense)
    defender.currentHp = math.max(0, defender.currentHp - damage)
    
    self.log:debug(actor .. " attacks for " .. damage .. " damage")
    
    -- 通知客户端
    self:notifyDamage(combat, actor, damage)
    
    return {
        success = true,
        damage = damage,
        targetHp = defender.currentHp
    }
end

-- 执行逃跑
function CombatSystemServer:executeFlee(combat)
    -- 50%逃跑成功率
    local success = math.random() > 0.5
    
    if success then
        self:endCombat(combat, "fled")
    end
    
    return {success = success}
end

-- 敌人回合
function CombatSystemServer:enemyTurn(combat)
    -- 简单AI：总是攻击
    self:executeAttack(combat, "enemy")
end

-- 结束战斗
function CombatSystemServer:endCombat(combat, result)
    self.log:info("Combat ended: " .. result)
    
    combat.status = "ended"
    combat.result = result
    
    -- 计算奖励
    if result == "victory" then
        local expReward = 50 + combat.enemy.level * 10
        local goldReward = 20 + combat.enemy.level * 5
        
        -- 给予奖励
        local playerSystem = self.dependencies_cache.PlayerSystem
        playerSystem:addExp(combat.playerId, expReward)
        
        self.log:info("Player gained " .. expReward .. " exp and " .. goldReward .. " gold")
    end
    
    -- 通知客户端
    self:notifyCombatEnd(combat, result)
    
    -- 清理战斗数据
    self.data.activeCombats[combat.combatId] = nil
end

-- 更新战斗
function CombatSystemServer:updateCombat(combat, dt)
    -- 战斗更新逻辑（如果需要）
end

-- 通知伤害
function CombatSystemServer:notifyDamage(combat, actor, damage)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(combat.playerId)
    
    if player and NetworkHelper then
        NetworkHelper:sendToClient(player, Protocol.ServerMSGID.COMBAT_DAMAGE_NOTIFY, {
            actor = actor,
            damage = damage,
            playerHp = combat.player.currentHp,
            enemyHp = combat.enemy.currentHp
        })
    end
end

-- 通知战斗结束
function CombatSystemServer:notifyCombatEnd(combat, result)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(combat.playerId)
    
    if player and NetworkHelper then
        local msgId = result == "victory" and Protocol.ServerMSGID.COMBAT_VICTORY_NOTIFY or Protocol.ServerMSGID.COMBAT_DEFEAT_NOTIFY
        NetworkHelper:sendToClient(player, msgId, {
            combatId = combat.combatId,
            result = result
        })
    end
    
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.CombatEnded, {combatId = combat.combatId, result = result})
end

return CombatSystemServer

