local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Tween = GFScript("CoreModule.Tween")

local JumpBy = Class.New("JumpBy", Action)

--初始化
function JumpBy:Init(duration, delta, height, jumps,upCallback,downCallback)
    Action.Init(self,duration)
    self.direction = delta:Normalized()
    self.delta = delta:Clone()
    self.height = height
    self.jumps = jumps
    self.upCallback = upCallback
    self.downCallback = downCallback
    self.preState = -1 --0上升 1下降
    self.previousY = 0
    self.speed = self.delta:Magnitude() / self.duration

    --各阶段曲线
    self.moveEasing = Tween.Easing.Linear
    self.upEasing = Tween.Easing.Linear
    self.downEasing = Tween.Easing.Linear
end

--开始
function JumpBy:StartWith(target)
    Action.StartWith(self, target)
    self.startPosition = self.target.AvatarComponent:GetPosition()
    self.previousPosition = self.startPosition:Clone()

    --禁用重力
    self.backupGravityEnable = self.target.AvatarComponent:GetGravityEnable()
    self.target.AvatarComponent:AddHoverCount()
end

--开始
function JumpBy:OnStart()
end

--更新
function JumpBy:OnUpdate(t, dt)

    local curState = (t <= 0.5) and 0 or 1
    if curState ~= self.preState then
        if curState == 1 then
            --落地
            if self.downCallback ~= nil then
                self.downCallback()
            end
        elseif curState == 0 then
            --上升
            if self.upCallback ~= nil then
                self.upCallback()
            end
        end
        self.preState = curState
    end

    local positionOffset
    if t <= 0.5 then
        positionOffset = self:CalculatePositionOffset(Tween[self.upEasing](t / 0.5) * 0.5)
    else
        positionOffset = self:CalculatePositionOffset(Tween[self.downEasing]((t - 0.5) / 0.5) * 0.5 + 0.5)
    end


    local preProcess = (self.elapsed - dt) / self.duration
    local curProcess = (self.elapsed) / self.duration
    preProcess = Tween[self.moveEasing](preProcess)
    curProcess = Tween[self.moveEasing](curProcess)
    local newDt = (curProcess - preProcess) * self.duration

    local jumpOffset = Vec3.New(0, positionOffset - self.previousY, 0)
    local moveOffset = self.direction * newDt * self.speed

    local position = self.target.AvatarComponent:GetPosition()
    local newPos = position + jumpOffset + moveOffset

    -- self.target.AvatarComponent:SetPosition(newPos)
    self.target.AvatarComponent:MoveStep(jumpOffset + moveOffset)

    self.previousY = positionOffset

    -- local position = self.target.AvatarComponent:GetPosition()
    -- local diff = position - self.previousPosition
    -- self.startPosition = self.startPosition + diff
    -- local frac = math.fmod(t * self.jumps, 1)
    -- local y = self.height * 4 * frac * (1 - frac)
    -- y = y + self.delta.y * t
    -- local x = self.delta.x * t
    -- local z = self.delta.z * t
    -- local newPos = self.startPosition + Vec3.New(x, y, z)
    -- local step = 1.0 / (self.jumps * 2)
    -- local stepIndex = math.floor(t / step)
    -- local curState = (stepIndex % 2 == 0) and 0 or 1
    -- if curState ~= self.preState then
    --     if curState == 1 then
    --         --落地
    --         if self.downCallback ~= nil then
    --             self.downCallback()
    --         end
    --     elseif curState == 0 then
    --         --上升
    --         if self.upCallback ~= nil then
    --             self.upCallback()
    --         end
    --     end
    --     self.preState = curState
    -- end
    -- self.target.AvatarComponent:SetPosition(newPos)
    -- -- self.target.AvatarComponent:MoveTo(newPos)
    -- self.previousPosition = newPos
end

function JumpBy:CalculatePositionOffset(t)
    return self.height * 4 * t * (1 - t)
end

--结束
function JumpBy:Stop()
    --恢复重力
    self.target.AvatarComponent:ReduceHoverCount()
    Action.Stop(self)
end


return JumpBy