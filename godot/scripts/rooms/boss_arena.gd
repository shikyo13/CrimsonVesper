extends Node2D
## Boss Arena — large flat room designed for a boss fight.
## Cemetery tileset (runtime). Red/purple dramatic lighting.
## On enter: door slams shut. On boss death: door opens, loot drops.

const T_BG       := Vector2i(1, 2)
const T_FLOOR    := Vector2i(0, 0)
const T_WALL     := Vector2i(1, 0)
const T_PLATFORM := Vector2i(2, 0)
const T_DOOR     := Vector2i(3, 2)
const T_PILLAR_T := Vector2i(3, 0)
const T_PILLAR_M := Vector2i(0, 1)
const T_PILLAR_B := Vector2i(1, 1)

@onready var tile_map:    TileMapLayer = $TileMapLayer
@onready var hp_label:    Label        = $HUD/HPLabel
@onready var door_left:   Area2D       = $DoorLeft
@onready var boss:        Node2D       = $Boss

var _boss_defeated: bool = false
var _loot_spawned:  bool = false


func _ready() -> void:
	RoomManager.current_room_id = "boss_arena"
	tile_map.tile_set = _create_tileset()
	_build_room()
	var player := $Player
	player.hp_changed.connect(_on_player_hp_changed)
	hp_label.text = "HP: %d / %d" % [player.current_hp, player.max_hp]
	_place_player(player)
	# Lock the exit door when the arena is entered.
	door_left.monitoring = false
	door_left.monitorable = false
	# Watch for boss death.
	_watch_boss()
	RoomManager.fade_in()


func _place_player(player: Node) -> void:
	var spawn := get_node_or_null(RoomManager.get_spawn_point_name())
	if spawn:
		player.global_position = spawn.global_position


func _on_player_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, max_val]


## Poll each frame for boss death (boss is just a scaled skeleton placeholder).
func _process(_delta: float) -> void:
	if _boss_defeated or not is_instance_valid(boss):
		if not _loot_spawned:
			_on_boss_defeated()
		return
	# Boss is still valid; nothing to do here beyond the tree signal.


func _watch_boss() -> void:
	if is_instance_valid(boss):
		boss.tree_exited.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	if _loot_spawned:
		return
	_boss_defeated = true
	_loot_spawned  = true
	# Unlock the left door so the player can leave.
	door_left.monitoring  = true
	door_left.monitorable = true
	door_left.body_entered.connect(_on_door_left)
	# Drop a key equipment piece as reward.
	_spawn_loot(Vector2(960, 560))
	# Flash the arena lights red briefly to signal victory.
	_flash_victory()


func _on_door_left(_body: Node) -> void:
	RoomManager.transition_to("res://scenes/rooms/pre_boss.tscn", "SpawnRight")


func _spawn_loot(pos: Vector2) -> void:
	var pickup_scene: PackedScene = load("res://scenes/items/pickup.tscn")
	var loot: Area2D = pickup_scene.instantiate()
	loot.position = pos
	loot.set("item_id", "crimson_armor")
	add_child(loot)


func _flash_victory() -> void:
	# Briefly flood the room with a bright white flash.
	var mod := CanvasModulate.new()
	mod.color = Color(1.2, 1.2, 1.2)
	add_child(mod)
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(mod):
		mod.queue_free()


# --- Tileset (runtime, cemetery) ---

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
# Wider room (3840px, camera scrolls). Flat floor with flanking pillars.
# Boss spawns at center. Player enters from left side.

func _build_room() -> void:
	# Background (60 cols × 11 rows)
	for r in range(0, 11):
		for c in range(0, 60):
			tile_map.set_cell(Vector2i(c, r), 0, T_BG)
	# Walls
	for r in range(0, 11):
		tile_map.set_cell(Vector2i(0,  r), 0, T_WALL)
		tile_map.set_cell(Vector2i(59, r), 0, T_WALL)
	# Visual floor
	for c in range(0, 60):
		tile_map.set_cell(Vector2i(c, 10), 0, T_FLOOR)
	# Flanking pillars for drama
	_place_pillar(5,  6, 10)
	_place_pillar(10, 6, 10)
	_place_pillar(49, 6, 10)
	_place_pillar(54, 6, 10)
	# Boss door tiles (locked entry) — right half of room
	tile_map.set_cell(Vector2i(1, 8), 0, T_DOOR)
	tile_map.set_cell(Vector2i(1, 9), 0, T_DOOR)

	# Dramatic red/purple lights
	var lt := _make_light_texture()
	_add_light(Vector2(320,   550), Color(0.9, 0.2, 0.2), 3.0, lt)  # Red left
	_add_light(Vector2(1920,  400), Color(0.6, 0.1, 0.8), 3.5, lt)  # Purple center
	_add_light(Vector2(1920,  550), Color(0.9, 0.2, 0.2), 2.5, lt)  # Red center
	_add_light(Vector2(3520,  550), Color(0.9, 0.2, 0.2), 3.0, lt)  # Red right


func _place_pillar(col: int, top_row: int, bottom_row: int) -> void:
	tile_map.set_cell(Vector2i(col, top_row), 0, T_PILLAR_T)
	for r in range(top_row + 1, bottom_row):
		tile_map.set_cell(Vector2i(col, r), 0, T_PILLAR_M)
	tile_map.set_cell(Vector2i(col, bottom_row), 0, T_PILLAR_B)


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
	light.energy = 1.5
	light.texture_scale = tex_scale
	light.texture = texture
	add_child(light)
