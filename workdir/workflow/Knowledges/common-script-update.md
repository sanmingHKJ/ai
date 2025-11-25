# Common Script Update Mechanisms in MiniWorld Studio

📚 **Prerequisites**: Read [How to Create Scripts](how-to-create-script.md) first for script types and basic structure.

## Overview

This guide covers all update mechanisms in MiniWorld Studio for creating periodic updates, frame-based logic, and scheduled tasks. Understanding these patterns is essential for implementing game loops, animations, timers, and real-time gameplay.

**Common Use Cases**: Game loops, animations, timers, periodic checks, real-time gameplay, visual effects, movement systems, score updates

---

## Critical Difference from Roblox

⚠️ **IMPORTANT**: MiniWorld Studio does NOT have `RunService.Heartbeat`!

| ❌ Roblox (Don't Use) | ✅ MiniWorld Studio (Use) |
|---------------------|------------------------|
| `RunService.Heartbeat:Connect()` | **Does not exist** |
| `RunService.RenderStepped:Connect()` | ✅ Available (less common) |
| `RunService.Stepped:Connect()` | ✅ **Primary choice** (most common) |

---

## Update Mechanism Options

MiniWorld Studio provides three main approaches for updates:

### 1. Frame-Based Updates (RunService.Stepped)
### 2. Scheduled Updates (UpdateManager Pattern)
### 3. Timer-Based Updates (Delayed/Periodic Tasks)

---

## 1. Frame-Based Updates with RunService.Stepped

### Overview

`RunService.Stepped:Connect()` is the **primary update mechanism** in MiniWorld Studio, equivalent to Roblox's `Heartbeat`. It fires every frame and is ideal for continuous updates.

### Basic Usage

```lua
local RunService = game:GetService("RunService")

-- Connect to frame updates
RunService.Stepped:Connect(function()
    -- This runs every frame
    print("Frame update")
end)
```

### Time-Based Updates

For time-based logic, use `RunService:CurrentMilliSecondTimeStamp()` for precise timing:

```lua
local RunService = game:GetService("RunService")
local lastUpdate = RunService:CurrentMilliSecondTimeStamp()
local updateInterval = 1000  -- 1 second in milliseconds

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    local deltaTime = currentTime - lastUpdate

    if deltaTime >= updateInterval then
        lastUpdate = currentTime
        -- Your periodic logic here
        print("1 second has passed")
    end
end)
```

### Example: Rotating Object

```lua
local RunService = game:GetService("RunService")
local WorkSpace = game:GetService("WorkSpace")
local rotatingPart = WorkSpace:FindFirstChild("RotatingPart", true)

if rotatingPart then
    local rotationSpeed = 1  -- Degrees per frame

    RunService.Stepped:Connect(function()
        local currentRotation = rotatingPart.LocalRotation
        -- Rotate around Y axis
        rotatingPart.LocalRotation = Vector3.new(
            currentRotation.x,
            currentRotation.y + rotationSpeed,
            currentRotation.z
        )
    end)
end
```

### Example: Score Update Timer

```lua
local RunService = game:GetService("RunService")
local updateInterval = 10000  -- 10 seconds in milliseconds
local lastUpdate = RunService:CurrentMilliSecondTimeStamp()

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    local deltaTime = currentTime - lastUpdate

    if deltaTime >= updateInterval then
        lastUpdate = currentTime
        -- Update scores or perform periodic task
        updateLeaderboard()
    end
end)
```

### When to Use RunService.Stepped

✅ **Use for:**
- Continuous animations
- Real-time movement
- Physics-based logic
- Visual effects that need smooth updates
- Camera controls
- Input polling

❌ **Avoid for:**
- Infrequent updates (use timers instead)
- Heavy computations every frame (performance impact)
- Server-side logic that doesn't need frame-rate precision

---

## 2. UpdateManager Pattern (Advanced)

### Overview

The UpdateManager pattern is used in professional MiniWorld Studio projects for centralized, priority-based update management. It's more efficient than multiple individual `Stepped` connections.

### Key Benefits

- **Single connection**: One `RunService.Stepped` connection for all systems
- **Priority-based**: Critical systems update first
- **Frame rate control**: Built-in FPS limiting
- **Performance monitoring**: Track execution time per system
- **Error handling**: Automatically disable failing systems

### UpdateManager Architecture

Based on `PromptTpl/samplecode/xplants/ServiceNodes/MainStorage/UpdateManager.lua`:

```lua
local UpdateManager = {}
UpdateManager.registeredSystems = {}
UpdateManager.isRunning = false

-- Priority levels
UpdateManager.PRIORITY = {
    CRITICAL = 1,    -- Network, core logic (every frame)
    HIGH = 2,        -- Weather, activities (every frame)
    NORMAL = 5,      -- Crops, pets, shops (30 FPS)
    LOW = 8,         -- Sound effects, timers (10 FPS)
    BACKGROUND = 10  -- Data saving, logs (5 FPS)
}

-- Register a system for updates
function UpdateManager:RegisterSystem(systemName, updateFunction, priority, context)
    local systemData = {
        name = systemName,
        updateFunction = updateFunction,
        priority = priority or self.PRIORITY.NORMAL,
        context = context,
        enabled = true,
        errorCount = 0
    }
    table.insert(self.registeredSystems, systemData)
end

-- Start the update loop
function UpdateManager:StartUpdateLoop()
    if self.isRunning then return end
    self.isRunning = true

    local RunService = game:GetService("RunService")
    RunService.Stepped:Connect(function()
        self:_InternalUpdate()
    end)
end

-- Internal update dispatcher
function UpdateManager:_InternalUpdate()
    local RunService = game:GetService("RunService")
    local currentTime = RunService:CurrentMilliSecondTimeStamp()

    for _, system in ipairs(self.registeredSystems) do
        if system.enabled then
            local success, error = pcall(function()
                if system.context then
                    system.updateFunction(system.context, deltaTime)
                else
                    system.updateFunction(deltaTime)
                end
            end)

            if not success then
                system.errorCount = system.errorCount + 1
                warn("System update failed:", system.name, error)

                -- Disable after too many errors
                if system.errorCount >= 10 then
                    system.enabled = false
                end
            end
        end
    end
end

return UpdateManager
```

### Using UpdateManager

```lua
-- In your game initialization script
local MainStorage = game:GetService("MainStorage")
local UpdateManager = require(MainStorage.UpdateManager)

-- Register systems
UpdateManager:RegisterSystem("PlayerMovement", function(deltaTime)
    -- Update player movement
end, UpdateManager.PRIORITY.CRITICAL)

UpdateManager:RegisterSystem("WeatherEffects", function(deltaTime)
    -- Update weather
end, UpdateManager.PRIORITY.HIGH)

UpdateManager:RegisterSystem("ScoreUpdate", function(deltaTime)
    -- Update scores periodically
end, UpdateManager.PRIORITY.LOW)

-- Start the update loop
UpdateManager:StartUpdateLoop()
```

### When to Use UpdateManager

✅ **Use for:**
- Large projects with many systems
- Performance-critical applications
- Games with complex update hierarchies
- Projects requiring centralized update control

❌ **Avoid for:**
- Simple projects with few updates
- Quick prototypes
- Single-system scripts

---

## 3. Timer-Based Updates

### Simple Timer with Delay Tracking

```lua
local RunService = game:GetService("RunService")
local timerInterval = 5000  -- 5 seconds
local lastTrigger = RunService:CurrentMilliSecondTimeStamp()

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()

    if currentTime - lastTrigger >= timerInterval then
        lastTrigger = currentTime
        -- Timer fired
        print("Timer: 5 seconds elapsed")
        doSomething()
    end
end)
```

### UpdateManager Timer Registration

If using UpdateManager pattern:

```lua
-- Register a timer that fires every 5 seconds
UpdateManager:RegisterTimerSystem("ScoreSync", function()
    -- Sync scores with server
    syncScores()
end, 5)  -- 5 seconds interval
```

### Delayed One-Time Task

```lua
-- Execute after 3 seconds (one-time)
UpdateManager:RegisterDelayedTask("ShowWelcome", function()
    print("Welcome to the game!")
    showWelcomeMessage()
end, 3)
```

---

## Best Practices

### 1. Choose the Right Mechanism

| Update Type | Recommended Approach |
|------------|---------------------|
| Smooth animations | `RunService.Stepped` direct |
| Every-frame logic | `RunService.Stepped` direct |
| Periodic updates (< 1/sec) | Timer pattern or UpdateManager |
| Complex multi-system | UpdateManager pattern |
| One-time delays | Delayed task pattern |

### 2. Use Millisecond Timestamps

✅ **Always use `RunService:CurrentMilliSecondTimeStamp()` for timing:**

```lua
local RunService = game:GetService("RunService")
local lastTime = RunService:CurrentMilliSecondTimeStamp()

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    local deltaTime = currentTime - lastTime
    lastTime = currentTime

    -- Use deltaTime for time-based calculations
end)
```

❌ **Don't use `os.time()` for frame-based logic** (too imprecise)

### 3. Avoid Expensive Operations Every Frame

```lua
-- ❌ BAD: Heavy computation every frame
RunService.Stepped:Connect(function()
    local allPlayers = Players:GetPlayers()
    for _, player in ipairs(allPlayers) do
        calculateComplexAI(player)  -- Too expensive!
    end
end)

-- ✅ GOOD: Heavy computation with interval
local updateInterval = 1000  -- 1 second
local lastUpdate = RunService:CurrentMilliSecondTimeStamp()

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()

    if currentTime - lastUpdate >= updateInterval then
        lastUpdate = currentTime
        local allPlayers = Players:GetPlayers()
        for _, player in ipairs(allPlayers) do
            calculateComplexAI(player)  -- Only once per second
        end
    end
end)
```

### 4. Clean Up Connections

Always store connections and disconnect when no longer needed:

```lua
local connection = nil

function startUpdates()
    local RunService = game:GetService("RunService")
    connection = RunService.Stepped:Connect(function()
        -- Update logic
    end)
end

function stopUpdates()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end
```

### 5. Use Error Handling for Critical Updates

```lua
RunService.Stepped:Connect(function()
    local success, error = pcall(function()
        criticalUpdateLogic()
    end)

    if not success then
        warn("Update failed:", error)
        -- Handle error or disable system
    end
end)
```

---

## Real-World Examples from Sample Code

### Example 1: Weather Visual Effects

From `xplants/ServiceNodes/StartPlayer/StarterPlayerScripts/WeatherVisualEffects.lua`:

```lua
local RunService = game:GetService("RunService")

-- Frost grid particle update system
self.frostGridSystem.updateConnection = RunService.Stepped:Connect(function()
    for pos, particleData in pairs(self.frostGridSystem.activeParticles) do
        if particleData.particle and particleData.particle.Parent then
            -- Update particle lifetime
            particleData.lifetime = particleData.lifetime - 0.016

            if particleData.lifetime <= 0 then
                -- Remove expired particles
                particleData.particle:Destroy()
                self.frostGridSystem.activeParticles[pos] = nil
            end
        end
    end
end)
```

### Example 2: Rotation Animation

From `town/WorkSpace/CentralSquare/Static/W_star/RotateXYZ.lua`:

```lua
local RunService = game:GetService("RunService")
local object = script.Parent

RunService.Stepped:Connect(function()
    local currentRotation = object.LocalRotation
    object.LocalRotation = Vector3.new(
        currentRotation.x,
        currentRotation.y + 1,  -- Rotate 1 degree per frame
        currentRotation.z
    )
end)
```

### Example 3: UpdateManager with Priority

From `xplants/ServiceNodes/MainStorage/UpdateManager.lua`:

```lua
-- Critical system (every frame)
UpdateManager:RegisterCriticalSystem("NetworkSync", function(deltaTime)
    syncNetworkState()
end)

-- Normal priority system (30 FPS effective)
UpdateManager:RegisterNormalSystem("CropGrowth", function(deltaTime)
    updateCropGrowth(deltaTime)
end)

-- Background system (5 FPS effective)
UpdateManager:RegisterBackgroundSystem("DataSave", function(deltaTime)
    autoSavePlayerData()
end)
```

---

## Performance Considerations

### Frame Rate Control

If you need to limit update frequency for performance:

```lua
local RunService = game:GetService("RunService")
local TARGET_FPS = 30
local FRAME_TIME = 1000 / TARGET_FPS  -- ~33.33ms
local lastFrameTime = 0

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()

    -- Only execute if enough time has passed
    if currentTime - lastFrameTime >= FRAME_TIME then
        lastFrameTime = currentTime

        -- Your update logic here (runs at ~30 FPS max)
        updateGameLogic()
    end
end)
```

### Batching Updates

For better performance, batch similar operations:

```lua
-- ❌ BAD: Multiple separate updates
RunService.Stepped:Connect(function()
    updatePlayer1()
end)
RunService.Stepped:Connect(function()
    updatePlayer2()
end)
RunService.Stepped:Connect(function()
    updatePlayer3()
end)

-- ✅ GOOD: Single update with batching
RunService.Stepped:Connect(function()
    updatePlayer1()
    updatePlayer2()
    updatePlayer3()
end)

-- ✅ BETTER: Even more efficient
local players = {player1, player2, player3}
RunService.Stepped:Connect(function()
    for _, player in ipairs(players) do
        updatePlayer(player)
    end
end)
```

---

## Common Mistakes and Solutions

### ❌ Mistake 1: Using Heartbeat (Roblox API)

**Problem**:
```lua
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    -- This will fail!
end)
```

**Error**: `attempt to index field 'Heartbeat' (a nil value)`

**Solution**:
```lua
local RunService = game:GetService("RunService")
RunService.Stepped:Connect(function()
    -- Works in MiniWorld Studio
end)
```

### ❌ Mistake 2: Not Tracking Time Properly

**Problem**:
```lua
local frameCount = 0
RunService.Stepped:Connect(function()
    frameCount = frameCount + 1
    if frameCount >= 60 then  -- Assumes 60 FPS - wrong!
        frameCount = 0
        doSomething()
    end
end)
```

**Solution**:
```lua
local RunService = game:GetService("RunService")
local lastTime = RunService:CurrentMilliSecondTimeStamp()
local interval = 1000  -- 1 second in milliseconds

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    if currentTime - lastTime >= interval then
        lastTime = currentTime
        doSomething()
    end
end)
```

### ❌ Mistake 3: Memory Leaks from Uncleared Connections

**Problem**:
```lua
function createTimer()
    RunService.Stepped:Connect(function()
        -- Connection never cleaned up!
    end)
end

-- Called multiple times = multiple connections = memory leak
createTimer()
createTimer()
createTimer()
```

**Solution**:
```lua
local timerConnection = nil

function createTimer()
    -- Clean up old connection first
    if timerConnection then
        timerConnection:Disconnect()
    end

    timerConnection = RunService.Stepped:Connect(function()
        -- New connection
    end)
end

function destroyTimer()
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
end
```

### ❌ Mistake 4: Infinite Loops Blocking Script

**Problem**:
```lua
-- This blocks the entire script!
while true do
    wait(1)
    updateSomething()
end

print("This never executes!")
```

**Solution**:
```lua
-- Use event-driven approach
local RunService = game:GetService("RunService")
local lastUpdate = RunService:CurrentMilliSecondTimeStamp()
local interval = 1000

RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    if currentTime - lastUpdate >= interval then
        lastUpdate = currentTime
        updateSomething()
    end
end)

print("This executes immediately!")
```

---

## Quick Reference: Update Mechanisms

### RunService.Stepped Pattern

```lua
local RunService = game:GetService("RunService")

-- Every frame
RunService.Stepped:Connect(function()
    -- Runs every frame
end)

-- With time tracking
local lastTime = RunService:CurrentMilliSecondTimeStamp()
RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    local deltaTime = currentTime - lastTime
    lastTime = currentTime
    -- Use deltaTime
end)

-- With interval
local interval = 1000
local lastUpdate = RunService:CurrentMilliSecondTimeStamp()
RunService.Stepped:Connect(function()
    local currentTime = RunService:CurrentMilliSecondTimeStamp()
    if currentTime - lastUpdate >= interval then
        lastUpdate = currentTime
        -- Periodic logic
    end
end)
```

### Comparison Table

| Pattern | Frequency | Use Case | Complexity |
|---------|-----------|----------|------------|
| `RunService.Stepped` direct | Every frame | Animations, movement | Low |
| Timer pattern | Custom interval | Periodic tasks | Low |
| UpdateManager | Priority-based | Large projects | High |
| Delayed task | One-time | Delayed actions | Medium |

---

## Related Documentation

- [How to Create Scripts](how-to-create-script.md) - Script types and structure
- [How to Use Remote Events](../how-to-use-remote-events.md) - Client-server communication
- [MiniWorld Studio vs Roblox Architecture Guide](../PromptTpl/AI_Templates/TemplateGame/common/MiniWorld_Studio_vs_Roblox_Architecture_Guide.md)

---

**Created**: 2025-10-23
**Version**: 1.0.0
**Based on**: Sample code analysis (xplants, town, sgfgamedemo2) and MiniWorld Studio API reference
