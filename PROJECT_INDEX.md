# PROJECT INDEX — BATTLE SIMULATOR MVP

> Canonical routing map for the Battle Simulator project.
> This file tells Claude **where to look**, not the full content of the game rules.

## Project root

```text
Battle_Simulator/
├── CLAUDE.md
├── PROJECT_INDEX.md
├── .claude/
│   └── skills/
├── Arquitetura/
├── Foundation/
├── Assets/
├── Imagens/
├── Ideias/
└── .asset-db-build/
```

## Directory authority

### `Arquitetura/`
**Source of truth for current game rules and architecture.**

Use this directory for:
- gameplay rules;
- systems and mechanics;
- formulas;
- progression;
- cards and abilities;
- combat;
- commanders;
- economy;
- City/world systems;
- PvE/PvP;
- ranking and seasons.

A code change that changes a game rule must be checked against the relevant document here.

### `Foundation/`
**Implementation and production specification layer.**

Use this directory for:
- implementation specifications;
- UI/UX specifications;
- visual/graphic rules;
- art bibles;
- asset-production rules;
- interaction layouts;
- technical production guidance.

Foundation documents explain **how to build/present** a system. They do not silently override a gameplay rule in `Arquitetura/`.

If Foundation and Arquitetura conflict:
1. identify whether the Foundation document is a stale implementation spec;
2. if the implementation spec reveals a genuine design change, flag it;
3. do not silently rewrite architecture.

### `Ideias/`
**Future proposals; non-canonical.**

Do not implement content from this directory during the MVP unless the user explicitly promotes it to the current architecture.

Ideas may be:
- rejected;
- partially adopted;
- corrected;
- or promoted into `Arquitetura/`.

Until promoted, they have no authority over the current game.

### `Assets/`
Actual game assets and project resources.

### `Imagens/`
Visual references and source material. These are not gameplay authority.

### `.claude/skills/`
Operational context for Claude. Skills are routing/context layers; they do not replace the architecture documents.

## Authority hierarchy

For current MVP work, use this hierarchy:

1. Explicit user decision in the current project context.
2. Current canonical document in `Arquitetura/`.
3. Other canonical architecture documents that are direct dependencies.
4. Current `Foundation/` implementation specifications.
5. Code/tests, as evidence of current implementation — **not** as authority over documented rules.
6. `Ideias/` — only after explicit promotion.

If two sources at the same authority level conflict, stop and classify the conflict instead of guessing.

## Skill routing

Start with `.claude/skills/bs-core/`.

Then load the narrowest domain Skill:

- Combat → `bs-combat`
- Cards → `bs-cards`
- Commanders → `bs-commanders`
- Economy → `bs-economy`
- City/PvE/PvP/World → `bs-world`
- Consistency/documentation validation → `bs-audit`

Do not load all Skills or all documents by default.

## Change workflow

```text
User request
    ↓
Identify domain
    ↓
bs-core
    ↓
domain Skill
    ↓
PROJECT_INDEX
    ↓
owning SSoT in Arquitetura/
    ↓
direct dependencies only
    ↓
Foundation/ implementation specs if needed
    ↓
inspect code
    ↓
implement
    ↓
validate against SSoT
```

## Canonical ownership rules

- Card model/identity/state → `Arquitetura/CARD.md`
- Card progression → `Arquitetura/CARD_PROGRESSION.md`
- Concrete card data → `Arquitetura/CARD_CATALOG.md`
- Unit characteristics/abilities → `Arquitetura/ABILITIES.md`
- Combat rules → `Arquitetura/COMBAT_RULES.md`
- Combat engine flow → `Arquitetura/COMBAT_CORE.md`
- Affinity → `Arquitetura/AFFINITY.md`
- Energy → `Arquitetura/ENERGY.md`
- Soldo → `Arquitetura/SOLDO.md`
- Shared formulas → `Arquitetura/FORMULAS.md`
- Commander architecture/details → the corresponding `Arquitetura/COMMANDER_*.md` owner
- City → `Arquitetura/CITY.md` plus the specific building owner
- Mines → `Arquitetura/MINES.md`
- Deposits → `Arquitetura/DEPOSITS.md`
- Academy → `Arquitetura/ACADEMY.md`
- Command Center progression → `Arquitetura/COMMAND_CENTER_PROGRESS.md`
- PvE → `Arquitetura/PvE.md` and referenced subsystem owners
- PvP matchmaking → `Arquitetura/MATCHMAKING.md`
- Ranking → `Arquitetura/RANKING.md`
- Seasons → `Arquitetura/SEASONS.md`
- XP → `Arquitetura/XP.md`
- Resources → `Arquitetura/RESOURCES.md`

## Confirmed MVP invariants

- Tier is mutable from Tier 1 through Tier 5.
- Card Energy depends on Tier.
- Card Soldo depends exclusively on Rarity.
- A War Machine/Balista starts at position 9, then follows normal movement rules.
- Affinity bonuses are frozen during the current turn; composition changes affect the next turn.
- `Arquitetura/ABILITIES.md` is the authority for Unit Characteristics.
- Combat maximum is 64 turns.
- There is no canonical `unit_traits.md`; do not recreate it.
- `Treinamento Arcano` remains unresolved until missing historical documentation is recovered.
- Do not reconstruct the historical chain of `Engenharia Militar II` by inference.

## Known decision-sensitive area

PG scope/ownership has had conflicting statements across economic systems. Until the canonical decision is frozen, do not invent a new PG spending rule or silently remove an existing one. Flag the conflict.

## Legacy and audit files

Files such as audit reports, historical analyses, and old structure notes are useful evidence but do not automatically become gameplay authority.

When a document is explicitly marked legacy/historical, do not use it to override the current canonical rule.

## Documentation rule

When implementation changes a gameplay rule:

1. update the owning SSoT in `Arquitetura/`;
2. update directly affected references;
3. check the relevant Skill;
4. run `bs-audit` for non-trivial changes.

Do not create duplicate rule definitions merely to support a local implementation.
