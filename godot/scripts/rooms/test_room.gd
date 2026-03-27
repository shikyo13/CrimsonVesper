extends Node2D

# Tile atlas coordinates in castle_tileset.png (4 columns × 3 rows of 32×32 tiles)
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

@onready var tile_map: TileMapLayer = $TileMapLayer

var torch_timer: float = 0.0
var torch_frame: int = 0
var torch_positions: Array[Vector2i] = []


func _ready() -> void:
	_build_room()


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

	# Platform 1 (~x 160–448 px → cols 5–14)
	for c in range(5, 15):
		tile_map.set_cell(Vector2i(c, 14), 0, T_PLATFORM)

	# Platform 2 (~x 544–896 px → cols 17–28)
	for c in range(17, 29):
		tile_map.set_cell(Vector2i(c, 11), 0, T_PLATFORM)

	# Platform 3 (~x 1024–1376 px → cols 32–43)
	for c in range(32, 44):
		tile_map.set_cell(Vector2i(c, 8), 0, T_PLATFORM)

	# Pillars (top, mid×n, base)
	_place_pillar(15, 15, 19)
	_place_pillar(30, 12, 19)
	_place_pillar(45, 9, 19)

	# Torches
	_place_torch(14, 13)
	_place_torch(29, 10)
	_place_torch(44, 7)
	_place_torch(2, 10)
	_place_torch(57, 10)

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
		var atlas := TORCH_FRAMES[torch_frame]
		for pos: Vector2i in torch_positions:
			tile_map.set_cell(pos, 0, atlas)
