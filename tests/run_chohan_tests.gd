extends SceneTree

## 丁半: seeded rule tests, CasinoBank v2 -> v3 migration, the shared table
## shell contract, and one full round through the screen.

const Model = preload("res://scripts/game/chohan_model.gd")
const Bank = preload("res://scripts/game/casino_bank.gd")
const ShellScript = preload("res://scripts/ui/casino_table_shell.gd")
const ScreenScript = preload("res://scripts/app/chohan_screen.gd")
const CHOHAN_SCENE: PackedScene = preload("res://scenes/casino/Chohan.tscn")

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
	test_save_path = "user://dice_slot_trip_casino_chohan_%d.json" % OS.get_process_id()
	Bank.set_test_save_path(test_save_path)
	ScreenScript.instant_for_tests = true
	ScreenScript.suppress_audio_for_tests = true
	_test_model_rules()
	_test_model_seeded_rolls()
	_test_save_migration_from_v2()
	await _test_shell_contract()
	await _test_screen_round()
	await _test_screen_resume_and_low_balance()
	ScreenScript.instant_for_tests = false
	ScreenScript.suppress_audio_for_tests = false
	_remove_save()
	Bank.clear_test_save_path()
	print("Chohan tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)


func _remove_save() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(test_save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path + suffix))


func _fresh_bank(chips: int) -> void:
	_remove_save()
	var data := Bank.default_data()
	data["chips"] = chips
	_expect(Bank.save_data(data), "fixture bank saves with %d chips" % chips)


func _test_model_rules() -> void:
	_expect(Model.parity_of([1, 1]) == Model.CHOICE_CHO and Model.parity_of([6, 6]) == Model.CHOICE_CHO, "doubles are always 丁")
	_expect(Model.parity_of([1, 2]) == Model.CHOICE_HAN and Model.parity_of([6, 5]) == Model.CHOICE_HAN, "odd totals are 半")
	var cho := 0
	var han := 0
	for first: int in range(1, 7):
		for second: int in range(1, 7):
			if Model.parity_of([first, second]) == Model.CHOICE_CHO:
				cho += 1
			else:
				han += 1
	_expect(cho == 18 and han == 18, "丁 and 半 are exactly even over all 36 outcomes")
	var win: Dictionary = Model.resolve(Model.CHOICE_CHO, [2, 4], 20)
	_expect(bool(win.ok) and bool(win.won) and int(win.total) == 6 and int(win.payout) == 40, "a correct call returns the wager doubled")
	var loss: Dictionary = Model.resolve(Model.CHOICE_HAN, [2, 4], 50)
	_expect(bool(loss.ok) and not bool(loss.won) and int(loss.payout) == 0, "a wrong call returns nothing")
	for bet: int in Model.BET_AMOUNTS:
		_expect(Model.win_payout(bet) == bet * 2, "bet %d pays exactly double" % bet)
	_expect(not bool(Model.resolve("zorome", [1, 1], 10).ok), "there is no side bet: unknown choices are rejected")
	_expect(not bool(Model.resolve(Model.CHOICE_CHO, [0, 7], 10).ok) and not bool(Model.resolve(Model.CHOICE_CHO, [1], 10).ok), "invalid dice are rejected")
	_expect(not bool(Model.resolve(Model.CHOICE_CHO, [1, 1], 0).ok), "a zero wager is rejected")
	_expect(Model.is_valid_bet(10) and Model.is_valid_bet(50) and not Model.is_valid_bet(15), "only the listed wagers are valid")


func _test_model_seeded_rolls() -> void:
	var first: Array = []
	var second: Array = []
	var rng_a := Model.make_rng(20261112)
	var rng_b := Model.make_rng(20261112)
	for index: int in range(40):
		first.append(Model.roll_dice(rng_a))
		second.append(Model.roll_dice(rng_b))
	_expect(first == second, "the same seed produces the same 40 rolls")
	var other: Array = []
	var rng_c := Model.make_rng(7)
	for index: int in range(40):
		other.append(Model.roll_dice(rng_c))
	_expect(other != first, "a different seed produces a different sequence")
	var in_range := true
	var faces_seen: Dictionary = {}
	var rng_d := Model.make_rng(99)
	for index: int in range(600):
		for value: int in Model.roll_dice(rng_d):
			in_range = in_range and value >= 1 and value <= 6
			faces_seen[value] = true
	_expect(in_range and faces_seen.size() == 6, "seeded rolls stay on 1-6 and reach every face")


