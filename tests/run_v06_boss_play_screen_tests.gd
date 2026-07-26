extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_boss_victory_and_clock()
	_test_defeat_and_retry()
	_test_damaged_hp_carry()
	await _test_screen_contract()
	print("V06_BOSS_PLAY_SCREEN_TESTS failures=%d" % failures)
	quit(1 if failures else 0)


func _test_boss_victory_and_clock() -> void:
	var session: RefCounted = Session.new()
	_expect(session.enter_boss(1000), "direct boss entry starts an armed deterministic clock")
	_expect(session.faces().is_empty() and session.phase() == Session.PHASE_BOSS_ROLL_READY, "boss starts with a shared empty slot")
	session.start_roll(6, 1100)
	var first: Dictionary = session.boss_result()
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and first.player_roll == 6 and first.boss_roll == 1 and first.player_position_after == 8, "first mirror turn reveals the reverse face and BOOST")
	_expect(not session.start_roll(6, 1150).ok and session.acknowledge_boss_round() and not session.acknowledge_boss_round(), "roll while result waits and double ack are rejected")
	_expect(session.pause_clock(1200), "pause accepts monotonic caller time")
	var paused_faces: Array[int] = session.faces()
	_expect(not session.start_roll(6, 1500).ok and session.faces() == paused_faces, "roll while paused is rejected without mutation")
	_expect(session.resume_clock(1700), "resume accepts monotonic caller time")
	session.start_roll(6, 2000)
	var second: Dictionary = session.boss_result()
	_expect(second.victory and second.player_position_after == 13 and session.elapsed_ms(9999) == 500, "second high roll wins and paused time is excluded")
	_expect(session.best_ms() == 500 and session.pb_delta_ms() == null and session.acknowledge_boss_round() and session.phase() == Session.PHASE_LAP_RESULT, "first race victory records PB before result ack")
	_expect(not session.start_roll(1, 2100).ok and not session.resume_clock(2100), "lap result rejects rolls and invalid clock resume")
	_expect(session.next_lap() and session.lap() == 2 and session.player_hp() == 3 and session.position().tile_index == 0, "next lap resets travel while carrying HP")
	_expect(session.faces().is_empty() and session.snapshot().clock_armed and session.boss_snapshot().is_empty(), "next lap is blank, armed, and creates no boss early")
	_expect(not session.enter_boss(900) and session.phase() == Session.PHASE_READY, "timestamp regression rejects without phase mutation")
	_expect(session.enter_boss(4000), "later monotonic timestamp can enter next boss")
	var cursor := _win_mirror_race(session, 4000, 1000)
	_expect(session.best_ms() == 500 and int(session.pb_delta_ms()) > 0, "slower victory retains PB and positive delta")
	session.next_lap(); session.enter_boss(cursor + 100)
	cursor = _win_mirror_race(session, cursor + 100, 400)
	_expect(session.best_ms() == 400 and int(session.pb_delta_ms()) < 0, "strictly faster victory replaces PB and retains negative improvement")
	session.next_lap(); session.enter_boss(cursor + 100)
	cursor = _win_mirror_race(session, cursor + 100, 400)
	_expect(session.best_ms() == 400 and session.pb_delta_ms() == 0 and not session.snapshot().pb_updated, "tie retains PB with a zero delta")
	_expect(session.retry_run() and session.best_ms() == 400 and session.lap() == 1 and session.player_hp() == 3 and session.faces().is_empty(), "retry resets run state but preserves existing PB")


func _test_defeat_and_retry() -> void:
	var session: RefCounted = Session.new()
	_expect(not session.pause_clock(100) and session.enter_boss(50), "pause before start is non-mutating and does not poison monotonic time")
	session.start_roll(1, 100)
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and not session.boss_result().defeat, "first losing race turn shows its result")
	session.acknowledge_boss_round()
	session.start_roll(1, 200)
	_expect(session.boss_result().defeat and session.acknowledge_boss_round() and session.phase() == Session.PHASE_LAP_RESULT, "race loss completes the stage without RUN OVER")
	_expect(session.retry_run() and session.lap() == 1 and session.player_hp() == 3 and session.position().tile_index == 0, "retry starts a clean run")


func _test_damaged_hp_carry() -> void:
	var source: RefCounted = Session.new()
	var state: Dictionary = source.stable_save_snapshot(0)
	state.player.hp = 2
	var session: RefCounted = Session.new()
	_expect(session.restore_stable_snapshot(state, 0) and session.enter_boss(1), "damaged travel state enters the mirror race")
	session.start_roll(6, 100)
	session.acknowledge_boss_round()
	session.start_roll(6, 200)
	session.acknowledge_boss_round()
	_expect(session.phase() == Session.PHASE_LAP_RESULT and session.player_hp() == 2, "mirror race carries HP without changing it")
	session.next_lap(); session.enter_boss(300)
	_expect(session.lap() == 2 and session.boss_snapshot().player_hp == 2 and session.boss_snapshot().boss_hp == 3, "fresh next-lap battle carries HP2 and resets boss HP3")


