local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local JumpBy = GFScript("ActorModule.Action.JumpBy")

local JumpTo = Class.New("JumpTo", JumpBy)

--初始化
function JumpTo:Init(duration,endPosition,height,jumps,upCallback,downCallback)
    JumpBy.Init(self,duration,endPosition,height,jumps,upCallback,downCallback)
    self.endPosition = endPosition:Clone()
end

--开始
function JumpTo:StartWith(target)
    JumpBy.StartWith(self, target)
    local targetPos = self.target.AvatarComponent:GetPosition()
    self.height = self.height - targetPos.y
    self.delta = self.endPosition - targetPos
    self.direction = self.delta:Normalized()
    self.speed = self.delta:Magnitude() / self.duration
end

--开始
function JumpTo:OnStart()
    JumpBy.OnStart(self)
end

--开始


return JumpTo