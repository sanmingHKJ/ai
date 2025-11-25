-- 说明:滚动控件
-- 日期:2025年1月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIUtils = GFScript("UIModule.UIUtils")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local SuperItem = GFScript("UIModule.UIWidget.SuperItem")

local SuperScrollView = UIClass.New("SuperScrollView", UIWidget)


function SuperScrollView:Constructor()
    self.content = nil  --内容控件节点

    self.scrollDirection = "Vertical"  --滚动方向："Vertical"(垂直) 或 "Horizontal"(水平)
    self.viewportWidth = 0   --可视区域宽度
    self.viewportHeight = 0  --可视区域高度
    self.contentSize = {width = 0, height = 0}  --内容实际大小
    self.decelerationRate = 0.95  --减速系数
    self.isPressed = false  --是否正在拖拽
    self.lastTouchPos = {x = 0, y = 0}  --上一次触摸位置

    --回弹相关参数
    self.elasticity = 0.3         --弹性系数
    self.maxOverscroll = 50       --最大越界距离
    self.bounceBackDuration = 0.3 --回弹动画持续时间
    self.bounceBackProgress = 0   --回弹动画进度
    self.isOverscrolling = false  --是否处于越界状态
    self.targetPosition = {x = 0, y = 0}    --目标位置
    self.currentPosition = {x = 0, y = 0}   --当前位置
    self.bounceBackSpeed = 300   --回弹速度（像素/秒）
    self.boundaryResistance = 100 --边界阻力系数，值越大阻力越小

    -- 滚动控制属性
    self.scrollEnabled = true  -- 是否允许滚动
    self.horizontalScrollEnabled = true  -- 是否允许水平滚动
    self.verticalScrollEnabled = true    -- 是否允许垂直滚动

    -- 添加脏标记
    self.isDirty = false  -- 标记是否需要更新可见项
    self.lastScrollPosition = {x = 0, y = 0}  -- 记录上次滚动位置
    self.dirtyThreshold = 1  -- 滚动位置变化阈值，超过此值才更新（可根据实际需求调整）

    -- 是否裁剪
    self.clipped = false -- 是否裁剪

    -- 触摸相关
    self.touchMoveDisplacements = {} -- 触摸移动偏移量
    self.touchMoveTimeDeltas = {} -- 触摸移动时间差
    self.touchMovePreviousTimestamp = 0 -- 触摸移动前时间戳

    -- 自动滚动相关
    self.autoScrolling = false -- 自动滚动是否开启
    self.autoScrollAttenuate = true -- 自动滚动衰减
    self.autoScrollStartPosition = {x = 0, y = 0} -- 自动滚动开始位置
    self.autoScrollTargetDelta = {x = 0, y = 0} -- 自动滚动目标偏移量
    self.autoScrollTotalTime = 0 -- 自动滚动总时间
    self.autoScrollAccumulatedTime = 0 -- 自动滚动累积时间
    self.autoScrollCurrentlyOutOfBoundary = false -- 自动滚动是否超出边界
    self.autoScrollBraking = false -- 自动滚动是否刹车
    self.autoScrollBrakingStartPosition = {x = 0, y = 0} -- 自动滚动刹车开始位置
    
    -- 惯性滚动
    self.inertiaScrollEnabled = true -- 惯性滚动是否启用
    
    -- 回弹相关
    self.bounceEnabled = true -- 回弹是否启用
    self.outOfBoundaryAmount = {x = 0, y = 0} -- 超出边界量
    self.outOfBoundaryAmountDirty = true -- 超出边界量是否需要更新

    self.pendingBounceCheck = false -- 是否需要检查回弹

    --是否允许超出边界
    self.allowOutOfBoundary = false

    --是否让Viewport跟随ContentSize变化
    self.followContentSize = false
end

function SuperScrollView:Destructor()
    
    -- 清理content节点
    if self.content then
        -- 断开 TouchBegin, TouchEnd, TouchMove 的连接
        self.content:Destroy()
        self.content = nil
    end

    -- if self.touchPad then
    --     self.touchPad:Destroy()
    --     self.touchPad = nil
    -- end

    if self.viewport then
        self.viewport:Destroy()
        self.viewport = nil
    end
end

--[[
    初始化滚动视图
    @param bindObj: 绑定的UI对象
    @param viewportWidth: 视口宽度
    @param viewportHeight: 视口高度
]]
function SuperScrollView:Init(bindObj)
    if not SuperScrollView.super.Init(self, bindObj) then
        return false
    end
    local viewportWidth = bindObj.Size.X
    local viewportHeight = bindObj.Size.Y
    if viewportWidth <= 0 or viewportHeight <= 0 then
        UILog:Error("Init: invalid viewport size")
        return false
    end

    self:EnableUpdate()

    self.bindObj.OverflowType = Enum.OverflowType.HIDDEN
    self.bindObj.ColumnCount = 0
    self.bindObj.LineCount = 0
    self.bindObj.LineGap = 0
    self.bindObj.ColumnGap = 0
    self.bindObj.AutoResizeItem = false
    self.bindObj.Padding = Vector4.New(0, 0, 0, 0)

    self.viewportWidth = viewportWidth
    self.viewportHeight = viewportHeight
    self:UpdateContentSize()
    self:InitContent()

    return true
