# How to Add Player Character Template

## Overview

**PlayerActorTemplate** is the fundamental player character system in MiniWorld Studio, defining the appearance, behaviors, animations, and physics properties for all players in your game. It is equivalent to StarterCharacter in Roblox but with a more sophisticated behavior-based animation system and avatar part structure.

### Primary Use Cases
- **Player Characters**: Define the default character that all players spawn as
- **Character Customization**: Configure appearance through avatar parts (body, head, clothing)
- **Movement Behaviors**: Set up walking, running, jumping, and flying capabilities
- **Animation System**: Link character behaviors to animations
- **Physics Properties**: Control movement speed, gravity, collision, and health

## Core Concepts

### Actor System Architecture

The PlayerActorTemplate follows a hierarchical component-based architecture:

```
PlayerActorTemplate (Actor)
├── AvatarPartGroup (Appearance)
│   ├── BODY, HEAD, FACE (Required)
│   ├── SKIN (Required)
│   ├── JACKET, TROUSERS, SHOE (Clothing)
│   └── Decorations (BACK_ORNAMENT, FACE_ORNAMENT, etc.)
├── MoveGroup (Movement Behaviors)
│   ├── IdleBehavior
│   ├── WalkBehavior
│   ├── JumpBehavior
│   ├── FlyBehavior
│   └── DropBehavior
├── LivingGroup (Lifecycle Behaviors)
│   ├── SpawnBehavior
│   ├── AliveBehavior
│   ├── DeadBehavior
│   └── ReSpawnBehavior
├── InteractGroup (Interaction Behaviors)
│   ├── SitDownBehavior
│   └── StandUpBehavior
├── Animator (Modern Animation Controller)
└── LegacyAnimation (Backward Compatibility)
```

**Key Pattern**: Actor (base) + BehaviorGroups (capabilities) + Avatar (appearance) + Animations (visual feedback)

---

## Method 1: Static Configuration (JSON)

### Location in Hierarchy

The PlayerActorTemplate **must** be placed in the **StartPlayer** service:

```
ServiceNodes/
└── StartPlayer/
    └── PlayerActorTemplate.json       # Root actor definition
        ├── AvatarPartGroup/
        │   ├── BODY.json
        │   ├── HEAD.json
        │   ├── FACE.json
        │   ├── SKIN.json
        │   ├── JACKET.json
        │   ├── TROUSERS.json
        │   ├── SHOE.json
        │   └── ... (other avatar parts)
        ├── MoveGroup.json
        │   ├── IdleBehavior.json
        │   ├── WalkBehavior.json
        │   ├── JumpBehavior.json
        │   ├── FlyBehavior.json
        │   └── DropBehavior.json
        ├── LivingGroup.json
        │   ├── SpawnBehavior.json
        │   ├── AliveBehavior.json
        │   ├── DeadBehavior.json
        │   └── ReSpawnBehavior.json
        ├── InteractGroup.json
        │   ├── SitDownBehavior.json
        │   └── StandUpBehavior.json
        ├── Animator.json
        └── LegacyAnimation.json
```

### Step 1: Create PlayerActorTemplate Root (Actor)

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate.json`

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

#### Critical Actor Properties

| Property | Type | Description | Typical Value |
|----------|------|-------------|---------------|
| `ClassType` | string | Type identifier | `"Actor"` (required) |
| `ModelId` | string | Player model prefab path | `"sandboxSysId://ministudio/entity/player/defaultplayer/body.prefab"` |
| `Movespeed` | number | Walking speed (cm/s) | `400` (4 m/s) |
| `JumpBaseSpeed` | number | Jump initial velocity (cm/s) | `400` |
| `RunSpeedFactor` | number | Sprint speed multiplier | `1.5` (150% of walk speed) |
| `Gravity` | number | Gravity strength (cm/s²) | `980` (9.8 m/s²) |
| `StepOffset` | number | Max auto-climbable step height (cm) | `100` (1 meter) |
| `SlopeLimit` | number | Max walkable slope angle (degrees) | `45` |
| `MaxHealth` | number | Maximum health points | `100` |
| `Health` | number | Current health points | `100` |
| `CollideGroupID` | number | Collision layer | `1` (player layer) |
| `PhysXRoleType` | number | Physics type | `1` (character controller) |
| `StandardSkeleton` | number | Skeleton type | `2` (humanoid) |
| `Friction` | number | Movement friction | `0.91` |
| `AutoRotate` | boolean | Auto-rotate toward movement | `true` |
| `UseCameraAngle` | boolean | Use camera for movement direction | `false` |

### Step 2: Create Avatar Part Group

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate/AvatarPartGroup.json`

