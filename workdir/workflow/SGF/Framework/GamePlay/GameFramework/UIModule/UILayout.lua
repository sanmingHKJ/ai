-- 说明:UI布局
-- 日期:2025年2月14日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UILog = GFScript("UIModule.UILog")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Rect = GFScript("UIModule.UIMath.Rect")
local UIDefines = GFScript("UIModule.UIDefines")

local UILayout = {}

--调整布局
--layoutRect: 布局矩形，是一个Rect，表示布局的矩形范围
--layoutItems: 布局项, 是一个Vec2的数组, 每个元素表示一个大小
--lineCount: 行数，如果为0，则表示自动计算行数, -1表示不换行
--layoutOrigin: 布局起点
--layoutDirection: 布局方向
--layoutReverse: 是否反转布局
--layoutPadding: 布局内边距
--layoutSpacing: 布局间距
--layoutCallback: 布局回调，回调参数:目标索引，位置，大小
function UILayout:AdjustLayout(layoutRect, layoutItems, lineCount,
    layoutOrigin, layoutDirection, 
    layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    if layoutDirection == "Horizontal" then
        self:AdjustHorizontalLayout(layoutRect, layoutItems, lineCount, layoutOrigin, layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    else
        self:AdjustVerticalLayout(layoutRect, layoutItems, lineCount, layoutOrigin, layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    end
end

--水平布局
function UILayout:AdjustHorizontalLayout(layoutRect, layoutItems, lineCount,
    layoutOrigin, 
    layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    
    if not layoutItems or #layoutItems == 0 then return end

    layoutOrigin = layoutOrigin or "LeftTop"
    layoutReverse = layoutReverse or false
    layoutPadding = layoutPadding or {left = 0, right = 0, top = 0, bottom = 0}
    layoutSpacing = layoutSpacing or {x = 0, y = 0}
    lineCount = lineCount or 0
    
    layoutRect:ApplyPadding(layoutPadding)
    -- 计算可用空间
    local availableWidth = layoutRect.width
    local availableHeight = layoutRect.height
    
    -- 根据layoutOrigin确定初始位置
    local startX = 0
    local startY = 0
    local currentX = 0
    local currentY = 0
    local dirX = 1
    local dirY = 1
    if string.find(layoutOrigin, "Bottom") then
        startY = layoutRect.height
        currentY = layoutRect.height
        dirY = -1
    end
    if string.find(layoutOrigin, "Right") then
        startX = layoutRect.width
        currentX = layoutRect.width
        dirX = -1
    end

    local lineHeight = 0
    local itemsInCurrentLine = 0
    
    -- 存储每行的项目，用于对齐
    local lineItems = {}
    local currentLineItems = {}
    local finalResultItems = {}
    
    local xInCurrentLine = 0
    for index, targetSize in ipairs(layoutItems) do
        local itemWidth = targetSize.x
        local itemHeight = targetSize.y
        
        -- 检查是否需要换行
        if (lineCount > 0 and itemsInCurrentLine >= lineCount) or 
           (lineCount == 0 and xInCurrentLine + itemWidth > availableWidth and itemsInCurrentLine > 0) then
            -- 处理当前行的对齐
            -- self:AlignLineItems(currentLineItems, lineHeight, availableWidth, layoutOrigin, "Horizontal", layoutSpacing, finalResultItems)
            self:UpdateItems(currentLineItems, finalResultItems)
            -- 换行
            currentX = startX
            xInCurrentLine = 0
            currentY = currentY + (lineHeight + layoutSpacing.y) * dirY

            lineHeight = 0
            itemsInCurrentLine = 0
            -- 保存行信息
            if #currentLineItems > 0 then
                table.insert(lineItems, currentLineItems)
                currentLineItems = {}
            end
        end
        
        -- 记录当前项目位置和大小
        local position = Vec2.New(currentX, currentY)
        if dirX == -1 then
            position.x = currentX - itemWidth
        end
        if dirY == -1 then
            position.y = currentY - itemHeight
        end
        local size = Vec2.New(itemWidth, itemHeight)
        
        -- 记录当前行的最大高度
        lineHeight = math.max(lineHeight, itemHeight)
        
        -- 更新位置
        currentX = currentX + (itemWidth + layoutSpacing.x) * dirX
        xInCurrentLine = xInCurrentLine + itemWidth + layoutSpacing.x
        
        itemsInCurrentLine = itemsInCurrentLine + 1
        table.insert(currentLineItems, {
            index = index,
            position = position,
            size = size
        })
    end
    
    -- 处理最后一行的对齐
    if #currentLineItems > 0 then
        -- self:AlignLineItems(currentLineItems, lineHeight, availableWidth, layoutOrigin, "Horizontal", layoutSpacing, finalResultItems)
        self:UpdateItems(currentLineItems, finalResultItems)
        table.insert(lineItems, currentLineItems)
    end
    
    local itemsRect = self:CalculateItemsRect(finalResultItems)
    
    -- 应用反向布局
    if layoutReverse then
        self:ApplyReverseLayout(lineItems, layoutRect, "Horizontal", finalResultItems)
    end
    
    if string.find(layoutOrigin, "Center") then
        self:HorizontalCenterItems(finalResultItems, layoutRect, itemsRect)
    end
    -- 让items垂直居中对齐
    if string.find(layoutOrigin, "Middle") then
        self:VerticalCenterItems(finalResultItems, layoutRect, itemsRect)
    end

    --应用内边距偏移
    for _, item in pairs(finalResultItems) do
        item.position = item.position + Vec2.New(layoutPadding.left, layoutPadding.top)
    end

    -- 调用布局回调
    for _, item in pairs(finalResultItems) do
        if layoutCallback then
            layoutCallback(item.index, item.position, item.size)
        end
    end
end

--垂直布局
function UILayout:AdjustVerticalLayout(layoutRect, layoutItems, lineCount,
    layoutOrigin, 
    layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    
    if not layoutItems or #layoutItems == 0 then return end

    layoutOrigin = layoutOrigin or "LeftTop"
    layoutReverse = layoutReverse or false
    layoutPadding = layoutPadding or {left = 0, right = 0, top = 0, bottom = 0}
    layoutSpacing = layoutSpacing or {x = 0, y = 0}
    lineCount = lineCount or 0
    
    layoutRect:ApplyPadding(layoutPadding)
    -- 计算可用空间
    local availableWidth = layoutRect.width
    local availableHeight = layoutRect.height
    
    -- 根据layoutOrigin确定初始位置
    local startX = 0
    local startY = 0
    local currentX = 0
    local currentY = 0
    local dirX = 1
    local dirY = 1
    if string.find(layoutOrigin, "Bottom") then
        startY = layoutRect.height
        currentY = layoutRect.height
        dirY = -1
    end
    if string.find(layoutOrigin, "Right") then
        startX = layoutRect.width
        currentX = layoutRect.width
        dirX = -1
    end

    local lineWidth = 0
    local itemsInCurrentLine = 0
    
    -- 存储每列的项目，用于对齐
    local lineItems = {}
    local currentLineItems = {}
    local finalResultItems = {}
    
    local yInCurrentLine = 0
    for index, targetSize in ipairs(layoutItems) do
        local itemWidth = targetSize.x
        local itemHeight = targetSize.y
        
        -- 检查是否需要换列
        if (lineCount > 0 and itemsInCurrentLine >= lineCount) or 
           (lineCount == 0 and yInCurrentLine + itemHeight > availableHeight and itemsInCurrentLine > 0) then
            -- 处理当前列的对齐
            self:UpdateItems(currentLineItems, finalResultItems)
            -- 换列
            currentY = startY
            yInCurrentLine = 0
            currentX = currentX + (lineWidth + layoutSpacing.x) * dirX

            lineWidth = 0
            itemsInCurrentLine = 0
            -- 保存列信息
            if #currentLineItems > 0 then
                table.insert(lineItems, currentLineItems)
                currentLineItems = {}
            end
        end
        
        -- 记录当前项目位置和大小
        local position = Vec2.New(currentX, currentY)
        if dirX == -1 then
            position.x = currentX - itemWidth
        end
        if dirY == -1 then
            position.y = currentY - itemHeight
        end
        local size = Vec2.New(itemWidth, itemHeight)
        
        -- 记录当前列的最大宽度
        lineWidth = math.max(lineWidth, itemWidth)
        
        -- 更新位置
        currentY = currentY + (itemHeight + layoutSpacing.y) * dirY
        yInCurrentLine = yInCurrentLine + itemHeight + layoutSpacing.y
        
        itemsInCurrentLine = itemsInCurrentLine + 1
        table.insert(currentLineItems, {
            index = index,
            position = position,
            size = size
        })
    end
    
    -- 处理最后一列的对齐
    if #currentLineItems > 0 then
        self:UpdateItems(currentLineItems, finalResultItems)
        table.insert(lineItems, currentLineItems)
    end
    
    local itemsRect = self:CalculateItemsRect(finalResultItems)
    
    -- 应用反向布局
    if layoutReverse then
        self:ApplyReverseLayout(lineItems, layoutRect, "Vertical", finalResultItems)
    end
    
    if string.find(layoutOrigin, "Center") then
        self:HorizontalCenterItems(finalResultItems, layoutRect, itemsRect)
    end
    -- 让items水平居中对齐
    if string.find(layoutOrigin, "Middle") then
        self:VerticalCenterItems(finalResultItems, layoutRect, itemsRect)
    end

    --应用内边距偏移
    for _, item in pairs(finalResultItems) do
        item.position = item.position + Vec2.New(layoutPadding.left, layoutPadding.top)
    end

    -- 调用布局回调
    for _, item in pairs(finalResultItems) do
        if layoutCallback then
            layoutCallback(item.index, item.position, item.size)
        end
    end
end

function UILayout:UpdateItems(sourceItems, targetItems)
    for _, item in ipairs(sourceItems) do
        targetItems[item.index] = item
    end
end

--计算items的矩形范围
function UILayout:CalculateItemsRect(items)
    if #items == 0 then return end

    local minX = items[1].position.x
    local minY = items[1].position.y
    local maxX = items[1].position.x + items[1].size.x
    local maxY = items[1].position.y + items[1].size.y

    for _, item in ipairs(items) do
        minX = math.min(minX, item.position.x)
        minY = math.min(minY, item.position.y)
        maxX = math.max(maxX, item.position.x + item.size.x)
        maxY = math.max(maxY, item.position.y + item.size.y)
    end

    return Rect.New(minX, minY, maxX - minX, maxY - minY)
end

--让items水平居中对齐
function UILayout:HorizontalCenterItems(items, layoutRect, itemsRect)
    if #items == 0 then return end

    local itemCenter = itemsRect:GetCenter()
    local layoutCenter = layoutRect.width / 2

    for _, item in ipairs(items) do
        item.position.x = layoutCenter + (item.position.x - itemCenter.x)
    end
end

--让items垂直居中对齐
function UILayout:VerticalCenterItems(items, layoutRect, itemsRect)
    if #items == 0 then return end

    local itemCenter = itemsRect:GetCenter()
    local layoutCenter = layoutRect.height / 2

    for _, item in ipairs(items) do
        item.position.y = layoutCenter + (item.position.y - itemCenter.y)
    end
end

function UILayout:AlignLineItems(items, lineSize, availableSize, layoutOrigin, layoutDirection, layoutSpacing, finalResultItems)
    if #items == 0 then return end
    
    -- 计算主轴方向的对齐偏移
    local totalSpacing = (#items - 1) * (layoutDirection == "Horizontal" and layoutSpacing.x or layoutSpacing.y)
    local totalItemSize = 0
    for _, item in ipairs(items) do
        totalItemSize = totalItemSize + (layoutDirection == "Horizontal" and item.size.x or item.size.y)
    end
    
    local mainAxisOffset = 0
    if string.find(layoutOrigin, "Center") then
        mainAxisOffset = (availableSize - totalItemSize - totalSpacing) / 2
    elseif (layoutDirection == "Horizontal" and string.find(layoutOrigin, "Right")) or
           (layoutDirection == "Vertical" and string.find(layoutOrigin, "Bottom")) then
        mainAxisOffset = availableSize - totalItemSize - totalSpacing
    end

    -- 计算交叉轴方向的对齐偏移
    local crossAxisOffset = 0
    if layoutDirection == "Horizontal" then
        if string.find(layoutOrigin, "Center") then
            crossAxisOffset = (lineSize - items[1].size.y) / 2
        elseif string.find(layoutOrigin, "Bottom") then
            crossAxisOffset = lineSize - items[1].size.y
        end
    else
        if string.find(layoutOrigin, "Center") then
            crossAxisOffset = (lineSize - items[1].size.x) / 2
        elseif string.find(layoutOrigin, "Right") then
            crossAxisOffset = lineSize - items[1].size.x
        end
    end
    
    -- 应用偏移
    for _, item in ipairs(items) do
        local pos = item.position
        if layoutDirection == "Horizontal" then
            item.position = Vec2.New(
                pos.x + (mainAxisOffset > 0 and mainAxisOffset or 0),
                pos.y + (crossAxisOffset > 0 and crossAxisOffset or 0)
            )
        else
            item.position = Vec2.New(
                pos.x + (crossAxisOffset > 0 and crossAxisOffset or 0),
                pos.y + (mainAxisOffset > 0 and mainAxisOffset or 0)
            )
        end
    end

    
    -- 调用布局回调
    for _, item in ipairs(items) do
        finalResultItems[item.index] = item
    end
end

function UILayout:ApplyReverseLayout(lineItems, layoutRect, layoutDirection, finalResultItems)
    if layoutDirection == "Horizontal" then
        -- 水平反转
        local totalWidth = layoutRect.width
        for _, line in ipairs(lineItems) do
            for _, item in ipairs(line) do
                local pos = item.position
                item.position = Vec2.New(
                    totalWidth - pos.x - item.size.x,
                    pos.y
                )
                finalResultItems[item.index] = item
            end
        end
    else
        -- 垂直反转
        local totalHeight = layoutRect.height
        for _, line in ipairs(lineItems) do
            for _, item in ipairs(line) do
                local pos = item.position
                item.position = Vec2.New(
                    pos.x, 
                    totalHeight - pos.y - item.size.y
                )
                finalResultItems[item.index] = item
            end
        end
    end
end

return UILayout

