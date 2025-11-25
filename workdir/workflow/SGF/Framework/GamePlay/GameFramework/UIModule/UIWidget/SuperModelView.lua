-- 说明:超级模型视图
-- 日期:2025年4月15日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Vec3 = GFScript("UIModule.UIMath.Vec3")
local Quat = GFScript("UIModule.UIMath.Quat")
local UIMath = GFScript("UIModule.UIMath")
local SuperModelView = UIClass.New("SuperModelView", UIWidget)

function SuperModelView:Constructor()
end

function SuperModelView:Destructor()
end

function SuperModelView:Init(bindObj)
    if not SuperModelView.super.Init(self, bindObj) then
        return false
    end
    self.bindObj.CameraLockX = true
    self.bindObj.CameraLockY = true
    --摄像机跟随的目标偏移
    self.offset = Vec3.New(0, 100, 0)
    self.pivotPositionSmoothSpeed = 4
    --锁定
    self.lockMouseX = false
    self.lockMouseY = false
    --反向
    self.invertMouseX = false
    self.invertMouseY = false
    --灵敏度
    self.mouseXSensitivity = 0.4
    self.mouseYSensitivity = 0.4
    self.wheelSensitivity = 50
    --范围限制
    self.mouseXMin = -90.0
    self.mouseXMax = 90.0
    self.mouseYMin = -89.9
    self.mouseYMax = 89.9
    --平滑时间
    self.mouseSmoothTime = 0.02
    --距离限制
    self.minDistance = 50
    self.maxDistance = 2000
    --距离平滑时间
    self.distanceSmoothTime = 0.2

    self._mouseX = 15
    self._mouseY = 0
    self._distance = 1000

    self._mouseXSmooth = self._mouseX
    self._mouseYSmooth = self._mouseY
    self._mouseSmoothTime = 0.02
    self._distanceSmooth = self._distance
    self._pivotPositionSmooth =  Vec3.New(0,0,0)
    self._pivotScale = Vec3.New(1,1,1)
    --速率记录
    self._mouseXCurrentVelocity = 0
    self._mouseYCurrentVelocity = 0
    self._distanceCurrentVelocity = 0

    self.currentCameraPos = Vec3.New(0,0,0)
    self.currentCameraRot = Quat.New(1,0,0,0)


    --触摸开始的位置
    self.touchBeginPos = Vec2.New(0,0)
    --上一个位置
    self.lastTouchPos = Vec2.New(0,0)
    --当前位置
    self.currentTouchPos = Vec2.New(0,0)
    --当前的摄像机旋转
    self._rotation = Quat.New(1,0,0,0)
    --记录最后点击的时间
    self.lastTouchTimeEnd = 0

    self.viewDirty = true
    self.projectionDirty = true

    self._zoomFactor = 1.0

    self.inputEnabled = true

    --根据同步bindObj的数据
    self._distance = self.bindObj.CameraDist
    self._distanceSmooth = self._distance
    self._mouseX = self.bindObj.CameraPitch
    self._mouseY = self.bindObj.CameraYaw
    self._mouseXSmooth = self._mouseX
    self._mouseYSmooth = self._mouseY

    self.offset = Vec3.New(self.bindObj.LookAtPosition.x,self.bindObj.LookAtPosition.y,self.bindObj.LookAtPosition.z)
    self._pivotPositionSmooth = self.offset

    self:EnableUpdate(0.02)

    return true
end

-- Getter and Setter functions
function SuperModelView:GetOffset()
    return self.offset
end

function SuperModelView:SetOffset(offset)
    self.offset = offset
end

--获取当前的yaw
function SuperModelView:GetYaw()
    return self._mouseYSmooth
end

--设置当前的yaw
function SuperModelView:SetYaw(yaw)
    self._mouseY = yaw
    self._mouseYSmooth = yaw
end

--获取当前的pitch
function SuperModelView:GetPitch()
    return self._mouseXSmooth
end

--设置当前的pitch
function SuperModelView:SetPitch(pitch)
    self._mouseX = pitch
    self._mouseXSmooth = pitch
end

--获取当前的距离
function SuperModelView:GetDistance()
    return self._distanceSmooth
end

--设置当前的距离
function SuperModelView:SetDistance(distance)
    self._distance = distance
    self._distanceSmooth = distance
end

function SuperModelView:GetPivotPositionSmoothSpeed()
    return self.pivotPositionSmoothSpeed
end

