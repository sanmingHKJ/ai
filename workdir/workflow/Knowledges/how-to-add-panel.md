# How to Add UIPanel

📚 **Prerequisites**: Read [Common UI Knowledge](common-ui.md) first for fundamental UI concepts, color formats, layout patterns, and how to access UI at runtime.

## Overview

**UIPanel** is a container element for grouping UI elements, creating backgrounds, and organizing interface layouts. Panels support rounded corners, borders, and semi-transparent fills.

---

## Method 1: Static Addition (JSON Configuration)

### Basic Panel Template

```json
{
  "ClassType": "UIPanel",
  "attribute": [],
  "flags": 0,
  "realNodeName": "SettingsPanel",
  "reflex": [
    {"Name": "SettingsPanel"},
    {"Size": [400, 500]},
    {"Pivot": [0.5, 0.5]},
    {"FillColor": [50, 50, 50, 220]},
    {"LineColor": [100, 100, 100, 255]},
    {"LineSize": 2},
    {"Round": 10},
    {"Visible": false},
    {"RenderIndex": 10},
    {"LayoutHRelation": 1},
    {"LayoutVRelation": 1},
    {"HRelationLength": 0},
    {"VRelationLength": 0}
  ]
}
```

---

## Method 2: Dynamic Addition (Lua Scripting)

### Basic Panel Creation

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Name = "SettingsPanel"
panel.Position = Vector2.new(960, 540)
panel.Size = Vector2.new(400, 500)
panel.Pivot = Vector2.new(0.5, 0.5)
panel.FillColor = ColorQuad.new(50, 50, 50, 220)  -- Semi-transparent dark
panel.LineColor = ColorQuad.new(100, 100, 100, 255)
panel.LineSize = 2
panel.Round = 10  -- Rounded corners
panel.Visible = false  -- Hidden by default
panel.RenderIndex = 10

-- Function to toggle panel
function TogglePanel()
    panel.Visible = not panel.Visible
end
```

---

## Panel-Specific Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `FillColor` | `[r,g,b,a]` | Panel background color | `[50, 50, 50, 220]` |
| `LineColor` | `[r,g,b,a]` | Panel border color | `[100, 100, 100, 255]` |
| `LineSize` | number | Border thickness (pixels) | `2` |
| `Round` | number | Corner radius (pixels) | `10` |

### Round Property (Corner Radius)

- `Round = 0` - Sharp corners (square)
- `Round = 5` - Slightly rounded
- `Round = 10` - Moderately rounded
- `Round = 20+` - Very rounded (pill shape for certain sizes)

---

## Practical Examples

### Example 1: Menu Background Panel

```lua
local menuPanel = SandboxNode.new('UIPanel', uiRoot)
menuPanel.Name = "MenuBackground"
menuPanel.Position = Vector2.new(960, 540)
menuPanel.Size = Vector2.new(600, 400)
menuPanel.Pivot = Vector2.new(0.5, 0.5)
menuPanel.FillColor = ColorQuad.new(30, 30, 40, 230)
menuPanel.LineColor = ColorQuad.new(80, 80, 100, 255)
menuPanel.LineSize = 3
menuPanel.Round = 15
menuPanel.Visible = true
menuPanel.LayoutHRelation = 1  -- Center H
menuPanel.LayoutVRelation = 1  -- Center V
menuPanel.RenderIndex = 5

