class_name V06PlaySession
extends RefCounted

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const V06BossBattleScript = preload("res://scripts/game/v06_boss_battle.gd")
const HeartRouletteModelScript = preload("res://scripts/game/heart_roulette_model.gd")
const RestEffectModelScript = preload("res://scripts/game/rest_effect_model.gd")
const COURSE_PATH := "res://data/stages/v06_cairo_course.json"
const DEFAULT_STAGE_ID: StringName = &"cairo_hourglass"
const DEFAULT_CHARACTER_ID: StringName = &"relaxed"

const PHASE_READY: StringName = &"READY"
const PHASE_MOVING: StringName = &"MOVING"
const PHASE_CHOICE_REQUIRED: StringName = &"CHOICE_REQUIRED"
const PHASE_RESOLUTION_REQUIRED: StringName = &"RESOLUTION_REQUIRED"
const PHASE_EVENT_REQUIRED: StringName = &"EVENT_REQUIRED"
const PHASE_BOSS_ROLL_READY: StringName = &"BOSS_ROLL_READY"
const PHASE_BOSS_ROUND_RESULT: StringName = &"BOSS_ROUND_RESULT"
const PHASE_BOSS_FINISHED: StringName = &"FINISHED"
const PHASE_FINISHED: StringName = PHASE_BOSS_FINISHED # Public shorthand for boss-race QA.
const PHASE_LAP_RESULT: StringName = &"LAP_RESULT"
const PHASE_RUN_OVER: StringName = &"RUN_OVER"
const PHASE_BOSS_GATE: StringName = PHASE_BOSS_ROLL_READY # Compatibility only.
const PHASE_ERROR: StringName = &"ERROR"
const SCORE_PER_STEP := 1
const SKILL_GAUGE_MAX := 3
const SKILL_STATE_CHARGING: StringName = &"CHARGING"
const SKILL_STATE_READY: StringName = &"READY"
const SKILL_STATE_ARMED: StringName = &"ARMED"
const SAVE_STABLE_PHASES := [PHASE_READY, PHASE_CHOICE_REQUIRED, PHASE_RESOLUTION_REQUIRED, PHASE_EVENT_REQUIRED, PHASE_BOSS_ROLL_READY, PHASE_BOSS_ROUND_RESULT, PHASE_BOSS_FINISHED, PHASE_LAP_RESULT, PHASE_RUN_OVER]
const START_PLAYER_HP := 3
const MAX_PLAYER_HP := 3
const MAX_LIFE := 3
# 3 is the FULL segment; the other values are direct HP recovery amounts.
const HEART_ROULETTE_VALUES: Array[int] = HeartRouletteModelScript.VALUES
const DEFAULT_COIN_GAIN := 2
const DEFAULT_REST_HEAL := 1
const DEFAULT_RISK_AMOUNT := 1
const STAGE_FLAG_NEXT_MOVE_PENALTY := "v06_next_basic_move_penalty"
const STAGE_FLAG_LAST_TILE_EFFECT := "v06_last_tile_effect"
const STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS := "v06_resolved_tile_effect_ids"
const STAGE_FLAG_SEEN_TILE_EXPLANATIONS := "v06_seen_tile_explanations"
const STAGE_FLAG_THREE_ROLL_ONBOARDING_SEEN := "v06_three_roll_onboarding_seen"
const STAGE_FLAG_SEEN_EVENT_IDS := "v06_seen_event_ids"
const STAGE_FLAG_ACTIVE_LOOP_WRAPS := "v06_active_loop_wraps"
const STAGE_FLAG_NEXT_MOVE_BONUS := "v06_next_move_bonus"
const STAGE_FLAG_RISK_SHIELD := "v06_risk_shield"
const STAGE_FLAG_PINPOINT_FACE := "v06_pinpoint_face"
const TILE_EXPLANATION_KINDS := ["EVENT", "ITEM", "COIN", "REST", "RISK", "WARP"]
const ITEM_CAPACITY := 3
const ITEM_WATER_CANTEEN := "water_canteen"
const ITEM_BRASS_COMPASS := "brass_compass"
const ITEM_SCARAB_SEAL := "scarab_seal"
const ITEM_IDS := [ITEM_WATER_CANTEEN, ITEM_BRASS_COMPASS, ITEM_SCARAB_SEAL]
const MISSION_SCHEMA_VERSION := 2
const MISSION_COIN_TARGET := 12
const MISSION_ROLE_TARGET := 5
const COIN_COST_RISK_INSURANCE := 2
const COIN_COST_REST_BOOST := 2
const COIN_COST_BOSS_SHIELD := 3
const COIN_COST_BOSS_HEAD_START := 4
const COIN_COST_BOSS_SABOTAGE := 5
const COIN_COST_EMERGENCY_REVIVE := 5
const STAGE_FLAG_NEXT_REST_BOOST := "v06_next_rest_boost"
const STAGE_FLAG_BOSS_SHIELD := "v06_boss_support_shield"
const STAGE_FLAG_BOSS_HEAD_START := "v06_boss_support_head_start"
const STAGE_FLAG_BOSS_SABOTAGE := "v06_boss_support_sabotage"
const STAGE_FLAG_SEEN_SURVIVAL_ONBOARDING := "v06_survival_onboarding_seen"
const STAGE_FLAG_SKILL_READY_DISCOVERY_SEEN := "v06_skill_ready_discovery_seen"
const STAGE_FLAG_EMERGENCY_REVIVE_USED := "v06_emergency_revive_used"

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
var _boss_finish_recorded := false
var _active_warp_gate_id := ""
var _consumed_warp_gate_ids := {}
var _visited_node_keys := {}
var _consumed_reward_node_keys := {}
var _awarded_score_event_ids := {}
var _last_error := ""
var _lap := 1
var _player_hp := START_PLAYER_HP
var _player_max_hp := START_PLAYER_HP
var _life := MAX_LIFE
var _roll_count := 0
var _score := 0
var _lap_score := 0
var _coins := 0
var _skill_gauge := 0
var _skill_state: StringName = SKILL_STATE_CHARGING
var _role_counts: Dictionary = {"MIX":0, "PAIR":0, "STRAIGHT":0, "TRIPLE":0}
var _last_role: StringName = &""
var _inventory: Dictionary = {}
var _item_consumption: Dictionary = {}
var _stage_flags: Dictionary = {}
var _active_event: Dictionary = {}
var _best_score := 0
var _score_event_serial := 0
var _last_score_award: Dictionary = {}
var _score_breakdown: Dictionary = {}
var _mission_coin_gained := 0
var _mission_role_successes := 0
var _mission_no_damage_active := true
var _mission_no_damage_completed := false
var _mission_coin_completed := false
var _mission_role_completed := false
var _mission_event_serial := 0
var _last_mission_event: Dictionary = {}
var _mission_ranks: Dictionary = {}
var _mission_active_ids: Array[String] = ["cairo_coin15", "cairo_triple2", "cairo_no_damage"]
var _mission_ring_exits := 0
var _last_loop_rescue_triggered := false
var _last_coin_cashout := 0
var _heart_roulette_pending := false
var _heart_roulette_resolved := false
var _heart_roulette_slot_index := -1
var _heart_roulette_result: Dictionary = {}

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
	var seen_tile_explanations := seen_tile_explanation_kinds()
	var onboarding_seen := has_seen_three_roll_onboarding()
	var survival_seen := has_seen_survival_onboarding()
	var skill_ready_seen := has_seen_skill_ready_discovery()
	var seen_event_ids := _seen_event_ids()
	_reset_run_state(true)
	_restore_seen_tile_explanations(seen_tile_explanations)
	_stage_flags[STAGE_FLAG_SEEN_EVENT_IDS] = seen_event_ids
	if onboarding_seen:
		mark_three_roll_onboarding_seen()
	if survival_seen:
		mark_survival_onboarding_seen()
	if skill_ready_seen:
		mark_skill_ready_discovery_seen()
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
			var result: Dictionary = _battle.result()
			var terminal_result := bool(result.get("victory", false)) or bool(result.get("defeat", false))
			_phase = PHASE_BOSS_FINISHED if terminal_result else PHASE_BOSS_ROUND_RESULT
			var boss_role := StringName(str(result.get("role", "")))
			if boss_role != &"":
				_award_role_score(boss_role)
			var hp_before := _player_hp
			# The mirror race changes position, not travel hearts. Preserve every
			# heart earned above the race model's legacy three-heart display cap.
			_player_hp = hp_before
			if _player_hp < hp_before:
				_fail_no_damage_mission()
			if terminal_result and not _boss_finish_recorded:
				_boss_finish_recorded = true
				_stop_clock(now_ms)
				_update_pb()
				if bool(result.get("victory", false)):
					_complete_no_damage_mission()
					_heart_roulette_pending = _player_hp < MAX_PLAYER_HP
					_heart_roulette_resolved = false
					_heart_roulette_slot_index = -1
					_heart_roulette_result.clear()
				else:
					_heart_roulette_pending = false
					_heart_roulette_resolved = false
					_heart_roulette_slot_index = -1
					_heart_roulette_result.clear()
		_roll_count += 1
		return _event(true, str(boss_event.get("status", "FACE_ACCEPTED")))
	if not _course_ready:
		return _rejected("INVALID_COURSE_DATA")
	if _phase != PHASE_READY:
		return _rejected("ROLL_NOT_AVAILABLE")
	if not _accept_now(now_ms):
		return _rejected("TIMESTAMP_REGRESSION")
	_start_clock_if_armed(now_ms)
	_last_loop_rescue_triggered = false
	_pending_face = face
	_pending_move_distance = _basic_move_distance(face)
	var result: Dictionary = _course.advance(_position, _pending_move_distance, "", _course_context())
	if not bool(result.get("ok", false)) and str(result.get("error", "")) != "CHOICE_REQUIRED":
		_pending_face = 0
		_pending_move_distance = 0
		_last_error = str(result.get("error", "COURSE_ADVANCE_FAILED"))
		return _rejected(_last_error)
	_consume_next_move_penalty()
	_consume_next_move_bonus()
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
	_award_travelled_steps(movement_path)
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
	var movement_wraps := maxi(int(result.get("loop_wraps", 0)), 0)
	if movement_wraps > 0:
		_stage_flags[STAGE_FLAG_ACTIVE_LOOP_WRAPS] = loop_wrap_count() + movement_wraps
	if not entered_gate_id.is_empty():
		_stage_flags[STAGE_FLAG_ACTIVE_LOOP_WRAPS] = 0
		_active_warp_gate_id = entered_gate_id
		_consumed_warp_gate_ids[entered_gate_id] = true
		_mark_position_visited(_position)
	elif not exited_gate_id.is_empty():
		_last_loop_rescue_triggered = bool(result.get("forced_loop_exit", false))
		_mark_position_visited(_position)
	var landing_kind := current_tile_kind()
	if not exited_gate_id.is_empty() and landing_kind == "RISK":
		_stage_flags[STAGE_FLAG_LAST_TILE_EFFECT] = {
			"resolution_id":"loop_return:%d:%s" % [_roll_count, _position_key(_position)],
			"node_key":_position_key(_position),
			"tile_kind":"RISK", "effect_kind":"return_safe", "amount":0,
			"applied":false, "guarded":true, "loop_return_safe":true,
			"text":"本線復帰　RISKは発動しない",
		}
	else:
		_resolve_landing_effect(landing_kind)
	var landing_score_awarded := false
	if not exited_gate_id.is_empty():
		_active_warp_gate_id = ""
		_stage_flags[STAGE_FLAG_ACTIVE_LOOP_WRAPS] = 0
	if _travel.is_complete() and not _pending_role_awarded:
		_award_role_score(_resolution_role)
	_pending_resolution_role = &""
	_pending_role_awarded = false
	var gate := bool(result.get("boss_gate_reached", false))
	_boss_transition_pending = gate and _travel.is_complete()
	var return_phase: StringName = PHASE_RESOLUTION_REQUIRED if _boss_transition_pending or (_travel.is_complete() and not gate) else PHASE_READY
	if landing_kind == "EVENT" and _prepare_active_event(return_phase, landing_score_awarded):
		_phase = PHASE_EVENT_REQUIRED
	elif return_phase == PHASE_RESOLUTION_REQUIRED:
		_phase = PHASE_RESOLUTION_REQUIRED
	elif gate and _player_hp > 0:
		_enter_boss_internal()
	else:
		_phase = PHASE_READY
	_normalize_hp_zero_after_stable_boundary()
	return _event(true, "BOSS_GATE_REACHED" if gate else "ROLL_COMMITTED")


