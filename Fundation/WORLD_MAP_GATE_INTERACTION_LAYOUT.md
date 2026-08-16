# WORLD_MAP_GATE_INTERACTION_LAYOUT.md

# BUILDING

World Map Gate

---

# PURPOSE

The World Map Gate is the Kingdom's deployment headquarters.

Every PvE activity begins here.

Unlike the Command Center, where armies are organized, the World Map Gate is where those armies leave the Kingdom.

This building is the transition between the safe Kingdom and the dangerous outside world.

It should immediately communicate movement, exploration, campaigns and military deployment.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- Background always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Every expedition station is interactive.

Hover

- soft blue glow
- cursor changes
- slight brightness increase

Click

- popup fades in
- background darkens slightly
- no camera movement

---

# HOTSPOTS

---

## HOTSPOT 01

Name

Campaign Map

Location

Central World Table

Object

Large relief map occupying the center of the hall.

Purpose

Main PvE navigation.

Opens

World Map Popup

Contains

- Territories
- Campaign Progress
- Difficulty Levels
- Available Expeditions
- Completed Regions
- Current Location

Priority

★★★★★

---

## HOTSPOT 02

Name

Deployment Gate

Location

Main Gate

Object

Massive fortified gate at the back of the hall.

Purpose

Launch expeditions.

Opens

Deploy Army Popup

Contains

- Selected Army
- Commander
- Energy Cost
- Estimated Duration
- Rewards Preview
- Deploy Button

Priority

★★★★★

---

## HOTSPOT 03

Name

Mission Planning

Location

Left Expedition Desk

Object

Planning table with expedition documents.

Purpose

Mission preparation.

Opens

Mission Planning Popup

Contains

- Available Missions
- Objectives
- Enemy Information
- Recommended Power
- Mission Rewards

Priority

★★★★☆

---

## HOTSPOT 04

Name

World Intelligence

Location

Right Intelligence Desk

Object

Wall map and reconnaissance equipment.

Purpose

Regional information.

Opens

Region Information Popup

Contains

- Region Description
- Terrain
- Enemy Factions
- Environmental Effects
- Completion Rewards

Priority

★★★★☆

---

## HOTSPOT 05

Name

Travel Records

Location

Navigation Instruments

Object

Globes, compasses and navigation archive near the entrance.

Purpose

Campaign statistics.

Opens

Travel Records Popup

Contains

- Completed Expeditions
- Total Distance Traveled
- Regions Cleared
- Fastest Completion
- Exploration Statistics

Priority

★★★☆☆

---

# RESERVED HOTSPOTS

Currently decorative only.

Bookshelves

Navigation Instruments

Statues

Wall Decorations

Banners

Secondary Desks

Upper Balcony

Future updates may activate these objects.

---

# POPUP STYLE

Grand medieval stone architecture.

Heavy oak furniture.

Bronze navigation instruments.

Large parchment maps.

Blue crystal accents.

Semi-transparent dark overlay.

Rounded borders.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene

WorldMapGateInterior.tscn

Hotspots

Hotspot_CampaignMap

Hotspot_DeploymentGate

Hotspot_MissionPlanning

Hotspot_WorldIntelligence

Hotspot_TravelRecords

Popup Scenes

Popup_WorldMap.tscn

Popup_DeployArmy.tscn

Popup_MissionPlanning.tscn

Popup_RegionInformation.tscn

Popup_TravelRecords.tscn

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

Endless Mode

Daily Expeditions

Weekly Campaigns

World Boss Portal

Guild Expeditions

Seasonal Events

Challenge Missions

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

✔ Campaign Map

✔ Deploy Army

✔ Mission Planning

✔ Region Information

✔ Travel Records

Status

READY FOR GODOT IMPLEMENTATION