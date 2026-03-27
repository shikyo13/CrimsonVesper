class_name HurtState
extends State
## Knockback + brief stagger window.
##
## Usage from a hit-detection callback:
##   player.state_machine.change_state("hurt")
##   (player.state_machine.current_state as HurtState).set_knockback(attacker.global_position.x)

const DURATION:     float = 0.40
const KNOCKBACK_X:  float = 220.0
const KNOCKBACK_Y:  float = -180.0

var _timer: float        = 0.0
var _knockback_dir: float = 1.0

func enter() -> void:
	_timer = DURATION
	player.play_anim("hurt")

func set_knockback(source_x: float) -> void:
	## source_x: world-space X of the hit source.
	## Player is knocked away from the source.
	_knockback_dir = 1.0 if player.global_position.x >= source_x else -1.0
	player.velocity = Vector2(_knockback_dir * KNOCKBACK_X, KNOCKBACK_Y)

func update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, KNOCKBACK_X * delta * 6.0)
	player.move_and_slide()

	if _timer <= 0.0:
		player.state_machine.change_state("idle")
