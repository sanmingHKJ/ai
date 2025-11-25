--[[
    SkillSystemClient.lua - 技能系统（客户端）

    职责：
    1. 缓存技能数据（从服务端同步）
    2. 发送技能学习/升级请求
    3. 发送技能释放请求
    4. 管理快捷栏
    5. 更新UI显示

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local SkillSystemClient = {
    -- ========== 基础信息 ==========
    name = "SkillSystemClient",
    version = "1.0.0",
    description = "技能系统（客户端）",

    -- ========== 依赖声明 ==========
    dependencies = {
        "PlayerSystemClient",
    },

    -- ========== 状态管理 ==========
    state = "uninitialized",

    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,

    -- ========== 配置 ==========
    config = {},

    -- ========== 数据 ==========
    data = {
        learnedSkills = {},   -- 本地玩家已学习的技能
        shortcuts = {},       -- 快捷栏
        cooldowns = {},       -- 冷却状态（本地缓存）
        skillTemplates = {},  -- 技能模板（客户端也需要显示信息）
    },

    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

function SkillSystemClient.new(sgf)
    local self = setmetatable({}, {__index = SkillSystemClient})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.data = {
        learnedSkills = {},
        shortcuts = {},
        cooldowns = {},
        skillTemplates = {},
    }
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function SkillSystemClient:PreInit()
    self.log:info("SkillSystemClient PreInit...")

    -- 注册事件监听器
    self:registerEventListeners()

    return true
end

function SkillSystemClient:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("SkillSystemClient already initialized")
        return false
    end

    self.log:info("SkillSystemClient Init...")

    -- 加载配置
    self:loadConfig()

    -- 加载技能模板（客户端也需要显示技能信息）
    self:loadSkillTemplates()

    -- 注册网络消息处理
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function SkillSystemClient:PostInit()
    self.log:info("SkillSystemClient PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    return true
end

function SkillSystemClient:Start()
    if self.state ~= "initialized" then
        self.log:error("SkillSystemClient cannot start, state: " .. self.state)
        return false
    end

    self.log:info("SkillSystemClient Start...")

    -- 请求服务端同步技能数据
    self:requestSkillList()

    self.state = "started"
    self.events:emit("SkillSystemStarted", {timestamp = os.time()})

    return true
end

function SkillSystemClient:Update(dt)
    if self.state ~= "started" then
        return
    end

    -- 更新本地冷却倒计时
    self:updateLocalCooldowns(dt)
end

function SkillSystemClient:Stop()
    self.log:info("SkillSystemClient Stop...")

    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function SkillSystemClient:loadConfig()
    self.log:debug("SkillSystemClient config loaded")
end

function SkillSystemClient:resolveDependencies()
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemClient")
        if self.dependencies_cache.PlayerSystem then
            self.log:debug("SkillSystemClient resolved dependency: PlayerSystemClient")
        else
            self.log:warning("SkillSystemClient dependency not found: PlayerSystemClient")
        end
    end
end

function SkillSystemClient:loadSkillTemplates()
    -- 加载技能模板（客户端需要显示技能图标、描述等）
    -- 这里应该和服务端保持一致，或者从服务端同步
    self.data.skillTemplates = {
        [1001] = {
            skillId = 1001,
            name = "火球术",
            description = "发射一颗火球，对单个敌人造成魔法伤害",
            iconPath = "icons/fireball.png",
        },
        [1002] = {
            skillId = 1002,
            name = "重击",
            description = "对敌人造成物理伤害并降低其防御",
            iconPath = "icons/heavy_strike.png",
        },
        [1003] = {
            skillId = 1003,
            name = "治疗术",
            description = "恢复自己或队友的生命值",
            iconPath = "icons/heal.png",
        },
    }
end

-- ========================================
-- 事件监听
-- ========================================

function SkillSystemClient:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听技能学习成功
    self.events:on(EventID.SkillLearned, function(data)
        self:onSkillLearned(data)
    end)

    -- 监听技能升级成功
    self.events:on(EventID.SkillUpgraded, function(data)
        self:onSkillUpgraded(data)
    end)

    -- 监听技能冷却开始
    self.events:on(EventID.SkillCooldownStarted, function(data)
        self:onSkillCooldownStarted(data)
    end)

    -- 监听技能冷却结束
    self.events:on(EventID.SkillCooldownEnded, function(data)
        self:onSkillCooldownEnded(data)
    end)

    self.log:debug("SkillSystemClient event listeners registered")
end

function SkillSystemClient:onSkillLearned(data)
    self.log:info("Skill learned: " .. data.skillId)
    -- UI会自动更新
end

function SkillSystemClient:onSkillUpgraded(data)
    self.log:info("Skill upgraded: " .. data.skillId .. " to level " .. data.newLevel)
    -- UI会自动更新
end

function SkillSystemClient:onSkillCooldownStarted(data)
    self.log:debug("Skill cooldown started: " .. data.skillId)
    -- 更新UI显示冷却
end

function SkillSystemClient:onSkillCooldownEnded(data)
    self.log:debug("Skill cooldown ended: " .. data.skillId)
    -- 更新UI显示技能可用
end

-- ========================================
-- 网络消息处理
-- ========================================

function SkillSystemClient:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- 注册服务端响应处理器
    self:OnResponse(Protocol.ServerMSGID.SKILL_LEARN_RSP, function(msgid, data)
        self:onLearnSkillResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.SKILL_UPGRADE_RSP, function(msgid, data)
        self:onUpgradeSkillResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.SKILL_SET_SHORTCUT_RSP, function(msgid, data)
        self:onSetShortcutResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.SKILL_GET_LIST_RSP, function(msgid, data)
        self:onGetSkillListResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.SKILL_LEARNED_NOTIFY, function(msgid, data)
        self:onSkillLearnedNotify(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.SKILL_COOLDOWN_NOTIFY, function(msgid, data)
        self:onSkillCooldownNotify(data)
    end)

    self.log:debug("SkillSystemClient network handlers registered")
end

-- ========================================
-- 客户端请求发送
-- ========================================

function SkillSystemClient:requestLearnSkill(skillId)
    self.log:debug("Requesting to learn skill: " .. skillId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.SKILL_LEARN_REQ, {
        skillId = skillId,
    })
end

function SkillSystemClient:requestUpgradeSkill(skillId)
    self.log:debug("Requesting to upgrade skill: " .. skillId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.SKILL_UPGRADE_REQ, {
        skillId = skillId,
    })
end

function SkillSystemClient:requestSetShortcut(slotIndex, skillId)
    self.log:debug(string.format("Requesting to set shortcut %d to skill %s", slotIndex, tostring(skillId)))

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.SKILL_SET_SHORTCUT_REQ, {
        slotIndex = slotIndex,
        skillId = skillId,
    })
end

function SkillSystemClient:requestSkillList()
    self.log:debug("Requesting skill list from server")

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.SKILL_GET_LIST_REQ, {})
end

function SkillSystemClient:requestCastSkill(skillId, targetId, targetPos)
    self.log:debug(string.format("Requesting to cast skill %d", skillId))

    -- 通过战斗系统发送技能释放请求
    self.events:emit("CastSkillRequest", {
        skillId = skillId,
        targetId = targetId,
        targetPos = targetPos,
        timestamp = os.time()
    })
end

-- ========================================
-- 服务端响应处理
-- ========================================

function SkillSystemClient:onLearnSkillResponse(data)
    if data.success then
        self.log:info("Successfully learned skill: " .. data.skillId)

        -- 请求更新技能列表
        self:requestSkillList()

        -- 显示成功提示
        self.events:emit("ShowMessage", {
            message = "学习技能成功！",
            type = "success"
        })
    else
        self.log:warning("Failed to learn skill: " .. (data.reason or "Unknown"))

        -- 显示失败提示
        self.events:emit("ShowMessage", {
            message = data.reason or "学习技能失败",
            type = "error"
        })
    end
end

function SkillSystemClient:onUpgradeSkillResponse(data)
    if data.success then
        self.log:info("Successfully upgraded skill: " .. data.skillId)

        -- 请求更新技能列表
        self:requestSkillList()

        -- 显示成功提示
        self.events:emit("ShowMessage", {
            message = "升级技能成功！",
            type = "success"
        })
    else
        self.log:warning("Failed to upgrade skill: " .. (data.reason or "Unknown"))

        -- 显示失败提示
        self.events:emit("ShowMessage", {
            message = data.reason or "升级技能失败",
            type = "error"
        })
    end
end

function SkillSystemClient:onSetShortcutResponse(data)
    if data.success then
        self.log:debug(string.format("Successfully set shortcut %d to skill %s",
            data.slotIndex, tostring(data.skillId)))

        -- 更新本地快捷栏
        self.data.shortcuts[data.slotIndex] = data.skillId

        -- 通知UI更新
        self.events:emit("SkillShortcutChanged", {
            slotIndex = data.slotIndex,
            skillId = data.skillId,
            timestamp = os.time()
        })
    else
        self.log:warning("Failed to set shortcut: " .. (data.reason or "Unknown"))
    end
end

function SkillSystemClient:onGetSkillListResponse(data)
    if data.success then
        self.log:info("Received skill list from server")

        -- 更新本地数据
        self.data.learnedSkills = data.learnedSkills or {}
        self.data.shortcuts = data.shortcuts or {}
        self.data.cooldowns = data.cooldowns or {}

        -- 通知UI更新
        self.events:emit("SkillListUpdated", {
            learnedSkills = self.data.learnedSkills,
            shortcuts = self.data.shortcuts,
            cooldowns = self.data.cooldowns,
            timestamp = os.time()
        })
    end
end

function SkillSystemClient:onSkillLearnedNotify(data)
    self.log:info("Skill learned notification: " .. data.skillId)

    -- 请求更新技能列表
    self:requestSkillList()
end

function SkillSystemClient:onSkillCooldownNotify(data)
    self.log:debug("Skill cooldown notification: " .. data.skillId)

    -- 更新本地冷却数据
    if data.duration and data.duration > 0 then
        self.data.cooldowns[data.skillId] = {
            startTime = os.time(),
            duration = data.duration,
            remaining = data.duration,
        }
    else
        self.data.cooldowns[data.skillId] = nil
    end

    -- 通知UI更新
    self.events:emit("SkillCooldownUpdated", {
        skillId = data.skillId,
        cooldown = self.data.cooldowns[data.skillId],
        timestamp = os.time()
    })
end

-- ========================================
-- 本地冷却更新
-- ========================================

function SkillSystemClient:updateLocalCooldowns(dt)
    for skillId, cooldown in pairs(self.data.cooldowns) do
        if cooldown.remaining > 0 then
            cooldown.remaining = cooldown.remaining - dt

            if cooldown.remaining <= 0 then
                cooldown.remaining = 0

                -- 冷却结束，通知UI
                self.events:emit("SkillCooldownEnded", {
                    skillId = skillId,
                    timestamp = os.time()
                })
            end
        end
    end
end

-- ========================================
-- 公共API
-- ========================================

function SkillSystemClient:getLearnedSkills()
    return self.data.learnedSkills
end

function SkillSystemClient:getShortcuts()
    return self.data.shortcuts
end

function SkillSystemClient:getCooldowns()
    return self.data.cooldowns
end

function SkillSystemClient:getSkillTemplate(skillId)
    return self.data.skillTemplates[skillId]
end

function SkillSystemClient:hasLearned(skillId)
    return self.data.learnedSkills[skillId] ~= nil
end

function SkillSystemClient:isOnCooldown(skillId)
    local cooldown = self.data.cooldowns[skillId]
    return cooldown and cooldown.remaining > 0
end

function SkillSystemClient:getCooldownRemaining(skillId)
    local cooldown = self.data.cooldowns[skillId]
    return cooldown and cooldown.remaining or 0
end

function SkillSystemClient:getCooldownPercentage(skillId)
    local cooldown = self.data.cooldowns[skillId]
    if not cooldown or cooldown.duration == 0 then
        return 0
    end

    return (cooldown.remaining / cooldown.duration) * 100
end

return SkillSystemClient
