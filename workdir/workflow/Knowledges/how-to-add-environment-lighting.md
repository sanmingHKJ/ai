# How to Add Environment & Lighting to Scene

## Overview

**Environment & Lighting** is the system that creates atmosphere, visual quality, and mood in MiniWorld Studio. It consists of three core components: the Environment container (weather, time, gravity), directional lighting (SunLight), and ambient lighting (SkyLight/Atmosphere). Together, these elements define how your game world looks and feels.

### Primary Use Cases
- **Day-Night Cycles**: Create dynamic time-of-day lighting
- **Weather Systems**: Add rain, fog, and atmospheric effects
- **Mood Setting**: Establish emotional tone through lighting
- **Visual Quality**: Enhance realism with shadows and ambient light
- **Gameplay Mechanics**: Use lighting for game rules (e.g., stealth, plant growth)

## Components Overview

There are three primary components for environment and lighting:

### Component 1: Environment Container
Controls weather, time, and global settings. Located at `ServiceNodes/WorkSpace/Environment.json`
- ClassType: "Environment"
- Manages weather type, time of day, gravity settings

### Component 2: SunLight (Directional Light)
Main directional light source (sun). Located at `ServiceNodes/WorkSpace/Environment/SunLight.json`
- ClassType: "SunLight"
- Provides primary illumination and shadows

### Component 3: SkyLight (Ambient Light)
Ambient environmental lighting. Located at `ServiceNodes/WorkSpace/Environment/SkyLight.json`
- ClassType: "SkyLight"
- Provides soft fill lighting from environment

### Optional: Atmosphere (Fog)
Fog and atmospheric effects. Located at `ServiceNodes/WorkSpace/Environment/Atmosphere.json`
- ClassType: "Atmosphere"
- Adds depth and atmosphere through fog effects

---

## Methods of Adding Environment & Lighting

There are two primary methods to set up environment and lighting:

### Method 1: Static Setup (JSON Configuration)
Create environment and lighting through JSON files. Best for:
- Fixed time-of-day games
- Standard weather conditions
- Simple lighting setups
- Initial game configuration

### Method 2: Dynamic Control (Lua Scripting)
Control environment and lighting at runtime using Lua. Best for:
- Day-night cycles
- Dynamic weather systems
- Mood transitions during gameplay
- Player-controlled lighting

---

## Method 1: Static Setup via JSON

### Step 1: Create Environment Container

**Location**: `ServiceNodes/WorkSpace/Environment.json`

Create the main environment container with this structure:

```json
{
  "ClassType": "Environment",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Environment",
  "reflex": [
    {"Name": "Environment"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"Weather": 0},
    {"Gravity": 0},
    {"LockTimeHour": true},
    {"OpenMiniCraftRender": false},
    {"TimeHour": 14},
    {"UsePlatformTextureMinimumMetaVersion": 1}
  ]
}
```

#### Key Environment Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `Weather` | number | Weather type | `0`=Sunny, `1`=Rain, `2`=Thunder, `3`=Auto, `4`=Custom |
| `Gravity` | number | World gravity (cm/s²) | `0`=Use default (980), or custom value |
| `TimeHour` | number | Integer time (0-23) | `14`=2pm, `6`=6am, `18`=6pm |
| `TimeHour2` | number | Precise time with decimals | `14.5`=2:30pm (optional) |
| `LockTimeHour` | boolean | Freeze time progression | `true`=Fixed time, `false`=Dynamic |
| `SkyPlanet` | number | Sky appearance | `0`=Earth, `1`=Twinkle, `2`=Flame, `3`=Volcano |
| `OpenMiniCraftRender` | boolean | Simple rendering mode | `false`=Standard, `true`=Simplified |

**Common Weather Values:**
- `0`: SUNNY - Clear sky with full sunlight
- `1`: RAIN - Rainy weather with precipitation
- `2`: THUNDER - Stormy weather with lightning
- `3`: AUTO - Automatic weather changes
- `4`: WEATHER_CUSTOM - Custom weather configuration

---

### Step 2: Add SunLight (Directional Light)

**Location**: `ServiceNodes/WorkSpace/Environment/SunLight.json`

Create the sun light source as a child of Environment:

```json
{
  "ClassType": "SunLight",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SunLight",
  "reflex": [
    {"Name": "SunLight"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"Intensity": 1},
    {"Color": [255, 255, 255, 255]},
    {"LockTimeDir": true},
    {"Euler": [0, 0, 0]},
    {"ShadowBias": 0.35},
    {"ShadowSlopeBias": 0.4},
    {"ShadowDistance": 2500},
    {"SunRaysActive": false},
    {"SunRaysScale": 0.45},
    {"SunRaysThreahold": 0.5},
    {"SunRaysColor": [255, 255, 255, 255]},
    {"UseCustomSunAndMoonTex": false},
    {"SunTex": ""},
    {"SunScale": [1, 1]},
    {"MoonTex": ""},
    {"MoonScale": [1, 1]},
    {"ShadowCascadeCount": 1}
  ]
}
```

#### Key SunLight Properties

