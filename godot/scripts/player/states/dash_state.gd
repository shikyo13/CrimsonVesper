class_name DashState
extends "res://scripts/player/state.gd"
## Fixed-duration horizontal burst, gravity suspended, with i-frames for the full dash.

var _timer: float = 0.0
var _dir: float   = 1.0


func enter() -> void:
	_timer = player.dash_duration
	_dir = -1.0 if player.animated_sprite.flip_h else 1.0
	player.velocity = Vector2(_dir * player.dash_speed, 0.0)
	player.facing_dir = _dir
	player.play_anim("dash")
	player.start_iframes(player.dash_duration + 0.05)


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
