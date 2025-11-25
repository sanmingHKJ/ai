# How to Implement Player Teleport Action in MiniWorld Studio

## Overview

The `teleport_player` action allows instant transportation of players to specific locations in your game world. This is essential for respawn systems, checkpoints, portals, cutscene transitions, and fast travel mechanics.

**Common Use Cases**: Respawn after death, checkpoint activation, portal transportation, cutscene transitions, fast travel, emergency rescues

---

## What is Player Teleportation?

Player teleportation provides:
- **Instant movement**: No travel time, instant position change
- **Safe placement**: Ground validation to prevent spawning in walls/void
- **Network synchronization**: Server-authoritative with automatic client updates
- **Rotation control**: Optional facing direction setting
- **Pet handling**: Automatic teleportation of player's pets

---

## MiniWorld Studio Teleport System

### Service Chain

The teleportation system uses a multi-layer architecture:

```
Actor:TeleportTo(position)
  ↓
AvatarComponent:TeleportTo(position, rotation)
  ↓
Utils:TeleportTo(character, position)
  ↓
TeleportService:Teleport(character, Vector3)
```

### Required Services

| Service | Purpose | Access |
|---------|---------|--------|
| `TeleportService` | Core teleport functionality | `game:GetService('TeleportService')` |
| `Actor` | Player entity object | SGF framework |
| `AvatarComponent` | Character movement component | `actor.AvatarComponent` |

---

## Implementation Methods

### Method 1: Using Actor (Recommended)

Use this when you have access to the SGF Actor object.

**Server-Side**:
```lua
function SystemServer:teleportPlayerToCheckpoint(playerId, checkpointId)
    -- Get player actor
    local actor = self:getPlayerActor(playerId)
    if not actor then
        self.log:warning("[SystemServer] Actor not found for player: " .. playerId)
        return false
    end

    -- Get checkpoint position
    local checkpoint = self:getCheckpoint(checkpointId)
    if not checkpoint then
        self.log:warning("[SystemServer] Checkpoint not found: " .. checkpointId)
        return false
    end

    -- Create position vector
    local targetPos = Vector3.new(checkpoint.x, checkpoint.y, checkpoint.z)

    -- Validate position (ensure on ground, not in walls)
    local validPos = actor:GetValidPosition(targetPos)

    -- Teleport player
    actor:TeleportTo(validPos)

    self.log:info(string.format(
        "[SystemServer] Teleported player %d to checkpoint %s at %s",
        playerId, checkpointId, tostring(validPos)
    ))

    return true
end
```

### Method 2: Using TeleportService Directly

Use this when working outside the SGF framework or with raw character objects.

**Server-Side**:
```lua
function teleportCharacter(character, position)
    local TeleportService = game:GetService('TeleportService')
    local targetPos = Vector3.new(position.x, position.y, position.z)
    TeleportService:Teleport(character, targetPos)
end
```

### Method 3: With Ground Validation

Ensure the player lands safely on the ground.

**Server-Side**:
```lua
function SystemServer:teleportToGroundPosition(actor, position)
    -- Get the ground position below the target
    local groundPos = actor.AvatarComponent:GetGroundPosition(position)

    if not groundPos then
        -- Fallback: try original position with offset
        groundPos = Vector3.new(position.x, position.y + 100, position.z)
        self.log:warning("[SystemServer] Ground not found, using offset position")
    end

    -- Teleport to validated ground position
    actor.AvatarComponent:TeleportToGround(groundPos)

    return groundPos
end
```

---

## Position Resolution Strategies

### Strategy 1: Absolute Coordinates

Direct x, y, z coordinates in centimeters.

```lua
function SystemServer:teleportToCoordinates(actor, x, y, z)
    local targetPos = Vector3.new(x, y, z)
    actor:TeleportTo(targetPos)
end

-- Example usage
self:teleportToCoordinates(actor, 0, 100, 0)  -- Origin, 1 meter above ground
```

### Strategy 2: Named Locations

Lookup locations from a configuration table.

