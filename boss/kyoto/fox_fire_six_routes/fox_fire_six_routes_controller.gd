class_name FoxFireSixRoutesController
extends Node

const ROLL_SET_SCRIPT_PATH: String = "res://scripts/game/v06_roll_set.gd"
const V06RollSetScript = preload(ROLL_SET_SCRIPT_PATH)
const BattleStateScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_battle_state.gd")
const BattleResultScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_battle_result.gd")
const BoardCellScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_board_cell.gd")
const DifficultyConfigScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_difficulty_config.gd")
const DifficultyTableScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_difficulty_table.gd")
const EdgeScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_edge.gd")

enum BattlePhase {
	INTRO,
	PRE_BATTLE,
	TURN_START,
	ROLL_SLOT,
	PATH_INPUT,
	CAT_MOVING,
	SEAL_RESOLVE,
	SPECIAL_RESOLVE,
	FOX_ACTION,
	TURN_END,
	VICTORY,
	DEFEAT,
	RESULT,
}

const BOARD_SIZE: int = 6
const TORII_A: int = 0
const TORII_B: int = 1
const TORII_C: int = 2
const TORII_D: int = 3
const TORII_POSITIONS: Array[Vector2i] = [
	Vector2i(2, 5),
	Vector2i(3, 0),
	Vector2i(0, 1),
	Vector2i(5, 3),
]
const ORTHOGONAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]
const INITIAL_FIRE_PRIORITY: Array[Vector2i] = [
	Vector2i(3, 3),
	Vector2i(2, 3),
	Vector2i(3, 2),
	Vector2i(1, 3),
	Vector2i(4, 2),
	Vector2i(1, 4),
	Vector2i(4, 4),
]
const SNAPSHOT_VERSION: int = 1

signal cell_pressed(position: Vector2i)
signal undo_requested
signal path_confirm_requested

signal phase_changed(phase: int)
signal move_steps_changed(value: int)
signal remaining_steps_changed(value: int)
signal reachable_endpoints_changed(endpoints: Array[Vector2i])
signal fox_preview_changed(cells: Array[Vector2i])

signal seal_completed(count: int)
signal white_fire_changed
signal line_cut_changed(edge_key: String)
signal special_requested(kind: StringName, options: Array[Vector2i])
signal battle_finished(result: FoxFireBattleResult)

var state: FoxFireBattleState = BattleStateScript.new()
var difficulty_config: FoxFireDifficultyConfig = DifficultyConfigScript.new()
var difficulty_table: FoxFireDifficultyTable = DifficultyTableScript.create_default()
var battle_seed: int = 0
var lap: int = 1

var _rng := RandomNumberGenerator.new()
var _roll_set: RefCounted = V06RollSetScript.new()
var _last_slot_role: StringName = &""
var _last_completed_slot_faces: Array[int] = []
var _result: FoxFireBattleResult = BattleResultScript.new()
var _board: Dictionary = {}
var _configured: bool = false
var _fox_actions_resolved: int = 0


func _init() -> void:
	_build_board()
	state.phase = BattlePhase.INTRO


func configure(
	battle_lap: int = 1,
	goshuin: Dictionary = {},
	seed_value: int = 0,
	difficulty_override: FoxFireDifficultyConfig = null
) -> bool:
	if battle_lap < 1:
		return false
	lap = battle_lap
	battle_seed = seed_value
	_rng = RandomNumberGenerator.new()
	_rng.seed = battle_seed
	_roll_set = V06RollSetScript.new()
	_last_slot_role = &""
	_last_completed_slot_faces.clear()
	_fox_actions_resolved = 0
	state = BattleStateScript.new()
	difficulty_config = (
		difficulty_override.duplicate_config()
		if difficulty_override != null
		else difficulty_table.config_for_lap(lap)
	)
	state.difficulty_level = difficulty_config.level
	state.phase = BattlePhase.PRE_BATTLE
	state.yasaka_delay_available = bool(goshuin.get("yasaka", false))
	state.kiyomizu_available = bool(goshuin.get("kiyomizu", false))
	state.tenryuji_available = bool(goshuin.get("tenryuji", false))
	state.fushimi_start_choice_available = bool(goshuin.get("fushimi", false))
	var owns_all_goshuin := (
		bool(goshuin.get("fushimi", false))
		and bool(goshuin.get("yasaka", false))
		and bool(goshuin.get("kiyomizu", false))
		and bool(goshuin.get("tenryuji", false))
	)
	state.mangan_available = bool(goshuin.get("mangan", owns_all_goshuin))
	_result = BattleResultScript.new()
	_result.difficulty_level = difficulty_config.level
	_build_board()
	_sync_board_runtime_flags()
	_configured = true
	emit_signal("phase_changed", state.phase)
	return true


func set_difficulty_table(table: FoxFireDifficultyTable) -> bool:
	if table == null or table.entries.is_empty():
		return false
	if _configured and state.phase not in [BattlePhase.INTRO, BattlePhase.PRE_BATTLE]:
		return false
	difficulty_table = table
	return true


func choose_start_torii(torii_id: int) -> bool:
	if state.phase != BattlePhase.PRE_BATTLE or not state.fushimi_start_choice_available:
		return false
	if torii_id < TORII_A or torii_id > TORII_D:
		return false
	state.current_torii_id = torii_id
	state.cat_position = TORII_POSITIONS[torii_id]
	state.visited_torii = {torii_id: true}
	state.fushimi_start_choice_available = false
	_sync_board_runtime_flags()
	return true


func start_battle() -> Dictionary:
	if not _configured:
		return _rejected("NOT_CONFIGURED")
	if state.phase not in [BattlePhase.INTRO, BattlePhase.PRE_BATTLE]:
		return _rejected("INVALID_PHASE")
	state.fushimi_start_choice_available = false
	_seed_initial_white_fire()
	_initialize_fox_schedule()
	_start_next_turn()
	return _event("ROLL_SLOT")


func roll_move() -> Dictionary:
	if state.phase != BattlePhase.ROLL_SLOT:
		return _rejected("ROLL_NOT_ALLOWED")
	var face: int = _rng.randi_range(1, 6)
	var event := _accept_move_steps(face)
	event["rolled"] = true
	event["face"] = face
	return event


func set_move_steps_for_test(value: int) -> Dictionary:
	if state.phase != BattlePhase.ROLL_SLOT:
		return _rejected("MOVE_VALUE_NOT_ALLOWED")
	return _accept_move_steps(value)


func evaluate_slot_faces(values: Array) -> StringName:
	var evaluator: RefCounted = V06RollSetScript.new()
	if not evaluator.restore_faces(values):
		return &""
	return evaluator.evaluate_role()


func uses_shared_roll_set() -> bool:
	return _roll_set.get_script() == V06RollSetScript


func slot_faces() -> Array[int]:
	return _roll_set.faces()


func last_slot_role() -> StringName:
	return _last_slot_role


func last_completed_slot_faces() -> Array[int]:
	return _last_completed_slot_faces.duplicate()


