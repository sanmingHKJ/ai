-- 说明:图片控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperButtonBase = GFScript("UIModule.UIWidget.SuperButtonBase")
local UIManager = GFScript("UIModule.UIManager")
local UITweenUtils = GFScript("UIModule.UITweenUtils")
local UIUtils = GFScript("UIModule.UIUtils")
local SuperImage = UIClass.New("SuperImage", SuperButtonBase)

function SuperImage:Constructor()
    
    
end 

function SuperImage:Destructor()
end

--初始化
function SuperImage:Init(bindObj, managedBindObj)
    if not SuperImage.super.Init(self, bindObj, managedBindObj) then
        return false
    end
    return true
end


return SuperImage

