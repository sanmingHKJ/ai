local Log = GFScript("CoreModule.Log")
local Class = GFScript("CoreModule.Class")
local TimerManager = GFScript("CoreModule.TimerManager")
local Tween = GFScript("CoreModule.Tween")
local Debugger = GFScript("CoreModule.Debugger")
local Database = GFScript("CoreModule.Database")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local EffectManager = GFScript("CoreModule.Effect.EffectManager")
local Resource = GFScript("CoreModule.Resource")
local CoreModule = {}

--版本号
CoreModule.version = "1.0.0"
--模块名字
CoreModule.moduleName = "CoreModule"
--模块描述
CoreModule.moduleDesc = "Common模块"
--日志标签
CoreModule.logTag = "Common"

--是否已经启动过
CoreModule.isStartup = false


--更新
function CoreModule:OnUpdate(dt)
    TimerManager:Update(dt)
    Tween:Update(dt)
    Debugger:Update(dt)
    Database:Update(dt)
    SoundManager:Update(dt)
    Resource:Update(dt)
    EffectManager:Update(dt)
    --更新Class
    Class:Update()
end

--启动
function CoreModule:Startup()
    if self.isStartup then
        return
    end

    TimerManager:Init()
    Debugger:Init()
    Database:Init(60)
    SoundManager:Init()
    Resource:Init()
    EffectManager:Init()

    self.isStartup = true
end

function CoreModule:OnPostInitialization()
    SoundManager:OnPostInitialization()
end


return CoreModule