-- 说明:列表控件
-- 日期:2025年5月24日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperScrollView = GFScript("UIModule.UIWidget.SuperScrollView")
local SuperItem = GFScript("UIModule.UIWidget.SuperItem")
local UIUtils = GFScript("UIModule.UIUtils")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local SuperListView = SuperScrollView.Extend("SuperListView")

function SuperListView:Constructor()
    self.origin = "TopLeft"

    --布局方向：Horizontal(水平) 或 Vertical(垂直)
    self.direction = "Horizontal"

    --是否反转布局
    self.reverse = false
    --内容边距
    self.padding = {left = 0, right = 0, top = 0, bottom = 0}
    --项目间距
    self.spacing = {x = 0, y = 0}

    self.items = {}

    self.layoutDirty = true
end

function SuperListView:Destructor()
    if self.notifyChildAddedEvent then
        self.notifyChildAddedEvent:Disconnect()
    end
    
    if self.notifyChildRemovedEvent then
        self.notifyChildRemovedEvent:Disconnect()
    end
end

--[[
    初始化布局控件
    @param bindObj: 绑定的UI对象
]]
function SuperListView:Init(bindObj)
    if not SuperListView.super.Init(self, bindObj) then
        return false
    end
    self.containerWidth = self.bindObj.Size.X
    self.containerHeight = self.bindObj.Size.Y

    --监听子节点添加函数
    self.notifyChildAddedEvent = self.content.NotifyChildAdded:Connect(function(node)
        self.layoutDirty = true
    end)
    self.notifyChildRemovedEvent =self.content.NotifyChildRemoved:Connect(function(node)
        self.layoutDirty = true
    end)
    
    self.layoutDirty = true

    return true
end

--[[
    更新布局
]]
function SuperListView:Update(deltaTime)
    SuperListView.super.Update(self, deltaTime)
    -- 检查容器大小是否变化
    if self.bindObj and (self.containerWidth ~= self.bindObj.Size.X or 
                        self.containerHeight ~= self.bindObj.Size.Y) then
        self.containerWidth = self.bindObj.Size.X
        self.containerHeight = self.bindObj.Size.Y
        self.layoutDirty = true
    end
    
    if self.layoutDirty then
        self:AdjustLayout()
    end
end

--添加项目
function SuperListView:AddItem(item)
    item.Parent = self.content
    table.insert(self.items, item)
end

--移除项目
function SuperListView:RemoveItem(item)
    table.remove(self.items, item)
    item:Destroy()
end

--清理所有项目
function SuperListView:ClearItems()
    for _, item in ipairs(self.items) do
        item:Destroy()
    end
    self.items = {}
end

--[[
    遍历所有项目
    @param callback: 回调函数
]]
function SuperListView:ForEachItem(callback)
    for _, child in ipairs(self.content.Children) do
        callback(self, child)
    end
end

--[[
    刷新布局
]]
function SuperListView:AdjustLayout()
    if not self.content then return end
    
    local children = {}
    for _, child in ipairs(self.content.Children) do
        if child.Visible then
            table.insert(children, child)
        end
    end
    
    if #children == 0 then return end

    UIUtils:AdjustLayoutChildren(self.content, children, 
        self.origin, self.direction, 
        self.reverse, self.padding, self.spacing, 1, function(child)
            self.layoutDirty = false
        end)

    self:UpdateContentSize()

    if self.adjustLayoutCallback then
        self.adjustLayoutCallback(self)
    end
end

--[[
    计算内容大小，考虑了内边距和间距
]]
function SuperListView:UpdateContentSize()
    if self.content then
        local rect = UIUtils:FitSize(self.content, self.padding.left, self.padding.top)
        self:SetContentSize(rect.width, rect.height)
    end
end

--[[
    设置内容边距
    @param left: 左边距
    @param right: 右边距
    @param top: 上边距
    @param bottom: 下边距
]]
function SuperListView:SetPadding(left, right, top, bottom)
    self.padding.left = left or 0
    self.padding.right = right or 0
    self.padding.top = top or 0
    self.padding.bottom = bottom or 0
    self.layoutDirty = true
end

--获取内容边距
function SuperListView:GetPadding()
    return self.padding
end

--[[
    设置项目间距
    @param x: 水平间距
    @param y: 垂直间距
]]
function SuperListView:SetSpacing(x, y)
    self.spacing.x = x or 0
    self.spacing.y = y or 0
    self.layoutDirty = true
end

--获取项目间距
function SuperListView:GetSpacing()
    return self.spacing
end

--设置布局起点
function SuperListView:SetOrigin(origin)
    self.origin = origin or "TopLeft"
    self.layoutDirty = true
end

--获取布局起点
function SuperListView:GetOrigin()
    return self.origin
end

--设置布局方向
function SuperListView:SetDirection(direction)
    self.direction = direction or "Horizontal"
    self.layoutDirty = true
end

--获取布局方向
function SuperListView:GetDirection()
    return self.direction
end

--设置是否反转布局
function SuperListView:SetReverse(reverse)
    self.reverse = reverse or false
    self.layoutDirty = true
end

--获取是否反转布局
function SuperListView:IsReverse()
    return self.reverse
end

--[[
    设置布局选项
    @param origin: 布局起点
    @param direction: 排序方向
    @param flow: 布局方向
]]
function SuperListView:SetLayoutOptions(origin, direction, reverse)
    self.origin = origin or "TopLeft"
    self.direction = direction or "Horizontal"
    self.reverse = reverse or false
    self.layoutDirty = true
end

--设置调整布局回调
function SuperListView:AdjustLayoutCallback(callback)
    self.adjustLayoutCallback = callback
end

return SuperListView