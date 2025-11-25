local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local ActorManager = GFScript("ActorModule.ActorManager")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")

local Spawner = Class.New("Spawner")

function Spawner:Constructor()
    self.spawnType = ""
    self.spawnInterval = 10
    self.spawnTimeEnd = 0
    self.bindObj = 0
    self.spawnedActors = {}
    self.params = nil
end

--初始化
function Spawner:Init(bindObj, spawnType, params, spawnInterval)
    self.bindObj = bindObj
    self.spawnType = spawnType
    self.params = params
    self.spawnInterval = spawnInterval
    --立刻产卵一个
    self:Spawn()
end

--更新，返回true表示要删除
function Spawner:Update()
    if self.spawnTimeEnd ~= 0 then
        if Utils:GetServerTime() >= self.spawnTimeEnd then
            self:Spawn()
        end
    end
    return false
end

--开始冷却
function Spawner:StartCooldown()
    self.spawnTimeEnd = Utils:GetServerTime() + self.spawnInterval
end

--产卵
function Spawner:Spawn()
    self:OnSpawn()
    self.spawnTimeEnd = 0
end

function Spawner:OnSpawn()
    local func = self["Spawn_"..self.spawnType]
    if func then
        local position = self.bindObj.Position
        local pos = Vec3.New(position.x,position.y,position.z)
        func(self, pos, self.params)
    end
end
--产卵怪物
function Spawner:Spawn_Monster(pos, params)
    local tid = params
    local config = DataProviderManager:GetData("Monster",tid)
    if config == nil then
        Log:Error("Spawner:Spawn_Monster failed, tid = %d",tid)
        return
    end
    local nodeTemplate = Utils:GetMainStorageNode(config.modelId)
    if nodeTemplate == nil then
        Log:Error("Spawner:Spawn_Monster failed, tid = %d",tid)
        return
    end
    local actor = ActorManager:ServerCreateActor(nil, "Monster", nodeTemplate, true, function(actor)
        actor:LoadConfigFromTid(tid)
        actor:SetBornPosition(pos)
        actor.AvatarComponent:SetPosition(pos)
    end)
    table.insert(self.spawnedActors, actor)
end

return Spawner

