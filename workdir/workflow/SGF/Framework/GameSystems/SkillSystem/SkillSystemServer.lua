--[[
    SkillSystemServer.lua - 技能系统（服务端）

    职责：
    1. 管理玩家技能列表（学习、遗忘）
    2. 处理技能释放请求和验证
    3. 管理技能冷却时间
    4. 计算技能效果和伤害
    5. 验证技能释放条件（MP、冷却、目标）

    框架特性：
    - 支持多种技能类型（主动、被动、光环）
    - 关键帧事件系统（参考FK项目）
    - 伤害公式驱动
    - 冷却管理和CD追踪
    - 技能升级系统

    按照SGF标准化开发框架规范开发
    Version: 1.0.0
]]

local SkillSystemServer = {
    -- ========== 基础信息 ==========
    name = "SkillSystemServer",
    version = "1.0.0",
    description = "技能系统（服务端）",

    -- ========== 依赖声明 ==========
    dependencies = {
        "PlayerSystemServer",
    },

    -- ========== 状态管理 ==========
    state = "uninitialized",

    -- ========== 框架引用 ==========
    sgf = nil,
    log = nil,
    events = nil,

    -- ========== 配置 ==========
    config = {
        maxSkills = 10,              -- 每个玩家最多学习的技能数量
        maxShortcuts = 6,            -- 快捷栏数量
        cooldownCheckInterval = 0.1, -- 冷却检查间隔（秒）
    },

    -- ========== 数据 ==========
    data = {
        playerSkills = {},    -- [userId] = {learnedSkills, shortcuts, cooldowns}
        skillTemplates = {},  -- [skillId] = SkillTemplate（技能配置模板）
        activeSkills = {},    -- [castId] = ActiveSkillCast（正在释放的技能）
    },

    -- ========== 依赖的其他系统 ==========
    dependencies_cache = {},
}

--[[
    技能数据结构：
    PlayerSkillData = {
        userId = id,
        learnedSkills = {
            [skillId] = {
                skillId = id,
                level = 1,           -- 技能等级
                exp = 0,             -- 技能经验
                learnedAt = timestamp,
            }
        },
        shortcuts = {
            [slotIndex] = skillId,  -- 快捷栏绑定
        },
        cooldowns = {
            [skillId] = {
                startTime = timestamp,
                duration = seconds,
                remaining = seconds,
            }
        }
    }

    SkillTemplate（技能模板）= {
        skillId = id,
        name = "技能名称",
        description = "技能描述",
        iconPath = "path/to/icon",

        -- 技能类型
        skillType = "Active|Passive|Aura",  -- 主动、被动、光环
        castType = "Instant|Cast|Channel|Charge",  -- 瞬发、施法、引导、蓄力

        -- 消耗
        mpCost = 10,                 -- 魔法消耗
        hpCost = 0,                  -- 生命消耗
        itemCost = {},               -- 物品消耗

        -- 冷却
        cooldown = 5.0,              -- 冷却时间（秒）
        charges = 1,                 -- 技能层数
        chargeRecovery = 0,          -- 层数恢复时间

        -- 施法
        castTime = 0,                -- 施法时间（秒）
        channelTime = 0,             -- 引导时间（秒）
        chargeTime = 0,              -- 蓄力时间（秒）

        -- 目标
        targetType = "Self|Enemy|Ally|Ground",  -- 目标类型
        range = 10,                  -- 施法距离
        radius = 0,                  -- 作用范围
        maxTargets = 1,              -- 最大目标数

        -- 伤害/治疗
        damageType = "Physical|Magic|True",  -- 伤害类型
        damageFormula = "0.5 * S.Attack + 100 - 0.1 * T.Defense",  -- 伤害公式
        healFormula = "",            -- 治疗公式

        -- 效果
        effects = {
            -- Buff/Debuff列表
            -- {buffId = id, duration = seconds, chance = 1.0}
        },

        -- 关键帧事件（参考FK项目）
        keyframes = {
            -- {frame = 0.5, eventType = "ApplyDamage", params = {...}}
        },

        -- 学习条件
        learnConditions = {
            level = 1,               -- 需要等级
            preSkills = {},          -- 前置技能
            classType = {},          -- 职业限制
            gold = 0,                -- 学习费用
        },

        -- 升级
        maxLevel = 10,
        levelUpExp = 100,
        levelUpGrowth = {
            damageMultiplier = 1.1,  -- 每级伤害提升10%
            cooldownReduction = 0.1, -- 每级冷却减少0.1秒
        },
    }
]]

