extends RefCounted
class_name Treasure21Model

## Pure TREASURE 21 rules.  The screen owns randomness, persistence and
## animation; every rule method receives an explicit face so an interrupted
## roll can be resumed without consuming another random number.

const BET_AMOUNTS := [5, 10, 20, 50]
const GOLDEN_NUMBERS := [18, 19, 20]
const START_TOTAL := 0
const TREASURE_TOTAL := 21
const TARGET_TOTAL := TREASURE_TOTAL
const MAX_TOTAL := TREASURE_TOTAL
const CASHOUT_MIN_TOTAL := 17
const CASH_OUT_MIN_TOTAL := CASHOUT_MIN_TOTAL

const NORMAL_MULTIPLIERS := {
	17: 0.4,
	18: 0.6,
	19: 1.0,
	20: 1.2,
	21: 2.0,
}
const GOLDEN_MULTIPLIERS := {
	18: 1.5,
	19: 1.7,
	20: 2.0,
}
const PAYOUT_MULTIPLIERS := NORMAL_MULTIPLIERS
const GOLDEN_BONUS_MULTIPLIERS := GOLDEN_MULTIPLIERS

static func affordable_bet(remembered_bet: int, balance: int) -> int:
	var remembered := remembered_bet if remembered_bet in BET_AMOUNTS else 20
	var chips := maxi(0, balance)
	for index: int in range(BET_AMOUNTS.size() - 1, -1, -1):
		var amount := int(BET_AMOUNTS[index])
		if amount <= chips and amount <= remembered:
			return amount
	return 5

static func highest_affordable_bet(balance: int) -> int:
	return affordable_bet(50, balance)

## Return a fresh deterministic state.  A golden value outside 18..20 is
## normalized to the first authored value so callers never create an invalid
## table lookup.  The first-ever game is passed 19 by the screen.
static func new_game(bet_amount: int, golden_number: int = 19) -> Dictionary:
	var bet := maxi(0, bet_amount)
	var golden := golden_number if golden_number in GOLDEN_NUMBERS else 19
	return {
		"facility_id": "treasure_21",
		"bet": bet,
		"stake": bet,
		"total": START_TOTAL,
		"current_total": START_TOTAL,
		"golden_number": golden,
		"golden": golden,
		"payout": 0,
		"profit": -bet,
		"active": bet > 0,
		"finished": false,
		"phase": "setup" if bet <= 0 else "active",
		"result": "",
		"last_roll": 0,
		"rolled_count": 0,
		"cashout_allowed": false,
		"auto_settled": false,
		"pending_rolls": [],
	}

static func start_game(bet_amount: int, golden_number: int = 19) -> Dictionary:
	return new_game(bet_amount, golden_number)

static func multiplier_for_total(total: int) -> float:
	return float(NORMAL_MULTIPLIERS.get(total, 0.0))

static func multiplier_for(total: int) -> float:
	return multiplier_for_total(total)

static func golden_multiplier_for(golden_number: int) -> float:
	return float(GOLDEN_MULTIPLIERS.get(golden_number, 0.0))

static func is_golden_number(value: int) -> bool:
	return value in GOLDEN_NUMBERS

static func can_cash_out_total(total: int) -> bool:
	return total >= CASHOUT_MIN_TOTAL and total <= TREASURE_TOTAL

static func can_cash_out(state: Dictionary) -> bool:
	if not bool(state.get("active", false)) or bool(state.get("finished", false)):
		return false
	return can_cash_out_total(int(state.get("total", state.get("current_total", 0))))

static func cash_out_available(state: Dictionary) -> bool:
	return can_cash_out(state)

static func payout_for_total(bet_amount: int, total: int) -> int:
	if total < CASHOUT_MIN_TOTAL or total > TREASURE_TOTAL:
		return 0
	return maxi(0, floori(float(maxi(0, bet_amount)) * multiplier_for_total(total)))

static func payout_for(bet_amount: int, total: int) -> int:
	return payout_for_total(bet_amount, total)

static func golden_payout_for(bet_amount: int, golden_number: int) -> int:
	return maxi(0, floori(float(maxi(0, bet_amount)) * golden_multiplier_for(golden_number)))

static func payout_for_golden(bet_amount: int, golden_number: int) -> int:
	return golden_payout_for(bet_amount, golden_number)

