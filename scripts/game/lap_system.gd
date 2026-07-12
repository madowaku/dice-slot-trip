class_name LapSystem
extends RefCounted

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const BASE_LAP_POINTS: int = 100
const MIN_LAP_POINTS: int = 100
const LEGACY_LAP_COINS: int = 15
const PENALTY_SCORE_COST: int = 25
const WARP_LAP_BONUS: int = 8

const ROLE_BONUSES: Dictionary = {
	DiceLogicScript.DOUBLE: 8,
	DiceLogicScript.PAIR: 10,
	DiceLogicScript.STRAIGHT: 15,
	DiceLogicScript.TRIPLE: 30,
	DiceLogicScript.ALL_EVEN: 12,
	DiceLogicScript.ALL_ODD: 20,
}

static func role_bonus_for(roles: Dictionary, rolled_dice_count: int) -> int:
	if bool(roles.get("five_of_a_kind", false)) and rolled_dice_count == 5:
		return 60
	var main: StringName = StringName(str(roles.get("main", "")))
	if rolled_dice_count == 2 and main == DiceLogicScript.DOUBLE:
		return int(ROLE_BONUSES[DiceLogicScript.DOUBLE])
	if rolled_dice_count >= 3 and main in [DiceLogicScript.PAIR, DiceLogicScript.STRAIGHT, DiceLogicScript.TRIPLE]:
		return int(ROLE_BONUSES.get(main, 0))
	var support: StringName = StringName(str(roles.get("support", "")))
	if rolled_dice_count >= 3 and support in [DiceLogicScript.ALL_ODD, DiceLogicScript.ALL_EVEN]:
		return int(ROLE_BONUSES.get(support, 0))
	return 0

static func speed_bonus_for(roll_count: int) -> int:
	if roll_count <= 10: return 100
	if roll_count <= 13: return 60
	if roll_count <= 16: return 30
	if roll_count <= 20: return 10
	return 0

static func preview(state: Dictionary) -> Dictionary:
	var bonus := maxi(0, int(state.get("current_lap_bonus", 0)))
	var roll_count := maxi(0, int(state.get("current_lap_roll_count", 0)))
	var penalty_count := maxi(0, int(state.get("current_lap_penalty_count", 0)))
	# CLEAN multipliers intentionally remain out of LAP-01. The field is already
	# persisted for the next slice, but the first foundation always uses x1.00.
	var points := maxi(MIN_LAP_POINTS, BASE_LAP_POINTS + bonus)
	var score := maxi(0, BASE_LAP_POINTS + bonus + speed_bonus_for(roll_count) - penalty_count * PENALTY_SCORE_COST)
	return {
		"base_points": BASE_LAP_POINTS,
		"lap_bonus": bonus,
		"roll_count": roll_count,
		"speed_bonus": speed_bonus_for(roll_count),
		"penalty_count": penalty_count,
		"multiplier": 1.0,
		"points": points,
		"score": score,
	}

static func resolve(state: Dictionary, resolution_id: String, source: String = "NORMAL") -> Dictionary:
	if resolution_id.is_empty():
		return {}
	var result := preview(state)
	result["lap_number"] = int(state.get("lap_count", state.get("laps", 0))) + 1
	result["total_lap_number"] = int(state.get("total_laps", 0)) + 1
	result["source"] = source
	result["journey_roll_index"] = int(state.get("rolls", 0))
	return {
		"resolution_id": resolution_id,
		"result_id": "lap_complete",
		"result": result,
		"state_changes": [{
			"type": "LAP_COMMIT",
			"resolution_id": resolution_id,
			"source": source,
			"points": int(result.points),
			"score": int(result.score),
			"lap_number": int(result.lap_number),
			"total_lap_number": int(result.total_lap_number),
			"coins": LEGACY_LAP_COINS,
			"result": result.duplicate(true),
		}],
		"rewards": [],
	}
