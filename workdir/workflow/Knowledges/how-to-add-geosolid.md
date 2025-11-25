# How to Add GeoSolid Elements to Scene

## Overview

**GeoSolid** is the fundamental 3D geometric primitive in MiniWorld Studio, equivalent to Parts in Roblox. GeoSolids are used to create terrain, platforms, walls, obstacles, and any basic 3D geometry in your game world. They serve as both visual geometry and physics collision volumes.

### Primary Use Cases
- **Terrain & Ground**: Create walkable surfaces and landscapes
- **Platforms**: Build jumping platforms and elevated surfaces
- **Structures**: Construct buildings, walls, and architectural elements
- **Obstacles**: Add barriers, pillars, and environmental hazards
- **Decorative Elements**: Place geometric decorations and props

## Methods of Adding GeoSolids

There are two primary methods to add GeoSolid elements to your scene:

### Method 1: Static Addition (JSON Configuration)
Add GeoSolids directly to the scene structure by creating JSON files. Best for:
- Pre-built level geometry that doesn't change
- Initial game setup and prototyping
- Complex multi-object scenes that need precise placement

### Method 2: Dynamic Addition (Lua Scripting)
Create GeoSolids at runtime using Lua scripts. Best for:
- Procedurally generated content
- Interactive elements that spawn based on gameplay
- Dynamic level construction
- Objects that need to respond to game logic

---

## Method 1: Static Addition via JSON

### Step 1: Choose Location in Hierarchy

GeoSolids must be placed in the **WorkSpace** hierarchy:
```
ServiceNodes/
└── WorkSpace/
    ├── YourGeoSolid.json          # Direct child of WorkSpace
    └── YourFolder/                 # Or in a subfolder for organization
        └── YourGeoSolid.json
```

### Step 2: Create JSON File

Create a JSON file with the following structure:

**Basic Template:**
```json
{
  "ClassType": "GeoSolid",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Cube",
  "reflex": [
    {"Name": "Cube"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": true},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 2},
    {"Euler": [0, 0, 0]},
    {"LocalPosition": [0, 50, 0]},
    {"LocalEuler": [0, 0, 0]},
    {"LocalScale": [50, 1, 50]},
    {"LocalRotation": [0, 0, 0, 1]},
    {"Visible": true},
    {"CubeBorderEnable": false},
    {"CubeBorderColor": [135, 206, 250, 255]},
    {"Layer": 0},
    {"LayerCoverChild": true},
    {"InheritParentVisible": true},
    {"Locked": false},
    {"DimensionUnit": 0},
    {"MaterialType": 0},
    {"TextureId": ""},
    {"Color": [200, 200, 200, 255]},
    {"ModelId": ""},
    {"Gravity": 980},
    {"Friction": 0},
    {"Restitution": 0.001},
    {"Mass": 1000},
    {"Velocity": [0, 0, 0]},
    {"AngleVelocity": [0, 0, 0]},
    {"Size": [100, 100, 100]},
    {"Center": [0, 0, 0]},
    {"EnableGravity": true},
    {"Anchored": true},
    {"PhysXType": 1},
    {"EnablePhysics": true},
    {"CanCollide": true},
    {"CanTouch": true},
    {"CollideGroupID": 2},
    {"CullLayer": 0},
    {"IgnoreStreamSync": false},
    {"TextureMode": 0},
    {"TextureOverride": true},
    {"CastShadow": true},
    {"CanRideOn": false},
    {"DrawPhysicsCollider": false},
    {"ReceiveShadow": true},
    {"CanBePushed": false},
    {"OutlineActive": false},
    {"OutlineColorIndex": 0},
    {"Climbable": false},
    {"GeoSolidShape": 0},
    {"Hollow": false},
    {"ToIntersect": false},
    {"InteractMethod": 3},
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
| `ClassType` | `"GeoSolid"` | Type identifier |
| `realNodeName` | `"<name>"` | Display name in editor |


#### Essential Transform Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `LocalPosition` | `[x, y, z]` | Position in world space (cm) | `[0, 50, 0]` = 50cm above ground |
| `LocalEuler` | `[x, y, z]` | Rotation in degrees | `[0, 45, 0]` = rotated 45° on Y-axis |
| `LocalScale` | `[x, y, z]` | Scale multiplier | `[50, 1, 50]` = flat platform shape |
| `Size` | `[w, h, d]` | Base dimensions (cm) before scaling | `[100, 100, 100]` = 1m cube |

#### Shape Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `GeoSolidShape` | number | Shape type | `0`=Box, `1`=Wedge, `2`=Pyramid, `3`=Cylinder, `4`=Cone, `5`=Sphere |

#### Visual Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `Color` | `[r, g, b, a]` | RGBA color (0-255) | `[200, 200, 200, 255]` = gray |
| `MaterialType` | number | Material ID | `0`=Stone, `6`=Default |
| `TextureId` | string | Custom texture path | `"sandboxSysId://path/to/texture.png"` |
| `Visible` | boolean | Visibility | `true` |
| `CastShadow` | boolean | Casts shadows | `true` |
| `ReceiveShadow` | boolean | Receives shadows | `true` |

#### Physics Properties (Critical for Terrain)

| Property | Type | Description | Terrain Value |
|----------|------|-------------|---------------|
| `Anchored` | boolean | Fixed in space (no physics) | `true` ⚠️ |
| `CanCollide` | boolean | Players/objects collide with it | `true` ⚠️ |
| `CanRideOn` | boolean | Players can stand on it | `false` (for terrain, use CanCollide) |
| `EnablePhysics` | boolean | Physics simulation enabled | `true` |
| `CollideGroupID` | number | Collision layer | `2` (terrain layer) |
| `EnableGravity` | boolean | Affected by gravity | `true` (but anchored prevents falling) |
| `Mass` | number | Mass in arbitrary units | `1000` |
| `Friction` | number | Surface friction | `0` (use default) |
| `Gravity` | number | Gravity strength (cm/s²) | `980` |

⚠️ **Critical for Walkable Surfaces**: Set `Anchored: true` AND `CanCollide: true` for ground/platforms

---

## Method 2: Dynamic Addition via Lua

### Step 1: Get WorkSpace Service

```lua
local WorkSpace = game:GetService("WorkSpace")
```

### Step 2: Create GeoSolid Node

```lua
local geosolid = SandboxNode.new('GeoSolid', WorkSpace)
```

### Step 3: Configure Properties

```lua
-- Basic Identity
geosolid.Name = "GroundPlatform"

