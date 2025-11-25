-- 说明:滚动控件
-- 日期:2025年1月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperScrollView = GFScript("UIModule.UIWidget.SuperScrollView")
local SuperItem = GFScript("UIModule.UIWidget.SuperItem")
local UIUtils = GFScript("UIModule.UIUtils")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local SuperGridView = UIClass.New("SuperGridView", SuperScrollView)

function SuperGridView:Constructor()
    self.itemTemplate = nil  --模板节点
    self.dataList = {}      --数据列表
    self.lineCount = 1  --换行数量
    self.itemWidth = 0  --item宽度
    self.itemHeight = 0 --item高度
    
    self.itemEnterCallback = nil  --item进入可视区域回调
    self.itemLeaveCallback = nil  --item离开可视区域回调
    
    self.itemPool = {}       --item对象池
    self.activeItems = {}    --当前激活的item列表
    
    --数据是否反序
    self.dataReverse = false

    --布局起点：TopLeft(左上), TopCenter(顶部中心), TopRight(右上), 
    --MiddleLeft(左中), MiddleCenter(中心), MiddleRight(右中),
    --BottomLeft(左下), BottomCenter(底部中心), BottomRight(右下)
    self.layoutOrigin = "TopLeft"

    --布局方向：Horizontal(水平) 或 Vertical(垂直)
    self.layoutDirection = "Horizontal"

    --是否反转布局
    self.layoutReverse = false
    --内容边距
    self.padding = {left = 0, right = 0, top = 0, bottom = 0}
    --项目间距
    self.spacing = {x = 0, y = 0}

    -- 当前可见范围的起始索引
    self.startIndex = 1
    -- 当前可见范围的结束索引
    self.endIndex = 1
    
    self:ForceUpdate()
end

function SuperGridView:Destructor()
    -- 清理所有items
    for _, item in ipairs(self.activeItems) do
        self:RecycleItem(item)
    end
    for _, item in ipairs(self.itemPool) do
        item:Destroy()
    end
    
    self.activeItems = {}
    self.itemPool = {}
    self.dataList = {}
end

--[[
    初始化滚动视图
    @param bindObj: 绑定的UI对象
]]
function SuperGridView:Init(bindObj)
    if bindObj.LineGap then
        self.spacing.y = bindObj.LineGap
    end
    if bindObj.ColumnGap then
        self.spacing.x = bindObj.ColumnGap
    end
    if bindObj.Padding then
        self.padding.left = bindObj.Padding.X
        self.padding.right = bindObj.Padding.Y
        self.padding.top = bindObj.Padding.Z
        self.padding.bottom = bindObj.Padding.W
    end

    if not SuperGridView.super.Init(self, bindObj) then
        return false
    end

    
    self.bindObj.ColumnCount = 0
    self.bindObj.LineCount = 0
    self.bindObj.LineGap = 0
    self.bindObj.ColumnGap = 0
    self.bindObj.AutoResizeItem = false
    
    return true
end


--[[
    设置内容边距
    @param left: 左边距
    @param right: 右边距
    @param top: 上边距
    @param bottom: 下边距
]]
function SuperGridView:SetPadding(left, right, top, bottom)
    self.padding.left = left or 0
    self.padding.right = right or 0
    self.padding.top = top or 0
    self.padding.bottom = bottom or 0
    self.isDirty = true
end

--[[
    设置项目间距
    @param x: 水平间距
    @param y: 垂直间距
]]
function SuperGridView:SetSpacing(x, y)
    self.spacing.x = x or 0
    self.spacing.y = y or 0
    self.isDirty = true
end

--设置行数
function SuperGridView:SetLineCount(count)
    self.lineCount = count
    self.isDirty = true
end

--获取行数
function SuperGridView:GetLineCount()
    return self.lineCount
end


function SuperGridView:UpdateScrollView()
    self:UpdateVisibleItems()
end

