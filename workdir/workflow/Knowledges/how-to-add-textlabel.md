# How to Add UITextLabel

📚 **Prerequisites**: Read [Common UI Knowledge](common-ui.md) first for fundamental UI concepts, color formats, layout patterns, and how to access UI at runtime.

## Overview

**UITextLabel** is a text display element for labels, scores, titles, and information displays. Text labels are non-interactive elements focused on displaying text content.

---

## Method 1: Static Addition (JSON Configuration)

### Basic Text Label Template

```json
{
  "ClassType": "UITextLabel",
  "attribute": [],
  "flags": 0,
  "realNodeName": "ScoreLabel",
  "reflex": [
    {"Name": "ScoreLabel"},
    {"Size": [200, 40]},
    {"Pivot": [0, 0]},
    {"Title": "Score: 0"},
    {"FontSize": 20},
    {"TitleColor": [255, 255, 255, 255]},
    {"TextHAlignment": 0},
    {"TextVAlignment": 1},
    {"Visible": true},
    {"RenderIndex": 1},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 10},
    {"VRelationLength": 10}
  ]
}
```

### Centered Title Label Template

```json
{
  "ClassType": "UITextLabel",
  "realNodeName": "TitleLabel",
  "reflex": [
    {"Name": "TitleLabel"},
    {"Size": [500, 60]},
    {"Pivot": [0.5, 0.5]},
    {"Title": "GAME TITLE"},
    {"FontSize": 36},
    {"TitleColor": [255, 215, 0, 255]},
    {"TextHAlignment": 1},
    {"TextVAlignment": 1},
    {"Visible": true},
    {"LayoutHRelation": 1},
    {"LayoutVRelation": 0},
    {"HRelationLength": 0},
    {"VRelationLength": 50}
  ]
}
```

---

## Method 2: Dynamic Addition (Lua Scripting)

### Basic Text Label Creation

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

local label = SandboxNode.new('UITextLabel', uiRoot)
label.Name = "ScoreLabel"
label.Position = Vector2.new(10, 10)
label.Size = Vector2.new(200, 40)
label.Pivot = Vector2.new(0, 0)  -- Top-left anchor
label.Title = "Score: 0"
label.FontSize = 20
label.TitleColor = ColorQuad.new(255, 255, 255, 255)
label.TextHAlignment = Enum.TextHAlignment.Left  -- Left align
label.TextVAlignment = Enum.TextVAlignment.Center  -- Center vertically
label.Visible = true

-- Function to update score
function UpdateScore(newScore)
    label.Title = "Score: " .. tostring(newScore)
end
```

### Centered Title Label

```lua
local titleLabel = SandboxNode.new('UITextLabel', uiRoot)
titleLabel.Name = "GameTitle"
titleLabel.Position = Vector2.new(960, 100)
titleLabel.Size = Vector2.new(500, 60)
titleLabel.Pivot = Vector2.new(0.5, 0.5)  -- Center anchor
titleLabel.Title = "AWESOME GAME"
titleLabel.FontSize = 36
titleLabel.TitleColor = ColorQuad.new(255, 215, 0, 255)  -- Gold
titleLabel.TextHAlignment = Enum.TextHAlignment.Center  -- Center horizontal
titleLabel.TextVAlignment = Enum.TextVAlignment.Center  -- Center vertical
titleLabel.Visible = true
```

---

## Text Label Properties

Text labels use all common text properties from [Common UI Knowledge](common-ui.md#text-properties):

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `Title` | string | Text content ⚠️ **Not `Text`** | `"Score: 0"` |
| `FontSize` | number | Font size in pixels | `24` |
| `TitleColor` | `[r,g,b,a]` | Text color | `[255, 255, 255, 255]` |
| `Fonts` | string | Font resource path | `""` (default) |
| `TextHAlignment` | number/Enum | Horizontal alignment (see below) | `Enum.TextHAlignment.Left` |
| `TextVAlignment` | number/Enum | Vertical alignment (see below) | `Enum.TextVAlignment.Center` |

---

## 🚨 CRITICAL: Text Alignment - JSON vs Lua

⚠️ **MOST COMMON MISTAKE**: Using numbers for alignment in Lua code

### The Rule

**Alignment values are DIFFERENT in JSON and Lua:**

| Context | TextHAlignment | TextVAlignment |
|---------|----------------|----------------|
| **JSON files** | Use numbers: `0, 1, 2` | Use numbers: `0, 1, 2` |
| **Lua code** | Use Enum: `Enum.TextHAlignment.*` | Use Enum: `Enum.TextVAlignment.*` |

```lua
-- ❌ WRONG: Using numbers in Lua
label.TextHAlignment = 0  -- ERROR: Bridge_EnumItem expected, got number

