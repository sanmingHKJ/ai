local Log = GFScript("CoreModule.Log")
local Network = GFScript("NetworkModule.Network")
local NetworkModule = {}

--版本号
NetworkModule.version = "1.0.0"
--模块名字
NetworkModule.moduleName = "NetworkModule"
--模块描述
NetworkModule.moduleDesc = "Network模块"
--日志标签
NetworkModule.logTag = "Network"

--是否已经启动过
NetworkModule.isStartup = false


--更新
function NetworkModule:OnUpdate(dt)
    Network:Update(dt)
end


--启动
function NetworkModule:Startup()
    if self.isStartup then
        return
    end


    self.isStartup = true
end

function NetworkModule:OnPlayerAdded(player)
end

return NetworkModule