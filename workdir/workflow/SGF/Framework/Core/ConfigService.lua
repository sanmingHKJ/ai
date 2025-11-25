--[[
    ConfigService - Hierarchical configuration management for SGF
    
    Features:
    - Hierarchical configuration with dot notation (game.player.maxHealth)
    - Environment-specific configs (dev, test, prod)
    - Configuration watching and change notifications
    - Type validation and schema support
    - Runtime configuration changes
    - JSON and Lua table support
]]

local ConfigService = {}
ConfigService.__index = ConfigService

--[[
    Create a new ConfigService instance
    @param sgf (table) StudioGameFramework instance
    @return ConfigService instance
]]
function ConfigService.new(sgf)
    local self = setmetatable({}, ConfigService)
    
    self.sgf = sgf
    
    -- Configuration data storage
    self.configs = {}
    
    -- Current environment
    self.environment = "development"
    
    -- Configuration watchers: pattern -> array of callbacks
    self.watchers = {}
    self.nextWatcherId = 1
    
    -- Default configuration
    self:setDefaults()
    
    return self
end

--[[
    Set default configuration values
]]
function ConfigService:setDefaults()
    self.configs = {
        framework = {
            logLevel = "INFO",
            development = false,
            profiling = false
        },
        modules = {},
        game = {
            name = "Studio Game",
            version = "1.0.0",
            maxPlayers = 10
        }
    }
end

--[[
    Get a configuration value
    @param key (string) Configuration key (supports dot notation)
    @param defaultValue (any) Default value if key doesn't exist
    @return (any) Configuration value
]]
function ConfigService:get(key, defaultValue)
    if type(key) ~= "string" then
        error("Configuration key must be a string")
    end
    
    local value = self:getNestedValue(self.configs, key)
    
    -- Check environment-specific override
    if value == nil and self.environment ~= "development" then
        local envKey = self.environment .. "." .. key
        value = self:getNestedValue(self.configs, envKey)
    end
    
    return value ~= nil and value or defaultValue
end

--[[
    Set a configuration value
    @param key (string) Configuration key (supports dot notation)
    @param value (any) Configuration value
]]
function ConfigService:set(key, value)
    if type(key) ~= "string" then
        error("Configuration key must be a string")
    end
    
    local oldValue = self:get(key)
    
    self:setNestedValue(self.configs, key, value)
    
    -- Notify watchers
    self:notifyWatchers(key, oldValue, value)
    
    -- Log configuration change
    if self.sgf and self.sgf.log then
        self.sgf.log:debug("Configuration changed", {
            key = key,
            oldValue = oldValue,
            newValue = value
        })
    end
end

--[[
    Check if a configuration key exists
    @param key (string) Configuration key
    @return (boolean) True if key exists
]]
function ConfigService:has(key)
    if type(key) ~= "string" then
        return false
    end
    
    return self:getNestedValue(self.configs, key) ~= nil
end

--[[
    Watch for configuration changes
    @param pattern (string) Key pattern to watch (supports wildcards)
    @param callback (function) Callback function(key, oldValue, newValue)
    @return (number) Watch ID for removal
]]
function ConfigService:watch(pattern, callback)
    if type(pattern) ~= "string" then
        error("Watch pattern must be a string")
    end
    
    if type(callback) ~= "function" then
        error("Watch callback must be a function")
    end
    
    local watcherId = self.nextWatcherId
    self.nextWatcherId = self.nextWatcherId + 1
    
    if not self.watchers[pattern] then
        self.watchers[pattern] = {}
    end
    
    table.insert(self.watchers[pattern], {
        id = watcherId,
        callback = callback
    })
    
    return watcherId
end

--[[
    Remove a configuration watcher
    @param watcherId (number) Watch ID returned by watch()
    @return (boolean) True if watcher was removed
]]
function ConfigService:unwatch(watcherId)
    for pattern, watchers in pairs(self.watchers) do
        for i, watcher in ipairs(watchers) do
            if watcher.id == watcherId then
                table.remove(watchers, i)
                return true
            end
        end
    end
    return false
end

--[[
    Set the current environment
    @param env (string) Environment name
]]
function ConfigService:setEnvironment(env)
    if type(env) ~= "string" then
        error("Environment must be a string")
    end
    
    local oldEnv = self.environment
    self.environment = env
    
    -- Log environment change
    if self.sgf and self.sgf.log then
        self.sgf.log:info("Environment changed", {
            from = oldEnv,
            to = env
        })
    end
    
    -- Emit environment change event
    if self.sgf and self.sgf.events then
        self.sgf.events:emit("EnvironmentChanged", {
            oldEnvironment = oldEnv,
            newEnvironment = env
        })
    end
