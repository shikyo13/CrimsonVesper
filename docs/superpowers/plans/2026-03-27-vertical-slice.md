# Crimson Vesper Vertical Slice — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the broken prototype into a polished vertical-slice demo: title → intro → 4 rooms → multi-phase boss → teaser ending.

**Architecture:** Godot 4.6, 8 autoload managers, player state machine with states as child nodes, runtime-generated tilesets per room, EnemyBase class for enemies, JSON-defined items. All game scripts under `godot/scripts/`, scenes under `godot/scenes/`, assets under `godot/assets/`.

**Tech Stack:** GDScript, Godot 4.6, GPUParticles2D, PointLight2D, CanvasModulate, AnimatedSprite2D, TileMapLayer with runtime TileSet generation.

**Design Spec:** `docs/superpowers/specs/2026-03-27-vertical-slice-design.md`

**Version Control:** Feature branch per phase. Meaningful commits after each task. Branch naming: `feature/phase-N-description`.

---

## File Map

### Files to Modify

| File | Responsibility | Changes |
|------|---------------|---------|
| `godot/scripts/ui/intro_cinematic.gd` | Intro cutscene | Fix GAME_SCENE constant |
| `godot/scripts/ui/title_screen.gd` | Title menu | Fix GAME_SCENE constant, wire Continue properly |
| `godot/scripts/systems/ability_manager.gd` | Ability tracking | Fix defaults: dash=true, fireball=false |
| `godot/scripts/systems/stats_manager.gd` | Player stats | Add level-up VFX signal, partial heal on level |
| `godot/scripts/systems/game_manager.gd` | Game state | Add GAME_OVER state handling |
| `godot/scripts/systems/room_manager.gd` | Room transitions | Add respawn support |
| `godot/scripts/player/player.gd` | Player controller | Add double-jump, death → game over flow |
| `godot/scripts/enemies/enemy_base.gd` | Base enemy | Add loot table support |
| `godot/scripts/enemies/boss_warden.gd` | Boss AI | Add intro sequence, polish phases |
| `godot/scripts/rooms/entry_hall.gd` | Room 1 | Polish enemy placement, transition zones |
| `godot/scripts/rooms/corridor.gd` | Room 2 | Add double-jump pickup, polish layout |
| `godot/scripts/rooms/pre_boss.gd` | Room 3 | Add fireball pickup, polish layout |
| `godot/scripts/rooms/boss_arena.gd` | Room 4 | Add boss intro, teaser ending, door lock |
| `godot/scripts/ui/hud.gd` | In-game HUD | Add boss HP bar, level-up flash |
| `godot/scripts/ui/pause_menu.gd` | Pause menu | Polish inventory/stats sub-screens |
| `godot/scripts/items/pickup.gd` | Item pickups | Add SFX, visual feedback |

### Files to Create

| File | Responsibility |
|------|---------------|
| `godot/scripts/ui/game_over_screen.gd` | Game over UI with retry/quit |
| `godot/scenes/ui/game_over_screen.tscn` | Game over scene |
| `godot/scripts/ui/boss_intro_overlay.gd` | Boss name title card |
| `godot/scenes/ui/boss_intro_overlay.tscn` | Boss intro scene |
| `godot/scripts/ui/teaser_ending.gd` | Post-boss cutscene |
| `godot/scenes/ui/teaser_ending.tscn` | Teaser ending scene |
| `godot/scripts/player/states/double_jump_state.gd` | Double-jump state |
| `godot/scripts/vfx/screen_shake.gd` | Camera shake utility |
| `godot/scripts/systems/combat_feel.gd` | Hit stop, hit flash, screen shake coordinator |
| `godot/scripts/systems/monster_respawn.gd` | Track killed enemies, respawn on room re-entry |

---

## Phase 1: Make It Work

**Branch:** `feature/phase-1-make-it-work`

### Task 1: Fix Game Routing

**Files:**
- Modify: `godot/scripts/ui/intro_cinematic.gd:5`
- Modify: `godot/scripts/ui/title_screen.gd:6`

- [ ] **Step 1: Create feature branch**

```bash
cd /Users/zero/Documents/Dev/CrimsonVesper/.claude/worktrees/thirsty-cori
git checkout -b feature/phase-1-make-it-work
```

- [ ] **Step 2: Fix intro_cinematic.gd routing**

In `godot/scripts/ui/intro_cinematic.gd`, change line 5 from:
```gdscript
const GAME_SCENE: String = "res://scenes/rooms/test_room.tscn"
```
to:
```gdscript
const GAME_SCENE: String = "res://scenes/rooms/entry_hall.tscn"
```

- [ ] **Step 3: Fix title_screen.gd routing**

In `godot/scripts/ui/title_screen.gd`, change line 6 from:
```gdscript
const GAME_SCENE:  String  = "res://scenes/rooms/test_room.tscn"
```
to:
```gdscript
const GAME_SCENE: String = "res://scenes/rooms/entry_hall.tscn"
```

- [ ] **Step 4: Verify — run game, click New Game, confirm entry_hall loads**

Run the game in Godot. Click "New Game". After the intro cinematic, the game should load the Entry Hall room (cemetery tileset, skeletons) instead of the boss fight.

Expected: Player appears in entry_hall with cemetery background, skeletons visible, no boss health bar.

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/ui/intro_cinematic.gd godot/scripts/ui/title_screen.gd
git commit -m "fix: route New Game to entry_hall instead of test_room"
```

---

### Task 2: Fix Ability Defaults

**Files:**
- Modify: `godot/scripts/systems/ability_manager.gd:15-25`

The spec says the player starts with melee attack + jump + dash. Fireball is picked up in pre_boss. Currently both dash AND fireball default to `true`.

- [ ] **Step 1: Update ability defaults**

In `godot/scripts/systems/ability_manager.gd`, change the abilities dictionary (lines 15-25) so fireball starts as `false`:

```gdscript
var _abilities: Dictionary = {
	"dash": true,
	"double_jump": false,
	"wall_climb": false,
	"grapple": false,
	"shadow_dash": false,
	"fireball": false,
	"fire_barrier": false,
	"levitate": false,
	"bat_form": false,
}
```

- [ ] **Step 2: Verify — run game, confirm C (spell) does nothing at start**

Run the game, start a new game, press C in the entry hall. Nothing should happen since fireball is not unlocked.

- [ ] **Step 3: Commit**

```bash
git add godot/scripts/systems/ability_manager.gd
git commit -m "fix: fireball starts locked, unlocked via pickup in pre_boss"
```

---

### Task 3: Verify Room Visuals — Entry Hall

**Files:**
- Modify: `godot/scripts/rooms/entry_hall.gd` (if fixes needed)
- Modify: `godot/scenes/rooms/entry_hall.tscn` (if CanvasModulate needs adjustment)

- [ ] **Step 1: Run entry_hall directly in Godot editor**

In the Godot editor, open `scenes/rooms/entry_hall.tscn` and press F6 (Run Current Scene). Take a screenshot.

Check:
- Player sprite is visible and properly lit (not a silhouette)
- Cemetery tileset tiles are rendered (not gray blocks)
- Parallax background is visible
- Skeletons are visible with proper sprites
- Torch lights create warm orange pools

- [ ] **Step 2: Fix any CanvasModulate or lighting issues found**

The entry_hall CanvasModulate is `Color(0.45, 0.45, 0.6)` which should be visible. If sprites are still too dark, increase to `Color(0.55, 0.55, 0.7)`.

If the tileset isn't rendering, check `_create_tileset()` — the cemetery_tileset.png path must be correct at `res://assets/tilesets/cemetery_tileset.png`.

