extends Node

const TRACK_STAGE_SELECT: StringName = &"stage_select"
const TRACK_HOME: StringName = &"home"
const TRACK_NORMAL_MAP: StringName = &"normal_map"
const TRACK_BOSS: StringName = &"boss"
const TRACK_AMAZON_PREVIEW: StringName = &"amazon_preview"
const TRACK_AMAZON_NORMAL: StringName = &"amazon_normal"
const TRACK_AMAZON_BOSS: StringName = &"amazon_boss"
const TRACK_KYOTO_PREVIEW: StringName = &"kyoto_preview"
const TRACK_KYOTO_NORMAL: StringName = &"kyoto_normal"
const TRACK_KYOTO_BOSS: StringName = &"kyoto_boss"
const TRACK_LASVEGAS_PREVIEW: StringName = &"lasvegas_preview"
const TRACK_LASVEGAS_MAIN: StringName = &"lasvegas_main"
const TRACK_DICE_RACE: StringName = &"dice_race"
const TRACK_DICE_ROULETTE: StringName = &"dice_roulette"
const TRACK_VAULT_BREAK: StringName = &"vault_break"
const TRACK_KYOTO_FOX_FIRE_CHASE: StringName = &"kyoto_fox_fire_chase"
const CROSSFADE_SECONDS := 0.8
const BGM_LINEAR_GAIN := 0.32
const SILENT_DB := -80.0

const TRACKS: Dictionary = {
	TRACK_HOME: preload("res://assets/audio/bgm/home/世界の最果てで、自由を謳う_2.mp3"),
	TRACK_STAGE_SELECT: preload("res://assets/audio/bgm/cairo/砂丘の風.mp3"),
	TRACK_NORMAL_MAP: preload("res://assets/audio/bgm/cairo/そよ風とお散歩.mp3"),
	TRACK_BOSS: preload("res://assets/audio/bgm/cairo/太陽の絨毯、砂漠の彼方.mp3"),
	TRACK_AMAZON_PREVIEW: preload("res://assets/audio/bgm/amazon/アマゾン探検.mp3"),
	TRACK_AMAZON_NORMAL: preload("res://assets/audio/bgm/amazon/森林ループ_2.mp3"),
	TRACK_AMAZON_BOSS: preload("res://assets/audio/bgm/amazon/黒の滝.mp3"),
	TRACK_KYOTO_PREVIEW: preload("res://assets/audio/bgm/kyoto/古都、路地裏にて.mp3"),
	TRACK_KYOTO_NORMAL: preload("res://assets/audio/bgm/kyoto/雅なフィールド.mp3"),
	TRACK_KYOTO_BOSS: preload("res://assets/audio/bgm/kyoto/お稲荷様.mp3"),
	TRACK_LASVEGAS_PREVIEW: preload("res://assets/audio/bgm/lasvegas/カジノ.mp3"),
	TRACK_LASVEGAS_MAIN: preload("res://assets/audio/bgm/lasvegas/ジャックポット.mp3"),
	TRACK_DICE_RACE: preload("res://assets/audio/bgm/lasvegas/ミニマルダービー.mp3"),
	TRACK_DICE_ROULETTE: preload("res://assets/audio/bgm/lasvegas/ルーレット.mp3"),
	TRACK_VAULT_BREAK: preload("res://assets/audio/bgm/lasvegas/忍び足.mp3"),
	TRACK_KYOTO_FOX_FIRE_CHASE: preload("res://assets/audio/bgm/kyoto/あのね.mp3"),
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


func play_home() -> void:
	play_track(TRACK_HOME)


func play_normal_map() -> void:
	play_track(TRACK_NORMAL_MAP)


func play_boss() -> void:
	play_track(TRACK_BOSS)


func play_amazon_preview() -> void:
	play_track(TRACK_AMAZON_PREVIEW)


func play_amazon_normal() -> void:
	play_track(TRACK_AMAZON_NORMAL)


func play_amazon_boss() -> void:
	play_track(TRACK_AMAZON_BOSS)


func play_kyoto_preview() -> void:
	play_track(TRACK_KYOTO_PREVIEW)


func play_kyoto_normal() -> void:
	play_track(TRACK_KYOTO_NORMAL)


func play_kyoto_boss() -> void:
	play_track(TRACK_KYOTO_BOSS)


func play_lasvegas_preview() -> void:
	play_track(TRACK_LASVEGAS_PREVIEW)


func play_lasvegas_main() -> void:
	play_track(TRACK_LASVEGAS_MAIN)


func play_dice_race() -> void:
	play_track(TRACK_DICE_RACE)


func play_dice_roulette() -> void:
	play_track(TRACK_DICE_ROULETTE)


func play_vault_break() -> void:
	play_track(TRACK_VAULT_BREAK)


func play_kyoto_fox_fire_chase() -> void:
	play_track(TRACK_KYOTO_FOX_FIRE_CHASE)


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
