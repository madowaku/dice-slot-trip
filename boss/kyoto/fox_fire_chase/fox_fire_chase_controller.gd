class_name FoxFireChaseController
extends Node

const ROLL_SET_SCRIPT_PATH: String = "res://scripts/game/v06_roll_set.gd"
const V06RollSetScript = preload(ROLL_SET_SCRIPT_PATH)
const BoardScript = preload("res://boss/kyoto/fox_fire_chase/fox_fire_chase_board.gd")
const StateScript = preload("res://boss/kyoto/fox_fire_chase/data/fox_fire_chase_state.gd")
const ResultScript = preload("res://boss/kyoto/fox_fire_chase/data/fox_fire_chase_result.gd")
const DifficultyScript = preload("res://boss/kyoto/fox_fire_chase/data/fox_fire_chase_difficulty.gd")

enum Phase {
	PRE_BATTLE,
	ROLL_READY,
	FIRE_CHOICE,
	TURN_RESOLVED,
	VICTORY,
	DEFEAT,
}
const BattlePhase = Phase # Familiar alias for the other Kyoto boss package.

const SNAPSHOT_VERSION: int = 2
const LEGACY_SNAPSHOT_VERSION: int = 1
const BATTLE_ID: String = "fox_fire_chase"
const INITIAL_DISTANCE: int = 10
const HEAD_START_COST: int = 3
const MAX_HEAD_STARTS: int = 2
const CHOICE_CLEANSE: StringName = &"CLEANSE"
const CHOICE_DETOUR: StringName = &"DETOUR"

signal phase_changed(phase: int)
signal state_changed(saved_snapshot: Dictionary)
signal coins_changed(coins: int, head_start_count: int)
signal fire_choice_requested(outer_index: int, goshuin_count: int)
signal turn_resolved(event: Dictionary)
signal battle_finished(result: Dictionary)

var state: FoxFireChaseState = StateScript.new()
var battle_seed: int = 0
var difficulty: FoxFireChaseDifficulty = DifficultyScript.for_lap(1)

var _roll_set: RefCounted = V06RollSetScript.new()
var _result: FoxFireChaseResult = ResultScript.new()
var _configured: bool = false


func _init() -> void:
	state.phase = Phase.PRE_BATTLE
	_sync_piece_positions()


func configure(
	battle_lap: int = 1,
	goshuin_count: int = 0,
	coins: int = 0,
	seed: int = 0,
	saved_snapshot: Dictionary = {}
) -> bool:
	## Short compatibility entry point used by headless tools and older Kyoto
	## callers.  The scene wrapper uses the more explicit configure_battle name.
	return configure_battle(battle_lap, goshuin_count, coins, seed, saved_snapshot)


func configure_battle(
	battle_lap: int = 1,
	goshuin_count: int = 0,
	coins: int = 0,
	seed: int = 0,
	saved_snapshot: Dictionary = {}
) -> bool:
	if battle_lap < 1 or goshuin_count < 0 or coins < 0:
		return false
	state = StateScript.new()
	state.phase = Phase.PRE_BATTLE
	state.lap = battle_lap
	state.goshuin_count = goshuin_count
	state.coins = coins
	difficulty = DifficultyScript.for_lap(battle_lap)
	state.difficulty_level = difficulty.level
	state.roll_speed_scale = difficulty.roll_speed_scale
	battle_seed = seed
	_roll_set = V06RollSetScript.new()
	_result = ResultScript.new()
	_result.lap = battle_lap
	_result.kyoto_level = difficulty.level
	_result.roll_speed_scale = difficulty.roll_speed_scale
	_result.goshuin_start = goshuin_count
	_result.final_distance = INITIAL_DISTANCE
	_configured = true
	_sync_piece_positions()
	if not saved_snapshot.is_empty() and not restore_snapshot(saved_snapshot):
		_configured = false
		return false
	_emit_phase_and_state()
	return true


func buy_head_start() -> Dictionary:
	if not _configured:
		return _rejected("NOT_CONFIGURED")
	if state.phase != Phase.PRE_BATTLE:
		return _rejected("HEAD_START_ONLY_BEFORE_BATTLE")
	if state.head_start_count >= MAX_HEAD_STARTS:
		return _rejected("HEAD_START_LIMIT")
	if state.coins < HEAD_START_COST:
		return _rejected("NOT_ENOUGH_COINS")
	state.coins -= HEAD_START_COST
	state.head_start_count += 1
	state.cat_progress += 1
	_result.coin_head_starts += 1
	_result.coins_spent += HEAD_START_COST
	_result.final_distance = _display_distance()
	_sync_piece_positions()
	emit_signal("coins_changed", state.coins, state.head_start_count)
	_emit_state_changed()
	return {
		"ok": true,
		"status": "HEAD_START_BOUGHT",
		"coins": state.coins,
		"head_start_count": state.head_start_count,
		"distance": distance_to_fox(),
		"cat_position": state.cat_position,
	}


