# How to Move Scene Objects in MiniWorld Studio

## Overview

**Scene Object Movement** enables dynamic platforms, elevators, rotating obstacles, and animated decorations in your MiniWorld Studio games. Scene objects (SandboxModelObject, SandboxCube, GeoSolid, etc.) are raw game objects without the Actor framework's component system, requiring different movement methods than character actors.

### Primary Use Cases
- **Moving Platforms**: Elevators, sliding platforms, conveyor belts
- **Rotating Objects**: Spinning fans, gears, decorative elements
- **Animated Obstacles**: Swinging pendulums, moving hazards
- **Interactive Elements**: Opening doors, drawbridges, trap doors
- **Environmental Animation**: Floating islands, bobbing platforms

## Core Concepts

### Scene Objects vs Actors

**CRITICAL DISTINCTION**: Scene objects and Actors use completely different movement systems!

| Aspect | Scene Objects | Actors |
|--------|---------------|--------|
| **Examples** | Platforms, obstacles, decorations | Players, NPCs, monsters |
| **Creation** | SandboxNode.new() | ActorManager:CreateActor() |
| **Has AvatarComponent?** | ❌ NO | ✅ YES (mandatory) |
| **Movement Methods** | TweenService, RunService, Direct Position | Action System (MoveBy, MoveTo, etc.) |
| **Common Mistake** | ❌ Trying to use Action System | ✅ Use TweenService instead |

**Key Principle**: If an object doesn't have `AvatarComponent`, it's a scene object and CANNOT use the Action System. Use TweenService or RunService instead.

### Available Movement Methods for Scene Objects

| Method | Best For | Production Usage | Complexity |
|--------|----------|------------------|------------|
| **TweenService** | A-to-B movement with endpoints | ⭐⭐⭐⭐⭐ Standard for platforms | Simple |
| **RunService.Stepped** | Continuous rotation/animation | ⭐⭐⭐⭐ Standard for spinning | Simple |
| **Direct Position** | Instant teleportation, manual control | ⭐⭐ Custom animations | Very Simple |

---

## Method 1: TweenService (Recommended for Platforms)

**TweenService is the PRODUCTION STANDARD method for moving platforms** in MiniWorld Studio games.

### Why TweenService?

✅ Works on any scene object (no component requirements)
✅ Smooth interpolation with 30+ easing curves
✅ Simple, declarative API
✅ **Production-proven in town sample game** ⭐
✅ Engine-optimized (better performance than manual loops)
✅ Deterministic (multiplayer-friendly)
✅ Time-based (duration in seconds, not frames)

### Basic TweenService Pattern

**Reference**: `refDoc/Documents/Services/SandboxTweenService.md`

```lua
-- Get TweenService
local TweenService = game:GetService('TweenService')

-- Get your platform (scene object)
local platform = script.parent  -- or game:FindObject("PlatformName")

-- Create TweenInfo (5 parameters as per sample code)
-- Parameters: duration, easingStyle, easingDirection, repeatCount, reverseDelay
local tweenInfo = TweenInfo.new(
    2.0,                           -- 2 seconds duration
    Enum.EasingStyle.Linear,       -- Constant speed
    Enum.EasingDirection.Out,      -- Easing direction
    0,                             -- Repeat count (0 = once)
    0                              -- Reverse delay (only used when reverse=true)
)

-- Define target properties
local goalUp = {
    LocalPosition = Vector3.new(0, 6, 0)  -- Move to Y=6
}

local goalDown = {
    LocalPosition = Vector3.new(0, 0, 0)  -- Move back to Y=0
}

-- Create tweens
local tweenUp = TweenService:Create(platform, tweenInfo, goalUp)
local tweenDown = TweenService:Create(platform, tweenInfo, goalDown)

-- Chain tweens for looping
tweenUp.Completed:Connect(function()
    tweenDown:Play()  -- Direct call, no wait() or coroutine needed
end)

tweenDown.Completed:Connect(function()
    tweenUp:Play()  -- Direct call, no wait() or coroutine needed
end)

-- Start the movement
tweenUp:Play()
```

### Available Easing Styles

