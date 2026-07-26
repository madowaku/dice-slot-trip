class_name V06SessionSaveData
extends RefCounted

const SCHEMA_VERSION := 1
const APP_VERSION := "v0.8"
const STATUS_VALID := "VALID"
const STATUS_CORRUPT := "CORRUPT"
const STATUS_INCOMPATIBLE_VERSION := "INCOMPATIBLE_VERSION"
const VALID_PHASES := [
	"READY",
	"CHOICE_REQUIRED",
	"BOSS_ROLL_READY",
	"BOSS_ROUND_RESULT",
	"LAP_RESULT",
	"RUN_OVER",
]
const VALID_SKILL_STATES := ["CHARGING", "READY", "ARMED"]
const VALID_ROLES := ["", "MIX", "PAIR", "STRAIGHT", "TRIPLE"]
const VALID_ROUTE_IDS := ["main", "bypass_bazaar_alley", "bypass_sirocco", "loop_oasis_ring", "loop_tomb_ring"]
const STAGE_FLAG_NEXT_MOVE_PENALTY := "v06_next_basic_move_penalty"
const STAGE_FLAG_LAST_TILE_EFFECT := "v06_last_tile_effect"
const STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS := "v06_resolved_tile_effect_ids"


static func from_session(session: RefCounted) -> Dictionary:
	if session == null or not session.has_method("stable_save_snapshot"):
		return {}
	var stable_state: Dictionary = session.stable_save_snapshot(Time.get_ticks_msec())
	if stable_state.is_empty():
		return {}
	return {
		"schema_version": SCHEMA_VERSION,
		"app_version": APP_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"saved_at_unix": Time.get_unix_time_from_system(),
		"stage_id": String(session.stage_id()),
		"character_id": String(session.character_id()),
		"session_state": stable_state,
		"pending_transaction": null,
	}


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "root is not an object")
	var data := value as Dictionary
	if not data.has("schema_version") or not _integer(data.get("schema_version")):
		return _invalid(STATUS_CORRUPT, "schema_version is missing")
	if int(data.get("schema_version")) != SCHEMA_VERSION:
		return _invalid(STATUS_INCOMPATIBLE_VERSION, "unsupported schema_version")
	for key: String in ["app_version", "saved_at", "saved_at_unix", "stage_id", "character_id", "session_state", "pending_transaction"]:
		if not data.has(key):
			return _invalid(STATUS_CORRUPT, "%s is missing" % key)
	if not data.get("app_version") is String or not data.get("saved_at") is String or not _integer(data.get("saved_at_unix")):
		return _invalid(STATUS_CORRUPT, "save metadata is invalid")
	if str(data.get("stage_id", "")).is_empty() or str(data.get("character_id", "")).is_empty():
		return _invalid(STATUS_CORRUPT, "stage or character id is empty")
	if data.get("pending_transaction") != null:
		return _invalid(STATUS_CORRUPT, "pending_transaction must be null")
	if not data.get("session_state") is Dictionary:
		return _invalid(STATUS_CORRUPT, "session_state is not an object")
	var state := data.get("session_state") as Dictionary
	var state_result := _validate_state(state)
	if not bool(state_result.get("ok", false)):
		return state_result
	return {"ok": true, "status": STATUS_VALID, "data": data.duplicate(true)}


