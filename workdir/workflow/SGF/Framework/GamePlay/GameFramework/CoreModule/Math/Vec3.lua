local MathDefines = GFScript("CoreModule.Math.MathDefines")
local Vec3 = {}

--实例化
function Vec3.New(x, y, z)
    local obj = {}
    obj.x = x or 0
    obj.y = y or 0
    obj.z = z or 0
    Vec3.__index = Vec3
    setmetatable(obj, Vec3)
    return obj
end

function Vec3.zero()
    return Vec3.New(0, 0, 0)
end

function Vec3.one()
    return Vec3.New(1, 1, 1)
end

function Vec3.up()
    return Vec3.New(0, 1, 0)
end

function Vec3.down()
    return Vec3.New(0, -1, 0)
end

function Vec3.forward()
    return Vec3.New(0, 0, 1)
end

function Vec3.back()
    return Vec3.New(0, 0, -1)
end

function Vec3.right()
    return Vec3.New(1, 0, 0)
end

function Vec3.left()
    return Vec3.New(-1, 0, 0)
end


--取最小值
function Vec3:Min(rhs)
    local x = math.min(self.x, rhs.x)
    local y = math.min(self.y, rhs.y)
    local z = math.min(self.z, rhs.z)
    return Vec3.New(x, y, z)
end

--取最大值
function Vec3:Max(rhs)
    local x = math.max(self.x, rhs.x)
    local y = math.max(self.y, rhs.y)
    local z = math.max(self.z, rhs.z)
    return Vec3.New(x, y, z)
end

