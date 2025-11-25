local Log = GFScript("CoreModule.Log")
local StatManager = GFScript("StatModule.StatManager")
local StatModule = {}

--版本号
StatModule.version = "1.0.0"
--模块名字
StatModule.moduleName = "StatModule"
--模块描述
StatModule.moduleDesc = "Stat模块"
--日志标签
StatModule.logTag = "Stat"

--是否已经启动过
StatModule.isStartup = false


--更新
function StatModule:OnUpdate(dt)
    StatManager:Update(dt)
end


--启动
function StatModule:Startup()
    if self.isStartup then
        return
    end

    StatManager:Init()
    

    self.isStartup = true
end

return StatModule