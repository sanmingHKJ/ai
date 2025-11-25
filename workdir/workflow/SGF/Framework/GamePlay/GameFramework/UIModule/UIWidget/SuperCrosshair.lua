-- 说明:十字准星控件
-- 日期:2025年3月15日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local UIUtils = GFScript("UIModule.UIUtils")
local UISettings = GFScript("UIModule.UISettings")
local SuperCrosshair = UIClass.New("SuperCrosshair", UIWidget)


function SuperCrosshair:Constructor()
    self.left = nil
    self.right = nil
    self.top = nil
    self.bottom = nil

    --十字准星的宽度
    self.width = 0
    --十字准星的高度
    self.height = 0

    --半径
    self.radius = 0
    --当前喷射的子弹数量
    self.currentSpray = 0
    --最大喷射的子弹数量
    self.maxSpray = 0

    --旋转角度
    self.rotation = 0
end

function SuperCrosshair:Destructor()
    if self.left then
        self.left:Destroy()
        self.left = nil
    end
    if self.right then
        self.right:Destroy()
        self.right = nil
    end
    if self.top then
        self.top:Destroy()
        self.top = nil
    end
    if self.bottom then
        self.bottom:Destroy()
        self.bottom = nil
    end
end

--初始化
function SuperCrosshair:Init(bindObj)
    if not SuperCrosshair.super.Init(self, bindObj) then
        return false
    end

    local function CreateLine(name, width, height, pivot, rotation)
        local line = SandboxNode.New("UIImage")
        line.Name = name
        line.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        line.Parent = self.bindObj
        line.Pivot = pivot
        line.Position  = Vector2.New(0, 0)
        line.Size  = Vector2.New(width, height)
        line.Active = false
        line.Rotation = rotation
        line.Scale = Vector2.New(1.0, 1.0)
        line.Icon = UIUtils:FullSpritePath(UISettings:GetGenericWhiteSprite())
        return line
    end

    self.left = CreateLine("Left", self.width, self.height, Vector2.New(0.5, 1.0), -90)
    self.right = CreateLine("Right", self.width, self.height, Vector2.New(0.5, 1.0), 90)
    self.top = CreateLine("Top", self.width, self.height, Vector2.New(0.5, 1), 0)
    self.bottom = CreateLine("Bottom", self.width, self.height, Vector2.New(0.5, 0), 0)
    
    self:UpdateLinesRotation()
    self:UpdateLinesPosition()
    self:UpdateLinesSize()

    return true
end

--设置线条的精灵
function SuperCrosshair:SetSprite(sprite)
    self.left.Icon = sprite
    self.right.Icon = sprite
    self.top.Icon = sprite
    self.bottom.Icon = sprite
end

function SuperCrosshair:SetScale(scale)
    self.left.Scale = Vector2.New(scale, scale)
    self.right.Scale = Vector2.New(scale, scale)
    self.top.Scale = Vector2.New(scale, scale)
    self.bottom.Scale = Vector2.New(scale, scale)
end

--更新十字准星的线条位置
function SuperCrosshair:UpdateLinesPosition()
    local size = self:GetSize()
    local halfWidth = size.x / 2
    local halfHeight = size.y / 2

    -- local radius = math.min(self.radius + self.currentSpray, self.radius + self.maxSpray)
    local radius = self.radius + self.currentSpray
    
    -- 将角度转换为弧度
    local angleRad = math.rad(self.rotation)
    local cosAngle = math.cos(angleRad)
    local sinAngle = math.sin(angleRad)
    
    -- 计算旋转后的位置
    -- 左线位置：(-radius, 0) 旋转后的坐标
    local leftX = -radius * cosAngle + halfWidth
    local leftY = -radius * sinAngle + halfHeight
    self.left.Position = Vector2.New(leftX, leftY)
    
    -- 右线位置：(radius, 0) 旋转后的坐标
    local rightX = radius * cosAngle + halfWidth
    local rightY = radius * sinAngle + halfHeight
    self.right.Position = Vector2.New(rightX, rightY)
    
    -- 上线位置：(0, -radius) 旋转后的坐标
    local topX = radius * sinAngle + halfWidth
    local topY = -radius * cosAngle + halfHeight
    self.top.Position = Vector2.New(topX, topY)
    
    -- 下线位置：(0, radius) 旋转后的坐标
    local bottomX = -radius * sinAngle + halfWidth
    local bottomY = radius * cosAngle + halfHeight
    self.bottom.Position = Vector2.New(bottomX, bottomY)
end

--设置半径
function SuperCrosshair:SetRadius(radius)
    self.radius = radius
    self:UpdateLinesPosition()
end

--设置宽度
function SuperCrosshair:SetWidth(width)
    self.width = width
    self:UpdateLinesSize()
end

--设置高度
function SuperCrosshair:SetHeight(height)
    self.height = height
    self:UpdateLinesSize()
end

--设置旋转角度
function SuperCrosshair:SetRotation(rotation)
    self.rotation = rotation
    self:UpdateLinesRotation()
    self:UpdateLinesPosition()
end

--更新线条大小
function SuperCrosshair:UpdateLinesSize()
    self.left.Size  = Vector2.New(self.width, self.height)
    self.right.Size  = Vector2.New(self.width, self.height)
    self.top.Size  = Vector2.New(self.width, self.height)
    self.bottom.Size  = Vector2.New(self.width, self.height)
end

--更新线条旋转
function SuperCrosshair:UpdateLinesRotation()
    self.left.Rotation = self.rotation - 90
    self.right.Rotation = self.rotation + 90
    self.top.Rotation = self.rotation
    self.bottom.Rotation = self.rotation
end

--设置当前喷射的子弹数量    
function SuperCrosshair:SetSpray(currentSpray, maxSpray)
    self.currentSpray = currentSpray
    if maxSpray then
        self.maxSpray = maxSpray
    end
    self:UpdateLinesPosition()
end

function SuperCrosshair:SetMaxSpray(maxSpray)
    self.maxSpray = maxSpray
    self:UpdateLinesPosition()
end

function SuperCrosshair:SetVisible(visible)
    self.left.Visible = visible
    self.right.Visible = visible
    self.top.Visible = visible
    self.bottom.Visible = visible
end

return SuperCrosshair