# How to Add Player Spawn System

## Overview

**SpawnLocation** is the fundamental spawn point system in MiniWorld Studio, defining where players appear when they join the game or respawn after death. SpawnLocations are invisible volumes (collision regions) that determine player spawn positions and team assignments.

### Primary Use Cases
- **Initial Spawn**: Define where players first appear when joining the game
- **Respawn Points**: Set checkpoint locations for player respawning
- **Team Spawns**: Create team-specific spawn locations
- **Distributed Spawns**: Spread players across multiple spawn areas to prevent crowding
- **Safe Zones**: Position spawns in protected or strategic locations

## Methods of Adding SpawnLocations

There are two primary methods to add SpawnLocation elements to your scene:

### Method 1: Static Addition (JSON Configuration)
Add SpawnLocations directly to the scene structure by creating JSON files. Best for:
- Fixed spawn points that don't change during gameplay
- Initial game setup and level design
- Simple spawn configurations with predetermined locations

### Method 2: Dynamic Addition (Lua Scripting)
Create SpawnLocations at runtime using Lua scripts. Best for:
- Dynamic spawn point generation based on game state
- Checkpoint systems that activate based on player progress
- Procedurally generated spawn locations
- Spawn points that move or change based on game logic

---

## Method 1: Static Addition via JSON

### Step 1: Choose Location in Hierarchy

SpawnLocations must be placed in the **WorkSpace** hierarchy:
```
ServiceNodes/
└── WorkSpace/
    ├── SpawnLocation.json         # Direct child of WorkSpace
    └── Spawns/                     # Or in a subfolder for organization
        ├── MainSpawn.json
        └── CheckpointSpawn.json
```

### Step 2: Create JSON File

Create a JSON file with the following structure:

**Basic Template:**
```json
{
  "ClassType": "SpawnLocation",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SpawnLocation",
  "reflex": [
    {"Name": "SpawnLocation"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"LocalPosition": [0, 100, 0]},
    {"LocalEuler": [0, 0, 0]},
    {"LocalScale": [1, 1, 1]},
    {"LocalRotation": [0, 0, 0, 1]},
    {"Visible": true},
    {"Layer": 0},
    {"LayerCoverChild": true},
    {"InheritParentVisible": true},
    {"Locked": false},
    {"Size": [10, 10, 10]},
    {"EnableGravity": false},
    {"Anchored": true},
    {"PhysXType": 1},
    {"EnablePhysics": true},
    {"CanCollide": false},
    {"CollideGroupID": 0},
    {"CullLayer": 0},
    {"IgnoreStreamSync": true},
    {"CanBePushed": false},
    {"Neutral": true},
    {"AllowTeamChangeOnTouch": false},
    {"MainSpawn": false},
    {"Duration": 0},
    {"TeamId": 0},
    {"SrcChildren": []},
    {"LastParentID": -1},
    {"SrcChildrenList": ""}
  ]
}
```

### Step 3: Configure Key Properties

#### Required Properties

| Property | Value | Description |
|----------|-------|-------------|
| `ClassType` | `"SpawnLocation"` | Type identifier |
| `realNodeName` | `"<name>"` | Display name in editor |

#### Essential Transform Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `LocalPosition` | `[x, y, z]` | Position in world space (cm) | `[0, 100, 0]` = 1m above ground |
| `LocalEuler` | `[x, y, z]` | Rotation in degrees (spawned player facing) | `[0, 90, 0]` = facing east |
| `Size` | `[w, h, d]` | Spawn area dimensions (cm) | `[10, 10, 10]` = 10cm spawn zone |

⚠️ **Important**: `LocalPosition` should be above the terrain surface to prevent players spawning inside geometry. Typical value: `Y = terrain_height + 100` (1 meter above ground)

#### Spawn Behavior Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `Neutral` | boolean | Spawn available to all teams | `true` |
| `MainSpawn` | boolean | Primary spawn point (higher priority) | `false` |
| `AllowTeamChangeOnTouch` | boolean | Allow team switching on touch | `false` |
| `TeamId` | number | Assigned team ID (0 = neutral) | `0` |
| `Duration` | number | Respawn cooldown in seconds | `0` |

