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
- World Map Gate (navigation entry point for PvE/PvP/Mines) → `Arquitetura/WORLD_MAP_GATE.md`
- Campo de Prova (Army test/preparation tool, accessed via Command Center → Exércitos) → `Arquitetura/CAMPO_DE_PROVA.md`
- PvP matchmaking → `Arquitetura/MATCHMAKING.md`
- Ranking → `Arquitetura/RANKING.md`
- Seasons → `Arquitetura/SEASONS.md`
- XP → `Arquitetura/XP.md`
- Resources → `Arquitetura/RESOURCES.md`
- PG (Pontos de Geração) → `Arquitetura/GENERATION_POINTS.md`

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

## Resolved decision record

PG scope/ownership previously had conflicting statements across economic systems ("Prestígio Global", "PdG", and a false Mines/Deposits-exclusivity claim). This has been resolved by the project owner: PG is one shared global infrastructure resource (`Pontos de Geração`), not exclusive to any system. Current consumers: Mines, Deposits, Command Center, Academy — the list may grow. SSoT: `Arquitetura/GENERATION_POINTS.md`.

Command Center previously owned the navigation entry point for PvP/PvE/Mines (decision then cited as "F-016/F-017" in `CITY.md`/`COMMAND_CENTER_UI.md`). This has been explicitly reversed by the project owner: the World Map Gate is now that entry point; the Command Center no longer defines those 3 windows. No PvP/PvE/Mines rule, resolver, or save data changed — only navigation ownership. SSoT: `Arquitetura/WORLD_MAP_GATE.md`.

**Second correction:** the World Map Gate's own physical location was initially left reachable only through a button inside the Command Center (a provisional, incorrect placement). The project owner clarified the World Map Gate must be its own City location (a direct hitbox in `city_panel.gd`, same "Consulta" group as Biblioteca/Observatório), never a Command Center window in any form. This has been fixed: `city_panel.gd` now has a `world_map_gate` region over the gate structure already present in `City.png`; `command_center_panel.gd` no longer references it at all. No PvE/PvP/Mines scene, rule, or resolver changed — only the entry point's physical location.

A player-facing "test my Army" system (informally requested as "Campo de Testes") was initially searched for and not found under that name. It was later located as `Ideias/CAMPO_DE_PROVA.md` (a non-canonical proposal) and has since been promoted to `Arquitetura/CAMPO_DE_PROVA.md` — the project owner explicitly decided it belongs to the Command Center, inside the Army preparation flow (Command Center → Exércitos → Editor de Exército → Campo de Prova), never as a World Map Gate destination. No functionality has been implemented — see that document's "Estado de Implementação" section for exactly what exists vs. what remains conceptual. A documentation tension was flagged when `COMMAND_CENTER.md`'s "Missão" (then 5 responsibilities, scoped entirely to Commander administration) did not list Exércitos or Campo de Prova — this has since been resolved: the Missão now lists 7 responsibilities, explicitly adding "organizar o acesso" to Exércitos and to Campo de Prova (never redefining `ARMY.md`'s or `CAMPO_DE_PROVA.md`'s own rules). `CAMPO_DE_PROVA.md`'s own "tensão documental registrada" paragraph still describes the pre-fix state and was intentionally left untouched (out of scope for that correction pass) — a small follow-up update there would bring it in sync.

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
