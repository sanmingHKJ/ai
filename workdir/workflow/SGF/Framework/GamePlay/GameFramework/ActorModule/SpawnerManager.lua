local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local Class = GFScript("CoreModule.Class")
local EventObject = GFScript("CoreModule.EventObject")
local Spawner = GFScript("ActorModule.Spawner")
local Vec3 = GFScript("CoreModule.Math.Vec3")

local SpawnerManager = Class.New("SpawnerManager", EventObject)

function SpawnerManager:Constructor()

end

--初始化
function SpawnerManager:Init()
    self.spawners = {}
end

--添加产卵器
function SpawnerManager:AddSpawner(bindObj, spawnType, params, interval)
    if Utils:IsServer() then
        local spawner = Spawner.New()
        spawner:Init(bindObj, spawnType, params, interval)
        table.insert(self.spawners, spawner)
    end
end

--更新
function SpawnerManager:Update(dt)
    for i = #self.spawners, 1, -1 do
        local spawner = self.spawners[i]
        if spawner:Update(dt) then
            table.remove(self.spawners, i)
        end
    end
end



return SpawnerManager