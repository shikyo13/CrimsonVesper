# Crimson Vesper — Godot Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the full Godot 4.x project in `godot/`, including autoload singletons, a stack-based player state machine, and a runnable test room, then push to shikyo13/CrimsonVesper on GitHub.

**Architecture:** Godot project lives in `godot/` inside the existing repo. All gameplay logic uses GDScript. Five autoload singletons handle global concerns. The player uses a stack-based finite state machine where each state is a Node child of a StateMachine node — states call `player.move_and_slide()` directly and own their transition logic.

**Tech Stack:** Godot 4.x (latest stable via Homebrew cask), GDScript, `gh` CLI for GitHub operations, Git LFS for binary assets.

**Key paths:**
- Project root: `~/Documents/Dev/CrimsonVesper/godot/`
- Autoloads: `scripts/systems/`
- Player scripts: `scripts/player/` and `scripts/player/states/`
- Scenes: `scenes/player/`, `scenes/rooms/`

---

## File Map

| File | Purpose |
|------|---------|
| `project.godot` | Engine config: display, physics, input map, autoloads |
| `.gitignore` | Ignore `.godot/`, `.import/`, etc. |
| `.gitattributes` | Git LFS for PNG/WAV/OGG; LF line endings for text |
| `scripts/systems/game_manager.gd` | Game state enum, pause, scene transitions, signal hub |
| `scripts/systems/save_manager.gd` | JSON save/load, multiple slots, FileAccess |
| `scripts/systems/audio_manager.gd` | AudioStreamPlayer pool, bus routing |
| `scripts/systems/ability_manager.gd` | Boolean ability dict, `has_ability()`, `unlock_ability()` |
| `scripts/systems/inventory_manager.gd` | Equipment slots, item list, save/load data |
| `scripts/player/state.gd` | Abstract base class for all states |
| `scripts/player/state_machine.gd` | Manages current state, dispatches update/input |
| `scripts/player/player.gd` | CharacterBody2D: constants, gravity, coyote time helpers |
| `scripts/player/states/idle_state.gd` | Standing still; transitions to run/jump/dash/attack |
| `scripts/player/states/run_state.gd` | Horizontal movement; transitions to idle/jump/fall/dash/attack |
| `scripts/player/states/jump_state.gd` | Ascending; variable height via early release cut |
| `scripts/player/states/fall_state.gd` | Descending; coyote jump available |
| `scripts/player/states/dash_state.gd` | Fixed-duration horizontal dash, ignores gravity |
| `scripts/player/states/attack_state.gd` | Fixed-duration attack placeholder |
| `scripts/player/states/hurt_state.gd` | Knockback + brief invincibility window |
| `scenes/player/player.tscn` | CharacterBody2D + CollisionShape2D + AnimatedSprite2D + StateMachine tree |
| `scenes/rooms/test_room.tscn` | StaticBody2D floor + platforms + Player instance + Camera2D |

---

## Task 1: Install Godot

**Files:** none (system install)

- [ ] **Step 1: Install Godot via Homebrew**

```bash
brew install --cask godot
```

Expected: Godot.app installed in /Applications.

- [ ] **Step 2: Verify installation**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --version
```

Expected output: `4.x.x.stable` (exact version will vary).

- [ ] **Step 3: Create a shell alias for the session**

```bash
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
echo "Godot binary: $GODOT"
```

---

## Task 2: Create directory structure

**Files:** all directories + `.gitkeep` markers

- [ ] **Step 1: Create all directories**

```bash
cd ~/Documents/Dev/CrimsonVesper/godot

mkdir -p \
  addons \
  assets/sprites/player \
  assets/sprites/enemies \
  assets/sprites/npcs \
  assets/sprites/effects \
  assets/tilesets \
  assets/backgrounds \
  assets/ui/hud \
  assets/ui/menus \
  assets/ui/fonts \
  assets/audio/music \
  assets/audio/sfx \
  assets/audio/ambient \
  assets/shaders \
  scenes/player \
  scenes/enemies \
  scenes/rooms \
  scenes/ui \
  scenes/autoload \
  scripts/player/states \
  scripts/enemies \
  scripts/systems \
  scripts/ui \
  scripts/util \
  data/items \
  data/enemies \
  data/abilities
