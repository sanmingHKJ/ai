# How to Add Player Control System to Your Game

## Overview

**Player Control** is the complete system for enabling player character movement, camera control, and input handling in MiniWorld Studio. It consists of three interconnected components: the PlayerActorTemplate (character capabilities and behaviors), camera configuration (view and controls), and input handling (user interaction). Together, these create the foundation for player interaction in your game.

### Primary Use Cases
- **Character Movement**: Enable walking, running, jumping, and flying
- **Camera Control**: Configure first-person, third-person, or fixed camera views
- **Input Handling**: Process keyboard, mouse, touch, and gamepad input
- **Cross-Platform**: Support both desktop (WASD + Mouse) and mobile (touch) controls
- **Character Customization**: Define movement physics, speed, and jump height

## Core Concepts

### Player Control Architecture

Player control in MiniWorld Studio follows a three-component architecture:

```
Player Control System
├── 1. PlayerActorTemplate (Character Definition)
│   ├── Actor Properties (speed, health, physics)
│   ├── BehaviorGroups (movement, lifecycle, interaction)
│   ├── AvatarPartGroup (appearance)
│   └── Animation System (visual feedback)
├── 2. Camera Configuration (View System)
│   ├── Canvas + Camera2D (rendering)
│   └── StartPlayer Settings (mode, zoom, controls)
└── 3. Input Handling (User Interaction)
    ├── StartPlayer Movement Modes (PCMovementMode, TouchMovementMode)
    └── UserInputService (optional custom input)
```

**Key Principle**: The character template defines *what the player can do*, the camera defines *how the player sees*, and input configuration defines *how the player controls* their character.
**The PlayerActorTemplate is the critical component that enables player control.**

---

## Method 1: Complete Setup from Scratch (Static JSON)

This is the recommended approach for creating a new playable game from an empty template.

### Step 1: Create PlayerActorTemplate (Character Definition)

**Location**: `ServiceNodes/StartPlayer/PlayerActorTemplate.json`

**Complete Template**:
```json
{
  "ClassType": "Actor",
  "attribute": [],
  "flags": 0,
  "realNodeName": "PlayerActorTemplate",
  "reflex": [
    {"Name": "PlayerActorTemplate"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": true},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 2},
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
    {"DimensionUnit": 0},
    {"MaterialType": 0},
    {"TextureId": ""},
    {"Color": [255, 255, 255, 255]},
    {"ModelId": "sandboxSysId://ministudio/entity/player/defaultplayer/body.prefab"},
    {"Friction": 0.91},
    {"Velocity": [0, 0, 0]},
    {"Size": [173.08, 162.81, 88.29]},
    {"Center": [-34.14, 81.18, 10.25]},
    {"EnablePhysics": true},
    {"CollideGroupID": 1},
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
    {"Movespeed": 400},
    {"MaxHealth": 100},
    {"Health": 100},
    {"UseCameraAngle": false},
    {"AutoRotate": true},
    {"UserId": 0},
    {"Gravity": 980},
    {"StepOffset": 100},
    {"CanAutoJump": false},
    {"SkinId": -1},
    {"SlopeLimit": 45},
    {"JumpBaseSpeed": 400},
    {"JumpContinueSpeed": 0},
    {"RunSpeedFactor": 1.5},
    {"CanPushOthers": false},
    {"PhysXRoleType": 1},
    {"StandardSkeleton": 2}
  ]
}
```

#### Critical Actor Properties for Player Control

| Property | Value | Purpose | Effect on Control |
|----------|-------|---------|-------------------|
| `Movespeed` | `400` | Walking speed (cm/s) | How fast player moves when walking |
| `JumpBaseSpeed` | `400` | Jump initial velocity (cm/s) | How high player jumps |
| `RunSpeedFactor` | `1.5` | Sprint multiplier | Sprint speed = Movespeed × 1.5 |
| `Gravity` | `980` | Gravity force (cm/s²) | How fast player falls (Earth gravity = 980) |
| `StepOffset` | `100` | Auto-climb height (cm) | Max step height player can walk up automatically |
| `SlopeLimit` | `45` | Max walkable slope (degrees) | Steepest slope player can walk on |
| `AutoRotate` | `true` | Auto-face movement direction | Player faces direction they're moving |
| `UseCameraAngle` | `false` | Movement relative to camera | If true, forward = camera forward |
| `CollideGroupID` | `1` | Collision layer | Must be 1 for players |
| `PhysXRoleType` | `1` | Physics type | 1 = character controller |

### Step 2: Create MoveGroup (Movement Behaviors)

**Location**: `ServiceNodes/StartPlayer/PlayerActorTemplate/MoveGroup.json`

```json
{
  "ClassType": "OnlyOneBehaviorGroup",
  "attribute": [],
  "flags": 0,
  "realNodeName": "MoveGroup",
  "reflex": [
    {"Name": "MoveGroup"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"GroupID": 2}
  ]
}
```

