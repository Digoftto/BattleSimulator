# ENERGY_CORE_INTERACTION_LAYOUT.md

# BUILDING

Energy Core

---

# PURPOSE

The Energy Core is the Kingdom's power plant.

It generates, stores and distributes every form of magical energy used by the Kingdom.

Every building ultimately depends on the Energy Core.

This building should immediately communicate that it is the technological and magical heart of the city.

Unlike the Academy, which researches knowledge, the Energy Core produces energy.

Unlike the Warehouse, which stores resources, the Energy Core stores power.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- Background always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Every major machine is interactive.

Hover

- blue energy pulse
- cursor changes
- emissive glow increases slightly

Click

- popup fades in
- room darkens slightly
- no camera movement

---

# HOTSPOTS

---

## HOTSPOT 01

Name

Core Crystal

Location

Center Crystal Reactor

Object

Large crystal suspended inside the central containment ring.

Purpose

Collect and monitor Energy.

Opens

Energy Core Popup

Contains

- Current Energy
- Maximum Capacity
- Energy Production / Hour
- Energy Consumption
- Collect Energy Button
- Overflow Status

Priority

★★★★★

---

## HOTSPOT 02

Name

Energy Distribution

Location

Left Engineering Console

Object

Engineering workstation connected to the crystal conduits.

Purpose

Monitor energy usage.

Opens

Distribution Popup

Contains

- Buildings Consumption
- Active Buildings
- Idle Buildings
- Energy Allocation
- Efficiency Bonus

Priority

★★★★☆

---

## HOTSPOT 03

Name

Crystal Processing

Location

Right Machinery Platform

Object

Industrial crystal refinement machines.

Purpose

Manage Arcane Crystal conversion.

Opens

Crystal Processing Popup

Contains

- Crystal Inventory
- Crystal Conversion
- Refined Crystals
- Production Queue
- Processing Speed

Priority

★★★★☆

---

## HOTSPOT 04

Name

Power Network

Location

Rear Control Altar

Object

Master control console behind the reactor.

Purpose

View Kingdom power network.

Opens

Power Network Popup

Contains

- Connected Buildings
- Network Status
- Efficiency
- Active Bonuses
- Maintenance Status

Priority

★★★☆☆

---

## HOTSPOT 05

Name

Energy Core Upgrade

Location

Planning Desk near Entrance

Object

Architectural blueprint table.

Purpose

Upgrade the building.

Opens

Energy Core Upgrade Popup

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

Energy Pipes

Pressure Valves

Generators

Secondary Crystals

Control Wheels

Storage Cabinets

Upper Balcony

Future updates may activate these objects.

---

# POPUP STYLE

Dark stone architecture.

Blue crystal illumination.

Bronze machinery.

Heavy industrial mechanisms.

Ancient magical engineering.

Parchment UI.

Semi-transparent dark overlay.

Rounded borders.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene

EnergyCoreInterior.tscn

Hotspots

Hotspot_CoreCrystal

Hotspot_Distribution

Hotspot_CrystalProcessing

Hotspot_PowerNetwork

Hotspot_Upgrade

Popup Scenes

Popup_EnergyCore.tscn

Popup_Distribution.tscn

Popup_CrystalProcessing.tscn

Popup_PowerNetwork.tscn

Popup_EnergyCoreUpgrade.tscn

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

Energy Batteries

Kingdom Power Grid

Energy Boosters

Crystal Resonance

Seasonal Energy Events

Alliance Energy Sharing

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

✔ Energy Core

✔ Energy Distribution

✔ Crystal Processing

✔ Power Network

✔ Energy Core Upgrade

Status

READY FOR GODOT IMPLEMENTATION