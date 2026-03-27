extends Node
## AudioManager — music playback with crossfade, SFX pooling, and bus volume control.
## Registered as autoload "AudioManager".
##
## Bus layout (defined in project.godot [audio]):
##   Master -> Music, SFX, Ambient, UI
##
## Usage:
##   AudioManager.play_music("exploration")
##   AudioManager.play_sfx("sword_swing", global_position)
##   AudioManager.play_ui("menu_select")
##   AudioManager.set_bus_volume_db("Music", -6.0)

const BUS_MUSIC:   String = "Music"
const BUS_SFX:     String = "SFX"
const BUS_AMBIENT: String = "Ambient"
const BUS_UI:      String = "UI"

## Named SFX preloads — key = logical name, value = resource path
const SFX_PATHS: Dictionary = {
	"sword_swing":  "res://assets/audio/sfx/sword_swing.ogg",
	"player_hurt":  "res://assets/audio/sfx/player_hurt.ogg",
	"player_death": "res://assets/audio/sfx/player_death.wav",
	"enemy_hit":    "res://assets/audio/sfx/enemy_hit.ogg",
	"enemy_death":  "res://assets/audio/sfx/enemy_death.ogg",
	"item_pickup":  "res://assets/audio/sfx/item_pickup.wav",
	"jump":         "res://assets/audio/sfx/jump.ogg",
	"footstep":     "res://assets/audio/sfx/footstep.wav",
	"save_game":    "res://assets/audio/sfx/save_game.wav",
}

const UI_PATHS: Dictionary = {
	"menu_select":  "res://assets/audio/sfx/menu_select.ogg",
	"menu_confirm": "res://assets/audio/sfx/menu_confirm.wav",
}

const MUSIC_PATHS: Dictionary = {
	"exploration": "res://assets/audio/music/exploration.ogg",
	"boss_battle": "res://assets/audio/music/boss_battle.ogg",
}

## Preloaded streams (populated in _ready)
var _sfx_cache:   Dictionary = {}
var _ui_cache:    Dictionary = {}
var _music_cache: Dictionary = {}

## Two music players for crossfading
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer   ## the currently audible one
var _music_inactive: AudioStreamPlayer ## the one being faded in/out
var _current_music_key: String = ""

## Active tween for crossfade
var _crossfade_tween: Tween


func _ready() -> void:
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_music_active   = _music_a
	_music_inactive = _music_b

	_preload_cache(SFX_PATHS,   _sfx_cache)
	_preload_cache(UI_PATHS,    _ui_cache)
	_preload_cache(MUSIC_PATHS, _music_cache)


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = BUS_MUSIC
	p.volume_db = -80.0
	add_child(p)
	return p


func _preload_cache(paths: Dictionary, cache: Dictionary) -> void:
	for key: String in paths:
		var path: String = paths[key]
		if ResourceLoader.exists(path):
			cache[key] = load(path)
		else:
			push_warning("AudioManager: missing asset '%s'" % path)


# ---------------------------------------------------------------------------
# Music
# ---------------------------------------------------------------------------

## Play a music track by logical name (see MUSIC_PATHS). Crossfades smoothly.
func play_music(key: String, fade_duration: float = 1.5) -> void:
	if key == _current_music_key:
		return
	var stream: AudioStream = _music_cache.get(key)
	if stream == null:
		push_warning("AudioManager.play_music: unknown key '%s'" % key)
		return

	_current_music_key = key

	# Kill any running crossfade
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	# Swap players
	var fade_in  := _music_inactive
	var fade_out := _music_active
	_music_active   = fade_in
	_music_inactive = fade_out

	fade_in.stream = stream
	fade_in.play()

	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(fade_in,  "volume_db", 0.0,   fade_duration)
	_crossfade_tween.tween_property(fade_out, "volume_db", -80.0, fade_duration)
	_crossfade_tween.chain().tween_callback(fade_out.stop)


## Stop all music with an optional fade.
func stop_music(fade_duration: float = 1.0) -> void:
	_current_music_key = ""
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(_music_a, "volume_db", -80.0, fade_duration)
	_crossfade_tween.tween_property(_music_b, "volume_db", -80.0, fade_duration)
	_crossfade_tween.chain().tween_callback(_music_a.stop)
	_crossfade_tween.chain().tween_callback(_music_b.stop)


# ---------------------------------------------------------------------------
# SFX (positional fire-and-forget)
# ---------------------------------------------------------------------------

## Play a named SFX at an optional world position.
func play_sfx(key: String, world_position: Vector2 = Vector2.ZERO) -> void:
	var stream: AudioStream = _sfx_cache.get(key)
	if stream == null:
		push_warning("AudioManager.play_sfx: unknown key '%s'" % key)
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()


## Play a named SFX with an AudioStream directly (for one-offs or generated streams).
func play_sfx_stream(stream: AudioStream, world_position: Vector2 = Vector2.ZERO) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = BUS_SFX
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()


# ---------------------------------------------------------------------------
# UI sounds (non-positional)
# ---------------------------------------------------------------------------

func play_ui(key: String) -> void:
	var stream: AudioStream = _ui_cache.get(key)
	if stream == null:
		push_warning("AudioManager.play_ui: unknown key '%s'" % key)
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = BUS_UI
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


# ---------------------------------------------------------------------------
# Volume control
# ---------------------------------------------------------------------------

func set_bus_volume_db(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)


func get_bus_volume_db(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_db(idx) if idx != -1 else -80.0
