extends Node2D
## Corridor — narrow connecting room with vertical platforming.
## Church tileset (runtime), darker lighting, 2 ghosts + 1 skeleton.
## Iron Sword pickup on upper platform.
## Door left → Entry Hall (SpawnRight), door right → Pre-Boss (SpawnLeft).

# Atlas coords — church_tileset.png is a 16px-grid pack like cemetery.
# Coords 0–3 in row 0 correspond to ground/wall/platform/misc.
const T_BG       := Vector2i(1, 0)
const T_FLOOR    := Vector2i(0, 0)
const T_WALL     := Vector2i(2, 0)
const T_PLATFORM := Vector2i(3, 0)
const T_PILLAR   := Vector2i(0, 1)

@onready var tile_map:   TileMapLayer = $TileMapLayer
@onready var hp_label:   Label        = $HUD/HPLabel
@onready var door_left:  Area2D       = $DoorLeft
@onready var door_right: Area2D       = $DoorRight


func _ready() -> void:
	RoomManager.current_room_id = "corridor"
	tile_map.tile_set = _create_tileset()
	_build_room()
	var player := $Player
	player.hp_changed.connect(_on_player_hp_changed)
	hp_label.text = "HP: %d / %d" % [StatsManager.hp, StatsManager.max_hp]
	_place_player(player)
	door_left.body_entered.connect(_on_door_left)
	door_right.body_entered.connect(_on_door_right)
	RoomManager.fade_in()


func _place_player(player: Node) -> void:
	var spawn := get_node_or_null(RoomManager.get_spawn_point_name())
	if spawn:
		player.global_position = spawn.global_position


func _on_player_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, max_val]


func _on_door_left(_body: Node) -> void:
	RoomManager.transition_to("res://scenes/rooms/entry_hall.tscn", "SpawnRight")


func _on_door_right(_body: Node) -> void:
	RoomManager.transition_to("res://scenes/rooms/pre_boss.tscn", "SpawnLeft")


# --- Tileset (runtime, church_tileset.png) ---

func _create_tileset() -> TileSet:
	var ts  := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tilesets/church_tileset.png")
	src.texture_region_size = Vector2i(16, 16)
	for row in 4:
		for col in 4:
			src.create_tile(Vector2i(col, row))
	ts.add_source(src, 0)
	return ts


# --- Room layout ---
# Three tiers of platforms for vertical traversal.
# Platform 1 (bottom):  y=448, x=0–512
# Platform 2 (middle):  y=320, x=576–1152
# Platform 3 (high):    y=192, x=1024–1600  ← Iron Sword here

func _build_room() -> void:
	# Background
	for r in range(0, 11):
		for c in range(0, 30):
			tile_map.set_cell(Vector2i(c, r), 0, T_BG)
	# Walls
	for r in range(0, 11):
		tile_map.set_cell(Vector2i(0, r), 0, T_WALL)
		tile_map.set_cell(Vector2i(29, r), 0, T_WALL)
	# Visual floor
	for c in range(0, 30):
		tile_map.set_cell(Vector2i(c, 10), 0, T_FLOOR)
	# Platform tiers
	for c in range(0, 9):    # P1 left
		tile_map.set_cell(Vector2i(c, 7), 0, T_PLATFORM)
	for c in range(9, 19):   # P2 mid
		tile_map.set_cell(Vector2i(c, 5), 0, T_PLATFORM)
	for c in range(16, 26):  # P3 high (Iron Sword)
		tile_map.set_cell(Vector2i(c, 3), 0, T_PLATFORM)
	# Pillars
	for r in range(8, 11):
		tile_map.set_cell(Vector2i(9, r), 0, T_PILLAR)
	for r in range(6, 11):
		tile_map.set_cell(Vector2i(19, r), 0, T_PILLAR)

	# Atmospheric lights (very dark room)
	var lt := _make_light_texture()
	_add_light(Vector2(64, 576),  Color(0.5, 0.5, 0.9), 1.8, lt)   # Left
	_add_light(Vector2(640, 384), Color(0.5, 0.5, 0.9), 1.5, lt)   # Mid
	_add_light(Vector2(1280, 256),Color(0.6, 0.4, 1.0), 1.5, lt)   # Upper (purple)
	_add_light(Vector2(1856, 576),Color(0.5, 0.5, 0.9), 1.8, lt)   # Right


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
	light.energy = 1.1
	light.texture_scale = tex_scale
	light.texture = texture
	add_child(light)
