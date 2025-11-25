--[[
    TimeUtils - Time and date utility functions for SGF
    
    Features:
    - Time and date utilities
    - Duration calculations
    - Timers and countdowns
    - Performance timing
    - Time zone utilities
]]

local RunService = game:GetService("RunService")
local TimeUtils = {}

-- Time constants
TimeUtils.SECOND = 1
TimeUtils.MINUTE = 60
TimeUtils.HOUR = 3600
TimeUtils.DAY = 86400
TimeUtils.WEEK = 604800
TimeUtils.MONTH = 2628000  -- Average month (30.4 days)
TimeUtils.YEAR = 31536000  -- 365 days

-- Timer management
TimeUtils.timers = {}
TimeUtils.autoId = 0
TimeUtils.updating = false
TimeUtils.addTimerList = {}
TimeUtils.removeTimerList = {}
TimeUtils.updateConnection = nil
TimeUtils.isRunning = false

-- 内建定时器类型
TimeUtils.Frame01 = 0  -- 0.1秒定时器
TimeUtils.Frame05 = 1  -- 0.5秒定时器
TimeUtils.Frame1 = 2   -- 1秒定时器
TimeUtils.Frame3 = 3   -- 3秒定时器
TimeUtils.Frame5 = 4   -- 5秒定时器
TimeUtils.Frame10 = 5  -- 10秒定时器
TimeUtils.Frame30 = 6  -- 30秒定时器
TimeUtils.Frame60 = 7  -- 60秒定时器

local AllInterTimers = {
    TimeUtils.Frame01,
    TimeUtils.Frame05,
    TimeUtils.Frame1,
    TimeUtils.Frame3,
    TimeUtils.Frame5,
    TimeUtils.Frame10,
    TimeUtils.Frame30,
    TimeUtils.Frame60,
}

local TimerTypes = {
    [TimeUtils.Frame01] = 0.1,
    [TimeUtils.Frame05] = 0.5,
    [TimeUtils.Frame1] = 1,
    [TimeUtils.Frame3] = 3,
    [TimeUtils.Frame5] = 5,
    [TimeUtils.Frame10] = 10,
    [TimeUtils.Frame30] = 30,
    [TimeUtils.Frame60] = 60,
}

local InternalTimers = {
    [TimeUtils.Frame01] = {},
    [TimeUtils.Frame05] = {},
    [TimeUtils.Frame1] = {},
    [TimeUtils.Frame3] = {},
    [TimeUtils.Frame5] = {},
    [TimeUtils.Frame10] = {},
    [TimeUtils.Frame30] = {},
    [TimeUtils.Frame60] = {},
}

-- Error logging function
local function logError(message, ...)
    local formatted = string.format(message, ...)
    print("[ERROR] TimeUtils: " .. formatted)
end

-- Remove all items from table matching predicate
local function removeAll(table, predicate)
    local i = 1
    while i <= #table do
        if predicate(table[i]) then
            table.remove(table, i)
        else
            i = i + 1
        end
    end
end

-- ===========================================
-- Basic Time Operations
-- ===========================================

--[[
    Get current timestamp in seconds
    @return (number) Current timestamp
]]
function TimeUtils.now()
    return os.time()
end

--[[
    Get high-precision time (for performance measurements)
    @return (number) High-precision timestamp
]]
function TimeUtils.preciseClock()
    return RunService:CurrentSteadyTimeStampMS() / 1000
end

--[[
    Convert seconds to milliseconds
    @param seconds (number) Time in seconds
    @return (number) Time in milliseconds
]]
function TimeUtils.toMilliseconds(seconds)
    return seconds * 1000
end

--[[
    Convert milliseconds to seconds
    @param milliseconds (number) Time in milliseconds
    @return (number) Time in seconds
]]
function TimeUtils.toSeconds(milliseconds)
    return milliseconds / 1000
end

-- ===========================================
-- Timer Management
-- ===========================================

