extends SceneTree

const RulesScript = preload("res://scripts/game/vault_break/vault_break_rules.gd")
const RepositoryScript = preload("res://scripts/game/vault_break/vault_break_template_repository.gd")
const SelectorScript = preload("res://scripts/game/vault_break/vault_break_selector.gd")
const ProgressScript = preload("res://scripts/game/vault_break/vault_break_progress.gd")
const ModelScript = preload("res://scripts/game/vault_break/vault_break_model.gd")

const EXPECTED_TEMPLATES := {
	"B01": ["bronze", "partition_exact", 5, ["low", "high", "exact:6"]],
	"B02": ["bronze", "partition_exact", 5, ["low", "high", "exact:1"]],
	"B03": ["bronze", "partition_exact", 5, ["low", "high", "exact:3"]],
	"B04": ["bronze", "parity_exact", 5, ["odd", "even", "exact:2"]],
	"B05": ["bronze", "parity_exact", 5, ["odd", "even", "exact:4"]],
	"B06": ["bronze", "parity_exact", 5, ["odd", "even", "exact:5"]],
	"B07": ["bronze", "mixed_overlap", 5, ["low", "even", "exact:5"]],
	"B08": ["bronze", "mixed_overlap", 5, ["high", "odd", "exact:2"]],
	"S01": ["silver", "triple_overlap", 5, ["low", "high", "odd", "exact:1"]],
	"S02": ["silver", "triple_overlap", 5, ["low", "high", "even", "exact:6"]],
	"S03": ["silver", "triple_overlap", 5, ["low", "odd", "even", "exact:3"]],
	"S04": ["silver", "triple_overlap", 5, ["high", "odd", "even", "exact:4"]],
	"S05": ["silver", "double_edge", 5, ["low", "high", "edge", "edge"]],
	"S06": ["silver", "double_edge", 5, ["odd", "even", "edge", "edge"]],
	"S07": ["silver", "exact_overlap", 5, ["low", "high", "odd", "exact:5"]],
	"S08": ["silver", "exact_overlap", 5, ["low", "high", "even", "exact:2"]],
	"G01": ["gold", "double_exact", 6, ["high", "even", "exact:2", "exact:6"]],
	"G02": ["gold", "double_exact", 6, ["low", "odd", "exact:1", "exact:5"]],
	"G03": ["gold", "split_exact", 6, ["low", "odd", "exact:2", "exact:5"]],
	"G04": ["gold", "split_exact", 6, ["high", "even", "exact:2", "exact:5"]],
	"G05": ["gold", "edge_double_exact", 6, ["high", "edge", "exact:1", "exact:3"]],
	"G06": ["gold", "edge_double_exact", 6, ["low", "edge", "exact:5", "exact:6"]],
	"G07": ["gold", "edge_double_exact", 6, ["odd", "edge", "exact:2", "exact:6"]],
	"G08": ["gold", "edge_double_exact", 6, ["even", "edge", "exact:1", "exact:5"]],
	"K01": ["black", "exact_triple", 5, ["exact:1", "exact:2", "exact:3"]],
	"K02": ["black", "exact_triple", 5, ["exact:4", "exact:5", "exact:6"]],
	"K03": ["black", "exact_triple", 5, ["exact:1", "exact:3", "exact:5"]],
	"K04": ["black", "exact_triple", 5, ["exact:2", "exact:4", "exact:6"]],
	"K05": ["black", "exact_triple", 5, ["exact:1", "exact:2", "exact:6"]],
	"K06": ["black", "exact_triple", 5, ["exact:3", "exact:4", "exact:5"]],
}

