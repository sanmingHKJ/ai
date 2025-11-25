-- 说明:功能槽位控件
-- 日期:2025年4月24日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperSlotBase = GFScript("UIModule.UIWidget.SuperSlotBase")
local UIUtils = GFScript("UIModule.UIUtils")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")

local UIFuncSlot = UIClass.New("UIFuncSlot", SuperSlotBase)

function UIFuncSlot:Constructor()
    
end

function UIFuncSlot:Destructor()
    
end

function UIFuncSlot:Init(bindObj)
    if not SuperSlotBase.Init(self, bindObj) then
        return false
    end

    return true
end


return UIFuncSlot