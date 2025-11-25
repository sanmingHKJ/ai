-- 说明:尺寸变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UIUtils = GFScript("UIModule.UIUtils")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")

local UISizeTo = UIClass.New("UISizeTo", UIValueTo)


function UISizeTo:SetValue(value)
    self:SetSize(value)
end

function UISizeTo:GetValue()
    return self:GetSize()
end

--克隆
function UISizeTo:Clone()
    local action = UISizeTo.New()
    action:Init(self.duration,self.endValue)
    return action
end

--反向
function UISizeTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UISizeTo.New()
    action:Init(self.duration,UIUtils:GetSize(target))
    return action
end



return UISizeTo