- [ ] **Step 3: Verify sprite scale**

Player should be approximately 2-3 tiles tall. If the player looks tiny or huge relative to the tile grid, adjust the player scene's scale or the tile size in the room script.

Check the player scene: `scenes/player/player.tscn` — CollisionShape2D is CapsuleShape2D with radius=16, height=48. At 32px tiles, the player is ~2 tiles tall — this should be correct.

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: entry_hall visual rendering — lighting and tileset verified"
```

---

### Task 4: Verify Room Visuals — Corridor

**Files:**
- Modify: `godot/scripts/rooms/corridor.gd` (if fixes needed)
- Modify: `godot/scenes/rooms/corridor.tscn` (if fixes needed)

- [ ] **Step 1: Run corridor directly (F6), take screenshot**

Check:
- Church tileset renders properly
- Blue/purple atmospheric lighting
- Ghosts visible with proper sprites
- Vertical platforms reachable
- Player visible against darker background

- [ ] **Step 2: Fix any issues found**

Read CanvasModulate color from corridor.tscn. If too dark (below 0.3 on any channel), increase. The corridor should feel darker than entry_hall but still readable.

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: corridor visual rendering verified and fixed"
```

---

### Task 5: Verify Room Visuals — Pre-Boss

**Files:**
- Modify: `godot/scripts/rooms/pre_boss.gd` (if fixes needed)
- Modify: `godot/scenes/rooms/pre_boss.tscn` (if fixes needed)

- [ ] **Step 1: Run pre_boss directly (F6), take screenshot**

Check:
- Town tileset renders
- Save point is visible and pulsing
- Warm lighting
- Fireball and mana pickups visible and bobbing
- Safe room feel — no enemies

- [ ] **Step 2: Fix any issues found**

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: pre_boss visual rendering verified and fixed"
```

---

### Task 6: Verify Room Visuals — Boss Arena

**Files:**
- Modify: `godot/scripts/rooms/boss_arena.gd` (if fixes needed)
- Modify: `godot/scenes/rooms/boss_arena.tscn` (if fixes needed)

- [ ] **Step 1: Run boss_arena directly (F6), take screenshot**

Check:
- Boss Warden sprite visible (not a silhouette)
- Player sprite visible against dark-red ambient
- Arena floor tiles rendered
- Boss HP bar at top
- Red/purple dramatic lighting

The CanvasModulate is `Color(0.3, 0.18, 0.22)` — darker and redder. If sprites are invisible, raise to `Color(0.4, 0.25, 0.3)`.

- [ ] **Step 2: Fix any issues found**

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: boss_arena visual rendering verified and fixed"
```

---

### Task 7: Wire Room-to-Room Transitions

**Files:**
- Modify: `godot/scripts/rooms/entry_hall.gd`
- Modify: `godot/scripts/rooms/corridor.gd`
- Modify: `godot/scripts/rooms/pre_boss.gd`
- Modify: `godot/scripts/rooms/boss_arena.gd`

Each room needs door Area2D nodes that trigger `RoomManager.transition_to()` on player contact. Verify the full chain works:

entry_hall (right exit) → corridor (SpawnLeft)
corridor (left exit) → entry_hall (SpawnRight)
corridor (right exit) → pre_boss (SpawnLeft)
pre_boss (left exit) → corridor (SpawnRight)
pre_boss (right exit) → boss_arena (SpawnLeft)
boss_arena (left exit, after boss defeat) → pre_boss (SpawnRight)

- [ ] **Step 1: Read each room script to verify door/transition setup**

Each room script should have an `_on_door_right_body_entered` or similar function that calls:
```gdscript
RoomManager.transition_to("res://scenes/rooms/next_room.tscn", "SpawnLeft")
```

Check that:
1. Door Area2D nodes exist in each room's `_build_room()` or in the .tscn
2. The `body_entered` signal is connected
3. The target room path and spawn point name are correct
4. Each room has `SpawnLeft` and `SpawnRight` Node2D children for positioning

- [ ] **Step 2: Fix any missing or broken transitions**

If a room is missing door zones, add them. Each door zone is:
```gdscript
var door = Area2D.new()
door.name = "DoorRight"
var door_shape = CollisionShape2D.new()
var rect = RectangleShape2D.new()
rect.size = Vector2(32, 128)
door_shape.shape = rect
door.add_child(door_shape)
door.position = Vector2(room_width_px - 16, floor_y - 64)
door.body_entered.connect(_on_door_right_entered)
add_child(door)

func _on_door_right_entered(body: Node2D) -> void:
    if body is Player:
        RoomManager.transition_to("res://scenes/rooms/next_room.tscn", "SpawnLeft")
```

- [ ] **Step 3: Test the full chain — play through all 4 rooms**

Run the game from title screen. Play through:
1. Entry Hall → walk to right edge → should transition to Corridor
2. Corridor → walk to right edge → should transition to Pre-Boss
3. Pre-Boss → walk to right edge → should transition to Boss Arena
4. Also test going backward: Corridor → left edge → Entry Hall

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire room-to-room transitions through all 4 rooms"
```

---

### Task 8: Game Over Screen

**Files:**
- Create: `godot/scripts/ui/game_over_screen.gd`
- Create: `godot/scenes/ui/game_over_screen.tscn`
- Modify: `godot/scripts/player/player.gd` (change `_die()`)
- Modify: `godot/scripts/systems/game_manager.gd` (add GAME_OVER handling)

- [ ] **Step 1: Create game_over_screen.gd**

```gdscript
extends CanvasLayer
## Game Over screen — shown when player HP reaches 0.

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"

@onready var retry_button: Button = %RetryButton
@onready var quit_button: Button = %QuitButton
@onready var anim_player: AnimationPlayer = %AnimPlayer

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry)
	quit_button.pressed.connect(_on_quit)
	retry_button.grab_focus()
	if anim_player:
		anim_player.play("fade_in")

func _on_retry() -> void:
	get_tree().paused = false
	var room_path: String = SaveManager.get_last_save_room()
	if room_path.is_empty():
		room_path = "res://scenes/rooms/entry_hall.tscn"
	StatsManager.full_heal()
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.go_to_scene(room_path)
	queue_free()

func _on_quit() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager.go_to_scene(TITLE_SCENE)
	queue_free()
