--[[
    QuestSystemClient.lua - RPG Game Quest System (Client Side)
    任务系统客户端

    按照SGF标准化开发框架规范开发

    功能:
    - 接收和显示任务数据
    - 处理任务UI交互
    - 显示任务进度更新
    - 任务追踪和提示

    Version: 1.0.0
]]

local QuestSystemClient = {
    -- System metadata
    _systemName = "QuestSystemClient",
    _version = "1.0.0",
    _dependencies = {"EventBus", "Protocol"},

    -- System data
    data = {
        -- 当前任务数据
        availableQuests = {},       -- 可接任务
        activeQuests = {},          -- 进行中任务
        completedQuests = {},       -- 已完成任务

        -- 当前追踪的任务
        trackedQuest = nil,

        -- UI引用
        questPanel = nil,
        questTracker = nil,
    },

    -- Configuration
    config = {
        maxTrackedObjectives = 5,   -- 最大追踪目标数
        showQuestNotifications = true,
        notificationDuration = 3,   -- 通知显示时长（秒）
    },

    -- Internal state
    state = {
        initialized = false,
        questPanelOpen = false,
    },

    -- Service references
    services = {},
}

-- ============================================================================
-- Constructor
-- ============================================================================

function QuestSystemClient.new(sgf)
    local self = setmetatable({}, {__index = QuestSystemClient})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    return self
end

-- ============================================================================
-- SGF Framework Lifecycle Methods
-- ============================================================================

--[[
    PreInit - 预初始化阶段
]]
function QuestSystemClient:PreInit()
    print("[QuestSystemClient] PreInit - Initializing client quest system...")

    -- 获取核心服务引用
    self.services.localPlayer = game:GetService("Players").LocalPlayer

    -- 初始化数据
    self.data.availableQuests = {}
    self.data.activeQuests = {}
    self.data.completedQuests = {}

    print("[QuestSystemClient] PreInit complete")
end

--[[
    Init - 初始化阶段
]]
function QuestSystemClient:Init()
    print("[QuestSystemClient] Init - Setting up client quest system...")

    -- 获取Framework引用
    local mainStorage = game:GetService("MainStorage")
    local framework = mainStorage:FindFirstChild("Framework", true)

    if framework then
        -- 获取EventBus
        local eventBusModule = framework:FindFirstChild("EventBus", true)
        if eventBusModule then
            self.services.EventBus = require(eventBusModule)
            print("[QuestSystemClient] EventBus loaded")
        end

        -- 获取Protocol
        local protocolModule = framework:FindFirstChild("Protocol", true)
        if protocolModule then
            self.services.Protocol = require(protocolModule)
            print("[QuestSystemClient] Protocol loaded")
        end
    end

    -- 注册网络消息处理器
    self:registerMessageHandlers()

    -- 注册事件监听器
    self:registerEventListeners()

    print("[QuestSystemClient] Init complete")
end

--[[
    PostInit - 后初始化阶段
]]
function QuestSystemClient:PostInit()
    print("[QuestSystemClient] PostInit - Finalizing client quest system...")

    -- 查找UI元素
    self:findUIElements()

    self.state.initialized = true
    print("[QuestSystemClient] PostInit complete")
end

--[[
    Start - 启动阶段
]]
function QuestSystemClient:Start()
    print("[QuestSystemClient] Start - Client quest system active")

    -- 请求初始任务数据
    self:requestQuestList()
end

--[[
    Update - 更新循环
]]
function QuestSystemClient:Update(dt)
    if not self.state.initialized then return end

    -- 更新任务追踪UI
    self:updateQuestTracker(dt)
end

--[[
    Stop - 停止系统
]]
function QuestSystemClient:Stop()
    print("[QuestSystemClient] Stop - Shutting down client quest system...")

    -- 清理UI
    if self.data.questPanel then
        self.data.questPanel.Visible = false
    end

    self.state.initialized = false
    print("[QuestSystemClient] Stop complete")
end

-- ============================================================================
-- UI Management
-- ============================================================================

