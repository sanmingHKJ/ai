local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local Vec3 = GFScript("CoreModule.Math.Vec3")

local ApproachTarget = Class.New("ApproachTarget", Action)

--初始化
function ApproachTarget:Init(duration, approachPosition, approachDistance, approachSpeed, approachAngle)
    Action.Init(self,duration)
    self.approachDistance = approachDistance
    self.approachSpeed = approachSpeed
    self.maxDistance = duration * self.approachSpeed
    self.approachPosition = approachPosition
    self.approachAngle = approachAngle
end

--开始
function ApproachTarget:StartWith(target)
    Action.StartWith(self, target)
end

--开始
function ApproachTarget:OnStart()
end

--更新
function ApproachTarget:OnUpdate(t, dt)
    local approachTarget = self.target.target
    if not approachTarget then
        --直线移动
        self.target.AvatarComponent:MoveStep(self.target.AvatarComponent:GetForward() * self.approachSpeed * dt)
        return
    end
    local targetPos = approachTarget:GetPosition()
    --位置接近
    if self.approachPosition then
        local selfPos = self.target:GetPosition()
        local diff = targetPos - selfPos
        local distance = diff:Magnitude()
        if distance > self.approachDistance then
            targetPos = selfPos + diff:Normalized() * self.approachDistance
            --移动到目标位置
            self.target.AvatarComponent:MoveStep(diff:Normalized() * self.approachSpeed * dt)
        else
            --移动结束
            self:StopImmediately()
        end
    end
    if self.approachAngle then
        --旋转接近
        self.target:RotateTo(targetPos)
    end
end


--结束
function ApproachTarget:Stop()
    Action.Stop(self)
end


return ApproachTarget