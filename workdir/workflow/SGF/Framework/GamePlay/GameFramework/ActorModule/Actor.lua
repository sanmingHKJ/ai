local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local EventObject = GFScript("CoreModule.EventObject")
local Database = GFScript("CoreModule.Database")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local TimerManager = GFScript("CoreModule.TimerManager")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local Network = GFScript("NetworkModule.Network")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local MoveBy = GFScript("ActorModule.Action.MoveBy")
local MoveTo = GFScript("ActorModule.Action.MoveTo")
local JumpBy = GFScript("ActorModule.Action.JumpBy")
local JumpTo = GFScript("ActorModule.Action.JumpTo")
local ActionManager = GFScript("ActorModule.ActionManager")
local CallFunc = GFScript("ActorModule.Action.CallFunc")
local Delay = GFScript("ActorModule.Action.Delay")
local Sequence = GFScript("ActorModule.Action.Sequence")
local Profiler = GFScript("CoreModule.Profiler")
local Quat = GFScript("CoreModule.Math.Quat")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local MathDefines = GFScript("CoreModule.Math.MathDefines")
local Path = GFScript("CoreModule.Math.Path")
local Math = GFScript("CoreModule.Math")
local StatDefines = GFScript("StatModule.StatDefines")
local GlobalEvent = GFScript("CoreModule.GlobalEvent")
local NetworkSetup = GFScript("NetworkModule.NetworkSetup")
local Players = game:GetService("Players")
local WorldService = game:GetService("WorldService")
local MainStorage = game:GetService("MainStorage")
local ConfigLoaderSetup = GFScript("CoreModule.ConfigLoaderSetup")
local ActorSettings = GFScript("ActorModule.ActorSettings")
local Actor = Class.New("Actor", EventObject)
--启用性能分析
Actor.profilerEnabled = false

--版本号
Actor.version = 2

--实例化
--@param actorType Actor类型
--@param bObj 外部绑定对象
--@param isServer 是否服务器
function Actor:Constructor(actorId, actorType, bObj, isServer)
    self.actorManager = GFScript("ActorModule.ActorManager")
    self.isServer = isServer
    self.isReady = false
    self.actorType = actorType
    self.netId = nil
    self.actorId = actorId
    self.nickName = ""
    --外部绑定对象
    self:SetBindObj(bObj)
    --根组件
    self.rootComponent = nil
    --组件
    self.components = {}
    self.updateComponents = {}
    self.fixedUpdateComponents = {}
    --玩家id，只有玩家才有
    self.playerId = nil
    --出生点
    self.bornPosition = nil
    --目标
    self.target = nil
    --当前攻击方
    self.attacker = nil
    --当前伤害者
    self.damager = nil
    --标签
    self.tags = {}
    --分类
    self.category = ""
    --正在运行的action
    self.actions = {}
    --当前状态值，与状态机同步
    self.state = ""
    --额外的序列化数据
    self.otherData = {}
    --碰撞来源位置
    self.hitSourcePos = nil
    --受击反馈
    self.hitFeedback = {}
    --切人退场表现配置
    self.partnerLeaveEffect = {}
    --延迟执行的定时器
    self.delayCallTimers = {}
    
    --我观察谁
    self.observing = {}
    --谁观察我
    self.observers = {}
    --仆从
    self.servants = {}
    self.servantIds = {}
    -- --设置场景
    -- self:SetScene(scene)

    self:SetTag(ActorDefines.ActorTag)
    self:SetCollideGroup(ActorDefines.CollideGroup.Other)
    
    if self.isServer then
        --设置ActorId到自定义属性
        Utils:SetActorId(self.bindObj,self.actorId)
    end
    --主人，只有分身有
    self.master = nil
    --actor身上的UI
    self.localUIs = {}

    --更新间隔
    self.updateRate = 0
    self.updateInterval = 0

    self.eventDebug = false
end

--析构
function Actor:Destructor()
    if self.master and not Class.IsExpired(self.master) then
        self.master:RemoveServant(self)
    end
    self:ClearAllServants()
    self:ClearAllDelayCall()
    self:StopAllActions()
    self:SetScene(nil, true)
    self:DestroyAllComponents()
    if self.loadFinishEvent then
        self.loadFinishEvent:Disconnect()
        self.loadFinishEvent = nil
    end
end

function Actor:OnConstructor()
    NetworkSetup:SetupRpc(self)
end

function Actor:OnDestructor()
    --触发事件
    if self:IsServer() then
        self:FireServer("Destroy", self)
    else
        self:FireClient("Destroy", self)
    end
end

--设置网络id
function Actor:SetNetId(netId)
    self.netId = netId
end

function Actor:SetBindObj(obj)
    local oldBindObj = self.bindObj
    self.bindObj = obj
    self.name = obj.Name
    self:OnBindObjChanged(oldBindObj, obj)
end
function Actor:OnBindObjChanged(oldBindObj, newBindObj)
    self:ForEachComponents(function(comp)
        comp:OnBindObjChanged(oldBindObj, newBindObj)
    end)
end
--是否可以受击
function Actor:CanHit()
    return not self:IsShadow()
end

--是否分身
function Actor:IsShadow()
    return self:GetCustomState("Shadow")
end

--设置Shadow
function Actor:SetShadow(isShadow)
    self:SetCustomState("Shadow", isShadow)
end

--设置主人
function Actor:SetMaster(master)
    if self.master then
        self.master:RemoveServant(self)
    end
    self.master = master
    if master ~= nil then
        self.masterId = master:GetActorId()
        self:SetPlayerId(0)
        
        self.master:AddServant(self)
    else
        self.masterId = 0
    end

    if self:IsServer() then 
        self:RpcSetMaster(self.masterId)
    end
end

--获取主人
function Actor:GetMaster()
    if self.master then
        return self.master
    end
    if self.masterId then   
        if self:IsServer() then 
            self.master = self.actorManager:GetServerActor(self.masterId)
        else
            self.master = self.actorManager:GetClientActor(self.masterId)
        end
    end
    return self.master
end

-- 获取主人Id
function Actor:GetMasterPlayerId()
    if self.master == nil then
        return 0
    end
    local masterId = self.master.playerId
    if masterId ~= 0 then
        return masterId
    end
    return self.master:GetMasterPlayerId()
end

-- 是否匹配主人
function Actor:IsMatchMaster(spawn)
    -- 主人调用
    if spawn == nil or spawn.playerId ~= 0 then
        -- 不是产卵
        return false
    end
    local tPlayerID = spawn:GetMasterPlayerId()
    if tPlayerID == 0 then
        -- 还是产卵
        return false
    end
    return self.playerId == tPlayerID
end

-- 是否匹配产卵
function Actor:IsMatchSpawn(master)
    -- 产卵调用
    if master == nil or self.playerId ~= 0 then
        -- 不是主人或产卵
        return false
    end
    local sPlayerID = self:GetMasterPlayerId()
    if sPlayerID == 0 then
        -- 还是产卵
        return false
    end
    return master.playerId == sPlayerID
end

--添加仆从
function Actor:AddServant(servant)
    if servant ~= self then
        table.insert(self.servants, servant)
        table.insert(self.servantIds, servant.actorId)

        if self:IsServer() then
            self:RpcServants(self.servantIds)
        end
    end
end
--移除仆从
function Actor:RemoveServant(servant)
    for i,v in ipairs(self.servants) do
        if v == servant then
            table.remove(self.servants, i)
            table.remove(self.servantIds, i)
            break
        end
    end
    if self:IsServer() then
        self:RpcServants(self.servantIds)
    end
end
--获取仆从
function Actor:GetServant(actorId)
    for _, servant in ipairs(self.servants) do
        if servant.actorId == actorId then
            return servant
        end
    end
    return nil
end

