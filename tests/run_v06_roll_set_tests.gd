extends SceneTree

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")

var failures: int = 0

func _init() -> void:
	var roll_set: RefCounted = V06RollSetScript.new()
	_expect(roll_set.faces().is_empty() and not roll_set.is_complete(), "new set is empty")
	_expect(roll_set.evaluate_role() == &"", "empty set has no role")
	_expect(not roll_set.append_face(0) and not roll_set.append_face(7), "invalid faces are rejected")
	_expect(roll_set.faces().is_empty(), "invalid faces do not mutate the set")
	_expect(roll_set.append_face(2) and roll_set.evaluate_role() == &"", "roll one is incomplete")
	_expect(roll_set.append_face(2) and roll_set.evaluate_role() == &"", "roll two is incomplete even when equal")
	_expect(not roll_set.reset_after_resolution() and roll_set.faces() == [2, 2], "incomplete reset is deterministic")
	_expect(roll_set.append_face(5) and roll_set.evaluate_role() == V06RollSetScript.ROLE_PAIR, "exactly two equal faces make PAIR")
	_expect(roll_set.is_complete() and roll_set.faces() == [2, 2, 5], "completed set remains readable")
	_expect(not roll_set.append_face(6) and roll_set.faces() == [2, 2, 5], "fourth append is rejected without mutation")
	var snapshot: Array[int] = roll_set.faces()
	snapshot[0] = 6
	_expect(roll_set.faces() == [2, 2, 5], "readable faces cannot mutate internal state")
	_expect(roll_set.reset_after_resolution() and roll_set.faces().is_empty(), "explicit resolution reset clears a complete set")
	_expect(not roll_set.reset_after_resolution() and roll_set.faces().is_empty(), "double reset is deterministic")
	for face: int in [4, 4, 4]:
		_expect(roll_set.append_face(face), "TRIPLE face appends")
	_expect(roll_set.evaluate_role() == V06RollSetScript.ROLE_TRIPLE, "TRIPLE has priority")
	_expect(roll_set.reset_after_resolution(), "TRIPLE resets")
	for face: int in [1, 2, 3]:
		_expect(roll_set.append_face(face), "distinct face appends")
	_expect(roll_set.evaluate_role() == V06RollSetScript.ROLE_NONE, "distinct consecutive faces are NONE, not STRAIGHT")
	_expect(roll_set.reset_after_resolution(), "NONE resets")
	var pair_permutations: Array[Array] = [[6, 1, 6], [3, 5, 5]]
	for values: Array in pair_permutations:
		for face: int in values:
			_expect(roll_set.append_face(face), "PAIR permutation face appends")
		_expect(roll_set.evaluate_role() == V06RollSetScript.ROLE_PAIR, "PAIR works in every slot position")
		_expect(roll_set.reset_after_resolution(), "PAIR permutation resets")
	print("V06_ROLL_SET_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
