extends Control
## OptionsMenu — music/SFX volume sliders and fullscreen toggle.
## Saves settings to user://settings.cfg.
## Emits back_pressed when the player closes the menu.

signal back_pressed

const SETTINGS_PATH: String = "user://settings.cfg"

@onready var music_slider:      HSlider     = $Backdrop/Panel/VBox/MusicRow/MusicSlider
@onready var music_value_label: Label       = $Backdrop/Panel/VBox/MusicRow/MusicValueLabel
@onready var sfx_slider:        HSlider     = $Backdrop/Panel/VBox/SFXRow/SFXSlider
@onready var sfx_value_label:   Label       = $Backdrop/Panel/VBox/SFXRow/SFXValueLabel
@onready var fullscreen_toggle: CheckButton = $Backdrop/Panel/VBox/FullscreenRow/FullscreenToggle
@onready var back_button:       Button      = $Backdrop/Panel/VBox/BackButton

var _config: ConfigFile


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = ConfigFile.new()

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)

	_load_settings()
	back_button.grab_focus()


func _load_settings() -> void:
	if _config.load(SETTINGS_PATH) != OK:
		# No config file yet — use defaults
		music_slider.value = 80.0
		sfx_slider.value   = 100.0
		fullscreen_toggle.button_pressed = false
	else:
		music_slider.value = _config.get_value("audio", "music_volume", 80.0)
		sfx_slider.value   = _config.get_value("audio", "sfx_volume",   100.0)
		fullscreen_toggle.button_pressed = _config.get_value("display", "fullscreen", false)

	_apply_audio()
	_apply_display()
	_update_labels()


func _save_settings() -> void:
	_config.set_value("audio",   "music_volume", music_slider.value)
	_config.set_value("audio",   "sfx_volume",   sfx_slider.value)
	_config.set_value("display", "fullscreen",   fullscreen_toggle.button_pressed)
	_config.save(SETTINGS_PATH)


# --- Change handlers ---

func _on_music_changed(value: float) -> void:
	music_value_label.text = "%d" % int(value)
	if has_node("/root/AudioManager"):
		AudioManager.set_bus_volume_db("Music", _vol_to_db(value))


func _on_sfx_changed(value: float) -> void:
	sfx_value_label.text = "%d" % int(value)
	if has_node("/root/AudioManager"):
		AudioManager.set_bus_volume_db("SFX", _vol_to_db(value))


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_back_pressed() -> void:
	_save_settings()
	back_pressed.emit()
	hide()


# --- Apply on load ---

func _apply_audio() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.set_bus_volume_db("Music", _vol_to_db(music_slider.value))
		AudioManager.set_bus_volume_db("SFX",   _vol_to_db(sfx_slider.value))


func _apply_display() -> void:
	if fullscreen_toggle.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _update_labels() -> void:
	music_value_label.text = "%d" % int(music_slider.value)
	sfx_value_label.text   = "%d" % int(sfx_slider.value)


# --- Input (Esc / B button to close) ---

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


# --- Util ---

func _vol_to_db(volume_0_100: float) -> float:
	# Map 0→-80 dB (silence), 100→0 dB (full)
	if volume_0_100 <= 0.0:
		return -80.0
	return linear_to_db(volume_0_100 / 100.0)