func reachable_endpoints_exact(steps: int = -1, start: Vector2i = Vector2i(-1, -1)) -> Array[Vector2i]:
	var actual_steps: int = state.move_steps if steps < 0 else steps
	var actual_start: Vector2i = state.cat_position if start == Vector2i(-1, -1) else start
	var endpoints: Dictionary = {}
	if actual_steps < 0 or actual_steps > 6 or not is_in_bounds(actual_start):
		return []
	var visited: Dictionary = {actual_start: true}
	var traversal_path: Array[Vector2i] = [actual_start]
	_dfs_exact_endpoints(actual_start, actual_steps, visited, endpoints, traversal_path)
	return _sorted_positions(endpoints.keys())


func legal_next_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if state.phase != BattlePhase.PATH_INPUT or state.current_input_path.is_empty():
		return result
	if state.remaining_steps() <= 0:
		return result
	var current: Vector2i = state.current_input_path.back()
	for direction: Vector2i in ORTHOGONAL_DIRECTIONS:
		var candidate := current + direction
		if _is_legal_forward_step(candidate, state.current_input_path):
			result.append(candidate)
	result.sort_custom(_position_precedes)
	return result


func legal_next_positions() -> Array[Vector2i]:
	return legal_next_cells()


func press_cell(position: Vector2i) -> Dictionary:
	emit_signal("cell_pressed", position)
	if state.phase != BattlePhase.PATH_INPUT:
		return _rejected("PATH_INPUT_NOT_ALLOWED")
	if state.current_input_path.is_empty():
		return _rejected("PATH_NOT_INITIALIZED")
	if state.current_input_path.size() >= 2 and position == state.current_input_path[-2]:
		state.current_input_path.pop_back()
		_emit_remaining_steps()
		return _event("UNDO")
	if state.remaining_steps() <= 0:
		return _rejected("PATH_ALREADY_COMPLETE")
	if not is_in_bounds(position):
		return _rejected("OUT_OF_BOUNDS")
	var current: Vector2i = state.current_input_path.back()
	if not EdgeScript.is_orthogonal_unit(current, position):
		return _rejected("NOT_ORTHOGONAL_ADJACENT")
	var step_direction := position - current
	if _bamboo_enabled() and not _bamboo_step_allowed(state.current_input_path, step_direction):
		return _rejected("BAMBOO_DIRECTION_REQUIRED")
	if state.white_fire_cells.has(position):
		return _rejected("WHITE_FIRE_BLOCKED")
	if state.current_input_path.has(position):
		return _rejected("SAME_TURN_REVISIT")
	state.current_input_path.append(position)
	_emit_remaining_steps()
	return _event("PATH_STEP_ADDED")


func undo_path() -> Dictionary:
	emit_signal("undo_requested")
	if state.phase != BattlePhase.PATH_INPUT:
		return _rejected("UNDO_NOT_ALLOWED")
	if state.current_input_path.size() <= 1:
		return _rejected("NOTHING_TO_UNDO")
	state.current_input_path.pop_back()
	_emit_remaining_steps()
	return _event("UNDO")


func can_confirm_path() -> bool:
	return (
		state.phase == BattlePhase.PATH_INPUT
		and not state.current_input_path.is_empty()
		and state.current_input_path.size() - 1 == state.move_steps
	)


func confirm_path() -> Dictionary:
	emit_signal("path_confirm_requested")
	if state.phase != BattlePhase.PATH_INPUT:
		return _rejected("PATH_CONFIRM_NOT_ALLOWED")
	if not can_confirm_path():
		return _rejected("PATH_INCOMPLETE")
	var committed_path: Array[Vector2i] = state.current_input_path.duplicate()
	for index: int in range(1, committed_path.size()):
		var edge: FoxFireEdge = EdgeScript.new(committed_path[index - 1], committed_path[index])
		if state.severed_edges.has(edge.key()):
			state.severed_edges.erase(edge.key())
			_result.line_cuts_repaired += 1
		state.active_edges[edge.key()] = edge
	state.cat_position = committed_path.back()
	_update_bamboo_direction_after_commit(committed_path)
	_result.total_steps += state.move_steps
	_change_phase(BattlePhase.CAT_MOVING)
	return {
		"ok": true,
		"status": "CAT_MOVING",
		"path": committed_path,
		"cat_position": state.cat_position,
	}


func finish_cat_movement() -> Dictionary:
	if state.phase != BattlePhase.CAT_MOVING:
		return _rejected("CAT_MOVEMENT_NOT_ACTIVE")
	var block_signature := _try_block_seal_bonus()
	_change_phase(BattlePhase.SEAL_RESOLVE)
	var did_seal := _try_complete_seal()
	if state.phase == BattlePhase.VICTORY:
		return _event("VICTORY")
	_change_phase(BattlePhase.SPECIAL_RESOLVE)
	var special_event := _prepare_special_resolution()
	if bool(special_event.get("pending", false)):
		return special_event
	_change_phase(BattlePhase.FOX_ACTION)
	var event := _event("FOX_ACTION")
	event["seal_completed"] = did_seal
	event["block_seal_bonus"] = not block_signature.is_empty()
	return event


func has_exact_route_for_current_move() -> bool:
	return not state.reachable_endpoints.is_empty()


func can_resolve_miss() -> bool:
	return state.phase == BattlePhase.PATH_INPUT and not has_exact_route_for_current_move()


func resolve_miss() -> Dictionary:
	if state.phase != BattlePhase.PATH_INPUT:
		return _rejected("MISS_NOT_ALLOWED")
	if has_exact_route_for_current_move():
		return _rejected("LEGAL_ROUTE_EXISTS")
	state.current_input_path.clear()
	_change_phase(BattlePhase.FOX_ACTION)
	return _event("MISS")


func special_options() -> Array[Vector2i]:
	if state.phase != BattlePhase.SPECIAL_RESOLVE or state.special_kind != &"SAKURA_PURIFY":
		return []
	return _sorted_positions(state.white_fire_cells.keys())


func purify_white_fire(position: Vector2i) -> Dictionary:
	if state.phase != BattlePhase.SPECIAL_RESOLVE or state.special_kind != &"SAKURA_PURIFY":
		return _rejected("SPECIAL_NOT_ALLOWED")
	if not state.white_fire_cells.has(position):
		return _rejected("WHITE_FIRE_TARGET_INVALID")
	state.white_fire_cells.erase(position)
	_result.white_fire_removed += 1
	state.special_kind = &""
	_sync_board_runtime_flags()
	emit_signal("white_fire_changed")
	_change_phase(BattlePhase.FOX_ACTION)
	return {
		"ok": true,
		"status": "SAKURA_PURIFIED",
		"removed": position,
		"removed_count": _result.white_fire_removed,
	}


func skip_special_resolution() -> Dictionary:
	if state.phase != BattlePhase.SPECIAL_RESOLVE:
		return _rejected("SPECIAL_NOT_ALLOWED")
	state.special_kind = &""
	_change_phase(BattlePhase.FOX_ACTION)
	return _event("SPECIAL_SKIPPED")


