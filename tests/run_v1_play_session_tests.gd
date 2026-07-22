extends SceneTree

const Session = preload("res://scripts/game/v1_play_session.gd")
const Race = preload("res://scripts/game/v1_boss_race.gd")
var failures := 0

func _init() -> void:
	_test_carry_and_same_roll_recharge()
	_test_reset_and_first_sand_ignore()
	_test_allowed_modifier_order()
	_test_terminal_results()
	print("V1_PLAY_SESSION_TESTS failures=%d" % failures)
	quit(1 if failures else 0)

func _test_carry_and_same_roll_recharge() -> void:
	var session = Session.new()
	session.play_stage_roll(4)
	session.play_stage_roll(4)
	session.skill.add_charge(3)
	session.skill.toggle_arm()
	session.begin_boss_race()
	_expect(session.slot.faces() == [4, 4] and session.skill.state == session.skill.State.ARMED, "boss entry carries slot and armed skill")
	var turn: Dictionary = session.play_boss_roll(4)
	_expect(turn.focus_used and turn.slot_reward.role == &"TRIPLE", "armed boss roll completes carried TRIPLE")
	_expect(session.skill.gauge == 3 and session.skill.state == session.skill.State.READY, "skill can recharge on its consumption roll")

func _test_reset_and_first_sand_ignore() -> void:
	var session = Session.new()
	session.play_stage_roll(2)
	session.skill.add_charge(2)
	session.begin_boss_race(true)
	session.race.player_position = 2
	session.play_boss_roll(1)
	_expect(session.race.player_position == 3 and session.race.player_pending_modifier == 0 and session.race.player_ignored_sand, "flag ignores first player SAND")
	session.race.player_position = 2
	session.race.boss_position = -10
	session.play_boss_roll(1)
	_expect(session.race.player_pending_modifier == -1, "second player SAND applies")
	session.reset_stage()
	_expect(session.slot.faces().is_empty() and session.skill.gauge == 0 and session.race == null and session.coins == 0, "stage reset clears v1 session state")

func _test_allowed_modifier_order() -> void:
	var session = Session.new()
	session.begin_boss_race()
	var turn: Dictionary = session.play_boss_roll(2, 1)
	_expect(turn.effective_face == 3 and turn.race_turn.boss_roll == 4 and turn.slot_faces == [3], "allowed modifier precedes mirror and slot transfer")

func _test_terminal_results() -> void:
	var leader = Race.new()
	leader.turn_count = 11
	leader.player_position = -9
	leader.boss_position = -12
	leader.player_roll_history.assign([3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3])
	leader.boss_roll_history.assign([4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4])
	leader.play_turn(3)
	_expect(leader.winner == &"PLAYER" and leader.win_reason == Race.WIN_REASON_SAFETY_MAX_TURNS_LEAD, "safety leader wins")
	_expect(leader.result().keys().size() == 7 and leader.result().player_roll_history.size() == 12 and leader.result().boss_roll_history.size() == 12, "result schema and histories are complete")
	var frozen := leader.result()
	_expect(leader.play_turn(6).is_empty() and leader.result() == frozen, "terminal race is immutable")
	var tie = Race.new()
	tie.turn_count = 11
	tie.player_position = -10
	tie.boss_position = -11
	tie.player_roll_history.assign([3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3])
	tie.boss_roll_history.assign([4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4])
	tie.player_pending_modifier = -1
	tie.boss_pending_modifier = -1
	tie.play_turn(3)
	_expect(tie.winner == &"PLAYER" and tie.win_reason == Race.WIN_REASON_SAFETY_MAX_TURNS_TIE, "safety tie favors player")
	var base = Race.new()
	base.player_position = 12
	base.play_turn(1)
	_expect(base.win_reason == Race.WIN_REASON_BASE_MOVE_GOAL, "base goal reason is reported")
	var boost = Race.new()
	boost.player_position = 10
	boost.boss_position = 0
	boost.play_turn(2)
	_expect(boost.winner == &"PLAYER" and boost.win_reason == Race.WIN_REASON_BOOST_MOVE_GOAL, "boost goal reason is reported")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
