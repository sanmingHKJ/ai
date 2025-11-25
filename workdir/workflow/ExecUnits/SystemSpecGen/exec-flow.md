# SystemSpecGen: Orchestrator for System Specification Generation

**EXECUTION UNIT INSTRUCTIONS (MiniWorld Studio)**

## Unit Role

Orchestrate the generation of behavior-focused system specifications using a **two-pass approach**:

1. **Reading** all systems from `systems_plan.yml`
2. **Pass 1 - Skeletons**: Generate lightweight skeletons for ALL systems (IDs, signatures only)
3. **Build Global Registry**: Use `build_global_registry.py` to collect all event/query/command IDs across systems
4. **Pass 2 - Full Specs**: Generate complete individual specs with behaviors using the registry
5. **Generate Contracts**: Use `generate_contracts.py` to create cross-system contracts with integration graph in `systems_contracts.yml`

This two-pass approach:
- Prevents context overflow (each subagent handles one system)
- Ensures consistent cross-system references (registry provides canonical IDs)
- Eliminates event name mismatches between producer and consumer
- Uses Python tools for deterministic registry and contract generation (not LLM)

## Output Schema

Generated specs conform to this simplified, behavior-focused schema.

**Schema Definition**: See `systems_spec_schema.yml` for complete schema structure.

**Individual System Schema**: See `system_spec_schema.yml` for single system specification schema.

**Skeleton Schema**: See `system_skeleton_schema.yml` for minimal skeleton template.

---

## Behavior Trigger Types

Behaviors are triggered by four distinct event channels that represent different runtime execution paths:

### 1. on_action - Player Input Entrypoint

**Purpose**: Handle player-initiated actions defined in `interface.player_actions`

**Structure**:
```yaml
trigger:
  type: "action"
  name: "ACTION_HERO_MOVE"  # Must match a player_action.id
```

**When to use**:
- Player explicitly initiates logic (taps, clicks, button presses)
- Logic represents player intent, not world-caused events
- Direct 1:1 mapping from UI input to game logic

**Examples**:
- Move hero
- Attack target
- Cast spell
- Open inventory
- Buy item
- Submit crafting recipe

**Lua Generation**:
```lua
function HeroSystem:on_ACTION_HERO_MOVE(payload)
    -- payload.hero_id, payload.target_position
end
```

---

### 2. on_event - System-to-System Communication

**Purpose**: React to events emitted by other systems (or self)

**Structure**:
```yaml
trigger:
  type: "event"
  name: "HERO_DAMAGED"  # Must match an event from events.subscribes
```

**When to use**:
- System needs to react to state changes in other systems
- Loose coupling between systems is desired
- Multiple systems need to respond to the same event
- Event-driven reactive logic

**Examples**:
- Hero damaged → update UI, play sound, check for death
- XP gained → check for level-up
- Gold spent → update UI, check achievements
- Match started → spawn heroes, initialize timers

**Lua Generation**:
```lua
function UISystem:on_HERO_DAMAGED(payload)
    -- payload.target_id, payload.amount
    self:update_health_bar(payload.target_id)
end
```

---

### 3. on_timer - Time-Based Periodic Logic

**Purpose**: Execute logic periodically based on time intervals

**Structure**:
```yaml
trigger:
  type: "timer"
  name: "match_tick"    # Timer identifier
  every: 0.1            # Interval in seconds
```

**When to use**:
- Logic depends on time passing
- Not triggered by specific events or actions
- Needs periodic checks or updates
- Continuous effects over time

**Examples**:
- Respawn checking (every 1.0s)
- Poison/DOT damage (every 0.5s)
- Auto-heal over time (every 2.0s)
- Buff expiration checks (every 0.1s)
- AI behavior updates (every 0.2s)
- Network state sync (every 0.05s)
- Energy/mana regeneration (every 1.0s)

**Timer Types**:
- `match_tick` - Global game tick (common: 0.05-0.2s)
- `slow_tick` - Slower updates (common: 1.0-5.0s)
- Custom named timers for specific purposes

**Lua Generation**:
```lua
function CombatSystem:on_timer_match_tick(dt)
    -- dt = time delta since last call
    self:process_dot_effects(dt)
    self:check_respawns(dt)
end
```

