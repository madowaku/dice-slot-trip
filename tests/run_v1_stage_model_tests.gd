extends SceneTree

const Parser = preload("res://tools/v1_yaml_subset.gd")
const StageModel = preload("res://scripts/game/v1_stage_model.gd")
var assertions := 0
var failures := 0

func _init() -> void:
	var model = StageModel.new()
	_check(model.load_bundle(), "canonical generated bundle validates: %s" % [model.errors])
	_check(model.stage.nodes.size() == 85, "full stage tree has 85 nodes")
	_check(model.boss.course.size() == 13, "full boss course has 13 positions")
	_check(model.stage.nodes.main_58.type == "BOSS_GATE", "terminal node retained")
	_check(model.boss.dice_rules.boss_roll_formula == "7 - effective_player_roll", "formula retained verbatim")
	var parser = Parser.new()
	_check(parser.parse("a: 1\na: 2\n") == null and parser.error_message.begins_with("line 2:"), "duplicate key rejected with line")
	parser = Parser.new()
	_check(parser.parse("a:\n   b: 1\n") == null and parser.error_message.begins_with("line 2:"), "ambiguous indentation rejected with line")
	parser = Parser.new()
	_check(parser.parse("a: [1, 2]\n") == null and parser.error_message.begins_with("line 1:"), "unsupported flow sequence rejected")
	print("V1 stage model tests: %d assertions, failures=%d" % [assertions, failures])
	quit(1 if failures else 0)

func _check(condition: bool, label: String) -> void:
	assertions += 1
	if condition: print("PASS: ", label)
	else: failures += 1; printerr("FAIL: ", label)
