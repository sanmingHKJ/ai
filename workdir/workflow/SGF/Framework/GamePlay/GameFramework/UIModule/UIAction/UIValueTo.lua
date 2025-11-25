-- 说明:值变化actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")

local UIValueTo = UIClass.New("UIValueTo", UIValueBy)

--初始化
function UIValueTo:Init(duration,endValue)
    UIAction.Init(self,duration)
    self.endValue = endValue
end

--开始
function UIValueTo:StartWith(target)
    UIAction.StartWith(self, target)
    self.startValue = self:GetValue()
end


return UIValueTo