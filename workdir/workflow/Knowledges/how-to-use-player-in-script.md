# How to Use Players in MiniWorld Studio Scripts

## Overview

This guide covers everything you need to know about working with players in MiniWorld Studio, including the Players service API, player objects, properties, events, and common patterns. Understanding the player system is essential for creating multiplayer games, tracking player data, and handling player interactions.

**Common Use Cases**: Player management, leaderboards, scoring systems, player data persistence, multiplayer mechanics, chat systems, player UI, character control

---

## Players Service API

The Players service is the core interface for accessing and managing players in your game.

### Getting the Players Service

```lua
local Players = game:GetService("Players")
```

---

## 🚨 CRITICAL: Players API vs Roblox

⚠️ **MiniWorld Studio uses DIFFERENT methods than Roblox!**

| ❌ Roblox (Don't Use) | ✅ MiniWorld Studio (Use) |
|---------------------|------------------------|
| `Players:GetPlayerByUserId()` | `Players:GetPlayerFromUserId()` |
| `Players:GetPlayers()` returns player objects | `Players:GetPlayers()` returns player objects ✅ Same |
| `player.Name` for display name | `player.Nickname` for display name |
| `player.UserId` for ID | `player.UserId` for ID ✅ Same |

**Key Difference**: The method name is `GetPlayerFromUserId()` (not `GetPlayerByUserId()`)

---

## Getting Players

### 1. Get All Players

Returns an array of all player objects currently in the game.

```lua
local Players = game:GetService("Players")
local allPlayers = Players:GetPlayers()

print("Total players:", #allPlayers)

for _, player in ipairs(allPlayers) do
    print("Player:", player.Nickname, "ID:", player.UserId)
end
```

**Returns**: `table` - Array of player objects
**Context**: Works on both client and server
**Use cases**: Leaderboards, player lists, broadcast messages

### 2. Get Player by UserId

Gets a specific player object by their unique user ID.

```lua
local Players = game:GetService("Players")
local targetPlayer = Players:GetPlayerFromUserId(12345678)

if targetPlayer then
    print("Found player:", targetPlayer.Nickname)
else
    warn("Player not found!")
end
```

**Method**: `Players:GetPlayerFromUserId(userId)`
**Parameters**: `userId` (number) - The player's unique ID
**Returns**: `player object` or `nil` if not found
**Context**: Works on both client and server

**Alternative Method** (also valid):
```lua
local targetPlayer = Players:GetPlayerByUserId(12345678)
```

### 3. Get Local Player (Client Only)

Gets the player object for the local client.

```lua
-- Client-side LocalScript only
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

if localPlayer then
    print("I am:", localPlayer.Nickname)
    print("My ID:", localPlayer.UserId)
else
    warn("LocalPlayer is nil (running on server?)")
end
```

**Property**: `Players.LocalPlayer`
**Returns**: `player object` on client, `nil` on server
**Context**: ✅ Client only, ❌ Returns nil on server
**Use cases**: Client-side UI, local input handling, first-person systems

---

## Player Object Properties

Once you have a player object, you can access these key properties:

### Core Properties

```lua
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Unique identifier (number)
local userId = player.UserId
print("User ID:", userId)  -- e.g., 12345678

-- Display name (string)
local displayName = player.Nickname
print("Display Name:", displayName)  -- e.g., "Alice"

-- Object name (string)
local objectName = player.Name
print("Object Name:", objectName)  -- Usually same as UserId

-- Character object
local character = player.Character
if character then
    print("Character exists")
end
```

### Property Reference Table

| Property | Type | Description | Use For |
|----------|------|-------------|---------|
| **UserId** | number | Unique player identifier | Data storage keys, player identification |
| **Nickname** | string | Player's display name | UI display, chat, leaderboards |
| **Name** | string | Player object name | Object hierarchy (rarely used) |
| **Character** | object | Player's character in world | Character manipulation, position, health |

### Important: UserId vs Nickname

```lua
-- ✅ CORRECT: Use UserId as data key
local playerData = {}
playerData[player.UserId] = {
    score = 100,
    coins = 50
}

-- ✅ CORRECT: Use Nickname for display
local label = SandboxNode.new('UITextLabel', parent)
label.Title = player.Nickname .. ": 100 points"

-- ❌ WRONG: Don't use Nickname as key (can change/duplicate)
playerData[player.Nickname] = { score = 100 }  -- Bad practice!
```

**Rule**:
- **UserId** = Permanent unique ID → Use for data storage
- **Nickname** = Display name → Use for UI/messages

---

## Player Events

The Players service provides events that fire when players join or leave the game.

### PlayerAdded

Fires when a player joins the game.

```lua
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    print(player.Nickname .. " joined the game!")
    print("User ID:", player.UserId)

    -- Initialize player data
    initializePlayerData(player.UserId)

    -- Send welcome message
    sendWelcomeMessage(player)
end)
```

**Parameters**: `player` (player object)
**Context**: Fires on both client and server
**Use cases**: Player data initialization, welcome messages, spawn logic

### PlayerRemoving

Fires when a player is about to leave the game (before removal).

```lua
local Players = game:GetService("Players")

Players.PlayerRemoving:Connect(function(player)
    print(player.Nickname .. " is leaving...")

    -- Save player data before they leave
    savePlayerData(player.UserId)

    -- Cleanup
    cleanupPlayerResources(player.UserId)
end)
```

**Parameters**: `player` (player object)
**Context**: Fires on both client and server
**Use cases**: Data persistence, cleanup, goodbye messages

### Event Best Practices

```lua
-- ✅ GOOD: Extract UserId immediately for data operations
Players.PlayerAdded:Connect(function(player)
    local userId = player.UserId
    local displayName = player.Nickname or ("Player " .. tostring(userId))

    print(displayName .. " joined!")

    -- Use userId for data storage
    playerScores[userId] = 0
end)

-- ❌ BAD: Trying to concatenate player object
Players.PlayerAdded:Connect(function(player)
    print("Player joined: " .. player)  -- ERROR: Can't concatenate userdata
end)
```

---

## Common Patterns

### Pattern 1: Player Iterator with Names

```lua
local Players = game:GetService("Players")

function printAllPlayers()
    local allPlayers = Players:GetPlayers()

    print("=== Players in Game ===")
    for index, player in ipairs(allPlayers) do
        local userId = player.UserId
        local displayName = player.Nickname or ("Player " .. tostring(userId))

        print(string.format("%d. %s (ID: %d)", index, displayName, userId))
    end
    print("Total:", #allPlayers)
end
```

### Pattern 2: Leaderboard Data Structure

```lua
local LeaderboardSystem = {}
LeaderboardSystem.playerScores = {}

-- Add score to player
function LeaderboardSystem:addScore(userId, points)
    self.playerScores[userId] = (self.playerScores[userId] or 0) + points
end

-- Get sorted leaderboard
function LeaderboardSystem:getSortedLeaderboard()
    local Players = game:GetService("Players")
    local allPlayers = Players:GetPlayers()
    local leaderboardData = {}

    for _, player in ipairs(allPlayers) do
        local userId = player.UserId
        local displayName = player.Nickname or ("Player " .. tostring(userId))
        local score = self.playerScores[userId] or 0

        table.insert(leaderboardData, {
            userId = userId,
            name = displayName,
            score = score
        })
    end

    -- Sort by score (highest first)
    table.sort(leaderboardData, function(a, b)
        return a.score > b.score
    end)

    return leaderboardData
end
```

### Pattern 3: Find Player by UserId Function

```lua
function getPlayerById(userId)
    local Players = game:GetService("Players")
    local allPlayers = Players:GetPlayers()

    for _, player in ipairs(allPlayers) do
        if player.UserId == userId then
            return player
        end
    end

    return nil  -- Player not found
end

-- Usage
local targetPlayer = getPlayerById(12345678)
if targetPlayer then
    print("Found:", targetPlayer.Nickname)
end
```

### Pattern 4: Player Data Initialization

```lua
local PlayerDataSystem = {}
PlayerDataSystem.playerData = {}

function PlayerDataSystem:init()
    local Players = game:GetService("Players")

    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:onPlayerJoined(player)
    end

    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)

    -- Handle leaving players
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeaving(player)
    end)
end

function PlayerDataSystem:onPlayerJoined(player)
    local userId = player.UserId
    local displayName = player.Nickname or ("Player " .. tostring(userId))

    print(displayName .. " joined!")

    -- Initialize default data
    self.playerData[userId] = {
        name = displayName,
        score = 0,
        coins = 100,
        level = 1,
        joinTime = os.time()
    }
end

function PlayerDataSystem:onPlayerLeaving(player)
    local userId = player.UserId
    local displayName = player.Nickname or ("Player " .. tostring(userId))

    print(displayName .. " is leaving...")

    -- Save data (in real game, save to database)
    self:savePlayerData(userId)

    -- Cleanup
    self.playerData[userId] = nil
end

function PlayerDataSystem:savePlayerData(userId)
    local data = self.playerData[userId]
    if data then
        print("Saving data for user", userId)
        -- Save to database/storage here
    end
end
```

---

## Client vs Server Differences

### Client-Side (LocalScript)

```lua
-- In StartPlayer/StarterPlayerScripts/

local Players = game:GetService("Players")

-- ✅ LocalPlayer is available
local localPlayer = Players.LocalPlayer
print("I am:", localPlayer.Nickname)

-- ✅ Can get all players
local allPlayers = Players:GetPlayers()
print("Total players:", #allPlayers)

-- ✅ Events work
Players.PlayerAdded:Connect(function(player)
    print(player.Nickname .. " joined!")
end)
```

### Server-Side (Script)

```lua
-- In ServerScriptService/

local Players = game:GetService("Players")

-- ❌ LocalPlayer is nil on server
local localPlayer = Players.LocalPlayer
print(localPlayer)  -- nil

-- ✅ Can get all players
local allPlayers = Players:GetPlayers()
print("Total players:", #allPlayers)

-- ✅ Events work (and are more reliable)
Players.PlayerAdded:Connect(function(player)
    print(player.Nickname .. " joined!")
    -- Initialize server-side data
end)
```

### Key Differences

| Feature | Client (LocalScript) | Server (Script) |
|---------|---------------------|-----------------|
| `Players.LocalPlayer` | ✅ Available | ❌ Returns nil |
| `Players:GetPlayers()` | ✅ Works | ✅ Works |
| `Players:GetPlayerFromUserId()` | ✅ Works | ✅ Works |
| `PlayerAdded` event | ✅ Fires | ✅ Fires (more reliable) |
| `PlayerRemoving` event | ✅ Fires | ✅ Fires (more reliable) |
| Player data authority | ❌ Can be spoofed | ✅ Authoritative |

**Best Practice**: Handle authoritative game logic (scores, inventory, etc.) on the **server**, use client for **UI and local feedback**.

---

## Real-World Examples from Sample Code

### Example 1: Getting Player Name

**Source**: `PromptTpl/samplecode/BridgeBattle/ServiceNodes/ServerScriptService/ServerInit/PlayerManager/SPlayer.lua:129-135`

```lua
function SPlayer:GetName()
    local Players = game:GetService("Players")
    local player = Players:GetPlayerByUserId(self.userId)

    if player then
        return player.Nickname
    end

    return "Unknown"
end
```

### Example 2: Player Data Management System

**Source**: `PromptTpl/samplecode/sgfgamedemo2/ServiceNodes/ServerScriptService/systems/PlayerDataSystem.lua:137-146`

```lua
function PlayerDataSystem:init()
    local Players = game:GetService("Players")

    if Players then
        Players.PlayerAdded:Connect(function(player)
            self:onPlayerJoined(player)
        end)

        Players.PlayerRemoving:Connect(function(player)
            self:onPlayerLeaving(player)
        end)
    end
end
```

### Example 3: Iterating All Players

**Source**: `PromptTpl/samplecode/sgfgamedemo2/ServiceNodes/ServerScriptService/systems/PlayerDataSystem.lua:608-616`

```lua
function PlayerDataSystem:getPlayerById(playerId)
    local Players = game:GetService("Players")

    for _, player in pairs(Players:GetPlayers()) do
        if player.UserId == playerId then
            return player
        end
    end

    return nil
end
```

### Example 4: Client-Side Player Access

**Source**: `PromptTpl/samplecode/xplants/ServiceNodes/StartPlayer/StarterPlayerScripts/UI/BuyGiftPanel.lua:10`

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local uin = localPlayer.UserId

-- Later in the code (line 66):
node.txtName.Title = player.Nickname
```

### Example 5: Player Character Access

**Source**: `PromptTpl/samplecode/xplants/ServiceNodes/MainStorage/PlayerModule.lua`

```lua
local Players = game:GetService("Players")
local playerService = game:GetService("Players")

local player = playerService:GetPlayerByUserId(uin).Character
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Wrong Method Name

```lua
-- ❌ WRONG: GetPlayerByUIN doesn't exist
local player = Players:GetPlayerByUIN(userId)  -- ERROR!

-- ✅ CORRECT: Use GetPlayerFromUserId
local player = Players:GetPlayerFromUserId(userId)

-- ✅ ALSO CORRECT: GetPlayerByUserId also works
local player = Players:GetPlayerByUserId(userId)
```

### ❌ Mistake 2: Concatenating Player Object

```lua
-- ❌ WRONG: Can't concatenate userdata
local player = Players.LocalPlayer
print("Player: " .. player)  -- ERROR: attempt to concatenate userdata

-- ✅ CORRECT: Use properties
print("Player: " .. player.Nickname)
print("ID: " .. tostring(player.UserId))
```

### ❌ Mistake 3: Using Nickname as Data Key

```lua
-- ❌ WRONG: Nicknames can change or be duplicated
local playerData = {}
playerData[player.Nickname] = { score = 100 }  -- Bad!

-- ✅ CORRECT: Use UserId as key
playerData[player.UserId] = { score = 100 }
```

### ❌ Mistake 4: Assuming GetPlayers() Returns IDs

```lua
-- ❌ WRONG: GetPlayers() returns player objects, not IDs
local allPlayers = Players:GetPlayers()
for _, playerId in ipairs(allPlayers) do
    print("ID: " .. playerId)  -- Wrong! This is a player object
end

-- ✅ CORRECT: Extract UserId from player object
for _, player in ipairs(allPlayers) do
    print("ID:", player.UserId)
    print("Name:", player.Nickname)
end
```

### ❌ Mistake 5: Using LocalPlayer on Server

```lua
-- ❌ WRONG: LocalPlayer is nil on server
-- In ServerScriptService/ServerInit.lua
local player = Players.LocalPlayer  -- nil!
print(player.Nickname)  -- ERROR!

-- ✅ CORRECT: Use PlayerAdded event on server
Players.PlayerAdded:Connect(function(player)
    print(player.Nickname .. " joined")
end)
```

### ❌ Mistake 6: Event Parameter Confusion

```lua
-- ❌ WRONG: Assuming event passes UserId
Players.PlayerAdded:Connect(function(userId)
    print("Player:", userId)  -- This is actually a player object!
    playerData[userId] = {}  -- Wrong key!
end)

-- ✅ CORRECT: Event passes player object
Players.PlayerAdded:Connect(function(player)
    local userId = player.UserId
    print("Player:", player.Nickname, "ID:", userId)
    playerData[userId] = {}  -- Correct key
end)
```

---

## Best Practices

### 1. Always Use UserId for Data Storage

```lua
-- ✅ GOOD: UserId is permanent and unique
local playerScores = {}

Players.PlayerAdded:Connect(function(player)
    playerScores[player.UserId] = 0  -- Use UserId as key
end)

function addScore(userId, points)
    playerScores[userId] = (playerScores[userId] or 0) + points
end
```

### 2. Handle Nil Cases

```lua
-- ✅ GOOD: Always check for nil
local player = Players:GetPlayerFromUserId(12345)

if player then
    print("Found:", player.Nickname)
else
    warn("Player not found or not in game")
end

-- ✅ GOOD: Provide fallback for Nickname
local displayName = player.Nickname or ("Player " .. tostring(player.UserId))
```

### 3. Initialize Existing Players

```lua
-- ✅ GOOD: Handle players who joined before script loaded
function initializeSystem()
    local Players = game:GetService("Players")

    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerJoined(player)
    end

    -- Handle new players
    Players.PlayerAdded:Connect(onPlayerJoined)
end
```

### 4. Clean Up on Player Leave

```lua
-- ✅ GOOD: Always clean up resources
local playerData = {}

Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId

    -- Save data before cleanup
    savePlayerData(userId)

    -- Remove from memory
    playerData[userId] = nil
end)
```

### 5. Use Descriptive Variable Names

```lua
-- ✅ GOOD: Clear variable names
for _, player in ipairs(Players:GetPlayers()) do
    local userId = player.UserId
    local displayName = player.Nickname
    print(displayName, userId)
end

-- ❌ BAD: Confusing variable names
for _, p in ipairs(Players:GetPlayers()) do
    local id = p.UserId
    print(p.Nickname, id)  -- What is p? What is id?
end
```

### 6. Server Authority for Important Data

```lua
-- ✅ GOOD: Server validates and manages scores
-- Server Script
local playerScores = {}

RemoteEvent.OnServerEvent:Connect(function(player, action, data)
    local userId = player.UserId

    if action == "collect_coin" then
        -- Validate on server
        if isValidCoinCollection(data.coinId) then
            playerScores[userId] = (playerScores[userId] or 0) + 10

            -- Notify all clients
            RemoteEvent:FireAllClients("score_update", userId, playerScores[userId])
        end
    end
end)

-- ❌ BAD: Trusting client for scores
-- Client LocalScript sends: "I have 1000000 points!"
RemoteEvent:FireServer("set_score", 1000000)  -- Can be exploited!
```

---

## Complete Reference

### Players Service Methods

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `GetPlayers()` | None | `table` | Gets all player objects |
| `GetPlayerFromUserId(userId)` | `userId: number` | `player` or `nil` | Gets player by user ID |
| `GetPlayerByUserId(userId)` | `userId: number` | `player` or `nil` | Alternative method (same as above) |
| `GetPlayerCount()` | None | `number` | Gets total player count |
| `GetPlayerByIndex(index)` | `index: number` | `player` or `nil` | Gets player by list index |
| `FindFirstChild(name)` | `name: string` | `player` or `nil` | Finds player by object name |

### Player Object Properties

| Property | Type | Description |
|----------|------|-------------|
| `UserId` | `number` | Unique player identifier |
| `Nickname` | `string` | Player display name |
| `Name` | `string` | Player object name |
| `Character` | `object` | Player's character object |

### Player Events

| Event | Parameters | Description |
|-------|-----------|-------------|
| `PlayerAdded` | `player` | Fires when player joins |
| `PlayerRemoving` | `player` | Fires when player is leaving (before removal) |
| `PlayerRemoved` | `player` | Fires after player fully removed |

---

## Quick Start Checklist

Working with players? Follow these steps:

1. ✅ Get Players service: `local Players = game:GetService("Players")`
2. ✅ Use `GetPlayers()` for all players or `GetPlayerFromUserId()` for specific player
3. ✅ Extract `player.UserId` for data storage
4. ✅ Use `player.Nickname` for display in UI
5. ✅ Handle `PlayerAdded` and `PlayerRemoving` events
6. ✅ Always check for `nil` when getting players by ID
7. ✅ Use server-side scripts for authoritative data
8. ✅ Clean up player data when they leave

---

## Quick Reference Card

```lua
-- Get Players service
local Players = game:GetService("Players")

-- Get all players
local allPlayers = Players:GetPlayers()
for _, player in ipairs(allPlayers) do
    print(player.Nickname, player.UserId)
end

-- Get specific player
local player = Players:GetPlayerFromUserId(12345)
if player then
    print("Found:", player.Nickname)
end

-- Get local player (client only)
local localPlayer = Players.LocalPlayer

-- Player events
Players.PlayerAdded:Connect(function(player)
    local userId = player.UserId
    local name = player.Nickname or ("Player " .. tostring(userId))
    print(name .. " joined!")
end)

Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    print("Player", userId, "leaving")
end)

-- Data storage pattern
local playerData = {}
playerData[player.UserId] = {  -- Use UserId as key
    name = player.Nickname,     -- Store Nickname for display
    score = 0
}
```

---

## See Also

- [how-to-create-script.md](./how-to-create-script.md) - Script types and structure
- [how-to-use-remote-events.md](../how-to-use-remote-events.md) - Client-server communication
- [common-script-update.md](./common-script-update.md) - Update mechanisms and timers

---

**Created**: 2025-10-23
**Version**: 1.0.0
**Based on**: MiniWorld Studio API documentation (refDoc/Documents/Actor/) and sample code analysis (samplecode/xplants, sgfgamedemo2, BridgeBattle)
