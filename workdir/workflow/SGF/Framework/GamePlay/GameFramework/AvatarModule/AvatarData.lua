local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")

local AvatarData = Class.New("AvatarData")

--实例化
function AvatarData:Constructor()
    self.tid = 0
    self.name = "普通攻击"
    self.desc = "普通攻击"
    self.icon = "icon"
end

--加载配置
function AvatarData:LoadConfig(config)
    self.name = config.name
    self.desc = config.desc
    self.icon = config.icon
    self.maxLevel = config.maxLevel
end

--从tid加载数据
function AvatarData:LoadConfigFromTid(tid)
    self.tid = tid
    local config = DataProviderManager:GetData("Avatar",tid)
    if config == nil then
        Log:Error("AvatarData:LoadConfigFromTid failed, tid = %d",tid)
        return
    end
    self:LoadConfig(config)
end

return AvatarData