| Property | Type | Description | Typical Value |
|----------|------|-------------|---------------|
| `Intensity` | number | Brightness (0-∞) | `1.0`=Normal, `0.5`=Dim, `2.0`=Bright |
| `Color` | `[r,g,b,a]` | Light color (0-255) | `[255,255,255,255]`=White |
| `LockTimeDir` | boolean | Lock direction to TimeHour | `true`=Follows time, `false`=Manual |
| `Euler` | `[x,y,z]` | Rotation (degrees) | `[45,180,0]`=Afternoon angle |
| `ShadowBias` | number | Shadow acne prevention | `0.35`=Standard, `0.1-0.5` range |
| `ShadowSlopeBias` | number | Slope shadow bias | `0.4`=Standard, `0.1-0.8` range |
| `ShadowDistance` | number | Shadow render distance (cm) | `2500`=25m, `5000`=50m |
| `ShadowCascadeCount` | number | Shadow quality levels | `1`=Mobile, `2-4`=Desktop |

#### Advanced SunLight Properties (Sun Rays/God Rays)

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `SunRaysActive` | boolean | Enable god rays effect | `false` |
| `SunRaysScale` | number | Ray effect intensity (0-1) | `0.45` |
| `SunRaysThreahold` | number | Ray visibility threshold | `0.5` |
| `SunRaysColor` | `[r,g,b,a]` | Ray tint color | `[255,255,255,255]` |
| `UseCustomSunAndMoonTex` | boolean | Use custom textures | `false` |
| `SunTex` | string | Custom sun texture path | `""` |
| `SunScale` | `[w,h]` | Sun texture scale | `[1,1]` |
| `MoonTex` | string | Custom moon texture path | `""` |
| `MoonScale` | `[w,h]` | Moon texture scale | `[1,1]` |

---

### Step 3: Add SkyLight (Ambient Light)

**Location**: `ServiceNodes/WorkSpace/Environment/SkyLight.json`

Create the ambient lighting as a child of Environment:

```json
{
  "ClassType": "SkyLight",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SkyLight",
  "reflex": [
    {"Name": "SkyLight"},
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
    {"SkyLightType": 0},
    {"SkyLightTexture": "sandboxSysId://SystemDefault/Textures/default_env.png"},
    {"CubeAssetID": "sandboxSysId://SystemDefault/Textures/default_env.png"},
    {"Intensity": 1},
    {"Color": [255, 255, 255, 255]},
    {"BlendAmount": 1},
    {"AmbientSkyColor": [130, 130, 140, 255]},
    {"AmbientEquatorColor": [100, 100, 100, 255]},
    {"AmbientGroundColor": [65, 65, 50, 255]},
    {"AmbientColor": [130, 133, 140, 255]}
  ]
}
```

#### Key SkyLight Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `SkyLightType` | number | Ambient light mode | `0`=Skybox, `1`=Color, `2`=Gradient |
| `Intensity` | number | Ambient brightness (0-∞) | `1.0`=Normal, `0.5`=Dim, `2.0`=Bright |
| `Color` | `[r,g,b,a]` | Main ambient color | `[255,255,255,255]`=White |

#### Skybox Mode (Type 0) - Recommended

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `SkyLightTexture` | string | Cubemap texture path | `"sandboxSysId://SystemDefault/Textures/default_env.png"` |
| `CubeAssetID` | string | Cubemap asset ID | Same as SkyLightTexture |
| `BlendAmount` | number | Texture blend (0-1) | `1.0`=Full texture, `0.5`=Half blend |

#### Gradient Mode (Type 2) - Three-Color Sky

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `AmbientSkyColor` | `[r,g,b,a]` | Sky/top color | `[130,130,140,255]`=Blue-gray |
| `AmbientEquatorColor` | `[r,g,b,a]` | Horizon color | `[100,100,100,255]`=Gray |
| `AmbientGroundColor` | `[r,g,b,a]` | Ground/bottom color | `[65,65,50,255]`=Dark olive |

#### Color Mode (Type 1) - Single Color

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `AmbientColor` | `[r,g,b,a]` | Uniform ambient color | `[130,133,140,255]`=Light gray |

---

### Step 4: Add Atmosphere (Fog) - Optional

**Location**: `ServiceNodes/WorkSpace/Environment/Atmosphere.json`

Add fog effects for depth and atmosphere:

```json
{
  "ClassType": "Atmosphere",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Atmosphere",
  "reflex": [
    {"Name": "Atmosphere"},
    {"Tag": 0},
    {"Enabled": true},
    {"SyncMode": 0},
    {"LocalSyncFlag": 0},
    {"ResourceDynamicLoad": false},
    {"IgnoreSafeMode": false},
    {"ResourceLoadMode": 0},
    {"FogType": 1},
    {"FogColor": [114, 163, 255, 255]},
    {"FogStart": 4800},
    {"FogEnd": 12800},
    {"FogOffset": 1}
  ]
}
```

#### Atmosphere Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `FogType` | number | Fog rendering mode | `1`=Disable, `2`=Linear, `4`=Exponential, `8`=Height-based |
| `FogColor` | `[r,g,b,a]` | Fog tint color | `[114,163,255,255]`=Sky blue |
| `FogStart` | number | Linear fog start distance (cm) | `4800`=48m |
| `FogEnd` | number | Linear fog end distance (cm) | `12800`=128m |
| `FogOffset` | number | Height fog offset | `1`=Standard ground level |

