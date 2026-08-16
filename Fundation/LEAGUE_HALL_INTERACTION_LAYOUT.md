# LEAGUE_HALL_INTERACTION_LAYOUT.md

# BUILDING

League Hall

---

# PURPOSE

The League Hall is the Kingdom's competitive headquarters.

Everything related to PvP, rankings, leagues, seasons, and competitive prestige is accessed here.

Unlike the Command Center, which prepares armies, the League Hall celebrates competition and measures player strength.

This building should feel ceremonial, prestigious and competitive.

---

# CAMERA

- Camera enters through the main entrance.
- Slow forward movement.
- Stops at the approved interior artwork.
- Camera never rotates.
- Background remains visible behind every popup.

---

# INTERACTION PRINCIPLE

Every competitive area is interactive.

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

League Arena

Location

Central Emblem Platform

Object

Large circular platform with the Kingdom emblem.

Purpose

Main PvP entry.

Opens

League Overview Popup

Contains

- Current League
- Current Rank
- Rating
- Season Progress
- Enter Battle

Priority

★★★★★

---

## HOTSPOT 02

Name

Hall of Champions

Location

Left Statue Gallery

Object

Rows of statues honoring legendary warriors.

Purpose

Historical champions.

Opens

Hall of Champions Popup

Contains

- Season Champions
- Top Players
- Legendary Records
- Kingdom Heroes
- Champion Profiles

Priority

★★★★☆

---

## HOTSPOT 03

Name

Season Rankings

Location

Right Wall Maps

Object

League boards and historical records.

Purpose

Current competitive standings.

Opens

Rankings Popup

Contains

- Global Ranking
- Friends Ranking
- Guild Ranking
- Win Rate
- Rating Distribution

Priority

★★★★★

---

## HOTSPOT 04

Name

Season Rewards

Location

Front Left Reward Table

Object

Display table presenting trophies and rewards.

Purpose

Season reward preview.

Opens

Season Rewards Popup

Contains

- Current Rewards
- League Rewards
- Promotion Rewards
- Season Countdown
- Claim Rewards

Priority

★★★★☆

---

## HOTSPOT 05

Name

League Administration

Location

Rear Administration Desk

Object

Main administrative desk beneath the Kingdom crest.

Purpose

League management.

Opens

League Information Popup

Contains

- Season Rules
- Matchmaking Rules
- PvP Statistics
- Patch Notes
- League Information

Priority

★★★☆☆

---

# RESERVED HOTSPOTS

Currently decorative only.

Weapon Displays

Flags

Statues

Windows

Decorative Maps

Wall Decorations

Upper Gallery

Future updates may activate these objects.

---

# POPUP STYLE

Royal medieval architecture.

Dark polished stone.

Blue banners.

Gold ornamentation.

Large marble statues.

Prestigious atmosphere.

Semi-transparent dark overlay.

Rounded borders.

Fade animation.

200–300 ms.

---

# GODOT IMPLEMENTATION

Scene

LeagueHallInterior.tscn

Hotspots

Hotspot_LeagueArena

Hotspot_HallOfChampions

Hotspot_SeasonRankings

Hotspot_SeasonRewards

Hotspot_LeagueAdministration

Popup Scenes

Popup_LeagueOverview.tscn

Popup_HallOfChampions.tscn

Popup_Rankings.tscn

Popup_SeasonRewards.tscn

Popup_LeagueInformation.tscn

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

Guild Wars

Tournaments

Spectator Mode

Replay Center

Regional Championships

World Championship

PvP Events

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

✔ League Overview

✔ Hall of Champions

✔ Rankings

✔ Season Rewards

✔ League Information

Status

READY FOR GODOT IMPLEMENTATION