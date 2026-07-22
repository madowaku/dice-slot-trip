class_name V1StageModel
extends RefCounted

var stage: Dictionary
var boss: Dictionary
var errors: Array[String] = []

const ADVANCE_SETTLED := &"SETTLED"
const ADVANCE_BRANCH_REQUIRED := &"BRANCH_REQUIRED"
const ADVANCE_BOSS_GATE := &"BOSS_GATE"
const ADVANCE_REJECTED := &"REJECTED"

func load_bundle(path := "res://data/generated/cairo_v1_runtime.json") -> bool:
	errors.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: errors.append("cannot open bundle"); return false
	var root = JSON.parse_string(file.get_as_text())
	if not root is Dictionary: errors.append("bundle root must be an object"); return false
	if root.get("generator_version") != "1": errors.append("unsupported generator version")
	var docs: Dictionary = root.get("documents", {})
	stage = docs.get("cairo_stage_v1.yaml", {})
	boss = docs.get("cairo_boss_race_v1.yaml", {})
	_validate()
	return errors.is_empty()

func _validate() -> void:
	if stage.get("schema_version") != "dice-slot-trip.stage/1": errors.append("invalid stage schema")
	if boss.get("schema_version") != "dice-slot-trip.boss-race/1": errors.append("invalid boss schema")
	var s: Dictionary = stage.get("stage", {})
	var race: Dictionary = boss.get("boss_race", {})
	if s.get("id") != race.get("stage_id"): errors.append("boss stage_id mismatch")
	if s.get("boss_race_id") != race.get("id"): errors.append("boss race id mismatch")
	if stage.get("stage_end", {}).get("boss_race_id") != race.get("id"): errors.append("stage_end race mismatch")
	var nodes: Dictionary = stage.get("nodes", {})
	var expected: Dictionary = stage.get("validation", {}).get("expected_counts", {})
	if nodes.size() != int(expected.get("total", -1)): errors.append("total node count mismatch")
	var route_counts := {}
	for id in nodes:
		var node: Dictionary = nodes[id]
		var route: String = node.get("route", "")
		route_counts[route] = route_counts.get(route, 0) + 1
		for next_id in node.get("next", []):
			if not nodes.has(next_id): errors.append("unknown next node %s from %s" % [next_id, id])
		if node.has("event_id") and not stage.get("events", {}).has(node.event_id): errors.append("unknown event on %s" % id)
		if node.has("item_source_id") and not stage.get("item_sources", {}).has(node.item_source_id): errors.append("unknown item source on %s" % id)
	for route in ["main", "bazaar_bypass", "desert_bypass", "oasis_loop", "tomb_loop"]:
		if route_counts.get(route, 0) != int(expected.get(route, -1)): errors.append("route count mismatch: %s" % route)
	_validate_contiguous(nodes, "main", int(s.get("mainline_space_count", 0)))
	for branch in stage.get("branches", {}).values():
		for key in ["decision_node", "merge_node"]:
			if not nodes.has(branch.get(key)): errors.append("unknown branch %s" % key)
		for option in branch.get("options", []):
			if not nodes.has(option.get("next_node")): errors.append("unknown branch target")
	for loop in stage.get("loops", {}).values():
		for key in ["entry_trigger_node", "entry_node", "exit_node", "return_node"]:
			if not nodes.has(loop.get(key)): errors.append("unknown loop %s" % key)
	var gate: String = s.get("boss_gate_node", "")
	if not nodes.has(gate) or nodes.get(gate, {}).get("type") != "BOSS_GATE" or not nodes.get(gate, {}).get("next", []).is_empty(): errors.append("boss gate must be terminal")
	_validate_reachable(nodes, s.get("start_node", ""))
	var course: Dictionary = boss.get("course", {})
	var length := int(race.get("course_length", 0))
	if course.size() != length: errors.append("boss course count mismatch")
	for position in range(1, length + 1):
		if not course.has(str(position)): errors.append("missing boss course position %d" % position)
	if course.get(str(length), {}).get("type") != "GOAL" or int(race.get("goal_position", -1)) != length: errors.append("boss goal mismatch")
	if boss.get("movement_rules", {}).get("minimum_move_after_modifiers") != 1: errors.append("boss minimum movement invalid")
	if boss.get("movement_rules", {}).get("safety_max_turns") != 12: errors.append("boss safety turn count invalid")

func _validate_contiguous(nodes: Dictionary, route: String, count: int) -> void:
	var seen := {}
	for node in nodes.values():
		if node.get("route") == route: seen[int(node.get("route_index", -1))] = true
	for index in range(1, count + 1):
		if not seen.has(index): errors.append("missing %s index %d" % [route, index])

