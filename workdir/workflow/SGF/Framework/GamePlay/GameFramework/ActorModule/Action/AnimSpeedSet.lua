local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Action = GFScript("ActorModule.Action")

local AnimSpeedSet = Class.New("AnimSpeedSet", Action)

--初始化
function AnimSpeedSet:Init(duration,speed)
    Action.Init(self,duration)
    self.speed = speed
end

--开始
function AnimSpeedSet:StartWith(target)
    Action.StartWith(self, target)
end
--开始
function AnimSpeedSet:OnStart()
    self.target.AvatarComponent:SetAnimSpeed(self.speed)
end

--更新
function AnimSpeedSet:OnUpdate(t)
end

--结束
function AnimSpeedSet:Stop()
    self.target.AvatarComponent:SetAnimSpeed(1)
    Action.Stop(self)
end


return AnimSpeedSet
