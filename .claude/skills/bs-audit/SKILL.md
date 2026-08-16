---
name: bs-audit
description: Validate Battle Simulator changes against the documented architecture, SSoT ownership, formulas, dependencies, and known unresolved decisions.
---

# BS Audit

## Routing

Start with `PROJECT_INDEX.md`, then load the domain Skill for the affected system. Do not audit the entire corpus by default.

Use this skill before or after any non-trivial rule or architecture change.

## Audit sequence

1. Identify the owning SSoT.
2. Identify every directly dependent document/system.
3. Search for duplicate definitions and stale references.
4. Check numerical consistency when values/formulas are involved.
5. Check whether the proposed behavior is MVP-current or a future idea.
6. Check code/data against the canonical rule.
7. Do not resolve ambiguous design choices by inference.

## Known unresolved items

- Scope/ownership of PG across Mines, Deposits, Command Center and related systems must follow the final canonical decision.
- `Treinamento Arcano` is unresolved because its historical definition is missing.
- Construction balance parameters may be intentionally pending; do not invent `b`/`x`.
- Academy time-reduction wording must follow the final canonical curve, not an invented literal interpretation.
- Missing historical documents must be recovered before reconstructing old mechanics.

## Classification

Classify findings as:

- CONFIRMED RULE
- DOCUMENTATION ERROR
- STALE/LEGACY REFERENCE
- BALANCE PARAMETER
- IMPLEMENTATION BUG
- DESIGN DECISION REQUIRED
- MISSING DOCUMENTATION

Never turn a BALANCE PARAMETER or DESIGN DECISION into an arbitrary implementation value.
