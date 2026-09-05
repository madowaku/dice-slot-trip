extends SceneTree

const TOWER_SCENE: PackedScene = preload("res://scenes/casino/DiceTower.tscn")
const BANK_SCRIPT = preload("res://scripts/game/casino_bank.gd")

const DESIGN_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(360, 800)
const RESULT_SETTLE_FRAMES := 24

var capture_viewport: SubViewport
var capture_root: Control
var tower: DiceTowerScreen
var failures: int = 0

func _init() -> void:
	call_deferred("_record")

func _record() -> void:
	var output_dir: String = OS.get_environment("DICE_TOWER_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/playtest/dice-tower-v1")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var requested: String = OS.get_environment("DICE_TOWER_QA_VIEWPORT")
	var capture_output: Vector2i = OUTPUT_SIZE
	if requested == "720x1280":
		capture_output = Vector2i(720, 1280)
	var save_path: String = "user://dice_tower_recorder_%d.json" % OS.get_process_id()
	BANK_SCRIPT.set_test_save_path(save_path)
	BANK_SCRIPT.add_chips(1240)

	capture_viewport = SubViewport.new()
	capture_viewport.size = DESIGN_SIZE
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.transparent_bg = false
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.size = Vector2(DESIGN_SIZE)
	capture_viewport.add_child(capture_root)

	tower = TOWER_SCENE.instantiate() as DiceTowerScreen
	if tower == null:
		push_error("DICE_TOWER_CAPTURE: scene did not instantiate as DiceTowerScreen")
		quit(1)
		return
	capture_root.add_child(tower)
	await _settle(8)
	tower.call("_close_tutorial")
	await _settle(4)
	_check_controls_inside([tower.start_button, tower.bet_buttons[10], tower.bet_buttons[20], tower.bet_buttons[50]], "setup")
	_capture(output_dir.path_join("setup-%dx%d.png" % [capture_output.x, capture_output.y]), capture_output)
	await _resize_design(Vector2i(720, 1560))
	_check_controls_inside([tower.start_button, tower.bet_buttons[10], tower.bet_buttons[20], tower.bet_buttons[50]], "setup-780")
	_capture(output_dir.path_join("setup-360x780.png"), Vector2i(360, 780))
	await _resize_design(DESIGN_SIZE)

	tower.call("_start_game")
	await _settle(48)
	tower.game.floor = 5
	tower.game.highest_floor = 5
	tower.game.last_roll = 6
	tower.game.last_kind = "leap"
	tower.call("_refresh_all")
	await _settle(8)
	_check_controls_inside([tower.cashout_button, tower.roll_button], "active")
	_capture(output_dir.path_join("active-floor5-%dx%d.png" % [capture_output.x, capture_output.y]), capture_output)
	await _resize_design(Vector2i(720, 1560))
	_check_controls_inside([tower.cashout_button, tower.roll_button], "active-780")
	_capture(output_dir.path_join("active-floor5-360x780.png"), Vector2i(360, 780))
	await _resize_design(DESIGN_SIZE)

	tower.game.floor = 0
	tower.game.highest_floor = 8
	tower.game.floor_before_bust = 8
	tower.game.lost_payout = 62
	tower.game.last_roll = 1
	tower.game.last_kind = "bust"
	tower.game.finished = true
	tower.game.busted = true
	tower.game.active = false
	tower.game.payout = 0
	tower.call("_set_result_finished")
	tower.call("_refresh_all")
	tower.call("_show_bust_result")
	await _settle(RESULT_SETTLE_FRAMES)
	_check_controls_inside([tower.result_overlay.find_child("RetryButton", true, false) as Control], "bust")
	_capture(output_dir.path_join("bust-floor8-%dx%d.png" % [capture_output.x, capture_output.y]), capture_output)
	await _resize_design(Vector2i(720, 1560))
	_check_controls_inside([tower.result_overlay.find_child("RetryButton", true, false) as Control], "bust-780")
	_capture(output_dir.path_join("bust-floor8-360x780.png"), Vector2i(360, 780))
	await _resize_design(DESIGN_SIZE)

	tower.game.floor = 10
	tower.game.highest_floor = 10
	tower.game.last_roll = 6
	tower.game.last_kind = "leap"
	tower.game.finished = true
	tower.game.busted = false
	tower.game.completed = true
	tower.game.cashed_out = true
	tower.game.active = false
	tower.game.payout = 84
	tower.call("_show_success_result", 84)
	await _settle(RESULT_SETTLE_FRAMES)
	_check_controls_inside([tower.result_overlay.find_child("RetryButton", true, false) as Control], "success")
	_capture(output_dir.path_join("success-floor10-%dx%d.png" % [capture_output.x, capture_output.y]), capture_output)

	print("DICE_TOWER_CAPTURE failures=%d output=%s" % [failures, output_dir])
	var bgm: Node = root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	var ui_sfx: Node = root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	if is_instance_valid(capture_viewport):
		capture_viewport.queue_free()
	await _settle(3)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	BANK_SCRIPT.clear_test_save_path()
	quit(1 if failures > 0 else 0)

func _settle(frames: int) -> void:
	for _frame: int in range(frames):
		await process_frame

func _resize_design(design_size: Vector2i) -> void:
	capture_viewport.size = design_size
	capture_root.size = Vector2(design_size)
	await _settle(4)

func _capture(path: String, output_size: Vector2i = OUTPUT_SIZE) -> void:
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image: Image = capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		failures += 1
		push_error("DICE_TOWER_CAPTURE: empty image for %s" % path)
		return
	image.resize(output_size.x, output_size.y, Image.INTERPOLATE_LANCZOS)
	var error: Error = image.save_png(path)
	if error != OK:
		failures += 1
		push_error("DICE_TOWER_CAPTURE: save failed for %s" % path)
	else:
		print("CAPTURE %s" % path)

func _check_controls_inside(controls: Array, state_name: String) -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(capture_viewport.size))
	for candidate: Variant in controls:
		var control: Control = candidate as Control
		if control == null or not control.visible:
			failures += 1
			push_error("DICE_TOWER_LAYOUT: %s has a missing or hidden required control" % state_name)
			continue
		var rect: Rect2 = control.get_global_rect()
		if not bounds.encloses(rect):
			failures += 1
			push_error("DICE_TOWER_LAYOUT: %s control outside viewport: %s" % [state_name, rect])
