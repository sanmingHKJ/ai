# How to Set Up SGF Framework in MiniWorld Studio

## Overview

The Studio Game Framework (SGF) is the foundation for organizing game code into business systems in MiniWorld Studio. This guide covers how to initialize and configure SGF for your game project, based on the production-ready patterns from the rpg-gamedemo sample.

**Common Use Cases**: Game initialization, framework setup, system management, project architecture

---

## What is SGF Framework?

SGF (Studio Game Framework) provides:
- **Business System Management**: Organize code into modular systems
- **Lifecycle Management**: Consistent initialization order (PreInit → Init → PostInit → Start)
- **Dependency Resolution**: Automatic ordering based on system dependencies
- **Event Bus**: Decoupled communication between systems
- **Service Container**: Access to shared services (logging, scheduling, etc.)
- **Network Helper**: Simplified client-server communication

---

## Framework Directory Structure

```
MainStorage/
└── Framework/
    ├── SGFFramework.lua              # Main framework entry point
    ├── Core/
    │   ├── BusinessSystemManager.lua # System lifecycle manager
    │   ├── EventBus.lua              # Event system
    │   ├── ServiceContainer.lua      # Dependency injection
    │   └── LogService.lua            # Logging
    ├── Runtime/
    │   ├── Protocol.lua              # Network message IDs
    │   └── EventID.lua               # Event definitions
    ├── GameSystems/                  # Your business systems
    │   ├── PlayerSystem/
    │   │   ├── PlayerSystemServer.lua
    │   │   └── PlayerSystemClient.lua
    │   └── LevelSystem/
    │       ├── LevelSystemServer.lua
    │       └── LevelSystemClient.lua
    ├── Config/                       # Configuration files
    │   └── Framework/
    │       └── MapConfig.lua
    └── UI/                           # UI framework
        ├── BasePanel.lua
        └── PanelManager.lua
```

---

## Server-Side Initialization

### Step 1: Create ServerMain.lua

**Location**: `ServiceNodes/ServerScriptService/ServerMain.lua`

```lua
--[[
    ServerMain.lua - Server entry point
    ClassType: Script (auto-runs on server start)
]]

print("[ServerMain] Server starting...")

-- Get services
local MainStorage = game:GetService("MainStorage")
local RunService = game:GetService("RunService")

-- Load SGF Framework
local SGFFramework = require(MainStorage.Framework.SGFFramework)

-- Create framework instance
local sgf = SGFFramework.new()

-- Initialize framework
sgf:Init({
    systems = {}  -- Legacy systems (optional)
})

print("[ServerMain] SGF Framework initialized")

-- Load business system modules
local PlayerSystemServer = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemServer)
local LevelSystemServer = require(MainStorage.Framework.GameSystems.LevelSystem.LevelSystemServer)

-- Create system instances
local playerSystem = PlayerSystemServer.new(sgf)
local levelSystem = LevelSystemServer.new(sgf)

-- Register systems with framework
sgf.businessSystemManager:register("PlayerSystemServer", playerSystem)
sgf.businessSystemManager:register("LevelSystemServer", levelSystem)

print("[ServerMain] Systems registered")

-- Initialize all systems (PreInit → Init → PostInit → Start)
local systemsToInit = {playerSystem, levelSystem}

-- Phase 1: PreInit
for _, system in ipairs(systemsToInit) do
    if system.PreInit then
        system:PreInit()
    end
end

-- Phase 2: Init
for _, system in ipairs(systemsToInit) do
    if system.Init then
        system:Init()
    end
end

-- Phase 3: PostInit (dependency resolution)
for _, system in ipairs(systemsToInit) do
    if system.PostInit then
        system:PostInit()
    end
end

-- Phase 4: Start
for _, system in ipairs(systemsToInit) do
    if system.Start then
        system:Start()
    end
end

print("[ServerMain] All systems started")

-- Main update loop
RunService.Stepped:Connect(function()
    sgf:Update(0.033)  -- ~30 FPS
end)

print("[ServerMain] Server initialized successfully")
```

**JSON Configuration** (`ServerMain.json`):
```json
{
  "ClassType": "Script",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ServerMain",
  "reflex": [
    {"Name": "ServerMain"},
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

**⚠️ CRITICAL**: ClassType must be `"Script"` (not ModuleScript) so it auto-runs on server startup.

---

## Client-Side Initialization

### Step 2: Create ClientMain.lua

**Location**: `ServiceNodes/StartPlayer/StarterPlayerScripts/ClientMain.lua`

```lua
--[[
    ClientMain.lua - Client entry point
    ClassType: LocalScript (auto-runs on client start)
]]

