-- 说明:颜色变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIUtils = GFScript("UIModule.UIUtils")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")

local UIColorTo = UIClass.New("UIColorTo", UIValueTo)

function UIColorTo:SetValue(value)
    self:SetColor(value)
end

function UIColorTo:GetValue()
    return self:GetColor()
end

--克隆
function UIColorTo:Clone()
    local action = UIColorTo.New()
    action:Init(self.duration,self.endValue)
    return action
end

--反向
function UIColorTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UIColorTo.New()
    action:Init(self.duration,UIUtils:GetColor(target))
    return action
end

return UIColorTo