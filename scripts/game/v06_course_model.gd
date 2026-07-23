class_name V06CourseModel
extends RefCounted

const ROUTE_MAIN: String = "main"
const ROUTE_BYPASS: String = "bypass_sirocco"
const ROUTE_LOOP: String = "loop_souk_ring"
const MAIN_PREFIX_KINDS: Array[String] = ["START","NORMAL","COIN","NORMAL","EVENT","ITEM","NORMAL","REST","COIN","NORMAL","EVENT","ITEM","BYPASS_FORK","COIN","ITEM","NORMAL","REST","COIN","ITEM","NORMAL","NORMAL","RISK","LOOP_PORTAL","NORMAL","COIN","EVENT","ITEM","NORMAL","REST","RISK"]
const BYPASS_KINDS: Array[String] = ["RISK","NORMAL","RISK","NORMAL"]
const LOOP_KINDS: Array[String] = ["LOOP_ENTRY","COIN","RISK","ITEM","EXIT_GATE","COIN","RISK","ITEM"]

var _definition: Dictionary = {}
var _valid: bool = false
var validation_error: String = "INVALID_COURSE_DATA"

func load_file(path: String) -> bool:
	_valid = false
	_definition = {}
	validation_error = "INVALID_COURSE_DATA"
	if not FileAccess.file_exists(path): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary: return false
	return load_definition(parsed as Dictionary)

func load_definition(data: Dictionary) -> bool:
	_valid = false
	_definition = {}
	validation_error = "INVALID_COURSE_DATA"
	if not _validate(data): return false
	_definition = data.duplicate(true)
	_valid = true
	validation_error = ""
	return true

func definition() -> Dictionary:
	return _definition.duplicate(true)

func advance(position: Variant, distance: Variant, route_choice: Variant = "") -> Dictionary:
	var fallback: Dictionary = position.duplicate(true) if position is Dictionary else {}
	if not _valid: return _error_result("INVALID_COURSE_DATA", fallback, distance)
	if not position is Dictionary: return _error_result("INVALID_POSITION_SHAPE", fallback, distance)
	var pos: Dictionary = position as Dictionary
	if not pos.has("route_id") or not pos.has("tile_index") or not pos["route_id"] is String or not pos["tile_index"] is int:
		return _error_result("INVALID_POSITION_SHAPE", fallback, distance)
	var route: String = pos["route_id"]
	var index: int = pos["tile_index"]
	if not [ROUTE_MAIN, ROUTE_BYPASS, ROUTE_LOOP].has(route): return _error_result("UNKNOWN_ROUTE", fallback, distance)
	var limit: int = _route_size(route)
	if index < 0 or index >= limit: return _error_result("INDEX_OUT_OF_RANGE", fallback, distance)
	if not distance is int or int(distance) < 1 or int(distance) > 6: return _error_result("INVALID_DISTANCE", fallback, distance)
	if not route_choice is String: return _error_result("INVALID_ROUTE_CHOICE", fallback, distance)
	var choice: String = route_choice
	if choice != "" and choice != ROUTE_MAIN and choice != ROUTE_BYPASS: return _error_result("INVALID_ROUTE_CHOICE", fallback, distance)
	if choice != "" and not (route == ROUTE_MAIN and index == _fork_index()): return _error_result("UNEXPECTED_ROUTE_CHOICE", fallback, distance)
	if (route == ROUTE_MAIN and index == _portal_index()) or (route == ROUTE_LOOP and index == _loop_exit_index()): return _error_result("TRANSIENT_POSITION", fallback, distance)
	if route == ROUTE_MAIN and index == _boss_index(): return _error_result("AT_BOSS_GATE", fallback, distance)
	if route == ROUTE_MAIN and index == _fork_index() and choice == "": return _error_result("CHOICE_REQUIRED", fallback, distance)
	var current: Dictionary = {"route_id": route, "tile_index": index}
	var path: Array = []
	var transitions: Array = []
	var wraps: int = 0
	var consumed: int = 0
	var remaining: int = int(distance)
	while remaining > 0:
		var previous: Dictionary = current.duplicate(true)
		if current.route_id == ROUTE_MAIN:
			if current.tile_index == _fork_index():
				current = {"route_id": ROUTE_BYPASS, "tile_index": 0} if choice == ROUTE_BYPASS else {"route_id": ROUTE_MAIN, "tile_index": 13}
			else: current.tile_index += 1
		elif current.route_id == ROUTE_BYPASS:
			current = _bypass_rejoin() if current.tile_index == _bypass_size() - 1 else {"route_id": ROUTE_BYPASS, "tile_index": current.tile_index + 1}
		else:
			var next_index: int = (int(current.tile_index) + 1) % 8
			if next_index == 0: wraps += 1
			current.tile_index = next_index
		consumed += 1
		remaining -= 1
		path.append(current.duplicate(true))
		if previous.route_id != current.route_id: transitions.append({"from":previous.duplicate(true),"to":current.duplicate(true)})
		if current.route_id == ROUTE_MAIN and current.tile_index == _fork_index() and remaining > 0:
			return _result(false, "CHOICE_REQUIRED", current, consumed, remaining, path, transitions, choice, wraps, false, "CHOICE_REQUIRED")
		if current.route_id == ROUTE_MAIN and current.tile_index == _boss_index():
			return _result(true, "BOSS_GATE_REACHED", current, consumed, remaining, path, transitions, choice, wraps, true, "")
	# Exact-final zero-cost transfers only.
	if current.route_id == ROUTE_MAIN and current.tile_index == _portal_index():
		var portal_from: Dictionary = current.duplicate(true)
		current = {"route_id": ROUTE_LOOP, "tile_index": 0}
		transitions.append({"from":portal_from,"to":current.duplicate(true)})
	elif current.route_id == ROUTE_LOOP and current.tile_index == _loop_exit_index():
		var exit_from: Dictionary = current.duplicate(true)
		current = _loop_return()
		transitions.append({"from":exit_from,"to":current.duplicate(true)})
	return _result(true, "OK", current, consumed, remaining, path, transitions, choice, wraps, false, "")

