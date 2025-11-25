# How to Use Network Communication in MiniWorld Studio SGF

## Overview

MiniWorld Studio uses a **Request/Response** pattern for client-server communication via the NetworkHelper system. This guide shows you how to set up network message handlers and send messages between client and server based on the rpg-gamedemo implementation.

**Common Use Cases**: Player data sync, combat actions, inventory updates, scene transitions, chat messages

---

## Network Communication Patterns

### Two Main Patterns

1. **Request/Response** (Synchronous): Client requests → Server responds
2. **Broadcast/Notify** (Asynchronous): Server sends → All/specific clients receive

---

## Protocol Definition File

### Create Protocol.lua

**Location**: `MainStorage/Framework/Runtime/Protocol.lua`

```lua
--[[
    Protocol.lua - Centralized network message ID definitions

    Convention:
    - Client messages (requests): 100-999
    - Server messages (responses/notifications): 1000-1999
]]

local Protocol = {
    -- Client → Server Messages (Requests)
    ClientMSGID = {
        -- Player System (100-199)
        PLAYER_GET_DATA_REQ = 100,
        PLAYER_CREATE_CHARACTER_REQ = 101,
        PLAYER_UPDATE_STATS_REQ = 102,

        -- Combat System (200-299)
        COMBAT_START_REQ = 200,
        COMBAT_ACTION_REQ = 201,
        COMBAT_FLEE_REQ = 202,

        -- Scene System (300-399)
        SCENE_CHANGE_REQ = 300,
        PORTAL_INTERACT_REQ = 301,

        -- Add your game-specific messages here
    },

    -- Server → Client Messages (Responses & Notifications)
    ServerMSGID = {
        -- Player System (1000-1099)
        PLAYER_GET_DATA_RSP = 1000,
        PLAYER_CREATE_CHARACTER_RSP = 1001,
        PLAYER_DATA_UPDATE_NOTIFY = 1010,
        PLAYER_HEALTH_UPDATE_NOTIFY = 1011,
        PLAYER_LEVEL_UP_NOTIFY = 1012,

        -- Combat System (1100-1199)
        COMBAT_START_RSP = 1100,
        COMBAT_ACTION_RSP = 1101,
        COMBAT_DAMAGE_NOTIFY = 1110,
        COMBAT_END_NOTIFY = 1111,

        -- Scene System (1200-1299)
        SCENE_CHANGE_RSP = 1200,
        SCENE_CHANGED_NOTIFY = 1201,

        -- System Messages (1900-1999)
        ERROR_NOTIFY = 1900,
        MESSAGE_NOTIFY = 1901,
    }
}

-- Helper: Get message name from ID (debugging)
function Protocol.getMessageName(msgId)
    for category, messages in pairs(Protocol) do
        if type(messages) == "table" then
            for name, id in pairs(messages) do
                if id == msgId then
                    return category .. "." .. name
                end
            end
        end
    end
    return "UNKNOWN_" .. tostring(msgId)
end

return Protocol
```

**JSON**: `Protocol.json`
```json
{
  "ClassType": "ModuleScript",
  "attribute": [],
  "flags": 0,
  "realNodeName": "Protocol",
  "reflex": [
    {"Name": "Protocol"},
    {"Tag": 0},
    {"Enabled": true}
  ]
}
```

---

## Server-Side Network Handlers

### Step 1: Register as Network Object

```lua
function PlayerSystemServer:Init()
    -- Register network handlers
    self:registerNetworkHandlers()

    return true
end

function PlayerSystemServer:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    -- Import protocol
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Register request handlers
    self:OnRequest(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, function(userId, msgid, data)
        return self:handleGetPlayerData(userId, data)
    end)

    self:OnRequest(Protocol.ClientMSGID.PLAYER_CREATE_CHARACTER_REQ, function(userId, msgid, data)
        return self:handleCreateCharacter(userId, data)
    end)
end
```

### Step 2: Handle Requests

