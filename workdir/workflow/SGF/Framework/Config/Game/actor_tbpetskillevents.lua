return {
    [101] = {
        eventName = "LootItem",--偷东西
        params = {
            Q1 = {
                cd = 60, --cd，单位：秒
                param1 = 10001, --道具id
                param2 = 1,  --数量
                param3 = 10000, --概率
                growUp = {                --成长
                    cd = 0, --cd
                    param1 = 0, --id
                    param2 = 0, --数量
                    param3 = 10000, --概率
                },
            },
            Q2 = {
                cd = 60, --cd，单位：秒
                param1 = 10001, --道具id
                param2 = 1,  --数量
                param3 = 10000, --概率
                growUp = {                --成长
                    cd = 0, --cd
                    param1 = 0, --id
                    param2 = 0, --数量
                    param3 = 10000, --概率
                },
            },
        },
        moveToTarget = true,--是否移动到玩家身上，（交互用）
        errorDistance = 150,---距离玩家的距离
        animName = "LootItem",-----宠物播放的动画
        desc = "每60分钟，偷取一个低级品质工具（98%概率获得珍稀2品质的工具*1，2%概率获得神圣6品质的工具*1）"
    },
    [102] = {
        eventName = "LootCurrency",--偷钱
        params = {
            Q1 = {
                cd = 40, --cd
                param1 = 500, --最小值
                param2 = 1500,  --最大值
                growUp = {
                    cd = 0, --cd
                    param1 = 500, --最小值
                    param2 = 1500, --最大值
                },
            },
            Q2 = {
                cd = 40, --cd
                param1 = 1000, --最小值
                param2 = 2500, --最大值
                growUp = {
                    cd = 0, --cd
                    param1 = 500, --最小值
                    param2 = 1500, --最大值
                },
            },
        },
        animName = "LootItem",
        desc = "每40分钟会跑向一名玩家，帮你偷取一笔钱回来（500~1500随机）"
    },
    [201] = {
        eventName = "PlantMutate",
        params = {
            Q1 = {
                cd = 10, --cd
                param1 = 1000, --最小值
                param2 = "Frozen",  --最大值
                growUp = {
                    cd = 0, --cd
                    param1 = 2000, --最小值
                    param2 = "Frozen", --最大值
                },
            },
            Q2 = {
                cd = 10, --cd
                param1 = 2000, --最小值
                param2 = "Golden", --最大值
                growUp = {
                    cd = 0, --cd
                    param1 = 500, --最小值
                    param2 = "Golden", --最大值
                },
            },
        },
        animName = "PlantMutate",
        desc = "每80分钟触发一次，让周边的果实获得一个“冰冻”变异"
    },
}