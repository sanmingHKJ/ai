# How to Add Sound Assets and Sound Nodes

## Overview

**Sound** (also known as **SandboxSound**) is the audio component in MiniWorld Studio used to play sound effects, music, and ambient audio. It supports both 2D global audio and 3D positional audio with distance-based attenuation, volume control, looping, and event callbacks. Sound nodes are essential for creating immersive game experiences with audio feedback.

### Primary Use Cases
- **UI Sound Effects**: Button clicks, menu interactions, notifications
- **Game Sound Effects**: Actions, impacts, events, gameplay feedback
- **Background Music**: Theme music, ambient soundscapes, dynamic music
- **3D Positional Audio**: Environmental sounds, character audio, location-based effects
- **Voice/Dialogue**: Character speech, narration, voiceovers

## Methods of Adding Sound Nodes

There are two primary methods to add Sound elements to your game:

### Method 1: Static Addition (JSON Configuration)
Add Sound nodes directly to the scene structure by creating JSON files. Best for:
- Pre-configured UI sounds (button clicks, releases)
- Static ambient sounds in specific locations
- Background music that's part of the scene

### Method 2: Dynamic Addition (Lua Scripting)
Create Sound nodes at runtime using Lua scripts. Best for:
- Dynamic sound effects triggered by gameplay
- 3D positional audio that follows objects
- Sound management systems with groups and mixing
- Interactive audio that responds to game state

---

## Method 1: Static Addition via JSON

### Step 1: Choose Location in Hierarchy