-- ✅ CORRECT: Using Enum in Lua
label.TextHAlignment = Enum.TextHAlignment.Left  -- Works!
```

### Text Alignment Values

**Horizontal Alignment (`TextHAlignment`):**

| Alignment | JSON Value | Lua Enum Value |
|-----------|-----------|----------------|
| Left | `0` | `Enum.TextHAlignment.Left` |
| Center | `1` | `Enum.TextHAlignment.Center` |
| Right | `2` | `Enum.TextHAlignment.Right` |

**Vertical Alignment (`TextVAlignment`):**

| Alignment | JSON Value | Lua Enum Value |
|-----------|-----------|----------------|
| Top | `0` | `Enum.TextVAlignment.Top` |
| Center | `1` | `Enum.TextVAlignment.Center` |
| Bottom | `2` | `Enum.TextVAlignment.Bottom` |

### Examples

**JSON Configuration (use numbers):**
```json
{
  "ClassType": "UITextLabel",
  "realNodeName": "MyLabel",
  "reflex": [
    {"TextHAlignment": 1},
    {"TextVAlignment": 1}
  ]
}
```

**Lua Code (use Enum):**
```lua
local label = SandboxNode.new('UITextLabel', uiRoot)
label.TextHAlignment = Enum.TextHAlignment.Center
label.TextVAlignment = Enum.TextVAlignment.Center
```

---

## Practical Examples

### Example 1: Score Display (Top-Left HUD)

```lua
local scoreLabel = SandboxNode.new('UITextLabel', uiRoot)
scoreLabel.Name = "ScoreLabel"
scoreLabel.Position = Vector2.new(10, 10)
scoreLabel.Size = Vector2.new(200, 40)
scoreLabel.Pivot = Vector2.new(0, 0)  -- Top-left
scoreLabel.Title = "Score: 0"
scoreLabel.FontSize = 20
scoreLabel.TitleColor = ColorQuad.new(255, 255, 255, 255)
scoreLabel.TextHAlignment = Enum.TextHAlignment.Left
scoreLabel.TextVAlignment = Enum.TextVAlignment.Center
scoreLabel.Visible = true
scoreLabel.LayoutHRelation = 0  -- Left edge
scoreLabel.LayoutVRelation = 0  -- Top edge
scoreLabel.HRelationLength = 10
scoreLabel.VRelationLength = 10

-- Update function
local currentScore = 0
function AddScore(points)
    currentScore = currentScore + points
    scoreLabel.Title = "Score: " .. tostring(currentScore)
end
```

### Example 2: Currency Display (Top-Right HUD)

```lua
local currencyLabel = SandboxNode.new('UITextLabel', uiRoot)
currencyLabel.Name = "CurrencyLabel"
currencyLabel.Position = Vector2.new(1910, 10)
currencyLabel.Size = Vector2.new(200, 40)
currencyLabel.Pivot = Vector2.new(1, 0)  -- Top-right anchor
currencyLabel.Title = "Coins: 0"
currencyLabel.FontSize = 20
currencyLabel.TitleColor = ColorQuad.new(255, 215, 0, 255)  -- Gold
currencyLabel.TextHAlignment = Enum.TextHAlignment.Right
currencyLabel.TextVAlignment = Enum.TextVAlignment.Center
currencyLabel.Visible = true
currencyLabel.LayoutHRelation = 2  -- Right edge
currencyLabel.LayoutVRelation = 0  -- Top edge
currencyLabel.HRelationLength = -10
currencyLabel.VRelationLength = 10
```

### Example 3: Centered Game Title

```lua
local titleLabel = SandboxNode.new('UITextLabel', uiRoot)
titleLabel.Name = "TitleLabel"
titleLabel.Position = Vector2.new(960, 100)
titleLabel.Size = Vector2.new(600, 80)
titleLabel.Pivot = Vector2.new(0.5, 0.5)  -- Center
titleLabel.Title = "TOWER DEFENSE"
titleLabel.FontSize = 48
titleLabel.TitleColor = ColorQuad.new(255, 215, 0, 255)  -- Gold
titleLabel.TextHAlignment = Enum.TextHAlignment.Center
titleLabel.TextVAlignment = Enum.TextVAlignment.Center
titleLabel.Visible = true
titleLabel.LayoutHRelation = 1  -- Center H
titleLabel.LayoutVRelation = 0  -- Top
titleLabel.VRelationLength = 50
```

### Example 4: Health Text Overlay

```lua
-- Text overlay on health bar
local healthText = SandboxNode.new('UITextLabel', healthBarPanel)
healthText.Name = "HealthText"
healthText.Position = Vector2.new(152, 17)
healthText.Size = Vector2.new(300, 30)
healthText.Pivot = Vector2.new(0.5, 0.5)
healthText.Title = "100 / 100"
healthText.FontSize = 18
healthText.TitleColor = ColorQuad.new(255, 255, 255, 255)
healthText.TextHAlignment = Enum.TextHAlignment.Center
healthText.TextVAlignment = Enum.TextVAlignment.Center
healthText.Visible = true

