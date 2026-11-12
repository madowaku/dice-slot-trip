extends SceneTree

const SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const ScreenScript = preload("res://scripts/app/dice_race_screen.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const BankScript = preload("res://scripts/game/casino_bank.gd")

const DEFAULT_VIEWPORT := Vector2i(360, 800)
const TEST_CHIPS := 300
const BET := 20
const SAVE_RELATIVE_PATH := ".qa-dice-race-feel-recorder.json"

var output_dir: String = ""
var viewport_size: Vector2i = DEFAULT_VIEWPORT
var capture_viewport: SubViewport
var capture_root: Control
var screen: DiceRaceScreen
var records: Array[Dictionary] = []
var failures: int = 0
var save_path: String = ""
var require_capture: bool = false


func _init() -> void:
	call_deferred("_record")


func _record() -> void:
	output_dir = OS.get_environment("DICE_RACE_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/qa/dice-race-feel")
	var viewport_env := OS.get_environment("DICE_RACE_QA_VIEWPORT")
	if not viewport_env.is_empty():
		var parts: PackedStringArray = viewport_env.to_lower().split("x")
		if parts.size() == 2:
			viewport_size = Vector2i(maxi(240, int(parts[0])), maxi(480, int(parts[1])))
	require_capture = OS.get_environment("DICE_RACE_QA_REQUIRE_CAPTURE").to_lower() in ["1", "true", "yes"]
	DirAccess.make_dir_recursive_absolute(output_dir)

	var design_scale: float = float(viewport_size.x) / 720.0
	var design_size := Vector2i(720, ceili(float(viewport_size.y) / design_scale))
	capture_viewport = SubViewport.new()
	capture_viewport.name = "DiceRaceFeelCaptureViewport"
	capture_viewport.size = viewport_size
	capture_viewport.size_2d_override = design_size
	capture_viewport.size_2d_override_stretch = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.name = "DiceRaceFeelCaptureRoot"
	capture_root.size = Vector2(design_size)
	capture_root.scale = Vector2(design_scale, design_scale)
	capture_viewport.add_child(capture_root)

	save_path = ProjectSettings.globalize_path("res://%s-%d" % [SAVE_RELATIVE_PATH, OS.get_process_id()])
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	BankScript.set_test_save_path(save_path)
	ScreenScript.suppress_audio_for_tests = true
	_reset_bank()
	_record_model_fixtures()

	await _new_setup_screen()
	if screen != null:
		_snapshot("setup", "ready")
		_assert_layout("setup")
		await _capture("setup")
		await _run_real_normal_fixture()

	await _run_transition_fixture(
		"overtake-b",
		{"camel": 10, "rabbit": 4, "fox": 8},
		{"camel": 2, "rabbit": 5, "fox": 1, "duck": 3, "dinosaur": 4, "robot": 6})
	await _run_transition_fixture(
		"leader-c",
		{"rabbit": 8, "fox": 10},
		{"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5})
	await _run_transition_fixture(
		"drop-d",
		{"rabbit": 10, "fox": 9},
		{"camel": 2, "rabbit": 1, "fox": 6, "duck": 3, "dinosaur": 4, "robot": 5})
	await _run_transition_fixture(
		"photo-finish",
		{"rabbit": 20, "fox": 21},
		{"camel": 1, "rabbit": 5, "fox": 4, "duck": 2, "dinosaur": 3, "robot": 6},
		true)
	await _run_transition_fixture(
		"goal-win",
		{"rabbit": 20},
		{"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5},
		false,
		true)
	await _run_transition_fixture(
		"loss",
		{"rabbit": 20, "fox": 21},
		{"camel": 2, "rabbit": 3, "fox": 6, "duck": 1, "dinosaur": 4, "robot": 5},
		false,
		true)
	await _run_teardown_fixture()

	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame
	await process_frame
	if is_instance_valid(capture_viewport):
		capture_viewport.queue_free()
	await process_frame
	await process_frame
	var log_path := output_dir.path_join("stage-log.json")
	var log_file := FileAccess.open(log_path, FileAccess.WRITE)
	if log_file == null:
		_fail("could not write stage log")
	else:
		log_file.store_string(JSON.stringify(records, "  "))
		log_file.close()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	BankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false
	print("DICE_RACE_FEEL_CAPTURE failures=%d output=%s" % [failures, output_dir])
	quit(1 if failures > 0 else 0)


func _record_model_fixtures() -> void:
	var normal := _fixture({"rabbit": 2})
	var normal_next := RaceScript.apply_roll(normal, _assignments({
		"camel": 1, "rabbit": 2, "fox": 3, "duck": 4, "dinosaur": 5, "robot": 6}))
	_record_model("A_normal", normal, normal_next, "normal_roll")
	_expect(int(normal_next.get("roll_count", 0)) == 1, "A normal roll increments once")

	var overtake_before := _fixture({"camel": 10, "rabbit": 4, "fox": 8})
	var overtake_after := RaceScript.apply_roll(overtake_before, _assignments({
		"camel": 2, "rabbit": 5, "fox": 1, "duck": 3, "dinosaur": 4, "robot": 6}))
	_record_model("B_overtake_3_to_2", overtake_before, overtake_after, "overtake")
	_expect(RaceScript.rank_for_racer(overtake_before, "rabbit") == 3 and RaceScript.rank_for_racer(overtake_after, "rabbit") == 2, "B is 3rd to 2nd")

	var leader_before := _fixture({"rabbit": 8, "fox": 10})
	var leader_after := RaceScript.apply_roll(leader_before, _assignments({
		"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5}))
	_record_model("C_leader_2_to_1", leader_before, leader_after, "leader")
	_expect(RaceScript.rank_for_racer(leader_before, "rabbit") == 2 and RaceScript.rank_for_racer(leader_after, "rabbit") == 1, "C is 2nd to 1st")

	var drop_before := _fixture({"rabbit": 10, "fox": 9})
	var drop_after := RaceScript.apply_roll(drop_before, _assignments({
		"camel": 2, "rabbit": 1, "fox": 6, "duck": 3, "dinosaur": 4, "robot": 5}))
	_record_model("D_drop_1_to_2", drop_before, drop_after, "drop")
	_expect(RaceScript.rank_for_racer(drop_before, "rabbit") == 1 and RaceScript.rank_for_racer(drop_after, "rabbit") == 2, "D is 1st to 2nd")

	var goal_before := _fixture({"rabbit": 20})
	var goal_after := RaceScript.apply_roll(goal_before, _assignments({
		"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5}))
	_record_model("E_goal", goal_before, goal_after, "goal")
	_expect(bool(goal_after.get("finished", false)) and str(goal_after.get("winner", "")) == "rabbit", "E reaches a unique goal")

	var photo_before := _fixture({"rabbit": 20, "fox": 21})
	var photo_after := RaceScript.apply_roll(photo_before, _assignments({
		"camel": 1, "rabbit": 5, "fox": 4, "duck": 2, "dinosaur": 3, "robot": 6}))
	_record_model("F_photo_finish", photo_before, photo_after, "photo_finish")
	_expect(not bool(photo_after.get("finished", false)) and (photo_after.get("photo_finish_candidates", []) as Array).size() == 2, "F keeps the tie unresolved")
	var photo_resolved := RaceScript.apply_roll(photo_after, _assignments({
		"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5}))
	_expect(bool(photo_resolved.get("finished", false)) and str(photo_resolved.get("winner", "")) == "rabbit", "F follow-up roll resolves the tie")

	var loss_before := _fixture({"rabbit": 20, "fox": 21})
	var loss_after := RaceScript.apply_roll(loss_before, _assignments({
		"camel": 2, "rabbit": 3, "fox": 6, "duck": 1, "dinosaur": 4, "robot": 5}))
	_record_model("G_loss", loss_before, loss_after, "loss")
	_expect(bool(loss_after.get("finished", false)) and str(loss_after.get("winner", "")) == "fox", "G preserves the winning opponent")

	var cashout := _fixture({})
	var cashout_assignments := _assignments({
		"camel": 1, "rabbit": 2, "fox": 3, "duck": 4, "dinosaur": 5, "robot": 6})
	for _i: int in range(3):
		cashout = RaceScript.apply_roll(cashout, cashout_assignments)
	var ride_on := RaceScript.ride_on(cashout)
	var extra_roll := RaceScript.apply_roll(ride_on, cashout_assignments)
	records.append({
		"fixture": "H_extra_roll",
		"event": "ride_on_then_roll",
		"roll_count_before": int(cashout.get("roll_count", 0)),
		"roll_count_after": int(extra_roll.get("roll_count", 0)),
		"cashout_offered": bool(cashout.get("cashout_offered", false)),
		"time_ms": Time.get_ticks_msec(),
	})
	_expect(bool(cashout.get("cashout_offered", false)) and int(extra_roll.get("roll_count", 0)) == 4, "H permits the extra roll")
	records.append({"fixture": "I_teardown", "event": "screen_free_during_presentation", "time_ms": Time.get_ticks_msec()})


func _record_model(label: String, before: Dictionary, after: Dictionary, event: String) -> void:
	records.append({
		"fixture": label,
		"event": event,
		"rank_before": RaceScript.rank_for_racer(before, "rabbit"),
		"rank_after": RaceScript.final_rank_for_racer(after, "rabbit"),
		"positions_before": _positions(before),
		"positions_after": _positions(after),
		"winner": str(after.get("winner", "")),
		"photo_candidates": (after.get("photo_finish_candidates", []) as Array).duplicate(),
		"time_ms": Time.get_ticks_msec(),
	})


func _run_real_normal_fixture() -> void:
	if screen == null:
		return
	screen.selected_racer = "rabbit"
	screen.selected_bet = BET
	screen._start_race()
	_snapshot("A_normal_runtime", "start_lock")
	await process_frame
	await process_frame
	_expect(screen.race_view.visible and not screen.setup_view.visible, "A runtime enters race view")
	screen._on_roll_stop()
	await create_timer(0.08).timeout
	screen.queued_coast_steps = 1
	screen._on_roll_stop()
	_snapshot("A_normal_runtime", "roll_lock")
	_expect(screen.presentation_locked and screen.roll_button.disabled, "A roll locks the CTA")
	await _wait_until_unlocked(2.6)
	_expect(screen.last_stop_feedback_assignments.size() == RaceScript.RACERS.size(), "A records all stopped dice")
	_snapshot("A_normal_runtime", "movement_complete")
	_assert_layout("A_normal_runtime")
	await _capture("race-normal")


func _run_transition_fixture(label: String, positions: Dictionary, values: Dictionary, capture_photo: bool = false, expect_result: bool = false) -> void:
	var before := _fixture(positions)
	await _new_active_screen(before)
	if screen == null:
		return
	screen.selected_racer = "rabbit"
	screen.selected_bet = BET
	screen.race = before.duplicate(true)
	screen.wager_committed = true
	screen.result_recorded = false
	screen.settled = false
	screen.spinning = false
	screen.presentation_locked = true
	screen.pending_roll = {}
	screen.current_assignments = _assignments(values)
	screen._refresh_all()
	await process_frame
	var before_rank := RaceScript.rank_for_racer(before, "rabbit")
	screen._set_phase("roll")
	screen._resolve_persisted_roll(screen.current_assignments)
	_snapshot(label, "movement_lock")
	var photo_seen := false
	var photo_captured := false
	var elapsed := 0.0
	while is_instance_valid(screen) and elapsed < 3.6:
		if screen.photo_overlay != null and is_instance_valid(screen.photo_overlay):
			photo_seen = true
			if capture_photo:
				_snapshot(label, "photo_overlay")
				_assert_layout(label + " photo")
				await _capture("race-%s" % label)
				capture_photo = false
				photo_captured = true
		if expect_result and screen.result_panel != null and screen.result_panel.visible and screen.presentation_phase == "result_cta":
			break
		if not expect_result and not screen.presentation_locked:
			break
		await create_timer(0.02).timeout
		elapsed += 0.02
	if capture_photo:
		_fail("%s photo overlay did not appear" % label)
	if expect_result:
		_expect(screen.result_panel.visible and screen.result_rank_label.visible, "%s presents rank" % label)
		_expect(screen.result_outcome_label.visible and screen.result_bet_value.visible and screen.result_net_value.visible, "%s presents outcome and metrics" % label)
		_expect(not screen.again_button.disabled and not screen.change_bet_button.disabled and not screen.result_exit_button.disabled, "%s unlocks result CTAs" % label)
		_assert_layout(label + " result")
		await _capture("race-%s-result" % label)
		if label == "goal-win":
			screen.again_button.pressed.emit()
			await process_frame
			_expect(screen.setup_view.visible and not screen.result_view.visible, "result again CTA returns to setup")
	else:
		_expect(not screen.presentation_locked, "%s unlocks after movement" % label)
		var after_rank := RaceScript.rank_for_racer(screen.race, "rabbit")
		records.append({
			"fixture": label,
			"event": "movement_complete",
			"rank_before": before_rank,
			"rank_after": after_rank,
			"photo_seen": photo_seen,
			"stage_trace": screen.stage_trace.duplicate(),
			"time_ms": Time.get_ticks_msec(),
		})
		_assert_layout(label)
		if not capture_photo and not photo_captured:
			await _capture("race-%s" % label)


func _run_teardown_fixture() -> void:
	var before := _fixture({"rabbit": 2})
	await _new_active_screen(before)
	if screen == null:
		return
	screen.selected_racer = "rabbit"
	screen.selected_bet = BET
	screen.race = before.duplicate(true)
	screen.wager_committed = true
	screen.presentation_locked = true
	screen.current_assignments = _assignments({
		"camel": 1, "rabbit": 2, "fox": 3, "duck": 4, "dinosaur": 5, "robot": 6})
	screen._refresh_all()
	screen._set_phase("roll")
	screen._resolve_persisted_roll(screen.current_assignments)
	await create_timer(0.10).timeout
	var weak: WeakRef = weakref(screen)
	screen.queue_free()
	await process_frame
	await process_frame
	_expect(weak.get_ref() == null, "I queue_free is safe during presentation")
	records.append({"fixture": "I_teardown", "event": "queue_free_complete", "time_ms": Time.get_ticks_msec()})
	screen = null


func _new_setup_screen() -> void:
	_reset_bank()
	await _spawn_screen()


func _new_active_screen(state: Dictionary) -> void:
	_reset_bank()
	var started := BankScript.begin_game("dice_race", BET, state.duplicate(true))
	_expect(bool(started.get("ok", false)), "active fixture starts Bank transaction")
	await _spawn_screen()


func _spawn_screen() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
		await process_frame
		await process_frame
	screen = SCENE.instantiate() as DiceRaceScreen
	if screen == null:
		_fail("could not instantiate DiceRaceScreen")
		return
	capture_root.add_child(screen)
	for _i: int in range(4):
		await process_frame


func _reset_bank() -> void:
	var data := BankScript.default_data()
	data["chips"] = TEST_CHIPS
	BankScript.save_data(data)


func _wait_until_unlocked(timeout_seconds: float) -> void:
	var elapsed := 0.0
	while is_instance_valid(screen) and screen.presentation_locked and elapsed < timeout_seconds:
		await create_timer(0.02).timeout
		elapsed += 0.02
	_expect(not screen.presentation_locked, "presentation unlocks within %.1fs" % timeout_seconds)


func _snapshot(fixture: String, event: String) -> void:
	if screen == null:
		return
	var state := {
		"fixture": fixture,
		"event": event,
		"presentation_phase": str(screen.presentation_phase),
		"presentation_locked": screen.presentation_locked,
		"spinning": screen.spinning,
		"roll_count": int(screen.race.get("roll_count", 0)),
		"selected_rank": RaceScript.rank_for_racer(screen.race, screen.selected_racer) if not screen.race.is_empty() else 0,
		"winner": str(screen.race.get("winner", "")),
		"result_visible": screen.result_panel != null and screen.result_panel.visible,
		"result_cta_locked": screen.again_button != null and screen.again_button.disabled,
		"stage_trace": screen.stage_trace.duplicate(),
		"time_ms": Time.get_ticks_msec(),
	}
	records.append(state)


func _assert_layout(label: String) -> void:
	if screen == null or capture_root == null:
		return
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	for entry: Array in [
		[screen.start_button, "start CTA"],
		[screen.roll_button, "roll CTA"],
		[screen.casino_back_button, "back CTA"],
		[screen.race_view, "race view"],
		[screen.track_frame, "track frame"],
		[screen.dice_console, "dice console"],
		[screen.result_panel, "result panel"],
	]:
		var control := entry[0] as Control
		if control != null and control.is_visible_in_tree():
			var rect := control.get_global_rect()
			records.append({"fixture": label, "event": "layout", "control": str(entry[1]), "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "viewport": [viewport_size.x, viewport_size.y], "time_ms": Time.get_ticks_msec()})
			_expect(viewport_rect.encloses(rect), "%s %s stays inside viewport" % [label, entry[1]])
	if screen.result_view != null and screen.result_view.visible:
		var ctas: Array[Rect2] = []
		for button: Button in [screen.again_button, screen.change_bet_button, screen.result_exit_button]:
			if button != null and button.visible:
				ctas.append(button.get_global_rect())
		for i: int in range(ctas.size()):
			for j: int in range(i + 1, ctas.size()):
				_expect(not ctas[i].intersects(ctas[j], true), "%s result CTAs do not overlap" % label)


func _capture(label: String) -> void:
	await process_frame
	if DisplayServer.get_name().to_lower().contains("headless"):
		records.append({"fixture": label, "event": "capture_unavailable", "reason": "headless_display_server", "time_ms": Time.get_ticks_msec()})
		if require_capture:
			_fail("headless display server cannot capture %s" % label)
		else:
			print("CAPTURE_SKIPPED %s (headless display server)" % label)
		return
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var texture := capture_viewport.get_texture()
	if texture == null:
		records.append({"fixture": label, "event": "capture_unavailable", "reason": "headless_rendering_driver", "time_ms": Time.get_ticks_msec()})
		if require_capture:
			_fail("capture texture unavailable for %s" % label)
		else:
			print("CAPTURE_SKIPPED %s (headless rendering driver)" % label)
		return
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		records.append({"fixture": label, "event": "capture_unavailable", "reason": "empty_headless_texture", "time_ms": Time.get_ticks_msec()})
		if require_capture:
			_fail("empty capture image for %s" % label)
		return
	var path := output_dir.path_join("dice-race-%s-%dx%d.png" % [label, viewport_size.x, viewport_size.y])
	if image.save_png(path) != OK:
		_fail("save failed for %s" % path)
	else:
		print("CAPTURE %s" % path)


func _fixture(positions: Dictionary, bet_racer: String = "rabbit") -> Dictionary:
	var state := RaceScript.new_race(bet_racer, BET)
	var racers: Dictionary = state.get("racers", {}) as Dictionary
	for racer_id: String in RaceScript.RACERS:
		var racer: Dictionary = racers.get(racer_id, {}) as Dictionary
		racer["position"] = int(positions.get(racer_id, 0))
		racers[racer_id] = racer
	state["racers"] = racers
	return state


func _assignments(values: Dictionary) -> Dictionary:
	var result := {}
	for racer_id: String in RaceScript.RACERS:
		result[racer_id] = int(values.get(racer_id, 1))
	return result


func _positions(state: Dictionary) -> Dictionary:
	var result := {}
	var racers: Dictionary = state.get("racers", {}) as Dictionary
	for racer_id: String in RaceScript.RACERS:
		result[racer_id] = int((racers.get(racer_id, {}) as Dictionary).get("position", 0))
	return result


func _expect(condition: bool, label: String) -> void:
	if condition:
		return
	_fail(label)


func _fail(message: String) -> void:
	failures += 1
	push_error("DICE_RACE_FEEL_FAIL: %s" % message)
