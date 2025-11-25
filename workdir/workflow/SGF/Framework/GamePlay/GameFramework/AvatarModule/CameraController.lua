local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec2 = GFScript("CoreModule.Math.Vec2")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Vec4 = GFScript("CoreModule.Math.Vec4")
local Quat = GFScript("CoreModule.Math.Quat")
local Mat4 = GFScript("CoreModule.Math.Mat4")
local Mat3x4 = GFScript("CoreModule.Math.Mat3x4")
local Math = GFScript("CoreModule.Math")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local Tween = GFScript("CoreModule.Tween")
local Perlin = GFScript("CoreModule.Math.Perlin")
local ShakeController = GFScript("AvatarModule.ShakeController")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local MathDefines = GFScript("CoreModule.Math.MathDefines")
local WorldService = game:GetService("WorldService")
local UserInputService = game:GetService("UserInputService")
local MouseService = game:GetService("MouseService")
local TimerManager = GFScript("CoreModule.TimerManager")
local Debugger = GFScript("CoreModule.Debugger")
local Color = GFScript("CoreModule.Math.Color")
local TargetUtils = GFScript("CombatModule.TargetUtils")
local CameraController = Class.New("CameraController",ActorComponent)


--摄像机模式
CameraController.CameraMode = {
    --自由模式
    Free,
    --第一人称摄像机
    FirstPerson = 0,
    --第三人称摄像机
    ThirdPerson = 1,
}

--初始化
function CameraController:Constructor()
    self.updateEnabled = true
    self.laterUpdateEnabled = true
    self.inputEnabled = true
    self.shakeCtrl = ShakeController.New()

    self.fixedUpdateInterval = 1.0 / 30.0

    GameFramework:RegisterLaterUpdate(self)
end

function CameraController:Destructor()
    self.target = nil
    GameFramework:UnRegisterLaterUpdate(self)
    if self.TouchStartedEvent then
        self.TouchStartedEvent:Disconnect()
        self.TouchStartedEvent = nil
    end
    if self.TouchEndedEvent then
        self.TouchEndedEvent:Disconnect()
        self.TouchEndedEvent = nil
    end
    if self.TouchMovedEvent then
        self.TouchMovedEvent:Disconnect()
        self.TouchMovedEvent = nil
    end
    
    if self.InputBeganEvent then
        self.InputBeganEvent:Disconnect()
        self.InputBeganEvent = nil
    end
    if self.InputEndedEvent then
        self.InputEndedEvent:Disconnect()
        self.InputEndedEvent = nil
    end

    if self.InputChangedEvent then
        self.InputChangedEvent:Disconnect()
        self.InputChangedEvent = nil
    end
end

--震动屏幕
function CameraController:StartShake(name, spaceData)
    self.shakeCtrl:Start(name, spaceData)
end
--开始持续震动
function CameraController:StartShakeLoop(name, spaceData)
    self.shakeCtrl:StartLoop(name, spaceData)
end
--停止持续震动
function CameraController:StopShakeLoop(name)
    self.shakeCtrl:StopLoop(name)
end
--淡出震动
function CameraController:StopShakeFade(name)
    self.shakeCtrl:StopFade(name)
end

--停止震动
function CameraController:StopShake(name)
    self.shakeCtrl:Stop(name)
end

--停止全部
function CameraController:StopAllShake()
    self.shakeCtrl:StopAll()
end

function CameraController:ShakeUpdate(dt)
    if not self.shakeCtrl:HasAnyShake() then
        return
    end
    local shakeRotData = self.shakeCtrl:GetRotDelta()
    self._mouseX = self._mouseX - shakeRotData.x
    self._mouseY = self._mouseY - shakeRotData.y

    self.shakeCtrl:Update(dt, self.actor:GetPosition())

    if self.shakeCtrl:IsShaking() then
        shakeRotData = self.shakeCtrl:GetRotDelta()
        self._mouseX = self._mouseX + shakeRotData.x
        self._mouseY = self._mouseY + shakeRotData.y
    end
end
--是否正在震动
function CameraController:IsShaking()
    return self.shakeCtrl:IsShaking()
