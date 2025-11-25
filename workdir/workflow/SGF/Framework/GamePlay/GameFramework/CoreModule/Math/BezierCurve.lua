local Path = GFScript("CoreModule.Math.Path")
local Vec3 = GFScript("CoreModule.Math.Vec3")

local BezierCurve = {}

--实例化
function BezierCurve.New(loop)
    local obj = {}
    obj.path = Path.New(loop)
    obj.smoothPath = Path.New(loop)
    obj.smoothDirty = true
    obj.loop = loop
    BezierCurve.__index = BezierCurve
    setmetatable(obj, BezierCurve)
    return obj
end

--添加
function BezierCurve:Add(pos)
    self.path:Add(pos)
    self.smoothDirty = true
end
--移除
function BezierCurve:Remove(index)
    self.path:Remove(index)
    self.smoothDirty = true
end
--清理
function BezierCurve:Clear()
    self.path:Clear()
    self.smoothDirty = true
end
--获取点
function BezierCurve:GetPoint(index)
    return self.path:GetPoint(index)
end
--获取数量
function BezierCurve:GetCount()
    return self.path:GetCount()
end
--获取长度
function BezierCurve:GetLength()
    return self.path:GetLength()
end
--获取点
--返回点和方向
function BezierCurve:GetPointAt(distance)
    return self.path:GetPointAt(distance)
end

-- 计算二阶贝塞尔曲线上的点
-- @param p0 起始点
-- @param p1 控制点
-- @param p2 终点
-- @param t 插值参数 (0-1)
-- @return 曲线上的点
function BezierCurve:QuadraticPoint(p0, p1, p2, t)
    local mt = 1 - t
    return Vec3.New(
        mt * mt * p0.x + 2 * mt * t * p1.x + t * t * p2.x,
        mt * mt * p0.y + 2 * mt * t * p1.y + t * t * p2.y,
        mt * mt * p0.z + 2 * mt * t * p1.z + t * t * p2.z
    )
end

-- 计算三阶贝塞尔曲线上的点
-- @param p0 起始点
-- @param p1 第一控制点
-- @param p2 第二控制点
-- @param p3 终点
-- @param t 插值参数 (0-1)
-- @return 曲线上的点
function BezierCurve:CubicPoint(p0, p1, p2, p3, t)
    local mt = 1 - t
    local mt2 = mt * mt
    local t2 = t * t
    return Vec3.New(
        mt2 * mt * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t2 * t * p3.x,
        mt2 * mt * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t2 * t * p3.y,
        mt2 * mt * p0.z + 3 * mt2 * t * p1.z + 3 * mt * t2 * p2.z + t2 * t * p3.z
    )
end

-- 获取二阶贝塞尔曲线上的多个点
-- @param p0 起始点
-- @param p1 控制点
-- @param p2 终点
-- @param segments 分段数
-- @return 点的数组
function BezierCurve:GetQuadraticPoints(p0, p1, p2, segments)
    local points = {}
    for i = 0, segments do
        local t = i / segments
        points[i + 1] = self:QuadraticPoint(p0, p1, p2, t)
    end
    return points
end

-- 获取三阶贝塞尔曲线上的多个点
-- @param p0 起始点
-- @param p1 第一控制点
-- @param p2 第二控制点
-- @param p3 终点
-- @param segments 分段数
-- @return 点的数组
function BezierCurve:GetCubicPoints(p0, p1, p2, p3, segments)
    local points = {}
    for i = 0, segments do
        local t = i / segments
        points[i + 1] = self:CubicPoint(p0, p1, p2, p3, t)
    end
    return points
end

function BezierCurve:UpdateSmoothPath(bothLength, segments)
    if not self.smoothDirty then return end

    bothLength = bothLength or 100
    segments = segments or 5
    
    self.smoothPath:Clear()
    local count = self:GetCount()
    if count < 2 then return end
    
    -- 遍历所有路径点
    for i = 1, count do
        local current = self:GetPoint(i)
        local next = self:GetPoint(i % count + 1)
        local next2 = self:GetPoint(i % count + 2)
        
        -- 计算当前点到下一个点的向量和距离
        local dir = next - current
        local distance = dir:Length()
        dir:Normalize()

        local p1, p2
        if distance <= 2 * bothLength then
            p1 = current + dir * distance * 0.5
            p2 = p1:Clone()
        else
            p1 = current + dir * bothLength
            p2 = next - dir * bothLength
        end

        if not self.loop then
            self.smoothPath:Add(current)
            if i == count - 1 then
                self.smoothPath:Add(next)
                return
            else
                self.smoothPath:Add(p2)
            end
        else
            self.smoothPath:Add(p1)
            self.smoothPath:Add(p2)
        end

        local nextDir = next2 - next
        local nextDistance = nextDir:Length()
        nextDir:Normalize()

        local p3, p4
        if nextDistance <= 2 * bothLength then
            p3 = next + nextDir * nextDistance * 0.5
            p4 = p3:Clone()
        else
            p3 = next + nextDir * bothLength
            p4 = next2 - nextDir * bothLength
        end

        local bezierPoints = self:GetQuadraticPoints(p2, next, p3, segments)
        for _, point in ipairs(bezierPoints) do
            self.smoothPath:Add(point)
        end
    end
    
    self.smoothDirty = false
end
--获取点，返回点和方向
function BezierCurve:GetPointAt(distance)
    return self.smoothPath:GetPointAt(distance)
end





return BezierCurve