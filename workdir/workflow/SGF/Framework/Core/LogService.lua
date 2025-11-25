--[[
    LogService - Multi-level logging system for SGF
    
    Features:
    - Multiple log levels (DEBUG, INFO, WARNING, ERROR)
    - Configurable outputs (console, file, network)
    - Performance profiling
    - Context-aware logging
    - Log formatting and filtering
]]

local LogService = {}
LogService.__index = LogService

-- Log levels
LogService.LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4
}

-- Level names for output
LogService.LevelNames = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARNING",
    [4] = "ERROR"
}

-- ANSI color codes for console output
LogService.Colors = {
    DEBUG = "\27[36m",    -- Cyan
    INFO = "\27[32m",     -- Green
    WARNING = "\27[33m",  -- Yellow
    ERROR = "\27[31m",    -- Red
    RESET = "\27[0m"      -- Reset
}

--[[
    Create a new LogService instance
    @param sgf (table) StudioGameFramework instance
    @return LogService instance
]]
function LogService.new(sgf)
    local self = setmetatable({}, LogService)
    
    self.sgf = sgf
    self.currentLevel = LogService.LogLevel.DEBUG
    
    -- Output handlers
    self.outputs = {
        console = {enabled = true, handler = self.consoleOutput}
    }
    
    -- Log formatting
    self.formatters = {
        default = self.defaultFormatter
    }
    self.currentFormatter = "default"
    
    -- Performance profiling
    self.timers = {}
    self.profiles = {}
    
    -- Statistics
    self.stats = {
        messagesLogged = 0,
        errorCount = 0,
        warningCount = 0
    }
    
    return self
end

--[[
    Set the current log level
    @param level (string|number) Log level ("DEBUG", "INFO", etc. or number)
]]
function LogService:setLevel(level)
    if type(level) == "string" then
        for num, name in pairs(LogService.LevelNames) do
            if name == level:upper() then
                self.currentLevel = num
                return
            end
        end
        error("Invalid log level: " .. level)
    elseif type(level) == "number" then
        if level >= 1 and level <= 4 then
            self.currentLevel = level
        else
            error("Log level must be between 1 and 4")
        end
    else
        error("Log level must be string or number")
    end
end

--[[
    Add a log output handler
    @param name (string) Output name
    @param handler (function) Output handler function
    @param enabled (boolean) Whether output is enabled
]]
function LogService:addOutput(name, handler, enabled)
    if type(name) ~= "string" then
        error("Output name must be a string")
    end
    
    if type(handler) ~= "function" then
        error("Output handler must be a function")
    end
    
    self.outputs[name] = {
        enabled = enabled ~= false,
        handler = handler
    }
end

--[[
    Set the log formatter
    @param formatter (function) Formatter function
]]
function LogService:setFormatter(formatter)
    if type(formatter) == "function" then
        self.formatters.custom = formatter
        self.currentFormatter = "custom"
    elseif type(formatter) == "string" and self.formatters[formatter] then
        self.currentFormatter = formatter
    else
        error("Invalid formatter")
    end
end

--[[
    Log a debug message
    @param message (string) Log message
    @param data (any) Additional data (optional)
]]
function LogService:debug(message, data)
    self:log(LogService.LogLevel.DEBUG, message, data)
end

--[[
    Log an info message
    @param message (string) Log message
    @param data (any) Additional data (optional)
]]
function LogService:info(message, data)
    self:log(LogService.LogLevel.INFO, message, data)
end

--[[
    Log a warning message
    @param message (string) Log message
    @param data (any) Additional data (optional)
]]
function LogService:warning(message, data)
    self:log(LogService.LogLevel.WARNING, message, data)
    self.stats.warningCount = self.stats.warningCount + 1
end

--[[
    Log an error message
    @param message (string) Log message
    @param data (any) Additional data (optional)
]]
function LogService:error(message, data)
    self:log(LogService.LogLevel.ERROR, message, data)
    self.stats.errorCount = self.stats.errorCount + 1
end

--[[
    Log a message at the specified level
    @param level (number) Log level
    @param message (string) Log message
    @param data (any) Additional data (optional)
]]
function LogService:log(level, message, data)
    -- Check if we should log this level
    if level < self.currentLevel then
        return
    end
    
    -- Create log entry
    local logEntry = {
        level = level,
        levelName = LogService.LevelNames[level],
        message = message,
        data = data,
        timestamp = os.clock(),
        source = self:getSource(),
        threadId = coroutine.running() and tostring(coroutine.running()) or "main"
    }
    
    -- Format the message
    local formatter = self.formatters[self.currentFormatter]
    local formattedMessage = formatter(self, logEntry)
    
    -- Output to all enabled outputs
    for name, output in pairs(self.outputs) do
        if output.enabled then
            local success, error = pcall(output.handler, self, logEntry, formattedMessage)
            if not success then
                print("Error in log output '" .. name .. "':", error)
            end
        end
    end
    
    self.stats.messagesLogged = self.stats.messagesLogged + 1
    
    -- Emit log event
    if self.sgf and self.sgf.events and level ~= LogService.LogLevel.DEBUG then
        self.sgf.events:emit("LogMessage", logEntry)
    end
end