--[[
    创建新实例
]]
function SkillSystemServer.new(sgf)
    local self = setmetatable({}, {__index = SkillSystemServer})

    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    self.data = {
        playerSkills = {},
        skillTemplates = {},
        activeSkills = {},
    }
    self.dependencies_cache = {}

    return self
end

-- ========================================
-- 生命周期方法
-- ========================================

function SkillSystemServer:PreInit()
    self.log:info("SkillSystemServer PreInit...")

    -- 注册事件监听器
    self:registerEventListeners()

    return true
end

function SkillSystemServer:Init()
    if self.state ~= "uninitialized" then
        self.log:warning("SkillSystemServer already initialized")
        return false
    end

    self.log:info("SkillSystemServer Init...")

    -- 加载配置
    self:loadConfig()

    -- 加载技能模板
    self:loadSkillTemplates()

    -- 注册网络消息处理
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function SkillSystemServer:PostInit()
    self.log:info("SkillSystemServer PostInit...")

    -- 获取依赖的其他系统
    self:resolveDependencies()

    return true
end

function SkillSystemServer:Start()
    if self.state ~= "initialized" then
        self.log:error("SkillSystemServer cannot start, state: " .. self.state)
        return false
    end

    self.log:info("SkillSystemServer Start...")

    -- 启动冷却更新定时器
    self:startCooldownUpdate()

    self.state = "started"
    self.events:emit("SkillSystemStarted", {timestamp = os.time()})

    return true
end

function SkillSystemServer:Update(dt)
    if self.state ~= "started" then
        return
    end

    -- 更新技能冷却
    self:updateCooldowns(dt)

    -- 更新正在施放的技能
    self:updateActiveSkills(dt)
end

function SkillSystemServer:Stop()
    self.log:info("SkillSystemServer Stop...")

    -- 保存所有技能数据
    self:saveAllSkillData()

    self.state = "stopped"
    return true
end

-- ========================================
-- 配置和依赖
-- ========================================

function SkillSystemServer:loadConfig()
    -- 从配置服务加载配置（如果有）
    self.log:debug("SkillSystemServer config loaded")
end

function SkillSystemServer:resolveDependencies()
    -- 获取PlayerSystem引用
    if self.sgf.businessSystemManager then
        self.dependencies_cache.PlayerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
        if self.dependencies_cache.PlayerSystem then
            self.log:debug("SkillSystemServer resolved dependency: PlayerSystemServer")
        else
            self.log:warning("SkillSystemServer dependency not found: PlayerSystemServer")
        end
    end
end

-- ========================================
-- 技能模板加载
-- ========================================

