-- 说明:超级摇杆
-- 日期:2025年2月19日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIUtils = GFScript("UIModule.UIUtils")
local SuperButtonBase = GFScript("UIModule.UIWidget.SuperButtonBase")
local SuperJoystick = UIClass.New("SuperJoystick", SuperButtonBase)

function SuperJoystick:Constructor()
    self.joystickRadius = 0

    --摇杆外圈，点击这个区域会触发摇杆的点击事件
    self.outer = nil
    --摇杆内圈
    self.inner = nil
    --摇杆瞄准器，摇杆的圆盘背景
    self.aimer = nil
    --摇杆指针，摇杆的圆盘指针
    self.pointer = nil
    --摇杆方向指针，摇杆的圆盘方向指针
    self.directionalPointer = nil

    --摇杆方向未修改
    self.directionUnmodded = Vec2.zero()
    --摇杆方向
    self.direction = Vec2.zero()
    --手指位置
    self.fingerPosition = Vec2.zero()
    --手指是否按下
    self.isFingerDown = false

    self.pointerRadius = 0 --摇杆指针的半径
    self.directionalRadius = 0 --摇杆方向指针的半径
    --摇杆是否固定
    self.fixedJoystick = false
    --超出摇杆半径是否跟随手指移动
    self.followFinger = true

    self.pointerDownCallback = nil
    self.pointerUpCallback = nil
    self.pointerMoveCallback = nil
    self.directionChangedCallback = nil

    self.resetDirectionOnPointerUp = false
end


function SuperJoystick:Destructor()
    self.joystickRadius = 0

    self.outer = nil
    self.inner = nil
    self.aimer = nil
    self.pointer = nil
    self.directionalPointer = nil
end

function SuperJoystick:Init(bindObj)
    if not SuperJoystick.super.Init(self, bindObj) then
        return false
    end
    
    return true
end

--设置外圈
function SuperJoystick:SetOuter(outerName)
    self.outer = self:FindImage(outerName)
    if self.outer then
        self.outer:SetEventFilter(self)
    end
    self:UpdateComponentsVisible()
end

--设置内圈
function SuperJoystick:SetInner(innerName)
    self.inner = self:FindImage(innerName)
    if self.inner then
        self.inner:SetPivot(Vec2.New(0.5, 0.5))
        self.inner:SetEventEnabled(false)
    end
    self:UpdateComponentsVisible()
end

--设置瞄准器
function SuperJoystick:SetAimer(aimerName)
    self.aimer = self:FindImage(aimerName)
    if self.aimer then
        self.aimer:SetPivot(Vec2.New(0.5, 0.5))
        self.aimer:SetEventEnabled(false)
    end
    self:UpdateComponentsVisible()
end

--设置摇杆指针
function SuperJoystick:SetPointer(pointerName)
    self.pointer = self:FindImage(pointerName)
    if self.pointer then
        self.pointer:SetPivot(Vec2.New(0.5, 0.5))
        self.pointer:SetEventEnabled(false)
    end
    self:UpdateComponentsVisible()
end

--设置摇杆方向指针
function SuperJoystick:SetDirectionalPointer(directionalPointerName)
    self.directionalPointer = self:FindImage(directionalPointerName)
    if self.directionalPointer then
        self.directionalPointer:SetPivot(Vec2.New(0.5, 0.5))
        self.directionalPointer:SetEventEnabled(false)
    end
    self:UpdateComponentsVisible()
end

function SuperJoystick:SetJoystickRadius(radius)
    self.joystickRadius = radius
end


function SuperJoystick:GetJoystickRadius()
    return self.joystickRadius
end

function SuperJoystick:SetDirectionalRadius(radius)
    self.directionalRadius = radius
end

function SuperJoystick:GetDirectionalRadius()
    return self.directionalRadius
end

--设置摇杆指针半径
function SuperJoystick:SetPointerRadius(radius)
    self.pointerRadius = radius
end

function SuperJoystick:OnClicked(touchPos)
    if not SuperJoystick.super.OnClicked(self, touchPos) then
        return false
    end
    return true
end

--事件过滤
function SuperJoystick:OnEventFilter(obj, eventName, args1, args2, args3, args4, args5)
    if obj == self.outer then
        if eventName == "TouchBegin" then
            if self.pointer then
                self.pointer:BackupScreenRect()
                self.joystickOrginPos = self.pointer:GetScreenPosition() + self.pointer:GetPivotPoint()
            end
            local touchPos = args1:Clone()
            if self.fixedJoystick then
                self:InputJoystickPosition(self.joystickOrginPos)
            else
                self:InputJoystickPosition(touchPos)
            end
            self:SetFingerDown(true)
            if self.pointerDownCallback then
                self.pointerDownCallback(self, touchPos)
            end
        elseif eventName == "TouchMove" then
            if self.isFingerDown then
                local touchPos = args1:Clone()
                self:InputFingerPosition(touchPos)
                if self.pointerMoveCallback then
                    self.pointerMoveCallback(self, touchPos)
                end
            end
        elseif eventName == "TouchEnd" then
            if self.isFingerDown then
                self:SetFingerDown(false)
                if self.pointerUpCallback then
                    self.pointerUpCallback(self, touchPos)
                end
                if self.resetDirectionOnPointerUp then
                    if self.directionChangedCallback then
                        self.directionChangedCallback(self, Vec2.zero(), Vec2.zero())
                    end
                end
            end
        end
        return false
    end
    return true
