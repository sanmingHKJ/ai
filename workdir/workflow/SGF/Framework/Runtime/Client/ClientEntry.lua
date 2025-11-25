--[[
    ClientEntry.lua - SGF框架客户端入口
    位置: framework/client/ClientEntry.lua
    
    功能：
    1. 提供客户端框架初始化
    2. 管理客户端框架组件
    3. 提供网络消息注册和处理
    
    Version: 4.0.0 (SGF框架)
    
    使用方式：
    local ClientEntry = require(MainStorage.Framework.Client.ClientEntry)
    local client = ClientEntry.new(sgf)
    client:Init()
]]

local ClientEntry = {}
ClientEntry.__index = ClientEntry

--[[
    创建客户端入口实例
    @param sgf SGF框架实例
]]
function ClientEntry.new(sgf)
    local self = setmetatable({}, ClientEntry)
    
    self.sgf = sgf
    self.isInitialized = false
    
    -- 框架组件引用
    self.components = {}
    
    -- 网络消息回调
    self.messageCallbacks = {}
    
    return self
end

--[[
    初始化全局服务
]]
function ClientEntry:InitGlobalServices()
    local GlobalServices = require(self.sgf.mainStorage.Framework.Core.GlobalServices)

    -- 初始化全局服务
    local services = GlobalServices.Initialize(self.sgf)

    self.sgf.log:info("ClientEntry: 全局服务初始化完成")

    return services
end

--[[
    加载框架组件
]]
function ClientEntry:LoadFrameworkComponents()
    local MainStorage = self.sgf.gameServices.MainStorage

    -- 1. 首先加载GameFramework以定义GFScript全局函数
    require(MainStorage.Framework.GamePlay.GameFramework)
    self.sgf.log:info("ClientEntry: GameFramework全局函数已加载")

    -- 2. 加载核心组件
    self.components.ConfigHelper = require(MainStorage.Framework.GamePlay.ConfigHelper)
    self.components.EffectPoolManager = require(MainStorage.Framework.GamePlay.EffectPoolManager)

    -- 使用GameFramework的网络模块
    -- Bridge, Protocol, NetworkService 已移除，使用 GFScript("NetworkModule.Network")

    self.sgf.log:info("ClientEntry: 框架组件加载完成")
end

--[[
    初始化框架组件
]]
function ClientEntry:InitFrameworkComponents()
    self.sgf.log:info("ClientEntry: 初始化框架组件...")

    -- 1. 初始化ConfigHelper
    local success = self.components.ConfigHelper:Init(self.sgf)
    if not success then
        self.sgf.log:error("ClientEntry: ConfigHelper初始化失败")
        return false
    end
    self.sgf.log:info("ClientEntry: ConfigHelper初始化成功")

    -- 2. 初始化EffectPoolManager
    success = self.components.EffectPoolManager:Init(self.sgf, {
        defaultPoolSize = 50,
        enableAutoCleanup = true,
        cleanupInterval = 60,
        maxIdleTime = 120
    })
    if not success then
        self.sgf.log:error("ClientEntry: EffectPoolManager初始化失败")
        return false
    end
    self.sgf.log:info("ClientEntry: EffectPoolManager初始化成功")

    -- 3. 初始化GameFramework网络模块
    local NetworkModule = GFScript("NetworkModule")
    if NetworkModule and NetworkModule.Startup then
        NetworkModule:Startup()
        self.sgf.log:info("ClientEntry: GameFramework网络模块初始化成功")
    end

    self.sgf.log:info("ClientEntry: 框架组件初始化完成")
    return true
end

--[[
    初始化GameMain（客户端3D交互管理器）
]]
function ClientEntry:InitGameMain()
    local MainStorage = self.sgf.gameServices.MainStorage
    local GameMain = require(MainStorage.Framework.Core.GameMain)

    self.sgf.gameMain = GameMain.new(self.sgf)
    self.sgf.gameMain:init(self.sgf)

    self.sgf.log:info("ClientEntry: GameMain初始化完成")
end

--[[
    注册网络消息回调
    @param msgId 消息ID
    @param callback 回调函数 function(msgid, body)
]]
function ClientEntry:RegisterMessageCallback(msgId, callback)
    if not self.components.Bridge then
        self.sgf.log:error("ClientEntry: Bridge未初始化，无法注册消息回调")
        return false
    end
    
    self.components.Bridge:RegisterServerMessageCallback(msgId, callback)
    self.messageCallbacks[msgId] = callback
    
    return true
end

--[[
    发送消息给服务器
    @param msgId 消息ID
    @param body 消息体
]]
function ClientEntry:SendMessageToServer(msgId, body)
    if not self.components.Bridge then
        self.sgf.log:error("ClientEntry: Bridge未初始化，无法发送消息")
        return false
    end
    
    self.components.Bridge:SendMessageToServer(msgId, body)
    return true
end

--[[
    获取框架组件
    @param componentName 组件名称
]]
function ClientEntry:GetComponent(componentName)
    return self.components[componentName]
end

--[[
    初始化客户端入口
]]
function ClientEntry:Init()
    if self.isInitialized then
        self.sgf.log:warning("ClientEntry: 已经初始化，跳过")
        return true
    end

    self.sgf.log:info("=== ClientEntry初始化开始（SGF 4.0）===")

    -- 1. 初始化全局服务
    self:InitGlobalServices()

    -- 2. 加载框架组件
    self:LoadFrameworkComponents()

    -- 3. 初始化框架组件
    local success = self:InitFrameworkComponents()
    if not success then
        self.sgf.log:error("ClientEntry: 框架组件初始化失败")
        return false
    end

    -- 4. 初始化GameMain（客户端3D交互管理器）
    self:InitGameMain()

    self.isInitialized = true
    self.sgf.log:info("=== ClientEntry初始化完成（SGF 4.0）===")

    return true
end

--[[
    获取统计信息
]]
function ClientEntry:GetStats()
    local stats = {
        isInitialized = self.isInitialized,
        componentsCount = 0,
        messageCallbacksCount = 0,
    }
    
    for _ in pairs(self.components) do
        stats.componentsCount = stats.componentsCount + 1
    end
    
    for _ in pairs(self.messageCallbacks) do
        stats.messageCallbacksCount = stats.messageCallbacksCount + 1
    end
    
    -- ConfigHelper统计
    if self.components.ConfigHelper then
        stats.configHelper = self.components.ConfigHelper:GetStats()
    end
    
    -- EffectPoolManager统计
    if self.components.EffectPoolManager then
        stats.effectPoolManager = self.components.EffectPoolManager:GetStats()
    end
    
    return stats
end

--[[
    打印统计信息
]]
function ClientEntry:PrintStats()
    local stats = self:GetStats()
    
    self.sgf.log:info("=== ClientEntry统计信息 ===")
    self.sgf.log:info("初始化状态: " .. tostring(stats.isInitialized))
    self.sgf.log:info("已加载组件数: " .. stats.componentsCount)
    self.sgf.log:info("已注册消息回调数: " .. stats.messageCallbacksCount)
    
    if stats.configHelper then
        self.sgf.log:info("已注册配置数: " .. stats.configHelper.registeredCount)
    end
    
    if stats.effectPoolManager then
        self.sgf.log:info("特效池统计 - 总数: " .. stats.effectPoolManager.total .. 
                         ", 空闲: " .. stats.effectPoolManager.free .. 
                         ", 使用中: " .. stats.effectPoolManager.used)
    end
    
    self.sgf.log:info("========================")
end

return ClientEntry

