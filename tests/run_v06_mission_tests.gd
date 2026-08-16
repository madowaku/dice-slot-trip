extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const SaveData = preload("res://scripts/game/v06_session_save_data.gd")
const PlayScreenScene = preload("res://scenes/app/V06PlayScreen.tscn")

var failures := 0


func _init() -> void:
	_test_progress_and_latches()
	_test_active_cairo_hooks()
	_test_risk6_survival_boundary_and_restore()
	_test_damage_victory_and_reset()
	_test_optional_save_and_legacy_migration()
	call_deferred("_test_ui")


func _test_progress_and_latches() -> void:
	var session: RefCounted = Session.new()
	session.call("_set_active_mission_for_test", "cairo_coin15")
	session.call("_advance_coin_mission", 5)
	session.call("_advance_coin_mission", 1)
	session.call("_advance_coin_mission", 8)
	var coin: Dictionary = session.mission_state()
	_expect(coin.schema_version == 2 and coin.coin_target == 12 and coin.role_target == 5 and coin.active_mission.progress == 12 and coin.active_mission.completed and coin.active_mission.reward_claimed and session.coins() == 12, "one selected coin mission reaches twelve and claims its reward once")
	var wallet_after_coin: int = session.coins()
	session.call("_award_role_score", &"MIX")
	_expect(session.coins() == wallet_after_coin and session.mission_state().role_successes == 0, "MIX has no normal SLOT reward and does not advance the role mission")
	session.call("_set_active_mission_for_test", "cairo_role")
	session.call("_award_role_score", &"PAIR")
	session.call("_award_role_score", &"STRAIGHT")
	session.call("_award_role_score", &"TRIPLE")
	_expect(session.mission_state().active_mission.progress == 1 and not session.mission_state().active_mission.completed, "only the selected target role advances the role mission")
	for _i: int in range(4): session.call("_award_role_score", &"TRIPLE")
	_expect(session.mission_state().active_mission.progress == 5 and session.mission_state().active_mission.completed and session.mission_state().active_mission.reward_claimed, "target role completion latches and grants the mission reward")


func _test_damage_victory_and_reset() -> void:
	var damaged: RefCounted = Session.new()
	damaged.call("_set_active_mission_for_test", "cairo_no_damage")
	damaged.call("_fail_no_damage_mission")
	damaged.call("_complete_no_damage_mission")
	_expect(not damaged.mission_state().no_damage_active and not damaged.mission_state().active_mission.completed and not damaged.mission_state().active_mission.reward_claimed, "damage failure latches and cannot be healed or completed")
	var victory: RefCounted = Session.new()
	victory.call("_set_active_mission_for_test", "cairo_no_damage")
	_expect(victory.enter_boss(0), "boss mission test enters race")
	for now: int in [1, 2, 3, 4]:
		victory.start_roll(6, now)
		if victory.phase() != Session.PHASE_BOSS_FINISHED:
			victory.acknowledge_boss_round()
	_expect(victory.boss_result().victory and victory.mission_state().active_mission.completed and victory.mission_state().active_mission.reward_claimed, "only terminal boss victory completes an active no-damage mission")
	_expect(victory.next_lap() and victory.resolve_active_missions().size() == 1 and victory.mission_state().active_mission.progress == 0 and not victory.mission_state().active_mission.completed, "successful next lap selects and resets one new mission")


