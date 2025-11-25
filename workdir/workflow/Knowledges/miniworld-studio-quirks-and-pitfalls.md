# MiniWorld Studio API Differences & Common Pitfalls

## Overview

MiniWorld Studio has significant API differences from Roblox/standard Lua game engines. This guide documents critical differences discovered during development to prevent future errors.

---

## 🚨 CRITICAL: Required Metadata Files

### Issue: Folders Not Recognized in Node Tree

**Problem:**
```
attempt to index field 'systems' (a nil value)
ServerSystems.ParkourMechanicsSystem = require(ServerScriptService.systems.ParkourMechanicsSystem)
                                                                      ^^^^^^^^ nil!
```

**Root Cause:**
In MiniWorld Studio, folders are NOT automatically recognized. They require metadata files to be registered in the node tree.

### ✅ Solution: Create Required Metadata Files

Every folder needs ONE files:

#### 1. `FolderName.json` file
```json
{
    "ClassID": 1,
    "ClassType": "SandboxNode",
    "NodeId": "10002",
    "attribute": [],
    "flags": 0,
    "realNodeName": "systems",
    "reflex": [
        {"Name": "systems"},
        {"Tag": 0},
        {"Enabled": true},
        {"SyncMode": 0},
        {"LocalSyncFlag": 0},
        {"ResourceDynamicLoad": false},
        {"IgnoreSafeMode": false},
        {"ResourceLoadMode": 0}
    ]
}
```

### Folder Structure Example

```
ServerScriptService/
├── systems.json           ← Required!
├── systems/
│   ├── ParkourMechanicsSystem.json
│   └── ParkourMechanicsSystem.lua
├── ServerInit.json
└── ServerInit.lua
```

---

## 🚨 Node Traversal APIs

### Issue: GetDescendants() and GetChildren() Don't Exist

**Problem:**
```lua
-- ❌ WRONG: These methods don't exist in MiniWorld Studio
for _, obj in ipairs(workspace:GetDescendants()) do  -- ERROR!
    -- ...
end

local children = parent:GetChildren()  -- ERROR!
```

**Error Messages:**
- `attempt to call method 'GetDescendants' (a nil value)`
- `attempt to call method 'GetChildren' (a nil value)`

### ✅ Solution: Use .Children Property

In MiniWorld Studio, nodes have a **`.Children` property** (not methods):

```lua
-- ✅ CORRECT: Access .Children property directly
if parent.Children then
    for _, child in pairs(parent.Children) do
        -- Process child
    end
end
```

### ✅ Solution: Recursive Traversal Pattern

To traverse entire hierarchy (equivalent to GetDescendants):

```lua
local function findObjectsRecursive(parent, pattern, results)
    results = results or {}

    if not parent then
        return results
    end

    -- Check current object
    if parent.Name and parent.Name:match(pattern) then
        table.insert(results, parent)
    end

    -- Recursively search children
    if parent.Children then
        for _, child in pairs(parent.Children) do
            findObjectsRecursive(child, pattern, results)
        end
    end

    return results
end

-- Usage
local workspace = game:GetService("WorkSpace")
local neonLights = findObjectsRecursive(workspace, "path_light")
```

---

## 🚨 Logging Functions

### Issue: warn() Function Doesn't Exist

**Problem:**
```lua
-- ❌ WRONG: warn() function doesn't exist in MiniWorld Studio
warn("[ServerMain] Something went wrong!")  -- ERROR!
```

**Error Message:**
- `attempt to call global 'warn' (a nil value)`

**Root Cause:**
MiniWorld Studio does not have a `warn()` function like Roblox does.

### ✅ Solution: Use print() for All Logging

```lua
-- ✅ CORRECT: Use print() for all logging
print("[ServerMain] Something went wrong!")
print("[ServerMain] ERROR: Init failed")
```

**Best Practice:**
- Use `print()` for all logging (info, warnings, errors)
- Prefix messages with context tags like `[ServerMain]` or `ERROR:` to distinguish severity
- Example patterns:
  ```lua
  print("[SystemName] INFO: Normal operation")
  print("[SystemName] WARNING: Potential issue detected")
  print("[SystemName] ERROR: Operation failed")
  ```

---

## 🚨 Service Name Case Sensitivity

### Issue: Incorrect Service Names

**Problem:**
```lua
-- ❌ WRONG: Case matters!
local workspace = game:GetService("Workspace")  -- Returns nil!
```

