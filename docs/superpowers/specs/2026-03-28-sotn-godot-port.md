# SOTN Godot Port — Design Spec

## Overview

A faithful port of Castlevania: Symphony of the Night to Godot 4.6, with modern remastering capabilities (4K, lighting, particles, effects, asset upscaling). Built as a learning exercise to understand how a game like this should be put together, with the goal of bringing lessons back to original content (Crimson Vesper).

**Scope:** Richter Prologue (Dracula fight) + Castle Entrance through Slogra & Gaibon boss.

**Philosophy:**
- Faithful first — get it working exactly like SOTN
- Modern second — layer remastering on top of the faithful base
- Learn by building — understand every system by implementing it
- Human playtests feel, AI handles code/systems/architecture

---

## Data Sources

### Primary: sotn-decomp (local fork)
Location: `/Users/zero/Documents/Dev/sotn-decomp/`

Available data:
- **Room layouts**: `assets/st/no3/rooms.json` (32 rooms), `assets/st/st0/rooms.json` (Prologue)
- **Layer definitions**: `assets/st/no3/layers.json`, `assets/st/st0/layers.json`
- **Tilemaps**: `assets/st/no3/no3_tilemap_*.bin` (binary tile placement data)
- **Tile definitions**: `assets/st/no3/no3_tiledef_*.json` + associated `.bin` files (cluts, cols, pages, tiles)
- **Texture pages**: `assets/st/no3_0.png` through `no3_7.png` (grayscale tile sheets)
- **CLUT palettes**: `assets/st/no3_clut.png` (color lookup table)
- **Alucard data**: `assets/dra/` (sprites as address-named PNGs + animation YAML)
- **Richter data**: `assets/ric/`
- **Decompiled C source**: Full game logic for physics, AI, combat — reference for accuracy

Stage codes:
| Code | Area |
|------|------|
| ST0 | Prologue (Richter vs Dracula) |
| NO3 | Castle Entrance (1st castle) |
| NP3 | Castle Entrance (variant) |
| NO0 | Marble Gallery (NOT Entrance) |
| NZ0 | Alchemy Lab |

### Secondary: Community Sprite Sheets (Spriters Resource)
316 assets available. Use for:
- **Alucard** — 2 full sprite sheets + transformations (bat, mist, wolf)
- **Richter Belmont** — full sprite sheet
- **Count Dracula** — prologue boss
- **Slogra & Gaibon** — Entrance boss fight
- **57+ enemies** — skeletons, mermen, zombies, flea men, warg, etc.
- **HUD elements** — health bars, menus, fonts
- **Save Point** — gold effect animation
- **Sub Weapons, Item Effects, Spells**
- **Entrance Objects** — doors, gates, decorations

### Gap (decomp fills):
- **Tilesets** — Entrance tileset not on Spriters Resource; use decomp texture pages + CLUTs
- **Room layout data** — rooms.json, layers.json, tilemaps from decomp

---

## Technical Architecture

### Viewport & Resolution

**Base viewport: 960×540** (quarter 4K, 16:9)
- Scales to 1080p (2x), 1440p (2.67x), 4K (4x) cleanly
- SOTN's 256×224 content at ~3.75x within viewport
- Ultrawide: Godot `expand` stretch aspect extends visible area horizontally
- MacBook Pro Retina: scales perfectly
- `canvas_items` stretch mode, nearest-neighbor texture filtering

**Coordinate mapping:**
- SOTN 16px tile → 60px in our viewport (16 × 3.75)
- Alucard ~48px tall → 180px in viewport
- Room screen (256×224) → 960×840 in viewport (plus HUD space)

**Assets imported at 4x NN upscale** (64px tiles) — Godot downsamples 64→60 cleanly.

### Project Structure

