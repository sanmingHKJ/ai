--[[
    InventorySystemClient.lua - 背包系统（客户端）

    职责：
    1. 缓存背包数据（从服务端同步）
    2. 发送物品使用/丢弃请求
    3. 发送背包整理/扩展请求
    4. 更新UI显示

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local InventorySystemClient = {
    -- ========== 基础信息 ==========
    name = "InventorySystemClient",
    version = "1.0.0",
    description = "背包系统（客户端）",

    -- ========== 依赖声明 ==========
    dependencies = {
        "PlayerSystemClient",
    },

    -- ========== 状态管理 ==========
    state = "uninitialized",

    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,

    -- ========== 配置 ==========
    config = {},

    -- ========== 数据 ==========
    data = {
        capacity = 20,
        slots = {},
        gold = 0,
        itemTemplates = {},  -- 物品模板（客户端需要显示物品信息）
    },

    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

function InventorySystemClient.new(sgf)
    local self = setmetatable({}, {__index = InventorySystemClient})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.data = {
        capacity = 20,
        slots = {},
        gold = 0,
        itemTemplates = {},
    }
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function InventorySystemClient:PreInit()
    self.log:info("InventorySystemClient PreInit...")

    -- 注册事件监听器
    self:registerEventListeners()

    return true
end

function InventorySystemClient:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("InventorySystemClient already initialized")
        return false
    end

    self.log:info("InventorySystemClient Init...")

    -- 加载配置
    self:loadConfig()

    -- 加载物品模板（客户端需要显示物品图标、描述等）
    self:loadItemTemplates()

    -- 注册网络消息处理
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function InventorySystemClient:PostInit()
    self.log:info("InventorySystemClient PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    return true
end

function InventorySystemClient:Start()
    if self.state ~= "initialized" then
        self.log:error("InventorySystemClient cannot start, state: " .. self.state)
        return false
    end

    self.log:info("InventorySystemClient Start...")

    -- 请求服务端同步背包数据
    self:requestInventory()

    self.state = "started"
    self.events:emit("InventorySystemStarted", {timestamp = os.time()})

    return true
end

function InventorySystemClient:Update(dt)
    -- 背包系统通常不需要每帧更新
end

function InventorySystemClient:Stop()
    self.log:info("InventorySystemClient Stop...")

    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function InventorySystemClient:loadConfig()
    self.log:debug("InventorySystemClient config loaded")
end

function InventorySystemClient:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemClient")
        if self.dependencies_cache.PlayerSystem then
            self.log:debug("InventorySystemClient resolved dependency: PlayerSystemClient")
        else
            self.log:warning("InventorySystemClient dependency not found: PlayerSystemClient")
        end
    end
end

function InventorySystemClient:loadItemTemplates()
    -- 加载物品模板（客户端需要显示物品信息）
    -- 应该和服务端保持一致，或从服务端同步
    self.data.itemTemplates = {
        -- 消耗品
        [2001] = {
            itemId = 2001,
            name = "生命药水",
            description = "恢复50点生命值",
            iconPath = "icons/potion_hp.png",
            itemType = "Consumable",
            quality = "Common",
        },
        [2002] = {
            itemId = 2002,
            name = "魔法药水",
            description = "恢复30点魔法值",
            iconPath = "icons/potion_mp.png",
            itemType = "Consumable",
            quality = "Common",
        },
        [2003] = {
            itemId = 2003,
            name = "经验药水",
            description = "获得100点经验值",
            iconPath = "icons/potion_exp.png",
            itemType = "Consumable",
            quality = "Uncommon",
        },

        -- 装备
        [3001] = {
            itemId = 3001,
            name = "新手剑",
            description = "简单的铁剑\n攻击力 +15",
            iconPath = "icons/sword_basic.png",
            itemType = "Equipment",
            quality = "Common",
        },
        [3002] = {
            itemId = 3002,
            name = "法师长袍",
            description = "增加魔法攻击力的长袍\n攻击力 +8\n防御力 +5\n魔法值 +20",
            iconPath = "icons/robe_mage.png",
            itemType = "Equipment",
            quality = "Uncommon",
        },

        -- 材料
        [4001] = {
            itemId = 4001,
            name = "铁矿石",
            description = "用于锻造的基础材料",
            iconPath = "icons/ore_iron.png",
            itemType = "Material",
            quality = "Common",
        },

        -- 任务物品
        [5001] = {
            itemId = 5001,
            name = "神秘的信件",
            description = "需要交给城里的商人",
            iconPath = "icons/quest_letter.png",
            itemType = "QuestItem",
            quality = "Common",
        },
    }
end

-- ========================================
-- 事件监听
-- ========================================

function InventorySystemClient:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听物品获得
    self.events:on(EventID.ItemObtained, function(data)
        self:onItemObtained(data)
    end)

    -- 监听物品使用
    self.events:on(EventID.ItemUsed, function(data)
        self:onItemUsed(data)
    end)

    -- 监听物品丢弃
    self.events:on(EventID.ItemDropped, function(data)
        self:onItemDropped(data)
    end)

    -- 监听背包整理
    self.events:on(EventID.ItemSorted, function(data)
        self:onItemSorted(data)
    end)

    -- 监听背包扩展
    self.events:on(EventID.InventoryExpanded, function(data)
        self:onInventoryExpanded(data)
    end)

    self.log:debug("InventorySystemClient event listeners registered")
end

function InventorySystemClient:onItemObtained(data)
    self.log:info("Item obtained: " .. data.itemId .. " x" .. data.quantity)

    -- 显示获得物品提示
    local template = self.data.itemTemplates[data.itemId]
    if template then
        self.events:emit("ShowFloatingText", {
            message = string.format("获得 %s x%d", template.name, data.quantity),
            type = "item",
            iconPath = template.iconPath,
        })
    end
end

function InventorySystemClient:onItemUsed(data)
    self.log:info("Item used: " .. data.itemId)
end

function InventorySystemClient:onItemDropped(data)
    self.log:info("Item dropped: " .. data.itemId .. " x" .. data.quantity)
end

function InventorySystemClient:onItemSorted(data)
    self.log:info("Inventory sorted")
end

function InventorySystemClient:onInventoryExpanded(data)
    self.log:info("Inventory expanded to: " .. data.newCapacity)

    self.events:emit("ShowMessage", {
        message = "背包扩展成功！",
        type = "success"
    })
end

-- ========================================
-- 网络消息处理
-- ========================================

function InventorySystemClient:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_GET_RSP, function(msgid, data)
        self:onGetInventoryResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_USE_ITEM_RSP, function(msgid, data)
        self:onUseItemResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_DROP_ITEM_RSP, function(msgid, data)
        self:onDropItemResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_SORT_RSP, function(msgid, data)
        self:onSortInventoryResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_EXPAND_RSP, function(msgid, data)
        self:onExpandInventoryResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_UPDATE_NOTIFY, function(msgid, data)
        self:onInventoryUpdateNotify(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_ITEM_ADD_NOTIFY, function(msgid, data)
        self:onItemAddNotify(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.INVENTORY_ITEM_REMOVE_NOTIFY, function(msgid, data)
        self:onItemRemoveNotify(data)
    end)

    self.log:debug("InventorySystemClient network handlers registered")
end

-- ========================================
-- 客户端请求发送
-- ========================================

function InventorySystemClient:requestInventory()
    self.log:debug("Requesting inventory from server")

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.INVENTORY_GET_REQ, {})
end

function InventorySystemClient:requestUseItem(slotIndex)
    self.log:debug("Requesting to use item at slot: " .. slotIndex)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.INVENTORY_USE_ITEM_REQ, {
        slotIndex = slotIndex,
    })
end

function InventorySystemClient:requestDropItem(slotIndex, quantity)
    self.log:debug(string.format("Requesting to drop item at slot %d x%d", slotIndex, quantity or 1))

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.INVENTORY_DROP_ITEM_REQ, {
        slotIndex = slotIndex,
        quantity = quantity or 1,
    })
end

function InventorySystemClient:requestSortInventory()
    self.log:debug("Requesting to sort inventory")

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.INVENTORY_SORT_REQ, {})
end

function InventorySystemClient:requestExpandInventory()
    self.log:debug("Requesting to expand inventory")

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.INVENTORY_EXPAND_REQ, {})
end

