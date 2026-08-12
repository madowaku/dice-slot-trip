extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const Course = preload("res://scripts/game/v06_course_model.gd")
const SaveData = preload("res://scripts/game/v06_session_save_data.gd")

var failures := 0


func _init() -> void:
	_test_data_contract()
	_test_coin_once_and_restore()
	_test_rest_repeat_and_cap()
	_test_hp_risk_and_floor()
	_test_bypass_coin_loss()
	_test_next_move_penalty_and_slot_face()
	_test_loop_effects()
	_test_resolution_id_contract()
	_test_hp_zero_boss_restore()
	_test_stage_flag_compatibility()
	_test_warp_destination_only()
	print("V06_TILE_EFFECT_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_data_contract() -> void:
	var course: RefCounted = Course.new()
	_expect(course.load_file(Session.COURSE_PATH), "tile effect course data validates")
	_expect(course.effect_for_position({"route_id":"main","tile_index":4}).amount == 2, "main COIN amount follows the fixed course contract")
	_expect(course.effect_for_position({"route_id":"bypass_bazaar_alley","tile_index":0}).kind == "hp_damage", "Bazaar shortcut starts with one-heart RISK")
	_expect(course.tile_kind_for_position({"route_id":"bypass_bazaar_alley","tile_index":1}) == "REST", "Bazaar shortcut alternates into REST")
	_expect(course.effect_for_position({"route_id":"bypass_sirocco","tile_index":0}).kind == "hp_damage", "desert_01 declares HP damage")
	_expect(course.tile_kind_for_position({"route_id":"bypass_sirocco","tile_index":3}) == "REST", "Sirocco shortcut alternates into REST at desert_04")
	_expect(course.effect_for_position({"route_id":"loop_tomb_ring","tile_index":1}).kind == "hp_damage", "tomb RISK declares HP damage")
	_expect(course.tile_kind_for_position({"route_id":"loop_tomb_ring","tile_index":4}) == "EXIT_GATE" and course.effect_for_position({"route_id":"loop_tomb_ring","tile_index":4}).is_empty(), "second tomb hazard is replaced by the alternate EXIT")
	_expect(course.effect_for_position({"route_id":"loop_tomb_ring","tile_index":7}).amount == 3, "represented tomb COIN declares three coins")
	for index: int in [17, 29, 34, 41, 52, 62, 74, 87]:
		_expect(course.effect_for_position({"route_id":"main","tile_index":index}).kind == "hp_damage", "main RISK %d uses the HP-damage default" % index)


func _test_coin_once_and_restore() -> void:
	var session := _session_at("main", 3)
	_roll_and_finish(session, 1)
	_expect(session.coins() == 2 and session.current_tile_kind() == "NORMAL" and session.last_tile_effect_result().text == "COIN +2", "COIN grants two and becomes consumed")
	var saved: Dictionary = session.stable_save_snapshot()
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(saved) and restored.coins() == 2, "COIN state restores without replay")
	var revisit_state: Dictionary = restored.stable_save_snapshot()
	_set_position(revisit_state, "main", 3)
	var revisit: RefCounted = Session.new()
	_expect(revisit.restore_stable_snapshot(revisit_state), "consumed COIN revisit setup restores")
	_roll_and_finish(revisit, 1)
	_expect(revisit.coins() == 2 and revisit.last_tile_effect_result().is_empty(), "consumed COIN cannot be collected again")


func _test_rest_repeat_and_cap() -> void:
	var session := _session_at("main", 10, 1)
	_roll_and_finish(session, 1)
	_expect(session.player_hp() == 2 and session.last_tile_effect_result().text == "HP +1", "REST heals one")
	var repeat_state: Dictionary = session.stable_save_snapshot()
	_set_position(repeat_state, "main", 10)
	var repeat: RefCounted = Session.new()
	repeat.restore_stable_snapshot(repeat_state)
	_roll_and_finish(repeat, 1)
	_expect(repeat.player_hp() == 3, "REST heals again on a separate landing")
	var full := _session_at("main", 10, 3)
	_roll_and_finish(full, 1)
	_expect(full.player_hp() == 3 and full.last_tile_effect_result().text == "HP FULL", "REST caps at maximum HP")


