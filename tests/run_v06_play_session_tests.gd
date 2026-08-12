extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const Course = preload("res://scripts/game/v06_course_model.gd")

var failures := 0


func _init() -> void:
	_test_session_context()
	_test_life_and_completed_lap_contract()
	_test_skill_ready_discovery_lifetime()
	_test_movement_precedes_commit()
	_test_exact_fork_and_resolution_ack()
	_test_mid_roll_fork_both_routes()
	_test_second_shortcut_contract()
	_test_exact_loop_transfers()
	_test_loop_rewards_are_single_use()
	_test_score_and_coin_contract()
	_test_boss_victory_score()
	_test_boss_terminal()
	_test_first_slot_boss_terminal()
	_test_third_slot_boss_resolution_order()
	print("V06_PLAY_SESSION_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_session_context() -> void:
	var configured: RefCounted = Session.new(&"cairo_hourglass", &"gambler")
	var snapshot: Dictionary = configured.snapshot()
	_expect(configured.stage_id() == &"cairo_hourglass" and configured.character_id() == &"gambler" and snapshot.stage_id == "cairo_hourglass" and snapshot.character_id == "gambler", "90-space session keeps the selected stage and traveler IDs")
	var fallback: RefCounted = Session.new(&"", &"")
	_expect(fallback.stage_id() == Session.DEFAULT_STAGE_ID and fallback.character_id() == Session.DEFAULT_CHARACTER_ID, "90-space session defaults missing context to Cairo and explorer cat")
	_expect(fallback.player_hp() == 3 and fallback.player_max_hp() == 3 and fallback.life() == 3, "new journey starts at fixed HP3 with three independent revivals")


func _test_life_and_completed_lap_contract() -> void:
	var lap10 := Session.new()
	var lap10_state: Dictionary = lap10.stable_save_snapshot(0)
	lap10_state.lap = 10
	lap10_state.player.life = 2
	_expect(lap10.restore_stable_snapshot(lap10_state, 0), "lap10 LIFE bonus fixture restores")
	_finish_victory(lap10)
	_expect(lap10.next_lap() and lap10.lap() == 11 and lap10.life() == 3, "completed lap10 restores one LIFE up to the cap")
	var lap20 := Session.new()
	var lap20_state: Dictionary = lap20.stable_save_snapshot(0)
	lap20_state.lap = 20
	lap20_state.player.life = 3
	_expect(lap20.restore_stable_snapshot(lap20_state, 0), "lap20 capped LIFE fixture restores")
	_finish_victory(lap20)
	_expect(lap20.next_lap() and lap20.lap() == 21 and lap20.life() == 3, "completed lap20 leaves full LIFE capped at three")
	var perfect := Session.new()
	_finish_victory(perfect)
	_expect(perfect.player_hp() == 3 and not perfect.heart_roulette_pending() and perfect.heart_roulette_result().is_empty(), "HP3 boss victory is PERFECT and skips recovery roulette")


func _test_skill_ready_discovery_lifetime() -> void:
	var session: RefCounted = Session.new()
	_expect(not session.has_seen_skill_ready_discovery(), "skill READY discovery begins unseen")
	session.mark_skill_ready_discovery_seen()
	var saved: Dictionary = session.stable_save_snapshot(0)
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(saved, 0) and restored.has_seen_skill_ready_discovery(), "skill READY discovery seen flag survives save restore")
	_expect(restored.retry_run() and restored.has_seen_skill_ready_discovery(), "skill READY discovery seen flag survives retry")
	_finish_victory(restored)
	_expect(restored.next_lap() and restored.has_seen_skill_ready_discovery(), "skill READY discovery seen flag survives next lap")