```

- [ ] **Step 2: Create game_over_screen.tscn**

Build the scene in code or via Godot editor. Structure:

```
GameOverScreen (CanvasLayer, layer=50)
├── ColorRect (full screen, Color(0, 0, 0, 0.75))
├── VBoxContainer (centered)
│   ├── YouDiedLabel ("YOU DIED", font_size=48, red color)
│   ├── Spacer (32px)
│   ├── RetryButton ("Retry from Save", unique_name=%RetryButton)
│   └── QuitButton ("Quit to Title", unique_name=%QuitButton)
└── AnimPlayer (unique_name=%AnimPlayer, fade_in animation)
```

- [ ] **Step 3: Add get_last_save_room() to SaveManager**

In `godot/scripts/systems/save_manager.gd`, add:

```gdscript
func get_last_save_room() -> String:
	for slot in range(MAX_SLOTS):
		if has_save(slot):
			var path = _slot_path(slot)
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var data = JSON.parse_string(file.get_as_text())
				if data and data.has("current_room"):
					return data["current_room"]
	return ""
```

- [ ] **Step 4: Update player._die() to show game over screen**

In `godot/scripts/player/player.gd`, replace the `_die()` function (currently respawns in-place) with:

```gdscript
func _die() -> void:
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	var game_over_scene = preload("res://scenes/ui/game_over_screen.tscn")
	var game_over = game_over_scene.instantiate()
	get_tree().root.add_child(game_over)
```

- [ ] **Step 5: Verify — take damage until death, confirm game over screen appears**

Run the game, let enemies hit the player until HP reaches 0. The game over screen should appear with "YOU DIED", "Retry from Save", and "Quit to Title" buttons.

Test "Retry from Save" — should reload at entry_hall (no save exists yet).
Test "Quit to Title" — should return to title screen.

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/ui/game_over_screen.gd godot/scenes/ui/game_over_screen.tscn \
       godot/scripts/player/player.gd godot/scripts/systems/save_manager.gd \
       godot/scripts/systems/game_manager.gd
git commit -m "feat: add game over screen with retry-from-save and quit-to-title"
```

---

### Task 9: End-to-End Playthrough Verification

- [ ] **Step 1: Full playthrough test**

Run the game from the title screen. Play through the entire flow:
1. Title → New Game → Intro cinematic (4 slides)
2. Entry Hall: player visible, skeletons attackable, walk right to exit
3. Corridor: ghosts visible, platforms climbable, walk right to exit
4. Pre-Boss: save point works (press E), pickups visible, walk right to exit
5. Boss Arena: boss visible, attacks work, player can fight
6. Die to boss → game over screen → retry → respawns at save point (pre_boss)
7. Return to boss, defeat boss
8. Back to title or end state

Take screenshots at each stage. Fix any remaining issues.

- [ ] **Step 2: Commit any final fixes and merge**

```bash
git add -A
git commit -m "fix: end-to-end playthrough fixes"
```

---

## Phase 2: Game Systems

**Branch:** `feature/phase-2-game-systems`

### Task 10: Create Phase 2 Branch

- [ ] **Step 1: Create branch from phase 1**

```bash
git checkout -b feature/phase-2-game-systems
```

---

### Task 11: Level-Up Visual/Audio Feedback

**Files:**
- Modify: `godot/scripts/systems/stats_manager.gd` (`_do_level_up()` at line 57)
- Modify: `godot/scripts/ui/hud.gd`

StatsManager already has `level_up` signal and `_do_level_up()` grants +5 max_hp, +3 max_mp, +1 all stats. Need to add: partial heal on level up and visual/audio cue.

- [ ] **Step 1: Add partial heal to _do_level_up()**

In `godot/scripts/systems/stats_manager.gd`, in `_do_level_up()` (line 57), after the stat increases, add:

```gdscript
	# Heal 50% of max HP on level up
	var heal_amount = int(max_hp * 0.5)
	heal(heal_amount)
	restore_mp(int(max_mp * 0.5))
```

- [ ] **Step 2: Add level-up flash to HUD**

In `godot/scripts/ui/hud.gd`, connect to `StatsManager.level_up` signal in `_ready()` and add:

```gdscript
func _on_level_up(new_level: int) -> void:
	# Flash the HUD gold briefly
	var flash = ColorRect.new()
	flash.color = Color(1.0, 0.85, 0.2, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.8)
	tween.tween_callback(flash.queue_free)
	AudioManager.play_ui("menu_confirm")  # Reuse as level-up chime for now
```

- [ ] **Step 3: Verify — kill enough enemies to level up, confirm flash + heal**

Run game, kill skeletons repeatedly. At 150 XP (roughly 30 skeletons at 5 XP each, or fewer with ghosts at 15 XP), a level up should trigger. Confirm gold flash and HP/MP restore.

- [ ] **Step 4: Commit**

```bash
git add godot/scripts/systems/stats_manager.gd godot/scripts/ui/hud.gd
git commit -m "feat: level-up heals 50% HP/MP and flashes HUD gold"
```

---

### Task 12: Enemy Loot Tables

**Files:**
- Modify: `godot/scripts/enemies/enemy_base.gd` (`drop_loot()` at line 57)
- Modify: `godot/scripts/enemies/skeleton.gd`
- Modify: `godot/scripts/enemies/ghost.gd`
- Modify: `godot/scripts/enemies/boss_warden.gd`

- [ ] **Step 1: Implement drop_loot() in EnemyBase**

In `godot/scripts/enemies/enemy_base.gd`, replace the empty `drop_loot()` with:

```gdscript
@export var loot_table: Array[Dictionary] = []
# Each entry: {"item_id": String, "chance": float (0.0-1.0)}

func drop_loot() -> void:
	for entry in loot_table:
		if randf() <= entry.get("chance", 0.0):
			var pickup_scene = preload("res://scenes/items/pickup.tscn")
			var pickup = pickup_scene.instantiate()
			pickup.item_id = entry["item_id"]
			pickup.global_position = global_position + Vector2(0, -16)
			get_tree().current_scene.add_child(pickup)
			return  # Only drop one item
```

- [ ] **Step 2: Call drop_loot() in die()**

In `enemy_base.gd`, in `die()` (line 41), add `drop_loot()` call before `_on_die()`:

```gdscript
func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	StatsManager.add_xp(xp_reward)
	drop_loot()
	enemy_died.emit(self)
	_on_die()
```

- [ ] **Step 3: Set loot tables for each enemy type**

For skeleton, in `_ready()` or as export defaults:
```gdscript
func _ready() -> void:
	super._ready()
	loot_table = [
		{"item_id": "health_potion", "chance": 0.2},
	]
```

