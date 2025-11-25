# SystemLuaGen: System Specification to Lua Code Generator (REVISED)

**EXECUTION UNIT INSTRUCTIONS (MiniWorld Studio)**

## Unit Role

Convert system specifications into executable Lua code for MiniWorld Studio's **SGF (Studio Game Framework)** using a **hybrid deterministic + LLM approach**:

1. **Deterministic Code Generation** (Program) - SGF lifecycle, network wiring, behavior handlers
2. **LLM Implementation** (AI) - Game-specific logic for queries, commands, helpers

This separation ensures:
- Correct SGF Framework integration
- Proper lifecycle management (PreInit → Init → PostInit → Start)
- Consistent network and event patterns
- Creative, game-specific gameplay logic via LLM

---

## Critical: MiniWorld Studio Architecture

### SGF Framework (Pre-Existing)

⚠️ **DO NOT GENERATE** - These are part of MiniWorld Studio's SGF Framework:
- `Framework/SGFFramework.lua`
- `Framework/Core/BusinessSystemManager.lua`
- `Framework/Core/EventBus.lua`
- `Framework/Core/ServiceContainer.lua`
- `Framework/GamePlay/NetworkHelper.lua`

✅ **DO GENERATE** - Game-specific code:
- `Framework/Runtime/Protocol.lua` - Network message IDs
- `Framework/Runtime/EventID.lua` - Event IDs
- `Framework/GameSystems/<System>/<System>Server.lua` - Business systems
- `ServiceNodes/ServerScriptService/ServerMain.lua` - Server entry
- `ServiceNodes/StartPlayer/StarterPlayerScripts/ClientMain.lua` - Client entry

---

## Inputs

### Required Files

1. **`specs/*.yml`** - Individual system specification files (from SystemSpecGen)
   - Format: `system_spec` schema with interface, events, behaviors

2. **`global_registry.yml`** - Cross-system interface registry (from SystemSpecGen)
   - All events, queries, commands with signatures

3. **`systems_contracts.yml`** - Integration contracts (from SystemSpecGen)
   - Event producers/consumers
   - Query/command providers/consumers

**Note**: Entity definitions are embedded within each system spec file (`specs/*.yml`) in the `data.entities` section. SystemLuaGen extracts them during Phase 1.

### Input Directory Structure

```
<GAME_DIR>/
└── UnitsData/
    ├── specs/
    │   ├── HeroSystem.yml        # Contains data.entities
    │   ├── CombatSystem.yml
    │   └── ...
    ├── global_registry.yml
    └── systems_contracts.yml
```

---

## Output

### Generated Lua Code Structure

```
<GAME_DIR>/
└── ServiceNodes/
    ├── StartPlayer/StarterPlayerScripts/
    │   ├── ClientMain.lua        # Generated: client entry point
    │   └── ClientMain.json
    ├── ServerScriptService/
    │   ├── ServerMain.lua        # Generated: server entry point
    │   └── ServerMain.json
    └── MainStorage/
        └── Framework/
            ├── Runtime/
            │   ├── Protocol.lua          # Generated: network message IDs
            │   └── EventID.lua           # Generated: event IDs
            │
            ├── GameSystems/              # Generated: business systems
            │   ├── HeroSystem/
            │   │   ├── HeroSystemServer.lua
            │   │   ├── HeroSystemServer.json
            │   │   ├── HeroSystemClient.lua
            │   │   └── HeroSystemClient.json
            │   └── CombatSystem/
            │       ├── CombatSystemServer.lua
            │       └── CombatSystemServer.json
```

---

## Execution Flow

### Phase 1: Analysis & Preparation

**Program: `analyze_specs.py`**

```bash
python analyze_specs.py <GAME_DIR>
```

**Purpose**: Load and validate all inputs, build generation plan

