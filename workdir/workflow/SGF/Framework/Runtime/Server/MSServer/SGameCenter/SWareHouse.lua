local Protocol = MS.Protocol
local Network = GFScript("NetworkModule.Network")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local InventoryKismet = GFScript("InventoryModule.InventoryKismet")
local InventoryManager = GFScript("InventoryModule.InventoryManager")
local DataPlayersManager = GFScript("CoreModule.DataPlayersManager")
local MapId = tonumber(game.RunService:GetCurMapOwid())
local SGameCenter = nil

local SWareHouse = {}
-- Source和GWareHouse定义需要同步
local Source = {
    UnKnow      = "UnKnow",
    TradeFail   = "TradeFail",
    TradeSuccess= "TradeSuccess",
    TradeCancel = "TradeCancel",
    TradeBuy    = "TradeBuy",
    TradeBack   = "TradeBack",
    TradeBuyFail= "TradeBuyFail",
    ItemStore   = "ItemStore",
}
SWareHouse.Source = Source

function SWareHouse:Init(_SGameCenter)
    local WareHouse = self
    SGameCenter = _SGameCenter

    MS.NetworkHelper:RegisterNetObj(self)

    -- 仓库存道具
    self:OnRequest(Protocol.ClientMSGID.WAREHOUSE_STORE_ITEM_REQ, function(userId, msgid, data)
    end)
    -- 仓库取道具
    self:OnRequest(Protocol.ClientMSGID.WAREHOUSE_FETCH_ITEM_REQ, function(userId, msgid, data)
    end)

    -- 匹配成功，进入战场
    function SGameCenter.CenterHandler:ResponseGCWareHouse(uin, body)
        local data = body.msg
        local opt = data.opt
        if not body.ok then
            return Network:Error("SGameCenter.CenterHandler:ResponseGCWareHouse No Data:" .. tostring(opt))
        end
        local handler = WareHouse[opt]
        if not handler then
            return Network:Error("SGameCenter.CenterHandler:ResponseGCWareHouse No Handler:" .. tostring(opt))
        end
        data.opt = nil
        local ok, msg = pcall(handler, WareHouse, uin, data)
        if not ok then
            Network:Error("SGameCenter.CenterHandler:ResponseGCWareHouse Error:" .. tostring(opt))
        end
    end
end

-- 中心服是否已连接
function SWareHouse:IsGameCenterAvailable()
    return (SGameCenter ~= nil) and SGameCenter:IsOnLine()
end

-- 检测仓库待领取物品
function SWareHouse:OnPlayerAdded(player, second)
    -- self:CheckWareHouseItems(player.UserId)
end

function SWareHouse:CheckOfflineItems(uin)
    self:CheckWareHouseItems(uin)
end

function SWareHouse:CheckWareHouseItems(uin)
    if self:IsGameCenterAvailable() then
        local orderCursor = DataPlayersManager:GetWareHouseOrderCursor(uin)
        if orderCursor ~= nil then
            SGameCenter:ToCenter("WareHouseFromClient", uin, { typ="WareHouseAvailableOrders", orderCursor=orderCursor, sid=0 })
            print("SWareHouse:CheckWareHouseItems Available:" .. tostring(orderCursor))
        else
            print("SWareHouse:CheckWareHouseItems Failed")
        end
    else
        print("SWareHouse:CheckWareHouseItems GameCenter Out Of Service")
    end
end

-- 交易日志
function SWareHouse:DoTradeReport(uin, opt, infoStr, curCursor, tarCursor)
    local reportData = {}
    reportData.eventId = MS.ReportData.EventDefine.WareHouse
    reportData.userId = uin
    reportData.standby1 = opt
    reportData.standby2 = infoStr
    reportData.standby3 = curCursor
    reportData.standby4 = tarCursor
    MS.ReportData:Report(reportData)

    print("SWareHouse:DoTradeReport >> " .. infoStr)
end

function SWareHouse:IsCurrencyType(order)
    local tConfig = self.tConfig
    if tConfig == nil then
        tConfig = MS.Config.GetConfigs("TradeConfig")
        self.tConfig = tConfig
    end
    return (tConfig ~= nil) and (tConfig.CurrencyType == order.type)
end