func resolve_fox_action() -> Dictionary:
	if state.phase != BattlePhase.FOX_ACTION:
		return _rejected("FOX_ACTION_NOT_ALLOWED")
	var scheduled_cells: Array[Vector2i] = state.fox_preview_cells.duplicate()
	var placed_cells: Array[Vector2i] = []
	var selected_cells: Array[Vector2i] = []
	var skipped_by_mangan := false
	var skipped_by_block_bonus := false
	var line_cut_applied := ""
	var fire_action_due := state.fox_preview_due_turn > 0 and state.turn_number >= state.fox_preview_due_turn
	var line_cut_due := state.line_cut_preview_due_turn > 0 and state.turn_number >= state.line_cut_preview_due_turn
	var action_due := fire_action_due or line_cut_due
	if not fire_action_due:
		scheduled_cells.clear()
	if action_due:
		_fox_actions_resolved += 1
		if line_cut_due:
			state.line_cuts_used += 1
		if state.block_bonus_pending:
			state.block_bonus_pending = false
			skipped_by_block_bonus = true
		elif state.mangan_available and state.mangan_armed:
			state.mangan_available = false
			state.mangan_armed = false
			_result.blessings_used += 1
			skipped_by_mangan = true
		else:
			# The committed candidate was chosen with the preview, before any die
			# stopped. Never re-roll A/B after seeing the player's route.
			if fire_action_due and state.fox_committed_cell != Vector2i(-1, -1):
				var selected := state.fox_committed_cell
				selected_cells.append(selected)
				if _can_place_fox_fire(selected):
					state.white_fire_cells[selected] = true
					placed_cells.append(selected)
			if line_cut_due and difficulty_config.enable_line_cut and not state.fox_preview_line_cut_edge.is_empty():
				if state.active_edges.has(state.fox_preview_line_cut_edge):
					var cut_edge: FoxFireEdge = state.active_edges[state.fox_preview_line_cut_edge] as FoxFireEdge
					state.active_edges.erase(state.fox_preview_line_cut_edge)
					if cut_edge != null:
						state.severed_edges[state.fox_preview_line_cut_edge] = cut_edge
					line_cut_applied = state.fox_preview_line_cut_edge
					emit_signal("line_cut_changed", line_cut_applied)
			_result.white_fire_placed += placed_cells.size()
	if fire_action_due:
		state.next_fox_action_turn = state.fox_preview_due_turn + maxi(difficulty_config.attack_interval, 1)
		state.fox_preview_cells.clear()
		state.fox_preview_due_turn = 0
		state.fox_committed_cell = Vector2i(-1, -1)
	if line_cut_due:
		state.fox_preview_line_cut_edge = ""
		state.line_cut_preview_due_turn = 0
	_sync_board_runtime_flags()
	if fire_action_due:
		emit_signal("fox_preview_changed", [])
	if not placed_cells.is_empty():
		emit_signal("white_fire_changed")
	if not any_unvisited_torii_reachable():
		_finish_defeat("ALL_UNVISITED_TORII_UNREACHABLE")
		return {
			"ok": true,
			"status": "DEFEAT",
			"preview_cells": scheduled_cells,
			"selected_cells": selected_cells,
			"placed_cells": placed_cells,
			"line_cut_edge": line_cut_applied,
			"mangan_skipped": skipped_by_mangan,
			"block_seal_bonus": skipped_by_block_bonus,
		}
	_change_phase(BattlePhase.TURN_END)
	return {
		"ok": true,
		"status": "TURN_END",
		"preview_cells": scheduled_cells,
		"selected_cells": selected_cells,
		"placed_cells": placed_cells,
		"line_cut_edge": line_cut_applied,
		"mangan_skipped": skipped_by_mangan,
		"block_seal_bonus": skipped_by_block_bonus,
	}


func finish_turn() -> Dictionary:
	if state.phase != BattlePhase.TURN_END:
		return _rejected("TURN_END_NOT_ACTIVE")
	_start_next_turn()
	return _event("ROLL_SLOT")


func fox_candidate_cells() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y: int in range(BOARD_SIZE):
		for x: int in range(BOARD_SIZE):
			var position := Vector2i(x, y)
			var cell: FoxFireBoardCell = _board.get(position) as FoxFireBoardCell
			if cell == null:
				continue
			if cell.type == FoxFireBoardCell.CellType.TORII:
				continue
			if not _cell_type_enabled_for_difficulty(cell.type):
				continue
			if not _can_place_fox_fire(position):
				continue
			candidates.append(position)
	return candidates


func line_cut_candidate_edges() -> Array[String]:
	var candidates: Array[String] = []
	for edge_key: Variant in state.active_edges.keys():
		var edge := state.active_edges[edge_key] as FoxFireEdge
		if edge != null and _line_cut_is_eligible(edge):
			candidates.append(str(edge_key))
	return candidates


func any_unvisited_torii_reachable() -> bool:
	var targets: Dictionary = {}
	for torii_id: int in range(TORII_POSITIONS.size()):
		if not state.has_visited_torii(torii_id):
			targets[TORII_POSITIONS[torii_id]] = true
	if targets.is_empty():
		return true
	var visited: Dictionary = {state.cat_position: true}
	var queue: Array[Vector2i] = [state.cat_position]
	var cursor: int = 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		if targets.has(current):
			return true
		for direction: Vector2i in ORTHOGONAL_DIRECTIONS:
			var neighbor := current + direction
			if not is_in_bounds(neighbor) or visited.has(neighbor):
				continue
			if state.white_fire_cells.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return false


func _can_place_fox_fire(position: Vector2i) -> bool:
	if not is_in_bounds(position) or position == state.cat_position:
		return false
	if state.white_fire_cells.has(position) or torii_id_at(position) >= 0:
		return false
	if _cell_touches_edges(position, state.active_edges) or _cell_touches_edges(position, state.sealed_edges):
		return false
	var cell := _board.get(position) as FoxFireBoardCell
	if cell == null:
		return false
	if not _cell_type_enabled_for_difficulty(cell.type):
		return false
	return true


func _line_cut_is_eligible(edge: FoxFireEdge) -> bool:
	if edge == null:
		return false
	if torii_id_at(edge.a) >= 0 or torii_id_at(edge.b) >= 0:
		return false
	if edge.a == state.cat_position or edge.b == state.cat_position:
		return false
	return true


func _prepare_special_resolution() -> Dictionary:
	state.special_kind = &""
	if not _sakura_enabled():
		return {"pending": false}
	var cell := _board.get(state.cat_position) as FoxFireBoardCell
	if cell == null:
		return {"pending": false}
	if cell.type == FoxFireBoardCell.CellType.SAKURA and not state.white_fire_cells.is_empty():
		state.special_kind = &"SAKURA_PURIFY"
		var options := special_options()
		if not options.is_empty():
			emit_signal("special_requested", state.special_kind, options.duplicate())
			return {
				"ok": true,
				"status": "SPECIAL_RESOLVE",
				"pending": true,
				"special_kind": state.special_kind,
				"options": options,
			}
	return {"pending": false}


func arm_mangan() -> bool:
	if not state.mangan_available or state.mangan_armed:
		return false
	if state.phase not in [BattlePhase.ROLL_SLOT, BattlePhase.PATH_INPUT, BattlePhase.CAT_MOVING, BattlePhase.FOX_ACTION]:
		return false
	state.mangan_armed = true
	return true


