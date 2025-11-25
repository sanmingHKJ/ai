local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local TimerManager = GFScript("CoreModule.TimerManager")
local BaseTest = GFScript("TestModule.BaseTest")
local Players = game:GetService("Players")
local ActorManager = GFScript("ActorModule.ActorManager")
local Actor = GFScript("ActorModule.Actor")

local ActorTest = Class.New("ActorTest", BaseTest)


function ActorTest:Constructor()
    self.testName = "ActorTest"
end

--运行服务端测试
function ActorTest:RunServer()
    Log:Info("ActorTest RunServer")
    --当玩家添加的时候
    Players.PlayerAdded:Connect(function(player)
        ActorManager:ServerCreateActor(nil, "Player", player,false,function(actor)
            actor:AddComponent("StatComponent")
            actor:AddComponent("CombatComponent")
            actor:AddComponent("SkillComponent")
            actor.StatComponent:SetBaseValue("attack",600)
            --先默认添加一个技能
            actor.SkillComponent:AddSkill(1)

            -- --添加一个定时器，不断对自己造成伤害
            -- TimerManager:AddTimer(function()
            --     --进行伤害测试
            --     local damageData = {
            --         causer = actor, --伤害来源
            --         target = actor, --伤害目标
            --         damage = 50, --伤害值
            --         damageType = 0, --伤害类型
            --         skillId = 0, --伤害来源技能id
            --         skillLevel = 0, --伤害来源技能等级
            --     }
            --     actor.CombatComponent:ApplyDamage(damageData) 
            -- end,1,5)
        end)
    end)
    --当玩家移除的时候
    Players.PlayerRemoving:Connect(function(player)
        local playerActor = ActorManager:GetServerActor(player.Name)
        ActorManager:ServerDestroyActor(playerActor)
    end)

    --监听ActorManager事件
    ActorManager:OnServerEvent("ActorCreated",function(actor)
        Log:Info("ServerActorCreated actorName: "..actor:GetName())

        --属性改变事件
        actor:OnServerEvent("StatChanged",function(statName,oldValue,newValue)
            Log:Info("ServerStatChanged statName: "..statName.." statValue: "..newValue)
        end)

        --承受伤害事件
        actor:OnServerEvent("TakeDamage",function(damageResult)
            Log:Info("ServerTakeDamage damage: "..damageResult.damage)
        end)

        --技能事件
        actor:OnServerEvent("SkillEvent",function(skill,event,params)
            Log:Info("ServerSkillEvent event:%s params:%s ",event,Utils:T2S(params))
        end)
    end) 

end

--运行客户端测试
function ActorTest:RunClient()
    ActorManager:OnClientEvent("ActorCreated",function(actor)
        Log:Info("ClientActorCreated actorName: "..actor:GetName())
        -- Log:Info("ClientActorCreated Attack: "..actor.StatComponent:GetValue("attack"))

        --属性改变事件
        actor:OnClientEvent("StatChanged",function(statName,oldValue,newValue)
            Log:Info("ClientStatChanged statName: "..statName.." statValue: "..newValue)
        end)

        --承受伤害事件
        actor:OnClientEvent("TakeDamage",function(damageResult)
            Log:Info("ClientTakeDamage damage: "..damageResult.damage)
        end)

        
        --技能事件
        actor:OnClientEvent("SkillEvent",function(skill,event,params)
            Log:Info("SkillEvent event:%s params:%s ",event,Utils:T2S(params))
        end)

        
        --释放技能
        TimerManager:AddTimer(function()
            actor.SkillComponent:StartCast(1)
        end,1,1)

    end)
end


return ActorTest