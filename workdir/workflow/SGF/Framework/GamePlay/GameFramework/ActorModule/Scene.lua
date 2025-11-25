local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local EventObject = GFScript("CoreModule.EventObject")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local Network = GFScript("NetworkModule.Network")
local TrafficSystem = GFScript("ActorModule.TrafficSystem")
local PedestrianSystem = GFScript("ActorModule.PedestrianSystem")
local TriggerSystem = GFScript("ActorModule.TriggerSystem")
local Scene = Class.New("Scene")
local Players = game:GetService("Players")

--实例化
function Scene:Constructor(sceneId, sceneType, sceneData)
    self.sceneId = sceneId
    self.sceneType = sceneType or 0
    self.sceneData = sceneData or {}
    self.actorRootNode = nil
    self.effectRootNode = nil
    self.rootNodes = {} 

    self.actors = {}

    self.trafficSystem = TrafficSystem.New()
    self.pedestrianSystem = PedestrianSystem.New()

    self.trafficSystem:Init(self)
    self.pedestrianSystem:Init(self)

    --当前天气
    self.currentWeather = nil
    --当前天气索引
    self.currentWeatherIndex = 0
    --天气切换结束时间
    self.weatherChangeTimeEnd = 0
    --天气切换类型
    self.weatherChangeType = "Sequence" --Random:随机切换,Sequence:顺序切换
    --天气切换时间段
    self.weatherChangeConfig = nil
    -- {
    --     {
    --         duration = 0.2,--分钟
    --         weather = "Weather_1",--天气
    --         fadeTime = 10,--秒
    --     },
    --     {
    --         duration = 0.2,--分钟
    --         weather = "Weather_2",--天气
    --         fadeTime = 10,--秒
    --     },
    --     {
    --         duration = 0.2,--分钟
    --         weather = "Weather_3",--天气
    --         fadeTime = 10,--秒
    --     },
    --     {
    --         duration = 0.2,--分钟
    --         weather = "Weather_4",--天气
    --         fadeTime = 10,--秒
    --     }
    -- }
end

function Scene:Destructor()
    if self.notifyChildAddedEvent then
        self.notifyChildAddedEvent:Disconnect()
        self.notifyChildAddedEvent = nil
    end
    if self.notifyChildRemovedEvent then
        self.notifyChildRemovedEvent:Disconnect()
        self.notifyChildRemovedEvent = nil
    end

    if self.trafficSystem then
        self.trafficSystem:Destroy()
        self.trafficSystem = nil
    end
    if self.pedestrianSystem then
        self.pedestrianSystem:Destroy()
        self.pedestrianSystem = nil
    end
    if self.triggerSystem then
        self.triggerSystem:Destroy()
        self.triggerSystem = nil
    end
end

function Scene:GetTrafficSystem()
    return self.trafficSystem
end

function Scene:GetPedestrianSystem()
    return self.pedestrianSystem
end

function Scene:GetTriggerSystem()
    return self.triggerSystem
end

--获取场景Tid
function Scene:GetSceneTid()
    -- return "Scene_1"
    --从场景的自定义节点数据获取
    local sceneNode = self.workspace.scene
    if sceneNode then
        return sceneNode:GetAttribute("SceneTid")
    end
    return nil
end

--初始化
function Scene:Init(workspace)
    self.workspace = workspace
    self.workspaceId = workspace.SceneId

    local tid = self:GetSceneTid()
    if tid then
        self:LoadConfigFromTid(tid)
    end

    if Utils:IsServer() then
        self:InitServer()
    end

    if Utils:IsClient() then
        self:InitClient()
    end
end

function Scene:InitClient()
    local ActorManager = GFScript("ActorModule.ActorManager")
    self.workspace:WaitForChild('ActorRootNode')
    local node = self.workspace['ActorRootNode']

    --监听子节点添加函数
    self.notifyChildAddedEvent = node.NotifyChildAdded:Connect(function(node)
        if not Utils:IsServerOnly() then
            local actorId = Utils:GetActorId(node)
            local clientActor = ActorManager:GetClientActor(actorId)
            if not clientActor and actorId then
                --Log:Debug('[Scene] ActorRootNode NotifyChildAdded: ' .. actorId)
                --请求下发Actor信息
                local body = {
                    actorId = actorId
                }
                Network:SendToServer(ActorNetProto.RequestActor, body)
            end
        end
    end)
    self.notifyChildRemovedEvent =node.NotifyChildRemoved:Connect(function(node)
        if not Utils:IsServerOnly() then
            local actorId = Utils:GetActorId(node)
            local clientActor = ActorManager:GetClientActor(actorId)
            if clientActor and actorId then
                --Log:Debug('[Scene] ActorRootNode NotifyChildRemoved: ' .. actorId)
                ActorManager:_ClientDestroyActor(clientActor)
            end
        end
    end)

    self:InitClientTriggers()

    self:ClientNetCallback(ActorNetProto.ResponseSceneWeather, function(body)
        self:OnResponseSceneWeather(body)
    end)
