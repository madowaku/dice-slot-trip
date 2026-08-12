extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const ScreenScript = preload("res://scripts/app/v06_play_screen.gd")
const AtlasScript = preload("res://scripts/game/v06_atlas_view.gd")
const DiceScript = preload("res://scripts/game/dice_presentation_3d.gd")
const SessionScript = preload("res://scripts/game/v06_play_session.gd")
const SaveManagerScript = preload("res://scripts/game/v06_session_save_manager.gd")
const CourseScript = preload("res://scripts/game/v06_course_model.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	_test_dice_roll_pacing_contract()
	var host := Control.new()
	host.size = UiTokensScript.BASE_VIEWPORT
	root.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	_test_named_structure(screen)
	await _test_hud_copy_contract(screen)
	_test_layout_and_touch(screen)
	_test_atlas_contract(screen)
	_test_card_route_label_contract(screen)
	await _test_straight_travel_contract(screen)
	await _test_bypass_step_travel_contract(screen)
	await _test_loop_portal_transfer_contract(screen)
	_test_map_contract(screen)
	await _test_straight_roll_sequence(screen)
	await _test_inline_slot_result_flow(screen)
	_test_bossless_run_over_ui(screen)
	await _test_rolling_tool_cancel(screen)
	await _test_compact_die_motion(screen)
	host.queue_free()
	await process_frame
	OS.set_environment("DICE_QA_V06_SCENARIO", "atlas_18")
	var qa_viewport := SubViewport.new()
	qa_viewport.size = Vector2i(UiTokensScript.BASE_VIEWPORT)
	qa_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(qa_viewport)
	var qa_host := Control.new()
	qa_host.size = UiTokensScript.BASE_VIEWPORT
	qa_viewport.add_child(qa_host)
	var qa_screen: Control = ScreenScene.instantiate()
	qa_host.add_child(qa_screen)
	await process_frame
	await process_frame
	_test_qa_state(qa_screen)
	var capture_path := OS.get_environment("DICE_QA_V06_CAPTURE_PATH")
	if not capture_path.is_empty():
		if OS.get_environment("DICE_QA_V06_BYPASS_CAPTURE") == "1":
			(qa_screen.get_node("%AtlasView") as Control).set_route_position({"route_id":CourseScript.ROUTE_BYPASS,"tile_index":0}, true)
		if OS.get_environment("DICE_QA_V06_KIND_PREVIEW") == "1":
			(qa_screen.get_node("%AtlasView") as Control).set_kind_preview_override(PackedStringArray(["NORMAL", "COIN", "REST", "RISK", "ITEM", "EVENT"]))
		match OS.get_environment("DICE_QA_V06_UTILITY_CAPTURE"):
			"item": qa_screen.call("_on_item_tool_pressed")
			"skill": qa_screen.call("_on_skill_tool_pressed")
		if OS.get_environment("DICE_QA_V06_MAP_CAPTURE") == "1":
			qa_screen.call("_on_map_pressed")
			var map_route := OS.get_environment("DICE_QA_V06_MAP_ROUTE")
			if not map_route.is_empty():
				var map_tile := OS.get_environment("DICE_QA_V06_MAP_TILE").to_int()
				(qa_screen.get_node("%OverviewAtlasView") as Control).set_route_position({"route_id":map_route, "tile_index":map_tile}, true)
		var die_capture_state := OS.get_environment("DICE_QA_DIE_QUATERNION_CAPTURE")
		var qa_die := qa_screen.get_node("%DicePresentation")
		var qa_die_values: Array[int] = [1]
		if die_capture_state == "ROLLING":
			qa_die.present(qa_die_values, true, 0)
			qa_die._process(0.31)
		elif die_capture_state == "LOCKED":
			qa_die_values[0] = 6
			qa_die.present(qa_die_values, false, 1)
			qa_die._process(0.0)
		var result_lock_face := OS.get_environment("DICE_QA_V06_RESULT_LOCK_FACE").to_int()
		if result_lock_face in range(1, 7):
			(qa_screen.get_node("%AtlasView") as Control).set_roll_preview(result_lock_face)
			await create_timer(AtlasScript.STRAIGHT_TARGET_PREVIEW_SECONDS + 0.02).timeout
		var inline_role_capture := OS.get_environment("DICE_QA_V06_INLINE_ROLE_CAPTURE")
		if not inline_role_capture.is_empty():
			var inline_session: RefCounted = qa_screen.session_for_test()
			inline_session.restart()
			match inline_role_capture:
				"PAIR", "TRIPLE":
					qa_screen.call("_qa_resolve_roll", 6)
					qa_screen.call("_qa_resolve_roll", 6)
				"STRAIGHT":
					qa_screen.call("_qa_resolve_roll", 1)
					qa_screen.call("_qa_resolve_roll", 2)
				_:
					qa_screen.call("_qa_resolve_roll", 4)
					qa_screen.call("_qa_resolve_roll", 1)
			(qa_screen.get_node("%AtlasView") as Control).set_route_position(inline_session.position(), true)
			qa_screen.call("_refresh_ui")
			var final_face := 6
			if inline_role_capture == "PAIR":
				final_face = 4
			elif inline_role_capture == "STRAIGHT":
				final_face = 3
			qa_screen.call("_run_face", final_face)
			var inline_capture_delay := OS.get_environment("DICE_QA_V06_INLINE_CAPTURE_DELAY").to_float()
			if inline_capture_delay <= 0.0:
				inline_capture_delay = 0.38
			await create_timer(inline_capture_delay).timeout
		else:
			await create_timer(1.02).timeout
		for ignored: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		RenderingServer.force_sync()
		var capture := qa_viewport.get_texture().get_image()
		var capture_result := capture.save_png(capture_path)
		_expect(capture.get_size() == Vector2i(720, 1280) and capture_result == OK, "native QA capture is deterministic 720x1280")
		var capture_360_path := OS.get_environment("DICE_QA_V06_CAPTURE_360_PATH")
		if not capture_360_path.is_empty():
			var capture_360 := capture.duplicate()
			capture_360.resize(360, 640, Image.INTERPOLATE_LANCZOS)
			_expect(capture_360.save_png(capture_360_path) == OK, "QA capture saves a Lanczos 360x640 derivative")
		print("V06_PLAY_SCREEN_CAPTURE path=%s size=%s result=%s" % [capture_path, capture.get_size(), capture_result])
		if not OS.get_environment("DICE_QA_V06_UTILITY_CAPTURE").is_empty():
			qa_screen.call("_on_utility_closed")
		if not inline_role_capture.is_empty():
			qa_screen.call("_cancel_motion", qa_screen.session_for_test().position())
			qa_screen.session_for_test().restart()
			(qa_screen.get_node("%AtlasView") as Control).set_route_position(qa_screen.session_for_test().position(), true)
			qa_screen.call("_refresh_ui")
	await _test_third_slot_boss_overlay_order(qa_screen)
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	qa_viewport.queue_free()
	await process_frame
	_test_stage_select_source_contract()
	_test_v06_save_source_contract()
	await _test_v06_resume_runtime()
	await _test_v06_resume_failure_preserves_save()
	print("V06_PLAY_SCREEN_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_dice_roll_pacing_contract() -> void:
	var elapsed := 1.0
	var normal_elapsed: float = ScreenScript.scaled_dice_roll_elapsed(elapsed, false)
	var boss_elapsed: float = ScreenScript.scaled_dice_roll_elapsed(elapsed, true)
	var boss_lap_three_elapsed: float = ScreenScript.scaled_dice_roll_elapsed(elapsed, true, 3)
	var normal_face_seconds := DiceScript.ROLL_FACE_STEP_SECONDS / ScreenScript.NORMAL_DICE_ROLL_SPEED_SCALE
	var boss_face_seconds := DiceScript.ROLL_FACE_STEP_SECONDS / ScreenScript.BOSS_DICE_ROLL_SPEED_SCALE
	_expect(normal_elapsed < elapsed and boss_elapsed > elapsed, "normal dice turns slightly slower while the boss-race die turns slightly faster")
	_expect(normal_face_seconds > DiceScript.ROLL_FACE_STEP_SECONDS and boss_face_seconds < DiceScript.ROLL_FACE_STEP_SECONDS and normal_face_seconds < 0.14 and boss_face_seconds > 0.10, "both dice pace changes stay subtle and readable")
	_expect(boss_lap_three_elapsed > boss_elapsed and ScreenScript.boss_dice_speed_scale_for_lap(99) == ScreenScript.BOSS_DICE_MAX_SPEED_SCALE, "boss die accelerates a little each lap and stops at its readability cap")
	var close_roulette_step: float = ScreenScript.heart_roulette_step_seconds_for_margin(1)
	var wide_roulette_step: float = ScreenScript.heart_roulette_step_seconds_for_margin(10)
	_expect(close_roulette_step < wide_roulette_step and is_equal_approx(wide_roulette_step, ScreenScript.HEART_ROULETTE_SLOW_STEP_SECONDS), "heart roulette spins faster after a close win and slows down for a wide lead")


func _test_hud_copy_contract(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	var message := screen.get_node("%MessageLabel") as Label
	var role := screen.get_node("%RoleLabel") as Label
	var status := screen.get_node("%TrayStatusLabel") as Label
	var hint := screen.get_node("%TrayHintLabel") as Label
	var action := screen.get_node("%ActionHintLabel") as Label
	var next_need := screen.get_node("%NextNeedLabel") as Label
	_expect(session.phase() == SessionScript.PHASE_READY and message.visible and message.text == "サイコロを振ろう" and (screen.get_node("%MessageBand") as Control).visible and not role.visible and not status.visible and status.text.is_empty() and not hint.visible and not action.visible and not next_need.visible, "ready HUD keeps one permanent operation message band without a redundant remaining-roll header")
	_expect((screen.get_node("%ProgressLabel") as Label).get_theme_font_size("font_size") >= 46 and (screen.get_node("%ScoreLabel") as Label).get_theme_font_size("font_size") >= 34, "current position and score receive real-device numeric priority")
	var landing_prompt := screen.get_node("%LandingArtPrompt") as Button
	var landing_art := screen.get_node("%LandingArt") as TextureRect
	var landing_thumb := screen.get_node("%LandingDiscoveryThumb") as TextureRect
	_expect(landing_prompt.text.contains("タップ") and landing_prompt.custom_minimum_size.y >= UiTokensScript.TOUCH_MIN and landing_art.custom_minimum_size.x >= 570.0 and not landing_thumb.visible, "shared journey card uses one wide image and an explicit touch-sized continue button")
	var onboarding_session: RefCounted = screen.session_for_test()
	_expect(screen.call("_open_three_roll_onboarding_if_eligible"), "untouched journey opens the three-roll onboarding")
	_expect(bool(screen.get("_three_roll_onboarding_open")) and landing_art.texture.resource_path.ends_with("slot-tray-luxury-v1.png"), "onboarding uses the shared overlay and luxury slot tray art")
	var onboarding_copy := (screen.get_node("%LandingArtCaption") as Label).text
	_expect((screen.get_node("%LandingArtTitle") as Label).text == "振って止めて、3投で役をつくる" and onboarding_copy.contains("1マス = 1ポイント") and onboarding_copy.contains("PAIR：同じ数字が2つ → SKILL +1") and onboarding_copy.contains("STRAIGHT：連続した3つ → SKILL +2") and onboarding_copy.contains("TRIPLE：同じ数字が3つ → SKILL READY") and onboarding_copy.contains("MIX：そのほか → COIN +1") and onboarding_copy.contains("盾・加速・必殺") and landing_prompt.text == "わかった！ 旅を始める", "onboarding explains distance scoring and every slot effect on both maps and boss races")
	var elapsed_before: int = int(onboarding_session.elapsed_ms(Time.get_ticks_msec()))
	screen.call("_on_landing_art_gui_input", InputEventMouseButton.new())
	screen.call("_request_back")
	screen.call("_on_die_pressed")
	_expect(bool(screen.get("_three_roll_onboarding_open")) and not bool(screen.get("_rolling")) and onboarding_session.elapsed_ms(Time.get_ticks_msec()) == elapsed_before, "background, back, and die input neither dismiss nor leak through the onboarding")
	landing_prompt.pressed.emit()
	_expect(not bool(screen.get("_three_roll_onboarding_open")) and onboarding_session.has_seen_three_roll_onboarding() and not screen.call("_open_three_roll_onboarding_if_eligible"), "only the CTA dismisses and the seen journey does not reopen")
	var reach_values: Array[int] = [2, 3]
	var normal_reach: Dictionary = screen.call("_normal_slot_reach", reach_values)
	screen.call("_show_slot_reach_cue", normal_reach)
	await process_frame
	_expect(message.visible and message.text.contains("STRAIGHTリーチ！") and message.get_theme_font_size("font_size") >= 27 and not message.get_global_rect().intersects((screen.get_node("%TrayPanel") as Control).get_global_rect()), "normal-map reach copy uses the existing message band between map and slot frame")
	screen.set("_slot_reach_message_active", false)
	screen.call("_refresh_ui")
	screen.call("_show_low_hp_warning", -1)
	await process_frame
	var low_hp_copy := (screen.get_node("%LowHpCaption") as Label).text
	_expect((screen.get_node("%LowHpOverlay") as Control).visible and low_hp_copy.contains("RESTマス") and low_hp_copy.contains("旅人の水筒") and low_hp_copy.contains("復活を1回") and not low_hp_copy.contains("コイン5枚"), "one-heart warning clearly explains HP recovery and separate LIFE revival")
	(screen.get_node("%LowHpCloseButton") as Button).pressed.emit()
	await process_frame
	_expect(not (screen.get_node("%LowHpOverlay") as Control).visible and not bool(screen.get("_low_hp_warning_open")), "one-heart warning closes only through its confirmation action")
	screen.call("_present_move_announcement", 4, int(screen.get("_motion_generation")))
	_expect(message.visible and message.text == "4マス進む！" and message.get_theme_font_size("font_size") >= 40, "move announcement uses actual distance and large text")
	screen.call("_present_move_announcement", 9, int(screen.get("_motion_generation")), 5)
	_expect(message.text == "5＋4＝9マス進む！", "boosted movement visibly explains the die and support total")
	await create_timer(1.05).timeout
	_expect(message.visible and message.text == "サイコロを振ろう", "move announcement restores the permanent ready guidance after one second")
	var role_reward := screen.get_node("%RoleRewardLabel") as Label
	var tray := screen.get_node("%TrayPanel") as Control
	var slots_row := screen.get_node("SafeMargin/Page/TrayPanel/TrayContent/RollRow/SlotColumn/SlotLayout/SlotsRow") as Control
	var slots_before := slots_row.get_global_rect()
	screen.call("_play_inline_slot_result", "PAIR", 4, int(screen.get("_motion_generation")))
	await process_frame
	screen.call("_refresh_ui")
	_expect(role.visible and role.text == "PAIR！" and role_reward.visible, "inline role copy survives a phase refresh")
	var role_rect := role.get_global_rect()
	var reward_rect := role_reward.get_global_rect()
	var slots_rect := slots_row.get_global_rect()
	var status_rect := status.get_global_rect()
	_expect(role.visible and role_reward.visible and not status.visible, "inline role and reward are visible while the slot header stays hidden")
	var first_slot_rect := (screen.get_node("%SlotPanel0") as Control).get_global_rect()
	_expect(role_rect.end.y <= first_slot_rect.position.y + 1.0 and reward_rect.position.y >= first_slot_rect.end.y - 1.0 and not role_rect.intersects(first_slot_rect) and not reward_rect.intersects(first_slot_rect), "inline role title, slot numbers, and reward use three non-overlapping rows")
	_expect(not role_rect.intersects(status_rect) and not reward_rect.intersects(status_rect) and role_rect.end.y <= tray.get_global_rect().end.y + 1.0 and reward_rect.end.y <= tray.get_global_rect().end.y + 1.0, "inline role copy stays inside the tray below its hidden header")
	screen.call("_reset_inline_slot_result")
	await process_frame
	_expect(not role.visible and not role_reward.visible and not status.visible and not role.is_visible_in_tree() and not role_reward.is_visible_in_tree(), "inline role reward clears without restoring the redundant slot status")
	var slots_after := slots_row.get_global_rect()
	_expect(slots_after.position.distance_to(slots_before.position) <= 1.0 and slots_after.size.distance_to(slots_before.size) <= 1.0, "reset restores the normal slot-row layout")


func _test_named_structure(screen: Control) -> void:
	for node_name: String in [
		"LapLabel", "SurvivalStack", "HPLabel", "LifeBox", "LifeIcon", "LifeLabel", "PBLabel", "TimeLabel", "ScoreLabel", "ScoreDeltaLabel", "BestLabel", "CoinLabel", "ProgressLabel", "StageLabel", "MessageBand", "MessageLabel",
		"RouteLabel", "TileKindLabel", "AtlasView", "TrayPanel", "MapButton", "MapOverlay", "MapFrameArt", "OverviewAtlasView", "MapCloseButton", "BranchChoiceAtlasView", "ChoiceRollLabel", "Slot0",
		"Slot1", "Slot2", "DicePresentation", "DieButton", "ChoiceOverlay", "ResolutionOverlay",
		"RollCountLabel", "RollButtonDieIcon", "RollButtonCopy", "RoleLabel", "RoleRewardLabel", "PairLink", "NextNeedLabel", "ActionHintLabel",
		"BossOverlay", "ToolDock", "ItemToolButton", "SkillToolButton", "UtilityOverlay", "UtilityCardArt", "UtilityCloseButton", "BackButton",
		"LowHpOverlay", "LowHpPanel", "LowHpTitle", "LowHpCaption", "LowHpCloseButton",
		"TravelMenuOverlay", "TravelMenuPanel", "TravelMenuTitle", "TravelMenuContinueButton", "TravelMenuExitButton",
	]:
		_expect(screen.get_node_or_null("%%%s" % node_name) != null, "named node %s exists" % node_name)
	var slots: Array[Node] = []
	for node_name: String in ["Slot0", "Slot1", "Slot2"]:
		slots.append(screen.get_node("%%%s" % node_name))
	_expect(slots.size() == 3, "fixed tray exposes exactly three slots")
	var grouped_dice := get_nodes_in_group("v06_die")
	var die_buttons := screen.find_children("*Die*", "Button", true, false)
	_expect(grouped_dice.size() == 1 and die_buttons.size() == 1 and grouped_dice[0].name == "DieButton", "screen exposes exactly one roll action")
	var dice_receipt: Dictionary = screen.get_node("%DicePresentation").pool_receipt()
	var hero_die := screen.get_node("%DieHeroArt") as TextureRect
	_expect(dice_receipt.active_count == 1 and dice_receipt.viewport_size.x >= 96 and dice_receipt.viewport_size.x == dice_receipt.viewport_size.y and not hero_die.visible and (screen.get_node("%DicePresentation") as Control).visible, "normal map presents one rotating 3D die without the duplicate antique overlay")
	_expect((screen.get_node("%ScoreLabel") as Label).text == "0" and (screen.get_node("%CoinLabel") as Label).text == "0" and (screen.get_node("%HPLabel") as Label).text == "♥♥♥" and (screen.get_node("%LifeLabel") as Label).text == "復活 ×3", "normal travel HUD separates HP from three revival stocks")
	var life_icon := screen.get_node("%LifeIcon") as TextureRect
	var life_atlas := life_icon.texture as AtlasTexture
	_expect(life_atlas != null and life_atlas.region == Rect2(0, 0, 192, 192) and life_icon.custom_minimum_size.x >= 32.0 and life_icon.custom_minimum_size.x <= 36.0, "LIFE HUD reuses the first explorer-cat frame at compact icon size")
	var survival_stack := screen.get_node("%SurvivalStack") as VBoxContainer
	var life_box := screen.get_node("%LifeBox") as Control
	var hp_label := screen.get_node("%HPLabel") as Label
	var hud_row2 := survival_stack.get_parent() as Control
	var hud_panel := screen.get_node("%HudPanel") as Control
	_expect(life_box.get_parent() == survival_stack and hp_label.get_parent() == survival_stack and survival_stack.get_child(0) == life_box and survival_stack.get_child(1) == hp_label and life_box.get_global_rect().end.y <= hp_label.get_global_rect().position.y + 1.0, "SurvivalStack keeps LIFE first and HP immediately below it")
	_expect(hud_row2.name == "HudRow2" and hud_row2.get_global_rect().encloses(survival_stack.get_global_rect()) and hud_panel.get_global_rect().encloses(life_box.get_global_rect()) and hud_panel.get_global_rect().encloses(hp_label.get_global_rect()), "720 logical HUD contains the vertical survival stack inside HudRow2")
	_expect(is_equal_approx(hud_panel.custom_minimum_size.y, 104.0) and (screen.get_node("%AtlasView") as Control).size.y >= 450.0, "vertical survival HUD preserves fixed104px contract and the playfield")
	_expect(ScreenScript.revival_stamp_text(2) == "復活！　復活 ×2　HP FULL", "revival uses one short nonmodal HP/LIFE stamp")
	_expect(ScreenScript.lap_life_stamp_text(10, 2, 3) == "10 LAP BONUS　復活 +1" and ScreenScript.lap_life_stamp_text(20, 3, 3) == "20 LAP達成　復活 FULL", "10-lap stamps distinguish LIFE gain from capped milestone with no extra reward")
	_expect(screen.get_node_or_null("%EmergencyReviveButton") == null and not FileAccess.get_file_as_string("res://scripts/app/v06_play_screen.gd").contains("_on_emergency_revive_pressed"), "obsolete coin emergency-revive button and callback are removed from UI")
	_expect((screen.get_node("%LapLabel") as Label).visible and (screen.get_node("%LapLabel") as Label).text == "1" and not (screen.get_node("%LapLabel") as Label).text.contains("/") and not (screen.get_node("%PBLabel") as Label).visible and not (screen.get_node("%TimeLabel") as Label).is_visible_in_tree() and (screen.get_node("%ProgressLabel") as Label).text == "1/90", "two-row HUD shows value-only lap and hides PB and TIME while keeping 90-route progress")
	_expect((screen.get_node("%BestLabel") as Label).text == screen.call("_format_score", int(screen.session_for_test().best_score())), "BEST is formatted from the session best score")
	_expect((screen.get_node("%MapButton") as Button).text == "全体マップ" and (screen.get_node("%MapButton") as Button).custom_minimum_size.x >= 72.0 and (screen.get_node("%MapButton") as Button).custom_minimum_size.y >= 96.0 and (screen.get_node("%MapFrameArt") as TextureRect).texture.resource_path == "res://assets/art/ui/common/map-panel-frame-v1.png", "map action uses the requested copy, touch contract, and generated frame")
	_expect((screen.get_node("%Slot0") as Label).text == "—" and (screen.get_node("%Slot2") as Label).text == "—", "initial slots are blank")
	_expect((screen.get_node("%DieButton") as Button).text == "振る", "the right-side roll action starts ready")
	_expect((screen.get_node("%RollButtonCopy") as Label).text == "振る" and (screen.get_node("%RollButtonDieIcon") as TextureRect).visible, "round roll action carries the reference dice-over-copy composition")
	_expect((screen.get_node("%ItemToolButton") as Button).text.contains("0 / 3") and (screen.get_node("%SkillToolButton") as Button).text == "スキル\n0/3", "bottom tool dock keeps the skill label compact because its detail lives inside the book")


func _test_layout_and_touch(screen: Control) -> void:
	_expect(screen.size == UiTokensScript.BASE_VIEWPORT, "root resolves to the 720x1280 design viewport")
	var page := screen.get_node("%Page") as Control
	var safe_margin := page.get_parent() as Control
	var needed := page.get_combined_minimum_size()
	var safe_margin_rect := safe_margin.get_global_rect()
	var screen_bounds := screen.get_global_rect()
	var safe_left := safe_margin_rect.position.x - screen_bounds.position.x
	var safe_top := safe_margin_rect.position.y - screen_bounds.position.y
	var safe_right := screen_bounds.end.x - safe_margin_rect.end.x
	var safe_bottom := screen_bounds.end.y - safe_margin_rect.end.y
	var inset_epsilon := 0.001
	_expect(safe_left >= 15.5 - inset_epsilon and safe_left <= 16.5 + inset_epsilon and safe_top >= 15.5 - inset_epsilon and safe_top <= 16.5 + inset_epsilon and safe_right >= 15.5 - inset_epsilon and safe_right <= 16.5 + inset_epsilon and safe_bottom >= 15.5 - inset_epsilon and safe_bottom <= 16.5 + inset_epsilon and absf(safe_left - safe_right) <= 0.5 and absf(safe_top - safe_bottom) <= 0.5 and screen_bounds.encloses(safe_margin_rect), "compact profile keeps balanced 16px screen-relative safe insets inside the viewport")
	_expect(page.position.distance_to(Vector2.ZERO) <= 0.5 and page.size.distance_to(safe_margin.size) <= 0.5 and page.global_position.distance_to(safe_margin.global_position) <= 0.5 and page.get_global_rect().size.distance_to(safe_margin.get_global_rect().size) <= 0.5, "compact page exactly fills its safe margin relative to the fixture origin")
	_expect(needed.x <= safe_margin.size.x + 1.0 and needed.y <= safe_margin.size.y + 1.0, "root content fits 720x1280 without clipping")
	var touch_ok := true
	for node: Node in screen.find_children("*", "Button", true, false):
		var button := node as Button
		touch_ok = touch_ok and button.custom_minimum_size.y >= UiTokensScript.TOUCH_MIN
	_expect(touch_ok, "every screen and overlay button meets the touch minimum")
	var atlas := screen.get_node("%AtlasView") as Control
	_expect(atlas.custom_minimum_size.y >= 470.0 and atlas.size.y >= 470.0, "compact profile preserves at least 470px of actual and minimum atlas height")
	var message_band := screen.get_node("%MessageBand") as Control
	var tray_panel := screen.get_node("%TrayPanel") as Control
	var hud_panel := screen.get_node("%HudPanel") as Control
	var stage_band := screen.get_node("%StageBand") as Control
	var mission_band := screen.get_node("%MissionBand") as Control
	_expect(hud_panel.get_global_rect().end.y <= stage_band.get_global_rect().position.y + 1.0 and stage_band.get_global_rect().end.y <= mission_band.get_global_rect().position.y + 1.0 and mission_band.get_global_rect().end.y <= atlas.get_global_rect().position.y + 1.0, "HUD rows remain ordered without overlap above the unchanged atlas")
	_expect(is_equal_approx(message_band.custom_minimum_size.y, 62.0) and (page as VBoxContainer).get_theme_constant("separation") == 0, "compact 16:9 profile uses zero decorative gaps and the approved 62px operation band")
	var primary_buttons_ok := true
	for button_path: String in ["%DieButton", "%ItemToolButton", "%SkillToolButton", "%BackButton"]:
		var primary_button := screen.get_node(button_path) as Button
		primary_buttons_ok = primary_buttons_ok and primary_button.visible and primary_button.custom_minimum_size.y >= 96.0 and primary_button.size.y >= 96.0
	_expect(primary_buttons_ok, "visible die, item, skill, and back controls preserve 96px actual and minimum height")
	_expect(message_band.get_parent() == screen.get_node("%Page") and message_band.get_global_rect().position.y >= atlas.get_global_rect().end.y - 1.0 and message_band.get_global_rect().end.y <= tray_panel.get_global_rect().position.y + 1.0, "operation message band owns a fixed row between map and controls")
	var first_slot := screen.get_node("%SlotPanel0") as Control
	var last_slot := screen.get_node("%SlotPanel2") as Control
	var die := screen.get_node("%DieButton") as Control
	var map_die := screen.get_node("%DicePresentation") as Control
	var tray := screen.get_node("%TrayPanel") as Control
	var atlas_rect := atlas.get_global_rect()
	var die_rect := map_die.get_global_rect()
	var safe_rect := Rect2(atlas_rect.position + Vector2(atlas_rect.size.x * 0.32, atlas_rect.size.y * 0.62), Vector2(atlas_rect.size.x * 0.36, atlas_rect.size.y * 0.36))
	map_die.scale = Vector2.ONE * 1.08
	var rolling_die_rect := map_die.get_global_rect()
	map_die.scale = Vector2.ONE
	_expect(map_die.get_parent() == atlas and atlas_rect.encloses(die_rect) and safe_rect.encloses(die_rect) and atlas_rect.encloses(rolling_die_rect), "the rotating 3D die stays inside the lower map safety zone while rolling")
	var slot_art := screen.get_node("%SlotTrayArt") as Control
	_expect((screen.get_node("%SlotTrayArt") as TextureRect).texture.resource_path == "res://assets/art/ui/common/slot-tray-luxury-v1.png", "normal tray uses the generated luxury slot-machine frame")
	var slot_centers := [first_slot.get_global_rect().get_center(), (screen.get_node("%SlotPanel1") as Control).get_global_rect().get_center(), last_slot.get_global_rect().get_center()]
	var art_rect := slot_art.get_global_rect()
	_expect(first_slot.get_global_rect().end.x <= die.get_global_rect().position.x and last_slot.get_global_rect().end.x <= die.get_global_rect().position.x, "slots stay left of the right-side roll action")
	_expect(absf(die.size.x - die.size.y) <= 1.0 and die.size.x >= 180.0 and bool(die.call("_has_point", die.size * 0.5)) and not bool(die.call("_has_point", Vector2.ZERO)), "normal roll action is a large circular hit target")
	_expect(slot_centers[0].x < slot_centers[1].x and slot_centers[1].x < slot_centers[2].x and art_rect.encloses(first_slot.get_global_rect()) and art_rect.encloses(last_slot.get_global_rect()), "three slot labels align inside the decorative reel windows")
	_expect(ScreenScript.SLOT_BREATH_ALPHA_AMPLITUDE <= 0.06 and ScreenScript.SLOT_BREATH_PERIOD_SECONDS >= 1.6, "unconfirmed slot glow is a slow low-amplitude breath")
	_expect((screen.get_node("%MapButton") as Button).custom_minimum_size.x >= 72 and (screen.get_node("%MapButton") as Button).custom_minimum_size.y >= 96, "top-right MAP control is a large one-hand target")
	_expect((screen.get_node("%NextNeedLabel") as Label).visible == false and (screen.get_node("%ActionHintLabel") as Label).visible == false and (screen.get_node("%TrayHintLabel") as Label).visible == false, "small slot explanations stay out of the primary tray")
	_expect((screen.get_node("%SlotPanel0") as Control).size.y >= 88 and (screen.get_node("%Slot0") as Label).get_theme_font_size("font_size") >= 48 and (screen.get_node("%Slot0") as Label).get_theme_font("font").resource_path == "res://assets/fonts/cinzel/Cinzel-Variable.ttf" and (screen.get_node("%BackButton") as Button).text.contains("メニュー"), "slot values use a high-contrast decorative Cinzel face and stage exit lives behind the menu")
	var tool_dock := screen.get_node("%ToolDock") as Control
	_expect(tool_dock.get_global_rect().position.y >= tray.get_global_rect().end.y and (screen.get_node("%AtlasView") as Control).size.y >= 450.0, "item and skill dock sits below the raised tray without shrinking the playfield below contract")
	_expect((screen.get_node("%ItemToolButton") as Button).icon.resource_path == "res://assets/art/v08/cards/item-card.png" and (screen.get_node("%SkillToolButton") as Button).icon.resource_path == "res://assets/art/ui/common/skill-book-v1.png" and (screen.get_node("%BackButton") as Button).icon.resource_path == "res://assets/art/ui/common/menu-gear-v1.png", "tool buttons use the item card, generated skill book, and generated menu gear")
	_test_utility_cards(screen)


func _test_utility_cards(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	var overlay := screen.get_node("%UtilityOverlay") as Control
	var message_band := screen.get_node("%MessageBand") as Control
	var message_label := screen.get_node("%MessageLabel") as Label
	screen.call("_on_item_tool_pressed")
	_expect(overlay.visible and not message_band.visible and not message_label.visible and (screen.get_node("%DieButton") as Button).disabled and (screen.get_node("%UtilityTitle") as Label).text == "旅のアイテム" and (screen.get_node("%UtilityDetail") as Label).text.contains("0 / 3") and (screen.get_node("%UtilityActionButton") as Button).disabled, "ITEM button opens its functional empty-bag card, hides operation copy, and gates gameplay input")
	screen.call("_show_operation_message", "UTILITY DIRECT MESSAGE", 0.0, 26)
	_expect(message_label.text == "UTILITY DIRECT MESSAGE" and not message_band.visible and not message_label.visible, "direct operation messages update their state but remain hidden behind an open utility")
	screen.call("_on_utility_closed")
	screen.call("_on_skill_tool_pressed")
	var face_grid := screen.get_node("%PinpointFaceRow") as GridContainer
	var face_buttons: Array[Node] = face_grid.get_children()
	var face_sizes_ok := face_buttons.size() == 6
	for button: Node in face_buttons:
		face_sizes_ok = face_sizes_ok and (button as Button).custom_minimum_size.x >= 96.0 and (button as Button).custom_minimum_size.y >= 96.0
	var utility_panel := screen.get_node("%UtilityPanel") as Control
	var close_button := screen.get_node("%UtilityCloseButton") as Control
	_expect(overlay.visible and not message_band.visible and not message_label.visible and (screen.get_node("%DieButton") as Button).disabled and (screen.get_node("%UtilityTitle") as Label).text == "次の出目を選ぶ" and face_grid.columns == 3 and face_grid.custom_minimum_size.y >= 192.0 and face_sizes_ok and utility_panel.get_global_rect().encloses(face_grid.get_global_rect()) and utility_panel.get_global_rect().encloses(close_button.get_global_rect()) and close_button.visible and close_button.custom_minimum_size.y >= 96.0 and (close_button as Button).focus_mode != Control.FOCUS_NONE and (screen.get_node("%UtilityCardArt") as TextureRect).texture.resource_path == "res://assets/art/ui/common/skill-pinpoint-v1.png" and (screen.get_node("%PinpointFace1") as Button).disabled, "SKILL opens a non-clipped 3x2 selector with six 96px-class face targets and one unobstructed close CTA")
	var screen_source := FileAccess.get_file_as_string("res://scripts/app/v06_play_screen.gd")
	_expect(screen_source.contains("次のサイコロ → %d") and screen_source.contains("_refresh_skill_utility()") and not screen_source.contains("_save_stable_checkpoint()\n\t_on_utility_closed()"), "arming a face shows the direct next-die result and leaves the overlay open for the explicit close CTA")
	screen.call("_on_utility_closed")
	_expect(not overlay.visible and not session.snapshot().clock_paused and not (screen.get_node("%DieButton") as Button).disabled and message_band.visible and message_label.visible and message_label.text == "サイコロを振ろう", "closing a utility card restores READY operation copy, gameplay input, and the run clock")
	var ready_state: Dictionary = session.stable_save_snapshot(0)
	ready_state.player.skill_gauge = 3
	ready_state.player.skill_state = "READY"
	_expect(session.restore_stable_snapshot(ready_state, 0), "skill discovery fixture restores READY")
	screen.call("_show_skill_ready_discovery_if_eligible", -1)
	_expect(overlay.visible == false and (screen.get_node("%LandingArtOverlay") as Control).visible and (screen.get_node("%LandingArtTitle") as Label).text == "SKILL READY!" and (screen.get_node("%LandingArtCaption") as Label).text == "次のサイコロの 出目を選べる！" and not session.has_seen_skill_ready_discovery(), "first READY discovery uses pinpoint art and remains unseen before its CTA")
	screen.call("_on_landing_art_prompt_pressed")
	_expect(session.has_seen_skill_ready_discovery() and not (screen.get_node("%LandingArtOverlay") as Control).visible, "skill discovery CTA alone marks durable seen state and closes the overlay")


func _test_atlas_contract(screen: Control) -> void:
	var atlas: Control = screen.get_node("%AtlasView")
	_expect(atlas.uses_semicircle_carousel() and atlas.carousel_cat_feet_anchor() == atlas.carousel_slot_position(0), "normal atlas uses a fixed-anchor semicircle carousel")
	_expect(atlas.carousel_moves_clockwise() and is_equal_approx(AtlasScript.HOP_SECONDS, 0.30), "carousel shifts clockwise with a calm 0.30-second hop")
	var edge_segments: Array[Dictionary] = atlas.carousel_main_edge_segments()
	_expect(edge_segments.size() == 2 and edge_segments[0].from.x < 0.0 and edge_segments[1].from.x < 0.0, "both open-left main-route endpoints continue beyond the local viewport")
	var original_position: Dictionary = atlas.current_route_position()
	_expect(atlas.set_route_position({"route_id": "main", "tile_index": 18}, true), "play-screen QA positions the atlas on the owner annotated frame for context checks")
	var context_positions: Array[Dictionary] = atlas.carousel_context_positions()
	_expect(context_positions.size() == 4 and context_positions[0].tile_index == 16 and context_positions[1].tile_index == 17 and context_positions[2].tile_index == 25 and context_positions[3].tile_index == 26, "play screen keeps two non-successor context tiles on each endpoint")
	_expect(atlas.prominent_space_count() == 6, "context tiles do not inflate the six-space forward horizon")
	atlas.set_route_position(original_position, true)
	_expect(atlas.uses_production_tile_kind_icons(), "play screen uses six preloaded normalized Kenney tile-kind glyphs")
	var prominent_count: int = atlas.prominent_space_count()
	_expect(prominent_count == 6, "atlas keeps exactly six forward spaces")
	var style_ids: PackedStringArray = atlas.route_style_ids()
	var unique_styles := {}
	for style_id: String in style_ids:
		unique_styles[style_id] = true
	_expect(style_ids.size() == 3 and unique_styles.size() == 3, "main, bypass, and loop expose distinct route style IDs")
	_expect(style_ids[0] == String(AtlasScript.ROUTE_STYLE_MAIN) and style_ids[1] == String(AtlasScript.ROUTE_STYLE_BYPASS) and style_ids[2] == String(AtlasScript.ROUTE_STYLE_LOOP), "route style IDs identify teal solid, rust dashed, and loop/gold exit")
	_expect(AtlasScript.CAMERA_FOLLOW_SECONDS >= 0.26 and AtlasScript.CAMERA_FOLLOW_SECONDS <= 0.34 and AtlasScript.HOP_SECONDS >= 0.28 and AtlasScript.HOP_SECONDS <= 0.34, "cat hop and camera follow use the low-stimulation motion interval")
	_expect(AtlasScript.CAT_TILE_SCALE >= 1.30 and AtlasScript.CAT_TILE_SCALE <= 1.50, "cat remains 1.3-1.5x the local tile focal scale")
	atlas.clear_roll_preview()
	_expect(not bool(atlas.roll_preview_receipt().active), "ROLLING state has no board highlight")
	atlas.set_roll_preview(4)
	await create_timer(AtlasScript.STRAIGHT_TARGET_PREVIEW_SECONDS + 0.02).timeout
	var locked_preview: Dictionary = atlas.roll_preview_receipt()
	_expect(bool(locked_preview.active) and int(locked_preview.distance) == 4 and str(locked_preview.target_key) == "main:4" and float(locked_preview.alpha) > 0.9, "RESULT_LOCK quietly highlights forward card four only")
	atlas.release_roll_preview()
	await create_timer(0.04).timeout
	var releasing_preview: Dictionary = atlas.roll_preview_receipt()
	_expect(bool(releasing_preview.active) and str(releasing_preview.target_key) == "main:4" and float(releasing_preview.alpha) < float(locked_preview.alpha), "highlight stays on the same card while fading at movement start")
	await create_timer(0.12).timeout
	_expect(not bool(atlas.roll_preview_receipt().active), "result-lock highlight clears after movement begins")


func _test_straight_travel_contract(screen: Control) -> void:
	var atlas := screen.get_node("%AtlasView") as V06AtlasView
	var original_position: Dictionary = atlas.current_route_position()
	var start_position := {"route_id": "main", "tile_index": 18}
	var target_position := {"route_id": "main", "tile_index": 20}
	_expect(atlas.can_use_straight_travel(start_position, 2) and not atlas.can_use_straight_travel({"route_id": "loop_oasis_ring", "tile_index": 0}, 2), "straight travel is limited to the main route")
	_expect(atlas.set_route_position(start_position, true) and atlas.begin_straight_travel(start_position, 2), "straight travel keeps a separate display window before stepping")
	var started_receipt: Dictionary = atlas.straight_travel_receipt()
	_expect(bool(started_receipt.active) and int(started_receipt.player_step) == 0 and is_zero_approx(float(started_receipt.camera_offset)), "straight travel starts with zero camera offset")
	_expect(int(atlas.card_route_receipt().card_count) == 7, "straight travel starts with seven visible cards")
	var frozen_labels := _position_label_map(atlas.card_route_receipt())
	_expect(frozen_labels.get("main:18") == "現在地" and frozen_labels.get("main:19") == "+1" and frozen_labels.get("main:24") == "+6", "straight travel freezes pre-roll labels on the actual path and true forward world cards")
	await atlas.animate_straight_step(1)
	var step_receipt: Dictionary = atlas.straight_travel_receipt()
	_expect(int(step_receipt.player_step) == 1 and is_zero_approx(float(step_receipt.camera_offset)), "cat step advances without camera follow")
	_expect(int(atlas.card_route_receipt().card_count) == 7 and atlas.cat_animation_state() == &"land", "each straight hop keeps seven cards and lands as a discrete jump")
	_expect(_position_label_map(atlas.card_route_receipt()) == frozen_labels and float(atlas.card_route_receipt().relative_steps[0]) < 0.0, "negative relative steps do not renumber frozen world-card labels")
	await atlas.animate_straight_step(2)
	await atlas.play_landing_effect(target_position)
	_expect(is_zero_approx(float(atlas.straight_travel_receipt().camera_follow_progress)), "landing effect completes before camera follow")
	_expect(_position_label_map(atlas.card_route_receipt()) == frozen_labels, "landing keeps the pre-roll world-card labels fixed")
	await atlas.animate_straight_camera_follow()
	var followed_receipt: Dictionary = atlas.straight_travel_receipt()
	_expect(is_equal_approx(float(followed_receipt.camera_follow_progress), 1.0) and float(followed_receipt.camera_offset) > 0.0, "camera follows only after the landing effect")
	_expect(int(atlas.card_route_receipt().card_count) == 7, "camera follow keeps seven visible cards")
	var followed_labels := _position_label_map(atlas.card_route_receipt())
	_expect(_shared_position_labels_match(frozen_labels, followed_labels), "camera follow preserves labels for every world card that remains visible")
	_expect(atlas.finish_straight_travel(target_position) and not atlas.straight_travel_active() and atlas.current_route_position() == target_position, "straight travel returns the cat to the base slot without a snap")
	_expect(int(atlas.card_route_receipt().card_count) == 7, "settled straight travel keeps seven visible cards")
	var settled_labels := _position_label_map(atlas.card_route_receipt())
	_expect(settled_labels.get("main:20") == "現在地" and settled_labels.get("main:21") == "+1" and frozen_labels.get("main:20") == "+2", "finish_straight_travel is the single boundary that relabels from pre-roll to settled distance")
	atlas.set_route_position(original_position, true)


func _test_card_route_label_contract(screen: Control) -> void:
	var atlas := screen.get_node("%AtlasView") as V06AtlasView
	var original_position: Dictionary = atlas.current_route_position()
	_expect(atlas.set_route_position({"route_id": "main", "tile_index": 18}, true), "settled label test starts on the main route")
	var main_labels := _position_label_map(atlas.card_route_receipt())
	_expect(main_labels.get("main:18") == "現在地" and main_labels.get("main:19") == "+1" and main_labels.get("main:24") == "+6", "settled main cards label current and six ordered true successors")
	_expect(atlas.set_route_position({"route_id": "bypass_bazaar_alley", "tile_index": 0}, true), "settled label test enters a bypass")
	var bypass_entries: Array = atlas.card_route_receipt().position_labels
	_expect(str(bypass_entries[0].display_label) == "現在地" and str(bypass_entries[1].display_label) == "+1" and str(bypass_entries[-1].display_label).begins_with("+"), "settled bypass cards continue ordered labels through their true rejoin successors")
	_expect(atlas.set_route_position({"route_id": "main", "tile_index": 88}, true), "terminal label test reaches the final approach")
	var terminal_entries: Array = atlas.card_route_receipt().position_labels
	var terminal_labels := _position_label_map(atlas.card_route_receipt())
	var dot_count := 0
	for entry: Dictionary in terminal_entries:
		if str(entry.display_label) == "·":
			dot_count += 1
	_expect(terminal_labels.get("main:88") == "現在地" and terminal_labels.get("main:89") == "+1" and dot_count >= 1, "terminal backfill cards use dots instead of claiming future distance")
	var original_size := atlas.size
	for test_size: Vector2 in [Vector2(360.0, 640.0), Vector2(720.0, 1280.0)]:
		atlas.size = test_size
		for entry: Dictionary in atlas.card_route_receipt().position_labels:
			_expect(float(entry.label_width) <= float(entry.card_width) - 3.0, "card route label fits its card at %dx%d" % [int(test_size.x), int(test_size.y)])
	atlas.size = original_size
	var atlas_source := FileAccess.get_file_as_string("res://scripts/game/v06_atlas_view.gd")
	_expect(not atlas_source.contains("var absolute_label := \"#%02d\""), "card route rendering no longer draws small absolute #NN labels")
	atlas.set_route_position(original_position, true)


func _position_label_map(receipt: Dictionary) -> Dictionary:
	var labels := {}
	for entry: Dictionary in receipt.get("position_labels", []):
		if not bool(entry.get("terminal_filler", false)):
			labels[str(entry.get("position_key", ""))] = str(entry.get("display_label", ""))
	return labels


func _shared_position_labels_match(first: Dictionary, second: Dictionary) -> bool:
	var shared_count := 0
	for position_key: String in first:
		if second.has(position_key):
			shared_count += 1
			if first[position_key] != second[position_key]:
				return false
	return shared_count > 0


func _test_bypass_step_travel_contract(screen: Control) -> void:
	var atlas := screen.get_node("%AtlasView") as V06AtlasView
	var original_position: Dictionary = atlas.current_route_position()
	var start_position := {"route_id": "bypass_bazaar_alley", "tile_index": 0}
	var path: Array[Dictionary] = [
		{"route_id": "bypass_bazaar_alley", "tile_index": 1},
		{"route_id": "bypass_bazaar_alley", "tile_index": 2},
	]
	_expect(atlas.set_route_position(start_position, true) and atlas.begin_step_travel(start_position, path), "main and bypass routes use the shared step travel window")
	_expect(int(atlas.straight_travel_receipt().player_step) == 0 and is_zero_approx(float(atlas.straight_travel_receipt().camera_offset)), "bypass step travel starts with the cat at the first card")
	await atlas.animate_straight_step(1)
	_expect(int(atlas.straight_travel_receipt().player_step) == 1 and is_zero_approx(float(atlas.straight_travel_receipt().camera_offset)), "bypass movement jumps the cat before camera follow")
	await atlas.animate_straight_step(2)
	await atlas.animate_straight_camera_follow()
	_expect(float(atlas.straight_travel_receipt().camera_offset) > 0.0 and atlas.finish_straight_travel(path[1]), "bypass travel follows the camera only after the final landing")
	atlas.set_route_position(original_position, true)


func _test_loop_portal_transfer_contract(screen: Control) -> void:
	var typed_screen := screen as V06PlayScreen
	var atlas := typed_screen.atlas_for_test()
	var original_position: Dictionary = atlas.current_route_position()
	var loop_position := {"route_id": "loop_oasis_ring", "tile_index": 0}
	var return_position := {"route_id": "main", "tile_index": 23}
	_expect(typed_screen.die_anchor_for_route("loop_oasis_ring").x > 0.80 and typed_screen.die_anchor_for_route("main") == ScreenScript.DICE_ANCHOR_NORMAL, "loop route moves the map die into the right-side clear area")
	_expect(atlas.set_route_position(loop_position, true), "portal transfer test starts on the oasis ring")
	await atlas.animate_portal_transfer_to(return_position)
	_expect(not atlas.portal_transfer_active() and atlas.current_route_position() == return_position, "loop exit completes a covered portal transition before revealing the main route")
	atlas.set_route_position(original_position, true)


func _test_straight_roll_sequence(screen: Control) -> void:
	var typed_screen := screen as V06PlayScreen
	var session: RefCounted = typed_screen.session_for_test()
	session.restart()
	typed_screen.call("_refresh_ui")
	await typed_screen._run_face(4)
	var atlas := typed_screen.atlas_for_test()
	_expect(session.position() == {"route_id": "main", "tile_index": 4} and session.phase() == SessionScript.PHASE_READY, "one straight roll commits the logical COIN destination after visual travel")
	_expect(not atlas.straight_travel_active() and atlas.current_route_position() == session.position() and not bool(typed_screen.get("_movement_active")), "next roll remains locked until camera follow has finished")
	_expect((typed_screen.get_node("%Slot0") as Label).text == "4" and not (typed_screen.get_node("%DieButton") as Button).disabled, "stopped face transfers to the slot before the next roll")
	await create_timer(0.50).timeout
	_expect(session.score() == 4 and session.coins() == 2 and (typed_screen.get_node("%ScoreLabel") as Label).text == "4", "one four-step COIN landing scores exactly four while coin stays separate")


func _test_inline_slot_result_flow(screen: Control) -> void:
	var typed_screen := screen as V06PlayScreen
	var session: RefCounted = typed_screen.session_for_test()
	session.restart()
	_set_session_main(session, 29, [])
	typed_screen.call("_refresh_ui")
	await typed_screen._run_face(1)
	_expect(session.phase() == SessionScript.PHASE_EVENT_REQUIRED and bool(typed_screen.get("_event_card_open")), "main:30 EVENT card precedes later slot-role flow")
	var free_cta := typed_screen.get_node("%LandingArtPrompt") as Button
	var paid_cta := typed_screen.get_node("%LandingPaidActionButton") as Button
	_expect(free_cta.visible and not free_cta.disabled and free_cta.has_focus() and free_cta.focus_mode == Control.FOCUS_ALL, "EVENT always opens with the free continue CTA visible, enabled, focusable, and focused")
	_expect(paid_cta.visible and paid_cta.disabled and paid_cta.text.contains("コイン ×2") and paid_cta.text.contains("不足") and paid_cta.icon != null and paid_cta.icon.resource_path.ends_with("coin-tokens-stack.png") and paid_cta.get_theme_font_size("font_size") >= 24, "insufficient paid CTA reuses the coin icon and emphasizes its required price with disabled styling")
	typed_screen.call("_on_event_paid_action_pressed")
	_expect(free_cta.visible and not free_cta.disabled and free_cta.has_focus(), "failed EVENT purchase returns focus to the free continuation without trapping input")
	_expect(ScreenScript.event_paid_cta_text(3, 5, false).begins_with("コイン ×3") and ScreenScript.event_paid_cta_text(3, 2, false).contains("不足") and ScreenScript.event_paid_cta_text(2, 5, true).contains("利用済み"), "paid EVENT copy distinguishes ×2/×3, insufficient, and used states")
	var screen_source := FileAccess.get_file_as_string("res://scripts/app/v06_play_screen.gd")
	_expect(screen_source.contains("[30, 43, 61, 77]") and not screen_source.contains("[4, 25, 41, 48]"), "EVENT movement prefetch uses the exact four 90-map indices")
	var first_body := typed_screen.event_card_body("market_hawker", "FIRST", true)
	var repeat_body := typed_screen.event_card_body("market_hawker", "REPEAT", false)
	_expect(first_body == "市場の呼び込みが、きらめく品を掲げて元気よく声をかけてきた。\n初めて発見！", "legacy discovery marker stays concise and contains no hidden score")
	_expect(repeat_body == "顔なじみの呼び込みが、今日もにぎやかに手を振っている。" and not repeat_body.contains("+150"), "non-awarded repeat EVENT keeps exact body and omits the reward line")
	_expect((typed_screen.get_node("%LandingArtPrompt") as Button).text == "旅を続ける", "EVENT reward-line state does not change the exact CTA")
	typed_screen.call("_dismiss_event_card")
	_expect(session.phase() == SessionScript.PHASE_READY and not bool(typed_screen.get("_event_card_open")), "EVENT CTA returns the first roll to READY without input leak")
	_set_session_main(session, 4, [4, 1], 5)
	typed_screen.atlas_for_test().set_route_position(session.position(), true)
	typed_screen.call("_refresh_ui")
	var position_before: Dictionary = session.position()
	typed_screen._run_face(6)
	await create_timer(0.20).timeout
	_expect(session.phase() == SessionScript.PHASE_MOVING and session.pending_resolution_role() == &"MIX", "third stopped face resolves MIX before cat movement")
	_expect(session.position() == position_before and session.visual_position() == position_before, "cat and logical route remain still during inline slot result")
	_expect((typed_screen.get_node("%RoleLabel") as Label).text == "MIX！" and (typed_screen.get_node("%RoleRewardLabel") as Label).visible and (typed_screen.get_node("%RoleRewardLabel") as Label).text == "COIN +1", "slot panel presents the exact role effect without a modal")
	_expect(not (typed_screen.get_node("%TrayStatusLabel") as Label).visible, "inline result keeps the slot header hidden")
	_expect(not (typed_screen.get_node("%ResolutionOverlay") as Control).visible and session.score() == 5 and session.coins() == 1, "MIX coin is awarded while score remains travelled distance and the modal stays hidden")
	var victory_lap_result := str(typed_screen.call("_score_result_text", true))
	var defeat_lap_result := str(typed_screen.call("_score_result_text", false))
	_expect(session.score() > 0 and session.best_score() == 0 and victory_lap_result.contains("スフィンクスに勝利！") and victory_lap_result.contains("この旅 5マス") and victory_lap_result.contains("合計 5マス") and victory_lap_result.contains("BEST 0マス") and not victory_lap_result.contains("自己ベスト更新！"), "victory result explains the travelled-space total without a premature BEST claim")
	_expect(defeat_lap_result.contains("スフィンクスには惜敗。") and defeat_lap_result.contains("この旅 5マス") and defeat_lap_result.contains("合計 5マス") and defeat_lap_result.contains("BEST 0マス") and not defeat_lap_result.contains("自己ベスト更新！"), "defeat result explains the travelled-space total without a premature BEST claim")
	var mix_spec: Dictionary = typed_screen.inline_slot_result_spec("MIX", [4, 1, 6])
	var pair_spec: Dictionary = typed_screen.inline_slot_result_spec("PAIR", [4, 1, 4])
	var straight_spec: Dictionary = typed_screen.inline_slot_result_spec("STRAIGHT", [2, 3, 4])
	var triple_spec: Dictionary = typed_screen.inline_slot_result_spec("TRIPLE", [6, 6, 6])
	_expect(mix_spec.effect == "soft_flash" and mix_spec.reward == "COIN +1", "MIX uses the quiet all-slot flash and exact coin reward")
	_expect(pair_spec.effect == "pair_link" and pair_spec.indices == [0, 2] and pair_spec.reward == "SKILL +1", "PAIR connects only the matching slots and shows its exact effect")
	_expect(straight_spec.effect == "left_to_right" and straight_spec.reward == "SKILL +2", "STRAIGHT flows from left to right and shows its exact effect")
	_expect(triple_spec.effect == "strong_flash" and triple_spec.reward.contains("READY"), "TRIPLE strengthens the flash without extending its duration")
	_expect(is_equal_approx(float(mix_spec.duration), float(pair_spec.duration)) and is_equal_approx(float(pair_spec.duration), float(straight_spec.duration)) and is_equal_approx(float(straight_spec.duration), float(triple_spec.duration)), "all four roles keep the same short result duration")
	await create_timer(3.4).timeout
	_expect(session.phase() == SessionScript.PHASE_READY and session.faces().is_empty() and session.position() != position_before, "inline result auto-acknowledges after movement and accepts the next roll")
	_expect(not (typed_screen.get_node("%ResolutionOverlay") as Control).visible and not (typed_screen.get_node("%RoleRewardLabel") as Label).visible, "inline reward clears without presenting a confirmation button")
	_set_session_main(session, 32, [])
	typed_screen.atlas_for_test().set_route_position(session.position(), true)
	typed_screen.call("_refresh_ui")
	typed_screen._run_face(3)
	await process_frame
	_expect(session.phase() == SessionScript.PHASE_CHOICE_REQUIRED and session.pending_remaining_steps() == 3 and not (typed_screen.get_node("%ChoiceOverlay") as Control).visible and (typed_screen.get_node("%MessageLabel") as Label).text.contains("出目3"), "confirmed result remains visible before the route modal opens")
	await create_timer(1.0).timeout
	_expect(not bool(typed_screen.get("_movement_active")), "fourth roll from the Bazaar fork opens route choice instead of freezing in MOVING")
	_expect((typed_screen.get_node("%ChoiceOverlay") as Control).visible, "zero-hop fork transition presents the route choice controls")
	var choice_map := typed_screen.get_node("%BranchChoiceAtlasView") as Control
	var target_receipt: Dictionary = choice_map.comparison_target_receipt()
	_expect((typed_screen.get_node("%ChoiceRollLabel") as Label).text.contains("出目 3") and (typed_screen.get_node("%ChoiceRollLabel") as Label).text.contains("あと3マス"), "route choice repeats the confirmed die result before asking for a decision")
	_expect(choice_map.is_overview_mode() and target_receipt.size() == 2 and (typed_screen.get_node("%ChoiceMainButton") as Button).text.contains("本線 35") and (typed_screen.get_node("%ChoiceBypassButton") as Button).text.contains("近道 3"), "route choice map and buttons expose both exact landing squares until the player decides")
	var free_choice_state: Dictionary = session.stable_save_snapshot()
	free_choice_state.player.coins = 0
	var free_choice_restored: bool = bool(session.restore_stable_snapshot(free_choice_state))
	typed_screen.call("_configure_route_choice")
	_expect(free_choice_restored and not (typed_screen.get_node("%ChoiceBypassButton") as Button).disabled and not (typed_screen.get_node("%ChoiceBypassButton") as Button).text.contains("コイン"), "shortcut remains selectable with zero coins because risk is its price")
	var bypass_effect_count := int(typed_screen.atlas_for_test().bypass_entry_receipt().play_count)
	await typed_screen._on_route_chosen(CourseScript.ROUTE_BYPASS_BAZAAR)
	var bypass_effect: Dictionary = typed_screen.atlas_for_test().bypass_entry_receipt()
	_expect(int(bypass_effect.play_count) == bypass_effect_count + 1 and str(bypass_effect.name) == "バザール裏路地" and int(bypass_effect.saved_steps) == 4, "entering the Bazaar shortcut presents its named four-space-saving cue once")
	typed_screen.call("_refresh_ui")
	_expect((typed_screen.get_node("%ProgressLabel") as Label).text.begins_with("ALLEY "), "off-main HUD reports truthful route-local progress instead of global /58")
	typed_screen.call("_cancel_motion", session.position())
	session.restart()
	typed_screen.atlas_for_test().set_route_position(session.position(), true)
	typed_screen.call("_refresh_ui")


func _test_bossless_run_over_ui(screen: Control) -> void:
	var typed_screen := screen as V06PlayScreen
	var session: RefCounted = typed_screen.session_for_test()
	session.retry_run()
	var state: Dictionary = session.stable_save_snapshot(0)
	state.player.hp = 0
	state.score.total = 777
	state.score.lap_total = 222
	state.score.breakdown.travel = 777
	_expect(session.restore_stable_snapshot(state, 0) and session.phase() == SessionScript.PHASE_RUN_OVER, "HP0 READY normalizes into bossless RUN_OVER for the screen")
	typed_screen.call("_refresh_ui")
	typed_screen.call("_present_session_phase")
	var title := typed_screen.get_node("%BossTitle") as Label
	var result := typed_screen.get_node("%BossResultLabel") as Label
	_expect((typed_screen.get_node("%BossOverlay") as Control).visible and title.text == "GAME OVER", "bossless RUN_OVER owns the GAME OVER overlay")
	_expect(result.text.contains("旅したマス 777") and result.text.contains("BEST 777") and result.text.contains("LAP 1") and result.text.contains("この旅 222"), "GAME OVER shows cumulative distance, BEST, lap, and this journey")
	_expect((typed_screen.get_node("%RetryButton") as Button).visible and not (typed_screen.get_node("%NextLapButton") as Button).visible and not (typed_screen.get_node("%BossBackButton") as Button).visible, "bossless RUN_OVER exposes Retry only")
	var retry_button := typed_screen.get_node("%RetryButton") as Button
	var labels_over_retry: Array[String] = []
	for raw_label: Node in typed_screen.find_children("*", "Label", true, false):
		var label := raw_label as Label
		if label.is_visible_in_tree() and label.get_global_rect().intersects(retry_button.get_global_rect()):
			labels_over_retry.append(label.name)
	_expect(not (typed_screen.get_node("%TrayPanel") as Control).visible and not (typed_screen.get_node("%DieButton") as Button).visible and labels_over_retry.is_empty(), "GAME OVER removes the old slot numbers and leaves Retry unobstructed")
	typed_screen.call("_on_replay_requested")
	_expect(session.phase() == SessionScript.PHASE_READY and session.player_hp() == 3 and session.score() == 0 and not (typed_screen.get_node("%BossOverlay") as Control).visible and (typed_screen.get_node("%TrayPanel") as Control).visible, "GAME OVER Retry starts a clean challenge and restores the travel controls")


func _test_rolling_tool_cancel(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	var roll_count_before := int(session.roll_count())
	var faces_before: Array[int] = session.faces()
	var tool_cases := [
		{"button":"%ItemToolButton", "mode":"item"},
		{"button":"%CoinToolButton", "mode":"coin"},
		{"button":"%SkillToolButton", "mode":"skill"},
	]
	for index: int in range(tool_cases.size()):
		screen.call("_start_roll")
		await process_frame
		_expect(bool(screen.get("_rolling")) and not (screen.get_node(str(tool_cases[index].button)) as Button).disabled, "%s remains available while the die is rolling" % str(tool_cases[index].mode))
		(screen.get_node(str(tool_cases[index].button)) as Button).pressed.emit()
		await process_frame
		_expect(not bool(screen.get("_rolling")) and bool(screen.get("_utility_open")) and str(screen.get("_utility_mode")) == str(tool_cases[index].mode), "%s cancels the uncommitted roll and opens directly" % str(tool_cases[index].mode))
		_expect(int(session.roll_count()) == roll_count_before and session.faces() == faces_before and session.pending_face() == 0, "cancelled roll consumes no face, turn, movement, or slot")
		if index == 0:
			_expect((screen.get_node("%UtilityDetail") as Label).text.contains("出目・投数・スキル効果は消費していません"), "the first cancelled roll explains that nothing was consumed")
		(screen.get_node("%UtilityCloseButton") as Button).pressed.emit()
		await process_frame
	_expect((screen.get_node("%MessageLabel") as Label).text == "サイコロを振ろう" and not (screen.get_node("%DieButton") as Button).disabled, "closing the selected tool returns to a clean roll-ready state")


func _test_qa_state(screen: Control) -> void:
	var snapshot: Dictionary = screen.session_snapshot()
	_expect(snapshot.position == {"route_id":"main","tile_index":17} and snapshot.faces == [6, 6], "atlas_18 reaches main 17 through the session model with [6,6]")
	_expect(snapshot.phase == &"READY" and snapshot.pending_face == 0 and snapshot.pending_remaining_steps == 0, "QA state is stable and ready with no debug movement residue")
	_expect((screen.get_node("%LapLabel") as Label).visible and (screen.get_node("%LapLabel") as Label).text == "4" and not (screen.get_node("%LapLabel") as Label).text.contains("/"), "QA lap 4 renders as the unbounded value-only integer")
	_expect(not (screen.get_node("%PBLabel") as Label).visible, "QA normal-travel HUD keeps PB hidden")
	_expect((screen.get_node("%HPLabel") as Label).text == "♥♥♡", "QA HUD shows two of three HP")
	_expect(snapshot.score == 17 and snapshot.coins == 0 and int(snapshot.score_breakdown.travel) == 17, "QA route scores exactly its seventeen travelled spaces while coin stays separate")
	_expect((screen.get_node("%ProgressLabel") as Label).text == "18/90", "QA HUD shows data-driven 18/90")
	_expect((screen.get_node("%Slot0") as Label).text == "6" and (screen.get_node("%Slot1") as Label).text == "6" and (screen.get_node("%Slot2") as Label).text == "—", "QA tray shows [6][6][_]")
	_expect((screen.get_node("%DieButton") as Button).text == "振る" and not (screen.get_node("%DieButton") as Button).disabled, "QA tray has exactly one ready roll action")
	_expect((screen.get_node("%AtlasView") as Control).prominent_space_count() == 6, "QA position keeps an exact six-space forward frame")
	_expect((screen.get_node("%AtlasView") as Control).prominent_visible_space_count() >= 6, "QA camera keeps six forward spaces inside the visible atlas")
	_expect((screen.get_node("%AtlasView") as Control).displayed_exit_steps() == -1, "normal atlas does not reveal ring EXIT before entering the loop")
	var atlas := screen.get_node("%AtlasView") as Control
	_expect(atlas.set_route_position({"route_id":"loop_oasis_ring","tile_index":3}, true) and atlas.prominent_space_count() == 8 and atlas.displayed_exit_steps() == 5, "oasis atlas switches to all eight spaces with its exact EXIT distance")
	var loop_diameter: float = atlas.world_position_for({"route_id":"loop_oasis_ring","tile_index":0}).distance_to(atlas.world_position_for({"route_id":"loop_oasis_ring","tile_index":4}))
	_expect(loop_diameter >= 380.0 and atlas.prominent_visible_space_count() == 8 and not atlas.uses_card_route(), "loop route fits all eight roomy spaces in one screen without the scrolling card camera")


func _test_map_contract(screen: Control) -> void:
	var map_button := screen.get_node("%MapButton") as Button
	var map_overlay := screen.get_node("%MapOverlay") as Control
	var overview := screen.get_node("%OverviewAtlasView") as Control
	var session: RefCounted = screen.session_for_test()
	session.restart()
	var started: Dictionary = session.start_roll(1, Time.get_ticks_msec())
	while session.has_pending_hops():
		session.next_hop()
	_expect(started.ok and session.finish_movement().ok and session.phase() == SessionScript.PHASE_READY, "map contract starts from a stable travel state")
	screen.call("_on_map_pressed")
	var message_band := screen.get_node("%MessageBand") as Control
	var message_label := screen.get_node("%MessageLabel") as Label
	_expect(map_button.visible and map_overlay.visible and overview.is_overview_mode() and session.snapshot().clock_paused and map_overlay.mouse_filter == Control.MOUSE_FILTER_STOP and overview.mouse_filter == Control.MOUSE_FILTER_STOP and not message_band.visible and not message_label.visible, "MAP immediately owns the modal view, hides backing operation copy, and pauses the run clock")
	var message_generation_before := int(screen.get("_operation_message_generation"))
	screen.call("_show_operation_message", "MAP中の保留メッセージ", 0.0, 24)
	_expect(message_label.text == "MAP中の保留メッセージ" and int(screen.get("_operation_message_generation")) == message_generation_before + 1 and not message_band.visible and not message_label.visible, "direct operation messages retain text and generation while remaining hidden behind MAP")
	var before_gesture: Dictionary = session.snapshot()
	var before_zoom: float = float(overview.overview_interaction_receipt().zoom)
	_expect(overview.pan_overview(Vector2(140.0, -90.0)) and is_equal_approx(float(overview.overview_interaction_receipt().zoom), before_zoom), "map drag pans without changing zoom")
	var after_gesture: Dictionary = session.snapshot()
	_expect(after_gesture.phase == before_gesture.phase and after_gesture.position == before_gesture.position and after_gesture.faces == before_gesture.faces and after_gesture.coins == before_gesture.coins, "modal map gesture cannot mutate backing roll, route, slot, or purchase state")
	var topology: Dictionary = overview.overview_topology_receipt()
	_expect(topology.detached_loop_routes == PackedStringArray(["loop_oasis_ring", "loop_tomb_ring"]) and int(topology.warp_gate_count) == 5 and int(topology.permanent_loop_connectors) == 0, "overview keeps two rings as detached islands behind five warp gates")
	_expect(topology.bypass_routes == PackedStringArray(["bypass_bazaar_alley", "bypass_sirocco"]) and topology.bypass_sides == PackedStringArray(["right", "left"]) and topology.bypass_saved_steps == PackedInt32Array([4, 6]), "overview separates the two connected shortcuts to opposite sides")
	var bazaar_visual: Dictionary = overview.bypass_visual_receipt("bypass_bazaar_alley")
	_expect(not bazaar_visual.active and float(bazaar_visual.line_alpha) < 0.5 and bazaar_visual.has_entry_marker and bazaar_visual.has_merge_marker, "unselected shortcut stays faint but keeps split and merge markers")
	overview.set_route_position({"route_id":"bypass_sirocco", "tile_index":2}, true)
	var sirocco_visual: Dictionary = overview.bypass_visual_receipt("bypass_sirocco")
	_expect(sirocco_visual.active and float(sirocco_visual.line_alpha) > 0.9 and int(sirocco_visual.saved_steps) == 6, "selected shortcut brightens without changing its six-space saving")
	overview.set_route_position(session.position(), true)
	screen.call("_on_map_closed")
	_expect(not map_overlay.visible and not overview.is_overview_mode() and overview.mouse_filter == Control.MOUSE_FILTER_IGNORE and not session.snapshot().clock_paused and root.gui_get_focus_owner() == map_button and not (screen.get_node("%DieButton") as Button).disabled and message_band.visible and message_label.visible and message_label.text == "サイコロを振ろう", "close CTA restores READY copy, local mode, owned clock pause, MAP focus, and gameplay input")
	_expect(session.pause_clock(Time.get_ticks_msec()), "pre-paused map fixture owns its existing clock pause")
	screen.call("_on_map_pressed")
	screen.call("_on_map_closed")
	_expect(session.snapshot().clock_paused, "closing MAP preserves a clock pause it did not own")
	session.resume_clock(Time.get_ticks_msec())


func _test_compact_die_motion(screen: Control) -> void:
	var presentation := screen.get_node("%DicePresentation")
	screen.call("_start_roll")
	await process_frame
	_expect(presentation.state_name(0) == "ROLLING" and (screen.get_node("%DieButton") as Button).text == "STOP" and not (screen.get_node("%DieHeroArt") as Control).visible and (presentation as Control).visible and (screen.get_node("%MessageBand") as Control).visible and (screen.get_node("%MessageLabel") as Label).text.contains("下の道具で準備に戻る"), "right-side die action explains both STOP and preparation cancellation while one 3D die rotates")
	_expect(not bool((screen.get_node("%AtlasView") as Control).roll_preview_receipt().active), "rolling never lights a destination card")
	await create_timer(0.55).timeout
	_expect(bool(screen.get("_rolling")) and presentation.state_name(0) == "ROLLING" and (screen.get_node("%DieButton") as Button).text == "STOP", "right-side die action keeps rolling until the player taps again")
	var rolling_top_faces := {}
	for sample: int in range(16):
		var orientation: Quaternion = presentation.rolling_orientation(float(sample) * 0.05)
		rolling_top_faces[presentation.top_face_for_orientation(orientation)] = true
	_expect(rolling_top_faces.size() >= 3, "compact die roll uses X/Z-inclusive quaternion motion that exposes multiple top faces")
	var rolling_slot_index: int = screen.session_for_test().faces().size()
	var rolling_slot_path := "%%%s" % ("Slot%d" % rolling_slot_index)
	var rolling_slot_face := int((screen.get_node(rolling_slot_path) as Label).text)
	_expect(rolling_slot_face >= 1 and rolling_slot_face <= 6, "rolling slot cycles only the next empty slot through faces one to six")
	screen.call("_stop_roll")
	var held_preview := int((screen.get_node(rolling_slot_path) as Label).text)
	var settling_before_transfer := bool(screen.get("_slot_settling"))
	await create_timer(ScreenScript.SLOT_STOP_DELAY_SECONDS + 0.04).timeout
	var settled_slot := int((screen.get_node(rolling_slot_path) as Label).text)
	var settling_after_transfer := bool(screen.get("_slot_settling"))
	var pending_face := int(screen.session_for_test().pending_face())
	var committed_faces: Array[int] = screen.session_for_test().faces()
	var logical_face: int = pending_face if pending_face > 0 else (committed_faces.back() if not committed_faces.is_empty() else 0)
	_expect(held_preview >= 1 and held_preview == logical_face and logical_face == settled_slot, "stopping commits the held preview face and transfers that same face to the slot")
	_expect(settling_before_transfer and not settling_after_transfer, "slot transfer retains its short settling delay")
	screen.call("_cancel_motion", screen.session_for_test().position())
	await create_timer(ScreenScript.TARGET_PREVIEW_SECONDS + 0.02).timeout


func _test_third_slot_boss_overlay_order(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	session.restart()
	_set_session_main(session, 87, [3, 3])
	_expect(session.position() == {"route_id":"main","tile_index":87} and session.faces() == [3, 3], "screen boss setup reaches the approved final approach")
	_settle_session_roll(session, 2)
	if session.phase() == SessionScript.PHASE_RUN_OVER:
		_expect(session.player_hp() == 0 and session.boss_snapshot().is_empty(), "screen route gives HP0 GAME OVER priority over third-slot boss entry")
		return
	_expect(session.phase() == SessionScript.PHASE_RESOLUTION_REQUIRED and session.resolution_role() == &"PAIR", "screen session queues PAIR before boss terminal")
	screen.call("_refresh_ui")
	screen.call("_present_session_phase")
	var resolution := screen.get_node("%ResolutionOverlay") as Control
	var boss := screen.get_node("%BossOverlay") as Control
	_expect(not resolution.visible and session.phase() == SessionScript.PHASE_BOSS_GATE and session.faces().is_empty(), "travel role auto-acknowledges without a resolution modal")
	await create_timer(1.5).timeout
	screen.call("_refresh_ui")
	_expect(boss.visible and (screen.get_node("%BossStartButton") as Button).visible and not (screen.get_node("%BossStartButton") as Button).disabled and session.faces().is_empty(), "boss intro remains actionable after the nonmodal travel role")


func _test_stage_select_source_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	_expect(source.contains("58マス") and source.contains("周回ボス：眠そうなスフィンクス"), "stage select names the 58-space Cairo route and Sphinx lap boss")
	_expect(source.contains("kyoto-city-card.png") and source.contains("singapore-city-card.png") and source.contains("newyork-city-card.png") and source.contains("venice-city-card.png"), "stage select imports all four new destination cards")
	_expect(source.contains("千年迷宮の京都") and source.contains("雨あがりの空中庭園シンガポール") and source.contains("眠らない街ニューヨーク") and source.contains("水路迷宮ヴェネツィア"), "stage select names the four replacement destinations")
	_expect(source.contains("千年碁盤の白狐") and source.contains("雨雲のマーライオン") and source.contains("眠らぬリバティキャット") and source.contains("水門の仮面獅子"), "locked destinations carry provisional boss names")
	_expect(source.contains("false, _preview_stage.bind(STAGE_KYOTO)") and source.contains("false, _preview_stage.bind(STAGE_SINGAPORE)") and source.contains("false, _preview_stage.bind(STAGE_NEWYORK)") and source.contains("false, _preview_stage.bind(STAGE_VENICE)") and source.contains("locked_cta.disabled = true"), "the four future destinations are previewable but remain locked")
	_expect(not source.contains("v0.6 新ルール試遊（保存なし）"), "stage select removes the duplicate legacy trial action")
	_expect(source.contains("_button(\"探検猫で出発\", _start_new_v06_game, true)") and source.contains("true, _start_new_v06_game, CAIRO_CITY_CARD"), "stage selection routes both entry controls directly to the explorer cat V06 start")
	_expect(source.contains("func _start_new_v06_game()") and source.contains("GameState.selected_character_id = GameState.DEFAULT_CHARACTER") and source.contains("show_v06_game(selected_stage_id, GameState.DEFAULT_CHARACTER)"), "new journey always starts V06 with the explorer cat")
	_expect(not source.contains("_button(\"この旅へ\", show_character_select, true)") and not source.contains("true, show_character_select, CAIRO_CITY_CARD"), "product stage selection does not open the character selection screen")
	_expect(not source.contains("オートセーブ対応"), "title hides the unimplemented autosave promise")


func _test_v06_save_source_contract() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	var screen_source := FileAccess.get_file_as_string("res://scripts/app/v06_play_screen.gd")
	var legacy_manager_source := FileAccess.get_file_as_string("res://autoload/save_manager.gd")
	_expect(main_source.contains("func _continue_v06_game()") and main_source.contains("show_v06_game(stage_id, character_id, data)"), "title continuation loads only the V06 save result")
	_expect(main_source.contains("screen.configure_resume_data(resume_data)") and main_source.contains("screen.configure_save_manager(_v06_save_manager())"), "V06 screen receives resume data and its separate save manager")
	_expect(screen_source.contains("add_to_group(\"v06_session_screen\")") and screen_source.contains("func _save_stable_checkpoint()") and screen_source.contains("NOTIFICATION_WM_CLOSE_REQUEST") and screen_source.contains("elif not resume_requested"), "V06 owns stable checkpoints and does not overwrite a failed resume")
	_expect(main_source.contains("add_to_group(\"v06_session_screen\")") and main_source.contains("remove_from_group(\"v06_session_screen\")") and legacy_manager_source.contains("v06_session_screen") and legacy_manager_source.contains("return"), "legacy lifecycle autosave is skipped through the V06 host transition")


func _test_v06_resume_runtime() -> void:
	var path := "user://v06_screen_resume_test.json"
	for candidate: String in [path, "%s.bak" % path, "%s.tmp" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
	var manager: RefCounted = SaveManagerScript.new(path)
	var source_session: RefCounted = SessionScript.new(&"cairo_hourglass", &"gambler")
	var started: Dictionary = source_session.start_roll(2)
	while source_session.has_pending_hops():
		source_session.next_hop()
	source_session.finish_movement()
	var saved: Dictionary = manager.save_session(source_session)
	var host := Control.new()
	host.size = UiTokensScript.BASE_VIEWPORT
	root.add_child(host)
	var resumed_screen: V06PlayScreen = ScreenScene.instantiate() as V06PlayScreen
	resumed_screen.configure_start_context(&"cairo_hourglass", &"gambler")
	resumed_screen.configure_save_manager(manager)
	resumed_screen.configure_resume_data(saved.data)
	host.add_child(resumed_screen)
	await process_frame
	await process_frame
	var resumed: RefCounted = resumed_screen.session_for_test()
	_expect(started.ok and saved.ok and resumed.stage_id() == &"cairo_hourglass" and resumed.character_id() == &"gambler" and resumed.position().tile_index == source_session.position().tile_index and resumed.phase() == SessionScript.PHASE_READY, "screen resumes the saved V06 stage, character, and stable position")
	host.queue_free()
	await process_frame
	for candidate: String in [path, "%s.bak" % path, "%s.tmp" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _test_v06_resume_failure_preserves_save() -> void:
	var path := "user://v06_screen_resume_failure_test.json"
	for candidate: String in [path, "%s.bak" % path, "%s.tmp" % path, "%s.bak.swap" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
	var manager: RefCounted = SaveManagerScript.new(path)
	_expect(manager.save_session(SessionScript.new(&"cairo_hourglass", &"gambler")).ok, "resume-failure setup creates the previous checkpoint")
	var host := Control.new()
	host.size = UiTokensScript.BASE_VIEWPORT
	root.add_child(host)
	var failed_screen: V06PlayScreen = ScreenScene.instantiate() as V06PlayScreen
	failed_screen.configure_start_context(&"cairo_hourglass", &"relaxed")
	failed_screen.configure_save_manager(manager)
	failed_screen.configure_resume_data({"session_state":{"phase":"NOT_A_STABLE_PHASE"}})
	host.add_child(failed_screen)
	await process_frame
	await process_frame
	var preserved: Dictionary = manager.load_result()
	_expect(preserved.ok and preserved.status == SaveManagerScript.STATUS_VALID_PRIMARY and preserved.data.character_id == "gambler", "failed V06 resume does not overwrite the previous Continue checkpoint")
	host.queue_free()
	await process_frame
	for candidate: String in [path, "%s.bak" % path, "%s.tmp" % path, "%s.bak.swap" % path]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _set_session_main(session: RefCounted, tile_index: int, face_values: Array, score_value := -1) -> void:
	var state: Dictionary = session.stable_save_snapshot(0)
	state.route.current_node_id = "main:%d" % tile_index
	state.route.route_id = "main"
	state.route.tile_index = tile_index
	state.route.visited_node_keys = ["main:%d" % tile_index]
	state.slot.faces = face_values.duplicate()
	state.slot.current_roll_index = face_values.size()
	state.slot.last_role = ""
	state.slot.last_role_resolved = false
	state.slot.resolution_role = ""
	state.slot.pending_role = ""
	state.slot.pending_role_awarded = false
	if score_value >= 0:
		state.score.total = score_value
		state.score.lap_total = score_value
		state.score.breakdown.travel = score_value
	_expect(session.restore_stable_snapshot(state, 0), "screen fixture restores main%d with %d faces" % [tile_index, face_values.size()])


func _settle_session_roll(session: RefCounted, face: int, route_choice := "") -> bool:
	var started: Dictionary = session.start_roll(face)
	if not bool(started.get("ok", false)):
		return false
	while session.has_pending_hops():
		session.next_hop()
	var settled: Dictionary = session.finish_movement()
	if not bool(settled.get("ok", false)):
		return false
	if session.phase() != SessionScript.PHASE_CHOICE_REQUIRED:
		return true
	if route_choice.is_empty() or not bool(session.choose_route(route_choice).get("ok", false)):
		return false
	while session.has_pending_hops():
		session.next_hop()
	return bool(session.finish_movement().get("ok", false))


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