func _validate_reachable(nodes: Dictionary, start: String) -> void:
	if not nodes.has(start): errors.append("start node missing"); return
	var pending := [start]
	var seen := {}
	while not pending.is_empty():
		var id: String = pending.pop_back()
		if seen.has(id): continue
		seen[id] = true
		var node: Dictionary = nodes[id]
		for target in node.get("next", []): pending.append(target)
		for transition in node.get("on_exact_land", []):
			if transition.has("exit_loop_to"): pending.append(transition.exit_loop_to)
			if transition.has("enter_loop"):
				var loop: Dictionary = stage.get("loops", {}).get(transition.enter_loop, {})
				if loop.has("entry_node"): pending.append(loop.entry_node)
				else: errors.append("unknown loop transition %s" % transition.enter_loop)
	if seen.size() != nodes.size(): errors.append("not all nodes reachable (%d/%d)" % [seen.size(), nodes.size()])

func advance(position: String, steps: int, branch_choice: String = "") -> Dictionary:
	var nodes: Dictionary = stage.get("nodes", {})
	if steps < 0 or not nodes.has(position):
		return _advance_result(ADVANCE_REJECTED, position, steps, [], [], "")
	var current := position
	var remaining := steps
	var path: Array[String] = []
	var transitions: Array[Dictionary] = []
	var choice_used := false
	while remaining > 0:
		var node: Dictionary = nodes[current]
		if node.get("type") == "BOSS_GATE":
			return _advance_result(ADVANCE_BOSS_GATE, current, 0, path, transitions, "")
		var next_node := ""
		if node.get("type") == "BRANCH":
			var branch_id: String = node.get("branch_id", "")
			if branch_choice.is_empty():
				return _advance_result(ADVANCE_BRANCH_REQUIRED, current, remaining, path, transitions, branch_id)
			next_node = _branch_target(branch_id, branch_choice)
			if next_node.is_empty():
				return _advance_result(ADVANCE_REJECTED, position, steps, [], [], branch_id)
			choice_used = true
			transitions.append({"type": &"BRANCH", "branch_id": branch_id, "choice": branch_choice, "to": next_node})
		else:
			var next_nodes: Array = node.get("next", [])
			if next_nodes.size() != 1:
				return _advance_result(ADVANCE_REJECTED, position, steps, [], [], "")
			next_node = next_nodes[0]
		current = next_node
		path.append(current)
		remaining -= 1
		if nodes[current].get("type") == "BOSS_GATE":
			if remaining > 0:
				transitions.append({"type": &"BOSS_GATE", "discarded_steps": remaining})
			return _advance_result(ADVANCE_BOSS_GATE, current, 0, path, transitions, "")
	if not branch_choice.is_empty() and not choice_used:
		return _advance_result(ADVANCE_REJECTED, position, steps, [], [], "")
	var exact: Dictionary = _exact_landing(current)
	if not exact.is_empty():
		transitions.append(exact)
		current = exact.to
		path.append(current)
		if exact.type == &"BOSS_GATE":
			return _advance_result(ADVANCE_BOSS_GATE, current, 0, path, transitions, "")
	return _advance_result(ADVANCE_SETTLED, current, 0, path, transitions, "")

func _branch_target(branch_id: String, choice: String) -> String:
	var branch: Dictionary = stage.get("branches", {}).get(branch_id, {})
	for option in branch.get("options", []):
		if option.get("id") == choice:
			return option.get("next_node", "")
	return ""

func _exact_landing(position: String) -> Dictionary:
	var node: Dictionary = stage.get("nodes", {}).get(position, {})
	for action in node.get("on_exact_land", []):
		if action.has("enter_loop"):
			var loop_id: String = action.enter_loop
			return {"type": &"WARP", "loop_id": loop_id, "from": position, "to": stage.get("loops", {}).get(loop_id, {}).get("entry_node", "")}
		if action.has("exit_loop_to"):
			return {"type": &"EXIT", "from": position, "to": action.exit_loop_to}
		if action.has("start_boss_race"):
			return {"type": &"BOSS_GATE", "from": position, "to": position, "boss_race_id": action.start_boss_race}
	return {}

func _advance_result(status: StringName, position: String, remaining: int, path: Array, transitions: Array, branch_id: String) -> Dictionary:
	return {"status": status, "position": position, "remaining": remaining, "path": path, "transitions": transitions, "branch_id": branch_id}
