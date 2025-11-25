local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local NetworkPacker = GFScript("NetworkModule.NetworkPacker")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local PetSettings = GFScript("PetModule.PetSettings")
local PetManager = GFScript("PetModule.PetManager")

local Pet = Class.New("Pet")

--实例化
function Pet:Constructor()
    self.petId = 0
    self.tid = 0
    self.level = 1--当前等级
    --饥饿
    self.hunger = 0 
    --经验值
    self.exp = 0
    --缩放
    self.scale = 1
    --体重
    -- self.weight = 0 等于缩放 * 2

    self.nickName = nil

    --是否已经召唤
    self.isSummoned = false
    self.isFollowPet = false

    self.skillStates = {}

    -- self.skillLastExecuteTime = 0
    self.remainingSkillTime = -1
    --召唤时间
    self.summonTime = 0
    --销毁召唤时间
    self.destroySummonTime = 0
    --是否需要同步
    self.syncDirty = true
end
--初始化
function Pet:Init(tid, actor)
    self.tid = tid
    self:SetActor(actor)
    self.level = 1
    self.data = PetManager:GetPetData(tid)
    self:SetSatisfied()

    -- self.skillLastExecuteTime = Utils:GetServerTime()
    self.remainingSkillTime = -1
end

function Pet:SetSyncDirty()
    self.syncDirty = true
end

function Pet:SetActor(actor)
    self.actor = actor
end

function Pet:NotifyStatDirty()
    self.actor.PetComponent:NotifyStatDirty()
end

--是否满级
function Pet:IsMaxLevel()
    return self.level >= self.data.maxLevel
end

--是否可以升级
function Pet:CanUpgrade()
    if self:IsMaxLevel() then
        return false
    end
    local nextLevel = self.level + 1
    local upgradeExp = self:GetUpgradeExp()
    if upgradeExp then
        if self.exp >= upgradeExp then
            return true
        end
    end
    return false
end

--升级
function Pet:Upgrade()
    if not self:CanUpgrade() then
        return false
    end
    self.level = self.level + 1
    self.exp = 0
    return true
end

function Pet:AddExp(exp)
    self.exp = self.exp + exp
    --判断是否可以升级
    if self:CanUpgrade() then
        self:Upgrade()
    end
end

--获取升级所需经验
function Pet:GetUpgradeExp()
    local nextLevel = self.level + 1
    local nextData = ConfigManager:GetConfig(PetSettings.Table.PetLevel,nextLevel)
    if nextData == nil then
        return nil
    end
    return nextData.exp
end

function Pet:Update(dt)

    self:Advance(dt)
    if self.remainingSkillTime and self.remainingSkillTime > 0 then
        self.remainingSkillTime = self.remainingSkillTime - dt
        if self.remainingSkillTime <= 0 then
            self.remainingSkillTime = 0
        end
    end 
end

--更新
function Pet:Advance(dt)
    if self.actor:IsServer() then
        local petSettings = PetManager:GetPetSettings()
        if not self:IsMaxLevel() then
            if self:IsHungry() then
                self:AddExp(self.data.hungryExpGrowth * dt * petSettings.HungryExpGrowthMul)
            else
                self:AddExp(self.data.expGrowth * dt * petSettings.ExpGrowthMul)
            end
        end
        local hungerGrowth = self:GetHungerGrowth()
        self:SetHunger(math.max(0, self.hunger - hungerGrowth * dt))
    end
end

--是否可以释放技能
function Pet:CanReleaseSkill()
    if self.remainingSkillTime > 0 then
        return false
    end
    return true
end

function Pet:InitSkillRemainingTime(skillIndex)
    if self.remainingSkillTime == -1 then
        self.remainingSkillTime = self:GetSkillCD(skillIndex)
    end
end

function Pet:ResetSkillRemainingTime(skillIndex)
    self.remainingSkillTime = self:GetSkillCD(skillIndex)
end

function Pet:NotifySkillEventExecuted(skillIndex)
    self:ResetSkillRemainingTime(skillIndex)
end

--获取饥饿成长
function Pet:GetHungerGrowth()
    local petSettings = PetManager:GetPetSettings()
    local maxHunger = self:GetMaxHunger()
    local hungerGrowth = maxHunger / (petSettings.HungerDecayTime * 60)
    return hungerGrowth
