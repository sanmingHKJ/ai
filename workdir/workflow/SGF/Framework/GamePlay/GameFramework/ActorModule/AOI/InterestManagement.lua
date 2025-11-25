local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local EventObject = GFScript("CoreModule.EventObject")
local Grid2D = GFScript("ActorModule.AOI.Grid2D")
local Vec2 = GFScript("CoreModule.Math.Vec2")
local InterestManagement = Class.New("InterestManagement", EventObject)

--初始化
function InterestManagement:Init(visRange, isServer)
    self.actorManager = GFScript("ActorModule.ActorManager")
    --新的观察者列表
    self.newObservers = {}

    --网格
    self.visRange = visRange or 1500 --视野
    self.resolution = self.visRange / 2
    self.rebuildInterval = 1
    self.lastRebuildTimeEnd = 0
    self.isServer = isServer

    self.grid = Grid2D.New()
    self.grid:Init()
    --是否开启
    self.enabled = true
end

--设置是否开启
function InterestManagement:SetEnabled(value)
    self.enabled = value
end

--是否开启
function InterestManagement:IsEnabled()
    return self.enabled
end

--重置
function InterestManagement:Reset()
    self.lastRebuildTimeEnd = 0
    self.grid:ClearAll()
end
--检查观察者
function InterestManagement:OnCheckObserver(actor, player)
    --过滤掉不在同场景或者不在同频道的对象
    if actor:GetSceneId() ~= player:GetSceneId() then
        return false
    end
    local x1, y1 = self:ProjectToGrid(actor:GetPosition())
    local x2, y2 = self:ProjectToGrid(player:GetPosition())
    local offsetX = x1 - x2
    local offsetY = y1 - y2
    return (offsetX * offsetX + offsetY * offsetY) <= 2
end
--创建
function InterestManagement:OnSpawned(actor)
    
end
--销毁
function InterestManagement:OnDestroyed(actor)
    
end
--重建观察者
function InterestManagement:OnRebuildObservers(actor, newObservers)
    local x, y = self:ProjectToGrid(actor:GetPosition())
    local rets = {}
    self.grid:GetWithNeighbours(x, y, rets)
    for k,v in pairs(rets) do
        newObservers[v:GetActorId()] = v
    end
end
--重建
function InterestManagement:Rebuild(actor, initialize)
    if not self.enabled then
        return
    end
    self.newObservers = {}
    self:OnRebuildObservers(actor, self.newObservers)
    
    -- if actor:IsPlayer() then
    --     table.insert(self.newObservers, actor)
    -- end

    local changed = false
    
    for k,v in pairs(self.newObservers) do
        local obActorId = v:GetActorId()
        if initialize or not actor.observers[obActorId] then
            v:AddToObserving(actor, initialize)
            changed = true
        end
    end

    for k,v in pairs(actor.observers) do
        local obActorId = v:GetActorId()
        if not self.newObservers[obActorId] and not v.__delete__ then
            v:RemoveFromObserving(actor, false)
            changed = true
        end
    end

    if changed then
        actor.observers = {}
        for k,v in pairs(self.newObservers) do
            local obActorId = v:GetActorId()
            actor.observers[obActorId] = v
        end
    end

    if initialize then
        -- if not self.newObservers[actor.actorId] then
        --     self.actorManager:HideForPlayer(actor, actor)
        -- end
    end
end
--重建全部
function InterestManagement:RebuildAll(initialize)
    if not self.enabled then
        return
    end
    if self.isServer then
        for k,v in pairs(self.actorManager.serverActors) do
            self:Rebuild(v, initialize)
        end
    else
        for k,v in pairs(self.actorManager.clientActors) do
            self:Rebuild(v, initialize)
        end
    end
end

--添加观察者
function InterestManagement:AddObserver(player, target)
    player:AddToObserving(target)
    target:AddObserver(player)
end

--移除观察者
function InterestManagement:RemoveObserver(player, target)
    player:RemoveFromObserving(target, false)
    target:RemoveObserver(player)
end

--投影到格子空间
function InterestManagement:ProjectToGrid(position)
    return math.floor(position.x / self.resolution), math.floor(position.z / self.resolution)
end

--更新
function InterestManagement:Update()
    if not self.enabled then
        return
    end
    self.grid:ClearAll()

    if self.isServer then
        for k,v in pairs(self.actorManager.serverPlayers) do
            local x, y = self:ProjectToGrid(v:GetPosition())
            self.grid:Add(x, y, v)
        end
    else
        local localPlayer = self.actorManager:GetLocalPlayer()
        if localPlayer then
            local x, y = self:ProjectToGrid(localPlayer:GetPosition())
            self.grid:Add(x, y, localPlayer)
        end
    end

    if Utils:GetServerTime() >= self.lastRebuildTimeEnd + self.rebuildInterval then
        self:RebuildAll(false)
        self.lastRebuildTimeEnd = Utils:GetServerTime()
    end
end

return InterestManagement
