-- 说明:UI组件
-- 日期:2025年1月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UITimer = GFScript("UIModule.UITimer")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Color = GFScript("UIModule.UIMath.Color")
local Rect = GFScript("UIModule.UIMath.Rect")
local UIActionRunner = GFScript("UIModule.UIActionRunner")
local UIUtils = GFScript("UIModule.UIUtils")
local UITween = GFScript("UIModule.UITween")
local UIEventObject = GFScript("UIModule.UIEventObject")
local UITweenUtils = GFScript("UIModule.UITweenUtils")
local UIWidgetCreator = GFScript("UIModule.UIWidgetCreator")
local RunService = game:GetService("RunService")
local UIWidget = UIClass.New("UIWidget", UIEventObject)

local autoId = 0
local maxAutoId = 10000000


--生成子网络id
function GenerateId()
    autoId = autoId + 1
    if autoId > maxAutoId then
        autoId = 1
    end
    return autoId
end

function UIWidget:Constructor(uiView)
    self.UIManager = GFScript("UIModule.UIManager")
    self.uiView = uiView
    self.parentWidget = nil
    self.childWidgets = {}
    self.childWidgetCaches = {}
    --是否启用拖拽
    self.isDragEnabled = false
    self.isDragging = false
    self.dragStartPos = nil
    self.dragPreviousPos = nil

    --是否启用放下
    self.isDropEnabled = false

    self.group = nil

    --事件过滤
    self.eventFilter = nil

    --事件穿透
    self.eventPass = false
    --响应事件
    self.eventEnabled = true

    --是否启用长按
    self.isLongPressEnabled = false
    self.longPressTotalTime = 0
    self.longPressCallback = nil
    self.longPressEndCallback = nil

    --双击相关
    self.isDoubleClickEnabled = false
    self.lastClickTime = 0
    self.lastClickPos = nil
    self.doubleClickedCallback = nil

    --事件联动控件
    self.eventLinkWidget = nil
end

function UIWidget:Destructor()
    self:DisableUpdate()
    self:StopAllActions()
    self:ClearAllEvents()
    self:__FinitInternalEvents()
    self:DestroyAllChildWidgets()
    self:SetParentWidget(nil)
    self:SetDropEnabled(false)
    self:StopDrag()
    self.uiView = nil
    self.UIManager = nil
    self.eventFilter = nil
    if self.longPressTimerId then
        UITimer:RemoveTimer(self.longPressTimerId)
        self.longPressTimerId = nil
    end
    if self.singleClickTimerId then
        UITimer:RemoveTimer(self.singleClickTimerId)
        self.singleClickTimerId = nil
    end

    if self.managedBindObj then
        self.bindObj:Destroy()
        self.bindObj = nil
    end
end

function UIWidget:OnConstructor()
    if self.uiView then
        self.uiView:AddWidget(self)
    end
end

function UIWidget:OnDestructor()
    if self.uiView then
        self.uiView:RemoveWidget(self)
    end
end

--设置组
function UIWidget:SetGroup(group)
    self.group = group
    if self.group then
        self.UIManager:AddWidgetToGroup(self, self.group)
    else
        self.UIManager:RemoveWidgetFromGroup(self)
    end
end

--获取组
function UIWidget:GetGroup()
    return self.group
end



--初始化
--@param bindObj: 绑定对象
--@param managedBindObj: 是否管理绑定对象
function UIWidget:Init(bindObj, managedBindObj)
    -- 参数验证
    if not bindObj then
        UILog:Error("Init: bindObj is required")
        return false
    end
    self.bindObj = bindObj
    self.managedBindObj = (managedBindObj == nil and false or managedBindObj)
    if self.bindObj.ClassType ~= "UIRoot" then
        self.bindObj.ClickPass = false
        self.bindObj.IsNotifyEventStop = not self.eventPass
        self.bindObj.Active = self.eventEnabled
        if not self.eventEnabled then
            self.bindObj.ClickPass = false
            self.bindObj.IsNotifyEventStop = false
        end
    end
    self.name = bindObj.Name
    self:__InitInternalEvents()

    return true
end

--初始化内部事件
function UIWidget:__InitInternalEvents()
    if not self.bindObj then
        UILog:Error("__InitInternalEvents: bindObj is nil")
        return
    end
    if self.bindObj.ClassType ~= "UIRoot" then
        self._internalTouchBeginEvent = self.bindObj.TouchBegin:Connect(function(node, issuccess, mousepos, touchId)
            if not RunService:IsPC() or touchId == 0 then --PC只有左键才行
                self:OnTouchBegin(Vec2.New(mousepos.X, mousepos.Y), touchId)
                if self.eventLinkWidget then
                    if not UIClass.IsExpired(self.eventLinkWidget) then
                        self.eventLinkWidget:OnLinkTouchBegin(Vec2.New(mousepos.X, mousepos.Y), touchId)
                    else
                        self.eventLinkWidget = nil
                    end
                end
            end
        end)
        self._internalTouchMoveEvent = self.bindObj.TouchMove:Connect(function(node, issuccess, mousepos, touchId)
            if not RunService:IsPC() or touchId == 0 then --PC只有左键才行
                self:OnTouchMove(Vec2.New(mousepos.X, mousepos.Y), touchId)
                if self.eventLinkWidget then
                    if not UIClass.IsExpired(self.eventLinkWidget) then
                        self.eventLinkWidget:OnLinkTouchMove(Vec2.New(mousepos.X, mousepos.Y), touchId)
                    else
                        self.eventLinkWidget = nil
                    end
                end
            end
        end)
        self._internalTouchEndEvent = self.bindObj.TouchEnd:Connect(function(node, issuccess, mousepos, touchId)
            if not RunService:IsPC() or touchId == 0 then --PC只有左键才行
                self:OnTouchEnd(Vec2.New(mousepos.X, mousepos.Y), touchId)
                if self.eventLinkWidget then
                    if not UIClass.IsExpired(self.eventLinkWidget) then
                        self.eventLinkWidget:OnLinkTouchEnd(Vec2.New(mousepos.X, mousepos.Y), touchId)
                    else
                        self.eventLinkWidget = nil
                    end
                end
            end
        end)
        self._internalClickedEvent = self.bindObj.Click:Connect(function(node, issuccess, mousepos, touchId)
            if not RunService:IsPC() or touchId == 0 then --PC只有左键才行
                self:OnClicked(Vec2.New(mousepos.X, mousepos.Y), touchId)
                if self.eventLinkWidget then
                    if not UIClass.IsExpired(self.eventLinkWidget) then
                        self.eventLinkWidget:OnLinkClicked(Vec2.New(mousepos.X, mousepos.Y), touchId)
                    else
                        self.eventLinkWidget = nil
                    end
                end
            end
        end)
    end
