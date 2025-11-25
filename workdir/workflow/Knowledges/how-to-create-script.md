# How to Create Scripts in MiniWorld Studio

## Overview

This guide covers all script types in MiniWorld Studio, their purposes, locations, and how to create them properly. Scripts are the foundation of game logic, enabling client-server communication, UI interaction, and gameplay systems.

---

## 🚨 CRITICAL: require() Only Works with ModuleScript

⚠️ **MOST COMMON MISTAKE**: Using `require()` on a LocalScript or Script

### The Rule

**`require()` ONLY works with `ClassType: "ModuleScript"`**

```lua
-- ❌ WRONG: Cannot require a LocalScript or Script
local MySystem = require(StarterPlayerScripts.MyLocalScript)  -- ERROR!

-- ✅ CORRECT: Can only require ModuleScript
local MySystem = require(StarterPlayerScripts.MyModuleScript)  -- Works!
```

### The Correct Pattern

**Pattern 1: Module with Initialization**

```lua
-- MySystem.lua (ClassType: "ModuleScript")
local MySystem = {}

function MySystem:init()
    -- Initialization code
end

function MySystem:doSomething()
    -- System logic
end

return MySystem
```

```lua
-- MySystemInit.lua (ClassType: "LocalScript")
local StarterPlayerScripts = game:GetService("StartPlayer").StarterPlayerScripts
local MySystem = require(StarterPlayerScripts.MySystem)

MySystem:init()
print("System initialized!")
```

**Pattern 2: Direct Auto-Execution (No require)**

```lua
-- MyScript.lua (ClassType: "LocalScript")
-- No require needed - just write the code directly

local Players = game:GetService("Players")
print("Script running automatically!")

-- Your code here...
```

### Quick Reference

| Want to... | Use ClassType | Can require()? | Auto-runs? |
|-----------|--------------|----------------|------------|
| Create reusable module | `ModuleScript` | ✅ Yes | ❌ No |
| Auto-run client code | `LocalScript` | ❌ No | ✅ Yes |
| Auto-run server code | `Script` | ❌ No | ✅ Yes |

**Remember**: If you need to `require()` it, it **MUST** be a ModuleScript!

---

## Script Types Summary

| Script Type | Execution | Context | Auto-Run | Common Location |
|-------------|-----------|---------|----------|-----------------|
| **Script** | Server-side | Server | ✅ Yes | `ServerScriptService/` |
| **LocalScript** | Client-side | Client | ✅ Yes | `StartPlayer/StarterPlayerScripts/` |
| **ModuleScript** | Both | Both | ❌ No (require only) | `MainStorage/`, `systems/`, `config/` |
| **RemoteEvent** | Communication | Both | N/A | `MainStorage/` |
| **RemoteFunction** | Communication | Both | N/A | `MainStorage/` |
| **TriggerBox** | Event trigger | Both | N/A | `WorkSpace/` |

---

## 1. Script (Server-Side Script)

### Description
Server scripts run on the game server and handle authoritative game logic, data persistence, security validation, and server-side events.

### Characteristics
- **Runs automatically**: Yes, when placed in `ServerScriptService`
- **Execution context**: Server only
- **Can access**: Server APIs, all game objects, player data
- **Cannot access**: Client UI directly, local player input
- **Use cases**: Game state management, player data, matchmaking, anti-cheat

### File Structure

**Lua File** (`ServerInit.lua`):
```lua
-- Server-side initialization script
print("Server script starting...")

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load server systems
local PlayerDataSystem = require(ServerScriptService.systems.PlayerDataSystem)
local GameStateSystem = require(ServerScriptService.systems.GameStateSystem)

-- Initialize systems
PlayerDataSystem:init()
GameStateSystem:init()

-- Start systems
PlayerDataSystem:start()
GameStateSystem:start()

-- Handle player joining
Players.PlayerAdded:Connect(function(playerUIN)
    print("Player joined:", playerUIN)
    PlayerDataSystem:onPlayerJoined(playerUIN)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(playerUIN)
    print("Player leaving:", playerUIN)
    PlayerDataSystem:onPlayerLeaving(playerUIN)
end)

print("Server initialized successfully")
```