end
--初始化
function CameraController:Init()
    --摄像机模式
    self.cameraMode = self.CameraMode.ThirdPerson
    --摄像机跟随的目标偏移
    self.offset = Vec3.New(60, 160, 0)
    self.pivotPositionSmoothSpeed = 4
    self.pivotPositionSmoothTime = 0.01

    --锁定
    self.lockMouseX = false
    self.lockMouseY = false
    --反向
    self.invertMouseX = false
    self.invertMouseY = false
    --灵敏度
    self.mouseXSensitivity = 0.2
    self.mouseYSensitivity = 0.2
    self.wheelSensitivity = 50
    --范围限制
    self.mouseXMin = -90.0
    self.mouseXMax = 90.0
    self.mouseYMin = -89.9
    self.mouseYMax = 89.9
    --平滑时间
    self.mouseSmoothTime = 0.01
    --距离限制
    self.minDistance = 50
    self.maxDistance = 2000
    --距离平滑时间
    self.distanceSmoothTime = 0.2
    --移动对齐
    self.alignWhenMoving = false
    --对齐平滑时间
    self.alignmentSmoothTime = 0.05
    --最小对齐距离
    self.minAlignDistance = 300
    --最小对齐高度
    self.minAlignAltitude = 100
    --是否使用摄像机方向进行瞄准（解决TPS偏移问题）
    self.useCameraAimDirection = true
    --是否使用屏幕中央射线检测进行瞄准（更精确的瞄准）
    self.useScreenCenterRaycast = true

    self._mouseX = 45
    self._mouseY = 0
    self._distance = 500

    self._mouseXSmooth = self._mouseX
    self._mouseYSmooth = self._mouseY
    self._mouseSmoothTime = 0.01
    self._distanceSmooth = self._distance
    self._pivotPositionCurrentVelocity = Vec3.New(0,0,0)
    self._pivotPositionSmooth =  Vec3.New(0,0,0)
    self._pivotPositionSmoothTime = 0.0
    self._pivotScale = Vec3.New(1,1,1)
    --速率记录
    self._mouseXCurrentVelocity = 0
    self._mouseYCurrentVelocity = 0
    self._distanceCurrentVelocity = 0
    --开启锁定目标模式
    self.lockedOnTarget = true

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

    --是否使用后坐力
    self.useRecoil = true
    --当前后坐力
    self.currentRecoil = Vec3.New(0,0,0)
    --后坐力结果
    self.resultRecoilRotation = Vec3.New(0,0,0)
    --后坐力平滑时间
    self.recoilDampTime = 10.0
    --后坐力强度
    self.recoilAmount = Vec3.New(-3, 4, 4)

    self.addLookValue = Vec2.New(0,0)

    self.aimStartPos = nil

    -- TimerManager:AddTimer(function()
    --     if not self:IsServer() then
    --         if not self.actor:IsLocalPlayer() then
    --             return
    --         end
    --         if not self.camera then
    --             CTipsUI:ShowTxtTips("CameraController: Camera is nil")
    --             return
    --         end
    --         if self.actor:IsShadow() then
    --             CTipsUI:ShowTxtTips("CameraController: actor is shadow")
    --             return
    --         end
    --         local playerPos = game:GetService("Players").LocalPlayer.Character.Position
    --         local avatarPos = self.actor.AvatarComponent:GetPosition()
    --         local ActorManager = GFScript("ActorModule.ActorManager")
    --         local oo = ActorManager.clientActors[self.actor.actorId]
            
    --         CTipsUI:ShowTxtTips(tostring(self.cameraMode).." "..tostring(GameFramework.updateCount).." "..tostring(GameFramework.laterUpdateCount).." "..tostring(ActorManager.stepCount).." "..tostring(ActorManager.stepCount2))
            
    --         -- local radius = 100
    --         -- local offset = Vec3.New(0,0,0)
    --         -- local hitPos = self.actor.AvatarComponent:GetOffsetPosition(offset)
    --         -- local height = 200
    --         -- local distance = 200
    --         -- -- Debugger:DrawCylinder(hitPos,
    --         -- --     Vec3.New(radius,height,radius),
    --         -- --     Color.New(1, 0, 0, 1),1)
    --         -- local boxOffset = Vec3.New(0,height / 2,distance / 2)
    --         -- Debugger:DrawBox(self.actor.AvatarComponent:GetOffsetPosition(offset + boxOffset),
    --         -- self.actor.AvatarComponent:GetRotation(),
    --         --     Vec3.New(radius,height / 2,distance / 2),
    --         --     Color.New(1, 0, 0, 1),1)
    --         -- -- local hitTargets = TargetUtils:SelectCylinderTargets(hitPos,
    --         -- -- radius,height,targetFilter)
    --         -- local hitTargets = TargetUtils:SelectLineTargets(hitPos,self.actor.AvatarComponent:GetForward(),distance,radius,height)
    --         -- local str = ""
    --         -- for i,v in ipairs(hitTargets) do
    --         --     str = str..v:GetNickName().." "
    --         -- end
    --         -- CTipsUI:ShowTxtTips(str)
    --     end
    -- end,1)
end
--拷贝
function CameraController:CopyFrom(other)
    self._mouseX = other._mouseX
    self._mouseY = other._mouseY
    self._distance = other._distance
    self._pivotPositionSmooth = other._pivotPositionSmooth
    self._mouseXSmooth = other._mouseXSmooth
    self._mouseXCurrentVelocity = other._mouseXCurrentVelocity
    self._mouseYSmooth = other._mouseYSmooth
    self._mouseYCurrentVelocity = other._mouseYCurrentVelocity
    self._distanceSmooth = other._distanceSmooth
    self._distanceCurrentVelocity = other._distanceCurrentVelocity