```lua
-- Define named locations
local NamedLocations = {
    MainCity = { x = 0, y = 100, z = 0 },
    ForestEntrance = { x = 5000, y = 120, z = 3000 },
    BossRoom = { x = -2000, y = 200, z = -1500 },
    SafeZone = { x = 1000, y = 150, z = 1000 }
}

function SystemServer:teleportToNamedLocation(actor, locationName)
    local location = NamedLocations[locationName]
    if not location then
        self.log:error("[SystemServer] Unknown location: " .. locationName)
        return false
    end

    local targetPos = Vector3.new(location.x, location.y, location.z)
    actor:TeleportTo(targetPos)
    return true
end

-- Example usage
self:teleportToNamedLocation(actor, "MainCity")
```

### Strategy 3: Entity-Based Targets

Teleport to another entity's position.

```lua
function SystemServer:teleportToEntity(actor, targetEntityId)
    -- Find target entity
    local targetActor = self.sgf.actorManager:GetServerActor(targetEntityId)
    if not targetActor then
        self.log:error("[SystemServer] Target entity not found: " .. targetEntityId)
        return false
    end

    -- Get target position
    local targetPos = targetActor:GetPosition()

    -- Optional: Add offset to prevent overlap
    local offset = Vector3.new(100, 0, 100)  -- 1 meter offset
    targetPos = targetPos + offset

    -- Teleport
    actor:TeleportTo(targetPos)
    return true
end
```

### Strategy 4: SpawnLocation-Based

Teleport to a SpawnLocation node.

```lua
function SystemServer:teleportToSpawnLocation(actor, spawnName)
    -- Find SpawnLocation in WorkSpace
    local workspace = game:GetService("WorkSpace")
    local spawnLocation = workspace:FindFirstChild(spawnName, true)  -- Recursive search

    if not spawnLocation or spawnLocation.ClassName ~= "SpawnLocation" then
        self.log:error("[SystemServer] SpawnLocation not found: " .. spawnName)
        return false
    end

    -- Get spawn position
    local spawnPos = spawnLocation.Position

    -- Teleport
    actor:TeleportTo(spawnPos)
    return true
end

-- Example usage
self:teleportToSpawnLocation(actor, "Checkpoint_01")
```

---

## Handling Offsets

Apply positional offsets to prevent exact overlaps or adjust placement.

### Simple Offset

```lua
function SystemServer:teleportWithOffset(actor, basePosition, offset)
    local targetPos = Vector3.new(
        basePosition.x + (offset.x or 0),
        basePosition.y + (offset.y or 0),
        basePosition.z + (offset.z or 0)
    )

    actor:TeleportTo(targetPos)
end

-- Example usage
self:teleportWithOffset(actor, checkpoint.position, { x = 0, y = 50, z = 100 })
```

### Random Scatter Offset

Distribute multiple players around a point to prevent crowding.

```lua
function SystemServer:teleportWithRandomOffset(actor, basePosition, radius)
    -- Generate random offset within radius
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius

    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance

    local targetPos = Vector3.new(
        basePosition.x + offsetX,
        basePosition.y,
        basePosition.z + offsetZ
    )

    -- Validate position
    local validPos = actor:GetValidPosition(targetPos)
    actor:TeleportTo(validPos)
end

-- Example: Scatter players within 5 meter radius
for _, playerId in ipairs(playerIds) do
    local actor = self:getPlayerActor(playerId)
    self:teleportWithRandomOffset(actor, spawnPoint, 500)  -- 500cm = 5m radius
end
```

---

## Complete Example: Checkpoint System

This example shows a full checkpoint teleportation system.

### Server-Side Implementation

