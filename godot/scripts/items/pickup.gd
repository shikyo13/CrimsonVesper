extends Area2D
## Generic pickup: bobs in place, collected on player touch.
## Set item_id to the inventory key (e.g. "health_potion", "iron_sword").
## Set is_ability = true to unlock an AbilityManager ability instead.

@export var item_id:    String = "health_potion"
@export var is_ability: bool   = false

const BOB_SPEED:  float = 2.5   # radians per second
const BOB_HEIGHT: float = 6.0   # pixels up/down

var _origin_y: float
var _time:     float = 0.0


func _ready() -> void:
	_origin_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	position.y = _origin_y + sin(_time * BOB_SPEED) * BOB_HEIGHT


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_ability:
		AbilityManager.unlock_ability(item_id)
	else:
		InventoryManager.add_item(item_id)
	queue_free()