func _test_hp_risk_and_floor() -> void:
	var session := _session_at("main", 16, 1)
	_roll_and_finish(session, 1)
	_expect(session.player_hp() == 3 and session.life() == 2 and session.last_tile_effect_result().text == "DAMAGE -1", "HP0 consumes one LIFE and revives at HP3")
	var game_over := _session_at("main", 16, 1, 0, 0)
	_roll_and_finish(game_over, 1)
	_expect(game_over.player_hp() == 0 and game_over.life() == 0 and game_over.phase() == Session.PHASE_RUN_OVER and not game_over.start_roll(1).ok, "LIFE0 HP0 enters RUN_OVER and blocks further travel")


func _test_bypass_coin_loss() -> void:
	var session := _choice_session("main", 32, 1, 5)
	_expect(session.choose_route(Course.ROUTE_BYPASS_BAZAAR).ok, "Bazaar route choice starts")
	_consume_hops(session)
	session.finish_movement()
	_expect(session.position() == {"route_id":"bypass_bazaar_alley","tile_index":0} and session.player_hp() == 2 and session.coins() == 5 and session.last_tile_effect_result().text == "DAMAGE -1", "Bazaar RISK costs one heart and never hides a coin penalty")
	_roll_and_finish(session, 1)
	_expect(session.position() == {"route_id":"bypass_bazaar_alley","tile_index":1} and session.player_hp() == 3 and session.last_tile_effect_result().text == "HP +1", "Bazaar REST immediately offers one-heart recovery")
	_roll_and_finish(session, 1)
	_expect(session.position() == {"route_id":"bypass_bazaar_alley","tile_index":2} and session.player_hp() == 2, "Bazaar shortcut finishes with the alternating RISK")


func _test_next_move_penalty_and_slot_face() -> void:
	var desert_hp := _choice_session("main", 71, 1, 0)
	desert_hp.choose_route(Course.ROUTE_BYPASS_SIROCCO)
	_consume_hops(desert_hp)
	desert_hp.finish_movement()
	_expect(desert_hp.player_hp() == 2 and desert_hp.next_basic_move_penalty() == 0, "desert_01 applies HP damage rather than movement loss")
	var session := _session_at(Course.ROUTE_BYPASS_SIROCCO, 2, 2)
	_roll_and_finish(session, 1)
	_expect(session.position() == {"route_id":"bypass_sirocco","tile_index":3} and session.player_hp() == 3 and session.next_basic_move_penalty() == 0, "Sirocco REST heals one without a hidden movement penalty")
	var saved: Dictionary = session.stable_save_snapshot()
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(saved) and restored.player_hp() == 3 and restored.next_basic_move_penalty() == 0, "Sirocco REST result survives restore")
	_roll_and_finish(restored, 1)
	_expect(restored.position() == {"route_id":"bypass_sirocco","tile_index":4} and restored.player_hp() == 2 and restored.faces() == [1, 1], "next Sirocco space alternates back to one-heart RISK")


func _test_loop_effects() -> void:
	var oasis_coin := _session_at(Course.ROUTE_LOOP_OASIS, 1)
	_roll_and_finish(oasis_coin, 1)
	_expect(oasis_coin.coins() == 2 and "loop_oasis_ring:2" in oasis_coin.consumed_reward_node_keys(), "oasis COIN is single-use")
	var oasis_rest := _session_at(Course.ROUTE_LOOP_OASIS, 3, 2)
	_roll_and_finish(oasis_rest, 1)
	_expect(oasis_rest.player_hp() == 3 and not ("loop_oasis_ring:4" in oasis_rest.consumed_reward_node_keys()), "oasis REST remains reusable")
	var tomb_exit := _session_at(Course.ROUTE_LOOP_TOMB, 2, 3)
	_roll_and_finish(tomb_exit, 2)
	_expect(tomb_exit.player_hp() == 3 and tomb_exit.position() == {"route_id":"main", "tile_index":76} and tomb_exit.next_basic_move_penalty() == 0, "alternate tomb EXIT returns safely to main76")
	var tomb_coin := _session_at(Course.ROUTE_LOOP_TOMB, 6)
	_roll_and_finish(tomb_coin, 1)
	_expect(tomb_coin.coins() == 3 and tomb_coin.last_tile_effect_result().text == "COIN +3", "represented tomb COIN grants three once")
	var mix_coin := _session_at(Course.ROUTE_LOOP_TOMB, 6)
	var mix_state: Dictionary = mix_coin.stable_save_snapshot()
	mix_state.slot.faces = [2, 4]
	mix_state.slot.current_roll_index = 2
	_expect(mix_coin.restore_stable_snapshot(mix_state), "MIX plus tomb COIN fixture restores")
	_roll_and_finish(mix_coin, 1)
	_expect(mix_coin.coins() == 4 and mix_coin.resolution_role() == &"MIX", "MIX plus one and tomb COIN plus three total four exactly once")


