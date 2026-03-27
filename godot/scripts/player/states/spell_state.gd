class_name SpellState
extends "res://scripts/player/state.gd"
## Spell cast state: briefly roots the player, spawns a fireball projectile,
## then returns to idle or fall. Costs MP_COST mana and starts spell_cooldown_timer.

const DURATION:  float = 0.25   ## Brief root while casting
const MP_COST:   int   = 10
const COOLDOWN:  float = 0.5

const FIREBALL_SCENE = preload("res://scenes/player/fireball.tscn")

var _timer: float = 0.0


func enter() -> void:
	_timer = DURATION
	player.velocity.x = 0.0
	# Reuse attack animation for the cast gesture
	player.play_anim("attack")
	_spawn_fireball()


func exit() -> void:
	player.spell_cooldown_timer = COOLDOWN


func update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * 8.0)
	player.move_and_slide()

	if _timer <= 0.0:
		if player.is_on_floor():
			player.state_machine.change_state("idle")
		else:
			player.state_machine.change_state("fall")


func _spawn_fireball() -> void:
	var fireball := FIREBALL_SCENE.instantiate()
	var dir := -1.0 if player.animated_sprite.flip_h else 1.0
	# Spawn slightly in front of and at chest height of the player
	fireball.global_position = player.global_position + Vector2(dir * 24.0, -16.0)
	fireball.direction = dir
	fireball.damage = int(player.intelligence * 1.5)
	# Add to room so fireball persists independently of player
	player.get_parent().add_child(fireball)
