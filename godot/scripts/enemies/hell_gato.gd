extends CharacterBody2D
## Hell Gato: fast ground cat-demon. Patrols until player is in range,
## then launches a dash-attack lunge. Faster and more aggressive than the skeleton.

const DEATH_BURST_SCENE = preload("res://scenes/vfx/death_burst.tscn")

# --- Config ---
@export var patrol_distance: float = 120.0
@export var move_speed:      float = 120.0   ## Faster than skeleton (60)
@export var max_hp:          int   = 4
@export var attack_damage:   int   = 2
@export var attack_range:    float = 80.0
@export var detect_range:    float = 220.0
@export var xp_reward:       int   = 25

const GRAVITY:          float = 980.0
const DASH_SPEED:       float = 380.0
const DASH_DURATION:    float = 0.25
const ATTACK_COOLDOWN:  float = 1.8
const HURT_DURATION:    float = 0.20
const KNOCKBACK_X:      float = 200.0

enum CatState { PATROL, ALERT, DASH, HURT, DEAD }

var state: CatState    = CatState.PATROL
var hp: int
var start_x: float
var direction: float       = 1.0
var attack_timer: float    = 0.0
var hurt_timer: float      = 0.0
var dash_timer: float      = 0.0
var dash_dir: float        = 1.0
var hit_in_dash: bool      = false
var player_ref: Node2D     = null

@onready var sprite:        AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D           = $AttackHitbox


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	start_x = global_position.x
	sprite.play("run")
	attack_hitbox.monitoring = false
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if state == CatState.DEAD:
		return

	velocity.y += GRAVITY * delta

	match state:
		CatState.PATROL: _do_patrol(delta)
		CatState.ALERT:  _do_alert(delta)
		CatState.DASH:   _do_dash(delta)
		CatState.HURT:   _do_hurt(delta)

	move_and_slide()

	if state != CatState.HURT and state != CatState.DASH:
		sprite.flip_h = velocity.x < 0.0


func _do_patrol(delta: float) -> void:
	velocity.x = direction * move_speed
	var dist := global_position.x - start_x
	if dist > patrol_distance:
		direction = -1.0
	elif dist < -patrol_distance:
		direction = 1.0
	if sprite.animation != "run":
		sprite.play("run")
	if player_ref and global_position.distance_to(player_ref.global_position) < detect_range:
		state = CatState.ALERT


func _do_alert(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	if not player_ref:
		state = CatState.PATROL
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > detect_range * 1.5:
		state = CatState.PATROL
		return
	# Chase fast
	direction = sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed
	if sprite.animation != "run":
		sprite.play("run")
	# Launch dash-attack when in range
	if dist <= attack_range and attack_timer <= 0.0:
		_start_dash()


func _do_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = dash_dir * DASH_SPEED
	if sprite.animation != "run":
		sprite.play("run")

	# Poll for player hit during dash
	if not hit_in_dash and attack_hitbox.monitoring:
		for body: Node2D in attack_hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				hit_in_dash = true
				attack_hitbox.monitoring = false
				body.take_damage(attack_damage, global_position.x)
				break

	if dash_timer <= 0.0:
		attack_hitbox.monitoring = false
		attack_timer = ATTACK_COOLDOWN
		state = CatState.ALERT


func _do_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_X * delta * 4.0)
	if hurt_timer <= 0.0:
		state = CatState.ALERT


func _start_dash() -> void:
	state = CatState.DASH
	dash_dir = sign(player_ref.global_position.x - global_position.x)
	dash_timer = DASH_DURATION
	hit_in_dash = false
	sprite.flip_h = dash_dir < 0.0
	velocity.x = dash_dir * DASH_SPEED
	attack_hitbox.monitoring = true
	attack_hitbox.position.x = dash_dir * 20.0


func take_damage(amount: int, source_x: float) -> void:
	if state == CatState.DEAD:
		return
	hp -= amount
	attack_hitbox.monitoring = false
	var kdir := 1.0 if global_position.x >= source_x else -1.0
	velocity = Vector2(kdir * KNOCKBACK_X, -80.0)
	_flash_hurt()
	if hp <= 0:
		state = CatState.DEAD
		set_physics_process(false)
		_spawn_death_burst()
		_grant_rewards()
		# No dedicated death anim — flash and free after delay
		get_tree().create_timer(0.4).timeout.connect(func(): if is_instance_valid(self): queue_free())
	else:
		state = CatState.HURT
		hurt_timer = HURT_DURATION


func _flash_hurt() -> void:
	sprite.modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and state != CatState.DEAD:
		sprite.modulate = Color.WHITE


func _spawn_death_burst() -> void:
	var burst := DEATH_BURST_SCENE.instantiate()
	burst.global_position = global_position
	get_parent().add_child(burst)


func _grant_rewards() -> void:
	if GameManager.has_method("add_xp"):
		GameManager.add_xp(xp_reward)