---

### 4. on_init - Initialization Logic

**Purpose**: One-time setup when system loads or match begins

**Structure**:
```yaml
trigger:
  type: "init"
  # No 'name' field needed
```

**When to use**:
- Initialize data structures
- Load configuration files
- Register NPCs, towers, spawn points
- Set default values
- Preload entity definitions
- Clear temporary state
- Perform dependency checks

**Examples**:
- Load hero stat tables
- Initialize damage calculation formulas
- Register spawn points
- Set up match configuration
- Preload item definitions
- Initialize random seeds

**Lua Generation**:
```lua
function HeroSystem:on_init()
    self.heroes = {}
    self.spawn_points = {}
    self:load_hero_definitions()
end
```

---

## Trigger Type Selection Guide

| Trigger Type | Source | Frequency | Use Case |
|--------------|--------|-----------|----------|
| `action` | Player input | On demand | Direct player intent |
| `event` | Other systems | On state change | Reactive cross-system logic |
| `timer` | Runtime clock | Periodic | Time-based effects, polling |
| `init` | System startup | Once | Setup and configuration |

**Decision Tree**:
1. Is this initialization logic? → `on_init`
2. Is this triggered by player input? → `on_action`
3. Does this happen periodically over time? → `on_timer`
4. Is this triggered by another system's state change? → `on_event`

---

## Inputs

- **Type**: GameIntentData
- **File**: `game_intent.md`

- **Type**: SystemsPlanData
- **File**: `systems_plan.yml`

## Outputs

### Final Outputs

Individual system specifications:
- **Type**: SystemSpecData
- **Directory**: `specs/`
- **Pattern**: `specs/{SystemId}.yml`

Cross-system contracts:
- **Type**: SystemContractsData
- **File**: `systems_contracts.yml`

### Intermediate Outputs (for debugging/resumability)

All intermediate files are written to `_intermediate/` subdirectory:

| Phase | File Pattern | Description |
|-------|-------------|-------------|
| 2A | `_intermediate/{SystemId}_skeleton.yml` | Skeleton for each system |
| 2B | `global_registry.yml` | Combined registry of all IDs |

Example structure:
```
project/
├── game_intent.md
├── systems_plan.yml
├── systems_contracts.yml      # Final output
├── global_registry.yml        # Final output
├── _intermediate/
│   ├── CombatSystem_skeleton.yml
│   ├── HeroSystem_skeleton.yml
│   └── GoldSystem_skeleton.yml
└── specs/                     # Final individual specs
    ├── CombatSystem.yml
    ├── HeroSystem.yml
    └── GoldSystem.yml
```

---

## Python Tools

Several phases use Python tools instead of LLM for deterministic processing:

| Tool | Phase | Description |
|------|-------|-------------|
| `build_global_registry.py` | 2B | Build registry from skeletons |
| `generate_contracts.py` | 3 | Generate contracts and integration graph |
| `validate_spec_schema.py` | Any | Validate YAML against schema |
| `check_naming_conventions.py` | Any | Check naming conventions |

Tools location: `workflow/ExecUnits/SystemSpecGen/`

### Usage Examples

```bash
# Phase 2B: Build global registry from skeletons
python build_global_registry.py ./project/_intermediate/

# Phase 3: Generate contracts from individual specs
python generate_contracts.py ./project/specs/ ./project/systems_contracts.yml

# Optional: Validate schema for all specs
python validate_spec_schema.py ./project/specs/ ./schemas/systems_spec_schema.yml

# Optional: Check naming conventions for all specs
python check_naming_conventions.py ./project/specs/
```

---

## Execution Flow

### Phase 1: Preparation

1. **Create directories** if they don't exist:
   - `_intermediate/` - for skeletons and registry
   - `specs/` - for final individual specs
2. **Read `systems_plan.yml`** and extract the list of all systems
3. **Read `game_intent.md`** and extract context summary:
   - Game name and genre
   - Core gameplay loop (brief)
   - Key resources and currencies
   - Win/lose conditions
   - Multiplayer mode (if any)
4. **Create context summary** (keep under 500 words) to pass to each per-system invocation

### Phase 2A: Skeleton Generation (Subagents)