| Style | Description | Best For |
|-------|-------------|----------|
| **Linear** | Constant speed | Mechanical platforms ⭐ Production standard |
| Sine | Smooth, natural | Floating platforms |
| Quad/Cubic/Quart | Acceleration curves | Dynamic platforms |
| Back | Overshoots target | Bouncy effects |
| Bounce | Bouncing motion | Spring pads |
| Elastic | Spring oscillation | Elastic platforms |

### Easing Directions

**IMPORTANT**: MiniWorld Studio uses underscores in easing direction enum values!

- `Enum.EasingDirection.In`: Slow start, fast end
- `Enum.EasingDirection.Out`: Fast start, slow end
- `Enum.EasingDirection.In_Out`: Slow start and end, fast middle (note the underscore!)

**Common Mistake**: Using `Enum.EasingDirection.InOut` (no underscore) will cause a runtime error: `bad argument #2 to 'new' (Bridge_EnumItem expected, got nil)`. Always use `In_Out` with underscore.

### Animatable Properties

```lua
-- Position
{Position = Vector3.new(10, 5, 0)}           -- World position
{LocalPosition = Vector3.new(10, 5, 0)}      -- Local position (preferred)

-- Rotation
{Rotation = Vector3.new(0, 45, 0)}           -- World rotation (Euler)
{LocalRotation = Vector3.new(0, 45, 0)}      -- Local rotation

-- Scale
{Scale = Vector3.new(2, 2, 2)}               -- World scale
{LocalScale = Vector3.new(2, 2, 2)}          -- Local scale

-- Combined (animate multiple properties at once)
{
    Position = Vector3.new(10, 5, 0),
    Rotation = Vector3.new(0, 45, 0),
    Scale = Vector3.new(1.5, 1.5, 1.5)
}
```

### Tween Control Methods

```lua
tween:Play()      -- Start/resume tween
tween:Pause()     -- Pause tween
tween:Cancel()    -- Stop and reset
tween:Destroy()   -- Clean up resources
```

### Production Example: Vertical Moving Platform

**From**: `samplecode/town/WorkSpace/CentralSquare/Interactive/MGRoundPlate/RotateTrans/SceneModelObject1/UpDownScript.lua`

```lua
-- Real production code from town game
local TweenService = game:GetService('TweenService')

-- Platform is a SceneModelObject (NOT an Actor!)
local platform = script.parent

-- TweenInfo parameters: duration, easingStyle, easingDirection, repeatCount, reverseDelay
local tweenInfo1 = TweenInfo.new(2, Enum.EasingStyle.Linear, nil, 0, 0.5)
local goal1 = {LocalPosition = Vector3.new(0, 6, 0)}
local tween1 = TweenService:Create(platform, tweenInfo1, goal1)

local tweenInfo2 = TweenInfo.new(2, Enum.EasingStyle.Linear, nil, 0, 0.5)
local goal2 = {LocalPosition = Vector3.new(0, 0, 0)}
local tween2 = TweenService:Create(platform, tweenInfo2, goal2)

-- Chain for continuous loop - simple callbacks with direct :Play() calls
tween1.Completed:Connect(function()
    tween2:Play()
end)

tween2.Completed:Connect(function()
    tween1:Play()
end)

-- Start
tween1:Play()
```

**Key Points**:
- ✅ Use direct `:Play()` calls in callbacks - no `wait()` or `coroutine.work()` needed
- ✅ TweenInfo.new() takes **5 parameters** (not 6!)
- ✅ This is the production-proven pattern from MiniWorld Studio sample code

### Advanced Pattern: Multi-Stage Platform

```lua
-- Platform with multiple waypoints
local TweenService = game:GetService('TweenService')
local platform = script.parent

local positions = {
    Vector3.new(0, 0, 0),
    Vector3.new(10, 0, 0),
    Vector3.new(10, 0, 10),
    Vector3.new(0, 0, 10)
}

local tweens = {}
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In_Out)

-- Create all tweens
for i = 1, #positions do
    local nextIndex = (i % #positions) + 1
    local goal = {Position = positions[nextIndex]}
    tweens[i] = TweenService:Create(platform, tweenInfo, goal)
end

-- Chain them
for i = 1, #tweens do
    local nextIndex = (i % #tweens) + 1
    tweens[i].Completed:Connect(function()
        tweens[nextIndex]:Play()
    end)
end

-- Start
tweens[1]:Play()
```

---

## Method 2: RunService Loop (Recommended for Rotation)

