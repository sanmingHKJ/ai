local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Network = GFScript("NetworkModule.Network")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local Class = GFScript("CoreModule.Class")
local EventObject = GFScript("CoreModule.EventObject")
local Database = GFScript("CoreModule.Database")
local SceneManager = GFScript("ActorModule.SceneManager")
local MoveBy = GFScript("ActorModule.Action.MoveBy")
local MoveTo = GFScript("ActorModule.Action.MoveTo")
local JumpBy = GFScript("ActorModule.Action.JumpBy")
local JumpTo = GFScript("ActorModule.Action.JumpTo")
local Quat = GFScript("CoreModule.Math.Quat")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Vec2 = GFScript("CoreModule.Math.Vec2")
local Profiler = GFScript("CoreModule.Profiler")
local TableUtils = GFScript("CoreModule.TableUtils")
local InterestManagement = GFScript("ActorModule.AOI.InterestManagement")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local ActorManager = Class.New("ActorManager", EventObject)
local PhysXService = game:GetService("PhysXService")
local UserInputService = game:GetService("UserInputService")
local MouseService = game:GetService("MouseService")

--actor同步流程
--创建节点，带有tag，以及对应的netid
--客户端收到以后，在根据这些信息发送协议到服务端查询对应的数据
--服务端查询数据以后，返回给客户端
--客户端根据数据创建actor

--启用性能分析
ActorManager.profilerEnabled = false

--actor列表
ActorManager.clientActors = {}
ActorManager.serverActors = {}

ActorManager.clientNetActors = {}
ActorManager.serverNetActors = {}

--玩家列表
ActorManager.serverPlayers = {}
ActorManager.clientPlayers = {}

--actor创建工厂
ActorManager.serverActorFactory = {}
ActorManager.clientActorFactory = {}
--组件创建工厂
ActorManager.componentFactory = {}
--组件哈希工厂
ActorManager.componentHashFactory = {}

--自动名字编号
ActorManager.autoNameIndex = 0

--缓存的场景数据
ActorManager.cacheSceneProtos = {}

--触摸开始的位置
ActorManager.touchBeginPos = Vec2.New(0,0)
--上一个位置
ActorManager.lastTouchPos = Vec2.New(0,0)
--当前位置
ActorManager.currentTouchPos = Vec2.New(0,0)
--同步server时间次数
ActorManager.syncTimeCount = 12

--AOI管理器
ActorManager.aoiEnabled = false

--初始化
function ActorManager:Init()
    ActorManager.super.Init(self)
    --注册组件
    self:RegisterComponentFactory(GFScript("ActorModule.DataComponent"))
    self:RegisterComponentFactory(GFScript("ActorModule.TriggerSystem.TriggerAgent"))
    self:RegisterComponentFactory(GFScript("ActorModule.ScheduleComponent"))
    self:RegisterComponentFactory(GFScript("ActorModule.SummonComponent"))
    --根节点，所有的actor都挂在这个节点下

    if Utils:IsServer() then
        self:InitServer()
    end
    if Utils:IsClient() then
        self:InitClient()
    end
    
    self:InitCollideGroup()
end

function ActorManager:InitServer()
    local gameSettings = GameFramework:GetGameSetting()
    self.serverAoi = InterestManagement.New()
    self.serverAoi:Init(gameSettings.Scene.serverAoiVisRange, true)
    self.serverAoi:SetEnabled(self.aoiEnabled)
    --注册网络协议
    Network:ServerSetCallback(ActorNetProto.RequestActor, self.OnRequestActor, self)
