# How to Move Actors in MiniWorld Studio

## Overview

**Actor Movement** enables dynamic NPC behavior, monster AI, patrol systems, and skill projectiles in MiniWorld Studio games. Actors are game objects wrapped in the framework with a component system (AvatarComponent, StatComponent, etc.) that provides specialized movement capabilities through the Action System.

### Primary Use Cases
- **NPC Patrol Routes**: Guards, villagers, quest characters
- **Monster AI**: Chase behavior, attack patterns, roaming
- **Skill Projectiles**: Arrows, fireballs, magic missiles
- **Cutscene Choreography**: Scripted character movements
- **Interactive Characters**: Companions, followers, pets

## Core Concepts

### Actors vs Scene Objects

**CRITICAL DISTINCTION**: Actors and scene objects use completely different movement systems!

| Aspect | Actors | Scene Objects |
|--------|--------|---------------|
| **Examples** | Players, NPCs, monsters, projectiles | Platforms, obstacles, decorations |
| **Creation** | ActorManager:CreateActor() | SandboxNode.new() |
| **Has AvatarComponent?** | ✅ YES (mandatory) | ❌ NO |
| **Movement Methods** | Action System (MoveBy, MoveTo, etc.) | TweenService, RunService, Direct Position |
| **Framework** | Actor framework with components | Raw game object |

**Key Principle**: The Action System REQUIRES `AvatarComponent`, which is **only available in Actor objects**. You cannot use Action System on platforms or scene objects!

### Actor Architecture

```lua
local Actor = Class.new("Actor", EventObject)

function Actor:InitServer()
    -- AvatarComponent is MANDATORY for all Actors
    local avatarComp = self:AddComponentByName("AvatarComponent")
    self:SetRootComponent(avatarComp)
    -- All movement methods require this component
end
```

**Location**: `Scripts/GameFramework/ActorModule/Actor.lua`

---

## Method 1: Action System (Recommended)

**The Action System is the PRODUCTION STANDARD for moving Actors** in MiniWorld Studio games.

### Why Action System?

✅ **Production-proven** - Used extensively in all sample games ⭐⭐⭐⭐⭐
✅ **Framework-integrated** - Works with game lifecycle
✅ **High-level API** - Simple, declarative movement
✅ **Chainable** - Sequence multiple actions together
✅ **Repeatable** - Built-in looping with RepeatForever
✅ **Event-driven** - Callbacks for movement completion
✅ **Physics-aware** - Integrates with character controller

❌ **Actors only** - Requires AvatarComponent (not for scene objects)

### Action System Requirements

**ALL Action classes require**:
1. Target must be an **Actor** instance
2. Actor must have **AvatarComponent** initialized
3. Actions call `self.target.AvatarComponent:Method()` directly

**Location**: `Scripts/GameFramework/ActorModule/Action/`

---

## Core Action Classes

### MoveBy - Relative Movement

**File**: `Scripts/GameFramework/ActorModule/Action/MoveBy.lua`

Move an actor by a relative offset from its current position.

```lua
-- Move Actor 10 units right over 2 seconds
local moveAction = MoveBy.new(actorInstance, 2.0, Vector3.new(10, 0, 0))
moveAction:Start()
```

**Parameters**:
- `target`: Actor instance
- `duration`: Time in seconds
- `offset`: Vector3 relative movement

**Implementation Detail**:
```lua
function MoveBy:StartWith(target)
    -- REQUIRES AvatarComponent
    self.startPosition = self.target.AvatarComponent:GetPosition()
    self.target.AvatarComponent:SetOverrideMoveSpeed(self.speed)
end

function MoveBy:OnUpdate(t, dt)
    -- REQUIRES AvatarComponent methods
    self.target.AvatarComponent:MoveStep(self.direction * dt * self.speed)
end
```

### MoveTo - Absolute Position

Move an actor to a specific world position.

```lua
local moveAction = MoveTo.new(actorInstance, 3.0, Vector3.new(50, 10, 30))
moveAction:Start()
```

**Parameters**:
- `target`: Actor instance
- `duration`: Time in seconds
- `position`: Vector3 target position

**Best For**:
- Moving to waypoints
- Teleporting to locations
- Returning to spawn point

### JumpBy - Parabolic Arc

Make an actor jump with a parabolic trajectory.

