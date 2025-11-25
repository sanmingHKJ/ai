local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigManager = GFScript("CoreModule.ConfigManager")

local ConfigLoaderSetup = {}

ConfigLoaderSetup.objCaches = {}

function ConfigLoaderSetup:Setup(obj)
    if not obj then
        return
    end
    local objClass = obj.class or obj
    local key = objClass.__cname
    if self.objCaches[key] then
        return
    end

    --判断对应的接口是否存在
    if not objClass.GetConfigName then
        Log:Error(key..":GetConfigName is not exist")
        return
    end

    self.objCaches[key] = true

    objClass.LoadConfig = function(target, config)
        if config.Id then
            target.tid = config.Id
        end
        if target.OnLoadConfig then
            target:OnLoadConfig(config)
        end
        if target.OnLoadConfigFinished then
            target:OnLoadConfigFinished(config)
        end
    end
    objClass.LoadConfigFromTid = function(target, tid)
        target.tid = tid
        local configName = target:GetConfigName()
        if configName == nil then
            Log:Error(key..":LoadConfigFromTid failed, configName is nil")
            return false
        end
        local config = ConfigManager:GetConfig(configName,tid)
        if config == nil then
            Log:Error(key..":LoadConfigFromTid failed, tid = %s",tostring(tid))
            return false
        end
        target:LoadConfig(config)
        return true
    end
end

return ConfigLoaderSetup
