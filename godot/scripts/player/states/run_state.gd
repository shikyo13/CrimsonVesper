class_name RunState
extends "res://scripts/player/state.gd"
## Player is running horizontally on the ground.

func enter() -> void:
	player.play_anim("run")
	player.set_state_color(Color(0.2, 0.8, 0.3, 1))  # green

func update(delta: float) -> void:
	player.tick_coyote()
	player.apply_gravity(delta)

	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0.0:
		player.animated_sprite.flip_h = dir < 0.0

	player.move_and_slide()

	if not player.is_on_floor():
		player.state_machine.change_state("fall")
	elif dir == 0.0:
		player.state_machine.change_state("idle")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.state_machine.change_state("jump")
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack"):
		player.state_machine.change_state("attack")
