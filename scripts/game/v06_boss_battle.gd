class_name V06BossBattle
extends RefCounted

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")
const COURSE_PATH := "res://data/stages/v06_cairo_boss_race.json"
const SCHEMA_VERSION := "dice-slot-trip.boss-race/3"
const PLAYER_MAX_HP := 3
const BOSS_MAX_HP := 3
const GOAL_POSITION := 20
const SAFETY_MAX_TURNS := 11
const WING_GATE_DISTANCE := 3
const QUICKSAND_DISTANCE := 2
const STRAIGHT_BONUS_DISTANCE := 3
const TRIPLE_BONUS_DISTANCE := 5
const ACTION_MIRROR_ROLL: StringName = &"MIRROR_ROLL"

var _definition: Dictionary = {}
var _lap := 1
var _turn := 1
var _player_hp := PLAYER_MAX_HP
var _boss_hp := BOSS_MAX_HP
var _player_position := 0
var _boss_position := 0
var _player_roll_history: Array[int] = []
var _boss_roll_history: Array[int] = []
var _player_wing_count := 0
var _player_sand_count := 0
var _boss_wing_count := 0
var _boss_sand_count := 0
var _boss_next_move_halved := false
var _boss_stop_turns := 0
var _role_counts: Dictionary = {"PAIR": 0, "STRAIGHT": 0, "TRIPLE": 0}
var _roll_set: RefCounted
var _pending_ack := false
var _terminal := false
var _winner := ""
var _last_result: Dictionary = {}


func _init() -> void:
	_roll_set = V06RollSetScript.new()
	_load_definition()


func configure_lap(lap: int, player_hp: int = PLAYER_MAX_HP, _carried_faces: Array = [], run_flags: Dictionary = {}) -> bool:
	if lap < 1 or player_hp < 0 or player_hp > PLAYER_MAX_HP or _turn != 1 or _pending_ack or _terminal or not _definition_valid():
		return false
	_lap = lap
	_player_hp = player_hp
	_player_position = clampi(int(run_flags.get("player_head_start", 0)), 0, goal_position())
	_boss_next_move_halved = bool(run_flags.get("boss_next_move_halved", false))
	_boss_stop_turns = maxi(int(run_flags.get("boss_stop_turns", 0)), 0)
	_roll_set = V06RollSetScript.new()
	return true


func apply_pre_race_support(action_id: String) -> bool:
	if _turn != 1 or _pending_ack or _terminal or not _player_roll_history.is_empty() or not faces().is_empty():
		return false
	match action_id:
		"boss_shield":
			_boss_next_move_halved = true
		"boss_head_start":
			_player_position = mini(_player_position + 3, goal_position())
		"boss_sabotage":
			_boss_stop_turns = maxi(_boss_stop_turns, 1)
		_:
			return false
	return true


func roll_face(face: int) -> Dictionary:
	if face < 1 or face > 6:
		return _rejected("INVALID_FACE")
	if _terminal:
		return _rejected("BATTLE_TERMINAL")
	if _pending_ack:
		return _rejected("TURN_ACK_REQUIRED")
	_resolve_turn(face)
	return {"ok": true, "status": "TURN_RESOLVED", "result": result()}


func acknowledge_round() -> bool:
	if not _pending_ack:
		return false
	_pending_ack = false
	if not _terminal:
		_turn += 1
		_last_result.clear()
	return true


func faces() -> Array[int]:
	return _roll_set.faces()


func result() -> Dictionary:
	return _last_result.duplicate(true)


func snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"boss_id": "sphinx",
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
		# Kept as zero-valued compatibility fields for existing stable saves.
		"player_next_modifier": 0,
		"boss_next_modifier": 0,
		"player_first_sand_available": false,
		"player_roll_history": _player_roll_history.duplicate(),
		"boss_roll_history": _boss_roll_history.duplicate(),
		"player_wing_count": _player_wing_count,
		"player_sand_count": _player_sand_count,
		"boss_wing_count": _boss_wing_count,
		"boss_sand_count": _boss_sand_count,
		"boss_next_move_halved": _boss_next_move_halved,
		"boss_stop_turns": _boss_stop_turns,
		"role_counts": _role_counts.duplicate(true),
		"pending_ack": _pending_ack,
		"victory": _terminal and _winner == "player",
		"defeat": _terminal and _winner == "boss",
		"winner": _winner,
		"terminal": _terminal,
		"result": result(),
	}


