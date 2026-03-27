extends CharacterBody2D
## Ghost enemy: floats toward player when in range, retreats when the player is
## attacking nearby. Phases through all terrain (collision_mask = 0).

const DEATH_BURST_SCENE = preload("res://scenes/vfx/death_burst.tscn")

# --- Config ---
@export var max_hp:          int   = 2
@export var attack_damage:   int   = 1
@export var xp_reward:       int   = 15
@export var move_speed:      float = 80.0
@export var detect_range:    float = 200.0
@export var retreat_range:   float = 120.0  ## Distance at which ghost retreats from attacking player

const HURT_DURATION:   float = 0.30
const RETREAT_DURATION: float = 1.0
const ATTACK_COOLDOWN:  float = 1.5
const KNOCKBACK_X:      float = 100.0

enum GhostState { IDLE, CHASE, RETREAT, HURT, DEAD }

var state: GhostState = GhostState.IDLE
var hp: int
var direction: float        = 1.0
var hurt_timer: float       = 0.0
var retreat_timer: float    = 0.0
var attack_cooldown: float  = 0.0
var player_ref: Node2D      = null

@onready var sprite:        AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D           = $AttackHitbox


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	modulate.a = 0.7
	# Ghost phases through all terrain — no collision mask
	collision_mask = 0
	sprite.play("float")
	attack_hitbox.monitoring = false
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if state == GhostState.DEAD:
		return

	attack_cooldown = max(0.0, attack_cooldown - delta)

	match state:
		GhostState.IDLE:    _do_idle(delta)
		GhostState.CHASE:   _do_chase(delta)
		GhostState.RETREAT: _do_retreat(delta)
		GhostState.HURT:    _do_hurt(delta)

	# Ghost uses direct position update — bypasses terrain collision entirely
	global_position += velocity * delta

	# Contact damage
	if state == GhostState.CHASE and attack_hitbox.monitoring:
		for body: Node2D in attack_hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				attack_hitbox.monitoring = false
				attack_cooldown = ATTACK_COOLDOWN
				body.take_damage(attack_damage, global_position.x)
				break

	# Re-enable hitbox after cooldown
	if attack_cooldown <= 0.0 and state == GhostState.CHASE:
		attack_hitbox.monitoring = true

	# Face movement direction
	if state != GhostState.HURT:
		sprite.flip_h = velocity.x < 0.0


func _do_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	if not player_ref:
		return
	if global_position.distance_to(player_ref.global_position) < detect_range:
		state = GhostState.CHASE
		attack_hitbox.monitoring = true


func _do_chase(delta: float) -> void:
	if not player_ref:
		state = GhostState.IDLE
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > detect_range * 1.5:
		state = GhostState.IDLE
		attack_hitbox.monitoring = false
		return

	# Retreat if player is in attack state nearby
	var player_attacking := _is_player_attacking()
	if player_attacking and dist < retreat_range:
		state = GhostState.RETREAT
		retreat_timer = RETREAT_DURATION
		return

	# Float toward player with gentle vertical tracking
	var to_player: Vector2 = (player_ref.global_position - global_position).normalized()
	velocity = to_player * move_speed


func _do_retreat(delta: float) -> void:
	retreat_timer -= delta
	if retreat_timer <= 0.0:
		state = GhostState.CHASE
		return
	if not player_ref:
		return
	# Move away from player
	var away: Vector2 = (global_position - player_ref.global_position).normalized()
	velocity = away * move_speed * 1.5


func _do_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_X * delta * 4.0)
	velocity.y = move_toward(velocity.y, 0.0, KNOCKBACK_X * delta * 4.0)
	if hurt_timer <= 0.0:
		state = GhostState.CHASE


func _is_player_attacking() -> bool:
	if not player_ref:
		return false
	var sm = player_ref.get_node_or_null("StateMachine")
	if sm == null:
		return false
	return sm.current_state != null and sm.current_state.name == "AttackState"


func take_damage(amount: int, source_x: float) -> void:
	if state == GhostState.DEAD:
		return
	hp -= amount
	attack_hitbox.monitoring = false
	# Knockback away from source
	var kdir := 1.0 if global_position.x >= source_x else -1.0
	velocity = Vector2(kdir * KNOCKBACK_X, -60.0)
	_flash_hurt()
	if hp <= 0:
		_die()
	else:
		state = GhostState.HURT
		hurt_timer = HURT_DURATION


func _flash_hurt() -> void:
	modulate = Color(1.5, 0.5, 0.5, 0.7)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and state != GhostState.DEAD:
		modulate = Color(1.0, 1.0, 1.0, 0.7)


func _die() -> void:
	state = GhostState.DEAD
	set_physics_process(false)
	attack_hitbox.monitoring = false
	_spawn_death_burst()
	_grant_rewards()
	# Fade out then free
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)


func _spawn_death_burst() -> void:
	var burst := DEATH_BURST_SCENE.instantiate()
	burst.global_position = global_position
	get_parent().add_child(burst)


func _grant_rewards() -> void:
	if GameManager.has_method("add_xp"):
		GameManager.add_xp(xp_reward)
