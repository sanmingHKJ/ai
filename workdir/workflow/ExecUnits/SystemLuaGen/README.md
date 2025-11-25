# SystemLuaGen - System Specification to Lua Code Generator

**Version 2.0 - SGF-Compliant**

Converts system specifications (YAML) into executable Lua code for MiniWorld Studio's SGF (Studio Game Framework).

## Overview

SystemLuaGen uses a **hybrid deterministic + LLM approach**:
- **Deterministic Generation** (Program) - SGF lifecycle, network wiring, behavior handlers
- **LLM Implementation** (AI) - Game-specific logic for queries, commands, helpers

This ensures correct SGF Framework integration while allowing creative game-specific implementation.

## Directory Structure

```
workflow/ExecUnits/SystemLuaGen/
├── README.md                    # This file
├── config.yml                   # Configuration
├── analyze_specs.py             # Phase 1: Analysis
├── generate_lua_stubs.py        # Phase 2: Code generation
├── implement_functions.py       # Phase 3: LLM implementation (optional)
├── validate_lua.py              # Phase 4: Validation
└── templates/                   # Jinja2 templates
    ├── Protocol.lua.j2
    ├── EventID.lua.j2
    ├── SystemServer.lua.j2
    ├── SystemClient.lua.j2
    ├── ServerMain.lua.j2
    ├── ClientMain.lua.j2
    └── json_config.j2
```

## Usage

### Quick Start

```bash
cd workflow/ExecUnits/SystemLuaGen

# Phase 1: Analyze specifications
python analyze_specs.py ../../../projects/aaa3/

# Phase 2: Generate Lua code
python generate_lua_stubs.py ../../../projects/aaa3/

# Phase 4: Validate generated code
python validate_lua.py ../../../projects/aaa3/
```

### Phase 1: Analysis & Preparation

**Program:** `analyze_specs.py`

**Purpose:** Load and validate all inputs, build generation plan

**Input:**
- `<GAME_DIR>/UnitsData/specs/*.yml` - System specifications
- `<GAME_DIR>/UnitsData/global_registry.yml` - Event/query/command registry
- `<GAME_DIR>/UnitsData/systems_contracts.yml` - Integration contracts

**Output:**
- `<GAME_DIR>/UnitsData/_intermediate/entities_registry.yml` - Entity definitions
- `<GAME_DIR>/UnitsData/_intermediate/lua_generation_plan.yml` - Generation plan

**Example:**
```bash
python analyze_specs.py ../../../projects/castle_defense/
```

### Phase 2: Deterministic Lua Generation

**Program:** `generate_lua_stubs.py`

**Purpose:** Generate structural Lua code using Jinja2 templates

**Output:**
- `<GAME_DIR>/ServiceNodes/MainStorage/Framework/Runtime/Protocol.lua` - Network message IDs
- `<GAME_DIR>/ServiceNodes/MainStorage/Framework/Runtime/EventID.lua` - Event IDs
- `<GAME_DIR>/ServiceNodes/MainStorage/Framework/GameSystems/<System>/<System>Server.lua` - Business systems
- `<GAME_DIR>/ServiceNodes/ServerScriptService/ServerMain.lua` - Server entry point
- `<GAME_DIR>/ServiceNodes/StartPlayer/StarterPlayerScripts/ClientMain.lua` - Client entry point
- `<GAME_DIR>/UnitsData/_intermediate/lua_stubs_generated.yml` - Generation metadata

**Example:**
```bash
python generate_lua_stubs.py ../../../projects/castle_defense/
```

### Phase 3: LLM Implementation (Optional)

**Program:** `implement_functions.py`

**Purpose:** Use LLM to implement query/command/action function bodies

**Requirements:**
- Anthropic API key (set ANTHROPIC_API_KEY environment variable)
- Or OpenAI API key (set OPENAI_API_KEY environment variable)

**Example:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
python implement_functions.py ../../../projects/castle_defense/
```

**Note:** This phase is optional. You can manually implement the TODO_LLM sections or skip this step for prototyping.

### Phase 4: Validation & Testing

**Program:** `validate_lua.py`

**Purpose:** Validate generated Lua code for syntax and contract compliance

**Checks:**
- Lua syntax validation (using luac if available)
- SGF pattern validation (lifecycle methods, constructor)
- Event contract validation (event references)
- Network contract validation (message references)

**Output:**
- `<GAME_DIR>/UnitsData/_intermediate/lua_validation_report.yml` - Validation report

**Example:**
```bash
python validate_lua.py ../../../projects/castle_defense/
```

## Generated Code Structure

```
<GAME_DIR>/ServiceNodes/
├── StartPlayer/StarterPlayerScripts/
│   ├── ClientMain.lua              # Client entry point
│   └── ClientMain.json
├── ServerScriptService/
│   ├── ServerMain.lua              # Server entry point
│   └── ServerMain.json
└── MainStorage/Framework/
    ├── Runtime/
    │   ├── Protocol.lua            # Network message IDs
    │   ├── Protocol.json
    │   ├── EventID.lua             # Event IDs
    │   └── EventID.json
    └── GameSystems/
        ├── HeroSystem/
        │   ├── HeroSystemServer.lua
        │   └── HeroSystemServer.json
        ├── CombatSystem/
        │   ├── CombatSystemServer.lua
        │   └── CombatSystemServer.json
        └── ...
