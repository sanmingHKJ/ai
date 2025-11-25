local Log = GFScript("CoreModule.Log")
local GmManager = GFScript("GmModule.GmManager")
local GmModule = {}

--版本号
GmModule.version = "1.0.0"
--模块名字
GmModule.moduleName = "GmModule"
--模块描述
GmModule.moduleDesc = "Gm模块"
--日志标签
GmModule.logTag = "GmData"

--是否已经启动过
GmModule.isStartup = false


--更新
function GmModule:OnUpdate(dt)
    GmManager:Update(dt)
end


--启动
function GmModule:Startup()
    if self.isStartup then
        return
    end

    GmManager:Init()
    

    self.isStartup = true
end

--收集一个模块的Gm指令
function GmModule:CollectGmCommands(module)
    local function RegisterCommand(GmCommands)
        for _, command in ipairs(GmCommands.commands) do
            GmManager:RegisterCommand(GmCommands.category, GmCommands.order or 0, command.name, command.example, command.description, command.callback, true)
        end
        for _, command in ipairs(GmCommands.clientCommands) do
            GmManager:RegisterCommand(GmCommands.category, GmCommands.order or 0, command.name, command.example, command.description, command.callback, false)
        end
    end
    if module.GmCommands then
        if module.GmCommands.category then
            RegisterCommand(module.GmCommands)
        else
            for _, GmCommand in ipairs(module.GmCommands) do
                RegisterCommand(GmCommand)
            end
        end
    end
end

--初始化
function GmModule:OnPostInitialization()
    --收集所有模块的Gm指令
    GameFramework:ForEachModule(function(module)
        self:CollectGmCommands(module)
    end)
end

return GmModule