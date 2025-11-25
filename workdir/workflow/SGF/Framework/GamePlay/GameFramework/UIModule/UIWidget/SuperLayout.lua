-- 说明:布局控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local SuperLayout = UIClass.New("SuperLayout", UIWidget)

function SuperLayout:Constructor()
    self.bindObj = nil
    
    -- 内容边距
    self.padding = {left = 0, right = 0, top = 0, bottom = 0}
    -- 项目间距
    self.spacing = {x = 0, y = 0}

    --布局起点：TopLeft(左上), TopCenter(顶部中心), TopRight(右上), 
    --MiddleLeft(左中), MiddleCenter(中心), MiddleRight(右中),
    --BottomLeft(左下), BottomCenter(底部中心), BottomRight(右下)
    self.origin = "TopLeft"

    --布局方向：Horizontal(水平) 或 Vertical(垂直)
    self.direction = "Horizontal"

    --是否反转布局
    self.reverse = false

    -- 是否保持原始大小
    self.keepOriginalSize = true

    -- 换行数量
    self.lineCount = 1

    -- 容器大小
    self.containerWidth = 0
    self.containerHeight = 0

    self.isDirty = false

    -- 焦点节点
    self.focusNode = nil
    --焦点高光背景
    self.focusHighLightBg = nil

end

function SuperLayout:Destructor()
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
function SuperLayout:Init(bindObj)
    if not SuperLayout.super.Init(self, bindObj) then
        return false
    end
    self.containerWidth = self.bindObj.Size.X
    self.containerHeight = self.bindObj.Size.Y

    
    self:EnableUpdate()

    --监听子节点添加函数
    self.notifyChildAddedEvent = self.bindObj.NotifyChildAdded:Connect(function(node)
        self.isDirty = true
    end)
    self.notifyChildRemovedEvent =self.bindObj.NotifyChildRemoved:Connect(function(node)
        self.isDirty = true
    end)
    
    self.isDirty = true

    return true
end

--[[
    更新布局
]]
function SuperLayout:Update(deltaTime)
    -- 检查容器大小是否变化
    if self.bindObj and (self.containerWidth ~= self.bindObj.Size.X or 
                        self.containerHeight ~= self.bindObj.Size.Y) then
        self.containerWidth = self.bindObj.Size.X
        self.containerHeight = self.bindObj.Size.Y
        self.isDirty = true
    end
    
    if self.isDirty then
        self:AdjustLayout()
    end
end

--[[
    刷新布局
]]
function SuperLayout:AdjustLayout()
    if not self.bindObj then return end
    
    local children = self.bindObj.Children
    if #children == 0 then return end
    
    if self.layoutAnimationDuration and self.layoutAnimationEase then
        self:AdjustLayoutChildrenTo(self.origin, self.direction, self.reverse, self.padding, self.spacing, self.lineCount, self.layoutAnimationDuration, self.layoutAnimationEase, function(child)
            self.isDirty = false
        end)
    else
        self:AdjustLayoutChildren(self.origin, self.direction, self.reverse, self.padding, self.spacing, self.lineCount, function(child)
            self.isDirty = false
        end)
    end
end

--[[
    设置内容边距
    @param left: 左边距
    @param right: 右边距
    @param top: 上边距
    @param bottom: 下边距
]]
function SuperLayout:SetPadding(left, right, top, bottom)
    self.padding.left = left or 0
    self.padding.right = right or 0
    self.padding.top = top or 0
    self.padding.bottom = bottom or 0
    self.isDirty = true
end

--获取内容边距
function SuperLayout:GetPadding()
    return self.padding
end

--[[
    设置项目间距
    @param x: 水平间距
    @param y: 垂直间距
]]
function SuperLayout:SetSpacing(x, y)
    self.spacing.x = x or 0
    self.spacing.y = y or 0
    self.isDirty = true
end

--获取项目间距
function SuperLayout:GetSpacing()
    return self.spacing
end

--设置布局起点
function SuperLayout:SetOrigin(origin)
    self.origin = origin or "TopLeft"
    self.isDirty = true
end

--获取布局起点
function SuperLayout:GetOrigin()
    return self.origin
end

--设置布局方向
function SuperLayout:SetDirection(direction)
    self.direction = direction or "Horizontal"
    self.isDirty = true
end

--获取布局方向
function SuperLayout:GetDirection()
    return self.direction
end

--设置是否反转布局
function SuperLayout:SetReverse(reverse)
    self.reverse = reverse or false
    self.isDirty = true
end

--获取是否反转布局
function SuperLayout:IsReverse()
    return self.reverse
end

--[[
    设置布局选项
    @param origin: 布局起点
    @param direction: 布局方向
    @param reverse: 是否反转布局
]]
function SuperLayout:SetOptions(origin, direction, reverse)
    self.origin = origin or "TopLeft"
    self.direction = direction or "Horizontal"
    self.reverse = reverse or false
    self.isDirty = true
end

--[[
    设置是否保持原始大小
    @param keep: 是否保持原始大小
]]
function SuperLayout:SetKeepOriginalSize(keep)
    self.keepOriginalSize = keep
    self.isDirty = true
end

--[[
    设置换行数量
    @param count: 换行数量
]]
function SuperLayout:SetLineCount(count)
    self.lineCount = count
    self.isDirty = true
end

--[[
    设置布局动画
    @param duration: 动画时长
    @param ease: 动画缓动类型
]]
function SuperLayout:EnableLayoutAnimation(duration, ease)
    self.layoutAnimationDuration = duration
    self.layoutAnimationEase = ease
end

--[[
    禁用布局动画
]]
function SuperLayout:DisableLayoutAnimation()
    self.layoutAnimationDuration = nil
    self.layoutAnimationEase = nil
end

return SuperLayout