-- Shape
geosolid.GeoSolidShape = 0  -- Box (see shape types below)
geosolid.Size = Vector3.new(100, 100, 100)  -- Base size

-- Transform
geosolid.LocalPosition = Vector3.new(0, 50, 0)  -- Position
geosolid.LocalEuler = Vector3.new(0, 0, 0)      -- Rotation
geosolid.LocalScale = Vector3.new(50, 1, 50)    -- Scale

-- Visual
geosolid.Color = ColorQuad.new(200, 200, 200, 255)  -- Gray
geosolid.MaterialType = 0  -- Stone
geosolid.Visible = true

-- Physics (for terrain/ground)
geosolid.Anchored = true      -- Fixed position
geosolid.CanCollide = true    -- Enable collision
geosolid.EnablePhysics = true
geosolid.CollideGroupID = 2   -- Terrain layer

-- Shadows
geosolid.CastShadow = true
geosolid.ReceiveShadow = true
```

---

## Practical Examples

### Example 1: Ground Platform (from simplegame)

**JSON Version** (`ServiceNodes/WorkSpace/Cube.json`):
```json
{
  "ClassType": "GeoSolid",
  "realNodeName": "Cube",
  "reflex": [
    {"Name": "Cube"},
    {"LocalPosition": [0, 50, 0]},
    {"LocalScale": [50, 1, 50]},
    {"Size": [100, 100, 100]},
    {"Color": [200, 200, 200, 255]},
    {"GeoSolidShape": 0},
    {"Anchored": true},
    {"CanCollide": true},
    {"EnablePhysics": true},
    {"CollideGroupID": 2}
  ]
}
```

**Lua Version**:
```lua
local WorkSpace = game:GetService("WorkSpace")

local ground = SandboxNode.new('GeoSolid', WorkSpace)
ground.Name = "Cube"
ground.GeoSolidShape = 0  -- Box
ground.Size = Vector3.new(100, 100, 100)
ground.LocalScale = Vector3.new(50, 1, 50)  -- Creates 5000x100x5000cm platform
ground.LocalPosition = Vector3.new(0, 50, 0)
ground.Color = ColorQuad.new(200, 200, 200, 255)
ground.Anchored = true
ground.CanCollide = true
ground.EnablePhysics = true
ground.CollideGroupID = 2
```

**Result**: A 50m × 1m × 50m gray platform at Y=50cm, providing walkable ground

### Example 2: Elevated Platform

```lua
local WorkSpace = game:GetService("WorkSpace")

