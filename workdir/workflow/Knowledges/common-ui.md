# Common UI Knowledge for MiniWorld Studio

## Overview

Fundamental UI concepts for MiniWorld Studio. **Read this first** before working with specific UI elements.

**Key Difference from Roblox**: MiniWorld Studio uses **Vector2 absolute pixel coordinates** instead of UDim2.

**Common Use Cases**: HUD elements (health, score), menus, buttons, text displays, progress bars, input fields, mobile touch controls

---

## UI Hierarchy and Structure

### Basic Hierarchy

All UI elements must be organized within the StarterGui service:

```
ServiceNodes/
└── StarterGui.json                  # Root UI service
    ├── DefaultUIMain/               # Main HUD container (UIRoot)
    │   ├── Button1.json            # UI elements as children
    │   ├── ScoreLabel.json
    │   └── ...
    ├── TouchUIMain/                # Mobile touch controls (UIRoot)
    │   ├── Rocker.json
    │   ├── BtnJump.json
    │   └── ...
    └── LoadingUIMain/              # Loading screen (UIRoot)
        ├── Background.json
        └── ProgressBar.json
```

### StarterGui Configuration

StarterGui controls global UI settings:

```json
{
  "ClassType": "StarterGui",
  "attribute": [],
  "flags": 0,
  "realNodeName": "StarterGui",
  "reflex": [
    {"ChatFrameVisible": true},
    {"RockerZoneVisible": false},
    {"RockerFixed": false},
    {"RockerFixPosition": [120, 600]},
    {"WalkZone": 1},
    {"InactiveAlpha": 1}
  ]
}
```

**Key StarterGui Properties:**

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `ChatFrameVisible` | boolean | Show/hide chat interface | `true` |
| `RockerZoneVisible` | boolean | Show/hide virtual joystick zone | `false` |
| `RockerFixed` | boolean | Fixed or dynamic joystick position | `false` |
| `RockerFixPosition` | `[x, y]` | Fixed joystick position (pixels) | `[120, 600]` |
| `WalkZone` | number | Walking zone mode | `1` |

### UIRoot Container

UIRoot serves as a container for groups of UI elements:

```json
{
  "ClassType": "UIRoot",
  "attribute": [],
  "flags": 0,
  "realNodeName": "DefaultUIMain",
  "reflex": [
    {"Name": "DefaultUIMain"},
    {"Visible": true},
    {"RenderIndex": 999},
    {"Locked": false}
  ]
}
```

**In Lua:**
```lua
local uiRoot = SandboxNode.new('UIRoot', WorkSpace)
uiRoot.Name = 'MainUI'
uiRoot.Visible = true
uiRoot.RenderIndex = 1
```

---

## 🚨 CRITICAL CONCEPT: UI Definition vs Runtime Instantiation

**This is essential knowledge for accessing UI elements in Lua scripts!**

### Where UI Lives: Definition vs Runtime

MiniWorld Studio has a two-stage UI system that confuses many developers:

#### 1. **UI Definition (JSON Files)** - Where You Create UI

UI elements are **defined** in `ServiceNodes/StarterGui/`:

```
ServiceNodes/
└── StarterGui.json                  # UI Definition Location
    └── DefaultUIMain.json           # Defined here as JSON
        └── JumpButton.json          # Defined here as JSON
```

**Purpose**: These JSON files define the UI structure, properties, and hierarchy.

#### 2. **UI Runtime Instantiation** - Where UI Actually Exists During Gameplay

When the game runs, UI elements are **automatically copied/instantiated** into each player's `PlayerGui`:

```
Runtime Player Hierarchy:
game.Players.LocalPlayer
    └── PlayerGui                    # UI Runtime Location (per player)
        └── DefaultUIMain            # Instantiated here during gameplay
            └── JumpButton           # Actually exists here at runtime
```

**Purpose**: PlayerGui is where each player's UI instance lives, allowing per-player UI customization.

### ⚠️ Critical Rule for Lua Scripts

