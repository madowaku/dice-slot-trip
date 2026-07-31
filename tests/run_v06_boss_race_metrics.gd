extends SceneTree

const BossBattle = preload("res://scripts/game/v06_boss_battle.gd")
const SAMPLE_COUNT := 10000
const SAMPLE_SEED := 32024


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SAMPLE_SEED
	var turns_total := 0
	var wings_total := 0
	var sands_total := 0
	var intentional_non_six_total := 0
	var pre_final_gap_total := 0
	var races_at_most_five := 0
	var races_seven_or_eight := 0
	for ignored: int in range(SAMPLE_COUNT):
		var battle: RefCounted = BossBattle.new()
		battle.configure_lap(1)
		while not bool(battle.snapshot().get("terminal", false)):
			# Uniformly selecting the visible stop face models an unbiased
			# baseline. Every selected non-six is counted as an intentional
			# alternative to the obvious maximum-distance face.
			var selected_face := rng.randi_range(1, 6)
			var response: Dictionary = battle.roll_face(selected_face)
			if not bool(response.get("ok", false)):
				push_error("metric simulation rejected a legal face")
				quit(1)
				return
			if not bool(battle.snapshot().get("terminal", false)):
				battle.acknowledge_round()
		var result: Dictionary = battle.result()
		var turns := int(result.get("turn_count", 0))
		turns_total += turns
		wings_total += int(result.get("player_wing_count", 0)) + int(result.get("boss_wing_count", 0))
		sands_total += int(result.get("player_sand_count", 0)) + int(result.get("boss_sand_count", 0))
		for face: int in result.get("player_roll_history", []):
			if face != 6:
				intentional_non_six_total += 1
		pre_final_gap_total += absi(int(result.get("player_position_before", 0)) - int(result.get("boss_position_before", 0)))
		if turns <= 5:
			races_at_most_five += 1
		if turns in [7, 8]:
			races_seven_or_eight += 1
	print("BOSS_RACE_METRICS samples=%d seed=%d" % [SAMPLE_COUNT, SAMPLE_SEED])
	print("average_turns=%.3f" % (float(turns_total) / SAMPLE_COUNT))
	print("average_wing_landings=%.3f" % (float(wings_total) / SAMPLE_COUNT))
	print("average_quicksand_landings=%.3f" % (float(sands_total) / SAMPLE_COUNT))
	print("average_intentional_non_six=%.3f" % (float(intentional_non_six_total) / SAMPLE_COUNT))
	print("average_pre_final_gap=%.3f" % (float(pre_final_gap_total) / SAMPLE_COUNT))
	print("races_at_most_five=%.1f%%" % (100.0 * races_at_most_five / SAMPLE_COUNT))
	print("races_seven_or_eight=%.1f%%" % (100.0 * races_seven_or_eight / SAMPLE_COUNT))
	quit()