```json
{
  "ClassType": "AvatarGroupPart",
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

#### Step 2.1: Create Required Avatar Parts

Create these JSON files inside `ServiceNodes/StartPlayer/PlayerActorTemplate/AvatarPartGroup/`:

**BODY.json** (Required):
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

**HEAD.json** (Required):
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

**FACE.json** (Required):
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

**SKIN.json** (Required):
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

#### Avatar Part Types Reference

| PartType Value | Part Name | Description | Required |
|----------------|-----------|-------------|----------|
| `0` | BODY | Body mesh | ✅ Yes |
| `1` | HEAD | Head mesh | ✅ Yes |
| `2` | FACE | Facial features | ✅ Yes |
| `3` | JACKET | Upper body clothing | Optional |
| `4` | TROUSERS | Lower body clothing | Optional |
| `5` | SHOE | Footwear | Optional |
| `6` | BACK_ORNAMENT | Back decoration (wings, backpack) | Optional |
| `7` | FACE_ORNAMENT | Face decoration (glasses, mask) | Optional |
| `8` | HAND_ORNAMENT | Hand decoration (gloves, bracelet) | Optional |
| `9` | RIGHT_HAND | Right hand item/weapon | Optional |
| `10` | SKIN | Skin texture | ✅ Yes |
| `11` | HEAD_EFFECT | Head particle effects | Optional |
| `12` | HAND_EFFECT | Hand particle effects | Optional |
| `13` | FOOTPRINT | Footprint effect | Optional |
| `14` | BG_EFFECT | Background effect | Optional |
| `15` | TRAILING_EFFECT | Trail effect | Optional |
| `16` | WHOLE_BODY_EFFECT | Full body effect | Optional |
| `17` | RIGHT_SHOE | Right shoe | Optional |
| `18` | FACE_EFFECT | Face particle effects | Optional |

### Step 3: Create Behavior Groups

#### Step 3.1: Create MoveGroup

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate/MoveGroup.json`

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

⚠️ **Important**: MoveGroup **must** use `GroupID: 2` (system reserved for movement behaviors)

#### Step 3.2: Create Movement Behaviors

Create these files inside `ServiceNodes/StartPlayer/PlayerActorTemplate/MoveGroup/`:

**IdleBehavior.json**:
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

**WalkBehavior.json**:
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

**JumpBehavior.json**:
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

**FlyBehavior.json**:
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

**DropBehavior.json**:
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

#### Common Behavior IDs Reference

| BehaviorID | Behavior Name | Description | Animation Required |
|------------|---------------|-------------|-------------------|
| `1` | Spawn | Character spawning | Optional |
| `2` | Alive | Living state (default) | No animation |
| `3` | Dead | Death state | Yes (death animation) |
| `4` | ReSpawn | Respawning | Optional |
| `5` | Idle | Standing still | Yes (idle animation) |
| `6` | Walk | Walking/Running | Yes (walk/run animation) |
| `7` | Jump | Jumping | Yes (jump animation) |
| `8` | Crouch | Crouching | Optional |
| `9` | Drop | Falling | Yes (fall animation) |
| `10` | Fly | Flying | Yes (fly animation) |
| `11` | SitDown | Sitting down | Optional |
| `12` | StandUp | Standing up from sit | Optional |