**Use RunService.Stepped for continuous updates every frame** (like rotation).

**Production Usage**: All rotating objects in town game use this method.

### Why RunService for Rotation?

✅ Natural for continuous/infinite motion
✅ Simple per-frame updates
✅ **Production-proven for spinning objects** ⭐
✅ No need to chain tweens for infinite rotation
✅ Easy to implement custom formulas (sine waves, orbits)

❌ Runs every frame (higher CPU than TweenService)
❌ Requires manual math for complex interpolation

### Pattern: Continuous Rotation

**From**: `samplecode/town/WorkSpace/CentralSquare/Interactive/MGRoundPlate/RotateTrans/RotationScript.lua`

```lua
local RunService = game:GetService("RunService")

local function Update()
    local e = script.parent.Euler
    script.parent.Euler = Vector3.new(e.x, e.y + 1, e.z)  -- Rotate 1 degree per frame
end

RunService.Stepped:Connect(function()
    Update()
end)
```

### Pattern with Speed Attribute

**From**: `samplecode/town/WorkSpace/CloneNode/FourBalls/RotationBallsScript.lua`

```lua
local RunService = game:GetService("RunService")

local function Update()
    local e = script.parent.Euler
    -- Read speed from object attribute
    local speed = script.parent.RotateSpeed.Value
    script.parent.Euler = Vector3.new(e.x, e.y, e.z + speed)
end

RunService.Stepped:Connect(function()
    Update()
end)
```

### Pattern: Local Rotation

**From**: `samplecode/town/WorkSpace/CloneNode/Hulahoop/RotationHulaHoopScript.lua`

```lua
local RunService = game:GetService("RunService")

local function Update()
    local e = script.parent.LocalEuler  -- Use LocalEuler for relative rotation
    local speed = script.parent.RotateSpeed.Value
    script.parent.LocalEuler = Vector3.new(e.x, e.y + speed, e.z)
end

RunService.Stepped:Connect(function()
    Update()
end)
```

### Complete Rotation System

```lua
-- RotatingPlatformScript.lua
-- Attach to any scene object to make it rotate

local RunService = game:GetService("RunService")
local object = script.parent

-- Configuration
local rotationSpeed = Vector3.new(0, 2, 0)  -- degrees per frame (Y-axis)
local useLocalRotation = true  -- true = relative to parent, false = world

local function Update()
    if useLocalRotation then
        local euler = object.LocalEuler
        object.LocalEuler = euler + rotationSpeed
    else
        local euler = object.Euler
        object.Euler = euler + rotationSpeed
    end
end

RunService.Stepped:Connect(Update)
```

### Pattern: Sine Wave Movement

```lua
-- Floating platform with sine wave
local RunService = game:GetService("RunService")
local platform = script.parent

local time = 0
local startY = platform.Position.y
local amplitude = 2  -- How high it floats
local frequency = 1  -- How fast it oscillates

local function Update(dt)
    time = time + dt
    local y = startY + math.sin(time * frequency) * amplitude

    local pos = platform.Position
    platform.Position = Vector3.new(pos.x, y, pos.z)
end

RunService.Heartbeat:Connect(Update)
```

### RunService Events

```lua
-- Stepped: Fires every frame BEFORE physics
RunService.Stepped:Connect(function() end)

-- Heartbeat: Fires every frame AFTER physics (has deltaTime)
RunService.Heartbeat:Connect(function(deltaTime) end)

-- RenderStepped: Fires every frame before rendering (client-only)
RunService.RenderStepped:Connect(function(deltaTime) end)
```

**Recommendation**: Use `Stepped` for simple updates, `Heartbeat` when you need deltaTime.

---

## Method 3: Direct Position Manipulation

### Overview

Direct property access for immediate position/rotation changes.

**File Reference**: `refDoc/Documents/Base/SandboxTransObject.md`

**Best For**:
- Instant teleportation
- Immediate positioning
- Frame-by-frame custom control
- Resetting positions

### Position Properties

```lua
local node = SandboxNode.new("SandboxCube")

-- World position
node.Position = Vector3.new(10, 5, 0)
node:SetWorldPosition(Vector3.new(10, 5, 0))
local pos = node:GetWorldPosition()

-- Local position (relative to parent)
node.LocalPosition = Vector3.new(5, 0, 0)
node:SetLocalPosition(Vector3.new(5, 0, 0))
local localPos = node:GetLocalPosition()
```

