-- 说明:不固定滚动控件
-- 日期:2025年1月21日
-- 描述:单位面积占用 
-- 支持:hkj
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperGridView = GFScript("UIModule.UIWidget.SuperGridView")
local SuperItem = GFScript("UIModule.UIWidget.SuperItem")
local UIHelper = GFScript("UIModule.UIHelper")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Utils = GFScript("CoreModule.Utils")
local ItemHelper = GFScript("InventoryModule.ItemHelper")
local ActorManager = GFScript("ActorModule.ActorManager")

local UnFixedGridView = UIClass.New("UnFixedGridView", SuperGridView)

function UnFixedGridView:Constructor()
    self.isDestory = false
    self.itemStatistics = nil
    self.itemTemplates = {}

    self.unFixedItems = {}
    self.unFixedItemsPool = {}

    self.cacheIndexs = {}
end

function UnFixedGridView:Destructor()
    self.isDestory = true
    self.itemTemplates = nil
    -- 销毁显示中的节点
    for _, item in pairs(self.unFixedItems) do
        if self.unFixedLeaveHandler ~= nil then
            self.unFixedLeaveHandler(item)
        end
        item:Destroy()
    end
    self.unFixedItems = {}
    -- 销毁对象池的节点
    for key, list in pairs(self.unFixedItemsPool) do
        for _, item in pairs(list) do
            item:Destroy()
        end
    end
    self.unFixedItemsPool = {}

    if self.unFixedContainer ~= nil then
        self.unFixedContainer:Destroy()
        self.unFixedContainer = nil
    end
    self.cacheIndexs = {}
end

function UnFixedGridView:Update(deltaTime)
    UnFixedGridView.super.Update(self, deltaTime)

    -- 同步两个容器
    if self.unFixedContainer ~= nil and self.content ~= nil then
        self.unFixedContainer.Position = self.content.Position
    end
end

function UnFixedGridView:CreateKey(width, height, isRotated)
    return string.format("%d_%d_%d", width, height, isRotated and 1 or 0)
end

-- 模板资源key
function UnFixedGridView:GetTemplateKey(itemData)
    return self:CreateKey(itemData:GetWidth(), itemData:GetHeight(), itemData.isRotated)
end

