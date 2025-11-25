local Log = GFScript("CoreModule.Log")
local Tween = {}

--补间动画列表
Tween.tweens = {}
Tween.tempTweens = {}

--补间类型
Tween.Easing = {
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
--生成TweenId
function Tween:GenerateTweenId()
    self.tweenId = self.tweenId or 0
    self.tweenId = self.tweenId + 1
    return self.tweenId
end
--注册补间动画
function Tween:AddTween(callback, duration, easing)
    local tweenId = self:GenerateTweenId()
    if self.updating then
        table.insert(Tween.tempTweens,
        {
            tweenId = tweenId,
            callback = callback,
            duration = duration,
            easing = easing or Tween.Easing.Linear,
            time = 0
        })
    else
        table.insert(Tween.tweens,
        {
            tweenId = tweenId,
            callback = callback,
            duration = duration,
            easing = easing or Tween.Easing.Linear,
            time = 0
        })
    end
    return tweenId
end

--移除补间动画
function Tween:RemoveTween(tweenId)
    for i, tween in ipairs(Tween.tweens) do
        if tween.tweenId == tweenId then
            table.remove(Tween.tweens, i)
            break
        end
    end
end

function Tween:SetTweenDelay(tweenId, delay)
    for i, tween in ipairs(Tween.tempTweens) do
        if tween.tweenId == tweenId then
            tween.delayTimeEnd = Utils:GetServerTime() + delay
            return
        end
    end
end

--补间添加完成回调
function Tween:AddTweenComplete(tweenId, complete)
    for i, tween in ipairs(Tween.tempTweens) do
        if tween.tweenId == tweenId then
            tween.complete = complete
            return
        end
    end
    for i, tween in ipairs(Tween.tweens) do
        if tween.tweenId == tweenId then
            tween.complete = complete
            return
        end
    end
end

function Tween:SetComplete(tweenId, complete)
    self:AddTweenComplete(tweenId, complete)
end

--取消补间动画
function Tween:Cancel(tweenId)
    self:RemoveTween(tweenId)
end

--MoveTo补间动画
function Tween:MoveTo(callback, from, to, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from:Lerp(to, progress),progress)
    end, duration, easing)
end

--ScaleTo补间动画
function Tween:ScaleTo(callback, from, to, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from:Lerp(to, progress),progress)
    end, duration, easing)
end

--RotateTo补间动画
function Tween:RotateTo(callback, from, to, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from:Lerp(to, progress),progress)
    end, duration, easing)
end

--ColorTo补间动画
function Tween:ColorTo(callback, from, to, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from:Lerp(to, progress),progress)
    end, duration, easing)
end

--AlphaTo补间动画
function Tween:AlphaTo(callback, from, to, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + (to - from) * progress,progress)
    end, duration, easing)
end

--SizeTo补间动画
function Tween:SizeTo(callback, from, to, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from:Lerp(to, progress),progress)
    end, duration, easing)
end

--MoveBy补间动画
function Tween:MoveBy(callback, from, by, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + by * progress,progress)
    end, duration, easing)
end

--ScaleBy补间动画
function Tween:ScaleBy(callback, from, by, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + by * progress,progress)
    end, duration, easing)
end

--RotateBy补间动画
function Tween:RotateBy(callback, from, by, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + by * progress,progress)
    end, duration, easing)
end

--ColorBy补间动画
function Tween:ColorBy(callback, from, by, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + by * progress,progress)
    end, duration, easing)
end

--AlphaBy补间动画
function Tween:AlphaBy(callback, from, by, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + by * progress,progress)
    end, duration, easing)
end

--SizeBy补间动画
function Tween:SizeBy(callback, from, by, duration, easing)
    return Tween:AddTween(function(progress)
        callback(from + by * progress,progress)
    end, duration, easing)
end

--Linear
function Tween.Linear(progress)
    return progress
end

--EaseInQuad
function Tween.EaseInQuad(progress)
    return progress * progress
end

--EaseOutQuad
function Tween.EaseOutQuad(progress)
    return -progress * (progress - 2)
end

--EaseInOutQuad
function Tween.EaseInOutQuad(progress)
    if progress < 0.5 then
        return 2 * progress * progress
    else
        return -2 * progress * (progress - 2) - 1
    end
end

--EaseInCubic
function Tween.EaseInCubic(progress)
    return progress * progress * progress
end

--EaseOutCubic
function Tween.EaseOutCubic(progress)
    return (progress - 1) * (progress - 1) * (progress - 1) + 1
