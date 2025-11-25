local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ActionInstant = GFScript("ActorModule.Action.ActionInstant")

local CallFunc = Class.New("CallFunc", ActionInstant)

--初始化
function CallFunc:Init(callback)
    self.callback = callback
end
--开始
function CallFunc:OnStart()
    --执行回调
    self.callback()
end

--克隆
function CallFunc:Clone()
    local action = CallFunc.New()
    action:Init(self.callback)
    return action
end

--反向
function CallFunc:Reverse(target)
    return self:Clone()
end

return CallFunc