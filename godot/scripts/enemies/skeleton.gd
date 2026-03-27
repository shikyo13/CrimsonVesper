extends CharacterBody2D
## Skeleton enemy: patrols, alerts when player is nearby, swings a melee attack,
## takes 3 hits to kill, plays death animation, then frees itself.

# --- Config ---
@export var patrol_distance: float = 150.0
@export var move_speed:      float = 60.0
@export var max_hp:          int   = 3
@export var attack_damage:   int   = 1
@export var attack_range:    float = 55.0
@export var alert_range:     float = 220.0

const GRAVITY:         float = 980.0
const ATTACK_COOLDOWN: float = 1.2
const HURT_DURATION:   float = 0.30
const KNOCKBACK_X:     float = 180.0

# Renamed from State to avoid conflict with player/state.gd class_name State
enum EnemyState { PATROL, ALERT, ATTACK, HURT, DEAD }

var state: EnemyState = EnemyState.PATROL
var hp: int
var start_x: float
var direction: float          = 1.0
var attack_timer: float       = 0.0
var hurt_timer: float         = 0.0
var attack_windup_timer: float = 0.0
var player_ref: Node2D        = null

@onready var sprite:        AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D           = $AttackHitbox


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	start_x = global_position.x
	sprite.play("walk")
	attack_hitbox.monitoring = false
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	velocity.y += GRAVITY * delta

	match state:
		EnemyState.PATROL: _do_patrol(delta)
		EnemyState.ALERT:  _do_alert(delta)
		EnemyState.ATTACK: _do_attack(delta)
		EnemyState.HURT:   _do_hurt(delta)

	move_and_slide()

	if state != EnemyState.HURT and state != EnemyState.ATTACK:
		sprite.flip_h = velocity.x < 0.0


func _do_patrol(delta: float) -> void:
	velocity.x = direction * move_speed
	var dist := global_position.x - start_x
	if dist > patrol_distance:
		direction = -1.0
	elif dist < -patrol_distance:
		direction = 1.0
	if sprite.animation != "walk":
		sprite.play("walk")
	if player_ref and global_position.distance_to(player_ref.global_position) < alert_range:
		state = EnemyState.ALERT


func _do_alert(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	if not player_ref:
		state = EnemyState.PATROL
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > alert_range * 1.5:
		state = EnemyState.PATROL
		return
	# Chase player
	direction = sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.5
	if sprite.animation != "walk":
		sprite.play("walk")
	if dist <= attack_range and attack_timer <= 0.0:
		_start_attack()


func _do_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 8.0)
	# Windup before hitbox activates
	if attack_windup_timer > 0.0:
		attack_windup_timer -= delta
		if attack_windup_timer <= 0.0:
			attack_hitbox.monitoring = true
	# Poll for player during active hitbox
	if attack_hitbox.monitoring:
		for body: Node2D in attack_hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				attack_hitbox.monitoring = false
				body.take_damage(attack_damage, global_position.x)
				break
	# End attack when animation finishes
	if not sprite.is_playing() and sprite.animation == "attack":
		attack_hitbox.monitoring = false
		attack_timer = ATTACK_COOLDOWN
		state = EnemyState.ALERT


func _do_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_X * delta * 4.0)
	if hurt_timer <= 0.0:
		state = EnemyState.ALERT


func _start_attack() -> void:
	state = EnemyState.ATTACK
	sprite.play("attack")
	sprite.flip_h = direction < 0.0
	attack_windup_timer = 0.12
	attack_hitbox.monitoring = false
	attack_hitbox.position.x = direction * 24.0


func take_damage(amount: int, source_x: float) -> void:
	if state == EnemyState.DEAD:
		return
	hp -= amount
	attack_hitbox.monitoring = false
	# Knockback away from hit source
	var kdir := 1.0 if global_position.x >= source_x else -1.0
	velocity = Vector2(kdir * KNOCKBACK_X, -80.0)
	_flash_hurt()
	if hp <= 0:
		state = EnemyState.DEAD
		sprite.play("death")
		set_physics_process(false)
		AudioManager.play_sfx("enemy_death", global_position)
		sprite.animation_finished.connect(_on_death_anim_done, CONNECT_ONE_SHOT)
	else:
		state = EnemyState.HURT
		hurt_timer = HURT_DURATION
		AudioManager.play_sfx("enemy_hit", global_position)


func _flash_hurt() -> void:
	sprite.modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and state != EnemyState.DEAD:
		sprite.modulate = Color.WHITE


func _on_death_anim_done() -> void:
	queue_free()
