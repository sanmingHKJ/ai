local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local TableUtils = GFScript("CoreModule.TableUtils")
local Log = GFScript("CoreModule.Log")
local CombatNetProto = GFScript("CombatModule.CombatNetProto")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local ActorManager = GFScript("ActorModule.ActorManager")
local CombatDefines = GFScript("CombatModule.CombatDefines")
local CombatComponent = Class.New("CombatComponent", ActorComponent)

--自定义的伤害计算器
CombatComponent.DamageCalculater = nil
CombatComponent.HealCalculater = nil
CombatComponent.AngerCalculater = nil

--实例化
function CombatComponent:Constructor()
    self.fixedUpdateInterval = 0.2
    --重置间隔
    self.comboResetInterval = 2
    self.nextAutoComboResetTimeEnd = 0
    self.inheritCombo = 0
end

--初始化
function CombatComponent:Awake()
    CombatComponent.super.Awake(self)
end
--启动服务端
function CombatComponent:OnStartServer()

end
--启动客户端
function CombatComponent:OnStartClient()
    --监听消息
    self:ClientNetCallback(CombatNetProto.ResponseTakeDamage,self.OnResponseTakeDamage,self)
    self:ClientNetCallback(CombatNetProto.ResponseReceiveHeal,self.OnResponseReceiveHeal,self)
    self:ClientNetCallback(CombatNetProto.ResponseReceiveAnger,self.OnResponseReceiveAnger,self)
    self:ClientNetCallback(CombatNetProto.ResponseKill,self.OnResponseKill,self)
end

--更新服务端
function CombatComponent:FixedUpdateServer(dt)
    if self.nextAutoComboResetTimeEnd ~= 0 and Utils:GetServerTime() >= self.nextAutoComboResetTimeEnd then
        self.nextAutoComboResetTimeEnd = 0
        self:ResetCombo()
    end
end

--应用伤害，服务端函数
function CombatComponent:ApplyDamage(damageData)
    -- print("CombatComponent:ApplyDamage(): ")
    if self.actor:IsServer() then
        --触发事件
        self.actor:FireServer("ApplyDamage", damageData)
        damageData.causer:FireServer("ApplyCauseDamage", damageData)

        local result = {}
        local damage = damageData.damage
        --计算基础伤害，这可能是攻击力和防御力的差值
        local defenderDefense = damageData.target.StatComponent:GetValue("Defense")
        local baseDamage = damage - defenderDefense

        damage = baseDamage
        --构建伤害结果数据
        result.damage = damage--伤害值
        result.damageType = damageData.damageType--伤害类型
        result.isCritical = isCritical --是否暴击
        result.isDodge = false --是否闪避
        result.isBlock = false --是否格挡
        
        result.source = damageData.source --伤害来源技能或者其他源
        result.causer = damageData.causer--伤害来源
        result.target = damageData.target--伤害目标
        -- --buff造成的伤害
        -- if damageData.buff then
        --     result.buffId = damageData.buffId--伤害来源buffId
        -- end
        -- result.skillId = damageData.skillId--伤害来源技能id
        -- result.skillLevel = damageData.skillLevel--伤害来源技能等级
        result.hateValue = damageData.hateValue or 0
        --附加信息
        result.otherData = damageData.otherData
        
        if CombatComponent.DamageCalculater then
            CombatComponent.DamageCalculater(damageData,result)
        end
        -- if result.target:IsPlayer() then
        --     result.damage = 999999
        -- else
        --     result.damage = 2000
        -- end
        self:TakeDamage(result)
    end
