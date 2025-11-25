local ActorDefines = {}

ActorDefines.EActorType = {
    Player = "Player",
    Npc = "Npc",
    Monster = "Monster",
    Boss = "Boss",
    Pet = "Pet",
    Walker = "Walker",
    Summon = "Summon",
}

ActorDefines.ActorTypeMap = {
    [1] = "Player",
    [2] = "Npc",
    [3] = "Monster",
    [4] = "Boss",
    [5] = "Pet",
    [6] = "Walker",
    [7] = "Summon",
}

-- 整数转Actor类型
function ActorDefines:ToActorType(typeInt)
    if type(typeInt) == "string" then
        return typeInt
    end
    return ActorDefines.ActorTypeMap[typeInt]
end


--Actor关联节点的Tag
ActorDefines.ActorTag = 4489
ActorDefines.ProjectileTag = 4490
ActorDefines.SummonTag = 4491
--碰撞过滤组
ActorDefines.CollideGroup = 
{
    Player = 18,
    Pet = 17,--宠物
    Soul = 16,--灵魂，无视阻挡
    Projectile = 25,--子弹
    Npc = 25,
    Monster = 25,
    Boss = 25,
    Other = 25,
    Summon = 25,--召唤物
    Walker = 25,--步行者
    NoCollide = 25, --不碰撞组
}
--全部碰撞组
ActorDefines.AllCollideActorGroups = 
{
    ActorDefines.CollideGroup.Player,
    ActorDefines.CollideGroup.Npc,
    ActorDefines.CollideGroup.Monster,
    ActorDefines.CollideGroup.Boss,
    ActorDefines.CollideGroup.Soul,
    ActorDefines.CollideGroup.Pet,
    ActorDefines.CollideGroup.Projectile,
    ActorDefines.CollideGroup.Walker,
    ActorDefines.CollideGroup.Summon,
}
ActorDefines.AllCollideActorAndObstacleGroups = 
{
    1,2,3,
    ActorDefines.CollideGroup.Player,
    ActorDefines.CollideGroup.Npc,
    ActorDefines.CollideGroup.Monster,
    ActorDefines.CollideGroup.Boss,
    ActorDefines.CollideGroup.Soul,
    ActorDefines.CollideGroup.Pet,
    ActorDefines.CollideGroup.Projectile,
    ActorDefines.CollideGroup.Walker,
    ActorDefines.CollideGroup.Summon,
}

--角色状态
ActorDefines.EActorState = {
    Idle = "Idle",--空闲
    Moving = "Moving",--移动
    NearDeath = "NearDeath",--濒死
    Dead = "Dead",--死亡
    Stun = "Stun", --眩晕
    KnockUp = "KnockUp",--浮空
    KnockUp2 = "KnockUp2",--浮空2
    KnockDown = "KnockDown", --赖地不起
    KnockBack = "KnockBack", --击退
    Fall = "Fall",--坠落
    Roll = "Roll",--翻滚
    SuperRoll = "SuperRoll",--超级翻滚
    Casting = "Casting",--施法中，后摇结束后回位
    Jump = "Jump",--跳跃
    Jumping = "Jumping",--跳跃中
    Fly = "Fly",--飞行
    Sleep = "Sleep",--睡眠
}

--障碍物碰撞组
ActorDefines.ObstacleCollisionGroup = {1,2,3,4}

--脚步声的碰撞组
ActorDefines.FootStepCollisionGroup = {3}

--子弹碰撞组
ActorDefines.ProjectileCollisionGroup = {ActorDefines.CollideGroup.Projectile}

--序列化的用途
ActorDefines.ESerializePurpose = {
    None = "None", --无
    Save = "Save", --保存，玩家保存，保存到云数据
    Load = "Load", --加载，玩家加载，从云数据加载
    Sync = "Sync", --同步，服务器同步，网络同步
}

return ActorDefines