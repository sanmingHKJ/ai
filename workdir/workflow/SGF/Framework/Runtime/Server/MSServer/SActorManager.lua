-- 服务端SSActorManager玩家管理器
local Log = GFScript("CoreModule.Log")
local ActorManager = GFScript("ActorModule.ActorManager")
local SkillDefines = GFScript("SkillModule.SkillDefines")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local DataPlayersManager = GFScript("CoreModule.DataPlayersManager")
local TimerManager = GFScript("CoreModule.TimerManager")

local sPlayer = require(script.SPlayer)
local Utils = GFScript("CoreModule.Utils")

local SActorManager = {}

function SActorManager:Init()
    MS.NetworkHelper:RegisterNetObj(self)
    self.playerCnt = 0
    self.playerDic = {}
    self:InitEvents()
end

function SActorManager:InitEvents()
    MS.Players.PlayerAdded:Connect(function(player)
        Log:Debug("Server Players.PlayerAdded ..UserId = "..player.UserId)
        ActorManager:ServerCreateActor(nil, "Player", player, false, function(actor)
            self.playerDic[player.UserId] = actor
            actor:Login()
            self:OnPlayerAdded(player)
            --加载默认配置
            actor:LoadConfigFromTid("101")
        end)
    end)

    MS.Players.PlayerRemoving:Connect(function(player)
        local playerActor = ActorManager:GetServerActor(player)
        playerActor:Logout()
        self:OnPlayerRemoved(player)
        self.playerDic[player.UserId] = nil
        ActorManager:ServerDestroyActor(playerActor)
    end)

    ActorManager:OnServerEvent("ActorCreated", function(actor)
        -- 这里拿不到英雄已装备的宠物，暂时放在scloudmanager中
        -- if actor:IsPlayer() then
        --     local heroId = actor.playerData.data.curUseHeroId
        --     actor.SPetManager:EquipPet(heroId)
        -- end
    end)
    

end

function SActorManager:ForEachPlayer(iter)
    for _, player in pairs(self.playerDic) do
        if iter(player) then
            break
        end
    end
end

function SActorManager:GetPlayerByUserId(userId)
    return self.playerDic[userId]
end

-- 玩家加入
function SActorManager:OnPlayerAdded(player)
    print("玩家加入房间：",player.UserId)
end
-- 玩家离开
function SActorManager:OnPlayerRemoved(player)
    print("玩家离开房间：",player.UserId)
end

return SActorManager