func choose_route(route_id: String) -> Dictionary:
	if _phase != PHASE_CHOICE_REQUIRED: return _rejected("CHOICE_NOT_AVAILABLE")
	var bypass: Dictionary = _course.bypass_for_fork(int(_position.get("tile_index", -1)))
	if bypass.is_empty() or (route_id != V06CourseModelScript.ROUTE_MAIN and route_id != str(bypass.route_id)):
		return _rejected("INVALID_ROUTE_CHOICE")
	var result: Dictionary = _course.advance(_position, _pending_remaining_steps, route_id, _course_context())
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
		if _player_hp > 0: _enter_boss_internal()
		else: _enter_run_over()
	else: _phase = PHASE_READY
	_normalize_hp_zero_after_stable_boundary()
	return true


func active_event() -> Dictionary: return _active_event.duplicate(true)


func acknowledge_event() -> bool:
	if _phase != PHASE_EVENT_REQUIRED or _active_event.is_empty(): return false
	var event_id := str(_active_event.get("event_id", ""))
	var return_phase := StringName(str(_active_event.get("return_phase", "")))
	var seen := _seen_event_ids()
	seen[event_id] = true
	_stage_flags[STAGE_FLAG_SEEN_EVENT_IDS] = seen
	_active_event.clear()
	_phase = return_phase
	_normalize_hp_zero_after_stable_boundary()
	return true


func acknowledge_boss_round() -> bool:
	# Compatibility for older callers that acknowledged the hidden result button.
	# The live boss UI never exposes this path for FINISHED; it uses Next Lap.
	if _phase == PHASE_BOSS_FINISHED:
		_phase = PHASE_LAP_RESULT
		return true
	if _phase != PHASE_BOSS_ROUND_RESULT: return false
	var result: Dictionary = _battle.result()
	if not _battle.acknowledge_round(): return false
	if bool(result.get("victory", false)) or bool(result.get("defeat", false)): _phase = PHASE_LAP_RESULT
	else: _phase = PHASE_BOSS_ROLL_READY
	return true


