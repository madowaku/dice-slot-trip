class_name V06CourseModel
extends RefCounted

const ROUTE_MAIN := "main"
const ROUTE_BYPASS_BAZAAR := "bypass_bazaar_alley"
const ROUTE_BYPASS_SIROCCO := "bypass_sirocco"
const ROUTE_BYPASS := ROUTE_BYPASS_BAZAAR # Compatibility alias for the first fork.
const ROUTE_BYPASSES: Array[String] = [ROUTE_BYPASS_BAZAAR, ROUTE_BYPASS_SIROCCO]
const ROUTE_LOOP_OASIS := "loop_oasis_ring"
const ROUTE_LOOP_TOMB := "loop_tomb_ring"
const ROUTE_LOOP := ROUTE_LOOP_OASIS # Compatibility alias for older callers.

const MAIN_KINDS: Array[String] = [
	"START","NORMAL","COIN","NORMAL","EVENT","ITEM","NORMAL","REST","COIN","NORMAL","WARP_OASIS","BYPASS_FORK",
	"ITEM","COIN","ITEM","NORMAL","REST","COIN","ITEM","NORMAL","NORMAL","RISK","WARP_OASIS","NORMAL",
	"COIN","EVENT","ITEM","NORMAL","REST","RISK","NORMAL","NORMAL","COIN","WARP_TOMB","BYPASS_FORK","ITEM",
	"NORMAL","RISK","REST","COIN","NORMAL","EVENT","ITEM","NORMAL","WARP_TOMB","COIN","NORMAL","REST",
	"EVENT","NORMAL","ITEM","RISK","COIN","NORMAL","WARP_GOLD","RISK","NORMAL","BOSS_GATE",
]
const BYPASS_BAZAAR_KINDS: Array[String] = ["RISK","ITEM","NORMAL"]
const BYPASS_SIROCCO_KINDS: Array[String] = ["RISK","NORMAL","ITEM","RISK","NORMAL"]
const OASIS_KINDS: Array[String] = ["EXIT_GATE","NORMAL","COIN","LOOP_ENTRY","REST","LOOP_ENTRY","ITEM","NORMAL"]
const TOMB_KINDS: Array[String] = ["EXIT_GATE","RISK","LOOP_ENTRY_GOLD","LOOP_ENTRY","RISK","LOOP_ENTRY","ITEM","COIN"]

var _definition: Dictionary = {}
var _valid := false
var validation_error := "INVALID_COURSE_DATA"


func load_file(path: String) -> bool:
	_valid = false
	_definition = {}
	validation_error = "INVALID_COURSE_DATA"
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return load_definition(parsed as Dictionary) if parsed is Dictionary else false


func load_definition(data: Dictionary) -> bool:
	_valid = false
	_definition = {}
	validation_error = "INVALID_COURSE_DATA"
	if not _validate(data):
		return false
	_definition = data.duplicate(true)
	_valid = true
	validation_error = ""
	return true


func definition() -> Dictionary:
	return _definition.duplicate(true)