### Rotation Properties

```lua
-- Euler angles (degrees)
node.Euler = Vector3.new(0, 45, 0)           -- World rotation
node.LocalEuler = Vector3.new(0, 45, 0)      -- Local rotation
node:SetWorldEuler(Vector3.new(0, 45, 0))
node:SetLocalEuler(Vector3.new(0, 45, 0))

-- Quaternion (advanced)
node:SetWorldRotation(quaternion)
node:SetLocalRotation(quaternion)

-- Look at target
node:LookAt(targetPos, false)  -- ignoreY parameter
```

### Scale Properties

```lua
node.Scale = Vector3.new(2, 2, 2)            -- World scale
node.LocalScale = Vector3.new(2, 2, 2)       -- Local scale
node:SetWorldScale(Vector3.new(2, 2, 2))
node:SetLocalScale(Vector3.new(2, 2, 2))
```

---

## TweenService vs RunService: When to Use Each

### Understanding the Fundamental Difference

These are **two completely different approaches** to movement:

| Aspect | TweenService | RunService.Stepped |
|--------|-------------|-------------------|
| **Approach** | **Interpolation-based** (A to B) | **Frame-by-frame manual updates** |
| **You specify** | Start, end, duration, easing | What to do each frame |
| **Timing** | Time-based (seconds) | Frame-based (~60 FPS) |
| **When runs** | Only during tween | Every frame forever |
| **Control** | Declarative ("what") | Imperative ("how") |
| **Complexity** | Simple - engine does the work | Complex - you do all math |
| **Best for** | A-to-B movement with endpoints | Continuous/infinite motion |

### TweenService: Interpolation-Based Animation

**Concept**: You define **start** and **end** states, the service automatically interpolates between them.

```lua
-- You say: "Move from here to there in 2 seconds"
local TweenService = game:GetService('TweenService')
local tweenInfo = TweenInfo.new(2.0, Enum.EasingStyle.Linear)
local goal = {Position = Vector3.new(10, 0, 0)}
local tween = TweenService:Create(platform, tweenInfo, goal)
tween:Play()

-- TweenService automatically:
-- - Calculates all in-between positions
-- - Handles timing and easing
-- - Interpolates smoothly
-- - Stops when done
```

**Characteristics**:
- ✅ **Declarative** - you specify "what" you want
- ✅ **Automatic** - engine handles all math
- ✅ **Time-based** - duration in seconds (deterministic)
- ✅ **Easing built-in** - 30+ easing functions
- ✅ **Control methods** - Play(), Pause(), Cancel()
- ✅ **Event-driven** - Completed event when finished
- ✅ **One-shot or limited** - moves then stops
- ✅ **Low CPU** - engine-optimized
- ✅ **Multiple properties** - animate position + rotation + scale together

### RunService.Stepped: Frame-by-Frame Manual Updates

**Concept**: A function runs **every single frame**, you manually calculate and apply changes.

```lua
-- You say: "Every frame, add 1 degree to rotation"
local RunService = game:GetService("RunService")

RunService.Stepped:Connect(function()
    -- This runs EVERY frame (approximately 60 times per second)
    local euler = platform.Euler
    platform.Euler = Vector3.new(euler.x, euler.y + 1, euler.z)

    -- You calculate and apply the change yourself
end)

-- Runs forever until you disconnect it
```

**Characteristics**:
- ⚠️ **Imperative** - you control "how" it happens
- ⚠️ **Manual** - you do all the math yourself
- ⚠️ **Frame-based** - runs every frame (~60 FPS, varies)
- ⚠️ **No built-in easing** - implement yourself if needed
- ⚠️ **Always running** - continues forever (must disconnect to stop)
- ⚠️ **Higher CPU** - your code runs every frame
- ✅ **Full control** - do anything you want
- ✅ **Infinite motion** - perfect for continuous rotation
- ✅ **Conditional logic** - adjust based on game state
- ✅ **Custom math** - implement any formula

### Performance Comparison

