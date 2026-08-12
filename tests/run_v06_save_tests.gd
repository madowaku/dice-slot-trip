extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const Course = preload("res://scripts/game/v06_course_model.gd")
const SaveData = preload("res://scripts/game/v06_session_save_data.gd")
const SaveManager = preload("res://scripts/game/v06_session_save_manager.gd")

const TEST_PATH := "user://v06_session_1b_test.json"

var failures := 0


func _init() -> void:
	_cleanup()
	_test_new_save_round_trip()
	_test_three_roll_onboarding_lifetime()
	_test_skill_ready_discovery_flag_validation()
	_test_stable_slot_sizes_and_states()
	_test_branch_loop_and_warp_restore()
	_test_boss_restore()
	_test_backup_recovery()
	_test_corrupt_and_incompatible_results()
	_test_write_failure_preserves_primary()
	_test_fault_injection_and_atomic_boundaries()
	_test_primary_backup_combinations_and_stale_temp()
	_test_semantic_dto_rejection()
	_test_schema2_roulette_arithmetic()
	_test_schema1_course_migration_contract()
	_test_active_event_semantic_validation()
	_test_challenge_score_and_hp0_migration()
	_test_stable_boundary_and_deep_copy_contracts()
	_test_tomb_loop_restore()
	_test_old_save_is_separate_and_load_is_idempotent()
	_cleanup()
	print("V06_SAVE_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_new_save_round_trip() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new(&"", &"")
	var empty: Dictionary = manager.load_result()
	_expect(not empty.ok and empty.status == SaveManager.STATUS_NO_SAVE, "missing V06 primary and backup return NO_SAVE")
	var saved: Dictionary = manager.save_session(session)
	var loaded: Dictionary = manager.load_result()
	_expect(saved.ok and saved.status == SaveManager.STATUS_SAVED, "new stable V06 session saves")
	_expect(loaded.ok and loaded.status == SaveManager.STATUS_VALID_PRIMARY, "primary V06 save loads as valid")
	var data: Dictionary = loaded.data
	_expect(data.schema_version == SaveData.SCHEMA_VERSION and data.stage_id == "cairo_hourglass" and data.character_id == "relaxed", "schema, stage, and relaxed default round-trip")
	var restored: RefCounted = Session.new(StringName(data.stage_id), StringName(data.character_id))
	_expect(restored.restore_stable_snapshot(data.session_state, 1000) and restored.phase() == Session.PHASE_READY and restored.position() == {"route_id":"main", "tile_index":0}, "stable READY state restores without movement residue")
	_expect(restored.score() == session.score() and restored.coins() == session.coins() and restored.visited_node_keys() == session.visited_node_keys(), "reloading a checkpoint does not duplicate score, coins, or visits")
	var state: Dictionary = data.session_state
	state.player.inventory = {"compass": 1}
	state.player.item_consumption = {"compass": true}
	state.player.stage_flags = {"cairo_intro_seen": true}
	state.player.skill_state = "ARMED"
	var altered := data.duplicate(true)
	altered.session_state = state
	_expect(SaveData.validate(altered).ok, "inventory, stage flags, and ARMED are accepted as future-compatible DTO data")
	var altered_session: RefCounted = Session.new(StringName(altered.stage_id), StringName(altered.character_id))
	_expect(altered_session.restore_stable_snapshot(altered.session_state, 2000) and altered_session.inventory().get("compass", 0) == 1 and altered_session.item_consumption().get("compass", false) and altered_session.skill_state() == Session.SKILL_STATE_ARMED, "future-compatible player fields restore without adding an effect")


func _test_three_roll_onboarding_lifetime() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new()
	_expect(not session.has_seen_three_roll_onboarding() and session.is_untouched_journey_start(), "a new journey is unseen and eligible at the untouched start")
	session.mark_three_roll_onboarding_seen()
	_expect(manager.save_session(session).ok, "onboarding dismissal is stable-save eligible")
	var loaded: Dictionary = manager.load_result()
	var restored: RefCounted = Session.new()
	_expect(loaded.ok and restored.restore_stable_snapshot(loaded.data.session_state, 1000) and restored.has_seen_three_roll_onboarding(), "onboarding seen flag round-trips through the save slot")
	_expect(restored.retry_run() and restored.has_seen_three_roll_onboarding(), "retry preserves the journey onboarding seen flag")
	var lap_session: RefCounted = Session.new()
	lap_session.mark_three_roll_onboarding_seen()
	_expect(lap_session.enter_boss(0), "next-lap onboarding setup enters the boss")
	for now: int in [1, 2, 3, 4]:
		lap_session.start_roll(6, now)
		if lap_session.phase() != Session.PHASE_BOSS_FINISHED:
			lap_session.acknowledge_boss_round()
	_expect(lap_session.next_lap() and lap_session.has_seen_three_roll_onboarding(), "next lap preserves the journey onboarding seen flag")
	var progressed: RefCounted = Session.new()
	_roll_and_finish(progressed, 1)
	_expect(not progressed.is_untouched_journey_start(), "a progressed READY journey is not onboarding eligible")
	_expect(not Session.new().has_seen_three_roll_onboarding(), "an explicit new journey starts unseen")


func _test_skill_ready_discovery_flag_validation() -> void:
	var session: RefCounted = Session.new()
	session.mark_skill_ready_discovery_seen()
	var dto: Dictionary = SaveData.from_session(session)
	_expect(SaveData.validate(dto).ok and bool(dto.session_state.player.stage_flags.get(Session.STAGE_FLAG_SKILL_READY_DISCOVERY_SEEN, false)), "skill READY discovery seen flag is persisted as schema2 durable state")
	var invalid := dto.duplicate(true)
	invalid.session_state.player.stage_flags[Session.STAGE_FLAG_SKILL_READY_DISCOVERY_SEEN] = 1
	_expect(not SaveData.validate(invalid).ok, "skill READY discovery seen flag rejects non-boolean save data")


func _test_stable_slot_sizes_and_states() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new()
	var initial: Dictionary = manager.save_session(session)
	_expect(initial.ok and initial.data.session_state.slot.current_roll_index == 0, "slot zero is a valid stable checkpoint")
	_roll_and_finish(session, 2)
	var one: Dictionary = manager.save_session(session)
	_expect(one.ok and one.data.session_state.slot.current_roll_index == 1, "slot one is saved after landing")
	_roll_and_finish(session, 1)
	var two: Dictionary = manager.save_session(session)
	_expect(two.ok and two.data.session_state.slot.current_roll_index == 2, "slot two is saved before the third face")
	_set_main_fixture(session, 29, [2, 1])
	_roll_and_finish(session, 1)
	_expect(session.phase() == Session.PHASE_EVENT_REQUIRED and session.active_event().return_phase == "RESOLUTION_REQUIRED", "third-face EVENT is the stable boundary before role acknowledgement")
	var event_checkpoint: Dictionary = manager.save_session(session)
	_expect(event_checkpoint.ok and event_checkpoint.data.session_state.active_event.event_id == "market_hawker", "EVENT_REQUIRED persists its active narrative card")
	_expect(session.acknowledge_event() and session.phase() == Session.PHASE_RESOLUTION_REQUIRED, "EVENT acknowledgement returns to the queued role exactly once")
	_expect(session.acknowledge_resolution(), "travel resolution acknowledges to a stable state")
	var three_after_resolution: Dictionary = manager.save_session(session)
	_expect(three_after_resolution.ok and three_after_resolution.data.session_state.slot.current_roll_index == 0, "post-resolution travel checkpoint clears the consumed three-slot set")
	var ready_skill: RefCounted = Session.new()
	_roll_and_finish(ready_skill, 1)
	_roll_and_finish(ready_skill, 1)
	_roll_and_finish(ready_skill, 1)
	ready_skill.acknowledge_resolution()
	var ready_skill_save: Dictionary = manager.save_session(ready_skill)
	_expect(ready_skill_save.ok and ready_skill_save.data.session_state.player.skill_state == "READY" and ready_skill_save.data.session_state.player.skill_gauge == 3, "READY skill state survives a stable checkpoint")

	var boss: RefCounted = Session.new()
	_expect(boss.enter_boss(0), "boss-ready state is enterable for save testing")
	var boss_saved: Dictionary = manager.save_session(boss)
	_expect(boss_saved.ok and boss_saved.data.session_state.slot.current_roll_index == 0 and boss_saved.data.session_state.player.skill_state == "CHARGING", "boss-ready state preserves empty slots and charging state")
	boss.start_roll(2, 2)
	var boss_partial_save: Dictionary = manager.save_session(boss)
	var boss_partial_loaded: Dictionary = manager.load_result()
	_expect(boss_partial_save.ok and boss_partial_loaded.ok and boss_partial_loaded.data.session_state.slot.current_roll_index == 1 and boss_partial_loaded.data.session_state.boss.pending_ack, "completed boss turn saves the first boss SLOT face")
	boss = Session.new()
	_expect(boss.enter_boss(0), "boss slot test re-enters a fresh battle")
	for face: int in [6, 6, 6, 6]:
		if boss.phase() == Session.PHASE_BOSS_FINISHED:
			break
		boss.start_roll(face, face)
		if boss.phase() != Session.PHASE_BOSS_FINISHED:
			boss.acknowledge_boss_round()
	_expect(boss.phase() == Session.PHASE_BOSS_FINISHED, "terminal boss result is a stable slot boundary")
	var boss_result_saved: Dictionary = manager.save_session(boss)
	_expect(boss_result_saved.ok and boss_result_saved.data.session_state.slot.current_roll_index == 0 and int(boss_result_saved.data.session_state.score.role_counts.get("TRIPLE", 0)) == 1, "terminal boss result persists the resolved boss role and reset slot")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(boss_result_saved.data.session_state, 1000) and restored.phase() == Session.PHASE_BOSS_FINISHED and restored.faces() == boss.faces(), "FINISHED slot result restores exactly")