end

--清除内部事件
function UIWidget:__FinitInternalEvents()
    if self._internalTouchBeginEvent then
        self._internalTouchBeginEvent:Disconnect()
        self._internalTouchBeginEvent = nil
    end
    if self._internalTouchMoveEvent then
        self._internalTouchMoveEvent:Disconnect()
        self._internalTouchMoveEvent = nil
    end
    if self._internalTouchEndEvent then
        self._internalTouchEndEvent:Disconnect()
        self._internalTouchEndEvent = nil
    end
    if self._internalClickedEvent then
        self._internalClickedEvent:Disconnect()
        self._internalClickedEvent = nil
    end
end

--设置名称
function UIWidget:SetName(name)
    self.name = name
    if self.bindObj then
        self.bindObj.Name = name
    end
end

--获取名称
function UIWidget:GetName()
    return self.name
end

--设置父节点
function UIWidget:SetParentWidget(parentWidget)
    if self.parentWidget then
        self.parentWidget:RemoveChildWidget(self)
    end
    self.parentWidget = parentWidget
    if self.parentWidget then
        self.parentWidget:AddChildWidget(self)
    end
end

--获取父节点
function UIWidget:GetParentWidget()
    return self.parentWidget
end

function UIWidget:AddChildWidget(childWidget)
    if childWidget then
        table.insert(self.childWidgets, childWidget)
        if childWidget.bindObj then
            if not self.childWidgetCaches[childWidget.__cname] then
                self.childWidgetCaches[childWidget.__cname] = {}
            end
            self.childWidgetCaches[childWidget.__cname][childWidget.bindObj] = childWidget
        end
    end
end

function UIWidget:RemoveChildWidget(childWidget)
    if childWidget then
        for i,v in ipairs(self.childWidgets) do
            if v == childWidget then
                table.remove(self.childWidgets, i)
                break
            end
        end
        if childWidget.bindObj then
            if self.childWidgetCaches[childWidget.__cname] then
                self.childWidgetCaches[childWidget.__cname][childWidget.bindObj] = nil
            end
        end
    end
end

function UIWidget:GetChildWidgets()
    return self.childWidgets
end

function UIWidget:DestroyAllChildWidgets()
    while #self.childWidgets > 0 do
        local childWidget = self.childWidgets[1]
        childWidget:Destroy()
    end
    self.childWidgets = {}
    self.childWidgetCaches = {}
end


--重绘
function UIWidget:Refresh()
    self.UIManager:RefreshWidget(self)
end

--强制重绘
function UIWidget:ForceRefresh()
    self.UIManager:ForceRefreshWidget(self)
end

--重绘回调
function UIWidget:OnRefresh()

end

--启用更新
function UIWidget:EnableUpdate(interval)
    if self.updateTimerId then
        return
    end
    interval = interval or 0.05
    self.updateTimerId = UITimer:AddTimer(function(dt)
        self:Update(dt)
    end, interval, 0)
end

function UIWidget:DisableUpdate()
    if self.updateTimerId then
        UITimer:RemoveTimer(self.updateTimerId)
        self.updateTimerId = nil
    end
end

--更新
function UIWidget:Update(deltaTime)

end

--设置位置
function UIWidget:SetPosition(position)
    UIUtils:SetPosition(self.bindObj, position)
    self:OnPositionChanged()
end

function UIWidget:GetPosition()
    return UIUtils:GetPosition(self.bindObj)
end

--设置大小
function UIWidget:SetSize(size)
    UIUtils:SetSize(self.bindObj, size)
    self:OnSizeChanged()
end

function UIWidget:GetSize()
    return UIUtils:GetSize(self.bindObj)
end

function UIWidget:GetWidth()
    return UIUtils:GetWidth(self.bindObj)
end

function UIWidget:GetHeight()
    return UIUtils:GetHeight(self.bindObj)
end

--设置Pivot
function UIWidget:SetPivot(pivot)
    UIUtils:SetPivot(self.bindObj, pivot)
    self:OnPivotChanged()
end

function UIWidget:GetPivot()
    return UIUtils:GetPivot(self.bindObj)
end

--获取Pivot点
function UIWidget:GetPivotPoint()
    return UIUtils:GetPivotPoint(self.bindObj)
end

--设置旋转
function UIWidget:SetRotation(rotation)
    UIUtils:SetRotation(self.bindObj, rotation)
    self:OnRotationChanged()
end

function UIWidget:GetRotation()
    return UIUtils:GetRotation(self.bindObj)
end

--设置缩放
function UIWidget:SetScale(scale)
    UIUtils:SetScale(self.bindObj, scale)
    self:OnScaleChanged()
end

function UIWidget:GetScale()
    return UIUtils:GetScale(self.bindObj)
end

--设置颜色
function UIWidget:SetColorInHierarchy(color, recursive)
    UIUtils:SetColorInHierarchy(self.bindObj, color, recursive)
    self:OnColorChanged()
end

--设置透明度
function UIWidget:SetAlphaInHierarchy(alpha, recursive)
    UIUtils:SetAlphaInHierarchy(self.bindObj, alpha, recursive)
    self:OnAlphaChanged()
end

--设置颜色
function UIWidget:SetColor(color)
    UIUtils:SetColor(self.bindObj, color)
    self:OnColorChanged()
end

function UIWidget:GetColor()
    return UIUtils:GetColor(self.bindObj)
end

--设置透明度
function UIWidget:SetAlpha(alpha)
    UIUtils:SetAlpha(self.bindObj, alpha)
    self:OnAlphaChanged()
end