```
sotn-godot-port/
├── godot/                          # Godot 4.6 project
│   ├── project.godot               # 960×540 viewport, canvas_items stretch
│   ├── assets/
│   │   ├── sprites/
│   │   │   ├── alucard/            # All Alucard animations
│   │   │   ├── richter/            # Richter animations
│   │   │   ├── enemies/            # Per-enemy sprite sheets
│   │   │   ├── bosses/             # Dracula, Slogra, Gaibon
│   │   │   └── effects/            # Sub weapons, spells, items
│   │   ├── tilesets/
│   │   │   ├── no3/                # Entrance tiles (palette-applied, upscaled)
│   │   │   └── st0/                # Prologue tiles
│   │   ├── ui/                     # HUD elements, fonts, menus
│   │   └── audio/                  # Music (CD audio tracks), SFX
│   ├── scenes/
│   │   ├── player/
│   │   │   ├── alucard.tscn        # Alucard scene with state machine
│   │   │   └── richter.tscn        # Richter scene (prologue)
│   │   ├── enemies/                # Per-enemy scenes
│   │   ├── bosses/                 # Boss scenes
│   │   ├── rooms/
│   │   │   ├── no3/                # Entrance rooms (generated from decomp)
│   │   │   └── st0/                # Prologue rooms
│   │   └── ui/
│   │       ├── hud.tscn            # In-game HUD
│   │       ├── pause_menu.tscn     # Equipment/Stats/Spells
│   │       └── title_screen.tscn
│   └── scripts/
│       ├── player/
│       │   ├── alucard.gd          # Main player controller
│       │   ├── richter.gd          # Richter controller
│       │   └── states/             # State machine states
│       ├── enemies/                # Enemy AI scripts
│       ├── bosses/                 # Boss AI scripts
│       ├── systems/                # Managers (game, room, save, audio, etc.)
│       └── data/                   # Item/equipment/enemy data definitions
├── tools/
│   └── asset_pipeline/             # Python scripts
│       ├── apply_palette.py        # CLUT + texture page → full-color PNG
│       ├── upscale_nn.py           # Nearest-neighbor 4x upscale
│       ├── extract_sprites.py      # Sprite sheet → individual frames
│       ├── rooms_to_godot.py       # rooms.json → .tscn scenes
│       └── generate_normal_maps.py # Future: for dynamic 2D lighting
└── docs/
    ├── physics_constants.md        # SOTN physics values from decomp
    └── enemy_data.md               # Enemy stats/behaviors from decomp
```

### Asset Pipeline

**Phase 1 pipeline (faithful):**
```
Decomp texture pages (grayscale) + CLUT palette
    ↓  apply_palette.py
Full-color 16px PNGs (faithful SOTN colors)
    ↓  upscale_nn.py
64px PNGs (4x nearest-neighbor, pixel-perfect)
    ↓  Import into Godot
Rendered in 960×540 viewport
```

**Phase 6 pipeline (remastered):**
```
64px faithful tiles
    ↓  AI upscale (Real-ESRGAN pixel art model)
High-detail tiles with added texture
    ↓  generate_normal_maps.py (Laigter)
Normal maps for each tile/sprite
    ↓  Godot PointLight2D + CanvasModulate + shaders
Dynamic 2D lighting, bloom, particles
    ↓
Modern SOTN with Ori/Lightfall-tier visuals
```

Key design decision: The viewport, camera, physics, and scene layout **never change** between faithful and remastered. Only textures swap. This means the game works first, then visuals layer on top.

---

## Phased Build

### Phase 1: Alucard in a Box
**Goal:** SOTN-accurate movement in a single room with real Alucard sprites.

**What to build:**
- Empty room (flat floor, walls at edges, one platform)
- Alucard with real sprite sheet animations: idle, walk, run, jump, fall, backdash, attack, crouch
- SOTN physics constants (from decompiled source):
  - Gravity, jump velocity, walk speed, run speed
  - Backdash distance and timing
  - Attack animation timing and hitbox placement
- Input mapping: move, jump, attack, backdash, crouch
- Camera: fixed to room

**Alucard sprites:** Source from Spriters Resource (2 full sheets). Extract individual animation frames with `extract_sprites.py`. NN 4x upscale.

**Physics reference:** `src/dra/` in sotn-decomp contains the decompiled player physics. Key files:
- Player state machine, gravity, velocity handling
- Jump arc calculations
- Attack frame data

**Verification:** User playtests. Does walking feel like SOTN? Does the jump arc match? Does backdash snap correctly? Does attack timing feel right? Iterate until the user confirms "this feels like SOTN."

**Deliverable:** A single room where Alucard moves, jumps, attacks, and backdashes with the exact feel of the PSX original.

### Phase 2: Asset Pipeline
**Goal:** Convert decomp tile data into Godot-ready assets. Render one real Entrance room.

**What to build:**
- `apply_palette.py`: Read NO3 texture pages + CLUT → output full-color tile sheets
- `upscale_nn.py`: Nearest-neighbor 4x upscale of all assets
- `rooms_to_godot.py`: Parse rooms.json + layers.json + tilemaps → generate Godot .tscn scenes with TileMapLayer
- Import one NO3 room into the Phase 1 box — verify tiles render correctly
- Verify foreground/background layers display in correct order

**Verification:** Run the game. Alucard stands in a real Entrance room with correct tiles, colors, and layer ordering. Proportions look right.

### Phase 3: Entrance Rooms + Enemies
**Goal:** Build Castle Entrance room-by-room with enemies.

**What to build:**
- Generate all 32 NO3 rooms from decomp data
- Room transitions (doors, edges) — RoomManager
- Camera limits per room, smooth follow in multi-screen rooms
- Enemies for the Entrance area:
  - Merman (water-based, leaps out of water)
  - Zombie (slow, shambling)
  - Skeleton (walking, throws bones)
  - Warg (fast, charges)
  - Bat (flying, swooping)
  - Others as encountered in the Entrance
