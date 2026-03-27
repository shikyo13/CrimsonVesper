extends Node
## StatsManager — player stats stub/mock until WS-A merges the full implementation.
## Provides the same signals and API that HUD.gd subscribes to.
## WS-A: replace this file with the full stats system; keep signal signatures identical.
## Registered as autoload "StatsManager".

signal stats_changed(stats: Dictionary)
signal hp_changed(current: int, maximum: int)
signal mp_changed(current: int, maximum: int)
signal xp_gained(amount: int, total: int)

var hp: int = 100
var max_hp: int = 100
var mp: int = 50
var max_mp: int = 50
var xp: int = 0
var xp_to_next: int = 100
var level: int = 1
var stat_points: int = 0

var strength: int = 10
var dexterity: int = 10
var intelligence: int = 10
var vitality: int = 10
var luck: int = 5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# --- HP / MP setters (emit signals so HUD updates) ---

func set_hp(value: int) -> void:
	hp = clampi(value, 0, max_hp)
	hp_changed.emit(hp, max_hp)


func set_mp(value: int) -> void:
	mp = clampi(value, 0, max_mp)
	mp_changed.emit(mp, max_mp)


# --- XP / levelling ---

func add_xp(amount: int) -> void:
	xp += amount
	xp_gained.emit(amount, xp)
	_check_level_up()


func _check_level_up() -> void:
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		stat_points += 3
		xp_to_next = int(float(xp_to_next) * 1.5)
	stats_changed.emit(get_all_stats())


# --- Stats query ---

func get_all_stats() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp,
		"mp": mp, "max_mp": max_mp,
		"xp": xp, "xp_to_next": xp_to_next,
		"level": level, "stat_points": stat_points,
		"strength": strength, "dexterity": dexterity,
		"intelligence": intelligence, "vitality": vitality, "luck": luck,
	}


# --- Persistence ---

func get_save_data() -> Dictionary:
	return get_all_stats()


func load_save_data(data: Dictionary) -> void:
	hp           = data.get("hp",           max_hp)
	max_hp       = data.get("max_hp",       100)
	mp           = data.get("mp",           max_mp)
	max_mp       = data.get("max_mp",       50)
	xp           = data.get("xp",           0)
	xp_to_next   = data.get("xp_to_next",   100)
	level        = data.get("level",        1)
	stat_points  = data.get("stat_points",  0)
	strength     = data.get("strength",     10)
	dexterity    = data.get("dexterity",    10)
	intelligence = data.get("intelligence", 10)
	vitality     = data.get("vitality",     10)
	luck         = data.get("luck",         5)
	stats_changed.emit(get_all_stats())
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)