func restore_snapshot(data: Dictionary) -> bool:
	if str(data.get("schema_version", "")) != SCHEMA_VERSION or str(data.get("boss_id", "")) != "sphinx":
		return false
	var lap := int(data.get("lap", 0))
	var turn := int(data.get("turn", data.get("round", 0)))
	var player_hp := int(data.get("player_hp", -1))
	var boss_hp := int(data.get("boss_hp", -1))
	var player_position := int(data.get("player_position", -1))
	var boss_position := int(data.get("boss_position", -1))
	var faces_value: Variant = data.get("faces", [])
	var player_history_value: Variant = data.get("player_roll_history", [])
	var boss_history_value: Variant = data.get("boss_roll_history", [])
	var result_value: Variant = data.get("result", {})
	var player_wing_count := int(data.get("player_wing_count", 0))
	var player_sand_count := int(data.get("player_sand_count", 0))
	var boss_wing_count := int(data.get("boss_wing_count", 0))
	var boss_sand_count := int(data.get("boss_sand_count", 0))
	var boss_next_move_halved := bool(data.get("boss_next_move_halved", false))
	var boss_stop_turns := int(data.get("boss_stop_turns", 0))
	var role_counts_value: Variant = data.get("role_counts", {})
	var pending_ack := bool(data.get("pending_ack", false))
	var terminal := bool(data.get("terminal", false))
	var winner := str(data.get("winner", ""))
	if lap < 1 or turn < 1 or player_hp < 0 or player_hp > PLAYER_MAX_HP or boss_hp < 0 or boss_hp > BOSS_MAX_HP:
		return false
	if player_position < 0 or player_position > goal_position() or boss_position < 0 or boss_position > goal_position():
		return false
	if not faces_value is Array or not player_history_value is Array or not boss_history_value is Array or not result_value is Dictionary:
		return false
	if player_history_value.size() != boss_history_value.size() or player_history_value.size() > SAFETY_MAX_TURNS:
		return false
	if terminal != (winner in ["player", "boss"]) or (not terminal and not winner.is_empty()):
		return false
	if [player_wing_count, player_sand_count, boss_wing_count, boss_sand_count, boss_stop_turns].min() < 0 or not role_counts_value is Dictionary:
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
	_player_roll_history = restored_player_history
	_boss_roll_history = restored_boss_history
	_player_wing_count = player_wing_count
	_player_sand_count = player_sand_count
	_boss_wing_count = boss_wing_count
	_boss_sand_count = boss_sand_count
	_boss_next_move_halved = boss_next_move_halved
	_boss_stop_turns = boss_stop_turns
	_role_counts = {"PAIR": 0, "STRAIGHT": 0, "TRIPLE": 0}
	for role_name: String in _role_counts.keys():
		_role_counts[role_name] = maxi(int((role_counts_value as Dictionary).get(role_name, 0)), 0)
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


func tile_at(position: int, is_player: bool = true) -> String:
	var key := "player_course" if is_player else "boss_course"
	var course: Variant = _definition.get(key, [])
	if not course is Array or position < 0 or position >= (course as Array).size():
		return ""
	return str((course as Array)[position])


func course_tiles(is_player: bool = true) -> Array:
	var key := "player_course" if is_player else "boss_course"
	var course: Variant = _definition.get(key, [])
	return (course as Array).duplicate() if course is Array else []