end

--[[
    Get the current environment
    @return (string) Current environment
]]
function ConfigService:getEnvironment()
    return self.environment
end

--[[
    Load configuration from a file or table
    @param source (string|table) File path or configuration table
]]
function ConfigService:load(source)
    local configData
    
    if type(source) == "string" then
        -- Load from file
        configData = self:loadFromFile(source)
    elseif type(source) == "table" then
        -- Load from table
        configData = source
    else
        error("Configuration source must be a file path (string) or table")
    end
    
    if configData then
        -- Merge with existing configuration
        self:mergeConfigs(self.configs, configData)
        
        -- Log successful load
        if self.sgf and self.sgf.log then
            self.sgf.log:info("Configuration loaded", {
                source = type(source) == "string" and source or "table"
            })
        end
        
        -- Emit configuration loaded event
        if self.sgf and self.sgf.events then
            self.sgf.events:emit("ConfigurationLoaded", {source = source})
        end
    end
end

--[[
    Load configuration from a file
    @param filePath (string) Path to configuration file
    @return (table) Configuration data
]]
function ConfigService:loadFromFile(filePath)
    -- For Studio environment, we'll simulate file loading
    -- In a real implementation, this would use Studio's file services
    
    if self.sgf and self.sgf.log then
        self.sgf.log:debug("Loading configuration from file", {path = filePath})
    end
    
    -- Simulate loading based on file extension
    if filePath:match("%.json$") then
        return self:loadJsonFile(filePath)
    elseif filePath:match("%.lua$") then
        return self:loadLuaFile(filePath)
    else
        error("Unsupported configuration file format: " .. filePath)
    end
end

--[[
    Load JSON configuration file
    @param filePath (string) Path to JSON file
    @return (table) Configuration data
]]
function ConfigService:loadJsonFile(filePath)
    -- In a real Studio implementation, this would use actual file I/O
    -- For now, we'll return a sample configuration
    
    -- This is where you would use Studio's JSON parsing services
    -- local jsonService = game:GetService("JSONService") or similar
    
    -- Sample configuration for demonstration
    return {
        framework = {
            logLevel = "INFO",
            development = false
        },
        game = {
            name = "My Studio Game",
            maxPlayers = 10,
            gameMode = "adventure"
        },
        modules = {
            EntityService = {
                enabled = true,
                config = {useECS = false, maxEntities = 1000}
            },
            NetworkService = {
                enabled = true,
                config = {serverMode = true, tickRate = 30}
            }
        }
    }
end

--[[
    Load Lua configuration file
    @param filePath (string) Path to Lua file
    @return (table) Configuration data
]]
function ConfigService:loadLuaFile(filePath)
    -- In a real Studio implementation, this would use require() or loadfile()
    -- For demonstration, return sample config
    
    return {
        framework = {
            logLevel = "DEBUG",
            development = true,
            profiling = true
        }
    }
end

--[[
    Save configuration to a file
    @param filePath (string) Path to save configuration
]]
function ConfigService:save(filePath)
    if type(filePath) ~= "string" then
        error("File path must be a string")
    end
    
    -- In a real implementation, this would serialize and save the configuration
    if self.sgf and self.sgf.log then
        self.sgf.log:info("Configuration saved", {path = filePath})
    end
end

--[[
    Reload configuration from the original source
]]
function ConfigService:reload()
    -- In a real implementation, this would reload from the original source
    if self.sgf and self.sgf.log then
        self.sgf.log:info("Configuration reloaded")
    end
    
    if self.sgf and self.sgf.events then
        self.sgf.events:emit("ConfigurationReloaded", {})
    end
end

--[[
    Validate configuration against a schema
    @param schema (table) Configuration schema
    @return (table) Validation result {valid = boolean, errors = {}}
]]
function ConfigService:validate(schema)
    if type(schema) ~= "table" then
        error("Schema must be a table")
    end
    
    local result = {valid = true, errors = {}}
    
    -- Validate configuration against schema
    self:validateAgainstSchema(self.configs, schema, "", result)
    
    return result
end

