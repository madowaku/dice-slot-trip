class_name EventSystem
extends RefCounted

const DATA_PATH := "res://data/events/cairo_m4a_events.json"
const RARE_ID := "CAI-E30"

static func definitions() -> Array[Dictionary]:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null: return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var result: Array[Dictionary] = []
	if parsed is Dictionary:
		for entry: Variant in parsed.get("events", []):
			if entry is Dictionary: result.append((entry as Dictionary).duplicate(true))
	return result

static func district_for_tile(tile_index: int) -> String:
	var number := posmod(tile_index, 90) + 1
	if number <= 18: return "MARKET"
	if number <= 36: return "PYRAMID"
	if number <= 54: return "OASIS"
	if number <= 72: return "RUINS"
	return "DUNES"

static func pool_for(district: String, events: Array[Dictionary], state: Dictionary) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var recent: Array = state.get("recent_event_ids", [])
	var last := str(recent[0]) if not recent.is_empty() else ""
	for event: Dictionary in events:
		var id := str(event.get("event_id", ""))
		if str(event.get("district_id", "")) != district or id == last: continue
		if id == RARE_ID and (bool(state.get("rare_event_used_this_loop", false)) or int(state.get("events_since_rare", 99)) < int(event.get("cooldown_events", 5))): continue
		var weight := float(event.get("weight", 1.0))
		if id in recent: weight *= 0.5
		if id not in state.get("seen_event_ids", []): weight *= 1.5
		var weighted := event.duplicate(true)
		weighted["effective_weight"] = weight
		pool.append(weighted)
	return pool

static func pick_event(district: String, events: Array[Dictionary], state: Dictionary, random_value: float) -> Dictionary:
	var pool := pool_for(district, events, state)
	if pool.is_empty(): return {}
	var total := 0.0
	for event: Dictionary in pool: total += float(event.effective_weight)
	var cursor := clampf(random_value, 0.0, 0.999999) * total
	for event: Dictionary in pool:
		cursor -= float(event.effective_weight)
		if cursor < 0.0: return event
	return pool.back()

static func arrival_snapshot(values: Array[int], roles: Dictionary, early_stopped: bool, character_id: StringName) -> Dictionary:
	var total := 0
	for value: int in values: total += value
	return {"source_dice_count": values.size(), "source_dice_values": values.duplicate(), "source_total": total, "source_roles": roles.duplicate(true), "source_was_early_stopped": early_stopped, "source_used_items": [], "source_character_id": String(character_id)}

static func condition_matches(condition: Dictionary, arrival: Dictionary, choice_id: String, extra: Dictionary) -> bool:
	var source_labels: Array = arrival.get("source_roles", {}).get("labels", [])
	if condition.has("source_role") and not _has_role(source_labels, str(condition.source_role)): return false
	if condition.has("source_total_max") and int(arrival.get("source_total", 0)) > int(condition.source_total_max): return false
	if condition.has("source_total_parity") and posmod(int(arrival.get("source_total", 0)), 2) != (0 if str(condition.source_total_parity) == "EVEN" else 1): return false
	var extra_labels: Array = extra.get("extra_roles", {}).get("labels", [])
	if condition.has("extra_role") and not _has_role(extra_labels, str(condition.extra_role)): return false
	if condition.has("effective_extra_value_min") and int(extra.get("effective_value", extra.get("extra_total", 0))) < int(condition.effective_extra_value_min): return false
	if condition.has("effective_extra_value_max") and int(extra.get("effective_value", extra.get("extra_total", 0))) > int(condition.effective_extra_value_max): return false
	if condition.has("extra_role_type_count_min") and int(extra.get("role_type_count", 0)) < int(condition.extra_role_type_count_min): return false
	return true

static func _has_role(labels: Array, requested: String) -> bool:
	var normalized := requested.replace("_", " ")
	for label: Variant in labels:
		if str(label).replace("_", " ") == normalized: return true
	return false

static func resolve(event: Dictionary, arrival: Dictionary, choice_id: String = "", extra: Dictionary = {}) -> Dictionary:
	var outcomes: Array = event.get("outcomes", [])
	if not choice_id.is_empty():
		for choice: Variant in event.get("choices", []):
			if choice is Dictionary and str((choice as Dictionary).get("choice_id", "")) == choice_id:
				outcomes = (choice as Dictionary).get("outcomes", [])
				break
	for outcome: Variant in outcomes:
		if outcome is Dictionary and condition_matches((outcome as Dictionary).get("condition", {}), arrival, choice_id, extra):
			return (outcome as Dictionary).duplicate(true)
	return {"result_id": "base", "result_text": "旅の記憶になった。", "rewards": event.get("base_rewards", []), "state_changes": [], "follow_up": "RETURN_TO_BOARD"}

static func record_event(state: Dictionary, event_id: String) -> void:
	state["event_history"].append({"event_id": event_id, "order": state["event_history"].size() + 1})
	if event_id not in state["seen_event_ids"]: state["seen_event_ids"].append(event_id)
	state["recent_event_ids"].push_front(event_id)
	while state["recent_event_ids"].size() > 3: state["recent_event_ids"].pop_back()
	state["events_seen_this_loop"].append(event_id)
	state["events_since_rare"] = int(state.get("events_since_rare", 99)) + 1
	if event_id == RARE_ID:
		state["rare_event_used_this_loop"] = true
		state["events_since_rare"] = 0

static func reset_loop_state(state: Dictionary) -> void:
	state["events_seen_this_loop"] = []
	state["rare_event_used_this_loop"] = false
	state["events_since_rare"] = 99
