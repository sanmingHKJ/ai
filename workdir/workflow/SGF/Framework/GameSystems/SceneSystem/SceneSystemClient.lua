--[[
    SceneSystemClient.lua - 场景管理系统（客户端）

    职责：
    1. 处理场景切换的客户端表现
    2. 管理传送门视觉效果
    3. 显示场景提示信息
    4. 本地场景对象缓存

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local SceneSystemClient = {
    name = "SceneSystemClient",
    version = "1.0.0",
    description = "场景管理系统（客户端）",
    dependencies = {},
    state = "uninitialized",
    sgf = nil,
    log = nil,
    events = nil,
    config = {},
    data = {
        currentScene = nil,
        currentSceneName = "主城",  -- 当前场景名称
        nearbyPortals = {},  -- 附近的传送门
        nearbyNPCs = {},     -- 附近的NPC
    },
    dependencies_cache = {},
    ui = {
        sceneLabel = nil,    -- 场景名称UI标签
    },
}

function SceneSystemClient.new(sgf)
    local self = setmetatable({}, {__index = SceneSystemClient})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    self.data = {
        currentScene = nil,
        currentSceneName = "主城",
        nearbyPortals = {},
        nearbyNPCs = {},
    }
    self.dependencies_cache = {}
    self.ui = {
        sceneLabel = nil,
        returnButton = nil,
    }
    return self
end

function SceneSystemClient:PreInit()
    self.log:info("SceneSystemClient PreInit...")
    self:registerEventListeners()
    return true
end

function SceneSystemClient:Init()
    if self.state ~= "uninitialized" then
        return false
    end
    self.log:info("SceneSystemClient Init...")

    -- 加载地图配置
    self.config.MapConfig = require(script.Parent.Parent.Parent.Config.Framework.MapConfig)

    self:registerNetworkHandlers()
    self.state = "initialized"
    return true
end

function SceneSystemClient:PostInit()
    self.log:info("SceneSystemClient PostInit...")
    self:resolveDependencies()
    return true
end

function SceneSystemClient:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("SceneSystemClient Start...")

    -- 初始化UI
    self:initializeUI()

    -- 设置初始场景名称（主城）
    self:updateSceneLabel("主城")

    -- 初始化返回按钮状态 (主城隐藏)
    self:setReturnButtonVisible(false)

    self.state = "started"
    return true
end

function SceneSystemClient:Update(dt)
    -- 检测玩家附近的传送门和NPC
    self:detectNearbyObjects(dt)
end

function SceneSystemClient:Stop()
    self.log:info("SceneSystemClient Stop...")
    self.state = "stopped"
    return true
end

function SceneSystemClient:registerEventListeners()
    self.log:debug("SceneSystemClient event listeners registered")
end

--[==[
    初始化UI元素
    查找并缓存场景名称标签
]==]
function SceneSystemClient:initializeUI()
    self.log:info("Initializing SceneSystemClient UI...")

    -- 获取本地玩家的PlayerGui (运行时UI从PlayerGui查找,不是StarterGui)
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        self.log:error("LocalPlayer not found")
        return
    end

    local playerGui = localPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then
        self.log:error("PlayerGui not found for LocalPlayer")
        return
    end

    -- 查找MainUIPanel (从PlayerGui,不是StarterGui)
    local mainUIPanel = playerGui:FindFirstChild("MainUIPanel")
    if not mainUIPanel then
        self.log:warning("MainUIPanel not found in PlayerGui")
        return
    end

    -- 查找Layer_NORMAL
    local layerNormal = mainUIPanel:FindFirstChild("Layer_NORMAL")
    if not layerNormal then
        self.log:warning("Layer_NORMAL not found in MainUIPanel")
        return
    end

    -- 查找SceneLabel
    local sceneLabel = layerNormal:FindFirstChild("SceneLabel")
    if sceneLabel then
        self.ui.sceneLabel = sceneLabel
        self.log:info("SceneLabel UI element found and cached from PlayerGui")
    else
        self.log:warning("SceneLabel not found in Layer_NORMAL")
    end

    -- 查找ReturnToMainCityButton (返回主城按钮)
    local returnButton = layerNormal:FindFirstChild("ReturnToMainCityButton")
    if returnButton then
        self.ui.returnButton = returnButton
        self:bindReturnButtonEvents(returnButton)
        self.log:info("ReturnToMainCityButton found and bound")
    else
        self.log:warning("ReturnToMainCityButton not found in Layer_NORMAL")
    end
end

--[==[
    更新场景名称标签
    @param sceneName string - 场景名称
]==]
function SceneSystemClient:updateSceneLabel(sceneName)
    if not self.ui.sceneLabel then
        self.log:warning("SceneLabel UI element not initialized, attempting to find it")
        self:initializeUI()
    end

    if self.ui.sceneLabel then
        -- UITextLabel使用Title属性,不是Text属性
        self.ui.sceneLabel.Title = sceneName
        self.log:info("SceneLabel updated to: " .. sceneName)
    else
        self.log:error("Failed to update SceneLabel: UI element not found")
    end
end

function SceneSystemClient:resolveDependencies()
    -- 客户端暂无依赖
end

function SceneSystemClient:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    if not NetworkHelper then
        self.log:error("NetworkHelper not found")
        return
    end

    -- 场景切换通知
    self:OnResponse(Protocol.ServerMSGID.SCENE_CHANGED_NOTIFY, function(msgid, data)
        self:onSceneChanged(data)
    end)

    self.log:debug("SceneSystemClient network handlers registered")
end

--[==[
    场景切换通知处理
]==]
function SceneSystemClient:onSceneChanged(data)
    local sceneId = data.sceneId
    local sceneName = data.sceneName
    local position = data.position

    self.log:info("Scene changed to: " .. sceneName)

    local oldSceneName = self.data.currentSceneName

    -- 显示场景切换动画和更新UI
    self:showSceneTransitionWithLabel(oldSceneName, sceneName)

    -- 更新当前场景数据
    self.data.currentScene = sceneId
    self.data.currentSceneName = sceneName

    -- 根据场景显示/隐藏返回按钮 (主城隐藏,其他场景显示)
    self:setReturnButtonVisible(sceneId ~= 1)

    -- 触发客户端事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.SceneChangedClient, {
        sceneId = sceneId,
        sceneName = sceneName,
        position = position,
    })
end

--[==[
    显示场景切换动画和标签更新
    先显示"场景正在切换中，从xxx到xxx"，然后恢复显示新场景名称
    @param oldSceneName string - 旧场景名称
    @param newSceneName string - 新场景名称
]==]
function SceneSystemClient:showSceneTransitionWithLabel(oldSceneName, newSceneName)
    self.log:info(string.format("Scene transitioning from %s to %s", oldSceneName, newSceneName))

    -- 显示切换中的提示文本
    local transitionText = string.format("场景正在切换中，从%s到%s", oldSceneName, newSceneName)
    self:updateSceneLabel(transitionText)

    -- 2秒后恢复显示新场景名称 (使用TimerManager延迟调用)
    local TimerManager = GFScript("CoreModule.TimerManager")
    TimerManager:DelayCall(function()
        self:updateSceneLabel(newSceneName)
        self.log:info("Scene transition complete, now showing: " .. newSceneName)
    end, 2)

    -- 触发UI事件（如果需要其他UI效果）
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.ShowSceneName, {
        oldSceneName = oldSceneName,
        newSceneName = newSceneName,
        transitionText = transitionText,
        duration = 2,  -- 显示2秒
    })