--获取仆从数量
function Actor:GetServantCount()
    if self:IsServer() then
        return #self.servants
    else
        return #self.servantIds
    end
end

--获取仆从
function Actor:GetServantByIndex(index)
    if self:IsServer() then
        return self.servants[index]
    else
        local servantId = self.servantIds[index]
        return self.actorManager:GetClientActor(servantId)
    end
end

--遍历仆从
function Actor:ForEachServants(callback)
    if self:IsServer() then
        for _, servant in ipairs(self.servants) do
            if callback(servant) then
                break
            end
        end
    else
        for _, servantId in ipairs(self.servantIds) do
            local servant = self.actorManager:GetClientActor(servantId)
            if callback(servant) then
                break
            end
        end
    end
end

--清除所有仆从
function Actor:ClearAllServants()
    --反向循环
    for i = #self.servants, 1, -1 do
        local servant = self.servants[i]
        if servant and not Class.IsExpired(servant) then
            self.actorManager:ServerDestroyActor(servant)
        end
    end
    self.servants = {}
    self.servantIds = {}
    if self:IsServer() then
        self:RpcServants(self.servantIds)
    end
end

--设置Tag
function Actor:SetTag(tag)
    local character = self:GetCharacter()
    if character.Tag then
        character.Tag = tag
    end
end

--获取标签
function Actor:GetTag()
    local character = self:GetCharacter()
    return character.Tag
end

--获取命中标签
function Actor:GetCategory()
    return self.category
end
--设置命中标签
function Actor:SetCategory(category)
    self.category = category
end

--设置碰撞组
function Actor:SetCollideGroup(group)
    -- if self:IsServer() then
        local character = self:GetCharacter()
        if character.CollideGroupID then
            character.CollideGroupID = group
        end
    -- end
end

--获取碰撞组
function Actor:GetCollideGroup()
    local character = self:GetCharacter()
    return character.CollideGroupID
end

--设置Tid
function Actor:SetTid(tid)
    self.tid = tid
    if self:IsServer() then
        self:SetCustomState("Tid",tid)  
    end
end
--获取Tid
function Actor:GetTid()
    if self.tid then
        return self.tid
    end
    return self:GetCustomState("Tid")
end
--获取当前根节点
function Actor:GetActorRootNode()
    return self.scene:GetActorRootNode()
end

--设置actor所属Scene
function Actor:SetScene(scene, silent)
    if self.scene == scene then
        return
    end
    if self.scene then
        self.scene:NotifyRemoveActor(self)
    end
    self.scene = scene
    self:OnSceneSet(scene)
    if self.scene then
        self.scene:NotifyAddActor(self)
        if not silent then
            if self:IsPlayer() then
            else

                local parent = scene:GetActorRootNode()
                if self.bindObj.Parent ~= parent then
                    self.bindObj.Parent = parent
                end
            end
        end
    end
end

--获取scene
function Actor:GetScene()
    return self.scene
end

--获取场景id
function Actor:GetSceneId()
    if self.scene == nil then
        return nil
    end
    return self.scene:GetSceneId()
end
--添加到场景
function Actor:OnAddToScene()

end

--从场景移除
function Actor:OnRemoveFromScene()
    
end
--场景设置的时候
function Actor:OnSceneSet(scene)
    self:ForEachComponents(function(comp)
        comp:OnSceneSet(scene)
    end)

end

--开启碰撞检测
function Actor:EnableOverlap(enable)
    if not WorldService.SetSceneId then
        Log:Error("Actor:EnableOverlap error SetSceneId is nil")
        return
    end
    if self.scene == nil then
        --Log:Error("Actor:EnableOverlap error scene is nil")
        return
    end
    if enable then
        local workspaceId = self.scene:GetWorkspaceId()
        WorldService:SetSceneId(workspaceId)
    else
        WorldService:SetSceneId(0)
    end
end

--获取actor类型
function Actor:GetActorType()
    return self.actorType
end

--是否已经准备就绪
function Actor:IsReady()
    return self.isReady
end

--设置准备就绪
function Actor:SetReady(isReady)
    self.isReady = isReady
    self:Fire(self:IsServer(), "Ready", isReady)
end

--是否服务器
function Actor:IsServer()
    return self.isServer
end

--是否客户端
function Actor:IsClient()
    return not self:IsServer()
end

--获取外部绑定对象
function Actor:GetBindObj()
    return self.bindObj
end

--获取挂载点
function Actor:GetSocket(name)
    if name == "Head" then
        return self.bindObj.HeadAttachment
    elseif name == "LeftHand" then
        return self.bindObj.LHandAttachment
    elseif name == "RightHand" then
        return self.bindObj.RHandAttachment
    elseif name == "Weapon" then
        return self.bindObj.WeaponAttachment
    elseif name == "Chest" then
        return self.bindObj.ChestAttachment
    elseif name == "Waist" then
        return self.bindObj.WaistAttachment
    end
    return nil
end

--获取对应的Character，可能是自己的绑定对象
function Actor:GetCharacter()
    return self.bindObj
end

--是否已经加载完毕
function Actor:IsLoadFinish()
    local character = self:GetCharacter()
    return character:IsLoadFinish()
end

--设置加载完毕回调
function Actor:SetLoadFinishCallback(callback)
    -- 先断开之前的连接，防止多次连接导致泄漏
    if self.loadFinishEvent then
        self.loadFinishEvent:Disconnect()
        self.loadFinishEvent = nil
    end
    
    if self:IsLoadFinish() then
        callback()
    else
        local character = self:GetCharacter()
        self.loadFinishEvent = character.LoadFinish:Connect(function()
            callback()
            -- 回调执行后断开连接
            if self.loadFinishEvent then
                self.loadFinishEvent:Disconnect()
                self.loadFinishEvent = nil
            end
        end)
    end
end


--初始化
function Actor:Init()
    Actor.super.Init(self)
    
    --创建状态机
    if self.isServer then
        self:InitServer()
    else
        self:InitClient()
    end
end

--服务端初始化
function Actor:InitServer()
    --初始化服务端组件
    self:InitServerComponents()
    --注册网络协议
    self:ServerNetCallback(ActorNetProto.RequestActorSay, self.OnRequestActorSay, self)
end

--客户端初始化
function Actor:InitClient()
    --初始化客户端组件
    self:InitClientComponents()
    --注册网络协议
    self:ClientNetCallback(ActorNetProto.ResponseEnergy, self.OnResponseEnergy, self)
    self:ClientNetCallback(ActorNetProto.ResponseMoveBy, self.OnResponseMoveBy, self)
    self:ClientNetCallback(ActorNetProto.ResponseEnterCombat, self.OnResponseEnterCombat, self)
    self:ClientNetCallback(ActorNetProto.ResponseLeaveCombat, self.OnResponseLeaveCombat, self)
    self:ClientNetCallback(ActorNetProto.ResponseActorSay, self.OnResponseActorSay, self)
    self:ClientNetCallback(ActorNetProto.ResponseActorRevive, self.OnResponseActorRevive, self)
end

--初始化服务端组件
function Actor:InitServerComponents()
    --添加默认的组件
    local avatarComp = self:AddComponent("AvatarComponent")
    self:SetRootComponent(avatarComp)
    self:AddComponent("StatComponent")
    self:AddComponent("CombatComponent")
    self:AddComponent("HealthComponent")
    self:AddComponent("ManaComponent")
    self:AddComponent("AngerComponent")
    self:AddComponent("CampComponent")

    if not self:IsPlayer() then
        self:AddComponent("AIPerception")
        self:AddComponent("HateComponent")
    end

    if self:IsPlayer() then
        avatarComp:SetUseSystemLogic(true)
    else
        avatarComp:SetUseSystemLogic(false)
    end
end

--初始化客户端组件
function Actor:InitClientComponents()
    self:AddComponent("OverheadDisplay")
end


