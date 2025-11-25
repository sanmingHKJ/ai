local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")

local Waypoint = Class.New("Waypoint")

function Waypoint:Constructor(path, pos, width, height, depth, rotation)
    self.path = path
    self.position = pos
    self.width = width
    self.height = height
    self.depth = depth
    self.rotation = rotation
    self.index = 0
    
    --上一个路点
    self.prevWaypoint = nil
    -- 添加额外属性
    self.nextWaypoints = {}        -- 连接的下一个路点列表
    self.waitTime = 0              -- NPC在此路点等待时间
    self.actions = {}              -- 在此路点可执行的动作列表
    self.type = "normal"           -- 路点类型（普通、对话、商店等）

    self.params = {}
end

function Waypoint:GetPath()
    return self.path
end

function Waypoint:GetPosition()
    return self.position
end

function Waypoint:GetRotation()
    return self.rotation
end

-- 添加连接的下一个路点
function Waypoint:AddNextWaypoint(waypoint)
    waypoint.prevWaypoint = self
    table.insert(self.nextWaypoints, waypoint)
end

-- 设置等待时间
function Waypoint:SetWaitTime(time)
    self.waitTime = time
end

-- 添加路点动作
function Waypoint:AddAction(action)
    table.insert(self.actions, action)
end

-- 设置路点类型
function Waypoint:SetType(type)
    self.type = type
end

-- 获取到指定路点的距离
function Waypoint:GetDistanceTo(otherWaypoint)
    return Utils.GetDistance(self.position, otherWaypoint:GetPosition())
end

-- 检查某个位置是否在路点范围内
function Waypoint:IsPositionInRange(position, tolerance)
    tolerance = tolerance or 1
    local dx = math.abs(position.x - self.position.x)
    local dy = math.abs(position.y - self.position.y)
    local dz = math.abs(position.z - self.position.z)
    
    return dx <= self.width/2 + tolerance
       and dy <= self.height/2 + tolerance
       and dz <= self.depth/2 + tolerance
end

-- 获取随机的下一个路点
function Waypoint:GetRandomNextWaypoint()
    if #self.nextWaypoints == 0 then
        return nil
    end
    return self.nextWaypoints[math.random(#self.nextWaypoints)]
end
--获取随机连接点位置
function Waypoint:GetRandomConnectedPos(includePrev)
    local connectedWaypoints = {}
    if includePrev and self.prevWaypoint then
        table.insert(connectedWaypoints, self.prevWaypoint)
    end
    for _, waypoint in ipairs(self.nextWaypoints) do
        table.insert(connectedWaypoints, waypoint)
    end
    --如果当前连接点是最后一个点且路径是循环的，则将第一个点也加入连接点列表
    if self.index > 1 and self.index == #self.path.waypoints and self.path.isLoop then
        table.insert(connectedWaypoints, self.path.waypoints[1])
    end
    if #connectedWaypoints == 0 then
        return nil
   end
   local sourcePos = self:GetRandomPosition()
   local targetPos = connectedWaypoints[math.random(#connectedWaypoints)]:GetRandomPosition()
   return sourcePos:Lerp(targetPos, math.random())
end

--返回这个路点的随机位置
function Waypoint:GetRandomPosition(is2d)
    is2d = (is2d == nil and true or is2d)
    local randomX = math.random(-self.width/2, self.width/2)
    local randomY = math.random(-self.height/2, self.height/2)
    local randomZ = math.random(-self.depth/2, self.depth/2)
    local randomPos = Vec3.New(randomX, randomY, randomZ)
    if not is2d then
        randomPos.y = self.position.y
    end
    return self.rotation * randomPos + self.position
end

return Waypoint