extends SceneTree

const ROULETTE_SCENE: PackedScene = preload("res://scenes/casino/DiceRoulette.tscn")
const BankScript = preload("res://scripts/game/casino_bank.gd")
const ScreenScript = preload("res://scripts/app/dice_roulette_screen.gd")
const PHONE_SIZE := Vector2i(360, 800)
const DESIGN_360 := Vector2i(720, 1600)
const DESIGN_720 := Vector2i(720, 1280)

var capture_viewport: SubViewport
var capture_root: Control
var screen: DiceRouletteScreen
var output_dir: String = ""
var output_size: Vector2i = PHONE_SIZE
var save_path: String = ""
var failures: int = 0
var stage_records: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_record")

func _record() -> void:
	output_dir = OS.get_environment("DICE_ROULETTE_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/playtest/dice-roulette-feel")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var design_size: Vector2i = DESIGN_360
	if OS.get_environment("DICE_ROULETTE_QA_VIEWPORT") == "720x1280":
		design_size = DESIGN_720
		output_size = DESIGN_720
	save_path = "user://dice_roulette_feel_recorder_%d.json" % OS.get_process_id()
	BankScript.set_test_save_path(save_path)
	ScreenScript.suppress_audio_for_tests = true
	capture_viewport = SubViewport.new()
	capture_viewport.size = design_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.size = Vector2(design_size)
	capture_viewport.add_child(capture_root)
	await _run_fixture("normal-win", {"HIGH": 10}, 1, 14, 3, 1)
	await _run_fixture("special-where-loss", {"HIGH": 10}, 11, 14, 2, 1)
	await _run_fixture("high-boost-win", {"HIGH": 10}, 1, 14, 6, 2)
	await _run_fixture("normal-loss", {"HIGH": 10}, 14, 6, 3, 4)
	var log_path: String = output_dir.path_join("stage-log.json")
	var log_file: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	if log_file != null:
		log_file.store_string(JSON.stringify(stage_records, "  "))
		log_file.close()
		print("STAGE_LOG %s records=%d" % [log_path, stage_records.size()])
	else:
		_fail("could not write stage log")
	print("DICE_ROULETTE_FEEL_CAPTURE failures=%d output=%s" % [failures, output_dir])
	await _cleanup()
	quit(1 if failures > 0 else 0)

func _run_fixture(label: String, bets: Dictionary, red_slot: int, blue_slot: int, red_face: int, blue_face: int) -> void:
	await _clear_screen()
	var data: Dictionary = BankScript.default_data()
	data["chips"] = 500
	BankScript.save_data(data)
	var started: Dictionary = BankScript.begin_game("dice_roulette", 10, {"phase": "SPINNING", "main_bets": bets.duplicate(true), "side_bet": {}, "pending_rolls": [{"slot": red_slot, "face": red_face}, {"slot": blue_slot, "face": blue_face}]})
	if not bool(started.get("ok", false)):
		_fail("could not start %s" % label)
		return
	screen = ROULETTE_SCENE.instantiate() as DiceRouletteScreen
	if screen == null:
		_fail("could not instantiate %s" % label)
		return
	capture_root.add_child(screen)
	await _wait_for_round_end(4.0, label)
	await _capture(label)

func _wait_for_round_end(timeout_seconds: float, label: String) -> void:
	var elapsed: float = 0.0
	var started_ms: int = Time.get_ticks_msec()
	var observed_events: Dictionary = {}
	var observed_motion_phases: Dictionary = {}
	var spin_started: bool = false
	while is_instance_valid(screen) and int(screen.phase) != 7 and elapsed < timeout_seconds:
		var events: Array[String] = screen.presentation_events.duplicate()
		var motion_phase: String = ""
		if is_instance_valid(screen.wheel):
			motion_phase = str(screen.wheel.get("motion_phase"))
		var phase_name: String = str(screen.phase)
		if not spin_started and phase_name != "0":
			spin_started = true
			stage_records.append({"fixture": label, "elapsed_ms": Time.get_ticks_msec() - started_ms, "phase": phase_name, "motion_phase": motion_phase, "event": "spin_start"})
		if not motion_phase.is_empty() and not observed_motion_phases.has(motion_phase):
			observed_motion_phases[motion_phase] = true
			stage_records.append({"fixture": label, "elapsed_ms": Time.get_ticks_msec() - started_ms, "phase": phase_name, "motion_phase": motion_phase, "event": ""})
		for event_index in range(events.size()):
			if observed_events.has(event_index):
				continue
			observed_events[event_index] = true
			stage_records.append({"fixture": label, "elapsed_ms": Time.get_ticks_msec() - started_ms, "phase": phase_name, "motion_phase": motion_phase, "event": events[event_index]})
		await create_timer(0.02).timeout
		elapsed += 0.02
	if not is_instance_valid(screen) or int(screen.phase) != 7:
		_fail("fixture did not reach ROUND_END")
	else:
		stage_records.append({"fixture": label, "elapsed_ms": Time.get_ticks_msec() - started_ms, "phase": str(screen.phase), "motion_phase": "", "event": "final_cta"})

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image: Image = capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("empty image for %s" % label)
		return
	image.resize(output_size.x, output_size.y, Image.INTERPOLATE_LANCZOS)
	var path: String = output_dir.path_join("%s-%dx%d.png" % [label, output_size.x, output_size.y])
	if image.save_png(path) != OK:
		_fail("save failed for %s" % path)
	else:
		print("CAPTURE %s" % path)

func _clear_screen() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	await process_frame
	await process_frame

func _cleanup() -> void:
	await _clear_screen()
	if is_instance_valid(capture_viewport):
		capture_viewport.queue_free()
	await process_frame
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	BankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false

func _fail(message: String) -> void:
	failures += 1
	push_error("DICE_ROULETTE_FEEL_CAPTURE: %s" % message)