Generate lightweight skeletons for ALL systems to establish the global ID registry.

#### Execution Model

```
Orchestrator
    ├── Subagent: Skeleton for SystemA
    ├── Subagent: Skeleton for SystemB
    ├── Subagent: Skeleton for SystemC
    └── ... (all systems in parallel)
```

#### Process

For each system in `systems_plan.systems`:

1. **Spawn subagent** with `single-system-spec-gen.md` in **skeleton mode**
   - Pass: context summary + system plan entry + `mode: "skeleton"`
   - Receive: skeleton YAML (IDs and signatures only)
2. **Write to file**: `_intermediate/{SystemId}_skeleton.yml`
3. **Store skeleton** in collection

#### Skeleton Output Structure

See `system_spec_skeleton_sample.yml` for example skeleton output structure.

#### Parallelization

**All systems can run in parallel** during skeleton phase since no cross-references are needed yet.

---

### Phase 2B: Build Global Registry

After all skeletons complete, build the **Global ID Registry** using the Python tool:

**IMPORTANT**: Use `build_global_registry.py` to generate `global_registry.yml` instead of LLM.

```bash
python build_global_registry.py <project_path>/_intermediate/
```

This tool will:
1. **Read all skeleton files** from `_intermediate/{SystemId}_skeleton.yml`
2. **Extract all event/query/command IDs** from each skeleton
3. **Check for duplicate IDs** - fail if same event ID from multiple producers
4. **Validate subscriptions** - ensure every `events_subscribe.event` exists in registry
5. **Normalize naming** - fix any convention violations
6. **Write registry** to `global_registry.yml`

**Schema Definition**: See `global_registry_schema.yml` for complete registry structure.

#### Error Handling and Recovery Loop

After running `build_global_registry.py`, check the exit code:

```
Build registry (run build_global_registry.py)
    ↓
Check exit code
    ↓
    ├─ SUCCESS (exit code = 0) → Continue to Phase 2C
    ↓
    └─ FAILURE (exit code != 0)
        ↓
        Retry loop (max 3 attempts):
        ├─ Parse errors, identify problematic skeleton(s) and find the solution to fix them
        ├─ Add the solution into the context and re-generate problematic skeleton(s)
        ├─ Re-run build_global_registry.py
        └─ Check exit code
            ├─ SUCCESS → Continue to Phase 2C
            └─ FAILURE → Next retry or escalate
        ↓
        If all retries exhausted:
        └─ Generate error report and request manual intervention
```

**Exit Codes**:
- `0`: Success - continue to Phase 2C
- `1`: Validation errors found - parse error messages to identify and fix
- `2`: File I/O error (missing directory, no skeleton files, YAML parse error) - fatal, cannot continue

**Error Recovery Strategy**:

1. **Check Exit Code**:
   - If `0`: Continue to Phase 2C
   - If `2`: Fatal error - check that Phase 2A completed, skeletons exist, directory is correct
   - If `1`: Parse error messages from stdout and proceed with recovery

2. **Parse Error Messages from stdout**: When exit code is `1`, extract all errors from output:

   Error messages follow this format:
   ```
   Errors found:
     - <error message 1>
     - <error message 2>
     - ...
   ```

   Parse each error message and categorize by type:
   - **Duplicate event**: Pattern `Duplicate event ID '(.+)': defined in both (.+) and (.+)`
   - **Missing event**: Pattern `System '(.+)' subscribes to event '(.+)' from '(.+)', but '(.+)' doesn't emit this event`
   - **Wrong producer**: Pattern `System '(.+)' expects event '(.+)' from '(.+)', but it's actually emitted by '(.+)'`
   - **Naming violation**: Pattern `Event '(.+)' in (.+) is not SCREAMING_SNAKE_CASE`
   - **Non-existent system**: Pattern `subscribes to event '(.+)' from '(.+)', but system '(.+)' doesn't exist`

3. **Group Errors by Affected System**: Organize errors by which skeleton file(s) need to be regenerated

   Example:
   ```
   CombatSystem_skeleton.yml needs fixes:
     - Duplicate event 'TOWER_DESTROYED' with TowerSystem
     - Subscribes to 'HERO_STUNNED' from 'StatusSystem', but 'StatusSystem' doesn't emit it
     - Event 'heroStunned' violates naming convention

   TowerSystem_skeleton.yml needs fixes:
     - Duplicate event 'TOWER_DESTROYED' with CombatSystem
   ```

