-- 说明:滑动条控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperProgress = GFScript("UIModule.UIWidget.SuperProgress")   
local UIManager = GFScript("UIModule.UIManager")
local SuperSlider = UIClass.New("SuperSlider", SuperProgress)

function SuperSlider:Constructor()
    
end 

function SuperSlider:Destructor()
    
end

return SuperSlider