end
function ActorManager:InitClient()
    local gameSettings = GameFramework:GetGameSetting()
    self.clientAoi = InterestManagement.New()
    self.clientAoi:Init(gameSettings.Scene.clientAoiVisRange, false)
    self.clientAoi:SetEnabled(self.aoiEnabled)
    --注册网络协议
    Network:ClientSetCallback(ActorNetProto.ResponseAddActor, self.OnResponseAddActor, self)
    Network:ClientSetCallback(ActorNetProto.ResponseRemoveActor, self.OnResponseRemoveActor, self)
    Network:ClientSetCallback(ActorNetProto.ResponseActor, self.OnResponseActor, self)
    Network:ClientSetCallback(ActorNetProto.ResponseActorMakeShadow, self.OnResponseActorMakeShadow, self)
    Network:ClientSetCallback(ActorNetProto.ResponseActorBindObjChanged, self.OnResponseActorBindObjChanged, self)

    --监听鼠标左键点击
    if UserInputService.TouchEnabled then -- 触摸
        UserInputService.TouchStarted:Connect(function(inputObj, gameprocessed)
            self.isTouching = true
            self:OnTouchStarted(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
        end)

        UserInputService.TouchMoved:Connect(function(inputObj, gameprocessed)
            if self.isTouching then
                self:OnTouchMoved(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)

        UserInputService.TouchEnded:Connect(function(inputObj, gameprocessed)
            self.isTouching = false
            self:OnTouchEnded(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
        end)
    elseif UserInputService.MouseEnabled then -- 鼠标
        UserInputService.InputBegan:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton3.Value
            then
                self.isTouching = true
                self:OnTouchStarted(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
        UserInputService.InputChanged:Connect(function(inputObj, gameprocessed)
            local IsSight = MouseService:IsSight()
            if IsSight then
                self:OnTouchMoved(self.currentTouchPos.x + inputObj.Delta.x, self.currentTouchPos.y + inputObj.Delta.y,inputObj.TouchId)
            elseif self.isTouching then
                self:OnTouchMoved(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
        UserInputService.InputEnded:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton3.Value
            then
                self.isTouching = false
                self:OnTouchEnded(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
    end
end

--初始化碰撞组配置
function ActorManager:InitCollideGroup()
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Player, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Npc, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Monster, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Boss, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Pet, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Player, ActorDefines.CollideGroup.NoCollide, false)
    
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Player, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Npc, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Monster, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Boss, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Pet, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Npc, ActorDefines.CollideGroup.NoCollide, false)

    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Player, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Npc, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Monster, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Boss, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Pet, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Monster, ActorDefines.CollideGroup.NoCollide, false)

    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Player, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Npc, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Monster, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Boss, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Pet, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Boss, ActorDefines.CollideGroup.NoCollide, false)
    
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Player, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Npc, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Monster, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Boss, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Pet, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Soul, ActorDefines.CollideGroup.NoCollide, false)


    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Player, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Npc, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Monster, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Boss, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Pet, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Projectile, ActorDefines.CollideGroup.NoCollide, false)

    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Player, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Npc, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Monster, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Boss, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Pet, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Walker, ActorDefines.CollideGroup.NoCollide, false)

    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Player, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Npc, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Monster, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Boss, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Pet, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.Summon, true)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Summon, ActorDefines.CollideGroup.NoCollide, false)

    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Other, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Player, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Npc, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Monster, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Boss, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Pet, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.NoCollide, ActorDefines.CollideGroup.NoCollide, false)
    
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Player, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Npc, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Monster, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Boss, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Soul, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Pet, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Projectile, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Walker, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.Summon, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, ActorDefines.CollideGroup.NoCollide, false)
    --特殊处理
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, 4, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, 5, false)
    PhysXService:SetCollideInfo(ActorDefines.CollideGroup.Pet, 19, false)
    
end

function ActorManager:SetAoiEnabled(value)
    self.aoiEnabled = value
    if self.serverAoi then
        self.serverAoi:SetEnabled(value)
    end
    if self.clientAoi then
        self.clientAoi:SetEnabled(value)
    end
end

--是否开启AOI
function ActorManager:IsAoiEnabled()
    return self.aoiEnabled
end

--通知Actor添加
function ActorManager:NotifyActorAdd(actor)
    if not actor then
        return
    end
    if actor:IsServer() then
        self.serverActors[actor.actorId] = actor
        if actor.netId then
            self.serverNetActors[actor.netId] = actor
        end
        self:UnifyCSTime(actor.actorId, self.syncTimeCount)
        -- Log:Debug("Server NotifyActorAdd "..actor.actorId)
        if actor:IsPlayer() then
            self.serverPlayers[actor.playerId] = actor
            --重建AOI
            if self.serverAoi then
                self.serverAoi:RebuildAll(true)
            end
        else
            --重建AOI
            if self.serverAoi then
                self.serverAoi:Rebuild(actor, true)
            end
        end
    else
        if actor:IsLocalPlayer() then
            self.localPlayer = actor
            -- self.localPlayer.AvatarComponent:SetVisibleInAOI(true)
        end
        self.clientActors[actor.actorId] = actor
        if actor.netId then
            self.clientNetActors[actor.netId] = actor
        end
        -- Log:Debug("Client NotifyActorAdd "..actor.actorId)
        if actor:IsPlayer() then
            self.clientPlayers[actor.playerId] = actor
            --重建AOI
            if self.clientAoi then
                self.clientAoi:RebuildAll(true)
            end
        else
            --重建AOI
            if self.clientAoi then
                self.clientAoi:Rebuild(actor, true)
            end
        end
    end