--[[
    计算内容大小，考虑了内边距和间距
]]
function SuperGridView:UpdateContentSize()
    local itemWidth, itemHeight = self:GetDerivedItemSize()
    if self.scrollDirection == "Horizontal" then
        -- 水平滚动：计算需要多少列来容纳所有项目
        local cols = math.ceil(#self.dataList / self.lineCount)
        self.contentSize.width = cols * itemWidth + (cols - 1) * self.spacing.x + self.padding.left + self.padding.right
        self.contentSize.height = self.lineCount * itemHeight + (self.lineCount - 1) * self.spacing.y + self.padding.top + self.padding.bottom
    else -- Vertical
        -- 垂直滚动：计算需要多少行来容纳所有项目
        local rows = math.ceil(#self.dataList / self.lineCount)
        self.contentSize.width = self.lineCount * itemWidth + (self.lineCount - 1) * self.spacing.x + self.padding.left + self.padding.right
        self.contentSize.height = rows * itemHeight + (rows - 1) * self.spacing.y + self.padding.top + self.padding.bottom
    end

    if self.followContentSize then
        local minWidth = itemWidth + self.padding.left + self.padding.right
        local minHeight = itemHeight + self.padding.top + self.padding.bottom
        self:SetContentSize(math.max(self.contentSize.width, minWidth), math.max(self.contentSize.height, minHeight))
    else
        self:SetContentSize(math.max(self.contentSize.width, self.viewportWidth), math.max(self.contentSize.height, self.viewportHeight))
    end
end

--[[
    从对象池中获取一个item
    @return: SuperItem实例
]]
function SuperGridView:GetItemFromPool()
    if not self.itemTemplate then
        UILog:Error("GetItemFromPool: itemTemplate is nil")
        return nil
    end
    local itemWidth, itemHeight = self:GetDerivedItemSize()
    local function InitItem(item)   
        item.bindObj.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        item.bindObj.IsNotifyEventStop = false
        item.bindObj.ClickPass = false
        item:SetParent(self.content)
        item:SetVisible(true)
        item:SetPivot(Vec2.New(0, 0))
        item:SetPosition(Vec2.New(0, 0))
        item:SetSize(Vec2.New(itemWidth, itemHeight))
    end
    if #self.itemPool > 0 then
        -- 从对象池中获取一个item
        local item = table.remove(self.itemPool)
        if not item then
            -- 如果对象池中没有item，则创建一个新的item
            item = SuperItem.New()
            item:Init(self.itemTemplate:Clone(), true)
            InitItem(item)
        else
            InitItem(item)
        end
        return item
    end
    -- 如果对象池中没有item，则创建一个新的item
    local item = SuperItem.New()
    item:Init(self.itemTemplate:Clone(), true)
    InitItem(item)
    return item
end

--[[
    回收item到对象池
    @param item: 要回收的item对象
]]
function SuperGridView:RecycleItem(item)
    if item then
        self:HandleItemLeave(item)
        -- 清理父节点关系
        item:SetParent(self.UIManager:GetNodePoolNode())
        table.insert(self.itemPool, item)
    end
end

--[[
    更新可见item列表，回收不可见的item并创建新的可见item
]]
function SuperGridView:UpdateVisibleItems(force)
    local startIndex, endIndex = self:CalculateVisibleRange()

    force = (force == nil and false or force)
    if force then
        for index, item in ipairs(self.activeItems) do
            self:UpdateItem(item.dataIndex)
        end
        return
    end
    
    -- 回收不可见的items
    for i = #self.activeItems, 1, -1 do
        local item = self.activeItems[i]
        if item.dataIndex < startIndex or item.dataIndex > endIndex then
            self:RecycleItem(item)
            table.remove(self.activeItems, i)
        end
    end
    
    -- 创建新的可见items
    for i = startIndex, endIndex do
        if i <= #self.dataList then
            local found = false
            for _, item in ipairs(self.activeItems) do
                if item.dataIndex == i then
                    found = true
                    break
                end
            end
            
            if not found then
                local item = self:GetItemFromPool()
                if item then
                    item:SetName("Item" .. i)
                    item.dataIndex = i
                    item.posX = ((i - 1) % self.lineCount) + 1
                    item.posY = math.floor((i - 1) / self.lineCount) + 1
                    
                    -- 根据dataReverse决定数据索引
                    local dataIndex = i
                    if self.dataReverse then
                        dataIndex = #self.dataList - i + 1
                    end
                    item.data = self.dataList[dataIndex]
                    
                    self:SetItemPosition(item, i)
                    self:HandleItemEnter(item)
                    table.insert(self.activeItems, item)
                end
            end
        end
    end

    self.startIndex = startIndex
    self.endIndex = endIndex
    
    self.isDirty = false
end

function SuperGridView:SetItemTemplate(itemTemplate)
    -- 应该添加参数检查
    if not itemTemplate then
        UILog:Warn("SetTemplate: itemTemplate is nil")
        return
    end 
    self.itemTemplate = itemTemplate
    self.itemTemplate.Visible = false
    if self.itemTemplate then
        self.itemWidth = self.itemTemplate.Size.X
        self.itemHeight = self.itemTemplate.Size.Y
    end
end

--[[
    设置数据
    @param dataList: 数据列表
    @param dataKey: 数据键
    @param silent: 是否不更新UI
]]
function SuperGridView:SetDataList(dataList, dataKey, silent)
    silent = (silent == nil and false or silent)
    self.dataList = dataList or {}
    self.dataKey = dataKey or "Id"

    self.dataMap = {}
    for i, v in ipairs(self.dataList) do
        if type(v) == "table" then
            local key = v[self.dataKey]
            if key then
                self.dataMap[key] = v
            end
        end
    end

    if not silent then
        -- 回收所有激活的items
        for _, item in ipairs(self.activeItems) do
            self:RecycleItem(item)
        end
        self.activeItems = {}

        -- 重置滚动相关状态
        self.isOverscrolling = false
        self.bounceBackProgress = 0
        self.currentPosition = {x = 0, y = 0}
        self.lastScrollPosition = {x = 0, y = 0}
        
        -- 重新计算内容大小并重置位置
        self:UpdateContentSize()
        self:SetContentPosition(0, 0)
        
        
        self:ForceUpdate()
    end
end

--[[
    更新指定key的数据
    @param key: 数据键
    @param data: 数据
]]
function SuperGridView:UpdateDataByKey(key, data)
    if not self.dataMap then
        return
    end
    local index = self:FindDataIndexByKey(key)
    if index then
        self.dataList[index] = data
        self.dataMap[key] = data
        self:UpdateItem(index)
    end
end

--[[
    根据key获取数据
    @param key: 数据键
    @return: 数据
]]
function SuperGridView:GetDataByKey(key)
    if not self.dataMap then
        return
    end
    return self.dataMap[key]
end

--[[
    根据key查找数据索引
    @param key: 数据键
    @return: 数据索引
]]
function SuperGridView:FindDataIndexByKey(key)
    if not self.dataMap then
        return
    end
    for i, v in ipairs(self.dataList) do
        if v[self.dataKey] == key then
            return i
        end
    end
    return nil
end

--[[
    按顺序遍历数据列表
]]
function SuperGridView:ForeachDataList(callback)
    for i, v in ipairs(self.dataList) do
        callback(v)
    end
end

--[[
    获取数据列表
]]
function SuperGridView:GetDatas()
    return self.dataList
end

--[[
    获取数据数量
]]
function SuperGridView:GetDataNum()
    return #self.dataList
end

--[[
    计算项目位置
    @param item: 项目对象
    @param index: 数据索引
    @return: 项目位置
]]
function SuperGridView:CalculateItemPosition(item, index)
    
    if not item then return end

    local itemWidth, itemHeight = self:GetDerivedItemSize()
    
    local row, col
    local x, y
    
    -- 根据滚动方向决定布局方式
    if self.scrollDirection == "Horizontal" then
        -- 水平滚动：先从左到右填充，达到 lineCount 后换行
        row = (index - 1) % self.lineCount
        col = math.floor((index - 1) / self.lineCount)
    else -- Vertical
        -- 垂直滚动：先从上到下填充，达到 lineCount 后换列
        col = (index - 1) % self.lineCount
        row = math.floor((index - 1) / self.lineCount)
    end
    
    -- 计算基础位置（不考虑布局原点）
    x = col * (itemWidth + self.spacing.x)
    y = row * (itemHeight + self.spacing.y)
    
    -- 计算实际可用内容区域（不包含padding）
    local contentWidth = self.contentSize.width - self.padding.left - self.padding.right
    local contentHeight = self.contentSize.height - self.padding.top - self.padding.bottom
    
    -- 计算当前行/列的实际项目数
    local itemsInLastRow = #self.dataList - (math.floor((#self.dataList - 1) / self.lineCount) * self.lineCount)
    if itemsInLastRow == 0 and #self.dataList > 0 then
        itemsInLastRow = self.lineCount
    end
    local totalRows = math.ceil(#self.dataList / self.lineCount)
    
    -- 根据布局原点调整位置
    if string.find(self.layoutOrigin, "Center") then
        if string.find(self.layoutOrigin, "Top") or string.find(self.layoutOrigin, "Bottom") or string.find(self.layoutOrigin, "Middle") then
            -- 水平居中
            local rowItems = (row == totalRows - 1) and itemsInLastRow or self.lineCount
            x = x + (contentWidth - rowItems * (itemWidth + self.spacing.x) + self.spacing.x) / 2
        end
    elseif string.find(self.layoutOrigin, "Right") then
        -- 右对齐
        x = contentWidth - x - itemWidth
    end
    
    if string.find(self.layoutOrigin, "Middle") then
        if string.find(self.layoutOrigin, "Left") or string.find(self.layoutOrigin, "Right") or string.find(self.layoutOrigin, "Center") then
            -- 垂直居中
            y = y + (contentHeight - totalRows * (itemHeight + self.spacing.y) + self.spacing.y) / 2
        end
    elseif string.find(self.layoutOrigin, "Bottom") then
        -- 底部对齐 - 修正计算
        if self.scrollDirection == "Vertical" then
            -- 对于垂直布局，需要从底部开始计算位置
            -- 修正：计算从底部开始的正确位置
            y = contentHeight - (row + 1) * (itemHeight + self.spacing.y) + self.spacing.y
        else
            -- 对于水平布局
            y = contentHeight - y - itemHeight
        end
    end
    
    -- 应用反向布局
    if self.layoutReverse then
        if self.layoutDirection == "Horizontal" then
            x = contentWidth - x - itemWidth
        else
            y = contentHeight - y - itemHeight
        end
    end
    
    -- 最后添加padding偏移
    x = x + self.padding.left
    y = y + self.padding.top
    
    return Vec2.New(x, y)
end

--[[
    设置项目位置
    @param item: 列表项对象
    @param index: 数据索引
    主要功能:
    1. 根据布局方向计算行列位置
    2. 考虑布局原点进行位置调整
    3. 应用边距和间距
    4. 处理反向布局
]]
function SuperGridView:SetItemPosition(item, index)
    local position = self:CalculateItemPosition(item, index)
    item:SetPosition(position)
end

--[[
    计算可见范围
    @return startIndex, endIndex: 可见范围的起始和结束索引
    主要功能:
    1. 根据当前滚动位置计算可见区域
    2. 考虑边距影响
    3. 计算可见项目的索引范围
]]
function SuperGridView:CalculateVisibleRange()
    local startIndex, endIndex = 1, #self.dataList
    
    -- 如果没有数据，直接返回
    if #self.dataList == 0 then
        return 1, 0
    end

    local itemWidth, itemHeight = self:GetDerivedItemSize()
    
    -- 计算实际可用内容区域（不包含padding）
    local contentWidth = self.contentSize.width - self.padding.left - self.padding.right
    local contentHeight = self.contentSize.height - self.padding.top - self.padding.bottom
    
    -- 计算总行数和列数
    local totalRows = math.ceil(#self.dataList / self.lineCount)
    local totalCols = math.ceil(#self.dataList / self.lineCount)
    
    -- 计算最后一行的实际项目数
    local itemsInLastRow = #self.dataList - (math.floor((#self.dataList - 1) / self.lineCount) * self.lineCount)
    if itemsInLastRow == 0 and #self.dataList > 0 then
        itemsInLastRow = self.lineCount
    end
    
    
    -- 检查是否是底部对齐
    local isBottomAligned = string.find(self.layoutOrigin, "Bottom") ~= nil
    
    if self.scrollDirection == "Vertical" then
        -- 计算可视区域的顶部和底部位置（考虑内容位置和padding）
        local viewportTop = -self.currentPosition.y
        local viewportBottom = viewportTop + self.viewportHeight
        
        -- 计算单个项目的总高度（包含间距）
        local itemTotalHeight = itemHeight + self.spacing.y
        
        -- 根据layoutOrigin调整垂直偏移
        local verticalOffset = self.padding.top
        if string.find(self.layoutOrigin, "Middle") then
            -- 垂直居中
            verticalOffset = verticalOffset + (contentHeight - totalRows * itemTotalHeight + self.spacing.y) / 2
        elseif isBottomAligned then
            -- 底部对齐
            if self.layoutDirection == "Vertical" then
                -- 对于垂直布局，需要从底部开始计算
                verticalOffset = self.padding.top + contentHeight - totalRows * itemTotalHeight
            else
                -- 对于水平布局
                verticalOffset = self.padding.top + contentHeight - self.lineCount * itemTotalHeight
            end
        end
        
        local startRow, endRow
        
        if isBottomAligned and self.layoutDirection == "Vertical" then
            -- 对于底部对齐的垂直布局，需要特殊处理
            -- 计算从底部开始的行索引
            local bottomViewportTop = contentHeight - viewportBottom + verticalOffset
            local bottomViewportBottom = contentHeight - viewportTop + verticalOffset
            
            startRow = math.floor(bottomViewportTop / itemTotalHeight)
            endRow = math.ceil(bottomViewportBottom / itemTotalHeight) - 1
            
            -- 限制行范围
            startRow = math.max(0, startRow)
            endRow = math.min(totalRows - 1, endRow)
            
            -- 反转行索引，因为我们是从底部计算的
            local tempStartRow = startRow
            startRow = totalRows - 1 - endRow
            endRow = totalRows - 1 - tempStartRow
        else
            -- 标准计算（从顶部开始）
            startRow = math.floor((viewportTop - verticalOffset) / itemTotalHeight)
            endRow = math.ceil((viewportBottom - verticalOffset) / itemTotalHeight) - 1
            
            -- 限制行范围
            startRow = math.max(0, startRow)
            endRow = math.min(totalRows - 1, endRow)
        end
        
        -- 处理反向布局
        if self.layoutReverse and self.layoutDirection == "Vertical" then
            -- 在垂直反向布局中，需要反转行的计算
            local tempStartRow = startRow
            startRow = totalRows - 1 - endRow
            endRow = totalRows - 1 - tempStartRow
        end
        
        -- 计算索引范围
        startIndex = startRow * self.lineCount + 1
        endIndex = math.min(#self.dataList, (endRow + 1) * self.lineCount)
        
        -- UILog:Debug(string.format("Vertical: viewportTop=%f, viewportBottom=%f, startRow=%d, endRow=%d, verticalOffset=%f, isBottomAligned=%s", 
        --     viewportTop, viewportBottom, startRow, endRow, verticalOffset, tostring(isBottomAligned)))
    else -- Horizontal
        -- 计算可视区域的左侧和右侧位置（考虑内容位置和padding）
        local viewportLeft = -self.currentPosition.x
        local viewportRight = viewportLeft + self.viewportWidth
        
        -- 计算单个项目的总宽度（包含间距）
        local itemTotalWidth = itemWidth + self.spacing.x
        
        -- 根据layoutOrigin调整水平偏移
        local horizontalOffset = self.padding.left
        if string.find(self.layoutOrigin, "Center") then
            if string.find(self.layoutOrigin, "Top") or string.find(self.layoutOrigin, "Bottom") or string.find(self.layoutOrigin, "Middle") then
                -- 水平居中
                horizontalOffset = horizontalOffset + (contentWidth - totalCols * itemTotalWidth + self.spacing.x) / 2
            end
        elseif string.find(self.layoutOrigin, "Right") then
            -- 右对齐
            horizontalOffset = horizontalOffset + (contentWidth - totalCols * itemTotalWidth + self.spacing.x)
        end
        
        local startCol, endCol
        
        if string.find(self.layoutOrigin, "Right") and self.layoutDirection == "Horizontal" then
            -- 对于右对齐的水平布局，需要特殊处理
            -- 计算从右侧开始的列索引
            local rightViewportLeft = contentWidth - viewportRight + horizontalOffset
            local rightViewportRight = contentWidth - viewportLeft + horizontalOffset
            
            startCol = math.floor(rightViewportLeft / itemTotalWidth)
            endCol = math.ceil(rightViewportRight / itemTotalWidth) - 1
            
            -- 限制列范围
            startCol = math.max(0, startCol)
            endCol = math.min(totalCols - 1, endCol)
            
            -- 反转列索引，因为我们是从右侧计算的
            local tempStartCol = startCol
            startCol = totalCols - 1 - endCol
            endCol = totalCols - 1 - tempStartCol
        else
            -- 标准计算（从左侧开始）
            startCol = math.floor((viewportLeft - horizontalOffset) / itemTotalWidth)
            endCol = math.ceil((viewportRight - horizontalOffset) / itemTotalWidth) - 1
            
            -- 限制列范围
            startCol = math.max(0, startCol)
            endCol = math.min(totalCols - 1, endCol)
        end
        
        -- 处理反向布局
        if self.layoutReverse and self.layoutDirection == "Horizontal" then
            -- 在水平反向布局中，需要反转列的计算
            local tempStartCol = startCol
            startCol = totalCols - 1 - endCol
            endCol = totalCols - 1 - tempStartCol
        end
        
        -- 计算索引范围
        startIndex = startCol * self.lineCount + 1
        endIndex = math.min(#self.dataList, (endCol + 1) * self.lineCount)
        
        -- UILog:Debug(string.format("Horizontal: viewportLeft=%f, viewportRight=%f, startCol=%d, endCol=%d, horizontalOffset=%f", 
        --     viewportLeft, viewportRight, startCol, endCol, horizontalOffset))
    end
    
    -- 确保索引在有效范围内
    startIndex = math.max(1, startIndex)
    endIndex = math.min(#self.dataList, endIndex)
    
    -- 添加缓冲区，多加载几个项目以提高滚动体验
    local buffer = self.lineCount * 2  -- 额外加载两行/列的项目
    startIndex = math.max(1, startIndex - buffer)
    endIndex = math.min(#self.dataList, endIndex + buffer)
    
    -- UILog:Debug(string.format("Final range: startIndex=%d, endIndex=%d (layoutOrigin=%s, layoutReverse=%s)", 
    --     startIndex, endIndex, self.layoutOrigin, tostring(self.layoutReverse)))
    
    return startIndex, endIndex
end

function SuperGridView:SetItemSize(width, height)
    self.itemWidth = width
    self.itemHeight = height
    self:UpdateContentSize()
    self.isDirty = true
end

function SuperGridView:GetItemSize()
    return Vec2.New(self.itemWidth, self.itemHeight)
end

function SuperGridView:SetItemWidth(width)
    self.itemWidth = width
    self:UpdateContentSize()
    self.isDirty = true
end

function SuperGridView:SetItemHeight(height)
    self.itemHeight = height
    self:UpdateContentSize()
    self.isDirty = true
end

function SuperGridView:SetItemAutoWidth(autoWidth)
    self.itemAutoWidth = autoWidth
    self:UpdateContentSize()
    self.isDirty = true
end

function SuperGridView:SetItemAutoHeight(autoHeight)
    self.itemAutoHeight = autoHeight
    self:UpdateContentSize()
    self.isDirty = true
end

--[[
    获取计算后的item大小
    @return width, height: 计算后的item宽度，高度
]]
function SuperGridView:GetDerivedItemSize()
    local width, height = self.itemWidth, self.itemHeight
    local size = UIUtils:GetSize(self.bindObj)
    if self.itemAutoWidth then
        width = size.x - self.padding.left - self.padding.right
    end
    if self.itemAutoHeight then
        height = size.y - self.padding.top - self.padding.bottom
    end

    return width, height
end


--[[
    设置布局选项
    @param origin: 布局起点
    @param direction: 排序方向
    @param flow: 布局方向
]]
function SuperGridView:SetLayoutOptions(origin, direction, reverse)
    self.layoutOrigin = origin or "TopLeft"
    self.layoutDirection = direction or "Horizontal"
    self.layoutReverse = reverse or false
    self.isDirty = true
end

--[[
    刷新布局
    主要功能:
    1. 重新计算内容大小
    2. 更新内容节点尺寸
    3. 刷新可见项目
]]
function SuperGridView:RefreshLayout()
    self:UpdateContentSize()
    self:UpdateVisibleItems()
end

--[[
    刷新可见项目
]]
function SuperGridView:RefreshVisibleItems()
    self:UpdateVisibleItems(true)
end

--[[
    可视区域
]]
function SuperGridView:GetVisibleRange()
    return self.startIndex, self.endIndex
end

--[[
    滚动到指定索引的item
    @param index: 目标索引
    @param animated: 是否启用动画
    @param alignment: 字符串枚举值，表示item在视口中的位置
                     "Start": 项目在视口顶部/左侧 (默认)
                     "Center": 项目在视口中间
                     "End": 项目在视口底部/右侧
]]
function SuperGridView:ScrollToItem(index, animated, alignment)
    if index < 1 or index > #self.dataList then
        UILog:Warn("ScrollToItem: Invalid index")
        return
    end

    local itemWidth, itemHeight = self:GetDerivedItemSize()

    -- 默认对齐到顶部/左侧
    alignment = alignment or "Start"
    -- 验证alignment是有效的枚举值
    if alignment ~= "Start" and alignment ~= "Center" and alignment ~= "End" then
        UILog:Warn("ScrollToItem: Invalid alignment value, using 'Start'")
        alignment = "Start"
    end

    local targetX, targetY = self.currentPosition.x, self.currentPosition.y
    
    -- 如果启用了数据反序，需要调整索引
    local adjustedIndex = index
    if self.dataReverse then
        adjustedIndex = #self.dataList - index + 1
    end
    
    -- 计算实际可用内容区域（不包含padding）
    local contentWidth = self.contentSize.width - self.padding.left - self.padding.right
    local contentHeight = self.contentSize.height - self.padding.top - self.padding.bottom
    
    -- 计算当前行/列的实际项目数
    local itemsInLastRow = #self.dataList - (math.floor((#self.dataList - 1) / self.lineCount) * self.lineCount)
    if itemsInLastRow == 0 and #self.dataList > 0 then
        itemsInLastRow = self.lineCount
    end
    local totalRows = math.ceil(#self.dataList / self.lineCount)
    
    if self.scrollDirection == "Vertical" then
        local row = math.floor((adjustedIndex - 1) / self.lineCount)
        local col = (adjustedIndex - 1) % self.lineCount
        local maxRows = math.ceil(#self.dataList / self.lineCount)
        
        -- 如果是垂直方向的反向布局，需要调整行号
        if self.layoutReverse and self.layoutDirection == "Vertical" then
            row = maxRows - 1 - row
        end
        
        -- 基础位置计算
        local x = col * (itemWidth + self.spacing.x)
        local y = row * (itemHeight + self.spacing.y)
        
        -- 根据layoutOrigin调整水平位置
        if string.find(self.layoutOrigin, "Center") then
            if string.find(self.layoutOrigin, "Top") or string.find(self.layoutOrigin, "Bottom") or string.find(self.layoutOrigin, "Middle") then
                -- 水平居中
                local rowItems = (row == totalRows - 1) and itemsInLastRow or self.lineCount
                x = x + (contentWidth - rowItems * (itemWidth + self.spacing.x) + self.spacing.x) / 2
            end
        elseif string.find(self.layoutOrigin, "Right") then
            -- 右对齐
            x = contentWidth - x - itemWidth
        end
        
        -- 根据layoutOrigin调整垂直位置
        if string.find(self.layoutOrigin, "Middle") then
            if string.find(self.layoutOrigin, "Left") or string.find(self.layoutOrigin, "Right") or string.find(self.layoutOrigin, "Center") then
                -- 垂直居中
                y = y + (contentHeight - totalRows * (itemHeight + self.spacing.y) + self.spacing.y) / 2
            end
        elseif string.find(self.layoutOrigin, "Bottom") then
            -- 底部对齐
            if self.layoutDirection == "Vertical" then
                -- 对于垂直布局，需要从底部开始计算位置
                y = contentHeight - (row + 1) * (itemHeight + self.spacing.y) + self.spacing.y
            else
                -- 对于水平布局
                y = contentHeight - y - itemHeight
            end
        end
        
        -- 应用padding
        x = x + self.padding.left
        y = y + self.padding.top
        
        -- 计算项目的顶部位置
        local itemTop = y
        -- 计算项目的底部位置
        local itemBottom = itemTop + itemHeight
        
        -- 根据alignment计算目标位置
        if alignment == "Start" then
            -- 项目顶部对齐视口顶部
            targetY = -itemTop
        elseif alignment == "End" then
            -- 项目底部对齐视口底部
            targetY = -(itemBottom - self.viewportHeight)
        else -- Center
            -- 项目中心对齐视口中心
            local itemCenter = itemTop + itemHeight * 0.5
            local viewportCenter = self.viewportHeight * 0.5
            targetY = -(itemCenter - viewportCenter)
        end
    else -- Horizontal
        local col = math.floor((adjustedIndex - 1) / self.lineCount)
        local row = (adjustedIndex - 1) % self.lineCount
        local maxCols = math.ceil(#self.dataList / self.lineCount)
        
        -- 如果是水平方向的反向布局，需要调整列号
        if self.layoutReverse and self.layoutDirection == "Horizontal" then
            col = maxCols - 1 - col
        end
        
        -- 基础位置计算
        local x = col * (itemWidth + self.spacing.x)
        local y = row * (itemHeight + self.spacing.y)
        
        -- 根据layoutOrigin调整水平位置
        if string.find(self.layoutOrigin, "Center") then
            if string.find(self.layoutOrigin, "Top") or string.find(self.layoutOrigin, "Bottom") or string.find(self.layoutOrigin, "Middle") then
                -- 水平居中
                local rowItems = (row == totalRows - 1) and itemsInLastRow or self.lineCount
                x = x + (contentWidth - rowItems * (itemWidth + self.spacing.x) + self.spacing.x) / 2
            end
        elseif string.find(self.layoutOrigin, "Right") then
            -- 右对齐
            x = contentWidth - x - itemWidth
        end
        
        -- 根据layoutOrigin调整垂直位置
        if string.find(self.layoutOrigin, "Middle") then
            if string.find(self.layoutOrigin, "Left") or string.find(self.layoutOrigin, "Right") or string.find(self.layoutOrigin, "Center") then
                -- 垂直居中
                y = y + (contentHeight - totalRows * (itemHeight + self.spacing.y) + self.spacing.y) / 2
            end
        elseif string.find(self.layoutOrigin, "Bottom") then
            -- 底部对齐
            if self.layoutDirection == "Vertical" then
                -- 对于垂直布局，需要从底部开始计算位置
                y = contentHeight - (row + 1) * (itemHeight + self.spacing.y) + self.spacing.y
            else
                -- 对于水平布局
                y = contentHeight - y - itemHeight
            end
        end
        
        -- 应用padding
        x = x + self.padding.left
        y = y + self.padding.top
        
        -- 计算项目的左侧位置
        local itemLeft = x
        -- 计算项目的右侧位置
        local itemRight = itemLeft + itemWidth
        
        -- 根据alignment计算目标位置
        if alignment == "Start" then
            -- 项目左侧对齐视口左侧
            targetX = -itemLeft
        elseif alignment == "End" then
            -- 项目右侧对齐视口右侧
            targetX = -(itemRight - self.viewportWidth)
        else -- Center
            -- 项目中心对齐视口中心
            local itemCenter = itemLeft + itemWidth * 0.5
            local viewportCenter = self.viewportWidth * 0.5
            targetX = -(itemCenter - viewportCenter)
        end
    end

    -- 确保不超出边界
    local minY = self.viewportHeight - self.contentSize.height
    local minX = self.viewportWidth - self.contentSize.width
    
    targetX = math.max(minX, math.min(0, targetX))
    targetY = math.max(minY, math.min(0, targetY))

    -- 使用正确的参数格式调用ScrollTo
    self:ScrollTo({x = targetX, y = targetY}, animated and 0.3 or 0, true)
    
    -- UILog:Debug(string.format("ScrollToItem: index=%d, adjustedIndex=%d, layoutReverse=%s, dataReverse=%s, target={x=%f, y=%f}", 
    --     index, adjustedIndex, tostring(self.layoutReverse), tostring(self.dataReverse), targetX, targetY))
end

--[[
    设置item进入回调
    @param callback: 回调函数
]]
function SuperGridView:ItemEnterCallback(callback)
    self.itemEnterCallback = callback
end

function SuperGridView:HandleItemEnter(item)
    if self.itemEnterCallback then
        self.itemEnterCallback(self, item)
    end
end

--[[
    设置item离开回调
    @param callback: 回调函数
]]  
function SuperGridView:ItemLeaveCallback(callback)
    self.itemLeaveCallback = callback
end

function SuperGridView:HandleItemLeave(item)
    if self.itemLeaveCallback then
        self.itemLeaveCallback(self, item)
    end
end

--[[
    设置数据反序选项
    @param reverse: 布尔值，true表示数据反序，false表示正常顺序
]]
function SuperGridView:SetDataReverse(reverse)
    if self.dataReverse ~= reverse then
        self.dataReverse = reverse
        self:ForceUpdate()
    end
end

--[[
    更新指定索引的项目
    @param index: 数据索引
    说明: 当data中的某个元素已经改变，调用这个函数来更新显示
    如果这个index的项正在显示范围内，会触发ItemLeaveCallback和ItemEnterCallback来刷新数据
]]
function SuperGridView:UpdateItem(index)
    if index < 1 or index > #self.dataList then
        UILog:Warn("UpdateItem: Invalid index: " .. tostring(index))
        return
    end
    
    -- 查找当前是否有此索引的激活项
    for i, item in ipairs(self.activeItems) do
        if item.dataIndex == index then
            -- 找到了对应项，调用离开回调
            self:HandleItemLeave(item)
            
            -- 根据dataReverse决定数据索引
            local dataIndex = index
            if self.dataReverse then
                dataIndex = #self.dataList - index + 1
            end
            
            -- 更新数据引用
            item.data = self.dataList[dataIndex]
            
            -- 调用进入回调以刷新显示
            self:HandleItemEnter(item)
            return
        end
    end
end

--[[
    更新指定key的项目
    @param key: 数据键
]]
function SuperGridView:UpdateItemByKey(key)
    if not self.dataMap then
        return
    end
    local index = self:FindDataIndexByKey(key)
    if index then
        self:UpdateItem(index)
    end
end

--[[
    遍历所有可见项目
    @param callback: 回调函数
]]
function SuperGridView:ForEachVisibleItem(callback)
    for _, item in ipairs(self.activeItems) do
        callback(self, item)
    end
end

--[[
    根据屏幕坐标获取网格位置
    @param screenPos: 屏幕坐标 Vec2
    @return row, col: 行号和列号，如果坐标无效则返回nil
]]
function SuperGridView:GetGridPositionByScreenPos(screenPos)
    local localPos = self:MapScreenToContentSpace(screenPos)
    return self:GetGridPositionByLocalPos(localPos)
end

--[[
    根据局部坐标获取网格位置
    @param localPos: 局部坐标 Vec2
    @return row, col: 行号和列号，如果坐标无效则返回nil
]]
function SuperGridView:GetGridPositionByLocalPos(localPos)
    if not localPos then
        return nil
    end

    local itemWidth, itemHeight = self:GetDerivedItemSize()
    
    -- 计算实际可用内容区域（不包含padding）
    local contentWidth = self.contentSize.width - self.padding.left - self.padding.right
    local contentHeight = self.contentSize.height - self.padding.top - self.padding.bottom
    
    -- 计算总行数和列数
    local totalRows = math.ceil(#self.dataList / self.lineCount)
    local totalCols = math.ceil(#self.dataList / self.lineCount)
    
    -- 计算最后一行的实际项目数
    local itemsInLastRow = #self.dataList - (math.floor((#self.dataList - 1) / self.lineCount) * self.lineCount)
    if itemsInLastRow == 0 and #self.dataList > 0 then
        itemsInLastRow = self.lineCount
    end
    
    -- 检查是否是底部对齐
    local isBottomAligned = string.find(self.layoutOrigin, "Bottom") ~= nil
    
    -- 计算单个项目的总宽度和高度（包含间距）
    local itemTotalWidth = itemWidth + self.spacing.x
    local itemTotalHeight = itemHeight + self.spacing.y
    
    -- 根据layoutOrigin调整偏移
    local horizontalOffset = self.padding.left
    local verticalOffset = self.padding.top
    
    if string.find(self.layoutOrigin, "Center") then
        if string.find(self.layoutOrigin, "Top") or string.find(self.layoutOrigin, "Bottom") or string.find(self.layoutOrigin, "Middle") then
            -- 水平居中
            horizontalOffset = horizontalOffset + (contentWidth - totalCols * itemTotalWidth + self.spacing.x) / 2
        end
    elseif string.find(self.layoutOrigin, "Right") then
        -- 右对齐
        horizontalOffset = horizontalOffset + (contentWidth - totalCols * itemTotalWidth + self.spacing.x)
    end
    
    if string.find(self.layoutOrigin, "Middle") then
        if string.find(self.layoutOrigin, "Left") or string.find(self.layoutOrigin, "Right") or string.find(self.layoutOrigin, "Center") then
            -- 垂直居中
            verticalOffset = verticalOffset + (contentHeight - totalRows * itemTotalHeight + self.spacing.y) / 2
        end
    elseif isBottomAligned then
        -- 底部对齐
        if self.layoutDirection == "Vertical" then
            -- 对于垂直布局，需要从底部开始计算
            verticalOffset = verticalOffset + contentHeight - totalRows * itemTotalHeight
        else
            -- 对于水平布局
            verticalOffset = verticalOffset + contentHeight - self.lineCount * itemTotalHeight
        end
    end
    
    -- 计算行列位置
    local row, col
    
    if self.scrollDirection == "Vertical" then
        -- 垂直滚动：先从上到下填充，达到 lineCount 后换列
        col = math.floor((localPos.x - horizontalOffset) / itemTotalWidth) + 1
        row = math.floor((localPos.y - verticalOffset) / itemTotalHeight) + 1
    else -- Horizontal
        -- 水平滚动：先从左到右填充，达到 lineCount 后换行
        row = math.floor((localPos.y - verticalOffset) / itemTotalHeight) + 1
        col = math.floor((localPos.x - horizontalOffset) / itemTotalWidth) + 1
    end
    
    -- 处理反向布局
    if self.layoutReverse then
        if self.layoutDirection == "Horizontal" then
            col = totalCols - col + 1
        else
            row = totalRows - row + 1
        end
    end
    
    -- 检查是否在有效范围内
    if row < 1 or row > totalRows or col < 1 or col > self.lineCount then
        return nil
    end
    
    -- 计算数据索引
    local index = (row - 1) * self.lineCount + col
    if index > #self.dataList then
        return nil
    end
    
    return row, col
end

--[[
    更新指定矩形区域的项目
    @param x: 矩形左上角x坐标
    @param y: 矩形左上角y坐标
    @param width: 矩形宽度
    @param height: 矩形高度
]]
function SuperGridView:UpdateItemByRect(x, y, width, height)
    for _, item in ipairs(self.activeItems) do
        if item.posX >= x and item.posX <= x + width and item.posY >= y and item.posY <= y + height then
            self:UpdateItem(item.dataIndex)
        end
    end
end

--[[
    更新指定区域的项目
    @param startPos: 区域左上角本地坐标 Vec2
    @param endPos: 区域右下角本地坐标 Vec2
]]
function SuperGridView:UpdateItemByArea(startPos, endPos)
    local startRow, startCol = self:GetGridPositionByLocalPos(startPos)
    local endRow, endCol = self:GetGridPositionByLocalPos(endPos)
    local rect = {
        x = startCol,
        y = startRow,
        width = endCol - startCol,
        height = endRow - startRow
    }
    self:UpdateItemByRect(rect.x, rect.y, rect.width, rect.height)
end

return SuperGridView