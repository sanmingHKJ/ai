-- 说明:瞬发action
-- 日期:2024年5月16日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")

local UIActionInstant = UIClass.New("UIActionInstant", UIAction)
--更新
function UIActionInstant:Update(dt)
    if self.target == nil then
        return true
    end
    if self.firstUpdate then
        self.firstUpdate = false
        self:OnStart()
    end
    self:OnUpdate(1)
    self:OnEnd()
    return true
end

--是否完成
function UIActionInstant:IsDone()
    return true
end


return UIActionInstant