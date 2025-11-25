local MathDefines = GFScript("CoreModule.Math.MathDefines")
local Vec2 = GFScript("CoreModule.Math.Vec2")
local Rect = {}

--实例化
function Rect.New(x, y, width, height)
    local obj = {}
    obj.x = x or 0
    obj.y = y or 0
    obj.width = width or 0
    obj.height = height or 0
    Rect.__index = Rect
    setmetatable(obj, Rect)
    return obj
end

function Rect.zero()
    return Rect.New(0, 0, 0, 0)
end

function Rect.one()
    return Rect.New(1, 1, 1, 1)
end


---------------------------------运算符重载-------------------------------
--加
function Rect.__add(lhs, rhs)
    return Rect.New(lhs.x + rhs.x, lhs.y + rhs.y, lhs.width + rhs.width, lhs.height + rhs.height)
end

--减
function Rect.__sub(lhs, rhs)
    return Rect.New(lhs.x - rhs.x, lhs.y - rhs.y, lhs.width - rhs.width, lhs.height - rhs.height)
end

--乘
function Rect.__mul(lhs, rhs)
    if rhs == nil then
        return Rect.New(lhs.x, lhs.y, lhs.width, lhs.height)
    end
    if type(lhs) == "number" then
        return Rect.New(lhs * rhs.x, lhs * rhs.y, lhs * rhs.width, lhs * rhs.height)
    elseif type(rhs) == "number" then
        return Rect.New(lhs.x * rhs, lhs.y * rhs, lhs.width * rhs, lhs.height * rhs)
    else
        return Rect.New(lhs.x * rhs.x, lhs.y * rhs.y, lhs.width * rhs.width, lhs.height * rhs.height)
    end
end

--除
function Rect.__div(lhs, rhs)
    if type(rhs) == "number" then
        return Rect.New(lhs.x / rhs, lhs.y / rhs, lhs.width / rhs, lhs.height / rhs)
    else
        return Rect.New(lhs.x / rhs.x, lhs.y / rhs.y, lhs.width / rhs.width, lhs.height / rhs.height)
    end
end

--字符串
function Rect.__tostring(v)
    return string.format("(%f, %f, %f, %f)", v.x, v.y, v.width, v.height)
end

--取元素
function Rect.__index(t, k)
    if k == 1 then
        return t.x
    elseif k == 2 then
        return t.y
    elseif k == 3 then
        return t.width
    elseif k == 4 then
        return t.height
    end
end

--设置元素
function Rect.__newindex(t, k, v)
    if k == 1 then
        t.x = v
    elseif k == 2 then
        t.y = v
    elseif k == 3 then
        t.width = v
    elseif k == 4 then
        t.height = v
    end
end

---------------------------------数学运算-------------------------------


--获取插值向量
function Rect:Lerp(to, t)
    return self + (to - self) * t
end

--取反
function Rect:Negate()
    return Rect.New(-self.x, -self.y, -self.width, -self.height)
end

--长度是否为0
function Rect:IsZero()
    --接近0即可
    local r = 0.01
    return math.abs(self.x) < r and math.abs(self.y) < r and math.abs(self.width) < r and math.abs(self.height) < r
end

--是否有无效值
function Rect:IsNaN()
    return self.x ~= self.x or self.y ~= self.y or self.width ~= self.width or self.height ~= self.height
end

--判断是否相等,接近0即可
function Rect:Equals(other)
    local r = 0.01
    return math.abs(self.x - other.x) < r and math.abs(self.y - other.y) < r and 
           math.abs(self.width - other.width) < r and math.abs(self.height - other.height) < r
end

--转换成表
function Rect:ToTable()
    return {self.x, self.y, self.width, self.height}
end

--从表创建
function Rect:FromTable(t)
    self.x = t[1]
    self.y = t[2]
    self.width = t[3]
    self.height = t[4]
end

--拷贝
function Rect:Clone()
    return Rect.New(self.x, self.y, self.width, self.height)
end

-- 新增的实用方法

--获取矩形左边界
function Rect:GetLeft()
    return self.x
end

--获取矩形上边界
function Rect:GetTop()
    return self.y
end

--获取矩形右边界
function Rect:GetRight()
    return self.x + self.width
end

--获取矩形底边界
function Rect:GetBottom()
    return self.y + self.height
end

--获取矩形宽度
function Rect:GetWidth()
    return self.width
end

--获取矩形高度  
function Rect:GetHeight()
    return self.height
end

--获取矩形中心点x坐标
function Rect:GetCenterX()
    return self.x + self.width / 2
end

--获取矩形中心点y坐标
function Rect:GetCenterY()
    return self.y + self.height / 2
end

