# How to Add UIButton

📚 **Prerequisites**: Read [Common UI Knowledge](common-ui.md) first for fundamental UI concepts, color formats, layout patterns, and how to access UI at runtime.

## Overview

**UIButton** is an interactive button element for player actions, menu options, and controls. Buttons support comprehensive events, sound effects, and visual enhancements.

---

## Method 1: Static Addition (JSON Configuration)

### Basic Button Template

```json
{
  "ClassType": "UIButton",
  "attribute": [],
  "flags": 0,
  "realNodeName": "StartButton",
  "reflex": [
    {"Name": "StartButton"},
    {"Tag": 0},
    {"Enabled": true},
    {"Size": [200, 60]},
    {"Pivot": [0.5, 0.5]},
    {"Title": "Start Game"},
    {"TitleSize": 24},
    {"TitleColor": [255, 255, 255, 255]},
    {"TextHAlignment": 1},
    {"TextVAlignment": 1},
    {"FillColor": [100, 150, 200, 255]},
    {"LineColor": [50, 50, 50, 255]},
    {"LineSize": 2},
    {"Visible": true},
    {"RenderIndex": 1},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 100},
    {"VRelationLength": 100}
  ]
}
```

### Button with Icon

```json
{
  "ClassType": "UIButton",
  "realNodeName": "IconButton",
  "reflex": [
    {"Name": "IconButton"},
    {"Size": [100, 100]},
    {"Pivot": [0.5, 0.5]},
    {"Icon": "sandboxSysId://UI/Icons/star.png"},
    {"IconColor": [255, 215, 0, 255]},
    {"ScaleType": 1},
    {"FillColor": [100, 150, 200, 255]},
    {"LineColor": [50, 50, 50, 255]},
    {"LineSize": 2},
    {"Visible": true},
    {"RenderIndex": 1},
    {"LayoutHRelation": 1},
    {"LayoutVRelation": 1},
    {"HRelationLength": 0},
    {"VRelationLength": 0}
  ]
}
```

---

## Method 2: Dynamic Addition (Lua Scripting)

### Basic Button Creation

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

local button = SandboxNode.new('UIButton', uiRoot)
button.Name = "StartButton"
button.Position = Vector2.new(960, 540)  -- Center of 1920x1080 screen
button.Size = Vector2.new(200, 60)
button.Pivot = Vector2.new(0.5, 0.5)     -- Center pivot
button.Title = "Start Game"
button.TitleSize = 24
button.TitleColor = ColorQuad.new(255, 255, 255, 255)  -- White text
button.FillColor = ColorQuad.new(100, 150, 200, 255)   -- Blue background
button.LineColor = ColorQuad.new(50, 50, 50, 255)      -- Dark border
button.LineSize = 2
button.Visible = true

