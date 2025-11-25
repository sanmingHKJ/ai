# Single System Spec Generator

**PER-SYSTEM EXECUTION INSTRUCTIONS**

## Purpose

Generate a behavior-focused specification for a **single system** based on:
- Game context summary
- System plan entry from `systems_plan.yml`
- Global ID registry (in full mode)

This focused scope prevents context overflow and ensures high-quality specifications.

---

## Execution Mode

The generator operates in one of two modes:

### Mode: Skeleton

When input contains `mode: "skeleton"`

**Output only**:
- `id`, `role`
- `data.entities` - names only (no fields)
- `interface.player_actions` - id and input only
- `interface.queries` - id, returns, args only
- `interface.commands` - id and args only
- `events.emits` - IDs only (no payloads)
- `events.subscribes` - from/event only

**Do NOT output**: field definitions, payloads, summaries, behaviors

### Mode: Full (default)

When input contains `mode: "full"` and `global_registry`

**Output complete specification** with all sections including behaviors.
**MUST use exact IDs** from `global_registry` for cross-system references.

---

## Critical Constraints

### DO NOT

- **Invent new systems** not in `all_system_ids`
- **Change the `id`** from `system_plan.id`
- **Reference systems** not in `all_system_ids`
- **Generate empty arrays** `[]` or empty objects `{}`
- **Use placeholder text** like "TBD", "TODO", or "..."
- **Add UI facets** to infrastructure systems
- **Emit events** not needed by any subscriber (check intent)
- **Guess event/query/command IDs** - use exact IDs from `global_registry` in full mode

### MUST

- **Use exact IDs** from `global_registry` when subscribing to events or using queries/commands
- **Follow naming conventions** exactly (SCREAMING_SNAKE for events, snake_case for queries)
- **Include only sections** required for this system's role
- **Omit sections** that don't apply rather than outputting empty content

---

## Input

The per-system generator receives two parts:

### Part 1: Game Context Summary

Condensed game information for cross-reference awareness.

```yaml
context:
  game_summary: |
    ## Game Context
    **Game**: Farming Adventure
    **Genre**: Casual simulation

    ### Core Loop
    Players plant crops, wait for growth, harvest, and sell for profit.
    Use profits to unlock new plots and crop types.

    ### Resources
    - soft_currency: Gold for buying seeds and unlocking plots
    - seeds: Consumable items for planting

    ### Win/Lose
    - Win: Achieve farm value milestones
    - Lose: N/A (progression game)

    ### Mode
    Solo with optional visiting

  all_system_ids:
    - "FarmSystem"
    - "CropSystem"
    - "InventorySystem"
    - "TimeSystem"
    - "ShopSystem"
    - "UISystem"
```

### Part 2: Complete System Section from systems_plan.yml

The **entire system entry** is transferred, preserving all fields.

```yaml
system_plan:
  id: "FarmSystem"
  name: "Farm System"
  role: "core"
  domain: "world_ownership"
  loop_stage: "action_space"
  novelty: "adapt"
  depends_on:
    - "TimeSystem"
    - "InventorySystem"
  description: "Manages player-owned farms and plots in shared world."

  intent:
    responsibility: "Track farm ownership, plot states, and coordinate planting/harvesting."
    player_interactions:
      - "Unlock new plots with currency"
      - "Plant seeds on empty plots"
      - "Harvest ready crops"
      - "Place decorations"
    affects:
      - system: "InventorySystem"
        aspect: "item_counts"
      - system: "CurrencySystem"
        aspect: "balance"
    required_properties:
      - "Persistent state across sessions"
      - "Time-based growth mechanics"
    design_goals:
      - "Satisfying feedback on harvest"
      - "Clear visual plot states"
    constraints:
      - "Max 16 plots per farm"

  data_interfaces:
    exports:
      - "plot_state_events"
      - "farm_layout_queries"
    imports:
      - "time_tick_events"
      - "inventory_has_item_queries"

  archetype_hints:
    - "farming_system"
    - "plot_management"
  tags:
    - "persistent"
    - "time_based"
  notes: "Adapt from standard farming archetype, add decoration support"
```