**Error Message:**
- `attempt to call method 'GetDescendants' (a nil value)` (because workspace is nil)

### ✅ Solution: Use Correct Casing

```lua
-- ✅ CORRECT: Note the capital 'S'
local workspace = game:GetService("WorkSpace")

-- Other common services (verify casing):
local MainStorage = game:GetService("MainStorage")
local StartPlayer = game:GetService("StartPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
```

**Always verify service names in sample code before using!**

---

## 🚨 Client/Server Service Access

### Issue: Accessing Client Services from Server Context

**Problem:**
```lua
-- In GameMain.lua (loaded by BOTH server and client)
local isClient = RunService:IsClient()

if isClient then
    -- ❌ WRONG: This runs on server during module load!
    local StarterPlayerScripts = game:GetService("StartPlayer").StarterPlayerScripts
    --                                                          ^^^^^^^^^^^^^^^^ nil on server!
end
```

**Error Message:**
- `attempt to index a nil value (field 'StarterPlayerScripts')`

**Root Cause:**
When a module is `require()`d from server code, the ENTIRE file is evaluated on the server, even code inside `if isClient` blocks.

### ✅ Solution: Protect Service Access with pcall

```lua
if isClient then
    local success, StartPlayer = pcall(game.GetService, game, "StartPlayer")
    if success and StartPlayer and StartPlayer.StarterPlayerScripts then
        local StarterPlayerScripts = StartPlayer.StarterPlayerScripts
        ClientSystems.MySystem = require(StarterPlayerScripts.systems.MySystem)
    else
        print("[Warning] Could not access StarterPlayerScripts")
    end
end
```

**Best Practice:**
- Always wrap cross-realm service access in `pcall`
- Check both service existence AND child nodes
- Log warnings when services are unavailable

---

## 🚨 Variable Shadowing with local

### Issue: Duplicate Variable Declarations

**Problem:**
```lua
-- Line 26: First declaration
local EventID = require(MainStorage.Runtime.EventID)

-- Line 32: Second declaration - OVERWRITES first!
local Protocol, EventID  -- EventID is now nil!

-- Later use
self.sgf.events:on(EventID.WallRunStarted, ...)  -- ERROR: EventID is nil!
```

**Error Message:**
- `attempt to index upvalue 'EventID' (a nil value)`

**Root Cause:**
In Lua, `local` creates a NEW variable that shadows any previous declaration with the same name.

### ✅ Solution: Declare Variables Once

```lua
-- ✅ CORRECT: Declare all variables in one place
local MainStorage = game:GetService("MainStorage")
local Players = game:GetService("Players")

-- Runtime imports
local EventID = require(MainStorage.Runtime.EventID)
local Protocol = require(MainStorage.Runtime.Protocol)

-- ❌ NEVER do this:
-- local Protocol, EventID  -- This resets both to nil!
```

**Rule:** Declare each variable exactly once at the top of the file

---

## 🚨 Module Import Patterns

### Issue: Missing require() Statements

**Problem:**
```lua
-- In system file
local EventID  -- Declared but never imported!

function System:PreInit()
    self.sgf.events:on(EventID.WallRunStarted, ...)  -- ERROR!
end
```

**Root Cause:**
Variables declared but never assigned a value remain `nil`.

### ✅ Solution: Always Import Required Modules

```lua
-- Services
local MainStorage = game:GetService("MainStorage")

-- Runtime imports - ALWAYS require() them!
local EventID = require(MainStorage.Runtime.EventID)
local Protocol = require(MainStorage.Runtime.Protocol)
```

### Standard Import Pattern for Systems

```lua
--[[
    SystemName - Brief description

    System Type: server-only / client-only / shared
    Dependencies: List any dependencies
]]

local SystemName = {}

-- System metadata
SystemName.name = "SystemName"
SystemName.version = "1.0.0"
SystemName.runMode = "server-only"  -- or "client-only"
SystemName.updatePriority = 100
SystemName.dependencies = {}

-- Services (always at top)
local MainStorage = game:GetService("MainStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Runtime imports (after services)
local EventID = require(MainStorage.Runtime.EventID)
local Protocol = require(MainStorage.Runtime.Protocol)

-- System state (after imports)
local state = {
    isInitialized = false,
    -- ... other state
}

-- Rest of system implementation
-- ...

return SystemName
```

---

## 🚨 Vector3 Operations

