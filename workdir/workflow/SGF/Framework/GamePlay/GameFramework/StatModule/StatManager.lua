local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local StatManager = {}

--初始化
function StatManager:Init()
    RegisterComponentFactory(GFScript("StatModule.StatComponent"))
    RegisterComponentFactory(GFScript("StatModule.HealthComponent"))
    RegisterComponentFactory(GFScript("StatModule.ManaComponent"))
    RegisterComponentFactory(GFScript("StatModule.AngerComponent"))
    RegisterComponentFactory(GFScript("StatModule.StaminaComponent"))
    RegisterComponentFactory(GFScript("StatModule.ExpComponent"))
    RegisterComponentFactory(GFScript("StatModule.LevelComponent"))
end

--更新
function StatManager:Update(dt)
end

return StatManager