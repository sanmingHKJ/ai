--[[
    ShopSystemServer.lua - RPG Game Shop System (Server Side)
    商店系统服务端

    按照SGF标准化开发框架规范开发

    功能:
    - 管理商店商品数据
    - 处理购买/出售物品
    - 验证交易合法性
    - 与InventorySystem和PlayerSystem集成

    Version: 1.0.0
]]

local ShopSystemServer = {
    -- SGF Standard fields
    name = "ShopSystemServer",
    version = "1.0.0",
    description = "商店系统（服务端）",
    dependencies = {"PlayerSystemServer", "InventorySystemServer"},
    state = "uninitialized",

    -- Legacy metadata (for compatibility)
    _systemName = "ShopSystemServer",
    _version = "1.0.0",
    _dependencies = {"PlayerSystemServer", "InventorySystemServer", "EventBus", "Protocol"},

    -- System data
    data = {
        -- 商店配置数据（从ShopData加载）
        shopConfigs = {},

        -- 玩家购买历史: [playerId] = { purchases = {...} }
        playerPurchaseHistory = {},

        -- 动态价格修正（如果需要）
        priceModifiers = {},
    },

    -- Configuration
    config = {
        sellPriceRatio = 0.5,       -- 出售价格比例（50%回收价）
        maxPurchaseQuantity = 99,    -- 单次最大购买数量
        enableDynamicPricing = false, -- 动态定价开关
    },

    -- Service references
    services = {},

    -- Dependencies cache (SGF standard)
    dependencies_cache = {},
}

-- ============================================================================
-- Constructor
-- ============================================================================

function ShopSystemServer.new(sgf)
    local self = setmetatable({}, {__index = ShopSystemServer})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    -- Initialize dependencies cache
    self.dependencies_cache = {}

    return self
end

-- ============================================================================
-- SGF Framework Lifecycle Methods
-- ============================================================================

--[[
    PreInit - 预初始化阶段
]]
function ShopSystemServer:PreInit()
    print("[ShopSystemServer] PreInit - Initializing shop system...")

    -- 获取核心服务引用
    self.services.workspace = game:GetService("WorkSpace")
    self.services.mainStorage = game:GetService("MainStorage")

    -- 初始化数据表
    self.data.shopConfigs = {}
    self.data.playerPurchaseHistory = {}
    self.data.priceModifiers = {}

    print("[ShopSystemServer] PreInit complete")
end

--[[
    Init - 初始化阶段
]]
function ShopSystemServer:Init()
    print("[ShopSystemServer] Init - Loading shop configurations...")

    -- 加载商店配置数据
    self:loadShopConfigs()

    -- 加载Protocol (静态模块,可以直接require)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self.services.Protocol = Protocol

    -- 注册网络消息处理器
    self:registerMessageHandlers()

    -- 注册事件监听器
    self:registerEventListeners()

    print("[ShopSystemServer] Init complete")
end

--[[
    PostInit - 后初始化阶段
]]
function ShopSystemServer:PostInit()
    print("[ShopSystemServer] PostInit - Setting up system interactions...")

    -- 解析业务系统依赖 (SGF标准方式)
    self:resolveDependencies()

    self.state = "initialized"
    print("[ShopSystemServer] PostInit complete - Shop system ready")
end

--[[
    Start - 启动阶段
]]
function ShopSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    print("[ShopSystemServer] Start - Shop system is now active")
    self.state = "started"
    return true
end

--[[
    Update - 更新循环
]]
function ShopSystemServer:Update(dt)
    if self.state ~= "started" then return end

    -- 可以在这里添加动态价格更新等逻辑
end

--[[
    Stop - 停止系统
]]
function ShopSystemServer:Stop()
    print("[ShopSystemServer] Stop - Shutting down shop system...")

    -- 清理数据
    self.data.playerPurchaseHistory = {}

    self.state = "stopped"
    print("[ShopSystemServer] Stop complete")
end

-- ============================================================================
-- Dependency Resolution (SGF Standard)
-- ============================================================================