func _test_save_migration_from_v2() -> void:
	_remove_save()
	# Written raw, exactly as a v2 build left it: no v3 keys at all.
	var v2 := {
		"version": 2,
		"chips": 137,
		"owned_cards": ["dice_racer_fox"],
		"conversion_keys": ["kyoto:lap:1"],
		"dice_race_play_count": 3,
		"dice_race_win_count": 1,
		"dice_race_best_payout": 60,
		"dice_roulette_play_count": 2,
		"dice_roulette_win_count": 1,
		"dice_roulette_best_payout": 47,
		"active_games": {"dice_tower": {"game_id": "dice_tower:1:1", "bet": 20, "session": {"floor": 2}}},
		"casino_settlements": {},
		"casino_settlement_order": [],
	}
	var file := FileAccess.open(test_save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(v2))
	file.close()
	var loaded := Bank.load_data()
	_expect(int(loaded.get("version", 0)) == 3 and Bank.SAVE_VERSION == 3, "a v2 save loads as v3")
	_expect(int(loaded.get("chips", 0)) == 137 and loaded.get("owned_cards", []) == ["dice_racer_fox"], "v2 chips and prizes survive")
	_expect(int(loaded.get("dice_race_best_payout", 0)) == 60 and loaded.get("conversion_keys", []) == ["kyoto:lap:1"], "v2 stats and conversion keys survive")
	_expect(Bank.has_active_game("dice_tower") and int(Bank.active_game("dice_tower").get("bet", 0)) == 20, "a v2 game in progress survives")
	_expect(loaded.get(Bank.GUIDES_SEEN_KEY, null) == [] and str(loaded.get(Bank.TARGET_PRIZE_KEY, "x")) == "", "new v3 fields start empty")
	_expect(not Bank.has_seen_guide("chohan"), "a migrated player still gets each first-play guide")
	_expect(Bank.mark_guide_seen("chohan") and Bank.has_seen_guide("chohan") and Bank.mark_guide_seen("chohan"), "marking a guide seen is saved and idempotent")
	_expect(Bank.set_target_prize_id("dice_racer_duck") and Bank.target_prize_id() == "dice_racer_duck", "the target prize is saved")
	var reloaded := Bank.load_data()
	_expect(int(reloaded.get("chips", 0)) == 137 and reloaded.get(Bank.GUIDES_SEEN_KEY, []) == ["chohan"], "v3 writes keep the migrated data")
	var broken := reloaded.duplicate(true)
	broken[Bank.GUIDES_SEEN_KEY] = "oops"
	broken[Bank.TARGET_PRIZE_KEY] = 12
	_expect(Bank.save_data(broken) and Bank.load_data().get(Bank.GUIDES_SEEN_KEY, null) == [] and Bank.target_prize_id() == "", "malformed v3 fields normalize to empty")


func _test_shell_contract() -> void:
	_fresh_bank(100)
	var shell: Control = ShellScript.new()
	root.add_child(shell)
	shell.configure("shell_probe", "TEST TABLE")
	await process_frame
	_expect(shell.back_button.text == "カジノへ戻る" and shell.back_button.name == "CasinoBackButton", "the shell uses the one shared return label")
	_expect(shell.title_label.text == "TEST TABLE" and shell.help_button.text == "？", "the header shows the title and a help button")
	shell.set_balance(100)
	_expect("100" in shell.chip_label.text, "the header shows the chip balance")
	var amounts: Array[int] = [10, 20, 50]
	shell.set_bets(amounts, 20, 30)
	_expect(shell.bet_buttons.size() == 3 and (shell.bet_buttons[20] as Button).button_pressed, "the wager row shows the selected amount")
	_expect((shell.bet_buttons[50] as Button).disabled and not (shell.bet_buttons[10] as Button).disabled, "unaffordable wagers are disabled")
	var picked: Array[int] = []
	shell.bet_selected.connect(func(amount: int) -> void: picked.append(amount))
	(shell.bet_buttons[10] as Button).pressed.emit()
	_expect(picked == [10] and shell.selected_bet() == 10, "choosing a wager reports it")
	var primaries: Array[Node] = shell.find_children("PrimaryButton", "Button", true, false)
	_expect(primaries.size() == 1, "there is exactly one primary button")
	var steps: Array[String] = ["one", "two", "three", "four"]
	shell.set_guide("HOW", steps)
	_expect(shell.guide_step_count() == 3, "the guide is capped at three steps")
	_expect(shell.show_guide_if_first_time() and shell.is_guide_open(), "the guide opens on the first visit")
	_expect(shell.find_child("GuideStep3", true, false) != null and shell.find_child("GuideStep4", true, false) == null, "the guide renders three steps at most")
	shell.close_guide()
	await process_frame
	_expect(not shell.is_guide_open() and Bank.has_seen_guide("shell_probe"), "closing the guide remembers it")
	_expect(not shell.show_guide_if_first_time(), "the guide does not reopen on later visits")
	shell.help_button.pressed.emit()
	_expect(shell.is_guide_open(), "the help button reopens the guide")
	shell.close_guide()
	shell.show_result(true, "WIN", "detail")
	_expect(shell.result_panel.visible and shell.result_headline.text == "WIN", "results appear on the table")
	shell.clear_result()
	_expect(not shell.result_panel.visible, "results can be cleared")
	shell.queue_free()
	await process_frame


