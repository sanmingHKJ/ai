local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Math = GFScript("CoreModule.Math")
local Waypoint = GFScript("ActorModule.PedestrianSystem.Waypoint")
local PedestrianDefines = GFScript("ActorModule.PedestrianSystem.PedestrianDefines")

local WalkPath = Class.New("WalkPath")

local SpawnType = {
    --固定
    Fixed = "Fixed",
    --随机
    Random = "Random",
    --沿路径
    Line = "Line",
}

function WalkPath:Constructor(name, pedestrianSystem, maxWalkers)
    self.name = name
    self.pedestrianSystem = pedestrianSystem
    self.waypoints = {}  -- 存储路径点的数组
    self.isLoop = false  -- 是否循环路径

    self.walkers = {}
    self.maxWalkers = maxWalkers
    self.walkerCount = 0
    self.spawnType = SpawnType.Line
    self.ai = "Walker1"
end

function WalkPath:GetName()
    return self.name
end

function WalkPath:SetSpawnType(spawnType)
    self.spawnType = spawnType
end

function WalkPath:SetAI(ai)
    self.ai = ai
end

-- 添加路径点
function WalkPath:AddWaypoint(pos, size, rotation, prevPointIndex)
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
function WalkPath:GetNextWaypoint(currentIndex, reverse)
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
function WalkPath:SetLoop(isLoop)
    self.isLoop = isLoop
end

-- 获取路径点数量
function WalkPath:GetWaypointCount()
    return #self.waypoints
end

--获取随机路点
function WalkPath:GetRandomWaypoint()
    local randomIndex = Math:RandomInt(1, #self.waypoints)
    return self.waypoints[randomIndex]
end

--查找最近的路径点
function WalkPath:FindNearestWaypoint(pos)
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
function WalkPath:InitFromNodes(nodes)
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
            waypoint.params.skinId = child:GetAttribute("SkinId")
            waypoint.params.ai = child:GetAttribute("AI")
            if type(waypoint.params.skinId) == "string" then
                waypoint.params.skinId = Utils:SplitToNumber(waypoint.params.skinId,",")
            end
        end
    end
end

--更新
function WalkPath:Update(dt)
    if self.spawnType == SpawnType.Fixed then
        self.fixedIndex = self.fixedIndex or 0
        if self.fixedIndex < #self.waypoints then
            self.fixedIndex = self.fixedIndex + 1
            local waypoint = self.waypoints[self.fixedIndex]
            self.walkerCount = self.walkerCount + 1
            local walker = self:CreateWalker(waypoint)
            table.insert(self.walkers, walker)
        end
    else
        if self.walkerCount < self.maxWalkers then
            self:SpawnWalker()
        end
    end
end
--产卵漫步者
function WalkPath:SpawnWalker()
    if self.walkerCount >= self.maxWalkers then
        return
    end
    local waypoint = self:GetRandomWaypoint()
    if waypoint then
        self.walkerCount = self.walkerCount + 1
        local walker = self:CreateWalker(waypoint)
        table.insert(self.walkers, walker)
    end
end

function WalkPath:CreateWalker(waypoint)
    local randomPos = nil
    local rotation = nil
    if self.spawnType == SpawnType.Line then
        randomPos = waypoint:GetRandomConnectedPos(true)
    elseif self.spawnType == SpawnType.Random then
        randomPos = waypoint:GetRandomPosition()
    elseif self.spawnType == SpawnType.Fixed then
        randomPos = waypoint:GetPosition()
        rotation = waypoint:GetRotation()
    end
    local walker = self.pedestrianSystem:CreateWalker(randomPos.x, randomPos.y, randomPos.z, "Walker.Walker_101")
    if rotation then
        walker:SetRotation(rotation)
    end
    local aiComponent = walker:GetDerivedComponent("AIComponent")
    if aiComponent then
        if waypoint.params.ai then
            aiComponent:LoadConfigFromTid(waypoint.params.ai)
        else
            aiComponent:LoadConfigFromTid(self.ai)
        end
    end
    walker.walkPath = self:GetName()
    --随机正向或者反向
    walker.walkDir = (Math:Random(0, 100) > 50 and 1 or -1)
    --随机外观
    local character = walker:GetCharacter()
    if character then
        if waypoint.params.skinId then
            if type(waypoint.params.skinId) == "table" then
                character.SkinId = Math:RandomSelect(waypoint.params.skinId)
            else
                character.SkinId = waypoint.params.skinId
            end
        else
            character.SkinId = Math:RandomSelect(PedestrianDefines.RandomSkinIds)
        end
    end
    return walker
end
--销毁
function WalkPath:UnspawnWalker(walker)
    if walker then
        self.walkerCount = self.walkerCount - 1
        self.pedestrianSystem:DestroyWalker(walker)
        table.remove(self.walkers, walker)
    end
end


return WalkPath
