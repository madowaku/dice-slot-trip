extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const Course = preload("res://scripts/game/v06_course_model.gd")

var failures := 0


func _init() -> void:
	_test_movement_precedes_commit()
	_test_exact_fork_and_resolution_ack()
	_test_mid_roll_fork_both_routes()
	_test_exact_loop_transfers()
	_test_boss_terminal()
	_test_first_slot_boss_terminal()
	_test_third_slot_boss_resolution_order()
	print("V06_PLAY_SESSION_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


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
	_expect(_roll_and_finish(session, 6).ok and session.position().tile_index == 12, "exact landing reaches fork without prompting")
	_expect(session.phase() == Session.PHASE_READY and session.faces() == [6, 6], "exact fork landing commits second face")
	var started: Dictionary = session.start_roll(4)
	_expect(started.ok and not session.has_pending_hops() and session.faces() == [6, 6], "leaving fork pauses the same third face before movement")
	var choice: Dictionary = session.finish_movement()
	_expect(choice.status == "CHOICE_REQUIRED" and session.pending_face() == 4 and session.pending_remaining_steps() == 4, "fork preserves face and every unspent step")
	_expect(not session.start_roll(2).ok and session.faces() == [6, 6], "a second roll cannot start during route choice")
	_expect(session.choose_route(Course.ROUTE_MAIN).ok, "main route resumes the held roll")
	_consume_hops(session)
	var result: Dictionary = session.finish_movement()
	_expect(result.ok and session.position().tile_index == 16 and session.faces() == [6, 6, 4], "resumed roll commits once at its final destination")
	_expect(session.phase() == Session.PHASE_RESOLUTION_REQUIRED and session.resolution_role() == &"PAIR", "third roll resolves PAIR after movement")
	_expect(not session.start_roll(1).ok and session.faces() == [6, 6, 4], "fourth roll is blocked before acknowledgement")
	_expect(session.acknowledge_resolution() and session.faces().is_empty() and session.position().tile_index == 16, "explicit acknowledgement resets slots but preserves position")
	_expect(not session.acknowledge_resolution(), "resolution cannot be acknowledged twice")


func _test_mid_roll_fork_both_routes() -> void:
	var bypass_session: RefCounted = Session.new()
	_roll_and_finish(bypass_session, 6)
	_roll_and_finish(bypass_session, 4)
	var paused: Dictionary = bypass_session.start_roll(4)
	_expect(paused.ok and _consume_hops(bypass_session).size() == 2, "mid-roll movement reaches the fork one space at a time")
	bypass_session.finish_movement()
	_expect(bypass_session.pending_remaining_steps() == 2 and bypass_session.faces() == [6, 4], "mid-roll fork retains two steps and does not commit")
	bypass_session.choose_route(Course.ROUTE_BYPASS)
	_consume_hops(bypass_session)
	bypass_session.finish_movement()
	_expect(bypass_session.position() == {"route_id":"bypass_sirocco","tile_index":1} and bypass_session.faces() == [6, 4, 4], "bypass resumes and commits the held face once")

	var main_session: RefCounted = Session.new()
	_roll_and_finish(main_session, 6)
	_roll_and_finish(main_session, 4)
	main_session.start_roll(4)
	_consume_hops(main_session)
	main_session.finish_movement()
	main_session.choose_route(Course.ROUTE_MAIN)
	_consume_hops(main_session)
	main_session.finish_movement()
	_expect(main_session.position() == {"route_id":"main","tile_index":14} and main_session.faces() == [6, 4, 4], "main choice consumes the same remaining steps")


func _test_exact_loop_transfers() -> void:
	var session: RefCounted = Session.new()
	_roll_and_finish(session, 6) # main 6
	_roll_and_finish(session, 4) # main 10
	_roll_with_choice(session, 4, Course.ROUTE_MAIN) # main 14, resolution
	_expect(session.acknowledge_resolution(), "pre-loop set acknowledges")
	_roll_and_finish(session, 6) # main 20
	_roll_and_finish(session, 1) # main 21
	var portal_started: Dictionary = session.start_roll(1)
	var portal_path := _consume_hops(session)
	_expect(portal_started.ok and portal_path == [{"route_id":"main","tile_index":22}], "portal path includes its exact landing only")
	session.finish_movement()
	_expect(session.position() == {"route_id":"loop_souk_ring","tile_index":0}, "portal settles at loop 0 through zero-cost transition")
	_expect(session.acknowledge_resolution(), "portal third face resolves before loop roll")
	var exit_started: Dictionary = session.start_roll(4)
	var exit_path := _consume_hops(session)
	_expect(exit_started.ok and exit_path.back() == {"route_id":"loop_souk_ring","tile_index":4}, "exit path visibly reaches loop gate 4")
	session.finish_movement()
	_expect(session.position() == {"route_id":"main","tile_index":23}, "exact loop gate settles at main 23")

	var pass_session: RefCounted = Session.new()
	# Reach loop 2 canonically, then pass exit 4 with a four.
	_roll_and_finish(pass_session, 6)
	_roll_and_finish(pass_session, 4)
	_roll_with_choice(pass_session, 4, Course.ROUTE_MAIN)
	pass_session.acknowledge_resolution()
	_roll_and_finish(pass_session, 6)
	_roll_and_finish(pass_session, 1)
	_roll_and_finish(pass_session, 1)
	pass_session.acknowledge_resolution()
	_roll_and_finish(pass_session, 2)
	_roll_and_finish(pass_session, 4)
	_expect(pass_session.position() == {"route_id":"loop_souk_ring","tile_index":6}, "passing loop gate stays in the ring")


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
	_roll_and_finish(session, 6)
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
	_roll_and_finish(session, 4)
	_roll_with_choice(session, 4, Course.ROUTE_MAIN)
	session.acknowledge_resolution()
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 1)
	_roll_and_finish(session, 2)
	session.acknowledge_resolution()
	_expect(session.position() == {"route_id":"main","tile_index":23} and session.faces().is_empty(), "canonical setup reaches main 23 with empty slots")


func _reach_main_49_with_empty_slots(session: RefCounted) -> void:
	_reach_main_23_with_empty_slots(session)
	_roll_and_finish(session, 3)
	_roll_and_finish(session, 3)
	_roll_and_finish(session, 3)
	session.acknowledge_resolution()
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 5)
	session.acknowledge_resolution()
	_expect(session.position() == {"route_id":"main","tile_index":49} and session.faces().is_empty(), "data-driven setup reaches main 49 with empty slots")


func _reach_main_55_with_empty_slots(session: RefCounted) -> void:
	_reach_main_23_with_empty_slots(session)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 6)
	session.acknowledge_resolution()
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 2)
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
