# How to Add Camera System to Your Game

## Overview

**Camera** is the player's view into the game world in MiniWorld Studio. The camera system consists of a Canvas container and a Camera2D node that renders the player's perspective. The camera can be configured for different view modes (first-person, third-person), control schemes (keyboard/mouse, touch), and zoom distances.

### Primary Use Cases
- **Third-Person View**: Follow-behind camera for character-focused games
- **First-Person View**: Direct perspective from character's eyes
- **Custom Camera Controls**: Configurable zoom, rotation, and movement
- **Mobile Support**: Touch-based camera controls for mobile devices
- **Desktop Support**: WASD + mouse camera controls for PC

## Methods of Adding Camera

There are two primary methods to add camera systems to your game:

### Method 1: Static Addition (JSON Configuration)
Add camera nodes directly to the scene structure by creating JSON files. Best for:
- Initial game setup and prototyping
- Standard camera configurations
- Games with consistent camera behavior

### Method 2: Dynamic Addition (Lua Scripting)
Create and configure cameras at runtime using Lua scripts. Best for:
- Dynamic camera switching (cutscenes, transitions)
- Camera effects and animations
- Context-sensitive camera behaviors
- Custom camera systems

---

## Method 1: Static Addition via JSON

### Step 1: Create Canvas Container

Cameras in MiniWorld Studio must be placed inside a Canvas node, which acts as the UI rendering container.

**Location in Hierarchy:**
```
ServiceNodes/
└── WorkSpace/
    └── Canvas.json              # Canvas container for camera
        └── Camera2D.json        # Camera node
```

**Canvas JSON Structure** (`ServiceNodes/WorkSpace/Canvas.json`):
```json
{
  "ClassType": "Canvas",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Canvas",
  "reflex": [
    {"Name": "Canvas"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"Euler": [0, 0, 0]},
    {"LocalPosition": [0, 0, 0]},
    {"LocalEuler": [0, 0, 0]},
    {"LocalScale": [1, 1, 1]},
    {"LocalRotation": [0, 0, 0, 1]},
    {"Visible": true},
    {"CubeBorderEnable": false},
    {"CubeBorderColor": [135, 206, 250, 255]},
    {"Layer": 0},
    {"LayerCoverChild": true},
    {"InheritParentVisible": true},
    {"Locked": false},
    {"DimensionUnit": 0}
  ]
}
```

### Step 2: Create Camera2D Node

**Camera2D JSON Structure** (`ServiceNodes/WorkSpace/Canvas/Camera2D.json`):
```json
{
  "ClassType": "Camera2D",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Camera2D",
  "reflex": [
    {"Name": "Camera2D"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"Euler": [0, 0, 0]},
    {"LocalPosition": [0, 0, 0]},
    {"LocalEuler": [0, 0, 0]},
    {"LocalScale": [1, 1, 1]},
    {"LocalRotation": [0, 0, 0, 1]},
    {"Visible": true},
    {"CubeBorderEnable": false},
    {"CubeBorderColor": [135, 206, 250, 255]},
    {"Layer": 0},
    {"LayerCoverChild": true},
    {"InheritParentVisible": true},
    {"Locked": false},
    {"DimensionUnit": 0}
  ]
}
```

### Step 3: Configure StartPlayer Camera Settings

Camera behavior is controlled through the StartPlayer service configuration. Edit `ServiceNodes/StartPlayer.json`:

**Key Camera Properties in StartPlayer:**
```json
{
  "ClassType": "StartPlayer",
  "reflex": [
    {"Name": "StartPlayer"},
    {"CameraMode": 0},
    {"CameraMaxZoomDistance": 1200},
    {"CameraMinZoomDistance": 1},
    {"PCMovementMode": 1},
    {"TouchMovementMode": 1}
  ]
}
```

#### Required Camera Configuration Properties