func steps_to_exit(position: Dictionary) -> int:
	if position.get("route_id") != ROUTE_LOOP or not position.get("tile_index") is int: return -1
	var value: int = posmod(_loop_exit_index() - int(position.tile_index), _route_size(ROUTE_LOOP))
	return value if value > 0 else -1


func stage_summary() -> Dictionary:
	return _definition.get("stage", {}).duplicate(true) if _definition.get("stage", {}) is Dictionary else {}

func _validate(data: Dictionary) -> bool:
	if not _integral_equals(data.get("schema_version"), 1) or data.get("course_id") != "cairo_v06": return false
	if not data.get("routes") is Dictionary or not data.get("bypass") is Dictionary or not data.get("loop") is Dictionary: return false
	var routes: Dictionary = data.routes
	if routes.keys().size() != 3 or not routes.has(ROUTE_MAIN) or not routes.has(ROUTE_BYPASS) or not routes.has(ROUTE_LOOP): return false
	if not _main_route_matches(routes[ROUTE_MAIN]) or not _route_matches(routes[ROUTE_BYPASS], BYPASS_KINDS) or not _route_matches(routes[ROUTE_LOOP], LOOP_KINDS): return false
	if data.get("stage", {}) is Dictionary and not _stage_matches(data.stage, routes[ROUTE_MAIN].size()): return false
	var bypass: Dictionary = data.bypass
	var loop: Dictionary = data.loop
	if bypass.get("route_id") != ROUTE_BYPASS or not _position_matches(bypass.get("choice"), ROUTE_MAIN, _fork_index_from(data)) or not _position_matches(bypass.get("rejoin"), ROUTE_MAIN, _rejoin_index_from(data)): return false
	if not _integral_equals(bypass.get("standard_distance"), 8) or not _integral_equals(bypass.get("bypass_distance"), 5) or not _integral_equals(bypass.get("saved_steps"), 3): return false
	if loop.get("route_id") != ROUTE_LOOP or not _position_matches(loop.get("portal"), ROUTE_MAIN, _portal_index_from(data)) or not _integral_equals(loop.get("entry_index"), 0) or not _integral_equals(loop.get("exit_index"), 4) or not _position_matches(loop.get("return"), ROUTE_MAIN, _loop_return_index_from(data)): return false
	return true


func _main_route_matches(value: Variant) -> bool:
	if not value is Array or value.size() < MAIN_PREFIX_KINDS.size() + 2: return false
	for i: int in MAIN_PREFIX_KINDS.size():
		var tile: Variant = value[i]
		if not tile is Dictionary or tile.keys().size() != 2 or not _integral_equals(tile.get("index"), i) or tile.get("kind") != MAIN_PREFIX_KINDS[i]: return false
	for i: int in range(MAIN_PREFIX_KINDS.size(), value.size()):
		var tail: Variant = value[i]
		if not tail is Dictionary or tail.keys().size() != 2 or not _integral_equals(tail.get("index"), i) or not tail.has("kind"): return false
	var last: Dictionary = value[value.size() - 1]
	return last.get("kind") == "BOSS_GATE"