**Actions**:
1. Load all spec files from `specs/`
2. Load `global_registry.yml` and `systems_contracts.yml`
3. Extract entities from all specs (`data.entities` sections)
4. Generate `_intermediate/entities_registry.yml` with all entity definitions
5. Validate consistency
6. Build execution plan:
   - Separate server vs client systems by `runtime` field
   - Map behaviors to event handlers
   - Map queries/commands to methods
   - Map player_actions to network handlers
   - Identify functions needing LLM implementation
   - Extract dependencies between systems

**Outputs**:
- `_intermediate/lua_generation_plan.yml`
- `_intermediate/entities_registry.yml`

**entities_registry.yml format**:
```yaml
entities:
  HeroInstance:
    defined_by: HeroSystem
    fields:
      hero_id: HeroDefinitionId
      level: int
      hp_current: int
  HeroDefinition:
    defined_by: HeroSystem
    fields:
      id: string
      base_stats:
        hp: int
        attack: int
```

**lua_generation_plan.yml format**:
```yaml
generation_plan:
  metadata:
    game_id: "castle_defense"
    total_systems: 5

  server_systems:
    - id: HeroSystem
      runtime: server
      dependencies: ["CombatSystem"]

      # From interface.queries
      queries:
        - id: GET_MAX_HP
          method_name: getMaxHP
          params: [hero_id]
          returns: int
          description: "..."

      # From interface.commands
      commands:
        - id: REVIVE_HERO
          method_name: reviveHero
          params: [hero_id, revive_position]
          returns: bool
          emits: [HERO_REVIVED]
          description: "..."

      # From interface.player_actions
      player_actions:
        - id: MOVE_HERO
          method_name: handleMoveHero
          message_id: HERO_MOVE_REQ
          params: [hero_id, target_position]
          description: "..."

      # From behaviors
      behaviors:
        - id: on_hero_damaged
          trigger:
            type: event
            name: UNIT_DAMAGED
          handler_method: onUnitDamaged
          actions: [...]

      # Helper methods needed (extracted from actions)
      helpers:
        - name: playSound
          params: [soundName]
        - name: animate
          params: [entityId, animName, duration]

  client_systems:
    - id: UISystem
      runtime: client
      # ... similar structure

  network_protocol:
    client_messages:
      HERO_MOVE_REQ: 1001
      HERO_ATTACK_REQ: 1002
    server_messages:
      HERO_STATE_UPDATE: 2001
      COMBAT_RESULT: 2002

  event_ids:
    - PLAYER_JOINED
    - PLAYER_LEFT
    - HERO_DAMAGED
    - HERO_REVIVED

  functions_needing_llm:
    - system: HeroSystem
      type: query
      method: getMaxHP
      spec: {...}
    - system: HeroSystem
      type: command
      method: reviveHero
      spec: {...}
```

**Exit Codes**:
- 0: Success
- 1: Validation errors
- 2: File I/O errors

---

### Phase 2: Deterministic Lua Generation

**Program: `generate_lua_stubs.py`**

```bash
python generate_lua_stubs.py <GAME_DIR>
```

**Purpose**: Generate all structural Lua code using templates

**Actions**:

#### 2.1 Generate Runtime Definitions

**Template**: `templates/Protocol.lua.j2`

```lua
-- Protocol.lua (auto-generated)

local Protocol = {}

-- Client-to-Server message IDs
Protocol.ClientMSGID = {
    {% for msg in client_messages %}
    {{msg.name}} = {{msg.id}},
    {% endfor %}
}

-- Server-to-Client message IDs
Protocol.ServerMSGID = {
    {% for msg in server_messages %}
    {{msg.name}} = {{msg.id}},
    {% endfor %}
}

return Protocol
```

**Template**: `templates/EventID.lua.j2`

```lua
-- EventID.lua (auto-generated)

local EventID = {}

{% for event in events %}
EventID.{{event.id}} = "{{event.id}}"
{% endfor %}

return EventID
```

#### 2.2 Generate Business System Modules