**Fog Type Guidelines:**
- `1` (DISABLE): No fog, maximum visibility
- `2` (LINEAR): Distance-based fog with start/end points (most common)
- `4` (EXP): Exponential fog for gradual transitions
- `8` (HEIGHT): Fog based on altitude (valley fog effect)

---

## Method 2: Dynamic Control via Lua

### Step 1: Access Environment Node

```lua
-- Get or create Environment
local WorkSpace = game:GetService("WorkSpace")
local environment = WorkSpace:FindFirstChildOfClass("Environment")

if not environment then
    environment = SandboxNode.new("Environment", WorkSpace)
    environment.Name = "Environment"
end
```

### Step 2: Configure Environment Properties

```lua
-- Basic Environment Setup
environment.Weather = 0  -- Sunny (0=Sunny, 1=Rain, 2=Thunder)
environment.Gravity = 0  -- 0 = use default 980 cm/s²
environment.TimeHour = 14  -- 2pm
environment.LockTimeHour = true  -- Fixed time

-- For dynamic time with precision
environment.TimeHour2 = 14.5  -- 2:30pm
environment.LockTimeHour = false  -- Allow time to change

-- Sky appearance
environment.SkyPlanet = 0  -- 0=Earth, 1=Twinkle, 2=Flame, 3=Volcano
```

### Step 3: Configure SunLight

```lua
-- Get or create SunLight
local sunLight = environment:FindFirstChild("SunLight")
if not sunLight then
    sunLight = SandboxNode.new("SunLight", environment)
    sunLight.Name = "SunLight"
end

-- Basic lighting
sunLight.Enabled = true
sunLight.Intensity = 1.0
sunLight.Color = {255, 255, 255, 255}  -- White light

-- Direction
sunLight.LockTimeDir = true  -- Follow TimeHour automatically
-- Or set manual direction:
sunLight.LockTimeDir = false
sunLight.Euler = {45, 180, 0}  -- [pitch, yaw, roll] in degrees

-- Shadows
sunLight.ShadowBias = 0.35
sunLight.ShadowSlopeBias = 0.4
sunLight.ShadowDistance = 2500  -- 25m
sunLight.ShadowCascadeCount = 1  -- 1 for mobile, 2-4 for desktop

-- Optional: God Rays
sunLight.SunRaysActive = true
sunLight.SunRaysScale = 0.45
sunLight.SunRaysThreahold = 0.5
sunLight.SunRaysColor = {255, 255, 200, 255}  -- Warm rays
```

### Step 4: Configure SkyLight

```lua
-- Get or create SkyLight
local skyLight = environment:FindFirstChild("SkyLight")
if not skyLight then
    skyLight = SandboxNode.new("SkyLight", environment)
    skyLight.Name = "SkyLight"
end

-- Method A: Skybox Mode (Recommended)
skyLight.SkyLightType = 0
skyLight.SkyLightTexture = "sandboxSysId://SystemDefault/Textures/default_env.png"
skyLight.CubeAssetID = "sandboxSysId://SystemDefault/Textures/default_env.png"
skyLight.BlendAmount = 1.0
skyLight.Intensity = 1.0
skyLight.Color = {255, 255, 255, 255}

-- Method B: Gradient Mode (Three-Color Sky)
skyLight.SkyLightType = 2
skyLight.AmbientSkyColor = {130, 130, 140, 255}     -- Top/sky
skyLight.AmbientEquatorColor = {100, 100, 100, 255} -- Horizon
skyLight.AmbientGroundColor = {65, 65, 50, 255}     -- Bottom/ground
skyLight.Intensity = 1.0

-- Method C: Single Color Mode
skyLight.SkyLightType = 1
skyLight.AmbientColor = {130, 133, 140, 255}
skyLight.Intensity = 1.0
```

### Step 5: Configure Atmosphere (Optional)

```lua
-- Get or create Atmosphere
local atmosphere = environment:FindFirstChild("Atmosphere")
if not atmosphere then
    atmosphere = SandboxNode.new("Atmosphere", environment)
    atmosphere.Name = "Atmosphere"
end

-- Linear fog (most common)
atmosphere.FogType = 2  -- LINEAR
atmosphere.FogColor = {114, 163, 255, 255}  -- Sky blue
atmosphere.FogStart = 4800   -- 48m
atmosphere.FogEnd = 12800    -- 128m

-- Disable fog
atmosphere.FogType = 1  -- DISABLE
```

---

## Practical Examples

### Example 1: Standard Daytime Scene (from simplegame)

**Setup**: Bright sunny day at 2pm with clear visibility

```lua
local WorkSpace = game:GetService("WorkSpace")

-- Create Environment
local environment = SandboxNode.new("Environment", WorkSpace)
environment.Name = "Environment"
environment.Weather = 0  -- Sunny
environment.Gravity = 0  -- Default
environment.TimeHour = 14  -- 2pm
environment.LockTimeHour = true

-- Create SunLight
local sunLight = SandboxNode.new("SunLight", environment)
sunLight.Name = "SunLight"
sunLight.Intensity = 1.0
sunLight.Color = {255, 255, 255, 255}
sunLight.LockTimeDir = true
sunLight.ShadowBias = 0.35
sunLight.ShadowSlopeBias = 0.4
sunLight.ShadowDistance = 2500
sunLight.ShadowCascadeCount = 1

-- Create SkyLight (Skybox mode)
local skyLight = SandboxNode.new("SkyLight", environment)
skyLight.Name = "SkyLight"
skyLight.SkyLightType = 0  -- Skybox
skyLight.SkyLightTexture = "sandboxSysId://SystemDefault/Textures/default_env.png"
skyLight.CubeAssetID = "sandboxSysId://SystemDefault/Textures/default_env.png"
skyLight.Intensity = 1.0
skyLight.Color = {255, 255, 255, 255}
skyLight.BlendAmount = 1.0

-- Create Atmosphere (Minimal fog)
local atmosphere = SandboxNode.new("Atmosphere", environment)
atmosphere.Name = "Atmosphere"
atmosphere.FogType = 1  -- Disabled for clear visibility
```