-- Add title to panel
local titleLabel = SandboxNode.new('UITextLabel', menuPanel)
titleLabel.Name = "Title"
titleLabel.Position = Vector2.new(300, 50)
titleLabel.Size = Vector2.new(500, 60)
titleLabel.Pivot = Vector2.new(0.5, 0.5)
titleLabel.Title = "GAME MENU"
titleLabel.FontSize = 36
titleLabel.TitleColor = ColorQuad.new(255, 215, 0, 255)  -- Gold
titleLabel.TextHAlignment = 1  -- Center
titleLabel.TextVAlignment = 1
titleLabel.Visible = true
```

### Example 2: Settings Panel with Close Button

```lua
local settingsPanel = SandboxNode.new('UIPanel', uiRoot)
settingsPanel.Name = "SettingsPanel"
settingsPanel.Position = Vector2.new(960, 540)
settingsPanel.Size = Vector2.new(500, 600)
settingsPanel.Pivot = Vector2.new(0.5, 0.5)
settingsPanel.FillColor = ColorQuad.new(40, 40, 50, 240)
settingsPanel.LineColor = ColorQuad.new(100, 100, 120, 255)
settingsPanel.LineSize = 2
settingsPanel.Round = 12
settingsPanel.Visible = false
settingsPanel.RenderIndex = 20

-- Title bar
local titleBar = SandboxNode.new('UIPanel', settingsPanel)
titleBar.Name = "TitleBar"
titleBar.Position = Vector2.new(0, 0)
titleBar.Size = Vector2.new(500, 60)
titleBar.Pivot = Vector2.new(0, 0)
titleBar.FillColor = ColorQuad.new(60, 60, 80, 255)
titleBar.LineColor = ColorQuad.new(0, 0, 0, 0)
titleBar.LineSize = 0
titleBar.Round = 12  -- Match parent
titleBar.Visible = true

-- Title text
local titleText = SandboxNode.new('UITextLabel', titleBar)
titleText.Position = Vector2.new(250, 30)
titleText.Size = Vector2.new(400, 40)
titleText.Pivot = Vector2.new(0.5, 0.5)
titleText.Title = "Settings"
titleText.FontSize = 28
titleText.TitleColor = ColorQuad.new(255, 255, 255, 255)
titleText.TextHAlignment = 1
titleText.TextVAlignment = 1
titleText.Visible = true

-- Close button
local closeButton = SandboxNode.new('UIButton', titleBar)
closeButton.Name = "CloseButton"
closeButton.Position = Vector2.new(460, 30)
closeButton.Size = Vector2.new(30, 30)
closeButton.Pivot = Vector2.new(0.5, 0.5)
closeButton.Title = "X"
closeButton.TitleSize = 20
closeButton.TitleColor = ColorQuad.new(255, 255, 255, 255)
closeButton.FillColor = ColorQuad.new(200, 50, 50, 255)
closeButton.LineColor = ColorQuad.new(150, 30, 30, 255)
closeButton.LineSize = 1
closeButton.Round = 5
closeButton.Visible = true

closeButton.Click:Connect(function()
    settingsPanel.Visible = false
end)

-- Function to show settings
function ShowSettings()
    settingsPanel.Visible = true
end
```

### Example 3: Inventory Slot Panel

```lua
local slotPanel = SandboxNode.new('UIPanel', uiRoot)
slotPanel.Name = "InventorySlot"
slotPanel.Position = Vector2.new(100, 100)
slotPanel.Size = Vector2.new(80, 80)
slotPanel.Pivot = Vector2.new(0, 0)
slotPanel.FillColor = ColorQuad.new(60, 60, 70, 200)
slotPanel.LineColor = ColorQuad.new(120, 120, 140, 255)
slotPanel.LineSize = 2
slotPanel.Round = 8
slotPanel.Visible = true

-- Item icon
local itemIcon = SandboxNode.new('UIImage', slotPanel)
itemIcon.Name = "ItemIcon"
itemIcon.Position = Vector2.new(40, 40)
itemIcon.Size = Vector2.new(60, 60)
itemIcon.Pivot = Vector2.new(0.5, 0.5)
itemIcon.Icon = "sandboxSysId://UI/Items/sword.png"
itemIcon.ScaleType = 2
itemIcon.Visible = false  -- Hidden until item is placed
```

### Example 4: Notification Panel

```lua
local notificationPanel = SandboxNode.new('UIPanel', uiRoot)
notificationPanel.Name = "Notification"
notificationPanel.Position = Vector2.new(960, -100)  -- Start off-screen
notificationPanel.Size = Vector2.new(400, 80)
notificationPanel.Pivot = Vector2.new(0.5, 0)
notificationPanel.FillColor = ColorQuad.new(70, 140, 70, 240)  -- Green
notificationPanel.LineColor = ColorQuad.new(50, 120, 50, 255)
notificationPanel.LineSize = 2
notificationPanel.Round = 10
notificationPanel.Visible = false
notificationPanel.RenderIndex = 100

