# How to Add UIProgressBar

📚 **Prerequisites**: Read [Common UI Knowledge](common-ui.md) first for fundamental UI concepts, color formats, layout patterns, and how to access UI at runtime.

## Overview

**UIProgressBar** displays progress indicators for health, stamina, loading screens, experience bars, and other quantifiable values. Progress bars show a visual fill based on a value between min and max.

---

## Method 1: Static Addition (JSON Configuration)

### Basic Progress Bar Template

```json
{
  "ClassType": "UIProgressBar",
  "attribute": [],
  "flags": 0,
  "realNodeName": "HealthBar",
  "reflex": [
    {"Name": "HealthBar"},
    {"Size": [300, 30]},
    {"Pivot": [0, 0]},
    {"MinValue": 0},
    {"MaxValue": 100},
    {"Value": 75},
    {"ForegroundColor": [0, 255, 0, 255]},
    {"BackgroundColor": [128, 128, 128, 255]},
    {"LineColor": [0, 0, 0, 255]},
    {"LineSize": 1},
    {"Visible": true},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 50},
    {"VRelationLength": 50}
  ]
}
```

---

## Method 2: Dynamic Addition (Lua Scripting)

### Basic Progress Bar Creation

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

local healthBar = SandboxNode.new('UIProgressBar', uiRoot)
healthBar.Name = "HealthBar"
healthBar.Position = Vector2.new(50, 50)
healthBar.Size = Vector2.new(300, 30)
healthBar.MinValue = 0
healthBar.MaxValue = 100
healthBar.Value = 100  -- Full health
healthBar.ForegroundColor = ColorQuad.new(0, 255, 0, 255)  -- Green
healthBar.BackgroundColor = ColorQuad.new(128, 128, 128, 255)  -- Gray
healthBar.LineColor = ColorQuad.new(0, 0, 0, 255)
healthBar.LineSize = 1
healthBar.Visible = true

-- Function to update health
function UpdateHealth(health)
    healthBar.Value = math.max(0, math.min(100, health))

    -- Change color based on health
    if health > 50 then
        healthBar.ForegroundColor = ColorQuad.new(0, 255, 0, 255)  -- Green
    elseif health > 25 then
        healthBar.ForegroundColor = ColorQuad.new(255, 255, 0, 255)  -- Yellow
    else
        healthBar.ForegroundColor = ColorQuad.new(255, 0, 0, 255)  -- Red
    end
end
```

---

## Progress Bar Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `MinValue` | number | Minimum value (usually 0) | `0` |
| `MaxValue` | number | Maximum value | `100` |
| `Value` | number | Current value | `75` |
| `ForegroundColor` | `[r,g,b,a]` | Fill color (progress) | `[0, 255, 0, 255]` |
| `BackgroundColor` | `[r,g,b,a]` | Background color (empty portion) | `[128, 128, 128, 255]` |
| `LineColor` | `[r,g,b,a]` | Border color | `[0, 0, 0, 255]` |
| `LineSize` | number | Border thickness (pixels) | `1` |

---

## Practical Examples

### Example 1: Health Bar with Background Panel

```lua
-- Background panel
local healthBG = SandboxNode.new('UIPanel', uiRoot)
healthBG.Name = "HealthBG"
healthBG.Position = Vector2.new(50, 50)
healthBG.Size = Vector2.new(304, 34)
healthBG.Pivot = Vector2.new(0, 0)
healthBG.FillColor = ColorQuad.new(40, 40, 40, 200)
healthBG.LineColor = ColorQuad.new(0, 0, 0, 255)
healthBG.LineSize = 2
healthBG.Visible = true

-- Health bar
local healthBar = SandboxNode.new('UIProgressBar', healthBG)
healthBar.Name = "HealthBar"
healthBar.Position = Vector2.new(2, 2)
healthBar.Size = Vector2.new(300, 30)
healthBar.Pivot = Vector2.new(0, 0)
healthBar.MinValue = 0
healthBar.MaxValue = 100
healthBar.Value = 100
healthBar.ForegroundColor = ColorQuad.new(0, 255, 0, 255)
healthBar.BackgroundColor = ColorQuad.new(80, 80, 80, 255)
healthBar.Visible = true