func _test_branch_loop_and_warp_restore() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var branch: RefCounted = Session.new()
	_set_main_fixture(branch, 32, [6, 5])
	branch.start_roll(4)
	_consume_hops(branch)
	var choice: Dictionary = branch.finish_movement()
	_expect(choice.status == "CHOICE_REQUIRED" and branch.is_stable_for_save() and branch.pending_remaining_steps() == 4, "branch choice and remaining movement are stable")
	var branch_save: Dictionary = manager.save_session(branch)
	var branch_restored: RefCounted = Session.new()
	_expect(branch_save.ok and branch_restored.restore_stable_snapshot(branch_save.data.session_state, 1000) and branch_restored.phase() == Session.PHASE_CHOICE_REQUIRED and branch_restored.pending_remaining_steps() == 4 and branch_restored.pending_face() == 4, "branch choice restores with the held face and remaining steps")
	_expect(branch_restored.choose_route(Course.ROUTE_BYPASS_BAZAAR).ok, "restored branch can continue through the selected bypass")
	_consume_hops(branch_restored)
	branch_restored.finish_movement()
	if branch_restored.phase() == Session.PHASE_RESOLUTION_REQUIRED:
		branch_restored.acknowledge_resolution()
	var bypass_save: Dictionary = manager.save_session(branch_restored)
	_expect(bypass_save.ok and "bypass_bazaar_alley:3" in bypass_save.data.session_state.route.visited_node_keys and "bypass_clear:bypass_bazaar_alley" not in bypass_save.data.session_state.route.awarded_score_event_ids, "bypass route history persists without a hidden completion bonus")

	var loop: RefCounted = Session.new()
	_set_main_fixture(loop, 23, [6, 3])
	_roll_and_finish(loop, 1)
	_expect(loop.active_warp_gate_id() == "W1" and "W1" in loop.consumed_warp_gate_ids(), "warp consumption settles with the warp destination")
	_expect(loop.acknowledge_resolution(), "warp travel role acknowledges before the ring roll")
	var loop_save: Dictionary = manager.save_session(loop)
	var loop_restored: RefCounted = Session.new()
	_expect(loop_save.ok and loop_save.data.session_state.route.loop_id == Course.ROUTE_LOOP_OASIS and loop_restored.restore_stable_snapshot(loop_save.data.session_state, 1000) and loop_restored.position() == loop.position() and "W1" in loop_restored.consumed_warp_gate_ids(), "oasis ring position and consumed warp restore without retrigger")


