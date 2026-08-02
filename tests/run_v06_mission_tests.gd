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
	session.call("_advance_coin_mission", 14)
	session.call("_advance_coin_mission", 1)
	session.call("_advance_coin_mission", 8)
	var coin: Dictionary = session.mission_state()
	_expect(coin.coin_gained == 23 and coin.coin_completed, "gross coin progress keeps increasing and latches at 15")
	session.call("_award_role_score", &"MIX")
	_expect(session.mission_state().role_successes == 0 and session.mission_state().coin_gained == 24, "MIX adds gross coin and is excluded from role mission")
	session.call("_award_role_score", &"PAIR")
	session.call("_award_role_score", &"STRAIGHT")
	session.call("_award_role_score", &"TRIPLE")
	_expect(session.mission_state().role_successes == 3 and session.mission_state().role_completed, "PAIR, STRAIGHT, and TRIPLE increment and role completion latches at two")


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
	var dto := {"schema_version": SaveData.SCHEMA_VERSION, "app_version":"v0.8", "saved_at":"now", "saved_at_unix":0, "stage_id":"cairo_hourglass", "character_id":"relaxed", "session_state":state, "pending_transaction":null}
	_expect(SaveData.validate(dto).ok, "schema-v1 save accepts the optional mission object")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(state, 20) and restored.mission_state().coin_gained == 7 and restored.mission_state().role_successes == 1, "mission state round-trips without replaying an event")
	var legacy := state.duplicate(true)
	legacy.erase("missions")
	legacy.player.coins = 5
	legacy.score.role_counts = {"MIX":4, "PAIR":1, "STRAIGHT":1, "TRIPLE":0}
	var migrated: RefCounted = Session.new()
	_expect(migrated.restore_stable_snapshot(legacy, 30) and migrated.mission_state().coin_gained == 5 and migrated.mission_state().role_successes == 2 and migrated.mission_state().event_serial == 0, "legacy save migrates conservatively from balance, non-MIX roles, and HP without toast replay")


func _test_ui() -> void:
	var screen: Node = PlayScreenScene.instantiate()
	root.add_child(screen)
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
	var shield_icon := screen.get_node("%MissionShieldIcon") as TextureRect
	var coin_icon := screen.get_node("%MissionCoinIcon") as TextureRect
	var role_icon := screen.get_node("%MissionRoleIcon") as TextureRect
	var cells: Array[Control] = [screen.get_node("%MissionNoDamageCell"), screen.get_node("%MissionCoinCell"), screen.get_node("%MissionRoleCell")]
	_expect(band.visible and header.text == "MISSION" and coin_label.text == "0/15" and role_label.text == "0/2" and no_damage_label.text == "継続中" and not toast.visible, "horizontal mission strip renders approved short copy without initial toast replay")
	_expect(shield_icon.texture != null and coin_icon.texture != null and role_icon.texture != null, "shield, coin, and die mission cells use real texture assets")
	_expect(band.custom_minimum_size.y <= 86.0 and band.get_theme_stylebox("panel") != null, "mission parchment stays within the safe 86px layout budget")
	var cell_widths := [cells[0].size.x, cells[1].size.x, cells[2].size.x]
	_expect(float(cell_widths.max()) - float(cell_widths.min()) <= 1.0, "mission strip gives all three cells equal width apart from one-pixel container rounding")
	for label: Label in [header, coin_label, role_label, no_damage_label]:
		_expect(label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_minimum_size().x <= label.size.x, "mission short copy does not wrap or truncate at the 360 layout scale")
	var session: RefCounted = screen.get("_session")
	session.call("_advance_coin_mission", 1)
	screen.call("_refresh_ui")
	_expect(toast.visible and (screen.get_node("%MissionToastLabel") as Label).text.contains("コイン 1/15"), "mission progress toast reports the actual capped current value and target")
	session.call("_advance_coin_mission", 14)
	screen.call("_refresh_ui")
	_expect(coin_label.text == "✓ 達成" and (screen.get_node("%MissionToastLabel") as Label).text.contains("コイン 15/15"), "completion uses the gold check stamp and capped target toast")
	session.call("_fail_no_damage_mission")
	screen.call("_refresh_ui")
	_expect(no_damage_label.text.contains("失敗") and toast.visible, "failed no-damage row remains visible and dimmed")
	var message := screen.get_node("%MessageLabel") as Label
	var page := screen.get_node("SafeMargin/Page") as Control
	_expect(message.get_parent() == screen and not page.is_ancestor_of(message), "transient announcement is parented outside the Page VBox flow")
	message.text = "4マス進む"
	message.show()
	await process_frame
	var atlas := screen.get_node("%AtlasView") as Control
	_expect(page.get_global_rect().end.y <= 1280.0 and message.get_global_rect().end.y <= 1280.0 and atlas.size.y >= 450.0, "root fits with a visible transient message while preserving the 450px atlas")
	_expect(message.autowrap_mode == TextServer.AUTOWRAP_OFF and message.get_minimum_size().x <= message.size.x, "visible movement announcement does not wrap or truncate at 360 scale")
	root.remove_child(screen)
	screen.free()
	print("V06_MISSION_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failures += 1
		push_error("FAIL: %s" % message)
