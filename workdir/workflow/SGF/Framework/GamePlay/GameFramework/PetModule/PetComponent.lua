local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local StateMachine = GFScript("CoreModule.StateMachine")
local Database = GFScript("CoreModule.Database")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local PetManager = GFScript("PetModule.PetManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local GlobalEvent = GFScript("CoreModule.GlobalEvent")
local NetworkSetup = GFScript("NetworkModule.NetworkSetup")
local CombatDefines = GFScript("CombatModule.CombatDefines")
local Math = GFScript("CoreModule.Math")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local TimerManager = GFScript("CoreModule.TimerManager")
local UIManager = GFScript("UIModule.UIManager")
local Math = GFScript("CoreModule.Math")
local PetSettings = GFScript("PetModule.PetSettings")
local Pet = GFScript("PetModule.Pet")
local TimerManager = GFScript("CoreModule.TimerManager")
local ActorManager = GFScript("ActorModule.ActorManager")
local Stat = GFScript("StatModule.Stat")
local PetComponent = Class.New("PetComponent", ActorComponent)

PetComponent.version = 1

--实例化
function PetComponent:Constructor()
    self.dataTableName = "Pet"
    self.pets = {}

    --召唤的宠物列表
    self.summonPets = {}
    self.summonPetCount = 0

    
    local petSettings = PetManager:GetPetSettings()
end

function PetComponent:Destructor()
    if self.timerId then
        TimerManager:RemoveTimer(self.timerId)
        self.timerId = nil
    end

    if self.syncTimerId then
        TimerManager:RemoveTimer(self.syncTimerId)
        self.syncTimerId = nil
    end

    if self.actorCreatedConn then
        self.actorCreatedConn = ActorManager:RemoveByEventId(self.actorCreatedConn)
        self.actorCreatedConn = nil
    end
end


--当节点设置的时候
function PetComponent:OnActorSet(actor)
    PetComponent.super.OnActorSet(self, actor)
    if actor then
        actor:OnServerEvent("LoadFinished", function()
            --计算时间差
            if actor:IsPlayer() then
                local loginTimeDiff = actor:GetLoginTimeDiff()
                if loginTimeDiff > 0 then
                    for _, pet in pairs(self.pets) do
                        if pet.isSummoned then
                            pet:Advance(loginTimeDiff)
                        end
                    end 
                end
            end
        end)
        actor:OnServerEvent("Ready", function(isReady)
            if isReady then
                self:SyncAllPets()
            end
        end)
    end
end

--实例化
function PetComponent:Awake()
    PetComponent.super.Awake(self)

    self.actor.StatComponent:AddStatAffecter("Pet", 50, function()
        return self:CalcStats()
    end)
end

--启动
function PetComponent:Start()
    PetComponent.super.Start(self)  
    self.timerId = TimerManager:AddTimer(function(dt)
        self:OnDot(dt)
    end, 1)

end
--启动服务端
function PetComponent:OnStartServer()
    self.syncTimerId = TimerManager:AddTimer(function(dt)
        for _, pet in pairs(self.pets) do   
            if pet.syncDirty then
                self:TRpcUpdatePet(pet)
                pet.syncDirty = false
            end
        end
    end, 0.033)
end
--启动客户端
function PetComponent:OnStartClient()
    if self:IsLocalPlayer() then
        self.actorCreatedConn = ActorManager:OnClientEvent("ActorCreated", function(actor)
            self:OnActorCreated(actor)
        end)
    end
end

--获取宠物
function PetComponent:GetPet(tid)

end
--生成自动id
function PetComponent:GenerateAutoId()
    return Utils:GenerateUniqueId()
end
--添加宠物
function PetComponent:AddPet(pet)
    pet:SetActor(self.actor)
    table.insert(self.pets, pet)
    if self:IsServer() then
        if pet.petId == 0 then
            pet.petId = self:GenerateAutoId()
        end

        --随机一个缩放大小
        local scaleConfig = PetManager:GetRandomScale()
        if scaleConfig then
            pet.scale = Math:Random(scaleConfig.range[1], scaleConfig.range[2])
        end
        -- --随机一个体重
        -- local petSettings = PetManager:GetPetSettings()
        -- if petSettings then
        --     pet.weight = Math:Random(petSettings.InitPetWeight[1], petSettings.InitPetWeight[2])
        -- end

        --进行一次存档
        self:SaveData()

        self:TRpcAddPet(pet)
    end
    self.actor:Fire(self:IsServer(), "AddPet", pet)
end

--根据tid添加宠物
function PetComponent:AddPetByTid(tid)
    local pet = Pet.New()
    pet:Init(tid, self.actor)
    self:AddPet(pet)
    return pet
end

--移除宠物
function PetComponent:RemovePet(pet)
    local index = self:FindPetIndex(pet)
    if index then
        table.remove(self.pets, index)
    end
    if self:IsServer() then
        self:TRpcRemovePet(pet.petId)
    end
    self.actor:Fire(self:IsServer(), "RemovePet", pet)
end

function PetComponent:RemovePetByTid(tid)
    local pet = self:GetPetByTid(tid)
    if pet then
        self:RemovePet(pet)
    end
end

function PetComponent:RemovePetById(id)
    local pet = self:GetPetById(id)
    if pet then
        self:RemovePet(pet)
    end
end

function PetComponent:FindPetIndex(pet)
    for i, v in ipairs(self.pets) do
        if v == pet then
            return i
        end
    end
end
--根据获取宠物
function PetComponent:GetPetById(id)
    for i, v in ipairs(self.pets) do
        if v.petId == id then
            return v
        end
    end
    return nil
end
--根据tid获取宠物
function PetComponent:GetPetByTid(tid)
    for i, v in ipairs(self.pets) do
        if v.tid == tid then
            return v
        end
    end
    return nil
end

--获取跟随的宠物
function PetComponent:GetFollowPet()
    for i, v in ipairs(self.pets) do    
        if v.isFollowPet then
            return v
        end
    end
    return nil
end

--遍历宠物
function PetComponent:ForEachPets(func)
    for k,v in ipairs(self.pets) do
        if func(v) then
            break
        end
    end
end

--遍历召唤宠物
function PetComponent:ForEachSummonPets(func)
    for k,v in pairs(self.summonPets) do
        if func(v) then
            break
        end
    end
end 

--当场景设置的时候
function PetComponent:OnSceneSet(scene)
    if self:IsServer() then
        
    end
end

--根据id获取召唤宠物
function PetComponent:GetSummonPetById(petId)
    for _, pet in pairs(self.summonPets) do
        if pet.petId == petId then
            return pet
        end
    end
    return nil
end

--获取最大召唤宠物数量
function PetComponent:GetMaxSummonPetCount()
    local petSettings = PetManager:GetPetSettings()
    local maxSummonCount = petSettings.MaxSummonCount
    return maxSummonCount
end

--召唤宠物
function PetComponent:SummonPet(pet, aiName, force)
    force = force == true
    if not self.actor:IsServer() then
        Log:Error("SummonPet failed, not server")
        return
    end
    if self:HasSummonPetActor(pet) then
        Log:Error("SummonPet failed, pet = %s",pet.tid)
        return
    end
    if not force then

        if self.summonPetCount >= self:GetMaxSummonPetCount() then
            Log:Error("SummonPet failed, max summon count = %d",self:GetMaxSummonPetCount())
            return
        end
    end

    self:DestroySummonPet(pet)

    local summonAI = aiName or "ShowPet_2"
    local summon = self.actor.SummonComponent:Summon(pet.tid, nil, nil, function(summon)
        summon:SetPetId(pet.petId)
    end, function(summon)
        if summonAI then
            summon:LoadAIFromTid(summonAI)
        end

    end)
    if not summon then
        Log:Error("SummonPet failed, tid = %s",pet.tid)
        return
    end

    summon.StatComponent:SetBaseValue("ActorScale", pet:GetDerivedScale())

    summon:OnServerEvent("Destroy", function(actor)
        self:OnActorDestroyed(actor)
    end)

    pet.isSummoned = true
    self.summonPets[pet] = summon
    self:UpdateSummonPetCount()
    pet:OnSummon(summon)
    self.actor:FireServer("SummonPet", pet, summon)

    self:NotifyStatDirty()

    self:TRpcSummonPet(summon:GetActorId(), pet.petId)
    
    return summon
end

function PetComponent:SummonPetByTid(tid)
    local pet = self:GetPetByTid(tid)
    if pet then
        return self:SummonPet(pet)
    end
    return nil
end
function PetComponent:SummonPetById(petId)
    local pet = self:GetPetById(petId)
    if pet then
        return self:SummonPet(pet)
    end
    return nil
end

--销毁展示宠物
function PetComponent:DestroySummonPet(pet)
    if not self.actor:IsServer() then
        Log:Error("DestroySummonPet failed, not server")
        return
    end

    local isFollowPet = pet.isFollowPet

    pet.isSummoned = false

    --销毁actor
    local summon = self.summonPets[pet]
    if not summon then
        Log:Error("DestroySummonPet failed, pet = %s",pet.tid)
    else
        self.actor.SummonComponent:DestroySummon(summon)
    end
    self:TRpcDestroySummonPet(pet.petId)

    
    if isFollowPet then
        self.actor:FireServer("DestroySummonFollowPet", pet, summon)
    end
    pet:OnDestroySummon()
    self.actor:FireServer("DestroySummonPet", pet, summon)
    self.summonPets[pet] = nil
    self:UpdateSummonPetCount()
    self:NotifyStatDirty()

    if isFollowPet then
        pet.isFollowPet = false

        self.followPet = nil
    end

    return true
end

function PetComponent:DestroySummonPetByTid(tid)
    local pet = self:GetPetByTid(tid)
    if pet then
        return self:DestroySummonPet(pet)
    end
    return false
end

function PetComponent:DestroySummonPetById(petId)
    local pet = self:GetPetById(petId)
    if pet then
        return self:DestroySummonPet(pet)
    end
    return false
end


--召唤跟随宠物
function PetComponent:SummonFollowPet(pet, force)
    force = force == true
    if self:HasSummonPetActor(pet) then
        self:DestroySummonPet(pet)
    end

    local followAI = "ShowPet_1"
    local followPet = self:SummonPet(pet, followAI, force)

    if not followPet then
        Log:Error("SummonFollowPet failed, pet = %s",pet.tid)
        return
    end

    pet.isFollowPet = true
    self.followPet = followPet

    followPet:SetSkillEnabled(false)

    self.actor:FireServer("SummonFollowPet", pet, followPet)

    
    self:TRpcSummonFollowPet(followPet:GetActorId(), pet.petId)
    
    return followPet
end

--根据tid召唤跟随宠物
function PetComponent:SummonFollowPetByTid(tid)
    local pet = self:GetPetByTid(tid)
    if pet then
        return self:SummonFollowPet(pet)
    end
    return nil
end
function PetComponent:SummonFollowPetById(petId)
    local pet = self:GetPetById(petId)
    if pet then
        return self:SummonFollowPet(pet)
    end
    return nil
end

--销毁跟随宠物
function PetComponent:DestroySummonFollowPet()
    if not self.actor:IsServer() then
        Log:Error("DestroySummonFollowPet failed, not server")
        return
    end
    local pet = nil
    local followPet = self.followPet
    if not followPet then
        Log:Error("DestroySummonFollowPet failed, followPet = nil")
    else
        pet = followPet:GetPet()
    end

    if not pet then
        --尝试找到一个跟随的宠物
        for _, v in pairs(self.pets) do
            if v.isFollowPet then
                pet = v
                break
            end
        end
        if not pet then
            Log:Error("DestroySummonFollowPet failed, pet = nil")
            return
        end
    end
    self:DestroySummonPet(pet)
    --召唤出来，让其回家
    self:SummonPet(pet)
    return true
end

function PetComponent:HasSummonPetActor(pet)
    return self.summonPets[pet] ~= nil
end

--是否已经召唤宠物
function PetComponent:IsSummonPet(pet)
    return pet.isSummoned
end

--是否已经召唤跟随宠物
function PetComponent:IsFollowPet(pet)
    return pet.isFollowPet
end


function PetComponent:NewData()
    self.pets = {}
    self.summonPets = {}
    self.summonPetCount = 0

    local petSettings = PetManager:GetPetSettings()
    local defaultPets = petSettings.DefaultPets
    for i, tid in ipairs(defaultPets) do
        self:AddPetByTid(tid)
    end
end 


--打印所有宠物信息
function PetComponent:GetDescription()
    local resultStr = ""
    local pets = self.pets
    if not pets or #pets == 0 then
        resultStr = "No pets in the pet component."
        return resultStr
    end

    for i, pet in ipairs(pets) do
        if pet then
            resultStr = resultStr .. pet:GetDescription() .. "\n"
        end
    end
    return resultStr
end

--设置宠物等级
function PetComponent:SetPetLevel(petId, level)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("SetPetLevel failed, petId = %s", petId)
        return
    end
    local oldLevel = pet.level
    pet.level = level

    if self:IsServer() then
        self:TRpcPetLevelChanged(petId, oldLevel, level)
    end

    self.actor:Fire(self:IsServer(), "PetLevelChanged", pet, oldLevel, level)
end

--获取宠物等级
function PetComponent:GetPetLevel(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetLevel failed, petId = %s", petId)
        return
    end
    return pet.level
end

--设置宠物经验
function PetComponent:SetPetExp(petId, exp)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("SetPetExp failed, petId = %s", petId)
        return
    end
    local oldExp = pet.exp
    pet.exp = exp

    if self:IsServer() then
        self:TRpcPetExpChanged(petId, oldExp, exp)
    end

    self.actor:Fire(self:IsServer(), "PetExpChanged", pet, oldExp, exp)
end 
--获取宠物经验
function PetComponent:GetPetExp(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetExp failed, petId = %s", petId)
        return
    end
    return pet.exp
end

--获取宠物升级所需经验
function PetComponent:GetPetUpgradeExp(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetUpgradeExp failed, petId = %s", petId)
        return
    end
    return pet:GetUpgradeExp()
end


--获取宠物技能描述
function PetComponent:GetPetSkillDesc(petId, skillIndex)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetSkillDesc failed, petId = %s", petId)
        return
    end
    return pet:GetSkillDesc(skillIndex)
end

--设置宠物饥饿
function PetComponent:SetPetHunger(petId, hunger)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("SetPetHunger failed, petId = %s", petId)
        return
    end
    local oldHunger = pet.hunger
    pet:SetHunger(hunger) 

    if self:IsServer() then
        self:TRpcPetHungerChanged(petId, oldHunger, hunger)
    end

    self.actor:Fire(self:IsServer(), "PetHungerChanged", pet, oldHunger, hunger)
end

--获取宠物饥饿
function PetComponent:GetPetHunger(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetHunger failed, petId = %s", petId)
        return 0
    end
    return pet.hunger
end

--获取宠物最大饥饿
function PetComponent:GetMaxPetHunger(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetMaxPetHunger failed, petId = %s", petId)
        return 0
    end
    return pet:GetMaxHunger()
end

--获取宠物体重
function PetComponent:GetPetWeight(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetWeight failed, petId = %s", petId)
        return 0
    end
    return pet:GetDerivedWeight()
end

--获取宠物缩放
function PetComponent:GetPetScale(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetScale failed, petId = %s", petId)
        return 0
    end
    return pet:GetDerivedScale()
end

--获取宠物售价
function PetComponent:GetPetSellPrice(petId)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetSellPrice failed, petId = %s", petId)
        return 0
    end
    return pet:CalculateSellPrice()
end

function PetComponent:GetPetSkillCD(petId, skillIndex)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetSkillCD failed, petId = %s", petId)
        return 0
    end
    return pet:GetSkillCD(skillIndex)
end

function PetComponent:GetPetSkillRemainingTime(petId, skillIndex)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetSkillRemainingTime failed, petId = %s", petId)
        return 0
    end
    return pet:GetSkillRemainingTime(skillIndex)
end

--设置宠物昵称
function PetComponent:SetPetNickName(petId, nickName)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("SetPetNickName failed, petId = %s", petId)
        return
    end
    pet:SetNickName(nickName)
    if self:IsServer() then
        self:TRpcPetNickNameChanged(petId, nickName)
    end
    self.actor:Fire(self:IsServer(), "PetNickNameChanged", pet, nickName)
end

function PetComponent:GetPetNickName(petId)     
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("GetPetNickName failed, petId = %s", petId)
        return ""
    end
    return pet:GetNickName()
end

--更新
function PetComponent:OnDot(dt)
    if self:IsServer() then
        -- for _, summonPet in pairs(self.summonPets) do
        --     local pet = summonPet:GetPet()
        --     if Class.IsExpired(summonPet) then
        --         self.summonPets[pet] = nil
        --     elseif pet then
        --         self:OnPetDot(pet, summonPet, dt)
        --     end
        -- end
        for _, pet in pairs(self.pets) do
            if pet and pet.isSummoned then
                self:OnPetDot(pet, dt)
            end
        end
    else
        for _, pet in pairs(self.pets) do
            if pet and pet.isSummoned then
                pet:Update(dt)
            end
        end
    end
end 

function PetComponent:OnPetDot(pet, dt)
    local oldScale = pet:GetDerivedScale()
    local oldLevel = pet.level
    local oldExp = pet.exp
    local oldHunger = pet.hunger
    local oldWeight = pet:GetDerivedWeight()

    pet:Update(dt)

    local newScale = pet:GetDerivedScale()
    local newLevel = pet.level
    local newExp = pet.exp  
    local newHunger = pet.hunger
    local newWeight = pet:GetDerivedWeight()

    if self:IsServer() then
        local petId = pet.petId
        if oldLevel ~= newLevel then
            self:TRpcPetLevelChanged(petId, oldLevel, newLevel)
            self.actor:Fire(self:IsServer(), "PetLevelChanged", pet, oldLevel, newLevel)
            self:NotifyStatDirty()
        end
        if oldExp ~= newExp then
            self:TRpcPetExpChanged(petId, oldExp, newExp)
            self.actor:Fire(self:IsServer(), "PetExpChanged", pet, oldExp, newExp)
        end
        if oldHunger ~= newHunger then
            self:TRpcPetHungerChanged(petId, oldHunger, newHunger)
            self.actor:Fire(self:IsServer(), "PetHungerChanged", pet, oldHunger, newHunger)
            self:NotifyStatDirty()
        end
        if oldScale ~= newScale and newScale then
            local summonPet = self.summonPets[pet]
            if summonPet then
                summonPet.StatComponent:SetBaseValue("ActorScale", newScale)
            end
        end
        if oldWeight ~= newWeight then
            self.actor:Fire(self:IsServer(), "PetWeightChanged", pet, oldWeight, newWeight)
        end
    end
end


--------------------------------------------------------------
--重新计算宠物属性
function PetComponent:CalcStats()
    local petStats = {}
    for pet,summonPet in pairs(self.summonPets) do
        if summonPet:IsStatsEnabled() then
            local bonusStats = pet:GetBonusStats()
            if bonusStats then
                for k,v in pairs(bonusStats) do
                    if petStats[k] then
                        petStats[k] = petStats[k] + v
                    else
                        petStats[k] = v
                    end
                end
            end
        end
    end

    local ret = {}
    for k,v in pairs(petStats) do
        local newStat = Stat.New(k, v)
        table.insert(ret, newStat)
    end
    return ret
end

--通知buff属性变化
function PetComponent:NotifyStatDirty()
    if self.actor:IsServer() then
        self.actor.StatComponent:SetStatAffecterDirty("Pet")
    end
end
-----------------------------------------------------------------------

--序列化
function PetComponent:Serialize(data, purpose)
    data.version = self.version
    PetComponent.super.Serialize(self, data, purpose)
    data.pets = {}
    for i, v in ipairs(self.pets) do
        local petData = {}
        v:Serialize(petData, purpose)
        table.insert(data.pets, petData)
    end

    -- --保存已经召唤的宠物列表
    -- if self:IsServer() and purpose == "Save" then
    --     data.summonPets = {}
    --     for i, v in pairs(self.summonPets) do
    --         local summonPetData = {}
    --         v:Serialize(summonPetData, purpose)
    --         summonPetData.position = v:GetPosition():ToTable()
    --         table.insert(data.summonPets, summonPetData)
    --     end
    -- end
end

--反序列化
function PetComponent:Deserialize(data)
    self.version = data.version
    PetComponent.super.Deserialize(self, data)
    self.pets = {}
    for i, v in ipairs(data.pets) do
        local pet = Pet.New()
        pet:Init(v.tid, self.actor)
        pet:Deserialize(v)
        table.insert(self.pets, pet)
    end

    -- --恢复已经召唤的宠物列表
    -- if self:IsServer() then
    --     self.summonPets = {}
    --     if data.summonPets then
    --         for i, v in ipairs(data.summonPets) do
    --             local petId = v.petId
    --             local pet = self:GetPetById(petId)
    --             if pet then
    --                 local summonPet = self:SummonPet(pet)
    --                 if summonPet then
    --                     summonPet:Deserialize(v)
    --                     if v.position then
    --                         summonPet:SetPosition(Vec3.New(v.position[1], v.position[2], v.position[3]))
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end
end

function PetComponent:UpdateSummonPetCount()
    self.summonPetCount = 0
    for _, pet in pairs(self.pets) do
        if pet.isSummoned then
            self.summonPetCount = self.summonPetCount + 1
        end
    end
end

function PetComponent:SyncAllPets()
    if not self:IsServer() then
        return
    end
    local PetKismet = GFScript("PetModule.PetKismet")
    for _, pet in pairs(self.pets) do
        local summonPet = nil
        if pet.isFollowPet then
            summonPet = self:SummonFollowPet(pet, true)
        elseif pet.isSummoned then
            summonPet = self:SummonPet(pet, nil, true)
        end 
        if summonPet then
            local position = PetKismet:GetLandPosition(self.actor)
            summonPet:SetPosition(position)
        end
    end
end

function PetComponent:GetSummonPetCount()
    return self.summonPetCount
end

--设置宠物技能状态
function PetComponent:SetPetSkillState(petId, skillIndex, state)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("SetPetSkillState failed, petId = %s", petId)
        return
    end
    pet:SetSkillState(skillIndex, state)
    if self:IsServer() then
        self:TRpcPetSkillStateChanged(petId, skillIndex, state)
    end
    self.actor:Fire(self:IsServer(), "PetSkillStateChanged", pet, skillIndex, state)
end

function PetComponent:NotifySkillEventExecuted(petId, skillIndex, skillEventIndex)
    local pet = self:GetPetById(petId)
    if not pet then
        Log:Error("NotifySkillEventExecuted failed, petId = %s", petId)
        return
    end
    if self:IsServer() then
        self:TRpcNotifySkillEventExecuted(petId, skillIndex, skillEventIndex)
    end
    pet:NotifySkillEventExecuted(skillIndex)
    self.actor:Fire(self:IsServer(), "NotifySkillEventExecuted", pet, skillIndex, skillEventIndex)
end

function PetComponent:UpdatePet(pet)
    if self:IsClient() then
        local localPet = self:GetPetById(pet.petId)
        if localPet then
            localPet:Deserialize(pet)
        end
    end
end

-----------------------------------------Cmd-----------------------------------------
function PetComponent:CmdGetAllPets()
    self:TRpcSetPets(self.pets)
end

function PetComponent:CmdSummonPet(petId)
    self:SummonPetById(petId)
end

function PetComponent:CmdDestroySummonPet(petId)
    self:DestroySummonPetById(petId)
end

function PetComponent:CmdSummonFollowPet(petId)
    self:SummonFollowPetById(petId)
end

function PetComponent:CmdDestroySummonFollowPet()
    self:DestroySummonFollowPet()
end
    -----------------------------------------Rpc-----------------------------------------
function PetComponent:TRpcAddPet(pet)
    self:AddPet(pet)
end
function PetComponent:TRpcRemovePet(petId)
    self:RemovePetById(petId)
end

function PetComponent:TRpcGetAllPets(pets)
    self.pets = {}
    for _, pet in pairs(pets) do
        self:AddPet(pet)
    end
end

function PetComponent:TRpcPetLevelChanged(petId, oldLevel, newLevel)
    self:SetPetLevel(petId, newLevel)
end

function PetComponent:TRpcPetExpChanged(petId, oldExp, newExp)
    self:SetPetExp(petId, newExp)
end

function PetComponent:TRpcPetHungerChanged(petId, oldHunger, newHunger)
    self:SetPetHunger(petId, newHunger)
end

function PetComponent:TRpcPetNickNameChanged(petId, nickName)
    self:SetPetNickName(petId, nickName)
end

function PetComponent:TRpcSummonPet(summonId, petId)
    local summon = ActorManager:GetClientActor(summonId)
    local pet = self:GetPetById(petId)
    if pet then
        pet.isSummoned = true
    end
    if summon and pet then
        self.summonPets[pet] = summon
        self:UpdateSummonPetCount()
        pet:OnSummon(summon)
        self.actor:FireClient("SummonPet", pet, summon)

        summon:OnClientEvent("Destroy", function(actor)
            self:OnActorDestroyed(actor)
        end)
    end
end

function PetComponent:OnActorCreated(actor)
    if self:IsServer() then

    else
        if actor.masterId == self.actor.actorId and actor.petId then
            --这个是宠物
            local pet = self:GetPetById(actor.petId)
            if pet and pet.isSummoned and not self.summonPets[pet] then
                self.summonPets[pet] = actor
                if pet.isFollowPet then
                    self.followPet = actor
                end

                actor:OnClientEvent("Destroy", function(actor)
                    self:OnActorDestroyed(actor)
                end)
            end
        end
    end
end

function PetComponent:OnActorDestroyed(actor)
    if self.followPet == actor then
        self.followPet = nil
    end
    for k,v in pairs(self.summonPets) do
        if v == actor then
            self.summonPets[k] = nil
            break
        end
    end
    self:UpdateSummonPetCount()
end

function PetComponent:TRpcDestroySummonPet(petId)
    local pet = self:GetPetById(petId)
    if pet then
        pet.isSummoned = false
        pet.isFollowPet = false
        self:UpdateSummonPetCount()
        self.summonPets[pet] = nil
        pet:OnDestroySummon()
        self.actor:FireClient("DestroySummonPet", pet)
    end
end


function PetComponent:TRpcSummonFollowPet(summonId, petId)
    local summon = ActorManager:GetClientActor(summonId)
    local pet = self:GetPetById(petId)
    if pet then
        pet.isFollowPet = true
    end
    if summon then
        self.followPet = summon
    end
    self.actor:FireClient("SummonFollowPet", pet, summon)
end

function PetComponent:TRpcPetSkillStateChanged(petId, skillIndex, state)
    self:SetPetSkillState(petId, skillIndex, state)
end

function PetComponent:TRpcNotifySkillEventExecuted(petId, skillIndex, skillEventIndex)
    self:NotifySkillEventExecuted(petId, skillIndex, skillEventIndex)
end

function PetComponent:TRpcUpdatePet(pet)
    self:UpdatePet(pet)
end

return PetComponent