end

--[[
    设置是否裁剪
    @param clipped: 是否裁剪
]]
function SuperScrollView:SetClipped(clipped)
    self.clipped = clipped

    if self.clipped then
        self.bindObj.OverflowType = Enum.OverflowType.HIDDEN
    else
        self.bindObj.OverflowType = Enum.OverflowType.VISIBLE
    end
end

--[[
    获取是否裁剪
    @return: 是否裁剪
]]
function SuperScrollView:IsClipped()
    return self.clipped
end

--[[
    初始化内容节点，设置触摸事件监听
]]
function SuperScrollView:InitContent()
    self.viewport = SandboxNode.New("UIImage")
    self.viewport.Name = "Viewport"
    self.viewport.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    self.viewport.Parent = self.bindObj
    self.viewport.Pivot = Vector2.New(0, 0)
    self.viewport.Position  = Vector2.New(0, 0)
    self.viewport.Size  = Vector2.New(self.viewportWidth, self.viewportHeight)

    self.content = SandboxNode.New("UIImage")
    self.content.Name = "Content"
    self.content.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    self.content.Parent = self.viewport
    self.content.Pivot = Vector2.New(0, 0)
    self.content.Position  = Vector2.New(0, 0)
    self.content.Size  = Vector2.New(self.viewportWidth, self.viewportHeight)
    self.content.IsNotifyEventStop = true
    self.content.ClickPass = false

    -- self.touchPad = SandboxNode.New("UIImage")
    -- self.touchPad.Name = "TouchPad"
    -- self.touchPad.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    -- self.touchPad.Parent = self.viewport
    -- self.touchPad.Pivot = Vector2.New(0, 0)
    -- self.touchPad.Position  = Vector2.New(0, 0)
    -- self.touchPad.Size  = Vector2.New(self.viewportWidth, self.viewportHeight)
    

    if self.content then
        self.content.TouchBegin:Connect(function(node, issuccess, mousepos)
            if not self.scrollEnabled then return end
            self:HandlePressUILogic(Vec2.New(mousepos.X, mousepos.Y))
        end)

        self.content.TouchEnd:Connect(function(node, issuccess, mousepos)
            if not self.scrollEnabled then return end
            self:HandleReleaseUILogic(Vec2.New(mousepos.X, mousepos.Y))
        end)

        self.content.TouchMove:Connect(function(node, issuccess, mousepos)
            if not self.scrollEnabled then return end
            self:HandleMoveUILogic(Vec2.New(mousepos.X, mousepos.Y))
        end)
        
        self.content.Click:Connect(function(node, issuccess, mousepos)
            -- UILog:Error("@@@@@@@@@@@@@@@@@@@@@@ content.Click")
        end)
    end
end


--设置事件穿透
function SuperScrollView:SetEventPass(eventPass)
    self.eventPass = eventPass
    if self.bindObj then
        self.bindObj.IsNotifyEventStop = not eventPass
    end
    if self.viewport then
        self.viewport.IsNotifyEventStop = not eventPass
    end
    if self.content then
        self.content.IsNotifyEventStop = not eventPass
    end
end


function SuperScrollView:OnLinkTouchBegin(touchPos, touchId)
    
end

function SuperScrollView:OnLinkTouchMove(touchPos, touchId)
    
end

function SuperScrollView:OnLinkTouchEnd(touchPos, touchId)
    
end

function SuperScrollView:OnLinkClicked(touchPos, touchId)
    
end

--[[
    处理按下逻辑
]]
function SuperScrollView:HandlePressUILogic(mousepos)
    self.isPressed = true
    self.autoScrolling = false
    
    -- 清理触摸移动信息
    self.touchMovePreviousTimestamp = os.clock()
    self.touchMoveDisplacements = {}
    self.touchMoveTimeDeltas = {}
    
    self.lastTouchPos = mousepos
end

--[[
    处理移动逻辑
    @param mousepos: 鼠标位置
]]
function SuperScrollView:HandleMoveUILogic(mousepos)
    if not self.isPressed then return end
    -- 计算触摸移动距离
    local deltaX = mousepos.x - self.lastTouchPos.x
    local deltaY = mousepos.y - self.lastTouchPos.y
    
    -- 根据滚动方向确定是否可以滚动
    local canScrollVertical = self.scrollDirection == "Vertical" or self.scrollDirection == "Both"
    local canScrollHorizontal = self.scrollDirection == "Horizontal" or self.scrollDirection == "Both"
    
    -- 根据滚动方向过滤移动距离
    local delta = {
        x = canScrollHorizontal and deltaX or 0,
        y = canScrollVertical and deltaY or 0
    }

    -- 处理滚动事件
    if not self.scrolling and (math.abs(delta.x) > 0 or math.abs(delta.y) > 0) then
        self:ProcessScrollingEvent()
    end
    
    -- 滚动内容
    self:ScrollChildren(delta)
    
    -- 收集触摸移动数据用于计算速度
    self:GatherTouchMove(delta)
    
    -- 更新最后触摸位置
    self.lastTouchPos = mousepos