-- Update function
function UpdateHealth(current, max)
    healthText.Title = string.format("%d / %d", current, max)
end
```

### Example 5: Instruction Label (Bottom Center)

```lua
local instructionLabel = SandboxNode.new('UITextLabel', uiRoot)
instructionLabel.Name = "Instructions"
instructionLabel.Position = Vector2.new(960, 1020)
instructionLabel.Size = Vector2.new(600, 40)
instructionLabel.Pivot = Vector2.new(0.5, 1)  -- Bottom center anchor
instructionLabel.Title = "Press SPACE to jump"
instructionLabel.FontSize = 22
instructionLabel.TitleColor = ColorQuad.new(255, 255, 255, 200)  -- Semi-transparent
instructionLabel.TextHAlignment = Enum.TextHAlignment.Center
instructionLabel.TextVAlignment = Enum.TextVAlignment.Center
instructionLabel.Visible = true
instructionLabel.LayoutHRelation = 1  -- Center H
instructionLabel.LayoutVRelation = 2  -- Bottom
instructionLabel.VRelationLength = -60
```

### Example 6: Timer Display

```lua
local timerLabel = SandboxNode.new('UITextLabel', uiRoot)
timerLabel.Name = "Timer"
timerLabel.Position = Vector2.new(960, 10)
timerLabel.Size = Vector2.new(200, 50)
timerLabel.Pivot = Vector2.new(0.5, 0)  -- Top center anchor
timerLabel.Title = "00:00"
timerLabel.FontSize = 32
timerLabel.TitleColor = ColorQuad.new(255, 255, 255, 255)
timerLabel.TextHAlignment = Enum.TextHAlignment.Center
timerLabel.TextVAlignment = Enum.TextVAlignment.Center
timerLabel.Visible = true
timerLabel.LayoutHRelation = 1  -- Center H
timerLabel.LayoutVRelation = 0  -- Top
timerLabel.VRelationLength = 10

-- Timer update function
local timeRemaining = 300  -- 5 minutes in seconds
function UpdateTimer()
    local minutes = math.floor(timeRemaining / 60)
    local seconds = timeRemaining % 60
    timerLabel.Title = string.format("%02d:%02d", minutes, seconds)

    timeRemaining = timeRemaining - 1
    if timeRemaining < 0 then
        timeRemaining = 0
        timerLabel.TitleColor = ColorQuad.new(255, 0, 0, 255)  -- Red when time's up
    end
end
```

### Example 7: Multi-line Information Label

```lua
local infoLabel = SandboxNode.new('UITextLabel', uiRoot)
infoLabel.Name = "InfoLabel"
infoLabel.Position = Vector2.new(50, 100)
infoLabel.Size = Vector2.new(300, 100)
infoLabel.Pivot = Vector2.new(0, 0)
infoLabel.Title = "Wave: 1\nEnemies: 10\nHealth: 100"
infoLabel.FontSize = 18
infoLabel.TitleColor = ColorQuad.new(255, 255, 255, 255)
infoLabel.TextHAlignment = Enum.TextHAlignment.Left
infoLabel.TextVAlignment = Enum.TextVAlignment.Top
infoLabel.Visible = true

