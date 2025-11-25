local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local ActionManager = GFScript("ActorModule.ActionManager")
local SpawnerManager = GFScript("ActorModule.SpawnerManager")
local SceneManager = GFScript("ActorModule.SceneManager")
local WeatherManager = GFScript("ActorModule.Weather.WeatherManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local ActorModule = {}

--版本号
ActorModule.version = "1.0.0"
--模块名字
ActorModule.moduleName = "ActorModule"
--模块描述
ActorModule.moduleDesc = "Actor模块"
--日志标签
ActorModule.logTag = "Actor"
--Gm指令
ActorModule.GmCommands = {GFScript("ActorModule.ActorGmCommands")}

--是否已经启动过
ActorModule.isStartup = false


--更新
function ActorModule:OnUpdate(dt)
    ActorManager:Update(dt)
    ActionManager:Update(dt)
    SpawnerManager:Update(dt)
    SceneManager:Update(dt)
    WeatherManager:Update(dt)
end

--启动
function ActorModule:Startup()
    if self.isStartup then
        return
    end

    ActorManager:Init()
    ActionManager:Init()
    SpawnerManager:Init()
    SceneManager:Init()
    WeatherManager:Init()

    self.isStartup = true
end


--添加全局的蚕卵注册函数
_G.AddNpcSpawner = function(bindObj, params, interval)
    SpawnerManager:AddSpawner(bindObj, "Npc", params, interval)
end

--产卵怪物
_G.SpawnActor = function(workspace, tid, x, y, z)
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        Log:Error("SpawnActor failed, x = %s, y = %s, z = %s", x, y, z)
        return
    end
    
    if config == nil then
        Log:Error("SpawnActor failed, tid = %s",tid)
        return
    end
    local nodeTemplate = Utils:GetMainStorageNode(config.modelId)
    if nodeTemplate == nil then
        Log:Error("SpawnActor failed, tid = %s",tid)
        return
    end
    local actor = ActorManager:ServerCreateActor(workspace, ActorUtils:GetActorType(tid), nodeTemplate, true, function(actor)
        local pos = Vec3.New(x,y,z)
        actor:LoadConfigFromTid(tid)
        actor:SetBornPosition(pos)
        actor.AvatarComponent:SetPosition(pos)
    end)
    return actor
end


return ActorModule