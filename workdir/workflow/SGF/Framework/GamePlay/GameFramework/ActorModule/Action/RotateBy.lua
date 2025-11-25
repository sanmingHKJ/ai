local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Action = GFScript("ActorModule.Action")

local RotateBy = Class.New("RotateBy", Action)

--初始化
function RotateBy:Init(duration,delta)
    Action.Init(self,duration)
    self.delta = delta:Clone()
    self.startOrient = nil
end

--开始
function RotateBy:StartWith(target)
    Action.StartWith(self, target)
    self.startOrient = self.target.AvatarComponent:GetRotation()
    self.endOrient = self.startOrient * self.delta
end
--开始
function RotateBy:OnStart()
end

--更新
function RotateBy:OnUpdate(t)
    local quat = self.startOrient:Slerp(self.endOrient,t)
    self.target.AvatarComponent:SetRotation(quat)
end

--结束
function RotateBy:Stop()
    Action.Stop(self)
end


return RotateBy