| Property | Type | Description | Common Values |
|----------|------|-------------|---------------|
| `CameraMode` | number | Camera view mode | `0`=Third-person, `1`=First-person, `2`=Fixed |
| `CameraMaxZoomDistance` | number | Maximum zoom distance (cm) | `1200` (12 meters) |
| `CameraMinZoomDistance` | number | Minimum zoom distance (cm) | `1` (1 centimeter) |
| `PCMovementMode` | number | Desktop control scheme | `1`=WASD + Mouse |
| `TouchMovementMode` | number | Mobile control scheme | `1`=Virtual Joystick |

---

## Method 2: Dynamic Addition via Lua

### Step 1: Get Required Services

```lua
local WorkSpace = game:GetService("WorkSpace")
local Players = game:GetService("Players")
local StartPlayer = game:GetService("StartPlayer")
```

### Step 2: Create Canvas and Camera

```lua
-- Create Canvas container
local canvas = SandboxNode.new('Canvas', WorkSpace)
canvas.Name = "Canvas"
canvas.Visible = true

-- Create Camera2D inside Canvas
local camera = SandboxNode.new('Camera2D', canvas)
camera.Name = "Camera2D"
camera.Enabled = true
camera.Visible = true
```

### Step 3: Configure StartPlayer Camera Settings

```lua
-- Configure camera behavior via StartPlayer
StartPlayer.CameraMode = 0  -- Third-person
StartPlayer.CameraMaxZoomDistance = 1200  -- 12 meters
StartPlayer.CameraMinZoomDistance = 1  -- 1 cm
StartPlayer.PCMovementMode = 1  -- WASD + Mouse
StartPlayer.TouchMovementMode = 1  -- Virtual joystick
```

### Step 4: Optional - Set Custom Camera Position

```lua
-- Get local player's camera
local player = Players.LocalPlayer
if player and player.Camera then
    local playerCamera = player.Camera
    -- Camera position is typically managed automatically
    -- but can be customized for special effects
end
```

---

## Practical Examples

### Example 1: Basic Third-Person Camera (from simplegame)

**JSON Version:**

**Canvas** (`ServiceNodes/WorkSpace/Canvas.json`):
```json
{
  "ClassType": "Canvas",
  "realNodeName": "Canvas",
  "reflex": [
    {"Name": "Canvas"},
    {"Enabled": true},
    {"Visible": true}
  ]
}
```

**Camera2D** (`ServiceNodes/WorkSpace/Canvas/Camera2D.json`):
```json
{
  "ClassType": "Camera2D",
  "realNodeName": "Camera2D",
  "reflex": [
    {"Name": "Camera2D"},
    {"Enabled": true},
    {"Visible": true}
  ]
}
```

**StartPlayer Configuration** (in `ServiceNodes/StartPlayer.json`):
```json
{
  "ClassType": "StartPlayer",
  "reflex": [
    {"CameraMode": 0},
    {"CameraMaxZoomDistance": 1200},
    {"CameraMinZoomDistance": 1},
    {"PCMovementMode": 1},
    {"TouchMovementMode": 1}
  ]
}
```

**Lua Version:**
```lua
-- Create camera structure
local WorkSpace = game:GetService("WorkSpace")
local StartPlayer = game:GetService("StartPlayer")

local canvas = SandboxNode.new('Canvas', WorkSpace)
canvas.Name = "Canvas"

local camera = SandboxNode.new('Camera2D', canvas)
camera.Name = "Camera2D"

-- Configure third-person camera
StartPlayer.CameraMode = 0
StartPlayer.CameraMaxZoomDistance = 1200
StartPlayer.CameraMinZoomDistance = 1
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

**Result**: A standard third-person camera that follows the player, with zoom range of 1cm to 12m, WASD movement, and mouse look.

### Example 2: First-Person Camera

```lua
local StartPlayer = game:GetService("StartPlayer")

