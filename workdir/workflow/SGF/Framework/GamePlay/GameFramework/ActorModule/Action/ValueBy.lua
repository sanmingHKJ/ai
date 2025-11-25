-- 说明:值变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")

local ValueBy = Action.Extend("ValueBy")

--初始化
function ValueBy:Init(duration,delta)
    Action.Init(self,duration)
    self.delta = delta
    self.startValue = nil

    self.setValueCallback = nil
    self.getValueCallback = nil
end

--开始
function ValueBy:StartWith(target)
    Action.StartWith(self, target)
    self.startValue = self:GetValue()
    self.endValue = self.startValue + self.delta
end
--开始
function ValueBy:OnStart()
end

--更新
function ValueBy:OnUpdate(t)
    local value = self:Lerp(self.startValue, self.endValue, t)
    self:SetValue(value)
end

--结束
function ValueBy:Stop()
    Action.Stop(self)
end

--派生类实现
function ValueBy:GetValue(target)
    target = target or self.target
    if self.getValueCallback then
        return self.getValueCallback(target)
    end
    if target and target.GetValue then
        return target:GetValue()
    end
    return 0
end

--派生类实现
function ValueBy:SetValue(value)
    if self.setValueCallback then
        self.setValueCallback(self.target, value)
    end
    if self.target and self.target.SetValue then
        self.target:SetValue(value)
    end
end

function ValueBy:Lerp(startValue, endValue, t)
    return startValue + (endValue - startValue) * t
end

--克隆
function ValueBy:Clone()
    local action = ValueBy.New()
    action:Init(self.duration,self.delta)
    return action
end

--反向
function ValueBy:Reverse(target)
    local action = ValueBy.New()
    action.setValueCallback = self.setValueCallback
    action.getValueCallback = self.getValueCallback
    action:Init(self.duration,-self.delta)
    return action
end

return ValueBy