-- ========================================
-- 服务端响应处理
-- ========================================

function InventorySystemClient:onGetInventoryResponse(data)
    if data.success then
        self.log:info("Received inventory from server")

        -- 更新本地数据
        self.data.capacity = data.capacity
        self.data.slots = data.slots or {}
        self.data.gold = data.gold or 0

        -- 通知UI更新
        self.events:emit("InventoryUpdated", {
            capacity = self.data.capacity,
            slots = self.data.slots,
            gold = self.data.gold,
            timestamp = os.time()
        })
    end
end

function InventorySystemClient:onUseItemResponse(data)
    if data.success then
        self.log:info("Successfully used item at slot: " .. data.slotIndex)

        -- 请求更新背包
        self:requestInventory()
    else
        self.log:warning("Failed to use item: " .. (data.reason or "Unknown"))

        self.events:emit("ShowMessage", {
            message = data.reason or "使用物品失败",
            type = "error"
        })
    end
end

function InventorySystemClient:onDropItemResponse(data)
    if data.success then
        self.log:info(string.format("Successfully dropped item at slot %d x%d",
            data.slotIndex, data.quantity))

        -- 请求更新背包
        self:requestInventory()
    else
        self.log:warning("Failed to drop item: " .. (data.reason or "Unknown"))

        self.events:emit("ShowMessage", {
            message = data.reason or "丢弃物品失败",
            type = "error"
        })
    end
