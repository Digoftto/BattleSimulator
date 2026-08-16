---
name: bs-commanders
description: Battle Simulator Commander system: generation, ranks, requirements, restrictions, targets, effects, values, recruitment and training.
---

# BS Commanders

## Primary SSoT

Use the Commander documents named in `PROJECT_INDEX.md` and route to the narrowest owner:

- Commander architecture
- generation
- requirements
- restrictions
- targets
- effects
- values
- recruitment
- training

Do not assume `COMMANDERS.md` owns every detailed rule.

## Implementation model

Prefer the documented compositional model:

Requirement + Target + Effect + Value

Do not hard-code a Commander effect in unrelated combat/card code when the architecture defines it as Commander data.

## Workflow

1. Identify the Commander subsystem.
2. Read its owner document.
3. Read dependent combat/card/economy documents only when referenced.
4. Check rank/progression requirements.
5. Validate target/effect/value compatibility.
6. Audit code and data after implementation.