```

- [ ] **Step 2: Add .gitkeep to every empty leaf directory**

```bash
find ~/Documents/Dev/CrimsonVesper/godot -type d -empty -exec touch {}/.gitkeep \;
```

- [ ] **Step 3: Verify**

```bash
find ~/Documents/Dev/CrimsonVesper/godot -type d | sort
```

Expected: 30+ directories all present.

---

## Task 3: Create project.godot and git files

**Files:**
- Create: `godot/project.godot`
- Create: `godot/.gitignore`
- Create: `godot/.gitattributes`

- [ ] **Step 1: Write project.godot**

Write `~/Documents/Dev/CrimsonVesper/godot/project.godot`:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="Crimson Vesper"
config/description="A 2D metroidvania — spiritual successor to Castlevania: Symphony of the Night."
config/version="0.1.0"
run/main_scene="res://scenes/rooms/test_room.tscn"
config/features=PackedStringArray("4.4", "Forward Plus")

[autoload]

GameManager="*res://scripts/systems/game_manager.gd"
SaveManager="*res://scripts/systems/save_manager.gd"
AudioManager="*res://scripts/systems/audio_manager.gd"
AbilityManager="*res://scripts/systems/ability_manager.gd"
InventoryManager="*res://scripts/systems/inventory_manager.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
]
}
attack={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":122,"location":0,"echo":false,"script":null)
]
}
dash={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":88,"key_label":0,"unicode":120,"location":0,"echo":false,"script":null)
]
}
spell={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":67,"key_label":0,"unicode":99,"location":0,"echo":false,"script":null)
]
}
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)
]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
map={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":77,"key_label":0,"unicode":109,"location":0,"echo":false,"script":null)
]
}
inventory={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":73,"key_label":0,"unicode":105,"location":0,"echo":false,"script":null)
]
}

[physics]

common/physics_ticks_per_second=60

[rendering]

renderer/rendering_method="forward_plus"
```

Input map key bindings:
- move_left: A (65) + Left Arrow (4194319)
- move_right: D (68) + Right Arrow (4194321)
- jump: Space (32)
- attack: Z (90)
- dash: X (88)
- spell: C (67)
- interact: E (69)
- pause: Escape (4194305)
- map: M (77)
- inventory: I (73)

- [ ] **Step 2: Write .gitignore**

Write `~/Documents/Dev/CrimsonVesper/godot/.gitignore`:

```
# Godot 4 generated cache — never commit these
.godot/

# Godot 3 legacy (safe to ignore)
.import/
export.cfg
export_preset.cfg

# Mono / C#
.mono/
data_*/
mono_crash.*.json

# macOS
.DS_Store
**/.DS_Store

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
```

- [ ] **Step 3: Write .gitattributes**

Write `~/Documents/Dev/CrimsonVesper/godot/.gitattributes`:

```
# Normalize text file line endings to LF on commit
* text=auto eol=lf

# Godot text formats
*.gd        text eol=lf
*.tscn      text eol=lf
*.tres      text eol=lf
*.godot     text eol=lf
*.gdshader  text eol=lf
*.import    text eol=lf
*.cfg       text eol=lf

# Binary assets — use Git LFS
*.png       filter=lfs diff=lfs merge=lfs -text
*.jpg       filter=lfs diff=lfs merge=lfs -text
*.jpeg      filter=lfs diff=lfs merge=lfs -text
*.webp      filter=lfs diff=lfs merge=lfs -text
*.wav       filter=lfs diff=lfs merge=lfs -text
*.ogg       filter=lfs diff=lfs merge=lfs -text
*.mp3       filter=lfs diff=lfs merge=lfs -text
*.ttf       filter=lfs diff=lfs merge=lfs -text
*.otf       filter=lfs diff=lfs merge=lfs -text
*.woff      filter=lfs diff=lfs merge=lfs -text
*.woff2     filter=lfs diff=lfs merge=lfs -text

# SVG is text
*.svg       text eol=lf
```

