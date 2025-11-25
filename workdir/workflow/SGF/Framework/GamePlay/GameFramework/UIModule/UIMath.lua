-- 说明:数学库
-- 日期:2025年4月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Vec3 = GFScript("UIModule.UIMath.Vec3")
local Quat = GFScript("UIModule.UIMath.Quat")

local UIMath = {}

--求半径内的随机点
function UIMath:RandomPointInRadius(center, radius)
    local angle = math.random(0, 360)
    local x = center.x + radius * math.cos(angle)
    local z = center.z + radius * math.sin(angle)
    return Vec3.New(x, center.y, z)
end
--平滑阻尼插值
function UIMath:SmoothDamp(current, target, velocity, smoothTime, maxSpeed, deltaTime)
    -- 防止除以零
    if smoothTime == 0 then
        return target
    end

    -- 计算减速度常数
    local timeConstant = math.sqrt(2.0 / smoothTime)

    -- 计算最大速度
    local maxVelocity = maxSpeed * timeConstant

    -- 限制速度
    velocity = math.min(velocity, maxVelocity)
    velocity = math.max(velocity, -maxVelocity)

    -- 计算新的位置
    local remainingTime = smoothTime - deltaTime
    local t = 1 - math.exp(-timeConstant * deltaTime)

    -- 使用线性插值（lerp）来平滑移动
    local smoothedValue = current + (target - current) * t

    -- 更新速度
    velocity = velocity - (target - smoothedValue) / remainingTime

    return smoothedValue, velocity
end

--范围随机数            
function UIMath:Random(min, max)
    return min + math.random() * (max - min)
end
--整数随机数
function UIMath:RandomInt(min, max)
    min = math.floor(min)
    max = math.floor(max)
    if not max then
        max = min
        min = 1
    end
    return math.floor(math.random() * (max - min + 1)) + min
end
--随机数加偏移
function UIMath:RandomDeviation(value, dev)
    return value + self:Random(-dev,dev)
end
--在一个圈内随机
function UIMath:RandomInsideUnitCircle()
    local x = math.random() * 2 - 1
    local y = math.random() * 2 - 1
    local ret = Vec2.New(x, y)
    return ret:Normalized()
end
--随机方向
function UIMath:RandomOrientAxisY()
    local angle = self:Random(0, 360)
    local orient = Quat.New()
    orient:FromAngleAxis(angle, Vec3.New(0, 1, 0))
    return orient
end

--从表中随机选择一个数据
function UIMath:RandomSelect(table)
    if not table or #table == 0 then
        return nil
    end
    
    -- 创建表的副本
    local copy = {}
    for i, v in ipairs(table) do
        copy[i] = v
    end
    
    -- Fisher-Yates洗牌算法
    for i = #copy, 2, -1 do
        local j = math.random(1, i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    
    -- 返回第一个元素
    return copy[1]
end

--判断一个数字是否在某个范围内
function UIMath:IsInRange(value, min, max)
    return value >= min and value <= max
end

--几乎等于
function UIMath:IsAlmostEqual(a, b, epsilon)
    return math.abs(a - b) < epsilon
end

--补间
function UIMath:Lerp(a, b, t)
    return a + (b - a) * t
end
--判断是否为NaN
function UIMath:IsNaN(x)
    return x ~= x
end
--判断数字是否无穷大
function UIMath:IsInfinity(x)
    return x == math.huge or x == -math.huge
end
--判断浮点是否等于0，接近即可
function UIMath:IsZero(x)
    local r = 0.001
    return math.abs(x) <= r
end
--角度差
function UIMath:DeltaAngle(a, b)
    local delta = (b - a) % 360
    if delta < -180 then
        delta = delta + 360
    elseif delta > 180 then
        delta = delta - 360
    end
    return delta
end

--根据一个向量方向，返回的左边方向
function UIMath:GetLeftDirection(direction)
    return self:GetRightDirection(direction):Negate()
end
--根据一个向量方向，返回的右边方向
function UIMath:GetRightDirection(direction)
    if direction.x == 0 and direction.z == 0 then
        return Vec3.New(0, 0, 1)
    end
    local orient = Quat.lookAt(direction)
    return orient * Vec3.New(1, 0, 0)
end

return UIMath