--[[
    Get the source of the log call
    @return (string) Source information
]]
function LogService:getSource()
    local info = debug.getinfo(4, "Sl")
    if info then
        local source = info.short_src or "unknown"
        local line = info.currentline or 0
        return source .. ":" .. line
    end
    return "unknown"
end

--[[
    Default log formatter
    @param logEntry (table) Log entry
    @return (string) Formatted message
]]
function LogService:defaultFormatter(logEntry)
    local timestamp = os.date("%H:%M:%S", logEntry.timestamp)
    local level = logEntry.levelName
    local message = logEntry.message
    
    local formatted = string.format("[%s] %s: %s", timestamp, level, message)
    
    -- Add data if present
    if logEntry.data then
        formatted = formatted .. " " .. self:serializeData(logEntry.data)
    end
    
    return formatted
end

--[[
    Serialize data for logging
    @param data (any) Data to serialize
    @return (string) Serialized data
]]
function LogService:serializeData(data)
    if type(data) == "table" then
        local parts = {}
        for k, v in pairs(data) do
            table.insert(parts, tostring(k) .. "=" .. tostring(v))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return tostring(data)
    end
end

--[[
    Console output handler
    @param logEntry (table) Log entry
    @param formattedMessage (string) Formatted message
]]
function LogService:consoleOutput(logEntry, formattedMessage)
    local color = LogService.Colors[logEntry.levelName] or ""
    local reset = LogService.Colors.RESET
    print(color .. formattedMessage .. reset)
end

--[[
    Start a performance timer
    @param name (string) Timer name
]]
function LogService:startTimer(name)
    if type(name) ~= "string" then
        error("Timer name must be a string")
    end
    
    self.timers[name] = os.clock()
end

--[[
    End a performance timer and log the duration
    @param name (string) Timer name
    @return (number) Duration in seconds
]]
function LogService:endTimer(name)
    if type(name) ~= "string" then
        error("Timer name must be a string")
    end
    
    local startTime = self.timers[name]
    if not startTime then
        self:warning("Timer not found", {name = name})
        return 0
    end
    
    local duration = os.clock() - startTime
    self.timers[name] = nil
    
    self:debug("Timer completed", {name = name, duration = duration})
    return duration
end

--[[
    Profile a function execution
    @param name (string) Profile name
    @param func (function) Function to profile
    @param ... Additional arguments to pass to function
    @return Results of function execution
]]
function LogService:profile(name, func, ...)
    if type(name) ~= "string" then
        error("Profile name must be a string")
    end
    
    if type(func) ~= "function" then
        error("Must provide a function to profile")
    end
    
    local startTime = os.clock()
    local results = {pcall(func, ...)}
    local duration = os.clock() - startTime
    
    -- Store profile data
    if not self.profiles[name] then
        self.profiles[name] = {
            totalCalls = 0,
            totalTime = 0,
            averageTime = 0,
            minTime = duration,
            maxTime = duration
        }
    end
    
    local profile = self.profiles[name]
    profile.totalCalls = profile.totalCalls + 1
    profile.totalTime = profile.totalTime + duration
    profile.averageTime = profile.totalTime / profile.totalCalls
    profile.minTime = math.min(profile.minTime, duration)
    profile.maxTime = math.max(profile.maxTime, duration)
    
    self:debug("Function profiled", {
        name = name,
        duration = duration,
        totalCalls = profile.totalCalls,
        averageTime = profile.averageTime
    })
    
    -- Return original results
    if results[1] then
        return unpack(results, 2)
    else
        error(results[2])
    end
end

--[[
    Get profiling statistics
    @param name (string) Profile name (optional, returns all if nil)
    @return (table) Profile statistics
]]
function LogService:getProfileStats(name)
    if name then
        return self.profiles[name]
    else
        return self.profiles
    end
end

--[[
    Get logging statistics
    @return (table) Logging statistics
]]
function LogService:getStats()
    return {
        messagesLogged = self.stats.messagesLogged,
        errorCount = self.stats.errorCount,
        warningCount = self.stats.warningCount,
        currentLevel = LogService.LevelNames[self.currentLevel],
        outputCount = self:getEnabledOutputCount(),
        activeTimers = self:getActiveTimerCount(),
        profileCount = self:getProfileCount()
    }
end

--[[
    Get number of enabled outputs
    @return (number) Enabled output count
]]
function LogService:getEnabledOutputCount()
    local count = 0
    for _, output in pairs(self.outputs) do
        if output.enabled then
            count = count + 1
        end
    end
    return count
end

--[[
    Get number of active timers
    @return (number) Active timer count
]]
function LogService:getActiveTimerCount()
    local count = 0
    for _ in pairs(self.timers) do
        count = count + 1
    end
    return count
end

--[[
    Get number of profiles
    @return (number) Profile count
]]
function LogService:getProfileCount()
    local count = 0
    for _ in pairs(self.profiles) do
        count = count + 1
    end
    return count
end

--[[
    Clear all profiling data
]]
function LogService:clearProfiles()
    self.profiles = {}
end

--[[
    Clear logging statistics
]]
function LogService:clearStats()
    self.stats = {
        messagesLogged = 0,
        errorCount = 0,
        warningCount = 0
    }
end

return LogService