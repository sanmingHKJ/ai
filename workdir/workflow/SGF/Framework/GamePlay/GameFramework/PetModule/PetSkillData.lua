local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigLoaderSetup = GFScript("CoreModule.ConfigLoaderSetup")
local PetSettings = GFScript("PetModule.PetSettings")
local PetSkillData = Class.New("PetSkillData")

PetSkillData.CDTimeUnit = {
    s = 1,
    m = 60,
    h = 3600,
    d = 86400,
}

--实例化
function PetSkillData:Constructor()
    self.tid = 0
    self.type = ""
    self.iconId = ""
    self.desc = ""
    self.event = nil
    self.events = {}
    self.bonusStats = {}
    self.stats = {} --奖励给宠物的属性
end

function PetSkillData:GetStats(factor)
    local stats = {}
    if self.stats then
        for k,v in pairs(self.stats) do
            if k ~= "growUp" then   
                stats[k] = Utils:GetDerivedParamsValue(k, factor, self.stats)
            end
        end
    end
    return stats
end

function PetSkillData:GetBonusStats(factor)
    local stats = {}
    if self.bonusStats then
        for k,v in pairs(self.bonusStats) do
            if k ~= "growUp" then
                stats[k] = Utils:GetDerivedParamsValue(k, factor, self.bonusStats)
            end
        end
    end
    return stats
end

function PetSkillData:GetParams(quality, eventIndex)
    eventIndex = eventIndex or 1
    local event = self:GetDerivedEvent(eventIndex)
    if not event then
        return nil
    end
    local params = event.params[quality] or event.params
    return params
end

function PetSkillData:GetDerivedEvent(eventIndex)
    eventIndex = eventIndex or 1
    return self.events and self.events[eventIndex] or self.event
end

--是否存在某个值
function PetSkillData:IsNullValue(name, quality, eventIndex)
    local params = self:GetParams(quality, eventIndex)
    if not params then
        return true
    end
    return params[name] == nil
end

function PetSkillData:GetDerivedValue(name, quality, factor, eventIndex)
    local params = self:GetParams(quality, eventIndex)
    if not params then
        return nil
    end
    return Utils:GetDerivedParamsValue(name, factor, params)
end

--获取衍生事件CD
function PetSkillData:GetDerivedCD(quality, factor, eventIndex)
    return self:GetDerivedValue("cd", quality, factor, eventIndex) or 0
end

--获取衍生事件参数1
function PetSkillData:GetDerivedParam1(quality, factor, eventIndex)
    return self:GetDerivedValue("param1", quality, factor, eventIndex)
end

--获取衍生事件参数2
function PetSkillData:GetDerivedParam2(quality, factor, eventIndex)
    return self:GetDerivedValue("param2", quality, factor, eventIndex)
end

--获取衍生事件参数3
function PetSkillData:GetDerivedParam3(quality, factor, eventIndex)
    return self:GetDerivedValue("param3", quality, factor, eventIndex)
end

--获取衍生事件参数4
function PetSkillData:GetDerivedParam4(quality, factor, eventIndex)
    return self:GetDerivedValue("param4", quality, factor, eventIndex)
end

--获取描述
function PetSkillData:GetDerivedDesc(quality, factor, eventIndex)
    local bonusStats = self:GetBonusStats(factor)
    local stats = self:GetStats(factor)
    local paramsGetter = function(name)
        return self:GetDerivedValue(name, quality, factor, eventIndex) or bonusStats[name] or stats[name]
    end
    return Utils:GenerateDesc(self.desc, paramsGetter)
end

--获取配置名称
function PetSkillData:GetConfigName()
    return PetSettings.Table.PetSkill
end

--加载配置
function PetSkillData:OnLoadConfig(config)
    self.tid = config.tid
    self.type = config.type
    self.iconId = config.iconId
    self.desc = config.desc
    self.event = config.event
    self.events = config.events
    self.bonusStats = config.bonusStats or {}
    self.stats = config.stats or {}

    self.radius = config.radius or 0
end

ConfigLoaderSetup:Setup(PetSkillData)

return PetSkillData