### Step 3.3: Create LivingGroup

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate/LivingGroup.json`

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

Create these behavior files inside `LivingGroup/`:

**SpawnBehavior.json**:
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SpawnBehavior",
  "reflex": [
    {"Name": "SpawnBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 1},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 0},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": ""},
    {"LegacyAutoStop": true}
  ]
}
```

**AliveBehavior.json**:
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "AliveBehavior",
  "reflex": [
    {"Name": "AliveBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 2},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 0},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": ""},
    {"LegacyAutoStop": true}
  ]
}
```

**DeadBehavior.json**:
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "DeadBehavior",
  "reflex": [
    {"Name": "DeadBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 3},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 100106},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Death"},
    {"LegacyAutoStop": true}
  ]
}
```

**ReSpawnBehavior.json**:
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ReSpawnBehavior",
  "reflex": [
    {"Name": "ReSpawnBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 4},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 0},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": ""},
    {"LegacyAutoStop": true}
  ]
}
```

### Step 3.4: Create InteractGroup

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate/InteractGroup.json`

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

Create interaction behaviors inside `InteractGroup/`:

**SitDownBehavior.json**:
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SitDownBehavior",
  "reflex": [
    {"Name": "SitDownBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 11},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 0},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Sit"},
    {"LegacyAutoStop": true}
  ]
}
```

**StandUpBehavior.json**:
```json
{
  "ClassType": "BehaviorItem",
  "attribute": [],
  "flags": 0,
  "realNodeName": "StandUpBehavior",
  "reflex": [
    {"Name": "StandUpBehavior"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"BehaviorID": 12},
    {"SkeletonType": 2},
    {"LegacyAnimationID": 0},
    {"AnimatorStateLayer": 0},
    {"AnimatorStateName": "Base Layer.Stand"},
    {"LegacyAutoStop": true}
  ]
}
```

### Step 4: Add Animation Components

#### Step 4.1: Create Animator (Modern Animation System)

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate/Animator.json`

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

**Key Animator Properties**:
- `ControllerAsset`: Path to animation controller (state machine)
- `Speed`: Animation playback speed multiplier (1 = normal speed)
- `IsReplication`: Replicate animations across network
- `ModelWaitForLoaded`: Wait for model to load before playing animations

#### Step 4.2: Create LegacyAnimation (Backward Compatibility)

**File**: `ServiceNodes/StartPlayer/PlayerActorTemplate/LegacyAnimation.json`

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

---

## Method 2: Dynamic Creation via Lua

While PlayerActorTemplate is typically configured statically via JSON, you can modify it at runtime or create custom actor instances using Lua.

### Accessing Player Actor at Runtime

```lua
-- Get the StartPlayer service
local StartPlayer = game:GetService("StartPlayer")

-- Access the player template
local playerTemplate = StartPlayer:FindFirstChild("PlayerActorTemplate")

if playerTemplate then
    -- Modify template properties at runtime
    playerTemplate.Movespeed = 500  -- Increase movement speed
    playerTemplate.JumpBaseSpeed = 500  -- Increase jump height
    playerTemplate.MaxHealth = 150  -- Increase max health
end
```

### Modifying Player Instance After Spawn

```lua
-- Get local player's character
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

if localPlayer then
    local character = localPlayer.Character

    if character then
        -- Modify player movement
        character.Movespeed = 600
        character.RunSpeedFactor = 2.0

        -- Modify player health
        character:SetMaxHealth(200)
        character:SetHealth(200)

        -- Modify physics
        character:SetGravity(800)  -- Lower gravity
        character:SetStepOffset(150)  -- Higher step climbing
    end
end
```

### Changing Avatar Parts Dynamically

```lua
local character = Players.LocalPlayer.Character
local avatarGroup = character:FindFirstChild("AvatarPartGroup")

if avatarGroup then
    -- Find a specific part
    for _, child in ipairs(avatarGroup:GetChildren()) do
        if child.Name == "JACKET" then
            -- Change jacket model
            child.ModelId = 10001  -- New jacket ID
            child:DoLoadPartModel()
        end

        if child.Name == "BODY" then
            -- Change body color
            local colors = {ColorQuad.new(255, 200, 150, 255)}
            child:AlterAvatarPartColor(1, {0}, colors)
        end
    end
end
```

