# PROJECT_INDEX.md — Battle Simulator MVP

## 0. Purpose

This file is the operational map of the Battle Simulator documentation.

It exists so a human or AI agent can answer, before changing anything:

1. Where is this rule defined?
2. Which document owns it?
3. Which documents should be consulted before changing it?
4. Is the document a rule source, a catalog, a governance file, or an analysis?
5. Is the issue already decided, or does it require an explicit design decision?

This index does not replace the architecture documents. It routes the agent to them.

---

# 1. Authority hierarchy

When working on the MVP, use this order:

1. `DECISOES.md` — development/documentation governance.
2. `GAME_PHILOSOPHY.md` — permanent design principles.
3. System SSOT — the document that owns the specific rule.
4. `FORMULAS.md` — shared mathematical relationships.
5. `BALANCING_SIMULATION.md` — currently active balance parameters.
6. Catalog/content documents — concrete data.
7. UI/tutorial/library documents — presentation and onboarding.
8. Code — implementation of the documented architecture.

If code conflicts with architecture, fix the code unless an explicit architectural revision has been approved first.

---

# 2. Critical project rules already decided

These rules are locked for the current MVP unless explicitly revised:

- Balista starts at position 9 and then follows normal movement rules.
- Tier is mutable, from Tier 1 through Tier 5.
- Energy depends on Tier.
- Soldo depends exclusively on Rarity.
- Affinity bonuses are frozen during the current turn; changes affect the next turn.
- `ABILITIES.md` owns Unit Characteristics.
- `UNIT_TRAITS.md` does not exist.
- Combat maximum is 64 turns.
- `Comando de Reparos` is the current documented evolution of `Engenharia Militar`.
- `Treinamento Arcano` is unresolved and must not be invented.

---

# 3. Architectural layers

## A. Governance

| Document | Owner / purpose |
|---|---|
| `PROJECT_STRUCTURE.md` | Documentation architecture. Currently contains duplicated historical content and needs cleanup. |
| `DECISOES.md` | Development, SSOT, AI-agent and documentation governance. |

## B. Philosophy / vocabulary / world

| Document | Owner / purpose |
|---|---|
| `GAME_PHILOSOPHY.md` | Permanent design principles. |
| `GLOSSARY.md` | Official terminology and owner mapping. |
| `LORE.md` | World, narrative and thematic foundations. |
| `FACTION_DESIGN.md` | Faction design principles. |

## C. Combat

| Document | Owner / purpose |
|---|---|
| `COMBAT_CORE.md` | Combat architecture and system boundaries. |
| `COMBAT_RULES.md` | Operational combat rules, phases, snapshots, targets, damage, victory and turn limit. |
| `ABILITIES.md` | Canonical ability catalog and ability behavior. |
| `AFFINITY.md` | Affinity points, levels and bonuses. |
| `BATTLEFIELDS.md` | Battlefield definitions and modifiers. |
| `ARMY.md` | Army structure, formations, composition and availability. |

## D. Cards / content

| Document | Owner / purpose |
|---|---|
| `CARD.md` | Card entity architecture and identity/state model. |
| `CARD_PROGRESSION.md` | Tier progression and upgrading. |
| `CARD_CATALOG.md` | Concrete card data. Catalog; does not redefine generic mechanics. |
| `LIBRARY_CONTENT.md` | Static content/lore/recipe relationships exposed by the Library. |
| `LIBRARY.md` | Library presentation/query layer. |

## E. Commanders / military administration

| Document | Owner / purpose |
|---|---|
| `COMMANDERS.md` | Commander architecture, ranks and military career. |
| `COMMANDER_GENERATION.md` | Commander generation. |
| `COMMANDER_REQUIREMENTS.md` | Advantage requirements. |
| `COMMANDER_RESTRICTIONS.md` | Commander restrictions. |
| `COMMANDER_TARGETS.md` | Advantage targets. |
| `COMMANDER_EFFECTS.md` | Advantage effects. |
| `COMMANDER_VALUES.md` | Effect values. |
| `COMMAND_CENTER.md` | Command Center architecture and administrative states. |
| `COMMAND_CENTER_PROGRESS.md` | Command Center structural/administrative progression. |
| `COMMAND_CENTER_RECRUITMENT.md` | Commander recruitment/incorporation. |
| `COMMAND_CENTER_TRAINING.md` | Passive commander training. |
| `COMMAND_CENTER_LEGACY.md` | Commander retirement/Legacy systems. |
| `COMMAND_CENTER_UI.md` | Command Center UI/navigation; never the owner of underlying rules. |
| `SOLDO.md` | Soldo costs, commander ceilings and army composition constraints. |

## F. City / infrastructure

| Document | Owner / purpose |
|---|---|
| `CITY.md` | City architecture. |
| `CAPITAL.md` | Capital progression and gates. |
| `ACADEMY.md` | Card creation, upgrading, production queues and Academy progression. |
| `ENERGY_NUCLEUS.md` | Energy infrastructure, base capacity and recovery efficiency. |
| `DEPOSITS.md` | Construction-resource storage and PG-based Deposit progression. |
| `MINES.md` | Mine ownership, mining cycles, production and PG-based mine progression. |
| `OBSERVATORY.md` | Analysis/telemetry; not a gameplay SSOT. |

## G. Economy / progression

| Document | Owner / purpose |
|---|---|
| `RESOURCES.md` | Resources, Fragment economy, VRP and VRG. |
| `FORMULAS.md` | Shared equations and mathematical relationships. |
| `BALANCING_SIMULATION.md` | Active calibration values and simulations; current b/x values are here. |
| `XP.md` | Commander XP and Account XP. |