### Issue: Vector3.Magnitude Property Doesn't Exist

**Problem:**
```lua
-- ❌ WRONG: .Magnitude property doesn't exist on Vector3 subtraction result
local distance = (nextWP.pos - currentWP.pos).Magnitude  -- ERROR!
```

**Error Message:**
- `[Bridge_Vector3] __index has no key(Magnitude)`

**Root Cause:**
In MiniWorld Studio, when you subtract two Vector3 objects, the result is a `Bridge_Vector3` type that doesn't have a `.Magnitude` property. This is different from Roblox where Vector3 operations return Vector3 objects with a `.Magnitude` property.

### ✅ Solution 1: Use .length Property (RECOMMENDED)

**The built-in Vector3 objects in MiniWorld Studio have a `.length` property that returns the magnitude:**

```lua
-- ✅ BEST: Use .length property for concise distance calculation
local distance = (nextWP.pos - currentWP.pos).length

-- Works with any Vector3 subtraction
local vec = self.node.Position - self.start_pos
if vec.length >= self.max_dist * 100 then
    -- ...
end

-- Can also use with Vector3.new()
local disPos = from - to
local distance2D = Vector3.new(disPos.x, 0, disPos.z).length
```

**Common usage patterns from sample code:**
```lua
-- Distance check
local disPos = workSpace.CurrentCamera.Position - pos
local distance = disPos.length

-- 2D distance (ignoring Y axis)
local function vec_distance(from, to)
    local disPos = from - to
    return Vector3.new(disPos.x, 0, disPos.z).length
end

-- Movement distance tracking
local vec = self.node.Position - self.start_pos
if vec.length >= self.max_dist * 100 then
    self:destroy()
end
```

### ✅ Solution 2: Manual Calculation (Alternative)

**If `.length` doesn't work in your context, calculate distance manually:**

```lua
-- ✅ ALTERNATIVE: Calculate distance using component-wise subtraction
local dx = nextWP.pos.x - currentWP.pos.x
local dy = nextWP.pos.y - currentWP.pos.y
local dz = nextWP.pos.z - currentWP.pos.z
local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
```

**Helper function pattern:**

```lua
-- Helper function for calculating distance between two positions
local function calculateDistance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Usage
local distance = calculateDistance(currentWP.pos, nextWP.pos)
```

**Important Notes:**
- **`.length` is a property**, not a method - use `vec.length`, not `vec:length()` or `vec.length()`
- Some MiniWorld sample code uses custom `Vec3` classes that have `:Magnitude()` as a method - these are custom implementations, not the built-in Vector3
- The `.length` property works with built-in Vector3 objects (from `.Position`, `Vector3.new()`, etc.)
- Use `.length` whenever possible for cleaner, more readable code

---

## 🚨 Entity Creation API

### Issue: game:CreateEntity() Doesn't Exist

**Problem:**
```lua
-- ❌ WRONG: CreateEntity() method doesn't exist in MiniWorld Studio
local entity = game:CreateEntity()  -- ERROR!
```

**Error Message:**
- `attempt to call method 'CreateEntity' (a nil value)`

**Root Cause:**
MiniWorld Studio does not have a `game:CreateEntity()` method. This is not part of the MiniWorld API.

### ✅ Solution: Use SandboxNode.New()

```lua
-- ✅ CORRECT: Use SandboxNode.New() to create scene nodes
local trigger = SandboxNode.New("TriggerBox")
trigger.Name = "MyTrigger"
trigger.Parent = workspace
trigger.LocalPosition = Vector3.new(0, 0, 0)
trigger.Size = Vector3.new(5, 5, 5)
```

**Available Node Types:**
- `"TriggerBox"` - For trigger volumes (if runtime creation is needed)
- `"CustomNotify"` - For custom events/notifications
- Other node types (check MiniWorld documentation)

**BEST PRACTICE: Use Scene-Based Triggers**

Instead of creating triggers at runtime, pre-place them in `blockout.yml` and reference them:

```lua
-- ✅ BEST PRACTICE: Reference pre-placed scene object
local triggerObj = self.data.sceneObjects["checkpoint_crystal_01"]
if triggerObj and triggerObj.Touched then
    local connection = triggerObj.Touched:Connect(function(otherObject)
        local player = self:getPlayerFromObject(otherObject)
        if player then
            self:handleCheckpoint(player)
        end
    end)
    self.data.triggerConnections["checkpoint_01"] = connection
end
```

