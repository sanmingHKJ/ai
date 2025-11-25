local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorSettings = {}  

--角色表名
ActorSettings.Table = {
    Actor = "actor_tbactor",
    Voice = "voice_tbvoice",
}

--角色id段
ActorSettings.ActorIdRange = 
{
    {ActorDefines.EActorType.Player, 101, 500},
    {ActorDefines.EActorType.Npc, 501, 1000},
    {ActorDefines.EActorType.Pet, 1001, 2000},
    {ActorDefines.EActorType.Boss, 2001, 3000},
    {ActorDefines.EActorType.Monster, 3001, 4000},
    {ActorDefines.EActorType.Walker, 4001, 5000},
    {ActorDefines.EActorType.Summon, 5001, 6000},
}

--根据类型获取对应的表，如果没有对应的类型，采用ActorSettings.Table
ActorSettings.TableByType = {
    [ActorDefines.EActorType.Player] = {
        Actor = "actor_tbplayer",
    },
    [ActorDefines.EActorType.Npc] = {
        Actor = "actor_tbnpc",
    },
    [ActorDefines.EActorType.Monster] = {
        Actor = "actor_tbmonster",
    },
    [ActorDefines.EActorType.Boss] = {
        Actor = "actor_tbboss",
    },
    [ActorDefines.EActorType.Pet] = {
        Actor = "actor_tbpet",
    },
    [ActorDefines.EActorType.Walker] = {
        Actor = "actor_tbwalker",
    },
    [ActorDefines.EActorType.Summon] = {
        Actor = "actor_tbsummon",
    },
}

return ActorSettings