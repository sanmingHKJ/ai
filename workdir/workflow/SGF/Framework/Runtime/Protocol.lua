--[[
    Protocol.lua - RPG Game Network Protocol
    网络协议定义

    按照SGF标准化开发框架规范开发

    消息码分配规则:
    - 100-199: 玩家相关
    - 200-299: 战斗相关
    - 300-399: 背包相关
    - 400-499: 技能相关
    - 500-599: 任务相关
    - 600-699: 商店相关
    - 700-799: 装备相关
    - 800-899: 社交相关

    Version: 1.0.0
]]

local Protocol = {
    -- ========================================
    -- 客户端 -> 服务端 请求消息
    -- ========================================
    ClientMSGID = {
        -- 玩家相关 (100-199)
        PLAYER_CREATE_CHARACTER_REQ     = 100,  -- 创建角色请求
        PLAYER_GET_DATA_REQ             = 101,  -- 获取玩家数据请求
        PLAYER_SAVE_DATA_REQ            = 102,  -- 保存玩家数据请求
        PLAYER_CHANGE_SCENE_REQ         = 103,  -- 切换场景请求
        PLAYER_LEVEL_UP_REQ             = 104,  -- 升级请求

        -- 战斗相关 (200-299)
        COMBAT_START_REQ                = 200,  -- 开始战斗请求
        COMBAT_ACTION_REQ               = 201,  -- 战斗行动请求 (攻击/技能/道具/逃跑)
        COMBAT_END_REQ                  = 202,  -- 结束战斗请求
        COMBAT_FLEE_REQ                 = 203,  -- 逃跑请求

        -- 背包相关 (300-399)
        INVENTORY_GET_REQ               = 300,  -- 获取背包数据请求
        INVENTORY_USE_ITEM_REQ          = 301,  -- 使用物品请求
        INVENTORY_DROP_ITEM_REQ         = 302,  -- 丢弃物品请求
        INVENTORY_SORT_REQ              = 303,  -- 整理背包请求
        INVENTORY_EXPAND_REQ            = 304,  -- 扩展背包请求

        -- 技能相关 (400-499)
        SKILL_LEARN_REQ                 = 400,  -- 学习技能请求
        SKILL_UPGRADE_REQ               = 401,  -- 升级技能请求
        SKILL_SET_SHORTCUT_REQ          = 402,  -- 设置快捷栏请求
        SKILL_GET_LIST_REQ              = 403,  -- 获取技能列表请求

        -- 任务相关 (500-599)
        QUEST_ACCEPT_REQ                = 500,  -- 接受任务请求
        QUEST_SUBMIT_REQ                = 501,  -- 提交任务请求
        QUEST_ABANDON_REQ               = 502,  -- 放弃任务请求
        QUEST_GET_LIST_REQ              = 503,  -- 获取任务列表请求
        QUEST_UPDATE_PROGRESS_REQ       = 504,  -- 更新任务进度请求

        -- 商店相关 (600-699)
        SHOP_BUY_ITEM_REQ               = 600,  -- 购买物品请求
        SHOP_SELL_ITEM_REQ              = 601,  -- 出售物品请求
        SHOP_GET_LIST_REQ               = 602,  -- 获取商店列表请求

        -- 装备相关 (700-799)
        EQUIPMENT_EQUIP_REQ             = 700,  -- 装备物品请求
        EQUIPMENT_UNEQUIP_REQ           = 701,  -- 卸下装备请求
        EQUIPMENT_GET_REQ               = 702,  -- 获取装备信息请求
        EQUIPMENT_UPGRADE_REQ           = 703,  -- 升级装备请求

        -- 场景相关 (800-899)
        SCENE_CHANGE_REQ                = 800,  -- 场景切换请求
        PORTAL_TOUCH_REQ                = 801,  -- 传送门触碰请求
        SCENE_OBJECT_INTERACT_REQ       = 802,  -- 场景对象交互请求
        RETURN_TO_MAINCITY_REQ          = 803,  -- 返回主城请求(UI按钮)

        -- NPC交互相关 (850-899)
        NPC_INTERACT_REQ                = 850,  -- NPC交互请求
        NPC_DIALOGUE_CHOICE_REQ         = 851,  -- 对话选项选择请求
        NPC_SHOP_BUY_REQ                = 852,  -- NPC商店购买请求
        NPC_SHOP_SELL_REQ               = 853,  -- NPC商店出售请求
    },

    -- ========================================
    -- 服务端 -> 客户端 响应/通知消息
    -- ========================================
    ServerMSGID = {
        -- 玩家相关 (100-199)
        PLAYER_CREATE_CHARACTER_RSP     = 100,  -- 创建角色响应
        PLAYER_GET_DATA_RSP             = 101,  -- 获取玩家数据响应
        PLAYER_SAVE_DATA_RSP            = 102,  -- 保存玩家数据响应
        PLAYER_CHANGE_SCENE_RSP         = 103,  -- 切换场景响应
        PLAYER_LEVEL_UP_RSP             = 104,  -- 升级响应
        PLAYER_DATA_UPDATE_NOTIFY       = 110,  -- 玩家数据更新通知
        PLAYER_STATS_UPDATE_NOTIFY      = 111,  -- 玩家属性更新通知
        PLAYER_EXP_UPDATE_NOTIFY        = 112,  -- 经验值更新通知
        PLAYER_HEALTH_UPDATE_NOTIFY     = 113,  -- 生命值更新通知
        PLAYER_MANA_UPDATE_NOTIFY       = 114,  -- 魔法值更新通知

        -- 战斗相关 (200-299)
        COMBAT_START_RSP                = 200,  -- 开始战斗响应
        COMBAT_ACTION_RSP               = 201,  -- 战斗行动响应
        COMBAT_END_RSP                  = 202,  -- 结束战斗响应
        COMBAT_FLEE_RSP                 = 203,  -- 逃跑响应
        COMBAT_TURN_NOTIFY              = 210,  -- 回合通知
        COMBAT_DAMAGE_NOTIFY            = 211,  -- 伤害通知
        COMBAT_HEAL_NOTIFY              = 212,  -- 治疗通知
        COMBAT_BUFF_NOTIFY              = 213,  -- Buff通知
        COMBAT_DEATH_NOTIFY             = 214,  -- 死亡通知
        COMBAT_VICTORY_NOTIFY           = 215,  -- 胜利通知
        COMBAT_DEFEAT_NOTIFY            = 216,  -- 失败通知

        -- 背包相关 (300-399)
        INVENTORY_GET_RSP               = 300,  -- 获取背包数据响应
        INVENTORY_USE_ITEM_RSP          = 301,  -- 使用物品响应
        INVENTORY_DROP_ITEM_RSP         = 302,  -- 丢弃物品响应
        INVENTORY_SORT_RSP              = 303,  -- 整理背包响应
        INVENTORY_EXPAND_RSP            = 304,  -- 扩展背包响应
        INVENTORY_UPDATE_NOTIFY         = 310,  -- 背包更新通知
        INVENTORY_ITEM_ADD_NOTIFY       = 311,  -- 物品添加通知
        INVENTORY_ITEM_REMOVE_NOTIFY    = 312,  -- 物品移除通知

        -- 技能相关 (400-499)
        SKILL_LEARN_RSP                 = 400,  -- 学习技能响应
        SKILL_UPGRADE_RSP               = 401,  -- 升级技能响应
        SKILL_SET_SHORTCUT_RSP          = 402,  -- 设置快捷栏响应
        SKILL_GET_LIST_RSP              = 403,  -- 获取技能列表响应
        SKILL_LEARNED_NOTIFY            = 410,  -- 技能学习通知
        SKILL_COOLDOWN_NOTIFY           = 411,  -- 技能冷却通知

        -- 任务相关 (500-599)
        QUEST_ACCEPT_RSP                = 500,  -- 接受任务响应
        QUEST_SUBMIT_RSP                = 501,  -- 提交任务响应
        QUEST_ABANDON_RSP               = 502,  -- 放弃任务响应
        QUEST_GET_LIST_RSP              = 503,  -- 获取任务列表响应
        QUEST_UPDATE_PROGRESS_RSP       = 504,  -- 更新任务进度响应
        QUEST_PROGRESS_NOTIFY           = 510,  -- 任务进度通知
        QUEST_COMPLETE_NOTIFY           = 511,  -- 任务完成通知
        QUEST_NEW_NOTIFY                = 512,  -- 新任务通知

        -- 商店相关 (600-699)
        SHOP_BUY_ITEM_RSP               = 600,  -- 购买物品响应
        SHOP_SELL_ITEM_RSP              = 601,  -- 出售物品响应
        SHOP_GET_LIST_RSP               = 602,  -- 获取商店列表响应

        -- 装备相关 (700-799)
        EQUIPMENT_EQUIP_RSP             = 700,  -- 装备物品响应
        EQUIPMENT_UNEQUIP_RSP           = 701,  -- 卸下装备响应
        EQUIPMENT_GET_RSP               = 702,  -- 获取装备信息响应
        EQUIPMENT_UPGRADE_RSP           = 703,  -- 升级装备响应
        EQUIPMENT_UPDATE_NOTIFY         = 710,  -- 装备更新通知

        -- 场景相关 (800-899)
        SCENE_CHANGE_RSP                = 800,  -- 场景切换响应
        PORTAL_TOUCH_RSP                = 801,  -- 传送门触碰响应
        SCENE_OBJECT_INTERACT_RSP       = 802,  -- 场景对象交互响应
        RETURN_TO_MAINCITY_RSP          = 803,  -- 返回主城响应
        SCENE_CHANGED_NOTIFY            = 810,  -- 场景切换通知
        SCENE_ENTER_NOTIFY              = 811,  -- 进入场景通知
        SCENE_EXIT_NOTIFY               = 812,  -- 离开场景通知

        -- NPC交互相关 (850-899)
        NPC_INTERACT_RSP                = 850,  -- NPC交互响应
        NPC_DIALOGUE_CHOICE_RSP         = 851,  -- 对话选项选择响应
        NPC_SHOP_BUY_RSP                = 852,  -- NPC商店购买响应
        NPC_SHOP_SELL_RSP               = 853,  -- NPC商店出售响应
        NPC_DIALOGUE_UPDATE_NOTIFY      = 860,  -- 对话更新通知
        NPC_INTERACTION_HINT_NOTIFY     = 861,  -- NPC交互提示通知

        -- 通用消息 (900-999)
        ERROR_NOTIFY                    = 900,  -- 错误通知
        MESSAGE_NOTIFY                  = 901,  -- 消息通知
        SYSTEM_MESSAGE_NOTIFY           = 902,  -- 系统消息通知
        SERVER_TIME_NOTIFY              = 903,  -- 服务器时间通知
    },
}

return Protocol