# Battle Simulator — Claude Project Instructions

You are working on the **Battle Simulator MVP**.

## 1. Source of truth

The current game architecture is defined by the project's canonical documentation.

Before changing game behavior:

1. Read `PROJECT_INDEX.md`.
2. Identify the owning/SSoT document.
3. Load the relevant Skill from `.claude/skills/`.
4. Read only the documents required for the task.
5. Check direct dependencies before editing.

Do not treat code as the source of truth when the architecture explicitly defines the rule.

## 2. Skills

Use the relevant Battle Simulator Skill for the task:

- `bs-core` — global project rules and workflow
- `bs-audit` — consistency and pre/post-change validation
- `bs-combat` — combat
- `bs-cards` — cards and progression
- `bs-commanders` — commanders
- `bs-economy` — economy and formulas
- `bs-world` — city, PvE, PvP and world systems

Do not load every Skill or every document by default.

## 3. MVP scope

Implement only the **currently approved MVP architecture**.

Do not implement ideas, proposals, speculative mechanics, or future roadmap items unless the user explicitly promotes them to the current MVP.

## 4. Conflict policy

If two canonical-looking sources disagree:

- do not silently choose one;
- identify the conflict;
- determine whether it is a stale/legacy reference, documentation error, balance parameter, or design decision;
- if it requires a design decision, stop before implementing that rule.

Never invent missing mechanics, formulas, values, abilities, or historical definitions.

## 5. Change discipline

Before editing:

- inspect the existing implementation;
- identify affected systems;
- read the relevant SSoT;
- check dependencies.

After editing:

- validate behavior against the SSoT;
- run the relevant tests/checks;
- check for unintended changes;
- report documentation conflicts or unresolved assumptions.

Prefer the smallest implementation that satisfies the documented rule.

## 6. Critical project invariants

The following are confirmed MVP rules:

- Tier is mutable from Tier 1 through Tier 5.
- Card Energy depends on Tier.
- Card Soldo depends exclusively on Rarity.
- A War Machine/Balista starts at position 9, then follows normal movement rules.
- Affinity bonuses are frozen during the current turn; composition changes affect the next turn.
- `ABILITIES.md` is the authority for Unit Characteristics.
- Combat maximum is 64 turns.

Do not duplicate these rules into unrelated architecture documents or replace them with inferred behavior from code.

## 7. Response behavior

When implementing a requested change:

- focus on the requested task;
- avoid unnecessary commentary;
- state blockers only when they affect correctness;
- distinguish confirmed facts from assumptions;
- if a required rule is missing, ask for the decision instead of inventing one.

## 8. Documentation updates

If an implementation change changes a documented rule, update the owning SSoT and affected references.

Do not create duplicate definitions merely to make a local implementation convenient.

## 9. Final validation

For non-trivial changes, use `bs-audit` to verify:

- SSoT consistency;
- cross-system dependencies;
- numerical/formula consistency when applicable;
- stale references;
- MVP scope.

The goal is a codebase that implements the architecture, not a codebase that silently becomes the architecture.

## 10. Visual / UI work

When the task concerns graphics, UI, layout, typography, Battle Art, assets, visual composition, or presentation, load the `bs-visual` Skill before editing.

The visual task must be treated separately from gameplay logic and data unless the requested change explicitly requires both.

### 10.1 Asset vs. runtime responsibility

Keep a strict separation between visual assets and dynamic game/UI behavior.

Assets provide visual content such as:
- characters and units;
- buildings and structures;
- icons and symbols;
- textures and backgrounds;
- Battle Art views.

Godot/runtime systems provide dynamic behavior such as:
- position and movement;
- scale and perspective;
- rotation and orientation selection;
- visibility and state;
- dynamic text and numeric values;
- animation and effects;
- responsive layout.

Do not bake dynamic information into PNGs or other static images when the information can change during gameplay.

### 10.2 Dynamic typography

Dynamic game information must remain real UI text/resources in Godot, not pre-rendered images.

Use project-provided font resources for thematic typography. Prefer a readable fantasy/medieval visual identity over excessive decorative effects.

Where appropriate, separate typography roles such as title, body text, and numeric/status information so that readability is preserved at gameplay scale.

### 10.3 Visual scope discipline

For visual tasks:
- identify whether the problem is an asset, layout, typography, transparency, scale, perspective, or runtime behavior before editing;
- do not solve a visual problem by changing unrelated gameplay systems;
- do not redesign approved visual elements unless explicitly requested;
- make the smallest change that addresses the stated visual problem;
- preserve existing responsive behavior and hitbox relationships unless the task explicitly concerns them;
- do not modify combat rules, card data, economy, or other unrelated systems.

### 10.4 HUD and overlays

When UI is placed over artwork or a map, do not introduce opaque or dark backing panels unless explicitly requested or required for legibility.

Prefer transparent composition, thematic typography, subtle text shadow/outline, and restrained decorative elements when they preserve the artwork underneath.

Dynamic values such as XP, levels, currency, resources, counters, names, health, shield, and damage must remain dynamic UI elements.

### 10.5 Battle Art

Battlefield unit assets must be designed for the actual battlefield camera and tile geometry, not as isolated card portraits.

When a unit requires directional representation, provide the required distinct views (for example front, back, left, and right) as separate assets. Runtime code is responsible for selecting the appropriate view based on battlefield direction/orientation.

Preserve alpha transparency around the subject. Do not use background-removal methods that erase light-colored parts of the character or otherwise damage the silhouette.

The asset must remain readable at the intended battlefield scale and must fit inside one occupied battlefield tile unless the documented unit size explicitly requires otherwise.

### 10.6 Visual validation

Claude is not required to create screenshots for visual tasks unless the user explicitly requests screenshots or automated visual evidence.

After implementation, perform only the relevant technical checks available in the project and report what was verified. Do not spend tokens generating screenshot artifacts merely to demonstrate visual changes.

The user will inspect the result directly in Godot and provide visual feedback for subsequent iterations.

Do not treat technical success as proof of visual success. The visual acceptance decision belongs to the user's direct inspection unless an automated visual criterion has been explicitly defined.