static func _validate_state(state: Dictionary) -> Dictionary:
	for key: String in ["phase", "lap", "roll_count", "player", "route", "slot", "score", "records", "clock", "boss", "boss_entered", "pending_transaction"]:
		if not state.has(key):
			return _invalid(STATUS_CORRUPT, "session_state.%s is missing" % key)
	var phase := str(state.get("phase", ""))
	if phase not in VALID_PHASES:
		return _invalid(STATUS_CORRUPT, "phase is not a stable V06 phase")
	if not _integer(state.get("lap")) or int(state.get("lap")) < 1:
		return _invalid(STATUS_CORRUPT, "lap is invalid")
	if not _integer(state.get("roll_count")) or int(state.get("roll_count")) < 0:
		return _invalid(STATUS_CORRUPT, "roll_count is invalid")
	if state.get("pending_transaction") != null:
		return _invalid(STATUS_CORRUPT, "state pending_transaction must be null")
	var result := _validate_player(state.get("player"))
	if not bool(result.get("ok", false)):
		return result
	result = _validate_route(state.get("route"))
	if not bool(result.get("ok", false)):
		return result
	result = _validate_slot(state.get("slot"))
	if not bool(result.get("ok", false)):
		return result
	result = _validate_score(state.get("score"))
	if not bool(result.get("ok", false)):
		return result
	result = _validate_records(state.get("records"))
	if not bool(result.get("ok", false)):
		return result
	result = _validate_clock(state.get("clock"))
	if not bool(result.get("ok", false)):
		return result
	if not state.get("boss") is Dictionary or not state.get("boss_entered") is bool:
		return _invalid(STATUS_CORRUPT, "boss fields are invalid")
	var boss_entered := bool(state.get("boss_entered"))
	var boss: Dictionary = state.get("boss") as Dictionary
	if boss_entered:
		for key: String in ["schema_version", "boss_id", "lap", "round", "turn", "faces", "player_hp", "boss_hp", "course_length", "player_position", "boss_position", "player_next_modifier", "boss_next_modifier", "player_first_sand_available", "player_roll_history", "boss_roll_history", "pending_ack", "terminal", "winner", "result"]:
			if not boss.has(key):
				return _invalid(STATUS_CORRUPT, "boss.%s is missing" % key)
		if str(boss.get("schema_version")) != "dice-slot-trip.boss-race/1" or str(boss.get("boss_id")) != "sphinx":
			return _invalid(STATUS_CORRUPT, "boss schema or identity is invalid")
		if not _integer(boss.get("lap")) or int(boss.get("lap")) < 1 or not _integer(boss.get("round")) or int(boss.get("round")) < 1:
			return _invalid(STATUS_CORRUPT, "boss turn is invalid")
		if not boss.get("faces") is Array or (boss.get("faces") as Array).size() > 3 or not _integer(boss.get("player_hp")) or not _integer(boss.get("boss_hp")) or int(boss.get("player_hp")) < 0 or int(boss.get("player_hp")) > 3 or int(boss.get("boss_hp")) < 0 or int(boss.get("boss_hp")) > 3:
			return _invalid(STATUS_CORRUPT, "boss state is invalid")
		if not _integer(boss.get("course_length")) or int(boss.get("course_length")) != 13 or not _integer(boss.get("player_position")) or not _integer(boss.get("boss_position")):
			return _invalid(STATUS_CORRUPT, "boss race position is invalid")
		if int(boss.get("player_position")) < 0 or int(boss.get("player_position")) > 13 or int(boss.get("boss_position")) < 0 or int(boss.get("boss_position")) > 13:
			return _invalid(STATUS_CORRUPT, "boss race position is outside the course")
		if not _integer(boss.get("player_next_modifier")) or int(boss.get("player_next_modifier")) not in [-1, 0, 1] or not _integer(boss.get("boss_next_modifier")) or int(boss.get("boss_next_modifier")) not in [-1, 0, 1]:
			return _invalid(STATUS_CORRUPT, "boss race movement modifier is invalid")
		if not boss.get("player_first_sand_available") is bool or not boss.get("player_roll_history") is Array or not boss.get("boss_roll_history") is Array:
			return _invalid(STATUS_CORRUPT, "boss race history is invalid")
		var player_history := boss.get("player_roll_history") as Array
		var boss_history := boss.get("boss_roll_history") as Array
		if player_history.size() != boss_history.size() or player_history.size() > 12:
			return _invalid(STATUS_CORRUPT, "boss race history length is invalid")
		for index: int in range(player_history.size()):
			if not _integer(player_history[index]) or not _integer(boss_history[index]) or int(player_history[index]) < 1 or int(player_history[index]) > 6 or int(boss_history[index]) != 7 - int(player_history[index]):
				return _invalid(STATUS_CORRUPT, "boss mirror roll history is invalid")
		if not boss.get("pending_ack") is bool or not boss.get("terminal") is bool or not boss.get("winner") is String or not boss.get("result") is Dictionary:
			return _invalid(STATUS_CORRUPT, "boss flags or result are invalid")
		for face: Variant in boss.get("faces") as Array:
			if not _integer(face) or int(face) < 1 or int(face) > 6:
				return _invalid(STATUS_CORRUPT, "boss face is invalid")
		if bool(boss.get("pending_ack")) and (boss.get("result") as Dictionary).is_empty():
			return _invalid(STATUS_CORRUPT, "boss acknowledgement has no turn result")
		var winner := str(boss.get("winner"))
		if bool(boss.get("terminal")) != (winner in ["player", "boss"]):
			return _invalid(STATUS_CORRUPT, "terminal boss winner is invalid")
	if phase in ["BOSS_ROLL_READY", "BOSS_ROUND_RESULT", "LAP_RESULT", "RUN_OVER"] and not boss_entered:
		return _invalid(STATUS_CORRUPT, "boss phase has no boss state")
	if phase in ["READY", "CHOICE_REQUIRED"] and boss_entered:
		return _invalid(STATUS_CORRUPT, "travel phase has boss state")
	var slot_faces: Array = state.get("slot", {}).get("faces", [])
	if phase in ["READY", "CHOICE_REQUIRED"] and slot_faces.size() > 2:
		return _invalid(STATUS_CORRUPT, "travel stable phase has too many committed faces")
	if phase == "BOSS_ROLL_READY" and slot_faces.size() > 2:
		return _invalid(STATUS_CORRUPT, "boss turn-start phase has a completed slot")
	if phase == "BOSS_ROUND_RESULT" and (slot_faces.is_empty() or slot_faces.size() > 3):
		return _invalid(STATUS_CORRUPT, "boss result has no committed face")
	if phase == "CHOICE_REQUIRED" and (int(state.get("route", {}).get("pending_face", 0)) < 1 or int(state.get("route", {}).get("pending_remaining_steps", 0)) < 1):
		return _invalid(STATUS_CORRUPT, "choice state has no held movement")
	if phase != "CHOICE_REQUIRED" and (int(state.get("route", {}).get("pending_face", 0)) != 0 or int(state.get("route", {}).get("pending_remaining_steps", 0)) != 0):
		return _invalid(STATUS_CORRUPT, "non-choice state has held movement")
	if phase != "CHOICE_REQUIRED" and not (state.get("route", {}).get("available_route_ids", []) as Array).is_empty():
		return _invalid(STATUS_CORRUPT, "non-choice state has route choices")
	return {"ok": true, "status": STATUS_VALID}


