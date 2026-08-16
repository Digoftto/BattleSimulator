# LIBRARY_INTERACTION_LAYOUT.md

# BUILDING

Library

---

# PURPOSE

The Library is the Kingdom's permanent repository of knowledge.

Unlike the Academy, which creates new knowledge, the Library preserves, organizes and exposes everything the player has already discovered.

It functions as the game's encyclopedia, codex and historical archive.

Whenever the player wants information instead of progression, they come here.

The atmosphere should feel silent, ancient and scholarly.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- The environment always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Knowledge is represented by physical objects.

Every major archive inside the Library is clickable.

Hover:

- soft blue glow
- cursor changes
- object slightly brightens

Click:

- popup fades in
- background darkens slightly (15–20%)
- camera remains fixed

---

# HOTSPOTS

---

## HOTSPOT 01

Name:

Kingdom Codex

Location:

Central Map Table

Object:

Large illuminated archive table occupying the center of the Library.

Purpose:

Main encyclopedia of the game.

Opens:

Kingdom Codex Popup

Contains:

- Buildings
- Resources
- Units
- Commanders
- Cards
- Structures
- Regions
- Tutorials

Priority:

★★★★★

---

## HOTSPOT 02

Name:

Bestiary

Location:

Left Archive Shelves

Object:

Tall archive shelves containing creature records and biological manuscripts.

Purpose:

Information about every discovered creature and enemy.

Opens:

Bestiary Popup

Contains:

- Creatures
- Bosses
- Enemy Factions
- Weaknesses
- Strengths
- Drops

Priority:

★★★★☆

---

## HOTSPOT 03

Name:

World Atlas

Location:

Large Wall Maps

Object:

Historical maps mounted on the right wall.

Purpose:

Information about the world.

Opens:

World Atlas Popup

Contains:

- Continents
- Regions
- Territories
- Mines
- Kingdoms
- World Lore

Priority:

★★★★☆

---

## HOTSPOT 04

Name:

Lore Archive

Location:

Large Reading Table

Object:

Research table filled with scrolls and ancient books.

Purpose:

Narrative and historical information.

Opens:

Lore Archive Popup

Contains:

- Timeline
- Kingdom History
- Factions
- Characters
- Ancient Civilizations
- World Events

Priority:

★★★☆☆

---

## HOTSPOT 05

Name:

Library Upgrade

Location:

Blueprint Desk

Object:

Small librarian planning desk beside the entrance.

Purpose:

Upgrade the Library building.

Opens:

Library Upgrade Popup

Contains:

Current Level

Required Resources

Iron

x / y

Arcane Crystals

x / y

Vital Essence

x / y

Upgrade Requirements

Upgrade Button

Construction Timer (future)

Priority:

★★★★★

---

# RESERVED HOTSPOTS

Currently decorative only.

Upper Bookshelves

Reading Desks

Balconies

Windows

Decorative Plants

Small Archives

Candles

Future expansions may activate these objects.

---

# POPUP STYLE

All Library popups share the same visual language.

Dark carved wood.

Stone frames.

Bronze ornaments.

Blue crystal lighting.

Ancient parchment textures.

Rounded corners.

Semi-transparent background.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene:

LibraryInterior.tscn

Hotspots:

Hotspot_Codex

Hotspot_Bestiary

Hotspot_WorldAtlas

Hotspot_Lore

Hotspot_Upgrade

Popup Scenes:

Popup_KingdomCodex.tscn

Popup_Bestiary.tscn

Popup_WorldAtlas.tscn

Popup_LoreArchive.tscn

Popup_LibraryUpgrade.tscn

Hover Animation:

Scale

1.00 → 1.03

Glow

0 → 0.20

Duration

0.15 s

Click Animation

Popup Fade

Background Darkening

No Camera Movement

---

# FUTURE EXPANSION

Reserved systems:

Artifact Encyclopedia

Collection Album

Music Archive

Replay Archive

Achievements Archive

Community Records

None of these are required for the MVP.

---

# MVP STATUS

Approved Building Artwork:

✔

Interaction Layout:

✔

Hotspots:

5

Immediate Popups:

✔ Kingdom Codex

✔ Bestiary

✔ World Atlas

✔ Lore Archive

✔ Library Upgrade

Status:

READY FOR GODOT IMPLEMENTATION