--获取节点id
function Actor:GetActorId()
    return self.actorId
end
--设置节点Id
function Actor:SetActorId(id)
    self.actorId = id
end

--获取节点名字
function Actor:GetNickName()
    return self.nickName
end

--设置节点名字
function Actor:SetNickName(name)
    self.nickName = name
end
--获取节点名字
function Actor:GetName()
    return self.name
end

--设置节点名字
function Actor:SetName(name)
    self.name = name
end

--获取玩家id
function Actor:GetPlayerId()
    return self.playerId
end

--获取玩家对象
function Actor:GetPlayer()
    if self.player == nil and self.playerId then
        local Players = game:GetService("Players")
        self.player = Players:GetPlayerByUserId(self.playerId)
    end
    return self.player
end

--是否是玩家
function Actor:IsPlayer()
    return self.playerId ~= nil and self.playerId ~= 0
end
--是否本地玩家
function Actor:IsLocalPlayer()
    if self:IsServer() then
        return false
    end
    return self.playerId == Utils:GetLocalPlayerId()
end

--是否本地玩家或者隶属于本地玩家
function Actor:IsOwnerLocalPlayer()
    local master = self:GetMaster()
    if master and master:IsLocalPlayer() then
        return true
    end
    return self:IsLocalPlayer()
end

function Actor:IsOwnerPlayer()
    local master = self:GetMaster()
    if master and master:IsPlayer() then
        return true
    end
    return self:IsPlayer()
end

function Actor:GetOwnerPlayerId()
    if self:IsPlayer() then
        return self.playerId
    end
    local master = self:GetMaster()
    if master then
        return master:GetPlayerId()
    end
    return nil
end

--设置玩家id
function Actor:SetPlayerId(playerId)
    self.playerId = playerId
end

--是否是拥有者
function Actor:IsOwned()
    if self:IsServer() and not self:IsOwnerPlayer() then
        return true
    elseif not self:IsServer() and self:IsOwnerLocalPlayer() then
        return true
    end
    return false
end

--是否拥有所有权
function Actor:HasAuthority()
    return self:IsOwned() or self:IsServer()
end

--是否拥有服务器权限
function Actor:HasAuthorityServerOnly()
    return self:IsServer() and not self:IsOwnerPlayer()
end

--检查玩家id是否就是该actor
function Actor:CheckPlayerId(playerId)
    return self.playerId == playerId
end
--检查actorid是否就是该actor
function Actor:CheckId(actorId)
    return self.actorId == actorId
end

--获取出生点
function Actor:GetBornPosition()
    if self.bornPosition == nil then
        return self:GetPosition()
    end
    return self.bornPosition
end
--设置出生点
function Actor:SetBornPosition(position)
    self.bornPosition = position
end

--获取受击反馈
function Actor:GetHitFeedback()
    return self.hitFeedback
end

--获取节点标签
function Actor:GetTags()
    return self.tags
end

--添加标签
function Actor:AddTag(tag)
    for k,v in pairs(self.tags) do
        if v == tag then
            return
        end
    end
    table.insert(self.tags, tag)    
end
--移除标签
function Actor:RemoveTag(tag)
    for k,v in pairs(self.tags) do
        if v == tag then
            table.remove(self.tags, k)
            return
        end
    end 
end
--是否存在标签
function Actor:HasTag(tag)
    for k,v in pairs(self.tags) do
        if v == tag then
            return true
        end
    end
    return false
end

--设置根组件
function Actor:SetRootComponent(component)
    self.rootComponent = component
end

--获取根组件
function Actor:GetRootComponent()
    return self.rootComponent
end

--根据类型名字添加组件
function Actor:AddComponentByName(componentName)
    if Utils:IsNullOrEmpty(componentName) then
        return nil
    end
    local component = self.actorManager:CreateComponent(componentName)
    if component == nil then
        Log:Error("Create component failed : "..componentName)
        return nil
    end
    return self:AddComponent(component)
end
--获取或者创建组件
function Actor:GetOrCreateComponent(componentName)
    if Utils:IsNullOrEmpty(componentName) then
        return nil
    end
    local component = self:GetComponent(componentName)
    if component == nil then
        return self:AddComponentByName(componentName)
    end
    return component
end

--添加组件
function Actor:AddComponent(component)
    if not component then
        return nil
    end

    if type(component) == "string" then
        return self:AddComponentByName(component)
    end

    --判断是否存在相同类型的组件
    for k,v in ipairs(self.components) do
        if v.__cname == component.__cname then
            -- Log:Warn("The component is exits : "..v.__cname)
            return nil
        end
    end
    --先从上一个节点移除
    if component.actor then
        component.actor:RemoveComponent(component)
    end
    table.insert(self.components, component)
    if component.updateEnabled then
        table.insert(self.updateComponents, component)
    end
    if component.fixedUpdateInterval ~= 0 then
        table.insert(self.fixedUpdateComponents, component)
        component.fixedUpdateTimeNow = 0
    end
    component:SetActor(self)
    if self.scene then
        component:OnSceneSet(self.scene)
    end

    if self.bindObj then
        component:OnBindObjChanged(nil, self.bindObj)
    end
    if self:IsServer() then 
        self:AddSubNetObject(component)
    end
    component:Awake()

    self[component.__cname] = component

    return component
end

--移除组件
function Actor:RemoveComponent(component)
    if not component then
        return
    end
    for k,v in ipairs(self.components) do
        if v == component then
            table.remove(self.components, k)
            if component.updateEnabled then
                for k1,v1 in ipairs(self.updateComponents) do
                    if v1 == component then
                        table.remove(self.updateComponents, k1)
                    end
                end
            end
            if component.fixedUpdateInterval ~= 0 then
                for k3,v3 in ipairs(self.fixedUpdateComponents) do
                    if v3 == component then
                        table.remove(self.fixedUpdateComponents, k3)
                    end
                end
            end
            component:SetActor(nil)
            -- self[component.__cname] = nil
            return
        end
    end
end

--销毁组件
function Actor:DestroyComponent(component)
    if not component then
        return
    end
    self:RemoveComponent(component)
    component:Destroy()
end

--销毁全部组件
function Actor:DestroyAllComponents()
    for k,v in ipairs(self.components) do
        -- v:SetActor(nil)
        -- self[v.__cname] = nil
        v:Destroy()
    end
    self.components = {}
    self.updateComponents = {}
    self.fixedUpdateComponents = {}
end

--获取组件
function Actor:GetComponent(type)
    for k,v in ipairs(self.components) do
        if v.__cname == type then
            return v
        end
    end
    return nil
end

--通过id查找组件
function Actor:GetComponentById(id)
    for k,v in ipairs(self.components) do
        if v.id == id then
            return v
        end
    end
    return nil
end

--通过guid查找组件
function Actor:GetComponentByGuid(guid)
    for k,v in ipairs(self.components) do
        if v.guid == guid then
            return v
        end
    end
    return nil
end

--获取衍生组件
function Actor:GetDerivedComponent(type)
    for k,v in ipairs(self.components) do
        if Class.Iskindof(v, type) then
            return v
        end
    end
    return nil
end

