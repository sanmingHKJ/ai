# How to Add UITextInput

📚 **Prerequisites**: Read [Common UI Knowledge](common-ui.md) first for fundamental UI concepts, color formats, layout patterns, and how to access UI at runtime.

## Overview

**UITextInput** is a text input field for player text entry, including player names, chat messages, search boxes, and custom input forms. Text inputs support character limits and completion events.

---

## Method 1: Static Addition (JSON Configuration)

### Basic Text Input Template

```json
{
  "ClassType": "UITextInput",
  "attribute": [],
  "flags": 0,
  "realNodeName": "NameInput",
  "reflex": [
    {"Name": "NameInput"},
    {"Size": [300, 40]},
    {"Pivot": [0, 0]},
    {"Title": ""},
    {"FontSize": 20},
    {"TitleColor": [255, 255, 255, 255]},
    {"FillColor": [60, 60, 70, 255]},
    {"LineColor": [120, 120, 140, 255]},
    {"LineSize": 2},
    {"MaxLength": 20},
    {"TextInputMode": 0},
    {"Visible": true},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 400},
    {"VRelationLength": 300}
  ]
}
```

---

## Method 2: Dynamic Addition (Lua Scripting)

### Basic Text Input Creation

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
wait(1)  -- Wait for UI to instantiate

local playerGui = localPlayer.PlayerGui
local uiRoot = playerGui:FindFirstChild("DefaultUIMain", true)

local input = SandboxNode.new('UITextInput', uiRoot)
input.Name = "NameInput"
input.Position = Vector2.new(400, 300)
input.Size = Vector2.new(300, 40)
input.Pivot = Vector2.new(0, 0)
input.Title = ""  -- Empty initially
input.FontSize = 20
input.TitleColor = ColorQuad.new(255, 255, 255, 255)
input.FillColor = ColorQuad.new(60, 60, 70, 255)
input.LineColor = ColorQuad.new(120, 120, 140, 255)
input.LineSize = 2
input.MaxLength = 20
input.Visible = true

-- Handle input completion
input.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        local text = input.Title
        print("User entered:", text)
        -- Validate and process input
        if text ~= "" then
            -- Process valid input
        end
    end
end)
```

---

## TextInput-Specific Properties

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `MaxLength` | number | Maximum input characters (0=unlimited) | `50` |
| `TextInputMode` | number | Input mode restriction (currently unused) | `0` |

---

## TextInput Events

| Event | Parameters | Description | Use Case |
|-------|-----------|-------------|----------|
| `NotifyTouchReturn` | `onReturn (bool)` | Input completed (focus lost or Enter pressed) | Validate and process input |

---

## Practical Examples

### Example 1: Player Name Input

```lua
local namePanel = SandboxNode.new('UIPanel', uiRoot)
namePanel.Name = "NamePanel"
namePanel.Position = Vector2.new(960, 540)
namePanel.Size = Vector2.new(400, 200)
namePanel.Pivot = Vector2.new(0.5, 0.5)
namePanel.FillColor = ColorQuad.new(40, 40, 50, 240)
namePanel.LineColor = ColorQuad.new(100, 100, 120, 255)
namePanel.LineSize = 2
namePanel.Round = 10
namePanel.Visible = true

-- Label
local nameLabel = SandboxNode.new('UITextLabel', namePanel)
nameLabel.Position = Vector2.new(200, 50)
nameLabel.Size = Vector2.new(360, 30)
nameLabel.Pivot = Vector2.new(0.5, 0.5)
nameLabel.Title = "Enter your name:"
nameLabel.FontSize = 22
nameLabel.TitleColor = ColorQuad.new(255, 255, 255, 255)
nameLabel.TextHAlignment = 1
nameLabel.TextVAlignment = 1
nameLabel.Visible = true

-- Input field
local nameInput = SandboxNode.new('UITextInput', namePanel)
nameInput.Name = "NameInput"
nameInput.Position = Vector2.new(50, 100)
nameInput.Size = Vector2.new(300, 40)
nameInput.Pivot = Vector2.new(0, 0)
nameInput.Title = ""
nameInput.FontSize = 20
nameInput.TitleColor = ColorQuad.new(255, 255, 255, 255)
nameInput.FillColor = ColorQuad.new(60, 60, 70, 255)
nameInput.LineColor = ColorQuad.new(120, 120, 140, 255)
nameInput.LineSize = 2
nameInput.MaxLength = 20
nameInput.Visible = true

