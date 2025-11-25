-- 说明:UI视图
-- 日期:2025年1月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local GlobalEvent = GFScript("CoreModule.GlobalEvent")
local UITimer = GFScript("UIModule.UITimer")
local UIUtils = GFScript("UIModule.UIUtils")
local UIWidgetCreator = GFScript("UIModule.UIWidgetCreator")
local UIDefines = GFScript("UIModule.UIDefines")

local UIView = UIClass.New("UIView")
local LoadStates = {
    Unload = "Unload",
    Load = "Load",
    Enter = "Enter",
    Show = "Show",
}

--生命周期
--1.初始化
--2.加载
--3.初始化
--4.进入
--5.显示
--6.隐藏
--7.卸载
--8.反初始化
--9.清除定时器


--层级
UIView.Layer = UIDefines.EViewLayer.Normal
--UI根节点
UIView.UIRoot = ""
--主视图
UIView.Master = ""
--渲染索引
UIView.RenderIndex = nil
--视图风格
function UIView:Constructor()
    self.subViews = {}
    self.loadState = LoadStates.Unload
    self.isShow = false
    self.isGlobalEventSleep = false
    self.UIManager = GFScript("UIModule.UIManager")
    self.delayCallTimers = {}
    self.timerIds = {}
    self.eventListeners = {}
    self.gapMap = {}


    local rootPath = rawget(self.class, "UIRoot")
    if UIUtils:IsNullOrEmpty(rootPath) then
        self.rootNode = SandboxNode.New("UIRoot")
        self.rootNode.Name = self.__cname
    else
        self.rootNode = self.UIManager:GetTemplateUINode(rootPath)
    end
    local layer = rawget(self.class, "Layer") or UIDefines.EViewLayer.Normal
    self.layerNode = self.UIManager:GetLayer(layer)

    self.name = ""

    self.widgets = {}
    self.widgetCaches = {}
    self.contentViews = {}
end

function UIView:Destructor()  
    self:ClearAllTimers()
    self:ClearAllDelayCall()
    self:ClearAllEventListeners()
    self:ClearAllWidgets()

    self:ClearAllContentViews()
end

function UIView:OnConstructor()
    if GlobalEvent then
        GlobalEvent:Setup(self)
    end
end

--销毁
function UIView:OnDestructor()

end

--设置名称
function UIView:SetName(name)
    self.name = name
end

--获取名称
function UIView:GetName()
    return self.name
end

--是否常驻
function UIView:IsPersistent()
    local persistent = rawget(self.class, "Persistent")
    if persistent ~= nil then
        return persistent
    end
    return false
end

--是否缓存支持
function UIView:IsCacheSuport()
    local cacheSuport = rawget(self.class, "CacheSuport")
    if cacheSuport ~= nil then
        return cacheSuport
    end
    return true
end

--获取主视图
function UIView:GetMaster()
    return rawget(self.class, "Master") or ""
end

function UIView:GetStyle()
    return rawget(self.class, "Style") or UIDefines.EViewStyle.Normal
end

--获取渲染索引
function UIView:GetRenderIndex()
    local renderIndex = rawget(self.class, "RenderIndex")
    if renderIndex ~= nil then
        return renderIndex
    end
    return nil
end
--是否是主视图
function UIView:IsMaster()
    return self:GetStyle() == UIDefines.EViewStyle.Master
end

--设置主视图
function UIView:SetMasterView(masterView)
    if self.masterView then
        self.masterView:PopContentView(self)
    end
    self.masterView = masterView
    if self.masterView then
        self.masterView:PushContentView(self)
    end
end

--获取主视图
function UIView:GetMasterView()
    return self.masterView
end

--添加内容视图
function UIView:PushContentView(view)
    if not view then
        UILog:Error("UIView:PushContentView: view is nil")
        return
    end
    table.insert(self.contentViews, view)

    UIUtils:SetParent(self.rootNode, view.rootNode)
    UIUtils:SetSiblingIndex(self.rootNode, 1)
    view:OnSetupMasterView(self)
end

