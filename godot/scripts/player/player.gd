class_name Player
extends CharacterBody2D
## Root player node. Owns movement constants and shared physics helpers.
## All per-state logic lives in scripts/player/states/.

# --- Tuning ---
@export var speed: float         = 200.0   ## Horizontal run speed (px/s)
@export var jump_force: float    = 520.0   ## Initial upward velocity on jump
@export var dash_speed: float    = 480.0   ## Horizontal speed during dash
@export var dash_duration: float = 0.18    ## Seconds the dash lasts
@export var max_hp: int          = 5       ## Maximum hit points
@export var attack_damage: int   = 2       ## Damage dealt per hit

# --- Signals ---
signal hp_changed(current_hp: int, max_hp: int)

# --- Jump feel constants ---
const JUMP_CUT_MULTIPLIER: float = 0.45
const COYOTE_FRAMES: int         = 6

# --- Runtime state shared with states ---
var coyote_timer: int            = 0
var jump_released_early: bool    = false
var current_hp: int
var invincible: bool             = false
var iframes_timer: float         = 0.0
var attack_cooldown_timer: float = 0.0
var facing_dir: float            = 1.0

# --- Cached nodes ---
@onready var state_machine: Node              = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D            = $AttackHitbox

var camera: Camera2D  ## Assigned in _ready via get_node_or_null (lives in room scene)

# --- Physics ---
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	camera = get_node_or_null("Camera2D")
	state_machine.change_state("idle")


func _physics_process(delta: float) -> void:
	# I-frames countdown with sprite flash
	if iframes_timer > 0.0:
		iframes_timer -= delta
		animated_sprite.visible = fmod(iframes_timer * 12.0, 1.0) > 0.5
		if iframes_timer <= 0.0:
			invincible = false
			animated_sprite.visible = true
	# Attack cooldown
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	# Camera lookahead
	if camera:
		var target_x := facing_dir * 40.0
		camera.offset.x = lerp(camera.offset.x, target_x, 0.08)


# --- Helpers called by states ---

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta


func tick_coyote() -> void:
	if is_on_floor():
		coyote_timer = COYOTE_FRAMES
	elif coyote_timer > 0:
		coyote_timer -= 1


func is_coyote_active() -> bool:
	return coyote_timer > 0


func play_anim(anim_name: String) -> void:
	if animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


# --- Combat ---

func take_damage(amount: int, source_x: float) -> void:
	if invincible or current_hp <= 0:
		return
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()
		return
	state_machine.change_state("hurt")
	var hurt_state = state_machine.states.get("hurt")
	if hurt_state:
		hurt_state.set_knockback(source_x)


func start_iframes(duration: float) -> void:
	invincible = true
	iframes_timer = duration


func trigger_hitstop(duration: float = 0.05) -> void:
	Engine.time_scale = 0.1
	get_tree().create_timer(duration, true, false, true).timeout.connect(
		func(): Engine.time_scale = 1.0
	)


func screen_shake(strength: float = 3.0, duration: float = 0.1) -> void:
	if camera == null:
		return
	var tween := create_tween()
	var step := duration / 6.0
	for i in 6:
		tween.tween_property(camera, "offset",
			Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), step)
	tween.tween_property(camera, "offset", Vector2.ZERO, step)


func _die() -> void:
	## Simple respawn — replace with death screen in a later pass.
	global_position = Vector2(200, 540)
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	invincible = false
	iframes_timer = 0.0
	velocity = Vector2.ZERO
	Engine.time_scale = 1.0
	state_machine.change_state("idle")
