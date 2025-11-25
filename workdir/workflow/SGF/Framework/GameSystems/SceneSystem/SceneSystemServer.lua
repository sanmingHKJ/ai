--[[
    SceneSystemServer.lua - 场景管理系统（服务端）

    职责：
    1. 管理场景切换逻辑
    2. 处理传送门交互
    3. 管理敌人刷新点
    4. 场景对象初始化

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local SceneSystemServer = {
    name = "SceneSystemServer",
    version = "1.0.0",
    description = "场景管理系统（服务端）",
    dependencies = {"PlayerSystemServer"},
    state = "uninitialized",
    sgf = nil,
    log = nil,
    events = nil,
    config = {},
    data = {
        currentScenes = {},      -- [playerId] = sceneId
        portalObjects = {},      -- [sceneName][portalName] = portalObject
        enemySpawnObjects = {}, -- [sceneName][spawnName] = spawnObject
        npcObjects = {},        -- [sceneName][npcName] = npcObject
    },
    dependencies_cache = {},
}

function SceneSystemServer.new(sgf)
    local self = setmetatable({}, {__index = SceneSystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    self.data = {
        currentScenes = {},
        portalObjects = {},
        enemySpawnObjects = {},
        npcObjects = {},
        portalCooldowns = {},  -- 传送门冷却管理
        portalConnections = {}, -- 传送门Touched事件连接管理
    }
    self.dependencies_cache = {}
    return self
end

function SceneSystemServer:PreInit()
    self.log:info("SceneSystemServer PreInit...")
    self:registerEventListeners()
    return true
end

function SceneSystemServer:Init()
    if self.state ~= "uninitialized" then
        return false
    end
    self.log:info("SceneSystemServer Init...")

    -- 加载地图配置
    self.config.MapConfig = require(script.Parent.Parent.Parent.Config.Framework.MapConfig)

    self:registerNetworkHandlers()
    self.state = "initialized"
    return true
end

function SceneSystemServer:PostInit()
    self.log:info("SceneSystemServer PostInit...")
    self:resolveDependencies()
    return true
end

function SceneSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("SceneSystemServer Start...")

    -- 初始化场景对象
    self:initializeSceneObjects()

    self.state = "started"
    return true
end

function SceneSystemServer:Update(dt)
    -- 场景系统更新（如果需要）
end

function SceneSystemServer:Stop()
    self.log:info("SceneSystemServer Stop...")

    -- 清理所有传送门的Touched事件连接
    if self.data.portalConnections then
        for portalId, connection in pairs(self.data.portalConnections) do
            if connection then
                connection:disconnect()
                self.log:debug("Disconnected portal Touched event for " .. portalId)
            end
        end
        self.data.portalConnections = {}
    end

    self.state = "stopped"
    return true
end

function SceneSystemServer:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听来自 WorkSpace 的传送门触发事件
    self.events:on("Portal:PlayerTouched", function(data)
        self:handlePortalTouchEvent(data)
    end)

    -- 监听玩家进入游戏事件
    self.events:on(EventID.PlayerJoined, function(data)
        if data and data.player then
            self:onPlayerJoined(data.player)
        elseif data and data.userId then
            -- 兼容使用 userId 的事件格式
            self:onPlayerJoined({UserId = data.userId})
        else
            self.log:warning("PlayerJoined event data is invalid")
        end
    end)

    -- 监听玩家离开游戏事件
    self.events:on(EventID.PlayerLeft, function(data)
        if data and data.player then
            self:onPlayerLeft(data.player)
        elseif data and data.userId then
            -- 兼容使用 userId 的事件格式
            self:onPlayerLeft({UserId = data.userId})
        else
            self.log:warning("PlayerLeft event data is invalid")
        end
    end)

    self.log:debug("SceneSystemServer event listeners registered")
end

function SceneSystemServer:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
    end
end

function SceneSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    if not NetworkHelper then
        self.log:error("NetworkHelper not found")
        return
    end

    -- 场景切换请求
    self:OnRequest(Protocol.ClientMSGID.SCENE_CHANGE_REQ, function(userId, msgid, data)
        return self:handleSceneChange(userId, data)
    end)

    -- 传送门触碰
    self:OnRequest(Protocol.ClientMSGID.PORTAL_TOUCH_REQ, function(userId, msgid, data)
        return self:handlePortalTouch(userId, data)
    end)

    -- 返回主城请求 (UI按钮)
    self:OnRequest(Protocol.ClientMSGID.RETURN_TO_MAINCITY_REQ, function(userId, msgid, data)
        return self:handleReturnToMainCity(userId, data)
    end)

    self.log:debug("SceneSystemServer network handlers registered")
end

--[==[
    初始化场景对象
    查找WorkSpace中的传送门、敌人刷新点、NPC等对象
]==]
function SceneSystemServer:initializeSceneObjects()
    self.log:info("Initializing scene objects...")

    -- 获取WorkSpace
    local workspace = game:GetService("WorkSpace")
    if not workspace then
        self.log:error("WorkSpace not found")
        return
    end

    -- 初始化主城场景对象
    self:initializeMainCityObjects(workspace)

    -- 初始化森林战场场景对象
    self:initializeForestBattleObjects(workspace)

    -- 设置初始场景可见性：MainCity可见，其他场景不可见
    self:setInitialSceneVisibility(workspace)

    self.log:info("Scene objects initialized successfully")
end

--[==[
    设置初始场景可见性
    游戏开始时，MainCity可见，其他战斗场景不可见
]==]
function SceneSystemServer:setInitialSceneVisibility(workspace)
    self.log:info("Setting initial scene visibility...")

    -- MainCity 初始可见
    local mainCity = workspace:FindFirstChild("MainCity")
    if mainCity then
        mainCity.Visible = true
        self.log:info("MainCity set to visible")
    else
        self.log:warning("MainCity scene not found for visibility setting")
    end

    -- ForestBattle 初始不可见
    local forestBattle = workspace:FindFirstChild("ForestBattle")
    if forestBattle then
        forestBattle.Visible = false
        self.log:info("ForestBattle set to invisible")
    else
        self.log:warning("ForestBattle scene not found for visibility setting")
    end

    -- 未来的其他场景也设置为不可见
    -- local caveBattle = workspace:FindFirstChild("CaveBattle")
    -- if caveBattle then caveBattle.Visible = false end
end

--[==[
    初始化主城场景对象
]==]
function SceneSystemServer:initializeMainCityObjects(workspace)
    local mainCity = workspace:FindFirstChild("MainCity")
    if not mainCity then
        self.log:warning("MainCity scene not found in WorkSpace")
        return
    end

    self.data.portalObjects["MainCity"] = {}
    self.data.npcObjects["MainCity"] = {}

    -- 查找传送门
    local teleports = mainCity:FindFirstChild("Teleports")
    if teleports then
        -- 森林传送门
        local forestPortal = self:findChildRecursive(teleports, "TeleportPortal_Forest")
        if forestPortal then
            self.data.portalObjects["MainCity"]["TeleportPortal_Forest"] = forestPortal
            self:setupPortalInteraction(forestPortal, "TeleportPortal_Forest", 2)  -- targetSceneId: ForestBattle
            self.log:info("Forest portal initialized")
        end

        -- 其他传送门（未来）
        -- ...
    end

    -- 查找NPC
    local npcs = mainCity:FindFirstChild("NPCs")
    if npcs then
        local questNPC = self:findChildRecursive(npcs, "QuestNPC")
        if questNPC then
            self.data.npcObjects["MainCity"]["QuestNPC"] = questNPC
            self:setupNPCInteraction(questNPC, {
                npcId = "QuestNPC_MainCity",
                npcType = "quest",
                npcName = "任务管理员·莉娅",
                metadata = { questType = "main" }
            })
            self.log:info("Quest NPC initialized")
        end

        local shopNPC = self:findChildRecursive(npcs, "ShopNPC")
        if shopNPC then
            self.data.npcObjects["MainCity"]["ShopNPC"] = shopNPC
            self:setupNPCInteraction(shopNPC, {
                npcId = "ShopNPC_MainCity",
                npcType = "shop",
                npcName = "商店老板·马克",
                metadata = { shopId = "MainCityShop" }
            })
            self.log:info("Shop NPC initialized")
        end
    end
end

--[==[
    初始化森林战场场景对象
]==]
function SceneSystemServer:initializeForestBattleObjects(workspace)
    local forestBattle = workspace:FindFirstChild("ForestBattle")
    if not forestBattle then
        self.log:warning("ForestBattle scene not found in WorkSpace")
        return
    end

    self.data.portalObjects["ForestBattle"] = {}
    self.data.enemySpawnObjects["ForestBattle"] = {}

    -- 查找退出传送门
    local exitPortal = self:findChildRecursive(forestBattle, "ExitPortal")
    if exitPortal then
        self.data.portalObjects["ForestBattle"]["ExitPortal"] = exitPortal
        self:setupPortalInteraction(exitPortal, "ExitPortal", 1)  -- targetSceneId: MainCity
        self.log:info("Exit portal initialized")
    end

    -- 查找敌人刷新点
    local enemySpawns = forestBattle:FindFirstChild("EnemySpawns")
    if enemySpawns then
        for i = 1, 3 do
            local spawnName = "EnemySpawn" .. i
            local spawnObj = self:findChildRecursive(enemySpawns, spawnName)
            if spawnObj then
                self.data.enemySpawnObjects["ForestBattle"][spawnName] = spawnObj
                self.log:info(spawnName .. " initialized")
            end
        end
    end
end

--[==[
    递归查找子对象
]==]
function SceneSystemServer:findChildRecursive(parent, childName)
    if not parent then return nil end

    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end

    -- 递归查找
    for _, obj in pairs(parent:GetChildren()) do
        local found = self:findChildRecursive(obj, childName)
        if found then
            return found
        end
    end

    return nil
end

--[==[
    设置传送门交互
]==]
function SceneSystemServer:setupPortalInteraction(portalObject, portalId, targetSceneId)
    if not portalObject then
        self.log:error("Portal object is nil for " .. portalId)
        return
    end

    -- 配置传送门的物理属性,使其能够触发 Touched 事件
    -- 参考: Documents/Scene/Model.md 和 reference/fk 项目
    portalObject.Anchored = true          -- 锚定,不受外部物理影响
    portalObject.EnableGravity = false    -- 不受重力影响
    portalObject.CanCollide = false       -- 不产生物理碰撞(触发器模式,玩家可穿过)
    portalObject.CanTouch = true          -- ✅ 启用 Touched/TouchEnded 事件(必需!)

    self.log:debug(string.format(
        "[Portal] %s physics properties configured: CanTouch=true, CanCollide=false",
        portalId
    ))

    -- 检查是否支持 Touched 事件
    if not portalObject.Touched then
        self.log:warning("Portal object does not support Touched event for " .. portalId)
        return
    end

    -- 设置传送门的 Touched 回调 (使用 connect 方法)
    local connection = portalObject.Touched:connect(function(node, pos, normal)
        if not node then
            return
        end

        -- 检查是否为玩家角色，并获取 UserId
        if node.ClassType == 'Actor' and node.UserId then
            local playerId = node.UserId

            self.log:debug(string.format(
                "Player %d touched portal %s, target scene: %s",
                playerId, portalId, tostring(targetSceneId)
            ))

            -- 调用传送门触碰处理逻辑
            self:handlePortalTouchEvent({
                playerId = playerId,
                portalId = portalId,
                targetSceneId = targetSceneId,
            })
        end
    end)

    -- 存储连接引用以便后续清理
    self.data.portalConnections[portalId] = connection

    self.log:info(string.format("[Portal] %s interaction setup complete (target scene: %s)", portalId, tostring(targetSceneId)))
end

--[==[
    设置NPC交互
    @param npcObject - NPC节点对象
    @param npcConfig table - {npcId, npcType, npcName, metadata}
]==]
function SceneSystemServer:setupNPCInteraction(npcObject, npcConfig)
    if not npcObject then
        self.log:error("NPC object is nil for " .. (npcConfig.npcId or "unknown"))
        return
    end

    -- 通过EventBus通知 NPCInteractionSystemServer 注册NPC
    self.events:emit("NPC:Initialized", {
        npcId = npcConfig.npcId,
        npcType = npcConfig.npcType,
        npcName = npcConfig.npcName,
        npcNode = npcObject,
        metadata = npcConfig.metadata or {},
    })

    self.log:info(string.format("[NPC] %s (%s) interaction setup complete", npcConfig.npcId, npcConfig.npcType))
end

--[==[
    玩家进入游戏
]==]
function SceneSystemServer:onPlayerJoined(player)
    local playerId = player.UserId
    self.log:info("Player " .. playerId .. " joined, initializing scene...")

    -- 传送玩家到主城出生点
    local spawnPos = self.config.MapConfig.SpawnPositions[self.config.MapConfig.ScenesTypeID.MainCity]
    self:teleportPlayer(playerId, self.config.MapConfig.ScenesTypeID.MainCity, spawnPos)
end

--[==[
    玩家离开游戏
]==]
function SceneSystemServer:onPlayerLeft(player)
    local playerId = player.UserId
    self.data.currentScenes[playerId] = nil
    self.log:info("Player " .. playerId .. " left, scene data cleared")
end

--[==[
    处理场景切换请求
]==]
function SceneSystemServer:handleSceneChange(userId, data)
    local playerId = userId
    local targetSceneId = data.targetSceneId
    local targetPos = data.targetPos

    self.log:info("Player " .. playerId .. " requesting scene change to " .. targetSceneId)

    -- 验证场景是否有效
    local sceneInfo = self.config.MapConfig.SceneInfo[targetSceneId]
    if not sceneInfo then
        self.log:error("Invalid scene ID: " .. targetSceneId)
        return {success = false, reason = "Invalid scene"}
    end

    -- 检查场景是否开放
    if sceneInfo.enabled == false then
        self.log:warning("Scene " .. sceneInfo.name .. " is not enabled yet")
        return {success = false, reason = "Scene not available"}
    end

    -- 检查玩家等级要求
    if sceneInfo.recommendedLevel then
        local playerSystem = self.dependencies_cache.PlayerSystem
        if playerSystem then
            local playerData = playerSystem:getPlayerData(playerId)
            if playerData and playerData.level < sceneInfo.recommendedLevel.min then
                self.log:warning("Player level too low for " .. sceneInfo.name)
                return {success = false, reason = "Level requirement not met"}
            end
        end
    end

    -- 执行传送
    local success = self:teleportPlayer(playerId, targetSceneId, targetPos)

    return {success = success}
end

--[==[
    处理传送门触碰
]==]
function SceneSystemServer:handlePortalTouch(userId, data)
    local playerId = userId
    local portalName = data.portalName

    self.log:info("Player " .. playerId .. " touched portal: " .. portalName)

    -- 获取当前场景
    local currentSceneId = self.data.currentScenes[playerId] or self.config.MapConfig.ScenesTypeID.MainCity

    -- 查找传送门配置
    local portalConfig = nil
    local portals = self.config.MapConfig.Portals[currentSceneId]
    if portals then
        for _, portal in ipairs(portals) do
            if portal.name == portalName then
                portalConfig = portal
                break
            end
        end
    end

    if not portalConfig then
        self.log:error("Portal config not found: " .. portalName)
        return {success = false, reason = "Portal not found"}
    end

    -- 检查传送门是否启用
    if not portalConfig.enabled then
        return {success = false, reason = "Portal not available"}
    end

    -- 检查等级要求
    if portalConfig.requiredLevel > 0 then
        local playerSystem = self.dependencies_cache.PlayerSystem
        if playerSystem then
            local playerData = playerSystem:getPlayerData(playerId)
            if playerData and playerData.level < portalConfig.requiredLevel then
                return {success = false, reason = "Level requirement: " .. portalConfig.requiredLevel}
            end
        end
    end

    -- 获取目标场景出生点
    local targetPos = self.config.MapConfig.SpawnPositions[portalConfig.targetScene]

    -- 执行传送
    local success = self:teleportPlayer(playerId, portalConfig.targetScene, targetPos)

    return {success = success, targetScene = portalConfig.targetScene}
end

--[==[
    传送玩家到指定场景
]==]
function SceneSystemServer:teleportPlayer(playerId, sceneId, position)
    if not position then
        self.log:error("Invalid position for teleport")
        return false
    end

    -- 获取玩家对象
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)
    if not player then
        self.log:error("Player not found: " .. tostring(playerId))
        return false
    end

    -- 检查玩家角色是否存在
    if not player.Character then
        self.log:error("Player character not found: " .. tostring(playerId))
        return false
    end

    -- 设置玩家角色位置 (参考xplants项目的实现)
    local success, err = pcall(function()
        player.Character.Position = Vector3.New(position.x, position.y, position.z)
    end)

    if not success then
        self.log:error("Failed to teleport player: " .. tostring(err))
        return false
    end

    -- 更新玩家当前场景
    local oldSceneId = self.data.currentScenes[playerId]
    self.data.currentScenes[playerId] = sceneId

    -- 切换场景可见性：隐藏所有场景，只显示目标场景
    self:switchSceneVisibility(sceneId)

    -- 触发场景切换事件
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.SceneChanged, {
        player = player,
        playerId = playerId,
        fromScene = oldSceneId,
        toScene = sceneId,
        position = position,
    })

    -- 发送通知到客户端
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:CallClient(playerId, Protocol.ServerMSGID.SCENE_CHANGED_NOTIFY, {
        sceneId = sceneId,
        sceneName = self.config.MapConfig.SceneInfo[sceneId].name,
        position = {x = position.x, y = position.y, z = position.z},
    })

    self.log:info("Player " .. playerId .. " teleported to scene " .. sceneId)
    return true
end

--[==[
    切换场景可见性
    根据场景ID切换场景的可见性，确保只有目标场景可见，其他场景不可见
    @param targetSceneId number - 目标场景ID
]==]
function SceneSystemServer:switchSceneVisibility(targetSceneId)
    local workspace = game:GetService("WorkSpace")
    if not workspace then
        self.log:error("WorkSpace not found for scene visibility switch")
        return
    end

    -- 场景ID到场景节点名称的映射
    local sceneIdToName = {
        [self.config.MapConfig.ScenesTypeID.MainCity] = "MainCity",
        [self.config.MapConfig.ScenesTypeID.ForestBattle] = "ForestBattle",
        [self.config.MapConfig.ScenesTypeID.CaveBattle] = "CaveBattle",
        [self.config.MapConfig.ScenesTypeID.MagicTower] = "MagicTower",
    }

    -- 遍历所有场景，设置可见性
    for sceneId, sceneName in pairs(sceneIdToName) do
        local scene = workspace:FindFirstChild(sceneName)
        if scene then
            if sceneId == targetSceneId then
                -- 目标场景设置为可见
                scene.Visible = true
                self.log:info(string.format("Scene %s (ID: %d) set to visible", sceneName, sceneId))
            else
                -- 其他场景设置为不可见
                scene.Visible = false
                self.log:debug(string.format("Scene %s (ID: %d) set to invisible", sceneName, sceneId))
            end
        else
            if sceneId == targetSceneId then
                self.log:warning(string.format("Target scene %s (ID: %d) not found in WorkSpace", sceneName, sceneId))
            end
        end
    end
end

--[==[
    获取场景中的对象
]==]
function SceneSystemServer:getSceneObject(sceneName, objectName)
    local workspace = game:GetService("WorkSpace")
    if not workspace then
        return nil
    end

    local scene = workspace:FindFirstChild(sceneName)
    if not scene then
        return nil
    end

    return self:findChildRecursive(scene, objectName)
end

--[==[
    获取敌人刷新点配置
]==]
function SceneSystemServer:getEnemySpawnConfig(sceneId)
    return self.config.MapConfig.EnemySpawns[sceneId] or {}
end

--[==[
    获取敌人刷新点对象
]==]
function SceneSystemServer:getEnemySpawnObject(sceneName, spawnName)
    if self.data.enemySpawnObjects[sceneName] then
        return self.data.enemySpawnObjects[sceneName][spawnName]
    end
    return nil
end

--[==[
    获取玩家当前场景
]==]
function SceneSystemServer:getPlayerScene(playerId)
    return self.data.currentScenes[playerId] or self.config.MapConfig.ScenesTypeID.MainCity
end

-- ========================================
-- 传送门处理逻辑（从 WorkSpace 迁移）
-- ========================================

--[==[
    处理传送门触碰事件（从事件系统调用）
    @param data table - {playerId, portalId, targetSceneId}
]==]
function SceneSystemServer:handlePortalTouchEvent(data)
    local playerId = data.playerId
    local portalId = data.portalId
    local targetSceneId = data.targetSceneId

    self.log:info(string.format("[Portal] Player %s touched portal %s", playerId, portalId))

    -- 检查冷却
    if self:isPortalInCooldown(playerId, portalId) then
        self.log:info(string.format("[Portal] Player %s in cooldown", playerId))
        return
    end

    -- 检查传送条件
    if not self:canTeleport(playerId, targetSceneId) then
        self:sendTeleportDenied(playerId, "条件不满足")
        return
    end

    -- 获取目标场景出生点
    local targetPos = self.config.MapConfig.SpawnPositions[targetSceneId]
    if not targetPos then
        self.log:error(string.format("[Portal] No spawn position for scene %d", targetSceneId))
        self:sendTeleportDenied(playerId, "目标场景配置错误")
        return
    end

    -- 发送传送提示到客户端
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:CallClient(playerId, Protocol.ServerMSGID.PORTAL_TOUCH_RSP, {
        portalId = portalId,
        portalName = self:getPortalName(portalId),
        targetSceneId = targetSceneId,
    })

    -- 执行传送
    local success = self:teleportPlayer(playerId, targetSceneId, targetPos)

    if not success then
        self.log:error(string.format("[Portal] Failed to teleport player %s to scene %d", playerId, targetSceneId))
        return
    end

    -- 设置冷却
    self:setPortalCooldown(playerId, portalId)

    -- 记录日志
    self.log:info(string.format("[Portal] Player %s teleported to scene %d", playerId, targetSceneId))
end

--[==[
    检查传送门是否在冷却中
]==]
function SceneSystemServer:isPortalInCooldown(playerId, portalId)
    local key = playerId .. "_" .. portalId
    if not self.data.portalCooldowns[key] then
        return false
    end

    local elapsed = os.time() - self.data.portalCooldowns[key]
    return elapsed < 2  -- 2秒冷却时间
end

--[==[
    设置传送门冷却
]==]
function SceneSystemServer:setPortalCooldown(playerId, portalId)
    local key = playerId .. "_" .. portalId
    self.data.portalCooldowns[key] = os.time()
end

--[==[
    检查玩家是否可以传送
]==]
function SceneSystemServer:canTeleport(playerId, targetSceneId)
    -- 可以添加更多检查逻辑
    -- - 等级要求
    -- - 任务要求
    -- - 物品要求
    return true
end

--[==[
    发送传送拒绝消息
]==]
function SceneSystemServer:sendTeleportDenied(playerId, reason)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:CallClient(playerId, Protocol.ServerMSGID.SYSTEM_MESSAGE_NOTIFY, {
        message = "无法传送: " .. reason,
        messageType = "warning"
    })
end

--[==[
    获取传送门名称
]==]
function SceneSystemServer:getPortalName(portalId)
    local portalNames = {
        ["TeleportPortal_Forest"] = "森林战场",
        ["ExitPortal"] = "返回主城",
    }
    return portalNames[portalId] or portalId
end

--[==[
    处理返回主城请求 (UI按钮触发)
    @param userId number - 用户ID
    @param data table - 请求数据
    @return table - 响应数据
]==]
function SceneSystemServer:handleReturnToMainCity(userId, data)
    self.log:info(string.format("Player %s requested return to MainCity via UI button", tostring(userId)))

    -- 获取玩家当前场景 (使用currentScenes,不是playerScenes)
    local currentScene = self.data.currentScenes[userId]
    if not currentScene then
        self.log:warning("Player scene data not found, assuming in MainCity: " .. tostring(userId))
        -- 如果没有场景数据,默认认为在主城,不需要返回
        return {
            success = false,
            reason = "场景数据错误"
        }
    end

    -- 检查是否已经在主城
    if currentScene == 1 then
        self.log:info("Player already in MainCity, no need to return")
        return {
            success = false,
            reason = "已经在主城"
        }
    end

    -- TODO: 检查战斗状态 (目前先简化处理)
    -- local combatSystem = self.sgf.businessSystemManager:get("CombatSystemServer")
    -- if combatSystem and combatSystem:isPlayerInCombat(userId) then
    --     self.log:warning("Player in combat, cannot return")
    --     return {
    --         success = false,
    --         reason = "战斗中无法返回,请先结束战斗"
    --     }
    -- end

    -- 执行传送到主城
    local targetSceneId = 1  -- MainCity
    local targetPosition = self.config.MapConfig.SpawnPositions[targetSceneId]

    local success = self:teleportPlayer(userId, targetSceneId, targetPosition)

    if success then
        self.log:info(string.format("Player %s returned to MainCity successfully", tostring(userId)))
        return {
            success = true,
            sceneId = targetSceneId,
            position = {
                x = targetPosition.x,
                y = targetPosition.y,
                z = targetPosition.z
            }
        }
    else
        self.log:error("Failed to teleport player to MainCity")
        return {
            success = false,
            reason = "传送失败,请重试"
        }
    end
end

return SceneSystemServer
