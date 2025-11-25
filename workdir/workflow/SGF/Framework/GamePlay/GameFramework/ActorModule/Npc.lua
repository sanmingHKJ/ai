local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local EventObject = GFScript("CoreModule.EventObject")
local Database = GFScript("CoreModule.Database")
local Actor = GFScript("ActorModule.Actor")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local TimerManager = GFScript("CoreModule.TimerManager")
local ActorManager = GFScript("ActorModule.ActorManager")
local Sequence = GFScript("ActorModule.Action.Sequence")
local CallFunc = GFScript("ActorModule.Action.CallFunc")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local MoveBy = GFScript("ActorModule.Action.MoveBy")
local InventoryManager = GFScript("InventoryModule.InventoryManager")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local Npc = Class.New("Npc", Actor)

--构造
function Npc:Constructor(actorId, actorType, bObj, isServer)
    self.offers = {}
end

--析构
function Npc:Destructor()
end

--初始化
function Npc:Init()
    Npc.super.Init(self)
    self:SetCollideGroup(ActorDefines.CollideGroup.Npc)
end

--判断是否限制行动
function Npc:IsDisallowAction(ignoreStates)
    ignoreStates = ignoreStates or {}
    return (not ignoreStates["Stun"] and self.StatComponent:HasValue("Stun")) or 
        (not ignoreStates["KnockDown"] and self.StatComponent:HasValue("KnockDown")) or 
        (not ignoreStates["KnockUp"] and self.StatComponent:HasValue("KnockUp")) or 
        (not ignoreStates["KnockBack"] and self.StatComponent:HasValue("KnockBack")) or 
        (not ignoreStates["Dead"] and self:IsDead()) or 
        (not ignoreStates["BanMove"] and self.StatComponent:HasValue("BanMove")) or 
        (not ignoreStates["NotAttack"] and self.StatComponent:HasValue("NotAttack"))
end


--服务端初始化
function Npc:InitServer()
    Npc.super.InitServer(self)
end

function Npc:InitClient()
    Npc.super.InitClient(self)
end

--初始化服务端组件
function Npc:InitServerComponents()
    Npc.super.InitServerComponents(self)

end

---------------------------------------Offer---------------------------------------

--添加Offer
function Npc:AddOffer(offer)
    table.insert(self.offers, offer)
end

--移除Offer
function Npc:RemoveOffer(offer)
    table.remove(self.offers, offer)
end


--------------------------------------LoadConfig--------------------------------------

--从tid加载数据
function Npc:GetConfigName()
    return ActorUtils:GetActorTable(ActorDefines.EActorType.Npc).Actor
end

--加载配置
function Npc:OnLoadConfig(config)
    self.nickName = config.name
    self.desc = config.desc
    self.icon = config.icon
    self.AvatarComponent:SetRotateSpeed(config.rotateSpeed or 180) --旋转速度
    self.AvatarComponent:SetRadius(config.radius or 50) --自身半径
    self.AvatarComponent:SetHeight(config.height or 180) --自身高度
    self.AIPerception:SetRadius(config.perceptionRadius or 1000) --AI感知半径
    self.deathTime = config.deathTime or 5
    --加载基础属性
    self.StatComponent:Reset()
    if config.stats then
        for k,v in pairs(config.stats) do
            self.StatComponent:SetBaseValue(k, v)
        end
    end

    --设置为满血状态
    local maxHealth = self.StatComponent:GetBaseValue("MaxHealth")
    self.StatComponent:SetBaseValue("Health", maxHealth)
    self.HealthComponent:SyncToCharacter()
    
    -- --加载默认技能
    -- self.SkillComponent:Reset()
    -- if config.skills then
    --     for k,v in pairs(config.skills) do
    --         self.SkillComponent:AddSkill(v)
    --     end
    -- end
    -- --加载技能栏
    -- if config.skillBar then
    --     for k,v in ipairs(config.skillBar) do
    --         self.SkillComponent:ServerSetSkillBar(k, v.ref, v.type)
    --     end
    -- else
    --     self.SkillComponent.skillBar = nil
    -- end

    --加载AI
    if config.ai then
        self:LoadAIFromTid(config.ai)
    end

    -- --加载Buff
    -- if config.buffs then
    --     for k,v in pairs(config.buffs) do
    --         self.BuffComponent:ServerAddBuffByTid(self, v.tid, v.stack, v.args)
    --     end
    -- end

    --加载装备
    if config.equips then
        for k,v in pairs(config.equips) do
            local item = InventoryManager:CreateItem(v.tid, 1, self)
            self.EquipmentComponent:Equip(item, v.slot)
        end
    end

    self.CampComponent:SetCamp(config.camp)
end

return Npc