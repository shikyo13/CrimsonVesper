extends Node
## InventoryManager — equipment slots and stackable item bag.
## Registered as autoload "InventoryManager".
##
## Usage:
##   InventoryManager.add_item("health_potion", 3)
##   InventoryManager.equip("rusty_sword", EquipSlot.WEAPON)
##   InventoryManager.use_item("health_potion")

## Preload required because autoloads are parsed before class_name registration.
const ItemData = preload("res://scripts/systems/item_data.gd")

signal inventory_changed()
signal item_equipped(item_id: String, slot: int)
signal item_used(item_id: String)

enum EquipSlot { WEAPON, ARMOR, ACCESSORY_1, ACCESSORY_2 }

const MAX_ITEM_TYPES: int = 64  # Max unique item types in bag

## Bag: Array of { "item_id": String, "quantity": int }
var _bag: Array = []

var _equipment: Dictionary = {
	EquipSlot.WEAPON:      "",
	EquipSlot.ARMOR:       "",
	EquipSlot.ACCESSORY_1: "",
	EquipSlot.ACCESSORY_2: "",
}


# --- Inventory bag ---

func add_item(item_id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return false
	# Stack onto existing entry
	for entry in _bag:
		if entry["item_id"] == item_id:
			entry["quantity"] += qty
			inventory_changed.emit()
			return true
	# New slot
	if _bag.size() >= MAX_ITEM_TYPES:
		push_warning("InventoryManager: bag full, cannot add '%s'" % item_id)
		return false
	_bag.append({"item_id": item_id, "quantity": qty})
	inventory_changed.emit()
	return true


func remove_item(item_id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return false
	for i in _bag.size():
		if _bag[i]["item_id"] == item_id:
			if _bag[i]["quantity"] < qty:
				return false
			_bag[i]["quantity"] -= qty
			if _bag[i]["quantity"] <= 0:
				_bag.remove_at(i)
			inventory_changed.emit()
			return true
	return false


func has_item(item_id: String) -> bool:
	for entry in _bag:
		if entry["item_id"] == item_id and entry["quantity"] > 0:
			return true
	return false


func get_quantity(item_id: String) -> int:
	for entry in _bag:
		if entry["item_id"] == item_id:
			return entry["quantity"]
	return 0


func get_bag() -> Array:
	return _bag.duplicate(true)


# --- Consumables ---

## Use one of item_id from the bag, applying its effect to StatsManager.
func use_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	var data := ItemData.get_item(item_id)
	if data.is_empty():
		return false
	if data.get("type", "") != "consumable":
		push_warning("InventoryManager.use_item: '%s' is not consumable" % item_id)
		return false
	var bonus: Dictionary = data.get("stats_bonus", {})
	if bonus.has("heal_hp"):
		StatsManager.heal(int(bonus["heal_hp"]))
	if bonus.has("restore_mp"):
		StatsManager.restore_mp(int(bonus["restore_mp"]))
	remove_item(item_id, 1)
	item_used.emit(item_id)
	return true


# --- Equipment ---

## Equip item_id into slot. Unequips whatever was there first.
func equip(item_id: String, slot: EquipSlot) -> bool:
	var data := ItemData.get_item(item_id)
	if data.is_empty():
		push_warning("InventoryManager.equip: unknown item '%s'" % item_id)
		return false
	# Remove old bonus
	var old_id: String = _equipment[slot]
	if old_id != "":
		var old_data := ItemData.get_item(old_id)
		if not old_data.is_empty():
			StatsManager.remove_bonus(old_data.get("stats_bonus", {}))
	# Apply new bonus
	_equipment[slot] = item_id
	StatsManager.apply_bonus(data.get("stats_bonus", {}))
	item_equipped.emit(item_id, slot)
	return true


func unequip(slot: EquipSlot) -> void:
	var old_id: String = _equipment[slot]
	if old_id == "":
		return
	var old_data := ItemData.get_item(old_id)
	if not old_data.is_empty():
		StatsManager.remove_bonus(old_data.get("stats_bonus", {}))
	_equipment[slot] = ""
	item_equipped.emit("", slot)


func get_equipped(slot: EquipSlot) -> String:
	return _equipment.get(slot, "")


# --- Persistence ---

func get_save_data() -> Dictionary:
	return {
		"bag": _bag.duplicate(true),
		"equipment": {
			str(EquipSlot.WEAPON):      _equipment[EquipSlot.WEAPON],
			str(EquipSlot.ARMOR):       _equipment[EquipSlot.ARMOR],
			str(EquipSlot.ACCESSORY_1): _equipment[EquipSlot.ACCESSORY_1],
			str(EquipSlot.ACCESSORY_2): _equipment[EquipSlot.ACCESSORY_2],
		}
	}


func load_save_data(data: Dictionary) -> void:
	if data.has("bag"):
		_bag.clear()
		for entry in data["bag"]:
			_bag.append({"item_id": str(entry["item_id"]), "quantity": int(entry["quantity"])})
	if data.has("equipment"):
		var eq: Dictionary = data["equipment"]
		_equipment[EquipSlot.WEAPON]      = str(eq.get(str(EquipSlot.WEAPON), ""))
		_equipment[EquipSlot.ARMOR]       = str(eq.get(str(EquipSlot.ARMOR), ""))
		_equipment[EquipSlot.ACCESSORY_1] = str(eq.get(str(EquipSlot.ACCESSORY_1), ""))
		_equipment[EquipSlot.ACCESSORY_2] = str(eq.get(str(EquipSlot.ACCESSORY_2), ""))
	inventory_changed.emit()
