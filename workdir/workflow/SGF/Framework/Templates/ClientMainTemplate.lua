--[[
    ClientMain.lua - Client Entry Template
    客户端主入口文件模板

    按照SGF标准化开发框架规范开发

    使用说明：
    1. 将此文件复制到 StartPlayer/StarterPlayerScripts/ 目录
    2. 修改项目名称和描述
    3. 根据需要加载和注册客户端业务系统
    4. 根据需要注册UI面板
    5. 根据需要监听游戏事件

    Version: 1.0.0
]]

print("========================================")
print("[YourGame] Client Starting...")
print("========================================")

-- 环境检查
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    error("This script should only run on client")
    return
end

local MainStorage = game:GetService("MainStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 加载SGF框架
local Framework = MainStorage:WaitForChild("Framework")
local SGFFramework = require(Framework:WaitForChild("SGFFramework"))

-- 创建框架实例
local sgf = SGFFramework.new()

print("[ClientMain] Initializing SGF Framework...")

-- 初始化框架
local success = sgf:Init({
    systems = {
        -- 客户端业务系统将在这里注册
        -- 示例：
        -- "PlayerSystemClient",
        -- "CombatSystemClient",
        -- "SkillSystemClient",
        -- "InventorySystemClient",
    }
})

if not success then
    error("[ClientMain] Failed to initialize SGF framework")
    return
end

-- ========================================
-- 加载业务系统（客户端）
-- ========================================
print("[ClientMain] Loading client systems...")

-- 示例：加载客户端业务系统
-- local PlayerSystemClient = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemClient)
-- local CombatSystemClient = require(MainStorage.Framework.GameSystems.CombatSystem.CombatSystemClient)

-- 示例：创建系统实例
-- local playerSystemClient = PlayerSystemClient.new(sgf)
-- local combatSystemClient = CombatSystemClient.new(sgf)

-- 示例：注册系统到框架
-- sgf.businessSystemManager:registerSystem("PlayerSystemClient", playerSystemClient)
-- sgf.businessSystemManager:registerSystem("CombatSystemClient", combatSystemClient)

-- 示例：初始化系统（PreInit -> Init -> PostInit -> Start）
print("[ClientMain] Initializing client systems...")

-- PreInit（注册事件监听器）
-- playerSystemClient:PreInit()
-- combatSystemClient:PreInit()

-- Init（加载配置、初始化数据）
-- playerSystemClient:Init()
-- combatSystemClient:Init()

-- PostInit（解析依赖、注册3D交互）
-- playerSystemClient:PostInit()
-- combatSystemClient:PostInit()

-- Start（启动逻辑）
print("[ClientMain] Starting client systems...")
-- playerSystemClient:Start()
-- combatSystemClient:Start()

-- ========================================
-- 初始化UI面板管理器
-- ========================================
print("[ClientMain] Initializing Panel Manager...")

-- 加载PanelManager
local PanelManager = require(Framework.UI.PanelManager)

-- 创建PanelManager实例
local panelManager = PanelManager.new(sgf)

-- 将PanelManager添加到sgf实例中，方便其他地方访问
sgf.panelManager = panelManager

-- 示例：加载UI面板类
-- local MainHUDPanel = require(MainStorage.Framework.UI.Panels.MainHUDPanel)
-- local InventoryPanel = require(MainStorage.Framework.UI.Panels.InventoryPanel)

-- 示例：注册UI面板到PanelManager
print("[ClientMain] Registering UI panels...")
-- panelManager:register("MainHUDPanel", MainHUDPanel)
-- panelManager:register("InventoryPanel", InventoryPanel)

-- 示例：创建并显示面板
print("[ClientMain] Creating and showing UI panels...")
-- panelManager:create("MainHUDPanel")
-- panelManager:show("MainHUDPanel")

print("[ClientMain] UI panels initialized successfully")

-- ========================================
-- 客户端主循环（渲染循环）
-- ========================================
RunService.RenderStepped:Connect(function(dt)
    -- 使用 SGF 框架的统一更新方法
    -- 框架会自动调用所有注册系统的 Update 方法
    sgf:Update(dt)
end)

-- ========================================
-- 监听UI事件
-- ========================================

-- 示例：监听角色面板打开事件
-- sgf.events:on("OpenCharacterPanel", function(data)
--     print("[ClientMain] Open character panel")
--     panelManager:show("CharacterPanel")
-- end)

-- 示例：监听背包面板打开事件
-- sgf.events:on("OpenInventoryPanel", function(data)
--     print("[ClientMain] Open inventory panel")
--     panelManager:show("InventoryPanel")
-- end)

-- ========================================
-- 监听游戏事件
-- ========================================

-- 示例：监听消息显示事件
-- sgf.events:on("ShowMessage", function(data)
--     print("[ClientMain] Message:", data.message)
-- end)

-- 示例：监听玩家数据更新事件
-- sgf.events:on("PlayerDataUpdated", function(data)
--     print("[ClientMain] Player data updated:", data.playerData)
-- end)

-- 示例：监听战斗开始事件
-- sgf.events:on("CombatStarted", function(data)
--     print("[ClientMain] Combat started")
--     panelManager:show("CombatPanel")
-- end)

-- 示例：监听战斗结束事件
-- sgf.events:on("CombatEnded", function(data)
--     print("[ClientMain] Combat ended")
--     panelManager:hide("CombatPanel")
-- end)

print("========================================")
print("[YourGame] Client Started Successfully!")
print("========================================")
