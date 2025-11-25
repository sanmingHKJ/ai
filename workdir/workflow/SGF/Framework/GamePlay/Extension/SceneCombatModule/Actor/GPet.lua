local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local PetSettings = GFScript("PetModule.PetSettings")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local PetManager = GFScript("PetModule.PetManager")

local GNpc = ExtensionScript("SceneCombatModule.Actor.GNpc")

-- 宠物
local GPet = GNpc.Extend("GPet")

function GPet:Constructor()
    self.skills = {}

    self.skillEnabled = true

    self.statsEnabled = true

    self.hungryState = false
end

function GPet:Destructor()
    self:ClearAllSkills()
end

function GPet:Init()
    GPet.super.Init(self)
    self:SetCollideGroup(ActorDefines.CollideGroup.Pet)
end


function GPet:InitServer()
    GPet.super.InitServer(self)
end

function GPet:SetSkillEnabled(enabled)
    self.skillEnabled = enabled
end

function GPet:IsSkillEnabled() 
    return self.skillEnabled
end

function GPet:SetStatsEnabled(enabled)
    self.statsEnabled = enabled
end

function GPet:IsStatsEnabled()
    return self.statsEnabled
end

function GPet:Update(dt)
    GPet.super.Update(self, dt)
    for _, skill in ipairs(self.skills) do
        skill:Update(dt)
    end

    if self:IsServer() then
        local pet = self:GetPet()
        if pet then
            if self.hungryState ~= pet:IsHungry() then
                self:NotifyHungryChanged(self.hungryState, pet:IsHungry())
                self.hungryState = pet:IsHungry()
            end 
            self.StatComponent:SetSimpleValue("Sleep", self.hungryState and 1 or 0)
        end
    end
end
--更新
function GPet:LaterUpdate(dt)
    GPet.super.LaterUpdate(self, dt)
end

function GPet:Serialize(data, purpose)
    if purpose == "Save" then
        data.skills = {}
        for _, skill in ipairs(self.skills) do
            local skillData = {}
            skill:Serialize(skillData, purpose)
            table.insert(data.skills, skillData)
        end
    else
        GPet.super.Serialize(self, data, purpose)
    end
    data.petId = self.petId
end

function GPet:Deserialize(data)
    if data.skills then
        for _, skillData in ipairs(data.skills) do
            local skill = self:GetOrCreateSkill(skillData.tid)
            if skill then
                skill:Deserialize(skillData)
            end
        end
    else
        GPet.super.Deserialize(self, data)
    end
    self.petId = data.petId
end

function GPet:SetPetId(petId)
    self.petId = petId
    if self:IsServer() then
        self:TRpcSetPetId(petId)
    end
end

--从tid加载数据
function GPet:GetConfigName()
    return ActorUtils:GetActorTable(ActorDefines.EActorType.Pet).Actor
end

--根据tid获取技能
function GPet:GetSkillByTid(skillTid)
    for _, skill in ipairs(self.skills) do
        if skill.tid == skillTid then
            return skill
        end
    end
    return nil
end

function GPet:GetOrCreateSkill(tid)
    local skill = self:GetSkillByTid(tid)
    if skill then
        return skill
    end
    local skillData = PetManager:GetPetSkillData(tid)
    return self:AddSkill(skillData)
end

function GPet:AddSkill(skillData)
    if skillData then
        local skillFactory = PetManager:GetSkillFactory(skillData.type)
        if skillFactory then
            local skill = skillFactory:New()
            local skillIndex = #self.skills + 1
            skill:Init(self, skillData, skillIndex)
            table.insert(self.skills, skill)
            return skill
        end
    end
    return nil
end

function GPet:ClearAllSkills()
    for _, skill in ipairs(self.skills) do
        skill:Destroy()
    end
    self.skills = {}
end

function GPet:GetPet()
    if self.petId then
        local master = self:GetMaster()
        if master then
            return master.PetComponent:GetPetById(self.petId)
        end
        return nil
    end
    return nil
end

function GPet:GetSkillCD(skillIndex)
    local pet = self:GetPet()
    if not pet then
        return 0
    end
    return pet:GetSkillCD(skillIndex)
end

