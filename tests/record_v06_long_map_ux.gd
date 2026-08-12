extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")


func _init() -> void:
	call_deferred("_record")


func _record() -> void:
	var output_path := OS.get_environment("DICE_QA_OUTPUT")
	var state_name := OS.get_environment("DICE_QA_STATE")
	var capture_size := _parse_size(OS.get_environment("DICE_QA_SIZE"))
	if output_path.is_empty() or state_name.is_empty() or capture_size == Vector2i.ZERO:
		_fail("DICE_QA_OUTPUT, DICE_QA_STATE, and DICE_QA_SIZE are required")
		return
	root.size = capture_size
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	for ignored: int in range(6):
		await process_frame
	_close_start_overlays(screen)
	match state_name:
		"normal":
			screen.call("_refresh_ui")
		"map_min", "map_max":
			_prepare_running_clock(screen)
			screen.call("_on_map_pressed")
			var overview := screen.get_node("%OverviewAtlasView") as Control
			var drag := Vector2(1000000.0, 1000000.0) if state_name == "map_min" else Vector2(-1000000.0, -1000000.0)
			if not bool(overview.call("pan_overview", drag)):
				_fail("overview pan rejected")
				return
		"boss_start3":
			var session: RefCounted = screen.session_for_test()
			var state: Dictionary = session.stable_save_snapshot(0)
			state.player.coins = 4
			if not session.restore_stable_snapshot(state, 0):
				_fail("boss fixture restore")
				return
			if not bool(session.purchase_coin_action("boss_head_start").get("ok", false)) or not session.enter_boss(1):
				_fail("boss START+3 fixture")
				return
			screen.set("_stage_intro_active", false)
			screen.set("_movement_active", false)
			screen.call("_present_session_phase")
			screen.call("_refresh_ui")
			screen.call("_dismiss_boss_intro")
		_:
			_fail("unknown state %s" % state_name)
			return
	for ignored: int in range(12):
		await process_frame
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	var sanity_ok := _pixel_sanity(image)
	var result := image.save_png(output_path)
	print("V06_LONG_MAP_UX_CAPTURE state=%s path=%s size=%s sanity=%s result=%s" % [state_name, output_path, image.get_size(), sanity_ok, result])
	quit(0 if result == OK and image.get_size() == capture_size and sanity_ok else 1)


func _close_start_overlays(screen: Control) -> void:
	if bool(screen.get("_map_open")):
		screen.call("_on_map_closed")
	screen.set("_three_roll_onboarding_open", false)
	screen.set("_onboarding_kind", "")
	screen.set("_three_roll_onboarding_clock_paused", false)
	(screen.get_node("%LandingArtOverlay") as Control).hide()
	var session: RefCounted = screen.session_for_test()
	if bool(session.snapshot().get("clock_paused", false)):
		session.resume_clock(Time.get_ticks_msec())


func _prepare_running_clock(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	var started: Dictionary = session.start_roll(1, Time.get_ticks_msec())
	if not bool(started.get("ok", false)):
		return
	while session.has_pending_hops():
		session.next_hop()
	session.finish_movement()
	screen.call("_refresh_ui")


func _pixel_sanity(image: Image) -> bool:
	if image.is_empty():
		return false
	var first := image.get_pixel(0, 0)
	for y: int in range(0, image.get_height(), maxi(image.get_height() / 9, 1)):
		for x: int in range(0, image.get_width(), maxi(image.get_width() / 9, 1)):
			var sample := image.get_pixel(x, y)
			if absf(sample.r - first.r) + absf(sample.g - first.g) + absf(sample.b - first.b) > 0.05:
				return true
	return false


func _parse_size(text: String) -> Vector2i:
	var parts := text.to_lower().split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
