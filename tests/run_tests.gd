extends SceneTree

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const BoardModelScript = preload("res://scripts/game/board_model.gd")
const BossSystemScript = preload("res://scripts/game/boss_system.gd")

var failures: int = 0

func _init() -> void:
	_expect(DiceLogicScript.evaluate([3, 3, 5]).main == &"PAIR", "PAIR")
	_expect(DiceLogicScript.evaluate([4, 2, 3]).main == &"STRAIGHT", "STRAIGHT unordered")
	_expect(DiceLogicScript.evaluate([5, 5, 5]).main == &"TRIPLE", "TRIPLE priority")
	_expect(DiceLogicScript.evaluate([5, 5, 5]).support == &"ALL ODD", "TRIPLE + ALL ODD")
	_expect(DiceLogicScript.evaluate([2, 4, 6]).support == &"ALL EVEN", "ALL EVEN")
	_expect(DiceLogicScript.recommended_indices([1, 6, 6, 2, 6]) == [1, 2, 4], "5 dice recommendation")
	var wrapped: Dictionary = BoardModelScript.move(89, 4)
	_expect(wrapped.index == 3 and wrapped.laps == 1, "89 to 0 lap")
	var long_move: Dictionary = BoardModelScript.move(0, 378)
	_expect(long_move.index == 18 and long_move.laps == 4, "multi lap")
	var simulated_index: int = 0
	var simulated_laps: int = 0
	for distance: int in [10, 11, 8, 14, 9, 12, 7, 15, 6, 13, 10, 11, 8, 14, 9, 12, 7, 15, 6, 13]:
		var simulated: Dictionary = BoardModelScript.move(simulated_index, distance)
		simulated_index = simulated.index
		simulated_laps += simulated.laps
	_expect(simulated_index >= 0 and simulated_index < 90 and simulated_laps == 2, "20 consecutive rolls stay valid")
	var tiles: Array[StringName] = BoardModelScript.build_tile_types()
	_expect(tiles.size() == 90, "90 tiles")
	var expected: Dictionary = {&"NORMAL": 46, &"EVENT": 14, &"ITEM": 8, &"COIN": 8, &"WARP": 3, &"SHOP": 2, &"REST": 2, &"LANDMARK": 3, &"BOSS_SCENT": 4}
	for tile_type: StringName in expected:
		_expect(tiles.count(tile_type) == expected[tile_type], "distribution " + tile_type)
	# M3: deterministic, UI-free travel-companion rules.
	var bosses := BossSystemScript.definitions()
	_expect(bosses.size() >= 3, "three Cairo individuals")
	var sleepy := BossSystemScript.definition_by_id("sleepy_sphinx", bosses)
	var individual := BossSystemScript.initial_individual(1)
	_expect(str(individual.get("name", "")) == "眠そうなスフィンクス", "initial sleepy individual")
	_expect(BossSystemScript.encounter_chance(5, 0) > BossSystemScript.encounter_chance(0, 0), "presence raises encounter chance")
	_expect(BossSystemScript.should_encounter(0, 0, true, 0.99), "TRIPLE forced encounter")
	_expect(BossSystemScript.should_encounter(0, BossSystemScript.RELIEF_FORCE_AFTER, false, 0.99), "relief prevents long absence")
	var relief := {"relief": 0}
	for ignored: int in range(5): relief = BossSystemScript.after_no_encounter(relief)
	_expect(int(relief.relief) == 5, "relief caps after failures")
	var pair_outcome := BossSystemScript.resolve_interaction(individual, sleepy, 0, true)
	_expect(int(pair_outcome.gain) == 21 and int(pair_outcome.individual.gauge) == 21, "PAIR bonus once")
	var regular_outcome := BossSystemScript.resolve_interaction(individual, sleepy, 0, false)
	_expect(int(regular_outcome.gain) == 18, "preferred action base gain")
	individual["gauge"] = 99
	individual["stage"] = "trusting"
	var joined_outcome := BossSystemScript.resolve_interaction(individual, sleepy, 1, false)
	_expect(int(joined_outcome.individual.gauge) == 100 and bool(joined_outcome.joined_now), "gauge clamps and joins once")
	_expect(BossSystemScript.stage_for_gauge(24) == "guarded" and BossSystemScript.stage_for_gauge(25) == "remembering" and BossSystemScript.stage_for_gauge(50) == "talking" and BossSystemScript.stage_for_gauge(75) == "trusting", "bond stages")
	var next := BossSystemScript.next_individual("眠そうなスフィンクス", 2, bosses)
	_expect(str(next.get("name", "")) != "眠そうなスフィンクス", "next individual differs")
	print("DICE_SLOT_TRIP_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)

func _expect(value: bool, label: String) -> void:
	if value:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)