end

--通知Actor移除
function ActorManager:NotifyActorRemove(actor)
    if not actor then
        return
    end
    if actor:IsServer() then
        -- Log:Debug("Server NotifyActorRemove "..actor.actorId)
        self.serverActors[actor.actorId] = nil
        if actor.netId then
            self.serverNetActors[actor.netId] = nil
        end
        if actor:IsPlayer() then
            self.serverPlayers[actor.playerId] = nil
        end
    else
        if actor:IsLocalPlayer() then
            self.localPlayer = nil
        end
        self.clientActors[actor.actorId] = nil
        if actor.netId then
            self.clientNetActors[actor.netId] = nil
        end
        if actor:IsPlayer() then
            self.clientPlayers[actor.playerId] = nil
        end
    end
end

--获取服务端Actor
function ActorManager:GetServerActor(obj)
    if not Utils:IsServer() then
        Log:Error("ActorManager:GetServerActor can only be called on server")
        return nil
    end
    local id = Utils:GetActorId(obj)
    if id then
        return self.serverActors[id]
    end
end

--获取客户端Actor
function ActorManager:GetClientActor(obj)
    if not Utils:IsClient() then
        Log:Error("ActorManager:GetClientActor can only be called on client")
        return nil
    end
    local id = Utils:GetActorId(obj)
    if id then
        return self.clientActors[id]
    end
end

--获取Actor
function ActorManager:GetActor(obj, isServer)
    if isServer then
        return self:GetServerActor(obj)
    else
        return self:GetClientActor(obj)
    end
end

--获取服务端网络Actor
function ActorManager:GetServerNetActor(netId)
    if not Utils:IsServer() then
        Log:Error("ActorManager:GetServerNetActor can only be called on server")
        return nil
    end
    return self.serverNetActors[netId]
end
function ActorManager:GetClientNetActor(netId)
    if not Utils:IsClient() then
        Log:Error("ActorManager:GetClientNetActor can only be called on client")
        return nil
    end
    return self.clientNetActors[netId]
end
--更新
function ActorManager:Update(dt)
    if Utils:IsServer() then
        self:UpdateServer(dt)
    end
    if Utils:IsClient() then
        self:UpdateClient(dt)
    end
end

--服务端更新
function ActorManager:UpdateServer(dt)
    if self.serverAoi then
        self.serverAoi:Update(dt)
    end
    for k, v in pairs(self.serverActors) do
        if ActorManager.profilerEnabled then
            Profiler:Start("UpdateServer: "..v:GetName(), 0.01)
        end
        PCall(function()
            v:Update(dt)
        end,v)
        if ActorManager.profilerEnabled then
            Profiler:Stop()
        end
    end
end
--客户端更新
function ActorManager:UpdateClient(dt)
    if self.clientAoi then
        self.clientAoi:Update(dt)
    end
    for k, v in pairs(self.clientActors) do
        if ActorManager.profilerEnabled then
            Profiler:Start("UpdateClient: "..v:GetName(), 0.01)
        end
        PCall(function()
            if not v.__delete__ then
                v:Update(dt)
            end
        end,v)
        if ActorManager.profilerEnabled then
            Profiler:Stop()
        end
    end
end

--注册Actor工厂
function ActorManager:RegisterActorFactory(actorType, actor, isServer)
    if isServer == nil then
        self.serverActorFactory[actorType] = actor
        self.clientActorFactory[actorType] = actor
        return
    end
    if isServer then
        self.serverActorFactory[actorType] = actor
    else
        self.clientActorFactory[actorType] = actor
    end
end

