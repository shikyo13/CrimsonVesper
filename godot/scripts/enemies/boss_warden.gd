extends CharacterBody2D
## The Crimson Warden — introductory boss fight.
## Three phases triggered by HP thresholds.
## Emits phase_changed, hp_changed, and boss_defeated signals.

signal phase_changed(new_phase: int)
signal boss_defeated
signal hp_changed(current_hp: int, max_hp: int)

# --- Config ---
@export var max_hp:    int = 100
@export var xp_reward: int = 200

const GRAVITY:      float = 980.0
const KNOCKBACK_X:  float = 160.0

## Phase data: speed, swing windup time, attack rate (s between attacks), tint
const PHASE_DATA := {
	1: { "speed": 80.0,  "windup": 1.5, "rate": 3.0, "tint": Color(1.0, 1.0, 1.0) },
	2: { "speed": 140.0, "windup": 1.0, "rate": 2.0, "tint": Color(1.0, 1.0, 1.0) },
	3: { "speed": 180.0, "windup": 0.7, "rate": 1.5, "tint": Color(1.5, 0.4, 0.4) },
}

const PHASE2_THRESHOLD: int = 60
const PHASE3_THRESHOLD: int = 30

const DEATH_BURST_SCENE   = preload("res://scenes/vfx/death_burst.tscn")
const SKELETON_SCENE      = preload("res://scenes/enemies/skeleton.tscn")
const BOSS_FIREBALL_SCENE = preload("res://scenes/player/fireball.tscn")

enum BossState {
	IDLE,
	CHASE,
	SWING_WINDUP,
	SWINGING,
	FIREBALL_CAST,
	DASH,
	SUMMON,
	TRANSITION,
	HURT,
	DEAD,
}

var hp: int
var phase: int           = 1
var state: BossState     = BossState.IDLE
var direction: float     = 1.0
var player_ref: Node2D   = null

# Cached from PHASE_DATA
var move_speed:   float = 80.0
var swing_windup: float = 1.5
var attack_rate:  float = 3.0

# Timers
var attack_timer:     float = 0.0
var windup_timer:     float = 0.0
var hurt_timer:       float = 0.0
var transition_timer: float = 0.0
var dash_timer:       float = 0.0

var minions_summoned: bool = false

@onready var sprite:        AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D           = $AttackHitbox


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	hp = max_hp
	_apply_phase_data()
	sprite.play("idle")
	attack_hitbox.monitoring = false
	call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if state == BossState.DEAD:
		return

	velocity.y += GRAVITY * delta
	if attack_timer > 0.0:
		attack_timer -= delta

	match state:
		BossState.IDLE:          _do_idle()
		BossState.CHASE:         _do_chase(delta)
		BossState.SWING_WINDUP:  _do_swing_windup(delta)
		BossState.SWINGING:      _do_swinging(delta)
		BossState.FIREBALL_CAST: _do_fireball_cast(delta)
		BossState.DASH:          _do_dash(delta)
		BossState.TRANSITION:    _do_transition(delta)
		BossState.HURT:          _do_hurt(delta)

	move_and_slide()

	if state not in [BossState.HURT, BossState.SWINGING, BossState.TRANSITION]:
		if velocity.x != 0.0:
			sprite.flip_h = velocity.x < 0.0


# ---- State handlers ----

func _do_idle() -> void:
	velocity.x = 0.0
	if player_ref:
		state = BossState.CHASE


func _do_chase(delta: float) -> void:
	if not player_ref:
		return
	direction = sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * move_speed

	if sprite.animation != "idle":
		sprite.play("idle")

	if attack_timer > 0.0:
		return

	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= 110.0:
		_start_swing_windup()
	elif phase >= 2 and dist <= 260.0 and randf() < 0.35:
		_start_dash()
	else:
		_start_fireball()


func _do_swing_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 6.0)
	windup_timer -= delta
	if windup_timer <= 0.0:
		state = BossState.SWINGING
		attack_hitbox.monitoring = true
		attack_hitbox.position.x = direction * 40.0
		sprite.play("attack")


func _do_swinging(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 3.0)
	for body: Node2D in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			attack_hitbox.monitoring = false
			body.take_damage(2, global_position.x)
			break
	if not sprite.is_playing() and sprite.animation == "attack":
		attack_hitbox.monitoring = false
		attack_timer = attack_rate
		state = BossState.CHASE


func _do_fireball_cast(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
	windup_timer -= delta
	if windup_timer <= 0.0:
		_launch_fireballs()
		attack_timer = attack_rate
		state = BossState.CHASE
		sprite.play("idle")


func _do_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = direction * 350.0
	for body: Node2D in attack_hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			attack_hitbox.monitoring = false
			body.take_damage(2, global_position.x)
			break
	if dash_timer <= 0.0:
		attack_hitbox.monitoring = false
		attack_timer = attack_rate
		state = BossState.CHASE


func _do_transition(delta: float) -> void:
	velocity.x = 0.0
	transition_timer -= delta
	if transition_timer <= 0.0:
		state = BossState.CHASE
		attack_timer = attack_rate


func _do_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_X * delta * 4.0)
	if hurt_timer <= 0.0:
		state = BossState.CHASE


