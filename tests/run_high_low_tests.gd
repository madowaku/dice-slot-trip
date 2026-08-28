extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const HighLowScript = preload("res://scripts/game/high_low_model.gd")
const HighLowScreenScript = preload("res://scripts/app/high_low_screen.gd")
const HIGH_LOW_SCENE: PackedScene = preload("res://scenes/casino/HighLow.tscn")

var failures := 0
var assertions := 0
var test_save_path := ""

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
	HighLowScreenScript.suppress_audio_for_tests = true
	# This rules/UI harness does not assert sound playback. Disable the SFX
	# router so transient AudioStreamPlayback objects cannot outlive the test;
	# the production screen still routes every cue when the game runs normally.
	var ui_sfx := root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_enabled", false)
	_test_multiplier_table_and_ranges()
	_test_model_vectors()
	await _test_scene_flow()
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	await process_frame
	HighLowScreenScript.suppress_audio_for_tests = false
	_cleanup_test_save()
	print("HIGH LOW tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _configure_test_save() -> void:
	test_save_path = "user://dice_slot_trip_high_low_tests_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(test_save_path)
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.add_chips(1000)

func _cleanup_test_save() -> void:
	if not test_save_path.is_empty() and FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.clear_test_save_path()

func _test_multiplier_table_and_ranges() -> void:
	var expected := {
		1: {"low": 0.0, "same": 5.5, "high": 1.1},
		2: {"low": 5.5, "same": 5.5, "high": 1.4},
		3: {"low": 2.8, "same": 5.5, "high": 1.8},
		4: {"low": 1.8, "same": 5.5, "high": 2.8},
		5: {"low": 1.4, "same": 5.5, "high": 5.5},
		6: {"low": 1.1, "same": 5.5, "high": 0.0},
	}
	for current: int in range(1, 7):
		for choice: String in HighLowScript.CHOICES:
			_expect(is_equal_approx(HighLowScript.multiplier_for(current, choice), float(expected[current][choice])), "table multiplier %d/%s" % [current, choice])
			var faces := HighLowScript.winning_faces(current, choice)
			for face: int in range(1, 7):
				var expected_win := (choice == "low" and face < current) or (choice == "same" and face == current) or (choice == "high" and face > current)
				_expect((face in faces) == expected_win, "strict winning range %d/%s/%d" % [current, choice, face])
		_expect(not HighLowScript.is_choice_available(current, "low") if current == 1 else true, "LOW is disabled on CURRENT 1")
		_expect(not HighLowScript.is_choice_available(current, "high") if current == 6 else true, "HIGH is disabled on CURRENT 6")
	_expect(not HighLowScript.is_choice_available(0, "same"), "unknown CURRENT disables all choices")

func _test_model_vectors() -> void:
	var high := HighLowScript.new_game(20, 3)
	high = HighLowScript.resolve_choice(high, "high", 5)
	_expect(int(high.get("pot", 0)) == 36 and int(high.get("current", 0)) == 5 and int(high.get("streak", 0)) == 1, "BET20 CURRENT3 HIGH roll5 pays floor 36 and advances CURRENT")
	var same := HighLowScript.new_game(20, 1)
	same = HighLowScript.resolve_choice(same, "same", 1)
	_expect(int(same.get("pot", 0)) == 110 and int(same.get("current", 0)) == 1, "BET20 CURRENT1 SAME roll1 pays 110")
	var miss := HighLowScript.resolve_choice(HighLowScript.new_game(20, 3), "high", 2)
	_expect(bool(miss.get("finished", false)) and not bool(miss.get("active", true)) and int(miss.get("pot", -1)) == 0 and int(miss.get("payout", -1)) == 0, "miss ends the run with zero POT and payout")
	var floor_case := HighLowScript.resolve_choice(HighLowScript.new_game(10, 3), "high", 4)
	_expect(int(floor_case.get("pot", 0)) == 18, "POT multiplication uses floor for 10 x 1.8")
	var cash := HighLowScript.cash_out(high)
	_expect(bool(cash.get("finished", false)) and int(cash.get("payout", 0)) == 36 and str(cash.get("result", "")) == "cashout", "cash out returns current POT")
	_expect(HighLowScript.cash_out(cash) == cash, "finished model cashout is idempotent")
	var five := HighLowScript.new_game(20, 1)
	for pair: Array in [["same", 1], ["high", 2], ["high", 3], ["high", 4], ["high", 5]]:
		five = HighLowScript.resolve_choice(five, str(pair[0]), int(pair[1]))
	_expect(bool(five.get("auto_cashed", false)) and bool(five.get("finished", false)) and int(five.get("streak", 0)) == 5 and int(five.get("payout", 0)) > 0, "five wins auto cash out")

func _test_scene_flow() -> void:
	var scene := HIGH_LOW_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.get_script() == HighLowScreenScript, "HIGH LOW scene instantiates HighLowScreen")
	_expect(scene.setup_view.visible and not scene.active_view.visible and not scene.result_view.visible, "HIGH LOW opens on setup")
	_expect(scene.bet_buttons.size() == 3 and scene.choice_buttons.size() == 3, "HIGH LOW builds three bets and three choices")
	for amount: int in scene.bet_buttons:
		_expect((scene.bet_buttons[amount] as Button).custom_minimum_size.y >= 96.0, "BET %d meets touch target" % amount)
	for choice: String in scene.choice_buttons:
		_expect((scene.choice_buttons[choice] as Button).custom_minimum_size.y >= 96.0, "choice %s meets touch target" % choice)
	scene.rng_seed = 11
	scene.queued_roll_value = 3
	scene.call("_start_game")
	await create_timer(0.58).timeout
	_expect(scene.active_view.visible and int(scene.game.get("current", 0)) == 3 and CasinoBankScript.balance() == 980, "GAME START charges BET and resolves persisted CURRENT")
	scene.queued_roll_value = 5
	(scene.choice_buttons["high"] as Button).pressed.emit()
	var pending := CasinoBankScript.active_game("high_low")
	var pending_rolls: Array = pending.get("pending_rolls", []) as Array
	_expect(not pending_rolls.is_empty() and int((pending_rolls[0] as Dictionary).get("value", 0)) == 5, "next face is persisted before HIGH animation")
	await create_timer(0.58).timeout
	_expect(int(scene.game.get("pot", 0)) == 36 and int(scene.game.get("current", 0)) == 5 and int(scene.game.get("streak", 0)) == 1, "scene resolves HIGH vector")
	_expect((CasinoBankScript.active_game("high_low").get("pending_rolls", []) as Array).is_empty(), "resolved roll clears the persisted pending queue")
	(scene.cashout_button as Button).pressed.emit()
	await process_frame
	_expect(scene.result_view.visible and int(scene.game.get("payout", 0)) == 36 and CasinoBankScript.balance() == 1016, "CASH OUT settles immediately")
	(scene.cashout_button as Button).pressed.emit()
	_expect(CasinoBankScript.balance() == 1016, "CASH OUT replay does not pay twice")
	scene.queue_free()
	await process_frame

	# Resume the exact pending face after the first screen is removed mid-roll.
	var first := HIGH_LOW_SCENE.instantiate()
	root.add_child(first)
	await process_frame
	first.queued_roll_value = 2
	first.call("_start_game")
	await create_timer(0.58).timeout
	first.queued_roll_value = 6
	(first.choice_buttons["high"] as Button).pressed.emit()
	var active_before_resume := CasinoBankScript.active_game("high_low")
	var stored := (active_before_resume.get("pending_rolls", []) as Array)[0] as Dictionary
	_expect(int(stored.get("value", 0)) == 6, "resume fixture stores forced HIGH face")
	first.queue_free()
	await process_frame
	var resumed := HIGH_LOW_SCENE.instantiate()
	root.add_child(resumed)
	await process_frame
	await create_timer(0.58).timeout
	_expect(int(resumed.game.get("current", 0)) == 6 and int(resumed.game.get("pot", 0)) == 28 and CasinoBankScript.has_active_game("high_low"), "new screen resolves the same pending face")
	resumed.call("_on_cashout_pressed")
	await process_frame
	_expect(not CasinoBankScript.has_active_game("high_low"), "resumed game settles cleanly")
	resumed.queue_free()
	await process_frame