func advance(position: Variant, distance: Variant, route_choice: Variant = "", context: Dictionary = {}) -> Dictionary:
	var fallback: Dictionary = position.duplicate(true) if position is Dictionary else {}
	if not _valid:
		return _error_result("INVALID_COURSE_DATA", fallback, distance)
	if not position is Dictionary:
		return _error_result("INVALID_POSITION_SHAPE", fallback, distance)
	var pos := position as Dictionary
	if not pos.has("route_id") or not pos.has("tile_index") or not pos.route_id is String or not pos.tile_index is int:
		return _error_result("INVALID_POSITION_SHAPE", fallback, distance)
	var route := str(pos.route_id)
	var index := int(pos.tile_index)
	if not _route_exists(route):
		return _error_result("UNKNOWN_ROUTE", fallback, distance)
	if index < 0 or index >= _route_size(route):
		return _error_result("INDEX_OUT_OF_RANGE", fallback, distance)
	if not distance is int or int(distance) < 1 or int(distance) > 6:
		return _error_result("INVALID_DISTANCE", fallback, distance)
	if not route_choice is String:
		return _error_result("INVALID_ROUTE_CHOICE", fallback, distance)
	var choice := str(route_choice)
	var fork: Dictionary = bypass_for_fork(index) if route == ROUTE_MAIN else {}
	if choice != "" and choice != ROUTE_MAIN and choice not in ROUTE_BYPASSES:
		return _error_result("INVALID_ROUTE_CHOICE", fallback, distance)
	if choice != "" and (fork.is_empty() or (choice != ROUTE_MAIN and choice != str(fork.route_id))):
		return _error_result("UNEXPECTED_ROUTE_CHOICE", fallback, distance)
	var disabled_gates := _string_set(context.get("disabled_warp_gate_ids", []))
	var active_gate_id := str(context.get("active_warp_gate_id", ""))
	var starting_gate := warp_gate_for_main_index(index) if route == ROUTE_MAIN else {}
	if not starting_gate.is_empty() and not disabled_gates.has(str(starting_gate.id)):
		return _error_result("TRANSIENT_POSITION", fallback, distance)
	if is_loop_route(route) and index == loop_exit_index(route):
		return _error_result("TRANSIENT_POSITION", fallback, distance)
	if route == ROUTE_MAIN and index == _boss_index():
		return _error_result("AT_BOSS_GATE", fallback, distance)
	if route == ROUTE_MAIN and not fork.is_empty() and choice == "":
		return _error_result("CHOICE_REQUIRED", fallback, distance)

	var current := {"route_id":route, "tile_index":index}
	var path: Array = []
	var transitions: Array = []
	var wraps := 0
	var consumed := 0
	var remaining := int(distance)
	while remaining > 0:
		var previous: Dictionary = current.duplicate(true)
		if current.route_id == ROUTE_MAIN:
			var current_fork: Dictionary = bypass_for_fork(int(current.tile_index))
			if not current_fork.is_empty():
				current = {"route_id":str(current_fork.route_id), "tile_index":0} if choice == str(current_fork.route_id) else {"route_id":ROUTE_MAIN, "tile_index":int(current.tile_index) + 1}
			else:
				current.tile_index += 1
		elif is_bypass_route(str(current.route_id)):
			current = bypass_rejoin(str(current.route_id)) if current.tile_index == _route_size(str(current.route_id)) - 1 else {"route_id":current.route_id, "tile_index":current.tile_index + 1}
		else:
			var next_index := (int(current.tile_index) + 1) % _route_size(str(current.route_id))
			if next_index == 0:
				wraps += 1
			current.tile_index = next_index
		consumed += 1
		remaining -= 1
		path.append(current.duplicate(true))
		if previous.route_id != current.route_id:
			transitions.append({"kind":"route_change", "from":previous, "to":current.duplicate(true)})
		if current.route_id == ROUTE_MAIN and not bypass_for_fork(int(current.tile_index)).is_empty() and remaining > 0:
			return _result(false, "CHOICE_REQUIRED", current, consumed, remaining, path, transitions, choice, wraps, false, "CHOICE_REQUIRED")
		if current.route_id == ROUTE_MAIN and current.tile_index == _boss_index():
			return _result(true, "BOSS_GATE_REACHED", current, consumed, remaining, path, transitions, choice, wraps, true, "")

	var entered_gate_id := ""
	var exited_gate_id := ""
	if current.route_id == ROUTE_MAIN:
		var gate := warp_gate_for_main_index(int(current.tile_index))
		if not gate.is_empty() and not disabled_gates.has(str(gate.id)):
			var portal_from: Dictionary = current.duplicate(true)
			current = {"route_id":str(gate.route_id), "tile_index":int(gate.entry_index)}
			entered_gate_id = str(gate.id)
			transitions.append({"kind":"warp_enter", "gate_id":entered_gate_id, "style":str(gate.style), "from":portal_from, "to":current.duplicate(true)})
	elif is_loop_route(str(current.route_id)) and int(current.tile_index) == loop_exit_index(str(current.route_id)):
		var active_gate := warp_gate(active_gate_id)
		if active_gate.is_empty() or str(active_gate.route_id) != str(current.route_id):
			return _error_result("WARP_CONTEXT_REQUIRED", fallback, distance)
		var exit_from: Dictionary = current.duplicate(true)
		current = {"route_id":ROUTE_MAIN, "tile_index":int(active_gate.return_index)}
		exited_gate_id = active_gate_id
		transitions.append({"kind":"warp_exit", "gate_id":active_gate_id, "from":exit_from, "to":current.duplicate(true)})
	var result := _result(true, "OK", current, consumed, remaining, path, transitions, choice, wraps, false, "")
	result.entered_warp_gate_id = entered_gate_id
	result.exited_warp_gate_id = exited_gate_id
	return result


func steps_to_exit(position: Dictionary) -> int:
	var route := str(position.get("route_id", ""))
	if not is_loop_route(route) or not position.get("tile_index") is int:
		return -1
	var value := posmod(loop_exit_index(route) - int(position.tile_index), _route_size(route))
	return value if value > 0 else -1


func stage_summary() -> Dictionary:
	return _definition.get("stage", {}).duplicate(true) if _definition.get("stage", {}) is Dictionary else {}