end
--承受伤害，服务端函数
function CombatComponent:TakeDamage(damageResult)
    if not self.actor:IsServer() then
        return
    end

    if damageResult.target:IsDead() then
        return
    end

    --设置伤害来源
    damageResult.target.damager = damageResult.causer

    --是否无敌
    local invincible = self.actor.StatComponent:HasValue("BanDamage")
    if invincible then
        damageResult.damageType = CombatDefines.EDamageType.Invincible
        damageResult.damage = 0
    elseif damageResult.target.SkillComponent:IsAntiDamageState() then
        damageResult.damage = 0
    end
    --扣血
    if not invincible and self.actor.HealthComponent then
        self.actor.HealthComponent:SubValue(damageResult.damage)
    end
    --仇恨
    if damageResult.causer ~= self.actor and damageResult.hateValue > 0 and self.actor.HateComponent then
        self.actor.HateComponent:ServerAddHate(damageResult.causer, damageResult.hateValue)
    end
    --记录连击
    if damageResult.source.type == CombatDefines.EDamageSourceType.Skill then
        damageResult.causer.CombatComponent:AddCombo(1)
    elseif damageResult.source.type == CombatDefines.EDamageSourceType.Buff then
        local buff = damageResult.source.buff
        local buffData = buff.data
        if buffData.isCombo then
            damageResult.causer.CombatComponent:AddCombo(1)
        end
    end
    --触发事件
    damageResult.causer:FireServer("BeforeCauseDamage",damageResult)
    damageResult.causer:FireServer("CauseDamage",damageResult)

    --触发事件
    self.actor:FireServer("BeforeTakeDamage",damageResult)
    self.actor:FireServer("TakeDamage",damageResult)



    -- print("CombatComponent:TakeDamage(): damageResult = ", TableUtils:ToString(damageResult))
    --广播伤害消息
    local body = {
        source = {
            type = damageResult.source.type,
            tid = damageResult.source.tid,
        },
        causerActorId = damageResult.causer:GetActorId(),--伤害来源
        targetActorId = damageResult.target:GetActorId(),--伤害目标
        damage = damageResult.damage,--伤害值
        damageType = damageResult.damageType,--伤害类型

        isCritical = damageResult.isCritical, --是否暴击
        isDodge = damageResult.isDodge, --是否闪避
        isBlock = damageResult.isBlock, --是否格挡
        otherData = damageResult.otherData,--附加信息
    }
    self:SendToObservers(CombatNetProto.ResponseTakeDamage, body)

    -- print("CombatComponent:TakeDamage(): self.actor = ", self.actor)
    if damageResult.target:IsDead() then
        -- print("CombatComponent:TakeDamage(): damageResult.target = ", damageResult.target)
        damageResult.causer:FireServer("Kill", damageResult.target)
        local body = {
            causerActorId = damageResult.causer:GetActorId(),--伤害来源
            targetActorId = damageResult.target:GetActorId(),--伤害目标
        }
        self:SendToAllClients(CombatNetProto.ResponseKill, body)
    elseif damageResult.target.SkillComponent:IsAntiDamageState() then
        --判断是否是反伤状态
        damageResult.target.SkillComponent:OnAntiDamage(damageResult.causer)
    elseif damageResult.target.BuffComponent:IsAntiDamageState() then
        --判断是否是反伤状态
        damageResult.target.BuffComponent:OnAntiDamage(damageResult.causer)
    end

    damageResult.causer:FireServer("AfterCauseDamage",damageResult)
    self.actor:FireServer("AfterTakeDamage",damageResult)
end
--应用治疗
function CombatComponent:ApplyHeal(healData)
    if self.actor:IsServer() then
        --触发事件
        self.actor:FireServer("ApplyHeal", healData)
        healData.causer:FireServer("ApplyCauseHeal", healData)

        local result = {}
        local heal = healData.heal
        --构建治疗结果数据
        result.heal = heal--治疗值
        result.isCritical = isCritical --是否暴击
        
        result.source = healData.source --治疗来源技能或者其他源
        result.causer = healData.causer--治疗来源
        result.target = healData.target--治疗目标
        
        result.hateValue = healData.hateValue or 0
        --附加信息
        result.otherData = healData.otherData
        
        if CombatComponent.HealCalculater then
            CombatComponent.HealCalculater(healData, result)
        end
        
        self:ReceiveHeal(result)
    end
end

--应用治疗，服务端函数
function CombatComponent:ReceiveHeal(healResult)
    if not self.actor:IsServer() then
        return
    end

    if healResult.target:IsDead() then
        return
    end

    --设置治疗来源
    healResult.target.healer = healResult.causer

    --回血
    if self.actor.HealthComponent then
        healResult.heal = self.actor.HealthComponent:AddValue(healResult.heal)
    end
    --仇恨
    if healResult.causer ~= self.actor and healResult.hateValue > 0 and self.actor.HateComponent then
        self.actor.HateComponent:ServerAddHate(healResult.causer, healResult.hateValue)
    end

    --触发事件
    healResult.causer:FireServer("BeforeCauseHeal",healResult)
    healResult.causer:FireServer("CauseHeal",healResult)

    --触发事件
    self.actor:FireServer("BeforeReceiveHeal",healResult)
    self.actor:FireServer("ReceiveHeal",healResult)

    --广播治疗消息
    local body = {
        source = {
            type = healResult.source.type,
            tid = healResult.source.tid,
        },
        causerActorId = healResult.causer:GetActorId(),--治疗来源
        targetActorId = healResult.target:GetActorId(),--治疗目标
        heal = healResult.heal,--治疗值

        isCritical = healResult.isCritical, --是否暴击
        otherData = healResult.otherData,--附加信息
    }
    self:SendToObservers(CombatNetProto.ResponseReceiveHeal, body)

    healResult.causer:FireServer("AfterCauseHeal",healResult)
    self.actor:FireServer("AfterReceiveHeal",healResult)
