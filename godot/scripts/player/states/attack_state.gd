class_name AttackState
extends "res://scripts/player/state.gd"
## Fixed-duration attack placeholder.
## Wire up a hitbox Area2D and proper animation in the next pass.
## Duration is intentionally short — tune it to feel snappy in testing.

const DURATION: float = 0.30

var _timer: float = 0.0

func enter() -> void:
	_timer = DURATION
	player.velocity.x = 0.0
	player.play_anim("attack")
	player.set_state_color(Color(0.9, 0.1, 0.1, 1))  # red

func update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	# Bleed off horizontal momentum so the attack doesn't slide.
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * 8.0)
	player.move_and_slide()

	if _timer <= 0.0:
		if player.is_on_floor():
			player.state_machine.change_state("idle")
		else:
			player.state_machine.change_state("fall")