**JSON Configuration** (`ServerInit.json`):
```json
{
  "ClassType": "Script",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ServerInit",
  "reflex": [
    {"Name": "ServerInit"},
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

### Best Practices
- ✅ Place in `ServiceNodes/ServerScriptService/`
- ✅ Use for authoritative game logic only
- ✅ Validate all data from clients
- ✅ Never trust client input
- ✅ Use RemoteEvents/RemoteFunctions for client communication
- ❌ Don't manipulate client UI
- ❌ Don't store sensitive data in client-accessible locations

---

## 2. LocalScript (Client-Side Script)

### Description
LocalScripts run on each player's client and handle UI interaction, local input, visual effects, and client-side game experience.

### Characteristics
- **Runs automatically**: Yes, when placed in `StarterPlayerScripts`
- **Execution context**: Client only (per-player)
- **Can access**: Client APIs, PlayerGui, local player, UserInputService
- **Cannot access**: Other players' clients, server authoritative data
- **Use cases**: UI handling, input processing, visual effects, local audio

### File Structure

**Lua File** (`ClientInit.lua`):
```lua
-- Client-side initialization script
print("Client script starting...")

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StartPlayer")
local localPlayer = Players.LocalPlayer

-- Wait for character to spawn
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
print("Character spawned:", character.Name)

-- Load client systems
local UISystem = require(StarterPlayer.StarterPlayerScripts.systems.UISystem)
local InputSystem = require(StarterPlayer.StarterPlayerScripts.systems.InputSystem)

-- Initialize systems
UISystem:init()
InputSystem:init()

-- Start systems
UISystem:start()
InputSystem:start()

-- Handle UI events
local playerGui = localPlayer.PlayerGui
local mainUI = playerGui:WaitForChild("DefaultUIMain")

