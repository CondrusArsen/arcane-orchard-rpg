# Project Overview

## Concept

Arcane Orchard RPG is a compact Roblox RPG prototype set in a fantasy village/orchard environment. The player earns and spends money, unlocks abilities, collects apples, fights NPCs, and uses magic to attack or place temporary structures.

## Core Systems

### World

- Main world folder: `Workspace/World`
- Includes fields, garden areas, orchard trees, props, structures, boosters, NPC spawn points, NPC movement points, and runtime NPC rigs.

### Magic

- Fireball projectile with explosion.
- Ice Arrow projectile with freeze effect.
- Spikes trap.
- Placeable wall, floor, and stairs.
- Super Magic meteor burst with capped explosions.

### NPCs

- Archer and Magicion enemy rigs.
- NPCs patrol between paired parts.
- NPCs detect players in a radius and switch from patrol to attack behavior.
- Death rewards are tagged through a `creator` value.
- Spawn points are released after NPC death.

### Economy

- Money and mana values are created on player join.
- Money can be earned through generators and NPC rewards.
- Mana regenerates over time and can also be upgraded through the shop.
- Shop purchases unlock combat/building abilities.
- Apples can be bought and sold.

### UI

- Static `StarterGui` styling saved directly in Roblox properties.
- Shop UI for purchases and upgrades.
- Skill UI for unlocked abilities and cooldowns.
- HP, mana, and money display.

### Persistence

- Money and mana are saved through `DataStoreService` outside Studio.
- Studio testing skips DataStore calls to avoid local API permission warnings.

## Main Technical Topics

- Roblox Luau scripting.
- Server/client architecture.
- `RemoteEvent` and `BindableEvent` workflows.
- `DataStoreService` persistence.
- `PathfindingService` NPC movement.
- Runtime cloning and cleanup with `Debris`.
- Projectile movement with `RunService.Heartbeat`.
- Static Roblox GUI styling through saved properties.

## Current Scope

The project is a working prototype. It is intentionally small enough to inspect and extend, but broad enough to demonstrate multiple gameplay systems in one Roblox place.