func _test_boss_restore() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new()
	_expect(session.enter_boss(0), "boss start is a stable checkpoint")
	var start: Dictionary = manager.save_session(session)
	var restored_start: RefCounted = Session.new()
	_expect(start.ok and restored_start.restore_stable_snapshot(start.data.session_state, 1000) and restored_start.phase() == Session.PHASE_BOSS_ROLL_READY and restored_start.boss_snapshot().round == 1, "boss start restores the current boss turn")
	session.start_roll(4, 1)
	var round_save: Dictionary = manager.save_session(session)
	var restored_round: RefCounted = Session.new()
	_expect(round_save.ok and restored_round.restore_stable_snapshot(round_save.data.session_state, 1000) and restored_round.phase() == Session.PHASE_BOSS_ROUND_RESULT and restored_round.boss_snapshot().pending_ack, "boss round result restores its pending acknowledgement")
	var victory: RefCounted = Session.new()
	_set_player_hp(victory, 1)
	victory.enter_boss(0)
	for now: int in [1, 2, 3, 4]:
		if victory.phase() == Session.PHASE_BOSS_FINISHED:
			break
		victory.start_roll(6, now)
		if victory.phase() != Session.PHASE_BOSS_FINISHED:
			victory.acknowledge_boss_round()
	var victory_save: Dictionary = manager.save_session(victory)
	var victory_restored: RefCounted = Session.new()
	_expect(victory.phase() == Session.PHASE_BOSS_FINISHED and victory_save.ok and victory_restored.restore_stable_snapshot(victory_save.data.session_state, 1000) and victory_restored.boss_result().victory and victory_restored.heart_roulette_pending(), "boss victory and pending heart roulette restore before the next journey")
	var heart_reward: Dictionary = victory_restored.resolve_heart_roulette(1)
	var heart_save: Dictionary = manager.save_session(victory_restored)
	var heart_restored: RefCounted = Session.new()
	_expect(heart_reward.ok and heart_save.ok and heart_restored.restore_stable_snapshot(heart_save.data.session_state, 1000) and heart_restored.player_max_hp() == 3 and heart_restored.player_hp() == 3 and not heart_restored.heart_roulette_pending(), "resolved HP-only reward survives save and restore")
	_expect(victory.acknowledge_boss_round(), "legacy boss result acknowledgement reaches LAP_RESULT")
	var lap_result_save: Dictionary = manager.save_session(victory)
	var lap_result_restored: RefCounted = Session.new()
	_expect(lap_result_save.ok and lap_result_restored.restore_stable_snapshot(lap_result_save.data.session_state, 1000) and lap_result_restored.phase() == Session.PHASE_LAP_RESULT, "LAP_RESULT restores after terminal boss acknowledgement")
	var defeat: RefCounted = Session.new()
	defeat.enter_boss(0)
	for now: int in range(1, 12):
		if defeat.phase() == Session.PHASE_BOSS_FINISHED:
			break
		defeat.start_roll(1, now)
		if defeat.phase() != Session.PHASE_BOSS_FINISHED:
			defeat.acknowledge_boss_round()
	_expect(defeat.phase() == Session.PHASE_BOSS_FINISHED and defeat.acknowledge_boss_round() and defeat.phase() == Session.PHASE_LAP_RESULT, "boss defeat FINISHED result records the loss and completes the stage")
	var loss_save: Dictionary = manager.save_session(defeat)
	var loss_restored: RefCounted = Session.new()
	_expect(loss_save.ok and loss_restored.restore_stable_snapshot(loss_save.data.session_state, 1000) and loss_restored.phase() == Session.PHASE_LAP_RESULT and loss_restored.boss_snapshot().defeat, "losing race LAP_RESULT restores without requesting a retry")


func _test_backup_recovery() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var first: RefCounted = Session.new(&"cairo_hourglass", &"relaxed")
	_expect(manager.save_session(first).ok, "first checkpoint creates primary")
	var second: RefCounted = Session.new(&"cairo_hourglass", &"gambler")
	_roll_and_finish(second, 2)
	_expect(manager.save_session(second).ok and FileAccess.file_exists(manager.backup_path), "second checkpoint rotates the prior primary to backup")
	_write(manager.save_path, "{not-json")
	var recovered: Dictionary = manager.load_result()
	_expect(recovered.ok and recovered.status == SaveManager.STATUS_RECOVERED_BACKUP and recovered.data.character_id == "relaxed", "corrupt primary recovers the valid backup without rewriting primary")


func _test_corrupt_and_incompatible_results() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	_write(manager.save_path, "{not-json")
	_write(manager.backup_path, "also-not-json")
	var corrupt: Dictionary = manager.load_result()
	_expect(not corrupt.ok and corrupt.status == SaveManager.STATUS_CORRUPT, "corrupt primary and backup return CORRUPT safely")
	_cleanup()
	_write(manager.save_path, JSON.stringify({"schema_version": 999}))
	var incompatible: Dictionary = manager.load_result()
	_expect(not incompatible.ok and incompatible.status == SaveManager.STATUS_INCOMPATIBLE_VERSION, "unsupported schema version is rejected explicitly")
	_expect(not manager.has_valid_save(), "invalid V06 data does not enable continue")


func _test_write_failure_preserves_primary() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new()
	_expect(manager.save_session(session).ok, "write-failure setup has a valid primary")
	var before: Dictionary = manager.load_result()
	manager.temp_path = "user://missing_v06_session_1b_directory/checkpoint.tmp"
	var failed: Dictionary = manager.save_session(Session.new(&"cairo_hourglass", &"gambler"))
	var after: Dictionary = manager.load_result()
	_expect(not failed.ok and failed.status == SaveManager.STATUS_WRITE_FAILED and after.ok and after.status == SaveManager.STATUS_VALID_PRIMARY and after.data.character_id == before.data.character_id, "temporary write failure leaves the prior primary intact")


