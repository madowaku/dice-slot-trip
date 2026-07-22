class_name BoardModel
extends RefCounted

const TILE_COUNT: int = 90
const ROUTE_MAIN: String = "main"
const ROUTE_BYPASS_CARAVAN: String = "bypass_caravan"
const ROUTE_LOOP_ROYAL_MAZE: String = "loop_royal_maze"
const ROYAL_MAZE_SOURCE_TILE: int = 18
const VALID_ROUTE_IDS: Array[String] = [ROUTE_MAIN, ROUTE_BYPASS_CARAVAN, ROUTE_LOOP_ROYAL_MAZE]
const TILE_TYPES: Array[StringName] = [
	&"NORMAL", &"EVENT", &"ITEM", &"COIN", &"WARP", &"SHOP", &"REST", &"LANDMARK", &"BOSS_SCENT", &"STAGE_SPECIAL", &"RISK"
]

const CAIRO_TILES: Array[StringName] = [
	# MARKET 0-17
	&"LANDMARK", &"NORMAL", &"ITEM", &"COIN", &"EVENT", &"NORMAL", &"SHOP", &"ITEM", &"NORMAL", &"COIN", &"NORMAL", &"EVENT", &"SHOP", &"ITEM", &"NORMAL", &"REST", &"NORMAL", &"NORMAL",
	# PYRAMID 18-35
	&"STAGE_SPECIAL", &"NORMAL", &"ITEM", &"EVENT", &"LANDMARK", &"BOSS_SCENT", &"NORMAL", &"COIN", &"EVENT", &"RISK", &"NORMAL", &"ITEM", &"EVENT", &"NORMAL", &"WARP", &"NORMAL", &"NORMAL", &"NORMAL",
	# OASIS 36-53
	&"ITEM", &"NORMAL", &"REST", &"EVENT", &"NORMAL", &"COIN", &"NORMAL", &"REST", &"RISK", &"NORMAL", &"EVENT", &"ITEM", &"NORMAL", &"REST", &"NORMAL", &"NORMAL", &"NORMAL", &"NORMAL",
	# RUINS 54-71
	&"LANDMARK", &"NORMAL", &"EVENT", &"BOSS_SCENT", &"RISK", &"NORMAL", &"COIN", &"ITEM", &"NORMAL", &"WARP", &"EVENT", &"NORMAL", &"BOSS_SCENT", &"NORMAL", &"RISK", &"NORMAL", &"NORMAL", &"NORMAL",
	# DUNES 72-89
	&"STAGE_SPECIAL", &"NORMAL", &"ITEM", &"EVENT", &"WARP", &"NORMAL", &"COIN", &"BOSS_SCENT", &"RISK", &"NORMAL", &"EVENT", &"NORMAL", &"SHOP", &"NORMAL", &"NORMAL", &"ITEM", &"NORMAL", &"NORMAL"
]

const CAIRO_LANDMARKS_BY_TILE: Dictionary = {
	0: "CAI_LANDMARK_01",
	22: "CAI_LANDMARK_02",
	54: "CAI_LANDMARK_03",
}

static func move(index: int, distance: int, tile_count: int = TILE_COUNT) -> Dictionary:
	var total: int = index + distance
	return {"index": posmod(total, tile_count), "laps": floori(float(total) / float(tile_count))}

static func normalized_route_id(route_id: String) -> String:
	return route_id if route_id in VALID_ROUTE_IDS else ROUTE_MAIN

static func route_definition(route_id: String) -> Dictionary:
	match normalized_route_id(route_id):
		ROUTE_BYPASS_CARAVAN:
			return {
				"id": ROUTE_BYPASS_CARAVAN, "type": "bypass", "name": "砂嵐のキャラバン道",
				"entry_route": ROUTE_MAIN, "entry_tile": 32, "exit_route": ROUTE_MAIN, "exit_tile": 58,
				"tile_count": 10, "tiles": [&"RISK", &"RISK", &"STRONG_RISK", &"RISK", &"GAMBLE", &"ITEM", &"RISK", &"COIN", &"STRONG_RISK", &"NORMAL"],
				"counts_for_lap": false, "exact_stop_exit": false,
			}
		ROUTE_LOOP_ROYAL_MAZE:
			return {
				"id": ROUTE_LOOP_ROYAL_MAZE, "type": "loop", "name": "王の迷い環",
				"source_route": ROUTE_MAIN, "source_tile": ROYAL_MAZE_SOURCE_TILE,
				"entry_tile": 4, "return_gate_tile": 0, "return_route": ROUTE_MAIN, "return_tile": 26,
				"tile_count": 8, "tiles": [&"RETURN_GATE", &"RISK", &"TREASURE", &"RISK", &"ANCIENT_ITEM", &"STRONG_RISK", &"MURAL", &"RISK"],
				"counts_for_lap": false, "exact_stop_exit": true,
			}
		_:
			return {
				"id": ROUTE_MAIN, "type": "main", "name": "カイロ観光本線",
				"tile_count": TILE_COUNT, "tiles": CAIRO_TILES,
				"counts_for_lap": true, "exact_stop_exit": false,
			}