function UIWidget:GetAlpha()
    return UIUtils:GetAlpha(self.bindObj)
end

--设置可见性
function UIWidget:SetVisible(visible)
    UIUtils:SetVisible(self.bindObj, visible)
    self:OnVisibleChanged()
end

function UIWidget:IsVisible()
    return UIUtils:IsVisible(self.bindObj)
end

--适应大小
--expandX: 扩展x
--expandY: 扩展y
--minWidth: 最小宽度
--minHeight: 最小高度
function UIWidget:FitSize(expandX, expandY, minWidth, minHeight)
    UIUtils:FitSize(self.bindObj, expandX, expandY, minWidth, minHeight)
end

--调整大小并扩展目标
--size: 大小
--pivot: 锚点
--targetWidget: 目标控件
function UIWidget:ResizeAndExpandTarget(size, pivot, targetWidget)
    UIUtils:ResizeAndExpandTarget(self.bindObj, size, pivot, targetWidget.bindObj)
end

--调整大小
--size: 大小
--pivot: 锚点
function UIWidget:Resize(size, pivot)
    UIUtils:Resize(self.bindObj, size, pivot)
end

--计算子控件矩形
function UIWidget:CalculateChildrenScreenRect()
    return UIUtils:CalculateChildrenScreenRect(self.bindObj)
end

--设置中间X
function UIWidget:CenterX()
    UIUtils:CenterX(self.bindObj)
end

--设置中间Y
function UIWidget:CenterY()
    UIUtils:CenterY(self.bindObj)
end

--设置中间
function UIWidget:Center()
    UIUtils:Center(self.bindObj)
end

--设置锚点预设
function UIWidget:SetAnchorPreset(anchorPreset, keepPosition)
    UIUtils:SetAnchorPreset(self.bindObj, anchorPreset, keepPosition)
end

--设置全屏大小
function UIWidget:SetFullScreenSize()
    UIUtils:SetFullScreenSize(self.bindObj)
end

--设置拉伸X
function UIWidget:SetStretchX(stretchX)
    UIUtils:SetStretchX(self.bindObj, stretchX)
end

--设置拉伸Y
function UIWidget:SetStretchY(stretchY)
    UIUtils:SetStretchY(self.bindObj, stretchY)
end

--获取拉伸X
function UIWidget:GetStretchX()
    return UIUtils:GetStretchX(self.bindObj)
end

--获取拉伸Y
function UIWidget:GetStretchY()
    return UIUtils:GetStretchY(self.bindObj)
end

--设置拉伸
function UIWidget:SetStretch(stretchX, stretchY)
    UIUtils:SetStretch(self.bindObj, stretchX, stretchY)
end

--获取拉伸
function UIWidget:GetStretch()
    return UIUtils:GetStretch(self.bindObj)
end

--设置原始大小
function UIWidget:SetNativeSize(keepPosition, singleLine)
    UIUtils:SetNativeSize(self.bindObj, keepPosition, singleLine)
end

--设置所有子控件原始大小
function UIWidget:SetChildrenNativeSize(keepPosition, singleLine)
    UIUtils:SetChildrenNativeSize(self.bindObj, keepPosition, singleLine)
end

--获取原始大小
function UIWidget:GetNativeSize(singleLine)
    return UIUtils:GetNativeSize(self.bindObj, singleLine)
end

--位置改变回调
function UIWidget:OnPositionChanged()

end

--大小改变回调
function UIWidget:OnSizeChanged()

end

--Pivot改变回调
function UIWidget:OnPivotChanged()

end

--旋转改变回调
function UIWidget:OnRotationChanged()

end

--缩放改变回调
function UIWidget:OnScaleChanged()

end

--颜色改变回调
function UIWidget:OnColorChanged()

end

--透明度改变回调
function UIWidget:OnAlphaChanged()

end

--可见性改变回调
function UIWidget:OnVisibleChanged()

end

--获取屏幕位置
function UIWidget:GetScreenPosition()
    return UIUtils:GetScreenPosition(self.bindObj)
end

--设置屏幕位置
function UIWidget:SetScreenPosition(pos)
    UIUtils:SetScreenPosition(self.bindObj, pos)
end

--获取屏幕矩形
function UIWidget:GetScreenRect()
    return UIUtils:GetScreenRect(self.bindObj)
end

--设置屏幕矩形
function UIWidget:SetScreenRect(rect)
    UIUtils:SetScreenRect(self.bindObj, rect)
end

--备份屏幕矩形
function UIWidget:BackupScreenRect()
    self.backupScreenRect = self:GetScreenRect()
end

--是否备份屏幕矩形
function UIWidget:IsBackupScreenRect()
    return self.backupScreenRect ~= nil
end

--清除备份屏幕矩形
function UIWidget:ClearBackupScreenRect()
    self.backupScreenRect = nil
end

--恢复屏幕矩形  
function UIWidget:RestoreScreenRect()
    if not self.backupScreenRect then
        return
    end
    self:SetScreenRect(self.backupScreenRect)
end

--获取锚点
function UIWidget:GetAnchorPoint()
    local rect = self:GetScreenRect()
    return rect:GetAnchorPoint()
end

--屏幕坐标转换为本地坐标
function UIWidget:MapScreenToLocal(screenPos)
    return UIUtils:MapScreenToLocal(self.bindObj, screenPos)
end

--本地坐标转换为屏幕坐标
function UIWidget:MapLocalToScreen(localPos)
    return UIUtils:MapLocalToScreen(self.bindObj, localPos)
end

--计算吸附矩形
--size: 大小
--pivot: 锚点
--offset: 偏移
--anchor: 吸附点，0-1之间，x为水平吸附点，y为垂直吸附点，0为左上角，1为右下角
function UIWidget:CalculateAnchoredRect(size, pivot, offset, anchor)
    return UIUtils:CalculateAnchoredRect(self.bindObj, size, pivot, offset, anchor)
end

--对齐
--targetWidget: 目标控件
--pivot: 锚点
--offset: 偏移
--anchor: 吸附点，0-1之间，x为水平吸附点，y为垂直吸附点，0为左上角，1为右下角
function UIWidget:Align(targetWidget, pivot, offset, anchor)
    UIUtils:Align(self.bindObj, targetWidget.bindObj, pivot, offset, anchor)