-- Add click event
button.Click:Connect(function(node, isClick, position, touchId)
    print("Button clicked at:", position.x, position.y)
    -- Add button action here
end)
```

### Button with Icon

```lua
local iconButton = SandboxNode.new('UIButton', uiRoot)
iconButton.Name = "IconButton"
iconButton.Position = Vector2.new(960, 540)
iconButton.Size = Vector2.new(100, 100)
iconButton.Pivot = Vector2.new(0.5, 0.5)
iconButton.Icon = "sandboxSysId://UI/Icons/star.png"
iconButton.IconColor = ColorQuad.new(255, 215, 0, 255)  -- Gold color
iconButton.ScaleType = 1  -- Keep aspect ratio
iconButton.FillColor = ColorQuad.new(100, 150, 200, 255)
iconButton.Visible = true
```

---

## Button-Specific Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `Icon` | string | Button icon resource path | `"sandboxSysId://UI/icon.png"` |
| `IconColor` | `[r,g,b,a]` | Icon tint color | `[255, 215, 0, 255]` |
| `ScaleType` | number | Icon scaling mode | `1=stretch, 2=slice, 3=tile` |
| `SliceCenter` | `Vector4` | 9-slice margins (left, top, right, bottom) | `Vector4.new(10, 10, 20, 20)` |
| `DownEffect` | enum | Press-down effect type | `0=none, 1=color, 2=scale` |
| `DownEffectValue` | number | Press-down effect strength | `0.9` (90% scale or brightness) |
| `OutlineEnable` | boolean | Enable text outline | `true` |
| `OutlineColor` | `[r,g,b,a]` | Outline color | `[0, 0, 0, 255]` |
| `OutlineSize` | number | Outline thickness (pixels) | `2` |
| `ShadowEnable` | boolean | Enable text shadow | `true` |
| `ShadowColor` | `[r,g,b,a]` | Shadow color | `[0, 0, 0, 128]` |
| `ShadowOffset` | `[x, y]` | Shadow offset (pixels) | `[2, 2]` |
| `IsEnableDefaultSound` | boolean | Enable default button sounds | `true` |
| `PressButtonSound` | SandboxNode | Custom press sound node | Sound node reference |
| `ReleaseButtonSound` | SandboxNode | Custom release sound node | Sound node reference |

---

## Button Events

| Event | Parameters | Description | Use Case |
|-------|-----------|-------------|----------|
| `Click` | `node, isClick, position, touchId` | Triggered when button is clicked | Primary button action |
| `TouchBegin` | `node, isTouchBegin, position, touchId` | Triggered when touch/click starts | Visual press feedback |
| `TouchEnd` | `node, isTouchEnd, position, touchId` | Triggered when touch/click ends | Visual release feedback |
| `RollOver` | `node, isOver, position` | Mouse enters button area | Hover effects (desktop) |
| `RollOut` | `node, isOut, position` | Mouse leaves button area | End hover effects |
| `TouchMove` | `node, isTouchMove, position, touchId` | Touch/mouse moves on button | Drag interactions |

### Complete Button Event Handling Example

```lua
local button = SandboxNode.new('UIButton', uiRoot)
button.Name = "InteractiveButton"
button.Position = Vector2.new(960, 540)
button.Size = Vector2.new(200, 60)
button.Title = "Press Me"
button.Visible = true

-- Main action
button.Click:Connect(function(node, isClick, position, touchId)
    print("Button activated!")
end)

-- Press feedback
button.TouchBegin:Connect(function(node, isTouchBegin, position, touchId)
    button.FillColor = ColorQuad.new(150, 150, 200, 255)  -- Darken
end)

-- Release feedback
button.TouchEnd:Connect(function(node, isTouchEnd, position, touchId)
    button.FillColor = ColorQuad.new(200, 200, 255, 255)  -- Restore
end)

-- Hover effects (desktop only)
button.RollOver:Connect(function(node, isOver, position)
    button.LineSize = 3  -- Thicker border
end)

button.RollOut:Connect(function(node, isOut, position)
    button.LineSize = 2  -- Normal border
end)
```

---

## Button Visual Enhancements

### Text Outline and Shadow

```lua
local button = SandboxNode.new('UIButton', uiRoot)
button.Name = "StyledButton"
button.Position = Vector2.new(960, 540)
button.Size = Vector2.new(200, 60)
button.Pivot = Vector2.new(0.5, 0.5)
button.Title = "Styled Button"
button.TitleSize = 24
button.TitleColor = ColorQuad.new(255, 255, 255, 255)
button.Visible = true

-- Add text outline
button.OutlineEnable = true
button.OutlineColor = ColorQuad.new(0, 0, 0, 255)  -- Black outline
button.OutlineSize = 2

-- Add text shadow
button.ShadowEnable = true
button.ShadowColor = ColorQuad.new(0, 0, 0, 128)  -- Semi-transparent black
button.ShadowOffset = Vector2.new(2, 2)
```

### Button Press Effects

```lua
-- Scale effect on press
button.DownEffect = Enum.ButtonDownEffect.ScaledEffect
button.DownEffectValue = 0.9  -- Scale to 90% when pressed