static func _validate_player(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "player is not an object")
	var player := value as Dictionary
	for key: String in ["hp", "max_hp", "coins", "skill_gauge", "skill_state", "inventory", "item_consumption", "stage_flags"]:
		if not player.has(key):
			return _invalid(STATUS_CORRUPT, "player.%s is missing" % key)
	if not _integer(player.get("hp")) or not _integer(player.get("max_hp")) or int(player.get("max_hp")) < 1 or int(player.get("hp")) < 0 or int(player.get("hp")) > int(player.get("max_hp")):
		return _invalid(STATUS_CORRUPT, "player hp is invalid")
	if not _integer(player.get("coins")) or int(player.get("coins")) < 0:
		return _invalid(STATUS_CORRUPT, "player coins are invalid")
	if not _integer(player.get("skill_gauge")) or int(player.get("skill_gauge")) < 0 or int(player.get("skill_gauge")) > 3:
		return _invalid(STATUS_CORRUPT, "skill gauge is invalid")
	if str(player.get("skill_state")) not in VALID_SKILL_STATES:
		return _invalid(STATUS_CORRUPT, "skill state is invalid")
	if not player.get("inventory") is Dictionary or not player.get("item_consumption") is Dictionary or not player.get("stage_flags") is Dictionary:
		return _invalid(STATUS_CORRUPT, "inventory, item_consumption, or stage_flags is invalid")
	if not _validate_nonnegative_dictionary(player.get("inventory") as Dictionary) or not _validate_item_consumption(player.get("item_consumption") as Dictionary):
		return _invalid(STATUS_CORRUPT, "inventory quantities are invalid")
	if not _validate_v06_stage_flags(player.get("stage_flags") as Dictionary):
		return _invalid(STATUS_CORRUPT, "known V06 stage flags are invalid")
	return {"ok": true, "status": STATUS_VALID}


static func _validate_v06_stage_flags(flags: Dictionary) -> bool:
	if flags.has(STAGE_FLAG_NEXT_MOVE_PENALTY):
		var penalty: Variant = flags.get(STAGE_FLAG_NEXT_MOVE_PENALTY)
		if not _integer(penalty) or int(penalty) < 0 or int(penalty) > 1:
			return false
	if flags.has(STAGE_FLAG_LAST_TILE_EFFECT):
		var last_effect: Variant = flags.get(STAGE_FLAG_LAST_TILE_EFFECT)
		if not last_effect is Dictionary:
			return false
		var result := last_effect as Dictionary
		if not result.is_empty():
			for key: String in ["resolution_id", "node_key", "tile_kind", "effect_kind", "amount", "applied", "text"]:
				if not result.has(key):
					return false
			if not result.get("resolution_id") is String or not result.get("node_key") is String or not result.get("tile_kind") is String or not result.get("effect_kind") is String or not result.get("text") is String:
				return false
			if not _integer(result.get("amount")) or int(result.get("amount")) < 0 or not result.get("applied") is bool:
				return false
	if flags.has(STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS):
		var resolved: Variant = flags.get(STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS)
		if not resolved is Dictionary:
			return false
		for key: Variant in (resolved as Dictionary).keys():
			if not key is String or not (resolved as Dictionary).get(key) is bool:
				return false
	return true