**Result**: Clean, bright daytime lighting suitable for most games

---

### Example 2: Dawn/Sunrise Scene

**Setup**: Early morning with warm tones and low sun angle

```lua
local WorkSpace = game:GetService("WorkSpace")
local environment = WorkSpace:FindFirstChildOfClass("Environment")
local sunLight = environment:FindFirstChild("SunLight")
local skyLight = environment:FindFirstChild("SkyLight")

-- Dawn time
environment.TimeHour = 6  -- 6am
environment.LockTimeHour = true
environment.Weather = 0  -- Clear

-- Warm sunrise lighting
sunLight.Intensity = 0.7  -- Softer than midday
sunLight.Color = {255, 200, 150, 255}  -- Warm orange tint
sunLight.LockTimeDir = true  -- Low angle follows 6am time

-- Warm ambient
skyLight.SkyLightType = 2  -- Gradient
skyLight.AmbientSkyColor = {100, 120, 150, 255}  -- Deep blue
skyLight.AmbientEquatorColor = {255, 180, 120, 255}  -- Orange horizon
skyLight.AmbientGroundColor = {80, 70, 90, 255}  -- Dark purple-blue
skyLight.Intensity = 0.8
```

**Result**: Beautiful sunrise atmosphere with warm orange glow

---

### Example 3: Stormy/Dark Scene

**Setup**: Overcast stormy weather with reduced visibility

```lua
local WorkSpace = game:GetService("WorkSpace")
local environment = WorkSpace:FindFirstChildOfClass("Environment")
local sunLight = environment:FindFirstChild("SunLight")
local skyLight = environment:FindFirstChild("SkyLight")
local atmosphere = environment:FindFirstChild("Atmosphere")

-- Storm settings
environment.Weather = 2  -- Thunder
environment.TimeHour = 16  -- 4pm
environment.LockTimeHour = true

-- Dim, cool lighting
sunLight.Intensity = 0.4  -- Much darker
sunLight.Color = {180, 190, 200, 255}  -- Cool blue-gray
sunLight.LockTimeDir = true

-- Dark ambient
skyLight.SkyLightType = 2  -- Gradient
skyLight.AmbientSkyColor = {60, 65, 75, 255}  -- Dark gray-blue
skyLight.AmbientEquatorColor = {70, 75, 80, 255}  -- Gray
skyLight.AmbientGroundColor = {40, 45, 50, 255}  -- Very dark
skyLight.Intensity = 0.5  -- Reduced ambient

-- Heavy fog
atmosphere.FogType = 2  -- Linear
atmosphere.FogColor = {100, 110, 120, 255}  -- Dark blue-gray fog
atmosphere.FogStart = 1000  -- 10m (closer)
atmosphere.FogEnd = 5000    -- 50m (shorter visibility)
```

**Result**: Moody, atmospheric storm scene with limited visibility

---

### Example 4: Night Scene with Moon

**Setup**: Nighttime with moon lighting

```lua
local WorkSpace = game:GetService("WorkSpace")
local environment = WorkSpace:FindFirstChildOfClass("Environment")
local sunLight = environment:FindFirstChild("SunLight")
local skyLight = environment:FindFirstChild("SkyLight")

-- Night time
environment.TimeHour = 22  -- 10pm
environment.LockTimeHour = true
environment.Weather = 0  -- Clear night

-- Moonlight (cool and dim)
sunLight.Intensity = 0.3  -- Very dim
sunLight.Color = {150, 160, 200, 255}  -- Cool blue moonlight
sunLight.LockTimeDir = true  -- Moon angle
sunLight.ShadowDistance = 1500  -- Shorter shadows

-- Dark blue ambient
skyLight.SkyLightType = 2  -- Gradient
skyLight.AmbientSkyColor = {10, 15, 30, 255}  -- Very dark blue
skyLight.AmbientEquatorColor = {20, 25, 40, 255}  -- Slightly lighter
skyLight.AmbientGroundColor = {5, 8, 15, 255}  -- Nearly black
skyLight.Intensity = 0.3
```

**Result**: Realistic night scene with moonlight and stars

---

### Example 5: Foggy Morning

**Setup**: Early morning with dense ground fog

