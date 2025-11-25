--[[
    UIPanelTemplate.lua - UI面板模板

    使用说明：
    1. 复制此模板文件到 StartPlayer/StarterPlayerScripts/
    2. 将所有 [PanelName] 替换为实际的面板名称
    3. 在StarterGui/MainUIPanel/对应层级中创建UI节点树（设计时）
    4. 运行时UI会自动复制到玩家的PlayerGui，代码从PlayerGui查找UI
    5. 根据需要重写BasePanel的钩子方法

    示例：
    - [PanelName] -> InventoryPanel
    - [面板功能描述] -> 背包面板，显示玩家物品
    注意：关联的业务系统在ClientMain中通过PanelManager注册时指定
    - [LayerName] -> Layer_NORMAL (或 Layer_BACKGROUND, Layer_POPUP, Layer_SYSTEM)

    Version: 2.0.0 (使用BasePanel继承)
]]

-- ========================================
-- 加载BasePanel基类（必需）
-- ========================================
local MainStorage = game:GetService("MainStorage")
local Framework = MainStorage:WaitForChild("Framework")
local BasePanel = require(Framework.UI.BasePanel)

-- ========================================
-- 创建面板类，继承BasePanel（必需）
-- ========================================
local [PanelName] = setmetatable({}, {__index = BasePanel})

-- ========== 基础信息 ==========
[PanelName].panelName = "[PanelName]"  -- 面板名称（必需）
[PanelName].layerName = "[LayerName]"  -- UI层级名称（Layer_NORMAL/Layer_POPUP/Layer_BACKGROUND/Layer_SYSTEM）
[PanelName].panelType = "normal"  -- background | normal | overlay | popup | modal | fullscreen
[PanelName].isStaticUI = true  -- true=从PlayerGui加载静态UI(运行时)，false=动态创建UI

-- ========================================
-- 构造函数（必需）
-- ========================================
function [PanelName].new()
    local self = setmetatable({}, {__index = [PanelName]})

    -- 复制类的静态属性到实例
    self.panelName = [PanelName].panelName
    self.layerName = [PanelName].layerName
    self.panelType = [PanelName].panelType
    self.isStaticUI = [PanelName].isStaticUI

    -- 实例数据
    self.controls = {}
    self.customData = {}

    return self
end

-- ========================================
-- 重写BasePanel方法（必需）
-- ========================================

--[[
    创建UI元素（重写BasePanel方法）
    如果isStaticUI=true，从PlayerGui加载静态UI节点(运行时从玩家的PlayerGui查找)
    如果isStaticUI=false，动态创建UI元素
]]
function [PanelName]:createUIElements()
    -- 从玩家的PlayerGui加载UI节点（运行时UI必须从PlayerGui查找，不是StarterGui）
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        print("[[PanelName]] LocalPlayer not found")
        return false
    end

    local playerGui = localPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then
        print("[[PanelName]] PlayerGui not found")
        return false
    end

    local mainUIPanel = playerGui:FindFirstChild("MainUIPanel")
    if not mainUIPanel then
        print("[[PanelName]] MainUIPanel not found in PlayerGui")
        return false
    end

    local layer = mainUIPanel:FindFirstChild("[LayerName]")  -- 例如：Layer_NORMAL
    if not layer then
        print("[[PanelName]] [LayerName] not found in MainUIPanel")
        return false
    end

    local uiNode = layer:FindFirstChild("[PanelName]UI")
    if not uiNode then
        print("[[PanelName]] UI node not found in [LayerName]")
        return false
    end

    self.uiRoot = uiNode
    print("[[PanelName]] UI loaded successfully from PlayerGui/MainUIPanel/[LayerName]/[PanelName]UI")

    -- 缓存常用控件引用
    self.controls.titleLabel = self:findControl("TitleLabel")
    self.controls.closeButton = self:findControl("CloseButton")
    self.controls.contentPanel = self:findControl("ContentPanel")
    -- ... 缓存其他控件

    print("[[PanelName]] Controls initialized")

    return true
end

--[[
    绑定事件（重写BasePanel方法）
    绑定UI控件的交互事件
]]
function [PanelName]:bindEvents()
    if not self.sgf or not self.sgf.events then
        print("[[PanelName]] No events system available")
        return
    end

    -- 绑定关闭按钮
    if self.controls.closeButton then
        self:connectEvent(self.controls.closeButton, "Click", function()
            self:onCloseButtonClick()
        end)
    end

    -- 绑定其他按钮事件
    -- ...

    -- 监听业务系统事件（如果面板关联了业务系统）
    -- 注意：systemName 由 PanelManager 在注册时指定
    -- self.sgf.events:on("SystemNameDataUpdated", function(data)
    --     self:onDataUpdated(data)
    -- end)

    print("[[PanelName]] Event listeners bound")
end

--[[
    初始化数据（重写BasePanel方法）
    在UI创建后、显示前初始化数据
]]
function [PanelName]:initializeData()
    -- 初始化自定义数据
    self.customData = {
        -- ...
    }

    -- 更新UI显示
    self:updateAllUI()
end

--[[
    显示后回调（重写BasePanel方法）
    面板显示动画完成后调用
]]
function [PanelName]:onAfterShow(data)
    print("[[PanelName]] Shown")

    -- 刷新显示
    self:updateAllUI()

    -- 播放音效等
end

--[[
    隐藏后回调（重写BasePanel方法）
    面板隐藏动画完成后调用
]]
function [PanelName]:onAfterHide()
    print("[[PanelName]] Hidden")

    -- 清理临时数据等
end

-- ========================================
-- 业务逻辑方法（自定义）
-- ========================================

--[[
    更新所有UI显示
]]
function [PanelName]:updateAllUI()
    -- 更新标题
    if self.controls.titleLabel then
        self.controls.titleLabel.Title = self.customData.title or "[Panel Title]"
    end

    -- 更新内容
    self:updateContent()
end

--[[
    更新内容区域
]]
function [PanelName]:updateContent()
    -- 根据数据更新内容显示
    -- 例如：更新列表、更新数值等
end

-- ========================================
-- 事件处理方法（自定义）
-- ========================================

--[[
    关闭按钮点击
]]
function [PanelName]:onCloseButtonClick()
    print("[[PanelName]] Close button clicked")
    self:hide()
end

--[[
    数据更新事件处理
]]
function [PanelName]:onDataUpdated(data)
    print("[[PanelName]] Data updated:", data)

    -- 如果面板可见，更新显示
    if self.isVisible then
        self.customData = data
        self:updateAllUI()
    end
end

-- ========================================
-- 工具方法
-- ========================================

--[[
    查找控件（递归查找）
]]
function [PanelName]:findControl(controlName, recursive)
    if not self.uiRoot then
        return nil
    end

    recursive = recursive ~= false  -- 默认递归查找

    if recursive then
        return self:findControlRecursive(self.uiRoot, controlName)
    else
        return self.uiRoot:FindFirstChild(controlName)
    end
end

--[[
    递归查找控件
]]
function [PanelName]:findControlRecursive(parent, controlName)
    -- 检查 parent 是否为 nil
    if not parent then
        return nil
    end

    -- 使用 Children 属性而不是 GetChildren() 方法
    local children = parent.Children
    if not children then
        return nil
    end

    for _, child in ipairs(children) do
        if child.Name == controlName then
            return child
        end

        local found = self:findControlRecursive(child, controlName)
        if found then
            return found
        end
    end

    return nil
end

return [PanelName]

