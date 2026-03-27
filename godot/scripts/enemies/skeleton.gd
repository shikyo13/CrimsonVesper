class_name Skeleton
extends CharacterBody2D
## Simple patrol skeleton enemy.
## Walks back and forth between two patrol points.

@export var patrol_distance: float = 200.0  ## Half-width of patrol range from spawn
@export var walk_speed: float       = 60.0
@export var gravity_scale: float    = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _dir: float = 1.0
var _origin_x: float
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	_origin_x = global_position.x
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += _gravity * delta
	else:
		velocity.y = 0.0

	# Patrol
	velocity.x = walk_speed * _dir

	# Reverse at patrol edges
	var dist = global_position.x - _origin_x
	if dist > patrol_distance and _dir > 0:
		_dir = -1.0
	elif dist < -patrol_distance and _dir < 0:
		_dir = 1.0

	# Also reverse on walls
	if is_on_wall():
		_dir *= -1.0

	sprite.flip_h = (_dir < 0)
	move_and_slide()
