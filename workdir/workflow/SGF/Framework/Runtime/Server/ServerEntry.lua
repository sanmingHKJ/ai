--[[
    ServerEntry.lua - SGF框架服务器端入口
    位置: framework/server/ServerEntry.lua
    
    功能：
    1. 提供服务器端框架初始化
    2. 管理服务器端框架组件
    3. 提供网络消息注册和处理
    
    Version: 4.0.0 (SGF框架)
    
    使用方式：
    local ServerEntry = require(MainStorage.Framework.Server.ServerEntry)
    local server = ServerEntry.new(sgf)
    server:Init()
]]

local ServerEntry = {}
ServerEntry.__index = ServerEntry

--[[
    创建服务器入口实例
    @param sgf SGF框架实例
]]
function ServerEntry.new(sgf)
    local self = setmetatable({}, ServerEntry)
    
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
function ServerEntry:InitGlobalServices()
    local GlobalServices = require(self.sgf.mainStorage.Framework.Core.GlobalServices)

    -- 初始化全局服务
    local services = GlobalServices.Initialize(self.sgf)

    self.sgf.log:info("ServerEntry: 全局服务初始化完成")

    return services
end

--[[
    加载框架组件
]]
function ServerEntry:LoadFrameworkComponents()
    local MainStorage = self.sgf.gameServices.MainStorage

    -- 1. 首先加载GameFramework以定义GFScript全局函数
    require(MainStorage.Framework.GamePlay.GameFramework)
    self.sgf.log:info("ServerEntry: GameFramework全局函数已加载")

    -- 2. 加载核心组件
    self.components.ConfigHelper = require(MainStorage.Framework.GamePlay.ConfigHelper)
    self.components.Bridge = require(MainStorage.Framework.Runtime.Bridge)
    self.components.Protocol = require(MainStorage.Framework.Runtime.Protocol)

    self.sgf.log:info("ServerEntry: 框架组件加载完成")
end

--[[
    初始化框架组件
]]
function ServerEntry:InitFrameworkComponents()
    self.sgf.log:info("ServerEntry: 初始化框架组件...")

    -- 1. 初始化ConfigHelper
    local success = self.components.ConfigHelper:Init(self.sgf)
    if not success then
        self.sgf.log:error("ServerEntry: ConfigHelper初始化失败")
        return false
    end
    self.sgf.log:info("ServerEntry: ConfigHelper初始化成功")

    -- 2. 初始化Bridge
    local MainStorage = self.sgf.gameServices.MainStorage
    local remoteEvent = MainStorage.Scripts.Common.Bridge.RemoteEvent
    success = self.components.Bridge:Init(self.sgf, remoteEvent)
    if not success then
        self.sgf.log:error("ServerEntry: Bridge初始化失败")
        return false
    end
    self.sgf.log:info("ServerEntry: Bridge初始化成功")

    -- 3. 初始化GameFramework网络模块
    local NetworkModule = GFScript("NetworkModule")
    if NetworkModule and NetworkModule.Startup then
        NetworkModule:Startup()
        self.sgf.log:info("ServerEntry: GameFramework网络模块初始化成功")
    end

    self.sgf.log:info("ServerEntry: 框架组件初始化完成")
    return true
end

--[[
    注册网络消息回调
    @param msgId 消息ID
    @param callback 回调函数 function(playerId, msgid, body)
]]
function ServerEntry:RegisterMessageCallback(msgId, callback)
    if not self.components.Bridge then
        self.sgf.log:error("ServerEntry: Bridge未初始化，无法注册消息回调")
        return false
    end
    
    self.components.Bridge:RegisterClientMessageCallback(msgId, callback)
    self.messageCallbacks[msgId] = callback
    
    return true
end

--[[
    发送消息给客户端
    @param playerId 玩家ID
    @param msgId 消息ID
    @param body 消息体
]]
function ServerEntry:SendMessageToClient(playerId, msgId, body)
    if not self.components.Bridge then
        self.sgf.log:error("ServerEntry: Bridge未初始化，无法发送消息")
        return false
    end
    
    self.components.Bridge:SendMessageToClient(playerId, msgId, body)
    return true
end

--[[
    广播消息给所有客户端
    @param msgId 消息ID
    @param body 消息体
]]
function ServerEntry:BroadcastMessage(msgId, body)
    if not self.components.Bridge then
        self.sgf.log:error("ServerEntry: Bridge未初始化，无法广播消息")
        return false
    end
    
    self.components.Bridge:BroadcastMessageToAllClients(msgId, body)
    return true
end

--[[
    获取框架组件
    @param componentName 组件名称
]]
function ServerEntry:GetComponent(componentName)
    return self.components[componentName]
end

--[[
    初始化服务器入口
]]
function ServerEntry:Init()
    if self.isInitialized then
        self.sgf.log:warning("ServerEntry: 已经初始化，跳过")
        return true
    end
    
    self.sgf.log:info("=== ServerEntry初始化开始（SGF 4.0）===")
    
    -- 1. 初始化全局服务
    self:InitGlobalServices()
    
    -- 2. 加载框架组件
    self:LoadFrameworkComponents()
    
    -- 3. 初始化框架组件
    local success = self:InitFrameworkComponents()
    if not success then
        self.sgf.log:error("ServerEntry: 框架组件初始化失败")
        return false
    end
    
    self.isInitialized = true
    self.sgf.log:info("=== ServerEntry初始化完成（SGF 4.0）===")
    
    return true
end

--[[
    获取统计信息
]]
function ServerEntry:GetStats()
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
    
    return stats
end

--[[
    打印统计信息
]]
function ServerEntry:PrintStats()
    local stats = self:GetStats()
    
    self.sgf.log:info("=== ServerEntry统计信息 ===")
    self.sgf.log:info("初始化状态: " .. tostring(stats.isInitialized))
    self.sgf.log:info("已加载组件数: " .. stats.componentsCount)
    self.sgf.log:info("已注册消息回调数: " .. stats.messageCallbacksCount)
    
    if stats.configHelper then
        self.sgf.log:info("已注册配置数: " .. stats.configHelper.registeredCount)
    end
    
    self.sgf.log:info("========================")
end

return ServerEntry