end

function Scene:InitClientTriggers()
    if self.triggerInit then
        return
    end
    if not self.triggerSystem then
        self.triggerSystem = TriggerSystem.New()
        self.triggerSystem:Init(self, false)
    end
    --初始化触发器
    local triggers = self.workspace.Triggers
    if not triggers and self.workspace.scene then
        triggers = self.workspace.scene.Triggers
    end
    if triggers then
        self.triggerSystem:InitTriggers(triggers)
        self.triggerInit = true
    end
end

function Scene:InitServer()
    --创建actorRootNode
    self.actorRootNode = SandboxNode.New('SandboxNode')
    self.actorRootNode.Name = 'ActorRootNode'
    self.actorRootNode.Parent = self.workspace
    --初始化路径
    self.pedestrianSystem:InitWalkPaths(self.workspace.WalkPaths)
    -- self.trafficSystem:InitPaths(self.workspace.WalkPaths)

    self:ServerNetCallback(ActorNetProto.RequestSceneWeather, function(playerId, body)
        self:OnRequestSceneWeather(playerId, body)
    end)

    self.effectRootNode = SandboxNode.New('SandboxNode')
    self.effectRootNode.Name = 'EffectRootNode'
    self.effectRootNode.Parent = self.workspace
end

--获取actor根节点
function Scene:GetActorRootNode()
    if self.actorRootNode == nil and Utils:IsClientOnly() then
        self.actorRootNode = self.workspace['ActorRootNode']
    end
    return self.actorRootNode
end

--获取effect根节点
function Scene:GetEffectRootNode()
    if self.effectRootNode == nil and Utils:IsClientOnly() then
        self.effectRootNode = self.workspace['EffectRootNode']
    end
    return self.effectRootNode
end
--获取其他节点需要的根节点
function Scene:GetRootNode(name)
    --客户端直接获取返回
    if Utils:IsClientOnly() then
        local node = self.workspace[name]
        return node
    end
    local node = self.rootNodes[name]
    if node ~= nil then
        return node
    end
    local newNode = SandboxNode.New('SandboxNode')
    newNode.Name = name
    newNode.Parent = self.workspace
    self.rootNodes[name] = newNode
    return newNode
end

--获取场景Id
function Scene:GetSceneId()
    return self.sceneId
end

--获取场景类型
function Scene:GetSceneType()
    return self.sceneType
end

--获取场景数据
function Scene:GetSceneData()
    return self.sceneData
end

--获取workspace
function Scene:GetWorkspace()
    return self.workspace
end
--获取workspaceId
function Scene:GetWorkspaceId()
    return self.workspaceId
end
--是否是主场景
function Scene:IsMainScene()
    return self:GetWorkspaceId() == 0
end

--查找Actor节点
function Scene:FindActorNode(actorId)
    --从玩家列表中查找if bindObj == nil then
    local rootNode = self.workspace
    if not Utils:IsPlayerId(actorId) then
        rootNode = self:GetActorRootNode()
    end
    rootNode:WaitForChild(actorId)

    local ret = rootNode[actorId]
    return ret
    
    -- local Players = game:GetService("Players")
    -- for k, v in pairs(Players:GetPlayers()) do
    --     if Utils:GetActorId(v.Character) == actorId then
    --         return v.Character
    --     end
    -- end
    -- --从actor根节点查找
    -- local children = self:GetActorRootNode().Children
    -- for i = 1, #children do
    --     local child = children[i]
    --     if Utils:GetActorId(child) == actorId then
    --         return child
    --     end
    -- end
    -- return nil
end

--通知actor添加
function Scene:NotifyAddActor(actor)
    self.actors[actor:GetActorId()] = actor
    actor:OnAddToScene()
end
--通知actor移除
function Scene:NotifyRemoveActor(actor)
    self.actors[actor:GetActorId()] = nil
    actor:OnRemoveFromScene()
end

--获取环境节点
function Scene:GetEnvironment()
    self.workspace:WaitForChild("Environment")
    return self.workspace.Environment
end
--获取摄像机
function Scene:GetCamera()
    self.workspace:WaitForChild("Camera")
    return self.workspace.Camera
end

--更新
function Scene:Update(dt)
    local ActorManager = GFScript("ActorModule.ActorManager")
    --判断是否有需要处理的缓存场景协议
    --反向迭代
    for i=#ActorManager.cacheSceneProtos,1,-1 do
        local v = ActorManager.cacheSceneProtos[i]
        if v.sceneId == self.sceneId then
            local actor = ActorManager:AddActorForNetData(v.body)
            if actor then
                table.remove(ActorManager.cacheSceneProtos, i)
            end
        end
    end

    if Utils:IsServer() then
        if self.pedestrianSystem then
            self.pedestrianSystem:Update(dt)
        end
        if self.trafficSystem then
            self.trafficSystem:Update(dt)
        end
        self:UpdateWeather(dt)
    end
    if Utils:IsClient() then
        if not self.triggerInit and self.workspace.scene then
            self:InitClientTriggers()
        end
    end
