--[[
    EventBus - High-performance event system for SGF
    
    Features:
    - Type-safe event registration and emission
    - Async and sync event processing
    - Wildcard event listeners
    - Event batching for performance
    - Memory-efficient handler management
]]

local EventBus = {}
EventBus.__index = EventBus

--[[
    Create a new EventBus instance
    @return EventBus instance
]]
function EventBus.new()
    local self = setmetatable({}, EventBus)
    
    -- Event handlers: eventType -> array of handlers
    self.handlers = {}
    
    -- One-time handlers: eventType -> array of handlers
    self.onceHandlers = {}
    
    -- Wildcard handlers: pattern -> array of handlers
    self.wildcards = {}
    
    -- Event queue for async processing
    self.eventQueue = {}
    self.isProcessing = false
    
    -- Performance stats
    self.stats = {
        eventsEmitted = 0,
        handlersExecuted = 0,
        errors = 0,
        averageProcessingTime = 0
    }
    
    -- Handler ID counter
    self.nextHandlerId = 1
    
    return self
end

--[[
    Register an event handler
    @param eventType (string) Event type to listen for
    @param handler (function) Handler function
    @param options (table) Options: {context, priority, pattern}
    @return (number) Handler ID for removal
]]
function EventBus:on(eventType, handler, options)
    -- Validate parameters
    if type(eventType) ~= "string" or eventType == "" then
        error("Event type must be a non-empty string")
    end
    
    if type(handler) ~= "function" then
        error("Handler must be a function")
    end
    
    options = options or {}
    
    -- Create handler entry
    local handlerEntry = {
        id = self.nextHandlerId,
        handler = handler,
        context = options.context,
        priority = options.priority or 0,
        pattern = options.pattern
    }
    
    self.nextHandlerId = self.nextHandlerId + 1
    
    -- Store handler
    if options.pattern then
        -- Wildcard handler
        if not self.wildcards[eventType] then
            self.wildcards[eventType] = {}
        end
        table.insert(self.wildcards[eventType], handlerEntry)
        -- Sort by priority
        table.sort(self.wildcards[eventType], function(a, b) return a.priority > b.priority end)
    else
        -- Regular handler
        if not self.handlers[eventType] then
            self.handlers[eventType] = {}
        end
        table.insert(self.handlers[eventType], handlerEntry)
        -- Sort by priority
        table.sort(self.handlers[eventType], function(a, b) return a.priority > b.priority end)
    end
    
    return handlerEntry.id
end

--[[
    Register a one-time event handler
    @param eventType (string) Event type to listen for
    @param handler (function) Handler function
    @param options (table) Options: {context, priority}
    @return (number) Handler ID for removal
]]
function EventBus:once(eventType, handler, options)
    if type(eventType) ~= "string" or eventType == "" then
        error("Event type must be a non-empty string")
    end
    
    if type(handler) ~= "function" then
        error("Handler must be a function")
    end
    
    options = options or {}
    
    -- Create one-time handler
    local handlerEntry = {
        id = self.nextHandlerId,
        handler = handler,
        context = options.context,
        priority = options.priority or 0
    }
    
    self.nextHandlerId = self.nextHandlerId + 1
    
    -- Store in once handlers
    if not self.onceHandlers[eventType] then
        self.onceHandlers[eventType] = {}
    end
    table.insert(self.onceHandlers[eventType], handlerEntry)
    table.sort(self.onceHandlers[eventType], function(a, b) return a.priority > b.priority end)
    
    return handlerEntry.id
end