function SuperModelView:SetPivotPositionSmoothSpeed(speed)
    self.pivotPositionSmoothSpeed = speed
end

function SuperModelView:IsLockMouseX()
    return self.lockMouseX
end

function SuperModelView:SetLockMouseX(lock)
    self.lockMouseX = lock
end

function SuperModelView:IsLockMouseY()
    return self.lockMouseY
end

function SuperModelView:SetLockMouseY(lock)
    self.lockMouseY = lock
end

function SuperModelView:IsInvertMouseX()
    return self.invertMouseX
end

function SuperModelView:SetInvertMouseX(invert)
    self.invertMouseX = invert
end

function SuperModelView:IsInvertMouseY()
    return self.invertMouseY
end

function SuperModelView:SetInvertMouseY(invert)
    self.invertMouseY = invert
end

function SuperModelView:GetMouseXSensitivity()
    return self.mouseXSensitivity
end

function SuperModelView:SetMouseXSensitivity(sensitivity)
    self.mouseXSensitivity = sensitivity
end

function SuperModelView:GetMouseYSensitivity()
    return self.mouseYSensitivity
end

function SuperModelView:SetMouseYSensitivity(sensitivity)
    self.mouseYSensitivity = sensitivity
end

function SuperModelView:GetWheelSensitivity()
    return self.wheelSensitivity
end

function SuperModelView:SetWheelSensitivity(sensitivity)
    self.wheelSensitivity = sensitivity
end

function SuperModelView:GetMouseXMin()
    return self.mouseXMin
end

function SuperModelView:SetMouseXMin(min)
    self.mouseXMin = min
end

function SuperModelView:GetMouseXMax()
    return self.mouseXMax
end

function SuperModelView:SetMouseXMax(max)
    self.mouseXMax = max
end

function SuperModelView:GetMouseYMin()
    return self.mouseYMin
end

function SuperModelView:SetMouseYMin(min)
    self.mouseYMin = min
end

function SuperModelView:GetMouseYMax()
    return self.mouseYMax
end

function SuperModelView:SetMouseYMax(max)
    self.mouseYMax = max
end

function SuperModelView:GetMouseSmoothTime()
    return self.mouseSmoothTime
end

function SuperModelView:SetMouseSmoothTime(time)
    self.mouseSmoothTime = time
end

function SuperModelView:GetMinDistance()
    return self.minDistance
end

function SuperModelView:SetMinDistance(distance)
    self.minDistance = distance
end

function SuperModelView:GetMaxDistance()
    return self.maxDistance
end

function SuperModelView:SetMaxDistance(distance)
    self.maxDistance = distance
end

function SuperModelView:GetDistanceSmoothTime()
    return self.distanceSmoothTime
end

function SuperModelView:SetDistanceSmoothTime(time)
    self.distanceSmoothTime = time
end

function SuperModelView:IsInputEnabled()
    return self.inputEnabled
end

function SuperModelView:SetInputEnabled(enabled)
    self.inputEnabled = enabled
end

--第三人称摄像机更新
function SuperModelView:Update(dt)
    -- 添加 dt 的限制，防止卡顿时出现过大的值
    dt = math.min(dt, 0.1)
    
    self:SetMouseSmoothTime(self.mouseSmoothTime)


    self._mouseXSmooth, self._mouseXCurrentVelocity = UIMath:SmoothDamp(self._mouseXSmooth, self._mouseX, self._mouseXCurrentVelocity, self._mouseSmoothTime, 0, dt)
    self._mouseYSmooth, self._mouseYCurrentVelocity = UIMath:SmoothDamp(self._mouseYSmooth, self._mouseY, self._mouseYCurrentVelocity, self._mouseSmoothTime, 0, dt)
    self.currentCameraRot = self:CalcCameraRotation(self._mouseXSmooth,self._mouseYSmooth)

    local pivotPosition = self:CalcPivotPosition(self._mouseYSmooth)
    self._pivotPositionSmooth = self._pivotPositionSmooth:Lerp(pivotPosition, self.pivotPositionSmoothSpeed * dt)
    --计算碰撞到障碍物的距离
    local isHit, closestDistance = self:GetClosestDistance(self._pivotPositionSmooth, self.currentCameraRot)
    if not isHit then
        self._distanceSmooth, self._distanceCurrentVelocity = UIMath:SmoothDamp(
            self._distanceSmooth, 
            closestDistance, 
            self._distanceCurrentVelocity, 
            self.distanceSmoothTime,
            math.huge,
            dt
        )
    else
        self._distanceSmooth = closestDistance
        self._distanceCurrentVelocity = 0
    end
    self.currentCameraPos = self:CalcCameraPosition(self._pivotPositionSmooth, self._mouseXSmooth,self._mouseYSmooth,self._distanceSmooth, dt)

    self:SetCameraPos(self.currentCameraPos)
    self:SetCameraRotation(self.currentCameraRot)

    self._rotation = orient
