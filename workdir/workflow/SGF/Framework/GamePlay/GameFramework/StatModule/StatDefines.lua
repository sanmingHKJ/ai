local StatDefines = {}

--内置属性定义
-- Level - 等级
-- Health - 生命值
-- MaxHealth
-- HealthRegen --生命值恢复
-- Mana - 法力值
-- MaxMana
-- HealthRegen --法力值恢复
-- Anger - 怒气
-- MaxAnger
-- AngerRegen --怒气恢复
-- AngerCharge --怒气充能
-- Stamina --耐力
-- MaxStamina
-- StaminaRegen --耐力恢复
-- StaminaConsumeCoef --耐力消耗系数
-- Attack - 攻击力
-- Pierce - 穿透
-- Defense - 防御力
-- Critical - 暴击
-- CriticalDamage - 暴击伤害
-- Dodge - 闪避
-- Hit - 命中
-- Block - 格挡
-- BlockDamage - 格挡伤害
-- Speed - 速度
-- AttackSpeed - 攻击速度
-- Tenacity - 韧性
-- Stiff - 硬直
-- Resist - 抗性
-- LifeSteal - 生命偷取
-- LockWeight - 锁敌权重
-- LockWeightMul - 锁敌权重倍率

-- Combo - 连击

-- MoveSpeed - 移动速度

-- ElemMul - 元素伤害倍率（元素力）

--外观类属性
-- ActorScale - 角色缩放
-- ActorAlpha - 角色透明度
-- ActorRim - 角色边缘光
-- ActorCameraZoom - 角色镜头缩放
-- ActorCameraOffsetX - 角色镜头偏移
-- ActorCameraYScale - 角色镜头Y轴缩放
-- ActorCameraFixed - 角色镜头固定
-- ActorUseCameraYaw - 角色使用镜头Yaw


-- DamageReduction - 伤害减免
-- DamageIncrease - 伤害增加
-- DamageReductionRate - 伤害减免率
-- DamageIncreaseRate - 伤害增加率
-- DamageReductionValue - 伤害减免值
-- DamageIncreaseValue - 伤害增加值
-- FireResistance - 火焰抗性
-- IceResistance - 冰霜抗性
-- LightningResistance - 闪电抗性
-- PoisonResistance - 毒素抗性
-- PhysicalResistance - 物理抗性
-- MagicalResistance - 魔法抗性
-- FireDamage - 火焰伤害
-- IceDamage - 冰霜伤害
-- LightningDamage - 闪电伤害
-- PoisonDamage - 毒素伤害
-- PhysicalDamage - 物理伤害
-- MagicalDamage - 魔法伤害
-- FireDamageIncrease - 火焰伤害增加
-- IceDamageIncrease - 冰霜伤害增加
-- LightningDamageIncrease - 闪电伤害增加
-- PoisonDamageIncrease - 毒素伤害增加
-- PhysicalDamageIncrease - 物理伤害增加
-- MagicalDamageIncrease - 魔法伤害增加
-- FireDamageReduction - 火焰伤害减免
-- IceDamageReduction - 冰霜伤害减免
-- LightningDamageReduction - 闪电伤害减免
-- PoisonDamageReduction - 毒素伤害减免
-- PhysicalDamageReduction - 物理伤害减免
-- MagicalDamageReduction - 魔法伤害减免
-- FireDamageReductionRate - 火焰伤害减免率
-- IceDamageReductionRate - 冰霜伤害减免率
-- LightningDamageReductionRate - 闪电伤害减免率
-- PoisonDamageReductionRate - 毒素伤害减免率
-- PhysicalDamageReductionRate - 物理伤害减免率
-- MagicalDamageReductionRate - 魔法伤害减免率

-- Buff状态值属性
-- Stun - 晕眩
-- KnockDown - 倒地
-- KnockUp - 悬空 
-- KnockBack - 击退 
-- Silence - 沉默
-- Fear - 恐惧
-- Charm - 魅惑
-- BanHit - 无法被攻击
-- BanSelect - 无法被选中
-- BanMove - 禁止移动
-- BanDamage - 免伤
-- ImmortalMode - 仙人模式
-- Roll - 闪避
-- SuperRoll - 超级闪避

-- 改变外观
-- Alpha - 透明度
-- Scale - 缩放
-- Hide - 隐藏
-- Stealth - 潜行

-- IgnoreObstacle - 无视障碍

-- 种植花园相关属性
-- SellBambooPriceMul -出售竹子加成
-- ProtectFruit - 保护果实 例如：有玩家偷取果实时，狗狗会警示，并有2.37%的概率保护果实不被偷取（成长公式=起始值2.37+成长值（0.67%）*体重）
-- SellFruitCritical - 出售果实暴击 例如：出售成功的果实有1.23%（可成长） 概率以1.5倍（不成长）价格出售
-- SellFruitCriticalPriceMul - 出售果实暴击价格倍率 例如：出售成功的果实有1.23%（可成长） 概率以1.5倍（不成长）价格出售
-- SellReturnOneFruit --例如:出售果实时，有3.07% 概率返还1个该果实。（仅会返还：价值低于10万以下的果实）
-- SellReturnGoldRate --出售果实返回黄金变异的概率
-- BambooToGoldRate --竹子变黄金的概率
-- LightningRate --获得闪电的概率提高



-- FruitGrowthMul - 果实生长提升倍率
-- FruitGrowthAtNightMul - 夜晚果实生长提升倍率




-- SellOver10kgPriceMul - 出售10公斤以上果实提高售价百分比



--属性堆叠方式
--1.加法
--2.乘法
--3.最大值
--4.最小值
StatDefines.StackType = {
    Add = 1,
    Mul = 2,
    Max = 3,
    Min = 4,
}
--属性堆叠定义，没有定义按照Add
StatDefines.StackDefines = {
    Tenacity = StatDefines.StackType.Max,
    ActorAlpha = StatDefines.StackType.Min,
    MoveSpeedPer = StatDefines.StackType.Mul,
}

--死亡需要重置的属性
StatDefines.ResetBuffStats = {
    "Stun", --晕眩
    "KnockDown", -- 倒地
    "KnockUp", -- 悬空 
    "KnockBack", -- 击退 
    "Silence", -- 沉默
    "Fear", -- 恐惧
    "Charm", -- 魅惑
    "BanHit", --无法被攻击
    "BanSelect", --无法被选中
    "BanChangeHero", --无法切换英雄
    "BanMove", --禁止移动
    "BanDamage", --免伤
    "ImmortalMode", --仙人模式
    "Roll", --闪避
    "SuperRoll", --超级闪避
    -- 改变外观
    "Alpha", --透明度
    "Scale", --缩放
    "Hide", --隐藏
    "IgnoreObstacle", --无视障碍
    "Stealth", --潜行

    "NotAttack", --不攻击
}

StatDefines.BanInherit = {
    ActorScale = true
}

StatDefines.ShowOffEvent = {
    PlayEffect = true,
    ShaderModify = true,
    ShaderSwitch = true
}

return StatDefines