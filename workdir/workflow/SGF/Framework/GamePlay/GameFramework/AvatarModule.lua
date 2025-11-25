
local Log = GFScript("CoreModule.Log")
local AvatarManager = GFScript("AvatarModule.AvatarManager")
local AvatarModule = {}

--版本号
AvatarModule.version = "1.0.0"
--模块名字
AvatarModule.moduleName = "AvatarModule"
--模块描述
AvatarModule.moduleDesc = "Avatar模块"
--日志标签
AvatarModule.logTag = "AvatarData"

--是否已经启动过
AvatarModule.isStartup = false


--更新
function AvatarModule:OnUpdate(dt)
    AvatarManager:Update(dt)
end


--启动
function AvatarModule:Startup()
    if self.isStartup then
        return
    end

    AvatarManager:Init()
    

    self.isStartup = true
end

return AvatarModule