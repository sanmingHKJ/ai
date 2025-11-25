local Log = GFScript("CoreModule.Log")

local CombatDefines = {}

--伤害类型枚举
CombatDefines.EDamageType = 
{
    Invincible = "Invincible", --无敌
    Physical = "Physical", --物理伤害
    Heal = "Heal", --治疗
    Wind = "Wind", --风系伤害
    Thunder = "Thunder", --雷系伤害
    Fire = "Fire", --火系伤害
    Ice = "Ice", --冰系伤害
    Lightning = "Lightning", --闪电伤害
    Poison = "Poison", --毒系伤害
    Water = "Water", --水系伤害
    Soil = "Soil", --土系伤害
    Holy = "Holy", --神圣伤害
    Shadow = "Shadow", --暗影伤害
    TrueDamage = "TrueDamage", --真实伤害
}

--魔法伤害
CombatDefines.EMagicType = 
{
    [CombatDefines.EDamageType.Wind] = "Wind", --风系伤害
    [CombatDefines.EDamageType.Thunder] = "Thunder", --雷系伤害
    [CombatDefines.EDamageType.Fire] = "Fire", --火系伤害
    [CombatDefines.EDamageType.Ice] = "Ice", --冰系伤害
    [CombatDefines.EDamageType.Lightning] = "Lightning", --闪电伤害
    [CombatDefines.EDamageType.Poison] = "Poison", --毒系伤害
    [CombatDefines.EDamageType.Water] = "Water", --水系伤害
    [CombatDefines.EDamageType.Soil] = "Soil", --土系伤害
    [CombatDefines.EDamageType.Holy] = "Holy", --神圣伤害
    [CombatDefines.EDamageType.Shadow] = "Shadow", --暗影伤害
}

--是否魔法伤害
function CombatDefines:IsMagicDamage(damageType)
    return CombatDefines.EMagicType[damageType] ~= nil
end

CombatDefines.EOtherType = 
{
    Health = "Health", --回血
}

--伤害来源类型
CombatDefines.EDamageSourceType = 
{
    Skill = "Skill", --技能伤害
    Buff = "Buff", --buff伤害
    Item = "Item", --物品伤害
}

return CombatDefines