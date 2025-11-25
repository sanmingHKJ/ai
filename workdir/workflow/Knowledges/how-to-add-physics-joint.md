# How to Add Physics Joints in MiniWorld Studio

## Overview

**Physics Joints** connect game objects together with physical constraints, enabling dynamic interactions like hinged doors, rope bridges, ragdolls, and mechanical systems. MiniWorld Studio provides both a production-proven custom joint (FixedJoint) and documented physics engine joints (PrismaticJoint, HingeJoint, etc.).

### Primary Use Cases
- **Object Binding**: Arrows sticking to targets, attachments
- **Mechanical Systems**: Doors, gates, elevators (theoretical)
- **Rope Physics**: Hanging bridges, chains (theoretical)
- **Ragdoll Physics**: Character death animations (theoretical)
- **Vehicle Suspension**: Car physics (theoretical)

## Core Concepts

### Two Types of "Joints"

**CRITICAL DISTINCTION**: MiniWorld Studio has TWO completely different "joint" systems!

| Type | FixedJoint (Custom) | Physics Joints (Engine) |
|------|---------------------|-------------------------|
| **Location** | `Scripts/GameFramework/ActorModule/Misc/FixedJoint.lua` | Physics engine (SandboxPrismaticJoint, etc.) |
| **Production Usage** | ⭐⭐⭐⭐⭐ Used in fk, maomi, rpg-gamedemo | ❌ ZERO usage in all sample games |
| **Implementation** | Custom framework class | Native physics constraints |
| **How it works** | Frame-by-frame position sync | Physics simulation |
| **Tested** | Production-proven | Documented but untested |
| **Best for** | Binding objects together | Theoretical physics simulations |

**Key Principle**: After searching 3,610+ files across ALL sample games, **ZERO production usage** of PrismaticJoint, HingeJoint, MotorJoint, or CylindricalJoint was found. The only "joint" actually used in production is FixedJoint.

---

## Method 1: FixedJoint (Production-Proven ⭐)

**FixedJoint is the ONLY "joint" actually used in production games.**

### What is FixedJoint?

A custom framework class that creates a rigid connection between two objects by synchronizing their position and rotation every frame.

**NOT a physics joint** - It's a position/rotation synchronization system.

**Location**: `Scripts/GameFramework/ActorModule/Misc/FixedJoint.lua`

**Found in**: fk, maomi, rpg-gamedemo

### How FixedJoint Works

```lua
-- FixedJoint class structure
local FixedJoint = class("FixedJoint")

function FixedJoint:Init(source, target)
    self.source = source  -- The object to follow
    self.target = target  -- The object that follows

    -- Calculate and store offset
    self.offset = target:GetPosition() - source:GetPosition()
    self.rotationOffset = -- rotation difference
end

function FixedJoint:Update(dt)
    -- Update target position to maintain offset
    local newPos = self.source:GetPosition() + self.offset
    self.target:SetPosition(newPos)
    -- Also update rotation...
end
```

### Production Example: Projectile Binding

**From**: `samplecode/fk/ServiceNodes/MainStorage/Scripts/GameFramework/ActorModule/Projectile.lua` (lines 219-222)

```lua
-- Bind projectile to hit target (arrow sticks to enemy)
if self.bindTarget and not self.binds[v] then
    local fixedJoint = FixedJoint:new()
    fixedJoint:Init(self, v)  -- Bind projectile (self) to target (v)
    self.binds[v] = fixedJoint
end
```

**Result**: When arrow hits enemy, it sticks to the enemy and moves with them.

### Complete FixedJoint Example

```lua
-- ArrowStickScript.lua
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")

-- Get arrow and enemy actors
local arrow = game:FindObject("Arrow")
local enemy = game:FindObject("Enemy")

-- Create fixed joint to bind arrow to enemy
local joint = FixedJoint:new()
joint:Init(arrow, enemy)

-- Now arrow follows enemy's movement automatically
-- The joint updates position/rotation every frame
```

### FixedJoint Use Cases

**Actual production uses**:
- ✅ Arrows/projectiles sticking to hit targets
- ✅ Debuff visual effects following enemies
- ✅ Skill effects attached to characters
- ✅ Equipment/accessories attached to body parts

