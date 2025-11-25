--[[
    BasePanel.lua - UI面板基类

    职责：
    - 提供Panel的基础生命周期管理
    - 统一的UI查找逻辑
    - 统一的显示/隐藏接口

    参考xplants项目的BasePanel实现
    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local BasePanel = {}
BasePanel.__index = BasePanel

-- 创建新的Panel实例
-- @param panelName 面板名称（对应UI资源中的Panel名称）
-- @param layerName UI层级名称（NORMAL/POPUP/SYSTEM等）
function BasePanel.new(panelName, layerName)
    local self = setmetatable({}, BasePanel)

    self.panelName = panelName or "UnknownPanel"
    self.layerName = layerName or "Layer_NORMAL"
    self.isVisible = false
    self.sgf = nil
    self.log = nil
    self.events = nil
    self.uiRoot = nil
    self.components = {}

    return self
end

-- 初始化面板
-- @param sgf SGF框架实例
-- @param system 业务系统实例（可选）
function BasePanel:init(sgf, system)
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.log:info(self.panelName .. " initializing...")

    -- 查找UI根节点
    self:findUIRoot()

    -- 查找UI组件
    self:findUIComponents()

    -- 绑定事件
    self:bindEvents()

    self.log:info(self.panelName .. " initialized successfully")

    return true
end

-- 查找UI根节点（标准实现，子类通常不需要重写）
function BasePanel:findUIRoot()
    local player = game:GetService("Players").LocalPlayer
    if not player then
        self.log:error("LocalPlayer not found")
        return
    end

    -- 直接通过UI节点树层级访问
    local playerGui = player.PlayerGui
    if not playerGui then
        self.log:error("PlayerGui not found")
        return
    end

    local mainUIPanel = playerGui.MainUIPanel
    if not mainUIPanel then
        self.log:error("MainUIPanel not found in PlayerGui")
        return
    end

    -- 通过层级访问Layer
    local layer = mainUIPanel[self.layerName]
    if not layer then
        self.log:error(self.layerName .. " not found in MainUIPanel")
        return
    end

    -- 访问Panel
    local uiRoot = layer[self.panelName]
    if uiRoot then
        self.uiRoot = uiRoot
        self.log:debug(self.panelName .. " UI root found")
    else
        self.log:warning(self.panelName .. " UI not found in " .. self.layerName)
    end
end

-- 查找UI组件（子类实现）
function BasePanel:findUIComponents()
    -- 子类重写此方法，查找具体的UI组件
    -- 例如：
    -- self.components.button = self.uiRoot:FindFirstChild("Button")
end

-- 绑定事件（子类实现）
function BasePanel:bindEvents()
    -- 子类重写此方法，绑定事件监听器
    -- 例如：
    -- self.events:on(EventID.SomeEvent, function(data)
    --     self:onSomeEvent(data)
    -- end)
end

-- 显示面板
function BasePanel:show()
    if not self.uiRoot then
        self.log:warning(self.panelName .. " cannot show: uiRoot is nil")
        return
    end

    if self.isVisible then
        return
    end

    self.log:debug(self.panelName .. " showing")

    self.uiRoot.Visible = true
    self.isVisible = true

    -- 调用子类的onShow钩子
    self:onShow()
end

-- 隐藏面板
function BasePanel:hide()
    if not self.uiRoot then
        return
    end

    if not self.isVisible then
        return
    end

    self.log:debug(self.panelName .. " hiding")

    self.uiRoot.Visible = false
    self.isVisible = false

    -- 调用子类的onHide钩子
    self:onHide()
end

-- 切换显示/隐藏
function BasePanel:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

-- 显示时的钩子方法（子类可重写）
function BasePanel:onShow()
    -- 子类可以重写此方法，在显示时执行特定逻辑
end

-- 隐藏时的钩子方法（子类可重写）
function BasePanel:onHide()
    -- 子类可以重写此方法，在隐藏时执行特定逻辑
end

-- 更新方法（可选，由子类实现）
function BasePanel:update(dt)
    -- 子类可以重写此方法，实现每帧更新逻辑
end

-- 销毁面板
function BasePanel:destroy()
    self.log:debug(self.panelName .. " destroying")

    -- 隐藏UI
    self:hide()

    -- 清理引用
    self.uiRoot = nil
    self.components = {}
    self.sgf = nil
    self.log = nil
    self.events = nil
end

-- 辅助方法：查找组件
-- @param componentPath 组件路径，支持层级查找（例如："Container.Button"）
function BasePanel:getComponent(componentPath)
    if not self.uiRoot then
        return nil
    end

    local parts = {}
    for part in string.gmatch(componentPath, "[^.]+") do
        table.insert(parts, part)
    end

    local current = self.uiRoot
    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then
            return nil
        end
    end

    return current
end

return BasePanel
