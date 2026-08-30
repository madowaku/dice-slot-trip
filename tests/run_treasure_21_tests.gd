extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const Treasure21Script = preload("res://scripts/game/treasure_21_model.gd")
const Treasure21ScreenScript = preload("res://scripts/app/treasure_21_screen.gd")
const TREASURE_SCENE: PackedScene = preload("res://scenes/casino/Treasure21.tscn")

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
	Treasure21ScreenScript.suppress_audio_for_tests = true
	var ui_sfx := root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_enabled", false)
	_test_model_rules()
	await _test_scene_flow()
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	await process_frame
	Treasure21ScreenScript.suppress_audio_for_tests = false
	_cleanup_test_save()
	print("TREASURE 21 tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _configure_test_save() -> void:
	test_save_path = "user://dice_slot_trip_treasure_21_tests_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(test_save_path)
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.add_chips(1000)

func _cleanup_test_save() -> void:
	if not test_save_path.is_empty() and FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.clear_test_save_path()

func _state_at_total(total: int, golden: int = 19) -> Dictionary:
	var state := Treasure21Script.new_game(20, golden)
	state["total"] = total
	state["current_total"] = total
	return state

func _test_model_rules() -> void:
	var expected := {17: 8, 18: 11, 19: 16, 20: 20, 21: 34}
	for total: int in expected:
		_expect(Treasure21Script.payout_for_total(20, total) == int(expected[total]), "BET20 normal payout total %d" % total)
	_expect(Treasure21Script.golden_payout_for(20, 18) == 25, "Golden18 pays 25")
	_expect(Treasure21Script.golden_payout_for(20, 19) == 28, "Golden19 pays 28")
	_expect(Treasure21Script.golden_payout_for(20, 20) == 32, "Golden20 pays 32")
	_expect(not Treasure21Script.can_cash_out_total(16), "cash out is gated below 17")
	_expect(Treasure21Script.can_cash_out_total(17) and Treasure21Script.can_cash_out_total(21), "cash out is available from 17 through 21")

	var normal := _state_at_total(16, 20)
	normal = Treasure21Script.apply_roll(normal, 1)
	_expect(int(normal.get("total", 0)) == 17 and bool(normal.get("active", false)), "roll accumulates TOTAL and remains active")
	var cash := Treasure21Script.cash_out(normal)
	_expect(str(cash.get("result", "")) == "cashout" and int(cash.get("payout", 0)) == 8 and bool(cash.get("finished", false)), "TOTAL17 cash out returns floor payout")
	_expect(Treasure21Script.cash_out(cash) == cash, "cash out is idempotent")

	var bust := _state_at_total(19, 20)
	bust = Treasure21Script.apply_roll(bust, 5)
	_expect(str(bust.get("result", "")) == "bust" and int(bust.get("payout", -1)) == 0 and not bool(bust.get("active", true)), "TOTAL over21 busts without payout")
	var treasure := _state_at_total(20, 18)
	treasure = Treasure21Script.apply_roll(treasure, 1)
	_expect(str(treasure.get("result", "")) == "treasure" and int(treasure.get("payout", 0)) == 34, "TOTAL21 auto settles at the Phase A x1.7 payout")
	var golden := _state_at_total(17, 18)
	golden = Treasure21Script.apply_roll(golden, 1)
	_expect(str(golden.get("result", "")) == "golden" and int(golden.get("payout", 0)) == 25, "exact GOLDEN auto settles with bonus priority")
	var golden_twenty := _state_at_total(19, 20)
	golden_twenty = Treasure21Script.apply_roll(golden_twenty, 1)
	_expect(str(golden_twenty.get("result", "")) == "golden" and int(golden_twenty.get("payout", 0)) == 32, "GOLDEN20 wins before normal total20 payout")

	var preview := Treasure21Script.danger_preview(18, 20)
	_expect(preview.size() == 6, "danger preview always exposes all six faces")
	_expect(str(preview[0].get("kind", "")) == "cashout" and str(preview[1].get("kind", "")) == "golden" and str(preview[2].get("kind", "")) == "treasure" and str(preview[3].get("kind", "")) == "bust", "danger preview distinguishes cashout golden treasure and bust")
	_expect(Treasure21Script.face_outcome(18, 1, 19).get("next_total", 0) == 19, "face outcome is deterministic")
	var first := Treasure21Script.new_game(20, 19)
	_expect(int(first.get("golden_number", 0)) == 19, "first-game golden default is 19")

func _test_scene_flow() -> void:
	var scene := TREASURE_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene is Treasure21Screen, "TREASURE 21 scene instantiates its screen")
	_expect(scene.setup_view.visible and not scene.active_view.visible and not scene.result_view.visible, "screen opens on setup")
	_expect(scene.bet_buttons.size() == 4, "screen exposes four authored BET amounts")
	for amount: int in scene.bet_buttons:
		_expect((scene.bet_buttons[amount] as Button).custom_minimum_size.y >= 96.0, "BET %d meets touch target" % amount)
	_expect(scene.roll_button != null and scene.cashout_button != null and scene.danger_cells.size() == 6, "active console has roll cashout and six danger cells")

	# First ever game keeps the authored GOLDEN 19 and charges exactly once.
	scene.selected_bet = 20
	scene.queued_roll_value = 1
	scene.call("_start_game")
	var active := CasinoBankScript.active_game("treasure_21")
	var pending: Array = active.get("pending_rolls", []) as Array
	_expect(not pending.is_empty() and int((pending[0] as Dictionary).get("value", 0)) == 1, "initial roll is persisted before animation")
	_expect(CasinoBankScript.balance() == 980, "GAME START charges wager once")
	await create_timer(0.58).timeout
	_expect(int(scene.game.get("total", 0)) == 1 and int(scene.game.get("golden_number", 0)) == 19 and scene.active_view.visible, "first game resolves initial face and fixes GOLDEN19")
	_expect(scene.back_button.disabled, "EXIT remains locked while the wager is active")
	scene.call("_on_back_pressed")
	_expect(scene.active_view.visible, "back request cannot leave an active wager")

	# Move the deterministic fixture to the danger threshold and cash out.
	scene.game["total"] = 17
	scene.game["current_total"] = 17
	scene.call("_refresh_all")
	_expect(not scene.cashout_button.disabled and scene.danger_panel.visible and scene.danger_preview.size() == 6, "DANGER ZONE and CASH OUT appear at TOTAL17")
	_expect("8 CHIP" in scene.cashout_button.text, "cashout shows authored floor payout")
	scene.call("_on_cashout_pressed")
	await process_frame
	_expect(scene.result_view.visible and str(scene.game.get("result", "")) == "cashout" and int(scene.game.get("payout", 0)) == 8, "cash out opens result with payout")
	_expect(CasinoBankScript.balance() == 988 and not CasinoBankScript.has_active_game("treasure_21"), "settlement credits once and clears active game")
	var balance_after_cash := CasinoBankScript.balance()
	scene.call("_on_cashout_pressed")
	_expect(CasinoBankScript.balance() == balance_after_cash, "result replay cannot settle twice")

	# AGAIN keeps the same bet and starts directly from the result card.
	scene.queued_golden_number = 20
	scene.queued_roll_value = 2
	scene.again_button.pressed.emit()
	await process_frame
	_expect(scene.active_view.visible and int(scene.game.get("bet", 0)) == 20 and CasinoBankScript.balance() == 968, "AGAIN starts the remembered BET without returning to hub")
	scene.queue_free()
	await process_frame

	# A queued face survives removing the first screen mid-animation.
	var first := TREASURE_SCENE.instantiate()
	root.add_child(first)
	await process_frame
	first.queued_golden_number = 18
	first.queued_roll_value = 2
	first.call("_start_game")
	await create_timer(0.58).timeout
	first.queued_roll_value = 6
	first.call("_on_roll_pressed")
	var before_resume := CasinoBankScript.active_game("treasure_21")
	var stored: Array = before_resume.get("pending_rolls", []) as Array
	_expect(not stored.is_empty() and int((stored[0] as Dictionary).get("value", 0)) == 6, "next roll face is persisted before ROLL animation")
	first.queue_free()
	await process_frame
	var resumed := TREASURE_SCENE.instantiate()
	root.add_child(resumed)
	await process_frame
	await create_timer(0.58).timeout
	_expect(int(resumed.game.get("total", 0)) == 8 and int(resumed.game.get("last_roll", 0)) == 6 and CasinoBankScript.has_active_game("treasure_21"), "new screen resumes the exact pending face")
	resumed.game["total"] = 17
	resumed.game["current_total"] = 17
	resumed.call("_on_cashout_pressed")
	await process_frame
	_expect(not CasinoBankScript.has_active_game("treasure_21"), "resumed game settles cleanly")
	resumed.queue_free()
	await process_frame
