--[[
    ServiceContainer - Dependency injection container for SGF
    
    Features:
    - Service registration and resolution
    - Singleton and factory patterns
    - Lazy initialization
    - Dependency injection
    - Service lifecycle management
    - Circular dependency detection
]]

local ServiceContainer = {}
ServiceContainer.__index = ServiceContainer

--[[
    Create a new ServiceContainer instance
    @return ServiceContainer instance
]]
function ServiceContainer.new()
    local self = setmetatable({}, ServiceContainer)
    
    -- Service factories
    self.factories = {}
    
    -- Service instances (for singletons)
    self.instances = {}
    
    -- Service configuration
    self.configs = {}
    
    -- Service dependencies
    self.dependencies = {}
    
    -- Resolution stack (for circular dependency detection)
    self.resolutionStack = {}
    
    return self
end

--[[
    Register a service
    @param name (string) Service name
    @param factory (function) Service factory function
    @param options (table) Options: {singleton, lazy, dependencies}
    @return (boolean) True if registered successfully
]]
function ServiceContainer:register(name, factory, options)
    if type(name) ~= "string" or name == "" then
        error("Service name must be a non-empty string")
    end
    
    if type(factory) ~= "function" then
        error("Service factory must be a function")
    end
    
    options = options or {}
    
    -- Store factory and configuration
    self.factories[name] = factory
    self.configs[name] = {
        singleton = options.singleton ~= false, -- Default to singleton
        lazy = options.lazy ~= false,           -- Default to lazy
        dependencies = options.dependencies or {}
    }
    
    -- Store dependencies
    self.dependencies[name] = options.dependencies or {}
    
    return true
end

--[[
    Unregister a service
    @param name (string) Service name
    @return (boolean) True if unregistered successfully
]]
function ServiceContainer:unregister(name)
    if not self.factories[name] then
        return false
    end
    
    -- Clean up
    self.factories[name] = nil
    self.configs[name] = nil
    self.dependencies[name] = nil
    self.instances[name] = nil
    
    return true
end

--[[
    Get a service instance
    @param name (string) Service name
    @return Service instance
]]
function ServiceContainer:get(name)
    if type(name) ~= "string" or name == "" then
        error("Service name must be a non-empty string")
    end
    
    -- Check for circular dependency
    if self:isInResolutionStack(name) then
        local stackStr = table.concat(self.resolutionStack, " -> ") .. " -> " .. name
        error("Circular dependency detected: " .. stackStr)
    end
    
    -- Add to resolution stack
    table.insert(self.resolutionStack, name)
    
    local success, result = pcall(function()
        return self:resolveService(name)
    end)
    
    -- Remove from resolution stack
    table.remove(self.resolutionStack)
    
    if not success then
        error("Failed to resolve service '" .. name .. "': " .. tostring(result))
    end
    
    return result
end

--[[
    Check if a service is registered
    @param name (string) Service name
    @return (boolean) True if service is registered
]]
function ServiceContainer:has(name)
    return self.factories[name] ~= nil
end

--[[
    Resolve a service instance
    @param name (string) Service name
    @return Service instance
]]
function ServiceContainer:resolveService(name)
    local config = self.configs[name]
    if not config then
        error("Service not registered: " .. name)
    end
    
    -- Return existing instance if singleton
    if config.singleton and self.instances[name] then
        return self.instances[name]
    end
    
    -- Resolve dependencies first
    local dependencies = {}
    for _, depName in ipairs(self.dependencies[name]) do
        dependencies[depName] = self:get(depName)
    end
    
    -- Create instance
    local factory = self.factories[name]
    local instance = factory(self, dependencies)
    
    -- Store instance if singleton
    if config.singleton then
        self.instances[name] = instance
    end
    
    return instance
end

--[[
    Check if a service name is in the resolution stack
    @param name (string) Service name
    @return (boolean) True if in stack
]]
function ServiceContainer:isInResolutionStack(name)
    for _, stackName in ipairs(self.resolutionStack) do
        if stackName == name then
            return true
        end
    end
    return false
end

--[[
    Get all registered service names
    @return (table) Array of service names
]]
function ServiceContainer:getServiceNames()
    local names = {}
    for name, _ in pairs(self.factories) do
        table.insert(names, name)
    end
    return names
end

--[[
    Get service configuration
    @param name (string) Service name
    @return (table) Service configuration or nil
]]
function ServiceContainer:getServiceConfig(name)
    return self.configs[name]
end

--[[
    Get service dependencies
    @param name (string) Service name
    @return (table) Array of dependency names
]]
function ServiceContainer:getServiceDependencies(name)
    return self.dependencies[name] or {}
end

--[[
    Check if a service has been instantiated
    @param name (string) Service name
    @return (boolean) True if instance exists
]]
function ServiceContainer:isInstantiated(name)
    return self.instances[name] ~= nil
end

--[[
    Clear a service instance (for singletons)
    @param name (string) Service name
    @return (boolean) True if instance was cleared
]]
function ServiceContainer:clearInstance(name)
    if self.instances[name] then
        self.instances[name] = nil
        return true
    end
    return false