```lua
--[[
    CheckpointSystemServer.lua
    Handles player checkpoints and respawn teleportation
]]

local CheckpointSystemServer = {
    name = "CheckpointSystemServer",
    checkpoints = {},
    playerCheckpoints = {}  -- [playerId] = lastCheckpointId
}

function CheckpointSystemServer:Init()
    self.log:info("[CheckpointSystemServer] Initializing checkpoint system")

    -- Load checkpoints from WorkSpace
    self:loadCheckpoints()

    -- Listen for player death
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:on(EventID.PlayerDied, function(data)
        self:onPlayerDied(data.playerId)
    end)

    return true
end

-- Load all checkpoint SpawnLocations from scene
function CheckpointSystemServer:loadCheckpoints()
    local workspace = game:GetService("WorkSpace")

    -- Find all nodes with "Checkpoint" in name
    for _, child in ipairs(workspace:GetDescendants()) do
        if child.Name:match("^Checkpoint_") and child.ClassName == "SpawnLocation" then
            local checkpointId = child.Name

            self.checkpoints[checkpointId] = {
                id = checkpointId,
                position = child.Position,
                rotation = child.Rotation,
                enabled = child.Enabled
            }

            self.log:debug(string.format(
                "[CheckpointSystemServer] Loaded checkpoint: %s at %s",
                checkpointId, tostring(child.Position)
            ))
        end
    end

    self.log:info(string.format(
        "[CheckpointSystemServer] Loaded %d checkpoints",
        self:getCheckpointCount()
    ))
end

-- Get checkpoint data
function CheckpointSystemServer:getCheckpoint(checkpointId)
    return self.checkpoints[checkpointId]
end

-- Get checkpoint count
function CheckpointSystemServer:getCheckpointCount()
    local count = 0
    for _ in pairs(self.checkpoints) do
        count = count + 1
    end
    return count
end

-- Set player's current checkpoint
function CheckpointSystemServer:setPlayerCheckpoint(playerId, checkpointId)
    local checkpoint = self:getCheckpoint(checkpointId)
    if not checkpoint then
        self.log:error("[CheckpointSystemServer] Invalid checkpoint: " .. checkpointId)
        return false
    end

    self.playerCheckpoints[playerId] = checkpointId

    self.log:info(string.format(
        "[CheckpointSystemServer] Player %d checkpoint set to %s",
        playerId, checkpointId
    ))

    -- Emit event for UI update
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit("CheckpointActivated", {
        playerId = playerId,
        checkpointId = checkpointId
    })

    return true
end

-- Get player's current checkpoint
function CheckpointSystemServer:getPlayerCheckpoint(playerId)
    return self.playerCheckpoints[playerId] or "Checkpoint_01"  -- Default
end

-- Teleport player to their checkpoint
function CheckpointSystemServer:teleportToCheckpoint(playerId, checkpointId)
    -- Get player actor
    local playerSystem = self.sgf.businessSystemManager:get("PlayerSystemServer")
    if not playerSystem then
        self.log:error("[CheckpointSystemServer] PlayerSystem not found")
        return false
    end

    local actor = playerSystem:getPlayerActor(playerId)
    if not actor then
        self.log:error("[CheckpointSystemServer] Actor not found for player: " .. playerId)
        return false
    end

    -- Get checkpoint
    local checkpoint = self:getCheckpoint(checkpointId)
    if not checkpoint then
        self.log:error("[CheckpointSystemServer] Checkpoint not found: " .. checkpointId)
        return false
    end

    if not checkpoint.enabled then
        self.log:warning("[CheckpointSystemServer] Checkpoint disabled: " .. checkpointId)
        return false
    end

    -- Validate position
    local targetPos = checkpoint.position
    local validPos = actor:GetValidPosition(targetPos)

    -- Teleport
    actor:TeleportTo(validPos)

    -- Optionally set rotation
    if checkpoint.rotation then
        actor:SetRotation(checkpoint.rotation)
    end

    self.log:info(string.format(
        "[CheckpointSystemServer] Teleported player %d to checkpoint %s",
        playerId, checkpointId
    ))

    return true
end

-- Handle player death - respawn at last checkpoint
function CheckpointSystemServer:onPlayerDied(playerId)
    self.log:info("[CheckpointSystemServer] Player died: " .. playerId)

    -- Get player's last checkpoint
    local checkpointId = self:getPlayerCheckpoint(playerId)

    -- Delay respawn by 3 seconds
    task.delay(3.0, function()
        -- Teleport to checkpoint
        if self:teleportToCheckpoint(playerId, checkpointId) then
            self.log:info(string.format(
                "[CheckpointSystemServer] Respawned player %d at %s",
                playerId, checkpointId
            ))

            -- Emit respawn event
            local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
            self.events:emit(EventID.PlayerRespawned, {
                playerId = playerId,
                checkpointId = checkpointId
            })
        end
    end)
end

return CheckpointSystemServer
```

