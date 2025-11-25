--[[
    NPCInteractionSystemServer.lua - NPC交互系统（服务端）

    职责：
    1. 管理NPC对话
    2. 处理NPC交互请求
    3. 提供任务和商店接口
    4. NPC状态管理

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local NPCInteractionSystemServer = {
    name = "NPCInteractionSystemServer",
    version = "1.0.0",
    description = "NPC交互系统（服务端）",
    dependencies = {"PlayerSystemServer", "SceneSystemServer"},
    state = "uninitialized",
    sgf = nil,
    log = nil,
    events = nil,
    config = {},
    data = {
        npcDialogues = {},       -- [npcName] = {dialogues}
        npcInteractions = {},    -- [playerId] = {npcName, interactionType}
    },
    dependencies_cache = {},
}

function NPCInteractionSystemServer.new(sgf)
    local self = setmetatable({}, {__index = NPCInteractionSystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    self.data = {
        npcDialogues = {},
        npcInteractions = {},
        npcRegistry = {},        -- NPC注册表 (从 WorkSpace 迁移)
        playersNearNPC = {},     -- [playerId] = {npcId, distance}
    }
    self.config.interactionRange = 300  -- 交互范围(厘米)
    self.dependencies_cache = {}
    return self
end

function NPCInteractionSystemServer:PreInit()
    self.log:info("NPCInteractionSystemServer PreInit...")
    self:registerEventListeners()
    return true
end

function NPCInteractionSystemServer:Init()
    if self.state ~= "uninitialized" then
        return false
    end
    self.log:info("NPCInteractionSystemServer Init...")

    -- 加载NPC对话配置
    self:loadNPCDialogues()

    self:registerNetworkHandlers()
    self.state = "initialized"
    return true
end

function NPCInteractionSystemServer:PostInit()
    self.log:info("NPCInteractionSystemServer PostInit...")
    self:resolveDependencies()
    return true
end

function NPCInteractionSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("NPCInteractionSystemServer Start...")
    self.state = "started"
    return true
end

function NPCInteractionSystemServer:Update(dt)
    -- NPC交互系统更新
end

function NPCInteractionSystemServer:Stop()
    self.log:info("NPCInteractionSystemServer Stop...")

    -- 停止并清理附近玩家检测定时器
    if self.nearbyPlayerDetectionTimer then
        self.nearbyPlayerDetectionTimer:Stop()
        self.nearbyPlayerDetectionTimer:Destroy()
        self.nearbyPlayerDetectionTimer = nil
        self.log:debug("[NPC] Nearby player detection timer stopped and destroyed")
    end

    self.state = "stopped"
    return true
end

function NPCInteractionSystemServer:registerEventListeners()
    -- 监听来自 WorkSpace 的NPC初始化事件
    self.events:on("NPC:Initialized", function(data)
        self:registerNPC(data)
    end)

    self.log:debug("NPCInteractionSystemServer event listeners registered")
end

function NPCInteractionSystemServer:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
        self.dependencies_cache.SceneSystem = self.sgf.businessSystemManager:get("SceneSystemServer")
        self.dependencies_cache.QuestSystem = self.sgf.businessSystemManager:get("QuestSystemServer")
        self.dependencies_cache.ShopSystem = self.sgf.businessSystemManager:get("ShopSystemServer")
    end

    -- 如果BusinessSystemManager不可用，尝试直接require
    if not self.dependencies_cache.QuestSystem then
        local framework = game:GetService("MainStorage"):FindFirstChild("Framework", true)
        if framework then
            local questSystemModule = framework:FindFirstChild("QuestSystemServer", true)
            if questSystemModule then
                self.dependencies_cache.QuestSystem = require(questSystemModule)
                self.log:info("QuestSystemServer loaded via require")
            end

            local shopSystemModule = framework:FindFirstChild("ShopSystemServer", true)
            if shopSystemModule then
                self.dependencies_cache.ShopSystem = require(shopSystemModule)
                self.log:info("ShopSystemServer loaded via require")
            end
        end
    end
end

function NPCInteractionSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    if not NetworkHelper then
        self.log:error("NetworkHelper not found")
        return
    end

    -- NPC交互请求
    self:OnRequest(Protocol.ClientMSGID.NPC_INTERACT_REQ, function(userId, msgid, data)
        return self:handleNPCInteract(player, data)
    end)

    -- 对话选项选择
    self:OnRequest(Protocol.ClientMSGID.NPC_DIALOGUE_CHOICE_REQ, function(userId, msgid, data)
        return self:handleDialogueChoice(player, data)
    end)

    self.log:debug("NPCInteractionSystemServer network handlers registered")
end

--[==[
    加载NPC对话配置
]==]
function NPCInteractionSystemServer:loadNPCDialogues()
    -- 任务NPC对话
    self.data.npcDialogues["QuestNPC"] = {
        greeting = {
            text = "欢迎来到主城，勇敢的冒险者！我这里有一些任务需要你的帮助。",
            options = {
                {id = 1, text = "查看可用任务", action = "show_quests"},
                {id = 2, text = "提交完成的任务", action = "submit_quests"},
                {id = 3, text = "告诉我这个世界的情况", action = "world_info"},
                {id = 4, text = "再见", action = "close"},
            }
        },
        world_info = {
            text = "这片土地曾经和平繁荣，但最近魔物开始侵占周边区域。森林、洞穴甚至远处的魔塔都被它们占领了。我们需要你的力量来清除这些威胁！",
            options = {
                {id = 1, text = "我准备好了", action = "show_quests"},
                {id = 2, text = "返回", action = "greeting"},
            }
        },
    }

    -- 商店NPC对话
    self.data.npcDialogues["ShopNPC"] = {
        greeting = {
            text = "欢迎光临我的商店！这里有最好的武器和防具，还有各种实用的道具。",
            options = {
                {id = 1, text = "我想购买装备", action = "show_equipment"},
                {id = 2, text = "我想购买道具", action = "show_items"},
                {id = 3, text = "我想出售物品", action = "sell_items"},
                {id = 4, text = "查看今日特惠", action = "daily_deals"},
                {id = 5, text = "再见", action = "close"},
            }
        },
        daily_deals = {
            text = "今天的特惠商品：生命药水8折，魔法药水8折，限时优惠！",
            options = {
                {id = 1, text = "查看商品", action = "show_items"},
                {id = 2, text = "返回", action = "greeting"},
            }
        },
    }

    self.log:info("NPC dialogues loaded")
end

--[==[
    处理NPC交互请求
]==]
function NPCInteractionSystemServer:handleNPCInteract(player, data)
    local playerId = player.UserId
    local npcName = data.npcName

    self.log:info("Player " .. playerId .. " interacting with " .. npcName)

    -- 获取NPC对话
    local dialogues = self.data.npcDialogues[npcName]
    if not dialogues then
        return {success = false, reason = "NPC not found"}
    end

    -- 记录交互状态
    self.data.npcInteractions[playerId] = {
        npcName = npcName,
        currentDialogue = "greeting",
    }

    -- 获取初始对话
    local greeting = dialogues.greeting

    -- 发送对话数据
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    return {
        success = true,
        npcName = npcName,
        dialogue = greeting,
    }
end

--[==[
    处理对话选项选择
]==]
function NPCInteractionSystemServer:handleDialogueChoice(player, data)
    local playerId = player.UserId
    local choiceId = data.choiceId
    local action = data.action

    self.log:info("Player " .. playerId .. " chose dialogue option: " .. action)

    -- 获取交互状态
    local interaction = self.data.npcInteractions[playerId]
    if not interaction then
        return {success = false, reason = "No active interaction"}
    end

    local npcName = interaction.npcName
    local dialogues = self.data.npcDialogues[npcName]

    -- 处理不同的动作
    if action == "close" then
        -- 关闭对话
        self.data.npcInteractions[playerId] = nil
        return {success = true, action = "close"}

    elseif action == "show_quests" then
        -- 显示任务列表
        return self:showQuests(player)

    elseif action == "submit_quests" then
        -- 提交任务
        return self:submitQuests(player)

    elseif action == "show_equipment" then
        -- 显示装备商店
        return self:showShop(player, "equipment")

    elseif action == "show_items" then
        -- 显示道具商店
        return self:showShop(player, "items")

    elseif action == "sell_items" then
        -- 打开出售界面
        return self:openSellInterface(player)

    else
        -- 切换到其他对话
        if dialogues[action] then
            interaction.currentDialogue = action
            return {
                success = true,
                action = "continue_dialogue",
                dialogue = dialogues[action],
            }
        else
            return {success = false, reason = "Unknown action"}
        end
    end
end

--[==[
    显示任务列表
]==]
function NPCInteractionSystemServer:showQuests(player)
    -- 调用QuestSystem获取任务列表
    local questSystem = self.dependencies_cache.QuestSystem
    if questSystem and questSystem.getAvailableQuests then
        local availableQuests = questSystem:getAvailableQuests(player)
        local inProgressQuests = questSystem:getInProgressQuests(player)

        return {
            success = true,
            action = "show_quests",
            availableQuests = availableQuests,
            inProgressQuests = inProgressQuests,
        }
    end

    -- 如果QuestSystem不可用，返回空列表
    self.log:warning("QuestSystem not available, returning empty quest list")

    local quests = {
        {
            id = 1,
            name = "清除森林威胁",
            description = "前往森林战场，击败10只史莱姆",
            progress = "0/10",
            reward = {exp = 100, gold = 50},
            status = "available",
        },
        {
            id = 2,
            name = "收集草药",
            description = "在森林中收集5份治疗草药",
            progress = "0/5",
            reward = {exp = 80, gold = 30, items = {"生命药水x3"}},
            status = "available",
        },
    }

    return {
        success = true,
        action = "show_quests",
        quests = quests,
    }
end

--[==[
    提交任务
]==]
function NPCInteractionSystemServer:submitQuests(player)
    -- 这里应该调用QuestSystem处理任务提交
    return {
        success = true,
        action = "submit_quests",
        message = "你目前没有可以提交的任务",
    }
end

--[==[
    显示商店
]==]
function NPCInteractionSystemServer:showShop(player, category)
    -- 这里应该调用ShopSystem获取商品列表
    local items = {}

    if category == "equipment" then
        items = {
            {id = 1, name = "新手之剑", price = 100, description = "攻击力+5"},
            {id = 2, name = "皮质护甲", price = 80, description = "防御力+3"},
            {id = 3, name = "敏捷之靴", price = 60, description = "速度+2"},
        }
    elseif category == "items" then
        items = {
            {id = 101, name = "生命药水", price = 20, description = "恢复50点生命值"},
            {id = 102, name = "魔法药水", price = 25, description = "恢复30点魔法值"},
            {id = 103, name = "解毒剂", price = 15, description = "解除中毒状态"},
        }
    end

    return {
        success = true,
        action = "show_shop",
        category = category,
        items = items,
    }
end

--[==[
    打开出售界面
]==]
function NPCInteractionSystemServer:openSellInterface(player)
    return {
        success = true,
        action = "open_sell",
        message = "选择你要出售的物品",
    }
end

--[==[
    获取NPC位置
]==]
function NPCInteractionSystemServer:getNPCPosition(npcName)
    local MapConfig = require(script.Parent.Parent.Parent.Config.Framework.MapConfig)
    local npcPositions = MapConfig.NPCPositions[MapConfig.ScenesTypeID.MainCity]

    if npcPositions and npcPositions[npcName] then
        return npcPositions[npcName].pos
    end

    return nil
end

-- ========================================
-- NPC注册和范围检测逻辑（从 WorkSpace 迁移）
-- ========================================

--[==[
    注册NPC到系统
    @param data table - {npcId, npcType, npcName, npcNode, metadata}
]==]
function NPCInteractionSystemServer:registerNPC(data)
    self.data.npcRegistry[data.npcId] = {
        npcId = data.npcId,
        npcType = data.npcType,
        npcName = data.npcName,
        npcNode = data.npcNode,
        metadata = data.metadata or {},
        position = data.npcNode.Position,
    }

    self.log:info(string.format("[NPC] Registered: %s (Type: %s, Name: %s)",
        data.npcId, data.npcType, data.npcName))

    -- 如果这是第一个NPC，启动范围检测定时器
    local npcCount = 0
    for _ in pairs(self.data.npcRegistry) do
        npcCount = npcCount + 1
    end

    if npcCount == 1 then
        self:startNearbyPlayerDetection()
    end
end

--[==[
    启动附近玩家检测（统一的定时器，检测所有NPC）
]==]
function NPCInteractionSystemServer:startNearbyPlayerDetection()
    self.log:info("[NPC] Starting nearby player detection timer")

    -- 全局只有一个定时器，检测所有 NPC
    -- 使用 SandboxNode.new("Timer") 创建定时器
    local timer = SandboxNode.new("Timer")
    timer.Interval = 0.5  -- 每0.5秒检测一次
    timer.Loop = true     -- 循环执行
    timer.Callback = function()
        self:updatePlayersNearNPCs()
    end
    timer:Start()

    -- 存储定时器引用以便后续清理
    self.nearbyPlayerDetectionTimer = timer

    self.log:info("[NPC] Nearby player detection timer started (interval: 0.5s)")
end

--[==[
    更新玩家附近的NPC
]==]
function NPCInteractionSystemServer:updatePlayersNearNPCs()
    local Players = game:GetService("Players")
    local allPlayers = Players:GetPlayers()

    for _, player in ipairs(allPlayers) do
        local playerId = player.UserId
        local playerPos = player.Position

        -- 找到玩家附近最近的 NPC
        local nearestNPC, minDistance = self:findNearestNPC(playerPos)

        if nearestNPC and minDistance <= self.config.interactionRange then
            -- 玩家进入 NPC 范围
            if not self.data.playersNearNPC[playerId] or
               self.data.playersNearNPC[playerId].npcId ~= nearestNPC.npcId then
                self:onPlayerEnterNPCRange(playerId, nearestNPC)
            end
        else
            -- 玩家离开 NPC 范围
            if self.data.playersNearNPC[playerId] then
                self:onPlayerLeaveNPCRange(playerId)
            end
        end
    end
end

--[==[
    找到离玩家最近的NPC
]==]
function NPCInteractionSystemServer:findNearestNPC(playerPos)
    local nearestNPC = nil
    local minDistance = math.huge

    for _, npc in pairs(self.data.npcRegistry) do
        local distance = Vector3.Distance(playerPos, npc.position)
        if distance < minDistance then
            minDistance = distance
            nearestNPC = npc
        end
    end

    return nearestNPC, minDistance
end

--[==[
    玩家进入NPC范围
]==]
function NPCInteractionSystemServer:onPlayerEnterNPCRange(playerId, npc)
    self.data.playersNearNPC[playerId] = {
        npcId = npc.npcId,
        npcType = npc.npcType,
    }

    -- 发送交互提示到客户端
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:CallClient(
        playerId,
        Protocol.ServerMSGID.NPC_INTERACTION_HINT_NOTIFY,
        {
            npcId = npc.npcId,
            npcName = npc.npcName,
            show = true,
            hint = "按E键与" .. npc.npcName .. "对话",
        }
    )
end

--[==[
    玩家离开NPC范围
]==]
function NPCInteractionSystemServer:onPlayerLeaveNPCRange(playerId)
    local nearbyNPC = self.data.playersNearNPC[playerId]
    if not nearbyNPC then return end

    -- 发送隐藏提示到客户端
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:CallClient(
        playerId,
        Protocol.ServerMSGID.NPC_INTERACTION_HINT_NOTIFY,
        {
            npcId = nearbyNPC.npcId,
            show = false,
        }
    )

    self.data.playersNearNPC[playerId] = nil
end

--[==[
    处理NPC交互（从网络消息调用）
    @param playerId string - 玩家ID
    @param npcId string - NPC ID
]==]
function NPCInteractionSystemServer:handleNPCInteractionRequest(playerId, npcId)
    local npc = self.data.npcRegistry[npcId]
    if not npc then
        self.log:error(string.format("[NPC] NPC not found: %s", npcId))
        return
    end

    -- 检查距离（获取玩家对象）
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(playerId)
    if not player then
        self.log:warning("Player not found for NPC interaction: " .. tostring(playerId))
        return
    end

    local distance = Vector3.Distance(player.Position, npc.position)
    if distance > self.config.interactionRange then
        -- 距离过远
        local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
        self:CallClient(
            playerId,
            Protocol.ServerMSGID.SYSTEM_MESSAGE_NOTIFY,
            {
                message = "距离太远，无法与NPC对话",
                messageType = "warning"
            }
        )
        return
    end

    self.log:info(string.format("[NPC] Player %s interacting with NPC %s (Type: %s)",
        playerId, npcId, npc.npcType))

    -- 根据 NPC 类型分发到对应的 System
    if npc.npcType == "shop" then
        local shopSystem = self.dependencies_cache.ShopSystem
        if shopSystem then
            shopSystem:openShop(playerId, npc.metadata.shopId)
        else
            self.log:error("[NPC] ShopSystem not found")
        end

    elseif npc.npcType == "quest" then
        local questSystem = self.dependencies_cache.QuestSystem
        if questSystem then
            questSystem:showQuestDialog(playerId, npc.npcId)
        else
            self.log:error("[NPC] QuestSystem not found")
        end

    else
        self.log:warning(string.format("[NPC] Unknown NPC type: %s", npc.npcType))
    end

    -- 发送事件供其他系统监听
    self.events:emit("NPC:Interacted", {
        playerId = playerId,
        npcId = npcId,
        npcType = npc.npcType,
    })
end

return NPCInteractionSystemServer
