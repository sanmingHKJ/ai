local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Waypath = GFScript("ActorModule.PathSystem.Waypath")
local Waypoint = GFScript("ActorModule.PathSystem.Waypoint")
local Math = GFScript("CoreModule.Math")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")

local PathSystem = Class.New("PathSystem")

PathSystem.SpawnType = {
    --固定
    Fixed = "Fixed",
    --随机
    Random = "Random",
    --沿路径
    Line = "Line",
}

function PathSystem:Constructor()
    self.paths = {}

    self.actors = {}
    self.maxActors = 0
    self.actorCount = 0

    self.actorType = "Walker"
    self.actorTid = "Walker.Walker_101"

    self.spawnType = "Line"

    self.enabled = false
end
--启用或者关闭
function PathSystem:SetEnabled(enabled)
    self.enabled = enabled
end

function PathSystem:Init(scene)
    self.scene = scene  
end
--更新
function PathSystem:Update(dt)
    if not self.enabled then
        return
    end
    if self.actorCount < self.maxActors then
        self:SpawnActor()
    end

    for _, path in ipairs(self.paths) do
        path:Update(dt)
    end
end

function PathSystem:GetPositionAndRotation(waypoint)
    local randomPos = nil
    local rotation = nil
    if self.spawnType == PathSystem.SpawnType.Line then
        randomPos = waypoint:GetRandomConnectedPos(true)
    elseif self.spawnType == PathSystem.SpawnType.Random then
        randomPos = waypoint:GetRandomPosition()
        rotation = Math:RandomOrientAxisY()
    elseif self.spawnType == PathSystem.SpawnType.Fixed then
        randomPos = waypoint:GetPosition()
        rotation = waypoint:GetRotation()
    end
    return randomPos, rotation
end

--产卵漫步者
function PathSystem:SpawnActor()
    if self.actorCount >= self.maxActors then
        return
    end
    local waypoint = self:GetRandomWaypoint()
    if waypoint then
        self.actorCount = self.actorCount + 1
        local actor = self:CreateActor(waypoint)
        
        table.insert(self.actors, actor)
    end
end
--销毁
function PathSystem:UnspawnActor(actor)
    if actor then
        self.actorCount = self.actorCount - 1
        self:DestroyActor(actor)
        table.remove(self.actors, actor)
    end
end

function PathSystem:DestroyActor(actor)
    local ActorManager = GFScript("ActorModule.ActorManager")
    ActorManager:ServerDestroyActor(actor)
end
--获取随机路径点
function PathSystem:GetRandomPath()
    local randomIndex = Math:RandomInt(1, #self.paths)
    return self.paths[randomIndex]
end

function PathSystem:GetPathCount()
    return #self.paths
end

function PathSystem:GetPathByIndex(index)
    return self.paths[index]
end
--获取随机路点
function PathSystem:GetRandomWaypoint()
    local walkPath = self:GetRandomPath()
    if walkPath then
        return walkPath:GetRandomWaypoint()
    end
    return nil
end

--获取路径
function PathSystem:GetPath(name)
    for _, walkPath in ipairs(self.paths) do
        if walkPath.name == name then
            return walkPath
        end
    end
    return nil
end

--添加路径
function PathSystem:AddPath(name, rootNode, maxActors)
    local path = Waypath.New(name, self, maxActors)
    self:OnInitWaypath(path, rootNode)
    path:InitFromNodes(rootNode)
    table.insert(self.paths, path)
    return path
end

--初始化路径
function PathSystem:InitPaths(rootNodes)
    self:DestroyAllPaths()
    if rootNodes then
        for _, rootNode in ipairs(rootNodes.Children) do
            local name = rootNode.Name
            self:AddPath(name, rootNode, true)
        end
    end
end

--销毁所有路径
function PathSystem:DestroyAllPaths()
    for _, walkPath in ipairs(self.paths) do
        walkPath:Destroy()
    end
    self.paths = {}
end
--创建漫步者
function PathSystem:CreateActor(waypoint)
    local workspace = self.scene:GetWorkspace()
    local pos, rotation = self:GetPositionAndRotation(waypoint)
    local config = DataProviderManager:GetData(self.actorType,self.actorTid)
    if config == nil then
        Log:Error("PathSystem:CreateActor", "Invalid config tid: " .. tostring(self.actorTid))
        return
    end
    local nodeTemplate = Utils:GetMainStorageNode(config.asset)
    if nodeTemplate == nil then
        Log:Error("PathSystem:CreateActor", "Invalid asset tid: " .. tostring(self.actorTid))
        return
    end
    local ActorManager = GFScript("ActorModule.ActorManager")
    local actor = ActorManager:ServerCreateActor(workspace, self.actorType, nodeTemplate, true, function(actor)
        actor:LoadConfigFromTid(self.actorTid)
        actor:SetBornPosition(pos)
        actor.AvatarComponent:SetPosition(pos)
        if rotation then
            actor.AvatarComponent:SetRotation(rotation)
        end

        self:OnInitActor(actor, waypoint)
    end)
    return actor
end

--初始化漫步者
function PathSystem:OnInitActor(actor, waypoint)

end

--初始化路径
function PathSystem:OnInitWaypath(path, node)

end

--初始化路点
function PathSystem:OnInitWaypoint(waypoint, node)
    
end

return PathSystem