func warp_gates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in _definition.get("warp_gates", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


func warp_gate(gate_id: String) -> Dictionary:
	for gate: Dictionary in warp_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func warp_gate_for_main_index(tile_index: int) -> Dictionary:
	for gate: Dictionary in warp_gates():
		if int(gate.get("main_index", -1)) == tile_index:
			return gate
	return {}


func loop_definition(route_id: String) -> Dictionary:
	var loops: Dictionary = _definition.get("loops", {})
	return loops.get(route_id, {}).duplicate(true) if loops.get(route_id, {}) is Dictionary else {}


func loop_exit_index(route_id: String) -> int:
	return int(loop_definition(route_id).get("exit_index", 0))


func is_loop_route(route_id: String) -> bool:
	return route_id in [ROUTE_LOOP_OASIS, ROUTE_LOOP_TOMB]


func effect_for_position(position: Dictionary) -> Dictionary:
	var route_id := str(position.get("route_id", ""))
	var tile_index := int(position.get("tile_index", -1))
	var routes: Dictionary = _definition.get("routes", {})
	if not routes.has(route_id) or not routes[route_id] is Array:
		return {}
	var route := routes[route_id] as Array
	if tile_index < 0 or tile_index >= route.size() or not route[tile_index] is Dictionary:
		return {}
	var effect: Variant = (route[tile_index] as Dictionary).get("effect", {})
	return (effect as Dictionary).duplicate(true) if effect is Dictionary else {}


func is_bypass_route(route_id: String) -> bool:
	return route_id in ROUTE_BYPASSES


func bypasses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in _definition.get("bypasses", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


func bypass_definition(route_id: String) -> Dictionary:
	for bypass: Dictionary in bypasses():
		if str(bypass.get("route_id", "")) == route_id:
			return bypass
	return {}


func bypass_for_fork(tile_index: int) -> Dictionary:
	for bypass: Dictionary in bypasses():
		var choice: Dictionary = bypass.get("choice", {})
		if int(choice.get("tile_index", -1)) == tile_index:
			return bypass
	return {}


func bypass_rejoin(route_id: String) -> Dictionary:
	var bypass := bypass_definition(route_id)
	if not bypass.get("rejoin", {}) is Dictionary:
		return {}
	var rejoin := bypass.get("rejoin", {}) as Dictionary
	return {"route_id":str(rejoin.get("route_id", ROUTE_MAIN)), "tile_index":int(rejoin.get("tile_index", -1))}


func _validate(data: Dictionary) -> bool:
	if not _integral_equals(data.get("schema_version"), 2) or data.get("course_id") != "cairo_v06":
		return false
	if not data.get("routes") is Dictionary or not data.get("bypasses") is Array or not data.get("loops") is Dictionary or not data.get("warp_gates") is Array:
		return false
	var routes: Dictionary = data.routes
	if routes.keys().size() != 5:
		return false
	if not _route_matches(routes.get(ROUTE_MAIN), MAIN_KINDS) \
			or not _route_matches(routes.get(ROUTE_BYPASS_BAZAAR), BYPASS_BAZAAR_KINDS) \
			or not _route_matches(routes.get(ROUTE_BYPASS_SIROCCO), BYPASS_SIROCCO_KINDS):
		return false
	if not _route_matches(routes.get(ROUTE_LOOP_OASIS), OASIS_KINDS) or not _route_matches(routes.get(ROUTE_LOOP_TOMB), TOMB_KINDS):
		return false
	if not _stage_matches(data.get("stage", {}), MAIN_KINDS.size()):
		return false
	var bypass_specs := [
		[ROUTE_BYPASS_BAZAAR, 11, 19, 8, 4, 4, "right"],
		[ROUTE_BYPASS_SIROCCO, 34, 46, 12, 6, 6, "left"],
	]
	var bypasses_value: Array = data.bypasses
	if bypasses_value.size() != bypass_specs.size():
		return false
	for index: int in range(bypass_specs.size()):
		var bypass: Variant = bypasses_value[index]
		var spec: Array = bypass_specs[index]
		if not bypass is Dictionary \
				or bypass.get("route_id") != spec[0] \
				or not _position_matches(bypass.get("choice"), ROUTE_MAIN, spec[1]) \
				or not _position_matches(bypass.get("rejoin"), ROUTE_MAIN, spec[2]) \
				or not _integral_equals(bypass.get("standard_distance"), spec[3]) \
				or not _integral_equals(bypass.get("bypass_distance"), spec[4]) \
				or not _integral_equals(bypass.get("saved_steps"), spec[5]) \
				or bypass.get("side") != spec[6] \
				or not bypass.get("name_ja") is String:
			return false
	var loops: Dictionary = data.loops
	if loops.keys().size() != 2:
		return false
	for route_id: String in [ROUTE_LOOP_OASIS, ROUTE_LOOP_TOMB]:
		var loop: Variant = loops.get(route_id)
		if not loop is Dictionary or not _integral_equals(loop.get("exit_index"), 0) or not _integral_number(loop.get("exit_score")):
			return false
	var gates: Array = data.warp_gates
	if gates.size() != 5:
		return false
	var expected_indices := [10, 22, 33, 44, 54]
	var ids := {}
	for index: int in range(gates.size()):
		var gate: Variant = gates[index]
		if not gate is Dictionary:
			return false
		var gate_id := str(gate.get("id", ""))
		var route_id := str(gate.get("route_id", ""))
		if gate_id.is_empty() or ids.has(gate_id) or not is_loop_route(route_id):
			return false
		ids[gate_id] = true
		if not _integral_equals(gate.get("main_index"), expected_indices[index]):
			return false
		if not _integral_number(gate.get("entry_index")) or int(gate.entry_index) < 0 or int(gate.entry_index) >= 8:
			return false
		if not _integral_number(gate.get("return_index")) or int(gate.return_index) <= int(gate.main_index) or int(gate.return_index) >= 57:
			return false
	return true


func _stage_matches(value: Variant, main_size: int) -> bool:
	if not value is Dictionary:
		return false
	var stage := value as Dictionary
	return _integral_equals(stage.get("main_tile_count"), main_size) \
		and _integral_equals(stage.get("branch_count"), 2) \
		and _integral_equals(stage.get("loop_count"), 2) \
		and _integral_equals(stage.get("warp_gate_count"), 5) \
		and stage.get("expected_minutes") is String and stage.get("difficulty") is String


func _route_matches(value: Variant, kinds: Array[String]) -> bool:
	if not value is Array or value.size() != kinds.size():
		return false
	for index: int in range(kinds.size()):
		var tile: Variant = value[index]
		if not tile is Dictionary or tile.keys().size() not in [2, 3] or not _integral_equals(tile.get("index"), index) or tile.get("kind") != kinds[index]:
			return false
		if tile.has("effect") and not _effect_matches(tile.get("effect"), str(tile.get("kind", ""))):
			return false
	return true


func _effect_matches(value: Variant, tile_kind: String) -> bool:
	if tile_kind not in ["COIN", "REST", "RISK"] or not value is Dictionary:
		return false
	var effect := value as Dictionary
	if effect.keys().size() != 3 or not effect.get("kind") is String or not _integral_number(effect.get("amount")) or int(effect.get("amount")) < 0 or not effect.get("consume_once") is bool:
		return false
	var effect_kind := str(effect.get("kind", ""))
	if tile_kind == "COIN":
		return effect_kind == "coin_gain" and bool(effect.get("consume_once"))
	if tile_kind == "REST":
		return effect_kind == "heal" and not bool(effect.get("consume_once"))
	return effect_kind in ["hp_damage", "coin_loss", "next_move"] and not bool(effect.get("consume_once"))


func _route_exists(route_id: String) -> bool:
	return _route_size(route_id) > 0


func _route_size(route_id: String) -> int:
	var routes: Dictionary = _definition.get("routes", {})
	return routes[route_id].size() if routes.has(route_id) and routes[route_id] is Array else 0


func _boss_index() -> int:
	return _route_size(ROUTE_MAIN) - 1


func _string_set(values: Variant) -> Dictionary:
	var result := {}
	if values is Array or values is PackedStringArray:
		for value: Variant in values:
			result[str(value)] = true
	return result


func _integral_number(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(value, roundf(value)))


func _integral_equals(value: Variant, expected: int) -> bool:
	return _integral_number(value) and int(value) == expected


func _position_matches(value: Variant, route_id: String, tile_index: int) -> bool:
	return value is Dictionary and value.keys().size() == 2 and value.get("route_id") == route_id and _integral_equals(value.get("tile_index"), tile_index)


func _error_result(code: String, position: Dictionary, distance: Variant) -> Dictionary:
	var remaining := int(distance) if distance is int else 0
	return _result(false, code, position, 0, remaining, [], [], "", 0, false, code)


func _result(ok: bool, status: String, position: Dictionary, consumed: int, remaining: int, path: Array, transitions: Array, choice: String, wraps: int, boss: bool, error: String) -> Dictionary:
	return {
		"ok":ok, "status":status, "position":position.duplicate(true), "steps_consumed":consumed,
		"remaining_steps":remaining, "path":path.duplicate(true), "transitions":transitions.duplicate(true),
		"route_choice_used":choice, "loop_wraps":wraps, "boss_gate_reached":boss, "error":error,
		"entered_warp_gate_id":"", "exited_warp_gate_id":"",
	}
