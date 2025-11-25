-- 说明:缓动类
-- 日期:2025年4月16日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Ease = {}

--补间类型
Ease.Easing = {
    Linear = "Linear",                    --线性变化，匀速运动
    EaseInQuad = "EaseInQuad",           --二次方加速，开始慢后来快
    EaseOutQuad = "EaseOutQuad",         --二次方减速，开始快后来慢
    EaseInOutQuad = "EaseInOutQuad",     --二次方加减速，两端慢中间快
    EaseInCubic = "EaseInCubic",         --三次方加速，开始更慢后来更快
    EaseOutCubic = "EaseOutCubic",       --三次方减速，开始更快后来更慢
    EaseInOutCubic = "EaseInOutCubic",   --三次方加减速，两端更慢中间更快
    EaseInQuart = "EaseInQuart",         --四次方加速，起始极慢迅速加快
    EaseOutQuart = "EaseOutQuart",       --四次方减速，开始极快迅速减慢
    EaseInOutQuart = "EaseInOutQuart",   --四次方加减速，两端极慢中间极快
    EaseInQuint = "EaseInQuint",         --五次方加速，开始几乎静止后急剧加速
    EaseOutQuint = "EaseOutQuint",       --五次方减速，开始极快后急剧减速至近静止
    EaseInOutQuint = "EaseInOutQuint",   --五次方加减速，两端几乎静止中间急剧变化
    EaseInExpo = "EaseInExpo",           --指数加速，开始几乎静止后呈指数加速
    EaseOutExpo = "EaseOutExpo",         --指数减速，开始极快后呈指数减速
    EaseInOutExpo = "EaseInOutExpo",     --指数加减速，两端静止中间呈指数变化
    EaseInCirc = "EaseInCirc",           --圆形加速，沿圆弧轨迹逐渐加速
    EaseOutCirc = "EaseOutCirc",         --圆形减速，沿圆弧轨迹逐渐减速
    EaseInOutCirc = "EaseInOutCirc",     --圆形加减速，两端沿圆弧轨迹变化
    EaseInElastic = "EaseInElastic",     --弹性加速，如同拉伸橡皮筋后释放
    EaseOutElastic = "EaseOutElastic",   --弹性减速，到达终点时会有回弹效果
    EaseInOutElastic = "EaseInOutElastic", --弹性加减速，两端都有回弹效果
    EaseInBack = "EaseInBack",           --回退加速，先回退一小步再加速前进
    EaseOutBack = "EaseOutBack",         --回退减速，快到终点时回退一下再到达
    EaseInOutBack = "EaseInOutBack",     --回退加减速，两端都会有回退效果
    EaseInBounce = "EaseInBounce",       --弹跳渐入，开始时多次弹跳幅度渐大
    EaseOutBounce = "EaseOutBounce",     --弹跳渐出，结束时多次弹跳幅度渐小
    EaseInOutBounce = "EaseInOutBounce"  --弹跳渐入渐出，两端都有多次弹跳效果
}

--Linear
function Ease.Linear(progress)
    return progress
end

--EaseInQuad
function Ease.EaseInQuad(progress)
    return progress * progress
end

--EaseOutQuad
function Ease.EaseOutQuad(progress)
    return -progress * (progress - 2)
end

--EaseInOutQuad
function Ease.EaseInOutQuad(progress)
    if progress < 0.5 then
        return 2 * progress * progress
    else
        return -2 * progress * (progress - 2) - 1
    end
end

--EaseInCubic
function Ease.EaseInCubic(progress)
    return progress * progress * progress
end

--EaseOutCubic
function Ease.EaseOutCubic(progress)
    return (progress - 1) * (progress - 1) * (progress - 1) + 1
end

--EaseInOutCubic
function Ease.EaseInOutCubic(progress)
    if progress < 0.5 then
        return 4 * progress * progress * progress
    else
        return (progress - 1) * (2 * progress - 2) * (2 * progress - 2) + 1
    end
end

--EaseInQuart
function Ease.EaseInQuart(progress)
    return progress * progress * progress * progress
end

