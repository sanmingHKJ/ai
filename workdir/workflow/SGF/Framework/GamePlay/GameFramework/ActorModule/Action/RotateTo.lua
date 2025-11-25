local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local RotateBy = GFScript("ActorModule.Action.RotateBy")

local RotateTo = Class.New("RotateTo", RotateBy)

--初始化
function RotateTo:Init(duration,endOrient)
    Action.Init(self,duration)
    self.endOrient = endOrient:Clone()
end

--开始
function RotateTo:StartWith(target)
    Action.StartWith(self, target)
    self.startOrient = self.target.AvatarComponent:GetRotation()
end

--开始
function RotateTo:OnStart()
    RotateTo.super.OnStart(self)
end

--更新
function RotateTo:OnUpdate(t)
    RotateTo.super.OnUpdate(self,t)
end


return RotateTo