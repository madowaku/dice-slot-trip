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
	_test_stable_slot_sizes_and_states()
	_test_branch_loop_and_warp_restore()
	_test_boss_restore()
	_test_backup_recovery()
	_test_corrupt_and_incompatible_results()
	_test_write_failure_preserves_primary()
	_test_fault_injection_and_atomic_boundaries()
	_test_primary_backup_combinations_and_stale_temp()
	_test_semantic_dto_rejection()
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
	_roll_and_finish(session, 1)
	_expect(session.phase() == Session.PHASE_RESOLUTION_REQUIRED, "third face resolves before the stable acknowledgement boundary")
	var unstable_resolution: Dictionary = manager.save_session(session)
	_expect(not unstable_resolution.ok and unstable_resolution.status == SaveManager.STATUS_NOT_STABLE, "RESOLUTION_REQUIRED is not saved before acknowledgement")
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
	_expect(not boss_partial_save.ok and boss_partial_save.status == SaveManager.STATUS_NOT_STABLE and boss_partial_loaded.ok and boss_partial_loaded.data.session_state.slot.current_roll_index == 0, "boss roll interruption returns to the turn-start checkpoint")
	boss = Session.new()
	_expect(boss.enter_boss(0), "boss slot test re-enters a fresh battle")
	for face: int in [2, 3, 4]:
		boss.start_roll(face, face)
	_expect(boss.phase() == Session.PHASE_BOSS_ROUND_RESULT, "boss round result is a stable three-slot boundary")
	var boss_result_saved: Dictionary = manager.save_session(boss)
	_expect(boss_result_saved.ok and boss_result_saved.data.session_state.slot.current_roll_index == 3 and boss_result_saved.data.session_state.slot.last_role == "STRAIGHT" and boss_result_saved.data.session_state.score.role_counts.STRAIGHT == 1, "three filled boss slots, last role, and role count are persisted")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(boss_result_saved.data.session_state, 1000) and restored.phase() == Session.PHASE_BOSS_ROUND_RESULT and restored.faces() == [2, 3, 4], "three-slot boss result restores exactly")


func _test_branch_loop_and_warp_restore() -> void:
	_cleanup()
	var manager: RefCounted = SaveManager.new(TEST_PATH)
	var branch: RefCounted = Session.new()
	_roll_and_finish(branch, 6)
	_roll_and_finish(branch, 5)
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
	_expect(bypass_save.ok and "bypass_bazaar_alley:1" in bypass_save.data.session_state.route.visited_node_keys and "bypass_clear:bypass_bazaar_alley" in bypass_save.data.session_state.route.awarded_score_event_ids, "bypass route history and one-time completion are persisted after rejoin")

	var loop: RefCounted = Session.new()
	_roll_and_finish(loop, 6)
	_roll_and_finish(loop, 3)
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
	for face: int in [2, 3, 4]:
		session.start_roll(face, face)
	var round_save: Dictionary = manager.save_session(session)
	var restored_round: RefCounted = Session.new()
	_expect(round_save.ok and restored_round.restore_stable_snapshot(round_save.data.session_state, 1000) and restored_round.phase() == Session.PHASE_BOSS_ROUND_RESULT and restored_round.boss_snapshot().pending_ack, "boss round result restores its pending acknowledgement")
	var victory: RefCounted = Session.new()
	victory.enter_boss(0)
	for face: int in [2, 3, 4]:
		victory.start_roll(face, face)
	victory.acknowledge_boss_round()
	for face: int in [2, 2, 6]:
		victory.start_roll(face, 10 + face)
	victory.acknowledge_boss_round()
	for face: int in [1, 1, 1]:
		victory.start_roll(face, 20 + face)
	var victory_save: Dictionary = manager.save_session(victory)
	var victory_restored: RefCounted = Session.new()
	_expect(victory.phase() == Session.PHASE_BOSS_ROUND_RESULT and victory_save.ok and victory_restored.restore_stable_snapshot(victory_save.data.session_state, 1000) and victory_restored.boss_result().victory, "boss victory result restores before its final acknowledgement")
	_expect(victory.acknowledge_boss_round(), "boss victory acknowledgement reaches LAP_RESULT")
	var lap_result_save: Dictionary = manager.save_session(victory)
	var lap_result_restored: RefCounted = Session.new()
	_expect(lap_result_save.ok and lap_result_restored.restore_stable_snapshot(lap_result_save.data.session_state, 1000) and lap_result_restored.phase() == Session.PHASE_LAP_RESULT, "LAP_RESULT restores after terminal boss acknowledgement")
	var defeat: RefCounted = Session.new()
	defeat.enter_boss(0)
	for round_index: int in range(3):
		for face: int in [1, 2, 3]:
			defeat.start_roll(face, round_index * 10 + face)
		if round_index < 2:
			defeat.acknowledge_boss_round()
	_expect(defeat.phase() == Session.PHASE_BOSS_ROUND_RESULT and defeat.acknowledge_boss_round(), "boss defeat acknowledgement reaches RUN_OVER")
	var run_over_save: Dictionary = manager.save_session(defeat)
	var run_over_restored: RefCounted = Session.new()
	_expect(run_over_save.ok and run_over_restored.restore_stable_snapshot(run_over_save.data.session_state, 1000) and run_over_restored.phase() == Session.PHASE_RUN_OVER, "RUN_OVER restores after terminal defeat")


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
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 5)
	session.start_roll(4)
	_consume_hops(session)
	var choice: Dictionary = session.finish_movement()
	if choice.status == "CHOICE_REQUIRED":
		session.choose_route(Course.ROUTE_MAIN)
		_consume_hops(session)
		session.finish_movement()
	if session.phase() == Session.PHASE_RESOLUTION_REQUIRED:
		session.acknowledge_resolution()
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 5)
	_roll_and_finish(session, 6)
	if session.phase() == Session.PHASE_RESOLUTION_REQUIRED:
		session.acknowledge_resolution()
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
