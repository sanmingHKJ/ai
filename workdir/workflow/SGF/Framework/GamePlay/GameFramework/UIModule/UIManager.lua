-- 说明:UI管理器
-- 日期:2025年1月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIDefines = GFScript("UIModule.UIDefines")
local UISettings = GFScript("UIModule.UISettings")
local UIUtils = GFScript("UIModule.UIUtils")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UITweenUtils = GFScript("UIModule.UITweenUtils")

local WidgetFactory = {}

local UIManager = {}

-- 存储所有UIView类
local viewClasses = {}
-- 存储所有UIView实例
local openedViews = {}  -- 已打开的视图堆栈
local cachedViews = {}  -- 缓存的视图

local layerViews = {}

-- 存储需要重绘的控件
local needRefreshWidgets = {}
local widgetRefreshing = false
local addRefreshWidgets = {}

-- 存储可以放下控件
local dropableWidgets = {}

--是否开启触摸调试
local touchDebugEnabled = false

--遮罩视图栈
local maskViewStack = {}

-- 存储所有组
local groups = {}

-- 存储所有顶层视图
local topViewStack = {}

--双击时间
UIManager.doubleClickTime = 0.3
--双击距离
UIManager.doubleClickDistance = 20
--长按时间
UIManager.longPressTime = 0.5

--初始化
function UIManager:Init()
    if touchDebugEnabled and UIUtils:IsClient() then
        local UIManageService = game:GetService("UIManageService")
        if UIManageService.TouchNode then
            UIManageService.TouchNode:Connect(function(node)
                UILog:Error("TouchNode: "..node.Name)
            end)
        end
    end
    
    self:RegisterViewClass(GFScript("UIModule.UIFocusMask"))
    self:RegisterViewClass(GFScript("UIModule.UIInputSystem"))
end

--更新
function UIManager:Update(dt)
    widgetRefreshing = true
    for widget, _ in pairs(needRefreshWidgets) do
        if not UIClass.IsExpired(widget) then
            widget:OnRefresh()
            widget:HandleRefreshCallback()
        end
    end
    needRefreshWidgets = {}
    widgetRefreshing = false

    for widget, _ in pairs(addRefreshWidgets) do
        self:RefreshWidget(widget)
    end
    addRefreshWidgets = {}

    for _, view in ipairs(openedViews) do
        view:Update(dt)
    end
end

--设置模板根节点
function UIManager:SetTemplateRootNode(node)
    self.templateRootNode = node
    for _, view in ipairs(self.templateRootNode.Children) do
        view.Visible = false
    end
end

--获取模板根节点
function UIManager:GetTemplateUINode(path)
    if not self.templateRootNode then
        UILog:Error("UIManager:GetTemplateUINode - templateRootNode is nil")
        return nil
    end
    return UIUtils:GetNode(path, self.templateRootNode)
end

--设置节点池所用节点
function UIManager:SetNodePoolNode(node)
    self.nodePoolNode = node
    self.nodePoolNode.Visible = false
end

--获取节点池所用节点
function UIManager:GetNodePoolNode()
    return self.nodePoolNode
end

--注册UIView类
function UIManager:RegisterViewClass(viewClass)
    viewClasses[viewClass.__cname] = viewClass
end

-- 创建并注册UIView
function UIManager:LoadView(viewName, callback)
    local viewClass = viewClasses[viewName]
    if not viewClass then
        UILog:Error("UIManager:CreateView - View class not found: " .. viewName)
        return
    end

    local view = viewClass.New()
    view:SetName(viewName)
    cachedViews[viewName] = view

    view:Load(false, callback)
    return view
end

--销毁UIView
function UIManager:UnloadView(viewName)
    local view = cachedViews[viewName]
    if view then
        cachedViews[viewName] = nil
        view:Unload(function()
            view:Finit()
            view:Destroy()
        end)
    end
end

