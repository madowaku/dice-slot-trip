extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const DicePokerScript = preload("res://scripts/game/dice_poker_model.gd")
const DicePokerScreenScript = preload("res://scripts/app/dice_poker_screen.gd")
const DICE_POKER_SCENE: PackedScene = preload("res://scenes/casino/DicePoker.tscn")

var failures: int = 0
var assertions: int = 0
var test_save_path: String = ""

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	_configure_test_save()
	DicePokerScreenScript.suppress_audio_for_tests = true
	var ui_sfx: Node = root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_enabled", false)
	_test_model_rules()
	await _test_scene_flow()
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	var bgm: Node = root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	await process_frame
	DicePokerScreenScript.suppress_audio_for_tests = false
	_cleanup_test_save()
	print("DICE POKER tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _configure_test_save() -> void:
	test_save_path = "user://dice_slot_trip_dice_poker_tests_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(test_save_path)
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.add_chips(1000)

func _cleanup_test_save() -> void:
	if not test_save_path.is_empty() and FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.clear_test_save_path()

func _test_model_rules() -> void:
	var cases: Array[Dictionary] = [
		{"dice": [6, 6, 6, 6, 6], "rank": DicePokerScript.RANK_FIVE},
		{"dice": [2, 2, 2, 2, 5], "rank": DicePokerScript.RANK_FOUR},
		{"dice": [3, 3, 3, 5, 5], "rank": DicePokerScript.RANK_FULL_HOUSE},
		{"dice": [1, 2, 3, 4, 5], "rank": DicePokerScript.RANK_STRAIGHT},
		{"dice": [2, 3, 4, 5, 6], "rank": DicePokerScript.RANK_STRAIGHT},
		{"dice": [4, 4, 4, 2, 6], "rank": DicePokerScript.RANK_THREE},
		{"dice": [1, 1, 5, 5, 6], "rank": DicePokerScript.RANK_TWO_PAIR},
		{"dice": [2, 2, 3, 4, 6], "rank": DicePokerScript.RANK_ONE_PAIR},
		{"dice": [1, 2, 3, 4, 6], "rank": DicePokerScript.RANK_NO_HAND},
		{"dice": [1, 2, 2, 4, 5], "rank": DicePokerScript.RANK_ONE_PAIR},
		{"dice": [1, 3, 2, 4, 6], "rank": DicePokerScript.RANK_NO_HAND},
	]
	for fixture: Dictionary in cases:
		var evaluated: Dictionary = DicePokerScript.evaluate(fixture["dice"] as Array)
		_expect(str(evaluated.get("rank", "")) == str(fixture["rank"]), "rank %s" % str(fixture["rank"]))

	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_NO_HAND), 0.0), "NO HAND multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_ONE_PAIR), 0.2), "ONE PAIR multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_TWO_PAIR), 0.4), "TWO PAIR multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_THREE), 0.6), "THREE multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_STRAIGHT), 0.8), "STRAIGHT multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_FULL_HOUSE), 1.0), "FULL HOUSE multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_FOUR), 1.7), "FOUR multiplier")
	_expect(is_equal_approx(DicePokerScript.multiplier_for(DicePokerScript.RANK_FIVE), 2.8), "FIVE multiplier")
	_expect(DicePokerScript.payout_for(20, DicePokerScript.RANK_FOUR) == 34, "BET20 FOUR floor payout is 34")
	_expect(DicePokerScript.payout_for(20, DicePokerScript.RANK_FULL_HOUSE) == 20, "BET20 FULL HOUSE payout is 20")
	_expect(DicePokerScript.payout_for(20, DicePokerScript.RANK_ONE_PAIR) == 4, "BET20 ONE PAIR payout is 4")
	_expect(DicePokerScript.payout_for(10, DicePokerScript.RANK_FIVE) == 28 and DicePokerScript.payout_for(50, DicePokerScript.RANK_STRAIGHT) == 40, "all BET payout floors")

	var state: Dictionary = DicePokerScript.new_game(20)
	state = DicePokerScript.apply_initial(state, [1, 2, 3, 4, 5])
	state = DicePokerScript.toggle_keep(state, 1)
	_expect(DicePokerScript.is_kept(state, 1) and DicePokerScript.kept_count(state) == 1, "KEEP toggles one die")
	state = DicePokerScript.toggle_keep(state, 1)
	_expect(not DicePokerScript.is_kept(state, 1) and DicePokerScript.kept_count(state) == 0, "KEEP toggles back to OPEN")
	state = DicePokerScript.set_keep(state, 0, true)
	var after_reroll: Dictionary = DicePokerScript.apply_reroll(state, [6, 6, 6, 6, 6])
	_expect(int(after_reroll["dice"][0]) == 1 and int(after_reroll["dice"][1]) == 6, "kept die stays unchanged during reroll")
	_expect(int(after_reroll.get("rerolls_used", 0)) == 1 and int(after_reroll.get("rerolls_remaining", 0)) == 1, "first reroll leaves one reroll")
	var second: Dictionary = DicePokerScript.apply_reroll(after_reroll, [2, 2, 2, 2, 2])
	_expect(bool(second.get("finished", false)) and int(second.get("rerolls_used", 0)) == 2, "second reroll finalizes automatically")
	_expect(int(second.get("payout", 0)) == 34, "automatic finalization evaluates FOUR")

	var locked: Dictionary = DicePokerScript.apply_initial(DicePokerScript.new_game(20), [2, 2, 3, 4, 5])
	locked = DicePokerScript.keep_all(locked)
	_expect(DicePokerScript.can_lock_hand(locked) and not DicePokerScript.can_reroll(locked), "all five KEEP switches action to LOCK HAND")
	locked = DicePokerScript.finalize(locked)
	_expect(bool(locked.get("finished", false)) and int(locked.get("payout", 0)) == 4, "LOCK HAND finalizes ONE PAIR without spending reroll")
	_expect(DicePokerScript.finalize(locked) == locked, "finalization is idempotent")

