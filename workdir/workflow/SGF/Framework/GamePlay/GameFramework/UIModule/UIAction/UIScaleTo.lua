-- 说明:缩放actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UIUtils = GFScript("UIModule.UIUtils")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")

local UIScaleTo = UIClass.New("UIScaleTo", UIValueTo)

function UIScaleTo:SetValue(value)
    self:SetScale(value)
end

function UIScaleTo:GetValue()
    return self:GetScale()
end

--克隆
function UIScaleTo:Clone()
    local action = UIScaleTo.New()
    action:Init(self.duration,self.endValue)
    return action
end

--反向
function UIScaleTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UIScaleTo.New()
    action:Init(self.duration,UIUtils:GetScale(target))
    return action
end


return UIScaleTo