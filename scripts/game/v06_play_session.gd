class_name V06PlaySession
extends RefCounted

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const V06BossBattleScript = preload("res://scripts/game/v06_boss_battle.gd")
const COURSE_PATH := "res://data/stages/v06_cairo_course.json"
const DEFAULT_STAGE_ID: StringName = &"cairo_hourglass"
const DEFAULT_CHARACTER_ID: StringName = &"relaxed"

const PHASE_READY: StringName = &"READY"
const PHASE_MOVING: StringName = &"MOVING"
const PHASE_CHOICE_REQUIRED: StringName = &"CHOICE_REQUIRED"
const PHASE_RESOLUTION_REQUIRED: StringName = &"RESOLUTION_REQUIRED"
const PHASE_BOSS_ROLL_READY: StringName = &"BOSS_ROLL_READY"
const PHASE_BOSS_ROUND_RESULT: StringName = &"BOSS_ROUND_RESULT"
const PHASE_LAP_RESULT: StringName = &"LAP_RESULT"
const PHASE_RUN_OVER: StringName = &"RUN_OVER"
const PHASE_BOSS_GATE: StringName = PHASE_BOSS_ROLL_READY # Compatibility only.
const PHASE_ERROR: StringName = &"ERROR"
const SCORE_PER_STEP := 10
const SCORE_COIN := 50
const SCORE_REST := 40
const SCORE_ITEM := 120
const SCORE_EVENT := 150
const SCORE_WARP := 100
const SCORE_BRANCH := 50
const SCORE_BOSS_GATE := 200
const SCORE_BYPASS_CLEAR := 300
const SCORE_LOOP_EXIT := 400
const SCORE_OASIS_EXIT := 400
const SCORE_TOMB_EXIT := 600
const SCORE_MIX := 50
const SCORE_PAIR := 150
const SCORE_STRAIGHT := 350
const SCORE_TRIPLE := 800
const SCORE_BOSS_COMPLETE := 500
const SCORE_BOSS_VICTORY := 1000
const SCORE_FINISH := 1000
const SCORE_FINISH_HP := 200
const SCORE_FINISH_FULL_HP := 300
const SKILL_GAUGE_MAX := 3
const SKILL_STATE_CHARGING: StringName = &"CHARGING"
const SKILL_STATE_READY: StringName = &"READY"
const SKILL_STATE_ARMED: StringName = &"ARMED"
const SAVE_STABLE_PHASES := [PHASE_READY, PHASE_CHOICE_REQUIRED, PHASE_BOSS_ROLL_READY, PHASE_BOSS_ROUND_RESULT, PHASE_LAP_RESULT, PHASE_RUN_OVER]
const MAX_PLAYER_HP := 3
const DEFAULT_COIN_GAIN := 2
const DEFAULT_REST_HEAL := 1
const DEFAULT_RISK_AMOUNT := 1
const STAGE_FLAG_NEXT_MOVE_PENALTY := "v06_next_basic_move_penalty"
const STAGE_FLAG_LAST_TILE_EFFECT := "v06_last_tile_effect"
const STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS := "v06_resolved_tile_effect_ids"

var _course: RefCounted
var _travel: RefCounted
var _battle: RefCounted
var _course_ready := false
var _position: Dictionary = {"route_id":"main", "tile_index":0}
var _visual_position: Dictionary = {"route_id":"main", "tile_index":0}
var _phase: StringName = PHASE_READY
var _pending_face := 0
var _pending_move_distance := 0
var _pending_remaining_steps := 0
var _pending_result: Dictionary = {}
var _pending_path: Array[Dictionary] = []
var _next_hop_index := 0
var _resolution_role: StringName = &""
var _pending_resolution_role: StringName = &""
var _pending_role_awarded := false
var _boss_transition_pending := false
var _active_warp_gate_id := ""
var _consumed_warp_gate_ids := {}
var _visited_node_keys := {}
var _consumed_reward_node_keys := {}
var _awarded_score_event_ids := {}
var _last_error := ""
var _lap := 1
var _player_hp := 3
var _roll_count := 0
var _score := 0
var _coins := 0
var _skill_gauge := 0
var _skill_state: StringName = SKILL_STATE_CHARGING
var _role_counts: Dictionary = {"MIX":0, "PAIR":0, "STRAIGHT":0, "TRIPLE":0}
var _last_role: StringName = &""
var _inventory: Dictionary = {}
var _item_consumption: Dictionary = {}
var _stage_flags: Dictionary = {}
var _best_score := 0
var _score_event_serial := 0
var _last_score_award: Dictionary = {}
var _score_breakdown: Dictionary = {}

# Clock state. The session never reads system time.
var _clock_armed := true
var _clock_running := false
var _clock_paused := false
var _clock_start_ms := 0
var _paused_total_ms := 0
var _pause_started_ms := 0
var _clock_stop_ms := 0
var _last_now_ms := -1
var _best_ms: Variant = null
var _pb_updated := false
var _pb_delta_ms: Variant = null
var _stage_id: StringName = DEFAULT_STAGE_ID
var _character_id: StringName = DEFAULT_CHARACTER_ID


func _init(stage_id: StringName = DEFAULT_STAGE_ID, character_id: StringName = DEFAULT_CHARACTER_ID) -> void:
	_stage_id = stage_id if not String(stage_id).is_empty() else DEFAULT_STAGE_ID
	_character_id = character_id if not String(character_id).is_empty() else DEFAULT_CHARACTER_ID
	_course = V06CourseModelScript.new()
	_course_ready = _course.load_file(COURSE_PATH)
	_reset_run_state(false)
	if not _course_ready:
		_phase = PHASE_ERROR
		_last_error = str(_course.validation_error)