--添加子网络对象
function Actor:AddSubNetObject(obj)
    if not self.subNetObjects then
        self.subNetObjects = {}
    end
    obj.netId = self.netId
    if obj.subNetId == nil then
        obj.subNetId = Utils:GenerateSubNetId()
    end
    self.subNetObjects[obj.subNetId] = obj

    if not obj.SendToServer then
        obj.SendToServer = function(subObj, msgid, body)
            self:SendToServer(msgid, body)
        end
    end

    if not obj.SendToClient then
        obj.SendToClient = function(subObj, msgid, body)
            self:SendToClient(msgid, body)
        end
    end

    if not obj.SendToObservers then
        obj.SendToObservers = function(subObj, msgid, body, includeSelf)
            self:SendToObservers(msgid, body, includeSelf)
        end
    end

    if not obj.SendToAllClients then
        obj.SendToAllClients = function(subObj, msgid, body, includeSelf)
            self:SendToAllClients(msgid, body, includeSelf)
        end
    end

    if not obj.SendToOtherClients then
        obj.SendToOtherClients = function(subObj, msgid, body)
            self:SendToOtherClients(msgid, body)
        end
    end

    if not obj.ClientNetCallback then
        obj.ClientNetCallback = function(subObj, id, fun, obj)
            self:ClientNetCallback(id, fun, obj)
        end
    end

    if not obj.ServerNetCallback then
        obj.ServerNetCallback = function(subObj, id, fun, obj)
            self:ServerNetCallback(id, fun, obj)
        end
    end
end

--移除子网络对象
function Actor:RemoveSubNetObject(obj)
    if not self.subNetObjects then
        return
    end
    self.subNetObjects[obj.subNetId] = nil
    obj.netId = nil
    obj.subNetId = nil
end

--获取子网络对象
function Actor:GetSubNetObject(subNetId)
    if not self.subNetObjects then
        return nil
    end
    return self.subNetObjects[subNetId]
end

--遍历组件
function Actor:ForEachComponents(func)
    if self.components then
        for k,v in ipairs(self.components) do
            func(v)
        end
    end
end

--启动
function Actor:Start()
    if self:IsServer() then
        self:OnStartServer()
    else
        self:OnStartClient()
    end
end
--启动服务端
function Actor:OnStartServer()
end
--启动客户端
function Actor:OnStartClient()
end
--更新
function Actor:Update(dt)
    if self._started == nil then
        self:Start()
        self._started = true
    end

    --做限帧处理
    if self.updateRate ~= 0 then
        self.updateInterval = self.updateInterval - dt
        if self.updateInterval <= 0 then
            self.updateInterval = self.updateInterval + self.updateRate
            dt = self.updateRate
        else
            return
        end
    end

    if self.isServer then
        self:UpdateServer(dt)
    else
        self:UpdateClient(dt)
    end
    for k,v in ipairs(self.components) do
        if v._started == nil then
            v:Start()
            v._started = true
        end
    end
    for k,v in ipairs(self.updateComponents) do
        --统计更新耗时
        if Actor.profilerEnabled then
            Profiler:Start("Update: "..v.__cname,0.001)
        end
        v:Update(dt)
        if Actor.profilerEnabled then
            Profiler:Stop()
        end
    end

    --固定更新
    for k,v in ipairs(self.fixedUpdateComponents) do
        v.fixedUpdateTimeNow = v.fixedUpdateTimeNow + dt
        if v.fixedUpdateTimeNow >= v.fixedUpdateInterval then
            --统计更新耗时
            if Actor.profilerEnabled then
                Profiler:Start("FixedUpdate: "..v.__cname,0.001)
            end
            v:FixedUpdate(v.fixedUpdateInterval)
            if Actor.profilerEnabled then
                Profiler:Stop()
            end
            v.fixedUpdateTimeNow = v.fixedUpdateTimeNow - v.fixedUpdateInterval
        end
    end
end

--更新服务端
function Actor:UpdateServer(dt)
    --解算状态
    if self:HasAuthorityServerOnly() then
        local state = self:ResolveState()
        if self.state ~= state then
            self:ChangeState(state)
        end
    end
end
--更新客户端
function Actor:UpdateClient(dt)
    self:UpdateLocalUI(dt)

    if self:IsOwnerLocalPlayer() then
        local state = self:ResolveState()
        if self.state ~= state then
            self:ChangeState(state)
        end
    end
end

function Actor:SetUpdateRate(rate)
    self.updateRate = rate
    self.updateInterval = self.updateRate
end

--设置属性
function Actor:SetAttribute(name, value)
    local character = self:GetCharacter()
    if character then
        character:SetAttribute(name, value)
    end
end

--获取属性
function Actor:GetAttribute(name)
    local character = self:GetCharacter()
    if character then
        return character:GetAttribute(name)
    end
    return nil
end
--设置某个状态，记录在自定义属性里面
function Actor:SetCustomState(name, value)
    self:SetAttribute("State_"..name, value)
end
--获取某个状态
function Actor:GetCustomState(name)
    return self:GetAttribute("State_"..name)
end
--是否死亡
function Actor:IsDead()
    if self.HealthComponent then
        return self.HealthComponent:IsDead()
    end
    return false
end
--判断是否濒临死亡
function Actor:IsNearDeath()
    if self.HealthComponent then
        return self.HealthComponent:IsNearDeath()
    end
    return false
end

--判断是否击晕
function Actor:IsStun() 
    if self.StatComponent:HasValue("Stun") then
        return true
    end
    return false
end
--判断是否被沉默
function Actor:IsSilence()
    if self.StatComponent:HasValue("Silence") then
        return true
    end
    return false
end
--判断是否被击飞
function Actor:IsKnockUp()
    if self.StatComponent:HasValue("KnockUp") then
        return true
    end
    return false
end
--判断是否被击倒
function Actor:IsKnockDown()
    if self.StatComponent:HasValue("KnockDown") then
        return true
    end
    return false
end
function Actor:IsKnockBack()
    if self.StatComponent:HasValue("KnockBack") then
        return true
    end
    return false
end
--判断是否正在坠落
function Actor:IsFall()
    if self.StatComponent:HasValue("Fall") then
        return true
    end
    return false
end
--判断是否闪避
function Actor:IsRoll()
    if self.StatComponent:HasValue("Roll") then
        return true
    end
    return false
end
--判断是否超级闪避
function Actor:IsSuperRoll()
    if self.StatComponent:HasValue("SuperRoll") then
        return true
    end
    return false
end
--判断是否瞄准
function Actor:IsAim()
    if self.StatComponent:HasValue("Aim") then
        return true
    end
    return false
end
--判断是否腰射状态
function Actor:IsWaistShoot()
    if self.StatComponent:HasValue("Shooting") then
        return true
    end
    return false
end
--判断是否戒备状态
function Actor:IsAlert()
    if self.StatComponent:HasValue("Alert") then
        return true
    end
    return false
end
--判断是否蹲下
function Actor:IsCrouch()
    if self.StatComponent:HasValue("Crouch") then
        return true
    end
    return false
end
--判断是否趴下
function Actor:IsProne()
    if self.StatComponent:HasValue("Prone") then
        return true
    end
    return false
end
--判断是否静步走
function Actor:IsWalk()
    if self.StatComponent:HasValue("Walk") then
        return true
    end
    return false
end
--判断是否跳跃
function Actor:IsJump()
    if self.AvatarComponent:IsJump() then
        return true
    end
    return false
end
--判定是否飞行
function Actor:IsFly()
    if self.AvatarComponent:IsFly() then
        return true
    end
    return false
end

--判断是否睡眠
function Actor:IsSleep()
    if self:IsMoving() then
        return false
    end
    if self.StatComponent:HasValue("Sleep") then
        return true
    end
    return false
end

--判断是否在空中
function Actor:IsInAir()
    return self:IsFly() or self:IsJump()
end
--判断是否可以跑
function Actor:IsCanRun()
    if self:IsAim() or self:IsCrouch() or self:IsProne() or self:IsWaistShoot() or self:IsAlert() or self:IsWalk() or self:IsInAir() then
        return false
    end
    return true
end
--延迟执行
function Actor:DelayCall(func,delayTime)
    local timerId = TimerManager:AddTimer(function()
        table.remove(self.delayCallTimers, timerId)
        if not self.__delete__ then
            func()
        end
    end, delayTime, 1)
    table.insert(self.delayCallTimers, timerId)
    return timerId
end