func use_kiyomizu_reroll() -> bool:
	if state.phase not in [BattlePhase.ROLL_SLOT, BattlePhase.PATH_INPUT] or not state.kiyomizu_available:
		return false
	state.kiyomizu_available = false
	_roll_set.restore_faces([])
	_last_slot_role = &""
	_last_completed_slot_faces.clear()
	if state.phase == BattlePhase.PATH_INPUT:
		state.move_steps = 0
		state.current_input_path.clear()
		state.reachable_endpoints.clear()
		emit_signal("move_steps_changed", 0)
		emit_signal("remaining_steps_changed", 0)
		emit_signal("reachable_endpoints_changed", [])
		_change_phase(BattlePhase.ROLL_SLOT)
	_result.rerolls_used += 1
	_result.blessings_used += 1
	return true


func apply_tenryuji_shift(delta: int) -> Dictionary:
	if state.phase != BattlePhase.PATH_INPUT or not state.tenryuji_available:
		return _rejected("TENRYUJI_NOT_AVAILABLE")
	if delta not in [-1, 1]:
		return _rejected("TENRYUJI_DELTA_INVALID")
	if state.current_input_path.size() != 1:
		return _rejected("PATH_ALREADY_STARTED")
	var shifted_value: int = state.move_steps + delta
	if shifted_value < 1 or shifted_value > 6:
		return _rejected("TENRYUJI_OUT_OF_RANGE")
	state.tenryuji_available = false
	_result.blessings_used += 1
	state.move_steps = shifted_value
	state.reachable_endpoints = reachable_endpoints_exact(shifted_value)
	emit_signal("move_steps_changed", state.move_steps)
	_emit_remaining_steps()
	emit_signal("reachable_endpoints_changed", state.reachable_endpoints.duplicate())
	return _event("TENRYUJI_SHIFTED")


func board_cell(position: Vector2i) -> FoxFireBoardCell:
	var cell: FoxFireBoardCell = _board.get(position) as FoxFireBoardCell
	return null if cell == null else cell.duplicate_cell()


func board_cells() -> Array[FoxFireBoardCell]:
	var cells: Array[FoxFireBoardCell] = []
	for y: int in range(BOARD_SIZE):
		for x: int in range(BOARD_SIZE):
			var cell: FoxFireBoardCell = _board.get(Vector2i(x, y)) as FoxFireBoardCell
			if cell != null:
				cells.append(cell.duplicate_cell())
	return cells


func torii_id_at(position: Vector2i) -> int:
	for torii_id: int in range(TORII_POSITIONS.size()):
		if TORII_POSITIONS[torii_id] == position:
			return torii_id
	return -1


func is_in_bounds(position: Vector2i) -> bool:
	return (
		position.x >= 0
		and position.x < BOARD_SIZE
		and position.y >= 0
		and position.y < BOARD_SIZE
	)


func _sakura_enabled() -> bool:
	return difficulty_config.enable_special_tiles and _effective_special_tile_count() >= 1


func _bamboo_enabled() -> bool:
	return difficulty_config.enable_special_tiles and _effective_special_tile_count() >= 2


func _effective_special_tile_count() -> int:
	if not difficulty_config.enable_special_tiles:
		return 0
	return difficulty_config.special_tile_count if difficulty_config.special_tile_count > 0 else 2


func _line_cut_limit() -> int:
	if not difficulty_config.enable_line_cut:
		return 0
	return difficulty_config.maximum_line_cuts if difficulty_config.maximum_line_cuts > 0 else 99


func _cell_type_enabled_for_difficulty(cell_type: int) -> bool:
	match cell_type:
		FoxFireBoardCell.CellType.NORMAL:
			return true
		FoxFireBoardCell.CellType.SAKURA:
			return _sakura_enabled()
		FoxFireBoardCell.CellType.BAMBOO:
			return _bamboo_enabled()
		_:
			return false


func fox_actions_resolved() -> int:
	return _fox_actions_resolved


func result() -> Dictionary:
	return _result.to_dictionary()


func battle_result() -> FoxFireBattleResult:
	return BattleResultScript.from_dictionary(_result.to_dictionary())


func snapshot() -> Dictionary:
	return {
		"version": SNAPSHOT_VERSION,
		"configured": _configured,
		"lap": lap,
		"battle_seed": battle_seed,
		"rng_state": _rng.state,
		"difficulty": difficulty_config.to_snapshot(),
		"phase": state.phase,
		"turn_number": state.turn_number,
		"cat_position": state.cat_position,
		"current_torii_id": state.current_torii_id,
		"move_steps": state.move_steps,
		"current_input_path": state.current_input_path.duplicate(),
		"reachable_endpoints": state.reachable_endpoints.duplicate(),
		"active_edges": _edge_snapshots(state.active_edges),
		"sealed_edges": _edge_snapshots(state.sealed_edges),
		"severed_edges": _edge_snapshots(state.severed_edges),
		"white_fire_cells": _sorted_positions(state.white_fire_cells.keys()),
		"visited_torii": _sorted_ints(state.visited_torii.keys()),
		"seal_count": state.seal_count,
		"fox_preview_cells": state.fox_preview_cells.duplicate(),
		"fox_preview_due_turn": state.fox_preview_due_turn,
		"fox_committed_cell": state.fox_committed_cell,
		"next_fox_action_turn": state.next_fox_action_turn,
		"fox_preview_line_cut_edge": state.fox_preview_line_cut_edge,
		"line_cut_preview_due_turn": state.line_cut_preview_due_turn,
		"special_kind": String(state.special_kind),
		"block_bonus_pending": state.block_bonus_pending,
		"block_bonus_signature": state.block_bonus_signature,
		"forced_exit_direction": state.forced_exit_direction,
		"line_cuts_used": state.line_cuts_used,
		"yasaka_delay_available": state.yasaka_delay_available,
		"kiyomizu_available": state.kiyomizu_available,
		"tenryuji_available": state.tenryuji_available,
		"fushimi_start_choice_available": state.fushimi_start_choice_available,
		"mangan_available": state.mangan_available,
		"mangan_armed": state.mangan_armed,
		"roll_faces": _roll_set.faces(),
		"last_slot_role": String(_last_slot_role),
		"last_completed_slot_faces": _last_completed_slot_faces.duplicate(),
		"fox_actions_resolved": _fox_actions_resolved,
		"result": _result.to_dictionary(),
	}