⚠️ **Critical**: MoveGroup **MUST** have `GroupID: 2` (system requirement for movement)

#### Create Movement Behavior Files

Inside `MoveGroup/` folder, create these 5 essential behaviors:

**IdleBehavior.json** (Standing still):
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "IdleBehavior",
  "reflex": [
    {"Name": "IdleBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 5},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 100100},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Idle"},
    {"LegacyAutoStop": true}
  ]
}
```

**WalkBehavior.json** (Walking/Running):
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "WalkBehavior",
  "reflex": [
    {"Name": "WalkBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 6},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 100101},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Run"},
    {"LegacyAutoStop": true}
  ]
}
```

**JumpBehavior.json** (Jumping):
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "JumpBehavior",
  "reflex": [
    {"Name": "JumpBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 7},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 100109},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Jump"},
    {"LegacyAutoStop": false}
  ]
}
```

**FlyBehavior.json** (Flying):
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "FlyBehavior",
  "reflex": [
    {"Name": "FlyBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 10},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 100107},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Fly"},
    {"LegacyAutoStop": true}
  ]
}
```

**DropBehavior.json** (Falling):
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "DropBehavior",
  "reflex": [
    {"Name": "DropBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 9},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 100108},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Drop"},
    {"LegacyAutoStop": true}
  ]
}
```

#### Behavior ID Reference

| BehaviorID | Behavior | User Action | Animation |
|------------|----------|-------------|-----------|
| `5` | Idle | No movement input | Standing still |
| `6` | Walk | WASD/Joystick movement | Walking/running |
| `7` | Jump | Spacebar/Jump button | Jumping up |
| `9` | Drop | Falling (gravity) | Falling down |
| `10` | Fly | Double jump or fly mode | Flying through air |

### Step 3: Create Avatar Parts (Appearance)

Create `AvatarPartGroup.json` in `ServiceNodes/StartPlayer/PlayerActorTemplate/`:

```json
{
  "ClassType": "AvatarPartGroup",
  "attribute": [],
  "flags": 0,
  "realNodeName": "AvatarPartGroup",
  "reflex": [
    {"Name": "AvatarPartGroup"},
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

#### Create Required Avatar Parts

Inside `AvatarPartGroup/` folder, create these 4 required parts:

**BODY.json** (PartType: 0):
```json
{
  "ClassType": "AvatarPart",
  "attribute": [],
  "flags": 0,
  "realNodeName": "BODY",
  "reflex": [
    {"Name": "BODY"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"PartType": 0},
    {"ModelResId": ""},
    {"DiffuseTexResId": ""},
    {"EmissiveTexResId": ""},
    {"Show": true},
    {"ModelId": -1}
  ]
}
```

**HEAD.json** (PartType: 1):
```json
{
  "ClassType": "AvatarPart",
  "attribute": [],
  "flags": 0,
  "realNodeName": "HEAD",
  "reflex": [
    {"Name": "HEAD"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"PartType": 1},
    {"ModelResId": ""},
    {"DiffuseTexResId": ""},
    {"EmissiveTexResId": ""},
    {"Show": true},
    {"ModelId": -1}
  ]
}
```

**FACE.json** (PartType: 2):
```json
{
  "ClassType": "AvatarPart",
  "attribute": [],
  "flags": 0,
  "realNodeName": "FACE",
  "reflex": [
    {"Name": "FACE"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"PartType": 2},
    {"ModelResId": ""},
    {"DiffuseTexResId": ""},
    {"EmissiveTexResId": ""},
    {"Show": true},
    {"ModelId": -1}
  ]
}
```

**SKIN.json** (PartType: 10):
```json
{
  "ClassType": "AvatarPart",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SKIN",
  "reflex": [
    {"Name": "SKIN"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"PartType": 10},
    {"ModelResId": ""},
    {"DiffuseTexResId": ""},
    {"EmissiveTexResId": ""},
    {"Show": true},
    {"ModelId": -1}
  ]
}
```

### Step 4: Create LivingGroup and InteractGroup (Optional but Recommended)

**LivingGroup.json** (lifecycle behaviors):
```json
{
  "ClassType": "OnlyOneBehaviorGroup",
  "attribute": [],
  "flags": 0,
  "realNodeName": "LivingGroup",
  "reflex": [
    {"Name": "LivingGroup"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"GroupID": 1}
  ]
}
```

Create minimal behaviors inside `LivingGroup/`: SpawnBehavior (BehaviorID: 1), AliveBehavior (BehaviorID: 2), DeadBehavior (BehaviorID: 3), ReSpawnBehavior (BehaviorID: 4).

**InteractGroup.json** (interaction behaviors):
```json
{
  "ClassType": "OnlyOneBehaviorGroup",
  "attribute": [],
  "flags": 0,
  "realNodeName": "InteractGroup",
  "reflex": [
    {"Name": "InteractGroup"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"GroupID": 3}
  ]
}
```

### Step 5: Add Animation Components

**Animator.json**:
```json
{
  "ClassType": "Animator",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Animator",
  "reflex": [
    {"Name": "Animator"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"IsReplication": true},
    {"pause": false},
    {"Pause": false},
    {"SkeletonAsset": ""},
    {"ControllerAsset": "sandboxSysId&restype=12://ministudio/entity/player/defaultplayer/Animation/OfficialController.controller"},
    {"Speed": 1},
    {"CullingMode": 0},
    {"FixedTickTime": 0},
    {"ModelWaitForLoaded": false}
  ]
}
```

**LegacyAnimation.json**:
```json
{
  "ClassType": "LegacyAnimation",
  "attribute": [],
  "flags": 0,
  "realNodeName": "LegacyAnimation",
  "reflex": [
    {"Name": "LegacyAnimation"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"IsReplication": true},
    {"EnablePlayEvent": false}
  ]
}
```

### Step 6: Configure StartPlayer Camera and Movement Settings

Edit `ServiceNodes/StartPlayer.json` to include:

```json
{
  "ClassType": "StartPlayer",
  "reflex": [
    {"Name": "StartPlayer"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"PCMovementMode": 1},
    {"TouchMovementMode": 1},
    {"CameraMaxZoomDistance": 1200},
    {"CameraMinZoomDistance": 1},
    {"CameraMode": 0}
  ]
}
```

#### StartPlayer Control Properties

| Property | Value | Purpose |
|----------|-------|---------|
| `PCMovementMode` | `1` | Desktop control scheme (1 = WASD + Mouse) |
| `TouchMovementMode` | `1` | Mobile control scheme (1 = Virtual Joystick) |
| `CameraMode` | `0` | Camera type (0 = Third-person, 1 = First-person, 2 = Fixed) |
| `CameraMaxZoomDistance` | `1200` | Maximum zoom distance (12 meters) |
| `CameraMinZoomDistance` | `1` | Minimum zoom distance (1 centimeter) |

### Step 7: Create Camera System (Canvas + Camera2D)

**Canvas** in `ServiceNodes/WorkSpace/Canvas.json`:
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
    {"Visible": true}
  ]
}
```

**Camera2D** in `ServiceNodes/WorkSpace/Canvas/Camera2D.json`:
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
    {"Visible": true}
  ]
}
```

