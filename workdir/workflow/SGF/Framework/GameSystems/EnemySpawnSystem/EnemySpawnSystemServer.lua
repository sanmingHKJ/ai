--[[
    EnemySpawnSystemServer.lua - 敌人生成系统（服务端）

    职责：
    1. 管理敌人刷新点
    2. 根据配置生成敌人
    3. 处理敌人重生逻辑
    4. 管理敌人实例

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local EnemySpawnSystemServer = {
    name = "EnemySpawnSystemServer",
    version = "1.0.0",
    description = "敌人生成系统（服务端）",
    dependencies = {"SceneSystemServer"},
    state = "uninitialized",
    sgf = nil,
    log = nil,
    events = nil,
    config = {},
    data = {
        spawnedEnemies = {},      -- [enemyId] = {config, object, spawnPoint}
        spawnTimers = {},         -- [spawnPointName] = {timer, nextSpawnTime}
        enemyCounter = 0,         -- 敌人ID计数器
    },
    dependencies_cache = {},
}

function EnemySpawnSystemServer.new(sgf)
    local self = setmetatable({}, {__index = EnemySpawnSystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    self.data = {
        spawnedEnemies = {},
        spawnTimers = {},
        enemyCounter = 0,
    }
    self.dependencies_cache = {}
    return self
end

function EnemySpawnSystemServer:PreInit()
    self.log:info("EnemySpawnSystemServer PreInit...")
    self:registerEventListeners()
    return true
end

function EnemySpawnSystemServer:Init()
    if self.state ~= "uninitialized" then
        return false
    end
    self.log:info("EnemySpawnSystemServer Init...")

    -- 加载地图配置
    self.config.MapConfig = require(script.Parent.Parent.Parent.Config.Framework.MapConfig)

    self.state = "initialized"
    return true
end

function EnemySpawnSystemServer:PostInit()
    self.log:info("EnemySpawnSystemServer PostInit...")
    self:resolveDependencies()
    return true
end

function EnemySpawnSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("EnemySpawnSystemServer Start...")

    -- 初始化所有刷新点
    self:initializeAllSpawnPoints()

    self.state = "started"
    return true
end

function EnemySpawnSystemServer:Update(dt)
    -- 更新刷新计时器
    self:updateSpawnTimers(dt)
end

function EnemySpawnSystemServer:Stop()
    self.log:info("EnemySpawnSystemServer Stop...")

    -- 清理所有敌人
    for enemyId, _ in pairs(self.data.spawnedEnemies) do
        self:despawnEnemy(enemyId)
    end

    self.state = "stopped"
    return true
end

function EnemySpawnSystemServer:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听敌人死亡事件
    self.events:on(EventID.EnemyKilled, function(data)
        self:onEnemyKilled(data.enemyId, data.spawnPointName)
    end)

    -- 监听场景切换事件
    self.events:on(EventID.SceneChanged, function(data)
        self:onSceneChanged(data)
    end)

    self.log:debug("EnemySpawnSystemServer event listeners registered")
end

function EnemySpawnSystemServer:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.SceneSystem = self.sgf.businessSystemManager:get("SceneSystemServer")
    end
end

--[==[
    初始化所有刷新点
]==]
function EnemySpawnSystemServer:initializeAllSpawnPoints()
    self.log:info("Initializing enemy spawn points...")

    -- 初始化森林战场的刷新点
    local forestSpawns = self.config.MapConfig.EnemySpawns[self.config.MapConfig.ScenesTypeID.ForestBattle]
    if forestSpawns then
        for _, spawnConfig in ipairs(forestSpawns) do
            self:initializeSpawnPoint("ForestBattle", spawnConfig)
        end
    end

    self.log:info("Enemy spawn points initialized")
end

--[==[
    初始化单个刷新点
]==]
function EnemySpawnSystemServer:initializeSpawnPoint(sceneName, spawnConfig)
    local spawnName = spawnConfig.name

    self.log:info("Initializing spawn point: " .. spawnName)

    -- 初始刷新一个敌人
    self:spawnEnemyAtPoint(sceneName, spawnConfig)

    -- 设置刷新计时器
    self.data.spawnTimers[spawnName] = {
        timer = 0,
        nextSpawnTime = spawnConfig.respawnTime or 60,
        sceneName = sceneName,
        config = spawnConfig,
    }
end

--[==[
    在刷新点生成敌人
]==]
function EnemySpawnSystemServer:spawnEnemyAtPoint(sceneName, spawnConfig)
    local spawnName = spawnConfig.name

    -- 检查是否已有敌人在此刷新点
    for _, enemyData in pairs(self.data.spawnedEnemies) do
        if enemyData.spawnPoint == spawnName then
            self.log:debug("Enemy already exists at " .. spawnName)
            return nil
        end
    end

    -- 随机选择敌人类型
    local enemyTypes = spawnConfig.types
    if not enemyTypes or #enemyTypes == 0 then
        self.log:error("No enemy types configured for " .. spawnName)
        return nil
    end

    local randomIndex = math.random(1, #enemyTypes)
    local enemyType = enemyTypes[randomIndex]

    -- 随机选择等级
    local levelRange = spawnConfig.levelRange
    local enemyLevel = math.random(levelRange.min, levelRange.max)

    -- 生成敌人ID
    self.data.enemyCounter = self.data.enemyCounter + 1
    local enemyId = "enemy_" .. self.data.enemyCounter

    -- 创建敌人数据
    local enemyData = {
        id = enemyId,
        type = enemyType,
        level = enemyLevel,
        spawnPoint = spawnName,
        sceneName = sceneName,
        position = spawnConfig.pos,
        hp = 50 + enemyLevel * 10,  -- 简单的血量计算
        maxHp = 50 + enemyLevel * 10,
        attack = 10 + enemyLevel * 2,
        defense = 5 + enemyLevel,
    }

    -- 保存敌人数据
    self.data.spawnedEnemies[enemyId] = enemyData

    self.log:info("Spawned " .. enemyType .. " (Lv." .. enemyLevel .. ") at " .. spawnName)

    -- 触发敌人生成事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.EnemySpawned, {
        enemyId = enemyId,
        enemyData = enemyData,
    })

    return enemyId
end

--[==[
    更新刷新计时器
]==]
function EnemySpawnSystemServer:updateSpawnTimers(dt)
    for spawnName, timerData in pairs(self.data.spawnTimers) do
        timerData.timer = timerData.timer + dt

        -- 检查是否到达刷新时间
        if timerData.timer >= timerData.nextSpawnTime then
            -- 尝试刷新敌人
            self:spawnEnemyAtPoint(timerData.sceneName, timerData.config)

            -- 重置计时器
            timerData.timer = 0
        end
    end
end

--[==[
    敌人被击杀
]==]
function EnemySpawnSystemServer:onEnemyKilled(enemyId, spawnPointName)
    self.log:info("Enemy " .. enemyId .. " killed at " .. (spawnPointName or "unknown"))

    -- 移除敌人数据
    local enemyData = self.data.spawnedEnemies[enemyId]
    if enemyData then
        -- 计算掉落奖励
        self:calculateDrops(enemyData)

        -- 重置对应刷新点的计时器
        if enemyData.spawnPoint and self.data.spawnTimers[enemyData.spawnPoint] then
            self.data.spawnTimers[enemyData.spawnPoint].timer = 0
        end

        -- 清除敌人
        self.data.spawnedEnemies[enemyId] = nil

        self.log:info("Enemy removed: " .. enemyId)
    end
end

--[==[
    计算掉落
]==]
function EnemySpawnSystemServer:calculateDrops(enemyData)
    -- 这里可以实现掉落逻辑
    -- 例如：金币、经验、物品等

    local expReward = enemyData.level * 10
    local goldReward = enemyData.level * 5

    self.log:info("Drop rewards: " .. expReward .. " EXP, " .. goldReward .. " Gold")

    -- 触发掉落事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.EnemyDrops, {
        enemyId = enemyData.id,
        exp = expReward,
        gold = goldReward,
        items = {},  -- 物品掉落
    })
end

--[==[
    场景切换事件处理
]==]
function EnemySpawnSystemServer:onSceneChanged(data)
    -- 当玩家进入战斗场景时，可以触发特殊逻辑
    local toScene = data.toScene

    if toScene == self.config.MapConfig.ScenesTypeID.ForestBattle then
        self.log:info("Player entered ForestBattle, ensuring enemies are spawned")
        -- 确保森林战场有敌人
    end
end

--[==[
    移除敌人
]==]
function EnemySpawnSystemServer:despawnEnemy(enemyId)
    local enemyData = self.data.spawnedEnemies[enemyId]
    if enemyData then
        self.data.spawnedEnemies[enemyId] = nil
        self.log:info("Despawned enemy: " .. enemyId)

        -- 触发敌人移除事件
        local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
        self.events:emit(EventID.EnemyDespawned, {
            enemyId = enemyId,
        })
    end
end

--[==[
    获取所有已生成的敌人
]==]
function EnemySpawnSystemServer:getAllEnemies()
    return self.data.spawnedEnemies
end

--[==[
    获取指定场景的敌人
]==]
function EnemySpawnSystemServer:getEnemiesInScene(sceneName)
    local enemies = {}
    for enemyId, enemyData in pairs(self.data.spawnedEnemies) do
        if enemyData.sceneName == sceneName then
            enemies[enemyId] = enemyData
        end
    end
    return enemies
end

--[==[
    获取敌人数据
]==]
function EnemySpawnSystemServer:getEnemyData(enemyId)
    return self.data.spawnedEnemies[enemyId]
end

--[==[
    手动在刷新点生成敌人（用于测试）
]==]
function EnemySpawnSystemServer:forceSpawn(sceneName, spawnName)
    local spawns = self.config.MapConfig.EnemySpawns[self.config.MapConfig.ScenesTypeID[sceneName]]
    if spawns then
        for _, spawnConfig in ipairs(spawns) do
            if spawnConfig.name == spawnName then
                return self:spawnEnemyAtPoint(sceneName, spawnConfig)
            end
        end
    end
    return nil
end

return EnemySpawnSystemServer