### Part 3: Global Registry (Full Mode Only)

In full mode, the orchestrator provides the global registry built from all skeletons:

```yaml
global_registry:
  events:
    - id: "PLOT_PLANTED"
      producer: "FarmSystem"
    - id: "CROP_HARVESTED"
      producer: "FarmSystem"
    - id: "TIME_TICK"
      producer: "TimeSystem"
    - id: "ITEM_ADDED"
      producer: "InventorySystem"

  queries:
    - id: "FarmSystem.get_plot_state"
      signature: "(plot_id: PlotId) -> PlotState"
    - id: "InventorySystem.has_item"
      signature: "(player_id: PlayerId, item_id: ItemId) -> bool"
    - id: "TimeSystem.get_current_time"
      signature: "() -> timestamp"

  commands:
    - id: "InventorySystem.add_item"
      signature: "(player_id: PlayerId, item_id: ItemId, count: int) -> bool"
    - id: "InventorySystem.remove_item"
      signature: "(player_id: PlayerId, item_id: ItemId, count: int) -> bool"
```

**Use these exact IDs** when:
- Subscribing to events from other systems
- Calling queries from other systems in preconditions/data_binding
- Calling commands from other systems in effects

---

## Output

### Skeleton Mode Output

**Schema**: See `system_skeleton_schema.yml` for skeleton template structure.

**Sample Output**: See `system_spec_skeleton_sample.yml` for example skeleton output.

### Full Mode Output

Complete system specification with all applicable sections (see Output Format section below).

---

## Input-to-Spec Mapping

Use this mapping to derive spec sections from the system plan:

| Plan Field | Derives → Spec Section |
|------------|------------------------|
| `id` | → `id` |
| `domain` | → `role` |
| `intent.responsibility` | → entity design |
| `intent.player_interactions` | → `interface.player_actions` |
| `intent.affects` | → `data.entities` (what state to track) |
| `data_interfaces.exports` | → `events.emits`, `interface.queries` |
| `data_interfaces.imports` | → `events.subscribes` |
| Event subscriptions + affects | → `behaviors` (reactive logic) |

### Role Mapping

Map `domain` to `role`:

| Domain | Role |
|--------|------|
| character, hero, player | character |
| combat, damage, health | combat |
| currency, shop, inventory | economy |
| progression, xp, level | progression |
| time, session, match | infrastructure |
| ui, input | presentation |

---

## Generation Sections

### 1. Data Entities

Define data structures owned by this system:

```yaml
data:
  entities:
    - name: string           # PascalCase
      fields:
        field_name: type_string
```

**Field Type Conventions:**
- Primitives: `int`, `float`, `string`, `bool`
- Vectors: `vec2`, `vec3`
- References: `PlayerId`, `HeroId`, `ItemId`, etc.
- Collections: `list<T>`, `dict<K,V>`

**Derivation from Plan:**
- Analyze `intent.affects` for state that needs tracking
- Analyze `intent.player_interactions` for action targets

---

### 2. Interface

#### Player Actions

Derive from `intent.player_interactions`:

```yaml
interface:
  player_actions:
    - id: string             # ACTION_VERB_NOUN
      input: { param: "type" }
      effect_summary: string # 1-2 sentences
```

#### Queries

Read-only accessors for entity state:

```yaml
  queries:
    - id: string             # GET_, HAS_, IS_, CAN_, LIST_
      returns: string
      args: { param: "type" }
      summary: string
```

#### Commands

Mutating operations callable by other systems:

```yaml
  commands:
    - id: string             # SCREAMING_SNAKE_CASE verb
      args: { param: "type" }
      summary: string
```

---

### 3. Events

#### Emits

Events this system produces:

```yaml
events:
  emits:
    - id: string             # SCREAMING_SNAKE_CASE
      payload: { field: "type" }
```

#### Subscribes

Events this system listens to:

