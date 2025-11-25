local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local Math = GFScript("CoreModule.Math")
local PetSettings = GFScript("PetModule.PetSettings")
local ActorManager = GFScript("ActorModule.ActorManager")
local PetManager = {}


--工作创建工厂
PetManager.skillFactory = {}

--初始化
function PetManager:Init()
    ActorManager:RegisterActorFactory("Pet",GFScript("PetModule.APet"))
    RegisterComponentFactory(GFScript("PetModule.PetComponent"))

    --注册技能工厂
    self:RegisterSkillFactory("PetSkill",GFScript("PetModule.PetSkill"))
    self:RegisterSkillFactory("PetDotSkill",GFScript("PetModule.PetSkill.PetDotSkill"))
    self:RegisterSkillFactory("PetHaloSkill",GFScript("PetModule.PetSkill.PetHaloSkill"))   

    self.cachedPetDatas = {}
    self.cachedPetSkillDatas = {}
end

--注册工作创建工厂
function PetManager:RegisterSkillFactory(name, factory)
    self.skillFactory[name] = factory
end

--获取工作创建工厂
function PetManager:GetSkillFactory(name)
    return self.skillFactory[name]
end 

--更新
function PetManager:Update(dt)

end

--获取宠物数据
function PetManager:GetPetData(tid)
    local petData = self.cachedPetDatas[tid]
    if petData then
        return petData
    end
    local PetData = GFScript("PetModule.PetData")
    local newPetData = PetData.New()
    newPetData:LoadConfigFromTid(tid)
    self.cachedPetDatas[tid] = newPetData 
    return newPetData
end

--获取宠物技能数据
function PetManager:GetPetSkillData(tid)
    local petSkillData = self.cachedPetSkillDatas[tid]
    if petSkillData then
        return petSkillData
    end
    local PetSkillData = GFScript("PetModule.PetSkillData")
    local newPetSkillData = PetSkillData.New()
    newPetSkillData:LoadConfigFromTid(tid)
    self.cachedPetSkillDatas[tid] = newPetSkillData 
    return newPetSkillData
end


--获取体积所在档位
function PetManager:GetSizeConfig(scale)
    local configs = ConfigManager:GetAllConfigs(PetSettings.Table.PetSize)
    for index, config in ipairs(configs) do
        local nextConfig = configs[index + 1]
        if nextConfig then
            if scale >= config.range[1] and scale <= nextConfig.range[1] then
                return config
            end
        else
            if scale >= config.range[1] and scale <= config.range[2] then
                return config
            end
        end 
    end
    return nil
end

--获取随机体积，根据weight权重  
function PetManager:GetRandomScale()
    local configs = ConfigManager:GetAllConfigs(PetSettings.Table.PetSize)
    local totalWeight = 0
    for _, config in pairs(configs) do
        totalWeight = totalWeight + config.weight
    end
    local randomWeight = Math:Random(0, totalWeight)
    local currentWeight = 0
    for _, config in pairs(configs) do
        currentWeight = currentWeight + config.weight
        if randomWeight <= currentWeight then
            return config
        end
    end
    return configs[1]
end

--获取宠物设置
function PetManager:GetPetSettings()
    return ConfigManager:GetAllConfigs(PetSettings.Table.PetSettings)
end

--获取宠物品质数据
function PetManager:GetQualityData(quality)
    return ConfigManager:GetConfig(PetSettings.Table.PetQuality, quality)
end

--获取宠物技能事件
function PetManager:GetPetSkillEvent(tid)
    return ConfigManager:GetConfig(PetSettings.Table.PetSkillEvent, tid)
end

return PetManager