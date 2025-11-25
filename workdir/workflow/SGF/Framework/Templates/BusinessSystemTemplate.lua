--[[
    BusinessSystemTemplate.lua - 业务系统模板
    
    使用说明：
    1. 复制此模板文件
    2. 将所有 [SystemName] 替换为实际的系统名称
    3. 根据需要实现各个方法
    4. 删除不需要的方法
    
    示例：
    - [SystemName] -> InventorySystem
    - [系统功能描述] -> 背包系统，管理玩家物品
    
    Version: 1.0.0
]]

local [SystemName] = {
    -- ========== 基础信息 ==========
    name = "[SystemName]",
    version = "1.0.0",
    description = "[系统功能描述]",
    
    -- ========== 依赖声明 ==========
    dependencies = {
        -- "OtherSystemName",  -- 依赖的其他业务系统
    },
    
    -- ========== 状态管理 ==========
    state = "uninitialized",  -- uninitialized | initialized | started | stopped | error
    
    -- ========== 框架引用 ==========
    sgf = nil,              -- SGF框架实例
    log = nil,              -- 日志服务
    events = nil,           -- 事件总线
    
    -- ========== 配置 ==========
    config = {
        -- 默认配置项
        -- exampleConfig = "value",
    },
    
    -- ========== 数据 ==========
    data = {
        -- 运行时数据
    },
    
    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

--[[
    创建新实例
    @param sgf SGF框架实例
    @return 模块实例
]]
function [SystemName].new(sgf)
    local self = setmetatable({}, {__index = [SystemName]})

    self.sgf = sgf
    self.log = sgf.log          -- 便捷访问日志服务
    self.events = sgf.events    -- 便捷访问事件总线

    -- 初始化数据结构
    self.data = {}
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

--[[
    预初始化（可选）
    用于：注册事件监听器、注册配置等
]]
function [SystemName]:PreInit()
    self.log:info("[SystemName] PreInit...")
    
    -- 注册事件监听器
    self:registerEventListeners()
    
    return true
end

--[[
    初始化（必需）
    用于：加载配置、初始化数据结构、加载资源等
]]
function [SystemName]:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("[SystemName] already initialized")
        return false
    end

    self.log:info("[SystemName] Init...")
    
    -- 加载配置
    self:loadConfig()
    
    -- 初始化数据
    self:initData()
    
    -- 注册网络消息处理
    self:registerNetworkHandlers()
    
    self.state = "initialized"
    return true
end

--[[
    后初始化（可选）
    用于：与其他模块建立连接、获取依赖模块引用等
]]
function [SystemName]:PostInit()
    self.log:info("[SystemName] PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    -- 注册3D交互处理器（如果需要）
    if self.sgf.gameMain then
        self.sgf.gameMain:registerSystemInteraction(self.name, function(objectId, interactionType)
            return self:handleInteraction(objectId, interactionType)
        end)
        self.log:debug("[SystemName] 3D interaction registered")
    end

    return true
end

--[[
    启动（必需）
    用于：启动定时器、开始监听、激活功能等
]]
function [SystemName]:Start()
    if self.state ~= "initialized" then
        self.log:error("[SystemName] cannot start, state: " .. self.state)
        return false
    end
    
    self.log:info("[SystemName] Start...")
    
    -- 启动逻辑
    self:startLogic()
    
    -- 发送启动事件
    self.events:emit("[SystemName]Started", {
        timestamp = os.time()
    })
    
    self.state = "started"
    return true
end

--[[
    更新（可选）
    @param dt 帧时间（秒）
]]
function [SystemName]:Update(dt)
    if self.state ~= "started" then
        return
    end
    
    -- 更新逻辑
    self:updateLogic(dt)
end

--[[
    停止（必需）
    用于：停止定时器、保存数据、清理资源等
]]
function [SystemName]:Stop()
    if self.state ~= "started" then
        return false
    end
    
    self.log:info("[SystemName] Stop...")
    
    -- 保存数据
    self:saveData()
    
    -- 清理资源
    self:cleanup()
    
    -- 发送停止事件
    self.events:emit("[SystemName]Stopped", {
        timestamp = os.time()
    })
    
    self.state = "stopped"
    return true
end

-- ========================================
-- 内部方法
-- ========================================

--[[
    加载配置
]]
function [SystemName]:loadConfig()
    -- 从ConfigService加载配置
    if self.sgf.config then
        local configService = self.sgf.config
        self.config = configService:get("[SystemName]Config") or self.config
    end
    
    self.log:debug("[SystemName] config loaded", self.config)
end

--[[
    初始化数据
]]
function [SystemName]:initData()
    -- 初始化运行时数据结构
    self.data = {
        -- 初始化数据字段
    }
end

--[[
    解析依赖
]]
function [SystemName]:resolveDependencies()
    -- 获取依赖的其他系统
    for _, depName in ipairs(self.dependencies) do
        local depSystem = self.sgf:GetSystem(depName)
        if depSystem then
            self.dependencies_cache[depName] = depSystem
            self.log:debug("[SystemName] resolved dependency: " .. depName)
        else
            self.log:warning("[SystemName] dependency not found: " .. depName)
        end
    end
end

--[[
    注册事件监听器
]]
function [SystemName]:registerEventListeners()
    -- 监听其他系统的事件
    -- 示例：
    -- self.events:on("SomeEvent", function(data)
    --     self:onSomeEvent(data)
    -- end)
end

--[[
    注册网络消息处理
]]
function [SystemName]:registerNetworkHandlers()
    -- 如果是服务端
    local Utils = GFScript("CoreModule.Utils")
    if Utils:IsServer() then
        self:registerServerHandlers()
    else
        self:registerClientHandlers()
    end
end

--[[
    注册服务端网络处理
]]
function [SystemName]:registerServerHandlers()
    local Network = GFScript("NetworkModule.Network")
    
    -- 注册消息处理回调
    -- 示例：
    -- Network:ServerSetCallback(NetProto.RequestSomething, self.OnRequestSomething, self)
end

--[[
    注册客户端网络处理
]]
function [SystemName]:registerClientHandlers()
    local Network = GFScript("NetworkModule.Network")
    
    -- 注册消息处理回调
    -- 示例：
    -- Network:ClientSetCallback(NetProto.ResponseSomething, self.OnResponseSomething, self)
end

--[[
    启动逻辑
]]
function [SystemName]:startLogic()
    -- 启动定时器、开始监听等
    -- 示例：
    -- self:startTimer()
end

--[[
    更新逻辑
]]
function [SystemName]:updateLogic(dt)
    -- 每帧更新逻辑
    -- 示例：
    -- self:updateTimers(dt)
end

--[[
    保存数据
]]
function [SystemName]:saveData()
    -- 保存需要持久化的数据
    -- 示例：
    -- self:saveToDatabase()
end

--[[
    清理资源
]]
function [SystemName]:cleanup()
    -- 清理定时器、事件监听器等
    -- 示例：
    -- self:stopAllTimers()
    -- self:disconnectAllEvents()
end

-- ========================================
-- 公共API方法
-- ========================================

--[[
    示例公共方法
    @param param1 参数1
    @return 返回值
]]
function [SystemName]:SomePublicMethod(param1)
    if self.state ~= "started" then
        self.log:warning("[SystemName] not started")
        return nil
    end

    -- 实现逻辑
    self.log:debug("[SystemName] SomePublicMethod called", {param1 = param1})
    
    -- 返回结果
    return result
end

-- ========================================
-- 网络消息处理方法（服务端）
-- ========================================

--[[
    处理客户端请求（服务端）
    @param playerId 玩家ID
    @param code 消息码
    @param body 消息体
]]
function [SystemName]:OnRequestSomething(playerId, code, body)
    self.log:debug("[SystemName] OnRequestSomething", {playerId = playerId, body = body})
    
    -- 服务端验证
    local valid, reason = self:validateRequest(playerId, body)
    if not valid then
        self.log:warning("[SystemName] invalid request", {playerId = playerId, reason = reason})

        -- 发送失败响应
        local Network = GFScript("NetworkModule.Network")
        Network:SendToClient(playerId, NetProto.ResponseSomething, {
            success = false,
            reason = reason
        })
        return
    end
    
    -- 处理请求
    local result = self:processRequest(playerId, body)
    
    -- 发送响应
    local Network = GFScript("NetworkModule.Network")
    Network:SendToClient(playerId, NetProto.ResponseSomething, {
        success = true,
        result = result
    })
end

--[[
    验证请求（服务端）
]]
function [SystemName]:validateRequest(playerId, body)
    -- 验证逻辑
    -- 返回 true 或 false, reason
    return true
end

--[[
    处理请求（服务端）
]]
function [SystemName]:processRequest(playerId, body)
    -- 处理逻辑
    return {}
end

-- ========================================
-- 网络消息处理方法（客户端）
-- ========================================

--[[
    处理服务端响应（客户端）
    @param code 消息码
    @param body 消息体
]]
function [SystemName]:OnResponseSomething(code, body)
    self.log:debug("[SystemName] OnResponseSomething", {body = body})
    
    if body.success then
        -- 处理成功响应
        self:processResponse(body.result)
        
        -- 发送事件通知UI更新
        self.events:emit("[SystemName]DataUpdated", body.result)
    else
        -- 处理失败响应
        self.log:warning("[SystemName] request failed", {reason = body.reason})

        -- 显示错误提示
        self.events:emit("ShowError", {
            message = body.reason or "Request failed"
        })
    end
end

--[[
    处理响应（客户端）
]]
function [SystemName]:processResponse(result)
    -- 更新本地数据
    -- self.data = result
end

-- ========================================
-- 事件处理方法
-- ========================================

--[[
    处理某个事件
    @param data 事件数据
]]
function [SystemName]:onSomeEvent(data)
    self.log:debug("[SystemName] onSomeEvent", data)
    
    -- 处理事件逻辑
end

-- ========================================
-- 工具方法
-- ========================================

--[[
    示例工具方法
]]
function [SystemName]:someUtilityMethod()
    -- 工具方法实现
end

return [SystemName]