| Aspect | TweenService | RunService.Stepped |
|--------|-------------|-------------------|
| **CPU Usage** | ✅ Very low - engine optimized | ⚠️ Higher - runs Lua code every frame |
| **Frame Impact** | ✅ Minimal | ⚠️ Depends on your code complexity |
| **When Running** | Only during active tweens | ⚠️ Always (until disconnected) |
| **Optimization** | ✅ Engine-level C++ | ⚠️ Your Lua code - your responsibility |
| **Memory** | ✅ Low - one tween object | ⚠️ Function closure + connection |
| **Scalability** | ✅ Good - hundreds of tweens OK | ⚠️ Limited - keep < 50 active |

**Recommendation**: Prefer TweenService when possible for better performance.

### When to Use Each

#### Use **TweenService** when:

✅ **Moving from A to B** - Platform elevator, door opening, sliding platform
✅ **Time-based movement** - "Move in exactly 2 seconds"
✅ **Easing curves needed** - Smooth acceleration/deceleration
✅ **Start/end states clear** - You know where it should end up
✅ **Event-driven logic** - Do something when movement completes
✅ **Multiple properties** - Animate position + rotation + scale together
✅ **Performance matters** - TweenService is more optimized

**Examples**:
- Elevator moving up and down ⭐
- Door opening to 90 degrees ⭐
- Platform sliding back and forth ⭐
- Pendulum swinging (with easing)
- Any "move to a specific place in X seconds" scenario

#### Use **RunService.Stepped** when:

✅ **Continuous/infinite motion** - Spinning fan, rotating platform forever
✅ **No clear endpoint** - Keeps going until game event stops it
✅ **Complex custom logic** - Movement depends on game state
✅ **Frame-by-frame control** - Need to adjust based on conditions
✅ **Custom math/physics** - Sine waves, orbital motion, custom curves
✅ **Following objects** - Smooth camera follow, tracking targets

**Examples**:
- Rotating fans or gears (continuous) ⭐
- Floating platforms (sine wave bobbing) ⭐
- Following another object smoothly
- Orbital motion around a point
- Custom physics simulation
- Any "do this calculation every frame forever" scenario

### Practical Decision Tree

```
What kind of movement do you need?
│
├─ Platform moves from Point A to Point B
│  └─ Use TweenService ✅ (simple, optimized)
│
├─ Platform moves back and forth repeatedly
│  ├─ Fixed pattern (A→B→A→B...)
│  │  └─ Use TweenService (chain two tweens) ✅
│  └─ Dynamic pattern (depends on game state)
│     └─ Use RunService.Stepped
│
├─ Object rotates continuously forever
│  └─ Use RunService.Stepped ✅ (natural for infinite motion)
│
├─ Need smooth easing curves (acceleration/deceleration)
│  └─ Use TweenService ✅ (30+ easing functions built-in)
│
├─ Movement depends on game conditions
│  └─ Use RunService.Stepped (full control)
│
├─ Complex custom movement pattern (sine wave, orbit, spiral)
│  └─ Use RunService.Stepped (implement your formula)
│
└─ Need maximum performance
   └─ Use TweenService ✅ (engine-optimized)
```

### Can You Combine Them?

**Yes!** They serve different purposes:

```lua
-- TweenService for back-and-forth movement
local tweenRight = TweenService:Create(platform, tweenInfo, {Position = Vector3.new(20, 0, 0)})
local tweenLeft = TweenService:Create(platform, tweenInfo, {Position = Vector3.new(0, 0, 0)})
tweenRight.Completed:Connect(function() tweenLeft:Play() end)
tweenLeft.Completed:Connect(function() tweenRight:Play() end)
tweenRight:Play()

-- RunService.Stepped for continuous rotation (at the same time!)
RunService.Stepped:Connect(function()
    local euler = platform.Euler
    platform.Euler = Vector3.new(euler.x, euler.y + 2, euler.z)
end)

-- Result: Platform moves back and forth WHILE spinning!
```

---

## Common Movement Patterns

### Pattern 1: Horizontal Back-and-Forth (TweenService)

```lua
local TweenService = game:GetService('TweenService')
local platform = script.parent

local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In_Out)

local goalRight = {Position = Vector3.new(20, 0, 0)}
local goalLeft = {Position = Vector3.new(0, 0, 0)}

local tweenRight = TweenService:Create(platform, tweenInfo, goalRight)
local tweenLeft = TweenService:Create(platform, tweenInfo, goalLeft)

tweenRight.Completed:Connect(function() tweenLeft:Play() end)
tweenLeft.Completed:Connect(function() tweenRight:Play() end)

tweenRight:Play()
```

