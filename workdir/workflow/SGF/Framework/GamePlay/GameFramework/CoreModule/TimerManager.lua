local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local TableUtils = GFScript("CoreModule.TableUtils")
local TimerManager = {}

--定时器列表
TimerManager.timers = {}

--内建定时器类型
--0.1秒定时器
TimerManager.Frame01 = 0
--0.5秒定时器
TimerManager.Frame05 = 1
--1秒定时器
TimerManager.Frame1 = 2
--3秒定时器
TimerManager.Frame3 = 3
--5秒定时器
TimerManager.Frame5 = 4
--10秒定时器
TimerManager.Frame10 = 5
--30秒定时器
TimerManager.Frame30 = 6
--60秒定时器
TimerManager.Frame60 = 7

local AllInterTimers = {
    TimerManager.Frame01,
    TimerManager.Frame05,
    TimerManager.Frame1,
    TimerManager.Frame3,
    TimerManager.Frame5,
    TimerManager.Frame10,
    TimerManager.Frame30,
    TimerManager.Frame60,
}

local TimerTypes = {
    [TimerManager.Frame01] = 0.1,
    [TimerManager.Frame05] = 0.5,
    [TimerManager.Frame1] = 1,
    [TimerManager.Frame3] = 3,
    [TimerManager.Frame5] = 5,
    [TimerManager.Frame10] = 10,
    [TimerManager.Frame30] = 30,
    [TimerManager.Frame60] = 60,
}

local InternalTimers = {
    [TimerManager.Frame01] = {},
    [TimerManager.Frame05] = {},
    [TimerManager.Frame1] = {},
    [TimerManager.Frame3] = {},
    [TimerManager.Frame5] = {},
    [TimerManager.Frame10] = {},
    [TimerManager.Frame30] = {},
    [TimerManager.Frame60] = {},
}

--初始化
function TimerManager:Init()
    self.autoId = 0
    --注册所有内建定时器
    for k,v in ipairs(AllInterTimers) do
        local interval = TimerTypes[v]
        self:AddTimer(function(dt)
            TableUtils:RemoveAll(InternalTimers[v], function(timer)
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
function TimerManager:GenTimerId()
    self.autoId = self.autoId + 1
    return self.autoId
end

--注册内建定时器
function TimerManager:AddInternalTimer(callback,type,repeatCount)
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
function TimerManager:RemoveInternalTimer(id)
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
function TimerManager:AddTimer(callback, interval, repeatCount, duration, delay, watchObj)
    if not interval then
        Log:Error("TimerManager:AddTimer failed, interval is nil")
        return
    end
    local timerId = self:GenTimerId()
    if self.updating then
        table.insert(self.addTimerList, {timerId, callback, interval, repeatCount, duration, delay, watchObj})
        return timerId
    end

    TimerManager.timers[timerId] = {
        callback = callback,
        interval = interval,
        repeatCount = repeatCount or 0,
        elapsedTime = 0,
        time = 0,
        count = 0,
        duration = duration or 0,
        delay = delay or 0,
        watchObj = watchObj
    }
    return timerId
end

--延迟执行
function TimerManager:DelayCall(func,delayTime)
    return TimerManager:AddTimer(function()
        func()
    end, delayTime, 1)
end

--移除定时器
function TimerManager:RemoveTimer(timerId)
    if self.updating then
        table.insert(self.removeTimerList, timerId)
        return
    end
    if TimerManager.timers[timerId] == nil then
        return
    end
    TimerManager.timers[timerId] = nil
end

--更新
function TimerManager:Update(dt)
    self:SetUpdating(true)
    local needCallbacks = {}
    local removeTimers = {}
    for k,v in pairs(TimerManager.timers) do
        if v.delay > 0 then
            v.delay = v.delay - dt
            if v.delay <= 0 then
                dt = dt + v.delay
                v.delay = 0
            end
        end
        if v.delay <= 0 then
            if (v.watchObj and Class.IsExpired(v.watchObj)) then
                table.insert(removeTimers,k)
            else
                v.elapsedTime = v.elapsedTime + dt
                v.time = v.time + dt
                if v.time >= v.interval then

                    table.insert(needCallbacks,{callback = v.callback,time = v.time,watchObj = v.watchObj})
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
                    --     Log:Error("TimerManager error:%s", tostring(errmsg))
                    -- end
                end
                if v.duration > 0 and v.elapsedTime >= v.duration then
                    table.insert(removeTimers,k)
                end
            end
        end
    end

    for k,v in pairs(needCallbacks) do
        if v.watchObj and Class.IsExpired(v.watchObj) then
            table.insert(removeTimers,k)
        else
            local result = false
            local ok, errmsg = xpcall(function()
                result = v.callback(v.time)
            end,debug.traceback)
            if not ok then
                Log:Error("TimerManager error:%s", tostring(errmsg))
            end
            if result then
                table.insert(removeTimers,k)
            end
        end
    end

    for _,v in pairs(removeTimers) do
        TimerManager:RemoveTimer(v)
    end
    self:SetUpdating(false)
end

function TimerManager:IsUpdating()
    return self.updating
end

function TimerManager:SetUpdating(updating)
    self.updating = updating
    if not updating then
        for _,v in pairs(self.addTimerList) do
            TimerManager.timers[v[1]] = {
                callback = v[2],
                interval = v[3],
                repeatCount = v[4] or 0,
                elapsedTime = 0,
                time = 0,
                count = 0,
                duration = v[5] or 0,
                delay = v[6] or 0,
                watchObj = v[7]
            }
        end
        for _,v in pairs(self.removeTimerList) do
            self:RemoveTimer(v)
        end
        self.addTimerList = {}
        self.removeTimerList = {}

    end
end

return TimerManager