print("[ClientMain] Client starting...")

-- Get services
local MainStorage = game:GetService("MainStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Load SGF Framework
local SGFFramework = require(MainStorage.Framework.SGFFramework)

-- Create framework instance
local sgf = SGFFramework.new()

-- Initialize framework
sgf:Init({
    systems = {
        -- Register business system here, for example:
        -- "PlayerSystemClient",
        -- "CombatSystemClient",
        -- "SkillSystemClient",
        -- "InventorySystemClient",
    }
})

print("[ClientMain] SGF Framework initialized")

-- Load client systems
local PlayerSystemClient = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemClient)

-- Create system instances
local playerSystemClient = PlayerSystemClient.new(sgf)

-- Register systems
sgf.businessSystemManager:register("PlayerSystemClient", playerSystemClient)

-- Initialize systems (PreInit → Init → PostInit → Start)
local systemsToInit = {playerSystemClient}

for _, system in ipairs(systemsToInit) do
    if system.PreInit then system:PreInit() end
end

for _, system in ipairs(systemsToInit) do
    if system.Init then system:Init() end
end

for _, system in ipairs(systemsToInit) do
    if system.PostInit then system:PostInit() end
end

for _, system in ipairs(systemsToInit) do
    if system.Start then system:Start() end
end

print("[ClientMain] All systems started")

-- Initialize UI
local PanelManager = require(MainStorage.Framework.UI.PanelManager)
sgf.panelManager = PanelManager.new(sgf)

-- Register UI panels
local ResourcePanel = require(script.UI.ResourcePanel)
sgf.panelManager:register("ResourcePanel", ResourcePanel)
sgf.panelManager:create("ResourcePanel")

print("[ClientMain] UI initialized")

-- Main update loop (client uses RenderStepped)
RunService.RenderStepped:Connect(function(dt)
    sgf:Update(dt)
end)

-- Listen to UI Event, for example:
-- listen to open event of character panel
-- sgf.events:on("OpenCharacterPanel", function(data)
--     print("[ClientMain] Open character panel")
--     panelManager:show("CharacterPanel")
-- end)

-- Listen to Game Event, for example:
-- listen to update event of player data
-- sgf.events:on("PlayerDataUpdated", function(data)
--     print("[ClientMain] Player data updated:", data.playerData)
-- end)

-- Listen to scene change event
-- local EventID = require(MainStorage.Framework.Runtime.EventID)
-- sgf.events:on(EventID.SceneChangedClient, function(data)
--     print("[ClientMain] Scene changed to:", data.sceneName)
-- 
--     -- 调用SceneStateManager切换场景UI
--     if sceneStateManager then
--         sceneStateManager:switchSceneByName(data.sceneName)
--     end
-- end)