```lua
local jumpAction = JumpBy.new(actorInstance, 2.0, Vector3.new(5, 0, 0), 3)
jumpAction.OnJumpUp = function() print("Going up!") end
jumpAction.OnJumpDown = function() print("Coming down!") end
jumpAction:Start()
```

**Parameters**:
- `target`: Actor instance
- `duration`: Jump duration in seconds
- `offset`: Horizontal offset during jump
- `height`: Maximum jump height

**Key Features**:
- Uses parabolic formula: `y = height * 4 * t * (1 - t)`
- Calls `AddHoverCount()` to disable gravity
- Calls `ReduceHoverCount()` to restore gravity
- Callbacks for jump phases (up/down)

**Best For**:
- Character jumping across gaps
- Monster leap attacks
- Platformer movement

### RotateBy - Smooth Rotation

Rotate an actor by a relative angle.

```lua
local rotateAction = RotateBy.new(actorInstance, 1.0, Vector3.new(0, 90, 0))
rotateAction:Start()
```

**Parameters**:
- `target`: Actor instance
- `duration`: Time in seconds
- `rotation`: Vector3 rotation offset (Euler angles)

**Best For**:
- Turning to face direction
- Spinning animations
- Orientation changes

### Sequence - Action Chaining

Execute multiple actions in order.

```lua
local move1 = MoveBy.new(actor, 2.0, Vector3.new(10, 0, 0))
local move2 = MoveBy.new(actor, 2.0, Vector3.new(0, 5, 0))
local move3 = MoveBy.new(actor, 2.0, Vector3.new(-10, 0, 0))

local sequence = Sequence.new(actor, {move1, move2, move3})
sequence:Start()
```

**Parameters**:
- `target`: Actor instance
- `actions`: Array of Action instances

**Best For**:
- Multi-step patrol routes
- Complex choreography
- Cutscene movements

### RepeatForever - Infinite Looping

Repeat an action or sequence indefinitely.

```lua
local moveRight = MoveBy.new(actor, 3.0, Vector3.new(20, 0, 0))
local moveLeft = MoveBy.new(actor, 3.0, Vector3.new(-20, 0, 0))
local sequence = Sequence.new(actor, {moveRight, moveLeft})
local forever = RepeatForever.new(actor, sequence)
forever:Start()
```

**Parameters**:
- `target`: Actor instance
- `action`: Action instance to repeat

**Best For**:
- Continuous patrol routes
- Looping animations
- Persistent behaviors

---

## Practical Examples

### Example 1: Simple NPC Patrol (Back and Forth)

```lua
-- NPCPatrolScript.lua
local MoveBy = require("Scripts.GameFramework.ActorModule.Action.MoveBy")
local Sequence = require("Scripts.GameFramework.ActorModule.Action.Sequence")
local RepeatForever = require("Scripts.GameFramework.ActorModule.Action.RepeatForever")

-- Get NPC actor (assumed to be created already)
local npcActor = script.parent

-- Create patrol actions
local moveRight = MoveBy.new(npcActor, 3.0, Vector3.new(20, 0, 0))
local moveLeft = MoveBy.new(npcActor, 3.0, Vector3.new(-20, 0, 0))

-- Chain into sequence
local sequence = Sequence.new(npcActor, {moveRight, moveLeft})

-- Loop forever
local patrol = RepeatForever.new(npcActor, sequence)
patrol:Start()
```

### Example 2: Square Patrol Route

```lua
-- SquarePatrolScript.lua
local MoveBy = require("Scripts.GameFramework.ActorModule.Action.MoveBy")
local Sequence = require("Scripts.GameFramework.ActorModule.Action.Sequence")
local RepeatForever = require("Scripts.GameFramework.ActorModule.Action.RepeatForever")

local guard = script.parent

-- Create square path
local patrol1 = MoveBy.new(guard, 3.0, Vector3.new(20, 0, 0))  -- East
local patrol2 = MoveBy.new(guard, 3.0, Vector3.new(0, 0, 20))  -- South
local patrol3 = MoveBy.new(guard, 3.0, Vector3.new(-20, 0, 0)) -- West
local patrol4 = MoveBy.new(guard, 3.0, Vector3.new(0, 0, -20)) -- North

-- Chain and loop
local sequence = Sequence.new(guard, {patrol1, patrol2, patrol3, patrol4})
local forever = RepeatForever.new(guard, sequence)
forever:Start()
```

