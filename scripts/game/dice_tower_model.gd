extends RefCounted
class_name DiceTowerModel

const MAX_FLOOR := 10
const MULTIPLIERS := {
	1: 1.10,
	2: 1.25,
	3: 1.50,
	4: 1.80,
	5: 2.00,
	6: 2.30,
	7: 2.70,
	8: 3.10,
	9: 3.60,
	10: 4.20,
}

static func new_game(bet_amount: int) -> Dictionary:
	return {
		"bet": maxi(0, bet_amount),
		"floor": 0,
		"roll_count": 0,
		"active": bet_amount > 0,
		"finished": false,
		"busted": false,
		"completed": false,
		"cashed_out": false,
		"payout": 0,
		"last_roll": 0,
		"last_kind": "",
		"highest_floor": 0,
		"floor_before_bust": 0,
		"lost_payout": 0,
	}

static func multiplier_for_floor(floor_number: int) -> float:
	if floor_number < 1 or floor_number > MAX_FLOOR:
		return 0.0
	return float(MULTIPLIERS.get(floor_number, 0.0))

static func payout_for_floor(bet_amount: int, floor_number: int) -> int:
	if bet_amount <= 0 or floor_number < 1 or floor_number > MAX_FLOOR:
		return 0
	return roundi(float(bet_amount) * multiplier_for_floor(floor_number))

static func cashout_payout(state: Dictionary) -> int:
	return payout_for_floor(int(state.get("bet", 0)), int(state.get("floor", 0)))

static func risk_amount(state: Dictionary) -> int:
	return cashout_payout(state)

static func apply_roll(state: Dictionary, rolled_value: int) -> Dictionary:
	var next := state.duplicate(true)
	var value := clampi(rolled_value, 1, 6)
	if not bool(next.get("active", false)) or bool(next.get("finished", false)):
		return next

	next["roll_count"] = int(next.get("roll_count", 0)) + 1
	next["last_roll"] = value
	next["last_kind"] = ""

	if value == 1:
		next["floor_before_bust"] = int(next.get("floor", 0))
		next["lost_payout"] = cashout_payout(next)
		next["floor"] = 0
		next["finished"] = true
		next["busted"] = true
		next["active"] = false
		next["payout"] = 0
		next["last_kind"] = "bust"
		return next

	var climb := 2 if value == 6 else 1
	var reached_floor := mini(MAX_FLOOR, int(next.get("floor", 0)) + climb)
	next["floor"] = reached_floor
	next["highest_floor"] = maxi(int(next.get("highest_floor", 0)), reached_floor)
	next["last_kind"] = "leap" if value == 6 else "climb"

	if reached_floor >= MAX_FLOOR:
		next["payout"] = payout_for_floor(int(next.get("bet", 0)), MAX_FLOOR)
		next["finished"] = true
		next["completed"] = true
		next["cashed_out"] = true
		next["active"] = false

	return next

static func take_cashout(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("active", false)) or bool(next.get("finished", false)):
		return next
	var floor_number := int(next.get("floor", 0))
	if floor_number < 1:
		return next
	next["payout"] = cashout_payout(next)
	next["finished"] = true
	next["cashed_out"] = true
	next["active"] = false
	return next