func next_lap() -> bool:
	if _phase not in [PHASE_BOSS_FINISHED, PHASE_LAP_RESULT]: return false
	# Compatibility callers may skip the presentation button. Never discard a
	# victory reward; use the first +1 segment as the safe deterministic fallback.
	if _heart_roulette_pending:
		resolve_heart_roulette(0)
	var seen_tile_explanations := seen_tile_explanation_kinds()
	var onboarding_seen := has_seen_three_roll_onboarding()
	var survival_seen := has_seen_survival_onboarding()
	var skill_ready_seen := has_seen_skill_ready_discovery()
	var seen_event_ids := _seen_event_ids()
	_lap += 1
	if (_lap - 1) % 10 == 0:
		_life = mini(_life + 1, MAX_LIFE)
	var monotonic_floor := _last_now_ms
	_reset_course_and_clock(false)
	_restore_seen_tile_explanations(seen_tile_explanations)
	_stage_flags[STAGE_FLAG_SEEN_EVENT_IDS] = seen_event_ids
	if onboarding_seen:
		mark_three_roll_onboarding_seen()
	if survival_seen:
		mark_survival_onboarding_seen()
	if skill_ready_seen:
		mark_skill_ready_discovery_seen()
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
func is_boss_terminal() -> bool: return _phase in [PHASE_BOSS_FINISHED, PHASE_LAP_RESULT, PHASE_RUN_OVER]
func can_roll() -> bool: return _phase in [PHASE_READY, PHASE_BOSS_ROLL_READY]
func lap() -> int: return _lap
func roll_count() -> int: return _roll_count
func player_hp() -> int: return _player_hp
func player_max_hp() -> int: return _player_max_hp
func life() -> int: return _life
func score() -> int: return _score
func lap_score() -> int: return _lap_score
func lap_multiplier_numerator() -> int: return 4
func coins() -> int: return _coins
func last_coin_cashout() -> int: return _last_coin_cashout
func heart_roulette_options() -> Array[int]: return HEART_ROULETTE_VALUES.duplicate()
func heart_roulette_pending() -> bool: return _heart_roulette_pending
func heart_roulette_result() -> Dictionary: return _heart_roulette_result.duplicate(true)
func heart_roulette_state() -> Dictionary:
	return {
		"pending": _heart_roulette_pending,
		"resolved": _heart_roulette_resolved,
		"slot_index": _heart_roulette_slot_index,
		"result": _heart_roulette_result.duplicate(true),
	}

func resolve_heart_roulette(slot_index: int) -> Dictionary:
	if _phase not in [PHASE_BOSS_FINISHED, PHASE_LAP_RESULT] or not _heart_roulette_pending:
		return _rejected("HEART_ROULETTE_NOT_AVAILABLE")
	if slot_index < 0 or slot_index >= HEART_ROULETTE_VALUES.size():
		return _rejected("INVALID_HEART_ROULETTE_SLOT")
	var shared_result: Dictionary = HeartRouletteModelScript.resolve(_player_hp, _player_max_hp, slot_index)
	var rolled_delta: int = int(shared_result.get("rolled_value", HEART_ROULETTE_VALUES[slot_index]))
	var max_before := _player_max_hp
	var hp_before := _player_hp
	_player_hp = int(shared_result.get("after_hp", _player_hp))
	var heal_gain := _player_hp - hp_before
	var label := "♥ %s" % str(shared_result.get("label", "+%d" % heal_gain))
	_heart_roulette_pending = false
	_heart_roulette_resolved = true
	_heart_roulette_slot_index = slot_index
	_heart_roulette_result = {
		"slot_index": slot_index,
		"delta": rolled_delta,
		"max_before": max_before,
		"max_after": _player_max_hp,
		"hp_before": hp_before,
		"hp_after": _player_hp,
		"max_gain": 0,
		"heal_gain": heal_gain,
		"label": label,
	}
	return {"ok":true, "status":"HEART_ROULETTE_RESOLVED", "result":_heart_roulette_result.duplicate(true)}

func skill_gauge() -> int: return _skill_gauge
func skill_state() -> StringName: return _skill_state
func pinpoint_face() -> int: return clampi(int(_stage_flags.get(STAGE_FLAG_PINPOINT_FACE, 0)), 0, 6)
func role_counts() -> Dictionary: return _role_counts.duplicate(true)
func mission_state() -> Dictionary:
	return {
		"schema_version": MISSION_SCHEMA_VERSION,
		"coin_gained": _mission_coin_gained,
		"coin_target": MISSION_COIN_TARGET,
		"coin_completed": _mission_coin_completed,
		"role_successes": _mission_role_successes,
		"role_target": MISSION_ROLE_TARGET,
		"role_completed": _mission_role_completed,
		"no_damage_active": _mission_no_damage_active,
		"no_damage_completed": _mission_no_damage_completed,
		"event_serial": _mission_event_serial,
		"last_event": _last_mission_event.duplicate(true),
		"catalog": mission_catalog(),
		"active_ids": _mission_active_ids.duplicate(),
		"ranks": _mission_ranks.duplicate(true),
		"ring_exits": _mission_ring_exits,
	}

func mission_catalog() -> Array[Dictionary]:
	return [
		{"id":"cairo_coin15","pillar":"travel","target":MISSION_COIN_TARGET,"ranks":{"bronze":6,"silver":12,"gold":18}},
		{"id":"cairo_triple2","pillar":"slot","target":MISSION_ROLE_TARGET,"roles":["PAIR","STRAIGHT","TRIPLE"],"ranks":{"bronze":1,"silver":2,"gold":3}},
		{"id":"cairo_no_damage","pillar":"challenge","target":1,"ranks":{"bronze":1}},
		{"id":"cairo_no_item","pillar":"travel","target":1,"locked":true,"ranks":{"bronze":1}},
		{"id":"cairo_time_trial","pillar":"challenge","target":20,"thresholds":[30,25,20],"ranks":{"bronze":30,"silver":25,"gold":20}},
		{"id":"cairo_ring_exit2","pillar":"travel","target":2,"ranks":{"bronze":2}},
	]

func resolve_active_missions() -> Array[String]:
	var by_pillar := {"travel":"", "slot":"", "challenge":""}
	for id in _mission_active_ids:
		for entry in mission_catalog():
			if str(entry.get("id")) == id:
				var pillar := str(entry.get("pillar", ""))
				if by_pillar.has(pillar) and str(by_pillar[pillar]).is_empty(): by_pillar[pillar] = id
	var result: Array[String] = []
	for pillar in ["travel", "slot", "challenge"]:
		if not str(by_pillar[pillar]).is_empty(): result.append(str(by_pillar[pillar]))
	return result
func last_role() -> StringName: return _last_role
func inventory() -> Dictionary: return _inventory.duplicate(true)
func seen_event_ids() -> Array[String]:
	var result: Array[String] = []
	for raw_event_id: Variant in _seen_event_ids().keys():
		result.append(str(raw_event_id))
	return result
func item_consumption() -> Dictionary: return _item_consumption.duplicate(true)
func inventory_total() -> int:
	var total := 0
	for quantity: Variant in _inventory.values():
		total += maxi(int(quantity), 0)
	return total

func item_catalog() -> Array[Dictionary]:
	return [
		{"id":ITEM_WATER_CANTEEN,"name":"旅人の水筒","effect_text":"♥ +1","description":"♥ +1","art_index":5},
		{"id":ITEM_BRASS_COMPASS,"name":"真鍮のコンパス","effect_text":"DICE +1","description":"DICE +1","art_index":0},
		{"id":ITEM_SCARAB_SEAL,"name":"スカラベの護符","effect_text":"RISK ×0","description":"RISK ×0","art_index":4},
	]

func inventory_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for definition: Dictionary in item_catalog():
		var amount := maxi(int(_inventory.get(str(definition.id), 0)), 0)
		if amount <= 0:
			continue
		var entry := definition.duplicate(true)
		entry["amount"] = amount
		entries.append(entry)
	return entries