---

## Method 2: Dynamic Control via Lua Scripting

For runtime modifications or custom control schemes:

### Accessing and Modifying Player Character

```lua
-- Get the local player's character
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

if localPlayer and localPlayer.Character then
    local character = localPlayer.Character

    -- Modify movement properties
    character.Movespeed = 600  -- Faster movement
    character.JumpBaseSpeed = 500  -- Higher jump
    character.RunSpeedFactor = 2.0  -- Faster sprint

    -- Modify physics
    character:SetGravity(800)  -- Lower gravity (floaty)
    character:SetStepOffset(150)  -- Can climb higher steps
    character:SetSlopeLimit(60)  -- Can walk steeper slopes

    -- Control character rotation
    character.AutoRotate = true  -- Auto-face movement direction
    character.UseCameraAngle = true  -- Move relative to camera
end
```

### Player Actions API Reference

This section documents all available player character control methods from `SandboxActorObject` and `SandboxCharacter`.

#### Movement Control Methods

| Method | Parameters | Description | Example |
|--------|-----------|-------------|---------|
| **Move** | `direction: Vector3`<br>`relativeToCamera: boolean` | Move character in specified direction. If `relativeToCamera=true`, direction is relative to camera angle | `character:Move(Vector3.new(0,0,1), true)` |
| **StopMove** | None | Stop all character movement | `character:StopMove()` |
| **MoveTo** | `position: Vector3` | Move character to specified world position | `character:MoveTo(Vector3.new(100, 0, 100))` |
| **SetMoveDirection** | `direction: Vector3` | Set character movement direction vector | `character:SetMoveDirection(Vector3.new(1,0,0))` |
| **SetRunState** | `state: boolean` | Enable/disable running (applies RunSpeedFactor multiplier) | `character:SetRunState(true)` |

#### Jump Control Methods

| Method | Parameters | Description | Usage Notes |
|--------|-----------|-------------|-------------|
| **Jump** | `enable: boolean` | **STATE TOGGLE**: `true` enables continuous jumping, `false` disables | **Not a trigger** - call once per state change, not every frame |
| **SetJumpInfo** | `baseSpeed: number`<br>`continueSpeed: number` | Configure jump velocity parameters | `character:SetJumpInfo(500, 100)` |
| **SetEnableContinueJump** | `enable: boolean` | Enable/disable continuous jump capability | `character:SetEnableContinueJump(true)` |
| **JumpCDTime** | `time: number` | Set jump cooldown time in seconds | `character:JumpCDTime(0.5)` |

