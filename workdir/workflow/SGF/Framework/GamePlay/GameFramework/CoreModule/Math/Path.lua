local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Mat3 = GFScript("CoreModule.Math.Mat3")
local MathDefines = GFScript("CoreModule.Math.MathDefines")
local Path = {}

--实例化
function Path.New(loop)
    local obj = {}
    obj.points = {}
    obj.loop = loop
    Path.__index = Path
    setmetatable(obj, Path)
    return obj
end

--添加
function Path:Add(pos)
    table.insert(self.points, pos)
end
--移除
function Path:Remove(index)
    table.remove(self.points, index)
end
--清理
function Path:Clear()
    self.points = {}
end
--获取点
function Path:GetPoint(index)
    return self.points[index]
end

--反转
function Path:Reverse()
    local tempPoints = {}
    for i = #self.points, 1, -1 do
        table.insert(tempPoints, self.points[i])
    end
    self.points = tempPoints
end

--获取数量
function Path:GetCount()
    return #self.points
end
--获取长度
function Path:GetLength()
    local length = 0
    for i = 1, #self.points - 1 do
        length = length + (self.points[i] - self.points[i + 1]):Magnitude()
    end
    return length
end
--获取点
--返回点、方向和朝向
function Path:GetPointAt(distance)
    if #self.points < 2 then
        return nil
    end

    local totalLength = self:GetLength()
    if totalLength == 0 then
        return nil
    end

    -- 如果是循环路径，调整distance到有效范围内
    if self.loop then
        -- 添加首尾相连的长度
        totalLength = totalLength + (self.points[#self.points] - self.points[1]):Magnitude()
        distance = distance % totalLength
    else
        -- 非循环路径，限制在路径长度内
        if distance > totalLength then
            return nil
        end
    end

    local length = 0
    for i = 1, #self.points do
        local nextIndex = i + 1
        -- 如果是循环路径且到达末尾，连接到起点
        if self.loop and nextIndex > #self.points then
            nextIndex = 1
        elseif not self.loop and nextIndex > #self.points then
            break
        end

        local segLength = (self.points[i] - self.points[nextIndex]):Magnitude()
        if length + segLength >= distance then
            local t = (distance - length) / segLength
            local p = (self.points[nextIndex] - self.points[i]) * t
            local direction = p:Normalized()
            return self.points[i] + p, direction
        end
        length = length + segLength
    end
    return nil
end

--查找最近的路径点
function Path:FindNearest(pos)
    local nearestDistance = math.huge
    local nearestPoint = nil
    for _, point in ipairs(self.points) do
        local distance = (point - pos):Magnitude()
        if distance < nearestDistance then
            nearestDistance = distance
            nearestPoint = point
        end
    end
    return nearestPoint
end

--查找最近的路径点，在直线路径上
function Path:FindNearestOnLine(pos)
    if #self.points < 2 then
        return nil
    end

    local nearestDistance = math.huge
    local nearestPoint = nil

    -- 遍历所有线段
    for i = 1, #self.points - (self.loop and 0 or 1) do
        local p1 = self.points[i]
        local p2 = self.points[i + 1]
        -- 如果是循环路径且到达末尾，连接到起点
        if self.loop and i == #self.points then
            p2 = self.points[1]
        end

        -- 计算线段向量
        local segment = p2 - p1
        local segmentLength = segment:Magnitude()
        
        if segmentLength > 0 then
            -- 计算投影点
            local v = pos - p1
            local t = v:Dot(segment) / (segmentLength * segmentLength)
            
            -- 限制投影点在线段范围内
            t = math.max(0, math.min(1, t))
            
            -- 计算最近点
            local projection = p1 + segment * t
            local distance = (pos - projection):Magnitude()
            
            -- 更新最近点
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPoint = projection
            end
        end
    end

    return nearestPoint
end

return Path