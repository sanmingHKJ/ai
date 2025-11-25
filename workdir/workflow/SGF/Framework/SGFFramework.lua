--[[
    SGFFramework.lua - SGF框架4.0主入口
    位置: framework/SGFFramework.lua
    
    功能：
    1. SGF框架的统一初始化和管理
    2. 整合所有系统模块和辅助模块
    3. 提供框架级别的服务和接口
    
    Version: 4.0.0
    Date: 2025-10-21
    
    使用示例：
    local SGFFramework = require(MainStorage.Framework.SGFFramework)
    local sgf = SGFFramework.new()
    sgf:Init()
]]

local SGFFramework = {}
SGFFramework.__index = SGFFramework

-- 版本信息
SGFFramework.VERSION = "4.0.0"
SGFFramework.BUILD_DATE = "2025-10-21"

--[[
    创建SGF框架实例
]]
function SGFFramework.new()
    local self = setmetatable({}, SGFFramework)
    
    -- 基础信息
    self.version = SGFFramework.VERSION
    self.buildDate = SGFFramework.BUILD_DATE
    self.isInitialized = false
    
    -- 游戏服务
    self.gameServices = nil
    
    -- 日志服务
    self.log = nil

    -- GameFramework引用
    self.gameFramework = nil

    -- 系统模块
    self.systems = {}

    -- 辅助模块
    self.modules = nil

    -- 事件总线
    self.eventBus = nil

    -- 配置服务
    self.config = nil

    return self
end

--[[
    初始化全局服务
]]
function SGFFramework:InitGlobalServices()
    local MainStorage = game:GetService("MainStorage")
    local GlobalServices = require(MainStorage.Framework.Core.GlobalServices)

    self.gameServices = GlobalServices.Initialize(self)
    print("✅ SGF框架：全局服务初始化完成")
end

--[[
    初始化核心服务（事件总线、配置服务等）
    注意：日志服务已在主Init中初始化
]]
function SGFFramework:InitCoreServices()
    local MainStorage = game:GetService("MainStorage")

    -- 初始化事件总线
    local EventBus = require(MainStorage.Framework.Core.EventBus)
    self.eventBus = EventBus.new()

    -- 确保events作为顶级属性可访问（便于业务系统使用）
    self.events = self.eventBus

    -- 初始化配置服务
    local ConfigService = require(MainStorage.Framework.Core.ConfigService)
    self.config = ConfigService.new(self)

    self.log:info("✅ SGF框架：核心服务初始化完成")
end

--[[
    初始化辅助模块
]]
function SGFFramework:InitModules()
    local MainStorage = self.gameServices.MainStorage
    local ModuleManager = require(MainStorage.Framework.Core.ModuleManager)

    self.modules = ModuleManager.new(self)

    self.log:info("✅ SGF框架：辅助模块初始化完成")
end

--[[
    初始化业务系统管理器
]]
function SGFFramework:InitBusinessSystemManager()
    local MainStorage = self.gameServices.MainStorage
    local BusinessSystemManager = require(MainStorage.Framework.Core.BusinessSystemManager)

    self.businessSystemManager = BusinessSystemManager.new(self)

    self.log:info("✅ SGF框架：业务系统管理器初始化完成")
end