end

function Pet:GetDerivedScale()
    local modelScale = self.data.modelScale
    local scale = (self.scale + self.data.scaleGrowth * self.level) * modelScale
    return scale
end

function Pet:GetWeight()
    return self.scale * 2
end

--获取体重
function Pet:GetDerivedWeight()
    local weight = self:GetWeight() + self.data.weightGrowth * self.level
    return weight
end

--是否饥饿
function Pet:IsHungry()
    return self.hunger <= 0
end

--设置饥饿      
function Pet:SetHunger(hunger)
    local isHungry = self:IsHungry()
    local maxHunger = self:GetMaxHunger()
    self.hunger = math.max(0, hunger)
    self.hunger = math.min(self.hunger, maxHunger)
    if isHungry ~= self:IsHungry() then
        if self.actor then
            local petActor = self.actor.PetComponent:GetSummonPetById(self.petId)
            -- if petActor then
            --     petActor:NotifyHungryChanged(isHungry, self:IsHungry())
            -- end
        end
    end 
end

--设置饱食
function Pet:SetSatisfied()
    self:SetHunger(self:GetMaxHunger())
end

--获取最大饥饿值
function Pet:GetMaxHunger()
    return self.data.sellPrice / (self.data.feedFactor or 1)
end

function Pet:SetNickName(nickName)
    self.nickName = nickName
end

function Pet:GetNickName()
    return self.nickName or self.data.name
end

--获取属性
function Pet:GetStats()
    --考虑成长
    local weight = self:GetDerivedWeight()  
    local stats = {}
    if self.data.stats then
        for k,v in pairs(self.data.stats) do
            if k ~= "growUp" then
                stats[k] = Utils:GetDerivedParamsValue(k, weight, self.data.stats)
            end
        end
    end

    for _, skill in ipairs(self.data.skills) do
        local skillStats = skill:GetStats(weight)
        for k,v in pairs(skillStats) do
            if stats[k] then
                stats[k] = stats[k] + v
            else
                stats[k] = v
            end
        end
    end

    return stats
end

--获取属性信息
function Pet:GetStatValue(statName)
    local stats = self:GetStats()
    return stats[statName] or 0
end

--获取体积所在档位
function Pet:GetSizeConfig()
    return PetManager:GetSizeConfig(self.scale)
end

--计算售价
function Pet:CalculateSellPrice()
    local levelScale = self.scale + self.data.scaleGrowth * self.level
    local sizeConfig = PetManager:GetSizeConfig(levelScale)
    if not sizeConfig then
        return 0
    end
    --初始价值 * 放大系数 * 收益系数
    return self.data.sellPrice * levelScale * sizeConfig.profit
end

--获取属性
function Pet:GetBonusStats()
    --考虑成长
    local weight = self:GetDerivedWeight()  
    local stats = {}
    if self.data.bonusStats then
        for k,v in pairs(self.data.bonusStats) do
            if k ~= "growUp" then
                stats[k] = Utils:GetDerivedParamsValue(k, weight, self.data.bonusStats)
            end
        end
    end

    for _, skill in ipairs(self.data.skills) do
        local bonusStats = skill:GetBonusStats(weight)
        for k,v in pairs(bonusStats) do
            if stats[k] then
                stats[k] = stats[k] + v
            else
                stats[k] = v
            end
        end
    end

    return stats
end

--获取品质
function Pet:GetQuality()
    return self.data.quality
end

--召唤
function Pet:OnSummon(summon)
    -- if self.actor:IsServer() then
        self.summon = summon
        self.summonTime = Utils:GetServerTime()
        if self.destroySummonTime ~= 0 and self.summonTime > self.destroySummonTime then
            --减去销毁召唤时间
            local time = self.summonTime - self.destroySummonTime   
            -- self.skillLastExecuteTime = self.skillLastExecuteTime + time
            -- if self.skillLastExecuteTime > self.summonTime then
            --     self.skillLastExecuteTime = self.summonTime
            -- end
        end
    -- end
end