**Why Scene-Based Triggers?**
1. Editor integration - Visual placement and adjustment
2. Better performance - No runtime object creation overhead
3. MiniWorld Studio best practice - Matches rpg-gamedemo reference implementation
4. Easier debugging - Objects visible in scene hierarchy

**When to Use Runtime Creation:**
- Prototyping/testing only
- Dynamic gameplay mechanics that require procedural trigger placement
- Temporary debugging triggers

---

## 📋 Checklist for New Game Projects

When creating a new MiniWorld Studio game, verify:

### 1. Folder Metadata
- [ ] Every folder has `childrenIndex` file
- [ ] Every folder has `FolderName.json` file
- [ ] childrenIndex lists all children with correct NodeIDs
- [ ] Nested folders also have both metadata files

### 2. Script Imports
- [ ] All `require()` statements point to ModuleScript (not Script/LocalScript)
- [ ] Service names use correct casing (e.g., "WorkSpace", "StartPlayer")
- [ ] Runtime modules (EventID, Protocol) are properly imported
- [ ] No duplicate variable declarations

### 3. Node Traversal
- [ ] Use `.Children` property (not :GetChildren() method)
- [ ] Use recursive functions (not :GetDescendants())
- [ ] Always check `if node.Children then` before iteration

### 4. Logging
- [ ] Use `print()` for all logging (not warn())
- [ ] Prefix messages with context like `[SystemName]` and severity like `ERROR:`

### 5. Client/Server Safety
- [ ] Cross-realm service access wrapped in `pcall`
- [ ] Check service AND child node existence
- [ ] Add warning logs when services unavailable

---

## 🔍 Common Error Messages & Solutions

| Error Message | Likely Cause | Solution |
|--------------|--------------|----------|
| `attempt to index field 'systems' (a nil value)` | Missing childrenIndex/JSON | Add metadata files |
| `attempt to call method 'GetDescendants' (a nil value)` | Wrong API or nil workspace | Use .Children + recursion; check service name |
| `attempt to call method 'GetChildren' (a nil value)` | Wrong API | Use .Children property |
| `attempt to call global 'warn' (a nil value)` | warn() doesn't exist | Use print() instead |
| `attempt to call method 'CreateEntity' (a nil value)` | Wrong API | Use SandboxNode.New() instead |
| `attempt to index a nil value (field 'StarterPlayerScripts')` | Service doesn't exist in context | Wrap in pcall, check existence |
| `attempt to index upvalue 'EventID' (a nil value)` | Duplicate declaration or missing require | Remove duplicate locals, add require() |
| `[Bridge_Vector3] __index has no key(Magnitude)` | Vector3 lacks .Magnitude property | Use .length property instead |

---

## 📚 Reference: MiniWorld vs Roblox APIs

| Feature | Roblox API | MiniWorld Studio API |
|---------|-----------|---------------------|
| Get all descendants | `node:GetDescendants()` | Use recursive function with `.Children` |
| Get direct children | `node:GetChildren()` | `node.Children` (property, not method) |
| Warning logging | `warn(message)` | `print(message)` |
| Create entity | `game:CreateEntity()` | `SandboxNode.New("TriggerBox")` |
| Vector magnitude | `vector.Magnitude` (property) | `vector.length` (property) |
| Workspace service | `game:GetService("Workspace")` | `game:GetService("WorkSpace")` (capital S) |
| Folder recognition | Automatic | Requires childrenIndex + JSON files |
| Module require | `require(path)` | Same, but needs metadata files |

---

## 🎯 Summary: Key Takeaways

1. **Folders need metadata**: Both `childrenIndex` and `.json` files for EVERY folder
2. **No GetDescendants/GetChildren**: Use `.Children` property with recursive traversal
3. **No warn() function**: Use `print()` for all logging (info, warnings, errors)
4. **No game:CreateEntity()**: Use `SandboxNode.New("TriggerBox")` to create scene nodes
5. **Use Vector3.length property**: For distance calculations, use `(pos2 - pos1).length`, not `.Magnitude`
6. **Service names are case-sensitive**: "WorkSpace" not "Workspace"
7. **Protect cross-realm access**: Use `pcall` when accessing client services from shared code
8. **One variable, one declaration**: Never redeclare `local` variables
9. **Always require() imports**: Don't just declare variables, import the modules

Following these rules will prevent 95% of common errors in MiniWorld Studio development.
