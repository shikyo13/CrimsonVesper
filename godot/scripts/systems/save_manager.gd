extends Node
## SaveManager — orchestrates save/load across all game managers.
## Registered as autoload "SaveManager".
##
## Usage:
##   SaveManager.save_game(0)
##   SaveManager.load_game(0)
##   SaveManager.has_save(0)
##
## Save files: user://saves/save_slot_N.json

const SAVE_DIR:  String = "user://saves/"
const MAX_SLOTS: int    = 3
const SAVE_VERSION: int = 1

signal save_completed(slot: int)
signal load_completed(slot: int)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# --- Public API ---

## Serialize stats, inventory, abilities, and current room to slot N.
func save_game(slot: int) -> bool:
	if not _slot_valid(slot):
		return false
	var data := {
		"version":      SAVE_VERSION,
		"stats":        StatsManager.get_save_data(),
		"inventory":    InventoryManager.get_save_data(),
		"abilities":    AbilityManager.get_save_data(),
		"current_room": _get_current_room(),
	}
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open %s for writing (error %d)" \
				% [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit(slot)
	return true


## Deserialize slot N and apply data to all managers. Returns false if no save exists.
func load_game(slot: int) -> bool:
	if not _slot_valid(slot):
		return false
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open %s for reading" % path)
		return false
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("SaveManager: failed to parse %s" % path)
		return false
	var data: Dictionary = json.data
	if data.has("stats"):
		StatsManager.load_save_data(data["stats"])
	if data.has("inventory"):
		InventoryManager.load_save_data(data["inventory"])
	if data.has("abilities"):
		AbilityManager.load_save_data(data["abilities"])
	if data.has("current_room") and str(data["current_room"]) != "":
		GameManager.go_to_scene(str(data["current_room"]))
	load_completed.emit(slot)
	return true


func has_save(slot: int) -> bool:
	return _slot_valid(slot) and FileAccess.file_exists(_slot_path(slot))


## Backwards-compatible alias for has_save().
func save_exists(slot: int) -> bool:
	return has_save(slot)


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))


## Return the current_room from the first valid save slot, or "" if none exist.
func get_last_save_room() -> String:
	for slot in range(MAX_SLOTS):
		if not has_save(slot):
			continue
		var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
		if file == null:
			continue
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			continue
		var data: Dictionary = json.data
		if data.has("current_room") and str(data["current_room"]) != "":
			return str(data["current_room"])
	return ""


# --- Helpers ---

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_%d.json" % slot


func _slot_valid(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveManager: invalid slot %d (valid: 0–%d)" % [slot, MAX_SLOTS - 1])
		return false
	return true


func _get_current_room() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	return scene.scene_file_path
