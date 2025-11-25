-- 说明:UI动画
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")

local UIUtils = GFScript("UIModule.UIUtils")

local UISequence = GFScript("UIModule.UIAction.UISequence")
local UIEase = GFScript("UIModule.UIAction.UIEase")
local UISpeed = GFScript("UIModule.UIAction.UISpeed")
local UIDelay = GFScript("UIModule.UIAction.UIDelay")
local UICallFunc = GFScript("UIModule.UIAction.UICallFunc")
local UIRepeatForever = GFScript("UIModule.UIAction.UIRepeatForever")
local UIRepeat = GFScript("UIModule.UIAction.UIRepeat")

local UIMoveBy = GFScript("UIModule.UIAction.UIMoveBy")
local UIMoveTo = GFScript("UIModule.UIAction.UIMoveTo")
local UIRotateBy = GFScript("UIModule.UIAction.UIRotateBy")
local UIRotateTo = GFScript("UIModule.UIAction.UIRotateTo")
local UIAlphaBy = GFScript("UIModule.UIAction.UIAlphaBy")
local UIAlphaTo = GFScript("UIModule.UIAction.UIAlphaTo")
local UIScaleBy = GFScript("UIModule.UIAction.UIScaleBy")
local UIScaleTo = GFScript("UIModule.UIAction.UIScaleTo")
local UISizeBy = GFScript("UIModule.UIAction.UISizeBy")
local UISizeTo = GFScript("UIModule.UIAction.UISizeTo")
local UIColorBy = GFScript("UIModule.UIAction.UIColorBy")
local UIColorTo = GFScript("UIModule.UIAction.UIColorTo")
local UIJumpBy = GFScript("UIModule.UIAction.UIJumpBy")
local UIJumpTo = GFScript("UIModule.UIAction.UIJumpTo")
local UIValueBy = GFScript("UIModule.UIAction.UIValueBy")
local UIValueTo = GFScript("UIModule.UIAction.UIValueTo")
local UIShake = GFScript("UIModule.UIAction.UIShake")

local UITween = {}

local actionStack = {}
local actionTag = nil
local actionRepeatTimes = nil
local finishCallback = nil

local actionSpeed = nil

local actionObj = nil

--通过表构建
--[[
    表数据形式，每个元素的第一个元素为当前类的函数名称，后面的元素为参数，数量不固定
    {
        {"MoveBy", Vec2.New(-100, 0), 1},
        {"Ease", "EaseInOutBack"},
        {"CallFunc", function()
            UILog:Error("touch1")
        end},
    }
]]
function UITween:Build(bindObj, data)
    actionObj = bindObj
    actionStack = {}
    actionTag = nil
    actionRepeatTimes = nil
    actionSpeed = nil
    finishCallback = nil
    if data then
        for _, v in ipairs(data) do
            local funcName = v[1]
            local func = self[funcName]
            if func then
                func(self, unpack(v, 2))
            end
        end
    end
    return self
end

--开始动画
function UITween:Start()
    if not actionObj then
        UILog:Error("UITween:Start actionObj is nil")
        return
    end
    if #actionStack == 0 then
        UILog:Error("UITween:Start actionStack is empty")
        return
    end

    local action = UISequence.New()
    action:Init(unpack(actionStack))

    -- 重复
    if actionRepeatTimes then
        if actionRepeatTimes == 0 then
            local repeatForever = UIRepeatForever.New()
            repeatForever:Init(action)
            action = repeatForever
        else
            local repeatAction = UIRepeat.New()
            repeatAction:Init(action, actionRepeatTimes)
            action = repeatAction

        end
    end

    -- 结束回调
    if finishCallback then
        local callFunc = UICallFunc.New()
        callFunc:Init(finishCallback)
        local sequence = UISequence.New()
        sequence:Init(action, callFunc)
        action = sequence
    end

    -- 速度
    if actionSpeed then
        local speedAction = UISpeed.New()
        speedAction:Init(action, actionSpeed)
        action = speedAction
    end

    if actionTag then
        UIUtils:StopActionByTag(actionObj, actionTag)
        action:SetTag(actionTag)
    end
    UIUtils:RunAction(actionObj, action)
    actionStack = {}
    actionTag = nil
    actionRepeatTimes = nil
    finishCallback = nil
    return action
end

--移动到
--@param position 位置
--@param duration 持续时间
function UITween:MoveTo(position, duration)
    local action = UIMoveTo.New()
    action:Init(duration, position)
    table.insert(actionStack, action)

    return self
end

--移动
--@param position 位置
--@param duration 持续时间
function UITween:MoveBy(position, duration)
    local action = UIMoveBy.New()
    action:Init(duration, position)
    table.insert(actionStack, action)

    return self
end

--旋转
--@param rotation 旋转
--@param duration 持续时间
function UITween:RotateTo(rotation, duration)
    local action = UIRotateTo.New()
    action:Init(duration, rotation)
    table.insert(actionStack, action)

    return self
end