func use_item(item_id: String) -> Dictionary:
	if _phase != PHASE_READY:
		return _rejected("ITEM_NOT_AVAILABLE")
	if int(_inventory.get(item_id, 0)) <= 0:
		return _rejected("ITEM_NOT_OWNED")
	var result := {"ok":false,"item_id":item_id,"text":""}
	match item_id:
		ITEM_WATER_CANTEEN:
			if _player_hp >= _player_max_hp:
				return _rejected("HP_FULL")
			_player_hp = mini(_player_hp + 1, _player_max_hp)
			result.text = "HP +1"
		ITEM_BRASS_COMPASS:
			if int(_stage_flags.get(STAGE_FLAG_NEXT_MOVE_BONUS, 0)) > 0:
				return _rejected("COMPASS_ALREADY_ACTIVE")
			_stage_flags[STAGE_FLAG_NEXT_MOVE_BONUS] = 1
			result.text = "NEXT MOVE +1"
		ITEM_SCARAB_SEAL:
			if bool(_stage_flags.get(STAGE_FLAG_RISK_SHIELD, false)):
				return _rejected("SCARAB_ALREADY_ACTIVE")
			_stage_flags[STAGE_FLAG_RISK_SHIELD] = true
			result.text = "RISK GUARD"
		_:
			return _rejected("UNKNOWN_ITEM")
	_inventory[item_id] = int(_inventory.get(item_id, 0)) - 1
	if int(_inventory[item_id]) <= 0:
		_inventory.erase(item_id)
	_item_consumption[item_id] = int(_item_consumption.get(item_id, 0)) + 1
	result.ok = true
	return result

func coin_action_catalog() -> Array[Dictionary]:
	return [
		{"id":"risk_insurance", "name":"RISKガード", "cost":COIN_COST_RISK_INSURANCE, "effect_text":"RISK ×0", "description":"RISK ×0", "active":bool(_stage_flags.get(STAGE_FLAG_RISK_SHIELD, false))},
		{"id":"rest_boost", "name":"ハート強化", "cost":COIN_COST_REST_BOOST, "effect_text":"♥ +2", "description":"♥ +2", "active":bool(_stage_flags.get(STAGE_FLAG_NEXT_REST_BOOST, false))},
		{"id":"boss_shield", "name":"ボスの盾", "cost":COIN_COST_BOSS_SHIELD, "effect_text":"BOSS ÷2", "description":"BOSS ÷2", "active":bool(_stage_flags.get(STAGE_FLAG_BOSS_SHIELD, false))},
		{"id":"boss_head_start", "name":"先行スタート", "cost":COIN_COST_BOSS_HEAD_START, "effect_text":"START +3", "description":"START +3", "active":bool(_stage_flags.get(STAGE_FLAG_BOSS_HEAD_START, false))},
		{"id":"boss_sabotage", "name":"ボスを止める", "cost":COIN_COST_BOSS_SABOTAGE, "effect_text":"BOSS STOP ×1", "description":"BOSS STOP ×1", "active":bool(_stage_flags.get(STAGE_FLAG_BOSS_SABOTAGE, false))},
	]

func purchase_coin_action(action_id: String) -> Dictionary:
	var buying_at_boss_start: bool = _phase == PHASE_BOSS_ROLL_READY and _battle != null and _battle.snapshot().get("player_roll_history", []).is_empty()
	if _phase != PHASE_READY and not buying_at_boss_start:
		return _rejected("COIN_ACTION_NOT_AVAILABLE")
	var flag := ""
	var cost := 0
	match action_id:
		"risk_insurance": flag = STAGE_FLAG_RISK_SHIELD; cost = COIN_COST_RISK_INSURANCE
		"rest_boost": flag = STAGE_FLAG_NEXT_REST_BOOST; cost = COIN_COST_REST_BOOST
		"boss_shield": flag = STAGE_FLAG_BOSS_SHIELD; cost = COIN_COST_BOSS_SHIELD
		"boss_head_start": flag = STAGE_FLAG_BOSS_HEAD_START; cost = COIN_COST_BOSS_HEAD_START
		"boss_sabotage": flag = STAGE_FLAG_BOSS_SABOTAGE; cost = COIN_COST_BOSS_SABOTAGE
		_: return _rejected("UNKNOWN_COIN_ACTION")
	if buying_at_boss_start and not action_id.begins_with("boss_"):
		return _rejected("COIN_ACTION_NOT_AVAILABLE")
	if bool(_stage_flags.get(flag, false)):
		return _rejected("COIN_ACTION_ALREADY_ACTIVE")
	if _coins < cost:
		return _rejected("NOT_ENOUGH_COINS")
	_coins -= cost
	_stage_flags[flag] = true
	if buying_at_boss_start and not _battle.apply_pre_race_support(action_id):
		_coins += cost
		_stage_flags.erase(flag)
		return _rejected("BOSS_SUPPORT_TOO_LATE")
	return {"ok":true, "status":"COIN_ACTION_PURCHASED", "action_id":action_id, "cost":cost, "coins":_coins}

func purchase_event_option() -> Dictionary:
	if _phase != PHASE_EVENT_REQUIRED or _active_event.is_empty():
		return _rejected("EVENT_OPTION_NOT_AVAILABLE")
	if bool(_active_event.get("paid_option_used", false)):
		return _rejected("EVENT_OPTION_ALREADY_USED")
	var event_id := str(_active_event.get("event_id", ""))
	var cost := 2
	var move_bonus := 0
	var grants_risk_shield := false
	var result_text := "安全な方法を選んだ"
	match event_id:
		"market_hawker":
			move_bonus = 2
			result_text = "近道の地図を確認　次の移動 +2"
		"nile_tailwind":
			cost = 3
			move_bonus = 4
			result_text = "ラクダを雇った　次の移動 +4"
		"ruin_whisper":
			grants_risk_shield = true
			result_text = "ガイドを雇った　次のRISKを無効化"
		"ferry_offer":
			cost = 3
			move_bonus = 4
			result_text = "渡し舟で先へ　次の移動 +4"
		_: return _rejected("UNKNOWN_EVENT_OPTION")
	if _coins < cost:
		return _rejected("NOT_ENOUGH_COINS")
	_coins -= cost
	if move_bonus > 0: _stage_flags[STAGE_FLAG_NEXT_MOVE_BONUS] = maxi(next_basic_move_bonus(), move_bonus)
	if grants_risk_shield: _stage_flags[STAGE_FLAG_RISK_SHIELD] = true
	_active_event["paid_option_used"] = true
	_active_event["paid_option_cost"] = cost
	_active_event["paid_option_result"] = result_text
	return {"ok":true, "status":"EVENT_OPTION_PURCHASED", "cost":cost, "text":result_text, "coins":_coins}

func purchase_bypass(route_id: String) -> Dictionary:
	# Compatibility alias for older callers and saves. Shortcuts are now a
	# free risk-versus-distance choice; their danger is the price.
	return choose_route(route_id)

func can_emergency_revive() -> bool:
	return false

func emergency_revive(now_ms: int = -1) -> Dictionary:
	return _rejected("EMERGENCY_REVIVE_REMOVED")

func arm_pinpoint(face: int) -> Dictionary:
	if _phase != PHASE_READY:
		return _rejected("SKILL_NOT_AVAILABLE")
	if face < 1 or face > 6:
		return _rejected("INVALID_FACE")
	if _skill_state != SKILL_STATE_READY or _skill_gauge < SKILL_GAUGE_MAX:
		return _rejected("SKILL_NOT_READY")
	_skill_gauge = 0
	_skill_state = SKILL_STATE_ARMED
	_stage_flags[STAGE_FLAG_PINPOINT_FACE] = face
	return {"ok":true,"status":"PINPOINT_ARMED","face":face,"text":"NEXT FACE %d" % face}