end

--居中
function UIWidget:Middle()
    UIUtils:Align(self.bindObj, self:GetParent(), Vec2.New(0.5, 0.5), Vec2.New(0, 0), Vec2.New(0.5, 0.5))
end

--调整子控件布局
--layoutOrigin: 布局原点
--layoutDirection: 布局方向
--layoutReverse: 布局反向
--layoutPadding: 布局内边距
--layoutSpacing: 布局间距
--lineCount: 布局行数
--layoutCallback: 布局回调
function UIWidget:AdjustLayoutChildWidgets(
    layoutOrigin, layoutDirection, 
    layoutReverse, layoutPadding, layoutSpacing, lineCount, layoutCallback)
    local layoutRect = self:GetScreenRect()
    local layoutItems = {}
    for _, child in ipairs(self.childWidgets) do
        if child:IsVisible() then
            local size = child:GetSize()
            table.insert(layoutItems, size)
        end
    end
    UILayout:AdjustLayout(layoutRect, layoutItems, lineCount,
        layoutOrigin, layoutDirection, 
        layoutReverse, layoutPadding, layoutSpacing, function(index, pos, size)
            local child = self.childWidgets[index]
            child:SetScreenPosition(pos)
            child:SetSize(size)
            if layoutCallback then
                layoutCallback(child)
            end
        end)
end

--调整子控件布局
--layoutOrigin: 布局原点
--layoutDirection: 布局方向
--layoutReverse: 布局反向
--layoutPadding: 布局内边距
--layoutSpacing: 布局间距
--lineCount: 布局行数
--layoutCallback: 布局回调
function UIWidget:AdjustLayoutChildren( 
    layoutOrigin, layoutDirection, 
    layoutReverse, layoutPadding, layoutSpacing, lineCount, layoutCallback)
    local children = {}
    for _, child in ipairs(self.bindObj.Children) do
        if child.Visible then
            table.insert(children, child)
        end
    end
    UIUtils:AdjustLayoutChildren(self.bindObj, children, 
        layoutOrigin, layoutDirection, 
        layoutReverse, layoutPadding, layoutSpacing, lineCount, layoutCallback)
end

--垂直布局
function UIWidget:VLayoutChildren(spacingY, paddingY, origin)
    UIUtils:VLayoutChildren(self.bindObj, spacingY, paddingY, origin)
end

--水平布局
function UIWidget:HLayoutChildren(spacingX, paddingX, origin)
    UIUtils:HLayoutChildren(self.bindObj, spacingX, paddingX, origin)
end

--克隆
function UIWidget:Clone()
    if not self.bindObj then
        UILog:Error("Clone: bindObj is nil")
        return
    end
    local newBindObj = self.bindObj:Clone()
    local widget = self.UIManager:CreateWidget(self.typeName, newBindObj, true, self.parentView)
    if widget then
        widget:SetParentWidget(self.parentWidget)
        widget:CopyFrom(self)
    end
    return widget
end

--复制
function UIWidget:CopyFrom(widget)
    if not widget then
        return
    end
end

--设置是否可拖拽
function UIWidget:SetDragable(dragable)
    self.isDragable = dragable
end

--获取是否可拖拽
function UIWidget:IsDragable()
    return self.isDragable
end

--设置是否启用拖拽
function UIWidget:SetDragEnabled(dragEnabled)
    self.isDragEnabled = dragEnabled
end

--设置是否启用放下
function UIWidget:SetDropEnabled(dropEnabled)
    self.isDropEnabled = dropEnabled
    if dropEnabled and not self.dropableId then
        self.dropableId = GenerateId()
        self.UIManager:AddDropableWidget(self)
    elseif not dropEnabled and self.dropableId then
        self.UIManager:RemoveDropableWidget(self)
        self.dropableId = nil
    end
end

--获取是否启用放下
function UIWidget:IsDropEnabled()
    return self.isDropEnabled
end

--是否可以放下
function UIWidget:CanDrop(widget, dragItem, touchPos)
    if self.canDropCallback then
        return self.canDropCallback(widget, dragItem, touchPos)
    end
    return true
end

--放下
function UIWidget:Drop(widget, dragItem, touchPos)
    if self.dropCallback then
        self.dropCallback(widget, dragItem, touchPos)
    end
end

--放下失败
function UIWidget:DropFailed(widget, dragItem, touchPos)
    if self.dropFailedCallback then
        self.dropFailedCallback(widget, dragItem, touchPos)
    end
end

--标记放下
function UIWidget:MarkDrop(widget, dragItem, touchPos)
    
end

--标记放下失败
function UIWidget:MarkDropFailed(widget, dragItem, touchPos)
    
end

--标记放下离开
function UIWidget:MarkDropLeave(widget, dragItem, touchPos)
    
end



--设置事件穿透
function UIWidget:SetEventPass(eventPass)
    self.eventPass = eventPass
    if self.bindObj then
        self.bindObj.IsNotifyEventStop = not eventPass
    end
end

--获取事件穿透
function UIWidget:GetEventPass()
    return self.eventPass
end

--设置事件过滤
function UIWidget:SetEventFilter(eventFilter)
    self.eventFilter = eventFilter
end

--获取事件过滤
function UIWidget:GetEventFilter()
    return self.eventFilter
end

--事件过滤
function UIWidget:OnEventFilter(obj, eventName, args1, args2, args3, args4, args5)
    return true
end

--设置事件联动控件
function UIWidget:SetEventLinkWidget(eventLinkWidget)
    self.eventLinkWidget = eventLinkWidget
end

--获取事件联动控件
function UIWidget:GetEventLinkWidget()
    return self.eventLinkWidget
end





--设置是否启用长按
function UIWidget:SetLongPressEnabled(longPressEnabled, maxCount)
    maxCount = maxCount or 999999999
    self.isLongPressEnabled = longPressEnabled
    self.longPressCount = 0
    self.longPressMaxCount = maxCount
    if not longPressEnabled then
        self.longPressCallback = nil
        self.longPressEndCallback = nil 
        self.longPressCount = 0
        self.longPressMaxCount = 0
        if self.longPressTimerId then
            UITimer:RemoveTimer(self.longPressTimerId)
            self.longPressTimerId = nil
        end
    end
