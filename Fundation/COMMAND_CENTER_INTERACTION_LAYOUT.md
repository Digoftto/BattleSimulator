# COMMAND_CENTER_INTERACTION_LAYOUT.md

# BUILDING

Command Center

---

# PURPOSE

The Command Center is the military headquarters of the Kingdom.

It is where the player organizes every military aspect before entering battle.

Unlike the Academy, which improves technology, the Command Center manages the army itself.

Unlike the World Map Gate, which launches expeditions, the Command Center prepares those expeditions.

The room should feel like a medieval war room filled with tactical planning, command decisions and military administration.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- Background always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Every military workstation is interactive.

Hover

- soft blue outline
- cursor changes
- slight illumination

Click

- popup appears
- background darkens slightly
- no camera movement

---

# HOTSPOTS

---

## HOTSPOT 01

Name

Army Management

Location

Central War Table

Object

Large circular strategic battlefield table in the center of the room.

Purpose

Manage the player's army.

Opens

Army Management Popup

Contains

- Current Army
- Total Power
- Army Presets
- Formation Selection
- Assigned Heroes
- Assigned Troops

Priority

★★★★★

---

## HOTSPOT 02

Name

Commander Office

Location

Left Command Desk

Object

Large administrative desk with military documents.

Purpose

Manage Commanders.

Opens

Commander Popup

Contains

- Commander List
- Commander Details
- Equipment
- Experience
- Promotion
- Skills

Priority

★★★★★

---

## HOTSPOT 03

Name

War Planning Room

Location

Right Strategy Table

Object

Large rectangular tactical planning table.

Purpose

Prepare military operations.

Opens

Battle Planning Popup

Contains

- Battle Presets
- Saved Strategies
- Tactical Notes
- Formation Templates
- Recent Battles

Priority

★★★★☆

---

## HOTSPOT 04

Name

Hall of Veterans

Location

Right Statue Gallery

Object

Military memorial with statues, banners and trophies.

Purpose

Military records.

Opens

Veteran Records Popup

Contains

- Battle Statistics
- Lifetime Victories
- Elite Units
- Fallen Heroes
- Army Achievements

Priority

★★★☆☆

---

## HOTSPOT 05

Name

Command Center Upgrade

Location

Planning Desk near Entrance

Object

Architectural planning desk.

Purpose

Upgrade the building.

Opens

Command Center Upgrade Popup

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

Military Archives

Wall Maps

Commander Statues

Flags

Weapon Displays

Upper Balcony

Future updates may activate these objects.

---

# POPUP STYLE

Dark medieval stone.

Military blue banners.

Heavy oak furniture.

Bronze decorations.

War maps.

Ancient parchment UI.

Semi-transparent dark overlay.

Rounded borders.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene

CommandCenterInterior.tscn

Hotspots

Hotspot_ArmyManagement

Hotspot_CommanderOffice

Hotspot_WarPlanning

Hotspot_VeteranRecords

Hotspot_Upgrade

Popup Scenes

Popup_ArmyManagement.tscn

Popup_Commanders.tscn

Popup_BattlePlanning.tscn

Popup_VeteranRecords.tscn

Popup_CommandCenterUpgrade.tscn

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

Army Presets

Mercenary Recruitment

Army History

Battle Replays

Commander Contracts

Military Doctrine

Alliance Armies

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

✔ Army Management

✔ Commander Office

✔ Battle Planning

✔ Veteran Records

✔ Command Center Upgrade

Status

READY FOR GODOT IMPLEMENTATION