#### Physics Properties (Critical for Spawn Points)

| Property | Type | Description | Spawn Value |
|----------|------|-------------|-------------|
| `Anchored` | boolean | Fixed in space (no physics) | `true` ⚠️ |
| `EnableGravity` | boolean | Affected by gravity | `false` ⚠️ |
| `CanCollide` | boolean | Blocks movement | `false` (invisible volume) |
| `IgnoreStreamSync` | boolean | Skip streaming synchronization | `true` |
| `EnablePhysics` | boolean | Physics simulation enabled | `true` |

⚠️ **Critical Settings**: Set `Anchored: true` AND `EnableGravity: false` for spawn points. SpawnLocations are invisible trigger volumes, not physical objects.

#### Visual Properties (SpawnLocations are Invisible)

| Property | Type | Description | Spawn Value |
|----------|------|-------------|-------------|
| `Visible` | boolean | Visibility in editor | `true` (editor only) |
| `CanCollide` | boolean | Physical collision | `false` (no collision) |

Note: SpawnLocations are **invisible in-game** but visible in the editor for placement purposes.

---

## Method 2: Dynamic Addition via Lua

### Step 1: Get WorkSpace Service

```lua
local WorkSpace = game:GetService("WorkSpace")
```

### Step 2: Create SpawnLocation Node

```lua
local spawn = SandboxNode.new('SpawnLocation', WorkSpace)
```

### Step 3: Configure Properties

```lua
-- Basic Identity
spawn.Name = "MainSpawn"

-- Position and Size
spawn.LocalPosition = Vector3.new(0, 100, 0)  -- 1m above ground
spawn.LocalEuler = Vector3.new(0, 0, 0)       -- Player facing direction
spawn.Size = Vector3.new(10, 10, 10)          -- 10cm spawn area

-- Spawn Behavior
spawn.Neutral = true               -- Available to all teams
spawn.MainSpawn = true             -- Primary spawn point
spawn.AllowTeamChangeOnTouch = false
spawn.TeamId = 0                   -- Neutral (0 = no team)
spawn.Duration = 0                 -- No cooldown

-- Physics (for spawn points)
spawn.Anchored = true              -- Fixed position
spawn.EnableGravity = false        -- No gravity on spawn volume
spawn.CanCollide = false           -- Invisible, no collision
spawn.IgnoreStreamSync = true      -- Performance optimization
spawn.EnablePhysics = true
```

---

## Practical Examples

### Example 1: Basic Neutral Spawn (from simplegame)

**JSON Version** (`ServiceNodes/WorkSpace/SpawnLocation.json`):
```json
{
  "ClassType": "SpawnLocation",
  "realNodeName": "SpawnLocation",
  "reflex": [
    {"Name": "SpawnLocation"},
    {"LocalPosition": [0, 100, 0]},
    {"Size": [10, 10, 10]},
    {"Neutral": true},
    {"MainSpawn": false},
    {"AllowTeamChangeOnTouch": false},
    {"Anchored": true},
    {"EnableGravity": false},
    {"CanCollide": false},
    {"IgnoreStreamSync": true}
  ]
}
```

**Lua Version**:
```lua
local WorkSpace = game:GetService("WorkSpace")

local spawn = SandboxNode.new('SpawnLocation', WorkSpace)
spawn.Name = "SpawnLocation"
spawn.LocalPosition = Vector3.new(0, 100, 0)  -- 1m above ground
spawn.Size = Vector3.new(10, 10, 10)          -- Small spawn area
spawn.Neutral = true
spawn.MainSpawn = false
spawn.AllowTeamChangeOnTouch = false
spawn.Anchored = true
spawn.EnableGravity = false
spawn.CanCollide = false
spawn.IgnoreStreamSync = true
```

**Result**: A neutral spawn point at origin, 1 meter above ground level, available to all players

### Example 2: Main Spawn Point with Larger Area

