-- 说明:值变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")

local UIValueBy = UIClass.New("UIValueBy", UIAction)

--初始化
function UIValueBy:Init(duration,delta)
    UIAction.Init(self,duration)
    self.delta = delta
    self.startValue = nil

    self.setValueCallback = nil
    self.getValueCallback = nil
end

--开始
function UIValueBy:StartWith(target)
    UIAction.StartWith(self, target)
    self.startValue = self:GetValue()
    self.endValue = self.startValue + self.delta
end
--开始
function UIValueBy:OnStart()
end

--更新
function UIValueBy:OnUpdate(t)
    local value = self:Lerp(self.startValue, self.endValue, t)
    self:SetValue(value)
end

--结束
function UIValueBy:Stop()
    UIAction.Stop(self)
end

--派生类实现
function UIValueBy:GetValue()
    if self.getValueCallback then
        return self.getValueCallback(self.target)
    end
    if self.target and self.target.GetValue then
        return self.target:GetValue()
    end
    return 0
end

--派生类实现
function UIValueBy:SetValue(value)
    if self.setValueCallback then
        self.setValueCallback(self.target, value)
    end
    if self.target and self.target.SetValue then
        self.target:SetValue(value)
    end
end

function UIValueBy:Lerp(startValue, endValue, t)
    return startValue + (endValue - startValue) * t
end

return UIValueBy