For ghost (doesn't extend EnemyBase — add inline loot logic):
```gdscript
func _die() -> void:
	# Add loot drop before death
	if randf() <= 0.15:
		var pickup_scene = preload("res://scenes/items/pickup.tscn")
		var pickup = pickup_scene.instantiate()
		pickup.item_id = "mana_potion"
		pickup.global_position = global_position
		get_tree().current_scene.add_child(pickup)
	# ... existing death logic
```

For boss_warden, in `_die()`:
```gdscript
# Boss always drops a weapon
var pickup_scene = preload("res://scenes/items/pickup.tscn")
var pickup = pickup_scene.instantiate()
pickup.item_id = "iron_sword"
pickup.global_position = global_position + Vector2(0, -32)
get_tree().current_scene.add_child(pickup)
```

- [ ] **Step 4: Verify — kill enemies, confirm loot drops**

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/enemies/enemy_base.gd godot/scripts/enemies/skeleton.gd \
       godot/scripts/enemies/ghost.gd godot/scripts/enemies/boss_warden.gd
git commit -m "feat: enemy loot tables — skeletons drop potions, ghosts drop mana, boss drops iron sword"
```

---

### Task 13: Double-Jump Ability

**Files:**
- Create: `godot/scripts/player/states/double_jump_state.gd`
- Modify: `godot/scripts/player/states/jump_state.gd`
- Modify: `godot/scripts/player/states/fall_state.gd`
- Modify: `godot/scripts/player/player.gd`
- Modify: `godot/scenes/player/player.tscn` (add DoubleJumpState node)

- [ ] **Step 1: Add double-jump tracking to player.gd**

In `godot/scripts/player/player.gd`, add to runtime state variables (around line 26):

```gdscript
var has_double_jumped: bool = false
```

Reset it when landing. In `_physics_process`, after `move_and_slide()` or in the idle/run states when `is_on_floor()` is true:

```gdscript
if is_on_floor():
	has_double_jumped = false
```

- [ ] **Step 2: Add double-jump input to jump_state.gd and fall_state.gd**

In both `jump_state.gd` and `fall_state.gd`, in the `handle_input()` or `update()` method, add:

```gdscript
if Input.is_action_just_pressed("jump") and not player.has_double_jumped \
		and AbilityManager.has_ability("double_jump"):
	player.has_double_jumped = true
	player.velocity.y = -player.jump_force * 0.85  # Slightly weaker second jump
	player.play_anim("jump")
	# Stay in jump state or transition to it
	player.state_machine.change_state("jump")
```

- [ ] **Step 3: Add DoubleJumpState node to player.tscn**

This is optional — the double jump can reuse the existing JumpState by re-entering it. If a separate state is preferred, create `double_jump_state.gd`:

```gdscript
extends "res://scripts/player/state.gd"
# Reuses jump state logic, just re-entered from air

func enter() -> void:
	player.velocity.y = -player.jump_force * 0.85
	player.play_anim("jump")

func update(delta: float) -> void:
	player.apply_gravity(delta)
	var dir = Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0:
		player.facing_dir = dir
		player.animated_sprite.flip_h = dir < 0
	player.move_and_slide()
	if player.velocity.y > 0:
		player.state_machine.change_state("fall")
```

Add it as a child of StateMachine in player.tscn.

- [ ] **Step 4: Verify — unlock double_jump, test in corridor**

For testing, temporarily set `"double_jump": true` in ability_manager.gd, run the game, and verify double-jump works mid-air. Then revert to `false`.

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/player/player.gd godot/scripts/player/states/jump_state.gd \
       godot/scripts/player/states/fall_state.gd godot/scenes/player/player.tscn
git commit -m "feat: double-jump ability — second jump at 85% force when unlocked"
```

---

### Task 14: Corridor Double-Jump Pickup

**Files:**
- Modify: `godot/scripts/rooms/corridor.gd`

- [ ] **Step 1: Replace iron_sword pickup with double-jump ability pickup**

In `godot/scripts/rooms/corridor.gd`, find where the Iron Sword pickup is placed (upper platform area). Change it to a double-jump ability pickup:

```gdscript
var pickup_scene = preload("res://scenes/items/pickup.tscn")
var dj_pickup = pickup_scene.instantiate()
dj_pickup.item_id = "double_jump"
dj_pickup.is_ability = true
dj_pickup.position = Vector2(480, 256)  # On the upper platform
add_child(dj_pickup)
```

- [ ] **Step 2: Verify — play through corridor, collect double-jump, test it**

- [ ] **Step 3: Commit**

```bash
git add godot/scripts/rooms/corridor.gd
git commit -m "feat: corridor gives double-jump pickup on upper platform"
```

---

### Task 15: Pre-Boss Fireball Pickup

**Files:**
- Modify: `godot/scripts/rooms/pre_boss.gd`

- [ ] **Step 1: Verify fireball pickup exists and is configured correctly**

The pre_boss room should already have a fireball ability pickup. Read the script and verify:
- `is_ability = true`
- `item_id = "fireball"`
- Pickup calls `AbilityManager.unlock_ability("fireball")`

If the fireball pickup is missing or misconfigured, add it:

```gdscript
var spell_pickup = pickup_scene.instantiate()
spell_pickup.item_id = "fireball"
spell_pickup.is_ability = true
spell_pickup.position = Vector2(640, floor_y - 48)
add_child(spell_pickup)
```

- [ ] **Step 2: Verify — collect fireball in pre_boss, press C, confirm it fires**

- [ ] **Step 3: Commit**

```bash
git add godot/scripts/rooms/pre_boss.gd
git commit -m "fix: verify fireball pickup in pre_boss room"
```

---

### Task 16: Inventory & Stats Menu Polish

**Files:**
- Modify: `godot/scripts/ui/pause_menu.gd`

The pause menu already has inventory and stats sub-panels. Polish them to show:
- Equipment slots with item names
- Bag contents with quantities
- All stats with labels
- EXP bar and level

- [ ] **Step 1: Read current pause_menu.gd to assess state**

Read the full `_populate_inventory()` and `_populate_stats()` functions. Identify what's missing vs spec requirements:
- Inventory Screen: grid of items, equipment slots, stat comparison on hover
- Stats Screen: level, EXP bar, all stats, play time

- [ ] **Step 2: Polish inventory panel**

Update `_populate_inventory()` to clearly show:
```gdscript
func _populate_inventory() -> void:
	# Clear existing
	for child in inventory_container.get_children():
		child.queue_free()

	# Equipment section
	var equip_header = Label.new()
	equip_header.text = "— EQUIPMENT —"
	equip_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_container.add_child(equip_header)

	var slot_names = ["Weapon", "Armor", "Accessory 1", "Accessory 2"]
	for i in range(4):
		var slot_label = Label.new()
		var item_id = InventoryManager.get_equipped(i)
		var item_name = "Empty"
		if not item_id.is_empty():
			var item_data = ItemData.get_item(item_id)
			item_name = item_data.get("name", item_id)
		slot_label.text = "%s: %s" % [slot_names[i], item_name]
		inventory_container.add_child(slot_label)

	# Bag section
	var bag_header = Label.new()
	bag_header.text = "\n— ITEMS —"
	bag_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_container.add_child(bag_header)

	var bag = InventoryManager.get_bag()
	if bag.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No items"
		inventory_container.add_child(empty_label)
	else:
		for entry in bag:
			var item_data = ItemData.get_item(entry["item_id"])
			var item_label = Label.new()
			item_label.text = "%s x%d" % [item_data.get("name", entry["item_id"]), entry["quantity"]]
			inventory_container.add_child(item_label)
```

- [ ] **Step 3: Polish stats panel**

Update `_populate_stats()`:
```gdscript
func _populate_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()

	var stats = StatsManager.get_all_stats()
	var lines = [
		"Level: %d" % stats.get("level", 1),
		"EXP: %d / %d" % [stats.get("xp", 0), stats.get("xp_to_next", 150)],
		"",
		"HP: %d / %d" % [stats.get("hp", 0), stats.get("max_hp", 0)],
		"MP: %d / %d" % [stats.get("mp", 0), stats.get("max_mp", 0)],
		"",
		"STR: %d" % StatsManager.get_strength(),
		"DEF: %d" % StatsManager.get_defense(),
		"INT: %d" % StatsManager.get_intellect(),
		"LCK: %d" % StatsManager.get_luck(),
	]
	for line in lines:
		var label = Label.new()
		label.text = line
		stats_container.add_child(label)
```

- [ ] **Step 4: Verify — pause game, check inventory and stats screens**

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/ui/pause_menu.gd
git commit -m "feat: polish pause menu inventory and stats sub-screens"
```

---

### Task 17: Save/Load Flow Verification

**Files:**
- Modify: `godot/scripts/items/save_point.gd` (if needed)
- Modify: `godot/scripts/ui/title_screen.gd` (Continue button)

- [ ] **Step 1: Test save flow**

Run game → reach pre_boss → interact with save point → confirm save succeeds.

Check: Does `SaveManager.save_game(0)` write a JSON file to `user://saves/save_slot_0.json`?

- [ ] **Step 2: Test load flow**

Quit to title → click Continue → confirm it loads at pre_boss room with correct stats.

Currently the Continue button in `title_screen.gd` loads from the first valid save slot. Verify this works after fixing GAME_SCENE.

- [ ] **Step 3: Test death → retry flow**

Die to boss → Game Over → "Retry from Save" → confirm loads at pre_boss save point.

- [ ] **Step 4: Fix any issues and commit**

```bash
git add -A
git commit -m "fix: save/load flow verified — save point, continue, retry all working"
```

---

## Phase 3: Content & Combat

**Branch:** `feature/phase-3-content-combat`

### Task 18: Create Phase 3 Branch

- [ ] **Step 1: Create branch**

```bash
git checkout -b feature/phase-3-content-combat
```

---

### Task 19: Combat Feel — Screen Shake, Hit Stop, Hit Flash

**Files:**
- Create: `godot/scripts/systems/combat_feel.gd`
- Modify: `godot/scripts/player/player.gd` (screen_shake already exists at line 143)
- Modify: `godot/scripts/enemies/enemy_base.gd` (add hit flash)
- Modify: `godot/scripts/enemies/ghost.gd` (add hit flash)

- [ ] **Step 1: Implement hit flash on enemy_base.gd**

In `enemy_base.gd`, add a hit flash method that all enemies can use:

```gdscript
func flash_white(duration: float = 0.1) -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = _white_flash_shader()
	sprite.material.set_shader_parameter("flash_amount", 1.0)
	var tween = create_tween()
	tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, duration)
	tween.tween_callback(func(): sprite.material = null)

static func _white_flash_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = mix(tex, vec4(1.0, 1.0, 1.0, tex.a), flash_amount);
}
"""
	return shader
```

Call `flash_white()` in `take_damage()`.

- [ ] **Step 2: Add hit stop to player.gd**

The player already has `trigger_hitstop(duration)` at line 136. Verify it pauses the game tree briefly:

```gdscript
func trigger_hitstop(duration: float = 0.05) -> void:
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	get_tree().paused = false
```

Call `trigger_hitstop(0.05)` when player's attack connects with an enemy.

- [ ] **Step 3: Add screen shake tuning**

Verify `screen_shake()` in player.gd (line 143). Should shake the Camera2D:

```gdscript
func screen_shake(strength: float = 3.0, duration: float = 0.1) -> void:
	if not camera:
		return
	var tween = create_tween()
	for i in range(int(duration / 0.02)):
		tween.tween_property(camera, "offset",
			Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.02)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.02)
```

Add calls:
- Small shake on regular enemy hit: `screen_shake(2.0, 0.08)`
- Medium on boss hit: `screen_shake(4.0, 0.12)`
- Large on boss phase transition: `screen_shake(8.0, 0.3)`

- [ ] **Step 4: Add i-frames sprite flicker**

In `player.gd`, when invincible, make sprite flicker in `_physics_process`:

```gdscript
if invincible:
	animated_sprite.visible = fmod(iframes_timer * 20.0, 2.0) > 1.0
else:
	animated_sprite.visible = true
```

- [ ] **Step 5: Verify — attack enemies, confirm flash + shake + hitstop**

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/enemies/enemy_base.gd godot/scripts/player/player.gd \
       godot/scripts/enemies/ghost.gd
git commit -m "feat: combat feel — hit flash, screen shake, hit stop, i-frame flicker"
```

---

### Task 20: Monster Respawn System

**Files:**
- Modify: `godot/scripts/systems/room_manager.gd`

When the player re-enters a room, basic enemies respawn but unique encounters do not.

- [ ] **Step 1: Add respawn tracking to RoomManager**

In `godot/scripts/systems/room_manager.gd`, add:

```gdscript
# Unique encounters that should NOT respawn (e.g., boss)
var _unique_kills: Dictionary = {}  # room_id -> [enemy_name, ...]

func register_unique_kill(room_id: String, enemy_name: String) -> void:
	if not _unique_kills.has(room_id):
		_unique_kills[room_id] = []
	_unique_kills[room_id].append(enemy_name)

func is_unique_killed(room_id: String, enemy_name: String) -> bool:
	return _unique_kills.has(room_id) and enemy_name in _unique_kills[room_id]
```

Regular enemies respawn automatically because rooms rebuild their `_build_room()` on each load. Unique encounters (boss) check `is_unique_killed()` before spawning.

- [ ] **Step 2: Mark boss as unique in boss_arena.gd**

In `godot/scripts/rooms/boss_arena.gd`, when the boss dies:

```gdscript
func _on_boss_defeated() -> void:
	RoomManager.register_unique_kill("boss_arena", "BossWarden")
	# ... existing victory logic
```

And when spawning the boss, check:

```gdscript
if not RoomManager.is_unique_killed("boss_arena", "BossWarden"):
	_spawn_boss()
```

- [ ] **Step 3: Verify — kill skeletons, leave and re-enter entry_hall, confirm they respawn. Kill boss, leave and re-enter boss_arena, confirm boss does NOT respawn.**

- [ ] **Step 4: Commit**

```bash
git add godot/scripts/systems/room_manager.gd godot/scripts/rooms/boss_arena.gd
git commit -m "feat: monster respawn — basic enemies respawn on re-entry, unique kills persist"
```

---

### Task 21: Boss Intro Sequence

**Files:**
- Create: `godot/scripts/ui/boss_intro_overlay.gd`
- Create: `godot/scenes/ui/boss_intro_overlay.tscn`
- Modify: `godot/scripts/rooms/boss_arena.gd`

- [ ] **Step 1: Create boss_intro_overlay.gd**

```gdscript
extends CanvasLayer
## Displays boss name title card on arena entry.

signal intro_finished

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var name_label = Label.new()
	name_label.text = "THE CRIMSON WARDEN"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(Control.PRESET_CENTER)
	name_label.add_theme_font_size_override("font_size", 42)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	name_label.modulate.a = 0.0
	add_child(name_label)

	# Animate: fade in name, hold, fade out, signal done
	var tween = create_tween()
	tween.tween_property(name_label, "modulate:a", 1.0, 0.8)
	tween.tween_interval(1.5)
	tween.tween_property(name_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		intro_finished.emit()
		queue_free()
	)
```

- [ ] **Step 2: Wire boss intro into boss_arena.gd**

In `godot/scripts/rooms/boss_arena.gd`, when the room loads and the boss is alive:

```gdscript
func _start_boss_intro() -> void:
	# Pause player input
	get_tree().paused = true

	var intro = preload("res://scenes/ui/boss_intro_overlay.tscn").instantiate()
	get_tree().root.add_child(intro)
	intro.intro_finished.connect(func():
		get_tree().paused = false
		# Boss starts fighting
	)
```

Call `_start_boss_intro()` after the room finishes building and the door locks behind the player.

- [ ] **Step 3: Create boss_intro_overlay.tscn**

Minimal scene — just the CanvasLayer root with the script attached. The script builds UI dynamically.

- [ ] **Step 4: Verify — enter boss arena, confirm title card appears and fades before fight starts**

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/ui/boss_intro_overlay.gd godot/scenes/ui/boss_intro_overlay.tscn \
       godot/scripts/rooms/boss_arena.gd
git commit -m "feat: boss intro sequence — name title card with fade animation"
```

---

### Task 22: Boss Phase Transition Polish

**Files:**
- Modify: `godot/scripts/enemies/boss_warden.gd`

The boss already has 3 phases with PHASE_DATA. Polish the transitions:

- [ ] **Step 1: Add screen shake on phase transition**

In `boss_warden.gd`, in `_enter_phase()` (line 289), add:

```gdscript
func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	_apply_phase_data()
	state = BossState.TRANSITION
	transition_timer = 1.5

	# Screen shake
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_node.screen_shake(8.0, 0.3)

	# Flash red
	flash_white(0.3)  # Reuse hit flash but could be red

	# Phase 3: summon minions
	if new_phase == 3 and not minions_summoned:
		_start_summon()
		minions_summoned = true

	phase_changed.emit(new_phase)
```

- [ ] **Step 2: Add music intensity change on phase transitions**

```gdscript
	# In _enter_phase:
	if new_phase == 2:
		AudioManager.play_music("boss_battle")  # Could crossfade to intense version
	elif new_phase == 3:
		AudioManager.play_music("boss_battle")  # Intensify further if alternate track exists
```

- [ ] **Step 3: Verify — fight boss, confirm phase transitions have shake + flash**

- [ ] **Step 4: Commit**

```bash
git add godot/scripts/enemies/boss_warden.gd
git commit -m "feat: boss phase transitions — screen shake, flash, music intensity"
```

---

### Task 23: Teaser Ending Cutscene

**Files:**
- Create: `godot/scripts/ui/teaser_ending.gd`
- Create: `godot/scenes/ui/teaser_ending.tscn`
- Modify: `godot/scripts/rooms/boss_arena.gd`

- [ ] **Step 1: Create teaser_ending.gd**

```gdscript
extends CanvasLayer
## Post-boss teaser ending — camera pans, text overlay, return to title.

const TITLE_SCENE = "res://scenes/ui/title_screen.tscn"

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var text1 = Label.new()
	text1.text = "The cathedral's depths beckon..."
	text1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text1.set_anchors_preset(Control.PRESET_CENTER)
	text1.add_theme_font_size_override("font_size", 28)
	text1.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	text1.modulate.a = 0.0
	add_child(text1)

	var text2 = Label.new()
	text2.text = "To be continued..."
	text2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text2.set_anchors_preset(Control.PRESET_CENTER)
	text2.position.y += 80
	text2.add_theme_font_size_override("font_size", 22)
	text2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	text2.modulate.a = 0.0
	add_child(text2)

	var tween = create_tween()
	# Fade to black
	tween.tween_property(bg, "color:a", 1.0, 1.5)
	tween.tween_interval(1.0)
	# Show teaser text
	tween.tween_property(text1, "modulate:a", 1.0, 1.2)
	tween.tween_interval(2.5)
	tween.tween_property(text1, "modulate:a", 0.0, 0.8)
	tween.tween_interval(0.5)
	# Show "To be continued"
	tween.tween_property(text2, "modulate:a", 1.0, 1.0)
	tween.tween_interval(3.0)
	tween.tween_property(text2, "modulate:a", 0.0, 1.0)
	tween.tween_interval(0.5)
	# Return to title
	tween.tween_callback(func():
		get_tree().paused = false
		GameManager.change_state(GameManager.GameState.MENU)
		GameManager.go_to_scene(TITLE_SCENE)
		queue_free()
	)
```

- [ ] **Step 2: Create teaser_ending.tscn**

Minimal scene — CanvasLayer root with script attached.

- [ ] **Step 3: Wire into boss_arena.gd after boss defeat**

In `boss_arena.gd`, after the boss dies and loot drops:

```gdscript
func _on_boss_defeated() -> void:
	RoomManager.register_unique_kill("boss_arena", "BossWarden")
	# Wait for loot pickup or timeout, then show teaser
	await get_tree().create_timer(3.0).timeout
	var teaser = preload("res://scenes/ui/teaser_ending.tscn").instantiate()
	get_tree().root.add_child(teaser)
```

- [ ] **Step 4: Verify — defeat boss, confirm teaser ending plays and returns to title**

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/ui/teaser_ending.gd godot/scenes/ui/teaser_ending.tscn \
       godot/scripts/rooms/boss_arena.gd
git commit -m "feat: teaser ending — post-boss cutscene with 'To be continued' text"
```

---

### Task 24: Room Content Polish — Enemy Placement & Pacing

**Files:**
- Modify: `godot/scripts/rooms/entry_hall.gd`
- Modify: `godot/scripts/rooms/corridor.gd`
- Modify: `godot/scripts/rooms/pre_boss.gd`

- [ ] **Step 1: Entry Hall — verify 3 skeletons placed for teaching**

Read `entry_hall.gd`, verify enemy placement:
- 1st skeleton: alone, near start — player learns to fight one enemy
- 2nd + 3rd skeleton: paired, further right — teaches crowd management
- Spacing gives the player room to approach each encounter

Adjust positions if needed. Each skeleton should be on the floor at the correct Y position.

- [ ] **Step 2: Corridor — verify ghost placement and double-jump pickup**

Read `corridor.gd`, verify:
- Ghosts placed on vertical platforms (teaching aerial combat)
- Double-jump pickup on upper platform (reachable after getting used to platforming)
- A skeleton or hell_gato on the ground level for variety

- [ ] **Step 3: Pre-Boss — verify save point prominence and pickup placement**

Read `pre_boss.gd`, verify:
- Save point is visually prominent (center of room, well-lit)
- Fireball pickup is clearly visible
- Mana potion nearby
- Optional health potion
- No enemies — safe room

- [ ] **Step 4: Adjust any enemy/pickup positions for better pacing**

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/rooms/entry_hall.gd godot/scripts/rooms/corridor.gd \
       godot/scripts/rooms/pre_boss.gd
git commit -m "fix: room content polish — enemy placement and pickup positioning"
```

---

## Phase 4: Lighting & Visual Art Pass

**Branch:** `feature/phase-4-lighting`

### Task 25: Create Phase 4 Branch

- [ ] **Step 1: Create branch**

```bash
git checkout -b feature/phase-4-lighting
```

---

### Task 26: Entry Hall Lighting — Moonlight + Torch Pools

**Files:**
- Modify: `godot/scripts/rooms/entry_hall.gd`
- Modify: `godot/scenes/rooms/entry_hall.tscn`

- [ ] **Step 1: Adjust CanvasModulate for moonlit outdoor feel**

Set CanvasModulate to a cool blue-tinted darkness that still lets sprites be readable:
```gdscript
canvas_mod.color = Color(0.25, 0.28, 0.45)  # Cool blue moonlight ambient
```

- [ ] **Step 2: Add moonlight from above**

Add a large, soft PointLight2D at the top-center of the room:
```gdscript
var moonlight = PointLight2D.new()
moonlight.position = Vector2(room_width_px / 2.0, -200)
moonlight.texture = _make_light_texture()
moonlight.texture_scale = 12.0
moonlight.color = Color(0.6, 0.65, 0.9)  # Cool blue-white
moonlight.energy = 0.4
moonlight.blend_mode = Light2D.BLEND_MODE_ADD
add_child(moonlight)
```

- [ ] **Step 3: Enhance torch lights with flicker animation**

Update existing torch lights with animated energy using a Tween:
```gdscript
func _add_flickering_torch(pos: Vector2) -> void:
	var light = PointLight2D.new()
	light.position = pos
	light.texture = _make_light_texture()
	light.texture_scale = 4.0
	light.color = Color(1.0, 0.65, 0.2)  # Warm orange
	light.energy = 1.5
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)

	# Flicker loop
	var tween = create_tween().set_loops()
	tween.tween_property(light, "energy", 1.2, randf_range(0.1, 0.2))
	tween.tween_property(light, "energy", 1.6, randf_range(0.1, 0.2))
```

- [ ] **Step 4: Add fog/mist particles near ground**

```gdscript
var fog = GPUParticles2D.new()
fog.position = Vector2(room_width_px / 2.0, floor_y)
fog.amount = 20
fog.lifetime = 4.0
fog.process_material = _create_fog_material()
add_child(fog)

func _create_fog_material() -> ParticleProcessMaterial:
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(room_width_px / 2.0, 8.0, 0)
	mat.direction = Vector3(1.0, -0.2, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 15.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(0.6, 0.65, 0.8, 0.08)
	return mat
```

- [ ] **Step 5: Verify — run entry_hall, screenshot, confirm moonlit atmosphere with torch pools and subtle fog**

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/rooms/entry_hall.gd godot/scenes/rooms/entry_hall.tscn
git commit -m "feat: entry_hall lighting — moonlight, flickering torches, ground fog"
```

---

### Task 27: Corridor Lighting — Candlelight Pools & Colored Light Shafts

**Files:**
- Modify: `godot/scripts/rooms/corridor.gd`
- Modify: `godot/scenes/rooms/corridor.tscn`

- [ ] **Step 1: Set CanvasModulate for dark interior**

```gdscript
canvas_mod.color = Color(0.15, 0.15, 0.25)  # Very dark blue — interior with no moonlight
```

- [ ] **Step 2: Add warm candlelight sconces along platforms**

Place 4-5 PointLight2D sconces at platform edges and walls:
```gdscript
var sconce_positions = [Vector2(128, 300), Vector2(480, 180), Vector2(700, 420), Vector2(900, 280)]
for pos in sconce_positions:
	_add_flickering_torch(pos)  # Reuse pattern but with candle color
```

Candle color: `Color(1.0, 0.8, 0.4)` — warmer and softer than torches.

- [ ] **Step 3: Add stained glass light shafts**

Create angled light beams using Sprite2D with additive blending:
```gdscript
func _add_light_shaft(pos: Vector2, angle: float, color: Color) -> void:
	var shaft = Sprite2D.new()
	shaft.texture = _make_light_shaft_texture()
	shaft.position = pos
	shaft.rotation = angle
	shaft.modulate = Color(color.r, color.g, color.b, 0.12)
	shaft.material = CanvasItemMaterial.new()
	shaft.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(shaft)

	# Gentle sway
	var tween = create_tween().set_loops()
	tween.tween_property(shaft, "rotation", angle + 0.03, 3.0)
	tween.tween_property(shaft, "rotation", angle - 0.03, 3.0)

func _make_light_shaft_texture() -> GradientTexture2D:
	var tex = GradientTexture2D.new()
	tex.width = 64
	tex.height = 256
	tex.gradient = Gradient.new()
	tex.gradient.set_color(0, Color(1, 1, 1, 0.3))
	tex.gradient.set_color(1, Color(1, 1, 1, 0.0))
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	return tex
```

Add 2-3 shafts with stained glass colors (purple, amber, blue).

- [ ] **Step 4: Add dust mote particles**

```gdscript
var dust = GPUParticles2D.new()
dust.amount = 15
dust.lifetime = 6.0
# Slow-floating particles visible in light shafts
```

- [ ] **Step 5: Verify — run corridor, screenshot, confirm dark-but-readable interior with light pools and colored shafts**

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/rooms/corridor.gd godot/scenes/rooms/corridor.tscn
git commit -m "feat: corridor lighting — candle pools, stained glass shafts, dust motes"
```

---

### Task 28: Pre-Boss Lighting — Warm Safe Haven

**Files:**
- Modify: `godot/scripts/rooms/pre_boss.gd`
- Modify: `godot/scenes/rooms/pre_boss.tscn`

- [ ] **Step 1: Set CanvasModulate for warm ambience**

```gdscript
canvas_mod.color = Color(0.35, 0.30, 0.22)  # Warm golden-brown
```

- [ ] **Step 2: Enhance save point glow**

Make the save point emit a strong, warm golden radiance:
```gdscript
# In save_point setup or pre_boss._build_room()
var save_glow = PointLight2D.new()
save_glow.position = save_point_position
save_glow.texture = _make_light_texture()
save_glow.texture_scale = 6.0
save_glow.color = Color(1.0, 0.9, 0.5)  # Warm gold
save_glow.energy = 1.2
save_glow.blend_mode = Light2D.BLEND_MODE_ADD
add_child(save_glow)

# Pulse the glow
var tween = create_tween().set_loops()
tween.tween_property(save_glow, "energy", 0.8, 1.5)
tween.tween_property(save_glow, "energy", 1.2, 1.5)
```

- [ ] **Step 3: Add warm ambient lights**

2-3 soft warm lights around the room to create an inviting atmosphere.

- [ ] **Step 4: Verify — run pre_boss, screenshot, confirm warm safe-haven feel**

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/rooms/pre_boss.gd godot/scenes/rooms/pre_boss.tscn
git commit -m "feat: pre_boss lighting — warm golden save point glow, safe haven ambience"
```

---

### Task 29: Boss Arena Dynamic Lighting

**Files:**
- Modify: `godot/scripts/rooms/boss_arena.gd`
- Modify: `godot/scripts/enemies/boss_warden.gd`
- Modify: `godot/scenes/rooms/boss_arena.tscn`

- [ ] **Step 1: Set initial CanvasModulate — cold and dim**

```gdscript
canvas_mod.color = Color(0.18, 0.12, 0.15)  # Very dark, cold
```

- [ ] **Step 2: Add crimson torches at arena edges**

4 torches: two at left edges, two at right edges of the arena.
```gdscript
var torch_color = Color(0.9, 0.2, 0.15)  # Deep crimson
```

- [ ] **Step 3: Connect to boss phase_changed signal for dynamic lighting**

```gdscript
func _on_boss_phase_changed(new_phase: int) -> void:
	var tween = create_tween()
	match new_phase:
		2:
			# Intensify red
			for torch in _torches:
				tween.parallel().tween_property(torch, "energy", 2.5, 1.0)
			tween.parallel().tween_property(_canvas_mod, "color",
				Color(0.25, 0.12, 0.12), 1.0)
		3:
			# Pulsing crimson
			for torch in _torches:
				tween.parallel().tween_property(torch, "energy", 3.5, 0.5)
			tween.parallel().tween_property(_canvas_mod, "color",
				Color(0.3, 0.1, 0.1), 0.5)
			_start_pulse_lighting()

func _start_pulse_lighting() -> void:
	# Sync light pulses to boss attacks
	var pulse_tween = create_tween().set_loops()
	for torch in _torches:
		pulse_tween.parallel().tween_property(torch, "energy", 2.0, 0.3)
	pulse_tween.parallel().tween_property(_canvas_mod, "color",
		Color(0.2, 0.08, 0.08), 0.3)
	for torch in _torches:
		pulse_tween.parallel().tween_property(torch, "energy", 3.5, 0.3)
	pulse_tween.parallel().tween_property(_canvas_mod, "color",
		Color(0.3, 0.1, 0.1), 0.3)
```

- [ ] **Step 4: Add ember particles during boss fight**

```gdscript
func _create_embers() -> GPUParticles2D:
	var embers = GPUParticles2D.new()
	embers.amount = 30
	embers.lifetime = 3.0
	embers.position = Vector2(room_width_px / 2.0, floor_y)
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(room_width_px / 2.0, 4.0, 0)
	mat.direction = Vector3(0, -1.0, 0)  # Rise upward
	mat.spread = 15.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, -20, 0)  # Negative = upward drift
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.color = Color(1.0, 0.4, 0.1, 0.6)  # Orange-red
	embers.process_material = mat
	return embers