-- Notification text
local notificationText = SandboxNode.new('UITextLabel', notificationPanel)
notificationText.Position = Vector2.new(200, 40)
notificationText.Size = Vector2.new(360, 60)
notificationText.Pivot = Vector2.new(0.5, 0.5)
notificationText.Title = "Achievement Unlocked!"
notificationText.FontSize = 22
notificationText.TitleColor = ColorQuad.new(255, 255, 255, 255)
notificationText.TextHAlignment = 1
notificationText.TextVAlignment = 1
notificationText.Visible = true

-- Show notification with animation
function ShowNotification(message)
    notificationText.Title = message
    notificationPanel.Visible = true

    local TweenService = game:GetService("TweenService")

    -- Slide in
    local slideInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local slideInTween = TweenService:Create(notificationPanel, slideInInfo, {
        Position = Vector2.new(960, 50)
    })
    slideInTween:Play()

    -- Wait and slide out
    wait(3)
    local slideOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local slideOutTween = TweenService:Create(notificationPanel, slideOutInfo, {
        Position = Vector2.new(960, -100)
    })
    slideOutTween:Play()

    slideOutTween.Completed:Connect(function()
        notificationPanel.Visible = false
    end)
end
```

### Example 5: Health Bar Background Panel

```lua
local healthBG = SandboxNode.new('UIPanel', uiRoot)
healthBG.Name = "HealthBG"
healthBG.Position = Vector2.new(50, 50)
healthBG.Size = Vector2.new(304, 34)
healthBG.Pivot = Vector2.new(0, 0)
healthBG.FillColor = ColorQuad.new(40, 40, 40, 200)
healthBG.LineColor = ColorQuad.new(0, 0, 0, 255)
healthBG.LineSize = 2
healthBG.Round = 5
healthBG.Visible = true

-- Add health bar inside
local healthBar = SandboxNode.new('UIProgressBar', healthBG)
healthBar.Name = "HealthBar"
healthBar.Position = Vector2.new(2, 2)
healthBar.Size = Vector2.new(300, 30)
healthBar.MinValue = 0
healthBar.MaxValue = 100
healthBar.Value = 100
healthBar.ForegroundColor = ColorQuad.new(0, 255, 0, 255)
healthBar.BackgroundColor = ColorQuad.new(80, 80, 80, 255)
healthBar.Visible = true
```

### Example 6: Tooltip Panel

```lua
local tooltipPanel = SandboxNode.new('UIPanel', uiRoot)
tooltipPanel.Name = "Tooltip"
tooltipPanel.Position = Vector2.new(0, 0)  -- Will be positioned dynamically
tooltipPanel.Size = Vector2.new(250, 80)
tooltipPanel.Pivot = Vector2.new(0, 1)  -- Bottom-left anchor
tooltipPanel.FillColor = ColorQuad.new(20, 20, 20, 240)
tooltipPanel.LineColor = ColorQuad.new(200, 200, 200, 255)
tooltipPanel.LineSize = 1
tooltipPanel.Round = 6
tooltipPanel.Visible = false
tooltipPanel.RenderIndex = 999  -- Always on top

-- Tooltip text
local tooltipText = SandboxNode.new('UITextLabel', tooltipPanel)
tooltipText.Position = Vector2.new(125, 40)
tooltipText.Size = Vector2.new(240, 70)
tooltipText.Pivot = Vector2.new(0.5, 0.5)
tooltipText.Title = "Tooltip text"
tooltipText.FontSize = 16
tooltipText.TitleColor = ColorQuad.new(255, 255, 255, 255)
tooltipText.TextHAlignment = 1
tooltipText.TextVAlignment = 1
tooltipText.Visible = true