--判断点是否在矩形内
function Rect:Contains(x, y)
    return x >= self.x and x <= self:GetRight() and
           y >= self.y and y <= self:GetBottom()
end

--判断是否与另一个矩形相交
function Rect:Intersects(other)
    return self.x < other:GetRight() and self:GetRight() > other.x and
           self.y < other:GetBottom() and self:GetBottom() > other.y
end

--移动
function Rect:Move(x, y)
    self.x = self.x + x
    self.y = self.y + y
end

--缩放
function Rect:Scale(x, y)
    self.width = self.width * x
    self.height = self.height * y
end

--缩放
function Rect:ScaleWithAnchor(scaleX, scaleY, anchorX, anchorY)
    local anchorPosX = self.x + self.width * anchorX
    local anchorPosY = self.y + self.height * anchorY
    
    self.width = self.width * scaleX
    self.height = self.height * scaleY
    
    self.x = anchorPosX - self.width * anchorX
    self.y = anchorPosY - self.height * anchorY
end

--扩展
function Rect:Expand(left, top, right, bottom)
    right = right or left
    bottom = bottom or top
    self.x = self.x - left
    self.y = self.y - top
    self.width = self.width + left + right
    self.height = self.height + top + bottom
end

--应用锚点
function Rect:ApplyPivot(pivot)
    self.x = self.x - self.width * pivot.x
    self.y = self.y - self.height * pivot.y
end

--应用内边距
function Rect:ApplyPadding(padding)
    self.x = self.x + padding.left
    self.y = self.y + padding.top
    self.width = self.width - padding.left - padding.right
    self.height = self.height - padding.top - padding.bottom
end

--获取锚点
function Rect:GetAnchorPoint(anchor)
    return Vec2.New(self.x + self.width * anchor.x, self.y + self.height * anchor.y)
end

--获取位置
function Rect:GetPosition() 
    return Vec2.New(self.x, self.y)
end

--获取大小
function Rect:GetSize()
    return Vec2.New(self.width, self.height)
end

--获取矩形中心点
function Rect:GetCenter()
    return Vec2.New(self:GetCenterX(), self:GetCenterY())
end

--限制一个坐标在矩形内
function Rect:Clamp(x, y)
    return Vec2.New(math.clamp(x, self.x, self.x + self.width), math.clamp(y, self.y, self.y + self.height))
end

--合并矩形
function Rect:Union(other)
    return Rect.New(math.min(self.x, other.x), math.min(self.y, other.y), math.max(self.x + self.width, other.x + other.width), math.max(self.y + self.height, other.y + other.height))
end

--获取矩形面积
function Rect:GetArea()
    return self.width * self.height
end

function Rect:GetLeftTopCorner()
    return Vec2.New(self.x, self.y)
end

function Rect:GetRightTopCorner()
    return Vec2.New(self.x + self.width, self.y)
end

function Rect:GetLeftBottomCorner()
    return Vec2.New(self.x, self.y + self.height)
end

function Rect:GetRightBottomCorner()
    return Vec2.New(self.x + self.width, self.y + self.height)
end

--计算角点偏移
function Rect:CalculateCornerOffsets(targetRect)
    local offsets = {
        self:GetLeftTopCorner() - targetRect:GetLeftTopCorner(),
        self:GetRightTopCorner() - targetRect:GetRightTopCorner(),
        self:GetLeftBottomCorner() - targetRect:GetLeftBottomCorner(),
        self:GetRightBottomCorner() - targetRect:GetRightBottomCorner(),
    }
    return offsets
end

--根据角点偏移拉伸
function Rect:StretchByCornerOffsets(offsets)
    -- offsets[1] 是左上角偏移
    -- offsets[2] 是右上角偏移
    -- offsets[3] 是左下角偏移
    -- offsets[4] 是右下角偏移
    
    -- 计算新的左上角位置（使用左上角偏移）
    self.x = self.x + offsets[1].x
    self.y = self.y + offsets[1].y
    
    -- 计算新的宽度（使用右上角和左上角的x差值）
    local newWidth = self.width + (offsets[2].x - offsets[1].x)
    -- 计算新的高度（使用左下角和左上角的y差值）
    local newHeight = self.height + (offsets[3].y - offsets[1].y)
    
    self.width = newWidth
    self.height = newHeight
end

--拉伸
function Rect:Stretch(left, top, right, bottom)
    self.x = self.x - left
    self.y = self.y - top
    self.width = self.width + left + right
    self.height = self.height + top + bottom
end

--调整大小
function Rect:Resize(width, height, pivotX, pivotY)
    local oldWidth = self.width
    local oldHeight = self.height
    self.width = width
    self.height = height
    self.x = self.x - (self.width - oldWidth) * pivotX
    self.y = self.y - (self.height - oldHeight) * pivotY
end



return Rect