```

Increase `embers.amount` during phase transitions (30 → 50 → 80).

- [ ] **Step 5: Verify — fight boss through all 3 phases, confirm lighting escalation**

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/rooms/boss_arena.gd godot/scripts/enemies/boss_warden.gd \
       godot/scenes/rooms/boss_arena.tscn
git commit -m "feat: boss arena dynamic lighting — crimson torches, phase-synced pulsing, embers"
```

---

### Task 30: Global Visual Polish

**Files:**
- Modify: `godot/scripts/player/player.gd` (camera lookahead)
- Modify: `godot/scenes/player/player.tscn` (vignette)
- Modify all room scripts (parallax layers)

- [ ] **Step 1: Add camera lookahead**

In `player.gd`, in `_physics_process`, smoothly offset the camera in the movement direction:

```gdscript
if camera:
	var target_offset_x = facing_dir * 40.0
	camera.offset.x = lerp(camera.offset.x, target_offset_x, 3.0 * delta)
```

- [ ] **Step 2: Add vignette overlay**

Create a CanvasLayer (layer 99) with a TextureRect showing a radial vignette gradient:

```gdscript
func _add_vignette() -> void:
	var vignette_layer = CanvasLayer.new()
	vignette_layer.layer = 99
	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.texture = _make_vignette_texture()
	tex_rect.modulate = Color(1, 1, 1, 0.3)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_layer.add_child(tex_rect)
	add_child(vignette_layer)
```