-- 获得仓库物品
function SWareHouse:ObtainOrderItems(uin, orders, curCursor, tarCursor)
    print(string.format("SWareHouse:ObtainOrderItems:%d - %d - %d", uin, curCursor, tarCursor))
    local player = MSServer.SActorManager:GetPlayerByUserId(uin)
    if player == nil then
        print("SWareHouse:ObtainOrderItems Error & Offline")
        return
    end
    local reportArr = {}
    local len = #orders
    local obtainItems = {}
    for i=1, len, 1 do
        local orderInfo = orders[i]
        if self:IsCurrencyType(orderInfo) then
            if orderInfo.source == Source.TradeSuccess then
                -- 交易成功
                local income = orderInfo.count
                local feeRate = orderInfo.feeRate
                if feeRate > 0 and feeRate < 100 then
                    income = math.floor((100 - feeRate) * income / 100)
                end
                InventoryKismet:AddInventoryItemByTid(player, orderInfo.id, income, "trade", "trade")
            elseif orderInfo.source == Source.TradeBack or orderInfo.source == Source.TradeBuyFail then
                -- 退回
                InventoryKismet:AddInventoryItemByTid(player, orderInfo.id, orderInfo.count, "trade", "tradeBack")
            else
                -- unkonw source
            end
        else
            local item = InventoryManager:CreateItem(orderInfo.id, orderInfo.count, player)
            if item == nil then
                self:DoTradeReport(uin, "obtain", string.format("not item:%s %s %s", 
                        tostring(orderInfo.type), tostring(orderInfo.id), orderInfo.count) , 0, 0)
            else
                if orderInfo.extendData ~= nil then
                    item:Deserialize(orderInfo.extendData)
                    item:SetStack(orderInfo.count)
                    item.itemId = nil
                    item.container = nil
                end
                item:SetBind(true)

                local status = player.InventoryComponent:AddItem(item, "trade", "trade")
                if status then
                    obtainItems[#obtainItems + 1] = { orderID=orderInfo.orderID, itemId=item.itemId, stack=item.stack }
                    player:Fire(true, "ObtainOrderItem", orderInfo.orderID, item.itemId, item.stack)
                else
                    obtainItems[#obtainItems + 1] = { orderID=orderInfo.orderID, itemId=0, stack=0 }
                    player:Fire(true, "ObtainOrderItem", orderInfo.orderID, 0, 0)

                    self:DoTradeReport(uin, "obtain", string.format("not success:%s %s %s", 
                        tostring(orderInfo.type), tostring(orderInfo.id), orderInfo.count) , 0, 0)
                end
            end
        end
        reportArr[#reportArr + 1] = string.format("%s-%s-%d-%d %d %s", tostring(orderInfo.type), 
            tostring(orderInfo.id), orderInfo.sellerID, orderInfo.count or 0, orderInfo.feeRate or 0, 
            tostring(orderInfo.source))
    end
    self:DoTradeReport(uin, "obtain", table.concat(reportArr, "##"), curCursor, tarCursor)

    self:CallClient(uin, Protocol.ServerMSGID.WAREHOUSE_OBTAIN_TRADE_RSP, obtainItems)
end

-- 中心服仓库可领取物品
function SWareHouse:OnGCResWareHouseAvailableOrders(uin, data)
    local curCursor = DataPlayersManager:GetWareHouseOrderCursor(uin)
    if curCursor == nil then
        print("SWareHouse:OnGCResWareHouseAvailableOrders No DataPlayers")
        return
    end
    local result = data.result
    local lenOrders = #result.orders
    if lenOrders > 0 then
        -- 有订单
        if (curCursor + lenOrders) ~= result.cursor then
            print("SWareHouse:OnGCResWareHouseAvailableOrders 数据存在异常")
        end
        if curCursor >= result.cursor then
            self:DoTradeReport(uin, "BackAvailableException", "CursorError", curCursor, result.cursor)
            -- 强制更新索引，可能存在数据丢失
            DataPlayersManager:SetWareHouseOrderCursor(uin, result.cursor)
        elseif DataPlayersManager:SetWareHouseOrderCursor(uin, result.cursor) then
            -- 设置游标成功
            self:ObtainOrderItems(uin, result.orders, curCursor, result.cursor)
            print(string.format("SWareHouse:OnGCResWareHouseAvailableOrders:%d->%d", curCursor, result.cursor))
        else
            print("SWareHouse:OnGCResWareHouseAvailableOrders SetWareHouseOrderCursor Failed")
        end
    elseif curCursor == result.cursor then
        print("SWareHouse:OnGCResWareHouseAvailableOrders No Data")
    else
        DataPlayersManager:SetWareHouseOrderCursor(uin, result.cursor)
        print("SWareHouse:OnGCResWareHouseAvailableOrders 索引错乱")
    end
end

-- 中心服仓库新增订单
function SWareHouse:OnGCResWareHouseNotfiyOrder(uin, data)
    local curCursor = DataPlayersManager:GetWareHouseOrderCursor(uin)
    if curCursor == nil then
        print("SWareHouse:OnGCResWareHouseNotfiyOrder No DataPlayers")
        return
    end
    local nextCursor = data.cursor
    if curCursor >= nextCursor then
        -- 可能存在数据丢失
        self:CheckWareHouseItems(uin)
        print("SWareHouse:OnGCResWareHouseNotfiyOrder Need Query")
    elseif (curCursor + 1) < nextCursor then
        -- 存在其它未完成的订单或数据错乱
        self:CheckWareHouseItems(uin)
        print("SWareHouse:OnGCResWareHouseNotfiyOrder Need Query 2")
    else
        -- 设置游标成功
        if DataPlayersManager:SetWareHouseOrderCursor(uin, nextCursor) then
            self:ObtainOrderItems(uin, { data.orderInfo }, curCursor, nextCursor)
            print("SWareHouse:OnGCResWareHouseNotfiyOrder" .. tostring(nextCursor))
        else
            print("SWareHouse:OnGCResWareHouseNotfiyOrder SetWareHouseOrderCursor Failed")
        end
    end
end

-- 玩家移除
function SWareHouse:OnPlayerRemoved(player)
    if self:IsGameCenterAvailable() then
        print("SWareHouse:OnPlayerRemoved")
    else
        print("SWareHouse:OnPlayerRemoved GameCenter Out Of Service")
    end
end

return SWareHouse