class_name DiceAudioController
extends Node

const PLAYER_POOL_SIZE := 9
const MAX_ROLL_VOICES := 2
const MAX_FIVE_DICE_CONTACTS := 4
const LAUNCH_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/dice/launch_01.wav"),
	preload("res://assets/audio/dice/launch_02.wav")
]
const ROLL_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/dice/roll_01.wav"),
	preload("res://assets/audio/dice/roll_02.wav"),
	preload("res://assets/audio/dice/roll_03.wav"),
	preload("res://assets/audio/dice/roll_04.wav")
]
const CONTACT_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/dice/contact_01.wav"),
	preload("res://assets/audio/dice/contact_02.wav"),
	preload("res://assets/audio/dice/contact_03.wav")
]
const LAND_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/dice/land_01.wav"),
	preload("res://assets/audio/dice/land_02.wav"),
	preload("res://assets/audio/dice/land_03.wav"),
	preload("res://assets/audio/dice/land_04.wav")
]
const LOCK_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/dice/lock_01.wav"),
	preload("res://assets/audio/dice/lock_02.wav")
]

const BASE_DB := {"launch": -20.0, "roll": -24.0, "contact": -23.0, "land": -18.0, "lock": -26.0}
const PITCH_RANGES := {
	"launch": Vector2(0.97, 1.03), "roll": Vector2(0.94, 1.06),
	"contact": Vector2(0.95, 1.05), "land": Vector2(0.96, 1.04), "lock": Vector2(0.99, 1.01)
}

var launch_player: AudioStreamPlayer
var rolling_players: Array[AudioStreamPlayer] = []
var contact_players: Array[AudioStreamPlayer] = []
var landing_players: Array[AudioStreamPlayer] = []
var lock_player: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var last_variation := {"launch": -1, "roll": -1, "contact": -1, "land": -1, "lock": -1}
var play_counts := {"launch": 0, "roll": 0, "contact": 0, "land": 0, "lock": 0}
var master_volume := 1.0
var se_volume := 1.0
var muted := false
var roll_generation := 0
var active_dice_count := 1
var launch_played := false
var contact_count := 0
var landed_indices: Dictionary = {}
var locked_indices: Dictionary = {}
var last_roll_tick := -1000

func _ready() -> void:
	rng.randomize()
	launch_player = _make_player("DiceLaunch")
	for index: int in range(2): rolling_players.append(_make_player("DiceRoll%d" % index))
	for index: int in range(2): contact_players.append(_make_player("DiceContact%d" % index))
	for index: int in range(3): landing_players.append(_make_player("DiceLand%d" % index))
	lock_player = _make_player("DiceLock")

func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Master"
	add_child(player)
	return player

func set_levels(master: float, se: float, dice_muted: bool = false) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	se_volume = clampf(se, 0.0, 1.0)
	muted = dice_muted
	if _is_silent(): stop_all()

func set_muted(value: bool) -> void:
	muted = value
	if muted: stop_all()

func begin_roll(dice_count: int) -> void:
	roll_generation += 1
	active_dice_count = clampi(dice_count, 1, 5)
	launch_played = false
	contact_count = 0
	landed_indices.clear()
	locked_indices.clear()
	last_roll_tick = -1000
	stop_all_roll_sounds()
	play_launch()

func play_launch() -> void:
	if launch_played or _is_silent(): return
	launch_played = true
	_play("launch", LAUNCH_STREAMS, [launch_player], 0.0)

func play_roll(speed_ratio: float = 1.0) -> void:
	if _is_silent(): return
	var speed := clampf(speed_ratio, 0.0, 1.0)
	var interval_ms := roundi(lerpf(165.0, 78.0, speed))
	var now := Time.get_ticks_msec()
	if now - last_roll_tick < interval_ms: return
	last_roll_tick = now
	_play("roll", ROLL_STREAMS, rolling_players, _mix_penalty() - (1.0 - speed) * 1.2, lerpf(-0.025, 0.025, speed))

func play_contact(intensity: float = 0.5) -> void:
	if _is_silent(): return
	var cap := MAX_FIVE_DICE_CONTACTS if active_dice_count >= 5 else mini(3, active_dice_count * 2)
	if contact_count >= cap: return
	contact_count += 1
	_play("contact", CONTACT_STREAMS, contact_players, _mix_penalty() + clampf(intensity, 0.0, 1.0) * 0.8)

func play_land(dice_index: int, impact_strength: float = 0.65) -> void:
	if _is_silent() or landed_indices.has(dice_index): return
	landed_indices[dice_index] = true
	play_counts["land"] = int(play_counts.land) + 1
	var impact := clampf(impact_strength, 0.0, 1.0)
	_play("land", LAND_STREAMS, landing_players, _mix_penalty() + impact * 1.3, (impact - 0.5) * 0.025, false)
	if not locked_indices.has(dice_index):
		locked_indices[dice_index] = true
		play_lock()

func play_lock() -> void:
	if _is_silent(): return
	_play("lock", LOCK_STREAMS, [lock_player], _mix_penalty())

func end_roll() -> void:
	stop_all_roll_sounds()

func stop_all_roll_sounds() -> void:
	for player: AudioStreamPlayer in rolling_players: player.stop()

func stop_all() -> void:
	if is_instance_valid(launch_player): launch_player.stop()
	for pool: Array[AudioStreamPlayer] in [rolling_players, contact_players, landing_players]:
		for player: AudioStreamPlayer in pool: player.stop()
	if is_instance_valid(lock_player): lock_player.stop()

func active_voice_count() -> int:
	var count := 0
	for child: Node in get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing: count += 1
	return count

func receipt() -> Dictionary:
	return {
		"pool_size": get_child_count(), "rolling_pool": rolling_players.size(),
		"contact_pool": contact_players.size(), "landing_pool": landing_players.size(),
		"active_voices": active_voice_count(), "contacts_this_roll": contact_count,
		"landed_count": landed_indices.size(), "play_counts": play_counts.duplicate(true),
		"muted": muted, "silent": _is_silent()
	}

func _play(category: String, streams: Array[AudioStream], players: Array[AudioStreamPlayer], extra_db: float = 0.0, pitch_offset: float = 0.0, count_play: bool = true) -> bool:
	if _is_silent(): return false
	var player: AudioStreamPlayer
	for candidate: AudioStreamPlayer in players:
		if not candidate.playing:
			player = candidate
			break
	if player == null: return false
	var last := int(last_variation.get(category, -1))
	var variation := next_variation_index(streams.size(), last, rng.randi())
	last_variation[category] = variation
	var pitch_range: Vector2 = PITCH_RANGES[category]
	player.stream = streams[variation]
	player.pitch_scale = clampf(rng.randf_range(pitch_range.x, pitch_range.y) + pitch_offset, 0.85, 1.15)
	player.volume_db = float(BASE_DB[category]) + rng.randf_range(-1.0, 1.0) + extra_db + linear_to_db(maxf(0.0001, master_volume * se_volume))
	player.play()
	if count_play: play_counts[category] = int(play_counts[category]) + 1
	return true

func _mix_penalty() -> float:
	if active_dice_count >= 5: return -3.8
	if active_dice_count >= 3: return -1.5
	if active_dice_count == 2: return -0.8
	return 0.0

func _is_silent() -> bool:
	return muted or master_volume <= 0.0 or se_volume <= 0.0

static func next_variation_index(size: int, previous: int, random_value: int) -> int:
	if size <= 1: return 0
	var candidate := posmod(random_value, size - 1)
	if previous >= 0 and candidate >= previous: candidate += 1
	return candidate

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_PREDELETE]:
		stop_all()
