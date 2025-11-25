-- 说明:缩放actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UIScaleBy = UIClass.New("UIScaleBy", UIValueBy)

function UIScaleBy:SetValue(value)
    self:SetScale(value)
end

function UIScaleBy:GetValue()
    return self:GetScale()
end

--克隆
function UIScaleBy:Clone()
    local action = UIScaleBy.New()
    action:Init(self.duration,self.delta)
    return action
end

--反向
function UIScaleBy:Reverse(target)
    local action = UIScaleBy.New()
    action:Init(self.duration,-self.delta)
    return action
end


return UIScaleBy