**Jump() Usage Pattern**:
```lua
-- ✅ CORRECT - Toggle state on button press/release
jumpButton.TouchBegin:Connect(function()
    character:Jump(true)  -- Enable jumping state
end)
jumpButton.TouchEnd:Connect(function()
    character:Jump(false)  -- Disable jumping state
end)

-- ❌ WRONG - Don't call every frame
RunService.Heartbeat:Connect(function()
    character:Jump(true)  -- Wasteful and incorrect
end)
```

#### Navigation Methods

| Method | Parameters | Description | Usage |
|--------|-----------|-------------|-------|
| **NavigateTo** | `target: Vector3` | Use navigation mesh to pathfind to target | Requires nav mesh in scene |
| **StopNavigate** | None | Stop navigation pathfinding | `character:StopNavigate()` |
| **FindNearestPolygonCenter** | `pos: Vector3`<br>`radius: number` | Find nearest walkable nav mesh point | Returns `Vector3` or `nil` |

#### Physics & Speed Configuration

| Method | Parameters | Description | Default |
|--------|-----------|-------------|---------|
| **SetGravity** | `gravity: number` | Set gravity force (cm/s²) | 980 (Earth gravity) |
| **SetSlopeLimit** | `limit: number` | Set max walkable slope angle (degrees) | 45° |
| **SetCanAutoJump** | `enable: boolean` | Enable auto-jump when hitting obstacles | false |
| **SetStepOffset** | `offset: number` | Set max auto-climb step height (cm) | 100 cm |

**Example - Low Gravity Jump Game**:
```lua
character:SetGravity(400)  -- Floaty gravity
character:SetJumpInfo(600, 0)  -- High jump
character:SetSlopeLimit(60)  -- Climb steeper slopes
```

#### Animation Control (SandboxCharacter)

| Method | Parameters | Description | Notes |
|--------|-----------|-------------|-------|
| **PlayAnimation** | `animName: string`<br>`looped: boolean` | Play animation by name | Requires animation in Animator |
| **StopAnimation** | `animName: string` | Stop specific animation | - |
| **StopAllAnimations** | None | Stop all active animations | - |

#### Health & Combat Methods

| Method | Parameters | Description | Events Triggered |
|--------|-----------|-------------|------------------|
| **SetHealth** | `health: number` | Set current health value | `OnHealthChanged` |
| **SetMaxHealth** | `maxHealth: number` | Set maximum health value | - |
| **TakeDamage** | `amount: number`<br>`attacker: Actor` | Damage character | `OnDamaged`, `OnDeath` (if health ≤ 0) |
| **Heal** | `amount: number` | Restore health (capped at MaxHealth) | `OnHealed` |
| **Die** | None | Instantly kill character | `OnDeath` |
| **Respawn** | `position: Vector3` | Respawn character at position | `OnRespawn` |

**Example - Damage System**:
```lua
-- Apply damage
enemy.Character:TakeDamage(25, player.Character)

-- Heal player
player.Character:Heal(50)

-- Listen to health changes
player.Character.OnHealthChanged:Connect(function(oldHealth, newHealth)
    print("Health: " .. newHealth .. "/" .. player.Character.MaxHealth)
end)
```

#### State Query Methods

| Method | Returns | Description |
|--------|---------|-------------|
| **GetHealth** | `number` | Get current health value |
| **GetMaxHealth** | `number` | Get maximum health value |
| **GetMoveDirection** | `Vector3` | Get current movement direction |
| **GetRunState** | `boolean` | Get whether character is running |
| **GetCurMoveState** | `string` | Get current state: "ZERO", "Jump", "Jumping", "Stand", "Walk", "Fly", "Died" |
| **GetGravity** | `number` | Get current gravity value |
| **GetSlopeLimit** | `number` | Get max walkable slope angle |
| **GetCanAutoJump** | `boolean` | Get auto-jump enabled state |

#### Character Events

| Event | Parameters | When Fired |
|-------|-----------|-----------|
| **Walking** | `isWalking: boolean` | Walk state changes |
| **Standing** | `isStanding: boolean` | Stand state changes |
| **Jumping** | `isJumping: boolean` | Jump state changes |
| **Flying** | `isFlying: boolean` | Fly state changes |
| **Died** | `isDead: boolean` | Death state changes |
| **MoveStateChange** | `oldState: string, newState: string` | Any movement state transition |
| **NavigateFinished** | `isSuccess: boolean` | Navigation pathfinding completes |
| **MoveFinished** | `isSuccess: boolean` | MoveTo completes |
| **OnHealthChanged** | `oldHealth: number, newHealth: number` | Health value changes |
| **OnDamaged** | `damage: number, attacker: Actor` | Character takes damage |
| **OnHealed** | `amount: number` | Character is healed |
| **OnDeath** | `attacker: Actor` | Character dies |
| **OnRespawn** | `position: Vector3` | Character respawns |

