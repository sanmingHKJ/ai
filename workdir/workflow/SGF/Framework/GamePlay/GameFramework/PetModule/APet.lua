local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local PetSettings = GFScript("PetModule.PetSettings")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local PetManager = GFScript("PetModule.PetManager")

local Npc = GFScript("ActorModule.Npc")

-- 宠物
local APet = Npc.Extend("APet")

function APet:Constructor()
    self.skills = {}
end

function APet:Destructor()
    self:ClearAllSkills()
end

function APet:InitServer()
    APet.super.InitServer(self)
end

function APet:Update(dt)
    APet.super.Update(self, dt)
end
--更新
function APet:LaterUpdate(dt)
    APet.super.LaterUpdate(self, dt)
end

--从tid加载数据
function APet:GetConfigName()
    return ActorUtils:GetActorTable(ActorDefines.EActorType.Pet).Actor
end

function APet:AddSkill(skillTid)
    local skillConfig = ConfigManager:GetConfig(PetSettings.Table.PetSkill, skillTid)
    if skillConfig then
        local skillFactory = PetManager:GetSkillFactory(skillConfig.type)
        if skillFactory then
            local skill = skillFactory:New()
            skill:Init(self, skillConfig)
            table.insert(self.skills, skill)
            return skill
        end
    end
    return nil
end

function APet:ClearAllSkills()
    for _, skill in ipairs(self.skills) do
        skill:Destroy()
    end
    self.skills = {}
end

--加载配置
function APet:OnLoadConfig(config)
    APet.super.OnLoadConfig(self, config)

    self.skills = {}
    for _, skillTid in ipairs(config.skills) do
        self:AddSkill(skillTid)
    end
end

return APet