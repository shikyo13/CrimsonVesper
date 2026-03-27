extends Control
## TitleScreen — main menu scene with animated parallax background.
## New Game → intro cinematic. Continue → game (if save exists). Options → overlay. Quit → exit.

const INTRO_SCENE: String  = "res://scenes/ui/intro_cinematic.tscn"
const GAME_SCENE:  String  = "res://scenes/rooms/test_room.tscn"

const SCROLL_SPEED: float  = 24.0   # pixels / second for the slowest parallax layer
const TITLE_PULSE_SPEED: float = 1.2

const OptionsMenuScene: PackedScene = preload("res://scenes/ui/options_menu.tscn")

@onready var parallax_bg:    ParallaxBackground = $ParallaxBackground
@onready var title_label:    Label              = $MenuContainer/TitleLabel
@onready var new_game_btn:   Button             = $MenuContainer/NewGameButton
@onready var continue_btn:   Button             = $MenuContainer/ContinueButton
@onready var options_btn:    Button             = $MenuContainer/OptionsButton
@onready var quit_btn:       Button             = $MenuContainer/QuitButton
@onready var version_label:  Label              = $VersionLabel

var _options_menu: Control
var _pulse_time: float = 0.0


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().paused = false

	# Grey out Continue if no saves exist
	var has_save: bool = (
		SaveManager.save_exists(0) or
		SaveManager.save_exists(1) or
		SaveManager.save_exists(2)
	)
	continue_btn.disabled = not has_save
	if has_save:
		continue_btn.modulate.a = 1.0
	else:
		continue_btn.modulate.a = 0.45

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	options_btn.pressed.connect(_on_options)
	quit_btn.pressed.connect(_on_quit)

	new_game_btn.grab_focus()

	if has_node("/root/InputHelper"):
		InputHelper.input_method_changed.connect(_on_input_method_changed)


func _process(delta: float) -> void:
	# Slow horizontal scroll
	parallax_bg.scroll_base_offset.x -= SCROLL_SPEED * delta

	# Subtle title pulse
	_pulse_time += delta * TITLE_PULSE_SPEED
	var pulse: float = 0.92 + 0.08 * sin(_pulse_time)
	title_label.modulate = Color(pulse, pulse * 0.88, pulse * 0.78, 1.0)


# --- Button handlers ---

func _on_new_game() -> void:
	GameManager.go_to_scene(INTRO_SCENE)


func _on_continue() -> void:
	# Load from the first valid slot (SaveManager applies data to all managers internally)
	for slot: int in [0, 1, 2]:
		if SaveManager.save_exists(slot):
			SaveManager.load_game(slot)
			break
	GameManager.go_to_scene(GAME_SCENE)


func _on_options() -> void:
	if not _options_menu:
		_options_menu = OptionsMenuScene.instantiate()
		add_child(_options_menu)
		_options_menu.back_pressed.connect(_on_options_closed)
	_options_menu.show()


func _on_options_closed() -> void:
	options_btn.grab_focus()


func _on_quit() -> void:
	get_tree().quit()


func _on_input_method_changed(_method: int) -> void:
	# Buttons auto-update their focus style; nothing special needed here
	pass


# --- Keyboard shortcut (Esc has no effect on title screen) ---

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Absorb so we don't accidentally trigger anything
		get_viewport().set_input_as_handled()
