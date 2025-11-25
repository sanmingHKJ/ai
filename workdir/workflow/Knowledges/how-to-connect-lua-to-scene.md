# How to Connect Lua Systems to Scene Objects in MiniWorld Studio

## Overview

This guide explains how to connect generated Lua business systems (like DoorSystem, SpawnSystem, etc.) with actual scene objects (doors, portals, NPCs) in the MiniWorld Studio WorkSpace.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    WorkSpace                             │
│  (Scene Objects stored as JSON files)                   │
│  - Doors, Portals, NPCs, Spawns, etc.                   │
└─────────────────┬───────────────────────────────────────┘
                  │
                  │ game:GetService("WorkSpace")
                  ▼
┌─────────────────────────────────────────────────────────┐
│            Business System (Server)                      │
│  - DoorSystemServer.lua                                 │
│  - Finds objects by name                                │
│  - Sets up event listeners (Touched, etc.)              │
│  - Manages state and logic                              │
└─────────────────┬───────────────────────────────────────┘
                  │
                  │ Network Messages & Events
                  ▼
┌─────────────────────────────────────────────────────────┐
│              Client Systems                              │
│  - DoorSystemClient.lua                                 │
│  - Receives updates and shows UI/effects                │
└─────────────────────────────────────────────────────────┘
```

## Step-by-Step Connection Process

### Step 1: Create Scene Objects in WorkSpace

Scene objects are stored as **JSON files** in `ServiceNodes/WorkSpace/`.

#### Example Directory Structure:
```
ServiceNodes/
└── WorkSpace/
    ├── village_square/
    │   ├── village_square.json        (Scene metadata)
    │   ├── church_main_door.json      (Door object)
    │   ├── fountain_central.json      (Decoration)
    │   └── npc_village_elder.json     (NPC)
    ├── church_crypt/
    │   ├── church_crypt.json
    │   └── crypt_door_sealed.json
    └── childrenIndex                   (Scene index)
```

#### Example Door Object JSON:

**`church_main_door.json`:**
```json
{
    "ClassID": 123,
    "ClassType": "GeoSolid",
    "NodeId": 2050,
    "realNodeName": "church_main_door",
    "reflex": [
        {"Name": "church_main_door"},
        {"Tag": 0},
        {"Enabled": true},
        {"LocalPosition": [65.0, 1.0, 60.0]},
        {"LocalEuler": [0.0, 0.0, 0.0]},
        {"LocalScale": [1.5, 2.5, 0.15]},
        {"Size": [100, 100, 100]},
        {"CanTouch": true},
        {"CanCollide": true},
        {"Anchored": true},
        {"MaterialType": 6},
        {"Color": [20000, 15000, 10000, 65535]}
    ]
}
```

**Key Properties:**
- `Name`: Unique identifier used by Lua to find the object
- `LocalPosition`: [x, y, z] world coordinates
- `CanTouch`: Enables Touched event
- `CanCollide`: Enables collision physics
- `ClassType`: "GeoSolid" (basic shape), "Model", etc.

### Step 2: Add Object Initialization to Business System

Modify your generated `DoorSystemServer.lua` to find and initialize scene objects.

#### Add Data Storage:

```lua
function DoorSystemServer.new(sgf)
    local self = setmetatable({}, {__index = DoorSystemServer})
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    -- Add object storage
    self.data = {
        doorObjects = {},      -- [doorId] = doorObject
        doorStates = {},       -- [doorId] = {open = bool, locked = bool}
        touchConnections = {}  -- [doorId] = connection
    }

    return self
end
```

#### Add Initialization Method:

```lua
function DoorSystemServer:initializeSceneObjects()
    self.log:info("[DoorSystemServer] Initializing scene objects...")

    -- Get WorkSpace service
    local workspace = game:GetService("WorkSpace")
    if not workspace then
        self.log:error("WorkSpace not found")
        return
    end

    -- Initialize each door from topology
    local doorNames = {
        "church_main_door",
        "crypt_door_sealed",
        "iron_gate_entrance",
        "boss_arena_gate"
    }

    for _, doorName in ipairs(doorNames) do
        local doorObject = self:findChildRecursive(workspace, doorName)
        if doorObject then
            self.data.doorObjects[doorName] = doorObject
            self:setupDoorInteraction(doorObject, doorName)
            self.log:info(string.format("Door initialized: %s", doorName))
        else
            self.log:warning(string.format("Door not found in WorkSpace: %s", doorName))
        end
    end
end