print("Client initialized successfully")
```

**JSON Configuration** (`ClientInit.json`):
```json
{
  "ClassType": "LocalScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ClientInit",
  "reflex": [
    {"Name": "ClientInit"},
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

### Best Practices
- ✅ Place in `ServiceNodes/StartPlayer/StarterPlayerScripts/`
- ✅ Use for UI interaction and local input
- ✅ Access UI from `PlayerGui`, NOT `StarterGui`
- ✅ Handle visual effects and audio locally
- ✅ Use RemoteEvents to send data to server
- ❌ Don't trust client-side data for game logic
- ❌ Don't implement anti-cheat on client
- ❌ Don't store sensitive information

### Common Example: UI Event Handler

**Lua File** (`ButtonHandler.lua`):
```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Wait for UI to instantiate
wait(1)

local playerGui = localPlayer.PlayerGui
local mainUI = playerGui:FindFirstChild("DefaultUIMain", true)
local button = mainUI:FindFirstChild("MyButton", true)

-- Color states
local normalColor = ColorQuad.new(100, 200, 100, 255)
local pressedColor = ColorQuad.new(50, 150, 50, 255)

-- Handle button press
button.TouchBegin:Connect(function()
    button.FillColor = pressedColor
    print("Button pressed!")
end)

button.TouchEnd:Connect(function()
    button.FillColor = normalColor
end)

print("Button handler initialized")
```

**JSON Configuration** (`ButtonHandler.json`):
```json
{
  "ClassType": "LocalScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ButtonHandler",
  "reflex": [
    {"Name": "ButtonHandler"},
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

## 3. ModuleScript (Reusable Module)

### Description
ModuleScripts are reusable Lua modules that encapsulate logic, utilities, or data structures. They don't run automatically and must be loaded via `require()`.

⚠️ **CRITICAL**: ModuleScript is the **ONLY** ClassType that can be `require()`'d. LocalScript and Script **CANNOT** be `require()`'d!

### Characteristics
- **Runs automatically**: No - must be `require()`'d
- **Execution context**: Both client and server
- **Returns**: A table (usually) with functions and data
- **Can be required**: ✅ **YES** - This is the ONLY script type that works with `require()`
- **Use cases**: Utility libraries, game systems, shared data models, configuration

### File Structure

**Lua File** (`MathUtils.lua`):
```lua
-- Utility module for mathematical operations
local MathUtils = {}

-- Calculate distance between two 3D points
function MathUtils.distance3D(pos1, pos2)
    local dx = pos2.X - pos1.X
    local dy = pos2.Y - pos1.Y
    local dz = pos2.Z - pos1.Z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Clamp a value between min and max
function MathUtils.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Linear interpolation
function MathUtils.lerp(a, b, t)
    return a + (b - a) * MathUtils.clamp(t, 0, 1)
end

return MathUtils
```

**JSON Configuration** (`MathUtils.json`):
```json
{
  "ClassType": "ModuleScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "MathUtils",
  "reflex": [
    {"Name": "MathUtils"},
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

### Usage Example
```lua
-- In another script (client or server)
local MainStorage = game:GetService("MainStorage")
local MathUtils = require(MainStorage.framework.utils.MathUtils)

-- Use the module
local distance = MathUtils.distance3D(
    Vector3.new(0, 0, 0),
    Vector3.new(10, 0, 0)
)
print("Distance:", distance)  -- Output: Distance: 10

local clamped = MathUtils.clamp(150, 0, 100)
print("Clamped:", clamped)  -- Output: Clamped: 100
```

### Module Locations

| Module Type | Location | Purpose |
|-------------|----------|---------|
| **Client Systems** | `StartPlayer/StarterPlayerScripts/systems/` | Client-side game systems |
| **Server Systems** | `ServerScriptService/systems/` | Server-side game systems |
| **UI Panels** | `StartPlayer/StarterPlayerScripts/ui/` | UI panel controllers |
| **Shared Models** | `MainStorage/shared/models/` | Data models shared between client/server |
| **Framework Core** | `MainStorage/framework/core/` | Core framework components |
| **Framework Services** | `MainStorage/framework/services/` | Framework services |
| **Utilities** | `MainStorage/framework/utils/` | Utility functions |
| **Configuration** | `MainStorage/config/` | Game configuration data |

### Best Practices
- ✅ Always return a table from the module
- ✅ Use local variables for state management
- ✅ Include error handling with pcall()
- ✅ Provide clear function names and documentation
- ✅ For game systems, include init(), start(), stop() methods
- ❌ Don't use global variables
- ❌ Don't forget to create matching JSON file
- ❌ Don't create circular dependencies

For more detailed ModuleScript examples, see [how-to-create-modulescript.md](./how-to-create-modulescript.md).

---

## 4. RemoteEvent (Asynchronous Communication)

### Description
RemoteEvents enable asynchronous communication between server and clients. They fire-and-forget with no return value.

### Characteristics
- **Direction**: Bidirectional (server ↔ client)
- **Return value**: None (fire-and-forget)
- **Use cases**: State updates, notifications, events without return values

### File Structure

**JSON Configuration Only** (No Lua file needed):
```json
{
  "ClassType": "RemoteEvent",
  "attribute": [],
  "flags": 0,
  "realNodeName": "PlayerScoreChanged",
  "reflex": [
    {"Name": "PlayerScoreChanged"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0}
  ]
}
```

### Usage Example

**Server Script** (sending to clients):
```lua
-- In ServerScriptService/ServerInit.lua
local MainStorage = game:GetService("MainStorage")
local scoreEvent = MainStorage:WaitForChild("PlayerScoreChanged")

-- Fire to all clients
scoreEvent:FireAllClients(playerUIN, newScore)

-- Fire to specific client
scoreEvent:FireClient(targetPlayerUIN, playerUIN, newScore)

-- Listen for client events
scoreEvent.OnServerEvent:Connect(function(senderUIN, data)
    print("Received from client:", senderUIN, data)
    -- Validate data here!
end)
```

**Client Script** (sending to server / receiving):
```lua
-- In StarterPlayerScripts/ClientInit.lua
local MainStorage = game:GetService("MainStorage")
local scoreEvent = MainStorage:WaitForChild("PlayerScoreChanged")

-- Listen for server events
scoreEvent.OnClientEvent:Connect(function(playerUIN, newScore)
    print("Player", playerUIN, "score updated to", newScore)
    -- Update UI here
end)

-- Send to server
scoreEvent:FireServer("collect_coin", { coinId = 123 })
```

### Best Practices
- ✅ Place in `ServiceNodes/MainStorage/`
- ✅ Use descriptive names (e.g., `PlayerScoreChanged`, `ItemCollected`)
- ✅ Always validate data on server when receiving from clients
- ✅ Use for events that don't need return values
- ❌ Don't send sensitive data from client to server without validation
- ❌ Don't use for operations that need immediate response (use RemoteFunction)

---

## 5. RemoteFunction (Synchronous Communication)

### Description
RemoteFunctions enable synchronous communication between server and clients with return values. The caller waits for the response.

### Characteristics
- **Direction**: Bidirectional (server ↔ client)
- **Return value**: Yes (caller waits for response)
- **Use cases**: Data queries, requests requiring immediate response

### File Structure

**JSON Configuration Only**:
```json
{
  "ClassType": "RemoteFunction",
  "attribute": [],
  "flags": 0,
  "realNodeName": "GetPlayerData",
  "reflex": [
    {"Name": "GetPlayerData"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0}
  ]
}
```

### Usage Example

**Server Script** (handling client requests):
```lua
-- In ServerScriptService/ServerInit.lua
local MainStorage = game:GetService("MainStorage")
local getDataFunc = MainStorage:WaitForChild("GetPlayerData")

-- Handle client requests
getDataFunc.OnServerInvoke = function(callerUIN, dataType)
    print("Client", callerUIN, "requested", dataType)

    -- Validate request
    if dataType == "score" then
        return PlayerDataSystem:getPlayerScore(callerUIN)
    elseif dataType == "inventory" then
        return PlayerDataSystem:getPlayerInventory(callerUIN)
    else
        print("Invalid data type requested:", dataType)
        return nil
    end
end
```

**Client Script** (calling server):
```lua
-- In StarterPlayerScripts/ClientInit.lua
local MainStorage = game:GetService("MainStorage")
local getDataFunc = MainStorage:WaitForChild("GetPlayerData")

-- Request data from server (blocks until response)
local score = getDataFunc:InvokeServer("score")
print("My score:", score)

local inventory = getDataFunc:InvokeServer("inventory")
print("My inventory:", inventory)
```

### Best Practices
- ✅ Place in `ServiceNodes/MainStorage/`
- ✅ Use for operations that need immediate response
- ✅ Always validate requests on server
- ✅ Handle errors with pcall()
- ✅ Set reasonable timeouts
- ❌ Don't use for frequent/high-volume requests (causes lag)
- ❌ Don't call from client to server in tight loops
- ❌ Don't trust client data without validation

### ⚠️ Important: RemoteFunction Blocking Behavior
```lua
-- ❌ WRONG: This will block the script
local result = remoteFunc:InvokeServer(data)
-- Script waits here until server responds
processResult(result)

-- ✅ BETTER: Use coroutine for long operations
coroutine.wrap(function()
    local result = remoteFunc:InvokeServer(data)
    processResult(result)
end)()
```

---

## 6. TriggerBox (Area Trigger)

### Description
TriggerBoxes detect when players or objects enter, stay in, or leave a defined 3D area, triggering events accordingly.

### Characteristics
- **Type**: Spatial event trigger
- **Events**: OnEnter, OnStay, OnLeave
- **Use cases**: Checkpoints, zones, area-based events, teleporters

### File Structure

**JSON Configuration** (TriggerBox is defined in JSON only):
```json
{
  "ClassType": "TriggerBox",
  "attribute": [
    {
      "name": "Priority",
      "type": 1,
      "value": 1
    },
    {
      "name": "TriggerData",
      "type": 3,
      "value": "SafeZone"
    },
    {
      "name": "TriggerType",
      "type": 3,
      "value": "SafetyArea"
    }
  ],
  "flags": 0,
  "realNodeName": "SafeZoneTrigger",
  "reflex": [
    {"Name": "SafeZoneTrigger"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"LocalPosition": [0, 100, 0]},
    {"LocalScale": [1, 1, 1]},
    {"LocalRotation": [0, 0, 0, 1]},
    {"Visible": true},
    {"Size": [1000, 500, 1000]},
    {"KinematicAble": true},
    {"GravityAble": false}
  ]
}
```

### Usage Example

**Server Script** (handling trigger events):
```lua
-- In ServerScriptService/ServerInit.lua
local WorkSpace = game:GetService("WorkSpace")
local safeTrigger = WorkSpace:FindFirstChild("SafeZoneTrigger", true)

-- Player enters safe zone
safeTrigger.OnEnter:Connect(function(player)
    print("Player", player.Name, "entered safe zone")
    player.Character.Health = player.Character.MaxHealth  -- Heal
    -- Set player as invulnerable
end)

-- Player stays in safe zone
safeTrigger.OnStay:Connect(function(player, deltaTime)
    -- Continuously heal while in zone
    local character = player.Character
    if character and character.Health < character.MaxHealth then
        character.Health = math.min(
            character.MaxHealth,
            character.Health + 5 * deltaTime
        )
    end
end)

-- Player leaves safe zone
safeTrigger.OnLeave:Connect(function(player)
    print("Player", player.Name, "left safe zone")
    -- Remove invulnerability
end)
```

### TriggerBox Properties

| Property | Type | Description |
|----------|------|-------------|
| `Size` | `[x, y, z]` | Dimensions of trigger area (centimeters) |
| `LocalPosition` | `[x, y, z]` | Position in world space |
| `Priority` | number | Trigger priority (higher = first) |
| `TriggerType` | string | Custom type identifier |
| `TriggerData` | string | Custom data payload |
| `KinematicAble` | boolean | Can move (default: true for triggers) |
| `GravityAble` | boolean | Affected by gravity (default: false for triggers) |

### Best Practices
- ✅ Place in `ServiceNodes/WorkSpace/`
- ✅ Use descriptive names and TriggerType
- ✅ Set appropriate Size for the area
- ✅ Use Priority for overlapping triggers
- ✅ Handle OnEnter and OnLeave for state changes
- ❌ Don't make triggers too small (hard to trigger)
- ❌ Don't use OnStay for infrequent checks (performance)

---

## Complete Directory Structure

```
ServiceNodes/
├── ServerScriptService/                # Server-side scripts
│   ├── ServerInit.lua                  # Main server initialization (Script)
│   ├── ServerInit.json
│   └── systems/                        # Server game systems
│       ├── PlayerDataSystem.lua        # (ModuleScript)
│       ├── PlayerDataSystem.json
│       ├── GameStateSystem.lua
│       └── GameStateSystem.json
│
├── StartPlayer/
│   └── StarterPlayerScripts/           # Client-side scripts
│       ├── ClientInit.lua              # Main client initialization (LocalScript)
│       ├── ClientInit.json
│       ├── ButtonHandler.lua           # UI handlers (LocalScript)
│       ├── ButtonHandler.json
│       ├── systems/                    # Client game systems
│       │   ├── UISystem.lua            # (ModuleScript)
│       │   ├── UISystem.json
│       │   ├── InputSystem.lua
│       │   └── InputSystem.json
│       └── ui/                         # UI panel modules
│           ├── MainMenuPanel.lua       # (ModuleScript)
│           └── MainMenuPanel.json
│
├── MainStorage/                        # Shared modules and communication
│   ├── framework/                      # Framework modules
│   │   ├── core/
│   │   ├── services/
│   │   └── utils/
│   │       ├── MathUtils.lua           # (ModuleScript)
│   │       └── MathUtils.json
│   ├── config/                         # Configuration modules
│   │   ├── GameConfig.lua              # (ModuleScript)
│   │   └── GameConfig.json
│   ├── shared/                         # Shared data models
│   │   └── models/
│   │       ├── PlayerModel.lua         # (ModuleScript)
│   │       └── PlayerModel.json
│   ├── PlayerScoreChanged.json         # RemoteEvent
│   └── GetPlayerData.json              # RemoteFunction
│
└── WorkSpace/                          # Game world and triggers
    └── Triggers/
        ├── SafeZoneTrigger.json        # TriggerBox
        └── CheckpointTrigger.json      # TriggerBox
```

---

## Quick Reference: When to Use Each Script Type

### Use **Script** when:
- Implementing server-side game logic
- Managing authoritative game state
- Handling player data persistence
- Validating client requests
- Running anti-cheat systems

### Use **LocalScript** when:
- Handling UI interactions
- Processing player input
- Creating visual effects
- Playing client-side audio
- Implementing camera controls

### Use **ModuleScript** when:
- Creating reusable utility functions
- Defining game systems (client or server)
- Sharing data models between scripts
- Organizing configuration data
- Building framework services

### Use **RemoteEvent** when:
- Notifying clients of state changes
- Broadcasting events to multiple players
- Sending fire-and-forget messages
- Events that don't need return values

### Use **RemoteFunction** when:
- Client needs to query server data
- Server needs immediate client response
- Operations requiring synchronous return values
- Data requests that can't be predicted

### Use **TriggerBox** when:
- Detecting player entering/leaving areas
- Creating checkpoints or safe zones
- Triggering area-based events
- Implementing invisible interactive regions

---

## Critical Rules

### 1. JSON Configuration Required
Every Lua script file MUST have a corresponding JSON configuration file with:
- Same filename (except extension)
- Correct ClassType for the script type
- Matching realNodeName

### 2. Script Locations

| Script Type | Location |
|-------------|----------|
| Server scripts | `ServerScriptService/` |
| Client scripts | `StartPlayer/StarterPlayerScripts/` |
| Shared modules | `MainStorage/` |
| Communication | `MainStorage/` |
| Triggers | `WorkSpace/` |

### 3. Common JSON Template

For Script, LocalScript, and ModuleScript:
```json
{
  "ClassType": "<Script|LocalScript|ModuleScript>",
  "attribute": [],
  "flags": 0,
  "realNodeName": "<ScriptName>",
  "reflex": [
    {"Name": "<ScriptName>"},
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

## Common Mistakes to Avoid

| Mistake | Problem | Solution |
|---------|---------|----------|
| **🚨 Using `require()` on LocalScript/Script** | **Error: "require error! param [1] need Module Script!!"** | **Change ClassType to "ModuleScript" in JSON file** |
| Wrong ClassType | Script won't execute or behaves incorrectly | Use correct ClassType (Script/LocalScript/ModuleScript) |
| ModuleScript in wrong location | Can't `require()` the module | Place in MainStorage/ or systems/ |
| Missing JSON file | Script won't load in MiniWorld Studio | Always create matching JSON |
| Using Script for UI | Server can't access client UI | Use LocalScript instead |
| Using LocalScript for game logic | Clients can cheat | Use Script on server |
| Trusting client data | Security vulnerability | Always validate on server |
| UI in StarterGui | FindFirstChild returns nil at runtime | Access from PlayerGui |
| Blocking RemoteFunction calls | Lag and poor performance | Use sparingly, prefer RemoteEvent |
| Too many TriggerBox OnStay | Performance issues | Use OnEnter/OnLeave when possible |
| Using `spawn()` | Function doesn't exist in MiniWorld | Use `coroutine` carefully or avoid |
| Coroutines with infinite loops | Blocks script execution | Avoid background loops; use event-driven design |

### 🚨 Most Common Error: require() on Wrong ClassType

This is the **#1 most common mistake** when creating scripts:

```lua
-- ❌ ERROR: Trying to require a LocalScript
-- JSON file has: "ClassType": "LocalScript"
local MySystem = require(StarterPlayerScripts.MySystem)
-- Result: "require error! param [1] need Module Script!!"

-- ✅ SOLUTION 1: Change JSON to ModuleScript
-- JSON file should have: "ClassType": "ModuleScript"
local MySystem = require(StarterPlayerScripts.MySystem)  -- Now works!

-- ✅ SOLUTION 2: Don't use require, make it auto-execute
-- Keep JSON as "ClassType": "LocalScript"
-- Just write your code directly - no require needed
-- The script will run automatically
```

**Remember**: `require()` ONLY works with `"ClassType": "ModuleScript"`!

---

## Critical Differences from Roblox

⚠️ **MiniWorld Studio is NOT Roblox!** Many Roblox patterns don't work here. Key differences:

### 1. No `spawn()` Function

**Problem**: Roblox's `spawn()` doesn't exist in MiniWorld Studio
```lua
-- ❌ WRONG (Roblox pattern)
spawn(function()
    while true do
        wait(1)
        updateSomething()
    end
end)
```

**Solution 1**: Use `coroutine` carefully (can block if not yielding properly)
```lua
-- ⚠️ USE WITH CAUTION: Ensure proper yielding
coroutine.wrap(function()
    while true do
        wait(1)
        updateSomething()
    end
end)()
```

**Solution 2**: Event-driven design (recommended)
```lua
-- ✅ BETTER: Update on events, not continuous loops
button.Click:Connect(function()
    updateSomething()  -- Only when needed
end)
```

### 2. Coroutines Can Block Execution

**Problem**: Infinite loops in coroutines prevent script from completing

⚠️ **Note**: Coroutines are OK for single async operations (see RemoteFunction section), but NOT for infinite background loops.

```lua
-- ❌ WRONG: Infinite loop blocks the main script
coroutine.wrap(function()
    while true do
        wait(2)
        if visible then
            update()
        end
    end
end)()

print("This line never executes!")  -- Script blocked above

-- ✅ OK: Single async operation (doesn't block)
coroutine.wrap(function()
    local result = remoteFunc:InvokeServer(data)
    processResult(result)
end)()

print("This executes immediately")  -- Not blocked
```

**Solution**: Avoid infinite `while true` loops in coroutines; use event-driven updates
```lua
-- ✅ CORRECT: Event-driven approach
local function update()
    -- Update logic here
end

-- Update when needed
showButton.Click:Connect(function()
    panel.Visible = true
    update()  -- Update immediately when shown
end)
```

### 3. No `warn()` Function
**Solution**: Use `print`


📘 **For comprehensive information on update mechanisms**, including `RunService.Stepped`, frame-based updates, timers, and the UpdateManager pattern, see **[Common Script Update Mechanisms](common-script-update.md)**.

### 3. UI Access: PlayerGui vs StarterGui

**Critical Rule**: At runtime, UI lives in `PlayerGui`, NOT `StarterGui`

```lua
-- ❌ WRONG: Accessing StarterGui at runtime
local StarterGui = game:GetService("StarterGui")
local button = StarterGui:FindFirstChild("MyButton")  -- Returns nil!

-- ✅ CORRECT: Access from PlayerGui
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)
local button = uiRoot:FindFirstChild("MyButton", true)  -- Works!
```

**Why the difference?**
- **StarterGui** (JSON files): UI *definition* - where you create UI
- **PlayerGui** (runtime): UI *instance* - where UI actually exists during gameplay
- MiniWorld automatically copies UI from StarterGui to PlayerGui when player joins

### 4. Parent-Relative Positioning

**Critical Concept**: Child UI elements use coordinates relative to their parent's top-left corner, NOT the screen.

```lua
-- Panel at screen position (10, 90), size 250×450
local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Position = Vector2.new(10, 90)
panel.Size = Vector2.new(250, 450)

-- ❌ WRONG: Using screen coordinates for child
local label = SandboxNode.new('UITextLabel', panel)
label.Position = Vector2.new(135, 115)  -- Thinks this is screen position
-- Actual position: (10+135, 90+115) = (145, 205) - NOT what you wanted!

-- ✅ CORRECT: Use parent-relative coordinates
label.Position = Vector2.new(125, 25)  -- 125px from panel's left, 25px from top
label:SetParent(panel)
-- Actual position: (10+125, 90+25) = (135, 115) - Correct!
```

**Key Rules**:
- Child position is ALWAYS relative to parent's top-left (0, 0)
- Child must fit within parent bounds (child.x + child.width ≤ parent.width)
- Call `:SetParent(parentElement)` to establish hierarchy

**Example: Centering child in parent**
```lua
local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Size = Vector2.new(250, 450)

local title = SandboxNode.new('UITextLabel', panel)
title.Size = Vector2.new(230, 50)
-- Center horizontally: (panelWidth - childWidth) / 2 = (250 - 230) / 2 = 10
title.Position = Vector2.new(125, 30)  -- Center X, 30px from top
title.Pivot = Vector2.new(0.5, 0.5)     -- Use center pivot
title:SetParent(panel)
```

### 5. Color Format Differences

| Feature | Roblox | MiniWorld Studio |
|---------|--------|------------------|
| **Color Type** | `Color3.new(r, g, b)` | `ColorQuad.new(r, g, b, a)` |
| **Value Range** | 0-1 (decimal) | 0-255 (integer) + alpha |
| **Alpha Channel** | Separate property | Built into color |

```lua
-- ❌ Roblox pattern
element.BackgroundColor3 = Color3.new(1, 0.5, 0)  -- Won't work

-- ✅ MiniWorld Studio
element.FillColor = ColorQuad.new(255, 128, 0, 255)  -- RGBA 0-255
```

### 6. Text Property Names

| Feature | Roblox | MiniWorld Studio |
|---------|--------|------------------|
| **Text Content** | `Text = "Hello"` | `Title = "Hello"` |
| **Text Color** | `TextColor3` | `TitleColor` |
| **Font Size** | `TextSize` | `FontSize` or `TitleSize` |

### Quick Reference: Roblox vs MiniWorld

| Category | Roblox | MiniWorld Studio |
|----------|--------|------------------|
| Background tasks | `spawn(function() ... end)` | Event-driven or careful `coroutine` |
| UI runtime access | Can use StarterGui | **MUST** use PlayerGui |
| Colors | `Color3.new(0-1, 0-1, 0-1)` | `ColorQuad.new(0-255, 0-255, 0-255, 0-255)` |
| Text property | `Text` | `Title` |
| Text color | `TextColor3` | `TitleColor` |
| Size property | `UDim2` | `Vector2` |
| Anchor point | `AnchorPoint` | `Pivot` |
| Z-index | `ZIndex` | `RenderIndex` |

---

## See Also

- [common-script-update.md](common-script-update.md) - Update mechanisms, RunService.Stepped, timers, and UpdateManager pattern
- [how-to-add-ui.md](./how-to-add-ui.md) - UI creation and interaction
- [how-to-control-player.md](./how-to-control-player.md) - Player control systems
- [global-notes.md](./global-notes.md) - Global development constraints

---

## Quick Start Checklist

Creating a new script? Follow these steps:

1. **Determine script type** based on purpose (see "When to Use" section)
2. **Choose correct location** based on script type
3. **Create Lua file** with proper code structure
4. **Create matching JSON file** with correct ClassType
5. **Match realNodeName** to Lua filename (without .lua)
6. **Test in MiniWorld Studio** to verify it loads correctly

---

**Created**: 2025-10-20
**Last Updated**: 2025-10-23
**Version**: 1.1.0
**Based on**: MiniWorld Studio reference documentation and sample code analysis

**v1.1.0 Changes**: Added critical documentation for `require()` only working with ModuleScript ClassType