end

--设置是否响应事件  
function UIWidget:SetEventEnabled(eventEnabled)
    self.eventEnabled = eventEnabled
    if self.bindObj then
        self.bindObj.Active = eventEnabled
    end
end

--获取是否响应事件
function UIWidget:IsEventEnabled()
    return self.eventEnabled
end

--触摸开始
function UIWidget:OnTouchBegin(touchPos, touchId)
    if not self.eventEnabled then
        return false
    end
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "TouchBegin", touchPos) then
            return false
        end
    end
    self.touchBeginPos = touchPos:Clone()
    self.previousTouchPos = touchPos:Clone()
    self.touchCurrentPos = touchPos:Clone()

    if self.touchScaleAnimation then
        self:ScaleTo(Vec2.New(self.touchScaleAnimation, self.touchScaleAnimation), 0.1):Ease("EaseInOutBack"):Start()
    end
    self:HandleTouchBeginCallback(touchPos, touchId)

    if self.isLongPressEnabled then
        if self.longPressTimerId then
            UITimer:RemoveTimer(self.longPressTimerId)
            self.longPressTimerId = nil
        end
        self.longPressTotalTime = 0
        self.longPressTimerId = UITimer:AddTimer(function(dt)
            self.longPressTotalTime = self.longPressTotalTime + dt
            if self.longPressCount < self.longPressMaxCount then
                self:OnLongPress(touchPos)
                self.longPressCount = self.longPressCount + 1
            end
        end, self.UIManager.longPressTime)
    end

    return true
end

--触摸移动
function UIWidget:OnTouchMove(touchPos, touchId)
    if not self.eventEnabled then
        return false
    end
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "TouchMove", touchPos) then
            return false
        end
    end
    if self.touchMovePos then
        self.previousTouchPos = self.touchMovePos:Clone()
    end
    self.touchMovePos = touchPos:Clone()
    self.touchCurrentPos = touchPos:Clone()

    if self.isDragEnabled then
        self.isDragging = true
        if self.isDragable then
            self:SetToTop()
        end
        self:OnDragBegin(self.touchBeginPos)
    end
    if self.isDragging then
        if self.isDragable then
            local delta = touchPos - self.previousTouchPos
            local newPos = self:GetPosition() + delta
            self:SetPosition(newPos)
        end
        if self.dragItem then
            self.dragItem:SetTouchPos(self.touchCurrentPos)
        end
        self:OnDragMove(self.previousTouchPos, self.touchMovePos)
    end
    self:HandleTouchMoveCallback(self.previousTouchPos, self.touchMovePos, touchId)
    return true
end

--触摸结束
function UIWidget:OnTouchEnd(touchPos, touchId)
    if not self.eventEnabled then
        return false
    end
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "TouchEnd", touchPos) then
            return false
        end
    end
    if self.isDragging then
        self:OnDragEnd(touchPos)
        self.isDragging = false
        self.touchMovePos = nil
        self.previousTouchPos = nil
        self.touchBeginPos = nil
    end
    if self.touchScaleAnimation then
        self:ScaleTo(Vec2.New(1, 1), 0.1):Ease("EaseInOutBack"):Start()
    end

    if self.isLongPressEnabled then
        self:OnLongPressEnd(touchPos)
        self.longPressCount = 0
        if self.longPressTimerId then
            UITimer:RemoveTimer(self.longPressTimerId)
            self.longPressTimerId = nil
        end
    end

    self:HandleTouchEndCallback(touchPos, touchId)

    --销毁拖拽控件
    self:StopDrag()


    return true
end

function UIWidget:OnLinkTouchBegin(touchPos, touchId)
    
end

function UIWidget:OnLinkTouchMove(touchPos, touchId)
    
end

function UIWidget:OnLinkTouchEnd(touchPos, touchId)
    
end

function UIWidget:OnLinkClicked(touchPos, touchId)
    
end

--长按
function UIWidget:OnLongPress(touchPos)
    self:HandleLongPressCallback(touchPos)
end

--长按结束
function UIWidget:OnLongPressEnd(touchPos)
    self:HandleLongPressEndCallback(touchPos)
end

--点击
function UIWidget:OnClicked(touchPos)
    if not self.eventEnabled then
        return false
    end
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "Clicked", touchPos) then
            return false
        end
    end

    -- 处理双击
    if self.isDoubleClickEnabled then
        local currentTime = UIUtils:GetSystemTime()
        if self.lastClickTime > 0 and currentTime - self.lastClickTime <= self.UIManager.doubleClickTime then
            -- 检查点击位置是否在允许的范围内
            if self.lastClickPos and (self.lastClickPos - touchPos):Length() < self.UIManager.doubleClickDistance then
                -- 取消之前的单击延迟
                if self.singleClickTimerId then
                    UITimer:RemoveTimer(self.singleClickTimerId)
                    self.singleClickTimerId = nil
                end
                self:HandleDoubleClickedCallback(touchPos)
                self.lastClickTime = 0
                self.lastClickPos = nil
                return true
            end
        end
        self.lastClickTime = currentTime
        self.lastClickPos = touchPos:Clone()
        
        -- 延迟执行单击事件，等待可能的双击
        if self.singleClickTimerId then
            UITimer:RemoveTimer(self.singleClickTimerId)
        end
        self.singleClickTimerId = UITimer:AddTimer(function()
            if self.singleClickTimerId then
                self.singleClickTimerId = nil
                self:ExecuteSingleClick(touchPos)
                self.lastClickTime = 0
            end
        end, self.UIManager.doubleClickTime, 1)
        
        return true
    end

    -- 如果没有启用双击，直接执行单击
    self:ExecuteSingleClick(touchPos)
    return true
end

