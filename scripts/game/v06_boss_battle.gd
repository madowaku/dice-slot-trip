class_name V06BossBattle
extends RefCounted

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")
const COURSE_PATH := "res://data/stages/v06_cairo_boss_race.json"
const PLAYER_MAX_HP := 3
const BOSS_MAX_HP := 3 # Legacy save/UI compatibility; the mirror race is position-based.
const GOAL_POSITION := 13
const SAFETY_MAX_TURNS := 12
const BOOST_DISTANCE := 2
const ACTION_MIRROR_ROLL: StringName = &"MIRROR_ROLL"

var _definition: Dictionary = {}
var _lap := 1
var _turn := 1
var _player_hp := PLAYER_MAX_HP
var _boss_hp := BOSS_MAX_HP
var _player_position := 0
var _boss_position := 0
var _player_next_modifier := 0
var _boss_next_modifier := 0
var _player_first_sand_available := true
var _player_roll_history: Array[int] = []
var _boss_roll_history: Array[int] = []
var _roll_set: RefCounted
var _pending_ack := false
var _terminal := false
var _winner := ""
var _last_result: Dictionary = {}


func _init() -> void:
	_roll_set = V06RollSetScript.new()
	_load_definition()


func configure_lap(lap: int, player_hp: int = PLAYER_MAX_HP, carried_faces: Array = [], run_flags: Dictionary = {}) -> bool:
	if lap < 1 or player_hp < 0 or player_hp > PLAYER_MAX_HP or _turn != 1 or _pending_ack or _terminal:
		return false
	if not _definition_valid():
		return false
	var carried_set: RefCounted = V06RollSetScript.new()
	if not carried_set.restore_faces(carried_faces) or carried_set.is_complete():
		return false
	_lap = lap
	_player_hp = player_hp
	_boss_hp = BOSS_MAX_HP
	_roll_set = carried_set
	_player_first_sand_available = bool(run_flags.get("boss_ignore_first_sand", true))
	return true


func roll_face(face: int) -> Dictionary:
	if face < 1 or face > 6:
		return _rejected("INVALID_FACE")
	if _terminal:
		return _rejected("BATTLE_TERMINAL")
	if _pending_ack:
		return _rejected("TURN_ACK_REQUIRED")
	if not _roll_set.append_face(face):
		return _rejected("ROLL_REJECTED")
	_resolve_turn(face)
	return {"ok": true, "status": "TURN_RESOLVED", "result": result()}


func acknowledge_round() -> bool:
	if not _pending_ack:
		return false
	if _roll_set.is_complete() and not _roll_set.reset_after_resolution():
		return false
	_pending_ack = false
	if _terminal:
		return true
	_turn += 1
	_last_result.clear()
	return true


func faces() -> Array[int]:
	return _roll_set.faces()


func result() -> Dictionary:
	return _last_result.duplicate(true)


func snapshot() -> Dictionary:
	return {
		"schema_version": str(_definition.get("schema_version", "dice-slot-trip.boss-race/1")),
		"boss_id": str(_definition.get("boss_id", "sphinx")),
		"boss_display_name": str(_definition.get("boss_display_name", "スフィンクス")),
		"lap": _lap,
		"round": _turn,
		"turn": _turn,
		"faces": faces(),
		"action": ACTION_MIRROR_ROLL,
		"defense": 0,
		"player_hp": _player_hp,
		"boss_hp": _boss_hp,
		"course_length": goal_position(),
		"player_position": _player_position,
		"boss_position": _boss_position,
		"player_next_modifier": _player_next_modifier,
		"boss_next_modifier": _boss_next_modifier,
		"player_first_sand_available": _player_first_sand_available,
		"player_roll_history": _player_roll_history.duplicate(),
		"boss_roll_history": _boss_roll_history.duplicate(),
		"pending_ack": _pending_ack,
		"victory": _terminal and _winner == "player",
		"defeat": _terminal and _winner == "boss",
		"winner": _winner,
		"terminal": _terminal,
		"result": result(),
	}