--[[
    Generate a timer ID
    @return (number) Timer ID
]]
function TimeUtils.genTimerId()
    TimeUtils.autoId = TimeUtils.autoId + 1
    return TimeUtils.autoId
end

--[[
    Start the global timer system
]]
function TimeUtils.startTimerSystem()
    if TimeUtils.isRunning then
        return
    end
    
    TimeUtils.autoId = 0
    -- 注册所有内建定时器
    for k, v in ipairs(AllInterTimers) do
        local interval = TimerTypes[v]
        TimeUtils.addTimer(function(dt)
            removeAll(InternalTimers[v], function(timer)
                timer.callback(dt)
                timer.count = timer.count + 1
                if timer.repeatCount > 0 and timer.count >= timer.repeatCount then
                    return true
                end
                return false
            end)
        end, interval)
    end

    TimeUtils.updating = false
    TimeUtils.addTimerList = {}
    TimeUtils.removeTimerList = {}
    TimeUtils.isRunning = true
    TimeUtils.updateConnection = RunService.RenderStepped:Connect(function(dt)
        TimeUtils.updateAllTimers(dt)
    end)
end

--[[
    Stop the global timer system
]]
function TimeUtils.stopTimerSystem()
    if not TimeUtils.isRunning then
        return
    end
    
    TimeUtils.isRunning = false
    if TimeUtils.updateConnection then
        TimeUtils.updateConnection:Disconnect()
        TimeUtils.updateConnection = nil
    end
    
    -- Clear all active timers
    TimeUtils.timers = {}
    TimeUtils.addTimerList = {}
    TimeUtils.removeTimerList = {}
end

