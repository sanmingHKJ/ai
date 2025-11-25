--地图配置
local MapConfig={}

--[==[
    地图场景类型ID
    MainCity: 主城场景 - 玩家的安全基地和功能中心
    ForestBattle: 森林战场 - 初级战斗场景 (1-10级)
    CaveBattle: 洞穴战场 - 中级战斗场景 (10-20级) [未来实现]
    MagicTower: 魔塔战场 - 高级战斗场景 (20级+) [未来实现]
]==]
MapConfig.ScenesTypeID = {
    MainCity = 1,           -- 主城场景
    ForestBattle = 2,       -- 森林战场
    CaveBattle = 3,         -- 洞穴战场（未来）
    MagicTower = 4,         -- 魔塔战场（未来）

    -- 保留旧命名以兼容旧代码
    MainHall = 1,           -- 主大厅（已废弃，使用MainCity）
    TouchGold = 2,          -- 摸金副本（已废弃，使用ForestBattle）
}

MapConfig.AllInsID={
    SinglePersonTouchGoldMap1 = 101,     -- 单人摸金地图1
    MultiplepeopleTouchGoldMap1 = 102,     -- 多人摸金地图1
}

--[==[
    场景出生点配置
    使用厘米为单位，Y=200表示地面以上2米（玩家视线高度）
]==]
MapConfig.SpawnPositions = {
    [MapConfig.ScenesTypeID.MainCity] = Vector3.new(0, 200, 0),           -- 主城中央出生点
    [MapConfig.ScenesTypeID.ForestBattle] = Vector3.new(0, 200, -1500),   -- 森林战场出生点
    [MapConfig.ScenesTypeID.CaveBattle] = Vector3.new(0, 200, 0),         -- 洞穴战场出生点（未来）
    [MapConfig.ScenesTypeID.MagicTower] = Vector3.new(0, 200, 0),         -- 魔塔战场出生点（未来）
}

-- 保留旧接口以兼容旧代码
MapConfig.MainHallSpawnPos = {
    [1] = Vector3.new(0, 200, 0),  -- 更新为新坐标
}

--[==[
    敌人刷新点配置
    每个战场有多个刷新点，每个刷新点有敌人类型和等级范围
]==]
MapConfig.EnemySpawns = {
    [MapConfig.ScenesTypeID.ForestBattle] = {
        {
            name = "EnemySpawn1",
            pos = Vector3.new(-800, 200, 1000),
            types = {"Slime", "Wolf"},
            levelRange = {min = 1, max = 5},
            respawnTime = 60,  -- 秒
        },
        {
            name = "EnemySpawn2",
            pos = Vector3.new(0, 200, 1200),
            types = {"Slime", "Wolf", "Bear"},
            levelRange = {min = 3, max = 8},
            respawnTime = 60,
        },
        {
            name = "EnemySpawn3",
            pos = Vector3.new(800, 200, 1000),
            types = {"Wolf", "Bear"},
            levelRange = {min = 5, max = 10},
            respawnTime = 60,
        },
    },
    [MapConfig.ScenesTypeID.CaveBattle] = {
        -- 未来实现
    },
    [MapConfig.ScenesTypeID.MagicTower] = {
        -- 未来实现
    },
}

--[==[
    NPC位置配置
]==]
MapConfig.NPCPositions = {
    [MapConfig.ScenesTypeID.MainCity] = {
        QuestNPC = {
            pos = Vector3.new(0, 200, 1500),
            name = "任务管理员",
            interactionRange = 300,  -- 厘米
        },
        ShopNPC = {
            pos = Vector3.new(1200, 200, 1500),
            name = "商店老板",
            interactionRange = 300,
        },
    },
}

--[==[
    传送门配置
]==]
MapConfig.Portals = {
    [MapConfig.ScenesTypeID.MainCity] = {
        {
            name = "TeleportPortal_Forest",
            pos = Vector3.new(-1500, 200, -2000),
            targetScene = MapConfig.ScenesTypeID.ForestBattle,
            requiredLevel = 1,
            enabled = true,
        },
        {
            name = "TeleportPortal_Cave",
            pos = Vector3.new(0, 200, -2000),
            targetScene = MapConfig.ScenesTypeID.CaveBattle,
            requiredLevel = 10,
            enabled = false,  -- 未来开放
        },
        {
            name = "TeleportPortal_Tower",
            pos = Vector3.new(1500, 200, -2000),
            targetScene = MapConfig.ScenesTypeID.MagicTower,
            requiredLevel = 20,
            enabled = false,  -- 未来开放
        },
    },
    [MapConfig.ScenesTypeID.ForestBattle] = {
        {
            name = "ExitPortal",
            pos = Vector3.new(0, 200, -2200),
            targetScene = MapConfig.ScenesTypeID.MainCity,
            requiredLevel = 0,
            enabled = true,
        },
    },
}

