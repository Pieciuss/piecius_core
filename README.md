# Piecius Core

Vehicle management system with key system, hotwire, ID cards, and dispatch control.

## Features

- **Vehicle Blocking** — Automatically removes military, Arena War, and non-RP vehicles
- **Key System** — Vehicle keys as inventory items with lock/unlock functionality
- **Hotwire** — Attempt to hotwire vehicles without keys (configurable chance)
- **ID Card (Dowód)** — Show your ID card to nearby players
- **Dispatch Control** — Disable wanted level, dispatch services, and emergency spawns
- **Military Base Cleanup** — Removes NPC vehicles from Fort Zancudo area

## Dependencies

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [Piecius_hud](../Piecius_hud)
- **ESX** or **QBCore** (auto-detected)

## Installation

1. Copy `Piecius_core` to your server's `resources` folder
2. Import the SQL if needed (uses `owned_vehicles` table)
3. Add `ensure Piecius_core` to your `server.cfg` (after framework and dependencies)
4. Configure `config.lua` to your needs

## Configuration

Edit `config.lua` to customize:

- `Config.BlockedVehicles` — List of vehicle models to auto-delete
- `Config.KeyItem` — Inventory item name for keys (default: `'kluczyk'`)
- `Config.LockDistance` — Max distance to lock/unlock vehicles
- `Config.HotwireEnabled` — Enable/disable hotwire system
- `Config.HotwireChance` — Success chance percentage
- `Config.DisableWantedLevel` — Disable wanted stars
- `Config.DisableDispatch` — Disable AI dispatch
- `Config.DowodCommand` — Command name for ID card

## Commands

| Command | Description |
|---------|-------------|
| `/dowod` | Show your ID card to nearby players |
| `/dajkluczyk [id] [plate]` | Give a key to player (admin) |
| `/zrobkluczyk [plate]` | Make a key for your own vehicle |
| `/dajklucz [id]` | Give your key to another player |

## Keybinds

| Key | Action |
|-----|--------|
| `U` | Lock/Unlock vehicle or attempt hotwire |

## Framework Support

Supports both **ESX** and **QBCore** via auto-detection bridge.
