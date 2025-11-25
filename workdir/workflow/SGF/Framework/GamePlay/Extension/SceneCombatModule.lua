local Log = GFScript("CoreModule.Log")
local SceneCombatManager = ExtensionScript("SceneCombatModule.SceneCombatManager")
local SceneCombatModule = {}

--版本号
SceneCombatModule.version = "1.0.0"
--模块名字
SceneCombatModule.moduleName = "SceneCombatModule"
--模块描述
SceneCombatModule.moduleDesc = "场景和战斗模块"
--日志标签
SceneCombatModule.logTag = "SceneCombatData"

--是否已经启动过
SceneCombatModule.isStartup = false


--更新
function SceneCombatModule:OnUpdate(dt)
    SceneCombatManager:Update(dt)
end


--启动
function SceneCombatModule:Startup()
    if self.isStartup then
        return
    end

    SceneCombatManager:Init()
    

    self.isStartup = true
end

return SceneCombatModule