--清理所有延迟执行
function Actor:ClearAllDelayCall()
    for k,v in ipairs(self.delayCallTimers) do
        TimerManager:RemoveTimer(v)
    end
    self.delayCallTimers = {}
end
--复活
function Actor:Revive(pos)
    if pos ~= nil then
        local groundPos = self:GetGroundPosition(pos)
        self:TeleportTo(groundPos)
    end
    --满血
    if self.HealthComponent then
        self.HealthComponent:Revive()
    end
    --怒气归0
    if self.AngerComponent then
        self.AngerComponent:SetValue(0)
    end

    --将当前玩家同步给其他玩家
    self.actorManager:SyncPlayerForSpawned(self)
    
    self:NotifyRevive()

    --通知客户端复活
    self:SendToAllClients(ActorNetProto.ResponseActorRevive, {})

    --[[2024-12-10 11:23 TODO : 
        已解决，优化可注释看下
        【FK】玩家加入游戏时的初始位置不正确】
        https://www.tapd.cn/38179541/bugtrace/bugs/view/1138179541001114862 
        【fk】进入游戏视角错误】
        https://www.tapd.cn/46302202/bugtrace/bugs/view/1146302202001114838
    ]]
    --为了防止掉落，先禁止物理然后再开启
    self.AvatarComponent:SetGravityEnable(true)
end

--序列化
function Actor:Serialize(data, purpose, includeComps,includeServerComps,includeClientComps)
    includeServerComps = includeServerComps == nil and true or includeServerComps
    includeClientComps = includeClientComps == nil and true or includeClientComps
    data.version = self.version

    if purpose ~= "Save" then
        data.netId = self.netId
    end

    self:SerializeSelf(data)

    if self.rootComponent then
        data.rootComp = self.rootComponent.__cname
    end
    data.comps = {}
    includeComps = includeComps or true
    if includeComps then
        for k,v in ipairs(self.components) do
            local check = true
            if v.serverComponentOnly and not includeServerComps then
                check = false
            end
            if v.clientComponentOnly and not includeClientComps then
                check = false
            end
            if check then
                local compData = {}
                v:Serialize(compData, purpose)
                table.insert(data.comps, compData)
            end
        end
    end
end

--反序列化
function Actor:Deserialize(data, includeComps)
    if data.version == nil then
        return
    end
    self.version = data.version
    self:DeserializeSelf(data)
    includeComps = includeComps or true
    if includeComps then
        for k,v in pairs(data.comps) do
            local comp = self:GetOrCreateComponent(v.type)
            if comp then
                comp:Deserialize(v)
                if data.rootComp == v.__cname then
                    self:SetRootComponent(comp)
                end
                if comp.subNetId then
                    self:AddSubNetObject(comp)
                else
                    Log:Error("Actor:Deserialize %s subNetId is nil", v.__cname)
                end
            end
        end
    end
end

function Actor:SerializeSelf(data)
    data.tid = self.tid
    data.sceneId = self:GetSceneId()

    data.actorId = self.actorId
    data.masterId = self.masterId
    data.nickName = self.nickName
    data.state = self.state
    data.tags = self.tags
    data.actorType = self.actorType
    data.hitFeedback = self.hitFeedback
    data.partnerLeaveEffect = self.partnerLeaveEffect
    data.otherData = self.otherData
    data.collideGroupID = self:GetCollideGroup()

    if self.playerId then
        data.playerId = self.playerId
    end
end

function Actor:DeserializeSelf(data)
    self.tid = data.tid
    --sceneId 不需要处理
    self.netId = data.netId
    self.actorId = data.actorId
    self.masterId = data.masterId
    self.nickName = data.nickName
    self.state = data.state
    self.tags = data.tags
    self.actorType = data.actorType
	self.hitFeedback = data.hitFeedback
    self.partnerLeaveEffect = data.partnerLeaveEffect or {}
    self.otherData = data.otherData or {}
    self.playerId = data.playerId
end
--重载完毕
function Actor:ReloadFinished()
    self:Fire(self:IsServer(),"ReloadFinished")
end
--加载完成
function Actor:LoadFinished()
    self:Fire(self:IsServer(),"LoadFinished")
end

--获取当前状态
function Actor:GetCurrentState()
    return self.state
end
--改变当前状态
function Actor:ChangeState(state, serverCall)
    if self.state ~= state then
        local oldState = self.state
        self.state = state
        self:NotifyStateChanged(oldState, state, serverCall)
    end
end
--当状态改变
function Actor:NotifyStateChanged(oldState, newState, serverCall)
    if self.isServer then
        self:RpcActorState(newState)
    else
        if not serverCall and self:IsOwnerLocalPlayer() then
            self:CmdOtherActorState(newState)
        end
    end

    self:Fire(self:IsServer(), "StateChanged", oldState, newState)
end

--状态解算
function Actor:ResolveState()
    --判断濒临死亡
    if self:IsNearDeath() then
        return ActorDefines.EActorState.NearDeath
    --判断死亡
    elseif self:IsDead() then
        return ActorDefines.EActorState.Dead
    --判断坠落
    elseif self:IsFall() then
        return ActorDefines.EActorState.Fall
    --判断击飞
    elseif self:IsKnockUp() and self.knockUpState then
        if self.knockUpState == 1 then
            return ActorDefines.EActorState.KnockUp2
        else
            return ActorDefines.EActorState.KnockUp
        end
    --判断击倒
    elseif self:IsKnockDown() then
        return ActorDefines.EActorState.KnockDown
    --判断击退
    elseif self:IsKnockBack() then
        return ActorDefines.EActorState.KnockBack
    --判断晕眩
    elseif self:IsStun() then
        return ActorDefines.EActorState.Stun
    --判断超级闪避
    elseif self:IsSuperRoll() then
        return ActorDefines.EActorState.SuperRoll
    --判断闪避
    elseif self:IsRoll() then
        return ActorDefines.EActorState.Roll
    --判断跳跃
    elseif self:IsJump() then
        return ActorDefines.EActorState.Jump
    elseif self:IsFly() then
        return ActorDefines.EActorState.Fly
    elseif self:IsSleep() then
        return ActorDefines.EActorState.Sleep
    --判断移动
    elseif self.AvatarComponent:IsMoving() then
        return ActorDefines.EActorState.Moving
    end
    return ActorDefines.EActorState.Idle
end
--服务端设置目标
function Actor:ServerSetTarget(target)
    if self.target == target then
        return
    end
    local oldTarget = self.target
    self.target = target
    --触发事件
    self:FireServer("TargetChanged", oldTarget,self.target)
end
--丢失目标
function Actor:ServerLostTarget(reason)
    self:ServerSetTarget(nil)
end
--设置目标
function Actor:SetTarget(target)
    if self.target == target then
        if target == nil then
            return
        elseif self:CheckId(target:GetActorId()) then
            return
        else
            -- 数据有变化
        end
    end
    local oldTarget = self.target
    self.target = target
    --触发事件
    self:FireClient("TargetChanged", oldTarget,self.target)
end
--进入战斗
function Actor:ServerEnterCombat()
    self.isInCombat = true
    self.enterCombatLocation = self:GetPosition()
    --触发事件
    self:FireServer("EnterCombat",self.enterCombatLocation)
    local body = {
        location = self.enterCombatLocation:ToTable()
    }
    self:SendToAllClients(ActorNetProto.ResponseEnterCombat, body)
end
--退出战斗
function Actor:ServerLeaveCombat()
    self.isInCombat = false
    self.enterCombatLocation = nil
    --触发事件
    self:FireServer("LeaveCombat")
    self:SendToAllClients(ActorNetProto.ResponseLeaveCombat, {})
end
--是否正在战斗中
function Actor:IsInCombat()
    return self.isInCombat
end
--获取进入战斗位置
function Actor:GetEnterCombatLocation()
    return self.enterCombatLocation
