local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local SNpc = require( script.Parent.SNpc)

-- 服务端怪物
local SMonster = Class.New("SMonster", SNpc)

function SMonster:InitServer()
    SMonster.super.InitServer(self)
end

function SMonster:Update(dt)
    SMonster.super.Update(self, dt)
end
--更新
function SMonster:LaterUpdate(dt)
    SMonster.super.LaterUpdate(self, dt)
end

--从tid加载数据
function SMonster:GetConfigName()
    return ActorUtils:GetActorTable(ActorDefines.EActorType.Monster).Actor
end

--加载配置
function SMonster:OnLoadConfig(config)
    SMonster.super.OnLoadConfig(self, config)
end

return SMonster