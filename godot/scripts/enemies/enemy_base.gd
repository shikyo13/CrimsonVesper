class_name EnemyBase
extends CharacterBody2D
## EnemyBase — base class for all enemies.
## Handles HP accounting, XP reward, loot drop, and death signal.
## Subclasses override _on_damaged(), _on_die(), and drop_loot().

signal enemy_died(enemy: Node)

@export var max_hp: int           = 10
@export var damage: int           = 1
@export var xp_reward: int        = 5
@export var knockback_force: float = 180.0

var current_hp: int
var _is_dead: bool = false


func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemy")


## Reduce HP by amount. Calls die() when HP reaches zero.
## source_x is the X world position of the attacker (for knockback direction).
func take_damage(amount: int, source_x: float) -> void:
	if _is_dead:
		return
	current_hp = max(0, current_hp - amount)
	_on_damaged(source_x)
	if current_hp <= 0:
		die()


## Override in subclasses for knockback, flash, state transitions on hit.
func _on_damaged(_source_x: float) -> void:
	pass


## Grants XP, drops loot, emits enemy_died, then calls _on_die().
## Safe to call multiple times — subsequent calls are no-ops.
func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	StatsManager.add_xp(xp_reward)
	drop_loot()
	enemy_died.emit(self)
	_on_die()


## Override in subclasses for death animation, cleanup, etc.
func _on_die() -> void:
	pass


## Override in subclasses to spawn item pickups.
func drop_loot() -> void:
	pass
