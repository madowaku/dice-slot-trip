extends SceneTree

const Course = preload("res://scripts/game/v06_course_model.gd")
var failures: int = 0
var model: RefCounted

func _init() -> void:
	model = Course.new()
	var loaded: bool = model.load_file("res://data/stages/v06_cairo_course.json")
	_expect(loaded, "canonical course validates")
	if not loaded:
		print("validation_error=%s" % model.validation_error)
		quit(1)
		return
	var definition: Dictionary = model.definition()
	_expect(definition.routes.main.size() == 58 and definition.routes.bypass_sirocco.size() == 4 and definition.routes.loop_souk_ring.size() == 8, "v0.7 route counts are 58/4/8")
	_expect(definition.stage.main_tile_count == 58 and definition.stage.expected_minutes == "8〜10分" and definition.stage.branch_count == 1 and definition.stage.loop_count == 1, "Cairo stage metadata carries length and pacing")
	var corrupt: Dictionary = definition.duplicate(true)
	corrupt.routes.main[3].kind = "RISK"
	var bad_model: RefCounted = Course.new()
	_expect(not bad_model.load_definition(corrupt), "wrong exact kind is rejected")
	_expect(not bad_model.advance({"route_id":"main","tile_index":0}, 1).ok and bad_model.advance({"route_id":"main","tile_index":0}, 1).error == "INVALID_COURSE_DATA", "unvalidated model rejects movement")
	var moved: Dictionary = model.advance({"route_id":"main","tile_index":0}, 6)
	_expect(moved.ok and moved.position == {"route_id":"main","tile_index":6} and moved.path.size() == 6, "main movement consumes steps")
	var required: Dictionary = model.advance({"route_id":"main","tile_index":10}, 4)
	_expect(not required.ok and required.error == "CHOICE_REQUIRED" and required.position.tile_index == 12 and required.steps_consumed == 2 and required.remaining_steps == 2, "choice is required only when leaving fork")
	_expect(model.advance({"route_id":"main","tile_index":12}, 1, "main").position.tile_index == 13, "main choice advances to 13")
	_expect(model.advance({"route_id":"main","tile_index":12}, 1, "bypass_sirocco").position == {"route_id":"bypass_sirocco","tile_index":0}, "bypass choice advances to bypass zero")
	var bypass: Dictionary = model.advance({"route_id":"main","tile_index":12}, 5, "bypass_sirocco")
	_expect(bypass.position == {"route_id":"main","tile_index":20} and bypass.steps_consumed == 5, "bypass rejoins in five steps")
	var standard: Dictionary = model.advance({"route_id":"main","tile_index":12}, 6, "main")
	_expect(standard.position.tile_index == 18, "standard remains three steps behind bypass")
	var portal: Dictionary = model.advance({"route_id":"main","tile_index":21}, 1)
	_expect(portal.position == {"route_id":"loop_souk_ring","tile_index":0} and portal.transitions.size() == 1, "exact portal landing transfers")
	var pass_portal: Dictionary = model.advance({"route_id":"main","tile_index":21}, 2)
	_expect(pass_portal.position == {"route_id":"main","tile_index":23} and pass_portal.transitions.is_empty(), "passing portal does not transfer")
	var wrapped: Dictionary = model.advance({"route_id":"loop_souk_ring","tile_index":6}, 3)
	_expect(wrapped.position.tile_index == 1 and wrapped.loop_wraps == 1, "loop wraps")
	var exit: Dictionary = model.advance({"route_id":"loop_souk_ring","tile_index":0}, 4)
	_expect(exit.position == {"route_id":"main","tile_index":23}, "exact stop exits loop")
	var pass_exit: Dictionary = model.advance({"route_id":"loop_souk_ring","tile_index":2}, 4)
	_expect(pass_exit.position == {"route_id":"loop_souk_ring","tile_index":6}, "passing exit stays in loop")
	_expect(model.steps_to_exit({"route_id":"loop_souk_ring","tile_index":0}) == 4 and model.steps_to_exit({"route_id":"loop_souk_ring","tile_index":5}) == 7, "steps to exit uses ring distance")
	var boss: Dictionary = model.advance({"route_id":"main","tile_index":55}, 6)
	_expect(boss.ok and boss.status == "BOSS_GATE_REACHED" and boss.position.tile_index == 57 and boss.steps_consumed == 2 and boss.remaining_steps == 4 and boss.boss_gate_reached, "data-driven boss gate discards reported surplus")
	_expect(model.advance({"route_id":"main","tile_index":57}, 1).error == "AT_BOSS_GATE", "cannot advance from data-driven boss gate")
	_test_atomic_errors()
	print("V06_COURSE_MODEL_TESTS failures=%d" % failures)
	quit(1 if failures else 0)

func _test_atomic_errors() -> void:
	var cases: Array = [
		[[], 2, "", "INVALID_POSITION_SHAPE"],
		[{"route_id":"wat","tile_index":0}, 2, "", "UNKNOWN_ROUTE"],
		[{"route_id":"main","tile_index":58}, 2, "", "INDEX_OUT_OF_RANGE"],
		[{"route_id":"main","tile_index":1}, 0, "", "INVALID_DISTANCE"],
		[{"route_id":"main","tile_index":1}, 2, "wrong", "INVALID_ROUTE_CHOICE"],
		[{"route_id":"main","tile_index":1}, 2, "main", "UNEXPECTED_ROUTE_CHOICE"],
		[{"route_id":"main","tile_index":22}, 2, "", "TRANSIENT_POSITION"]]
	for item: Array in cases:
		var original: Variant = item[0].duplicate(true)
		var result: Dictionary = model.advance(item[0], item[1], item[2])
		_expect(not result.ok and result.error == item[3] and result.steps_consumed == 0 and result.path.is_empty() and item[0] == original, "atomic error %s" % item[3])

func _expect(condition: bool, label: String) -> void:
	if condition: print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