--根据类型名字创建Actor
function ActorManager:CreateActor(actorId, actorType, bindObj, isServer)
    local actor = nil
    if isServer and self.serverActorFactory[actorType] then
        actor = self.serverActorFactory[actorType].New(actorId, actorType, bindObj, isServer)
    elseif not isServer and self.clientActorFactory[actorType] then
        actor = self.clientActorFactory[actorType].New(actorId, actorType, bindObj, isServer)
    else
        actor = GFScript("ActorModule.Actor").New(actorId, actorType, bindObj, isServer)
    end
    return actor
end

--注册组件工厂
function ActorManager:RegisterComponentFactory(component)
    self.componentFactory[component.__cname] = component
    self.componentHashFactory[component:GetHashName()] = component
end

--根据类型名字创建组件
function ActorManager:CreateComponent(componentName)
    local component = nil
    if type(componentName) == "number" then
        component = self.componentHashFactory[componentName]
    else
        component = self.componentFactory[componentName]
    end
    if component then
        local comp = component.New()
        comp:Init()
        return comp
    end
    return nil
end
--根据类型生成Actor自动名字
function ActorManager:GenerateActorName(actorType)
    self.autoNameIndex = self.autoNameIndex + 1
    return actorType .. self.autoNameIndex
end

--遍历服务端Actor
function ActorManager:ForEachServerActors(func)
    for k,v in pairs(self.serverActors) do
        func(v)
    end
end
--遍历客户端Actor
function ActorManager:ForEachClientActors(func)
    for k,v in pairs(self.clientActors) do
        func(v)
    end
end

--遍历所有玩家
function ActorManager:ForEachServerPlayers(func)
    for k,v in pairs(self.serverPlayers) do
        if not v:IsShadow() then
            if func(v) then
                break
            end
        end
    end
end
--遍历所有玩家
function ActorManager:ForEachClientPlayers(func)
    for k,v in pairs(self.clientPlayers) do
        if not v:IsShadow() then
            if func(v) then
                break
            end
        end
    end
end

--获取本地玩家
function ActorManager:GetLocalPlayer()
    if self.localPlayer == nil then
        self:ForEachClientPlayers(function(actor)
            if actor:IsLocalPlayer() and not actor:IsShadow() then
                self.localPlayer = actor
            end
        end)
    end
    return self.localPlayer
end
--根据玩家id获取玩家对象
function ActorManager:GetServerPlayer(playerId)
    local player = self.serverPlayers[playerId]
    if player then
        return player
    end
end

--根据玩家id获取玩家对象
function ActorManager:GetClientPlayer(playerId)
    local player = self.clientPlayers[playerId]
    if player then
        return player
    end
end

------------------------------------Server-------------------------------------
--创建Actor
--服务端函数
function ActorManager:ServerCreateActor(workspace, actorType, targetObj, cloneTarget, successCallback, sync)
    if workspace == nil then
        workspace = game:GetService("WorkSpace")
    end

    local scene = SceneManager:GetSceneByWorkspace(workspace)
    if scene == nil then
        Log:Error("ActorManager:ServerCreateActor workspace is nil")
        return
    end

    local newObj = nil
    if cloneTarget then
        newObj = targetObj:Clone()
    else
        newObj = targetObj
    end
    if newObj and newObj.LocalScale then
        newObj.LocalScale = Vector3.New(1, 1, 1)
    end

    local playerId = newObj.UserId
    if newObj.Character then
        newObj = newObj.Character
    end
    local actorId, autoIdIndex = Utils:GenerateActorId(actorType, newObj)
    newObj.Name = actorId --self:GenerateActorName(actorType)
    -- print(debug.traceback())
    -- print("ServerCreateActor(): playerId = ", playerId)
    -- print("ServerCreateActor(): actorType = ", actorType)
    -- print("ServerCreateActor(): newObj.Name = ", newObj.Name)
    local actor = self:CreateActor(actorId, actorType, newObj, true)
    if actor then
        actor:SetNetId(autoIdIndex)
        --复制玩家id，这数据可能没有
        actor:SetPlayerId(playerId)
        actor:Init()
        actor:SetScene(scene)
        self:NotifyActorAdd(actor)
        --进行成功回调
        if successCallback then
            successCallback(actor)
        end
        sync = (sync == nil and true or sync)
        if not sync then
            self:FireServer("ActorCreated", actor)
            return actor
        end
        --读取数据库数据
        if actor:IsPlayer() then
            --设置一个默认的serverId
            actor.serverId = 1
            if actor:GetServerId() == 0 then
                self:FireServer("ActorCreated", actor)
                actor:LoadFinished()
                if sync then
                    if actor:IsPlayer() then
                        self:SyncPlayerForSpawned(actor)
                    else
                        self:SyncActor(actor)
                    end
                end
                actor:SetReady(true)
            else
                actor.DataComponent:LoadAll(function()
                    self:FireServer("ActorCreated", actor)
                    actor:LoadFinished()
                    if sync then
                        if actor:IsPlayer() then
                            self:SyncPlayerForSpawned(actor)
                        else
                            self:SyncActor(actor)
                        end
                    end
                    actor:SetReady(true)
                end)
            end
        else
            self:FireServer("ActorCreated", actor)
            actor:LoadFinished()
            if sync then
                if actor:IsPlayer() then
                    self:SyncPlayerForSpawned(actor)
                else
                    self:SyncActor(actor)
                end
            end
            actor:SetReady(true)
        end
    end
    return actor