4. **Find Solution** for each error in each system:

   **For Duplicate Event IDs**:
   ```
   Error: "Duplicate event ID 'TOWER_DESTROYED': defined in both CombatSystem and TowerSystem"

   Solution Strategy:
   - Determine canonical producer using domain matching:
     * Event domain (e.g., "TOWER_*") matches system domain → that system produces it
     * Or use system dependency order from systems_plan.yml (more fundamental system produces)
   - For producer system: Add constraint to keep the event
   - For consumer system: Add constraint to remove emission, add subscription instead
   ```

   **For Missing Events**:
   ```
   Error: "System 'CombatSystem' subscribes to event 'HERO_STUNNED' from 'StatusSystem',
           but 'StatusSystem' doesn't emit this event"

   Solution Strategy (choose most appropriate):
   a) If producer system SHOULD emit the event:
      - Add constraint to producer: "You must emit event 'HERO_STUNNED'"

   b) If wrong producer specified:
      - Search all skeletons for which system actually emits it
      - Add constraint to consumer: "Subscribe to 'HERO_STUNNED' from '{ActualProducer}', not '{WrongProducer}'"

   c) If event doesn't exist in game design:
      - Add constraint to consumer: "Remove subscription to non-existent event 'HERO_STUNNED'"
   ```

   **For Wrong Producer**:
   ```
   Error: "System 'CombatSystem' expects event 'TOWER_DESTROYED' from 'TowerSystem',
           but it's actually emitted by 'BuildingSystem'"

   Solution Strategy:
   - Add constraint to consumer: "Event 'TOWER_DESTROYED' is emitted by 'BuildingSystem', not 'TowerSystem'.
     Update your subscription's 'from' field to 'BuildingSystem'"
   ```

   **For Naming Violations**:
   ```
   Error: "Event 'heroStunned' in CombatSystem is not SCREAMING_SNAKE_CASE"

   Solution Strategy:
   - Add constraint: "All event IDs must be SCREAMING_SNAKE_CASE. Rename 'heroStunned' to 'HERO_STUNNED'"
   ```

   **For Non-existent System**:
   ```
   Error: "System 'CombatSystem' subscribes to event 'BUFF_APPLIED' from 'BuffSystem',
           but system 'BuffSystem' doesn't exist"

   Solution Strategy:
   - Check systems_plan.yml for correct system name
   - Add constraint: "System 'BuffSystem' doesn't exist. The correct system name is 'StatusEffectSystem'.
     Update your subscription's 'from' field accordingly"
   - Or if system truly doesn't exist: "System 'BuffSystem' doesn't exist in the game design.
     Remove this subscription or identify the correct producer system"
   ```

5. **Re-generate Problematic Skeletons** with solution context:

   For each problematic system, invoke skeleton generation subagent with:
   ```yaml
   mode: "skeleton"

   context:
     game_summary: |
       # Same as before
     all_system_ids: [...]

     # NEW: Error recovery context
     regeneration_reason: "registry_validation_failed"
     previous_errors: |
       - Duplicate event 'TOWER_DESTROYED' with TowerSystem

     constraints: |
       - Event 'TOWER_DESTROYED' is already emitted by TowerSystem
       - Do NOT emit 'TOWER_DESTROYED' in this system
       - If you need to react to tower destruction, subscribe to this event from TowerSystem

   system_plan:
     # Same system plan as before
   ```

6. **Re-run** `build_global_registry.py` with updated skeletons

7. **Check exit code and parse messages again**:
   - Exit code `0`: Success → Continue to Phase 2C
   - Exit code `1`: Still has validation errors → Parse new error messages
     * If errors are DIFFERENT from previous attempt: Continue retry with new solutions
     * If errors are IDENTICAL to previous attempt: Increment retry counter with stronger constraints
   - Exit code `2`: File I/O error → Fatal, investigate why skeleton files are corrupted

