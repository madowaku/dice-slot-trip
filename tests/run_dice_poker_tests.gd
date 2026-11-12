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
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(720, 1600)
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
	# Top up to an exact 1000 so the checks do not depend on the starting gift.
	CasinoBankScript.add_chips(1000 - CasinoBankScript.balance())

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

	# Feel fixtures A/B/D keep the presentation contract honest without changing
	# the pure five-dice rules: only unkept indices may be supplied to a reroll.
	var scenario_a: Dictionary = DicePokerScript.apply_initial(DicePokerScript.new_game(20), [3, 3, 2, 5, 6])
	scenario_a = DicePokerScript.set_keep(scenario_a, 0, true)
	scenario_a = DicePokerScript.set_keep(scenario_a, 1, true)
	_expect(DicePokerScript.reroll_indices(scenario_a) == [2, 3, 4], "Scenario A rerolls only the three open dice")
	var scenario_a_resolved: Dictionary = DicePokerScript.apply_reroll(scenario_a, [3, 5, 5], [2, 3, 4])
	_expect((scenario_a_resolved["dice"] as Array) == [3, 3, 3, 5, 5], "Scenario A preserves two held 3s while the open dice land")

	var scenario_b: Dictionary = DicePokerScript.apply_initial(DicePokerScript.new_game(20), [3, 3, 2, 5, 6])
	scenario_b = DicePokerScript.toggle_keep(scenario_b, 0)
	scenario_b = DicePokerScript.toggle_keep(scenario_b, 0)
	scenario_b = DicePokerScript.toggle_keep(scenario_b, 0)
	_expect(DicePokerScript.is_kept(scenario_b, 0) and DicePokerScript.kept_count(scenario_b) == 1, "Scenario B unhold then rehold ends in HOLD")

	var scenario_d: Dictionary = DicePokerScript.apply_initial(DicePokerScript.new_game(20), [4, 4, 4, 4, 2])
	scenario_d = DicePokerScript.keep_all(scenario_d)
	_expect(not DicePokerScript.can_reroll(scenario_d) and DicePokerScript.can_lock_hand(scenario_d), "Scenario D keeps the final decision available after intentional holds")

func _open_table() -> DicePokerScreen:
	var node: Node = DICE_POKER_SCENE.instantiate()
	root.add_child(node)
	await process_frame
	await process_frame
	return node as DicePokerScreen

func _visible_label_text(screen: Node) -> String:
	var parts: Array[String] = []
	for node: Node in screen.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree():
			parts.append((node as Label).text)
	for node: Node in screen.find_children("*", "Button", true, false):
		if (node as Button).is_visible_in_tree():
			parts.append((node as Button).text)
	return "\n".join(parts)

