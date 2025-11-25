# UI Layout System Guide for MiniWorld Studio

## 🚨 CRITICAL REQUIREMENT FOR CHILD ELEMENTS

⚠️ **If you're adding child elements inside a panel or container in JSON, YOU MUST include these 4 properties in each child's JSON `reflex` array, or the child will NOT display correctly:**

```json
{"LayoutHRelation": 0},      // Horizontal anchor (0=left, 1=center, 2=right)
{"LayoutVRelation": 0},      // Vertical anchor (0=top, 1=center, 2=bottom)
{"HRelationLength": 10},     // Horizontal offset in pixels
{"VRelationLength": 20}      // Vertical offset in pixels
```

**Why this matters**: Without layout properties, child elements won't position correctly and will appear overlapped at [0,0] or not render at all.

**See the complete guide** in [How to Add Panel - Adding Children section](how-to-add-panel.md#🚨-critical-adding-children-to-panels) for detailed examples.

---

## Overview

MiniWorld Studio's layout system enables **responsive UI positioning** across different screen resolutions using layout relations, offsets, and pivot points. This system is built on **FairyGUI** and provides fine-grained control over UI element positioning and sizing.

**Prerequisites**: Read [common-ui.md](common-ui.md) first for fundamental UI concepts.

---

## Core Layout Concepts

### The Three-Component Layout System

MiniWorld Studio's UI layout uses three key components that work together:

1. **Pivot Point** - The anchor/reference point within the element itself (0-1 range)
2. **Layout Relations** - Which edge or center of the parent/screen to anchor to
3. **Relation Offsets** - Pixel offsets from the anchor point

```
Element Final Position = Parent Anchor Point + Relation Offset - (Element Size × Element Pivot)
```

### Parent-Child Coordinate Systems

⚠️ **Critical Concept**: Child element positions are **relative to the parent's top-left corner**, not the screen.
⚠️ **In JSON Configuration Files:**Child elements MUST explicitly set layout relation properties to use arent-relative positioning

**How It Works**:

When a UI element is a child of another element (e.g., a label inside a panel), the child's `Position` property is interpreted relative to the parent's coordinate system, with the parent's top-left corner as the origin `[0, 0]`.

**Example**:

```
Panel (parent):
  - Screen position: [10, 90]
  - Size: [250, 450]

Child Label inside panel:
  - Position: [125, 25] (relative to parent)
  - Actual screen position: [10+125, 90+25] = [135, 115]
  - Interpretation: 125px from panel's left edge, 25px from panel's top edge
```

**Hierarchy Example**:

```
Screen (1920×1080)
└── UIRoot (DefaultUIMain)
    └── Panel at [10, 90], size [250, 450]
        ├── Title at [125, 25]   → Screen position: [135, 115]
        ├── Label1 at [15, 70]   → Screen position: [25, 160]
        └── Label2 at [15, 115]  → Screen position: [25, 205]
```

**Common Mistakes**:

❌ **Setting child bounds outside parent bounds**:
```json
// Panel is only 250px wide
{"Size": [250, 450]}

// Child at x=300 would be OUTSIDE the panel's visible area!
{"Size": [300, 30]}  // ❌ Wrong - exceeds parent width (300 > 250)
```

❌ **Confusing screen coordinates with parent-relative coordinates**:
```lua
-- Wrong: Trying to position child at screen coordinates
local panel = SandboxNode.new('UIPanel', uiRoot)
panel.Position = Vector2.new(10, 90)
panel.Size = Vector2.new(250, 450)

local label = SandboxNode.new('UITextLabel', panel)
label.Position = Vector2.new(135, 115)  -- ❌ Wrong! This is 135px from panel's left, not screen

-- Correct: Use parent-relative coordinates
label.Position = Vector2.new(125, 25)   -- ✅ Correct - relative to panel at [10, 90]
```

**Best Practices**:

✅ **Always calculate child positions relative to parent dimensions**:
```lua
-- Center a child horizontally within parent
local parentWidth = 250
local childWidth = 200
local childX = (parentWidth - childWidth) / 2  -- = 25px from parent's left

-- Position child with padding
local padding = 15
local childX = padding  -- 15px from parent's left edge
```

✅ **Verify child positions stay within parent bounds**:
```lua
-- Child position + child size should not exceed parent size
assert(childX + childSize.x <= parentSize.x, "Child exceeds parent width")
assert(childY + childSize.y <= parentSize.y, "Child exceeds parent height")
```

✅ **Use UIRoot or UIPanel as containers to organize related elements**:
```
UIRoot/Panel serves as the positioning context for all its children,
making it easier to move groups of elements together.
```

---

## Layout Properties

### Core Layout Properties

LayoutHRelation and LayoutVRelation define which edge or center of the parent container (or screen) to anchor to.

| Property | Type | Description | Values | Default |
|----------|------|-------------|--------|---------|
| `Size` | Vector2 | Element dimensions | [width, height] pixels | [100, 100] |
| `Pivot` | Vector2 | Element's anchor point (normalized) | [0-1, 0-1] where [0,0]=top-left, [1,1]=bottom-right | [0.5, 0.5] |
| `LayoutHRelation` | number | Horizontal alignment anchor | 0=left, 1=center, 2=right | 0 (Left) |
| `LayoutVRelation` | number | Vertical alignment anchor | 0=top, 1=center, 2=bottom | 0 (Top) |
| `HRelationLength` | number | Horizontal offset from anchor (pixels) | Any number (can be negative) | 0 |
| `VRelationLength` | number | Vertical offset from anchor (pixels) | Any number (can be negative) | 0 |

**Important**: `Position` property is NOT used for positioning when layout relations are set. The element's position is calculated from Pivot, LayoutHRelation, LayoutVRelation, HRelationLength, and VRelationLength.

### Understanding Pivot Points

**Pivot** is the **anchor point within the element** that determines:
- Where the Position refers to on the element
- The center point for rotation and scaling
- The reference point for layout calculations

```
Pivot Coordinate System (normalized 0-1):
  [0, 0]     = Top-left corner of element
  [0.5, 0]   = Top-center of element
  [1, 0]     = Top-right corner of element
  [0, 0.5]   = Middle-left of element
  [0.5, 0.5] = Center of element (most common)
  [1, 0.5]   = Middle-right of element
  [0, 1]     = Bottom-left corner of element
  [0.5, 1]   = Bottom-center of element
  [1, 1]     = Bottom-right corner of element
```

**Key Principle**: The Pivot point of the element aligns with the Position coordinate.

**Example**:
```lua
-- Element with Pivot [0, 0] (top-left)
element.Pivot = Vector2.new(0, 0)
element.Position = Vector2.new(100, 50)
-- The top-left corner of the element will be at (100, 50)

-- Element with Pivot [0.5, 0.5] (center)
element.Pivot = Vector2.new(0.5, 0.5)
element.Position = Vector2.new(100, 50)
-- The center of the element will be at (100, 50)

-- Element with Pivot [1, 1] (bottom-right)
element.Pivot = Vector2.new(1, 1)
element.Position = Vector2.new(100, 50)
-- The bottom-right corner of the element will be at (100, 50)
```

### How Layout Relations Work

**Offset Direction Rules**:
- **Left anchor (0)**: Positive `HRelationLength` moves RIGHT from left edge
- **Right anchor (1)**: Negative `HRelationLength` moves LEFT from right edge (inward)
- **Center anchor (2)**: Positive moves RIGHT, negative moves LEFT from center
- **Top anchor (0)**: Positive `VRelationLength` moves DOWN from top edge
- **Bottom anchor (1)**: Negative `VRelationLength` moves UP from bottom edge (inward)
- **Center anchor (2)**: Positive moves DOWN, negative moves UP from center

---

## Layout Computation Formulas

### Position Calculation Formula

The final position of a UI element is calculated as:

```
For Horizontal Position (X):
  if LayoutHRelation == 0 (Left):
    Final_X = 0 + HRelationLength - (Size.width × Pivot.x)

  if LayoutHRelation == 1 (Center):
    Final_X = (Parent_Width / 2) + HRelationLength - (Size.width × Pivot.x)

  if LayoutHRelation == 2 (Right):
    Final_X = Parent_Width + HRelationLength - (Size.width × Pivot.x)

For Vertical Position (Y):
  if LayoutVRelation == 0 (Top):
    Final_Y = 0 + VRelationLength - (Size.height × Pivot.y)

  if LayoutVRelation == 1 (Center):
    Final_Y = (Parent_Height / 2) + VRelationLength - (Size.height × Pivot.y)

  if LayoutVRelation == 2 (Bottom):
    Final_Y = Parent_Height + VRelationLength - (Size.height × Pivot.y)
```

### Practical Calculation Examples

**Example 1: Top-Left Corner Element**
```
Given:
  Size = [54, 54]
  Pivot = [0, 0]
  LayoutHRelation = 0 (Left)
  LayoutVRelation = 0 (Top)
  HRelationLength = 10
  VRelationLength = 10

Calculation:
  Final_X = 0 + 10 + (54 × 0) = 10
  Final_Y = 0 + 10 + (54 × 0) = 10

Result: Element's top-left corner is at (10, 10)
```

**Example 2: Top-Right Corner Element** (from BtnExit sample)
```
Given:
  Parent_Width = 1920 (Full HD)
  Size = [54, 54]
  Pivot = [0, 0]
  LayoutHRelation = 2 (Right)
  LayoutVRelation = 0 (None, but effectively top)
  HRelationLength = -17
  VRelationLength = 6

Calculation:
  Final_X = 1920 + (-17) - (54 × (1 - 0))
         = 1920 - 17 - 54
         = 1849
  Final_Y = 0 + 6 + (54 × 0) = 6

Result: Element's top-left corner is at (1849, 6)
        which positions it 17 pixels from the right edge
```

**Example 3: Bottom-Right Corner Element** (from BtnJump sample)
```
Given:
  Parent_Width = 1920, Parent_Height = 1080
  Size = [117, 119]
  Pivot = [0.5, 0.5]
  LayoutHRelation = 2 (Right)
  LayoutVRelation = 2 (Bottom)
  HRelationLength = -58.5
  VRelationLength = -40.5

Calculation:
  Final_X = 1920 + (-58.5) - (117 × (1 - 0.5))
         = 1920 - 58.5 - 58.5
         = 1803
  Final_Y = 1080 + (-40.5) - (119 × (1 - 0.5))
         = 1080 - 40.5 - 59.5
         = 980

Result: Element's center is at (1803, 980)
        which positions it ~58.5px from the right and ~40.5px from the bottom
```

**Example 4: Center Screen Element**
```
Given:
  Parent_Width = 1920, Parent_Height = 1080
  Size = [400, 300]
  Pivot = [0.5, 0.5]
  LayoutHRelation = 1 (Center)
  LayoutVRelation = 1 (Center)
  HRelationLength = 0
  VRelationLength = 0

Calculation:
  Final_X = (1920 / 2) + 0 + (400 × (0.5 - 0.5))
         = 960 + 0 + 0
         = 960
  Final_Y = (1080 / 2) + 0 + (300 × (0.5 - 0.5))
         = 540 + 0 + 0
         = 540

Result: Element's center is perfectly centered at (960, 540)
```

---

## Common Layout Patterns

### Pattern 1: Top-Left Corner (HUD Elements)

**Use Case**: Health bars, minimap, player stats

```lua
-- JSON
{
  "Size": [200, 50],
  "Pivot": [0, 0],
  "LayoutHRelation": 0,  -- Left align
  "LayoutVRelation": 0,  -- Top align
  "HRelationLength": 10,
  "VRelationLength": 10
}

-- Lua
element.Size = Vector2.new(200, 50)
element.Pivot = Vector2.new(0, 0)
element.LayoutHRelation = 0  -- Left
element.LayoutVRelation = 0  -- Top
element.HRelationLength = 10
element.VRelationLength = 10
```

**Result**: Element positioned 10px from left edge, 10px from top edge

### Pattern 2: Top-Right Corner (Score/Currency)

**Use Case**: Score displays, currency counters, settings button

```lua
-- JSON (Based on real BtnSetting example)
{
  "Size": [54, 54],
  "Pivot": [0, 0],
  "LayoutHRelation": 2,  -- Right align
  "LayoutVRelation": 0,  -- Top
  "HRelationLength": -197,  -- Negative = inward from right
  "VRelationLength": 6
}

-- Lua
element.Size = Vector2.new(54, 54)
element.Pivot = Vector2.new(0, 0)
element.LayoutHRelation = 2  -- Right
element.LayoutVRelation = 0  -- Top
element.HRelationLength = -197  -- Negative to offset from right edge
element.VRelationLength = 6
```

**Result**: Element positioned 197px from right edge (moving left), 6px from top

### Pattern 3: Center Screen (Main Menu)

**Use Case**: Main menus, dialogs, modal windows

```lua
-- JSON
{
  "Size": [400, 300],
  "Pivot": [0.5, 0.5],
  "LayoutHRelation": 1,  -- Center H
  "LayoutVRelation": 1,  -- Center V
  "HRelationLength": 0,
  "VRelationLength": 0
}

-- Lua
element.Size = Vector2.new(400, 300)
element.Pivot = Vector2.new(0.5, 0.5)
element.LayoutHRelation = 1  -- Center
element.LayoutVRelation = 1  -- Center
element.HRelationLength = 0
element.VRelationLength = 0
```

**Result**: Element perfectly centered on screen, center point at screen center

### Pattern 4: Bottom-Right Corner (Jump Button)

**Use Case**: Jump button, attack button (mobile controls)

```lua
-- JSON (Based on real BtnJump example)
{
  "Size": [117, 119],
  "Pivot": [0.5, 0.5],
  "LayoutHRelation": 2,  -- Right align
  "LayoutVRelation": 2,  -- Bottom align
  "HRelationLength": -58.5,
  "VRelationLength": -40.5
}

-- Lua
element.Size = Vector2.new(117, 119)
element.Pivot = Vector2.new(0.5, 0.5)
element.LayoutHRelation = 2  -- Right
element.LayoutVRelation = 2  -- Bottom
element.HRelationLength = -58.5  -- Negative = inward from right
element.VRelationLength = -40.5  -- Negative = inward from bottom
```

**Result**: Element positioned ~58.5px from right edge, ~40.5px from bottom edge

### Pattern 5: Bottom-Left Corner (Controls)

**Use Case**: Movement joystick, mobile touch controls

```lua
-- JSON
{
  "Size": [150, 150],
  "Pivot": [0, 1],
  "LayoutHRelation": 0,  -- Left align
  "LayoutVRelation": 2,  -- Bottom align
  "HRelationLength": 120,
  "VRelationLength": -60
}

-- Lua
element.Size = Vector2.new(150, 150)
element.Pivot = Vector2.new(0, 1)
element.LayoutHRelation = 0  -- Left
element.LayoutVRelation = 2  -- Bottom
element.HRelationLength = 120
element.VRelationLength = -60  -- Negative to offset up from bottom
```

**Result**: Element positioned 120px from left edge, 60px from bottom edge

### Pattern 6: Bottom Center (Action Bar)

**Use Case**: Action bar, skill buttons, interaction prompts

```lua
-- JSON
{
  "Size": [400, 80],
  "Pivot": [0.5, 1],
  "LayoutHRelation": 1,  -- Center H
  "LayoutVRelation": 2,  -- Bottom align
  "HRelationLength": 0,
  "VRelationLength": -60
}

-- Lua
element.Size = Vector2.new(400, 80)
element.Pivot = Vector2.new(0.5, 1)
element.LayoutHRelation = 1  -- Center
element.LayoutVRelation = 2  -- Bottom
element.HRelationLength = 0
element.VRelationLength = -60  -- Negative to offset up from bottom
```

**Result**: Element horizontally centered, 60px from bottom edge

---

## Best Practices

### Guiding Principle: User Flow Over Math

⚠️ **Key Principle**: UI layout is about **user flow and expectations**, not just mathematical non-overlap.

**Common Anti-Pattern**:
```
❌ Calculate positions to avoid overlap → Place elements anywhere that "fits"
✅ Consider user expectations first → Then calculate positions that serve UX
```

**Example of Wrong Thinking**:
```
Panel ends at y=550, so put toggle button at y=560
→ Technically correct (no overlap)
→ Terrible UX (button in middle of screen, disconnected from context)
```

**Example of Right Thinking**:
```
Toggle buttons belong at screen edges where users expect them
→ Button at top-left (y=30)
→ Panel appears below when toggled (y=90)
→ Clear relationship, predictable location
```

**Remember**: Users don't care about your math. They care about finding controls quickly and having a consistent, predictable interface.

---

### 1. Pivot and Anchor Alignment

**Match Pivot to Layout Relation** for intuitive positioning:

| Layout Position | Recommended Pivot | Reason |
|----------------|-------------------|---------|
| Top-Left | [0, 0] | Pivot at top-left corner aligns with top-left anchor |
| Top-Right | [1, 0] or [0, 0] | Either works; [0, 0] common for buttons |
| Bottom-Left | [0, 1] | Pivot at bottom-left aligns with bottom-left anchor |
| Bottom-Right | [1, 1] or [0.5, 0.5] | [0.5, 0.5] common for circular buttons |
| Center | [0.5, 0.5] | Center pivot for centered elements |
| Top-Center | [0.5, 0] | Center pivot horizontally, top vertically |
| Bottom-Center | [0.5, 1] | Center pivot horizontally, bottom vertically |

### 2. Offset Sign Convention

**Always use correct offset signs**:
- ✅ Right anchor with **negative** offset (moves left/inward): `HRelationLength = -20`
- ✅ Bottom anchor with **negative** offset (moves up/inward): `VRelationLength = -40`
- ✅ Left anchor with **positive** offset (moves right): `HRelationLength = 10`
- ✅ Top anchor with **positive** offset (moves down): `VRelationLength = 10`
- ❌ Wrong: Right anchor with positive offset (moves outside screen)

### 3. Element Sizing

**Use the `Size` property** to set element dimensions:
```lua
element.Size = Vector2.new(width, height)
```

The element will use its `Size` property for dimensions. There are no additional size relation properties needed.

**Best Practices**:

✅ **Do not use `Position` in json**:
```json
{
  "LayoutHRelation": 1,    // Left anchor
  "LayoutVRelation": 1,    // Top anchor
  "HRelationLength": 10,   // Offset from left
  "VRelationLength": 30    // Offset from top
}
```

✅ **Clear separation of concerns**:
```lua
-- Either use absolute positioning
element.Position = Vector2.new(100, 200)
element.LayoutHRelation = 0
element.LayoutVRelation = 0

-- OR use layout relations
element.LayoutHRelation = 1  -- Left
element.LayoutVRelation = 1  -- Top
element.HRelationLength = 10
element.VRelationLength = 30
-- Don't mix both approaches
```

### 5. Responsive Design Strategy

**For multi-resolution support**:
1. Use layout relations instead of absolute positioning
2. Anchor edge-aligned elements to their respective edges
3. Center important dialogs and menus
4. Test on common resolutions: 1920×1080, 1280×720, 2560×1440, 3840×2160

### 5. Common Pivot Values

**Most frequently used pivot values**:
- `[0.5, 0.5]` - Universal, works for most elements (50% usage)
- `[0, 0]` - Top-left anchor, common for HUD elements (30% usage)
- `[1, 1]` - Bottom-right anchor, less common (10% usage)
- `[0, 1]` - Bottom-left anchor (5% usage)
- `[1, 0]` - Top-right anchor (5% usage)

### 6. Layout Relation Combinations

**Common relation combinations**:

| Pattern | LayoutHRelation | LayoutVRelation | Use Case |
|---------|----------------|-----------------|----------|
| Top-Left | 0 (Left) | 0 (Top) | Status bars, minimap |
| Top-Right | 2 (Right) | 0 (Top) | Settings, score |
| Top-Center | 1 (Center) | 0 (Top) | Title text |
| Center | 1 (Center) | 1 (Center) | Dialogs, menus |
| Bottom-Left | 0 (Left) | 2 (Bottom) | Joystick |
| Bottom-Right | 2 (Right) | 2 (Bottom) | Jump button |
| Bottom-Center | 1 (Center) | 2 (Bottom) | Action bar |

### 7. UI Design Checklist

Before finalizing UI element positions, ask yourself these questions:

#### User Expectations
- [ ] **Is this where users would naturally look for this control?**
  - Toggle buttons → Screen corners/edges
  - HUD elements → Top corners
  - Action buttons → Bottom area
  - Menus/dialogs → Screen center

#### Control Type Considerations
- [ ] **Is this a persistent control or dynamic content?**
  - **Persistent controls** (always visible) → Fixed screen edges/corners
  - **Dynamic content** (appears/disappears) → Can be flexible, centered, or context-dependent
  - **Toggle buttons** → Must be persistent and in predictable locations

#### Multi-Resolution Support
- [ ] **Will this look good at different screen resolutions?**
  - Use layout relations for edge-anchored elements
  - Use center anchoring for dialogs and menus

#### Visual Validation
- [ ] **Have I mentally simulated what this looks like on screen?**
  - Don't just calculate coordinates - visualize the result
  - Consider spacing, grouping, and visual hierarchy
  - Check for awkward gaps or unexpected overlaps

**Example Decision Process**:

```
Task: Add a leaderboard toggle button

❌ Wrong thinking:
"Panel ends at y=550, so button goes at y=560"
→ Math-focused, ignores UX

✅ Right thinking:
"Where do users expect toggle buttons?"
→ Screen edges (top-left, top-right)
"What similar controls exist?"
→ Exit button at top-right
"Where should this go?"
→ Top-left (y=30) - predictable, accessible
→ Panel appears below when toggled (y=90)
```

---

## Advanced Topics

### Dynamic Position Calculation in Lua

Calculate element positions at runtime:

```lua
-- Get screen/parent dimensions
local screenWidth = 1920   -- Get from UI service
local screenHeight = 1080

-- Calculate position for top-right element
local function calculateTopRightPosition(elementSize, offsetFromRight, offsetFromTop)
    local finalX = screenWidth - offsetFromRight - elementSize.x
    local finalY = offsetFromTop
    return Vector2.new(finalX, finalY)
end

-- Usage
local btnSize = Vector2.new(54, 54)
local position = calculateTopRightPosition(btnSize, 17, 6)
element.Position = position
```

### Converting Between Pivot Points

When changing pivot, adjust position to maintain visual location:

```lua
function changePivotKeepPosition(element, newPivot)
    local oldPivot = element.Pivot
    local size = element.Size

    -- Calculate offset caused by pivot change
    local offsetX = (newPivot.x - oldPivot.x) * size.x
    local offsetY = (newPivot.y - oldPivot.y) * size.y

    -- Adjust position to compensate
    element.Position = Vector2.new(
        element.Position.x + offsetX,
        element.Position.y + offsetY
    )
    element.Pivot = newPivot
end

-- Usage
changePivotKeepPosition(element, Vector2.new(0.5, 0.5))
```

### Screen-Safe Margins

Add safe margins for different screen aspect ratios:

```lua
-- Define safe margins
local safeMargins = {
    top = 10,
    bottom = 60,
    left = 10,
    right = 10
}

-- Apply to element
element.LayoutHRelation = 0  -- Left
element.LayoutVRelation = 0  -- Top
element.HRelationLength = safeMargins.left
element.VRelationLength = safeMargins.top
```

---

## Common Mistakes and Solutions

### ❌ Mistake 1: Wrong Pivot for Alignment

**Problem**: Element appears offset from expected position

```lua
-- WRONG: Top-right anchor with center pivot
element.Pivot = Vector2.new(0.5, 0.5)
element.LayoutHRelation = 2  -- Right
element.HRelationLength = -10
-- Element's center is 10px from right, so it extends beyond screen
```

**Solution**: Match pivot to anchor

```lua
-- CORRECT: Top-right anchor with top-left pivot
element.Pivot = Vector2.new(0, 0)
element.LayoutHRelation = 2  -- Right
element.HRelationLength = -10
-- Element's left edge is 10px from right edge
```

### ❌ Mistake 2: Forgetting Negative Offsets

**Problem**: Right/bottom-anchored elements positioned incorrectly

```lua
-- WRONG: Right anchor with positive offset
element.LayoutHRelation = 2  -- Right
element.HRelationLength = 20  -- Moves outside screen to the right!
```

**Solution**: Use negative offsets for right/bottom anchors

```lua
-- CORRECT: Right anchor with negative offset
element.LayoutHRelation = 2  -- Right
element.HRelationLength = -20  -- Moves 20px inward from right edge
```

### ❌ Mistake 3: Absolute Positioning Without Relations

**Problem**: UI breaks on different screen sizes

```lua
-- WRONG: No layout relations, breaks on different resolutions
element.Position = Vector2.new(1850, 10)
element.LayoutHRelation = 0  -- None
element.LayoutVRelation = 0  -- None
```

**Solution**: Always use layout relations

```lua
-- CORRECT: Layout relations for responsive behavior
element.LayoutHRelation = 2  -- Right
element.LayoutVRelation = 0  -- Top
element.HRelationLength = -70
element.VRelationLength = 10
```

### ❌ Mistake 4: Inconsistent Pivot and Anchor

**Problem**: Element rotates or scales from wrong point

```lua
-- WRONG: Bottom anchor but top pivot
element.Pivot = Vector2.new(0.5, 0)  -- Top center pivot
element.LayoutVRelation = 2  -- Bottom anchor
-- When parent resizes, element moves unexpectedly
```

**Solution**: Align pivot with intended anchor

```lua
-- CORRECT: Bottom anchor with bottom pivot
element.Pivot = Vector2.new(0.5, 1)  -- Bottom center pivot
element.LayoutVRelation = 2  -- Bottom anchor
```

---

## Quick Reference: Layout Relation Codes

```
Horizontal (LayoutHRelation):
  0 = Left edge
  1 = Center (Middle)
  2 = Right edge

Vertical (LayoutVRelation):
  0 = Top edge
  1 = Center (Middle)
  2 = Bottom edge

Note: Position property is NOT used when layout relations are set.
Element position is calculated from: Pivot + LayoutH/VRelation + H/VRelationLength
```

---

## Real-World Examples from Sample Code

### Example 1: Exit Button (Top-Right)

From `BridgeBattle/ServiceNodes/StarterGui/DefaultUIMain/BtnExit.json`:

```json
{
  "Size": [54, 54],
  "Pivot": [0, 0],
  "LayoutHRelation": 2,      // Right edge
  "LayoutVRelation": 0,      // None (absolute top)
  "HRelationLength": -17,    // 17px from right edge (inward)
  "VRelationLength": 6,      // 6px from top
  "WidthRelationLength": 10000000,
  "HeightRelationLength": 10000000
}
```

**Analysis**: 54×54 button anchored to right edge, positioned 17px from right, 6px from top.

### Example 2: Settings Button (Top-Right, Further Left)

From `BridgeBattle/ServiceNodes/StarterGui/DefaultUIMain/BtnSetting.json`:

```json
{
  "Size": [54, 54],
  "Pivot": [0, 0],
  "LayoutHRelation": 2,      // Right edge
  "LayoutVRelation": 0,      // None (absolute top)
  "HRelationLength": -197,   // 197px from right edge (inward)
  "VRelationLength": 6,      // 6px from top
  "WidthRelationLength": 10000000,
  "HeightRelationLength": 10000000
}
```

**Analysis**: Same size as exit button, but positioned 197px from right edge (further left).

### Example 3: Jump Button (Bottom-Right)

From `BridgeBattle/ServiceNodes/StarterGui/TouchUIMain/BtnJump.json`:

```json
{
  "Size": [117, 119],
  "Pivot": [0.5, 0.5],       // Center pivot
  "LayoutHRelation": 2,      // Right edge
  "LayoutVRelation": 2,      // Bottom edge
  "HRelationLength": -58.5,  // 58.5px from right edge (inward)
  "VRelationLength": -40.5,  // 40.5px from bottom edge (inward)
  "WidthRelationLength": 10000000,
  "HeightRelationLength": 10000000
}
```

**Analysis**: Circular button with center pivot, anchored to bottom-right corner, uses negative offsets for both axes to position inward from edges.

---

## Related Documentation

- [Common UI Knowledge](common-ui.md) - Core UI concepts and properties
- [How to Add Button](how-to-add-button.md) - Button creation and configuration
- [How to Add Panel](how-to-add-panel.md) - Panel layout and containers
- [How to Create UI Elements](../how-to-create-ui-elements.md) - General UI element creation
- [SandboxUIComponent Reference](../refDoc/Documents/UI/SandboxUIComponent.md) - Complete API reference
- [SandboxUIBase Reference](../refDoc/Documents/UI/SandboxUIBase.md) - Base UI class reference

---

## Summary

The MiniWorld Studio UI layout system provides powerful responsive positioning through:

1. **Pivot Points** - Define the anchor within the element (0-1 normalized, where [0,0]=top-left, [1,1]=bottom-right)
2. **Layout Relations** - Define which parent edge/center to anchor to (0=left/top, 1=center, 2=right/bottom)
3. **Relation Offsets** - Define pixel offsets from the anchor point (positive/negative)
4. **Element Size** - Set explicit dimensions via the Size property

**Key Principles**:
- Position is NOT used - calculated from Pivot + LayoutRelations + RelationOffsets
- LayoutHRelation: 0=left, 1=center, 2=right
- LayoutVRelation: 0=top, 1=center, 2=bottom
- Match pivot to intended anchor for intuitive positioning
- Use negative offsets for right/bottom anchors to move inward
- Test on multiple resolutions to ensure responsive behavior
- Follow the offset sign conventions to avoid positioning errors

This system ensures UI elements position correctly across all screen sizes while maintaining design intent.
