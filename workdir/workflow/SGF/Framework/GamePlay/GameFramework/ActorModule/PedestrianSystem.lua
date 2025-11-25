local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local WalkPath = GFScript("ActorModule.PedestrianSystem.WalkPath")
local Waypoint = GFScript("ActorModule.PedestrianSystem.Waypoint")
local Math = GFScript("CoreModule.Math")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")
local PedestrianDefines = GFScript("ActorModule.PedestrianSystem.PedestrianDefines")
local PedestrianSystem = Class.New("PedestrianSystem")

function PedestrianSystem:Constructor()
    self.walkPaths = {}

    self.walkers = {}
    self.maxWalkers = 0
    self.walkerCount = 0

    self.defaultMaxWalkers = 0
    self.defaultSpawnType = "Line"
    self.defaultAI = "Walker1"

    self.enabled = false
end

function PedestrianSystem:OnDestructor()
    self:DestroyAllWalkPaths()
    self:DestroyAllWalkers()
end
--启用或者关闭
function PedestrianSystem:SetEnabled(enabled)
    self.enabled = enabled
end

function PedestrianSystem:Init(scene)
    self.scene = scene  
end
--更新
function PedestrianSystem:Update(dt)
    if not self.enabled then
        return
    end
    if self.walkerCount < self.maxWalkers then
        self:SpawnWalker()
    end

    for _, path in ipairs(self.walkPaths) do
        path:Update(dt)
    end
end
--产卵漫步者
function PedestrianSystem:SpawnWalker()
    if self.walkerCount >= self.maxWalkers then
        return
    end
    local waypoint = self:GetRandomWaypoint()
    if waypoint then
        self.walkerCount = self.walkerCount + 1
        local randomPos = waypoint:GetRandomConnectedPos(true)
        local walker = self:CreateWalker(randomPos.x, randomPos.y, randomPos.z, "Walker.Walker_101")
        walker.walkPath = waypoint:GetPath():GetName()
        --随机正向或者反向
        walker.walkDir = (Math:Random(0, 100) > 50 and 1 or -1)
        --随机外观
        local character = walker:GetCharacter()
        if character then
            character.SkinId = Math:RandomSelect(PedestrianDefines.RandomSkinIds)
        end
        table.insert(self.walkers, walker)
    end
end
--销毁
function PedestrianSystem:UnspawnWalker(walker)
    if walker then
        self.walkerCount = self.walkerCount - 1
        self:DestroyWalker(walker)
        table.remove(self.walkers, walker)
    end
end
--创建漫步者
function PedestrianSystem:CreateWalker(x, y, z, tid)
    local workspace = self.scene:GetWorkspace()
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or type(tid) ~= "string" then
        return
    end
    local config = DataProviderManager:GetData("Walker",tid)
    if config == nil then
        Log:Error("PedestrianSystem:CreateWalker", "Invalid config tid: " .. tostring(tid))
        return
    end
    local nodeTemplate = Utils:GetMainStorageNode(config.asset)
    if nodeTemplate == nil then
        Log:Error("PedestrianSystem:CreateWalker", "Invalid asset tid: " .. tostring(tid))
        return
    end
    local ActorManager = GFScript("ActorModule.ActorManager")
    local actor = ActorManager:ServerCreateActor(workspace, "Walker", nodeTemplate, true, function(actor)
        local pos = Vec3.New(x,y,z)
        actor:LoadConfigFromTid(tid)
        actor:SetBornPosition(pos)
        actor.AvatarComponent:SetPosition(pos)
        actor:SetCollideGroup(ActorDefines.CollideGroup.Walker)
        --actor.AvatarComponent:SetMoveType(AvatarDefines.EMoveType.Walk)
        actor.AvatarComponent:SetMoveType(Math:Random(0, 100) > 20 and AvatarDefines.EMoveType.Walk or AvatarDefines.EMoveType.Run)
    end)
    return actor
end

function PedestrianSystem:DestroyWalker(walker)
    local ActorManager = GFScript("ActorModule.ActorManager")
    ActorManager:ServerDestroyActor(walker)
end

function PedestrianSystem:DestroyAllWalkers()
    for _, walker in ipairs(self.walkers) do
        self:DestroyWalker(walker)
    end
    self.walkers = {}
end

--获取随机路径点
function PedestrianSystem:GetRandomWalkPath()
    local randomIndex = Math:RandomInt(1, #self.walkPaths)
    return self.walkPaths[randomIndex]
end

function PedestrianSystem:GetWalkPathCount()
    return #self.walkPaths
end

function PedestrianSystem:GetWalkPathByIndex(index)
    return self.walkPaths[index]
end
--获取随机路点
function PedestrianSystem:GetRandomWaypoint()
    local walkPath = self:GetRandomWalkPath()
    if walkPath then
        return walkPath:GetRandomWaypoint()
    end
    return nil
end

--获取路径
function PedestrianSystem:GetWalkPath(name)
    for _, walkPath in ipairs(self.walkPaths) do
        if walkPath.name == name then
            return walkPath
        end
    end
    return nil
end

--添加路径
function PedestrianSystem:AddWalkPath(name, rootNode, isLoop)
    local maxWalkers = rootNode:GetAttribute("MaxWalkers") or self.defaultMaxWalkers
    local spawnType = rootNode:GetAttribute("SpawnType") or self.defaultSpawnType
    local ai = rootNode:GetAttribute("AI") or self.defaultAI
    local walkPath = WalkPath.New(name, self, maxWalkers)
    walkPath:InitFromNodes(rootNode)
    walkPath:SetLoop(isLoop)
    walkPath:SetSpawnType(spawnType)
    walkPath:SetAI(ai)
    table.insert(self.walkPaths, walkPath)
    return walkPath
end

--初始化路径
function PedestrianSystem:InitWalkPaths(rootNodes)
    self:DestroyAllWalkPaths()
    if rootNodes then
        for _, rootNode in ipairs(rootNodes.Children) do
            local name = rootNode.Name
            self:AddWalkPath(name, rootNode, true)
        end
    end
end

--销毁所有路径
function PedestrianSystem:DestroyAllWalkPaths()
    for _, walkPath in ipairs(self.walkPaths) do
        walkPath:Destroy()
    end
    self.walkPaths = {}
end

return PedestrianSystem