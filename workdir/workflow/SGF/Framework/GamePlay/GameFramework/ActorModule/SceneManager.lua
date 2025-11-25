local Class = GFScript("CoreModule.Class")
local EventObject = GFScript("CoreModule.EventObject")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Scene = GFScript("ActorModule.Scene")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")

local SceneManager = Class.New("SceneManager", EventObject)
--所有场景列表
SceneManager.scenes = {}
--当前激活的场景
SceneManager.activeScene = nil

--初始化
function SceneManager:Init()
    local defworkspace = game:GetService("WorkSpace")
    self.defaultScene = self:AddSceneWithWorkSpace(defworkspace)

    local SceneMgr = game:GetService("SceneMgr")
    if Utils:IsServer() then
        SceneMgr.DynamicSceneOpResultServer:Connect(function(optype, workspaceid, result, uin)
            if result == 0 then
                if optype == 3 then
                    --删除
                    self:OnServerSceneRemoving(workspaceid)
                    if not Utils:IsServerOnly() then
                        self:OnSceneRemoving(workspaceid)
                    end
                else
                    local workspace = game:GetWorkSpace(workspaceid)
                    if optype == 1 then
                        --切换
                        self:OnServerSceneChanged(workspace, uin)
                        if not Utils:IsServerOnly() then
                            self:OnSceneChanged(workspace, uin)
                        end
                    elseif optype == 2 then
                        --添加
                        self:OnServerSceneAdded(workspace)
                        if not Utils:IsServerOnly() then
                            self:OnSceneAdded(workspace)
                        end
                    end
                end
            end
        end) 
    else
        SceneMgr.SceneOpResult:Connect(function(optype, workspaceid, result, uin)
            if result == 0 then
                if optype == 3 then
                    self:OnSceneRemoving(workspaceid)
                else
                    local workspace = game:GetWorkSpace(workspaceid)
                    if optype == 1  then
                        --切换
                        self:OnSceneChanged(workspace)
                    elseif optype == 2 then
                        --添加
                        self:OnSceneAdded(workspace)
                    end
                end
           end
           
        end) 
    end
end


--场景添加时
function SceneManager:OnServerSceneAdded(workspace)
    local scene = self:AddSceneWithWorkSpace(workspace)
    self:FireServer("SceneAdded", scene)
end
--场景改变时
function SceneManager:OnServerSceneChanged(workspace, playerId)
    local ActorManager = GFScript("ActorModule.ActorManager")
    
    --切换
    local scene = self:AddSceneWithWorkSpace(workspace)
    --设置服务端所属场景
    local player = ActorManager:GetServerPlayer(playerId)
    if player then
        --通知其他玩家我已经删除
        --发送协议通知Actor删除
        local body = 
        {
            actorId = player.actorId,
        }
        ActorManager:BroadcastOther(ActorNetProto.ResponseRemoveActor, body, player:GetSceneId(), player:GetPlayerId())
        --设置新场景
        player:SetScene(scene, true)
        --将当前玩家同步给其他玩家
        ActorManager:SyncPlayerForSpawned(player)
    end
    self:FireServer("SceneChanged", scene, playerId)
end
--场景移除时
function SceneManager:OnServerSceneRemoving(workspaceId)
    local scene = self:GetSceneByWorkspaceId(workspaceId)
    if scene then
        local ActorManager = GFScript("ActorModule.ActorManager")
        --将其他不在这个场景的Actor全部删除掉,反向循环
        local needRemoveActors = {}
        ActorManager:ForEachServerActors(function(actor)
            if actor:GetScene() == scene then
                table.insert(needRemoveActors, actor)
            end
        end)

        for _, actor in ipairs(needRemoveActors) do
            ActorManager:ServerDestroyActor(actor)
        end
        self:FireServer("SceneRemoving", scene)
        self.scenes[scene:GetSceneId()] = nil
        scene:Destroy()
    end
end

--场景添加时
function SceneManager:OnSceneAdded(workspace)
    local scene = self:AddSceneWithWorkSpace(workspace)
    self:FireClient("SceneAdded", scene)
end
--场景改变时
function SceneManager:OnSceneChanged(workspace)
    local ActorManager = GFScript("ActorModule.ActorManager")
    
    local scene = self:AddSceneWithWorkSpace(workspace)
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer then
        -- 设置场景
        localPlayer:SetScene(scene, true)
        -- 取消瞄准状态
        localPlayer.AvatarComponent:SetVisible(true)
        if localPlayer.CameraController then
            localPlayer.CameraController:SetFov(75)
        end
        
        --将其他不在这个场景的Actor全部删除掉,反向循环
        local needRemoveActors = {}
        ActorManager:ForEachClientActors(function(actor)
            if actor ~= localPlayer and  actor:GetSceneId() ~= localPlayer:GetSceneId() then
                table.insert(needRemoveActors, actor)
            end
        end)

        for _, actor in ipairs(needRemoveActors) do
            ActorManager:_ClientDestroyActor(actor)
        end

    end
    self.activeScene = scene
    if self.activeScene then
        self.activeScene:RequestSceneWeather()
    end

    
    if Utils:IsClientOnly() then
        --客户端只有1个场景
       for _, scene in pairs(self.scenes) do
           if scene ~= self.activeScene then
               scene:Destroy()
           end
       end 
       self.scenes = {}
       self.scenes[workspace.Name] = self.activeScene
    end
    self:FireClient("SceneChanged", self.activeScene)
end
--场景移除时
function SceneManager:OnSceneRemoving(workspaceId)
    local scene = self:GetSceneByWorkspaceId(workspaceId)
    if scene then
        self:FireClient("SceneRemoving", self.activeScene)
        scene:Destroy()
        self.scenes[scene:GetSceneId()] = nil
        self.scenes[sceneID] = nil
    end
end

--添加场景
function SceneManager:AddSceneWithWorkSpace(workspace)
    if self:GetScene(workspace.Name) then
        return self:GetScene(workspace.Name)
    end
    local scene = Scene.New(workspace.Name)
    scene:Init(workspace)
    self:AddScene(workspace.Name, scene)
    return scene
end

--添加场景
function SceneManager:AddScene(sceneID, scene)
    if self.activeScene == nil then
        self.activeScene = scene
    end
    self.scenes[sceneID] = scene
end

--获取场景
function SceneManager:GetScene(sceneID)
    return self.scenes[sceneID]
end

--获取场景
function SceneManager:GetSceneByWorkspace(workspace)
    return self:GetScene(workspace.Name)
end

--移除场景
function SceneManager:RemoveScene(sceneID)
    local scene = self:GetScene(sceneID)
    if scene then
        scene:Destroy()
        self.scenes[sceneID] = nil
    end
end

function SceneManager:GetSceneByWorkspaceId(workspaceId)
    for k,v in pairs(self.scenes) do
        if v.workspaceId == workspaceId then
            return v
        end
    end
end

--清理所有场景
function SceneManager:ClearAllScenes()
    for k,v in pairs(self.scenes) do
        v:Destroy()
    end
    self.activeScene = nil
    self.scenes = {}
end

--遍历场景
function SceneManager:ForEachScene(func)
    for k,v in pairs(self.scenes) do
        func(v)
    end
end

--获取默认场景
function SceneManager:GetDefaultScene()
    return self.defaultScene
end

--更新
function SceneManager:Update(dt)
    self:ForEachScene(function(scene)
        scene:Update(dt)
    end)
end

return SceneManager