--执行单击事件
function UIWidget:ExecuteSingleClick(touchPos)
    if self.clickScaleAnimation then
        self:Tween({
            {"ScaleTo", Vec2.New(self.clickScaleAnimation, self.clickScaleAnimation), 0.1},
            {"Ease", "EaseInOutBack"},
            {"ScaleTo", Vec2.New(1, 1), 0.1},
            {"Ease", "EaseInOutBack"},
        }):Tag("Clicked"):OnComplete(function() 
            if self.clickedCallbackDelay then
                self:HandleClickedCallback(touchPos)
            end
        end):Start()

        if not self.clickedCallbackDelay then
            self:HandleClickedCallback(touchPos)
        end
    else
        self:HandleClickedCallback(touchPos)
    end
end

--拖拽开始
function UIWidget:OnDragBegin(touchPos)
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "DragBegin", touchPos) then
            return false
        end
    end
    self:HandleDragBeginCallback(touchPos)
    return true
end

--拖拽移动
function UIWidget:OnDragMove(previousTouchPos, touchPos)
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "DragMove", touchPos) then
            return false
        end
    end
    self:HandleDragMoveCallback(previousTouchPos, touchPos)
    return true
end

--拖拽结束
function UIWidget:OnDragEnd(touchPos)
    if self.eventFilter then
        if not self.eventFilter:OnEventFilter(self, "DragEnd", touchPos) then
            return false
        end
    end
    self:HandleDragEndCallback(touchPos)
    return true
end

--获取是否启用拖拽
function UIWidget:IsDragEnabled()
    return self.isDragEnabled
end

--Tween
function UIWidget:Tween(data)
    return UITweenUtils:Tween(self.bindObj, data)
end

--显示焦点遮罩
function UIWidget:FocusMask(expand)
    self.UIManager:FocusMask(self, expand)
end

--隐藏焦点遮罩
function UIWidget:UnFocusMask()
    self.UIManager:UnFocusMask()
end

--------------------------------------------父子关系管理--------------------------------------------

--设置父节点
function UIWidget:SetParent(parent, keepScreenPos)
    UIUtils:SetParent(self.bindObj, parent, keepScreenPos)
end 

--获取父节点
function UIWidget:GetParent()
    if not self.bindObj then
        UILog:Error("GetParent: bindObj is nil")
        return
    end
    return self.bindObj.Parent
end

--设置兄弟节点索引
function UIWidget:SetSiblingIndex(index)
    if not self.bindObj then
        UILog:Error("SetSiblingIndex: bindObj is nil")
        return
    end
    UIUtils:SetSiblingIndex(self.bindObj, index)
end

--获取兄弟节点索引
function UIWidget:GetSiblingIndex()
    if not self.bindObj then
        UILog:Error("GetSiblingIndex: bindObj is nil")
        return
    end
    return UIUtils:GetSiblingIndex(self.bindObj)
end

--设置到最上层
function UIWidget:SetToTop()
    if not self.bindObj then
        UILog:Error("SetToTop: bindObj is nil")
        return
    end
    UIUtils:SetToTop(self.bindObj)
end

--设置到最下层
function UIWidget:SetToBottom()
    if not self.bindObj then
        UILog:Error("SetToBottom: bindObj is nil")
        return
    end
    UIUtils:SetToBottom(self.bindObj)
end

--查找控件
function UIWidget:FindControl(controlName, recursive, parent)
    recursive = recursive or true
    parent = parent or self.bindObj
    if type(parent) == "string" then
        parent = UIUtils:FindChildControl(self.rootNode, parent, true)
    end
    if parent then
        return UIUtils:FindChildControl(parent, controlName, recursive)
    end
    return nil
end


--创建控件
function UIWidget:CreateWidget(typeName, control, managedBindObj, ...)
    if control and self.childWidgetCaches[typeName] then
        local widget = self.childWidgetCaches[typeName][control]
        if widget then
            return widget
        end
    end
    local widget = self.UIManager:CreateWidget(typeName, control, managedBindObj, nil, ...)
    if widget then
        widget:SetParentWidget(self)
    end
    return widget 
end

--查找控件
function UIWidget:FindWidget(typeName, widgetName, parent)
    local bindObj = self:FindControl(widgetName, true, parent)
    if bindObj then
        return self:CreateWidget(typeName, bindObj)
    end
    return nil
end

UIWidgetCreator:RegisterAllCreators(UIWidget)
--------------------------------------------Action--------------------------------------------
--运行动作
function UIWidget:RunAction(action)
    UIUtils:RunAction(self.bindObj,action)
end
--根据Tag获取动作
function UIWidget:GetActionByTag(tag)
    return UIUtils:GetActionByTag(self.bindObj,tag)
end

--根据Tag停止动作
function UIWidget:StopActionByTag(tag)
    UIUtils:StopActionByTag(self.bindObj,tag)
end

--根据Tag获取Action的数量
function UIWidget:CountActionByTag(tag)
    return UIUtils:CountActionByTag(self.bindObj,tag)
end

--停止所有动作
function UIWidget:StopAllActions()
    UIUtils:StopAllActions(self.bindObj)
end

--------------------------------------------------UI事件管理--------------------------------------------------

function UIWidget:ClearAllEvents()
    self.clickedCallback = nil
    self.touchBeginCallback = nil
    self.touchMoveCallback = nil
    self.touchEndCallback = nil
    self.longPressCallback = nil
    self.longPressEndCallback = nil
    self.doubleClickedCallback = nil
    self.dragBeginCallback = nil
    self.dragMoveCallback = nil
    self.dragEndCallback = nil
    self.canDropCallback = nil
    self.newDragItemCallback = nil
    self.dropCallback = nil
    
    -- 清理单击延迟定时器
    if self.singleClickTimerId then
        UITimer:RemoveTimer(self.singleClickTimerId)
        self.singleClickTimerId = nil
    end
end

--点击事件
function UIWidget:ClickedCallback(callback)
    self.clickedCallback = callback
end

--触摸开始事件
function UIWidget:TouchBeginCallback(callback)
    self.touchBeginCallback = callback
end

--触摸移动事件
function UIWidget:TouchMoveCallback(callback)
    self.touchMoveCallback = callback
end

--触摸结束事件
function UIWidget:TouchEndCallback(callback)
    self.touchEndCallback = callback
end

--长按事件
function UIWidget:LongPressCallback(callback)
    self.longPressCallback = callback
end

--长按结束事件
function UIWidget:LongPressEndCallback(callback)
    self.longPressEndCallback = callback