### Usage Example

```lua
-- In your game logic or trigger system

-- Activate checkpoint when player touches it
function onCheckpointTouched(checkpointId, playerId)
    local checkpointSystem = sgf.businessSystemManager:get("CheckpointSystemServer")
    checkpointSystem:setPlayerCheckpoint(playerId, checkpointId)
end

-- Manual teleport via command or button
function onTeleportCommand(playerId, targetCheckpoint)
    local checkpointSystem = sgf.businessSystemManager:get("CheckpointSystemServer")
    checkpointSystem:teleportToCheckpoint(playerId, targetCheckpoint)
end
```

---

## Position Validation

### GetValidPosition()

Ensures the target position is walkable and not inside geometry.

```lua
function SystemServer:teleportSafely(actor, targetPos)
    -- Validate position to ensure it's on walkable ground
    local validPos = actor:GetValidPosition(targetPos)

    if not validPos then
        self.log:error("[SystemServer] Invalid teleport position, using fallback")
        -- Fallback: use spawn location
        validPos = self:getFallbackSpawnPosition()
    end

    actor:TeleportTo(validPos)
    return validPos
end
```

### GetGroundPosition()

Finds the ground position below a point.

```lua
function SystemServer:teleportToGround(actor, targetPos)
    -- Find ground below target position
    local groundPos = actor.AvatarComponent:GetGroundPosition(targetPos)

    if groundPos then
        actor:TeleportTo(groundPos)
        return groundPos
    else
        self.log:error("[SystemServer] No ground found at position: " .. tostring(targetPos))
        return nil
    end
end
```

### Manual Raycast Validation

Custom ground detection using raycasting.

```lua
function SystemServer:findGroundPosition(position, maxDistance)
    local WorldService = game:GetService("WorldService")

    -- Raycast downward from position
    local rayStart = Vector3.new(position.x, position.y, position.z)
    local rayEnd = Vector3.new(position.x, position.y - (maxDistance or 1000), position.z)

    local hitResult = WorldService:Raycast(rayStart, rayEnd, {
        ignoreWater = false,
        ignoreTransparent = true
    })

    if hitResult then
        -- Ground found, add small offset above surface
        return Vector3.new(hitResult.Position.x, hitResult.Position.y + 100, hitResult.Position.z)
    else
        -- No ground found
        return nil
    end
end

-- Usage
function SystemServer:teleportWithGroundCheck(actor, position)
    local groundPos = self:findGroundPosition(position, 1000)

    if groundPos then
        actor:TeleportTo(groundPos)
        return true
    else
        self.log:error("[SystemServer] Cannot teleport: no ground at position")
        return false
    end
end
```

---

## Rotation Control

Set the player's facing direction after teleportation.

### Basic Rotation

```lua
function SystemServer:teleportWithRotation(actor, position, rotation)
    -- Teleport to position
    actor:TeleportTo(position)

    -- Set rotation (quaternion or euler angles)
    if rotation then
        actor:SetRotation(rotation)
    end
end

-- Example: Face north (positive Z)
local rotation = Quaternion.fromEulerAngles(0, 0, 0)
self:teleportWithRotation(actor, targetPos, rotation)

-- Example: Face east (positive X)
local rotation = Quaternion.fromEulerAngles(0, 90, 0)
self:teleportWithRotation(actor, targetPos, rotation)
```

### Using AvatarComponent Directly