func _test_fault_injection_and_atomic_boundaries() -> void:
	var temp_faults: Array[String] = ["fail_temp_open", "fail_temp_write", "fail_temp_flush", "fail_temp_close", "fail_temp_parse", "fail_temp_validation"]
	for fault: String in temp_faults:
		_cleanup()
		var manager: RefCounted = SaveManager.new(TEST_PATH)
		_expect(manager.save_session(Session.new(&"cairo_hourglass", &"relaxed")).ok, "%s setup has a valid primary" % fault)
		_expect(manager.save_session(Session.new(&"cairo_hourglass", &"gambler")).ok, "%s setup has a valid backup" % fault)
		manager.set_test_fault(fault)
		var failed: Dictionary = manager.save_session(Session.new(&"cairo_hourglass", &"default"))
		var after: Dictionary = manager.load_result()
		var backup_after: Dictionary = _read_json(manager.backup_path)
		_expect(not failed.ok and failed.status == SaveManager.STATUS_WRITE_FAILED and after.ok and after.data.character_id == "gambler" and backup_after.character_id == "relaxed", "%s preserves primary and backup" % fault)

	_cleanup()
	var rename_manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(rename_manager.save_session(Session.new(&"cairo_hourglass", &"relaxed")).ok, "rename-failure setup has a valid primary")
	rename_manager.set_test_fault("fail_primary_to_backup_rename")
	var primary_rename_failed: Dictionary = rename_manager.save_session(Session.new(&"cairo_hourglass", &"gambler"))
	var primary_rename_after: Dictionary = rename_manager.load_result()
	_expect(not primary_rename_failed.ok and primary_rename_after.ok and primary_rename_after.data.character_id == "relaxed", "primary to backup rename failure preserves the primary")

	_cleanup()
	var temp_rename_manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(temp_rename_manager.save_session(Session.new(&"cairo_hourglass", &"relaxed")).ok, "temp rename setup has a valid primary")
	temp_rename_manager.set_test_fault("fail_temp_to_primary_rename")
	var temp_rename_failed: Dictionary = temp_rename_manager.save_session(Session.new(&"cairo_hourglass", &"gambler"))
	var temp_rename_after: Dictionary = temp_rename_manager.load_result()
	_expect(not temp_rename_failed.ok and temp_rename_after.ok and temp_rename_after.status == SaveManager.STATUS_VALID_PRIMARY and temp_rename_after.data.character_id == "relaxed", "temp to primary rename failure restores the previous primary from backup")

	_cleanup()
	var final_readback_manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(final_readback_manager.save_session(Session.new(&"cairo_hourglass", &"relaxed")).ok, "final readback setup has a valid primary")
	final_readback_manager.set_test_fault("fail_final_readback")
	var final_readback_failed: Dictionary = final_readback_manager.save_session(Session.new(&"cairo_hourglass", &"gambler"))
	var final_readback_after: Dictionary = final_readback_manager.load_result()
	_expect(not final_readback_failed.ok and final_readback_after.ok and final_readback_after.status == SaveManager.STATUS_VALID_PRIMARY and final_readback_after.data.character_id == "relaxed", "final readback failure restores the previous primary and keeps the backup")

	_cleanup()
	var destination_manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(destination_manager.save_session(Session.new(&"cairo_hourglass", &"relaxed")).ok, "destination collision setup has a valid primary")
	_expect(destination_manager.save_session(Session.new(&"cairo_hourglass", &"gambler")).ok and FileAccess.file_exists(destination_manager.backup_path), "normal rotation creates a backup destination")
	destination_manager.set_test_fault("fail_primary_to_backup_rename")
	var destination_failed: Dictionary = destination_manager.save_session(Session.new(&"cairo_hourglass", &"default"))
	var destination_after: Dictionary = destination_manager.load_result()
	_expect(not destination_failed.ok and destination_after.ok and destination_after.data.character_id == "gambler", "existing backup destination collision preserves a valid save")

	_cleanup()
	var backup_stage_manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(backup_stage_manager.save_session(Session.new(&"cairo_hourglass", &"relaxed")).ok, "backup staging failure setup has a valid primary")
	_expect(backup_stage_manager.save_session(Session.new(&"cairo_hourglass", &"gambler")).ok, "backup staging failure setup has a valid backup")
	backup_stage_manager.set_test_fault("fail_backup_to_hold_rename")
	var backup_stage_failed: Dictionary = backup_stage_manager.save_session(Session.new(&"cairo_hourglass", &"default"))
	var backup_stage_after: Dictionary = backup_stage_manager.load_result()
	_expect(not backup_stage_failed.ok and backup_stage_after.ok and backup_stage_after.data.character_id == "gambler", "backup staging failure preserves the primary")


func _test_primary_backup_combinations_and_stale_temp() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var valid_session: RefCounted = Session.new(&"cairo_hourglass", &"relaxed")
	_expect(manager.save_session(valid_session).ok, "combination fixture is saved")
	var valid_text := _read_text(manager.save_path)
	var incompatible_text := JSON.stringify({"schema_version":999})
	var corrupt_text := "{not-json"

	_cleanup()
	_write(manager.save_path, valid_text)
	_expect(manager.load_result().status == SaveManager.STATUS_VALID_PRIMARY, "primary valid and backup missing is valid")
	_cleanup()
	_write(manager.backup_path, valid_text)
	_expect(manager.load_result().status == SaveManager.STATUS_RECOVERED_BACKUP, "primary missing and backup valid recovers")
	_cleanup()
	_write(manager.save_path, corrupt_text)
	_write(manager.backup_path, valid_text)
	_expect(manager.load_result().status == SaveManager.STATUS_RECOVERED_BACKUP, "primary corrupt and backup valid recovers")
	_cleanup()
	_write(manager.save_path, valid_text)
	_write(manager.backup_path, corrupt_text)
	_expect(manager.load_result().status == SaveManager.STATUS_VALID_PRIMARY, "primary valid and backup corrupt uses primary")
	_cleanup()
	_write(manager.save_path, corrupt_text)
	_write(manager.backup_path, corrupt_text)
	_expect(manager.load_result().status == SaveManager.STATUS_CORRUPT, "both corrupt return CORRUPT")
	_cleanup()
	_write(manager.save_path, incompatible_text)
	_write(manager.backup_path, valid_text)
	_expect(manager.load_result().status == SaveManager.STATUS_INCOMPATIBLE_VERSION, "incompatible primary is not hidden by a valid backup")
	_cleanup()
	_write(manager.save_path, valid_text)
	_write(manager.backup_path, incompatible_text)
	_expect(manager.load_result().status == SaveManager.STATUS_VALID_PRIMARY, "valid primary is preferred over incompatible backup")
	_cleanup()
	_write(manager.save_path, incompatible_text)
	_expect(manager.load_result().status == SaveManager.STATUS_INCOMPATIBLE_VERSION, "incompatible primary without backup is explicit")
	_cleanup()
	_expect(manager.load_result().status == SaveManager.STATUS_NO_SAVE, "both missing return NO_SAVE")
	_cleanup()
	_write(manager.save_path, corrupt_text)
	_write(manager.backup_path, valid_text)
	var corrupt_primary_save: Dictionary = manager.save_session(Session.new(&"cairo_hourglass", &"gambler"))
	var corrupt_primary_after: Dictionary = manager.load_result()
	_expect(not corrupt_primary_save.ok and corrupt_primary_after.status == SaveManager.STATUS_RECOVERED_BACKUP and corrupt_primary_after.data.character_id == "relaxed" and _read_text(manager.save_path) == corrupt_text, "saving with a corrupt primary never overwrites the valid backup")

	_cleanup()
	_write(manager.save_path, valid_text)
	_write(manager.temp_path, valid_text)
	var stale_result: Dictionary = manager.load_result()
	_expect(stale_result.status == SaveManager.STATUS_VALID_PRIMARY and not FileAccess.file_exists(manager.temp_path), "stale temp is ignored and cleaned without changing primary")

	_cleanup()
	_write(manager.backup_path, valid_text)
	var missing_primary_save: Dictionary = manager.save_session(Session.new(&"cairo_hourglass", &"gambler"))
	var backup_after_missing_primary := _read_json(manager.backup_path)
	var primary_after_missing_primary: Dictionary = manager.load_result()
	_expect(missing_primary_save.ok and primary_after_missing_primary.status == SaveManager.STATUS_VALID_PRIMARY and primary_after_missing_primary.data.character_id == "gambler" and SaveData.validate(backup_after_missing_primary).ok and backup_after_missing_primary.character_id == "relaxed", "missing primary is recreated while the valid backup remains")