```lua
local WorkSpace = game:GetService("WorkSpace")
local environment = WorkSpace:FindFirstChildOfClass("Environment")
local sunLight = environment:FindFirstChild("SunLight")
local skyLight = environment:FindFirstChild("SkyLight")
local atmosphere = environment:FindFirstChild("Atmosphere")

-- Early morning
environment.TimeHour = 7  -- 7am
environment.LockTimeHour = true
environment.Weather = 0  -- Clear but foggy

-- Soft morning light
sunLight.Intensity = 0.8
sunLight.Color = {255, 240, 220, 255}  -- Warm white
sunLight.LockTimeDir = true

-- Cool ambient
skyLight.SkyLightType = 2  -- Gradient
skyLight.AmbientSkyColor = {180, 190, 210, 255}  -- Light blue
skyLight.AmbientEquatorColor = {200, 200, 200, 255}  -- Foggy gray
skyLight.AmbientGroundColor = {160, 165, 170, 255}  -- Gray
skyLight.Intensity = 0.9

-- Dense fog
atmosphere.FogType = 2  -- Linear
atmosphere.FogColor = {220, 225, 230, 255}  -- Light gray-white
atmosphere.FogStart = 500   -- 5m (very close)
atmosphere.FogEnd = 3000    -- 30m (thick fog)
```

**Result**: Mysterious foggy morning atmosphere

---

### Example 6: Dynamic Day-Night Cycle

**Setup**: Automated time progression with lighting changes

```lua
-- Day-Night Cycle System
local DayNightSystem = {}

function DayNightSystem:init()
    local WorkSpace = game:GetService("WorkSpace")
    self.environment = WorkSpace:FindFirstChildOfClass("Environment")
    self.sunLight = self.environment:FindFirstChild("SunLight")
    self.skyLight = self.environment:FindFirstChild("SkyLight")

    -- Cycle configuration
    self.dayDuration = 600  -- 10 minutes for full 24-hour cycle (60s per game hour)
    self.environment.LockTimeHour = false
    self.environment.TimeHour2 = 6.0  -- Start at dawn

    -- Color presets for different times
    self.timePresets = {
        dawn = {  -- 5-7am
            sunIntensity = 0.7,
            sunColor = {255, 200, 150, 255},
            skyIntensity = 0.8,
            skyTop = {100, 120, 150, 255},
            skyHorizon = {255, 180, 120, 255},
            skyGround = {80, 70, 90, 255}
        },
        day = {  -- 7am-5pm
            sunIntensity = 1.0,
            sunColor = {255, 255, 255, 255},
            skyIntensity = 1.0,
            skyTop = {130, 130, 140, 255},
            skyHorizon = {100, 100, 100, 255},
            skyGround = {65, 65, 50, 255}
        },
        dusk = {  -- 5-7pm
            sunIntensity = 0.6,
            sunColor = {255, 150, 100, 255},
            skyIntensity = 0.7,
            skyTop = {80, 90, 120, 255},
            skyHorizon = {255, 130, 80, 255},
            skyGround = {60, 50, 70, 255}
        },
        night = {  -- 7pm-5am
            sunIntensity = 0.2,
            sunColor = {150, 160, 200, 255},
            skyIntensity = 0.3,
            skyTop = {10, 15, 30, 255},
            skyHorizon = {20, 25, 40, 255},
            skyGround = {5, 8, 15, 255}
        }
    }
end

function DayNightSystem:update(deltaTime)
    -- Update time
    local currentTime = self.environment.TimeHour2
    local newTime = (currentTime + deltaTime * (24 / self.dayDuration)) % 24
    self.environment.TimeHour2 = newTime

    -- Get current time period and blend
    local preset = self:getCurrentPreset(newTime)

    -- Apply lighting
    self.sunLight.Intensity = preset.sunIntensity
    self.sunLight.Color = preset.sunColor
    self.skyLight.Intensity = preset.skyIntensity
    self.skyLight.SkyLightType = 2  -- Gradient
    self.skyLight.AmbientSkyColor = preset.skyTop
    self.skyLight.AmbientEquatorColor = preset.skyHorizon
    self.skyLight.AmbientGroundColor = preset.skyGround
end

function DayNightSystem:getCurrentPreset(hour)
    if hour >= 5 and hour < 7 then
        return self.timePresets.dawn
    elseif hour >= 7 and hour < 17 then
        return self.timePresets.day
    elseif hour >= 17 and hour < 19 then
        return self.timePresets.dusk
    else
        return self.timePresets.night
    end
end

-- Usage
DayNightSystem:init()
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    DayNightSystem:update(deltaTime)
end)
```

**Result**: Smooth 24-hour day-night cycle with realistic lighting transitions

---

## Property Reference Tables

### Environment Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `Weather` | number | Enum | Weather type (0=Sunny, 1=Rain, 2=Thunder, 3=Auto, 4=Custom) | `0` |
| `Gravity` | number | cm/s² | World gravity (0=default 980) | `0` |
| `TimeHour` | number | Hour | Integer time 0-23 | `14` |
| `TimeHour2` | number | Hour | Precise time 0-23.999 | `14.0` |
| `LockTimeHour` | boolean | - | Freeze time progression | `true` |
| `SkyPlanet` | number | Enum | Sky appearance (0=Earth, 1=Twinkle, 2=Flame, 3=Volcano) | `0` |
| `OpenMiniCraftRender` | boolean | - | Simplified rendering | `false` |