**Template**: `templates/SystemServer.lua.j2`

```lua
--[[
    {{system_name}}Server - {{system_description}}

    System Type: server
    Dependencies: {{dependencies}}

    Auto-generated by SystemLuaGen
]]

local {{system_name}}Server = {}

-- ========== METADATA ==========
{{system_name}}Server.name = "{{system_name}}Server"
{{system_name}}Server.version = "1.0.0"
{{system_name}}Server.description = "{{system_description}}"
{{system_name}}Server.dependencies = { {% for dep in dependencies %}"{{dep}}",{% endfor %} }
{{system_name}}Server.state = "uninitialized"

-- Framework references
{{system_name}}Server.sgf = nil
{{system_name}}Server.log = nil
{{system_name}}Server.events = nil

-- ========== DATA STORAGE ==========
{{system_name}}Server.data = {}

-- Cached dependencies (populated in PostInit)
{{system_name}}Server.dependencies_cache = {}

-- ========== CONSTRUCTOR ==========
function {{system_name}}Server.new(sgf)
    local self = setmetatable({}, {__index = {{system_name}}Server})

    -- Store framework reference
    self.sgf = sgf
    self.log = sgf.log
    self.events = sgf.events

    return self
end

-- ========== LIFECYCLE PHASE 1: PREINIT ==========
--[[
    PreInit - Register event listeners, prepare resources

    Called FIRST, before other systems exist.
    DO NOT access other systems here.
]]
function {{system_name}}Server:PreInit()
    self.log:info("[{{system_name}}Server] PreInit started")

    -- Register event handlers
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)

    {% for behavior in behaviors %}
    {% if behavior.trigger.type == "event" %}
    -- Behavior: {{behavior.id}}
    self.events:on(EventID.{{behavior.trigger.name}}, function(data)
        self:{{behavior.handler_method}}(data)
    end)
    {% endif %}
    {% endfor %}

    self.log:info("[{{system_name}}Server] PreInit complete")
    return true
end

-- ========== LIFECYCLE PHASE 2: INIT ==========
--[[
    Init - Initialize system, load configuration, register network handlers

    Called SECOND, after all PreInit.
    DO NOT access other systems here (use PostInit).
]]
function {{system_name}}Server:Init()
    self.log:info("[{{system_name}}Server] Init started")

    -- Load configuration
    self.config = {
        -- TODO: Add configuration values
    }

    {% if has_network %}
    -- Register network handlers
    self:registerNetworkHandlers()
    {% endif %}

    -- Initialize data structures
    -- TODO: Initialize self.data

    self.state = "initialized"
    self.log:info("[{{system_name}}Server] Init complete")
    return true
end

-- ========== LIFECYCLE PHASE 3: POSTINIT ==========
--[[
    PostInit - Resolve dependencies on other systems

    Called THIRD, after all Init.
    NOW safe to access other systems.
]]
function {{system_name}}Server:PostInit()
    self.log:info("[{{system_name}}Server] PostInit started")

    -- Get dependency references
    {% for dep in dependencies %}
    self.dependencies_cache.{{dep}} =
        self.sgf.businessSystemManager:get("{{dep}}Server")

    if not self.dependencies_cache.{{dep}} then
        self.log:error("[{{system_name}}Server] Missing dependency: {{dep}}Server")
        return false
    end
    {% endfor %}

    self.log:info("[{{system_name}}Server] PostInit complete")
    return true
end

-- ========== LIFECYCLE PHASE 4: START ==========
--[[
    Start - Begin operations, start timers, activate features

    Called FOURTH, after all PostInit.
    All systems are fully initialized.
]]
function {{system_name}}Server:Start()
    self.log:info("[{{system_name}}Server] Start started")

    -- TODO: Start periodic tasks, spawn entities, etc.

    self.state = "started"
    self.log:info("[{{system_name}}Server] Started successfully")
    return true
end

-- ========== LIFECYCLE PHASE 5: UPDATE ==========
--[[
    Update - Called every frame

    Optional: Most systems don't need this
]]
function {{system_name}}Server:Update(dt)
    -- Optional: Implement frame updates if needed
end

-- ========== LIFECYCLE PHASE 6: STOP ==========
--[[
    Stop - Clean up resources

    Called when system is shutting down.
]]
function {{system_name}}Server:Stop()
    self.log:info("[{{system_name}}Server] Stopping...")

    -- TODO: Save data, clean up timers, release resources

    self.state = "stopped"
    self.log:info("[{{system_name}}Server] Stopped")
    return true
end

{% if has_network %}
-- ========== NETWORK HANDLERS ==========
function {{system_name}}Server:registerNetworkHandlers()
    -- Register as network object
    local NetworkHelper = require(script.Parent.Parent.Parent.GamePlay.NetworkHelper)
    NetworkHelper:RegisterNetObj(self)

    -- Import protocol definitions
    local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

    {% for action in player_actions %}
    -- Player action: {{action.id}}
    self:OnRequest(Protocol.ClientMSGID.{{action.message_id}}, function(userId, msgid, data)
        return self:{{action.method_name}}(userId, data)
    end)
    {% endfor %}
end

{% for action in player_actions %}
-- Player Action: {{action.id}}
function {{system_name}}Server:{{action.method_name}}(userId, data)
    self.log:debug("[{{system_name}}Server] {{action.id}} from user:", userId)

    -- TODO_LLM: Implement {{action.id}}
    -- Available: userId, data.{{action.params|join(', data.')}}

    return {
        success = false,
        error = "Not implemented"
    }
end

{% endfor %}
{% endif %}

-- ========== BEHAVIOR HANDLERS (AUTO-GENERATED) ==========
{% for behavior in behaviors %}

-- Behavior Handler: {{behavior.id}}
-- Trigger: {{behavior.trigger.type}} {{behavior.trigger.name}}
function {{system_name}}Server:{{behavior.handler_method}}(data)
    {% if behavior.authority == "server" %}
    -- Authority check
    if not self.sgf.isServer then
        self.log:warn("[{{system_name}}Server] Authority violation: {{behavior.id}} requires server")
        return
    end
    {% endif %}

    {% if behavior.safety.once %}
    -- Safety: once check
    -- TODO: Implement once-only tracking
    {% endif %}

    {% for condition in behavior.conditions %}
    -- Condition: {{condition.type}}
    -- TODO: Check {{condition}}
    {% endfor %}

    {% for action in behavior.actions %}
    -- Action: {{action.type}}
    {% if action.type == "play_sound" %}
    self:playSound("{{action.sound}}")
    {% elif action.type == "animate" %}
    self:animate(data.target_ref, "{{action.animation}}", {{action.duration_s}})
    {% elif action.type == "set_state" %}
    self:setState(data.target_ref, {{action.state}})
    {% elif action.type == "call_method" %}
    self:{{action.method}}({{action.args}})
    {% endif %}
    {% endfor %}

    {% if behavior.network.broadcast_event %}
    -- Broadcast event
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.{{behavior.network.broadcast_event}}, {
        -- TODO: Add payload
    })
    {% endif %}
end
{% endfor %}

-- ========== QUERIES (LLM-IMPLEMENTED) ==========
{% for query in queries %}

-- LLM_IMPL
-- Query: {{query.id}}({{query.params|join(', ')}}) -> {{query.returns}}
-- Description: {{query.description}}
function {{system_name}}Server:{{query.method_name}}({{query.params|join(', ')}})
    -- TODO_LLM: Implement {{query.id}}
    -- Parameters: {{query.params|join(', ')}}
    -- Returns: {{query.returns}}
    -- Context: self.ctx.entities

    {% if query.returns == "int" %}
    return 0
    {% elif query.returns == "bool" %}
    return false
    {% elif query.returns == "string" %}
    return ""
    {% else %}
    return nil
    {% endif %}
end
{% endfor %}

-- ========== COMMANDS (LLM-IMPLEMENTED) ==========
{% for command in commands %}

-- LLM_IMPL
-- Command: {{command.id}}({{command.params|join(', ')}}) -> {{command.returns}}
-- Description: {{command.description}}
-- Emits: {{command.emits|join(', ')}}
function {{system_name}}Server:{{command.method_name}}({{command.params|join(', ')}})
    -- TODO_LLM: Implement {{command.id}}
    -- Parameters: {{command.params|join(', ')}}
    -- Returns: {{command.returns}}

    {% for event in command.emits %}
    -- Must emit: {{event}}
    local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
    self.events:emit(EventID.{{event}}, {
        -- TODO: Add payload
    })
    {% endfor %}

    return false
end
{% endfor %}

-- ========== HELPER METHODS (STUBS) ==========
{% for helper in helpers %}

function {{system_name}}Server:{{helper.name}}({{helper.params|join(', ')}})
    -- TODO: Implement {{helper.name}}
    self.log:info("[{{system_name}}Server] {{helper.name}} called")
end
{% endfor %}

return {{system_name}}Server
```