### Example 3: Monster Chase Behavior

```lua
-- MonsterChaseScript.lua
local MoveTo = require("Scripts.GameFramework.ActorModule.Action.MoveTo")

local monster = script.parent
local player = game:GetService("Players").LocalPlayer.Character

-- Chase player every 0.5 seconds
local function ChasePlayer()
    if player and player:IsValid() then
        local playerPos = player.AvatarComponent:GetPosition()

        -- Create chase action
        local chase = MoveTo.new(monster, 1.0, playerPos)
        chase:Start()

        -- Update chase target periodically
        game:GetService("Scheduler"):ScheduleOnce(0.5, ChasePlayer)
    end
end

ChasePlayer()
```

### Example 4: Jumping Across Platforms

```lua
-- JumpingCharacterScript.lua
local JumpBy = require("Scripts.GameFramework.ActorModule.Action.JumpBy")
local Sequence = require("Scripts.GameFramework.ActorModule.Action.Sequence")
local RepeatForever = require("Scripts.GameFramework.ActorModule.Action.RepeatForever")

local character = script.parent

-- Jump forward, then back
local jumpForward = JumpBy.new(character, 1.5, Vector3.new(10, 0, 0), 5)
local jumpBack = JumpBy.new(character, 1.5, Vector3.new(-10, 0, 0), 5)

-- Add callbacks
jumpForward.OnJumpUp = function()
    print("Jumping forward!")
end

jumpBack.OnJumpUp = function()
    print("Jumping back!")
end

-- Loop forever
local sequence = Sequence.new(character, {jumpForward, jumpBack})
local forever = RepeatForever.new(character, sequence)
forever:Start()
```

### Example 5: Projectile Movement

```lua
-- ArrowProjectileScript.lua
local MoveBy = require("Scripts.GameFramework.ActorModule.Action.MoveBy")

-- Get arrow actor
local arrow = script.parent

-- Shoot arrow forward 50 units over 1 second
local shoot = MoveBy.new(arrow, 1.0, Vector3.new(50, 0, 0))

-- When arrow completes movement, destroy it
shoot.OnComplete = function()
    arrow:Destroy()
end

shoot:Start()
```

### Example 6: Rotating Turret

```lua
-- TurretRotationScript.lua
local RotateBy = require("Scripts.GameFramework.ActorModule.Action.RotateBy")
local RepeatForever = require("Scripts.GameFramework.ActorModule.Action.RepeatForever")

local turret = script.parent

-- Rotate 360 degrees every 4 seconds
local rotate = RotateBy.new(turret, 4.0, Vector3.new(0, 360, 0))

-- Loop forever
local spin = RepeatForever.new(turret, rotate)
spin:Start()
```

---

## Action System Complete Example

```lua
-- ActorMovementSystem.lua
-- Complete system for moving NPCs, monsters, skill projectiles, etc.

local MoveBy = require("Scripts.GameFramework.ActorModule.Action.MoveBy")
local Sequence = require("Scripts.GameFramework.ActorModule.Action.Sequence")
local RepeatForever = require("Scripts.GameFramework.ActorModule.Action.RepeatForever")

-- Create an Actor (not a raw scene node!)
local actorManager = game:GetService("ActorManager")
local npcActor = actorManager:CreateActor("Monster", "patrol_guard")

-- Now use Action System
local patrol1 = MoveBy.new(npcActor, 3.0, Vector3.new(20, 0, 0))
local patrol2 = MoveBy.new(npcActor, 3.0, Vector3.new(0, 0, 20))
local patrol3 = MoveBy.new(npcActor, 3.0, Vector3.new(-20, 0, 0))
local patrol4 = MoveBy.new(npcActor, 3.0, Vector3.new(0, 0, -20))

local sequence = Sequence.new(npcActor, {patrol1, patrol2, patrol3, patrol4})
local forever = RepeatForever.new(npcActor, sequence)
forever:Start()
```

**CRITICAL WARNING**: If you try to use Action System on a SandboxModelObject or other scene node, you will get:
```
Runtime Error: attempt to index field 'AvatarComponent' (a nil value)
```

---

## Method 2: Direct Position Manipulation

For immediate, non-animated movement (teleportation, instant repositioning).

### Position Control

