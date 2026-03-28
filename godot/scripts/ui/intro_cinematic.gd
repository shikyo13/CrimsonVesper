extends Control
## IntroCinematic — atmospheric story slides shown before the first room.
## Skip with Start/Escape; advance with ui_accept (A / Enter / Space).

const GAME_SCENE: String = "res://scenes/rooms/entry_hall.tscn"

const FADE_IN_BG_TIME:   float = 1.2
const FADE_IN_TEXT_TIME: float = 1.8
const FADE_OUT_TIME:     float = 0.8

enum Phase { FADE_IN_BG, FADE_IN_TEXT, WAIT, FADE_OUT }

# Each slide: text + background texture path
const SLIDES: Array = [
	{
		"text": "The ancient cathedral of Vesper has awakened...",
		"bg":   "res://assets/backgrounds/cemetery_bg_far.png",
	},
	{
		"text": "Seraphine Ashveil, last of her bloodline,\nreturns to claim what was stolen...",
		"bg":   "res://assets/backgrounds/cemetery_bg_mid.png",
	},
	{
		"text": "Within its halls, dark power grows.\nThe Crimson Vesper calls...",
		"bg":   "res://assets/backgrounds/cemetery_bg_near.png",
	},
	{
		"text": "She must descend into darkness...\nor be consumed by it.",
		"bg":   "res://assets/backgrounds/cemetery_bg_far.png",
	},
]

@onready var bg_texture:    TextureRect = $BGTexture
@onready var fade_rect:     ColorRect   = $FadeRect
@onready var story_label:   Label       = $TextContainer/StoryLabel
@onready var prompt_label:  Label       = $PromptLabel

var _slide_index: int   = 0
var _phase:       Phase = Phase.FADE_IN_BG
var _timer:       float = 0.0
var _advance_queued: bool = false
var _skip_queued:    bool = false


func _ready() -> void:
	fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	bg_texture.modulate.a = 0.0
	story_label.modulate.a = 0.0
	_load_slide(_slide_index)
	_update_prompt()

	if has_node("/root/InputHelper"):
		InputHelper.input_method_changed.connect(_update_prompt)


func _process(delta: float) -> void:
	if _skip_queued:
		_finish()
		return

	_timer += delta

	match _phase:
		Phase.FADE_IN_BG:
			var t: float = minf(_timer / FADE_IN_BG_TIME, 1.0)
			bg_texture.modulate.a = t
			fade_rect.color.a = 1.0 - t
			if _timer >= FADE_IN_BG_TIME or _advance_queued:
				bg_texture.modulate.a = 1.0
				fade_rect.color.a = 0.0
				_phase = Phase.FADE_IN_TEXT
				_timer = 0.0
				_advance_queued = false

		Phase.FADE_IN_TEXT:
			var t: float = minf(_timer / FADE_IN_TEXT_TIME, 1.0)
			story_label.modulate.a = t
			if _timer >= FADE_IN_TEXT_TIME or _advance_queued:
				story_label.modulate.a = 1.0
				_phase = Phase.WAIT
				_timer = 0.0
				_advance_queued = false

		Phase.WAIT:
			if _advance_queued:
				_advance_queued = false
				_phase = Phase.FADE_OUT
				_timer = 0.0

		Phase.FADE_OUT:
			var t: float = minf(_timer / FADE_OUT_TIME, 1.0)
			fade_rect.color.a = t
			bg_texture.modulate.a = 1.0 - t
			story_label.modulate.a = 1.0 - t
			if _timer >= FADE_OUT_TIME:
				_slide_index += 1
				if _slide_index >= SLIDES.size():
					_finish()
				else:
					_load_slide(_slide_index)
					_phase = Phase.FADE_IN_BG
					_timer = 0.0
					fade_rect.color.a = 1.0
					bg_texture.modulate.a = 0.0
					story_label.modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance_queued = true
	elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip_queued = true


func _load_slide(index: int) -> void:
	var slide: Dictionary = SLIDES[index]
	story_label.text = slide["text"]
	var tex: Texture2D = load(slide["bg"])
	if tex:
		bg_texture.texture = tex


func _finish() -> void:
	set_process(false)
	set_process_input(false)
	GameManager.go_to_scene(GAME_SCENE)


func _update_prompt(_method: int = -1) -> void:
	if has_node("/root/InputHelper"):
		prompt_label.text = "Press %s to advance  |  %s to skip" % [
			InputHelper.get_prompt("ui_accept"),
			InputHelper.get_prompt("pause"),
		]
	else:
		prompt_label.text = "Press [Enter] to advance  |  [Esc] to skip"
