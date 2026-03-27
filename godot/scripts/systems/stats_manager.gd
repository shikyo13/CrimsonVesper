extends Node
## StatsManager — authoritative source for all player RPG stats.
## Registered as autoload "StatsManager".
##
## Usage:
##   StatsManager.add_xp(50)
##   StatsManager.take_damage(3)
##   StatsManager.heal(10)

signal stats_changed()
signal level_up(new_level: int)
signal xp_gained(amount: int, total: int)
signal hp_changed(current_hp: int, max_hp: int)
signal mp_changed(current_mp: int, max_mp: int)
signal player_died()

# --- Base stats ---
var hp: int = 50
var max_hp: int = 50
var mp: int = 30
var max_mp: int = 30
var strength: int = 10    ## str
var defense: int = 8      ## def
var intellect: int = 7    ## int
var luck: int = 5         ## lck
var level: int = 1
var xp: int = 0
var xp_to_next: int = 150  # recalculated on level changes

# --- Equipment bonuses (tracked separately so unequip is clean) ---
var _bonus_max_hp: int = 0
var _bonus_max_mp: int = 0
var _bonus_strength: int = 0
var _bonus_defense: int = 0
var _bonus_intellect: int = 0
var _bonus_luck: int = 0


func _ready() -> void:
	_recalc_xp_to_next()


# --- XP & Levelling ---

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	xp_gained.emit(amount, xp)
	while xp >= xp_to_next:
		xp -= xp_to_next
		_do_level_up()


func _do_level_up() -> void:
	level += 1
	max_hp += 5
	max_mp += 3
	strength += 1
	defense += 1
	hp = max_hp
	mp = max_mp
	_recalc_xp_to_next()
	level_up.emit(level)
	stats_changed.emit()
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)


func _recalc_xp_to_next() -> void:
	xp_to_next = int(100 * level * 1.5)


# --- HP ---

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		player_died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	hp = min(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)


func full_heal() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)


# --- MP ---

func use_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	mp_changed.emit(mp, max_mp)
	return true


func restore_mp(amount: int) -> void:
	if amount <= 0:
		return
	mp = min(max_mp, mp + amount)
	mp_changed.emit(mp, max_mp)


# --- Equipment bonuses ---
## Called by InventoryManager when equipping gear.
func apply_bonus(bonus: Dictionary) -> void:
	if bonus.has("max_hp"):
		_bonus_max_hp += bonus["max_hp"]
		max_hp += bonus["max_hp"]
	if bonus.has("max_mp"):
		_bonus_max_mp += bonus["max_mp"]
		max_mp += bonus["max_mp"]
	if bonus.has("strength"):
		_bonus_strength += bonus["strength"]
	if bonus.has("defense"):
		_bonus_defense += bonus["defense"]
	if bonus.has("intellect"):
		_bonus_intellect += bonus["intellect"]
	if bonus.has("luck"):
		_bonus_luck += bonus["luck"]
	stats_changed.emit()
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)


## Called by InventoryManager when unequipping gear.
func remove_bonus(bonus: Dictionary) -> void:
	if bonus.has("max_hp"):
		_bonus_max_hp -= bonus["max_hp"]
		max_hp = max(1, max_hp - bonus["max_hp"])
		hp = min(hp, max_hp)
	if bonus.has("max_mp"):
		_bonus_max_mp -= bonus["max_mp"]
		max_mp = max(0, max_mp - bonus["max_mp"])
		mp = min(mp, max_mp)
	if bonus.has("strength"):
		_bonus_strength -= bonus["strength"]
	if bonus.has("defense"):
		_bonus_defense -= bonus["defense"]
	if bonus.has("intellect"):
		_bonus_intellect -= bonus["intellect"]
	if bonus.has("luck"):
		_bonus_luck -= bonus["luck"]
	stats_changed.emit()
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)


# --- Effective stat getters (base + equipment bonuses) ---

func get_strength() -> int:
	return strength + _bonus_strength


func get_defense() -> int:
	return defense + _bonus_defense


func get_intellect() -> int:
	return intellect + _bonus_intellect


func get_luck() -> int:
	return luck + _bonus_luck


# --- Persistence ---

func get_save_data() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp,
		"mp": mp, "max_mp": max_mp,
		"strength": strength, "defense": defense,
		"intellect": intellect, "luck": luck,
		"level": level, "xp": xp,
		"bonus_max_hp": _bonus_max_hp, "bonus_max_mp": _bonus_max_mp,
		"bonus_strength": _bonus_strength, "bonus_defense": _bonus_defense,
		"bonus_intellect": _bonus_intellect, "bonus_luck": _bonus_luck,
	}


func load_save_data(data: Dictionary) -> void:
	hp         = data.get("hp", 50)
	max_hp     = data.get("max_hp", 50)
	mp         = data.get("mp", 30)
	max_mp     = data.get("max_mp", 30)
	strength   = data.get("strength", 10)
	defense    = data.get("defense", 8)
	intellect  = data.get("intellect", 7)
	luck       = data.get("luck", 5)
	level      = data.get("level", 1)
	xp         = data.get("xp", 0)
	_bonus_max_hp    = data.get("bonus_max_hp", 0)
	_bonus_max_mp    = data.get("bonus_max_mp", 0)
	_bonus_strength  = data.get("bonus_strength", 0)
	_bonus_defense   = data.get("bonus_defense", 0)
	_bonus_intellect = data.get("bonus_intellect", 0)
	_bonus_luck      = data.get("bonus_luck", 0)
	_recalc_xp_to_next()
	stats_changed.emit()
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)
