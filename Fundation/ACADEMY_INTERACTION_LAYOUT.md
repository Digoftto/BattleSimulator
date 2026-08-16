# ACADEMY_INTERACTION_LAYOUT.md

# BUILDING

Academy

---

# PURPOSE

The Academy is the scientific heart of the Kingdom.

Every long-term progression system related to technology, evolution and experimentation begins here.

Unlike the Capital, this building represents knowledge instead of authority.

Unlike the Command Center, it focuses on development rather than military management.

The Academy should feel alive, experimental and constantly evolving.

---

# CAMERA

- Camera enters through the Academy main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- The environment always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

The laboratory itself is the interface.

Every important workstation is a clickable object.

Hover:

- subtle blue glow
- cursor changes
- workstation slightly illuminates

Click:

- popup fades in
- background darkens slightly (15–20%)
- camera remains fixed

---

# HOTSPOTS

---

## HOTSPOT 01

Name:

Artificer Laboratory

Location:

Left Workshop Area

Object:

Large engineering benches filled with tools, blueprints, mechanical devices and crafting equipment.

Purpose:

Create and upgrade equipment, artifacts and technological projects.

Opens:

Artificer Popup

Contains:

- Craft Equipment
- Upgrade Equipment
- Recipes
- Required Materials
- Success Rate
- Queue (future)

Priority:

★★★★★

---

## HOTSPOT 02

Name:

Metamorph Laboratory

Location:

Right Experimental Platforms

Object:

Large circular arcane platforms with crystal reactors and transformation chambers.

Purpose:

Unit evolution and biological transformation.

Opens:

Metamorph Popup

Contains:

- Evolution
- Transformation
- Mutation
- Requirements
- Preview
- Confirm Evolution

Priority:

★★★★★

---

## HOTSPOT 03

Name:

Research Core

Location:

Central Crystal Platform

Object:

Large circular crystal reactor located at the center of the Academy.

Purpose:

General research overview.

Opens:

Research Overview Popup

Contains:

- Active Research
- Research Progress
- Available Projects
- Queue
- Research Speed
- Global Bonuses

Priority:

★★★★☆

---

## HOTSPOT 04

Name:

Academy Upgrade

Location:

Front Blueprint Table

Object:

Large architectural planning table located near the entrance.

Purpose:

Upgrade the Academy building.

Opens:

Academy Upgrade Popup

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

## HOTSPOT 05

Name:

Knowledge Archive

Location:

Rear Library

Object:

Large bookshelves occupying the back wall of the Academy.

Purpose:

Research encyclopedia.

Opens:

Knowledge Archive Popup

Contains:

Unlocked Technologies

Research History

Crafting Encyclopedia

Evolution Records

Game Lore

Priority:

★★★☆☆

---

# RESERVED HOTSPOTS

Currently decorative only.

Upper Balconies

Large Trees

Small Workstations

Side Shelves

Crystal Lamps

Windows

Upper Galleries

Future expansions may activate these objects.

---

# POPUP STYLE

All Academy popups share the same visual language.

Dark stone frame.

Blue magical crystal accents.

Bronze mechanical details.

Scientific atmosphere.

Animated crystal illumination.

Rounded corners.

Semi-transparent background.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene:

AcademyInterior.tscn

Hotspots:

Hotspot_Artificer

Hotspot_Metamorph

Hotspot_Research

Hotspot_Upgrade

Hotspot_Archive

Popup Scenes:

Popup_Artificer.tscn

Popup_Metamorph.tscn

Popup_ResearchOverview.tscn

Popup_AcademyUpgrade.tscn

Popup_KnowledgeArchive.tscn

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

Alchemy

Rune Laboratory

Legendary Projects

Technology Tree

Master Researchers

Academy Events

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

✔ Artificer

✔ Metamorph

✔ Research Overview

✔ Academy Upgrade

✔ Knowledge Archive

Status:

READY FOR GODOT IMPLEMENTATION