```yaml
  subscribes:
    - event: string
      from: string           # Producer system ID
      summary: string
```

---

### 4. Behaviors

**Behaviors define reactive logic** triggered by four distinct runtime channels.

```yaml
behaviors:
  - id: string               # snake_case, e.g. "on_event_name" or "init_system"
    trigger:
      type: "action" | "event" | "timer" | "init"
      name: string           # ACTION_* for action, EVENT_* for event, timer name for timer
      every: number          # optional, only for timer type (seconds)
    summary: string          # What this behavior accomplishes
    steps:
      - op: "query" | "command" | "emit" | "if_true" | "if_false"
        system: string
        name: string
        args: { key: "value_or_var" }
        assign_to: string    # optional, for query results
        cond: string         # optional, for if_true/if_false
        then: [steps]        # optional, for if_true/if_false
```

---

#### Trigger Type 1: on_action - Player Input

**Purpose**: Handle player-initiated actions from `interface.player_actions`

**Structure**:
```yaml
trigger:
  type: "action"
  name: "ACTION_HERO_MOVE"  # Must match a player_action.id
```

**Derivation**:
- For each entry in `interface.player_actions`, consider if it needs a behavior
- Not all player actions need behaviors (some are pure commands)
- Create behavior when action requires multi-step orchestration

**Example**:
```yaml
behaviors:
  - id: "on_hero_move"
    trigger:
      type: "action"
      name: "ACTION_HERO_MOVE"
    summary: "Handle player move command by updating hero position."
    steps:
      - op: "command"
        system: NavSystem
        name: SET_PATH
        args: { hero_id: "hero_id", target_pos: "target_position" }
```

**When to create**:
- Action requires validation before execution
- Action affects multiple systems
- Action needs to query state before proceeding
- Action has complex multi-step logic

---

#### Trigger Type 2: on_event - System-to-System Communication

**Purpose**: React to events from `events.subscribes`

**Structure**:
```yaml
trigger:
  type: "event"
  name: "HERO_DAMAGED"  # Must match an event from events.subscribes
```

**Derivation**:
- **MANDATORY**: Each entry in `events.subscribes` MUST have a corresponding behavior
- The behavior defines what happens when the subscribed event is received
- Use exact event ID from `global_registry` in full mode

**Example**:
```yaml
behaviors:
  - id: "on_xp_gained"
    trigger:
      type: "event"
      name: "XP_GAINED"
    summary: "Apply XP and check for level-up."
    steps:
      - op: "query"
        system: XPSystem
        name: GET_XP_FOR_NEXT_LEVEL
        args: { hero_instance_id: "hero_id" }
        assign_to: "xp_required"

      - op: "if_true"
        cond: "current_xp >= xp_required"
        then:
          - op: "command"
            system: HeroSystem
            name: LEVEL_UP
            args: { hero_instance_id: "hero_id" }
```

**When to create**:
- ALWAYS create for each `events.subscribes` entry
- This is the system's response to external state changes

---

#### Trigger Type 3: on_timer - Time-Based Periodic Logic

**Purpose**: Execute logic periodically based on time intervals

**Structure**:
```yaml
trigger:
  type: "timer"
  name: "match_tick"    # Timer identifier
  every: 0.1            # Interval in seconds
```

**Derivation**:
- Analyze `intent.responsibility` for time-based mechanics
- Look for keywords: "periodic", "over time", "regeneration", "decay", "respawn timer", "DOT", "buff duration"
- Consider if system needs to poll or check state regularly

**Common Timer Names**:
- `match_tick` - Main game loop (0.05-0.2s)
- `slow_tick` - Slower updates (1.0-5.0s)
- `respawn_tick` - Respawn checking (1.0s)
- Custom names for specific purposes

**Example**:
```yaml
behaviors:
  - id: "process_dot_effects"
    trigger:
      type: "timer"
      name: "match_tick"
      every: 1.0
    summary: "Apply periodic damage from poison, burn, and other DOT effects."
    steps:
      - op: "query"
        system: BuffSystem
        name: GET_ACTIVE_DOTS
        args: {}
        assign_to: "dot_list"

      - op: "command"
        system: CombatSystem
        name: APPLY_DAMAGE
        args: { target_id: "dot.target_id", amount: "dot.damage_per_tick" }
```

