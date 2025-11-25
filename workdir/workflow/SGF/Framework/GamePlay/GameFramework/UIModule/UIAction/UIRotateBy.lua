-- 说明:旋转actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UIRotateBy = UIClass.New("UIRotateBy", UIValueBy)

function UIRotateBy:SetValue(value)
    self:SetRotation(value)
end

function UIRotateBy:GetValue()
    return self:GetRotation()
end

--克隆
function UIRotateBy:Clone()
    local action = UIRotateBy.New()
    action:Init(self.duration,self.delta)
    return action
end

--反向
function UIRotateBy:Reverse(target)
    local action = UIRotateBy.New()
    action:Init(self.duration,-self.delta)
    return action
end



return UIRotateBy