end

--应用能量
function CombatComponent:ApplyAnger(angerData)
    if self.actor:IsServer() then
        --触发事件
        self.actor:FireServer("ApplyAnger", angerData)

        local result = {}
        --构建治疗结果数据
        result.anger = angerData.anger--治疗值
        result.isCritical = isCritical --是否暴击
        
        result.source = angerData.source --治疗来源技能或者其他源
        result.causer = angerData.causer--治疗来源
        result.target = angerData.target--治疗目标
        
        result.hateValue = angerData.hateValue or 0
        --附加信息
        result.otherData = angerData.otherData
        
        if CombatComponent.AngerCalculater then
            CombatComponent.AngerCalculater(angerData, result)
        end
        
        self:ReceiveAnger(result)
    end
end

--应用能量，服务端函数
function CombatComponent:ReceiveAnger(angerResult)
    if not self.actor:IsServer() then
        return
    end

    if angerResult.target:IsDead() then
        return
    end

    --设置治疗来源
    angerResult.target.healer = angerResult.causer

    --回能量
    if self.actor.AngerComponent then
        self.actor.AngerComponent:AddValue(angerResult.anger)
    end
    --仇恨
    if angerResult.causer ~= self.actor and angerResult.hateValue > 0 and self.actor.HateComponent then
        self.actor.HateComponent:ServerAddHate(angerResult.causer, angerResult.hateValue)
    end

    --触发事件
    angerResult.causer:FireServer("CauseAnger",angerResult)
    self.actor:FireServer("ReceiveAnger",angerResult)

    --广播治疗消息
    local body = {
        source = {
            type = angerResult.source.type,
            tid = angerResult.source.tid,
        },
        causerActorId = angerResult.causer:GetActorId(),--治疗来源
        targetActorId = angerResult.target:GetActorId(),--治疗目标
        anger = angerResult.anger,--能量值

        isCritical = angerResult.isCritical, --是否暴击
        otherData = angerResult.otherData,--附加信息
    }
    self:SendToObservers(CombatNetProto.ResponseReceiveAnger, body)
end

--扣除法力值
function CombatComponent:TakeMana(mana)
    if type(mana) == "number" then
        return self.actor.ManaComponent:SubValue(mana, true)
    end
    return false
end
--扣除怒气值
function CombatComponent:TakeAnger(anger)
    if type(anger) == "number" then
        return self.actor.AngerComponent:SubValue(anger, true)
    end
    return false
end
--扣除体力值
function CombatComponent:TakeStamina(stamina)
    if type(stamina) == "number" then
        return self.actor.StaminaComponent:SubValue(stamina, false)
    end
    return false
end
--应用攻击效果
function CombatComponent:ApplyHitEffect(effect)
    self:ApplyHitEffect(effect)
end
--是否是敌对关系
function CombatComponent:IsEnemy(target)
    local relation = self.actor.CampComponent:GetRelation(target.CampComponent)
    return relation == "Enemy"
end
------------------------------------Client-------------------------------------
--收到伤害战报
function CombatComponent:OnResponseTakeDamage(body)
    -- print("CombatComponent:OnResponseTakeDamage(): ")
    local causer = nil
    local target = nil

    local result = {}
    result.causer = ActorManager:GetClientActor(body.causerActorId)--伤害来源
    result.target = ActorManager:GetClientActor(body.targetActorId)--伤害目标
    result.damage = body.damage--伤害值
    result.damageType = body.damageType--伤害类型
    result.source = body.source
    result.isCritical = body.isCritical --是否暴击
    result.isDodge = body.isDodge --是否闪避
    result.isBlock = body.isBlock --是否格挡
    result.otherData = body.otherData --受击特效

    --触发事件
    if result.causer and result.target then
        result.causer:FireClient("CauseDamage",result)
        result.target:FireClient("TakeDamage",result)
    end
end

