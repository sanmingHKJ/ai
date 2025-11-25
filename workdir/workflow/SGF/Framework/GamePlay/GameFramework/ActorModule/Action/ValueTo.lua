-- 说明:值变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local ValueBy = GFScript("ActorModule.Action.ValueBy")
local ValueTo = ValueBy.Extend("ValueTo")

--初始化
function ValueTo:Init(duration,endValue)
    Action.Init(self,duration)
    self.endValue = endValue
end

--开始
function ValueTo:StartWith(target)
    Action.StartWith(self, target)
    self.startValue = self:GetValue()
end

--克隆
function ValueTo:Clone()
    local action = ValueTo.New()
    action:Init(self.duration,self.endValue)
    return action
end

--反向
function ValueTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = ValueTo.New()
    action.setValueCallback = self.setValueCallback
    action.getValueCallback = self.getValueCallback
    action:Init(self.duration,self:GetValue(target))
    return action
end


return ValueTo