return {
[1001] = {---白兔技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootSeed",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3600, --cd
                growUp = {                --成长
                    cd = -11.31, --cd
                },
            },
			items = {
				{itemId = 71003, weight = 10000},
				{itemId = 71002, weight = 10000},
            },
        },
        desc = "每{cd:time:s2m}分钟，崽崽会找到一个工具"--技能描述
},
[1002] = {---灰白兔技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootSeed",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3300, --cd
                growUp = {                --成长
                    cd = -13.31, --cd
                },
            },
			items = {
				{itemId = 71003, weight = 10000},
				{itemId = 71002, weight = 10000},
				{itemId = 71006, weight = 8000},
				{itemId = 71004, weight = 100},
            },
        },
        desc = "每{cd:time:s2m}分钟，崽崽会找到一个工具，有概率找到好点的工具"--技能描述
},
[1003] = {---灰白兔技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootSeed",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3000, --cd
                growUp = {                --成长
                    cd = -15.66, --cd
                },
            },
			items = {
				{itemId = 71003, weight = 10000},
				{itemId = 71002, weight = 10000},
				{itemId = 71006, weight = 5000},
				{itemId = 71004, weight = 100},
				{itemId = 71005, weight = 100}
            },
        },
        desc = "每{cd:time:s2m}分钟，崽崽会找到一个工具，有概率找到到神圣品质的工具"--技能描述
},
[1004] = {---螃蟹
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootCurrency",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2400, --cd
                minCoin = 500, --最小值
                maxCoin = 1500, --最大值
                growUp = {                --成长
                    cd = -11.31, --cd
                    minCoin = 10, --最小值
                    maxCoin = 30, --最大值
                },
            },
		moveToTarget = true,--是否移动到玩家身上，（交互用）
        errorDistance = 200,---距离玩家的距离
        },
        desc = "每{cd:time:s2m}分钟会跑向一名玩家，帮你偷取一笔钱回来"--技能描述
},
[1005] = {---绿星蟹
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootCurrency",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2100, --cd
                minCoin = 2000, --最小值
                maxCoin = 3000, --最大值
                growUp = {                --成长
                    cd = -13.31, --cd
                    minCoin = 40, --最小值
                    maxCoin = 60, --最大值
                },
            },
		moveToTarget = true,--是否移动到玩家身上，（交互用）
        errorDistance = 200,---距离玩家的距离
        },
        desc = "每{cd:time:s2m}分钟会跑向一名玩家，帮你偷取一笔钱回来，整体硬币数量更多"--技能描述
},
[1006] = {---赛博蟹
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootCurrency",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 1800, --cd
                minCoin = 4000, --最小值
                maxCoin = 5000, --最大值
                growUp = {                --成长
                    cd = -15.66, --cd
                    minCoin = 40, --最小值
                    maxCoin = 50, --最大值
                },
            },
		moveToTarget = true,--是否移动到玩家身上，（交互用）
        errorDistance = 200,---距离玩家的距离
        },
			bonusStats = {----奖励到玩家的属性
            MoveSpeedMul = 0,
            growUp = {                --成长
                MoveSpeedMul = 0.6921,
            },
        },
        desc = "每{cd:time:s2m}分钟会跑向一名玩家，帮你偷取一笔钱回来，整体硬币数量更多，崽崽成长值更高，略微提升玩家{MoveSpeedMul:float:2}%移动速度"--技能描述
},
[1007] = {--白狗技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
            ProtectFruit = 2.373,
			growUp = {                --成长
				ProtectFruit = 0.2219,
            },
        },
        desc = "有玩家偷取果实时，狗狗会警示，并有{ProtectFruit:float:2}%的概率保护果实不被偷取，让果实留在庄园里"--技能描述
},
[1008] = {--黑狗技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
            ProtectFruit = 4.22,
			growUp = {                --成长
				ProtectFruit = 0.3071,
            },
        },
		event = {
            eventName = "LootSeed",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 1800, --cd
                chance = 100, --概率
                growUp = {                --成长
                    cd = -18.42, --cd
                },
            },
			items = {
				{itemId = 10001, weight = 1000},
				{itemId = 10002, weight = 1000},
				{itemId = 10003, weight = 1000},
				{itemId = 10004, weight = 1000},
				{itemId = 10005, weight = 500},
				{itemId = 10006, weight = 500},
				{itemId = 10007, weight = 500},
				{itemId = 10008, weight = 500},
				{itemId = 10058, weight = 500},
				{itemId = 10009, weight = 250},
				{itemId = 10010, weight = 250},
				{itemId = 10013, weight = 250},
				{itemId = 10012, weight = 250},
				{itemId = 10011, weight = 250},
				{itemId = 10033, weight = 50},
				{itemId = 10014, weight = 50},
				{itemId = 10015, weight = 50},
				{itemId = 10016, weight = 50},
				{itemId = 10018, weight = 50},
				{itemId = 10017, weight = 50},
				{itemId = 71003, weight = 50},
				{itemId = 71002, weight = 500},
				{itemId = 71006, weight = 250},
				{itemId = 71004, weight = 30},
				{itemId = 71005, weight = 30}
            },
        },
        desc = "有玩家偷取果实时，狗狗会警示，并有{ProtectFruit:float:2}%的概率保护果实不被偷取，让果实留在庄园里，每{cd:time:s2m}分钟，有概率帮你获取一个种子或工具"--技能描述
},
[1009] = {--黄狗技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
            ProtectFruit = 3.16,
			growUp = {                --成长
				ProtectFruit = 0.261,
            },
        },
        desc = "有玩家偷取果实时，狗狗会警示，并有{ProtectFruit:float:2}%的概率保护果实不被偷取，让果实留在庄园里"--技能描述
},
[1010] = {--黑猫猫技能
        type = "PetHaloSkill",--技能类型
        iconId = "",--技能图标，默认不配
        stats = {        --属性
            FruitGrowthRadius = 250,--厘米
            FruitGrowthMul = 0.06, --果实生长提升倍率
            growUp = 
            {
                FruitGrowthMul = 0.01775,---生长速度成长值
                FruitGrowthRadius = 22,--范围成长值（厘米）
            },
        },
        desc = "以猫咪为中心，半径{FruitGrowthRadius:length:c2m}米范围内的果实生长速度提升{FruitGrowthMul:percentage}"--技能描述
},
[1011] = {--白猫猫技能
        type = "PetHaloSkill",--技能类型
        iconId = "",--技能图标，默认不配
        stats = {        --属性
            FruitGrowthRadius = 300,--厘米
            FruitGrowthMul = 0.08, --果实生长提升倍率
            growUp = 
            {
                FruitGrowthMul = 0.02088,---生长速度成长值
                FruitGrowthRadius = 26,--范围成长值（厘米）
            },
        },
        desc = "以猫咪为中心，半径{FruitGrowthRadius:length:c2m}米范围内的果实生长速度提升{FruitGrowthMul:percentage}"--技能描述
},
[1012] = {--月光猫技能
        type = "PetHaloSkill",--技能类型
        iconId = "",--技能图标，默认不配
        stats = {        --属性
            FruitGrowthRadius = 350,--厘米
            FruitGrowthMul = 0.11, --果实生长提升倍率
            FruitGrowthAtNightMul = 1, --夜晚果实生长提升倍率
            growUp = 
            {
                FruitGrowthMul = 0.02457,---生长速度成长值
                FruitGrowthRadius = 30.7,--范围成长值（厘米）
            },
        },
        desc = "以猫咪为中心，半径{FruitGrowthRadius:length:c2m}米范围内的果实生长速度提升{FruitGrowthMul:percentage}，夜晚天气下，生长速度提升至{FruitGrowthAtNightMul:percentage}"--技能描述
},
[1013] = {--猴子技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
			SellReturnOneFruit = 2.2,  --返还概率%
			growUp = {                --成长
                    SellReturnOneFruit = 0.0111, --返还概率成长值%
                },
        },
        desc = "出售果实时，有{SellReturnOneFruit:float:2}%概率返还低价值果实。"--技能描述
},
[1014] = {--圣猴技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
			SellReturnOneFruit = 3.07,  --返还概率%
			SellFruitCritical=1.23,  ---2%概率提升售价%
			SellFruitCriticalPriceMul=0.5, ---售价加成
			growUp = {                --成长
                    SellReturnOneFruit = 0.0154, --返还概率成长值%
					SellFruitCritical = 0.0921  --售价加成概率%
                },
        },
        desc = "出售果实时，有{SellReturnOneFruit:float:2}%概率返还较低价值果实。出售成功的果实有{SellFruitCritical:float:2}% 概率以{SellFruitCriticalPriceMul:growup:2}倍价格出售"--技能描述
},
[1015] = {--霓虹猴技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
			SellReturnOneFruit = 5,  --返还概率%
			SellFruitCritical= 2,  ---2%概率提升售价%
			SellFruitCriticalPriceMul=0.5, ---售价加成
			SellReturnGoldRate=7.5, --出售果实返回黄金变异的概率%
			growUp = {                --成长
                    SellReturnOneFruit = 0.0250, --返还概率成长值%
					SellFruitCritical = 0.15,  --售价加成概率%
					SellReturnGoldRate=0.375
                },
        },
        desc = "出售果实时，有{SellReturnOneFruit:float:2}%概率返还中低价值果实，出售成功的果实有{SellFruitCritical:float:2}%概率以{SellFruitCriticalPriceMul:growup:2}倍价格出售，所返还的果实中有概率返还“黄金变异”果实."--技能描述
},
[1016] = {---狐狸技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootSeed",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3600, --cd
                chance = 100, --概率
                growUp = {                --成长
                    cd = -11.31, --cd
                },
            },
			items = {
				{itemId = 10001, weight = 1000},
				{itemId = 10002, weight = 1000},
				{itemId = 10003, weight = 1000},
				{itemId = 10004, weight = 1000},
				{itemId = 10005, weight = 500},
				{itemId = 10006, weight = 500},
				{itemId = 10007, weight = 500},
				{itemId = 10008, weight = 500},
				{itemId = 10058, weight = 500},
				{itemId = 10009, weight = 250},
				{itemId = 10010, weight = 250},
				{itemId = 10013, weight = 250},
				{itemId = 10012, weight = 250},
				{itemId = 10011, weight = 250}
            },
        },
        desc = "每{cd:time:s2m}分钟，从种子商人处偷取一个低级品质种子"--技能描述
},
[1017] = {---瑶光狐技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootSeed",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3300, --cd
                chance = 100, --概率
                growUp = {                --成长
                    cd = -15.66, --cd
                },
            },
            items = {
				{itemId = 10001, weight = 1000},
				{itemId = 10002, weight = 1000},
				{itemId = 10003, weight = 1000},
				{itemId = 10004, weight = 1000},
				{itemId = 10005, weight = 500},
				{itemId = 10006, weight = 500},
				{itemId = 10007, weight = 500},
				{itemId = 10008, weight = 500},
				{itemId = 10058, weight = 500},
				{itemId = 10009, weight = 250},
				{itemId = 10010, weight = 250},
				{itemId = 10013, weight = 250},
				{itemId = 10012, weight = 250},
				{itemId = 10011, weight = 250},
				{itemId = 10033, weight = 125},
				{itemId = 10014, weight = 125},
				{itemId = 10015, weight = 125},
				{itemId = 10016, weight = 125},
				{itemId = 10018, weight = 125},
				{itemId = 10017, weight = 125}
            },
            --denominator = 100, --概率分母
            --moveToTarget = false,--是否移动到玩家身上，（交互用）
            -- errorDistance = 150,---距离玩家的距离
        },
        desc = "每{cd:time:s2m}分钟，从种子商人处偷取一个植物种子，有几率偷取到稀有品质种子"--技能描述
},
[1018] = {---稻荷狐技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "LootSeed",--偷种子
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3000, --cd
                chance = 100, --概率
                growUp = {                --成长
                    cd = -18.42, --cd
                },
            },
    		items = {
    			{itemId = 10001, weight = 1000},
    			{itemId = 10002, weight = 1000},
    			{itemId = 10003, weight = 1000},
    			{itemId = 10004, weight = 1000},
    			{itemId = 10005, weight = 500},
    			{itemId = 10006, weight = 500},
    			{itemId = 10007, weight = 500},
    			{itemId = 10008, weight = 500},
    			{itemId = 10058, weight = 500},
    			{itemId = 10009, weight = 250},
    			{itemId = 10010, weight = 250},
    			{itemId = 10013, weight = 250},
    			{itemId = 10012, weight = 250},
    			{itemId = 10011, weight = 250},
    			{itemId = 10033, weight = 125},
    			{itemId = 10014, weight = 125},
    			{itemId = 10015, weight = 125},
    			{itemId = 10016, weight = 125},
    			{itemId = 10018, weight = 125},
    			{itemId = 10017, weight = 125},
    			{itemId = 10021, weight = 62},
    			{itemId = 10019, weight = 62},
    			{itemId = 10020, weight = 62},
    			{itemId = 10034, weight = 62},
    			{itemId = 10035, weight = 62},
    			{itemId = 10045, weight = 62},
    			{itemId = 10059, weight = 62},
    			{itemId = 10022, weight = 62}
            },
        },
        desc = "每{cd:time:s2m}分钟，从种子商人处偷取一个植物种子，有几率偷取到神话品质种子"--技能描述
},
[1019] = {---奶牛技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
            JumpSpeedMul = 0,
		growUp = {                --成长
			JumpSpeedMul = 0.79102,
            },
        },
        desc = "提升玩家的跳跃高度，跳跃高度提高{JumpSpeedMul:float:2}%"--技能描述
    },