func _test_active_cairo_hooks() -> void:
	for mission_id: String in ["cairo_face6", "cairo_face10"]:
		var faces: RefCounted = Session.new()
		faces.call("_set_active_mission_for_test", mission_id)
		for _i: int in range(int(faces.mission_state().active_mission.target) - 1): faces.call("_advance_face_mission", 4)
		var before_reward: int = faces.coins()
		faces.call("_advance_face_mission", 4)
		faces.call("_advance_face_mission", 4)
		_expect(faces.mission_state().active_mission.completed and faces.mission_state().active_mission.progress == faces.mission_state().active_mission.target and faces.coins() == before_reward + int(faces.mission_state().active_mission.reward_coins), "%s target hit caps and rewards once" % mission_id)
	var small: RefCounted = Session.new()
	small.call("_set_active_mission_for_test", "cairo_small_faces")
	small.call("_advance_face_mission", 4)
	_expect(small.mission_state().active_mission.progress == 0, "small_faces does not count the default target_face value four")
	for face: int in [1, 2, 3]:
		for _i: int in range(4): small.call("_advance_face_mission", face)
	var small_state: Dictionary = small.mission_state()
	var small_save: Dictionary = small.stable_save_snapshot(0)
	var small_restored: RefCounted = Session.new()
	_expect(small_state.active_mission.face_counters == {"1":4, "2":4, "3":4} and small_state.active_mission.completed and small_restored.restore_stable_snapshot(small_save) and small_restored.mission_state().active_mission.face_counters == {"1":4, "2":4, "3":4}, "small_faces counts each 1/2/3 four times and round-trips")
	for role_case: Array in [["cairo_pair4", &"PAIR"], ["cairo_straight4", &"STRAIGHT"], ["cairo_triple3", &"TRIPLE"]]:
		var role_session: RefCounted = Session.new()
		role_session.call("_set_active_mission_for_test", role_case[0])
		for _i: int in range(int(role_session.mission_state().active_mission.target)): role_session.call("_award_role_score", role_case[1])
		var normal_slot_coins: int = 4 if role_case[1] == &"PAIR" else (12 if role_case[1] == &"STRAIGHT" else 15)
		_expect(role_session.mission_state().active_mission.completed and role_session.coins() == normal_slot_coins + int(role_session.mission_state().active_mission.reward_coins), "%s progress is separate from normal SLOT coins" % role_case[0])
	var coin_landing: RefCounted = Session.new()
	coin_landing.call("_set_active_mission_for_test", "cairo_coin3")
	for _i: int in range(3): coin_landing.call("_record_cairo_landing", "COIN", {})
	_expect(coin_landing.mission_state().active_mission.completed, "coin3 advances on COIN landings")
	coin_landing.call("_set_active_mission_for_test", "cairo_coin5")
	for _i: int in range(5): coin_landing.call("_record_cairo_landing", "COIN", {})
	_expect(coin_landing.mission_state().active_mission.completed, "coin5 advances on COIN landings")
	var item: RefCounted = Session.new()
	item.call("_set_active_mission_for_test", "cairo_item2")
	item.call("_record_cairo_landing", "ITEM", {"item_id":"water_canteen"})
	item.call("_record_cairo_landing", "ITEM", {"converted_to_coins":2})
	_expect(item.mission_state().active_mission.progress == 1, "item2 counts actual ITEM acquisition but not full-inventory conversion")
	var risk: RefCounted = Session.new()
	risk.call("_set_active_mission_for_test", "cairo_risk4")
	for _i: int in range(4): risk.call("_record_cairo_landing", "RISK", {})
	_expect(risk.mission_state().active_mission.completed, "risk4 counts RISK landings")
	risk.call("_set_active_mission_for_test", "cairo_risk6_survive")
	for _i: int in range(5): risk.call("_record_cairo_landing", "RISK", {})
	var risk_state: Dictionary = risk.stable_save_snapshot(0)
	risk_state.player.hp = 0
	var risk_zero: RefCounted = Session.new()
	_expect(risk_zero.restore_stable_snapshot(risk_state) and risk_zero.call("_record_cairo_landing", "RISK", {}) == null and risk_zero.mission_state().active_mission.progress == 5, "risk6 does not count a zero-HP landing")
	var boss: RefCounted = Session.new()
	boss.call("_set_active_mission_for_test", "cairo_hp_full_boss")
	var boss_state: Dictionary = boss.stable_save_snapshot(0)
	boss_state.route.tile_index = 89
	boss_state.route.current_node_id = "main:89"
	var boss_restored: bool = boss.restore_stable_snapshot(boss_state)
	boss.call("_set_active_mission_for_test", "cairo_hp_full_boss")
	boss.call("_set_active_mission_progress", 1, "boss_gate")
	_expect(boss_restored and boss.mission_state().active_mission.completed, "hp_full_boss completes at the normal boss-gate boundary")


