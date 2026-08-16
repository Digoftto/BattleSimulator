---
name: bs-core
description: Core operating rules for the Battle Simulator project. Use for any task that touches game rules, architecture, documentation, or code behavior.
---

# BS Core

You are working on the Battle Simulator MVP.

## Authority

- Treat the current architecture corpus and `PROJECT_INDEX.md` as the primary routing layer.
- Before changing code, identify the owning/SSoT document for the rule.
- Do not invent missing mechanics, values, abilities, formulas, or historical definitions.
- If two canonical-looking documents conflict, stop implementation and report the conflict.
- Do not treat future ideas/proposals as current MVP rules.
- Do not load the entire documentation corpus unless the task genuinely crosses multiple systems.

## Critical confirmed rules

These are cross-domain invariants. Domain-specific details remain in the relevant skill.

- Tier is mutable and progresses from Tier 1 through Tier 5.
- Card Energy depends on Tier.
- Card Soldo depends exclusively on Rarity.
- A War Machine/Balista starts at position 9, then follows normal movement rules.
- Affinity bonuses are frozen during the current turn; composition changes affect the next turn.
- `ABILITIES.md` is the authority for Unit Characteristics.
- Combat maximum is 64 turns.
- `Treinamento Arcano` remains unresolved until missing historical documentation is recovered.
- `Engenharia Militar II` / its current evolution relationship must not be reconstructed from guesses.

## Workflow

1. Identify the task domain.
2. Read this skill.
3. Read only the relevant domain skill(s).
4. Follow the domain skill's SSoT references.
5. Check dependent systems before editing.
6. Implement the smallest change consistent with the architecture.
7. Validate the result against the SSoT.
8. Report any unresolved documentation conflict instead of silently choosing a rule.
