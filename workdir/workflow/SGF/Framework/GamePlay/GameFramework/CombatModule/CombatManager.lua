local Log = GFScript("CoreModule.Log")
local CombatManager = {}

--初始化
function CombatManager:Init()
    RegisterComponentFactory(GFScript("CombatModule.CombatComponent"))
    RegisterComponentFactory(GFScript("CombatModule.CampComponent"))
    RegisterComponentFactory(GFScript("CombatModule.TargetingComponent"))
    RegisterComponentFactory(GFScript("CombatModule.HateComponent"))
end

--更新
function CombatManager:Update(dt)
end

return CombatManager