### SunLight Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `Intensity` | number | - | Brightness 0-∞ | `1.0` |
| `Color` | array | RGB | [R, G, B, A] 0-255 | `[255,255,255,255]` |
| `LockTimeDir` | boolean | - | Lock direction to TimeHour | `true` |
| `Euler` | array | Degrees | [pitch, yaw, roll] rotation | `[0,0,0]` |
| `ShadowBias` | number | - | Shadow acne prevention | `0.35` |
| `ShadowSlopeBias` | number | - | Slope shadow bias | `0.4` |
| `ShadowDistance` | number | cm | Shadow render distance | `2500` |
| `ShadowCascadeCount` | number | - | Shadow quality (1-4) | `1` |
| `SunRaysActive` | boolean | - | Enable god rays | `false` |
| `SunRaysScale` | number | - | Ray intensity 0-1 | `0.45` |
| `SunRaysThreahold` | number | - | Ray visibility | `0.5` |

### SkyLight Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `SkyLightType` | number | Enum | 0=Skybox, 1=Color, 2=Gradient | `0` |
| `Intensity` | number | - | Brightness 0-∞ | `1.0` |
| `Color` | array | RGB | [R, G, B, A] 0-255 | `[255,255,255,255]` |
| `SkyLightTexture` | string | Path | Cubemap texture (Type 0) | `"sandboxSysId://..."` |
| `BlendAmount` | number | - | Texture blend 0-1 | `1.0` |
| `AmbientSkyColor` | array | RGB | Gradient top (Type 2) | `[130,130,140,255]` |
| `AmbientEquatorColor` | array | RGB | Gradient horizon (Type 2) | `[100,100,100,255]` |
| `AmbientGroundColor` | array | RGB | Gradient bottom (Type 2) | `[65,65,50,255]` |
| `AmbientColor` | array | RGB | Single color (Type 1) | `[130,133,140,255]` |

### Atmosphere Properties

| Property | Type | Units | Description | Default |
|----------|------|-------|-------------|---------|
| `FogType` | number | Enum | 1=Disable, 2=Linear, 4=Exp, 8=Height | `1` |
| `FogColor` | array | RGB | [R, G, B, A] 0-255 | `[114,163,255,255]` |
| `FogStart` | number | cm | Linear fog start distance | `4800` |
| `FogEnd` | number | cm | Linear fog end distance | `12800` |
| `FogOffset` | number | - | Height fog offset | `1` |

---

## Best Practices

### Lighting Quality
1. ✅ **Balance SunLight and SkyLight intensities** - Typically 1:1 ratio for natural look
2. ✅ **Use warm tones for sunrise/sunset** - Orange/pink tints (255, 200, 150)
3. ✅ **Use cool tones for night/moonlight** - Blue tints (150, 160, 200)
4. ✅ **Enable shadows on SunLight** - Set `ShadowDistance` based on scene size
5. ✅ **Use Gradient SkyLight mode** for custom atmospheres - More control than Skybox

### Performance Optimization
1. ✅ **Limit ShadowCascadeCount** - Use `1` for mobile, `2-4` for desktop
2. ✅ **Reduce ShadowDistance** for indoor scenes - 1000-2000cm instead of 2500cm
3. ✅ **Use SkyLightType 0 (Skybox)** for best performance - Precomputed lighting
4. ✅ **Disable fog when not needed** - Set `FogType = 1` (DISABLE)
5. ✅ **Lock time when dynamic cycle not needed** - `LockTimeHour = true` saves computation

### Visual Quality
1. ✅ **Match fog color to ambient** - Creates cohesive atmosphere
2. ✅ **Adjust shadow bias** to prevent artifacts - Start with 0.35, tune as needed
3. ✅ **Use god rays sparingly** - Can be performance-intensive
4. ✅ **Test at different times of day** - Ensure readability at all lighting levels
5. ✅ **Consider color-blind accessibility** - Avoid relying solely on color for gameplay

### Workflow Efficiency
1. ✅ **Start with simplegame defaults** - Copy Environment folder as baseline
2. ✅ **Test in Studio before deployment** - Preview lighting in editor
3. ✅ **Document custom lighting presets** - Note TimeHour and color values
4. ✅ **Create lighting templates** for common moods - Day, night, storm, etc.

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Scene Too Dark or Too Bright
**Problem**: Unbalanced SunLight and SkyLight intensities
**Solution**:
```lua
-- Balanced lighting (most common)
sunLight.Intensity = 1.0
skyLight.Intensity = 1.0

-- Outdoor sunny day
sunLight.Intensity = 1.2
skyLight.Intensity = 0.8

-- Overcast/indoor
sunLight.Intensity = 0.6
skyLight.Intensity = 1.0
```

### ❌ Mistake 2: Shadow Artifacts (Acne/Striping)
**Problem**: Incorrect `ShadowBias` or `ShadowSlopeBias` values
**Solution**:
```lua
-- Standard fix
sunLight.ShadowBias = 0.35
sunLight.ShadowSlopeBias = 0.4

-- If still seeing artifacts, increase:
sunLight.ShadowBias = 0.5
sunLight.ShadowSlopeBias = 0.6

-- If shadows disappear, decrease:
sunLight.ShadowBias = 0.2
sunLight.ShadowSlopeBias = 0.3
```

### ❌ Mistake 3: No Shadows Appearing
**Problem**: `ShadowDistance` too small or shadows disabled
**Solution**:
```lua
sunLight.Enabled = true  -- Must be enabled
sunLight.ShadowDistance = 2500  -- At least 25m
sunLight.ShadowCascadeCount = 1  -- At least 1

-- For larger scenes
sunLight.ShadowDistance = 5000  -- 50m
```