-- 打开UIView
function UIManager:OpenView(viewName, parentView, ...)
    local view = cachedViews[viewName]
    local args = {...}
    if not view then
        view = self:LoadView(viewName, function(view)
            --设置主视图
            self:SetupMasterView(view)
            view:Init()
            view:Enter(unpack(args))
            view:Show()
            if parentView then
                parentView:AddSubView(view)
            else
                self:AddOpenedView(view)
            end
        end)
    elseif not view:IsShow() then
        --设置主视图
        self:SetupMasterView(view)
        view:Enter(unpack(args))
        view:Show()
        if parentView then
            parentView:AddSubView(view)
        else
            self:AddOpenedView(view)
        end
    end


    if self:IsNeedMask(view) then
        --插入到最后
        UIUtils:InsertUnique(maskViewStack, view)
        self:SetupMask(view)
    elseif view:GetStyle() == UIDefines.EViewStyle.FullScreen then
        --关闭其他非常驻视图
        local needCloseViews = {}
        --反向循环
        for i = #topViewStack, 1, -1 do
            local v = topViewStack[i]
            if UIClass.IsExpired(v) then
                table.remove(topViewStack, i)
            elseif not v:IsPersistent() and not v:IsMaster() then
                table.insert(needCloseViews, v)
            end
        end
        for _, v in ipairs(needCloseViews) do
            self:CloseView(v.name)
        end
    end

    if not view.parentView then
        UIUtils:InsertUnique(topViewStack, view)
    end

    view:OnOpen()

    return view
end

