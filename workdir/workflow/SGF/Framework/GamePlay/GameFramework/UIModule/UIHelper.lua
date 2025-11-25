-- 说明:UI助手
-- 日期:2025年2月10日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Rect = GFScript("UIModule.UIMath.Rect")
local UIResource = GFScript("UIModule.UIResource")
local UILayout = GFScript("UIModule.UILayout")
local UIActionRunner = GFScript("UIModule.UIActionRunner")

local UIHelper = {}

--开发分辨率
UIHelper.DESIGN_RESOLUTION = Vec2.New(1280, 720)
--资源分辨率
UIHelper.RESOURCE_RESOLUTION = Vec2.New(1920, 1080)

--获取缩放比例
function UIHelper:GetDesignScale()
    local scaleX = UIHelper.DESIGN_RESOLUTION.x / UIHelper.RESOURCE_RESOLUTION.x
    local scaleY = UIHelper.DESIGN_RESOLUTION.y / UIHelper.RESOURCE_RESOLUTION.y
    return Vec2.New(scaleX, scaleY)
end

--获取视口分辨率
function UIHelper:GetViewportSize()
    local resolution = game:GetService("WorldService"):GetUISize()
    return Vec2.New(resolution.X, resolution.Y)
end

--规范化精灵路径
function UIHelper:FullSpritePath(sprite)
    if not string.find(sprite, "sandboxId://") then
        sprite = "sandboxId://" .. sprite
    end
    return sprite
end

--获取相对路径
function UIHelper:RelativeSpritePath(sprite)
    if string.find(sprite, "sandboxId://") then
        sprite = string.sub(sprite, 12)
    end
    return sprite
end

--调整某个控件所在父节点中的排序位置
function UIHelper:SetSiblingIndex(control, index)
    local parent = control.Parent
    if not parent then
        UILog:Error("UIHelper:SetSiblingIndex: parent is nil")
        return
    end
    local children = parent.Children
    if not children then
        UILog:Error("UIHelper:SetSiblingIndex: children is nil")
        return
    end
    local currentIndex = self:GetSiblingIndex(control)
    if currentIndex == -1 or currentIndex == index then
        return
    end
    --挪动位置
    UIUtils:MoveArrayElement(children, currentIndex, index)
    
    for i, child in ipairs(children) do
        child.Parent = nil
    end
    for i, child in ipairs(children) do
        child.Parent = parent
    end
    self:SortRenderIndex(parent)
end

function UIHelper:GetSiblingIndex(control)
    local parent = control.Parent
    if not parent then
        UILog:Error("UIHelper:GetSiblingIndex: parent is nil")
        return
    end
    local children = parent.Children
    if not children then
        UILog:Error("UIHelper:GetSiblingIndex: children is nil")
        return
    end
    for i, child in ipairs(children) do
        if child == control then
            return i
        end
    end
    return -1
end

function UIHelper:SetParent(control, parent, keepScreenPos)
    if not control then
        UILog:Error("SetParent: control is nil")
        return
    end
    if not parent then
        UILog:Error("SetParent: parent is nil")
        return
    end
    keepScreenPos = (keepScreenPos == nil and false or keepScreenPos)
    local screenPos = nil
    if keepScreenPos then
        screenPos = UIHelper:GetScreenPosition(control)
    end
    control.Parent = parent
    if keepScreenPos then
        UIHelper:SetScreenPosition(control, screenPos)
    end
end

--排序渲染索引
function UIHelper:SortRenderIndex(control)
    local children = control.Children
    for i, child in ipairs(children) do
        child.RenderIndex = i
    end
end