func _test_screen_contract() -> void:
	var host := Control.new(); host.size = Vector2(720, 1280); root.add_child(host)
	var screen: Control = ScreenScene.instantiate(); host.add_child(screen)
	await process_frame; await process_frame
	for name: String in ["TimeLabel", "BossOverlay", "NightVignette", "BossLanternLeft", "BossLanternRight", "BossImage", "BossHPLabel", "BossRaceTrackLabel", "BossActionLabel", "BossResultLabel", "BossRoundAckButton", "NextLapButton", "RetryButton", "BossBackButton"]:
		_expect(screen.get_node_or_null("%%%s" % name) != null, "named boss UI node %s exists" % name)
	var boss_image := screen.get_node("%BossImage") as TextureRect
	var vignette := screen.get_node("%NightVignette") as TextureRect
	var left_lantern := screen.get_node("%BossLanternLeft") as TextureRect
	_expect(boss_image.texture.resource_path == "res://assets/art/v06/boss/sleepy-sphinx.png", "boss overlay uses production sphinx")
	_expect(vignette.texture.resource_path == "res://assets/art/v06/boss/night-vignette.png" and vignette.material is ShaderMaterial, "boss-only night vignette uses its luminance mask")
	_expect(left_lantern.texture is AtlasTexture and (left_lantern.texture as AtlasTexture).atlas.resource_path == "res://assets/art/v06/effects/lantern-glow.png", "boss-only lanterns use the production glow strip")
	var dice := screen.find_children("*Die*", "Button", true, false)
	_expect(dice.size() == 1 and screen.get_node("%TimeLabel").text.contains(":"), "screen keeps one roll action and readable tabular time")
	var session: RefCounted = screen.session_for_test()
	var now := Time.get_ticks_msec()
	_expect(session.enter_boss(now), "screen test enters boss through deterministic hook")
	screen.call("_present_session_phase"); screen.call("_refresh_ui"); await process_frame
	var tray := screen.get_node("%TrayPanel") as Control
	var hud := screen.get_node("%HudPanel") as Control
	var panel := screen.get_node("%BossPanel") as Control
	var overlay := screen.get_node("%BossOverlay") as Control
	var dim := overlay.get_node("Dim") as Control
	var center := overlay.get_node("Center") as Control
	_expect(overlay.visible and tray.visible and (screen.get_node("%DieButton") as Control).visible, "boss-ready keeps fixed tray and die visible")
	var hud_rect := hud.get_global_rect()
	var panel_rect := panel.get_global_rect()
	var tray_rect := tray.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(720, 1280))
	_expect(not hud_rect.intersects(panel_rect) and not tray_rect.intersects(panel_rect), "BossPanel overlaps neither HUD nor fixed tray")
	_expect(viewport_rect.encloses(hud_rect) and viewport_rect.encloses(panel_rect) and viewport_rect.encloses(tray_rect), "HUD, BossPanel, and tray remain within 720x1280")
	print("V06_BOSS_RECTS hud=%s panel=%s tray=%s" % [hud_rect, panel_rect, tray_rect])
	_expect(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE and dim.mouse_filter == Control.MOUSE_FILTER_IGNORE and center.mouse_filter == Control.MOUSE_FILTER_IGNORE, "full-screen boss layers do not intercept die input")
	screen.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_expect(session.snapshot().clock_paused, "application pause notification pauses running session clock")
	screen.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_expect(not session.snapshot().clock_paused and session.snapshot().clock_running, "application resume notification resumes session clock")
	var travel_position: Dictionary = session.position()
	screen.call("_run_face", 2); await process_frame
	_expect(session.faces() == [2] and session.position() == travel_position and session.phase() == Session.PHASE_BOSS_ROUND_RESULT, "actual screen roll resolves one mirror-race turn without travel movement")
	_expect(not (screen.get_node("%MessageLabel") as Label).text.contains("完了できません"), "boss screen roll avoids movement-finish errors")
	(screen.get_node("%BossRoundAckButton") as Button).emit_signal("pressed"); await process_frame
	_expect(session.phase() == Session.PHASE_BOSS_ROLL_READY, "screen turn acknowledgment reaches the next mirror-race roll")
	_expect((screen.get_node("%BossHPLabel") as Label).text.contains("SPHINX") and (screen.get_node("%BossActionLabel") as Label).text.contains("7-x"), "race HUD identifies the Sphinx and explains the mirror rule")
	_expect((screen as Object).call("_format_pb_delta", -2400) == "-2.4s" and (screen as Object).call("_format_pb_delta", 1300) == "+1.3s" and (screen as Object).call("_format_pb_delta", 0) == "±0.0s", "screen formats signed PB deltas")
	var touch_ok := true
	for button: Button in screen.find_children("*", "Button", true, false): touch_ok = touch_ok and button.custom_minimum_size.y >= 96
	_expect(touch_ok, "all controls meet 48px physical touch target at 720 scale")
	host.queue_free(); await process_frame
	var capture_path := OS.get_environment("DICE_QA_V06_BOSS_CAPTURE_PATH")
	if not capture_path.is_empty():
		await _capture_boss_runtime(capture_path)


func _capture_boss_runtime(path: String) -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "boss_ready")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var host := Control.new()
	host.size = Vector2(720, 1280)
	viewport.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	for ignored: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	var capture := viewport.get_texture().get_image()
	var result := capture.save_png(path)
	_expect(capture.get_size() == Vector2i(720, 1280) and result == OK, "native boss capture is deterministic 720x1280")
	print("V06_BOSS_CAPTURE path=%s size=%s result=%s" % [path, capture.get_size(), result])
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	viewport.queue_free()
	await process_frame


func _win_mirror_race(session: RefCounted, start_ms: int, duration_ms: int) -> int:
	var now := start_ms + duration_ms / 2
	session.start_roll(6, now)
	session.acknowledge_boss_round()
	now = start_ms + duration_ms
	session.start_roll(6, now)
	session.acknowledge_boss_round()
	return now


func _expect(condition: bool, label: String) -> void:
	if condition: print("PASS %s" % label)
	else: failures += 1; push_error("FAIL %s" % label)
