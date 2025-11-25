return {
    [101] = {
        name = "小白",
        desc = "小白兔",
        icon = "icon",
        --属性
        stats = {
            Level = 1,
            MaxLevel = 100,
            Attack = 100,
            Defense = 0,
            MoveSpeed = 600,
            JumpSpeed = 400,
            MoveSpeedMul = 0,
            JumpSpeedMul = 0,
            MaxHealth = 100,
            FireRateScale = 1,
            MuzzleVelocityScale = 1.0,
            AmmoConsumptionScale = 1.0,
        },
        --技能
        skills = {
            1,2,3,4
        },
        skillBar = {
            {ref = 1, type = 1},
        },
        --宠物
        pets = {
            1,2,3,4
        },
        --道具
        items = {
            1,2,3
        },
        --装备
        equips = {
            1,2,3
        },
        --任务
        quests = {
            1,2,3
        }
    },
}