### ❌ Mistake 4: Time Not Changing in Day-Night Cycle
**Problem**: `LockTimeHour` is `true`
**Solution**:
```lua
environment.LockTimeHour = false  -- Allow time to change
environment.TimeHour2 = 6.0  -- Starting time

-- In update loop:
environment.TimeHour2 = (environment.TimeHour2 + deltaTime * timeSpeed) % 24
```

### ❌ Mistake 5: Fog Not Visible
**Problem**: Wrong `FogType` or fog range too large
**Solution**:
```lua
-- Enable linear fog
atmosphere.FogType = 2  -- LINEAR (not 1=DISABLE)
atmosphere.FogStart = 2000  -- 20m (closer)
atmosphere.FogEnd = 6000    -- 60m (shorter range)
atmosphere.FogColor = {180, 190, 200, 255}  -- Visible gray
```

### ❌ Mistake 6: Weather Not Appearing
**Problem**: Weather type set incorrectly or not supported
**Solution**:
```lua
-- Sunny weather
environment.Weather = 0  -- SUNNY

-- Rainy weather (requires particle effects to be visible)
environment.Weather = 1  -- RAIN

-- Note: Visual weather effects may require additional particle systems
```

### ❌ Mistake 7: Ambient Light Too Flat
**Problem**: Using `SkyLightType = 1` (single color) instead of gradient
**Solution**:
```lua
-- Use gradient for depth
skyLight.SkyLightType = 2  -- GRADIENT
skyLight.AmbientSkyColor = {130, 130, 140, 255}     -- Top
skyLight.AmbientEquatorColor = {100, 100, 100, 255} -- Middle
skyLight.AmbientGroundColor = {65, 65, 50, 255}     -- Bottom
```

### ❌ Mistake 8: Sun Direction Not Following Time
**Problem**: `LockTimeDir = false` when it should be `true`
**Solution**:
```lua
-- For automatic sun angle based on time
sunLight.LockTimeDir = true
environment.TimeHour = 14  -- Sun angle follows this

-- For manual control
sunLight.LockTimeDir = false
sunLight.Euler = {45, 180, 0}  -- Manual angle
```

---

## Directory Structure

Your lighting files should follow this hierarchy:

```
ServiceNodes/
└── WorkSpace/
    └── Environment.json           # Main container
        ├── SunLight.json          # Directional light
        ├── SkyLight.json          # Ambient light
        └── Atmosphere.json        # Fog effects [Optional]
```

**Important**: All lighting components (SunLight, SkyLight, Atmosphere) must be children of the Environment container in the hierarchy.

---

## Validation Checklist

Before finalizing your environment and lighting setup:

### Environment
- [ ] `ClassType = "Environment"` are set
- [ ] Placed in `ServiceNodes/WorkSpace/` directory
- [ ] `Weather` set to desired type (0=Sunny most common)
- [ ] `TimeHour` set to desired time (14=2pm typical)
- [ ] `LockTimeHour` configured (`true` for fixed, `false` for dynamic)

### SunLight
- [ ] `ClassType = "SunLight"` are set
- [ ] Placed as child of Environment
- [ ] `Intensity` set appropriately (0.5-2.0 range)
- [ ] `Color` configured (white [255,255,255,255] typical)
- [ ] `LockTimeDir` matches your time setup
- [ ] Shadow properties configured (`ShadowBias`, `ShadowDistance`)
- [ ] `ShadowCascadeCount` set based on platform (1=mobile, 2-4=desktop)

### SkyLight
- [ ] `ClassType = "SkyLight"` are set
- [ ] Placed as child of Environment
- [ ] `SkyLightType` chosen (0=Skybox, 2=Gradient recommended)
- [ ] `Intensity` set appropriately (0.5-2.0 range)
- [ ] Gradient colors configured (if Type 2) or texture set (if Type 0)
- [ ] Balanced with SunLight intensity

### Atmosphere (Optional)
- [ ] `ClassType = "Atmosphere"` are set
- [ ] Placed as child of Environment
- [ ] `FogType` configured (1=Disable, 2=Linear typical)
- [ ] `FogColor` matches scene mood
- [ ] `FogStart` and `FogEnd` set for desired visibility range

### Testing
- [ ] Scene is adequately lit (not too dark or bright)
- [ ] Shadows appear correctly without artifacts
- [ ] Ambient lighting provides good fill light
- [ ] Fog creates desired atmospheric effect (if enabled)
- [ ] Performance is acceptable on target platform
- [ ] Lighting works at all intended times of day (if dynamic)

---

## Lighting Presets Quick Reference

### Bright Sunny Day (Standard)
```lua
environment.TimeHour = 14
sunLight.Intensity = 1.0
sunLight.Color = {255, 255, 255, 255}
skyLight.Intensity = 1.0
atmosphere.FogType = 1  -- Disabled
```

### Dawn/Sunrise
```lua
environment.TimeHour = 6
sunLight.Intensity = 0.7
sunLight.Color = {255, 200, 150, 255}
skyLight.Intensity = 0.8
skyLight.AmbientEquatorColor = {255, 180, 120, 255}
```

