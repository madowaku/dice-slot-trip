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
	_test_boss_finished_guards()
	await _test_screen_contract()
	print("V06_BOSS_PLAY_SCREEN_TESTS failures=%d" % failures)
	quit(1 if failures else 0)


func _test_boss_victory_and_clock() -> void:
	var session: RefCounted = Session.new()
	_expect(session.enter_boss(1000), "direct boss entry starts an armed deterministic clock")
	_expect(session.faces().is_empty() and session.phase() == Session.PHASE_BOSS_ROLL_READY, "boss starts without a 3ROLL SLOT")
	session.start_roll(6, 1100)
	var first: Dictionary = session.boss_result()
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and first.player_roll == 6 and first.boss_roll == 1 and first.player_position_after == 6, "first turn reveals the reverse face on the 20-space course")
	_expect(not session.start_roll(6, 1150).ok and session.acknowledge_boss_round() and not session.acknowledge_boss_round(), "roll while result waits and double ack are rejected")
	_expect(session.pause_clock(1200), "pause accepts monotonic caller time")
	var paused_faces: Array[int] = session.faces()
	_expect(not session.start_roll(6, 1500).ok and session.faces() == paused_faces, "roll while paused is rejected without mutation")
	_expect(session.resume_clock(1700), "resume accepts monotonic caller time")
	for now: int in [1800, 1900, 2000]:
		session.start_roll(6, now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	var second: Dictionary = session.boss_result()
	_expect(second.victory and second.player_position_after == 20 and session.elapsed_ms(9999) == 500, "fourth high roll wins and paused time is excluded")
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
	for now: int in [200, 300, 400]:
		session.start_roll(1, now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	_expect(session.boss_result().defeat and session.acknowledge_boss_round() and session.phase() == Session.PHASE_LAP_RESULT, "race loss completes the stage without RUN OVER")
	_expect(session.retry_run() and session.lap() == 1 and session.player_hp() == 3 and session.position().tile_index == 0, "retry starts a clean run")


func _test_damaged_hp_carry() -> void:
	var source: RefCounted = Session.new()
	var state: Dictionary = source.stable_save_snapshot(0)
	state.player.hp = 2
	var session: RefCounted = Session.new()
	_expect(session.restore_stable_snapshot(state, 0) and session.enter_boss(1), "damaged travel state enters the mirror race")
	for now: int in [100, 200, 300, 400]:
		session.start_roll(6, now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	session.acknowledge_boss_round()
	_expect(session.phase() == Session.PHASE_LAP_RESULT and session.player_hp() == 2, "mirror race carries HP without changing it")
	session.next_lap(); session.enter_boss(700)
	_expect(session.lap() == 2 and session.boss_snapshot().player_hp == 2 and session.boss_snapshot().boss_hp == 3, "fresh next-lap battle carries HP2 and resets boss HP3")


func _test_boss_finished_guards() -> void:
	var session: RefCounted = Session.new()
	_expect(session.enter_boss(0), "finished guard enters boss")
	for now: int in [100, 200, 300]:
		session.start_roll(6, now)
		_expect(session.acknowledge_boss_round(), "finished guard acknowledges non-terminal turn %d" % now)
	session.start_roll(6, 400)
	var finished_faces: Array[int] = session.faces()
	var finished_score: int = session.score()
	var finished_breakdown: Dictionary = session.score_breakdown()
	_expect(session.phase() == Session.PHASE_BOSS_FINISHED and not session.can_roll(), "goal enters the dedicated FINISHED phase")
	_expect(not session.start_roll(1, 300).ok and session.faces() == finished_faces, "goal after finish rejects ROLL and keeps slot faces stable")
	_expect(session.score() == finished_score and session.score_breakdown() == finished_breakdown, "boss finish record is not awarded twice")
	var saved: Dictionary = session.stable_save_snapshot(300)
	var restored: RefCounted = Session.new()
	_expect(not saved.is_empty() and restored.restore_stable_snapshot(saved, 300) and restored.phase() == Session.PHASE_BOSS_FINISHED, "FINISHED result is stable and restorable")
	_expect(session.next_lap() and session.phase() == Session.PHASE_READY, "FINISHED exposes only the next journey transition")


func _test_screen_contract() -> void:
	var host := Control.new(); host.size = Vector2(720, 1280); root.add_child(host)
	var screen: Control = ScreenScene.instantiate(); host.add_child(screen)
	await process_frame; await process_frame
	for name: String in ["TimeLabel", "BossOverlay", "BossArenaBackdrop", "BossArenaBackdropNext", "BossHud", "BossYouProgressLabel", "BossSphinxProgressLabel", "BossPauseButton", "BossStartRulePanel", "BossQuickRulePanel", "MirrorPanel", "BossDicePresentation", "BossDiceOwnerLabel", "BossLaneBoard", "GoldenGateSprite", "BossPlayerTargetLabel", "BossSphinxTargetLabel", "PlayerFootMarker", "BossFootMarker", "BossFinishDim", "BossFinishSummaryLabel", "BossPauseOverlay", "BossResumeButton", "BossImage", "BossActionLabel", "BossResultLabel", "BossRoundAckButton", "NextLapButton", "RetryButton", "BossBackButton"]:
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
	screen.set("_stage_intro_active", false)
	screen.set("_movement_active", false)
	screen.call("_present_session_phase"); screen.call("_refresh_ui"); await process_frame
	var tray := screen.get_node("%TrayPanel") as Control
	var hud := screen.get_node("%HudPanel") as Control
	var stage_band := screen.get_node("%StageBand") as Control
	var tool_dock := screen.get_node("%ToolDock") as Control
	var boss_hud := screen.get_node("%BossHud") as Control
	var panel := screen.get_node("%BossPanel") as Control
	var race_stage := screen.get_node("%RaceStage") as Control
	var overlay := screen.get_node("%BossOverlay") as Control
	var dim := overlay.get_node("Dim") as Control
	var center := overlay.get_node("Center") as Control
	var die_button := screen.get_node("%DieButton") as Button
	_expect(overlay.visible and tray.visible and die_button.visible, "boss-ready keeps fixed tray and die visible")
	_expect(panel.scale == Vector2.ONE and int(screen.get("_boss_last_player_position")) == 0 and int(screen.get("_boss_last_position")) == 0, "boss intro starts from one fixed-scale frame without an entry movement tween")
	_expect(not hud.visible and not stage_band.visible and not tool_dock.visible and boss_hud.visible, "boss race replaces the normal stage chrome with the minimal boss HUD")
	_expect((screen.get_node("%BossYouProgressLabel") as Label).text == "0 / 20" and (screen.get_node("%BossSphinxProgressLabel") as Label).text == "0 / 20", "minimal boss HUD exposes only both 20-space race counters")
	_expect((screen.get_node("%BossStartRulePanel") as Control).visible and not (screen.get_node("%MirrorPanel") as Control).visible, "black mirror-rule panel appears only at the race start")
	_expect(die_button.disabled, "start explanation blocks ROLL input")
	screen.call("_on_die_pressed")
	_expect(session.faces().is_empty(), "start explanation does not mutate the slot")
	await create_timer(1.60).timeout
	# Hardware-backed SubViewport startup can delay the deferred timer while
	# shaders compile; finish the already-verified intro gate deterministically.
	if bool(screen.get("_boss_intro_active")):
		screen.set("_boss_intro_active", false)
		screen.set("_boss_intro_complete", true)
	screen.call("_refresh_ui")
	_expect(not die_button.disabled and not bool(screen.get("_boss_intro_active")), "explanation ends before READY accepts input")
	screen.call("_start_roll"); await process_frame
	var preview_face := int((screen.get_node("%PlayerRollValue") as Label).text)
	var lane_board := screen.get_node("%BossLaneBoard")
	_expect(not (screen.get_node("%SlotColumn") as Control).visible and not (screen.get_node("%TrayStatusLabel") as Control).visible and session.faces().is_empty(), "boss race removes the 3ROLL SLOT surface and state")
	_expect((screen.get_node("%BossRollValue") as Label).text == str(7 - preview_face) and not (screen.get_node("%MirrorPanel") as Control).visible, "rolling preview shares one value but does not expose the mirror equation before STOP")
	_expect(int(lane_board.get("player_preview_position")) == preview_face and int(lane_board.get("boss_preview_position")) == 7 - preview_face, "current mirror destinations are highlighted on both concrete lanes")
	var boss_die := screen.get_node("%BossDicePresentation") as Control
	_expect((boss_die as Object).call("pool_receipt").tray_visible == false and (screen.get_node("%BossDiceShadow") as Control).visible, "boss die removes the pedestal and keeps only an oval contact shadow")
	_expect(boss_die.size.x >= 140.0 and bool(boss_die.get("high_contrast_pips")), "boss roll die is enlarged by roughly eighteen percent and uses high-contrast pips")
	var permanent_steps_hidden := true
	for index: int in range(1, 7):
		permanent_steps_hidden = permanent_steps_hidden and not (screen.get_node("%BossForwardStep" + str(index)) as Control).visible
	_expect(permanent_steps_hidden, "course hides permanent relative 1-6 labels during live preview")
	screen.call("_cancel_motion", session.position()); screen.call("_refresh_ui")
	_expect(not (screen.get_node("%BossBackButton") as Control).is_visible_in_tree(), "stage select is absent from the live play surface")
	var hud_rect := hud.get_global_rect()
	var boss_hud_rect := boss_hud.get_global_rect()
	var panel_rect := panel.get_global_rect()
	var tray_rect := tray.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(720, 1280))
	_expect(not boss_hud_rect.intersects(panel_rect) and not tray_rect.intersects(panel_rect), "course overlaps neither minimal boss HUD nor fixed tray")
	_expect(viewport_rect.encloses(boss_hud_rect) and viewport_rect.encloses(panel_rect) and viewport_rect.encloses(tray_rect), "boss HUD, course, and tray remain within 720x1280")
	_expect(race_stage.size.y >= 704.0 and race_stage.size.y <= 768.0, "course occupies 55-60 percent of the 1280px design height")
	var player_token := screen.get_node("%PlayerToken") as Control
	var sphinx_token := screen.get_node("%BossToken") as Control
	_expect(player_token.size.x >= 120.0 and sphinx_token.size.x >= 120.0 and (screen.get_node("%PlayerFootMarker") as Control).visible and (screen.get_node("%BossFootMarker") as Control).visible, "both racers are enlarged and keep distinct foot markers")
	_expect(session.boss_course_tiles(true).has("WING_GATE") and session.boss_course_tiles(true).has("QUICKSAND") and not session.boss_course_tiles(true).has("REST"), "concrete lanes keep only readable wing and sand effects")
	lane_board.call("clear_preview")
	lane_board.call("set_camera_position", 0.0)
	var initial_camera := float(lane_board.get("camera_position"))
	lane_board.call("set_racers", 2.0, 10.0)
	lane_board.call("set_preview", {"player_position": 6, "boss_position": 5, "player_roll": 4, "boss_roll": 3})
	_expect(is_equal_approx(float(lane_board.get("camera_position")), initial_camera), "racer and preview updates never move or zoom the camera")
	var first_step: Vector2 = lane_board.call("lane_point", 1.0, true)
	var second_step: Vector2 = lane_board.call("lane_point", 2.0, true)
	_expect(is_equal_approx(absf(first_step.y - second_step.y), 78.0) and is_equal_approx(first_step.x, second_step.x), "concrete cells retain fixed scale and vertical spacing throughout the race")
	_expect(is_equal_approx(float(lane_board.call("next_camera_scroll_target", 10.0)), 2.0), "camera requests exactly one two-space vertical scroll only after an out-of-safe-area movement")
	_expect(str(lane_board.call("offscreen_marker_text", 10.0, false, 2.0)) == "SPHINX ↑ 8マス先", "offscreen opponent is replaced by an edge distance marker")
	lane_board.call("set_camera_position", 8.0)
	_expect(str(lane_board.call("offscreen_marker_text", 0.0, false, 8.0)) == "SPHINX ↓ 8マス後ろ", "a trailing offscreen opponent gets the matching downward distance marker")
	lane_board.call("set_camera_position", 2.0)
	var scrolled_step: Vector2 = lane_board.call("lane_point", 2.0, true)
	_expect(is_equal_approx(scrolled_step.x, second_step.x) and is_equal_approx(scrolled_step.y - second_step.y, 156.0), "two-space camera scroll is vertical translation only, with no lane or object scaling")
	var backdrop := screen.get_node("%BossArenaBackdrop") as TextureRect
	var backdrop_next := screen.get_node("%BossArenaBackdropNext") as TextureRect
	var backdrop_scale := backdrop.scale
	screen.call("_sync_boss_board_tokens")
	_expect(backdrop.scale == backdrop_scale and backdrop_next.modulate.a <= 0.001, "gate approach begins on one static backdrop plate without continuous magnification")
	lane_board.call("set_camera_position", 0.0)
	screen.set("_boss_visual_player_position", 10.0)
	screen.set("_boss_visual_sphinx_position", 2.0)
	screen.call("_sync_boss_board_tokens")
	_expect(player_token.visible and player_token.position.y >= 0.0 and player_token.position.y + player_token.size.y <= race_stage.size.y, "player token stays pinned inside the lane while the post-movement camera catches up")
	screen.set("_boss_roll_animation_active", true)
	screen.call("_refresh_ui")
	var camera_hold_started := Time.get_ticks_msec()
	var camera_settled: bool = await screen.call("_settle_boss_camera_after_movement", 10, int(screen.get("_boss_roll_sequence_id")))
	var camera_hold_elapsed := Time.get_ticks_msec() - camera_hold_started
	var settled_player_point: Vector2 = lane_board.call("lane_point", 10.0, true)
	_expect(camera_settled and camera_hold_elapsed >= 2300 and is_equal_approx(float(lane_board.get("camera_position")), 10.0), "camera repeats eased two-space segments until the player is safely framed")
	_expect(settled_player_point.y >= 620.0 and settled_player_point.y <= 725.0, "completed camera settle leaves the player visible near the lower lane anchor")
	_expect(die_button.disabled, "ROLL stays unavailable through the post-scroll 120ms hold")
	_expect(backdrop.scale == backdrop_scale and backdrop_next.modulate.a <= 0.001, "board scrolling does not start or interpolate a backdrop crossfade")
	screen.set("_boss_roll_animation_active", false)
	screen.set("_boss_intro_active", false)
	screen.set("_boss_intro_complete", true)
	screen.set("_movement_active", false)
	screen.call("_refresh_ui")
	_expect(not die_button.disabled, "ROLL becomes available only after the camera sequence caller completes")
	lane_board.call("clear_preview")
	lane_board.call("set_camera_position", 0.0)
	lane_board.call("set_racers", 0.0, 0.0)
	screen.set("_boss_visual_player_position", 0.0)
	screen.set("_boss_visual_sphinx_position", 0.0)
	screen.call("_sync_boss_board_tokens")
	_expect(panel_rect.size.y * 0.5 >= 352.0 and player_token.size.x * 0.5 >= 60.0, "720x1280 design geometry remains readable at the 360x640 half-scale window")
	print("V06_BOSS_RECTS boss_hud=%s panel=%s tray=%s" % [boss_hud_rect, panel_rect, tray_rect])
	_expect(overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE and dim.mouse_filter == Control.MOUSE_FILTER_IGNORE and center.mouse_filter == Control.MOUSE_FILTER_IGNORE, "full-screen boss layers do not intercept die input")
	(screen.get_node("%BossPauseButton") as Button).emit_signal("pressed"); await process_frame
	_expect((screen.get_node("%BossPauseOverlay") as Control).visible and session.snapshot().clock_paused and (screen.get_node("%BossBackButton") as Control).is_visible_in_tree(), "pause menu owns stage select and pauses the boss clock")
	(screen.get_node("%BossResumeButton") as Button).emit_signal("pressed"); await process_frame
	_expect(not (screen.get_node("%BossPauseOverlay") as Control).visible and not session.snapshot().clock_paused, "resume returns to the race without exposing stage select")
	screen.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_expect(session.snapshot().clock_paused, "application pause notification pauses running session clock")
	screen.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_expect(not session.snapshot().clock_paused and session.snapshot().clock_running, "application resume notification resumes session clock")
	var travel_position: Dictionary = session.position()
	screen.call("_run_face", 2); await process_frame
	_expect(session.faces().is_empty() and session.position() == travel_position and session.phase() == Session.PHASE_BOSS_ROUND_RESULT, "actual screen roll resolves one two-lane race turn without travel movement or SLOT fill")
	_expect((screen.get_node("%BossDiceOwnerLabel") as Label).text == "YOU" and (screen.get_node("%BossDiceOwnerLabel") as Control).visible and not (screen.get_node("%MirrorPanel") as Control).visible, "STOP first fixes and enlarges the YOU face without showing the equation")
	await create_timer(0.28).timeout
	_expect((screen.get_node("%BossDiceOwnerLabel") as Label).text == "SPHINX" and not (screen.get_node("%MirrorPanel") as Control).visible, "half-turn labels the opposite face as SPHINX before the equation appears")
	await create_timer(0.32).timeout
	_expect(not (screen.get_node("%BossStartRulePanel") as Control).visible and (screen.get_node("%MirrorPanel") as Control).visible, "first roll replaces the rule panel with the compact mirror values")
	_expect(not (screen.get_node("%MessageLabel") as Label).text.contains("完了できません"), "boss screen roll avoids movement-finish errors")
	(screen.get_node("%BossRoundAckButton") as Button).emit_signal("pressed"); await process_frame
	_expect(session.phase() == Session.PHASE_BOSS_ROLL_READY, "screen turn acknowledgment reaches the next mirror-race roll")
	_expect((screen.get_node("%BossSphinxProgressLabel") as Label).text.contains("/ 20") and (screen.get_node("%BossActionLabel") as Label).text.contains("1↔6"), "race HUD identifies the Sphinx and the intro explains opposite faces without top/bottom wording")
	_expect((screen as Object).call("_format_pb_delta", -2400) == "-2.4s" and (screen as Object).call("_format_pb_delta", 1300) == "+1.3s" and (screen as Object).call("_format_pb_delta", 0) == "±0.0s", "screen formats signed PB deltas")
	var touch_ok := true
	for button: Button in screen.find_children("*", "Button", true, false): touch_ok = touch_ok and button.custom_minimum_size.y >= 96
	_expect(touch_ok, "all controls meet 48px physical touch target at 720 scale")
	var terminal_host := Control.new(); terminal_host.size = Vector2(720, 1280); root.add_child(terminal_host)
	var terminal_screen: Control = ScreenScene.instantiate(); terminal_host.add_child(terminal_screen)
	await process_frame; await process_frame
	var terminal_session: RefCounted = terminal_screen.session_for_test()
	terminal_session.enter_boss(0)
	for offset: int in [1, 2, 3]:
		terminal_session.start_roll(6, offset)
		terminal_session.acknowledge_boss_round()
	terminal_screen.call("_cancel_motion", terminal_session.position())
	terminal_screen.call("_run_face", 6)
	await create_timer(3.0).timeout
	_expect(terminal_session.phase() == Session.PHASE_BOSS_FINISHED and not (terminal_screen.get_node("%DieButton") as Button).visible and (terminal_screen.get_node("%NextLapButton") as Button).visible and not (terminal_screen.get_node("%NextLapButton") as Button).disabled, "screen finish exposes only Next Lap")
	var finish_dim := terminal_screen.get_node("%BossFinishDim") as Control
	var finish_summary := terminal_screen.get_node("%BossFinishSummaryLabel") as Label
	var finish_button := terminal_screen.get_node("%NextLapButton") as Control
	var finish_panel := terminal_screen.get_node("%BossPanel") as Control
	var finish_tray := terminal_screen.get_node("%TrayPanel") as Control
	_expect(finish_dim.visible and finish_summary.visible and finish_summary.text.contains("投・非6選択") and finish_summary.text.contains("最終投前差"), "FINISHED switches to a dedicated dimmed result presentation with race statistics")
	_expect((terminal_screen.get_node("%BossResultLabel") as Label).get_theme_font_size("font_size") >= 46, "FINISHED gives the winner callout stronger priority than the delayed statistics")
	_expect(not finish_button.get_global_rect().intersects(finish_panel.get_global_rect()) and finish_button.get_global_rect().intersects(finish_tray.get_global_rect()), "Next Journey is centered in the lower action frame instead of overlapping the board")
	var terminal_faces: Array[int] = terminal_session.faces()
	await create_timer(2.0).timeout
	var terminal_slot_text := (terminal_screen.get_node("%Slot0") as Label).text
	terminal_screen.call("_run_face", 1)
	await create_timer(2.0).timeout
	_expect(terminal_session.faces() == terminal_faces and (terminal_screen.get_node("%Slot0") as Label).text == terminal_slot_text and not bool(terminal_screen.get("_rolling")) and (terminal_screen.get_node("%BossResultLabel") as Label).text == "YOU WIN", "old await cannot continue after FINISHED")
	terminal_host.queue_free(); await process_frame
	var repeat_session: RefCounted = Session.new()
	repeat_session.enter_boss(100)
	for timestamp: int in [200, 300, 400, 500]:
		repeat_session.start_roll(6, timestamp)
		if repeat_session.phase() != Session.PHASE_BOSS_FINISHED:
			repeat_session.acknowledge_boss_round()
	_expect(repeat_session.next_lap() and repeat_session.enter_boss(700), "repeat intro fixture reaches the lap-two boss")
	var repeat_host := Control.new(); repeat_host.size = Vector2(720, 1280); root.add_child(repeat_host)
	var repeat_screen: Control = ScreenScene.instantiate(); repeat_host.add_child(repeat_screen)
	await process_frame; await process_frame
	repeat_screen.set("_session", repeat_session)
	repeat_screen.set("_boss_intro_active", false)
	repeat_screen.set("_boss_intro_complete", false)
	repeat_screen.call("_show_boss_overlay")
	repeat_screen.call("_refresh_ui")
	repeat_screen.call("_present_session_phase")
	await process_frame
	_expect(not (repeat_screen.get_node("%BossStartRulePanel") as Control).visible and (repeat_screen.get_node("%BossQuickRulePanel") as Control).visible and (repeat_screen.get_node("%DieButton") as Button).disabled, "lap two uses the short opposite-face reminder while preserving intro input gating")
	repeat_host.queue_free(); await process_frame
	host.queue_free(); await process_frame
	var capture_path := OS.get_environment("DICE_QA_V06_BOSS_CAPTURE_PATH")
	if not capture_path.is_empty():
		await _capture_boss_runtime(capture_path)


func _capture_boss_runtime(path: String) -> void:
	var scenario := OS.get_environment("DICE_QA_V06_BOSS_CAPTURE_SCENARIO")
	if scenario.is_empty():
		scenario = "boss_ready"
	OS.set_environment("DICE_QA_V06_SCENARIO", "boss_ready" if scenario == "boss_aim" else scenario)
	var capture_size := Vector2i(720, 1280)
	if OS.get_environment("DICE_QA_V06_BOSS_CAPTURE_SIZE") == "360x640":
		capture_size = Vector2i(360, 640)
	var viewport := SubViewport.new()
	viewport.size = capture_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var host := Control.new()
	host.size = Vector2(capture_size)
	viewport.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	if scenario == "boss_aim":
		await create_timer(1.2).timeout
		if bool(screen.get("_boss_intro_active")):
			screen.set("_boss_intro_active", false)
			screen.set("_boss_intro_complete", true)
		screen.call("_start_roll")
		await create_timer(0.35).timeout
	elif scenario == "boss_round":
		await create_timer(2.6).timeout
	else:
		for ignored: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	var capture := viewport.get_texture().get_image()
	var result := capture.save_png(path)
	_expect(capture.get_size() == capture_size and result == OK, "native boss capture is deterministic %dx%d" % [capture_size.x, capture_size.y])
	print("V06_BOSS_CAPTURE path=%s size=%s result=%s" % [path, capture.get_size(), result])
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	viewport.queue_free()
	await process_frame


func _win_mirror_race(session: RefCounted, start_ms: int, duration_ms: int) -> int:
	var now := start_ms
	for index: int in range(1, 5):
		now = start_ms + roundi(float(duration_ms) * float(index) / 4.0)
		session.start_roll(6, now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	session.acknowledge_boss_round()
	return now


func _expect(condition: bool, label: String) -> void:
	if condition: print("PASS %s" % label)
	else: failures += 1; push_error("FAIL %s" % label)