func start_battle() -> Dictionary:
	if not _configured:
		return _rejected("NOT_CONFIGURED")
	if state.phase != Phase.PRE_BATTLE:
		return _rejected("BATTLE_ALREADY_STARTED")
	_set_phase(Phase.ROLL_READY)
	var event := {
		"ok": true,
		"status": "ROLL_READY",
		"phase": state.phase,
		"distance": distance_to_fox(),
	}
	_emit_state_changed()
	return event


func preview_face(face: int) -> Dictionary:
	if face < 1 or face > 6:
		return _rejected("FACE_OUT_OF_RANGE")
	var preview_faces: Array[int] = state.slot_faces.duplicate()
	preview_faces.append(face)
	var role: StringName = &""
	var bonus := 0
	if preview_faces.size() == V06RollSetScript.SLOT_COUNT:
		var evaluator: RefCounted = V06RollSetScript.new()
		if evaluator.restore_faces(preview_faces):
			role = evaluator.evaluate_role()
			bonus = _bonus_for_role(role)
	return {
		"ok": true,
		"face": face,
		"fox_face": 7 - face,
		"creates_fire": face == 6,
		"slot_faces": preview_faces,
		"slot_complete": preview_faces.size() == V06RollSetScript.SLOT_COUNT,
		"slot_role": str(role),
		"slot_bonus": bonus,
		"player_move": face + bonus,
	}


func commit_face(face: int) -> Dictionary:
	if not _configured:
		return _rejected("NOT_CONFIGURED")
	if state.phase != Phase.ROLL_READY:
		return _rejected("ROLL_NOT_READY")
	if face < 1 or face > 6:
		return _rejected("FACE_OUT_OF_RANGE")

	state.clear_turn_runtime()
	state.pending_face = face
	state.pending_fox_face = 7 - face
	_result.rolls_used += 1
	_result.player_faces.append(face)

	if not _roll_set.append_face(face):
		return _rejected("SLOT_APPEND_FAILED")
	state.slot_faces = _roll_set.faces()
	state.last_slot_role = &""
	state.last_slot_bonus = 0
	if _roll_set.is_complete():
		state.last_slot_role = _roll_set.evaluate_role()
		state.last_slot_bonus = _bonus_for_role(state.last_slot_role)
		state.completed_slot_faces = _roll_set.faces()
		var role_key := str(state.last_slot_role)
		_result.role_counts[role_key] = int(_result.role_counts.get(role_key, 0)) + 1
		if state.last_slot_bonus > 0:
			_result.slot_bonus_steps += state.last_slot_bonus
		_roll_set.reset_after_resolution()
		state.slot_faces = []
	state.pending_player_steps = face + state.last_slot_bonus

	if face == 6:
		var fire_index := BoardScript.normalize_outer_index(state.fox_progress + BoardScript.CAT_BASE_OUTER_INDEX)
		state.current_turn_fire_created = fire_index
		if not state.fox_fire_indices.has(fire_index):
			state.fox_fire_indices[fire_index] = true
			_result.fox_fire_generated += 1

	_move_fox(state.pending_fox_face)
	if state.phase == Phase.DEFEAT:
		var defeat_event := _turn_event("DEFEAT")
		_publish_event(defeat_event)
		return defeat_event

	if not _extend_active_detour():
		_finish_defeat("OUTER_RING_BLOCKED")
		var blocked_event := _turn_event("DEFEAT")
		_publish_event(blocked_event)
		return blocked_event

	var event := _continue_cat_movement()
	_publish_event(event)
	return event


func resolve_fire_choice(choice: Variant) -> Dictionary:
	if state.phase != Phase.FIRE_CHOICE:
		return _rejected("FIRE_CHOICE_NOT_ACTIVE")
	var normalized := StringName(str(choice).to_upper())
	if normalized == CHOICE_CLEANSE:
		if state.goshuin_count <= 0:
			return _rejected("NO_GOSHUIN")
		var fire_index := BoardScript.normalize_outer_index(state.pending_fire_progress + BoardScript.CAT_BASE_OUTER_INDEX)
		if not state.fox_fire_indices.has(fire_index):
			return _rejected("FIRE_ALREADY_GONE")
		state.goshuin_count -= 1
		_result.goshuin_used += 1
		state.fox_fire_indices.erase(fire_index)
		state.pending_fire_progress = -1
		# Continue through the now-clear outer cell with the unspent step.
	elif normalized == CHOICE_DETOUR:
		state.pending_fire_progress = -1
		if not _begin_detour():
			_finish_defeat("OUTER_RING_BLOCKED")
			var defeat_event := _turn_event("DEFEAT")
			_publish_event(defeat_event)
			return defeat_event
	else:
		return _rejected("UNKNOWN_FIRE_CHOICE")

	var event := _continue_cat_movement()
	_publish_event(event)
	return event


func acknowledge_turn() -> Dictionary:
	if state.phase != Phase.TURN_RESOLVED:
		return _rejected("TURN_NOT_RESOLVED")
	state.clear_turn_runtime()
	_set_phase(Phase.ROLL_READY)
	_emit_state_changed()
	return {
		"ok": true,
		"status": "ROLL_READY",
		"phase": state.phase,
		"distance": distance_to_fox(),
	}


func distance_to_fox() -> int:
	return _display_distance()


