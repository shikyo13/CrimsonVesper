extends CharacterBody2D

@export var patrol_distance: float = 200.0
@export var move_speed: float = 60.0

const GRAVITY: float = 980.0

var start_x: float
var direction: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_x = global_position.x
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	velocity.x = direction * move_speed
	velocity.y += GRAVITY * delta
	move_and_slide()

	var dist: float = global_position.x - start_x
	if dist > patrol_distance:
		direction = -1.0
	elif dist < -patrol_distance:
		direction = 1.0
	sprite.flip_h = direction < 0
