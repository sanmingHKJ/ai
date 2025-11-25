local Class = GFScript("CoreModule.Class")
local Player = GFScript("ActorModule.Player")
local TimerManager = GFScript("CoreModule.TimerManager")
local ActorManager = GFScript("ActorModule.ActorManager")
local MainStorage = game:GetService("MainStorage")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Stat = GFScript("StatModule.Stat")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")

-- 服务端玩家
local SPlayer = Player.Extend("SPlayer")
SPlayer.version = 1


function SPlayer:Constructor()
    
end

function SPlayer:Destructor()
    MS.NetworkHelper:UnregisterNetObj(self)
end

function SPlayer:CheckSession(userId)
    return userId == self:GetPlayerId()
end

function SPlayer:InitServer()
    MS.NetworkHelper:RegisterNetObj(self)
    SPlayer.super.InitServer(self)

    self.BasePlayerData = {
        level=1,
        maxStamina=100,      --最大体力值
        curStamina=100,          --当前体力值
        curExp=0,
        lastLoginTime = 0,         --离线时间
        diamond = 0,            --钻石
        bounty = 0,                 --赏金
        cumulativeRecharge = 0,    --累充迷你币数额
    }
    self:OnServerEvent("SkillEvent", 
    function(skill,event,params)
        local func = self["SkillEvent_"..event]
        if type(func) == "function" then
            func(self, skill, params)
        end
    end)

    self:OnServerEvent("CauseDamage",
        function(damageResult)
            self:CauseDamage(damageResult)
            
        end)
    self:OnServerEvent("TakeDamage", 
        function(damageResult)
            self:TakeDamage(damageResult)
        end)
    self:OnServerEvent("StateChanged", 
        function(oldState,newState)

        end)

    self:OnServerEvent("AngerChanged", 
        function(oldValue, newValue)
            --怒气改变
            
        end)

    self:OnServerEvent("HealthChanged", 
        function(oldValue, newValue)
            
        end)

    self:OnServerEvent("StaminaChanged", 
        function(oldValue, newValue)
        
        end)

    self:OnServerEvent("Kill", 
        function(target)
            if target:IsPlayer() then
                
            end
        end) 

    self:OnServerEvent("Dead", 
        function()
            
        end)

    self:OnServerEvent("Revive",
        function()
        
        end)

    self:OnServerEvent("RemoveBuff", 
        function(buff)
            
        end)

    self:OnServerEvent("SummonPet",     
        function(pet, petActor)
            local Players = game:GetService("Players")
            local player = Players:GetPlayerByUserId(self:GetPlayerId())
            if player then
                local landData = XPlants.LandExpansion:GetLand(player)
                if landData and landData.Position then
                    local pos = landData.Position
                    local centerX = pos.x
                    local centerZ = pos.z
                    local width = 3900
                    local depth = 3900

                    local startX = centerX - width / 2
                    local startZ = centerZ - depth / 2
                    local endX = centerX + width / 2
                    local endZ = centerZ + depth / 2
                    --设置宠物的活动范围
                    local validPos = self:GetValidPosition(Vec3.New(centerX, 200, centerZ))
                    petActor:SetBornPosition(validPos)
                    petActor.AIComponent:SetBlackboardValue("RandomMove_Area", {startX, startZ, endX, endZ})
                end
            end
            
        end)

    self:OnServerEvent("DestroySummonPet", 
        function(pet, petActor)

        end)
end


--加载数据完毕
function SPlayer:LoadFinished()

    self.node = self:GetCharacter()
    self:HandlePlayerInit(self:GetPlayerId())
        
    SPlayer.super.LoadFinished(self)
end


function SPlayer:HandlePlayerInit(userId)
    print("[SPlayer]"..userId.." 加载角色成功")
end


--场景设置的时候
function SPlayer:OnSceneSet(scene)
    SPlayer.super.OnSceneSet(self, scene)
end

function SPlayer:SkillEvent_RemoveProjectiles(params)
end

--新数据
function SPlayer:NewData()
    
end

-- 获取数据
function SPlayer:GetData()
    local data = SPlayer.super.GetData(self)
    data.version = SPlayer.version
    return data
end

-- 设置数据
function SPlayer:SetData(data)
    SPlayer.super.SetData(self, data)
end

-- 造成伤害
function SPlayer:CauseDamage(damageResult)
end
-- 受到伤害
function SPlayer:TakeDamage(damageResult)
end

--从另外一个Actor拷贝信息
function SPlayer:CopyFrom(src)
    SPlayer.super.CopyFrom(self, src)
end

--更新客户端
function SPlayer:UpdateServer(dt)
    SPlayer.super.UpdateServer(self, dt)
end

--------------------------------------LoadConfig--------------------------------------

--加载配置
function SPlayer:OnLoadConfig(config)
    SPlayer.super.OnLoadConfig(self, config)
    
end

return SPlayer