```lua
--[[
    Handle client request for player data
    @param userId (number) - Player's user ID
    @param data (table) - Request data from client
    @return (table) - Response data
]]
function PlayerSystemServer:handleGetPlayerData(userId, data)
    self.log:debug("[PlayerSystemServer] Get player data", {userId = userId})

    local playerData = self.data.players[userId]

    if playerData then
        return {
            success = true,
            playerData = {
                userId = playerData.userId,
                name = playerData.name,
                level = playerData.level,
                exp = playerData.exp,
                health = playerData.health,
                mana = playerData.mana
            }
        }
    else
        return {
            success = false,
            error = "Player data not found"
        }
    end
end

function PlayerSystemServer:handleCreateCharacter(userId, data)
    self.log:info("[PlayerSystemServer] Create character", {
        userId = userId,
        name = data.characterName
    })

    -- Validate input
    if not data.characterName or data.characterName == "" then
        return {
            success = false,
            error = "Invalid character name"
        }
    end

    -- Create player data
    local playerData = {
        userId = userId,
        name = data.characterName,
        classType = data.classType or "Warrior",
        level = 1,
        exp = 0,
        health = 100,
        mana = 50
    }

    self.data.players[userId] = playerData

    -- Broadcast to all clients (state sync)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:Broadcast(Protocol.ServerMSGID.PLAYER_DATA_UPDATE_NOTIFY, {
        userId = userId,
        playerData = playerData
    })

    -- Return success response to requesting client
    return {
        success = true,
        playerData = playerData
    }
end
```

### Step 3: Send Notifications

```lua
-- Notify specific client
function PlayerSystemServer:notifyPlayerHealthChanged(userId, currentHp, maxHp)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallClient(userId, Protocol.ServerMSGID.PLAYER_HEALTH_UPDATE_NOTIFY, {
        currentHp = currentHp,
        maxHp = maxHp
    })
end

-- Broadcast to all clients
function PlayerSystemServer:notifyPlayerLevelUp(userId, newLevel)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:Broadcast(Protocol.ServerMSGID.PLAYER_LEVEL_UP_NOTIFY, {
        userId = userId,
        newLevel = newLevel
    })
end
```

---

## Client-Side Network Handlers

### Step 1: Register as Network Object

```lua
function PlayerSystemClient:Init()
    -- Register network handlers
    self:registerNetworkHandlers()

    return true
end

function PlayerSystemClient:registerNetworkHandlers()
    -- Register this system as a network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    -- Import protocol
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Listen for server responses
    self:OnResponse(Protocol.ServerMSGID.PLAYER_GET_DATA_RSP, function(msgid, data)
        self:onGetPlayerDataResponse(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.PLAYER_DATA_UPDATE_NOTIFY, function(msgid, data)
        self:onPlayerDataUpdated(data)
    end)

    self:OnResponse(Protocol.ServerMSGID.PLAYER_LEVEL_UP_NOTIFY, function(msgid, data)
        self:onPlayerLevelUp(data)
    end)
end
```

### Step 2: Send Requests

```lua
-- Request player data from server
function PlayerSystemClient:requestPlayerData()
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, {})
end

-- Request character creation
function PlayerSystemClient:requestCreateCharacter(characterName, classType)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.PLAYER_CREATE_CHARACTER_REQ, {
        characterName = characterName,
        classType = classType
    })
end
```

### Step 3: Handle Responses

```lua
-- Handle server response
function PlayerSystemClient:onGetPlayerDataResponse(data)
    if data.success then
        self.log:info("[PlayerSystemClient] Received player data")
        self.data.localPlayerData = data.playerData

        -- Update UI
        self:updateUI()
    else
        self.log:error("[PlayerSystemClient] Failed to get player data:", data.error)
    end
end

-- Handle server notification
function PlayerSystemClient:onPlayerDataUpdated(data)
    self.log:debug("[PlayerSystemClient] Player data updated", data)

    if data.playerData then
        self.data.localPlayerData = data.playerData
        self:updateUI()
    end
end

function PlayerSystemClient:onPlayerLevelUp(data)
    self.log:info("[PlayerSystemClient] Player leveled up!", data)

    -- Show level up effect
    if self.sgf.panelManager then
        local panel = self.sgf.panelManager:getPanel("PlayerStatsPanel")
        if panel then
            panel:showLevelUpAnimation(data.newLevel)
        end
    end
end
```

---

## NetworkHelper API Reference

### Server Methods

```lua
-- Register system as network object (call once in Init)
NetworkHelper:RegisterNetObj(self)

-- Handle client requests (returns data to client)
self:OnRequest(msgid, function(userId, msgid, data)
    -- Process request
    return {success = true, result = ...}
end)

-- Send message to specific client
self:CallClient(userId, msgid, data)

-- Broadcast message to all clients
self:Broadcast(msgid, data)
```

### Client Methods

```lua
-- Register system as network object (call once in Init)
NetworkHelper:RegisterNetObj(self)

-- Send request to server
self:CallServer(msgid, data)

-- Listen for server responses/notifications
self:OnResponse(msgid, function(msgid, data)
    -- Handle response
end)
```

---

## Complete Example: Door System

### Server System

