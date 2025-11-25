--[[
    BusinessSystemManager.lua - 业务系统管理器
    负责业务系统的注册、生命周期管理和系统间通信
    Version: 1.0.0
]]

local BusinessSystemManager = {
    name = "BusinessSystemManager",
    version = "1.0.0",
    
    -- 系统注册表
    systems = {},
    systemConfigs = {},
    systemStates = {},
    
    -- 依赖关系
    dependencies = {},
    
    -- SGF框架引用
    sgf = nil,
}

function BusinessSystemManager.new(sgf)
    local instance = setmetatable({}, {__index = BusinessSystemManager})
    instance.sgf = sgf
    instance.systems = {}
    instance.systemConfigs = {}
    instance.systemStates = {}
    instance.dependencies = {}
    
    return instance
end

-- 注册业务系统
function BusinessSystemManager:register(name, systemClass, config)
    if self.systems[name] then
        self.sgf.log:warning("System already registered", {name = name})
        return false
    end
    
    local system = systemClass
    if type(systemClass) == "function" then
        system = systemClass()
    end
    
    -- 根据运行模式决定是否注册
    if system.runMode == "server-only" and not self.sgf.studio.isServer then
        self.sgf.log:debug("Skipping server-only system on client", {name = name})
        return false
    elseif system.runMode == "client-only" and self.sgf.studio.isServer then
        self.sgf.log:debug("Skipping client-only system on server", {name = name})
        return false
    end
    
    -- 注册系统
    self.systems[name] = system
    self.systemConfigs[name] = config or {}
    self.systemStates[name] = "registered"
    
    -- 记录依赖关系
    if system.dependencies then
        self.dependencies[name] = system.dependencies
    end
    
    -- 根据系统特性进行相应注册
    self:registerSystemFeatures(name, system)
    
    self.sgf.log:info("Business system registered", {
        name = name,
        runMode = system.runMode,
        hasUI = system.hasUI,
        has3DLogic = system.has3DLogic
    })
    
    return true
end

-- 注册系统特性
function BusinessSystemManager:registerSystemFeatures(name, system)
    -- 如果有UI，注册到PanelManager
    if system.hasUI and system.getUIPanels and self.sgf.panels then
        local panels = system:getUIPanels()
        for _, panelName in ipairs(panels) do
            self.sgf.panels:registerSystemPanel(panelName, name)
        end
        self.sgf.log:debug("UI panels registered", {system = name, panels = panels})
    end
    
    -- 如果有3D逻辑，注册到GameMain
    if system.has3DLogic and system.on3DInteraction and self.sgf.gameMain then
        self.sgf.gameMain:registerSystemInteraction(name, function(objectId, interactionType)
            return system:on3DInteraction(objectId, interactionType)
        end)
        self.sgf.log:debug("3D interaction registered", {system = name})
    end
    
    -- 如果有共享模型，注册到SharedModelManager
    if system.getSharedModels and self.sgf.sharedModels then
        local models = system:getSharedModels()
        for _, modelName in ipairs(models) do
            self.sgf.sharedModels:registerSystemModel(modelName, name)
        end
        self.sgf.log:debug("Shared models registered", {system = name, models = models})
    end
    
    -- 如果需要更新，注册到调度器
    if system.update then
        local priority = system.isBackgroundSystem and "LOW" or "NORMAL"
        self.sgf.scheduler:register(name .. "_Update", function(dt)
            if self.systemStates[name] == "running" then
                system:update(dt)
            end
        end, self.sgf.scheduler.UpdatePriority[priority])
        self.sgf.log:debug("Update scheduler registered", {system = name, priority = priority})
    end
end

-- 获取系统实例
function BusinessSystemManager:get(name)
    return self.systems[name]
end

-- PreInit所有系统
function BusinessSystemManager:preInitAll()
    local initOrder = self:calculateInitOrder()

    for _, name in ipairs(initOrder) do
        local system = self.systems[name]
        if system and type(system.PreInit) == "function" then
            local success, error = pcall(system.PreInit, system)
            if not success then
                self.sgf.log:error("System PreInit failed", {name = name, error = error})
            else
                self.sgf.log:info("System PreInit completed", {name = name})
            end
        end
    end

    self.sgf.log:info("All business systems PreInit completed")
end

-- 初始化所有系统
function BusinessSystemManager:initializeAll()
    local initOrder = self:calculateInitOrder()

    for _, name in ipairs(initOrder) do
        self:initializeSystem(name)
    end

    self.sgf.log:info("All business systems initialized")
end

-- PostInit所有系统
function BusinessSystemManager:postInitAll()
    local initOrder = self:calculateInitOrder()

    for _, name in ipairs(initOrder) do
        local system = self.systems[name]
        if system and type(system.PostInit) == "function" then
            local success, error = pcall(system.PostInit, system)
            if not success then
                self.sgf.log:error("System PostInit failed", {name = name, error = error})
            else
                self.sgf.log:info("System PostInit completed", {name = name})
            end
        end
    end

    self.sgf.log:info("All business systems PostInit completed")
end

-- 初始化单个系统
function BusinessSystemManager:initializeSystem(name)
    local system = self.systems[name]
    if not system then
        return false, "System not found: " .. name
    end
    
    if self.systemStates[name] ~= "registered" then
        return false, "System not in registered state: " .. name
    end
    
    -- 初始化系统
    local success, error = pcall(system.init, system, self.sgf, self.systemConfigs[name])
    if success then
        self.systemStates[name] = "initialized"
        self.sgf.log:info("System initialized", {name = name})
        return true
    else
        self.systemStates[name] = "error"
        self.sgf.log:error("System initialization failed", {name = name, error = error})
        return false, error
    end