**Example - Event Handling**:
```lua
-- Monitor jump state
character.Jumping:Connect(function(isJumping)
    print("Jumping:", isJumping)
end)

-- Monitor health
character.OnDamaged:Connect(function(damage, attacker)
    print("Took " .. damage .. " damage!")
end)

-- Monitor navigation
character.NavigateFinished:Connect(function(success)
    if success then
        print("Reached destination")
    else
        print("Navigation failed")
    end
end)
```

---

### Custom Input Handling with UserInputService

```lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Example: Custom WASD movement control
RunService.Heartbeat:Connect(function(deltaTime)
    local player = Players.LocalPlayer
    if not player or not player.Character then return end

    local character = player.Character
    local moveDirection = Vector3.new(0, 0, 0)

    -- Check WASD keys
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + Vector3.new(0, 0, 1)  -- Forward
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection + Vector3.new(0, 0, -1)  -- Backward
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection + Vector3.new(-1, 0, 0)  -- Left
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + Vector3.new(1, 0, 0)  -- Right
    end

    -- Apply movement if any key pressed
    if moveDirection.Magnitude > 0 then
        character:Move(moveDirection.Unit, true)  -- true = relative to camera
    else
        character:StopMove()
    end
end)

-- Example: Custom jump on Spacebar (hold to jump)
-- See "Player Actions API Reference" section for detailed Jump() documentation

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.Space then
        local player = Players.LocalPlayer
        if player and player.Character then
            player.Character:Jump(true)  -- Enable jumping state
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.Space then
        local player = Players.LocalPlayer
        if player and player.Character then
            player.Character:Jump(false)  -- Disable jumping state
        end
    end
end)
```

### Modifying Camera Settings Dynamically

```lua
local StartPlayer = game:GetService("StartPlayer")

-- Change camera mode
StartPlayer.CameraMode = 1  -- Switch to first-person

-- Adjust zoom range
StartPlayer.CameraMaxZoomDistance = 600  -- Limit zoom to 6 meters
StartPlayer.CameraMinZoomDistance = 100  -- Minimum 1 meter

-- Change control scheme
StartPlayer.PCMovementMode = 2  -- Change to click-to-move
StartPlayer.TouchMovementMode = 2  -- Change to tap-to-move
```

---

## Practical Examples

### Example 1: Standard Third-Person Game (like simplegame)

**Setup**:
1. PlayerActorTemplate with standard movement (400 cm/s walk, 400 cm/s jump)
2. Third-person camera (CameraMode = 0, zoom 1-1200cm)
3. WASD + Mouse controls (PCMovementMode = 1)
4. Virtual joystick for mobile (TouchMovementMode = 1)

**Player Control Result**: Standard action-adventure game controls - character moves with WASD, camera follows behind, mouse rotates camera, spacebar jumps.

### Example 2: Fast-Paced Platformer

**Configuration**:
```lua
-- In PlayerActorTemplate.json or via Lua:
character.Movespeed = 600  -- Fast movement
character.JumpBaseSpeed = 600  -- High jump
character.RunSpeedFactor = 1.8  -- Fast sprint
character.Gravity = 800  -- Slightly lower gravity (floaty)
character.StepOffset = 150  -- Can jump on higher platforms

-- Camera settings
StartPlayer.CameraMode = 0
StartPlayer.CameraMaxZoomDistance = 400  -- Closer camera
StartPlayer.CameraMinZoomDistance = 200
```

**Result**: Fast, responsive platformer with high jumps and close camera for precision movement.

### Example 3: First-Person Shooter

**Configuration**:
```lua
-- Camera settings
StartPlayer.CameraMode = 1  -- First-person view
StartPlayer.CameraMaxZoomDistance = 1  -- No zoom
StartPlayer.CameraMinZoomDistance = 1

-- Character settings
character.Movespeed = 500
character.AutoRotate = true
character.UseCameraAngle = true  -- Move in camera direction

-- Disable jump (optional for tactical shooter)
-- Remove or disable JumpBehavior
```

**Result**: First-person view with forward movement matching camera direction.

### Example 4: Top-Down Strategy Game

**Configuration**:
```lua
-- Camera settings
StartPlayer.CameraMode = 0  -- Third-person
StartPlayer.CameraMaxZoomDistance = 2000  -- Far zoom (20m)
StartPlayer.CameraMinZoomDistance = 500  -- Minimum 5m

-- Movement
StartPlayer.PCMovementMode = 2  -- Click to move
StartPlayer.TouchMovementMode = 2  -- Tap to move
```

**Result**: Bird's-eye view with click-to-move controls like RTS games.

