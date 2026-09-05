class_name CasinoFeelFX
extends Node

const ROLL_STREAMS: Array[AudioStream] = [preload("res://assets/audio/dice/roll_01.wav"), preload("res://assets/audio/dice/roll_02.wav"), preload("res://assets/audio/dice/roll_03.wav"), preload("res://assets/audio/dice/roll_04.wav")]
const LAND_STREAMS: Array[AudioStream] = [preload("res://assets/audio/dice/land_01.wav"), preload("res://assets/audio/dice/land_02.wav"), preload("res://assets/audio/dice/land_03.wav"), preload("res://assets/audio/dice/land_04.wav")]
var _players: Array[AudioStreamPlayer] = []
var _cursor: int = 0

func _ready() -> void:
	for index: int in 3:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "FeelSfx%d" % index
		# Some exports do not ship a dedicated SFX bus; route safely to Master.
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

func _sfx(cue: StringName, world_specific: bool = false) -> void:
	var manager: Node = get_node_or_null("/root/UiSfxManager")
	if manager != null: manager.call("play_ui_sfx", cue, world_specific)

func _play_stream(stream: AudioStream, volume_db: float = -3.0) -> void:
	if _players.is_empty(): return
	var player: AudioStreamPlayer = _players[_cursor % _players.size()]
	_cursor += 1
	player.stream = stream
	player.volume_db = volume_db + _se_volume_db()
	player.play()

func press_button(button: Control = null, with_light_haptic: bool = false) -> void:
	_sfx(&"press", false)
	if button == null: return
	button.offset_transform_enabled = true
	button.pivot_offset = button.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(button, "offset_transform_scale", Vector2(0.96, 0.96), 0.06)
	tween.tween_property(button, "offset_transform_scale", Vector2.ONE, 0.10)
	if with_light_haptic:
		vibrate_light()

func play_dice_roll() -> void: _play_stream(ROLL_STREAMS[randi() % ROLL_STREAMS.size()], -5.0)
func play_dice_land() -> void:
	_play_stream(LAND_STREAMS[randi() % LAND_STREAMS.size()], -2.0)
	vibrate_light()

func animate_chip_change(label: Control = null) -> void:
	_sfx(&"reward", false)
	if label == null: return
	label.offset_transform_enabled = true
	label.pivot_offset = label.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(label, "offset_transform_scale", Vector2(1.06, 1.06), 0.10)
	tween.tween_property(label, "offset_transform_scale", Vector2.ONE, 0.18)

func animate_payout_change(label: Label, from_value: int, to_value: int) -> void:
	if label == null or from_value == to_value:
		return
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void:
		label.text = "%d CHIP" % roundi(value)
	, float(from_value), float(to_value), 0.52)
	tween.parallel().tween_callback(func() -> void: _sfx(&"reward", false))
	animate_chip_change(label)

func play_win_feedback() -> void:
	_sfx(&"bonus", true)
	vibrate_result()
func play_lose_feedback() -> void:
	_sfx(&"error", true)
	vibrate_result()

func play_tower_floor_up(floor_number: int) -> void:
	# Escalate presentation only; game model and BGM remain untouched.
	if floor_number >= 9:
		_sfx(&"warning", true)
	elif floor_number >= 4:
		_sfx(&"bonus", true)
	else:
		_sfx(&"progress-step", true)
	vibrate_light()

func play_tower_tension() -> void:
	_sfx(&"warning", true)

func play_tower_complete() -> void:
	_sfx(&"achievement", true)
	vibrate_result()

func play_tower_bust() -> void:
	_sfx(&"error", true)
	_sfx(&"drop", true)
	vibrate_result()

func animate_balance_change(label: Label, from_value: int, to_value: int) -> void:
	if label == null or from_value == to_value:
		return
	var tween: Tween = create_tween()
	tween.tween_method(func(value: float) -> void:
		label.text = "CASINO CHIP\n%d" % roundi(value)
	, float(from_value), float(to_value), 0.55)

func play_cashout_feedback(label: Control = null) -> void:
	_sfx(&"complete", true)
	animate_chip_change(label)
	vibrate_result()
func vibrate_light() -> void:
	if _haptics_enabled() and (OS.has_feature("android") or OS.has_feature("ios")): Input.vibrate_handheld(25)
func vibrate_result() -> void:
	if _haptics_enabled() and (OS.has_feature("android") or OS.has_feature("ios")): Input.vibrate_handheld(55)
func _haptics_enabled() -> bool:
	var state: Node = get_node_or_null("/root/GameState")
	return state == null or bool(state.get("haptics_enabled"))

func _se_volume_db() -> float:
	var state: Node = get_node_or_null("/root/GameState")
	if state == null:
		return 0.0
	var value: Variant = state.get("se_volume")
	if value == null:
		return 0.0
	var linear: float = clampf(float(value), 0.001, 1.0)
	return linear_to_db(linear)
