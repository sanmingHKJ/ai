--[[
    PanelManager.lua - 面板管理器
    负责UI面板的注册、生命周期管理和显示控制
    Version: 1.0.0
]]

local PanelManager = {
    name = "PanelManager",
    version = "1.0.0",
    
    -- 面板注册表
    panelClasses = {},
    panelInstances = {},
    panelSystems = {},
    
    -- 面板状态
    panelStates = {},
    
    -- 显示层级
    displayLayers = {
        background = 0,
        normal = 100,
        overlay = 200,
        popup = 300,
        modal = 400,
        system = 500
    },
    
    -- 当前活跃面板
    activePanel = nil,
    
    -- 面板历史栈
    panelStack = {},
    
    -- SGF框架引用
    sgf = nil,
}

function PanelManager.new(sgf)
    local instance = setmetatable({}, {__index = PanelManager})
    instance.sgf = sgf
    instance.panelClasses = {}
    instance.panelInstances = {}
    instance.panelSystems = {}
    instance.panelStates = {}
    instance.panelStack = {}
    instance.activePanel = nil
    
    return instance
end

-- 注册面板
function PanelManager:register(name, panelClass, systemName)
    if self.panelClasses[name] then
        self.sgf.log:warning("Panel already registered", {name = name})
        return false
    end

    self.panelClasses[name] = panelClass
    self.panelSystems[name] = systemName
    self.panelStates[name] = "registered"
    
    self.sgf.log:info("Panel registered", {
        name = name,
        system = systemName,
        panelType = panelClass.panelType
    })
    
    return true
end

-- 注册系统面板
function PanelManager:registerSystemPanel(panelName, systemName)
    self.panelSystems[panelName] = systemName
    self.sgf.log:debug("System panel registered", {panel = panelName, system = systemName})
end

-- 创建面板实例
function PanelManager:create(name, config)
    local panelClass = self.panelClasses[name]
    if not panelClass then
        self.sgf.log:error("Panel class not found", {name = name})
        return false
    end
    
    if self.panelInstances[name] then
        self.sgf.log:warning("Panel instance already exists", {name = name})
        return true
    end

    -- 创建面板实例（调用Panel的构造函数）
    local panel = panelClass.new(self.sgf)
    
    -- 获取关联的业务系统
    local systemName = self.panelSystems[name]
    local system = nil
    if systemName and self.sgf.businessSystems then
        system = self.sgf.businessSystems:get(systemName)
    end
    
    -- 初始化面板
    local success, error = pcall(panel.init, panel, self.sgf, system)
    if not success then
        self.sgf.log:error("Panel initialization failed", {name = name, error = error})
        return false
    end
    
    self.panelInstances[name] = panel
    self.panelStates[name] = "created"
    
    self.sgf.log:info("Panel created", {name = name})
    return true
end

-- 显示面板
function PanelManager:show(name, data)
    -- 确保面板实例存在
    if not self.panelInstances[name] then
        if not self:create(name) then
            return false
        end
    end
    
    local panel = self.panelInstances[name]
    if not panel then
        return false
    end
    
    -- 检查面板类型，处理互斥显示
    self:handlePanelExclusivity(name, panel)
    
    -- 显示面板
    local success, error = pcall(function ()
        panel:show(data)
    end)
    if not success then
        self.sgf.log:error("Panel show failed", {name = name, error = error})
        return false
    end
    
    self.panelStates[name] = "visible"
    
    -- 更新活跃面板
    if panel.panelType ~= "background" then
        self.activePanel = name
    end
    
    -- 添加到面板栈
    self:addToStack(name)
    
    -- 发送事件
    self.sgf.events:emit("PanelShown", {name = name, data = data})
    
    self.sgf.log:info("Panel shown", {name = name})
    return true
end