-- Recursive search helper
function DoorSystemServer:findChildRecursive(parent, targetName)
    if not parent then return nil end

    -- Check direct children first
    local child = parent:FindFirstChild(targetName)
    if child then return child end

    -- Search recursively in all children
    local children = parent:GetChildren()
    for _, child in ipairs(children) do
        local found = self:findChildRecursive(child, targetName)
        if found then return found end
    end

    return nil
end
```

#### Setup Interaction Events:

```lua
function DoorSystemServer:setupDoorInteraction(doorObject, doorId)
    if not doorObject then
        self.log:error("Door object is nil for " .. doorId)
        return
    end

    -- Configure physics
    doorObject.CanTouch = true
    doorObject.CanCollide = true

    -- Connect Touched event
    if doorObject.Touched then
        local connection = doorObject.Touched:Connect(function(otherObject)
            -- Get player who touched
            local player = self:getPlayerFromObject(otherObject)
            if player then
                local playerId = player.UserId
                self.log:debug(string.format(
                    "[Door] Player %s touched door %s",
                    playerId,
                    doorId
                ))

                -- Handle door interaction
                self:handleDoorTouch(playerId, doorId, doorObject)
            end
        end)

        -- Store connection for cleanup
        self.data.touchConnections[doorId] = connection
    else
        self.log:warning("Door does not support Touched event: " .. doorId)
    end
end

-- Get player from touched object
function DoorSystemServer:getPlayerFromObject(object)
    if not object then return nil end

    -- Navigate up hierarchy to find player
    local current = object
    while current do
        if current.ClassName == "Player" then
            return current
        end
        current = current.Parent
    end

    return nil
end

-- Handle door touch
function DoorSystemServer:handleDoorTouch(playerId, doorId, doorObject)
    -- Check if door is already open
    local state = self.data.doorStates[doorId] or {open = false, locked = false}

    if state.open then
        self.log:debug("Door already open: " .. doorId)
        return
    end

    if state.locked then
        -- Check if player has key
        local hasKey = self:playerHasKey(playerId, doorId)
        if not hasKey then
            self:sendMessage(playerId, "This door is locked. You need a key.")
            return
        end
    end

    -- Open the door
    self:openDoor(doorId, doorObject)
end

-- Open door animation
function DoorSystemServer:openDoor(doorId, doorObject)
    self.log:info("Opening door: " .. doorId)

    -- Update state
    self.data.doorStates[doorId] = {open = true, locked = false}

    -- Animate door (rotate open)
    local targetRotation = Vector3.new(0, 90, 0)
    doorObject.LocalEuler = targetRotation

    -- Disable collision
    doorObject.CanCollide = false

    -- Broadcast to all clients
    self:Broadcast(Protocol.ServerMSGID.DOOR_STATE_CHANGED, {
        doorId = doorId,
        open = true
    })

    -- Emit event
    self.events:emit(EventID.door_opened, {doorId = doorId})
end
```

### Step 3: Call Initialization in Start Method

```lua
function DoorSystemServer:Start()
    if self.state ~= "initialized" then
        return false
    end
    self.log:info("[DoorSystemServer] Start...")

    -- Initialize scene objects
    self:initializeSceneObjects()

    self.state = "started"
    return true
end
```

### Step 4: Cleanup on Stop

```lua
function DoorSystemServer:Stop()
    self.log:info("[DoorSystemServer] Stop...")

    -- Disconnect all touch events
    for doorId, connection in pairs(self.data.touchConnections) do
        if connection then
            connection:disconnect()
            self.log:debug("Disconnected touch event for door: " .. doorId)
        end
    end

    self.data.touchConnections = {}
    self.state = "stopped"
    return true
end
```

## MiniWorld Studio Supported APIs

The following APIs are **officially supported** in MiniWorld Studio (verified from sample code):

### Service Access:
```lua
local workspace = game:GetService("WorkSpace")
local mainStorage = game:GetService("MainStorage")
local players = game:GetService("Players")
```

### Finding Children:
```lua
-- Direct child search (non-recursive)
local child = parent:FindFirstChild("childName")

-- Recursive search (searches all descendants)
local child = parent:FindFirstChild("childName", true)  -- true = recursive

-- Get all children
local children = parent:GetChildren()  -- Returns array/table

-- Alternative: .Children property (less common)
local children = parent.Children  -- Property access
```

### Iteration:
```lua
-- Iterate through all children
for _, child in pairs(parent:GetChildren()) do
    -- Process child
end

-- Or using ipairs (if order matters)
for i, child in ipairs(parent:GetChildren()) do
    -- Process child with index