--[[
    Add a timer (similar to TimerManager:AddTimer)
    @param callback (function) Timer callback function
    @param interval (number) Timer interval in seconds
    @param repeatCount (number) Number of times to repeat (0 = infinite)
    @param duration (number) Maximum duration in seconds
    @param delay (number) Initial delay in seconds
    @return (number) Timer ID
]]
function TimeUtils.addTimer(callback, interval, repeatCount, duration, delay)
    if not interval then
        logError("addTimer failed, interval is nil")
        return
    end
    
    local timerId = TimeUtils.genTimerId()
    if TimeUtils.updating then
        table.insert(TimeUtils.addTimerList, {timerId, callback, interval, repeatCount, duration, delay})
        return timerId
    end

    TimeUtils.timers[timerId] = {
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

--[[
    Remove a timer
    @param timerId (number) Timer ID to remove
]]
function TimeUtils.removeTimer(timerId)
    if TimeUtils.updating then
        table.insert(TimeUtils.removeTimerList, timerId)
        return
    end
    if TimeUtils.timers[timerId] == nil then
        return
    end
    TimeUtils.timers[timerId] = nil
end

--[[
    Delay call (similar to TimerManager:DelayCall)
    @param func (function) Function to call
    @param delayTime (number) Delay time in seconds
    @return (number) Timer ID
]]
function TimeUtils.delayCall(func, delayTime)
    return TimeUtils.addTimer(function()
        func()
    end, delayTime, 1)
end

--[[
    Add internal timer (similar to TimerManager:AddInternalTimer)
    @param callback (function) Callback function
    @param type (number) Timer type
    @param repeatCount (number) Repeat count
    @return (number) Timer ID
]]
function TimeUtils.addInternalTimer(callback, type, repeatCount)
    if InternalTimers[type] == nil then
        InternalTimers[type] = {}
    end
    repeatCount = repeatCount or 0
    local timerId = TimeUtils.genTimerId()
    table.insert(InternalTimers[type], {
        id = timerId, 
        repeatCount = repeatCount,
        count = 0, 
        callback = callback
    })
    return timerId
end

--[[
    Remove internal timer
    @param id (number) Timer ID to remove
]]
function TimeUtils.removeInternalTimer(id)
    for i, v in ipairs(InternalTimers) do
        for j, k in ipairs(v) do
            if k.id == id then
                table.remove(v, j)
                return
            end
        end
    end
end

--[[
    Update all timers (similar to TimerManager:Update)
    @param dt (number) Delta time
]]
function TimeUtils.updateAllTimers(dt)
    TimeUtils.setUpdating(true)
    local needCallbacks = {}
    local removeTimers = {}
    
    for k, v in pairs(TimeUtils.timers) do
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
                table.insert(needCallbacks, {callback = v.callback, time = v.time})
                -- 取模
                v.time = v.time % v.interval
                v.count = v.count + 1
                if v.repeatCount > 0 and v.count >= v.repeatCount then
                    table.insert(removeTimers, k)
                end
            end
            
            if v.duration > 0 and v.elapsedTime >= v.duration then
                table.insert(removeTimers, k)
            end
        end
    end

    for k, v in pairs(needCallbacks) do
        local result = false
        local ok, errmsg = xpcall(function()
            result = v.callback(v.time)
        end, debug.traceback)
        if not ok then
            logError("TimeUtils error:%s", tostring(errmsg))
        end
        if result then
            table.insert(removeTimers, k)
        end
    end

    for _, v in pairs(removeTimers) do
        TimeUtils.removeTimer(v)
    end
    TimeUtils.setUpdating(false)
end

--[[
    Check if updating
    @return (boolean) True if updating
]]
function TimeUtils.isUpdating()
    return TimeUtils.updating
end

--[[
    Set updating state
    @param updating (boolean) Updating state
]]
function TimeUtils.setUpdating(updating)
    TimeUtils.updating = updating
    if not updating then
        for _, v in pairs(TimeUtils.addTimerList) do
            TimeUtils.timers[v[1]] = {
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
        for _, v in pairs(TimeUtils.removeTimerList) do
            TimeUtils.removeTimer(v)
        end
        TimeUtils.addTimerList = {}
        TimeUtils.removeTimerList = {}
    end
end

-- ===========================================
-- Duration Calculations
-- ===========================================

--[[
    Calculate elapsed time between two timestamps
    @param startTime (number) Start timestamp
    @param endTime (number) End timestamp (optional, defaults to now)
    @return (number) Elapsed time in seconds
]]
function TimeUtils.elapsed(startTime, endTime)
    endTime = endTime or TimeUtils.now()
    return endTime - startTime
end

--[[
    Convert seconds to human-readable duration
    @param seconds (number) Duration in seconds
    @param precision (number) Number of units to include (default: 2)
    @return (string) Human-readable duration
]]
function TimeUtils.formatDuration(seconds, precision)
    precision = precision or 2
    
    if seconds < 0 then
        return "0 seconds"
    end
    
    local units = {
        {TimeUtils.YEAR, "year", "years"},
        {TimeUtils.MONTH, "month", "months"},
        {TimeUtils.WEEK, "week", "weeks"},
        {TimeUtils.DAY, "day", "days"},
        {TimeUtils.HOUR, "hour", "hours"},
        {TimeUtils.MINUTE, "minute", "minutes"},
        {TimeUtils.SECOND, "second", "seconds"}
    }
    
    local result = {}
    local remaining = seconds
    
    for _, unit in ipairs(units) do
        local value = math.floor(remaining / unit[1])
        if value > 0 then
            local label = value == 1 and unit[2] or unit[3]
            table.insert(result, value .. " " .. label)
            remaining = remaining - (value * unit[1])
            
            if #result >= precision then
                break
            end
        end
    end
    
    return #result > 0 and table.concat(result, ", ") or "0 seconds"
end

--[[
    Convert seconds to compact duration format (HH:MM:SS)
    @param seconds (number) Duration in seconds
    @param includeHours (boolean) Whether to include hours (default: auto)
    @return (string) Compact duration format
]]
function TimeUtils.formatCompactDuration(seconds, includeHours)
    local hours = math.floor(seconds / TimeUtils.HOUR)
    local minutes = math.floor((seconds % TimeUtils.HOUR) / TimeUtils.MINUTE)
    local secs = seconds % TimeUtils.MINUTE
    
    if includeHours == nil then
        includeHours = hours > 0
    end
    
    if includeHours then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

--[[
    Parse compact duration format to seconds
    @param durationStr (string) Duration string (MM:SS or HH:MM:SS)
    @return (number) Duration in seconds
]]
function TimeUtils.parseCompactDuration(durationStr)
    local parts = {}
    for part in string.gmatch(durationStr, "%d+") do
        table.insert(parts, tonumber(part))
    end
    
    if #parts == 2 then
        -- MM:SS format
        return parts[1] * TimeUtils.MINUTE + parts[2]
    elseif #parts == 3 then
        -- HH:MM:SS format
        return parts[1] * TimeUtils.HOUR + parts[2] * TimeUtils.MINUTE + parts[3]
    else
        return 0
    end
end

-- ===========================================
-- Date and Time Formatting
-- ===========================================

--[[
    Format timestamp as date string
    @param timestamp (number) Timestamp (optional, defaults to now)
    @param format (string) Format string (optional, defaults to "%Y-%m-%d %H:%M:%S")
    @return (string) Formatted date string
]]
function TimeUtils.formatDate(timestamp, format)
    timestamp = timestamp or TimeUtils.now()
    format = format or "%Y-%m-%d %H:%M:%S"
    return os.date(format, timestamp)
end

--[[
    Format timestamp as relative time (e.g., "2 hours ago")
    @param timestamp (number) Timestamp
    @param now (number) Current time (optional)
    @return (string) Relative time string
]]
function TimeUtils.formatRelative(timestamp, now)
    now = now or TimeUtils.now()
    local diff = now - timestamp
    
    if diff < 0 then
        diff = -diff
        local future = TimeUtils.formatDuration(diff, 1)
        return "in " .. future
    end
    
    if diff < TimeUtils.MINUTE then
        return "just now"
    elseif diff < TimeUtils.HOUR then
        local minutes = math.floor(diff / TimeUtils.MINUTE)
        return minutes == 1 and "1 minute ago" or minutes .. " minutes ago"
    elseif diff < TimeUtils.DAY then
        local hours = math.floor(diff / TimeUtils.HOUR)
        return hours == 1 and "1 hour ago" or hours .. " hours ago"
    elseif diff < TimeUtils.WEEK then
        local days = math.floor(diff / TimeUtils.DAY)
        return days == 1 and "1 day ago" or days .. " days ago"
    elseif diff < TimeUtils.MONTH then
        local weeks = math.floor(diff / TimeUtils.WEEK)
        return weeks == 1 and "1 week ago" or weeks .. " weeks ago"
    elseif diff < TimeUtils.YEAR then
        local months = math.floor(diff / TimeUtils.MONTH)
        return months == 1 and "1 month ago" or months .. " months ago"
    else
        local years = math.floor(diff / TimeUtils.YEAR)
        return years == 1 and "1 year ago" or years .. " years ago"
    end
end

--[[
    Get day of week name
    @param timestamp (number) Timestamp (optional, defaults to now)
    @return (string) Day name
]]
function TimeUtils.getDayName(timestamp)
    timestamp = timestamp or TimeUtils.now()
    return os.date("%A", timestamp)
end

--[[
    Get month name
    @param timestamp (number) Timestamp (optional, defaults to now)
    @return (string) Month name
]]
function TimeUtils.getMonthName(timestamp)
    timestamp = timestamp or TimeUtils.now()
    return os.date("%B", timestamp)
end

--[[
    Check if timestamp is today
    @param timestamp (number) Timestamp to check
    @param now (number) Current time (optional)
    @return (boolean) True if timestamp is today
]]
function TimeUtils.isToday(timestamp, now)
    now = now or TimeUtils.now()
    local today = os.date("%Y-%m-%d", now)
    local date = os.date("%Y-%m-%d", timestamp)
    return today == date
end

--[[
    Check if timestamp is this week
    @param timestamp (number) Timestamp to check
    @param now (number) Current time (optional)
    @return (boolean) True if timestamp is this week
]]
function TimeUtils.isThisWeek(timestamp, now)
    now = now or TimeUtils.now()
    local diff = now - timestamp
    return math.abs(diff) < TimeUtils.WEEK
end

-- ===========================================
-- Timer Utilities
-- ===========================================

--[[
    Create a simple timer object
    @param duration (number) Timer duration in seconds
    @param onComplete (function) Callback when timer completes (optional)
    @param autoStart (boolean) Whether to automatically start the timer (default: true)
    @return (table) Timer object
]]
function TimeUtils.createTimer(duration, onComplete, autoStart)
    autoStart = autoStart ~= false -- Default to true
    
    local timer = {
        duration = duration,
        startTime = TimeUtils.now(),
        endTime = TimeUtils.now() + duration,
        onComplete = onComplete,
        completed = false,
        paused = false,
        pausedTime = 0,
        autoManaged = autoStart,
        timerId = nil,
        
        -- Get remaining time
        getRemaining = function(self)
            if self.completed or self.paused then
                return self.paused and (self.endTime - self.pausedTime) or 0
            end
            return math.max(0, self.endTime - TimeUtils.now())
        end,
        
        -- Get elapsed time
        getElapsed = function(self)
            if self.paused then
                return self.pausedTime - self.startTime
            end
            return TimeUtils.now() - self.startTime
        end,
        
        -- Get progress (0-1)
        getProgress = function(self)
            return math.min(1, self:getElapsed() / self.duration)
        end,
        
        -- Check if timer is finished
        isFinished = function(self)
            return self:getRemaining() <= 0
        end,
        
        -- Update timer (call each frame)
        update = function(self)
            if not self.completed and not self.paused and self:isFinished() then
                self.completed = true
                if self.onComplete then
                    self.onComplete(self)
                end
            end
        end,
        
        -- Reset timer
        reset = function(self, newDuration)
            self.duration = newDuration or self.duration
            self.startTime = TimeUtils.now()
            self.endTime = self.startTime + self.duration
            self.completed = false
            self.paused = false
            self.pausedTime = 0
        end,
        
        -- Pause timer
        pause = function(self)
            if not self.paused and not self.completed then
                self.paused = true
                self.pausedTime = TimeUtils.now()
            end
        end,
        
        -- Resume timer
        resume = function(self)
            if self.paused then
                local pauseDuration = TimeUtils.now() - self.pausedTime
                self.endTime = self.endTime + pauseDuration
                self.paused = false
                self.pausedTime = 0
            end
        end,
        
        -- Destroy timer (remove from auto management)
        destroy = function(self)
            self.autoManaged = false
            self.completed = true
            if self.timerId then
                TimeUtils.removeTimer(self.timerId)
                self.timerId = nil
            end
        end
    }
    
    -- Add to timer system if auto-managed
    if autoStart then
        timer.timerId = TimeUtils.addTimer(function()
            timer:update()
        end, 0.1, 0) -- Update every 0.1 seconds
    end
    
    return timer
end

--[[
    Create a countdown timer
    @param duration (number) Countdown duration in seconds
    @param onTick (function) Callback called each second (optional)
    @param onComplete (function) Callback when countdown finishes (optional)
    @param autoStart (boolean) Whether to automatically start the timer (default: true)
    @return (table) Countdown timer object
]]
function TimeUtils.createCountdown(duration, onTick, onComplete, autoStart)
    local timer = TimeUtils.createTimer(duration, onComplete, autoStart)
    local lastSecond = math.ceil(timer:getRemaining())
    
    local originalUpdate = timer.update
    timer.update = function(self)
        originalUpdate(self)
        
        if not self.completed and not self.paused then
            local currentSecond = math.ceil(self:getRemaining())
            if currentSecond ~= lastSecond and onTick then
                onTick(currentSecond)
                lastSecond = currentSecond
            end
        end
    end
    
    return timer
end

-- ===========================================
-- Performance Timing
-- ===========================================

--[[
    Create a stopwatch for performance timing
    @return (table) Stopwatch object
]]
function TimeUtils.createStopwatch()
    return {
        startTime = 0,
        endTime = 0,
        running = false,
        totalTime = 0,
        lapTimes = {},
        
        -- Start the stopwatch
        start = function(self)
            if not self.running then
                self.startTime = TimeUtils.preciseClock()
                self.running = true
            end
        end,
        
        -- Stop the stopwatch
        stop = function(self)
            if self.running then
                self.endTime = TimeUtils.preciseClock()
                self.totalTime = self.totalTime + (self.endTime - self.startTime)
                self.running = false
            end
        end,
        
        -- Record a lap time
        lap = function(self)
            if self.running then
                local lapTime = TimeUtils.preciseClock() - self.startTime
                table.insert(self.lapTimes, lapTime)
                return lapTime
            end
            return 0
        end,
        
        -- Get current elapsed time
        getElapsed = function(self)
            if self.running then
                return self.totalTime + (TimeUtils.preciseClock() - self.startTime)
            else
                return self.totalTime
            end
        end,
        
        -- Reset the stopwatch
        reset = function(self)
            self.startTime = 0
            self.endTime = 0
            self.totalTime = 0
            self.running = false
            self.lapTimes = {}
        end,
        
        -- Get formatted elapsed time
        getFormattedTime = function(self)
            return TimeUtils.formatCompactDuration(self:getElapsed())
        end
    }
end

--[[
    Measure execution time of a function
    @param func (function) Function to measure
    @param ... Additional arguments to pass to function
    @return (any, number) Function result and execution time in seconds
]]
function TimeUtils.measure(func, ...)
    local startTime = TimeUtils.preciseClock()
    local results = {func(...)}
    local elapsed = TimeUtils.preciseClock() - startTime
    return results[1], elapsed
end

--[[
    Create a performance profiler
    @return (table) Profiler object
]]
function TimeUtils.createProfiler()
    return {
        measurements = {},
        
        -- Start measuring a named operation
        start = function(self, name)
            self.measurements[name] = {
                startTime = TimeUtils.preciseClock(),
                totalTime = self.measurements[name] and self.measurements[name].totalTime or 0,
                callCount = self.measurements[name] and self.measurements[name].callCount or 0
            }
        end,
        
        -- End measuring a named operation
        finish = function(self, name)
            local measurement = self.measurements[name]
            if measurement and measurement.startTime then
                local elapsed = TimeUtils.preciseClock() - measurement.startTime
                measurement.totalTime = measurement.totalTime + elapsed
                measurement.callCount = measurement.callCount + 1
                measurement.averageTime = measurement.totalTime / measurement.callCount
                measurement.startTime = nil
            end
        end,
        
        -- Measure a function call
        measure = function(self, name, func, ...)
            self:start(name)
            local results = {func(...)}
            self:finish(name)
            return unpack(results)
        end,
        
        -- Get measurement results
        getResults = function(self)
            local results = {}
            for name, measurement in pairs(self.measurements) do
                if measurement.callCount > 0 then
                    results[name] = {
                        totalTime = measurement.totalTime,
                        callCount = measurement.callCount,
                        averageTime = measurement.averageTime,
                        formattedTotal = TimeUtils.formatDuration(measurement.totalTime, 3),
                        formattedAverage = string.format("%.3fms", measurement.averageTime * 1000)
                    }
                end
            end
            return results
        end,
        
        -- Reset all measurements
        reset = function(self)
            self.measurements = {}
        end,
        
        -- Print results to console
        report = function(self)
            local results = self:getResults()
            print("=== Performance Report ===")
            for name, data in pairs(results) do
                print(string.format("%s: %d calls, %s total, %s avg", 
                    name, data.callCount, data.formattedTotal, data.formattedAverage))
            end
        end
    }
end

-- ===========================================
-- Date/Time Parsing
-- ===========================================

--[[
    Parse ISO 8601 date string to timestamp
    @param dateStr (string) Date string (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)
    @return (number) Timestamp or nil if invalid
]]
function TimeUtils.parseISO8601(dateStr)
    local year, month, day, hour, min, sec = string.match(dateStr, "(%d+)-(%d+)-(%d+)%s*(%d*):?(%d*):?(%d*)")
    
    if not year or not month or not day then
        return nil
    end
    
    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour) or 0,
        min = tonumber(min) or 0,
        sec = tonumber(sec) or 0
    })
