--[[
    LevelSystemServer.lua - 等级系统（服务端）
    
    职责：
    1. 管理等级和经验值计算
    2. 处理升级逻辑
    3. 计算属性成长
    
    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local LevelSystemServer = {
    name = "LevelSystemServer",
    version = "1.0.0",
    description = "等级系统（服务端）",
    dependencies = {},
    state = "uninitialized",
    sgf = nil,
    log = nil,
    events = nil,
    config = {
        maxLevel = 50,
        baseExpPerLevel = 100,
        expGrowthRate = 1.5,
    },
    data = {},
    dependencies_cache = {},
}

function LevelSystemServer.new(sgf)
    local self = setmetatable({}, {__index = LevelSystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    self.data = {}
    self.dependencies_cache = {}
    return self
end

function LevelSystemServer:PreInit()
    self.log:info("LevelSystemServer PreInit...")
    return true
end

function LevelSystemServer:Init()
    if self.state ~= "uninitialized" then
        return false
    end
    self.log:info("LevelSystemServer Init...")
    self.state = "initialized"
    return true
end

function LevelSystemServer:PostInit()
    self.log:info("LevelSystemServer PostInit...")
    return true
end

function LevelSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("LevelSystemServer Start...")
    self.state = "started"
    return true
end

function LevelSystemServer:Update(dt)
end

function LevelSystemServer:Stop()
    self.log:info("LevelSystemServer Stop...")
    self.state = "stopped"
    return true
end

-- 计算升级所需经验
function LevelSystemServer:getExpForLevel(level)
    return math.floor(self.config.baseExpPerLevel * math.pow(self.config.expGrowthRate, level - 1))
end

-- 检查是否可以升级
function LevelSystemServer:checkLevelUp(playerId, currentExp)
    local playerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
    if not playerSystem then return false end
    
    local playerData = playerSystem:getPlayerData(playerId)
    if not playerData then return false end
    
    local requiredExp = self:getExpForLevel(playerData.level + 1)
    return currentExp >= requiredExp
end

return LevelSystemServer