func consume_pinpoint_face() -> int:
	if _skill_state != SKILL_STATE_ARMED:
		return 0
	var face := pinpoint_face()
	_stage_flags.erase(STAGE_FLAG_PINPOINT_FACE)
	_skill_state = SKILL_STATE_CHARGING
	return face
func stage_flags() -> Dictionary: return _stage_flags.duplicate(true)
func has_seen_three_roll_onboarding() -> bool: return bool(_stage_flags.get(STAGE_FLAG_THREE_ROLL_ONBOARDING_SEEN, false))
func mark_three_roll_onboarding_seen() -> void: _stage_flags[STAGE_FLAG_THREE_ROLL_ONBOARDING_SEEN] = true
func has_seen_survival_onboarding() -> bool: return bool(_stage_flags.get(STAGE_FLAG_SEEN_SURVIVAL_ONBOARDING, false))
func mark_survival_onboarding_seen() -> void: _stage_flags[STAGE_FLAG_SEEN_SURVIVAL_ONBOARDING] = true
func has_seen_skill_ready_discovery() -> bool: return bool(_stage_flags.get(STAGE_FLAG_SKILL_READY_DISCOVERY_SEEN, false))
func mark_skill_ready_discovery_seen() -> void: _stage_flags[STAGE_FLAG_SKILL_READY_DISCOVERY_SEEN] = true
func is_untouched_journey_start() -> bool:
	return _phase == PHASE_READY and _lap == 1 and _roll_count == 0 and _position == {"route_id":"main", "tile_index":0} and faces().is_empty()
func tile_explanation_kind(tile_kind: String) -> String:
	var normalized := tile_kind.strip_edges().to_upper()
	if normalized.begins_with("WARP"):
		return "WARP"
	return normalized if normalized in TILE_EXPLANATION_KINDS else ""


func has_seen_tile_explanation(tile_kind: String) -> bool:
	var normalized := tile_explanation_kind(tile_kind)
	if normalized.is_empty():
		return false
	var seen: Variant = _stage_flags.get(STAGE_FLAG_SEEN_TILE_EXPLANATIONS, {})
	return seen is Dictionary and bool((seen as Dictionary).get(normalized, false))


func mark_tile_explanation_seen(tile_kind: String) -> bool:
	var normalized := tile_explanation_kind(tile_kind)
	if normalized.is_empty():
		return false
	var seen: Dictionary = (_stage_flags.get(STAGE_FLAG_SEEN_TILE_EXPLANATIONS, {}) as Dictionary).duplicate(true)
	seen[normalized] = true
	_stage_flags[STAGE_FLAG_SEEN_TILE_EXPLANATIONS] = seen
	return true


func seen_tile_explanation_kinds() -> Array[String]:
	var result: Array[String] = []
	var seen: Variant = _stage_flags.get(STAGE_FLAG_SEEN_TILE_EXPLANATIONS, {})
	if not seen is Dictionary:
		return result
	for kind: String in TILE_EXPLANATION_KINDS:
		if bool((seen as Dictionary).get(kind, false)):
			result.append(kind)
	return result


func _restore_seen_tile_explanations(kinds: Array[String]) -> void:
	for kind: String in kinds:
		mark_tile_explanation_seen(kind)


func next_basic_move_penalty() -> int: return maxi(int(_stage_flags.get(STAGE_FLAG_NEXT_MOVE_PENALTY, 0)), 0)
func next_basic_move_bonus() -> int: return maxi(int(_stage_flags.get(STAGE_FLAG_NEXT_MOVE_BONUS, 0)), 0)
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
func boss_landing_preview(face: int) -> Dictionary: return _battle.landing_preview(face) if _battle != null else {}
func boss_course_tiles(is_player: bool = true) -> Array: return _battle.course_tiles(is_player) if _battle != null else []


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
			"max_hp": _player_max_hp,
			"life": _life,
			"coins": _coins,
			"skill_gauge": _skill_gauge,
			"skill_state": String(_skill_state),
			"inventory": _inventory.duplicate(true),
			"item_consumption": _item_consumption.duplicate(true),
			"stage_flags": _stage_flags.duplicate(true),
			"heart_roulette": heart_roulette_state(),
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
			"lap_total": _lap_score,
			"breakdown": _score_breakdown.duplicate(true),
			"role_counts": _role_counts.duplicate(true),
			"last_award": _last_score_award.duplicate(true),
			"last_coin_cashout": _last_coin_cashout,
		},
		"records": {
			"best_score": _best_score,
			"best_ms": _best_ms,
			"pb_delta_ms": pb_delta_ms(now_ms),
			"pb_updated": _pb_updated,
		},
		"missions": mission_state(),
		"clock": {
			"elapsed_ms": elapsed_ms(now_ms),
			"armed": _clock_armed,
			"running": _clock_running,
			"paused": _clock_paused,
		},
		"boss": boss_data,
		"boss_entered": _battle != null,
		"active_event": _active_event.duplicate(true) if not _active_event.is_empty() else null,
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
	var active_event_value: Variant = state.get("active_event", null)
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
	_player_max_hp = MAX_PLAYER_HP
	_player_hp = clampi(int(player.get("hp", _player_max_hp)), 0, _player_max_hp)
	_life = clampi(int(player.get("life", MAX_LIFE)), 0, MAX_LIFE)
	_coins = maxi(int(player.get("coins", 0)), 0)
	_skill_gauge = clampi(int(player.get("skill_gauge", 0)), 0, SKILL_GAUGE_MAX)
	_skill_state = StringName(str(player.get("skill_state", SKILL_STATE_CHARGING)))
	_inventory = (player.get("inventory", {}) as Dictionary).duplicate(true)
	_item_consumption = (player.get("item_consumption", {}) as Dictionary).duplicate(true)
	_stage_flags = (player.get("stage_flags", {}) as Dictionary).duplicate(true)
	_active_event = (active_event_value as Dictionary).duplicate(true) if active_event_value is Dictionary else {}
	_position = {"route_id":route_id, "tile_index":tile_index}
	_visual_position = _position.duplicate(true)
	_active_warp_gate_id = str(route.get("active_warp_gate_id", ""))
	_restore_string_set(_consumed_warp_gate_ids, route.get("consumed_warp_gate_ids", []))
	_restore_string_set(_visited_node_keys, route.get("visited_node_keys", []))
	_restore_string_set(_consumed_reward_node_keys, route.get("consumed_reward_node_keys", []))
	_restore_string_set(_awarded_score_event_ids, route.get("awarded_score_event_ids", []))
	_score = maxi(int(score_data.get("total", 0)), 0)
	_lap_score = maxi(int(score_data.get("lap_total", _score)), 0)
	_score_breakdown = (score_data.get("breakdown", {}) as Dictionary).duplicate(true)
	_role_counts = {"MIX":0, "PAIR":0, "STRAIGHT":0, "TRIPLE":0}
	for role: String in _role_counts.keys():
		_role_counts[role] = maxi(int((score_data.get("role_counts", {}) as Dictionary).get(role, 0)), 0)
	_last_score_award = (score_data.get("last_award", {}) as Dictionary).duplicate(true)
	_last_coin_cashout = maxi(int(score_data.get("last_coin_cashout", 0)), 0)
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
	_restore_missions(state.get("missions", null), player, _role_counts, phase)
	_phase = phase
	var roulette_value: Variant = player.get("heart_roulette", null)
	_heart_roulette_pending = false
	_heart_roulette_resolved = false
	_heart_roulette_slot_index = -1
	_heart_roulette_result.clear()
	if roulette_value is Dictionary:
		var roulette := roulette_value as Dictionary
		_heart_roulette_pending = bool(roulette.get("pending", false))
		_heart_roulette_resolved = bool(roulette.get("resolved", false))
		_heart_roulette_slot_index = int(roulette.get("slot_index", -1))
		var restored_roulette_result: Variant = roulette.get("result", {})
		if restored_roulette_result is Dictionary:
			_heart_roulette_result = (restored_roulette_result as Dictionary).duplicate(true)
	elif phase in [PHASE_BOSS_FINISHED, PHASE_LAP_RESULT] and _battle != null and bool(_battle.result().get("victory", false)):
		# Existing v1 saves predate the reward state. Give restored victories their
		# pending Heart Chance instead of silently skipping the new reward.
		_heart_roulette_pending = _player_hp < MAX_PLAYER_HP
	_boss_finish_recorded = phase == PHASE_BOSS_FINISHED or (boss_entered and phase in [PHASE_LAP_RESULT, PHASE_RUN_OVER] and bool((_battle.snapshot() if _battle != null else {}).get("terminal", false)))
	if phase in [PHASE_BOSS_ROLL_READY, PHASE_BOSS_ROUND_RESULT, PHASE_BOSS_FINISHED, PHASE_LAP_RESULT] and _battle == null:
		return false
	if phase in [PHASE_READY, PHASE_CHOICE_REQUIRED, PHASE_RESOLUTION_REQUIRED, PHASE_EVENT_REQUIRED] and _battle != null:
		return false
	if (phase == PHASE_EVENT_REQUIRED) != (not _active_event.is_empty()):
		return false
	_restore_clock(clock, now_ms)
	if _player_hp <= 0 and phase in [PHASE_READY, PHASE_BOSS_ROLL_READY, PHASE_BOSS_ROUND_RESULT, PHASE_BOSS_FINISHED, PHASE_LAP_RESULT]:
		_enter_run_over()
	return true


