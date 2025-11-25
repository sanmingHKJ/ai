local Log = GFScript("CoreModule.Log")
local Vec2 = GFScript("CoreModule.Math.Vec2")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")

local Math = {}

--求半径内的随机点
function Math:RandomPointInRadius(center, radius)
    local angle = math.random(0, 360)
    local x = center.x + radius * math.cos(angle)
    local z = center.z + radius * math.sin(angle)
    return Vec3.New(x, center.y, z)
end
--平滑阻尼插值
function Math:SmoothDamp(current, target, velocity, smoothTime, maxSpeed, deltaTime)
    -- 防止除以零
    if smoothTime == 0 then
        return target, velocity
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

--平滑阻尼插值向量
function Math:SmoothDampVector(current, target, velocity, smoothTime, maxSpeed, deltaTime)
    -- 防止除以零
    if smoothTime == 0 then
        return target, velocity
    end
    
    -- 参数验证和默认值
    smoothTime = math.max(0.0001, smoothTime or 0.15)
    maxSpeed = maxSpeed or math.huge
    deltaTime = deltaTime or 0.016 -- 默认60fps
    
    -- 计算减速度常数
    local timeConstant = math.sqrt(2.0 / smoothTime)
    
    -- 计算最大速度
    local maxVelocity = maxSpeed * timeConstant
    
    -- 限制速度
    local velocityMagnitude = velocity:Magnitude()
    if velocityMagnitude > maxVelocity then
        velocity = velocity / velocityMagnitude * maxVelocity
    end
    
    -- 计算新的位置
    local remainingTime = smoothTime - deltaTime
    local t = 1 - math.exp(-timeConstant * deltaTime)
    
    -- 使用线性插值（lerp）来平滑移动
    local smoothedValue = current + (target - current) * t
    
    -- 更新速度
    local newVelocity = velocity - (target - smoothedValue) / remainingTime
    
    return smoothedValue, newVelocity
end

--范围随机数            
function Math:Random(min, max)
    return min + math.random() * (max - min)
end
--整数随机数
function Math:RandomInt(min, max)
    min = math.floor(min)
    max = math.floor(max)
    if not max then
        max = min
        min = 1
    end
    return math.floor(math.random() * (max - min + 1)) + min
end
--随机数加偏移
function Math:RandomDeviation(value, dev)
    return value + self:Random(-dev,dev)
end

--随机方向偏移
function Math:RandomDirectionDeviation(direction, dev)
    -- 参数验证
    if not direction or dev <= 0 then
        return direction
    end
    
    -- 归一化输入方向
    local normalizedDir = direction:Normalized()
    
    -- 生成随机角度偏移
    local randomAngleYaw = self:Random(-dev, dev)
    local randomAnglePitc = self:Random(-dev, dev)

    local rot = Quat.lookAt(direction)
    local euler = rot:ToEuler()
    euler.y = euler.y + randomAngleYaw
    euler.x = euler.x + randomAnglePitc
    local rot2 = Quat.euler(euler.x, euler.y, euler.z)
    -- local newDirection = rot2:GetForward()
    return rot2:GetForward()
end
--在一个圈内随机
function Math:RandomInsideUnitCircle()
    local x = math.random() * 2 - 1
    local y = math.random() * 2 - 1
    local ret = Vec2.New(x, y)
    return ret:Normalized()
end

--在一个球内随机
function Math:RandomInsideUnitSphere()
    local x = math.random() * 2 - 1
    local y = math.random() * 2 - 1
    local z = math.random() * 2 - 1
    local ret = Vec3.New(x, y, z)
    return ret:Normalized()
end

--随机方向
function Math:RandomOrientAxisY()
    local angle = self:Random(0, 360)
    local orient = Quat.New()
    orient:FromAngleAxis(angle, Vec3.New(0, 1, 0))
    return orient
end

--从表中随机选择一个数据
function Math:RandomSelect(table)
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
function Math:IsInRange(value, min, max)
    return value >= min and value <= max
end

--几乎等于
function Math:IsAlmostEqual(a, b, epsilon)
    return math.abs(a - b) < epsilon
end

--补间
function Math:Lerp(a, b, t)
    return a + (b - a) * t
end

--补间到
function Math:InterpTo(current, target, deltaTime, speed)
    speed = speed or 1
    return current + (target - current) * deltaTime * speed
end

--判断是否为NaN
function Math:IsNaN(x)
    return x ~= x
end
--判断数字是否无穷大
function Math:IsInfinity(x)
    return x == math.huge or x == -math.huge
end
--判断浮点是否等于0，接近即可
function Math:IsZero(x)
    local r = 0.001
    return math.abs(x) <= r
end
--角度差
function Math:DeltaAngle(a, b)
    local delta = (b - a) % 360
    if delta < -180 then
        delta = delta + 360
    elseif delta > 180 then
        delta = delta - 360
    end
    return delta
end

--根据一个向量方向，返回的左边方向
function Math:GetLeftDirection(direction)
    return self:GetRightDirection(direction):Negate()
end
--根据一个向量方向，返回的右边方向
function Math:GetRightDirection(direction)
    if direction.x == 0 and direction.z == 0 then
        return Vec3.New(0, 0, 1)
    end
    local orient = Quat.lookAt(direction)
    return orient * Vec3.New(1, 0, 0)
end

--根据权重随机选择一个数据  
function Math:RandomByWeight(weightList)   
    local totalWeight = 0
    for _, config in pairs(weightList) do
        totalWeight = totalWeight + config.weight
    end
    local randomWeight = self:Random(1, totalWeight)
    local currentWeight = 0
    for _, config in pairs(weightList) do
        currentWeight = currentWeight + config.weight
        if randomWeight <= currentWeight then
            return config
        end
    end
    return nil
end

return Math