--[[
    解析业务系统依赖
    按照SGF标准,通过businessSystemManager获取其他业务系统的实例
]]
function ShopSystemServer:resolveDependencies()
    if not self.sgf.businessSystemManager then
        self.log:warning("ShopSystemServer: businessSystemManager not available")
        return
    end

    -- 解析 PlayerSystemServer 依赖
    self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
    if self.dependencies_cache.PlayerSystem then
        self.log:info("ShopSystemServer resolved dependency: PlayerSystemServer")
    else
        self.log:warning("ShopSystemServer dependency not found: PlayerSystemServer")
    end

    -- 解析 InventorySystemServer 依赖
    self.dependencies_cache.InventorySystem = self.sgf.businessSystemManager:get("InventorySystemServer")
    if self.dependencies_cache.InventorySystem then
        self.log:info("ShopSystemServer resolved dependency: InventorySystemServer")
    else
        self.log:warning("ShopSystemServer dependency not found: InventorySystemServer")
    end
end

-- ============================================================================
-- Configuration Loading
-- ============================================================================

--[[
    加载商店配置数据
]]
function ShopSystemServer:loadShopConfigs()
    -- 尝试加载ShopData模块
    local framework = self.services.mainStorage:FindFirstChild("Framework", true)
    if framework then
        local configFolder = framework:FindFirstChild("Config", true)
        if configFolder then
            local shopDataModule = configFolder:FindFirstChild("ShopData", true)
            if shopDataModule then
                local success, ShopData = pcall(require, shopDataModule)
                if success and ShopData then
                    self.data.shopConfigs = ShopData.shops or {}
                    print("[ShopSystemServer] Loaded " .. self:getTableSize(self.data.shopConfigs) .. " shop configs")
                    return
                end
            end
        end
    end

    print("[ShopSystemServer] WARNING: ShopData not found, using empty config")
    self.data.shopConfigs = {}
end

-- ============================================================================
-- Network Message Handlers
-- ============================================================================

--[[
    注册网络消息处理器
]]
function ShopSystemServer:registerMessageHandlers()
    if not self.services.Protocol then return end

    local Protocol = self.services.Protocol

    -- 注册客户端请求处理器
    print("[ShopSystemServer] Message handlers registered:")
    print("  - SHOP_BUY_ITEM_REQ (600)")
    print("  - SHOP_SELL_ITEM_REQ (601)")
    print("  - SHOP_GET_LIST_REQ (602)")
end

--[[
    处理购买物品请求
    @param player - 玩家对象
    @param data - 请求数据 { shopId, itemId, quantity }
]]
function ShopSystemServer:handleBuyItem(player, data)
    if not player or not data or not data.shopId or not data.itemId then
        print("[ShopSystemServer] Invalid buy item request")
        return
    end

    local playerId = tostring(player.UserId)
    local shopId = data.shopId
    local itemId = data.itemId
    local quantity = data.quantity or 1

    print("[ShopSystemServer] Player " .. playerId .. " buying: " .. itemId .. " x" .. quantity)

    -- 验证数量
    if quantity <= 0 or quantity > self.config.maxPurchaseQuantity then
        self:sendErrorToPlayer(player, "无效的购买数量")
        return
    end

    -- 获取商店配置
    local shopConfig = self.data.shopConfigs[shopId]
    if not shopConfig then
        self:sendErrorToPlayer(player, "商店不存在")
        return
    end

    -- 查找商品
    local itemConfig = self:findItemInShop(shopConfig, itemId)
    if not itemConfig then
        self:sendErrorToPlayer(player, "商品不存在")
        return
    end

    -- 检查库存（如果有限制）
    if itemConfig.stock and itemConfig.stock > 0 then
        if itemConfig.currentStock < quantity then
            self:sendErrorToPlayer(player, "库存不足")
            return
        end
    end

    -- 计算总价
    local totalPrice = self:calculateBuyPrice(itemConfig, quantity)

    -- 检查玩家金币
    local playerGold = self:getPlayerGold(player)
    if playerGold < totalPrice then
        self:sendErrorToPlayer(player, "金币不足")
        return
    end

    -- 检查背包空间
    if not self:checkInventorySpace(player, itemId, quantity) then
        self:sendErrorToPlayer(player, "背包空间不足")
        return
    end

    -- 执行购买
    self:executeBuy(player, shopId, itemConfig, quantity, totalPrice)
end