end

--[[
    Clear all service instances
]]
function ServiceContainer:clearAllInstances()
    self.instances = {}
end

--[[
    Get container statistics
    @return (table) Container statistics
]]
function ServiceContainer:getStats()
    local registeredCount = 0
    local instantiatedCount = 0
    local singletonCount = 0
    local factoryCount = 0
    
    for name, config in pairs(self.configs) do
        registeredCount = registeredCount + 1
        
        if config.singleton then
            singletonCount = singletonCount + 1
        else
            factoryCount = factoryCount + 1
        end
        
        if self.instances[name] then
            instantiatedCount = instantiatedCount + 1
        end
    end
    
    return {
        registeredServices = registeredCount,
        instantiatedServices = instantiatedCount,
        singletonServices = singletonCount,
        factoryServices = factoryCount,
        resolutionStackDepth = #self.resolutionStack
    }
end

--[[
    Validate the service container configuration
    @return (table) Validation result {valid = boolean, errors = {}}
]]
function ServiceContainer:validate()
    local result = {valid = true, errors = {}}
    
    -- Check for missing dependencies
    for serviceName, deps in pairs(self.dependencies) do
        for _, depName in ipairs(deps) do
            if not self:has(depName) then
                table.insert(result.errors, 
                    "Service '" .. serviceName .. "' depends on unregistered service '" .. depName .. "'")
                result.valid = false
            end
        end
    end
    
    -- Check for potential circular dependencies
    local visited = {}
    local visiting = {}
    
    local function checkCircular(name)
        if visiting[name] then
            table.insert(result.errors, "Potential circular dependency involving service: " .. name)
            result.valid = false
            return
        end
        
        if not visited[name] then
            visiting[name] = true
            
            local deps = self.dependencies[name] or {}
            for _, dep in ipairs(deps) do
                checkCircular(dep)
            end
            
            visiting[name] = false
            visited[name] = true
        end
    end
    
    for serviceName, _ in pairs(self.factories) do
        if not visited[serviceName] then
            checkCircular(serviceName)
        end
    end
    
    return result
end

--[[
    Get dependency graph
    @return (table) Dependency graph representation
]]
function ServiceContainer:getDependencyGraph()
    local graph = {}
    
    for serviceName, deps in pairs(self.dependencies) do
        graph[serviceName] = {
            dependencies = deps,
            dependents = {}
        }
    end
    
    -- Calculate dependents
    for serviceName, deps in pairs(self.dependencies) do
        for _, depName in ipairs(deps) do
            if graph[depName] then
                table.insert(graph[depName].dependents, serviceName)
            end
        end
    end
    
    return graph
end

--[[
    Get topological sort of services (dependency order)
    @return (table) Array of service names in dependency order
]]
function ServiceContainer:getTopologicalSort()
    local sorted = {}
    local visited = {}
    local visiting = {}
    
    local function visit(name)
        if visiting[name] then
            error("Circular dependency detected involving: " .. name)
        end
        
        if not visited[name] and self:has(name) then
            visiting[name] = true
            
            local deps = self.dependencies[name] or {}
            for _, dep in ipairs(deps) do
                visit(dep)
            end
            
            visiting[name] = false
            visited[name] = true
            table.insert(sorted, name)
        end
    end
    
    for serviceName, _ in pairs(self.factories) do
        if not visited[serviceName] then
            visit(serviceName)
        end
    end
    
    return sorted
end

--[[
    Create a child container that inherits from this container
    @return (ServiceContainer) Child container
]]
function ServiceContainer:createChild()
    local child = ServiceContainer.new()
    
    -- Set up inheritance - child can access parent services
    local childGet = child.get
    child.get = function(self, name)
        -- Try child first
        if child:has(name) then
            return childGet(child, name)
        end
        
        -- Fall back to parent
        return self:get(name)
    end
    
    local childHas = child.has
    child.has = function(self, name)
        return childHas(child, name) or self:has(name)
    end
    
    child.parent = self
    
    return child
end

--[[
    Debug: Print service information
    @param name (string) Service name (optional, prints all if nil)
]]
function ServiceContainer:debug(name)
    if name then
        local config = self.configs[name]
        local instance = self.instances[name]
        
        print("Service: " .. name)
        print("  Registered: " .. tostring(config ~= nil))
        print("  Singleton: " .. tostring(config and config.singleton))
        print("  Lazy: " .. tostring(config and config.lazy))
        print("  Instantiated: " .. tostring(instance ~= nil))
        print("  Dependencies: " .. table.concat(self.dependencies[name] or {}, ", "))
    else
        print("ServiceContainer Debug Info:")
        print("  Total Services: " .. #self:getServiceNames())
        print("  Instantiated: " .. #self.instances)
        
        for _, serviceName in ipairs(self:getServiceNames()) do
            self:debug(serviceName)
            print("")
        end
    end
end

return ServiceContainer