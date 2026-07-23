class_name V06PlaySession
extends RefCounted

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const V06BossBattleScript = preload("res://scripts/game/v06_boss_battle.gd")
const COURSE_PATH := "res://data/stages/v06_cairo_course.json"

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

var _course: RefCounted
var _travel: RefCounted
var _battle: RefCounted
var _course_ready := false
var _position: Dictionary = {"route_id":"main", "tile_index":0}
var _visual_position: Dictionary = {"route_id":"main", "tile_index":0}
var _phase: StringName = PHASE_READY
var _pending_face := 0
var _pending_remaining_steps := 0
var _pending_result: Dictionary = {}
var _pending_path: Array[Dictionary] = []
var _next_hop_index := 0
var _resolution_role: StringName = &""
var _boss_transition_pending := false
var _last_error := ""
var _lap := 1
var _player_hp := 3

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


func _init() -> void:
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
		if str(boss_event.get("status", "")) == "ROUND_RESOLVED":
			_phase = PHASE_BOSS_ROUND_RESULT
			var result: Dictionary = _battle.result()
			_player_hp = int(result.get("player_hp_after", _player_hp))
			if bool(result.get("victory", false)) or bool(result.get("defeat", false)):
				_stop_clock(now_ms)
				if bool(result.get("victory", false)):
					_update_pb()
		return _event(true, str(boss_event.get("status", "FACE_ACCEPTED")))
	if not _course_ready:
		return _rejected("INVALID_COURSE_DATA")
	if _phase != PHASE_READY:
		return _rejected("ROLL_NOT_AVAILABLE")
	if not _accept_now(now_ms):
		return _rejected("TIMESTAMP_REGRESSION")
	_start_clock_if_armed(now_ms)
	_pending_face = face
	var result: Dictionary = _course.advance(_position, face)
	if not bool(result.get("ok", false)) and str(result.get("error", "")) != "CHOICE_REQUIRED":
		_pending_face = 0
		_last_error = str(result.get("error", "COURSE_ADVANCE_FAILED"))
		return _rejected(_last_error)
	_prepare_movement(result)
	return _event(true, "MOVEMENT_STARTED")


func has_pending_hops() -> bool:
	return _phase == PHASE_MOVING and _next_hop_index < _pending_path.size()


func pending_hop_count() -> int:
	return maxi(_pending_path.size() - _next_hop_index, 0) if _phase == PHASE_MOVING else 0


func next_hop() -> Dictionary:
	if not has_pending_hops(): return {}
	var hop: Dictionary = _pending_path[_next_hop_index].duplicate(true)
	_next_hop_index += 1
	_visual_position = hop.duplicate(true)
	return hop


func finish_movement() -> Dictionary:
	if _phase != PHASE_MOVING: return _rejected("MOVEMENT_NOT_ACTIVE")
	if has_pending_hops(): return _rejected("HOPS_REMAIN")
	var result := _pending_result.duplicate(true)
	_position = (result.get("position", _position) as Dictionary).duplicate(true)
	_visual_position = _position.duplicate(true)
	_pending_result.clear(); _pending_path.clear(); _next_hop_index = 0
	if not bool(result.get("ok", false)):
		if str(result.get("error", "")) == "CHOICE_REQUIRED":
			_pending_remaining_steps = int(result.get("remaining_steps", 0)); _phase = PHASE_CHOICE_REQUIRED
			return _event(true, "CHOICE_REQUIRED")
		_pending_face = 0; _pending_remaining_steps = 0; _phase = PHASE_READY
		return _rejected(str(result.get("error", "COURSE_ADVANCE_FAILED")))
	if not _travel.append_face(_pending_face):
		_phase = PHASE_ERROR
		return _rejected("FACE_COMMIT_FAILED")
	_pending_face = 0; _pending_remaining_steps = 0
	_resolution_role = _travel.evaluate_role()
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
	if route_id != V06CourseModelScript.ROUTE_MAIN and route_id != V06CourseModelScript.ROUTE_BYPASS:
		return _rejected("INVALID_ROUTE_CHOICE")
	var result: Dictionary = _course.advance(_position, _pending_remaining_steps, route_id)
	if not bool(result.get("ok", false)): return _rejected(str(result.get("error", "COURSE_ADVANCE_FAILED")))
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
	if bool(result.get("victory", false)): _phase = PHASE_LAP_RESULT
	elif bool(result.get("defeat", false)): _phase = PHASE_RUN_OVER
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
func pending_face() -> int: return _pending_face
func pending_remaining_steps() -> int: return _pending_remaining_steps
func is_boss_terminal() -> bool: return _phase in [PHASE_LAP_RESULT, PHASE_RUN_OVER]
func can_roll() -> bool: return _phase in [PHASE_READY, PHASE_BOSS_ROLL_READY]
func lap() -> int: return _lap
func player_hp() -> int: return _player_hp
func best_ms() -> Variant: return _best_ms
func pb_delta_ms(now_ms: int = -1) -> Variant:
	if _clock_armed or _best_ms == null: return null
	if not _clock_running: return _pb_delta_ms
	return elapsed_ms(now_ms) - int(_best_ms)
