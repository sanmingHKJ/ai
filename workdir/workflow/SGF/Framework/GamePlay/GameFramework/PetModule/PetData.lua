local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigLoaderSetup = GFScript("CoreModule.ConfigLoaderSetup")
local PetSettings = GFScript("PetModule.PetSettings")
local PetManager = GFScript("PetModule.PetManager")
local PetData = Class.New("PetData")

--实例化
function PetData:Constructor()
    self.tid = 0
    self.name = "普通攻击"
    self.desc = "普通攻击"
    self.iconId = "icon"
    self.modelId = ""
    self.modelScale = 1--模型缩放
    self.sellPrice = 0
    --品质
    self.quality = "Q1"
    self.qualityData = nil
    --工作
    self.skills = 0

    --音效
    self.audio = {}

    --经验成长系数
    self.expGrowth = 0
    --饥饿时经验成长系数
    self.hungryExpGrowth = 0
    --饥饿成长系数
    -- self.hungerGrowth = 0
    --缩放成长系数
    self.scaleGrowth = 0
    --体重成长系数
    self.weightGrowth = 0
    --喂养系数
    self.feedFactor = 1
end

--获取配置名称
function PetData:GetConfigName()
    return PetSettings.Table.Pet
end

--加载配置
function PetData:OnLoadConfig(config)
    local petSettings = PetManager:GetPetSettings()
    local commonConfig = petSettings.Common
    self.name = config.name
    self.desc = config.desc
    self.iconId = config.iconId
    self.modelId = config.modelId
    self.modelScale = config.modelScale or 1
    self.quality = config.quality or "Q1"
    self.maxLevel = config.maxLevel or petSettings.MaxLevel
    self.sellPrice = config.sellPrice
    self.expGrowth = config.expGrowth or commonConfig.expGrowth
    self.hungryExpGrowth = config.hungryExpGrowth or commonConfig.hungryExpGrowth
    -- self.hungerGrowth = config.hungerGrowth or commonConfig.hungerGrowth
    self.scaleGrowth = config.scaleGrowth or commonConfig.scaleGrowth
    self.weightGrowth = config.weightGrowth or commonConfig.weightGrowth
    self.feedFactor = config.feedFactor or commonConfig.feedFactor
    self.stats = config.stats
    self.bonusStats = config.bonusStats
    self.audio = config.audio or {}
    self.qualityData = PetManager:GetQualityData(self.quality)

    self.skills = {}
    for _, skillTid in ipairs(config.skills) do
        local skillData = PetManager:GetPetSkillData(skillTid)
        if skillData then
            table.insert(self.skills, skillData)
        end
    end
end

ConfigLoaderSetup:Setup(PetData)

return PetData