func _test_scene_flow() -> void:
	var scene_node: Node = DICE_POKER_SCENE.instantiate()
	var scene: DicePokerScreen = scene_node as DicePokerScreen
	root.add_child(scene_node)
	await process_frame
	_expect(scene != null and scene.get_script() == DicePokerScreenScript, "DICE POKER scene reaches DicePokerScreen")
	_expect(scene.setup_view.visible and not scene.active_view.visible and not scene.result_view.visible, "DICE POKER opens on setup")
	_expect(scene.bet_buttons.size() == 3 and scene.keep_buttons.size() == 5, "screen builds three BET and five KEEP targets")
	for amount: int in scene.bet_buttons:
		_expect((scene.bet_buttons[amount] as Button).custom_minimum_size.y >= 96.0, "BET %d meets touch target" % amount)
	for index: int in scene.keep_buttons:
		_expect((scene.keep_buttons[index] as Button).custom_minimum_size.y >= 96.0, "DIE %d KEEP meets touch target" % (index + 1))

	scene.selected_bet = 20
	scene.queued_roll_batch = [[2, 2, 3, 4, 5], [6, 6, 6, 6, 6]]
	scene.deal_button.pressed.emit()
	var active: Dictionary = CasinoBankScript.active_game("dice_poker")
	var pending: Array = active.get("pending_rolls", []) as Array
	_expect(not pending.is_empty() and int((pending[0] as Dictionary).get("values", [0])[0]) == 2, "DEAL pending values persist before animation")
	_expect(CasinoBankScript.balance() == 980, "DEAL charges BET once")
	await create_timer(0.58).timeout
	_expect(scene.active_view.visible and scene.game["dice"] == [2, 2, 3, 4, 5], "DEAL resolves exact five faces")
	scene.keep_buttons[0].pressed.emit()
	await process_frame
	_expect(bool((scene.game.get("kept", []) as Array)[0]), "KEEP button updates persistent state")
	scene.reroll_button.pressed.emit()
	var pending_reroll: Dictionary = CasinoBankScript.active_game("dice_poker")
	var pending_values: Array = pending_reroll.get("pending_rolls", []) as Array
	_expect(not pending_values.is_empty() and (pending_values[0] as Dictionary).has("indices") and (pending_values[0] as Dictionary).has("full_values"), "REROLL persists full index/value mapping")
	await create_timer(0.58).timeout
	_expect(int(scene.game.get("rerolls_used", 0)) == 1 and int((scene.game.get("dice", []) as Array)[0]) == 2, "REROLL keeps die one and decrements remaining")
	for index: int in range(1, 5):
		scene.keep_buttons[index].pressed.emit()
	await process_frame
	_expect(scene.lock_button.visible and not scene.reroll_button.visible, "all kept state shows LOCK HAND primary action")
	scene.lock_button.pressed.emit()
	await process_frame
	_expect(scene.result_view.visible and int(scene.game.get("payout", 0)) == 34 and CasinoBankScript.balance() == 1014, "LOCK HAND settles FOUR once")
	var settled_balance: int = CasinoBankScript.balance()
	scene.lock_button.pressed.emit()
	_expect(CasinoBankScript.balance() == settled_balance, "settlement replay is idempotent")
	scene.queue_free()
	await process_frame

	# Kill a screen while a reroll is animating and resume the exact persisted
	# pending faces on a fresh screen.
	var first_node: Node = DICE_POKER_SCENE.instantiate()
	var first: DicePokerScreen = first_node as DicePokerScreen
	root.add_child(first_node)
	await process_frame
	first.selected_bet = 20
	first.queued_roll_batch = [[1, 1, 1, 2, 3], [6, 5, 4, 3]]
	first.deal_button.pressed.emit()
	await create_timer(0.58).timeout
	first.keep_buttons[0].pressed.emit()
	first.reroll_button.pressed.emit()
	var before_resume: Dictionary = CasinoBankScript.active_game("dice_poker")
	var stored: Array = before_resume.get("pending_rolls", []) as Array
	_expect(not stored.is_empty() and int((stored[0] as Dictionary).get("full_values", [0, 0, 0, 0, 0])[0]) == 1, "resume fixture stores pending full values")
	first.queue_free()
	await process_frame
	var resumed_node: Node = DICE_POKER_SCENE.instantiate()
	var resumed: DicePokerScreen = resumed_node as DicePokerScreen
	root.add_child(resumed_node)
	await process_frame
	await create_timer(0.58).timeout
	_expect(int(resumed.game.get("rerolls_used", 0)) == 1 and int((resumed.game.get("dice", []) as Array)[0]) == 1 and int((resumed.game.get("dice", []) as Array)[1]) == 6, "fresh screen resumes exact pending reroll values")
	resumed.keep_buttons[1].pressed.emit()
	resumed.keep_buttons[2].pressed.emit()
	resumed.keep_buttons[3].pressed.emit()
	resumed.keep_buttons[4].pressed.emit()
	resumed.lock_button.pressed.emit()
	await process_frame
	_expect(not CasinoBankScript.has_active_game("dice_poker"), "resumed game settles and clears active transaction")
	resumed.queue_free()
	await process_frame
