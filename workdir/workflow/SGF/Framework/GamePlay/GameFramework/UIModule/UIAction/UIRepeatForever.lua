-- 说明:永久循环action
-- 日期:2024年5月16日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIRepeat = GFScript("UIModule.UIAction.UIRepeat")

local UIRepeatForever = UIClass.New("UIRepeatForever", UIRepeat)
--初始化
function UIRepeatForever:Init(action)
    UIRepeatForever.super.Init(self, action, math.huge)
end

--克隆
function UIRepeatForever:Clone()
    local action = UIRepeatForever.New()
    action:Init(self.innerAction:Clone())
    return action
end

--反向
function UIRepeatForever:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = UIRepeatForever.New()
    action:Init(innerAction)
    return action
end

return UIRepeatForever