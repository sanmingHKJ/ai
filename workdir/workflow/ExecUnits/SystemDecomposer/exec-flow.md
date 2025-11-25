# SystemDecomposer: Game Systems Plan Generation

**EXECUTION UNIT INSTRUCTIONS (MiniWorld Studio)**

## Unit Role
Analyze a **game_intent.md** and produce a concise **systems_plan.yml** that:

- Decomposes the game into **modular systems** with clear responsibilities
- Defines **roles, dependencies, and priorities** between systems
- Stays at the **"plan" level** (what systems exist and how they relate), not full system specs

This plan is consumed by:
- **SystemSpecGen** (to pick archetypes or synthesize new systems)
- **DSL/schema generators**
- Later implementation agents

---

## Inputs

- **Type**: GameIntentData
- **File**: `game_intent.md`

Assume game_intent.md includes, at least:
- Game overview (fantasy, genre, core loop)
- Structure/progression (levels/phases/modes)
- Systems & resources summary (if present)
- Difficulty / content **budgets** (if present, e.g. enemy_points, puzzle_complexity, etc.)

---

## Outputs

- **Type**: SystemsPlanData
- **File**: `systems_plan.yml`

The output must be:
- Structurally valid according to `systems_plan_schema.yml`
- Compact, with **8–20 systems** for a typical game

---

## 1. Read & Extract from Game Intent

From `game_intent.md`, extract only what you need:

### 1.1 Core Loop & Phases
- List the **core gameplay loop steps** (what players do repeatedly)
- Identify **phases or level groups** (early/mid/late, or level tiers)
- Mark which loop steps are primarily:
  - **player_action** (input-driven)
  - **game_response** (simulation/AI/progression)

### 1.2 Systems & Resources
- Collect **explicit systems** mentioned (if any)
- Identify **implicit systems** required to support the loop and structure:
  - Combat, economy, inventory, progression, match/session management, etc.
  - **Note**: Do NOT include generic infrastructure like UI or Input systems - these are handled by MiniWorld Studio APIs and SGF core functions
- List **resources** that must be tracked:
  - Health, ammo, gold, energy, XP, meta-currency, etc.

### 1.3 Budgets & Constraints (If Available)
- Map **difficulty / content budgets** to likely system families, e.g.:
  - `enemy_points` → Combat/Enemy/Spawn systems
  - `puzzle_complexity` → Puzzle/Interaction systems
  - `treasure_value` → Economy/Loot/Reward systems
- Note structural constraints:
  - Single-level vs multi-level vs endless
  - Solo vs co-op vs PvP

---

## 2. Identify Systems

### 2.1 Start from the Loop

For each **core loop step**, ask:

> "Which single system (or small set of systems) is mainly responsible for making this step possible?"

- Propose systems that **directly support** loop steps
- Avoid over-fragmentation. Prefer **one system per responsibility**, not per feature.

### 2.2 Add Session Management

Include session/flow systems as needed:

- **MatchFlowSystem** or **RunFlowSystem** – match/run start, end, and transitions

**Important**: Do NOT add generic infrastructure systems like UISystem or InputSystem. These are already integrated in MiniWorld Studio APIs and SGF core functions. Focus only on **game-specific logic systems**.

### 2.3 Avoid Overreach

SystemDecomposer should **not**:

- Define detailed ability lists, formulas, or data schemas
- Design full UI flows or meta-progression trees
- Implement balancing rules

Those belong to later **SystemSpecGen** and tuning stages.

---

## 3. Classify Systems

### 3.1 Role

Assign each system a **role** that describes its high-level category:

Suggested values:
- `character` – player/hero management, stats, leveling
- `combat` – attacks, damage, death resolution
- `economy` – currency, trading, rewards
- `progression` – XP, unlocks, skill trees
- `movement` – locomotion, physics, navigation
- `inventory` – items, equipment, storage
- `matchflow` – match/session lifecycle, transitions
- `meta` – persistence, cosmetics, achievements

