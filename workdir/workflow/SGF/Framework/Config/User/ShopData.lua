--[[
    ShopData.lua - RPG Game Shop Configuration
    商店数据配置

    按照SGF标准化开发框架规范开发

    Version: 1.0.0
]]

local ShopData = {
    shops = {},
}

-- ============================================================================
-- 主城商店 - 商人NPC (ShopNPC)
-- ============================================================================

ShopData.shops["MainCityShop"] = {
    id = "MainCityShop",
    name = "主城杂货铺",
    npcId = "ShopNPC",
    type = "general",

    items = {
        -- 消耗品
        {
            itemId = "potion_hp_small",
            name = "小型生命药水",
            description = "恢复50点生命值",
            price = 10,
            stock = -1,  -- -1表示无限库存
            currentStock = -1,
        },
        {
            itemId = "potion_hp_medium",
            name = "中型生命药水",
            description = "恢复150点生命值",
            price = 30,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "potion_hp_large",
            name = "大型生命药水",
            description = "恢复300点生命值",
            price = 60,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "potion_mp_small",
            name = "小型魔法药水",
            description = "恢复30点魔法值",
            price = 15,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "potion_mp_medium",
            name = "中型魔法药水",
            description = "恢复80点魔法值",
            price = 40,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "potion_mp_large",
            name = "大型魔法药水",
            description = "恢复150点魔法值",
            price = 80,
            stock = -1,
            currentStock = -1,
        },

        -- 基础装备
        {
            itemId = "equipment_sword_iron",
            name = "铁剑",
            description = "基础的铁制武器\n攻击力+10",
            price = 100,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "equipment_sword_steel",
            name = "钢剑",
            description = "更强的钢制武器\n攻击力+20",
            price = 300,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "equipment_armor_leather",
            name = "皮甲",
            description = "基础的皮革护甲\n防御力+8",
            price = 80,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "equipment_armor_iron",
            name = "铁甲",
            description = "坚固的铁制护甲\n防御力+15",
            price = 250,
            stock = -1,
            currentStock = -1,
        },

        -- 材料
        {
            itemId = "item_herb",
            name = "草药",
            description = "制作药水的基础材料",
            price = 5,
            stock = -1,
            currentStock = -1,
        },
    },
}

-- ============================================================================
-- 高级装备商店 (后续扩展)
-- ============================================================================

ShopData.shops["AdvancedEquipmentShop"] = {
    id = "AdvancedEquipmentShop",
    name = "高级装备铺",
    npcId = "EquipmentMerchant",  -- 需要新增NPC
    type = "equipment",
    minLevel = 5,  -- 需要等级5才能访问

    items = {
        {
            itemId = "equipment_sword_mithril",
            name = "秘银剑",
            description = "稀有的秘银武器\n攻击力+35",
            price = 800,
            stock = 5,
            currentStock = 5,
        },
        {
            itemId = "equipment_armor_mithril",
            name = "秘银甲",
            description = "稀有的秘银护甲\n防御力+30",
            price = 1000,
            stock = 3,
            currentStock = 3,
        },
        {
            itemId = "equipment_ring_power",
            name = "力量之戒",
            description = "增强力量的戒指\n力量+5",
            price = 500,
            stock = 10,
            currentStock = 10,
        },
    },
}

-- ============================================================================
-- 技能书商店 (后续扩展)
-- ============================================================================

ShopData.shops["SkillBookShop"] = {
    id = "SkillBookShop",
    name = "技能学院",
    npcId = "SkillMaster",  -- 需要新增NPC
    type = "skill",

    items = {
        {
            itemId = "skillbook_fireball",
            name = "技能书：火球术",
            description = "学习火球术技能",
            price = 200,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "skillbook_heal",
            name = "技能书：治疗术",
            description = "学习治疗术技能",
            price = 150,
            stock = -1,
            currentStock = -1,
        },
        {
            itemId = "skillbook_shield",
            name = "技能书：护盾术",
            description = "学习护盾术技能",
            price = 180,
            stock = -1,
            currentStock = -1,
        },
    },
}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--[[
    根据ID获取商店配置
]]
function ShopData:getShopById(shopId)
    return self.shops[shopId]
end

--[[
    根据NPC获取商店
]]
function ShopData:getShopByNPC(npcId)
    for shopId, shop in pairs(self.shops) do
        if shop.npcId == npcId then
            return shop
        end
    end
    return nil
end

--[[
    根据类型获取商店列表
]]
function ShopData:getShopsByType(shopType)
    local result = {}
    for shopId, shop in pairs(self.shops) do
        if shop.type == shopType then
            table.insert(result, shop)
        end
    end
    return result
end

return ShopData