-- Color effect on press
button.DownEffect = Enum.ButtonDownEffect.ColorEffect
button.DownEffectValue = 0.8  -- Darken to 80% when pressed
```

### 9-Slice Scaling for Backgrounds

```lua
local button = SandboxNode.new('UIButton', uiRoot)
button.Icon = "sandboxSysId://UI/Backgrounds/panel.png"
button.ScaleType = 2  -- Slice mode
button.SliceCenter = Vector4.new(10, 10, 20, 20)  -- Left, Top, Right, Bottom margins
button.Visible = true
```

---

## Button Sound Effects

### Adding Sound Effects

```lua
local button = SandboxNode.new('UIButton', uiRoot)
button.Name = "SoundButton"
button.Position = Vector2.new(960, 540)
button.Size = Vector2.new(200, 60)
button.Title = "Click Me"
button.Visible = true

-- Create sound nodes
local pressSound = SandboxNode.new('SandboxSound')
pressSound.Name = "PressSound"
pressSound.SoundId = "sandboxSysId://Audio/button_press.mp3"
pressSound:SetParent(button)

local releaseSound = SandboxNode.new('SandboxSound')
releaseSound.Name = "ReleaseSound"
releaseSound.SoundId = "sandboxSysId://Audio/button_release.mp3"
releaseSound:SetParent(button)

-- Configure button sounds
button.IsEnableDefaultSound = false  -- Disable default sound
button.PressButtonSound = pressSound
button.ReleaseButtonSound = releaseSound
```

### Using SoundService for Button Sounds

```lua
local SoundService = game:GetService("SoundService")

-- Create UI sounds (2D, non-spatial)
local clickSound = SandboxNode.new('SandboxSound')
clickSound.Name = "ClickSound"
clickSound.SoundId = "sandboxSysId://Audio/UI/click.mp3"
clickSound.Volume = 0.7
clickSound.Is3D = false
clickSound:SetParent(uiRoot)

local hoverSound = SandboxNode.new('SandboxSound')
hoverSound.Name = "HoverSound"
hoverSound.SoundId = "sandboxSysId://Audio/UI/hover.mp3"
hoverSound.Volume = 0.5
hoverSound.Is3D = false
hoverSound:SetParent(uiRoot)

-- Create button with sound feedback
local soundButton = SandboxNode.new('UIButton', uiRoot)
soundButton.Name = "SoundButton"
soundButton.Position = Vector2.new(960, 540)
soundButton.Size = Vector2.new(200, 60)
soundButton.Title = "Play Sound"
soundButton.Visible = true

-- Play hover sound on mouse over
soundButton.RollOver:Connect(function()
    SoundService:PlayerLocalSound(hoverSound)
end)

-- Play click sound on button press
soundButton.Click:Connect(function()
    SoundService:PlayerLocalSound(clickSound)
    print("Button clicked with sound!")
end)
```

---

## Practical Examples

### Example 1: Menu Button with Hover Effect

```lua
local menuButton = SandboxNode.new('UIButton', uiRoot)
menuButton.Name = "PlayButton"
menuButton.Position = Vector2.new(960, 400)
menuButton.Size = Vector2.new(250, 60)
menuButton.Pivot = Vector2.new(0.5, 0.5)
menuButton.Title = "PLAY"
menuButton.TitleSize = 24
menuButton.TitleColor = ColorQuad.new(255, 255, 255, 255)
menuButton.FillColor = ColorQuad.new(50, 200, 50, 255)  -- Green
menuButton.LineColor = ColorQuad.new(30, 150, 30, 255)
menuButton.LineSize = 2
menuButton.Round = 5
menuButton.Visible = true

-- Store colors
local normalColor = ColorQuad.new(50, 200, 50, 255)
local hoverColor = ColorQuad.new(70, 220, 70, 255)

menuButton.RollOver:Connect(function()
    menuButton.FillColor = hoverColor
end)

menuButton.RollOut:Connect(function()
    menuButton.FillColor = normalColor
end)

menuButton.Click:Connect(function()
    print("Starting game...")
end)
```

### Example 2: Mobile Touch Button

```lua
-- Jump button for mobile
local jumpButton = SandboxNode.new('UIButton', uiRoot)
jumpButton.Name = "BtnJump"
jumpButton.Position = Vector2.new(1770, 920)  -- Bottom right
jumpButton.Size = Vector2.new(100, 100)
jumpButton.Pivot = Vector2.new(0.5, 0.5)
jumpButton.Icon = "sandboxSysId://ministudio/ui/jump_icon.png"
jumpButton.FillColor = ColorQuad.new(100, 200, 100, 150)
jumpButton.LineColor = ColorQuad.new(50, 150, 50, 255)
jumpButton.LineSize = 2
jumpButton.Round = 50  -- Circular
jumpButton.LayoutHRelation = 2  -- Right
jumpButton.LayoutVRelation = 2  -- Bottom
jumpButton.HRelationLength = -150
jumpButton.VRelationLength = -100
jumpButton.Visible = true

