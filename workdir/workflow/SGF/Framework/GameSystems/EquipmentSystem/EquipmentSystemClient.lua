--[[
    EquipmentSystemClient.lua - 装备系统（客户端）

    职责：
    1. 缓存装备数据（从服务端同步）
    2. 发送装备穿戴/卸下请求
    3. 发送装备强化请求
    4. 更新UI显示
    5. 显示装备信息和套装效果

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local EquipmentSystemClient = {
    -- ========== 基础信息 ==========
    name = "EquipmentSystemClient",
    version = "1.0.0",
    description = "装备系统（客户端）",

    -- ========== 依赖声明 ==========
    dependencies = {
        "PlayerSystemClient",
        "InventorySystemClient",
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
            "Weapon",
            "Head",
            "Chest",
            "Legs",
            "Feet",
            "Accessory1",
            "Accessory2",
        },
    },

    -- ========== 数据 ==========
    data = {
        slots = {},
        totalStats = {},
        activeSets = {},
    },

    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

function EquipmentSystemClient.new(sgf)
    local self = setmetatable({}, {__index = EquipmentSystemClient})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.data = {
        slots = {},
        totalStats = {},
        activeSets = {},
    }
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function EquipmentSystemClient:PreInit()
    self.log:info("EquipmentSystemClient PreInit...")

    -- 注册事件监听器
    self:registerEventListeners()

    return true
end

function EquipmentSystemClient:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("EquipmentSystemClient already initialized")
        return false
    end

    self.log:info("EquipmentSystemClient Init...")

    -- 加载配置
    self:loadConfig()

    -- 注册网络消息处理
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function EquipmentSystemClient:PostInit()
    self.log:info("EquipmentSystemClient PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    return true
end

function EquipmentSystemClient:Start()
    if self.state ~= "initialized" then
        self.log:error("EquipmentSystemClient cannot start, state: " .. self.state)
        return false
    end

    self.log:info("EquipmentSystemClient Start...")

    -- 请求服务端同步装备数据
    self:requestEquipment()

    self.state = "started"
    self.events:emit("EquipmentSystemStarted", {timestamp = os.time()})

    return true
end

function EquipmentSystemClient:Update(dt)
    -- 装备系统通常不需要每帧更新
end

function EquipmentSystemClient:Stop()
    self.log:info("EquipmentSystemClient Stop...")

    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function EquipmentSystemClient:loadConfig()
    self.log:debug("EquipmentSystemClient config loaded")
end

function EquipmentSystemClient:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemClient")
        self.dependencies_cache.InventorySystem = self.sgf.businessSystemManager:get("InventorySystemClient")

        if self.dependencies_cache.PlayerSystem then
            self.log:debug("EquipmentSystemClient resolved dependency: PlayerSystemClient")
        end

        if self.dependencies_cache.InventorySystem then
            self.log:debug("EquipmentSystemClient resolved dependency: InventorySystemClient")
        end
    end
end

-- ========================================
-- 事件监听
-- ========================================

function EquipmentSystemClient:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听装备穿戴
    self.events:on(EventID.EquipmentEquipped, function(data)
        self:onEquipmentEquipped(data)
    end)

    -- 监听装备卸下
    self.events:on(EventID.EquipmentUnequipped, function(data)
        self:onEquipmentUnequipped(data)
    end)

    -- 监听装备更新
    self.events:on(EventID.EquipmentUpdated, function(data)
        self:onEquipmentUpdated(data)
    end)

    -- 监听装备强化
    self.events:on(EventID.EquipmentUpgraded, function(data)
        self:onEquipmentUpgraded(data)
    end)

    self.log:debug("EquipmentSystemClient event listeners registered")
end

function EquipmentSystemClient:onEquipmentEquipped(data)
    self.log:info("Equipment equipped: " .. data.itemId .. " to slot " .. data.slotType)

    -- 显示提示
    local inventorySystem = self.dependencies_cache.InventorySystem
    if inventorySystem then
        local template = inventorySystem:getItemTemplate(data.itemId)
        if template then
            self.events:emit("ShowMessage", {
                message = string.format("装备了 %s", template.name),
                type = "success"
            })
        end
    end
end

function EquipmentSystemClient:onEquipmentUnequipped(data)
    self.log:info("Equipment unequipped: " .. data.itemId .. " from slot " .. data.slotType)
end

function EquipmentSystemClient:onEquipmentUpdated(data)
    self.log:debug("Equipment updated notification")

    -- 请求更新装备数据
    self:requestEquipment()
end

function EquipmentSystemClient:onEquipmentUpgraded(data)
    self.log:info("Equipment upgraded in slot " .. data.slotType .. " to level " .. data.newLevel)

    self.events:emit("ShowMessage", {
        message = string.format("装备强化成功！强化等级 +%d", data.newLevel),
        type = "success"
    })
end

-- ========================================
-- 网络消息处理
-- ========================================

function EquipmentSystemClient:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:OnResponse(Protocol.ServerMSGID.EQUIPMENT_EQUIP_RSP, function(msgid, data)
        self:onEquipResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.EQUIPMENT_UNEQUIP_RSP, function(msgid, data)
        self:onUnequipResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.EQUIPMENT_GET_RSP, function(msgid, data)
        self:onGetEquipmentResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.EQUIPMENT_UPGRADE_RSP, function(msgid, data)
        self:onUpgradeResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.EQUIPMENT_UPDATE_NOTIFY, function(msgid, data)
        self:onEquipmentUpdateNotify(data)
    end)

    self.log:debug("EquipmentSystemClient network handlers registered")
end

-- ========================================
-- 客户端请求发送
-- ========================================

function EquipmentSystemClient:requestEquipment()
    self.log:debug("Requesting equipment from server")

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.EQUIPMENT_GET_REQ, {})
end

function EquipmentSystemClient:requestEquip(itemId, inventorySlotIndex)
    self.log:debug("Requesting to equip item: " .. itemId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.EQUIPMENT_EQUIP_REQ, {
        itemId = itemId,
        inventorySlotIndex = inventorySlotIndex,
    })
end

function EquipmentSystemClient:requestUnequip(slotType)
    self.log:debug("Requesting to unequip from slot: " .. slotType)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.EQUIPMENT_UNEQUIP_REQ, {
        slotType = slotType,
    })
end

function EquipmentSystemClient:requestUpgrade(slotType)
    self.log:debug("Requesting to upgrade equipment in slot: " .. slotType)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.EQUIPMENT_UPGRADE_REQ, {
        slotType = slotType,
    })
