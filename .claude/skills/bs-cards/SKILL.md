---
name: bs-cards
description: Battle Simulator card architecture, attributes, rarity, Tier progression, card catalog, classes, abilities, Energy and Soldo relationships.
---

# BS Cards

## Primary SSoT

- `CARD.md` — card model and identity/state boundaries
- `CARD_PROGRESSION.md` — Tier progression
- `CARD_CATALOG.md` — concrete card data
- `ABILITIES.md` — unit characteristics and ability definitions
- `ENERGY.md` — Energy rules
- `SOLDO.md` — Soldo rules

## Critical rules

- Tier is mutable: Tier 1 → Tier 5.
- Rarity is distinct from Tier.
- Card Energy is determined by Tier.
- Card Soldo is determined exclusively by Rarity.
- Do not derive Energy from Rarity.
- Do not derive Soldo from Tier.
- `ABILITIES.md` is the authority for Unit Characteristics.

## Progression

When changing Tier progression, inspect both the progression rule and the concrete catalog/data representation.

When changing a specific card, distinguish:
- canonical ability;
- card-specific parameter;
- card-specific presentation/name.

Do not create a new canonical ability merely because a card has a narrative label.