func restart() -> bool:
	return retry_run()


func retry_run() -> bool:
	if not _course_ready:
		return false
	_reset_run_state(true)
	return true


func start_roll(face: int, now_ms: int = -1) -> Dictionary:
	if face < 1 or face > 6:
		return _rejected("INVALID_FACE")
	if _clock_paused:
		return _rejected("CLOCK_PAUSED")
	if _phase == PHASE_BOSS_ROLL_READY:
		if not _accept_now(now_ms):
			return _rejected("TIMESTAMP_REGRESSION")
		var boss_event: Dictionary = _battle.roll_face(face)
		if not bool(boss_event.get("ok", false)):
			return _rejected(str(boss_event.get("error", "BOSS_ROLL_REJECTED")))
		if str(boss_event.get("status", "")) == "TURN_RESOLVED":
			_phase = PHASE_BOSS_ROUND_RESULT
			var result: Dictionary = _battle.result()
			var boss_role := StringName(str(result.get("role", "")))
			if boss_role != &"":
				_award_role_score(boss_role)
			_player_hp = int(result.get("player_hp_after", _player_hp))
			if bool(result.get("victory", false)) or bool(result.get("defeat", false)):
				_stop_clock(now_ms)
				_add_score_once("boss_complete", SCORE_BOSS_COMPLETE, "BOSS COMPLETE", "boss")
				_update_pb()
				if bool(result.get("victory", false)):
					_add_score_once("boss_victory", SCORE_BOSS_VICTORY, "BOSS WIN", "boss")
				_award_finish_score()
				_update_best_score()
		_roll_count += 1
		return _event(true, str(boss_event.get("status", "FACE_ACCEPTED")))
	if not _course_ready:
		return _rejected("INVALID_COURSE_DATA")
	if _phase != PHASE_READY:
		return _rejected("ROLL_NOT_AVAILABLE")
	if not _accept_now(now_ms):
		return _rejected("TIMESTAMP_REGRESSION")
	_start_clock_if_armed(now_ms)
	_pending_face = face
	_pending_move_distance = _basic_move_distance(face)
	var result: Dictionary = _course.advance(_position, _pending_move_distance, "", _course_context())
	if not bool(result.get("ok", false)) and str(result.get("error", "")) != "CHOICE_REQUIRED":
		_pending_face = 0
		_pending_move_distance = 0
		_last_error = str(result.get("error", "COURSE_ADVANCE_FAILED"))
		return _rejected(_last_error)
	_consume_next_move_penalty()
	_prepare_movement(result)
	_prepare_pending_role_reward()
	_roll_count += 1
	return _event(true, "MOVEMENT_STARTED")


func has_pending_hops() -> bool:
	return _phase == PHASE_MOVING and _next_hop_index < _pending_path.size()


func pending_hop_count() -> int:
	return maxi(_pending_path.size() - _next_hop_index, 0) if _phase == PHASE_MOVING else 0


func pending_hop_positions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _phase != PHASE_MOVING:
		return result
	for index: int in range(_next_hop_index, _pending_path.size()):
		result.append(_pending_path[index].duplicate(true))
	return result


func next_hop() -> Dictionary:
	if not has_pending_hops(): return {}
	var hop: Dictionary = _pending_path[_next_hop_index].duplicate(true)
	_next_hop_index += 1
	_visual_position = hop.duplicate(true)
	return hop


func finish_movement() -> Dictionary:
	if _phase != PHASE_MOVING: return _rejected("MOVEMENT_NOT_ACTIVE")
	if has_pending_hops(): return _rejected("HOPS_REMAIN")
	var movement_path := _pending_path.duplicate(true)
	var result := _pending_result.duplicate(true)
	_position = (result.get("position", _position) as Dictionary).duplicate(true)
	_visual_position = _position.duplicate(true)
	_pending_result.clear(); _pending_path.clear(); _next_hop_index = 0
	_award_first_visit_steps(movement_path)
	if not bool(result.get("ok", false)):
		if str(result.get("error", "")) == "CHOICE_REQUIRED":
			_pending_remaining_steps = int(result.get("remaining_steps", 0)); _phase = PHASE_CHOICE_REQUIRED
			return _event(true, "CHOICE_REQUIRED")
		_pending_face = 0; _pending_move_distance = 0; _pending_remaining_steps = 0; _phase = PHASE_READY
		return _rejected(str(result.get("error", "COURSE_ADVANCE_FAILED")))
	if not _travel.append_face(_pending_face):
		_phase = PHASE_ERROR
		return _rejected("FACE_COMMIT_FAILED")
	_pending_face = 0; _pending_move_distance = 0; _pending_remaining_steps = 0
	_resolution_role = _travel.evaluate_role()
	if _pending_resolution_role != &"" and _pending_resolution_role != _resolution_role:
		_phase = PHASE_ERROR
		return _rejected("PENDING_ROLE_MISMATCH")
	var entered_gate_id := str(result.get("entered_warp_gate_id", ""))
	var exited_gate_id := str(result.get("exited_warp_gate_id", ""))
	if not entered_gate_id.is_empty():
		_active_warp_gate_id = entered_gate_id
		_consumed_warp_gate_ids[entered_gate_id] = true
		_mark_position_visited(_position)
		_add_score_once("warp:%s" % entered_gate_id, SCORE_WARP, "WARP %s" % entered_gate_id, "discovery")
	elif not exited_gate_id.is_empty():
		_mark_position_visited(_position)
	var landing_kind := current_tile_kind()
	_resolve_landing_effect(landing_kind)
	_award_landing_score(landing_kind)
	_award_route_completion_score(result)
	if not exited_gate_id.is_empty():
		_active_warp_gate_id = ""
	if _travel.is_complete() and not _pending_role_awarded:
		_award_role_score(_resolution_role)
	_pending_resolution_role = &""
	_pending_role_awarded = false
	var gate := bool(result.get("boss_gate_reached", false))
	_boss_transition_pending = gate and _travel.is_complete()
	if _boss_transition_pending or (_travel.is_complete() and not gate):
		_phase = PHASE_RESOLUTION_REQUIRED
	elif gate:
		_enter_boss_internal()
	else:
		_phase = PHASE_READY
	return _event(true, "BOSS_GATE_REACHED" if gate else "ROLL_COMMITTED")


