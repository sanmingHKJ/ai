# How to Use System Lifecycle and Dependencies in MiniWorld Studio

## Overview

The SGF Framework uses a 6-phase lifecycle (PreInit → Init → PostInit → Start → Update → Stop) to initialize systems in the correct order and resolve dependencies between them. Understanding this lifecycle is critical for creating systems that work correctly together.

**Common Use Cases**: System initialization, dependency management, cross-system communication, startup order control

---

## The 6-Phase Lifecycle

### Lifecycle Flow

```
1. PreInit  → Register event listeners (no system access)
2. Init     → Load config, register network handlers (no system access)
3. PostInit → Resolve dependencies on other systems (NOW safe to access)
4. Start    → Begin operations, start timers
5. Update   → Frame-by-frame updates (optional)
6. Stop     → Clean up, save data (optional)
```

**Key Rule**: Systems CANNOT access other systems until **PostInit** phase.

---

## Phase 1: PreInit

### Purpose
Register event listeners and prepare resources BEFORE other systems exist.

### What to do
- Register event listeners via `self.events:on()`
- Prepare data structures
- Load static resources
- **DO NOT**: Access other systems

### Example

```lua
function PlayerSystemServer:PreInit()
    self.log:info("[PlayerSystemServer] PreInit started")

    -- Register event listeners
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)

    self.events:on(EventID.PlayerLeft, function(data)
        self:onPlayerLeft(data)
    end)

    -- Prepare data structures
    self.data = {
        players = {},
        eventHandlers = {}
    }

    return true
end
```

---

## Phase 2: Init

### Purpose
Initialize the system itself: load configuration, register network handlers.

### What to do
- Load configuration files
- Register network message handlers
- Set initial state
- **DO NOT**: Access other systems

### Example

```lua
function PlayerSystemServer:Init()
    self.log:info("[PlayerSystemServer] Init started")

    -- Load configuration
    self.config = {
        defaultHealth = 100,
        defaultMana = 50,
        respawnTime = 5
    }

    -- Register network handlers
    self:registerNetworkHandlers()

    -- Initialize data
    self.data.players = {}

    self.state = "initialized"
    return true
end

function PlayerSystemServer:registerNetworkHandlers()
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:OnRequest(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, function(userId, msgid, data)
        return self:handleGetPlayerData(userId, data)
    end)
end
```

---

## Phase 3: PostInit

### Purpose
**NOW safe to access other systems**. Resolve dependencies.

### What to do
- Get references to other systems via `businessSystemManager:get()`
- Cache dependency references
- Validate dependencies exist
- **NOW SAFE**: Access other systems

### Example

```lua
function PlayerSystemServer:PostInit()
    self.log:info("[PlayerSystemServer] PostInit started")

    -- Resolve dependencies (NOW safe)
    if self.sgf.businessSystemManager then
        self.dependencies_cache.LevelSystem =
            self.sgf.businessSystemManager:get("LevelSystemServer")

        self.dependencies_cache.InventorySystem =
            self.sgf.businessSystemManager:get("InventorySystemServer")

        -- Validate dependencies
        if not self.dependencies_cache.LevelSystem then
            self.log:error("[PlayerSystemServer] Missing LevelSystemServer")
            return false
        end

        if not self.dependencies_cache.InventorySystem then
            self.log:error("[PlayerSystemServer] Missing InventorySystemServer")
            return false
        end
    end

    self.log:info("[PlayerSystemServer] Dependencies resolved")
    return true
end
```

---

## Phase 4: Start

### Purpose
Begin operations. All systems are fully initialized.

### What to do
- Start periodic timers
- Spawn entities
- Begin game logic
- **Safe to use dependencies**

### Example

```lua
function PlayerSystemServer:Start()
    self.log:info("[PlayerSystemServer] Starting...")

    -- Start auto-save timer (example)
    if self.sgf.scheduler then
        self.sgf.scheduler:scheduleRepeating("PlayerAutoSave", 60, function()
            self:autoSaveAll()
        end)
    end

    -- Register update loop (if needed)
    if self.sgf.scheduler then
        self.sgf.scheduler:register("PlayerSystemUpdate", function(dt)
            self:Update(dt)
        end, self.sgf.scheduler.UpdatePriority.NORMAL)
    end

    self.state = "started"
    self.log:info("[PlayerSystemServer] Started successfully")
    return true
end
```