func restore_snapshot(data: Dictionary) -> bool:
	if str(data.get("schema_version", "")) != "dice-slot-trip.boss-race/1":
		return false
	if str(data.get("boss_id", "")) != "sphinx":
		return false
	var lap := int(data.get("lap", 0))
	var turn := int(data.get("turn", data.get("round", 0)))
	var player_hp := int(data.get("player_hp", -1))
	var boss_hp := int(data.get("boss_hp", -1))
	var player_position := int(data.get("player_position", -1))
	var boss_position := int(data.get("boss_position", -1))
	var player_modifier := int(data.get("player_next_modifier", 99))
	var boss_modifier := int(data.get("boss_next_modifier", 99))
	var faces_value: Variant = data.get("faces", [])
	var player_history_value: Variant = data.get("player_roll_history", [])
	var boss_history_value: Variant = data.get("boss_roll_history", [])
	var result_value: Variant = data.get("result", {})
	var pending_ack := bool(data.get("pending_ack", false))
	var terminal := bool(data.get("terminal", false))
	var winner := str(data.get("winner", ""))
	if lap < 1 or turn < 1 or player_hp < 0 or player_hp > PLAYER_MAX_HP or boss_hp < 0 or boss_hp > BOSS_MAX_HP:
		return false
	if player_position < 0 or player_position > goal_position() or boss_position < 0 or boss_position > goal_position():
		return false
	if player_modifier not in [-1, 0, 1] or boss_modifier not in [-1, 0, 1]:
		return false
	if not faces_value is Array or not player_history_value is Array or not boss_history_value is Array or not result_value is Dictionary:
		return false
	if player_history_value.size() != boss_history_value.size() or player_history_value.size() > SAFETY_MAX_TURNS:
		return false
	if terminal != (winner in ["player", "boss"]):
		return false
	if not terminal and not winner.is_empty():
		return false
	var restored_set: RefCounted = V06RollSetScript.new()
	if not restored_set.restore_faces(faces_value as Array):
		return false
	if pending_ack and (result_value as Dictionary).is_empty():
		return false
	if not pending_ack and not terminal and not (result_value as Dictionary).is_empty():
		return false
	var restored_player_history: Array[int] = []
	var restored_boss_history: Array[int] = []
	for index: int in range(player_history_value.size()):
		var player_roll := int(player_history_value[index])
		var boss_roll := int(boss_history_value[index])
		if player_roll < 1 or player_roll > 6 or boss_roll != 7 - player_roll:
			return false
		restored_player_history.append(player_roll)
		restored_boss_history.append(boss_roll)
	_lap = lap
	_turn = turn
	_player_hp = player_hp
	_boss_hp = boss_hp
	_player_position = player_position
	_boss_position = boss_position
	_player_next_modifier = player_modifier
	_boss_next_modifier = boss_modifier
	_player_first_sand_available = bool(data.get("player_first_sand_available", false))
	_player_roll_history = restored_player_history
	_boss_roll_history = restored_boss_history
	_roll_set = restored_set
	_pending_ack = pending_ack
	_terminal = terminal
	_winner = winner
	_last_result = (result_value as Dictionary).duplicate(true)
	return true


func current_action() -> StringName:
	return ACTION_MIRROR_ROLL


func current_defense() -> int:
	return 0


func goal_position() -> int:
	return int(_definition.get("goal_position", GOAL_POSITION))


func tile_at(position: int) -> String:
	var course: Variant = _definition.get("course", [])
	if not course is Array or position < 0 or position >= (course as Array).size():
		return ""
	return str((course as Array)[position])


