extends SceneTree

const SCENE: PackedScene = preload("res://scenes/casino/DicePoker.tscn")
const ScreenScript = preload("res://scripts/app/dice_poker_screen.gd")
const BankScript = preload("res://scripts/game/casino_bank.gd")
const ModelScript = preload("res://scripts/game/dice_poker_model.gd")

var output_dir: String = ""
var viewport_size: Vector2i = Vector2i(360, 800)
var capture_viewport: SubViewport
var capture_root: Control
var screen: DicePokerScreen
var records: Array[Dictionary] = []
var failures: int = 0
var save_path: String = ""

func _init() -> void:
	call_deferred("_record")

func _record() -> void:
	output_dir = OS.get_environment("DICEPOKER_QA_OUTPUT_DIR")
	if output_dir.is_empty(): output_dir = ProjectSettings.globalize_path("res://artifacts/qa/dice-poker-feel")
	var vp: String = OS.get_environment("DICEPOKER_QA_VIEWPORT")
	if not vp.is_empty():
		var p: PackedStringArray = vp.to_lower().split("x")
		if p.size() == 2: viewport_size = Vector2i(maxi(240, int(p[0])), maxi(480, int(p[1])))
	DirAccess.make_dir_recursive_absolute(output_dir)
	capture_viewport = SubViewport.new()
	capture_viewport.size = viewport_size
	var design_scale: float = float(viewport_size.x) / 720.0
	var design_size: Vector2i = Vector2i(720, ceili(float(viewport_size.y) / design_scale))
	capture_viewport.size_2d_override = design_size
	capture_viewport.size_2d_override_stretch = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.size = Vector2(design_size)
	capture_root.scale = Vector2(design_scale, design_scale)
	capture_viewport.add_child(capture_root)
	save_path = "user://dice_poker_feel_%d.json" % OS.get_process_id()
	BankScript.set_test_save_path(save_path)
	BankScript.add_chips(500)
	ScreenScript.suppress_audio_for_tests = true
	_record_model_fixtures()
	await _new_screen()
	await _capture("setup")
	if screen != null:
		screen.selected_bet = 20
		screen.queued_roll_batch = [[3, 3, 2, 5, 6], [3, 5, 5]]
		screen.deal_button.pressed.emit()
		_assert(screen.presentation_locked and screen.rolling, "initial presentation locks input")
		records.append(_state("initial_lock"))
		await create_timer(1.35).timeout
		_assert(not screen.presentation_locked and not screen.rolling, "initial presentation unlocks input")
		_assert((screen.game.get("dice", []) as Array) == [3, 3, 2, 5, 6], "initial fixture lands exact faces")
		_assert_layout("after-roll")
		await _capture("after-roll")
		screen.keep_buttons[0].pressed.emit(); await process_frame
		screen.keep_buttons[0].pressed.emit(); await process_frame
		screen.keep_buttons[0].pressed.emit(); await process_frame
		screen.keep_buttons[1].pressed.emit(); await process_frame
		_assert(_kept_mask(screen) == [true, true, false, false, false], "HOLD then UNHOLD then re-HOLD leaves two held dice")
		records.append(_state("hold_unhold_rehold"))
		screen.reroll_button.pressed.emit(); records.append(_state("reroll_lock"))
		_assert(screen.presentation_locked and screen.dice_presentation.state_name(0) == "LOCKED" and screen.dice_presentation.state_name(1) == "LOCKED", "reroll locks held dice and input")
		await create_timer(1.35).timeout
		_assert(not screen.presentation_locked and (screen.game.get("dice", []) as Array) == [3, 3, 3, 5, 5], "reroll preserves held dice and improves the hand")
		_assert_layout("reroll")
		await _capture("reroll")
		for i: int in range(2, 5): screen.keep_buttons[i].pressed.emit()
		await process_frame
		if screen.lock_button != null: screen.lock_button.pressed.emit()
		records.append(_state("final_result"))
		_assert(screen.presentation_locked and screen.result_view.visible and screen.exit_button.disabled, "result presentation locks all CTAs")
		await create_timer(1.7).timeout
		_assert(not screen.presentation_locked and screen.result_outcome_label.text == "WIN" and screen.result_chip_delta_label.visible, "result reveals WIN and CHIP after metrics")
		await _capture("result")
		if screen.exit_button != null: screen.exit_button.pressed.emit()
		await process_frame
		# teardown safety during active animation
		if is_instance_valid(screen): screen.queue_free()
	await process_frame
	await _record_final_one_die_fixture()
	await process_frame
	await _record_no_hand_fixture()
	await process_frame
	await _probe_result_chip_teardown()
	await process_frame
	await _probe_intermediate_hand_teardown()
	await process_frame
	var log_path: String = output_dir.path_join("stage-log.json")
	var f: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	if f == null: failures += 1
	else:
		f.store_string(JSON.stringify(records, "  ")); f.close()
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	BankScript.clear_test_save_path(); ScreenScript.suppress_audio_for_tests = false
	print("DICEPOKER_FEEL_CAPTURE failures=%d output=%s" % [failures, output_dir])
	quit(1 if failures > 0 else 0)