--旋转
--@param rotation 旋转
--@param duration 持续时间
function UITween:RotateBy(rotation, duration)
    local action = UIRotateBy.New()
    action:Init(duration, rotation)
    table.insert(actionStack, action)   

    return self
end

--透明度
--@param alpha 透明度
--@param duration 持续时间
function UITween:AlphaTo(alpha, duration)
    local action = UIAlphaTo.New()
    action:Init(duration, alpha)
    table.insert(actionStack, action)

    return self
end

--透明度
--@param alpha 透明度
--@param duration 持续时间
function UITween:AlphaBy(alpha, duration)
    local action = UIAlphaBy.New()
    action:Init(duration, alpha)
    table.insert(actionStack, action)

    return self
end

--缩放
--@param scale 缩放
--@param duration 持续时间
function UITween:ScaleTo(scale, duration)
    local action = UIScaleTo.New()
    action:Init(duration, scale)
    table.insert(actionStack, action)

    return self
end

--缩放
--@param scale 缩放
--@param duration 持续时间
function UITween:ScaleBy(scale, duration)
    local action = UIScaleBy.New()
    action:Init(duration, scale)
    table.insert(actionStack, action)

    return self
end

--颜色
--@param color 颜色
--@param duration 持续时间
function UITween:ColorTo(color, duration)
    local action = UIColorTo.New()
    action:Init(duration, color)
    table.insert(actionStack, action)

    return self
end

--颜色
--@param color 颜色
--@param duration 持续时间
function UITween:ColorBy(color, duration)
    local action = UIColorBy.New()
    action:Init(duration, color)
    table.insert(actionStack, action)

    return self
end

--尺寸
--@param size 尺寸
--@param duration 持续时间
function UITween:SizeTo(size, duration)
    local action = UISizeTo.New()
    action:Init(duration, size)
    table.insert(actionStack, action)

    return self
end

--尺寸
--@param size 尺寸
--@param duration 持续时间
function UITween:SizeBy(size, duration)
    local action = UISizeBy.New()
    action:Init(duration, size)
    table.insert(actionStack, action)

    return self
end

--跳跃
--@param position 位置
--@param height 高度
--@param duration 持续时间
function UITween:JumpTo(position, height, duration)
    local action = UIJumpTo.New()
    action:Init(duration, position, height)
    table.insert(actionStack, action)

    return self
end

--跳跃
--@param position 位置
--@param height 高度
--@param duration 持续时间
function UITween:JumpBy(position, height, duration)
    local action = UIJumpBy.New()
    action:Init(duration, position, height)
    table.insert(actionStack, action)

    return self
end

--值变化
--@param value 值
--@param duration 持续时间
--@param setValueCallback 设置值的回调
--@param getValueCallback 获取值的回调
function UITween:ValueTo(value, duration, setValueCallback, getValueCallback)
    local action = UIValueTo.New()
    action:Init(duration, value)
    action.setValueCallback = setValueCallback
    action.getValueCallback = getValueCallback
    table.insert(actionStack, action)

    return self
end

--值变化
--@param value 值
--@param duration 持续时间
--@param setValueCallback 设置值的回调
--@param getValueCallback 获取值的回调
function UITween:ValueBy(value, duration, setValueCallback, getValueCallback)
    local action = UIValueBy.New()
    action:Init(duration, value)
    action.setValueCallback = setValueCallback
    action.getValueCallback = getValueCallback
    table.insert(actionStack, action)

    return self
end

--震动
--@param duration 持续时间
--@param params 参数
function UITween:Shake(duration, params)
    local action = UIShake.New()
    action:Init(duration, params)
    table.insert(actionStack, action)

    return self
end

--延迟
--@param delay 延迟时间
function UITween:Delay(delay)
    local action = UIDelay.New()
    action:Init(delay)
    table.insert(actionStack, action)

    return self
end

--调用函数
--@param func 函数
function UITween:CallFunc(func)
    local action = UICallFunc.New()
    action:Init(func)
    table.insert(actionStack, action)

    return self
end

--缓动
--@param easing 缓动类型
function UITween:Ease(easing)
    local action = actionStack[#actionStack]
    if not action then
        UILog:Error("UITween:Ease action is nil")
        return
    end

    local ease = UIEase.New()
    ease:Init(action, easing)
    actionStack[#actionStack] = ease

    return self
end

--速度
--@param speed 速度
function UITween:Speed(speed)
    actionSpeed = speed
    return self
end

--重复
--@param times 次数 0为无限
function UITween:Repeat(times)
    times = times or 0
    actionRepeatTimes = times
    return self
end

--取反
function UITween:Reverse()
    local action = actionStack[#actionStack]
    if not action then
        UILog:Error("UITween:Reverse action is nil")
        return
    end
    local reverseAction = action:Reverse(actionObj)
    table.insert(actionStack, reverseAction)
    return self
end

--设置tag
--@param tag 标签
function UITween:Tag(tag)
    actionTag = tag
    return self
end

--结束回调
--@param callback 回调
function UITween:OnComplete(callback)
    finishCallback = callback
    return self
end



return UITween