### Pattern 2: Circular Path (Multiple Tweens)

```lua
local TweenService = game:GetService('TweenService')
local platform = script.parent

local radius = 10
local segments = 8
local tweens = {}
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)

-- Create circular waypoints
for i = 0, segments - 1 do
    local angle = (i / segments) * 2 * math.pi
    local x = radius * math.cos(angle)
    local z = radius * math.sin(angle)

    local goal = {Position = Vector3.new(x, 0, z)}
    tweens[i + 1] = TweenService:Create(platform, tweenInfo, goal)
end

-- Chain them in a loop
for i = 1, #tweens do
    local nextIndex = (i % #tweens) + 1
    tweens[i].Completed:Connect(function()
        tweens[nextIndex]:Play()
    end)
end

tweens[1]:Play()
```

### Pattern 3: Floating Platform (Sine Wave with RunService)

```lua
local RunService = game:GetService("RunService")
local platform = script.parent

local startY = platform.Position.y
local amplitude = 1.5
local frequency = 2
local time = 0

local function Update(dt)
    time = time + dt
    local y = startY + math.sin(time * frequency) * amplitude

    local pos = platform.Position
    platform.Position = Vector3.new(pos.x, y, pos.z)
end

RunService.Heartbeat:Connect(Update)
```

### Pattern 4: Pendulum Swing (TweenService with Back easing)

```lua
local TweenService = game:GetService('TweenService')
local pendulum = script.parent

local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Back, Enum.EasingDirection.In_Out)

local swingLeft = {LocalEuler = Vector3.new(0, 0, -45)}
local swingRight = {LocalEuler = Vector3.new(0, 0, 45)}

local tweenLeft = TweenService:Create(pendulum, tweenInfo, swingLeft)
local tweenRight = TweenService:Create(pendulum, tweenInfo, swingRight)

tweenLeft.Completed:Connect(function() tweenRight:Play() end)
tweenRight.Completed:Connect(function() tweenLeft:Play() end)

tweenLeft:Play()
```

### Pattern 5: Diagonal Zigzag

```lua
local TweenService = game:GetService('TweenService')
local platform = script.parent

local positions = {
    Vector3.new(0, 0, 0),
    Vector3.new(10, 0, 5),
    Vector3.new(20, 0, 0),
    Vector3.new(30, 0, 5),
    Vector3.new(40, 0, 0)
}

local tweens = {}
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)

for i = 1, #positions do
    local nextIndex = (i % #positions) + 1
    tweens[i] = TweenService:Create(platform, tweenInfo, {Position = positions[nextIndex]})
end

for i = 1, #tweens do
    local nextIndex = (i % #tweens) + 1
    tweens[i].Completed:Connect(function()
        tweens[nextIndex]:Play()
    end)
end

tweens[1]:Play()
```

---

## Best Practices

### 1. Choose the Right Method

**For Scene Objects (Platforms, Obstacles, Decorations)**:
- ✅ Use **TweenService** (production standard) ⭐⭐⭐⭐⭐
- ✅ Use **RunService.Stepped** (for continuous rotation) ⭐⭐⭐⭐
- ✅ Use **Direct Position** (for manual control)
- ❌ **CANNOT** use Action System (no AvatarComponent)

### 2. Performance Guidelines

**TweenService**:
- ✅ Lightweight, efficient
- ✅ Handles interpolation internally
- ✅ Good for dozens of platforms
- ✅ Deterministic (multiplayer-friendly)

**RunService.Stepped**:
- ⚠️ Runs every frame
- ⚠️ Keep Update() functions fast
- ⚠️ Avoid heavy calculations
- ✅ Good for < 50 concurrent objects

### 3. Timing Recommendations

| Platform Type | Duration | Easing | Method |
|---------------|----------|--------|--------|
| Fast elevator | 1-2 sec | Linear | TweenService |
| Normal platform | 2-4 sec | Linear or Sine | TweenService |
| Slow floating | 4-6 sec | Sine | TweenService or RunService |
| Continuous rotation | N/A | N/A | RunService.Stepped |

### 4. Common Mistakes to Avoid