func fox_fire_outer_indices() -> Array[int]:
	var result: Array[int] = []
	for key: Variant in state.fox_fire_indices.keys():
		result.append(int(key))
	result.sort()
	return result


func slot_faces() -> Array[int]:
	return state.slot_faces.duplicate()


func completed_slot_faces() -> Array[int]:
	return state.completed_slot_faces.duplicate()


func last_completed_slot_faces() -> Array[int]:
	return completed_slot_faces()


func last_slot_role() -> StringName:
	return state.last_slot_role


func last_slot_bonus() -> int:
	return state.last_slot_bonus


func difficulty_config() -> Dictionary:
	return difficulty.to_dictionary()


func evaluate_slot_faces(values: Array) -> StringName:
	var evaluator: RefCounted = V06RollSetScript.new()
	if not evaluator.restore_faces(values):
		return &""
	return evaluator.evaluate_role()


func uses_shared_roll_set() -> bool:
	return _roll_set.get_script() == V06RollSetScript


func result_dict() -> Dictionary:
	_result.final_distance = _display_distance()
	return _result.to_dictionary()


func result() -> Dictionary:
	return result_dict()


func restore(saved_snapshot: Dictionary) -> bool:
	## Compatibility alias for save hosts that expose restore() on all boss
	## controllers.  The strict v2 restore path remains the single source of
	## truth.
	return restore_snapshot(saved_snapshot)


func playtest_stats() -> Dictionary:
	var stats := result_dict()
	stats["current_phase"] = Phase.keys()[state.phase]
	stats["current_distance"] = distance_to_fox()
	stats["goshuin_remaining"] = state.goshuin_count
	stats["coins_remaining"] = state.coins
	stats["active_fox_fire"] = fox_fire_outer_indices().size()
	stats["cat_inside_detour"] = state.is_inside_detour()
	return stats


func snapshot() -> Dictionary:
	return {
		"snapshot_version": SNAPSHOT_VERSION,
		"battle_id": BATTLE_ID,
		"phase": state.phase,
		"lap": state.lap,
		"battle_seed": battle_seed,
		"difficulty_level": state.difficulty_level,
		"roll_speed_scale": state.roll_speed_scale,
		"cat_progress": state.cat_progress,
		"fox_progress": state.fox_progress,
		# Integer ids are the canonical save representation.  The *_xy aliases
		# are retained for old tooling and are never used in v2 restore.
		"cat_cell_id": BoardScript.cell_id(state.cat_position),
		"fox_cell_id": BoardScript.cell_id(state.fox_position),
		"cat_position": BoardScript.cell_id(state.cat_position),
		"fox_position": BoardScript.cell_id(state.fox_position),
		"cat_position_xy": _coordinate_to_json(state.cat_position),
		"fox_position_xy": _coordinate_to_json(state.fox_position),
		"cat_on_outer": state.cat_on_outer,
		"fox_fire_indices": fox_fire_outer_indices(),
		"fox_fire_cell_ids": _fire_cell_ids(),
		"goshuin_count": state.goshuin_count,
		"coins": state.coins,
		"head_start_count": state.head_start_count,
		"slot_faces": state.slot_faces.duplicate(),
		"completed_slot_faces": state.completed_slot_faces.duplicate(),
		"last_slot_role": str(state.last_slot_role),
		"last_slot_bonus": state.last_slot_bonus,
		"detour_path": _path_to_cell_ids(state.detour_path),
		"detour_path_cell_ids": _path_to_cell_ids(state.detour_path),
		"detour_path_xy": _path_to_json(state.detour_path),
		"detour_exit_progress": state.detour_exit_progress,
		"pending_face": state.pending_face,
		"pending_fox_face": state.pending_fox_face,
		"pending_player_steps": state.pending_player_steps,
		"pending_fire_progress": state.pending_fire_progress,
		"current_turn_cat_path": _path_to_cell_ids(state.current_turn_cat_path),
		"current_turn_cat_path_cell_ids": _path_to_cell_ids(state.current_turn_cat_path),
		"current_turn_cat_path_xy": _path_to_json(state.current_turn_cat_path),
		"current_turn_fox_path": _path_to_cell_ids(state.current_turn_fox_path),
		"current_turn_fox_path_cell_ids": _path_to_cell_ids(state.current_turn_fox_path),
		"current_turn_fox_path_xy": _path_to_json(state.current_turn_fox_path),
		"current_turn_fire_created": state.current_turn_fire_created,
		"result": _result.to_dictionary(),
	}