func _record_model_fixtures() -> void:
	var state_a: Dictionary = ModelScript.apply_initial(ModelScript.new_game(20), [3, 3, 2, 5, 6])
	state_a = ModelScript.set_keep(state_a, 0, true)
	state_a = ModelScript.set_keep(state_a, 1, true)
	var resolved_a: Dictionary = ModelScript.apply_reroll(state_a, [3, 5, 5], [2, 3, 4])
	records.append({"fixture": "A_hold_two_threes", "kept": state_a["kept"], "reroll_indices": ModelScript.reroll_indices(state_a), "dice": resolved_a["dice"], "rank": resolved_a["rank"]})
	var state_b: Dictionary = ModelScript.apply_initial(ModelScript.new_game(20), [3, 3, 2, 5, 6])
	state_b = ModelScript.toggle_keep(state_b, 0)
	state_b = ModelScript.toggle_keep(state_b, 0)
	state_b = ModelScript.toggle_keep(state_b, 0)
	records.append({"fixture": "B_unhold_rehold", "kept": state_b["kept"], "last_action": state_b["last_action"]})
	records.append({"fixture": "C_pair_to_three", "dice": [3, 3, 3, 5, 6], "rank": ModelScript.evaluate([3, 3, 3, 5, 6])["rank"]})
	var state_d: Dictionary = ModelScript.apply_initial(ModelScript.new_game(20), [4, 4, 4, 4, 2])
	state_d = ModelScript.set_keep(state_d, 0, true)
	state_d = ModelScript.set_keep(state_d, 1, true)
	state_d = ModelScript.set_keep(state_d, 2, true)
	state_d = ModelScript.set_keep(state_d, 3, true)
	records.append({"fixture": "D_final_reroll", "kept": state_d["kept"], "reroll_indices": ModelScript.reroll_indices(state_d)})
	records.append({"fixture": "E_full_house_high", "dice": [3, 3, 3, 5, 5], "tier": 4, "rank": ModelScript.RANK_FULL_HOUSE})
	records.append({"fixture": "F_no_hand", "dice": [1, 2, 3, 4, 6], "tier": 0, "rank": ModelScript.RANK_NO_HAND})
	records.append({"fixture": "G_four_held_one_reroll", "kept": [true, true, true, true, false], "reroll_indices": [4]})

func _record_final_one_die_fixture() -> void:
	await _new_screen()
	if screen == null:
		return
	screen.selected_bet = 20
	screen.queued_roll_batch = [[4, 4, 4, 4, 2], [6], [5]]
	screen.deal_button.pressed.emit()
	await create_timer(1.35).timeout
	for i: int in range(4): screen.keep_buttons[i].pressed.emit()
	await process_frame
	screen.reroll_button.pressed.emit()
	records.append(_state("one_die_reroll_lock"))
	_assert(screen.presentation_locked and screen.dice_presentation.state_name(0) == "LOCKED" and screen.dice_presentation.state_name(4) == "ROLLING", "four held dice stay still for one-die reroll")
	await create_timer(0.54).timeout
	await _capture("one-die-reroll")
	await create_timer(0.75).timeout
	await process_frame
	_assert(not screen.presentation_locked and not screen.rolling and screen.game.get("rerolls_used", 0) == 1, "one-die first reroll finishes before final reroll")
	screen.reroll_button.pressed.emit()
	records.append(_state("final_reroll_lock"))
	_assert(screen.presentation_locked and screen.presentation_phase == "reroll_suspense", "final reroll adds a short suspense phase")
	await create_timer(2.4).timeout
	await process_frame
	_assert(screen.result_view.visible and not screen.presentation_locked, "final one-die reroll resolves to result")
	_assert(_trace_contains_in_order(screen.stage_trace, ["dice", "hand", "multiplier", "outcome", "metrics", "chip_count", "cta"]), "final result stages stay in the authored order")
	await _capture("one-die-result")
	if is_instance_valid(screen): screen.queue_free()

func _record_no_hand_fixture() -> void:
	await _new_screen()
	if screen == null:
		return
	screen.selected_bet = 20
	screen.queued_roll_batch = [[1, 2, 3, 4, 6]]
	screen.deal_button.pressed.emit()
	await create_timer(1.35).timeout
	for i: int in range(5): screen.keep_buttons[i].pressed.emit()
	await process_frame
	screen.lock_button.pressed.emit()
	await create_timer(1.75).timeout
	_assert(screen.result_view.visible and screen.result_label.text == ModelScript.RANK_NO_HAND, "NO HAND fixture reaches the real restrained result presentation")
	_assert(screen.result_hand_tier == 0 and screen.result_label.modulate.r < 0.9, "NO HAND rendering stays visibly restrained at tier zero")
	await _capture("no-hand-result")
	if is_instance_valid(screen): screen.queue_free()