func _finish_victory(session: RefCounted) -> void:
	_expect(session.enter_boss(0), "victory fixture enters the boss")
	for now: int in range(1, 12):
		if session.phase() == Session.PHASE_BOSS_FINISHED:
			break
		session.start_roll(6, now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	_expect(session.phase() == Session.PHASE_BOSS_FINISHED and session.boss_result().victory, "victory fixture reaches a terminal win")


func _test_movement_precedes_commit() -> void:
	var session: RefCounted = Session.new()
	var started: Dictionary = session.start_roll(3)
	_expect(started.ok and session.phase() == Session.PHASE_MOVING, "one face starts one movement")
	_expect(session.faces().is_empty() and session.position() == {"route_id":"main","tile_index":0}, "slot and stable position wait for movement")
	var hops: Array[Dictionary] = _consume_hops(session)
	_expect(hops == [
		{"route_id":"main","tile_index":1},
		{"route_id":"main","tile_index":2},
		{"route_id":"main","tile_index":3},
	], "one-space hops expose the canonical path")
	_expect(session.faces().is_empty(), "face is still uncommitted after the final visible hop")
	var settled: Dictionary = session.finish_movement()
	_expect(settled.ok and session.position().tile_index == 3 and session.faces() == [3], "face commits exactly once after movement settles")
	_expect(not session.finish_movement().ok and session.faces() == [3], "movement cannot be finished twice")


func _test_exact_fork_and_resolution_ack() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 32, [6, 5])
	_expect(session.position().tile_index == 32, "fixture starts on the approved Bazaar fork")
	_expect(session.phase() == Session.PHASE_READY and session.faces() == [6, 5], "exact fork landing commits second face")
	var started: Dictionary = session.start_roll(4)
	_expect(started.ok and not session.has_pending_hops() and session.faces() == [6, 5], "leaving fork pauses the same third face before movement")
	var choice: Dictionary = session.finish_movement()
	_expect(choice.status == "CHOICE_REQUIRED" and session.pending_face() == 4 and session.pending_remaining_steps() == 4, "fork preserves face and every unspent step")
	var previews: Dictionary = session.route_choice_previews()
	_expect(previews.main.position == {"route_id":"main", "tile_index":36} and previews[Course.ROUTE_BYPASS_BAZAAR].position == {"route_id":"bypass_bazaar_alley", "tile_index":3}, "route choice previews both exact landing squares before selection")
	_expect(not session.start_roll(2).ok and session.faces() == [6, 5], "a second roll cannot start during route choice")
	_expect(session.choose_route(Course.ROUTE_MAIN).ok, "main route resumes the held roll")
	_consume_hops(session)
	var result: Dictionary = session.finish_movement()
	_expect(result.ok and session.position().tile_index == 36 and session.faces() == [6, 5, 4], "resumed roll commits once at its final destination")
	_expect(session.phase() == Session.PHASE_RESOLUTION_REQUIRED and session.resolution_role() == &"STRAIGHT", "third roll resolves STRAIGHT after movement")
	_expect(not session.start_roll(1).ok and session.faces() == [6, 5, 4], "fourth roll is blocked before acknowledgement")
	_expect(session.acknowledge_resolution() and session.faces().is_empty() and session.position().tile_index == 36, "explicit acknowledgement resets slots but preserves position")
	_expect(not session.acknowledge_resolution(), "resolution cannot be acknowledged twice")


func _test_mid_roll_fork_both_routes() -> void:
	var bypass_session: RefCounted = Session.new()
	_set_position_and_faces(bypass_session, 30, [6, 3])
	var paused: Dictionary = bypass_session.start_roll(4)
	_expect(paused.ok and _consume_hops(bypass_session).size() == 2, "mid-roll movement reaches the Bazaar fork one space at a time")
	bypass_session.finish_movement()
	_expect(bypass_session.pending_remaining_steps() == 2 and bypass_session.faces() == [6, 3], "mid-roll fork retains two steps and does not commit")
	bypass_session.choose_route(Course.ROUTE_BYPASS_BAZAAR)
	_consume_hops(bypass_session)
	bypass_session.finish_movement()
	_expect(bypass_session.position() == {"route_id":"bypass_bazaar_alley","tile_index":1} and bypass_session.faces() == [6, 3, 4], "Bazaar bypass resumes and commits the held face once")

	var main_session: RefCounted = Session.new()
	_set_position_and_faces(main_session, 30, [6, 3])
	main_session.start_roll(4)
	_consume_hops(main_session)
	main_session.finish_movement()
	main_session.choose_route(Course.ROUTE_MAIN)
	_consume_hops(main_session)
	main_session.finish_movement()
	_expect(main_session.position() == {"route_id":"main","tile_index":34} and main_session.faces() == [6, 3, 4], "main choice consumes the same remaining steps")


