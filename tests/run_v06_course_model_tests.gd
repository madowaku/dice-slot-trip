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
	_expect(str(definition.get("course_version", "")) == "cairo_v06_90_life3_v1", "canonical course exposes the frozen 90-map version")
	_expect(definition.routes.main.size() == 90 and definition.routes.bypass_bazaar_alley.size() == 4 and definition.routes.bypass_sirocco.size() == 5 and definition.routes.loop_oasis_ring.size() == 8 and definition.routes.loop_tomb_ring.size() == 8, "Cairo route counts are 90/4/5/8/8")
	var expected_main_specials := {
		"COIN":[4, 8, 13, 18, 25, 31, 38, 46, 55, 64, 72, 80, 85],
		"REST":[11, 20, 27, 36, 49, 58, 69, 83],
		"RISK":[17, 29, 34, 41, 52, 62, 74, 87],
		"ITEM":[22, 40, 57, 75],
		"EVENT":[30, 43, 61, 77],
		"BYPASS_FORK":[32, 71],
		"WARP_OASIS":[24, 47],
		"WARP_TOMB":[66, 73],
		"WARP_GOLD":[84],
	}
	for kind: String in expected_main_specials:
		var actual: Array = (definition.routes.main as Array).filter(func(tile: Dictionary) -> bool: return str(tile.kind) == kind).map(func(tile: Dictionary) -> int: return int(tile.index))
		_expect(actual == expected_main_specials[kind], "%s exact indices remain an independent frozen set" % kind)
	_expect(model.loop_exit_indices(Course.ROUTE_LOOP_TOMB) == [0, 4] and definition.routes.loop_tomb_ring.filter(func(tile: Dictionary) -> bool: return tile.kind == "RISK").size() == 1, "tomb ring replaces its second RISK with a second EXIT")
	_expect(definition.stage.main_tile_count == 90 and definition.stage.branch_count == 2 and definition.stage.loop_count == 2 and definition.stage.warp_gate_count == 5, "Cairo metadata carries two shortcuts, five gates, and two detached rings")
	var corrupt: Dictionary = definition.duplicate(true)
	corrupt.routes.main[3].kind = "RISK"
	var bad_model: RefCounted = Course.new()
	_expect(not bad_model.load_definition(corrupt), "wrong exact kind is rejected")
	_expect(not bad_model.advance({"route_id":"main","tile_index":0}, 1).ok and bad_model.advance({"route_id":"main","tile_index":0}, 1).error == "INVALID_COURSE_DATA", "unvalidated model rejects movement")
	var moved: Dictionary = model.advance({"route_id":"main","tile_index":0}, 6)
	_expect(moved.ok and moved.position == {"route_id":"main","tile_index":6} and moved.path.size() == 6, "main movement consumes steps")
	var boosted: Dictionary = model.advance({"route_id":"main","tile_index":0}, 9)
	_expect(boosted.ok and boosted.position == {"route_id":"main","tile_index":9} and boosted.path.size() == 9, "boosted dice movement accepts one continuous path beyond six spaces")
	var required: Dictionary = model.advance({"route_id":"main","tile_index":30}, 4)
	_expect(not required.ok and required.error == "CHOICE_REQUIRED" and required.position.tile_index == 32 and required.steps_consumed == 2 and required.remaining_steps == 2, "movement reaches the Bazaar fork with every remaining step")
	_expect(model.advance({"route_id":"main","tile_index":32}, 1, "main").position.tile_index == 33, "first main choice advances to 33")
	_expect(model.advance({"route_id":"main","tile_index":32}, 1, Course.ROUTE_BYPASS_BAZAAR).position == {"route_id":"bypass_bazaar_alley","tile_index":0}, "Bazaar choice advances to its first node")
	var bazaar: Dictionary = model.advance({"route_id":"main","tile_index":32}, 5, Course.ROUTE_BYPASS_BAZAAR)
	_expect(bazaar.position == {"route_id":"main","tile_index":41} and bazaar.steps_consumed == 5, "Bazaar alley rejoins at 41 in five steps")
	var bazaar_standard: Dictionary = model.advance({"route_id":"main","tile_index":32}, 5, "main")
	_expect(bazaar_standard.position.tile_index == 37, "Bazaar shortcut saves four spaces over the main route")
	var sirocco: Dictionary = model.advance({"route_id":"main","tile_index":71}, 6, Course.ROUTE_BYPASS_SIROCCO)
	_expect(sirocco.position == {"route_id":"main","tile_index":83} and sirocco.steps_consumed == 6, "Sirocco shortcut rejoins at 83 in six steps")
	var sirocco_standard: Dictionary = model.advance({"route_id":"main","tile_index":71}, 6, "main")
	_expect(sirocco_standard.position.tile_index == 77, "Sirocco shortcut saves six spaces over the main route")
	var gates: Array[Dictionary] = model.warp_gates()
	_expect(gates.map(func(gate: Dictionary) -> int: return int(gate.main_index)) == [24, 47, 66, 73, 84], "five visible gates use the approved 90-map positions")
	var w1: Dictionary = model.advance({"route_id":"main","tile_index":23}, 1)
	_expect(w1.position == {"route_id":"loop_oasis_ring","tile_index":3} and w1.entered_warp_gate_id == "W1", "W1 exact stop warps to the five-step oasis entry")
	var used_w1: Dictionary = model.advance({"route_id":"main","tile_index":23}, 1, "", {"disabled_warp_gate_ids":["W1"]})
	_expect(used_w1.position == {"route_id":"main","tile_index":24} and used_w1.transitions.is_empty(), "used W1 behaves as NORMAL")
	var pass_w1: Dictionary = model.advance({"route_id":"main","tile_index":23}, 2)
	_expect(pass_w1.position == {"route_id":"main","tile_index":25} and pass_w1.transitions.is_empty(), "passing W1 does not warp")
	var oasis_exit: Dictionary = model.advance({"route_id":"loop_oasis_ring","tile_index":3}, 5, "", {"active_warp_gate_id":"W1"})
	_expect(oasis_exit.position == {"route_id":"main","tile_index":29} and oasis_exit.exited_warp_gate_id == "W1", "W1 oasis exit returns to 29")
	var oasis_pass: Dictionary = model.advance({"route_id":"loop_oasis_ring","tile_index":6}, 3, "", {"active_warp_gate_id":"W1"})
	_expect(oasis_pass.position == {"route_id":"loop_oasis_ring","tile_index":1} and oasis_pass.loop_wraps == 1, "passing oasis EXIT stays in the detached ring")
	var oasis_second_pass: Dictionary = model.advance({"route_id":"loop_oasis_ring","tile_index":6}, 3, "", {"active_warp_gate_id":"W1", "loop_wrap_count":1})
	_expect(oasis_second_pass.position == {"route_id":"loop_oasis_ring","tile_index":1} and not oasis_second_pass.forced_loop_exit, "second EXIT pass still preserves exact-stop play")
	var oasis_rescue: Dictionary = model.advance({"route_id":"loop_oasis_ring","tile_index":6}, 3, "", {"active_warp_gate_id":"W1", "loop_wrap_count":2})
	_expect(oasis_rescue.position == {"route_id":"main","tile_index":29} and oasis_rescue.exited_warp_gate_id == "W1" and oasis_rescue.forced_loop_exit, "third EXIT pass forces the W1 rescue return")
	var w2: Dictionary = model.advance({"route_id":"main","tile_index":46}, 1)
	var w2_exit: Dictionary = model.advance(w2.position, 3, "", {"active_warp_gate_id":"W2"})
	_expect(w2.position.tile_index == 5 and w2_exit.position == {"route_id":"main","tile_index":60}, "W2 reuses oasis geometry and returns to 60")
	var w3: Dictionary = model.advance({"route_id":"main","tile_index":65}, 1)
	var w3_exit: Dictionary = model.advance(w3.position, 5, "", {"active_warp_gate_id":"W3"})
	var w3_alternate_exit: Dictionary = model.advance(w3.position, 1, "", {"active_warp_gate_id":"W3"})
	_expect(w3.position == {"route_id":"loop_tomb_ring","tile_index":3} and w3_exit.position == {"route_id":"main","tile_index":88}, "tomb primary EXIT returns to 88")
	_expect(w3_alternate_exit.position == {"route_id":"main","tile_index":76} and int(w3_alternate_exit.transitions.back().exit_index) == 4, "tomb alternate EXIT returns to 76")
	var w4: Dictionary = model.advance({"route_id":"main","tile_index":72}, 1)
	var w4_exit: Dictionary = model.advance(w4.position, 3, "", {"active_warp_gate_id":"W4"})
	_expect(w4.position.tile_index == 5 and w4_exit.position == {"route_id":"main","tile_index":88}, "W4 reaches the same boss-side primary EXIT")
	var w5: Dictionary = model.advance({"route_id":"main","tile_index":83}, 1)
	var w5_exit: Dictionary = model.advance(w5.position, 6, "", {"active_warp_gate_id":"W5"})
	_expect(w5.position.tile_index == 2 and w5_exit.position == {"route_id":"main","tile_index":88}, "gold W5 at 84 uses its special tomb entry and returns to 88")
	_expect(model.steps_to_exit({"route_id":"loop_oasis_ring","tile_index":3}) == 5 and model.steps_to_exit({"route_id":"loop_tomb_ring","tile_index":5}) == 3 and model.steps_to_exit({"route_id":"loop_tomb_ring","tile_index":3}) == 1, "each ring reports its nearest exact-stop EXIT distance")
	var boss: Dictionary = model.advance({"route_id":"main","tile_index":87}, 6)
	_expect(boss.ok and boss.status == "BOSS_GATE_REACHED" and boss.position.tile_index == 89 and boss.steps_consumed == 2 and boss.remaining_steps == 4 and boss.boss_gate_reached, "data-driven boss gate discards reported surplus")
	_expect(model.advance({"route_id":"main","tile_index":89}, 1).error == "AT_BOSS_GATE", "cannot advance from data-driven boss gate")
	_test_atomic_errors()
	print("V06_COURSE_MODEL_TESTS failures=%d" % failures)
	quit(1 if failures else 0)