end

--[[
    Parse duration string to seconds (e.g., "1h 30m", "2d 3h 45m")
    @param durationStr (string) Duration string
    @return (number) Duration in seconds
]]
function TimeUtils.parseDuration(durationStr)
    local total = 0
    
    -- Years
    local years = string.match(durationStr, "(%d+)y")
    if years then
        total = total + (tonumber(years) * TimeUtils.YEAR)
    end
    
    -- Months
    local months = string.match(durationStr, "(%d+)mo")
    if months then
        total = total + (tonumber(months) * TimeUtils.MONTH)
    end
    
    -- Weeks
    local weeks = string.match(durationStr, "(%d+)w")
    if weeks then
        total = total + (tonumber(weeks) * TimeUtils.WEEK)
    end
    
    -- Days
    local days = string.match(durationStr, "(%d+)d")
    if days then
        total = total + (tonumber(days) * TimeUtils.DAY)
    end
    
    -- Hours
    local hours = string.match(durationStr, "(%d+)h")
    if hours then
        total = total + (tonumber(hours) * TimeUtils.HOUR)
    end
    
    -- Minutes
    local minutes = string.match(durationStr, "(%d+)m")
    if minutes then
        total = total + (tonumber(minutes) * TimeUtils.MINUTE)
    end
    
    -- Seconds
    local seconds = string.match(durationStr, "(%d+)s")
    if seconds then
        total = total + tonumber(seconds)
    end
    
    return total
