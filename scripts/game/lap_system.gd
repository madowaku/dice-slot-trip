class_name LapSystem
extends RefCounted

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const BASE_LAP_POINTS: int = 100
const MIN_LAP_POINTS: int = 100
const LEGACY_LAP_COINS: int = 15
const PENALTY_SCORE_COST: int = 25
const WARP_LAP_BONUS: int = 8
const MAX_CLEAN_STREAK: int = 5
const CLEAN_MULTIPLIERS: Array[float] = [1.0, 1.15, 1.30, 1.50, 1.75, 2.0]

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

static func clean_multiplier_for(streak: int) -> float:
	return CLEAN_MULTIPLIERS[clampi(streak, 0, MAX_CLEAN_STREAK)]

static func next_clean_goal_for(streak: int) -> String:
	var current := clampi(streak, 0, MAX_CLEAN_STREAK)
	for target: int in [2, 3, 5]:
		if current < target:
			return "あと%d回でCLEAN STREAK %d" % [target - current, target]
	return "CLEAN STREAK MAX"

static func preview(state: Dictionary) -> Dictionary:
	var bonus := maxi(0, int(state.get("current_lap_bonus", 0)))
	var roll_count := maxi(0, int(state.get("current_lap_roll_count", 0)))
	var penalty_count := maxi(0, int(state.get("current_lap_penalty_count", 0)))
	var was_clean := bool(state.get("current_lap_clean", true))
	var previous_streak := clampi(int(state.get("clean_streak", 0)), 0, MAX_CLEAN_STREAK)
	var updated_streak := mini(MAX_CLEAN_STREAK, previous_streak + 1) if was_clean else maxi(0, previous_streak - 1)
	var multiplier := clean_multiplier_for(updated_streak) if was_clean else 1.0
	var points := maxi(MIN_LAP_POINTS, int(floor(float(BASE_LAP_POINTS + bonus) * multiplier)))
	var score := maxi(0, int(floor(float(BASE_LAP_POINTS + bonus + speed_bonus_for(roll_count)) * multiplier)) - penalty_count * PENALTY_SCORE_COST)
	return {
		"base_points": BASE_LAP_POINTS,
		"lap_bonus": bonus,
		"roll_count": roll_count,
		"speed_bonus": speed_bonus_for(roll_count),
		"penalty_count": penalty_count,
		"clean": was_clean,
		"previous_clean_streak": previous_streak,
		"clean_streak": updated_streak,
		"multiplier": multiplier,
		"points": points,
		"score": score,
		"next_clean_goal": next_clean_goal_for(updated_streak),
	}

static func resolve(state: Dictionary, resolution_id: String, source: String = "NORMAL") -> Dictionary:
	if resolution_id.is_empty():
		return {}
	var result := preview(state)
	result["lap_number"] = int(state.get("lap_count", state.get("laps", 0))) + 1
	result["total_lap_number"] = int(state.get("total_laps", 0)) + 1
	result["source"] = source
	result["journey_roll_index"] = int(state.get("rolls", 0))
	var milestone_rewards: Array[Dictionary] = []
	if bool(result.clean) and int(result.clean_streak) > int(result.previous_clean_streak):
		match int(result.clean_streak):
			2: milestone_rewards.append({"type": "COIN", "amount_key": "COIN_S"})
			3: milestone_rewards.append({"type": "DICE_ADD_1"})
			5: milestone_rewards.append({"type": "DICE_KEEP"})
	result["milestone"] = int(result.clean_streak) if not milestone_rewards.is_empty() else 0
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
			"clean_streak": int(result.clean_streak),
			"result": result.duplicate(true),
		}],
		"rewards": milestone_rewards,
	}
