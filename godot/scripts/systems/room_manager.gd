extends Node
## RoomManager — fade-to-black room transitions and spawn-point routing.
## Registered as autoload "RoomManager". Persists across all scene changes.
##
## Usage (from a door Area2D):
##   RoomManager.transition_to("res://scenes/rooms/corridor.tscn", "SpawnLeft")
##
## Usage (from a room's _ready, after placing the player):
##   RoomManager.fade_in()

signal room_transition_started(room_path: String)
signal room_transition_finished

## ID of the room currently loaded — set by each room's _ready().
var current_room_id: String = ""

var _pending_spawn: String = "SpawnLeft"
var _canvas: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	# Build the persistent fade overlay on top of everything.
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	_canvas.follow_viewport_enabled = false
	add_child(_canvas)

	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(_fade)


## Begin transition: fade out → change scene → caller's room _ready() must
## call fade_in() once the player is positioned.
func transition_to(room_path: String, spawn_point_name: String) -> void:
	if GameManager.current_state == GameManager.GameState.TRANSITIONING:
		return
	GameManager.change_state(GameManager.GameState.TRANSITIONING)
	_pending_spawn = spawn_point_name
	room_transition_started.emit(room_path)

	var tween := create_tween()
	tween.tween_property(_fade, "color", Color(0.0, 0.0, 0.0, 1.0), 0.5)
	await tween.finished

	get_tree().change_scene_to_file(room_path)


## Fade back in after a room loads. Call from the new room's _ready().
func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color", Color(0.0, 0.0, 0.0, 0.0), 0.5)
	await tween.finished
	GameManager.change_state(GameManager.GameState.PLAYING)
	room_transition_finished.emit()


## The spawn-point name the next room should use to place the player.
func get_spawn_point_name() -> String:
	return _pending_spawn