## H. Game modes / competition

| Document | Owner / purpose |
|---|---|
| `PvE.md` | PvE campaign/trails/expeditions. |
| `MATCHMAKING.md` | Matchmaking and battle snapshot generation. |
| `RANKING.md` | Leagues, divisions and competitive points. |
| `SEASONS.md` | Season lifecycle and content expansion. |

## I. Onboarding / review

| Document | Owner / purpose |
|---|---|
| `TUTORIAL.md` | Tutorial flow. Not yet frozen. |
| `TUTORIAL_REVIEW.md` | Review recommendations; never overrides Tutorial rules. |

---

# 4. Recommended reading order for an AI agent

## First pass

1. `DECISOES.md`
2. `GAME_PHILOSOPHY.md`
3. `GLOSSARY.md`
4. `COMBAT_CORE.md`
5. `COMBAT_RULES.md`
6. `CARD.md`
7. `CARD_PROGRESSION.md`
8. `ABILITIES.md`
9. `ARMY.md`
10. `COMMANDERS.md`
11. `SOLDO.md`
12. `CITY.md`
13. `RESOURCES.md`
14. `FORMULAS.md`
15. `XP.md`

## Then read only the subsystem relevant to the requested task.

Do not load all 49 documents into context for every code change.

---

# 5. Routing rules

### Combat change

Read:

`COMBAT_CORE → COMBAT_RULES → relevant ABILITIES/AFFINITY/CARD_CATALOG/ARMY/BATTLEFIELDS`

### Card change

Read:

`CARD → CARD_PROGRESSION → ABILITIES → CARD_CATALOG → SOLDO/ENERGY if costs are involved`

### Commander change

Read:

`COMMANDERS → relevant COMMANDER_* → COMMAND_CENTER → SOLDO`

### City change

Read:

`CITY → target building document → FORMULAS → RESOURCES/XP if relevant`

### Economy change

Read:

`RESOURCES → FORMULAS → BALANCING_SIMULATION → affected system`

### PvE change

Read:

`PvE → COMBAT_RULES → ARMY → ENERGY → MINES/RESOURCES/XP as required`

### PvP change

Read:

`RANKING → MATCHMAKING → COMBAT_RULES → ARMY → ENERGY → SOLDO`

### UI change

Read:

the UI document first, then the owner of the underlying rule.

A UI document may never redefine a gameplay rule.

---

# 6. SSOT rules

A document is a rule owner only for the domain explicitly assigned to it.

Never resolve a conflict by making a second document authoritative.

If a rule is duplicated:

1. identify the owner;
2. correct the owner;
3. replace the duplicate with a reference;
4. update examples;
5. only then implement.

---

# 7. Important known issue — PG

Current documents disagree about the scope of PG.

`XP.md` says PG are used exclusively for Mines and Deposits.

`COMMAND_CENTER_PROGRESS.md` uses PG for administrative activation.

`MINES.md` and `DEPOSITS.md` use PG for their progression.

**Status: DESIGN DECISION REQUIRED.**

The agent must not choose between these interpretations.

---

# 8. Known unresolved content

### `Treinamento Arcano`

Not present in the current 49-document corpus.

Do not invent it.

### Historical `Engenharia Militar II`

The current corpus uses `Comando de Reparos` as the evolved Tier V ability. Historical naming should not be reintroduced unless the missing documentation requires it.

---

# 9. Known stale references

Do not create replacement documents merely to satisfy old references.

Current intended owners include:

- `UNIT_TRAITS.md` → `ABILITIES.md`
- `COMBAT.md` → `COMBAT_CORE.md` / `COMBAT_RULES.md`
- `RECRUITMENT.md` → `COMMAND_CENTER_RECRUITMENT.md`
- `TURN_SEQUENCE.md` → `COMBAT_RULES.md`
- `WEATHER.md` → `BATTLEFIELDS.md`

`PROJECT_STRUCTURE.md` itself contains references to documents outside the current 49-file MVP corpus and needs cleanup.

---

# 10. Balance governance

`FORMULAS.md` owns equations.

`BALANCING_SIMULATION.md` owns currently active calibration parameters.

Current active construction parameters:

| Construction | b | x |
|---|---:|---:|
| Capital | 50 | 300 |
| Command Center | 50 | 225 |
| Academy | 50 | 460 |
| Energy Nucleus | 50 | 530 |

An AI agent must never invent a replacement b/x pair during implementation.

---

# 11. MVP principle

The current objective is **MVP implementation**.

Therefore:

- do not incorporate future ideas;
- do not redesign systems merely because a future proposal might be better;
- do not create speculative abstractions for unapproved mechanics;
- implement only the currently documented architecture;
- when the documentation is contradictory, stop and identify the conflict;
- when a rule is missing, do not invent it.

---

# 12. Change protocol

Before modifying code:

1. Identify the affected domain.
2. Open the owner document.
3. Open its directly referenced dependencies.
4. Check for a known decision in `DECISOES.md`.
5. Check this Index for unresolved conflicts.
6. If the rule is stable, implement.
7. If the rule must change, update architecture first.
8. Then update affected references/examples.
9. Only after documentation is coherent, modify code.

---

# 13. Next documentation artifacts

This Index is the foundation for:

1. `CLAUDE.md`
2. Individual Claude Skills by subsystem.
3. Implementation-specific documentation.
4. Future idea/proposal validation.

The Ideas folder must be treated as a separate proposal layer and must not modify the MVP architecture automatically.
