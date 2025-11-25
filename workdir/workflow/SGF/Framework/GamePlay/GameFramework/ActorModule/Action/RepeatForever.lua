local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Repeat = GFScript("ActorModule.Action.Repeat")

local RepeatForever = Class.New("RepeatForever", Repeat)
--初始化
function RepeatForever:Init(action)
    RepeatForever.super.Init(self, action, math.huge)
end

--克隆
function RepeatForever:Clone()
    local action = RepeatForever.New()
    action:Init(self.innerAction:Clone())
    return action
end

--反向
function RepeatForever:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = RepeatForever.New()
    action:Init(innerAction)
    return action
end

return RepeatForever