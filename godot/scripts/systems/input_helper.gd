extends Node
## InputHelper — tracks whether the last input came from keyboard or controller.
## Provides action-to-prompt-string mappings for UI hints.
## Registered as autoload "InputHelper".

signal input_method_changed(method: int)

enum InputMethod { KEYBOARD, CONTROLLER }

var current_method: int = InputMethod.KEYBOARD

const _CONTROLLER_PROMPTS: Dictionary = {
	"ui_accept":  "[A]",
	"ui_cancel":  "[B]",
	"ui_up":      "[▲]",
	"ui_down":    "[▼]",
	"jump":       "[A]",
	"attack":     "[X]",
	"spell":      "[RB]",
	"dash":       "[LB]",
	"interact":   "[Y]",
	"pause":      "[Start]",
	"move_left":  "[◄]",
	"move_right": "[►]",
}

const _KEYBOARD_PROMPTS: Dictionary = {
	"ui_accept":  "[Enter]",
	"ui_cancel":  "[Esc]",
	"ui_up":      "[↑]",
	"ui_down":    "[↓]",
	"jump":       "[Space]",
	"attack":     "[Z]",
	"spell":      "[C]",
	"dash":       "[X]",
	"interact":   "[E]",
	"pause":      "[Esc]",
	"move_left":  "[A]",
	"move_right": "[D]",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_set_method(InputMethod.CONTROLLER)
	elif event is InputEventKey or event is InputEventMouseButton:
		_set_method(InputMethod.KEYBOARD)


func _set_method(method: int) -> void:
	if current_method == method:
		return
	current_method = method
	input_method_changed.emit(method)


func get_prompt(action: String) -> String:
	if current_method == InputMethod.CONTROLLER:
		return _CONTROLLER_PROMPTS.get(action, "[?]")
	return _KEYBOARD_PROMPTS.get(action, "[?]")


func is_controller() -> bool:
	return current_method == InputMethod.CONTROLLER
