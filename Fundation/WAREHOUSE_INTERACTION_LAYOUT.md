# WAREHOUSE_INTERACTION_LAYOUT.md

# BUILDING

Warehouse

---

# PURPOSE

The Warehouse is the Kingdom's central logistics hub.

Every physical resource owned by the player passes through this building.

It stores materials, manages inventories and supplies every construction and upgrade in the Kingdom.

Unlike the Energy Core, which stores magical power, the Warehouse stores physical resources.

Unlike the Command Center, which manages armies, the Warehouse manages supplies.

The environment should immediately communicate industrial organization, logistics and production.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- Background always remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Every logistics area is interactive.

Hover

- soft blue outline
- cursor changes
- subtle highlight

Click

- popup fades in
- room darkens slightly
- no camera movement

---

# HOTSPOTS

---

## HOTSPOT 01

Name

Kingdom Inventory

Location

Central Logistics Table

Object

Large planning table in the center of the warehouse.

Purpose

View every stored resource.

Opens

Inventory Popup

Contains

- Iron
- Wood
- Stone
- Food
- Arcane Crystals
- Vital Essence
- Event Resources
- Capacity Used
- Total Capacity

Priority

★★★★★

---

## HOTSPOT 02

Name

Material Storage

Location

Left Storage Area

Object

Large stacks of crates, pallets and shelving.

Purpose

Browse stored materials.

Opens

Storage Popup

Contains

- Resource Categories
- Quantity
- Sorting
- Filters
- Recently Acquired
- Storage Capacity

Priority

★★★★☆

---

## HOTSPOT 03

Name

Crystal Vault

Location

Right Crystal Storage

Object

Shelves containing Arcane Crystals and rare resources.

Purpose

Manage premium materials.

Opens

Crystal Vault Popup

Contains

- Arcane Crystals
- Vital Essence
- Rare Resources
- Legendary Materials
- Event Items

Priority

★★★★☆

---

## HOTSPOT 04

Name

Production Supply

Location

Rear Workshop Platform

Object

Crafting benches and logistics station.

Purpose

Monitor resource consumption.

Opens

Supply Chain Popup

Contains

- Incoming Resources
- Outgoing Resources
- Building Consumption
- Upgrade Requirements
- Production History

Priority

★★★☆☆

---

## HOTSPOT 05

Name

Warehouse Upgrade

Location

Planning Desk near Entrance

Object

Architectural blueprint desk.

Purpose

Upgrade the Warehouse.

Opens

Warehouse Upgrade Popup

Contains

Current Level

Storage Capacity

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

Cranes

Shelves

Cargo Carts

Storage Racks

Packing Tables

Glass Botanical Area

Secondary Vaults

Future updates may activate these objects.

---

# POPUP STYLE

Industrial medieval architecture.

Stone walls.

Heavy oak storage systems.

Bronze logistics equipment.

Blue crystal accents.

Parchment UI.

Semi-transparent dark overlay.

Rounded borders.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene

WarehouseInterior.tscn

Hotspots

Hotspot_Inventory

Hotspot_Storage

Hotspot_CrystalVault

Hotspot_SupplyChain

Hotspot_Upgrade

Popup Scenes

Popup_Inventory.tscn

Popup_Storage.tscn

Popup_CrystalVault.tscn

Popup_SupplyChain.tscn

Popup_WarehouseUpgrade.tscn

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

Auto Sorting

Resource History

Trade Depot

Crafting Materials

Guild Donations

Marketplace Storage

Warehouse Workers

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

✔ Kingdom Inventory

✔ Material Storage

✔ Crystal Vault

✔ Supply Chain

✔ Warehouse Upgrade

Status

READY FOR GODOT IMPLEMENTATION