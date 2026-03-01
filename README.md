# Snap Dungeon

Daily dungeon crawler for mobile. Deterministic seeded runs, portrait mode, touch controls, Firebase leaderboards.

Built with Godot 4.6 + GDScript. Engine based on [statico/godot-roguelike-example](https://github.com/statico/godot-roguelike-example) (MIT).

## Features

- Turn-based roguelike with D20 combat, behavior tree AI, shadowcasting FOV
- Daily seeded runs (5 floors) with deterministic generation
- Portrait mode (256x416) with swipe + touch action bar
- DawnLike pixel art tileset
- Firebase backend: anonymous auth, daily leaderboard, score submission
- Inventory and equipment system with modular components
- Data-driven items and monsters (CSV)
- Share card generation (Wordle-style emoji grid)

## Development Setup

1. Clone the repo
2. Open in Godot 4.6
3. Run the project

### VS Code / Cursor

Install recommended extensions (Godot Tools, GDScript Formatter). Run `Tasks: Run Task` > `Run Godot Project`.

Optional: install [gdtoolkit](https://github.com/Scony/gdtoolkit) for linting/formatting.

### Data Files

Monster and item data lives in `assets/data/*.csv`. Edit with LibreOffice or any spreadsheet editor. Set CSV import mode to "Keep" in Godot to avoid generating translation files.

### Art Pipeline

See `art/README.md`. Processes DawnLike tilesets into sprite atlases.

### Debug Tools

- `scenes/debug/map_generator_tool.tscn` — dungeon generator preview
- `scenes/debug/item_explorer.tscn` — item data browser
- `scenes/debug/sprite_explorer.tscn` — sprite/tile browser

## Project Structure

```
src/
  world.gd              — central game state, turn engine, signals
  dice.gd               — seeded D20 roller
  seed_factory.gd       — daily/floor seed generation
  combat.gd             — D20 combat resolution
  monster_ai.gd         — behavior tree AI
  map.gd                — map data + FOV
  map_renderer.gd       — tilemap rendering
  constants.gd          — game constants (MAX_FLOORS, etc.)
  actions/              — action system (move, attack, pickup, equip, ...)
  actions/effects/      — visual effect descriptors
  map_generators/       — dungeon/arena generation
  data/                 — data classes (RunState, PlayerProfile, etc.)
  autoload/             — singletons (backend, audio, persistence, etc.)
scenes/
  game/                 — main gameplay scene
  menu/                 — main menu with class selection
  ui/                   — HUD, modals, inventory, floor transition
  actor/                — entity rendering
  fx/                   — visual effects
  debug/                — dev tools
assets/
  data/                 — CSV item/monster definitions
  audio/                — SFX + music
  generated/            — sprite atlases from art pipeline
  fonts/                — Pixel Operator (CC0)
  ui/                   — theme and styles
cloud_functions/        — Firebase Cloud Functions (TypeScript)
art/                    — tileset processing pipeline
```

## Architecture

- **SSOT**: `World` autoload owns all game state and signals
- **Actions**: all input becomes `Action` objects processed by the turn engine
- **Determinism**: all RNG flows through `Dice._rng` seeded by `SeedFactory`
- **Data-driven**: monsters/items defined in CSV, loaded via factory classes
- **Backend**: Firebase REST API (anonymous auth, Firestore leaderboard)

## Licenses

Source code: MIT. See `LICENSE`.

Artwork: [DawnLike by DawnBringer](https://opengameart.org/content/16x16-dawnhack-roguelike-tileset) — see tileset license.

Font: [Pixel Operator](https://www.dafont.com/pixel-operator.font) — CC0.