func _test_atomic_errors() -> void:
	var cases: Array = [
		[[], 2, "", "INVALID_POSITION_SHAPE"],
		[{"route_id":"wat","tile_index":0}, 2, "", "UNKNOWN_ROUTE"],
		[{"route_id":"main","tile_index":90}, 2, "", "INDEX_OUT_OF_RANGE"],
		[{"route_id":"main","tile_index":1}, 0, "", "INVALID_DISTANCE"],
		[{"route_id":"main","tile_index":1}, 2, "wrong", "INVALID_ROUTE_CHOICE"],
		[{"route_id":"main","tile_index":1}, 2, "main", "UNEXPECTED_ROUTE_CHOICE"],
		[{"route_id":"main","tile_index":24}, 2, "", "TRANSIENT_POSITION"],
		[{"route_id":"loop_oasis_ring","tile_index":0}, 2, "", "TRANSIENT_POSITION"]]
	for item: Array in cases:
		var original: Variant = item[0].duplicate(true)
		var result: Dictionary = model.advance(item[0], item[1], item[2])
		_expect(not result.ok and result.error == item[3] and result.steps_consumed == 0 and result.path.is_empty() and item[0] == original, "atomic error %s" % item[3])

func _expect(condition: bool, label: String) -> void:
	if condition: print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
