extends Node
## SaveManager — JSON save/load with multiple save slots.
## Registered as autoload "SaveManager".
## Usage: SaveManager.save_game(0, data_dict)
##        var data = SaveManager.load_game(0)

const SAVE_DIR: String = "user://saves/"
const MAX_SLOTS: int = 3

signal save_completed(slot: int)
signal load_completed(slot: int)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# --- Public API ---

func save_game(slot: int, data: Dictionary) -> bool:
	if not _slot_valid(slot):
		return false
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open %s for writing (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_completed.emit(slot)
	return true

func load_game(slot: int) -> Dictionary:
	if not _slot_valid(slot):
		return {}
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open %s for reading" % path)
		return {}
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("SaveManager: failed to parse %s" % path)
		return {}
	load_completed.emit(slot)
	return json.data

func delete_save(slot: int) -> void:
	if _slot_valid(slot) and save_exists(slot):
		DirAccess.remove_absolute(_slot_path(slot))

func save_exists(slot: int) -> bool:
	return _slot_valid(slot) and FileAccess.file_exists(_slot_path(slot))

# --- Helpers ---

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot

func _slot_valid(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("SaveManager: invalid slot %d (valid: 0–%d)" % [slot, MAX_SLOTS - 1])
		return false
	return true
