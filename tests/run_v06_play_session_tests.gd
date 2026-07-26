extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const Course = preload("res://scripts/game/v06_course_model.gd")

var failures := 0


func _init() -> void:
	_test_session_context()
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
	_expect(configured.stage_id() == &"cairo_hourglass" and configured.character_id() == &"gambler" and snapshot.stage_id == "cairo_hourglass" and snapshot.character_id == "gambler", "58-space session keeps the selected stage and traveler IDs")
	var fallback: RefCounted = Session.new(&"", &"")
	_expect(fallback.stage_id() == Session.DEFAULT_STAGE_ID and fallback.character_id() == Session.DEFAULT_CHARACTER_ID, "58-space session defaults missing context to Cairo and explorer cat")


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
	_expect(_roll_and_finish(session, 6).ok and session.position().tile_index == 6, "first six reaches main 6")
	_expect(_roll_and_finish(session, 5).ok and session.position().tile_index == 11, "exact landing reaches the Bazaar fork without prompting")
	_expect(session.phase() == Session.PHASE_READY and session.faces() == [6, 5], "exact fork landing commits second face")
	var started: Dictionary = session.start_roll(4)
	_expect(started.ok and not session.has_pending_hops() and session.faces() == [6, 5], "leaving fork pauses the same third face before movement")
	var choice: Dictionary = session.finish_movement()
	_expect(choice.status == "CHOICE_REQUIRED" and session.pending_face() == 4 and session.pending_remaining_steps() == 4, "fork preserves face and every unspent step")
	_expect(not session.start_roll(2).ok and session.faces() == [6, 5], "a second roll cannot start during route choice")
	_expect(session.choose_route(Course.ROUTE_MAIN).ok, "main route resumes the held roll")
	_consume_hops(session)
	var result: Dictionary = session.finish_movement()
	_expect(result.ok and session.position().tile_index == 15 and session.faces() == [6, 5, 4], "resumed roll commits once at its final destination")
	_expect(session.phase() == Session.PHASE_RESOLUTION_REQUIRED and session.resolution_role() == &"STRAIGHT", "third roll resolves STRAIGHT after movement")
	_expect(not session.start_roll(1).ok and session.faces() == [6, 5, 4], "fourth roll is blocked before acknowledgement")
	_expect(session.acknowledge_resolution() and session.faces().is_empty() and session.position().tile_index == 15, "explicit acknowledgement resets slots but preserves position")
	_expect(not session.acknowledge_resolution(), "resolution cannot be acknowledged twice")


func _test_mid_roll_fork_both_routes() -> void:
	var bypass_session: RefCounted = Session.new()
	_roll_and_finish(bypass_session, 6)
	_roll_and_finish(bypass_session, 3)
	var paused: Dictionary = bypass_session.start_roll(4)
	_expect(paused.ok and _consume_hops(bypass_session).size() == 2, "mid-roll movement reaches the Bazaar fork one space at a time")
	bypass_session.finish_movement()
	_expect(bypass_session.pending_remaining_steps() == 2 and bypass_session.faces() == [6, 3], "mid-roll fork retains two steps and does not commit")
	bypass_session.choose_route(Course.ROUTE_BYPASS_BAZAAR)
	_consume_hops(bypass_session)
	bypass_session.finish_movement()
	_expect(bypass_session.position() == {"route_id":"bypass_bazaar_alley","tile_index":1} and bypass_session.faces() == [6, 3, 4], "Bazaar bypass resumes and commits the held face once")

	var main_session: RefCounted = Session.new()
	_roll_and_finish(main_session, 6)
	_roll_and_finish(main_session, 3)
	main_session.start_roll(4)
	_consume_hops(main_session)
	main_session.finish_movement()
	main_session.choose_route(Course.ROUTE_MAIN)
	_consume_hops(main_session)
	main_session.finish_movement()
	_expect(main_session.position() == {"route_id":"main","tile_index":13} and main_session.faces() == [6, 3, 4], "main choice consumes the same remaining steps")