8. **Escalate** if max retries (3) exhausted:
   ```markdown
   ## Registry Build Failed After 3 Retries

   **Problematic Systems**: CombatSystem, TowerSystem

   **Unresolved Errors**:
   - Duplicate event ID 'TOWER_DESTROYED': defined in both CombatSystem and TowerSystem

   **Manual Review Required**:
   - Review skeleton files in _intermediate/
   - Decide: Should TowerSystem or CombatSystem emit TOWER_DESTROYED?
   - Manually edit the skeleton file to resolve conflict
   - Re-run: python build_global_registry.py <project>/_intermediate/

   **Recommendation**: Event name suggests TowerSystem should be the producer.
   ```

**Key Principles**:
- **Parse error messages, not exit codes**: All validation error details are in the stdout error messages; exit code only indicates success/failure/fatal
- **Handle multiple error types**: A single validation run can report duplicates, missing events, and naming violations simultaneously
- **Preserve successful skeletons**: Only regenerate files that have errors
- **Context enrichment**: Each retry adds more specific constraints based on parsed error messages
- **Deterministic validation**: Python tool ensures consistency across all systems
- **Bounded retries**: Avoid infinite loops, escalate to user after 3 attempts
- **Solution-based regeneration**: Don't just retry - parse errors, find solutions, provide explicit fix guidance
- **Track error changes**: If errors change between retries, you're making progress; if identical, use stronger constraints

---

### Phase 2C: Full Spec Generation (Subagents)

Generate complete specifications using the global registry for accurate cross-references.

#### Execution Model

```
Orchestrator
    ├── Subagent: Full spec for SystemA (with registry)
    ├── Subagent: Full spec for SystemB (with registry)
    ├── Subagent: Full spec for SystemC (with registry)
    └── ... (tiered parallelization)
```

#### Process

For each system in `systems_plan.systems`:

1. **Read global registry** from `global_registry.yml`
2. **Spawn subagent** with `single-system-spec-gen.md` in **full mode**
   - Pass: context summary + system plan entry + `mode: "full"` + **global_registry**
   - Subagent generates complete specification
   - Receive: full system specification YAML
3. **Write to file**: `specs/{SystemId}.yml`
4. **Store result** in collection

#### Parallelization Strategy

**Recommended approach**:
1. Group systems by role tier (infrastructure → core → support → meta)
2. Within each tier, run systems in parallel
3. Wait for tier completion before starting next tier

This balances parallelism with dependency ordering.

### Phase 3: Contract Generation

Generate `systems_contracts.yml` using the Python tool:

**IMPORTANT**: Use `generate_contracts.py` to generate `systems_contracts.yml` instead of LLM.

```bash
python generate_contracts.py <project_path>/specs/ <project_path>/systems_contracts.yml
```

This tool will:
1. **Read all spec files** from `specs/{SystemId}.yml`
2. **Build integration graph**:
   - For each system, summarize all inbound/outbound connections
   - Identify dependencies, events, queries, commands used
3. **Build event contract map**:
   - For each system's `events_emit`, find all subscribers
   - Validate payload compatibility
   - Flag orphan events (no subscribers)
4. **Build query/command contract map**:
   - For each public query/command, find all consumers
   - Validate signature compatibility
   - Flag unused queries/commands
5. **Validate topology**:
   - Detect dependency cycles
   - Identify "god systems" with too many connections (>10)
   - Flag isolated systems with no connections
6. **Write final output** to `systems_contracts.yml`

**Schema Definition**: See `systems_contracts_schema.yml` for complete contract structure.

---

## Context Summary Template

Prepare this summary to pass to each per-system invocation:

```markdown
## Game Context

**Game**: <game_name>
**Genre**: <genre>

### Core Loop
<2-3 sentences describing what players do>

### Resources
- <resource_1>: <brief description>
- <resource_2>: <brief description>

### Win/Lose
- Win: <condition>
- Lose: <condition>

### Mode
<Solo/Co-op/PvP>

### All Systems in Game
<list of system IDs for cross-reference awareness>
```

---

## Per-System Invocation

The per-system generator is invoked twice for each system: once in skeleton mode, once in full mode.

---

### Skeleton Mode Input (Phase 2A)

