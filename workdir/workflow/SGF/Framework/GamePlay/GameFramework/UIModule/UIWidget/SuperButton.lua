-- 说明:按钮控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local SuperButton = UIClass.New("SuperButton", UIWidget)

function SuperButton:Constructor()
end 

function SuperButton:Destructor()
    
end

function SuperButton:Init(bindObj, managedBindObj)
    if not SuperButton.super.Init(self, bindObj, managedBindObj) then
        return false
    end 
    self:EnableClickScaleAnimation(0.9)
    return true
end

return SuperButton