local platform = SandboxNode.new('GeoSolid', WorkSpace)
platform.Name = "ElevatedPlatform"
platform.GeoSolidShape = 0  -- Box
platform.Size = Vector3.new(100, 100, 100)
platform.LocalScale = Vector3.new(2, 0.5, 2)  -- 200x50x200cm
platform.LocalPosition = Vector3.new(300, 200, 0)  -- Elevated position
platform.Color = ColorQuad.new(100, 150, 255, 255)  -- Light blue
platform.Anchored = true
platform.CanCollide = true
platform.CollideGroupID = 2
```

### Example 3: Wall/Barrier

```lua
local WorkSpace = game:GetService("WorkSpace")

local wall = SandboxNode.new('GeoSolid', WorkSpace)
wall.Name = "Barrier"
wall.GeoSolidShape = 0  -- Box
wall.Size = Vector3.new(100, 100, 100)
wall.LocalScale = Vector3.new(10, 3, 0.3)  -- 1000x300x30cm wall
wall.LocalPosition = Vector3.new(0, 150, 500)
wall.Color = ColorQuad.new(139, 69, 19, 255)  -- Brown
wall.MaterialType = 0  -- Stone
wall.Anchored = true
wall.CanCollide = true
wall.CollideGroupID = 2
```

### Example 4: Cylinder Pillar

```lua
local WorkSpace = game:GetService("WorkSpace")

local pillar = SandboxNode.new('GeoSolid', WorkSpace)
pillar.Name = "Pillar"
pillar.GeoSolidShape = 3  -- Cylinder
pillar.Size = Vector3.new(50, 300, 50)  -- Base cylinder size
pillar.LocalScale = Vector3.new(0.5, 1.5, 0.5)  -- 25cm radius, 450cm tall
pillar.LocalPosition = Vector3.new(200, 225, 200)
pillar.Color = ColorQuad.new(180, 180, 180, 255)  -- Light gray
pillar.MaterialType = 0
pillar.Anchored = true
pillar.CanCollide = true
pillar.CollideGroupID = 2
```

### Example 5: Decorative Sphere

```lua
local WorkSpace = game:GetService("WorkSpace")

local sphere = SandboxNode.new('GeoSolid', WorkSpace)
sphere.Name = "DecoSphere"
sphere.GeoSolidShape = 5  -- Sphere
sphere.Size = Vector3.new(80, 80, 80)  -- 80cm diameter
sphere.LocalPosition = Vector3.new(-150, 120, -150)
sphere.Color = ColorQuad.new(255, 215, 0, 255)  -- Gold
sphere.Anchored = true
sphere.CanCollide = false  -- Decorative only, no collision
sphere.CastShadow = true
```

### Example 6: Ramp (Wedge)

```lua
local WorkSpace = game:GetService("WorkSpace")

