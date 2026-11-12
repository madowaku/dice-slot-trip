extends RefCounted

## Trip dice: casino prizes that change how a journey is played.
##
## Each die is six face values plus copy for what it gives and what it costs.
## None is strictly better than the normal die. In Kyoto the die keeps the
## timing-based roll: the spinning face cycles through the die's own values,
## interleaved so the same value never shows twice in a row (1,6,1,6,1,6 for
## 1,1,1,6,6,6), which keeps a stop exactly as hard as on the normal die.
##
## Pure data and rules only; the screens own presentation and CasinoBank owns
## ownership and the equipped die.

const DATA_PATH := "res://data/casino/trip_dice.json"
const DICE_PRESENTATION := preload("res://scripts/game/dice_presentation_3d.gd")
const DEFAULT_USES_PER_LAP := 3
const FLAG_LAP := "trip_die_lap"
const FLAG_USED := "trip_die_used"
const FLAG_ARMED := "trip_die_armed"


static func _parse() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed as Dictionary if parsed is Dictionary else {}


static func uses_per_lap() -> int:
	return maxi(1, int(_parse().get("uses_per_lap", DEFAULT_USES_PER_LAP)))


## Valid dice only, in authored order. Faces become an Array[int].
static func catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in _parse().get("dice", []):
		if not value is Dictionary:
			continue
		var entry: Dictionary = (value as Dictionary).duplicate(true)
		var faces := normalize_faces(entry.get("faces", []))
		if str(entry.get("id", "")).is_empty() or faces.is_empty() or int(entry.get("price", 0)) <= 0:
			continue
		entry["faces"] = faces
		entry["price"] = int(entry.get("price", 0))
		result.append(entry)
	return result


static func find(die_id: String) -> Dictionary:
	for entry: Dictionary in catalog():
		if str(entry.get("id", "")) == die_id:
			return entry
	return {}


static func normalize_faces(source: Variant) -> Array[int]:
	var faces: Array[int] = []
	if not source is Array or (source as Array).size() != 6:
		return faces
	for value: Variant in source as Array:
		if not (value is int or value is float) or int(value) < 1 or int(value) > 6:
			var empty: Array[int] = []
			return empty
		faces.append(int(value))
	return faces


## The order the faces show while the die spins: distinct values round-robin,
## so a value never repeats back to back.
static func carousel_order(faces: Array[int]) -> Array[int]:
	var buckets: Dictionary = {}
	var order_of_values: Array[int] = []
	for value: int in faces:
		if not buckets.has(value):
			buckets[value] = 0
			order_of_values.append(value)
		buckets[value] = int(buckets[value]) + 1
	order_of_values.sort()
	var result: Array[int] = []
	while result.size() < faces.size():
		for value: int in order_of_values:
			if int(buckets[value]) > 0:
				result.append(value)
				buckets[value] = int(buckets[value]) - 1
	return result


## The face shown at a point of the spin, on the same clock as the normal die.
static func face_for_elapsed(faces: Array[int], elapsed: float) -> int:
	var order := carousel_order(faces)
	if order.size() != 6:
		return DICE_PRESENTATION.rolling_face_for_elapsed(elapsed)
	return order[DICE_PRESENTATION.rolling_face_for_elapsed(elapsed) - 1]


static func roll(faces: Array[int], rng: RandomNumberGenerator) -> int:
	return faces[rng.randi_range(0, faces.size() - 1)] if faces.size() == 6 else rng.randi_range(1, 6)


static func average(faces: Array[int]) -> float:
	var total := 0
	for value: int in faces:
		total += value
	return float(total) / float(maxi(1, faces.size()))


static func distinct_values(faces: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value: int in carousel_order(faces):
		if value not in result:
			result.append(value)
	return result


# ---- per-lap use counter, kept in a journey's stage_flags ---------------

static func uses_left(stage_flags: Dictionary, lap: int) -> int:
	if int(stage_flags.get(FLAG_LAP, lap)) != lap:
		return uses_per_lap()
	return maxi(0, uses_per_lap() - int(stage_flags.get(FLAG_USED, 0)))


## Spend one use. Returns false (and changes nothing) when none are left.
static func consume_use(stage_flags: Dictionary, lap: int) -> bool:
	if uses_left(stage_flags, lap) <= 0:
		return false
	var used := int(stage_flags.get(FLAG_USED, 0)) if int(stage_flags.get(FLAG_LAP, lap)) == lap else 0
	stage_flags[FLAG_LAP] = lap
	stage_flags[FLAG_USED] = used + 1
	if uses_left(stage_flags, lap) <= 0:
		stage_flags[FLAG_ARMED] = false
	return true


static func is_armed(stage_flags: Dictionary, lap: int) -> bool:
	return bool(stage_flags.get(FLAG_ARMED, false)) and uses_left(stage_flags, lap) > 0


static func set_armed(stage_flags: Dictionary, armed: bool) -> void:
	stage_flags[FLAG_ARMED] = armed