**When accessing UI elements in Lua scripts, you MUST find them in `PlayerGui`, NOT in `StarterGui`!**

#### ❌ WRONG - Looking in StarterGui
```lua
local StarterGui = game:GetService("StarterGui")
local button = StarterGui:FindFirstChild("DefaultUIMain", true)  -- Will NOT find it!
```

#### ✅ CORRECT - Looking in PlayerGui
```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local defaultUIMain = playerGui:FindFirstChild("DefaultUIMain", true)  -- Finds instantiated UI
local jumpButton = defaultUIMain:FindFirstChild("JumpButton", true)
```

### Why This Two-Stage System Exists

1. **Separation of Concerns**: JSON files define the UI structure (like a blueprint), while PlayerGui contains each player's actual running instances
2. **Per-Player UI**: Each player gets their own PlayerGui instance, allowing different UI states for different players
3. **Replication**: StarterGui acts as a template that is instantiated for each player when they join
4. **Performance**: UI is instantiated only when needed during gameplay
5. **Multiplayer Support**: Each player can have customized UI without affecting others

### Key Takeaways

✅ **Define UI**: Create JSON files in `ServiceNodes/StarterGui/`
✅ **Access UI**: Find UI elements in `game.Players.LocalPlayer.PlayerGui` at runtime using Lua
✅ **Wait for Instantiation**: Add a small wait (1-2 seconds) before accessing UI to ensure it's instantiated
✅ **Use FindFirstChild**: Use `FindFirstChild(name, true)` to search recursively in PlayerGui
✅ **Per-Player**: Remember that each player has their own PlayerGui instance

---

## 🎨 Working with Colors

### Color Format: JSON vs Lua

MiniWorld Studio uses **different color formats** depending on whether you're defining UI in JSON files or creating/modifying UI via Lua scripts.

#### JSON Format (Static Definition)

In JSON files, colors are defined as **arrays with RGBA values (0-255)**:

```json
{
  "TitleColor": [255, 255, 255, 255],  // White (R, G, B, A)
  "FillColor": [100, 200, 100, 255],   // Light green
  "LineColor": [50, 150, 50, 255]      // Dark green
}
```

#### Lua Format (Runtime Modification)

In Lua scripts, you **MUST use `ColorQuad.new(r, g, b, a)`**:

```lua
-- ✅ CORRECT: Use ColorQuad.new()
button.TitleColor = ColorQuad.new(255, 255, 255, 255)  -- White
button.FillColor = ColorQuad.new(100, 200, 100, 255)   -- Light green
button.LineColor = ColorQuad.new(50, 150, 50, 255)     -- Dark green

-- ❌ WRONG: Using Lua table will cause type error
button.FillColor = {100, 200, 100, 255}  -- ERROR: Bridge_ColorQuad expected, got table
```

### Common Color Properties

Different UI elements support different color properties:

| Property | Applies To | Description | Format |
|----------|-----------|-------------|---------|
| `TitleColor` | Button, Label, TextInput | Text color | RGBA 0-255 |
| `FillColor` | Button, Panel, Image | Background/fill color | RGBA 0-255 |
| `LineColor` | Button, Panel, ProgressBar | Border/outline color | RGBA 0-255 |
| `ForegroundColor` | ProgressBar | Progress fill color | RGBA 0-255 |
| `BackgroundColor` | ProgressBar, Panel | Background color | RGBA 0-255 |

### Color Value Examples

```lua
-- Common colors using ColorQuad.new(r, g, b, a)
local white = ColorQuad.new(255, 255, 255, 255)
local black = ColorQuad.new(0, 0, 0, 255)
local red = ColorQuad.new(255, 0, 0, 255)
local green = ColorQuad.new(0, 255, 0, 255)
local blue = ColorQuad.new(0, 0, 255, 255)
local yellow = ColorQuad.new(255, 255, 0, 255)
local transparent = ColorQuad.new(0, 0, 0, 0)

-- Semi-transparent colors (last value is alpha)
local semi_transparent_white = ColorQuad.new(255, 255, 255, 128)  -- 50% opacity
local semi_transparent_black = ColorQuad.new(0, 0, 0, 128)
```