end

function SuperJoystick:SetFingerDown(isFingerDown)
    self.isFingerDown = isFingerDown

    if self.isFingerDown then
        self.directionUnmodded = Vec2.zero()
        self.direction = Vec2.zero()
        self.angle = 0
    else
        if self.pointer then
            self.pointer:RestoreScreenRect()
        end
        self.directionUnmodded = Vec2.zero()
        self.direction = Vec2.zero()
        self.angle = 0
    end
    self:UpdateComponentsVisible()
end

--更新组件可见性
function SuperJoystick:UpdateComponentsVisible()    
    if self.isFingerDown then
        if self.aimer then
            self.aimer:SetVisible(true)
        end
        if self.directionalPointer and self.directionUnmodded:Length() > 0 then
            self.directionalPointer:SetVisible(true)
        end
        if self.inner then
            self.inner:SetVisible(false)
        end
    else
        if self.aimer then
            self.aimer:SetVisible(false)
        end
        if self.directionalPointer then
            self.directionalPointer:SetVisible(false)
        end
        if self.inner then
            self.inner:SetVisible(true)
        end
    end
end

--设置摇杆是否固定
function SuperJoystick:SetFixedJoystick(fixedJoystick)
    self.fixedJoystick = fixedJoystick
end

--设置超出摇杆半径是否跟随手指移动
function SuperJoystick:SetFollowFinger(followFinger)
    self.followFinger = followFinger
end

--设置内圈位置
function SuperJoystick:InputJoystickPosition(position)
    self.joystickPosition = position:Clone()
    if self.aimer then
        self.aimer:SetScreenPosition(position - self.aimer:GetPivotPoint())
    end
    if self.directionalPointer then
        self.directionalPointer:SetScreenPosition(position - self.directionalPointer:GetPivotPoint())
    end
    if self.pointer then
        self.pointer:SetScreenPosition(position - self.pointer:GetPivotPoint())
    end
end

--设置手指位置
function SuperJoystick:InputFingerPosition(fingerPosition)
    self.fingerPosition = fingerPosition:Clone()

    if self.followFinger then
        -- 计算从摇杆中心到手指位置的向量
        local pointerOffset = self.fingerPosition - self.joystickPosition
        -- 如果超出最大半径，则限制在最大半径上
        
        local maxRadius = self.joystickRadius
        if pointerOffset:Length() > maxRadius then
            local joystickPos = self.fingerPosition - pointerOffset:Normalized() * maxRadius
            local outerScreenRect = self.outer:GetScreenRect()
            joystickPos = outerScreenRect:Clamp(joystickPos.x, joystickPos.y)
            self:InputJoystickPosition(joystickPos)
        end
    end

    self.directionUnmodded = self.fingerPosition - self.joystickPosition
    self.direction = self.directionUnmodded:Normalized()

    self.angle = math.deg(self.direction:ClockwiseAngle(Vec2.New(0, 1))) - 180

    local aimerWidth = self.aimer:GetSize().x
    local aimerHeight = self.aimer:GetSize().y

    if self.pointer then
        -- 计算从摇杆中心到手指位置的向量
        local pointerOffset = self.fingerPosition - self.joystickPosition
        -- 如果超出最大半径，则限制在最大半径上
        local maxRadius = self.joystickRadius - self.pointerRadius
        if pointerOffset:Length() > maxRadius then
            pointerOffset = pointerOffset:Normalized() * maxRadius
        end
        -- 直接设置pointer位置
        self.pointer:SetScreenPosition(self.joystickPosition + pointerOffset - self.pointer:GetPivotPoint())
    end


    if self.directionalPointer then
        local criclePos = UIUtils:CalculateCirclePos(self.directionalRadius, self.directionalRadius, self.angle)
        self.directionalPointer:SetRotation(self.angle)
        self.directionalPointer:SetScreenPosition(criclePos + self.joystickPosition - self.directionalPointer:GetPivotPoint())
    end

    self:UpdateComponentsVisible()

    if self.directionChangedCallback then
        self.directionChangedCallback(self, self.direction, self.directionUnmodded)
    end
end

--设置摇杆指针按下回调
function SuperJoystick:PointerDownCallback(callback)
    self.pointerDownCallback = callback
end

--设置摇杆指针抬起回调
function SuperJoystick:PointerUpCallback(callback)
    self.pointerUpCallback = callback
end

--设置摇杆指针移动回调
function SuperJoystick:PointerMoveCallback(callback)
    self.pointerMoveCallback = callback
end

--设置摇杆方向改变回调
function SuperJoystick:DirectionChangedCallback(callback)
    self.directionChangedCallback = callback
end



return SuperJoystick