local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local GlobalEvent = GFScript("CoreModule.GlobalEvent")
local EventObject = GFScript("CoreModule.EventObject")
local NetworkSetup = GFScript("NetworkModule.NetworkSetup")

local ActorComponent = EventObject.Extend("ActorComponent")

----------------------------------------------
--由于技术困难，相同的组件在一个节点下只能存在一个
----------------------------------------------
--实例化
function ActorComponent:Constructor()
    --组件id，节点内唯一
    self.id = 0

    self.enabled = true
    self.updateEnabled = false
    self.laterUpdateEnabled = false
    self.fixedUpdateInterval = 0

    self.netId = nil
    self.subNetId = nil
end

function ActorComponent:OnConstructor()
    GlobalEvent:Setup(self)
    NetworkSetup:SetupRpc(self)
end

--析构
function ActorComponent:Destructor()
    self:OnDestroy()
    self.actor = nil
    self.componentParts = nil
end

--是否启用
function ActorComponent:IsEnabled()
    return self.enabled
end

--设置是否启用
function ActorComponent:SetEnabled(enabled)
    self.enabled = enabled
    self:OnEnabled(enabled)
end

--启用
function ActorComponent:OnEnabled(enabled)

end

--添加组件部分
function ActorComponent:AddComponentPart(compPart)
    if not self.componentParts then
        self.componentParts = {}
    end
    table.insert(self.componentParts, compPart)
    --将compPart的函数拷贝到当前组件
    for k, v in pairs(compPart) do
        if type(v) == "function" and k ~= "Init" and k ~= "Serialize" and k ~= "Deserialize" and k ~= "GetData" and k ~= "SetData" and k ~= "LoadData" and k ~= "SaveData" and k ~= "CopyFrom" then
            if self[k] then
                Log:Error("ActorComponent:AddComponentPart: function %s already exists", k)
            else
                self[k] = v
            end
        end
    end
end

--遍历组件部分
function ActorComponent:ForEachComponentParts(func)
    if not self.componentParts then
        return
    end
    for _, compPart in ipairs(self.componentParts) do
        func(compPart)
    end
end
--初始化
function ActorComponent:Init()
    self:ForEachComponentParts(function(compPart)
        compPart:Init()
    end)
end

--是否准备就绪
function ActorComponent:IsReady()
    return self.actor and self.actor:IsReady()
end

--是否服务端
function ActorComponent:IsServer()
    if self.actor then
        return self.actor:IsServer()
    end
    return false
end

--是否客户端
function ActorComponent:IsClient()
    return not self:IsServer()
end

--是否是玩家
function ActorComponent:IsPlayer()
    if self.actor then
        return self.actor:IsPlayer()
    end
    return false
end

--获取玩家id
function ActorComponent:GetPlayerId()
    if self.actor then
        return self.actor:GetPlayerId()
    end
    return 0
end

--获取服务器id
function ActorComponent:GetServerId()
    if self.actor then
        return self.actor:GetServerId()
    end
    return 0
end

--是否本地玩家
function ActorComponent:IsLocalPlayer()
    if self.actor then
        return self.actor:IsLocalPlayer()
    end
    return false
end
--是否拥有
function ActorComponent:IsOwned()
    if self.actor then
        return self.actor:IsOwned()
    end
    return false
end
--是否拥有所有权
function ActorComponent:HasAuthority()
    if self.actor then
        return self.actor:HasAuthority()
    end
    return false
end

function ActorComponent:HasAuthorityServerOnly()
    if self.actor then
        return self.actor:HasAuthorityServerOnly()
    end
    return false
end

--当节点设置的时候
function ActorComponent:OnActorSet(actor)
    if not actor then
        return
    end
    if self:IsServer() then
        if self.__initServer then
            return
        end
        if self.actor:IsPlayer() then
            self:InitDataTable()
        end
        self:InitServer()
        self.__initServer = true
    else
        if self.__initClient then
            return
        end
        self:InitClient()
        self.__initClient = true
    end
end

--初始化数据表
function ActorComponent:InitDataTable()
    if self.dataTableName then
        self.actor.DataComponent:RegisterTable(self.dataTableName, self, self.isMutable)
    end
end

function ActorComponent:InitServer()
end

function ActorComponent:InitClient()
end