end

-- ===========================================
-- Utility Functions
-- ===========================================

--[[
    Get start of day timestamp
    @param timestamp (number) Timestamp (optional, defaults to now)
    @return (number) Start of day timestamp
]]
function TimeUtils.getStartOfDay(timestamp)
    timestamp = timestamp or TimeUtils.now()
    local date = os.date("*t", timestamp)
    date.hour = 0
    date.min = 0
    date.sec = 0
    return os.time(date)
end

--[[
    Get end of day timestamp
    @param timestamp (number) Timestamp (optional, defaults to now)
    @return (number) End of day timestamp
]]
function TimeUtils.getEndOfDay(timestamp)
    timestamp = timestamp or TimeUtils.now()
    local date = os.date("*t", timestamp)
    date.hour = 23
    date.min = 59
    date.sec = 59
    return os.time(date)
end

--[[
    Sleep/wait function (yields in environments that support it)
    @param seconds (number) Seconds to wait
]]
function TimeUtils.wait(seconds)
    if wait then
        -- Studio environment
        wait(seconds)
    elseif coroutine then
        -- Generic Lua environment with coroutines
        coroutine.yield(seconds)
    else
        -- Fallback: busy wait (not recommended for production)
        local endTime = TimeUtils.preciseClock() + seconds
        while TimeUtils.preciseClock() < endTime do
            -- Busy wait
        end
    end
end

-- Auto-start the timer system when module loads
TimeUtils.startTimerSystem()

return TimeUtils