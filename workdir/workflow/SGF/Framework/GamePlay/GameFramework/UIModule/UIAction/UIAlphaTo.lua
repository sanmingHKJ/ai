-- 说明:透明度变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UIUtils = GFScript("UIModule.UIUtils")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")

local UIAlphaTo = UIClass.New("UIAlphaTo", UIValueTo)

function UIAlphaTo:SetValue(value)
    self:SetAlpha(value)
end

function UIAlphaTo:GetValue()
    return self:GetAlpha()
end

--克隆
function UIAlphaTo:Clone()
    local action = UIAlphaTo.New()
    action:Init(self.duration,self.endValue)
    return action
end

function UIAlphaTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UIAlphaTo.New()
    action:Init(self.duration,UIUtils:GetAlpha(target))
    return action
end

return UIAlphaTo