### Custom Behavior Triggers

```lua
local character = Players.LocalPlayer.Character

-- Listen to movement state changes
character.NotifyMoveStateChange:Connect(function(oldState, newState)
    print("Player state changed from " .. tostring(oldState) .. " to " .. tostring(newState))

    -- Trigger custom effects based on state
    if newState == Enum.BehaviorState.Jump then
        print("Player jumped!")
        -- Add jump effects
    elseif newState == Enum.BehaviorState.Walk then
        print("Player is walking")
        -- Add footstep sounds
    end
end)

-- Listen to health changes
character.NotifyDied:Connect(function(isDead)
    if isDead then
        print("Player died!")
        -- Handle death logic
    end
end)
```

---

## Complete Minimal Example

Here's the absolute minimum PlayerActorTemplate structure that will work:

**Directory Structure**:
```
ServiceNodes/StartPlayer/
└── PlayerActorTemplate.json
    ├── AvatarPartGroup/
    │   ├── BODY.json
    │   ├── HEAD.json
    │   ├── FACE.json
    │   └── SKIN.json
    ├── MoveGroup.json
    │   ├── IdleBehavior.json
    │   ├── WalkBehavior.json
    │   ├── JumpBehavior.json
    │   ├── FlyBehavior.json
    │   └── DropBehavior.json
    ├── LivingGroup.json
    │   ├── SpawnBehavior.json
    │   ├── AliveBehavior.json
    │   ├── DeadBehavior.json
    │   └── ReSpawnBehavior.json
    ├── Animator.json
    └── LegacyAnimation.json
```

This minimal setup provides:
- ✅ Basic player appearance (body, head, face, skin)
- ✅ Movement capabilities (idle, walk, jump, fly, fall)
- ✅ Lifecycle states (spawn, alive, dead, respawn)
- ✅ Animation system (both modern and legacy)

---

## Property Reference

### Actor Core Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `ClassType` | string | - | Must be "Actor" | Required |
| `ModelId` | string | - | Player model prefab path | Required |
| `Movespeed` | number | cm/s | Walking speed | 400 |
| `JumpBaseSpeed` | number | cm/s | Initial jump velocity | 400 |
| `JumpContinueSpeed` | number | cm/s | Sustained jump velocity | 0 |
| `RunSpeedFactor` | number | multiplier | Sprint speed multiplier | 1.5 |
| `Gravity` | number | cm/s² | Gravity acceleration | 980 |
| `StepOffset` | number | cm | Max auto-climb step height | 100 |
| `SlopeLimit` | number | degrees | Max walkable slope angle | 45 |
| `MaxHealth` | number | HP | Maximum health points | 100 |
| `Health` | number | HP | Current health points | 100 |
| `Friction` | number | coefficient | Movement friction | 0.91 |
| `Size` | [x, y, z] | cm | Character collision box size | Model-dependent |
| `Center` | [x, y, z] | cm | Collision box center offset | Model-dependent |
| `CollideGroupID` | number | layer | Collision layer (1=player) | 1 |
| `PhysXRoleType` | number | enum | Physics type (1=character) | 1 |
| `StandardSkeleton` | number | enum | Skeleton type (2=humanoid) | 2 |
| `AutoRotate` | boolean | - | Auto-rotate toward movement | true |
| `UseCameraAngle` | boolean | - | Use camera for direction | false |
| `CanAutoJump` | boolean | - | Enable auto-jump | false |
| `CanPushOthers` | boolean | - | Can push other actors | false |