### RGBA Values Explained

Each color channel ranges from **0 to 255**:

```lua
ColorQuad.new(R, G, B, A)
              ↓  ↓  ↓  ↓
            Red│  │  │  │
           Green│  │  │
            Blue│  │
           Alpha (Transparency)

-- RGB examples:
-- (255, 0, 0, 255)   = Pure red
-- (0, 255, 0, 255)   = Pure green
-- (0, 0, 255, 255)   = Pure blue
-- (255, 255, 0, 255) = Yellow (red + green)
-- (255, 0, 255, 255) = Magenta (red + blue)
-- (0, 255, 255, 255) = Cyan (green + blue)

-- Alpha examples (using red):
-- (255, 0, 0, 255) = Fully opaque red
-- (255, 0, 0, 192) = 75% opaque red
-- (255, 0, 0, 128) = 50% opaque red
-- (255, 0, 0, 64)  = 25% opaque red
-- (255, 0, 0, 0)   = Fully transparent red (invisible)
```

### Key Color Takeaways

✅ **JSON files**: Use array format `[r, g, b, a]`
✅ **Lua scripts**: Use `ColorQuad.new(r, g, b, a)`
✅ **RGBA values**: Range from 0 to 255
✅ **Alpha channel**: 255 = opaque, 0 = transparent
✅ **Dynamic colors**: Change colors at runtime for visual feedback
❌ **Never use Lua tables** for colors in Lua scripts (will cause type error)

---

## Property Reference

### Common Properties (All UI Elements)

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `Name` | string | Element identifier | `"StartButton"` |
| `Size` | `[width, height]` | Dimensions in pixels | `[200, 60]` |
| `Pivot` | `[x, y]` | Anchor point (0-1) | `[0.5, 0.5]` (center) |
| `Visible` | boolean | Visibility state | `true` |
| `RenderIndex` | number | Layering order (higher = front) | `5` |
| `Locked` | boolean | Lock from editing | `false` |
| `Alpha` | number | Transparency (0-1) | `1.0` |

### Text Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `Title` | string | Text content ⚠️ **Not `Text`** | `"Start Game"` |
| `TitleColor` | `[r,g,b,a]` | Text color ⚠️ **Not `TextColor3`** | `[255, 255, 255, 255]` |
| `FontSize` or `TitleSize` | number | Font size in pixels | `24` |
| `Fonts` | string | Font resource path | `""` (default) |
| `TextHAlignment` | number | Horizontal alignment | 0=left, 1=center, 2=right |
| `TextVAlignment` | number | Vertical alignment | 0=top, 1=center, 2=bottom |

### Visual Style Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `FillColor` | `[r,g,b,a]` | Background fill color | `[100, 150, 200, 255]` |
| `LineColor` | `[r,g,b,a]` | Border color | `[50, 50, 50, 255]` |
| `LineSize` | number | Border thickness (pixels) | `2` |
| `Round` | number | Corner radius (panels) | `10` |
| `Icon` | string | Image resource path | `"sandboxSysId://path.png"` |
| `ScaleType` | number | Image scaling mode | 1=stretch, 2=keep ratio |

### Layout Properties (Responsive Positioning)

**For detailed layout information, patterns, and responsive design strategies, see [UI Layout System Guide](common-ui-layout.md).**

---

## UI Element Types Reference

### Complete ClassType List

**Note**: ClassID values are automatically generated by MiniWorld Studio - do not include them in your JSON files.

