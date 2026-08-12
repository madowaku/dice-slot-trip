extends Node

const TRACK_STAGE_SELECT: StringName = &"stage_select"
const TRACK_NORMAL_MAP: StringName = &"normal_map"
const TRACK_BOSS: StringName = &"boss"
const CROSSFADE_SECONDS := 0.8
const BGM_LINEAR_GAIN := 0.32
const SILENT_DB := -80.0

const TRACKS: Dictionary = {
	TRACK_STAGE_SELECT: preload("res://assets/audio/bgm/cairo/砂丘の風.mp3"),
	TRACK_NORMAL_MAP: preload("res://assets/audio/bgm/cairo/そよ風とお散歩.mp3"),
	TRACK_BOSS: preload("res://assets/audio/bgm/cairo/太陽の絨毯、砂漠の彼方.mp3"),
}

var _players: Array[AudioStreamPlayer] = []
var _active_player_index := -1
var _current_track: StringName = &""
var _master_volume := 1.0
var _transition_generation := 0
var _fade_tween: Tween


func _ready() -> void:
	for index: int in 2:
		var player := AudioStreamPlayer.new()
		player.name = "BGMPlayer%d" % (index + 1)
		player.bus = &"Master"
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	for stream: AudioStream in TRACKS.values():
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true


func _exit_tree() -> void:
	stop()


func play_stage_select() -> void:
	play_track(TRACK_STAGE_SELECT)


func play_normal_map() -> void:
	play_track(TRACK_NORMAL_MAP)


func play_boss() -> void:
	play_track(TRACK_BOSS)


func play_track(track: StringName) -> void:
	if not TRACKS.has(track) or track == _current_track:
		return
	_transition_generation += 1
	var generation := _transition_generation
	if _fade_tween != null:
		_fade_tween.kill()
	var previous_index := _active_player_index
	var next_index := 0 if previous_index != 0 else 1
	var incoming := _players[next_index]
	var outgoing: AudioStreamPlayer = _players[previous_index] if previous_index >= 0 else null
	incoming.stop()
	incoming.stream = TRACKS[track]
	incoming.volume_db = SILENT_DB
	incoming.play()
	_active_player_index = next_index
	_current_track = track
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", _target_volume_db(), CROSSFADE_SECONDS)
	if outgoing != null and outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", SILENT_DB, CROSSFADE_SECONDS)
	_fade_tween.finished.connect(_finish_transition.bind(generation, outgoing))


func stop() -> void:
	_transition_generation += 1
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null
	_current_track = &""
	_active_player_index = -1
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null
		player.volume_db = SILENT_DB


func set_master_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	if _active_player_index >= 0:
		_players[_active_player_index].volume_db = _target_volume_db()


func current_track() -> StringName:
	return _current_track


func _finish_transition(generation: int, outgoing: AudioStreamPlayer) -> void:
	if generation != _transition_generation:
		return
	_fade_tween = null
	if outgoing != null:
		outgoing.stop()


func _target_volume_db() -> float:
	if _master_volume <= 0.0:
		return SILENT_DB
	return linear_to_db(_master_volume * BGM_LINEAR_GAIN)