-- 回收节点
function UnFixedGridView:RecycleUnFixedItem(linked)
    local firstValue = linked.firstValue
    local unfixedNode = self.unFixedItems[firstValue]
    if unfixedNode == nil then
        return nil
    end
    local templateKey = self:GetTemplateKey(linked.itemData)
    local list = self.unFixedItemsPool[templateKey]
    if list == nil then
        self.unFixedItemsPool[templateKey] = { unfixedNode }
    else
        list[#list + 1] = unfixedNode
    end
    unfixedNode:SetParent(self.UIManager:GetNodePoolNode())
    self.unFixedItems[firstValue] = nil
    return unfixedNode
end

function UnFixedGridView:CreateContainer()
    local container = SandboxNode.New("UIImage")
    container.RenderIndex = 10
    container.Name = "Container"
    container.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    container.Parent = self.viewport
    container.Pivot = Vector2.New(0, 0)
    container.Position  = Vector2.New(0, 0)
    container.Size  = Vector2.New(0, 0)
    container.IsNotifyEventStop = false
    container.ClickPass = false
    container.Active = true

    container.TouchBegin:Connect(function(node, issuccess, mousepos)
        if not self.scrollEnabled then return end
        self:HandlePressUILogic(mousepos)
    end)
    container.TouchEnd:Connect(function(node, issuccess, mousepos)
        if not self.scrollEnabled then return end
        self:HandleReleaseUILogic(mousepos)
    end)

    container.TouchMove:Connect(function(node, issuccess, mousepos)
        if not self.scrollEnabled then return end
        self:HandleMoveUILogic(mousepos)
    end)
    
    container.Click:Connect(function(node, issuccess, mousepos)
        -- UILog:Error("@@@@@@@@@@@@@@@@@@@@@@ content.Click")
    end)
    return container
end

-- 初始化节点
function UnFixedGridView:InitUnFixedItem(item)
    if self.unFixedContainer == nil then
        self.unFixedContainer = self:CreateContainer()
    end 

    item.bindObj.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    item.bindObj.RenderIndex = 1000
    item.bindObj.IsNotifyEventStop = false
    item.bindObj.ClickPass = false
    item:SetParent(self.unFixedContainer)
    item:SetVisible(true)
    item:SetPivot(Vec2.New(0, 0))
    item:SetPosition(Vec2.New(0, 0))
    -- item:SetSize(Vec2.New(itemWidth, itemHeight))
end

-- 显示节点
function UnFixedGridView:AddUnFixedItem(linked)
    local templateKey = self:GetTemplateKey(linked.itemData)

    local itemTemplate = self.itemTemplates[templateKey]
    if not itemTemplate then
        UILog:Error("UnFixedGridView: itemTemplate is nil")
        return nil
    end

    local item = nil
    local list = self.unFixedItemsPool[templateKey]
    if list ~= nil and #list > 0 then
        item = table.remove(list)
    end
    if item == nil then
        item = SuperItem.New()
        item:Init(itemTemplate:Clone(), true)
    end
    self:InitUnFixedItem(item)
    self:SetItemPosition(item, linked.firstValue)
    self.unFixedItems[linked.firstValue] = item
    return item
end

function UnFixedGridView:HandleItemEnter(item)
    UnFixedGridView.super.HandleItemEnter(self, item)

    ----------------添加额外管理的节点------------------
    local linked = item.data.linked
    if linked ~= nil then
        local grides = linked.grides
        local len = #grides
        for i = 1, len, 1 do
            if self.cacheIndexs[grides[i]] == 1 then
                -- 已经显示了
                self.cacheIndexs[item.dataIndex] = 1
                return
            end
        end
        -- 添加节点
        local unFixedItem = self:AddUnFixedItem(linked)
        if unFixedItem ~= nil then
            self.cacheIndexs[item.dataIndex] = 1

            if self.unFixedEnterHandler ~= nil then
                self.unFixedEnterHandler(unFixedItem, item.data)
            end
        end
    else
        self.cacheIndexs[item.dataIndex] = 1
    end
end

-- 添加道具
function UnFixedGridView:AddItem(item)
    -- 注册成功
    if ItemHelper:RegisterGrides(self.itemStatistics, item) then
        local linked = self.itemStatistics:GetItemLinked(item)
        -- 显示节点
        if linked ~= nil then
            local itemData = nil
            local isShowed = false
            local grides = linked.grides
            local len = #grides
            for i = 1, len, 1 do
                local index = grides[i]
                if self.cacheIndexs[index] == 1 then
                    -- 区域已经显示了
                    isShowed = true
                end
                -- 更新数据
                itemData = self.dataList[index]
                if itemData ~= nil then
                    itemData.linked = linked
                end
            end
            if isShowed and (itemData ~= nil) then
                -- 添加节点
                local unFixedItem = self:AddUnFixedItem(linked)
                if unFixedItem ~= nil then
                    if self.unFixedEnterHandler ~= nil then
                        self.unFixedEnterHandler(unFixedItem, itemData)
                    end
                end
            end
        end
        return true
    end
    return false
end

function UnFixedGridView:HandleItemLeave(item)
    -- item SuperItem节点
    UnFixedGridView.super.HandleItemLeave(self, item)

    ----------------清理额外管理的节点------------------
    if self.isDestory then
        -- view 销毁时已提前释放节点
        return
    end
    local dataIndex = item.dataIndex
    self.cacheIndexs[dataIndex] = nil

    local linked = item.data.linked
    if linked ~= nil then
        local grides = linked.grides
        local len = #grides
        for i = 1, len, 1 do
            if self.cacheIndexs[grides[i]] == 1 then
                -- 还有显示部分
                return
            end
        end
        -- 回收节点
        local unFixedItem = self:RecycleUnFixedItem(linked)
        if unFixedItem ~= nil and self.unFixedLeaveHandler ~= nil then
            self.unFixedLeaveHandler(unFixedItem)
        end
    end
end

-- 更新item
function UnFixedGridView:UpdateItem(itemID)
    local linked = self.itemStatistics:GetItemLinkedByID(itemID)
    -- 显示节点
    if linked ~= nil then
        local grides = linked.grides
        local len = #grides
        for i = 1, len, 1 do
            -- 区域已经显示了
            if self.cacheIndexs[grides[i]] == 1 then
                -- 回收节点
                local unFixedItem = self:RecycleUnFixedItem(linked)
                if unFixedItem ~= nil and self.unFixedLeaveHandler ~= nil then
                    self.unFixedLeaveHandler(unFixedItem)
                end
                -- 添加节点
                unFixedItem = self:AddUnFixedItem(linked)
                if unFixedItem ~= nil then
                    if self.unFixedEnterHandler ~= nil then
                        self.unFixedEnterHandler(unFixedItem, itemData)
                    end
                end
                break
            end
        end
    end
end

-- 移除道具
function UnFixedGridView:RemoveItem(itemID)
    -- 记录移除节点信息
    local oLinked = self.itemStatistics:GetItemLinkedByID(itemID)
    if oLinked ~= nil and oLinked.itemData ~= nil then
        -- 清空格子
        if self.itemStatistics:FreeByLinked(oLinked) then
        -- if oLinked.itemData:Free(self.itemStatistics) then
            -- 清空节点
            local grides = oLinked.grides
            local len = #grides
            for i = 1, len, 1 do
                -- 更新数据
                local itemData = self.dataList[grides[i]]
                if itemData ~= nil then
                    itemData.linked = nil
                end
            end
            -- 回收节点
            local unFixedItem = self:RecycleUnFixedItem(oLinked)
            if unFixedItem ~= nil and self.unFixedLeaveHandler ~= nil then
                self.unFixedLeaveHandler(unFixedItem)
            end
        end
    end
end

function UnFixedGridView:RegisterTemplate(width, height, tempNode, rotatedTempNode)
    self.itemTemplates[self:CreateKey(width, height, false)] = tempNode
    if rotatedTempNode ~= nil then
        self.itemTemplates[self:CreateKey(width, height, true)] = rotatedTempNode
    end
end

function UnFixedGridView:RegisterEnterHandler(enterHandler)
    self.unFixedEnterHandler = enterHandler
end

function UnFixedGridView:RegisterLeaveHandler(leaveHandler)
    self.unFixedLeaveHandler = leaveHandler
end

function UnFixedGridView:ShowTradeInventoryView(items)
    local itemStatistics = ItemHelper:NewStatistics(items, 9, 20)
    self.itemStatistics = itemStatistics

    local rowNum = itemStatistics:GetRowNum()
    local rowSize = itemStatistics:GetRowSize()
    local linkedData = itemStatistics:GetLinkedData()

    local tempPool = Utils:GetUINode("UI_Template.Trade.temp")
    self:RegisterTemplate(1, 1, tempPool.GideItem11)
    self:RegisterTemplate(2, 1, tempPool.GideItem21, tempPool.GideItem12)
    self:RegisterTemplate(2, 2, tempPool.GideItem22)
    self:RegisterTemplate(3, 2, tempPool.GideItem32, tempPool.GideItem23)
    self:RegisterTemplate(3, 3, tempPool.GideItem33)

    self:SetPadding(5, 5, 0, 0)
    self:SetSpacing(0, 0)
    self:SetItemSize(70, 70)
    self:SetLineCount(rowSize)
    self:SetItemTemplate(tempPool.GideItem)
    self:SetLayoutOptions("TopLeft", "Vertical")

    local grideDatas = {}
    for i = 1, rowNum, 1 do
        local base = (i - 1) * rowSize
        for j = 1, rowSize, 1 do
            local dataIndex = base + j            
            grideDatas[dataIndex] = { dataIndex=dataIndex, linked=linkedData[dataIndex] }
        end
    end
    self:SetDataList(grideDatas)
end

return UnFixedGridView