-- Show tooltip at mouse position
function ShowTooltip(text, mouseX, mouseY)
    tooltipText.Title = text
    tooltipPanel.Position = Vector2.new(mouseX, mouseY)
    tooltipPanel.Visible = true
end

function HideTooltip()
    tooltipPanel.Visible = false
end
```

### Example 7: Loading Screen Panel

```lua
local loadingScreen = SandboxNode.new('UIPanel', uiRoot)
loadingScreen.Name = "LoadingScreen"
loadingScreen.Position = Vector2.new(960, 540)
loadingScreen.Size = Vector2.new(1920, 1080)
loadingScreen.Pivot = Vector2.new(0.5, 0.5)
loadingScreen.FillColor = ColorQuad.new(0, 0, 0, 230)
loadingScreen.LineColor = ColorQuad.new(0, 0, 0, 0)
loadingScreen.LineSize = 0
loadingScreen.Round = 0
loadingScreen.Visible = false
loadingScreen.RenderIndex = 1000  -- Always on top
loadingScreen.LayoutHRelation = 1  -- Center H
loadingScreen.LayoutVRelation = 1  -- Center V

-- Loading text
local loadingText = SandboxNode.new('UITextLabel', loadingScreen)
loadingText.Position = Vector2.new(960, 540)
loadingText.Size = Vector2.new(600, 60)
loadingText.Pivot = Vector2.new(0.5, 0.5)
loadingText.Title = "Loading..."
loadingText.FontSize = 36
loadingText.TitleColor = ColorQuad.new(255, 255, 255, 255)
loadingText.TextHAlignment = 1
loadingText.TextVAlignment = 1
loadingText.Visible = true

-- Show/hide loading screen
function ShowLoadingScreen()
    loadingScreen.Visible = true
end

function HideLoadingScreen()
    loadingScreen.Visible = false