func current_tile_kind() -> String:
	return _displayed_tile_kind_at(_position)


func _displayed_tile_kind_at(route_position: Dictionary) -> String:
	if not _course_ready: return ""
	var route_id := str(route_position.get("route_id", "")); var index := int(route_position.get("tile_index", -1))
	var raw_kind: String = str(_course.tile_kind_for_position(route_position))
	if raw_kind.is_empty(): return ""
	var node_key := _position_key(route_position)
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		var gate: Dictionary = _course.warp_gate_for_main_index(index)
		if not gate.is_empty() and _consumed_warp_gate_ids.has(str(gate.id)):
			return "NORMAL"
	if _consumed_reward_node_keys.has(node_key):
		return "NORMAL"
	return raw_kind


func stage_summary() -> Dictionary:
	return _course.stage_summary() if _course_ready else {}


func pending_bypass() -> Dictionary:
	return _course.bypass_for_fork(int(_position.get("tile_index", -1))) if _course_ready and _phase == PHASE_CHOICE_REQUIRED else {}


func route_choice_previews() -> Dictionary:
	if not _course_ready or _phase != PHASE_CHOICE_REQUIRED or _pending_remaining_steps <= 0:
		return {}
	var bypass := pending_bypass()
	if bypass.is_empty():
		return {}
	var previews := {}
	for choice_id: String in [V06CourseModelScript.ROUTE_MAIN, str(bypass.get("route_id", ""))]:
		var result: Dictionary = _course.advance(_position, _pending_remaining_steps, choice_id, _course_context())
		if not bool(result.get("ok", false)):
			continue
		var target: Dictionary = (result.get("position", _position) as Dictionary).duplicate(true)
		previews[choice_id] = {
			"position": target,
			"tile_kind": _displayed_tile_kind_at(target),
			"remaining_steps": _pending_remaining_steps,
			"path": (result.get("path", []) as Array).duplicate(true),
		}
	return previews


func steps_to_loop_exit() -> int: return _course.steps_to_exit(_position) if _course_ready else -1
func loop_wrap_count() -> int: return maxi(int(_stage_flags.get(STAGE_FLAG_ACTIVE_LOOP_WRAPS, 0)), 0)
func loop_rescue_threshold() -> int: return V06CourseModelScript.LOOP_RESCUE_WRAP_THRESHOLD
func last_loop_rescue_triggered() -> bool: return _last_loop_rescue_triggered


func snapshot(now_ms: int = -1) -> Dictionary:
	var elapsed := elapsed_ms(now_ms)
	return {"stage_id":String(_stage_id), "character_id":String(_character_id), "position":position(), "visual_position":visual_position(), "phase":_phase, "faces":faces(),
		"pending_face":_pending_face, "pending_move_distance":_pending_move_distance, "pending_remaining_steps":_pending_remaining_steps, "pending_hops":pending_hop_count(),
		"resolution_role":_resolution_role, "boss_terminal":is_boss_terminal(), "boss_transition_pending":_boss_transition_pending,
		"can_roll":can_roll(), "tile_kind":current_tile_kind(), "steps_to_exit":steps_to_loop_exit(), "last_error":_last_error,
		"lap":_lap, "rolls_used":_roll_count, "player_hp":_player_hp, "player_max_hp":_player_max_hp, "boss":boss_snapshot(), "boss_result":boss_result(),
		"score":_score, "lap_score":_lap_score, "lap_multiplier_numerator":lap_multiplier_numerator(), "coins":_coins, "skill_gauge":_skill_gauge, "pending_resolution_role":_pending_resolution_role,
		"last_coin_cashout":_last_coin_cashout,
		"next_basic_move_penalty":next_basic_move_penalty(), "last_tile_effect":last_tile_effect_result(),
		"active_warp_gate_id":_active_warp_gate_id, "consumed_warp_gate_ids":consumed_warp_gate_ids(),
		"consumed_reward_node_keys":consumed_reward_node_keys(), "visited_node_keys":visited_node_keys(),
		"best_score":_best_score, "score_breakdown":score_breakdown(), "last_score_award":last_score_award(),
		"missions":mission_state(), "active_event":active_event(), "heart_roulette":heart_roulette_state(),
		"elapsed_ms":elapsed, "best_ms":_best_ms, "pb_delta_ms":pb_delta_ms(now_ms),
		"pb_updated":_pb_updated, "clock_armed":_clock_armed, "clock_running":_clock_running, "clock_paused":_clock_paused}


func _reset_run_state(keep_pb: bool) -> void:
	if not keep_pb:
		_best_ms = null
		_best_score = 0
	_lap = 1; _player_max_hp = MAX_PLAYER_HP; _player_hp = _player_max_hp; _life = MAX_LIFE; _roll_count = 0
	_reset_course_and_clock()


