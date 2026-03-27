extends Node2D
## Entry Hall — first room the player enters after the cinematic.
## Cemetery tileset, 3 skeletons, health potion on ledge, save point near entrance.
## Door right → Corridor (SpawnLeft).

# --- Tile atlas coords (cemetery_tileset.png, 28×10 grid of 16px tiles) ---
const T_BG          := Vector2i(1, 2)
const T_FLOOR       := Vector2i(0, 0)
const T_WALL        := Vector2i(1, 0)
const T_PLATFORM    := Vector2i(2, 0)
const T_PILLAR_TOP  := Vector2i(3, 0)
const T_PILLAR_MID  := Vector2i(0, 1)
const T_PILLAR_BASE := Vector2i(1, 1)
const T_TORCH_0     := Vector2i(2, 1)
const T_TORCH_1     := Vector2i(3, 1)
const T_TORCH_2     := Vector2i(0, 2)
const T_DOOR        := Vector2i(3, 2)

const TORCH_FRAMES := [Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 2)]

@onready var tile_map:  TileMapLayer = $TileMapLayer
@onready var hp_label:  Label        = $HUD/HPLabel
@onready var door_right: Area2D      = $DoorRight

var torch_timer: float = 0.0
var torch_frame: int   = 0
var torch_positions: Array[Vector2i] = []


func _ready() -> void:
	RoomManager.current_room_id = "entry_hall"
	tile_map.tile_set = _create_tileset()
	_build_room()
	var player := $Player
	player.hp_changed.connect(_on_player_hp_changed)
	hp_label.text = "HP: %d / %d" % [player.current_hp, player.max_hp]
	_place_player(player)
	door_right.body_entered.connect(_on_door_right)
	RoomManager.fade_in()


func _place_player(player: Node) -> void:
	var spawn_name := RoomManager.get_spawn_point_name()
	var spawn := get_node_or_null(spawn_name)
	if spawn:
		player.global_position = spawn.global_position


func _on_player_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, max_val]


func _on_door_right(_body: Node) -> void:
	RoomManager.transition_to("res://scenes/rooms/corridor.tscn", "SpawnLeft")


func _process(delta: float) -> void:
	torch_timer += delta
	if torch_timer >= 0.15:
		torch_timer = 0.0
		torch_frame = (torch_frame + 1) % 3
		var atlas := TORCH_FRAMES[torch_frame]
		for pos: Vector2i in torch_positions:
			tile_map.set_cell(pos, 0, atlas)


# --- Tileset (runtime, Option C) ---

func _create_tileset() -> TileSet:
	var ts  := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tilesets/cemetery_tileset.png")
	src.texture_region_size = Vector2i(16, 16)
	for row in 4:
		for col in 4:
			src.create_tile(Vector2i(col, row))
	ts.add_source(src, 0)
	return ts


# --- Room layout ---
# Viewport 1920×1080, TileMapLayer scale 4.0 (64px/tile)
# Visible cols 0–29, visible rows 0–16
# Floor collision at y=620 → visual floor at row 10 (y=640)

func _build_room() -> void:
	# Background fill
	for r in range(0, 11):
		for c in range(0, 30):
			tile_map.set_cell(Vector2i(c, r), 0, T_BG)

	# Left wall
	for r in range(0, 11):
		tile_map.set_cell(Vector2i(0, r), 0, T_WALL)

	# Right wall
	for r in range(0, 11):
		tile_map.set_cell(Vector2i(29, r), 0, T_WALL)

	# Visual floor row
	for c in range(0, 30):
		tile_map.set_cell(Vector2i(c, 10), 0, T_FLOOR)

	# Platform 1: row 7, cols 5–12 → 512px wide, y=448
	for c in range(5, 13):
		tile_map.set_cell(Vector2i(c, 7), 0, T_PLATFORM)

	# Platform 2: row 5, cols 16–23 → 512px wide, y=320
	for c in range(16, 24):
		tile_map.set_cell(Vector2i(c, 5), 0, T_PLATFORM)

	# Pillars flanking platforms
	_place_pillar(13, 8, 10)   # Right of P1
	_place_pillar(24, 6, 10)   # Right of P2

	# Torches (tile + point light)
	_place_torch(2, 9)    # Left wall
	_place_torch(12, 6)   # Above P1
	_place_torch(23, 4)   # Above P2
	_place_torch(27, 9)   # Right wall

	# Torch lights (warm orange-yellow, GradientTexture2D required by Godot 4)
	var lt := _make_light_texture()
	_add_light(Vector2(128, 576), Color(1.0, 0.65, 0.2), 2.5, lt)
	_add_light(Vector2(832, 384), Color(1.0, 0.65, 0.2), 2.0, lt)
	_add_light(Vector2(1536, 256), Color(1.0, 0.65, 0.2), 2.0, lt)
	_add_light(Vector2(1792, 576), Color(1.0, 0.65, 0.2), 2.5, lt)

	# Door frame on right side
	tile_map.set_cell(Vector2i(28, 8), 0, T_DOOR)
	tile_map.set_cell(Vector2i(28, 9), 0, T_DOOR)


## Create a shared radial gradient texture for all PointLight2D nodes.
## Godot 4 requires a texture; no texture → no light rendered.
func _make_light_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.width = 128
	gt.height = 128
	return gt


func _add_light(pos: Vector2, color: Color, tex_scale: float,
		texture: GradientTexture2D) -> void:
	var light := PointLight2D.new()
	light.position = pos
	light.color = color
	light.energy = 1.3
	light.texture_scale = tex_scale
	light.texture = texture
	add_child(light)


func _place_pillar(col: int, top_row: int, bottom_row: int) -> void:
	tile_map.set_cell(Vector2i(col, top_row), 0, T_PILLAR_TOP)
	for r in range(top_row + 1, bottom_row):
		tile_map.set_cell(Vector2i(col, r), 0, T_PILLAR_MID)
	tile_map.set_cell(Vector2i(col, bottom_row), 0, T_PILLAR_BASE)


func _place_torch(col: int, row: int) -> void:
	tile_map.set_cell(Vector2i(col, row), 0, T_TORCH_0)
	torch_positions.append(Vector2i(col, row))