**When to create**:
- System has DOT (damage/heal over time) mechanics
- System has regeneration (HP, mana, energy)
- System needs respawn checking
- System has buff/debuff expiration
- System has decay mechanics
- System needs periodic state synchronization

**Typical Intervals**:
- 0.05-0.1s: Fast updates (network sync, interpolation)
- 0.2-0.5s: Medium updates (AI behavior, DOT effects)
- 1.0-2.0s: Slow updates (respawn checks, resource regen)
- 5.0+s: Very slow updates (match state, leaderboards)

---

#### Trigger Type 4: on_init - Initialization Logic

**Purpose**: One-time setup when system loads or match begins

**Structure**:
```yaml
trigger:
  type: "init"
  # No 'name' field needed
```

**Derivation**:
- Check if system needs initialization in `intent.responsibility`
- Look for: "manages", "tracks", "maintains", "stores"
- Consider if system needs to load data or set defaults

**Example**:
```yaml
behaviors:
  - id: "init_hero_system"
    trigger:
      type: "init"
    summary: "Initialize hero system with default stats and configurations."
    steps:
      - op: "command"
        system: HeroSystem
        name: INIT_DEFAULT_STATS
        args: {}
```

**When to create**:
- System manages collections (heroes, items, NPCs)
- System needs to load configuration
- System needs to register spawn points
- System needs to initialize lookup tables
- System needs to set default values
- System has persistent state that needs setup

**Common Patterns**:
- Load static data (hero stats, item definitions, formulas)
- Initialize empty collections (entity lists, caches)
- Register world objects (spawn points, towers, zones)
- Set up internal state machines
- Perform dependency checks

---

#### Step Operations

**Available Operations**:
- `query`: Read data, assign result to variable
- `command`: Execute mutation on a system
- `emit`: Fire an event with payload
- `if_true`: Conditional execution (requires `cond` and `then`)
- `if_false`: Inverse conditional execution

**Args Reference**:
- Literal values: `{ count: 10 }`
- Variables from prior steps: `{ position: "revive_pos" }`
- Trigger payload fields: `{ hero_id: "hero_id" }`
- Expressions: `{ amount: "base_damage * multiplier" }`

**Derivation from Plan**:
- Each `events.subscribes` entry **MUST** have a corresponding `on_event` behavior
- Each `interface.player_actions` **MAY** have a corresponding `on_action` behavior
- Systems with time-based mechanics **SHOULD** have `on_timer` behaviors
- Systems that manage state **SHOULD** have an `on_init` behavior

---

## Validation Checklist

Before outputting:

- [ ] `id` and `role` are present
- [ ] Entity names are PascalCase
- [ ] Entity fields have type strings
- [ ] Player action IDs start with `ACTION_`
- [ ] Query IDs start with `GET_`, `HAS_`, `IS_`, `CAN_`, or `LIST_`
- [ ] Event IDs are SCREAMING_SNAKE_CASE
- [ ] All summaries are 1-2 sentences max
- [ ] Behaviors have valid triggers with proper structure:
  - [ ] `trigger.type` is one of: "action", "event", "timer", "init"
  - [ ] `trigger.name` matches ACTION_* for action, EVENT_* for event, timer name for timer
  - [ ] `trigger.every` is present only for timer type
  - [ ] Each `events.subscribes` has a corresponding `on_event` behavior
- [ ] Step operations are `query`, `command`, `emit`, `if_true`, or `if_false`
- [ ] Cross-system references use valid system IDs
- [ ] No empty arrays or objects

---

## Output Format

Return a single YAML block containing the system specification.

**Schema**: See `system_spec_schema.yml` for complete single system specification schema.

**Sample Output**: See `system_spec_full_sample.yml` for example full specification with all trigger types.

---