func _probe_result_chip_teardown() -> void:
	await _new_screen()
	if screen == null:
		return
	screen.selected_bet = 20
	screen.queued_roll_batch = [[2, 2, 3, 4, 6]]
	screen.deal_button.pressed.emit()
	await create_timer(1.35).timeout
	for i: int in range(5): screen.keep_buttons[i].pressed.emit()
	await process_frame
	screen.lock_button.pressed.emit()
	await create_timer(0.98).timeout
	_assert(screen.presentation_phase == "result_chip", "teardown probe reaches CHIP counting stage")
	var weak: WeakRef = weakref(screen)
	screen.queue_free()
	await process_frame
	await process_frame
	_assert(weak.get_ref() == null, "queue_free is safe during CHIP counting stage")
	screen = null

func _probe_intermediate_hand_teardown() -> void:
	await _new_screen()
	if screen == null:
		return
	screen.selected_bet = 20
	screen.queued_roll_batch = [[3, 3, 2, 5, 6], [3, 5, 5]]
	screen.deal_button.pressed.emit()
	await create_timer(1.35).timeout
	screen.keep_buttons[0].pressed.emit()
	screen.keep_buttons[1].pressed.emit()
	screen.reroll_button.pressed.emit()
	for _i: int in range(180):
		if screen.stage_trace.has("intermediate_hand_4"):
			break
		await process_frame
	_assert(screen.presentation_phase == "intermediate_hand" and screen.stage_trace.has("intermediate_hand_4"), "teardown probe reaches intermediate-hand pulse stage")
	var weak: WeakRef = weakref(screen)
	screen.queue_free()
	await process_frame
	await process_frame
	_assert(weak.get_ref() == null, "queue_free is safe during intermediate-hand pulse stage")
	screen = null

func _assert(condition: bool, label: String) -> void:
	if condition:
		return
	failures += 1
	push_error("DICEPOKER_FEEL_FAIL: %s" % label)

func _kept_mask(target: DicePokerScreen) -> Array:
	var result: Array = target.game.get("kept", []) as Array
	return result.duplicate()

func _assert_layout(label: String) -> void:
	if screen == null or not screen.active_view.visible:
		return
	var rects: Array[Rect2] = []
	for value: Variant in screen.active_die_faces.values():
		if value is Dictionary:
			var panel: PanelContainer = (value as Dictionary).get("panel", null) as PanelContainer
			if panel != null and panel.visible:
				rects.append(panel.get_global_rect())
	if rects.size() != 5:
		_assert(false, "%s keeps five die cards visible" % label)
		return
	for i: int in range(rects.size()):
		for j: int in range(i + 1, rects.size()):
			_assert(not rects[i].intersects(rects[j], true), "%s die cards do not overlap" % label)
	var bounds: Rect2 = rects[0]
	for rect: Rect2 in rects.slice(1):
		bounds = bounds.merge(rect)
	_assert(capture_root.get_global_rect().encloses(bounds), "%s die cards stay inside the capture viewport" % label)

func _trace_contains_in_order(trace: Array[String], expected: Array[String]) -> bool:
	var cursor: int = 0
	for item: String in trace:
		if cursor < expected.size() and item == expected[cursor]:
			cursor += 1
	return cursor == expected.size()

func _new_screen() -> void:
	screen = SCENE.instantiate() as DicePokerScreen
	if screen == null: failures += 1; return
	capture_root.add_child(screen)
	for _i: int in range(4): await process_frame

func _state(label: String) -> Dictionary:
	var trace: Array[String] = []
	var dice: Array = []
	var kept: Array = []
	var die_states: Array[String] = []
	var cta_locked: bool = false
	if screen != null:
		for item: String in screen.stage_trace: trace.append(item)
		dice = (screen.game.get("dice", []) as Array).duplicate()
		kept = (screen.game.get("kept", []) as Array).duplicate()
		if screen.dice_presentation != null and screen.dice_presentation.die_states.size() >= 5:
			for index: int in range(5): die_states.append(screen.dice_presentation.state_name(index))
		cta_locked = screen.presentation_locked or (screen.again_button != null and screen.again_button.disabled)
	return {"fixture": label, "presentation_phase": str(screen.presentation_phase), "rolling": screen.rolling, "presentation_locked": screen.presentation_locked, "cta_locked": cta_locked, "dice": dice, "kept": kept, "die_states": die_states, "result_tier": screen.result_hand_tier, "chip_text": screen.chip_label.text if screen.chip_label != null else "", "stage_trace": trace, "time_ms": Time.get_ticks_msec()}

func _capture(label: String) -> void:
	await process_frame
	if screen != null and screen.result_view != null and screen.result_view.visible:
		for _i: int in range(30): await process_frame
	RenderingServer.force_draw(false, 0.0); RenderingServer.force_sync()
	var image: Image = capture_viewport.get_texture().get_image()
	if image == null or image.is_empty(): failures += 1; return
	var path: String = output_dir.path_join("dice-poker-%s-%dx%d.png" % [label, viewport_size.x, viewport_size.y])
	if image.save_png(path) != OK: failures += 1
	records.append(_state("capture_%s" % label))
