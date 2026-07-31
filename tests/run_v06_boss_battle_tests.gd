extends SceneTree

const V06BossBattleScript = preload("res://scripts/game/v06_boss_battle.gd")

var failures := 0


func _init() -> void:
	_test_mirror_rolls_and_asymmetric_preview()
	_test_immediate_lane_effects()
	_test_player_victory_and_boss_victory()
	_test_boss_race_has_no_roll_slot()
	_test_exact_arrival_tie()
	_test_snapshot_restore_and_rejections()
	print("V06_BOSS_BATTLE_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_mirror_rolls_and_asymmetric_preview() -> void:
	for face: int in range(1, 7):
		var battle: RefCounted = V06BossBattleScript.new()
		var event: Dictionary = battle.roll_face(face)
		var result: Dictionary = event.get("result", {})
		_expect(event.status == "TURN_RESOLVED" and int(result.player_roll) == face and int(result.boss_roll) == 7 - face, "face %d produces public mirror face %d" % [face, 7 - face])
		_expect(int(result.player_roll) + int(result.boss_roll) == 7, "mirror pair sums to seven")
	var source: RefCounted = V06BossBattleScript.new()
	var state: Dictionary = source.snapshot()
	state.player_position = 4
	state.boss_position = 5
	var preview_battle: RefCounted = V06BossBattleScript.new()
	_expect(preview_battle.restore_snapshot(state), "asymmetric preview setup restores")
	var preview: Dictionary = preview_battle.landing_preview(3)
	_expect(preview.player_position == 7 and preview.boss_position == 9 and preview.player_tile == "WING_GATE" and preview.boss_tile == "WING_GATE", "one die face previews both concrete lane destinations")
	_expect(preview.player_final_position == 10 and preview.boss_final_position == 12 and preview.player_distance_to_goal == 10 and preview.boss_distance_to_goal == 8, "preview exposes both final positions on the 20-space course")


func _test_immediate_lane_effects() -> void:
	var source: RefCounted = V06BossBattleScript.new()
	var wing_state: Dictionary = source.snapshot()
	wing_state.player_position = 4
	var wing: RefCounted = V06BossBattleScript.new()
	_expect(wing.restore_snapshot(wing_state), "wing setup restores")
	var wing_result: Dictionary = wing.roll_face(3).result
	_expect(wing_result.player_base_position_after == 7 and wing_result.player_position_after == 10 and wing_result.player_effect == "WING_GATE" and wing_result.player_effect_delta == 3, "wing gate immediately advances three")
	_expect(wing_result.player_wing_count == 1 and wing_result.player_sand_count == 0, "wing usage is counted for the finish summary")
	_expect(wing.snapshot().player_next_modifier == 0, "wing gate creates no carried state")
	var quicksand_state: Dictionary = source.snapshot()
	quicksand_state.player_position = 6
	var quicksand: RefCounted = V06BossBattleScript.new()
	_expect(quicksand.restore_snapshot(quicksand_state), "quicksand setup restores")
	var quicksand_result: Dictionary = quicksand.roll_face(3).result
	_expect(quicksand_result.player_base_position_after == 9 and quicksand_result.player_position_after == 7 and quicksand_result.player_effect == "QUICKSAND" and quicksand_result.player_effect_delta == -2, "quicksand immediately returns two")
	_expect(quicksand_result.player_sand_count == 1 and quicksand_result.player_wing_count == 0, "quicksand usage is counted for the finish summary")
	_expect(quicksand.snapshot().player_next_modifier == 0, "quicksand creates no next-turn modifier")
	_expect(not battle_courses_contain_rest(source), "v3.2 course keeps only wing and quicksand special spaces")


func _test_player_victory_and_boss_victory() -> void:
	var player: RefCounted = V06BossBattleScript.new()
	var player_finish: Dictionary = {}
	for index: int in range(4):
		player_finish = player.roll_face(6).result
		if not player.snapshot().terminal:
			_expect(player.acknowledge_round(), "high-roll path turn %d acknowledges" % (index + 1))
	_expect(player_finish.victory and player_finish.winner == "player" and player.snapshot().terminal, "four high rolls win the 20-space race")
	_expect(player_finish.turn_count == 4 and player_finish.boss_stamp == "cairo_sphinx_win", "terminal result exposes Sphinx record fields")
	_expect(not player.roll_face(6).ok and player.acknowledge_round(), "terminal race blocks rolls and accepts one result acknowledgment")
	_expect(player.snapshot().terminal and not player.snapshot().pending_ack, "terminal result remains stable after acknowledgment")
	var sphinx: RefCounted = V06BossBattleScript.new()
	var sphinx_finish: Dictionary = {}
	for index: int in range(4):
		sphinx_finish = sphinx.roll_face(1).result
		if not sphinx.snapshot().terminal:
			_expect(sphinx.acknowledge_round(), "low-roll path turn %d acknowledges" % (index + 1))
	_expect(sphinx_finish.defeat and sphinx_finish.winner == "boss" and sphinx.snapshot().terminal, "four low rolls record a Sphinx victory")


func _test_boss_race_has_no_roll_slot() -> void:
	var battle: RefCounted = V06BossBattleScript.new()
	_expect(battle.configure_lap(2, 2, [4, 4]), "boss race accepts carried HP context")
	_expect(battle.faces().is_empty() and battle.snapshot().course_length == 20, "boss race starts a 20-space course without 3ROLL SLOT carry")
	var turn: Dictionary = battle.roll_face(4).result
	_expect(turn.role == &"" and battle.faces().is_empty(), "boss roll does not fill or evaluate 3ROLL SLOT")


func battle_courses_contain_rest(battle: RefCounted) -> bool:
	return battle.course_tiles(true).has("REST") or battle.course_tiles(false).has("REST")


func _test_exact_arrival_tie() -> void:
	var source: RefCounted = V06BossBattleScript.new()
	var state: Dictionary = source.snapshot()
	state.player_position = 19
	state.boss_position = 19
	var tied: RefCounted = V06BossBattleScript.new()
	_expect(tied.restore_snapshot(state), "pre-goal tied race snapshot restores")
	var result: Dictionary = tied.roll_face(1).result
	_expect(result.victory and result.winner == "player" and result.win_reason == "BASE_MOVE_GOAL", "same-turn arrival still favors the player")


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
	_expect(restored_ready.restore_snapshot(ready_snapshot) and restored_ready.faces().is_empty(), "between-turn checkpoint preserves positions without a boss SLOT")
	var corrupt: Dictionary = ready_snapshot.duplicate(true)
	corrupt.boss_roll_history[0] = 4
	_expect(not V06BossBattleScript.new().restore_snapshot(corrupt), "non-mirror history is rejected")


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