func _test_second_shortcut_contract() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 71, [])
	_expect(session.position() == {"route_id":"main","tile_index":71} and session.phase() == Session.PHASE_READY, "fixture starts on the approved Sirocco fork")
	var started: Dictionary = session.start_roll(6)
	_expect(started.ok and session.finish_movement().status == "CHOICE_REQUIRED" and session.pending_bypass().route_id == Course.ROUTE_BYPASS_SIROCCO, "second fork offers only the Sirocco shortcut")
	_expect(session.choose_route(Course.ROUTE_BYPASS_SIROCCO).ok, "Sirocco choice resumes the held six")
	_consume_hops(session)
	session.finish_movement()
	_expect(session.position() == {"route_id":"main","tile_index":83} and session.score() == int(session.score_breakdown().travel), "Sirocco rejoins at REST83 and score remains exactly the travelled distance")


func _test_exact_loop_transfers() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 23, [6, 3])
	var portal_started: Dictionary = session.start_roll(1)
	var portal_path := _consume_hops(session)
	_expect(portal_started.ok and portal_path == [{"route_id":"main","tile_index":24}], "W1 path includes its exact landing only")
	session.finish_movement()
	_expect(session.position() == {"route_id":"loop_oasis_ring","tile_index":3} and session.active_warp_gate_id() == "W1" and "W1" in session.consumed_warp_gate_ids(), "W1 settles at its oasis entry and is consumed")
	_expect(session.acknowledge_resolution(), "W1 third face resolves before ring roll")
	var exit_started: Dictionary = session.start_roll(5)
	var exit_path := _consume_hops(session)
	_expect(exit_started.ok and exit_path.back() == {"route_id":"loop_oasis_ring","tile_index":0}, "exit path visibly reaches oasis EXIT")
	session.finish_movement()
	_expect(session.position() == {"route_id":"main","tile_index":29} and session.active_warp_gate_id().is_empty(), "oasis EXIT returns to approved main29")
	_expect(int(session.score_breakdown().discovery) == 0 and session.score() == int(session.score_breakdown().travel), "W1 and oasis EXIT add no hidden bonus beyond travelled spaces")

	var pass_session: RefCounted = Session.new()
	_set_position_and_faces(pass_session, 23, [6, 3])
	_roll_and_finish(pass_session, 1)
	pass_session.acknowledge_resolution()
	_roll_and_finish(pass_session, 6)
	_expect(pass_session.position() == {"route_id":"loop_oasis_ring","tile_index":1}, "passing oasis EXIT stays in the ring")


func _test_loop_rewards_are_single_use() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 23, [6, 3])
	_roll_and_finish(session, 1)
	session.acknowledge_resolution()
	_roll_and_finish(session, 3)
	var item_score := int(session.score_breakdown().discovery)
	_expect(session.position() == {"route_id":"loop_oasis_ring","tile_index":6} and session.current_tile_kind() == "NORMAL", "collected oasis ITEM becomes NORMAL immediately")
	_expect("loop_oasis_ring:6" in session.consumed_reward_node_keys(), "collected ring reward is recorded as consumed")
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 2)
	_expect(session.position() == {"route_id":"loop_oasis_ring","tile_index":6} and int(session.score_breakdown().discovery) == item_score, "revisiting a ring ITEM awards no discovery score")


