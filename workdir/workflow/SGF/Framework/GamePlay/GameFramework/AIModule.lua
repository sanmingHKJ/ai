local Log = GFScript("CoreModule.Log")
local AIManager = GFScript("AIModule.AIManager")
local AIModule = {}

--版本号
AIModule.version = "1.0.0"
--模块名字
AIModule.moduleName = "AIModule"
--模块描述
AIModule.moduleDesc = "AI模块"
--日志标签
AIModule.logTag = "AI"

--是否已经启动过
AIModule.isStartup = false


--更新
function AIModule:OnUpdate(dt)
    AIManager:Update(dt)
end


--启动
function AIModule:Startup()
    if self.isStartup then
        return
    end

    AIManager:Init()
    

    self.isStartup = true
end


return AIModule