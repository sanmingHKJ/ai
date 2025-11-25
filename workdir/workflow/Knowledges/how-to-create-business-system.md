# How to Create Business Systems in MiniWorld Studio

## Overview

Business systems are the core organizational pattern in MiniWorld Studio's SGF Framework. Instead of individual behavior scripts, you group related game features into modular systems with consistent lifecycle management. This guide shows you how to create server-side and client-side business systems based on production patterns from rpg-gamedemo.

**Common Use Cases**: Player management, combat systems, inventory, scene transitions, NPC interactions, quest systems, economy systems

---

## What is a Business System?

A business system is a ModuleScript that:
- Handles a specific feature area (e.g., PlayerSystem, CombatSystem, InventorySystem)
- Has a consistent lifecycle (PreInit → Init → PostInit → Start → Update → Stop)
- Can declare dependencies on other systems
- Communicates via network messages (server) or network listeners (client)
- Emits and listens for events via the event bus

**Server systems** = Authoritative game logic
**Client systems** = Local rendering, UI updates, input handling

---

## Server Business System Template

### File Structure

```
MainStorage/Framework/GameSystems/
└── PlayerSystem/
    ├── PlayerSystemServer.lua    # Server logic (ModuleScript)
    ├── PlayerSystemServer.json
    ├── PlayerSystemClient.lua    # Client logic (ModuleScript)
    └── PlayerSystemClient.json
```

### Complete Server System Example

**File**: `MainStorage/Framework/GameSystems/PlayerSystem/PlayerSystemServer.lua`

