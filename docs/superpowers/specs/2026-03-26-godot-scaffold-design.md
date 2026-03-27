# Crimson Vesper — Godot Project Scaffold Design

Date: 2026-03-26 | Status: Approved

## Overview

Initial Godot 4.x project scaffold for Crimson Vesper, a 2D metroidvania. The Godot project lives in `godot/` inside the existing repo, keeping design docs, prototype work, and tooling as separate top-level directories.

## Repository Layout

```
CrimsonVesper/              ← repo root (already initialized)
├── docs/                   ← GDD, tech doc, audio doc (already committed)
├── prototype/
├── tools/
├── assets/                 ← raw/source art, audio — NOT imported by Godot
└── godot/                  ← Godot 4.x project root (this scaffold)
    ├── project.godot
    ├── .gitignore
    ├── .gitattributes
    ├── addons/
    ├── assets/             ← game-ready assets Godot can import
    │   ├── sprites/{player,enemies,npcs,effects}/
    │   ├── tilesets/
    │   ├── backgrounds/
    │   ├── ui/{hud,menus,fonts}/
    │   ├── audio/{music,sfx,ambient}/
    │   └── shaders/
    ├── scenes/
    │   ├── player/
    │   ├── enemies/
    │   ├── rooms/
    │   ├── ui/
    │   └── autoload/
    ├── scripts/
    │   ├── player/
    │   ├── enemies/
    │   ├── systems/        ← singleton GDScript files
    │   ├── ui/
    │   └── util/
    └── data/
        ├── items/
        ├── enemies/
        └── abilities/
```

## project.godot Configuration

- **Renderer**: Forward+ (Vulkan) — enables PointLight2D normal map pipeline
- **Display**: 1920×1080 base, stretch mode `canvas_items`, aspect `keep`
- **Physics**: 60 FPS fixed timestep
- **Input map**: move_left, move_right, jump, attack, dash, spell, interact, pause, map, inventory
- **Autoloads**: GameManager, SaveManager, AudioManager, AbilityManager, InventoryManager (all from `scripts/systems/`)

## Autoload Singletons

| Singleton | File | Responsibility |
|-----------|------|----------------|
| GameManager | `game_manager.gd` | Pause, scene transitions, game state enum, signal hub |
| SaveManager | `save_manager.gd` | JSON save/load, multiple slots, FileAccess |
| AudioManager | `audio_manager.gd` | Music/SFX playback, bus routing, crossfades |
| AbilityManager | `ability_manager.gd` | Boolean ability dict, `has_ability()` check |
| InventoryManager | `inventory_manager.gd` | Equipment slots, item storage |

## Player Scene

- Root: `CharacterBody2D` (`Player`)
  - `CollisionShape2D` (CapsuleShape2D)
  - `AnimatedSprite2D`
  - `StateMachine` (Node, custom script)
    - `IdleState`, `RunState`, `JumpState`, `FallState`, `AttackState`, `DashState`, `HurtState`
- State machine: stack-based, `enter()` / `exit()` / `update(delta)` / `handle_input(event)` per state
- Mechanics: variable jump height (release early = lower apex), coyote time (6 frames), placeholder dash

## Test Room Scene

- `Node2D` root
- `TileMapLayer` with a simple placeholder TileSet (solid color tiles)
- Player scene instantiated
- `Camera2D` attached to player with `position_smoothing_enabled = true`
- A few platforms to verify movement

## Git / GitHub

- Remote: `shikyo13/CrimsonVesper` (public, created via `gh repo create`)
- Branch: `main`
- Initial commit for scaffold covers all files above
