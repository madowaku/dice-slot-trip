extends RefCounted
class_name VaultBreakRules

## Pure VAULT BREAK face and payout rules. Runtime data can replace the
## default lock table, while these defaults keep isolated model tests useful.

const BET_OPTIONS: Array[int] = [10, 20, 50]
const DIE_SIDES := 6
const DEFAULT_LOCK_RULES := {
	"low": {"accepted_faces": [1, 2, 3]},
	"high": {"accepted_faces": [4, 5, 6]},
	"odd": {"accepted_faces": [1, 3, 5]},
	"even": {"accepted_faces": [2, 4, 6]},
	"edge": {"accepted_faces": [1, 6]},
	"exact": {"mode": "exact"},
}

static func is_valid_face(face: int) -> bool:
	return face >= 1 and face <= DIE_SIDES

static func is_valid_bet(bet_amount: int) -> bool:
	return bet_amount in BET_OPTIONS

static func accepts_face(lock_data: Dictionary, face: int, lock_rule_definitions: Dictionary = DEFAULT_LOCK_RULES) -> bool:
	if not is_valid_face(face):
		return false
	var rule_name := str(lock_data.get("rule", ""))
	if rule_name == "exact":
		if not lock_data.has("value"):
			return false
		return face == int(lock_data.get("value", 0))
	if not lock_rule_definitions.has(rule_name):
		return false
	var rule_data: Dictionary = lock_rule_definitions.get(rule_name, {}) as Dictionary
	var accepted_faces: Array = rule_data.get("accepted_faces", []) as Array
	# JSON numbers are decoded as floats by Godot. Compare their numeric value
	# instead of relying on Variant membership's type-sensitive equality.
	for accepted_value: Variant in accepted_faces:
		if (typeof(accepted_value) == TYPE_INT or typeof(accepted_value) == TYPE_FLOAT) and int(accepted_value) == face:
			return true
	return false

static func accepted_faces_for_lock(lock_data: Dictionary, lock_rule_definitions: Dictionary = DEFAULT_LOCK_RULES) -> Array[int]:
	var result: Array[int] = []
	for face: int in range(1, DIE_SIDES + 1):
		if accepts_face(lock_data, face, lock_rule_definitions):
			result.append(face)
	return result

static func reward_for_bet(bet_amount: int, payout_multiplier: float) -> int:
	if bet_amount < 0 or payout_multiplier <= 0.0:
		return 0
	return floori(float(bet_amount) * payout_multiplier)