```lua
--[[
    PlayerSystemServer - Player management system (Server-side)

    Functionality:
    - Manage player data (health, level, experience)
    - Handle player join/leave events
    - Validate player actions
    - Sync player state to clients

    System Type: server-only
    Dependencies: LevelSystemServer
]]

local PlayerSystemServer = {}

-- ========== METADATA ==========
PlayerSystemServer.name = "PlayerSystemServer"
PlayerSystemServer.version = "1.0.0"
PlayerSystemServer.description = "Player management system (Server)"

-- Dependencies (other systems this system needs)
PlayerSystemServer.dependencies = {"LevelSystemServer"}

-- State tracking
PlayerSystemServer.state = "uninitialized"  -- "uninitialized" | "initialized" | "started" | "stopped"

-- Framework references (set in constructor)
PlayerSystemServer.sgf = nil
PlayerSystemServer.log = nil
PlayerSystemServer.events = nil

-- Configuration
PlayerSystemServer.config = {}

-- ========== DATA STORAGE ==========
PlayerSystemServer.data = {
    players = {}  -- [playerId] = PlayerData
}

-- Cached dependencies (populated in PostInit)
PlayerSystemServer.dependencies_cache = {}

-- ========== CONSTRUCTOR ==========
function PlayerSystemServer.new(sgf)
    local self = setmetatable({}, {__index = PlayerSystemServer})

    -- Store framework reference
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    return self
end

-- ========== LIFECYCLE PHASE 1: PREINIT ==========
--[[
    PreInit - Register event listeners, prepare resources

    Called FIRST, before other systems exist.
    DO NOT access other systems here.

    Use for:
    - Registering event listeners
    - Preparing data structures
    - Loading resources
]]
function PlayerSystemServer:PreInit()
    self.log:info("[PlayerSystemServer] PreInit started")

    -- Register for game events
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)

    self.events:on(EventID.PlayerLeft, function(data)
        self:onPlayerLeft(data)
    end)

    self.log:info("[PlayerSystemServer] PreInit complete")
    return true
end

-- ========== LIFECYCLE PHASE 2: INIT ==========
--[[
    Init - Initialize system, load configuration, register network handlers

    Called SECOND, after all PreInit.
    DO NOT access other systems here (use PostInit).

    Use for:
    - Loading configuration
    - Registering network handlers
    - Setting up timers
]]
function PlayerSystemServer:Init()
    self.log:info("[PlayerSystemServer] Init started")

    -- Load configuration (if any)
    self.config = {
        defaultHealth = 100,
        defaultMana = 50,
        respawnTime = 5
    }

    -- Register network handlers
    self:registerNetworkHandlers()

    -- Initialize data structures
    self.data.players = {}

    self.state = "initialized"
    self.log:info("[PlayerSystemServer] Init complete")
    return true
end

-- ========== LIFECYCLE PHASE 3: POSTINIT ==========
--[[
    PostInit - Resolve dependencies on other systems

    Called THIRD, after all Init.
    NOW safe to access other systems.

    Use for:
    - Getting references to other systems
    - Validating dependencies exist
]]
function PlayerSystemServer:PostInit()
    self.log:info("[PlayerSystemServer] PostInit started")

    -- Get dependency references (NOW safe to access other systems)
    if self.sgf.businessSystemManager then
        self.dependencies_cache.LevelSystem =
            self.sgf.businessSystemManager:get("LevelSystemServer")

        -- Validate dependencies
        if not self.dependencies_cache.LevelSystem then
            self.log:error("[PlayerSystemServer] Missing dependency: LevelSystemServer")
            return false
        end
    end

    self.log:info("[PlayerSystemServer] PostInit complete")
    return true
end

-- ========== LIFECYCLE PHASE 4: START ==========
--[[
    Start - Begin operations, start timers, activate features

    Called FOURTH, after all PostInit.
    All systems are fully initialized.

    Use for:
    - Starting periodic tasks
    - Spawning entities
    - Beginning game logic
]]
function PlayerSystemServer:Start()
    self.log:info("[PlayerSystemServer] Start started")

    -- Example: Start auto-save timer
    -- self.sgf.scheduler:scheduleRepeating("PlayerAutoSave", 60, function()
    --     self:autoSaveAll()
    -- end)

    self.state = "started"
    self.log:info("[PlayerSystemServer] Started successfully")
    return true
end

-- ========== LIFECYCLE PHASE 5: UPDATE (Optional) ==========
--[[
    Update - Called every frame

    Use for:
    - Frame-by-frame logic
    - Position updates
    - State checks
]]
function PlayerSystemServer:Update(dt)
    -- Optional: Implement frame updates if needed
    -- Most systems don't need this
end

-- ========== LIFECYCLE PHASE 6: STOP (Optional) ==========
--[[
    Stop - Clean up resources

    Called when system is shutting down.

    Use for:
    - Saving data
    - Cleaning up timers
    - Releasing resources
]]
function PlayerSystemServer:Stop()
    self.log:info("[PlayerSystemServer] Stopping...")

    -- Save all player data
    for playerId, _ in pairs(self.data.players) do
        self:savePlayerData(playerId)
    end

    -- Clean up
    self.data.players = {}

    self.state = "stopped"
    self.log:info("[PlayerSystemServer] Stopped")
    return true
end

-- ========== NETWORK HANDLERS ==========
function PlayerSystemServer:registerNetworkHandlers()
    -- Register as network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    -- Import protocol definitions
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Handle client requests
    self:OnRequest(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, function(userId, msgid, data)
        return self:handleGetPlayerData(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.PLAYER_CREATE_CHARACTER_REQ, function(userId, msgid, data)
        return self:handleCreateCharacter(userId, data)
    end)
end

function PlayerSystemServer:handleGetPlayerData(userId, data)
    self.log:debug("[PlayerSystemServer] Get player data request", {userId = userId})

    local playerData = self.data.players[userId]

    if playerData then
        return {
            success = true,
            playerData = playerData
        }
    else
        return {
            success = false,
            error = "Player data not found"
        }
    end
end

function PlayerSystemServer:handleCreateCharacter(userId, data)
    self.log:info("[PlayerSystemServer] Create character", {
        userId = userId,
        name = data.characterName
    })

    -- Create player data
    local playerData = {
        userId = userId,
        name = data.characterName,
        classType = data.classType,
        level = 1,
        exp = 0,
        health = self.config.defaultHealth,
        mana = self.config.defaultMana
    }

    self.data.players[userId] = playerData

    -- Notify all clients
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:Broadcast(Protocol.ServerMSGID.PLAYER_DATA_UPDATE_NOTIFY, {
        userId = userId,
        playerData = playerData
    })

    return {
        success = true,
        playerData = playerData
    }
end

-- ========== GAME LOGIC METHODS ==========
function PlayerSystemServer:onPlayerJoined(data)
    local playerId = data.playerId
    self.log:info("[PlayerSystemServer] Player joined", {playerId = playerId})

    -- Initialize player data if new
    if not self.data.players[playerId] then
        self:createDefaultPlayerData(playerId)
    end
end

function PlayerSystemServer:onPlayerLeft(data)
    local playerId = data.playerId
    self.log:info("[PlayerSystemServer] Player left", {playerId = playerId})

    -- Save player data
    self:savePlayerData(playerId)

    -- Clean up
    self.data.players[playerId] = nil
end

function PlayerSystemServer:createDefaultPlayerData(playerId)
    self.data.players[playerId] = {
        userId = playerId,
        name = "Player" .. playerId,
        level = 1,
        exp = 0,
        health = self.config.defaultHealth,
        mana = self.config.defaultMana
    }
end

function PlayerSystemServer:savePlayerData(playerId)
    -- TODO: Save to database
    self.log:info("[PlayerSystemServer] Saving player data", {playerId = playerId})
end

-- ========== PUBLIC API ==========
--[[
    Public methods that other systems can call
]]
function PlayerSystemServer:getPlayerData(playerId)
    return self.data.players[playerId]
end

function PlayerSystemServer:updatePlayerHealth(playerId, newHealth)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.health = newHealth

    -- Emit event
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerHealthUpdated, {
        playerId = playerId,
        currentHp = newHealth,
        maxHp = self.config.defaultHealth
    })

    return true
end

function PlayerSystemServer:addExp(playerId, exp)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.exp = playerData.exp + exp

    -- Check for level up (using LevelSystem dependency)
    if self.dependencies_cache.LevelSystem then
        local levelSystem = self.dependencies_cache.LevelSystem
        if levelSystem:checkLevelUp(playerId, playerData.exp) then
            self:levelUp(playerId)
        end
    end

    return true
end

function PlayerSystemServer:levelUp(playerId)
    local playerData = self.data.players[playerId]
    if not playerData then return false end

    playerData.level = playerData.level + 1

    -- Emit event
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.PlayerLevelUp, {
        playerId = playerId,
        newLevel = playerData.level
    })

    self.log:info("[PlayerSystemServer] Player leveled up", {
        playerId = playerId,
        newLevel = playerData.level
    })

    return true
end

return PlayerSystemServer
```