end

--销毁Actor
--服务端函数
function ActorManager:ServerDestroyActor(actor)
    if actor and not Class.IsExpired(actor) then
        local isPlayer = actor:IsPlayer()
        --发送协议通知Actor删除
        local body = 
        {
            actorId = actor.actorId,
        }
        self:Broadcast(ActorNetProto.ResponseRemoveActor, body, actor:GetSceneId())

        local bindObj = actor.bindObj
        self:NotifyActorRemove(actor)
        self:FireServer("ActorDestroy", actor)
        
        actor:Destroy()

        -- destroyCharacter = (destroyCharacter == nil and true or destroyCharacter)

        --直接销毁bindObj，会自动同步到客户端，客户端收到以后会自动销毁actor
        if bindObj and not isPlayer then
            -- bindObj.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
            bindObj:Destroy()
        end

    end
end
function ActorManager:ServerDestroyActorForShadow(actor)
    if actor and actor:IsShadow() then
        -- if not silent then
            --发送协议通知Actor删除
            local body = 
            {
                actorId = actor.actorId,
            }
            self:Broadcast(ActorNetProto.ResponseRemoveActor, body, actor:GetSceneId())
        -- end

        local bindObj = actor.bindObj
        self:NotifyActorRemove(actor)
        self:FireServer("ActorDestroy", actor)
        
        actor:Destroy()

        -- destroyCharacter = (destroyCharacter == nil and true or destroyCharacter)

        --直接销毁bindObj，会自动同步到客户端，客户端收到以后会自动销毁actor
        if bindObj then
            -- bindObj.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
            bindObj:Destroy()
        end

    end
end
--当收到客户端的Actor请求协议
function ActorManager:OnRequestActor(playerId, code, body)
    --查询信息并返回
    local actor = self:GetServerActor(body.actorId)
    if actor then
        local comps = {}
        actor:ForEachComponents(function(comp)
            table.insert(comps, comp.__cname)
        end)
        local actorData = {}
        actor:Serialize(actorData, "Load", true, false)
        local body = 
        {
            actorData = actorData,
        }
        Network:SendToClient(playerId, ActorNetProto.ResponseActor, body)
    end
end
--同步当前Actor信息到客户端
function ActorManager:SyncActor(actor)
    --同步数据给其他人
    local actorData = {}
    actor:Serialize(actorData, "Sync")
    self:Broadcast(ActorNetProto.ResponseActor, {actorData = actorData}, actor:GetSceneId())
end
--同步当前Actor信息到客户端
function ActorManager:SyncPlayer(actor)
    --同步数据给自己
    local fullActorData = {}
    actor:Serialize(fullActorData, "Load")
    Network:SendToClient(actor:GetPlayerId(), ActorNetProto.ResponseActor, {actorData = fullActorData})

    --同步数据给其他人
    local actorData = {}
    actor:Serialize(actorData, "Sync")
    self:BroadcastOther(ActorNetProto.ResponseActor, {actorData = actorData}, actor:GetSceneId(), actor:GetPlayerId())
end

