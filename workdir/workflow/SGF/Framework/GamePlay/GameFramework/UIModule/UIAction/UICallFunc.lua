-- 说明:函数调用Action
-- 日期:2024年5月30日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIActionInstant = GFScript("UIModule.UIAction.UIActionInstant")

local UICallFunc = UIClass.New("UICallFunc", UIActionInstant)

--初始化
function UICallFunc:Init(callback)
    self.callback = callback
end
--开始
function UICallFunc:OnStart()
    --执行回调
    self.callback()
end

--克隆
function UICallFunc:Clone()
    local action = UICallFunc.New()
    action:Init(self.callback)
    return action
end

--反向
function UICallFunc:Reverse(target)
    return self:Clone()
end

return UICallFunc