function SkillSystemServer:loadSkillTemplates()
    self.log:info("Loading skill templates...")

    -- 这里应该从配置文件加载技能模板
    -- 现在提供示例技能
    self.data.skillTemplates = {
        [1001] = {
            skillId = 1001,
            name = "火球术",
            description = "发射一颗火球，对单个敌人造成魔法伤害",
            iconPath = "icons/fireball.png",

            skillType = "Active",
            castType = "Cast",

            mpCost = 15,
            hpCost = 0,

            cooldown = 3.0,
            charges = 1,

            castTime = 0.8,

            targetType = "Enemy",
            range = 15,
            radius = 0,
            maxTargets = 1,

            damageType = "Magic",
            damageFormula = "1.2 * S.Attack + 50",

            effects = {
                {buffId = 2001, duration = 3, chance = 0.2}  -- 20%几率灼烧
            },

            keyframes = {
                {frame = 0.3, eventType = "PlayEffect", params = {effectName = "FireCharge"}},
                {frame = 0.8, eventType = "LaunchProjectile", params = {speed = 20}},
                {frame = 1.0, eventType = "ApplyDamage", params = {}},
            },

            learnConditions = {
                level = 1,
                classType = {"Mage"},
                gold = 100,
            },

            maxLevel = 10,
            levelUpExp = 100,
            levelUpGrowth = {
                damageMultiplier = 1.15,
                cooldownReduction = 0.1,
            },
        },

        [1002] = {
            skillId = 1002,
            name = "重击",
            description = "对敌人造成物理伤害并降低其防御",
            iconPath = "icons/heavy_strike.png",

            skillType = "Active",
            castType = "Instant",

            mpCost = 10,
            hpCost = 0,

            cooldown = 4.0,
            charges = 1,

            castTime = 0,

            targetType = "Enemy",
            range = 3,
            radius = 0,
            maxTargets = 1,

            damageType = "Physical",
            damageFormula = "1.5 * S.Attack - 0.3 * T.Defense",

            effects = {
                {buffId = 2002, duration = 5, chance = 1.0}  -- 降低防御
            },

            keyframes = {
                {frame = 0.2, eventType = "PlayAnimation", params = {animName = "Attack_Heavy"}},
                {frame = 0.4, eventType = "ApplyDamage", params = {}},
                {frame = 0.4, eventType = "ApplyBuff", params = {buffId = 2002}},
            },

            learnConditions = {
                level = 1,
                classType = {"Warrior"},
                gold = 100,
            },

            maxLevel = 10,
            levelUpExp = 100,
            levelUpGrowth = {
                damageMultiplier = 1.12,
                cooldownReduction = 0.1,
            },
        },

        [1003] = {
            skillId = 1003,
            name = "治疗术",
            description = "恢复自己或队友的生命值",
            iconPath = "icons/heal.png",

            skillType = "Active",
            castType = "Cast",

            mpCost = 20,
            hpCost = 0,

            cooldown = 6.0,
            charges = 1,

            castTime = 1.0,

            targetType = "Ally",
            range = 20,
            radius = 0,
            maxTargets = 1,

            damageType = "Magic",
            healFormula = "1.5 * S.Attack + 80",

            effects = {},

            keyframes = {
                {frame = 0.5, eventType = "PlayEffect", params = {effectName = "HealCharge"}},
                {frame = 1.0, eventType = "ApplyHeal", params = {}},
            },

            learnConditions = {
                level = 3,
                classType = {"Mage", "Priest"},
                gold = 200,
            },

            maxLevel = 10,
            levelUpExp = 150,
            levelUpGrowth = {
                healMultiplier = 1.15,
                cooldownReduction = 0.15,
            },
        },
    }

    self.log:info(string.format("Loaded %d skill templates", self:getTableSize(self.data.skillTemplates)))
end

-- ========================================
-- 事件监听
-- ========================================

function SkillSystemServer:registerEventListeners()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- 监听玩家加入游戏
    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)

    -- 监听玩家离开游戏
    self.events:on(EventID.PlayerLeft, function(data)
        self:onPlayerLeft(data)
    end)

    self.log:debug("SkillSystemServer event listeners registered")
end

function SkillSystemServer:onPlayerJoined(data)
    if not data or not data.userId then
        self.log:warning("PlayerJoined event data is invalid")
        return
    end

    local userId = data.userId
    self.log:debug("Player joined, initializing skill data: " .. tostring(userId))

    -- 初始化玩家技能数据
    self:initPlayerSkillData(userId)

    -- 加载玩家技能数据（从存储）
    self:loadPlayerSkillData(userId)
end

function SkillSystemServer:onPlayerLeft(data)
    if not data or not data.userId then
        self.log:warning("PlayerLeft event data is invalid")
        return
    end

    local userId = data.userId
    self.log:debug("Player left, saving skill data: " .. tostring(userId))

    -- 保存玩家技能数据
    self:savePlayerSkillData(userId)

    -- 清理数据
    self.data.playerSkills[userId] = nil