#### 2.3 Generate Entry Points

**Template**: `templates/ServerMain.lua.j2`

```lua
--[[
    ServerMain.lua - Server entry point
    ClassType: Script (auto-runs on server start)

    Auto-generated by SystemLuaGen
]]

print("[ServerMain] Server starting...")

-- Get services
local MainStorage = game:GetService("MainStorage")
local RunService = game:GetService("RunService")

-- Load SGF Framework
local SGFFramework = require(MainStorage.Framework.SGFFramework)

-- Create framework instance
local sgf = SGFFramework.new()

-- Initialize framework
sgf:Init({
    systems = {}  -- Legacy systems (optional)
})

-- Set environment flags (REQUIRED for authority checks)
sgf.isServer = RunService:IsServer()
sgf.isClient = RunService:IsClient()

print("[ServerMain] SGF Framework initialized")

-- Load business system modules
{% for system in server_systems %}
local {{system.name}}Server = require(MainStorage.Framework.GameSystems.{{system.name}}.{{system.name}}Server)
{% endfor %}

-- Create system instances
{% for system in server_systems %}
local {{system.var_name}} = {{system.name}}Server.new(sgf)
{% endfor %}

-- Register systems with framework
{% for system in server_systems %}
sgf.businessSystemManager:register("{{system.name}}Server", {{system.var_name}})
{% endfor %}

print("[ServerMain] Systems registered")

-- Initialize all systems (PreInit → Init → PostInit → Start)
local systemsToInit = {
    {% for system in server_systems %}
    {{system.var_name}},
    {% endfor %}
}

-- Phase 1: PreInit
for _, system in ipairs(systemsToInit) do
    if system.PreInit then
        system:PreInit()
    end
end

-- Phase 2: Init
for _, system in ipairs(systemsToInit) do
    if system.Init then
        system:Init()
    end
end

-- Phase 3: PostInit (dependency resolution)
for _, system in ipairs(systemsToInit) do
    if system.PostInit then
        system:PostInit()
    end
end

-- Phase 4: Start
for _, system in ipairs(systemsToInit) do
    if system.Start then
        system:Start()
    end
end

print("[ServerMain] All systems started")

-- Main update loop
RunService.Stepped:Connect(function()
    sgf:Update(0.033)  -- ~30 FPS
end)

print("[ServerMain] Server initialized successfully")
```

