
local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local AIComponent = GFScript("AIModule.AIComponent")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local StateMachine = GFScript("CoreModule.StateMachine")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local SkillDefines = GFScript("SkillModule.SkillDefines")

local BTreeMonsterAI = Class.New("BTreeMonsterAI", AIComponent)

--实例化
function BTreeMonsterAI:Constructor()
end

return BTreeMonsterAI