func restore_snapshot(saved: Dictionary) -> bool:
	if int(saved.get("version", -1)) != SNAPSHOT_VERSION:
		return false
	var restored_lap := int(saved.get("lap", 0))
	var restored_phase := int(saved.get("phase", -1))
	var restored_cat: Variant = saved.get("cat_position")
	var restored_torii := int(saved.get("current_torii_id", -1))
	var restored_steps := int(saved.get("move_steps", -1))
	if restored_lap < 1 or restored_phase < BattlePhase.INTRO or restored_phase > BattlePhase.RESULT:
		return false
	if not restored_cat is Vector2i or not is_in_bounds(restored_cat as Vector2i):
		return false
	if restored_torii < TORII_A or restored_torii > TORII_D or restored_steps < 0 or restored_steps > 6:
		return false
	var restored_path: Variant = _validated_position_array(saved.get("current_input_path", []), true)
	var restored_endpoints: Variant = _validated_position_array(saved.get("reachable_endpoints", []), false)
	var restored_preview: Variant = _validated_position_array(saved.get("fox_preview_cells", []), false)
	var restored_white: Variant = _validated_position_array(saved.get("white_fire_cells", []), false)
	if restored_path == null or restored_endpoints == null or restored_preview == null or restored_white == null:
		return false
	if not restored_path.is_empty() and restored_path[0] != (restored_cat as Vector2i) and restored_phase == BattlePhase.PATH_INPUT:
		# During PATH_INPUT the cat has not moved, so the path must start at the cat.
		return false
	var restored_committed_value: Variant = saved.get("fox_committed_cell", Vector2i(-1, -1))
	if not restored_committed_value is Vector2i:
		return false
	var restored_committed := restored_committed_value as Vector2i
	if restored_committed != Vector2i(-1, -1) and restored_committed not in restored_preview:
		return false
	var restored_preview_due_turn := maxi(int(saved.get("fox_preview_due_turn", 0)), 0)
	var restored_next_fox_action_turn := maxi(int(saved.get("next_fox_action_turn", restored_preview_due_turn)), 0)
	var restored_active: Variant = _restore_edges(saved.get("active_edges", []))
	var restored_sealed: Variant = _restore_edges(saved.get("sealed_edges", []))
	var restored_severed: Variant = _restore_edges(saved.get("severed_edges", []))
	if restored_active == null or restored_sealed == null or restored_severed == null:
		return false
	var restored_line_cut_edge := str(saved.get("fox_preview_line_cut_edge", ""))
	if not restored_line_cut_edge.is_empty() and not (restored_active as Dictionary).has(restored_line_cut_edge):
		return false
	var restored_special_kind := StringName(str(saved.get("special_kind", "")))
	if restored_special_kind not in [&"", &"SAKURA_PURIFY"]:
		return false
	var visited_values: Variant = saved.get("visited_torii", [])
	if not visited_values is Array:
		return false
	var restored_visited: Dictionary = {}
	for value: Variant in visited_values:
		if not (value is int or value is float):
			return false
		var torii_id := int(value)
		if torii_id < TORII_A or torii_id > TORII_D:
			return false
		restored_visited[torii_id] = true
	var restored_seal_count := int(saved.get("seal_count", -1))
	if not restored_visited.has(restored_torii) or restored_seal_count != restored_visited.size() - 1:
		return false
	for position: Vector2i in restored_white:
		if torii_id_at(position) >= 0:
			return false
	var restored_roll_set: RefCounted = V06RollSetScript.new()
	if not restored_roll_set.restore_faces(saved.get("roll_faces", [])):
		return false
	var completed_faces: Variant = _validated_face_array(saved.get("last_completed_slot_faces", []))
	if completed_faces == null:
		return false
	var restored_config_value: Variant = saved.get("difficulty", {})
	var restored_result_value: Variant = saved.get("result", {})
	if not restored_config_value is Dictionary or not restored_result_value is Dictionary:
		return false

	var restored_state: FoxFireBattleState = BattleStateScript.new()
	restored_state.phase = restored_phase
	restored_state.turn_number = maxi(int(saved.get("turn_number", 0)), 0)
	restored_state.difficulty_level = maxi(int((restored_config_value as Dictionary).get("level", 1)), 1)
	restored_state.cat_position = restored_cat as Vector2i
	restored_state.current_torii_id = restored_torii
	restored_state.move_steps = restored_steps
	restored_state.current_input_path = restored_path
	restored_state.reachable_endpoints = restored_endpoints
	restored_state.active_edges = restored_active
	restored_state.sealed_edges = restored_sealed
	restored_state.severed_edges = restored_severed
	for position: Vector2i in restored_white:
		restored_state.white_fire_cells[position] = true
	restored_state.visited_torii = restored_visited
	restored_state.seal_count = restored_seal_count
	restored_state.fox_preview_cells = restored_preview
	restored_state.fox_preview_due_turn = restored_preview_due_turn
	restored_state.fox_committed_cell = restored_committed
	restored_state.next_fox_action_turn = restored_next_fox_action_turn
	restored_state.fox_preview_line_cut_edge = restored_line_cut_edge
	restored_state.line_cut_preview_due_turn = maxi(int(saved.get("line_cut_preview_due_turn", restored_preview_due_turn if not restored_line_cut_edge.is_empty() else 0)), 0)
	restored_state.special_kind = restored_special_kind
	restored_state.block_bonus_pending = bool(saved.get("block_bonus_pending", false))
	restored_state.block_bonus_signature = str(saved.get("block_bonus_signature", ""))
	restored_state.forced_exit_direction = saved.get("forced_exit_direction", Vector2i.ZERO) as Vector2i
	restored_state.line_cuts_used = maxi(int(saved.get("line_cuts_used", 0)), 0)
	restored_state.yasaka_delay_available = bool(saved.get("yasaka_delay_available", false))
	restored_state.kiyomizu_available = bool(saved.get("kiyomizu_available", false))
	restored_state.tenryuji_available = bool(saved.get("tenryuji_available", false))
	restored_state.fushimi_start_choice_available = bool(saved.get("fushimi_start_choice_available", false))
	restored_state.mangan_available = bool(saved.get("mangan_available", false))
	restored_state.mangan_armed = bool(saved.get("mangan_armed", false))

	lap = restored_lap
	battle_seed = int(saved.get("battle_seed", 0))
	_rng = RandomNumberGenerator.new()
	_rng.seed = battle_seed
	_rng.state = int(saved.get("rng_state", _rng.state))
	difficulty_config = DifficultyConfigScript.from_snapshot(restored_config_value as Dictionary)
	state = restored_state
	_roll_set = restored_roll_set
	_last_slot_role = StringName(str(saved.get("last_slot_role", "")))
	_last_completed_slot_faces = completed_faces
	_fox_actions_resolved = maxi(int(saved.get("fox_actions_resolved", 0)), 0)
	_result = BattleResultScript.from_dictionary(restored_result_value as Dictionary)
	_configured = bool(saved.get("configured", true))
	_build_board()
	_sync_board_runtime_flags()
	return true


func restore(saved: Dictionary) -> bool:
	return restore_snapshot(saved)


func _accept_move_steps(value: int) -> Dictionary:
	if value < 1 or value > 6:
		return _rejected("MOVE_VALUE_OUT_OF_RANGE")
	if not _roll_set.append_face(value):
		return _rejected("ROLL_SET_REJECTED_FACE")
	var role: StringName = _roll_set.evaluate_role()
	var current_faces: Array[int] = _roll_set.faces()
	if _roll_set.is_complete():
		_last_slot_role = role
		_last_completed_slot_faces = current_faces.duplicate()
		_roll_set.reset_after_resolution()
	state.move_steps = value
	state.current_input_path = [state.cat_position]
	state.reachable_endpoints = reachable_endpoints_exact(value)
	emit_signal("move_steps_changed", value)
	emit_signal("remaining_steps_changed", value)
	emit_signal("reachable_endpoints_changed", state.reachable_endpoints.duplicate())
	_change_phase(BattlePhase.PATH_INPUT)
	return {
		"ok": true,
		"status": "PATH_INPUT" if not state.reachable_endpoints.is_empty() else "NO_ROUTE",
		"move_steps": value,
		"slot_faces": current_faces,
		"slot_role": role,
		"reachable_endpoints": state.reachable_endpoints.duplicate(),
		"can_resolve_miss": state.reachable_endpoints.is_empty(),
	}