-- Configure first-person view
StartPlayer.CameraMode = 1  -- First-person
StartPlayer.CameraMaxZoomDistance = 1  -- No zoom out
StartPlayer.CameraMinZoomDistance = 1
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

**Result**: Camera positioned at player's eye level with no zoom, creating immersive first-person view.

### Example 3: Limited Zoom Third-Person

```lua
local StartPlayer = game:GetService("StartPlayer")

-- Configure limited zoom for platformer-style camera
StartPlayer.CameraMode = 0  -- Third-person
StartPlayer.CameraMaxZoomDistance = 400  -- Max 4 meters
StartPlayer.CameraMinZoomDistance = 100  -- Min 1 meter
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

**Result**: Third-person camera with restricted zoom range (1-4 meters), good for platformers or action games.

### Example 4: Fixed Camera

```lua
local StartPlayer = game:GetService("StartPlayer")

-- Configure fixed camera (no player control)
StartPlayer.CameraMode = 2  -- Fixed
StartPlayer.CameraMaxZoomDistance = 0
StartPlayer.CameraMinZoomDistance = 0
StartPlayer.PCMovementMode = 0  -- No movement control
StartPlayer.TouchMovementMode = 0
```

**Result**: Camera remains in fixed position and orientation, useful for cutscenes or specific gameplay mechanics.

### Example 5: Custom Camera Following (Advanced)

```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Custom camera follow behavior
local player = Players.LocalPlayer
local character = player.Character

RunService.Heartbeat:Connect(function(dt)
    if character and player.Camera then
        local camera = player.Camera
        local characterPos = character.LocalPosition

        -- Custom offset camera position
        local offset = Vector3.new(0, 300, -500)  -- Behind and above
        camera.LocalPosition = characterPos + offset

        -- Look at character
        -- (Camera look-at logic would go here)
    end
end)
```

**Result**: Fully custom camera behavior with manual position and orientation control.

---

## Camera Mode Reference

| Mode | CameraMode Value | Description | Use Case |
|------|------------------|-------------|----------|
| **Third-Person** | `0` | Camera follows behind player | Adventure, RPG, action games |
| **First-Person** | `1` | Camera at player eye level | Shooter, immersive games |
| **Fixed** | `2` | Camera stays in place | Cutscenes, fixed perspective games |

---

## Movement Mode Reference

### PC Movement Modes (PCMovementMode)

| Mode | Value | Description |
|------|-------|-------------|
| **WASD** | `1` | WASD keys for movement, mouse for camera |
| **Click to Move** | `2` | Click destination to move (RTS-style) |
| **Disabled** | `0` | No movement control |

### Touch Movement Modes (TouchMovementMode)

| Mode | Value | Description |
|------|-------|-------------|
| **Virtual Joystick** | `1` | On-screen joystick for movement |
| **Tap to Move** | `2` | Tap destination to move |
| **Disabled** | `0` | No touch control |

---

## Property Reference

### StartPlayer Camera Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `CameraMode` | number | Enum | Camera perspective mode | `0` (third-person) |
| `CameraMaxZoomDistance` | number | Centimeters | Maximum zoom-out distance | `1200` (12m) |
| `CameraMinZoomDistance` | number | Centimeters | Minimum zoom-in distance | `1` (1cm) |
| `PCMovementMode` | number | Enum | Desktop control scheme | `1` (WASD) |
| `TouchMovementMode` | number | Enum | Mobile control scheme | `1` (joystick) |

### Camera2D Node Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `Name` | string | Node identifier | `"Camera2D"` |
| `Enabled` | boolean | Camera active state | `true` |
| `Visible` | boolean | Camera rendering enabled | `true` |
| `LocalPosition` | `[x, y, z]` | Camera position (usually auto-managed) | `[0, 0, 0]` |
| `LocalEuler` | `[x, y, z]` | Camera rotation (usually auto-managed) | `[0, 0, 0]` |

### Canvas Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `Name` | string | Canvas identifier | `"Canvas"` |
| `Visible` | boolean | Canvas rendering enabled | `true` |
| `Enabled` | boolean | Canvas active state | `true` |

---

## Best Practices

### Camera Configuration
1. ✅ **Always create Canvas first** - Camera2D must be child of Canvas
2. ✅ **Set appropriate zoom ranges** - Match zoom to game genre (close for platformers, far for strategy)
3. ✅ **Configure both PC and touch modes** - Ensure cross-platform compatibility
4. ✅ **Test camera in-game** - Verify camera doesn't clip through walls or terrain

### Performance Optimization
1. ✅ **Use single camera per player** - Multiple cameras impact performance
2. ✅ **Avoid frequent camera mode switching** - Smooth transitions are better than abrupt changes
3. ✅ **Let engine manage camera position** - Only override for special effects

### User Experience
1. ✅ **Provide appropriate zoom range** - Too limited feels restrictive, too wide can disorient
2. ✅ **Match movement mode to game type** - WASD for action, click-to-move for strategy
3. ✅ **Consider camera collision** - Prevent camera from going through walls
4. ✅ **Test on mobile** - Ensure touch controls are responsive and intuitive

### Organization
1. ✅ **Keep camera in standard location** - Canvas directly under WorkSpace
2. ✅ **Use clear naming** - "Canvas" and "Camera2D" are standard
3. ✅ **Document custom camera behavior** - Comment Lua scripts that modify camera

---

## Common Patterns

### Pattern 1: Standard Third-Person (Most Common)
```lua
-- Basic follow camera for most game types
StartPlayer.CameraMode = 0
StartPlayer.CameraMaxZoomDistance = 1200
StartPlayer.CameraMinZoomDistance = 1
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