-- Update function
function UpdateWaveInfo(wave, enemies, health)
    infoLabel.Title = string.format("Wave: %d\nEnemies: %d\nHealth: %d", wave, enemies, health)
end
```

---

## Common Label Patterns

### HUD Score/Stats Pattern

```lua
-- Top-left score
local label = SandboxNode.new('UITextLabel', uiRoot)
label.Position = Vector2.new(10, 10)
label.Pivot = Vector2.new(0, 0)
label.TextHAlignment = Enum.TextHAlignment.Left
label.LayoutHRelation = 0  -- Left edge
label.LayoutVRelation = 0  -- Top edge
```

### Centered Title Pattern

```lua
-- Center screen title
local label = SandboxNode.new('UITextLabel', uiRoot)
label.Position = Vector2.new(960, 100)
label.Pivot = Vector2.new(0.5, 0.5)
label.TextHAlignment = Enum.TextHAlignment.Center
label.LayoutHRelation = 1  -- Center H
label.LayoutVRelation = 0  -- Top
```

### Right-Aligned Currency Pattern

```lua
-- Top-right currency
local label = SandboxNode.new('UITextLabel', uiRoot)
label.Position = Vector2.new(1910, 10)
label.Pivot = Vector2.new(1, 0)
label.TextHAlignment = Enum.TextHAlignment.Right
label.LayoutHRelation = 2  -- Right edge
label.LayoutVRelation = 0  -- Top edge
```

---

## Quick Reference

### Minimal Text Label (JSON)
```json
{
  "ClassType": "UITextLabel",
  "realNodeName": "MyLabel",
  "reflex": [
    {"Name": "MyLabel"},
    {"Size": [200, 40]},
    {"Title": "Hello"},
    {"FontSize": 20},
    {"Visible": true},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 10},
    {"VRelationLength": 10}
  ]
}
```

### Minimal Text Label (Lua)
```lua
local lbl = SandboxNode.new('UITextLabel', uiRoot)
lbl.Position = Vector2.new(10, 10)
lbl.Size = Vector2.new(200, 40)
lbl.Title = "Hello"
lbl.FontSize = 20
lbl.Visible = true
```

---

## Important Notes

🚨 **CRITICAL - Use Enum for Alignment in Lua**: In Lua code, use `Enum.TextHAlignment.*` and `Enum.TextVAlignment.*`, NOT numbers
⚠️ **Use `Title` not `Text`**: MiniWorld Studio uses `Title` property for text content, not `Text`
⚠️ **Access from PlayerGui**: Remember to access UI from `game.Players.LocalPlayer.PlayerGui` at runtime, not from StarterGui
⚠️ **JSON vs Lua Alignment**: JSON files use numbers (0, 1, 2), Lua code uses Enum values
✅ **String Formatting**: Use Lua's `string.format()` for formatted text (e.g., `string.format("Score: %d", score)`)
✅ **Multi-line Text**: Use `\n` for line breaks in text content

### Common Alignment Mistake

```lua
-- ❌ WRONG: This will cause "Bridge_EnumItem expected, got number" error
label.TextHAlignment = 0
label.TextVAlignment = 1

-- ✅ CORRECT: Use Enum values in Lua
label.TextHAlignment = Enum.TextHAlignment.Left
label.TextVAlignment = Enum.TextVAlignment.Center
```

---

## See Also

- [Common UI Knowledge](common-ui.md) - Fundamental concepts, colors, runtime access
- [UI Layout System Guide](common-ui-layout.md) - Responsive positioning, layout patterns, multi-resolution support
- [How to Add Button](how-to-add-button.md)
- [How to Add ProgressBar](how-to-add-progressbar.md)
- [How to Add Panel](how-to-add-panel.md)

---

**Created**: 2025-10-20
**Last Updated**: 2025-10-23
**Version**: 2.0.0
**Based on**: MiniWorld Studio UI documentation and sample code analysis

**v2.0.0 Changes**: Added comprehensive documentation for text alignment Enum values (TextHAlignment/TextVAlignment). BREAKING: All Lua code examples now use correct Enum values instead of numbers.