--移除内容视图
function UIView:PopContentView()
    if #self.contentViews > 0 then
        table.remove(self.contentViews, #self.contentViews)
        if #self.contentViews == 0 then
            self:Close()
        else
            local view = self.contentViews[#self.contentViews]
            UIUtils:SetParent(self.rootNode, view.rootNode)
            UIUtils:SetSiblingIndex(self.rootNode, 1)
            view:OnSetupMasterView(self)
        end
    end
end

--移除内容视图
function UIView:RemoveContentView(view)
    if view then
        for i,v in ipairs(self.contentViews) do
            if v == view then
                table.remove(self.contentViews, i)
                if #self.contentViews == 0 then
                    self:Close()
                else
                    local view = self.contentViews[#self.contentViews]
                    UIUtils:SetParent(self.rootNode, view.rootNode)
                    UIUtils:SetSiblingIndex(self.rootNode, 1)
                    view:OnSetupMasterView(self)
                end
                break
            end
        end
    end
end

--清除所有内容视图
function UIView:ClearAllContentViews()
    self.contentViews = {}
end

--当设置主视图的时候
function UIView:OnSetupMasterView(masterView)

end

--初始化
function UIView:Load(sync, callback)
    self.loadState = LoadStates.Load
    if self.rootNode and self.layerNode then
        self.rootNodeBackupParent = self.rootNode.Parent
        self.rootNode.Parent = self.layerNode
        UIUtils:SetSiblingIndex(self.rootNode, #self.layerNode.Children + 1)
        local renderIndex = self:GetRenderIndex()
        if renderIndex then
            self.rootNode.RenderIndex = renderIndex
        end
    end
    if callback then
        callback(self)
    end
end


--初始化
function UIView:Init()
    self:InitControls()
    self:InitEvents()
end

--初始化控件
function UIView:InitControls()

end

--初始化事件
function UIView:InitEvents()


end


--进入
function UIView:Enter()
    for _, subView in pairs(self.subViews) do
        subView:Enter()
    end
end

--显示
function UIView:Show()
    self.isGlobalEventSleep = false
    self.isShow = true
    if self.rootNode then
        self.rootNode.Visible = true
    end
    -- Display the view
    for _, subView in pairs(self.subViews) do
        subView:Show()
    end
end

--隐藏
function UIView:Hide()
    self.isGlobalEventSleep = true
    self.isShow = false
    if self.rootNode then
        self.rootNode.Visible = false
    end
    -- Hide the view
    for _, subView in pairs(self.subViews) do
        subView:Hide()
    end
end

--是否显示
function UIView:IsShow()
    return self.isShow
end

--离开
function UIView:Leave()
    -- Leave the view (e.g., transition out)
    for _, subView in pairs(self.subViews) do
        subView:Leave()
    end
end

--卸载事件
function UIView:FinitEvents()

end

--卸载控件
function UIView:FinitControls()

end

--卸载
function UIView:Unload(callback)

    if self.rootNode and self.rootNodeBackupParent then
        self.rootNode.Parent = self.rootNodeBackupParent
        self.rootNodeBackupParent = nil
    end
    self.loadState = LoadStates.Unload
    if callback then
        callback(self)
    end
    self.layerNode = nil
    self.rootNode = nil

end

--是否加载
function UIView:IsLoaded()
    return self.loadState == LoadStates.Loaded
end

--是否卸载
function UIView:IsUnloaded()
    return self.loadState == LoadStates.Unload
end

--是否加载中
function UIView:IsLoading()
    return self.loadState == LoadStates.Loading
end

--卸载
function UIView:Finit()
    -- Finalize and clean up
    for _, subView in pairs(self.subViews) do

        subView:Finit()
    end
    self.subViews = {}

    self:FinitEvents()
    self:FinitControls()
end

--关闭
function UIView:Close()
    if self.UIManager then
        self.UIManager:CloseView(self.name)
    end
end

--打开
function UIView:OnOpen()
end

--关闭
function UIView:OnClose()
    if self.masterView then
        self.masterView:RemoveContentView(self)
        self.masterView = nil
    end
end

--添加子视图
function UIView:AddSubView(subView)



    if subView and not self.subViews[subView] then
        self.subViews[subView] = subView
        subView:SetParentView(self)
    end
end

--移除子视图
function UIView:RemoveSubView(subView)
    if subView and self.subViews[subView] then
        self.subViews[subView] = nil
        subView:SetParentView(nil)
    end
end

--获取子视图
function UIView:GetSubView(subViewName)
    for subView, _ in pairs(self.subViews) do
        if subView.name == subViewName then
            return subView
        end
    end
    return nil
end

--更新
function UIView:Update(dt)
    for _, subView in pairs(self.subViews) do

        subView:Update(dt)
    end
    for obj, time in pairs(self.gapMap) do
        self.gapMap[obj] = time - dt
    end
end

--设置视图层级
function UIView:SetOrder(order)
    self.order = order
end

--定时器管理
function UIView:AddTimer(callback, interval, repeatCount, duration, delay)
    self.timerIds = self.timerIds or {}
    local timerId = UITimer:AddTimer(callback, interval, repeatCount, duration, delay)
    table.insert(self.timerIds, timerId)
    return timerId
end

--移除定时器
function UIView:RemoveTimer(timerId)
    if self.timerIds then
        for i, v in ipairs(self.timerIds) do
            if v == timerId then
                table.remove(self.timerIds, i)
                break
            end
        end
    end
    UITimer:RemoveTimer(timerId)
end

--清除定时器
function UIView:ClearAllTimers()
    if self.timerIds then
        for _, timerId in ipairs(self.timerIds) do
            UITimer:RemoveTimer(timerId)
        end
        self.timerIds = nil
    end
end

--延迟执行
function UIView:DelayCall(func,delayTime)
    local timerId = UITimer:AddTimer(function()
        table.remove(self.delayCallTimers, timerId)
        func()
    end, delayTime, 1)
    table.insert(self.delayCallTimers, timerId)
    return timerId
end

--清理所有延迟执行
function UIView:ClearAllDelayCall()
    for k,v in ipairs(self.delayCallTimers) do
        UITimer:RemoveTimer(v)
    end
    self.delayCallTimers = {}
end

--查找控件
function UIView:FindControl(controlName, recursive, parent)
    recursive = recursive or true
    parent = parent or self.rootNode
    if type(parent) == "string" then
        parent = UIUtils:FindChildControl(self.rootNode, parent, true)
    end
    if parent then
        return UIUtils:FindChildControl(parent, controlName, recursive)
    end
    return nil
end


--------------------------------------------------Widget管理--------------------------------------------------

function UIView:AddWidget(widget)
    if widget then
        table.insert(self.widgets, widget)
    end

    if widget.bindObj then
        if not self.widgetCaches[widget.__cname] then
            self.widgetCaches[widget.__cname] = {}
        end
        self.widgetCaches[widget.__cname][widget.bindObj] = widget
    end
end

function UIView:RemoveWidget(widget)
    if widget then
        for i,v in ipairs(self.widgets) do
            if v == widget then
                table.remove(self.widgets, i)
                break
            end
        end
        if widget.bindObj then
            if self.widgetCaches[widget.__cname] then
                self.widgetCaches[widget.__cname][widget.bindObj] = nil
            end
        end
    end
end

function UIView:ClearAllWidgets()
    while #self.widgets > 0 do
        local widget = self.widgets[1]
        widget:Destroy()
    end
    self.widgets = {}
    self.widgetCaches = {}
end

--遍历所有控件
function UIView:ForEachWidgets(func)
    for _, widget in ipairs(self.widgets) do
        func(widget)
    end
end

--创建控件
function UIView:CreateWidget(typeName, control, managedBindObj, ...)
    managedBindObj = (managedBindObj == nil and false or managedBindObj)
    if type(control) == "string" then
        control = self:FindControl(control, true, self.rootNode)
    end
    if not control then
        UILog:Error("UIView:CreateWidget: control is nil")
        return nil
    end

    if control and self.widgetCaches[typeName] then
        local widget = self.widgetCaches[typeName][control]
        if widget then
            return widget
        end
    end

    local widget = self.UIManager:CreateWidget(typeName, control, managedBindObj, self, ...)
    return widget 
end

--查找控件
function UIView:FindWidget(typeName, widgetName, parent)
    local bindObj = self:FindControl(widgetName, true, parent)
    if bindObj then
        return self:CreateWidget(typeName, bindObj)
    end
    return nil
end

UIWidgetCreator:RegisterAllCreators(UIView)

--------------------------------------------------UI事件管理--------------------------------------------------

--点击事件
function UIView:OnClicked(obj, callback)
    if not obj then
        UILog:Error("UIView:OnClicked obj is nil")
        return
    end

    self:RemoveEventByObj(obj, "Clicked")
    local listener = obj.Click:Connect(function ()
        callback(self, obj)
    end) 
    table.insert(self.eventListeners, {
        obj = obj,
        listener = listener,
        name = "Clicked"
    })
    return listener
end

function UIView:OnGapClicked(obj, callback, gap, stopCallback)
    if gap ~= nil then
        local switch = false
        self:OnClicked(obj, function(owner, obj)
            local gapTime = self.gapMap[obj]
            if gapTime == nil or gapTime < 0 then
                self.gapMap[obj] = gap
                callback(owner, obj)
                switch = true
            elseif (stopCallback ~= nil) and switch then
                switch = false
                stopCallback()
            end
        end)
    else
        self:OnClicked(obj, callback)
    end
end

--移除事件
function UIView:RemoveEventByObj(obj, name)
    for k,v in pairs(self.eventListeners) do
        if v.obj == obj then
            if not name or v.name == name then
                v.listener:Disconnect()
                table.remove(self.eventListeners, k)
                break
            end
        end
    end
end

--移除事件
function UIView:RemoveEvent(listener)
    for k,v in pairs(self.eventListeners) do
        if v.listener == listener then
            v.listener:Disconnect()
            table.remove(self.eventListeners, k)
            break
        end
    end
end

--清除所有事件
function UIView:ClearAllEventListeners()
    for k,v in pairs(self.eventListeners) do
        v.listener:Disconnect()
    end
    self.eventListeners = {}
end

return UIView