**JSON Configuration** (`PlayerSystemServer.json`):
```json
{
  "ClassType": "ModuleScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "PlayerSystemServer",
  "reflex": [
    {"Name": "PlayerSystemServer"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"Scriptid": 1},
    {"Mode": 1},
    {"Luafile": ""}
  ]
}
```

---

## Client Business System Template

### Complete Client System Example

**File**: `MainStorage/Framework/GameSystems/PlayerSystem/PlayerSystemClient.lua`

```lua
--[[
    PlayerSystemClient - Player management system (Client-side)

    Functionality:
    - Display player stats in UI
    - Handle player input
    - Update visual effects
    - Request data from server

    System Type: client-only
    Dependencies: None
]]

local PlayerSystemClient = {}

-- ========== METADATA ==========
PlayerSystemClient.name = "PlayerSystemClient"
PlayerSystemClient.version = "1.0.0"
PlayerSystemClient.description = "Player management system (Client)"

PlayerSystemClient.dependencies = {}
PlayerSystemClient.state = "uninitialized"

PlayerSystemClient.sgf = nil
PlayerSystemClient.log = nil
PlayerSystemClient.events = nil

-- ========== DATA STORAGE ==========
PlayerSystemClient.data = {
    localPlayerData = nil
}

-- ========== CONSTRUCTOR ==========
function PlayerSystemClient.new(sgf)
    local self = setmetatable({}, {__index = PlayerSystemClient})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    return self
end

-- ========== LIFECYCLE METHODS ==========
function PlayerSystemClient:PreInit()
    self.log:info("[PlayerSystemClient] PreInit started")

    -- Register event listeners
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    self.events:on(EventID.PlayerHealthUpdated, function(data)
        self:onHealthUpdated(data)
    end)

    self.events:on(EventID.PlayerLevelUp, function(data)
        self:onLevelUp(data)
    end)

    return true
end

function PlayerSystemClient:Init()
    self.log:info("[PlayerSystemClient] Init started")

    -- Register network handlers
    self:registerNetworkHandlers()

    self.state = "initialized"
    return true
end

function PlayerSystemClient:PostInit()
    self.log:info("[PlayerSystemClient] PostInit started")
    -- Client systems usually don't have dependencies
    return true
end

function PlayerSystemClient:Start()
    self.log:info("[PlayerSystemClient] Start started")

    -- Request initial player data from server
    self:requestPlayerData()

    self.state = "started"
    return true
end

function PlayerSystemClient:Update(dt)
    -- Optional: Client-side updates
end

function PlayerSystemClient:Stop()
    self.data.localPlayerData = nil
    self.state = "stopped"
    return true
end

-- ========== NETWORK HANDLERS ==========
function PlayerSystemClient:registerNetworkHandlers()
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Listen for server responses
    self:OnResponse(Protocol.ServerMSGID.PLAYER_DATA_UPDATE_NOTIFY, function(msgid, data)
        self:onPlayerDataUpdated(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.PLAYER_CREATE_CHARACTER_RSP, function(msgid, data)
        self:onCreateCharacterResponse(data)
    end)
end

function PlayerSystemClient:requestPlayerData()
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, {})
end

function PlayerSystemClient:requestCreateCharacter(characterName, classType)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.PLAYER_CREATE_CHARACTER_REQ, {
        characterName = characterName,
        classType = classType
    })
end

function PlayerSystemClient:onPlayerDataUpdated(data)
    self.log:debug("[PlayerSystemClient] Player data updated", data)

    if data.playerData then
        self.data.localPlayerData = data.playerData
        self:updateUI()
    end
end

function PlayerSystemClient:onCreateCharacterResponse(data)
    if data.success then
        self.log:info("[PlayerSystemClient] Character created")
        self.data.localPlayerData = data.playerData
        self:updateUI()
    else
        self.log:error("[PlayerSystemClient] Create character failed:", data.error)
    end
end

-- ========== UI UPDATE METHODS ==========
function PlayerSystemClient:onHealthUpdated(data)
    self.log:debug("[PlayerSystemClient] Health updated", data)

    -- Update health bar UI
    if self.sgf.panelManager then
        local panel = self.sgf.panelManager:getPanel("PlayerStatsPanel")
        if panel then
            panel:updateHealth(data.currentHp, data.maxHp)
        end
    end
end

function PlayerSystemClient:onLevelUp(data)
    self.log:info("[PlayerSystemClient] Level up!", data)

    -- Show level up effect
    if self.sgf.panelManager then
        local panel = self.sgf.panelManager:getPanel("PlayerStatsPanel")
        if panel then
            panel:showLevelUpAnimation(data.newLevel)
        end
    end
end

function PlayerSystemClient:updateUI()
    if not self.data.localPlayerData then return end

    -- Update all UI panels with latest data
    if self.sgf.panelManager then
        local panel = self.sgf.panelManager:getPanel("PlayerStatsPanel")
        if panel then
            panel:refresh(self.data.localPlayerData)
        end
    end
end

-- ========== PUBLIC API ==========
function PlayerSystemClient:getLocalPlayerData()
    return self.data.localPlayerData
end

return PlayerSystemClient
```