end

-- ========================================
-- 网络消息处理
-- ========================================

function SkillSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)
    
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- 注册消息处理器
    self:OnRequest(Protocol.ClientMSGID.SKILL_LEARN_REQ, function(userId, msgid, data)
        return self:handleLearnSkillRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.SKILL_UPGRADE_REQ, function(userId, msgid, data)
        return self:handleUpgradeSkillRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.SKILL_SET_SHORTCUT_REQ, function(userId, msgid, data)
        return self:handleSetShortcutRequest(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.SKILL_GET_LIST_REQ, function(userId, msgid, data)
        return self:handleGetSkillListRequest(userId, data)
    end)

    -- 技能释放请求（通过战斗系统处理）
    self.events:on("CastSkillRequest", function(data)
        self:handleCastSkillRequest(data)
    end)

    self.log:debug("SkillSystemServer network handlers registered")
end

-- ========================================
-- 玩家技能数据管理
-- ========================================

function SkillSystemServer:initPlayerSkillData(userId)
    if self.data.playerSkills[userId] then
        return  -- 已经初始化
    end

    self.data.playerSkills[userId] = {
        userId = userId,
        learnedSkills = {},
        shortcuts = {},
        cooldowns = {},
    }

    self.log:debug("Initialized skill data for userId: " .. userId)
end

function SkillSystemServer:loadPlayerSkillData(userId)
    -- 从数据存储加载玩家技能数据
    -- TODO: 实现数据持久化

    -- 临时：给新玩家一些初始技能
    local playerSystem = self.dependencies_cache.PlayerSystem
    if playerSystem then
        local playerData = playerSystem:getPlayerData(userId)
        if playerData then
            -- 根据职业给予初始技能
            if playerData.classType == "Warrior" then
                self:learnSkill(userId, 1002, true)  -- 重击
            elseif playerData.classType == "Mage" then
                self:learnSkill(userId, 1001, true)  -- 火球术
                self:learnSkill(userId, 1003, true)  -- 治疗术
            elseif playerData.classType == "Assassin" then
                self:learnSkill(userId, 1002, true)  -- 重击
            end
        end
    end
end

function SkillSystemServer:savePlayerSkillData(userId)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return
    end

    -- 保存到数据存储
    -- TODO: 实现数据持久化

    self.log:debug("Saved skill data for userId: " .. userId)
end

function SkillSystemServer:saveAllSkillData()
    for userId, _ in pairs(self.data.playerSkills) do
        self:savePlayerSkillData(userId)
    end
end

-- ========================================
-- 技能学习
-- ========================================

function SkillSystemServer:learnSkill(userId, skillId, isFree)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return false, "玩家数据不存在"
    end

    -- 检查是否已经学习
    if skillData.learnedSkills[skillId] then
        return false, "已经学习该技能"
    end

    -- 获取技能模板
    local template = self.data.skillTemplates[skillId]
    if not template then
        return false, "技能不存在"
    end

    -- 检查学习条件
    if not isFree then
        local valid, reason = self:checkLearnConditions(userId, template)
        if not valid then
            return false, reason
        end

        -- 扣除学习费用
        self:consumeLearnCost(userId, template)
    end

    -- 学习技能
    skillData.learnedSkills[skillId] = {
        skillId = skillId,
        level = 1,
        exp = 0,
        learnedAt = os.time(),
    }

    self.log:info(string.format("Player %s learned skill %d", userId, skillId))

    -- 发送事件
    self.events:emit("SkillLearned", {
        userId = userId,
        skillId = skillId,
        timestamp = os.time()
    })

    return true
end

function SkillSystemServer:checkLearnConditions(userId, template)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return false, "系统错误"
    end

    local playerData = playerSystem:getPlayerData(userId)
    if not playerData then
        return false, "玩家数据不存在"
    end

    local conditions = template.learnConditions

    -- 检查等级
    if conditions.level and playerData.level < conditions.level then
        return false, string.format("需要等级%d", conditions.level)
    end

    -- 检查职业
    if conditions.classType and #conditions.classType > 0 then
        local classMatch = false
        for _, className in ipairs(conditions.classType) do
            if playerData.classType == className then
                classMatch = true
                break
            end
        end
        if not classMatch then
            return false, "职业不符合要求"
        end
    end

    -- 检查金币
    if conditions.gold and playerData.gold < conditions.gold then
        return false, string.format("需要%d金币", conditions.gold)
    end

    -- 检查前置技能
    if conditions.preSkills and #conditions.preSkills > 0 then
        local skillData = self.data.playerSkills[userId]
        for _, preSkillId in ipairs(conditions.preSkills) do
            if not skillData.learnedSkills[preSkillId] then
                return false, "需要先学习前置技能"
            end
        end
    end

    return true
end

function SkillSystemServer:consumeLearnCost(userId, template)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return
    end

    local conditions = template.learnConditions

    -- 扣除金币
    if conditions.gold and conditions.gold > 0 then
        playerSystem:addGold(userId, -conditions.gold)
    end
end

-- ========================================
-- 技能升级
-- ========================================

function SkillSystemServer:upgradeSkill(userId, skillId)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return false, "玩家数据不存在"
    end

    local learnedSkill = skillData.learnedSkills[skillId]
    if not learnedSkill then
        return false, "未学习该技能"
    end

    local template = self.data.skillTemplates[skillId]
    if not template then
        return false, "技能不存在"
    end

    -- 检查是否达到最高等级
    if learnedSkill.level >= template.maxLevel then
        return false, "已达到最高等级"
    end

    -- 检查经验是否足够
    if learnedSkill.exp < template.levelUpExp then
        return false, "经验不足"
    end

    -- 升级
    learnedSkill.level = learnedSkill.level + 1
    learnedSkill.exp = learnedSkill.exp - template.levelUpExp

    self.log:info(string.format("Player %s upgraded skill %d to level %d",
        userId, skillId, learnedSkill.level))

    -- 发送事件
    self.events:emit("SkillUpgraded", {
        userId = userId,
        skillId = skillId,
        newLevel = learnedSkill.level,
        timestamp = os.time()
    })

    return true
end

-- ========================================
-- 技能释放
-- ========================================

function SkillSystemServer:castSkill(userId, skillId, targetId, targetPos)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return false, "玩家数据不存在"
    end

    local learnedSkill = skillData.learnedSkills[skillId]
    if not learnedSkill then
        return false, "未学习该技能"
    end

    local template = self.data.skillTemplates[skillId]
    if not template then
        return false, "技能不存在"
    end

    -- 检查释放条件
    local valid, reason = self:checkCastConditions(userId, skillId, template, targetId, targetPos)
    if not valid then
        return false, reason
    end

    -- 消耗资源
    self:consumeCastCost(userId, template)

    -- 启动冷却
    self:startCooldown(userId, skillId, template.cooldown)

    -- 创建技能释放实例
    local castId = self:generateCastId()
    self.data.activeSkills[castId] = {
        castId = castId,
        userId = userId,
        skillId = skillId,
        template = template,
        level = learnedSkill.level,
        targetId = targetId,
        targetPos = targetPos,
        startTime = os.time(),
        currentFrame = 0,
        state = "Casting",  -- Casting, Channeling, Completed
    }

    -- 发送事件
    self.events:emit("SkillCasted", {
        userId = userId,
        skillId = skillId,
        castId = castId,
        targetId = targetId,
        timestamp = os.time()
    })

    self.log:debug(string.format("Player %s cast skill %d (Cast ID: %s)",
        userId, skillId, castId))

    return true, castId
end

function SkillSystemServer:checkCastConditions(userId, skillId, template, targetId, targetPos)
    -- 检查冷却
    if self:isOnCooldown(userId, skillId) then
        local remaining = self:getCooldownRemaining(userId, skillId)
        return false, string.format("技能冷却中 (%.1f秒)", remaining)
    end

    -- 检查MP
    local playerSystem = self.dependencies_cache.PlayerSystem
    if playerSystem then
        local playerData = playerSystem:getPlayerData(userId)
        if playerData then
            if playerData.stats.currentMp < template.mpCost then
                return false, "魔法值不足"
            end

            if playerData.stats.currentHp <= template.hpCost then
                return false, "生命值不足"
            end
        end
    end

    -- 检查目标（如果需要目标）
    if template.targetType == "Enemy" or template.targetType == "Ally" then
        if not targetId then
            return false, "需要选择目标"
        end

        -- TODO: 检查目标有效性和距离
    end

    return true
end

function SkillSystemServer:consumeCastCost(userId, template)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return
    end

    -- 消耗MP
    if template.mpCost > 0 then
        playerSystem:consumeMp(userId, template.mpCost)
    end

    -- 消耗HP
    if template.hpCost > 0 then
        playerSystem:consumeHp(userId, template.hpCost)
    end
end

-- ========================================
-- 冷却管理
-- ========================================

function SkillSystemServer:startCooldown(userId, skillId, duration)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return
    end

    skillData.cooldowns[skillId] = {
        startTime = os.time(),
        duration = duration,
        remaining = duration,
    }

    -- 发送事件
    self.events:emit("SkillCooldownStarted", {
        userId = userId,
        skillId = skillId,
        duration = duration,
        timestamp = os.time()
    })
end

function SkillSystemServer:isOnCooldown(userId, skillId)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return false
    end

    local cooldown = skillData.cooldowns[skillId]
    if not cooldown then
        return false
    end

    return cooldown.remaining > 0
end

function SkillSystemServer:getCooldownRemaining(userId, skillId)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return 0
    end

    local cooldown = skillData.cooldowns[skillId]
    if not cooldown then
        return 0
    end

    return math.max(0, cooldown.remaining)
end

function SkillSystemServer:updateCooldowns(dt)
    for userId, skillData in pairs(self.data.playerSkills) do
        for skillId, cooldown in pairs(skillData.cooldowns) do
            if cooldown.remaining > 0 then
                cooldown.remaining = cooldown.remaining - dt

                if cooldown.remaining <= 0 then
                    cooldown.remaining = 0

                    -- 冷却结束事件
                    self.events:emit("SkillCooldownEnded", {
                        userId = userId,
                        skillId = skillId,
                        timestamp = os.time()
                    })
                end
            end
        end
    end
end

-- ========================================
-- 正在施放的技能更新
-- ========================================

function SkillSystemServer:updateActiveSkills(dt)
    for castId, castData in pairs(self.data.activeSkills) do
        local elapsed = os.time() - castData.startTime

        -- 更新关键帧事件
        self:updateKeyframes(castData, elapsed)

        -- 检查是否完成
        local totalTime = castData.template.castTime + castData.template.channelTime
        if elapsed >= totalTime then
            castData.state = "Completed"
            self.data.activeSkills[castId] = nil
        end
    end
end

function SkillSystemServer:updateKeyframes(castData, elapsed)
    -- 遍历关键帧，触发事件
    for _, keyframe in ipairs(castData.template.keyframes) do
        local triggerTime = keyframe.frame * castData.template.castTime

        if elapsed >= triggerTime and castData.currentFrame < keyframe.frame then
            self:executeKeyframeEvent(castData, keyframe)
        end
    end

    castData.currentFrame = elapsed / castData.template.castTime
end

function SkillSystemServer:executeKeyframeEvent(castData, keyframe)
    local eventType = keyframe.eventType
    local params = keyframe.params

    self.log:debug(string.format("Executing keyframe event: %s for cast %s",
        eventType, castData.castId))

    if eventType == "ApplyDamage" then
        self:applyDamage(castData)
    elseif eventType == "ApplyHeal" then
        self:applyHeal(castData)
    elseif eventType == "ApplyBuff" then
        self:applyBuff(castData, params.buffId)
    elseif eventType == "PlayEffect" then
        self:playEffect(castData, params.effectName)
    elseif eventType == "PlayAnimation" then
        self:playAnimation(castData, params.animName)
    elseif eventType == "LaunchProjectile" then
        self:launchProjectile(castData, params.speed)
    end
end

-- ========================================
-- 技能效果计算
-- ========================================

function SkillSystemServer:applyDamage(castData)
    local playerSystem = self.dependencies_cache.PlayerSystem
    if not playerSystem then
        return
    end

    local casterData = playerSystem:getPlayerData(castData.userId)
    if not casterData then
        return
    end

    -- 计算伤害
    local damage = self:calculateDamage(castData, casterData)

    -- 应用伤害到目标
    if castData.targetId then
        -- TODO: 应用伤害到目标
        self.events:emit("CombatDamageDealt", {
            casterId = castData.userId,
            targetId = castData.targetId,
            damage = damage,
            damageType = castData.template.damageType,
            skillId = castData.skillId,
            timestamp = os.time()
        })

        self.log:debug(string.format("Skill %d dealt %d damage to target %s",
            castData.skillId, damage, castData.targetId))
    end
end

function SkillSystemServer:calculateDamage(castData, casterData)
    local template = castData.template
    local level = castData.level

    -- 基础伤害（根据公式计算）
    local baseDamage = self:evaluateDamageFormula(template.damageFormula, casterData, nil)

    -- 等级加成
    local levelMultiplier = math.pow(template.levelUpGrowth.damageMultiplier or 1.0, level - 1)
    local finalDamage = baseDamage * levelMultiplier

    return math.floor(finalDamage)
end

function SkillSystemServer:evaluateDamageFormula(formula, caster, target)
    -- 简化的公式计算（实际应该使用更复杂的表达式解析器）
    -- 支持的变量：S.Attack, S.Defense, T.Attack, T.Defense

    local S = caster.stats  -- 施法者属性
    local T = target and target.stats or {Defense = 0}  -- 目标属性

    -- 简单替换和计算
    -- 这里应该使用更安全的表达式求值方法
    local result = 0

    -- 示例：解析 "1.2 * S.Attack + 50"
    if formula:find("S%.Attack") then
        local multiplier = tonumber(formula:match("([%d%.]+)%s*%*%s*S%.Attack")) or 1.0
        local addition = tonumber(formula:match("%+%s*([%d%.]+)")) or 0
        result = multiplier * S.attack + addition
    end

    return math.max(0, result)
end

function SkillSystemServer:applyHeal(castData)
    -- TODO: 实现治疗逻辑
    self.log:debug("Apply heal for cast: " .. castData.castId)
end

function SkillSystemServer:applyBuff(castData, buffId)
    -- TODO: 实现Buff应用逻辑
    self.log:debug("Apply buff " .. buffId .. " for cast: " .. castData.castId)
end

function SkillSystemServer:playEffect(castData, effectName)
    -- 通知客户端播放特效
    self.events:emit("PlaySkillEffect", {
        castId = castData.castId,
        userId = castData.userId,
        effectName = effectName,
        timestamp = os.time()
    })
end

function SkillSystemServer:playAnimation(castData, animName)
    -- 通知客户端播放动画
    self.events:emit("PlaySkillAnimation", {
        castId = castData.castId,
        userId = castData.userId,
        animName = animName,
        timestamp = os.time()
    })
end

function SkillSystemServer:launchProjectile(castData, speed)
    -- 通知客户端发射弹道
    self.events:emit("LaunchSkillProjectile", {
        castId = castData.castId,
        userId = castData.userId,
        targetId = castData.targetId,
        speed = speed,
        timestamp = os.time()
    })
end

-- ========================================
-- 快捷栏管理
-- ========================================

function SkillSystemServer:setShortcut(userId, slotIndex, skillId)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return false, "玩家数据不存在"
    end

    -- 检查技能是否已学习
    if skillId and not skillData.learnedSkills[skillId] then
        return false, "未学习该技能"
    end

    -- 检查槽位索引
    if slotIndex < 1 or slotIndex > self.config.maxShortcuts then
        return false, "快捷栏槽位无效"
    end

    -- 设置快捷栏
    skillData.shortcuts[slotIndex] = skillId

    self.log:debug(string.format("Player %s set shortcut %d to skill %s",
        userId, slotIndex, tostring(skillId)))

    -- 发送事件
    self.events:emit("SkillShortcutChanged", {
        userId = userId,
        slotIndex = slotIndex,
        skillId = skillId,
        timestamp = os.time()
    })

    return true
end

-- ========================================
-- 网络请求处理
-- ========================================

function SkillSystemServer:handleLearnSkillRequest(userId, data)
    
    local skillId = data.skillId

    self.log:debug(string.format("Player %s requests to learn skill %d", userId, skillId))

    local success, result = self:learnSkill(userId, skillId, false)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.SKILL_LEARN_RSP, {
        success = success,
        skillId = skillId,
        reason = result or nil,
    })

    if success then
        -- 同步技能列表
        self:sendSkillList(userId)
    end