func choose_route(route_id: String) -> Dictionary:
	if _phase != PHASE_CHOICE_REQUIRED: return _rejected("CHOICE_NOT_AVAILABLE")
	var bypass: Dictionary = _course.bypass_for_fork(int(_position.get("tile_index", -1)))
	if bypass.is_empty() or (route_id != V06CourseModelScript.ROUTE_MAIN and route_id != str(bypass.route_id)):
		return _rejected("INVALID_ROUTE_CHOICE")
	var result: Dictionary = _course.advance(_position, _pending_remaining_steps, route_id, _course_context())
	if not bool(result.get("ok", false)): return _rejected(str(result.get("error", "COURSE_ADVANCE_FAILED")))
	_add_score_once("branch:main:%d" % int(_position.tile_index), SCORE_BRANCH, "BRANCH", "travel")
	_pending_remaining_steps = 0
	_prepare_movement(result)
	return _event(true, "MOVEMENT_RESUMED")


func acknowledge_resolution() -> bool:
	if _phase != PHASE_RESOLUTION_REQUIRED or not _travel.is_complete(): return false
	if not _travel.reset_after_resolution(): return false
	_resolution_role = &""
	if _boss_transition_pending:
		_boss_transition_pending = false
		_enter_boss_internal()
	else: _phase = PHASE_READY
	return true


func acknowledge_boss_round() -> bool:
	if _phase != PHASE_BOSS_ROUND_RESULT: return false
	var result: Dictionary = _battle.result()
	if not _battle.acknowledge_round(): return false
	if bool(result.get("victory", false)) or bool(result.get("defeat", false)): _phase = PHASE_LAP_RESULT
	else: _phase = PHASE_BOSS_ROLL_READY
	return true


func next_lap() -> bool:
	if _phase != PHASE_LAP_RESULT: return false
	_lap += 1
	var monotonic_floor := _last_now_ms
	_reset_course_and_clock()
	_last_now_ms = monotonic_floor
	return true


func enter_boss(now_ms: int) -> bool:
	if _phase != PHASE_READY or not _accept_now(now_ms): return false
	_start_clock_if_armed(now_ms)
	_enter_boss_internal()
	return true


func pause_clock(now_ms: int) -> bool:
	if not _clock_running or _clock_paused: return false
	if not _accept_now(now_ms): return false
	_clock_paused = true; _pause_started_ms = now_ms
	return true


func resume_clock(now_ms: int) -> bool:
	if not _clock_running or not _clock_paused: return false
	if not _accept_now(now_ms): return false
	_paused_total_ms += now_ms - _pause_started_ms
	_clock_paused = false; _pause_started_ms = 0
	return true


func elapsed_ms(now_ms: int = -1) -> int:
	if _clock_armed: return 0
	var end_ms := _clock_stop_ms if not _clock_running else (_pause_started_ms if _clock_paused else now_ms)
	if end_ms < 0: end_ms = _last_now_ms
	return maxi(end_ms - _clock_start_ms - _paused_total_ms, 0)


