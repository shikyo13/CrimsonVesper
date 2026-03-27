extends Node2D

# Tile atlas coordinates in cemetery_tileset.png (28 columns × 10 rows of 16×16 tiles)
const T_FLOOR       := Vector2i(0, 0)   # stone_floor
const T_WALL        := Vector2i(1, 0)   # stone_wall
const T_PLATFORM    := Vector2i(2, 0)   # stone platform ledge
const T_PILLAR_TOP  := Vector2i(3, 0)
const T_PILLAR_MID  := Vector2i(0, 1)
const T_PILLAR_BASE := Vector2i(1, 1)
const T_TORCH_0     := Vector2i(2, 1)   # flame frame 0
const T_TORCH_1     := Vector2i(3, 1)   # flame frame 1
const T_TORCH_2     := Vector2i(0, 2)   # flame frame 2
const T_BG          := Vector2i(1, 2)   # background stone
const T_SPIKES      := Vector2i(2, 2)
const T_DOOR        := Vector2i(3, 2)

const TORCH_FRAMES := [Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 2)]

@onready var tile_map:      TileMapLayer = $TileMapLayer
@onready var hp_label:      Label        = $HUD/HPLabel
@onready var mp_label:      Label        = $HUD/MPLabel
@onready var boss_hp_bar:   ProgressBar  = $HUD/BossHPBar
@onready var boss_name_lbl: Label        = $HUD/BossNameLabel

var torch_timer: float = 0.0
var torch_frame: int   = 0
var torch_positions: Array[Vector2i] = []


func _ready() -> void:
	_build_room()
	# Connect player HP / MP signals
	var player := $Player
	player.hp_changed.connect(_on_player_hp_changed)
	player.mp_changed.connect(_on_player_mp_changed)
	hp_label.text = "HP: %d / %d" % [player.current_hp, player.max_hp]
	mp_label.text = "MP: %d / %d" % [player.current_mp, player.max_mp]
	# Connect boss signals
	var boss := get_node_or_null("BossWarden")
	if boss:
		boss_hp_bar.max_value = boss.max_hp
		boss_hp_bar.value = boss.hp
		boss_hp_bar.visible = true
		boss_name_lbl.visible = true
		boss.hp_changed.connect(_on_boss_hp_changed)
		boss.boss_defeated.connect(_on_boss_defeated)


func _on_player_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, max_val]


func _on_player_mp_changed(current: int, max_val: int) -> void:
	mp_label.text = "MP: %d / %d" % [current, max_val]


func _on_boss_hp_changed(current: int, max_val: int) -> void:
	boss_hp_bar.max_value = max_val
	boss_hp_bar.value = current


func _on_boss_defeated() -> void:
	boss_hp_bar.visible = false
	boss_name_lbl.visible = false


func _build_room() -> void:
	# Background fill: rows 0–18, cols 1–58
	for r in range(0, 19):
		for c in range(1, 59):
			tile_map.set_cell(Vector2i(c, r), 0, T_BG)

	# Left wall: col 0, rows 0–19
	for r in range(0, 20):
		tile_map.set_cell(Vector2i(0, r), 0, T_WALL)

	# Right wall: col 59, rows 0–19
	for r in range(0, 20):
		tile_map.set_cell(Vector2i(59, r), 0, T_WALL)

	# Floor: row 19, cols 0–59
	for c in range(0, 60):
		tile_map.set_cell(Vector2i(c, 19), 0, T_FLOOR)

	# Platform 1 (row 15, cols 5–14) — 128px above floor, just reachable with max jump
	for c in range(5, 15):
		tile_map.set_cell(Vector2i(c, 15), 0, T_PLATFORM)

	# Platform 2 (row 12, cols 17–28) — 96px above P1
	for c in range(17, 29):
		tile_map.set_cell(Vector2i(c, 12), 0, T_PLATFORM)

	# Platform 3 (row 9, cols 32–43) — 96px above P2
	for c in range(32, 44):
		tile_map.set_cell(Vector2i(c, 9), 0, T_PLATFORM)

	# Platform 4 (row 12, cols 44–53) — descent path back down from P3
	for c in range(44, 54):
		tile_map.set_cell(Vector2i(c, 12), 0, T_PLATFORM)

	# Pillars
	_place_pillar(15, 16, 19)   # Right of P1
	_place_pillar(29, 13, 19)   # Right of P2
	_place_pillar(43, 10, 19)   # Right of P3

	# Torches
	_place_torch(14, 14)    # Left edge of P1
	_place_torch(28, 11)    # Left edge of P2
	_place_torch(42, 8)     # Left edge of P3
	_place_torch(53, 11)    # Right edge of P4
	_place_torch(2, 10)     # Left wall
	_place_torch(57, 10)    # Right wall

	# Spikes on a dangerous stretch of floor
	for c in range(48, 55):
		tile_map.set_cell(Vector2i(c, 19), 0, T_SPIKES)

	# Door frame on right side
	tile_map.set_cell(Vector2i(58, 17), 0, T_DOOR)
	tile_map.set_cell(Vector2i(58, 18), 0, T_DOOR)


func _place_pillar(col: int, top_row: int, bottom_row: int) -> void:
	tile_map.set_cell(Vector2i(col, top_row), 0, T_PILLAR_TOP)
	for r in range(top_row + 1, bottom_row):
		tile_map.set_cell(Vector2i(col, r), 0, T_PILLAR_MID)
	tile_map.set_cell(Vector2i(col, bottom_row), 0, T_PILLAR_BASE)


func _place_torch(col: int, row: int) -> void:
	tile_map.set_cell(Vector2i(col, row), 0, T_TORCH_0)
	torch_positions.append(Vector2i(col, row))


func _process(delta: float) -> void:
	torch_timer += delta
	if torch_timer >= 0.15:
		torch_timer = 0.0
		torch_frame = (torch_frame + 1) % 3
		var atlas: Vector2i = TORCH_FRAMES[torch_frame]
		for pos: Vector2i in torch_positions:
			tile_map.set_cell(pos, 0, atlas)