--EaseOutQuart
function Ease.EaseOutQuart(progress)
    return 1 - (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
end

--EaseInOutQuart
function Ease.EaseInOutQuart(progress)
    if progress < 0.5 then
        return 8 * progress * progress * progress * progress
    else
        return 1 - 8 * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
    end
end

--EaseInQuint
function Ease.EaseInQuint(progress)
    return progress * progress * progress * progress * progress
end

--EaseOutQuint
function Ease.EaseOutQuint(progress)
    return 1 + (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
end

--EaseInOutQuint
function Ease.EaseInOutQuint(progress)
    if progress < 0.5 then
        return 16 * progress * progress * progress * progress * progress
    else
        return 1 + 16 * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
    end
end

--EaseInExpo
function Ease.EaseInExpo(progress)
    return progress == 0 and 0 or math.pow(2, 10 * (progress - 1))
end

--EaseOutExpo
function Ease.EaseOutExpo(progress)
    return progress == 1 and 1 or 1 - math.pow(2, -10 * progress)
end

--EaseInOutExpo
function Ease.EaseInOutExpo(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    if progress < 0.5 then
        return math.pow(2, 20 * progress - 10) / 2
    else
        return (2 - math.pow(2, -20 * progress + 10)) / 2
    end
end

--EaseInCirc
function Ease.EaseInCirc(progress)
    return 1 - math.sqrt(1 - progress * progress)
end

--EaseOutCirc
function Ease.EaseOutCirc(progress)
    return math.sqrt(1 - (progress - 1) * (progress - 1))
end

--EaseInOutCirc
function Ease.EaseInOutCirc(progress)
    if progress < 0.5 then
        return (1 - math.sqrt(1 - 4 * progress * progress)) / 2
    else
        return (math.sqrt(1 - 4 * (progress - 1) * (progress - 1)) + 1) / 2
    end
end

--EaseInElastic
function Ease.EaseInElastic(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    return -math.pow(2, 10 * progress - 10) * math.sin((progress * 10 - 10.75) * 2 * math.pi / 3)
end

--EaseOutElastic
function Ease.EaseOutElastic(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    return math.pow(2, -10 * progress) * math.sin((progress * 10 - 0.75) * 2 * math.pi / 3) + 1
end

--EaseInOutElastic
function Ease.EaseInOutElastic(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    if progress < 0.5 then
        return -(math.pow(2, 20 * progress - 10) * math.sin((20 * progress - 11.125) * 2 * math.pi / 4.5)) / 2
    else
        return (math.pow(2, -20 * progress + 10) * math.sin((20 * progress - 11.125) * 2 * math.pi / 4.5)) / 2 + 1
    end
end

--EaseInBack
function Ease.EaseInBack(progress)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * progress * progress * progress - c1 * progress * progress
end

--EaseOutBack
function Ease.EaseOutBack(progress)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(progress - 1, 3) + c1 * math.pow(progress - 1, 2)
end

--EaseInOutBack
function Ease.EaseInOutBack(progress)
    local c1 = 1.70158
    local c2 = c1 * 1.525
    if progress < 0.5 then
        return (math.pow(2 * progress, 2) * ((c2 + 1) * 2 * progress - c2)) / 2
    else
        return (math.pow(2 * progress - 2, 2) * ((c2 + 1) * (progress * 2 - 2) + c2) + 2) / 2
    end
end

--EaseOutBounce
function Ease.EaseOutBounce(progress)
    local n1 = 7.5625
    local d1 = 2.75
    if progress < 1 / d1 then
        return n1 * progress * progress
    elseif progress < 2 / d1 then
        progress = progress - 1.5 / d1
        return n1 * progress * progress + 0.75
    elseif progress < 2.5 / d1 then
        progress = progress - 2.25 / d1
        return n1 * progress * progress + 0.9375
    else
        progress = progress - 2.625 / d1
        return n1 * progress * progress + 0.984375
    end
end

--EaseInBounce
function Ease.EaseInBounce(progress)
    return 1 - Ease.EaseOutBounce(1 - progress)
end

--EaseInOutBounce
function Ease.EaseInOutBounce(progress)
    if progress < 0.5 then
        return (1 - Ease.EaseOutBounce(1 - 2 * progress)) / 2
    else
        return (1 + Ease.EaseOutBounce(2 * progress - 1)) / 2
    end
end

return Ease