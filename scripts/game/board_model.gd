class_name BoardModel
extends RefCounted

const TILE_COUNT: int = 90
const TILE_TYPES: Array[StringName] = [
	&"NORMAL", &"EVENT", &"ITEM", &"COIN", &"WARP", &"SHOP", &"REST", &"LANDMARK", &"BOSS_SCENT"
]

static func move(index: int, distance: int, tile_count: int = TILE_COUNT) -> Dictionary:
	var total: int = index + distance
	return {"index": posmod(total, tile_count), "laps": floori(float(total) / float(tile_count))}

static func build_tile_types() -> Array[StringName]:
	var counts: Dictionary = {
		# M3 adds four quiet foreshadowing spaces while keeping the existing slice's economy.
		&"NORMAL": 46, &"EVENT": 14, &"ITEM": 8, &"COIN": 8,
		&"WARP": 3, &"SHOP": 2, &"REST": 2, &"LANDMARK": 3, &"BOSS_SCENT": 4
	}
	var result: Array[StringName] = []
	# A deterministic interleave keeps special spaces readable and data-testable.
	for index: int in range(TILE_COUNT):
		var preferred: StringName = &"NORMAL"
		if index in [0, 30, 60]: preferred = &"LANDMARK"
		elif index in [10, 36, 63, 84]: preferred = &"BOSS_SCENT"
		elif index in [17, 47, 77]: preferred = &"WARP"
		elif index in [24, 66]: preferred = &"SHOP"
		elif index in [14, 54]: preferred = &"REST"
		elif index % 9 == 4: preferred = &"ITEM"
		elif index % 8 == 2: preferred = &"COIN"
		elif index % 5 == 1: preferred = &"EVENT"
		if int(counts.get(preferred, 0)) <= 0:
			preferred = _next_available(counts)
		result.append(preferred)
		counts[preferred] = int(counts[preferred]) - 1
	# Replace late NORMAL slots with any remaining special types.
	for tile_type: StringName in TILE_TYPES:
		while int(counts.get(tile_type, 0)) > 0:
			for index: int in range(result.size() - 1, -1, -1):
				if result[index] == &"NORMAL" and tile_type != &"NORMAL":
					result[index] = tile_type
					counts[tile_type] = int(counts[tile_type]) - 1
					break
			if tile_type == &"NORMAL":
				break
	return result

static func _next_available(counts: Dictionary) -> StringName:
	for tile_type: StringName in TILE_TYPES:
		if int(counts.get(tile_type, 0)) > 0:
			return tile_type
	return &"NORMAL"