func restore_snapshot(saved: Dictionary) -> bool:
	if str(saved.get("battle_id", "")) != BATTLE_ID:
		return false
	var version_data := _strict_int(saved.get("snapshot_version", null), 1, SNAPSHOT_VERSION)
	if not bool(version_data.get("ok", false)):
		return false
	var snapshot_version := int(version_data["value"])
	if snapshot_version != LEGACY_SNAPSHOT_VERSION and snapshot_version != SNAPSHOT_VERSION:
		return false
	var battle_id: Variant = saved.get("battle_id", "")
	if not battle_id is String and not battle_id is StringName:
		return false
	var phase_data := _strict_int(saved.get("phase", null), Phase.PRE_BATTLE, Phase.DEFEAT)
	if not bool(phase_data.get("ok", false)):
		return false
	var restored_phase := int(phase_data["value"])
	if restored_phase < Phase.PRE_BATTLE or restored_phase > Phase.DEFEAT:
		return false
	var lap_data := _strict_int(saved.get("lap", null), 1, 9999)
	var cat_progress_data := _strict_int(saved.get("cat_progress", null), 0)
	var fox_progress_data := _strict_int(saved.get("fox_progress", null), 0)
	if not bool(lap_data.get("ok", false)) or not bool(cat_progress_data.get("ok", false)) or not bool(fox_progress_data.get("ok", false)):
		return false
	var restored_lap := int(lap_data["value"])
	var restored_cat_progress := int(cat_progress_data["value"])
	var restored_fox_progress := int(fox_progress_data["value"])

	var restored_cat_position_data := _position_from_snapshot(saved, "cat_position", "cat_position_xy", snapshot_version)
	var restored_fox_position_data := _position_from_snapshot(saved, "fox_position", "fox_position_xy", snapshot_version)
	if not bool(restored_cat_position_data.get("ok", false)) or not bool(restored_fox_position_data.get("ok", false)):
		return false
	var restored_cat_position: Vector2i = restored_cat_position_data["position"]
	var restored_fox_position: Vector2i = restored_fox_position_data["position"]
	if not BoardScript.is_in_bounds(restored_cat_position) or not BoardScript.is_outer_position(restored_fox_position):
		return false
	if not _position_alias_matches(saved, "cat_cell_id", restored_cat_position) or not _position_alias_matches(saved, "fox_cell_id", restored_fox_position):
		return false

	var fire_data := _fire_indices_from_snapshot(saved, snapshot_version)
	if not bool(fire_data.get("ok", false)):
		return false
	var restored_fires: Dictionary = fire_data["indices"]
	if not _fire_index_alias_matches(saved, restored_fires):
		return false

	var restored_slot_faces: Array[int] = []
	var slot_values: Variant = saved.get("slot_faces", [])
	if not slot_values is Array or slot_values.size() > 2:
		return false
	for value: Variant in slot_values:
		var face_data := _strict_int(value, 1, 6)
		if not bool(face_data.get("ok", false)):
			return false
		restored_slot_faces.append(int(face_data["value"]))
	var restored_completed_faces: Array[int] = []
	var completed_values: Variant = saved.get("completed_slot_faces", [])
	if not completed_values is Array or completed_values.size() > 3:
		return false
	for value: Variant in completed_values:
		var face_data := _strict_int(value, 1, 6)
		if not bool(face_data.get("ok", false)):
			return false
		restored_completed_faces.append(int(face_data["value"]))

	var restored_detour := _path_from_snapshot(saved, "detour_path", "detour_path_xy", snapshot_version)
	var restored_cat_path := _path_from_snapshot(saved, "current_turn_cat_path", "current_turn_cat_path_xy", snapshot_version)
	var restored_fox_path := _path_from_snapshot(saved, "current_turn_fox_path", "current_turn_fox_path_xy", snapshot_version)
	if not bool(restored_detour.get("ok", false)) or not bool(restored_cat_path.get("ok", false)) or not bool(restored_fox_path.get("ok", false)):
		return false
	var restored_detour_path: Array[Vector2i] = restored_detour["path"]
	var restored_cat_turn_path: Array[Vector2i] = restored_cat_path["path"]
	var restored_fox_turn_path: Array[Vector2i] = restored_fox_path["path"]
	if not _path_is_sequential(restored_cat_turn_path) or not _path_is_sequential(restored_fox_turn_path):
		return false
	if not _path_alias_matches(saved, "detour_path_cell_ids", restored_detour_path) or not _path_alias_matches(saved, "current_turn_cat_path_cell_ids", restored_cat_turn_path) or not _path_alias_matches(saved, "current_turn_fox_path_cell_ids", restored_fox_turn_path):
		return false
	var restored_on_outer_data := _strict_bool(saved.get("cat_on_outer", true))
	if not bool(restored_on_outer_data.get("ok", false)):
		return false
	var restored_on_outer := bool(restored_on_outer_data["value"])
	var restored_exit_data := _strict_int(saved.get("detour_exit_progress", -1), -1)
	if not bool(restored_exit_data.get("ok", false)):
		return false
	var restored_exit_progress := int(restored_exit_data["value"])
	if (not restored_detour_path.is_empty() or not restored_on_outer) and restored_exit_progress < 0:
		return false
	if restored_on_outer and (not restored_detour_path.is_empty() or restored_exit_progress >= 0):
		return false
	if not restored_on_outer:
		if BoardScript.is_outer_position(restored_cat_position) or restored_detour_path.is_empty():
			return false
		if restored_exit_progress <= restored_cat_progress:
			return false
		if not BoardScript.path_is_orthogonal(restored_detour_path, restored_cat_position):
			return false
		for path_index: int in range(restored_detour_path.size() - 1):
			if BoardScript.is_outer_position(restored_detour_path[path_index]):
				return false
	if restored_on_outer and restored_detour_path.is_empty():
		var expected_cat := BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + restored_cat_progress)
		if restored_cat_position != expected_cat:
			return false
	var expected_fox := BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + restored_fox_progress)
	if restored_fox_position != expected_fox:
		return false
	if not restored_on_outer and restored_detour_path.back() is Vector2i and BoardScript.is_outer_position(restored_detour_path.back()):
		if restored_detour_path.back() != BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + restored_exit_progress):
			return false

	var pending_face_data := _strict_int(saved.get("pending_face", 0), 0, 6)
	var pending_fox_data := _strict_int(saved.get("pending_fox_face", 0), 0, 6)
	var pending_steps_data := _strict_int(saved.get("pending_player_steps", 0), 0, 64)
	var pending_fire_data := _strict_int(saved.get("pending_fire_progress", -1), -1)
	var created_fire_data := _strict_int(saved.get("current_turn_fire_created", -1), -1, BoardScript.OUTER_CELL_COUNT - 1)
	if not bool(pending_face_data.get("ok", false)) or not bool(pending_fox_data.get("ok", false)) or not bool(pending_steps_data.get("ok", false)) or not bool(pending_fire_data.get("ok", false)) or not bool(created_fire_data.get("ok", false)):
		return false
	var restored_pending_face := int(pending_face_data["value"])
	var restored_pending_fox_face := int(pending_fox_data["value"])
	if (restored_pending_face == 0 and restored_pending_fox_face != 0) or (restored_pending_face > 0 and restored_pending_fox_face != 7 - restored_pending_face):
		return false
	var restored_pending_fire := int(pending_fire_data["value"])
	var goshuin_data := _strict_int(saved.get("goshuin_count", 0), 0)
	if not bool(goshuin_data.get("ok", false)):
		return false
	if restored_phase == Phase.FIRE_CHOICE:
		if restored_pending_fire < 0 or int(goshuin_data["value"]) <= 0:
			return false
		var pending_fire_index := BoardScript.normalize_outer_index(BoardScript.CAT_BASE_OUTER_INDEX + restored_cat_progress + restored_pending_fire)
		if not restored_fires.has(pending_fire_index):
			return false
	elif restored_pending_fire >= 0:
		return false

	var coins_data := _strict_int(saved.get("coins", 0), 0)
	var head_start_data := _strict_int(saved.get("head_start_count", 0), 0, MAX_HEAD_STARTS)
	if not bool(goshuin_data.get("ok", false)) or not bool(coins_data.get("ok", false)) or not bool(head_start_data.get("ok", false)):
		return false
	var restored_goshuin := int(goshuin_data["value"])
	var restored_coins := int(coins_data["value"])
	var restored_head_start := int(head_start_data["value"])

	state = StateScript.new()
	state.phase = restored_phase
	state.lap = restored_lap
	difficulty = DifficultyScript.for_lap(restored_lap)
	state.difficulty_level = difficulty.level
	state.roll_speed_scale = difficulty.roll_speed_scale
	state.cat_progress = restored_cat_progress
	state.fox_progress = restored_fox_progress
	state.cat_position = restored_cat_position
	state.fox_position = restored_fox_position
	state.cat_on_outer = restored_on_outer
	state.fox_fire_indices = restored_fires
	state.goshuin_count = restored_goshuin
	state.coins = restored_coins
	state.head_start_count = restored_head_start
	state.slot_faces = restored_slot_faces
	state.completed_slot_faces = restored_completed_faces
	var restored_role := StringName(str(saved.get("last_slot_role", "")))
	if restored_role not in [&"", V06RollSetScript.ROLE_MIX, V06RollSetScript.ROLE_PAIR, V06RollSetScript.ROLE_STRAIGHT, V06RollSetScript.ROLE_TRIPLE]:
		return false
	var restored_bonus_data := _strict_int(saved.get("last_slot_bonus", 0), 0, 3)
	if not bool(restored_bonus_data.get("ok", false)):
		return false
	var restored_bonus := int(restored_bonus_data["value"])
	if restored_bonus != _bonus_for_role(restored_role):
		return false
	state.last_slot_role = restored_role
	state.last_slot_bonus = restored_bonus
	state.detour_path = restored_detour_path
	state.detour_exit_progress = restored_exit_progress
	state.pending_face = restored_pending_face
	state.pending_fox_face = restored_pending_fox_face
	state.pending_player_steps = int(pending_steps_data["value"])
	state.pending_fire_progress = restored_pending_fire
	state.current_turn_cat_path = restored_cat_turn_path
	state.current_turn_fox_path = restored_fox_turn_path
	state.current_turn_fire_created = int(created_fire_data["value"])
	var seed_data := _strict_int(saved.get("battle_seed", 0))
	if not bool(seed_data.get("ok", false)):
		return false
	battle_seed = int(seed_data["value"])
	_roll_set = V06RollSetScript.new()
	if not _roll_set.restore_faces(state.slot_faces):
		return false
	var result_data: Variant = saved.get("result", {})
	if not result_data is Dictionary:
		return false
	_result = ResultScript.from_dictionary(result_data)
	_configured = true
	_emit_phase_and_state()
	return true