---

## Phase 5: Update (Optional)

### Purpose
Frame-by-frame updates. Only implement if needed.

### What to do
- Position updates
- State checks
- Animation updates
- **Most systems don't need this**

### Example

```lua
function PlayerSystemServer:Update(dt)
    -- Example: Check player positions
    for playerId, playerData in pairs(self.data.players) do
        if playerData.character then
            local pos = playerData.character.Position
            self:checkBoundaries(playerId, pos)
        end
    end
end
```

---

## Phase 6: Stop (Optional)

### Purpose
Clean up when system shuts down.

### What to do
- Save data
- Clean up timers
- Release resources

### Example

```lua
function PlayerSystemServer:Stop()
    self.log:info("[PlayerSystemServer] Stopping...")

    -- Save all player data
    for playerId, _ in pairs(self.data.players) do
        self:savePlayerData(playerId)
    end

    -- Unregister timers
    if self.sgf.scheduler then
        self.sgf.scheduler:unregister("PlayerSystemUpdate")
        self.sgf.scheduler:cancelSchedule("PlayerAutoSave")
    end

    -- Clean up data
    self.data.players = {}

    self.state = "stopped"
    return true
end
```

---

## Declaring Dependencies

### How to Declare

```lua
local DoorSystemServer = {
    name = "DoorSystemServer",
    version = "1.0.0",

    -- Declare dependencies here
    dependencies = {"PlayerSystemServer", "InventorySystemServer"}
}
```

### Why Dependencies Matter

The BusinessSystemManager uses dependencies to:
1. **Calculate initialization order** (topological sort)
2. **Ensure dependencies are initialized first**
3. **Detect circular dependencies**

---

## Dependency Resolution Pattern

### Complete Example

```lua
--[[
    DoorSystemServer - Depends on PlayerSystem and InventorySystem
]]

local DoorSystemServer = {
    name = "DoorSystemServer",
    dependencies = {"PlayerSystemServer", "InventorySystemServer"},

    -- Cache for dependency references
    dependencies_cache = {}
}

-- Phase 1: PreInit - Register events (NO system access)
function DoorSystemServer:PreInit()
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    self.events:on(EventID.PlayerJoined, function(data)
        self:onPlayerJoined(data)
    end)

    return true
end

-- Phase 2: Init - Initialize self (NO system access)
function DoorSystemServer:Init()
    self.config = {
        defaultOpenDuration = 2.0
    }

    self.data.doors = {}

    self:registerNetworkHandlers()
    return true
end

-- Phase 3: PostInit - Resolve dependencies (NOW safe to access systems)
function DoorSystemServer:PostInit()
    -- Get dependency references
    self.dependencies_cache.PlayerSystem =
        self.sgf.businessSystemManager:get("PlayerSystemServer")

    self.dependencies_cache.InventorySystem =
        self.sgf.businessSystemManager:get("InventorySystemServer")

    -- Validate dependencies exist
    if not self.dependencies_cache.PlayerSystem then
        self.log:error("[DoorSystem] Missing PlayerSystemServer")
        return false
    end

    if not self.dependencies_cache.InventorySystem then
        self.log:error("[DoorSystem] Missing InventorySystemServer")
        return false
    end

    self.log:info("[DoorSystem] Dependencies resolved")
    return true
end

-- Phase 4: Start - Use dependencies safely
function DoorSystemServer:Start()
    -- Can now safely call methods on dependencies
    local playerCount = self.dependencies_cache.PlayerSystem:getPlayerCount()
    self.log:info("[DoorSystem] Started", {playerCount = playerCount})

    return true
end

-- Using dependencies in game logic
function DoorSystemServer:tryOpenDoor(userId, doorId)
    local door = self.data.doors[doorId]
    if not door then return false end

    -- Check player level (using PlayerSystem dependency)
    local playerData = self.dependencies_cache.PlayerSystem:getPlayerData(userId)
    if not playerData then return false end

    if playerData.level < door.requiredLevel then
        return false, "Level too low"
    end

    -- Check if player has key (using InventorySystem dependency)
    if door.requiresKey then
        local hasKey = self.dependencies_cache.InventorySystem:hasItem(userId, door.keyItemId)
        if not hasKey then
            return false, "Missing key"
        end
    end

    -- Open door
    door.isOpen = true
    return true
end

return DoorSystemServer
```

