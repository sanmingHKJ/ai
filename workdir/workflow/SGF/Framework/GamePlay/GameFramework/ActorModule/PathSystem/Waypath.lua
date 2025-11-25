local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Math = GFScript("CoreModule.Math")
local Waypoint = GFScript("ActorModule.PathSystem.Waypoint")

local Waypath = Class.New("Waypath")

function Waypath:Constructor(name, pathSystem)
    self.name = name
    self.pathSystem = pathSystem
    self.waypoints = {}  -- 存储路径点的数组
    self.isLoop = false  -- 是否循环路径

    self.actors = {}
    self.maxActors = 0
    self.actorCount = 0
    self.spawnType = "Line"
    self.ai = "Walker1"
end

function Waypath:GetName()
    return self.name
end

function Waypath:SetMaxActors(maxActors)
    self.maxActors = maxActors
end

function Waypath:SetSpawnType(spawnType)
    self.spawnType = spawnType
end

function Waypath:SetAI(ai)
    self.ai = ai
end

-- 添加路径点
function Waypath:AddWaypoint(pos, size, rotation, prevPointIndex)
    local waypoint = Waypoint.New(self, pos, size.x, size.y, size.z, rotation)

    if #self.waypoints > 0 then
        if prevPointIndex and prevPointIndex <= #self.waypoints then
            self.waypoints[prevPointIndex]:AddNextWaypoint(waypoint)
        else
            self.waypoints[#self.waypoints]:AddNextWaypoint(waypoint)
        end
    end

    waypoint.index = #self.waypoints + 1
    table.insert(self.waypoints, waypoint)
    return waypoint
end

-- 获取下一个路径点
function Waypath:GetNextWaypoint(currentIndex, reverse)
    if #self.waypoints == 0 then
        return nil
    end
    
    -- 根据方向更新索引
    local nextIndex = currentIndex
    if reverse then
        nextIndex = nextIndex - 1
        if nextIndex < 1 then
            if self.isLoop then
                nextIndex = #self.waypoints
            else
                nextIndex = 1
            end
        end
    else
        nextIndex = nextIndex + 1
        if nextIndex > #self.waypoints then
            if self.isLoop then
                nextIndex = 1
            else
                nextIndex = #self.waypoints
            end
        end
    end
    
    return self.waypoints[nextIndex]
end

-- 设置是否循环
function Waypath:SetLoop(isLoop)
    self.isLoop = isLoop
end

-- 获取路径点数量
function Waypath:GetWaypointCount()
    return #self.waypoints
end

--获取随机路点
function Waypath:GetRandomWaypoint()
    local randomIndex = Math:RandomInt(1, #self.waypoints)
    return self.waypoints[randomIndex]
end

--查找最近的路径点
function Waypath:FindNearestWaypoint(pos)
    local nearestWaypoint = nil
    local nearestDistance = math.huge
    for _, waypoint in ipairs(self.waypoints) do
        local distance = pos:Distance(waypoint:GetPosition())
        if distance < nearestDistance then
            nearestDistance = distance
            nearestWaypoint = waypoint
        end
    end
    return nearestWaypoint
end

-- 从节点中初始化
function Waypath:InitFromNodes(nodes)
    for _, child in ipairs(nodes.Children) do
        if child.ClassType == 'GeoSolid' then
            local pos = Vec3.New(child.Position.X, child.Position.Y, child.Position.Z)
            local rotation = Quat.New(child.Rotation.w, child.Rotation.x, child.Rotation.y, child.Rotation.z)
            local size = Vec3.New(child.LocalScale.X, child.LocalScale.Y, child.LocalScale.Z) * 100
            child.Visible = false
            child.EnablePhysics = false
            child.CanCollide = false
            child.CanTouch = false

            local waypoint = self:AddWaypoint(pos, size, rotation)
            self.pathSystem:OnInitWaypoint(waypoint, child)
        end
    end
end

--更新
function Waypath:Update(dt)
    if self.spawnType == "Fixed" then
        self.fixedIndex = self.fixedIndex or 0
        if self.fixedIndex < #self.waypoints then
            self.fixedIndex = self.fixedIndex + 1
            local waypoint = self.waypoints[self.fixedIndex]
            self.actorCount = self.actorCount + 1
            local actor = self.pathSystem:CreateActor(waypoint)
            table.insert(self.actors, actor)
        end
    else
        if self.actorCount < self.maxActors then
            self:SpawnActor()
        end
    end
end
--产卵漫步者
function Waypath:SpawnActor()
    if self.actorCount >= self.maxActors then
        return
    end
    local waypoint = self:GetRandomWaypoint()
    if waypoint then
        self.actorCount = self.actorCount + 1
        local actor = self.pathSystem:CreateActor(waypoint)
        table.insert(self.actors, actor)
    end
end
--销毁
function Waypath:UnspawnActor(actor)
    if actor then
        self.actorCount = self.actorCount - 1
        self.pathSystem:DestroyActor(actor)
        table.remove(self.actors, actor)
    end
end


return Waypath