```lua
local actor = script.parent  -- Actor instance

-- World position
actor.AvatarComponent:SetPosition(Vector3.new(10, 5, 0))
local pos = actor.AvatarComponent:GetPosition()

-- Instant teleportation
actor.AvatarComponent:SetPosition(spawnPoint)
```

### Rotation Control

```lua
-- Euler angles (degrees)
actor.AvatarComponent:SetRotation(Vector3.new(0, 45, 0))
local rot = actor.AvatarComponent:GetRotation()

-- Look at target
local targetPos = enemy.AvatarComponent:GetPosition()
actor.AvatarComponent:LookAt(targetPos)
```

**Best For**:
- Teleportation
- Instant respawn
- Snapping to positions
- Resetting position

---

## Best Practices

### 1. Use Action System for Complex Movement

**For Actor Objects (Characters, NPCs, Monsters)**:
- ✅ Use **Action System** (MoveBy, MoveTo, JumpBy, etc.) ⭐⭐⭐⭐⭐
- ✅ Use **Sequence** for multi-step behaviors
- ✅ Use **RepeatForever** for continuous loops
- ✅ Use **Direct Position** only for teleports

❌ **Never use TweenService on Actors** - Action System is designed for Actors
❌ **Never use Action System on scene objects** - Will crash with nil AvatarComponent

### 2. Action Lifecycle

```lua
-- Create action
local action = MoveBy.new(actor, duration, offset)

-- Configure callbacks (optional)
action.OnComplete = function()
    print("Movement finished!")
end

-- Start action
action:Start()

-- Control action (if needed)
action:Pause()    -- Pause
action:Resume()   -- Resume
action:Stop()     -- Stop completely
```

### 3. Performance Guidelines

**Action System**:
- ✅ Framework-optimized
- ✅ Good for many AI actors
- ✅ Integrated with game logic
- ✅ Handles physics automatically

