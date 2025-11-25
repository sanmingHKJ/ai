# How to Use Event Bus in MiniWorld Studio SGF

## Overview

The Event Bus provides decoupled communication between systems without direct dependencies. Instead of SystemA calling SystemB directly, SystemA emits an event that SystemB listens for. This creates flexible, maintainable code based on the Observer pattern.

**Common Use Cases**: Cross-system notifications, UI updates, breaking circular dependencies, quest triggers, achievement systems

---

## What is the Event Bus?

The Event Bus allows:
- **Emitting events**: `self.events:emit(eventId, data)`
- **Listening for events**: `self.events:on(eventId, handler)`
- **Decoupled communication**: Systems don't need direct references to each other
- **One-to-many broadcasting**: Multiple systems can listen for the same event

---

## EventID Definition File

### Create EventID.lua

**Location**: `MainStorage/Framework/Runtime/EventID.lua`

```lua
--[[
    EventID.lua - Centralized event definitions

    All events should be defined here to:
    - Prevent typos
    - Provide autocomplete
    - Document all events in one place
]]

local EventID = {
    -- ===== GAME LIFECYCLE =====
    GameInitialized = "Game:Initialized",
    GameStarted = "Game:Started",
    GamePaused = "Game:Paused",
    GameEnded = "Game:Ended",

    -- ===== PLAYER EVENTS =====
    PlayerJoined = "Player:Joined",
    PlayerLeft = "Player:Left",
    PlayerSpawned = "Player:Spawned",
    PlayerDied = "Player:Died",
    PlayerRespawned = "Player:Respawned",
    PlayerLevelUp = "Player:LevelUp",
    PlayerHealthUpdated = "Player:HealthUpdated",
    PlayerManaUpdated = "Player:ManaUpdated",
    PlayerExpUpdated = "Player:ExpUpdated",

    -- ===== COMBAT EVENTS =====
    CombatStarted = "Combat:Started",
    CombatEnded = "Combat:Ended",
    CombatDamageDealt = "Combat:DamageDealt",
    CombatDamageTaken = "Combat:DamageTaken",
    CombatEnemyDefeated = "Combat:EnemyDefeated",

    -- ===== INVENTORY EVENTS =====
    InventoryUpdated = "Inventory:Updated",
    ItemObtained = "Inventory:ItemObtained",
    ItemUsed = "Inventory:ItemUsed",
    ItemDropped = "Inventory:ItemDropped",

    -- ===== QUEST EVENTS =====
    QuestAccepted = "Quest:Accepted",
    QuestCompleted = "Quest:Completed",
    QuestObjectiveUpdated = "Quest:ObjectiveUpdated",

    -- ===== SCENE EVENTS =====
    SceneChanged = "Scene:Changed",
    SceneChangedClient = "Scene:ChangedClient",
    DoorOpened = "Scene:DoorOpened",
    DoorClosed = "Scene:DoorClosed",

    -- ===== UI EVENTS =====
    UIShowMessage = "UI:ShowMessage",
    UIOpenPanel = "UI:OpenPanel",
    UIClosePanel = "UI:ClosePanel",

    -- ===== INTERACTION EVENTS =====
    NPCInteracted = "Interaction:NPCInteracted",
    ObjectClicked = "Interaction:ObjectClicked",

    -- ===== SYSTEM EVENTS =====
    SystemError = "System:Error",
    DataSaved = "System:DataSaved",
    DataLoaded = "System:DataLoaded",
}

-- Helper: Validate event ID exists
function EventID.isValid(eventId)
    for _, id in pairs(EventID) do
        if type(id) == "string" and id == eventId then
            return true
        end
    end
    return false
end

return EventID
```

**JSON**: `EventID.json`
```json
{
  "ClassType": "ModuleScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "EventID",
  "reflex": [
    {"Name": "EventID"},
    {"Tag": 0},
    {"Enabled": true}
  ]
}
```

---

## Emitting Events

### Basic Event Emission

```lua
function PlayerSystemServer:levelUp(playerId)
    local playerData = self.data.players[playerId]

    -- Update player level
    playerData.level = playerData.level + 1

    -- Emit event for other systems
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    self.events:emit(EventID.PlayerLevelUp, {
        playerId = playerId,
        newLevel = playerData.level,
        oldLevel = playerData.level - 1,
        timestamp = os.time()
    })

    self.log:info("[PlayerSystem] Player leveled up", {
        playerId = playerId,
        newLevel = playerData.level
    })
end
```