static func _validate_route(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "route is not an object")
	var route := value as Dictionary
	for key: String in ["current_node_id", "route_id", "tile_index", "pending_face", "pending_remaining_steps", "available_route_ids", "active_warp_gate_id", "consumed_warp_gate_ids", "visited_node_keys", "consumed_reward_node_keys", "awarded_score_event_ids", "loop_id", "loop_tile_index", "loop_exit_steps"]:
		if not route.has(key):
			return _invalid(STATUS_CORRUPT, "route.%s is missing" % key)
	if str(route.get("route_id", "")) not in VALID_ROUTE_IDS or not _integer(route.get("tile_index")) or int(route.get("tile_index")) < 0:
		return _invalid(STATUS_CORRUPT, "route position is invalid")
	if str(route.get("current_node_id", "")) != "%s:%d" % [str(route.get("route_id", "")), int(route.get("tile_index"))]:
		return _invalid(STATUS_CORRUPT, "current_node_id is empty")
	if not _integer(route.get("pending_face")) or int(route.get("pending_face")) < 0 or int(route.get("pending_face")) > 6:
		return _invalid(STATUS_CORRUPT, "pending face is invalid")
	if not _integer(route.get("pending_remaining_steps")) or int(route.get("pending_remaining_steps")) < 0:
		return _invalid(STATUS_CORRUPT, "pending remaining steps are invalid")
	for key: String in ["available_route_ids", "consumed_warp_gate_ids", "visited_node_keys", "consumed_reward_node_keys", "awarded_score_event_ids"]:
		if not route.get(key) is Array or not _string_array(route.get(key) as Array):
			return _invalid(STATUS_CORRUPT, "%s is invalid" % key)
	if not _integer(route.get("loop_tile_index")) or not _integer(route.get("loop_exit_steps")):
		return _invalid(STATUS_CORRUPT, "loop position is invalid")
	var route_id := str(route.get("route_id", ""))
	var loop_id := str(route.get("loop_id", ""))
	if loop_id != "" and loop_id != route_id:
		return _invalid(STATUS_CORRUPT, "loop id does not match route")
	if loop_id == "" and (int(route.get("loop_tile_index")) != -1 or int(route.get("loop_exit_steps")) != -1):
		return _invalid(STATUS_CORRUPT, "non-loop state has loop position")
	if loop_id != "" and (int(route.get("loop_tile_index")) != int(route.get("tile_index")) or int(route.get("loop_exit_steps")) < 0):
		return _invalid(STATUS_CORRUPT, "loop position does not match route")
	if not route.get("active_warp_gate_id") is String:
		return _invalid(STATUS_CORRUPT, "active warp gate id is invalid")
	if not _valid_route_array(route.get("available_route_ids") as Array):
		return _invalid(STATUS_CORRUPT, "available route ids are invalid")
	return {"ok": true, "status": STATUS_VALID}


static func _validate_slot(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "slot is not an object")
	var slot := value as Dictionary
	for key: String in ["faces", "current_roll_index", "last_role", "last_role_resolved", "resolution_role", "pending_role", "pending_role_awarded", "next_set_carry"]:
		if not slot.has(key):
			return _invalid(STATUS_CORRUPT, "slot.%s is missing" % key)
	if not slot.get("faces") is Array or (slot.get("faces") as Array).size() > 3:
		return _invalid(STATUS_CORRUPT, "slot faces are invalid")
	for face: Variant in slot.get("faces") as Array:
		if not _integer(face) or int(face) < 1 or int(face) > 6:
			return _invalid(STATUS_CORRUPT, "slot face is invalid")
	if not _integer(slot.get("current_roll_index")) or int(slot.get("current_roll_index")) != (slot.get("faces") as Array).size():
		return _invalid(STATUS_CORRUPT, "slot index is invalid")
	for key: String in ["last_role", "resolution_role", "pending_role"]:
		if not slot.get(key) is String or str(slot.get(key)) not in VALID_ROLES:
			return _invalid(STATUS_CORRUPT, "slot role is invalid")
	if not slot.get("last_role_resolved") is bool or not slot.get("pending_role_awarded") is bool or not slot.get("next_set_carry") is bool:
		return _invalid(STATUS_CORRUPT, "slot flags are invalid")
	if bool(slot.get("last_role_resolved")) != (str(slot.get("last_role")) != ""):
		return _invalid(STATUS_CORRUPT, "last role resolution flag is inconsistent")
	if str(slot.get("pending_role")) == "" and bool(slot.get("pending_role_awarded")):
		return _invalid(STATUS_CORRUPT, "pending role award has no role")
	return {"ok": true, "status": STATUS_VALID}


