--brief 数据提供者
--Date:2024年2月23日
--Author:hkj
--Copyright (c) 2024 迷你创想. All rights reserved.
local CloudService = game:GetService("CloudService")
local DataKey = "fkgc_mini_player_%d_other_data"

local DataPlayersManager = {}
DataPlayersManager.playerCache = {}

function DataPlayersManager:Init()
    coroutine.work(function()
        while true do
            local ok, errmsg = xpcall(function()
                for uin, extendData in pairs(self.playerCache) do
                    self:SaveExtendData(uin, false)
                end
            end, debug.traceback)
            if not ok then
                print("DataPlayersManager Save Error: " .. tostring(errmsg))
            end
            wait(10)
        end
    end)
end

--注册数据提供函数
function DataPlayersManager:GetDataKey(uin)
    return string.format(DataKey, uin)
end

function DataPlayersManager:GetExtendData(uin)
    local cacheData = self.playerCache[uin]
    if cacheData ~= nil then
        return cacheData
    end

    local ok, value = CloudService:GetTableOrEmpty(self:GetDataKey(uin))
    if ok then
        self.playerCache[uin] = value
        value.isMarkDirty = true
        value.isChanged = false
    else
        self.playerCache[uin] = { isMarkDirty=false, TradeMarkArr={}, isChanged=false }
    end
    return self.playerCache[uin]
end

-- 设置仓库订单游标
function DataPlayersManager:SetWareHouseOrderCursor(uin, cursor)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil then
        extendData.isChanged = true
        extendData.WareHouseOrderCursor = cursor
        print("DataPlayersManager:SetWareHouseOrderCursor:" .. tostring(cursor))
        return true
    else
        print("DataPlayersManager:SetWareHouseOrderCursor Error")
    end
    return false
end

-- 获取仓库订单游标
function DataPlayersManager:GetWareHouseOrderCursor(uin)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil then
        return extendData.WareHouseOrderCursor or 0
    end
    return nil
end

-- 经营数据
function DataPlayersManager:GetReportData(uin)
    local extendData = self:GetExtendData(uin)
    local data = { income=0, tradeCount=0, tradeSellCount=0 }
    if extendData ~= nil then
        data.income = extendData.tradeIncome
        data.tradeCount = extendData.tradeCount
        data.tradeSellCount = extendData.tradeSellCount
    end
    return data
end

function DataPlayersManager:IsMarkDirty(uin)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil then
        if extendData.isMarkDirty then
            if extendData.TradeMarkArr == nil or #extendData.TradeMarkArr <= 0 then
                extendData.isMarkDirty = false
            end
        end
        return extendData.isMarkDirty
    end
    return false
end

-- 更新收藏订单号
function DataPlayersManager:UpdateTradeMarks(uin, markArr)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil then
        extendData.isMarkDirty = false
        extendData.TradeMarkArr = markArr
        extendData.isChanged = true
        print("DataPlayersManager:SetTradeMarks")
        return true
    else
        print("DataPlayersManager:SetTradeMarks Error")
    end
    return false
end

-- 取消收藏订单号
function DataPlayersManager:CancelMark(uin, ID)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil then
        local markArr = extendData.TradeMarkArr
        if markArr ~= nil and #markArr > 0 then
            for i, id in pairs(markArr) do
                if id == ID then
                    table.remove(markArr, i)
                    extendData.isChanged = true
                    return true
                end
            end
        end
    end
    return false
end

-- 添加收藏订单号
function DataPlayersManager:AddMark(uin, ID)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil and ID ~= nil then
        local markArr = extendData.TradeMarkArr
        -- 已有收藏数据
        if markArr ~= nil then
            local len = #markArr
            if len > 0 and len < 20 then
                for i, id in pairs(markArr) do
                    if id == ID then
                        return false
                    end
                end
            end
            markArr[len + 1] = ID
            return true
        else
            extendData.TradeMarkArr = { ID }
            extendData.isChanged = true
            return true
        end
    end
    return false
end

-- 获取交易行收藏订单号
function DataPlayersManager:GetTradeMarks(uin)
    local extendData = self:GetExtendData(uin)
    if extendData ~= nil then
        return extendData.TradeMarkArr or {}
    end
    return {}
end

function DataPlayersManager:SaveExtendData(uin, force)
    local extendData = self.playerCache[uin]
    if extendData ~= nil then
        if force or extendData.isChanged then
            CloudService:SetTable(self:GetDataKey(uin), extendData)
        end
        extendData.isChanged = false
    end
end

-- 玩家退出
function DataPlayersManager:OnPlayerRemoved(uin)
    self:SaveExtendData(uin, true)
    self.playerCache[uin] = nil
end

-- 中途保存，防止数据丢失
function DataPlayersManager:TrySavePlayer(uin)
    self:SaveExtendData(uin, false)
end

DataPlayersManager:Init()

return DataPlayersManager