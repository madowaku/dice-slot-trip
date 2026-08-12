extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const SaveData = preload("res://scripts/game/v06_session_save_data.gd")
const PlayScreenScene = preload("res://scenes/app/V06PlayScreen.tscn")

var failures := 0


func _init() -> void:
	_test_progress_and_latches()
	_test_damage_victory_and_reset()
	_test_optional_save_and_legacy_migration()
	call_deferred("_test_ui")


func _test_progress_and_latches() -> void:
	var session: RefCounted = Session.new()
	session.call("_advance_coin_mission", 5)
	session.call("_advance_coin_mission", 1)
	session.call("_advance_coin_mission", 8)
	var coin: Dictionary = session.mission_state()
	_expect(coin.schema_version == 2 and coin.coin_target == 12 and coin.role_target == 5 and coin.coin_gained == 14 and coin.coin_completed, "schema2 gross coin progress keeps increasing and latches at twelve")
	session.call("_award_role_score", &"MIX")
	_expect(session.mission_state().role_successes == 0 and session.mission_state().coin_gained == 15, "MIX adds gross coin and is excluded from role mission")
	session.call("_award_role_score", &"PAIR")
	session.call("_award_role_score", &"STRAIGHT")
	session.call("_award_role_score", &"TRIPLE")
	_expect(session.mission_state().role_successes == 3 and not session.mission_state().role_completed, "three qualifying roles remain below the five-role target")
	session.call("_award_role_score", &"PAIR")
	session.call("_award_role_score", &"STRAIGHT")
	_expect(session.mission_state().role_successes == 5 and session.mission_state().role_completed, "PAIR, STRAIGHT, and TRIPLE increment and role completion latches at five")


func _test_damage_victory_and_reset() -> void:
	var damaged: RefCounted = Session.new()
	damaged.call("_fail_no_damage_mission")
	damaged.call("_complete_no_damage_mission")
	_expect(not damaged.mission_state().no_damage_active and not damaged.mission_state().no_damage_completed, "damage failure latches and cannot be healed or completed")
	var victory: RefCounted = Session.new()
	_expect(victory.enter_boss(0), "boss mission test enters race")
	for now: int in [1, 2, 3, 4]:
		victory.start_roll(6, now)
		if victory.phase() != Session.PHASE_BOSS_FINISHED:
			victory.acknowledge_boss_round()
	_expect(victory.boss_result().victory and victory.mission_state().no_damage_completed, "only terminal boss victory completes an active no-damage mission")
	_expect(victory.next_lap() and victory.mission_state().coin_gained == 0 and victory.mission_state().role_successes == 0 and victory.mission_state().no_damage_active, "successful next lap resets all per-lap mission state")


func _test_optional_save_and_legacy_migration() -> void:
	var session: RefCounted = Session.new()
	session.call("_advance_coin_mission", 7)
	session.call("_award_role_score", &"PAIR")
	var state: Dictionary = session.stable_save_snapshot(10)
	var dto := {"schema_version": SaveData.SCHEMA_VERSION, "course_version":SaveData.COURSE_VERSION, "app_version":"v0.8", "saved_at":"now", "saved_at_unix":0, "stage_id":"cairo_hourglass", "character_id":"relaxed", "session_state":state, "pending_transaction":null}
	var schema2_result: Dictionary = SaveData.validate(dto)
	_expect(schema2_result.ok and schema2_result.data.session_state.missions.schema_version == 2 and schema2_result.data.session_state.missions.coin_target == 12 and schema2_result.data.session_state.missions.role_target == 5, "outer schema2 save accepts exact nested mission schema2 and course version")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(state, 20) and restored.mission_state().coin_gained == 7 and restored.mission_state().role_successes == 1 and restored.mission_state().event_serial == state.missions.event_serial, "nested schema2 mission state round-trips idempotently without replaying an event")
	var legacy_nested_dto := dto.duplicate(true)
	legacy_nested_dto.session_state.missions.schema_version = 1
	legacy_nested_dto.session_state.missions.coin_target = 6
	legacy_nested_dto.session_state.missions.role_target = 2
	legacy_nested_dto.session_state.missions.coin_gained = 10
	legacy_nested_dto.session_state.missions.role_successes = 4
	legacy_nested_dto.session_state.missions.coin_completed = true
	legacy_nested_dto.session_state.missions.role_completed = true
	legacy_nested_dto.session_state.missions.no_damage_active = false
	legacy_nested_dto.session_state.missions.no_damage_completed = false
	legacy_nested_dto.session_state.missions.active_ids = ["cairo_coin15", "cairo_triple2", "cairo_no_damage"]
	legacy_nested_dto.session_state.missions.ranks = {"cairo_coin15":2, "cairo_triple2":3}
	legacy_nested_dto.session_state.missions.ring_exits = 4
	legacy_nested_dto.session_state.missions.event_serial = 9
	legacy_nested_dto.session_state.missions.last_event = {"serial":9, "kind":"coin", "completed":true}
	var legacy_result: Dictionary = SaveData.validate(legacy_nested_dto)
	var migrated_missions: Dictionary = legacy_result.get("data", {}).get("session_state", {}).get("missions", {})
	_expect(legacy_result.ok and migrated_missions.schema_version == 2 and migrated_missions.coin_target == 12 and migrated_missions.role_target == 5, "exact legacy nested schema1 targets6/2 migrate to schema2 targets12/5")
	_expect(migrated_missions.coin_gained == 10 and migrated_missions.role_successes == 4 and not migrated_missions.coin_completed and not migrated_missions.role_completed, "legacy gross progress is preserved and completion is recomputed against12/5")
	_expect(migrated_missions.active_ids == ["cairo_coin15", "cairo_triple2", "cairo_no_damage"] and migrated_missions.ranks == {"cairo_coin15":2, "cairo_triple2":3} and migrated_missions.ring_exits == 4 and not migrated_missions.no_damage_active, "legacy active IDs, ranks, ring exits, and no-damage state are preserved")
	_expect(migrated_missions.event_serial == 0 and migrated_missions.last_event.is_empty(), "legacy event serial and last event clear so no toast or reward replays")
	var migrated_again: Dictionary = SaveData.validate(legacy_result.data)
	_expect(migrated_again.ok and migrated_again.data == legacy_result.data, "normalized nested schema2 validation is idempotent")
	var wrong_legacy := legacy_nested_dto.duplicate(true)
	wrong_legacy.session_state.missions.coin_target = 7
	_expect(not SaveData.validate(wrong_legacy).ok, "legacy nested schema1 is accepted only with exact targets6/2")
	var legacy := state.duplicate(true)
	legacy.erase("missions")
	legacy.player.coins = 5
	legacy.score.role_counts = {"MIX":4, "PAIR":1, "STRAIGHT":1, "TRIPLE":0}
	var migrated: RefCounted = Session.new()
	_expect(migrated.restore_stable_snapshot(legacy, 30) and migrated.mission_state().coin_gained == 5 and migrated.mission_state().role_successes == 2 and migrated.mission_state().event_serial == 0, "legacy save migrates conservatively from balance, non-MIX roles, and HP without toast replay")