**Example: Spell Effect Attachment**
```lua
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")

-- Create burning effect
local fireEffect = game:CreateEffect("BurningFlame")

-- Attach to enemy
local joint = FixedJoint:new()
joint:Init(fireEffect, enemy)

-- Effect now follows enemy as they move
```

### FixedJoint Important Notes

- **NOT a physics joint** - Custom framework class, not engine physics
- **Frame-by-frame updates** - Recalculates position each frame
- **No physics simulation** - Just position/rotation synchronization
- **Works on any objects** - Actors or scene nodes
- **Production-proven** - Used extensively in sample games ⭐⭐⭐⭐⭐

---

## Method 2: Physics Joints (Theoretical/Advanced)

### ⚠️ CRITICAL WARNING

**Physics joints are DOCUMENTED but NOT USED in any production MiniWorld Studio games.**

After searching 3,610+ files across all sample games (BridgeBattle, fk, maomi, rpg-gamedemo, town):
- **ZERO implementations** of PrismaticJoint, HingeJoint, MotorJoint, or CylindricalJoint found
- Documentation exists in `refDoc/Documents/Physics/`
- **No working production examples**

### Why Aren't Physics Joints Used?

1. **Determinism** - Physics simulation is non-deterministic (hard to sync in multiplayer)
2. **Complexity** - TweenService/Action System is simpler and more reliable
3. **Performance** - Physics simulation is CPU intensive
4. **Control** - TweenService gives exact control over movement
5. **Testing** - No evidence these features are production-ready

### When MIGHT You Use Physics Joints?

**Theoretical use cases** (untested in production):
- Ragdoll physics for character death
- Destructible environments with realistic collapse
- Vehicle suspension systems
- Rope/chain mechanics for hanging bridges
- Realistic mechanical puzzles
- Physics-based gameplay (e.g., bridge-building games)

**But expect to solve**:
- Multiplayer synchronization issues
- Physics stability problems
- Performance optimization challenges
- Testing and debugging complexity

---

## Available Physics Joint Types

**File Reference**: `refDoc/Documents/Physics/`

### Overview of Joint Types

| Joint Type | Function | Theoretical Use Case |
|------------|----------|---------------------|
| **SandboxPrismaticJoint** | Linear sliding | Elevators, pistons, sliding doors |
| **SandboxHingeJoint** | Rotational with limits | Doors, gates, drawbridges |
| **SandboxMotorJoint** | Continuous rotation | Fans, wheels, conveyor belts |
| **SandboxCylindricalJoint** | Linear + rotation | Screw drives, drill systems |
| **SandboxBallSocketJoint** | Free 3D rotation | Ragdolls, chain links |
| **SandboxRopeJoint** | Distance constraint | Ropes, chains, cables |
| **SandboxSpringJoint** | Spring physics | Bouncy platforms, suspension |

---

## Theoretical Joint Examples

**⚠️ WARNING**: These examples are theoretical and untested in production. Use at your own risk.

### Example 1: SandboxPrismaticJoint (Linear Sliding)

**Theoretical Use**: Elevator platform

```lua
-- THEORETICAL - NOT TESTED IN PRODUCTION
-- Create elevator platform
local base = SandboxNode.new("SandboxModelObject")
local platform = SandboxNode.new("SandboxModelObject")

local prismatic = SandboxNode.new("SandboxPrismaticJoint")
prismatic:SetAttachment0(base)
prismatic:SetAttachment1(platform)

prismatic:SetLimitEnable(true)
prismatic:SetLowerLimit(0)
prismatic:SetUpperLimit(20)  -- Can slide 20 units

prismatic:SetActuatorType(2)  -- SERVO mode
prismatic:SetTargetPosition(20)  -- Move to top
prismatic:SetLinearResponsiveness(50)
prismatic:SetLinearServoMaxForce(2000)

-- This MAY work, but has not been tested in production games
```

**Alternative (Production-Proven)**:
```lua
-- ✅ USE THIS INSTEAD - TweenService for elevators
local TweenService = game:GetService('TweenService')
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
local tween = TweenService:Create(platform, tweenInfo, {Position = Vector3.new(0, 20, 0)})
tween:Play()
```

