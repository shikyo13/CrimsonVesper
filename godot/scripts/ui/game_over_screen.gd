extends CanvasLayer
## Game Over screen shown when the player dies.
## Built programmatically — no companion .tscn node tree needed beyond the root.

const DEFAULT_ROOM := "res://scenes/rooms/entry_hall.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	# --- Full-screen dark overlay ---
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# --- Centered VBoxContainer ---
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# --- "YOU DIED" label ---
	var label := Label.new()
	label.text = "YOU DIED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.12, 1.0))
	vbox.add_child(label)

	# --- Retry button ---
	var retry_btn := Button.new()
	retry_btn.text = "Retry from Save"
	retry_btn.custom_minimum_size = Vector2(280, 52)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_btn.add_theme_font_size_override("font_size", 22)
	retry_btn.pressed.connect(_on_retry)
	vbox.add_child(retry_btn)

	# --- Quit to Title button ---
	var quit_btn := Button.new()
	quit_btn.text = "Quit to Title"
	quit_btn.custom_minimum_size = Vector2(280, 52)
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_btn.add_theme_font_size_override("font_size", 22)
	quit_btn.pressed.connect(_on_quit_to_title)
	vbox.add_child(quit_btn)

	# Retry grabs focus so the player can navigate with gamepad/keyboard immediately.
	retry_btn.grab_focus()


func _on_retry() -> void:
	StatsManager.full_heal()
	StatsManager.restore_mp(StatsManager.max_mp)

	var room_path: String = SaveManager.get_last_save_room()
	if room_path == "":
		room_path = DEFAULT_ROOM

	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)
	GameManager.go_to_scene(room_path)
	queue_free()


func _on_quit_to_title() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager.go_to_scene(TITLE_SCENE)
	queue_free()
