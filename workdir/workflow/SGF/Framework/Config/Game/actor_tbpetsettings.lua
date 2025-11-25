return {
    MaxLevel = 75,  ---最大等级
    SkillCDScale = 1.0, --技能CD缩放
    ExpGrowthMul = 1,     --经验成长倍数（默认1）
    HungryExpGrowthMul = 1,    --饥饿状态下经验成长系数（默认1，需下面hungryExpGrowth配合）
    HungerDecayTime = 720,    --饥饿衰减时间，单位：分钟
    MaxSummonCount = 3, --最大召唤数量
    MinCD = 300, --最小CD

    --通用宠物设置
    Common = {
        expGrowth = 0.51,--每秒经验数量
        hungryExpGrowth = 0,--饥饿状态下每秒增加的经验值，默认0
        scaleGrowth = 0.08,--每一级的体型增加值（模型尺寸）
        weightGrowth = 0.16,--每一级的体型增体重KG
		feedFactor = 1,--喂养系数（这个控制降低玩家所需投喂价值 *0.9 打九折）

    },
    --默认拥有的宠物
    DefaultPets = {---默认背包持有的宠物，测试预留用

    },
}