end

--设置摄像机位置
function SuperModelView:SetCameraPos(pos)
    self.bindObj.LookAtPosition = Vector3.New(self._pivotPositionSmooth.x,self._pivotPositionSmooth.y,self._pivotPositionSmooth.z)
    self.bindObj.CameraDist = self._distanceSmooth
end

--设置摄像机旋转
function SuperModelView:SetCameraRotation(rotation)
    local euler = rotation:ToEuler()
    self.bindObj.CameraYaw = euler.y    -- Yaw around Y
    self.bindObj.CameraPitch = euler.x  -- Pitch around X
end

--获取摄像机观察点位置
function SuperModelView:CalcPivotPosition(axisDegrees)
    local orient = Quat.New()
    orient:FromEuler(Vec3.New(0, axisDegrees, 0))
    local centerPos = Vec3.New(0,0,0)
    local pivotPosition = centerPos + orient * (self.offset * self._pivotScale)
    return pivotPosition
end

--获取摄像机位置
function SuperModelView:CalcCameraPosition(pivotPosition, xAxisDegrees, yAxisDegrees, distance, dt) 
    local orient = self:CalcCameraRotation(xAxisDegrees, yAxisDegrees)
    local cameraPos = pivotPosition + orient:GetBackward() * distance
    return cameraPos
end

--获取摄像机旋转
function SuperModelView:CalcCameraRotation(xAxisDegrees, yAxisDegrees) 
    local orient = Quat.New()
    orient:FromEuler(Vec3.New(xAxisDegrees, yAxisDegrees, 0))
    return orient
end

--获取摄像机距离
function SuperModelView:GetClosestDistance(pos, orient)
    local distance = self._distance
    return false, distance
end

--鼠标移动
function SuperModelView:InputMove(deltaX, deltaY)
    local mouseXinput = deltaY
    local mouseYinput = deltaX
    if self.invertMouseX then
        mouseXinput = -mouseXinput
    end
    if self.invertMouseY then
        mouseYinput = -mouseYinput
    end

    if self.lockMouseX then
        mouseXinput = 0
    end
    if self.lockMouseY then
        mouseYinput = 0
    end

    self._mouseX = self._mouseX + mouseXinput * self.mouseXSensitivity
    self._mouseY = self._mouseY + mouseYinput * self.mouseYSensitivity
    --限制角度
    self._mouseX = math.clamp(self._mouseX, self.mouseXMin, self.mouseXMax)
    -- self._mouseY = math.clamp(self._mouseY, self.mouseYMin, self.mouseYMax)

end

--鼠标滚轮
function SuperModelView:InputWheel(delta)
    self._distance = math.clamp(self._distance + delta * self.wheelSensitivity, self.minDistance, self.maxDistance)
end

function SuperModelView:OnTouchBegin(touchPos, touchId)
    SuperModelView.super.OnTouchBegin(self, touchPos, touchId)
    
    if self.touchId and self.touchId ~= touchId then
        return
    end
    local x = touchPos.x
    local y = touchPos.y
    
    self.touchId = touchId
    self.touchBeginPos.x = x
    self.touchBeginPos.y = y
    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
end

function SuperModelView:OnTouchMove(touchPos, touchId)
    SuperModelView.super.OnTouchMove(self, touchPos, touchId)
    if self.touchId ~= touchId then
        return
    end
    
    -- 第一次移动时锁定touchId
    if not self.touchMoveId then
        self.touchMoveId = touchId
    end
    local x = touchPos.x
    local y = touchPos.y

    self.touchMoving = true
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
    
    local delta = self.currentTouchPos - self.lastTouchPos

    if self.inputEnabled then
        self:InputMove(delta.x,delta.y)
    end

    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
end

function SuperModelView:OnTouchEnd(touchPos, touchId)
    SuperModelView.super.OnTouchEnd(self, touchPos, touchId)
    if self.touchId ~= touchId then
        return
    end
    
    self.touchMoving = false
    self.touchMoveId = nil
    self.touchId = nil
end

return SuperModelView