--[[
    Remove an event handler
    @param eventType (string) Event type
    @param handlerId (number) Handler ID returned by on() or once()
    @return (boolean) True if handler was removed
]]
function EventBus:off(eventType, handlerId)
    if type(eventType) ~= "string" then
        return false
    end
    
    -- Remove from regular handlers
    if self.handlers[eventType] then
        for i, handler in ipairs(self.handlers[eventType]) do
            if handler.id == handlerId then
                table.remove(self.handlers[eventType], i)
                return true
            end
        end
    end
    
    -- Remove from once handlers
    if self.onceHandlers[eventType] then
        for i, handler in ipairs(self.onceHandlers[eventType]) do
            if handler.id == handlerId then
                table.remove(self.onceHandlers[eventType], i)
                return true
            end
        end
    end
    
    -- Remove from wildcard handlers
    if self.wildcards[eventType] then
        for i, handler in ipairs(self.wildcards[eventType]) do
            if handler.id == handlerId then
                table.remove(self.wildcards[eventType], i)
                return true
            end
        end
    end
    
    return false
end

--[[
    Emit an event synchronously
    @param eventType (string) Event type
    @param data (any) Event data
    @param options (table) Options: {immediate, batch}
    @return (boolean) True if at least one handler was called
]]
function EventBus:emit(eventType, data, options)
    if type(eventType) ~= "string" then
        return false
    end
    
    options = options or {}
    
    local event = {
        type = eventType,
        data = data,
        timestamp = os.time(),
        immediate = options.immediate ~= false
    }
    
    if options.batch and not options.immediate then
        -- Add to queue for batch processing
        table.insert(self.eventQueue, event)
        return true
    else
        -- Process immediately
        return self:processEvent(event)
    end
end

--[[
    Emit an event asynchronously
    @param eventType (string) Event type  
    @param data (any) Event data
    @param options (table) Options
]]
function EventBus:emitAsync(eventType, data, options)
    options = options or {}
    options.immediate = false
    
    local event = {
        type = eventType,
        data = data,
        timestamp = os.time(),
        immediate = false
    }
    
    table.insert(self.eventQueue, event)
end

--[[
    Process a single event
    @param event (table) Event object
    @return (boolean) True if handlers were called
]]
function EventBus:processEvent(event)
    local startTime = os.time()
    local handlersExecuted = 0
    local hasHandlers = false
    
    -- Process regular handlers
    local regularHandlers = self.handlers[event.type]
    if regularHandlers and #regularHandlers > 0 then
        hasHandlers = true
        for _, handler in ipairs(regularHandlers) do
            local success, result = self:executeHandler(handler, event)
            if success then
                handlersExecuted = handlersExecuted + 1
            end
        end
    end
    
    -- Process one-time handlers
    local onceHandlers = self.onceHandlers[event.type]
    if onceHandlers and #onceHandlers > 0 then
        hasHandlers = true
        for _, handler in ipairs(onceHandlers) do
            local success, result = self:executeHandler(handler, event)
            if success then
                handlersExecuted = handlersExecuted + 1
            end
        end
        -- Clear once handlers after execution
        self.onceHandlers[event.type] = {}
    end
    
    -- Process wildcard handlers
    for pattern, handlers in pairs(self.wildcards) do
        if self:matchesPattern(event.type, pattern) then
            hasHandlers = true
            for _, handler in ipairs(handlers) do
                local success, result = self:executeHandler(handler, event)
                if success then
                    handlersExecuted = handlersExecuted + 1
                end
            end
        end
    end
    
    -- Update stats
    self.stats.eventsEmitted = self.stats.eventsEmitted + 1
    self.stats.handlersExecuted = self.stats.handlersExecuted + handlersExecuted
    
    local processingTime = os.time() - startTime
    self.stats.averageProcessingTime = (self.stats.averageProcessingTime + processingTime) / 2
    
    return hasHandlers
end

--[[
    Execute a handler safely
    @param handler (table) Handler entry
    @param event (table) Event object
    @return (boolean, any) Success, result
]]
function EventBus:executeHandler(handler, event)
    local success, result = pcall(function()
        if handler.context then
            return handler.handler(handler.context, event.data, event.type)
        else
            return handler.handler(event.data, event.type)
        end
    end)
    
    if not success then
        self.stats.errors = self.stats.errors + 1
        -- Log error without causing recursion
        print("EventBus error in handler:", result)
    end
    
    return success, result