func _test_risk6_survival_boundary_and_restore() -> void:
	var pending: RefCounted = Session.new()
	pending.call("_set_active_mission_for_test", "cairo_risk6_survive")
	for _i: int in range(6): pending.call("_record_cairo_landing", "RISK", {})
	var pending_mission: Dictionary = pending.mission_state().active_mission
	_expect(pending_mission.progress == 6 and not pending_mission.completed and not pending_mission.reward_claimed and pending.coins() == 0 and not pending_mission.survival_failed, "risk6 reaches six safe landings as pending progress without reward")
	var pending_state: Dictionary = pending.stable_save_snapshot(0)
	var pending_restored: RefCounted = Session.new()
	var pending_save_result: Dictionary = SaveData.validate(_mission_dto(pending_state))
	_expect(pending_save_result.ok and pending_restored.restore_stable_snapshot(pending_state, 0) and pending_restored.mission_state().active_mission.progress == 6 and not pending_restored.mission_state().active_mission.completed and not pending_restored.mission_state().active_mission.reward_claimed and not pending_restored.mission_state().active_mission.survival_failed, "schema2 restore preserves pending risk6 state and exposes failed=false")
	var risk_reward_coins: int = int(pending_restored.mission_state().active_mission.reward_coins)
	_expect(risk_reward_coins == 18 and _finish_boss_victory(pending_restored) and pending_restored.next_lap() and pending_restored.coins() == 0, "successful boss victory lap boundary finalizes the configured risk6 +18 reward before wallet reset")
	var rewarded_coins: int = pending_restored.coins()
	_expect(not pending_restored.next_lap() and pending_restored.coins() == rewarded_coins, "repeating next_lap cannot duplicate the risk6 reward")
	var post_boundary: RefCounted = Session.new()
	var post_state: Dictionary = pending_restored.stable_save_snapshot(0)
	_expect(post_boundary.restore_stable_snapshot(post_state, 0) and not post_boundary.next_lap() and post_boundary.coins() == rewarded_coins, "restoring the post-boundary save cannot replay the risk6 reward")

	var hp0_fixture: RefCounted = Session.new()
	hp0_fixture.call("_set_active_mission_for_test", "cairo_risk6_survive")
	for _i: int in range(5): hp0_fixture.call("_record_cairo_landing", "RISK", {})
	var hp0_state: Dictionary = hp0_fixture.stable_save_snapshot(0)
	hp0_state.phase = "RESOLUTION_REQUIRED"
	hp0_state.player.hp = 0
	var failed: RefCounted = Session.new()
	_expect(failed.restore_stable_snapshot(hp0_state, 0) and failed.call("_record_cairo_landing", "RISK", {}) == null and failed.mission_state().active_mission.survival_failed and failed.mission_state().active_mission.progress == 5, "HP0 RISK landing latches risk6 failure without advancing progress")
	var failed_state: Dictionary = failed.stable_save_snapshot(0)
	var failed_restored: RefCounted = Session.new()
	var failed_save_result: Dictionary = SaveData.validate(_mission_dto(failed_state))
	_expect(failed_save_result.ok and failed_restored.restore_stable_snapshot(failed_state, 0) and failed_restored.mission_state().active_mission.survival_failed and not failed_restored.mission_state().active_mission.completed and not failed_restored.mission_state().active_mission.reward_claimed, "schema2 restore preserves failed risk6 without reward")
	var failed_ready_state: Dictionary = failed_state.duplicate(true)
	failed_ready_state.phase = "READY"
	failed_ready_state.player.hp = 3
	var failed_ready: RefCounted = Session.new()
	_expect(failed_ready.restore_stable_snapshot(failed_ready_state, 0), "failed risk6 restores at a safe READY boundary")
	failed_ready.call("_record_cairo_landing", "RISK", {})
	_expect(failed_ready.mission_state().active_mission.progress == 5 and failed_ready.mission_state().active_mission.survival_failed and _finish_boss_victory(failed_ready) and failed_ready.next_lap() and failed_ready.coins() == 0, "failed risk6 ignores later safe landings and boss victory")


func _finish_boss_victory(session: RefCounted) -> bool:
	if not session.enter_boss(0):
		return false
	for now: int in [1, 2, 3, 4]:
		if session.phase() == Session.PHASE_BOSS_FINISHED:
			break
		if not bool(session.start_roll(6, now).get("ok", false)):
			return false
		if session.phase() != Session.PHASE_BOSS_FINISHED and not session.acknowledge_boss_round():
			return false
	return bool(session.boss_result().get("victory", false))


func _mission_dto(state: Dictionary) -> Dictionary:
	return {"schema_version": SaveData.SCHEMA_VERSION, "course_version": SaveData.COURSE_VERSION, "app_version":"v0.8", "saved_at":"now", "saved_at_unix":0, "stage_id":"cairo_hourglass", "character_id":"relaxed", "session_state":state, "pending_transaction":null}


