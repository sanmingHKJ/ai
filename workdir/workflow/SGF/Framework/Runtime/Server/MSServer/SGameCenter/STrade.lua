local Protocol = MS.Protocol
local Utils = GFScript("CoreModule.Utils")
local Network = GFScript("NetworkModule.Network")
local DataPlayersManager = GFScript("CoreModule.DataPlayersManager")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local TimerManager = GFScript("CoreModule.TimerManager")
local ItemUtils = GFScript("InventoryModule.ItemUtils")
local MapId = tonumber(game.RunService:GetCurMapOwid())
local SGameCenter = nil

local STrade = {}

function STrade:Init(_SGameCenter)
    local Trade = self
    SGameCenter = _SGameCenter

    self.centerTimeInfo = {}
    self.orderPriceMap = {}
    MS.NetworkHelper:RegisterNetObj(self)

    self:OnRequest(Protocol.ClientMSGID.TRADE_MARKS_REQ, function(userId, msgid, data)
        self:OnReqTradeMark(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_SELL_REQ, function(userId, msgid, data)
        self:OnReqTradeSell(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_RESELL_REQ, function(userId, msgid, data)
        self:OnReqTradeReSell(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_BUY_REQ, function(userId, msgid, data)
        self:OnReqTradeBuy(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_CANCEL_REQ, function(userId, msgid, data)
        self:OnReqTradeCancel(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_GET_REQ, function(userId, msgid, data)
        self:OnReqTradeGet(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_GET_NUM_REQ, function(userId, msgid, data)
        self:OnReqTradeGetNum(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_GET_ITEM_REQ, function(userId, msgid, data)
        self:OnReqTradeGetItem(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_GET_ITEMS_REQ, function(userId, msgid, data)
        self:OnReqTradeGetItems(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_RECORDS_REQ, function(userId, msgid, data)
        self:OnReqTradeRecords(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.TRADE_REPORT_REQ, function(userId, msgid, data)
        self:OnReqTradeReport(userId, data)
    end)    

    self:OnRequest(Protocol.ClientMSGID.TRADE_SAVE_DATA_REQ, function(userId, msgid, data)
        DataPlayersManager:TrySavePlayer(userId)
    end)

    -- Center至云服消息
    function SGameCenter.CenterHandler:ResponseGCTrade(uin, body)
        local data = body.msg
        local opt = data.opt
        if not body.ok then
            return Network:Error("SGameCenter.CenterHandler:ResponseGCTrade No Data:" .. tostring(opt))
        end
        local handler = Trade[opt]
        if not handler then
            return Network:Error("SGameCenter.CenterHandler:ResponseGCTrade No Handler:" .. tostring(opt))
        end
        data.opt = nil
        local ok, msg = pcall(handler, Trade, uin, data)
        if not ok then
            Network:Error("SGameCenter.CenterHandler:ResponseGCTrade Error:" .. tostring(opt))
        end
    end
end

-- 中心服是否已连接
function STrade:IsGameCenterAvailable()
    return (SGameCenter ~= nil) and SGameCenter:IsOnLine()
end

-- 同步中心服时间
function STrade:NotifyPlayerCenterServerTime(uin)
    if self:IsGameCenterAvailable() then
        print("STrade:NotifyPlayerCenterServerTime")

        local centerTime = self.centerTimeInfo.time
        if centerTime ~= nil then
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_SERVERTIME_RSP, { centerServerTime=centerTime })
        else
            local curTime = os.time()
            local expired = self.centerTimeInfo.expired
            if expired == nil or expired < curTime then
                self.centerTimeInfo.expired = curTime + 2
                SGameCenter:ToCenter("TradeFromClient", uin, { typ="SyncCenterTime", sid=0 })
            end        
        end
    else
        print("STrade:NotifyPlayerCenterServerTime Ban")
    end
end

-- 同步中心服时间
function STrade:OnSyncCenterTime(uin, body)
    local centerTimeInfo = self.centerTimeInfo
    centerTimeInfo.time = body.timestamp

    if centerTimeInfo.tickTimer == nil then
        centerTimeInfo.tickTimer = TimerManager:AddTimer(function(dt)
            centerTimeInfo.time = centerTimeInfo.time + dt
        end, 1)
    end

    MSServer.SActorManager:ForEachPlayer(function(player)
        self:CallClient(player:GetPlayerId(), Protocol.ServerMSGID.TRADE_SERVERTIME_RSP, 
            { centerServerTime=centerTimeInfo.time })
    end)
end

function STrade:GetConfig()
    local tConfig = self.tConfig
    if tConfig == nil then
        tConfig = MS.Config.GetConfigs("TradeConfig")
        self.tConfig = tConfig
    end
    return tConfig
end

-- 收益订单模板
function STrade:GetIncomeTemplate()
    if self.incomeOrder == nil then
        local tConfig = self:GetConfig()
        local productData = Utils:DeepCopy(tConfig.OrderTemplate)
        productData.type = tConfig.CurrencyType
        productData.id = tConfig.CurrencyID
        productData.feeRate = tConfig.FeeRate
        self.incomeOrder = productData
    end
    return self.incomeOrder
end

-- 交易日志
function STrade:DoTradeReport(uin, opt, order)
    local reportData = {}
    reportData.eventId = MS.ReportData.EventDefine.Trade
    reportData.userId = uin
    reportData.standby1 = opt
    reportData.standby2 = order.type
    reportData.standby3 = order.id
    reportData.standby4 = order.price
    reportData.standby5 = order.count
    if order.extendData ~= nil then
        reportData.standby6 = tostring(order.extendData.itemId)
    end
    MS.ReportData:Report(reportData)
end

-- 花费money
function STrade:PayMoney(uin, value, source)
    local player = MSServer.SActorManager:GetPlayerByUserId(uin)
    if player ~= nil then
        local tConfig = self:GetConfig()
        return player.InventoryComponent:RemoveItemByTid(tConfig.CurrencyID, value, "trade", source)
    end
    return false
end

-- 扣除售卖物品
function STrade:DeductSaleItem(uin, product)
    print(string.format("STrade:DeductSaleItem:%d - %s - %s", uin, tostring(product.type), tostring(product.id)))
    local player = MSServer.SActorManager:GetPlayerByUserId(uin)
    if player == nil then
        return false
    end
    local price = math.floor(tonumber(product.price) or 0)
    local count = math.floor(tonumber(product.count) or 0)
    -- 校验输入
    if price <= 0 or count <= 0 then
        return false
    end
    if product.extendData == nil then
        return false
    end
    local itemId = product.extendData.itemId
    if itemId == nil then
        return false
    end
    local tConfig = self:GetConfig()
    local deposit = math.floor(price * count * tConfig.DepositRate / 100)

    local totalCurrency = player.InventoryComponent:CountItemByTid(tConfig.CurrencyID)
    if totalCurrency < deposit then
        return false
    end
    product.feeRate = tConfig.FeeRate
    product.deposit = deposit
    product.price = price
    product.count = count

    local item, container = ItemUtils:GetItemFromActorById(player, itemId)
    if item == nil or container == nil then
        return false
    end

    if item.data.type == "SafeBox" then
        return false
    end
    if container:RemoveItemById(itemId, count, "trade", "DeductSaleItem") then
        self:PayMoney(uin, deposit, "Deposit")
        return true
    end
    return false
end

-- 请求售卖
function STrade:OnReqTradeSell(uin, data)
    if self:IsGameCenterAvailable() then
        local product = data.productData
        if self:DeductSaleItem(uin, product) then
            local playerInfo = MSServer.SGameCenter:GetPlayerInfoByID(uin)
            if playerInfo ~= nil then
                product.sellerName = playerInfo.name
            end
            -- 上报日志
            self:DoTradeReport(uin, "Sell", product)
            SGameCenter:ToCenter("TradeFromClient", uin, { typ="TradeSellGoods", orderInfo=product, isSellAll=data.isSellAll, sid=0 })
        else
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_TIP_RSP, { tip="售卖物品或保证金扣除失败，交易失败！" })
        end        
    else
        print("STrade:OnReqTradeSell Ban")
    end
end

-- 请求重新上架
function STrade:OnReqTradeReSell(uin, data)
    if self:IsGameCenterAvailable() then
        SGameCenter:ToCenter("TradeFromClient", uin, { typ="TradeReSellGoods", orderID=data.orderID, sid=0 })
    else
        print("STrade:OnReqTradeReSell Ban")
    end
end

-- 中心服售卖返回
function STrade:OnGCResTradeSell(uin, data)
    if data.orderID ~= nil then
        -- 售卖成功
        self:CallClient(uin, Protocol.ServerMSGID.TRADE_SELL_RSP, data)
        print("STrade:OnGCResTradeSell:" .. tostring(data.orderID))
    else
        self:CallClient(uin, Protocol.ServerMSGID.TRADE_TIP_RSP, { tip="操作失败，请稍后重试！" })
    end
end

-- 请求购买
function STrade:OnReqTradeBuy(uin, body)
    if self:IsGameCenterAvailable() then
        local isFromTrade = body.isFromTrade
        local price = self.orderPriceMap[body.orderID]
        if price == nil then
            print("STrade:OnReqTradeBuy No Price")
            if isFromTrade then
                self:CallClient(uin, Protocol.ServerMSGID.TRADE_TIP_RSP, { tip="购买失败，售卖物品无法获得价格！" })
            else
                self:CallClient(uin, Protocol.ServerMSGID.TRADE_ERROR_RSP, { errCode=1 })
            end
            return
        end
        if self:PayMoney(uin, body.count * price, "trade") then
            local nickName = ""
            local playerInfo = MSServer.SGameCenter:GetPlayerInfoByID(uin)
            if playerInfo ~= nil then
                nickName = playerInfo.name
            end
            self:DoTradeReport(uin, "Buy", { type="Product", id=body.orderID, price=price, count=body.count, isFromTrade=isFromTrade })
            SGameCenter:ToCenter("TradeFromClient", uin, {typ="TradeBuyGoods", orderID=body.orderID, nickName=nickName, 
                itemID=body.itemID, count=body.count, price=price, income=self:GetIncomeTemplate(), isFromTrade=isFromTrade, sid=0})
        else
            if isFromTrade then
                self:CallClient(uin, Protocol.ServerMSGID.TRADE_TIP_RSP, { tip="购买失败，货币不足！" })
            else
                self:CallClient(uin, Protocol.ServerMSGID.TRADE_ERROR_RSP, { errCode=2 })
            end
        end        
        print("STrade:OnReqTradeBuy:" .. tostring(body.orderID))
    else
        if isFromTrade then
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_TIP_RSP, { tip="暂未开放，请稍后重试" })
        else
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_ERROR_RSP, { errCode=3 })
        end
        print("STrade:OnReqTradeBuy Ban")
    end
end

-- 中心服购买返回
function STrade:OnGCResTradeBuy(uin, data)
    if data.orderID ~= nil then
        if data.isFromTrade then
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_BUY_RSP, data)
        else
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_OTHER_BUY_RSP, data)
        end
        print("STrade:OnGCResTradeBuy:" .. tostring(data.orderID) .. " " .. tostring(data.count))
    else
        print("STrade:OnGCResTradeBuy Error")
    end
end

-- 请求取消
function STrade:OnReqTradeCancel(uin, body)
    if self:IsGameCenterAvailable() then
        self:DoTradeReport(uin, "Cancel", { type="Product", id=body.orderID, price=0, count=1 })
        SGameCenter:ToCenter("TradeFromClient", uin, {typ="TradeCancelGoods", orderID=body.orderID, sid=0 })
        print("STrade:OnReqTradeCancel:" .. tostring(body.orderID))
    else
        print("STrade:OnReqTradeCancel Ban")
    end
end

-- 中心服取消返回
function STrade:OnGCResTradeCancel(uin, data)
    if data.orderID ~= nil then
        -- 取消成功
        self:CallClient(uin, Protocol.ServerMSGID.TRADE_CANCEL_RSP, data)
        print("STrade:OnGCResTradeCancel:" .. tostring(data.orderID))
    else
        print("STrade:OnGCResTradeCancel Error")
    end
end

-- 请求收藏操作
function STrade:OnReqTradeMark(uin, data)
    if data.itemID == nil then
        -- 请求
        self:CallClient(uin, Protocol.ServerMSGID.TRADE_MARKS_RSP, { markArr=DataPlayersManager:GetTradeMarks(uin) } )
    else
        -- 更新
        local isSuccess = false
        if data.isMark then
            isSuccess = DataPlayersManager:AddMark(uin, data.itemID)
        else
            isSuccess = DataPlayersManager:CancelMark(uin, data.itemID)
        end
        if isSuccess then
            self:CallClient(uin, Protocol.ServerMSGID.TRADE_MARKS_RSP, { markArr=DataPlayersManager:GetTradeMarks(uin) } )
        end
    end
end

-- 经营数据
function STrade:OnReqTradeReport(uin)
    self:CallClient(uin, Protocol.ServerMSGID.TRADE_REPORT_RSP, DataPlayersManager:GetReportData(uin))
end

-- 解析查询条件
function STrade:ResolveQueryConditions(uin, param, info)
    local conditions = {}
    if info.isMark then
        local markMap = {}
        local markArr = DataPlayersManager:GetTradeMarks(uin)
        for i = #markArr, 1, -1 do
            markMap[markArr[i]] = true
        end
        conditions.id = markMap
    elseif info.isOwner then
        conditions.sellerID = { [uin] = true }
    end
    param.conditions = conditions
end

-- 查询交易记录
function STrade:OnReqTradeRecords(uin, body)
    if self:IsGameCenterAvailable() then
        SGameCenter:ToCenter("TradeFromClient", uin, { typ="TradeGetRecords", frontID=body.frontID, 
            cacheLen=body.cacheLen, querySize=20, sid=0 })

        print("STrade:OnReqTradeRecords:" .. tostring(body.lastIndex))
    else
        print("STrade:OnReqTradeRecords Ban")
    end
end

function STrade:OnGCResTradeRecordsGet(uin, data)
    self:CallClient(uin, Protocol.ServerMSGID.TRADE_RECORDS_RSP, data)
    print("STrade:OnGCResTradeRecordsGet:" .. tostring(data.lastIndex))
end

-- 获取订单数量
function STrade:OnReqTradeGetNum(uin, body)
    if self:IsGameCenterAvailable() then
        local tConfig = self:GetConfig()
        local param = { typ="TradeGetNum", seq=0, duration=tConfig.OutTime or 3600, 
            sortType=body.sortType, filters=body.filters or {}, lastIndex=0, querySize=100, sid=0 }
        self:ResolveQueryConditions(uin, param, body.conditions)
        SGameCenter:ToCenter("TradeFromClient", uin, param)
        print("STrade:OnReqTradeGetNum:" .. tostring(uin))
    else
        print("STrade:OnReqTradeGetNum Ban")
    end
end

-- 返回订单数量
function STrade:OnGCResTradeGetNum(uin, data)
    local orders = data.orders or {}
    local orderNum = #orders
    self:CallClient(uin, Protocol.ServerMSGID.TRADE_GET_NUM_RSP, { orderNum=orderNum })
    print("STrade:OnGCResTradeGetNum:" .. tostring(orderNum))
end

-- 按页请求列表
function STrade:OnReqTradeGet(uin, body)
    if self:IsGameCenterAvailable() then
        local tConfig = self:GetConfig()
        local param = { typ="TradeGetGoods", seq=body.seq, duration=tConfig.OutTime or 3600, 
            sortType=body.sortType, filters=body.filters or {}, lastIndex=body.lastIndex or 0, querySize=20, sid=0 }
        self:ResolveQueryConditions(uin, param, body.conditions)
        SGameCenter:ToCenter("TradeFromClient", uin, param)
        print("STrade:OnReqTradeGet:" .. tostring(body.lastIndex))
    else
        print("STrade:OnReqTradeGet Ban")
    end
end

function STrade:CacheOrderPrice(orders)
    for i=#orders, 1, -1 do
        local orderInfo = orders[i]
        self.orderPriceMap[orderInfo.orderID] = orderInfo.price
    end
end

-- 获取列表返回
function STrade:OnGCResTradeGet(uin, data)
    self:CacheOrderPrice(data.orders or {})
    self:CallClient(uin, Protocol.ServerMSGID.TRADE_GET_RSP, data)

    print("STrade:OnGCResTradeGet:" .. tostring(data.lastIndex))
end

-- 按道具ID请求订单
function STrade:OnReqTradeGetItem(uin, body)
    if self:IsGameCenterAvailable() then
        local itemID = body.itemID
        local tConfig = self:GetConfig()
        local param = { typ="TradeGetGoodByItemID", seq=0, itemID=itemID, duration=tConfig.OutTime or 3600, 
            sortType=body.sortType, conditions = { id={ [itemID] = true } }, filters=body.filters or {}, 
            lastIndex=body.lastIndex or 0, querySize=1, queryType=body.queryType, sid=0 }
        SGameCenter:ToCenter("TradeFromClient", uin, param)
        print("STrade:OnReqTradeGetItem:" .. tostring(itemID))
    else
        print("STrade:OnReqTradeGetItem Ban")
    end
end

-- 按道具ID列表请求订单
function STrade:OnReqTradeGetItems(uin, body)
    if self:IsGameCenterAvailable() then
        local idArr = body.idArr
        local idMap = {}
        local conditions = { id=idMap }
        for i, itemID in pairs(idArr) do
            idMap[itemID] = true
        end
        local tConfig = self:GetConfig()
        local param = { typ="TradeGetGoodByItemIDs", seq=0, idArr=idArr, duration=tConfig.OutTime or 3600, 
            sortType=body.sortType, conditions=conditions, filters=body.filters or {}, 
            lastIndex=body.lastIndex or 0, querySize=1, queryType=body.queryType, sid=0 }
        SGameCenter:ToCenter("TradeFromClient", uin, param)
        print("STrade:OnReqTradeGetItem:" .. table.concat(idArr, ","))
    else
        print("STrade:OnReqTradeGetItem Ban")
    end
end

-- 按道具ID获取订单信息
function STrade:OnGCResTradeGetItem(uin, data)
    self:CacheOrderPrice(data.orders or {})
    self:CallClient(uin, Protocol.ServerMSGID.TRADE_GET_ITEM_RSP, data)
end

-- 按道具ID列表获取订单信息
function STrade:OnGCResTradeGetItems(uin, data)
    self:CacheOrderPrice(data.orders or {})
    self:CallClient(uin, Protocol.ServerMSGID.TRADE_GET_ITEMS_RSP, data)
end

-- 玩家上线
function STrade:OnPlayerAdded(player, second)
    self:NotifyPlayerCenterServerTime(player.UserId)
end

-- 玩家下线
function STrade:OnPlayerRemoved(player)

end

return STrade