end
--获取目标
function Actor:GetTarget()
    return self.target
end
--获取能量组件
function Actor:GetEnergyComponent(type)
    if self.energyComps == nil then
        return nil
    end
    return self.energyComps[type]
end
------------------------------------Avatar------------------------------------
--获取高度
function Actor:GetHeight()
    return self.AvatarComponent:GetHeight()
end
--获取半径
function Actor:GetRadius()
    return self.AvatarComponent:GetRadius()
end
--获取位置
function Actor:GetPosition()
    return self.AvatarComponent:GetPosition()
end
--开始安全移动
function Actor:StartSafeMove()
    self.AvatarComponent:StartSafeMove()
end
--结束安全移动
function Actor:EndSafeMove()
    self.AvatarComponent:EndSafeMove()
end
--设置位置
function Actor:SetPosition(pos)
    self.AvatarComponent:SetPosition(pos)
end
--传送
function Actor:TeleportTo(pos)
    self.AvatarComponent:TeleportTo(pos)
end
--获取偏移位置
function Actor:GetOffsetPosition(pos)
    return self.AvatarComponent:GetOffsetPosition(pos)
end
--获取前方
function Actor:GetForward()
    return self.AvatarComponent:GetForward()
end
--获取右方向
function Actor:GetRight()
    return self.AvatarComponent:GetRight()
end
--获取旋转
function Actor:GetRotation()
    return self.AvatarComponent:GetRotation()
end
--设置旋转
function Actor:SetRotation(rot)
    self.AvatarComponent:SetRotation(rot)
end

function Actor:GetScale()
    return self.AvatarComponent:GetScale()
end

function Actor:SetScale(scale)
    self.AvatarComponent:SetScale(scale)
end

function Actor:GetEffectiveScale()
    return self.AvatarComponent:GetEffectiveScale()
end

--移动到目标
--@param target Actor 目标
--@param callback function 回调函数
--@param errorDistance 误差距离
function Actor:MoveToTarget(target, callback, errorDistance)
    self.AvatarComponent:MoveToTarget(target, callback, errorDistance)
end

--移动到目标位置
--@param pos Vector3 目标位置
--@param callback function 回调函数
--@param errorDistance 误差距离
function Actor:MoveTo(pos, callback, errorDistance)
    self.AvatarComponent:MoveTo(pos, callback, errorDistance)
end
--导航移动到
--@param pos Vector3 目标位置
--@param callback function 回调函数
--@param errorDistance 误差距离
function Actor:NavigateTo(pos, callback, errorDistance)
    self.AvatarComponent:NavigateTo(pos, callback, errorDistance)
end
--停止移动
function Actor:StopMove()
    self.AvatarComponent:StopMove()
end

--是否正在移动
function Actor:IsMoving()
    return self.AvatarComponent:IsMoving()
end
--旋转到目标位置
function Actor:RotateTo(targetPos, callback)
    self.AvatarComponent:RotateTo(targetPos, callback)
end
--停止旋转
function Actor:StopRotate()
    self.AvatarComponent:StopRotate()
end
--计算距离
function Actor:Distance(target, subRadius)
    local pos = self:GetPosition()
    local targetPos = target:GetPosition()
    if subRadius then
        local dis = pos:Distance(targetPos) - (self.AvatarComponent:GetDerivedRadius() + target.AvatarComponent:GetDerivedRadius())
        return math.max(0, dis)
    else
        return pos:Distance(targetPos)
    end
end
--朝向目标
function Actor:LookAt(target)
    self.AvatarComponent:LookAt(target.AvatarComponent)
end
--朝向位置
function Actor:LookAtPos(pos)
    self.AvatarComponent:LookAtPos(pos)
end
--设置方向
function Actor:SetDirection(dir)
    self.AvatarComponent:SetDirection(dir)
end
--获取地面位置
function Actor:GetGroundPosition(worldPos)
    return self.AvatarComponent:GetGroundPosition(worldPos)
end
--是否正在地面上
function Actor:IsOnGround()
    return self.AvatarComponent:IsOnGround()
end
--地面状态改变
function Actor:OnGroundChanged(isOnGround)
    if self:IsServer() then
        if isOnGround then
            if self:IsDead() then
                --开始死亡计时
                self:StartDeathTimer()
            end
        end
    end
end
--获取合法的位移位置
function Actor:GetValidPosition(worldPos)
    return self.AvatarComponent:GetValidPosition(worldPos)
end
--查找最近的可行走点
function Actor:FindNearestWalkablePoint(worldPos,radius)
    local character = self:GetCharacter()
    local nearPoint = character:FindNearestPolygonCenterAsync(Vector3.New(worldPos.x,worldPos.y,worldPos.z),radius)
    return Vec3.New(nearPoint.x,nearPoint.y,nearPoint.z)
end
--寻路，返回路径
function Actor:FindNavigatePath(targetPos)
    local character = self:GetCharacter()
    return Utils:FindNavigatePath(self:GetPosition(), targetPos)
end
--判断是否限制移动
function Actor:IsDisallowMove()
    return self.StatComponent:HasValue("Stun") or 
        self.StatComponent:HasValue("KnockDown") or 
        self.StatComponent:HasValue("KnockUp") or 
        self.StatComponent:HasValue("KnockBack") or 
        self.StatComponent:HasValue("BanMove") or
        self.StatComponent:HasValue("Freeze") or
        self:IsDead()
end
--判断是否限制行动
function Actor:IsDisallowAction(ignoreStates)
    ignoreStates = ignoreStates or {}
    return (not ignoreStates["Stun"] and self.StatComponent:HasValue("Stun")) or 
        (not ignoreStates["KnockDown"] and self.StatComponent:HasValue("KnockDown")) or 
        (not ignoreStates["KnockUp"] and self.StatComponent:HasValue("KnockUp")) or 
        (not ignoreStates["KnockBack"] and self.StatComponent:HasValue("KnockBack")) or 
        (not ignoreStates["Freeze"] and self.StatComponent:HasValue("Freeze")) or 
        (not ignoreStates["Dead"] and self:IsDead()) or
        -- (not ignoreStates["BanMove"] and self.StatComponent:HasValue("BanMove")) or 
        (not ignoreStates["NotAttack"] and self.StatComponent:HasValue("NotAttack"))
end
--是否可以输入
function Actor:IsDisallowInput()
    return self.StatComponent:HasValue("BanInput") or self:IsDead() or self:IsShadow()
end
--是否无视障碍
function Actor:IsIgnoreObstacle()
    return self.StatComponent:HasValue("IgnoreObstacle")
end
--无视障碍
function Actor:SetIgnoreObstacle(value)
    if self.ignoreObstacle == value then
        return
    end
    if value then
        self.backupCollideGroup = self:GetCollideGroup()
        self:SetCollideGroup(ActorDefines.CollideGroup.Soul)
    else
        if self.backupCollideGroup ~= nil then
            self:SetCollideGroup(self.backupCollideGroup)
        end
    end
    self.ignoreObstacle = value
end

--是否潜行
function Actor:IsStealth()
    return self.StatComponent:HasValue("Stealth")
end

--从另外一个Actor拷贝信息
function Actor:CopyFrom(actor)
    self:CopyComponentsFrom(actor)
end
--拷贝组件
function Actor:CopyComponentsFrom(actor)
    for _,component in ipairs(actor.components) do
        local newComponent = self:GetComponent(component.__cname)
        newComponent:CopyFrom(component)
    end
end

--应用游戏设置
function Actor:ApplyServerGameSettings(settings)
    for _,component in ipairs(self.components) do
        component:ApplyServerGameSettings(settings)
    end
end
function Actor:ApplyClientGameSettings(settings)
    for _,component in ipairs(self.components) do
        component:ApplyClientGameSettings(settings)
    end
