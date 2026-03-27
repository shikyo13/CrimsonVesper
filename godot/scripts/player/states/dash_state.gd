class_name DashState
extends "res://scripts/player/state.gd"
## Fixed-duration horizontal burst, gravity suspended.
## Replace with a proper dodge-roll animation once art is ready.
## To gate on ability unlock: guard in handle_input callers with
##   if AbilityManager.has_ability("dash"): state_machine.change_state("dash")

var _timer: float = 0.0
var _dir: float   = 1.0

func enter() -> void:
	_timer = player.dash_duration
	# Dash in the direction the player is currently facing.
	_dir = -1.0 if player.animated_sprite.flip_h else 1.0
	player.velocity = Vector2(_dir * player.dash_speed, 0.0)
	player.play_anim("dash")
	player.set_state_color(Color(1.0, 0.9, 0.0, 1))  # yellow

func update(delta: float) -> void:
	_timer -= delta
	player.velocity.x = _dir * player.dash_speed
	player.velocity.y = 0.0  # Suspend gravity for the full dash duration.
	player.move_and_slide()

	if _timer <= 0.0:
		if player.is_on_floor():
			player.state_machine.change_state("idle")
		else:
			player.state_machine.change_state("fall")