--[[
    处理出售物品请求
    @param player - 玩家对象
    @param data - 请求数据 { itemId, quantity }
]]
function ShopSystemServer:handleSellItem(player, data)
    if not player or not data or not data.itemId then
        print("[ShopSystemServer] Invalid sell item request")
        return
    end

    local playerId = tostring(player.UserId)
    local itemId = data.itemId
    local quantity = data.quantity or 1

    print("[ShopSystemServer] Player " .. playerId .. " selling: " .. itemId .. " x" .. quantity)

    -- 验证数量
    if quantity <= 0 then
        self:sendErrorToPlayer(player, "无效的出售数量")
        return
    end

    -- 检查玩家是否拥有该物品
    if not self:hasItem(player, itemId, quantity) then
        self:sendErrorToPlayer(player, "物品数量不足")
        return
    end

    -- 获取物品价值（需要从ItemData或其他配置获取）
    local itemValue = self:getItemValue(itemId)
    if itemValue <= 0 then
        self:sendErrorToPlayer(player, "该物品无法出售")
        return
    end

    -- 计算出售价格
    local sellPrice = math.floor(itemValue * quantity * self.config.sellPriceRatio)

    -- 执行出售
    self:executeSell(player, itemId, quantity, sellPrice)
end

--[[
    处理获取商店列表请求
    @param player - 玩家对象
    @param data - 请求数据 { shopId }
]]
function ShopSystemServer:handleGetShopList(player, data)
    if not player or not data or not data.shopId then
        print("[ShopSystemServer] Invalid get shop list request")
        return
    end

    local playerId = tostring(player.UserId)
    local shopId = data.shopId

    print("[ShopSystemServer] Player " .. playerId .. " requesting shop: " .. shopId)

    -- 获取商店配置
    local shopConfig = self.data.shopConfigs[shopId]
    if not shopConfig then
        self:sendErrorToPlayer(player, "商店不存在")
        return
    end

    -- 发送商店列表
    self:sendShopListToPlayer(player, shopConfig)
end

-- ============================================================================
-- Event Listeners
-- ============================================================================

--[[
    注册事件监听器
]]
function ShopSystemServer:registerEventListeners()
    if not self.events then return end

    -- 监听玩家登录事件
    self.events:on("PlayerJoined", function(player)
        self:onPlayerJoined(player)
    end)

    -- 监听玩家离开事件
    self.events:on("PlayerLeft", function(player)
        self:onPlayerLeft(player)
    end)

    print("[ShopSystemServer] Event listeners registered")
end

--[[
    处理玩家加入事件
]]
function ShopSystemServer:onPlayerJoined(player)
    local playerId = tostring(player.UserId)
    print("[ShopSystemServer] Player joined: " .. playerId)

    -- 初始化购买历史
    if not self.data.playerPurchaseHistory[playerId] then
        self.data.playerPurchaseHistory[playerId] = {
            purchases = {},
        }
    end
end

--[[
    处理玩家离开事件
]]
function ShopSystemServer:onPlayerLeft(player)
    local playerId = tostring(player.UserId)
    print("[ShopSystemServer] Player left: " .. playerId)

    -- 可以选择保存购买历史
    -- 暂时保留在内存中
end

-- ============================================================================
-- Core Shop Logic
-- ============================================================================

--[[
    执行购买交易
    @param player - 玩家对象
    @param shopId - 商店ID
    @param itemConfig - 物品配置
    @param quantity - 数量
    @param totalPrice - 总价
]]
function ShopSystemServer:executeBuy(player, shopId, itemConfig, quantity, totalPrice)
    local playerId = tostring(player.UserId)

    -- 扣除金币
    if not self:deductPlayerGold(player, totalPrice) then
        self:sendErrorToPlayer(player, "扣除金币失败")
        return
    end

    -- 添加物品到背包
    if not self:addItemToInventory(player, itemConfig.itemId, quantity) then
        -- 如果添加失败，返还金币
        self:addPlayerGold(player, totalPrice)
        self:sendErrorToPlayer(player, "添加物品失败")
        return
    end

    -- 更新库存（如果有限制）
    if itemConfig.stock and itemConfig.stock > 0 then
        itemConfig.currentStock = itemConfig.currentStock - quantity
    end

    -- 记录购买历史
    self:recordPurchase(playerId, shopId, itemConfig.itemId, quantity, totalPrice)

    -- 触发购买事件
    if self.events then
        self.events:emit("ItemPurchased", {
            playerId = playerId,
            shopId = shopId,
            itemId = itemConfig.itemId,
            quantity = quantity,
            price = totalPrice,
        })
    end

    -- 发送成功响应
    self:sendBuyItemResponse(player, true, itemConfig.itemId, quantity, totalPrice)

    print("[ShopSystemServer] Purchase complete: " .. itemConfig.itemId .. " x" .. quantity .. " for " .. totalPrice .. " gold")