### Behavior Item Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `ClassType` | string | Type identifier | "BehaviorItem" |
| `BehaviorID` | number | Behavior type identifier | See Behavior IDs table |
| `SkeletonType` | number | Skeleton type (2=humanoid) | 2 |
| `LegacyAnimationID` | number | Legacy animation ID | 100100-100109 |
| `AnimatorStateName` | string | Animator state machine path | "Base Layer.Idle" |
| `AnimatorStateLayer` | number | Animation layer index | 0 |
| `LegacyAutoStop` | boolean | Auto-stop legacy animation | true/false |

### Avatar Part Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `ClassType` | string | Type identifier | "AvatarPart" |
| `PartType` | number | Avatar part type | See Avatar Part Types table |
| `ModelId` | number | Model resource ID | -1 (use default) |
| `ModelResId` | string | Model resource path | "" (empty for default) |
| `DiffuseTexResId` | string | Diffuse texture path | "" (empty for default) |
| `EmissiveTexResId` | string | Emissive texture path | "" (empty for default) |
| `Show` | boolean | Show this part | true |

---

## Common Use Cases

### Use Case 1: Fast Player

```json
{
  "Movespeed": 800,
  "JumpBaseSpeed": 600,
  "RunSpeedFactor": 2.0,
  "Gravity": 980
}
```

### Use Case 2: Slow Heavy Player

```json
{
  "Movespeed": 200,
  "JumpBaseSpeed": 200,
  "RunSpeedFactor": 1.2,
  "Gravity": 1200,
  "StepOffset": 50
}
```

### Use Case 3: High Jump Player

```json
{
  "Movespeed": 400,
  "JumpBaseSpeed": 800,
  "JumpContinueSpeed": 200,
  "Gravity": 800
}
```

### Use Case 4: Tank Player (High Health)

```json
{
  "Movespeed": 300,
  "MaxHealth": 300,
  "Health": 300,
  "JumpBaseSpeed": 300,
  "RunSpeedFactor": 1.3
}
```

---

## Best Practices

### 1. Movement Tuning
- ✅ **Standard walking speed**: 400 cm/s (4 m/s) feels natural for most games
- ✅ **Sprint multiplier**: 1.5x is common, 2x feels very fast
- ✅ **Jump speed**: 400-600 cm/s for normal jumps, 800+ for platformers
- ✅ **Gravity**: 980 cm/s² (Earth gravity) is standard, lower for floaty feel

### 2. Collision Settings
- ✅ **Always use CollideGroupID = 1** for player characters
- ✅ **PhysXRoleType = 1** (character controller) for proper movement
- ✅ **StepOffset = 100** allows players to climb 1m steps automatically
- ✅ **SlopeLimit = 45** prevents sliding on steep slopes

### 3. Health System
- ✅ **Start with Health = MaxHealth** to avoid confusion
- ✅ **Use round numbers** (100, 150, 200) for easier balance
- ✅ **Consider game type**: FPS (100 HP), RPG (1000+ HP), casual (3 hearts)

### 4. Behavior Groups
- ✅ **MoveGroup GroupID must be 2** (system requirement)
- ✅ **Include all 5 basic movement behaviors** (Idle, Walk, Jump, Fly, Drop)
- ✅ **Include all 4 lifecycle behaviors** (Spawn, Alive, Dead, ReSpawn)
- ✅ **InteractGroup is optional** but recommended for sit/emote systems

### 5. Avatar Parts
- ✅ **Always include BODY, HEAD, FACE, SKIN** (required parts)
- ✅ **Use ModelId = -1 for default appearance**
- ✅ **Set Show = true** for all visible parts
- ✅ **Optional parts** (JACKET, TROUSERS, SHOE) can be added for customization

### 6. Animation System
- ✅ **Use both Animator and LegacyAnimation** for compatibility
- ✅ **ControllerAsset must match player model** skeleton type
- ✅ **Set IsReplication = true** for multiplayer synchronization
- ✅ **Match AnimatorStateName** to controller state machine paths

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Missing Required Avatar Parts

**Problem**: Player appears invisible or model fails to load

**Solution**: Ensure BODY, HEAD, FACE, and SKIN parts are all present
```json
// Required: All four parts must exist
AvatarPartGroup/
├── BODY.json (PartType: 0)
├── HEAD.json (PartType: 1)
├── FACE.json (PartType: 2)
└── SKIN.json (PartType: 10)
```

