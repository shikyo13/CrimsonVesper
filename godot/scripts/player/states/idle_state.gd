class_name IdleState
extends "res://scripts/player/state.gd"
## Player is standing still on the ground.


func enter() -> void:
	player.velocity.x = 0.0
	player.play_anim("idle")


func update(delta: float) -> void:
	player.tick_coyote()
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		player.state_machine.change_state("fall")
	elif Input.get_axis("move_left", "move_right") != 0.0:
		player.state_machine.change_state("run")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.state_machine.change_state("jump")
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack") and player.attack_cooldown_timer <= 0.0:
		player.state_machine.change_state("attack")
