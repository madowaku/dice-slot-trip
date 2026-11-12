extends SceneTree

## DICE TOWER on the shared casino table: rules, the ladder of returns, the
## climb / step-off decision, settlement once, and resume on the same face.

const Bank = preload("res://scripts/game/casino_bank.gd")
const TowerModel = preload("res://scripts/game/dice_tower_model.gd")
const TowerScreen = preload("res://scripts/app/dice_tower_screen.gd")
const TOWER_SCENE: PackedScene = preload("res://scenes/casino/DiceTower.tscn")

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
	test_save_path = "user://dice_slot_trip_dice_tower_tests_%d.json" % OS.get_process_id()
	Bank.set_test_save_path(test_save_path)
	TowerScreen.suppress_audio_for_tests = true
	TowerScreen.instant_for_tests = true
	_test_model()
	await _test_first_visit_and_setup()
	await _test_climb_and_step_off()
	await _test_bust_and_complete()
	TowerScreen.instant_for_tests = false
	await _test_resume_and_leave()
	TowerScreen.instant_for_tests = true
	await _test_low_balance()
	TowerScreen.instant_for_tests = false
	TowerScreen.suppress_audio_for_tests = false
	_remove_save()
	Bank.clear_test_save_path()
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	print("DICE TOWER tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)


func _remove_save() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(test_save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path + suffix))


func _fresh_bank(chips: int, guide_seen: bool = true) -> void:
	_remove_save()
	var data := Bank.default_data()
	data["chips"] = chips
	_expect(Bank.save_data(data), "fixture bank saves with %d chips" % chips)
	if guide_seen:
		Bank.mark_guide_seen("dice_tower")


func _open() -> DiceTowerScreen:
	var screen := TOWER_SCENE.instantiate() as DiceTowerScreen
	root.add_child(screen)
	await process_frame
	await process_frame
	return screen


func _visible_text(screen: Node) -> String:
	var parts: Array[String] = []
	for node: Node in screen.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree():
			parts.append((node as Label).text)
	for node: Node in screen.find_children("*", "Button", true, false):
		if (node as Button).is_visible_in_tree():
			parts.append((node as Button).text)
	return "\n".join(parts)


func _test_model() -> void:
	var game := TowerModel.new_game(20)
	game = TowerModel.apply_roll(game, 3)
	_expect(int(game.floor) == 1 and TowerModel.cashout_payout(game) == 22, "2-5 climbs one floor; floor 1 returns 22 on a 20 wager")
	game = TowerModel.apply_roll(game, 6)
	_expect(int(game.floor) == 3 and TowerModel.cashout_payout(game) == 30, "6 climbs two floors")
	game = TowerModel.apply_roll(game, 1)
	_expect(bool(game.busted) and int(game.payout) == 0 and int(game.lost_payout) == 30, "1 loses the run and remembers what stepping off would have paid")
	var top := TowerModel.new_game(20)
	top["floor"] = 9
	top = TowerModel.apply_roll(top, 6)
	_expect(bool(top.completed) and int(top.payout) == 84 and int(top.floor) == 10, "reaching the 10th floor pays 84 at once")


func _test_first_visit_and_setup() -> void:
	_fresh_bank(100, false)
	var screen := await _open()
	_expect(screen.shell.is_guide_open() and screen.shell.guide_step_count() <= 3, "the first visit opens a guide of three steps or fewer")
	(screen.find_child("GuideCloseButton", true, false) as Button).pressed.emit()
	await process_frame
	_expect(not screen.shell.is_guide_open() and Bank.has_seen_guide("dice_tower"), "closing the guide remembers it")
	_expect(screen.view_state == "setup" and screen.back_button.text == "カジノへ戻る", "setup uses the shared return label")
	_expect(screen.find_children("PrimaryButton", "Button", true, false).size() == 1 and screen.start_button.text == "サイコロを振る", "setup has one primary action")
	_expect(not screen.cashout_button.is_visible_in_tree(), "stepping off is not offered before the climb")
	_expect(screen.find_child("CasinoHowTo3Steps", true, false) == null and screen.find_child("TowerContentScroll", true, false) == null, "the always-on how-to and the scrolling layout are gone")
	_expect(screen.floor_rows.size() == 10, "the ladder shows all ten floors")
	_expect((screen.floor_amount_labels[1] as Label).text == "+22" and (screen.floor_amount_labels[10] as Label).text == "+84", "the ladder shows what each floor returns for the chosen wager")
	(screen.bet_buttons[50] as Button).pressed.emit()
	_expect((screen.floor_amount_labels[1] as Label).text == "+55" and "+210" in screen.shell.status_label.text, "changing the wager updates every floor's return")
	_expect("×" not in _visible_text(screen), "no multiplier notation is shown")
	screen.queue_free()
	await process_frame


