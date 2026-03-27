class_name FallState
extends "res://scripts/player/state.gd"
## Player is descending (walked off edge or reached jump apex).
## Coyote jump available for COYOTE_FRAMES after leaving the ground.


func enter() -> void:
	player.play_anim("fall")


func update(delta: float) -> void:
	player.tick_coyote()
	player.apply_gravity(delta)

	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0.0:
		player.animated_sprite.flip_h = dir < 0.0
		player.facing_dir = sign(dir)

	player.move_and_slide()

	if player.is_on_floor():
		if Input.get_axis("move_left", "move_right") != 0.0:
			player.state_machine.change_state("run")
		else:
			player.state_machine.change_state("idle")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and player.is_coyote_active():
		player.coyote_timer = 0  # Consume coyote — prevents double coyote.
		player.state_machine.change_state("jump")
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack") and player.attack_cooldown_timer <= 0.0:
		player.state_machine.change_state("attack")
