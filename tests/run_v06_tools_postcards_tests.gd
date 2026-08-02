extends SceneTree

const SessionScript = preload("res://scripts/game/v06_play_session.gd")
const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_item_acquisition_and_effects()
	_test_pinpoint_skill_and_save()
	await _test_tool_overlay()
	await _test_postcard_unlock_and_gallery()
	print("V06_TOOLS_POSTCARDS_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_item_acquisition_and_effects() -> void:
	var found: RefCounted = SessionScript.new()
	_roll_and_finish(found, 5)
	_expect(found.inventory_total() == 1 and int(found.inventory().get(SessionScript.ITEM_SCARAB_SEAL, 0)) == 1, "first ITEM stop grants its deterministic Cairo tool")
	_expect(str(found.last_tile_effect_result().get("item_id", "")) == SessionScript.ITEM_SCARAB_SEAL, "ITEM landing receipt identifies the granted tool")

	var compass := _session_with_player_state({SessionScript.ITEM_BRASS_COMPASS:1}, 3)
	var compass_use: Dictionary = compass.use_item(SessionScript.ITEM_BRASS_COMPASS)
	var moved: Dictionary = compass.start_roll(1)
	_expect(compass_use.ok and moved.ok and compass.pending_move_distance() == 2 and compass.inventory_total() == 0, "brass compass consumes once and adds one to the next move")

	var canteen := _session_with_player_state({SessionScript.ITEM_WATER_CANTEEN:1}, 2)
	var canteen_use: Dictionary = canteen.use_item(SessionScript.ITEM_WATER_CANTEEN)
	_expect(canteen_use.ok and canteen.player_hp() == 3 and canteen.inventory_total() == 0, "water canteen heals one and leaves no negative quantity")

	var scarab := _session_with_player_state({SessionScript.ITEM_SCARAB_SEAL:1}, 3, {"route_id":"main","tile_index":20})
	_expect(bool(scarab.use_item(SessionScript.ITEM_SCARAB_SEAL).get("ok", false)), "scarab seal can be armed before a risk stop")
	_roll_and_finish(scarab, 1)
	var guarded: Dictionary = scarab.last_tile_effect_result()
	_expect(scarab.player_hp() == 3 and bool(guarded.get("guarded", false)) and guarded.text == "SCARAB GUARD", "scarab seal cancels the next risk effect and is consumed")


func _test_pinpoint_skill_and_save() -> void:
	var ready := _session_with_player_state({}, 3, {"route_id":"main","tile_index":0}, SessionScript.SKILL_GAUGE_MAX, SessionScript.SKILL_STATE_READY)
	var armed: Dictionary = ready.arm_pinpoint(4)
	_expect(armed.ok and ready.skill_state() == SessionScript.SKILL_STATE_ARMED and ready.pinpoint_face() == 4 and ready.skill_gauge() == 0, "pinpoint spends a full gauge and stores the selected face")
	var restored := SessionScript.new()
	_expect(restored.restore_stable_snapshot(ready.stable_save_snapshot(1000), 1000) and restored.pinpoint_face() == 4 and restored.skill_state() == SessionScript.SKILL_STATE_ARMED, "armed pinpoint survives a stable save")
	_expect(restored.consume_pinpoint_face() == 4 and restored.consume_pinpoint_face() == 0 and restored.skill_state() == SessionScript.SKILL_STATE_CHARGING, "pinpoint face is consumed exactly once")


func _test_tool_overlay() -> void:
	var host := Control.new(); host.size = Vector2(720, 1280); root.add_child(host)
	var screen: Control = ScreenScene.instantiate(); host.add_child(screen)
	await process_frame; await process_frame
	var session: RefCounted = screen.session_for_test()
	var state: Dictionary = session.stable_save_snapshot(1000)
	state.player.inventory = {SessionScript.ITEM_WATER_CANTEEN:1, SessionScript.ITEM_BRASS_COMPASS:1}
	state.player.hp = 2
	state.player.skill_gauge = SessionScript.SKILL_GAUGE_MAX
	state.player.skill_state = String(SessionScript.SKILL_STATE_READY)
	_expect(session.restore_stable_snapshot(state, 1000), "tool overlay fixture restores inventory and ready skill")
	screen.call("_refresh_ui")
	screen.call("_on_item_tool_pressed")
	_expect((screen.get_node("%UtilityOverlay") as Control).visible and (screen.get_node("%UtilityActionButton") as Button).visible and not (screen.get_node("%UtilityActionButton") as Button).disabled, "item button opens a usable inventory card")
	_expect((screen.get_node("%UtilityPageLabel") as Label).text == "1 / 2" and (screen.get_node("%UtilityNextButton") as Button).visible, "inventory card pages through owned tools")
	screen.call("_on_utility_action")
	_expect(session.inventory_total() == 1 and session.player_hp() == 3, "inventory action applies the selected canteen immediately")
	screen.call("_on_utility_closed")
	screen.call("_on_skill_tool_pressed")
	_expect((screen.get_node("%PinpointFaceRow") as Control).visible and not (screen.get_node("%PinpointFace4") as Button).disabled, "ready pinpoint exposes six large face choices")
	screen.call("_on_pinpoint_face_selected", 4)
	_expect(not (screen.get_node("%UtilityOverlay") as Control).visible and session.pinpoint_face() == 4, "choosing a pinpoint face closes the modal and returns to travel")
	host.queue_free(); await process_frame


func _test_postcard_unlock_and_gallery() -> void:
	var signal_host := Control.new(); signal_host.size = Vector2(720, 1280); root.add_child(signal_host)
	var screen: Control = ScreenScene.instantiate(); signal_host.add_child(screen)
	await process_frame; await process_frame
	var unlocked_ids: Array[String] = []
	screen.postcard_unlocked.connect(func(postcard_id: String) -> void: unlocked_ids.append(postcard_id))
	var session: RefCounted = screen.session_for_test()
	session.enter_boss(0)
	for timestamp: int in [1, 2, 3, 4]:
		session.start_roll(6, timestamp)
		if session.phase() != SessionScript.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	screen.call("_cancel_motion", session.position())
	screen.call("_refresh_ui")
	screen.call("_refresh_ui")
	_expect(unlocked_ids == ["cairo_journey_complete"], "Cairo victory emits its postcard unlock exactly once")
	signal_host.queue_free(); await process_frame

	var global_state := root.get_node("GameState")
	var original_postcards: Array = global_state.get("registered_postcards").duplicate()
	var original_book: Array = global_state.get("encyclopedia").duplicate(true)
	var main_scene := load("res://scenes/app/Main.tscn") as PackedScene
	var app: Control = main_scene.instantiate(); root.add_child(app)
	await process_frame; await process_frame
	var runtime_postcards: Array = global_state.get("registered_postcards")
	runtime_postcards.clear(); runtime_postcards.append("cairo_journey_complete")
	var runtime_book: Array = global_state.get("encyclopedia")
	runtime_book.clear()
	app.call("show_encyclopedia")
	await process_frame; await process_frame
	var unlocked_card := app.find_child("Postcard_cairo_journey_complete", true, false) as PanelContainer
	var locked_card := app.find_child("Postcard_cairo_spice_market_complete", true, false) as PanelContainer
	var unlocked_art := unlocked_card.find_child("PostcardArt", true, false) as TextureRect
	var locked_art := locked_card.find_child("PostcardArt", true, false) as TextureRect
	_expect(app.find_child("TravelEncyclopediaScroll", true, false) != null and app.find_child("PostcardGallery", true, false) != null, "travel encyclopedia provides a scrollable postcard gallery")
	_expect(unlocked_art.texture.resource_path.ends_with("cairo-journey-postcard.png") and unlocked_art.modulate.r > 0.9, "earned Cairo postcard is shown in full color")
	_expect(locked_art.modulate.r < 0.2, "unearned postcard remains a dark collectible slot")
	app.queue_free()
	runtime_postcards.assign(original_postcards)
	runtime_book.assign(original_book)
	await process_frame


func _session_with_player_state(inventory: Dictionary, hp: int, route_position := {"route_id":"main","tile_index":0}, gauge := 0, skill_state := SessionScript.SKILL_STATE_CHARGING) -> RefCounted:
	var source: RefCounted = SessionScript.new()
	var state: Dictionary = source.stable_save_snapshot(1000)
	state.player.inventory = inventory.duplicate(true)
	state.player.hp = hp
	state.player.skill_gauge = gauge
	state.player.skill_state = String(skill_state)
	state.route.route_id = str(route_position.route_id)
	state.route.tile_index = int(route_position.tile_index)
	state.route.current_node_id = "%s:%d" % [str(route_position.route_id), int(route_position.tile_index)]
	var restored: RefCounted = SessionScript.new()
	if not restored.restore_stable_snapshot(state, 1000):
		push_error("fixture restore failed")
	return restored


func _roll_and_finish(session: RefCounted, face: int) -> void:
	var started: Dictionary = session.start_roll(face)
	if not bool(started.get("ok", false)):
		return
	while session.has_pending_hops():
		session.next_hop()
	session.finish_movement()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