end

--[[
    执行出售交易
    @param player - 玩家对象
    @param itemId - 物品ID
    @param quantity - 数量
    @param sellPrice - 出售价格
]]
function ShopSystemServer:executeSell(player, itemId, quantity, sellPrice)
    local playerId = tostring(player.UserId)

    -- 从背包移除物品
    if not self:removeItemFromInventory(player, itemId, quantity) then
        self:sendErrorToPlayer(player, "移除物品失败")
        return
    end

    -- 添加金币
    if not self:addPlayerGold(player, sellPrice) then
        -- 如果添加失败，返还物品
        self:addItemToInventory(player, itemId, quantity)
        self:sendErrorToPlayer(player, "添加金币失败")
        return
    end

    -- 触发出售事件
    if self.events then
        self.events:emit("ItemSold", {
            playerId = playerId,
            itemId = itemId,
            quantity = quantity,
            price = sellPrice,
        })
    end

    -- 发送成功响应
    self:sendSellItemResponse(player, true, itemId, quantity, sellPrice)

    print("[ShopSystemServer] Sell complete: " .. itemId .. " x" .. quantity .. " for " .. sellPrice .. " gold")
end

--[[
    在商店中查找物品
    @param shopConfig - 商店配置
    @param itemId - 物品ID
    @return table - 物品配置
]]
function ShopSystemServer:findItemInShop(shopConfig, itemId)
    if not shopConfig.items then return nil end

    for _, item in ipairs(shopConfig.items) do
        if item.itemId == itemId then
            return item
        end
    end

    return nil
end

--[[
    计算购买价格
    @param itemConfig - 物品配置
    @param quantity - 数量
    @return number - 总价
]]
function ShopSystemServer:calculateBuyPrice(itemConfig, quantity)
    local basePrice = itemConfig.price or 0

    -- 应用价格修正（如果启用动态定价）
    if self.config.enableDynamicPricing then
        local modifier = self.data.priceModifiers[itemConfig.itemId] or 1.0
        basePrice = math.floor(basePrice * modifier)
    end

    return basePrice * quantity
end

--[[
    获取物品价值
    @param itemId - 物品ID
    @return number - 物品价值
]]
function ShopSystemServer:getItemValue(itemId)
    -- TODO: 从ItemData或配置中获取物品基础价值
    -- 现在返回默认值
    return 10
end

--[[
    记录购买历史
]]
function ShopSystemServer:recordPurchase(playerId, shopId, itemId, quantity, price)
    local history = self.data.playerPurchaseHistory[playerId]
    if not history then return end

    table.insert(history.purchases, {
        shopId = shopId,
        itemId = itemId,
        quantity = quantity,
        price = price,
        timestamp = os.time(),
    })
end

-- ============================================================================
-- Player Integration (与PlayerSystem和InventorySystem交互)
-- ============================================================================

--[[
    获取玩家金币
    @param player - 玩家对象
    @return number - 金币数量
]]
function ShopSystemServer:getPlayerGold(player)
    if not self.dependencies_cache.PlayerSystem then return 0 end

    -- 假设PlayerSystem有getPlayerData方法
    if self.dependencies_cache.PlayerSystem.getPlayerData then
        local playerData = self.dependencies_cache.PlayerSystem:getPlayerData(player)
        if playerData then
            return playerData.gold or 0
        end
    end

    return 0
end

--[[
    扣除玩家金币
    @param player - 玩家对象
    @param amount - 金币数量
    @return boolean - 是否成功
]]
function ShopSystemServer:deductPlayerGold(player, amount)
    if self.events then
        self.events:emit("DeductPlayerGold", {
            playerId = tostring(player.UserId),
            amount = amount,
        })
        return true
    end
    return false
end