```lua
local WorkSpace = game:GetService("WorkSpace")

local mainSpawn = SandboxNode.new('SpawnLocation', WorkSpace)
mainSpawn.Name = "MainSpawn"
mainSpawn.LocalPosition = Vector3.new(0, 150, 0)  -- 1.5m above ground
mainSpawn.Size = Vector3.new(50, 20, 50)          -- 50x20x50cm spawn zone
mainSpawn.LocalEuler = Vector3.new(0, 0, 0)       -- Players face north
mainSpawn.Neutral = true
mainSpawn.MainSpawn = true                         -- Higher priority spawn
mainSpawn.Duration = 0                             -- No cooldown
mainSpawn.Anchored = true
mainSpawn.EnableGravity = false
mainSpawn.CanCollide = false
mainSpawn.IgnoreStreamSync = true
```

**Result**: A larger main spawn area with higher priority, spawning players at 1.5m height

### Example 3: Team-Specific Spawn

```lua
local WorkSpace = game:GetService("WorkSpace")

local redTeamSpawn = SandboxNode.new('SpawnLocation', WorkSpace)
redTeamSpawn.Name = "RedTeamSpawn"
redTeamSpawn.LocalPosition = Vector3.new(-500, 120, 0)  -- Left side of map
redTeamSpawn.Size = Vector3.new(30, 15, 30)
redTeamSpawn.LocalEuler = Vector3.new(0, 90, 0)  -- Face east (toward center)
redTeamSpawn.Neutral = false                      -- Team-specific
redTeamSpawn.TeamId = 1                           -- Red team ID
redTeamSpawn.AllowTeamChangeOnTouch = false
redTeamSpawn.Anchored = true
redTeamSpawn.EnableGravity = false
redTeamSpawn.CanCollide = false
redTeamSpawn.IgnoreStreamSync = true
```

**Result**: A spawn point exclusive to the red team (TeamId = 1), positioned on the left side of the map

### Example 4: Multiple Distributed Spawns

```lua
local WorkSpace = game:GetService("WorkSpace")

-- Function to create spawn at position
local function createSpawn(name, position, rotation)
    local spawn = SandboxNode.new('SpawnLocation', WorkSpace)
    spawn.Name = name
    spawn.LocalPosition = position
    spawn.LocalEuler = Vector3.new(0, rotation, 0)
    spawn.Size = Vector3.new(20, 15, 20)
    spawn.Neutral = true
    spawn.MainSpawn = false
    spawn.Anchored = true
    spawn.EnableGravity = false
    spawn.CanCollide = false
    spawn.IgnoreStreamSync = true
    return spawn
end

-- Create spawn grid to distribute players
createSpawn("Spawn_North", Vector3.new(0, 120, 300), 180)    -- Face south
createSpawn("Spawn_South", Vector3.new(0, 120, -300), 0)     -- Face north
createSpawn("Spawn_East", Vector3.new(300, 120, 0), 270)     -- Face west
createSpawn("Spawn_West", Vector3.new(-300, 120, 0), 90)     -- Face east
createSpawn("Spawn_Center", Vector3.new(0, 120, 0), 0)       -- Face north
```

**Result**: Five spawn points distributed around the map to prevent player crowding

### Example 5: Checkpoint Spawn System

```lua
local WorkSpace = game:GetService("WorkSpace")

-- Checkpoint spawn that activates when player reaches certain area
local checkpointSpawn = SandboxNode.new('SpawnLocation', WorkSpace)
checkpointSpawn.Name = "Checkpoint_01"
checkpointSpawn.LocalPosition = Vector3.new(800, 150, 200)
checkpointSpawn.Size = Vector3.new(25, 20, 25)
checkpointSpawn.LocalEuler = Vector3.new(0, 45, 0)  -- Face northeast
checkpointSpawn.Neutral = true
checkpointSpawn.MainSpawn = false
checkpointSpawn.Duration = 5  -- 5 second cooldown between spawns
checkpointSpawn.Enabled = false  -- Disabled until checkpoint reached
checkpointSpawn.Anchored = true
checkpointSpawn.EnableGravity = false
checkpointSpawn.CanCollide = false
checkpointSpawn.IgnoreStreamSync = true

-- Later in game logic: checkpointSpawn.Enabled = true when checkpoint reached
```

