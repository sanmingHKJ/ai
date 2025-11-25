--[[
    ServerMain.lua - Server Entry Template
    服务端主入口文件模板

    按照SGF标准化开发框架规范开发

    使用说明：
    1. 将此文件复制到 ServerScriptService/ 目录
    2. 修改项目名称和描述
    3. 根据需要加载和注册服务端业务系统
    4. 根据需要处理玩家加入/离开事件
    5. 根据需要监听游戏事件

    Version: 1.0.0
]]

print("========================================")
print("[YourGame] Server Starting...")
print("========================================")

-- 环境检查
local RunService = game:GetService("RunService")
if not RunService:IsServer() then
    error("This script should only run on server")
    return
end

local MainStorage = game:GetService("MainStorage")
local Players = game:GetService("Players")

-- 加载SGF框架
local Framework = MainStorage:WaitForChild("Framework")
local SGFFramework = require(Framework:WaitForChild("SGFFramework"))

-- 创建框架实例
local sgf = SGFFramework.new()

print("[ServerMain] Initializing SGF Framework...")

-- 初始化框架
local success = sgf:Init({
    systems = {
        -- 服务端业务系统将在这里注册
        -- 示例：
        -- "PlayerSystemServer",
        -- "CombatSystemServer",
        -- "SkillSystemServer",
        -- "InventorySystemServer",
        -- "QuestSystemServer",
        -- "LevelSystemServer",
    }
})

if not success then
    error("[ServerMain] Failed to initialize SGF framework")
    return
end

-- ========================================
-- 加载业务系统（服务端）
-- ========================================
print("[ServerMain] Loading server systems...")

-- 示例：加载服务端业务系统
-- local PlayerSystemServer = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemServer)
-- local CombatSystemServer = require(MainStorage.Framework.GameSystems.CombatSystem.CombatSystemServer)
-- local LevelSystemServer = require(MainStorage.Framework.GameSystems.LevelSystem.LevelSystemServer)

-- 示例：创建系统实例
-- local playerSystem = PlayerSystemServer.new(sgf)
-- local combatSystem = CombatSystemServer.new(sgf)
-- local levelSystem = LevelSystemServer.new(sgf)

-- 示例：注册系统到框架
-- sgf.businessSystemManager:registerSystem("PlayerSystemServer", playerSystem)
-- sgf.businessSystemManager:registerSystem("CombatSystemServer", combatSystem)
-- sgf.businessSystemManager:registerSystem("LevelSystemServer", levelSystem)

-- 示例：初始化系统（PreInit -> Init -> PostInit -> Start）
print("[ServerMain] Initializing game systems...")

-- PreInit（注册事件监听器）
-- playerSystem:PreInit()
-- combatSystem:PreInit()
-- levelSystem:PreInit()

-- Init（加载配置、初始化数据）
-- playerSystem:Init()
-- combatSystem:Init()
-- levelSystem:Init()

-- PostInit（解析依赖、注册3D交互）
-- playerSystem:PostInit()
-- combatSystem:PostInit()
-- levelSystem:PostInit()

-- Start（启动逻辑）
print("[ServerMain] Starting game systems...")
-- playerSystem:Start()
-- combatSystem:Start()
-- levelSystem:Start()

-- ========================================
-- 注册玩家事件
-- ========================================
Players.PlayerAdded:Connect(function(player)
    print("[ServerMain] Player joined:", player.Name, player.UserId)

    -- 发送玩家加入事件
    sgf.events:emit("PlayerJoined", {
        playerId = player.UserId,
        playerName = player.Name
    })

    -- 示例：初始化玩家数据
    -- playerSystem:OnPlayerJoined(player.UserId, player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
    print("[ServerMain] Player left:", player.Name, player.UserId)

    -- 发送玩家离开事件
    sgf.events:emit("PlayerLeft", {
        playerId = player.UserId
    })

    -- 示例：保存玩家数据
    -- playerSystem:OnPlayerLeft(player.UserId)
end)

-- ========================================
-- 服务端主循环（物理循环）
-- ========================================
-- 注意：迷你世界Studio使用 RunService.Stepped 而不是 Heartbeat
RunService.Stepped:Connect(function()
    -- Stepped 不提供 deltaTime 参数，需要使用固定时间步长
    local dt = 0.033  -- 固定时间步长，约30FPS

    -- 使用 SGF 框架的统一更新方法
    -- 框架会自动调用所有注册系统的 Update 方法
    sgf:Update(dt)
end)

-- ========================================
-- 监听游戏事件
-- ========================================

-- 示例：监听战斗事件
-- sgf.events:on("CombatStarted", function(data)
--     print("[ServerMain] Combat started:", data.attacker, "vs", data.defender)
-- end)

-- 示例：监听玩家升级事件
-- sgf.events:on("PlayerLevelUp", function(data)
--     print("[ServerMain] Player leveled up:", data.playerId, "->", data.newLevel)
-- end)

-- 示例：监听物品获得事件
-- sgf.events:on("ItemObtained", function(data)
--     print("[ServerMain] Item obtained:", data.playerId, data.itemId, data.count)
-- end)

print("========================================")
print("[YourGame] Server Started Successfully!")
print("========================================")