func _test_score_and_coin_contract() -> void:
	var session: RefCounted = Session.new()
	_expect(session.score() == 0 and session.coins() == 0 and session.best_score() == 0, "normal journey score and spendable coin start separately at zero")
	_roll_and_finish(session, 4)
	_expect(session.score() == 4 and session.coins() == 2 and session.score_breakdown().travel == 4, "four travelled spaces score exactly four while the COIN reward stays separate")
	_roll_and_finish(session, 1)
	var pair_started: Dictionary = session.start_roll(1)
	_expect(pair_started.ok and session.pending_resolution_role() == &"PAIR" and session.score() == 5 and session.skill_gauge() == 1, "third stopped face awards PAIR skill charge without hidden score")
	_consume_hops(session)
	_expect(session.finish_movement().ok, "pre-awarded PAIR movement still settles once")
	_expect(session.phase() == Session.PHASE_RESOLUTION_REQUIRED, "PAIR result follows the settled movement")
	_expect(session.score() == 6 and session.coins() == 2 and session.resolution_role() == &"PAIR", "movement and PAIR add no hidden score")
	_expect(session.score_breakdown().slot == 0, "slot effects never enter the distance score")
	_expect(session.acknowledge_resolution() and session.score() == 6, "slot acknowledgment preserves the journey distance")
	var mix: RefCounted = Session.new()
	_roll_and_finish(mix, 1)
	_roll_and_finish(mix, 3)
	_roll_and_finish(mix, 5)
	_expect(mix.resolution_role() == &"MIX" and mix.score() == 9 and mix.coins() == 3 and mix.skill_gauge() == 0, "MIX adds one coin on top of the route COIN while score stays at nine travelled spaces")
	var straight: RefCounted = Session.new()
	_roll_and_finish(straight, 2)
	_roll_and_finish(straight, 3)
	_roll_and_finish(straight, 4)
	_expect(straight.resolution_role() == &"STRAIGHT" and straight.score() == 9 and straight.skill_gauge() == 2, "STRAIGHT adds two skill charge while score stays at nine travelled spaces")
	var triple: RefCounted = Session.new()
	_roll_and_finish(triple, 1)
	_roll_and_finish(triple, 1)
	var triple_started: Dictionary = triple.start_roll(1)
	_expect(triple_started.ok and triple.pending_resolution_role() == &"TRIPLE" and triple.skill_gauge() == Session.SKILL_GAUGE_MAX and triple.score() == 2, "TRIPLE becomes READY without adding hidden score")
	_consume_hops(triple)
	_expect(triple.finish_movement().ok and triple.score() == 3 and triple.score_breakdown().slot == 0, "TRIPLE movement adds only its one travelled space")