**Result**: A checkpoint spawn that can be activated dynamically, with a 5-second cooldown

### Example 6: Safe Zone Spawn with Height

```lua
local WorkSpace = game:GetService("WorkSpace")

local safeSpawn = SandboxNode.new('SpawnLocation', WorkSpace)
safeSpawn.Name = "SafeZoneSpawn"
safeSpawn.LocalPosition = Vector3.new(0, 500, 0)  -- 5m above ground (safe from ground enemies)
safeSpawn.Size = Vector3.new(40, 30, 40)          -- Large safe area
safeSpawn.LocalEuler = Vector3.new(0, 0, 0)
safeSpawn.Neutral = true
safeSpawn.MainSpawn = false
safeSpawn.AllowTeamChangeOnTouch = true  -- Allow team switching in safe zone
safeSpawn.Duration = 0
safeSpawn.Anchored = true
safeSpawn.EnableGravity = false
safeSpawn.CanCollide = false
safeSpawn.IgnoreStreamSync = true
```

**Result**: An elevated spawn point in a safe zone where players can change teams

---

## Spawn System Patterns Reference

| Pattern | Neutral | MainSpawn | TeamId | Use Case |
|---------|---------|-----------|--------|----------|
| **Default Spawn** | `true` | `false` | `0` | Standard neutral spawn |
| **Primary Spawn** | `true` | `true` | `0` | Main entry point (higher priority) |
| **Team Spawn** | `false` | varies | `1+` | Team-specific spawn |
| **Checkpoint** | `true` | `false` | `0` | Progress-based respawn |
| **Safe Zone** | `true` | varies | `0` | Protected spawn area |

---

## Property Reference

### Transform Properties

| Property | Type | Units | Description |
|----------|------|-------|-------------|
| `LocalPosition` | `[x, y, z]` | Centimeters | Spawn center position (Y is up) |
| `LocalEuler` | `[x, y, z]` | Degrees | Player facing direction when spawned |
| `LocalRotation` | `[x, y, z, w]` | Quaternion | Alternative rotation format |
| `Size` | `[w, h, d]` | Centimeters | Spawn volume dimensions |

**Spawn Position Calculation**: Players spawn randomly within the `Size` volume around `LocalPosition`

### Spawn Behavior Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `Neutral` | boolean | Available to all teams | `true` |
| `MainSpawn` | boolean | Primary spawn (higher priority) | `false` |
| `AllowTeamChangeOnTouch` | boolean | Enable team switching on spawn | `false` |
| `TeamId` | number | Team assignment (0 = neutral) | `0` |
| `Duration` | number | Cooldown between spawns (seconds) | `0` |
| `Enabled` | boolean | Spawn active/inactive | `true` |

### Physics Properties

| Property | Type | Description | Spawn Default |
|----------|------|-------------|---------------|
| `Anchored` | boolean | Fixed in space | `true` ⚠️ |
| `EnableGravity` | boolean | Affected by gravity | `false` ⚠️ |
| `CanCollide` | boolean | Physical collision | `false` |
| `IgnoreStreamSync` | boolean | Skip streaming sync | `true` |
| `EnablePhysics` | boolean | Physics enabled | `true` |
| `PhysXType` | number | Physics type | `1` |

⚠️ **Critical**: Always set `Anchored = true` AND `EnableGravity = false` for spawn points

---

## Coordinate System & Units

### Coordinate System
- **Y-axis is up**: Vertical direction
- **X-axis**: Horizontal (left/right)
- **Z-axis**: Horizontal (forward/back)
- **Facing Direction**: Controlled by `LocalEuler` Y-axis rotation

### Units
- **Position**: Centimeters (100 units = 1 meter)
- **Rotation**: Degrees (0-360)
  - Y = 0: Face north (positive Z)
  - Y = 90: Face east (positive X)
  - Y = 180: Face south (negative Z)
  - Y = 270: Face west (negative X)
