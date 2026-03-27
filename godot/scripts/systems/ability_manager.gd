extends Node
## AbilityManager — tracks unlocked traversal/combat abilities.
## Registered as autoload "AbilityManager".
##
## Usage:
##   if AbilityManager.has_ability("double_jump"): ...
##   AbilityManager.unlock_ability("dash")
##
## Ability keys are stable identifiers — never rename them after shipping save data.

signal ability_unlocked(ability_name: String)

## All abilities start locked. Extend this dict as the game grows.
var _abilities: Dictionary = {
	"double_jump":  false,
	"dash":         false,
	"wall_climb":   false,
	"grapple":      false,
	"shadow_dash":  false,
	"fire_barrier": false,
	"levitate":     false,
	"bat_form":     false,
}

func has_ability(ability_name: String) -> bool:
	if not _abilities.has(ability_name):
		push_warning("AbilityManager: unknown ability '%s'" % ability_name)
		return false
	return _abilities[ability_name]

func unlock_ability(ability_name: String) -> void:
	if not _abilities.has(ability_name):
		push_error("AbilityManager: cannot unlock unknown ability '%s'" % ability_name)
		return
	if _abilities[ability_name]:
		return  # Already unlocked — idempotent.
	_abilities[ability_name] = true
	ability_unlocked.emit(ability_name)

# --- Persistence ---

func get_save_data() -> Dictionary:
	return _abilities.duplicate()

func load_save_data(data: Dictionary) -> void:
	for key: String in data:
		if _abilities.has(key):
			_abilities[key] = bool(data[key])