-- 隐藏面板
function PanelManager:hide(name)
    local panel = self.panelInstances[name]
    if not panel then
        return false
    end
    
    if self.panelStates[name] ~= "visible" then
        return false
    end
    
    -- 隐藏面板
    local success, error = pcall(function ()
        panel:hide()
    end)
    if not success then
        self.sgf.log:error("Panel hide failed", {name = name, error = error})
        return false
    end
    
    self.panelStates[name] = "hidden"
    
    -- 更新活跃面板
    if self.activePanel == name then
        self.activePanel = self:getTopVisiblePanel()
    end
    
    -- 从面板栈中移除
    self:removeFromStack(name)
    
    -- 发送事件
    self.sgf.events:emit("PanelHidden", {name = name})
    
    self.sgf.log:info("Panel hidden", {name = name})
    return true
end

-- 切换面板显示
function PanelManager:toggle(name, data)
    if self:isVisible(name) then
        return self:hide(name)
    else
        return self:show(name, data)
    end
end

-- 检查面板是否可见
function PanelManager:isVisible(name)
    return self.panelStates[name] == "visible"
end

-- 获取当前活跃面板
function PanelManager:getActivePanel()
    return self.activePanel
end

-- 获取面板实例
function PanelManager:getPanel(name)
    return self.panelInstances[name]
end

-- 获取面板状态
function PanelManager:getPanelState(name)
    return self.panelStates[name]
end

-- 处理面板互斥性
function PanelManager:handlePanelExclusivity(name, panel)
    local panelType = panel.panelType
    
    if panelType == "fullscreen" or panelType == "modal" then
        -- 全屏或模态面板，隐藏其他面板
        self:hideAllExcept(name)
    elseif panelType == "popup" then
        -- 弹窗面板，隐藏其他弹窗
        self:hidePopups(name)
    end
end

-- 隐藏除指定面板外的所有面板
function PanelManager:hideAllExcept(exceptName)
    for name, state in pairs(self.panelStates) do
        if name ~= exceptName and state == "visible" then
            local panel = self.panelInstances[name]
            if panel and panel.panelType ~= "background" then
                self:hide(name)
            end
        end
    end
end

-- 隐藏所有弹窗
function PanelManager:hidePopups(exceptName)
    for name, panel in pairs(self.panelInstances) do
        if name ~= exceptName and panel.panelType == "popup" and self.panelStates[name] == "visible" then
            self:hide(name)
        end
    end
end

-- 添加到面板栈
function PanelManager:addToStack(name)
    -- 移除已存在的记录
    self:removeFromStack(name)
    
    -- 添加到栈顶
    table.insert(self.panelStack, name)
    
    -- 限制栈大小
    if #self.panelStack > 20 then
        table.remove(self.panelStack, 1)
    end
end

-- 从面板栈中移除
function PanelManager:removeFromStack(name)
    for i = #self.panelStack, 1, -1 do
        if self.panelStack[i] == name then
            table.remove(self.panelStack, i)
        end
    end
end

-- 获取栈顶可见面板
function PanelManager:getTopVisiblePanel()
    for i = #self.panelStack, 1, -1 do
        local name = self.panelStack[i]
        if self.panelStates[name] == "visible" then
            return name
        end
    end
    return nil
end

-- 关闭所有面板
function PanelManager:hideAll()
    for name, state in pairs(self.panelStates) do
        if state == "visible" then
            self:hide(name)
        end
    end
end

-- 获取所有可见面板
function PanelManager:getVisiblePanels()
    local visible = {}
    for name, state in pairs(self.panelStates) do
        if state == "visible" then
            table.insert(visible, name)
        end
    end
    return visible
end

-- 获取面板统计信息
function PanelManager:getStats()
    local stats = {
        registered = 0,
        created = 0,
        visible = 0,
        hidden = 0,
        destroyed = 0
    }
    
    for _, state in pairs(self.panelStates) do
        if state == "registered" then
            stats.registered = stats.registered + 1
        elseif state == "created" or state == "hidden" then
            stats.created = stats.created + 1
            if state == "hidden" then
                stats.hidden = stats.hidden + 1
            end
        elseif state == "visible" then
            stats.created = stats.created + 1
            stats.visible = stats.visible + 1
        elseif state == "destroyed" then
            stats.destroyed = stats.destroyed + 1
        end
    end
    
    return stats
end

return PanelManager
