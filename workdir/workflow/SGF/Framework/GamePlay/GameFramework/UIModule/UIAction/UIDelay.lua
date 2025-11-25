-- 说明:延迟Action
-- 日期:2024年5月30日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")

local UIDelay = UIClass.New("UIDelay", UIAction)

--初始化
function UIDelay:Init(duration)
    UIAction.Init(self,duration)
end

--克隆
function UIDelay:Clone()
    local action = UIDelay.New()
    action:Init(self.duration)
    return action
end

--反向
function UIDelay:Reverse(target)
    return self:Clone()
end

return UIDelay
