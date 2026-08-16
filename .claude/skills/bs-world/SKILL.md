---
name: bs-world
description: Battle Simulator world systems: City, Academy, Mines, Deposits, PvE, PvP, Matchmaking, Ranking, Seasons and campaign/world structure.
---

# BS World

## Routing

Use `PROJECT_INDEX.md` to identify the narrowest SSoT.

Typical domains:

- City/infrastructure → `CITY.md` and the specific building owner
- Academy → `ACADEMY.md`
- Mines → `MINES.md`
- Deposits → `DEPOSITS.md`
- PvE → `PvE.md` and its subsystem documents
- PvP → ranking/matchmaking/season owners
- Seasons → `SEASONS.md`

## Rules

- Do not use City as a replacement for the specific building's SSoT.
- Do not duplicate building formulas into City.
- Keep PvE and PvP reward rules separate.
- Matchmaking, Ranking and Seasons are separate responsibilities.
- Historical/legacy documents must not silently override the current MVP corpus.
- If a world-system change consumes a shared currency, consult `bs-economy`.

## MVP discipline

Ideas not yet approved are not current rules.

When implementing a world feature:
1. identify its owner;
2. inspect direct dependencies;
3. check economy/progression impact;
4. implement only the current documented behavior;
5. leave future ideas untouched.
