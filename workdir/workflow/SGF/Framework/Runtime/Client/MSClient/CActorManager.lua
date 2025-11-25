-- 客户端玩家管理器
local MainStorage = game:GetService("MainStorage")
local Utils = GFScript("CoreModule.Utils")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local ActorManager = GFScript("ActorModule.ActorManager")
local TimerManager = GFScript("CoreModule.TimerManager")
local UIManager = GFScript("UIModule.UIManager")
local Log = GFScript("CoreModule.Log")
local CActorManager = {}

function CActorManager:Init()
    MS.NetworkHelper:RegisterNetObj(self)

    self:InitEvents()
end

function CActorManager:InitEvents()
    -- 玩家加入
    ActorManager:OnClientEvent("ActorCreated",function(actor)
        if actor:IsPlayer() then
            self:OnPlayerAdded(actor)
        end
    end)

    ActorManager:OnClientEvent("ActorUpdated",function(actor)
        if actor:IsPlayer() then
        end
    end)

end

-- 玩家加入
function CActorManager:OnPlayerAdded(player)
    if player:IsLocalPlayer() then
        -- UIManager:OpenView("HudView")
        -- UIManager:UpdateView("HudView", 1, 2, 3)
        -- UIManager:UpdateView("HudView", 4, 5, 6)
        -- UIManager:OpenCrosshair()
        UIManager:OpenInputSystem()
        -- UIManager:OpenPickupNotification()

    end
end


return CActorManager