func _move_fox(steps: int) -> void:
	for _step: int in range(steps):
		state.fox_progress += 1
		state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + state.fox_progress)
		state.current_turn_fox_path.append(state.fox_position)
		_result.total_fox_steps += 1
		if state.fox_progress >= state.cat_progress + BoardScript.OUTER_CELL_COUNT:
			_finish_defeat("FOX_LAPPED_PLAYER")
			return


func _continue_cat_movement() -> Dictionary:
	while state.pending_player_steps > 0:
		if not state.detour_path.is_empty():
			var next_detour_cell: Vector2i = state.detour_path.pop_front()
			state.cat_position = next_detour_cell
			state.cat_on_outer = BoardScript.is_outer_position(next_detour_cell)
			state.pending_player_steps -= 1
			state.current_turn_cat_path.append(next_detour_cell)
			_result.total_player_steps += 1
			if state.cat_on_outer and state.detour_path.is_empty():
				state.cat_progress = state.detour_exit_progress
				state.detour_exit_progress = -1
				if state.cat_progress >= state.fox_progress:
					_finish_victory()
					return _turn_event("VICTORY")
			continue

		var next_progress := state.cat_progress + 1
		var next_index := BoardScript.normalize_outer_index(BoardScript.CAT_BASE_OUTER_INDEX + next_progress)
		if state.fox_fire_indices.has(next_index):
			_result.fox_fire_encounters += 1
			state.pending_fire_progress = next_progress
			if state.goshuin_count > 0:
				_set_phase(Phase.FIRE_CHOICE)
				return _turn_event("FIRE_CHOICE")
			state.pending_fire_progress = -1
			if not _begin_detour():
				_finish_defeat("OUTER_RING_BLOCKED")
				return _turn_event("DEFEAT")
			continue

		state.cat_progress = next_progress
		state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + state.cat_progress)
		state.cat_on_outer = true
		state.pending_player_steps -= 1
		state.current_turn_cat_path.append(state.cat_position)
		_result.total_player_steps += 1
		if state.cat_progress >= state.fox_progress:
			_finish_victory()
			return _turn_event("VICTORY")

	_set_phase(Phase.TURN_RESOLVED)
	_result.final_distance = _display_distance()
	return _turn_event("TURN_RESOLVED")