---

## Movement Mode Reference

### Desktop Controls (PCMovementMode)

| Mode | Value | Description | Use Case |
|------|-------|-------------|----------|
| **WASD** | `1` | WASD keys for movement, mouse for camera | Action, adventure, shooter games |
| **Click-to-Move** | `2` | Click destination to move (RTS-style) | Strategy, simulation games |
| **Disabled** | `0` | No movement control | Cutscenes, fixed character |

### Mobile Controls (TouchMovementMode)

| Mode | Value | Description | Use Case |
|------|-------|-------------|----------|
| **Virtual Joystick** | `1` | On-screen joystick for movement | Action games, platformers |
| **Tap-to-Move** | `2` | Tap destination to move | Strategy, casual games |
| **Disabled** | `0` | No touch control | Desktop-only games |

### Camera Modes (CameraMode)

| Mode | Value | Description | Use Case |
|------|-------|-------------|----------|
| **Third-Person** | `0` | Camera follows behind player | Most common - action, adventure, RPG |
| **First-Person** | `1` | Camera at player eye level | Shooter, immersive games |
| **Fixed** | `2` | Camera stays in place | Cutscenes, fixed-perspective games |

---

## Property Reference

### Actor Movement Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `Movespeed` | number | cm/s | Walking speed | 400 |
| `JumpBaseSpeed` | number | cm/s | Jump initial velocity | 400 |
| `JumpContinueSpeed` | number | cm/s | Sustained jump speed | 0 |
| `RunSpeedFactor` | number | multiplier | Sprint speed multiplier | 1.5 |
| `Gravity` | number | cm/s² | Gravity acceleration | 980 |
| `StepOffset` | number | cm | Max auto-climb step height | 100 |
| `SlopeLimit` | number | degrees | Max walkable slope angle | 45 |
| `Friction` | number | coefficient | Movement friction | 0.91 |
| `AutoRotate` | boolean | - | Auto-rotate toward movement | true |
| `UseCameraAngle` | boolean | - | Move relative to camera | false |

### Actor Physics Properties

| Property | Type | Description | Player Default |
|----------|------|-------------|----------------|
| `CollideGroupID` | number | Collision layer | `1` (player layer) |
| `PhysXRoleType` | number | Physics type | `1` (character controller) |
| `EnablePhysics` | boolean | Physics enabled | `true` |
| `CanCollide` | boolean | Physical collision | `true` (implied) |
| `Size` | [x, y, z] | Collision box size (cm) | Model-dependent |
| `Center` | [x, y, z] | Collision box offset (cm) | Model-dependent |

### Actor Health Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `MaxHealth` | number | Maximum health points | 100 |
| `Health` | number | Current health points | 100 |

---

## Best Practices

### Movement Configuration
1. ✅ **Test movement feel** - Adjust Movespeed, JumpBaseSpeed until it feels right for your game
2. ✅ **Match speed to camera** - Faster movement needs wider camera zoom
3. ✅ **Balance gravity and jump** - Lower gravity = floatier, higher = heavier feel
4. ✅ **Configure cross-platform** - Set both PCMovementMode and TouchMovementMode

### Camera Configuration
1. ✅ **Third-person for exploration** - Use CameraMode = 0 for most games
2. ✅ **Appropriate zoom range** - Close camera (100-600) for platformers, far (500-2000) for strategy
3. ✅ **Test camera collision** - Ensure camera doesn't clip through walls
4. ✅ **Match controls to view** - WASD for third-person, relative-to-camera for first-person

### Physics Tuning
1. ✅ **StepOffset for terrain** - Set to 100cm (1m) to allow climbing small steps
2. ✅ **SlopeLimit for slopes** - 45° is standard, lower for realistic climbing
3. ✅ **CollideGroupID = 1** - Always use 1 for player characters
4. ✅ **Enable AutoRotate** - Makes character face movement direction naturally

### Behavior Groups
1. ✅ **Always include all 5 movement behaviors** - Idle, Walk, Jump, Fly, Drop
2. ✅ **MoveGroup GroupID MUST be 2** - System requirement
3. ✅ **Include LivingGroup** - Even if simple, provides spawn/death handling
4. ✅ **Match BehaviorIDs** - Use standard IDs (5=Idle, 6=Walk, 7=Jump, etc.)

### Avatar Parts
1. ✅ **Required parts** - BODY, HEAD, FACE, SKIN must all exist
2. ✅ **Use ModelId = -1 for default** - Let engine use default player model
3. ✅ **Set Show = true** - Make all parts visible
4. ✅ **PartType must match** - BODY=0, HEAD=1, FACE=2, SKIN=10

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Player Can't Move (No PlayerActorTemplate)

**Problem**: Created StartPlayer but no PlayerActorTemplate inside
**Symptom**: Player spawns but can't be controlled
**Solution**: Must create complete PlayerActorTemplate hierarchy with MoveGroup