func _test_resolution_id_contract() -> void:
	var session := _session_at("main", 16, 3)
	_roll_and_finish(session, 1)
	var first_ids: Dictionary = session.stage_flags().get(Session.STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {})
	var first_count := first_ids.size()
	var duplicate_finish: Dictionary = session.finish_movement()
	_expect(not duplicate_finish.ok and session.stage_flags().get(Session.STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {}).size() == first_count, "the same landing cannot add its resolution ID twice")
	var continued_state: Dictionary = session.stable_save_snapshot()
	_set_position(continued_state, Course.ROUTE_LOOP_OASIS, 3)
	continued_state.route.active_warp_gate_id = "W1"
	continued_state.player.hp = 1
	var continued: RefCounted = Session.new()
	_expect(continued.restore_stable_snapshot(continued_state), "Continue fixture preserves prior landing IDs and roll count")
	_roll_and_finish(continued, 1)
	var second_ids: Dictionary = continued.stage_flags().get(Session.STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {})
	_expect(second_ids.size() == first_count + 1 and continued.player_hp() == 2, "Continue next landing uses a distinct resolution ID")
	var revisit_state: Dictionary = continued.stable_save_snapshot()
	_set_position(revisit_state, Course.ROUTE_LOOP_OASIS, 3)
	revisit_state.route.active_warp_gate_id = "W1"
	var revisit: RefCounted = Session.new()
	revisit.restore_stable_snapshot(revisit_state)
	_roll_and_finish(revisit, 1)
	var third_ids: Dictionary = revisit.stage_flags().get(Session.STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {})
	_expect(third_ids.size() == first_count + 2 and revisit.player_hp() == 3, "a loop revisit on another roll gets a distinct ID and re-applies REST")
	if revisit.phase() == Session.PHASE_RESOLUTION_REQUIRED:
		_expect(revisit.acknowledge_resolution(), "landing-ID fixture acknowledges its completed slot set")
	var boss_count_before: int = revisit.roll_count()
	var boss_ids_before: Dictionary = revisit.stage_flags().get(Session.STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {})
	_expect(revisit.enter_boss(0) and revisit.start_roll(2, 1).ok and revisit.roll_count() == boss_count_before + 1, "boss rolls continue the monotonic roll count")
	_expect(revisit.stage_flags().get(Session.STAGE_FLAG_RESOLVED_TILE_EFFECT_IDS, {}) == boss_ids_before, "boss rolls do not enter the landing-effect ID namespace")


func _test_hp_zero_boss_restore() -> void:
	var session := _session_at("main", 16, 1, 0, 0)
	_roll_and_finish(session, 1)
	_expect(session.player_hp() == 0 and session.phase() == Session.PHASE_RUN_OVER and session.best_score() == session.score(), "HP zero records GAME OVER and BEST at the stable boundary")
	var dto: Dictionary = SaveData.from_session(session)
	_expect(SaveData.validate(dto).ok and not dto.session_state.boss_entered, "bossless HP-zero RUN_OVER is DTO-valid")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(dto.session_state, 10) and restored.phase() == Session.PHASE_RUN_OVER and restored.player_hp() == 0 and restored.boss_snapshot().is_empty(), "bossless RUN_OVER restores without healing or award replay")
	var legacy_boss := Session.new()
	_expect(legacy_boss.enter_boss(0), "legacy HP-zero boss normalization fixture enters boss while healthy")
	var legacy_state: Dictionary = legacy_boss.stable_save_snapshot(1)
	legacy_state.player.hp = 0
	legacy_state.player.life = 0
	var normalized := Session.new()
	_expect(normalized.restore_stable_snapshot(legacy_state, 2) and normalized.phase() == Session.PHASE_RUN_OVER and normalized.boss_snapshot().is_empty(), "legacy HP0 boss phase normalizes to bossless RUN_OVER without replay")