### Event Emission with Rich Data

```lua
function CombatSystemServer:dealDamage(attackerId, targetId, damage)
    -- Apply damage
    local targetHealth = self:applyDamage(targetId, damage)

    -- Emit event with detailed information
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    self.events:emit(EventID.CombatDamageDealt, {
        attackerId = attackerId,
        targetId = targetId,
        damage = damage,
        remainingHealth = targetHealth,
        isCritical = false,
        timestamp = os.time()
    })

    -- Check if target died
    if targetHealth <= 0 then
        self.events:emit(EventID.CombatEnemyDefeated, {
            defeatedBy = attackerId,
            enemyId = targetId,
            exp = 100,
            loot = {"Sword", "Potion"}
        })
    end
end
```

---

## Listening for Events

### Register Listeners in PreInit

```lua
function QuestSystemServer:PreInit()
    self.log:info("[QuestSystemServer] PreInit started")

    -- Register event listeners
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- Listen for enemy defeated (for kill quests)
    self.events:on(EventID.CombatEnemyDefeated, function(data)
        self:onEnemyDefeated(data)
    end)

    -- Listen for item obtained (for collection quests)
    self.events:on(EventID.ItemObtained, function(data)
        self:onItemObtained(data)
    end)

    -- Listen for player level up (for level-based quests)
    self.events:on(EventID.PlayerLevelUp, function(data)
        self:checkLevelBasedQuests(data.playerId, data.newLevel)
    end)

    return true
end
```

### Event Handler Methods

```lua
function QuestSystemServer:onEnemyDefeated(data)
    self.log:debug("[QuestSystemServer] Enemy defeated", data)

    -- Update kill quest progress
    local playerId = data.defeatedBy
    local enemyType = data.enemyId

    local activeQuests = self:getActiveQuests(playerId)

    for _, quest in ipairs(activeQuests) do
        if quest.objectiveType == "kill" and quest.targetEnemy == enemyType then
            quest.progress = quest.progress + 1

            -- Emit quest progress event
            local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
            self.events:emit(EventID.QuestObjectiveUpdated, {
                playerId = playerId,
                questId = quest.id,
                progress = quest.progress,
                required = quest.required
            })

            -- Check if quest completed
            if quest.progress >= quest.required then
                self:completeQuest(playerId, quest.id)
            end
        end
    end
end

function QuestSystemServer:onItemObtained(data)
    self.log:debug("[QuestSystemServer] Item obtained", data)

    -- Update collection quest progress
    local playerId = data.playerId
    local itemId = data.itemId

    -- ... similar logic for collection quests
end
```

---

## Client-Side Event Listeners

### Listen for Events to Update UI

```lua
function PlayerUISystemClient:PreInit()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- Update health bar when health changes
    self.events:on(EventID.PlayerHealthUpdated, function(data)
        self:updateHealthBar(data.currentHp, data.maxHp)
    end)

    -- Update mana bar when mana changes
    self.events:on(EventID.PlayerManaUpdated, function(data)
        self:updateManaBar(data.currentMp, data.maxMp)
    end)

    -- Show level up effect
    self.events:on(EventID.PlayerLevelUp, function(data)
        self:showLevelUpEffect(data.newLevel)
    end)

    -- Show damage numbers
    self.events:on(EventID.CombatDamageDealt, function(data)
        self:showDamageNumber(data.targetId, data.damage, data.isCritical)
    end)

    return true
end

function PlayerUISystemClient:updateHealthBar(currentHp, maxHp)
    if self.sgf.panelManager then
        local panel = self.sgf.panelManager:getPanel("PlayerStatsPanel")
        if panel then
            panel:updateHealth(currentHp, maxHp)
        end
    end
end

function PlayerUISystemClient:showLevelUpEffect(newLevel)
    self.log:info("[PlayerUISystem] LEVEL UP!", {newLevel = newLevel})

    -- Show animated effect
    if self.sgf.panelManager then
        local panel = self.sgf.panelManager:getPanel("PlayerStatsPanel")
        if panel then
            panel:showLevelUpAnimation(newLevel)
        end
    end

    -- Play sound effect
    -- self.sgf.audio:play("level_up_sound")
end
```