end

--获取下一个天气
function Scene:GetNextWeather()
    if self.weatherChangeType == "Random" then
        local index = math.random(1, #self.weatherChangeConfig)
        self.currentWeatherIndex = index
        return self.weatherChangeConfig[index]
    elseif self.weatherChangeType == "Sequence" then
        self.currentWeatherIndex = self.currentWeatherIndex + 1
        if self.currentWeatherIndex > #self.weatherChangeConfig then
            self.currentWeatherIndex = 1
        end
        return self.weatherChangeConfig[self.currentWeatherIndex]
    end
end

--获取当前天气
function Scene:GetCurrentWeather()
    return self.currentWeather
end

--更新天气
function Scene:UpdateWeather(dt)
    if self.weatherChangeConfig ~= nil and Utils:GetServerTime() >= self.weatherChangeTimeEnd then
        self.currentWeather = self:GetNextWeather()
        if self.currentWeather then 
            self.weatherChangeTimeEnd = Utils:GetServerTime() + self.weatherChangeConfig[self.currentWeatherIndex].duration * 60
            self:SendToAllClients(ActorNetProto.ResponseSceneWeather, {
                weatherIndex = self.currentWeatherIndex,
            })
        end
    end
end

--请求场景天气
function Scene:RequestSceneWeather()
    self:SendToServer(ActorNetProto.RequestSceneWeather, {
    })
end

--响应场景天气
function Scene:OnRequestSceneWeather(playerId, body)
    self:SendToClient(playerId, ActorNetProto.ResponseSceneWeather, {
        weatherIndex = self.currentWeatherIndex,
        init = true,
    })
end

--响应场景天气
function Scene:OnResponseSceneWeather(body)
    self.currentWeatherIndex = body.weatherIndex
    local WeatherManager = GFScript("ActorModule.Weather.WeatherManager")
    if self.currentWeatherIndex <= #self.weatherChangeConfig then
        local weather = self.weatherChangeConfig[self.currentWeatherIndex]
        self.currentWeather = weather
        if weather then
            if body.init then
                WeatherManager:SwitchWeather(weather.weather)
            else
                WeatherManager:SwitchWeather(weather.weather, weather.fadeTime)
            end
        end
    end
end



------------------------------------DataTable------------------------------------
--加载配置
function Scene:LoadConfig(config)
    self.weatherChangeType = config.weatherChangeType
    self.weatherChangeConfig = config.weatherChangeConfig
end

--从tid加载数据
function Scene:LoadConfigFromTid(tid)
    local config = DataProviderManager:GetSceneData(tid)
    self:LoadConfig(config)
end

--广播消息到客户端
function Scene:SendToAllClients(msgid, body)
    if Utils:IsServer() then
        local ActorManager = GFScript("ActorModule.ActorManager")
        --暂时全员广播
		local players = Players:GetPlayers()
		for i, v in ipairs(players) do
            local otherActor = ActorManager:GetServerActor(v)
            if otherActor ~= nil and otherActor:GetSceneId() == self:GetSceneId() then
                body.sceneId = self.sceneId
                Network:_FireClient(Network.RemoteEvent, otherActor:GetPlayerId(), msgid, body)
            end
		end
    end
end

--发送消息到服务器,只有玩家才可以
function Scene:SendToServer(msgid, body)
    if Utils:IsServer() then
        body.sceneId = self.sceneId
        Network:_FireServer(Network.RemoteEvent, msgid, body)
    end
end

local NetCallback = {}
function NetCallback.New(callback,obj)
	return {
		obj = obj,
		callback = callback
	}
end
--客户端协议监听
function Scene:ClientNetCallback(id, fun, obj)
    if self.clientNetCallback == nil then
        self.clientNetCallback = {}
    end
    self.clientNetCallback[id] = NetCallback.New(fun,obj)
end
--服务端协议监听
function Scene:ServerNetCallback(id, fun, obj)
    if self.serverNetCallback == nil then
        self.serverNetCallback = {}
    end
    self.serverNetCallback[id] = NetCallback.New(fun,obj)
end
--客户端接收到协议
function Scene:ClientReciveData(msgid, body)
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
function Scene:ServerReciveData(playerId, msgid, body)
    if self.serverNetCallback == nil then
        self.serverNetCallback = {}
    end
    local netCallback = self.serverNetCallback[msgid]
    if netCallback then
        if netCallback.obj then
            PCall(function()
                if netCallback.obj then
                    netCallback.callback(netCallback.obj, playerId, body)
                else
                    netCallback.callback(playerId, body)
                end
            end,self)
        end
    end
end

return Scene