func _test_semantic_dto_rejection() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(manager.save_session(Session.new()).ok, "semantic DTO fixture is saved")
	var valid: Dictionary = _read_json(manager.save_path)
	var bad_node := valid.duplicate(true)
	bad_node.session_state.route.current_node_id = "main:999"
	var bad_inventory := valid.duplicate(true)
	bad_inventory.session_state.player.inventory = {"compass": -1}
	var bad_slot := valid.duplicate(true)
	bad_slot.session_state.slot.last_role_resolved = true
	var bad_clock := valid.duplicate(true)
	bad_clock.session_state.clock.armed = true
	bad_clock.session_state.clock.running = true
	var bad_pending := valid.duplicate(true)
	bad_pending.session_state.route.pending_face = 2
	var bad_active := valid.duplicate(true)
	bad_active.session_state.player.skill_state = "ACTIVE"
	var bad_nan := valid.duplicate(true)
	bad_nan.saved_at_unix = NAN
	_expect(not SaveData.validate(bad_node).ok and not SaveData.validate(bad_inventory).ok and not SaveData.validate(bad_slot).ok and not SaveData.validate(bad_clock).ok and not SaveData.validate(bad_pending).ok and not SaveData.validate(bad_active).ok and not SaveData.validate(bad_nan).ok, "semantic DTO corruption is rejected without relying on JSON parse failure")


func _test_schema2_roulette_arithmetic() -> void:
	var session := Session.new()
	_set_player_hp(session, 1)
	_enter_victory(session)
	_expect(session.resolve_heart_roulette(1).ok, "resolved roulette fixture awards +2")
	var valid := SaveData.from_session(session)
	_expect(SaveData.validate(valid).ok, "schema2 resolved roulette accepts exact HP arithmetic")
	var bad_hp_after := valid.duplicate(true)
	bad_hp_after.session_state.player.heart_roulette.result.hp_after = 2
	var bad_gain := valid.duplicate(true)
	bad_gain.session_state.player.heart_roulette.result.heal_gain = 1
	_expect(not SaveData.validate(bad_hp_after).ok and not SaveData.validate(bad_gain).ok, "schema2 rejects forged hp_after and heal_gain arithmetic")
	var bad_max_type := valid.duplicate(true)
	bad_max_type.session_state.player.max_hp = 3.5
	var bad_max_value := valid.duplicate(true)
	bad_max_value.session_state.player.max_hp = 4
	var bad_life_low := valid.duplicate(true)
	bad_life_low.session_state.player.life = -1
	var bad_life_high := valid.duplicate(true)
	bad_life_high.session_state.player.life = 4
	_expect(not SaveData.validate(bad_max_type).ok and not SaveData.validate(bad_max_value).ok and not SaveData.validate(bad_life_low).ok and not SaveData.validate(bad_life_high).ok, "schema2 rejects noninteger/non3 max_hp and LIFE outside 0..3")


