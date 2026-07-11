class_name DiceLogic
extends RefCounted

const MAIN_NONE: StringName = &""
const PAIR: StringName = &"PAIR"
const STRAIGHT: StringName = &"STRAIGHT"
const TRIPLE: StringName = &"TRIPLE"
const ALL_ODD: StringName = &"ALL ODD"
const ALL_EVEN: StringName = &"ALL EVEN"

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