func _test_climb_and_step_off() -> void:
	_fresh_bank(100)
	var screen := await _open()
	_expect(not screen.shell.is_guide_open(), "the guide does not reopen on later visits")
	(screen.bet_buttons[20] as Button).pressed.emit()
	screen.queued_roll_value = 4
	screen.start_button.pressed.emit()
	await process_frame
	_expect(Bank.balance() == 80 and Bank.has_active_game("dice_tower"), "the first roll commits the wager once")
	_expect(screen.view_state == "active" and int(screen.game.floor) == 1, "a 4 climbs to the first floor")
	_expect(screen.cashout_button.is_visible_in_tree() and "+22" in screen.cashout_button.text, "stepping off shows the chips it pays")
	_expect("いま 1F" in screen.shell.status_label.text and "+22" in screen.shell.status_label.text and "1が出たら 0" in screen.shell.status_label.text, "the status states what is at stake")
	_expect(screen.roll_button.text == "もう1段（振る）", "the primary climbs again")
	_expect(not screen.shell.bet_row.visible, "the wager row is hidden during the climb")
	screen.queued_roll_value = 6
	screen.roll_button.pressed.emit()
	await process_frame
	_expect(int(screen.game.floor) == 3 and "+30" in screen.cashout_button.text and Bank.balance() == 80, "a 6 climbs two floors and costs nothing")
	screen.cashout_button.pressed.emit()
	await process_frame
	_expect(screen.view_state == "result" and Bank.balance() == 110 and not Bank.has_active_game("dice_tower"), "stepping off at 3F pays 30 and clears the run")
	_expect("+30" in screen.shell.result_headline.text and "3F" in screen.shell.result_detail.text, "the result names the floor and the chips")
	screen.call("_finish_run")
	_expect(Bank.balance() == 110, "a repeated settlement pays nothing more")
	_expect("もう一度" in screen.start_button.text and screen.shell.bet_row.visible, "the result offers another climb and the wager row")
	(screen.bet_buttons[10] as Button).pressed.emit()
	_expect(screen.view_state == "setup" and screen.selected_bet == 10, "choosing a wager on the result returns to setup")
	screen.queue_free()
	await process_frame


func _test_bust_and_complete() -> void:
	_fresh_bank(100)
	var screen := await _open()
	screen.queued_roll_value = 5
	screen.start_button.pressed.emit()
	await process_frame
	screen.queued_roll_value = 1
	screen.roll_button.pressed.emit()
	await process_frame
	_expect(screen.view_state == "result" and Bank.balance() == 80 and bool(screen.game.busted), "a 1 loses only the wager")
	_expect(screen.shell.result_headline.text == "1が出た…" and "+22" in screen.shell.result_detail.text, "the bust says what stepping off would have paid")
	screen.queued_roll_value = 1
	screen.start_button.pressed.emit()
	await process_frame
	_expect(Bank.balance() == 60 and screen.view_state == "result" and "最初の1投" in screen.shell.result_detail.text, "「もう一度」 restarts at the same wager; a first-roll 1 is a bust")
	screen.queue_free()
	await process_frame

	_fresh_bank(100)
	screen = await _open()
	screen.queued_roll_value = 6
	screen.start_button.pressed.emit()
	await process_frame
	for _climb: int in range(4):
		screen.queued_roll_value = 6
		screen.roll_button.pressed.emit()
		await process_frame
	_expect(screen.view_state == "result" and bool(screen.game.completed) and Bank.balance() == 164, "five 6s reach the top and pay 84 automatically")
	_expect("頂上" in screen.shell.result_headline.text and "+84" in screen.shell.result_headline.text, "the result celebrates the top")
	screen.queue_free()
	await process_frame


