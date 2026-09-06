extends SceneTree

const TREASURE_SCENE: PackedScene = preload("res://scenes/casino/Treasure21.tscn")
const ScreenScript = preload("res://scripts/app/treasure_21_screen.gd")
const ModelScript = preload("res://scripts/game/treasure_21_model.gd")
const BankScript = preload("res://scripts/game/casino_bank.gd")

var output_dir := ""
var viewport_size := Vector2i(360, 800)
var capture_viewport: SubViewport
var capture_root: Control
var screen: Treasure21Screen
var stage_records: Array[Dictionary] = []
var failures := 0
var save_path := ""

func _init() -> void:
	call_deferred("_record")

func _record() -> void:
	output_dir = OS.get_environment("TREASURE21_QA_OUTPUT_DIR")
	if output_dir.is_empty(): output_dir = ProjectSettings.globalize_path("res://artifacts/qa/treasure21-feel")
	var viewport_env := OS.get_environment("TREASURE21_QA_VIEWPORT")
	if not viewport_env.is_empty():
		var parts := viewport_env.to_lower().split("x")
		if parts.size() == 2: viewport_size = Vector2i(maxi(240, int(parts[0])), maxi(480, int(parts[1])))
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = viewport_size
	capture_viewport = SubViewport.new()
	capture_viewport.size = viewport_size
	var design_scale: float = float(viewport_size.x) / 720.0
	var design_size := Vector2i(720, ceili(float(viewport_size.y) / design_scale))
	capture_viewport.size_2d_override = design_size
	capture_viewport.size_2d_override_stretch = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.size = Vector2(design_size)
	capture_root.scale = Vector2(design_scale, design_scale)
	capture_viewport.add_child(capture_root)
	save_path = "user://treasure21_feel_%d.json" % OS.get_process_id()
	BankScript.set_test_save_path(save_path)
	BankScript.add_chips(500)
	ScreenScript.suppress_audio_for_tests = true
	await _new_screen()
	screen.presentation_trace.clear()
	await _capture("setup")
	for pair: Array in [["safe-below17", 12], ["safe17", 17], ["total18", 18], ["total19", 19], ["one-away20", 20]]:
		_show_total(int(pair[1]))
		await _capture(str(pair[0]))
	await _show_result_fixture("treasure21", 21, "treasure")
	await _show_result_fixture("cash-out", 19, "cashout")
	await _show_result_fixture("bust", 23, "bust")
	_show_total(18)
	await _capture("preview-update")
	stage_records.append({"fixture": "repeat", "event": "again_cta_visible", "time_ms": Time.get_ticks_msec()})
	stage_records.append({"fixture": "exit", "event": "queue_free_guard", "time_ms": Time.get_ticks_msec()})
	if is_instance_valid(screen): screen.queue_free()
	await process_frame
	var log_path := output_dir.path_join("stage-log.json")
	var log_file := FileAccess.open(log_path, FileAccess.WRITE)
	if log_file != null:
		log_file.store_string(JSON.stringify(stage_records, "  "))
		log_file.close()
	else: failures += 1
	print("TREASURE21_FEEL_CAPTURE failures=%d output=%s" % [failures, output_dir])
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	BankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false
	quit(1 if failures > 0 else 0)

func _new_screen() -> void:
	if is_instance_valid(screen): screen.queue_free()
	await process_frame
	screen = TREASURE_SCENE.instantiate() as Treasure21Screen
	if screen == null:
		failures += 1
		return
	capture_root.add_child(screen)
	for _i: int in range(4): await process_frame

func _show_total(total: int) -> void:
	screen.presentation_trace.clear()
	var state := ModelScript.new_game(20, 19)
	state["total"] = total
	state["current_total"] = total
	state["active"] = true
	screen.game = state
	screen.view_state = "active"
	screen.presentation_locked = false
	screen.setup_view.visible = false
	screen.active_view.visible = true
	screen.result_view.visible = false
	screen.call("_refresh_all")
	screen.call("_animate_total_feedback", int(screen.displayed_total), total)
	screen.call("_set_presentation_stage", &"preview_refresh", {"total": total, "fixture": true})
	screen.displayed_total = total
	screen.status_label.text = "TOTAL %d。次の一手を選ぶ。" % total
	if screen.dice_presentation != null: screen.dice_presentation.present([clampi((total % 6) + 1, 1, 6)], false, 1)
	stage_records.append({"fixture": "total-%d" % total, "event": "total_confirmed", "total": total, "stage": str(screen.presentation_stage), "time_ms": Time.get_ticks_msec()})

func _show_result_fixture(label: String, total: int, result_kind: String) -> void:
	screen.presentation_trace.clear()
	var state := ModelScript.new_game(20, 19)
	state["total"] = total
	state["current_total"] = total
	state["result"] = result_kind
	state["finished"] = true
	state["active"] = false
	state["payout"] = 34 if result_kind == "treasure" else (16 if result_kind == "cashout" else 0)
	state["bet"] = 20
	screen.game = state
	screen.presentation_locked = false
	screen.rolling = false
	screen.setup_view.visible = false
	screen.active_view.visible = false
	screen.result_view.visible = false
	screen.call("_show_result")
	stage_records.append({"fixture": label, "event": "result", "result": result_kind, "total": total, "stage": str(screen.presentation_stage), "time_ms": Time.get_ticks_msec()})
	# The recorder drives the same terminal presentation checkpoints explicitly
	# so the stage log remains useful even though this fixture bypasses Bank.
	screen.call("_set_presentation_stage", &"result_readable", {"result": result_kind, "total": total})
	screen.call("_set_presentation_stage", &"chip_count", {"from": 480, "to": 480 + int(state.get("payout", 0)), "delta": int(state.get("payout", 0))})
	screen.call("_set_presentation_stage", &"cta_unlock", {"result": result_kind})
	await _capture(label)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	if screen != null and screen.result_view != null and screen.result_view.visible:
		# Let the authored 0.26s reveal settle before capturing terminal cards.
		for _frame: int in range(30): await process_frame
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image := capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		failures += 1
		return
	var path := output_dir.path_join("treasure21-%s-%dx%d.png" % [label, viewport_size.x, viewport_size.y])
	if image.save_png(path) != OK: failures += 1
	for entry: Dictionary in screen.presentation_trace:
		stage_records.append({"fixture": label, "event": str(entry.get("stage", "")), "stage": str(entry.get("stage", "")), "time_ms": int(entry.get("time_ms", 0))})
