extends SceneTree

const V06BossBattleScript = preload("res://scripts/game/v06_boss_battle.gd")

var failures := 0


func _init() -> void:
	_test_mirror_rolls_and_lane_effects()
	_test_player_victory_and_boss_victory()
	_test_slot_carry_and_role_resolution()
	_test_exact_arrival_tie()
	_test_snapshot_restore_and_rejections()
	print("V06_BOSS_BATTLE_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_mirror_rolls_and_lane_effects() -> void:
	for face: int in range(1, 7):
		var battle: RefCounted = V06BossBattleScript.new()
		var event: Dictionary = battle.roll_face(face)
		var result: Dictionary = event.get("result", {})
		_expect(event.status == "TURN_RESOLVED" and int(result.player_roll) == face and int(result.boss_roll) == 7 - face, "face %d produces public mirror face %d" % [face, 7 - face])
		_expect(int(result.player_roll) + int(result.boss_roll) == 7, "mirror pair sums to seven")
	var player_sand: RefCounted = V06BossBattleScript.new()
	var sand_result: Dictionary = player_sand.roll_face(3).result
	_expect(sand_result.player_effect == "SAND_IGNORED" and player_sand.snapshot().player_next_modifier == 0, "first player SAND is ignored by the Cairo flag")
	var boss_sand: RefCounted = V06BossBattleScript.new()
	var boss_sand_result: Dictionary = boss_sand.roll_face(4).result
	_expect(boss_sand_result.boss_effect == "SAND" and boss_sand.snapshot().boss_next_modifier == -1, "Sphinx SAND queues minus one for its next base move")
	_expect(boss_sand.acknowledge_round(), "SAND turn acknowledges")
	var modified: Dictionary = boss_sand.roll_face(6).result
	_expect(modified.boss_roll == 1 and modified.boss_move == 1 and modified.boss_modifier_used == -1, "minimum movement prevents SAND deadlock")
	var wind: RefCounted = V06BossBattleScript.new()
	var wind_first: Dictionary = wind.roll_face(5).result
	_expect(wind_first.player_effect == "WIND" and wind.snapshot().player_next_modifier == 1, "WIND queues plus one")
	_expect(wind.acknowledge_round(), "WIND turn acknowledges")
	var wind_second: Dictionary = wind.roll_face(1).result
	_expect(wind_second.player_move == 2 and wind_second.player_modifier_used == 1, "queued WIND applies to the next base move")


func _test_player_victory_and_boss_victory() -> void:
	var player: RefCounted = V06BossBattleScript.new()
	var first: Dictionary = player.roll_face(6).result
	_expect(first.player_position_after == 8 and first.player_effect == "BOOST" and first.boss_position_after == 1, "player BOOST adds two without chaining")
	_expect(player.acknowledge_round(), "first winning-path turn acknowledges")
	var player_finish: Dictionary = player.roll_face(6).result
	_expect(player_finish.victory and player_finish.winner == "player" and player.snapshot().terminal, "two high rolls win the 13-space race")
	_expect(player_finish.turn_count == 2 and player_finish.player_roll_history == [6, 6] and player_finish.boss_roll_history == [1, 1] and player_finish.boss_stamp == "cairo_sphinx_win", "terminal result exposes the Sphinx record fields")
	_expect(not player.roll_face(6).ok and player.acknowledge_round(), "terminal race blocks rolls and accepts one result acknowledgment")
	_expect(player.snapshot().terminal and not player.snapshot().pending_ack, "terminal result remains stable after acknowledgment")
	var sphinx: RefCounted = V06BossBattleScript.new()
	var low_first: Dictionary = sphinx.roll_face(1).result
	_expect(low_first.boss_position_after == 8 and low_first.boss_effect == "BOOST", "Sphinx receives the same BOOST layout")
	_expect(sphinx.acknowledge_round(), "first losing-path turn acknowledges")
	var sphinx_finish: Dictionary = sphinx.roll_face(1).result
	_expect(sphinx_finish.defeat and sphinx_finish.winner == "boss" and sphinx.snapshot().terminal, "two low rolls record a Sphinx victory without retry")


func _test_slot_carry_and_role_resolution() -> void:
	var battle: RefCounted = V06BossBattleScript.new()
	_expect(battle.configure_lap(2, 2, [4, 4]), "boss race accepts HP and two carried slot faces")
	_expect(battle.faces() == [4, 4] and battle.snapshot().boss_id == "sphinx", "carried slot and current Sphinx identity are visible")
	var triple: Dictionary = battle.roll_face(4).result
	_expect(triple.role == &"TRIPLE" and battle.faces() == [4, 4, 4], "first boss-race roll can complete a carried TRIPLE")
	_expect(battle.acknowledge_round() and battle.faces().is_empty(), "completed slot resets only after turn acknowledgment")
	var partial: Dictionary = battle.roll_face(2).result
	_expect(partial.role == &"" and battle.faces() == [2], "next race roll starts the next shared 3ROLL SLOT set")


func _test_exact_arrival_tie() -> void:
	var source: RefCounted = V06BossBattleScript.new()
	var state: Dictionary = source.snapshot()
	state.player_position = 12
	state.boss_position = 12
	var tied: RefCounted = V06BossBattleScript.new()
	_expect(tied.restore_snapshot(state), "pre-goal tied race snapshot restores")
	var result: Dictionary = tied.roll_face(1).result
	_expect(result.victory and result.winner == "player" and result.win_reason == "BASE_MOVE_GOAL", "exact same arrival step favors the player")


func _test_snapshot_restore_and_rejections() -> void:
	var battle: RefCounted = V06BossBattleScript.new()
	_expect(not battle.configure_lap(0) and not battle.roll_face(0).ok and not battle.roll_face(7).ok, "invalid lap and faces are rejected")
	var result: Dictionary = battle.roll_face(4).result
	var pending_snapshot: Dictionary = battle.snapshot()
	var restored_pending: RefCounted = V06BossBattleScript.new()
	_expect(restored_pending.restore_snapshot(pending_snapshot) and restored_pending.result() == result, "turn-result checkpoint restores without replay")
	_expect(not restored_pending.roll_face(2).ok and restored_pending.acknowledge_round(), "restored result requires acknowledgment before another roll")
	var ready_snapshot: Dictionary = restored_pending.snapshot()
	var restored_ready: RefCounted = V06BossBattleScript.new()
	_expect(restored_ready.restore_snapshot(ready_snapshot) and restored_ready.faces() == [4], "between-turn checkpoint preserves partial SLOT and positions")
	var corrupt: Dictionary = ready_snapshot.duplicate(true)
	corrupt.boss_roll_history[0] = 4
	_expect(not V06BossBattleScript.new().restore_snapshot(corrupt), "non-mirror history is rejected")


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
