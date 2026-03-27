extends CharacterBody2D
## Ghost enemy: floats toward player with no gravity, deals contact damage.
## Uses cemetery ghost sprites (4-frame loop).

@export var move_speed:    float = 80.0
@export var max_hp:        int   = 2
@export var attack_damage: int   = 1
@export var detect_range:  float = 300.0

const HURT_DURATION: float  = 0.4
const KNOCKBACK_XY:  float  = 160.0

enum GhostState { IDLE, CHASE, HURT, DEAD }

var state:      GhostState = GhostState.IDLE
var hp:         int
var hurt_timer: float  = 0.0
var player_ref: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	sprite.play("float")
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if state == GhostState.DEAD:
		return

	match state:
		GhostState.IDLE:  _do_idle()
		GhostState.CHASE: _do_chase()
		GhostState.HURT:  _do_hurt(delta)

	move_and_slide()

	# Contact damage when chasing
	if state == GhostState.CHASE:
		for i in get_slide_collision_count():
			var body := get_slide_collision(i).get_collider()
			if body != null and body.is_in_group("player"):
				body.take_damage(attack_damage, global_position.x)


func _do_idle() -> void:
	velocity = Vector2.ZERO
	if player_ref and global_position.distance_to(player_ref.global_position) < detect_range:
		state = GhostState.CHASE


func _do_chase() -> void:
	if not player_ref:
		state = GhostState.IDLE
		return
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * move_speed
	sprite.flip_h = velocity.x < 0.0


func _do_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, KNOCKBACK_XY * 3.0 * delta)
	if hurt_timer <= 0.0:
		state = GhostState.CHASE


func take_damage(amount: int, source_x: float) -> void:
	if state == GhostState.DEAD:
		return
	hp -= amount
	var kdir := 1.0 if global_position.x >= source_x else -1.0
	velocity = Vector2(kdir * KNOCKBACK_XY, -KNOCKBACK_XY * 0.5)
	_flash_hurt()
	if hp <= 0:
		_die()
	else:
		state = GhostState.HURT
		hurt_timer = HURT_DURATION


func _flash_hurt() -> void:
	sprite.modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and state != GhostState.DEAD:
		sprite.modulate = Color.WHITE


func _die() -> void:
	state = GhostState.DEAD
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