--收到治疗事件
function CombatComponent:OnResponseReceiveHeal(body)
    -- print("CombatComponent:OnResponseReceiveHeal(): ")
    local causer = ActorManager:GetClientActor(body.causerActorId)--治疗来源
    local target = ActorManager:GetClientActor(body.targetActorId)--治疗目标
    local heal = body.heal or 0--治疗值
    local isCritical = body.isCritical --是否暴击
    local otherData = body.otherData --附加信息
    local result = {
        heal = heal,
        isCritical = isCritical,
        otherData = otherData
    }

    --触发事件
    if causer and target then
        causer:FireClient("CauseHeal",result)
        target:FireClient("ReceiveHeal",result)
    end
end

--收到回复能量事件
function CombatComponent:OnResponseReceiveAnger(body)
    -- print("CombatComponent:OnResponseReceiveAnger(): ")
    local causer = ActorManager:GetClientActor(body.causerActorId)--治疗来源
    local target = ActorManager:GetClientActor(body.targetActorId)--治疗目标
    local anger = body.anger or 0--能量值
    local isCritical = body.isCritical --是否暴击
    local otherData = body.otherData --附加信息
    local result = {
        anger = anger,
        isCritical = isCritical,
        otherData = otherData
    }

    --触发事件
    if causer and target then
        causer:FireClient("CauseAnger",result)
        target:FireClient("ReceiveAnger",result)
    end
end

--收到击杀事件
function CombatComponent:OnResponseKill(body)
    -- print("CombatComponent:OnResponseKill(): ")
    local causer = ActorManager:GetClientActor(body.causerActorId)--伤害来源
    local target = ActorManager:GetClientActor(body.targetActorId)--击杀目标

    --触发事件
    if causer and target then
        causer:FireClient("Kill",target)
        target:FireClient("KilledBy", causer)
    end
end

--添加连击
function CombatComponent:AddCombo(count)
    self.actor.StatComponent:SetSimpleValue("Combo", self:GetCombo() + count)
    self.inheritCombo = 0
    self.nextAutoComboResetTimeEnd = Utils:GetServerTime() + self.comboResetInterval
end

--获取连击
function CombatComponent:GetCombo()
    if self.inheritCombo ~= 0 then
        return self.inheritCombo
    end
    return self.actor.StatComponent:GetValue("Combo")
end

--重置连击
function CombatComponent:ResetCombo()
    self.inheritCombo = 0
    self.actor.StatComponent:SetSimpleValue("Combo", 0)
end

--设置连击重置间隔
function CombatComponent:SetComboResetInterval(interval)
    self.comboResetInterval = interval
end

function CombatComponent:CopyFrom(comp)
    CombatComponent.super.CopyFrom(self, comp)
    if self.actor:IsServer() then
        self.nextAutoComboResetTimeEnd = comp.nextAutoComboResetTimeEnd
        self.comboResetInterval = comp.comboResetInterval
        self.inheritCombo = comp.actor.StatComponent:GetValue("Combo")
    end
end

--杀死自己
function CombatComponent:Kill()
    local hp = self.actor.HealthComponent:GetValue()

    local damageResult = {}
    damageResult.source = {
        type = CombatDefines.EDamageSourceType.Skill,
        tid = "Self",
    }
    damageResult.causer = self.actor
    damageResult.target = self.actor
    damageResult.damage = hp
    damageResult.damageType = CombatDefines.EDamageType.TrueDamage
    damageResult.isCritical = false
    damageResult.isDodge = false
    damageResult.isBlock = false
    damageResult.otherData = {}

    --触发事件
    damageResult.causer:FireServer("CauseDamage",damageResult)
    self.actor:FireServer("TakeDamage",damageResult)

    --扣血
    if self.actor.HealthComponent then
        self.actor.HealthComponent:SubValue(hp)
    end

    --广播伤害消息
    local body = {
        source = {
            type = damageResult.source.type,
            tid = damageResult.source.tid,
        },
        causerActorId = damageResult.causer:GetActorId(),--伤害来源
        targetActorId = damageResult.target:GetActorId(),--伤害目标
        damage = damageResult.damage,--伤害值
        damageType = damageResult.damageType,--伤害类型

        isCritical = damageResult.isCritical, --是否暴击
        isDodge = damageResult.isDodge, --是否闪避
        isBlock = damageResult.isBlock, --是否格挡
        otherData = damageResult.otherData,--附加信息
    }
    self:SendToObservers(CombatNetProto.ResponseTakeDamage, body)

    self.actor:FireServer("Kill", self.actor)
    local body = {
        causerActorId = damageResult.causer:GetActorId(),--伤害来源
        targetActorId = damageResult.target:GetActorId(),--伤害目标
    }
    self:SendToAllClients(CombatNetProto.ResponseKill, body)
end

return CombatComponent