Free-form values are allowed if none of these fit.

### 3.2 Priority

Assign each system a **priority** indicating its importance:

- `core` – essential for the main gameplay experience
- `important` – significantly enhances gameplay
- `optional` – nice-to-have, can be deferred

---

## 4. Dependencies

### 4.1 System Dependencies

For each system, list `dependencies` (system ids it needs to call or consume from):

- Prefer **acyclic** dependency graphs
- Typical pattern:
  - Core systems → Important systems → Optional systems

Rules:
- Core systems can depend on other core systems
- Important systems can depend on core systems
- Optional systems can depend on core/important systems
- Avoid dependency chains longer than 3

---

## 5. Systems Plan YAML Structure

Produce a single YAML document under `systems_plan`.

**IMPORTANT**: Refer to `systems_plan_schema.yml` for the exact field definitions.

```yaml
systems_plan:
  systems:
    - id: CombatSystem                # PascalCase, ends with "System"
      role: "combat"                  # High-level category
      responsibilities:
        - "Resolves all damage calculations between entities"
        - "Handles attack execution and hit detection"
        - "Manages death and respawn triggers"
      dependencies:
        - HeroSystem
        - MovementSystem
      priority: "core"                # core | important | optional
      notes: "Uses physics raycast for hit detection"

    - id: HeroSystem
      role: "character"
      responsibilities:
        - "Manages hero stats (health, mana, attack power)"
        - "Handles hero leveling and stat growth"
        - "Tracks hero state (alive, dead, stunned)"
      dependencies: []
      priority: "core"
      notes: ""

    - id: EconomySystem
      role: "economy"
      responsibilities:
        - "Tracks gold income from kills and objectives"
        - "Manages gold spending on items"
        - "Provides reward events for UI feedback"
      dependencies:
        - CombatSystem
      priority: "important"
      notes: "May integrate with meta-progression later"
```

Notes:

* `responsibilities` are one-line descriptions of what the system owns
* `dependencies` lists system ids this system needs to call or consume from
* `notes` is optional free-form text for constraints, special rules, or hints

---

## 6. Decomposition Guidelines

### 6.1 Granularity

* Split a system if it has **multiple independent responsibilities**
* Merge systems if they **always operate together** and would create noisy dependencies
* Aim for:

  * At least **1–2 core** priority systems
  * A small set of **important** systems
  * Only **necessary** optional systems
  * Focus on **game-specific logic** only

### 6.2 Coverage

Ensure that:

* Every **core loop step** is supported by at least one system
* Each **resource** (health, currency, XP, etc.) has an owning system
* Win/lose conditions map to responsible systems (e.g. `MatchFlowSystem`, `ObjectiveSystem`)

### 6.3 Multiplayer & Modes

If the game is multiplayer or multi-mode:

* Add **mode/match** systems instead of duplicating entire system graphs:
  * `MatchFlowSystem`, `TeamSystem`, `LobbySystem`

---

## 7. Validation Checklist

Before finalizing `systems_plan.yml`, verify:

### Structural

* [ ] Each system has unique `id` (PascalCase, ends with "System")
* [ ] Each system has `role` (category) and `priority`
* [ ] Each system has at least one `responsibility`
* [ ] Dependencies form a DAG (no cycles)
* [ ] Total system count is reasonable (8–20)

### Coverage

* [ ] All **explicit** systems from `game_intent.md` are represented
* [ ] All **implicit** systems needed for the core loop are included
* [ ] Every core loop step has at least one linked system
* [ ] Key resources have a clear owning system

### Semantic Correctness

* [ ] Responsibilities clearly describe what each system owns
* [ ] No generic infrastructure systems included (UI, Input are handled by MiniWorld Studio)
* [ ] Priorities reflect actual importance to gameplay

### Downstream Readiness

* [ ] Responsibilities are specific enough for SystemSpecGen to expand
* [ ] Dependencies show clear information flow between systems
* [ ] YAML is valid and matches `systems_plan_schema.yml`

---