func landing_preview(player_face: int) -> Dictionary:
	var face := clampi(player_face, 1, 6)
	var boss_face := 7 - face
	var boss_move := _preview_boss_move(boss_face)
	var player_landing := mini(_player_position + face, goal_position())
	var boss_landing := mini(_boss_position + boss_move, goal_position())
	var player_tile := tile_at(player_landing, true)
	var boss_tile := tile_at(boss_landing, false)
	var player_final := _preview_effect_position(player_landing, player_tile)
	var boss_final := _preview_effect_position(boss_landing, boss_tile)
	return {
		"player_roll": face,
		"boss_roll": boss_face,
		"boss_move": boss_move,
		"player_position": player_landing,
		"boss_position": boss_landing,
		"player_tile": player_tile,
		"boss_tile": boss_tile,
		"player_final_position": player_final,
		"boss_final_position": boss_final,
		"player_distance_to_goal": goal_position() - player_final,
		"boss_distance_to_goal": goal_position() - boss_final,
	}


func _preview_effect_position(position: int, tile: String) -> int:
	match tile:
		"WING_GATE":
			return mini(position + WING_GATE_DISTANCE, goal_position())
		"QUICKSAND":
			return maxi(position - QUICKSAND_DISTANCE, 0)
		_:
			return position


func _resolve_turn(committed_face: int) -> void:
	var player_roll := clampi(committed_face, 1, 6)
	var boss_roll := 7 - player_roll
	var boss_move := _consume_boss_move(boss_roll)
	var player_before := _player_position
	var boss_before := _boss_position
	_player_roll_history.append(player_roll)
	_boss_roll_history.append(boss_roll)
	_roll_set.append_face(player_roll)
	var completed_faces: Array[int] = _roll_set.faces()
	var role: StringName = _roll_set.evaluate_role()
	_player_position = mini(_player_position + player_roll, goal_position())
	_boss_position = mini(_boss_position + boss_move, goal_position())
	var player_base_after := _player_position
	var boss_base_after := _boss_position
	var player_tile := tile_at(_player_position, true)
	var boss_tile := tile_at(_boss_position, false) if boss_move > 0 else "NORMAL"
	var player_effect := ""
	var boss_effect := ""
	player_effect = _apply_landing_effect(true, player_tile)
	if boss_move > 0:
		boss_effect = _apply_landing_effect(false, boss_tile)
	var player_effect_position_after := _player_position
	var boss_effect_position_after := _boss_position
	var role_bonus := _apply_role(role)
	var winner := _effect_winner()
	if winner.is_empty() and _player_roll_history.size() >= int(_definition.get("safety_max_turns", SAFETY_MAX_TURNS)):
		winner = "player" if _player_position >= _boss_position else "boss"
	_terminal = not winner.is_empty()
	_winner = winner
	_pending_ack = true
	var win_reason := ""
	if _terminal:
		if _player_roll_history.size() >= int(_definition.get("safety_max_turns", SAFETY_MAX_TURNS)) and _player_position < goal_position() and _boss_position < goal_position():
			win_reason = "SAFETY_LIMIT_POSITION"
		elif role_bonus > 0:
			win_reason = "SLOT_ROLE_GOAL"
		elif player_effect == "WING_GATE" or boss_effect == "WING_GATE":
			win_reason = "WING_GATE_GOAL"
		else:
			win_reason = "BASE_MOVE_GOAL"
	_last_result = {
		"turn": _turn,
		"faces": completed_faces,
		"role": role,
		"player_roll": player_roll,
		"boss_roll": boss_roll,
		"player_move": player_roll,
		"boss_move": boss_move,
		"player_modifier_used": 0,
		"boss_modifier_used": 0,
		"player_position_before": player_before,
		"boss_position_before": boss_before,
		"player_base_position_after": player_base_after,
		"boss_base_position_after": boss_base_after,
		"player_effect_position_after": player_effect_position_after,
		"boss_effect_position_after": boss_effect_position_after,
		"player_position_after": _player_position,
		"boss_position_after": _boss_position,
		"turn_count": _player_roll_history.size(),
		"player_final_position": _player_position,
		"boss_final_position": _boss_position,
		"player_roll_history": _player_roll_history.duplicate(),
		"boss_roll_history": _boss_roll_history.duplicate(),
		"player_wing_count": _player_wing_count,
		"player_sand_count": _player_sand_count,
		"boss_wing_count": _boss_wing_count,
		"boss_sand_count": _boss_sand_count,
		"player_tile": player_tile,
		"boss_tile": boss_tile,
		"player_effect": player_effect,
		"boss_effect": boss_effect,
		"player_effect_delta": _effect_delta(player_effect),
		"boss_effect_delta": _effect_delta(boss_effect),
		"role_bonus": role_bonus,
		"role_effect": _role_effect_name(role),
		"boss_move_halved": boss_move > 0 and boss_move < boss_roll,
		"boss_move_stopped": boss_move == 0,
		"boss_next_move_halved": _boss_next_move_halved,
		"boss_stop_turns": _boss_stop_turns,
		"role_counts": _role_counts.duplicate(true),
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
	if _roll_set.is_complete():
		_roll_set.reset_after_resolution()


func _preview_boss_move(boss_roll: int) -> int:
	if _boss_stop_turns > 0:
		return 0
	if _boss_next_move_halved:
		return ceili(float(boss_roll) * 0.5)
	return boss_roll


func _consume_boss_move(boss_roll: int) -> int:
	if _boss_stop_turns > 0:
		_boss_stop_turns -= 1
		return 0
	if _boss_next_move_halved:
		_boss_next_move_halved = false
		return ceili(float(boss_roll) * 0.5)
	return boss_roll


func _apply_role(role: StringName) -> int:
	match role:
		V06RollSetScript.ROLE_PAIR:
			_boss_next_move_halved = true
			_role_counts.PAIR += 1
		V06RollSetScript.ROLE_STRAIGHT:
			_player_position = mini(_player_position + STRAIGHT_BONUS_DISTANCE, goal_position())
			_role_counts.STRAIGHT += 1
			return STRAIGHT_BONUS_DISTANCE
		V06RollSetScript.ROLE_TRIPLE:
			_player_position = mini(_player_position + TRIPLE_BONUS_DISTANCE, goal_position())
			_boss_stop_turns += 1
			_role_counts.TRIPLE += 1
			return TRIPLE_BONUS_DISTANCE
	return 0


func _role_effect_name(role: StringName) -> String:
	match role:
		V06RollSetScript.ROLE_PAIR: return "SHIELD"
		V06RollSetScript.ROLE_STRAIGHT: return "ACCELERATE"
		V06RollSetScript.ROLE_TRIPLE: return "FINISHER"
		_: return ""


func _arrival_winner(player_before: int, boss_before: int, player_move: int, boss_move: int) -> String:
	var player_steps := goal_position() - player_before
	var boss_steps := goal_position() - boss_before
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
		"WING_GATE":
			if is_player:
				_player_position = mini(_player_position + WING_GATE_DISTANCE, goal_position())
				_player_wing_count += 1
			else:
				_boss_position = mini(_boss_position + WING_GATE_DISTANCE, goal_position())
				_boss_wing_count += 1
			return "WING_GATE"
		"QUICKSAND":
			if is_player:
				_player_position = maxi(_player_position - QUICKSAND_DISTANCE, 0)
				_player_sand_count += 1
			else:
				_boss_position = maxi(_boss_position - QUICKSAND_DISTANCE, 0)
				_boss_sand_count += 1
			return "QUICKSAND"
	return ""


func _effect_delta(effect: String) -> int:
	if effect == "WING_GATE":
		return WING_GATE_DISTANCE
	if effect == "QUICKSAND":
		return -QUICKSAND_DISTANCE
	return 0


func _effect_winner() -> String:
	var player_reaches := _player_position >= goal_position()
	var boss_reaches := _boss_position >= goal_position()
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
	if str(_definition.get("schema_version", "")) != SCHEMA_VERSION or str(_definition.get("boss_id", "")) != "sphinx":
		return false
	for key: String in ["player_course", "boss_course"]:
		var course: Variant = _definition.get(key, [])
		if not course is Array or (course as Array).size() != goal_position() + 1:
			return false
		if str((course as Array)[0]) != "START" or str((course as Array)[goal_position()]) != "GOAL":
			return false
		for tile: Variant in course:
			if str(tile) not in ["START", "NORMAL", "WING_GATE", "QUICKSAND", "GOAL"]:
				return false
	return true


func _rejected(error: String) -> Dictionary:
	return {"ok": false, "status": error, "error": error}