### ❌ Mistake 2: Wrong MoveGroup GroupID

**Problem**: Movement doesn't work, behaviors don't trigger

**Solution**: MoveGroup **must** use GroupID = 2
```json
{
  "ClassType": "OnlyOneBehaviorGroup",
  "realNodeName": "MoveGroup",
  "reflex": [
    {"GroupID": 2}  // MUST be 2 for movement
  ]
}
```

### ❌ Mistake 3: Incorrect BehaviorID Mapping

**Problem**: Animations play at wrong times or not at all

**Solution**: Use correct BehaviorIDs:
- Idle = 5
- Walk = 6
- Jump = 7
- Fly = 10
- Drop = 9

### ❌ Mistake 4: Wrong CollideGroupID

**Problem**: Player falls through floor or can't collide with objects

**Solution**: Use CollideGroupID = 1 for players, 2 for terrain
```json
{
  "CollideGroupID": 1,  // Players use layer 1
  "EnablePhysics": true
}
```

### ❌ Mistake 5: Mismatched Animator Controller

**Problem**: Animations don't play or character freezes

**Solution**: Ensure ControllerAsset matches player model's skeleton
```json
{
  "ControllerAsset": "sandboxSysId&restype=12://ministudio/entity/player/defaultplayer/Animation/OfficialController.controller",
  "StandardSkeleton": 2  // Must match controller skeleton type
}
```

### ❌ Mistake 6: Missing Animation States

**Problem**: Some behaviors work but others freeze character

**Solution**: Ensure AnimatorStateName matches controller states
```json
{
  "BehaviorID": 5,
  "AnimatorStateName": "Base Layer.Idle"  // Must exist in controller
}
```

### ❌ Mistake 7: PlayerActorTemplate in Wrong Location

**Problem**: Players don't spawn or template doesn't work

**Solution**: Must be directly inside StartPlayer service
```
✅ Correct: ServiceNodes/StartPlayer/PlayerActorTemplate.json
❌ Wrong: ServiceNodes/WorkSpace/PlayerActorTemplate.json
❌ Wrong: ServiceNodes/MainStorage/PlayerActorTemplate.json
```

### ❌ Mistake 8: Wrong AvatarPartGroup ClassType

**Problem**: Import fails with error `createNodeByType failure=>AvatarPartGroup`

**Solution**: Use `"AvatarGroupPart"` not `"AvatarPartGroup"` as ClassType
```json
{
  "ClassType": "AvatarGroupPart",  // ✅ Correct
  // NOT "AvatarPartGroup" ❌
  "realNodeName": "AvatarPartGroup",
  "reflex": [
    {"Name": "AvatarPartGroup"}
  ]
}
```

**Note**: The `realNodeName` and `Name` should still be `"AvatarPartGroup"`, but the `ClassType` must be `"AvatarGroupPart"`.

---

## Validation Checklist

Before finalizing your PlayerActorTemplate:

### Actor Root
- [ ] `ClassType = "Actor"` is set
- [ ] Placed in `ServiceNodes/StartPlayer/`
- [ ] `ModelId` points to valid player model prefab
- [ ] Movement properties configured (Movespeed, JumpBaseSpeed, etc.)
- [ ] Health properties set (MaxHealth, Health)
- [ ] Physics properties configured (Gravity, CollideGroupID, PhysXRoleType)
- [ ] `StandardSkeleton = 2` for humanoid

### Avatar Parts
- [ ] AvatarPartGroup exists
- [ ] BODY part exists (PartType = 0)
- [ ] HEAD part exists (PartType = 1)
- [ ] FACE part exists (PartType = 2)
- [ ] SKIN part exists (PartType = 10)
- [ ] All parts have `Show = true`

