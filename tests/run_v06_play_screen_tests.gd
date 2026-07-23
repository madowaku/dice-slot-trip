extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const ScreenScript = preload("res://scripts/app/v06_play_screen.gd")
const AtlasScript = preload("res://scripts/game/v06_atlas_view.gd")
const SessionScript = preload("res://scripts/game/v06_play_session.gd")
const CourseScript = preload("res://scripts/game/v06_course_model.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	var host := Control.new()
	host.size = UiTokensScript.BASE_VIEWPORT
	root.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	_test_named_structure(screen)
	_test_layout_and_touch(screen)
	_test_atlas_contract(screen)
	_test_map_contract(screen)
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
	var capture_path := OS.get_environment("DICE_QA_V06_CAPTURE_PATH")
	if not capture_path.is_empty():
		if OS.get_environment("DICE_QA_V06_BYPASS_CAPTURE") == "1":
			(qa_screen.get_node("%AtlasView") as Control).set_route_position({"route_id":CourseScript.ROUTE_BYPASS,"tile_index":0}, true)
		if OS.get_environment("DICE_QA_V06_KIND_PREVIEW") == "1":
			(qa_screen.get_node("%AtlasView") as Control).set_kind_preview_override(PackedStringArray(["NORMAL", "COIN", "REST", "RISK", "ITEM", "EVENT"]))
		match OS.get_environment("DICE_QA_V06_UTILITY_CAPTURE"):
			"item": qa_screen.call("_on_item_tool_pressed")
			"skill": qa_screen.call("_on_skill_tool_pressed")
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
	_test_qa_state(qa_screen)
	_test_third_slot_boss_overlay_order(qa_screen)
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	qa_viewport.queue_free()
	await process_frame
	print("V06_PLAY_SCREEN_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_named_structure(screen: Control) -> void:
	for node_name: String in [
		"LapLabel", "HPLabel", "PBLabel", "TimeLabel", "ProgressLabel", "StageLabel",
		"RouteLabel", "TileKindLabel", "AtlasView", "TrayPanel", "MapButton", "MapOverlay", "OverviewAtlasView", "MapCloseButton", "Slot0",
		"Slot1", "Slot2", "DieWell", "DicePresentation", "DieButton", "ChoiceOverlay", "ResolutionOverlay",
		"BossOverlay", "ToolDock", "ItemToolButton", "SkillToolButton", "UtilityOverlay", "UtilityCardArt", "UtilityCloseButton", "BackButton",
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
	_expect(dice_receipt.active_count == 1 and dice_receipt.viewport_size.x >= 96 and dice_receipt.viewport_size.x == dice_receipt.viewport_size.y, "fixed tray renders exactly one compact square 3D die")
	_expect((screen.get_node("%LapLabel") as Label).text == "LAP 1" and (screen.get_node("%HPLabel") as Label).text == "HP 3/3", "initial HUD is LAP 1 and HP 3/3")
	_expect((screen.get_node("%PBLabel") as Label).text == "PB --" and (screen.get_node("%ProgressLabel") as Label).text == "1/58", "initial PB and data-driven Cairo progress are readable")
	_expect((screen.get_node("%Slot0") as Label).text == "—" and (screen.get_node("%Slot2") as Label).text == "—", "initial slots are blank")
	_expect((screen.get_node("%DieButton") as Button).text == "READY\nROLL", "the one die starts READY")
	_expect((screen.get_node("%ItemToolButton") as Button).text.contains("0 / 3") and (screen.get_node("%SkillToolButton") as Button).text.contains("READY"), "bottom tool dock exposes item capacity and skill readiness")


func _test_layout_and_touch(screen: Control) -> void:
	_expect(screen.size == UiTokensScript.BASE_VIEWPORT, "root resolves to the 720x1280 design viewport")
	var page := screen.get_node("%Page") as Control
	var safe_margin := page.get_parent() as Control
	var needed := page.get_combined_minimum_size()
	_expect(needed.x <= safe_margin.size.x + 1.0 and needed.y <= safe_margin.size.y + 1.0, "root content fits 720x1280 without clipping")
	var touch_ok := true
	for node: Node in screen.find_children("*", "Button", true, false):
		var button := node as Button
		touch_ok = touch_ok and button.custom_minimum_size.y >= UiTokensScript.TOUCH_MIN
	_expect(touch_ok, "every screen and overlay button meets the touch minimum")
	var last_slot := screen.get_node("%SlotPanel2") as Control
	var die := screen.get_node("%DieButton") as Control
	var die_well := screen.get_node("%DieWell") as Control
	var tray := screen.get_node("%TrayPanel") as Control
	var gap := die.get_global_rect().position.x - last_slot.get_global_rect().end.x
	_expect(gap >= 0.0 and gap <= 20.0, "third slot and the one die share one close sightline")
	_expect(tray.get_global_rect().encloses(die_well.get_global_rect()) and die_well.get_global_rect().end.x <= (screen.get_node("%SlotPanel0") as Control).get_global_rect().position.x, "3D die well stays inside the fixed tray to the left of all three history slots")
	_expect(ScreenScript.SLOT_BREATH_ALPHA_AMPLITUDE <= 0.06 and ScreenScript.SLOT_BREATH_PERIOD_SECONDS >= 1.6, "unconfirmed slot glow is a slow low-amplitude breath")
	_expect((screen.get_node("%MapButton") as Button).custom_minimum_size.x >= 72 and (screen.get_node("%MapButton") as Button).custom_minimum_size.y >= 96, "top-right MAP control is a large one-hand target")
	var tool_dock := screen.get_node("%ToolDock") as Control
	_expect(tool_dock.get_global_rect().position.y >= tray.get_global_rect().end.y and (screen.get_node("%AtlasView") as Control).size.y >= 520.0, "item and skill dock sits below the raised tray without shrinking the playfield below contract")
	_expect((screen.get_node("%ItemToolButton") as Button).icon.resource_path == "res://assets/art/v08/cards/item-card.png" and (screen.get_node("%SkillToolButton") as Button).icon.resource_path == "res://assets/art/v08/cards/skill-card.png", "tool buttons use the two production ImageGen card rasters")
	_test_utility_cards(screen)


func _test_utility_cards(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	var overlay := screen.get_node("%UtilityOverlay") as Control
	screen.call("_on_item_tool_pressed")
	_expect(overlay.visible and (screen.get_node("%DieButton") as Button).disabled and (screen.get_node("%UtilityTitle") as Label).text == "アイテム" and (screen.get_node("%UtilityDetail") as Label).text.contains("0 / 3"), "ITEM button opens its functional capacity card and gates gameplay input")
	screen.call("_on_utility_closed")
	screen.call("_on_skill_tool_pressed")
	_expect(overlay.visible and (screen.get_node("%DieButton") as Button).disabled and (screen.get_node("%UtilityTitle") as Label).text.contains("READY") and (screen.get_node("%UtilityCardArt") as TextureRect).texture.resource_path == "res://assets/art/v08/cards/skill-card.png", "SKILL button opens the generated character card without inventing an effect")
	screen.call("_on_utility_closed")
	_expect(not overlay.visible and not session.snapshot().clock_paused and not (screen.get_node("%DieButton") as Button).disabled, "closing a utility card restores gameplay input and the run clock")


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
	_expect(prominent_count >= 5 and prominent_count <= 7, "atlas emphasizes the forward 5-7 spaces only")
	var style_ids: PackedStringArray = atlas.route_style_ids()
	var unique_styles := {}
	for style_id: String in style_ids:
		unique_styles[style_id] = true
	_expect(style_ids.size() == 3 and unique_styles.size() == 3, "main, bypass, and loop expose distinct route style IDs")
	_expect(style_ids[0] == String(AtlasScript.ROUTE_STYLE_MAIN) and style_ids[1] == String(AtlasScript.ROUTE_STYLE_BYPASS) and style_ids[2] == String(AtlasScript.ROUTE_STYLE_LOOP), "route style IDs identify teal solid, rust dashed, and loop/gold exit")
	_expect(AtlasScript.CAMERA_FOLLOW_SECONDS >= 0.26 and AtlasScript.CAMERA_FOLLOW_SECONDS <= 0.34 and AtlasScript.HOP_SECONDS >= 0.28 and AtlasScript.HOP_SECONDS <= 0.34, "cat hop and camera follow use the low-stimulation motion interval")
	_expect(AtlasScript.CAT_TILE_SCALE >= 1.30 and AtlasScript.CAT_TILE_SCALE <= 1.50, "cat remains 1.3-1.5x the local tile focal scale")


func _test_qa_state(screen: Control) -> void:
	var snapshot: Dictionary = screen.session_snapshot()
	_expect(snapshot.position == {"route_id":"main","tile_index":17} and snapshot.faces == [6, 6], "atlas_18 reaches main 17 through the session model with [6,6]")
	_expect(snapshot.phase == &"READY" and snapshot.pending_face == 0 and snapshot.pending_remaining_steps == 0, "QA state is stable and ready with no debug movement residue")
	_expect((screen.get_node("%LapLabel") as Label).text == "LAP 4", "QA HUD shows LAP 4")
	_expect((screen.get_node("%HPLabel") as Label).text == "HP 2/3", "QA HUD shows HP 2/3")
	_expect((screen.get_node("%PBLabel") as Label).text == "PB -2.4s", "QA HUD shows PB -2.4s")
	_expect((screen.get_node("%ProgressLabel") as Label).text == "18/58", "QA HUD shows data-driven 18/58")
	_expect((screen.get_node("%Slot0") as Label).text == "6" and (screen.get_node("%Slot1") as Label).text == "6" and (screen.get_node("%Slot2") as Label).text == "—", "QA tray shows [6][6][_]")
	_expect((screen.get_node("%DieButton") as Button).text == "READY\nROLL" and not (screen.get_node("%DieButton") as Button).disabled, "QA tray has exactly one READY die")
	_expect((screen.get_node("%AtlasView") as Control).prominent_space_count() >= 5 and (screen.get_node("%AtlasView") as Control).prominent_space_count() <= 7, "QA position keeps a forward 5-7-space frame")
	_expect((screen.get_node("%AtlasView") as Control).prominent_visible_space_count() >= 6, "QA camera keeps six forward spaces inside the visible atlas")
	_expect((screen.get_node("%AtlasView") as Control).displayed_exit_steps() == -1, "normal atlas does not reveal ring EXIT before entering the loop")
	var atlas := screen.get_node("%AtlasView") as Control
	_expect(atlas.set_route_position({"route_id":"loop_souk_ring","tile_index":0}, true) and atlas.prominent_space_count() == 8 and atlas.displayed_exit_steps() == 4, "loop atlas switches to all eight spaces with EXIT 4")


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
	_expect(map_button.visible and map_overlay.visible and overview.is_overview_mode() and session.snapshot().clock_paused, "MAP opens the overview and pauses the run clock")
	screen.call("_on_map_closed")
	_expect(not map_overlay.visible and not overview.is_overview_mode() and not session.snapshot().clock_paused, "closing MAP restores local view and resumes the clock")


func _test_compact_die_motion(screen: Control) -> void:
	var presentation := screen.get_node("%DicePresentation")
	screen.call("_start_roll")
	await process_frame
	_expect(presentation.state_name(0) == "ROLLING" and (screen.get_node("%DieButton") as Button).text == "TAP\nSTOP", "tray die enters visible rolling state on the first tap")
	await create_timer(0.55).timeout
	_expect(bool(screen.get("_rolling")) and presentation.state_name(0) == "ROLLING" and (screen.get_node("%DieButton") as Button).text == "TAP\nSTOP", "tray die keeps rolling until the player taps again")


func _test_third_slot_boss_overlay_order(screen: Control) -> void:
	var session: RefCounted = screen.session_for_test()
	session.restart()
	_settle_session_roll(session, 6)
	_settle_session_roll(session, 4)
	_settle_session_roll(session, 4, CourseScript.ROUTE_MAIN)
	session.acknowledge_resolution()
	_settle_session_roll(session, 6)
	_settle_session_roll(session, 1)
	_settle_session_roll(session, 2)
	session.acknowledge_resolution()
	_expect(session.position() == {"route_id":"main","tile_index":23} and session.faces().is_empty(), "screen boss setup reaches canonical main 23")
	_settle_session_roll(session, 3)
	_settle_session_roll(session, 3)
	_settle_session_roll(session, 2)
	session.acknowledge_resolution()
	_settle_session_roll(session, 6)
	_settle_session_roll(session, 6)
	_settle_session_roll(session, 6)
	session.acknowledge_resolution()
	_settle_session_roll(session, 3)
	_settle_session_roll(session, 3)
	_settle_session_roll(session, 2)
	screen.call("_refresh_ui")
	screen.call("_present_session_phase")
	var resolution := screen.get_node("%ResolutionOverlay") as Control
	var boss := screen.get_node("%BossOverlay") as Control
	_expect(session.phase() == SessionScript.PHASE_RESOLUTION_REQUIRED and session.resolution_role() == &"PAIR", "screen session queues PAIR before boss terminal")
	_expect(resolution.visible and not boss.visible and (screen.get_node("%ResolutionTitle") as Label).text == "PAIR", "resolution overlay is visible while boss overlay stays hidden")
	(screen.get_node("%ResolutionAckButton") as Button).emit_signal("pressed")
	_expect(session.phase() == SessionScript.PHASE_BOSS_GATE and session.faces().is_empty(), "screen acknowledgement advances session to boss terminal")
	_expect(not resolution.visible and boss.visible and not (screen.get_node("%DieButton") as Button).disabled and session.faces().is_empty(), "screen hides travel result, shows boss, and enables a fresh blank boss round")


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
