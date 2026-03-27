# Workstream D: Rooms & Level Design — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build 4 connected intro-sequence rooms (Entry Hall → Corridor → Pre-Boss → Boss Arena) with transitions, pickups, save points, and atmospheric lighting, using the Gothicvania asset packs already in `godot/assets/`.

**Architecture:** All rooms use Option C — runtime GDScript TileSet creation (`TileSet.new()` + `TileSetAtlasSource`) so each room script is fully self-contained with no `.tres` dependencies for church/town tilesets. A `RoomManager` autoload handles fade-to-black transitions (0.5s out / 0.5s in) and spawn-point routing. Each room's `.tscn` defines the static node tree (floor/platform StaticBody2D, spawn Marker2Ds, door Area2Ds, parallax backgrounds) while the room GDScript builds visual tiles and wires up signals.

**Tech Stack:** Godot 4.6.1, GDScript, Gothicvania cemetery/church/town asset packs, existing autoloads (GameManager, SaveManager, AbilityManager, InventoryManager)

---

## File Map

| File | Role |
|------|------|
| `scripts/systems/room_manager.gd` | Autoload: fade overlay, transition_to(), fade_in(), spawn routing |
| `scripts/enemies/ghost.gd` | Floating enemy: no gravity, chases player on proximity |
| `scenes/enemies/ghost.tscn` | Ghost CharacterBody2D with 4-frame cemetery ghost sprites |
| `scripts/items/pickup.gd` | Generic Area2D pickup: bob animation, calls InventoryManager/AbilityManager |
| `scenes/items/pickup.tscn` | Pickup root; sprite set per instance in room |
| `scripts/items/save_point.gd` | Area2D crystal: pulsing PointLight2D, interact to save |
| `scenes/items/save_point.tscn` | Save point with PointLight2D |
| `scripts/rooms/entry_hall.gd` | Entry Hall: cemetery tileset, 3 skeletons, health pickup, save point |
| `scenes/rooms/entry_hall.tscn` | Entry Hall scene tree |
| `scripts/rooms/corridor.gd` | Corridor: church tileset, 2 ghosts + 1 skeleton, sword pickup |
| `scenes/rooms/corridor.tscn` | Corridor scene tree |
| `scripts/rooms/pre_boss.gd` | Pre-Boss: town tileset, 2 enemies, fireball + mana potion, save point |
| `scenes/rooms/pre_boss.tscn` | Pre-Boss scene tree |
| `scripts/rooms/boss_arena.gd` | Boss Arena: cemetery tileset, boss placeholder, door lock/unlock |
| `scenes/rooms/boss_arena.tscn` | Boss Arena scene tree |
| `godot/project.godot` | +RoomManager autoload, main scene = entry_hall.tscn |

## Coordinate Reference
- Viewport: 1920×1080
- TileMapLayer scale: 4.0 × 16px tiles = 64px/tile effective
- Floor collision y: 620 (matches test_room.tscn pattern)
- Row 10 tiles at y=640 ≈ aligns with floor collision

---

## Tasks

### Task 1: feature branch + plan commit

- [ ] Create branch and commit plan:
```bash
git -C /path/to/worktree checkout -b feature/ws-d-rooms
git add docs/superpowers/plans/2026-03-27-ws-d-rooms-design.md
git commit -m "docs: add rooms workstream implementation plan"
```

---

### Task 2: RoomManager autoload

**Files:**
- Create: `godot/scripts/systems/room_manager.gd`
- Modify: `godot/project.godot` (add autoload + update main scene)

- [ ] Write `room_manager.gd` — CanvasLayer fade overlay, transition_to(), fade_in(), get_spawn_point_name()
- [ ] Add `RoomManager="*res://scripts/systems/room_manager.gd"` to `[autoload]` in project.godot
- [ ] Change `run/main_scene` to `"res://scenes/rooms/entry_hall.tscn"`
- [ ] Commit

