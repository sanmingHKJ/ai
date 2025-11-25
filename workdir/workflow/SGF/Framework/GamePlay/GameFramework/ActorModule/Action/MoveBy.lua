local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Action = GFScript("ActorModule.Action")

local MoveBy = Class.New("MoveBy", Action)

--初始化
function MoveBy:Init(duration,delta,autoRotate)
    Action.Init(self,duration)
    self.direction = delta:Normalized()
    self.delta = delta:Clone()
    self.startPosition = nil
	self.previousPosition = nil
    self.speed = self.delta:Magnitude() / self.duration
    self.autoRotate = autoRotate
end

--是否同步起始速度
function MoveBy:SetSyncStartSpeed(syncStart)
    self.syncStartSpeed = syncStart
end
--是否同步结束速度
function MoveBy:SetSyncEndSpeed(syncEnd)
    self.syncEndSpeed = syncEnd
end

--开始
function MoveBy:StartWith(target)
    Action.StartWith(self, target)
    self.startPosition = self.target.AvatarComponent:GetPosition()
    self.previousPosition = self.startPosition:Clone()
    --设置速度
    self.target.AvatarComponent:SetOverrideMoveSpeed(self.speed, self.syncStartSpeed ~= false)
    self.target.AvatarComponent:SetAutoRotate(false)
end
--开始
function MoveBy:OnStart()
end

--更新
function MoveBy:OnUpdate(t,dt)
    local position = self.target.AvatarComponent:GetPosition()

    -- local newPos = position + self.direction * dt * self.speed

    self.target.AvatarComponent:MoveStep(self.direction * dt * self.speed)

    -- local diff = position - self.previousPosition
    -- self.startPosition = self.startPosition + diff
    -- local newPos = self.startPosition + self.delta * t

    -- self.target.AvatarComponent:MoveStep(newPos - self.previousPosition)
    -- -- local dir = self.delta:Normalized()
    -- -- self.target.AvatarComponent:MoveBy(dir)
    -- -- self.target.AvatarComponent:SetPosition(newPos)
    -- self.previousPosition = self.target.AvatarComponent:GetPosition()
end

--结束
function MoveBy:Stop()
    self.target.AvatarComponent:MoveBy(Vec3.New(0,0,0))
    --恢复速度
    self.target.AvatarComponent:SetOverrideMoveSpeed(0, self.syncEndSpeed ~= false)
    self.target.AvatarComponent:SetAutoRotate(true)
    Action.Stop(self)
end


return MoveBy
