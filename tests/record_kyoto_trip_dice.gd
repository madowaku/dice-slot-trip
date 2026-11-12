extends SceneTree

## Screenshots of Kyoto with and without an equipped trip die.
##
##   LAS_VEGAS_QA_OUTPUT_DIR  output folder (default: artifacts/playtest/
##                            las-vegas-casino-renewal/phase4)
##   DICE_RACE_QA_VIEWPORT    e.g. 360x800 or 720x1280
##
## Run without --headless. CasinoBank and the journey saves go to isolated
## test paths; the player's saves are never read or written.

const JOURNEY_SCENE: PackedScene = preload("res://scenes/app/JourneyStageScreen.tscn")
const Bank = preload("res://scripts/game/casino_bank.gd")
const JourneySaves = preload("res://scripts/game/journey_save_manager.gd")

var failures := 0
var assertions := 0
var output_dir := ""
var viewport_size := Vector2i(360, 800)
var capture_viewport: SubViewport
var capture_root: Control
var bank_path := ""
var journey_dir := ""


func _init() -> void:
	call_deferred("_record")


func _expect(value: bool, label: String) -> void:
	assertions += 1
	if value:
		return
	failures += 1
	push_error("FAIL: %s" % label)


func _record() -> void:
	output_dir = OS.get_environment("LAS_VEGAS_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/playtest/las-vegas-casino-renewal/phase4")
	var viewport_env := OS.get_environment("DICE_RACE_QA_VIEWPORT")
	if not viewport_env.is_empty():
		var parts := viewport_env.to_lower().split("x")
		if parts.size() == 2:
			viewport_size = Vector2i(maxi(240, int(parts[0])), maxi(480, int(parts[1])))
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = viewport_size
	var design_scale := float(viewport_size.x) / 720.0
	var design_size := Vector2i(720, ceili(float(viewport_size.y) / design_scale))
	capture_viewport = SubViewport.new()
	capture_viewport.size = viewport_size
	capture_viewport.size_2d_override = design_size
	capture_viewport.size_2d_override_stretch = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.transparent_bg = false
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	capture_root.size = Vector2(design_size)
	capture_root.scale = Vector2(design_scale, design_scale)
	capture_viewport.add_child(capture_root)

	bank_path = "user://kyoto_trip_dice_recorder_%d.json" % OS.get_process_id()
	journey_dir = "user://kyoto_trip_dice_recorder_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(journey_dir))
	Bank.set_test_save_path(bank_path)
	JourneySaves._test_save_directory = journey_dir

	_reset(30, [], "")
	await _capture_kyoto("kyoto-no-trip-die", false)
	_reset(30, ["trip_die_gamble"], "trip_die_gamble")
	await _capture_kyoto("kyoto-trip-die", true)

	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	_reset(0, [], "")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(bank_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bank_path + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(journey_dir))
	Bank.clear_test_save_path()
	JourneySaves._test_save_directory = ""
	capture_viewport.queue_free()
	print("KYOTO_TRIP_DICE_CAPTURE size=%s assertions=%d failures=%d output=%s" % [viewport_size, assertions, failures, output_dir])
	quit(1 if failures > 0 else 0)


func _reset(chips: int, owned: Array, equipped: String) -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(bank_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bank_path + suffix))
	var data := Bank.default_data()
	data["chips"] = chips
	data[Bank.OWNED_TRIP_DICE_KEY] = owned
	data[Bank.EQUIPPED_TRIP_DIE_KEY] = equipped
	Bank.save_data(data)
	var dir := DirAccess.open(journey_dir)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)


func _capture_kyoto(prefix: String, with_trip_die: bool) -> void:
	var screen := JOURNEY_SCENE.instantiate() as JourneyStageScreen
	screen.configure_start_context(StageCatalog.STAGE_KYOTO)
	screen.show_stage_intro = false
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_root.add_child(screen)
	screen.size = capture_root.size
	await _settle_frames(10)
	screen.call("_close_overview_map")
	await _settle_frames(4)
	screen.call("_close_modal")
	await _settle_frames(10)
	await _capture("%s-ready" % prefix)
	if with_trip_die:
		_expect(screen.trip_die_toggle != null and screen.trip_die_toggle.visible, "trip die toggle is shown")
		_assert_inside(screen.trip_die_toggle, "trip die toggle")
		screen.trip_die_toggle.toggled.emit(true)
		await _settle_frames(6)
		await _capture("%s-armed" % prefix)
	else:
		_expect(screen.trip_die_toggle == null or not screen.trip_die_toggle.visible, "no toggle without a trip die")
	screen.call("_roll_map")
	await create_timer(0.30).timeout
	await _capture("%s-spinning" % prefix)
	screen.call("_roll_map")
	await create_timer(2.6).timeout
	screen.call("_close_modal")
	await _settle_frames(6)
	await _capture("%s-landed" % prefix)
	screen.queue_free()
	await _settle_frames(4)


func _assert_inside(control: Control, label: String) -> void:
	var rect := control.get_global_rect()
	var bounds := Rect2(Vector2.ZERO, capture_root.size).grow(1.0)
	var host := control.get_parent() as Control
	if host != null:
		# The map panel clips its children, so the panel is the real bound.
		bounds = host.get_global_rect().grow(1.0)
	_expect(bounds.encloses(rect), "%s stays inside the %dx%d screen" % [label, viewport_size.x, viewport_size.y])


func _capture(name: String) -> void:
	await _settle_frames(4)
	RenderingServer.force_draw(false, 0.0)
	if OS.get_cmdline_args().has("--headless"):
		print("CAPTURE_SKIPPED %s (run without --headless)" % name)
		return
	var image := capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_expect(false, "%s screenshot is readable" % name)
		return
	var path := output_dir.path_join("%s-%dx%d.png" % [name, viewport_size.x, viewport_size.y])
	_expect(image.save_png(path) == OK, "%s screenshot saved" % name)
	print("CAPTURE %s %s" % [name, path])


func _settle_frames(count: int) -> void:
	for _i in count:
		await process_frame