--[[
    查找UI元素
]]
function QuestSystemClient:findUIElements()
    local player = self.services.localPlayer
    if not player then return end

    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end

    -- 查找任务面板
    local questPanel = playerGui:FindFirstChild("QuestPanel", true)
    if questPanel then
        self.data.questPanel = questPanel
        print("[QuestSystemClient] QuestPanel UI found")
    end

    -- 查找任务追踪器
    local questTracker = playerGui:FindFirstChild("QuestTracker", true)
    if questTracker then
        self.data.questTracker = questTracker
        print("[QuestSystemClient] QuestTracker UI found")
    end
end

--[[
    更新任务追踪器UI
]]
function QuestSystemClient:updateQuestTracker(dt)
    if not self.data.questTracker then return end
    if not self.data.trackedQuest then
        self.data.questTracker.Visible = false
        return
    end

    self.data.questTracker.Visible = true

    -- TODO: 更新追踪器显示内容
    -- 显示任务名称、目标进度等
end

--[[
    显示任务通知
    @param message - 通知消息
    @param duration - 显示时长
]]
function QuestSystemClient:showQuestNotification(message, duration)
    if not self.config.showQuestNotifications then return end

    duration = duration or self.config.notificationDuration

    print("[QuestSystemClient] Quest Notification: " .. message)

    -- TODO: 显示UI通知
    -- 可以使用UITextLabel + 淡入淡出动画
end

--[[
    打开任务面板
]]
function QuestSystemClient:openQuestPanel()
    if not self.data.questPanel then
        print("[QuestSystemClient] Quest panel not found")
        return
    end

    self.data.questPanel.Visible = true
    self.state.questPanelOpen = true

    -- 刷新任务列表显示
    self:refreshQuestPanelDisplay()

    print("[QuestSystemClient] Quest panel opened")
end

--[[
    关闭任务面板
]]
function QuestSystemClient:closeQuestPanel()
    if not self.data.questPanel then return end

    self.data.questPanel.Visible = false
    self.state.questPanelOpen = false

    print("[QuestSystemClient] Quest panel closed")
end

--[[
    刷新任务面板显示
]]
function QuestSystemClient:refreshQuestPanelDisplay()
    if not self.data.questPanel then return end

    -- TODO: 更新任务列表UI
    -- 显示可接任务、进行中任务、已完成任务
end

-- ============================================================================
-- Network Message Handlers
-- ============================================================================

--[[
    注册网络消息处理器
]]
function QuestSystemClient:registerMessageHandlers()
    if not self.services.Protocol then return end

    local Protocol = self.services.Protocol

    -- TODO: 注册服务端消息处理
    -- 实际注册方式取决于网络框架

    print("[QuestSystemClient] Message handlers registered:")
    print("  - QUEST_ACCEPT_RSP (500)")
    print("  - QUEST_SUBMIT_RSP (501)")
    print("  - QUEST_ABANDON_RSP (502)")
    print("  - QUEST_GET_LIST_RSP (503)")
    print("  - QUEST_PROGRESS_NOTIFY (510)")
    print("  - QUEST_COMPLETE_NOTIFY (511)")
end

--[[
    处理任务接受响应
    @param data - { questId, success, quest }
]]
function QuestSystemClient:handleQuestAcceptResponse(data)
    if not data then return end

    if data.success then
        print("[QuestSystemClient] Quest accepted: " .. data.questId)

        -- 添加到活动任务列表
        if data.quest then
            self.data.activeQuests[data.questId] = data.quest
        end

        -- 从可接任务中移除
        self.data.availableQuests[data.questId] = nil

        -- 显示通知
        self:showQuestNotification("已接受任务: " .. (data.quest and data.quest.name or data.questId))

        -- 触发本地事件
        if self.services.EventBus then
            self.services.EventBus:emit("QuestAcceptedClient", data)
        end

        -- 刷新UI
        self:refreshQuestPanelDisplay()
    else
        print("[QuestSystemClient] Quest accept failed: " .. (data.error or "Unknown error"))
        self:showQuestNotification("接受任务失败: " .. (data.error or ""))
    end
end

