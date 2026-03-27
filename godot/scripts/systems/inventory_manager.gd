extends Node
## InventoryManager — equipment slots and item storage.
## Registered as autoload "InventoryManager".
##
## Usage:
##   InventoryManager.add_item("sword_of_dawn")
##   InventoryManager.equip(EquipSlot.WEAPON, "sword_of_dawn")
##   var weapon_id = InventoryManager.get_equipped(EquipSlot.WEAPON)

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal equipment_changed(slot: int, item_id: String)

enum EquipSlot { WEAPON, ARMOR, HELMET, CLOAK, ACCESSORY_1, ACCESSORY_2 }

const MAX_ITEMS: int = 64

var _equipment: Dictionary = {
	EquipSlot.WEAPON:      "",
	EquipSlot.ARMOR:       "",
	EquipSlot.HELMET:      "",
	EquipSlot.CLOAK:       "",
	EquipSlot.ACCESSORY_1: "",
	EquipSlot.ACCESSORY_2: "",
}
var _inventory: Array[String] = []

# --- Inventory ---

func add_item(item_id: String) -> bool:
	if _inventory.size() >= MAX_ITEMS:
		return false
	_inventory.append(item_id)
	item_added.emit(item_id)
	return true

func remove_item(item_id: String) -> bool:
	var idx := _inventory.find(item_id)
	if idx == -1:
		return false
	_inventory.remove_at(idx)
	item_removed.emit(item_id)
	return true

func has_item(item_id: String) -> bool:
	return _inventory.has(item_id)

func get_inventory() -> Array[String]:
	return _inventory.duplicate()

# --- Equipment ---

func equip(slot: EquipSlot, item_id: String) -> void:
	_equipment[slot] = item_id
	equipment_changed.emit(slot, item_id)

func unequip(slot: EquipSlot) -> void:
	_equipment[slot] = ""
	equipment_changed.emit(slot, "")

func get_equipped(slot: EquipSlot) -> String:
	return _equipment.get(slot, "")

# --- Persistence ---

func get_save_data() -> Dictionary:
	return {
		"equipment": _equipment.duplicate(),
		"inventory": _inventory.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("equipment"):
		for key in data["equipment"]:
			_equipment[key] = str(data["equipment"][key])
	if data.has("inventory"):
		_inventory.clear()
		for item in data["inventory"]:
			_inventory.append(str(item))