- **Size**: Centimeters (spawn area dimensions)

### Common Position Values
- **Above ground terrain**: `Y = terrain_height + 100` (1 meter clearance)
- **Safe height**: `Y = terrain_height + 150-200` (1.5-2 meters)
- **Elevated platform**: `Y = platform_height + 100`

---

## Best Practices

### Spawn Placement
1. ✅ **Always spawn above terrain** - Set `Y = terrain_height + 100` minimum
2. ✅ **Avoid geometry overlap** - Ensure spawn volumes don't intersect walls/obstacles
3. ✅ **Distribute spawns** - Spread multiple spawns to prevent crowding
4. ✅ **Face logical direction** - Use `LocalEuler` to orient players toward gameplay area

### Team Configuration
1. ✅ **Neutral spawns**: Set `Neutral = true`, `TeamId = 0` for non-team games
2. ✅ **Team spawns**: Set `Neutral = false`, assign specific `TeamId`
3. ✅ **Main spawn priority**: Use `MainSpawn = true` for primary entry points
4. ✅ **Team balance**: Provide equal spawn opportunities for each team

### Performance Optimization
1. ✅ **Set `IgnoreStreamSync = true`** - Spawns don't need streaming
2. ✅ **Use appropriate Size** - Larger areas prevent spawn overlap, but don't make excessive
3. ✅ **Disable unused spawns** - Set `Enabled = false` for inactive checkpoints
4. ✅ **Minimal properties** - Only configure necessary spawn properties

### Gameplay Design
1. ✅ **Safe spawn zones** - Position spawns away from immediate threats
2. ✅ **Checkpoint progression** - Enable spawns as players progress through levels
3. ✅ **Spawn cooldown** - Use `Duration > 0` to prevent spawn camping
4. ✅ **Backup spawns** - Always have at least 2 spawn points in case one is blocked

### Organization
1. ✅ **Use descriptive names** - E.g., "MainSpawn", "Checkpoint_03", "RedTeamSpawn"
2. ✅ **Group in folders** - Organize spawns in WorkSpace/Spawns/ folder
3. ✅ **Document spawn logic** - Comment spawn activation conditions in scripts
4. ✅ **Consistent naming** - Use patterns like "Checkpoint_01", "Checkpoint_02", etc.

---

## Common Patterns

### Pattern 1: Single Neutral Spawn (Simplest)
```lua
-- Basic spawn for simple games
spawn.LocalPosition = Vector3.new(0, 100, 0)
spawn.Size = Vector3.new(10, 10, 10)
spawn.Neutral = true
spawn.MainSpawn = true
spawn.Anchored = true
spawn.EnableGravity = false
```

### Pattern 2: Distributed Neutral Spawns
```lua
-- Multiple spawns to spread players
for i = 1, 4 do
    local spawn = SandboxNode.new('SpawnLocation', WorkSpace)
    spawn.LocalPosition = spawnPositions[i]
    spawn.Neutral = true
    spawn.MainSpawn = (i == 1)  -- First is main
    spawn.Anchored = true
    spawn.EnableGravity = false
end
```

### Pattern 3: Team-Based Spawns
```lua
-- Team 1 spawn (Red)
redSpawn.LocalPosition = Vector3.new(-500, 120, 0)
redSpawn.Neutral = false
redSpawn.TeamId = 1

-- Team 2 spawn (Blue)
blueSpawn.LocalPosition = Vector3.new(500, 120, 0)
blueSpawn.Neutral = false
blueSpawn.TeamId = 2
```

### Pattern 4: Dynamic Checkpoint System
```lua
-- Create disabled checkpoint, enable on trigger
checkpoint.Enabled = false
checkpoint.Duration = 5  -- 5s cooldown

-- Enable when player reaches checkpoint
function OnCheckpointReached(player)
    checkpoint.Enabled = true
    -- Set as player's new spawn
end
```

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Players Spawn Inside Terrain
**Problem**: Set `LocalPosition.Y` too low or at ground level
**Solution**: Always spawn above terrain: `Y = terrain_height + 100` minimum