jumpButton.Click:Connect(function()
    if localPlayer and localPlayer.Character then
        localPlayer.Character:Jump(true)
        print("Player jumped!")
    end
end)
```

### Example 3: Animated Button with TweenService

```lua
local TweenService = game:GetService("TweenService")

local button = SandboxNode.new('UIButton', uiRoot)
button.Name = "AnimatedButton"
button.Position = Vector2.new(960, 540)
button.Size = Vector2.new(160, 50)
button.Pivot = Vector2.new(0.5, 0.5)
button.Title = "Hover Me"
button.TitleSize = 20
button.TitleColor = ColorQuad.new(255, 255, 255, 255)
button.FillColor = ColorQuad.new(70, 130, 180, 255)
button.Alpha = 1.0
button.Scale = Vector2.new(1.0, 1.0)
button.Visible = true

-- Hover animations
local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

button.RollOver:Connect(function()
    local hoverTween = TweenService:Create(button, hoverInfo, {
        Scale = Vector2.new(1.1, 1.1),
        FillColor = ColorQuad.new(100, 160, 210, 255)
    })
    hoverTween:Play()
end)

button.RollOut:Connect(function()
    local normalTween = TweenService:Create(button, hoverInfo, {
        Scale = Vector2.new(1.0, 1.0),
        FillColor = ColorQuad.new(70, 130, 180, 255)
    })
    normalTween:Play()
end)
```

### Example 4: Button with Visual Feedback

```lua
local button = SandboxNode.new('UIButton', uiRoot)
button.Name = "FeedbackButton"
button.Position = Vector2.new(960, 540)
button.Size = Vector2.new(200, 60)
button.Pivot = Vector2.new(0.5, 0.5)
button.Title = "Click Me"
button.TitleSize = 22
button.TitleColor = ColorQuad.new(255, 255, 255, 255)
button.FillColor = ColorQuad.new(100, 200, 100, 255)
button.Visible = true

-- Store color states
local normalColor = ColorQuad.new(100, 200, 100, 255)  -- Light green
local hoverColor = ColorQuad.new(120, 220, 120, 255)   -- Lighter green
local pressedColor = ColorQuad.new(50, 150, 50, 255)   -- Dark green

-- Hover effect
button.RollOver:Connect(function()
    button.FillColor = hoverColor
end)

button.RollOut:Connect(function()
    button.FillColor = normalColor
end)

-- Press effect
button.TouchBegin:Connect(function()
    button.FillColor = pressedColor
end)

-- Release effect
button.TouchEnd:Connect(function()
    button.FillColor = hoverColor  -- Back to hover color
end)

-- Click action
button.Click:Connect(function()
    print("Button clicked!")
end)
```

---

## Quick Reference

### Minimal Button (JSON)
```json
{
  "ClassType": "UIButton",
  "realNodeName": "MyButton",
  "reflex": [
    {"Name": "MyButton"},
    {"Size": [200, 60]},
    {"Title": "Click"},
    {"Visible": true}
  ]
}
```

### Minimal Button (Lua)
```lua
local btn = SandboxNode.new('UIButton', uiRoot)
btn.Position = Vector2.new(960, 540)
btn.Size = Vector2.new(200, 60)
btn.Title = "Click"
btn.Visible = true
btn.Click:Connect(function() print("Clicked!") end)
```

---

## See Also

- [Common UI Knowledge](common-ui.md) - Fundamental concepts, colors, runtime access
- [UI Layout System Guide](common-ui-layout.md) - Responsive positioning, layout patterns, multi-resolution support
- [How to Add TextLabel](how-to-add-textlabel.md)
- [How to Add Panel](how-to-add-panel.md)
- [How to Add Image](how-to-add-image.md)