end

--EaseInOutCubic
function Tween.EaseInOutCubic(progress)
    if progress < 0.5 then
        return 4 * progress * progress * progress
    else
        return (progress - 1) * (2 * progress - 2) * (2 * progress - 2) + 1
    end
end

--EaseInQuart
function Tween.EaseInQuart(progress)
    return progress * progress * progress * progress
end

--EaseOutQuart
function Tween.EaseOutQuart(progress)
    return 1 - (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
end

--EaseInOutQuart
function Tween.EaseInOutQuart(progress)
    if progress < 0.5 then
        return 8 * progress * progress * progress * progress
    else
        return 1 - 8 * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
    end
end

--EaseInQuint
function Tween.EaseInQuint(progress)
    return progress * progress * progress * progress * progress
end

--EaseOutQuint
function Tween.EaseOutQuint(progress)
    return 1 + (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
end

--EaseInOutQuint
function Tween.EaseInOutQuint(progress)
    if progress < 0.5 then
        return 16 * progress * progress * progress * progress * progress
    else
        return 1 + 16 * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1) * (progress - 1)
    end
end

--EaseInExpo
function Tween.EaseInExpo(progress)
    return progress == 0 and 0 or math.pow(2, 10 * (progress - 1))
end

--EaseOutExpo
function Tween.EaseOutExpo(progress)
    return progress == 1 and 1 or 1 - math.pow(2, -10 * progress)
end

--EaseInOutExpo
function Tween.EaseInOutExpo(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    if progress < 0.5 then
        return math.pow(2, 20 * progress - 10) / 2
    else
        return (2 - math.pow(2, -20 * progress + 10)) / 2
    end
end

--EaseInCirc
function Tween.EaseInCirc(progress)
    return 1 - math.sqrt(1 - progress * progress)
end

--EaseOutCirc
function Tween.EaseOutCirc(progress)
    return math.sqrt(1 - (progress - 1) * (progress - 1))
end

--EaseInOutCirc
function Tween.EaseInOutCirc(progress)
    if progress < 0.5 then
        return (1 - math.sqrt(1 - 4 * progress * progress)) / 2
    else
        return (math.sqrt(1 - 4 * (progress - 1) * (progress - 1)) + 1) / 2
    end
end

--EaseInElastic
function Tween.EaseInElastic(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    return -math.pow(2, 10 * progress - 10) * math.sin((progress * 10 - 10.75) * 2 * math.pi / 3)
end

--EaseOutElastic
function Tween.EaseOutElastic(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    return math.pow(2, -10 * progress) * math.sin((progress * 10 - 0.75) * 2 * math.pi / 3) + 1
end

--EaseInOutElastic
function Tween.EaseInOutElastic(progress)
    if progress == 0 then return 0 end
    if progress == 1 then return 1 end
    if progress < 0.5 then
        return -(math.pow(2, 20 * progress - 10) * math.sin((20 * progress - 11.125) * 2 * math.pi / 4.5)) / 2
    else
        return (math.pow(2, -20 * progress + 10) * math.sin((20 * progress - 11.125) * 2 * math.pi / 4.5)) / 2 + 1
    end
end

--EaseInBack
function Tween.EaseInBack(progress)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * progress * progress * progress - c1 * progress * progress
end

--EaseOutBack
function Tween.EaseOutBack(progress)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(progress - 1, 3) + c1 * math.pow(progress - 1, 2)
end

--EaseInOutBack
function Tween.EaseInOutBack(progress)
    local c1 = 1.70158
    local c2 = c1 * 1.525
    if progress < 0.5 then
        return (math.pow(2 * progress, 2) * ((c2 + 1) * 2 * progress - c2)) / 2
    else
        return (math.pow(2 * progress - 2, 2) * ((c2 + 1) * (progress * 2 - 2) + c2) + 2) / 2
    end
end

--EaseOutBounce
function Tween.EaseOutBounce(progress)
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
function Tween.EaseInBounce(progress)
    return 1 - Tween.EaseOutBounce(1 - progress)
end

--EaseInOutBounce
function Tween.EaseInOutBounce(progress)
    if progress < 0.5 then
        return (1 - Tween.EaseOutBounce(1 - 2 * progress)) / 2
    else
        return (1 + Tween.EaseOutBounce(2 * progress - 1)) / 2
    end
end

--更新
function Tween:Update(dt)
    self.updating = true
    --遍历补间动画，从后往前
    for i = #Tween.tweens, 1, -1 do
        local tween = Tween.tweens[i]
        if not tween.delayTimeEnd or (tween.delayTimeEnd and Utils:GetServerTime() >= tween.delayTimeEnd) then
            if tween.time < tween.duration then
                tween.time = tween.time + dt
                local progress = tween.time / tween.duration
                if progress > 1 then
                    progress = 1
                end
                if tween.easing == Tween.Easing.Linear then
                    tween.callback(progress)
                elseif tween.easing == Tween.Easing.EaseInQuad then
                    tween.callback(Tween.EaseInQuad(progress))
                elseif tween.easing == Tween.Easing.EaseOutQuad then
                    tween.callback(Tween.EaseOutQuad(progress))
                elseif tween.easing == Tween.Easing.EaseInOutQuad then
                    tween.callback(Tween.EaseInOutQuad(progress))
                elseif tween.easing == Tween.Easing.EaseInCubic then
                    tween.callback(Tween.EaseInCubic(progress))
                elseif tween.easing == Tween.Easing.EaseOutCubic then
                    tween.callback(Tween.EaseOutCubic(progress))
                elseif tween.easing == Tween.Easing.EaseInOutCubic then
                    tween.callback(Tween.EaseInOutCubic(progress))
                elseif tween.easing == Tween.Easing.EaseInQuart then
                    tween.callback(Tween.EaseInQuart(progress))
                elseif tween.easing == Tween.Easing.EaseOutQuart then
                    tween.callback(Tween.EaseOutQuart(progress))
                elseif tween.easing == Tween.Easing.EaseInOutQuart then
                    tween.callback(Tween.EaseInOutQuart(progress))
                elseif tween.easing == Tween.Easing.EaseInQuint then
                    tween.callback(Tween.EaseInQuint(progress))
                elseif tween.easing == Tween.Easing.EaseOutQuint then
                    tween.callback(Tween.EaseOutQuint(progress))
                elseif tween.easing == Tween.Easing.EaseInOutQuint then
                    tween.callback(Tween.EaseInOutQuint(progress))
                elseif tween.easing == Tween.Easing.EaseInExpo then
                    tween.callback(Tween.EaseInExpo(progress))
                elseif tween.easing == Tween.Easing.EaseOutExpo then
                    tween.callback(Tween.EaseOutExpo(progress))
                elseif tween.easing == Tween.Easing.EaseInOutExpo then
                    tween.callback(Tween.EaseInOutExpo(progress))
                elseif tween.easing == Tween.Easing.EaseInCirc then
                    tween.callback(Tween.EaseInCirc(progress))
                elseif tween.easing == Tween.Easing.EaseOutCirc then
                    tween.callback(Tween.EaseOutCirc(progress))
                elseif tween.easing == Tween.Easing.EaseInOutCirc then
                    tween.callback(Tween.EaseInOutCirc(progress))
                elseif tween.easing == Tween.Easing.EaseInElastic then
                    tween.callback(Tween.EaseInElastic(progress))
                elseif tween.easing == Tween.Easing.EaseOutElastic then
                    tween.callback(Tween.EaseOutElastic(progress))
                elseif tween.easing == Tween.Easing.EaseInOutElastic then
                    tween.callback(Tween.EaseInOutElastic(progress))
                elseif tween.easing == Tween.Easing.EaseInBack then
                    tween.callback(Tween.EaseInBack(progress))
                elseif tween.easing == Tween.Easing.EaseOutBack then
                    tween.callback(Tween.EaseOutBack(progress))
                elseif tween.easing == Tween.Easing.EaseInOutBack then
                    tween.callback(Tween.EaseInOutBack(progress))
                elseif tween.easing == Tween.Easing.EaseInBounce then
                    tween.callback(Tween.EaseInBounce(progress))
                elseif tween.easing == Tween.Easing.EaseOutBounce then
                    tween.callback(Tween.EaseOutBounce(progress))
                elseif tween.easing == Tween.Easing.EaseInOutBounce then
                    tween.callback(Tween.EaseInOutBounce(progress))
                end
            else
                tween.callback(1)
                if tween.complete ~= nil then
                    tween.complete()
                end
                table.remove(Tween.tweens, i)
            end
        end
    end
    self.updating = false
    for _,v in ipairs(Tween.tempTweens) do
        table.insert(Tween.tweens, v)
    end
    Tween.tempTweens = {}
end

return Tween