### ❌ Mistake 2: Movement Doesn't Work (Wrong MoveGroup GroupID)

**Problem**: Set MoveGroup GroupID to 1 or 3 instead of 2
**Symptom**: Character exists but movement commands don't work
**Solution**: MoveGroup **MUST** have GroupID = 2 (system requirement)

### ❌ Mistake 3: Player Is Invisible (Missing Avatar Parts)

**Problem**: Forgot to create BODY, HEAD, FACE, or SKIN parts
**Symptom**: Can control camera but can't see character
**Solution**: Create all 4 required avatar parts in AvatarPartGroup

### ❌ Mistake 4: Camera Doesn't Follow (No Camera System)

**Problem**: Didn't create Canvas + Camera2D in WorkSpace
**Symptom**: Black screen or fixed view
**Solution**: Create Canvas in WorkSpace with Camera2D as child

### ❌ Mistake 5: No Input Response (Wrong Movement Mode)

**Problem**: Set PCMovementMode = 0 (disabled)
**Symptom**: Player visible but no keyboard/mouse response
**Solution**: Set PCMovementMode = 1 (WASD) and TouchMovementMode = 1 (Joystick)

### ❌ Mistake 6: Player Falls Through Floor

**Problem**: CollideGroupID mismatch with terrain
**Symptom**: Player spawns and immediately falls through world
**Solution**:
- Player: CollideGroupID = 1
- Terrain: CollideGroupID = 2, CanCollide = true, Anchored = true

### ❌ Mistake 7: Animations Don't Play

**Problem**: Missing or incorrect AnimatorStateName in behaviors
**Symptom**: Character moves but T-pose or frozen animation
**Solution**: Ensure Animator has correct ControllerAsset and behavior states match controller

### ❌ Mistake 8: Wrong Collision Detection

**Problem**: Set CollideGroupID = 2 for player (terrain layer)
**Symptom**: Player collides incorrectly or passes through obstacles
**Solution**: Always use CollideGroupID = 1 for player characters

---

## Validation Checklist

Before testing player control:

### PlayerActorTemplate
- [ ] PlayerActorTemplate.json exists in ServiceNodes/StartPlayer/
- [ ] ClassType = "Actor"
- [ ] Movespeed, JumpBaseSpeed, Gravity configured
- [ ] CollideGroupID = 1
- [ ] PhysXRoleType = 1
- [ ] StandardSkeleton = 2
- [ ] ModelId points to valid model

### Behavior Groups
- [ ] MoveGroup exists with GroupID = 2 ⚠️
- [ ] IdleBehavior exists (BehaviorID = 5)
- [ ] WalkBehavior exists (BehaviorID = 6)
- [ ] JumpBehavior exists (BehaviorID = 7)
- [ ] FlyBehavior exists (BehaviorID = 10)
- [ ] DropBehavior exists (BehaviorID = 9)
- [ ] LivingGroup exists (optional but recommended)

### Avatar Parts
- [ ] AvatarPartGroup exists
- [ ] BODY part exists (PartType = 0)
- [ ] HEAD part exists (PartType = 1)
- [ ] FACE part exists (PartType = 2)
- [ ] SKIN part exists (PartType = 10)
- [ ] All parts have Show = true

### Camera System
- [ ] Canvas exists in WorkSpace
- [ ] Camera2D exists as child of Canvas
- [ ] StartPlayer.json has camera settings
- [ ] CameraMode configured (0/1/2)
- [ ] CameraMaxZoomDistance and CameraMinZoomDistance set

### Input Configuration
- [ ] PCMovementMode = 1 (or appropriate mode)
- [ ] TouchMovementMode = 1 (or appropriate mode)

### Scene Setup
- [ ] Ground/terrain exists (GeoSolid with CollideGroupID = 2)
- [ ] Terrain is Anchored = true, CanCollide = true
- [ ] SpawnLocation exists above terrain
- [ ] SpawnLocation Y position > terrain Y + 100cm

---

## Complete Directory Structure

```
ServiceNodes/
├── StartPlayer.json (with camera and movement settings)
│   └── PlayerActorTemplate.json (Actor root)
│       ├── AvatarPartGroup.json
│       │   ├── BODY.json (required)
│       │   ├── HEAD.json (required)
│       │   ├── FACE.json (required)
│       │   └── SKIN.json (required)
│       ├── MoveGroup.json (GroupID: 2) ⚠️
│       │   ├── IdleBehavior.json (BehaviorID: 5)
│       │   ├── WalkBehavior.json (BehaviorID: 6)
│       │   ├── JumpBehavior.json (BehaviorID: 7)
│       │   ├── FlyBehavior.json (BehaviorID: 10)
│       │   └── DropBehavior.json (BehaviorID: 9)
│       ├── LivingGroup.json (GroupID: 1)
│       │   ├── SpawnBehavior.json (BehaviorID: 1)
│       │   ├── AliveBehavior.json (BehaviorID: 2)
│       │   ├── DeadBehavior.json (BehaviorID: 3)
│       │   └── ReSpawnBehavior.json (BehaviorID: 4)
│       ├── InteractGroup.json (GroupID: 3)
│       │   ├── SitDownBehavior.json (BehaviorID: 11)
│       │   └── StandUpBehavior.json (BehaviorID: 12)
│       ├── Animator.json
│       └── LegacyAnimation.json
└── WorkSpace/
    ├── Canvas.json
    │   └── Camera2D.json
    ├── Cube.json (ground - CollideGroupID: 2)
    └── SpawnLocation.json (above ground)
```

