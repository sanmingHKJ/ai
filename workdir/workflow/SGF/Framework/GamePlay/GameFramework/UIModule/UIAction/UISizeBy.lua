-- 说明:尺寸变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UISizeBy = UIClass.New("UISizeBy", UIValueBy)

function UISizeBy:SetValue(value)
    self:SetSize(value)
end

function UISizeBy:GetValue()
    return self:GetSize()
end

--克隆
function UISizeBy:Clone()
    local action = UISizeBy.New()
    action:Init(self.duration,self.delta)
    return action
end

--反向
function UISizeBy:Reverse(target)
    local action = UISizeBy.New()
    action:Init(self.duration,-self.delta)
    return action
end



return UISizeBy