end
--说话
function Actor:Say(msg)
    if self:IsServer() then
        self:SendToAllClients(ActorNetProto.ResponseActorSay, {msg = msg})
    else
        self:SendToServer(ActorNetProto.RequestActorSay, {msg = msg})
    end
end
--计算屏幕坐标
local function CalcScreenPos(actor, xOffset, height)
    local localPlayer = actor.actorManager:GetLocalPlayer()
    local pos = actor:GetPosition()
    pos.y = pos.y + height

    local rot = localPlayer.CameraController:GetRotation()
    local offsetPos = pos + rot * Vec3.New(xOffset,0,0)
    local screenPos = localPlayer.CameraController:WorldToScreen(offsetPos)
    return screenPos, offsetPos
end
--绑定UI
--@param ui 对应的UI节点
--@param xOffset double X偏移
--@param height double 高度偏移，垂直于Actor，不受rotate影响
function Actor:AddLocalUI(ui, xOffset, height,minScale,maxScale,globalScale)
    local screenPos = CalcScreenPos(self,xOffset,height)
    local localUI = {
        ui = ui,
        xOffset = xOffset or 0,
        height = height or 0,
        minScale = minScale,
        maxScale = maxScale,
        globalScale = globalScale or 1.0,
        _xSmooth = screenPos.x,
        _ySmooth = screenPos.y,
        _xCurrentVelocity = 0,
        _yCurrentVelocity = 0,
        _scaleSmooth = 1.0,
        _scaleCurrentVelocity = 0,
    }
    ui.Position = Vector2.New(screenPos.x, screenPos.y)
    table.insert(self.localUIs, localUI)
end
--移除绑定UI
function Actor:RemoveLocalUI(ui)
    for i,localUI in ipairs(self.localUIs) do
        if localUI.ui == ui then
            table.remove(self.localUIs, i)
            break
        end
    end
end
--更新localUI
function Actor:UpdateLocalUI(dt)
    for _,localUI in ipairs(self.localUIs) do
        if localUI.ui.Visible then
            local screenPos, worldPos = CalcScreenPos(self,localUI.xOffset,localUI.height)
            
            local smoothTime = 0.1
            localUI._xSmooth, localUI._xCurrentVelocity = Math:SmoothDamp(localUI._xSmooth, screenPos.x, localUI._xCurrentVelocity, smoothTime, 0, dt)
            localUI._ySmooth, localUI._yCurrentVelocity = Math:SmoothDamp(localUI._ySmooth, screenPos.y, localUI._yCurrentVelocity, smoothTime, 0, dt)
            
            localUI.ui.Position = Vector2.New(localUI._xSmooth, localUI._ySmooth)
            if localUI.minScale and localUI.maxScale then
                local scale = 1 / self.CameraController:CalculateFixedScaleFactor(worldPos)
                localUI.ui.Scale = Vector2.New(scale, scale)
                scale = math.clamp(scale, localUI.minScale, localUI.maxScale)

                localUI._scaleSmooth, localUI._scaleCurrentVelocity = Math:SmoothDamp(localUI._scaleSmooth, scale, localUI._scaleCurrentVelocity, smoothTime, 0, dt)
                localUI.ui.Scale = Vector2.New(localUI._scaleSmooth * localUI.globalScale, localUI._scaleSmooth * localUI.globalScale)
            end
        end
    end
end

--通知已经死亡
function Actor:NotifyDead()
    self:StopAllActions()
    if self:IsServer() then
        --通知玩家死亡
        self:FireServer("Dead")
        if self:IsOnGround() then
            self:StartDeathTimer()
        else
            --如果超过一定的时间也进行死亡倒计时
            self:DelayCall(function()
                self:StartDeathTimer()
            end, 2)
        end
    else
        self:FireClient("Dead")
        if self:IsOnGround() then
            self:StartDeathTimer()
        else
            --如果超过一定的时间也进行死亡倒计时
            self:DelayCall(function()
                self:StartDeathTimer()
            end, 2)
        end
    end
end
--通知复活
function Actor:NotifyRevive()
    self.deathTimerStarted = false
    if self:IsServer() then
        self:FireServer("Revive")
    else  
        self:FireClient("Revive")
    end
end

--杀死自己
function Actor:Kill()
    self.CombatComponent:Kill()
end

--开始尸体残留计时
function Actor:StartDeathTimer()
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
        return
    end
    if self.deathTimerStarted then
        return
    end
    self.deathTimerStarted = true
    self:DelayCall(function()
        --残留时间已到
        self:OnDeathTimeEnd()
    end, self:GetDeathTime())

    if self:IsServer() then 
        self:DelayCall(function()
            --尸体销毁时间已到
            self:OnDeathDestroyTimeEnd()
        end, self:GetDeathDestroyTime())
    end
end
--死亡残留时间
function Actor:GetDeathTime()
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
        return 0
    end
    return gameSetting.Combat.deathTime
end
--死亡溶解时间
function Actor:GetDissolveTime()
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
        return 0
    end
    return gameSetting.Combat.dissolveTime
end
--开始销毁时间
function Actor:GetDeathDestroyTime()
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
        return 0
    end
    return gameSetting.Combat.deathDestroyTime 
end

--残留时间已到
function Actor:OnDeathTimeEnd()
    --客户端开始做残留动画
end
--尸体销毁时间已到
function Actor:OnDeathDestroyTimeEnd()
    self.actorManager:ServerDestroyActor(self)
end

--通知角色是否可见
function Actor:NotifyCharacterVisibleChanged(visible)
    -- if visible then
    --     --恢复满帧更新
    --     self:SetUpdateRate(0)
    -- else
    --     self:SetUpdateRate(1 / 10)
    -- end
end

function Actor:NotifyAOIVisibleChanged(visible)
    if visible then
        --恢复满帧更新
        self:SetUpdateRate(0)
    else
        self:SetUpdateRate(1 / 10)
    end
end

--点击
function Actor:OnClicked(x, y)
end

--聚焦
function Actor:OnFocus()
end

--取消聚焦
function Actor:OnUnFocus()

end

--交互
function Actor:OnInteract(player, interactType)
    
end

--停止交互
function Actor:OnStopInteract(player, interactType)

end

--------------------------------------------Server--------------------------------------------
--同步生命值到客户端
function Actor:ServerSyncEnergy(energyType)
    local energyComp = self:GetEnergyComponent(energyType)
    self:SendToAllClients(ActorNetProto.ResponseEnergy, 
    {
        type = energyType,
        value = energyComp.value,
    })
end
--玩家说话
function Actor:OnRequestActorSay(body)
    self:SendToAllClients(ActorNetProto.ResponseActorSay, body)
end

--------------------------------------------Client--------------------------------------------

function Actor:OnResponseEnergy(data)
    local energyComp = self:GetEnergyComponent(data.type)
    if energyComp then
        energyComp:SetValue(data.value)
    end
end

--收到移动协议
function Actor:OnResponseMoveBy(body)
    self:StopActionByTag("Roll")
    self:StopActionByTag("ClientMoveBy")
    self:StopActionByTag("SuperRoll")
    local moveBy = MoveBy.New()
    local forward = Vec3.New(body.dir[1],body.dir[2],body.dir[3])
    local quat = Quat.New()
    quat:FromEuler(Vec3.New(0,body.angleOffset,0))
    forward = quat * forward
    moveBy:Init(body.duration,forward * body.distance)
    moveBy:SetSyncStartSpeed(body.syncStartSpeed)
    moveBy:SetSyncEndSpeed(body.syncEndSpeed)
    moveBy:SetTag("ClientMoveBy")
    self:RunAction(moveBy)

end
--收到进入战斗协议
function Actor:OnResponseEnterCombat(body)
    self.isInCombat = true
    self.enterCombatLocation = body.location
    self:FireClient("EnterCombat", self.enterCombatLocation)
