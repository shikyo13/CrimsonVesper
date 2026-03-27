extends Node
## AbilityManager — tracks unlocked traversal/combat abilities and active spell.
## Registered as autoload "AbilityManager".
##
## Usage:
##   if AbilityManager.has_ability("fireball"): ...
##   AbilityManager.unlock_ability("fireball")
##   AbilityManager.set_active_spell("fireball")
##
## Ability keys are stable identifiers — never rename them after shipping save data.

signal ability_unlocked(ability_name: String)

## All abilities start locked except "dash", which is already playable.
var _abilities: Dictionary = {
	"dash":        true,   # Already implemented — player can dash from the start
	"double_jump": false,  # Future traversal upgrade
	"wall_climb":  false,
	"grapple":     false,
	"shadow_dash": false,
	"fireball":    true,   # Unlocked by default for playtest
	"fire_barrier": false,
	"levitate":    false,
	"bat_form":    false,
}

var _active_spell: String = ""


# --- Ability queries ---

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
		return  # Already unlocked — idempotent
	_abilities[ability_name] = true
	ability_unlocked.emit(ability_name)


func get_unlocked_abilities() -> Array[String]:
	var result: Array[String] = []
	for key: String in _abilities:
		if _abilities[key]:
			result.append(key)
	return result


# --- Active spell ---

## Set the spell that fires when the player presses the spell button.
## Silently ignores if the ability is not yet unlocked.
func set_active_spell(ability_name: String) -> void:
	if ability_name != "" and not has_ability(ability_name):
		push_warning("AbilityManager.set_active_spell: '%s' not unlocked" % ability_name)
		return
	_active_spell = ability_name


func get_active_spell() -> String:
	return _active_spell


# --- Persistence ---

func get_save_data() -> Dictionary:
	return {
		"abilities": _abilities.duplicate(),
		"active_spell": _active_spell,
	}


func load_save_data(data: Dictionary) -> void:
	if data.has("abilities"):
		for key: String in data["abilities"]:
			if _abilities.has(key):
				_abilities[key] = bool(data["abilities"][key])
	if data.has("active_spell"):
		_active_spell = str(data["active_spell"])
