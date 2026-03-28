class_name AttackState
extends "res://scripts/player/state.gd"
## Melee attack: enables hitbox for the swing window, polls overlaps each frame,
## applies damage with hitstop and screen shake on the first hit per swing.

const DURATION: float = 0.30
const COOLDOWN: float = 0.45

const HIT_SPARK_SCENE = preload("res://scenes/vfx/hit_spark.tscn")

var _timer: float = 0.0
var _hit_targets: Array = []


func enter() -> void:
	_timer = DURATION
	_hit_targets.clear()
	player.velocity.x = 0.0
	player.play_anim("attack")
	AudioManager.play_sfx("sword_swing", player.global_position)
	# Position hitbox in front of player based on current facing
	var dir := -1.0 if player.animated_sprite.flip_h else 1.0
	player.facing_dir = dir
	player.attack_hitbox.position.x = dir * 48.0
	player.attack_hitbox.scale.x = dir
	player.attack_hitbox.monitoring = true


func exit() -> void:
	player.attack_hitbox.monitoring = false
	player.attack_cooldown_timer = COOLDOWN


func update(delta: float) -> void:
	_timer -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * 8.0)
	player.move_and_slide()

	# Poll overlapping bodies — avoids false-positive from body_entered on monitoring-enable
	for body: Node2D in player.attack_hitbox.get_overlapping_bodies():
		if body == player or body in _hit_targets:
			continue
		if not body.has_method("take_damage"):
			continue
		_hit_targets.append(body)
		body.take_damage(player.attack_damage, player.global_position.x)
		player.trigger_hitstop()
		player.screen_shake()
		_spawn_hit_spark(body.global_position)

	if _timer <= 0.0:
		if player.is_on_floor():
			player.state_machine.change_state("idle")
		else:
			player.state_machine.change_state("fall")


func _spawn_hit_spark(pos: Vector2) -> void:
	var spark := HIT_SPARK_SCENE.instantiate()
	spark.global_position = pos
	player.get_parent().add_child(spark)