--[[
    处理任务提交响应
    @param data - { questId, success, rewards }
]]
function QuestSystemClient:handleQuestSubmitResponse(data)
    if not data then return end

    if data.success then
        print("[QuestSystemClient] Quest completed: " .. data.questId)

        -- 移动到已完成列表
        local quest = self.data.activeQuests[data.questId]
        if quest then
            self.data.completedQuests[data.questId] = quest
            self.data.activeQuests[data.questId] = nil
        end

        -- 显示完成通知和奖励
        local rewardText = self:formatRewards(data.rewards)
        self:showQuestNotification("任务完成! 获得: " .. rewardText, 5)

        -- 播放完成音效
        -- TODO: 播放音效

        -- 触发本地事件
        if self.services.EventBus then
            self.services.EventBus:emit("QuestCompletedClient", data)
        end

        -- 刷新UI
        self:refreshQuestPanelDisplay()
    else
        print("[QuestSystemClient] Quest submit failed: " .. (data.error or "Unknown error"))
        self:showQuestNotification("提交任务失败: " .. (data.error or ""))
    end
end

--[[
    处理任务放弃响应
    @param data - { questId, success }
]]
function QuestSystemClient:handleQuestAbandonResponse(data)
    if not data then return end

    if data.success then
        print("[QuestSystemClient] Quest abandoned: " .. data.questId)

        -- 从活动任务中移除
        self.data.activeQuests[data.questId] = nil

        -- 显示通知
        self:showQuestNotification("已放弃任务")

        -- 触发本地事件
        if self.services.EventBus then
            self.services.EventBus:emit("QuestAbandonedClient", data)
        end

        -- 刷新UI
        self:refreshQuestPanelDisplay()
    else
        print("[QuestSystemClient] Quest abandon failed: " .. (data.error or "Unknown error"))
    end
end

--[[
    处理任务列表响应
    @param data - { available, active, completed }
]]
function QuestSystemClient:handleQuestListResponse(data)
    if not data then return end

    print("[QuestSystemClient] Received quest list")

    -- 更新本地数据
    if data.available then
        self.data.availableQuests = data.available
    end

    if data.active then
        self.data.activeQuests = data.active
    end

    if data.completed then
        self.data.completedQuests = data.completed
    end

    -- 刷新UI
    self:refreshQuestPanelDisplay()
end

--[[
    处理任务进度通知
    @param data - { questId, progress }
]]
function QuestSystemClient:handleQuestProgressNotify(data)
    if not data or not data.questId then return end

    print("[QuestSystemClient] Quest progress updated: " .. data.questId)

    -- 更新任务进度
    local quest = self.data.activeQuests[data.questId]
    if quest and data.progress then
        quest.progress = data.progress

        -- 检查是否有目标完成
        if data.objectiveCompleted then
            self:showQuestNotification("目标完成: " .. data.objectiveCompleted)
        end
    end

    -- 刷新追踪器
    if self.data.trackedQuest == data.questId then
        self:updateQuestTracker(0)
    end

    -- 刷新任务面板
    if self.state.questPanelOpen then
        self:refreshQuestPanelDisplay()
    end
end

--[[
    处理任务完成通知
    @param data - { questId }
]]
function QuestSystemClient:handleQuestCompleteNotify(data)
    if not data or not data.questId then return end

    print("[QuestSystemClient] Quest can be submitted: " .. data.questId)

    -- 显示可提交通知
    self:showQuestNotification("任务可以提交了!")

    -- 高亮显示任务（如果UI支持）
    -- TODO: 高亮任务项
end

-- ============================================================================
-- Event Listeners
-- ============================================================================

--[[
    注册事件监听器
]]
function QuestSystemClient:registerEventListeners()
    if not self.services.EventBus then return end

    local EventBus = self.services.EventBus

    -- 监听UI按钮事件
    EventBus:on("OpenQuestPanel", function()
        self:openQuestPanel()
    end)

    EventBus:on("CloseQuestPanel", function()
        self:closeQuestPanel()
    end)

    EventBus:on("AcceptQuest", function(questId)
        self:requestAcceptQuest(questId)
    end)

    EventBus:on("SubmitQuest", function(questId)
        self:requestSubmitQuest(questId)
    end)

    EventBus:on("AbandonQuest", function(questId)
        self:requestAbandonQuest(questId)
    end)

    EventBus:on("TrackQuest", function(questId)
        self:trackQuest(questId)
    end)

    print("[QuestSystemClient] Event listeners registered")