end

-- 启动所有系统
function BusinessSystemManager:startAll()
    local startOrder = self:calculateStartOrder()
    
    for _, name in ipairs(startOrder) do
        self:startSystem(name)
    end
    
    self.sgf.log:info("All business systems started")
end

-- 启动单个系统
function BusinessSystemManager:startSystem(name)
    local system = self.systems[name]
    if not system then
        return false, "System not found: " .. name
    end

    if self.systemStates[name] ~= "initialized" then
        return false, "System not initialized: " .. name
    end

    -- 🔧 修复：start方法是可选的，如果不存在则直接标记为running
    if type(system.start) == "function" then
        -- 启动系统
        local success, error = pcall(system.start, system)
        if success then
            self.systemStates[name] = "running"
            self.sgf.events:emit("SystemStarted", {name = name, system = system})
            self.sgf.log:info("System started", {name = name})
            return true
        else
            self.systemStates[name] = "error"
            self.sgf.log:error("System start failed", {name = name, error = error})
            return false, error
        end
    else
        -- 没有start方法，直接标记为running
        self.systemStates[name] = "running"
        self.sgf.events:emit("SystemStarted", {name = name, system = system})
        self.sgf.log:info("System started (no start method)", {name = name})
        return true
    end
end

-- 停止所有系统
function BusinessSystemManager:stopAll()
    -- 按相反顺序停止
    local stopOrder = self:calculateStopOrder()
    
    for _, name in ipairs(stopOrder) do
        self:stopSystem(name)
    end
    
    self.sgf.log:info("All business systems stopped")
end

-- 停止单个系统
function BusinessSystemManager:stopSystem(name)
    local system = self.systems[name]
    if not system then
        return false, "System not found: " .. name
    end

    if self.systemStates[name] ~= "running" then
        return false, "System not running: " .. name
    end

    -- 🔧 修复：stop方法是可选的，如果不存在则直接标记为stopped
    if type(system.stop) == "function" then
        -- 停止系统
        local success, error = pcall(system.stop, system)
        if success then
            self.systemStates[name] = "stopped"
            self.sgf.events:emit("SystemStopped", {name = name, system = system})
            self.sgf.log:info("System stopped", {name = name})
            return true
        else
            self.sgf.log:error("System stop failed", {name = name, error = error})
            return false, error
        end
    else
        -- 没有stop方法，直接标记为stopped
        self.systemStates[name] = "stopped"
        self.sgf.events:emit("SystemStopped", {name = name, system = system})
        self.sgf.log:info("System stopped (no stop method)", {name = name})
        return true
    end
end

-- 系统间消息发送
function BusinessSystemManager:sendMessage(fromSystem, toSystem, message, data)
    local targetSystem = self.systems[toSystem]
    if not targetSystem then
        self.sgf.log:warning("Target system not found", {from = fromSystem, to = toSystem})
        return false
    end
    
    if targetSystem.onSystemMessage then
        local success, error = pcall(targetSystem.onSystemMessage, targetSystem, fromSystem, message, data)
        if not success then
            self.sgf.log:error("System message failed", {
                from = fromSystem,
                to = toSystem,
                message = message,
                error = error
            })
        end
        return success
    end
    
    return false
end

-- 广播消息
function BusinessSystemManager:broadcastMessage(fromSystem, message, data)
    for name, system in pairs(self.systems) do
        if name ~= fromSystem and system.onSystemMessage then
            self:sendMessage(fromSystem, name, message, data)
        end
    end
end

-- 更新所有系统
function BusinessSystemManager:updateAll(dt)
    for name, system in pairs(self.systems) do
        if self.systemStates[name] == "running" and type(system.Update) == "function" then
            local success, error = pcall(system.Update, system, dt)
            if not success then
                self.sgf.log:error("System update failed", {
                    name = name,
                    error = error
                })
            end
        end
    end
end

-- 计算初始化顺序
function BusinessSystemManager:calculateInitOrder()
    return self:topologicalSort(self.dependencies)
end

-- 计算启动顺序
function BusinessSystemManager:calculateStartOrder()
    return self:topologicalSort(self.dependencies)
end

-- 计算停止顺序（启动顺序的反向）
function BusinessSystemManager:calculateStopOrder()
    local startOrder = self:calculateStartOrder()
    local stopOrder = {}
    for i = #startOrder, 1, -1 do
        table.insert(stopOrder, startOrder[i])
    end
    return stopOrder
end

-- 拓扑排序
function BusinessSystemManager:topologicalSort(dependencies)
    local visited = {}
    local result = {}
    
    local function visit(name)
        if visited[name] then
            return
        end
        
        visited[name] = true
        
        -- 先访问依赖
        if dependencies[name] then
            for _, dep in ipairs(dependencies[name]) do
                if self.systems[dep] then
                    visit(dep)
                end
            end
        end
        
        table.insert(result, name)
    end
    
    -- 访问所有系统
    for name in pairs(self.systems) do
        visit(name)
    end
    
    return result
end

-- 获取所有系统
function BusinessSystemManager:getAllSystems()
    return self.systems
end

-- 获取系统状态
function BusinessSystemManager:getSystemState(name)
    return self.systemStates[name]
end

return BusinessSystemManager