func boss_snapshot() -> Dictionary: return _battle.snapshot() if _battle != null else {}
func boss_result() -> Dictionary: return _battle.result() if _battle != null else {}


func current_tile_kind() -> String:
	if not _course_ready: return ""
	var routes: Dictionary = _course.definition().get("routes", {})
	var route_id := str(_position.get("route_id", "")); var index := int(_position.get("tile_index", -1))
	if not routes.has(route_id) or index < 0 or index >= routes[route_id].size(): return ""
	return str(routes[route_id][index].get("kind", ""))


func stage_summary() -> Dictionary:
	return _course.stage_summary() if _course_ready else {}


func steps_to_loop_exit() -> int: return _course.steps_to_exit(_position) if _course_ready else -1


func snapshot(now_ms: int = -1) -> Dictionary:
	var elapsed := elapsed_ms(now_ms)
	return {"position":position(), "visual_position":visual_position(), "phase":_phase, "faces":faces(),
		"pending_face":_pending_face, "pending_remaining_steps":_pending_remaining_steps, "pending_hops":pending_hop_count(),
		"resolution_role":_resolution_role, "boss_terminal":is_boss_terminal(), "boss_transition_pending":_boss_transition_pending,
		"can_roll":can_roll(), "tile_kind":current_tile_kind(), "steps_to_exit":steps_to_loop_exit(), "last_error":_last_error,
		"lap":_lap, "player_hp":_player_hp, "boss":boss_snapshot(), "boss_result":boss_result(),
		"elapsed_ms":elapsed, "best_ms":_best_ms, "pb_delta_ms":pb_delta_ms(now_ms),
		"pb_updated":_pb_updated, "clock_armed":_clock_armed, "clock_running":_clock_running, "clock_paused":_clock_paused}


func _reset_run_state(keep_pb: bool) -> void:
	if not keep_pb: _best_ms = null
	_lap = 1; _player_hp = 3
	_reset_course_and_clock()


func _reset_course_and_clock() -> void:
	_travel = V06RollSetScript.new(); _battle = null
	_position = {"route_id":"main", "tile_index":0}; _visual_position = _position.duplicate(true)
	_phase = PHASE_READY; _pending_face = 0; _pending_remaining_steps = 0; _pending_result.clear(); _pending_path.clear()
	_next_hop_index = 0; _resolution_role = &""; _boss_transition_pending = false; _last_error = ""
	_clock_armed = true; _clock_running = false; _clock_paused = false; _clock_start_ms = 0; _paused_total_ms = 0
	_pause_started_ms = 0; _clock_stop_ms = 0; _last_now_ms = -1; _pb_updated = false
	_pb_delta_ms = null


func _enter_boss_internal() -> void:
	_battle = V06BossBattleScript.new()
	if not _battle.configure_lap(_lap, _player_hp):
		_phase = PHASE_ERROR; _last_error = "BOSS_CONFIG_FAILED"; return
	_travel = V06RollSetScript.new()
	_resolution_role = &""; _boss_transition_pending = false; _phase = PHASE_BOSS_ROLL_READY


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