### Pattern 2: Close Third-Person (Action Games)
```lua
-- Closer camera for action-focused gameplay
StartPlayer.CameraMode = 0
StartPlayer.CameraMaxZoomDistance = 600  -- 6 meters max
StartPlayer.CameraMinZoomDistance = 100  -- 1 meter min
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

### Pattern 3: First-Person Shooter
```lua
-- First-person view with no zoom
StartPlayer.CameraMode = 1
StartPlayer.CameraMaxZoomDistance = 1
StartPlayer.CameraMinZoomDistance = 1
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

### Pattern 4: Strategy Game (Top-Down)
```lua
-- Wide zoom range for RTS-style view
StartPlayer.CameraMode = 0
StartPlayer.CameraMaxZoomDistance = 2000  -- 20 meters
StartPlayer.CameraMinZoomDistance = 500   -- 5 meters
StartPlayer.PCMovementMode = 2  -- Click to move
StartPlayer.TouchMovementMode = 2
```

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Camera Not Rendering
**Problem**: Created Camera2D directly in WorkSpace without Canvas
**Solution**: Always create Canvas first, then Camera2D as child of Canvas

### ❌ Mistake 2: Camera Won't Move
**Problem**: Set `CameraMode = 2` (Fixed) unintentionally
**Solution**: Use `CameraMode = 0` for third-person or `1` for first-person

### ❌ Mistake 3: No Player Control
**Problem**: Set `PCMovementMode = 0` or didn't configure movement modes
**Solution**: Set `PCMovementMode = 1` and `TouchMovementMode = 1` for standard controls

### ❌ Mistake 4: Camera Too Close/Too Far
**Problem**: Inappropriate zoom distance settings
**Solution**: Standard ranges: min=1, max=1200 for third-person; adjust based on game scale

### ❌ Mistake 5: Mobile Controls Not Working
**Problem**: Only configured PCMovementMode, forgot TouchMovementMode
**Solution**: Always configure both PC and touch movement modes

### ❌ Mistake 6: Camera Inside Character Model
**Problem**: CameraMinZoomDistance set to 0 or very small value in third-person
**Solution**: Set minimum distance to at least 100cm (1 meter) for third-person view

