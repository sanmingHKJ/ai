-- 说明:旋转actin
-- 日期:2024年8月7日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UIUtils = GFScript("UIModule.UIUtils")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")

local UIRotateTo = UIClass.New("UIRotateTo", UIValueTo)

function UIRotateTo:SetValue(value)
    self:SetRotation(value)
end

function UIRotateTo:GetValue()
    return self:GetRotation()
end

--克隆
function UIRotateTo:Clone()
    local action = UIRotateTo.New()
    action:Init(self.duration,self.endValue)
    return action
end

--反向
function UIRotateTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UIRotateTo.New()
    action:Init(self.duration,UIUtils:GetRotation(target))
    return action
end



return UIRotateTo