---

## Breaking Circular Dependencies with Events

### Problem: Circular Dependency

```lua
-- ❌ BAD: Circular dependency
PlayerSystem.dependencies = {"CombatSystem"}
CombatSystem.dependencies = {"PlayerSystem"}

-- Error: Circular dependency detected!
```

### Solution: Use Events

```lua
-- ✅ GOOD: Break circular dependency with events
PlayerSystem.dependencies = {}
CombatSystem.dependencies = {"PlayerSystem"}

-- PlayerSystem emits event
function PlayerSystem:takeDamage(playerId, damage)
    -- Update health
    playerData.health = playerData.health - damage

    -- Emit event (instead of calling CombatSystem)
    local EventID = require(...EventID)
    self.events:emit(EventID.PlayerDamageTaken, {
        playerId = playerId,
        damage = damage,
        remainingHealth = playerData.health
    })
end

-- CombatSystem listens for event
function CombatSystem:PreInit()
    local EventID = require(...EventID)

    self.events:on(EventID.PlayerDamageTaken, function(data)
        self:onPlayerDamageTaken(data)
    end)
end

function CombatSystem:onPlayerDamageTaken(data)
    -- Handle damage effects (without depending on PlayerSystem)
    self:spawnBloodEffect(data.playerId)
    self:playHurtAnimation(data.playerId)
end
```

---

## Event-Driven Achievement System

### Complete Example

```lua
--[[
    AchievementSystemServer - Achievement tracking via events
]]

local AchievementSystemServer = {}

AchievementSystemServer.name = "AchievementSystemServer"
AchievementSystemServer.dependencies = {}  -- No direct dependencies!

function AchievementSystemServer:PreInit()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    -- Listen for various events
    self.events:on(EventID.PlayerLevelUp, function(data)
        self:checkLevelAchievements(data.playerId, data.newLevel)
    end)

    self.events:on(EventID.CombatEnemyDefeated, function(data)
        self:checkKillAchievements(data.defeatedBy, data.enemyId)
    end)

    self.events:on(EventID.ItemObtained, function(data)
        self:checkCollectionAchievements(data.playerId, data.itemId)
    end)

    self.events:on(EventID.QuestCompleted, function(data)
        self:checkQuestAchievements(data.playerId, data.questId)
    end)

    return true
end

function AchievementSystemServer:checkLevelAchievements(playerId, level)
    local achievements = {
        {level = 10, id = "level_10", name = "Novice Adventurer"},
        {level = 25, id = "level_25", name = "Experienced Hero"},
        {level = 50, id = "level_50", name = "Master Warrior"}
    }

    for _, achievement in ipairs(achievements) do
        if level >= achievement.level then
            self:unlockAchievement(playerId, achievement.id)
        end
    end
end

function AchievementSystemServer:unlockAchievement(playerId, achievementId)
    -- Check if already unlocked
    if self:hasAchievement(playerId, achievementId) then
        return
    end

    -- Unlock achievement
    self.data.achievements[playerId] = self.data.achievements[playerId] or {}
    self.data.achievements[playerId][achievementId] = true

    self.log:info("[AchievementSystem] Achievement unlocked", {
        playerId = playerId,
        achievementId = achievementId
    })

    -- Emit achievement unlocked event (for other systems/UI)
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit("Achievement:Unlocked", {
        playerId = playerId,
        achievementId = achievementId,
        timestamp = os.time()
    })
end
```

---

## Common Patterns

### Pattern 1: Event with Cancellation

```lua
-- Emitter: Allow event to be cancelled
function PlayerSystem:beforeTakeDamage(playerId, damage)
    local EventID = require(...EventID)

    local event = {
        playerId = playerId,
        damage = damage,
        cancelled = false
    }

    self.events:emit("Player:BeforeTakeDamage", event)

    -- Check if cancelled by a listener
    if event.cancelled then
        self.log:info("[PlayerSystem] Damage cancelled")
        return false
    end

    -- Apply damage
    self:applyDamage(playerId, event.damage)  -- Listeners can modify damage
    return true
end

-- Listener: Cancel or modify event
function InvulnerabilitySystem:PreInit()
    self.events:on("Player:BeforeTakeDamage", function(event)
        if self:isInvulnerable(event.playerId) then
            event.cancelled = true
            event.damage = 0
        end
    end)
end
```