❌ **Using Action System on scene objects**
```lua
-- WRONG: This will crash!
local platform = SandboxNode.new("SandboxModelObject")
local move = MoveBy.new(platform, 2.0, Vector3.new(10, 0, 0))  -- ERROR!
```

✅ **Use TweenService instead**
```lua
-- CORRECT: Use TweenService for scene objects
local platform = SandboxNode.new("SandboxModelObject")
local tween = TweenService:Create(platform, tweenInfo, {Position = Vector3.new(10, 0, 0)})
tween:Play()
```

❌ **Creating tweens every frame**
```lua
-- WRONG: Performance killer!
function Update()
    local tween = TweenService:Create(platform, tweenInfo, goal)
    tween:Play()
end
```

✅ **Create once, reuse**
```lua
-- CORRECT: Create tweens at initialization
local tween = TweenService:Create(platform, tweenInfo, goal)

function StartMovement()
    tween:Play()
end
```

❌ **Forgetting to chain loop tweens**
```lua
-- WRONG: Platform only moves once
tween1:Play()
tween2:Play()
```

✅ **Chain with Completed event (Production Pattern)**
```lua
-- CORRECT: Create infinite loop with direct :Play() calls
tween1.Completed:Connect(function()
    tween2:Play()  -- Direct call, no wait() or coroutine needed
end)
tween2.Completed:Connect(function()
    tween1:Play()  -- Direct call, no wait() or coroutine needed
end)
tween1:Play()

-- TweenInfo uses 5 parameters (from sample code)
local tweenInfo = TweenInfo.new(
    2.0,                           -- Duration
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.In_Out,
    0,                             -- No repeat (we handle loop manually)
    0                              -- Reverse delay (only used when reverse=true)
)
```

❌ **Forgetting to disconnect RunService connections**
```lua
-- WRONG: Memory leak - connection never stops
RunService.Stepped:Connect(function()
    if platform.Position.y > 10 then
        -- Oops, still running even though we're done!
        return
    end
    -- ...
end)
```

✅ **Properly disconnect when done**
```lua
-- CORRECT: Disconnect when finished
local connection
connection = RunService.Stepped:Connect(function()
    if platform.Position.y > 10 then
        connection:Disconnect()  -- Stop the updates
        return
    end
    -- ...
end)
```

### 5. Debugging Tips

**Check object type**:
```lua
print(type(object))              -- "userdata"
print(object.ClassName)          -- "SandboxModelObject", "Actor", etc.
```

**Check if it's a scene object**:
```lua
if object.AvatarComponent then
    print("This is an Actor - can use Action System")
else
    print("This is a scene object - use TweenService")
end
```

**Monitor tween state**:
```lua
tween.Completed:Connect(function()
    print("Tween completed!")
end)
```

### 6. Configuration-Driven Design

**PlatformConfig.lua**:
```lua
return {
    elevator1 = {
        method = "tween",
        startPos = Vector3.new(0, 0, 0),
        endPos = Vector3.new(0, 20, 0),
        duration = 3.0,
        easing = "Linear"
    },

    spinner1 = {
        method = "runservice",
        rotationSpeed = Vector3.new(0, 2, 0),
        useLocal = true
    }
}
```

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Using Action System on Scene Objects

**Problem**: Trying to use MoveBy, MoveTo on platforms/obstacles
**Symptom**: `Runtime Error: attempt to index field 'AvatarComponent' (a nil value)`
**Solution**: Use TweenService instead - Action System only works on Actors

### ❌ Mistake 2: Not Chaining Tweens for Loops

**Problem**: Tween plays once and stops
**Symptom**: Platform moves once, then never moves again
**Solution**: Connect tweens with `Completed` event for continuous loops

### ❌ Mistake 3: Creating Tweens Every Frame

**Problem**: Creating new tween objects in Update() or Heartbeat
**Symptom**: Poor performance, memory leaks
**Solution**: Create tweens once during initialization, reuse with Play()

### ❌ Mistake 4: Using RunService for A-to-B Movement

**Problem**: Manually implementing interpolation in RunService.Stepped
**Symptom**: 20+ lines of complex code for simple movement
**Solution**: Use TweenService - it handles interpolation automatically

### ❌ Mistake 5: RunService Connection Never Disconnects

