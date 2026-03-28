class_name Player
extends CharacterBody2D
## Root player node. Owns movement constants and shared physics helpers.
## HP is authoritative in StatsManager; player.gd owns invincibility and hurt-state logic.
## All per-state logic lives in scripts/player/states/.

# --- Tuning ---
@export var speed: float         = 200.0   ## Horizontal run speed (px/s)
@export var jump_force: float    = 520.0   ## Initial upward velocity on jump
@export var dash_speed: float    = 480.0   ## Horizontal speed during dash
@export var dash_duration: float = 0.18    ## Seconds the dash lasts
@export var attack_damage: int   = 2       ## Damage dealt per hit
@export var max_mp: int          = 50      ## Maximum mana points
@export var intelligence: int    = 5       ## INT stat — scales spell damage

# --- Signals ---
## Forwarded from StatsManager.hp_changed for any UI connected to the player node.
signal hp_changed(current_hp: int, max_hp: int)
signal mp_changed(current_mp: int, max_mp: int)

# --- Jump feel constants ---
const JUMP_CUT_MULTIPLIER: float = 0.45
const COYOTE_FRAMES: int         = 6

# --- Runtime state shared with states ---
var coyote_timer: int            = 0
var jump_released_early: bool    = false
var invincible: bool             = false
var iframes_timer: float         = 0.0
var attack_cooldown_timer: float = 0.0
var spell_cooldown_timer: float  = 0.0
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
	# Forward StatsManager HP/MP changes through the player's own signals for UI convenience
	StatsManager.hp_changed.connect(_on_stats_hp_changed)
	StatsManager.mp_changed.connect(_on_stats_mp_changed)
	camera = get_node_or_null("Camera2D")
	state_machine.change_state("idle")


func _on_stats_hp_changed(new_hp: int, new_max_hp: int) -> void:
	hp_changed.emit(new_hp, new_max_hp)


func _on_stats_mp_changed(new_mp: int, new_max_mp: int) -> void:
	mp_changed.emit(new_mp, new_max_mp)


func _physics_process(delta: float) -> void:
	# I-frames countdown with sprite flash
	if iframes_timer > 0.0:
		iframes_timer -= delta
		animated_sprite.visible = fmod(iframes_timer * 12.0, 1.0) > 0.5
		if iframes_timer <= 0.0:
			invincible = false
			animated_sprite.visible = true
	# Attack / spell cooldowns
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if spell_cooldown_timer > 0.0:
		spell_cooldown_timer -= delta
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
	if invincible or StatsManager.hp <= 0:
		return
	StatsManager.take_damage(amount)
	if StatsManager.hp <= 0:
		_die()
		return
	state_machine.change_state("hurt")
	var hurt_state = state_machine.states.get("hurt")
	if hurt_state:
		hurt_state.set_knockback(source_x)


func use_mp(amount: int) -> bool:
	return StatsManager.use_mp(amount)


func restore_mp(amount: int) -> void:
	StatsManager.restore_mp(amount)


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
	AudioManager.play_sfx("player_death", global_position)
	Engine.time_scale = 1.0
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	var game_over := preload("res://scenes/ui/game_over_screen.tscn").instantiate()
	get_tree().root.add_child(game_over)