end
```

---

## Quick Reference

### Minimal Panel (JSON)
```json
{
  "ClassType": "UIPanel",
  "realNodeName": "MyPanel",
  "reflex": [
    {"Name": "MyPanel"},
    {"Size": [400, 300]},
    {"FillColor": [50, 50, 50, 220]},
    {"LineColor": [100, 100, 100, 255]},
    {"LineSize": 2},
    {"Round": 10},
    {"Visible": true},
    {"LayoutHRelation": 1},
    {"LayoutVRelation": 1},
    {"HRelationLength": 0},
    {"VRelationLength": 0}
  ]
}
```

### Minimal Panel (Lua)
```lua
local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Position = Vector2.new(960, 540)
panel.Size = Vector2.new(400, 300)
panel.FillColor = ColorQuad.new(50, 50, 50, 220)
panel.LineColor = ColorQuad.new(100, 100, 100, 255)
panel.LineSize = 2
panel.Round = 10
panel.Visible = true
```

---

## Common Panel Patterns

**For detailed layout positioning patterns, see [UI Layout System Guide](common-ui-layout.md).**

### Menu Background Panel (Centered)
```lua
panel.FillColor = ColorQuad.new(30, 30, 40, 230)  -- Dark semi-transparent
panel.LineColor = ColorQuad.new(80, 80, 100, 255)
panel.Round = 15  -- Rounded corners
panel.LayoutHRelation = 1  -- Center H (see layout guide for details)
panel.LayoutVRelation = 1  -- Center V
```

### HUD Panel (Edge-Anchored)
```lua
panel.FillColor = ColorQuad.new(40, 40, 40, 200)
panel.LineColor = ColorQuad.new(0, 0, 0, 255)
panel.Round = 5  -- Slight rounding
panel.LayoutHRelation = 0  -- Left edge (or 2 for right edge)
```

### Full-Screen Overlay Panel
```lua
panel.Size = Vector2.new(1920, 1080)
panel.FillColor = ColorQuad.new(0, 0, 0, 180)  -- Semi-transparent black
panel.LineSize = 0  -- No border
panel.Round = 0  -- No rounding
panel.RenderIndex = 1000  -- Always on top
```

---

## 🚨 CRITICAL: Adding Children to Panels

### The Layout Properties Requirement

⚠️ **CRITICAL REQUIREMENT**: When adding child elements inside a panel (in JSON), you **MUST** include layout relation properties for the child elements to position correctly.

**Without these properties, child elements will not display or will overlap at [0,0].**

### Required Properties for Child Elements

Every child element inside a panel **MUST** have these properties in its JSON `reflex` array:

```json
{
  "LayoutHRelation": 0,     // 0=left, 1=center, 2=right of parent
  "LayoutVRelation": 0,     // 0=top, 1=center, 2=bottom of parent
  "HRelationLength": 10,    // Horizontal offset in pixels
  "VRelationLength": 20     // Vertical offset in pixels
}
```

### Complete Example: Panel with Children (JSON)

**Panel JSON** (`MyPanel.json`):
```json
{
  "ClassType": "UIPanel",
  "realNodeName": "MyPanel",
  "reflex": [
    {"Name": "MyPanel"},
    {"Size": [300, 200]},
    {"Pivot": [0, 0]},
    {"FillColor": [40, 40, 50, 220]},
    {"LineColor": [100, 100, 120, 255]},
    {"LineSize": 2},
    {"Round": 10},
    {"Visible": true},
    {"RenderIndex": 10},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 10},
    {"VRelationLength": 90}
  ]
}
```

**Child Label JSON** (`MyPanel/TitleLabel.json`):
```json
{
  "ClassType": "UITextLabel",
  "realNodeName": "TitleLabel",
  "reflex": [
    {"Name": "TitleLabel"},
    {"Position": [150, 30]},
    {"Size": [280, 40]},
    {"Pivot": [0.5, 0.5]},
    {"Title": "Panel Title"},
    {"FontSize": 24},
    {"TitleColor": [255, 215, 0, 255]},
    {"TextHAlignment": 1},
    {"TextVAlignment": 1},
    {"Visible": true},
    {"RenderIndex": 1},
    {"LayoutHRelation": 0},      // ⚠️ REQUIRED for child!
    {"LayoutVRelation": 0},      // ⚠️ REQUIRED for child!
    {"HRelationLength": 150},    // ⚠️ REQUIRED for child!
    {"VRelationLength": 30}      // ⚠️ REQUIRED for child!
  ]
}
```

**Directory Structure**:
```
StarterGui/DefaultUIMain/
├── MyPanel.json
└── MyPanel/
    ├── childrenIndex          # Defines child positions
    └── TitleLabel.json        # Child element with layout properties
```

**childrenIndex file**:
```
TitleLabel	[150, 30]	childrenEnd	0	1	0	0
```

### Complete Example: Panel with Children (Lua)

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

-- Create parent panel
local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Name = "MyPanel"
panel.Position = Vector2.new(10, 90)
panel.Size = Vector2.new(300, 200)
panel.Pivot = Vector2.new(0, 0)
panel.FillColor = ColorQuad.new(40, 40, 50, 220)
panel.LineColor = ColorQuad.new(100, 100, 120, 255)
panel.LineSize = 2
panel.Round = 10
panel.Visible = true
panel.RenderIndex = 10

-- Create child label INSIDE the panel
local titleLabel = SandboxNode.new('UITextLabel', panel)  -- Parent is panel!
titleLabel.Name = "TitleLabel"
titleLabel.Position = Vector2.new(150, 30)  -- Relative to panel's top-left!
titleLabel.Size = Vector2.new(280, 40)
titleLabel.Pivot = Vector2.new(0.5, 0.5)
titleLabel.Title = "Panel Title"
titleLabel.FontSize = 24
titleLabel.TitleColor = ColorQuad.new(255, 215, 0, 255)
titleLabel.TextHAlignment = 1
titleLabel.TextVAlignment = 1
titleLabel.Visible = true
titleLabel.RenderIndex = 1

-- ⚠️ CRITICAL: In Lua, child coordinates are automatically parent-relative
-- No layout relation properties needed in Lua (only for JSON)
```