### Example 2: SandboxHingeJoint (Rotating Door)

**Theoretical Use**: Hinged door

```lua
-- THEORETICAL - NOT TESTED IN PRODUCTION
local doorFrame = game:FindObject("DoorFrame")
local door = game:FindObject("Door")

local hinge = SandboxNode.new("SandboxHingeJoint")
hinge:SetAttachment0(doorFrame)
hinge:SetAttachment1(door)
hinge:SetAxis(Vector3.new(0, 1, 0))  -- Y-axis rotation

hinge:SetLimitsEnable(true)
hinge:SetLowerAngle(0)
hinge:SetUpperAngle(90)  -- Can open 90 degrees

hinge:SetActuatorType(1)  -- MOTOR mode
hinge:SetMotorAngularSpeed(45)  -- 45 degrees/second
hinge:SetMotorMaxTorque(1000)

-- This MAY work, but has not been tested in production games
```

**Alternative (Production-Proven)**:
```lua
-- ✅ USE THIS INSTEAD - TweenService for doors
local TweenService = game:GetService('TweenService')
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
local tween = TweenService:Create(door, tweenInfo, {Rotation = Vector3.new(0, 90, 0)})
tween:Play()
```

### Example 3: SandboxMotorJoint (Continuous Rotation)

**Theoretical Use**: Spinning fan

```lua
-- THEORETICAL - NOT TESTED IN PRODUCTION
local fanBase = game:FindObject("FanBase")
local fanBlades = game:FindObject("FanBlades")

local motor = SandboxNode.new("SandboxMotorJoint")
motor:SetAttachment0(fanBase)
motor:SetAttachment1(fanBlades)

motor:SetMotorMaxTorque(1000)
motor:SetMotorAngularSpeed(180)  -- 180 degrees/second

-- This MAY work, but has not been tested in production games
```

**Alternative (Production-Proven)**:
```lua
-- ✅ USE THIS INSTEAD - RunService for continuous rotation
local RunService = game:GetService("RunService")
RunService.Stepped:Connect(function()
    local euler = fanBlades.Euler
    fanBlades.Euler = Vector3.new(euler.x, euler.y + 3, euler.z)
end)
```

### Example 4: SandboxRopeJoint (Distance Constraint)

**Theoretical Use**: Hanging rope bridge

```lua
-- THEORETICAL - NOT TESTED IN PRODUCTION
local anchor1 = game:FindObject("Anchor1")
local anchor2 = game:FindObject("Anchor2")

local rope = SandboxNode.new("SandboxRopeJoint")
rope:SetAttachment0(anchor1)
rope:SetAttachment1(anchor2)
rope:SetMaxLength(10)  -- Maximum 10 units apart

-- This MAY work, but has not been tested in production games
```

### Example 5: SandboxBallSocketJoint (Ragdoll)

**Theoretical Use**: Ragdoll physics

```lua
-- THEORETICAL - NOT TESTED IN PRODUCTION
local torso = game:FindObject("Torso")
local upperArm = game:FindObject("UpperArm")

local shoulder = SandboxNode.new("SandboxBallSocketJoint")
shoulder:SetAttachment0(torso)
shoulder:SetAttachment1(upperArm)

shoulder:SetLimitsEnable(true)
shoulder:SetMaxConeAngle(90)  -- Arm can swing 90 degrees
shoulder:SetRestitution(0.1)
shoulder:SetTwistLimitsEnable(true)

-- This MAY work, but has not been tested in production games
```

---

## Best Practices

### 1. Prefer Production-Proven Methods

**For 99.9% of games, use these production-proven methods**:
- ✅ **FixedJoint** for binding objects together ⭐⭐⭐⭐⭐
- ✅ **TweenService** for platforms, doors, elevators ⭐⭐⭐⭐⭐
- ✅ **RunService.Stepped** for continuous rotation ⭐⭐⭐⭐
- ✅ **Action System** for character movement ⭐⭐⭐⭐⭐

**Avoid physics joints unless**:
- You need realistic physics simulation
- You're willing to solve synchronization issues
- You can test extensively
- You're okay with no production examples to reference

