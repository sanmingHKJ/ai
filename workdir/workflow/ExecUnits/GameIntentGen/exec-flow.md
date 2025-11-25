# GameIntentGen: Game Design Intent Generation

**EXECUTION UNIT INSTRUCTIONS (MiniWorld Studio)**

## Unit Role
Analyze a high-level game idea and produce a **concise, structured game_intent.md** that:
- Captures the **core fantasy, gameplay, and structure** of the whole game (or main mode)
- Provides clear signals for **downstream generators**:
  - Level topology & layout
  - Game systems & DSL
  - Content generators (enemies, items, challenges)
- Avoids engine / platform details (MiniWorld Studio is fixed)

## Inputs
- **Type**: UserPrompt  
- **Content**: High-level game concept (genre, vibe, rough reference games, target players, etc.)

## Outputs
- **Type**: GameIntentData  
- **File**: `game_intent.md` (single markdown file)

---

## 1. Analyze User Game Concept

Extract the following **minimal but essential** information:

- **Genre & Mode**
  - Primary genre (e.g., MOBA, Parkour, Tower Defense, Roguelike)
  - Main mode type: `Single-Level`, `Multi-Level`, `Arena`, `Endless`, etc.

- **Player Fantasy & Theme**
  - 1–2 sentence “you are / you feel like” player fantasy
  - Setting & theme in a short paragraph
  - 2–3 reference games or media (optional but helpful)

- **Target Players & Sessions**
  - Target audience: age, skill, casual vs competitive
  - Match / run length target (e.g., 10–15 min, 30–40 min)
  - Single-player / Co-op / PvP and player count

- **Core Gameplay Loop**
  - 4–8 step loop describing **what players repeatedly do**
  - Focus on actions and decisions, not tech

---

## 2. Identify Design Gaps & Ask Focused Questions

Generate targeted questions to clarify the game design intent:

- **Gameplay & Controls**
  - Camera style (e.g., 3rd-person, top-down, side-view)
  - Movement style (WASD + mouse aim, twin-stick, click-to-move)
  - Key player abilities (movement, attack, interact, special mechanics)

- **Game Structure**
  - Is this one main mode or multiple?
  - For multi-level: rough level count and progression arc
  - For arena / endless: early–mid–late phase differences

- **Systems & Resources**
  - What persistent resources exist? (gold, energy, lives, meta-currency)
  - Win / lose conditions for a typical run or match
  - Whether meta-progression (unlock heroes, upgrades, cosmetics) exists

- **Difficulty & Content Budgets**
  - Target difficulty: Easy / Normal / Hard / Hardcore
  - Desired challenge style: mechanical skill, puzzle thinking, planning, etc.
  - Rough budgets (examples, adapt as needed):
    - `enemy_points` (0–100): overall combat density
    - `puzzle_complexity` (0–3): none / light / medium / heavy
    - `treasure_value` (0–100): generosity of rewards

Ask only what’s needed to fill the template; do **not** drift into full GDD detail here.

**Example Questions:**
```
Q1: Is this a single level/scene or multiple levels/stages?
Q2: How do players progress - through story, skill mastery, or collection?
Q3: What are the core player abilities - jump, attack, interact, build?
Q4: Will there be enemy AI, NPCs, or just environmental challenges?
Q5: Should the game have a tutorial/onboarding phase?
Q6: What happens when players fail - restart level, respawn, lose resources?
Q7: Is there a scoring/rating system or just completion-based?
```

Ask questions **interactively** to gather comprehensive requirements.

---

## 3. Generate Game Intent Document (game_intent.md)

Create a **clear, compact** markdown document with these sections.

### 3.1 Game Overview

```markdown
# Game Design Intent: [GAME_NAME]

## Metadata
- **Game Name**: [Name]
- **Genre**: [Primary genre] / [Secondary genre]
- **Mode Type**: [Single-Level / Multi-Level / Arena / Endless / Roguelike, etc.]
- **Target Players**: [Age, skill level, casual/competitive]
- **Player Count**: [Solo / Co-op X / PvP XvX]
- **Session Length**: [e.g., 10–15 min per run]

## High-Level Concept
[2–4 sentence elevator pitch summarizing the fantasy and what players do.]

## Core Gameplay Loop
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]
[Optionally more steps if needed, but stay compact.]
```

### 3.2 Fantasy, Theme & References

