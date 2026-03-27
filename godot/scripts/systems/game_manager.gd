extends Node
## GameManager — global game state, pause, and scene transitions.
## Registered as autoload "GameManager". Persists across all scene changes.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, TRANSITIONING }

signal state_changed(new_state: GameState)
signal scene_transition_started(target_scene: String)

var current_state: GameState = GameState.MENU

func _ready() -> void:
	# Always process so pause input works even when tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- State ---

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)

func pause_game() -> void:
	change_state(GameState.PAUSED)
	get_tree().paused = true

func resume_game() -> void:
	change_state(GameState.PLAYING)
	get_tree().paused = false

func is_playing() -> bool:
	return current_state == GameState.PLAYING

# --- Scene transitions ---

func go_to_scene(path: String) -> void:
	change_state(GameState.TRANSITIONING)
	scene_transition_started.emit(path)
	get_tree().change_scene_to_file(path)
