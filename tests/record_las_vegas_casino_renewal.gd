extends SceneTree

## Screenshot recorder for the casino renewal (hub, prize counter, 丁半).
##
##   LAS_VEGAS_QA_OUTPUT_DIR  output folder (default: artifacts/playtest/
##                            las-vegas-casino-renewal/phase1/after)
##   DICE_RACE_QA_VIEWPORT    e.g. 360x800 or 720x1280
##
## Run without --headless: the dummy renderer cannot read back a viewport.
## Uses an isolated CasinoBank save, never the player's.

const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const CHOHAN_SCENE: PackedScene = preload("res://scenes/casino/Chohan.tscn")
const POKER_SCENE: PackedScene = preload("res://scenes/casino/DicePoker.tscn")
const Poker = preload("res://scripts/app/dice_poker_screen.gd")
const Bank = preload("res://scripts/game/casino_bank.gd")
const Hub = preload("res://scripts/app/casino_hub_screen.gd")
const Chohan = preload("res://scripts/app/chohan_screen.gd")
const Model = preload("res://scripts/game/chohan_model.gd")

var failures := 0
var assertions := 0
var output_dir := ""
var viewport_size := Vector2i(360, 800)
var capture_viewport: SubViewport
var capture_root: Control
var save_path := ""


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
		output_dir = ProjectSettings.globalize_path("res://artifacts/playtest/las-vegas-casino-renewal/phase1/after")
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
	# Same offscreen setup as record_las_vegas_casino_expansion.gd: lay the
	# scene out on the 720-wide design canvas (taller on narrow phones) and
	# scale it into the requested physical size.
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

	save_path = "user://las_vegas_renewal_recorder_%d.json" % OS.get_process_id()
	Bank.set_test_save_path(save_path)
	_reset_bank(38)
	Hub.suppress_audio_for_tests = true
	Chohan.suppress_audio_for_tests = true
	Poker.suppress_audio_for_tests = true

	await _capture_hub()
	await _capture_chohan()
	await _capture_poker()

	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	_remove_save()
	Bank.clear_test_save_path()
	Hub.suppress_audio_for_tests = false
	Chohan.suppress_audio_for_tests = false
	Poker.suppress_audio_for_tests = false
	capture_viewport.queue_free()
	print("LAS_VEGAS_RENEWAL_CAPTURE size=%s assertions=%d failures=%d output=%s" % [viewport_size, assertions, failures, output_dir])
	quit(1 if failures > 0 else 0)


func _remove_save() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))


func _reset_bank(chips: int) -> void:
	_remove_save()
	var data := Bank.default_data()
	data["chips"] = chips
	Bank.save_data(data)


func _capture_hub() -> void:
	var hub := HUB_SCENE.instantiate()
	capture_root.add_child(hub)
	await _settle_frames(10)
	_assert_inside(hub.find_child("BackToTripButton", true, false) as Control, "hub trip-return button")
	_assert_inside(hub.prize_shelf, "hub prize shelf")
	for id: Variant in hub.facility_buttons.keys():
		_assert_inside(hub.facility_buttons[id] as Control, "hub %s entry" % str(id))
	await _capture("hub-saving")
	Bank.add_chips(200)
	hub.call("_refresh")
	await _capture("hub-prize-ready")
	hub.open_prize_counter()
	await _settle_frames(4)
	_assert_inside(hub.find_child("PrizeCounterCloseButton", true, false) as Control, "prize counter close button")
	await _capture("hub-prize-counter")
	hub.close_prize_counter()
	hub.queue_free()
	await _settle_frames(3)


func _capture_chohan() -> void:
	_reset_bank(120)
	var screen := CHOHAN_SCENE.instantiate()
	capture_root.add_child(screen)
	await _settle_frames(10)
	_expect(screen.shell.is_guide_open(), "chohan opens its first-play guide")
	await _capture("chohan-first-guide")
	screen.shell.close_guide()
	await _settle_frames(4)
	_assert_inside(screen.shell.primary_button, "chohan primary button")
	_assert_inside(screen.shell.back_button, "chohan back button")
	await _capture("chohan-choose")
	screen.cho_button.pressed.emit()
	await _settle_frames(4)
	await _capture("chohan-called")
	var dice: Array[int] = [3, 5]
	screen.queued_dice = dice
	screen.shell.primary_button.pressed.emit()
	await _settle_seconds(0.45)
	await _capture("chohan-shaking")
	await _settle_seconds(2.4)
	_expect(screen.state == screen.State.RESULT, "chohan reaches its result")
	await _capture("chohan-win")
	screen.han_button.pressed.emit()
	dice = [6, 6]
	screen.queued_dice = dice
	screen.shell.primary_button.pressed.emit()
	await _settle_seconds(3.0)
	await _capture("chohan-lose")
	screen.queue_free()
	await _settle_frames(3)


func _capture_poker() -> void:
	_reset_bank(120)
	var screen := POKER_SCENE.instantiate()
	capture_root.add_child(screen)
	await _settle_frames(10)
	_expect(screen.shell.is_guide_open(), "poker opens its first-play guide")
	await _capture("poker-first-guide")
	screen.shell.close_guide()
	await _settle_frames(4)
	_assert_inside(screen.shell.primary_button, "poker primary button")
	await _capture("poker-setup")
	screen.queued_roll_batch = [[3, 3, 5, 2, 6], [3, 3, 3, 5, 5]]
	screen.shell.primary_button.pressed.emit()
	await _settle_seconds(1.6)
	_expect(screen.view_state == "active", "poker deals into its active hand")
	(screen.keep_buttons[0] as Button).pressed.emit()
	(screen.keep_buttons[1] as Button).pressed.emit()
	await _settle_frames(8)
	for index: Variant in screen.keep_buttons.keys():
		_assert_inside(screen.keep_buttons[index] as Control, "poker die %d tap target" % (int(index) + 1))
	_assert_inside(screen.lock_button, "poker take-hand button")
	await _capture("poker-keep")
	screen.shell.primary_button.pressed.emit()
	await _settle_seconds(1.6)
	await _capture("poker-after-reroll")
	screen.lock_button.pressed.emit()
	await _settle_frames(12)
	_expect(screen.view_state == "result", "poker reaches its result")
	await _capture("poker-result")
	screen.queue_free()
	await _settle_frames(3)


func _assert_inside(control: Control, label: String) -> void:
	if control == null:
		_expect(false, "%s exists" % label)
		return
	var rect := control.get_global_rect()
	var bounds := Rect2(Vector2.ZERO, capture_root.size).grow(1.0)
	_expect(bounds.encloses(rect), "%s stays inside the %dx%d screen" % [label, viewport_size.x, viewport_size.y])


func _capture(name: String) -> void:
	await _settle_frames(4)
	RenderingServer.force_draw(false, 0.0)
	var image: Image = null
	if not OS.get_cmdline_args().has("--headless"):
		image = capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		print("CAPTURE_SKIPPED %s (no renderer; run without --headless)" % name)
		return
	var path := output_dir.path_join("%s-%dx%d.png" % [name, viewport_size.x, viewport_size.y])
	_expect(image.save_png(path) == OK and image.get_size() == viewport_size, "%s screenshot saved" % name)
	print("CAPTURE %s %s" % [name, path])


func _settle_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _settle_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
