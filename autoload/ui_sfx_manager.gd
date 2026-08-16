extends Node

## Semantic UI sound router.
##
## Gameplay asks for a meaning (`reward`, `select`, `complete`) and this node
## chooses the concrete UI SFX pack. Common controls stay on `soft`; world
## feedback follows the active stage's sonic personality.

const SFX_ROOT := "res://assets/audio/ui_sfx"
const COMMON_PACK: StringName = &"soft"
const DEFAULT_STAGE_PACK: StringName = &"soft"
const PLAYER_COUNT := 8

const STAGE_PACKS: Dictionary = {
	&"cairo_hourglass": &"organic",
	&"amazon_suiu_falls": &"organic",
	&"kyoto_thousand_year_grid": &"zen",
	# Future stage IDs can opt into a different personality without touching
	# gameplay event code.
	&"las_vegas": &"arcade",
	&"space_ship": &"scifi",
}

const CUE_VOLUMES: Dictionary = {
	&"hover": 0.12,
	&"press": 0.20,
	&"release": 0.18,
	&"select": 0.20,
	&"deselect": 0.17,
	&"toggle-on": 0.20,
	&"toggle-off": 0.18,
	&"cancel": 0.17,
	&"open": 0.18,
	&"close": 0.17,
	&"back": 0.17,
	&"success": 0.23,
	&"warning": 0.22,
	&"error": 0.22,
	&"blocked": 0.20,
	&"start": 0.19,
	&"stop": 0.19,
	&"progress-step": 0.12,
	&"complete": 0.24,
	&"checkpoint": 0.18,
	&"reward": 0.22,
	&"level-up": 0.25,
	&"achievement": 0.26,
	&"streak": 0.21,
	&"badge": 0.22,
	&"bonus": 0.24,
}

var _players: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _next_player := 0
var _stage_id: StringName = &""
var _stage_pack: StringName = DEFAULT_STAGE_PACK
var _common_pack: StringName = COMMON_PACK
var _enabled := true
var _volume := 1.0
var _play_count := 0
var _last_cue: StringName = &""
var _last_pack: StringName = &""


func _ready() -> void:
	for index: int in range(PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "UISFXPlayer%d" % index
		player.bus = &"Master"
		add_child(player)
		_players.append(player)
	_sync_volume_from_game_state()


func set_stage(stage_id: StringName) -> void:
	_stage_id = stage_id
	_stage_pack = StringName(STAGE_PACKS.get(stage_id, DEFAULT_STAGE_PACK))


func current_stage() -> StringName:
	return _stage_id


func current_stage_pack() -> StringName:
	return _stage_pack


func set_common_pack(pack: StringName) -> void:
	if _pack_exists(pack):
		_common_pack = pack


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		stop_all()


func set_volume(value: float) -> void:
	_volume = clampf(value, 0.0, 1.0)


func play_common_ui_sfx(cue: StringName) -> bool:
	return play_ui_sfx(cue, false)


func play_world_sfx(cue: StringName) -> bool:
	return play_ui_sfx(cue, true)


## Public semantic entry point. `world_specific` defaults to true so a call
## such as `play_ui_sfx("reward")` automatically follows the active stage.
## Common controls should use `play_common_ui_sfx` to stay globally consistent.
func play_ui_sfx(cue: StringName, world_specific := true, pack_override: StringName = &"") -> bool:
	if not _enabled or _players.is_empty():
		return false
	var volume := _effective_volume()
	if volume <= 0.0:
		return false
	var requested_pack := pack_override
	if String(requested_pack).is_empty():
		requested_pack = _stage_pack if world_specific else _common_pack
	var stream := _stream_for(requested_pack, cue)
	var actual_pack := requested_pack
	if stream == null and requested_pack != _common_pack:
		stream = _stream_for(_common_pack, cue)
		actual_pack = _common_pack
	if stream == null:
		return false
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = linear_to_db(maxf(0.0001, volume * float(CUE_VOLUMES.get(cue, 0.20))))
	player.pitch_scale = 1.0
	player.play()
	_play_count += 1
	_last_cue = cue
	_last_pack = actual_pack
	return true


func stop_all() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()


func receipt() -> Dictionary:
	return {
		"enabled": _enabled,
		"volume": _effective_volume(),
		"stage_id": String(_stage_id),
		"stage_pack": String(_stage_pack),
		"common_pack": String(_common_pack),
		"play_count": _play_count,
		"last_cue": String(_last_cue),
		"last_pack": String(_last_pack),
		"player_count": _players.size(),
	}


func _stream_for(pack: StringName, cue: StringName) -> AudioStream:
	var key := "%s/%s" % [String(pack), String(cue)]
	if _stream_cache.has(key):
		return _stream_cache[key] as AudioStream
	# The upstream Ogg files are Opus-in-Ogg. Godot's portable import path is
	# MP3 here, so the project keeps the matching upstream MP3 assets instead.
	var path := "%s/%s/%s.mp3" % [SFX_ROOT, String(pack), String(cue)]
	if not ResourceLoader.exists(path):
		_stream_cache[key] = null
		return null
	var stream := ResourceLoader.load(path) as AudioStream
	_stream_cache[key] = stream
	return stream


func _pack_exists(pack: StringName) -> bool:
	return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("%s/%s" % [SFX_ROOT, String(pack)]))


func _effective_volume() -> float:
	return _volume


func _sync_volume_from_game_state() -> void:
	var global_state := get_node_or_null("/root/GameState")
	if global_state != null:
		_volume = clampf(float(global_state.get("se_volume")), 0.0, 1.0)