func _test_scene_flow() -> void:
	DicePokerScreenScript.instant_for_tests = true

	# --- first visit and the shared table frame -------------------------
	var scene: DicePokerScreen = await _open_table()
	_expect(scene.shell.is_guide_open() and scene.shell.guide_step_count() <= 3, "first visit opens a guide of three steps or fewer")
	var reference := scene.find_child("GuideReference", true, false) as Label
	_expect(reference != null and "ファイブ" in reference.text and "ワンペア" in reference.text, "the hand list lives in the guide, not on the table")
	(scene.find_child("GuideCloseButton", true, false) as Button).pressed.emit()
	await process_frame
	_expect(not scene.shell.is_guide_open() and CasinoBankScript.has_seen_guide("dice_poker"), "closing the guide remembers it")
	_expect(scene.view_state == "setup" and scene.back_button.text == "カジノへ戻る", "setup uses the shared return label")
	_expect(scene.find_children("PrimaryButton", "Button", true, false).size() == 1 and scene.deal_button.text == "ダイスを配る", "setup has exactly one primary action")
	_expect(scene.find_child("CasinoHowTo3Steps", true, false) == null, "the always-on how-to panel is gone")
	var setup_copy := _visible_label_text(scene)
	_expect("×" not in setup_copy and "PAY TABLE" not in setup_copy and "FULL HOUSE" not in setup_copy, "setup shows no pay table or multiplier notation")
	_expect(scene.keep_buttons.size() == 5, "five dice tap targets exist")
	for index: int in scene.keep_buttons:
		_expect((scene.keep_buttons[index] as Button).custom_minimum_size.y >= 96.0 and (scene.keep_buttons[index] as Button).custom_minimum_size.x >= 96.0, "die %d tap target meets the touch size" % (index + 1))
		_expect(not (scene.keep_buttons[index] as Button).is_visible_in_tree(), "die %d cannot be kept before the deal" % (index + 1))

	# --- deal: the wager and the decided dice are saved before animation --
	DicePokerScreenScript.instant_for_tests = false
	(scene.bet_buttons[20] as Button).pressed.emit()
	scene.queued_roll_batch = [[2, 2, 3, 4, 5], [6, 6, 6, 6, 6]]
	scene.deal_button.pressed.emit()
	_expect(scene.presentation_locked and scene.view_state == "rolling", "dealing locks the table at once")
	var active: Dictionary = CasinoBankScript.active_game("dice_poker")
	var pending: Array = active.get("pending_rolls", []) as Array
	_expect(not pending.is_empty() and int((pending[0] as Dictionary).get("values", [0])[0]) == 2, "dealt values persist before the animation")
	_expect(CasinoBankScript.balance() == 980, "the deal charges the wager once")
	scene.deal_button.pressed.emit()
	_expect(CasinoBankScript.balance() == 980, "a second press while rolling charges nothing")
	scene.back_button.pressed.emit()
	await create_timer(1.4).timeout
	DicePokerScreenScript.instant_for_tests = true
	_expect(scene.view_state == "active" and not scene.presentation_locked, "the hand becomes playable after the roll")
	_expect((scene.game.get("dice", []) as Array) == [2, 2, 3, 4, 5], "the dealt hand matches the saved values")

	# --- active: one line says the hand and what it returns ---------------
	_expect("ワンペア" in scene.shell.status_label.text and "+4" in scene.shell.status_label.text, "the status names the current hand and its return for this wager")
	_expect("×" not in _visible_label_text(scene), "play shows no multiplier notation")
	_expect("振り直す" in scene.reroll_button.text and "あと2回" in scene.reroll_button.text and scene.lock_button.is_visible_in_tree(), "the primary re-rolls while taking the hand stays a quiet secondary")
	_expect(not scene.shell.bet_row.visible, "the wager row is hidden during the hand")
	scene.keep_buttons[0].pressed.emit()
	scene.keep_buttons[1].pressed.emit()
	_expect((scene.keep_buttons[0] as Button).button_pressed and (scene.keep_tags[0] as Label).visible and not (scene.keep_tags[2] as Label).visible, "kept dice are framed and tagged")
	_expect(scene.dice_presentation.base_positions[0].y > scene.dice_presentation.base_positions[2].y, "kept dice lift off the felt")
	var saved_kept: Array = (CasinoBankScript.active_game("dice_poker").get("session", {}) as Dictionary).get("kept", []) as Array
	_expect(saved_kept.size() == 5 and bool(saved_kept[0]) and bool(saved_kept[1]) and not bool(saved_kept[2]), "keeps are saved with the round")
	scene.keep_buttons[1].pressed.emit()
	_expect(not (scene.keep_buttons[1] as Button).button_pressed, "tapping a kept die releases it")
	scene.keep_buttons[1].pressed.emit()

	# --- re-roll only the dice that were not kept -------------------------
	scene.reroll_button.pressed.emit()
	await process_frame
	_expect((scene.game.get("dice", []) as Array) == [2, 2, 6, 6, 6] and int(scene.game.get("rerolls_used", 0)) == 1, "the re-roll replaces only the unkept dice")
	_expect("フルハウス" in scene.shell.status_label.text and "+20" in scene.shell.status_label.text and "あと1回" in scene.reroll_button.text, "the status and the remaining re-rolls update")
	_expect(CasinoBankScript.balance() == 980, "re-rolling costs nothing")

	# --- take the hand ----------------------------------------------------
	scene.lock_button.pressed.emit()
	await process_frame
	_expect(scene.view_state == "result" and scene.result_view.visible, "taking the hand shows the result on the table")
	_expect(CasinoBankScript.balance() == 1000 and not CasinoBankScript.has_active_game("dice_poker"), "a full house returns the 20 wager and clears the round")
	_expect("フルハウス" in scene.shell.result_headline.text and "+20" in scene.shell.result_headline.text, "the result names the hand and the chips returned")
	_expect("賭け金 20" in scene.shell.result_detail.text and "受け取り 20" in scene.shell.result_detail.text, "the result states wager and return")
	scene.call("_settle_finished_game")
	_expect(CasinoBankScript.balance() == 1000, "a repeated settlement pays nothing more")
	_expect("もう一度" in scene.deal_button.text and scene.shell.bet_row.visible, "the result offers another hand and the wager row")

	# --- again, then take a hand without keeping anything -----------------
	scene.queued_roll_batch = [[1, 2, 3, 4, 6]]
	scene.deal_button.pressed.emit()
	await process_frame
	_expect(scene.view_state == "active" and CasinoBankScript.balance() == 980, "「もう一度」 deals a new hand at the same wager")
	scene.lock_button.pressed.emit()
	await process_frame
	_expect(scene.view_state == "result" and CasinoBankScript.balance() == 980 and scene.shell.result_headline.text == "役なし", "a hand can be taken as dealt; no hand returns nothing")

	# --- all kept: the primary itself takes the hand ----------------------
	scene.queued_roll_batch = [[4, 4, 4, 4, 2]]
	scene.deal_button.pressed.emit()
	await process_frame
	for index: int in range(5):
		scene.keep_buttons[index].pressed.emit()
	_expect(scene.reroll_button.text == "この役で受け取る" and not scene.lock_button.is_visible_in_tree(), "with every die kept there is one action: take the hand")
	scene.reroll_button.pressed.emit()
	await process_frame
	_expect(scene.view_state == "result" and CasinoBankScript.balance() == 960 + 34 and "フォー" in scene.shell.result_headline.text, "four of a kind returns 34 on a 20 wager")

	# --- the second re-roll ends the hand ---------------------------------
	scene.queued_roll_batch = [[1, 2, 3, 4, 6], [1, 1, 3, 4, 6], [1, 1, 1, 4, 6]]
	scene.deal_button.pressed.emit()
	await process_frame
	scene.reroll_button.pressed.emit()
	await process_frame
	_expect(scene.view_state == "active" and "あと1回" in scene.reroll_button.text, "one re-roll remains after the first")
	scene.reroll_button.pressed.emit()
	await process_frame
	_expect(scene.view_state == "result" and "スリー" in scene.shell.result_headline.text and CasinoBankScript.balance() == 994 - 20 + 12, "the last re-roll settles the hand automatically")

	# --- changing the wager from the result -------------------------------
	(scene.bet_buttons[50] as Button).pressed.emit()
	_expect(scene.view_state == "setup" and scene.selected_bet == 50 and not scene.result_view.visible, "choosing a wager on the result returns to setup")
	var backs: Array[int] = []
	scene.back_requested.connect(func() -> void: backs.append(1))
	scene.back_button.pressed.emit()
	_expect(backs.size() == 1, "「カジノへ戻る」 leaves the table")
	scene.queue_free()
	await process_frame

	# --- an interrupted re-roll resumes on the same dice ------------------
	DicePokerScreenScript.instant_for_tests = false
	scene = await _open_table()
	_expect(not scene.shell.is_guide_open(), "the guide does not reopen on later visits")
	(scene.bet_buttons[20] as Button).pressed.emit()
	scene.queued_roll_batch = [[1, 2, 3, 4, 5], [1, 6, 6, 6, 6]]
	scene.deal_button.pressed.emit()
	await create_timer(1.4).timeout
	scene.keep_buttons[0].pressed.emit()
	scene.reroll_button.pressed.emit()
	_expect(scene.presentation_locked, "the re-roll locks the table")
	var before_close: int = CasinoBankScript.balance()
	scene.queue_free()
	await process_frame
	var resumed: DicePokerScreen = await _open_table()
	await create_timer(1.4).timeout
	_expect(int(resumed.game.get("rerolls_used", 0)) == 1 and (resumed.game.get("dice", []) as Array) == [1, 6, 6, 6, 6], "a fresh screen resumes the exact pending re-roll")
	_expect(CasinoBankScript.balance() == before_close and resumed.view_state == "active", "resuming charges nothing and returns to the hand")

	# --- leaving mid-hand keeps the round ---------------------------------
	DicePokerScreenScript.instant_for_tests = true
	var left: Array[int] = []
	resumed.back_requested.connect(func() -> void: left.append(1))
	resumed.back_button.pressed.emit()
	_expect(left.size() == 1 and CasinoBankScript.has_active_game("dice_poker"), "leaving mid-hand is allowed and keeps the round saved")
	resumed.queue_free()
	await process_frame
	resumed = await _open_table()
	# Faces read back from JSON are floats, so compare through the screen's int view.
	_expect(resumed.view_state == "active" and resumed.call("_state_dice", resumed.game) == [1, 6, 6, 6, 6], "returning finds the same hand")
	resumed.lock_button.pressed.emit()
	await process_frame
	_expect(not CasinoBankScript.has_active_game("dice_poker") and CasinoBankScript.balance() == before_close + 34, "the resumed hand settles once")
	resumed.queue_free()
	await process_frame

	# --- too few chips ----------------------------------------------------
	var poor: Dictionary = CasinoBankScript.load_data()
	poor["chips"] = 15
	CasinoBankScript.save_data(poor)
	scene = await _open_table()
	_expect(scene.selected_bet == 10 and (scene.bet_buttons[20] as Button).disabled and not scene.deal_button.disabled, "with 15 chips only the 10 wager is offered")
	scene.queue_free()
	await process_frame
	poor["chips"] = 3
	CasinoBankScript.save_data(poor)
	scene = await _open_table()
	scene.deal_button.pressed.emit()
	_expect(scene.deal_button.disabled and CasinoBankScript.balance() == 3 and not CasinoBankScript.has_active_game("dice_poker"), "no hand starts without chips")
	scene.queue_free()
	await process_frame
	DicePokerScreenScript.instant_for_tests = false

	# Deterministic model fixtures: held faces stay while targets resolve.
	var fixtures: Array[Dictionary] = [
		{"name": "C pair to three", "start": [3, 3, 2, 5, 6], "reroll": [3, 3, 3, 5, 6], "rank": DicePokerScript.RANK_THREE},
		{"name": "E full house", "start": [3, 3, 2, 5, 6], "reroll": [3, 3, 2, 2, 2], "rank": DicePokerScript.RANK_FULL_HOUSE},
		{"name": "F no hand", "start": [1, 2, 3, 4, 6], "reroll": [1, 2, 3, 4, 6], "rank": DicePokerScript.RANK_NO_HAND},
		{"name": "G four held", "start": [4, 4, 4, 4, 2], "reroll": [6, 6, 6, 6, 5], "rank": DicePokerScript.RANK_FOUR},
	]
	for fixture: Dictionary in fixtures:
		var state: Dictionary = DicePokerScript.apply_initial(DicePokerScript.new_game(20), fixture["start"] as Array)
		for index: int in range(4 if fixture["name"] == "G four held" else 2):
			state = DicePokerScript.toggle_keep(state, index)
		var resolved: Dictionary = DicePokerScript.apply_reroll(state, fixture["reroll"] as Array)
		_expect((resolved["dice"] as Array)[0] == (state["dice"] as Array)[0], "%s keeps held die" % fixture["name"])
		_expect(str((DicePokerScript.evaluate(resolved["dice"] as Array))["rank"]) == str(fixture["rank"]), "%s resolves deterministic rank" % fixture["name"])

func _trace_contains_in_order(trace: Array[String], expected: Array[String]) -> bool:
	var cursor: int = 0
	for item: String in trace:
		if cursor < expected.size() and item == expected[cursor]:
			cursor += 1
	return cursor == expected.size()
