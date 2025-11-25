local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local PetManager = GFScript("PetModule.PetManager")
local PetSkillData = GFScript("PetModule.PetSkillData")
local PetSkillEvent = Class.New("PetSkillEvent")

function PetSkillEvent:Constructor()
    -- --上一次执行时间
    -- self.lastExecuteTime = 0
end

function PetSkillEvent:Destructor()

end

function PetSkillEvent:Init(petActor, skill, skillEventData, eventIndex)
    self.petActor = petActor
    self.skill = skill
    self.eventIndex = eventIndex
    self.skillEventData = skillEventData
    self.player = self.petActor:GetMaster()
    -- self.lastExecuteTime = Utils:GetServerTime()

    local pet = self:GetPet()
    if pet then
        pet:InitSkillRemainingTime(skill.skillIndex)
        pet:SetSyncDirty()
    end
end

-- function PetSkillEvent:GetLastExecuteTime()
--     local pet = self:GetPet()
--     if not pet then
--         return Utils:GetServerTime()
--     end 
--     return pet:GetSkillLastExecuteTime()
-- end

function PetSkillEvent:Update(dt)
    local petSettings = PetManager:GetPetSettings()
    local now = Utils:GetServerTime()
    local cd = self:GetDerivedCD()
    if cd > petSettings.MinCD then
        local pet = self:GetPet()
        if pet then
            if pet:CanReleaseSkill() then
                self:Execute()
                self.skill:NotifySkillEventExecuted(self.eventIndex)
            end
        end
        
    end
end

--获取技能剩余时间
function PetSkillEvent:GetRemainingTime()
    local pet = self:GetPet()
    if pet then
        return pet:GetSkillRemainingTime()
    end
    return 0
end

function PetSkillEvent:Serialize(data, purpose)
    -- data.lastExecuteTime = self.lastExecuteTime
end     

function PetSkillEvent:Deserialize(data)
    -- self.lastExecuteTime = data.lastExecuteTime
end

--是否存在某个值
function PetSkillEvent:IsNullValue(name)   
    local skillData = self.skill.data
    local quality = self:GetQuality()
    local pet = self:GetPet()
    if not quality or not pet then
        return true 
    end
    return skillData:IsNullValue(name, quality, self.eventIndex)
end

function PetSkillEvent:GetDerivedValue(name)
    local skillData = self.skill.data
    local quality = self:GetQuality()
    local pet = self:GetPet()
    if not quality or not pet then
        return 0
    end
    local weight = pet:GetDerivedWeight()
    return skillData:GetDerivedValue(name, quality, weight, self.eventIndex)
end

function PetSkillEvent:GetDerivedCD()
    local petSettings = PetManager:GetPetSettings()
    local cdTimeUnit = self.skillEventData.cdTimeUnit or "s"
    return self:GetDerivedValue("cd") * petSettings.SkillCDScale * PetSkillData.CDTimeUnit[cdTimeUnit]
end

function PetSkillEvent:GetDerivedParam1()
    return self:GetDerivedValue("param1")
end

function PetSkillEvent:GetDerivedParam2()
    return self:GetDerivedValue("param2")
end

function PetSkillEvent:GetDerivedParam3()
    return self:GetDerivedValue("param3")
end

function PetSkillEvent:GetDerivedParam4()
    return self:GetDerivedValue("param4")   
end

function PetSkillEvent:GetQuality()
    local pet = self:GetPet()
    if pet then
        return pet:GetQuality()
    end
    return 0
end

--获取宠物
function PetSkillEvent:GetPet()
    local petId = self.petActor.petId
    if self.player then
        return self.player.PetComponent:GetPetById(petId)
    end
    return nil
end

function PetSkillEvent:PackSkillEventInfo()
    local skillEventInfo = {}
    skillEventInfo.eventIndex = self.eventIndex
    -- skillEventInfo.lastExecuteTime = self.lastExecuteTime
    return skillEventInfo
end

--执行
function PetSkillEvent:Execute()
    --播放动画
    self.petActor.AvatarComponent:PlayMontage(self.skillEventData.animName)
    self.petActor:NotifySkillEventExecuted(self.skill.skillIndex)
end


return PetSkillEvent