func _start_next_turn() -> void:
	state.turn_number += 1
	state.move_steps = 0
	state.current_input_path.clear()
	state.reachable_endpoints.clear()
	state.special_kind = &""
	_change_phase(BattlePhase.TURN_START)
	if state.fox_preview_due_turn <= 0:
		_prepare_fox_preview()
	else:
		emit_signal("fox_preview_changed", state.fox_preview_cells.duplicate())
	if state.line_cut_preview_due_turn <= 0:
		_prepare_line_cut_preview()
	_change_phase(BattlePhase.ROLL_SLOT)


func _prepare_fox_preview() -> void:
	state.fox_preview_cells.clear()
	state.fox_preview_due_turn = 0
	state.fox_committed_cell = Vector2i(-1, -1)
	if difficulty_config.attack_interval <= 0:
		emit_signal("fox_preview_changed", [])
		return
	if state.next_fox_action_turn <= 0:
		_initialize_fox_schedule()
	# Normal previews are announced one turn in advance. A level whose first
	# action is TURN 1 still locks its target at TURN 1 start, before rolling.
	if state.next_fox_action_turn > state.turn_number + 1:
		emit_signal("fox_preview_changed", [])
		return
	var candidates: Array[Vector2i] = fox_candidate_cells()
	if difficulty_config.level <= 3:
		var non_blocking: Array[Vector2i] = []
		for candidate: Vector2i in candidates:
			if not _would_block_all_unvisited_torii(candidate):
				non_blocking.append(candidate)
		candidates = non_blocking
	if candidates.is_empty():
		emit_signal("fox_preview_changed", [])
		return
	var use_smart_target := (
		difficulty_config.smart_targeting
		and _rng.randf() < clampf(difficulty_config.smart_target_rate, 0.0, 1.0)
	)
	if use_smart_target:
		var ranked: Array[Dictionary] = []
		for candidate: Vector2i in candidates:
			ranked.append({
				"position": candidate,
				"score": _fox_candidate_score(candidate),
				"tie": _rng.randi(),
			})
		ranked.sort_custom(_ranked_candidate_precedes)
		for entry: Dictionary in ranked.slice(0, mini(difficulty_config.candidate_count, ranked.size())):
			state.fox_preview_cells.append(entry["position"] as Vector2i)
	else:
		var safe_candidates := _safe_random_candidates(candidates)
		if not safe_candidates.is_empty():
			candidates = safe_candidates
		var preview_count := mini(difficulty_config.candidate_count, candidates.size())
		for _index: int in range(preview_count):
			var selected_index: int = _rng.randi_range(0, candidates.size() - 1)
			state.fox_preview_cells.append(candidates[selected_index])
			candidates.remove_at(selected_index)
	if not state.fox_preview_cells.is_empty():
		var committed_index := _rng.randi_range(0, state.fox_preview_cells.size() - 1)
		state.fox_committed_cell = state.fox_preview_cells[committed_index]
	state.fox_preview_due_turn = state.next_fox_action_turn
	emit_signal("fox_preview_changed", state.fox_preview_cells.duplicate())


func _prepare_line_cut_preview() -> void:
	state.fox_preview_line_cut_edge = ""
	state.line_cut_preview_due_turn = 0
	if state.line_cuts_used >= _line_cut_limit() or difficulty_config.line_cut_interval <= 0:
		return
	var interval := maxi(difficulty_config.line_cut_interval, 1)
	var next_due := (floori(float(state.turn_number) / float(interval)) + 1) * interval
	if next_due > state.turn_number + 1:
		return
	var preview := _choose_line_cut_preview()
	if preview.is_empty():
		return
	state.fox_preview_line_cut_edge = preview
	state.line_cut_preview_due_turn = next_due


func _initialize_fox_schedule() -> void:
	if state.next_fox_action_turn > 0 or difficulty_config.attack_interval <= 0:
		return
	state.next_fox_action_turn = maxi(difficulty_config.first_attack_turn, 1)
	if state.yasaka_delay_available:
		state.next_fox_action_turn += maxi(difficulty_config.attack_interval, 1)
		state.yasaka_delay_available = false


func _seed_initial_white_fire() -> void:
	if difficulty_config.initial_white_fire_count <= 0 or not state.white_fire_cells.is_empty():
		return
	var candidates := fox_candidate_cells()
	var preferred: Array[Vector2i] = []
	for position: Vector2i in INITIAL_FIRE_PRIORITY:
		if position in candidates and _initial_fire_is_fair(position):
			preferred.append(position)
	for position: Vector2i in candidates:
		if position not in preferred and _initial_fire_is_fair(position):
			preferred.append(position)
	var count := 0
	for position: Vector2i in preferred:
		if count >= difficulty_config.initial_white_fire_count:
			break
		if not _initial_fire_is_fair(position):
			continue
		state.white_fire_cells[position] = true
		count += 1
	_sync_board_runtime_flags()
	if count > 0:
		emit_signal("white_fire_changed")


func _initial_fire_is_fair(position: Vector2i) -> bool:
	var distance := absi(position.x - state.cat_position.x) + absi(position.y - state.cat_position.y)
	if distance <= 1:
		return false
	return difficulty_config.level >= 4 or not _would_block_all_unvisited_torii(position)


func _safe_random_candidates(candidates: Array[Vector2i]) -> Array[Vector2i]:
	var safe: Array[Vector2i] = []
	for position: Vector2i in candidates:
		var distance := absi(position.x - state.cat_position.x) + absi(position.y - state.cat_position.y)
		if distance <= 1:
			continue
		if difficulty_config.level <= 3 and _would_block_all_unvisited_torii(position):
			continue
		safe.append(position)
	return safe


func _would_block_all_unvisited_torii(position: Vector2i) -> bool:
	if state.white_fire_cells.has(position):
		return not any_unvisited_torii_reachable()
	state.white_fire_cells[position] = true
	var blocked := not any_unvisited_torii_reachable()
	state.white_fire_cells.erase(position)
	return blocked


func _fox_candidate_score(position: Vector2i) -> int:
	var score := 0
	var route_scored := false
	var shortest_route_hits := 0
	for torii_id: int in range(TORII_POSITIONS.size()):
		if state.has_visited_torii(torii_id):
			continue
		var target: Vector2i = TORII_POSITIONS[torii_id]
		if _is_on_shortest_route_to_unvisited_torii(position, target):
			shortest_route_hits += 1
			if not route_scored:
				score += 6
				route_scored = true
	# A cell shared by shortest routes toward multiple unvisited torii is the
	# actual strategic intersection described by the design, not merely a grid
	# cell with many geometric neighbours.
	if shortest_route_hits >= 2:
		score += 4
	var cat_distance := absi(position.x - state.cat_position.x) + absi(position.y - state.cat_position.y)
	if cat_distance in [2, 3]:
		score += 3
	if _cell_adjacent_to_edges(position, state.active_edges):
		score += 2
	if cat_distance == 1:
		score -= 5
	return score


func _is_on_shortest_route_to_unvisited_torii(position: Vector2i, target: Vector2i) -> bool:
	if position == state.cat_position:
		return false
	var from_cat := _bfs_distances(state.cat_position)
	var from_target := _bfs_distances(target)
	if not from_cat.has(target) or not from_cat.has(position) or not from_target.has(position):
		return false
	return int(from_cat[position]) + int(from_target[position]) == int(from_cat[target])