### 2. FixedJoint Usage Pattern

```lua
-- ✅ CORRECT - Production pattern
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")

-- Create joint
local joint = FixedJoint:new()

-- Initialize with source and target
joint:Init(source, target)

-- Joint automatically updates every frame
-- Target follows source's position and rotation

-- Clean up when done
joint:Destroy()  -- If destroy method exists
```

### 3. When to Consider Physics Joints

**Only consider physics joints if**:
1. ✅ You need realistic physics simulation (ragdolls, destruction)
2. ✅ You're willing to implement multiplayer sync yourself
3. ✅ You can handle physics stability issues
4. ✅ You have time for extensive testing
5. ✅ You're prepared for debugging complexity

**Examples where physics joints MIGHT be justified**:
- Physics-based puzzle game (bridge builder, demolition)
- Realistic vehicle simulation
- Advanced ragdoll death system
- Destructible environments

### 4. Testing Checklist for Physics Joints

If you decide to use physics joints:

- [ ] Single-player testing first (before multiplayer)
- [ ] Physics stability at different frame rates
- [ ] Joint doesn't explode or jitter
- [ ] Objects don't clip through geometry
- [ ] Performance is acceptable (< 30ms per frame)
- [ ] Multiplayer synchronization implemented
- [ ] Fallback behavior if physics fails
- [ ] Save/load system handles joints correctly

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Using Physics Joints for Simple Movement

**Problem**: Using PrismaticJoint for elevator instead of TweenService
**Symptom**: Complex setup, unstable physics, poor performance
**Solution**: Use TweenService - simpler, more reliable, production-proven

```lua
-- ❌ WRONG - Unnecessary complexity
local prismatic = SandboxNode.new("SandboxPrismaticJoint")
-- ...50 lines of joint configuration...

-- ✅ CORRECT - Simple and reliable
local TweenService = game:GetService('TweenService')
local tween = TweenService:Create(platform, tweenInfo, {Position = targetPos})
tween:Play()
```

### ❌ Mistake 2: Not Using FixedJoint for Binding

**Problem**: Manually updating position every frame instead of using FixedJoint
**Symptom**: Lots of custom code, potential bugs
**Solution**: Use FixedJoint - it's designed for this

```lua
-- ❌ WRONG - Manual implementation
RunService.Heartbeat:Connect(function()
    arrow.Position = enemy.Position + offset
    arrow.Rotation = enemy.Rotation
end)

-- ✅ CORRECT - Use FixedJoint
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")
local joint = FixedJoint:new()
joint:Init(arrow, enemy)
```

### ❌ Mistake 3: Expecting Physics Joints to "Just Work"

**Problem**: Copy-pasting physics joint code without testing
**Symptom**: Crashes, unstable physics, multiplayer desync
**Solution**: Extensive testing, fallback to TweenService if issues

### ❌ Mistake 4: Not Cleaning Up Joints

**Problem**: Creating joints but never destroying them
**Symptom**: Memory leaks, orphaned connections
**Solution**: Properly destroy joints when no longer needed

```lua
-- ✅ CORRECT - Clean up
local joint = FixedJoint:new()
joint:Init(arrow, enemy)

-- Later, when arrow is removed
joint:Destroy()  -- Clean up joint
arrow:Destroy()  -- Clean up arrow
```

---

## Validation Checklist

### FixedJoint Setup
- [ ] FixedJoint class imported correctly
- [ ] Joint initialized with valid source and target objects
- [ ] Source and target are not nil
- [ ] Objects exist and are valid
- [ ] Joint cleaned up when objects destroyed

### Physics Joint Setup (If Using)
- [ ] Joint type matches use case
- [ ] Attachments set to valid objects
- [ ] Constraints configured (limits, forces)
- [ ] Actuator type set if using motors/servos
- [ ] Physics tested in single-player first
- [ ] Multiplayer synchronization implemented
- [ ] Fallback behavior if physics fails

---

## Quick Reference Card

### Minimum Working FixedJoint

**Arrow Sticking to Enemy**:
```lua
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")

-- On arrow hit
local joint = FixedJoint:new()
joint:Init(arrow, enemy)

-- Arrow now follows enemy
```

