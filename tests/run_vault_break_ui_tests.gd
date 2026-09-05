extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const ProgressScript = preload("res://scripts/game/vault_break/vault_break_progress.gd")
const ModelScript = preload("res://scripts/game/vault_break/vault_break_model.gd")
const ScreenScript = preload("res://scripts/app/vault_break_screen.gd")
const LockViewScript = preload("res://scripts/app/vault_break_lock_view.gd")
const VAULT_SCENE: PackedScene = preload("res://scenes/casino/VaultBreak.tscn")

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

func _assert_how_to(screen: Node) -> void:
	var panel := screen.find_child("CasinoHowTo3Steps", true, false) as PanelContainer
	_expect(panel != null, "VAULT BREAK exposes the shared CasinoHowTo3Steps panel")
	if panel == null:
		return
	var headings: Array[String] = ["① 最初に何をする？", "② プレイ中に何をする？", "③ どうなれば勝ち？"]
	var actions: Array[String] = ["ベットと金庫を選ぶ", "サイコロを振って置く", "6つのロックを埋める"]
	for index: int in range(3):
		var heading := panel.find_child("Step%dHeading" % (index + 1), true, false) as Label
		var detail := panel.find_child("Step%dDetail" % (index + 1), true, false) as Label
		_expect(heading != null and heading.text == headings[index], "VAULT BREAK keeps shared step heading %d" % (index + 1))
		_expect(detail != null and actions[index] in detail.text and detail.text.length() <= 48, "VAULT BREAK keeps concise step copy %d" % (index + 1))