func _bfs_distances(start: Vector2i) -> Dictionary:
	var distances: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		for direction: Vector2i in ORTHOGONAL_DIRECTIONS:
			var neighbor := current + direction
			if not is_in_bounds(neighbor) or distances.has(neighbor) or state.white_fire_cells.has(neighbor):
				continue
			distances[neighbor] = int(distances[current]) + 1
			queue.append(neighbor)
	return distances


func _cell_adjacent_to_edges(position: Vector2i, edges: Dictionary) -> bool:
	for edge_value: Variant in edges.values():
		var edge: FoxFireEdge = edge_value as FoxFireEdge
		if edge == null:
			continue
		for endpoint: Vector2i in [edge.a, edge.b]:
			if absi(endpoint.x - position.x) + absi(endpoint.y - position.y) == 1:
				return true
	return false


func _ranked_candidate_precedes(left: Dictionary, right: Dictionary) -> bool:
	var left_score := int(left.get("score", 0))
	var right_score := int(right.get("score", 0))
	if left_score != right_score:
		return left_score > right_score
	return int(left.get("tie", 0)) < int(right.get("tie", 0))


func _choose_line_cut_preview() -> String:
	var candidates: Array[String] = line_cut_candidate_edges()
	if candidates.is_empty():
		return ""
	var ranked: Array[Dictionary] = []
	for edge_key: String in candidates:
		var edge := state.active_edges.get(edge_key) as FoxFireEdge
		if edge == null:
			continue
		var distance_a := absi(edge.a.x - state.cat_position.x) + absi(edge.a.y - state.cat_position.y)
		var distance_b := absi(edge.b.x - state.cat_position.x) + absi(edge.b.y - state.cat_position.y)
		ranked.append({"edge": edge_key, "distance": mini(distance_a, distance_b), "tie": _rng.randi()})
	if ranked.is_empty():
		return ""
	ranked.sort_custom(_line_cut_precedes)
	return str(ranked[0].get("edge", ""))


func _line_cut_precedes(left: Dictionary, right: Dictionary) -> bool:
	var left_distance := int(left.get("distance", 999))
	var right_distance := int(right.get("distance", 999))
	if left_distance != right_distance:
		return left_distance < right_distance
	return int(left.get("tie", 0)) < int(right.get("tie", 0))


func _dfs_exact_endpoints(
	current: Vector2i,
	steps_remaining: int,
	visited: Dictionary,
	endpoints: Dictionary,
	path: Array[Vector2i]
) -> void:
	if steps_remaining == 0:
		endpoints[current] = true
		return
	for direction: Vector2i in ORTHOGONAL_DIRECTIONS:
		var neighbor := current + direction
		if not is_in_bounds(neighbor) or visited.has(neighbor) or state.white_fire_cells.has(neighbor):
			continue
		if _bamboo_enabled() and not _bamboo_step_allowed(path, direction):
			continue
		visited[neighbor] = true
		path.append(neighbor)
		_dfs_exact_endpoints(neighbor, steps_remaining - 1, visited, endpoints, path)
		path.pop_back()
		visited.erase(neighbor)


func _is_legal_forward_step(position: Vector2i, path: Array[Vector2i]) -> bool:
	if not is_in_bounds(position) or state.white_fire_cells.has(position) or path.has(position):
		return false
	if not EdgeScript.is_orthogonal_unit(path.back(), position):
		return false
	return not _bamboo_enabled() or _bamboo_step_allowed(path, position - path.back())


func _bamboo_step_allowed(path: Array[Vector2i], direction: Vector2i) -> bool:
	if path.is_empty():
		return true
	var current: Vector2i = path.back()
	var cell := _board.get(current) as FoxFireBoardCell
	if cell != null and cell.type == FoxFireBoardCell.CellType.BAMBOO and path.size() >= 2:
		var entry_direction: Vector2i = current - path[path.size() - 2]
		return direction == entry_direction
	if path.size() == 1 and state.forced_exit_direction != Vector2i.ZERO:
		return direction == state.forced_exit_direction
	return true


func _update_bamboo_direction_after_commit(path: Array[Vector2i]) -> void:
	if not _bamboo_enabled():
		state.forced_exit_direction = Vector2i.ZERO
		return
	if path.size() < 2:
		return
	var destination: Vector2i = path.back()
	var destination_cell := _board.get(destination) as FoxFireBoardCell
	if destination_cell != null and destination_cell.type == FoxFireBoardCell.CellType.BAMBOO:
		state.forced_exit_direction = destination - path[path.size() - 2]
	else:
		state.forced_exit_direction = Vector2i.ZERO


func _try_complete_seal() -> bool:
	var destination_torii := torii_id_at(state.cat_position)
	if destination_torii < 0 or destination_torii == state.current_torii_id:
		return false
	if state.has_visited_torii(destination_torii):
		return false
	var origin := TORII_POSITIONS[state.current_torii_id]
	if not _positions_connected(origin, state.cat_position, state.active_edges):
		return false
	var component_keys := _component_edge_keys(origin, state.active_edges)
	for edge_key: String in component_keys:
		state.sealed_edges[edge_key] = state.active_edges[edge_key]
	state.active_edges.clear()
	state.seal_count += 1
	state.current_torii_id = destination_torii
	state.visited_torii[destination_torii] = true
	_result.seal_count = state.seal_count
	_sync_board_runtime_flags()
	emit_signal("seal_completed", state.seal_count)
	if state.seal_count >= 3:
		_finish_victory()
	return true


func _try_block_seal_bonus() -> String:
	if not difficulty_config.enable_block_seal_bonus:
		return ""
	var combined_edges: Dictionary = {}
	for edge_key: Variant in state.sealed_edges:
		combined_edges[str(edge_key)] = state.sealed_edges[edge_key]
	for edge_key: Variant in state.active_edges:
		combined_edges[str(edge_key)] = state.active_edges[edge_key]
	var cycle := _find_cycle_in_edges(combined_edges)
	if cycle.is_empty():
		return ""
	var signature := _cycle_signature(cycle)
	if signature.is_empty() or signature == state.block_bonus_signature:
		return ""
	state.block_bonus_signature = signature
	state.block_bonus_pending = true
	_result.city_blocks_sealed += 1
	var removed_positions := _sorted_positions(state.white_fire_cells.keys())
	if not removed_positions.is_empty():
		state.white_fire_cells.erase(removed_positions[0])
		_result.white_fire_removed += 1
		_sync_board_runtime_flags()
		emit_signal("white_fire_changed")
	return signature


func _find_cycle_in_edges(edges: Dictionary) -> Array[Vector2i]:
	var keys: Array = edges.keys()
	keys.sort()
	for edge_key_value: Variant in keys:
		var edge_key := str(edge_key_value)
		var edge: FoxFireEdge = edges[edge_key] as FoxFireEdge
		if edge == null:
			continue
		var path := _find_edge_path(edge.a, edge.b, edges, edge_key)
		if path.size() < 3:
			continue
		if _cycle_encloses_board_cell(path):
			return path
	return []