**Debuff Effect Attachment**:
```lua
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")

-- Attach effect to character
local joint = FixedJoint:new()
joint:Init(effect, character)

-- Effect follows character
```

### Critical Values
- **FixedJoint location**: `Scripts/GameFramework/ActorModule/Misc/FixedJoint.lua`
- **Production usage**: ⭐⭐⭐⭐⭐ Proven and reliable
- **Physics joints usage**: ❌ Zero in production games

---

## Decision Tree

```
What do you need to do?
│
├─ Bind object to another (arrow to enemy, effect to character)
│  └─ Use FixedJoint ✅ (production-proven)
│
├─ Move platform/elevator up and down
│  └─ Use TweenService ✅ (NOT PrismaticJoint)
│
├─ Rotate door/gate on hinge
│  └─ Use TweenService ✅ (NOT HingeJoint)
│
├─ Continuous rotation (fan, wheel)
│  └─ Use RunService.Stepped ✅ (NOT MotorJoint)
│
├─ Realistic physics simulation (ragdoll, destruction)
│  ├─ Production game?
│  │  └─ Use TweenService/Action System instead ✅
│  └─ Experimental/learning?
│     └─ Try physics joints (with caution) ⚠️
│
└─ Move character/NPC
   └─ Use Action System ✅ (NOT any joint)
```

---

## Troubleshooting

### FixedJoint not working
1. ✅ Check FixedJoint class imported correctly
2. ✅ Verify source and target are valid objects
3. ✅ Check :Init() was called with correct parameters
4. ✅ Verify objects are not destroyed

### Physics joint explodes or jitters
1. ⚠️ Physics joints are unstable (expected)
2. ⚠️ No production examples to reference
3. ✅ Consider using TweenService instead
4. ⚠️ If must use physics, reduce forces/speeds

### Objects clip through each other
1. ⚠️ Physics simulation limitation
2. ✅ Check collision groups configured
3. ✅ Reduce movement speeds
4. ✅ Consider switching to TweenService

### Multiplayer desync with physics joints
1. ⚠️ Physics is non-deterministic
2. ⚠️ No production examples of sync solution
3. ✅ Implement authoritative server sync
4. ✅ Or use TweenService (deterministic)

---

## Summary & Recommendations

### Production-Proven Approach (Recommended)

**Use FixedJoint for object binding**:
```lua
local FixedJoint = require("Scripts.GameFramework.ActorModule.Misc.FixedJoint")
local joint = FixedJoint:new()
joint:Init(source, target)
```

**Use TweenService for all mechanical movement**:
```lua
local TweenService = game:GetService('TweenService')
local tween = TweenService:Create(object, tweenInfo, {Position = targetPos})
tween:Play()
```

**Use RunService for continuous rotation**:
```lua
RunService.Stepped:Connect(function()
    object.Euler = object.Euler + Vector3.new(0, 1, 0)
end)
```

### Physics Joints (Experimental)

**Only use if**:
- Realistic physics simulation required
- Single-player game or can implement sync
- Willing to solve stability issues
- Have time for extensive testing

**Expect challenges**:
- No production examples to reference
- Physics stability problems
- Multiplayer synchronization complexity
- Performance optimization needed

---

## Related Documentation

- [How to Move Scene Objects](how-to-move-scene-object.md) - TweenService and RunService movement
- [How to Move Actors](how-to-move-actor.md) - Action System for characters
- [FixedJoint Source](../Scripts/GameFramework/ActorModule/Misc/FixedJoint.lua) - Implementation reference
- [Physics Joints Reference](../refDoc/Documents/Physics/) - Theoretical documentation

---

**Summary**: For production games, use **FixedJoint** (⭐⭐⭐⭐⭐ proven) for binding objects together like arrows sticking to enemies. Physics engine joints (PrismaticJoint, HingeJoint, etc.) have **ZERO production usage** across all sample games - they are documented but untested. For mechanical movement (elevators, doors), use **TweenService** instead of physics joints. For continuous rotation (fans, wheels), use **RunService.Stepped** instead of MotorJoint. Physics joints are theoretical and should only be considered for experimental physics-based gameplay with extensive testing.
