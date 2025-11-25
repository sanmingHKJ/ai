-- 说明:流式布局控件
-- 日期:2025年3月31日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIUtils = GFScript("UIModule.UIUtils")
local SuperFlowLayout = UIClass.New("SuperFlowLayout", UIWidget)

function SuperFlowLayout:Constructor()
    self.autoId = 0
    self.items = {}
    self.layoutStates = {}
end

--添加布局项
--@param item 布局项
--@param layoutOrigin 布局起点 LeftTop, CenterTop, RightTop, LeftCenter, CenterCenter, RightCenter, LeftBottom, CenterBottom, RightBottom
--@param layoutDirection 布局方向 left,right,top,bottom
--@param order 排序
--@param offset 偏移量
--@param spacing 间距
--@param changedCallback 变化回调
function SuperFlowLayout:AddItem(item, layoutOrigin, layoutDirection, pivot, offset, size, order, updateCallback)
    if not self.items[layoutOrigin] then
        self.items[layoutOrigin] = {}
    end
    self.autoId = self.autoId + 1
    local item = {
        id = self.autoId,
        item = item,
        layoutOrigin = layoutOrigin,
        layoutDirection = layoutDirection,
        pivot = pivot,
        order = order,
        offset = offset,
        size = size,
        visible = true,
        updateCallback = updateCallback,
    }
    table.insert(self.items[layoutOrigin], item)
    self:SortItems(layoutOrigin)
    return self.autoId
end

--移除布局项
--@param id 布局项id
function SuperFlowLayout:RemoveItem(id)
    for layoutOrigin, items in pairs(self.items) do
        for i, item in ipairs(items) do
            if item.id == id then
                table.remove(items, i)
                break
            end
        end
    end
end

--排序布局项
--@param layoutOrigin 布局起点
function SuperFlowLayout:SortItems(layoutOrigin)
    if not self.items[layoutOrigin] then
        return
    end
    table.sort(self.items[layoutOrigin], function(a, b)
        return a.order < b.order
    end)
end

--设置布局项大小
--@param id 布局项id
--@param size 大小
function SuperFlowLayout:SetItemSize(id, size)
    for i, item in ipairs(self.items) do
        if item.id == id then
            item.size = size
            self:OnRefresh()
            break
        end
    end
end

--设置布局项可见性
--@param id 布局项id
--@param visible 可见性
function SuperFlowLayout:SetItemVisible(id, visible)
    for i, item in ipairs(self.items) do
        if item.id == id then
            item.visible = visible
            self:OnRefresh()
            break
        end
    end
end

--设置布局项排序
--@param id 布局项id
--@param order 排序
function SuperFlowLayout:SetItemOrder(id, order)
    for i, item in ipairs(self.items) do
        if item.id == id then
            item.order = order
            self:SortItems(item.layoutOrigin)
            self:OnRefresh()
            break
        end
    end
end

--设置布局项偏移量
--@param id 布局项id
--@param offset 偏移量
function SuperFlowLayout:SetItemOffset(id, offset)
    for i, item in ipairs(self.items) do
        if item.id == id then
            item.offset = offset
            self:OnRefresh()
            break
        end
    end
end

function SuperFlowLayout:SetItemUpdateCallback(id, updateCallback)
    for i, item in ipairs(self.items) do
        if item.id == id then
            item.updateCallback = updateCallback
            self:OnRefresh()
            break
        end
    end
end

function SuperFlowLayout:UpdateLayout(layoutOrigin)
    if not self.items[layoutOrigin] then
        return
    end
    local layoutState = self.layoutStates[layoutOrigin]
    if not layoutState then
        layoutState = {}
    end
    
    local anchor = UIUtils:LayoutOriginToAnchor(layoutOrigin)
    local rect = UIUtils:GetScreenRect(self.bindObj)
    local anchorPoint = rect:GetAnchorPoint(anchor)

    layoutState.left = anchorPoint:Clone()
    layoutState.top = anchorPoint:Clone()
    layoutState.right = anchorPoint:Clone()
    layoutState.bottom = anchorPoint:Clone()


    local items = self.items[layoutOrigin]
    for i, item in ipairs(items) do
        if item.visible then
            local prevPos = layoutState[item.layoutDirection]

            local newPos = prevPos + item.offset

            if item.layoutDirection == "left" or item.layoutDirection == "top" then
                newPos = newPos - item.size * item.pivot
            elseif item.layoutDirection == "right" or item.layoutDirection == "bottom" then
                newPos = newPos + item.size * item.pivot
            end

            if item.updateCallback then
                item.updateCallback(newPos, item.size)
            end

            layoutState[item.layoutDirection] = newPos
        end
    end




    self.layoutStates[layoutOrigin] = layoutState
end

--刷新布局
function SuperFlowLayout:OnRefresh()
    for layoutOrigin, _ in pairs(self.items) do
        self:UpdateLayout(layoutOrigin)
    end
end




return SuperFlowLayout
