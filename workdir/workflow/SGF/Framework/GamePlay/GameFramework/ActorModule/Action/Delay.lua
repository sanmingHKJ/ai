local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")

local Delay = Class.New("Delay", Action)

--初始化
function Delay:Init(duration)
    Action.Init(self,duration)
end

--克隆
function Delay:Clone()
    local action = Delay.New()
    action:Init(self.duration)
    return action
end

--反向
function Delay:Reverse(target)
    return self:Clone()
end

return Delay