```lua
local DoorSystemServer = {}

function DoorSystemServer:registerNetworkHandlers()
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Handle door open request
    self:OnRequest(Protocol.ClientMSGID.DOOR_OPEN_REQ, function(userId, msgid, data)
        return self:handleOpenDoorRequest(userId, data)
    end)
end

function DoorSystemServer:handleOpenDoorRequest(userId, data)
    local doorId = data.doorId
    local door = self.data.doors[doorId]

    if not door then
        return {success = false, error = "Door not found"}
    end

    if door.isLocked then
        return {success = false, error = "Door is locked"}
    end

    -- Open door
    door.isOpen = true

    -- Broadcast to all clients
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:Broadcast(Protocol.ServerMSGID.DOOR_OPENED_NOTIFY, {
        doorId = doorId,
        openedBy = userId
    })

    return {success = true}
end
```

### Client System

```lua
local DoorSystemClient = {}

function DoorSystemClient:registerNetworkHandlers()
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Listen for door opened notifications
    self:OnResponse(Protocol.ServerMSGID.DOOR_OPENED_NOTIFY, function(msgid, data)
        self:onDoorOpened(data)
    end)
end

function DoorSystemClient:requestOpenDoor(doorId)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    self:CallServer(Protocol.ClientMSGID.DOOR_OPEN_REQ, {
        doorId = doorId
    })
end

function DoorSystemClient:onDoorOpened(data)
    self.log:info("[DoorSystemClient] Door opened", data)

    -- Play animation
    local door = self.data.doors[data.doorId]
    if door then
        self:playDoorOpenAnimation(door)
    end
end
```

---

## Common Patterns

### Pattern 1: Request with Callback

```lua
-- Client sends request with callback
function PlayerSystemClient:getPlayerDataWithCallback(callback)
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    -- Send request
    self:CallServer(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, {})

    -- Store callback (will be called when response arrives)
    self.pendingCallbacks = self.pendingCallbacks or {}
    table.insert(self.pendingCallbacks, callback)
end

function PlayerSystemClient:onGetPlayerDataResponse(data)
    -- Execute callbacks
    for _, callback in ipairs(self.pendingCallbacks or {}) do
        callback(data)
    end
    self.pendingCallbacks = {}
end
```

### Pattern 2: Cooldown on Requests

```lua
-- Client: Rate limiting
function PlayerSystemClient:requestPlayerData()
    local now = os.time()

    if self.lastRequestTime and (now - self.lastRequestTime) < 1 then
        self.log:warn("[PlayerSystemClient] Request cooldown active")
        return
    end

    self.lastRequestTime = now

    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)
    self:CallServer(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, {})
end
```

### Pattern 3: Validation on Server

```lua
-- Server: Always validate input
function PlayerSystemServer:handlePlayerAction(userId, data)
    -- Validate player exists
    local player = Players:GetPlayerFromUserId(userId)
    if not player then
        return {success = false, error = "Invalid player"}
    end

    -- Validate data structure
    if not data.actionType or not data.targetId then
        return {success = false, error = "Missing required fields"}
    end

    -- Validate authorization
    if not self:canPerformAction(userId, data.actionType) then
        return {success = false, error = "Not authorized"}
    end

    -- Process action
    return {success = true}
end
```

---

## Best Practices

### 1. Always Use Protocol IDs

```lua
-- ✅ GOOD: Use Protocol constants
local Protocol = require(...Protocol)
self:CallServer(Protocol.ClientMSGID.PLAYER_GET_DATA_REQ, {})

-- ❌ BAD: Magic numbers
self:CallServer(100, {})
```

### 2. Validate on Server

```lua
-- ✅ GOOD: Server validates everything
function Server:handleRequest(userId, data)
    if not data.actionType then
        return {success = false, error = "Invalid data"}
    end

    if not self:isValidAction(userId, data.actionType) then
        return {success = false, error = "Invalid action"}
    end

    -- Process
    return {success = true}
end
```

### 3. Use Structured Responses

```lua
-- ✅ GOOD: Consistent response structure
return {
    success = true,
    data = {...},
    timestamp = os.time()
}

-- ❌ BAD: Inconsistent structure
return {...}  -- Is this success or failure?
```

---

## See Also

- [how-to-create-business-system.md](./how-to-create-business-system.md) - Creating systems
- [how-to-use-event-bus.md](./how-to-use-event-bus.md) - Event-driven communication
- [how-to-setup-sgf-framework.md](./how-to-setup-sgf-framework.md) - Framework setup

---

**Created**: 2025-10-31
**Version**: 1.0.0
**Based on**: rpg-gamedemo sample and scene-workflow-stage-4.md