--进行一次玩家初始同步
function ActorManager:SyncPlayerForSpawned(actor)
    self:SyncPlayer(actor)

    --同步当前所有对象到客户端
    for k, v in pairs(self.serverActors) do
        if v:GetPlayerId() ~= actor:GetPlayerId() and v:GetSceneId() == actor:GetSceneId() then
            local actorData = {}
            v:Serialize(actorData, "Sync", true, false)
            local body = 
            {
                actorData = actorData,
            }
            Network:SendToClient(actor:GetPlayerId(), ActorNetProto.ResponseAddActor, body)
        end
    end
end

function ActorManager:UnifyCSTime(actorId, count)
    if count <= 0 then
        return
    end
    local actor = self.serverActors[actorId]
    if actor == nil then
        return
    end
    --同步服务端时间
    local serverInfo = {
        serverTime = Utils:GetServerTime()
    }
    actor:SendToClient(ActorNetProto.ResponseServerInfo, serverInfo)

    --再次同步时间
    actor:DelayCall(function()
        self:UnifyCSTime(actorId, count - 1)
    end, self.syncTimeCount - count + 1)
end
------------------------------------Client-------------------------------------
--客户端函数
--创建Actor
function ActorManager:_ClientCreateActor(actorId, scene, actorType, bindObj, actorData, successCallback)
    local actor = self:CreateActor(actorId, actorType, bindObj, false)
    if actor then
        
        actor:Deserialize(actorData)
        actor:Init()
        actor:SetScene(scene)
        
        self:NotifyActorAdd(actor)
        actor:LoadFinished()
        if successCallback then
            successCallback(actor)
        end
        self:FireClient("ActorCreated", actor)
        -- Log:Error("ActorManager:_ClientCreateActor actorId:%s", actor.actorId)
        if not self:IsAoiEnabled() then
            actor.AvatarComponent:SetVisibleInAOI(true)
        end
        actor:SetReady(true)
    end
    return actor
end
--获取或者创建Actor
function ActorManager:_ClientGetOrCreateActor(actorId, scene, actorType, bindObj,actorData, successCallback)
    local actor = self:GetClientActor(actorId)
    if actor == nil then
        actor = self:_ClientCreateActor(actorId, scene, actorType, bindObj,actorData, successCallback)
    else
        if successCallback then
            successCallback(actor)
        end
    end
    return actor
end

function ActorManager:_ClientDestroyActor(actor)
    if actor then
        local bindObj = actor.bindObj
        self:NotifyActorRemove(actor)
        self:FireClient("ActorDestroy", actor)
        actor:Destroy()

        -- if bindObj then
        --     if actor:IsShadow() or not Utils:IsServer() then
        --         bindObj:Destroy()
        --     end
        -- end
        
        -- Log:Error("ActorManager:_ClientDestroyActor actorId:%s", actor.actorId)
    end
end
--当收到服务端的Actor创建协议
function ActorManager:AddActorForNetData(body)
    local actorData = body.actorData
    local actorType = actorData.actorType

    local scene = SceneManager:GetScene(actorData.sceneId)
    if scene == nil then
        --Log:Error("ActorManager:OnResponseAddActor can't find scene: %s", actorData.sceneId)
        return nil
    end

    local bindObj = scene:FindActorNode(actorData.actorId)
    if bindObj == nil then
        Log:Error("ActorManager:OnResponseAddActor can't find bindObj: %s", actorData.actorId)
        return nil
    end

    Network:UnblockProtocolIndex(body.protocolIndex)

    local oldActor = self:GetClientActor(actorData.actorId)
    if oldActor then
        oldActor:SetReady(false)
        --该信息已经存在
        oldActor:Deserialize(actorData)
        oldActor:ReloadFinished()
        self:FireClient("ActorUpdated", oldActor)
        oldActor:SetReady(true)
        return oldActor
    end

    local actor = self:_ClientCreateActor(actorData.actorId, scene, actorType, bindObj,actorData, function(actor)
        actor:CheckShowOff()
    end)

    return actor
end
--当收到服务端的Actor创建协议
function ActorManager:OnResponseAddActor(code, body)
    local actorData = body.actorData
    local actorType = actorData.actorType

    local actor = self:AddActorForNetData(body)
    if not actor then
        Network:BlockProtocolIndex(body.protocolIndex)
        --将消息缓存起来等待创建
        table.insert( self.cacheSceneProtos, {sceneId = actorData.sceneId, body = body})
    end
