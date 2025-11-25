-- 说明:移动actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIUtils = GFScript("UIModule.UIUtils")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")

local UIMoveTo = UIClass.New("UIMoveTo", UIValueTo)

function UIMoveTo:SetValue(value)
    self:SetPosition(value)
end

function UIMoveTo:GetValue()
    return self:GetPosition()
end

--克隆
function UIMoveTo:Clone()
    local action = UIMoveTo.New()
    action:Init(self.duration,self.endValue)
    return action
end


--反向
function UIMoveTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UIMoveTo.New()
    action:Init(self.duration,UIUtils:GetPosition(target))
    return action
end

return UIMoveTo