end

function UIWidget:DragBeginCallback(callback)
    self.dragBeginCallback = callback
end

function UIWidget:DragMoveCallback(callback)
    self.dragMoveCallback = callback
end

function UIWidget:DragEndCallback(callback)
    self.dragEndCallback = callback
end

--刷新事件
function UIWidget:RefreshCallback(callback)
    self.refreshCallback = callback
end

--是否可以放下
function UIWidget:CanDropCallback(callback)
    self.canDropCallback = callback
end

--创建拖拽控件事件
function UIWidget:NewDragItemCallback(callback)
    self.newDragItemCallback = callback
end

--放下事件
function UIWidget:DropCallback(callback)
    self.dropCallback = callback
end

--放下失败事件
function UIWidget:DropFailedCallback(callback)
    self.dropFailedCallback = callback
end

--开始拖拽
function UIWidget:StartDrag()
    if self.newDragItemCallback then
        local item = self.newDragItemCallback(self, self.touchCurrentPos)
        self.dragItem = item
        if self.dragItem then
            self.dragItem:SetTouchPos(self.touchCurrentPos) 
        end
    end
end

--停止拖拽
function UIWidget:StopDrag()
    if self.dragItem then
        self.dragItem:Destroy()
        self.dragItem = nil
    end
end

------------------------------------HandleCallback------------------------------------
function UIWidget:HandleClickedCallback(touchPos, touchId)
    if self.clickedCallback then
        self.clickedCallback(self, touchPos, touchId)
    end
end

function UIWidget:HandleTouchBeginCallback(touchPos, touchId)
    if self.touchBeginCallback then
        self.touchBeginCallback(self, touchPos, touchId)
    end
end

function UIWidget:HandleTouchMoveCallback(previousTouchPos, touchPos, touchId)
    if self.touchMoveCallback then
        self.touchMoveCallback(self, previousTouchPos, touchPos, touchId)
    end
end

function UIWidget:HandleTouchEndCallback(touchPos, touchId)
    if self.touchEndCallback then
        self.touchEndCallback(self, touchPos, touchId)
    end
end

function UIWidget:HandleLongPressCallback(touchPos, touchId)
    if self.longPressCallback then
        self.longPressCallback(self, touchPos, touchId)
    end
end

function UIWidget:HandleLongPressEndCallback(touchPos, touchId)
    if self.longPressEndCallback then
        self.longPressEndCallback(self, touchPos, touchId)
    end
end

function UIWidget:HandleDoubleClickedCallback(touchPos, touchId)
    if self.doubleClickedCallback then
        self.doubleClickedCallback(self, touchPos, touchId)
    end
end

function UIWidget:HandleDragBeginCallback(touchPos)
    if self.dragBeginCallback then
        self.dragBeginCallback(self, touchPos)
    end

end

function UIWidget:HandleDragMoveCallback(previousTouchPos, touchPos)
    if self.dragMoveCallback then
        self.dragMoveCallback(self, previousTouchPos, touchPos)
    end

    if self.dragItem then
        if self.lastDropableWidget then
            self.lastDropableWidget:MarkDropLeave(self, self.dragItem, touchPos)
        end
        local dropableWidget = self.UIManager:GetDropableWidgetAtPos(touchPos)
        if dropableWidget then
            if dropableWidget:CanDrop(self, self.dragItem, touchPos) then
                dropableWidget:MarkDrop(self, self.dragItem, touchPos)
            else
                dropableWidget:MarkDropFailed(self, self.dragItem, touchPos)
            end
        end
        self.lastDropableWidget = dropableWidget
    end
end

function UIWidget:HandleDragEndCallback(touchPos)
    if self.dragEndCallback then
        self.dragEndCallback(self, touchPos)
    end
    
    if self.dragItem then
        --判断是否可以放下
        local dropableWidget = self.UIManager:GetDropableWidgetAtPos(touchPos)
        if dropableWidget then
            if dropableWidget:CanDrop(self, self.dragItem, touchPos) then
                dropableWidget:Drop(self, self.dragItem, touchPos)
            else
                dropableWidget:DropFailed(self, self.dragItem, touchPos)
            end
        end

        if self.lastDropableWidget then
            self.lastDropableWidget:MarkDropLeave(self, self.dragItem, touchPos)
            self.lastDropableWidget = nil
        end
    end
end

function UIWidget:HandleRefreshCallback()
    if self.refreshCallback then
        self.refreshCallback(self)
    end
end


--------------------------------------------------UI效果管理--------------------------------------------------

--淡入
--@param duration number 动画持续时间
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UIWidget:FadeIn(duration, ease, finishCallback)
    UITweenUtils:FadeIn(self.bindObj, duration, ease, finishCallback)
end

--淡出
--@param duration number 动画持续时间
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UIWidget:FadeOut(duration, ease, finishCallback)
    UITweenUtils:FadeOut(self.bindObj, duration, ease, finishCallback)
end

--闪烁
--@param duration number 动画持续时间
--@param count number 闪烁次数
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UIWidget:Blink(duration, count, ease, finishCallback)
    UITweenUtils:Blink(self.bindObj, duration, count, ease, finishCallback)
end

--匹配变换
--@param targetWidget UIWidget 目标控件
--@param duration number 动画持续时间
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UIWidget:MatchTransformTo(targetWidget, duration, ease, finishCallback)
    UITweenUtils:MatchTransformTo(self.bindObj, targetWidget.bindObj, duration, ease, finishCallback)
end

--将控件对齐到目标控件的指定锚点位置
--@param targetWidget UIWidget 目标控件
--@param duration number 动画持续时间
--@param pivot Vec2 轴心点
--@param offset Vec2 位置偏移量
--@param anchor Vec2 锚点(0-1)，x为水平锚点，y为垂直锚点
--@param ease string 缓动类型
function UIWidget:AlignTo(targetWidget, duration, pivot, offset, anchor, ease, finishCallback)
    UITweenUtils:AlignTo(self.bindObj, targetWidget.bindObj, duration, pivot, offset, anchor, ease, finishCallback)
end