```lua
function SystemServer:teleportWithFacing(actor, position, facingDirection)
    -- facingDirection: Vector3 indicating where to look

    -- Calculate rotation from direction
    local forward = facingDirection:Unit()
    local rotation = Quaternion.fromLookRotation(forward, Vector3.new(0, 1, 0))

    -- Teleport with rotation
    actor.AvatarComponent:TeleportTo(position, rotation)
end

-- Example: Face toward a specific point
local targetPoint = Vector3.new(1000, 100, 500)
local currentPos = actor:GetPosition()
local facingDir = (targetPoint - currentPos):Unit()
self:teleportWithFacing(actor, targetPos, facingDir)
```

---

## Network Considerations

### Server-Authoritative Teleportation

**Critical**: Teleportation MUST be initiated on the server for security.

```lua
-- ❌ WRONG: Client-initiated teleport (exploitable)
function SystemClient:teleportPlayer(position)
    local localPlayer = game:GetService("Players").LocalPlayer
    local actor = self:getPlayerActor(localPlayer.UserId)
    actor:TeleportTo(position)  -- SECURITY RISK!
end

-- ✅ CORRECT: Server-authoritative teleport
function SystemClient:requestTeleport(checkpointId)
    -- Send request to server
    self:SendServerRequest(Protocol.ClientMSGID.TELEPORT_REQUEST, {
        checkpointId = checkpointId
    })
end

function SystemServer:OnRequest(Protocol.ClientMSGID.TELEPORT_REQUEST, function(userId, msgid, data)
    -- Validate request
    if not self:canPlayerTeleport(userId, data.checkpointId) then
        return { success = false, reason = "Not allowed" }
    end

    -- Perform teleport on server
    self:teleportToCheckpoint(userId, data.checkpointId)

    return { success = true }
end)
```

### Automatic Replication

The server-side teleport automatically replicates to all clients - no manual synchronization needed.

```lua
-- Server teleports actor
actor:TeleportTo(position)
-- ↓ Automatic network replication
-- ↓ All clients see player at new position
-- ✅ No client-side code required
```

---

## Best Practices

### 1. Always Validate Positions

```lua
-- ✅ Good: Validate before teleport
local validPos = actor:GetValidPosition(targetPos)
actor:TeleportTo(validPos)

-- ❌ Bad: Direct teleport without validation
actor:TeleportTo(targetPos)  -- May spawn in wall or void!
```

### 2. Use Named Locations

```lua
-- ✅ Good: Named locations are maintainable
self:teleportToNamedLocation(actor, "SafeZone")

-- ❌ Bad: Hardcoded coordinates scattered everywhere
actor:TeleportTo(Vector3.new(12345, 678, 90123))
```

### 3. Add Safety Fallbacks

```lua
function SystemServer:teleportSafely(actor, targetPos)
    local validPos = actor:GetValidPosition(targetPos)

    if not validPos then
        -- Fallback to main spawn
        self.log:warning("[SystemServer] Invalid position, using main spawn")
        validPos = self:getMainSpawnPosition()
    end

    actor:TeleportTo(validPos)
end
```

### 4. Log Teleport Events

```lua
function SystemServer:teleportPlayer(actor, destination)
    local oldPos = actor:GetPosition()

    actor:TeleportTo(destination)

    local newPos = actor:GetPosition()

    self.log:info(string.format(
        "[SystemServer] Teleported actor %d from %s to %s",
        actor:GetActorId(),
        tostring(oldPos),
        tostring(newPos)
    ))
end
```

### 5. Handle Pets and Followers

```lua
-- The framework handles pets automatically in AvatarComponent:TeleportTo()
-- But for custom followers:

function SystemServer:teleportWithFollowers(actor, position)
    -- Teleport main actor
    actor:TeleportTo(position)

    -- Teleport followers
    for _, followerId in ipairs(actor:GetFollowerIds()) do
        local follower = self.sgf.actorManager:GetServerActor(followerId)
        if follower then
            -- Offset followers to prevent overlap
            local offset = Vector3.new(
                math.random(-200, 200),
                0,
                math.random(-200, 200)
            )
            follower:TeleportTo(position + offset)
        end
    end
end
```

---

## Common Mistakes & Solutions

### ❌ Mistake 1: Teleporting on Client