## Apply one explicit d6 face. Invalid faces and already settled states are
## no-ops, making repeated callbacks safe during a scene teardown/resume.
static func apply_roll(state: Dictionary, rolled_value: int) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("active", false)) or bool(next.get("finished", false)):
		return next
	if rolled_value < 1 or rolled_value > 6:
		return next
	var bet := maxi(0, int(next.get("bet", next.get("stake", 0))))
	var previous_total := int(next.get("total", next.get("current_total", 0)))
	var total := previous_total + rolled_value
	var golden := int(next.get("golden_number", next.get("golden", 19)))
	next["last_roll"] = rolled_value
	next["rolled_count"] = int(next.get("rolled_count", 0)) + 1
	next["total"] = total
	next["current_total"] = total
	next["cashout_allowed"] = can_cash_out_total(total)
	next["payout"] = 0
	next["profit"] = -bet

	if total > TREASURE_TOTAL:
		next["active"] = false
		next["finished"] = true
		next["phase"] = "result"
		next["result"] = "bust"
		next["auto_settled"] = true
		return next

	# 21 always wins as TREASURE, even if a future caller supplies an invalid
	# golden value. Golden 18/19/20 is checked before normal cash-out values.
	if total == TREASURE_TOTAL:
		next["active"] = false
		next["finished"] = true
		next["phase"] = "result"
		next["result"] = "treasure"
		next["auto_settled"] = true
		next["payout"] = payout_for_total(bet, TREASURE_TOTAL)
		next["profit"] = int(next["payout"]) - bet
		return next

	if total == golden and is_golden_number(golden):
		next["active"] = false
		next["finished"] = true
		next["phase"] = "result"
		next["result"] = "golden"
		next["auto_settled"] = true
		next["payout"] = golden_payout_for(bet, golden)
		next["profit"] = int(next["payout"]) - bet
		return next

	next["active"] = true
	next["finished"] = false
	next["phase"] = "active"
	next["result"] = ""
	return next

static func resolve_roll(state: Dictionary, rolled_value: int) -> Dictionary:
	return apply_roll(state, rolled_value)

static func roll(state: Dictionary, rolled_value: int) -> Dictionary:
	return apply_roll(state, rolled_value)

static func cash_out(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if not can_cash_out(state):
		return next
	var bet := maxi(0, int(next.get("bet", next.get("stake", 0))))
	var total := int(next.get("total", next.get("current_total", 0)))
	var payout := payout_for_total(bet, total)
	next["payout"] = payout
	next["profit"] = payout - bet
	next["active"] = false
	next["finished"] = true
	next["phase"] = "result"
	next["result"] = "cashout"
	next["auto_settled"] = false
	next["cashout_allowed"] = false
	return next

static func cashout(state: Dictionary) -> Dictionary:
	return cash_out(state)

static func take_cashout(state: Dictionary) -> Dictionary:
	return cash_out(state)

## Return all six next-face outcomes in face order.  Each dictionary carries
## enough display data for a screen to make a deterministic danger preview,
## including a stable kind string for styling and QA.
static func danger_preview(total: int, golden_number: int = 19, bet_amount: int = 20) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var golden := golden_number if golden_number in GOLDEN_NUMBERS else 19
	for face: int in range(1, 7):
		var next_total := total + face
		var kind := "progress"
		var payout := 0
		var label := str(next_total)
		if next_total > TREASURE_TOTAL:
			kind = "bust"
			label = "BUST"
		elif next_total == TREASURE_TOTAL:
			kind = "treasure"
			label = "TREASURE 21"
			payout = payout_for_total(bet_amount, TREASURE_TOTAL)
		elif next_total == golden:
			kind = "golden"
			label = "GOLDEN %d" % golden
			payout = golden_payout_for(bet_amount, golden)
		elif next_total >= CASHOUT_MIN_TOTAL:
			kind = "cashout"
			label = "TOTAL %d" % next_total
		result.append({
			"face": face,
			"total": next_total,
			"next_total": next_total,
			"kind": kind,
			"result": kind,
			"label": label,
			"outcome": label,
			"payout": payout,
			"golden": next_total == golden and next_total != TREASURE_TOTAL,
			"treasure": next_total == TREASURE_TOTAL,
			"bust": next_total > TREASURE_TOTAL,
		})
	return result

static func danger_preview_for(state: Dictionary) -> Array[Dictionary]:
	return danger_preview(int(state.get("total", state.get("current_total", 0))), int(state.get("golden_number", state.get("golden", 19))), int(state.get("bet", state.get("stake", 20))))

static func face_outcome(total: int, face: int, golden_number: int = 19, bet_amount: int = 20) -> Dictionary:
	var previews := danger_preview(total, golden_number, bet_amount)
	if face < 1 or face > previews.size():
		return {}
	return previews[face - 1].duplicate(true)
