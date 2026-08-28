extends RefCounted
class_name HighLowModel

## Pure HIGH / LOW rules.  The screen owns animation and persistence; this
## model only receives explicit faces so a recorded roll can never be
## re-rolled during a resume.

const BET_AMOUNTS := [10, 20, 50]
const CHOICES := ["low", "same", "high"]
const MAX_STREAK := 5

## A zero multiplier is used for a boundary-disabled choice.  Callers should
## use is_choice_available() rather than treating x0.0 as a playable bet.
const MULTIPLIER_TABLE := {
	1: {"low": 0.0, "same": 5.5, "high": 1.1},
	2: {"low": 5.5, "same": 5.5, "high": 1.4},
	3: {"low": 2.8, "same": 5.5, "high": 1.8},
	4: {"low": 1.8, "same": 5.5, "high": 2.8},
	5: {"low": 1.4, "same": 5.5, "high": 5.5},
	6: {"low": 1.1, "same": 5.5, "high": 0.0},
}

const WINNING_FACE_TABLE := {
	1: {"low": [], "same": [1], "high": [2, 3, 4, 5, 6]},
	2: {"low": [1], "same": [2], "high": [3, 4, 5, 6]},
	3: {"low": [1, 2], "same": [3], "high": [4, 5, 6]},
	4: {"low": [1, 2, 3], "same": [4], "high": [5, 6]},
	5: {"low": [1, 2, 3, 4], "same": [5], "high": [6]},
	6: {"low": [1, 2, 3, 4, 5], "same": [6], "high": []},
}

static func new_game(bet_amount: int, current_value: int = 0) -> Dictionary:
	var bet := maxi(0, bet_amount)
	var current := clampi(current_value, 0, 6)
	return {
		"bet": bet,
		"pot": bet,
		"current": current,
		"streak": 0,
		"active": bet > 0,
		"finished": false,
		"payout": 0,
		"last_roll": 0,
		"last_choice": "",
		"last_kind": "",
		"result": "",
		"auto_cashed": false,
		"phase": "active" if current > 0 and bet > 0 else "setup",
	}

static func initialise_current(state: Dictionary, current_value: int) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("active", false)) or bool(next.get("finished", false)):
		return next
	if current_value < 1 or current_value > 6:
		return next
	var value := current_value
	next["current"] = value
	next["phase"] = "active"
	next["last_kind"] = "initial"
	return next

static func set_current(state: Dictionary, current_value: int) -> Dictionary:
	return initialise_current(state, current_value)

static func multiplier_for(current_value: int, choice: String) -> float:
	if current_value < 1 or current_value > 6:
		return 0.0
	var current := current_value
	var normalized := choice.strip_edges().to_lower()
	if not MULTIPLIER_TABLE.has(current):
		return 0.0
	return float((MULTIPLIER_TABLE[current] as Dictionary).get(normalized, 0.0))

static func multiplier_for_choice(current_value: int, choice: String) -> float:
	return multiplier_for(current_value, choice)

static func winning_faces(current_value: int, choice: String) -> Array[int]:
	if current_value < 1 or current_value > 6:
		return []
	var current := current_value
	var normalized := choice.strip_edges().to_lower()
	if not WINNING_FACE_TABLE.has(current):
		return []
	var values: Array = (WINNING_FACE_TABLE[current] as Dictionary).get(normalized, []) as Array
	var result: Array[int] = []
	for value: Variant in values:
		result.append(int(value))
	return result

static func winning_range(current_value: int, choice: String) -> Array[int]:
	return winning_faces(current_value, choice)

static func is_choice_available(current_value: int, choice: String) -> bool:
	if current_value < 1 or current_value > 6:
		return false
	var current := current_value
	var normalized := choice.strip_edges().to_lower()
	if normalized not in CHOICES or current < 1 or current > 6:
		return false
	return not winning_faces(current, normalized).is_empty()

static func choice_available(current_value: int, choice: String) -> bool:
	return is_choice_available(current_value, choice)

static func potential_payout(state: Dictionary, choice: String) -> int:
	if not bool(state.get("active", false)) or bool(state.get("finished", false)):
		return 0
	var current := int(state.get("current", 0))
	if not is_choice_available(current, choice):
		return 0
	return maxi(0, floori(float(int(state.get("pot", 0))) * multiplier_for(current, choice)))

static func payout_for_pot(pot: int, current_value: int, choice: String) -> int:
	if not is_choice_available(current_value, choice):
		return 0
	return maxi(0, floori(float(maxi(0, pot)) * multiplier_for(current_value, choice)))

static func apply_choice(state: Dictionary, choice: String, rolled_value: int) -> Dictionary:
	return resolve_choice(state, choice, rolled_value)

static func resolve_choice(state: Dictionary, choice: String, rolled_value: int) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("active", false)) or bool(next.get("finished", false)):
		return next
	var current := int(next.get("current", 0))
	var normalized := choice.strip_edges().to_lower()
	var roll := int(rolled_value)
	if current < 1 or current > 6 or not is_choice_available(current, normalized) or roll < 1 or roll > 6:
		return next

	next["last_choice"] = normalized
	next["last_roll"] = roll
	next["last_kind"] = "win" if _is_win(current, normalized, roll) else "miss"
	if not _is_win(current, normalized, roll):
		next["pot"] = 0
		next["payout"] = 0
		next["streak"] = 0
		next["active"] = false
		next["finished"] = true
		next["phase"] = "result"
		next["result"] = "miss"
		return next

	var multiplier := multiplier_for(current, normalized)
	next["pot"] = maxi(0, floori(float(int(next.get("pot", 0))) * multiplier))
	next["current"] = roll
	next["streak"] = int(next.get("streak", 0)) + 1
	next["payout"] = 0
	if int(next["streak"]) >= MAX_STREAK:
		next["payout"] = int(next["pot"])
		next["active"] = false
		next["finished"] = true
		next["auto_cashed"] = true
		next["phase"] = "result"
		next["result"] = "auto_cash"
	else:
		next["phase"] = "active"
		next["result"] = "win"
	return next

static func apply_roll(state: Dictionary, choice: String, rolled_value: int) -> Dictionary:
	return resolve_choice(state, choice, rolled_value)

static func cash_out(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("active", false)) or bool(next.get("finished", false)):
		return next
	if int(next.get("streak", 0)) < 1 or int(next.get("pot", 0)) <= 0:
		return next
	next["payout"] = maxi(0, int(next.get("pot", 0)))
	next["active"] = false
	next["finished"] = true
	next["phase"] = "result"
	next["result"] = "cashout"
	next["last_kind"] = "cashout"
	return next

static func cashout(state: Dictionary) -> Dictionary:
	return cash_out(state)

static func take_cashout(state: Dictionary) -> Dictionary:
	return cash_out(state)

static func _is_win(current_value: int, choice: String, rolled_value: int) -> bool:
	return rolled_value in winning_faces(current_value, choice)
