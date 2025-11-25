local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local PlayerManager = require(script.Parent.PlayerManager)
local Player = require(script.Parent.Player)
-- Config is available via MS.Config (loaded in Global.lua)

local CombatKismet = {}

--[Server]生成伤害
--@param damageType 伤害类型
--@param value 伤害值
--@return 伤害
function CombatKismet:GenerateDamage(attackerId, targetId, skillId)
    if Utils:IsServer() then
        local attacker = PlayerManager:GetPlayer(attackerId)
        local target = PlayerManager:GetPlayer(targetId)
        if attacker and target then
            local damage = {}
            damage.attackerId = attackerId
            damage.targetId = targetId
            damage.skillId = skillId
            damage.damageType = 1
            damage.value = 100
            return damage
        end
    end
    return nil
end


--[Server]应用伤害
--@param attackerId 攻击者ID
--@param targetId 目标ID
--@param damage 伤害值，可以是一个table，包含伤害类型和数值等
--@return 是否成功
function CombatKismet:ApplyDamage(attackerId, targetId, damage)
    if Utils:IsServer() then
        local attacker = PlayerManager:GetPlayer(attackerId)
        local target = PlayerManager:GetPlayer(targetId)
        if attacker and target then
            target:ApplyDamage(attacker, damage)
            return true
        end
    end
    return false
end

--[Server]直接拿走伤害
--@param targetId 目标ID
--@param damage 伤害值，可以是一个table，包含伤害类型和数值等
--@return 是否成功
function CombatKismet:TakeDamage(targetId, damage)
    if Utils:IsServer() then
        local target = PlayerManager:GetPlayer(targetId)
        if target then
            target:TakeDamage(damage)
            return true
        end
    end
    return false
end


return CombatKismet