static func route_tile_count(route_id: String) -> int:
	return int(route_definition(route_id).get("tile_count", TILE_COUNT))

static func normalize_position(route_id: String, tile_index: int) -> Dictionary:
	var normalized_route := normalized_route_id(route_id)
	return {"route_id": normalized_route, "tile_index": posmod(tile_index, route_tile_count(normalized_route))}

## Shared ROUTE-01 movement primitive. Branch entry and exact-stop maze exit are
## deliberately deferred; debug positions can already traverse, save and resume
## every topology. A bypass naturally rejoins main while a loop only increments
## its own counter and never creates a main-lap crossing.
static func advance_route(route_id: String, tile_index: int, distance: int) -> Dictionary:
	var position := normalize_position(route_id, tile_index)
	var crossed_laps := 0
	var maze_loops := 0
	var path: Array[Dictionary] = []
	for _step: int in range(maxi(0, distance)):
		var current_route := str(position.route_id)
		var current_index := int(position.tile_index)
		match current_route:
			ROUTE_BYPASS_CARAVAN:
				if current_index + 1 >= route_tile_count(current_route):
					var bypass := route_definition(current_route)
					position = normalize_position(str(bypass.exit_route), int(bypass.exit_tile))
				else:
					position.tile_index = current_index + 1
			ROUTE_LOOP_ROYAL_MAZE:
				position.tile_index = posmod(current_index + 1, route_tile_count(current_route))
				if int(position.tile_index) == 0:
					maze_loops += 1
			_:
				position.tile_index = posmod(current_index + 1, TILE_COUNT)
				if int(position.tile_index) == 0:
					crossed_laps += 1
		path.append(position.duplicate(true))
	return {
		"route_id": str(position.route_id), "tile_index": int(position.tile_index),
		"index": int(position.tile_index), "laps": crossed_laps, "maze_loops": maze_loops,
		"path": path,
	}

static func route_choice_encounter(route_id: String, tile_index: int, distance: int) -> Dictionary:
	if normalized_route_id(route_id) != ROUTE_MAIN or distance <= 0:
		return {}
	var entry_tile := int(route_definition(ROUTE_BYPASS_CARAVAN).entry_tile)
	var steps_to_entry := posmod(entry_tile - posmod(tile_index, TILE_COUNT), TILE_COUNT)
	# A traveler already standing on the fork chose a route when they arrived.
	# Never reopen the same fork at the beginning of the following roll.
	if steps_to_entry <= 0 or steps_to_entry > distance:
		return {}
	var arrival := advance_route(ROUTE_MAIN, tile_index, steps_to_entry)
	return {
		"entry_route_id": ROUTE_MAIN,
		"entry_tile_index": entry_tile,
		"steps_to_entry": steps_to_entry,
		"remaining_steps": distance - steps_to_entry,
		"crossed_laps": int(arrival.laps),
		"movement_path": arrival.path,
	}

static func tile_type_for_position(route_id: String, tile_index: int) -> StringName:
	var definition := route_definition(route_id)
	var route_tiles: Array = definition.get("tiles", [])
	if route_tiles.is_empty():
		return &"NORMAL"
	return StringName(route_tiles[posmod(tile_index, route_tiles.size())])

static func build_tile_types() -> Array[StringName]:
	return CAIRO_TILES.duplicate()

static func landmark_id_for_tile(tile_index: int) -> String:
	return str(CAIRO_LANDMARKS_BY_TILE.get(posmod(tile_index, TILE_COUNT), ""))

static func item_space_rewards_for_roll(roll: int, is_double: bool = false) -> Array[StringName]:
	if is_double:
		return [&"DICE_ADD_1", &"ITEM"]
	var normalized := clampi(roll, 0, 99)
	if normalized < 35: return [&"DICE_ADD_1"]
	if normalized < 90: return [&"ITEM"]
	return [&"ITEM_CHOICE"]

static func circular_gaps(types: Array[StringName], target: StringName) -> Array[int]:
	var indices: Array[int] = []
	for index: int in range(types.size()):
		if types[index] == target: indices.append(index)
	var gaps: Array[int] = []
	if indices.is_empty(): return gaps
	for index: int in range(indices.size()):
		gaps.append(posmod(indices[(index + 1) % indices.size()] - indices[index], types.size()))
	return gaps

static func minimum_circular_gap_for(types: Array[StringName], targets: Array[StringName]) -> int:
	var indices: Array[int] = []
	for index: int in range(types.size()):
		if types[index] in targets: indices.append(index)
	if indices.size() < 2: return types.size()
	var minimum := types.size()
	for index: int in range(indices.size()):
		minimum = mini(minimum, posmod(indices[(index + 1) % indices.size()] - indices[index], types.size()))
	return minimum