[1020] = {---红牛技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
            MoveSpeedMul = 0,
		growUp = {                --成长
			MoveSpeedMul = 1.64063,
            },
        },
        desc = "提升玩家的移动速度和攀爬速度，移动和攀爬提高{MoveSpeedMul:float:2}%"--技能描述
    },
[1021] = {---乔尼牛技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        bonusStats = {----奖励到玩家的属性
            MoveSpeedMul = 0,
            JumpSpeedMul = 0,
		growUp = {                --成长
				MoveSpeedMul = 2.91668,
				JumpSpeedMul = 1.87500,
            },
        },
        desc = "提升玩家的移动速度和攀爬速度，移动和攀爬提高{MoveSpeedMul:float:2}%，提升跳跃高度，跳跃高度提高{JumpSpeedMul:float:2}%"--技能描述
    },
[1022] = {---北极熊技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3600, --cd
                effectType = {5}, --效果类型
                growUp = {                --成长
                    cd = -21.68, --cd
                },
            },
        },
        desc = "每{cd:time:s2m}分钟触发一次，让庄园内一颗成熟的果实获得一个“冰冻”变异（价值x10倍）"--技能描述
    },
[1023] = {---熊二技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 3600, --cd
                effectType = {8}, --效果类型
                growUp = {                --成长
                    cd = -21.68, --cd
                },
            },
        },
        desc = "每{cd:time:s2m}分钟触发一次，让庄园内一颗成熟的果实获得一个“尘晶”变异（价值x10倍）"--技能描述
    },
