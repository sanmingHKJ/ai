--[[
    ModuleManager - Plugin system for SGF modules
    
    Features:
    - Module registration and loading
    - Dependency resolution and injection
    - Lifecycle management (init, start, stop, cleanup)
    - Module discovery and hot-reloading
    - Error handling and recovery
]]

local ModuleManager = {}
ModuleManager.__index = ModuleManager

-- Module states
ModuleManager.ModuleState = {
    UNLOADED = "unloaded",
    LOADING = "loading", 
    LOADED = "loaded",
    STARTING = "starting",
    RUNNING = "running",
    STOPPING = "stopping",
    STOPPED = "stopped",
    ERROR = "error"
}

--[[
    Create a new ModuleManager instance
    @param sgf (table) StudioGameFramework instance
    @return ModuleManager instance
]]
function ModuleManager.new(sgf)
    local self = setmetatable({}, ModuleManager)
    
    self.sgf = sgf
    
    -- Registered module factories
    self.factories = {}
    
    -- Loaded module instances
    self.modules = {}
    
    -- Module configurations
    self.configs = {}
    
    -- Dependency graph
    self.dependencies = {}
    
    -- Module search paths
    self.searchPaths = {
        script.Parent.Parent.modules, -- Default modules directory
    }
    
    -- Auto-discovery of modules
    self:discoverModules()
    
    return self
end

--[[
    Register a module factory
    @param name (string) Module name
    @param moduleFactory (function|table) Module factory function or module class
]]
function ModuleManager:register(name, moduleFactory)
    if type(name) ~= "string" or name == "" then
        error("Module name must be a non-empty string")
    end
    
    if type(moduleFactory) ~= "function" and type(moduleFactory) ~= "table" then
        error("Module factory must be a function or table")
    end
    
    self.factories[name] = moduleFactory
    
    if self.sgf.log then
        self.sgf.log:debug("Module factory registered", {name = name})
    end
end

--[[
    Unregister a module factory
    @param name (string) Module name
    @return (boolean) True if module was unregistered
]]
function ModuleManager:unregister(name)
    if self.factories[name] then
        self.factories[name] = nil
        
        if self.sgf.log then
            self.sgf.log:debug("Module factory unregistered", {name = name})
        end
        
        return true
    end
    return false
end

--[[
    Load a module
    @param name (string) Module name
    @param config (table) Module configuration
    @return (table) Module instance
]]
function ModuleManager:load(name, config)
    if type(name) ~= "string" or name == "" then
        error("Module name must be a non-empty string")
    end
    
    -- Check if already loaded
    if self.modules[name] then
        if self.sgf.log then
            self.sgf.log:warning("Module already loaded", {name = name})
        end
        return self.modules[name]
    end
    
    -- Get module factory
    local factory = self.factories[name]
    if not factory then
        error("Module not found: " .. name)
    end
    
    config = config or {}
    self.configs[name] = config
    
    -- Set module state
    self:setModuleState(name, ModuleManager.ModuleState.LOADING)
    
    local success, result = pcall(function()
        -- Create module instance
        local module
        if type(factory) == "function" then
            module = factory()
        else
            module = factory
        end
        
        -- Validate module interface
        if not self:validateModule(module) then
            error("Module does not implement required interface: " .. name)
        end
        
        -- Store module
        self.modules[name] = module
        module.name = name
        module.state = ModuleManager.ModuleState.LOADED
        
        -- Resolve dependencies
        self:resolveDependencies(name, module)
        
        -- Initialize module
        if module.init then
            local initSuccess, initError = pcall(module.init, module, self.sgf, config)
            if not initSuccess then
                self:setModuleState(name, ModuleManager.ModuleState.ERROR)
                error("Module initialization failed: " .. name .. " - " .. tostring(initError))
            end
        end
        
        self:setModuleState(name, ModuleManager.ModuleState.LOADED)
        
        if self.sgf.log then
            self.sgf.log:info("Module loaded", {name = name})
        end
        
        -- Emit module loaded event
        if self.sgf.events then
            self.sgf.events:emit("ModuleLoaded", {name = name, module = module})
        end
        
        return module
    end)
    
    if not success then
        self:setModuleState(name, ModuleManager.ModuleState.ERROR)
        self.modules[name] = nil
        
        if self.sgf.log then
            self.sgf.log:error("Module loading failed", {name = name, error = result})
        end
        
        error("Failed to load module: " .. name .. " - " .. tostring(result))
    end
    
    return result