---

## Initialization Order Examples

### Example 1: Simple Chain

```lua
-- System declarations
PlayerSystemServer.dependencies = {}
LevelSystemServer.dependencies = {"PlayerSystemServer"}

-- Initialization order:
-- 1. PlayerSystemServer (no dependencies)
-- 2. LevelSystemServer (depends on PlayerSystem)
```

### Example 2: Complex Dependencies

```lua
-- System declarations
PlayerSystemServer.dependencies = {}
InventorySystemServer.dependencies = {"PlayerSystemServer"}
CombatSystemServer.dependencies = {"PlayerSystemServer", "InventorySystemServer"}
QuestSystemServer.dependencies = {"PlayerSystemServer", "CombatSystemServer"}

-- Initialization order (calculated automatically):
-- 1. PlayerSystemServer (no dependencies)
-- 2. InventorySystemServer (depends on PlayerSystem)
-- 3. CombatSystemServer (depends on PlayerSystem and InventorySystem)
-- 4. QuestSystemServer (depends on PlayerSystem and CombatSystem)
```

---

## Circular Dependency Detection

### What is a Circular Dependency?

```lua
-- ❌ BAD: Circular dependency
SystemA.dependencies = {"SystemB"}
SystemB.dependencies = {"SystemA"}

-- Error: Circular dependency detected: SystemA → SystemB → SystemA
```

### Solution: Use Events Instead

```lua
-- ✅ GOOD: Break circular dependency with events
SystemA.dependencies = {}
SystemB.dependencies = {}

-- SystemA emits event
function SystemA:doSomething()
    self.events:emit(EventID.SystemAAction, {data = "foo"})
end

-- SystemB listens for event
function SystemB:PreInit()
    self.events:on(EventID.SystemAAction, function(data)
        self:handleSystemAAction(data)
    end)
end
```

---

## Common Patterns

### Pattern 1: Optional Dependencies

```lua
function MySystem:PostInit()
    -- Get optional dependency
    self.dependencies_cache.OptionalSystem =
        self.sgf.businessSystemManager:get("OptionalSystem")

    -- Don't fail if missing
    if not self.dependencies_cache.OptionalSystem then
        self.log:warn("[MySystem] Optional dependency missing")
    end

    return true
end

function MySystem:doSomething()
    -- Check before using
    if self.dependencies_cache.OptionalSystem then
        self.dependencies_cache.OptionalSystem:doStuff()
    end
end
```

### Pattern 2: Late Binding

```lua
function MySystem:useDependency()
    -- Look up dependency when needed (not cached)
    local system = self.sgf.businessSystemManager:get("SomeSystem")

    if system then
        system:doSomething()
    end
end
```

### Pattern 3: Dependency Validation

```lua
function MySystem:PostInit()
    -- Required dependencies
    local requiredSystems = {"PlayerSystem", "LevelSystem"}

    for _, systemName in ipairs(requiredSystems) do
        local system = self.sgf.businessSystemManager:get(systemName)

        if not system then
            self.log:error("[MySystem] Missing required system:", systemName)
            return false
        end

        self.dependencies_cache[systemName] = system
    end

    return true
end
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Accessing Systems in Init

```lua
-- ❌ WRONG: Accessing other system in Init
function MySystem:Init()
    local otherSystem = self.sgf.businessSystemManager:get("OtherSystem")
    otherSystem:doSomething()  -- OtherSystem might not be Init'd yet!
end

-- ✅ CORRECT: Access in PostInit or Start
function MySystem:PostInit()
    self.dependencies_cache.OtherSystem =
        self.sgf.businessSystemManager:get("OtherSystem")
end

function MySystem:Start()
    self.dependencies_cache.OtherSystem:doSomething()  -- Safe now
end
```

### ❌ Mistake 2: Not Declaring Dependencies

```lua
-- ❌ WRONG: Using system without declaring
MySystem.dependencies = {}  -- Empty!

function MySystem:PostInit()
    -- Using undeclared dependency
    self.dependencies_cache.LevelSystem =
        self.sgf.businessSystemManager:get("LevelSystemServer")
end