func position() -> Dictionary: return _position.duplicate(true)
func visual_position() -> Dictionary: return _visual_position.duplicate(true)
func faces() -> Array[int]: return _battle.faces() if _battle != null else _travel.faces()
func phase() -> StringName: return _phase
func resolution_role() -> StringName: return _resolution_role
func pending_resolution_role() -> StringName: return _pending_resolution_role
func pending_face() -> int: return _pending_face
func pending_move_distance() -> int: return _pending_move_distance
func pending_remaining_steps() -> int: return _pending_remaining_steps
func is_boss_terminal() -> bool: return _phase in [PHASE_LAP_RESULT, PHASE_RUN_OVER]
func can_roll() -> bool: return _phase in [PHASE_READY, PHASE_BOSS_ROLL_READY]
func lap() -> int: return _lap
func roll_count() -> int: return _roll_count
func player_hp() -> int: return _player_hp
func score() -> int: return _score
func coins() -> int: return _coins
func skill_gauge() -> int: return _skill_gauge
func skill_state() -> StringName: return _skill_state
func role_counts() -> Dictionary: return _role_counts.duplicate(true)
func last_role() -> StringName: return _last_role
func inventory() -> Dictionary: return _inventory.duplicate(true)
func item_consumption() -> Dictionary: return _item_consumption.duplicate(true)
func stage_flags() -> Dictionary: return _stage_flags.duplicate(true)
func next_basic_move_penalty() -> int: return maxi(int(_stage_flags.get(STAGE_FLAG_NEXT_MOVE_PENALTY, 0)), 0)
func last_tile_effect_result() -> Dictionary:
	var value: Variant = _stage_flags.get(STAGE_FLAG_LAST_TILE_EFFECT, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
func stage_id() -> StringName: return _stage_id
func character_id() -> StringName: return _character_id
func active_warp_gate_id() -> String: return _active_warp_gate_id
func consumed_warp_gate_ids() -> PackedStringArray: return PackedStringArray(_consumed_warp_gate_ids.keys())
func consumed_reward_node_keys() -> PackedStringArray: return PackedStringArray(_consumed_reward_node_keys.keys())
func visited_node_keys() -> PackedStringArray: return PackedStringArray(_visited_node_keys.keys())
func best_score() -> int: return _best_score
func score_breakdown() -> Dictionary: return _score_breakdown.duplicate(true)
func last_score_award() -> Dictionary: return _last_score_award.duplicate(true)
func best_ms() -> Variant: return _best_ms
func pb_delta_ms(now_ms: int = -1) -> Variant:
	if _clock_armed or _best_ms == null: return null
	if not _clock_running: return _pb_delta_ms
	return elapsed_ms(now_ms) - int(_best_ms)
func boss_snapshot() -> Dictionary: return _battle.snapshot() if _battle != null else {}
func boss_result() -> Dictionary: return _battle.result() if _battle != null else {}


func is_stable_for_save() -> bool:
	return _phase in SAVE_STABLE_PHASES and _pending_result.is_empty() and _pending_path.is_empty() and _next_hop_index == 0


func stable_save_snapshot(now_ms: int = -1) -> Dictionary:
	if not is_stable_for_save():
		return {}
	var route_id := str(_position.get("route_id", "main"))
	var tile_index := int(_position.get("tile_index", 0))
	var available_route_ids: Array[String] = []
	if _phase == PHASE_CHOICE_REQUIRED:
		available_route_ids.append(V06CourseModelScript.ROUTE_MAIN)
		var bypass := pending_bypass()
		if not bypass.is_empty():
			available_route_ids.append(str(bypass.get("route_id", "")))
	var loop_id := route_id if _course.is_loop_route(route_id) else ""
	var loop_definition: Dictionary = _course.loop_definition(route_id) if not loop_id.is_empty() else {}
	var slot_faces := faces()
	var boss_data := boss_snapshot()
	return {
		"phase": String(_phase),
		"lap": _lap,
		"roll_count": _roll_count,
		"player": {
			"hp": _player_hp,
			"max_hp": MAX_PLAYER_HP,
			"coins": _coins,
			"skill_gauge": _skill_gauge,
			"skill_state": String(_skill_state),
			"inventory": _inventory.duplicate(true),
			"item_consumption": _item_consumption.duplicate(true),
			"stage_flags": _stage_flags.duplicate(true),
		},
		"route": {
			"current_node_id": _position_key(_position),
			"route_id": route_id,
			"tile_index": tile_index,
			"pending_face": _pending_face if _phase == PHASE_CHOICE_REQUIRED else 0,
			"pending_remaining_steps": _pending_remaining_steps if _phase == PHASE_CHOICE_REQUIRED else 0,
			"available_route_ids": available_route_ids,
			"active_warp_gate_id": _active_warp_gate_id,
			"consumed_warp_gate_ids": _string_keys(_consumed_warp_gate_ids),
			"visited_node_keys": _string_keys(_visited_node_keys),
			"consumed_reward_node_keys": _string_keys(_consumed_reward_node_keys),
			"awarded_score_event_ids": _string_keys(_awarded_score_event_ids),
			"loop_id": loop_id,
			"loop_tile_index": tile_index if not loop_id.is_empty() else -1,
			"loop_exit_steps": _course.steps_to_exit(_position) if not loop_id.is_empty() else -1,
			"exit_position": loop_definition.get("exit_position", {}) if not loop_definition.is_empty() else {},
		},
		"slot": {
			"faces": slot_faces,
			"current_roll_index": slot_faces.size(),
			"last_role": String(_last_role),
			"last_role_resolved": not _last_role.is_empty(),
			"resolution_role": String(_resolution_role),
			"pending_role": String(_pending_resolution_role),
			"pending_role_awarded": _pending_role_awarded,
			"next_set_carry": false,
		},
		"score": {
			"total": _score,
			"breakdown": _score_breakdown.duplicate(true),
			"role_counts": _role_counts.duplicate(true),
			"last_award": _last_score_award.duplicate(true),
		},
		"records": {
			"best_score": _best_score,
			"best_ms": _best_ms,
			"pb_delta_ms": pb_delta_ms(now_ms),
			"pb_updated": _pb_updated,
		},
		"clock": {
			"elapsed_ms": elapsed_ms(now_ms),
			"armed": _clock_armed,
			"running": _clock_running,
			"paused": _clock_paused,
		},
		"boss": boss_data,
		"boss_entered": _battle != null,
		"pending_transaction": null,
	}


func restore_stable_snapshot(state: Dictionary, now_ms: int = -1) -> bool:
	if not _course_ready or state.is_empty():
		return false
	var phase := StringName(str(state.get("phase", "")))
	if phase not in SAVE_STABLE_PHASES:
		return false
	var player: Dictionary = state.get("player", {})
	var route: Dictionary = state.get("route", {})
	var slot: Dictionary = state.get("slot", {})
	var score_data: Dictionary = state.get("score", {})
	var records: Dictionary = state.get("records", {})
	var clock: Dictionary = state.get("clock", {})
	if not player is Dictionary or not route is Dictionary or not slot is Dictionary or not score_data is Dictionary or not records is Dictionary or not clock is Dictionary:
		return false
	var route_id := str(route.get("route_id", ""))
	var tile_index := int(route.get("tile_index", -1))
	if not _course_position_exists(route_id, tile_index):
		return false
	var face_values: Variant = slot.get("faces", [])
	if not face_values is Array or face_values.size() > V06RollSetScript.SLOT_COUNT:
		return false
	_reset_run_state(false)
	_stage_id = _stage_id if not String(_stage_id).is_empty() else DEFAULT_STAGE_ID
	_character_id = _character_id if not String(_character_id).is_empty() else DEFAULT_CHARACTER_ID
	_lap = maxi(int(state.get("lap", 1)), 1)
	_roll_count = maxi(int(state.get("roll_count", 0)), 0)
	_player_hp = clampi(int(player.get("hp", MAX_PLAYER_HP)), 0, MAX_PLAYER_HP)
	_coins = maxi(int(player.get("coins", 0)), 0)
	_skill_gauge = clampi(int(player.get("skill_gauge", 0)), 0, SKILL_GAUGE_MAX)
	_skill_state = StringName(str(player.get("skill_state", SKILL_STATE_CHARGING)))
	_inventory = (player.get("inventory", {}) as Dictionary).duplicate(true)
	_item_consumption = (player.get("item_consumption", {}) as Dictionary).duplicate(true)
	_stage_flags = (player.get("stage_flags", {}) as Dictionary).duplicate(true)
	_position = {"route_id":route_id, "tile_index":tile_index}
	_visual_position = _position.duplicate(true)
	_active_warp_gate_id = str(route.get("active_warp_gate_id", ""))
	_restore_string_set(_consumed_warp_gate_ids, route.get("consumed_warp_gate_ids", []))
	_restore_string_set(_visited_node_keys, route.get("visited_node_keys", []))
	_restore_string_set(_consumed_reward_node_keys, route.get("consumed_reward_node_keys", []))
	_restore_string_set(_awarded_score_event_ids, route.get("awarded_score_event_ids", []))
	_score = maxi(int(score_data.get("total", 0)), 0)
	_score_breakdown = (score_data.get("breakdown", {}) as Dictionary).duplicate(true)
	_role_counts = {"MIX":0, "PAIR":0, "STRAIGHT":0, "TRIPLE":0}
	for role: String in _role_counts.keys():
		_role_counts[role] = maxi(int((score_data.get("role_counts", {}) as Dictionary).get(role, 0)), 0)
	_last_score_award = (score_data.get("last_award", {}) as Dictionary).duplicate(true)
	_score_event_serial = int(_last_score_award.get("serial", 0))
	_best_score = maxi(int(records.get("best_score", 0)), 0)
	_best_ms = records.get("best_ms", null)
	_pb_delta_ms = records.get("pb_delta_ms", null)
	_pb_updated = bool(records.get("pb_updated", false))
	_pending_face = int(route.get("pending_face", 0)) if phase == PHASE_CHOICE_REQUIRED else 0
	_pending_remaining_steps = maxi(int(route.get("pending_remaining_steps", 0)), 0) if phase == PHASE_CHOICE_REQUIRED else 0
	_last_role = StringName(str(slot.get("last_role", "")))
	_resolution_role = StringName(str(slot.get("resolution_role", "")))
	_pending_resolution_role = StringName(str(slot.get("pending_role", "")))
	_pending_role_awarded = bool(slot.get("pending_role_awarded", false))
	_pending_result.clear(); _pending_path.clear(); _next_hop_index = 0
	_boss_transition_pending = false; _last_error = ""
	var boss_entered := bool(state.get("boss_entered", false))
	_battle = null
	if boss_entered:
		var restored_battle: RefCounted = V06BossBattleScript.new()
		if not restored_battle.restore_snapshot(state.get("boss", {}) as Dictionary):
			return false
		_battle = restored_battle
		_travel = V06RollSetScript.new()
	else:
		_battle = null
		_travel = V06RollSetScript.new()
		if not _travel.restore_faces(face_values as Array):
			return false
	_phase = phase
	if phase in [PHASE_BOSS_ROLL_READY, PHASE_BOSS_ROUND_RESULT, PHASE_LAP_RESULT, PHASE_RUN_OVER] and _battle == null:
		return false
	if phase in [PHASE_READY, PHASE_CHOICE_REQUIRED] and _battle != null:
		return false
	_restore_clock(clock, now_ms)
	return true


func current_tile_kind() -> String:
	if not _course_ready: return ""
	var routes: Dictionary = _course.definition().get("routes", {})
	var route_id := str(_position.get("route_id", "")); var index := int(_position.get("tile_index", -1))
	if not routes.has(route_id) or index < 0 or index >= routes[route_id].size(): return ""
	var node_key := _position_key(_position)
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		var gate: Dictionary = _course.warp_gate_for_main_index(index)
		if not gate.is_empty() and _consumed_warp_gate_ids.has(str(gate.id)):
			return "NORMAL"
	if _consumed_reward_node_keys.has(node_key):
		return "NORMAL"
	return str(routes[route_id][index].get("kind", ""))


func stage_summary() -> Dictionary:
	return _course.stage_summary() if _course_ready else {}


func pending_bypass() -> Dictionary:
	return _course.bypass_for_fork(int(_position.get("tile_index", -1))) if _course_ready and _phase == PHASE_CHOICE_REQUIRED else {}


func steps_to_loop_exit() -> int: return _course.steps_to_exit(_position) if _course_ready else -1


func snapshot(now_ms: int = -1) -> Dictionary:
	var elapsed := elapsed_ms(now_ms)
	return {"stage_id":String(_stage_id), "character_id":String(_character_id), "position":position(), "visual_position":visual_position(), "phase":_phase, "faces":faces(),
		"pending_face":_pending_face, "pending_move_distance":_pending_move_distance, "pending_remaining_steps":_pending_remaining_steps, "pending_hops":pending_hop_count(),
		"resolution_role":_resolution_role, "boss_terminal":is_boss_terminal(), "boss_transition_pending":_boss_transition_pending,
		"can_roll":can_roll(), "tile_kind":current_tile_kind(), "steps_to_exit":steps_to_loop_exit(), "last_error":_last_error,
		"lap":_lap, "rolls_used":_roll_count, "player_hp":_player_hp, "boss":boss_snapshot(), "boss_result":boss_result(),
		"score":_score, "coins":_coins, "skill_gauge":_skill_gauge, "pending_resolution_role":_pending_resolution_role,
		"next_basic_move_penalty":next_basic_move_penalty(), "last_tile_effect":last_tile_effect_result(),
		"active_warp_gate_id":_active_warp_gate_id, "consumed_warp_gate_ids":consumed_warp_gate_ids(),
		"consumed_reward_node_keys":consumed_reward_node_keys(), "visited_node_keys":visited_node_keys(),
		"best_score":_best_score, "score_breakdown":score_breakdown(), "last_score_award":last_score_award(),
		"elapsed_ms":elapsed, "best_ms":_best_ms, "pb_delta_ms":pb_delta_ms(now_ms),
		"pb_updated":_pb_updated, "clock_armed":_clock_armed, "clock_running":_clock_running, "clock_paused":_clock_paused}


func _reset_run_state(keep_pb: bool) -> void:
	if not keep_pb:
		_best_ms = null
		_best_score = 0
	_lap = 1; _player_hp = MAX_PLAYER_HP; _roll_count = 0
	_reset_course_and_clock()


func _reset_course_and_clock() -> void:
	_travel = V06RollSetScript.new(); _battle = null
	_score = 0; _coins = 0; _skill_gauge = 0; _skill_state = SKILL_STATE_CHARGING; _score_event_serial = 0; _last_score_award.clear()
	_role_counts = {"MIX":0, "PAIR":0, "STRAIGHT":0, "TRIPLE":0}; _last_role = &""
	_inventory.clear(); _item_consumption.clear(); _stage_flags.clear()
	_score_breakdown = {"travel":0, "slot":0, "discovery":0, "boss":0, "finish":0}
	_position = {"route_id":"main", "tile_index":0}; _visual_position = _position.duplicate(true)
	_active_warp_gate_id = ""; _consumed_warp_gate_ids.clear(); _visited_node_keys.clear()
	_consumed_reward_node_keys.clear(); _awarded_score_event_ids.clear()
	_mark_position_visited(_position)
	_phase = PHASE_READY; _pending_face = 0; _pending_move_distance = 0; _pending_remaining_steps = 0; _pending_result.clear(); _pending_path.clear()
	_next_hop_index = 0; _resolution_role = &""; _pending_resolution_role = &""; _pending_role_awarded = false
	_boss_transition_pending = false; _last_error = ""
	_clock_armed = true; _clock_running = false; _clock_paused = false; _clock_start_ms = 0; _paused_total_ms = 0
	_pause_started_ms = 0; _clock_stop_ms = 0; _last_now_ms = -1; _pb_updated = false
	_pb_delta_ms = null


func _enter_boss_internal() -> void:
	_battle = V06BossBattleScript.new()
	var carried_faces: Array[int] = _travel.faces()
	var boss_flags := {"boss_ignore_first_sand": bool(_stage_flags.get("boss_ignore_first_sand", true))}
	if not _battle.configure_lap(_lap, _player_hp, carried_faces, boss_flags):
		_phase = PHASE_ERROR; _last_error = "BOSS_CONFIG_FAILED"; return
	_travel = V06RollSetScript.new()
	_resolution_role = &""; _pending_resolution_role = &""; _pending_role_awarded = false
	_boss_transition_pending = false; _phase = PHASE_BOSS_ROLL_READY


func _start_clock_if_armed(now_ms: int) -> void:
	if _clock_armed and now_ms >= 0:
		_clock_armed = false; _clock_running = true; _clock_start_ms = now_ms


func _stop_clock(now_ms: int) -> void:
	if not _clock_running: return
	_clock_stop_ms = now_ms if now_ms >= 0 else _last_now_ms
	if _clock_paused:
		_paused_total_ms += maxi(_clock_stop_ms - _pause_started_ms, 0)
	_clock_running = false; _clock_paused = false


func _update_pb() -> void:
	var value := elapsed_ms()
	var prior_best: Variant = _best_ms
	_pb_delta_ms = null if prior_best == null else value - int(prior_best)
	_pb_updated = prior_best == null or value < int(prior_best)
	if _pb_updated: _best_ms = value


func _update_best_score() -> void:
	_best_score = maxi(_best_score, _score)


func _add_score(amount: int, label: String, category: String) -> void:
	if amount <= 0:
		return
	_score += amount
	_score_event_serial += 1
	_score_breakdown[category] = int(_score_breakdown.get(category, 0)) + amount
	_last_score_award = {"amount":amount, "label":label, "category":category, "serial":_score_event_serial}


func _add_score_once(event_id: String, amount: int, label: String, category: String) -> bool:
	if event_id.is_empty() or _awarded_score_event_ids.has(event_id):
		return false
	_awarded_score_event_ids[event_id] = true
	_add_score(amount, label, category)
	return true


func _award_first_visit_steps(path: Array) -> void:
	for value: Variant in path:
		if not value is Dictionary:
			continue
		var route_position := value as Dictionary
		var key := _position_key(route_position)
		if _visited_node_keys.has(key):
			continue
		_visited_node_keys[key] = true
		_add_score_once("visit:%s" % key, SCORE_PER_STEP, "TRAVEL", "travel")


func _mark_position_visited(route_position: Dictionary) -> void:
	_visited_node_keys[_position_key(route_position)] = true


func _position_key(route_position: Dictionary) -> String:
	return "%s:%d" % [str(route_position.get("route_id", "")), int(route_position.get("tile_index", -1))]


func _course_context() -> Dictionary:
	return {
		"active_warp_gate_id":_active_warp_gate_id,
		"disabled_warp_gate_ids":consumed_warp_gate_ids(),
	}


func _award_landing_score(kind: String) -> void:
	var node_key := _position_key(_position)
	var awarded := false
	match kind:
		"COIN":
			awarded = _add_score_once("stop:%s:coin" % node_key, SCORE_COIN, "COIN", "travel")
		"REST":
			awarded = _add_score_once("stop:%s:rest" % node_key, SCORE_REST, "REST", "travel")
		"ITEM":
			awarded = _add_score_once("stop:%s:item" % node_key, SCORE_ITEM, "ITEM", "discovery")
		"EVENT":
			awarded = _add_score_once("stop:%s:event" % node_key, SCORE_EVENT, "EVENT", "discovery")
		"TREASURE":
			awarded = _add_score_once("stop:%s:treasure" % node_key, 1000, "TREASURE", "discovery")
		"BOSS_GATE":
			awarded = _add_score_once("stop:%s:boss_gate" % node_key, SCORE_BOSS_GATE, "BOSS GATE", "boss")
	if awarded and _course.is_loop_route(str(_position.get("route_id", ""))) and kind in ["ITEM", "EVENT", "TREASURE"]:
		_consumed_reward_node_keys[node_key] = true


func _resolve_landing_effect(kind: String) -> Dictionary:
	if kind not in ["COIN", "REST", "RISK"]:
		_stage_flags[STAGE_FLAG_LAST_TILE_EFFECT] = {}
		return {}
	var node_key := _position_key(_position)
	var resolution_id := "landing:%d:%s" % [_roll_count, node_key]
	var resolved_ids := _resolved_tile_effect_ids()
	if resolved_ids.has(resolution_id):
		return last_tile_effect_result()
	var effect: Dictionary = _course.effect_for_position(_position)
	var effect_kind := str(effect.get("kind", _default_effect_kind(kind)))
	var amount := maxi(int(effect.get("amount", _default_effect_amount(kind))), 0)
	var result := {
		"resolution_id": resolution_id,
		"node_key": node_key,
		"tile_kind": kind,
		"effect_kind": effect_kind,
		"amount": amount,
		"applied": false,
		"text": "",
	}
	if kind == "COIN":
		if not _consumed_reward_node_keys.has(node_key):
			_coins += amount
			_consumed_reward_node_keys[node_key] = true
			result.applied = true
			result.text = "COIN +%d" % amount
	elif kind == "REST":
		var before := _player_hp
		_player_hp = mini(_player_hp + amount, MAX_PLAYER_HP)
		result.applied = _player_hp != before
		result.text = "HP +%d" % (_player_hp - before) if result.applied else "HP FULL"
	elif kind == "RISK":
		match effect_kind:
			"coin_loss":
				var before := _coins
				_coins = maxi(_coins - amount, 0)
				result.applied = _coins != before
				result.text = "COIN -%d" % (before - _coins)
			"next_move":
				_stage_flags[STAGE_FLAG_NEXT_MOVE_PENALTY] = maxi(amount, 1)
				result.applied = true
				result.text = "NEXT MOVE -%d" % maxi(amount, 1)
			_:
				var before := _player_hp
				_player_hp = maxi(_player_hp - amount, 0)
				result.applied = _player_hp != before
				result.text = "DAMAGE -%d" % (before - _player_hp)
	resolved_ids[resolution_id] = true
	_stage_flags[STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS] = resolved_ids
	_stage_flags[STAGE_FLAG_LAST_TILE_EFFECT] = result.duplicate(true)
	return result


func _resolved_tile_effect_ids() -> Dictionary:
	var value: Variant = _stage_flags.get(STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _default_effect_kind(tile_kind: String) -> String:
	match tile_kind:
		"COIN": return "coin_gain"
		"REST": return "heal"
		_: return "hp_damage"


func _default_effect_amount(tile_kind: String) -> int:
	match tile_kind:
		"COIN": return DEFAULT_COIN_GAIN
		"REST": return DEFAULT_REST_HEAL
		_: return DEFAULT_RISK_AMOUNT


func _basic_move_distance(face: int) -> int:
	return maxi(face - next_basic_move_penalty(), 1)


func _consume_next_move_penalty() -> void:
	if next_basic_move_penalty() > 0:
		_stage_flags[STAGE_FLAG_NEXT_MOVE_PENALTY] = 0


func _award_route_completion_score(result: Dictionary) -> void:
	for value: Variant in result.get("transitions", []):
		if not value is Dictionary:
			continue
		var transition := value as Dictionary
		var from: Dictionary = transition.get("from", {})
		var to: Dictionary = transition.get("to", {})
		var from_route := str(from.get("route_id", ""))
		var to_route := str(to.get("route_id", ""))
		if _course.is_bypass_route(from_route) and to_route == V06CourseModelScript.ROUTE_MAIN:
			_add_score_once("bypass_clear:%s" % from_route, SCORE_BYPASS_CLEAR, "BYPASS", "travel")
		elif _course.is_loop_route(from_route) and to_route == V06CourseModelScript.ROUTE_MAIN:
			var gate_id := str(transition.get("gate_id", result.get("exited_warp_gate_id", "")))
			var loop: Dictionary = _course.loop_definition(from_route)
			var amount := int(loop.get("exit_score", SCORE_LOOP_EXIT))
			var label := "OASIS EXIT" if from_route == V06CourseModelScript.ROUTE_LOOP_OASIS else "TOMB EXIT"
			_add_score_once("loop_exit:%s" % gate_id, amount, label, "discovery")


func _award_finish_score() -> void:
	_add_score_once("finish:stage", SCORE_FINISH, "FINISH", "finish")
	_add_score_once("finish:hp", _player_hp * SCORE_FINISH_HP, "HP BONUS", "finish")
	if _player_hp >= 3:
		_add_score_once("finish:full_hp", SCORE_FINISH_FULL_HP, "FULL HP", "finish")


func _award_role_score(role: StringName) -> void:
	if role == &"":
		return
	_record_role(role)
	match role:
		V06RollSetScript.ROLE_TRIPLE:
			_skill_gauge = SKILL_GAUGE_MAX
			_add_score(SCORE_TRIPLE, "TRIPLE", "slot")
		V06RollSetScript.ROLE_PAIR:
			_skill_gauge = mini(_skill_gauge + 1, SKILL_GAUGE_MAX)
			_add_score(SCORE_PAIR, "PAIR", "slot")
		V06RollSetScript.ROLE_STRAIGHT:
			_skill_gauge = mini(_skill_gauge + 2, SKILL_GAUGE_MAX)
			_add_score(SCORE_STRAIGHT, "STRAIGHT", "slot")
		_:
			_coins += 1
			_add_score(SCORE_MIX, "MIX", "slot")
	_skill_state = SKILL_STATE_READY if _skill_gauge >= SKILL_GAUGE_MAX else SKILL_STATE_CHARGING


func _record_role(role: StringName) -> void:
	if role == &"":
		return
	var role_key := String(role)
	_role_counts[role_key] = int(_role_counts.get(role_key, 0)) + 1
	_last_role = role


func _prepare_pending_role_reward() -> void:
	_pending_resolution_role = &""
	_pending_role_awarded = false
	if _travel.faces().size() != V06RollSetScript.SLOT_COUNT - 1:
		return
	var preview: RefCounted = V06RollSetScript.new()
	for value: int in _travel.faces():
		if not preview.append_face(value):
			return
	if not preview.append_face(_pending_face):
		return
	_pending_resolution_role = preview.evaluate_role()
	if _pending_resolution_role == &"":
		return
	_award_role_score(_pending_resolution_role)
	_pending_role_awarded = true


func _accept_now(now_ms: int) -> bool:
	if now_ms < 0: return true # Compatibility for movement-only legacy callers.
	if _last_now_ms >= 0 and now_ms < _last_now_ms: return false
	_last_now_ms = now_ms
	return true


func _prepare_movement(result: Dictionary) -> void:
	_pending_result = result.duplicate(true); _pending_path.clear()
	for value: Variant in result.get("path", []):
		if value is Dictionary: _pending_path.append((value as Dictionary).duplicate(true))
	_next_hop_index = 0; _phase = PHASE_MOVING; _last_error = ""


func _event(ok: bool, status: String) -> Dictionary:
	var event := snapshot(); event["ok"] = ok; event["status"] = status; return event


func _rejected(error: String) -> Dictionary:
	var event := snapshot(); event["ok"] = false; event["status"] = error; event["error"] = error; return event


func _course_position_exists(route_id: String, tile_index: int) -> bool:
	if route_id.is_empty() or tile_index < 0:
		return false
	var routes: Dictionary = _course.definition().get("routes", {})
	return routes.has(route_id) and routes[route_id] is Array and tile_index < (routes[route_id] as Array).size()


func _string_keys(values: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for value: Variant in values.keys():
		keys.append(str(value))
	keys.sort()
	return keys


func _restore_string_set(target: Dictionary, values: Variant) -> void:
	target.clear()
	if not values is Array:
		return
	for value: Variant in values as Array:
		target[str(value)] = true


func _restore_clock(clock: Dictionary, now_ms: int) -> void:
	var restore_now := now_ms if now_ms >= 0 else 0
	var saved_elapsed := maxi(int(clock.get("elapsed_ms", 0)), 0)
	_clock_armed = bool(clock.get("armed", false))
	_clock_running = bool(clock.get("running", false)) and not _phase in [PHASE_LAP_RESULT, PHASE_RUN_OVER]
	_clock_paused = false
	_clock_start_ms = restore_now - saved_elapsed
	_paused_total_ms = 0
	_pause_started_ms = 0
	_clock_stop_ms = restore_now if not _clock_running else 0
	_last_now_ms = restore_now
	if _clock_armed:
		_clock_running = false
		_clock_start_ms = 0
		_clock_stop_ms = 0
	elif not _clock_running:
		_clock_stop_ms = restore_now