func _begin_detour() -> bool:
	var detour: Dictionary = BoardScript.detour_from_progress(state.cat_progress + BoardScript.CAT_BASE_OUTER_INDEX, state.fox_fire_indices)
	if not bool(detour.get("ok", false)):
		return false
	# Board helper progress is expressed in raw ring coordinates; translate the
	# absolute exit back to the controller's cat-relative progress domain.
	var raw_entry_progress := state.cat_progress + BoardScript.CAT_BASE_OUTER_INDEX
	var raw_exit_progress := int(detour["exit_progress"])
	state.detour_exit_progress = state.cat_progress + (raw_exit_progress - raw_entry_progress)
	state.detour_path = detour["path"]
	if state.detour_path.is_empty() or not BoardScript.path_is_orthogonal(state.detour_path, state.cat_position):
		state.detour_path.clear()
		state.detour_exit_progress = -1
		return false
	state.cat_on_outer = false
	_result.fox_fire_detours += 1
	return true


func _extend_active_detour() -> bool:
	if state.detour_path.is_empty() or state.detour_exit_progress < 0:
		return true
	var raw_exit_progress := state.detour_exit_progress + BoardScript.CAT_BASE_OUTER_INDEX
	var extension: Dictionary = BoardScript.extend_detour(state.detour_path, raw_exit_progress, state.fox_fire_indices)
	if not bool(extension.get("ok", false)):
		return false
	if bool(extension.get("extended", false)):
		var raw_new_exit := int(extension["exit_progress"])
		state.detour_exit_progress += raw_new_exit - raw_exit_progress
		state.detour_path = extension["path"]
	return true


func _finish_victory() -> void:
	_result.victory = true
	_result.defeat_reason = ""
	_result.final_distance = 0
	state.fox_fire_indices.clear()
	_set_phase(Phase.VICTORY)


func _finish_defeat(reason: String) -> void:
	_result.victory = false
	_result.defeat_reason = reason
	_result.final_distance = _display_distance()
	_set_phase(Phase.DEFEAT)


func _turn_event(status: String) -> Dictionary:
	return {
		"ok": true,
		"status": status,
		"phase": state.phase,
		"face": state.pending_face,
		"fox_face": state.pending_fox_face,
		"player_move": state.pending_face + state.last_slot_bonus,
		"player_steps_remaining": state.pending_player_steps,
		"slot_role": str(state.last_slot_role),
		"slot_bonus": state.last_slot_bonus,
		"slot_faces": state.slot_faces.duplicate(),
		"completed_slot_faces": state.completed_slot_faces.duplicate(),
		"fox_fire_created": state.current_turn_fire_created,
		"fox_fire_indices": fox_fire_outer_indices(),
		"fox_fire_cell_ids": _fire_cell_ids(),
		"pending_fire_index": (
			BoardScript.normalize_outer_index(state.pending_fire_progress + BoardScript.CAT_BASE_OUTER_INDEX)
			if state.pending_fire_progress >= 0
			else -1
		),
		"fox_path": state.current_turn_fox_path.duplicate(),
		"cat_path": state.current_turn_cat_path.duplicate(),
		"cat_position": state.cat_position,
		"fox_position": state.fox_position,
		"cat_cell_id": BoardScript.cell_id(state.cat_position),
		"fox_cell_id": BoardScript.cell_id(state.fox_position),
		"cat_path_cell_ids": _path_to_cell_ids(state.current_turn_cat_path),
		"fox_path_cell_ids": _path_to_cell_ids(state.current_turn_fox_path),
		"cat_on_outer": state.cat_on_outer,
		"distance": distance_to_fox(),
		"goshuin_count": state.goshuin_count,
	}