static func _validate_score(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "score is not an object")
	var score := value as Dictionary
	for key: String in ["total", "breakdown", "role_counts", "last_award"]:
		if not score.has(key):
			return _invalid(STATUS_CORRUPT, "score.%s is missing" % key)
	for key: String in ["total"]:
		if not _integer(score.get(key)) or int(score.get(key)) < 0:
			return _invalid(STATUS_CORRUPT, "score total is invalid")
	if not score.get("breakdown") is Dictionary or not score.get("role_counts") is Dictionary or not score.get("last_award") is Dictionary:
		return _invalid(STATUS_CORRUPT, "score details are invalid")
	if not _validate_nonnegative_dictionary(score.get("breakdown") as Dictionary):
		return _invalid(STATUS_CORRUPT, "score breakdown is invalid")
	for role: String in ["MIX", "PAIR", "STRAIGHT", "TRIPLE"]:
		if not score.get("role_counts").has(role) or not _integer(score.get("role_counts").get(role)) or int(score.get("role_counts").get(role)) < 0:
			return _invalid(STATUS_CORRUPT, "role count is invalid")
	var award: Dictionary = score.get("last_award") as Dictionary
	if not award.is_empty():
		for key: String in ["amount", "serial"]:
			if not award.has(key) or not _integer(award.get(key)) or int(award.get(key)) < 0:
				return _invalid(STATUS_CORRUPT, "last score award is invalid")
		for key: String in ["label", "category"]:
			if not award.has(key) or not award.get(key) is String:
				return _invalid(STATUS_CORRUPT, "last score award text is invalid")
	return {"ok": true, "status": STATUS_VALID}


static func _validate_records(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "records is not an object")
	var records := value as Dictionary
	for key: String in ["best_score", "best_ms", "pb_delta_ms", "pb_updated"]:
		if not records.has(key):
			return _invalid(STATUS_CORRUPT, "records.%s is missing" % key)
	if not _integer(records.get("best_score")) or int(records.get("best_score")) < 0 or not _nullable_integer(records.get("best_ms")) or not _nullable_integer(records.get("pb_delta_ms")) or not records.get("pb_updated") is bool:
		return _invalid(STATUS_CORRUPT, "records are invalid")
	return {"ok": true, "status": STATUS_VALID}


static func _validate_clock(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _invalid(STATUS_CORRUPT, "clock is not an object")
	var clock := value as Dictionary
	for key: String in ["elapsed_ms", "armed", "running", "paused"]:
		if not clock.has(key):
			return _invalid(STATUS_CORRUPT, "clock.%s is missing" % key)
	if not _integer(clock.get("elapsed_ms")) or int(clock.get("elapsed_ms")) < 0:
		return _invalid(STATUS_CORRUPT, "elapsed_ms is invalid")
	if not clock.get("armed") is bool or not clock.get("running") is bool or not clock.get("paused") is bool:
		return _invalid(STATUS_CORRUPT, "clock flags are invalid")
	if bool(clock.get("armed")) and bool(clock.get("running")):
		return _invalid(STATUS_CORRUPT, "clock cannot be armed and running")
	if bool(clock.get("paused")) and not bool(clock.get("running")):
		return _invalid(STATUS_CORRUPT, "paused clock is not running")
	return {"ok": true, "status": STATUS_VALID}


static func _integer(value: Variant) -> bool:
	return value is int or (value is float and not is_nan(float(value)) and not is_inf(float(value)) and is_equal_approx(float(value), roundf(float(value))))


static func _string_array(value: Array) -> bool:
	for item: Variant in value:
		if not item is String:
			return false
	return true


static func _nullable_integer(value: Variant) -> bool:
	return value == null or _integer(value)


static func _validate_nonnegative_dictionary(value: Dictionary) -> bool:
	for item: Variant in value.values():
		if not _integer(item) or int(item) < 0:
			return false
	return true


static func _validate_item_consumption(value: Dictionary) -> bool:
	for item: Variant in value.values():
		if item is bool:
			continue
		if not _integer(item) or int(item) < 0:
			return false
	return true


static func _valid_route_array(value: Array) -> bool:
	for item: Variant in value:
		if str(item) not in VALID_ROUTE_IDS:
			return false
	return true


static func _invalid(status: String, error: String) -> Dictionary:
	return {"ok": false, "status": status, "error": error}
