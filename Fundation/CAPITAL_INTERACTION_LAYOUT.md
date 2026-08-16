# CAPITAL_INTERACTION_LAYOUT.md

# BUILDING
Capital

---

# PURPOSE

The Capital is the political and administrative heart of the Kingdom.

This building contains the highest level management of the player's kingdom.

It is intentionally calm, ceremonial and prestigious.

Unlike the Command Center, there is no military planning here.

Unlike the Academy, there is no research.

Everything inside should communicate authority, government and long-term progression.

---

# CAMERA

- Camera enters through the main gate.
- Slow forward movement.
- Stops at the current approved artwork.
- Camera never rotates.
- Building always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

The room itself is the interface.

There are no floating buttons.

Every feature is opened by interacting with a physical object inside the hall.

Hover:
- subtle blue outline
- cursor changes
- object slightly brightens

Click:
- camera remains fixed
- popup fades in
- background is darkened slightly (15–20%)
- Capital interior always stays visible

---

# HOTSPOTS

## HOTSPOT 01

Name:
Kingdom Overview

Location:
Central War Table

Object:
Large stone relief map located at the center of the hall.

Purpose:
General kingdom overview.

Opens:

Kingdom Overview Popup

Contains:

- Kingdom Level
- Account XP
- Generation Points
- Total Population
- Overall Progress
- Kingdom Power
- Current Bonuses
- Active Effects

Priority:
★★★★★

---

## HOTSPOT 02

Name:
Capital Upgrade

Location:
Royal Council Table
(left meeting table)

Object:
Large meeting table with scrolls and construction plans.

Purpose:
Upgrade the Capital.

Opens:

Capital Upgrade Popup

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

## HOTSPOT 03

Name:
Kingdom Statistics

Location:
Right-side fountain.

Object:
Royal fountain representing the prosperity of the kingdom.

Purpose:
Displays kingdom statistics.

Opens:

Statistics Popup

Contains:

Military Power

Economic Power

Research Progress

Battles Won

Cards Owned

Buildings

Resources Produced

Achievements

Priority:
★★★☆☆

---

## HOTSPOT 04

Name:
Kingdom History

Location:
Upper gallery.

Object:
Large statues overlooking the throne room.

Purpose:
Historical records.

Opens:

History Popup

Contains:

Kingdom Timeline

Important Events

Major Victories

Unlocked Chapters

Lore

Priority:
★★☆☆☆

---

# RESERVED HOTSPOTS

The following objects are intentionally NOT interactive yet.

Large Staircase

Upper Balconies

Bookshelves

Side Doors

Windows

Decorative Trees

Blue Crystal Lamps

They may become interactive in future expansions.

---

# POPUP STYLE

Every popup uses the same visual language.

Stone frame.

Dark blue fabric accents.

Bronze details.

Soft blue crystal illumination.

Rounded corners.

Semi-transparent background.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene:

CapitalInterior.tscn

Hotspots:

Hotspot_Overview

Hotspot_Upgrade

Hotspot_Statistics

Hotspot_History

Popup Scenes:

Popup_KingdomOverview.tscn

Popup_CapitalUpgrade.tscn

Popup_KingdomStatistics.tscn

Popup_KingdomHistory.tscn

Hover Animation:

Scale:
1.00 → 1.03

Glow:
0 → 0.2

Duration:
0.15 s

Click Animation:

Popup Fade

Background Darkening

No Camera Movement

---

# FUTURE EXPANSION

Reserved for future systems:

Royal Advisors

Diplomacy

Kingdom Laws

Season Management

Achievements Hall

Event Room

Guild Administration

None of these should be implemented during MVP.

---

# MVP STATUS

Approved Building Artwork:
✔

Interaction Layout:
✔

Hotspots:
4

Immediate Popups:

✔ Kingdom Overview

✔ Capital Upgrade

✔ Kingdom Statistics

✔ Kingdom History

Status:

READY FOR GODOT IMPLEMENTATION