--[==[
    场景信息配置
]==]
MapConfig.SceneInfo = {
    [MapConfig.ScenesTypeID.MainCity] = {
        name = "主城",
        description = "冒险者的安全基地",
        safeZone = true,
        pvpEnabled = false,
        size = {x = 10000, z = 10000},  -- 厘米
    },
    [MapConfig.ScenesTypeID.ForestBattle] = {
        name = "森林战场",
        description = "被魔物侵占的森林",
        safeZone = false,
        pvpEnabled = false,
        difficulty = "easy",
        recommendedLevel = {min = 1, max = 10},
        size = {x = 6000, z = 6000},
    },
    [MapConfig.ScenesTypeID.CaveBattle] = {
        name = "洞穴战场",
        description = "幽暗的地下洞窟",
        safeZone = false,
        pvpEnabled = false,
        difficulty = "medium",
        recommendedLevel = {min = 10, max = 20},
        size = {x = 5000, z = 5000},
        enabled = false,  -- 未来开放
    },
    [MapConfig.ScenesTypeID.MagicTower] = {
        name = "魔塔",
        description = "充满魔法能量的神秘高塔",
        safeZone = false,
        pvpEnabled = false,
        difficulty = "hard",
        recommendedLevel = {min = 20, max = 50},
        size = {x = 4000, z = 4000},
        enabled = false,  -- 未来开放
    },
}