**Template**: `templates/ClientMain.lua.j2` - Similar pattern for client systems

**Template**: `templates/json_config.j2` - JSON configurations for all files

#### 2.4 Behavior DSL to Lua Conversion Rules

**Module**: `behavior_converter.py`

| Behavior Trigger | Generated Code |
|-----------------|----------------|
| `type: event` | Register listener in PreInit + handler method |
| `type: timer` | Register timer in Start + handler method |
| `type: action` | Network handler registration in Init |
| `type: init` | Code in Start() method |

| Action Type | Generated Lua |
|-------------|---------------|
| `play_sound` | `self:playSound(soundName)` |
| `animate` | `self:animate(entityId, animName, duration)` |
| `set_state` | `self:setState(entityId, state)` |
| `emit` | `self.events:emit(EventID.EVENT_NAME, payload)` |
| `call_method` | `self:methodName(args)` |

**Output**:
- System modules with TODO_LLM markers
- Protocol.lua and EventID.lua
- ServerMain.lua and ClientMain.lua
- All JSON configuration files
- `_intermediate/lua_stubs_generated.yml` (metadata)

**Exit Codes**:
- 0: Success
- 2: Template errors, file write errors

---

### Phase 3: LLM Implementation

**Two Modes Available** (configured in `config.yml`):