```

## SGF Framework Integration

### Pre-Existing Framework (DO NOT GENERATE)

These files are part of MiniWorld Studio's SGF Framework:
- `Framework/SGFFramework.lua`
- `Framework/Core/BusinessSystemManager.lua`
- `Framework/Core/EventBus.lua`
- `Framework/Core/ServiceContainer.lua`
- `Framework/GamePlay/NetworkHelper.lua`

### Generated Per-Game (DO GENERATE)

These files are game-specific:
- `Framework/Runtime/Protocol.lua` - Network message IDs
- `Framework/Runtime/EventID.lua` - Event IDs
- `Framework/GameSystems/<System>/<System>Server.lua` - Business systems
- `ServerMain.lua` / `ClientMain.lua` - Entry points

## SGF Lifecycle Pattern

All generated business systems follow the SGF lifecycle:

```lua
-- Phase 1: PreInit - Register event listeners
function SystemServer:PreInit()
    self.events:on(EventID.SOME_EVENT, function(data)
        self:onSomeEvent(data)
    end)
end

-- Phase 2: Init - Load config, register network
function SystemServer:Init()
    self:registerNetworkHandlers()
end

-- Phase 3: PostInit - Resolve dependencies
function SystemServer:PostInit()
    self.dependencies_cache.OtherSystem =
        self.sgf.businessSystemManager:get("OtherSystemServer")
end

-- Phase 4: Start - Begin operations
function SystemServer:Start()
    -- Start timers, spawn entities, etc.
end

-- Phase 5: Update - Frame updates (optional)
function SystemServer:Update(dt)
    -- Frame logic
end

-- Phase 6: Stop - Cleanup
function SystemServer:Stop()
    -- Save data, release resources
end
```

## Configuration

Edit `config.yml` to customize:

```yaml
llm:
  provider: "anthropic"
  model: "claude-3-5-sonnet-20241022"
  api_key_env: "ANTHROPIC_API_KEY"

lua:
  version: "5.1"
  luac_path: "luac"

validation:
  strict_mode: false
  forbidden_patterns:
    - "os.execute"
    - "io.open"
```

## Troubleshooting

### "lua_generation_plan.yml not found"

Run Phase 1 (analyze_specs.py) first to generate the plan.

### "luac not found" warning

Install Lua 5.1 to enable syntax checking:
- Windows: Download from https://luabinaries.sourceforge.net/
- Linux: `sudo apt-get install lua5.1`
- macOS: `brew install lua@5.1`

### Validation warnings about unknown events/messages

This is normal if the system specs are incomplete. The warnings indicate that behavior handlers or player actions reference events/messages that weren't registered in the global registry. You can:
1. Update the specs to add missing events/messages
2. Manually fix the generated code
3. Ignore warnings if they're intentional

### "SGF Framework not found" error

Ensure your game project has the SGF Framework installed in:
`<GAME_DIR>/ServiceNodes/MainStorage/Framework/`

## Testing Generated Code

1. Import `<GAME_DIR>/ServiceNodes/` into MiniWorld Studio Editor
2. The systems will be automatically discovered by SGF Framework
3. Run the game to test

## Key Design Principles

1. **Use SGF Framework** - Integrate with existing framework, don't reinvent
2. **Follow SGF Lifecycle** - PreInit → Init → PostInit → Start
3. **Proper Dependency Resolution** - Access systems only in PostInit/Start
4. **Network via Protocol** - Use NetworkHelper + Protocol pattern
5. **Events via EventBus** - Use SGF's event bus

## Implementation Status

✅ **Complete:**
- analyze_specs.py - Analysis and planning
- generate_lua_stubs.py - Code generation with templates
- validate_lua.py - Syntax and contract validation
- Jinja2 templates for all file types
- SGF-compliant system structure

⏳ **Optional/Future:**
- implement_functions.py - LLM implementation of function bodies
- behavior_converter.py - Advanced behavior DSL to Lua conversion
- Interactive mode for manual review
- Parallel LLM calls for speed
- Test generation

## Version History

- **v2.0** - SGF-compliant generation (current)
- **v1.0** - Initial solution (outdated, see SPEC_TO_LUA_SOLUTION.md)

## References

- `exec-flow.md` - Detailed execution flow specification
- `MINIWORLD_STUDIO_ANALYSIS.md` - SGF framework analysis
- `SPEC_TO_LUA_SOLUTION.md` - Original v1 solution (outdated)