-- Health text overlay
local healthText = SandboxNode.new('UITextLabel', healthBG)
healthText.Name = "HealthText"
healthText.Position = Vector2.new(152, 17)
healthText.Size = Vector2.new(300, 30)
healthText.Pivot = Vector2.new(0.5, 0.5)
healthText.Title = "100 / 100"
healthText.FontSize = 18
healthText.TitleColor = ColorQuad.new(255, 255, 255, 255)
healthText.TextHAlignment = 1  -- Center
healthText.TextVAlignment = 1  -- Center
healthText.Visible = true

-- Update function
function UpdateHealth(current, max)
    healthBar.Value = current
    healthBar.MaxValue = max
    healthText.Title = string.format("%d / %d", current, max)

    -- Change color based on percentage
    local percent = current / max
    if percent > 0.5 then
        healthBar.ForegroundColor = ColorQuad.new(0, 255, 0, 255)  -- Green
    elseif percent > 0.25 then
        healthBar.ForegroundColor = ColorQuad.new(255, 255, 0, 255)  -- Yellow
    else
        healthBar.ForegroundColor = ColorQuad.new(255, 0, 0, 255)  -- Red
    end
end
```

### Example 2: Stamina Bar

```lua
local staminaBar = SandboxNode.new('UIProgressBar', uiRoot)
staminaBar.Name = "StaminaBar"
staminaBar.Position = Vector2.new(50, 90)
staminaBar.Size = Vector2.new(300, 20)
staminaBar.MinValue = 0
staminaBar.MaxValue = 100
staminaBar.Value = 100
staminaBar.ForegroundColor = ColorQuad.new(255, 215, 0, 255)  -- Gold
staminaBar.BackgroundColor = ColorQuad.new(100, 100, 100, 255)
staminaBar.LineColor = ColorQuad.new(0, 0, 0, 255)
staminaBar.LineSize = 1
staminaBar.Visible = true

-- Update stamina
function UpdateStamina(stamina)
    staminaBar.Value = math.max(0, math.min(100, stamina))

    -- Fade when low
    if stamina < 20 then
        staminaBar.ForegroundColor = ColorQuad.new(255, 100, 0, 255)  -- Orange
    else
        staminaBar.ForegroundColor = ColorQuad.new(255, 215, 0, 255)  -- Gold
    end
end
```

### Example 3: Experience Bar (Bottom of Screen)

```lua
local expBar = SandboxNode.new('UIProgressBar', uiRoot)
expBar.Name = "ExperienceBar"
expBar.Position = Vector2.new(960, 1070)
expBar.Size = Vector2.new(1000, 10)
expBar.Pivot = Vector2.new(0.5, 1)  -- Bottom center
expBar.MinValue = 0
expBar.MaxValue = 1000
expBar.Value = 350
expBar.ForegroundColor = ColorQuad.new(138, 43, 226, 255)  -- Purple
expBar.BackgroundColor = ColorQuad.new(50, 50, 50, 200)
expBar.LineColor = ColorQuad.new(0, 0, 0, 255)
expBar.LineSize = 1
expBar.Visible = true
expBar.LayoutHRelation = 1  -- Center H
expBar.LayoutVRelation = 2  -- Bottom
expBar.VRelationLength = -10

-- Update experience
function AddExperience(exp)
    local newValue = expBar.Value + exp
    if newValue >= expBar.MaxValue then
        -- Level up!
        print("Level up!")
        expBar.Value = newValue - expBar.MaxValue
    else
        expBar.Value = newValue
    end
end
```

### Example 4: Loading Bar (Center Screen)

```lua
local loadingBar = SandboxNode.new('UIProgressBar', uiRoot)
loadingBar.Name = "LoadingBar"
loadingBar.Position = Vector2.new(960, 600)
loadingBar.Size = Vector2.new(500, 30)
loadingBar.Pivot = Vector2.new(0.5, 0.5)
loadingBar.MinValue = 0
loadingBar.MaxValue = 100
loadingBar.Value = 0
loadingBar.ForegroundColor = ColorQuad.new(0, 150, 255, 255)  -- Blue
loadingBar.BackgroundColor = ColorQuad.new(60, 60, 60, 255)
loadingBar.LineColor = ColorQuad.new(200, 200, 200, 255)
loadingBar.LineSize = 2
loadingBar.Visible = false  -- Hidden by default
loadingBar.RenderIndex = 999  -- Always on top

