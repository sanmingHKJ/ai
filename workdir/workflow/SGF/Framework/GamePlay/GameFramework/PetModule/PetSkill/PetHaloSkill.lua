local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigLoaderSetup = GFScript("CoreModule.ConfigLoaderSetup")
local PetSkill = GFScript("PetModule.PetSkill")
local PetSettings = GFScript("PetModule.PetSettings")
local TimerManager = GFScript("CoreModule.TimerManager")
local PetKismet = GFScript("PetModule.PetKismet")
local PetHaloSkill = Class.New("PetHaloSkill", PetSkill)

--实例化
function PetHaloSkill:Constructor()

    self.haloTimer = nil

    --进入列表
    self.enterTargets = {}
end

function PetHaloSkill:Destructor()
    if self.haloTimer then
        TimerManager:RemoveTimer(self.haloTimer)
        self.haloTimer = nil
    end
end

function PetHaloSkill:Init(pet, data, skillIndex)
    PetHaloSkill.super.Init(self, pet, data, skillIndex)

    self.haloTimer = TimerManager:AddTimer(function()
        self:OnHalo()
    end, 1)
end

function PetHaloSkill:OnHalo()
    local targets = self:OverlapTargets()
    --判断离开
    for idx = #self.enterTargets, 1, -1 do
        local target = self.enterTargets[idx]
        local found = false
        for _, target2 in ipairs(targets) do
            if target2 == target then
                found = true
                break
            end
        end
        if not found then
            self:OnLeave(target)
        end
    end 

    --判断进入
    for idx = #targets, 1, -1 do
        local target = targets[idx]
        local found = false
        for idx2 = #self.enterTargets, 1, -1 do
            local target2 = self.enterTargets[idx2]
            if target2 == target then
                found = true
                break
            end
        end
   
        if not found then
            self:OnEnter(target)
        end
    end

    self.enterTargets = targets


    return true
end

function PetHaloSkill:OnEnter(target)
    local pet = self.pet:GetPet()       
    if not pet then
        return
    end
    PetKismet:PetEnter(pet, target)
end

function PetHaloSkill:OnLeave(target)
    local pet = self.pet:GetPet()       
    if not pet then
        return
    end
    PetKismet:PetLeave(pet, target)
end

function PetHaloSkill:OverlapTargets()  
    local player = self:GetPlayer()
    if not player then
        return {}
    end
    local pet = self.pet:GetPet()
    if not pet then
        return {}
    end
    local radius = pet:GetStatValue("FruitGrowthRadius")   
    if not radius or radius <= 0 then
        return {}
    end
    return PetKismet:GetTargetInRange(player, self.pet:GetPosition(), radius)
end

--序列化
function PetHaloSkill:Serialize(data, purpose)
    PetHaloSkill.super.Serialize(self, data, purpose)
end

--反序列化
function PetHaloSkill:Deserialize(data)
    PetHaloSkill.super.Deserialize(self, data)
end

return PetHaloSkill