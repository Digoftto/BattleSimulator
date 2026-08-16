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