- Enemy AI: reference decompiled C source for accurate behavior
- Enemy spawn positions from decomp entity data
- Basic combat: player attacks damage enemies, enemies damage player
- Enemy drops (hearts, items)

**Verification:** Walk through the entire Entrance from first room to Slogra & Gaibon door. All rooms render, enemies behave correctly, transitions work.

### Phase 4: Bosses
**Goal:** Slogra & Gaibon fight + Richter Prologue (Dracula).

**Slogra & Gaibon:**
- Two-boss simultaneous fight
- Slogra: ground-based spear attacks, leaps
- Gaibon: flying, swooping, fire breath
- Phase transitions when one dies (the other gets enraged)
- Boss HP bars
- Victory → door opens to next area

**Richter Prologue (Dracula):**
- Separate player character (Richter) with different moveset
- Dracula Phase 1: teleport + fireball patterns
- Dracula Phase 2: large demon form
- Pre-scripted opening (recreate the Maria scene)
- Transition to castle exterior / Alucard intro

**Verification:** Both boss fights are completable and feel accurate to the original.

### Phase 5: Systems
**Goal:** All RPG/metroidvania systems working.

**What to build:**
- HUD: HP bar, MP bar, hearts counter, current sub weapon icon
- Pause menu: Equipment, Spells, Stats, System
- Inventory/Equipment: weapon, shield, armor, cloak, accessories x2
- Stats: STR, CON, INT, LCK, ATK, DEF, level, EXP
- Leveling: EXP from kills, level-up stat increases
- Save rooms: save point interaction, save/load state
- Sub weapons: dagger, axe, holy water, cross, stopwatch
- Relics: collected items that grant abilities
- Heart system: hearts as sub weapon ammo
- Item drops: candles drop hearts/items, enemies have loot tables
- Map: room-by-room reveal as you explore

**Verification:** Full playthrough from prologue through Entrance with all systems functional. Level up, equip items, save, load, use sub weapons.

### Phase 6: Modern Enhancements
**Goal:** Ori/Lightfall-tier visual remastering.

**What to build:**
- **AI asset upscaling**: Run tiles/sprites through Real-ESRGAN pixel art model for enhanced detail
- **Normal map generation**: Generate normal maps from pixel art using Laigter or similar
- **Dynamic 2D lighting**: PointLight2D with normal maps — torches cast light that wraps around stone
- **CanvasModulate per room**: Atmospheric ambient lighting (cool blue exterior, warm torch interior)
- **GPUParticles2D**: Dust motes, fog wisps, ember sparks, water spray, boss arena effects
- **Light shafts**: Textured Sprite2D with additive blending + sway animation (moonlight through windows)
- **Screen-space effects**: Vignette overlay, subtle bloom on light sources
- **Boss fight lighting**: Dynamic — changes with boss phases, flashes on big attacks
- **60fps animations**: Interpolated from original 30fps where appropriate
- **Camera improvements**: Slight lookahead, smooth follow, subtle shake on impacts

**Verification:** The game looks stunning. Lighting creates mood and atmosphere. Every room has distinct visual identity. Player and enemies always readable.

---

## SOTN Physics Constants (Reference)

These will be extracted from the decompiled source during Phase 1. Approximate values from game analysis:

| Constant | SOTN Value (pixels/frame at 30fps) | Notes |
|----------|-----------------------------------|-------|
| Gravity | ~0.5 px/frame² | Applied every frame |
| Jump velocity | ~-6.0 px/frame | Initial upward velocity |
| Walk speed | ~1.5 px/frame | Normal walk |
| Run speed | ~2.5 px/frame | After run buildup |
| Backdash speed | ~4.0 px/frame | Fast, decelerating |
| Backdash duration | ~12 frames | Quick snap backward |
| Attack duration | ~15-20 frames | Depends on weapon |
| Fall max speed | ~6.0 px/frame | Terminal velocity |

These will be converted to Godot units (pixels/second at 60fps) during implementation.

---

## Standing Rules

- **Faithful first**: Get the original behavior working before adding modern features
- **Community sprites are fine**: Use pre-ripped sprite sheets from Spriters Resource if they're the actual faithful game art (not fanart/mods)
- **Decomp for data**: Use sotn-decomp for room layouts, tile data, physics constants, AI behavior
- **Meaningful commits**: Feature branches per phase, descriptive commit messages
- **Human playtests feel**: Movement, combat timing, jump arcs — user verifies by playing
- **AI handles code/systems**: Architecture, pipeline tools, GDScript, scene generation
- **4K support**: 960×540 base viewport, scales to any modern display including ultrawide
- **Nearest-neighbor 4x upscale** for Phase 1; AI upscale as Phase 6 enhancement
- **Pixel-perfect rendering**: Nearest-neighbor filtering, no texture smoothing, crisp pixels