Sound nodes are typically placed in **StarterGui/Sounds/** for UI sounds or in **WorkSpace** for world sounds:
```
ServiceNodes/
└── StarterGui/
    └── Sounds/                          # Container for UI sounds
        ├── DefaultButtonSound.json      # Button click sound
        └── DefaultButtonRelease.json    # Button release sound

ServiceNodes/
└── WorkSpace/
    └── AmbientSounds/                   # Container for world sounds
        └── BackgroundMusic.json
```

### Step 2: Create Sound Container (Optional)

First, create a container node for organizing sounds:

**Container Template** (`ServiceNodes/StarterGui/Sounds.json`):
```json
{
  "ClassType": "SandboxNode",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Sounds",
  "reflex": [
    {"Name": "Sounds"},
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

### Step 3: Create Sound JSON File

Create a JSON file with the following structure:

**Basic Sound Template:**
```json
{
  "ClassType": "Sound",
  "attribute": [],
  "flags": 0,
  "realNodeName": "DefaultButtonSound",
  "reflex": [
    {"Name": "DefaultButtonSound"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 1},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"SoundPath": "sandboxSysId://sounds/ui/button/button_click.ogg"},
    {"Volume": 1},
    {"IsLoop": false},
    {"PlayOnRemove": false},
    {"TransObject": {
      "__reflextype": "SandboxNode_Ref",
      "_nodetype": "invalid",
      "sceneobjid": 0
    }},
    {"FixPos": [0, 0, 0]},
    {"IsFixPosPlay": false},
    {"RollOffMode": 0},
    {"RollOffMaxDistance": 6000},
    {"RollOffMinDistance": 600},
    {"SoundPosition": 0},
    {"Pitch": 1},
    {"SoundLength": 0}
  ]
}
```

### Step 4: Configure Key Properties

#### Required Properties

| Property | Value | Description |
|----------|-------|-------------|
| `ClassType` | `"Sound"` | Type identifier |
| `realNodeName` | `"<name>"` | Display name in editor |
| `SoundPath` | `"<path>"` | Audio file path/resource ID |

#### Essential Audio Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `SoundPath` | string | Audio file path or resource ID | `"sandboxSysId://sounds/ui/button/button_click.ogg"` |
| `Volume` | float | Volume level (0.0-1.0) | `1` = 100% volume |
| `IsLoop` | boolean | Loop playback | `false` for sound effects, `true` for music |
| `Pitch` | float | Playback speed/pitch | `1.0` = normal speed |

#### 3D Audio Properties (for Spatial Sound)

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `TransObject` | SandboxNode_Ref | Object to follow (3D audio) | `null` |
| `FixPos` | `[x, y, z]` | Fixed 3D position | `[0, 0, 0]` |
| `IsFixPosPlay` | boolean | Enable fixed position 3D audio | `false` |
| `RollOffMode` | number | Distance attenuation mode | `0` (Inverse) |
| `RollOffMinDistance` | float | Min distance (full volume) | `600` |
| `RollOffMaxDistance` | float | Max distance (silent) | `6000` |

#### Behavior Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `PlayOnRemove` | boolean | Auto-play when removed | `false` |
| `SoundPosition` | number | Start position (milliseconds) | `0` |

---

## Method 2: Dynamic Addition via Lua

### Step 1: Get Required Services

```lua
local WorkSpace = game:GetService("WorkSpace")
-- or for UI sounds
local StarterGui = game:GetService("StarterGui")
```

### Step 2: Create Sound Node

```lua
-- Create a sound node
local sound = SandboxNode.new('Sound', WorkSpace)
```

### Step 3: Configure Properties

#### Basic 2D Sound Setup

```lua
-- Basic Identity
sound.Name = "ButtonClick"

-- Audio File
sound.SoundPath = "sandboxSysId://sounds/ui/button_click.ogg"

-- Playback Properties
sound.Volume = 1.0          -- 100% volume
sound.Pitch = 1.0           -- Normal pitch
sound.IsLoop = false        -- Don't loop

-- Play the sound
sound:PlaySound()

-- Handle completion
sound.PlayFinish:Connect(function(node)
    print("Sound finished playing")
    node:Destroy()  -- Clean up one-shot sounds
end)
```

#### 3D Positional Sound Setup

```lua
-- Create 3D sound at fixed position
local sound3D = SandboxNode.new('Sound', WorkSpace)
sound3D.Name = "Explosion3D"
sound3D.SoundPath = "sandboxSysId://audio/explosion.mp3"
sound3D.Volume = 0.8
sound3D.IsLoop = false

-- Configure 3D audio properties
sound3D.FixPos = Vector3.new(100, 50, 200)  -- World position
sound3D.IsFixPosPlay = true                  -- Enable 3D positioning
sound3D.RollOffMode = Enum.RollOffMode.Linear
sound3D.RollOffMinDistance = 500   -- 5 meters at full volume
sound3D.RollOffMaxDistance = 5000  -- 50 meters silent

sound3D:PlaySound()

-- Clean up after playing
sound3D.PlayFinish:Connect(function(node)
    node:Destroy()
end)
```

#### Sound Following Object (3D)

```lua
-- Create sound that follows a moving object
local movingSound = SandboxNode.new('Sound', WorkSpace)
movingSound.Name = "EngineSound"
movingSound.SoundPath = "sandboxSysId://audio/engine_loop.mp3"
movingSound.Volume = 0.7
movingSound.IsLoop = true

-- Attach to object
movingSound.TransObject = myMovingVehicle  -- Sound follows this object

-- 3D audio settings
movingSound.RollOffMode = Enum.RollOffMode.Linear
movingSound.RollOffMinDistance = 1000
movingSound.RollOffMaxDistance = 5000

movingSound:PlaySound()

-- Stop and clean up when vehicle is destroyed
myMovingVehicle.Destroyed:Connect(function()
    movingSound:StopSound()
    movingSound:Destroy()
end)
```

---

## Practical Examples

### Example 1: UI Button Sounds (from simplegame)

**JSON Version** (`ServiceNodes/StarterGui/Sounds/DefaultButtonSound.json`):
```json
{
  "ClassType": "Sound",
  "realNodeName": "DefaultButtonSound",
  "reflex": [
    {"Name": "DefaultButtonSound"},
    {"SoundPath": "sandboxSysId://sounds/ui/button/button_click.ogg"},
    {"Volume": 1},
    {"IsLoop": false},
    {"RollOffMode": 0},
    {"RollOffMaxDistance": 6000},
    {"RollOffMinDistance": 600}
  ]
}
```

**Usage in UI Button**:
UI buttons can reference these sounds for click and release events.

### Example 2: Simple Sound Effect

```lua
-- Play a one-shot sound effect
local function playSound(soundPath, volume)
    local sound = SandboxNode.new('Sound', game.WorkSpace)
    sound.SoundPath = soundPath
    sound.Volume = volume or 1.0
    sound.IsLoop = false

    sound:PlaySound()

    -- Auto-cleanup
    sound.PlayFinish:Connect(function(node)
        node:Destroy()
    end)

    return sound
end

-- Usage
playSound("sandboxSysId://audio/coin_pickup.mp3", 0.8)
```

### Example 3: Background Music System

```lua
-- Simple background music manager
local MusicManager = {}
MusicManager.currentMusic = nil

function MusicManager:playMusic(musicPath, volume)
    -- Stop current music
    if self.currentMusic then
        self.currentMusic:StopSound()
        self.currentMusic:Destroy()
    end

    -- Create new music
    local music = SandboxNode.new('Sound', game.WorkSpace)
    music.Name = "BackgroundMusic"
    music.SoundPath = musicPath
    music.Volume = volume or 0.6
    music.IsLoop = true

    music:PlaySound()

    self.currentMusic = music
    return music
end

function MusicManager:stopMusic()
    if self.currentMusic then
        self.currentMusic:StopSound()
        self.currentMusic:Destroy()
        self.currentMusic = nil
    end
end

function MusicManager:setVolume(volume)
    if self.currentMusic then
        self.currentMusic.Volume = volume
    end
end

-- Usage
MusicManager:playMusic("sandboxSysId://audio/menu_theme.mp3", 0.5)
```

### Example 4: 3D Ambient Sound Zone

```lua
-- Create an ambient sound zone (e.g., waterfall)
local function createAmbientZone(position, soundPath, minDist, maxDist)
    local sound = SandboxNode.new('Sound', game.WorkSpace)
    sound.Name = "AmbientZone"
    sound.SoundPath = soundPath
    sound.Volume = 0.7
    sound.IsLoop = true

    -- 3D positioning
    sound.FixPos = position
    sound.IsFixPosPlay = true
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMinDistance = minDist
    sound.RollOffMaxDistance = maxDist

    sound:PlaySound()

    return sound
end

-- Create a waterfall ambient sound
local waterfallSound = createAmbientZone(
    Vector3.new(500, 100, 300),           -- Position
    "sandboxSysId://audio/waterfall.mp3",  -- Sound
    2000,                                  -- 20m min distance
    10000                                  -- 100m max distance
)
```

### Example 5: Sound Pool for Frequent Effects

```lua
-- Sound pool for performance optimization
local SoundPool = {}
SoundPool.pools = {}

function SoundPool:createPool(soundName, soundPath, poolSize)
    local pool = {
        sounds = {},
        path = soundPath,
        available = {}
    }

    -- Pre-create sound nodes
    for i = 1, poolSize do
        local sound = SandboxNode.new('Sound', game.WorkSpace)
        sound.SoundPath = soundPath
        sound.IsLoop = false
        sound.Volume = 1.0

        sound.PlayFinish:Connect(function(node)
            -- Return to pool
            table.insert(pool.available, node)
        end)

        table.insert(pool.sounds, sound)
        table.insert(pool.available, sound)
    end

    self.pools[soundName] = pool
end

function SoundPool:play(soundName, volume, position)
    local pool = self.pools[soundName]
    if not pool or #pool.available == 0 then
        return nil
    end

    local sound = table.remove(pool.available)
    sound.Volume = volume or 1.0

    if position then
        sound.FixPos = position
        sound.IsFixPosPlay = true
    end

    sound:PlaySound()
    return sound
end

-- Setup
SoundPool:createPool("footstep", "sandboxSysId://audio/footstep.mp3", 5)

-- Usage
SoundPool:play("footstep", 0.8, Vector3.new(0, 50, 0))
```

### Example 6: Audio Service Framework

```lua
-- Comprehensive audio management system
local AudioService = {}
AudioService.soundGroups = {}
AudioService.masterVolume = 1.0

function AudioService:init()
    -- Create sound group container
    self.soundGroup = SandboxNode.new('SoundGroup')
    self.soundGroup.Name = 'GameSoundGroup'
    self.soundGroup.Parent = game.WorkSpace

    -- Volume settings
    self.musicVolume = 1.0
    self.effectVolume = 1.0

    -- Track current music
    self.currentMusic = nil
end

function AudioService:playSound(soundPath, options)
    options = options or {}

    local sound = SandboxNode.new('Sound', self.soundGroup)
    sound.SoundPath = soundPath
    sound.Volume = (options.volume or 1.0) * self.effectVolume * self.masterVolume
    sound.IsLoop = options.loop or false

    -- 3D audio setup
    if options.position then
        sound.FixPos = options.position
        sound.IsFixPosPlay = true
        sound.RollOffMode = Enum.RollOffMode.Linear
        sound.RollOffMinDistance = options.minDistance or 1000
        sound.RollOffMaxDistance = options.maxDistance or 5000
    end

    sound:PlaySound()

    -- Auto-cleanup for one-shot sounds
    if not options.loop then
        sound.PlayFinish:Connect(function(node)
            node:Destroy()
        end)
    end

    return sound
end

function AudioService:playMusic(musicPath, volume)
    -- Stop current music
    if self.currentMusic then
        self.currentMusic:StopSound()
        self.currentMusic:Destroy()
    end

    -- Create new music
    local music = SandboxNode.new('Sound', self.soundGroup)
    music.SoundPath = musicPath
    music.Volume = (volume or 0.6) * self.musicVolume * self.masterVolume
    music.IsLoop = true

    music:PlaySound()

    self.currentMusic = music
    return music
end

function AudioService:setMasterVolume(volume)
    self.masterVolume = math.clamp(volume, 0, 1)
    self.soundGroup:ChangeVolume(self.masterVolume)
end

function AudioService:setMusicVolume(volume)
    self.musicVolume = math.clamp(volume, 0, 1)
    if self.currentMusic then
        self.currentMusic.Volume = self.musicVolume * self.masterVolume
    end
end

function AudioService:setEffectVolume(volume)
    self.effectVolume = math.clamp(volume, 0, 1)
end

-- Initialize
AudioService:init()

-- Usage
AudioService:playSound("sandboxSysId://audio/explosion.mp3", {
    volume = 0.8,
    position = Vector3.new(100, 50, 200),
    minDistance = 500,
    maxDistance = 5000
})

AudioService:playMusic("sandboxSysId://audio/battle_theme.mp3", 0.5)
```

---

## Sound Node Properties Reference

### Audio File Properties

| Property | Type | Units | Description |
|----------|------|-------|-------------|
| `SoundPath` | string | - | Audio file path/resource ID (required) |
| `Volume` | float | 0.0-1.0 | Volume level (1.0 = 100%) |
| `Pitch` | float | multiplier | Playback speed/pitch (1.0 = normal) |
| `IsLoop` | boolean | - | Loop playback continuously |

### 3D Audio Properties

| Property | Type | Units | Description |
|----------|------|-------|-------------|
| `TransObject` | SandboxNode | - | Object to follow (dynamic 3D audio) |
| `FixPos` | Vector3 | cm | Fixed world position for 3D audio |
| `IsFixPosPlay` | boolean | - | Enable fixed position 3D audio |
| `RollOffMode` | enum | - | Distance attenuation mode (0=Inverse, 1=Linear, 2=LinearSquare, 3=InverseTapered) |
| `RollOffMinDistance` | float | cm | Distance at full volume |
| `RollOffMaxDistance` | float | cm | Distance at silent/minimum volume |

### Playback Control Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `PlayOnRemove` | boolean | Auto-play when node removed | `false` |
| `SoundPosition` | number | Current playback position (ms) | `0` |
| `SoundLength` | number | Total audio length (ms, read-only) | `0` |

---

## Sound Node Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `PlaySound()` | - | void | Play/replay the sound |
| `StopSound()` | - | void | Stop playback |
| `PauseSound()` | - | void | Pause playback |
| `ResumeSound()` | - | void | Resume from pause |
| `SoundSyncMode(mode)` | SYNCMODE | void | Set synchronization mode |

---

## Sound Node Events

| Event | Parameters | Description |
|-------|------------|-------------|
| `PlayFinish` | SandboxNode | Fired when sound finishes playing |

**Usage:**
```lua
sound.PlayFinish:Connect(function(node)
    print("Sound finished: " .. node.Name)
    node:Destroy()
end)
```

---

## RollOffMode Reference

Distance attenuation modes for 3D audio:

| Mode | Value | Description | Use Case |
|------|-------|-------------|----------|
| **Inverse** | 0 | Inverse distance falloff (realistic) | Natural sound propagation |
| **Linear** | 1 | Linear distance falloff | Simple, predictable attenuation |
| **LinearSquare** | 2 | Squared linear falloff (fast dropoff) | Sounds that should fade quickly |
| **InverseTapered** | 3 | Inverse with plateau near source | Controlled near-field volume |

**Visualization:**
- **Inverse**: Realistic, like real-world sound
- **Linear**: Smooth, even falloff
- **LinearSquare**: Rapid falloff, stays local
- **InverseTapered**: Full volume zone, then falloff

---

## Sound Path Formats

### Resource ID Format
```lua
sound.SoundPath = "sandboxSysId://sounds/ui/button_click.ogg"
sound.SoundPath = "sandboxId://audio/explosion.mp3"
```

### Supported Audio Formats
- **MP3**: Common, good compression
- **OGG**: Open format, good quality
- **WAV**: Uncompressed, best quality (larger files)

---

## Best Practices

### Performance Optimization

1. **Use Sound Pools for Frequent Effects**
   - Pre-create sound nodes for common effects
   - Reuse nodes instead of creating/destroying

2. **Clean Up One-Shot Sounds**
   ```lua
   sound.PlayFinish:Connect(function(node)
       node:Destroy()
   end)
   ```

3. **Limit Concurrent Sounds**
   - Track playing sounds
   - Stop lowest priority when limit reached
   - Typical limit: 10-20 sound effects

4. **Optimize 3D Audio Range**
   - Set appropriate `RollOffMaxDistance`
   - Distant sounds don't need computation

### Volume Management

1. **Layer Volume Controls**
   ```lua
   finalVolume = soundVolume * groupVolume * masterVolume
   ```

2. **Use Sound Groups**
   - Separate music, SFX, voice, UI
   - Independent volume controls per group

3. **Reasonable Volume Ranges**
   - Music: 0.4 - 0.7
   - SFX: 0.6 - 1.0
   - UI sounds: 0.5 - 0.8
   - Ambient: 0.3 - 0.6

### 3D Audio Configuration

1. **Choose Appropriate Distances**
   ```lua
   -- UI sounds (no 3D)
   -- Leave IsFixPosPlay = false

   -- Close sounds (footsteps, pickups)
   RollOffMinDistance = 500   -- 5m
   RollOffMaxDistance = 2000  -- 20m

   -- Medium sounds (explosions, impacts)
   RollOffMinDistance = 1000  -- 10m
   RollOffMaxDistance = 5000  -- 50m

   -- Far sounds (ambient, environment)
   RollOffMinDistance = 2000  -- 20m
   RollOffMaxDistance = 10000 -- 100m
   ```

2. **Use Linear Mode for Most Cases**
   ```lua
   sound.RollOffMode = Enum.RollOffMode.Linear
   ```

3. **Attach to Moving Objects**
   ```lua
   sound.TransObject = movingObject  -- Sound follows object
   ```

### Organization

1. **Naming Convention**
   ```lua
   "Sound_<category>_<name>"  -- e.g., "Sound_UI_ButtonClick"
   "Music_<theme>"            -- e.g., "Music_BattleTheme"
   "Ambient_<location>"       -- e.g., "Ambient_Waterfall"
   ```

2. **Folder Structure**
   ```
   ServiceNodes/
   └── StarterGui/
       └── Sounds/
           ├── DefaultButtonSound.json
           ├── DefaultButtonRelease.json
           └── NotificationSound.json

   ServiceNodes/
   └── WorkSpace/
       └── Audio/
           ├── Music/
           │   └── BackgroundMusic.json
           └── Ambient/
               └── WaterfallSound.json
   ```

3. **Use Audio Configuration Tables**
   ```lua
   local AudioConfig = {
       ["button_click"] = {
           path = "sandboxSysId://sounds/ui/button_click.ogg",
           volume = 0.8
       },
       ["explosion"] = {
           path = "sandboxSysId://audio/explosion.mp3",
           volume = 1.0,
           minDistance = 1000,
           maxDistance = 5000
       }
   }
   ```

---

## Common Patterns

### Pattern 1: UI Sound Effect
```lua
-- Simple UI click sound
local sound = SandboxNode.new('Sound', game.StarterGui.Sounds)
sound.SoundPath = "sandboxSysId://sounds/ui/button_click.ogg"
sound.Volume = 0.8
sound.IsLoop = false
sound:PlaySound()
sound.PlayFinish:Connect(function(n) n:Destroy() end)
```

### Pattern 2: Background Music
```lua
-- Looping background music
local music = SandboxNode.new('Sound', game.WorkSpace)
music.Name = "BackgroundMusic"
music.SoundPath = "sandboxSysId://audio/theme.mp3"
music.Volume = 0.6
music.IsLoop = true
music:PlaySound()
```

### Pattern 3: 3D Positional Effect
```lua
-- 3D sound at fixed position
local sound = SandboxNode.new('Sound', game.WorkSpace)
sound.SoundPath = "sandboxSysId://audio/explosion.mp3"
sound.FixPos = Vector3.new(100, 50, 200)
sound.IsFixPosPlay = true
sound.RollOffMode = Enum.RollOffMode.Linear
sound.RollOffMinDistance = 1000
sound.RollOffMaxDistance = 5000
sound.Volume = 1.0
sound:PlaySound()
sound.PlayFinish:Connect(function(n) n:Destroy() end)
```

### Pattern 4: Sound Following Object
```lua
-- Sound that follows a moving object
local sound = SandboxNode.new('Sound', game.WorkSpace)
sound.Name = "EngineSound"
sound.SoundPath = "sandboxSysId://audio/engine.mp3"
sound.TransObject = vehicle  -- Follows this object
sound.RollOffMode = Enum.RollOffMode.Linear
sound.RollOffMinDistance = 1000
sound.RollOffMaxDistance = 5000
sound.Volume = 0.7
sound.IsLoop = true
sound:PlaySound()
```

---

## Common Mistakes & Solutions

### Mistake 1: Forgetting to Clean Up One-Shot Sounds
**Problem**: Memory leak from accumulated sound nodes
**Solution**: Always destroy non-looping sounds after playback
```lua
sound.PlayFinish:Connect(function(node)
    node:Destroy()
end)
```

### Mistake 2: 3D Audio Not Working
**Problem**: Sound plays as 2D (global) instead of 3D
**Solution**: Must set either `TransObject` OR (`FixPos` + `IsFixPosPlay = true`)
```lua
-- Correct 3D setup
sound.FixPos = Vector3.new(100, 50, 200)
sound.IsFixPosPlay = true  -- Required!
```

### Mistake 3: Volume Too Low or Too High
**Problem**: Sounds are inaudible or distorted
**Solution**: Layer volume controls, use 0.0-1.0 range
```lua
local finalVolume = soundVolume * groupVolume * masterVolume
sound.Volume = math.clamp(finalVolume, 0, 1)
```

### Mistake 4: Wrong Distance Units
**Problem**: 3D audio range too short or too long
**Solution**: Remember units are in centimeters (100cm = 1m)
```lua
sound.RollOffMinDistance = 1000  -- 10 meters
sound.RollOffMaxDistance = 5000  -- 50 meters
```

### Mistake 5: Too Many Concurrent Sounds
**Problem**: Audio clutter, performance issues
**Solution**: Limit concurrent sounds, use priority system
```lua
-- Implement max concurrent sound limit
if #playingSounds >= MAX_SOUNDS then
    stopLowestPriority()
end
```

### Mistake 6: Not Handling Sound Completion
**Problem**: Looping sounds never stop, or scripts wait indefinitely
**Solution**: Use `PlayFinish` event for one-shots, manually stop loops
```lua
-- For loops, stop explicitly
music:StopSound()
music:Destroy()
```

---

## Validation Checklist

Before finalizing your sound implementation:

- [ ] `ClassType = "Sound"` is set correctly
- [ ] `SoundPath` points to valid audio resource
- [ ] Placed in appropriate hierarchy location
- [ ] `Volume` is in valid range (0.0-1.0)
- [ ] `IsLoop` is set correctly (false for SFX, true for music)
- [ ] **3D Audio**: `IsFixPosPlay` or `TransObject` configured if using 3D
- [ ] **3D Audio**: `RollOffMinDistance` and `RollOffMaxDistance` set appropriately
- [ ] **3D Audio**: `RollOffMode` chosen appropriately
- [ ] One-shot sounds have cleanup logic (`PlayFinish` → `Destroy`)
- [ ] Looping sounds have stop mechanism
- [ ] Sound naming follows project conventions

---

## Related Documentation

- [How to Create UI Elements](how-to-create-ui-elements.md)
- [How to Add GeoSolid Elements](how-to-add-geosolid.md)
- [How to Create ModuleScript](how-to-create-modulescript.md)
- [How to Build a Feature](../how-to-build-a-feature.md)

---

## Quick Reference Card

### Simple 2D Sound Effect
```lua
local sound = SandboxNode.new('Sound', game.WorkSpace)
sound.SoundPath = "sandboxSysId://audio/click.mp3"
sound.Volume = 0.8
sound.IsLoop = false
sound:PlaySound()
sound.PlayFinish:Connect(function(n) n:Destroy() end)
```

### Background Music
```lua
local music = SandboxNode.new('Sound', game.WorkSpace)
music.SoundPath = "sandboxSysId://audio/theme.mp3"
music.Volume = 0.6
music.IsLoop = true
music:PlaySound()
```

### 3D Positional Sound
```lua
local sound3D = SandboxNode.new('Sound', game.WorkSpace)
sound3D.SoundPath = "sandboxSysId://audio/explosion.mp3"
sound3D.FixPos = Vector3.new(100, 50, 200)
sound3D.IsFixPosPlay = true
sound3D.RollOffMode = Enum.RollOffMode.Linear
sound3D.RollOffMinDistance = 1000  -- 10m
sound3D.RollOffMaxDistance = 5000  -- 50m
sound3D.Volume = 1.0
sound3D:PlaySound()
sound3D.PlayFinish:Connect(function(n) n:Destroy() end)
```

### Sound Following Object
```lua
local sound = SandboxNode.new('Sound', game.WorkSpace)
sound.SoundPath = "sandboxSysId://audio/engine.mp3"
sound.TransObject = movingObject
sound.RollOffMode = Enum.RollOffMode.Linear
sound.RollOffMinDistance = 1000
sound.RollOffMaxDistance = 5000
sound.Volume = 0.7
sound.IsLoop = true
sound:PlaySound()
```

### Critical Settings
- **2D Audio**: Don't set `TransObject` or `IsFixPosPlay`
- **3D Audio**: Set `IsFixPosPlay=true` + `FixPos`, OR set `TransObject`
- **Cleanup**: Use `PlayFinish:Connect(function(n) n:Destroy() end)` for one-shots
- **Distance Units**: Centimeters (1000 = 10 meters)
- **Volume Range**: 0.0 to 1.0 (never exceed)