func _test_resume_and_leave() -> void:
	_fresh_bank(100)
	var screen := await _open()
	screen.queued_roll_value = 3
	screen.start_button.pressed.emit()
	_expect(screen.rolling and screen.view_state == "rolling", "the first roll locks the table at once")
	var pending: Array = Bank.active_game("dice_tower").get("pending_rolls", []) as Array
	_expect(not pending.is_empty() and int((pending[0] as Dictionary).get("value", 0)) == 3 and Bank.balance() == 80, "the wager and the first face are saved before the animation")
	screen.start_button.pressed.emit()
	_expect(Bank.balance() == 80, "a second press while rolling charges nothing")
	var backs: Array[int] = []
	screen.back_requested.connect(func() -> void: backs.append(1))
	screen.back_button.pressed.emit()
	_expect(backs.is_empty(), "leaving is blocked while the die is in the air")
	screen.queue_free()
	await process_frame
	screen = await _open()
	await create_timer(1.3).timeout
	_expect(screen.view_state == "active" and int(screen.game.floor) == 1 and int(screen.game.last_roll) == 3, "a fresh screen resumes the exact pending face")
	_expect(Bank.balance() == 80 and Bank.has_active_game("dice_tower"), "resuming neither charges again nor settles early")
	backs.clear()
	screen.back_requested.connect(func() -> void: backs.append(1))
	screen.back_button.pressed.emit()
	_expect(backs.size() == 1 and Bank.has_active_game("dice_tower"), "leaving mid-climb is allowed and keeps the run saved")
	screen.queue_free()
	await process_frame
	screen = await _open()
	_expect(screen.view_state == "active" and int(screen.game.floor) == 1 and "+22" in screen.cashout_button.text, "returning finds the same floor")
	screen.cashout_button.pressed.emit()
	await process_frame
	_expect(Bank.balance() == 102 and not Bank.has_active_game("dice_tower"), "the resumed run settles once")
	screen.queue_free()
	await process_frame

	# A completion face saved mid-animation pays out on reopen.
	_fresh_bank(100)
	screen = await _open()
	screen.queued_roll_value = 4
	screen.start_button.pressed.emit()
	await create_timer(1.3).timeout
	screen.game["floor"] = 9
	screen.game["highest_floor"] = 9
	screen.game["pending_rolls"] = [{"kind": "roll", "value": 6, "from_floor": 9, "roll_index": 2}]
	Bank.update_game("dice_tower", screen.game, screen.game_id)
	screen.queue_free()
	await process_frame
	screen = await _open()
	await create_timer(1.3).timeout
	_expect(bool(screen.game.completed) and int(screen.game.payout) == 84 and not Bank.has_active_game("dice_tower") and Bank.balance() == 164, "a saved completion face pays once on reopen")
	screen.queue_free()
	await process_frame


func _test_low_balance() -> void:
	_fresh_bank(15)
	var screen := await _open()
	_expect(screen.selected_bet == 10 and (screen.bet_buttons[20] as Button).disabled and not screen.start_button.disabled, "with 15 chips only the 10 wager is offered")
	screen.queue_free()
	await process_frame
	_fresh_bank(4)
	screen = await _open()
	screen.start_button.pressed.emit()
	_expect(screen.start_button.disabled and Bank.balance() == 4 and not Bank.has_active_game("dice_tower"), "no climb starts without chips")
	screen.queue_free()
	await process_frame