func _reset_course_and_clock(reset_challenge_score: bool = true) -> void:
	_travel = V06RollSetScript.new(); _battle = null
	if reset_challenge_score:
		_score = 0; _score_breakdown = {"travel":0, "slot":0, "discovery":0, "boss":0, "finish":0}; _score_event_serial = 0; _last_score_award.clear()
	_lap_score = 0; _coins = 0; _last_coin_cashout = 0; _skill_gauge = 0; _skill_state = SKILL_STATE_CHARGING
	_role_counts = {"MIX":0, "PAIR":0, "STRAIGHT":0, "TRIPLE":0}; _last_role = &""
	_reset_missions()
	_last_loop_rescue_triggered = false
	_heart_roulette_pending = false; _heart_roulette_resolved = false; _heart_roulette_slot_index = -1; _heart_roulette_result.clear()
	_inventory.clear(); _item_consumption.clear(); _stage_flags.clear(); _active_event.clear()
	_position = {"route_id":"main", "tile_index":0}; _visual_position = _position.duplicate(true)
	_active_warp_gate_id = ""; _consumed_warp_gate_ids.clear(); _visited_node_keys.clear()
	_consumed_reward_node_keys.clear(); _awarded_score_event_ids.clear()
	_mark_position_visited(_position)
	_phase = PHASE_READY; _pending_face = 0; _pending_move_distance = 0; _pending_remaining_steps = 0; _pending_result.clear(); _pending_path.clear()
	_next_hop_index = 0; _resolution_role = &""; _pending_resolution_role = &""; _pending_role_awarded = false
	_boss_transition_pending = false; _boss_finish_recorded = false; _last_error = ""
	_clock_armed = true; _clock_running = false; _clock_paused = false; _clock_start_ms = 0; _paused_total_ms = 0
	_pause_started_ms = 0; _clock_stop_ms = 0; _last_now_ms = -1; _pb_updated = false
	_pb_delta_ms = null


func _enter_boss_internal() -> void:
	_battle = V06BossBattleScript.new()
	var carried_faces: Array[int] = _travel.faces()
	var boss_flags := {
		"boss_ignore_first_sand": bool(_stage_flags.get("boss_ignore_first_sand", true)),
		"boss_next_move_halved": bool(_stage_flags.get(STAGE_FLAG_BOSS_SHIELD, false)),
		"player_head_start": 3 if bool(_stage_flags.get(STAGE_FLAG_BOSS_HEAD_START, false)) else 0,
		"boss_stop_turns": 1 if bool(_stage_flags.get(STAGE_FLAG_BOSS_SABOTAGE, false)) else 0,
	}
	if not _battle.configure_lap(_lap, mini(_player_hp, V06BossBattleScript.PLAYER_MAX_HP), carried_faces, boss_flags):
		_phase = PHASE_ERROR; _last_error = "BOSS_CONFIG_FAILED"; return
	_travel = V06RollSetScript.new()
	_resolution_role = &""; _pending_resolution_role = &""; _pending_role_awarded = false
	_boss_transition_pending = false; _boss_finish_recorded = false; _phase = PHASE_BOSS_ROLL_READY


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
	var credited := amount
	_score += credited
	_lap_score += credited
	_score_event_serial += 1
	_score_breakdown[category] = int(_score_breakdown.get(category, 0)) + credited
	_last_score_award = {"amount":credited, "base_amount":amount, "label":label, "category":category, "serial":_score_event_serial, "lap":_lap, "multiplier_numerator":lap_multiplier_numerator()}


func _enter_run_over() -> void:
	if _phase == PHASE_RUN_OVER: return
	_battle = null
	_boss_transition_pending = false
	_phase = PHASE_RUN_OVER
	_stop_clock(_last_now_ms)
	_update_best_score()


func _normalize_hp_zero_after_stable_boundary() -> void:
	if _player_hp > 0: return
	if _phase in [PHASE_READY, PHASE_BOSS_ROLL_READY, PHASE_BOSS_ROUND_RESULT, PHASE_BOSS_FINISHED, PHASE_LAP_RESULT]:
		if _life > 0:
			_life -= 1
			_player_hp = MAX_PLAYER_HP
		else:
			_enter_run_over()


func _award_travelled_steps(path: Array) -> void:
	var travelled_steps := 0
	for value: Variant in path:
		if not value is Dictionary:
			continue
		var route_position := value as Dictionary
		var key := _position_key(route_position)
		_visited_node_keys[key] = true
		travelled_steps += 1
	if travelled_steps > 0:
		_add_score(travelled_steps * SCORE_PER_STEP, "%dマス" % travelled_steps, "travel")


func _mark_position_visited(route_position: Dictionary) -> void:
	_visited_node_keys[_position_key(route_position)] = true


func _position_key(route_position: Dictionary) -> String:
	return "%s:%d" % [str(route_position.get("route_id", "")), int(route_position.get("tile_index", -1))]


func _course_context() -> Dictionary:
	return {
		"active_warp_gate_id":_active_warp_gate_id,
		"disabled_warp_gate_ids":consumed_warp_gate_ids(),
		"loop_wrap_count":loop_wrap_count(),
	}


