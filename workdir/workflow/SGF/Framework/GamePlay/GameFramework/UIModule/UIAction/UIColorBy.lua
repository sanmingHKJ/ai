-- 说明:颜色变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Color = GFScript("UIModule.UIMath.Color")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UIColorBy = UIClass.New("UIColorBy", UIValueBy)

function UIColorBy:SetValue(value)
    self:SetColor(value)
end

function UIColorBy:GetValue()
    return self:GetColor()
end

--克隆
function UIColorBy:Clone()
    local action = UIColorBy.New()
    action:Init(self.duration,self.delta)
    return action
end

--反向
function UIColorBy:Reverse(target)
    local action = UIColorBy.New()
    action:Init(self.duration,-self.delta)
    return action
end

return UIColorBy
