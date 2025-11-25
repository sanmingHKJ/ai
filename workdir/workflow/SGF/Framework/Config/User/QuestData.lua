--[[
    QuestData.lua - RPG Game Quest Configuration
    任务数据配置

    按照SGF标准化开发框架规范开发

    定义所有游戏任务的配置数据

    Version: 1.0.0
]]

local QuestData = {
    -- 任务配置表
    quests = {},
}

-- ============================================================================
-- Quest Type Definitions
-- ============================================================================

--[[
    任务类型:
    - main: 主线任务
    - side: 支线任务
    - daily: 日常任务
    - repeatable: 可重复任务
]]

-- ============================================================================
-- 新手任务 (ID: 1000-1099)
-- ============================================================================

QuestData.quests["quest_1001"] = {
    id = "quest_1001",
    name = "初入冒险",
    type = "main",
    minLevel = 1,
    repeatable = false,

    description = "欢迎来到这个世界！与任务NPC对话，了解基本情况。",

    objectives = {
        {
            id = "obj_1",
            type = "talk",
            description = "与任务NPC对话",
            npcId = "QuestNPC",
        },
    },

    rewards = {
        exp = 50,
        gold = 10,
    },

    -- NPC相关
    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

QuestData.quests["quest_1002"] = {
    id = "quest_1002",
    name = "史莱姆的威胁",
    type = "main",
    minLevel = 1,
    repeatable = false,
    prerequisites = {"quest_1001"},

    description = "森林中的史莱姆开始威胁到主城的安全。前往森林战场消灭3只史莱姆。",

    objectives = {
        {
            id = "obj_1",
            type = "kill",
            description = "击败史莱姆",
            target = "Slime",
            count = 3,
        },
    },

    rewards = {
        exp = 100,
        gold = 20,
        items = {
            {itemId = "potion_hp_small", quantity = 2},
        },
    },

    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

QuestData.quests["quest_1003"] = {
    id = "quest_1003",
    name = "狼群猎手",
    type = "main",
    minLevel = 2,
    repeatable = false,
    prerequisites = {"quest_1002"},

    description = "更危险的野狼出现了！击败5只野狼，保护主城的安全。",

    objectives = {
        {
            id = "obj_1",
            type = "kill",
            description = "击败野狼",
            target = "Wolf",
            count = 5,
        },
    },

    rewards = {
        exp = 200,
        gold = 50,
        items = {
            {itemId = "equipment_sword_iron", quantity = 1},
        },
    },

    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

-- ============================================================================
-- 收集任务 (ID: 2000-2099)
-- ============================================================================

QuestData.quests["quest_2001"] = {
    id = "quest_2001",
    name = "草药采集",
    type = "side",
    minLevel = 1,
    repeatable = true,

    description = "商店NPC需要一些草药来制作药水。收集5个草药交给他。",

    objectives = {
        {
            id = "obj_1",
            type = "collect",
            description = "收集草药",
            itemId = "item_herb",
            count = 5,
        },
    },

    rewards = {
        exp = 80,
        gold = 30,
        items = {
            {itemId = "potion_hp_medium", quantity = 1},
        },
    },

    questGiver = "ShopNPC",
    questReceiver = "ShopNPC",
}

QuestData.quests["quest_2002"] = {
    id = "quest_2002",
    name = "史莱姆粘液",
    type = "side",
    minLevel = 1,
    repeatable = true,

    description = "收集史莱姆的粘液，这是制作炼金材料的重要成分。",

    objectives = {
        {
            id = "obj_1",
            type = "collect",
            description = "收集史莱姆粘液",
            itemId = "item_slime_gel",
            count = 10,
        },
    },

    rewards = {
        exp = 60,
        gold = 25,
    },

    questGiver = "ShopNPC",
    questReceiver = "ShopNPC",
}

-- ============================================================================
-- 复合任务 (ID: 3000-3099)
-- ============================================================================

QuestData.quests["quest_3001"] = {
    id = "quest_3001",
    name = "森林清剿",
    type = "main",
    minLevel = 3,
    repeatable = false,
    prerequisites = {"quest_1003"},

    description = "彻底清理森林中的威胁。击败史莱姆和野狼，并与任务NPC汇报情况。",

    objectives = {
        {
            id = "obj_1",
            type = "kill",
            description = "击败史莱姆",
            target = "Slime",
            count = 5,
        },
        {
            id = "obj_2",
            type = "kill",
            description = "击败野狼",
            target = "Wolf",
            count = 5,
        },
        {
            id = "obj_3",
            type = "talk",
            description = "向任务NPC汇报",
            npcId = "QuestNPC",
        },
    },

    rewards = {
        exp = 300,
        gold = 100,
        items = {
            {itemId = "equipment_armor_leather", quantity = 1},
            {itemId = "potion_hp_large", quantity = 3},
        },
    },

    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

-- ============================================================================
-- 日常任务 (ID: 4000-4099)
-- ============================================================================

QuestData.quests["quest_4001"] = {
    id = "quest_4001",
    name = "每日狩猎：史莱姆",
    type = "daily",
    minLevel = 1,
    repeatable = true,

    description = "每日任务：击败10只史莱姆。",

    objectives = {
        {
            id = "obj_1",
            type = "kill",
            description = "击败史莱姆",
            target = "Slime",
            count = 10,
        },
    },

    rewards = {
        exp = 150,
        gold = 40,
    },

    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

QuestData.quests["quest_4002"] = {
    id = "quest_4002",
    name = "每日狩猎：野狼",
    type = "daily",
    minLevel = 2,
    repeatable = true,

    description = "每日任务：击败8只野狼。",

    objectives = {
        {
            id = "obj_1",
            type = "kill",
            description = "击败野狼",
            target = "Wolf",
            count = 8,
        },
    },

    rewards = {
        exp = 200,
        gold = 60,
    },

    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

-- ============================================================================
-- 商店相关任务 (ID: 5000-5099)
-- ============================================================================

QuestData.quests["quest_5001"] = {
    id = "quest_5001",
    name = "商人的请求",
    type = "side",
    minLevel = 1,
    repeatable = false,

    description = "商店NPC想要了解你的实力。与他对话并购买一件装备。",

    objectives = {
        {
            id = "obj_1",
            type = "talk",
            description = "与商店NPC对话",
            npcId = "ShopNPC",
        },
    },

    rewards = {
        exp = 50,
        gold = 50,
    },

    questGiver = "ShopNPC",
    questReceiver = "ShopNPC",
}

-- ============================================================================
-- 进阶任务 (ID: 6000-6099)
-- ============================================================================

QuestData.quests["quest_6001"] = {
    id = "quest_6001",
    name = "成为真正的冒险者",
    type = "main",
    minLevel = 5,
    repeatable = false,
    prerequisites = {"quest_3001"},

    description = "完成最终试炼，证明你已经成为一名真正的冒险者！",

    objectives = {
        {
            id = "obj_1",
            type = "kill",
            description = "击败史莱姆",
            target = "Slime",
            count = 20,
        },
        {
            id = "obj_2",
            type = "kill",
            description = "击败野狼",
            target = "Wolf",
            count = 15,
        },
        {
            id = "obj_3",
            type = "collect",
            description = "收集草药",
            itemId = "item_herb",
            count = 10,
        },
        {
            id = "obj_4",
            type = "talk",
            description = "向任务NPC汇报",
            npcId = "QuestNPC",
        },
    },

    rewards = {
        exp = 500,
        gold = 200,
        items = {
            {itemId = "equipment_sword_steel", quantity = 1},
            {itemId = "equipment_armor_iron", quantity = 1},
            {itemId = "potion_hp_large", quantity = 5},
            {itemId = "potion_mp_large", quantity = 5},
        },
    },

    questGiver = "QuestNPC",
    questReceiver = "QuestNPC",
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--[[
    根据ID获取任务配置
    @param questId - 任务ID
    @return table - 任务配置
]]
function QuestData:getQuestById(questId)
    return self.quests[questId]
end

--[[
    根据类型获取任务列表
    @param questType - 任务类型
    @return table - 任务列表
]]
function QuestData:getQuestsByType(questType)
    local result = {}
    for questId, quest in pairs(self.quests) do
        if quest.type == questType then
            table.insert(result, quest)
        end
    end
    return result
end

--[[
    根据等级获取可接任务
    @param level - 玩家等级
    @return table - 任务列表
]]
function QuestData:getQuestsByLevel(level)
    local result = {}
    for questId, quest in pairs(self.quests) do
        if not quest.minLevel or quest.minLevel <= level then
            table.insert(result, quest)
        end
    end
    return result
end

--[[
    获取所有主线任务
    @return table - 主线任务列表
]]
function QuestData:getMainQuests()
    return self:getQuestsByType("main")
end

--[[
    获取所有支线任务
    @return table - 支线任务列表
]]
function QuestData:getSideQuests()
    return self:getQuestsByType("side")
end

--[[
    获取所有日常任务
    @return table - 日常任务列表
]]
function QuestData:getDailyQuests()
    return self:getQuestsByType("daily")
end

-- 导出模块
return QuestData