-- Confirm button
local confirmButton = SandboxNode.new('UIButton', namePanel)
confirmButton.Position = Vector2.new(200, 160)
confirmButton.Size = Vector2.new(120, 40)
confirmButton.Pivot = Vector2.new(0.5, 0.5)
confirmButton.Title = "Confirm"
confirmButton.TitleSize = 20
confirmButton.TitleColor = ColorQuad.new(255, 255, 255, 255)
confirmButton.FillColor = ColorQuad.new(70, 140, 70, 255)
confirmButton.LineColor = ColorQuad.new(50, 120, 50, 255)
confirmButton.LineSize = 2
confirmButton.Round = 5
confirmButton.Visible = true

confirmButton.Click:Connect(function()
    local playerName = nameInput.Title
    if playerName ~= "" and string.len(playerName) >= 3 then
        print("Player name set to:", playerName)
        namePanel.Visible = false
        -- Save player name
    else
        print("Name must be at least 3 characters!")
    end
end)

-- Handle Enter key
nameInput.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        confirmButton.Click:Fire()  -- Trigger confirm button
    end
end)
```

### Example 2: Chat Input Box

```lua
local chatInput = SandboxNode.new('UITextInput', uiRoot)
chatInput.Name = "ChatInput"
chatInput.Position = Vector2.new(20, 1020)
chatInput.Size = Vector2.new(500, 40)
chatInput.Pivot = Vector2.new(0, 1)  -- Bottom-left anchor
chatInput.Title = "Type a message..."
chatInput.FontSize = 18
chatInput.TitleColor = ColorQuad.new(200, 200, 200, 255)
chatInput.FillColor = ColorQuad.new(30, 30, 30, 200)
chatInput.LineColor = ColorQuad.new(80, 80, 80, 255)
chatInput.LineSize = 1
chatInput.MaxLength = 100
chatInput.Visible = true
chatInput.LayoutHRelation = 0  -- Left
chatInput.LayoutVRelation = 2  -- Bottom
chatInput.HRelationLength = 20
chatInput.VRelationLength = -60

chatInput.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        local message = chatInput.Title
        if message ~= "" and message ~= "Type a message..." then
            print("Chat message:", message)
            -- Send chat message to server
            chatInput.Title = "Type a message..."  -- Reset
        end
    end
end)
```

### Example 3: Search Box

```lua
local searchPanel = SandboxNode.new('UIPanel', uiRoot)
searchPanel.Name = "SearchPanel"
searchPanel.Position = Vector2.new(960, 100)
searchPanel.Size = Vector2.new(500, 60)
searchPanel.Pivot = Vector2.new(0.5, 0)
searchPanel.FillColor = ColorQuad.new(50, 50, 60, 240)
searchPanel.LineColor = ColorQuad.new(100, 100, 120, 255)
searchPanel.LineSize = 2
searchPanel.Round = 30  -- Pill shape
searchPanel.Visible = true

-- Search icon (you would add an actual image here)
local searchLabel = SandboxNode.new('UITextLabel', searchPanel)
searchLabel.Position = Vector2.new(30, 30)
searchLabel.Size = Vector2.new(40, 40)
searchLabel.Pivot = Vector2.new(0.5, 0.5)
searchLabel.Title = "🔍"
searchLabel.FontSize = 24
searchLabel.TitleColor = ColorQuad.new(200, 200, 200, 255)
searchLabel.TextHAlignment = 1
searchLabel.TextVAlignment = 1
searchLabel.Visible = true

-- Search input
local searchInput = SandboxNode.new('UITextInput', searchPanel)
searchInput.Name = "SearchInput"
searchInput.Position = Vector2.new(60, 10)
searchInput.Size = Vector2.new(380, 40)
searchInput.Pivot = Vector2.new(0, 0)
searchInput.Title = "Search..."
searchInput.FontSize = 18
searchInput.TitleColor = ColorQuad.new(255, 255, 255, 255)
searchInput.FillColor = ColorQuad.new(0, 0, 0, 0)  -- Transparent
searchInput.LineColor = ColorQuad.new(0, 0, 0, 0)  -- No border
searchInput.LineSize = 0
searchInput.MaxLength = 50
searchInput.Visible = true

searchInput.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        local query = searchInput.Title
        if query ~= "" and query ~= "Search..." then
            print("Searching for:", query)
            -- Perform search
        end
    end
end)
```

### Example 4: Code/Password Input

```lua
local codePanel = SandboxNode.new('UIPanel', uiRoot)
codePanel.Name = "CodePanel"
codePanel.Position = Vector2.new(960, 540)
codePanel.Size = Vector2.new(350, 180)
codePanel.Pivot = Vector2.new(0.5, 0.5)
codePanel.FillColor = ColorQuad.new(40, 40, 50, 250)
codePanel.LineColor = ColorQuad.new(100, 100, 120, 255)
codePanel.LineSize = 2
codePanel.Round = 10
codePanel.Visible = false