--当场景设置的时候
function ActorComponent:OnSceneSet(scene)

end

--当绑定对象改变
function ActorComponent:OnBindObjChanged(oldBindObj, newBindObj)

end

--当id设置的时候
function ActorComponent:OnIdSet(id)

end

--设置所属节点
function ActorComponent:SetActor(actor)
    -- local userId = actor:GetPlayerId()
    -- if userId == 534771936 then
    --     print(debug.traceback())
    --     print("SetActor(): userId = ", userId)
    -- end
    self.actor = actor
    self:OnActorSet(actor)
end

--获取所属节点
function ActorComponent:GetActor()
    return self.actor
end

--获取节点id
function ActorComponent:GetActorId()
    if self.actor then
        return self.actor:GetActorId()
    end
    return 0
end

--获取组件id
function ActorComponent:GetId()
    return self.id
end

--初始化
function ActorComponent:Awake()

end

--启动
function ActorComponent:Start()
    if self:IsServer() then
        self:OnStartServer()
    else
        self:OnStartClient()
    end
end
--启动服务端
function ActorComponent:OnStartServer()
end
--启动客户端
function ActorComponent:OnStartClient()
end

--更新
function ActorComponent:Update(dt)
    if self:IsServer() then
        self:UpdateServer(dt)
    else
        self:UpdateClient(dt)
    end
end
--更新
function ActorComponent:FixedUpdate(dt)
    if self:IsServer() then
        self:FixedUpdateServer(dt)
    else
        self:FixedUpdateClient(dt)
    end
end
--更新服务端
function ActorComponent:UpdateServer(dt)
end
--更新客户端
function ActorComponent:UpdateClient(dt)
end
--更新服务端
function ActorComponent:FixedUpdateServer(dt)
end
--更新客户端
function ActorComponent:FixedUpdateClient(dt)
end

--销毁
function ActorComponent:OnDestroy()
end

--打印描述
function ActorComponent:GetDescription()

end

--序列化
function ActorComponent:Serialize(data, purpose)
    data.type = self.__cname
    if purpose ~= "Save" then
        data.subNetId = self.subNetId
    end
    self:ForEachComponentParts(function(subComp)
        subComp:Serialize(data, purpose)
    end)
end

--反序列化
function ActorComponent:Deserialize(data)
    if data.subNetId then
        self.subNetId = data.subNetId
    end
    self:ForEachComponentParts(function(subComp)
        subComp:Deserialize(data)
    end)
end
--获取数据
function ActorComponent:GetData()
    local data = {}
    self:Serialize(data, "Save")
    return data
end

--设置数据
function ActorComponent:SetData(data)
    self:Deserialize(data)
end

-- --获取数据
-- function ActorComponent:LoadData()
--     --这个函数不要实现，不注册到数据组件里面不执行任何操作
-- end

-- --设置数据
-- function ActorComponent:SaveData()
--     --这个函数不要实现，不注册到数据组件里面不执行任何操作
-- end

--复制
function ActorComponent:CopyFrom(comp)
end

--应用游戏设置
function ActorComponent:ApplyServerGameSettings(settings)
end

function ActorComponent:ApplyClientGameSettings(settings)
end


--发送消息到服务器,只有玩家才可以
function ActorComponent:SendToServer(msgid, body)
    self.actor:SendToServer(msgid, body)
end
--发送消息到客户端，只有玩家才可以
function ActorComponent:SendToClient(msgid, body)
    self.actor:SendToClient(msgid, body)
end

--发送协议给所有观察者
function ActorComponent:SendToObservers(msgid, body, includeSelf)
    self.actor:SendToObservers(msgid, body, includeSelf)
end
--广播消息到客户端
function ActorComponent:SendToAllClients(msgid, body, includeSelf)
    self.actor:SendToAllClients(msgid, body, includeSelf)
end
function ActorComponent:SendToOtherClients(msgid, body)
    self.actor:SendToOtherClients(msgid, body)
end
--客户端协议监听
function ActorComponent:ClientNetCallback(id, fun, obj)
    self.actor:ClientNetCallback(id, fun, obj)
end
--服务端协议监听
function ActorComponent:ServerNetCallback(id, fun, obj)
    self.actor:ServerNetCallback(id, fun, obj)
end

return ActorComponent
