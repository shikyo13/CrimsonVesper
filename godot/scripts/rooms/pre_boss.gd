extends Node2D
## Pre-Boss Room — transitional room before the boss arena.
## Town tileset (runtime), save point, fireball spell pickup, mana potion.
## Door left → Corridor (SpawnRight), door right → Boss Arena (SpawnLeft).

const T_BG       := Vector2i(0, 0)
const T_FLOOR    := Vector2i(1, 0)
const T_WALL     := Vector2i(2, 0)
const T_PLATFORM := Vector2i(3, 0)
const T_DOOR     := Vector2i(0, 1)

@onready var tile_map:   TileMapLayer = $TileMapLayer
@onready var hp_label:   Label        = $HUD/HPLabel
@onready var door_left:  Area2D       = $DoorLeft
@onready var door_right: Area2D       = $DoorRight


func _ready() -> void:
	RoomManager.current_room_id = "pre_boss"
	tile_map.tile_set = _create_tileset()
	_build_room()
	var player := $Player
	player.hp_changed.connect(_on_player_hp_changed)
	hp_label.text = "HP: %d / %d" % [player.current_hp, player.max_hp]
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
	RoomManager.transition_to("res://scenes/rooms/corridor.tscn", "SpawnRight")


func _on_door_right(_body: Node) -> void:
	RoomManager.transition_to("res://scenes/rooms/boss_arena.tscn", "SpawnLeft")


# --- Tileset (runtime, town_tileset.png) ---

func _create_tileset() -> TileSet:
	var ts  := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tilesets/town_tileset.png")
	src.texture_region_size = Vector2i(16, 16)
	for row in 4:
		for col in 4:
			src.create_tile(Vector2i(col, row))
	ts.add_source(src, 0)
	return ts


# --- Room layout ---
# Open area with a central platform for pickups. Large door arch on right.
# Platform center: y=380, x=640–1280

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
	# Central platform (save + pickups)
	for c in range(10, 21):
		tile_map.set_cell(Vector2i(c, 6), 0, T_PLATFORM)
	# Boss door arch (right side, imposing double-width frame)
	for r in range(5, 10):
		tile_map.set_cell(Vector2i(27, r), 0, T_DOOR)
		tile_map.set_cell(Vector2i(28, r), 0, T_DOOR)

	# Warm atmospheric lights (town feel, torches in sconces)
	var lt := _make_light_texture()
	_add_light(Vector2(128,  576), Color(1.0, 0.75, 0.3), 2.5, lt)
	_add_light(Vector2(960,  350), Color(1.0, 0.80, 0.4), 2.0, lt)   # Above platform
	_add_light(Vector2(1792, 576), Color(1.0, 0.75, 0.3), 2.5, lt)
	_add_light(Vector2(1760, 350), Color(0.8, 0.3,  0.3), 3.0, lt)   # Red boss-door glow


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
	light.energy = 1.2
	light.texture_scale = tex_scale
	light.texture = texture
	add_child(light)