--[[
    初始化系统模块
    @param systemNames 要初始化的系统名称列表，nil表示初始化所有系统
]]
function SGFFramework:InitSystems(systemNames)
    local MainStorage = self.gameServices.MainStorage
    
    -- 定义所有可用的系统
    local availableSystems = {
        {name = "core", path = "CoreSystem", priority = 1},
        {name = "network", path = "NetworkSystem", priority = 2},
        {name = "actor", path = "ActorSystem", priority = 3},
        {name = "ui", path = "UISystem", priority = 4},
        {name = "stat", path = "StatSystem", priority = 5},
        {name = "combat", path = "CombatSystem", priority = 6},
        {name = "ai", path = "AISystem", priority = 7},
        {name = "avatar", path = "AvatarSystem", priority = 8},
        {name = "pet", path = "PetSystem", priority = 9},
        {name = "gm", path = "GmSystem", priority = 10},
        {name = "test", path = "TestSystem", priority = 11}
    }
    
    -- 如果指定了系统列表，只初始化指定的系统
    local systemsToInit = availableSystems
    if systemNames then
        systemsToInit = {}
        for _, systemInfo in ipairs(availableSystems) do
            for _, name in ipairs(systemNames) do
                if systemInfo.name == name then
                    table.insert(systemsToInit, systemInfo)
                    break
                end
            end
        end
    end
    
    -- 按优先级排序
    table.sort(systemsToInit, function(a, b) return a.priority < b.priority end)
    
    -- 初始化系统
    for _, systemInfo in ipairs(systemsToInit) do
        local systemPath = MainStorage.Framework.systems[systemInfo.name][systemInfo.path]
        local SystemClass = require(systemPath)
        
        self.systems[systemInfo.name] = SystemClass.new(self)
        self.systems[systemInfo.name]:Init()
        
        self.log:info("✅ SGF框架：" .. systemInfo.path .. " 初始化完成")
    end
    
    self.log:info("✅ SGF框架：所有系统模块初始化完成（" .. #systemsToInit .. "个）")
end

--[[
    完整初始化
    @param options 初始化选项
        - systems: 要初始化的系统列表，nil表示全部
]]
function SGFFramework:Init(options)
    if self.isInitialized then
        print("⚠️ SGF框架：已经初始化，跳过")
        return true
    end

    options = options or {}

    print("========================================")
    print("🚀 SGF框架 " .. self.version .. " 初始化开始")
    print("========================================")

    -- 0. 检测服务器/客户端环境
    local RunService = game:GetService("RunService")
    self.isServer = RunService:IsServer()
    self.isClient = RunService:IsClient()
    print("✅ SGF框架：环境检测完成 (isServer=" .. tostring(self.isServer) .. ", isClient=" .. tostring(self.isClient) .. ")")

    -- 1. 初始化日志服务（最先初始化，其他模块需要用到）
    local MainStorage = game:GetService("MainStorage")
    local LogService = require(MainStorage.Framework.Core.LogService)
    self.log = LogService.new(self)
    print("✅ SGF框架：日志服务初始化完成")

    -- 2. 初始化全局服务
    self:InitGlobalServices()

    -- 2.5. 加载GameFramework模块（定义GFScript全局函数，但不启动）
    self.gameFramework = require(MainStorage.Framework.GamePlay.GameFramework)
    print("✅ SGF框架：GameFramework模块已加载(GFScript全局函数已定义)")

    -- 2.6. 初始化ConfigHelper（需要GFScript函数，必须在GameFramework加载之后）
    local ConfigHelper = require(MainStorage.Framework.GamePlay.ConfigHelper)
    ConfigHelper:Init()
    print("✅ SGF框架：ConfigHelper已初始化(GameSettings等配置已注册)")

    -- 2.7. 启动GameFramework（需要ConfigHelper已初始化，因为ActorModule等需要访问配置）
    self.gameFramework:Startup()  -- 初始化所有GameFramework模块(包括CoreModule和TimerManager)
    print("✅ SGF框架：GameFramework已启动(CoreModule、TimerManager、ActorModule等已初始化)")

    -- 3. 初始化核心服务（事件总线、配置服务等）
    self:InitCoreServices()

    -- 4. 初始化辅助模块
    self:InitModules()

    -- 5. 初始化业务系统管理器
    self:InitBusinessSystemManager()

    -- 6. 初始化系统模块（旧的系统，保持兼容）
    if options.systems then
        self:InitSystems(options.systems)
    end

    self.isInitialized = true

    print("========================================")
    print("✅ SGF框架 " .. self.version .. " 初始化完成")
    print("========================================")

    return true
end

--[[
    启动框架
]]
function SGFFramework:Start()
    if not self.isInitialized then
        self.log:error("Framework not initialized")
        return false
    end

    self.log:info("========================================")
    self.log:info("🚀 SGF框架启动开始")
    self.log:info("========================================")

    -- 1. PreInit所有业务系统
    if self.businessSystemManager then
        self.businessSystemManager:preInitAll()
    end

    -- 2. Init所有业务系统
    if self.businessSystemManager then
        self.businessSystemManager:initializeAll()
    end

    -- 3. PostInit所有业务系统
    if self.businessSystemManager then
        self.businessSystemManager:postInitAll()
    end

    -- 4. Start所有业务系统
    if self.businessSystemManager then
        self.businessSystemManager:startAll()
    end

    -- 5. 启动GameMain（客户端）
    if self.gameMain then
        self.gameMain:start()
    end

    self.log:info("========================================")
    self.log:info("✅ SGF框架启动完成")
    self.log:info("========================================")

    return true
end

--[[
    更新框架（每帧调用）
    @param dt 帧时间
]]
function SGFFramework:Update(dt)
    if not self.isInitialized then
        return
    end

    -- 更新GameFramework(包括TimerManager等核心模块)
    if self.gameFramework then
        self.gameFramework:OnUpdate(dt)
    end

    -- 更新业务系统
    if self.businessSystemManager then
        self.businessSystemManager:updateAll(dt)
    end

    -- 更新旧的系统（兼容）
    for _, system in pairs(self.systems) do
        if system.Update then
            system:Update(dt)
        end
    end

    -- 更新GameMain（客户端）
    if self.gameMain then
        self.gameMain:update(dt)
    end
end

--[[
    注册业务系统
    @param name 系统名称
    @param systemClass 系统类
    @param config 配置
]]
function SGFFramework:RegisterSystem(name, systemClass, config)
    if not self.businessSystemManager then
        self.log:error("BusinessSystemManager not initialized")
        return false
    end

    return self.businessSystemManager:register(name, systemClass, config)
end

--[[
    获取系统
    @param systemName 系统名称
]]
function SGFFramework:GetSystem(systemName)
    -- 优先从BusinessSystemManager获取
    if self.businessSystemManager then
        local system = self.businessSystemManager:get(systemName)
        if system then
            return system
        end
    end

    -- 兼容旧的系统
    return self.systems[systemName]
end

--[[
    获取模块
    @param moduleName 模块名称
]]
function SGFFramework:GetModule(moduleName)
    if self.modules then
        return self.modules:GetModule(moduleName)
    end
    return nil
end

--[[
    获取框架信息
]]
function SGFFramework:GetInfo()
    local info = {
        version = self.version,
        buildDate = self.buildDate,
        isInitialized = self.isInitialized,
        systemsCount = 0,
        systems = {}
    }
    
    for name, system in pairs(self.systems) do
        info.systemsCount = info.systemsCount + 1
        table.insert(info.systems, {
            name = name,
            version = system.version or "unknown",
            isInitialized = system.isInitialized or false
        })
    end
    
    return info
end

--[[
    打印框架信息
]]
function SGFFramework:PrintInfo()
    local info = self:GetInfo()
    
    self.log:info("========================================")
    self.log:info("SGF框架信息")
    self.log:info("========================================")
    self.log:info("版本: " .. info.version)
    self.log:info("构建日期: " .. info.buildDate)
    self.log:info("初始化状态: " .. tostring(info.isInitialized))
    self.log:info("系统数量: " .. info.systemsCount)
    self.log:info("----------------------------------------")
    self.log:info("已加载系统:")
    for _, systemInfo in ipairs(info.systems) do
        self.log:info("  - " .. systemInfo.name .. " (v" .. systemInfo.version .. ")")
    end
    self.log:info("========================================")
end

return SGFFramework