**Problem**: Not disconnecting RunService connections when done
**Symptom**: Memory leak, code runs forever even when not needed
**Solution**: Store connection and call `connection:Disconnect()` when done

---

## Validation Checklist

Before deploying moving platforms:

### TweenService Setup
- [ ] TweenService obtained via `game:GetService('TweenService')`
- [ ] TweenInfo configured with appropriate duration and easing
- [ ] Goal properties use LocalPosition (not Position) for relative movement
- [ ] Tweens chained with `Completed` event for loops
- [ ] Initial tween started with `:Play()`

### RunService Setup
- [ ] RunService obtained via `game:GetService("RunService")`
- [ ] Update function is fast and efficient
- [ ] Connection stored for later disconnect (if needed)
- [ ] Using Stepped or Heartbeat appropriately
- [ ] Rotation uses Euler or LocalEuler (not Rotation)

### Performance
- [ ] Not creating tweens every frame
- [ ] RunService connections < 50 active simultaneously
- [ ] Complex calculations cached/optimized
- [ ] Tweens destroyed when no longer needed

### Platform Physics
- [ ] Platform has collision enabled
- [ ] Platform is not Anchored (if needs to move physically)
- [ ] CollideGroupID set appropriately
- [ ] Players can stand on platform while it moves

---

## Quick Reference Card

### Minimum Working Platform Setup

**Vertical Elevator**:
```lua
local TweenService = game:GetService('TweenService')
local platform = script.parent
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)

local up = TweenService:Create(platform, tweenInfo, {LocalPosition = Vector3.new(0, 10, 0)})
local down = TweenService:Create(platform, tweenInfo, {LocalPosition = Vector3.new(0, 0, 0)})

up.Completed:Connect(function() down:Play() end)
down.Completed:Connect(function() up:Play() end)
up:Play()
```

**Continuous Rotation**:
```lua
local RunService = game:GetService("RunService")
RunService.Stepped:Connect(function()
    local e = script.parent.Euler
    script.parent.Euler = Vector3.new(e.x, e.y + 1, e.z)
end)
```

### Critical Values
- **Linear easing**: Best for mechanical platforms
- **Rotation speed**: 1-5 degrees per frame typical
- **Platform duration**: 2-4 seconds standard
- **LocalPosition**: Preferred over Position for child objects

---

## Troubleshooting

### Platform doesn't move
1. ✅ Check object is a scene object (not Actor)
2. ✅ Verify TweenService:Create() succeeded
3. ✅ Check tween:Play() was called
4. ✅ Verify goal properties are valid

### Platform moves once then stops
1. ✅ Check tweens are chained with `Completed` event
2. ✅ Verify both directions created and connected
3. ✅ Check for runtime errors breaking the chain

### Rotation doesn't work
1. ✅ Using Euler or LocalEuler (not Rotation)
2. ✅ RunService.Stepped connected successfully
3. ✅ Check rotation speed is not zero
4. ✅ Verify script.parent is correct object

### Poor performance
1. ✅ Not creating tweens every frame
2. ✅ Limit RunService connections (< 50 active)
3. ✅ Use TweenService instead of manual RunService interpolation
4. ✅ Profile Update() functions for optimization

### Platform clips through walls
1. ✅ Movement speed not too fast
2. ✅ Check collision detection enabled
3. ✅ Adjust tween duration for slower movement
4. ✅ Ensure proper CollideGroupID settings

---

## Related Documentation

- [How to Move Actors](how-to-move-actor.md) - Character movement with Action System
- [How to Add Physics Joints](how-to-add-physics-joint.md) - Joint-based object connections
- [SandboxTweenService API](../refDoc/Documents/Services/SandboxTweenService.md) - Complete TweenService reference
- [SandboxTransObject API](../refDoc/Documents/Base/SandboxTransObject.md) - Position/rotation properties

---

**Summary**: Scene objects (platforms, obstacles, decorations) use TweenService for A-to-B movement (⭐ production standard), RunService.Stepped for continuous rotation/animation, and direct position manipulation for instant changes. TweenService provides smooth, optimized interpolation with easing curves, while RunService gives frame-by-frame control for custom behaviors. Scene objects CANNOT use the Action System (which requires AvatarComponent found only in Actors). Always prefer TweenService for moving platforms and RunService.Stepped for continuous rotation as these are the production-proven methods.
