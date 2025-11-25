local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")

local ActorCondition = Class.New("ActorCondition")

--实例化
function ActorCondition:Constructor(config)
    self.condition = config
end

--初始化
function ActorCondition:Init()
end
--检查目标类型
function ActorCondition:CheckTargets(actor, condition, targetIndex)
    if condition == nil or actor == nil then
        return true
    end

    --判断索引位置是否合法
    if not Utils:IsNullOrZero(targetIndex) then
        if not Utils:IsNullOrZero(condition.targetStartIndex) and targetIndex < condition.targetStartIndex then
            return false
        end
        if not Utils:IsNullOrZero(condition.targetEndIndex) and targetIndex > condition.targetEndIndex then
            return false
        end
    end

    if condition.requiredTargets and #condition.requiredTargets > 0 then
        --判断是否是玩家
        if actor:IsPlayer() and not Utils:IsInTable(condition.requiredTargets, "Player") then
            return false
        end
        --判断是否是怪物
        if not actor:IsPlayer() and not Utils:IsInTable(condition.requiredTargets, "Monster") then
            return false
        end

        --判断是否是子弹
        if actor.__cname == "Projectile" and not Utils:IsInTable(condition.requiredTargets, "Projectile") then
            return false
        end
    end
    --判断是否有命中标签
    if condition.requiredCategories and #condition.requiredCategories > 0 then
        if not Utils:IsInTable(condition.requiredCategories, actor:GetCategory()) then
            return false
        end
    end

    return true
end
--检查状态
function ActorCondition:CheckStates(actor, condition)
    if condition == nil or actor == nil then
        return true
    end
    
    if condition.requiredStates and #condition.requiredStates > 0 then
        --判断自己是否活着
        if actor:IsDead() and Utils:IsInTable(condition.requiredStates, "Alive") then
            return false
        end
        --判断自己是否死亡
        if not actor:IsDead() and Utils:IsInTable(condition.requiredStates, "Dead") then
            return false
        end
        --判断是否击晕
        if not actor:IsStun() and Utils:IsInTable(condition.requiredStates, "Stun") then
            return false
        end
        --判断是否被沉默
        if not actor:IsSilence() and Utils:IsInTable(condition.requiredStates, "Silence") then
            return false
        end
        --判断是否被击飞
        if not actor:IsKnockUp() and Utils:IsInTable(condition.requiredStates, "KnockUp") then
            return false
        end
        --判断是否被击倒
        if not actor:IsKnockDown() and Utils:IsInTable(condition.requiredStates, "KnockDown") then
            return false
        end
        --判断是否在移动
        if not actor.AvatarComponent:IsMoving() and Utils:IsInTable(condition.requiredStates, "Run") then
            return false
        end
    end

    
    if condition.requiredNoStates and #condition.requiredNoStates > 0 then
        --判断自己是否活着
        if not actor:IsDead() and Utils:IsInTable(condition.requiredNoStates, "Alive") then
            return false
        end
        --判断自己是否死亡
        if actor:IsDead() and Utils:IsInTable(condition.requiredNoStates, "Dead") then
            return false
        end
        --判断是否击晕
        if actor:IsStun() and Utils:IsInTable(condition.requiredNoStates, "Stun") then
            return false
        end
        --判断是否被沉默
        if actor:IsSilence() and Utils:IsInTable(condition.requiredNoStates, "Silence") then
            return false
        end
        --判断是否被击飞
        if actor:IsKnockUp() and Utils:IsInTable(condition.requiredNoStates, "KnockUp") then
            return false
        end
        --判断是否被击倒
        if actor:IsKnockDown() and Utils:IsInTable(condition.requiredNoStates, "KnockDown") then
            return false
        end
        --判断是否在移动
        if actor.AvatarComponent:IsMoving() and Utils:IsInTable(condition.requiredNoStates, "Run") then
            return false
        end
    end

    return true
end
--检查Buff
function ActorCondition:CheckBuffs(actor, condition)
    if condition == nil or actor == nil then
        return true
    end
    
    local ret = true
    if condition.requiredBuffs and #condition.requiredBuffs > 0 then
        for _, buffTid in ipairs(condition.requiredBuffs) do
            if type(buffTid) == "table" then
                if actor.BuffComponent:GetBuffStack(buffTid.tid) < buffTid.stack then
                    ret = false
                    break
                end
            else
                if not actor.BuffComponent:HasBuff(buffTid) then
                    ret = false
                    break
                end
            end
        end
    end
    if ret then
        --判断不允许的Buff是否存在
        if condition.requiredNoBuffs and #condition.requiredNoBuffs > 0 then
            for _, buffTid in ipairs(condition.requiredNoBuffs) do
                if actor.BuffComponent:HasBuff(buffTid) then
                    ret = false
                    break
                end
            end
        end
    end
    return ret
end

--检查某个属性是否存在
function ActorCondition:CheckStat(actor, condition)
    if condition == nil or actor == nil then
        return true
    end
    if condition.requiredStats and #condition.requiredStats > 0 then
        for _,stat in ipairs(condition.requiredStats) do
            if actor.StatComponent:HasValue(stat) then
                return true
            end
        end
    end
    return true
end

--检查自己
function ActorCondition:CheckActor(actor, condition, targetIndex)
    return self:CheckTargets(actor, condition, targetIndex) and self:CheckStates(actor, condition) and self:CheckBuffs(actor, condition) and self:CheckStat(actor, condition)
end

--检查
function ActorCondition:Check(selfActor, targetActor, targetIndex)
    if self.condition == nil then
        return true
    end

    -- 触发比率
    if not Utils:IsNullOrZero(self.condition.triggerRate) then
        if Math:Random(0,100) > self.condition.triggerRate then
            return false
        end
    end
    
    return self:CheckActor(selfActor,self.condition.selfActor) and self:CheckActor(targetActor,self.condition.targetActor, targetIndex)
end


--加载配置
function ActorCondition:LoadConfig(config)
    self.condition = config
end


return ActorCondition