-- ✅ CORRECT: Declare all dependencies
MySystem.dependencies = {"LevelSystemServer"}
```

### ❌ Mistake 3: Not Returning from Lifecycle Methods

```lua
-- ❌ WRONG: No return value
function MySystem:Init()
    -- Do stuff
    -- Missing return!
end

-- ✅ CORRECT: Always return boolean
function MySystem:Init()
    -- Do stuff
    return true  -- Indicate success
end
```

### ❌ Mistake 4: Circular Dependencies

```lua
-- ❌ WRONG: Circular dependency
PlayerSystem.dependencies = {"CombatSystem"}
CombatSystem.dependencies = {"PlayerSystem"}

-- ✅ CORRECT: Use events to break cycle
PlayerSystem.dependencies = {}
CombatSystem.dependencies = {"PlayerSystem"}

-- PlayerSystem emits events, CombatSystem listens
```

---

## Best Practices

### 1. Cache Dependency References

```lua
-- ✅ GOOD: Cache in PostInit
function MySystem:PostInit()
    self.dependencies_cache.PlayerSystem =
        self.sgf.businessSystemManager:get("PlayerSystemServer")
end

function MySystem:doSomething()
    self.dependencies_cache.PlayerSystem:getData()  -- Use cache
end

-- ❌ BAD: Look up every time
function MySystem:doSomething()
    local playerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
    playerSystem:getData()  -- Slow!
end
```

### 2. Validate Dependencies

```lua
-- ✅ GOOD: Validate and handle missing dependencies
function MySystem:PostInit()
    self.dependencies_cache.LevelSystem =
        self.sgf.businessSystemManager:get("LevelSystemServer")

    if not self.dependencies_cache.LevelSystem then
        self.log:error("[MySystem] Missing LevelSystemServer")
        return false  -- Fail initialization
    end

    return true
end
```

### 3. Document Dependencies

```lua
-- ✅ GOOD: Document why each dependency is needed
--[[
    MySystem - Example system

    Dependencies:
    - PlayerSystemServer: Required for player data access
    - LevelSystemServer: Required for level-up calculations
    - InventorySystemServer: Optional for item-related features
]]
local MySystem = {
    dependencies = {"PlayerSystemServer", "LevelSystemServer"}
}
```

### 4. Minimize Dependencies

```lua
-- ✅ GOOD: Only declare true dependencies
MySystem.dependencies = {"PlayerSystemServer"}  -- Only what we need

-- ❌ BAD: Too many dependencies
MySystem.dependencies = {
    "PlayerSystemServer",
    "LevelSystemServer",
    "InventorySystemServer",
    "CombatSystemServer",
    "QuestSystemServer",
    "NPCSystemServer"
}  -- Hard to maintain!
```

---

## Quick Reference Card

```lua
-- System lifecycle template
local MySystem = {}

-- Declare dependencies
MySystem.dependencies = {"OtherSystemServer"}
MySystem.dependencies_cache = {}

-- Phase 1: PreInit - Register event listeners (NO system access)
function MySystem:PreInit()
    self.events:on(EventID.SomeEvent, function(data)
        self:onEvent(data)
    end)
    return true
end

-- Phase 2: Init - Load config, register network (NO system access)
function MySystem:Init()
    self.config = {}
    self:registerNetworkHandlers()
    return true
end

-- Phase 3: PostInit - Resolve dependencies (NOW safe to access systems)
function MySystem:PostInit()
    self.dependencies_cache.OtherSystem =
        self.sgf.businessSystemManager:get("OtherSystemServer")

    if not self.dependencies_cache.OtherSystem then
        return false
    end

    return true
end

-- Phase 4: Start - Begin operations (safe to use dependencies)
function MySystem:Start()
    self.dependencies_cache.OtherSystem:doSomething()
    return true
end

-- Phase 5: Update - Frame updates (optional)
function MySystem:Update(dt) end

-- Phase 6: Stop - Clean up (optional)
function MySystem:Stop() return true end

return MySystem
```

---

## See Also

- [how-to-setup-sgf-framework.md](./how-to-setup-sgf-framework.md) - Framework initialization
- [how-to-create-business-system.md](./how-to-create-business-system.md) - Creating systems
- [how-to-use-event-bus.md](./how-to-use-event-bus.md) - Event-driven communication

---

**Created**: 2025-10-31
**Version**: 1.0.0
**Based on**: rpg-gamedemo sample and scene-workflow-stage-4.md