func _stage_matches(stage: Dictionary, main_size: int) -> bool:
	if not _integral_equals(stage.get("main_tile_count"), main_size): return false
	if main_size < 54 or main_size > 60: return false
	return stage.get("expected_minutes") is String and stage.get("difficulty") is String and _integral_equals(stage.get("branch_count"), 1) and _integral_equals(stage.get("loop_count"), 1)

func _route_matches(value: Variant, kinds: Array[String]) -> bool:
	if not value is Array or value.size() != kinds.size(): return false
	for i: int in kinds.size():
		var tile: Variant = value[i]
		if not tile is Dictionary or tile.keys().size() != 2 or not _integral_equals(tile.get("index"), i) or tile.get("kind") != kinds[i]: return false
	return true


func _route_size(route_id: String) -> int:
	var routes: Dictionary = _definition.get("routes", {})
	return routes[route_id].size() if routes.has(route_id) and routes[route_id] is Array else 0


func _bypass_size() -> int:
	return _route_size(ROUTE_BYPASS)


func _fork_index() -> int:
	return _fork_index_from(_definition)


func _portal_index() -> int:
	return _portal_index_from(_definition)


func _boss_index() -> int:
	return _route_size(ROUTE_MAIN) - 1


func _loop_exit_index() -> int:
	var loop: Dictionary = _definition.get("loop", {})
	return int(loop.get("exit_index", 4))


func _bypass_rejoin() -> Dictionary:
	var bypass: Dictionary = _definition.get("bypass", {})
	var rejoin: Dictionary = bypass.get("rejoin", {"route_id": ROUTE_MAIN, "tile_index": 20}) as Dictionary
	return {"route_id": str(rejoin.get("route_id", ROUTE_MAIN)), "tile_index": int(rejoin.get("tile_index", 20))}


func _loop_return() -> Dictionary:
	var loop: Dictionary = _definition.get("loop", {})
	var returned: Dictionary = loop.get("return", {"route_id": ROUTE_MAIN, "tile_index": 23}) as Dictionary
	return {"route_id": str(returned.get("route_id", ROUTE_MAIN)), "tile_index": int(returned.get("tile_index", 23))}


func _fork_index_from(data: Dictionary) -> int:
	var bypass: Dictionary = data.get("bypass", {})
	var choice: Dictionary = bypass.get("choice", {}) if bypass.get("choice", {}) is Dictionary else {}
	return int(choice.get("tile_index", 12))


func _rejoin_index_from(data: Dictionary) -> int:
	var bypass: Dictionary = data.get("bypass", {})
	var rejoin: Dictionary = bypass.get("rejoin", {}) if bypass.get("rejoin", {}) is Dictionary else {}
	return int(rejoin.get("tile_index", 20))


func _portal_index_from(data: Dictionary) -> int:
	var loop: Dictionary = data.get("loop", {})
	var portal: Dictionary = loop.get("portal", {}) if loop.get("portal", {}) is Dictionary else {}
	return int(portal.get("tile_index", 22))


func _loop_return_index_from(data: Dictionary) -> int:
	var loop: Dictionary = data.get("loop", {})
	var returned: Dictionary = loop.get("return", {}) if loop.get("return", {}) is Dictionary else {}
	return int(returned.get("tile_index", 23))

func _integral_equals(value: Variant, expected: int) -> bool:
	return (value is int or value is float) and value == expected

func _position_matches(value: Variant, route_id: String, tile_index: int) -> bool:
	if not value is Dictionary or value.keys().size() != 2: return false
	return value.get("route_id") == route_id and _integral_equals(value.get("tile_index"), tile_index)

func _error_result(code: String, position: Dictionary, distance: Variant) -> Dictionary:
	var remaining: int = int(distance) if distance is int else 0
	return _result(false, code, position, 0, remaining, [], [], "", 0, false, code)

func _result(ok: bool, status: String, position: Dictionary, consumed: int, remaining: int, path: Array, transitions: Array, choice: String, wraps: int, boss: bool, error: String) -> Dictionary:
	return {"ok":ok,"status":status,"position":position.duplicate(true),"steps_consumed":consumed,"remaining_steps":remaining,"path":path.duplicate(true),"transitions":transitions.duplicate(true),"route_choice_used":choice,"loop_wraps":wraps,"boss_gate_reached":boss,"error":error}