### Dusk/Sunset
```lua
environment.TimeHour = 18
sunLight.Intensity = 0.6
sunLight.Color = {255, 150, 100, 255}
skyLight.Intensity = 0.7
skyLight.AmbientEquatorColor = {255, 130, 80, 255}
```

### Night/Moonlight
```lua
environment.TimeHour = 22
sunLight.Intensity = 0.3
sunLight.Color = {150, 160, 200, 255}
skyLight.Intensity = 0.3
skyLight.AmbientSkyColor = {10, 15, 30, 255}
```

### Overcast/Stormy
```lua
environment.Weather = 2  -- Thunder
sunLight.Intensity = 0.4
sunLight.Color = {180, 190, 200, 255}
skyLight.Intensity = 0.5
atmosphere.FogType = 2
atmosphere.FogStart = 1000
atmosphere.FogEnd = 5000
```

### Foggy Morning
```lua
environment.TimeHour = 7
sunLight.Intensity = 0.8
sunLight.Color = {255, 240, 220, 255}
skyLight.Intensity = 0.9
atmosphere.FogType = 2
atmosphere.FogColor = {220, 225, 230, 255}
atmosphere.FogStart = 500
atmosphere.FogEnd = 3000
```

---

## Related Documentation

- [How to Add GeoSolid Elements](how-to-add-geosolid.md)
- [How to Create UI Elements](how-to-create-ui-elements.md)
- [How to Build a Feature](../how-to-build-a-feature.md)
- [How to Control Camera](../how-to-control-camera.md)

---

## Color Temperature Guide

Understanding color temperature helps create realistic lighting:

| Time/Mood | Temperature | RGB Example | Description |
|-----------|-------------|-------------|-------------|
| **Sunrise** | Warm | `[255, 200, 150, 255]` | Orange-yellow glow |
| **Midday** | Neutral | `[255, 255, 255, 255]` | Pure white light |
| **Sunset** | Warm | `[255, 150, 100, 255]` | Deep orange-red |
| **Overcast** | Cool | `[180, 190, 200, 255]` | Blue-gray tint |
| **Moonlight** | Cool | `[150, 160, 200, 255]` | Blue-white |
| **Storm** | Cool | `[120, 130, 150, 255]` | Dark blue-gray |
| **Indoor Warm** | Warm | `[255, 220, 180, 255]` | Incandescent bulb |
| **Indoor Cool** | Cool | `[200, 220, 255, 255]` | Fluorescent light |

---

## Advanced Topics

### Custom Sky Textures

To use custom skybox textures:

```lua
skyLight.SkyLightType = 0  -- Skybox mode
skyLight.SkyLightTexture = "sandboxSysId://YourProject/Textures/custom_sky.png"
skyLight.CubeAssetID = "sandboxSysId://YourProject/Textures/custom_sky.png"
skyLight.BlendAmount = 1.0
```

**Requirements**:
- Texture must be cubemap format (6 faces)
- Recommended resolution: 1024x1024 per face
- File format: PNG or JPG

### Dynamic Weather Transitions

For smooth weather changes:

```lua
function transitionWeather(targetWeather, duration)
    local startTime = os.time()
    local startWeather = environment.Weather

    game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = os.time() - startTime
        local progress = math.min(elapsed / duration, 1.0)

        -- Interpolate lighting
        local startIntensity = 1.0
        local targetIntensity = targetWeather == 2 and 0.4 or 1.0
        sunLight.Intensity = startIntensity + (targetIntensity - startIntensity) * progress

        if progress >= 1.0 then
            environment.Weather = targetWeather
            return true  -- Complete
        end
    end)
end

-- Usage: Transition to storm over 5 seconds
transitionWeather(2, 5)  -- 2 = THUNDER
```

### Shadow Quality Tuning

For high-quality shadows on desktop:

```lua
-- High-end configuration
sunLight.ShadowCascadeCount = 4  -- Maximum quality
sunLight.ShadowDistance = 5000   -- 50m range
sunLight.ShadowBias = 0.2        -- Minimal artifacts
sunLight.ShadowSlopeBias = 0.3

-- Mobile-optimized
sunLight.ShadowCascadeCount = 1  -- Performance
sunLight.ShadowDistance = 1500   -- 15m range
sunLight.ShadowBias = 0.4        -- Prevent artifacts
sunLight.ShadowSlopeBias = 0.5
```

---

## Summary

Environment & Lighting in MiniWorld Studio consists of four components:

1. **Environment Container**: Controls weather, time, and gravity
2. **SunLight**: Provides directional lighting and shadows
3. **SkyLight**: Provides ambient lighting and sky appearance
4. **Atmosphere**: Adds fog and atmospheric depth (optional)

**Key takeaways**:
- Use JSON for static lighting setups
- Use Lua for dynamic day-night cycles and weather
- Balance SunLight and SkyLight intensities (typically 1:1)
- Use gradient SkyLight (Type 2) for custom atmospheres
- Tune shadow bias to prevent artifacts
- Test on target platform for performance

**Quick Start**:
1. Copy `simplegame/ServiceNodes/WorkSpace/Environment/` folder
2. Adjust `TimeHour` and `Weather` in Environment.json
3. Modify `Intensity` and `Color` in SunLight.json and SkyLight.json
4. Enable/configure fog in Atmosphere.json if desired
5. Test and iterate based on visual results