### Key Differences: JSON vs Lua

| Aspect | JSON Configuration | Lua Scripting |
|--------|-------------------|---------------|
| **Layout Properties** | ⚠️ **REQUIRED** for children | ✅ Not needed (automatic) |
| **Position** | Relative to parent | Relative to parent |
| **Parent Reference** | Directory structure | `SandboxNode.new('Type', parent)` |
| **childrenIndex** | Required | Not needed |

### Common Mistakes

❌ **Mistake 1: Missing layout properties in JSON**
```json
{
  "ClassType": "UITextLabel",
  "realNodeName": "Label",
  "reflex": [
    {"Name": "Label"},
    {"Position": [10, 10]},
    {"Size": [100, 30]},
    {"Title": "Text"},
    {"Visible": true}
    // ❌ MISSING: LayoutHRelation, LayoutVRelation, HRelationLength, VRelationLength
  ]
}
```
**Result**: Label will not display or will appear at [0,0]!

✅ **Correct: Include all layout properties**
```json
{
  "ClassType": "UITextLabel",
  "realNodeName": "Label",
  "reflex": [
    {"Name": "Label"},
    {"Position": [10, 10]},
    {"Size": [100, 30]},
    {"Title": "Text"},
    {"Visible": true},
    {"LayoutHRelation": 0},       // ✅ Added
    {"LayoutVRelation": 0},       // ✅ Added
    {"HRelationLength": 10},      // ✅ Added
    {"VRelationLength": 10}       // ✅ Added
  ]
}
```

❌ **Mistake 2: Using screen coordinates for children**
```lua
-- Panel at screen position [10, 90]
local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Position = Vector2.new(10, 90)

-- ❌ WRONG: Using screen coordinates for child
local label = SandboxNode.new('UITextLabel', panel)
label.Position = Vector2.new(135, 115)  -- This is 135px from panel's left, not screen!

-- ✅ CORRECT: Use parent-relative coordinates
label.Position = Vector2.new(125, 25)   -- 125px from panel's left edge
```

### Best Practices

✅ **Always add layout properties to JSON child elements**
✅ **Use parent-relative coordinates for all children**
✅ **Verify child positions stay within parent bounds**
✅ **Create childrenIndex file when adding children in JSON**
✅ **Test UI after adding children to verify positioning**

---

## Important Notes

⚠️ **Access from PlayerGui**: Remember to access UI from `game.Players.LocalPlayer.PlayerGui` at runtime, not from StarterGui
✅ **Container for Other Elements**: Panels are excellent containers - add child elements to organize UI
✅ **Semi-transparency**: Use alpha channel (4th value in color) for semi-transparent backgrounds (e.g., 220 instead of 255)
✅ **Rounded Corners**: Use `Round` property for modern UI appearance
✅ **RenderIndex**: Set higher `RenderIndex` for panels that should appear in front (e.g., popup menus)
✅ **Layout Relations**: Use layout relations for responsive panel positioning
✅ **No Border**: Set `LineSize = 0` to remove panel border completely

---

## See Also

- [Common UI Knowledge](common-ui.md) - Fundamental concepts, colors, runtime access
- [UI Layout System Guide](common-ui-layout.md) - Responsive positioning, layout patterns, multi-resolution support
- [How to Add Button](how-to-add-button.md)
- [How to Add TextLabel](how-to-add-textlabel.md)
- [How to Add ProgressBar](how-to-add-progressbar.md)