--设置到最上层
function UIHelper:SetToTop(control)
    local parent = control.Parent
    if not parent then
        UILog:Error("UIHelper:SetToTop: parent is nil")
        return
    end
    local children = parent.Children
    if not children then
        UILog:Error("UIHelper:SetToTop: children is nil")
        return
    end
    UIHelper:SetSiblingIndex(control, #children)
end

--设置到最下层
function UIHelper:SetToBottom(control)
    local parent = control.Parent
    if not parent then
        UILog:Error("UIHelper:SetToBottom: parent is nil")
        return
    end
    local children = parent.Children
    if not children then
        UILog:Error("UIHelper:SetToBottom: children is nil")
        return
    end
    UIHelper:SetSiblingIndex(control, 1)
end

--设置颜色
function UIHelper:SetColorInHierarchy(control, color, recursive)
    if not control then
        UILog:Error("SetColorInHierarchy: control is nil")
        return
    end
    recursive = recursive or true
    self:SetColor(control, color)
    if recursive then
        for _, child in ipairs(control.Children) do
            self:SetColorInHierarchy(child, color, recursive)
        end
    end
end

--设置透明度
function UIHelper:SetAlphaInHierarchy(control, alpha, recursive)
    if not control then
        UILog:Error("SetAlphaInHierarchy: control is nil")
        return
    end
    recursive = recursive or true
    self:SetAlpha(control, alpha)
    if recursive then
        for _, child in ipairs(control.Children) do
            self:SetAlphaInHierarchy(child, alpha, recursive)
        end
    end
end

--设置颜色
function UIHelper:SetColor(control, color)
    if not control then
        UILog:Error("SetColor: control is nil")
        return
    end
    if not color then
        UILog:Error("SetColor: color is nil")
        return
    end

    if type(color) == "string" then
        color = Color.FromHex(color)
    end

    local r = math.min(255, color.r * 255)
    local g = math.min(255, color.g * 255)
    local b = math.min(255, color.b * 255)
    if control.BMColor then
        control.BMColor = Vector3.New(r, g, b)
    elseif control.TitleColor then
        local a = control.TitleColor.A
        control.TitleColor = ColorQuad.New(r, g, b, a)
    else
        local a = control.FillColor.A
        control.FillColor = ColorQuad.New(r, g, b, a)
    end
end

--获取颜色
function UIHelper:GetColor(control)
    if not control then
        UILog:Error("GetColor: control is nil")
        return
    end
    if control.BMColor then
        local color = control.BMColor
        local alpha = control.Alpha
        return Color.New(color.x / 255, color.y / 255, color.z / 255, alpha / 255)
    elseif control.TitleColor then
        local color = control.TitleColor
        return Color.New(color.R / 255, color.G / 255, color.B / 255, color.A / 255)
    else
        local color = control.FillColor
        return Color.New(color.R / 255, color.G / 255, color.B / 255, color.A / 255)
    end
end

--设置透明度
function UIHelper:SetAlpha(control, alpha)
    if not control then
        UILog:Error("SetAlpha: control is nil")
        return
    end
    local a = math.min(255, alpha * 255)
    if control.Alpha then
        control.Alpha = a
    elseif control.TitleColor then
        control.TitleColor = ColorQuad.New(control.TitleColor.R, control.TitleColor.G, control.TitleColor.B, a)
        if control.OutlineColor then
            control.OutlineColor = ColorQuad.New(control.OutlineColor.R, control.OutlineColor.G, control.OutlineColor.B, a)
        end
        if control.ShadowColor then
            control.ShadowColor = ColorQuad.New(control.ShadowColor.R, control.ShadowColor.G, control.ShadowColor.B, a)
        end
    else
        control.FillColor = ColorQuad.New(control.FillColor.R, control.FillColor.G, control.FillColor.B, a)
        
    end
end

--获取透明度
function UIHelper:GetAlpha(control)
    if not control then
        UILog:Error("GetAlpha: control is nil")
        return
    end
    if control.Alpha then
        return control.Alpha / 255
    elseif control.TitleColor then
        return control.TitleColor.A / 255
    else
        return control.FillColor.A / 255
    end
end


--查找子控件
function UIHelper:FindChildControl(control, controlName, recursive)
    recursive = recursive or true
    local childControl = control[controlName]
    if childControl then
        return childControl
    end
    if recursive then
        for _, child in ipairs(control.Children) do
            local result = self:FindChildControl(child, controlName, recursive)
            if result then
                return result
            end
        end
    end
    return nil
end

--获取屏幕缩放
function UIHelper:GetScreenScale(control)
    local scaleX = 1
    local scaleY = 1

    local parent = control
    while parent and parent.ClassType ~= "UIRoot" do
        local parentScale = parent.Scale
        scaleX = scaleX * parentScale.X
        scaleY = scaleY * parentScale.Y
        parent = parent.Parent
    end
    return scaleX, scaleY

end


--调整子控件布局
--@param control 控件
--@param children 子控件列表
--@param layoutOrigin 布局对齐方式
--@param layoutDirection 布局方向
--@param layoutReverse 是否反向布局
--@param layoutPadding 布局内边距
--@param layoutSpacing 布局间距
function UIHelper:AdjustLayoutChildren(control, children,
    layoutOrigin, layoutDirection, 
    layoutReverse, layoutPadding, layoutSpacing, lineCount, layoutCallback)
    local layoutRect = self:GetScreenRect(control)
    local layoutItems = {}
    for _, child in ipairs(children) do
        local size = child.Size
        table.insert(layoutItems, Vec2.New(size.X, size.Y))
    end
    UILayout:AdjustLayout(layoutRect, layoutItems, lineCount,
        layoutOrigin, layoutDirection, 
        layoutReverse, layoutPadding, layoutSpacing, function(index, pos, size)
            local child = children[index]
            local pivot = child.Pivot
            child.Position = Vector2.New(pos.x + size.x * pivot.X, pos.y + size.y * pivot.Y)
            child.Size = Vector2.New(size.x, size.y)
            if layoutCallback then
                layoutCallback(child)
            end
        end)
end

--水平布局
function UIHelper:AdjustHLayoutChildren(control, children,
    layoutOrigin, 
    layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    local layoutRect = self:GetScreenRect(control)
    local layoutItems = {}
    for _, child in ipairs(children) do
        local size = child.Size
        table.insert(layoutItems, Vec2.New(size.X, size.Y))
    end
    UILayout:AdjustLayout(layoutRect, layoutItems, math.huge,
        layoutOrigin, "Horizontal", 
        layoutReverse, layoutPadding, layoutSpacing, function(index, pos, size)
            local child = children[index]
            local pivot = child.Pivot
            child.Position = Vector2.New(pos.x + size.x * pivot.X, child.Position.Y)
            child.Size = Vector2.New(size.x, size.y)
            if layoutCallback then
                layoutCallback(child)
            end
        end)
end

--纵向布局
function UIHelper:AdjustVLayoutChildren(control, children,
    layoutOrigin, 
    layoutReverse, layoutPadding, layoutSpacing, layoutCallback)
    local layoutRect = self:GetScreenRect(control)
    local layoutItems = {}
    for _, child in ipairs(children) do
        local size = child.Size
        table.insert(layoutItems, Vec2.New(size.X, size.Y))
    end
    UILayout:AdjustLayout(layoutRect, layoutItems, math.huge,
        layoutOrigin, "Vertical", 
        layoutReverse, layoutPadding, layoutSpacing, function(index, pos, size)
            local child = children[index]
            local pivot = child.Pivot
            child.Position = Vector2.New(child.Position.X, pos.y + size.y * pivot.Y)
            child.Size = Vector2.New(size.x, size.y)
            if layoutCallback then
                layoutCallback(child)
            end
        end)
end


--水平布局
--@param control 控件
--@param spacingX 水平间距
--@param paddingX 水平内边距
--@param origin 对齐方式
function UIHelper:HLayoutChildren(control, spacingX, paddingX, origin)
    spacingX = spacingX or 0
    paddingX = paddingX or 0
    origin = origin or "LeftMiddle"
    local children = {}
    for _, child in ipairs(control.Children) do
        if child.Visible then
            table.insert(children, child)
        end
    end
    self:HLayout(children, spacingX, paddingX, origin)
end

--水平布局
--@param controls 控件列表
--@param spacingX 水平间距
--@param paddingX 水平内边距
--@param origin 对齐方式
function UIHelper:HLayout(controls, spacingX, paddingX, origin)
    if #controls == 0 then
        return
    end
    spacingX = spacingX or 0
    paddingX = paddingX or 0
    origin = origin or "LeftMiddle"
    self:AdjustHLayoutChildren(controls[1].Parent, controls, 
        origin, 
        false, {left = paddingX, right = paddingX, top = 0, bottom = 0}, {x = spacingX, y = 0}, nil)
end

--垂直布局
--@param control 控件
--@param spacingY 垂直间距
--@param paddingY 垂直内边距
--@param origin 对齐方式
function UIHelper:VLayoutChildren(control, spacingY, paddingY, origin)
    spacingY = spacingY or 0
    paddingY = paddingY or 0
    origin = origin or "TopCenter"
    local children = {}
    for _, child in ipairs(control.Children) do
        if child.Visible then
            table.insert(children, child)
        end
    end
    self:VLayout(children, spacingY, paddingY, origin)
end

--垂直布局
--@param controls 控件列表
--@param spacingY 垂直间距
--@param paddingY 垂直内边距
--@param origin 对齐方式
function UIHelper:VLayout(controls, spacingY, paddingY, origin)
    if #controls == 0 then
        return
    end
    spacingY = spacingY or 0
    paddingY = paddingY or 0
    origin = origin or "TopCenter"
    self:AdjustVLayoutChildren(controls[1].Parent, controls, 
        origin, 
        false, {left = 0, right = 0, top = paddingY, bottom = paddingY}, {x = 0, y = spacingY}, nil)
end


--获取屏幕位置
function UIHelper:GetScreenPosition(control)
    local pos = control.Position
    local size = control.Size
    local pivot = control.Pivot
    local screenPos = Vec2.New(
        pos.X - size.X * pivot.X,
        pos.Y - size.Y * pivot.Y
    )
    
    local currentControl = control
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parent = currentControl.Parent
        local parentPos = parent.Position
        local parentPivot = parent.Pivot
        local parentSize = parent.Size
        local parentScale = parent.Scale
        
        screenPos.x = screenPos.x * parentScale.X
        screenPos.y = screenPos.y * parentScale.Y
        
        screenPos.x = screenPos.x + parentPos.X - parentSize.X * parentPivot.X
        screenPos.y = screenPos.y + parentPos.Y - parentSize.Y * parentPivot.Y
        
        currentControl = parent
    end
    
    return screenPos
end

--设置屏幕位置
function UIHelper:SetScreenPosition(control, pos)
    local currentControl = control
    local parentTransforms = {}
    
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parent = currentControl.Parent
        table.insert(parentTransforms, {
            position = parent.Position,
            pivot = parent.Pivot,
            size = parent.Size,
            scale = parent.Scale
        })
        currentControl = parent
    end
    
    local localPos = Vec2.New(pos.x, pos.y)
    for i = #parentTransforms, 1, -1 do
        local transform = parentTransforms[i]
        
        localPos.x = localPos.x + transform.size.X * transform.pivot.X - transform.position.X
        localPos.y = localPos.y + transform.size.Y * transform.pivot.Y - transform.position.Y
        
        localPos.x = localPos.x / transform.scale.X
        localPos.y = localPos.y / transform.scale.Y
    end
    
    local size = control.Size
    local pivot = control.Pivot
    control.Position = Vector2.New(localPos.x + size.X * pivot.X, localPos.y + size.Y * pivot.Y)
end

--获取父节点屏幕矩形
function UIHelper:GetParentScreenRect(control)
    local parent = control.Parent
    if not parent then
        UILog:Error("GetParentScreenRect: parent is nil")
        local viewportSize = self:GetViewportSize()
        return Rect.New(0, 0, viewportSize.x, viewportSize.y)
    end
    return self:GetScreenRect(parent)
end

--获取屏幕矩形
function UIHelper:GetScreenRect(control)
    local pos = control.Position
    local size = control.Size
    local pivot = control.Pivot
    local rect = Rect.New(pos.X, pos.Y, size.X, size.Y)
    rect:ApplyPivot(Vec2.New(pivot.X, pivot.Y))
    
    local currentControl = control
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parent = currentControl.Parent
        local parentPos = parent.Position
        local parentPivot = parent.Pivot
        local parentSize = parent.Size
        
        local parentScale = parent.Scale
        rect.x = rect.x * parentScale.X + parentPos.X - parentSize.X * parentPivot.X
        rect.y = rect.y * parentScale.Y + parentPos.Y - parentSize.Y * parentPivot.Y
        rect.width = rect.width * parentScale.X
        rect.height = rect.height * parentScale.Y
        
        currentControl = parent
    end
    
    return rect
end

--设置屏幕矩形
function UIHelper:SetScreenRect(control, rect)
    local currentControl = control
    local parentTransforms = {}
    
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parent = currentControl.Parent
        table.insert(parentTransforms, {
            position = parent.Position,
            pivot = parent.Pivot,
            size = parent.Size,
            scale = parent.Scale
        })
        currentControl = parent
    end
    
    local localRect = Rect.New(rect.x, rect.y, rect.width, rect.height)
    for i = #parentTransforms, 1, -1 do
        local transform = parentTransforms[i]
        
        localRect.x = localRect.x + transform.size.X * transform.pivot.X - transform.position.X
        localRect.y = localRect.y + transform.size.Y * transform.pivot.Y - transform.position.Y
        
        localRect.x = localRect.x / transform.scale.X
        localRect.y = localRect.y / transform.scale.Y
        localRect.width = localRect.width / transform.scale.X
        localRect.height = localRect.height / transform.scale.Y
    end
    
    local pivot = control.Pivot
    control.Position = Vector2.New(localRect.x + localRect.width * pivot.X, 
                                 localRect.y + localRect.height * pivot.Y)
    control.Size = Vector2.New(localRect.width, localRect.height)
end

--获取屏幕位置X
function UIHelper:GetScreenPositionX(control)
    local pos = self:GetScreenPosition(control)
    return pos.x
end

--设置屏幕位置X
function UIHelper:SetScreenPositionX(control, x)
    local pos = self:GetScreenPosition(control)
    pos.x = x
    self:SetScreenPosition(control, pos)
end

--获取屏幕位置Y
function UIHelper:GetScreenPositionY(control)
    local pos = self:GetScreenPosition(control)
    return pos.y
end

--设置屏幕位置Y
function UIHelper:SetScreenPositionY(control, y)
    local pos = self:GetScreenPosition(control)
    pos.y = y
    self:SetScreenPosition(control, pos)
end

--获取父节点屏幕尺寸
function UIHelper:GetParentScreenSize(control)
    local parent = control.Parent
    if not parent then
        UILog:Error("GetParentScreenSize: parent is nil")
        return self:GetViewportSize()
    end

    return self:GetScreenSize(parent)
end

--获取屏幕尺寸
function UIHelper:GetScreenSize(control)
    local size = control.Size
    local screenSize = Vec2.New(size.X, size.Y)
    
    -- 遍历所有父节点，累积缩放
    local currentControl = control
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parent = currentControl.Parent
        local parentScale = parent.Scale
        
        -- 应用父节点缩放
        screenSize.x = screenSize.x * parentScale.X
        screenSize.y = screenSize.y * parentScale.Y
        
        currentControl = parent
    end
    
    return screenSize
end

--设置屏幕尺寸
function UIHelper:SetScreenSize(control, size)
    local currentControl = control
    local parentScales = {}
    
    -- 收集所有父节点的缩放
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parent = currentControl.Parent
        table.insert(parentScales, parent.Scale)
        currentControl = parent
    end
    
    -- 从后往前应用缩放的逆运算
    for i = #parentScales, 1, -1 do
        local scale = parentScales[i]
        size.x = size.x / scale.X
        size.y = size.y / scale.Y
    end
    
    -- 设置最终的本地尺寸
    control.Size = Vector2.New(size.x, size.y)
end

--获取屏幕宽度
function UIHelper:GetScreenWidth(control)
    return self:GetScreenSize(control).x
end

--设置屏幕宽度
function UIHelper:SetScreenWidth(control, width)
    local size = self:GetScreenSize(control)
    size.x = width
    self:SetScreenSize(control, size)
end

--获取屏幕高度
function UIHelper:GetScreenHeight(control)
    return self:GetScreenSize(control).y
end

--设置屏幕高度
function UIHelper:SetScreenHeight(control, height)
    local size = self:GetScreenSize(control)
    size.y = height
    self:SetScreenSize(control, size)
end

--设置全屏
function UIHelper:SetFullScreenSize(control)
    local viewportSize = self:GetViewportSize()
    local pivot = control.Pivot
    
    -- Get the cumulative parent scale to adjust the size accordingly
    local currentControl = control
    local scaleX, scaleY = 1, 1
    while currentControl.Parent and currentControl.Parent.ClassType ~= "UIRoot" do
        local parentScale = currentControl.Parent.Scale
        scaleX = scaleX * parentScale.X
        scaleY = scaleY * parentScale.Y
        currentControl = currentControl.Parent
    end
    
    -- Adjust size based on parent scales
    control.Size = Vector2.New(viewportSize.x / scaleX, viewportSize.y / scaleY)
    control.Position = Vector2.New((viewportSize.x / scaleX) * pivot.X, (viewportSize.y / scaleY) * pivot.Y)
end

--设置拉伸X
function UIHelper:SetStretchX(control, stretchX)
    if not control then
        UILog:Error("SetStretchX: control is nil")
        return
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    control.Size = Vector2.New(parentScreenRect.width * stretchX, control.Size.Y)
end

--获取拉伸X 
function UIHelper:GetStretchX(control)
    if not control then
        UILog:Error("GetStretchX: control is nil")
        return 0
    end
    return control.Size.X / self:GetParentScreenRect(control).width
end

--设置拉伸Y
function UIHelper:SetStretchY(control, stretchY)
    if not control then
        UILog:Error("SetStretchY: control is nil")
        return
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    control.Size = Vector2.New(control.Size.X, parentScreenRect.height * stretchY)
end

--获取拉伸Y
function UIHelper:GetStretchY(control)
    if not control then
        UILog:Error("GetStretchY: control is nil")
        return 0
    end
    return control.Size.Y / self:GetParentScreenRect(control).height
end

--设置拉伸
function UIHelper:SetStretch(control, stretchX, stretchY)
    if not control then
        UILog:Error("SetStretch: control is nil")
        return
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    control.Size = Vector2.New(parentScreenRect.width * stretchX, parentScreenRect.height * stretchY)
end

--获取拉伸
function UIHelper:GetStretch(control)
    if not control then
        UILog:Error("GetStretch: control is nil")
        return 0, 0
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    return control.Size.X / parentScreenRect.width, control.Size.Y / parentScreenRect.height
end

--设置锚点X
function UIHelper:SetAnchorX(control, anchorX)
    if not control then
        UILog:Error("SetAnchorX: control is nil")
        return
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    control.Position = Vector2.New(parentScreenRect.width * anchorX, control.Position.Y)
end

--获取锚点X
function UIHelper:GetAnchorX(control)
    if not control then
        UILog:Error("GetAnchorX: control is nil")
        return 0
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    return control.Position.X / parentScreenRect.width
end

--设置锚点Y
function UIHelper:SetAnchorY(control, anchorY)
    if not control then
        UILog:Error("SetAnchorY: control is nil")
        return
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    control.Position = Vector2.New(control.Position.X, parentScreenRect.height * anchorY)
end

--获取锚点Y
function UIHelper:GetAnchorY(control)   
    if not control then
        UILog:Error("GetAnchorY: control is nil")
        return 0
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    return control.Position.Y / parentScreenRect.height
end 

--设置锚点
function UIHelper:SetAnchor(control, anchorX, anchorY)
    if not control then
        UILog:Error("SetAnchor: control is nil")
        return
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    control.Position = Vector2.New(parentScreenRect.width * anchorX, parentScreenRect.height * anchorY)
end

--获取锚点
function UIHelper:GetAnchor(control)
    if not control then
        UILog:Error("GetAnchor: control is nil")
        return 0, 0
    end
    local parentScreenRect = self:GetParentScreenRect(control)
    return control.Position.X / parentScreenRect.width, control.Position.Y / parentScreenRect.height
end

--设置中间X
function UIHelper:CenterX(control)
    local parentScreenRect = self:GetParentScreenRect(control)
    local centerX = parentScreenRect.width / 2
    local pivot = control.Pivot
    local size = control.Size
    centerX = centerX - size.X * 0.5
    self:SetLeftTopCorner(control, Vec2.New(centerX, control.Position.Y))
end

--设置中间Y
function UIHelper:CenterY(control)
    local parentScreenRect = self:GetParentScreenRect(control)
    local centerY = parentScreenRect.height / 2
    local pivot = control.Pivot
    local size = control.Size
    centerY = centerY - size.Y * 0.5
    self:SetLeftTopCorner(control, Vec2.New(control.Position.X, centerY))
end

--设置中间
function UIHelper:Center(control)
    local parentScreenRect = self:GetParentScreenRect(control)
    local centerX = parentScreenRect.width / 2
    local centerY = parentScreenRect.height / 2
    local pivot = control.Pivot
    local size = control.Size
    centerX = centerX - size.X * 0.5
    centerY = centerY - size.Y * 0.5
    self:SetLeftTopCorner(control, Vec2.New(centerX, centerY))
end

--设置位置
function UIHelper:SetPosition(control, position)
    if not control then
        UILog:Error("SetPosition: control is nil")
        return
    end
    control.Position = Vector2.New(position.x, position.y)
end

function UIHelper:GetPosition(control)
    if not control then
        UILog:Error("GetPosition: control is nil")
        return
    end
    local position = control.Position
    return Vec2.New(position.X, position.Y)
end

--设置左上角
function UIHelper:SetLeftTopCorner(control, leftTopCorner)
    if not control then
        UILog:Error("SetLeftTopCorner: control is nil")
        return
    end
    local size = control.Size
    local pivot = control.Pivot
    control.Position = Vector2.New(
        leftTopCorner.x + size.X * pivot.X,
        leftTopCorner.y + size.Y * pivot.Y
    )
end

--获取左上角
function UIHelper:GetLeftTopCorner(control)
    if not control then
        UILog:Error("GetLeftTopCorner: control is nil")
        return
    end
    local position = control.Position
    local size = control.Size
    local pivot = control.Pivot
    return Vec2.New(
        position.X - size.X * pivot.X,
        position.Y - size.Y * pivot.Y
    )
end

--设置右上角
function UIHelper:SetRightTopCorner(control, rightTopCorner)
    if not control then
        UILog:Error("SetRightTopCorner: control is nil")
        return
    end
    local size = control.Size
    local pivot = control.Pivot
    control.Position = Vector2.New(
        rightTopCorner.x - size.X * pivot.X,
        rightTopCorner.y - size.Y * pivot.Y
    )
end

--获取右上角
function UIHelper:GetRightTopCorner(control)
    if not control then     
        UILog:Error("GetRightTopCorner: control is nil")
        return
    end
    local position = control.Position
    local size = control.Size
    local pivot = control.Pivot
    return Vec2.New(
        position.X + size.X * (1 - pivot.X),
        position.Y - size.Y * pivot.Y
    )
end

--设置左下角
function UIHelper:SetLeftBottomCorner(control, leftBottomCorner)
    if not control then
        UILog:Error("SetLeftBottomCorner: control is nil")
        return
    end
    local size = control.Size
    local pivot = control.Pivot
    control.Position = Vector2.New(
        leftBottomCorner.x + size.X * pivot.X,
        leftBottomCorner.y - size.Y * pivot.Y
    )
end

--获取左下角
function UIHelper:GetLeftBottomCorner(control)  
    if not control then
        UILog:Error("GetLeftBottomCorner: control is nil")
        return
    end
    local position = control.Position
    local size = control.Size
    local pivot = control.Pivot
    return Vec2.New(    
        position.X - size.X * pivot.X,
        position.Y + size.Y * (1 - pivot.Y)
    )
end

--设置右下角
function UIHelper:SetRightBottomCorner(control, rightBottomCorner)
    if not control then
        UILog:Error("SetRightBottomCorner: control is nil")
        return
    end
    local size = control.Size
    local pivot = control.Pivot
    control.Position = Vector2.New(
        rightBottomCorner.x - size.X * pivot.X,
        rightBottomCorner.y - size.Y * pivot.Y
    )
end

--获取右下角
function UIHelper:GetRightBottomCorner(control)
    if not control then
        UILog:Error("GetRightBottomCorner: control is nil")
        return
    end
    local position = control.Position
    local size = control.Size
    local pivot = control.Pivot
    return Vec2.New(
        position.X + size.X * (1 - pivot.X),
        position.Y + size.Y * (1 - pivot.Y)
    )
end



--设置大小
function UIHelper:SetSize(control, size)
    if not control then
        UILog:Error("SetSize: control is nil")
        return
    end
    control.Size = Vector2.New(size.x, size.y)
end

function UIHelper:GetSize(control)
    if not control then
        UILog:Error("GetSize: control is nil")
        return
    end
    local size = control.Size
    return Vec2.New(size.X, size.Y)
end

--获取宽度
function UIHelper:GetWidth(control)
    if not control then
        UILog:Error("GetWidth: control is nil")
        return
    end
    return control.Size.X
end

--获取高度
function UIHelper:GetHeight(control)
    if not control then
        UILog:Error("GetHeight: control is nil")
        return
    end
    return control.Size.Y
end

--设置Pivot
function UIHelper:SetPivot(control, pivot)
    if not control then
        UILog:Error("SetPivot: control is nil")
        return
    end
    control.Pivot = Vector2.New(pivot.x, pivot.y)
end

function UIHelper:GetPivot(control)
    if not control then
        UILog:Error("GetPivot: control is nil")
        return
    end 
    local pivot = control.Pivot
    return Vec2.New(pivot.X, pivot.Y)
end

--获取锚点在点上的位置
function UIHelper:GetPivotPoint(control)
    if not control then
        UILog:Error("GetPivotPoint: control is nil")
        return
    end
    local pivot = control.Pivot
    local size = control.Size
    return Vec2.New(pivot.X * size.X, pivot.Y * size.Y)
end

--设置旋转
function UIHelper:SetRotation(control, rotation)
    if not control then
        UILog:Error("SetRotation: control is nil")
        return
    end
    control.Rotation = rotation
end

function UIHelper:GetRotation(control)
    if not control then
        UILog:Error("GetRotation: control is nil")
        return
    end
    return control.Rotation
end

--设置缩放
function UIHelper:SetScale(control, scale)
    if not control then
        UILog:Error("SetScale: control is nil")
        return
    end
    local scaleX = 1
    local scaleY = 1
    if type(scale) == "number" then
        scaleX = scale
        scaleY = scale
    elseif type(scale) == "table" then
        scaleX = scale.x
        scaleY = scale.y
    end
    control.Scale = Vector2.New(scaleX, scaleY)
end

function UIHelper:GetScale(control)
    if not control then
        UILog:Error("GetScale: control is nil")
        return
    end
    local scale = control.Scale
    return Vec2.New(scale.X, scale.Y)
end

--设置可见性
function UIHelper:SetVisible(control, visible)
    if not control then
        UILog:Error("SetVisible: control is nil")
        return
    end
    control.Visible = visible
end

function UIHelper:IsVisible(control)
    if not control then
        UILog:Error("IsVisible: control is nil")
        return
    end
    return control.Visible
end

--是否在可见层级中
function UIHelper:IsVisibleInHierarchy(control)
    if not control then
        UILog:Error("IsVisibleInHierarchy: control is nil")
        return
    end
    local parent = control
    while parent and parent.ClassType ~= "UIRoot" do
        if not parent.Visible then
            return false
        end
        parent = parent.Parent
    end
    return true
end

function UIHelper:SetRenderIndex(control, renderIndex)
    if not control then
        UILog:Error("SetRenderIndex: control is nil")
        return
    end
    control.RenderIndex = renderIndex
end

function UIHelper:SetFontSize(control, fontSize)
    if not control then
        UILog:Error("SetFontSize: control is nil")
        return
    end
    control.FontSize = fontSize
end

function UIHelper:SetBMText(control, text)
    if not control then
        UILog:Error("SetBMText: control is nil")
        return
    end
    control.BMText = text
end

function UIHelper:SetBMFonts(control, fonts)
    if not control then
        UILog:Error("SetBMFonts: control is nil")
        return
    end
    control.BMFonts = fonts
end

function UIHelper:SetBMPng(control, png)
    if not control then
        UILog:Error("SetBMPng: control is nil")
        return
    end
    control.BMPng = png
end

--计算吸附矩形
--size: 大小
--pivot: 锚点
--offset: 偏移
--anchor: 吸附点，0-1之间，x为水平吸附点，y为垂直吸附点，0为左上角，1为右下角
function UIHelper:CalculateAnchoredRect(control, size, pivot, offset, anchor)
    local rect = self:GetScreenRect(control)
    local anchorPoint = rect:GetAnchorPoint(anchor)
    anchorPoint = anchorPoint + offset
    local rect = Rect.New(anchorPoint.x, anchorPoint.y, size.x, size.y)
    rect:ApplyPivot(pivot)
    return rect
end

--布局起点转换为锚点
function UIHelper:LayoutOriginToAnchor(layoutOrigin)
    local anchor = Vec2.New(0, 0)
    if string.find(layoutOrigin, "Center") then
        anchor.y = 0.5
    elseif string.find(layoutOrigin, "Right") then
        anchor.x = 1
    end
    
    if string.find(layoutOrigin, "Middle") then
        anchor.y = 0.5
    elseif string.find(layoutOrigin, "Bottom") then
        anchor.y = 1
    end
    return anchor
end


--适应大小
--expandX: 扩展x
--expandY: 扩展y
--minWidth: 最小宽度
--minHeight: 最小高度
function UIHelper:FitSize(control, expandX, expandY, minWidth, minHeight)
    expandX = expandX or 0
    expandY = expandY or 0
    local childrenRect, childrenRects = self:CalculateChildrenScreenRect(control)
    childrenRect:Expand(expandX, expandY)

    local stretchX = 0
    local stretchY = 0
    if minWidth then
        if childrenRect.width < minWidth then
            stretchX = (minWidth - childrenRect.width) / 2
        end
    end
    if minHeight then
        if childrenRect.height < minHeight then
            stretchY = (minHeight - childrenRect.height) / 2
        end
    end
    childrenRect:Stretch(stretchX, stretchY, stretchX, stretchY)

    self:SetScreenRect(control, childrenRect)

    for index, child in ipairs(control.Children) do
        local childRect = childrenRects[index]
        if childRect then
            UIHelper:SetScreenRect(child, childRect)
        end
    end
    return childrenRect
end

--调整大小并扩展目标
function UIHelper:ResizeAndExpandTarget(control, size, pivot, targetControl)
    local rect = self:GetScreenRect(control)
    local targetRect = self:GetScreenRect(targetControl)
    local offsets = targetRect:CalculateCornerOffsets(rect)
    self:Resize(control, size, pivot)
    local newRect = self:GetScreenRect(control)
    newRect:StretchByCornerOffsets(offsets)
    self:SetScreenRect(targetControl, newRect)
end

--调整大小
function UIHelper:Resize(control, size, pivot)
    local rect = self:GetScreenRect(control)
    rect:Resize(size.x, size.y, pivot.x, pivot.y)
    self:SetScreenRect(control, rect)
end

--计算子控件矩形
function UIHelper:CalculateChildrenScreenRect(control)
    local childrenRect = nil
    local childrenRects = {}
    
    if #control.Children == 0 then
        local pos = self:GetScreenPosition(control)
        return Rect.New(pos.x, pos.y, 0, 0), childrenRects
    end
    
    for _, child in ipairs(control.Children) do
        if child.Visible then
            local childRect = self:GetScreenRect(child)
            if not childrenRect then
                childrenRect = Rect.New(childRect.x, childRect.y, childRect.width, childRect.height)
            else
                local minX = math.min(childrenRect.x, childRect.x)
                local minY = math.min(childrenRect.y, childRect.y)
                local maxX = math.max(childrenRect.x + childrenRect.width, childRect.x + childRect.width)
                local maxY = math.max(childrenRect.y + childrenRect.height, childRect.y + childRect.height)
                
                childrenRect.x = minX
                childrenRect.y = minY
                childrenRect.width = maxX - minX
                childrenRect.height = maxY - minY
            end
            table.insert(childrenRects, childRect)
        end
    end
    
    return childrenRect, childrenRects
end

--设置锚点预设
function UIHelper:SetAnchorPreset(control, anchorPreset, keepPosition)
    keepPosition = keepPosition or true
    local anchor = UIDefines.EAnchorPreset[anchorPreset]
    if not anchor then
        UILog:Error("SetAnchorPreset: anchorPreset is nil")
        return
    end
    if not control then
        UILog:Error("SetAnchorPreset: control is nil")
        return
    end
    local screenPos = nil
    if keepPosition then
        screenPos = self:GetScreenPosition(control)
    end
    if anchor == UIDefines.EAnchorPreset.LeftTop then
        self:SetAnchor(control, Vec2.New(0, 0))
        self:SetPivot(control, Vec2.New(0, 0))
    elseif anchor == UIDefines.EAnchorPreset.CenterTop then
        self:SetAnchor(control, Vec2.New(0.5, 0))
        self:SetPivot(control, Vec2.New(0.5, 0))
    elseif anchor == UIDefines.EAnchorPreset.RightTop then
        self:SetAnchor(control, Vec2.New(1, 0))
        self:SetPivot(control, Vec2.New(1, 0))
    elseif anchor == UIDefines.EAnchorPreset.LeftMiddle then
        self:SetAnchor(control, Vec2.New(0, 0.5))
        self:SetPivot(control, Vec2.New(0, 0.5))
    elseif anchor == UIDefines.EAnchorPreset.CenterMiddle then
        self:SetAnchor(control, Vec2.New(0.5, 0.5))
        self:SetPivot(control, Vec2.New(0.5, 0.5))
    elseif anchor == UIDefines.EAnchorPreset.RightMiddle then
        self:SetAnchor(control, Vec2.New(1, 0.5))
        self:SetPivot(control, Vec2.New(1, 0.5))
    elseif anchor == UIDefines.EAnchorPreset.LeftBottom then
        self:SetAnchor(control, Vec2.New(0, 1))
        self:SetPivot(control, Vec2.New(0, 1))
    elseif anchor == UIDefines.EAnchorPreset.CenterBottom then
        self:SetAnchor(control, Vec2.New(0.5, 1))
        self:SetPivot(control, Vec2.New(0.5, 1))
    elseif anchor == UIDefines.EAnchorPreset.RightBottom then
        self:SetAnchor(control, Vec2.New(1, 1))
        self:SetPivot(control, Vec2.New(1, 1))
    end
    if screenPos then
        self:SetScreenPosition(control, screenPos)
    end
end

--计算圆上位置
function UIHelper:CalculateCirclePos(width, height, angle)
    local angleRad = math.rad(angle) -- 将角度转换为弧度
    angleRad = angleRad - math.pi / 2
    local x = width * math.cos(angleRad)
    local y = height * math.sin(angleRad)
    return Vec2.New(x, y)
end

--将屏幕位置转换为本地位置
function UIHelper:ToLocalPosition(control, screenPos)
    local parent = control.Parent
    if not parent then
        return screenPos
    end
    
    local parentScreenPos = self:GetScreenPosition(parent)
    
    local parentScaleX, parentScaleY = self:GetScreenScale(parent)
    
    local localPos = Vec2.New(
        (screenPos.x - parentScreenPos.x) / parentScaleX,
        (screenPos.y - parentScreenPos.y) / parentScaleY
    )
    
    return localPos
end

--将本地位置转换为屏幕位置
function UIHelper:ToScreenPosition(control, localPos)
    local parent = control.Parent
    if not parent then
        return localPos
    end
    
    local parentScreenPos = self:GetScreenPosition(parent)
    
    local parentScaleX, parentScaleY = self:GetScreenScale(parent)
    
    local screenPos = Vec2.New(
        localPos.x * parentScaleX + parentScreenPos.x,
        localPos.y * parentScaleY + parentScreenPos.y
    )
    
    return screenPos
end

--计算文本大小
function UIHelper:CalculateTextSize(control, singleLine)
    singleLine = singleLine or false
    local screenRect = self:GetScreenRect(control)
    local autoSize = control.IsAutoSize
    if not singleLine then
        control.IsAutoSize = Enum.AutoSizeType.HEIGHT
    else
        control.IsAutoSize = Enum.AutoSizeType.BOTH
    end
    local size = self:GetSize(control)
    control.IsAutoSize = autoSize
    self:SetScreenRect(control, screenRect)
    return size
end

function UIHelper:GetNativeSize(control, singleLine)
    singleLine = singleLine or false
    if not control then
        UILog:Error("GetNativeSize: control is nil")
        return
    end
    if control.ResourceSize then
        local size = control.ResourceSize
        local designScale = self:GetDesignScale()
        local nativeSize = Vec2.New(size.x * designScale.x, size.y * designScale.y)
        return nativeSize
    elseif control.Title then
        local size = self:CalculateTextSize(control, singleLine)
        return size
    end
    return Vec2.New(0, 0)
end

--设置控件大小为原始大小
function UIHelper:SetNativeSize(control, keepPosition, singleLine)
    singleLine = singleLine or false
    if not control then
        UILog:Error("SetNativeSize: control is nil")
        return
    end
    local leftTopCorner = nil
    if keepPosition then
        leftTopCorner = self:GetLeftTopCorner(control)
    end
    local nativeSize = self:GetNativeSize(control, singleLine)
    self:SetSize(control, nativeSize)
    if leftTopCorner then
        self:SetLeftTopCorner(control, leftTopCorner)
    end
end

--设置所有子控件的原始大小
function UIHelper:SetChildrenNativeSize(control, keepPosition, singleLine)
    singleLine = singleLine or false
    if not control then
        UILog:Error("SetChildrenNativeSize: control is nil")
        return
    end
    local children = control.Children
    for _, child in ipairs(children) do
        self:SetNativeSize(child, keepPosition, singleLine)
    end
end

--对齐控件
--control: 控件
--targetControl: 目标控件
--pivot: 锚点
--offset: 偏移
--anchor: 吸附点，0-1之间，x为水平吸附点，y为垂直吸附点，0为左上角，1为右下角
function UIHelper:Align(control, targetControl, pivot, offset, anchor)
    if not targetControl then
        UILog:Error("Align: targetControl is nil")
        return
    end
    local size = UIHelper:GetSize(control)
    local anchoredRect = UIHelper:CalculateAnchoredRect(targetControl, size, pivot, offset, anchor)
    local selfPivot = UIHelper:GetPivot(control)
    anchoredRect:Move(size.x * selfPivot.x, size.y * selfPivot.y)
    self:SetScreenRect(control, anchoredRect)
end

--对齐链
--controls: 控件列表
--pivot: 锚点
--offset: 偏移
--anchor: 吸附点，0-1之间，x为水平吸附点，y为垂直吸附点，0为左上角，1为右下角
function UIHelper:AlignChain(controls, firstPivot, firstOffset, firstAnchor, otherPivot, otherOffset, otherAnchor)
    if not controls then
        UILog:Error("AlignChain: controls is nil")
        return
    end

    local visibleControls = {}
    for _, control in ipairs(controls) do
        if control.Visible then
            table.insert(visibleControls, control)
        end
    end

    if #visibleControls < 2 then
        UILog:Error("AlignChain: controls count is less than 2")
        return
    end
    for i = 2, #visibleControls do
        local control = visibleControls[i]
        local targetControl = visibleControls[i - 1]
        if i == 2 then
            self:Align(control, targetControl, firstPivot, firstOffset, firstAnchor)
        else
            self:Align(control, targetControl, otherPivot, otherOffset, otherAnchor)
        end
    end
end

--水平左对齐
function UIHelper:HLAlign(control, targetControl)
    if not targetControl then
        UILog:Error("HLAlign: targetControl is nil")
        return
    end
    local pos = self:GetScreenPosition(control)
    local targetPos = self:GetScreenPosition(targetControl)
    self:SetScreenPosition(control, Vec2.New(targetPos.x, pos.y))
end

function UIHelper:HCAlign(control, targetControl)
    if not targetControl then
        UILog:Error("HCAlign: targetControl is nil")
        return
    end
    local rect = self:GetScreenRect(control)
    local targetRect = self:GetScreenRect(targetControl)
    self:SetScreenPosition(control, Vec2.New(targetRect:GetCenterX() - rect:GetWidth() / 2, rect.y))
end

function UIHelper:HRAlign(control, targetControl, pivot, offset, anchor)
    if not targetControl then
        UILog:Error("HRAlign: targetControl is nil")
        return
    end
    local rect = self:GetScreenRect(control)
    local targetRect = self:GetScreenRect(targetControl)
    self:SetScreenPosition(control, Vec2.New(targetRect:GetRight() - rect:GetWidth(), rect.y))
end

--纵向顶部对齐
function UIHelper:VTAlign(control, targetControl)
    if not targetControl then
        UILog:Error("VTAlign: targetControl is nil")
        return
    end
    local pos = self:GetScreenPosition(control)
    local targetPos = self:GetScreenPosition(targetControl)
    self:SetScreenPosition(control, Vec2.New(pos.x, targetPos.y))
end

--纵向居中对齐
function UIHelper:VCAlign(control, targetControl)   
    if not targetControl then
        UILog:Error("VCAlign: targetControl is nil")
        return
    end
    local rect = self:GetScreenRect(control)
    local targetRect = self:GetScreenRect(targetControl)
    self:SetScreenPosition(control, Vec2.New(rect.x, targetRect:GetCenterY() - rect:GetHeight() / 2))
end

--纵向底部对齐
function UIHelper:VBAlign(control, targetControl)
    if not targetControl then
        UILog:Error("VBAlign: targetControl is nil")
        return
    end
    local rect = self:GetScreenRect(control)
    local targetRect = self:GetScreenRect(targetControl)
    self:SetScreenPosition(control, Vec2.New(rect.x, targetRect:GetBottom() - rect:GetHeight()))
end

--纵向顶部对齐子控件
function UIHelper:VTAlignChildren(control)
    if not control then
        UILog:Error("VTAlignChildren: control is nil")
        return
    end
    local children = control.Children
    if #children > 1 then
        local firstChild = children[1]
        for i = 2, #children do
            local child = children[i]
            self:VTAlign(child, firstChild)
        end
    end
end

--纵向居中对齐子控件
function UIHelper:VCAlignChildren(control)
    if not control then
        UILog:Error("VCAlignChildren: control is nil")
        return
    end
    local children = control.Children
    if #children > 1 then
        local firstChild = children[1]
        for i = 2, #children do
            local child = children[i]
            self:VCAlign(child, firstChild)
        end
    end
end

--纵向底部对齐子控件
function UIHelper:VBAlignChildren(control)
    if not control then
        UILog:Error("VBAlignChildren: control is nil")
        return
    end
    local children = control.Children
    if #children > 1 then
        local firstChild = children[1]
        for i = 2, #children do
            local child = children[i]
            self:VBAlign(child, firstChild)
        end
    end
end

--加载图片
function UIHelper:LoadImage(control, imagePath, callback)
    if not control then
        UILog:Error("LoadImage: control is nil")
        return
    end
    if not imagePath then
        UILog:Error("LoadImage: imagePath is nil")
        return
    end
    UIResource:Load(imagePath, "Texture", function(success, res)
        if success then
            control.Icon = imagePath
            if callback then
                callback(true, control, res)
            end
        else
            if callback then
                callback(false, control, res)
            end
        end
    end)
end

--计算本地矩形
--anchoredPosition: 锚点位置
--sizeDelta: 尺寸偏移
--anchorMin: 锚点最小值
--anchorMax: 锚点最大值
--pivot: 锚点
--offsetMin: 偏移最小值
--offsetMax: 偏移最大值
--localScale: 本地缩放
--parentWidth: 父宽度
--parentHeight: 父高度
function UIHelper:CalculateLocalRect(anchoredPosition, sizeDelta, anchorMin, anchorMax, pivot, offsetMin, offsetMax, localScale, 
    parentWidth, parentHeight, isLeftTopSpace)
    -- 检查是否为单点锚点
    local isPointAnchor = anchorMin:Equals(anchorMax)
    
    -- 计算锚点位置
    local anchorPosX = parentWidth * anchorMin.x
    local anchorPosY = parentHeight * anchorMin.y
    
    -- 计算尺寸
    local width, height
    
    if isPointAnchor then
        -- 单点锚点：尺寸直接来自sizeDelta
        width = sizeDelta.x * localScale.x
        height = sizeDelta.y * localScale.y
    else
        local minPos = anchorMin * Vec2.New(parentWidth, parentHeight) + offsetMin
        local maxPos = anchorMax * Vec2.New(parentWidth, parentHeight) + offsetMax
        width = maxPos.x - minPos.x
        height = maxPos.y - minPos.y
    end
    
    -- 计算位置
    local x, y
    
    if isPointAnchor then
        x = anchorPosX + anchoredPosition.x * localScale.x - width * pivot.x
        y = anchorPosY + anchoredPosition.y * localScale.y - height * pivot.y
    else
        x = anchorPosX + anchoredPosition.x * localScale.x + offsetMin.x
        y = anchorPosY + anchoredPosition.y * localScale.y + offsetMin.y
    end

    if isLeftTopSpace then
        y = parentHeight - y - height
    end
    
    -- 直接返回计算出的四个值
    return x, y, width, height
end

--------------------------------------------Action--------------------------------------------
--运行动作
function UIHelper:RunAction(control, action)
    UIActionRunner:RunAction(control,action)
end
--根据Tag获取动作
function UIHelper:GetActionByTag(control, tag)
    return UIActionRunner:GetActionByTag(control,tag)
end

--根据Tag停止动作
function UIHelper:StopActionByTag(control, tag)
    UIActionRunner:StopActionByTag(control,tag)
end

--根据Tag获取Action的数量
function UIHelper:CountActionByTag(control, tag)
    return UIActionRunner:CountActionByTag(control,tag)
end

--停止所有动作
function UIHelper:StopAllActions(control)
    UIActionRunner:StopAllActions(control)
end

--屏幕坐标转换为本地坐标
function UIHelper:MapScreenToLocal(control, screenPos)
    local mapPos = self:GetScreenPosition(control)
    return screenPos - mapPos
end

--本地坐标转换为屏幕坐标
function UIHelper:MapLocalToScreen(control, localPos)
    local mapPos = self:GetScreenPosition(control)
    return localPos + mapPos
end

return UIHelper



