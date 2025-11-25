local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local PathSystem = GFScript("ActorModule.PathSystem")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local PedestrianDefines = GFScript("ActorModule.PedestrianSystem.PedestrianDefines")
local Math = GFScript("CoreModule.Math")
local TrafficSystem = Class.New("TrafficSystem", PathSystem)

function TrafficSystem:Constructor()
    self.defaultMaxWalkers = 5
    self.defaultSpawnType = "Line"
    self.defaultAI = "Walker1"

    self.enabled = true
end

function TrafficSystem:OnDestructor()
    
end
--初始化
function TrafficSystem:Init(scene)
    TrafficSystem.super.Init(self, scene)
end

--更新
function TrafficSystem:Update(dt)
    TrafficSystem.super.Update(self, dt)
end

--初始化漫步者
function TrafficSystem:OnInitActor(actor, waypoint)
    actor:SetCollideGroup(ActorDefines.CollideGroup.Walker)
    actor.AvatarComponent:SetMoveType(Math:Random(0, 100) > 20 and AvatarDefines.EMoveType.Walk or AvatarDefines.EMoveType.Run)

    local aiComponent = actor:GetDerivedComponent("AIComponent")
    if aiComponent then
        if waypoint.params.ai then
            aiComponent:LoadConfigFromTid(waypoint.params.ai)
        else
            aiComponent:LoadConfigFromTid(self.defaultAI)
        end
    end
    actor.walkPath = waypoint:GetPath():GetName()
    --随机正向或者反向
    actor.walkDir = (Math:Random(0, 100) > 50 and 1 or -1)
    --随机外观
    local character = actor:GetCharacter()
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
end

--初始化路径
function TrafficSystem:OnInitWaypath(path, node)
    local maxWalkers = node:GetAttribute("MaxWalkers") or self.defaultMaxWalkers
    local spawnType = node:GetAttribute("SpawnType") or self.defaultSpawnType
    local ai = node:GetAttribute("AI") or self.defaultAI
    path:SetMaxActors(maxWalkers)
    path:SetSpawnType(spawnType)
    path:SetAI(ai)
    path:SetLoop(true)
end

--初始化路点
function TrafficSystem:OnInitWaypoint(waypoint, node)
    waypoint.params.skinId = node:GetAttribute("SkinId")
    waypoint.params.ai = node:GetAttribute("AI")
    if type(waypoint.params.skinId) == "string" then
        waypoint.params.skinId = Utils:SplitToNumber(waypoint.params.skinId,",")
    end
end

return TrafficSystem