func _test_schema1_course_migration_contract() -> void:
	var ordinary := SaveData.from_session(Session.new(&"cairo_hourglass", &"gambler"))
	ordinary.schema_version = 1
	ordinary.erase("course_version")
	ordinary.session_state.lap = 12
	ordinary.session_state.score.total = 777
	ordinary.session_state.score.lap_total = 123
	ordinary.session_state.score.breakdown.travel = 700
	ordinary.session_state.score.role_counts.PAIR = 9
	ordinary.session_state.score.last_award = {"points":12}
	ordinary.session_state.records.best_score = 888
	ordinary.session_state.player.hp = 0
	ordinary.session_state.player.coins = 44
	ordinary.session_state.player.skill_gauge = 3
	ordinary.session_state.player.skill_state = "READY"
	ordinary.session_state.player.inventory = {"compass":2}
	ordinary.session_state.player.item_consumption = {"compass":true}
	ordinary.session_state.player.stage_flags = {"v06_three_roll_onboarding_seen":true, "v06_seen_event_ids":{"market_hawker":true}, "v06_next_basic_move_penalty":1}
	ordinary.session_state.route.current_node_id = "main:57"
	ordinary.session_state.route.route_id = "main"
	ordinary.session_state.route.tile_index = 57
	ordinary.session_state.route.pending_face = 6
	ordinary.session_state.route.pending_remaining_steps = 4
	ordinary.session_state.route.available_route_ids = ["main"]
	ordinary.session_state.route.active_warp_gate_id = "W2"
	ordinary.session_state.route.consumed_warp_gate_ids = ["W1", "W2"]
	ordinary.session_state.route.loop_id = "loop_oasis_ring"
	ordinary.session_state.route.loop_tile_index = 5
	ordinary.session_state.route.loop_exit_steps = 3
	ordinary.session_state.missions = {"legacy_transient":true}
	var ordinary_result := SaveData.validate(ordinary)
	var migrated: Dictionary = ordinary_result.get("data", {})
	_expect(ordinary_result.ok and migrated.course_version == SaveData.COURSE_VERSION and migrated.stage_id == "cairo_hourglass" and migrated.character_id == "gambler", "schema1 ordinary migrates to the exact course while preserving stage and character")
	_expect(migrated.session_state.route.current_node_id == "main:0" and migrated.session_state.player.hp == 1 and migrated.session_state.player.max_hp == 3 and migrated.session_state.player.life == 3, "schema1 ordinary restarts at main0 with HP/LIFE invariants")
	_expect(migrated.session_state.lap == 12 and migrated.session_state.score.total == 777 and migrated.session_state.score.breakdown.travel == 700 and migrated.session_state.records.best_score == 888, "schema1 ordinary preserves cumulative score, BEST, lap, and records")
	_expect(migrated.session_state.score.lap_total == 0 and migrated.session_state.score.role_counts.PAIR == 0 and migrated.session_state.score.last_award.is_empty(), "schema1 ordinary resets lap-local score state")
	_expect(migrated.session_state.player.stage_flags == {"v06_three_roll_onboarding_seen":true, "v06_seen_event_ids":{"market_hawker":true}}, "schema1 ordinary preserves only approved durable flags")
	_expect(migrated.session_state.route == {"current_node_id":"main:0", "route_id":"main", "tile_index":0, "pending_face":0, "pending_remaining_steps":0, "available_route_ids":[], "active_warp_gate_id":"", "consumed_warp_gate_ids":[], "visited_node_keys":["main:0"], "consumed_reward_node_keys":[], "awarded_score_event_ids":[], "loop_id":"", "loop_tile_index":-1, "loop_exit_steps":-1, "exit_position":{}}, "schema1 ordinary discards old main57 movement, warp, loop, and visit transients")
	_expect(migrated.session_state.player.coins == 0 and migrated.session_state.player.skill_gauge == 0 and migrated.session_state.player.skill_state == "CHARGING" and migrated.session_state.player.inventory.is_empty() and migrated.session_state.player.item_consumption.is_empty() and not migrated.session_state.has("missions"), "schema1 ordinary clears coins, skill, inventory, consumption, and missions")
	var ordinary_second := SaveData.validate(migrated)
	_expect(ordinary_second.ok and ordinary_second.data == migrated, "schema1 ordinary migration is idempotent after normalization")
	_cleanup()
	var manager := SaveManager.new(TEST_PATH)
	_write(manager.save_path, JSON.stringify(ordinary))
	var managed := manager.load_result()
	_expect(managed.ok and managed.status == SaveManager.STATUS_VALID_PRIMARY and managed.data.schema_version == SaveData.SCHEMA_VERSION and managed.data.course_version == SaveData.COURSE_VERSION and managed.data.session_state.route.current_node_id == "main:0", "manager load returns normalized schema2 data for a genuine schema1 ordinary save")
	_cleanup()

	for hp: int in [1, 2, 3]:
		var terminal := SaveData.from_session(Session.new())
		terminal.schema_version = 1
		terminal.erase("course_version")
		terminal.session_state.player.hp = hp
		terminal.session_state.erase("active_event")
		terminal.session_state.player.heart_roulette = {"pending":true, "resolved":false, "slot_index":-1, "result":{}}
		terminal.session_state.phase = "FINISHED"
		terminal.session_state.boss_entered = true
		terminal.session_state.boss = _legacy_victory_boss()
		var terminal_result := SaveData.validate(terminal)
		var terminal_state: Dictionary = terminal_result.get("data", {}).get("session_state", {})
		_expect(terminal_result.ok and terminal_state.route.current_node_id == "main:89" and terminal_state.phase == "FINISHED", "schema1 terminal HP%d stays next-lap capable at main89" % hp)
		_expect(bool(terminal_state.player.heart_roulette.pending) == (hp < 3), "schema1 explicit pending terminal HP%d preserves recovery only when wounded/PERFECT" % hp)
		var terminal_second := SaveData.validate(terminal_result.data)
		_expect(terminal_second.ok and terminal_second.data == terminal_result.data, "schema1 terminal HP%d migration is idempotent" % hp)

	var resolved := SaveData.from_session(Session.new())
	resolved.schema_version = 1
	resolved.erase("course_version")
	resolved.session_state.player.hp = 2
	resolved.session_state.phase = "FINISHED"
	resolved.session_state.boss_entered = true
	resolved.session_state.boss = _legacy_victory_boss()
	resolved.session_state.player.heart_roulette = {"pending":false, "resolved":true, "slot_index":0, "result":{"legacy":true}}
	var first := SaveData.validate(resolved)
	var second := SaveData.validate(first.data)
	_expect(first.ok and second.ok and second.data == first.data and not first.data.session_state.player.heart_roulette.pending and not first.data.session_state.player.heart_roulette.resolved, "schema1 resolved roulette clears without a duplicate reward and migration is idempotent")
	_cleanup()
	var resolved_manager := SaveManager.new(TEST_PATH)
	_write(resolved_manager.save_path, JSON.stringify(resolved))
	var managed_resolved := resolved_manager.load_result()
	_expect(managed_resolved.ok and managed_resolved.data.schema_version == SaveData.SCHEMA_VERSION and not managed_resolved.data.session_state.player.heart_roulette.pending, "manager normalized-load never re-awards a resolved legacy roulette")
	_cleanup()


func _legacy_victory_boss() -> Dictionary:
	var battle_session := Session.new()
	_enter_victory(battle_session)
	return battle_session.stable_save_snapshot(0).boss


