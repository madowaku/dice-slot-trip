extends SceneTree

const V06BossBattleScript = preload("res://scripts/game/v06_boss_battle.gd")

var failures: int = 0


func _init() -> void:
	_test_victory_sequence()
	_test_defeat_sequence()
	_test_lap_defenses()
	_test_rejections_and_snapshots()
	print("V06_BOSS_BATTLE_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_victory_sequence() -> void:
	var battle: RefCounted = V06BossBattleScript.new()
	var first := _roll_round(battle, [2, 3, 4])
	_expect(first.sum == 9 and first.defense == 9 and first.boss_hp_before == 3 and first.boss_hp_after == 2, "round 1 tie damages boss")
	_expect(first.action == V06BossBattleScript.ACTION_SAND_GAZE and first.applied_boss_damage == 1, "round 1 action and damage")
	_expect(battle.acknowledge_round(), "round 1 acknowledgment")
	_expect(battle.faces().is_empty() and battle.snapshot().round == 2, "ack starts fresh blank round")
	var second := _roll_round(battle, [2, 2, 6])
	_expect(second.sum == 10 and second.defense == 11 and second.role == &"PAIR" and second.guard, "round 2 PAIR guards failed comparison")
	_expect(second.attempted_player_damage == 1 and second.applied_player_damage == 0, "PAIR reports guarded attempted damage")
	_expect(second.player_hp_after == 3 and second.boss_hp_after == 2, "PAIR guard causes no HP damage")
	_expect(battle.acknowledge_round(), "round 2 acknowledgment")
	var third := _roll_round(battle, [1, 1, 1])
	_expect(third.role == &"TRIPLE" and third.attempted_boss_damage == 2 and third.applied_boss_damage == 2, "TRIPLE ignores defense for two damage")
	_expect(third.boss_hp_before == 2 and third.boss_hp_after == 0 and third.victory, "TRIPLE reaches victory with clamp")
	_expect(battle.snapshot().pending_ack and not battle.snapshot().terminal and not battle.snapshot().victory, "victory candidate waits for acknowledgment")
	_expect(not battle.roll_face(6).ok, "fourth roll rejected while victory acknowledgment waits")
	_expect(battle.acknowledge_round() and battle.faces().is_empty(), "victory acknowledgment clears slots")
	_expect(battle.snapshot().terminal and battle.snapshot().victory, "victory becomes terminal on acknowledgment")
	_expect(not battle.acknowledge_round() and not battle.roll_face(6).ok, "post-victory acknowledgment and roll rejected")


func _test_defeat_sequence() -> void:
	var battle: RefCounted = V06BossBattleScript.new()
	var last_result: Dictionary = {}
	for expected_hp: int in [2, 1, 0]:
		last_result = _roll_round(battle, [1, 2, 3])
		_expect(last_result.player_hp_after == expected_hp and last_result.boss_hp_after == 3, "failed round damages only player to %d" % expected_hp)
		if expected_hp > 0:
			_expect(battle.acknowledge_round(), "failed nonterminal round acknowledgment")
	_expect(last_result.defeat and battle.snapshot().pending_ack and not battle.snapshot().defeat and not battle.snapshot().terminal, "defeat candidate waits for acknowledgment")
	_expect(not battle.roll_face(4).ok, "fourth roll rejected while defeat acknowledgment waits")
	_expect(battle.acknowledge_round() and battle.faces().is_empty(), "defeat acknowledgment clears slots")
	_expect(battle.snapshot().defeat and battle.snapshot().terminal, "defeat becomes terminal on acknowledgment")
	_expect(not battle.acknowledge_round() and not battle.roll_face(4).ok, "post-defeat mutation rejected")


func _test_lap_defenses() -> void:
	for case: Array in [[9, 9], [10, 11], [20, 11], [11, 9]]:
		var battle: RefCounted = V06BossBattleScript.new()
		_expect(battle.configure_lap(case[0]), "lap %d config accepted" % case[0])
		_expect(battle.current_defense() == case[1], "lap %d has defense %d" % case)
		_expect(battle.snapshot().boss_hp == 3 and battle.snapshot().player_hp == 3, "lap enhancement leaves HP unchanged")
	var carried: RefCounted = V06BossBattleScript.new()
	_expect(carried.configure_lap(2, 2), "next lap accepts carried player HP")
	_expect(carried.snapshot().lap == 2 and carried.snapshot().player_hp == 2 and carried.snapshot().boss_hp == 3, "next lap carries player HP and resets boss HP")
	var invalid_before: Dictionary = carried.snapshot()
	_expect(not carried.configure_lap(3, 0) and carried.snapshot() == invalid_before, "zero player HP config rejected without mutation")
	_expect(not carried.configure_lap(3, 4) and carried.snapshot() == invalid_before, "excess player HP config rejected without mutation")


func _test_rejections_and_snapshots() -> void:
	var battle: RefCounted = V06BossBattleScript.new()
	_expect(not battle.configure_lap(0), "invalid lap rejected")
	_expect(not battle.roll_face(0).ok and not battle.roll_face(7).ok and battle.faces().is_empty(), "invalid faces rejected without mutation")
	var completed := _roll_round(battle, [2, 3, 4])
	var before: Dictionary = battle.snapshot()
	_expect(not battle.roll_face(6).ok and battle.snapshot() == before, "fourth roll rejected without mutation")
	var copy: Dictionary = completed.duplicate(true)
	copy.faces[0] = 6
	_expect(battle.result().faces == [2, 3, 4], "result faces are immutable-style copies")
	_expect(battle.acknowledge_round() and not battle.acknowledge_round(), "double acknowledgment rejected")
	_expect(battle.faces().is_empty(), "ack leaves three blank slots")
	_expect(not battle.configure_lap(2), "lap mutation after play rejected")


func _roll_round(battle: RefCounted, values: Array[int]) -> Dictionary:
	var event: Dictionary = {}
	for face: int in values:
		event = battle.roll_face(face)
		_expect(bool(event.get("ok", false)), "face %d accepted" % face)
	return event.get("result", {})


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
