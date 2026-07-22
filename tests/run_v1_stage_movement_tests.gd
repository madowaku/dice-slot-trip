extends SceneTree

const Model = preload("res://scripts/game/v1_stage_model.gd")
const Session = preload("res://scripts/game/v1_play_session.gd")
var failures := 0

func _init() -> void:
	var model = Model.new()
	_expect(model.load_bundle(), "model loads")
	_test_main_and_branch(model)
	_test_warp_exit_and_wrap(model)
	_test_bypasses_and_gate(model)
	_test_session_staging()
	print("V1_STAGE_MOVEMENT_TESTS failures=%d" % failures)
	quit(1 if failures else 0)

func _test_main_and_branch(model) -> void:
	var moved: Dictionary = model.advance("main_01", 6)
	_expect(moved.status == Model.ADVANCE_SETTLED and moved.position == "main_07" and moved.path.size() == 6, "mainline advances one hop per step")
	var paused: Dictionary = model.advance("main_09", 4)
	_expect(paused.status == Model.ADVANCE_BRANCH_REQUIRED and paused.position == "main_11" and paused.remaining == 2 and paused.path == ["main_10", "main_11"], "branch pauses mid-move with remaining steps")
	var resumed: Dictionary = model.advance(paused.position, paused.remaining, "bypass")
	_expect(resumed.status == Model.ADVANCE_SETTLED and resumed.position == "bazaar_02" and resumed.path == ["bazaar_01", "bazaar_02"], "branch choice resumes remaining hops")
	_expect(model.advance("main_11", 1, "invalid").status == Model.ADVANCE_REJECTED, "invalid branch choice is rejected atomically")

func _test_warp_exit_and_wrap(model) -> void:
	var exact_warp: Dictionary = model.advance("main_21", 1)
	_expect(exact_warp.position == "oasis_01" and exact_warp.transitions[0].type == &"WARP", "exact WARP enters loop")
	_expect(model.advance("main_21", 2).position == "main_23", "passing WARP stays on mainline")
	var exact_exit: Dictionary = model.advance("oasis_07", 1)
	_expect(exact_exit.position == "main_23" and exact_exit.transitions[0].type == &"EXIT", "exact EXIT leaves loop")
	_expect(model.advance("oasis_07", 2).position == "oasis_01", "passing EXIT wraps loop")
	_expect(model.advance("tomb_09", 1).position == "main_46", "tomb exact EXIT returns to canonical node")

func _test_bypasses_and_gate(model) -> void:
	_expect(model.advance("bazaar_03", 2).position == "main_19", "bazaar bypass merges to mainline")
	_expect(model.advance("desert_04", 2).position == "main_46", "desert bypass merges to mainline")
	var gate: Dictionary = model.advance("main_56", 6)
	_expect(gate.status == Model.ADVANCE_BOSS_GATE and gate.position == "main_58" and gate.remaining == 0 and gate.transitions[0].discarded_steps == 4, "boss gate discards surplus movement")

func _test_session_staging() -> void:
	var session = Session.new()
	session.stage_position = "main_09"
	var paused: Dictionary = session.play_stage_roll(4)
	_expect(paused.movement.status == Model.ADVANCE_BRANCH_REQUIRED and session.slot.faces().is_empty(), "session defers face commit while branch is pending")
	_expect(session.play_stage_roll(2).is_empty() and session.slot.faces().is_empty(), "roll is rejected atomically while branch is pending")
	_expect(session.choose_stage_branch("invalid").is_empty() and session.stage_position == "main_11", "rejected choice leaves pending movement unchanged")
	var settled: Dictionary = session.choose_stage_branch("bypass")
	_expect(settled.movement.position == "bazaar_02" and session.slot.faces() == [4], "face commits exactly once after resumed movement settles")
	_expect(session.choose_stage_branch("mainline").is_empty() and session.slot.faces() == [4], "settled movement cannot be committed twice")
	session.stage_position = "main_56"
	var gate: Dictionary = session.play_stage_roll(6)
	_expect(gate.movement.status == Model.ADVANCE_BOSS_GATE and session.race != null and session.slot.faces() == [4, 6], "gate starts race and preserves slot")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