---

## Validation Checklist

Before finalizing your camera configuration:

- [ ] Canvas node created in WorkSpace
- [ ] Camera2D node created as child of Canvas
- [ ] `ClassType = "Canvas"` for Canvas node
- [ ] `ClassType = "Camera2D"` for camera node
- [ ] `CameraMode` set appropriately (0=third-person, 1=first-person)
- [ ] `CameraMaxZoomDistance` configured (typical: 1200 for third-person)
- [ ] `CameraMinZoomDistance` configured (typical: 1 for first-person, 100+ for third-person)
- [ ] `PCMovementMode` set (typical: 1 for WASD)
- [ ] `TouchMovementMode` set (typical: 1 for virtual joystick)
- [ ] Camera tested in-game with player movement
- [ ] Camera doesn't clip through terrain or walls
- [ ] Mobile touch controls tested (if targeting mobile)

---

## Coordinate System Notes

### Camera Position
- **Automatic Management**: Camera position is typically managed automatically by the engine based on player position
- **Manual Override**: Can be customized via Lua for cutscenes or special effects
- **Offset**: Third-person camera maintains offset behind and above player
- **Y-axis Up**: Vertical positioning follows MiniWorld's Y-up coordinate system

### Zoom Distance
- **Units**: Centimeters (100 = 1 meter)
- **Typical Ranges**:
  - Close third-person: 100-600cm (1-6 meters)
  - Standard third-person: 1-1200cm (0.01-12 meters)
  - Strategy/top-down: 500-2000cm (5-20 meters)
  - First-person: 1-1cm (locked at eye level)

---

## Related Documentation

- [How to Add GeoSolid Elements](how-to-add-geosolid.md)
- [How to Create UI Elements](how-to-create-ui-elements.md)
- [How to Control Player](how-to-control-player.md)

---

## Quick Reference Card

### Minimal Camera Setup (JSON)
```
1. Create ServiceNodes/WorkSpace/Canvas.json (ClassType: "Canvas")
2. Create ServiceNodes/WorkSpace/Canvas/Camera2D.json (ClassType: "Camera2D")
3. Edit ServiceNodes/StartPlayer.json:
   - CameraMode: 0
   - CameraMaxZoomDistance: 1200
   - CameraMinZoomDistance: 1
   - PCMovementMode: 1
   - TouchMovementMode: 1
```

### Minimal Camera Setup (Lua)
```lua
local WorkSpace = game:GetService("WorkSpace")
local StartPlayer = game:GetService("StartPlayer")

-- Create structure
local canvas = SandboxNode.new('Canvas', WorkSpace)
canvas.Name = "Canvas"
local camera = SandboxNode.new('Camera2D', canvas)
camera.Name = "Camera2D"

-- Configure camera
StartPlayer.CameraMode = 0
StartPlayer.CameraMaxZoomDistance = 1200
StartPlayer.CameraMinZoomDistance = 1
StartPlayer.PCMovementMode = 1
StartPlayer.TouchMovementMode = 1
```

### Camera Mode Quick Ref
- `0` = Third-person (most common)
- `1` = First-person
- `2` = Fixed

### Movement Mode Quick Ref
- `1` = WASD/Joystick (most common)
- `2` = Click/Tap to move
- `0` = Disabled

---

## Implementation Sequence

When adding a camera system to a game like initgame → simplegame:

1. **Create Canvas**: Add Canvas.json in WorkSpace
2. **Create Camera2D**: Add Camera2D.json as child of Canvas
3. **Configure StartPlayer**: Edit StartPlayer.json camera properties
4. **Test**: Verify camera follows player and responds to input
5. **Adjust**: Fine-tune zoom ranges and movement modes based on gameplay

**Key Pattern**: Camera is separate from player but automatically follows player position. The engine handles the follow logic; you configure the behavior parameters.