**JSON Configuration** (`PlayerSystemClient.json`):
```json
{
  "ClassType": "ModuleScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "PlayerSystemClient",
  "reflex": [
    {"Name": "PlayerSystemClient"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"Scriptid": 1},
    {"Mode": 1},
    {"Luafile": ""}
  ]
}
```

---

## System Organization Patterns

### Pattern 1: Group Related Behaviors

Instead of individual scripts per behavior, group related behaviors into systems:

```
❌ OLD WAY (Individual Behavior Scripts):
- door_basic.lua
- door_pressure_plate_locked.lua
- door_lever_locked.lua
- pressure_plate_activate.lua
- lever_activate.lua

✅ NEW WAY (Business Systems):
- DoorSystemServer.lua
  - Handles all door types (basic, locked, etc.)
  - Manages door states
  - Coordinates with activation mechanisms
- InteractiveObjectSystemServer.lua
  - Handles pressure plates, levers, buttons
  - Sends activation signals
  - Manages cooldowns
```

### Pattern 2: Server-Client Separation

```
Server Systems (Authoritative):
- PlayerSystemServer.lua      # Player data, validation
- CombatSystemServer.lua       # Damage calculations, combat logic
- InventorySystemServer.lua    # Item management, trading

Client Systems (Visual/Input):
- PlayerSystemClient.lua       # Player UI, input handling
- CombatSystemClient.lua       # Combat animations, damage numbers
- InventorySystemClient.lua    # Inventory UI, item tooltips
```

### Pattern 3: Feature-Based Systems

Organize by game feature, not by entity type:

```
✅ GOOD (Feature-based):
- SceneSystemServer         # Scene transitions, portals
- NPCInteractionSystem      # NPC dialogues, quests
- LevelSystem              # Experience, leveling
- PlayerSystem             # Player stats, data

❌ BAD (Entity-based):
- ActorSystem              # Too broad, unclear responsibility
- ObjectSystem             # What objects? Too vague
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Accessing Dependencies in Init

```lua
-- ❌ WRONG: Trying to access other system in Init
function MySystem:Init()
    local otherSystem = self.sgf.businessSystemManager:get("OtherSystem")
    otherSystem:doSomething()  -- OtherSystem might not be Init'd yet!
