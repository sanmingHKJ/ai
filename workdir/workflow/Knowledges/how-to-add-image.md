# How to Add UIImage

📚 **Prerequisites**: Read [Common UI Knowledge](common-ui.md) first for fundamental UI concepts, color formats, layout patterns, and how to access UI at runtime.

## Overview

**UIImage** displays image assets for icons, logos, backgrounds, and visual elements. Images support various scaling modes and can be tinted with colors.

---

## Method 1: Static Addition (JSON Configuration)

### Basic Image Template

```json
{
  "ClassType": "UIImage",
  "attribute": [],
  "flags": 0,
  "realNodeName": "GameLogo",
  "reflex": [
    {"Name": "GameLogo"},
    {"Size": [300, 150]},
    {"Pivot": [0.5, 0.5]},
    {"Icon": "sandboxSysId://UI/Images/game_logo.png"},
    {"Alpha": 1.0},
    {"ScaleType": 1},
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

### Basic Image Creation

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

local image = SandboxNode.new('UIImage', uiRoot)
image.Name = "Logo"
image.Position = Vector2.new(960, 100)
image.Size = Vector2.new(300, 150)
image.Pivot = Vector2.new(0.5, 0.5)
image.Icon = "sandboxSysId://UI/Images/logo.png"
image.Alpha = 1.0
image.ScaleType = 1  -- Keep aspect ratio
image.Visible = true
```

---

## Image-Specific Properties

| Property | Type | Description | Values |
|----------|------|-------------|--------|
| `Icon` | string | Image resource path | `"sandboxSysId://UI/Images/image.png"` |
| `Alpha` | number | Image transparency (0-1) | `1.0` = opaque, `0.0` = transparent |
| `ScaleType` | number | Image scaling mode | `1` = stretch, `2` = keep aspect ratio |

### ScaleType Values

- **1 = Stretch**: Image stretches to fill the size (may distort)
- **2 = Keep Aspect Ratio**: Image maintains proportions (may have borders)

---

## Practical Examples

### Example 1: Centered Logo

```lua
local logo = SandboxNode.new('UIImage', uiRoot)
logo.Name = "GameLogo"
logo.Position = Vector2.new(960, 100)
logo.Size = Vector2.new(400, 200)
logo.Pivot = Vector2.new(0.5, 0.5)  -- Center anchor
logo.Icon = "sandboxSysId://UI/Images/game_logo.png"
logo.Alpha = 1.0
logo.ScaleType = 2  -- Keep aspect ratio
logo.Visible = true
logo.LayoutHRelation = 1  -- Center horizontal
logo.LayoutVRelation = 0  -- Top
logo.VRelationLength = 50
```

### Example 2: HUD Icon

```lua
local healthIcon = SandboxNode.new('UIImage', uiRoot)
healthIcon.Name = "HealthIcon"
healthIcon.Position = Vector2.new(20, 20)
healthIcon.Size = Vector2.new(40, 40)
healthIcon.Pivot = Vector2.new(0, 0)  -- Top-left
healthIcon.Icon = "sandboxSysId://UI/Icons/heart.png"
healthIcon.Alpha = 1.0
healthIcon.ScaleType = 2  -- Keep aspect ratio
healthIcon.Visible = true
healthIcon.LayoutHRelation = 0  -- Left
healthIcon.LayoutVRelation = 0  -- Top
healthIcon.HRelationLength = 20
healthIcon.VRelationLength = 20
```

### Example 3: Background Image

```lua
local background = SandboxNode.new('UIImage', uiRoot)
background.Name = "MenuBackground"
background.Position = Vector2.new(960, 540)
background.Size = Vector2.new(1920, 1080)
background.Pivot = Vector2.new(0.5, 0.5)  -- Center
background.Icon = "sandboxSysId://UI/Backgrounds/menu_bg.png"
background.Alpha = 0.8  -- Semi-transparent
background.ScaleType = 1  -- Stretch to fill
background.Visible = true
background.RenderIndex = 0  -- Behind other elements
background.LayoutHRelation = 1  -- Center H
background.LayoutVRelation = 1  -- Center V
```

### Example 4: Avatar/Character Portrait

```lua
local avatar = SandboxNode.new('UIImage', uiRoot)
avatar.Name = "PlayerAvatar"
avatar.Position = Vector2.new(50, 50)
avatar.Size = Vector2.new(100, 100)
avatar.Pivot = Vector2.new(0, 0)
avatar.Icon = "sandboxSysId://UI/Avatars/player_portrait.png"
avatar.Alpha = 1.0
avatar.ScaleType = 2  -- Keep aspect ratio
avatar.Visible = true
```