func _seen_event_ids() -> Dictionary:
	var value: Variant = _stage_flags.get(STAGE_FLAG_SEEN_EVENT_IDS, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _prepare_active_event(return_phase: StringName, score_awarded: bool) -> bool:
	var node_key := _position_key(_position)
	var event_ids := {"main:30":"market_hawker", "main:43":"nile_tailwind", "main:61":"ruin_whisper", "main:77":"ferry_offer"}
	var event_id := str(event_ids.get(node_key, ""))
	if event_id.is_empty() or return_phase not in [PHASE_READY, PHASE_RESOLUTION_REQUIRED]: return false
	_active_event = {"event_id":event_id, "node_key":node_key, "first_visit":not _seen_event_ids().has(event_id), "score_awarded":score_awarded, "return_phase":String(return_phase)}
	return true


func _resolve_landing_effect(kind: String) -> Dictionary:
	if kind not in ["COIN", "REST", "RISK", "ITEM"]:
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
			_advance_coin_mission(amount)
			_consumed_reward_node_keys[node_key] = true
		result.applied = true
		result.text = "COIN +%d" % amount
	elif kind == "REST":
		var boost := 1 if bool(_stage_flags.get(STAGE_FLAG_NEXT_REST_BOOST, false)) else 0
		var rest_result := RestEffectModelScript.resolve(_player_hp, _player_max_hp, amount + boost)
		var before := int(rest_result.get("before_hp", _player_hp))
		_player_hp = int(rest_result.get("after_hp", _player_hp))
		var coin_bonus := int(rest_result.get("coin_bonus", 0))
		if coin_bonus > 0:
			_coins += coin_bonus
			_advance_coin_mission(coin_bonus)
		if boost > 0: _stage_flags.erase(STAGE_FLAG_NEXT_REST_BOOST)
		result["coin_bonus"] = coin_bonus
		result["hp_gain"] = _player_hp - before
		result.applied = _player_hp != before or coin_bonus > 0
		result.text = str(rest_result.get("text", "HP FULL"))
	elif kind == "ITEM":
		if not _consumed_reward_node_keys.has(node_key):
			var item_id: String = str(ITEM_IDS[posmod(int(_position.get("tile_index", 0)), ITEM_IDS.size())])
			if inventory_total() < ITEM_CAPACITY:
				_inventory[item_id] = int(_inventory.get(item_id, 0)) + 1
				result.applied = true
				result["item_id"] = item_id
				result.text = "ITEM  %s" % _item_name(item_id)
			else:
				_coins += 2
				_advance_coin_mission(2)
				result.applied = true
				result["converted_to_coins"] = 2
				result.text = "ITEM FULL  COIN +2"
			_consumed_reward_node_keys[node_key] = true
	elif kind == "RISK":
		if bool(_stage_flags.get(STAGE_FLAG_RISK_SHIELD, false)):
			_stage_flags.erase(STAGE_FLAG_RISK_SHIELD)
			result.applied = true
			result["guarded"] = true
			result.text = "SCARAB GUARD"
		else:
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
					if result.applied:
						_fail_no_damage_mission()
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
	return maxi(face + next_basic_move_bonus() - next_basic_move_penalty(), 1)


func _consume_next_move_penalty() -> void:
	if next_basic_move_penalty() > 0:
		_stage_flags[STAGE_FLAG_NEXT_MOVE_PENALTY] = 0


func _consume_next_move_bonus() -> void:
	if next_basic_move_bonus() > 0:
		_stage_flags.erase(STAGE_FLAG_NEXT_MOVE_BONUS)


func _item_name(item_id: String) -> String:
	for definition: Dictionary in item_catalog():
		if str(definition.get("id", "")) == item_id:
			return str(definition.get("name", item_id))
	return item_id


func _award_role_score(role: StringName) -> void:
	if role == &"":
		return
	_record_role(role)
	if role in [V06RollSetScript.ROLE_PAIR, V06RollSetScript.ROLE_STRAIGHT, V06RollSetScript.ROLE_TRIPLE]:
		_advance_role_mission()
	match role:
		V06RollSetScript.ROLE_TRIPLE:
			_skill_gauge = SKILL_GAUGE_MAX
		V06RollSetScript.ROLE_PAIR:
			_skill_gauge = mini(_skill_gauge + 1, SKILL_GAUGE_MAX)
		V06RollSetScript.ROLE_STRAIGHT:
			_skill_gauge = mini(_skill_gauge + 2, SKILL_GAUGE_MAX)
		_:
			_coins += 1
			_advance_coin_mission(1)
	_skill_state = SKILL_STATE_READY if _skill_gauge >= SKILL_GAUGE_MAX else SKILL_STATE_CHARGING


func _record_role(role: StringName) -> void:
	if role == &"":
		return
	var role_key := String(role)
	_role_counts[role_key] = int(_role_counts.get(role_key, 0)) + 1
	_last_role = role


func _reset_missions() -> void:
	_mission_coin_gained = 0
	_mission_role_successes = 0
	_mission_no_damage_active = true
	_mission_no_damage_completed = false
	_mission_coin_completed = false
	_mission_role_completed = false
	_mission_event_serial = 0
	_last_mission_event.clear()
	_mission_ranks = {}
	_mission_ring_exits = 0


func _advance_coin_mission(amount: int) -> void:
	if amount <= 0:
		return
	_mission_coin_gained += amount
	_update_mission_rank("cairo_coin15", _mission_coin_gained)
	if not _mission_coin_completed and _mission_coin_gained >= MISSION_COIN_TARGET:
		_mission_coin_completed = true
		_emit_mission_event("coin", true)
	else:
		_emit_mission_event("coin", false)


func _advance_role_mission() -> void:
	_mission_role_successes += 1
	_update_mission_rank("cairo_triple2", _mission_role_successes)
	if not _mission_role_completed and _mission_role_successes >= MISSION_ROLE_TARGET:
		_mission_role_completed = true
		_emit_mission_event("role", true)
	else:
		_emit_mission_event("role", false)


func _fail_no_damage_mission() -> void:
	if not _mission_no_damage_active or _mission_no_damage_completed:
		return
	_mission_no_damage_active = false
	_emit_mission_event("no_damage", false)


func _complete_no_damage_mission() -> void:
	if not _mission_no_damage_active or _mission_no_damage_completed:
		return
	_mission_no_damage_completed = true
	_update_mission_rank("cairo_no_damage", 1)
	_emit_mission_event("no_damage", true)


func _emit_mission_event(kind: String, completed: bool) -> void:
	_mission_event_serial += 1
	_last_mission_event = {"serial": _mission_event_serial, "kind": kind, "completed": completed}

func _update_mission_rank(id: String, progress: int) -> void:
	var rank := int(_mission_ranks.get(id, 0))
	var thresholds: Array = []
	match id:
		"cairo_coin15": thresholds = [6, 12, 18]
		"cairo_triple2": thresholds = [1, 2, 3]
		"cairo_no_damage": thresholds = [1]
		_: return
	var new_rank := rank
	for index in range(thresholds.size()):
		if progress >= int(thresholds[index]): new_rank = maxi(new_rank, index + 1)
	_mission_ranks[id] = new_rank


func _restore_missions(value: Variant, player: Dictionary, roles: Dictionary, phase: StringName) -> void:
	var saved_schema := int((value as Dictionary).get("schema_version", 0)) if value is Dictionary else 0
	var legacy_missions := value is Dictionary and saved_schema == 1 and int((value as Dictionary).get("coin_target", 0)) == 6 and int((value as Dictionary).get("role_target", 0)) == 2
	if value is Dictionary and (saved_schema == MISSION_SCHEMA_VERSION or legacy_missions):
		var saved := value as Dictionary
		_mission_coin_gained = maxi(int(saved.get("coin_gained", 0)), 0)
		_mission_role_successes = maxi(int(saved.get("role_successes", 0)), 0)
		_mission_no_damage_active = bool(saved.get("no_damage_active", true))
		_mission_no_damage_completed = bool(saved.get("no_damage_completed", false))
		_mission_coin_completed = _mission_coin_gained >= MISSION_COIN_TARGET if legacy_missions else bool(saved.get("coin_completed", _mission_coin_gained >= MISSION_COIN_TARGET))
		_mission_role_completed = _mission_role_successes >= MISSION_ROLE_TARGET if legacy_missions else bool(saved.get("role_completed", _mission_role_successes >= MISSION_ROLE_TARGET))
		_mission_active_ids = []
		for id in saved.get("active_ids", ["cairo_coin15", "cairo_triple2", "cairo_no_damage"]): _mission_active_ids.append(str(id))
		_mission_ranks = (saved.get("ranks", {}) as Dictionary).duplicate(true)
		_mission_ring_exits = maxi(int(saved.get("ring_exits", 0)), 0)
		if _mission_ranks.is_empty():
			if _mission_coin_completed: _mission_ranks["cairo_coin15"] = 1
			if _mission_role_completed: _mission_ranks["cairo_triple2"] = 1
			if _mission_no_damage_completed: _mission_ranks["cairo_no_damage"] = 1
		_mission_event_serial = 0 if legacy_missions else maxi(int(saved.get("event_serial", 0)), 0)
		_last_mission_event = {} if legacy_missions else (saved.get("last_event", {}) as Dictionary).duplicate(true)
	else:
		_mission_coin_gained = maxi(int(player.get("coins", 0)), 0)
		_mission_role_successes = maxi(int(roles.get("PAIR", 0)), 0) + maxi(int(roles.get("STRAIGHT", 0)), 0) + maxi(int(roles.get("TRIPLE", 0)), 0)
		var restored_max_hp := maxi(int(player.get("max_hp", START_PLAYER_HP)), 1)
		_mission_no_damage_active = int(player.get("hp", restored_max_hp)) >= restored_max_hp
		_mission_no_damage_completed = _mission_no_damage_active and phase in [PHASE_BOSS_FINISHED, PHASE_LAP_RESULT] and bool((_battle.result() if _battle != null else {}).get("victory", false))
		_mission_coin_completed = _mission_coin_gained >= MISSION_COIN_TARGET
		_mission_role_completed = _mission_role_successes >= MISSION_ROLE_TARGET
		_mission_ranks = {}
		if _mission_coin_completed: _mission_ranks["cairo_coin15"] = 1
		if _mission_role_completed: _mission_ranks["cairo_triple2"] = 1
		if _mission_no_damage_completed: _mission_ranks["cairo_no_damage"] = 1
		_mission_event_serial = 0
		_last_mission_event.clear()


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
	_clock_running = bool(clock.get("running", false)) and not _phase in [PHASE_BOSS_FINISHED, PHASE_LAP_RESULT, PHASE_RUN_OVER]
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
