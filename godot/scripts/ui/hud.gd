extends CanvasLayer
## HUD — always-on-top health / mana / XP / level / equipped display.
## Layer 10 ensures it renders above the game world.
##
## Usage: instance hud.tscn and add it to any game room scene.
## It will auto-connect to StatsManager and InventoryManager if they exist.

@onready var hp_bar:       ProgressBar = $Control/TopRow/LeftStats/HPBar
@onready var mp_bar:       ProgressBar = $Control/TopRow/LeftStats/MPBar
@onready var level_label:  Label       = $Control/TopRow/LeftStats/LevelLabel
@onready var xp_bar:       ProgressBar = $Control/XPBar
@onready var weapon_label: Label       = $Control/TopRow/RightEquipped/WeaponLabel
@onready var spell_label:  Label       = $Control/TopRow/RightEquipped/SpellLabel

var _hp_tween:  Tween
var _mp_tween:  Tween
var _xp_tween:  Tween


func _ready() -> void:
	layer = 10

	if has_node("/root/StatsManager"):
		StatsManager.hp_changed.connect(_on_hp_changed)
		StatsManager.mp_changed.connect(_on_mp_changed)
		StatsManager.xp_gained.connect(_on_xp_gained)
		StatsManager.stats_changed.connect(_on_stats_changed)
		_refresh_from_stats()

	if has_node("/root/InventoryManager"):
		InventoryManager.equipment_changed.connect(_on_equipment_changed)
		_refresh_equipped()


# --- Init helpers ---

func _refresh_from_stats() -> void:
	hp_bar.value    = _ratio(StatsManager.hp, StatsManager.max_hp) * 100.0
	mp_bar.value    = _ratio(StatsManager.mp, StatsManager.max_mp) * 100.0
	xp_bar.value    = _ratio(StatsManager.xp, StatsManager.xp_to_next) * 100.0
	level_label.text = "Lv %d" % StatsManager.level


func _refresh_equipped() -> void:
	var w: String = InventoryManager.get_equipped(InventoryManager.EquipSlot.WEAPON)
	weapon_label.text = w if not w.is_empty() else "—"


# --- Signal handlers ---

func _on_hp_changed(current: int, maximum: int) -> void:
	_animate_hp(_ratio(current, maximum) * 100.0)


func _on_mp_changed(current: int, maximum: int) -> void:
	_animate_mp(_ratio(current, maximum) * 100.0)


func _on_xp_gained(_amount: int, total: int) -> void:
	if has_node("/root/StatsManager"):
		_animate_xp(_ratio(total, StatsManager.xp_to_next) * 100.0)


func _on_stats_changed(stats: Dictionary) -> void:
	level_label.text = "Lv %d" % stats.get("level", 1)
	if has_node("/root/StatsManager"):
		xp_bar.value = _ratio(StatsManager.xp, StatsManager.xp_to_next) * 100.0


func _on_equipment_changed(_slot: int, _item_id: String) -> void:
	_refresh_equipped()


# --- Bar animations ---

func _animate_hp(target: float) -> void:
	if _hp_tween:
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(hp_bar, "value", target, 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


func _animate_mp(target: float) -> void:
	if _mp_tween:
		_mp_tween.kill()
	_mp_tween = create_tween()
	_mp_tween.tween_property(mp_bar, "value", target, 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


func _animate_xp(target: float) -> void:
	if _xp_tween:
		_xp_tween.kill()
	_xp_tween = create_tween()
	_xp_tween.tween_property(xp_bar, "value", target, 0.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


# --- Utility ---

func _ratio(current: int, maximum: int) -> float:
	return float(current) / float(maximum) if maximum > 0 else 0.0