func _run() -> void:
	test_save_path = "user://vault_break_ui_tests_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(test_save_path)
	ScreenScript.suppress_audio_for_tests = true
	await _test_scene_setup_and_pending_resume()
	await _test_auto_discard_and_final_roll_failure()
	await _test_success_settlement_and_progress()
	await _test_black_persistence_and_attempt()
	await _test_setup_back_signal()
	_cleanup_save()
	CasinoBankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false
	print("Vault Break UI tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _test_scene_setup_and_pending_resume() -> void:
	_reset_bank(100)
	var screen := await _spawn_screen()
	_expect(screen is VaultBreakScreen, "scene instantiates VaultBreakScreen")
	_expect(screen.result_vault_door != null and screen.result_vault_door.texture != null, "result view reuses the canonical vault door asset")
	_expect(screen.repository != null and bool(screen.repository.call("is_loaded")) and (screen.repository.get("templates_by_id") as Dictionary).size() == 30, "screen loads the canonical 30-template repository")
	_expect(screen.bet_buttons.size() == 3 and screen.tier_buttons.size() == 4, "setup exposes three BETs and four authored tier controls")
	_expect(not (screen.bet_buttons.get(10) as Button).disabled and not (screen.bet_buttons.get(20) as Button).disabled and not (screen.bet_buttons.get(50) as Button).disabled, "all BETs are available at 100 CHIP")
	_expect(not (screen.tier_buttons.get("bronze") as Button).disabled and (screen.tier_buttons.get("silver") as Button).disabled and (screen.tier_buttons.get("gold") as Button).disabled, "tier availability is derived from wins")
	_expect(not (screen.tier_buttons.get("black") as Button).visible, "BLACK stays hidden without an active template")
	_expect((screen.start_button as Button).custom_minimum_size.y >= 96.0 and (screen.back_button as Button).custom_minimum_size.y >= 96.0, "primary touch targets meet the 96-unit minimum")
	_assert_how_to(screen)

	screen.call("_select_bet", 20)
	screen.call("_select_tier", "bronze")
	screen.call("_start_game")
	_expect(screen.view_state == "ready" and str(screen.active_template.get("id", "")) == "B01", "first BRONZE start delegates to fixed template B01")
	_expect(CasinoBankScript.balance() == 80, "start charges BET20 once")
	screen.call("_start_game")
	_expect(CasinoBankScript.balance() == 80, "duplicate start cannot charge a second wager")
	_expect(screen.lock_views.size() == 3 and screen.lock_views.all(func(view: VaultBreakLockView) -> bool: return view.custom_minimum_size.y >= 96.0), "B01 builds three reusable interactive lock views")

	screen.queued_roll_value = 6
	screen.call("_on_roll_pressed")
	var pending_record := CasinoBankScript.active_game("vault_break")
	var pending_session: Dictionary = pending_record.get("session", {}) as Dictionary
	var pending_values: Array = pending_session.get("pending_rolls", []) as Array
	var pre_roll: Dictionary = pending_session.get("model_snapshot", {}) as Dictionary
	_expect(pending_values.size() == 1 and int((pending_values[0] as Dictionary).get("value", 0)) == 6, "face is persisted before roll animation")
	_expect(int(pre_roll.get("state", -1)) == ModelScript.State.READY and int(pre_roll.get("rolls_used", -1)) == 0 and int(pre_roll.get("current_face", -1)) == 0, "pending transaction stores the canonical pre-roll snapshot")
	screen.queue_free()
	await process_frame

	var resumed := await _spawn_screen()
	await _frames(6)
	_expect(resumed.view_state == "waiting_for_placement" and int(resumed.model.get("current_face")) == 6 and resumed.displayed_face == 6, "resume animates and resolves the exact saved face")
	_expect((resumed.lock_views[1] as VaultBreakLockView).is_valid_target() and (resumed.lock_views[2] as VaultBreakLockView).is_valid_target() and not (resumed.lock_views[0] as VaultBreakLockView).is_valid_target(), "only valid empty locks highlight for FACE 6")
	var before_wrong: Array = resumed.model.call("get_placed_faces") as Array
	resumed.call("_on_lock_pressed", 0)
	_expect((resumed.model.call("get_placed_faces") as Array) == before_wrong and resumed.view_state == "waiting_for_placement", "wrong-lock placement is rejected without consuming the die")
	resumed.call("_on_lock_pressed", 2)
	await _frames(4)
	_expect(int((resumed.model.call("get_placed_faces") as Array)[2]) == 6 and resumed.view_state == "ready", "valid placement persists and returns to READY")
	_expect((resumed.lock_views[2] as VaultBreakLockView).get_lock_state() == VaultBreakLockView.State.FILLED and (resumed.lock_views[2] as VaultBreakLockView).disabled, "placed die is visibly immutable")
	resumed.queued_roll_value = 6
	resumed.call("_on_roll_pressed")
	await _frames(5)
	resumed.call("_on_lock_pressed", 2)
	_expect(int(resumed.model.get("current_face")) == 6 and int((resumed.model.call("get_placed_faces") as Array)[2]) == 6, "filled lock rejects a second placement")
	resumed.call("_on_discard_pressed")
	await _frames(4)
	_expect(int(resumed.model.get("discard_count")) == 1 and not bool(resumed.model.get("last_discard_was_automatic")) and resumed.view_state == "ready", "explicit DISCARD resolves a fitting die manually")
	await _dispose(resumed)

func _test_auto_discard_and_final_roll_failure() -> void:
	_reset_bank(100)
	var screen := await _spawn_screen()
	screen.call("_select_bet", 20)
	screen.call("_start_game")
	await _roll_and_place(screen, 1, 0)
	await _roll_and_place(screen, 4, 1)
	await _roll_without_action(screen, 5)
	_expect(int(screen.model.get("discard_count")) == 1 and bool(screen.model.get("last_discard_was_automatic")) and screen.view_state == "ready", "NO FIT automatically discards without waiting for input")
	_expect(screen.discard_button.disabled, "auto-discard does not leave a discard-only decision state")
	await _dispose(screen)

	_reset_bank(100)
	var final_screen := await _spawn_screen()
	final_screen.call("_select_bet", 20)
	final_screen.call("_start_game")
	await _roll_and_place(final_screen, 1, 0)
	for ignored: int in 3:
		await _roll_to_wait(final_screen, 4)
		final_screen.call("_on_discard_pressed")
		await _frames(4)
	await _roll_to_wait(final_screen, 4)
	final_screen.call("_on_lock_pressed", 1)
	# The placement happens synchronously before the brief failure/result hold.
	_expect(int((final_screen.model.call("get_placed_faces") as Array)[1]) == 4, "final roll applies its chosen placement before failure evaluation")
	await _frames(7)
	_expect(final_screen.view_state == "result" and str(final_screen.result_data.get("result", "")) == "failure" and "チップなし" in final_screen.result_label.text and final_screen.result_payout_label.text == "受け取り 0 CHIP（BET込み）" and "収支 -20 CHIP · BET 20" in final_screen.result_detail_label.text, "incomplete final placement reaches an explicit failure Result with BET, return, and net")
	_expect(CasinoBankScript.balance() == 80, "failure settles with zero payout")
	await _dispose(final_screen)

func _test_success_settlement_and_progress() -> void:
	_reset_bank(100)
	var screen := await _spawn_screen()
	screen.call("_select_bet", 20)
	screen.call("_start_game")
	await _roll_and_place(screen, 1, 0)
	await _roll_and_place(screen, 4, 1)
	await _roll_to_wait(screen, 6)
	var returned := {"value": false}
	screen.back_requested.connect(func() -> void: returned["value"] = true)
	screen.call("_on_lock_pressed", 2)
	_expect(int(screen.model.get("reward")) == 34, "BET20 BRONZE reward floors to 34")
	await _frames(7)
	_expect(screen.view_state == "result" and screen.result_view.visible and not bool(returned["value"]), "Result is shown before any casino return")
	_expect(screen.result_payout_label.text == "受け取り 34 CHIP（BET込み）" and "収支 +14 CHIP" in screen.result_detail_label.text, "Vault success separates stake-inclusive return from net")
	_expect(screen.result_vault_door.visible and screen.result_vault_door_panel.visible and screen.result_vault_door.modulate.a >= 0.95, "Vault success keeps the door visual present and bright in Result")
	_expect(screen.again_button.text == "次の金庫を選ぶ", "Vault setup-return CTA explains choosing the next vault")
	_expect(CasinoBankScript.balance() == 114 and screen.settlement_attempt_count == 1, "success credits 34 once after the committed wager")
	var saved := CasinoBankScript.load_data()
	var meta: Dictionary = saved.get("vault_break", {}) as Dictionary
	var saved_progress: Dictionary = meta.get("progress", {}) as Dictionary
	var tiers: Dictionary = saved_progress.get("tiers", {}) as Dictionary
	var bronze: Dictionary = tiers.get("bronze", {}) as Dictionary
	_expect(int(bronze.get("plays", 0)) == 1 and int(bronze.get("wins", 0)) == 1 and bool(bronze.get("first_play_done", false)), "result progress is persisted before Result")
	_expect(bool(screen.progress.call("is_tier_unlocked", "silver")), "persisted BRONZE win derives the SILVER unlock")
	_expect(meta.get("pending_result", {}) is Dictionary and not (meta.get("pending_result", {}) as Dictionary).is_empty(), "crash-safe Result receipt is namespaced in casino save data")
	var settlement_order: Array = saved.get("casino_settlement_order", []) as Array
	_expect(settlement_order.size() == 1 and not CasinoBankScript.has_active_game("vault_break"), "terminal session settles once and leaves no active wager")
	screen.call("_on_back_pressed")
	_expect(bool(returned["value"]) and screen.view_state == "exiting", "Result return emits the hub-compatible back signal")
	await _dispose(screen)

func _test_black_persistence_and_attempt() -> void:
	var raw_progress: Dictionary = ProgressScript.default_progress()
	var tiers: Dictionary = raw_progress.get("tiers", {}) as Dictionary
	var gold: Dictionary = tiers.get("gold", {}) as Dictionary
	gold["plays"] = 1
	gold["wins"] = 1
	gold["first_play_done"] = true
	tiers["gold"] = gold
	raw_progress["tiers"] = tiers
	var spawn: Dictionary = raw_progress.get("black_spawn", {}) as Dictionary
	spawn["active_template_id"] = "K01"
	raw_progress["black_spawn"] = spawn
	_reset_bank(100, {"schema_version": 1, "progress": raw_progress, "last_bet": 20, "last_tier": "black"})
	var screen := await _spawn_screen()
	_expect(screen.selected_tier == "black" and (screen.tier_buttons.get("black") as Button).visible and not (screen.tier_buttons.get("black") as Button).disabled, "active BLACK template makes BLACK visible and playable")
	screen.call("_start_game")
	_expect(str(screen.active_template.get("id", "")) == "K01" and CasinoBankScript.balance() == 80, "BLACK start uses the persisted active template and charges once")
	var returned := {"value": false}
	screen.back_requested.connect(func() -> void: returned["value"] = true)
	screen.call("_on_back_pressed")
	_expect(bool(returned["value"]) and str(((CasinoBankScript.load_data().get("vault_break", {}) as Dictionary).get("progress", {}) as Dictionary).get("black_spawn", {}).get("active_template_id", "")) == "K01", "casino exit preserves an unresolved active BLACK vault")
	await _dispose(screen)

	var resumed := await _spawn_screen()
	_expect(resumed.view_state == "ready" and str(resumed.active_template.get("id", "")) == "K01", "BLACK attempt resumes from its canonical model snapshot")
	for roll_index: int in 5:
		await _roll_without_action(resumed, 6)
		if roll_index < 4:
			_expect(resumed.view_state == "ready", "BLACK no-fit roll %d remains resumable" % (roll_index + 1))
	await _frames(7)
	_expect(resumed.view_state == "result", "actual BLACK attempt resolves before lifecycle cleanup")
	var saved := CasinoBankScript.load_data()
	var meta: Dictionary = saved.get("vault_break", {}) as Dictionary
	var final_progress: Dictionary = meta.get("progress", {}) as Dictionary
	var final_spawn: Dictionary = final_progress.get("black_spawn", {}) as Dictionary
	var final_black: Dictionary = (final_progress.get("tiers", {}) as Dictionary).get("black", {}) as Dictionary
	_expect(str(final_spawn.get("active_template_id", "")).is_empty() and int(final_spawn.get("cooldown_remaining", 0)) == 2, "resolved BLACK attempt clears active id and starts cooldown two")
	_expect(int(final_black.get("plays", 0)) == 1 and bool(final_black.get("first_play_done", false)), "BLACK attempt records its first play even on failure")
	_expect(CasinoBankScript.balance() == 80 and resumed.settlement_attempt_count == 1, "BLACK failure settles its wager exactly once")
	await _dispose(resumed)

func _test_setup_back_signal() -> void:
	_reset_bank(34)
	var screen := await _spawn_screen()
	_expect(not (screen.bet_buttons.get(10) as Button).disabled and not (screen.bet_buttons.get(20) as Button).disabled and (screen.bet_buttons.get(50) as Button).disabled, "BET buttons reflect the live CHIP balance")
	var returned := {"value": false}
	screen.back_requested.connect(func() -> void: returned["value"] = true)
	screen.call("_on_back_pressed")
	_expect(bool(returned["value"]) and screen.view_state == "exiting", "setup Back emits the hub-compatible signal")
	await _dispose(screen)

func _roll_to_wait(screen: VaultBreakScreen, face: int) -> void:
	screen.queued_roll_value = face
	screen.call("_on_roll_pressed")
	await _frames(5)
	_expect(screen.view_state == "waiting_for_placement", "FACE %d reaches placement state when a target exists" % face)
	var valid_indices: Array = screen.model.call("get_valid_empty_lock_indices", face) as Array
	if valid_indices.size() > 1:
		_expect("%d個のLOCKが有効 · どこに使うか選択" % valid_indices.size() == screen.instruction_label.text, "multiple valid Vault locks retain one concise choice hint")

func _roll_and_place(screen: VaultBreakScreen, face: int, lock_index: int) -> void:
	await _roll_to_wait(screen, face)
	screen.call("_on_lock_pressed", lock_index)
	await _frames(4)

func _roll_without_action(screen: VaultBreakScreen, face: int) -> void:
	screen.queued_roll_value = face
	screen.call("_on_roll_pressed")
	await _frames(5)

func _spawn_screen() -> VaultBreakScreen:
	var screen := VAULT_SCENE.instantiate() as VaultBreakScreen
	screen.animation_duration_scale = 0.0
	root.add_child(screen)
	await process_frame
	return screen

func _dispose(screen: Node) -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame
	await process_frame

func _frames(count: int) -> void:
	for ignored: int in count:
		await process_frame

func _reset_bank(chips: int, vault_meta: Dictionary = {}) -> void:
	_cleanup_save()
	var data := CasinoBankScript.default_data()
	data["chips"] = chips
	if not vault_meta.is_empty():
		data["vault_break"] = vault_meta.duplicate(true)
	CasinoBankScript.save_data(data)

func _cleanup_save() -> void:
	if test_save_path.is_empty() or not FileAccess.file_exists(test_save_path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