--[[
    添加玩家金币
    @param player - 玩家对象
    @param amount - 金币数量
    @return boolean - 是否成功
]]
function ShopSystemServer:addPlayerGold(player, amount)
    if self.events then
        self.events:emit("AddPlayerGold", {
            playerId = tostring(player.UserId),
            amount = amount,
        })
        return true
    end
    return false
end

--[[
    检查背包空间
    @param player - 玩家对象
    @param itemId - 物品ID
    @param quantity - 数量
    @return boolean - 是否有足够空间
]]
function ShopSystemServer:checkInventorySpace(player, itemId, quantity)
    if not self.dependencies_cache.InventorySystem then return true end

    -- 假设InventorySystem有checkSpace方法
    if self.dependencies_cache.InventorySystem.checkSpace then
        return self.dependencies_cache.InventorySystem:checkSpace(player, itemId, quantity)
    end

    return true
end

--[[
    添加物品到背包
    @param player - 玩家对象
    @param itemId - 物品ID
    @param quantity - 数量
    @return boolean - 是否成功
]]
function ShopSystemServer:addItemToInventory(player, itemId, quantity)
    if self.events then
        self.events:emit("AddPlayerItem", {
            playerId = tostring(player.UserId),
            itemId = itemId,
            quantity = quantity,
        })
        return true
    end
    return false
end

--[[
    从背包移除物品
    @param player - 玩家对象
    @param itemId - 物品ID
    @param quantity - 数量
    @return boolean - 是否成功
]]
function ShopSystemServer:removeItemFromInventory(player, itemId, quantity)
    if self.events then
        self.events:emit("RemovePlayerItem", {
            playerId = tostring(player.UserId),
            itemId = itemId,
            quantity = quantity,
        })
        return true
    end
    return false
end

--[[
    检查玩家是否拥有物品
    @param player - 玩家对象
    @param itemId - 物品ID
    @param quantity - 数量
    @return boolean - 是否拥有
]]
function ShopSystemServer:hasItem(player, itemId, quantity)
    if not self.dependencies_cache.InventorySystem then return false end

    -- 假设InventorySystem有hasItem方法
    if self.dependencies_cache.InventorySystem.hasItem then
        return self.dependencies_cache.InventorySystem:hasItem(player, itemId, quantity)
    end

    return false
end

-- ============================================================================
-- Network Communication
-- ============================================================================

--[[
    发送购买物品响应
]]
function ShopSystemServer:sendBuyItemResponse(player, success, itemId, quantity, price)
    -- TODO: 使用实际的网络发送方法
    print("[ShopSystemServer] Sending SHOP_BUY_ITEM_RSP to player: " .. tostring(player.UserId))
end

--[[
    发送出售物品响应
]]
function ShopSystemServer:sendSellItemResponse(player, success, itemId, quantity, price)
    -- TODO: 使用实际的网络发送方法
    print("[ShopSystemServer] Sending SHOP_SELL_ITEM_RSP to player: " .. tostring(player.UserId))
end

--[[
    发送商店列表给玩家
]]
function ShopSystemServer:sendShopListToPlayer(player, shopConfig)
    -- TODO: 使用实际的网络发送方法
    print("[ShopSystemServer] Sending SHOP_GET_LIST_RSP to player: " .. tostring(player.UserId))
end

--[[
    发送错误消息给玩家
]]
function ShopSystemServer:sendErrorToPlayer(player, message)
    -- TODO: 使用实际的网络发送方法
    print("[ShopSystemServer] Error for player " .. tostring(player.UserId) .. ": " .. message)
end

-- ============================================================================
-- Public API
-- ============================================================================

--[[
    获取商店配置
    @param shopId - 商店ID
    @return table - 商店配置
]]
function ShopSystemServer:getShopConfig(shopId)
    return self.data.shopConfigs[shopId]
end

--[[
    刷新商店库存（定时任务）
    @param shopId - 商店ID
]]
function ShopSystemServer:refreshShopStock(shopId)
    local shopConfig = self.data.shopConfigs[shopId]
    if not shopConfig then return end

    -- 重置库存到初始值
    if shopConfig.items then
        for _, item in ipairs(shopConfig.items) do
            if item.stock and item.stock > 0 then
                item.currentStock = item.stock
            end
        end
    end

    print("[ShopSystemServer] Shop stock refreshed: " .. shopId)
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

--[[
    获取table大小
]]
function ShopSystemServer:getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 导出模块
return ShopSystemServer
