class_name ItemData
extends Resource
## ItemData — schema for game items and static item loader.
##
## Item JSON files live in res://data/items/<item_id>.json.
## Use ItemData.get_item(id) to fetch a cached item dict.
##
## Item dict shape:
##   { id, name, description, type, icon_path, stats_bonus, rarity, value }
##
## types: "weapon", "armor", "accessory", "consumable"
## stats_bonus keys: "strength", "defense", "intellect", "luck", "max_hp", "max_mp",
##                   "heal_hp" (consumable), "restore_mp" (consumable)
## rarity: 0=common, 1=uncommon, 2=rare, 3=legendary

enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE }

@export var id: String          = ""
@export var item_name: String   = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var icon_path: String   = ""
@export var stats_bonus: Dictionary = {}
@export var rarity: int         = 0
@export var value: int          = 0

# --- Static item registry ---

static var _cache: Dictionary = {}


## Returns the item dict for item_id, loading from JSON if not cached.
## Returns empty dict if the item does not exist.
static func get_item(item_id: String) -> Dictionary:
	if _cache.has(item_id):
		return _cache[item_id] as Dictionary
	var path: String = "res://data/items/%s.json" % item_id
	if not FileAccess.file_exists(path):
		push_warning("ItemData.get_item: no item file for '%s'" % item_id)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ItemData.get_item: cannot open '%s'" % path)
		return {}
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("ItemData.get_item: JSON parse error in '%s'" % path)
		return {}
	var parsed: Dictionary = json.data as Dictionary
	_cache[item_id] = parsed
	return parsed


## Returns true if item_id refers to a consumable.
static func is_consumable(item_id: String) -> bool:
	var data: Dictionary = get_item(item_id)
	return data.get("type", "") == "consumable"


## Returns true if item_id refers to equippable gear.
static func is_equippable(item_id: String) -> bool:
	var data: Dictionary = get_item(item_id)
	var t: String = data.get("type", "") as String
	return t in ["weapon", "armor", "accessory"]