local ramp = SandboxNode.new('GeoSolid', WorkSpace)
ramp.Name = "Ramp"
ramp.GeoSolidShape = 1  -- Wedge
ramp.Size = Vector3.new(100, 100, 100)
ramp.LocalScale = Vector3.new(3, 1, 4)  -- 300x100x400cm ramp
ramp.LocalPosition = Vector3.new(-300, 100, 0)
ramp.LocalEuler = Vector3.new(0, 0, 0)  -- Adjust rotation as needed
ramp.Color = ColorQuad.new(169, 169, 169, 255)  -- Dark gray
ramp.Anchored = true
ramp.CanCollide = true
ramp.CollideGroupID = 2
```

---

## GeoSolid Shape Types Reference

| Shape | GeoSolidShape Value | Description | Common Use |
|-------|---------------------|-------------|------------|
| **Box** | `0` | Rectangular cuboid | Platforms, walls, buildings |
| **Wedge** | `1` | Triangular prism | Ramps, roofs, slopes |
| **Pyramid** | `2` | Square pyramid | Decorative tops, monuments |
| **Cylinder** | `3` | Circular cylinder | Pillars, pipes, towers |
| **Cone** | `4` | Circular cone | Decorative tops, markers |
| **Sphere** | `5` | Perfect sphere | Decorations, planets, balls |

---

## Property Reference

### Transform Properties

| Property | Type | Units | Description |
|----------|------|-------|-------------|
| `LocalPosition` | `[x, y, z]` | Centimeters | World position (Y is up) |
| `LocalEuler` | `[x, y, z]` | Degrees | Rotation around each axis |
| `LocalRotation` | `[x, y, z, w]` | Quaternion | Alternative rotation format |
| `LocalScale` | `[x, y, z]` | Multiplier | Scale factor per axis |
| `Size` | `[w, h, d]` | Centimeters | Base dimensions before scaling |

**Final Dimensions** = `Size × LocalScale`
- Example: Size `[100, 100, 100]` × Scale `[50, 1, 50]` = `5000cm × 100cm × 5000cm` (50m × 1m × 50m)

### Physics Properties

| Property | Type | Description | Terrain Default |
|----------|------|-------------|-----------------|
| `Anchored` | boolean | Immune to physics forces | `true` |
| `CanCollide` | boolean | Solid to other objects | `true` |
| `CanRideOn` | boolean | Special ride-on behavior | `false` |
| `EnablePhysics` | boolean | Physics simulation active | `true` |
| `EnableGravity` | boolean | Affected by gravity | `true` (anchored overrides) |
| `PhysXType` | number | Physics type | `1` |
| `CollideGroupID` | number | Collision layer ID | `2` (terrain) |
| `Mass` | number | Object mass | `1000` |
| `Friction` | number | Surface friction coefficient | `0` |
| `Gravity` | number | Gravity strength (cm/s²) | `980` |
| `Restitution` | number | Bounciness (0-1) | `0.001` |
| `Velocity` | `[x, y, z]` | Initial velocity (cm/s) | `[0, 0, 0]` |
| `AngleVelocity` | `[x, y, z]` | Rotational velocity | `[0, 0, 0]` |

### Visual Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `Visible` | boolean | Render visibility | `true` |
| `Color` | `[r, g, b, a]` | RGBA color (0-255) | `[200, 200, 200, 255]` |
| `MaterialType` | number | Material shader ID | `0` (stone) |
| `TextureId` | string | Custom texture path | `""` (none) |
| `TextureMode` | number | Texture mapping mode | `0` |
| `TextureOverride` | boolean | Override texture settings | `true` |
| `CastShadow` | boolean | Casts shadow | `true` |
| `ReceiveShadow` | boolean | Receives shadow | `true` |

### Behavior Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `CanBePushed` | boolean | Can be pushed by characters | `false` |
| `CanTouch` | boolean | Triggers touch events | `true` |
| `Climbable` | boolean | Can be climbed | `false` |
| `Locked` | boolean | Locked in editor | `false` |

---

## Coordinate System & Units

### Coordinate System
- **Y-axis is up**: Vertical direction
- **X-axis**: Horizontal (left/right)
- **Z-axis**: Horizontal (forward/back)
- **Left-handed coordinate system**: Standard for MiniWorld

### Units
- **Position**: Centimeters (100 units = 1 meter)
- **Rotation**: Degrees (0-360)
- **Scale**: Multiplier (1 = 100%, 2 = 200%)
- **Mass**: Arbitrary units (affects physics interaction strength)

### Common Position Values
- Ground level: `Y = 50` (50cm above origin)
- Player spawn: `Y = 100` (1 meter height)
- Eye-level: `Y = 150-180` (1.5-1.8 meters)

---

## Best Practices

### Performance Optimization
1. ✅ **Always set `Anchored = true` for static terrain** - Saves physics computation
2. ✅ **Use `CollideGroupID = 2` for terrain** - Proper collision layering
3. ✅ **Set `ResourceDynamicLoad = true`** for large objects
4. ✅ **Minimize `EnableGravity = true` on anchored objects** - No performance benefit if anchored

### Collision Configuration
1. ✅ **Walkable surfaces**: `Anchored = true`, `CanCollide = true`
2. ✅ **Walls/barriers**: `Anchored = true`, `CanCollide = true`
3. ✅ **Decorative only**: `Anchored = true`, `CanCollide = false`
4. ✅ **Dynamic objects**: `Anchored = false`, `EnablePhysics = true`, `Mass > 0`

### Visual Quality
1. ✅ **Enable shadows** for realistic lighting: `CastShadow = true`, `ReceiveShadow = true`
2. ✅ **Use appropriate materials** via `MaterialType`
3. ✅ **Apply textures** via `TextureId` for visual variety
4. ✅ **Set proper colors** with alpha channel for transparency

### Organization
1. ✅ **Use descriptive names** for GeoSolids (e.g., "GroundPlatform", "MainWall")
2. ✅ **Group related objects** in folders within WorkSpace
3. ✅ **Organize JSON files** logically by function (terrain, structures, decorations)
4. ✅ **Document complex structures** with comments in scripts

---

## Common Patterns

### Pattern 1: Terrain Platform
```lua
-- Flat, wide ground surface
geosolid.GeoSolidShape = 0
geosolid.LocalScale = Vector3.new(large_x, small_y, large_z)
geosolid.Anchored = true
geosolid.CanCollide = true
```

### Pattern 2: Building Block
```lua
-- Structural element (wall, pillar, etc.)
geosolid.GeoSolidShape = 0  -- or 3 for cylinder
geosolid.MaterialType = 0   -- Stone
geosolid.Anchored = true
geosolid.CanCollide = true
```

### Pattern 3: Decorative Element
```lua
-- Visual only, no collision
geosolid.GeoSolidShape = 5  -- Sphere or other decorative shape
geosolid.Anchored = true
geosolid.CanCollide = false
geosolid.CastShadow = true
```

### Pattern 4: Moving Platform
```lua
-- Physics-enabled moving object
geosolid.Anchored = false
geosolid.EnablePhysics = true
geosolid.Mass = 500
geosolid.CanCollide = true
-- Control movement via Velocity or scripting
```

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Players Fall Through Platform
**Problem**: Set `CanRideOn = true` but not `CanCollide = true`
**Solution**: For terrain, set `CanCollide = true` AND `Anchored = true`

### ❌ Mistake 2: Object Falls Through Floor
**Problem**: Forgot to set `Anchored = true`
**Solution**: Static terrain must have `Anchored = true`

### ❌ Mistake 3: Using Roblox API
**Problem**: Using `Instance.new()` or `Color3`
**Solution**: Use `SandboxNode.new()` and `ColorQuad.new()`

### ❌ Mistake 4: Wrong Collision Layer
**Problem**: Player collision ID (1) used for terrain
**Solution**: Use `CollideGroupID = 2` for terrain, `1` for players

### ❌ Mistake 5: Scale vs Size Confusion
**Problem**: Modifying Size directly for scaling
**Solution**: Set base Size once, then use LocalScale for adjustments

### ❌ Mistake 6: Missing Parent Reference
**Problem**: Not specifying WorkSpace parent
**Solution**: Always create with `SandboxNode.new('GeoSolid', WorkSpace)`

---

## Validation Checklist

Before finalizing your GeoSolid configuration:

- [ ] `ClassType = "GeoSolid"` is set
- [ ] Placed in `WorkSpace` hierarchy (JSON) or created with WorkSpace parent (Lua)
- [ ] `LocalPosition` set to desired world coordinates
- [ ] `LocalScale` configured for final dimensions
- [ ] `GeoSolidShape` matches intended shape
- [ ] `Color` set appropriately
- [ ] **Physics**: `Anchored`, `CanCollide`, `CollideGroupID` configured correctly
- [ ] **Shadows**: `CastShadow` and `ReceiveShadow` enabled if needed
- [ ] Descriptive `Name` assigned (via `realNodeName` in JSON or `Name` property in Lua)

---

## Related Documentation

- [How to Create UI Elements](how-to-create-ui-elements.md)
- [How to Create ModuleScript](how-to-create-modulescript.md)
- [How to Build a Feature](../how-to-build-a-feature.md)
- [How to Create Game System](../how-to-create-game-system.md)

---

## Quick Reference Card

### Terrain Ground (Most Common)
```lua
local ground = SandboxNode.new('GeoSolid', game.WorkSpace)
ground.Name = "Ground"
ground.GeoSolidShape = 0
ground.Size = Vector3.new(100, 100, 100)
ground.LocalScale = Vector3.new(50, 1, 50)
ground.LocalPosition = Vector3.new(0, 50, 0)
ground.Color = ColorQuad.new(200, 200, 200, 255)
ground.Anchored = true
ground.CanCollide = true
ground.CollideGroupID = 2
```

### Shape Type Quick Ref
- `0` = Box (most common)
- `1` = Wedge (ramps)
- `3` = Cylinder (pillars)
- `5` = Sphere (decorations)

### Critical Physics Settings
- **Walkable**: `Anchored=true` + `CanCollide=true`
- **Terrain Layer**: `CollideGroupID=2`
- **Dynamic**: `Anchored=false` + `EnablePhysics=true`
