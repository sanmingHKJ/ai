--[[
    EquipmentSystemServer.lua - 装备系统（服务端）

    职责：
    1. 管理玩家装备槽位（武器、头盔、胸甲等）
    2. 处理装备穿戴/卸下请求和验证
    3. 计算装备属性加成
    4. 更新玩家总属性（与PlayerSystem集成）
    5. 装备强化/升级
    6. 套装效果

    框架特性：
    - 多槽位装备系统（武器、头盔、胸甲、腿甲、鞋子、饰品等）
    - 装备需求验证（等级、职业、属性）
    - 属性加成系统（基础属性+附加属性）
    - 套装系统（穿戴多件同套装获得额外属性）
    - 装备耐久度系统
    - 装备强化系统

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local EquipmentSystemServer = {
    -- ========== 基础信息 ==========
    name = "EquipmentSystemServer",
    version = "1.0.0",
    description = "装备系统（服务端）",

    -- ========== 依赖声明 ==========
    dependencies = {
        "PlayerSystemServer",
        "InventorySystemServer",
    },

    -- ========== 状态管理 ==========
    state = "uninitialized",

    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,

    -- ========== 配置 ==========
    config = {
        equipmentSlots = {
            "Weapon",      -- 武器
            "Head",        -- 头盔
            "Chest",       -- 胸甲
            "Legs",        -- 腿甲
            "Feet",        -- 鞋子
            "Accessory1",  -- 饰品1
            "Accessory2",  -- 饰品2
        },
    },

    -- ========== 数据 ==========
    data = {
        playerEquipments = {},  -- [userId] = EquipmentData
        setEffects = {},        -- 套装效果定义
    },

    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

--[[
    装备数据结构：
    EquipmentData = {
        userId = id,
        slots = {
            Weapon = {
                itemId = 3001,
                slotType = "Weapon",
                enhanceLevel = 0,       -- 强化等级
                durability = 100,       -- 耐久度
                maxDurability = 100,
                properties = {},        -- 特殊属性
            },
            Head = nil,
            Chest = nil,
            ...
        },
        totalStats = {
            attack = 15,
            defense = 10,
            maxHp = 0,
            maxMp = 0,
            ...
        },
        activeSets = {},  -- 激活的套装效果
    }

    套装定义：
    SetEffect = {
        setId = id,
        name = "战士套装",
        pieces = {3001, 3002, 3003},  -- 套装物品ID列表
        bonuses = {
            [2] = {attack = 5},        -- 穿戴2件：攻击+5
            [3] = {attack = 10, defense = 5},  -- 穿戴3件：攻击+10，防御+5
        },
    }
]]

function EquipmentSystemServer.new(sgf)
    local self = setmetatable({}, {__index = EquipmentSystemServer})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.data = {
        playerEquipments = {},
        setEffects = {},
    }
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function EquipmentSystemServer:PreInit()
    self.log:info("EquipmentSystemServer PreInit...")

    -- 注册事件监听器
    self:registerEventListeners()

    return true
end

function EquipmentSystemServer:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("EquipmentSystemServer already initialized")
        return false
    end

    self.log:info("EquipmentSystemServer Init...")

    -- 加载配置
    self:loadConfig()

    -- 加载套装效果
    self:loadSetEffects()

    -- 注册网络消息处理
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function EquipmentSystemServer:PostInit()
    self.log:info("EquipmentSystemServer PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    return true
end

function EquipmentSystemServer:Start()
    if self.state ~= "initialized" then
        self.log:error("EquipmentSystemServer cannot start, state: " .. self.state)
        return false
    end

    self.log:info("EquipmentSystemServer Start...")

    self.state = "started"
    self.events:emit("EquipmentSystemStarted", {timestamp = os.time()})

    return true
end

function EquipmentSystemServer:Update(dt)
    -- 装备系统通常不需要每帧更新
end

function EquipmentSystemServer:Stop()
    self.log:info("EquipmentSystemServer Stop...")

    -- 保存所有装备数据
    self:saveAllEquipments()

    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function EquipmentSystemServer:loadConfig()
    self.log:debug("EquipmentSystemServer config loaded")
end

function EquipmentSystemServer:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
        self.dependencies_cache.InventorySystem = self.sgf.businessSystemManager:get("InventorySystemServer")

        if self.dependencies_cache.PlayerSystem then
            self.log:debug("EquipmentSystemServer resolved dependency: PlayerSystemServer")
        end

        if self.dependencies_cache.InventorySystem then
            self.log:debug("EquipmentSystemServer resolved dependency: InventorySystemServer")
        end
    end
end

function EquipmentSystemServer:loadSetEffects()
    self.log:info("Loading set effects...")

    -- 示例套装效果
    self.data.setEffects = {
        [1] = {
            setId = 1,
            name = "战士套装",
            pieces = {3001, 3003, 3004},  -- 新手剑、战士头盔、战士胸甲
            bonuses = {
                [2] = {attack = 5, defense = 3},
                [3] = {attack = 12, defense = 8, maxHp = 30},
            },
        },
        [2] = {
            setId = 2,
            name = "法师套装",
            pieces = {3002, 3005, 3006},  -- 法师长袍、法师帽、法师鞋
            bonuses = {
                [2] = {attack = 8, maxMp = 20},
                [3] = {attack = 18, maxMp = 50, defense = 5},
            },
        },
    }

    self.log:info("Loaded set effects")
end

-- ========================================
-- 事件监听
-- ========================================

function EquipmentSystemServer:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听玩家加入游戏
    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)

    -- 监听玩家离开游戏
    self.events:on(EventID.PlayerLeft, function(data)
        self:onPlayerLeft(data)
    end)

    self.log:debug("EquipmentSystemServer event listeners registered")
end

function EquipmentSystemServer:onPlayerJoined(data)
    if not data or not data.userId then
        self.log:warning("PlayerJoined event data is invalid")
        return
    end

    local userId = data.userId
    self.log:debug("Player joined, initializing equipment: " .. tostring(userId))

    -- 初始化玩家装备
    self:initPlayerEquipment(userId)

    -- 加载玩家装备数据
    self:loadPlayerEquipment(userId)
end

function EquipmentSystemServer:onPlayerLeft(data)
    if not data or not data.userId then
        self.log:warning("PlayerLeft event data is invalid")
        return
    end

    local userId = data.userId
    self.log:debug("Player left, saving equipment: " .. tostring(userId))

    -- 保存玩家装备数据
    self:savePlayerEquipment(userId)

    -- 清理数据
    self.data.playerEquipments[userId] = nil
end

-- ========================================
-- 网络消息处理
-- ========================================

function EquipmentSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:OnRequest(Protocol.ClientMSGID.EQUIPMENT_EQUIP_REQ, function(userId, msgid, data)
        return self:handleEquipRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.EQUIPMENT_UNEQUIP_REQ, function(userId, msgid, data)
        return self:handleUnequipRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.EQUIPMENT_GET_REQ, function(userId, msgid, data)
        return self:handleGetEquipmentRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.EQUIPMENT_UPGRADE_REQ, function(userId, msgid, data)
        return self:handleUpgradeRequest(userId, data)
    end)

    self.log:debug("EquipmentSystemServer network handlers registered")
end

-- ========================================
-- 玩家装备数据管理
-- ========================================

function EquipmentSystemServer:initPlayerEquipment(userId)
    if self.data.playerEquipments[userId] then
        return
    end

    self.data.playerEquipments[userId] = {
        userId = userId,
        slots = {},
        totalStats = {
            attack = 0,
            defense = 0,
            maxHp = 0,
            maxMp = 0,
        },
        activeSets = {},
    }

    self.log:debug("Initialized equipment for userId: " .. userId)
end

function EquipmentSystemServer:loadPlayerEquipment(userId)
    -- 从数据存储加载装备数据
    -- TODO: 实现数据持久化

    self.log:debug("Loaded equipment for userId: " .. userId)
end

function EquipmentSystemServer:savePlayerEquipment(userId)
    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return
    end

    -- 保存到数据存储
    -- TODO: 实现数据持久化

    self.log:debug("Saved equipment for userId: " .. userId)
end

function EquipmentSystemServer:saveAllEquipments()
    for userId, _ in pairs(self.data.playerEquipments) do
        self:savePlayerEquipment(userId)
    end
end

-- ========================================
-- 装备穿戴/卸下
-- ========================================

function EquipmentSystemServer:equipItem(userId, itemId, inventorySlotIndex)
    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return false, "装备数据不存在"
    end

    local inventorySystem = self.dependencies_cache.InventorySystem
    if not inventorySystem then
        return false, "系统错误"
    end

    -- 获取物品模板
    local template = inventorySystem:getItemTemplate(itemId)
    if not template then
        return false, "物品不存在"
    end

    if template.itemType ~= "Equipment" then
        return false, "该物品不是装备"
    end

    local equipData = template.equipmentData
    if not equipData then
        return false, "装备数据错误"
    end

    -- 检查装备需求
    local valid, reason = self:checkEquipmentRequirements(userId, template)
    if not valid then
        return false, reason
    end

    local slotType = equipData.slot

    -- 如果槽位已有装备，先卸下
    if equipment.slots[slotType] then
        local success, reason = self:unequipItem(userId, slotType)
        if not success then
            return false, reason
        end
    end

    -- 从背包移除物品
    local success, reason = inventorySystem:removeItem(userId, itemId, 1)
    if not success then
        return false, reason
    end

    -- 穿戴装备
    equipment.slots[slotType] = {
        itemId = itemId,
        slotType = slotType,
        enhanceLevel = 0,
        durability = 100,
        maxDurability = 100,
        properties = {},
    }

    self.log:info(string.format("Player %s equipped item %d to slot %s", userId, itemId, slotType))

    -- 重新计算属性
    self:recalculateStats(userId)

    -- 发送事件
    self.events:emit("EquipmentEquipped", {
        userId = userId,
        itemId = itemId,
        slotType = slotType,
        timestamp = os.time()
    })

    return true
end

function EquipmentSystemServer:unequipItem(userId, slotType)
    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return false, "装备数据不存在"
    end

    local slot = equipment.slots[slotType]
    if not slot then
        return false, "该槽位没有装备"
    end

    local inventorySystem = self.dependencies_cache.InventorySystem
    if not inventorySystem then
        return false, "系统错误"
    end

    -- 检查背包是否有空位
    local emptySlot = inventorySystem:findEmptySlot(userId)
    if not emptySlot then
        return false, "背包已满"
    end

    local itemId = slot.itemId

    -- 卸下装备
    equipment.slots[slotType] = nil

    -- 放回背包
    inventorySystem:addItem(userId, itemId, 1, true)

    self.log:info(string.format("Player %s unequipped item %d from slot %s", userId, itemId, slotType))

    -- 重新计算属性
    self:recalculateStats(userId)

    -- 发送事件
    self.events:emit("EquipmentUnequipped", {
        userId = userId,
        itemId = itemId,
        slotType = slotType,
        timestamp = os.time()
    })

    return true
end

-- ========================================
-- 装备需求验证
-- ========================================

function EquipmentSystemServer:checkEquipmentRequirements(userId, template)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return false, "系统错误"
    end

    local playerData = playerSystem:getPlayerData(userId)
    if not playerData then
        return false, "玩家数据不存在"
    end

    local requirements = template.equipmentData.requirements
    if not requirements then
        return true  -- 没有需求限制
    end

    -- 检查等级
    if requirements.level and playerData.level < requirements.level then
        return false, string.format("需要等级%d", requirements.level)
    end

    -- 检查职业
    if requirements.classType and #requirements.classType > 0 then
        local classMatch = false
        for _, className in ipairs(requirements.classType) do
            if playerData.classType == className then
                classMatch = true
                break
            end
        end
        if not classMatch then
            return false, "职业不符合要求"
        end
    end

    return true
end

-- ========================================
-- 属性计算
-- ========================================

function EquipmentSystemServer:recalculateStats(userId)
    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return
    end

    local inventorySystem = self.dependencies_cache.InventorySystem
    if not inventorySystem then
        return
    end

    -- 重置总属性
    equipment.totalStats = {
        attack = 0,
        defense = 0,
        maxHp = 0,
        maxMp = 0,
    }

    -- 累加所有装备的属性
    for slotType, slot in pairs(equipment.slots) do
        local template = inventorySystem:getItemTemplate(slot.itemId)
        if template and template.equipmentData then
            local stats = template.equipmentData.stats
            for statName, statValue in pairs(stats) do
                equipment.totalStats[statName] = (equipment.totalStats[statName] or 0) + statValue
            end

            -- 强化等级加成（每级+5%基础属性）
            if slot.enhanceLevel > 0 then
                local enhanceBonus = slot.enhanceLevel * 0.05
                for statName, statValue in pairs(stats) do
                    equipment.totalStats[statName] = equipment.totalStats[statName] + math.floor(statValue * enhanceBonus)
                end
            end
        end
    end

    -- 计算套装效果
    self:calculateSetEffects(userId)

    -- 更新玩家属性
    self:updatePlayerStats(userId)

    -- 同步装备数据
    self:syncEquipment(userId)

    self.log:debug("Recalculated stats for userId: " .. userId)
end

function EquipmentSystemServer:calculateSetEffects(userId)
    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return
    end

    equipment.activeSets = {}

    -- 收集当前穿戴的所有装备ID
    local equippedItems = {}
    for _, slot in pairs(equipment.slots) do
        table.insert(equippedItems, slot.itemId)
    end

    -- 检查每个套装
    for _, setEffect in pairs(self.data.setEffects) do
        local equippedPieces = 0

        -- 计算穿戴了多少件套装物品
        for _, pieceId in ipairs(setEffect.pieces) do
            for _, equippedId in ipairs(equippedItems) do
                if pieceId == equippedId then
                    equippedPieces = equippedPieces + 1
                    break
                end
            end
        end

        -- 应用套装效果
        if equippedPieces >= 2 then
            equipment.activeSets[setEffect.setId] = equippedPieces

            for pieceCount, bonus in pairs(setEffect.bonuses) do
                if equippedPieces >= pieceCount then
                    for statName, statValue in pairs(bonus) do
                        equipment.totalStats[statName] = (equipment.totalStats[statName] or 0) + statValue
                    end
                end
            end

            self.log:debug(string.format("Player %s activated set %d (%d pieces)",
                userId, setEffect.setId, equippedPieces))
        end
    end
end

function EquipmentSystemServer:updatePlayerStats(userId)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return
    end

    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return
    end

    -- 通知PlayerSystem更新玩家装备加成
    playerSystem:updateEquipmentBonus(userId, equipment.totalStats)
end

-- ========================================
-- 装备强化
-- ========================================

function EquipmentSystemServer:upgradeEquipment(userId, slotType)
    local equipment = self.data.playerEquipments[userId]
    if not equipment then
        return false, "装备数据不存在"
    end

    local slot = equipment.slots[slotType]
    if not slot then
        return false, "该槽位没有装备"
    end

    -- 检查强化等级上限
    if slot.enhanceLevel >= 10 then
        return false, "已达到最高强化等级"
    end

    -- TODO: 检查强化材料和金币

    -- 强化成功
    slot.enhanceLevel = slot.enhanceLevel + 1

    self.log:info(string.format("Player %s upgraded equipment in slot %s to level %d",
        userId, slotType, slot.enhanceLevel))

    -- 重新计算属性
    self:recalculateStats(userId)

    -- 发送事件
    self.events:emit("EquipmentUpgraded", {
        userId = userId,
        slotType = slotType,
        newLevel = slot.enhanceLevel,
        timestamp = os.time()
    })

    return true
end

-- ========================================
-- 网络请求处理
-- ========================================

function EquipmentSystemServer:handleEquipRequest(userId, data)
    
    local itemId = data.itemId
    local inventorySlotIndex = data.inventorySlotIndex

    self.log:debug(string.format("Player %s requests to equip item %d", userId, itemId))

    local success, reason = self:equipItem(userId, itemId, inventorySlotIndex)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.EQUIPMENT_EQUIP_RSP, {
        success = success,
        itemId = itemId,
        reason = reason,
    })
end

function EquipmentSystemServer:handleUnequipRequest(userId, data)
    
    local slotType = data.slotType

    self.log:debug(string.format("Player %s requests to unequip from slot %s", userId, slotType))

    local success, reason = self:unequipItem(userId, slotType)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.EQUIPMENT_UNEQUIP_RSP, {
        success = success,
        slotType = slotType,
        reason = reason,
    })
end

function EquipmentSystemServer:handleGetEquipmentRequest(userId, data)
    

    self.log:debug("Player " .. userId .. " requests equipment")

    self:sendEquipment(userId)
end

function EquipmentSystemServer:handleUpgradeRequest(userId, data)
    
    local slotType = data.slotType

    self.log:debug(string.format("Player %s requests to upgrade equipment in slot %s", userId, slotType))

    local success, reason = self:upgradeEquipment(userId, slotType)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.EQUIPMENT_UPGRADE_RSP, {
        success = success,
        slotType = slotType,
        reason = reason,
    })
end

function EquipmentSystemServer:sendEquipment(userId)
    
    local equipment = self.data.playerEquipments[userId]

    if not equipment then
        return
    end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.EQUIPMENT_GET_RSP, {
        success = true,
        slots = equipment.slots,
        totalStats = equipment.totalStats,
        activeSets = equipment.activeSets,
    })
end

function EquipmentSystemServer:syncEquipment(userId)
    -- 通知客户端更新装备
    self.events:emit("EquipmentUpdated", {
        userId = userId,
        timestamp = os.time()
    })
end

-- ========================================
-- 公共API
-- ========================================

function EquipmentSystemServer:getPlayerEquipment(userId)
    return self.data.playerEquipments[userId]
end

function EquipmentSystemServer:getTotalStats(userId)
    local equipment = self.data.playerEquipments[userId]
    return equipment and equipment.totalStats or {}
end

function EquipmentSystemServer:getEquippedItem(userId, slotType)
    local equipment = self.data.playerEquipments[userId]
    return equipment and equipment.slots[slotType] or nil
end

return EquipmentSystemServer
