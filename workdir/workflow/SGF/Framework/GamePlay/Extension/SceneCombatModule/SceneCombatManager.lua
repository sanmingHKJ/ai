local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local UIManager = GFScript("UIModule.UIManager")
local BuffManager = GFScript("BuffModule.BuffManager")
local ActorManager = GFScript("ActorModule.ActorManager")

local GNpc = ExtensionScript("SceneCombatModule.Actor.GNpc")
local GPet = ExtensionScript("SceneCombatModule.Actor.GPet")

local SceneCombatManager = {}

--初始化
function SceneCombatManager:Init() 
    ActorManager:RegisterActorFactory("Pet", GPet)
end

--更新  
function SceneCombatManager:Update(dt)

end

return SceneCombatManager