func _publish_event(event: Dictionary) -> void:
	_emit_state_changed()
	match str(event.get("status", "")):
		"FIRE_CHOICE":
			emit_signal("fire_choice_requested", int(event.get("pending_fire_index", -1)), state.goshuin_count)
		"TURN_RESOLVED":
			emit_signal("turn_resolved", event)
		"VICTORY", "DEFEAT":
			emit_signal("turn_resolved", event)
			emit_signal("battle_finished", result_dict())


func _set_phase(next_phase: int) -> void:
	if state.phase == next_phase:
		return
	state.phase = next_phase
	emit_signal("phase_changed", state.phase)


func _emit_phase_and_state() -> void:
	emit_signal("phase_changed", state.phase)
	_emit_state_changed()


func _emit_state_changed() -> void:
	emit_signal("state_changed", snapshot())


func _sync_piece_positions() -> void:
	state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + state.cat_progress)
	state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + state.fox_progress)
	state.cat_on_outer = true


func _display_distance() -> int:
	var gap := state.fox_progress - state.cat_progress
	if gap <= 0 or gap >= BoardScript.OUTER_CELL_COUNT:
		return 0
	return gap


func _bonus_for_role(role: StringName) -> int:
	match role:
		V06RollSetScript.ROLE_PAIR:
			return 1
		V06RollSetScript.ROLE_STRAIGHT:
			return 2
		V06RollSetScript.ROLE_TRIPLE:
			return 3
	return 0


func _coordinate_to_json(position: Vector2i) -> Array[int]:
	return [position.x, position.y]


func _path_to_json(path: Array[Vector2i]) -> Array:
	var result: Array = []
	for position: Vector2i in path:
		result.append(_coordinate_to_json(position))
	return result


func _path_to_cell_ids(path: Array[Vector2i]) -> Array[int]:
	var result: Array[int] = []
	for position: Vector2i in path:
		result.append(BoardScript.cell_id(position))
	return result


func _fire_cell_ids() -> Array[int]:
	var result: Array[int] = []
	for index: int in fox_fire_outer_indices():
		result.append(BoardScript.outer_cell_id(index))
	return result


func _strict_int(value: Variant, minimum: int = -2147483647, maximum: int = 2147483647) -> Dictionary:
	var parsed: int
	if value is int:
		parsed = int(value)
	elif value is float:
		# Godot's JSON decoder represents every JSON number as a float on
		# some builds.  Preserve strict integer semantics by accepting only
		# mathematically integral floats (14.5 remains invalid).
		var numeric := float(value)
		if not is_equal_approx(numeric, round(numeric)):
			return {"ok": false}
		parsed = int(numeric)
	else:
		return {"ok": false}
	if parsed < minimum or parsed > maximum:
		return {"ok": false}
	return {"ok": true, "value": parsed}


func _strict_bool(value: Variant) -> Dictionary:
	if not value is bool:
		return {"ok": false}
	return {"ok": true, "value": bool(value)}


func _position_alias_matches(saved: Dictionary, alias_key: String, expected: Vector2i) -> bool:
	if not saved.has(alias_key):
		return true
	var id_data := _strict_int(saved.get(alias_key, null), 0, BoardScript.BOARD_SIZE * BoardScript.BOARD_SIZE - 1)
	return bool(id_data.get("ok", false)) and int(id_data["value"]) == BoardScript.cell_id(expected)


func _path_alias_matches(saved: Dictionary, alias_key: String, expected: Array[Vector2i]) -> bool:
	if not saved.has(alias_key):
		return true
	var values: Variant = saved.get(alias_key, null)
	if not values is Array or values.size() != expected.size():
		return false
	for index: int in range(expected.size()):
		var id_data := _strict_int(values[index], 0, BoardScript.BOARD_SIZE * BoardScript.BOARD_SIZE - 1)
		if not bool(id_data.get("ok", false)) or int(id_data["value"]) != BoardScript.cell_id(expected[index]):
			return false
	return true


func _fire_index_alias_matches(saved: Dictionary, expected: Dictionary) -> bool:
	if not saved.has("fox_fire_indices"):
		return true
	var values: Variant = saved.get("fox_fire_indices", null)
	if not values is Array or values.size() != expected.size():
		return false
	var seen: Dictionary = {}
	for raw_index: Variant in values:
		var index_data := _strict_int(raw_index, 0, BoardScript.OUTER_CELL_COUNT - 1)
		if not bool(index_data.get("ok", false)):
			return false
		var index := int(index_data["value"])
		if seen.has(index) or not expected.has(index):
			return false
		seen[index] = true
	return true


