# SKILLS_AUDIT_v0.2

## Result

The 7-Skill structure is appropriate for the MVP.

### Confirmed

- `bs-core` contains cross-domain invariants and workflow.
- `bs-audit` is a validator, not a second architecture document.
- `bs-combat`, `bs-cards`, `bs-commanders`, `bs-economy`, and `bs-world` are domain-scoped.
- No substantive duplication problem was found beyond a few intentional invariants.
- Specialized Skills do not need to reproduce the full architecture documents.

### Corrections made

1. Removed the stale `UNIT_TRAITS.md` reference from `bs-cards`; `ABILITIES.md` is canonical.
2. Added explicit routing from `bs-audit` through `PROJECT_INDEX.md` and the relevant domain Skill.
3. Marked all Skills as current-MVP scope; future ideas are excluded.
4. Kept cross-domain invariants in `bs-core` because they prevent common implementation errors.

## Important design decision

Do NOT create one Skill per document.

The Skills are an access-control/context layer above the architecture documents. The documents remain the source of truth.

## Recommended loading pattern

Task → `bs-core` → one domain Skill → 1–4 owner documents → implementation.

Cross-domain task → `bs-core` → relevant domain Skills → only affected SSoTs.

## Next step

Create a minimal `CLAUDE.md` that:
- identifies the project;
- points to `PROJECT_INDEX.md`;
- tells Claude to use Skills;
- enforces SSoT/conflict rules;
- enforces MVP-only scope;
- avoids duplicating game rules already stored in Skills/documents.