-- Title
local codeTitle = SandboxNode.new('UITextLabel', codePanel)
codeTitle.Position = Vector2.new(175, 30)
codeTitle.Size = Vector2.new(300, 30)
codeTitle.Pivot = Vector2.new(0.5, 0.5)
codeTitle.Title = "Enter Access Code"
codeTitle.FontSize = 22
codeTitle.TitleColor = ColorQuad.new(255, 255, 255, 255)
codeTitle.TextHAlignment = 1
codeTitle.TextVAlignment = 1
codeTitle.Visible = true

-- Code input
local codeInput = SandboxNode.new('UITextInput', codePanel)
codeInput.Name = "CodeInput"
codeInput.Position = Vector2.new(25, 70)
codeInput.Size = Vector2.new(300, 40)
codeInput.Pivot = Vector2.new(0, 0)
codeInput.Title = ""
codeInput.FontSize = 24
codeInput.TitleColor = ColorQuad.new(255, 255, 255, 255)
codeInput.FillColor = ColorQuad.new(60, 60, 70, 255)
codeInput.LineColor = ColorQuad.new(120, 120, 140, 255)
codeInput.LineSize = 2
codeInput.MaxLength = 6  -- 6-digit code
codeInput.TextHAlignment = 1  -- Center text
codeInput.Visible = true

-- Submit button
local submitButton = SandboxNode.new('UIButton', codePanel)
submitButton.Position = Vector2.new(175, 130)
submitButton.Size = Vector2.new(120, 40)
submitButton.Pivot = Vector2.new(0.5, 0.5)
submitButton.Title = "Submit"
submitButton.TitleSize = 20
submitButton.TitleColor = ColorQuad.new(255, 255, 255, 255)
submitButton.FillColor = ColorQuad.new(70, 140, 200, 255)
submitButton.LineColor = ColorQuad.new(50, 120, 180, 255)
submitButton.LineSize = 2
submitButton.Round = 5
submitButton.Visible = true

local correctCode = "123456"

submitButton.Click:Connect(function()
    local enteredCode = codeInput.Title
    if enteredCode == correctCode then
        print("Access granted!")
        codePanel.Visible = false
        -- Grant access
    else
        print("Incorrect code!")
        codeInput.Title = ""  -- Clear input
        -- Show error animation
    end
end)

codeInput.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        submitButton.Click:Fire()
    end
end)
```

### Example 5: Form with Multiple Inputs

```lua
local formPanel = SandboxNode.new('UIPanel', uiRoot)
formPanel.Name = "RegistrationForm"
formPanel.Position = Vector2.new(960, 540)
formPanel.Size = Vector2.new(450, 350)
formPanel.Pivot = Vector2.new(0.5, 0.5)
formPanel.FillColor = ColorQuad.new(40, 40, 50, 240)
formPanel.LineColor = ColorQuad.new(100, 100, 120, 255)
formPanel.LineSize = 2
formPanel.Round = 10
formPanel.Visible = false

-- Title
local formTitle = SandboxNode.new('UITextLabel', formPanel)
formTitle.Position = Vector2.new(225, 30)
formTitle.Size = Vector2.new(400, 40)
formTitle.Pivot = Vector2.new(0.5, 0.5)
formTitle.Title = "Create Account"
formTitle.FontSize = 28
formTitle.TitleColor = ColorQuad.new(255, 215, 0, 255)
formTitle.TextHAlignment = 1
formTitle.TextVAlignment = 1
formTitle.Visible = true

-- Username label
local usernameLabel = SandboxNode.new('UITextLabel', formPanel)
usernameLabel.Position = Vector2.new(25, 80)
usernameLabel.Size = Vector2.new(150, 30)
usernameLabel.Title = "Username:"
usernameLabel.FontSize = 18
usernameLabel.TitleColor = ColorQuad.new(255, 255, 255, 255)
usernameLabel.TextHAlignment = 0
usernameLabel.TextVAlignment = 1
usernameLabel.Visible = true

-- Username input
local usernameInput = SandboxNode.new('UITextInput', formPanel)
usernameInput.Name = "UsernameInput"
usernameInput.Position = Vector2.new(25, 115)
usernameInput.Size = Vector2.new(400, 40)
usernameInput.Title = ""
usernameInput.FontSize = 18
usernameInput.TitleColor = ColorQuad.new(255, 255, 255, 255)
usernameInput.FillColor = ColorQuad.new(60, 60, 70, 255)
usernameInput.LineColor = ColorQuad.new(120, 120, 140, 255)
usernameInput.LineSize = 2
usernameInput.MaxLength = 20
usernameInput.Visible = true

