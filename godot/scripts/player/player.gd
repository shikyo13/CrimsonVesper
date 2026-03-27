class_name Player
extends CharacterBody2D
## Root player node. Owns movement constants and shared physics helpers.
## All per-state logic lives in scripts/player/states/.

# --- Tuning (adjust in Inspector) ---
@export var speed: float         = 200.0  ## Horizontal run speed (px/s)
@export var jump_force: float    = 520.0  ## Initial upward velocity on jump
@export var dash_speed: float    = 480.0  ## Horizontal speed during dash
@export var dash_duration: float = 0.18  ## Seconds the dash lasts

# --- Jump feel constants ---
const JUMP_CUT_MULTIPLIER: float = 0.45  ## Multiplier applied to upward vel on early release
const COYOTE_FRAMES: int         = 6     ## Physics frames of grace after walking off an edge

# --- Runtime state shared with states ---
var coyote_timer: int      = 0
var jump_released_early: bool = false

# --- Cached nodes ---
@onready var state_machine: Node             = $StateMachine  ## Node type for headless compat; cast to StateMachine in editor
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Physics ---
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	state_machine.change_state("idle")

# --- Helpers called by states ---

func apply_gravity(delta: float) -> void:
	## Accumulates downward velocity. Call every physics frame in airborne states.
	if not is_on_floor():
		velocity.y += _gravity * delta

func tick_coyote() -> void:
	## Call in idle/run states (resets to max) and fall state (counts down).
	## Never call in jump state — that would allow coyote double-jumps.
	if is_on_floor():
		coyote_timer = COYOTE_FRAMES
	elif coyote_timer > 0:
		coyote_timer -= 1

func is_coyote_active() -> bool:
	return coyote_timer > 0

func play_anim(anim_name: String) -> void:
	## Safe animation play — no-ops if SpriteFrames not yet assigned or animation missing.
	if animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
