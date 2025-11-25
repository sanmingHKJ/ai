-- 说明:透明度变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UIAlphaBy = UIClass.New("UIAlphaBy", UIValueBy)

function UIAlphaBy:SetValue(value)
    self:SetAlpha(value)
end

function UIAlphaBy:GetValue()
    return self:GetAlpha()
end

--克隆
function UIAlphaBy:Clone()
    local action = UIAlphaBy.New()
    action:Init(self.duration,self.delta)
    return action
end 

--反向
function UIAlphaBy:Reverse(target)
    local action = UIAlphaBy.New()
    action:Init(self.duration,-self.delta)
    return action
end

return UIAlphaBy
