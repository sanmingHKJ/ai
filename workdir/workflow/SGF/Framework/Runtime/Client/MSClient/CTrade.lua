local Protocol = MS.Protocol
local Utils = GFScript("CoreModule.Utils")
local Network = GFScript("NetworkModule.Network")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local TimerManager = GFScript("CoreModule.TimerManager")
local UIManager = GFScript("UIModule.UIManager")
local ActorManager = GFScript("ActorModule.ActorManager")
local ItemDefines = GFScript("InventoryModule.ItemDefines")
local InventoryManager = GFScript("InventoryModule.InventoryManager")
local CTrade = {}

local RecordType = {
    Buy = "Buy",
    Sell = "Sell"
}

local UIEvent = {
    MarksChange = "MarksChange",
    SellSuccess = "SellSuccess",
    BuySuccess = "BuySuccess",
    BuyFromOther = "BuyFromOther",
    ObtainItems = "ObtainItems",
    TradeFail = "TradeFail",
    OrderChanged = "OrderChanged",
    CancelSuccess = "CancelSuccess",
    RecordGet = "RecordGet",
    TradeGet = "TradeGet",
    TradeGetItems = "TradeGetItems",
    TradeGetNum = "TradeGetNum",
    TradeGetPrice = "TradeGetPrice",
    TradeGetPrices = "TradeGetPrices",
    RecordChanged = "RecordChanged",
}
CTrade.UIEvent = UIEvent
CTrade.RecordType = RecordType