end
--启动客户端
function CameraController:OnStartClient()
    if not self.actor:IsLocalPlayer() then
        return
    end
    self:SetCamera(self.actor:GetScene():GetCamera())
    self._pivotPositionSmooth = self:CalcPivotPosition(self._mouseY)
    
    self:EnableSightTouch()


    if UserInputService.TouchEnabled then -- 触摸
        self.TouchStartedEvent = UserInputService.TouchStarted:Connect(function(inputObj, gameprocessed)
            self.isTouching = true
            self:OnTouchStarted(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
        end)

        self.TouchMovedEvent = UserInputService.TouchMoved:Connect(function(inputObj, gameprocessed)
            if self.isTouching then
                self:OnTouchMoved(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)

        self.TouchEndedEvent = UserInputService.TouchEnded:Connect(function(inputObj, gameprocessed)
            self.isTouching = false
            self:OnTouchEnded(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
        end)
    elseif UserInputService.MouseEnabled then -- 鼠标
        self.InputBeganEvent = UserInputService.InputBegan:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton3.Value
            then
                self.isTouching = true
                self:OnTouchStarted(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
        self.InputChangedEvent = UserInputService.InputChanged:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseWheel.Value then
                self:OnWheel(inputObj.Delta.y)
            end
            local IsSight = MouseService:IsSight()
            if IsSight then
                if self.canSightTouch and (self.touchId == nil) then
                    --self.touchId = inputObj.TouchId
                    self.canSightTouch = false
                end
                local dx = 0
                local dy = 0
                if self.camera then
                    local winSize = self.camera.WindowSize
                    local centerPos = { x = winSize.x/2 , y = winSize.y/2}
                    dx = inputObj.Position.x - math.floor(centerPos.x)
                    dy = inputObj.Position.y - math.floor(centerPos.y)
                end

                self.canSightTouch = false
                self:OnTouchMoved(self.currentTouchPos.x + dx, self.currentTouchPos.y + dy,self.touchId)
            elseif self.isTouching then
                self:OnTouchMoved(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
        self.InputEndedEvent = UserInputService.InputEnded:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton3.Value
            then
                self.isTouching = false
                self:OnTouchEnded(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
    end
end
--应用游戏设置
function CameraController:ApplyClientGameSettings(settings)
    local config = settings.CameraController
    self._distance = config.distance
    self.minDistance = config.minDistance
    self.maxDistance = config.maxDistance

    self._distance = math.clamp(self._distance, self.minDistance, self.maxDistance)

    self.pivotPositionSmoothSpeed = config.positionSmoothSpeed
    self.mouseSmoothTime = config.rotateSmoothTime
end

--设置摄像机
function CameraController:SetCamera(camera)
    self.camera = camera
    -- self.camera.CameraType = Enum.CameraType.Scriptable
end
--获取摄像机
function CameraController:GetCamera()
    return self.camera
end
--当场景设置的时候
function CameraController:OnSceneSet(scene)
    if not self.actor:IsServer() and scene ~= nil and self.actor:IsLocalPlayer() then
        self:SetCamera(scene:GetCamera())
    end
end

function CameraController:Client(dt)
    if not self.actor:IsLocalPlayer() then
        return
    end
    
    self.deltaTime = dt
end

--更新客户端
function CameraController:OnLaterUpdate(dt)
    if not self.actor:IsLocalPlayer() then
        return
    end

    if not self.camera then
        Log:Error("CameraController:OnLaterUpdate no camera")
        return
    end
    if self.actor:IsShadow() then
        return
    end
    --判断超时
    local IsSight = MouseService:IsSight()
    if IsSight then
        -- if self.lastTouchTimeEnd < Utils:GetServerTime() then
        --     self.touchMoving = false
        -- end
    end

    self:ShakeUpdate(dt)

    if self.cameraMode == CameraController.CameraMode.ThirdPerson then
        self:ThirdPersonUpdate(dt)
    end
    

    self.viewDirty = true
    self.projectionDirty = true
end

--更新客户端
function CameraController:FixedUpdateClient(dt)
    if self:IsLocalPlayer() then
        if self.useRecoil and self.deltaTime then
            self.currentRecoil = self.currentRecoil:Lerp(Vec3.zero(), 35 * self.deltaTime)
            self.resultRecoilRotation = self.resultRecoilRotation:Slerp(self.currentRecoil, self.recoilDampTime * dt)
        end
    end
end
--设置摄像机模式
function CameraController:SetCameraMode(mode)
    self.cameraMode = mode
end

--设置摄像机跟随的目标偏移
function CameraController:SetOffset(offset)
    self.offset = offset
end

--获取当前Yaw
function CameraController:GetYaw()
    local orient = self:GetRotation()
    return orient:ToEuler().y
end

--获取当前Pitch
function CameraController:GetPitch()
    local orient = self:GetRotation()
    return orient:ToEuler().x
end

function CameraController:GetForward()
    local orient = self:GetRotation()
    return orient:GetForward()
end

function CameraController:GetBackward()
    local orient = self:GetRotation()
    return orient:GetBackward()
end

function CameraController:SetMouseSmoothTime(smoothTime)
    if not self.shakeCtrl:IsShaking() then
        self._mouseSmoothTime = smoothTime
    end
end

--设置锁定目标
function CameraController:SetLockedOnTarget(locked)
    self.lockedOnTarget = locked
end
--设置移动时对齐摄像机
function CameraController:SetAlignWhenMoving(aligh)
    self.alignWhenMoving = aligh
end
--获取缩放系数
function CameraController:GetScaleFactor()
    return self.actor:GetEffectiveScale().x
end

function CameraController:GetZoomFactor()
    return self._zoomFactor
end

function CameraController:SetZoomFactor(zoomFactor)
    self._zoomFactor = zoomFactor
end
--获取缩放系数
function CameraController:GetPivotScale()
    return self._pivotScale
end
--设置缩放系数
function CameraController:SetPivotScale(pivotScale)
    self._pivotScale = pivotScale
end

--设置是否使用摄像机瞄准方向
function CameraController:SetUseCameraAimDirection(useCameraAimDirection)
    self.useCameraAimDirection = useCameraAimDirection
end

--获取是否使用摄像机瞄准方向
function CameraController:GetUseCameraAimDirection()
    return self.useCameraAimDirection
end

--设置是否使用屏幕中央射线检测
function CameraController:SetUseScreenCenterRaycast(useScreenCenterRaycast)
    self.useScreenCenterRaycast = useScreenCenterRaycast
end

--获取是否使用屏幕中央射线检测
function CameraController:GetUseScreenCenterRaycast()
    return self.useScreenCenterRaycast
end

--设置瞄准起点位置
function CameraController:SetAimStartPos(aimStartPos)
    self.aimStartPos = aimStartPos
end

--获取瞄准起点位置
function CameraController:GetAimStartPos()
    return self.aimStartPos
end

--第三人称摄像机更新
function CameraController:ThirdPersonUpdate(dt)
    -- 添加 dt 的限制，防止卡顿时出现过大的值
    dt = math.min(dt, 0.1)
    
    self:SetMouseSmoothTime(self.mouseSmoothTime)

    if self.alignWhenMoving and (not self.touchMoving or self.alignWhenMoving and self.lockedOnTarget) then -- 索敌状态对齐
        local invertAlignment = true
        local target = self.actor:GetTarget()
        if self.lockedOnTarget and target then
            local selfPos = self.actor.AvatarComponent:GetPosition()
            local targetPos = target.AvatarComponent:GetPosition()
            --因为-1是正向，所以取反方向
            local dir = selfPos - targetPos
            if math.abs(dir.y) < self.minAlignAltitude or dir:Magnitude() > self.minAlignDistance then
                dir:Normalize()
                local lookRotation = Quat.New()
                lookRotation:FromLookRotation(dir, Vec3.New(0,1,0))
                self:AlignWithAngle(lookRotation:ToEuler().y, invertAlignment)
            end
        else
            local eulerAngleY = self.actor.AvatarComponent:GetRotation():ToEuler().y
            self:AlignWithAngle(eulerAngleY, invertAlignment)
        end

        self:SetMouseSmoothTime(self.alignmentSmoothTime)
    end

    -- -- 平滑处理 X 轴旋转
    -- local deltaX = self._mouseX - self._mouseXSmooth
    -- if deltaX > 180 then
    --     deltaX = deltaX - 360
    -- elseif deltaX < -180 then
    --     deltaX = deltaX + 360
    -- end
    
    -- local targetX = self._mouseXSmooth + deltaX
    -- self._mouseXSmooth, self._mouseXCurrentVelocity = Math:SmoothDamp(
    --     self._mouseXSmooth, 
    --     targetX, 
    --     self._mouseXCurrentVelocity, 
    --     self._mouseSmoothTime,
    --     math.huge,
    --     dt
    -- )
    
    -- if self._mouseXSmooth >= 360 then
    --     self._mouseXSmooth = self._mouseXSmooth - 360
    -- elseif self._mouseXSmooth < 0 then
    --     self._mouseXSmooth = self._mouseXSmooth + 360
    -- end

    -- -- Y 轴平滑处理
    -- self._mouseYSmooth, self._mouseYCurrentVelocity = Math:SmoothDamp(
    --     self._mouseYSmooth, 
    --     self._mouseY, 
    --     self._mouseYCurrentVelocity, 
    --     self._mouseSmoothTime,
    --     math.huge,
    --     dt
    -- )


    self._mouseXSmooth, self._mouseXCurrentVelocity = Math:SmoothDamp(self._mouseXSmooth, self._mouseX, self._mouseXCurrentVelocity, self._mouseSmoothTime, 0, dt)
    self._mouseYSmooth, self._mouseYCurrentVelocity = Math:SmoothDamp(self._mouseYSmooth, self._mouseY, self._mouseYCurrentVelocity, self._mouseSmoothTime, 0, dt)
    self.currentCameraRot = self:CalcCameraRotation(self._mouseXSmooth - self.addLookValue.y,self._mouseYSmooth + self.addLookValue.x)

    local pivotPosition = self:CalcPivotPosition(self._mouseYSmooth)
    self._pivotPositionSmooth, self._pivotPositionCurrentVelocity = Math:SmoothDampVector(self._pivotPositionSmooth, pivotPosition, self._pivotPositionCurrentVelocity, self._pivotPositionSmoothTime, nil, dt)
    -- if self.pivotPositionSmoothSpeed > 0 then
    --     self._pivotPositionSmooth = self._pivotPositionSmooth:Lerp(pivotPosition, self.pivotPositionSmoothSpeed * dt)
    -- else
    --     self._pivotPositionSmooth = pivotPosition
    -- end
    --计算碰撞到障碍物的距离
    local isHit, closestDistance = self:GetClosestDistance(self._pivotPositionSmooth, self.currentCameraRot)
    if not isHit then
        self._distanceSmooth, self._distanceCurrentVelocity = Math:SmoothDamp(
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

    local finalCameraRot = self.currentCameraRot * Quat.euler(self.resultRecoilRotation.x, self.resultRecoilRotation.y, self.resultRecoilRotation.z)
    
    -- self.camera.Position = Vector3.New(self.currentCameraPos.x,self.currentCameraPos.y,self.currentCameraPos.z)
    -- self.camera.Rotation = Quaternion.New(finalCameraRot.x,finalCameraRot.y,finalCameraRot.z,finalCameraRot.w)
    

    -- local pos = self.actor.AvatarComponent:GetPosition()
    -- local orient = Quat.New()
    -- orient:FromEuler(Vec3.New(self._mouseX,self._mouseY,0))
    -- local cameraPos = pos + orient:GetBackward() * self._distance
    
    -- self.camera.Position = Vector3.New(cameraPos.x,cameraPos.y,cameraPos.z)
    -- self.camera.Rotation = Quaternion.New(orient.x,orient.y,orient.z,orient.w)

    
    self.addLookValue.x = 0
    self.addLookValue.y = 0

    self._rotation = orient

    self.actor:FireClient("CameraUpdated", self)
end

--获取摄像机观察点位置
function CameraController:CalcPivotPosition(axisDegrees)
    local orient = Quat.New()
    orient:FromEuler(Vec3.New(0,axisDegrees,0))
    local pivotPosition = self.actor.AvatarComponent:GetPosition() + orient * (self.offset * self:GetScaleFactor() * self._pivotScale)
    return pivotPosition
end
--获取摄像机位置
function CameraController:CalcCameraPosition(pivotPosition, xAxisDegrees, yAxisDegrees, distance, dt) 
    local shakePosDelta = self.shakeCtrl:GetPosDelta()
    local orient = self:CalcCameraRotation(xAxisDegrees, yAxisDegrees)
    local cameraPos = pivotPosition + orient:GetBackward() * distance + orient * shakePosDelta
    return cameraPos
end

--获取摄像机旋转
function CameraController:CalcCameraRotation(xAxisDegrees, yAxisDegrees) 
    local orient = Quat.New()
    orient:FromEuler(Vec3.New(xAxisDegrees,yAxisDegrees,0))
    return orient
end
--获取摄像机距离
function CameraController:GetClosestDistance(pos, orient)
    local distance = self._distance * self:GetScaleFactor() * self:GetZoomFactor()
    self.actor:EnableOverlap(true)
    local dir = orient:GetBackward()
    local result = WorldService:SweepSphere(50, Vector3.New(pos.x,pos.y,pos.z), 
                                                Vector3.New(dir.x,dir.y,dir.z),distance,true,ActorDefines.ObstacleCollisionGroup)
    self.actor:EnableOverlap(false)
    if result.isHit then
        return true, result.distance
    end
    return false, distance
end

--水平对齐
function CameraController:AlignWithAngle(yAngle,inverted)
    local shakeRotDelta = self.shakeCtrl:GetRotDelta()
    local targetRotation = Quat.New()
    targetRotation:FromEuler(Vec3.New(0, (inverted and (yAngle - 180.0) or yAngle), 0))
    local inverseRotation = Quat.New() 
    inverseRotation:FromEuler(Vec3.New(0, self._mouseY - shakeRotDelta.y, 0))
    inverseRotation:Inverse()
    local delta = targetRotation * inverseRotation
    local deltaEuler = delta:ToEuler().y
    local deltaEuler = delta:ToEuler().y
    if Math:IsAlmostEqual(deltaEuler, 0, 0.5) then
        return
    end
    if deltaEuler > 180 then
        deltaEuler = deltaEuler - 360
    end
    self._mouseY = self._mouseY + deltaEuler
end
--获取位置
function CameraController:GetPosition()
    local pos = self.camera.Position
    return Vec3.New(pos.x,pos.y,pos.z)
end
--获取旋转
function CameraController:GetRotation()
    if self.camera then
        local rot = self.camera.Rotation
        return Quat.New(rot.w, rot.x,rot.y,rot.z)
    end
    return Quat.identity()
end
--获取摄像机瞄准方向（考虑偏移）
function CameraController:GetAimDirection()
    if not self.camera then
        return self:GetForward(), Vec3.zero()
    end
    
    return self:GetAimDirectionFromScreenCenter()
    -- -- 优先使用屏幕中央射线检测（最精确）
    -- if self.useScreenCenterRaycast then
    --     return self:GetAimDirectionFromScreenCenter()
    -- end
    
    -- -- 如果不使用摄像机瞄准方向，直接返回摄像机前方
    -- if not self.useCameraAimDirection then
    --     return self:GetForward()
    -- end
    
    -- -- 获取摄像机位置和角色位置
    -- local cameraPos = self:GetPosition()
    -- local characterPos = self.actor.AvatarComponent:GetPosition()
    
    -- -- 计算摄像机到角色的方向
    -- local cameraToChar = characterPos - cameraPos
    -- cameraToChar.y = 0 -- 忽略高度差
    -- cameraToChar:Normalize()
    
    -- -- 获取摄像机前方方向
    -- local cameraForward = self:GetForward()
    -- cameraForward.y = 0 -- 忽略高度差
    -- cameraForward:Normalize()
    
    -- -- 计算瞄准方向
    -- local aimDirection = cameraForward
    
    -- -- 如果摄像机在侧面，调整瞄准方向
    -- local dot = cameraToChar:Dot(cameraForward)
    -- if dot < 0.7 then -- 当摄像机在侧面时（夹角大于45度）
    --     -- 根据摄像机位置调整瞄准方向
    --     local right = cameraToChar:Cross(Vec3.New(0, 1, 0))
    --     if right:Dot(cameraForward) > 0 then
    --         aimDirection = right
    --     else
    --         aimDirection = -right
    --     end
    -- end
    
    -- return aimDirection
end
--获取屏幕中央射线检测的世界坐标点
function CameraController:GetScreenCenterWorldPoint(maxDistance)
    if not self.camera then
        return nil
    end
    
    maxDistance = maxDistance or 10000 -- 默认最大距离
    
    -- 获取屏幕尺寸
    local viewportSize = self:GetViewportSize()
    local screenCenterX = viewportSize.x / 2
    local screenCenterY = viewportSize.y / 2
    
    -- 从屏幕中央发射射线
    local ray = self.camera:ViewportPointToRay(screenCenterX, screenCenterY, 0)
    
    self.actor:EnableOverlap(true)
    -- 进行射线检测
    local result = WorldService:RaycastClosest(
        ray.Origin, 
        ray.Direction, 
        maxDistance, 
        false, 
        ActorDefines.AllCollideActorAndObstacleGroups
    )
    self.actor:EnableOverlap(false)
    
    if result.isHit then
        return Vec3.New(result.position.x, result.position.y, result.position.z)
    else
        -- 如果没有击中任何物体，返回射线方向上的一个远点
        local farPoint = Vec3.New(ray.Origin.x, ray.Origin.y, ray.Origin.z) + 
                        Vec3.New(ray.Direction.x, ray.Direction.y, ray.Direction.z) * maxDistance
        return farPoint
    end
end

--获取从角色位置到屏幕中央瞄准点的方向
function CameraController:GetAimDirectionFromScreenCenter()
    if not self.camera then
        return self:GetForward()
    end
    
    -- 获取屏幕中央瞄准的世界坐标点
    local aimWorldPoint = self:GetScreenCenterWorldPoint()
    if not aimWorldPoint then
        return self:GetForward()
    end
    
    -- 使用提供的瞄准起点位置，如果没有提供则使用角色位置
    local startPos = self.aimStartPos or self.actor.AvatarComponent:GetPosition()
    
    -- 计算从瞄准起点位置到瞄准点的方向
    local aimDirection = aimWorldPoint - startPos
    aimDirection:Normalize()
    
    return aimDirection, aimWorldPoint
end

--获取朝向旋转
function CameraController:GetFaceCameraRotation(pos,rotation,faceMode,minAnge)
    local cameraPos = self:GetPosition()
    local cameraRot = self:GetRotation()
    if faceMode == 0 then
        return cameraRot
    end
    local lookRotation = Quat.New()
    lookRotation:GetFaceCameraRotation(cameraPos,cameraRot,pos,rotation,faceMode,minAnge)
    return lookRotation
end
--设置衍生位置
function CameraController:SetDerivedPosition(pos)
    if self.cameraMode == CameraController.CameraMode.ThirdPerson then
       local pivotPos = self:CalcPivotPosition(self._mouseY)
       local direction = pivotPos - pos
       
       local newDistance = direction:Magnitude()
       newDistance = math.clamp(newDistance, self.minDistance, self.maxDistance)
       self._distance = newDistance
       self._distanceSmooth = newDistance
       
       local normalizedDir = direction:Normalized()

       local lookRotation = Quat.lookAt(normalizedDir)
       local euler = lookRotation:ToEuler()
       
       self._mouseX = euler.x
       self._mouseXSmooth = euler.x
       
       self._mouseY = euler.y
       self._mouseYSmooth = euler.y
       
       self._mouseXCurrentVelocity = 0
       self._mouseYCurrentVelocity = 0
       self._distanceCurrentVelocity = 0
    end
end

function CameraController:SetOrginPosition(pos)
    if self.cameraMode == CameraController.CameraMode.ThirdPerson then
        local pivotPos = self:CalcPivotPosition(self._mouseY)
        local direction = pivotPos - pos
        
        local newDistance = direction:Magnitude()
        self._distanceSmooth = newDistance
        
        local normalizedDir = direction:Normalized()
 
        local lookRotation = Quat.lookAt(normalizedDir)
        local euler = lookRotation:ToEuler()
        
        self._mouseXSmooth = euler.x
        
        self._mouseYSmooth = euler.y
        
        self._mouseXCurrentVelocity = 0
        self._mouseYCurrentVelocity = 0
        self._distanceCurrentVelocity = 0
     end
end

--世界坐标映射到屏幕坐标
function CameraController:WorldToScreen(worldPos)
    if self.camera then
        local screenPos = self.camera:WorldToUIPoint(Vector3.New(worldPos.x,worldPos.y,worldPos.z))
        return Vec2.New(screenPos.x, screenPos.y)
    end
    return Vec2.zero()
    -- if not self.camera then
    --     return Vec2.zero()
    -- end
    -- local view = self:GetView()
    -- local projection = self:GetProjection()
    -- local viewportSize = self:GetViewportSize()
    
    
    -- local eyeSpacePos = view * worldPos
    -- local ret = Vec2.New()

    -- if eyeSpacePos.z > 0.0 then
    --     local screenSpacePos = projection * eyeSpacePos
    --     ret.x = screenSpacePos.x
    --     ret.y = screenSpacePos.y
    -- else
    --     ret.x = (-eyeSpacePos.x > 0.0) and -1.0 or 1.0
    --     ret.y = (-eyeSpacePos.y > 0.0) and -1.0 or 1.0
    -- end

    -- ret.x = (ret.x / 2.0) + 0.5
    -- ret.y = 1.0 - ((ret.y / 2.0) + 0.5)


    -- ret.x = ret.x * viewportSize.x
    -- ret.y = ret.y * viewportSize.y
    
    -- return ret
end
--获取视口高度一半
function CameraController:GetHalfViewSize()
    if self.camera then
        local fov = self:GetFov()
        local viewportSize = self:GetViewportSize()
        return math.tan(fov * MathDefines.M_DEGTORAD * 0.5)
    end
    return 0
end
--计算固定屏幕缩放系数
function CameraController:CalculateFixedScaleFactor(pos)
    if self.camera then
        local viewportSize = self:GetViewportSize()
        local invViewHeight = 1.0 / viewportSize.y
        local halfViewSize = self:GetHalfViewSize()

        local view = self:GetView()
        local projection = self:GetProjection()
        
        local viewProj = projection * view
        local projPos = viewProj * Vec4.New(pos.x,pos.y,pos.z, 1.0)
        local newScaleFactor = invViewHeight * halfViewSize * projPos.w
        return newScaleFactor
    end
    return 1
end
--获取世界矩阵
function CameraController:GetEffectiveWorldTransform()
    local position = self:GetPosition()
    local rotation = self:GetRotation()
    local mat3x4 = Mat3x4.New()
    mat3x4:FromTransforms(position,rotation,1.0)
    return mat3x4
end
--获取视图矩阵
function CameraController:GetView()
    if self.viewDirty then
        self.view = self:GetEffectiveWorldTransform():Inverse()
        self.viewDirty = false
    end
    return self.view
end
--获取投影矩阵
function CameraController:GetProjection()
    if self.projectionDirty then
        if self.projection == nil then
            self.projection = Mat4.New()
        end
        self.projection:SetData(
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0
        )
        local fov = self:GetFov()
        local far = self:GetFar()
        local near = self:GetNear()
        local viewportSize = self:GetViewportSize()
        local aspectRatio = viewportSize.x / viewportSize.y

        local h = (1.0 / math.tan(fov * MathDefines.M_DEGTORAD * 0.5))
        local w = h / aspectRatio
        local q = far / (far - near)
        local r = -q * near

        self.projection.m00 = w
        self.projection.m02 = 2.0
        self.projection.m11 = h
        self.projection.m12 = 2.0
        self.projection.m22 = q
        self.projection.m23 = r
        self.projection.m32 = 1.0
        self.projectionDirty = false
    end
    return self.projection
end
--获取广角
function CameraController:GetFov()
    if not self.fov then
        self.fov = self.camera.FieldOfView
    end
    return self.fov
end
--设置广角
function CameraController:SetFov(fov)
    if self.camera then
        self.fov = fov
        self.camera.FieldOfView = fov
    end
end

--获取近截面
function CameraController:GetNear()
    if not self.near then
        self.near = self.camera.ZNear
    end
    return self.near
end

function CameraController:SetNear(near)
    self.near = near
    self.camera.ZNear = near
end
--获取远截面
function CameraController:GetFar()
    if not self.far then
        self.far = self.camera.ZFar
    end
    return self.far
end

function CameraController:SetFar(far)
    self.far = far
    self.camera.ZFar = far
end
--获取视口大小
function CameraController:GetViewportSize()
    local viewportSize = self.camera.WindowSize
    return Vec2.New(viewportSize.x,viewportSize.y)
end

function CameraController:ApplyRecoil(vertical, horizontal, shakeMultipler, isAiming)
    if not self.useRecoil then
        return
    end
    local multipler = isAiming and 1.0 or 0.7

    self.addLookValue = self.addLookValue + Vec2.New(vertical * multipler, horizontal * multipler)

    local recoilX = self.recoilAmount.x
    local recoilY = Math:Random(-self.recoilAmount.y, self.recoilAmount.y)
    local recoilZ = Math:Random(-self.recoilAmount.z, self.recoilAmount.z)
    self.currentRecoil = self.currentRecoil + Vec3.New(recoilX, recoilY, recoilZ) * multipler * shakeMultipler
end

--------------------------------------输入控制-----------------------------------------
--设置输入启用
function CameraController:SetInputEnabled(enabled)
    self.inputEnabled = enabled
end
--鼠标移动
function CameraController:InputMove(deltaX, deltaY)
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
function CameraController:InputWheel(delta)
    self._distance = math.clamp(self._distance + delta * self.wheelSensitivity, self.minDistance, self.maxDistance)
end

function CameraController:EnableSightTouch()
    if MouseService:IsSight() then
        self.canSightTouch = true
    end
end


function CameraController:OnTouchStarted(x,y,touchId)
    
    if self.touchId and self.touchId ~= touchId then
        return
    end
    -- CTipsUI:ShowTxtTips(string.format("input %s touchId %s touchMoveId %s", tostring(touchId), tostring(self.touchId), tostring(self.touchMoveId)))
    -- 如果已经有锁定的touchMoveId,则忽略其他触摸
    -- if self.touchMoveId and self.touchMoveId ~= touchId then
    --     return
    -- end
    
    self.touchId = touchId
    self.touchBeginPos.x = x
    self.touchBeginPos.y = y
    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
    self.canSightTouch = false
end

function CameraController:OnTouchMoved(x,y,touchId)
    if self.touchId ~= touchId then
        return
    end
    -- -- 如果已经有锁定的touchMoveId,则忽略其他触摸
    -- if self.touchMoveId and self.touchMoveId ~= touchId then
    --     return
    -- end
    -- CTipsUI:ShowTxtTips("CameraController: OnTouchMoved touchMoveId " .. tostring(self.touchMoveId))
    
    -- 第一次移动时锁定touchId
    if not self.touchMoveId then
        self.touchMoveId = touchId
    end

    self.touchMoving = true
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
    
    local delta = self.currentTouchPos - self.lastTouchPos

    if self.inputEnabled then
        if self.alignWhenMoving and self.lockedOnTarget then
            self:InputMove(0,delta.y)
        else
            self:InputMove(delta.x,delta.y)
        end
    end

    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
end

function CameraController:OnTouchEnded(x,y,touchId)
    if self.touchId ~= touchId then
        return
    end
    -- CTipsUI:ShowTxtTips(string.format("input %s touchId %s touchMoveId %s", tostring(touchId), tostring(self.touchId), tostring(self.touchMoveId)))
    -- 只处理锁定的touchId
    -- if self.touchMoveId and self.touchMoveId ~= touchId then
    --     return
    -- end
    
    self.touchMoving = false
    self.touchMoveId = nil
    self.touchId = nil
end
function CameraController:OnWheel(delta)
    if self.inputEnabled then
        self:InputWheel(delta)
    end
end
--------------------------------------效果-----------------------------------------
local ChromaticAberrationBy = GFScript("ActorModule.Action.ChromaticAberrationBy")
local Sequence = GFScript("ActorModule.Action.Sequence")
function CameraController:StartChromaticAberration(duration,intensity,startOffset,iterationStep,iterationSamples)
    intensity = intensity or 1
    startOffset = startOffset or 1
    iterationStep = iterationStep or 4
    iterationSamples = iterationSamples or 4
    
    self.actor.PostProcessing:SetChromaticAberrationStartOffset(startOffset)
    self.actor.PostProcessing:SetChromaticAberrationIterationStep(iterationStep)
    self.actor.PostProcessing:SetChromaticAberrationIterationSamples(iterationSamples)

    self.actor:StopActionByTag("ChromaticAberration")
    local ca1 = ChromaticAberrationBy.New()
    ca1:Init(duration / 2,intensity)
    local ca2 = ChromaticAberrationBy.New()
    ca2:Init(duration / 2,-intensity)
    local seq = Sequence.New()
    seq:Init(ca1, ca2)
    seq:SetTag("ChromaticAberration")
    self.actor:RunAction(seq)
end
return CameraController