class_name DiceLogic
extends RefCounted

const MAIN_NONE: StringName = &""
const DOUBLE: StringName = &"DOUBLE"
const PAIR: StringName = &"PAIR"
const STRAIGHT: StringName = &"STRAIGHT"
const TRIPLE: StringName = &"TRIPLE"
const ALL_ODD: StringName = &"ALL ODD"
const ALL_EVEN: StringName = &"ALL EVEN"
const FIVE_OF_A_KIND: StringName = &"FIVE_OF_A_KIND"

static func evaluate(values: Array[int]) -> Dictionary:
	if values.size() != 3:
		return {"main": MAIN_NONE, "support": MAIN_NONE, "labels": []}
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	var main: StringName = MAIN_NONE
	if sorted[0] == sorted[2]:
		main = TRIPLE
	elif sorted[1] == sorted[0] + 1 and sorted[2] == sorted[1] + 1:
		main = STRAIGHT
	elif sorted[0] == sorted[1] or sorted[1] == sorted[2]:
		main = PAIR
	var support: StringName = MAIN_NONE
	if values.all(func(value: int) -> bool: return value % 2 == 1):
		support = ALL_ODD
	elif values.all(func(value: int) -> bool: return value % 2 == 0):
		support = ALL_EVEN
	var labels: Array[StringName] = []
	if main != MAIN_NONE:
		labels.append(main)
	if support != MAIN_NONE:
		labels.append(support)
	return {"main": main, "support": support, "labels": labels}

static func evaluate_unlocked(values: Array[int], unlocked_dice_count: int) -> Dictionary:
	# Kept as the compatibility entry point for callers from the v4 progression
	# slice. The second argument is now the temporary current dice count.
	return evaluate_current(values, unlocked_dice_count)

static func evaluate_current(values: Array[int], current_dice_count: int) -> Dictionary:
	if current_dice_count == 2 and values.size() == 2:
		if values[0] == values[1]:
			return {"main": DOUBLE, "support": MAIN_NONE, "labels": [DOUBLE]}
		return {"main": MAIN_NONE, "support": MAIN_NONE, "labels": []}
	if current_dice_count == 3 and values.size() == 3:
		return evaluate(values)
	return {"main": MAIN_NONE, "support": MAIN_NONE, "labels": []}

static func next_dice_state(rolled_dice_count: int, roles: Dictionary, dice_keep_active: bool = false, double_retry_active: bool = false, slot_retry_active: bool = false) -> Dictionary:
	var current := clampi(rolled_dice_count, 1, 3)
	# One-die travel and temporary festival/extra rolls do not consume or grow
	# the base state. Callers identify temporary rolls with a count outside 1..3.
	if rolled_dice_count not in [1, 2, 3]:
		return {"count": current, "consume_keep": false, "consume_double_retry": false, "consume_slot_retry": false, "slot_continues": false}
	var main: StringName = roles.get("main", MAIN_NONE)
	var support: StringName = roles.get("support", MAIN_NONE)
	var natural_next := 1
	if rolled_dice_count == 2:
		natural_next = 3 if main == DOUBLE else 1
	elif rolled_dice_count == 3:
		if main == TRIPLE:
			natural_next = 3
		elif main in [PAIR, STRAIGHT] or (main == MAIN_NONE and support == ALL_EVEN):
			natural_next = 2

	var result := {"count": natural_next, "consume_keep": false, "consume_double_retry": false, "consume_slot_retry": false, "slot_continues": rolled_dice_count == 3 and natural_next == 3}
	if natural_next >= rolled_dice_count:
		return result
	# DICE_KEEP is the strongest hold: it prevents the whole decrease. Dedicated
	# retry flags are only considered when KEEP did not already preserve the roll.
	if dice_keep_active:
		result.count = rolled_dice_count
		result.consume_keep = true
		return result
	if rolled_dice_count == 2 and double_retry_active:
		result.count = 2
		result.consume_double_retry = true
	elif rolled_dice_count == 3 and natural_next == 1 and slot_retry_active:
		result.count = 2
		result.consume_slot_retry = true
	return result

static func recommended_indices(values: Array[int]) -> Array[int]:
	if values.size() < 3:
		return []
	var best_indices: Array[int] = [0, 1, 2]
	var best_score: int = -1
	for first: int in range(values.size() - 2):
		for second: int in range(first + 1, values.size() - 1):
			for third: int in range(second + 1, values.size()):
				var pick: Array[int] = [values[first], values[second], values[third]]
				var roles: Dictionary = evaluate(pick)
				var role_score: int = role_priority(roles.get("main", MAIN_NONE)) * 100
				if roles.get("support", MAIN_NONE) != MAIN_NONE:
					role_score += 25
				role_score += pick[0] + pick[1] + pick[2]
				if role_score > best_score:
					best_score = role_score
					best_indices = [first, second, third]
	return best_indices

static func role_priority(role: StringName) -> int:
	match role:
		TRIPLE: return 3
		STRAIGHT: return 2
		PAIR: return 1
		_: return 0

static func roll_many(rng: RandomNumberGenerator, count: int, fixed: Array[int] = []) -> Array[int]:
	var result: Array[int] = []
	for index: int in range(count):
		if index < fixed.size():
			result.append(clampi(fixed[index], 1, 6))
		else:
			result.append(rng.randi_range(1, 6))
	return result

static func evaluate_many(values: Array[int]) -> Dictionary:
	var labels: Array[StringName] = []
	if values.size() == 5 and values.all(func(value: int) -> bool: return value == values[0]):
		labels.append(FIVE_OF_A_KIND)
	var counts: Dictionary = {}
	for value: int in values:
		counts[value] = int(counts.get(value, 0)) + 1
	if counts.values().any(func(count: Variant) -> bool: return int(count) >= 3):
		labels.append(TRIPLE)
	elif counts.values().any(func(count: Variant) -> bool: return int(count) >= 2):
		labels.append(PAIR)
	var unique: Array[int] = []
	for value: Variant in counts.keys(): unique.append(int(value))
	unique.sort()
	for start: int in range(maxi(0, unique.size() - 2)):
		if unique[start + 1] == unique[start] + 1 and unique[start + 2] == unique[start] + 2:
			labels.append(STRAIGHT)
			break
	if values.all(func(value: int) -> bool: return value % 2 == 1): labels.append(ALL_ODD)
	elif values.all(func(value: int) -> bool: return value % 2 == 0): labels.append(ALL_EVEN)
	return {"labels": labels, "type_count": labels.size(), "five_of_a_kind": FIVE_OF_A_KIND in labels}