--恢复到备份屏幕矩形
function UIWidget:RestoreToBackupScreenRect(duration, ease, finishCallback)
    if not self.backupScreenRect then
        UILog:Error("RestoreToBackupScreenRect: backupScreenRect is nil")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseOutCubic"
    local size = self:GetSize()
    local selfPivot = self:GetPivot()
    self:MoveTo(self.backupScreenRect:GetPosition() + Vec2.New(size.x * selfPivot.x, size.y * selfPivot.y), duration):Ease(ease):Start()
    self:SizeTo(self.backupScreenRect:GetSize(), duration):Ease(ease):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--收集到目标控件
function UIWidget:CollectIn(targetWidget, duration, scale, fadeDuration, ease, finishCallback)
    UITweenUtils:CollectIn(self.bindObj, targetWidget.bindObj, duration, scale, fadeDuration, ease, finishCallback)
end

--收集到目标控件
function UIWidget:CollectOut(targetWidget, duration, scale, fadeDuration, ease, finishCallback)
    UITweenUtils:CollectOut(self.bindObj, targetWidget.bindObj, duration, scale, fadeDuration, ease, finishCallback)
end
--滑动进入动画
--@param offset Vec2 起始位置的偏移量
--@param duration number 动画持续时间
--@param ease string 缓动类型(可选)
--@return UITween 动画对象
function UIWidget:SlideIn(offset, duration, ease, finishCallback)
    UITweenUtils:SlideIn(self.bindObj, offset, duration, ease, finishCallback)
end

--滑动退出动画
--@param offset Vec2 目标位置的偏移量
--@param duration number 动画持续时间
--@param ease string 缓动类型(可选)
--@return UITween 动画对象
function UIWidget:SlideOut(offset, duration, ease, finishCallback)
    UITweenUtils:SlideOut(self.bindObj, offset, duration, ease, finishCallback)
end

--缩放进入动画
function UIWidget:ScaleIn(scale, duration, ease, finishCallback)
    UITweenUtils:ScaleIn(self.bindObj, scale, duration, ease, finishCallback)
end

--缩放退出动画
function UIWidget:ScaleOut(scale, duration, ease, finishCallback)
    UITweenUtils:ScaleOut(self.bindObj, scale, duration, ease, finishCallback)
end

--调整子控件布局
function UIWidget:AdjustLayoutChildrenTo(layoutOrigin, layoutDirection, layoutReverse, layoutPadding, layoutSpacing, lineCount, duration, ease, finishCallback)
    UITweenUtils:AdjustLayoutChildrenTo(self.bindObj, self.bindObj.Children, layoutOrigin, layoutDirection, layoutReverse, layoutPadding, layoutSpacing, lineCount, duration, ease, finishCallback)
end

--震动
function UIWidget:Shake(duration, params, finishCallback)
    UITweenUtils:Shake(self.bindObj, duration, params, finishCallback)
end

-----------------------------------------------------------基础动画-----------------------------------------------------------
--跳跃
function UIWidget:JumpTo(position, height, duration)
    return UITweenUtils:JumpTo(self.bindObj, position, height, duration)
end

--跳跃
function UIWidget:JumpBy(position, height, duration)
    return UITweenUtils:JumpBy(self.bindObj, position, height, duration)
end

--移动
function UIWidget:MoveTo(position, duration)
    return UITweenUtils:MoveTo(self.bindObj, position, duration)
end

--移动
function UIWidget:MoveBy(position, duration)
    return UITweenUtils:MoveBy(self.bindObj, position, duration)
end

--大小
function UIWidget:SizeTo(size, duration)
    return UITweenUtils:SizeTo(self.bindObj, size, duration)
end

--大小
function UIWidget:SizeBy(size, duration)
    return UITweenUtils:SizeBy(self.bindObj, size, duration)
end

--缩放
function UIWidget:ScaleTo(scale, duration)
    return UITweenUtils:ScaleTo(self.bindObj, scale, duration)
end

--缩放
function UIWidget:ScaleBy(scale, duration)
    return UITweenUtils:ScaleBy(self.bindObj, scale, duration)
end

--旋转
function UIWidget:RotateTo(rotation, duration)
    return UITweenUtils:RotateTo(self.bindObj, rotation, duration)
end

--旋转
function UIWidget:RotateBy(rotation, duration)
    return UITweenUtils:RotateBy(self.bindObj, rotation, duration)
end

--颜色
function UIWidget:ColorTo(color, duration)
    return UITweenUtils:ColorTo(self.bindObj, color, duration)
end

--颜色
function UIWidget:ColorBy(color, duration)
    return UITweenUtils:ColorBy(self.bindObj, color, duration)
end

--透明度
function UIWidget:AlphaTo(alpha, duration)
    return UITweenUtils:AlphaTo(self.bindObj, alpha, duration)
end

--透明度
function UIWidget:AlphaBy(alpha, duration)
    return UITweenUtils:AlphaBy(self.bindObj, alpha, duration)
end



-----------------------------------交互效果-----------------------------------
--启用触摸缩放
function UIWidget:EnableTouchScaleAnimation(scale)
    self.touchScaleAnimation = scale or 1.1
end

--禁用触摸缩放
function UIWidget:DisableTouchScaleAnimation()
    self.touchScaleAnimation = nil
end

--启用点击缩放
function UIWidget:EnableClickScaleAnimation(scale, clickedCallbackDelay)
    self.clickScaleAnimation = scale or 1.1
    self.clickedCallbackDelay = clickedCallbackDelay == nil and true or clickedCallbackDelay
end

--禁用点击缩放
function UIWidget:DisableClickScaleAnimation()
    self.clickScaleAnimation = nil
end

--设置是否启用双击
function UIWidget:SetDoubleClickedEnabled(doubleClickEnabled)
    self.isDoubleClickEnabled = doubleClickEnabled
    if not doubleClickEnabled then
        self.lastClickTime = 0
        self.lastClickPos = nil
        self.doubleClickedCallback = nil
        -- 清理单击延迟定时器
        if self.singleClickTimerId then
            UITimer:RemoveTimer(self.singleClickTimerId)
            self.singleClickTimerId = nil
        end
    end
end

--双击事件
function UIWidget:DoubleClickedCallback(callback)
    self.doubleClickedCallback = callback
end

return UIWidget