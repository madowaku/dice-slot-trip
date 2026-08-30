extends SceneTree

const TREASURE_SCENE: PackedScene = preload("res://scenes/casino/Treasure21.tscn")
const TreasureScreen = preload("res://scripts/app/treasure_21_screen.gd")
const TreasureModel = preload("res://scripts/game/treasure_21_model.gd")
const Bank = preload("res://scripts/game/casino_bank.gd")

var output_dir: String = ""
var viewport_size: Vector2i = Vector2i(360, 800)
var capture_viewport: SubViewport = null
var capture_root: Control = null
var failures: int = 0
var assertions: int = 0
var save_path: String = ""

func _init() -> void:
	call_deferred("_record")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _record() -> void:
	output_dir = OS.get_environment("TREASURE21_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/qa/treasure21-product")
	var viewport_env: String = OS.get_environment("TREASURE21_QA_VIEWPORT")
	if not viewport_env.is_empty():
		var parts: PackedStringArray = viewport_env.to_lower().split("x")
		if parts.size() == 2:
			viewport_size = Vector2i(maxi(240, int(parts[0])), maxi(480, int(parts[1])))
	DirAccess.make_dir_recursive_absolute(output_dir)

	root.size = viewport_size
	capture_viewport = SubViewport.new()
	capture_viewport.size = viewport_size
	var design_scale: float = float(viewport_size.x) / 720.0
	var design_size: Vector2i = Vector2i(720, ceili(float(viewport_size.y) / design_scale))
	capture_viewport.size_2d_override = design_size
	capture_viewport.size_2d_override_stretch = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	capture_root.size = Vector2(design_size)
	capture_root.scale = Vector2(design_scale, design_scale)
	capture_viewport.add_child(capture_root)

	save_path = "user://treasure21_product_ui_%d.json" % OS.get_process_id()
	Bank.set_test_save_path(save_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	Bank.add_chips(500)
	TreasureScreen.suppress_audio_for_tests = true

	var screen := TREASURE_SCENE.instantiate() as Treasure21Screen
	_expect(screen != null, "TREASURE 21 scene instantiates")
	if screen == null:
		_finish()
		return
	capture_root.add_child(screen)
	await _settle(8)
	await _capture(screen, "setup")

	_show_total(screen, 12)
	await _capture(screen, "safe-12")
	_show_total(screen, 17)
	await _capture(screen, "danger-17")
	_show_total(screen, 20)
	await _capture(screen, "one-away-20")

	var result_state: Dictionary = TreasureModel.new_game(20, 19)
	result_state["total"] = 20
	result_state["current_total"] = 20
	result_state = TreasureModel.apply_roll(result_state, 1)
	screen.game = result_state
	screen.call("_show_result")
	await _capture(screen, "result-treasure")

	screen.queue_free()
	await _settle(2)
	_finish()

func _show_total(screen: Treasure21Screen, total: int) -> void:
	var state: Dictionary = TreasureModel.new_game(20, 19)
	state["total"] = total
	state["current_total"] = total
	screen.game = state
	screen.view_state = "active"
	screen.setup_view.visible = false
	screen.active_view.visible = true
	screen.result_view.visible = false
	screen.call("_refresh_all")
	screen.status_label.text = "TOTAL %d。次の一手を選ぶ。" % total
	if screen.dice_presentation != null:
		screen.dice_presentation.present([clampi((total % 6) + 1, 1, 6)], false, 1)

func _capture(screen: Treasure21Screen, capture_name: String) -> void:
	await _settle(6)
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var texture: ViewportTexture = capture_viewport.get_texture()
	var image: Image = texture.get_image()
	var path: String = output_dir.path_join("treasure21-%s-%dx%d.png" % [capture_name, viewport_size.x, viewport_size.y])
	var result: Error = image.save_png(path)
	_expect(result == OK, "%s screenshot saves" % capture_name)
	_expect(image.get_size() == viewport_size, "%s screenshot size" % capture_name)
	_assert_control_inside(screen.find_child("Treasure21Header", true, false) as Control, capture_name + " header")
	_assert_control_inside(screen.find_child("CasinoBackButton", true, false) as Control, capture_name + " back")
	if screen.active_view.visible:
		_assert_control_inside(screen.roll_button, capture_name + " roll")
		_assert_control_inside(screen.cashout_button, capture_name + " cashout")
		_assert_control_inside(screen.danger_panel, capture_name + " preview")
	print("CAPTURE %s" % path)

func _assert_control_inside(control: Control, label: String) -> void:
	_expect(control != null, "%s exists" % label)
	if control == null:
		return
	var rect: Rect2 = control.get_global_rect()
	var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size))
	_expect(rect.size.x > 0.0 and rect.size.y > 0.0, "%s has size" % label)
	_expect(bounds.encloses(rect), "%s stays on-screen" % label)

func _settle(frame_count: int) -> void:
	for _frame: int in range(frame_count):
		await process_frame

func _finish() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	Bank.clear_test_save_path()
	TreasureScreen.suppress_audio_for_tests = false
	print("TREASURE21_PRODUCT_UI assertions=%d failures=%d output=%s" % [assertions, failures, output_dir])
	quit(1 if failures > 0 else 0)