end

--[[
    Unload a module
    @param name (string) Module name
    @return (boolean) True if module was unloaded
]]
function ModuleManager:unload(name)
    local module = self.modules[name]
    if not module then
        return false
    end
    
    -- Stop module if running
    if module.state == ModuleManager.ModuleState.RUNNING then
        self:stop(name)
    end
    
    self:setModuleState(name, ModuleManager.ModuleState.UNLOADING)
    
    -- Cleanup module
    if module.cleanup then
        local success, error = pcall(module.cleanup, module)
        if not success and self.sgf.log then
            self.sgf.log:error("Module cleanup failed", {name = name, error = error})
        end
    end
    
    -- Remove module
    self.modules[name] = nil
    self.configs[name] = nil
    
    if self.sgf.log then
        self.sgf.log:info("Module unloaded", {name = name})
    end
    
    -- Emit module unloaded event
    if self.sgf.events then
        self.sgf.events:emit("ModuleUnloaded", {name = name})
    end
    
    return true
end

--[[
    Reload a module
    @param name (string) Module name
    @return (table) New module instance
]]
function ModuleManager:reload(name)
    local config = self.configs[name]
    self:unload(name)
    return self:load(name, config)
end

--[[
    Start a module
    @param name (string) Module name
    @return (boolean) True if module was started
]]
function ModuleManager:start(name)
    local module = self.modules[name]
    if not module then
        error("Module not loaded: " .. name)
    end
    
    if module.state == ModuleManager.ModuleState.RUNNING then
        return true -- Already running
    end
    
    self:setModuleState(name, ModuleManager.ModuleState.STARTING)
    
    -- Start module
    if module.start then
        local success, error = pcall(module.start, module)
        if not success then
            self:setModuleState(name, ModuleManager.ModuleState.ERROR)
            if self.sgf.log then
                self.sgf.log:error("Module start failed", {name = name, error = error})
            end
            return false
        end
    end
    
    self:setModuleState(name, ModuleManager.ModuleState.RUNNING)
    
    if self.sgf.log then
        self.sgf.log:info("Module started", {name = name})
    end
    
    -- Emit module started event
    if self.sgf.events then
        self.sgf.events:emit("ModuleStarted", {name = name, module = module})
    end
    
    return true
end

--[[
    Stop a module
    @param name (string) Module name
    @return (boolean) True if module was stopped
]]
function ModuleManager:stop(name)
    local module = self.modules[name]
    if not module then
        return false
    end
    
    if module.state ~= ModuleManager.ModuleState.RUNNING then
        return true -- Already stopped
    end
    
    self:setModuleState(name, ModuleManager.ModuleState.STOPPING)
    
    -- Stop module
    if module.stop then
        local success, error = pcall(module.stop, module)
        if not success and self.sgf.log then
            self.sgf.log:error("Module stop failed", {name = name, error = error})
        end
    end
    
    self:setModuleState(name, ModuleManager.ModuleState.STOPPED)
    
    if self.sgf.log then
        self.sgf.log:info("Module stopped", {name = name})
    end
    
    -- Emit module stopped event
    if self.sgf.events then
        self.sgf.events:emit("ModuleStopped", {name = name, module = module})
    end
    
    return true
end