end

--[==[
    请求使用传送门
]==]
function SceneSystemClient:requestPortalTeleport(portalName)
    self.log:info("Requesting portal teleport: " .. portalName)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    if NetworkHelper then
        self:CallServer(Protocol.ClientMSGID.PORTAL_TOUCH_REQ, {
            portalName = portalName,
        })
    end
end

--[==[
    检测附近的可交互对象
]==]
function SceneSystemClient:detectNearbyObjects(dt)
    -- 这里可以实现检测逻辑
    -- 检测玩家附近的传送门和NPC
    -- 当靠近时显示交互提示

    -- 示例：检测传送门
    -- local player = self:getLocalPlayer()
    -- if player then
    --     local playerPos = player.Position
    --     -- 遍历所有传送门，计算距离
    --     -- 如果距离 < 交互范围，显示提示
    -- end
end

--[==[
    获取本地玩家
]==]
function SceneSystemClient:getLocalPlayer()
    -- 获取本地玩家对象
    -- 这需要根据MiniWorld Studio的实际API来实现
    return nil
end

--[==[
    显示交互提示
]==]
function SceneSystemClient:showInteractionHint(objectName, objectType)
    -- 显示"按E键交互"之类的提示
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.ShowInteractionHint, {
        objectName = objectName,
        objectType = objectType,
    })
end

--[==[
    隐藏交互提示
]==]
function SceneSystemClient:hideInteractionHint()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.HideInteractionHint, {})
end

--[==[
    绑定返回主城按钮事件
    @param button - 按钮UI对象
]==]
function SceneSystemClient:bindReturnButtonEvents(button)
    if not button then
        return
    end

    -- 绑定点击事件 (UIButton使用Click事件)
    button.Click:Connect(function(node, isSuccess, mousePos)
        if isSuccess then
            self:onReturnButtonClicked()
        end
    end)
end

--[==[
    处理返回主城按钮点击
    根据当前状态决定是否显示确认对话框
]==]
function SceneSystemClient:onReturnButtonClicked()
    self.log:info("Return to MainCity button clicked")

    -- 检查当前场景是否是主城
    if self.data.currentScene == 1 then
        self.log:info("Already in MainCity, no need to return")
        return
    end

    -- TODO: 检查战斗状态 (目前先简化处理,直接返回)
    -- local isInCombat = self:isPlayerInCombat()
    -- if isInCombat then
    --     self:showReturnConfirmDialog()
    -- else
    --     self:requestReturnToMainCity()
    -- end

    -- 简化版: 直接请求返回主城
    self:requestReturnToMainCity()
end

--[==[
    请求返回主城
    发送网络消息给服务端
]==]
function SceneSystemClient:requestReturnToMainCity()
    self.log:info("Requesting return to MainCity...")

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)

    -- 发送返回主城请求
    self:CallServer(Protocol.ClientMSGID.RETURN_TO_MAINCITY_REQ, {})
end

--[==[
    显示/隐藏返回按钮
    根据当前场景决定是否显示返回按钮
    @param visible boolean - 是否显示
]==]
function SceneSystemClient:setReturnButtonVisible(visible)
    if self.ui.returnButton then
        self.ui.returnButton.Visible = visible
        self.log:info("Return button visibility set to: " .. tostring(visible))
    end
end

return SceneSystemClient