func _test_screen_round() -> void:
	_fresh_bank(100)
	var screen: Control = CHOHAN_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var shell: Control = screen.shell
	_expect(shell.is_guide_open() and shell.guide_step_count() <= 3, "the first visit opens a guide of three steps or fewer")
	(shell.find_child("GuideCloseButton", true, false) as Button).pressed.emit()
	await process_frame
	_expect(not shell.is_guide_open() and Bank.has_seen_guide("chohan"), "the guide closes and is remembered")
	_expect(shell.primary_button.disabled and screen.cup.visible and not screen.dice_presentation.visible, "before a call the cup hides the dice and the roll is locked")
	_expect((shell.bet_buttons[20] as Button).button_pressed, "the default wager is preselected")
	(shell.bet_buttons[50] as Button).pressed.emit()
	screen.cho_button.pressed.emit()
	_expect(not shell.primary_button.disabled and "+100" in shell.status_label.text, "after a call the roll unlocks and shows the amount returned, not a multiplier")
	_expect("×" not in shell.status_label.text and "x" not in shell.status_label.text.to_lower(), "no multiplier notation is shown")
	var queued: Array[int] = [3, 5]
	screen.queued_dice = queued
	shell.primary_button.pressed.emit()
	await process_frame
	_expect(screen.state == screen.State.RESULT and Bank.balance() == 150, "a correct 丁 call on 3+5 pays 100 for a 50 wager")
	_expect(not Bank.has_active_game("chohan"), "the round is settled, not left active")
	_expect(shell.result_panel.visible and "+100" in shell.result_headline.text and "8" in shell.result_detail.text and "丁" in shell.result_detail.text, "the result names the total, the parity and the amount")
	_expect(screen.dice_presentation.visible and not screen.cup.visible and "150" in shell.chip_label.text, "the dice are revealed and the balance updates")
	_expect(shell.primary_button.text == "もう一度" and not shell.primary_button.disabled, "the primary button offers another round")

	# Calling the next round directly from the result.
	screen.han_button.pressed.emit()
	_expect(screen.state == screen.State.CHOOSING and screen.choice == Model.CHOICE_HAN and screen.cup.visible and not shell.result_panel.visible, "choosing 丁/半 on the result starts the next round")
	queued = [2, 2]
	screen.queued_dice = queued
	shell.primary_button.pressed.emit()
	await process_frame
	_expect(Bank.balance() == 100 and "はずれ" in shell.result_headline.text, "a wrong 半 call on 2+2 loses the 50 wager")
	shell.primary_button.pressed.emit()
	_expect(screen.state == screen.State.CHOOSING and screen.choice == "" and shell.primary_button.disabled, "「もう一度」 returns to a fresh call")

	# Seeded, unqueued rounds are reproducible end to end.
	screen.set_rng_seed(4242)
	var expected_rng := Model.make_rng(4242)
	var expected_balance := 100
	for index: int in range(5):
		var dice: Array[int] = Model.roll_dice(expected_rng)
		(shell.bet_buttons[10] as Button).pressed.emit()
		screen.cho_button.pressed.emit()
		shell.primary_button.pressed.emit()
		await process_frame
		expected_balance += -10 + int(Model.resolve(Model.CHOICE_CHO, dice, 10).payout)
		_expect(screen.last_result.get("dice", []) == dice and Bank.balance() == expected_balance, "seeded round %d matches the model" % (index + 1))
	var backs: Array[int] = []
	screen.back_requested.connect(func() -> void: backs.append(1))
	shell.back_button.pressed.emit()
	_expect(backs.size() == 1, "「カジノへ戻る」 leaves the table")
	screen.queue_free()
	await process_frame


func _test_screen_resume_and_low_balance() -> void:
	_fresh_bank(60)
	Bank.mark_guide_seen("chohan")
	var dice: Array[int] = [1, 2]
	var begun: Dictionary = Bank.begin_game("chohan", 20, {"choice": Model.CHOICE_HAN, "dice": dice, "pending_rolls": dice})
	_expect(bool(begun.get("ok", false)) and Bank.balance() == 40, "a round interrupted mid-shake has already charged its wager")
	var screen: Control = CHOHAN_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(not Bank.has_active_game("chohan") and Bank.balance() == 80, "reopening pays the interrupted round exactly once")
	_expect(screen.state == screen.State.RESULT and screen.shell.result_panel.visible and not screen.shell.is_guide_open(), "the interrupted round is shown as a result")
	screen.queue_free()
	await process_frame

	_fresh_bank(15)
	Bank.mark_guide_seen("chohan")
	screen = CHOHAN_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.selected_bet == 10 and (screen.shell.bet_buttons[20] as Button).disabled, "with 15 chips only the 10 wager is offered")
	screen.queue_free()
	await process_frame

	_fresh_bank(4)
	Bank.mark_guide_seen("chohan")
	screen = CHOHAN_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.selected_bet == 0 and screen.shell.primary_button.disabled and screen.cho_button.disabled, "with too few chips nothing can be wagered")
	screen.shell.primary_button.pressed.emit()
	_expect(Bank.balance() == 4 and not Bank.has_active_game("chohan"), "no round starts without chips")
	screen.queue_free()
	await process_frame