--[[
    Start all loaded modules
]]
function ModuleManager:startAll()
    -- Sort modules by dependencies to ensure proper start order
    local sortedModules = self:topologicalSort()
    
    for _, name in ipairs(sortedModules) do
        if self.modules[name] then
            self:start(name)
        end
    end
    
    if self.sgf.log then
        self.sgf.log:info("All modules started", {count = #sortedModules})
    end
end

--[[
    Stop all running modules
]]
function ModuleManager:stopAll()
    -- Stop in reverse dependency order
    local sortedModules = self:topologicalSort()
    
    for i = #sortedModules, 1, -1 do
        local name = sortedModules[i]
        if self.modules[name] then
            self:stop(name)
        end
    end
    
    if self.sgf.log then
        self.sgf.log:info("All modules stopped")
    end
end

--[[
    Check if a module is loaded
    @param name (string) Module name
    @return (boolean) True if module is loaded
]]
function ModuleManager:isLoaded(name)
    return self.modules[name] ~= nil
end

--[[
    Get dependencies for a module
    @param name (string) Module name
    @return (table) Array of dependency names
]]
function ModuleManager:getDependencies(name)
    return self.dependencies[name] or {}
end

--[[
    Get dependents of a module
    @param name (string) Module name
    @return (table) Array of dependent module names
]]
function ModuleManager:getDependents(name)
    local dependents = {}
    
    for moduleName, deps in pairs(self.dependencies) do
        for _, dep in ipairs(deps) do
            if dep == name then
                table.insert(dependents, moduleName)
                break
            end
        end
    end
    
    return dependents
end

--[[
    Discover modules from search paths
]]
function ModuleManager:discoverModules()
    for _, searchPath in ipairs(self.searchPaths) do
        if searchPath then
            for _, child in ipairs(searchPath.Children) do
                if child:IsA("ModuleScript") then
                    local moduleName = child.Name
                    if not self.factories[moduleName] then
                        self:register(moduleName, function()
                            return require(child)
                        end)
                    end
                end
            end
        end
    end
end

--[[
    List all registered modules
    @return (table) Array of module names
]]
function ModuleManager:list()
    local modules = {}
    for name, _ in pairs(self.factories) do
        table.insert(modules, name)
    end
    return modules
end

--[[
    Validate that a module implements the required interface
    @param module (table) Module to validate
    @return (boolean) True if valid
]]
function ModuleManager:validateModule(module)
    if type(module) ~= "table" then
        return false
    end
    
    -- Check for required properties
    -- (All methods are optional in our flexible design)
    return true
end

--[[
    Resolve dependencies for a module
    @param name (string) Module name
    @param module (table) Module instance
]]
function ModuleManager:resolveDependencies(name, module)
    if module.dependencies then
        self.dependencies[name] = module.dependencies
        
        -- Load dependencies if not already loaded
        for _, depName in ipairs(module.dependencies) do
            if not self:isLoaded(depName) then
                self:load(depName)
            end
        end
    end
end

--[[
    Set module state
    @param name (string) Module name
    @param state (string) New state
]]
function ModuleManager:setModuleState(name, state)
    local module = self.modules[name]
    if module then
        module.state = state
    end
end

--[[
    Topological sort of modules by dependencies
    @return (table) Array of module names in dependency order
]]
function ModuleManager:topologicalSort()
    local sorted = {}
    local visited = {}
    local visiting = {}
    
    local function visit(name)
        if visiting[name] then
            error("Circular dependency detected involving: " .. name)
        end
        
        if not visited[name] then
            visiting[name] = true
            
            local deps = self:getDependencies(name)
            for _, dep in ipairs(deps) do
                visit(dep)
            end
            
            visiting[name] = false
            visited[name] = true
            table.insert(sorted, name)
        end
    end
    
    for name, _ in pairs(self.modules) do
        if not visited[name] then
            visit(name)
        end
    end
    
    return sorted
end

--[[
    Get module statistics
    @return (table) Module statistics
]]
function ModuleManager:getStats()
    local stats = {
        registered = 0,
        loaded = 0,
        running = 0,
        stopped = 0,
        error = 0
    }
    
    for _, _ in pairs(self.factories) do
        stats.registered = stats.registered + 1
    end
    
    for _, module in pairs(self.modules) do
        stats.loaded = stats.loaded + 1
        
        if module.state == ModuleManager.ModuleState.RUNNING then
            stats.running = stats.running + 1
        elseif module.state == ModuleManager.ModuleState.STOPPED then
            stats.stopped = stats.stopped + 1
        elseif module.state == ModuleManager.ModuleState.ERROR then
            stats.error = stats.error + 1
        end
    end
    
    return stats
end

return ModuleManager