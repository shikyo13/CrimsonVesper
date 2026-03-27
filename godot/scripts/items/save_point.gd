extends Area2D
## SavePoint — glowing crystal. Press interact (Y/E) while nearby to save.
## Pulses with a PointLight2D; flashes brightly on save confirmation.

const PULSE_SPEED: float = 2.0
const PULSE_MIN:   float = 0.5
const PULSE_MAX:   float = 1.0

var _player_nearby: bool  = false
var _time:          float = 0.0

@onready var light: PointLight2D = $PointLight2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false


func _process(delta: float) -> void:
	_time += delta
	light.energy = lerp(PULSE_MIN, PULSE_MAX, (sin(_time * PULSE_SPEED) + 1.0) * 0.5)


func _input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		_save()


func _save() -> void:
	var players := get_tree().get_nodes_in_group("player")
	var hp := players[0].current_hp if players.size() > 0 else 0
	var data := {
		"room_id":   RoomManager.current_room_id,
		"hp":        hp,
		"abilities": AbilityManager.get_save_data(),
		"inventory": InventoryManager.get_save_data(),
	}
	SaveManager.save_game(0, data)
	# Flash confirmation
	var tween := create_tween()
	tween.tween_property(light, "energy", 3.0, 0.1)
	tween.tween_property(light, "energy", PULSE_MAX, 0.4)