---

### Task 3: Ghost enemy

**Files:**
- Create: `godot/scripts/enemies/ghost.gd`
- Create: `godot/scenes/enemies/ghost.tscn`

- [ ] Write `ghost.gd` — CharacterBody2D, no gravity, IDLE/CHASE/HURT/DEAD states, contact damage
- [ ] Write `ghost.tscn` — 4-frame SpriteFrames from cemetery ghost PNGs, CapsuleShape2D
- [ ] Commit

---

### Task 4: Generic Pickup

**Files:**
- Create: `godot/scripts/items/pickup.gd`
- Create: `godot/scenes/items/pickup.tscn`

- [ ] Write `pickup.gd` — bob animation via sin(), body_entered → add_item or unlock_ability, queue_free
- [ ] Write `pickup.tscn` — Area2D root, Sprite2D (fireball1.png default), PointLight2D, CircleShape2D
- [ ] Commit

---

### Task 5: Save Point

**Files:**
- Create: `godot/scripts/items/save_point.gd`
- Create: `godot/scenes/items/save_point.tscn`

- [ ] Write `save_point.gd` — pulsing light, player proximity, interact action → SaveManager.save_game(0, data)
- [ ] Write `save_point.tscn` — Area2D, Sprite2D colored cyan, PointLight2D cyan
- [ ] Commit

---

### Task 6: Entry Hall

**Files:**
- Create: `godot/scripts/rooms/entry_hall.gd`
- Create: `godot/scenes/rooms/entry_hall.tscn`

Layout: Wide room (1920×620 playable). Floor y=620. Platform1 at y=448 x=320-832, Platform2 at y=320 x=832-1344. 3 skeletons on floor. Save point at x=120. Health potion on Platform1. Torch lights. Door right → Corridor/SpawnLeft. CanvasModulate dark blue-grey.

- [ ] Write `entry_hall.tscn` — node tree with all static bodies, spawn markers, door Area2D, enemy/pickup instances
- [ ] Write `entry_hall.gd` — runtime cemetery tileset, _build_room(), door signal → RoomManager.transition_to(), fade_in() call
- [ ] Commit

---

### Task 7: Corridor

**Files:**
- Create: `godot/scripts/rooms/corridor.gd`
- Create: `godot/scenes/rooms/corridor.tscn`

Layout: Same width but more vertical platforms (3 tiers). Church background. CanvasModulate very dark. 2 ghosts + 1 skeleton. Iron Sword on top platform. Doors: left → EntryHall/SpawnRight, right → PreBoss/SpawnLeft.

- [ ] Write `corridor.tscn`
- [ ] Write `corridor.gd` — runtime church tileset
- [ ] Commit

---

### Task 8: Pre-Boss Room

**Files:**
- Create: `godot/scripts/rooms/pre_boss.gd`
- Create: `godot/scenes/rooms/pre_boss.tscn`

Layout: Town background. Large open area. 2 skeletons. Fireball pickup (is_ability=true, item_id="fire_barrier"). Mana potion pickup. Save point center. Large door right → BossArena/SpawnLeft.

- [ ] Write `pre_boss.tscn`
- [ ] Write `pre_boss.gd` — runtime town tileset
- [ ] Commit

---

### Task 9: Boss Arena

**Files:**
- Create: `godot/scripts/rooms/boss_arena.gd`
- Create: `godot/scenes/rooms/boss_arena.tscn`

Layout: Wide flat room (3840px wide, camera scrolls). Cemetery background with red CanvasModulate. Door left starts locked. Boss placeholder (large skeleton with 20 HP). On boss death: unlock door, spawn equipment pickup. Red/purple PointLight2Ds.

- [ ] Write `boss_arena.tscn`
- [ ] Write `boss_arena.gd` — boss death → unlock door Area2D + spawn loot, runtime cemetery tileset
- [ ] Commit + push
