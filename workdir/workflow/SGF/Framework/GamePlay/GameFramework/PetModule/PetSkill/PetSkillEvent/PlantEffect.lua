local Math = GFScript("CoreModule.Math")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local PetSkillEvent = GFScript("PetModule.PetSkill.PetSkillEvent")
local PetKismet = GFScript("PetModule.PetKismet")

local PlantEffect = PetSkillEvent.Extend("PlantEffect")

function PlantEffect:Execute()
    PlantEffect.super.Execute(self)
    --效果
    local radius = self:GetDerivedValue("radius")  
    local effectType = self:GetDerivedValue("effectType")
    if type(effectType) == "table" then
        effectType = effectType[math.random(1, #effectType)]
    end
    PetKismet:PlantEffect(self.player, self.petActor:GetPosition(), radius, effectType)
    if self.petActor then
        local tips = "崽崽发动能力了，你的庄园内有果实发生了变化"
        self.petActor:ShowTip(tips)
    end
end

return PlantEffect