function CTrade:Init()
    self.markItemMap = {}
    self.levelbgPaths = {}
    self.sellFilters = {}
    self.factorFilters = {}

    -- 初始化过滤列表
    self:InitFilters()

    self.newRecordNum = 0
    self.centerServerTime = nil
    self.recordData = { isEnd=false, frontID=0, lastID=0, cacheNum=0, Buy={}, Sell={}, queryType=nil }
    self.storeData = { seq=0, isEnd=false, lastIndex=0, sortType=3, factors={}, conditions={}, orders={} }

    MS.NetworkHelper:RegisterNetObj(self)
    MS.ObserverHelper:RegisterObserver(self)

    local syncTradeTimer = nil
    self:OnResponse(Protocol.ServerMSGID.TRADE_SERVERTIME_RSP, function(userId, msg)
        self.centerServerTime = msg.centerServerTime
        if syncTradeTimer == nil then
            -- 请求收藏道具数据
            self:MarkProduct()
            syncTradeTimer = TimerManager:AddTimer(function(dt)
                self.centerServerTime = self.centerServerTime + dt
            end, 1)
        end
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_MARKS_RSP, function(userId, msg)
        self.markItemMap = {}
        for i, itemID in pairs(msg.markArr or {}) do
            self.markItemMap[itemID] = true
        end
        self:BroadcastObservers(UIEvent.MarksChange)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_SELL_RSP, function(userId, msg)
        self:OnResponseTradeSell(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_BUY_RSP, function(userId, msg)
        self:OnResponseTradeBuy(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_OTHER_BUY_RSP, function(userId, msg)
        self:OnResponseTradeOtherBuy(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_CANCEL_RSP, function(userId, msg)
        self:OnResponseTradeCancel(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_RECORDS_RSP, function(userId, msg)
        self:OnResponseTradeRecords(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_GET_RSP, function(userId, msg)
        self:OnResponseTradeGet(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_GET_ITEM_RSP, function(userId, msg)
        self:OnResponseTradeGetItem(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_GET_ITEMS_RSP, function(userId, msg)
        self:OnResponseTradeGetItems(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.WAREHOUSE_OBTAIN_TRADE_RSP, function(userId, msg)
        self:OnResponseWareHouseObtain(msg)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_GET_NUM_RSP, function(userId, msg)
        self:BroadcastObservers(UIEvent.TradeGetNum, msg.orderNum)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_ERROR_RSP, function(userId, msg)
        -- errCode#1价格错误 2货币不足 3暂未开放交易
        self:BroadcastObservers(UIEvent.TradeFail, msg.errCode)
    end)

    self:OnResponse(Protocol.ServerMSGID.TRADE_TIP_RSP, function(userId, msg)
        UIManager:ShowTip(msg.tip)
    end)
end

-----------------------初始化数据--------------------------------
-- 交易行配置
function CTrade:GetConfig()
    if self.tradeConfig == nil then
        self.tradeConfig = MS.Config.GetConfigs("TradeConfig")
    end
    return self.tradeConfig
end

-- 最大订单数
function CTrade:GetMaxOrderCount()
    local tConfig = self:GetConfig()
    return tConfig and tConfig.MaxCount or 10
end

-- 获取费率
function CTrade:GetFeeRate()
    local tConfig = self:GetConfig()
    return tConfig and tConfig.FeeRate
end

-- 获取保证金率
function CTrade:GetDepositRate()
    local tConfig = self:GetConfig()
    return tConfig and tConfig.DepositRate
end

-- 获取手续费
function CTrade:GetFee(total)
    local feeRate = self:GetFeeRate()
    if feeRate > 0 and feeRate < 100 then
        return total - math.floor((100 - feeRate) * total / 100)
    end
    return 0
end

-- 获取税后收益
function CTrade:GetIncome(total)
    return total - self:GetFee(total)
end

-- 获取保证金
function CTrade:GetDeposit(total)
    local depositRate = self:GetDepositRate()
    if depositRate > 0 and depositRate < 100 then
        return math.floor(total * depositRate / 100)
    end 
    return 0
end

-- 玩家ID
function CTrade:GetPlayerID()
    if self.selfPlayerID == nil then
        local localPlayer = ActorManager:GetLocalPlayer()
        if localPlayer ~= nil then
            self.selfPlayerID = localPlayer:GetPlayerId()
        end
    end
    return self.selfPlayerID
end

-- 初始化可售卖过滤器
function CTrade:InitFilters()
    local tConfig = self:GetConfig()
    for i, category in ipairs(tConfig.Categorys) do
        category.index = i

        local subCategorys = tConfig.SubCategorys[category.key] or {}
        -- 添加过滤器
        for i, subCategory in ipairs(subCategorys) do
            subCategory.addRule = function(filters)
                filters.type = subCategory.type
                filters.subType = subCategory.subType
            end
            local subTypeValue = subCategory.subType or subCategory.type -- 兼容没有子类型
            local subTypes = self.sellFilters[subCategory.type]
            if subTypes == nil then
                subTypes = { [subTypeValue] = true }
                self.sellFilters[subCategory.type] = subTypes
            else
                subTypes[subTypeValue] = true
            end
        end
        self.factorFilters[category.key] = subCategorys
    end
end

-- 订单是否有效
function CTrade:IsProductAvailable(isOwner, product)
    if isOwner ~= self:IsMyOrder(product.sellerID) then
        return false
    end
    local filters = product.filters
    if not self:IsSellType(filters.type, filters.subType) then
        -- 商品类型暂不支持
        return false
    end
    -- todo 版本不兼容
    return true
end

-- 是否售卖品
function CTrade:CanSellItem(item)
    local itemData = item:GetItemData()
    if itemData == nil then
        return false
    end
    if item:IsBind() then
        return false
    end
    return self:IsSellType(itemData.type, itemData.subType)
end

-- 是否售卖类型
function CTrade:IsSellType(itemType, subType)
    local subTypes = self.sellFilters[itemType]
    if subTypes ~= nil then
        local filterKey = subType or itemType -- 兼容没有子类型
        return subTypes[filterKey] == true
    end 
    return false
end

-- 获取子类型数组
function CTrade:GetSubCategorys(category)
    local filters = self.factorFilters[category]
    if filters == nil or #filters <= 0 then
        return {}
    end
    return { filters }
end

-- 交易行类别
function CTrade:GetCategorys()
    local tConfig = self:GetConfig()
    return tConfig.Categorys
end
-----------------------逻辑处理--------------------------------
function CTrade:GetMoney()
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer ~= nil then
        local tConfig = self:GetConfig()
        return localPlayer.InventoryComponent:CountItemByTid(tConfig.CurrencyID)
    end
    return 0
end

-- 是否收藏
function CTrade:IsMarkOrder(item)
    return self.markItemMap[item.id] or false
end

function CTrade:IsMarkItem(tid)
    return self.markItemMap[tid] or false
end

-- 是否有收藏过
function CTrade:HasMarkItem()
    for id, status in pairs(self.markItemMap) do
        return true
    end
    return false
end

-- 是否自己订单
function CTrade:IsMyOrder(sellerID)
    return self:GetPlayerID() == sellerID
end

-- 订单剩余时间
function CTrade:GetOrderRemainTime(product)
    if self.centerServerTime == nil then
        return 0
    end
    local tConfig = self:GetConfig()
    local timeout = tConfig.OutTime + product.sellTimestamp
    return timeout - self.centerServerTime
end

-- 是否满足筛选
function CTrade:IsProductMatchFilters(product, factors)
    -- factors 过滤因子Map
    local filters = product.filters or {} --商品标签
    for name, value in pairs(factors) do
        if filters[name] ~= value then
            return false
        end
    end
    return true
end

-- 创建商品
function CTrade:CreateProduct(item, count, price)
    local itemData = item:GetItemData()
    if itemData == nil then
        return nil
    end
    local tConfig = self:GetConfig()
    local itemType = itemData.type
    local productData = Utils:DeepCopy(tConfig.OrderTemplate)
    productData.type = itemType
    productData.id = item.tid
    productData.price = price
    productData.count = count
    productData.extendData = {}
    item:Serialize(productData.extendData)
    productData.filters = { type=itemType, subType=itemData.subType }

    return productData
end

-- 仓库获得的交易物品
function CTrade:OnResponseWareHouseObtain(obtainItems)
    self.newRecordNum = self.newRecordNum + (#obtainItems)
    -- obtainItems#{{orderID=x, itemId=x, stack=x}, {orderID=x, itemId=x, stack=x}, ...}
    self:BroadcastObservers(UIEvent.ObtainItems, obtainItems)
end

-- 清空新纪录数量
function CTrade:ClearNewRecordNum()
    self.newRecordNum = 0
    self:BroadcastObservers(UIEvent.RecordChanged, self.newRecordNum)
end

-- 新记录数量
function CTrade:GetNewRecordNum()
    return self.newRecordNum
end

-- 收藏操作
function CTrade:MarkProduct(isMark, item)
    if item ~= nil then
        self:CallServer(Protocol.ClientMSGID.TRADE_MARKS_REQ, { isMark=isMark, itemID=item.id })
    else
        self:CallServer(Protocol.ClientMSGID.TRADE_MARKS_REQ, {})
    end
end

-- 查询订单数量
function CTrade:QueryOrderNum()
    self:CallServer(Protocol.ClientMSGID.TRADE_GET_NUM_REQ, { filters={}, conditions={ isOwner=true }, sortType=1 })
end

-- 售卖商品
function CTrade:SellProduct(item, count, price, isSellAll)
    local productData = self:CreateProduct(item, count, price)
    if productData ~= nil then
        self:CallServer(Protocol.ClientMSGID.TRADE_SELL_REQ, { productData=productData, isSellAll=isSellAll })
    else
        UIManager:ShowTip("上架失败，创建订单失败！")
    end    
end

-- 售卖返回
function CTrade:OnResponseTradeSell(body)
    if body.orderID ~= nil then
        UIManager:ShowTip("上架成功！")

        -- 更新订单信息
        local storeData = self.storeData
        if storeData.conditions.isOwner then
            local newOrder = body.orderInfo
            local orders = storeData.orders
            for i, orderInfo in pairs(orders) do
                if orderInfo.orderID == newOrder.orderID then
                    for k, v in pairs(newOrder) do
                        orderInfo[k] = v
                    end
                    -- 超时订单
                    newOrder = nil
                    break
                end
            end
            -- 新订单
            if newOrder then
                orders[#orders + 1] = newOrder
            end
            -- table.sort(orders, function(r0, r1) return r0.id < r1.id end)
            -- 通知界面刷新
            if newOrder ~= nil then
                self:BroadcastObservers(UIEvent.SellSuccess, orders, newOrder.extendData.itemId)
            else
                self:BroadcastObservers(UIEvent.SellSuccess, orders, nil)
            end
        end
    end
end

-- 购买商品
function CTrade:BuyProduct(orderID, itemID, count, isFromTrade)
    local isFromTrade = isFromTrade ~= false
    self:CallServer(Protocol.ClientMSGID.TRADE_BUY_REQ, { orderID=orderID, itemID=itemID, count=count, isFromTrade=isFromTrade })
end

-- 购买返回
function CTrade:OnResponseTradeBuy(body)
    local orderID = body.orderID
    if orderID ~= nil then
        local itemID = body.itemID
        local itemConfig = InventoryManager:GetItemData(itemID)
        local itemName = itemConfig and itemConfig.name or ""

        if body.count > 0 then
            UIManager:ShowTip(string.format("购买%sX%d！", itemName, body.count))
        else
            UIManager:ShowTip(string.format("%s已售空，购买失败！", itemName))
        end

        local orderData = body.orderData
        local status, orders = self:UpdateStoreOrderData(itemID, orderData)
        -- 通知界面刷新
        if status then
            self:BroadcastObservers(UIEvent.BuySuccess, orders)
        end

        -- 订单失效
        if orderData == nil then
            self:QueryOrderByItemIDFromServer(itemID, 1)
        end
    end
end

-- 从其他地方购买返回
function CTrade:OnResponseTradeOtherBuy(body)
    local orderID = body.orderID
    local count = body.count
    local orderData = body.orderData
    -- 订单失效
    if orderData == nil then
        self:QueryOrdersByItemIDsFromServer({body.itemID}, 1)
    end
    -- count大于0购买成功
    self:BroadcastObservers(UIEvent.BuyFromOther, orderID, count)
end

-- 请求订单数据 queryType=> 1请求订单 2请求价格
function CTrade:QueryOrderByItemIDFromServer(itemID, queryType)
    self:CallServer(Protocol.ClientMSGID.TRADE_GET_ITEM_REQ, { itemID=itemID, queryType=queryType, sortType=3 })
end

-- 请求道具价格
function CTrade:QueryItemPriceFromServer(itemID)
    self:QueryOrderByItemIDFromServer(itemID, 2)
end

-- 更新订单信息
function CTrade:OnResponseTradeGetItem(body)
    local queryType = body.queryType
    if queryType == 1 then
        self:HandleOrderInfoQuery(body)
    elseif queryType == 2 then
        self:HandleItemPriceQuery(body)
    end
end

-- 处理价格请求
function CTrade:HandleItemPriceQuery(body)
    local itemID = body.itemID
    if #body.orders <= 0 then
        local itemConfig = InventoryManager:GetItemData(itemID)
        self:BroadcastObservers(UIEvent.TradeGetPrice, itemID, itemConfig and itemConfig.sellPrice or 0)
    else
        self:BroadcastObservers(UIEvent.TradeGetPrice, itemID, body.orders[1].price)
    end
end

-- 处理订单请求
function CTrade:HandleOrderInfoQuery(body)
    local itemID = body.itemID
    if #body.orders <= 0 then
        local status, orders = self:RemoveStoreOrderData(itemID)
        -- 通知界面刷新
        if status then
            self:BroadcastObservers(UIEvent.CancelSuccess, orders)
        end
    else
        local status, orders = self:UpdateStoreOrderData(itemID, body.orders[1])
        -- 通知界面刷新
        if status then
            self:BroadcastObservers(UIEvent.OrderChanged, orders)
        end
    end
end

-- 请求订单列表数据 queryType=> 1请求订单列表 2请求价格列表
function CTrade:QueryOrdersByItemIDsFromServer(idArr, queryType)
    self:CallServer(Protocol.ClientMSGID.TRADE_GET_ITEMS_REQ, { idArr=idArr, queryType=queryType, sortType=3 })
end

-- 返回订单列表信息
function CTrade:OnResponseTradeGetItems(body)
    local queryType = body.queryType
    if queryType == 1 then
        self:HandleOrderInfosQuery(body)
    elseif queryType == 2 then
        self:HandleItemsPriceQuery(body)
    end
end

-- 订单信息
function CTrade:HandleOrderInfosQuery(body)
    local orderMap = {}
    local idArr = body.idArr
    local orders = body.orders
    for i, orderInfo in pairs(orders) do
        orderMap[orderInfo.id] = orderInfo
    end
    self:BroadcastObservers(UIEvent.TradeGetItems, orderMap, idArr)
end

-- 处理价格列表请求
function CTrade:HandleItemsPriceQuery(body)
    local prices = {}
    local orderMap = {}
    local idArr = body.idArr
    local orders = body.orders
    for i, orderInfo in pairs(orders) do
        orderMap[orderInfo.id] = orderInfo
    end
    for i, itemID in pairs(idArr) do
        local orderInfo = orderMap[itemID]
        if orderInfo == nil then
            local itemConfig = InventoryManager:GetItemData(itemID)
            prices[itemID] = itemConfig and itemConfig.sellPrice or 0
        else
            prices[itemID] = orderInfo.price
        end
    end
    self:BroadcastObservers(UIEvent.TradeGetPrices, prices)
end

-- 重新上架
function CTrade:ReSellProduct(orderID)
    self:CallServer(Protocol.ClientMSGID.TRADE_RESELL_REQ, { orderID=orderID })
end

-- 取消商品
function CTrade:CancelProduct(orderID)
    self:CallServer(Protocol.ClientMSGID.TRADE_CANCEL_REQ, { orderID=orderID })
end

-- 取消返回
function CTrade:OnResponseTradeCancel(body)
    local orderID = body.orderID
    if orderID ~= nil then
        if body.status then
            UIManager:ShowTip("取消成功！")
        end

        local status, orders = self:RemoveOrderData(orderID)
        -- 通知界面刷新
        if status then
            self:BroadcastObservers(UIEvent.CancelSuccess, orders)
        end
    end
end

-- 请求订单记录
function CTrade:QueryTradeRecords(recordType)
    local recordData = self.recordData
    recordData.isEnd = false
    recordData.queryType = recordType

    -- 通知界面刷新
    self:BroadcastObservers(UIEvent.RecordGet, recordData[recordType] or {})
    -- 尝试请求新数据
    self:CallServer(Protocol.ClientMSGID.TRADE_RECORDS_REQ, { frontID=recordData.frontID, cacheLen=recordData.cacheNum })
end

function CTrade:IsRecordToEnd(itemData)
    return itemData.orderID == self.recordData.lastID
end

-- 尝试查询下一页记录数据
function CTrade:TryQueryRecordNextPage(itemData)
    if self:IsRecordToEnd(itemData) then
        self:QueryRecordNextPage()
    end
end

-- 查询下一页记录数据
function CTrade:QueryRecordNextPage()
    local recordData = self.recordData
    if recordData.isEnd then
        return
    end
    self:CallServer(Protocol.ClientMSGID.TRADE_RECORDS_REQ, { frontID=recordData.frontID, cacheLen=recordData.cacheNum })
end

-- 订单返回
function CTrade:OnResponseTradeRecords(body)
    local recordData = self.recordData
    recordData.isEnd = body.isEnd
    recordData.frontID = body.frontID

    -- 未覆盖到已缓存的数据，则重新请求
    if not body.isCover then
        recordData.Buy = {}
        recordData.Sell = {}
    end
    local records = body.records
    local frontNum = body.frontNum
    local len = #records
    -- 倒序插入新数据
    for i=frontNum, 1, -1 do
        local recordType = nil
        local record = records[i]
        if self:IsMyOrder(record.sellerID) then
            recordType = RecordType.Sell -- 售卖记录
        else
            recordType = RecordType.Buy -- 购买记录
        end
        table.insert(recordData[recordType], 1, record)
    end
    -- 正序插入旧数据
    for i=frontNum+1, len, 1 do
        local recordType = nil
        local record = records[i]
        if self:IsMyOrder(record.sellerID) then
            recordType = RecordType.Sell -- 售卖记录
        else
            recordType = RecordType.Buy -- 购买记录
        end
        table.insert(recordData[recordType], record)
    end

    if len > 0 then
        recordData.lastID = records[len].orderID
        recordData.cacheNum = recordData.cacheNum + len
        self:BroadcastObservers(UIEvent.RecordGet, recordData[recordData.queryType] or {})
    end
end

-- 请求云服订单数据
function CTrade:QueryOrdersFromServer(factors, conditions, sortType)
    local storeData = self.storeData
    storeData.seq = storeData.seq + 1
    storeData.orders = {}
    storeData.isEnd = false
    storeData.lastIndex = 0
    storeData.factors = factors
    storeData.conditions = conditions
    storeData.sortType = sortType

    -- 通知界面刷新
    self:BroadcastObservers(UIEvent.TradeGet, storeData.orders)
    -- 请求数据
    self:CallServer(Protocol.ClientMSGID.TRADE_GET_REQ, { seq=storeData.seq, sortType=sortType,
        filters=factors, conditions=conditions, lastIndex=0 })
end

function CTrade:IsOrderToEnd(itemData)
    local orders = self.storeData.orders
    local len = #orders
    if len <= 0 then
        return false
    end
    return orders[len].orderID == itemData.orderID
end

-- 尝试查询下一页商品数据
function CTrade:TryQueryOrderNextPage(itemData)
    if self:IsOrderToEnd(itemData) then
        self:QueryOrderNextPage()
    end
end

-- 查询下一页商品数据
function CTrade:QueryOrderNextPage()
    local storeData = self.storeData
    if storeData.seq <= 0 then
        return
    end
    if storeData.isEnd then
        return
    end
    self:CallServer(Protocol.ClientMSGID.TRADE_GET_REQ, { seq=storeData.seq, filters=storeData.factors, 
        conditions=storeData.conditions, sortType=storeData.sortType, lastIndex=storeData.lastIndex})
end

-- 商店列表
function CTrade:OnResponseTradeGet(body)
    local storeData = self.storeData
    if (body.seq ~= storeData.seq) or (body.lastIndex <= 0) then
        -- 不是当次查询的数据、没有查到数据
        return
    end
    storeData.isEnd = body.isEnd
    storeData.lastIndex = body.lastIndex

    local status = false
    local len = #body.orders
    local isOwner = storeData.conditions.isOwner or false
    for i = 1, len, 1 do
        local orderData = body.orders[i]
        if self:IsProductAvailable(isOwner, orderData) then
            status = true
            storeData.orders[#storeData.orders+1] = orderData
        end        
    end
    if status then
        self:BroadcastObservers(UIEvent.TradeGet, storeData.orders)
    else
        self:QueryOrderNextPage()
    end
end

-- 更新订单数据,仅限购买列表数据
function CTrade:UpdateStoreOrderData(itemID, orderData)
    local status = false
    local storeData = self.storeData
    if storeData.conditions.isOwner then
        return status
    end
    local orders = storeData.orders
    for i = #orders, 1, -1 do
        local tempData = orders[i]
        if tempData.id == itemID then
            status = true
            -- 同订单（更新数量）或不同订单（订单卖完）
            if orderData ~= nil then
                for k, v in pairs(orderData) do
                    tempData[k] = v
                end
            else
                tempData.count = 0
            end
            break
        end
    end
    return status, orders
end

-- 移除订单数据
function CTrade:RemoveStoreOrderData(itemID)
    local status = false
    local storeData = self.storeData
    if storeData.conditions.isOwner then
        return status
    end
    local orders = self.storeData.orders
    for i = #orders, 1, -1 do
        if orders[i].id == itemID then
            status = true
            table.remove(orders, i)          
            break
        end
    end
    return status, orders
end

-- 移除订单数据
function CTrade:RemoveOrderData(orderID)
    local status = false
    local orders = self.storeData.orders
    for i = #orders, 1, -1 do
        if orders[i].orderID == orderID then
            status = true
            table.remove(orders, i)          
            break
        end
    end
    return status, orders
end

function CTrade:GetOrders()
    return self.storeData.orders
end

----------------------UI相关------------------------
-- 品级背景图
function CTrade:GetQualityColor(quality)
    if self.qualityColors == nil then
        self.qualityColors = {
            default = ColorQuad.New(0, 0, 0, 0),
            [ItemDefines.EItemQuality.C] = ColorQuad.New(0x1f, 0x30, 0x26, 255),
            [ItemDefines.EItemQuality.B] = ColorQuad.New(0x27, 0x3a, 0x4a, 255),
            [ItemDefines.EItemQuality.A] = ColorQuad.New(0x3a, 0x36, 0x4f, 255),
            [ItemDefines.EItemQuality.S] = ColorQuad.New(0x5f, 0x4d, 0x43, 255),
            [ItemDefines.EItemQuality.SS] = ColorQuad.New(0x49, 0x2d, 0x30, 255) 
        }
    end
    return self.qualityColors[quality] or self.qualityColors.default
end

CTrade:Init()

return CTrade