func _test_ui() -> void:
	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen: Node = PlayScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	var raster_path := OS.get_environment("DICE_QA_MISSION_RASTER")
	if not raster_path.is_empty():
		root.content_scale_size = Vector2i(720, 1280)
		root.size = Vector2i(360, 640)
		await process_frame
		await process_frame
		var raster := root.get_texture().get_image()
		if raster.get_size() != Vector2i(360, 640):
			raster.resize(360, 640, Image.INTERPOLATE_LANCZOS)
		_expect(raster.save_png(raster_path) == OK and raster.get_size() == Vector2i(360, 640), "optional QA raster records the real 360x640 viewport")
	var band := screen.get_node("%MissionBand") as Control
	var coin_label := screen.get_node("%MissionCoinLabel") as Label
	var no_damage_label := screen.get_node("%MissionNoDamageLabel") as Label
	var role_label := screen.get_node("%MissionRoleLabel") as Label
	var header := screen.get_node("%MissionHeader") as Label
	var toast := screen.get_node("%MissionToast") as Control
	var message := screen.get_node("%MessageLabel") as Label
	var shield_icon := screen.get_node("%MissionShieldIcon") as TextureRect
	var coin_icon := screen.get_node("%MissionCoinIcon") as TextureRect
	var role_icon := screen.get_node("%MissionRoleIcon") as TextureRect
	var cells: Array[Control] = [screen.get_node("%MissionNoDamageCell"), screen.get_node("%MissionCoinCell"), screen.get_node("%MissionRoleCell")]
	_expect(band.visible and header.text == "MISSION" and coin_label.text == "獲得0/12" and role_label.text == "0/5" and no_damage_label.text == "継続中" and not toast.visible, "horizontal mission strip makes cumulative coin acquisition explicit")
	_expect(shield_icon.texture != null and coin_icon.texture != null and role_icon.texture != null, "shield, coin, and die mission cells use real texture assets")
	_expect(band.custom_minimum_size.y <= 86.0 and band.get_theme_stylebox("panel") != null, "mission parchment stays within the safe 86px layout budget")
	var cell_widths := [cells[0].size.x, cells[1].size.x, cells[2].size.x]
	_expect(float(cell_widths.max()) - float(cell_widths.min()) <= 1.0, "mission strip gives all three cells equal width apart from one-pixel container rounding")
	for label: Label in [header, coin_label, role_label, no_damage_label]:
		_expect(label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_minimum_size().x <= label.size.x, "mission short copy does not wrap or truncate at the 360 layout scale")
	var session: RefCounted = screen.get("_session")
	session.call("_advance_coin_mission", 1)
	screen.call("_refresh_ui")
	_expect(not toast.visible and message.visible and message.text.contains("コイン獲得 1/12"), "operation band reports cumulative mission acquisition")
	session.call("_advance_coin_mission", 11)
	screen.call("_refresh_ui")
	_expect(coin_label.text == "✓ 12獲得" and message.text.contains("コイン獲得 12/12"), "completion uses cumulative-earned copy rather than wallet balance")
	session.call("_fail_no_damage_mission")
	screen.call("_refresh_ui")
	_expect(no_damage_label.text.contains("失敗") and not toast.visible and message.text.contains("無傷 失敗"), "failed no-damage row stays dimmed while the operation band announces it")
	var page := screen.get_node("SafeMargin/Page") as Control
	_expect(message.get_parent() == screen.get_node("%MessageBand") and page.is_ancestor_of(message), "transient announcement uses the fixed operation band inside the Page flow")
	message.text = "4マス進む"
	message.show()
	await process_frame
	var atlas := screen.get_node("%AtlasView") as Control
	_expect(page.get_global_rect().end.y <= screen.size.y and message.get_global_rect().end.y <= screen.size.y and atlas.size.y >= 450.0, "screen fits with a visible operation message while preserving the 450px atlas")
	_expect(message.autowrap_mode == TextServer.AUTOWRAP_OFF and message.get_minimum_size().x <= message.size.x, "visible movement announcement does not wrap or truncate at 360 scale")
	host.queue_free()
	await process_frame
	print("V06_MISSION_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failures += 1
		push_error("FAIL: %s" % message)
