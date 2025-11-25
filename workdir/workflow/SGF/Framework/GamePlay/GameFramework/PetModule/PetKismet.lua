local ActorManager = GFScript("ActorModule.ActorManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local PetKismet = {}

local MainStorage = game:GetService("MainStorage")
-- 加载配置
local GardenConfig = require(MainStorage:WaitForChild("GardenConfig"))

--客户端召唤宠物
function PetKismet:ClientSummonPet(petId)
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer then
        localPlayer.PetComponent:CmdSummonPet(petId)
    end
end

--客户端销毁宠物
function PetKismet:ClientDestroyPet(petId)
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer then
        localPlayer.PetComponent:CmdDestroySummonPet(petId)
    end
end

--客户端召唤宠物
function PetKismet:ClientSummonFollowPet(tid)
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer then
        localPlayer.PetComponent:CmdSummonFollowPet(tid)
    end
end

--客户端销毁宠物
function PetKismet:ClientDestroyFollowPet()
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer then
        localPlayer.PetComponent:CmdDestroySummonFollowPet()
    end
end

--召唤宠物
function PetKismet:SummonPet(player, petId)
    player = player or ActorManager:GetLocalPlayer()
    if player:IsServer() then
        return player.PetComponent:SummonPetById(petId)
    else
        player.PetComponent:CmdSummonPet(petId)
    end
end

--销毁宠物
function PetKismet:DestroySummonPet(player, petId)
    player = player or ActorManager:GetLocalPlayer()
    if player:IsServer() then
        return player.PetComponent:DestroySummonPetById(petId)
    else
        player.PetComponent:CmdDestroySummonPet(petId)
    end
end

--召唤跟随宠物
function PetKismet:SummonFollowPet(player, petId) 
    player = player or ActorManager:GetLocalPlayer()
    if player:IsServer() then
        return player.PetComponent:SummonFollowPetById(petId)
    else
        player.PetComponent:CmdSummonFollowPet(petId)
    end
end

--销毁跟随宠物
function PetKismet:DestroySummonFollowPet(player)
    player = player or ActorManager:GetLocalPlayer()
    if player:IsServer() then
        return player.PetComponent:DestroySummonFollowPet()
    else
        player.PetComponent:CmdDestroySummonFollowPet()
    end
end

-- 获取召唤宠物数量
function PetKismet:GetSummonPetCount(player)
    player = player or ActorManager:GetLocalPlayer()
    if player then
        return player.PetComponent:GetSummonPetCount()
    end
    return 0
end

-- 更新宠物数量
function PetKismet:UpdateSummonPetCount(player)
    player = player or ActorManager:GetLocalPlayer()
    if player then
        return player.PetComponent:UpdateSummonPetCount()
    end
    return 0
end

--获取最大召唤宠物数量
function PetKismet:GetMaxSummonPetCount(player)
    player = player or ActorManager:GetLocalPlayer()
    if player then
        return player.PetComponent:GetMaxSummonPetCount()
    end
    return 0
end

--设置饥饿值
function PetKismet:SetPetHunger(player, petId, hunger)  
    if not player:IsServer() then
        Log:Error("SetPetHunger failed, not server")
        return
    end
    player.PetComponent:SetPetHunger(petId, hunger)
end

function PetKismet:SetPetNickName(player, petId, nickName)
    if not player:IsServer() then
        Log:Error("SetPetNickName failed, not server")
        return
    end
    player.PetComponent:SetPetNickName(petId, nickName)
end

--获取饥饿值
function PetKismet:GetPetHunger(player, petId)
    return player.PetComponent:GetPetHunger(petId)
end

--获取最大饥饿值
function PetKismet:GetMaxPetHunger(player, petId)
    return player.PetComponent:GetMaxPetHunger(petId)
end

--获取宠物技能cd
function PetKismet:GetPetSkillCD(player, petId, skillIndex) 
    return player.PetComponent:GetPetSkillCD(petId, skillIndex)
end

--获取宠物技能剩余时间
function PetKismet:GetPetSkillRemainingTime(player, petId, skillIndex)
    return player.PetComponent:GetPetSkillRemainingTime(petId, skillIndex)
end

--获取宠物的售价
function PetKismet:GetPetSellPrice(player, petId)
    return player.PetComponent:GetPetSellPrice(petId)
end

--获取宠物体重
function PetKismet:GetPetWeight(player, petId)
    return player.PetComponent:GetPetWeight(petId)
end

--获取宠物缩放
function PetKismet:GetPetScale(player, petId)
    return player.PetComponent:GetPetScale(petId)
end

--获取宠物等级
function PetKismet:GetPetLevel(player, petId)
    return player.PetComponent:GetPetLevel(petId)
end 

--获取宠物经验
function PetKismet:GetPetExp(player, petId)
    return player.PetComponent:GetPetExp(petId)
end

--获取宠物升级所需经验
function PetKismet:GetPetUpgradeExp(player, petId)
    return player.PetComponent:GetPetUpgradeExp(petId)
end

--获取宠物技能描述
function PetKismet:GetPetSkillDesc(player, petId, skillIndex)
    return player.PetComponent:GetPetSkillDesc(petId, skillIndex)
end

function PetKismet:ForEachPets(player, func)
    player.PetComponent:ForEachPets(func)
end

function PetKismet:ForEachSummonPets(player, func)
    player.PetComponent:ForEachSummonPets(func)
end

--播放音效
function PetKismet:PlayPetVoice(player, petId, audioName, is3D)
    is3D = is3D ~= false
    local petActor = player.PetComponent:GetSummonPetById(petId)
    if petActor then
        petActor:PlayVoice(audioName, is3D)
    end
end

--播放动作
function PetKismet:PlayPetMontage(player, petId, montageName)
    local petActor = player.PetComponent:GetSummonPetById(petId)
    if petActor then
        petActor.AvatarComponent:PlayMontage(montageName)
    end
end

--是否已经召唤跟随宠物
function PetKismet:IsFollowPet(player, petId)
    local pet = player.PetComponent:GetPetById(petId)
    if pet then
        return player.PetComponent:IsFollowPet(pet)
    end
    return false
end

--是否已经召唤宠物
function PetKismet:IsSummonPet(player, petId)
    local pet = player.PetComponent:GetPetById(petId)
    if pet then
        return player.PetComponent:IsSummonPet(pet)
    end
    return false
end

--获取跟随的宠物
function PetKismet:GetFollowPet(player)
    return player.PetComponent:GetFollowPet()
end


--获取范围内的植物
function PetKismet:GetTargetInRange(player, pos, range)
    local plants = XPlants.CropSystem:GetPlantsByRange(player:GetPlayerId(), Vector3.New(pos.x, pos.y, pos.z), range)
    return plants
end

--获取玩家土地位置
function PetKismet:GetLandPosition(player)
    local landData = XPlants.LandExpansion:GetLand(player.bindObj)
    if landData and landData.Position then
        return Vec3.New(landData.Position.x, landData.Position.y, landData.Position.z)
    end
    return nil
end

--通知宠物进入植物范围
--适用情况
--1.猫咪5米范围内的树干果实，果实生长速度提升 47%
function PetKismet:PetEnter(pet, target)
    if pet.petId and pet.petId > 0 then
        if target.affectPets == nil then
            target.affectPets = {}
        end
        target.affectPets[pet.petId] = pet.petId
    end
end

--通知宠物离开植物范围  
function PetKismet:PetLeave(pet, target)
    if pet.petId and pet.petId > 0 then
        if target.affectPets ~= nil then
            target.affectPets[pet.petId] = nil
        end
    end
end

--获取宠物属性值
function PetKismet:GetPetStatValue(player, petId, statName)
    local pet = player.PetComponent:GetPetById(petId)
    if pet then
        return pet:GetStatValue(statName)
    end
    return 0
end

--宠物拾取物品
--适用情况
--1.宠每60分钟，偷取一个低级品质工具（98%概率获得珍稀2品质的工具*1，2%概率获得神圣6品质的工具*1）
--2.每40分钟会跑向一名玩家，帮你偷取一笔钱回来（500~1500随机）
--3.每60分钟，偷取一个低级品质工具（98%概率获得珍稀2品质种子*1，2%概率获得神圣6品质的工具*1）
function PetKismet:PetLootItems(pet, player, items)

end

--宠物拾取工具
function PetKismet:PetLootTool(pet, player, chance)
    local toolId = GardenConfig.StealToolByPet(chance)
    if toolId then
        XPlants.Backpack:AddItemByItemId(player.bindObj, toolId, 1, "PetLootToolSkill")
    end
end

--宠物拾取种子
function PetKismet:PetLootSeed(pet, player, chance)
    local seedId = GardenConfig.StealSeedByPet(chance)
    if seedId then
        XPlants.Backpack:AddItemByItemId(player.bindObj, seedId, 1, "PetLootSeedSkill")
    end

end



--变异  
function PetKismet:PlantEffect(player, pos, radius, effectType)
    -- local plants = XPlants.CropSystem:GetPlantsByRange(player:GetPlayerId(), Vector3.New(pos.x, pos.y, pos.z), radius)
    -- for _, plant in ipairs(plants) do
    --     --TODO:变异
    --     Log:Error("PlantMutate ".. mutateType)
    -- end

    -- local fruit = XPlants.CropSystem:GetRandomFruit(player:GetPlayerId())
    -- if fruit then
    --     XPlants.CropSystem:AddEffectToFruit(fruit, effectType)
    -- end
    XPlants.CropSystem:AddEffectToRandomFruit(player:GetPlayerId(), effectType)
end

return PetKismet