end

--[[
    处理释放逻辑
]]
function SuperScrollView:HandleReleaseUILogic(mousepos)
    if not self.isPressed then return end
    
    -- 收集最后的触摸信息
    local deltaX = mousepos.x - self.lastTouchPos.x
    local deltaY = mousepos.y - self.lastTouchPos.y
    self:GatherTouchMove({x = deltaX, y = deltaY})
    
    self.isPressed = false
    
    -- 检查是否需要回弹
    local bounceBackStarted = false
    if self.bounceEnabled and not self.allowOutOfBoundary then
        bounceBackStarted = self:StartBounceBackIfNeeded()
    end
    
    if not bounceBackStarted and self.inertiaScrollEnabled then
        -- 计算触摸移动速度并开始惯性滚动
        local touchMoveVelocity = self:CalculateTouchMoveVelocity()
        if touchMoveVelocity.x ~= 0 or touchMoveVelocity.y ~= 0 then
            self:StartInertiaScroll(touchMoveVelocity)
        end
    end
end

--[[
    收集触摸移动数据
    @param delta: 移动距离
]]
function SuperScrollView:GatherTouchMove(delta)
    -- 保持最多5个采样点
    while #self.touchMoveDisplacements >= 5 do
        table.remove(self.touchMoveDisplacements, 1)
        table.remove(self.touchMoveTimeDeltas, 1)
    end
    
    -- 添加新的移动数据
    table.insert(self.touchMoveDisplacements, delta)
    local currentTime = os.clock()
    table.insert(self.touchMoveTimeDeltas, currentTime - self.touchMovePreviousTimestamp)
    self.touchMovePreviousTimestamp = currentTime
end

--[[
    滚动内容
    @param delta: 移动距离
]]
function SuperScrollView:ScrollChildren(delta)
    local realMove = {x = delta.x, y = delta.y}
    
    if self.bounceEnabled and not self.allowOutOfBoundary then
        -- 如果内容超出边界，移动距离减半
        local outOfBoundary = self:GetHowMuchOutOfBoundary()
        realMove.x = realMove.x * (outOfBoundary.x == 0 and 1 or 0.5)
        realMove.y = realMove.y * (outOfBoundary.y == 0 and 1 or 0.5)
    else
        -- 不允许超出边界，但提供更平滑的边界限制
        local outOfBoundary = self:GetHowMuchOutOfBoundary(realMove)
        
        -- 如果即将超出边界，逐渐减少移动距离而不是完全阻止
        if outOfBoundary.x ~= 0 then
            local resistance = math.max(0.1, 1 - math.abs(outOfBoundary.x) / self.boundaryResistance) -- 根据超出距离计算阻力
            realMove.x = realMove.x * resistance
        end
        
        if outOfBoundary.y ~= 0 then
            local resistance = math.max(0.1, 1 - math.abs(outOfBoundary.y) / self.boundaryResistance) -- 根据超出距离计算阻力
            realMove.y = realMove.y * resistance
        end
    end
    
    -- 移动内容容器
    self:MoveInnerContainer(realMove, false)
end

--[[
    移动内容容器
    @param delta: 移动距离
    @param canStartBounceBack: 是否可以开始回弹
]]
function SuperScrollView:MoveInnerContainer(delta, canStartBounceBack)
    -- 计算新位置
    local newPosition = {
        x = self.currentPosition.x + delta.x,
        y = self.currentPosition.y + delta.y
    }
    
    -- 设置内容位置
    self:SetContentPosition(newPosition.x, newPosition.y)
    
    -- 标记需要更新可见项
    self.isDirty = true
    
    -- 处理回弹
    if self.bounceEnabled and canStartBounceBack and not self.allowOutOfBoundary then
        self:StartBounceBackIfNeeded()
    end
end

--[[
    更新方法
    @param deltaTime: 帧间隔时间
]]
function SuperScrollView:Update(deltaTime)
    -- if not self.scrollEnabled then return end
    
    -- 处理自动滚动
    if self.autoScrolling then
        self:ProcessAutoScrolling(deltaTime)
    end
    
    -- 处理待定的回弹检查
    if self.pendingBounceCheck then
        self.pendingBounceCheck = false
        self:StartBounceBackIfNeeded()
    end
    
    -- 更新可见项
    if self.isDirty then
        local needUpdate = false
        
        -- 如果是SetData后的第一次更新，强制更新可见项
        if self.forceUpdate then
            needUpdate = true
            self.forceUpdate = false
        else
            -- 正常的滚动更新检查
            if self.scrollDirection == "Vertical" then
                local deltaY = math.abs(self.currentPosition.y - self.lastScrollPosition.y)
                needUpdate = deltaY > self.dirtyThreshold
            else -- Horizontal
                local deltaX = math.abs(self.currentPosition.x - self.lastScrollPosition.x)
                needUpdate = deltaX > self.dirtyThreshold
            end
        end
        
        if needUpdate then
            self:UpdateScrollView()
            self.lastScrollPosition.x = self.currentPosition.x
            self.lastScrollPosition.y = self.currentPosition.y
        end
        
        self.isDirty = false
    end