[1024] = {---初号熊技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2700, --cd
                effectType = {6}, --效果类型
                growUp = {                --成长
                    cd = -25.50, --cd
                },
            },
        },
		bonusStats = {----奖励到玩家的属性
		LightningRate  = 18.75,
		growUp = {                --成长
				LightningRate = 5.313,
            },
        },
        desc = "每{cd:time:s2m}分钟触发一次，让庄园内一颗成熟的果实获得一个“闪电”变异（价值x30倍），雷暴天气下，获得“闪电”的概率增高"--技能描述
},
[1025] = {---熊猫技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2700, --cd
                effectType = {51}, --效果类型
                growUp = {                --成长
                    cd = -25.50, --cd
                },
            },
        },
        desc = "每{cd:time:s2m}分钟触发一次，随机让庄园内一颗果实获得一个“竹福”变异,果实价值x4倍"--技能描述
    },
[1026] = {---火熊猫技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2700, --cd
                effectType = {51}, --效果类型
                growUp = {                --成长
                    cd = -25.50, --cd
                },
            },
        },
        bonusStats = {----奖励到玩家的属性
            SellBambooPriceMul  = 1.4,
			growUp = {                --成长
				SellBambooPriceMul = 0.0459,
            },
        },
        desc = "每{cd:time:s2m}分钟触发一次，随机让庄园内一颗果实获得一个“竹福”变异,果实价值x4倍，竹子售价提升{SellBambooPriceMul:percentage}"--技能描述
},
[1027] = {---金熊猫技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2700, --cd
                effectType = {51}, --效果类型
                growUp = {                --成长
                    cd = -30, --cd
                },
            },
        },
        bonusStats = {----奖励到玩家的属性
            SellBambooPriceMul  = 2.0,--竹子基础加成
			BambooToGoldRate = 12400,
			growUp = {                --成长
				SellBambooPriceMul = 0.0505,--竹子售价成长系数
				BambooToGoldRate = 625,
            },
        },
        desc = "每{cd:time:s2m}分钟触发一次，随机让庄园内一颗果实获得一个“竹福”变异,果实价值x4倍，竹子售价提升{SellBambooPriceMul:percentage}，提生竹子生长出“黄金” 变异的概率"--技能描述
},
[1028] = {---坤坤技能
        type = "PetSkill",--技能类型
        iconId = "",--技能图标，默认不配
        event = {
            eventName = "PlantEffect",--偷东西
            cdTimeUnit = "s", --cd时间单位: s 秒 m 分钟 h 小时 d 天
            params = {
                cd = 2700, --cd
                effectType = {50}, --效果类型
                growUp = {                --成长
                    cd = -25.50, --cd
                },
            },
            animName = "IdleAFK2",
        },
        desc = "每{cd:time:s2m}分钟触发一次，随机让庄园内一颗果实获得一个“陶醉”变异,果实价值x5倍"--技能描述
},
}