- [ ] **Step 3: Verify parallax backgrounds have 3+ layers in each room**

Each room should have Far, Mid, Near parallax layers with different scroll speeds. The existing rooms may already have this from the title screen pattern.

- [ ] **Step 4: Verify — full playthrough with all lighting, screenshot each room**

Run the complete demo. Take screenshots of each room to verify:
- Entry Hall: moonlit with torches and fog
- Corridor: dark interior with candle pools and colored shafts
- Pre-Boss: warm golden glow
- Boss Arena: escalating crimson intensity

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: global visual polish — camera lookahead, vignette, parallax verification"
```

---

### Task 31: Final Integration & Phase Merges

- [ ] **Step 1: Merge all feature branches into main**

```bash
git checkout main
git merge feature/phase-1-make-it-work --no-ff -m "merge: Phase 1 — fix routing, visuals, game over screen"
git merge feature/phase-2-game-systems --no-ff -m "merge: Phase 2 — stats, inventory, abilities, menus"
git merge feature/phase-3-content-combat --no-ff -m "merge: Phase 3 — boss phases, combat feel, teaser ending"
git merge feature/phase-4-lighting --no-ff -m "merge: Phase 4 — Ori/Lightfall lighting, particles, polish"
```

- [ ] **Step 2: Final full playthrough on main branch**

Complete demo playthrough. Take screenshots of every stage. Verify everything works together.

- [ ] **Step 3: Fix any integration issues**

```bash
git add -A
git commit -m "fix: final integration fixes after phase merges"
```

---

## Summary

| Phase | Tasks | Key Deliverables |
|-------|-------|-----------------|
| Phase 1 | Tasks 1-9 | Playable loop: title → 4 rooms → boss → game over |
| Phase 2 | Tasks 10-17 | Stats, leveling, loot, double-jump, inventory UI, save/load |
| Phase 3 | Tasks 18-24 | Combat feel, boss intro/phases, respawn, teaser ending |
| Phase 4 | Tasks 25-31 | Per-room lighting, particles, vignette, camera polish |
