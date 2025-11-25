local Curve = {}

-- 插值类型枚举
Curve.InterpMode = {
    Linear = 1,      -- 线性插值
    Constant = 2,    -- 常量插值
    Cubic = 3,       -- 三次插值
    EaseInOut = 4,   -- 缓入缓出
    EaseIn = 5,      -- 缓入
    EaseOut = 6      -- 缓出
}

-- 循环模式枚举
Curve.LoopMode = {
    None = 1,        -- 不循环
    Loop = 2,        -- 循环
    PingPong = 3     -- 乒乓循环
}

-- 关键帧结构
local KeyFrame = {
    Time = 0,
    Value = 0,
    InterpMode = Curve.InterpMode.Linear,
    TangentIn = 0,
    TangentOut = 0
}

function KeyFrame.New(time, value, interpMode, tangentIn, tangentOut)
    local key = {}
    key.Time = time or 0
    key.Value = value or 0
    key.InterpMode = interpMode or Curve.InterpMode.Linear
    key.TangentIn = tangentIn or 0
    key.TangentOut = tangentOut or 0
    return key
end

--实例化
function Curve.New(loopMode)
    local obj = {}
    Curve.__index = Curve
    
    -- 初始化属性
    obj.KeyFrames = {}
    obj.LoopMode = loopMode or Curve.LoopMode.None
    obj.Duration = 0
    obj.IsSorted = true
    
    setmetatable(obj, Curve)
    return obj
end

-- 添加关键帧
function Curve:AddKeyFrame(time, value, interpMode, tangentIn, tangentOut)
    local key = KeyFrame.New(time, value, interpMode, tangentIn, tangentOut)
    table.insert(self.KeyFrames, key)
    self.IsSorted = false
    self:UpdateDuration()
    return #self.KeyFrames
end

-- 移除关键帧
function Curve:RemoveKeyFrame(index)
    if index >= 1 and index <= #self.KeyFrames then
        table.remove(self.KeyFrames, index)
        self:UpdateDuration()
        return true
    end
    return false
end

-- 获取关键帧
function Curve:GetKeyFrame(index)
    if index >= 1 and index <= #self.KeyFrames then
        return self.KeyFrames[index]
    end
    return nil
end

-- 更新持续时间
function Curve:UpdateDuration()
    if #self.KeyFrames > 0 then
        self.Duration = 0
        for _, key in ipairs(self.KeyFrames) do
            if key.Time > self.Duration then
                self.Duration = key.Time
            end
        end
    else
        self.Duration = 0
    end
end

-- 排序关键帧
function Curve:SortKeyFrames()
    if not self.IsSorted then
        table.sort(self.KeyFrames, function(a, b) return a.Time < b.Time end)
        self.IsSorted = true
    end
end