--销毁召唤
function Pet:OnDestroySummon()
    -- if self.actor:IsServer() then
        if self.summon then
            self.destroySummonTime = Utils:GetServerTime()
            self.summon = nil
        end
    -- end
end

--获取技能cd
function Pet:GetSkillCD(skillIndex)
    skillIndex = skillIndex or 1
    local skillData = self.data.skills[skillIndex]
    if skillData then
        local petSettings = PetManager:GetPetSettings()
        return skillData:GetDerivedCD(self:GetQuality(), self:GetDerivedWeight(), 0) * petSettings.SkillCDScale 
    end
    return 0
end

function Pet:GetSkillRemainingTime(skillIndex)

    if self.remainingSkillTime then
        return self.remainingSkillTime
    end
    return 0

    -- skillIndex = skillIndex or 1

    -- local cd = self:GetSkillCD(skillIndex)
    -- if cd <= 0 then
    --     return 0
    -- end
    -- local executeTime = self.skillLastExecuteTime

    -- -- local skillState = self:GetSkillState(skillIndex)   
    -- -- if skillState then  
    -- --     if skillState.skillEvents and skillState.skillEvents[1] then      
    -- --         executeTime = skillState.skillEvents[1].lastExecuteTime
    -- --     end
    -- -- end

    -- local now = Utils:GetServerTime()
    -- if executeTime <= 0 then
    --     return cd
    -- end
    -- local remainingTime = executeTime + cd - now
    -- if remainingTime <= 0 then
    --     remainingTime = 0
    -- end 
    -- if remainingTime > cd then
    --     remainingTime = cd
    -- end
    -- return remainingTime
end

-- --获取技能上次执行时间
-- function Pet:GetSkillLastExecuteTime()
--     return self.skillLastExecuteTime
-- end

--获取技能描述
function Pet:GetSkillDesc(skillIndex)
    local skillData = self.data.skills[skillIndex]
    if skillData then
        return skillData:GetDerivedDesc(self:GetQuality(), self:GetDerivedWeight(), 0)
    end
    return nil
end

--获取技能状态
function Pet:GetSkillState(skillIndex)
    return self.skillStates[skillIndex]
end

--设置技能状态
function Pet:SetSkillState(skillIndex, state)
    self.skillStates[skillIndex] = state
end

--序列化
function Pet:Serialize(data, purpose)
    data.petId = self.petId
    data.tid = self.tid
    data.level = self.level
    data.hunger = self.hunger
    data.exp = self.exp
    data.scale = self.scale
    data.nickName = self.nickName
    data.isSummoned = self.isSummoned
    data.isFollowPet = self.isFollowPet
    data.skillStates = self.skillStates
    -- data.skillLastExecuteTime = self.skillLastExecuteTime

    -- if purpose == "Sync" then   
        data.remainingSkillTime = self.remainingSkillTime
    -- end

end

--反序列化
function Pet:Deserialize(data)
    self.petId = data.petId
    self.tid = data.tid
    self.level = data.level
    self:SetHunger(data.hunger)
    self.exp = data.exp
    self.scale = data.scale
    self.nickName = data.nickName
    self.isSummoned = data.isSummoned
    self.isFollowPet = data.isFollowPet
    self.skillStates = data.skillStates or {}
    -- self.skillLastExecuteTime = data.skillLastExecuteTime
    -- if not self.skillLastExecuteTime then
    --     self.skillLastExecuteTime = Utils:GetServerTime()
    -- end
    self.data = PetManager:GetPetData(self.tid)
    self.remainingSkillTime = data.remainingSkillTime or -1
end

--网络序列化
function Pet:NetSerialize(pet)
    local data = {}
    pet:Serialize(data, "Sync")
    return data
end

--网络反序列化
function Pet:NetDeserialize(data, isServer)
    local newPet = Pet.New()
    newPet:Init(data.tid)
    newPet:Deserialize(data)
    return newPet
end

--打印描述
function Pet:GetDescription()
    local desc = ""

    desc = string.format("Pet: ID=%d TID=%s, Level=%s",
        self.petId,
        tostring(self.tid),
        tostring(self.level),
        tostring(self.nickName)
    )
    return desc
end

NetworkPacker:Setup("Pet", Pet)

return Pet