--环境配置
MapConfig.EnvironmentConfig = {
    [1001] = { 
        --SkyLight
        Position = {X = 0, Y = 0, Z = 0},
        Euler = {X = 0, Y = 0, Z = 0},
        LocalPosition = {X = 0, Y = 0, Z = 0},
        LocalEuler = {X = 0, Y = 0, Z = 0},
        LocalScale = {X = 1, Y = 1, Z = 1},
        CubeBorderEnable = false,
        CubeBorderColor ={R = 170, G = 203, B = 255, A = 255}, 

        SkyLightType = Enum.SkyLightType.Skybox ,
        SkyLightTexture="sandboxId://Map_Scenes/HDRI/FK_2001_HDRI.png",
        SkyLightCubeAssetID="sandboxId://Map_Scenes/HDRI/FK_2001_HDRI.png",
        Intensity= 1,
        Color = {R = 170, G = 203, B = 255, A = 255}, 
        --BlendAmount = 1,
        AmbientSkyColor = {R = 197, G = 234, B = 202, A = 255}, 
        AmbientEquatorColor = {R = 160, G = 167, B = 188, A = 255}, 
        AmbientGroundColor = {R = 151, G = 179, B = 214, A = 255}, 
        AmbientColor = {R = 130, G = 133, B = 140, A = 255}, 

        --Atmosphere
        FogType =  Enum.FogType.Linear,        
        FogColor = {R = 166, G = 182, B = 196, A = 255}, 
        FogStart = 500.00, 
        FogEnd = 130000.00,
        FogOffset = 1,

        --skydome
        HazeColor = {R = 150, G = 179, B = 203, A = 255}, 
        HorizonColor = {R = 206, G = 221, B = 237, A = 255},
        ZenithColor = {R = 206, G = 221, B = 237, A = 255},
        SkyBoxType = Enum.SkyBoxType.Custom,
        CubeAssetID ="sandboxId://Map_Scenes/HDRI/FK_2001_HDRI.png",
    
        CloudsEnable = false,
        ShadowColor = {R = 255, G = 255, B = 255, A = 255}, 
        ShadowDarkColor = {R = 255, G = 255, B = 255, A = 255},
        CloudsCoverage = 0.042,
        LightIntensity = 0.1,
        CloudsSpeed = 0.1,
        CloudsAlpha = 0.41,
        StarsAmount= 0.5,
            
        --SunLight
        SunLightIntensity=1.15,
        SunLightColor = {R = 255, G = 212, B = 174, A = 255},
        LockTimeDir = false,
        SunLightEuler = {X = 23.9, Y = 42.72, Z = 4.44},

        ShadowBias = 0.1,
        ShadowSlopeBias = 0.3,
        ShadowDistance = 2500,
        ShadowCascadeCount =Enum.ShadowCascadeCount.FOUR,
        SunRaysActive = true,
        SunRaysScale = 5,
        SunRaysThreahold = 1.1,
        SunRaysColor = {R = 255, G = 107, B = 21, A = 255},
        
        UseCustomSunAndMoonTex = false,
        SunTex = "" ,
        SunScale = {X = 1, Y = 1},
        MoonTex = "" ,
        MoonScale = {X = 1, Y = 1},     
        
        ---PostProcessing
        BloomActive = true,
        BloomIntensity = 2,
        BloomThreshold = 1,
        BloomLuminanceScale=1,
        BloomIterator=4,

        DofActive = false,
        DofFocalRegion = 100,
        DofNearTransitionRegion = 9000,
        DofFarTransitionRegion = 50000,
        DofFocalDistance = 100,
        DofScale = 1,

        VignetteActive = true,
        VignetteIntensity=0.31,
        VignetteRounded=false,
        VignetteSmoothness=0.28,
        VignetteRoundness=1,
        VignetteMaskOpacity=1,
        VignetteCenter={X = 0.5, Y = 0.5},
        VignetteColor={R = 56, G = 56, B = 63, A = 255},
        VignetteMode=Enum.VignetteMode.Classic,
        
        AntialiasingEnable = true,
        --AntialiasingMethod = kAntialiasingMethodFXAA,
        --AntialiasingQuality = kAntialiasingQualityHigh,

        LUTsActive = true,
        --LUTsTemperatureType =WhilteBalance,
        LUTsWhiteTemp = 6300,
        LUTsWhiteTint = 0,
        LUTsColorCorrectionShadowsMax = 0.8,
        LUTsColorCorrectionHighlightsMin = 0.5,
        LUTsBlueCorrection = 0.59,
        LUTsExpandGamut = 1,
        LUTsToneCurveAmout = 0.2,
        LUTsFilmicToneMapSlope = 0.88,
        LUTsFilmicToneMapToe = 0.55,
        LUTsFilmicToneMapShoulder = 0.26,
        LUTsFilmicToneMapBlackClip = 0,
        LUTsFilmicToneMapWhiteClip = 0.14,

        LUTsBaseSaturation = {R = 255, G = 255, B = 255, A = 255},
        LUTsBaseContrast = {R = 255, G = 255, B = 255, A = 255},
        LUTsBaseGamma = {R = 255, G = 255, B = 255, A = 255},
        LUTsBaseGain = {R = 225, G = 225, B = 225, A = 255},
        LUTsBaseOffset = {R = 0, G = 0, B = 0, A = 0},
        LUTsShadowSaturation = {R = 255, G = 255, B = 255, A = 255},
        LUTsShadowContrast = {R = 255, G = 255, B = 255, A = 255},
        LUTsShadowGamma = {R = 255, G = 255, B = 255, A = 255},
        LUTsShadowGain = {R = 255, G = 255, B = 255, A = 255},
        LUTsShadowOffset = {R = 0, G = 0, B = 0, A = 0},
        LUTsMidtoneSaturation = {R = 255, G = 255, B = 255, A = 255},
        LUTsMidtoneContrast = {R = 255, G = 255, B = 255, A = 255},
        LUTsMidtoneGamma = {R = 255, G = 255, B = 255, A = 255},
        LUTsMidtoneGain = {R = 255, G = 255, B = 255, A = 255},
        LUTsMidtoneOffset = {R = 0, G = 0, B = 0, A = 0},
        LUTsHighlightSaturation = {R = 171, G = 171, B = 171, A = 255},
        LUTsHighlightContrast = {R = 255, G = 255, B = 255, A = 255},
        LUTsHighlightGamma = {R = 255, G = 255, B = 255, A = 255},
        LUTsHighlightGain = {R = 255, G = 255, B = 255, A = 255},
        LUTsHighlightOffset = {R = 0, G = 0, B = 0, A = 0},
        LUTsColorGradingLUTPath = "",

        GTAOActive = true,
        GTAOThicknessblend = 0.05,
        GTAOFalloffStartRatio = 0.5,
        GTAOFalloffEnd = 50,
        GTAOFadeoutDistance = 3000,
        GTAOFadeoutRadius = 1000,
        GTAOIntensity = 0.8,
        GTAOPower = 8,

        ChromaticAberrationActive = true,
        ChromaticAberrationIntensity = 1,
        ChromaticAberrationStartOffset = 0.8,
        ChromaticAberrationIterationStep = 0.01,
        ChromaticAberrationIterationSamples = 1,
    },
}

return MapConfig