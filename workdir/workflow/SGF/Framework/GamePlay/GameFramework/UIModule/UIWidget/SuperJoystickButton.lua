-- 说明:超级摇杆按钮
-- 日期:2025年2月19日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperJoystick = GFScript("UIModule.UIWidget.SuperJoystick")
local SuperJoystickButton = UIClass.New("SuperJoystickButton", SuperJoystick)

function SuperJoystickButton:Constructor()
    self.joystickRadius = 0
end


function SuperJoystickButton:Destructor()
    self.joystickRadius = 0
end

function SuperJoystickButton:Init(bindObj)
    if not SuperJoystickButton.super.Init(self, bindObj) then
        return false
    end
    
    return true
end

return SuperJoystickButton