end

function SkillSystemServer:handleUpgradeSkillRequest(userId, data)
    
    local skillId = data.skillId

    self.log:debug(string.format("Player %s requests to upgrade skill %d", userId, skillId))

    local success, result = self:upgradeSkill(userId, skillId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.SKILL_UPGRADE_RSP, {
        success = success,
        skillId = skillId,
        reason = result or nil,
    })

    if success then
        -- 同步技能列表
        self:sendSkillList(userId)
    end
end

function SkillSystemServer:handleSetShortcutRequest(userId, data)
    
    local slotIndex = data.slotIndex
    local skillId = data.skillId

    self.log:debug(string.format("Player %s requests to set shortcut %d to skill %s",
        userId, slotIndex, tostring(skillId)))

    local success, result = self:setShortcut(userId, slotIndex, skillId)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.SKILL_SET_SHORTCUT_RSP, {
        success = success,
        slotIndex = slotIndex,
        skillId = skillId,
        reason = result or nil,
    })
end

function SkillSystemServer:handleGetSkillListRequest(userId, data)
    

    self.log:debug(string.format("Player %s requests skill list", userId))

    self:sendSkillList(userId)
end

function SkillSystemServer:handleCastSkillRequest(data)
    local userId = data.userId
    local skillId = data.skillId
    local targetId = data.targetId
    local targetPos = data.targetPos

    local success, result = self:castSkill(userId, skillId, targetId, targetPos)

    if not success then
        self.log:warning(string.format("Failed to cast skill %d: %s", skillId, result))

        -- 通知客户端失败
        self.events:emit("CastSkillFailed", {
            userId = userId,
            skillId = skillId,
            reason = result,
            timestamp = os.time()
        })
    end