```yaml
mode: "skeleton"

context:
  game_summary: |
    ## Game Context
    **Game**: <game_name>
    **Genre**: <genre>

    ### Core Loop
    <2-3 sentences>

    ### Resources
    - <resource_1>: <description>

    ### Win/Lose
    - Win: <condition>
    - Lose: <condition>

    ### Mode
    <Solo/Co-op/PvP>

  all_system_ids: ["SystemA", "SystemB", "SystemC", ...]

system_plan:
  id: "CombatSystem"
  name: "Combat System"
  role: "core"
  domain: "combat"
  # ... complete system plan entry
```

**Skeleton Output**: IDs and signatures only (see Phase 2A structure)

---

### Full Mode Input (Phase 2C)

```yaml
mode: "full"

context:
  game_summary: |
    # Same as skeleton mode
  all_system_ids: ["SystemA", "SystemB", "SystemC", ...]

system_plan:
  id: "CombatSystem"
  name: "Combat System"
  role: "core"
  domain: "combat"
  # ... complete system plan entry

# NEW: Global registry from Phase 2B
global_registry:
  events:
    - id: "HERO_DAMAGED"
      producer: "CombatSystem"
    - id: "HERO_KILLED"
      producer: "CombatSystem"
    - id: "XP_GAINED"
      producer: "ProgressionSystem"

  queries:
    - id: "HeroSystem.get_max_hp"
      signature: "(hero_id: HeroInstanceId) -> int"

  commands:
    - id: "GoldSystem.spend"
      signature: "(player_id: PlayerId, amount: int) -> bool"
```

**Full Output**: Complete system specification with behaviors

See `system_spec_full_sample.yml` for example full specification output.

---

## Processing Order

Process systems in this order to maximize coherence:

1. **Infrastructure systems** (UISystem, InputSystem, TimeSystem)
2. **Core systems** by dependency depth
3. **Support systems**
4. **Meta systems**

Within each tier, sort by `depends_on` to process dependencies first.

---

## Validation Checklist

### After Phase 2A (Skeletons)

For each skeleton:
- [ ] Has `id` and `role`
- [ ] Entity names are present in `data.entities`
- [ ] Event IDs are SCREAMING_SNAKE_CASE
- [ ] Query/command IDs and signatures are present
- [ ] YAML is syntactically valid

### After Phase 2B (Registry)

- [ ] No duplicate event IDs across systems
- [ ] All `events.subscribes.event` exist in registry
- [ ] Query/command IDs follow `SystemId.name` format
- [ ] No naming convention violations

### After Phase 2C (Full Specs)

For each generated spec in `specs/`:
- [ ] Has `id` and `role`
- [ ] Entities have field types as strings
- [ ] Events have payload definitions
- [ ] Uses exact IDs from global_registry
- [ ] Behaviors have valid triggers and steps
- [ ] Step operations are "query", "command", or "emit"
- [ ] YAML is syntactically valid
- [ ] All `events.subscribes.from` resolve to existing systems
- [ ] All event subscriptions have matching producers
- [ ] All behavior step references are valid

### After Phase 3 (Contracts)

- [ ] Integration graph has entry for each system
- [ ] Every event has producer and payload defined
- [ ] Consumer payload requirements are subset of producer payload
- [ ] No dependency cycles detected
- [ ] No "god systems" flagged (or reviewed if present)
- [ ] Warnings section lists any orphans/unused items
- [ ] Contract file is valid YAML

---

## Error Handling

### Missing System Spec

If per-system generation fails:
1. Log the error with system ID
2. Create placeholder spec with `origin: "generation_failed"`
3. Continue with remaining systems
4. Report failures in final output

### Cross-Reference Errors

If validation finds broken references:
1. List all broken references
2. Attempt auto-fix if unambiguous (e.g., typo in system ID)
3. Mark unresolvable issues in warnings

### Contract Conflicts

If payload requirements conflict:
1. Document the conflict
2. Use union of all required fields
3. Flag for manual review

---

## Output Files

### specs/{SystemId}.yml

Individual system specifications, one file per system. Each file contains the complete specification for that system including data entities, interface, events, and behaviors.

### systems_contracts.yml

Cross-system integration contracts with validation results.

### (Optional) generation_report.md

Summary of generation process:
- Systems processed
- Archetype matches found
- Warnings and errors
- Manual review items

---