# ---- Action starters ----

func _start_swing_windup() -> void:
	state = BossState.SWING_WINDUP
	windup_timer = swing_windup
	if player_ref:
		direction = sign(player_ref.global_position.x - global_position.x)
	sprite.flip_h = direction < 0.0
	# Yellow telegraph tint during windup
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.2, 0.3), windup_timer * 0.7)
	tween.tween_property(sprite, "modulate", PHASE_DATA[phase]["tint"], 0.15)


func _start_fireball() -> void:
	state = BossState.FIREBALL_CAST
	windup_timer = 0.4
	sprite.play("attack")


func _start_dash() -> void:
	state = BossState.DASH
	if player_ref:
		direction = sign(player_ref.global_position.x - global_position.x)
	dash_timer = 0.22
	sprite.flip_h = direction < 0.0
	attack_hitbox.monitoring = true
	attack_hitbox.position.x = direction * 40.0


func _launch_fireballs() -> void:
	if not player_ref:
		return
	var dir := sign(player_ref.global_position.x - global_position.x)
	# Phase 1: single shot. Phase 2+: 3-shot vertical spread.
	var y_offsets: Array = [-20.0] if phase == 1 else [-44.0, -22.0, 0.0]
	for y_off in y_offsets:
		var fb := BOSS_FIREBALL_SCENE.instantiate()
		fb.global_position = global_position + Vector2(dir * 32.0, y_off)
		fb.direction = dir
		fb.damage = 2
		fb.hits_player = true
		get_parent().add_child(fb)


func _start_summon() -> void:
	if minions_summoned:
		return
	minions_summoned = true
	state = BossState.SUMMON
	for x_off in [-180.0, 180.0]:
		var skel := SKELETON_SCENE.instantiate()
		skel.global_position = global_position + Vector2(x_off, 0.0)
		get_parent().add_child(skel)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(self) and state == BossState.SUMMON:
			state = BossState.CHASE
	)


# ---- Damage and phase transitions ----

func take_damage(amount: int, source_x: float) -> void:
	if state == BossState.DEAD or state == BossState.TRANSITION:
		return
	hp -= amount
	hp_changed.emit(max(0, hp), max_hp)
	attack_hitbox.monitoring = false

	var kdir := 1.0 if global_position.x >= source_x else -1.0
	velocity = Vector2(kdir * KNOCKBACK_X * 0.4, -30.0)  ## Boss staggers less
	_flash_hurt()

	# Phase transitions take priority over death check
	if hp <= PHASE3_THRESHOLD and phase < 3:
		_enter_phase(3)
		return
	if hp <= PHASE2_THRESHOLD and phase < 2:
		_enter_phase(2)
		return

	if hp <= 0:
		_die()
		return

	state = BossState.HURT
	hurt_timer = 0.20


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	_apply_phase_data()
	phase_changed.emit(new_phase)

	state = BossState.TRANSITION
	transition_timer = 1.0
	attack_hitbox.monitoring = false

	# Visual "roar" — scale pulse
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.10)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)

	sprite.modulate = PHASE_DATA[phase]["tint"]

	# Phase 3 summon
	if new_phase == 3 and not minions_summoned:
		get_tree().create_timer(1.3).timeout.connect(func():
			if is_instance_valid(self) and state != BossState.DEAD:
				_start_summon()
		)

	# Screen shake on transition
	if player_ref and player_ref.has_method("screen_shake"):
		player_ref.screen_shake(6.0, 0.4)


func _apply_phase_data() -> void:
	var data: Dictionary = PHASE_DATA[phase]
	move_speed   = data["speed"]
	swing_windup = data["windup"]
	attack_rate  = data["rate"]


func _flash_hurt() -> void:
	var base_tint: Color = PHASE_DATA[phase]["tint"]
	sprite.modulate = Color(2.0, 0.8, 0.8)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and state != BossState.DEAD:
		sprite.modulate = base_tint


func _die() -> void:
	state = BossState.DEAD
	set_physics_process(false)
	attack_hitbox.monitoring = false

	if player_ref and player_ref.has_method("screen_shake"):
		player_ref.screen_shake(10.0, 0.6)

	# Staggered death bursts
	for i in 5:
		get_tree().create_timer(i * 0.28).timeout.connect(func():
			if is_instance_valid(self):
				var burst := DEATH_BURST_SCENE.instantiate()
				burst.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 20))
				get_parent().add_child(burst)
		)

	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		boss_defeated.emit()
		queue_free()
	)
