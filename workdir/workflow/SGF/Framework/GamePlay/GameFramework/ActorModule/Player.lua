local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local EventObject = GFScript("CoreModule.EventObject")
local Database = GFScript("CoreModule.Database")
local Actor = GFScript("ActorModule.Actor")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local ActorManager = GFScript("ActorModule.ActorManager")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local Network = GFScript("NetworkModule.Network")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local ActorSettings = GFScript("ActorModule.ActorSettings")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local TimerManager = GFScript("CoreModule.TimerManager")

local Player = Class.New("Player", Actor)
--版本号
Player.version = 1

--构造
function Player:Constructor(actorId, actorType, bObj, isServer)
    self.serverId = 0

    self.loginTime = 0
    self.logoutTime = 0
end

--析构
function Player:Destructor()
end

function Player:Init()
    self:SetCollideGroup(ActorDefines.CollideGroup.Player)
    Player.super.Init(self)
end


--服务端初始化
function Player:InitServer()
    self:AddComponent("DataComponent")
    --注册数据表
    self.DataComponent:RegisterTable("Player", self)
    Player.super.InitServer(self)

    --注册网络协议
    self:ServerNetCallback(ActorNetProto.RequestSelectServer, self.OnRequestSelectServer, self)
    self:ServerNetCallback(ActorNetProto.RequestSetTarget, self.OnRequestSetTarget, self)

    --加载游戏配置
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
    else
        self:ApplyServerGameSettings(gameSetting)

        if gameSetting.General.gmEnabled then
            self:AddComponent("GmComponent")
        end
    end
    self.GameServerSettings = gameSetting
end
--客户端初始化
function Player:InitClient()
    Player.super.InitClient(self)
    
    --注册网络协议
    self:ClientNetCallback(ActorNetProto.ResponseSelectServer, self.OnResponseSelectServer, self)
    self:ClientNetCallback(ActorNetProto.ResponseSetTarget, self.OnResponseSetTarget, self)
    self:ClientNetCallback(ActorNetProto.ResponseServerInfo, self.OnResponseServerInfo, self)
    
    --加载游戏配置
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
    else
        self:ApplyClientGameSettings(gameSetting)
    end
    self.GameClientSettings = gameSetting

    self:SetCollideGroup(ActorDefines.CollideGroup.Player)
end

--初始化服务端组件
function Player:InitServerComponents()
    Player.super.InitServerComponents(self)
    --添加必要组件
    self:AddComponent("ScheduleComponent")
    self:AddComponent("PetComponent")
    self:AddComponent("AIPerceptionSignal")

    self:AddComponent("StaminaComponent")
    self:AddComponent("TargetingComponent")
    self:AddComponent("LevelComponent")
    self:AddComponent("ExpComponent")

    self:AddComponent("SummonComponent")

end

--初始化客户端组件
function Player:InitClientComponents()
    Player.super.InitClientComponents(self)
    self:AddComponent("CameraController")
    self:AddComponent("PostProcessing")
    if self:IsLocalPlayer() then
        self:AddComponent("TriggerAgent")
        self:AddComponent("FirearmSystem")
    end
end

--更新客户端
function Player:UpdateClient(dt)
    Player.super.UpdateClient(self, dt)
end

--获取数据
function Player:GetData()
    local data = {}
    data.logoutTime = self.logoutTime
    return data
end

--设置数据
function Player:SetData(data)
    self.logoutTime = data.logoutTime
end

function Player:SerializeSelf(data)
    Player.super.SerializeSelf(self, data)
    data.loginTime = self.loginTime
    data.logoutTime = self.logoutTime
end

function Player:DeserializeSelf(data)
    Player.super.DeserializeSelf(self, data)
    self.loginTime = data.loginTime
    self.logoutTime = data.logoutTime
end

--应用游戏设置
function Player:ApplyServerGameSettings(settings)
    Player.super.ApplyServerGameSettings(self, settings)
end

--是否是玩家
function Player:IsPlayer()
    return true
end
--添加到场景
function Player:OnAddToScene()
    -- if not self:IsServer() and self:IsLocalPlayer() then
    --     local camera = self.scene:GetWorkspace().Camera
    --     if camera then
    --         self.CameraController:SetCamera(camera)
    --     end
    -- end
end
--获取服务器Id
function Player:GetServerId()
    return self.serverId
end