#### Mode Selection

Edit `config.yml` to choose implementation mode:

```yaml
implementation:
  mode: "direct"  # or "agent"
```

**Mode 1: Direct Mode** (default) - Uses `implement_functions.py`
**Mode 2: Agent Mode** - Spawns a subagent for implementation

---

#### Mode 1: Direct Mode (implement_functions.py)

**Program: `implement_functions.py`**

```bash
python implement_functions.py <GAME_DIR> [--system <system_name>] [--dry-run] [--parallel]
```

**When to Use**:
- Standard automated implementation
- Batch processing of multiple systems
- When you want parallel LLM calls (--parallel flag)
- Simpler deployment (no agent management)

**How It Works**:

##### 3.1.1 For Each TODO_LLM Marker

1. **Extract Context**:
   - Function signature and spec
   - Entity definitions used
   - Related methods from same system
   - Example implementations (if available)

2. **Build Focused Prompt**:

```
You are implementing a Lua method for a business system in MiniWorld Studio's SGF Framework.

SYSTEM: {{system_name}}Server
METHOD: {{method_name}}

FUNCTION SIGNATURE (DO NOT CHANGE):
function {{system_name}}Server:{{method_name}}({{params}})
    -- returns: {{returns}}
end

SPECIFICATION:
- Description: {{description}}
- Parameters:
  {{params_description}}
- Returns: {{returns_description}}

ENTITY DEFINITIONS USED BY THIS SYSTEM:
{{entities}}

(Extracted from specs/{{system_name}}.yml data.entities section)

ENTITY ACCESS:
- Entities are stored in self.data.EntityName[id]
- Example: local hero = self.data.HeroInstance[hero_id]
- Event emission: self.events:emit(EventID.EVENT_NAME, payload)
- Logging: self.log:info("message"), self.log:error("error")
- Dependencies: self.dependencies_cache.SystemName:method()

SGF FRAMEWORK CONTEXT:
- self.sgf = framework instance
- self.log = logging service
- self.events = event bus
- self.dependencies_cache = cached system references

REQUIREMENTS:
1. Keep the exact function signature
2. Use self.log for logging
3. Use self.events:emit() for events
4. Handle edge cases (nil checks)
5. Return the specified type
6. Follow MiniWorld Studio patterns

{% if method_type == "command" and emits %}
MUST EMIT EVENTS: {{emits}}
{% endif %}

IMPLEMENT ONLY THE FUNCTION BODY (between function...end):
```

3. **Call LLM**:
   ```python
   response = llm.generate(prompt, temperature=0.2, max_tokens=500)
   ```

4. **Validate LLM Output**:
   - Parse Lua code
   - Check signature unchanged
   - Verify syntax with `luac -p`
   - For commands: verify `emit()` calls match spec
   - Check no forbidden patterns

5. **Replace TODO_LLM**:
   - Extract function body
   - Replace marker with implementation
   - Preserve comments and metadata

