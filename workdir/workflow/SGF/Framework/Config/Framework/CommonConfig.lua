--数据配置
local Config={}

function Config.Init()
    for _, child in ipairs(script.Children) do
        if child.ClassType ~= 'ModuleScript' then
            return
        end

        local scriptName = child.Name
        Config[scriptName] = require(child)
    end
end

function Config.GetConfigs(configName)
    return Config[configName]
end

function Config.GetConfigData(configName, key, value)
    local config = Config[configName] or {}
    local rst = nil
    for _, data in pairs(config) do
        if data[key] == value then
            rst = data
            break
        end
    end
    return rst
end

Config.Init()
return Config