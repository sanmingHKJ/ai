local Log = GFScript("CoreModule.Log")
local PetManager = GFScript("PetModule.PetManager")
local PetModule = {}

--版本号
PetModule.version = "1.0.0"
--模块名字
PetModule.moduleName = "PetModule"
--模块描述
PetModule.moduleDesc = "Pet模块"
--日志标签
PetModule.logTag = "PetData"

--Gm指令
PetModule.GmCommands = {GFScript("PetModule.PetGmCommands")}

--是否已经启动过
PetModule.isStartup = false


--更新
function PetModule:OnUpdate(dt)
    PetManager:Update(dt)
end


--启动
function PetModule:Startup()
    if self.isStartup then
        return
    end

    PetManager:Init()
    

    self.isStartup = true
end

return PetModule