---------------------------------运算符重载-------------------------------
--加
function Vec3.__add(lhs, rhs)
    return Vec3.New(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
end

--减
function Vec3.__sub(lhs, rhs)
    return Vec3.New(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
end

--乘
function Vec3.__mul(lhs, rhs)
    if rhs == nil then
        return Vec3.New(lhs.x,lhs.y,lhs.z)
    end
    if type(lhs) == "number" then
        return Vec3.New(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    elseif type(rhs) == "number" then
        return Vec3.New(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    else
        return Vec3.New(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
    end
end

--除
function Vec3.__div(lhs, rhs)
    if type(rhs) == "number" then
        return Vec3.New(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    else
        return Vec3.New(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z)
    end
end

--负
function Vec3.__unm(v)
    return Vec3.New(-v.x, -v.y, -v.z)
end

--等于
function Vec3.__eq(lhs, rhs)
    return lhs.x == rhs.x and lhs.y == rhs.y and lhs.z == rhs.z
end

--不等于
function Vec3.__ne(lhs, rhs)
    return lhs.x ~= rhs.x or lhs.y ~= rhs.y or lhs.z ~= rhs.z
end

--小于
function Vec3.__lt(lhs, rhs)
    return lhs.x < rhs.x and lhs.y < rhs.y and lhs.z < rhs.z
end

--小于等于
function Vec3.__le(lhs, rhs)
    return lhs.x <= rhs.x and lhs.y <= rhs.y and lhs.z <= rhs.z
end

--大于
function Vec3.__gt(lhs, rhs)
    return lhs.x > rhs.x and lhs.y > rhs.y and lhs.z > rhs.z
end

--大于等于
function Vec3.__ge(lhs, rhs)
    return lhs.x >= rhs.x and lhs.y >= rhs.y and lhs.z >= rhs.z
end

--字符串
function Vec3.__tostring(v)
    return string.format("(%f, %f, %f)", v.x, v.y, v.z)
end

--取元素
function Vec3.__index(t, k)
    if k == 1 then
        return t.x
    elseif k == 2 then
        return t.y
    elseif k == 3 then
        return t.z
    end
end

--设置元素
function Vec3.__newindex(t, k, v)
    if k == 1 then
        t.x = v
    elseif k == 2 then
        t.y = v
    elseif k == 3 then
        t.z = v
    end
end

---------------------------------运算符重载-------------------------------

--获取长度
function Vec3:Magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vec3:SqrMagnitude()
    return self.x * self.x + self.y * self.y + self.z * self.z
end

function Vec3:Length()
    return self:Magnitude()
end

--点乘
function Vec3:Dot(rhs)
    return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z
end

--叉乘
function Vec3:Cross(rhs)
    return Vec3.New(
			self.y * rhs.z - self.z * rhs.y,
			self.z * rhs.x - self.x * rhs.z,
			self.x * rhs.y - self.y * rhs.x)
end

--归一化
function Vec3:Normalize()
    local mag = self:Magnitude()
    if mag > 0 then
        self.x = self.x / mag
        self.y = self.y / mag
        self.z = self.z / mag
    end
end

--获取归一化向量
function Vec3:Normalized()
    local mag = self:Magnitude()
    if mag > 0 then
        return Vec3.New(self.x / mag, self.y / mag, self.z / mag)
    end
    return Vec3.New(0,0,0)
end

--获取反向向量
function Vec3:Inversed()
    return Vec3.New(-self.x, -self.y, -self.z)
end

--获取垂直向量
function Vec3:Perpendicular()
    local x = self.x
    local y = self.y
    local z = self.z
    if math.abs(x) <= math.abs(y) and math.abs(x) <= math.abs(z) then
        return Vec3.New(0, -z, y)
    elseif math.abs(y) <= math.abs(x) and math.abs(y) <= math.abs(z) then
        return Vec3.New(-z, 0, x)
    else
        return Vec3.New(-y, x, 0)
    end
end

--获取反射向量
function Vec3:Reflect(normal)
    return self - 2 * self:Dot(normal) * normal
end

--获取插值向量
function Vec3:Lerp(to, t)
    return self + (to - self) * t
end

--获取球面插值向量
function Vec3:Slerp(to, t)
    -- 限制t在[0,1]范围内
    t = math.clamp(t, 0, 1)
    return self:SlerpUnclamped(to, t)
end

--获取切线插值向量
function Vec3:SlerpUnclamped(to, t)
    -- 不限制t的范围
    
    -- 检查输入向量是否为零向量
    if self:IsZero() or to:IsZero() then
        return Vec3.zero()
    end
    
    -- 归一化输入向量
    local from = self:Normalized()
    local toNormalized = to:Normalized()
    
    local dot = from:Dot(toNormalized)
    dot = math.clamp(dot, -1, 1)
    
    -- 如果向量几乎平行，直接返回from或to
    if dot > 0.9995 then
        return from
    elseif dot < -0.9995 then
        -- 向量几乎相反，需要选择一个中间方向
        -- 使用垂直于from的向量作为旋转轴
        local perpendicular = from:Perpendicular()
        if perpendicular:IsZero() then
            -- 如果无法找到垂直向量，返回from
            return from
        end
        local angle = math.pi * t
        return from * math.cos(angle) + perpendicular * math.sin(angle)
    end
    
    local theta = math.acos(dot) * t
    local relative = (toNormalized - from * dot):Normalized()
    
    -- 处理边界情况：如果relative为零向量，返回from
    if relative:IsZero() then
        return from
    end
    
    return from * math.cos(theta) + relative * math.sin(theta)
end

--获取两个向量之间的角度
function Vec3:AngleBetween(to)
    local dot = self:Dot(to)
    return math.acos(dot / (self:Magnitude() * to:Magnitude())) * MathDefines.M_RADTODEG
end

--距离
function Vec3:Distance(to)
    return (self - to):Magnitude()
end

--取反
function Vec3:Negate()
    return Vec3.New(-self.x, -self.y, -self.z)
end

--移动向量
function Vec3:MoveTowards(target, maxDistanceDelta)
    local delta = target - self
    local sqrDelta = delta:SqrMagnitude()
    local sqrDistance = maxDistanceDelta * maxDistanceDelta
    if sqrDelta > sqrDistance then
        local magnitude = math.sqrt(sqrDelta)
        if magnitude > 0 then
            return self + delta / magnitude * maxDistanceDelta
        end
        return target
    end
    return target
end

--求点到线段上的距离
function Vec3:DistanceToLine(startPos, endPos)
    local line = endPos - startPos
    local pointToStart = self - startPos
    local projection = pointToStart:Dot(line) / line:SqrMagnitude()
    if projection < 0 then
        return pointToStart:Magnitude()
    end
    if projection > 1 then
        return (self - endPos):Magnitude()
    end
    local projectionOnLine = startPos + line * projection
    return (self - projectionOnLine):Magnitude()
end
--投影到平面
function Vec3:ProjectOnPlane(planeNormal)
    return self - (self:Dot(planeNormal) * planeNormal)
end

--长度是否为0
function Vec3:IsZero()
    --接近0即可
    local r = 0.01
    return math.abs(self.x) < r and math.abs(self.y) < r and math.abs(self.z) < r
end

--是否有无效值
function Vec3:IsNaN()
    return self.x ~= self.x or self.y ~= self.y or self.z ~= self.z
end

--判断是否相等,接近0即可
function Vec3:Equals(other, r)
    if not other then
        return false
    end
    r = r or 0.01
    return math.abs(self.x - other.x) < r and math.abs(self.y - other.y) < r and math.abs(self.z - other.z) < r
end

--判断是否方向相同,接近1即可
function Vec3:EqualsDirection(other)
    return self:Dot(other) > 0.999
end

--转换成表
function Vec3:ToTable()
    return {self.x, self.y, self.z}
end

--从表创建
function Vec3:FromTable(t)
    self.x = t[1]
    self.y = t[2]
    self.z = t[3]
end

--拷贝
function Vec3:Clone()
    return Vec3.New(self.x, self.y, self.z)
end

return Vec3