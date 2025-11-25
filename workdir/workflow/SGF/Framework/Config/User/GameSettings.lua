--游戏设置
local GameSettings = {
    --通用
    General = {
        gmEnabled = true,--GM是否开启
    },
    --镜头配置
    CameraController = {
        distance = 500,--摄像机到人的距离
        minDistance = 200,--最小距离
        maxDistance = 2000,--最大距离
        positionSmoothSpeed = 10,--镜头位置平滑速度，越大速度越快
        rotateSmoothTime = 0.02,--镜头旋转平滑时间，越小速度越快
    },
    --Buff
    Buff = {
        defaultKnockDownBuff = "Buff.Common.Buff_KnockDown",--默认击倒Buff
        defaultKnockUpBuff = "Buff.Common.Buff_KnockUp",--默认击飞Buff
        defaultKnockBackBuff = "Buff.Common.Buff_KnockBack",--默认击退Buff
    },
    --战斗
    Combat = {
        BreakDuration = 0.5, --预输入有效时间，单位秒
        deathTime = 5, --尸体残留时间
        dissolveTime = 0.8, --死亡溶解时间
        deathDestroyTime = 7,--死亡后尸体销毁时间，需大于残留和溶解时间之和

        --准心系数
        crosshairCoefficient = 15,
    },
    --锁敌
    Targeting= {
        height = 1000, --视野高度
        distance = 1500,--视野范围
        lostDistance = 2000, --丢失目标距离
        targetType = 0,--目标类型
        angle = 360,--视野角度
        autoSelect = true,--自动选择
        --距离区间
        distanceRanges = {
            {minDis = 0, maxDis = 300, value = 190 },
            {minDis = 300, maxDis = 600, value = 160 },
            {minDis = 600, maxDis = 1200, value = 130 },
            {minDis = 1200, maxDis = 1800, value = 70 },
            {minDis = 1800, maxDis = 2400, value = 10 }
        }
    },
    Game={
        openServerList = 6,     --服务器开启数量 
    },
    Scene = {
        --AOI范围
        clientAoiVisRange = 5000,
        --AOI范围
        serverAoiVisRange = 1500,
    },
    Sound = {
        MasterVolume = 1,
        Channel = {
            Background = {
                volume = 1,
                fadeTime = 1,
            },
            Ambient = {
                volume = 1,
                fadeTime = 0.5,
            },
            --脚步声
            Footstep = {
                volume = 0.7,
                fadeTime = 0,
            },
            Effect = {
                volume = 0.5,
                fadeTime = 0,
            },
            Voice = {
                volume = 1.5,
                fadeTime = 0.1,
            },
            UI = {
                volume = 1,
                fadeTime = 0,
            }
        }
    }
}

return GameSettings