-- 查找关键帧索引
function Curve:FindKeyFrameIndex(time)
    self:SortKeyFrames()
    
    if #self.KeyFrames == 0 then
        return 0, 0
    end
    
    if time <= self.KeyFrames[1].Time then
        return 0, 1
    end
    
    if time >= self.KeyFrames[#self.KeyFrames].Time then
        return #self.KeyFrames, 0
    end
    
    for i = 1, #self.KeyFrames - 1 do
        if time >= self.KeyFrames[i].Time and time < self.KeyFrames[i + 1].Time then
            return i, i + 1
        end
    end
    
    return 0, 0
end

-- 线性插值
function Curve:LinearInterp(key1, key2, alpha)
    return key1.Value + (key2.Value - key1.Value) * alpha
end

-- 三次插值
function Curve:CubicInterp(key1, key2, alpha)
    local t = alpha
    local t2 = t * t
    local t3 = t2 * t
    
    -- 使用Hermite插值
    local h1 = 2 * t3 - 3 * t2 + 1
    local h2 = -2 * t3 + 3 * t2
    local h3 = t3 - 2 * t2 + t
    local h4 = t3 - t2
    
    return h1 * key1.Value + h2 * key2.Value + h3 * key1.TangentOut + h4 * key2.TangentIn
end

-- 缓入缓出插值
function Curve:EaseInOutInterp(key1, key2, alpha)
    local t = alpha
    if t < 0.5 then
        t = 2 * t * t
    else
        t = 1 - 2 * (1 - t) * (1 - t)
    end
    return self:LinearInterp(key1, key2, t)
end

-- 缓入插值
function Curve:EaseInInterp(key1, key2, alpha)
    local t = alpha * alpha
    return self:LinearInterp(key1, key2, t)
end

-- 缓出插值
function Curve:EaseOutInterp(key1, key2, alpha)
    local t = 1 - (1 - alpha) * (1 - alpha)
    return self:LinearInterp(key1, key2, t)
end

-- 处理循环时间
function Curve:HandleLoopTime(time)
    if self.LoopMode == Curve.LoopMode.None then
        return time
    elseif self.LoopMode == Curve.LoopMode.Loop then
        if self.Duration > 0 then
            return time % self.Duration
        end
        return time
    elseif self.LoopMode == Curve.LoopMode.PingPong then
        if self.Duration > 0 then
            local cycle = math.floor(time / self.Duration)
            local cycleTime = time % self.Duration
            if cycle % 2 == 1 then
                return self.Duration - cycleTime
            else
                return cycleTime
            end
        end
        return time
    end
    return time
end

-- 获取曲线值
function Curve:GetValue(time)
    if #self.KeyFrames == 0 then
        return 0
    end
    
    -- 处理循环
    time = self:HandleLoopTime(time)
    
    -- 查找关键帧
    local index1, index2 = self:FindKeyFrameIndex(time)
    
    if index1 == 0 and index2 == 0 then
        return 0
    end
    
    if index1 == 0 then
        return self.KeyFrames[index2].Value
    end
    
    if index2 == 0 then
        return self.KeyFrames[index1].Value
    end
    
    local key1 = self.KeyFrames[index1]
    local key2 = self.KeyFrames[index2]
    
    -- 计算插值参数
    local alpha = (time - key1.Time) / (key2.Time - key1.Time)
    
    -- 根据插值模式计算值
    if key1.InterpMode == Curve.InterpMode.Constant then
        return key1.Value
    elseif key1.InterpMode == Curve.InterpMode.Linear then
        return self:LinearInterp(key1, key2, alpha)
    elseif key1.InterpMode == Curve.InterpMode.Cubic then
        return self:CubicInterp(key1, key2, alpha)
    elseif key1.InterpMode == Curve.InterpMode.EaseInOut then
        return self:EaseInOutInterp(key1, key2, alpha)
    elseif key1.InterpMode == Curve.InterpMode.EaseIn then
        return self:EaseInInterp(key1, key2, alpha)
    elseif key1.InterpMode == Curve.InterpMode.EaseOut then
        return self:EaseOutInterp(key1, key2, alpha)
    else
        return self:LinearInterp(key1, key2, alpha)
    end
end

-- 清空所有关键帧
function Curve:Clear()
    self.KeyFrames = {}
    self.Duration = 0
    self.IsSorted = true
end

-- 获取关键帧数量
function Curve:GetKeyFrameCount()
    return #self.KeyFrames
end

-- 获取持续时间
function Curve:GetDuration()
    return self.Duration
end

-- 设置循环模式
function Curve:SetLoopMode(loopMode)
    self.LoopMode = loopMode
end

-- 获取循环模式
function Curve:GetLoopMode()
    return self.LoopMode
end

-- 检查是否为空
function Curve:IsEmpty()
    return #self.KeyFrames == 0
end

-- 获取最小值
function Curve:GetMinValue()
    if #self.KeyFrames == 0 then
        return 0
    end
    
    local minValue = self.KeyFrames[1].Value
    for _, key in ipairs(self.KeyFrames) do
        if key.Value < minValue then
            minValue = key.Value
        end
    end
    return minValue
end

-- 获取最大值
function Curve:GetMaxValue()
    if #self.KeyFrames == 0 then
        return 0
    end
    
    local maxValue = self.KeyFrames[1].Value
    for _, key in ipairs(self.KeyFrames) do
        if key.Value > maxValue then
            maxValue = key.Value
        end
    end
    return maxValue
end

return Curve