print("[ClientMain] Client initialized successfully")
```

**JSON Configuration** (`ClientMain.json`):
```json
{
  "ClassType": "LocalScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ClientMain",
  "reflex": [
    {"Name": "ClientMain"},
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

**⚠️ CRITICAL**: ClassType must be `"LocalScript"` (not ModuleScript) so it auto-runs on each client.

---

## Framework Configuration Options

### SGF:Init() Options

```lua
sgf:Init({
    -- Legacy GameFramework systems (optional)
    systems = {},

    -- Logging configuration
    logLevel = "info",  -- "debug", "info", "warn", "error"

    -- Framework modules
    modules = {
        network = true,
        scheduler = true,
        audio = true,
        effects = true
    }
})
```

---

## Accessing Framework Services

Once SGF is initialized, systems can access framework services:

```lua
function MySystem:Init(sgf, config)
    self.sgf = sgf

    -- Access logging service
    self.sgf.log:info("System initializing")
    self.sgf.log:debug("Debug info", {data = "value"})
    self.sgf.log:warn("Warning message")
    self.sgf.log:error("Error occurred")

    -- Access event bus
    self.sgf.events:emit("EventName", {data = "value"})
    self.sgf.events:on("EventName", function(data)
        -- Handle event
    end)

    -- Access business system manager
    local otherSystem = self.sgf.businessSystemManager:get("OtherSystemName")

    -- Access service container
    local customService = self.sgf.container:resolve("serviceName")
end
```

---

## Common Patterns

### Pattern 1: Minimal Server Setup

For simple games, you can start with just a few systems:

```lua
-- ServerMain.lua (minimal)
local MainStorage = game:GetService("MainStorage")
local SGFFramework = require(MainStorage.Framework.SGFFramework)

local sgf = SGFFramework.new()
sgf:Init({systems = {}})

-- Load only essential systems
local PlayerSystem = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemServer)
local playerSystem = PlayerSystem.new(sgf)

sgf.businessSystemManager:register("PlayerSystemServer", playerSystem)

-- Initialize
playerSystem:PreInit()
playerSystem:Init()
playerSystem:PostInit()
playerSystem:Start()

-- Update loop
local RunService = game:GetService("RunService")
RunService.Stepped:Connect(function()
    sgf:Update(0.033)
end)
```

### Pattern 2: System Registration Helper

Create a helper function to reduce boilerplate:

```lua
-- Helper function
local function registerAndInitSystem(sgf, systemName, systemModule)
    local system = systemModule.new(sgf)
    sgf.businessSystemManager:register(systemName, system)

    if system.PreInit then system:PreInit() end
    if system.Init then system:Init() end
    if system.PostInit then system:PostInit() end
    if system.Start then system:Start() end

    return system
end

-- Usage
local PlayerSystem = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemServer)
local LevelSystem = require(MainStorage.Framework.GameSystems.LevelSystem.LevelSystemServer)

local playerSystem = registerAndInitSystem(sgf, "PlayerSystemServer", PlayerSystem)
local levelSystem = registerAndInitSystem(sgf, "LevelSystemServer", LevelSystem)
```

### Pattern 3: Dynamic System Loading

Load systems based on configuration:

```lua
-- GameConfig.lua
local GameConfig = {
    enabledSystems = {
        "PlayerSystem",
        "LevelSystem",
        "SceneSystem"
    }
}

-- ServerMain.lua
local systemModules = {
    PlayerSystem = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemServer),
    LevelSystem = require(MainStorage.Framework.GameSystems.LevelSystem.LevelSystemServer),
    SceneSystem = require(MainStorage.Framework.GameSystems.SceneSystem.SceneSystemServer)
}

for _, systemName in ipairs(GameConfig.enabledSystems) do
    local systemModule = systemModules[systemName]
    if systemModule then
        local system = systemModule.new(sgf)
        sgf.businessSystemManager:register(systemName .. "Server", system)
        -- ... initialize
    end
end
```

---

## Real-World Example from rpg-gamedemo

**Source**: `PromptTpl/samplecode/rpg-gamedemo/ServiceNodes/ServerScriptService/ServerMain.lua`

```lua
local MainStorage = game:GetService("MainStorage")
local RunService = game:GetService("RunService")

-- Load framework
local SGFFramework = require(MainStorage.Framework.SGFFramework)
local sgf = SGFFramework.new()

sgf:Init({systems = {}})

-- Load all game systems
local PlayerSystemServer = require(MainStorage.Framework.GameSystems.PlayerSystem.PlayerSystemServer)
local LevelSystemServer = require(MainStorage.Framework.GameSystems.LevelSystem.LevelSystemServer)
local SceneSystemServer = require(MainStorage.Framework.GameSystems.SceneSystem.SceneSystemServer)
local NPCInteractionSystemServer = require(MainStorage.Framework.GameSystems.NPCInteractionSystem.NPCInteractionSystemServer)

-- Create instances
local playerSystem = PlayerSystemServer.new(sgf)
local levelSystem = LevelSystemServer.new(sgf)
local sceneSystem = SceneSystemServer.new(sgf)
local npcSystem = NPCInteractionSystemServer.new(sgf)

-- Register all systems
sgf.businessSystemManager:register("PlayerSystemServer", playerSystem)
sgf.businessSystemManager:register("LevelSystemServer", levelSystem)
sgf.businessSystemManager:register("SceneSystemServer", sceneSystem)
sgf.businessSystemManager:register("NPCInteractionSystemServer", npcSystem)

-- Initialize in phases
local systems = {playerSystem, levelSystem, sceneSystem, npcSystem}

for _, system in ipairs(systems) do
    if system.PreInit then system:PreInit() end
end

for _, system in ipairs(systems) do
    if system.Init then system:Init() end
end

for _, system in ipairs(systems) do
    if system.PostInit then system:PostInit() end
end

for _, system in ipairs(systems) do
    if system.Start then system:Start() end
end

-- Update loop
RunService.Stepped:Connect(function()
    sgf:Update(0.033)
end)
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Wrong ClassType for Entry Scripts

```lua
-- ❌ WRONG: ServerMain.json with "ModuleScript"
{
  "ClassType": "ModuleScript"  // Won't auto-run!
}

-- ✅ CORRECT: ServerMain.json with "Script"
{
  "ClassType": "Script"  // Auto-runs on server
}
```

### ❌ Mistake 2: Skipping Lifecycle Phases

```lua
-- ❌ WRONG: Only calling Init
playerSystem:Init()
playerSystem:Start()  // Dependencies not resolved!

-- ✅ CORRECT: All phases in order
playerSystem:PreInit()
playerSystem:Init()
playerSystem:PostInit()  // Resolves dependencies
playerSystem:Start()
```

### ❌ Mistake 3: Wrong Update Loop

```lua
-- ❌ WRONG: Using Heartbeat
RunService.Heartbeat:Connect(function(dt)
    sgf:Update(dt)
end)

-- ✅ CORRECT: Use Stepped for server
RunService.Stepped:Connect(function()
    sgf:Update(0.033)
end)

-- ✅ CORRECT: Use RenderStepped for client
RunService.RenderStepped:Connect(function(dt)
    sgf:Update(dt)
end)
```

### ❌ Mistake 4: Accessing Systems Before PostInit

```lua
-- ❌ WRONG: Trying to use dependency in Init
function MySystem:Init()
    local otherSystem = self.sgf.businessSystemManager:get("OtherSystem")
    otherSystem:doSomething()  // Other system might not be Init'd yet!
end

-- ✅ CORRECT: Access dependencies in PostInit
function MySystem:PostInit()
    self.otherSystem = self.sgf.businessSystemManager:get("OtherSystem")
end

function MySystem:Start()
    self.otherSystem:doSomething()  // Safe now
end
```

---

## Best Practices

### 1. Always Initialize in Correct Phase Order

```lua
-- ✅ GOOD: Clear phase separation
local systems = {playerSystem, levelSystem, sceneSystem}

-- PreInit: Register event listeners
for _, system in ipairs(systems) do
    if system.PreInit then system:PreInit() end
end

-- Init: Load configurations, register network handlers
for _, system in ipairs(systems) do
    if system.Init then system:Init() end
end

-- PostInit: Resolve dependencies
for _, system in ipairs(systems) do
    if system.PostInit then system:PostInit() end
end

-- Start: Begin operations
for _, system in ipairs(systems) do
    if system.Start then system:Start() end
end
```

### 2. Use Consistent Naming

```lua
-- ✅ GOOD: Clear naming convention
local PlayerSystemServer = require(...PlayerSystemServer)
local playerSystem = PlayerSystemServer.new(sgf)
sgf.businessSystemManager:register("PlayerSystemServer", playerSystem)

-- ❌ BAD: Inconsistent names
local PS = require(...PlayerSystemServer)
local pSys = PS.new(sgf)
sgf.businessSystemManager:register("PlayerSys", pSys)
```

### 3. Add Logging for Debugging

```lua
-- ✅ GOOD: Clear logging
print("[ServerMain] Server starting...")
sgf:Init({systems = {}})
print("[ServerMain] SGF initialized")

playerSystem:PreInit()
print("[ServerMain] PlayerSystem PreInit complete")

playerSystem:Init()
print("[ServerMain] PlayerSystem Init complete")
```

### 4. Handle Initialization Errors

```lua
-- ✅ GOOD: Check for initialization success
local success, err = pcall(function()
    playerSystem:Init()
end)

if not success then
    warn("[ServerMain] PlayerSystem Init failed:", err)
end
```

---

## Quick Reference Card

```lua
-- Server initialization template
local MainStorage = game:GetService("MainStorage")
local RunService = game:GetService("RunService")

-- 1. Load framework
local SGFFramework = require(MainStorage.Framework.SGFFramework)
local sgf = SGFFramework.new()
sgf:Init({systems = {}})

-- 2. Load systems
local MySystemServer = require(MainStorage.Framework.GameSystems.MySystem.MySystemServer)
local mySystem = MySystemServer.new(sgf)

-- 3. Register system
sgf.businessSystemManager:register("MySystemServer", mySystem)

-- 4. Initialize (PreInit → Init → PostInit → Start)
mySystem:PreInit()
mySystem:Init()
mySystem:PostInit()
mySystem:Start()

-- 5. Update loop
RunService.Stepped:Connect(function()
    sgf:Update(0.033)
end)
```

---

## See Also

- [how-to-create-business-system.md](./how-to-create-business-system.md) - Creating business systems
- [how-to-use-system-lifecycle.md](./how-to-use-system-lifecycle.md) - System lifecycle and dependencies
- [how-to-create-script.md](./how-to-create-script.md) - Script types and JSON configuration

---

**Created**: 2025-10-31
**Version**: 1.0.0
**Based on**: rpg-gamedemo sample (PromptTpl/samplecode/rpg-gamedemo) and scene-workflow-stage-4.md
