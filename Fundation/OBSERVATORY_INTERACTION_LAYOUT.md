# OBSERVATORY_INTERACTION_LAYOUT.md

# BUILDING

Observatory

---

# PURPOSE

The Observatory is the Kingdom's intelligence center.

It is responsible for everything related to exploration, reconnaissance and strategic information.

Unlike the Library, which stores knowledge, the Observatory discovers new knowledge.

Unlike the World Map Gate, which deploys expeditions, the Observatory analyzes the world before the expedition begins.

The environment should feel like a combination of an astronomical observatory, cartography room and strategic intelligence headquarters.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- Background always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Every important scientific instrument is interactive.

Hover

- soft blue glow
- cursor changes
- subtle brightness increase

Click

- popup fades in
- environment darkens slightly
- no camera movement

---

# HOTSPOTS

---

## HOTSPOT 01

Name

Celestial Observatory

Location

Large Armillary Sphere

Object

Massive astronomical mechanism positioned on the upper platform.

Purpose

World intelligence and celestial events.

Opens

Celestial Observatory Popup

Contains

- Current World Conditions
- Special Events
- Weather Modifiers
- Seasonal Effects
- Future Event Forecasts
- Active World Bonuses

Priority

★★★★★

---

## HOTSPOT 02

Name

World Scanner

Location

Central Holographic Map

Object

Large illuminated tactical map in the center of the room.

Purpose

Reveal exploration information.

Opens

World Scanner Popup

Contains

- Explored Regions
- Fog of War
- Territory Status
- Exploration Progress
- Hidden Locations
- Discovery Percentage

Priority

★★★★★

---

## HOTSPOT 03

Name

Reconnaissance Desk

Location

Left Strategy Table

Object

Large table covered with maps, reports and miniature armies.

Purpose

Expedition intelligence.

Opens

Reconnaissance Popup

Contains

- Enemy Information
- Difficulty Estimates
- Suggested Army Power
- Recommended Commanders
- Terrain Analysis
- Expected Rewards

Priority

★★★★☆

---

## HOTSPOT 04

Name

Research Archive

Location

Right Research Desk

Object

Scientific desk containing charts, manuscripts and navigation instruments.

Purpose

Advanced world information.

Opens

Research Archive Popup

Contains

- Region Lore
- Ancient Ruins
- Landmark Information
- Expedition History
- Previous Discoveries

Priority

★★★☆☆

---

## HOTSPOT 05

Name

Observatory Upgrade

Location

Architect Blueprint Desk

Object

Small planning desk positioned near the entrance.

Purpose

Upgrade the Observatory.

Opens

Observatory Upgrade Popup

Contains

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

Priority

★★★★★

---

# RESERVED HOTSPOTS

Currently decorative only.

Bookshelves

Windows

Navigation Instruments

Globes

Telescopes

Small Armillary Models

Scientific Cabinets

Upper Balcony

Future updates may activate these objects.

---

# POPUP STYLE

Stone architecture.

Dark oak furniture.

Bronze astronomical instruments.

Blue crystal illumination.

Ancient parchment UI.

Semi-transparent dark background.

Rounded borders.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene

ObservatoryInterior.tscn

Hotspots

Hotspot_CelestialObservatory

Hotspot_WorldScanner

Hotspot_ReconDesk

Hotspot_ResearchArchive

Hotspot_Upgrade

Popup Scenes

Popup_CelestialObservatory.tscn

Popup_WorldScanner.tscn

Popup_Reconnaissance.tscn

Popup_ResearchArchive.tscn

Popup_ObservatoryUpgrade.tscn

Hover Animation

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

Reserved systems

World Boss Tracker

Guild Recon Reports

Astronomical Calendar

Expedition Replay

Kingdom Statistics

Alliance Intelligence

None of these are required for the MVP.

---

# MVP STATUS

Approved Building Artwork

✔

Interaction Layout

✔

Hotspots

5

Immediate Popups

✔ Celestial Observatory

✔ World Scanner

✔ Reconnaissance

✔ Research Archive

✔ Observatory Upgrade

Status

READY FOR GODOT IMPLEMENTATION