end

-- ============================================================================
-- Network Requests
-- ============================================================================

--[[
    请求任务列表
]]
function QuestSystemClient:requestQuestList()
    print("[QuestSystemClient] Requesting quest list...")

    -- TODO: 发送网络请求
    -- 使用Protocol.ClientMSGID.QUEST_GET_LIST_REQ
end

--[[
    请求接受任务
    @param questId - 任务ID
]]
function QuestSystemClient:requestAcceptQuest(questId)
    print("[QuestSystemClient] Requesting to accept quest: " .. questId)

    -- TODO: 发送网络请求
    -- 使用Protocol.ClientMSGID.QUEST_ACCEPT_REQ
end

--[[
    请求提交任务
    @param questId - 任务ID
]]
function QuestSystemClient:requestSubmitQuest(questId)
    print("[QuestSystemClient] Requesting to submit quest: " .. questId)

    -- TODO: 发送网络请求
    -- 使用Protocol.ClientMSGID.QUEST_SUBMIT_REQ
end

--[[
    请求放弃任务
    @param questId - 任务ID
]]
function QuestSystemClient:requestAbandonQuest(questId)
    print("[QuestSystemClient] Requesting to abandon quest: " .. questId)

    -- TODO: 发送网络请求
    -- 使用Protocol.ClientMSGID.QUEST_ABANDON_REQ
end

-- ============================================================================
-- Quest Tracking
-- ============================================================================

--[[
    追踪任务
    @param questId - 任务ID
]]
function QuestSystemClient:trackQuest(questId)
    if not self.data.activeQuests[questId] then
        print("[QuestSystemClient] Cannot track quest - not active: " .. questId)
        return
    end

    self.data.trackedQuest = questId
    print("[QuestSystemClient] Now tracking quest: " .. questId)

    -- 更新追踪器UI
    self:updateQuestTracker(0)
end

--[[
    取消追踪任务
]]
function QuestSystemClient:untrackQuest()
    self.data.trackedQuest = nil
    if self.data.questTracker then
        self.data.questTracker.Visible = false
    end
end

-- ============================================================================
-- Public API
-- ============================================================================

--[[
    获取活动任务数量
    @return number - 活动任务数
]]
function QuestSystemClient:getActiveQuestCount()
    local count = 0
    for _ in pairs(self.data.activeQuests) do
        count = count + 1
    end
    return count
end

--[[
    检查任务是否已接受
    @param questId - 任务ID
    @return boolean
]]
function QuestSystemClient:isQuestActive(questId)
    return self.data.activeQuests[questId] ~= nil
end

--[[
    检查任务是否已完成
    @param questId - 任务ID
    @return boolean
]]
function QuestSystemClient:isQuestCompleted(questId)
    return self.data.completedQuests[questId] ~= nil
end

--[[
    获取任务进度
    @param questId - 任务ID
    @return table - 任务进度数据
]]
function QuestSystemClient:getQuestProgress(questId)
    local quest = self.data.activeQuests[questId]
    if quest and quest.progress then
        return quest.progress
    end
    return nil
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

--[[
    格式化奖励文本
    @param rewards - 奖励数据
    @return string - 格式化的奖励文本
]]
function QuestSystemClient:formatRewards(rewards)
    if not rewards then return "" end

    local parts = {}

    if rewards.exp and rewards.exp > 0 then
        table.insert(parts, rewards.exp .. "经验")
    end

    if rewards.gold and rewards.gold > 0 then
        table.insert(parts, rewards.gold .. "金币")
    end

    if rewards.items then
        for _, item in ipairs(rewards.items) do
            table.insert(parts, item.name or item.itemId)
        end
    end

    return table.concat(parts, ", ")
end

-- 导出模块
return QuestSystemClient