```markdown
## Fantasy & Theme
- **Player Fantasy**: “You are a … who …”
- **Setting**: [Short paragraph on world/location.]
- **Tone & Mood**: [e.g., lighthearted, tense, cozy, dark.]

## Reference Works
- [Game/Work 1] – [What to take inspiration from]
- [Game/Work 2] – [What to take inspiration from]
```

### 3.3 Structure & Progression

Focus on **shape of play over time**, not level implementation details.

```markdown
## Structure & Progression

### Overall Structure
- **Main Mode**: [Description, e.g., “Single arena with repeatable matches” / “Campaign of ~X levels”.]
- **Expected Play Flow**: [1–2 sentences on how a typical session unfolds.]

### Phases or Level Groups
[Pick one of the patterns below.]

**For Multi-Level Campaign:**
- **Early Game**: [Levels X–Y, introduce mechanics …]
- **Mid Game**: [Levels …, combine mechanics …]
- **Late Game**: [Levels …, mastery / final challenges.]

**For Arena / Endless:**
- **Early Phase**: [Low intensity, tutorial or onboarding beats.]
- **Mid Phase**: [Main challenge phase, more enemies/systems.]
- **Late Phase**: [High intensity, difficulty spikes, win/lose conditions.]

### Win / Lose Conditions
- **Win**: [What must the player/team achieve.]
- **Lose**: [Failure conditions – death, timer, objective loss, etc.]
```

### 3.4 Systems, Resources & Budgets

This section is for **downstream system spec and DSL**. Do not fully design systems here; just identify them and outline their role.

````markdown
## Systems & Resources

### Core Resources
- **Primary Resources**: [e.g., Health, Ammo, Gold, Energy]
- **Meta Resources (if any)**: [e.g., permanent upgrades, unlock currency.]
- **Resource Loops**:
  - [Loop 1]: [Earn → Spend → Benefit cycle]
  - [Loop 2]: […]

### Game Systems
Tick systems that are clearly needed, and briefly describe their purpose:

- [ ] **Combat / Damage System**
- [ ] **Enemy / AI System**
- [ ] **Progression System** (XP, levels, skill tree)
- [ ] **Inventory / Item System**
- [ ] **Quest / Objective System**
- [ ] **Economy / Shop System**
- [ ] **Match / Run Management** (start/end, scoring, rewards)
- [ ] **Meta-Progression System** (if applicable)
- [ ] **Other Custom Systems**:
  - **[System Name]**: [1–2 sentence purpose.]

*(Do not detail abilities, formulas, or data tables here.)*

### Difficulty & Content Budgets
- **Target Difficulty**: [Easy / Normal / Hard / Hardcore]
- **Challenge Emphasis**: [Mechanical skill / Strategy / Puzzle solving / Exploration.]

```yaml
budgets:
  enemy_points: [0–100]          # Overall combat density
  puzzle_complexity: [0–3]       # 0 none, 1 light, 2 medium, 3 heavy
  treasure_value: [0–100]        # How generous rewards feel
  session_target_minutes: [int]  # Target duration per run/match
```

````

### 3.5 Player, Camera & Controls (MiniWorld-Oriented)

These fields help downstream **player template & camera setup** without going into hard numbers unless necessary.

````markdown
## Player, Camera & Controls

### Camera & View
- **Camera Style**: [Third-person / Top-down / Side-view / Isometric]
- **Camera Behavior**: [Locked follow / free orbit / tactical overview, etc.]

### Movement & Interaction
- **Movement Scheme**: [e.g., “WASD move + mouse aim” / “Click-to-move”.]
- **Key Actions**:
  - Movement actions: [jump, dash, sprint, climb, etc.]
  - Interaction actions: [use, pick-up, talk, activate, etc.]
  - Combat actions (if any): [basic attack, special, ultimate – high-level only.]

### Player Template Notes
If needed, include **relative** tuning hints, not full physics math:

```yaml
player_template_hints:
  mobility: "low / medium / high"
  survivability: "fragile / normal / tanky"
  complexity: "simple / intermediate / advanced"
```

````

---

## 4. Validation Checklist (Before Output)

Before finalizing `game_intent.md`, verify:

- [ ] Game fantasy, mode, and core loop are clearly described in **under one page** of content.
- [ ] Structure & progression fields let downstream units infer:
  - How many levels/phases.
  - How difficulty should ramp.
- [ ] Systems & resources are identified with **short roles**, not full designs.
- [ ] Budgets are filled with reasonable values.
- [ ] Camera, controls, and main actions are specified at a **high level**.
- [ ] No unnecessary platform, performance, or development-plan details are included.

---