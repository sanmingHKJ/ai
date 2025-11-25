local Log = GFScript("CoreModule.Log")
local CombatManager = GFScript("CombatModule.CombatManager")
local CombatModule = {}

--版本号
CombatModule.version = "1.0.0"
--模块名字
CombatModule.moduleName = "CombatModule"
--模块描述
CombatModule.moduleDesc = "Combat模块"
--日志标签
CombatModule.logTag = "Combat"

--是否已经启动过
CombatModule.isStartup = false


--更新
function CombatModule:OnUpdate(dt)
    CombatManager:Update(dt)
end


--启动
function CombatModule:Startup()
    if self.isStartup then
        return
    end

    CombatManager:Init()
    

    self.isStartup = true
end

return CombatModule