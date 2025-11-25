local Class = GFScript("CoreModule.Class")
local Summon = GFScript("ActorModule.Summon")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")

-- 服务端召唤物
local SSummon = Class.New("SSummon", Summon)

function SSummon:InitServer()
    SSummon.super.InitServer(self)
end

function SSummon:Update(dt)
    SSummon.super.Update(self, dt)
end
--更新
function SSummon:LaterUpdate(dt)
    SSummon.super.LaterUpdate(self, dt)
end

-----------------------------------技能事件-----------------------------------
function SSummon:SkillEvent_ApplyDamage(params)
end

return SSummon