func _find_edge_path(start: Vector2i, target: Vector2i, edges: Dictionary, excluded_key: String) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var parent: Dictionary = {start: Vector2i(-99, -99)}
	var cursor := 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		if current == target:
			break
		for edge_key_value: Variant in edges:
			var edge_key := str(edge_key_value)
			if edge_key == excluded_key:
				continue
			var edge: FoxFireEdge = edges[edge_key] as FoxFireEdge
			if edge == null or not edge.touches(current):
				continue
			var neighbor := edge.other(current)
			if parent.has(neighbor):
				continue
			parent[neighbor] = current
			queue.append(neighbor)
	if not parent.has(target):
		return []
	var reversed_path: Array[Vector2i] = []
	var cursor_position: Vector2i = target
	while cursor_position != Vector2i(-99, -99):
		reversed_path.append(cursor_position)
		cursor_position = parent[cursor_position] as Vector2i
	reversed_path.reverse()
	return reversed_path


func _cycle_encloses_board_cell(vertices: Array[Vector2i]) -> bool:
	if vertices.size() < 4:
		return false
	var polygon: PackedVector2Array = PackedVector2Array()
	for vertex: Vector2i in vertices:
		polygon.append(Vector2(vertex.x, vertex.y))
	for y: int in range(BOARD_SIZE - 1):
		for x: int in range(BOARD_SIZE - 1):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			if Geometry2D.is_point_in_polygon(point, polygon):
				return true
	return false


func _cycle_signature(vertices: Array[Vector2i]) -> String:
	if vertices.size() < 4:
		return ""
	var edge_keys: Array[String] = []
	for index: int in range(vertices.size() - 1):
		var edge := EdgeScript.new(vertices[index], vertices[index + 1])
		edge_keys.append(edge.key())
	edge_keys.sort()
	return "|".join(edge_keys)


func _positions_connected(start: Vector2i, target: Vector2i, edges: Dictionary) -> bool:
	if start == target:
		return true
	var visited: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var cursor: int = 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		for edge_value: Variant in edges.values():
			var edge: FoxFireEdge = edge_value as FoxFireEdge
			if edge == null or not edge.touches(current):
				continue
			var neighbor := edge.other(current)
			if neighbor == target:
				return true
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return false


func _component_edge_keys(start: Vector2i, edges: Dictionary) -> Array[String]:
	var component: Dictionary = {}
	var visited: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var cursor: int = 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		for edge_key: Variant in edges:
			var edge: FoxFireEdge = edges[edge_key] as FoxFireEdge
			if edge == null or not edge.touches(current):
				continue
			component[str(edge_key)] = true
			var neighbor := edge.other(current)
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	var keys: Array[String] = []
	for edge_key: Variant in component:
		keys.append(str(edge_key))
	keys.sort()
	return keys


func _cell_touches_edges(position: Vector2i, edges: Dictionary) -> bool:
	for edge_value: Variant in edges.values():
		var edge: FoxFireEdge = edge_value as FoxFireEdge
		if edge != null and edge.touches(position):
			return true
	return false


func _finish_victory() -> void:
	_result.victory = true
	_result.defeat_reason = ""
	_result.turns_used = state.turn_number
	_result.seal_count = state.seal_count
	_change_phase(BattlePhase.VICTORY)
	emit_signal("battle_finished", battle_result())


func _finish_defeat(reason: String) -> void:
	_result.victory = false
	_result.defeat_reason = reason
	_result.turns_used = state.turn_number
	_result.seal_count = state.seal_count
	_change_phase(BattlePhase.DEFEAT)
	emit_signal("battle_finished", battle_result())


func _build_board() -> void:
	_board.clear()
	for y: int in range(BOARD_SIZE):
		for x: int in range(BOARD_SIZE):
			var position := Vector2i(x, y)
			_board[position] = BoardCellScript.new(position)
	for torii_id: int in range(TORII_POSITIONS.size()):
		var position: Vector2i = TORII_POSITIONS[torii_id]
		_board[position] = BoardCellScript.new(position, FoxFireBoardCell.CellType.TORII, torii_id)
	_board[Vector2i(2, 2)] = BoardCellScript.new(Vector2i(2, 2), FoxFireBoardCell.CellType.SAKURA)
	_board[Vector2i(2, 4)] = BoardCellScript.new(Vector2i(2, 4), FoxFireBoardCell.CellType.BAMBOO)


func _sync_board_runtime_flags() -> void:
	for cell_value: Variant in _board.values():
		var cell: FoxFireBoardCell = cell_value as FoxFireBoardCell
		if cell == null:
			continue
		cell.has_white_fire = state.white_fire_cells.has(cell.position)
		cell.visited_torii = cell.torii_id >= 0 and state.has_visited_torii(cell.torii_id)


func _emit_remaining_steps() -> void:
	emit_signal("remaining_steps_changed", state.remaining_steps())


func _change_phase(next_phase: BattlePhase) -> void:
	state.phase = next_phase
	emit_signal("phase_changed", state.phase)


func _edge_snapshots(edges: Dictionary) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	var keys: Array = edges.keys()
	keys.sort()
	for edge_key: Variant in keys:
		var edge: FoxFireEdge = edges[edge_key] as FoxFireEdge
		if edge != null:
			snapshots.append(edge.to_snapshot())
	return snapshots


func _restore_edges(value: Variant) -> Variant:
	if not value is Array:
		return null
	var restored: Dictionary = {}
	for edge_value: Variant in value:
		if not edge_value is Dictionary:
			return null
		var edge_data := edge_value as Dictionary
		var first: Variant = edge_data.get("a")
		var second: Variant = edge_data.get("b")
		if not first is Vector2i or not second is Vector2i:
			return null
		if not is_in_bounds(first as Vector2i) or not is_in_bounds(second as Vector2i):
			return null
		if not EdgeScript.is_orthogonal_unit(first as Vector2i, second as Vector2i):
			return null
		var edge: FoxFireEdge = EdgeScript.new(first as Vector2i, second as Vector2i)
		if restored.has(edge.key()):
			return null
		restored[edge.key()] = edge
	return restored


func _validated_position_array(value: Variant, require_path_rules: bool) -> Variant:
	if not value is Array:
		return null
	var result: Array[Vector2i] = []
	var seen: Dictionary = {}
	for position_value: Variant in value:
		if not position_value is Vector2i or not is_in_bounds(position_value as Vector2i):
			return null
		var position := position_value as Vector2i
		if seen.has(position):
			return null
		if require_path_rules and not result.is_empty() and not EdgeScript.is_orthogonal_unit(result.back(), position):
			return null
		seen[position] = true
		result.append(position)
	return result


func _validated_face_array(value: Variant) -> Variant:
	if not value is Array:
		return null
	var result: Array[int] = []
	if value.size() not in [0, V06RollSetScript.SLOT_COUNT]:
		return null
	for face_value: Variant in value:
		if not (face_value is int or face_value is float):
			return null
		var face := int(face_value)
		if face < 1 or face > 6:
			return null
		result.append(face)
	return result


func _sorted_positions(values: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value: Variant in values:
		if value is Vector2i:
			result.append(value as Vector2i)
	result.sort_custom(_position_precedes)
	return result


func _sorted_ints(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in values:
		result.append(int(value))
	result.sort()
	return result


func _position_precedes(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)


func _event(status: String) -> Dictionary:
	return {"ok": true, "status": status, "phase": state.phase}


func _rejected(error: String) -> Dictionary:
	return {"ok": false, "status": "REJECTED", "error": error, "phase": state.phase}