- [ ] **Step 4: Verify files exist**

```bash
ls -la ~/Documents/Dev/CrimsonVesper/godot/
```

Expected: `project.godot`, `.gitignore`, `.gitattributes` all present.

---

## Task 4: Create autoload singletons

**Files:**
- Create: `scripts/systems/game_manager.gd`
- Create: `scripts/systems/save_manager.gd`
- Create: `scripts/systems/audio_manager.gd`
- Create: `scripts/systems/ability_manager.gd`
- Create: `scripts/systems/inventory_manager.gd`

- [ ] **Step 1: Write game_manager.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/systems/game_manager.gd`:

```gdscript
extends Node
## GameManager — global game state, pause, and scene transitions.
## Registered as autoload "GameManager". Persists across all scene changes.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, TRANSITIONING }

signal state_changed(new_state: GameState)
signal scene_transition_started(target_scene: String)

var current_state: GameState = GameState.MENU

func _ready() -> void:
	# Always process so pause input works even when tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- State ---

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)

func pause_game() -> void:
	change_state(GameState.PAUSED)
	get_tree().paused = true

func resume_game() -> void:
	change_state(GameState.PLAYING)
	get_tree().paused = false

func is_playing() -> bool:
	return current_state == GameState.PLAYING

# --- Scene transitions ---

func go_to_scene(path: String) -> void:
	change_state(GameState.TRANSITIONING)
	scene_transition_started.emit(path)
	get_tree().change_scene_to_file(path)
```

- [ ] **Step 2: Write save_manager.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/systems/save_manager.gd`:

```gdscript
extends Node
## SaveManager — JSON save/load with multiple save slots.
## Registered as autoload "SaveManager".

const SAVE_DIR: String = "user://saves/"
const MAX_SLOTS: int = 3

signal save_completed(slot: int)
signal load_completed(slot: int)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# --- Public API ---

func save_game(slot: int, data: Dictionary) -> bool:
	if not _slot_valid(slot):
		return false
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open %s for writing (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit(slot)
	return true

func load_game(slot: int) -> Dictionary:
	if not _slot_valid(slot):
		return {}
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open %s for reading" % path)
		return {}
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("SaveManager: failed to parse %s" % path)
		return {}
	load_completed.emit(slot)
	return json.data

func delete_save(slot: int) -> void:
	if _slot_valid(slot) and save_exists(slot):
		DirAccess.remove_absolute(_slot_path(slot))

func save_exists(slot: int) -> bool:
	return _slot_valid(slot) and FileAccess.file_exists(_slot_path(slot))

# --- Helpers ---

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot

func _slot_valid(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveManager: invalid slot %d (valid: 0–%d)" % [slot, MAX_SLOTS - 1])
		return false
	return true
```

- [ ] **Step 3: Write audio_manager.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/systems/audio_manager.gd`:

```gdscript
extends Node
## AudioManager — music playback, SFX pooling, and bus volume control.
## Registered as autoload "AudioManager".
## Bus layout: Master → Music, SFX, Ambient, UI
## Buses must be created in Project > Audio (or via AudioServer in _ready).

const BUS_MUSIC:   String = "Music"
const BUS_SFX:     String = "SFX"
const BUS_AMBIENT: String = "Ambient"
const BUS_UI:      String = "UI"

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)

# --- Music ---

func play_music(stream: AudioStream) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

# --- SFX (fire-and-forget, positional) ---

func play_sfx(stream: AudioStream, world_position: Vector2 = Vector2.ZERO) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()

# --- UI sounds (non-positional) ---

