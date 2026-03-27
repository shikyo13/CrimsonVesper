extends Area2D
## Fireball projectile used by both player and boss.
## Set `direction`, `damage`, and `hits_player` before adding to the scene tree.
## hits_player = false (default) → damages enemies only (player spell)
## hits_player = true           → damages player only (boss projectile)

const SPEED:        float = 400.0
const MAX_DISTANCE: float = 500.0

var direction:   float = 1.0
var damage:      int   = 8
var hits_player: bool  = false   ## true for boss fireballs

var _distance: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.flip_h = direction < 0.0
	sprite.play("fly")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	global_position.x += direction * step
	_distance += step
	if _distance >= MAX_DISTANCE:
		queue_free()


func _on_body_entered(body: Node) -> void:
	# Disappear on terrain contact
	if body is StaticBody2D:
		queue_free()
		return

	if hits_player:
		# Boss fireball — only harms the player
		if body.is_in_group("player"):
			body.take_damage(damage, global_position.x)
			queue_free()
	else:
		# Player fireball — harms enemies, ignores player
		if body.is_in_group("player"):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position.x)
		queue_free()