-- 关闭UIView
function UIManager:CloseView(viewName)
    local view = self:GetOpenedView(viewName)
    if not view then
        UILog:Error("UIManager:CloseView - View not found: " .. viewName)
        return
    end

    --关闭栈顶视图
    if view:IsMaster() then
        if #view.contentViews > 0 then
            local contentView = view.contentViews[#view.contentViews]
            self:CloseView(contentView.name)
            return
        end
    end

    view:OnClose()

    self:RemoveOpenedView(view)
    if view:IsShow() then
        view:Hide()
        view:Leave()
    end

    if self:IsNeedMask(view) then
        for i, v in ipairs(maskViewStack) do
            if v == view then
                table.remove(maskViewStack, i)
                break
            end
        end
    end

    if #maskViewStack > 0 then
        local maskView = maskViewStack[#maskViewStack]
        self:SetupMask(maskView)
    else
        if self.mask then
            self.mask.Visible = false
        end
    end

    if not view.parentView then
        for _, v in ipairs(topViewStack) do
            if v == view then
                table.remove(topViewStack, i)
                break
            end
        end
    end

    if not view:IsCacheSuport() and not view:IsPersistent() then
        self:UnloadView(viewName)
    end
end

--更新视图
function UIManager:UpdateView(viewName, ...)
    local view = self:GetOpenedView(viewName)
    if not view then
        return
    end
    
    local args = {...}
    view:Leave()
    view:Enter(unpack(args))
end

--关闭所有打开的界面
function UIManager:CloseAllViews()
    local needCloseViews = {}
    for _, view in ipairs(openedViews) do
        table.insert(needCloseViews, view)
    end
    for _, view in ipairs(needCloseViews) do
        self:CloseView(view.name)
    end
end

-- 获取UIView实例
function UIManager:GetView(viewName)
    return cachedViews[viewName]
end

--是否打开视图
function UIManager:IsOpen(viewName)
    return self:GetOpenedView(viewName) and true or false
end

--切换视图
function UIManager:ToggleView(viewName)
    if self:IsOpen(viewName) then
        self:CloseView(viewName)
    else
        self:OpenView(viewName)
    end
end

--获取打开的UIView数量
function UIManager:GetOpenedViewCount()
    return #openedViews
end

function UIManager:GetOpenedView(name)
    for _, view in ipairs(openedViews) do
        if view.name == name then
            return view
        end
    end
    return nil
end

function UIManager:AddOpenedView(view)
    table.insert(openedViews, view)
end

function UIManager:RemoveOpenedView(view)
    for i, v in ipairs(openedViews) do
        if v == view then
            table.remove(openedViews, i)
            break
        end
    end
end

--遍历所有打开的UIView
function UIManager:ForEachOpenedViews(func)
    for _, view in ipairs(openedViews) do
        func(view)
    end
end

--获取视图层级
function UIManager:GetLayer(layer)
    return layerViews[layer]
end

--获取顶层视图
function UIManager:GetTopLayer()
    return layerViews[UIDefines.EViewLayer.Top]
end

--添加视图层级
function UIManager:AddLayer(layer, view)
    layerViews[layer] = view
end 

--创建控件
function UIManager:CreateWidget(typeName, bindObj, managedBindObj, parentView, ...)
    local widget = nil
    if type(typeName) == "string" then
        if not WidgetFactory[typeName] then
            local widgetClass = GFScript("UIModule.UIWidget." .. typeName)
            if not widgetClass then
                widgetClass = GFScript("UIModule.UIExtends." .. typeName)
            end
            if not widgetClass then
                UILog:Error("CreateWidget: widgetClass not found: " .. typeName)
                return nil
            end
            WidgetFactory[typeName] = widgetClass
        end
        local factory = WidgetFactory[typeName]
        widget = factory.New(parentView)
    else
        widget = typeName.New(parentView)
    end
    if not widget:Init(bindObj, managedBindObj, ...) then
        UILog:Error("CreateWidget: Init failed")
        widget:Destroy()
        return nil
    end
    return widget
end

--重绘控件
function UIManager:RefreshWidget(widget)
    if not widget then
        UILog:Error("RefreshWidget: widget is nil")
        return
    end
    if widgetRefreshing then    
        addRefreshWidgets[widget] = true
    else
        needRefreshWidgets[widget] = true
    end
end

--强制重绘控件
function UIManager:ForceRefreshWidget(widget)
    if not widget then
        UILog:Error("ForceRefreshWidget: widget is nil")
        return
    end
    if needRefreshWidgets[widget] then
        needRefreshWidgets[widget] = nil
        widget:OnRefresh()
        widget:HandleRefreshCallback()
    end
end
--添加控件到组
function UIManager:AddWidgetToGroup(widget, group)
    if not groups[group] then
        groups[group] = {}
    end
    table.insert(groups[group], widget)
end

--移除控件从组
function UIManager:RemoveWidgetFromGroup(widget)
    for group, widgets in pairs(groups) do
        for i, w in ipairs(widgets) do
            if w == widget then
                table.remove(widgets, i)
                break
            end
        end
    end
end

--获取组
function UIManager:GetGroup(group)
    return groups[group]
end

--遍历组
function UIManager:ForEachGroup(group, func)
    for _, widget in ipairs(groups[group]) do
        func(widget)
    end
end

--设置主视图
function UIManager:SetupMasterView(uiView)
    local master = uiView:GetMaster()
    if not UIUtils:IsNullOrEmpty(master) then
        local masterView = self:OpenView(master)
        uiView:SetMasterView(masterView)
    end
end

--是否需要遮罩
function UIManager:IsNeedMask(uiView)
    return not uiView.parentView and (uiView:GetStyle() == UIDefines.EViewStyle.Popup or uiView:GetStyle() == UIDefines.EViewStyle.Modal)
end

--设置遮罩
function UIManager:SetupMask(uiView)
    local alpha = 0.5
    if not self.mask then
        self.mask = SandboxNode.New("UIImage")
        self.mask.Name = "MaskView"
        self.mask.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        self.mask.Icon = UIUtils:FullSpritePath(UISettings:GetGenericWhiteSprite())
        self.mask.ClickPass = false
        self.mask.IsNotifyEventStop = true
        self.mask.Click:Connect(function(node, issuccess, mousepos)
            if #maskViewStack > 0 then
                local popupView = maskViewStack[#maskViewStack]
                if popupView:GetStyle() == UIDefines.EViewStyle.Popup then
                    self:CloseView(popupView.name)
                end
            end
        end)
        
        UIUtils:SetColor(self.mask, Color.New(0, 0, 0))
    end
    self.mask.Parent = uiView.rootNode
    UIUtils:SetFullScreenSize(self.mask)
    UIUtils:SetSiblingIndex(self.mask, 1)

    self.mask.Visible = true

    UIUtils:SetAlpha(self.mask, alpha)
    UITweenUtils:Tween(self.mask, {
        {"AlphaTo", alpha, 0.25}, {"Ease", "EaseInCubic"},
    }):Tag("MaskIn"):OnComplete(function()
    end):Start()
end

--显示焦点遮罩
function UIManager:FocusMask(control, expand)
    if self.focusMaskControl == control then
        return
    end
    self:UnFocusMask()
    if not self.focusMask then
        self.focusMask = self:OpenView("UIFocusMask")
    end
    self.focusMask:Focus(control, expand)
    self.focusMaskControl = control
end

--隐藏焦点遮罩
function UIManager:UnFocusMask()
    if self.focusMask then
        self.focusMask:Unfocus()
        self:CloseView(self.focusMask.name)
        self.focusMask = nil
        self.focusMaskControl = nil
    end
end

--显示十字准星
function UIManager:OpenCrosshair()
    if not self.crosshair then
        self.crosshair = self:OpenView("UICrosshair")
    end
end

--关闭十字准星
function UIManager:CloseCrosshair()
    if self.crosshair then
        self:CloseView(self.crosshair.name)
        self.crosshair = nil
    end
end

--获取十字准星
function UIManager:GetCrosshair()
    -- if not self.crosshair then
    --     self.crosshair = self:OpenView("UICrosshair")
    -- end
    return self.crosshair
end

--显示输入系统
function UIManager:OpenInputSystem()
    if not self.inputSystem then
        self.inputSystem = self:OpenView("UIInputSystem")
    end
end

--关闭输入系统
function UIManager:CloseInputSystem()
    if self.inputSystem then
        self:CloseView(self.inputSystem.name)
        self.inputSystem = nil
    end
end

--获取输入系统
function UIManager:GetInputSystem()
    return self.inputSystem
end

--设置HUD类
function UIManager:SetHudClass(hudClass)
    self.hudClass = hudClass
end

--获取HUD显示
function UIManager:GetHud()
    if not self.hud then
        self.hud = self:OpenView(self.hudClass or "UIHud")
    end
    return self.hud
end

--设置拾取通知类
function UIManager:SetPickupNotificationClass(pickupNotificationClass)
    self.pickupNotificationClass = pickupNotificationClass
end

--获取拾取通知类
function UIManager:GetPickupNotification()
    if not self.pickupNotification then
        self.pickupNotification = self:OpenView(self.pickupNotificationClass or "UIPickupNotification")
    end
    return self.pickupNotification
end

--显示拾取通知
function UIManager:OpenPickupNotification()
    if not self.pickupNotification then
        self.pickupNotification = self:OpenView(self.pickupNotificationClass or "UIPickupNotification")
    end
end

--隐藏拾取通知
function UIManager:ClosePickupNotification()
    if self.pickupNotification then
        self.pickupNotification:Close()
        self.pickupNotification = nil
    end
end

-- tip飘字 msg内容 duration持续时间 priority优先级
function UIManager:ShowTip(msg, duration, priority)
    if not self.tips then
        self.tips = self:OpenView("UITips")
    end
    self.tips:ShowTip(msg, duration or 2.5, priority or 5)
end

--加载视图类
function UIManager:LoadViewClass(view)
    for _, subView in ipairs(view.Children) do
        if subView.ClassType == 'ModuleScript' then
            local viewClass = require(subView)
            if viewClass.__cname then
                self:RegisterViewClass(viewClass)
            end
        end
        self:LoadViewClass(subView)
    end
end

--设置Item模板
function UIManager:SetItemTemplate(templateNode)
    self.itemTemplateNode = templateNode
end

--获取Item的模板
function UIManager:FindItemTemplate(templateName)
    return UIUtils:FindChildControl(self.itemTemplateNode, templateName, true)
end

--添加可以放下控件
function UIManager:AddDropableWidget(widget)
    dropableWidgets[widget.dropableId] = widget
end

--移除可以放下控件  
function UIManager:RemoveDropableWidget(widget)
    dropableWidgets[widget.dropableId] = nil
end

--遍历可以放下控件
function UIManager:ForEachDropableWidgets(func)
    for _, widget in pairs(dropableWidgets) do
        if func(widget) then
            break
        end
    end
end

--获取指定位置的可以放下控件
function UIManager:GetDropableWidgetAtPos(pos)
    for _, widget in pairs(dropableWidgets) do
        if UIUtils:IsVisibleInHierarchy(widget.bindObj) then
            local screenRect = widget:GetScreenRect()
            if screenRect:Contains(pos.x, pos.y) then
                return widget
            end
        end
    end
    return nil
end

return UIManager