end

--[[
    Check if event type matches a wildcard pattern
    @param eventType (string) Event type
    @param pattern (string) Pattern to match
    @return (boolean) True if matches
]]
function EventBus:matchesPattern(eventType, pattern)
    -- Simple wildcard matching (supports * at end)
    if pattern:sub(-1) == "*" then
        local prefix = pattern:sub(1, -2)
        return eventType:sub(1, #prefix) == prefix
    else
        return eventType == pattern
    end
end

--[[
    Process queued events
    @param maxEvents (number) Maximum events to process (optional)
]]
function EventBus:processQueue(maxEvents)
    if self.isProcessing then
        return
    end
    
    self.isProcessing = true
    maxEvents = maxEvents or #self.eventQueue
    
    local processed = 0
    while #self.eventQueue > 0 and processed < maxEvents do
        local event = table.remove(self.eventQueue, 1)
        self:processEvent(event)
        processed = processed + 1
    end
    
    self.isProcessing = false
end

--[[
    Clear all handlers for an event type
    @param eventType (string) Event type (optional, clears all if nil)
]]
function EventBus:clear(eventType)
    if eventType then
        self.handlers[eventType] = {}
        self.onceHandlers[eventType] = {}
        self.wildcards[eventType] = {}
    else
        self.handlers = {}
        self.onceHandlers = {}
        self.wildcards = {}
        self.eventQueue = {}
    end
end

--[[
    List all registered events
    @return (table) Array of event types
]]
function EventBus:listEvents()
    local events = {}
    
    for eventType, _ in pairs(self.handlers) do
        table.insert(events, eventType)
    end
    
    for eventType, _ in pairs(self.onceHandlers) do
        if not events[eventType] then
            table.insert(events, eventType)
        end
    end
    
    for pattern, _ in pairs(self.wildcards) do
        table.insert(events, pattern .. " (wildcard)")
    end
    
    return events
end

--[[
    List handlers for a specific event
    @param eventType (string) Event type
    @return (table) Handler information
]]
function EventBus:listHandlers(eventType)
    local result = {
        regular = {},
        once = {},
        wildcards = {}
    }
    
    if self.handlers[eventType] then
        for _, handler in ipairs(self.handlers[eventType]) do
            table.insert(result.regular, {
                id = handler.id,
                priority = handler.priority,
                hasContext = handler.context ~= nil
            })
        end
    end
    
    if self.onceHandlers[eventType] then
        for _, handler in ipairs(self.onceHandlers[eventType]) do
            table.insert(result.once, {
                id = handler.id,
                priority = handler.priority,
                hasContext = handler.context ~= nil
            })
        end
    end
    
    -- Check wildcard matches
    for pattern, handlers in pairs(self.wildcards) do
        if self:matchesPattern(eventType, pattern) then
            for _, handler in ipairs(handlers) do
                table.insert(result.wildcards, {
                    id = handler.id,
                    pattern = pattern,
                    priority = handler.priority,
                    hasContext = handler.context ~= nil
                })
            end
        end
    end
    
    return result
end

--[[
    Get performance statistics
    @return (table) Performance stats
]]
function EventBus:getStats()
    return {
        eventsEmitted = self.stats.eventsEmitted,
        handlersExecuted = self.stats.handlersExecuted,
        errors = self.stats.errors,
        averageProcessingTime = self.stats.averageProcessingTime,
        queuedEvents = #self.eventQueue,
        totalHandlers = self:getTotalHandlerCount()
    }
end

--[[
    Get total number of registered handlers
    @return (number) Total handler count
]]
function EventBus:getTotalHandlerCount()
    local count = 0
    
    for _, handlers in pairs(self.handlers) do
        count = count + #handlers
    end
    
    for _, handlers in pairs(self.onceHandlers) do
        count = count + #handlers
    end
    
    for _, handlers in pairs(self.wildcards) do
        count = count + #handlers
    end
    
    return count
end

return EventBus