extends Node
## AudioManager — music playback, SFX pooling, and bus volume control.
## Registered as autoload "AudioManager".
##
## Bus layout (create these in Project > Audio):
##   Master -> Music, SFX, Ambient, UI
##
## Usage:
##   AudioManager.play_music(preload("res://assets/audio/music/theme.ogg"))
##   AudioManager.play_sfx(sfx_stream, global_position)
##   AudioManager.set_bus_volume_db("Music", -6.0)

const BUS_MUSIC:   String = "Music"
const BUS_SFX:     String = "SFX"
const BUS_AMBIENT: String = "Ambient"
const BUS_UI:      String = "UI"

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)

# --- Music ---

func play_music(stream: AudioStream) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

# --- SFX (fire-and-forget, positional) ---

func play_sfx(stream: AudioStream, world_position: Vector2 = Vector2.ZERO) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()

# --- UI sounds (non-positional) ---

func play_ui(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_UI
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

# --- Volume control ---

func set_bus_volume_db(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

func get_bus_volume_db(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_db(idx) if idx != -1 else -80.0