func _test_second_shortcut_contract() -> void:
	var session: RefCounted = Session.new()
	_reach_main_23_with_empty_slots(session)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 5)
	_expect(session.position() == {"route_id":"main","tile_index":34} and session.phase() == Session.PHASE_READY, "exact landing reaches the Sirocco fork")
	var started: Dictionary = session.start_roll(6)
	_expect(started.ok and session.finish_movement().status == "CHOICE_REQUIRED" and session.pending_bypass().route_id == Course.ROUTE_BYPASS_SIROCCO, "second fork offers only the Sirocco shortcut")
	_expect(session.choose_route(Course.ROUTE_BYPASS_SIROCCO).ok, "Sirocco choice resumes the held six")
	_consume_hops(session)
	session.finish_movement()
	_expect(session.position() == {"route_id":"main","tile_index":46} and int(session.score_breakdown().travel) >= Session.SCORE_BYPASS_CLEAR, "Sirocco rejoins at 46 and awards its one-time bypass clear score")


func _test_exact_loop_transfers() -> void:
	var session: RefCounted = Session.new()
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 3)
	var portal_started: Dictionary = session.start_roll(1)
	var portal_path := _consume_hops(session)
	_expect(portal_started.ok and portal_path == [{"route_id":"main","tile_index":10}], "W1 path includes its exact landing only")
	session.finish_movement()
	_expect(session.position() == {"route_id":"loop_oasis_ring","tile_index":3} and session.active_warp_gate_id() == "W1" and "W1" in session.consumed_warp_gate_ids(), "W1 settles at its oasis entry and is consumed")
	_expect(session.acknowledge_resolution(), "W1 third face resolves before ring roll")
	var exit_started: Dictionary = session.start_roll(5)
	var exit_path := _consume_hops(session)
	_expect(exit_started.ok and exit_path.back() == {"route_id":"loop_oasis_ring","tile_index":0}, "exit path visibly reaches oasis EXIT")
	session.finish_movement()
	_expect(session.position() == {"route_id":"main","tile_index":23} and session.active_warp_gate_id().is_empty(), "oasis EXIT returns after W2 without retriggering it")
	_expect(int(session.score_breakdown().discovery) >= Session.SCORE_WARP + Session.SCORE_OASIS_EXIT, "W1 and oasis EXIT add first-time discovery score")

	var pass_session: RefCounted = Session.new()
	_roll_and_finish(pass_session, 6)
	_roll_and_finish(pass_session, 3)
	_roll_and_finish(pass_session, 1)
	pass_session.acknowledge_resolution()
	_roll_and_finish(pass_session, 6)
	_expect(pass_session.position() == {"route_id":"loop_oasis_ring","tile_index":1}, "passing oasis EXIT stays in the ring")


func _test_loop_rewards_are_single_use() -> void:
	var session: RefCounted = Session.new()
	for face: int in [6, 3, 1]:
		_roll_and_finish(session, face)
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
	_roll_and_finish(session, 2)
	_expect(session.score() == 70 and session.coins() == 1 and session.score_breakdown().travel == 70, "two steps plus a COIN stop award 70 score and one coin")
	_roll_and_finish(session, 1)
	var pair_started: Dictionary = session.start_roll(1)
	_expect(pair_started.ok and session.pending_resolution_role() == &"PAIR" and session.score() == 230 and session.skill_gauge() == 1, "third stopped face awards PAIR and gauge before movement")
	_consume_hops(session)
	_expect(session.finish_movement().ok, "pre-awarded PAIR movement still settles once")
	_expect(session.score() == 390 and session.coins() == 1 and session.resolution_role() == &"PAIR", "movement, EVENT stop, and PAIR produce additive score")
	_expect(session.score_breakdown().slot == Session.SCORE_PAIR, "slot breakdown records the pre-movement role award exactly once")
	_expect(session.acknowledge_resolution() and session.score() == 390, "slot acknowledgment preserves the journey score")
	var mix: RefCounted = Session.new()
	_roll_and_finish(mix, 1)
	_roll_and_finish(mix, 3)
	_roll_and_finish(mix, 5)
	_expect(mix.resolution_role() == &"MIX" and mix.score() == 290 and mix.coins() == 1 and mix.skill_gauge() == 0, "MIX adds 50 score and one coin without conflating the resources")
	var straight: RefCounted = Session.new()
	_roll_and_finish(straight, 2)
	_roll_and_finish(straight, 3)
	_roll_and_finish(straight, 4)
	_expect(straight.resolution_role() == &"STRAIGHT" and straight.score() == 610 and straight.skill_gauge() == 2, "STRAIGHT is reachable and adds its 350-point role award and two gauge")
	var triple: RefCounted = Session.new()
	_roll_and_finish(triple, 1)
	_roll_and_finish(triple, 1)
	var triple_started: Dictionary = triple.start_roll(1)
	_expect(triple_started.ok and triple.pending_resolution_role() == &"TRIPLE" and triple.skill_gauge() == Session.SKILL_GAUGE_MAX and triple.score() == 870, "TRIPLE becomes READY without extending into a separate confirmation phase")
	_consume_hops(triple)
	_expect(triple.finish_movement().ok and triple.score_breakdown().slot == Session.SCORE_TRIPLE, "TRIPLE reward remains single-awarded after movement")


