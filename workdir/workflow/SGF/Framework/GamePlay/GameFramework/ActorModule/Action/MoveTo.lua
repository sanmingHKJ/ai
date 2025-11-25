local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local MoveBy = GFScript("ActorModule.Action.MoveBy")

local MoveTo = Class.New("MoveTo", MoveBy)

--初始化
function MoveTo:Init(duration,endPosition,autoRotate)
    Action.Init(self,duration)
    self.autoRotate = autoRotate
    self.endPosition = endPosition:Clone()
end

--开始
function MoveTo:StartWith(target)
    MoveTo.super.StartWith(self, target)
    self.delta = self.endPosition - self.target.AvatarComponent:GetPosition()
    self.direction = self.delta:Normalized()
    self.speed = self.delta:Magnitude() / self.duration
end

--开始
function MoveTo:OnStart()
    MoveTo.super.OnStart(self)
end

--更新
function MoveTo:OnUpdate(t,dt)
    MoveTo.super.OnUpdate(self,t,dt)
end


return MoveTo