func _resolve_turn(committed_face: int) -> void:
	var player_roll := clampi(committed_face, 1, 6)
	var boss_roll := 7 - player_roll
	var player_move := maxi(player_roll + _player_next_modifier, 1)
	var boss_move := maxi(boss_roll + _boss_next_modifier, 1)
	var player_before := _player_position
	var boss_before := _boss_position
	var player_modifier_used := _player_next_modifier
	var boss_modifier_used := _boss_next_modifier
	_player_next_modifier = 0
	_boss_next_modifier = 0
	_player_roll_history.append(player_roll)
	_boss_roll_history.append(boss_roll)
	var role: StringName = _roll_set.evaluate_role()
	var winner := _base_movement_winner(player_move, boss_move)
	_player_position = mini(_player_position + player_move, goal_position())
	_boss_position = mini(_boss_position + boss_move, goal_position())
	var player_tile := ""
	var boss_tile := ""
	var player_effect := ""
	var boss_effect := ""
	if winner.is_empty():
		player_tile = tile_at(_player_position)
		boss_tile = tile_at(_boss_position)
		player_effect = _apply_landing_effect(true, player_tile)
		boss_effect = _apply_landing_effect(false, boss_tile)
		winner = _boost_winner(player_effect, boss_effect)
	if winner.is_empty() and _player_roll_history.size() >= int(_definition.get("safety_max_turns", SAFETY_MAX_TURNS)):
		winner = "player" if _player_position >= _boss_position else "boss"
	_terminal = not winner.is_empty()
	_winner = winner
	_pending_ack = true
	var win_reason := ""
	if _terminal:
		if _player_roll_history.size() >= int(_definition.get("safety_max_turns", SAFETY_MAX_TURNS)) and _player_position < goal_position() and _boss_position < goal_position():
			win_reason = "SAFETY_LIMIT_POSITION"
		elif player_effect == "BOOST" or boss_effect == "BOOST":
			win_reason = "BOOST_GOAL"
		else:
			win_reason = "BASE_MOVE_GOAL"
	_last_result = {
		"turn": _turn,
		"faces": faces(),
		"role": role,
		"player_roll": player_roll,
		"boss_roll": boss_roll,
		"player_move": player_move,
		"boss_move": boss_move,
		"player_modifier_used": player_modifier_used,
		"boss_modifier_used": boss_modifier_used,
		"player_position_before": player_before,
		"boss_position_before": boss_before,
		"player_position_after": _player_position,
		"boss_position_after": _boss_position,
		"turn_count": _player_roll_history.size(),
		"player_final_position": _player_position,
		"boss_final_position": _boss_position,
		"player_roll_history": _player_roll_history.duplicate(),
		"boss_roll_history": _boss_roll_history.duplicate(),
		"player_tile": player_tile,
		"boss_tile": boss_tile,
		"player_effect": player_effect,
		"boss_effect": boss_effect,
		"player_hp_before": _player_hp,
		"player_hp_after": _player_hp,
		"boss_hp_before": _boss_hp,
		"boss_hp_after": _boss_hp,
		"victory": _terminal and _winner == "player",
		"defeat": _terminal and _winner == "boss",
		"record_boss_win": _terminal and _winner == "player",
		"record_boss_loss": _terminal and _winner == "boss",
		"boss_stamp": "cairo_sphinx_win" if _terminal and _winner == "player" else "",
		"score_bonus": 1000 if _terminal and _winner == "player" else 0,
		"stage_rating_bonus": 1 if _terminal and _winner == "player" else 0,
		"winner": _winner,
		"win_reason": win_reason,
	}


func _base_movement_winner(player_move: int, boss_move: int) -> String:
	var player_steps := goal_position() - _player_position
	var boss_steps := goal_position() - _boss_position
	var player_reaches := player_move >= player_steps
	var boss_reaches := boss_move >= boss_steps
	if player_reaches and boss_reaches:
		return "player" if player_steps <= boss_steps else "boss"
	if player_reaches:
		return "player"
	if boss_reaches:
		return "boss"
	return ""


func _apply_landing_effect(is_player: bool, tile: String) -> String:
	match tile:
		"BOOST":
			if is_player:
				_player_position = mini(_player_position + BOOST_DISTANCE, goal_position())
			else:
				_boss_position = mini(_boss_position + BOOST_DISTANCE, goal_position())
			return "BOOST"
		"SAND":
			if is_player and _player_first_sand_available:
				_player_first_sand_available = false
				return "SAND_IGNORED"
			if is_player:
				_player_next_modifier = -1
			else:
				_boss_next_modifier = -1
			return "SAND"
		"WIND":
			if is_player:
				_player_next_modifier = 1
			else:
				_boss_next_modifier = 1
			return "WIND"
	return ""


func _boost_winner(player_effect: String, boss_effect: String) -> String:
	var player_reaches := player_effect == "BOOST" and _player_position >= goal_position()
	var boss_reaches := boss_effect == "BOOST" and _boss_position >= goal_position()
	if player_reaches and boss_reaches:
		return "player"
	if player_reaches:
		return "player"
	if boss_reaches:
		return "boss"
	return ""


func _load_definition() -> void:
	if not FileAccess.file_exists(COURSE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COURSE_PATH))
	if parsed is Dictionary:
		_definition = (parsed as Dictionary).duplicate(true)


func _definition_valid() -> bool:
	if str(_definition.get("schema_version", "")) != "dice-slot-trip.boss-race/1":
		return false
	if str(_definition.get("boss_id", "")) != "sphinx":
		return false
	var course: Variant = _definition.get("course", [])
	if not course is Array or (course as Array).size() != goal_position() + 1:
		return false
	if str((course as Array)[0]) != "START" or str((course as Array)[goal_position()]) != "GOAL":
		return false
	for tile: Variant in course:
		if str(tile) not in ["START", "NORMAL", "BOOST", "SAND", "WIND", "GOAL"]:
			return false
	return true


func _rejected(error: String) -> Dictionary:
	return {"ok": false, "status": error, "error": error}
