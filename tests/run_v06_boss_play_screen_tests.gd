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
	_expect(session.faces().is_empty() and session.phase() == Session.PHASE_BOSS_ROLL_READY, "boss starts with three blank slots")
	for face: int in [2, 3, 4]: session.start_roll(face, 1100 + session.faces().size() * 100)
	var first: Dictionary = session.boss_result()
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and first.sum == 9 and first.defense == 9 and first.boss_hp_after == 2, "9 vs DEF 9 damages boss")
	_expect(not session.start_roll(6, 1500).ok and session.acknowledge_boss_round() and not session.acknowledge_boss_round(), "fourth roll and double ack are rejected")
	for face: int in [2, 2, 6]: session.start_roll(face, 1600 + session.faces().size() * 100)
	var second: Dictionary = session.boss_result()
	_expect(second.role == &"PAIR" and second.guard and second.player_hp_after == 3 and second.boss_hp_after == 2, "PAIR guards failed comparison")
	session.acknowledge_boss_round()
	_expect(session.pause_clock(2000), "pause accepts monotonic caller time")
	var paused_faces: Array[int] = session.faces()
	_expect(not session.start_roll(6, 2200).ok and session.faces() == paused_faces, "roll while paused is rejected without mutation")
	_expect(session.resume_clock(2500), "resume accepts monotonic caller time")
	for face: int in [1, 1, 1]: session.start_roll(face, 2600 + session.faces().size() * 100)
	var third: Dictionary = session.boss_result()
	_expect(third.triple and third.applied_boss_damage == 2 and session.elapsed_ms(9999) == 1300, "TRIPLE wins and clock stops at damage with pause excluded")
	_expect(session.best_ms() == 1300 and session.pb_delta_ms() == null and session.acknowledge_boss_round() and session.phase() == Session.PHASE_LAP_RESULT, "first victory records PB with no prior comparison before result ack")
	_expect(not session.start_roll(1, 3000).ok and not session.resume_clock(3000), "lap result rejects rolls and invalid clock resume")
	_expect(session.next_lap() and session.lap() == 2 and session.player_hp() == 3 and session.position().tile_index == 0, "next lap resets travel while carrying HP")
	_expect(session.faces().is_empty() and session.snapshot().clock_armed and session.boss_snapshot().is_empty(), "next lap is blank, armed, and creates no boss early")
	_expect(not session.enter_boss(900) and session.phase() == Session.PHASE_READY, "timestamp regression rejects without phase mutation")
	_expect(session.enter_boss(4000), "later monotonic timestamp can enter next boss")
	var cursor := _win_with_triples(session, 4000, 2000)
	_expect(session.best_ms() == 1300 and int(session.pb_delta_ms()) > 0, "slower victory retains PB and positive delta")
	session.next_lap(); session.enter_boss(cursor + 100)
	cursor = _win_with_triples(session, cursor + 100, 900)
	_expect(session.best_ms() == 900 and int(session.pb_delta_ms()) < 0, "strictly faster victory replaces PB and retains negative improvement")
	session.next_lap(); session.enter_boss(cursor + 100)
	cursor = _win_with_triples(session, cursor + 100, 900)
	_expect(session.best_ms() == 900 and session.pb_delta_ms() == 0 and not session.snapshot().pb_updated, "tie retains PB with a zero delta")
	while session.lap() < 9:
		session.next_lap(); session.enter_boss(cursor + 100)
		cursor = _win_with_triples(session, cursor + 100, 1000)
	session.next_lap(); session.enter_boss(cursor + 100)
	_expect(session.lap() == 10 and session.boss_snapshot().defense == 11, "lap 10 creates an enhanced fresh boss with DEF +2")
	_expect(session.retry_run() and session.best_ms() == 900 and session.lap() == 1 and session.player_hp() == 3 and session.faces().is_empty(), "retry resets run state but preserves existing PB")


func _test_defeat_and_retry() -> void:
	var session: RefCounted = Session.new()
	_expect(not session.pause_clock(100) and session.enter_boss(50), "pause before start is non-mutating and does not poison monotonic time")
	var now := 100
	for round_index: int in range(3):
		for face: int in [1, 2, 3]:
			session.start_roll(face, now); now += 100
		_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT, "defeat round shows result before outcome")
		session.acknowledge_boss_round()
	_expect(session.phase() == Session.PHASE_RUN_OVER and session.player_hp() == 0, "three failed rounds enter RUN OVER after ack")
	_expect(session.retry_run() and session.lap() == 1 and session.player_hp() == 3 and session.position().tile_index == 0, "retry starts a clean run")


func _test_damaged_hp_carry() -> void:
	var session: RefCounted = Session.new(); session.enter_boss(0)
	var now := 100
	for face: int in [1, 2, 3]: session.start_roll(face, now); now += 100
	session.acknowledge_boss_round()
	_expect(session.player_hp() == 2, "failed round actually lowers player HP to 2")
	for round_index: int in range(2):
		for face: int in [1, 1, 1]: session.start_roll(face, now); now += 100
		session.acknowledge_boss_round()
	_expect(session.phase() == Session.PHASE_LAP_RESULT and session.player_hp() == 2, "damaged player can win without healing")
	session.next_lap(); session.enter_boss(now + 100)
	_expect(session.lap() == 2 and session.boss_snapshot().player_hp == 2 and session.boss_snapshot().boss_hp == 3, "fresh next-lap battle carries HP2 and resets boss HP3")


func _test_screen_contract() -> void:
	var host := Control.new(); host.size = Vector2(720, 1280); root.add_child(host)
	var screen: Control = ScreenScene.instantiate(); host.add_child(screen)
	await process_frame; await process_frame
	for name: String in ["TimeLabel", "BossOverlay", "NightVignette", "BossLanternLeft", "BossLanternRight", "BossImage", "BossHPLabel", "BossActionLabel", "BossResultLabel", "BossRoundAckButton", "NextLapButton", "RetryButton", "BossBackButton"]:
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
	_expect(session.faces() == [2] and session.position() == travel_position and session.phase() == Session.PHASE_BOSS_ROLL_READY, "actual screen roll path commits one boss face without travel movement")
	_expect(not (screen.get_node("%MessageLabel") as Label).text.contains("完了できません"), "boss screen roll avoids movement-finish errors")
	screen.call("_run_face", 3); screen.call("_run_face", 4); await process_frame
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and overlay.visible and (screen.get_node("%BossRoundAckButton") as Button).visible, "third actual boss screen roll shows round result")
	(screen.get_node("%BossRoundAckButton") as Button).emit_signal("pressed"); await process_frame
	_expect(session.phase() == Session.PHASE_BOSS_ROLL_READY, "screen result acknowledgment reaches next boss round")
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


func _win_with_triples(session: RefCounted, start_ms: int, duration_ms: int) -> int:
	var step := duration_ms / 6
	var now := start_ms
	for round_index: int in range(2):
		for face_index: int in range(3):
			now = start_ms + step * (round_index * 3 + face_index + 1)
			session.start_roll(1, now)
		session.acknowledge_boss_round()
	return now


func _expect(condition: bool, label: String) -> void:
	if condition: print("PASS %s" % label)
	else: failures += 1; push_error("FAIL %s" % label)