| Element Type | Description | Common Use |
|--------------|-------------|------------|
| **StarterGui** | UI root service | Top-level UI container service |
| **UIRoot** | UI container | Groups UI elements together |
| **UIButton** | Interactive button | Player actions, menu options |
| **UIPanel** | Container panel | Backgrounds, grouping elements |
| **UIDropDownBox** | Dropdown selector | Option selection |
| **UIImage** | Image display | Icons, logos, backgrounds |
| **UIList** | Scrollable list | Inventory, item lists |
| **UIListLayout** | List layout manager | Auto-layout for lists |
| **UIProgressBar** | Progress indicator | Health, stamina, loading |
| **UITextInput** | Text input field | Player text entry |
| **UITextLabel** | Text display | Labels, scores, titles |
| **UISliderBar** | Slider control | Volume, settings adjustment |
| **UIRoot3D** | 3D UI root | 3D world space UI |
| **UIBillboard** | Billboard UI | Name tags, world markers |
| **UIModelView** | 3D model display | Character preview |
| **UIMovieClip** | Animation clip | Animated UI elements |
| **UIVideoImage** | Video display | Video playback |
| **UISnapshotNode** | Snapshot capture | Screenshot functionality |
| **UIMiniCoin** | Currency display | In-game currency |
| **UIBMLabel** | Bitmap label | Bitmap font text |
| **UIBMNode** | Bitmap node | Bitmap elements |
| **UIBackground** | Background element | Full-screen backgrounds |

---

## Critical Differences from Roblox

⚠️ **IMPORTANT**: MiniWorld Studio UI is fundamentally different from Roblox!

