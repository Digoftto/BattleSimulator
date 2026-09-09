# Battle Simulator — Visual Skill (`bs-visual`)

## Purpose

This Skill governs visual and presentation work in the Battle Simulator MVP:

- UI and HUD;
- layout and responsive composition;
- typography;
- visual hierarchy;
- transparency and overlays;
- Battle Art and battlefield assets;
- asset integration;
- visual effects and presentation;
- visual consistency between factions and systems.

It does not define gameplay rules, combat formulas, card data, economy, or world mechanics. Those remain owned by their respective Skills and SSoT documents.

## 1. First determine the layer being changed

Before editing, classify the request as one or more of:

1. static asset;
2. UI/layout;
3. typography;
4. runtime presentation;
5. animation/effect;
6. asset-to-runtime integration.

Do not change another layer merely because it is technically convenient.

## 2. Asset vs. dynamic UI

### Static assets

Use image assets for:
- characters;
- buildings;
- scenery;
- symbols;
- icons;
- decorative elements;
- battlefield unit views.

### Dynamic runtime/UI

Use Godot resources/nodes for:
- text;
- numbers;
- counters;
- XP and levels;
- resources/currencies;
- names;
- health/shield/damage;
- visibility/state;
- positioning;
- movement;
- scale;
- orientation selection;
- animation.

Never create separate images for values that change during gameplay when normal Godot UI can render them.

## 3. Typography

The project should use reusable font resources rather than embedding text into artwork.

When a fantasy/medieval visual identity is requested:
- use a suitable project font resource;
- keep titles more distinctive if appropriate;
- keep body/status/numeric information highly readable;
- avoid decorative fonts that become illegible at small sizes;
- use subtle outline/shadow only when needed for contrast against the artwork.

If no approved font resource exists, do not invent a font identity silently. Identify the missing resource and ask for the decision or use the least invasive temporary choice explicitly marked as such.

## 4. HUD and map composition

The map/artwork should remain visually dominant unless the design explicitly says otherwise.

For HUD elements placed over artwork:
- prefer transparent backgrounds;
- do not add dark bars or opaque panels without explicit approval;
- use typography, spacing, alignment, small separators, and restrained ornaments to establish hierarchy;
- preserve the underlying artwork wherever possible.

Do not change map cropping, aspect-ratio behavior, safe zones, or hitboxes unless the task explicitly requires it.

## 5. Battle Art production rules

Battlefield art is not card art.

A battlefield asset must be designed around:
- the actual camera angle;
- the occupied tile;
- the battlefield's visual depth;
- neighboring units;
- the intended gameplay scale;
- directional readability.

When directional movement matters, produce distinct views as separate files where required:

- `front`
- `back`
- `left`
- `right`

The runtime selects the correct view. Do not encode battlefield movement logic into the artwork itself.

The four views must represent the same unit consistently:
- same proportions;
- same equipment;
- same silhouette language;
- same visual quality;
- same material treatment.

The pose may communicate direction naturally, but the asset must not depend on text, arrows, labels, or UI markings to indicate direction.

## 6. Transparency and cutouts

Battlefield character/unit PNGs must have clean alpha.

Do not remove light-colored body parts, robes, armor, or effects because they resemble the background.

Validate that:
- the silhouette is intact;
- important interior surfaces remain opaque/visible;
- soft effects remain intentional;
- transparent background is actually transparent;
- the asset is readable at battlefield scale.

## 7. Tile occupancy

Unless the unit specification explicitly says otherwise, one battlefield unit occupies one battlefield tile.

Do not create an asset whose visible footprint unintentionally occupies neighboring tiles.

The unit may visually extend beyond the nominal tile area where the approved perspective/scale requires it, but the composition must remain compatible with the battlefield geometry and must not cause unintended overlap between units.

## 8. Runtime integration

Do not duplicate asset-specific positioning rules across unrelated scripts.

Prefer the existing shared geometry/integration helpers when they already provide:
- tile coordinates;
- depth ordering;
- anchor placement;
- scale-to-fit;
- orientation selection.

If existing infrastructure already solves the integration problem, do not rewrite it merely to support a new asset.

## 9. Visual iteration workflow

For a requested visual change:

1. inspect the existing implementation;
2. identify the exact visual layer involved;
3. read the relevant SSoT and Skill;
4. make the smallest required change;
5. run relevant technical checks;
6. report changed files and technical validation;
7. stop.

Claude does not need to generate screenshots unless the user explicitly requests them.

The user will open the project in Godot and perform direct visual inspection. Subsequent visual corrections should be based on the user's observations/screenshots rather than speculative extra work.

## 10. Token and scope discipline

Visual tasks must not expand into unrelated cleanup or redesign.

Do not:
- refactor unrelated code;
- generate large screenshot suites without request;
- alter gameplay systems to solve presentation problems;
- modify assets that were not part of the request;
- implement future visual systems merely because they may be useful later.

If the task can be completed with one asset, one resource, or one small UI change, do not build a larger framework.

## 11. Reporting

At completion, report concisely:

- files changed;
- what was changed;
- technical checks performed;
- any unresolved blocker or assumption.

Do not claim visual acceptance merely because tests pass. Visual acceptance is determined by direct inspection unless an explicit automated visual criterion exists.