func _test_optional_save_and_legacy_migration() -> void:
	var session: RefCounted = Session.new()
	session.call("_set_active_mission_for_test", "cairo_coin15")
	session.call("_advance_coin_mission", 7)
	session.call("_award_role_score", &"PAIR")
	var state: Dictionary = session.stable_save_snapshot(10)
	var dto := {"schema_version": SaveData.SCHEMA_VERSION, "course_version":SaveData.COURSE_VERSION, "app_version":"v0.8", "saved_at":"now", "saved_at_unix":0, "stage_id":"cairo_hourglass", "character_id":"relaxed", "session_state":state, "pending_transaction":null}
	var schema2_result: Dictionary = SaveData.validate(dto)
	_expect(schema2_result.ok and schema2_result.data.session_state.missions.schema_version == 2 and schema2_result.data.session_state.missions.coin_target == 12 and schema2_result.data.session_state.missions.role_target == 5, "outer schema2 save accepts exact nested mission schema2 and course version")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(state, 20) and restored.mission_state().active_mission.id == "cairo_coin15" and restored.mission_state().active_mission.progress == 8 and restored.mission_state().active_mission.reward_claimed == false and restored.mission_state().event_serial == state.missions.event_serial, "nested schema2 mission selection, progress, and reward claim round-trip without replaying an event")
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
	var session: RefCounted = screen.get("_session")
	session.call("_set_active_mission_for_test", "cairo_face6")
	screen.call("_refresh_ui")
	var face_caption := screen.get_node("SafeMargin/Page/MissionBand/MissionStrip/MissionNoDamageCell/Content/Copy/Caption") as Label
	_expect(face_caption.text.begins_with("DICE ") and face_caption.text.contains("を6回出す"), "seeded face mission card shows its exact target and keeps the legacy mission card")
	session.call("_set_active_mission_for_test", "cairo_small_faces")
	screen.call("_refresh_ui")
	_expect(face_caption.text.contains("1・2・3を各4回出す") and not face_caption.text.contains("DICE 4を12回出す") and not bool((session.mission_state().get("active_mission", {}) as Dictionary).get("target_face_enabled", true)), "small-face mission card keeps its three-face rule instead of displaying the internal default target face")
	session.call("_set_active_mission_for_test", "cairo_coin15")
	screen.call("_refresh_ui")
	_expect(band.visible and header.text == "MISSION" and face_caption.text.contains("COIN × 12") and no_damage_label.text.contains("進捗 0/12") and no_damage_label.text.contains("○".repeat(12)) and not no_damage_label.text.contains("COIN") and cells[0].visible and not cells[1].visible and not cells[2].visible and not toast.visible, "single featured mission card puts the COIN reward on the upper line and target-sized dots on the progress line")
	session.call("_set_active_mission_for_test", "cairo_pair4")
	screen.call("_refresh_ui")
	_expect(face_caption.text.contains("COIN × 8") and no_damage_label.text.contains("進捗 0/4") and no_damage_label.text.contains("○○○○") and not no_damage_label.text.contains("○○○○○"), "mission progress dots match the required count and the upper line names the COIN reward")
	session.call("_set_active_mission_for_test", "cairo_coin15")
	screen.call("_refresh_ui")
	_expect(shield_icon.texture != null and coin_icon.texture != null and role_icon.texture != null, "shield, coin, and die mission cells use real texture assets")
	_expect(band.custom_minimum_size.y >= 120.0 and band.custom_minimum_size.y <= 124.0 and band.get_theme_stylebox("panel") != null, "mission parchment uses the enlarged 120px layout budget")
	_expect(header.get_theme_font_size("font_size") >= 24 and no_damage_label.get_theme_font_size("font_size") >= 22 and face_caption.get_theme_font_size("font_size") >= 20, "mission labels use the enlarged elder-friendly type scale")
	for label: Label in [header, coin_label, role_label, no_damage_label, face_caption]:
		_expect(label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_minimum_size().x <= label.size.x, "mission short copy does not wrap or truncate at the 360 layout scale")
	session.call("_advance_coin_mission", 1)
	screen.call("_refresh_ui")
	_expect(not toast.visible and message.visible and message.text.contains("コインを12枚集める") and message.text.contains("1/12"), "operation band reports featured mission progress")
	session.call("_advance_coin_mission", 11)
	screen.call("_refresh_ui")
	_expect(face_caption.text.contains("COIN × 12") and no_damage_label.text.contains("CLEAR") and no_damage_label.text.contains("COIN +12") and message.text.contains("MISSION CLEAR"), "completion keeps the upper-line COIN reward and adds explicit clear copy")
	session.call("_set_active_mission_for_test", "cairo_no_damage")
	session.call("_fail_no_damage_mission")
	screen.call("_refresh_ui")
	_expect(no_damage_label.text.contains("失敗") and not toast.visible and message.text.contains("MISSION FAILED"), "failed featured mission stays dimmed while the operation band announces it")
	var page := screen.get_node("SafeMargin/Page") as Control
	_expect(message.get_parent() == screen.get_node("%MessageBand") and page.is_ancestor_of(message), "transient announcement uses the fixed operation band inside the Page flow")
	message.text = "4マス進む"
	message.show()
	await process_frame
	var atlas := screen.get_node("%AtlasView") as Control
	_expect(page.get_global_rect().end.y <= screen.size.y and message.get_global_rect().end.y <= screen.size.y and atlas.size.y >= 440.0, "screen fits with a visible operation message while preserving the 440px atlas")
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