end
```

### Events:
```lua
-- Touch event (for collision detection)
object.Touched:Connect(function(otherObject)
    -- Handle touch
end)

-- Property access
object.CanTouch = true
object.CanCollide = false
object.LocalPosition = Vector3.new(x, y, z)
object.LocalEuler = Vector3.new(rx, ry, rz)
```

## Complete Example: SpawnSystem

Here's how the SpawnSystem connects to spawn point objects (using verified APIs):

```lua
function SpawnSystemServer:initializeSceneObjects()
    local workspace = game:GetService("WorkSpace")

    -- Find spawn points
    local spawnPoint = workspace:FindFirstChild("spawn_point_01")
    if spawnPoint then
        -- Spawn players at this location
        local position = spawnPoint.LocalPosition

        -- Spawn player 1
        self:spawnPlayer(1, position)

        -- Spawn player 2 with offset
        self:spawnPlayer(2, Vector3.new(position.x + 200, position.y, position.z))
    end
end

function SpawnSystemServer:spawnPlayer(playerIndex, position)
    local playerId = self:getPlayerIdByIndex(playerIndex)
    if not playerId then return end

    -- Get player object
    local player = self.sgf.playerManager:GetPlayer(playerId)
    if player then
        -- Set player position
        player.LocalPosition = position
        self.log:info(string.format("Player %d spawned at position: %s",
            playerIndex,
            tostring(position)))
    end
end
```

## Topology.yml → WorkSpace Mapping

Your `topology.yml` defines behaviors with `target` fields that should **match object names** in WorkSpace:

```yaml
# In topology.yml
- id: "door_church_entrance"
  target: "church_main_door"    # ← Must match WorkSpace object name
  system: "DoorSystem"

  trigger:
    type: "player_interact"
    params:
      target: "church_main_door"  # ← Same name
```

```
# In WorkSpace
ServiceNodes/WorkSpace/village_square/church_main_door.json
                                       ^^^^^^^^^^^^^^^
                                       Must match target name
```

## Common Object Types

### 1. Doors/Portals
- **ClassType:** `GeoSolid`
- **Key Properties:** `CanTouch: true`, `CanCollide: true`
- **Events:** `Touched`

### 2. NPCs
- **ClassType:** `Actor` or `Model`
- **Key Properties:** `CanTouch: true`, AI behavior scripts
- **Events:** `Touched`, custom interact events

### 3. Spawn Points
- **ClassType:** `SandboxNode` (empty container)
- **Key Properties:** `LocalPosition`
- **Usage:** Read position, spawn entities there

### 4. Interactive Objects (Chests, Levers)
- **ClassType:** `GeoSolid` or `Model`
- **Key Properties:** `CanTouch: true`
- **Events:** `Touched`

## Best Practices

1. **Naming Convention:** Use descriptive, unique names (e.g., `church_main_door`, not `door_01`)

2. **Organize by Scene:** Group objects in folders by scene/area

3. **Error Handling:** Always check if objects exist before using them

4. **Cleanup:** Disconnect events in `Stop()` method

5. **State Management:** Store object references and state in `self.data`

6. **Documentation:** Comment which WorkSpace objects each system expects

## Tools for Creating WorkSpace Objects

You can create WorkSpace objects in two ways:

1. **MiniWorld Studio Editor:**
   - Visual drag-and-drop interface
   - Set properties in inspector
   - Export to WorkSpace automatically

2. **Manual JSON Creation:**
   - Copy template JSON
   - Modify properties (Name, Position, etc.)
   - Add to WorkSpace folder
   - Update `childrenIndex` file

## Troubleshooting

**Object not found:**
- Check spelling of object name
- Verify object exists in WorkSpace
- Use recursive search: `findChildRecursive()`

**Touched event not firing:**
- Ensure `CanTouch: true`
- Check `Anchored: true` (for static objects)
- Verify collision groups

**Door doesn't move:**
- Use `LocalEuler` or `LocalPosition` to animate
- Broadcast changes to clients
- Check if object is anchored

## Summary

The connection flow is:
1. Create JSON objects in `WorkSpace/` with unique names
2. In System's `Start()`, call `initializeSceneObjects()`
3. Use `game:GetService("WorkSpace")` to access objects
4. Find objects by name: `workspace:FindFirstChild("name")`
5. Setup event listeners: `object.Touched:Connect(...)`
6. Handle interactions in your business logic
7. Cleanup in `Stop()` method

This creates a clean separation between **scene design** (WorkSpace) and **game logic** (Lua systems).