### ❌ Mistake 2: Players Fall Through World
**Problem**: Spawn point positioned below terrain or in void
**Solution**: Verify spawn Y-position is above solid ground, add safety margin

### ❌ Mistake 3: Spawn Point Has Gravity
**Problem**: Set `EnableGravity = true` causing spawn volume to fall
**Solution**: Always set `EnableGravity = false` for SpawnLocations

### ❌ Mistake 4: Players Can't Spawn (Wrong Team)
**Problem**: Team spawn (`Neutral = false`) with wrong `TeamId`
**Solution**: Match `TeamId` to player team, or use `Neutral = true` for all players

### ❌ Mistake 5: Spawn Collision Blocks Players
**Problem**: Set `CanCollide = true` blocking spawn area
**Solution**: Always set `CanCollide = false` - spawns are invisible volumes

### ❌ Mistake 6: Players Face Wrong Direction
**Problem**: Forgot to set `LocalEuler` rotation
**Solution**: Use `LocalEuler = [0, rotation, 0]` to orient player facing

### ❌ Mistake 7: Spawn Not Anchored
**Problem**: Forgot `Anchored = true`, spawn point moves
**Solution**: Always set `Anchored = true` for spawn points

### ❌ Mistake 8: No Main Spawn Defined
**Problem**: All spawns have `MainSpawn = false`, inconsistent spawn priority
**Solution**: Set at least one spawn with `MainSpawn = true` as primary entry

---

## Validation Checklist

Before finalizing your SpawnLocation configuration:

- [ ] `ClassType = "SpawnLocation"` is set
- [ ] Placed in `WorkSpace` hierarchy (JSON) or created with WorkSpace parent (Lua)
- [ ] `LocalPosition.Y` is **above** terrain surface (minimum +100cm clearance)
- [ ] `Size` configured for appropriate spawn area (typical: 10-50cm)
- [ ] `LocalEuler` set for player facing direction (optional but recommended)
- [ ] **Spawn Type**: `Neutral`, `MainSpawn`, `TeamId` configured correctly
- [ ] **Physics**: `Anchored = true`, `EnableGravity = false`, `CanCollide = false`
- [ ] **Optimization**: `IgnoreStreamSync = true` set
- [ ] Descriptive `Name` assigned (via `realNodeName` in JSON or `Name` property in Lua)
- [ ] No geometry overlap (spawn volume clear of walls/obstacles)
- [ ] At least **2 spawn points** exist in scene (redundancy)

---

## Related Documentation

- [How to Add GeoSolid Elements](how-to-add-geosolid.md)
- [How to Create UI Elements](how-to-create-ui-elements.md)
- [How to Build a Feature](../how-to-build-a-feature.md)
- [How to Create Game System](../how-to-create-game-system.md)

---

## Quick Reference Card

### Basic Neutral Spawn (Most Common)
```lua
local WorkSpace = game:GetService("WorkSpace")

local spawn = SandboxNode.new('SpawnLocation', WorkSpace)
spawn.Name = "SpawnLocation"
spawn.LocalPosition = Vector3.new(0, 100, 0)  -- Above ground
spawn.Size = Vector3.new(10, 10, 10)
spawn.Neutral = true
spawn.MainSpawn = true
spawn.Anchored = true
spawn.EnableGravity = false
spawn.CanCollide = false
spawn.IgnoreStreamSync = true
```

### Critical Settings
- **Above Terrain**: `LocalPosition.Y = terrain_height + 100`
- **No Physics**: `Anchored = true` + `EnableGravity = false`
- **Invisible Volume**: `CanCollide = false`
- **Neutral Access**: `Neutral = true` (or set TeamId for teams)

### Spawn Type Quick Ref
- **Neutral All**: `Neutral = true`, `TeamId = 0`
- **Main Entry**: `MainSpawn = true`
- **Team Specific**: `Neutral = false`, `TeamId = <team_number>`
- **Checkpoint**: `Enabled = false` (enable on trigger)
