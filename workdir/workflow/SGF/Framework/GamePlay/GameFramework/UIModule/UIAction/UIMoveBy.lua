-- 说明:移动actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UIMoveBy = UIClass.New("UIMoveBy", UIValueBy)

function UIMoveBy:SetValue(value)
    self:SetPosition(value)
end

function UIMoveBy:GetValue()
    return self:GetPosition()
end

--克隆
function UIMoveBy:Clone()
    local action = UIMoveBy.New()
    action:Init(self.duration,self.delta)
    return action
end

--反向
function UIMoveBy:Reverse(target)
    local action = UIMoveBy.New()
    action:Init(self.duration,-self.delta)
    return action
end



return UIMoveBy
