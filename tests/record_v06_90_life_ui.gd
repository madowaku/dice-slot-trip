extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const Session = preload("res://scripts/game/v06_play_session.gd")


func _init() -> void:
	call_deferred("_record")


func _record() -> void:
	var output_path := OS.get_environment("DICE_QA_OUTPUT")
	var state_name := OS.get_environment("DICE_QA_STATE")
	var capture_size := _parse_size(OS.get_environment("DICE_QA_SIZE"))
	if output_path.is_empty() or state_name.is_empty() or capture_size == Vector2i.ZERO:
		push_error("DICE_QA_OUTPUT, DICE_QA_STATE, and DICE_QA_SIZE are required")
		quit(2)
		return
	root.size = capture_size
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	for ignored: int in range(4):
		await process_frame
	_close_start_overlays(screen)
	var session: RefCounted = screen.session_for_test()
	match state_name:
		"normal":
			pass
		"revival":
			var revival_state: Dictionary = session.stable_save_snapshot(0)
			revival_state.player.hp = 3
			revival_state.player.life = 2
			if not session.restore_stable_snapshot(revival_state, 0):
				_fail("revival fixture restore")
				return
			screen.set("_last_presented_life", 3)
			screen.call("_refresh_ui")
		"lap_full":
			screen.call("_show_operation_message", "10 LAP達成　復活 FULL", 30.0, 25)
		"lap_gain":
			screen.call("_show_operation_message", "10 LAP BONUS　復活 +1", 30.0, 25)
		"event":
			var event_state: Dictionary = session.stable_save_snapshot(0)
			event_state.route.current_node_id = "main:29"
			event_state.route.route_id = "main"
			event_state.route.tile_index = 29
			event_state.route.visited_node_keys = ["main:29"]
			event_state.player.coins = 3
			if not session.restore_stable_snapshot(event_state, 0):
				_fail("event fixture restore")
				return
			var started: Dictionary = session.start_roll(1, 1)
			if not bool(started.get("ok", false)):
				_fail("event fixture roll")
				return
			while session.has_pending_hops(): session.next_hop()
			session.finish_movement()
			screen.call("_refresh_ui")
			screen.call("_present_session_phase")
		"skill_discovery":
			_set_skill_ready(session)
			screen.call("_refresh_ui")
			screen.call("_show_skill_ready_discovery_if_eligible", -1)
		"skill_selector":
			_set_skill_ready(session)
			screen.call("_refresh_ui")
			screen.call("_on_skill_tool_pressed")
		"roulette_pending":
			if not _finish_boss(session, 1):
				_fail("wounded victory fixture")
				return
			screen.call("_cancel_motion", session.position())
			screen.call("_refresh_ui")
			screen.call("_present_session_phase")
		"roulette_result":
			if not _finish_boss(session, 1):
				_fail("retained result fixture")
				return
			session.resolve_heart_roulette(0)
			screen.call("_cancel_motion", session.position())
			screen.call("_refresh_ui")
			screen.call("_present_session_phase")
		"perfect":
			if not _finish_boss(session, 3):
				_fail("perfect fixture")
				return
			screen.call("_cancel_motion", session.position())
			screen.call("_refresh_ui")
			screen.call("_present_session_phase")
		_:
			_fail("unknown state %s" % state_name)
			return
	for ignored: int in range(8):
		await process_frame
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	var result := image.save_png(output_path)
	print("V06_90_LIFE_CAPTURE state=%s path=%s size=%s result=%s" % [state_name, output_path, image.get_size(), result])
	quit(0 if result == OK and image.get_size() == capture_size else 1)


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


func _set_skill_ready(session: RefCounted) -> void:
	var state: Dictionary = session.stable_save_snapshot(0)
	state.player.skill_gauge = 3
	state.player.skill_state = "READY"
	session.restore_stable_snapshot(state, 0)


func _finish_boss(session: RefCounted, hp: int) -> bool:
	var state: Dictionary = session.stable_save_snapshot(0)
	state.player.hp = hp
	if not session.restore_stable_snapshot(state, 0) or not session.enter_boss(1):
		return false
	for timestamp: int in [2, 3, 4, 5]:
		if session.phase() == Session.PHASE_BOSS_FINISHED:
			break
		session.start_roll(6, timestamp)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	return session.phase() == Session.PHASE_BOSS_FINISHED


func _parse_size(text: String) -> Vector2i:
	var parts := text.to_lower().split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