end
--离开战斗
function Actor:OnResponseLeaveCombat(body)
    self.isInCombat = false
    self:FireClient("LeaveCombat")
end
--收到复活协议
function Actor:OnResponseActorRevive(body)
    self:NotifyRevive()
end
--Actor说话
function Actor:OnResponseActorSay(body)
    Log:Info(self:GetActorId().." "..self:GetNickName().." Say: "..body.msg)
end
--兼容后进Actor看不到先进Actor客机的展示效果
function Actor:CheckShowOff()

end
--------------------------------------------Network--------------------------------------------
local NetCallback = {}
function NetCallback.New(callback,obj)
	return {
		obj = obj,
		callback = callback
	}
end
--发送消息到服务器,只有本地玩家才可以
function Actor:SendToServer(msgid, body)
    if not self:IsServer() and self:IsOwnerLocalPlayer() then
        body.actorId = self:GetActorId()
        self:_FireServer(msgid, body)
    end
end
--发送消息到客户端，只有玩家才可以
function Actor:SendToClient(msgid, body)
    if self:IsServer() and self:IsOwnerPlayer() then
        local selfPlayerId = self:GetOwnerPlayerId()
        body.actorId = self:GetActorId()
        self:_FireClient(selfPlayerId, msgid, body)
    end
end
--发送协议给所有观察者
function Actor:SendToObservers(msgid, body, includeSelf)
    if includeSelf == nil then
        includeSelf = true
    end
    if self.actorManager:IsAoiEnabled() then
        local selfPlayerId = self:GetOwnerPlayerId()
        for k,v in pairs(self.observers) do
            if includeSelf or v:GetPlayerId() ~= selfPlayerId then
                v:SendToClient(msgid, body)
            end
        end
    else
        self:SendToAllClients(msgid, body, includeSelf)
    end
end
--广播消息到客户端
function Actor:SendToAllClients(msgid, body, includeSelf)
    if includeSelf == nil then
        includeSelf = true
    end
    if self:IsServer() then
        --暂时全员广播
		local players = Players:GetPlayers()
        local selfPlayerId = self:GetOwnerPlayerId()
		for i, v in ipairs(players) do
            local otherActor = self.actorManager:GetServerActor(v)
            if otherActor ~= nil and otherActor:GetSceneId() == self:GetSceneId() then
                if includeSelf or otherActor:GetPlayerId() ~= selfPlayerId then
                    body.actorId = self:GetActorId()
                    self:_FireClient(otherActor:GetPlayerId(), msgid, body)
                end
            end
		end
    end
end
function Actor:_FireClient(playerId, msgid, body)
    Network:_FireClient(Network.RemoteEvent, playerId, msgid, body)
end
function Actor:_FireServer(msgid, body)
    Network:_FireServer(Network.RemoteEvent, msgid, body)
end
--广播消息到其他客户端
function Actor:SendToOtherClients(msgid, body)
    if self:IsServer() then
        --暂时全员广播
		local players = Players:GetPlayers()
        local selfPlayerId = self:GetOwnerPlayerId()
		for i, v in ipairs(players) do
            if v.UserId ~= selfPlayerId then
                local otherActor = self.actorManager:GetServerActor(v)
                if otherActor ~= nil and otherActor:GetSceneId() == self:GetSceneId() then
                    body.actorId = self:GetActorId()
                    self:_FireClient(otherActor:GetPlayerId(), msgid, body)
                end
            end
		end
    end
end
--客户端协议监听
function Actor:ClientNetCallback(id, fun, obj)
    if self.clientNetCallback == nil then
        self.clientNetCallback = {}
    end
    self.clientNetCallback[id] = NetCallback.New(fun,obj)
end
--服务端协议监听
function Actor:ServerNetCallback(id, fun, obj)
    if self.serverNetCallback == nil then
        self.serverNetCallback = {}
    end
    self.serverNetCallback[id] = NetCallback.New(fun,obj)
end
--客户端接收到协议
function Actor:ClientReciveData(msgid, body)
    if self.clientNetCallback == nil then
        self.clientNetCallback = {}
    end
    local netCallback = self.clientNetCallback[msgid]
    if netCallback then
        PCall(function()
            if netCallback.obj then
                netCallback.callback(netCallback.obj, body)
            else
                netCallback.callback(body)
            end
        end,self)
    end
end
--服务端接收到协议
function Actor:ServerReciveData(msgid, body)
    if self.serverNetCallback == nil then
        self.serverNetCallback = {}
    end
    local netCallback = self.serverNetCallback[msgid]
    if netCallback then
        if netCallback.obj then
            PCall(function()
                if netCallback.obj then
                    netCallback.callback(netCallback.obj, body)
                else
                    netCallback.callback(body)
                end
            end,self)
        end
    end
end

--------------------------------------------Action--------------------------------------------
--运行动作
function Actor:RunAction(action)
    ActionManager:RunAction(self,action)
end
--根据Tag获取动作
function Actor:GetActionByTag(tag)
    return ActionManager:GetActionByTag(self,tag)
end

--根据Tag停止动作
function Actor:StopActionByTag(tag)
    ActionManager:StopActionByTag(self,tag)
end

--根据Tag获取Action的数量
function Actor:CountActionByTag(tag)
    return ActionManager:CountActionByTag(self,tag)
end

--停止所有动作
function Actor:StopAllActions()
    ActionManager:StopAllActions(self)
end


function Actor:OnEventDebug(eventName, ...)
    -- if self:IsServer() then
        Log:Error("Actor:OnEventDebug %s %s", self.__cname, eventName)
    -- end
end
--------------------------------------------Observer--------------------------------------------
--添加观察目标
function Actor:AddToObserving(target, initialize)
    if not self:IsPlayer() then
        Log:Error("Actor:AddToObserving failed, actor is not player")
        return
    end
    self.observing[target:GetActorId()] = target
    self.actorManager:ShowForPlayer(target, self, initialize)

end
--移除观察目标
function Actor:RemoveFromObserving(target, isDestroyed)
    if not self:IsPlayer() then
        Log:Error("Actor:RemoveFromObserving failed, actor is not player")
        return
    end
    self.observing[target:GetActorId()] = nil

    if not isDestroyed then
        self.actorManager:HideForPlayer(target, self)
    end

end


--添加观察者
function Actor:AddObserver(observer)
    if not observer:IsPlayer() then
        Log:Error("Actor:AddObserver failed, actor is not player")
        return
    end
    self.observers[observer:GetPlayerId()] = observer
end
--移除观察者
function Actor:RemoveObserver(observer)
    if not observer:IsPlayer() then
        Log:Error("Actor:RemoveObserver failed, actor is not player")
        return
    end
    self.observers[observer:GetPlayerId()] = nil
end

--------------------------------------LoadConfig--------------------------------------

--获取配置表名
function Actor:GetConfigName()
    return ActorSettings.Table.Actor
end

--加载配置
function Actor:OnLoadConfig(config)
    self.actorManager:ActorLoadConfig(self, config)
end

ConfigLoaderSetup:Setup(Actor)

function Actor:LoadAIFromTid(tid)
    local aiComp = self:GetOrCreateComponent("AIComponent")
    if aiComp then
        aiComp:LoadConfigFromTid(tid)
    end
end


--------------------------------------Cmd--------------------------------------
function Actor:CmdOtherActorState(newState)
    self:ORpcActorState(newState)
end

--------------------------------------Rpc--------------------------------------
function Actor:RpcSetMaster(masterId)
    self.master = nil
    self.masterId = masterId
end

function Actor:RpcServants(servantIds)
    self.servantIds = servantIds
end


function Actor:RpcActorState(newState)
    self:ChangeState(newState, true)
end
function Actor:ORpcActorState(newState)
    self:ChangeState(newState, true)
end


return Actor