end

--强制更新
function SuperScrollView:ForceUpdate()
    self.forceUpdate = true
    self.isDirty = true
end

--[[
    滚动变化
]]
function SuperScrollView:UpdateScrollView()
    
end

--[[
    计算内容大小，考虑了内边距和间距
]]
function SuperScrollView:UpdateContentSize()
    if self.content then
        local rect = UIUtils:FitSize(self.content, 0, 0)
        self:SetContentSize(rect.width, rect.height)
    end
end

--设置内容大小
function SuperScrollView:SetContentSize(width, height)
    self.contentSize = { width = width, height = height }
    if self.content then
        self.content.Size  = Vector2.New(self.contentSize.width, self.contentSize.height)
        
        -- 如果启用了viewport跟随contentSize，则更新viewport大小
        if self.followContentSize and self.viewport then
            self:SetFollowContentSize(true)
        end
    end
end

--[[
    设置Viewport是否跟随ContentSize变化
    @param follow: 是否跟随
]]
function SuperScrollView:SetFollowContentSize(follow)
    self.followContentSize = follow
    if follow and self.content and self.viewport then

        local screenPos = self:GetScreenPosition()
        self:SetSize(Vec2.New(self.contentSize.width, self.contentSize.height))

        self.viewportWidth = self.contentSize.width
        self.viewportHeight = self.contentSize.height
        self.viewport.Pivot = Vector2.New(0, 0)
        self.viewport.Position  = Vector2.New(0, 0)
        self.viewport.Size  = Vector2.New(self.viewportWidth, self.viewportHeight)

        self:SetScreenPosition(screenPos)
    end
end

--获取内容大小
function SuperScrollView:GetContentSize()
    return self.contentSize.width, self.contentSize.height
end

function SuperScrollView:FitSize(expandX, expandY, minWidth, minHeight)
    self:SetSize(Vec2.New(self.contentSize.width, self.contentSize.height))

    self.viewportWidth = self.contentSize.width
    self.viewportHeight = self.contentSize.height
    self.viewport.Pivot = Vector2.New(0, 0)
    self.viewport.Position  = Vector2.New(0, 0)
    self.viewport.Size  = Vector2.New(self.viewportWidth, self.viewportHeight)
end

--添加控件
function SuperScrollView:AddControl(control, keepScreenPos)
    UIUtils:SetParent(control, self.content, keepScreenPos)
end

--[[
    设置滚动方向
    @param direction: "Vertical"(垂直) 或 "Horizontal"(水平)
]]
function SuperScrollView:SetScrollDirection(direction)
    self.scrollDirection = direction
    self:UpdateContentSize()
end

--[[
    应用弹性边界效果
    @param position: 目标位置
    @return: 应用弹性效果后的实际位置
    主要功能:
    1. 检测是否超出边界
    2. 根据弹性系数计算实际位置
    3. 实现软性边界效果
]]
function SuperScrollView:ApplyElasticBounds(position)
    local result = {x = position.x, y = position.y}
    
    if self.scrollDirection == "Vertical" then
        local minY = self.viewportHeight - self.contentSize.height
        local maxY = 0
        
        if position.y < minY then
            local delta = position.y - minY
            result.y = minY + delta * self.elasticity
        elseif position.y > maxY then
            local delta = position.y - maxY
            result.y = maxY + delta * self.elasticity
        end
    else
        local minX = self.viewportWidth - self.contentSize.width
        local maxX = 0
        
        if position.x < minX then
            local delta = position.x - minX
            result.x = minX + delta * self.elasticity
        elseif position.x > maxX then
            local delta = position.x - maxX
            result.x = maxX + delta * self.elasticity
        end
    end
    
    return result
end

function SuperScrollView:GetScrollPosition()
    return self.currentPosition.x, self.currentPosition.y
end

--[[
    刷新布局
    主要功能:
    1. 重新计算内容大小
    2. 更新内容节点尺寸
    3. 刷新可见项目
]]
function SuperScrollView:RefreshLayout()
    self:UpdateContentSize()
end


--[[
    设置是否启用滚动
    @param enabled: 是否启用滚动
]]
function SuperScrollView:SetScrollEnabled(enabled)
    self.scrollEnabled = enabled
end

--[[
    设置水平滚动启用状态
    @param enabled: 是否启用水平滚动
]]
function SuperScrollView:SetHorizontalScrollEnabled(enabled)
    self.horizontalScrollEnabled = enabled
end

--[[
    设置垂直滚动启用状态
    @param enabled: 是否启用垂直滚动
]]
function SuperScrollView:SetVerticalScrollEnabled(enabled)
    self.verticalScrollEnabled = enabled
