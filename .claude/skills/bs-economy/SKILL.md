---
name: bs-economy
description: Battle Simulator economy: Resources, Energy, Soldo, PG, XP, formulas, Academy production economics, Mines, Deposits and construction economics.
---

# BS Economy

## Primary SSoT

Use the narrowest owner first:

- `RESOURCES.md` — resource/economic definitions
- `ENERGY.md` — operational Energy
- `SOLDO.md` — Soldo
- `XP.md` — XP and Account progression
- `FORMULAS.md` — shared equations
- `ACADEMY.md` — Academy production
- `MINES.md` — Mine production
- `DEPOSITS.md` — storage
- `COMMAND_CENTER_PROGRESS.md` — Command Center progression

## Critical rules

- Card Energy depends on Tier.
- Card Soldo depends on Rarity.
- Do not merge XP of different domains into one pool.
- Do not create a global PvE reward multiplier: reward domains may have different ratios.
- Treat balance parameters separately from mathematical identities.
- Do not invent construction `b`/`x` values if they are marked for balance calibration.

## PG warning

PG ownership/scope has appeared inconsistently across documents. Until the canonical decision is frozen, do not silently expand or restrict PG spending. Report the conflict.

## Numeric audit rule

Whenever changing an economic value:
1. locate the formula;
2. locate the table/parameter;
3. identify all dependent systems;
4. recompute examples;
5. check for unit/rounding assumptions;
6. update all canonical owners.

Do not use a stale example as a source of truth.
