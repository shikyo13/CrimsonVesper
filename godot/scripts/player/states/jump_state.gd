class_name JumpState
extends State
## Player is ascending after a jump.
## Supports variable jump height: release jump early → lower apex.

func enter() -> void:
	player.velocity.y = -player.jump_force
	player.jump_released_early = false
	player.coyote_timer = 0  # Consume coyote so it can't fire again mid-air.
	player.play_anim("jump")

func update(delta: float) -> void:
	# Variable jump height: cut upward velocity once on early release.
	if player.jump_released_early:
		if player.velocity.y < 0.0:
			player.velocity.y *= player.JUMP_CUT_MULTIPLIER
		player.jump_released_early = false

	player.apply_gravity(delta)

	var dir := Input.get_axis("move_left", "move_right")
	player.velocity.x = dir * player.speed
	if dir != 0.0:
		player.animated_sprite.flip_h = dir < 0.0

	player.move_and_slide()

	# Apex reached — start falling.
	if player.velocity.y >= 0.0:
		player.state_machine.change_state("fall")

func handle_input(event: InputEvent) -> void:
	if event.is_action_released("jump"):
		player.jump_released_early = true
	elif event.is_action_pressed("dash"):
		player.state_machine.change_state("dash")
	elif event.is_action_pressed("attack"):
		player.state_machine.change_state("attack")