### Behavior Groups
- [ ] MoveGroup exists with `GroupID = 2`
- [ ] IdleBehavior exists (BehaviorID = 5)
- [ ] WalkBehavior exists (BehaviorID = 6)
- [ ] JumpBehavior exists (BehaviorID = 7)
- [ ] FlyBehavior exists (BehaviorID = 10)
- [ ] DropBehavior exists (BehaviorID = 9)
- [ ] LivingGroup exists
- [ ] SpawnBehavior exists (BehaviorID = 1)
- [ ] AliveBehavior exists (BehaviorID = 2)
- [ ] DeadBehavior exists (BehaviorID = 3)
- [ ] ReSpawnBehavior exists (BehaviorID = 4)

### Animation System
- [ ] Animator exists
- [ ] ControllerAsset path is valid
- [ ] LegacyAnimation exists
- [ ] Behavior AnimatorStateNames match controller states
- [ ] `IsReplication = true` for multiplayer

### Testing
- [ ] Player spawns successfully
- [ ] Player can move and walk
- [ ] Player can jump
- [ ] Player can respawn after death
- [ ] Animations play correctly
- [ ] Collision works with terrain

---

## Related Documentation

- [How to Add Player Spawn Points](how-to-add-player-spawn.md) - Configure where players spawn
- [How to Control Camera](../how-to-control-camera.md) - Set up camera following player
- [How to Add GeoSolid Elements](how-to-add-geosolid.md) - Create terrain for players to walk on
- [SandboxActor API Reference](../PromptTpl/refDoc/Documents/Actor/SandboxActor.md) - Complete Actor class documentation

---

## Quick Reference Card

### Minimal Working Template

**What you need**:
1. PlayerActorTemplate.json (Actor root)
2. AvatarPartGroup/ with BODY, HEAD, FACE, SKIN
3. MoveGroup/ (GroupID=2) with 5 behaviors
4. LivingGroup/ with 4 behaviors
5. Animator.json + LegacyAnimation.json

### Critical Values

| Setting | Value | Why |
|---------|-------|-----|
| Location | `StartPlayer/` | Only location that works |
| CollideGroupID | `1` | Player collision layer |
| MoveGroup GroupID | `2` | System requirement |
| PhysXRoleType | `1` | Character controller |
| StandardSkeleton | `2` | Humanoid skeleton |
| SkeletonType (Behaviors) | `2` | Humanoid skeleton |

### Common Movement Speeds

| Use Case | Movespeed | JumpBaseSpeed | RunSpeedFactor |
|----------|-----------|---------------|----------------|
| Standard | 400 | 400 | 1.5 |
| Fast | 600-800 | 500-600 | 1.8-2.0 |
| Slow | 200-300 | 300 | 1.2-1.3 |
| Platformer | 500 | 600-800 | 1.5 |

---

## Troubleshooting

### Player doesn't spawn
1. Check PlayerActorTemplate is in `ServiceNodes/StartPlayer/`
2. Verify player spawn point exists (see [How to Add Player Spawn](how-to-add-player-spawn.md))
3. Check console for model loading errors

### Player appears invisible
1. Verify all required avatar parts exist (BODY, HEAD, FACE, SKIN)
2. Check `ModelId` path is valid
3. Ensure `Show = true` for all parts

### Player can't move
1. Verify MoveGroup has `GroupID = 2`
2. Check all 5 movement behaviors exist
3. Verify Movespeed > 0

### Player falls through floor
1. Check CollideGroupID = 1
2. Verify EnablePhysics = true
3. Ensure terrain has CollideGroupID = 2 and CanCollide = true

### Animations don't play
1. Check ControllerAsset path is valid
2. Verify AnimatorStateNames match controller states
3. Ensure BehaviorIDs are correct (Idle=5, Walk=6, Jump=7)
4. Check StandardSkeleton = 2 matches skeleton type

---

**Summary**: PlayerActorTemplate is a multi-component system combining Actor properties, avatar parts, behavior groups, and animation systems. The key is creating the complete hierarchy with all required components, using correct property values (especially MoveGroup GroupID=2 and CollideGroupID=1), and ensuring animation state names match the controller.