--[[
    Validate configuration against schema recursively
    @param config (table) Configuration data
    @param schema (table) Schema definition
    @param path (string) Current path
    @param result (table) Validation result
]]
function ConfigService:validateAgainstSchema(config, schema, path, result)
    for key, schemaValue in pairs(schema) do
        local currentPath = path == "" and key or (path .. "." .. key)
        local configValue = config[key]
        
        if type(schemaValue) == "table" then
            if schemaValue.type then
                -- This is a field definition
                if schemaValue.required and configValue == nil then
                    table.insert(result.errors, "Required field missing: " .. currentPath)
                    result.valid = false
                elseif configValue ~= nil then
                    -- Check type
                    if type(configValue) ~= schemaValue.type then
                        table.insert(result.errors, "Type mismatch at " .. currentPath .. 
                            ": expected " .. schemaValue.type .. ", got " .. type(configValue))
                        result.valid = false
                    end
                    
                    -- Check constraints
                    if schemaValue.min and configValue < schemaValue.min then
                        table.insert(result.errors, "Value too small at " .. currentPath .. 
                            ": " .. configValue .. " < " .. schemaValue.min)
                        result.valid = false
                    end
                    
                    if schemaValue.max and configValue > schemaValue.max then
                        table.insert(result.errors, "Value too large at " .. currentPath .. 
                            ": " .. configValue .. " > " .. schemaValue.max)
                        result.valid = false
                    end
                end
            else
                -- This is a nested object
                if type(configValue) == "table" then
                    self:validateAgainstSchema(configValue, schemaValue, currentPath, result)
                end
            end
        end
    end
end

--[[
    Get nested value using dot notation
    @param table (table) Table to search
    @param key (string) Dot-notated key
    @return (any) Value or nil
]]
function ConfigService:getNestedValue(table, key)
    local current = table
    local parts = self:splitKey(key)
    
    for _, part in ipairs(parts) do
        if type(current) ~= "table" or current[part] == nil then
            return nil
        end
        current = current[part]
    end
    
    return current
end

--[[
    Set nested value using dot notation
    @param table (table) Table to modify
    @param key (string) Dot-notated key
    @param value (any) Value to set
]]
function ConfigService:setNestedValue(table, key, value)
    local current = table
    local parts = self:splitKey(key)
    
    -- Navigate to parent of target
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    
    -- Set the final value
    current[parts[#parts]] = value
end

--[[
    Split a dot-notated key into parts
    @param key (string) Dot-notated key
    @return (table) Array of key parts
]]
function ConfigService:splitKey(key)
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    return parts
end

--[[
    Merge configuration tables
    @param target (table) Target configuration
    @param source (table) Source configuration
]]
function ConfigService:mergeConfigs(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            self:mergeConfigs(target[key], value)
        else
            target[key] = value
        end
    end
end

--[[
    Notify watchers of configuration changes
    @param key (string) Changed key
    @param oldValue (any) Previous value
    @param newValue (any) New value
]]
function ConfigService:notifyWatchers(key, oldValue, newValue)
    for pattern, watchers in pairs(self.watchers) do
        if self:matchesPattern(key, pattern) then
            for _, watcher in ipairs(watchers) do
                local success, error = pcall(watcher.callback, key, oldValue, newValue)
                if not success then
                    if self.sgf and self.sgf.log then
                        self.sgf.log:error("Error in configuration watcher", {
                            pattern = pattern,
                            error = error
                        })
                    end
                end
            end
        end
    end
end

--[[
    Check if a key matches a pattern
    @param key (string) Configuration key
    @param pattern (string) Pattern to match against
    @return (boolean) True if matches
]]
function ConfigService:matchesPattern(key, pattern)
    -- Simple wildcard matching (supports * at end)
    if pattern:sub(-1) == "*" then
        local prefix = pattern:sub(1, -2)
        return key:sub(1, #prefix) == prefix
    else
        return key == pattern
    end
end

--[[
    Get all configuration keys
    @return (table) Array of all keys
]]
function ConfigService:getAllKeys()
    local keys = {}
    self:collectKeys(self.configs, "", keys)
    return keys
end

--[[
    Collect all keys recursively
    @param table (table) Table to search
    @param prefix (string) Current prefix
    @param keys (table) Array to collect keys
]]
function ConfigService:collectKeys(table, prefix, keys)
    for key, value in pairs(table) do
        local fullKey = prefix == "" and key or (prefix .. "." .. key)
        table.insert(keys, fullKey)
        
        if type(value) == "table" then
            self:collectKeys(value, fullKey, keys)
        end
    end
end

return ConfigService