var failures := 0
var assertions := 0
var repository: RefCounted

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	repository = RepositoryScript.new()
	_expect(bool(repository.call("load_default")), "canonical JSON loads and validates")
	_test_repository_data()
	_test_lock_and_reward_rules()
	_test_game_model()
	_test_active_game_snapshot_restore()
	_test_unlocks_and_first_plays()
	_test_selection_guards_and_fallbacks()
	_test_weighted_selection()
	_test_black_lifecycle_and_serialization()
	print("VAULT BREAK tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _test_repository_data() -> void:
	_expect(bool(repository.call("is_loaded")), "repository reports its complete v1 data as loaded")
	var templates_by_id: Dictionary = repository.get("templates_by_id") as Dictionary
	_expect(templates_by_id.size() == 30, "repository indexes exactly 30 templates")
	var expected_counts := {"bronze": 8, "silver": 8, "gold": 8, "black": 6}
	var expected_config := {
		"bronze": [3, 5, 1.7, "B01"],
		"silver": [4, 5, 2.2, "S05"],
		"gold": [4, 6, 3.0, "G01"],
		"black": [3, 5, 5.5, "K01"],
	}
	for tier: String in expected_counts:
		var tier_templates: Array = repository.call("get_templates_for_tier", tier) as Array
		_expect(tier_templates.size() == int(expected_counts[tier]), "%s has the authored template count" % tier)
		var config: Dictionary = repository.call("get_tier_config", tier) as Dictionary
		var values: Array = expected_config[tier] as Array
		_expect(int(config.get("lock_count", 0)) == int(values[0]), "%s lock count is configured" % tier)
		_expect(int(config.get("max_rolls", 0)) == int(values[1]), "%s roll limit is configured" % tier)
		_expect(is_equal_approx(float(config.get("payout_multiplier", 0.0)), float(values[2])), "%s multiplier is configured" % tier)
		_expect(str(config.get("first_template", "")) == str(values[3]), "%s first template is configured" % tier)

	for template_id: String in EXPECTED_TEMPLATES:
		var expected: Array = EXPECTED_TEMPLATES[template_id] as Array
		var template: Dictionary = repository.call("get_template", template_id) as Dictionary
		_expect(not template.is_empty(), "%s exists" % template_id)
		_expect(str(template.get("tier", "")) == str(expected[0]), "%s tier matches" % template_id)
		_expect(str(template.get("structure_group", "")) == str(expected[1]), "%s structure group matches" % template_id)
		_expect(int(template.get("max_rolls", 0)) == int(expected[2]), "%s roll limit matches" % template_id)
		_expect(float(template.get("weight", 0.0)) > 0.0, "%s has a positive weight" % template_id)
		var locks: Array = template.get("locks", []) as Array
		_expect(locks.size() == (expected[3] as Array).size(), "%s lock count matches" % template_id)
		_expect(_lock_signatures(locks) == (expected[3] as Array), "%s exact lock table matches" % template_id)
		if str(template.get("tier", "")) == "black":
			_expect(_all_exact(locks), "%s is exact-only" % template_id)

	var invalid_data: Dictionary = (repository.get("source_data") as Dictionary).duplicate(true)
	var invalid_templates: Array = invalid_data.get("templates", []) as Array
	(invalid_templates[1] as Dictionary)["id"] = "B01"
	(invalid_templates[2] as Dictionary)["weight"] = 0.0
	var invalid_repository: RefCounted = RepositoryScript.new()
	_expect(not bool(invalid_repository.call("load_from_data", invalid_data)), "duplicate ids and non-positive weights reject the whole dataset")
	var errors: Array = invalid_repository.get("validation_errors") as Array
	_expect(not errors.is_empty(), "invalid repository exposes validation evidence")

func _test_lock_and_reward_rules() -> void:
	var accepted := {
		"low": [1, 2, 3],
		"high": [4, 5, 6],
		"odd": [1, 3, 5],
		"even": [2, 4, 6],
		"edge": [1, 6],
	}
	for rule_name: String in accepted:
		for face: int in range(1, 7):
			var expected := face in (accepted[rule_name] as Array)
			_expect(RulesScript.accepts_face({"rule": rule_name}, face) == expected, "%s face %d acceptance" % [rule_name, face])
	for exact_value: int in range(1, 7):
		for face: int in range(1, 7):
			_expect(RulesScript.accepts_face({"rule": "exact", "value": exact_value}, face) == (face == exact_value), "EXACT%d face %d acceptance" % [exact_value, face])
	_expect(not RulesScript.accepts_face({"rule": "unknown"}, 1), "unknown rule is rejected")
	_expect(not RulesScript.accepts_face({"rule": "exact"}, 1), "exact rule without a value is rejected")
	_expect(not RulesScript.accepts_face({"rule": "low"}, 0) and not RulesScript.accepts_face({"rule": "high"}, 7), "out-of-d6 faces are rejected")

	var payout_cases := {
		"bronze": [1.7, [17, 34, 85]],
		"silver": [2.2, [22, 44, 110]],
		"gold": [3.0, [30, 60, 150]],
		"black": [5.5, [55, 110, 275]],
	}
	for tier: String in payout_cases:
		var payout_case: Array = payout_cases[tier] as Array
		var expected_rewards: Array = payout_case[1] as Array
		for index: int in RulesScript.BET_OPTIONS.size():
			var bet_amount: int = RulesScript.BET_OPTIONS[index]
			_expect(RulesScript.reward_for_bet(bet_amount, float(payout_case[0])) == int(expected_rewards[index]), "%s BET%d reward is floored" % [tier, bet_amount])
	_expect(RulesScript.reward_for_bet(19, 1.7) == 32, "reward uses floor for non-integral products")
	_expect(RulesScript.is_valid_bet(10) and RulesScript.is_valid_bet(20) and RulesScript.is_valid_bet(50), "all authored BET values are valid")
	_expect(not RulesScript.is_valid_bet(5), "non-authored BET is invalid")

func _test_game_model() -> void:
	var model: RefCounted = ModelScript.new()
	model.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	var b01: Dictionary = repository.call("get_template", "B01") as Dictionary
	_expect(bool(model.call("start", b01, 20, 1.7)), "game starts from SETUP")
	_expect(int(model.get("state")) == ModelScript.State.READY and int(model.get("rolls_used")) == 0, "start enters READY with zero rolls")
	_expect((model.call("get_placed_faces") as Array) == [0, 0, 0], "start exposes all locks empty")
	_expect(int(model.call("begin_roll", 6)) == 6 and int(model.get("state")) == ModelScript.State.ROLLING, "explicit face enters ROLLING")
	_expect(int(model.get("rolls_used")) == 1, "roll increments exactly once")
	_expect(int(model.call("begin_roll", 1)) == 0 and int(model.get("rolls_used")) == 1, "ROLLING blocks double roll")
	var targets: Array = model.call("resolve_rolled_die") as Array
	_expect(targets == [1, 2] and int(model.get("state")) == ModelScript.State.WAITING_FOR_PLACEMENT, "all valid empty locks are exposed")
	_expect(bool(model.call("place_current_die", 2)), "rolled 6 can fill E6")
	_expect(int(model.call("get_lock_face", 2)) == 6 and int(model.get("state")) == ModelScript.State.READY, "placement returns to READY")
	model.call("begin_roll", 6)
	var targets2: Array = model.call("resolve_rolled_die") as Array
	_expect(targets2 == [1], "filled exact lock is excluded from later targets")
	_expect(not bool(model.call("place_current_die", 2)), "filled lock cannot be overwritten")
	_expect(int(model.call("get_lock_face", 2)) == 6 and int(model.get("state")) == ModelScript.State.WAITING_FOR_PLACEMENT, "failed overwrite preserves immutable placement and pending face")
	_expect(bool(model.call("place_current_die", 1)), "pending face remains placeable after invalid target")
	model.call("begin_roll", 1)
	model.call("resolve_rolled_die")
	_expect(bool(model.call("place_current_die", 0)), "last bronze lock accepts LOW face")
	_expect(int(model.get("state")) == ModelScript.State.SUCCESS and int(model.get("reward")) == 34, "success pays floor(BET x multiplier) with wager already external")
	_expect(int(model.call("begin_roll", 1)) == 0, "SUCCESS blocks further rolls")
	var copied_faces: Array = model.call("get_placed_faces") as Array
	copied_faces[0] = 6
	_expect(int(model.call("get_lock_face", 0)) == 1, "placed-die getter cannot mutate model state")
	_expect(bool(model.call("advance_to_result")) and int(model.get("state")) == ModelScript.State.RESULT, "SUCCESS advances explicitly to RESULT")
	_expect(bool(model.call("reset_to_setup")) and int(model.get("state")) == ModelScript.State.SETUP, "RESULT can reset to SETUP")
	_expect(bool(model.call("exit_game")) and int(model.get("state")) == ModelScript.State.EXITING, "SETUP can exit")

	var discard_model: RefCounted = ModelScript.new()
	_expect(bool(discard_model.call("start", b01, 10, 1.7)), "manual-discard game starts")
	discard_model.call("begin_roll", 6)
	discard_model.call("resolve_rolled_die")
	_expect(bool(discard_model.call("discard_current_die")), "manual discard is allowed despite valid targets")
	_expect(int(discard_model.get("state")) == ModelScript.State.READY and int(discard_model.get("discard_count")) == 1 and not bool(discard_model.get("last_discard_was_automatic")), "manual discard resolves without placement")

	var auto_model: RefCounted = ModelScript.new()
	var k01: Dictionary = repository.call("get_template", "K01") as Dictionary
	_expect(bool(auto_model.call("start", k01, 10, 5.5)), "auto-discard game starts")
	auto_model.call("begin_roll", 6)
	var no_targets: Array = auto_model.call("resolve_rolled_die") as Array
	_expect(no_targets.is_empty() and int(auto_model.get("state")) == ModelScript.State.READY, "no valid target auto-discards without waiting")
	_expect(bool(auto_model.get("last_discard_was_automatic")) and int(auto_model.get("discard_count")) == 1, "auto discard is observable")

	var final_template := {
		"id": "TEST_FINAL",
		"tier": "black",
		"max_rolls": 3,
		"locks": [
			{"rule": "exact", "value": 1},
			{"rule": "exact", "value": 2},
			{"rule": "exact", "value": 3},
		],
	}
	var final_success: RefCounted = ModelScript.new()
	final_success.call("start", final_template, 50, 5.5)
	_play_and_place(final_success, 1, 0)
	_play_and_place(final_success, 2, 1)
	_expect(int(final_success.call("begin_roll", 3)) == 3 and int(final_success.get("rolls_used")) == 3, "final roll begins before terminal resolution")
	_expect((final_success.call("resolve_rolled_die") as Array) == [2] and int(final_success.get("state")) == ModelScript.State.WAITING_FOR_PLACEMENT, "final fitting roll waits for placement instead of failing")
	_expect(bool(final_success.call("place_current_die", 2)) and int(final_success.get("state")) == ModelScript.State.SUCCESS and int(final_success.get("reward")) == 275, "placing the final die on the final roll succeeds")

	var final_failure: RefCounted = ModelScript.new()
	final_failure.call("start", final_template, 10, 5.5)
	_play_and_place(final_failure, 1, 0)
	_play_and_place(final_failure, 2, 1)
	final_failure.call("begin_roll", 3)
	final_failure.call("resolve_rolled_die")
	_expect(int(final_failure.get("state")) == ModelScript.State.WAITING_FOR_PLACEMENT, "final roll is still actionable before failure")
	_expect(bool(final_failure.call("discard_current_die")) and int(final_failure.get("state")) == ModelScript.State.FAILURE, "manual discard on final roll resolves failure")
	_expect(int(final_failure.get("reward")) == 0 and int(final_failure.call("begin_roll", 3)) == 0, "FAILURE has no reward and blocks rolls")

	var provider_model: RefCounted = ModelScript.new()
	provider_model.call("set_roll_provider", func() -> int: return 4)
	provider_model.call("start", b01, 10, 1.7)
	_expect(int(provider_model.call("begin_roll")) == 4, "injected roll provider controls the die")
	var rng_a := RandomNumberGenerator.new()
	var rng_b := RandomNumberGenerator.new()
	rng_a.seed = 123456
	rng_b.seed = 123456
	var seeded_a: RefCounted = ModelScript.new()
	var seeded_b: RefCounted = ModelScript.new()
	seeded_a.call("set_rng", rng_a)
	seeded_b.call("set_rng", rng_b)
	seeded_a.call("start", b01, 10, 1.7)
	seeded_b.call("start", b01, 10, 1.7)
	_expect(int(seeded_a.call("begin_roll")) == int(seeded_b.call("begin_roll")), "injected seeded RNG is deterministic")
	for state_index: int in ModelScript.STATE_NAMES.size():
		_expect(str(ModelScript.state_name(state_index)) == str(ModelScript.STATE_NAMES[state_index]), "state %d exposes its canonical name" % state_index)

func _test_active_game_snapshot_restore() -> void:
	var b01: Dictionary = repository.call("get_template", "B01") as Dictionary
	var bronze_config: Dictionary = repository.call("get_tier_config", "bronze") as Dictionary
	var source: RefCounted = ModelScript.new()
	source.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	_expect(bool(source.call("start_with_tier_config", b01, 20, bronze_config)), "snapshot READY source starts from canonical template and config")
	source.call("begin_roll", 6)
	source.call("resolve_rolled_die")
	source.call("place_current_die", 2)
	var ready_snapshot: Dictionary = source.call("snapshot_active_game") as Dictionary
	var ready_template_snapshot: Dictionary = ready_snapshot.get("template", {}) as Dictionary
	var ready_tier_snapshot: Dictionary = ready_snapshot.get("tier_config", {}) as Dictionary
	_expect(int(ready_snapshot.get("schema_version", 0)) == 1 and str(ready_snapshot.get("snapshot_type", "")) == "vault_break_active_game", "active snapshot identifies its schema and type")
	_expect(int(ready_snapshot.get("state", -1)) == ModelScript.State.READY and str(ready_snapshot.get("state_name", "")) == "READY", "READY snapshot records state value and name")
	_expect(str(ready_snapshot.get("template_id", "")) == "B01" and str(ready_template_snapshot.get("id", "")) == "B01", "snapshot records template identity")
	_expect(int(ready_template_snapshot.get("max_rolls", 0)) == 5 and (ready_template_snapshot.get("locks", []) as Array).size() == 3, "snapshot carries authored template validation config")
	_expect(int(ready_tier_snapshot.get("lock_count", 0)) == 3 and int(ready_tier_snapshot.get("max_rolls", 0)) == 5 and is_equal_approx(float(ready_tier_snapshot.get("payout_multiplier", 0.0)), 1.7), "snapshot carries tier validation config")
	_expect(int(ready_snapshot.get("rolls_used", -1)) == 1 and int(ready_snapshot.get("max_rolls", 0)) == 5 and int(ready_snapshot.get("current_face", -1)) == 0, "snapshot records roll counters and resolved face")
	_expect(int(ready_snapshot.get("bet", 0)) == 20 and is_equal_approx(float(ready_snapshot.get("payout_multiplier", 0.0)), 1.7) and int(ready_snapshot.get("reward", -1)) == 0 and str(ready_snapshot.get("result", "")).is_empty(), "snapshot records wager and result fields")
	_expect(int(ready_snapshot.get("discard_count", -1)) == 0 and not bool(ready_snapshot.get("last_discard_was_automatic", true)), "snapshot records discard fields")
	_expect((ready_snapshot.get("placed_faces", []) as Array) == [0, 0, 6], "snapshot records immutable placed lock faces")

	var ready_json: String = JSON.stringify(ready_snapshot)
	var ready_parsed_value: Variant = JSON.parse_string(ready_json)
	_expect(ready_parsed_value is Dictionary, "active snapshot is JSON serializable")
	var restored: RefCounted = ModelScript.new()
	restored.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	_expect(bool(restored.call("restore_active_game", ready_parsed_value as Dictionary, b01, bronze_config)), "fresh model restores READY against canonical template and config")
	_expect(int(restored.get("state")) == ModelScript.State.READY and int(restored.get("rolls_used")) == 1 and (restored.call("get_placed_faces") as Array) == [0, 0, 6], "READY restore round-trips gameplay state")
	restored.call("begin_roll", 6)
	_expect((restored.call("resolve_rolled_die") as Array) == [1], "restored READY game exposes the same next placement")
	restored.call("place_current_die", 1)
	restored.call("begin_roll", 1)
	restored.call("resolve_rolled_die")
	restored.call("place_current_die", 0)
	_expect(int(restored.get("state")) == ModelScript.State.SUCCESS and int(restored.get("reward")) == 34, "restored READY game continues to canonical success and reward")
	var success_snapshot: Dictionary = restored.call("snapshot_active_game") as Dictionary
	_expect(str(success_snapshot.get("result", "")) == "success" and int(success_snapshot.get("reward", 0)) == 34, "terminal snapshot preserves success result and reward")
	var success_restored: RefCounted = ModelScript.new()
	success_restored.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	_expect(bool(success_restored.call("restore_active_game", success_snapshot, b01, bronze_config)) and int(success_restored.get("state")) == ModelScript.State.SUCCESS, "validated SUCCESS snapshot round-trips")
	success_restored.call("advance_to_result")
	var result_snapshot: Dictionary = success_restored.call("snapshot_active_game") as Dictionary
	var result_restored: RefCounted = ModelScript.new()
	result_restored.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	_expect(bool(result_restored.call("restore_active_game", result_snapshot, b01, bronze_config)) and int(result_restored.get("state")) == ModelScript.State.RESULT and int(result_restored.get("reward")) == 34, "validated RESULT snapshot round-trips without changing reward")

	var current_authored: RefCounted = ModelScript.new()
	current_authored.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	current_authored.call("start_with_tier_config", b01, 20, bronze_config)
	_expect(bool(current_authored.call("restore_active_game", ready_parsed_value as Dictionary)), "already-started model can validate restore against its current authored template")
	var no_authority: RefCounted = ModelScript.new()
	_expect(not bool(no_authority.call("restore_active_game", ready_parsed_value as Dictionary)), "fresh restore rejects a snapshot without canonical validation authority")

	var final_template: Dictionary = {
		"id": "TEST_FINAL_SNAPSHOT",
		"tier": "black",
		"structure_group": "exact_triple",
		"max_rolls": 3,
		"locks": [
			{"rule": "exact", "value": 1},
			{"rule": "exact", "value": 2},
			{"rule": "exact", "value": 3},
		],
	}
	var final_config: Dictionary = {"lock_count": 3, "max_rolls": 3, "payout_multiplier": 5.5}
	var waiting_source: RefCounted = ModelScript.new()
	waiting_source.call("start_with_tier_config", final_template, 50, final_config)
	_play_and_place(waiting_source, 1, 0)
	_play_and_place(waiting_source, 2, 1)
	waiting_source.call("begin_roll", 3)
	waiting_source.call("resolve_rolled_die")
	var waiting_snapshot: Dictionary = waiting_source.call("snapshot_active_game") as Dictionary
	var waiting_json_value: Variant = JSON.parse_string(JSON.stringify(waiting_snapshot))
	var waiting_restored: RefCounted = ModelScript.new()
	_expect(bool(waiting_restored.call("restore_active_game", waiting_json_value as Dictionary, final_template, final_config)), "WAITING_FOR_PLACEMENT snapshot restores from JSON")
	_expect(int(waiting_restored.get("state")) == ModelScript.State.WAITING_FOR_PLACEMENT and int(waiting_restored.get("rolls_used")) == 3 and int(waiting_restored.get("current_face")) == 3, "final-roll WAITING state round-trips without premature failure")
	_expect((waiting_restored.call("get_valid_empty_lock_indices") as Array) == [2], "restored final roll retains its valid empty target")
	_expect(bool(waiting_restored.call("place_current_die", 2)) and int(waiting_restored.get("state")) == ModelScript.State.SUCCESS and int(waiting_restored.get("reward")) == 275, "restored final-roll placement succeeds before failure resolution")

	var guard: RefCounted = ModelScript.new()
	guard.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	guard.call("start_with_tier_config", b01, 20, bronze_config)
	var malformed: Dictionary = ready_snapshot.duplicate(true)
	malformed["schema_version"] = 2
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects an unknown snapshot schema")
	malformed = ready_snapshot.duplicate(true)
	malformed["schema_version"] = "1"
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects a non-numeric snapshot schema")
	malformed = ready_snapshot.duplicate(true)
	malformed["template_id"] = "B02"
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects template identity mismatch")
	malformed = ready_snapshot.duplicate(true)
	var malformed_template: Dictionary = malformed.get("template", {}) as Dictionary
	var malformed_locks: Array = malformed_template.get("locks", []) as Array
	(malformed_locks[2] as Dictionary)["value"] = 5
	malformed_template["locks"] = malformed_locks
	malformed["template"] = malformed_template
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects authored lock mismatch")
	malformed = ready_snapshot.duplicate(true)
	malformed["placed_faces"] = [0, 0]
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects placed-lock count mismatch")
	malformed = ready_snapshot.duplicate(true)
	malformed["placed_faces"] = [0, 0, 7]
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects out-of-range placed faces")
	malformed = ready_snapshot.duplicate(true)
	malformed["placed_faces"] = [0, 0, 5]
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects a face that its authored lock cannot accept")
	malformed = ready_snapshot.duplicate(true)
	malformed["rolls_used"] = 6
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects rolls beyond max_rolls")
	malformed = ready_snapshot.duplicate(true)
	malformed["current_face"] = 6
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects a pending face in READY")
	malformed = ready_snapshot.duplicate(true)
	malformed["reward"] = 34
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects active-state reward")
	malformed = ready_snapshot.duplicate(true)
	malformed["state"] = ModelScript.State.RESOLVING_PLACEMENT
	malformed["state_name"] = "RESOLVING_PLACEMENT"
	_expect_restore_rejected_without_mutation(guard, malformed, b01, bronze_config, "restore rejects transient RESOLVING_PLACEMENT")
	var wrong_config: Dictionary = bronze_config.duplicate(true)
	wrong_config["payout_multiplier"] = 2.2
	_expect_restore_rejected_without_mutation(guard, ready_snapshot, b01, wrong_config, "restore rejects canonical tier-config mismatch")
	var waiting_no_fit: Dictionary = waiting_snapshot.duplicate(true)
	waiting_no_fit["current_face"] = 4
	var waiting_guard: RefCounted = ModelScript.new()
	waiting_guard.call("start_with_tier_config", final_template, 50, final_config)
	_expect_restore_rejected_without_mutation(waiting_guard, waiting_no_fit, final_template, final_config, "restore rejects WAITING state with no valid authored target")
	_expect((ModelScript.new() as RefCounted).call("snapshot_active_game") == {}, "SETUP does not produce an active-game snapshot")

func _test_unlocks_and_first_plays() -> void:
	var progress: RefCounted = ProgressScript.new()
	_expect(bool(progress.call("is_tier_unlocked", "bronze")), "BRONZE starts unlocked")
	_expect(not bool(progress.call("is_tier_unlocked", "silver")) and not bool(progress.call("is_tier_unlocked", "gold")) and not bool(progress.call("is_tier_unlocked", "black")), "higher tiers start locked")
	for index: int in 10:
		progress.call("record_game_result", "bronze", "B%02d" % ((index % 8) + 1), "partition_exact", false)
	_expect(not bool(progress.call("is_tier_unlocked", "silver")), "BRONZE losses do not unlock SILVER")
	progress.call("record_game_result", "bronze", "B01", "partition_exact", true)
	_expect(bool(progress.call("is_tier_unlocked", "silver")), "one BRONZE win unlocks SILVER")
	progress.call("record_game_result", "silver", "S05", "double_edge", true)
	_expect(not bool(progress.call("is_tier_unlocked", "gold")), "one SILVER win does not unlock GOLD")
	progress.call("record_game_result", "silver", "S06", "double_edge", true)
	_expect(bool(progress.call("is_tier_unlocked", "gold")), "two SILVER wins unlock GOLD")
	progress.call("record_game_result", "gold", "G01", "double_exact", true)
	_expect(bool(progress.call("is_tier_unlocked", "black")), "one GOLD win unlocks the BLACK system")

	var selector: RefCounted = SelectorScript.new(repository)
	var first_progress: RefCounted = ProgressScript.new()
	var first_ids := {"bronze": "B01", "silver": "S05", "gold": "G01", "black": "K01"}
	for tier: String in first_ids:
		var selected: Dictionary = selector.call("select_template", tier, first_progress, 0.99) as Dictionary
		_expect(str(selected.get("id", "")) == str(first_ids[tier]), "%s first play is fixed" % tier)
	first_progress.call("record_game_result", "bronze", "B01", "partition_exact", false)
	_expect(bool(first_progress.call("is_first_play_done", "bronze")), "a loss consumes the first BRONZE play")
	var after_loss: Dictionary = selector.call("select_template", "bronze", first_progress, 0.0) as Dictionary
	_expect(str(after_loss.get("id", "")) != "B01", "first template is not repeated merely because the first game lost")
	var stats: Dictionary = (progress.call("serialize") as Dictionary).get("template_stats", {}) as Dictionary
	_expect((stats.get("B01", {}) as Dictionary).get("plays", 0) == 3 and (stats.get("B01", {}) as Dictionary).get("wins", 0) == 1, "template stats remain sparse and count wins separately")

func _test_selection_guards_and_fallbacks() -> void:
	var selector: RefCounted = SelectorScript.new(repository)
	var bronze_history := _progress_with_history("bronze", ["B01", "B02"], ["partition_exact", "parity_exact"])
	var bronze_ids: Array = selector.call("candidate_ids", "bronze", bronze_history) as Array
	_expect("B01" not in bronze_ids and "B02" not in bronze_ids, "recent two templates are excluded")

	var bronze_streak := _progress_with_history("bronze", ["B01", "B02"], ["partition_exact", "partition_exact"])
	var streak_ids: Array = selector.call("candidate_ids", "bronze", bronze_streak) as Array
	_expect(_none_have_structure(streak_ids, "partition_exact"), "a repeated normal-tier structure group is excluded")
	var silver_streak := _progress_with_history("silver", ["S01", "S03"], ["triple_overlap", "triple_overlap"])
	var silver_ids: Array = selector.call("candidate_ids", "silver", silver_streak) as Array
	_expect(_none_have_structure(silver_ids, "triple_overlap"), "SILVER structure anti-streak excludes all matching templates")
	var black_history := _progress_with_history("black", ["K01", "K02"], ["exact_triple", "exact_triple"])
	var black_ids: Array = selector.call("candidate_ids", "black", black_history) as Array
	_expect("K01" not in black_ids and "K02" not in black_ids and "K03" in black_ids, "BLACK uses recent exclusion but no structure guard")

	var templates_by_tier: Dictionary = repository.get("templates_by_tier") as Dictionary
	var original_bronze: Array = (templates_by_tier.get("bronze", []) as Array).duplicate(true)
	templates_by_tier["bronze"] = [repository.call("get_template", "B01"), repository.call("get_template", "B02")]
	var fallback_b_progress := _progress_with_history("bronze", [], ["partition_exact", "partition_exact"])
	var pool_b: Dictionary = selector.call("candidate_pool", "bronze", fallback_b_progress) as Dictionary
	_expect(str(pool_b.get("fallback_level", "")) == "B" and (pool_b.get("candidates", []) as Array).size() == 2, "fallback B releases structure while preserving recent exclusion")
	var fallback_c_progress := _progress_with_history("bronze", ["B01", "B02"], [])
	var pool_c: Dictionary = selector.call("candidate_pool", "bronze", fallback_c_progress) as Dictionary
	var c_candidates: Array = pool_c.get("candidates", []) as Array
	_expect(str(pool_c.get("fallback_level", "")) == "C" and c_candidates.size() == 1 and str((c_candidates[0] as Dictionary).get("id", "")) == "B01", "fallback C excludes only the latest template")
	templates_by_tier["bronze"] = [repository.call("get_template", "B01")]
	var fallback_d_progress := _progress_with_history("bronze", ["B01"], [])
	var pool_d: Dictionary = selector.call("candidate_pool", "bronze", fallback_d_progress) as Dictionary
	_expect(str(pool_d.get("fallback_level", "")) == "D" and (pool_d.get("candidates", []) as Array).size() == 1, "fallback D returns the full tier rather than stalling")
	templates_by_tier["bronze"] = original_bronze

func _test_weighted_selection() -> void:
	var selector: RefCounted = SelectorScript.new(repository)
	var weighted: Array[Dictionary] = [
		{"id": "C", "weight": 1.0},
		{"id": "A", "weight": 1.0},
		{"id": "B", "weight": 2.0},
	]
	_expect(str((selector.call("weighted_select", weighted, 0.0) as Dictionary).get("id", "")) == "A", "weight selection is stably sorted at zero")
	_expect(str((selector.call("weighted_select", weighted, 0.2499) as Dictionary).get("id", "")) == "A", "first weight interval ends below 0.25")
	_expect(str((selector.call("weighted_select", weighted, 0.25) as Dictionary).get("id", "")) == "B", "weight boundary selects the next interval")
	_expect(str((selector.call("weighted_select", weighted, 0.7499) as Dictionary).get("id", "")) == "B", "double-weight interval is respected")
	_expect(str((selector.call("weighted_select", weighted, 0.75) as Dictionary).get("id", "")) == "C", "final weight interval starts at 0.75")
	_expect(str((selector.call("weighted_select", weighted, 1.0) as Dictionary).get("id", "")) == "C", "injected one maps safely to the final candidate")
	var provider_progress := _progress_with_history("bronze", [], [])
	selector.call("set_random_provider", func() -> float: return 0.999)
	var provider_selected: Dictionary = selector.call("select_template", "bronze", provider_progress) as Dictionary
	_expect(str(provider_selected.get("id", "")) == "B08", "injected random provider drives stable weighted selection")

func _test_black_lifecycle_and_serialization() -> void:
	var selector: RefCounted = SelectorScript.new(repository)
	var locked: RefCounted = ProgressScript.new()
	for index: int in 100:
		locked.call("after_normal_game_completed", selector, 0.0, 0.0)
	var locked_spawn: Dictionary = (locked.call("serialize") as Dictionary).get("black_spawn", {}) as Dictionary
	_expect(str(locked_spawn.get("active_template_id", "")).is_empty() and int(locked_spawn.get("eligible_games", -1)) == 0, "locked BLACK never spawns or accumulates eligibility")

	var threshold_data := _gold_unlocked_progress()
	var threshold_miss: RefCounted = ProgressScript.new(threshold_data)
	_expect(str(threshold_miss.call("after_normal_game_completed", selector, 0.15, 0.0)).is_empty(), "BLACK 15 percent comparison excludes the exact upper boundary")
	_expect(int(((threshold_miss.call("serialize") as Dictionary).get("black_spawn", {}) as Dictionary).get("eligible_games", 0)) == 1, "eligible miss increments the ceiling counter")
	var threshold_hit: RefCounted = ProgressScript.new(threshold_data)
	_expect(str(threshold_hit.call("after_normal_game_completed", selector, 0.149999, 0.9)) == "K01", "BLACK spawns below the 15 percent boundary")
	_expect(str(threshold_hit.call("get_active_black_template_id")) == "K01", "first BLACK spawn fixes K01")

	var ceiling_data := _gold_unlocked_progress()
	var ceiling_spawn: Dictionary = ceiling_data.get("black_spawn", {}) as Dictionary
	ceiling_spawn["eligible_games"] = 6
	ceiling_data["black_spawn"] = ceiling_spawn
	var ceiling: RefCounted = ProgressScript.new(ceiling_data)
	_expect(str(ceiling.call("after_normal_game_completed", selector, 1.0, 0.0)) == "K01", "eligible game seven guarantees BLACK independent of chance")
	var active_before := str(ceiling.call("get_active_black_template_id"))
	ceiling.call("after_normal_game_completed", selector, 0.0, 1.0)
	_expect(str(ceiling.call("get_active_black_template_id")) == active_before, "active BLACK persists through normal completions without reroll")

	var saved: Dictionary = ceiling.call("serialize") as Dictionary
	var reloaded: RefCounted = ProgressScript.new(ProgressScript.normalize_from_json(JSON.stringify(saved)))
	_expect(str(reloaded.call("get_active_black_template_id")) == "K01", "active BLACK survives JSON save and reload")
	_expect(bool(reloaded.call("record_game_result", "black", "K01", "exact_triple", false)), "BLACK loss records as a completed attempt")
	var after_attempt: Dictionary = reloaded.call("serialize") as Dictionary
	var after_attempt_spawn: Dictionary = after_attempt.get("black_spawn", {}) as Dictionary
	_expect(str(after_attempt_spawn.get("active_template_id", "")).is_empty() and int(after_attempt_spawn.get("eligible_games", -1)) == 0 and int(after_attempt_spawn.get("cooldown_remaining", 0)) == 2, "BLACK attempt clears active state and starts cooldown two")
	_expect(bool(reloaded.call("is_first_play_done", "black")), "BLACK first play is consumed on loss")

	reloaded.call("after_normal_game_completed", selector, 0.0, 0.0)
	_expect(_cooldown(reloaded) == 1 and str(reloaded.call("get_active_black_template_id")).is_empty(), "first normal completion ticks cooldown 2 to 1 without spawn")
	reloaded.call("after_normal_game_completed", selector, 0.0, 0.0)
	_expect(_cooldown(reloaded) == 0 and str(reloaded.call("get_active_black_template_id")).is_empty(), "second normal completion ticks cooldown 1 to 0 without spawn")
	var post_cooldown_id := str(reloaded.call("after_normal_game_completed", selector, 0.0, 0.0))
	_expect(post_cooldown_id == "K02", "only the following normal completion becomes eligible and recent exclusion selects K02")

	var malformed := {
		"schema_version": 99,
		"tiers": {
			"bronze": {"plays": -4, "wins": 9, "first_play_done": true, "recent_template_ids": ["B01", "B02", "B03"], "recent_structure_groups": ["a", "b", "c"]},
		},
		"black_spawn": {"active_template_id": "K04", "eligible_games": -2, "cooldown_remaining": 99},
		"template_stats": {"B01": {"plays": 2, "wins": 8}, "bad": "ignored"},
		"unknown_future_key": true,
	}
	var normalized: Dictionary = ProgressScript.normalize_progress(malformed)
	var normalized_bronze: Dictionary = (normalized.get("tiers", {}) as Dictionary).get("bronze", {}) as Dictionary
	_expect(int(normalized.get("schema_version", 0)) == 1 and int(normalized_bronze.get("plays", -1)) == 0 and int(normalized_bronze.get("wins", -1)) == 0, "normalizer produces v1 and clamps invalid win totals")
	_expect((normalized_bronze.get("recent_template_ids", []) as Array) == ["B02", "B03"] and (normalized_bronze.get("recent_structure_groups", []) as Array) == ["b", "c"], "normalizer retains only the recent two values")
	var normalized_spawn: Dictionary = normalized.get("black_spawn", {}) as Dictionary
	_expect(str(normalized_spawn.get("active_template_id", "")) == "K04" and int(normalized_spawn.get("eligible_games", -1)) == 0 and int(normalized_spawn.get("cooldown_remaining", -1)) == 2, "normalizer preserves active BLACK and bounds counters")
	var normalized_stats: Dictionary = normalized.get("template_stats", {}) as Dictionary
	_expect(normalized_stats.has("B01") and not normalized_stats.has("bad") and int((normalized_stats.get("B01", {}) as Dictionary).get("wins", -1)) == 2, "normalizer keeps sparse valid template stats and clamps wins to plays")

func _play_and_place(model: RefCounted, face: int, lock_index: int) -> void:
	model.call("begin_roll", face)
	model.call("resolve_rolled_die")
	model.call("place_current_die", lock_index)

func _expect_restore_rejected_without_mutation(model: RefCounted, candidate_snapshot: Dictionary, canonical_template: Dictionary, canonical_tier_config: Dictionary, label: String) -> void:
	var before_json: String = JSON.stringify(model.call("snapshot_active_game") as Dictionary)
	var rejected: bool = not bool(model.call("restore_active_game", candidate_snapshot, canonical_template, canonical_tier_config))
	var after_json: String = JSON.stringify(model.call("snapshot_active_game") as Dictionary)
	_expect(rejected and before_json == after_json, "%s without mutating the model" % label)

func _lock_signatures(locks: Array) -> Array:
	var result: Array = []
	for lock_value: Variant in locks:
		var lock: Dictionary = lock_value as Dictionary
		var signature := str(lock.get("rule", ""))
		if signature == "exact":
			signature += ":%d" % int(lock.get("value", 0))
		result.append(signature)
	return result

func _all_exact(locks: Array) -> bool:
	for lock_value: Variant in locks:
		if str((lock_value as Dictionary).get("rule", "")) != "exact":
			return false
	return true

func _progress_with_history(tier: String, recent_ids: Array, recent_structures: Array) -> RefCounted:
	var raw: Dictionary = ProgressScript.default_progress()
	var tiers: Dictionary = raw.get("tiers", {}) as Dictionary
	var stats: Dictionary = tiers.get(tier, {}) as Dictionary
	stats["first_play_done"] = true
	stats["recent_template_ids"] = recent_ids.duplicate()
	if tier != "black":
		stats["recent_structure_groups"] = recent_structures.duplicate()
	tiers[tier] = stats
	raw["tiers"] = tiers
	return ProgressScript.new(raw)

func _none_have_structure(template_ids: Array, structure_group: String) -> bool:
	for template_id_value: Variant in template_ids:
		var template: Dictionary = repository.call("get_template", str(template_id_value)) as Dictionary
		if str(template.get("structure_group", "")) == structure_group:
			return false
	return true

func _gold_unlocked_progress() -> Dictionary:
	var raw: Dictionary = ProgressScript.default_progress()
	var tiers: Dictionary = raw.get("tiers", {}) as Dictionary
	var gold: Dictionary = tiers.get("gold", {}) as Dictionary
	gold["plays"] = 1
	gold["wins"] = 1
	tiers["gold"] = gold
	raw["tiers"] = tiers
	return raw

func _cooldown(progress: RefCounted) -> int:
	var serialized: Dictionary = progress.call("serialize") as Dictionary
	var spawn: Dictionary = serialized.get("black_spawn", {}) as Dictionary
	return int(spawn.get("cooldown_remaining", 0))