func _test_stage_flag_compatibility() -> void:
	var legacy: RefCounted = Session.new()
	var state: Dictionary = legacy.stable_save_snapshot()
	state.player.stage_flags = {"legacy_unknown_key": true}
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(state) and restored.next_basic_move_penalty() == 0 and restored.last_tile_effect_result().is_empty(), "schema-v1 stage flags may omit all new keys")
	_expect(bool(restored.stage_flags().get("legacy_unknown_key", false)), "unknown schema-v1 stage flag keys remain accepted")
	var valid_dto: Dictionary = SaveData.from_session(restored)
	_expect(SaveData.validate(valid_dto).ok, "unknown stage flags remain DTO-valid")
	var invalid_dto: Dictionary = valid_dto.duplicate(true)
	invalid_dto.session_state.player.stage_flags[Session.STAGE_FLAG_NEXT_MOVE_PENALTY] = 2
	_expect(not SaveData.validate(invalid_dto).ok, "known next-move stage flag rejects invalid stacking")


func _test_warp_destination_only() -> void:
	var session := _session_at("main", 23, 3)
	_roll_and_finish(session, 1)
	_expect(session.position() == {"route_id":"loop_oasis_ring","tile_index":3} and session.player_hp() == 3 and session.last_tile_effect_result().is_empty(), "warp resolves only its final LOOP_ENTRY destination")


func _session_at(route_id: String, tile_index: int, hp := 3, coins := 0, life := 3) -> RefCounted:
	var session: RefCounted = Session.new()
	var state: Dictionary = session.stable_save_snapshot()
	_set_position(state, route_id, tile_index)
	state.player.hp = hp
	state.player.coins = coins
	state.player.life = life
	if route_id == Course.ROUTE_LOOP_OASIS:
		state.route.active_warp_gate_id = "W1"
	elif route_id == Course.ROUTE_LOOP_TOMB:
		state.route.active_warp_gate_id = "W3"
	_expect(session.restore_stable_snapshot(state), "effect test position restores: %s:%d" % [route_id, tile_index])
	return session


func _choice_session(route_id: String, tile_index: int, pending_face: int, coins: int) -> RefCounted:
	var session: RefCounted = Session.new()
	var state: Dictionary = session.stable_save_snapshot()
	_set_position(state, route_id, tile_index)
	state.phase = "CHOICE_REQUIRED"
	state.route.pending_face = pending_face
	state.route.pending_remaining_steps = pending_face
	state.route.available_route_ids = ["main"]
	state.player.coins = coins
	_expect(SaveData.validate({"schema_version":SaveData.SCHEMA_VERSION,"course_version":SaveData.COURSE_VERSION,"app_version":"v0.8","saved_at":"","saved_at_unix":0,"stage_id":"cairo_hourglass","character_id":"relaxed","session_state":state,"pending_transaction":null}).ok, "choice effect fixture is DTO-valid")
	_expect(session.restore_stable_snapshot(state), "choice effect fixture restores")
	return session


func _set_position(state: Dictionary, route_id: String, tile_index: int) -> void:
	state.route.route_id = route_id
	state.route.tile_index = tile_index
	state.route.current_node_id = "%s:%d" % [route_id, tile_index]
	state.route.loop_id = route_id if route_id in [Course.ROUTE_LOOP_OASIS, Course.ROUTE_LOOP_TOMB] else ""
	state.route.loop_tile_index = tile_index if not state.route.loop_id.is_empty() else -1


func _roll_and_finish(session: RefCounted, face: int) -> Dictionary:
	var started: Dictionary = session.start_roll(face)
	if not bool(started.get("ok", false)):
		return started
	_consume_hops(session)
	return session.finish_movement()


func _consume_hops(session: RefCounted) -> void:
	while session.has_pending_hops():
		session.next_hop()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