**Output**:
- Updated `*.lua` files with implementations
- `_intermediate/llm_implementation_log.yml`

**Exit Codes**:
- 0: All functions implemented
- 1: Some functions failed
- 2: LLM API errors

---

#### Mode 2: Agent Mode (Subagent)

**Execution**: Spawn a specialized subagent for implementation

```
Use Task tool with subagent_type='miniworld-lua-expert'
```

**When to Use**:
- More complex implementation scenarios
- When you need interactive decision-making
- Custom implementation strategies per system
- When you want human-like code review during implementation

**How It Works**:

##### 3.2.1 Prepare Context for Agent

1. Load generation plan and entities registry
2. Identify all systems with TODO_LLM markers
3. Prepare comprehensive context including:
   - All system specs
   - Entity definitions
   - Generated Lua stubs
   - SGF Framework patterns

##### 3.2.2 Spawn Subagent

```python
# In Claude Code environment, the workflow executor would:
# Task tool call with:
# - subagent_type: 'miniworld-lua-expert'
# - prompt: Comprehensive implementation instructions
```

**Agent Prompt Structure**:

```
You are a MiniWorld Studio Lua implementation expert tasked with completing
all TODO_LLM function implementations in the generated business systems.

GAME DIRECTORY: <GAME_DIR>

CONTEXT:
1. Generation Plan: <path to lua_generation_plan.yml>
2. Entities Registry: <path to entities_registry.yml>
3. Generated Lua Files: <list of files with TODO_LLM markers>

SYSTEMS TO IMPLEMENT:
{{for each system}}
- System: {{system_name}}
  Runtime: {{runtime}}
  File: {{lua_file_path}}
  Functions: {{list of TODO_LLM functions}}
{{end}}

SGF FRAMEWORK PATTERNS:
- Business systems follow PreInit → Init → PostInit → Start lifecycle
- Use self.data for entity storage
- Use self.events:emit() for events
- Use self.dependencies_cache for system references
- Follow MiniWorld Studio Lua conventions

YOUR TASK:
1. Read each Lua file with TODO_LLM markers
2. Implement each function following the specifications in comments
3. Ensure implementations match entity definitions
4. Validate syntax and patterns
5. Report progress and any issues

IMPLEMENTATION GUIDELINES:
- Queries: READ-ONLY, no side effects
- Commands: MODIFY state, emit events
- Player actions: Handle network requests, validate input

Proceed to implement all functions systematically.
```

##### 3.2.3 Agent Execution

The subagent will:
1. Read all relevant files
2. Implement functions one by one
3. Use Edit tool to replace TODO_LLM markers
4. Validate implementations
5. Report completion status

**Output**:
- Updated `*.lua` files with implementations
- Agent's execution log and decisions
- Summary report of implementations

**Exit Codes**:
- 0: All functions implemented successfully
- 1: Some implementations failed or incomplete
- 2: Agent execution error

---

#### Choosing the Right Mode

| Criteria | Direct Mode | Agent Mode |
|----------|-------------|------------|
| Speed | Faster (parallel) | Slower (sequential) |
| Complexity | Simple functions | Complex logic |
| Interaction | None | Can ask questions |
| Debugging | Log files | Interactive feedback |
| Control | Automated | More control |
| Best for | Batch processing | Custom scenarios |

**Recommendation**:
- Start with **Direct Mode** for most projects
- Use **Agent Mode** when you need more control or face complex implementation challenges

---

### Phase 4: Validation & Testing

**Program: `validate_lua.py`**

```bash
python validate_lua.py <GAME_DIR>
```

**Purpose**: Final validation of all generated Lua code

**Actions**:

#### 4.1 Syntax Validation
```bash
luac -p <file.lua>
```

#### 4.2 SGF Pattern Validation

Check that all systems follow SGF pattern:
- Has `.new(sgf)` constructor
- Has lifecycle methods: PreInit, Init, PostInit, Start
- Registers with businessSystemManager in ServerMain
- Uses correct dependency resolution (PostInit)