### Example 5: Animated Icon with Fade

```lua
local TweenService = game:GetService("TweenService")

local icon = SandboxNode.new('UIImage', uiRoot)
icon.Name = "NotificationIcon"
icon.Position = Vector2.new(960, 540)
icon.Size = Vector2.new(80, 80)
icon.Pivot = Vector2.new(0.5, 0.5)
icon.Icon = "sandboxSysId://UI/Icons/notification.png"
icon.Alpha = 0.0  -- Start invisible
icon.ScaleType = 2
icon.Visible = true

-- Fade in animation
local fadeInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeInTween = TweenService:Create(icon, fadeInInfo, {Alpha = 1.0})
fadeInTween:Play()
```

### Example 6: Item Icon in Inventory Slot

```lua
local itemIcon = SandboxNode.new('UIImage', inventorySlotPanel)
itemIcon.Name = "ItemIcon"
itemIcon.Position = Vector2.new(50, 50)  -- Centered in slot
itemIcon.Size = Vector2.new(60, 60)
itemIcon.Pivot = Vector2.new(0.5, 0.5)
itemIcon.Icon = "sandboxSysId://UI/Items/sword.png"
itemIcon.Alpha = 1.0
itemIcon.ScaleType = 2  -- Keep aspect ratio
itemIcon.Visible = true

-- Function to change item
function SetItem(itemIconPath)
    itemIcon.Icon = itemIconPath
end
```

### Example 7: Loading Spinner

```lua
local spinner = SandboxNode.new('UIImage', uiRoot)
spinner.Name = "LoadingSpinner"
spinner.Position = Vector2.new(960, 540)
spinner.Size = Vector2.new(100, 100)
spinner.Pivot = Vector2.new(0.5, 0.5)
spinner.Icon = "sandboxSysId://UI/Icons/spinner.png"
spinner.Alpha = 1.0
spinner.ScaleType = 2
spinner.Visible = false  -- Hidden until needed
spinner.RenderIndex = 999  -- Always on top

-- Show loading spinner
function ShowLoading()
    spinner.Visible = true
    -- Add rotation animation here if needed
end

function HideLoading()
    spinner.Visible = false
end
```

---

## Image Resource Paths

Images use the `sandboxSysId://` URI scheme to reference game assets:

```lua
-- UI Images
image.Icon = "sandboxSysId://UI/Images/logo.png"

-- Icons
image.Icon = "sandboxSysId://UI/Icons/star.png"

-- Backgrounds
image.Icon = "sandboxSysId://UI/Backgrounds/menu_bg.png"

-- Item images
image.Icon = "sandboxSysId://UI/Items/sword.png"
```

---

## Quick Reference

### Minimal Image (JSON)
```json
{
  "ClassType": "UIImage",
  "realNodeName": "MyImage",
  "reflex": [
    {"Name": "MyImage"},
    {"Size": [200, 200]},
    {"Icon": "sandboxSysId://UI/Images/image.png"},
    {"Visible": true},
    {"LayoutHRelation": 1},
    {"LayoutVRelation": 1},
    {"HRelationLength": 0},
    {"VRelationLength": 0}
  ]
}
```

### Minimal Image (Lua)
```lua
local img = SandboxNode.new('UIImage', uiRoot)
img.Position = Vector2.new(960, 540)
img.Size = Vector2.new(200, 200)
img.Icon = "sandboxSysId://UI/Images/image.png"
img.Visible = true
```

---

## Important Notes

⚠️ **Access from PlayerGui**: Remember to access UI from `game.Players.LocalPlayer.PlayerGui` at runtime, not from StarterGui
✅ **Alpha for Transparency**: Use the `Alpha` property (0-1) to control image transparency
✅ **ScaleType**: Use `ScaleType = 2` to maintain aspect ratio and prevent distortion
✅ **RenderIndex**: Set lower `RenderIndex` for background images, higher for foreground elements
✅ **Resource Paths**: Always use the `sandboxSysId://` scheme for image paths

---

## See Also

- [Common UI Knowledge](common-ui.md) - Fundamental concepts, colors, runtime access
- [UI Layout System Guide](common-ui-layout.md) - Responsive positioning, layout patterns, multi-resolution support
- [How to Add Button](how-to-add-button.md)
- [How to Add Panel](how-to-add-panel.md)
- [How to Add TextLabel](how-to-add-textlabel.md)