**Problem**: Client-initiated teleports are not secure and cause desync.

**Solution**: Always initiate teleports on the server.

```lua
-- ✅ Correct
function SystemServer:teleportPlayer(playerId, position)
    local actor = self:getPlayerActor(playerId)
    actor:TeleportTo(position)
end
```

### ❌ Mistake 2: No Position Validation

**Problem**: Teleporting to invalid positions (inside walls, in void).

**Solution**: Always use `GetValidPosition()` or `GetGroundPosition()`.

```lua
-- ✅ Correct
local validPos = actor:GetValidPosition(targetPos)
actor:TeleportTo(validPos)
```

### ❌ Mistake 3: Wrong Coordinate Units

**Problem**: Using meters instead of centimeters.

**Solution**: Remember MiniWorld uses centimeters (100 units = 1 meter).

```lua
-- ❌ Wrong: 5 meters in wrong units
actor:TeleportTo(Vector3.new(0, 5, 0))  -- Only 5cm above ground!

-- ✅ Correct: 5 meters = 500 centimeters
actor:TeleportTo(Vector3.new(0, 500, 0))
```

### ❌ Mistake 4: Forgetting Pet Teleportation

**Problem**: Player teleports but pets left behind.

**Solution**: Use `Actor:TeleportTo()` which handles pets automatically.

```lua
-- ✅ Automatic pet handling
actor:TeleportTo(position)  -- Pets teleport automatically

-- ⚠️ Manual handling required if using service directly
local TeleportService = game:GetService('TeleportService')
TeleportService:Teleport(character, position)  -- Pets NOT handled!
```

### ❌ Mistake 5: No Safety Checks

**Problem**: Teleporting without checking if location exists or is valid.

**Solution**: Always validate before teleporting.

```lua
-- ✅ Correct
function SystemServer:teleportToCheckpoint(actor, checkpointId)
    local checkpoint = self:getCheckpoint(checkpointId)

    if not checkpoint then
        self.log:error("Checkpoint not found: " .. checkpointId)
        return false
    end

    if not checkpoint.enabled then
        self.log:warning("Checkpoint disabled: " .. checkpointId)
        return false
    end

    actor:TeleportTo(checkpoint.position)
    return true
end
```

---

## Validation Checklist

Before deploying teleport functionality:

- [ ] Teleportation is **server-authoritative** (not client-initiated)
- [ ] All positions are **validated** using `GetValidPosition()` or `GetGroundPosition()`
- [ ] Coordinates are in **centimeters** (100 units = 1 meter)
- [ ] **Fallback positions** are defined for invalid targets
- [ ] Teleport events are **logged** for debugging
- [ ] **Named locations** are used instead of hardcoded coordinates
- [ ] **Pets and followers** are handled (automatic with `Actor:TeleportTo()`)
- [ ] **Rotation** is set if needed for specific facing direction
- [ ] **Network requests** are validated before executing teleport
- [ ] **Safety checks** prevent teleporting to disabled or missing locations

---

## Related Documentation

- [How to Add Player Spawn System](how-to-add-player-spawn.md)
- [How to Use Event Bus](how-to-use-event-bus.md)
- [How to Create Business System](how-to-create-business-system.md)
- [How to Use Network Communication](how-to-use-network-communication.md)

---

## Quick Reference Card

### Basic Teleport

```lua
-- Get player actor
local actor = self:getPlayerActor(playerId)

-- Validate position
local validPos = actor:GetValidPosition(targetPosition)

-- Teleport
actor:TeleportTo(validPos)
```

### Teleport with Rotation

```lua
actor.AvatarComponent:TeleportTo(position, rotation)
```

### Ground-Safe Teleport

```lua
actor.AvatarComponent:TeleportToGround(position)
```

### Service Direct Access

```lua
local TeleportService = game:GetService('TeleportService')
TeleportService:Teleport(character, Vector3.new(x, y, z))
```

**Coordinate Conversion**:
- 1 meter = 100 centimeters = 100 units
- Common height offset: Y + 100 (1 meter above ground)