end

-- ========================================
-- 服务端响应处理
-- ========================================

function EquipmentSystemClient:onEquipResponse(data)
    if data.success then
        self.log:info("Successfully equipped item: " .. data.itemId)

        -- 请求更新装备和背包
        self:requestEquipment()

        local inventorySystem = self.dependencies_cache.InventorySystem
        if inventorySystem then
            inventorySystem:requestInventory()
        end
    else
        self.log:warning("Failed to equip item: " .. (data.reason or "Unknown"))

        self.events:emit("ShowMessage", {
            message = data.reason or "装备失败",
            type = "error"
        })
    end
end

function EquipmentSystemClient:onUnequipResponse(data)
    if data.success then
        self.log:info("Successfully unequipped from slot: " .. data.slotType)

        -- 请求更新装备和背包
        self:requestEquipment()

        local inventorySystem = self.dependencies_cache.InventorySystem
        if inventorySystem then
            inventorySystem:requestInventory()
        end
    else
        self.log:warning("Failed to unequip: " .. (data.reason or "Unknown"))

        self.events:emit("ShowMessage", {
            message = data.reason or "卸下装备失败",
            type = "error"
        })
    end
end

function EquipmentSystemClient:onGetEquipmentResponse(data)
    if data.success then
        self.log:info("Received equipment from server")

        -- 更新本地数据
        self.data.slots = data.slots or {}
        self.data.totalStats = data.totalStats or {}
        self.data.activeSets = data.activeSets or {}

        -- 通知UI更新
        self.events:emit("EquipmentUpdated", {
            slots = self.data.slots,
            totalStats = self.data.totalStats,
            activeSets = self.data.activeSets,
            timestamp = os.time()
        })
    end
end

function EquipmentSystemClient:onUpgradeResponse(data)
    if data.success then
        self.log:info("Successfully upgraded equipment in slot: " .. data.slotType)

        -- 请求更新装备
        self:requestEquipment()
    else
        self.log:warning("Failed to upgrade equipment: " .. (data.reason or "Unknown"))

        self.events:emit("ShowMessage", {
            message = data.reason or "强化失败",
            type = "error"
        })
    end
end

function EquipmentSystemClient:onEquipmentUpdateNotify(data)
    self.log:debug("Equipment update notification received")

    -- 请求更新装备
    self:requestEquipment()
end

-- ========================================
-- 公共API
-- ========================================

function EquipmentSystemClient:getSlots()
    return self.data.slots
end

function EquipmentSystemClient:getSlot(slotType)
    return self.data.slots[slotType]
end

function EquipmentSystemClient:getTotalStats()
    return self.data.totalStats
end

function EquipmentSystemClient:getActiveSets()
    return self.data.activeSets
end

function EquipmentSystemClient:isSlotEmpty(slotType)
    return self.data.slots[slotType] == nil
end

function EquipmentSystemClient:getEquippedItemId(slotType)
    local slot = self.data.slots[slotType]
    return slot and slot.itemId or nil
end

function EquipmentSystemClient:getEquipmentSlots()
    return self.config.equipmentSlots
end

-- 获取装备槽位显示名称
function EquipmentSystemClient:getSlotDisplayName(slotType)
    local names = {
        Weapon = "武器",
        Head = "头盔",
        Chest = "胸甲",
        Legs = "腿甲",
        Feet = "鞋子",
        Accessory1 = "饰品1",
        Accessory2 = "饰品2",
    }

    return names[slotType] or slotType
end

-- 获取装备总属性的格式化文本
function EquipmentSystemClient:getStatsText()
    local text = ""
    local stats = self.data.totalStats

    if stats.attack and stats.attack > 0 then
        text = text .. string.format("攻击力 +%d\n", stats.attack)
    end

    if stats.defense and stats.defense > 0 then
        text = text .. string.format("防御力 +%d\n", stats.defense)
    end

    if stats.maxHp and stats.maxHp > 0 then
        text = text .. string.format("生命值 +%d\n", stats.maxHp)
    end

    if stats.maxMp and stats.maxMp > 0 then
        text = text .. string.format("魔法值 +%d\n", stats.maxMp)
    end

    return text ~= "" and text or "无装备加成"
end

return EquipmentSystemClient