func _test_boss_victory_score() -> void:
	var session: RefCounted = Session.new()
	_set_hp(session, 1)
	_expect(session.enter_boss(0), "score contract can enter the Sphinx stage")
	_expect(session.start_roll(6, 1).ok and session.boss_result().boss_roll == 1, "first race turn derives the Sphinx mirror roll")
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and session.acknowledge_boss_round(), "first Sphinx race turn resolves")
	for now: int in [2, 3, 4]:
		if session.phase() == Session.PHASE_BOSS_FINISHED:
			break
		_expect(session.start_roll(6, now).ok, "high mirror roll %d resolves" % now)
		if session.phase() != Session.PHASE_BOSS_FINISHED:
			_expect(session.acknowledge_boss_round(), "high mirror roll %d acknowledges" % now)
	_expect(session.boss_result().victory, "high rolls and TRIPLE reach the 20-space race goal")
	_expect(session.score() == 0 and session.best_score() == 0 and session.score_breakdown().slot == 0 and session.score_breakdown().boss == 0 and session.score_breakdown().finish == 0, "boss roles and victory add no hidden score")
	_expect(session.heart_roulette_pending() and session.heart_roulette_options() == [1, 2, 1, 3, 1, 2], "wounded boss victory opens the recovery-only six-segment roulette")
	var pending_heart_state: Dictionary = session.stable_save_snapshot(0)
	var heart_reward: Dictionary = session.resolve_heart_roulette(1)
	_expect(heart_reward.ok and session.player_max_hp() == 3 and session.player_hp() == 3 and not session.heart_roulette_pending(), "+2 roulette result heals HP without changing maximum HP")
	var full_session: RefCounted = Session.new()
	_expect(full_session.restore_stable_snapshot(pending_heart_state, 0), "pending recovery roulette restores")
	var full_reward: Dictionary = full_session.resolve_heart_roulette(3)
	_expect(full_reward.ok and full_session.player_max_hp() == 3 and full_session.player_hp() == 3 and full_reward.result.label == "♥ FULL", "FULL roulette segment heals to fixed HP3")
	_expect(session.acknowledge_boss_round() and session.phase() == Session.PHASE_LAP_RESULT, "victory score survives into the journey result")
	var loss: RefCounted = Session.new()
	_expect(loss.enter_boss(0), "losing score contract enters boss")
	for now: int in range(1, 12):
		if loss.phase() == Session.PHASE_BOSS_FINISHED:
			break
		_expect(loss.start_roll(1, now).ok, "low mirror roll %d resolves" % now)
		if loss.phase() != Session.PHASE_BOSS_FINISHED:
			_expect(loss.acknowledge_boss_round(), "low mirror roll %d acknowledges" % now)
	_expect(loss.boss_result().defeat and loss.acknowledge_boss_round() and loss.phase() == Session.PHASE_LAP_RESULT, "boss loss records the result and completes the stage without RUN_OVER")


func _test_boss_terminal() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 87, [])
	if session.phase() == Session.PHASE_RUN_OVER:
		_expect(session.player_hp() == 0 and not session.start_roll(6).ok and session.boss_snapshot().is_empty(), "HP0 at a stable travel boundary takes priority over boss entry")
		return
	var boss_started: Dictionary = session.start_roll(6)
	var boss_path := _consume_hops(session)
	_expect(boss_started.ok and boss_path.size() == 2 and boss_path.back().tile_index == 89, "data-driven boss movement stops after two visible hops")
	var terminal: Dictionary = session.finish_movement()
	_expect(terminal.status == "BOSS_GATE_REACHED" and session.phase() == Session.PHASE_BOSS_ROLL_READY and session.position().tile_index == 89, "data-driven boss gate enters a fresh battle")
	_expect(session.faces().is_empty() and session.pending_remaining_steps() == 0, "boss race drops the travel slot and discards surplus movement")
	_expect(session.start_roll(1).ok and session.boss_result().boss_roll == 6 and not session.acknowledge_resolution(), "first boss roll routes only to the mirror race")


func _test_first_slot_boss_terminal() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 87, [])
	var terminal: Dictionary = _roll_and_finish(session, 6)
	_expect(terminal.status == "BOSS_GATE_REACHED" and session.faces().is_empty(), "first-slot boss starts without carrying 3ROLL SLOT state")
	_expect(session.phase() == Session.PHASE_BOSS_ROLL_READY and not session.is_boss_terminal(), "first-slot boss enters combat immediately")
	_expect(session.pending_remaining_steps() == 0 and not session.snapshot().boss_transition_pending, "first-slot boss discards surplus without queued result transition")


func _test_third_slot_boss_resolution_order() -> void:
	var session: RefCounted = Session.new()
	_set_position_and_faces(session, 87, [3, 3])
	var terminal: Dictionary = _roll_and_finish(session, 2)
	var before_ack: Dictionary = session.snapshot()
	_expect(terminal.status == "BOSS_GATE_REACHED" and before_ack.position.tile_index == 89, "third-slot roll reaches data-driven boss gate")
	_expect(before_ack.faces == [3, 3, 2] and before_ack.boss_transition_pending, "travel face commits once and queues the boss transition")
	_expect(before_ack.phase == Session.PHASE_RESOLUTION_REQUIRED and before_ack.resolution_role == &"PAIR", "third-slot boss presents PAIR before terminal UI")
	_expect(not session.start_roll(1).ok and session.faces() == [3, 3, 2], "roll remains blocked while boss result awaits acknowledgement")
	_expect(session.acknowledge_resolution(), "boss result acknowledges exactly once")
	var after_ack: Dictionary = session.snapshot()
	_expect(after_ack.faces.is_empty() and after_ack.phase == Session.PHASE_BOSS_ROLL_READY and not after_ack.boss_transition_pending, "ack resets the set once then enters fresh boss combat")
	_expect(not after_ack.boss_terminal and after_ack.pending_remaining_steps == 0, "boss combat has no surplus movement")
	_expect(not session.acknowledge_resolution() and session.start_roll(1).ok, "double travel ack is rejected and one boss roll is accepted")


