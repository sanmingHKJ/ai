local ConfigManager = {}
setmetatable(ConfigManager, ConfigManager)
local tableLoaders = {}
local singleTableLoaders = {}
local tables = {}

local function __GetConfig(key, tid)
    local func = tableLoaders[key]
    if not func then
        return nil
    end
    return func(tid)
end

local table = {}
table.__index = function(self, tid)
    -- 先检查缓存中是否已存在
    if self.caches[tid] then
        return self.caches[tid]
    end
    -- 如果缓存中没有，则获取并存储到缓存中
    local result = __GetConfig(self.key, tid)
    self.caches[tid] = result
    return result
end

ConfigManager.__index = function(self, key)
    if not tables[key] then
        if singleTableLoaders[key] then
            tables[key] = __GetConfig(key)
        else
            tables[key] = setmetatable({key = key, caches = {}}, table)
        end
    end
    return tables[key]
end

--注册数据提供函数
function ConfigManager:Register(name, single, func)
    if not tableLoaders then
        tableLoaders = {}
    end
    tableLoaders[name] = func
    if single then
        singleTableLoaders[name] = func
    end
end

--获取数据
function ConfigManager:GetConfig(name, tid)
    return __GetConfig(name, tid)
end

--获取所有数据
function ConfigManager:GetAllConfigs(name)
    local func = tableLoaders[name]
    if not func then
        return nil
    end
    return func()
end

--是否存在数据
function ConfigManager:HasConfig(name, tid)
    if not name then
        return false
    end
    return self:GetConfig(name, tid) ~= nil
end


return ConfigManager