function GPet:GetSkillRemainingTime(skillIndex)
    skillIndex = skillIndex or 1
    if self:IsServer() then
        local skill = self.skills[skillIndex]
        if not skill then
            return 0
        end
        return skill:GetRemainingTime()
    else
        local cd = self:GetSkillCD(skillIndex)
        if cd <= 0 then
            return 0
        end
        local executeTime = 0
        if self.petInfo and self.petInfo.skills and self.petInfo.skills[skillIndex] then
            local events = self.petInfo.skills[skillIndex].events
            if events and events[1] then
                executeTime = events[1].lastExecuteTime
            end
        end
        local now = Utils:GetServerTime()
        if executeTime <= 0 then
            return cd
        end
        return executeTime + cd - now
    end
end

function GPet:GetSkillByIndex(skillIndex)
    skillIndex = skillIndex or 1
    return self.skills[skillIndex]
end


--加载配置
function GPet:OnLoadConfig(config)
    GPet.super.OnLoadConfig(self, config)

    self.skills = {}
    for _, tid in ipairs(config.skills) do
        local skillData = PetManager:GetPetSkillData(tid)
        if skillData then
            self:AddSkill(skillData)
        end
    end
end

function GPet:NotifySkillEventExecuted(skillIndex)
    if self:IsServer() then
        self:RpcNotifySkillEventExecuted(skillIndex)
        return
    end

    --播放音效
    self:PlayVoice("skill")
    local player = self:GetMaster()
    if player then
        local pet = self:GetPet()   
        player:FireClient("SkillEventExecuted", pet, skillIndex)
    end
end

--播放音效
function GPet:PlayVoice(audioName, is3D)
    is3D = is3D ~= false
    local pet = self:GetPet()
    if pet then
        local audio = pet.data.audio
        if audio then
            if audio[audioName] then
                local soundId = audio[audioName].soundId
                local volume = audio[audioName].volume or 1
                self.AvatarComponent:PlayVoice(soundId, volume, is3D)
            end
        end
    end
end

--饥饿状态改变
function GPet:NotifyHungryChanged(isHungry, newHungry)
    if self:IsServer() then
        self:RpcNotifyHungryChanged(isHungry, newHungry)
    end
    local master = self:GetMaster()
    if master then
        master:Fire(self:IsServer(), "HungryChanged", self, isHungry, newHungry)
    end
    if self:IsServer() then
        if newHungry then
            self:EnterHungryState()
        else
            self:ExitHungryState()
        end
    end
end

--进入饥饿状态
function GPet:EnterHungryState()
    if self:IsServer() then
        local pet = self:GetPet()
        local master = self:GetMaster()
        if master and pet then
            if not master.PetComponent:IsFollowPet(pet) then
                self:StartSleep()
            end
        end
    end
end

--退出饥饿状态
function GPet:ExitHungryState()
    if self:IsServer() then
        local pet = self:GetPet()
        local master = self:GetMaster()
        if master and pet then
            if not master.PetComponent:IsFollowPet(pet) then
                self:StopSleep()
            end
        end
    end
end

--开始睡眠  
function GPet:StartSleep()
    if self:IsServer() then
        self.AIComponent:SetAIEnabled(false)
        self.AvatarComponent:StopMove()
    end
end

--停止睡眠
function GPet:StopSleep()
    if self:IsServer() then
        self.AIComponent:SetAIEnabled(true)
    end
end

--弹出提示
function GPet:ShowTip(tip)
    if self:IsServer() then
        self:RpcShowTip(tip)
    end
    if XPlants.RemoteManager then
        local player = self:GetMaster()
        if player then
            XPlants.RemoteManager:FireClient(player:GetPlayerId(), XPlants.RemoteManager.Events.TIP_NOTIFICATION, {
                message = tip,
            })
        end
    end
end

-------------------------------------Rpc-------------------------------------
function GPet:TRpcSetPetId(petId)
    self:SetPetId(petId)
end

function GPet:RpcNotifySkillEventExecuted(skillIndex)
    self:NotifySkillEventExecuted(skillIndex)
end

function GPet:RpcNotifyHungryChanged(isHungry, newHungry)
    self:NotifyHungryChanged(isHungry, newHungry)
end

function GPet:RpcShowTip(tip)
    self:ShowTip(tip)
end

return GPet