func _reach_main_23_with_empty_slots(session: RefCounted) -> void:
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 3)
	_roll_and_finish(session, 1)
	session.acknowledge_resolution()
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 3)
	session.acknowledge_resolution()
	_expect(session.position() == {"route_id":"main","tile_index":23} and session.faces().is_empty(), "canonical setup reaches main 23 with empty slots")


func _reach_main_49_with_empty_slots(session: RefCounted) -> void:
	_reach_main_23_with_empty_slots(session)
	_roll_and_finish(session, 6)
	_roll_with_choice(session, 6, Course.ROUTE_MAIN)
	_roll_and_finish(session, 6)
	session.acknowledge_resolution()
	_roll_and_finish(session, 4)
	_roll_and_finish(session, 2)
	_roll_and_finish(session, 2)
	session.acknowledge_resolution()
	_expect(session.position() == {"route_id":"main","tile_index":49} and session.faces().is_empty(), "data-driven setup reaches main 49 with empty slots")


func _reach_main_55_with_empty_slots(session: RefCounted) -> void:
	_reach_main_23_with_empty_slots(session)
	_roll_and_finish(session, 6)
	_roll_with_choice(session, 6, Course.ROUTE_MAIN)
	_roll_and_finish(session, 6)
	session.acknowledge_resolution()
	_roll_and_finish(session, 4)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 4)
	session.acknowledge_resolution()
	_expect(session.position() == {"route_id":"main","tile_index":55} and session.faces().is_empty(), "data-driven setup reaches main 55 with empty slots")


func _set_position_and_faces(session: RefCounted, tile_index: int, face_values: Array) -> void:
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
	_expect(session.restore_stable_snapshot(state, 0), "fixture restores main%d with %d committed faces" % [tile_index, face_values.size()])


func _set_hp(session: RefCounted, hp: int) -> void:
	var state: Dictionary = session.stable_save_snapshot(0)
	state.player.hp = hp
	state.player.max_hp = 3
	state.player.life = 3
	_expect(session.restore_stable_snapshot(state, 0), "fixture restores HP%d with fixed max3/LIFE3" % hp)


func _roll_and_finish(session: RefCounted, face: int) -> Dictionary:
	var started: Dictionary = session.start_roll(face)
	if not started.ok:
		return started
	_consume_hops(session)
	var settled: Dictionary = session.finish_movement()
	if session.phase() == Session.PHASE_EVENT_REQUIRED:
		session.acknowledge_event()
	return settled


func _roll_with_choice(session: RefCounted, face: int, route_id: String) -> Dictionary:
	var first: Dictionary = session.start_roll(face)
	if not first.ok:
		return first
	_consume_hops(session)
	var settled: Dictionary = session.finish_movement()
	if session.phase() != Session.PHASE_CHOICE_REQUIRED:
		return settled
	var resumed: Dictionary = session.choose_route(route_id)
	if not resumed.ok:
		return resumed
	_consume_hops(session)
	var completed: Dictionary = session.finish_movement()
	if session.phase() == Session.PHASE_EVENT_REQUIRED:
		session.acknowledge_event()
	return completed


func _consume_hops(session: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	while session.has_pending_hops():
		result.append(session.next_hop())
	return result


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
