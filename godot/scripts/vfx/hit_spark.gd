extends CPUParticles2D
## Small burst of sparks on enemy hit. Spawned by AttackState.
## Frees itself after the burst completes.

func _ready() -> void:
	# Configure burst parameters at runtime
	amount = 5
	lifetime = 0.35
	one_shot = true
	explosiveness = 0.95
	direction = Vector2(0.0, -1.0)
	spread = 80.0
	initial_velocity_min = 50.0
	initial_velocity_max = 110.0
	gravity = Vector2(0.0, 320.0)
	scale_amount_min = 2.0
	scale_amount_max = 4.0
	color = Color(1.0, 0.85, 0.3, 1.0)
	emitting = true
	get_tree().create_timer(lifetime + 0.15).timeout.connect(
		func(): if is_instance_valid(self): queue_free()
	)