end

function SkillSystemServer:sendSkillList(userId)
    
    local skillData = self.data.playerSkills[userId]

    if not skillData then
        return
    end

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    NetworkHelper:sendToClient(userId, Protocol.ServerMSGID.SKILL_GET_LIST_RSP, {
        success = true,
        learnedSkills = skillData.learnedSkills,
        shortcuts = skillData.shortcuts,
        cooldowns = skillData.cooldowns,
    })
end

-- ========================================
-- 公共API
-- ========================================

function SkillSystemServer:getPlayerSkillData(userId)
    return self.data.playerSkills[userId]
end

function SkillSystemServer:getSkillTemplate(skillId)
    return self.data.skillTemplates[skillId]
end

function SkillSystemServer:hasLearned(userId, skillId)
    local skillData = self.data.playerSkills[userId]
    if not skillData then
        return false
    end

    return skillData.learnedSkills[skillId] ~= nil
end

-- ========================================
-- 工具方法
-- ========================================

function SkillSystemServer:generateCastId()
    return string.format("cast_%d_%d", os.time(), math.random(10000, 99999))
end

function SkillSystemServer:startCooldownUpdate()
    -- 启动定时器更新冷却
    self.log:debug("Cooldown update timer started")
end

function SkillSystemServer:getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return SkillSystemServer
