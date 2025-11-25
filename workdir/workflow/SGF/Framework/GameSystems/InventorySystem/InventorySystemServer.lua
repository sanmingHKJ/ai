--[[
    InventorySystemServer.lua - 背包系统（服务端）

    职责：
    1. 管理玩家背包数据（物品列表、容量）
    2. 处理物品增加/删除操作
    3. 处理物品使用请求和验证
    4. 管理物品堆叠
    5. 处理背包扩展
    6. 物品掉落和拾取

    框架特性：
    - 基于槽位的背包系统
    - 物品堆叠支持（可堆叠/不可堆叠）
    - 物品类型分类（消耗品、装备、材料、任务物品）
    - 物品使用效果系统
    - 自动整理功能

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local InventorySystemServer = {
    -- ========== 基础信息 ==========
    name = "InventorySystemServer",
    version = "1.0.0",
    description = "背包系统（服务端）",

    -- ========== 依赖声明 ==========
    dependencies = {
        "PlayerSystemServer",
    },

    -- ========== 状态管理 ==========
    state = "uninitialized",

    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,

    -- ========== 配置 ==========
    config = {
        defaultCapacity = 20,      -- 默认背包容量
        maxCapacity = 100,         -- 最大背包容量
        expandSlotCount = 5,       -- 每次扩展增加的槽位数
        expandCost = 1000,         -- 扩展费用（金币）
        maxStackSize = 99,         -- 默认最大堆叠数量
    },

    -- ========== 数据 ==========
    data = {
        playerInventories = {},    -- [playerId] = InventoryData
        itemTemplates = {},        -- [itemId] = ItemTemplate（物品模板）
    },

    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

--[[
    背包数据结构：
    InventoryData = {
        playerId = id,
        capacity = 20,             -- 背包容量
        slots = {
            [slotIndex] = {
                itemId = id,
                quantity = count,
                slotIndex = index,
                timestamp = os.time(),  -- 获得时间
                properties = {},        -- 物品特殊属性（如耐久度）
            }
        },
        gold = 1000,               -- 金币（也可以作为特殊物品）
    }

    ItemTemplate（物品模板）= {
        itemId = id,
        name = "物品名称",
        description = "物品描述",
        iconPath = "path/to/icon",

        -- 物品类型
        itemType = "Consumable|Equipment|Material|QuestItem|Currency",
        subType = "Potion|Weapon|Armor|...",

        -- 堆叠
        stackable = true,
        maxStack = 99,

        -- 品质
        quality = "Common|Uncommon|Rare|Epic|Legendary",  -- 普通、优秀、稀有、史诗、传说

        -- 价值
        buyPrice = 100,            -- 购买价格
        sellPrice = 50,            -- 出售价格

        -- 使用
        usable = true,
        useEffect = {
            effectType = "RestoreHP|RestoreMp|Buff|...",
            value = 50,
            duration = 0,
        },

        -- 装备属性（如果是装备）
        equipmentData = {
            slot = "Weapon|Head|Chest|Legs|...",
            stats = {
                attack = 10,
                defense = 5,
            },
            requirements = {
                level = 5,
                classType = {"Warrior"},
            },
        },

        -- 获取条件
        obtainMethods = {"Shop", "Drop", "Quest", "Craft"},

        -- 其他
        unique = false,            -- 唯一物品
        tradable = true,           -- 可交易
        dropable = true,           -- 可丢弃
    }
]]

function InventorySystemServer.new(sgf)
    local self = setmetatable({}, {__index = InventorySystemServer})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.data = {
        playerInventories = {},
        itemTemplates = {},
    }
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function InventorySystemServer:PreInit()
    self.log:info("InventorySystemServer PreInit...")

    -- 注册事件监听器
    self:registerEventListeners()

    return true
end

function InventorySystemServer:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("InventorySystemServer already initialized")
        return false
    end

    self.log:info("InventorySystemServer Init...")

    -- 加载配置
    self:loadConfig()

    -- 加载物品模板
    self:loadItemTemplates()

    -- 注册网络消息处理
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function InventorySystemServer:PostInit()
    self.log:info("InventorySystemServer PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    return true
end

function InventorySystemServer:Start()
    if self.state ~= "initialized" then
        self.log:error("InventorySystemServer cannot start, state: " .. self.state)
        return false
    end

    self.log:info("InventorySystemServer Start...")

    self.state = "started"
    self.events:emit("InventorySystemStarted", {timestamp = os.time()})

    return true
end

function InventorySystemServer:Update(dt)
    -- 背包系统通常不需要每帧更新
end

function InventorySystemServer:Stop()
    self.log:info("InventorySystemServer Stop...")

    -- 保存所有背包数据
    self:saveAllInventories()

    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function InventorySystemServer:loadConfig()
    self.log:debug("InventorySystemServer config loaded")
end

function InventorySystemServer:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
        if self.dependencies_cache.PlayerSystem then
            self.log:debug("InventorySystemServer resolved dependency: PlayerSystemServer")
        else
            self.log:warning("InventorySystemServer dependency not found: PlayerSystemServer")
        end
    end
end

-- ========================================
-- 物品模板加载
-- ========================================

function InventorySystemServer:loadItemTemplates()
    self.log:info("Loading item templates...")

    -- 示例物品模板
    self.data.itemTemplates = {
        -- 消耗品
        [2001] = {
            itemId = 2001,
            name = "生命药水",
            description = "恢复50点生命值",
            iconPath = "icons/potion_hp.png",
            itemType = "Consumable",
            subType = "Potion",
            stackable = true,
            maxStack = 99,
            quality = "Common",
            buyPrice = 50,
            sellPrice = 25,
            usable = true,
            useEffect = {
                effectType = "RestoreHP",
                value = 50,
                duration = 0,
            },
            obtainMethods = {"Shop", "Drop"},
            unique = false,
            tradable = true,
            dropable = true,
        },

        [2002] = {
            itemId = 2002,
            name = "魔法药水",
            description = "恢复30点魔法值",
            iconPath = "icons/potion_mp.png",
            itemType = "Consumable",
            subType = "Potion",
            stackable = true,
            maxStack = 99,
            quality = "Common",
            buyPrice = 40,
            sellPrice = 20,
            usable = true,
            useEffect = {
                effectType = "RestoreMP",
                value = 30,
                duration = 0,
            },
            obtainMethods = {"Shop", "Drop"},
            unique = false,
            tradable = true,
            dropable = true,
        },

        [2003] = {
            itemId = 2003,
            name = "经验药水",
            description = "获得100点经验值",
            iconPath = "icons/potion_exp.png",
            itemType = "Consumable",
            subType = "Potion",
            stackable = true,
            maxStack = 20,
            quality = "Uncommon",
            buyPrice = 200,
            sellPrice = 100,
            usable = true,
            useEffect = {
                effectType = "GainExp",
                value = 100,
                duration = 0,
            },
            obtainMethods = {"Shop", "Quest"},
            unique = false,
            tradable = true,
            dropable = true,
        },

        -- 装备
        [3001] = {
            itemId = 3001,
            name = "新手剑",
            description = "简单的铁剑",
            iconPath = "icons/sword_basic.png",
            itemType = "Equipment",
            subType = "Weapon",
            stackable = false,
            maxStack = 1,
            quality = "Common",
            buyPrice = 100,
            sellPrice = 50,
            usable = false,
            equipmentData = {
                slot = "Weapon",
                stats = {
                    attack = 15,
                },
                requirements = {
                    level = 1,
                    classType = {"Warrior", "Assassin"},
                },
            },
            obtainMethods = {"Shop", "Drop"},
            unique = false,
            tradable = true,
            dropable = true,
        },

        [3002] = {
            itemId = 3002,
            name = "法师长袍",
            description = "增加魔法攻击力的长袍",
            iconPath = "icons/robe_mage.png",
            itemType = "Equipment",
            subType = "Armor",
            stackable = false,
            maxStack = 1,
            quality = "Uncommon",
            buyPrice = 300,
            sellPrice = 150,
            usable = false,
            equipmentData = {
                slot = "Chest",
                stats = {
                    attack = 8,
                    defense = 5,
                    maxMp = 20,
                },
                requirements = {
                    level = 5,
                    classType = {"Mage"},
                },
            },
            obtainMethods = {"Shop", "Drop"},
            unique = false,
            tradable = true,
            dropable = true,
        },

        -- 材料
        [4001] = {
            itemId = 4001,
            name = "铁矿石",
            description = "用于锻造的基础材料",
            iconPath = "icons/ore_iron.png",
            itemType = "Material",
            subType = "Ore",
            stackable = true,
            maxStack = 99,
            quality = "Common",
            buyPrice = 10,
            sellPrice = 5,
            usable = false,
            obtainMethods = {"Gather", "Drop"},
            unique = false,
            tradable = true,
            dropable = true,
        },

        -- 任务物品
        [5001] = {
            itemId = 5001,
            name = "神秘的信件",
            description = "需要交给城里的商人",
            iconPath = "icons/quest_letter.png",
            itemType = "QuestItem",
            subType = "Letter",
            stackable = false,
            maxStack = 1,
            quality = "Common",
            buyPrice = 0,
            sellPrice = 0,
            usable = false,
            obtainMethods = {"Quest"},
            unique = true,
            tradable = false,
            dropable = false,
        },
    }

    self.log:info(string.format("Loaded %d item templates", self:getTableSize(self.data.itemTemplates)))
end

-- ========================================
-- 事件监听
-- ========================================

function InventorySystemServer:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听玩家加入游戏
    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)

    -- 监听玩家离开游戏
    self.events:on(EventID.PlayerLeft, function(data)
        self:onPlayerLeft(data)
    end)

    self.log:debug("InventorySystemServer event listeners registered")
end

function InventorySystemServer:onPlayerJoined(data)
    local playerId = data.playerId
    self.log:debug("Player joined, initializing inventory: " .. playerId)

    -- 初始化玩家背包
    self:initPlayerInventory(playerId)

    -- 加载玩家背包数据
    self:loadPlayerInventory(playerId)
end

function InventorySystemServer:onPlayerLeft(data)
    local playerId = data.playerId
    self.log:debug("Player left, saving inventory: " .. playerId)

    -- 保存玩家背包数据
    self:savePlayerInventory(playerId)

    -- 清理数据
    self.data.playerInventories[playerId] = nil
end

-- ========================================
-- 网络消息处理
-- ========================================

function InventorySystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:OnRequest(Protocol.ClientMSGID.INVENTORY_GET_REQ, function(userId, msgid, data)
        return self:handleGetInventoryRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.INVENTORY_USE_ITEM_REQ, function(userId, msgid, data)
        return self:handleUseItemRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.INVENTORY_DROP_ITEM_REQ, function(userId, msgid, data)
        return self:handleDropItemRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.INVENTORY_SORT_REQ, function(userId, msgid, data)
        return self:handleSortInventoryRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.INVENTORY_EXPAND_REQ, function(userId, msgid, data)
        return self:handleExpandInventoryRequest(userId, data)
    end)

    self.log:debug("InventorySystemServer network handlers registered")
end

-- ========================================
-- 玩家背包数据管理
-- ========================================

function InventorySystemServer:initPlayerInventory(playerId)
    if self.data.playerInventories[playerId] then
        return
    end

    self.data.playerInventories[playerId] = {
        playerId = playerId,
        capacity = self.config.defaultCapacity,
        slots = {},
        gold = 1000,  -- 初始金币
    }

    self.log:debug("Initialized inventory for player: " .. playerId)
end

function InventorySystemServer:loadPlayerInventory(playerId)
    -- 从数据存储加载背包数据
    -- TODO: 实现数据持久化

    -- 临时：给新玩家一些初始物品
    self:addItem(playerId, 2001, 5, true)   -- 5个生命药水
    self:addItem(playerId, 2002, 3, true)   -- 3个魔法药水
    self:addItem(playerId, 3001, 1, true)   -- 新手剑

    self.log:debug("Loaded inventory for player: " .. playerId)
end

function InventorySystemServer:savePlayerInventory(playerId)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return
    end

    -- 保存到数据存储
    -- TODO: 实现数据持久化

    self.log:debug("Saved inventory for player: " .. playerId)
end

function InventorySystemServer:saveAllInventories()
    for playerId, _ in pairs(self.data.playerInventories) do
        self:savePlayerInventory(playerId)
    end
end

-- ========================================
-- 物品操作
-- ========================================

function InventorySystemServer:addItem(playerId, itemId, quantity, isFree)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return false, "背包数据不存在"
    end

    local template = self.data.itemTemplates[itemId]
    if not template then
        return false, "物品不存在"
    end

    quantity = quantity or 1

    -- 检查是否可堆叠
    if template.stackable then
        -- 尝试堆叠到已有物品
        local remaining = quantity
        for slotIndex, slot in pairs(inventory.slots) do
            if slot.itemId == itemId and slot.quantity < template.maxStack then
                local canAdd = math.min(remaining, template.maxStack - slot.quantity)
                slot.quantity = slot.quantity + canAdd
                remaining = remaining - canAdd

                if remaining == 0 then
                    break
                end
            end
        end

        -- 如果还有剩余，创建新槽位
        while remaining > 0 do
            local emptySlot = self:findEmptySlot(playerId)
            if not emptySlot then
                return false, "背包已满"
            end

            local addCount = math.min(remaining, template.maxStack)
            inventory.slots[emptySlot] = {
                itemId = itemId,
                quantity = addCount,
                slotIndex = emptySlot,
                timestamp = os.time(),
                properties = {},
            }

            remaining = remaining - addCount
        end
    else
        -- 不可堆叠，每个物品占一个槽位
        for i = 1, quantity do
            local emptySlot = self:findEmptySlot(playerId)
            if not emptySlot then
                return false, "背包已满"
            end

            inventory.slots[emptySlot] = {
                itemId = itemId,
                quantity = 1,
                slotIndex = emptySlot,
                timestamp = os.time(),
                properties = {},
            }
        end
    end

    self.log:info(string.format("Player %s received item %d x%d", playerId, itemId, quantity))

    -- 发送事件
    self.events:emit("ItemObtained", {
        playerId = playerId,
        itemId = itemId,
        quantity = quantity,
        timestamp = os.time()
    })

    -- 同步背包数据
    self:syncInventory(playerId)

    return true
end

function InventorySystemServer:removeItem(playerId, itemId, quantity)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return false, "背包数据不存在"
    end

    -- 检查是否有足够数量
    local totalCount = self:getItemCount(playerId, itemId)
    if totalCount < quantity then
        return false, "物品数量不足"
    end

    -- 移除物品
    local remaining = quantity
    for slotIndex, slot in pairs(inventory.slots) do
        if slot.itemId == itemId and remaining > 0 then
            if slot.quantity <= remaining then
                remaining = remaining - slot.quantity
                inventory.slots[slotIndex] = nil
            else
                slot.quantity = slot.quantity - remaining
                remaining = 0
            end
        end
    end

    self.log:info(string.format("Player %s removed item %d x%d", playerId, itemId, quantity))

    -- 发送事件
    self.events:emit("ItemDropped", {
        playerId = playerId,
        itemId = itemId,
        quantity = quantity,
        timestamp = os.time()
    })

    -- 同步背包数据
    self:syncInventory(playerId)

    return true
end

function InventorySystemServer:useItem(playerId, slotIndex)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return false, "背包数据不存在"
    end

    local slot = inventory.slots[slotIndex]
    if not slot then
        return false, "槽位为空"
    end

    local template = self.data.itemTemplates[slot.itemId]
    if not template then
        return false, "物品不存在"
    end

    if not template.usable then
        return false, "该物品不可使用"
    end

    -- 应用物品效果
    local success = self:applyItemEffect(playerId, template)
    if not success then
        return false, "使用物品失败"
    end

    -- 减少物品数量
    slot.quantity = slot.quantity - 1
    if slot.quantity <= 0 then
        inventory.slots[slotIndex] = nil
    end

    self.log:info(string.format("Player %s used item %d", playerId, slot.itemId))

    -- 发送事件
    self.events:emit("ItemUsed", {
        playerId = playerId,
        itemId = slot.itemId,
        slotIndex = slotIndex,
        timestamp = os.time()
    })

    -- 同步背包数据
    self:syncInventory(playerId)

    return true
end

function InventorySystemServer:applyItemEffect(playerId, template)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return false
    end

    local effect = template.useEffect
    if not effect then
        return false
    end

    if effect.effectType == "RestoreHP" then
        playerSystem:healHp(playerId, effect.value)
        return true
    elseif effect.effectType == "RestoreMP" then
        playerSystem:restoreMp(playerId, effect.value)
        return true
    elseif effect.effectType == "GainExp" then
        playerSystem:addExp(playerId, effect.value)
        return true
    elseif effect.effectType == "Buff" then
        -- TODO: 实现Buff系统
        return true
    end

    return false
end

-- ========================================
-- 背包查询
-- ========================================

function InventorySystemServer:findEmptySlot(playerId)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return nil
    end

    for i = 1, inventory.capacity do
        if not inventory.slots[i] then
            return i
        end
    end

    return nil
end

function InventorySystemServer:getItemCount(playerId, itemId)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return 0
    end

    local count = 0
    for _, slot in pairs(inventory.slots) do
        if slot.itemId == itemId then
            count = count + slot.quantity
        end
    end

    return count
end

function InventorySystemServer:hasItem(playerId, itemId, quantity)
    return self:getItemCount(playerId, itemId) >= (quantity or 1)
end

function InventorySystemServer:getUsedSlotCount(playerId)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return 0
    end

    local count = 0
    for _ in pairs(inventory.slots) do
        count = count + 1
    end

    return count
end

-- ========================================
-- 背包整理
-- ========================================

function InventorySystemServer:sortInventory(playerId)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return false, "背包数据不存在"
    end

    -- 收集所有物品
    local items = {}
    for _, slot in pairs(inventory.slots) do
        table.insert(items, {
            itemId = slot.itemId,
            quantity = slot.quantity,
            timestamp = slot.timestamp,
            properties = slot.properties,
        })
    end

    -- 清空背包
    inventory.slots = {}

    -- 按物品ID和品质排序
    table.sort(items, function(a, b)
        local templateA = self.data.itemTemplates[a.itemId]
        local templateB = self.data.itemTemplates[b.itemId]

        if templateA and templateB then
            -- 先按类型排序
            if templateA.itemType ~= templateB.itemType then
                return templateA.itemType < templateB.itemType
            end
            -- 再按ID排序
            return a.itemId < b.itemId
        end

        return a.itemId < b.itemId
    end)

    -- 重新放入背包
    local slotIndex = 1
    for _, item in ipairs(items) do
        local remaining = item.quantity
        local template = self.data.itemTemplates[item.itemId]

        if template and template.stackable then
            -- 可堆叠物品
            while remaining > 0 do
                local addCount = math.min(remaining, template.maxStack)
                inventory.slots[slotIndex] = {
                    itemId = item.itemId,
                    quantity = addCount,
                    slotIndex = slotIndex,
                    timestamp = item.timestamp,
                    properties = item.properties,
                }
                remaining = remaining - addCount
                slotIndex = slotIndex + 1
            end
        else
            -- 不可堆叠物品
            for i = 1, remaining do
                inventory.slots[slotIndex] = {
                    itemId = item.itemId,
                    quantity = 1,
                    slotIndex = slotIndex,
                    timestamp = item.timestamp,
                    properties = item.properties,
                }
                slotIndex = slotIndex + 1
            end
        end
    end

    self.log:info("Sorted inventory for player: " .. playerId)

    -- 发送事件
    self.events:emit("ItemSorted", {
        playerId = playerId,
        timestamp = os.time()
    })

    -- 同步背包数据
    self:syncInventory(playerId)

    return true
end

-- ========================================
-- 背包扩展
-- ========================================

function InventorySystemServer:expandInventory(playerId)
    local inventory = self.data.playerInventories[playerId]
    if not inventory then
        return false, "背包数据不存在"
    end

    if inventory.capacity >= self.config.maxCapacity then
        return false, "背包已达到最大容量"
    end

    local playerSystem = self.dependencies_cache.PlayerSystem
    if playerSystem then
        local playerData = playerSystem:getPlayerData(playerId)
        if playerData and playerData.gold < self.config.expandCost then
            return false, "金币不足"
        end

        -- 扣除金币
        playerSystem:addGold(playerId, -self.config.expandCost)
    end

    -- 扩展背包
    inventory.capacity = inventory.capacity + self.config.expandSlotCount

    self.log:info(string.format("Player %s expanded inventory to %d slots", playerId, inventory.capacity))

    -- 发送事件
    self.events:emit("InventoryExpanded", {
        playerId = playerId,
        newCapacity = inventory.capacity,
        timestamp = os.time()
    })

    -- 同步背包数据
    self:syncInventory(playerId)

    return true
end

-- ========================================
-- 网络请求处理
-- ========================================

function InventorySystemServer:handleGetInventoryRequest(userId, data)
    self.log:debug("Player " .. userId .. " requests inventory")

    self:sendInventory(userId)
end

function InventorySystemServer:handleUseItemRequest(userId, data)
    local slotIndex = data.slotIndex

    self.log:debug(string.format("Player %s requests to use item at slot %d", userId, slotIndex))

    local success, reason = self:useItem(userId, slotIndex)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- 使用 self:CallClient() 发送消息（由 NetworkHelper:RegisterNetObj 注册）
    self:CallClient(userId, Protocol.ServerMSGID.INVENTORY_USE_ITEM_RSP, {
        success = success,
        slotIndex = slotIndex,
        reason = reason,
    })
end

function InventorySystemServer:handleDropItemRequest(userId, data)
    local slotIndex = data.slotIndex
    local quantity = data.quantity or 1

    self.log:debug(string.format("Player %s requests to drop item at slot %d x%d",
        userId, slotIndex, quantity))

    local inventory = self.data.playerInventories[userId]
    if not inventory then
        return
    end

    local slot = inventory.slots[slotIndex]
    if not slot then
        return
    end

    local success, reason = self:removeItem(userId, slot.itemId, quantity)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallClient(userId, Protocol.ServerMSGID.INVENTORY_DROP_ITEM_RSP, {
        success = success,
        slotIndex = slotIndex,
        quantity = quantity,
        reason = reason,
    })
end

function InventorySystemServer:handleSortInventoryRequest(userId, data)
    self.log:debug("Player " .. userId .. " requests to sort inventory")

    local success, reason = self:sortInventory(userId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallClient(userId, Protocol.ServerMSGID.INVENTORY_SORT_RSP, {
        success = success,
        reason = reason,
    })
end

function InventorySystemServer:handleExpandInventoryRequest(userId, data)
    self.log:debug("Player " .. userId .. " requests to expand inventory")

    local success, reason = self:expandInventory(userId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallClient(userId, Protocol.ServerMSGID.INVENTORY_EXPAND_RSP, {
        success = success,
        reason = reason,
    })
end

function InventorySystemServer:sendInventory(userId)
    local inventory = self.data.playerInventories[userId]

    if not inventory then
        return
    end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallClient(userId, Protocol.ServerMSGID.INVENTORY_GET_RSP, {
        success = true,
        capacity = inventory.capacity,
        slots = inventory.slots,
        gold = inventory.gold,
    })
end

function InventorySystemServer:syncInventory(playerId)
    -- 通知客户端更新背包
    self.events:emit("InventoryUpdated", {
        playerId = playerId,
        timestamp = os.time()
    })
end

-- ========================================
-- 公共API
-- ========================================

function InventorySystemServer:getPlayerInventory(playerId)
    return self.data.playerInventories[playerId]
end

function InventorySystemServer:getItemTemplate(itemId)
    return self.data.itemTemplates[itemId]
end

-- ========================================
-- 工具方法
-- ========================================

function InventorySystemServer:getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return InventorySystemServer