func _enter_victory(session: RefCounted) -> void:
	session.enter_boss(0)
	for now: int in range(1, 12):
		if session.phase() == Session.PHASE_BOSS_FINISHED:
			break
		session.start_roll(6, now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()


func _test_active_event_semantic_validation() -> void:
	var ready_event := Session.new()
	_set_main_fixture(ready_event, 29, [])
	_roll_and_finish(ready_event, 1)
	var ready_dto: Dictionary = SaveData.from_session(ready_event)
	_expect(SaveData.validate(ready_dto).ok and ready_dto.session_state.active_event.return_phase == "READY", "valid READY-return EVENT save is accepted")

	var resolution_event := Session.new()
	_set_main_fixture(resolution_event, 29, [2, 1])
	_roll_and_finish(resolution_event, 1)
	var resolution_dto: Dictionary = SaveData.from_session(resolution_event)
	_expect(SaveData.validate(resolution_dto).ok and resolution_dto.session_state.active_event.return_phase == "RESOLUTION_REQUIRED", "valid RESOLUTION-return EVENT save is accepted")

	var wrong_mapping := ready_dto.duplicate(true)
	wrong_mapping.session_state.active_event.event_id = "ferry_offer"
	var non_event_node := ready_dto.duplicate(true)
	non_event_node.session_state.route.current_node_id = "main:5"
	non_event_node.session_state.route.tile_index = 5
	non_event_node.session_state.active_event.node_key = "main:5"
	var inconsistent_first := ready_dto.duplicate(true)
	inconsistent_first.session_state.player.stage_flags[Session.STAGE_FLAG_SEEN_EVENT_IDS] = {"market_hawker":true}
	var unsupported_score := ready_dto.duplicate(true)
	unsupported_score.session_state.active_event.score_awarded = true
	unsupported_score.session_state.route.awarded_score_event_ids.erase("stop:main:30:event")
	_expect(not SaveData.validate(wrong_mapping).ok, "wrong node/event mapping is rejected")
	_expect(not SaveData.validate(non_event_node).ok, "non-EVENT node payload is rejected")
	_expect(not SaveData.validate(inconsistent_first).ok, "first_visit inconsistent with seen-event state is rejected")
	_expect(not SaveData.validate(unsupported_score).ok, "score_awarded without the corresponding score-event ID is rejected")

	var repeat_dto := ready_dto.duplicate(true)
	repeat_dto.session_state.active_event.first_visit = false
	repeat_dto.session_state.active_event.score_awarded = false
	repeat_dto.session_state.player.stage_flags[Session.STAGE_FLAG_SEEN_EVENT_IDS] = {"market_hawker":true}
	_expect(SaveData.validate(repeat_dto).ok, "valid seen repeat without a new score award is accepted")

	var legacy_ready := SaveData.from_session(Session.new())
	legacy_ready.session_state.erase("active_event")
	_expect(SaveData.validate(legacy_ready).ok, "schema-v1 legacy save without active_event remains accepted")


func _test_challenge_score_and_hp0_migration() -> void:
	for lap_value: int in [1, 2, 3, 4, 5, 8]:
		var state: Dictionary = Session.new().stable_save_snapshot(0)
		state.lap = lap_value
		var session := Session.new()
		_expect(session.restore_stable_snapshot(state, 0), "lap multiplier fixture restores at lap %d" % lap_value)
		_roll_and_finish(session, 2)
		_expect(session.score() == 2 and session.lap_score() == 2 and session.lap_multiplier_numerator() == 4, "lap %d keeps the one-space one-point rule" % lap_value)

	var legacy_state: Dictionary = Session.new().stable_save_snapshot(0)
	legacy_state.score.total = 321
	legacy_state.score.breakdown.travel = 321
	legacy_state.score.erase("lap_total")
	var legacy := Session.new()
	_expect(legacy.restore_stable_snapshot(legacy_state, 0) and legacy.score() == 321 and legacy.lap_score() == 321, "legacy score without lap_total conservatively migrates total into current lap")

	var event_session := Session.new()
	_set_main_fixture(event_session, 29, [])
	_roll_and_finish(event_session, 1)
	var event_state: Dictionary = event_session.stable_save_snapshot(0)
	event_state.player.hp = 0
	event_state.player.life = 0
	var pending_event := Session.new()
	_expect(pending_event.restore_stable_snapshot(event_state, 0) and pending_event.phase() == Session.PHASE_EVENT_REQUIRED, "legacy HP0 EVENT remains pending until its stable interaction completes")
	_expect(pending_event.acknowledge_event() and pending_event.phase() == Session.PHASE_RUN_OVER and pending_event.best_score() == pending_event.score(), "HP0 EVENT acknowledgement enters RUN_OVER and updates BEST once")

	var resolution_session := Session.new()
	_set_main_fixture(resolution_session, 29, [2, 1])
	_roll_and_finish(resolution_session, 1)
	var resolution_state: Dictionary = resolution_session.stable_save_snapshot(0)
	resolution_state.player.hp = 0
	resolution_state.player.life = 0
	var pending_resolution := Session.new()
	_expect(pending_resolution.restore_stable_snapshot(resolution_state, 0) and pending_resolution.acknowledge_event() and pending_resolution.phase() == Session.PHASE_RESOLUTION_REQUIRED, "HP0 third-roll EVENT preserves role resolution ordering")
	_expect(pending_resolution.acknowledge_resolution() and pending_resolution.phase() == Session.PHASE_RUN_OVER, "HP0 enters RUN_OVER only after third-roll resolution acknowledgement")


func _test_stable_boundary_and_deep_copy_contracts() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new()
	var public_snapshot: Dictionary = session.snapshot()
	var public_position: Dictionary = public_snapshot.position
	public_position.tile_index = 99
	public_snapshot.position = public_position
	var public_visits: PackedStringArray = public_snapshot.visited_node_keys
	public_visits.append("fake:1")
	public_snapshot.visited_node_keys = public_visits
	_expect(session.position().tile_index == 0 and "fake:1" not in session.visited_node_keys(), "public snapshot is detached from session state")

	var stable: Dictionary = session.stable_save_snapshot(0)
	var stable_inventory: Dictionary = stable.player.inventory
	stable_inventory["compass"] = 1
	stable.player.inventory = stable_inventory
	var stable_visits: Array = stable.route.visited_node_keys
	stable_visits.append("fake:2")
	stable.route.visited_node_keys = stable_visits
	_expect(session.inventory().is_empty() and "fake:2" not in session.visited_node_keys(), "stable save snapshot deep-copies inventory and route history")

	var dto_a: Dictionary = SaveData.from_session(session)
	var dto_b: Dictionary = SaveData.from_session(session)
	_expect(_without_save_metadata(dto_a) == _without_save_metadata(dto_b), "equivalent stable sessions produce deterministic DTO content")
	var restored: RefCounted = Session.new(StringName(dto_a.stage_id), StringName(dto_a.character_id))
	_expect(restored.restore_stable_snapshot(dto_a.session_state, 1000), "DTO state restores before deep-copy mutation")
	var detached_state: Dictionary = dto_a.session_state.duplicate(true)
	var detached_inventory: Dictionary = detached_state.player.inventory
	detached_inventory["mutated_after_restore"] = 1
	detached_state.player.inventory = detached_inventory
	var detached_visits: Array = detached_state.route.visited_node_keys
	detached_visits.append("mutated:1")
	detached_state.route.visited_node_keys = detached_visits
	_expect(restored.inventory().get("mutated_after_restore", 0) == 0 and "mutated:1" not in restored.visited_node_keys(), "restore deep-copies DTO state")

	var armed_state: Dictionary = dto_a.session_state.duplicate(true)
	armed_state.player.skill_state = "ARMED"
	armed_state.player.skill_gauge = 3
	armed_state.clock.armed = false
	armed_state.clock.running = true
	var armed_session: RefCounted = Session.new()
	_expect(armed_session.restore_stable_snapshot(armed_state, 1000) and armed_session.pause_clock(1100) and armed_session.resume_clock(1200) and armed_session.skill_state() == Session.SKILL_STATE_ARMED and armed_session.skill_gauge() == 3, "ARMED state survives pause and resume without consuming its gauge")
	var armed_save: Dictionary = manager.save_session(armed_session)
	_expect(armed_save.ok and armed_save.data.session_state.player.skill_state == "ARMED" and armed_save.data.session_state.player.skill_gauge == 3, "ARMED state is persisted at a stable checkpoint")

	var resolution_session: RefCounted = Session.new()
	_roll_and_finish(resolution_session, 1)
	_roll_and_finish(resolution_session, 1)
	_roll_and_finish(resolution_session, 1)
	var resolution_position: Dictionary = resolution_session.position()
	var resolution_score: int = resolution_session.score()
	var resolution_coins: int = resolution_session.coins()
	var resolution_gauge: int = resolution_session.skill_gauge()
	_expect(resolution_session.phase() == Session.PHASE_RESOLUTION_REQUIRED and resolution_session.acknowledge_resolution() and resolution_session.position() == resolution_position and resolution_session.score() == resolution_score and resolution_session.coins() == resolution_coins and resolution_session.skill_gauge() == resolution_gauge, "RESOLUTION_REQUIRED acknowledgement only clears the already-settled slot")
	var resolution_after_ack: Dictionary = resolution_session.snapshot()
	_expect(not resolution_session.acknowledge_resolution() and resolution_session.snapshot().position == resolution_after_ack.position and resolution_session.snapshot().score == resolution_after_ack.score, "duplicate RESOLUTION_REQUIRED acknowledgement is idempotently rejected")

	var baseline: Dictionary = manager.save_session(session)
	session.start_roll(2)
	var interrupted: Dictionary = manager.save_session(session)
	var restored_interrupted: RefCounted = Session.new()
	var interrupted_data: Dictionary = manager.load_result().data
	_expect(not interrupted.ok and interrupted.status == SaveManager.STATUS_NOT_STABLE and restored_interrupted.restore_stable_snapshot(interrupted_data.session_state, 1000) and restored_interrupted.position() == {"route_id":"main", "tile_index":0} and restored_interrupted.faces().is_empty() and baseline.data.session_state.score.total == interrupted_data.session_state.score.total, "roll interruption returns to the prior stable checkpoint")

	var reward_session: RefCounted = Session.new()
	_roll_and_finish(reward_session, 2)
	_roll_and_finish(reward_session, 1)
	var reward_baseline: Dictionary = manager.save_session(reward_session)
	reward_session.start_roll(1)
	var reward_interrupted: Dictionary = manager.save_session(reward_session)
	var reward_loaded: Dictionary = manager.load_result().data
	_expect(not reward_interrupted.ok and reward_interrupted.status == SaveManager.STATUS_NOT_STABLE and reward_loaded.session_state.score.total == reward_baseline.data.session_state.score.total and reward_loaded.session_state.player.skill_gauge == reward_baseline.data.session_state.player.skill_gauge, "partial slot reward is not checkpointed before movement settles")

	var warp_session: RefCounted = Session.new()
	_roll_and_finish(warp_session, 6)
	_roll_and_finish(warp_session, 3)
	_expect(manager.save_session(warp_session).ok, "warp interruption setup saves before the gate")
	warp_session.start_roll(1)
	warp_session.next_hop()
	var warp_interrupted: Dictionary = manager.save_session(warp_session)
	var warp_loaded: Dictionary = manager.load_result().data
	_expect(not warp_interrupted.ok and warp_interrupted.status == SaveManager.STATUS_NOT_STABLE and warp_loaded.session_state.route.current_node_id == "main:9" and warp_loaded.session_state.route.active_warp_gate_id == "", "warp animation interruption does not checkpoint a transient destination")


func _test_tomb_loop_restore() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var session: RefCounted = Session.new()
	_set_main_fixture(session, 65, [])
	_roll_and_finish(session, 1)
	var saved: Dictionary = manager.save_session(session)
	var restored: RefCounted = Session.new()
	_expect(saved.ok and saved.data.session_state.route.loop_id == Course.ROUTE_LOOP_TOMB and saved.data.session_state.route.active_warp_gate_id == "W3" and restored.restore_stable_snapshot(saved.data.session_state, 1000) and restored.position() == session.position() and "W3" in restored.consumed_warp_gate_ids(), "tomb ring position and consumed warp restore without retrigger")


func _test_old_save_is_separate_and_load_is_idempotent() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	_expect(manager.save_path != manager.OLD_SAVE_PATH and manager.backup_path != manager.OLD_SAVE_PATH and manager.temp_path != manager.OLD_SAVE_PATH, "V06 save paths never share the legacy save path")
	var session: RefCounted = Session.new()
	_roll_and_finish(session, 2)
	var saved: Dictionary = manager.save_session(session)
	var data: Dictionary = saved.data
	var restored_a: RefCounted = Session.new(StringName(data.stage_id), StringName(data.character_id))
	var restored_b: RefCounted = Session.new(StringName(data.stage_id), StringName(data.character_id))
	_expect(restored_a.restore_stable_snapshot(data.session_state, 1000) and restored_b.restore_stable_snapshot(data.session_state, 2000), "the same stable save can be loaded repeatedly")
	_expect(restored_a.score() == restored_b.score() and restored_a.coins() == restored_b.coins() and restored_a.visited_node_keys() == restored_b.visited_node_keys(), "repeated restore does not multiply score, coins, or visits")


func _set_main_fixture(session: RefCounted, tile_index: int, face_values: Array) -> void:
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
	_expect(session.restore_stable_snapshot(state, 0), "save fixture restores main%d with %d faces" % [tile_index, face_values.size()])


func _set_player_hp(session: RefCounted, hp: int) -> void:
	var state: Dictionary = session.stable_save_snapshot(0)
	state.player.hp = hp
	state.player.max_hp = 3
	state.player.life = 3
	_expect(session.restore_stable_snapshot(state, 0), "save fixture restores HP%d/max3/LIFE3" % hp)


func _roll_and_finish(session: RefCounted, face: int) -> Dictionary:
	var started: Dictionary = session.start_roll(face)
	if not bool(started.get("ok", false)):
		return started
	_consume_hops(session)
	return session.finish_movement()


func _consume_hops(session: RefCounted) -> void:
	while session.has_pending_hops():
		session.next_hop()


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures += 1
		push_error("Could not write test fixture: %s" % path)
		return
	file.store_string(text)
	file.flush()
	file.close()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _read_json(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(_read_text(path)) != OK or not parser.data is Dictionary:
		return {}
	return parser.data as Dictionary


func _without_save_metadata(value: Dictionary) -> Dictionary:
	var copy := value.duplicate(true)
	copy.erase("saved_at")
	copy.erase("saved_at_unix")
	return copy


func _cleanup() -> void:
	for path: String in [TEST_PATH, "%s.bak" % TEST_PATH, "%s.tmp" % TEST_PATH, "%s.bak.swap" % TEST_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