| Feature | ❌ Roblox (Don't Use) | ✅ MiniWorld Studio (Use) |
|---------|---------------------|------------------------|
| **Size** | `UDim2.new(0, 200, 0, 60)` | `Vector2.new(200, 60)` |
| **Text Property** | `Text = "Hello"` | `Title = "Hello"` |
| **Text Color** | `TextColor3 = Color3.new(1,1,1)` | `TitleColor = ColorQuad.new(255,255,255,255)` |
| **Font Size** | `TextSize = 24` | `FontSize = 24` or `TitleSize = 24` |
| **Anchor** | `AnchorPoint = Vector2.new(0.5,0.5)` | `Pivot = Vector2.new(0.5,0.5)` |
| **Z-Index** | `ZIndex = 5` | `RenderIndex = 5` |
| **Button Click** | `MouseButton1Click:Connect()` | `Click:Connect()` |
| **Color Format** | `Color3.new(1, 0.5, 0)` (0-1 range) | `ColorQuad.new(255, 128, 0, 255)` (0-255 RGBA) |

---

## Best Practices

### Organization
1. ✅ **Use UIRoot containers** to group related UI elements
2. ✅ **Use descriptive names** for all UI elements
3. ✅ **Organize by function**: Separate HUD, menus, popups into different UIRoots
4. ✅ **Use RenderIndex** to control layering (higher = in front)

### Performance
1. ✅ **Cache UI references** for frequently updated elements
2. ✅ **Hide instead of destroy** UI elements you'll reuse
3. ✅ **Use layout relations** for responsive design across screen sizes
4. ✅ **Minimize UI updates** - only update when values actually change
5. ✅ **Batch visibility changes** when showing/hiding multiple elements

### Visual Design
1. ✅ **Use consistent colors** throughout your UI
2. ✅ **Set appropriate Pivot points** for proper alignment
3. ✅ **Use Round property** for modern rounded corners on panels
4. ✅ **Set Alpha for transparency** effects
5. ✅ **Use RenderIndex** to ensure proper layering

### Responsive Design
1. ✅ **Use layout relations** for multi-resolution support - See [UI Layout System Guide](common-ui-layout.md)
2. ✅ **Match pivot to anchor** (e.g., `[0,0]` for top-left, `[0.5,0.5]` for center)
3. ✅ **Test multiple resolutions** (1920x1080, 1280x720, 2560x1440)

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Using Roblox Property Names
**Problem**: Using `Text`, `TextColor3`, `UDim2`, `AnchorPoint`
**Solution**: Use MiniWorld properties: `Title`, `TitleColor`, `Vector2`, `Pivot`

### ❌ Mistake 2: Wrong Color Format
**Problem**: `Color3.new(1, 0.5, 0)` or RGB without alpha
**Solution**: `ColorQuad.new(255, 128, 0, 255)` with RGBA 0-255 range

### ❌ Mistake 3: Forgetting UIRoot Container
**Problem**: Adding UI elements directly to WorkSpace
**Solution**: Create UIRoot first, then add elements as children

### ❌ Mistake 4: Wrong Parent Hierarchy
**Problem**: Creating UI in MainStorage or WorkSpace directly
**Solution**: UI elements should be children of StarterGui → UIRoot

### ❌ Mistake 5: Not Setting Visible = true
**Problem**: UI elements created but not visible
**Solution**: Always set `Visible = true` on UI elements

### ❌ Mistake 6: Incorrect Pivot for Centering
**Problem**: Centered element appears offset
**Solution**: Use `Pivot = Vector2.new(0.5, 0.5)` for center-aligned elements

### ❌ Mistake 7: Manually Specifying ClassID or NodeId
**Problem**: Including `ClassID` or `NodeId` fields in JSON files
**Solution**: Remove these fields - they are auto-generated by MiniWorld Studio based on `ClassType`

### ❌ Mistake 8: Accessing UI in StarterGui Instead of PlayerGui 🚨 VERY COMMON
**Problem**: Trying to find UI elements in StarterGui service in Lua scripts
**Symptom**: `FindFirstChild` returns nil even though UI exists in JSON files
**Wrong Code**:
```lua
local StarterGui = game:GetService("StarterGui")
local button = StarterGui:FindFirstChild("DefaultUIMain", true)  -- Returns nil!
```
**Solution**: UI defined in StarterGui JSON is instantiated to PlayerGui at runtime. Always access UI from PlayerGui:
```lua
local Players = game:GetService("Players")
wait(1)  -- Wait for UI to instantiate
local playerGui = Players.LocalPlayer.PlayerGui
local defaultUIMain = playerGui:FindFirstChild("DefaultUIMain", true)  -- ✅ Works!
```

---

## Validation Checklist

Before finalizing your UI configuration:

- [ ] `ClassType` matches the correct UI element type
- [ ] ⚠️ **DO NOT include** `ClassID` or `NodeId` (auto-generated by MiniWorld Studio)
- [ ] `Size` use Vector2 format `[x, y]`
- [ ] `Pivot` is set appropriately for alignment (0-1 range)
- [ ] `Title` property used for text (not `Text`)
- [ ] `TitleColor` uses RGBA format 0-255
- [ ] `RenderIndex` set for proper layering
- [ ] `Visible = true` for elements that should display
- [ ] Parent hierarchy correct: StarterGui → UIRoot → UI Elements
- [ ] Event handlers connected properly
- [ ] 🚨 Lua scripts access UI from `game.Players.LocalPlayer.PlayerGui` (NOT StarterGui)
- [ ] Layout relations set for responsive positioning if needed

---

## Related Documentation

### Layout & Positioning
- **[UI Layout System Guide](common-ui-layout.md)** - Responsive positioning, layout patterns, multi-resolution support

### UI Element Guides
- [How to Add Button](how-to-add-button.md)
- [How to Add TextLabel](how-to-add-textlabel.md)
- [How to Add Image](how-to-add-image.md)
- [How to Add ProgressBar](how-to-add-progressbar.md)
- [How to Add Panel](how-to-add-panel.md)
- [How to Add TextInput](how-to-add-textinput.md)

### System Development
- [How to Create ModuleScript](how-to-create-modulescript.md)
- [How to Build a Feature](../how-to-build-a-feature.md)
- [How to Create Game System](../how-to-create-game-system.md)

### Technical References
- [MiniWorld Studio vs Roblox Architecture Guide](../PromptTpl/AI_Templates/TemplateGame/common/MiniWorld_Studio_vs_Roblox_Architecture_Guide.md)
- [UI Technical Specification](../PromptTpl/AI_Templates/TemplateGame/common/UI_Design_UI_Technical_Specification.md)