#### 4.3 Contract Validation

- All events emitted are declared in EventID.lua
- All network messages are declared in Protocol.lua
- All event subscriptions reference valid events
- All dependencies exist

#### 4.4 Generate Validation Report

```yaml
validation_report:
  timestamp: "2025-01-21T10:30:00Z"

  syntax_check:
    status: PASS
    files_checked: 15
    errors: []

  sgf_pattern_check:
    status: PASS
    systems_validated: 5
    lifecycle_methods_present: true

  contract_check:
    status: PASS
    event_contracts_validated: 23
    network_contracts_validated: 18

  overall_status: PASS
```

**Output**: `_intermediate/lua_validation_report.yml`

**Exit Codes**:
- 0: All validations passed
- 1: Validation errors found
- 2: Missing tools (luac)

---

## Tool Requirements

### Python Dependencies

```
pip install pyyaml jinja2 anthropic openai
```

### External Tools

- **Lua 5.1** with `luac` compiler for syntax checking
- **LLM API access** (Claude API or OpenAI API)

### Templates

All Jinja2 templates stored in:
```
workflow/ExecUnits/SystemLuaGen/templates/
├── SystemServer.lua.j2
├── SystemClient.lua.j2
├── ServerMain.lua.j2
├── ClientMain.lua.j2
├── Protocol.lua.j2
├── EventID.lua.j2
├── json_config.j2
└── behavior_converter.py
```

---

## Configuration

**Config File**: `workflow/ExecUnits/SystemLuaGen/config.yml`

```yaml
llm:
  provider: "anthropic"  # or "openai"
  model: "claude-3-5-sonnet-20241022"
  api_key_env: "ANTHROPIC_API_KEY"
  temperature: 0.2
  max_tokens: 1000

lua:
  version: "5.1"
  luac_path: "luac"

validation:
  forbidden_patterns:
    - "os.execute"
    - "io.open"
    - "loadstring"

generation:
  retry_on_failure: true
  max_retries: 3
  skip_on_error: false
```

---

## Error Handling

### Common Errors

1. **Missing SGF Framework**: Ensure framework exists in `MainStorage/Framework/`
2. **Wrong Lua version**: MiniWorld Studio uses Lua 5.1
3. **Missing dependencies**: Check all system dependencies exist
4. **Authority check failures**: Ensure `sgf.isServer` is set in ServerMain

---

## Usage Examples

### Full Generation Pipeline

```bash
cd workflow/ExecUnits/SystemLuaGen

# Phase 1: Analyze
python analyze_specs.py ../../projects/castle_defense/

# Phase 2: Generate stubs
python generate_lua_stubs.py ../../projects/castle_defense/

# Phase 3: LLM implementation
export ANTHROPIC_API_KEY="sk-ant-..."
python implement_functions.py ../../projects/castle_defense/

# Phase 4: Validate
python validate_lua.py ../../projects/castle_defense/
```

---

## Integration with MiniWorld Studio

Generated files match MiniWorld Studio's expected structure:
```
<GAME_DIR>/ServiceNodes/MainStorage/Framework/
```

Import the `<GAME_DIR>` folder into MiniWorld Studio Editor and systems will be automatically discovered by SGF Framework.

---

## Key Design Principles

1. **Use SGF Framework** - Don't reinvent, integrate with existing framework
2. **Follow SGF Lifecycle** - PreInit → Init → PostInit → Start
3. **Proper Dependency Resolution** - Access systems only in PostInit/Start
4. **Network via Protocol** - Use NetworkHelper + Protocol pattern
5. **Events via EventBus** - Use SGF's event bus, don't create new one

---

## Exit Codes Summary

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Validation/contract errors |
| 2 | File I/O or API errors |

---

**Status**: Revised to match MiniWorld Studio SGF Framework patterns

**Version**: 2.0 (SGF-compliant)