func _position_from_snapshot(
	saved: Dictionary, canonical_key: String, legacy_coordinate_key: String, snapshot_version: int
) -> Dictionary:
	if snapshot_version >= SNAPSHOT_VERSION:
		var raw_id: Variant = saved.get(canonical_key, null)
		if raw_id == null:
			raw_id = saved.get(canonical_key + "_cell_id", null)
		var id_data := _strict_int(raw_id, 0, BoardScript.BOARD_SIZE * BoardScript.BOARD_SIZE - 1)
		if not bool(id_data.get("ok", false)):
			return {"ok": false}
		var position := BoardScript.position_from_cell_id(int(id_data["value"]))
		if not BoardScript.is_in_bounds(position):
			return {"ok": false}
		return {"ok": true, "position": position}
	# v1 saved Vector2i coordinates as [x, y] arrays under the canonical key.
	var legacy_value: Variant = saved.get(legacy_coordinate_key, saved.get(canonical_key, []))
	return _coordinate_from_json(legacy_value)


func _fire_indices_from_snapshot(saved: Dictionary, snapshot_version: int) -> Dictionary:
	var indices: Dictionary = {}
	var values: Variant
	if snapshot_version >= SNAPSHOT_VERSION or saved.has("fox_fire_cell_ids"):
		if not saved.has("fox_fire_cell_ids"):
			return {"ok": false}
		values = saved.get("fox_fire_cell_ids", [])
		if not values is Array:
			return {"ok": false}
		for raw_id: Variant in values:
			var id_data := _strict_int(raw_id, 0, BoardScript.BOARD_SIZE * BoardScript.BOARD_SIZE - 1)
			if not bool(id_data.get("ok", false)):
				return {"ok": false}
			var index := BoardScript.outer_index_for_cell_id(int(id_data["value"]))
			if index < 0 or indices.has(index):
				return {"ok": false}
			indices[index] = true
		return {"ok": true, "indices": indices}
	values = saved.get("fox_fire_indices", [])
	if not values is Array:
		return {"ok": false}
	for raw_index: Variant in values:
		var index_data := _strict_int(raw_index, 0, BoardScript.OUTER_CELL_COUNT - 1)
		if not bool(index_data.get("ok", false)):
			return {"ok": false}
		var index := int(index_data["value"])
		if indices.has(index):
			return {"ok": false}
		indices[index] = true
	return {"ok": true, "indices": indices}


func _path_from_snapshot(
	saved: Dictionary, canonical_key: String, legacy_coordinate_key: String, snapshot_version: int
) -> Dictionary:
	if snapshot_version >= SNAPSHOT_VERSION:
		var values: Variant = saved.get(canonical_key, null)
		if values == null:
			values = saved.get(canonical_key + "_cell_ids", null)
		if not values is Array:
			return {"ok": false, "path": []}
		var result: Array[Vector2i] = []
		for raw_id: Variant in values:
			var id_data := _strict_int(raw_id, 0, BoardScript.BOARD_SIZE * BoardScript.BOARD_SIZE - 1)
			if not bool(id_data.get("ok", false)):
				return {"ok": false, "path": []}
			var position := BoardScript.position_from_cell_id(int(id_data["value"]))
			if not BoardScript.is_in_bounds(position):
				return {"ok": false, "path": []}
			result.append(position)
		return {"ok": true, "path": result}
	var legacy_value: Variant = saved.get(legacy_coordinate_key, saved.get(canonical_key, []))
	return _path_from_json(legacy_value)


func _coordinate_from_json(value: Variant) -> Dictionary:
	if not value is Array or value.size() != 2:
		return {"ok": false}
	var x_data := _strict_int(value[0], 0, BoardScript.BOARD_SIZE - 1)
	var y_data := _strict_int(value[1], 0, BoardScript.BOARD_SIZE - 1)
	if not bool(x_data.get("ok", false)) or not bool(y_data.get("ok", false)):
		return {"ok": false}
	var position := Vector2i(int(x_data["value"]), int(y_data["value"]))
	return {"ok": true, "position": position}


func _path_from_json(value: Variant) -> Dictionary:
	if not value is Array:
		return {"ok": false, "path": []}
	var result: Array[Vector2i] = []
	for coordinate: Variant in value:
		var decoded := _coordinate_from_json(coordinate)
		if not bool(decoded.get("ok", false)):
			return {"ok": false, "path": []}
		var position: Vector2i = decoded["position"]
		if not BoardScript.is_in_bounds(position):
			return {"ok": false, "path": []}
		result.append(position)
	return {"ok": true, "path": result}


func _path_is_sequential(path: Array[Vector2i]) -> bool:
	for index: int in range(path.size()):
		if not BoardScript.is_in_bounds(path[index]):
			return false
		if index == 0:
			continue
		var previous := path[index - 1]
		var current := path[index]
		if absi(current.x - previous.x) + absi(current.y - previous.y) != 1:
			return false
	return true


func _rejected(error: String) -> Dictionary:
	return {"ok": false, "error": error, "phase": state.phase}
