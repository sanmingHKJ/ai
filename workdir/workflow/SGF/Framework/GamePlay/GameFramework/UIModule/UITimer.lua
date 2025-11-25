-- 说明:定时器管理器
-- 日期:2024年3月11日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UILog = GFScript("UIModule.UILog")
local UIUtils = GFScript("UIModule.UIUtils")
local UITimer = {}

--定时器列表
UITimer.timers = {}

--内建定时器类型
--0.1秒定时器
UITimer.Frame01 = 0
--0.5秒定时器
UITimer.Frame05 = 1
--1秒定时器
UITimer.Frame1 = 2
--3秒定时器
UITimer.Frame3 = 3
--5秒定时器
UITimer.Frame5 = 4
--10秒定时器
UITimer.Frame10 = 5
--30秒定时器
UITimer.Frame30 = 6
--60秒定时器
UITimer.Frame60 = 7

local AllInterTimers = {
    UITimer.Frame01,
    UITimer.Frame05,
    UITimer.Frame1,
    UITimer.Frame3,
    UITimer.Frame5,
    UITimer.Frame10,
    UITimer.Frame30,
    UITimer.Frame60,
}

local TimerTypes = {
    [UITimer.Frame01] = 0.1,
    [UITimer.Frame05] = 0.5,
    [UITimer.Frame1] = 1,
    [UITimer.Frame3] = 3,
    [UITimer.Frame5] = 5,
    [UITimer.Frame10] = 10,
    [UITimer.Frame30] = 30,
    [UITimer.Frame60] = 60,
}

local InternalTimers = {
    [UITimer.Frame01] = {},
    [UITimer.Frame05] = {},
    [UITimer.Frame1] = {},
    [UITimer.Frame3] = {},
    [UITimer.Frame5] = {},
    [UITimer.Frame10] = {},
    [UITimer.Frame30] = {},
    [UITimer.Frame60] = {},
}

--初始化
function UITimer:Init()
    self.autoId = 0
    --注册所有内建定时器
    for k,v in ipairs(AllInterTimers) do
        local interval = TimerTypes[v]
        self:AddTimer(function(dt)
            UIUtils:RemoveAll(InternalTimers[v], function(timer)
                timer.callback(dt)
                timer.count = timer.count + 1
                if timer.repeatCount > 0 and timer.count >= timer.repeatCount then
                    return true
                end
                return false
            end)
        end,interval)
    end

    self.updating = false

    self.addTimerList = {}
    self.removeTimerList = {}
end
-- 生成一个定时器Id
function UITimer:GenTimerId()
    self.autoId = self.autoId + 1
    return self.autoId
end

--注册内建定时器
function UITimer:AddInternalTimer(callback,type,repeatCount)
    if InternalTimers[type] == nil then
        InternalTimers[type] = {}
    end
    repeatCount = repeatCount or 0
    local timerId = self:GenTimerId()
    table.insert(InternalTimers[type], {
        id = timerId, 
        repeatCount = repeatCount,
        count = 0, 
        callback = callback
    })
    return timerId
end

--注销内建定时器
function UITimer:RemoveInternalTimer(id)
    for i,v in ipairs(InternalTimers) do
        for j,k in ipairs(v) do
            if k.id == id then
                table.remove(v, j)
                return
            end
        end
    end
end

--注册定时器
function UITimer:AddTimer(callback, interval, repeatCount, duration, delay)
    local timerId = self:GenTimerId()
    if self.updating then
        table.insert(self.addTimerList, {timerId, callback, interval, repeatCount, duration, delay})
        return timerId
    end

    UITimer.timers[timerId] = {
        callback = callback,
        interval = interval,
        repeatCount = repeatCount or 0,
        elapsedTime = 0,
        time = 0,
        count = 0,
        duration = duration or 0,
        delay = delay or 0
    }
    return timerId
end

--延迟执行
function UITimer:DelayCall(func,delayTime)
    return UITimer:AddTimer(function()
        func()
    end, delayTime, 1)
end

--移除定时器
function UITimer:RemoveTimer(timerId)
    if self.updating then
        table.insert(self.removeTimerList, timerId)
        return
    end
    if UITimer.timers[timerId] == nil then
        return
    end
    UITimer.timers[timerId] = nil
end

--更新
function UITimer:Update(dt)
    self:SetUpdating(true)
    local needCallbacks = {}
    local removeTimers = {}
    for k,v in pairs(UITimer.timers) do
        if v.delay > 0 then
            v.delay = v.delay - dt
            if v.delay <= 0 then
                dt = dt + v.delay
                v.delay = 0
            end
        end
        if v.delay <= 0 then
            v.elapsedTime = v.elapsedTime + dt
            v.time = v.time + dt
            if v.time >= v.interval then

                table.insert(needCallbacks,{callback = v.callback,time = v.time})
                --取模
                v.time = v.time % v.interval
                --v.time = v.time - v.interval
                v.count = v.count + 1
                if v.repeatCount > 0 and v.count >= v.repeatCount then
                    table.insert(removeTimers,k)
                end

                -- local ok, errmsg = xpcall(function()
                --     v.callback(v.time)
                -- end,debug.traceback)
                -- if not ok then
                --     UILog:Error("UITimer error:%s", tostring(errmsg))
                -- end
            end
            if v.duration > 0 and v.elapsedTime >= v.duration then
                table.insert(removeTimers,k)
            end
        end
    end

    for _,v in pairs(needCallbacks) do
        local ok, errmsg = xpcall(function()
            v.callback(v.time)
        end,debug.traceback)
        if not ok then
            UILog:Error("UITimer error:%s", tostring(errmsg))
        end
    end

    for _,v in pairs(removeTimers) do
        UITimer:RemoveTimer(v)
    end
    self:SetUpdating(false)
end

function UITimer:IsUpdating()
    return self.updating
end

function UITimer:SetUpdating(updating)
    self.updating = updating
    if not updating then
        for _,v in pairs(self.addTimerList) do
            UITimer.timers[v[1]] = {
                callback = v[2],
                interval = v[3],
                repeatCount = v[4] or 0,
                elapsedTime = 0,
                time = 0,
                count = 0,
                duration = v[5] or 0,
                delay = v[6] or 0
            }
        end
        for _,v in pairs(self.removeTimerList) do
            self:RemoveTimer(v)
        end
        self.addTimerList = {}
        self.removeTimerList = {}

    end
end

return UITimer