end
--当收到服务端的Actor响应协议
function ActorManager:OnResponseActor(code, body)
    local actorData = body.actorData
    local actorType = actorData.actorType

    local scene = SceneManager:GetScene(actorData.sceneId)
    if scene == nil then
        Log:Error("ActorManager:OnResponseActor can't find scene: %s", actorData.sceneId)
        return
    end

    local actor = self:GetClientActor(actorData.actorId)
    if actor then
        actor:SetReady(false)
        actor:Deserialize(actorData)
        actor:ReloadFinished()
        self:FireClient("ActorUpdated", actor)
        actor:SetReady(true)
        return
    end

    local bindObj = scene:FindActorNode(actorData.actorId)
    if bindObj == nil then
        Log:Error("ActorManager:OnResponseActor can't find bindObj")
        return
    end
    local actor = self:_ClientCreateActor(actorData.actorId, scene, actorType, bindObj,actorData, function(actor)

    end)
end
--当收到服务端的Actor移除协议
function ActorManager:OnResponseRemoveActor(code, body)
    local actorId = body.actorId
    if not actorId then
        return
    end
    local actor = self:GetClientActor(actorId)
    self:_ClientDestroyActor(actor)

    TableUtils:RemoveAll(self.cacheSceneProtos, function(v)
        return v.body.actorData.actorId == actorId
    end)
end

--Actor转移通知
function ActorManager:OnResponseActorMakeShadow(code, body)
    local actorId = body.actorId
    local targetId = body.targetId
    local actor = self:GetClientActor(actorId)
    local targetActor = self:GetClientActor(targetId)

    local bindObjId = body.bindObjId
    local isDead = body.isDead

    if not actor or not targetActor then
        Log:Error("ActorManager:OnResponseActorMakeShadow can't find actorId or targetId")
        return
    end

    --同步playerData信息
    targetActor:CopyFrom(actor)
    targetActor.playerData:SetCurUseHero(body.isUseMiniModel, body.targetHeroId)
    
    local bindObj = actor:GetScene():FindActorNode(bindObjId)
    if bindObj == nil then
        Log:Error("ActorManager:OnResponseActorMakeShadow can't find bindObj: %s", bindObjId)
        return nil
    end
    -- actor.bindObj.Position = Vector3.New(body.oldObjPos[1],body.oldObjPos[2],body.oldObjPos[3])
    
    local timePos = actor.AvatarComponent:GetCurAnimTimePos()
    local curAnimName = actor.AvatarComponent:GetCurrentStateName()
    local controllerAssetName = actor.AvatarComponent:GetAnimControllerAssetName()
    local character = actor:GetCharacter()
    local modelId = character.ModelId
    actor:SetBindObj(bindObj)
    
    actor:SetMaster(targetActor)
    actor:SetShadow(targetActor ~= nil)
    
    bindObj.ModelId = modelId
    actor.AvatarComponent:SetAnimControllerAssetName(controllerAssetName)
    --同步动作
    actor.AvatarComponent:PlayAnim(curAnimName,0,0,timePos)
    
    --同步摄像机
    targetActor.CameraController:CopyFrom(actor.CameraController)
    
    --触发事件
    self:FireClient("ActorShadowChanged", actor, targetActor, body.params)
end
--绑定对象的改变
function ActorManager:OnResponseActorBindObjChanged(code, body)
    local actorId = body.actorId
    local bindObjId = body.bindObjId
    local actor = self:GetClientActor(actorId)
    if not actor then
        Log:Error("ActorManager:OnResponseActorBindObjChanged can't find actorId: %s", tostring(actorId))
        return
    end
    local bindObj = actor:GetScene():FindActorNode(bindObjId)
    if bindObj == nil then
        Log:Error("ActorManager:OnResponseAddActor can't find bindObj: %s", bindObjId)
        return nil
    end
    actor.bindObj.Position = Vector3.New(body.oldObjPos[1],body.oldObjPos[2],body.oldObjPos[3])
    actor:SetBindObj(bindObj)
end


_G.RegisterComponentFactory = function(component)
    ActorManager:RegisterComponentFactory(component)
