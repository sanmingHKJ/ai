-- 说明:UI动画工具
-- 日期:2025年2月16日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Rect = GFScript("UIModule.UIMath.Rect")
local UITween = GFScript("UIModule.UITween")
local UILayout = GFScript("UIModule.UILayout")
local UIUtils = GFScript("UIModule.UIUtils")
local UIDefines = GFScript("UIModule.UIDefines")

local UITweenUtils = {}

--Tween
function UITweenUtils:Tween(control, tween)
    return UITween:Build(control, tween)
end

--淡入
--@param control UIWidget 控件
--@param duration number 动画持续时间
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UITweenUtils:FadeIn(control, duration, ease, finishCallback)
    duration = duration or 0.5
    ease = ease or "EaseInCubic"
    UIUtils:SetAlphaInHierarchy(control, 0)
    self:Tween(control, {
        {"AlphaTo", 1, duration}, {"Ease", ease},
    }):Tag("FadeIn"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--淡出
--@param control UIWidget 控件
--@param duration number 动画持续时间
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UITweenUtils:FadeOut(control, duration, ease, finishCallback)
    duration = duration or 0.5
    ease = ease or "EaseOutCubic"
    self:Tween(control, {
        {"AlphaTo", 0, duration}, {"Ease", ease},
    }):Tag("FadeOut"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end


--闪烁
--@param control UIWidget 控件
--@param duration number 动画持续时间
--@param count number 闪烁次数
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UITweenUtils:Blink(control, duration, count, ease, finishCallback)
    duration = duration or 0.5
    count = count or 1
    ease = ease or "EaseInOutBack"
    self:Tween(control, {
        {"AlphaTo", 0, duration}, {"Ease", ease},
        {"AlphaTo", 1, duration}, {"Ease", ease},
    }):Repeat(count):Tag("Blink"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end


--匹配变换
--@param control UIWidget 控件
--@param targetControl UIWidget 目标控件
--@param duration number 动画持续时间
--@param ease string 缓动类型
--@param finishCallback function 动画结束回调
function UITweenUtils:MatchTransformTo(control, targetControl, duration, ease, finishCallback)
    if not targetControl then
        UILog:Error("AnchoredMoveTo: targetControl is nil")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseOutCubic"
    local targetRect = UIUtils:GetScreenRect(targetControl)
    local targetPos = targetRect:GetPosition()
    local targetSize = targetRect:GetSize()
    self:MoveTo(control, targetPos + UIUtils:GetPivot(control) * targetSize, duration):Ease(ease):Start()
    self:SizeTo(control, targetSize, duration):Ease(ease):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--将控件对齐到目标控件的指定锚点位置
--@param control UIWidget 控件
--@param targetControl UIWidget 目标控件
--@param duration number 动画持续时间
--@param pivot Vec2 轴心点
--@param offset Vec2 位置偏移量
--@param anchor Vec2 锚点(0-1)，x为水平锚点，y为垂直锚点
--@param ease string 缓动类型
function UITweenUtils:AlignTo(control, targetControl, duration, pivot, offset, anchor, ease, finishCallback)
    if not targetControl then
        UILog:Error("AlignTo: targetControl is nil")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseOutCubic"
    local size = UIUtils:GetSize(control)
    local anchoredRect = UIUtils:CalculateAnchoredRect(targetControl, size, pivot, offset, anchor)
    local selfPivot = UIUtils:GetPivot(control)
    anchoredRect:Move(size.x * selfPivot.x, size.y * selfPivot.y)
    self:MoveTo(control, anchoredRect:GetPosition(), duration):Ease(ease):Start()
    self:SizeTo(control, anchoredRect:GetSize(), duration):Ease(ease):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--收集到目标控件
function UITweenUtils:CollectIn(control, targetControl, duration, scale, fadeDuration, ease, finishCallback)
    if not targetControl then
        UILog:Error("CollectIn: targetControl is nil")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseInCubic"
    scale = scale or 0.5
    fadeDuration = fadeDuration or 0.5

    local scaleX = 1
    local scaleY = 1
    if type(scale) == "number" then
        scaleX = scale
        scaleY = scale
    else
        scaleX = scale.x
        scaleY = scale.y
    end

    self:FadeIn(control, duration)
    
    local targetPos = UIUtils:GetPosition(control)
    local targetScale = UIUtils:GetScale(control)
    local targetRect = UIUtils:GetScreenRect(targetControl)
    UIUtils:SetPosition(control, targetRect:GetCenter())
    UIUtils:SetScale(control, Vec2.New(scaleX, scaleY))

    self:MoveTo(control, targetPos, duration):Ease(ease):Start()
    self:ScaleTo(control, targetScale, duration):Ease(ease):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--收集到目标控件
function UITweenUtils:CollectOut(control, targetControl, duration, scale, fadeDuration, ease, finishCallback)
    if not targetControl then
        UILog:Error("CollectOut: targetControl is nil")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseInCubic"
    scale = scale or 0.5
    fadeDuration = fadeDuration or 0.5

    local scaleX = 1
    local scaleY = 1
    if type(scale) == "number" then
        scaleX = scale
        scaleY = scale
    else
        scaleX = scale.x
        scaleY = scale.y
    end
    local targetRect = UIUtils:GetScreenRect(targetControl)
    local size = UIUtils:GetSize(control)
    local selfPivot = UIUtils:GetPivot(control)
    self:MoveTo(control, targetRect:GetCenter(), duration):Ease(ease):Start()
    self:ScaleTo(control, Vec2.New(scaleX, scaleY), duration):Ease(ease):OnComplete(function()
        self:FadeOut(control, fadeDuration, nil, finishCallback)
    end):Start()
end
--滑动进入动画
--@param control UIWidget 控件
--@param offset Vec2 起始位置的偏移量
--@param duration number 动画持续时间
--@param ease string 缓动类型(可选)
--@return UITween 动画对象
function UITweenUtils:SlideIn(control, offset, duration, ease, finishCallback)
    if not offset then
        UILog:Error("SlideIn: offset is required")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseOutBack"

    local targetPos = UIUtils:GetPosition(control)
    UIUtils:SetPosition(control, targetPos + offset)
    UIUtils:SetVisible(control, true)

    self:Tween(control, {
        {"MoveTo", targetPos, duration}, {"Ease", ease},
    }):Tag("SlideIn"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--滑动退出动画
--@param control UIWidget 控件
--@param offset Vec2 目标位置的偏移量
--@param duration number 动画持续时间
--@param ease string 缓动类型(可选)
--@return UITween 动画对象
function UITweenUtils:SlideOut(control, offset, duration, ease, finishCallback)
    if not offset then
        UILog:Error("SlideOut: offset is required")
        return
    end
    duration = duration or 0.5
    ease = ease or "EaseInBack"

    local targetPos = UIUtils:GetPosition(control) + offset

    self:Tween(control, {
        {"MoveTo", targetPos, duration}, {"Ease", ease},
    }):Tag("SlideOut"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--缩放进入动画
function UITweenUtils:ScaleIn(control, scale, duration, ease, finishCallback)
    self:FadeIn(control, duration)
    duration = duration or 0.5
    ease = ease or "EaseInCubic"
    local targetScale = UIUtils:GetScale(control)

    local scaleX = 1
    local scaleY = 1
    if type(scale) == "number" then
        scaleX = scale
        scaleY = scale
    else
        scaleX = scale.x
        scaleY = scale.y
    end

    UIUtils:SetScale(control, Vec2.New(scaleX, scaleY))
    self:Tween(control, {
        {"ScaleTo", targetScale, duration}, {"Ease", ease},
    }):Tag("ScaleIn"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--缩放退出动画
function UITweenUtils:ScaleOut(control, scale, duration, ease, finishCallback)
    self:FadeOut(control, duration)
    duration = duration or 0.5
    ease = ease or "EaseOutCubic"

    local scaleX = 1
    local scaleY = 1
    if type(scale) == "number" then
        scaleX = scale
        scaleY = scale
    else
        scaleX = scale.x
        scaleY = scale.y
    end

    local targetScale = UIUtils:GetScale(control) * Vec2.New(scaleX, scaleY)
    self:Tween(control, { 
        {"ScaleTo", targetScale, duration}, {"Ease", ease},
    }):Tag("ScaleOut"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--调整子控件布局
function UITweenUtils:AdjustLayoutChildrenTo(control, children,
    layoutOrigin, layoutDirection, 
    layoutReverse, layoutPadding, layoutSpacing, lineCount, duration, ease, finishCallback)
    
    duration = duration or 0.5
    ease = ease or "EaseOutCubic"

    local layoutRect = UIUtils:GetScreenRect(control)
    local layoutItems = {}
    for _, child in ipairs(children) do
        if child.Visible then
            local size = child.Size
            table.insert(layoutItems, Vec2.New(size.X, size.Y))
        end
    end
    UILayout:AdjustLayout(layoutRect, layoutItems, lineCount,
        layoutOrigin, layoutDirection, 
        layoutReverse, layoutPadding, layoutSpacing, function(index, pos, size)
            local child = children[index]
            local pivot = child.Pivot
            local targetPos = Vec2.New(pos.x + size.x * pivot.X, pos.y + size.y * pivot.Y)
            local targetSize = Vec2.New(size.x, size.y)
            self:MoveTo(child, targetPos, duration):Ease(ease):Start()
            if index == #layoutItems then
                self:SizeTo(child, targetSize, duration):Ease(ease):OnComplete(function()
                    if finishCallback then
                        finishCallback()
                    end
                end):Start()
            else
                self:SizeTo(child, targetSize, duration):Ease(ease):Start()
            end
        end)
end

--震动
function UITweenUtils:Shake(control, duration, params, finishCallback)
    return self:Tween(control, {
        {"Shake", duration, params},
    }):Tag("Shake"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end

--漂浮
function UITweenUtils:Float(control, offsetY, duration, finishCallback)
    return self:Tween(control, {
        {"MoveBy", Vec2.New(0, -offsetY), duration / 2},
        {"MoveBy", Vec2.New(0, offsetY), duration / 2},
    }):Repeat():Tag("Float"):OnComplete(function()
        if finishCallback then
            finishCallback()
        end
    end):Start()
end
-----------------------------------------------------------基础动画-----------------------------------------------------------
--跳跃
function UITweenUtils:JumpTo(control, position, height, duration)
    position = position or UIUtils:GetPosition(control)
    height = height or 100
    duration = duration or 0.5
    return self:Tween(control, {
        {"JumpTo", position, height, duration},
    }):Tag("JumpTo")
end

--跳跃
function UITweenUtils:JumpBy(control, position, height, duration)
    position = position or Vec2.New(0, 0)
    height = height or 100
    duration = duration or 0.5
    return self:Tween(control, {
        {"JumpBy", position, height, duration},
    }):Tag("JumpBy")
end

--移动
function UITweenUtils:MoveTo(control, position, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"MoveTo", position, duration},
    }):Tag("MoveTo")
end

--移动
function UITweenUtils:MoveBy(control, position, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"MoveBy", position, duration},
    }):Tag("MoveBy")
end

--大小
function UITweenUtils:SizeTo(control, size, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"SizeTo", size, duration},
    }):Tag("SizeTo")
end

--大小
function UITweenUtils:SizeBy(control, size, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"SizeBy", size, duration},
    }):Tag("SizeBy")
end

--缩放
function UITweenUtils:ScaleTo(control, scale, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"ScaleTo", scale, duration},
    }):Tag("ScaleTo")
end

--缩放
function UITweenUtils:ScaleBy(control, scale, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"ScaleBy", scale, duration},
    }):Tag("ScaleBy")
end

--旋转
function UITweenUtils:RotateTo(control, rotation, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"RotateTo", rotation, duration},
    }):Tag("RotateTo")
end

--旋转
function UITweenUtils:RotateBy(control, rotation, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"RotateBy", rotation, duration},
    }):Tag("RotateBy")
end

--颜色
function UITweenUtils:ColorTo(control, color, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"ColorTo", color, duration},
    }):Tag("ColorTo")
end

--颜色
function UITweenUtils:ColorBy(control, color, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"ColorBy", color, duration},
    }):Tag("ColorBy")
end

--透明度
function UITweenUtils:AlphaTo(control, alpha, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"AlphaTo", alpha, duration},
    }):Tag("AlphaTo")
end

--透明度
function UITweenUtils:AlphaBy(control, alpha, duration)
    duration = duration or 0.5
    return self:Tween(control, {
        {"AlphaBy", alpha, duration},
    }):Tag("AlphaBy")
end

return UITweenUtils