**Recommendations**:
- Limit simultaneous complex sequences (< 100)
- Reuse action instances when possible
- Clean up completed actions
- Use RepeatForever for infinite loops (don't recreate)

### 4. Movement Speed Tuning

| Actor Type | Duration | Use Case |
|------------|----------|----------|
| NPC patrol | 2-5 sec | Leisurely walking |
| Monster chase | 1-3 sec | Aggressive pursuit |
| Projectile | 0.5-2 sec | Arrow/spell speed |
| Cutscene | Varies | Scripted timing |

### 5. Common Patterns

**Patrol Route**:
```lua
local points = {
    MoveBy.new(actor, 2, Vector3.new(10, 0, 0)),
    MoveBy.new(actor, 2, Vector3.new(0, 0, 10)),
    MoveBy.new(actor, 2, Vector3.new(-10, 0, 0)),
    MoveBy.new(actor, 2, Vector3.new(0, 0, -10))
}
local sequence = Sequence.new(actor, points)
local forever = RepeatForever.new(actor, sequence)
forever:Start()
```

**Chase then Attack**:
```lua
local chase = MoveTo.new(monster, 1.0, playerPos)
chase.OnComplete = function()
    -- Attack when reached
    monster:PlayAnimation("Attack")
end
chase:Start()
```

**Jump Puzzle**:
```lua
local jump1 = JumpBy.new(char, 1.0, Vector3.new(5, 0, 0), 3)
local jump2 = JumpBy.new(char, 1.0, Vector3.new(5, 0, 5), 4)
local jump3 = JumpBy.new(char, 1.0, Vector3.new(0, 0, 5), 3)
local sequence = Sequence.new(char, {jump1, jump2, jump3})
sequence:Start()
```

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Using Action System on Scene Objects

**Problem**: Trying to use MoveBy on platforms/obstacles
**Symptom**: `Runtime Error: attempt to index field 'AvatarComponent' (a nil value)`
**Solution**: Action System only works on Actors. Use TweenService for scene objects.

```lua
-- ❌ WRONG
local platform = SandboxNode.new("SandboxCube")
local move = MoveBy.new(platform, 2.0, Vector3.new(10, 0, 0))  -- CRASH!

-- ✅ CORRECT - Use TweenService for scene objects
local TweenService = game:GetService('TweenService')
local tween = TweenService:Create(platform, tweenInfo, {Position = Vector3.new(10, 0, 0)})
tween:Play()
```

### ❌ Mistake 2: Not Checking Actor Validity

**Problem**: Using action on destroyed or invalid actor
**Symptom**: Nil reference errors, actions not executing
**Solution**: Always check actor validity before creating actions

```lua
-- ✅ CORRECT
if actor and actor:IsValid() and actor.AvatarComponent then
    local move = MoveBy.new(actor, 2.0, Vector3.new(10, 0, 0))
    move:Start()
else
    print("Actor is invalid!")
end
```

### ❌ Mistake 3: Forgetting to Start Actions

**Problem**: Creating action but never calling :Start()
**Symptom**: Nothing happens, actor doesn't move
**Solution**: Always call :Start() on actions

```lua
-- ❌ WRONG
local move = MoveBy.new(actor, 2.0, Vector3.new(10, 0, 0))
-- Forgot to start!

-- ✅ CORRECT
local move = MoveBy.new(actor, 2.0, Vector3.new(10, 0, 0))
move:Start()  -- Actually start the action
```

### ❌ Mistake 4: Creating Actions Every Frame

**Problem**: Creating new action instances in Update() loop
**Symptom**: Poor performance, memory leaks
**Solution**: Create actions once, reuse or use RepeatForever

```lua
-- ❌ WRONG
RunService.Heartbeat:Connect(function()
    local move = MoveBy.new(actor, 1.0, Vector3.new(1, 0, 0))  -- New action every frame!
    move:Start()
end)

-- ✅ CORRECT - Use RepeatForever
local move = MoveBy.new(actor, 1.0, Vector3.new(1, 0, 0))
local forever = RepeatForever.new(actor, move)
forever:Start()
```

### ❌ Mistake 5: Conflicting Actions

**Problem**: Starting multiple movement actions on same actor simultaneously
**Symptom**: Erratic movement, unexpected behavior
**Solution**: Stop previous action before starting new one, or use Sequence

```lua
-- ✅ CORRECT - Stop before starting new
if currentAction then
    currentAction:Stop()
end
currentAction = MoveBy.new(actor, 2.0, Vector3.new(10, 0, 0))
currentAction:Start()

-- ✅ CORRECT - Use Sequence for ordered actions
local sequence = Sequence.new(actor, {action1, action2, action3})
sequence:Start()
```

---

## Validation Checklist

Before implementing actor movement:

### Actor Requirements
- [ ] Object is created as Actor (via ActorManager:CreateActor())
- [ ] Actor has AvatarComponent initialized
- [ ] Actor is valid and not destroyed
- [ ] Actor has proper collision setup

### Action Setup
- [ ] Correct Action class imported (MoveBy, MoveTo, etc.)
- [ ] Action target is Actor instance (not scene object)
- [ ] Duration and parameters are valid
- [ ] Action is started with :Start()

### Sequence/Loop Setup
- [ ] All actions in sequence target same actor
- [ ] Sequence array is not empty
- [ ] RepeatForever wraps sequence (not individual actions)
- [ ] Actions are properly chained

### Performance
- [ ] Not creating actions every frame
- [ ] Actions cleaned up when no longer needed
- [ ] Simultaneous actions limited (< 100 complex sequences)
- [ ] RepeatForever used for infinite loops (not recreation)

---

## Quick Reference Card

### Minimum Working Actor Movement

**Simple Back-and-Forth Patrol**:
```lua
local MoveBy = require("Scripts.GameFramework.ActorModule.Action.MoveBy")
local Sequence = require("Scripts.GameFramework.ActorModule.Action.Sequence")
local RepeatForever = require("Scripts.GameFramework.ActorModule.Action.RepeatForever")

local actor = script.parent
local right = MoveBy.new(actor, 3.0, Vector3.new(20, 0, 0))
local left = MoveBy.new(actor, 3.0, Vector3.new(-20, 0, 0))
local seq = Sequence.new(actor, {right, left})
local loop = RepeatForever.new(actor, seq)
loop:Start()
```

**One-Time Movement**:
```lua
local MoveTo = require("Scripts.GameFramework.ActorModule.Action.MoveTo")
local move = MoveTo.new(actor, 2.0, Vector3.new(50, 10, 30))
move:Start()
```

### Critical Values
- **Movement duration**: 1-5 seconds typical
- **Patrol speed**: 2-3 seconds per segment
- **Chase speed**: 1-2 seconds for aggressive
- **Jump height**: 3-5 units typical

### Action Class Locations
- `Scripts/GameFramework/ActorModule/Action/MoveBy.lua`
- `Scripts/GameFramework/ActorModule/Action/MoveTo.lua`
- `Scripts/GameFramework/ActorModule/Action/JumpBy.lua`
- `Scripts/GameFramework/ActorModule/Action/RotateBy.lua`
- `Scripts/GameFramework/ActorModule/Action/Sequence.lua`
- `Scripts/GameFramework/ActorModule/Action/RepeatForever.lua`

---

## Troubleshooting

### Actor doesn't move
1. ✅ Check actor has AvatarComponent (is an Actor, not scene object)
2. ✅ Verify action:Start() was called
3. ✅ Check actor is valid (not destroyed)
4. ✅ Verify movement parameters are non-zero

### "AvatarComponent is nil" error
1. ✅ Object is NOT an Actor (it's a scene object)
2. ✅ Use TweenService instead of Action System
3. ✅ Or create actor with ActorManager:CreateActor()

### Action executes once then stops
1. ✅ Need RepeatForever for continuous loops
2. ✅ Check sequence is wrapped in RepeatForever
3. ✅ Verify action wasn't stopped prematurely

### Erratic or jittery movement
1. ✅ Multiple conflicting actions running simultaneously
2. ✅ Stop previous action before starting new one
3. ✅ Use Sequence for ordered execution
4. ✅ Check for conflicting direct position manipulation

### Actor moves but doesn't rotate
1. ✅ Actor movement doesn't auto-rotate by default
2. ✅ Use RotateBy action explicitly
3. ✅ Or enable AutoRotate on actor
4. ✅ Use LookAt for instant rotation

---

## Production Examples from Sample Games

### Example: Projectile Binding (FixedJoint)

**Source**: `samplecode/fk/ServiceNodes/MainStorage/Scripts/GameFramework/ActorModule/Projectile.lua`

```lua
-- Arrow sticks to enemy when hit
if self.bindTarget and not self.binds[targetActor] then
    local fixedJoint = FixedJoint:new()
    fixedJoint:Init(self, targetActor)
    self.binds[targetActor] = fixedJoint
end
```

**Use Case**: Arrow projectile actor binds to enemy actor on hit

---

## Related Documentation

- [How to Move Scene Objects](how-to-move-scene-object.md) - Platform/obstacle movement with TweenService
- [How to Add Physics Joints](how-to-add-physics-joint.md) - Joint-based connections
- [Actor Module Reference](../Scripts/GameFramework/ActorModule/Actor.lua) - Actor framework
- [Action System Reference](../Scripts/GameFramework/ActorModule/Action/) - All action classes

---

## Summary Decision Tree

```
What are you trying to move?
│
├─ Actor (Player/NPC/Monster)
│  │
│  ├─ Complex movement patterns → Action System (MoveBy + Sequence) ⭐⭐⭐⭐⭐
│  ├─ Instant teleport → Direct Position
│  ├─ Patrol route → Sequence + RepeatForever
│  ├─ Chase behavior → MoveTo + periodic updates
│  └─ Jumping → JumpBy
│
└─ Scene Object (Platform/Obstacle)
   └─ Use TweenService or RunService (see how-to-move-scene-object.md)
```

### Quick Recommendations

| Use Case | Object Type | Method | Production Usage |
|----------|-------------|--------|------------------|
| NPC patrol | Actor | Action System (Sequence) | ⭐⭐⭐⭐⭐ |
| Monster chase | Actor | Action System (MoveTo) | ⭐⭐⭐⭐⭐ |
| Projectile | Actor | Action System (MoveBy) | ⭐⭐⭐⭐ |
| Cutscene choreography | Actor | Action System (Sequence) | ⭐⭐⭐⭐ |
| Arrow sticks to enemy | Actor | FixedJoint | ⭐⭐⭐⭐ |

---

**Summary**: Actors (players, NPCs, monsters, projectiles) use the Action System for movement, which requires `AvatarComponent` available only in Actor objects. The core action classes are MoveBy (relative), MoveTo (absolute), JumpBy (parabolic), RotateBy (rotation), Sequence (chaining), and RepeatForever (looping). The Action System is production-proven (⭐⭐⭐⭐⭐) and provides high-level, framework-integrated movement control. Actors CANNOT use TweenService effectively - that's for scene objects. Always verify object is an Actor before using Action System to avoid "AvatarComponent is nil" errors.
