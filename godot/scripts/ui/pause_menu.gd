extends CanvasLayer
## PauseMenu — shown when the player presses pause (Start / Escape).
## Layer 20. process_mode = ALWAYS so it runs while the tree is paused.
##
## Usage: instance pause_menu.tscn and add it to any game room scene.

const OptionsMenuScene: PackedScene = preload("res://scenes/ui/options_menu.tscn")

# Main menu nodes
@onready var backdrop:         ColorRect  = $Backdrop
@onready var menu_panel:       Panel      = $MenuPanel
@onready var resume_btn:       Button     = $MenuPanel/VBox/ResumeButton
@onready var inventory_btn:    Button     = $MenuPanel/VBox/InventoryButton
@onready var stats_btn:        Button     = $MenuPanel/VBox/StatsButton
@onready var save_btn:         Button     = $MenuPanel/VBox/SaveButton
@onready var options_btn:      Button     = $MenuPanel/VBox/OptionsButton
@onready var quit_title_btn:   Button     = $MenuPanel/VBox/QuitTitleButton

# Sub-panel nodes
@onready var inventory_panel:  Panel      = $InventoryPanel
@onready var inv_equipped_grid:GridContainer = $InventoryPanel/VBox/EquippedGrid
@onready var inv_bag_grid:     GridContainer = $InventoryPanel/VBox/BagGrid
@onready var inv_back_btn:     Button     = $InventoryPanel/VBox/BackButton

@onready var stats_panel:      Panel      = $StatsPanel
@onready var stats_grid:       GridContainer = $StatsPanel/VBox/StatsGrid
@onready var stats_back_btn:   Button     = $StatsPanel/VBox/BackButton

var _options_menu: Control


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_btn.pressed.connect(_on_resume)
	inventory_btn.pressed.connect(_on_inventory)
	stats_btn.pressed.connect(_on_stats)
	save_btn.pressed.connect(_on_save)
	options_btn.pressed.connect(_on_options)
	quit_title_btn.pressed.connect(_on_quit_title)

	inv_back_btn.pressed.connect(_show_main_menu)
	stats_back_btn.pressed.connect(_show_main_menu)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if visible:
			_on_resume()
		else:
			_open()
	elif event.is_action_pressed("ui_cancel") and visible:
		get_viewport().set_input_as_handled()
		if inventory_panel.visible or stats_panel.visible:
			_show_main_menu()
		else:
			_on_resume()


# --- Open / close ---

func _open() -> void:
	visible = true
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.PAUSED)
	_show_main_menu()


func _close() -> void:
	visible = false
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)


# --- Panel switching ---

func _show_main_menu() -> void:
	menu_panel.show()
	inventory_panel.hide()
	stats_panel.hide()
	resume_btn.grab_focus()


func _show_inventory() -> void:
	menu_panel.hide()
	inventory_panel.show()
	stats_panel.hide()
	_populate_inventory()
	inv_back_btn.grab_focus()


func _show_stats() -> void:
	menu_panel.hide()
	inventory_panel.hide()
	stats_panel.show()
	_populate_stats()
	stats_back_btn.grab_focus()


# --- Button handlers ---

func _on_resume() -> void:
	_close()


func _on_inventory() -> void:
	_show_inventory()


func _on_stats() -> void:
	_show_stats()


func _on_save() -> void:
	if has_node("/root/SaveManager") and has_node("/root/StatsManager"):
		var data: Dictionary = {
			"stats": StatsManager.get_save_data(),
		}
		if has_node("/root/InventoryManager"):
			data["inventory"] = InventoryManager.get_save_data()
		SaveManager.save_game(0, data)
		# Brief visual feedback on the save button
		save_btn.text = "Saved!"
		await get_tree().create_timer(1.0).timeout
		save_btn.text = "Save"


func _on_options() -> void:
	if not _options_menu:
		_options_menu = OptionsMenuScene.instantiate()
		add_child(_options_menu)
		_options_menu.back_pressed.connect(_on_options_closed)
	_options_menu.show()


func _on_options_closed() -> void:
	resume_btn.grab_focus()


func _on_quit_title() -> void:
	_close()
	GameManager.go_to_scene("res://scenes/ui/title_screen.tscn")


# --- Inventory population ---

func _populate_inventory() -> void:
	# Clear old children
	for child in inv_equipped_grid.get_children():
		child.queue_free()
	for child in inv_bag_grid.get_children():
		child.queue_free()

	if not has_node("/root/InventoryManager"):
		return

	# Equipped slots
	var slot_names: Array = ["Weapon", "Armor", "Helmet", "Cloak", "Acc 1", "Acc 2"]
	for i: int in range(slot_names.size()):
		var slot_label: Label = Label.new()
		var item_id: String = InventoryManager.get_equipped(i)
		slot_label.text = "%s: %s" % [slot_names[i], item_id if not item_id.is_empty() else "—"]
		slot_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1.0))
		inv_equipped_grid.add_child(slot_label)

	# Bag contents
	var items: Array = InventoryManager.get_inventory()
	if items.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "(empty)"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		inv_bag_grid.add_child(empty_label)
	else:
		for item_id: String in items:
			var item_label: Label = Label.new()
			item_label.text = item_id
			item_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70, 1.0))
			inv_bag_grid.add_child(item_label)


# --- Stats population ---

func _populate_stats() -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	if not has_node("/root/StatsManager"):
		return

	var all_stats: Dictionary = StatsManager.get_all_stats()
	var display_order: Array = [
		["Level",        "level"],
		["HP",           ""],
		["MP",           ""],
		["Strength",     "strength"],
		["Dexterity",    "dexterity"],
		["Intelligence", "intelligence"],
		["Vitality",     "vitality"],
		["Luck",         "luck"],
		["Stat Points",  "stat_points"],
	]

	for entry: Array in display_order:
		var key_label: Label = Label.new()
		key_label.text = entry[0] + ":"
		key_label.add_theme_color_override("font_color", Color(0.70, 0.65, 0.55, 1.0))

		var val_label: Label = Label.new()
		match entry[1]:
			"":
				if entry[0] == "HP":
					val_label.text = "%d / %d" % [StatsManager.hp, StatsManager.max_hp]
				elif entry[0] == "MP":
					val_label.text = "%d / %d" % [StatsManager.mp, StatsManager.max_mp]
			_:
				val_label.text = str(all_stats.get(entry[1], "—"))
		val_label.add_theme_color_override("font_color", Color(0.90, 0.85, 0.75, 1.0))

		stats_grid.add_child(key_label)
		stats_grid.add_child(val_label)