end

-- ✅ CORRECT: Access in PostInit
function MySystem:PostInit()
    self.dependencies_cache.OtherSystem =
        self.sgf.businessSystemManager:get("OtherSystem")
end

function MySystem:Start()
    self.dependencies_cache.OtherSystem:doSomething()  -- Safe now
end
```

### ❌ Mistake 2: Missing Return Statement

```lua
-- ❌ WRONG: No return statement
local MySystem = {}
function MySystem.new(sgf) ... end
-- Missing: return MySystem

-- ✅ CORRECT: Always return the module
return MySystem
```

### ❌ Mistake 3: Wrong ClassType in JSON

```lua
-- ❌ WRONG: System JSON with "Script"
{
  "ClassType": "Script"  // Systems are ModuleScripts!
}

-- ✅ CORRECT: Systems use "ModuleScript"
{
  "ClassType": "ModuleScript"
}
```

### ❌ Mistake 4: Not Declaring Dependencies

```lua
-- ❌ WRONG: Using dependency without declaring
MySystem.dependencies = {}  -- Empty

function MySystem:PostInit()
    -- Using LevelSystem without declaring it
    local levelSystem = self.sgf.businessSystemManager:get("LevelSystem")
end

-- ✅ CORRECT: Declare dependencies
MySystem.dependencies = {"LevelSystem"}
```

---

## Best Practices

### 1. Always Follow Lifecycle Pattern

```lua
-- ✅ GOOD: Complete lifecycle implementation
function MySystem:PreInit() return true end
function MySystem:Init() return true end
function MySystem:PostInit() return true end
function MySystem:Start() return true end
function MySystem:Update(dt) end  -- Optional
function MySystem:Stop() return true end
```

### 2. Use Descriptive System Names

```lua
-- ✅ GOOD: Clear, descriptive names
PlayerSystemServer
CombatSystemServer
InventorySystemServer
SceneSystemServer

-- ❌ BAD: Vague names
GameSystem
Manager
Controller
Handler
```

### 3. Cache Framework References

```lua
-- ✅ GOOD: Cache in constructor
function MySystem.new(sgf)
    local self = setmetatable({}, {__index = MySystem})
    self.sgf = sgf
    self.log = sgf.log      -- Cache logging
    self.events = sgf.events  -- Cache event bus
    return self
end

-- ❌ BAD: Look up every time
function MySystem:doSomething()
    self.sgf.log:info("...")
    self.sgf.events:emit("...")
end
```

### 4. Add Clear Comments

```lua
-- ✅ GOOD: Document each section
--[[
    Phase 2: Init - Initialize system

    Loads configuration and registers network handlers.
    DO NOT access other systems here (use PostInit).
]]
function MySystem:Init()
    -- Load config
    -- Register network
    return true
end
```

---

## Quick Reference Card

```lua
-- Business system template
local MySystemServer = {}

-- Metadata
MySystemServer.name = "MySystemServer"
MySystemServer.version = "1.0.0"
MySystemServer.dependencies = {}  -- List dependency systems
MySystemServer.state = "uninitialized"

-- Data
MySystemServer.data = {}
MySystemServer.dependencies_cache = {}

-- Constructor
function MySystemServer.new(sgf)
    local self = setmetatable({}, {__index = MySystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events
    return self
end

-- Lifecycle (PreInit → Init → PostInit → Start)
function MySystemServer:PreInit() return true end
function MySystemServer:Init() return true end
function MySystemServer:PostInit() return true end
function MySystemServer:Start() return true end
function MySystemServer:Update(dt) end
function MySystemServer:Stop() return true end

return MySystemServer
```

---

## See Also

- [how-to-setup-sgf-framework.md](./how-to-setup-sgf-framework.md) - Framework initialization
- [how-to-use-system-lifecycle.md](./how-to-use-system-lifecycle.md) - Lifecycle and dependencies
- [how-to-use-network-communication.md](./how-to-use-network-communication.md) - Network patterns

---

**Created**: 2025-10-31
**Version**: 1.0.0
**Based on**: rpg-gamedemo sample (PromptTpl/samplecode/rpg-gamedemo) and scene-workflow-stage-4.md