-- Loading text
local loadingText = SandboxNode.new('UITextLabel', uiRoot)
loadingText.Name = "LoadingText"
loadingText.Position = Vector2.new(960, 560)
loadingText.Size = Vector2.new(500, 30)
loadingText.Pivot = Vector2.new(0.5, 0.5)
loadingText.Title = "Loading... 0%"
loadingText.FontSize = 20
loadingText.TitleColor = ColorQuad.new(255, 255, 255, 255)
loadingText.TextHAlignment = 1
loadingText.TextVAlignment = 1
loadingText.Visible = false
loadingText.RenderIndex = 999

-- Show loading
function ShowLoading()
    loadingBar.Visible = true
    loadingText.Visible = true
    loadingBar.Value = 0
end

-- Update loading progress
function UpdateLoading(percent)
    loadingBar.Value = percent
    loadingText.Title = string.format("Loading... %d%%", percent)
end

-- Hide loading
function HideLoading()
    loadingBar.Visible = false
    loadingText.Visible = false
end
```

### Example 5: Enemy Health Bar (Above Enemy)

```lua
-- Create health bar for enemy (would be parented to a UIBillboard in actual use)
local enemyHealthBar = SandboxNode.new('UIProgressBar', uiRoot)
enemyHealthBar.Name = "EnemyHealth"
enemyHealthBar.Position = Vector2.new(960, 300)
enemyHealthBar.Size = Vector2.new(150, 15)
enemyHealthBar.Pivot = Vector2.new(0.5, 0.5)
enemyHealthBar.MinValue = 0
enemyHealthBar.MaxValue = 100
enemyHealthBar.Value = 100
enemyHealthBar.ForegroundColor = ColorQuad.new(255, 0, 0, 255)  -- Red
enemyHealthBar.BackgroundColor = ColorQuad.new(80, 0, 0, 200)
enemyHealthBar.LineColor = ColorQuad.new(0, 0, 0, 255)
enemyHealthBar.LineSize = 1
enemyHealthBar.Visible = true

-- Update enemy health
function UpdateEnemyHealth(health)
    enemyHealthBar.Value = math.max(0, math.min(100, health))
    if health <= 0 then
        enemyHealthBar.Visible = false
    end
end
```

### Example 6: Boss Health Bar (Top of Screen)

```lua
local bossHealthBar = SandboxNode.new('UIProgressBar', uiRoot)
bossHealthBar.Name = "BossHealth"
bossHealthBar.Position = Vector2.new(960, 50)
bossHealthBar.Size = Vector2.new(800, 40)
bossHealthBar.Pivot = Vector2.new(0.5, 0)
bossHealthBar.MinValue = 0
bossHealthBar.MaxValue = 10000
bossHealthBar.Value = 10000
bossHealthBar.ForegroundColor = ColorQuad.new(200, 0, 0, 255)  -- Dark red
bossHealthBar.BackgroundColor = ColorQuad.new(60, 60, 60, 255)
bossHealthBar.LineColor = ColorQuad.new(255, 215, 0, 255)  -- Gold border
bossHealthBar.LineSize = 3
bossHealthBar.Visible = false  -- Hidden until boss appears
bossHealthBar.LayoutHRelation = 1  -- Center H
bossHealthBar.LayoutVRelation = 0  -- Top
bossHealthBar.VRelationLength = 50
bossHealthBar.RenderIndex = 10

-- Boss name label
local bossNameLabel = SandboxNode.new('UITextLabel', uiRoot)
bossNameLabel.Name = "BossName"
bossNameLabel.Position = Vector2.new(960, 30)
bossNameLabel.Size = Vector2.new(800, 30)
bossNameLabel.Pivot = Vector2.new(0.5, 0)
bossNameLabel.Title = "BOSS NAME"
bossNameLabel.FontSize = 24
bossNameLabel.TitleColor = ColorQuad.new(255, 215, 0, 255)
bossNameLabel.TextHAlignment = 1
bossNameLabel.TextVAlignment = 1
bossNameLabel.Visible = false
bossNameLabel.LayoutHRelation = 1
bossNameLabel.LayoutVRelation = 0
bossNameLabel.VRelationLength = 30