### Pattern 2: Event Logging

```lua
function SystemName:PreInit()
    local EventID = require(...EventID)

    -- Log all important events
    local eventsToLog = {
        EventID.PlayerLevelUp,
        EventID.CombatEnemyDefeated,
        EventID.QuestCompleted
    }

    for _, eventId in ipairs(eventsToLog) do
        self.events:on(eventId, function(data)
            self.log:info("[EventLog] " .. eventId, data)
        end)
    end
end
```

### Pattern 3: Event Aggregation

```lua
-- Aggregate multiple events into one
function StatisticsSystem:PreInit()
    local EventID = require(...EventID)

    local playerActions = {}

    -- Track all player actions
    local actionEvents = {
        EventID.CombatAction,
        EventID.ItemUsed,
        EventID.NPCInteracted
    }

    for _, eventId in ipairs(actionEvents) do
        self.events:on(eventId, function(data)
            playerActions[data.playerId] = (playerActions[data.playerId] or 0) + 1

            -- Emit aggregated event every 10 actions
            if playerActions[data.playerId] % 10 == 0 then
                self.events:emit("Player:ActionMilestone", {
                    playerId = data.playerId,
                    totalActions = playerActions[data.playerId]
                })
            end
        end)
    end
end
```

---

## Best Practices

### 1. Always Use EventID Constants

```lua
-- ✅ GOOD: Use EventID constants
local EventID = require(...EventID)
self.events:emit(EventID.PlayerLevelUp, data)

-- ❌ BAD: Magic strings
self.events:emit("PlayerLevelUp", data)
```

### 2. Provide Rich Event Data

```lua
-- ✅ GOOD: Rich event data
self.events:emit(EventID.PlayerLevelUp, {
    playerId = playerId,
    newLevel = newLevel,
    oldLevel = oldLevel,
    timestamp = os.time(),
    rewardGold = 100
})

-- ❌ BAD: Minimal data
self.events:emit(EventID.PlayerLevelUp, playerId)
```

### 3. Document Event Structure

```lua
--[[
    Event: PlayerLevelUp
    Emitted when a player levels up

    Data structure:
    {
        playerId: number,
        newLevel: number,
        oldLevel: number,
        timestamp: number,
        rewardGold: number
    }
]]
```

### 4. Prefer Events Over Dependencies

```lua
-- ✅ GOOD: Use events for notifications
AchievementSystem.dependencies = {}  -- No dependencies!

function AchievementSystem:PreInit()
    self.events:on(EventID.QuestCompleted, function(data)
        self:checkAchievements(data.playerId)
    end)
end

-- ❌ BAD: Direct dependency
AchievementSystem.dependencies = {"QuestSystem"}

function AchievementSystem:PostInit()
    self.questSystem = ...
end
```

---

## Quick Reference Card

```lua
-- EventID definition
local EventID = {
    PlayerLevelUp = "Player:LevelUp",
    -- ... more events
}

-- Emit event
function MySystem:doSomething()
    local EventID = require(...EventID)

    self.events:emit(EventID.PlayerLevelUp, {
        playerId = playerId,
        newLevel = level
    })
end

-- Listen for event (in PreInit)
function MySystem:PreInit()
    local EventID = require(...EventID)

    self.events:on(EventID.PlayerLevelUp, function(data)
        self:onPlayerLevelUp(data)
    end)

    return true
end

-- Event handler
function MySystem:onPlayerLevelUp(data)
    self.log:info("Player leveled up!", data)
end
```

---

## See Also

- [how-to-create-business-system.md](./how-to-create-business-system.md) - Creating systems
- [how-to-use-system-lifecycle.md](./how-to-use-system-lifecycle.md) - Lifecycle and dependencies
- [how-to-use-network-communication.md](./how-to-use-network-communication.md) - Network patterns

---

**Created**: 2025-10-31
**Version**: 1.0.0
**Based on**: rpg-gamedemo sample and scene-workflow-stage-4.md
