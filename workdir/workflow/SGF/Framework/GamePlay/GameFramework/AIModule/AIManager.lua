local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local AIManager = {}

--初始化
function AIManager:Init()
    RegisterComponentFactory(GFScript("AIModule.AIPerception"))
    RegisterComponentFactory(GFScript("AIModule.AIPerceptionSignal"))
    
    RegisterComponentFactory(GFScript("AIModule.AIComponent"))
    RegisterComponentFactory(GFScript("AIModule.BTreeMonsterAI"))
end

--更新
function AIManager:Update(dt)
end

return AIManager