end

function InventorySystemClient:onSortInventoryResponse(data)
    if data.success then
        self.log:info("Successfully sorted inventory")

        -- 请求更新背包
        self:requestInventory()

        self.events:emit("ShowMessage", {
            message = "背包整理完成",
            type = "success"
        })
    else
        self.log:warning("Failed to sort inventory: " .. (data.reason or "Unknown"))
    end
end

function InventorySystemClient:onExpandInventoryResponse(data)
    if data.success then
        self.log:info("Successfully expanded inventory")

        -- 请求更新背包
        self:requestInventory()
    else
        self.log:warning("Failed to expand inventory: " .. (data.reason or "Unknown"))

        self.events:emit("ShowMessage", {
            message = data.reason or "扩展背包失败",
            type = "error"
        })
    end
end

function InventorySystemClient:onInventoryUpdateNotify(data)
    self.log:debug("Inventory update notification received")

    -- 请求更新背包
    self:requestInventory()
end

function InventorySystemClient:onItemAddNotify(data)
    self.log:debug("Item add notification: " .. data.itemId)

    -- 请求更新背包
    self:requestInventory()
end

function InventorySystemClient:onItemRemoveNotify(data)
    self.log:debug("Item remove notification: " .. data.itemId)

    -- 请求更新背包
    self:requestInventory()
end

-- ========================================
-- 公共API
-- ========================================

function InventorySystemClient:getCapacity()
    return self.data.capacity
end

function InventorySystemClient:getSlots()
    return self.data.slots
end

function InventorySystemClient:getSlot(slotIndex)
    return self.data.slots[slotIndex]
end

function InventorySystemClient:getGold()
    return self.data.gold
end

function InventorySystemClient:getItemTemplate(itemId)
    return self.data.itemTemplates[itemId]
end

function InventorySystemClient:getUsedSlotCount()
    local count = 0
    for _ in pairs(self.data.slots) do
        count = count + 1
    end
    return count
end

function InventorySystemClient:getEmptySlotCount()
    return self.data.capacity - self:getUsedSlotCount()
end

function InventorySystemClient:getItemCount(itemId)
    local count = 0
    for _, slot in pairs(self.data.slots) do
        if slot.itemId == itemId then
            count = count + slot.quantity
        end
    end
    return count
end

function InventorySystemClient:hasItem(itemId, quantity)
    return self:getItemCount(itemId) >= (quantity or 1)
end

function InventorySystemClient:findItemSlots(itemId)
    local slots = {}
    for slotIndex, slot in pairs(self.data.slots) do
        if slot.itemId == itemId then
            table.insert(slots, slotIndex)
        end
    end
    return slots
end

-- 获取物品品质颜色
function InventorySystemClient:getQualityColor(quality)
    local colors = {
        Common = {r = 255, g = 255, b = 255},      -- 白色
        Uncommon = {r = 30, g = 255, b = 0},       -- 绿色
        Rare = {r = 0, g = 112, b = 221},          -- 蓝色
        Epic = {r = 163, g = 53, b = 238},         -- 紫色
        Legendary = {r = 255, g = 128, b = 0},     -- 橙色
    }

    return colors[quality] or colors.Common
end

return InventorySystemClient