-- Show boss health bar
function ShowBossHealth(bossName, maxHealth)
    bossHealthBar.MaxValue = maxHealth
    bossHealthBar.Value = maxHealth
    bossHealthBar.Visible = true
    bossNameLabel.Title = bossName
    bossNameLabel.Visible = true
end

-- Update boss health
function UpdateBossHealth(currentHealth)
    bossHealthBar.Value = currentHealth
    if currentHealth <= 0 then
        bossHealthBar.Visible = false
        bossNameLabel.Visible = false
    end
end
```

### Example 7: Multi-segment Health Bar

```lua
-- Create multiple segments for a segmented health bar
local segmentCount = 5
local segmentWidth = 58
local segmentSpacing = 2
local totalWidth = (segmentWidth * segmentCount) + (segmentSpacing * (segmentCount - 1))

local healthSegments = {}

for i = 1, segmentCount do
    local segment = SandboxNode.new('UIProgressBar', uiRoot)
    segment.Name = "HealthSegment" .. i
    segment.Position = Vector2.new(50 + ((i - 1) * (segmentWidth + segmentSpacing)), 50)
    segment.Size = Vector2.new(segmentWidth, 30)
    segment.MinValue = 0
    segment.MaxValue = 100
    segment.Value = 100
    segment.ForegroundColor = ColorQuad.new(0, 255, 0, 255)
    segment.BackgroundColor = ColorQuad.new(80, 80, 80, 255)
    segment.LineColor = ColorQuad.new(0, 0, 0, 255)
    segment.LineSize = 1
    segment.Visible = true

    table.insert(healthSegments, segment)
end

-- Update segmented health
function UpdateSegmentedHealth(totalHealth)
    local maxHealthPerSegment = 100
    local remainingHealth = totalHealth

    for i, segment in ipairs(healthSegments) do
        if remainingHealth >= maxHealthPerSegment then
            segment.Value = maxHealthPerSegment
            remainingHealth = remainingHealth - maxHealthPerSegment
        elseif remainingHealth > 0 then
            segment.Value = remainingHealth
            remainingHealth = 0
        else
            segment.Value = 0
        end
    end
end
```

---

## Quick Reference

### Minimal Progress Bar (JSON)
```json
{
  "ClassType": "UIProgressBar",
  "realNodeName": "MyBar",
  "reflex": [
    {"Name": "MyBar"},
    {"Size": [300, 30]},
    {"MinValue": 0},
    {"MaxValue": 100},
    {"Value": 75},
    {"ForegroundColor": [0, 255, 0, 255]},
    {"BackgroundColor": [128, 128, 128, 255]},
    {"Visible": true},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 50},
    {"VRelationLength": 50}
  ]
}
```

### Minimal Progress Bar (Lua)
```lua
local bar = SandboxNode.new('UIProgressBar', uiRoot)
bar.Position = Vector2.new(50, 50)
bar.Size = Vector2.new(300, 30)
bar.MinValue = 0
bar.MaxValue = 100
bar.Value = 75
bar.ForegroundColor = ColorQuad.new(0, 255, 0, 255)
bar.BackgroundColor = ColorQuad.new(128, 128, 128, 255)
bar.Visible = true
```

---

## Important Notes

⚠️ **Access from PlayerGui**: Remember to access UI from `game.Players.LocalPlayer.PlayerGui` at runtime, not from StarterGui
✅ **Value Clamping**: Always clamp values between `MinValue` and `MaxValue` using `math.max()` and `math.min()`
✅ **Color Feedback**: Change `ForegroundColor` based on value to provide visual feedback (e.g., green → yellow → red for health)
✅ **Text Overlay**: Add a UITextLabel on top of the bar to show exact values (e.g., "75/100")
✅ **Background Panel**: Place progress bars inside a UIPanel for a cleaner look with borders
✅ **Percentage Calculation**: Calculate percentage as `(Value / MaxValue) * 100` for conditional logic

---

## See Also

- [Common UI Knowledge](common-ui.md) - Fundamental concepts, colors, runtime access
- [UI Layout System Guide](common-ui-layout.md) - Responsive positioning, layout patterns, multi-resolution support
- [How to Add TextLabel](how-to-add-textlabel.md) - For text overlays on progress bars
- [How to Add Panel](how-to-add-panel.md) - For background panels
- [How to Add Button](how-to-add-button.md)