func play_ui(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_UI
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

# --- Volume control ---

func set_bus_volume_db(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

func get_bus_volume_db(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_db(idx) if idx != -1 else -80.0
```

- [ ] **Step 4: Write ability_manager.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/systems/ability_manager.gd`:

```gdscript
extends Node
## AbilityManager — tracks unlocked traversal/combat abilities.
## Registered as autoload "AbilityManager".
## Gate checks: if AbilityManager.has_ability("double_jump"): ...

signal ability_unlocked(ability_name: String)

## All abilities start locked. Keys are stable identifiers used throughout the codebase.
var _abilities: Dictionary = {
	"double_jump":  false,
	"dash":         false,
	"wall_climb":   false,
	"grapple":      false,
	"shadow_dash":  false,
	"fire_barrier": false,
	"levitate":     false,
	"bat_form":     false,
}

func has_ability(ability_name: String) -> bool:
	if not _abilities.has(ability_name):
		push_warning("AbilityManager: unknown ability '%s'" % ability_name)
		return false
	return _abilities[ability_name]

func unlock_ability(ability_name: String) -> void:
	if not _abilities.has(ability_name):
		push_error("AbilityManager: cannot unlock unknown ability '%s'" % ability_name)
		return
	if _abilities[ability_name]:
		return  # Already unlocked — idempotent.
	_abilities[ability_name] = true
	ability_unlocked.emit(ability_name)

func get_save_data() -> Dictionary:
	return _abilities.duplicate()

func load_save_data(data: Dictionary) -> void:
	for key: String in data:
		if _abilities.has(key):
			_abilities[key] = data[key]
```

- [ ] **Step 5: Write inventory_manager.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/systems/inventory_manager.gd`:

```gdscript
extends Node
## InventoryManager — equipment slots and item storage.
## Registered as autoload "InventoryManager".

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal equipment_changed(slot: EquipSlot, item_id: String)

enum EquipSlot { WEAPON, ARMOR, HELMET, CLOAK, ACCESSORY_1, ACCESSORY_2 }

const MAX_ITEMS: int = 64

var _equipment: Dictionary = {
	EquipSlot.WEAPON:      "",
	EquipSlot.ARMOR:       "",
	EquipSlot.HELMET:      "",
	EquipSlot.CLOAK:       "",
	EquipSlot.ACCESSORY_1: "",
	EquipSlot.ACCESSORY_2: "",
}
var _inventory: Array[String] = []

# --- Inventory ---

func add_item(item_id: String) -> bool:
	if _inventory.size() >= MAX_ITEMS:
		return false
	_inventory.append(item_id)
	item_added.emit(item_id)
	return true

func remove_item(item_id: String) -> bool:
	var idx := _inventory.find(item_id)
	if idx == -1:
		return false
	_inventory.remove_at(idx)
	item_removed.emit(item_id)
	return true

func has_item(item_id: String) -> bool:
	return _inventory.has(item_id)

# --- Equipment ---

func equip(slot: EquipSlot, item_id: String) -> void:
	_equipment[slot] = item_id
	equipment_changed.emit(slot, item_id)

func unequip(slot: EquipSlot) -> void:
	_equipment[slot] = ""
	equipment_changed.emit(slot, "")

func get_equipped(slot: EquipSlot) -> String:
	return _equipment.get(slot, "")

# --- Persistence ---

func get_save_data() -> Dictionary:
	return {"equipment": _equipment.duplicate(), "inventory": _inventory.duplicate()}

func load_save_data(data: Dictionary) -> void:
	if data.has("inventory"):
		_inventory = (data["inventory"] as Array).map(func(v): return v as String)
	if data.has("equipment"):
		for key in data["equipment"]:
			_equipment[key] = data["equipment"][key]
```

- [ ] **Step 6: Validate all singletons parse cleanly**

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
cd ~/Documents/Dev/CrimsonVesper/godot
$GODOT --headless --check-only --path . 2>&1 | grep -E "(ERROR|SCRIPT ERROR|Parse Error)" || echo "No parse errors"
```

Expected: "No parse errors" (or only warnings about missing buses — those are runtime, not parse-time).

- [ ] **Step 7: Commit**

```bash
cd ~/Documents/Dev/CrimsonVesper
git add godot/project.godot godot/.gitignore godot/.gitattributes godot/scripts/systems/
git commit -m "feat(godot): add project.godot, git files, and autoload singletons"
```

---

## Task 5: Create player state machine base classes

**Files:**
- Create: `scripts/player/state.gd`
- Create: `scripts/player/state_machine.gd`

- [ ] **Step 1: Write state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/state.gd`:

```gdscript
class_name State
extends Node
## Base class for all player states.
## Subclasses override the four lifecycle methods below.
## `player` is injected by StateMachine._ready().

var player: CharacterBody2D

func enter() -> void:
	## Called when this state becomes active.
	pass

func exit() -> void:
	## Called just before this state is replaced.
	pass

func update(delta: float) -> void:
	## Called every physics frame while this state is active.
	## Responsible for movement and self-initiated transitions.
	pass

func handle_input(event: InputEvent) -> void:
	## Called for every unhandled input event while this state is active.
	## Use for discrete action transitions (jump pressed, dash pressed, etc.).
	pass
```

- [ ] **Step 2: Write state_machine.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/state_machine.gd`:

```gdscript
class_name StateMachine
extends Node
## Stack-based finite state machine for the player.
## Place as a child of CharacterBody2D. Add State nodes as children of this node.
## Call change_state("idle") from the player's _ready() to start.

var current_state: State
var states: Dictionary = {}  # name (lowercase) -> State node

func _ready() -> void:
	var parent := get_parent() as CharacterBody2D
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = parent

func change_state(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	if new_state == null:
		push_error("StateMachine: state '%s' not found. Available: %s" % [new_state_name, states.keys()])
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
```

- [ ] **Step 3: Validate**

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --check-only --path ~/Documents/Dev/CrimsonVesper/godot 2>&1 | grep -E "(ERROR|Parse Error)" || echo "OK"
```

---

## Task 6: Create player.gd and all state scripts

**Files:**
- Create: `scripts/player/player.gd`
- Create: `scripts/player/states/idle_state.gd`
- Create: `scripts/player/states/run_state.gd`
- Create: `scripts/player/states/jump_state.gd`
- Create: `scripts/player/states/fall_state.gd`
- Create: `scripts/player/states/dash_state.gd`
- Create: `scripts/player/states/attack_state.gd`
- Create: `scripts/player/states/hurt_state.gd`

- [ ] **Step 1: Write player.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/player.gd`:

```gdscript
class_name Player
extends CharacterBody2D
## Root player node. Owns movement constants and shared physics helpers.
## All per-state logic lives in the state scripts under states/.

# --- Tuning (adjust in Inspector) ---
@export var speed: float        = 200.0   ## Horizontal run speed (px/s)
@export var jump_force: float   = 520.0   ## Initial upward velocity on jump
@export var dash_speed: float   = 480.0   ## Horizontal speed during dash
@export var dash_duration: float = 0.18  ## Seconds the dash lasts

# --- Jump feel ---
const JUMP_CUT_MULTIPLIER: float = 0.45  ## Applied to upward velocity on early release
const COYOTE_FRAMES: int = 6             ## Physics frames of grace after walking off an edge

# --- Runtime state (written by states, not directly) ---
var coyote_timer: int = 0
var jump_released_early: bool = false

# --- Cached nodes ---
@onready var state_machine: StateMachine   = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Physics constant ---
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	state_machine.change_state("idle")

# --- Helpers called by states ---

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

func tick_coyote() -> void:
	## Call in idle/run/fall states every physics frame.
	## Resets to COYOTE_FRAMES while on floor; counts down while airborne.
	if is_on_floor():
		coyote_timer = COYOTE_FRAMES
	elif coyote_timer > 0:
		coyote_timer -= 1

func is_coyote_active() -> bool:
	return coyote_timer > 0

func play_anim(anim_name: String) -> void:
	## Safe animation play — no-ops if SpriteFrames not yet loaded.
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
```

- [ ] **Step 2: Write idle_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/idle_state.gd`:

```gdscript
class_name IdleState
extends State

func enter() -> void:
	player.velocity.x = 0.0
	player.play_anim("idle")

func update(delta: float) -> void:
	player.tick_coyote()
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		player.state_machine.change_state("fall")
	elif Input.get_axis("move_left", "move_right") != 0.0:
		player.state_machine.change_state("run")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.state_machine.change_state("jump")
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack"):
		player.state_machine.change_state("attack")
```

- [ ] **Step 3: Write run_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/run_state.gd`:

```gdscript
class_name RunState
extends State

func enter() -> void:
	player.play_anim("run")

func update(delta: float) -> void:
	player.tick_coyote()
	player.apply_gravity(delta)

	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0.0:
		player.animated_sprite.flip_h = dir < 0.0

	player.move_and_slide()

	if not player.is_on_floor():
		player.state_machine.change_state("fall")
	elif dir == 0.0:
		player.state_machine.change_state("idle")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.state_machine.change_state("jump")
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack"):
		player.state_machine.change_state("attack")
```

- [ ] **Step 4: Write jump_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/jump_state.gd`:

```gdscript
class_name JumpState
extends State

func enter() -> void:
	player.velocity.y = -player.jump_force
	player.jump_released_early = false
	player.coyote_timer = 0  # Consume coyote so it can't fire again mid-air.
	player.play_anim("jump")

func update(delta: float) -> void:
	# Variable jump height: cut upward velocity once on early release.
	if player.jump_released_early:
		if player.velocity.y < 0.0:
			player.velocity.y *= player.JUMP_CUT_MULTIPLIER
		player.jump_released_early = false

	player.apply_gravity(delta)

	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0.0:
		player.animated_sprite.flip_h = dir < 0.0

	player.move_and_slide()

	if player.velocity.y >= 0.0:
		player.state_machine.change_state("fall")

func handle_input(event: InputEvent) -> void:
	if event.is_action_released("jump"):
		player.jump_released_early = true
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack"):
		player.state_machine.change_state("attack")
```

- [ ] **Step 5: Write fall_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/fall_state.gd`:

```gdscript
class_name FallState
extends State

func enter() -> void:
	player.play_anim("fall")

func update(delta: float) -> void:
	player.tick_coyote()
	player.apply_gravity(delta)

	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0.0:
		player.animated_sprite.flip_h = dir < 0.0

	player.move_and_slide()

	if player.is_on_floor():
		if Input.get_axis("move_left", "move_right") != 0.0:
			player.state_machine.change_state("run")
		else:
			player.state_machine.change_state("idle")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and player.is_coyote_active():
		player.coyote_timer = 0  # Consume coyote.
		player.state_machine.change_state("jump")
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack"):
		player.state_machine.change_state("attack")
```

- [ ] **Step 6: Write dash_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/dash_state.gd`:

```gdscript
class_name DashState
extends State
## Placeholder dash: fixed-duration horizontal burst, ignores gravity.
## Replace _dash_direction logic with proper dodge-roll when animation is ready.

var _timer: float = 0.0
var _dir: float = 1.0

func enter() -> void:
	_timer = player.dash_duration
	# Dash in the direction the player is currently facing.
	_dir = -1.0 if player.animated_sprite.flip_h else 1.0
	player.velocity = Vector2(_dir * player.dash_speed, 0.0)
	player.play_anim("dash")

func update(delta: float) -> void:
	_timer -= delta
	player.velocity.x = _dir * player.dash_speed
	player.velocity.y = 0.0  # Suspend gravity for the dash duration.
	player.move_and_slide()

	if _timer <= 0.0:
		if player.is_on_floor():
			player.state_machine.change_state("idle")
		else:
			player.state_machine.change_state("fall")
```

- [ ] **Step 7: Write attack_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/attack_state.gd`:

```gdscript
class_name AttackState
extends State
## Placeholder attack: fixed-duration standstill, then returns to idle/fall.
## Wire up hitbox Area2D and proper animation in the next pass.

const DURATION: float = 0.30

var _timer: float = 0.0

func enter() -> void:
	_timer = DURATION
	player.velocity.x = 0.0
	player.play_anim("attack")

func update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	# Preserve a little momentum so it doesn't feel sticky.
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * 8.0)
	player.move_and_slide()

	if _timer <= 0.0:
		if player.is_on_floor():
			player.state_machine.change_state("idle")
		else:
			player.state_machine.change_state("fall")
```

- [ ] **Step 8: Write hurt_state.gd**

Write `~/Documents/Dev/CrimsonVesper/godot/scripts/player/states/hurt_state.gd`:

```gdscript
class_name HurtState
extends State
## Knockback + brief stagger window.
## Call state_machine.change_state("hurt") from a hit-detection callback,
## then call set_knockback(direction) immediately after to configure it.

const DURATION: float = 0.40
const KNOCKBACK_X: float = 220.0
const KNOCKBACK_Y: float = -180.0

var _timer: float = 0.0
var _knockback_dir: float = 1.0

func enter() -> void:
	_timer = DURATION
	player.play_anim("hurt")

func set_knockback(source_x: float) -> void:
	## source_x: the world-space X position of whatever hit the player.
	_knockback_dir = 1.0 if player.global_position.x >= source_x else -1.0
	player.velocity = Vector2(_knockback_dir * KNOCKBACK_X, KNOCKBACK_Y)

func update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, KNOCKBACK_X * delta * 6.0)
	player.move_and_slide()

	if _timer <= 0.0:
		player.state_machine.change_state("idle")
```

- [ ] **Step 9: Validate all player scripts**

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --check-only --path ~/Documents/Dev/CrimsonVesper/godot 2>&1 | grep -E "(ERROR|Parse Error)" || echo "OK"
```

- [ ] **Step 10: Commit**

```bash
cd ~/Documents/Dev/CrimsonVesper
git add godot/scripts/player/
git commit -m "feat(godot): add player state machine — State, StateMachine, Player, 7 states"
```

---

## Task 7: Create scenes

**Files:**
- Create: `scenes/player/player.tscn`
- Create: `scenes/rooms/test_room.tscn`

- [ ] **Step 1: Write player.tscn**

Write `~/Documents/Dev/CrimsonVesper/godot/scenes/player/player.tscn`:

```ini
[gd_scene load_steps=11 format=3]

[ext_resource type="Script" path="res://scripts/player/player.gd" id="1"]
[ext_resource type="Script" path="res://scripts/player/state_machine.gd" id="2"]
[ext_resource type="Script" path="res://scripts/player/states/idle_state.gd" id="3"]
[ext_resource type="Script" path="res://scripts/player/states/run_state.gd" id="4"]
[ext_resource type="Script" path="res://scripts/player/states/jump_state.gd" id="5"]
[ext_resource type="Script" path="res://scripts/player/states/fall_state.gd" id="6"]
[ext_resource type="Script" path="res://scripts/player/states/dash_state.gd" id="7"]
[ext_resource type="Script" path="res://scripts/player/states/attack_state.gd" id="8"]
[ext_resource type="Script" path="res://scripts/player/states/hurt_state.gd" id="9"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_1"]
radius = 16.0
height = 48.0

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CapsuleShape2D_1")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]

[node name="StateMachine" type="Node" parent="."]
script = ExtResource("2")

[node name="IdleState" type="Node" parent="StateMachine"]
script = ExtResource("3")

[node name="RunState" type="Node" parent="StateMachine"]
script = ExtResource("4")

[node name="JumpState" type="Node" parent="StateMachine"]
script = ExtResource("5")

[node name="FallState" type="Node" parent="StateMachine"]
script = ExtResource("6")

[node name="DashState" type="Node" parent="StateMachine"]
script = ExtResource("7")

[node name="AttackState" type="Node" parent="StateMachine"]
script = ExtResource("8")

[node name="HurtState" type="Node" parent="StateMachine"]
script = ExtResource("9")
```

- [ ] **Step 2: Write test_room.tscn**

The test room uses `StaticBody2D` nodes for collidable geometry. No tileset texture is needed to test movement. The `TileMapLayer` node is included as a placeholder for when tiles are ready.

Write `~/Documents/Dev/CrimsonVesper/godot/scenes/rooms/test_room.tscn`:

```ini
[gd_scene load_steps=4 format=3]

[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="1"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_floor"]
size = Vector2(1920, 32)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_platform"]
size = Vector2(300, 32)

[node name="TestRoom" type="Node2D"]

[node name="TileMapLayer" type="TileMapLayer" parent="."]

[node name="Floor" type="StaticBody2D" parent="."]
position = Vector2(960, 620)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor"]
shape = SubResource("RectangleShape2D_floor")

[node name="Platform1" type="StaticBody2D" parent="."]
position = Vector2(320, 460)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platform1"]
shape = SubResource("RectangleShape2D_platform")

[node name="Platform2" type="StaticBody2D" parent="."]
position = Vector2(720, 360)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platform2"]
shape = SubResource("RectangleShape2D_platform")

[node name="Platform3" type="StaticBody2D" parent="."]
position = Vector2(1200, 260)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platform3"]
shape = SubResource("RectangleShape2D_platform")

[node name="Player" parent="." instance=ExtResource("1")]
position = Vector2(200, 540)

[node name="Camera2D" type="Camera2D" parent="Player"]
position_smoothing_enabled = true
position_smoothing_speed = 5.0
```

- [ ] **Step 3: Validate scenes**

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --headless --check-only --path ~/Documents/Dev/CrimsonVesper/godot 2>&1 | grep -E "(ERROR|Parse Error)" || echo "OK"
```

- [ ] **Step 4: Run test room headlessly for 3 seconds to catch runtime errors**

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
timeout 5 $GODOT --headless --path ~/Documents/Dev/CrimsonVesper/godot 2>&1 | head -40
```

Expected: Engine starts, scene loads, no SCRIPT ERRORs. It will log warnings about missing animations and audio buses — those are expected for the scaffold.

- [ ] **Step 5: Commit**

```bash
cd ~/Documents/Dev/CrimsonVesper
git add godot/scenes/
git commit -m "feat(godot): add player scene and test room"
```

---

## Task 8: Create GitHub remote and push

- [ ] **Step 1: Create the GitHub repository**

```bash
cd ~/Documents/Dev/CrimsonVesper
gh repo create shikyo13/CrimsonVesper --public --description "Crimson Vesper — 2D metroidvania built in Godot 4" --source . --remote origin
```

Expected: Repo created at `https://github.com/shikyo13/CrimsonVesper`, remote `origin` added.

- [ ] **Step 2: Verify remote**

```bash
cd ~/Documents/Dev/CrimsonVesper
git remote -v
```

Expected:
```
origin  https://github.com/shikyo13/CrimsonVesper.git (fetch)
origin  https://github.com/shikyo13/CrimsonVesper.git (push)
```

- [ ] **Step 3: Commit the spec and plan docs**

```bash
cd ~/Documents/Dev/CrimsonVesper
git add docs/superpowers/
git commit -m "docs: add scaffold design spec and implementation plan"
```

- [ ] **Step 4: Push all commits**

```bash
cd ~/Documents/Dev/CrimsonVesper
git push -u origin main
```

Expected: All commits pushed, branch tracking set.

- [ ] **Step 5: Verify on GitHub**

```bash
gh repo view shikyo13/CrimsonVesper --web
```

Or check with:
```bash
gh repo view shikyo13/CrimsonVesper
```

Expected: Repo visible with all files including `godot/`, `docs/`, `README.md`.

---

## Self-Review Notes

- Spec requires `project.godot` to configure 60 FPS physics, 1920×1080, canvas_items stretch, keep aspect — Task 3 covers all of these.
- Spec requires input mappings for 10 actions — Task 3 covers all 10 with dual bindings where applicable.
- Spec requires 5 autoloads — Task 4 covers all 5 with full implementations.
- Spec requires 7 player states — Task 6 covers all 7 (Idle, Run, Jump, Fall, Dash, Attack, Hurt).
- Spec requires coyote time and variable jump — both implemented in jump_state.gd and fall_state.gd.
- Spec requires Camera2D following player — test_room.tscn Camera2D is parented to Player.
- Spec requires git + GitHub push — Task 8.
- Godot install is a prerequisite — Task 1.
