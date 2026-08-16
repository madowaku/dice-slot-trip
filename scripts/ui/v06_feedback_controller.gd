class_name V06FeedbackController
extends Node

## Small, bounded feedback mixer for the v0.6 journey screen.  Gameplay calls
## semantic events; this node owns the concrete sounds and mobile vibration.

const DICE_LOCK: AudioStream = preload("res://assets/audio/dice/lock_02.wav")
const DICE_LAND: AudioStream = preload("res://assets/audio/dice/land_04.wav")
const DICE_CONTACT: AudioStream = preload("res://assets/audio/dice/contact_03.wav")

const EVENT_BUTTON: StringName = &"button"
const EVENT_ROLL_STOP: StringName = &"roll_stop"
const EVENT_REWARD: StringName = &"reward"
const EVENT_DAMAGE: StringName = &"damage"
const EVENT_MISSION_COMPLETE: StringName = &"mission_complete"
const EVENT_LEVEL_UP: StringName = &"level_up"
const EVENT_VICTORY: StringName = &"victory"
const EVENT_DEFEAT: StringName = &"defeat"
const EVENT_BLOCKED: StringName = &"blocked"

const PLAYER_COUNT := 3
const HAPTIC_PATTERNS := {
	EVENT_BUTTON: [16],
	EVENT_ROLL_STOP: [24],
	EVENT_REWARD: [22, 42, 22],
	EVENT_DAMAGE: [58],
	EVENT_MISSION_COMPLETE: [28, 48, 28],
	EVENT_LEVEL_UP: [24, 42, 24],
	EVENT_VICTORY: [34, 54, 34, 78],
	EVENT_DEFEAT: [42],
	EVENT_BLOCKED: [34],
}

var master_volume := 1.0
var se_volume := 1.0
var dice_muted := false
var haptics_enabled := true
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _haptic_generation := 0
var _event_counts: Dictionary = {}
var _last_event: StringName = &""
var _last_haptic_pattern: Array[int] = []
var _audio_play_count := 0


func _ready() -> void:
	for index: int in range(PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "FeedbackPlayer%d" % index
		player.bus = &"Master"
		add_child(player)
		_players.append(player)


func set_levels(master: float, effects: float, mute_dice := false) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	se_volume = clampf(effects, 0.0, 1.0)
	dice_muted = mute_dice
	var manager := get_node_or_null("/root/UiSfxManager")
	if manager != null:
		manager.call("set_volume", se_volume)


func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled
	if not enabled:
		_haptic_generation += 1
		Input.stop_joy_vibration(0)


func emit_feedback(event: StringName) -> void:
	if not HAPTIC_PATTERNS.has(event):
		return
	_last_event = event
	_event_counts[event] = int(_event_counts.get(event, 0)) + 1
	_last_haptic_pattern.clear()
	for duration: Variant in HAPTIC_PATTERNS[event]:
		_last_haptic_pattern.append(int(duration))
	_play_event_audio(event)
	_haptic_generation += 1
	if haptics_enabled and _mobile_haptics_available():
		_run_haptic_pattern(_haptic_generation, _last_haptic_pattern.duplicate())


func feedback_receipt() -> Dictionary:
	return {
		"last_event": String(_last_event),
		"last_haptic_pattern": _last_haptic_pattern.duplicate(),
		"event_counts": _event_counts.duplicate(true),
		"audio_play_count": _audio_play_count,
		"player_count": _players.size(),
		"master_volume": master_volume,
		"se_volume": se_volume,
		"dice_muted": dice_muted,
		"haptics_enabled": haptics_enabled,
	}


func _play_event_audio(event: StringName) -> void:
	if master_volume <= 0.0 or se_volume <= 0.0:
		return
	match event:
		EVENT_BUTTON:
			_play_ui_sfx(&"press", false)
		EVENT_ROLL_STOP:
			if not dice_muted:
				_play_stream(DICE_LOCK, -3.0)
		EVENT_REWARD:
			_play_ui_sfx(&"reward", true)
		EVENT_DAMAGE:
			_play_ui_sfx(&"warning", true)
			if not dice_muted:
				_play_stream(DICE_CONTACT, -1.0)
		EVENT_MISSION_COMPLETE:
			_play_ui_sfx(&"complete", true)
			if not dice_muted:
				_play_stream(DICE_LOCK, -7.0)
		EVENT_LEVEL_UP:
			_play_ui_sfx(&"level-up", true)
		EVENT_VICTORY:
			_play_ui_sfx(&"achievement", true)
			if not dice_muted:
				_play_stream(DICE_LAND, -4.0)
				_play_stream(DICE_LOCK, -6.0)
		EVENT_DEFEAT:
			_play_ui_sfx(&"error", true)
			if not dice_muted:
				_play_stream(DICE_CONTACT, -5.0)
		EVENT_BLOCKED:
			_play_ui_sfx(&"blocked", false)


func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	var manager := get_node_or_null("/root/UiSfxManager")
	if manager == null:
		return
	if bool(manager.call("play_ui_sfx", cue, world_specific)):
		_audio_play_count += 1


func _play_stream(stream: AudioStream, base_db: float) -> void:
	if _players.is_empty() or stream == null:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = base_db + linear_to_db(maxf(0.0001, master_volume * se_volume))
	player.play()
	_audio_play_count += 1


func _mobile_haptics_available() -> bool:
	return DisplayServer.get_name() != "headless" and OS.get_name() in ["Android", "iOS"]


func _run_haptic_pattern(generation: int, pattern: Array[int]) -> void:
	for index: int in range(pattern.size()):
		if generation != _haptic_generation or not haptics_enabled or not is_inside_tree():
			return
		Input.vibrate_handheld(pattern[index], 0.72)
		if index < pattern.size() - 1:
			await get_tree().create_timer(0.055).timeout