end

--广播网络消息
function ActorManager:Broadcast(msgid, body, sceneId)
    self:ForEachServerPlayers(function(player)
        if sceneId == nil or player:GetSceneId() == sceneId then
            Network:SendToClient(player:GetPlayerId(), msgid, body)
        end
    end)
end
function ActorManager:BroadcastOther(msgid, body, sceneId, playerId)
    self:ForEachServerPlayers(function(player)
        if player:GetPlayerId() ~= playerId and (sceneId == nil or player:GetSceneId() == sceneId) then
            Network:SendToClient(player:GetPlayerId(), msgid, body)
        end
    end)
end

--显示
function ActorManager:ShowForPlayer(actor, player, initialize)
    if not player:IsServer() then
        if player:IsLocalPlayer() then
            -- if not initialize then
                --设置为显示
                actor.AvatarComponent:SetVisibleInAOI(true)
            -- else
            --     actor.AvatarComponent:SetVisibleInAOI(false)
            -- end
            -- Log:Error("ActorManager:ShowForPlayer: %s %s", tostring(player:GetActorId()),tostring(actor:GetActorId()))
        end
    else
    end
end

--隐藏
function ActorManager:HideForPlayer(actor, player)
    if not player:IsServer() then
        if player:IsLocalPlayer() then
            --设置为隐藏
            actor.AvatarComponent:SetVisibleInAOI(false)
            -- Log:Error("ActorManager:HideForPlayer: %s %s", tostring(player:GetActorId()),tostring(actor:GetActorId()))
        end
    else
    end
end

--------------------------Input----------------------------------
--触摸开始
function ActorManager:OnTouchStarted(x,y,touchId)
    self.touchId = touchId
    self.touchBeginPos.x = x
    self.touchBeginPos.y = y
    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
end
--触摸移动
function ActorManager:OnTouchMoved(x,y,touchId)
    if self.touchId ~= touchId then
        return
    end
    self.touchMoving = true
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
    
    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
end
--触摸结束
function ActorManager:OnTouchEnded(x,y,touchId)
    if self.touchId ~= touchId then
        return
    end
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y

    --判断是否是点击
    if (self.currentTouchPos - self.touchBeginPos):Length() < 10 then
        self:OnClick(x,y)
    end

    self.touchMoving = false
end

--点击
function ActorManager:OnClick(x,y)
    local localPlayer = self:GetLocalPlayer()
    if not localPlayer then
        return
    end
    local viewportSize = localPlayer.CameraController:GetViewportSize()
    local ray = localPlayer.CameraController.camera:ViewportPointToRay(x, viewportSize.y - y, 0)
    local ret = game:GetService("WorldService"):RaycastClosest(ray.Origin, ray.Direction, 50000, false, ActorDefines.AllCollideActorGroups)
    -- 如果击中
    if ret.isHit then
        local obj = ret.obj
        if obj then
            if obj.Tag == ActorDefines.ActorTag then
                local actor = ActorManager:GetClientActor(obj)
                if actor.OnClicked then
                    actor:OnClicked(x, y)
                    actor:FireClient("Clicked", x, y)
                end
                if self.lastClickedActor ~= actor then
                    if self.lastClickedActor and not Class.IsExpired(self.lastClickedActor) then
                        if self.lastClickedActor.OnUnFocus then
                            self.lastClickedActor:OnUnFocus()
                            self.lastClickedActor:FireClient("UnFocus")
                        end
                    end
                    if actor.OnFocus then
                        actor:OnFocus()
                        actor:FireClient("Focus")
                    end
                    self.lastClickedActor = actor
                end
                self:FireClient("ActorClicked", actor)
            end
        end
    else
        if self.lastClickedActor and not Class.IsExpired(self.lastClickedActor) then
            if self.lastClickedActor.OnUnFocus then
                self.lastClickedActor:OnUnFocus()
                self.lastClickedActor:FireClient("UnFocus")
            end
        end
        self.lastClickedActor = nil
        self:FireClient("ActorClicked", nil)
    end
end


function ActorManager:GetActorConfig(tid)
    local config = ConfigManager:GetConfig(ActorUtils:GetActorTableByTid(tid).Actor, tid)
    return config
end


return ActorManager