func _test_boss_victory_score() -> void:
	var session: RefCounted = Session.new()
	_expect(session.enter_boss(0), "score contract can enter the Sphinx stage")
	for face: int in [2, 3, 4]:
		session.start_roll(face, face)
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and session.acknowledge_boss_round(), "first Sphinx round resolves")
	for face: int in [2, 2, 6]:
		session.start_roll(face, 10 + face)
	_expect(session.phase() == Session.PHASE_BOSS_ROUND_RESULT and session.acknowledge_boss_round(), "second Sphinx round resolves")
	for face: int in [1, 1, 1]:
		session.start_roll(face, 20 + face)
	_expect(session.score() == 3400 and session.best_score() == 3400 and session.score_breakdown().boss == 1500 and session.score_breakdown().finish == 1900, "Sphinx victory and full-HP finish award the score-spec total")
	_expect(session.acknowledge_boss_round() and session.phase() == Session.PHASE_LAP_RESULT, "victory score survives into the journey result")


func _test_boss_terminal() -> void:
	var session: RefCounted = Session.new()
	# v0.7 Cairo keeps the same portal/fork, then extends the main route to 58.
	# Starting at main 55 makes the final six expose exactly two visible hops.
	_reach_main_55_with_empty_slots(session)
	var boss_started: Dictionary = session.start_roll(6)
	var boss_path := _consume_hops(session)
	_expect(boss_started.ok and boss_path.size() == 2 and boss_path.back().tile_index == 57, "data-driven boss movement stops after two visible hops")
	var terminal: Dictionary = session.finish_movement()
	_expect(terminal.status == "BOSS_GATE_REACHED" and session.phase() == Session.PHASE_BOSS_ROLL_READY and session.position().tile_index == 57, "data-driven boss gate enters a fresh battle")
	_expect(session.faces().is_empty() and session.pending_remaining_steps() == 0, "boss starts with blank slots and discards surplus")
	_expect(session.start_roll(1).ok and not session.acknowledge_resolution(), "first boss roll routes only to the battle")


func _test_first_slot_boss_terminal() -> void:
	var session: RefCounted = Session.new()
	_reach_main_23_with_empty_slots(session)
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 4)
	_expect(session.position().tile_index == 29 and session.phase() == Session.PHASE_RESOLUTION_REQUIRED, "first-slot setup completes a set at main 29")
	_expect(session.acknowledge_resolution() and session.faces().is_empty(), "first-slot setup resets before boss arrival")
	_roll_with_choice(session, 6, Course.ROUTE_MAIN)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 6)
	session.acknowledge_resolution()
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 2)
	session.acknowledge_resolution()
	var terminal: Dictionary = _roll_and_finish(session, 6)
	_expect(terminal.status == "BOSS_GATE_REACHED" and session.faces().is_empty(), "first-slot boss normalizes to blank slots")
	_expect(session.phase() == Session.PHASE_BOSS_ROLL_READY and not session.is_boss_terminal(), "first-slot boss enters combat immediately")
	_expect(session.pending_remaining_steps() == 0 and not session.snapshot().boss_transition_pending, "first-slot boss discards surplus without queued result transition")


func _test_third_slot_boss_resolution_order() -> void:
	var session: RefCounted = Session.new()
	_reach_main_49_with_empty_slots(session)
	var terminal: Dictionary = _roll_and_finish(session, 3)
	terminal = _roll_and_finish(session, 3)
	terminal = _roll_and_finish(session, 2)
	var before_ack: Dictionary = session.snapshot()
	_expect(terminal.status == "BOSS_GATE_REACHED" and before_ack.position.tile_index == 57, "third-slot roll reaches data-driven boss gate")
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


func _roll_and_finish(session: RefCounted, face: int) -> Dictionary:
	var started: Dictionary = session.start_roll(face)
	if not started.ok:
		return started
	_consume_hops(session)
	return session.finish_movement()


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
	return session.finish_movement()


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