end

--[[
    计算触摸移动速度
    @return: 移动速度向量
]]
function SuperScrollView:CalculateTouchMoveVelocity()
    local totalTime = 0
    local totalMoveX = 0
    local totalMoveY = 0
    
    -- 计算最近几次移动的平均速度
    local samples = math.min(5, #self.touchMoveTimeDeltas)
    if samples == 0 then
        return {x = 0, y = 0}
    end
    
    -- 从最近的移动开始计算
    for i = #self.touchMoveTimeDeltas - samples + 1, #self.touchMoveTimeDeltas do
        if i > 0 then
            local delta = self.touchMoveDisplacements[i]
            local time = self.touchMoveTimeDeltas[i]
            
            totalMoveX = totalMoveX + delta.x
            totalMoveY = totalMoveY + delta.y
            totalTime = totalTime + time
        end
    end
    
    -- 避免除以零
    if totalTime <= 0.0001 then
        return {x = 0, y = 0}
    end
    
    -- 计算速度
    local velocityX = totalMoveX / totalTime
    local velocityY = totalMoveY / totalTime
    
    -- 限制最大速度
    local maxVelocity = 2000 -- 可以根据需要调整
    local velocityLength = math.sqrt(velocityX * velocityX + velocityY * velocityY)
    if velocityLength > maxVelocity then
        local scale = maxVelocity / velocityLength
        velocityX = velocityX * scale
        velocityY = velocityY * scale
    end
    
    return {x = velocityX, y = velocityY}
end

--[[
    开始惯性滚动
    @param velocity: 初始速度
]]
function SuperScrollView:StartInertiaScroll(velocity)
    if not self.inertiaScrollEnabled then
        return
    end
    
    -- 根据滚动方向过滤速度
    if self.scrollDirection == "Vertical" then
        velocity.x = 0
    elseif self.scrollDirection == "Horizontal" then
        velocity.y = 0
    end
    
    -- 计算滚动距离和时间
    local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
    if speed < 10 then
        return -- 速度太小，不进行惯性滚动
    end
    
    -- 计算减速距离
    local deceleration = 1000 -- 减速度，可以根据需要调整
    local time = speed / deceleration -- 减速到零所需的时间
    
    -- 计算滚动距离
    local deltaX = velocity.x * time * 0.5 -- 匀减速运动，距离 = 初速度 * 时间 * 0.5
    local deltaY = velocity.y * time * 0.5
    
    -- 检查是否会超出边界，如果会超出边界，调整滚动距离和时间
    local targetPosition = {
        x = self.currentPosition.x + deltaX,
        y = self.currentPosition.y + deltaY
    }
    
    if not self.allowOutOfBoundary then
        -- 获取边界限制
        local minX, maxX, minY, maxY = self:GetBoundaries()
        
        -- 调整目标位置到边界内
        if targetPosition.x > maxX then
            deltaX = maxX - self.currentPosition.x
        elseif targetPosition.x < minX then
            deltaX = minX - self.currentPosition.x
        end
        
        if targetPosition.y > maxY then
            deltaY = maxY - self.currentPosition.y
        elseif targetPosition.y < minY then
            deltaY = minY - self.currentPosition.y
        end
    end
    
    -- 重新计算时间，保持减速感
    local adjustedDelta = math.sqrt(deltaX * deltaX + deltaY * deltaY)
    local adjustedTime = time
    if adjustedDelta > 0 then
        -- 按比例调整时间
        local originalDelta = math.sqrt((velocity.x * time * 0.5) * (velocity.x * time * 0.5) + 
                                       (velocity.y * time * 0.5) * (velocity.y * time * 0.5))
        if originalDelta > 0 then
            adjustedTime = time * (adjustedDelta / originalDelta)
        end
    end
    
    -- 开始自动滚动
    self:StartAutoScroll({x = deltaX, y = deltaY}, adjustedTime, true)
end

--[[
    获取滚动边界
    @return: minX, maxX, minY, maxY
]]
function SuperScrollView:GetBoundaries()
    local maxX = 0
    local maxY = 0
    local minX = self.viewportWidth - self.contentSize.width
    local minY = self.viewportHeight - self.contentSize.height
    
    -- 确保最小值不大于最大值
    minX = math.min(minX, maxX)
    minY = math.min(minY, maxY)
    
    return minX, maxX, minY, maxY
end

--[[
    处理自动滚动
    @param deltaTime: 帧间隔时间
]]
function SuperScrollView:ProcessAutoScrolling(deltaTime)
    if not self.autoScrolling then
        return
    end
    
    -- 累计时间
    self.autoScrollAccumulatedTime = self.autoScrollAccumulatedTime + deltaTime
    
    -- 计算进度百分比
    local percentage = math.min(1, self.autoScrollAccumulatedTime / self.autoScrollTotalTime)
    
    -- 使用缓动函数
    if self.autoScrollAttenuate then
        percentage = 1 - math.pow(1 - percentage, 3) -- 三次方缓动
    end
    
    -- 计算新位置
    local newPosition = {
        x = self.autoScrollStartPosition.x + (self.autoScrollTargetDelta.x * percentage),
        y = self.autoScrollStartPosition.y + (self.autoScrollTargetDelta.y * percentage)
    }
    
    -- 检查是否到达终点
    local reachedEnd = percentage >= 0.999
    
    -- 检查是否超出边界
    if not self.bounceEnabled and not self.allowOutOfBoundary then
        local minX, maxX, minY, maxY = self:GetBoundaries()
        
        -- 如果超出边界，立即停止自动滚动并触发回弹
        if newPosition.x > maxX or newPosition.x < minX or 
           newPosition.y > maxY or newPosition.y < minY then
            reachedEnd = true
            
            -- 限制位置在边界内
            newPosition.x = math.max(minX, math.min(maxX, newPosition.x))
            newPosition.y = math.max(minY, math.min(maxY, newPosition.y))
        end
    end
    
    -- 移动内容
    self:MoveInnerContainer({
        x = newPosition.x - self.currentPosition.x,
        y = newPosition.y - self.currentPosition.y
    }, not reachedEnd)  -- 只有在未到达终点时才允许继续自动滚动
    
    -- 如果到达目标位置则结束自动滚动
    if reachedEnd then
        self.autoScrolling = false
        
        -- 检查是否需要再次回弹（处理可能的越界情况）
        if self.bounceEnabled and not self.allowOutOfBoundary then
            self.pendingBounceCheck = true
        end
    end
end

--[[
    检查是否需要开始回弹,如果需要则开始回弹动画
    @return: 是否开始了回弹
]]
function SuperScrollView:StartBounceBackIfNeeded()
    if not self.bounceEnabled or self.allowOutOfBoundary then
        return false
    end
    
    -- 如果已经在自动滚动，不要开始新的回弹
    if self.autoScrolling then
        return false
    end
    
    local bounceBackAmount = self:GetHowMuchOutOfBoundary()
    
    -- 检查是否需要回弹
    if math.abs(bounceBackAmount.x) < 0.5 and math.abs(bounceBackAmount.y) < 0.5 then
        return false
    end
    
    -- 根据回弹距离动态计算时间，保持回弹速度一致
    local distance = math.sqrt(bounceBackAmount.x * bounceBackAmount.x + bounceBackAmount.y * bounceBackAmount.y)
    local duration = distance / self.bounceBackSpeed
    
    -- 限制最小和最大时间
    duration = math.max(0.1, math.min(1.5, duration))
    
    -- 开始回弹
    self:StartAutoScroll(bounceBackAmount, duration, true)
    return true
end

--[[
    开始自动滚动
    @param deltaMove: 目标移动距离
    @param timeInSec: 滚动时间
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:StartAutoScroll(deltaMove, timeInSec, attenuated)
    -- 如果已经在自动滚动，先停止当前滚动
    self.autoScrolling = false
    
    -- 根据滚动方向过滤移动
    if self.scrollDirection == "Vertical" then
        deltaMove.x = 0
    elseif self.scrollDirection == "Horizontal" then
        deltaMove.y = 0
    end
    
    -- 如果移动距离太小，不进行滚动
    if math.abs(deltaMove.x) < 0.1 and math.abs(deltaMove.y) < 0.1 then
        return
    end
    
    self.autoScrolling = true
    self.autoScrollTargetDelta = deltaMove
    self.autoScrollAttenuate = attenuated
    self.autoScrollStartPosition = {
        x = self.currentPosition.x,
        y = self.currentPosition.y
    }
    self.autoScrollTotalTime = timeInSec
    self.autoScrollAccumulatedTime = 0
end

--[[
    获取内容超出边界的距离
    @param position: 位置
    @return: 超出边界的距离向量
]]
function SuperScrollView:GetHowMuchOutOfBoundary(position)
    if self.allowOutOfBoundary then
        return {x = 0, y = 0}
    end
    position = position or self.currentPosition
    local outOfBoundaryAmount = {x = 0, y = 0}
    
    if self.scrollDirection == "Horizontal" then
        -- 检查水平方向
        local leftBoundary = 0
        local rightBoundary = math.min(0, self.viewportWidth - self.contentSize.width)
        
        if position.x > leftBoundary then
            outOfBoundaryAmount.x = leftBoundary - position.x
        elseif position.x < rightBoundary then
            outOfBoundaryAmount.x = rightBoundary - position.x
        end
    else -- Vertical
        -- 检查垂直方向
        local topBoundary = 0
        local bottomBoundary = math.min(0, self.viewportHeight - self.contentSize.height)
        
        if position.y > topBoundary then
            outOfBoundaryAmount.y = topBoundary - position.y
        elseif position.y < bottomBoundary then
            outOfBoundaryAmount.y = bottomBoundary - position.y
        end
    end
    
    return outOfBoundaryAmount
end

--[[
    根据滚动方向调整向量
    @param vector: 输入向量
    @return: 调整后的向量
]]
function SuperScrollView:FlattenVectorByDirection(vector)
    local result = {x = vector.x, y = vector.y}
    if self.scrollDirection == "Vertical" then
        result.x = 0
    elseif self.scrollDirection == "Horizontal" then
        result.y = 0
    end
    return result
end

--[[
    判断是否需要自动滚动制动
    @return: 是否需要制动
]]
function SuperScrollView:IsNecessaryAutoScrollBrake()
    if not self.autoScrolling or self.autoScrollBraking then
        return false
    end
    
    if self.bounceEnabled and not self.allowOutOfBoundary then
        return false
    end
    
    -- 计算预期位置
    local nextPosition = {
        x = self.currentPosition.x + self.autoScrollTargetDelta.x,
        y = self.currentPosition.y + self.autoScrollTargetDelta.y
    }
    
    -- 检查是否会超出边界
    if not self:FltEqualZero(self:GetHowMuchOutOfBoundary(nextPosition)) then
        return true
    end
    
    return false
end

--[[
    获取自动滚动停止的误差范围
    @return: 误差范围
]]
function SuperScrollView:GetAutoScrollStopEpsilon()
    return 0.0001
end

--[[
    判断浮点数是否接近零
    @param value: 要判断的值
    @return: 是否接近零
]]
function SuperScrollView:FltEqualZero(value)
    if type(value) == "table" then
        return math.abs(value.x) <= 0.0001 and math.abs(value.y) <= 0.0001
    end
    return math.abs(value) <= 0.0001
end

--[[
    设置内容位置
    @param x: x坐标
    @param y: y坐标
]]
function SuperScrollView:SetContentPosition(x, y)
    self.currentPosition.x = x
    self.currentPosition.y = y
    if self.content then
        self.content.Position  = Vector2.New(x, y)
    end
    self.outOfBoundaryAmountDirty = true
end

--[[
    开始减速自动滚动
    @param deltaMove: 总移动距离
    @param initialVelocity: 初始速度
]]
function SuperScrollView:StartAttenuatingAutoScroll(deltaMove, initialVelocity)
    -- 根据初始速度计算滚动时间
    local time = self:CalculateAutoScrollTimeByInitialSpeed(initialVelocity.length())
    self:StartAutoScroll(deltaMove, time, true)
end

--[[
    根据初始速度计算自动滚动时间
    @param initialSpeed: 初始速度
    @return: 计算得到的时间
]]
function SuperScrollView:CalculateAutoScrollTimeByInitialSpeed(initialSpeed)
    -- 使用五次方根计算时间
    local time = math.sqrt(math.sqrt(initialSpeed / 5))
    return time
end

-- 应该添加滚动事件处理
function SuperScrollView:ProcessScrollingEvent()
    if not self.scrolling then
        self.scrolling = true
        self:FireClient("ScrollingBegan")
    end
    self:FireClient("Scrolling")
end

function SuperScrollView:ProcessScrollingEndedEvent()
    self.scrolling = false 
    self:FireClient("ScrollingEnded")
end

--[[
    滚动到指定位置
    @param targetPos: 目标位置
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollTo(targetPos, timeInSec, attenuated)
    if not timeInSec or timeInSec <= 0 then
        -- 如果没有指定时间或时间为0，直接跳转
        self:JumpTo(targetPos)
        return
    end

    -- 计算滚动增量
    local delta = {
        x = targetPos.x - self.currentPosition.x,
        y = targetPos.y - self.currentPosition.y
    }

    -- 开始自动滚动
    self.autoScrolling = true
    self.autoScrollTargetDelta = delta
    self.autoScrollAttenuate = attenuated
    self.autoScrollStartPosition = {
        x = self.currentPosition.x,
        y = self.currentPosition.y
    }
    self.autoScrollTotalTime = timeInSec
    self.autoScrollAccumulatedTime = 0
    self.autoScrollBraking = false
    self.autoScrollBrakingStartPosition = {x = 0, y = 0}
end

--[[
    滚动到顶部
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollToTop(timeInSec, attenuated)
    if self.scrollDirection == "Vertical" then
        self:ScrollTo({x = self.currentPosition.x, y = 0}, timeInSec, attenuated)
    end
end

--[[
    滚动到底部
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollToBottom(timeInSec, attenuated)
    if self.scrollDirection == "Vertical" then
        local minY = self.viewportHeight - self.contentSize.height
        self:ScrollTo({x = self.currentPosition.x, y = minY}, timeInSec, attenuated)
    end
end

--[[
    滚动到左边
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollToLeft(timeInSec, attenuated)
    if self.scrollDirection == "Horizontal" then
        self:ScrollTo({x = 0, y = self.currentPosition.y}, timeInSec, attenuated)
    end
end

--[[
    滚动到右边
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollToRight(timeInSec, attenuated)
    if self.scrollDirection == "Horizontal" then
        local minX = self.viewportWidth - self.contentSize.width
        self:ScrollTo({x = minX, y = self.currentPosition.y}, timeInSec, attenuated)
    end
end

--[[
    跳转到指定位置
    @param targetPos: 目标位置
]]
function SuperScrollView:JumpTo(targetPos)
    self.autoScrolling = false
    self:MoveInnerContainer({
        x = targetPos.x - self.currentPosition.x,
        y = targetPos.y - self.currentPosition.y
    }, true)
end

--[[
    跳转到顶部
]]
function SuperScrollView:JumpToTop()
    if self.scrollDirection == "Vertical" then
        self:JumpTo({x = self.currentPosition.x, y = 0})
    end
end

--[[
    跳转到底部
]]
function SuperScrollView:JumpToBottom()
    if self.scrollDirection == "Vertical" then
        local minY = self.viewportHeight - self.contentSize.height
        self:JumpTo({x = self.currentPosition.x, y = minY})
    end
end

--[[
    跳转到左边
]]
function SuperScrollView:JumpToLeft()
    if self.scrollDirection == "Horizontal" then
        self:JumpTo({x = 0, y = self.currentPosition.y})
    end
end

--[[
    跳转到右边
]]
function SuperScrollView:JumpToRight()
    if self.scrollDirection == "Horizontal" then
        local minX = self.viewportWidth - self.contentSize.width
        self:JumpTo({x = minX, y = self.currentPosition.y})
    end
end

--[[
    滚动到指定百分比位置(垂直)
    @param percent: 百分比(0-100)
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollToPercentVertical(percent, timeInSec, attenuated)
    if self.scrollDirection == "Vertical" then
        local minY = self.viewportHeight - self.contentSize.height
        local h = -minY
        self:ScrollTo({
            x = self.currentPosition.x,
            y = minY + percent * h / 100.0
        }, timeInSec, attenuated)
    end
end

--[[
    滚动到指定百分比位置(水平)
    @param percent: 百分比(0-100)
    @param timeInSec: 滚动时间(秒)
    @param attenuated: 是否使用缓动
]]
function SuperScrollView:ScrollToPercentHorizontal(percent, timeInSec, attenuated)
    if self.scrollDirection == "Horizontal" then
        local minX = self.viewportWidth - self.contentSize.width
        local w = -minX
        self:ScrollTo({
            x = minX + percent * w / 100.0,
            y = self.currentPosition.y
        }, timeInSec, attenuated)
    end
end

--[[
    停止普通滚动
]]
function SuperScrollView:StopScroll()
    if self.scrolling then

        self.scrolling = false
        self.isPressed = false

        self:StartBounceBackIfNeeded()

        self:FireClient("ScrollingEnded")
    end
end

--[[
    停止自动滚动
]]
function SuperScrollView:StopAutoScroll()
    if self.autoScrolling then

        self.autoScrolling = false
        self.autoScrollAttenuate = true
        self.autoScrollTotalTime = 0
        self.autoScrollAccumulatedTime = 0

        self:FireClient("AutoScrollEnded")
    end
end

--[[
    停止所有滚动
]]
function SuperScrollView:StopOverallScroll()
    self:StopScroll()
    self:StopAutoScroll()
end

--屏幕坐标转换为内容坐标
function SuperScrollView:MapScreenToContentSpace(screenPos)
    return UIUtils:MapScreenToLocal(self.content, screenPos)
end

--内容坐标转换为屏幕坐标
function SuperScrollView:MapContentToScreenSpace(contentPos)
    return UIUtils:MapLocalToScreen(self.content, contentPos)
end

--[[
    设置是否启用回弹效果
    @param enabled: 是否启用回弹效果
]]
function SuperScrollView:SetBounceEnabled(enabled)
    self.bounceEnabled = enabled
end

--[[
    获取是否启用回弹效果
    @return: 是否启用回弹效果
]]
function SuperScrollView:IsBounceEnabled()
    return self.bounceEnabled
end

--[[
    设置是否允许超出边界
    @param allowed: 是否允许超出边界
]]
function SuperScrollView:SetAllowOutOfBoundary(allowed)
    self.allowOutOfBoundary = allowed
end

--[[
    获取是否允许超出边界
    @return: 是否允许超出边界
]]
function SuperScrollView:IsAllowOutOfBoundary()
    return self.allowOutOfBoundary
end

--[[
    设置回弹速度
    @param speed: 回弹速度（像素/秒）
]]
function SuperScrollView:SetBounceBackSpeed(speed)
    self.bounceBackSpeed = speed
end

--[[
    获取回弹速度
    @return: 回弹速度（像素/秒）
]]
function SuperScrollView:GetBounceBackSpeed()
    return self.bounceBackSpeed
end

--[[
    设置边界阻力系数
    @param resistance: 边界阻力系数，值越大阻力越小
]]
function SuperScrollView:SetBoundaryResistance(resistance)
    self.boundaryResistance = resistance
end

--[[
    获取边界阻力系数
    @return: 边界阻力系数
]]
function SuperScrollView:GetBoundaryResistance()
    return self.boundaryResistance
end

return SuperScrollView