--设置服务器id
function Player:ServerSetServerId(serverId,resetData,finishedCallback)
    if not self:HasAuthority() then
        return 
    end
    self.serverId = serverId
    if self.serverId ~= 0 then
        local actorId = self.actorId
        local playerId = self.playerId
        resetData = false           --必须用false，不可更改
        self:SetReady(false)
        --加载全部数据
        self.DataComponent:LoadAll(function()
            self.actorId = actorId
            self.playerId = playerId
            --同步
            ActorManager:SyncPlayer(self)
            if finishedCallback then
                finishedCallback()
            end
            self:SetReady(true)
        end,resetData)
    end
end
--客户端设置服务器Id
function Player:SetServerId(serverId)
    self.serverId = serverId
    self:SendToServer(ActorNetProto.RequestSelectServer, {serverId = self.serverId})
end
--设置目标
function Player:SetTarget(target)
    if self:GetTarget() == target then
        if target == nil then
            return
        elseif self:CheckId(target:GetActorId()) then
            return
        else
            -- 数据有变化
        end
    end

    Player.super.SetTarget(self, target)
    if self:IsOwned() then
        --同步到服务端
        self:SendToServer(ActorNetProto.RequestSetTarget, 
        {
            actorId = self:GetActorId(),
            targetId = (target and target:GetActorId() or "")
        })
    end
end

--当状态改变
function Player:NotifyStateChanged(oldState,newState)
    Player.super.NotifyStateChanged(self, oldState, newState)
    if self.isServer then
        if newState == ActorDefines.EActorState.Idle then
            -- if self:IsShadow() then
            --     --延迟消失
            --     self:DelayCall(function()
            --         self.actorManager:ServerDestroyActorForShadow(self)
            --     end, 1)
            -- end
        end
    end
end
--尸体销毁时间已到
function Player:OnDeathDestroyTimeEnd()

end
-- 是否可以更新索敌状态
function Player:CanAutoSelectUpdate()
    return true
end
------------------------------------Server-------------------------------------
function Player:CallClientMoveBy(dir, angleOffset,distance,duration)
    local body = 
    {
        actorId = self:GetActorId(),
        dir = dir:ToTable(),
        angleOffset = angleOffset,
        distance = distance,
        duration = duration,
    }
    self:SendToClient(ActorNetProto.ResponseMoveBy, body)
end
function Player:OnRequestSelectServer(body)
    self:ServerSetServerId(body.serverId)
    self:SendToClient(ActorNetProto.ResponseSelectServer, {serverId = self.serverId})
end
function Player:OnRequestSetTarget(body)
    local targetId = body.targetId
    if targetId == "" then
        self:SetTarget(nil)
    else
        local target = ActorManager:GetServerActor(body.targetId)
        self:SetTarget(target)
    end
end
------------------------------------Client-------------------------------------
function Player:OnResponseSelectServer(body)
end
function Player:OnResponseSetTarget(body)
end

function Player:OnResponseServerInfo(body)
    local timeOffset = body.serverTime - Utils:GetLocalTime()
    Utils:SetServerTimeOffset(timeOffset)
end

function Player:CopyFrom(src)
    Player.super.CopyFrom(self, src)
    self.serverId = src.serverId
end

--登录
function Player:Login() 
    self.loginTime = os.time()
end

--登出
function Player:Logout()
    self.logoutTime = os.time()
    self.DataComponent:SaveAll()
end

--获取本次上线以后距离上一次下线的时间差
function Player:GetLoginTimeDiff()
    if not Utils:IsNullOrZero(self.loginTime) and not Utils:IsNullOrZero(self.logoutTime) then
        return self.loginTime - self.logoutTime
    end
    return 0
end


--------------------------------------LoadConfig--------------------------------------

--从tid加载数据
function Player:GetConfigName()
    return ActorUtils:GetActorTable(ActorDefines.EActorType.Player).Actor
end

--加载配置
function Player:OnLoadConfig(config)
    self.nickName = config.name
    self.desc = config.desc
    self.icon = config.icon
    --加载基础属性
    self.StatComponent:Reset()
    if config.stats then
        for k,v in pairs(config.stats) do
            self.StatComponent:SetBaseValue(k, v)
        end
    end
    --设置为满血状态
    local maxHealth = self.StatComponent:GetBaseValue("MaxHealth")
    self.StatComponent:SetBaseValue("Health", maxHealth)
    self.HealthComponent:SyncToCharacter()

    local maxStamina = self.StatComponent:GetBaseValue("MaxStamina")
    self.StatComponent:SetBaseValue("Stamina", maxStamina)


end

--加载配置完毕
function Player:OnLoadConfigFinished(config)
    self:Fire(self:IsServer(), "LoadConfigFinished")
end

return Player