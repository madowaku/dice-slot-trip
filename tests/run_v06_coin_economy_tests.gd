extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const Course = preload("res://scripts/game/v06_course_model.gd")

var failures := 0


func _init() -> void:
	_test_wallet_actions_and_mission_progress()
	_test_rest_boost()
	_test_free_shortcut()
	_test_event_option()
	_test_four_space_event_move()
	_test_boss_support()
	_test_boss_support_at_race_start()
	_test_emergency_revive()
	_test_coin_cashout()
	_test_loop_return_risk_is_safe()
	print("V06_COIN_ECONOMY_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_wallet_actions_and_mission_progress() -> void:
	var session := _ready_session(10)
	var before_progress := int(session.mission_state().get("coin_gained", 0))
	var bought: Dictionary = session.purchase_coin_action("risk_insurance")
	_expect(bought.ok and session.coins() == 8 and bool(session.stage_flags().get(Session.STAGE_FLAG_RISK_SHIELD, false)), "RISK insurance costs two coins and arms one guard")
	_expect(int(session.mission_state().get("coin_gained", 0)) == before_progress, "spending never reduces cumulative coin mission progress")
	_expect(not session.purchase_coin_action("risk_insurance").ok and session.coins() == 8, "the same prepared support cannot be bought twice")


func _test_rest_boost() -> void:
	var session := _ready_session(2, "main", 10, 1)
	_expect(session.purchase_coin_action("rest_boost").ok, "REST boost can be prepared during travel")
	_roll_and_finish(session, 1)
	_expect(session.player_hp() == 3 and session.coins() == 0 and not bool(session.stage_flags().get(Session.STAGE_FLAG_NEXT_REST_BOOST, false)), "REST boost spends two, adds one extra HP, and is consumed")


func _test_free_shortcut() -> void:
	var session := _choice_session(0)
	var result: Dictionary = session.choose_route(Course.ROUTE_BYPASS_BAZAAR)
	_expect(result.ok and session.coins() == 0, "shortcut is selectable with zero coins because its shorter risky route is the tradeoff")


func _test_event_option() -> void:
	var session := _event_session("ruin_whisper", 2)
	var result: Dictionary = session.purchase_event_option()
	_expect(result.ok and session.coins() == 0 and bool(session.stage_flags().get(Session.STAGE_FLAG_RISK_SHIELD, false)), "paid ruin guide spends two and grants RISK protection")
	_expect(not session.purchase_event_option().ok, "an EVENT paid option can be used only once")


func _test_four_space_event_move() -> void:
	var session := _event_session("nile_tailwind", 3)
	var purchased: Dictionary = session.purchase_event_option()
	_expect(purchased.ok and session.next_basic_move_bonus() == 4 and session.acknowledge_event(), "camel support arms a four-space bonus for the next roll")
	var started: Dictionary = session.start_roll(5)
	_expect(started.ok and session.pending_move_distance() == 9 and session.pending_hop_count() == 9 and session.next_basic_move_bonus() == 0, "five plus four starts one nine-space move and consumes the bonus immediately")
	while session.has_pending_hops(): session.next_hop()
	var settled: Dictionary = session.finish_movement()
	_expect(settled.ok and session.position() == {"route_id":"main", "tile_index":52} and session.faces() == [5], "the boosted move settles once at its final destination")


func _test_boss_support() -> void:
	var session := _ready_session(4)
	_expect(session.purchase_coin_action("boss_head_start").ok and session.enter_boss(100), "boss head-start can be purchased before the race")
	_expect(int(session.boss_snapshot().get("player_position", 0)) == 3, "boss head-start begins the player three spaces ahead")


func _test_boss_support_at_race_start() -> void:
	var session := _ready_session(5)
	_expect(session.enter_boss(100), "live boss-support fixture enters the race")
	var bought: Dictionary = session.purchase_coin_action("boss_head_start")
	_expect(bought.ok and session.coins() == 1 and int(session.boss_snapshot().get("player_position", 0)) == 3, "boss HUD support purchase applies head-start immediately before the first roll")
	_expect(session.start_roll(2, 200).ok and not session.purchase_coin_action("boss_shield").ok, "boss support shop closes after the first roll")


func _test_emergency_revive() -> void:
	var session := _ready_session(5, "main", 16, 1)
	_roll_and_finish(session, 1)
	_expect(session.phase() == Session.PHASE_READY and session.player_hp() == 3 and session.life() == 2 and not session.can_emergency_revive(), "HP zero uses LIFE and never exposes coin revival")
	var revived: Dictionary = session.emergency_revive(500)
	_expect(not revived.ok and revived.error == "EMERGENCY_REVIVE_REMOVED" and session.coins() == 5, "removed emergency revival cannot spend coins")
	_expect(not session.stage_flags().has(Session.STAGE_FLAG_EMERGENCY_REVIVE_USED), "removed emergency revival never records its legacy flag")


func _test_coin_cashout() -> void:
	var session := _ready_session(8)
	var score_before: int = session.score()
	_expect(session.enter_boss(100), "cashout fixture enters boss")
	for face: int in [6, 6, 6]:
		var rolled: Dictionary = session.start_roll(face, 200 + face)
		if not rolled.ok: break
		if session.phase() == Session.PHASE_BOSS_ROUND_RESULT: session.acknowledge_boss_round()
	_expect(session.last_coin_cashout() == 0 and session.score() == score_before and session.coins() == 8, "lap finish keeps coin and distance score separate with no hidden cashout")
	_expect(session.next_lap() and session.coins() == 0, "the next lap resets the wallet to zero")


func _test_loop_return_risk_is_safe() -> void:
	var session := _ready_session(0, Course.ROUTE_LOOP_TOMB, 5, 2)
	var state: Dictionary = session.stable_save_snapshot()
	state.route.active_warp_gate_id = "W4"
	_expect(session.restore_stable_snapshot(state), "W4 return fixture restores")
	_roll_and_finish(session, 3)
	_expect(session.position() == {"route_id":"main", "tile_index":88} and session.player_hp() == 2, "primary tomb EXIT returns beside the boss without dealing landing damage")


func _ready_session(coins: int, route_id := "main", tile_index := 0, hp := 3) -> RefCounted:
	var session: RefCounted = Session.new()
	var state: Dictionary = session.stable_save_snapshot()
	_set_position(state, route_id, tile_index)
	state.player.coins = coins
	state.player.hp = hp
	state.missions.coin_gained = coins
	state.missions.coin_completed = coins >= Session.MISSION_COIN_TARGET
	if route_id == Course.ROUTE_LOOP_TOMB: state.route.active_warp_gate_id = "W3"
	_expect(session.restore_stable_snapshot(state), "coin economy fixture restores")
	return session


func _choice_session(coins: int) -> RefCounted:
	var session := _ready_session(coins, "main", 32)
	var state: Dictionary = session.stable_save_snapshot()
	state.phase = "CHOICE_REQUIRED"
	state.route.pending_face = 1
	state.route.pending_remaining_steps = 1
	state.route.available_route_ids = ["main", Course.ROUTE_BYPASS_BAZAAR]
	_expect(session.restore_stable_snapshot(state), "shortcut choice fixture restores")
	return session


func _event_session(event_id: String, coins: int) -> RefCounted:
	var event_positions := {"market_hawker":30, "nile_tailwind":43, "ruin_whisper":61, "ferry_offer":77}
	var event_position := int(event_positions.get(event_id, 61))
	var session := _ready_session(coins, "main", event_position)
	var state: Dictionary = session.stable_save_snapshot()
	state.phase = "EVENT_REQUIRED"
	state.active_event = {"event_id":event_id, "node_key":"main:%d" % event_position, "first_visit":true, "score_awarded":true, "return_phase":"READY"}
	_expect(session.restore_stable_snapshot(state), "paid EVENT fixture restores")
	return session


func _set_position(state: Dictionary, route_id: String, tile_index: int) -> void:
	state.route.route_id = route_id
	state.route.tile_index = tile_index
	state.route.current_node_id = "%s:%d" % [route_id, tile_index]
	state.route.loop_id = route_id if route_id in [Course.ROUTE_LOOP_OASIS, Course.ROUTE_LOOP_TOMB] else ""
	state.route.loop_tile_index = tile_index if not state.route.loop_id.is_empty() else -1


func _roll_and_finish(session: RefCounted, face: int) -> Dictionary:
	var started: Dictionary = session.start_roll(face)
	if not bool(started.get("ok", false)): return started
	while session.has_pending_hops(): session.next_hop()
	return session.finish_movement()


func _expect(condition: bool, label: String) -> void:
	if condition: print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
