class_name BoardModel
extends RefCounted

const TILE_COUNT: int = 90
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

static func move(index: int, distance: int, tile_count: int = TILE_COUNT) -> Dictionary:
	var total: int = index + distance
	return {"index": posmod(total, tile_count), "laps": floori(float(total) / float(tile_count))}

static func build_tile_types() -> Array[StringName]:
	return CAIRO_TILES.duplicate()

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