---

## Related Documentation

- [How to Add Player Character Template](how-to-add-player-template.md) - Detailed PlayerActorTemplate documentation
- [How to Add Player Spawn System](how-to-add-player-spawn.md) - SpawnLocation configuration
- [How to Add Camera System](how-to-add-camera.md) - Camera setup and configuration
- [How to Add GeoSolid Elements](how-to-add-geosolid.md) - Create terrain for walking
- [SandboxActorObject API](../PromptTpl/refDoc/Documents/Actor/SandboxActorObject.md) - Actor class reference
- [UserInputService API](../PromptTpl/refDoc/Documents/Services/UserInputService.md) - Input handling reference

---

## Quick Reference Card

### Minimum Working Player Control Setup

**Required Files** (in order):
1. **PlayerActorTemplate.json** in StartPlayer/
   - Movespeed: 400, JumpBaseSpeed: 400, CollideGroupID: 1
2. **MoveGroup.json** with **GroupID: 2** ⚠️
   - 5 behaviors: Idle(5), Walk(6), Jump(7), Fly(10), Drop(9)
3. **AvatarPartGroup/** with 4 parts
   - BODY(0), HEAD(1), FACE(2), SKIN(10)
4. **Animator.json** + **LegacyAnimation.json**
5. **Canvas.json** in WorkSpace/
   - **Camera2D.json** as child
6. **StartPlayer.json** settings:
   - PCMovementMode: 1, TouchMovementMode: 1
   - CameraMode: 0, CameraMaxZoom: 1200, CameraMinZoom: 1
7. **Ground terrain** (GeoSolid, CollideGroupID: 2, Anchored: true)
8. **SpawnLocation** (above terrain, Y = terrain_Y + 100)

### Critical Values
- **MoveGroup GroupID**: MUST be 2
- **Player CollideGroupID**: MUST be 1
- **Terrain CollideGroupID**: MUST be 2
- **Required Avatar Parts**: BODY, HEAD, FACE, SKIN

### Standard Movement Speeds
- Walking: 400 cm/s (4 m/s)
- Sprint: 600 cm/s (walking × 1.5)
- Jump: 400 cm/s upward
- Gravity: 980 cm/s² (Earth gravity)

---

## Troubleshooting

### Player doesn't spawn
1. Check SpawnLocation exists in WorkSpace
2. Verify SpawnLocation Y > terrain Y + 100
3. Check PlayerActorTemplate exists in StartPlayer

### Player spawns but can't move
1. ✅ MoveGroup exists with GroupID = 2 (most common issue)
2. ✅ All 5 movement behaviors exist (Idle, Walk, Jump, Fly, Drop)
3. ✅ PCMovementMode = 1 or TouchMovementMode = 1
4. ✅ Movespeed > 0

### Player is invisible
1. ✅ All 4 avatar parts exist (BODY, HEAD, FACE, SKIN)
2. ✅ All parts have Show = true
3. ✅ ModelId is valid (use -1 for default)

### Player falls through floor
1. ✅ Player CollideGroupID = 1
2. ✅ Terrain CollideGroupID = 2
3. ✅ Terrain Anchored = true
4. ✅ Terrain CanCollide = true

### Camera doesn't follow player
1. ✅ Canvas + Camera2D exist in WorkSpace
2. ✅ CameraMode = 0 (or 1 for first-person)
3. ✅ Camera2D Enabled = true

### No keyboard/mouse response
1. ✅ PCMovementMode = 1 (not 0)
2. ✅ TouchMovementMode = 1 (for mobile)
3. ✅ Check for UI consuming input (gameProcessedEvent)

---

**Summary**: Player control requires three components: PlayerActorTemplate (character definition with MoveGroup GroupID=2), camera system (Canvas + Camera2D), and input configuration (PCMovementMode/TouchMovementMode in StartPlayer). The character must have all movement behaviors (Idle, Walk, Jump, Fly, Drop) and required avatar parts (BODY, HEAD, FACE, SKIN) to function correctly. The player uses CollideGroupID=1 and requires terrain with CollideGroupID=2 to walk on.