-- Email label
local emailLabel = SandboxNode.new('UITextLabel', formPanel)
emailLabel.Position = Vector2.new(25, 170)
emailLabel.Size = Vector2.new(150, 30)
emailLabel.Title = "Email:"
emailLabel.FontSize = 18
emailLabel.TitleColor = ColorQuad.new(255, 255, 255, 255)
emailLabel.TextHAlignment = 0
emailLabel.TextVAlignment = 1
emailLabel.Visible = true

-- Email input
local emailInput = SandboxNode.new('UITextInput', formPanel)
emailInput.Name = "EmailInput"
emailInput.Position = Vector2.new(25, 205)
emailInput.Size = Vector2.new(400, 40)
emailInput.Title = ""
emailInput.FontSize = 18
emailInput.TitleColor = ColorQuad.new(255, 255, 255, 255)
emailInput.FillColor = ColorQuad.new(60, 60, 70, 255)
emailInput.LineColor = ColorQuad.new(120, 120, 140, 255)
emailInput.LineSize = 2
emailInput.MaxLength = 50
emailInput.Visible = true

-- Register button
local registerButton = SandboxNode.new('UIButton', formPanel)
registerButton.Position = Vector2.new(225, 290)
registerButton.Size = Vector2.new(200, 45)
registerButton.Pivot = Vector2.new(0.5, 0.5)
registerButton.Title = "Register"
registerButton.TitleSize = 22
registerButton.TitleColor = ColorQuad.new(255, 255, 255, 255)
registerButton.FillColor = ColorQuad.new(70, 140, 70, 255)
registerButton.LineColor = ColorQuad.new(50, 120, 50, 255)
registerButton.LineSize = 2
registerButton.Round = 8
registerButton.Visible = true

registerButton.Click:Connect(function()
    local username = usernameInput.Title
    local email = emailInput.Title

    if username ~= "" and email ~= "" then
        print("Registering:", username, email)
        -- Validate and submit registration
        formPanel.Visible = false
    else
        print("Please fill in all fields!")
    end
end)
```

---

## Input Validation Examples

### Validate Input Length

```lua
input.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        local text = input.Title
        if string.len(text) < 3 then
            print("Input too short! Minimum 3 characters")
            input.LineColor = ColorQuad.new(255, 0, 0, 255)  -- Red border
        else
            print("Valid input:", text)
            input.LineColor = ColorQuad.new(0, 255, 0, 255)  -- Green border
        end
    end
end)
```

### Validate Numeric Input

```lua
input.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        local text = input.Title
        local number = tonumber(text)
        if number then
            print("Valid number:", number)
        else
            print("Please enter a valid number!")
            input.Title = ""  -- Clear invalid input
        end
    end
end)
```

---

## Quick Reference

### Minimal Text Input (JSON)
```json
{
  "ClassType": "UITextInput",
  "realNodeName": "MyInput",
  "reflex": [
    {"Name": "MyInput"},
    {"Size": [300, 40]},
    {"Title": ""},
    {"FontSize": 20},
    {"MaxLength": 50},
    {"Visible": true},
    {"LayoutHRelation": 0},
    {"LayoutVRelation": 0},
    {"HRelationLength": 400},
    {"VRelationLength": 300}
  ]
}
```

### Minimal Text Input (Lua)
```lua
local input = SandboxNode.new('UITextInput', uiRoot)
input.Position = Vector2.new(400, 300)
input.Size = Vector2.new(300, 40)
input.Title = ""
input.FontSize = 20
input.MaxLength = 50
input.Visible = true

input.NotifyTouchReturn:Connect(function(onReturn)
    if onReturn then
        print("Input:", input.Title)
    end
end)
```

---

## Important Notes

⚠️ **Access from PlayerGui**: Remember to access UI from `game.Players.LocalPlayer.PlayerGui` at runtime, not from StarterGui
✅ **MaxLength**: Set `MaxLength` to limit input characters (0 = unlimited)
✅ **Validation**: Always validate user input before processing
✅ **NotifyTouchReturn**: Use this event to detect when input is complete (Enter key or focus lost)
✅ **Clear After Use**: Reset `input.Title = ""` after processing input if needed
✅ **Placeholder Text**: Set initial `Title` to placeholder text (e.g., "Type here...")
✅ **Visual Feedback**: Change border color to indicate valid/invalid input

---

## See Also

- [Common UI Knowledge](common-ui.md) - Fundamental concepts, colors, runtime access
- [UI Layout System Guide](common-ui-layout.md) - Responsive positioning, layout patterns, multi-resolution support
- [How to Add Button](how-to-add-button.md)
- [How to Add TextLabel](how-to-add-textlabel.md)
- [How to Add Panel](how-to-add-panel.md)
