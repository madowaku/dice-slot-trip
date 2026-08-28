extends RefCounted
class_name DicePokerModel

## Pure DICE POKER rules.
##
## The screen owns randomness, persistence and animation.  Every model action
## receives explicit die values so a pending roll can be replayed exactly after
## a process restart.  A state is always copied before it is changed.

const FACILITY_ID: String = "dice_poker"
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const DIE_COUNT: int = 5
const MAX_REROLLS: int = 2

const RANK_FIVE: String = "FIVE"
const RANK_FOUR: String = "FOUR"
const RANK_FULL_HOUSE: String = "FULL HOUSE"
const RANK_STRAIGHT: String = "STRAIGHT"
const RANK_THREE: String = "THREE"
const RANK_TWO_PAIR: String = "TWO PAIR"
const RANK_ONE_PAIR: String = "ONE PAIR"
const RANK_NO_HAND: String = "NO HAND"

## Rank order is high-to-low.  The return table is the reverse order: a no-hand
## result returns zero, while FIVE returns 2.8x the wager.
const RANKS_HIGH_TO_LOW: Array[String] = [
	RANK_FIVE,
	RANK_FOUR,
	RANK_FULL_HOUSE,
	RANK_STRAIGHT,
	RANK_THREE,
	RANK_TWO_PAIR,
	RANK_ONE_PAIR,
	RANK_NO_HAND,
]
const MULTIPLIERS: Dictionary = {
	RANK_NO_HAND: 0.0,
	RANK_ONE_PAIR: 0.2,
	RANK_TWO_PAIR: 0.4,
	RANK_THREE: 0.6,
	RANK_STRAIGHT: 0.8,
	RANK_FULL_HOUSE: 1.0,
	RANK_FOUR: 1.7,
	RANK_FIVE: 2.8,
}

static func new_game(bet_amount: int) -> Dictionary:
	var bet: int = maxi(0, bet_amount)
	var empty_dice: Array[int] = [0, 0, 0, 0, 0]
	var empty_kept: Array[bool] = [false, false, false, false, false]
	return {
		"facility_id": FACILITY_ID,
		"bet": bet,
		"stake": bet,
		"dice": empty_dice.duplicate(),
		"values": empty_dice.duplicate(),
		"kept": empty_kept.duplicate(),
		"keep_mask": empty_kept.duplicate(),
		"rerolls_used": 0,
		"rerolls_remaining": MAX_REROLLS,
		"max_rerolls": MAX_REROLLS,
		"roll_count": 0,
		"active": bet > 0,
		"finished": false,
		"finalized": false,
		"phase": "setup" if bet > 0 else "idle",
		"rank": RANK_NO_HAND,
		"rank_name": RANK_NO_HAND,
		"multiplier": 0.0,
		"payout": 0,
		"profit": -bet,
		"result": "",
		"last_action": "",
		"last_roll_indices": [],
		"last_roll_values": [],
		"pending_rolls": [],
	}

static func start_game(bet_amount: int) -> Dictionary:
	return new_game(bet_amount)

static func new_state(bet_amount: int) -> Dictionary:
	return new_game(bet_amount)

## Evaluate all five faces.  Invalid input is represented as NO HAND with
## valid=false; callers never receive an exception or a partial role.
static func evaluate(dice: Array) -> Dictionary:
	var faces: Array[int] = _faces_from_array(dice)
	var valid: bool = faces.size() == DIE_COUNT
	if not valid:
		return {
			"rank": RANK_NO_HAND,
			"rank_name": RANK_NO_HAND,
			"label": RANK_NO_HAND,
			"multiplier": 0.0,
			"valid": false,
			"dice": faces.duplicate(),
			"counts": {},
		}

	var counts: Dictionary = {}
	for face: int in faces:
		counts[face] = int(counts.get(face, 0)) + 1
	var frequencies: Array[int] = []
	for key: Variant in counts.keys():
		frequencies.append(int(counts[key]))
	frequencies.sort()
	var sorted_faces: Array[int] = faces.duplicate()
	sorted_faces.sort()
	var straight: bool = sorted_faces == [1, 2, 3, 4, 5] or sorted_faces == [2, 3, 4, 5, 6]
	var rank_name: String = RANK_NO_HAND
	if 5 in frequencies:
		rank_name = RANK_FIVE
	elif 4 in frequencies:
		rank_name = RANK_FOUR
	elif 3 in frequencies and 2 in frequencies:
		rank_name = RANK_FULL_HOUSE
	elif straight:
		rank_name = RANK_STRAIGHT
	elif 3 in frequencies:
		rank_name = RANK_THREE
	elif frequencies.count(2) == 2:
		rank_name = RANK_TWO_PAIR
	elif 2 in frequencies:
		rank_name = RANK_ONE_PAIR
	return {
		"rank": rank_name,
		"rank_name": rank_name,
		"label": rank_name,
		"multiplier": multiplier_for(rank_name),
		"valid": true,
		"dice": faces.duplicate(),
		"counts": counts.duplicate(true),
		"frequencies": frequencies.duplicate(),
		"straight": straight,
	}

static func evaluate_hand(dice: Array) -> Dictionary:
	return evaluate(dice)

static func hand_rank(dice: Array) -> String:
	return str(evaluate(dice).get("rank", RANK_NO_HAND))

static func rank(dice: Array) -> String:
	return hand_rank(dice)

static func rank_for(dice: Array) -> String:
	return hand_rank(dice)

static func multiplier_for(rank_name: String) -> float:
	var normalized: String = rank_name.strip_edges().to_upper()
	return float(MULTIPLIERS.get(normalized, 0.0))

static func multiplier_for_rank(rank_name: String) -> float:
	return multiplier_for(rank_name)

static func rank_multiplier(rank_name: String) -> float:
	return multiplier_for(rank_name)

static func payout_for(bet_amount: int, rank_name: String) -> int:
	var bet: int = maxi(0, bet_amount)
	return maxi(0, floori(float(bet) * multiplier_for(rank_name)))

static func payout_for_rank(bet_amount: int, rank_name: String) -> int:
	return payout_for(bet_amount, rank_name)

static func payout(bet_amount: int, rank_name: String) -> int:
	return payout_for(bet_amount, rank_name)

static func rank_index(rank_name: String) -> int:
	var normalized: String = rank_name.strip_edges().to_upper()
	var index: int = RANKS_HIGH_TO_LOW.find(normalized)
	return index

static func ranks() -> Array[String]:
	return RANKS_HIGH_TO_LOW.duplicate()

static func apply_initial(state: Dictionary, dice: Array) -> Dictionary:
	var faces: Array[int] = _faces_from_array(dice)
	if faces.size() != DIE_COUNT:
		return state.duplicate(true)
	var next: Dictionary = state.duplicate(true)
	_set_dice(next, faces)
	var kept: Array[bool] = [false, false, false, false, false]
	_set_kept(next, kept)
	var hand: Dictionary = evaluate(faces)
	var rank_name: String = str(hand.get("rank", RANK_NO_HAND))
	next["rerolls_used"] = 0
	next["rerolls_remaining"] = MAX_REROLLS
	next["roll_count"] = 0
	next["rank"] = rank_name
	next["rank_name"] = rank_name
	next["multiplier"] = multiplier_for(rank_name)
	next["payout"] = 0
	next["profit"] = -maxi(0, int(next.get("bet", next.get("stake", 0))))
	next["result"] = ""
	next["last_action"] = "deal"
	next["last_roll_indices"] = [0, 1, 2, 3, 4]
	next["last_roll_values"] = faces.duplicate()
	next["pending_rolls"] = []
	next["active"] = true
	next["finished"] = false
	next["finalized"] = false
	next["phase"] = "active"
	return next

static func initialise_hand(state: Dictionary, dice: Array) -> Dictionary:
	return apply_initial(state, dice)

static func initialize_hand(state: Dictionary, dice: Array) -> Dictionary:
	return apply_initial(state, dice)

static func deal(state: Dictionary, dice: Array) -> Dictionary:
	return apply_initial(state, dice)

static func toggle_keep(state: Dictionary, die_index: int) -> Dictionary:
	if not _state_is_playable(state):
		return state.duplicate(true)
	var faces: Array[int] = _state_dice(state)
	if faces.size() != DIE_COUNT or 0 in faces or die_index < 0 or die_index >= DIE_COUNT:
		return state.duplicate(true)
	var next: Dictionary = state.duplicate(true)
	var kept: Array[bool] = _state_kept(state)
	kept[die_index] = not kept[die_index]
	_set_kept(next, kept)
	next["last_action"] = "keep" if kept[die_index] else "unkeep"
	return next

static func toggle_kept(state: Dictionary, die_index: int) -> Dictionary:
	return toggle_keep(state, die_index)

static func set_keep(state: Dictionary, die_index: int, keep: bool) -> Dictionary:
	if not _state_is_playable(state):
		return state.duplicate(true)
	var faces: Array[int] = _state_dice(state)
	if faces.size() != DIE_COUNT or 0 in faces or die_index < 0 or die_index >= DIE_COUNT:
		return state.duplicate(true)
	var next: Dictionary = state.duplicate(true)
	var kept: Array[bool] = _state_kept(state)
	kept[die_index] = keep
	_set_kept(next, kept)
	next["last_action"] = "keep" if keep else "unkeep"
	return next

static func keep_die(state: Dictionary, die_index: int) -> Dictionary:
	return set_keep(state, die_index, true)

static func unkeep_die(state: Dictionary, die_index: int) -> Dictionary:
	return set_keep(state, die_index, false)

static func keep_all(state: Dictionary) -> Dictionary:
	var next: Dictionary = state.duplicate(true)
	if not _state_is_playable(state):
		return next
	var faces: Array[int] = _state_dice(state)
	if faces.size() != DIE_COUNT or 0 in faces:
		return next
	_set_kept(next, [true, true, true, true, true])
	return next

static func is_kept(state: Dictionary, die_index: int) -> bool:
	var kept: Array[bool] = _state_kept(state)
	return die_index >= 0 and die_index < kept.size() and kept[die_index]

static func all_kept(state: Dictionary) -> bool:
	var kept: Array[bool] = _state_kept(state)
	if kept.size() != DIE_COUNT:
		return false
	for value: bool in kept:
		if not value:
			return false
	return true

static func kept_count(state: Dictionary) -> int:
	var result: int = 0
	for value: bool in _state_kept(state):
		if value:
			result += 1
	return result

static func reroll_indices(state: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var kept: Array[bool] = _state_kept(state)
	for index: int in range(DIE_COUNT):
		if index >= kept.size() or not kept[index]:
			result.append(index)
	return result

static func indices_to_reroll(state: Dictionary) -> Array[int]:
	return reroll_indices(state)

static func can_reroll(state: Dictionary) -> bool:
	return _state_is_playable(state) and int(state.get("rerolls_used", 0)) < MAX_REROLLS and not all_kept(state)

static func can_lock_hand(state: Dictionary) -> bool:
	return _state_is_playable(state) and all_kept(state)

static func can_finalize(state: Dictionary) -> bool:
	return _state_is_playable(state) and _state_dice(state).size() == DIE_COUNT and 0 not in _state_dice(state)

static func remaining_rerolls(state: Dictionary) -> int:
	return maxi(0, MAX_REROLLS - int(state.get("rerolls_used", 0)))

## Apply an explicit reroll.  `rerolled_values` may be a full five-face
## mapping, only the unkept faces in order, or values paired with
## `rerolled_indices`.  Kept faces are never changed.
static func apply_reroll(state: Dictionary, rerolled_values: Array, rerolled_indices: Array = []) -> Dictionary:
	if not can_reroll(state):
		return state.duplicate(true)
	var current: Array[int] = _state_dice(state)
	if current.size() != DIE_COUNT or 0 in current:
		return state.duplicate(true)
	var targets: Array[int] = []
	for value: Variant in rerolled_indices:
		var index: int = int(value)
		if index >= 0 and index < DIE_COUNT and index not in targets and not is_kept(state, index):
			targets.append(index)
	if targets.is_empty():
		targets = reroll_indices(state)
	if targets.is_empty():
		return state.duplicate(true)
	var supplied: Array[int] = _faces_from_array(rerolled_values, false)
	if supplied.is_empty() or (supplied.size() != DIE_COUNT and supplied.size() != targets.size()):
		return state.duplicate(true)
	var next: Dictionary = state.duplicate(true)
	var applied_values: Array[int] = []
	for offset: int in range(targets.size()):
		var die_index: int = targets[offset]
		var source_index: int = die_index if supplied.size() == DIE_COUNT else offset
		if source_index < 0 or source_index >= supplied.size():
			return state.duplicate(true)
		current[die_index] = supplied[source_index]
		applied_values.append(supplied[source_index])
	_set_dice(next, current)
	var used: int = int(next.get("rerolls_used", 0)) + 1
	next["rerolls_used"] = mini(MAX_REROLLS, used)
	next["rerolls_remaining"] = maxi(0, MAX_REROLLS - used)
	next["roll_count"] = int(next.get("roll_count", 0)) + 1
	next["last_action"] = "reroll"
	next["last_roll_indices"] = targets.duplicate()
	next["last_roll_values"] = applied_values.duplicate()
	var hand: Dictionary = evaluate(current)
	var rank_name: String = str(hand.get("rank", RANK_NO_HAND))
	next["rank"] = rank_name
	next["rank_name"] = rank_name
	next["multiplier"] = multiplier_for(rank_name)
	if used >= MAX_REROLLS:
		return finalize(next)
	next["phase"] = "active"
	next["result"] = ""
	return next

static func reroll(state: Dictionary, rerolled_values: Array, rerolled_indices: Array = []) -> Dictionary:
	return apply_reroll(state, rerolled_values, rerolled_indices)

static func finalize(state: Dictionary) -> Dictionary:
	if not _state_is_playable(state) or not can_finalize(state):
		return state.duplicate(true)
	var next: Dictionary = state.duplicate(true)
	var faces: Array[int] = _state_dice(state)
	var hand: Dictionary = evaluate(faces)
	var rank_name: String = str(hand.get("rank", RANK_NO_HAND))
	var bet: int = maxi(0, int(next.get("bet", next.get("stake", 0))))
	var payout_value: int = payout_for(bet, rank_name)
	next["rank"] = rank_name
	next["rank_name"] = rank_name
	next["multiplier"] = multiplier_for(rank_name)
	next["payout"] = payout_value
	next["profit"] = payout_value - bet
	next["active"] = false
	next["finished"] = true
	next["finalized"] = true
	next["phase"] = "result"
	next["result"] = rank_name
	next["last_action"] = "finalize"
	next["pending_rolls"] = []
	return next

static func finalise(state: Dictionary) -> Dictionary:
	return finalize(state)

static func finalize_hand(state: Dictionary) -> Dictionary:
	return finalize(state)

static func lock_hand(state: Dictionary) -> Dictionary:
	return finalize(state)

static func lock(state: Dictionary) -> Dictionary:
	return finalize(state)

static func settled_payout(state: Dictionary) -> int:
	return maxi(0, int(state.get("payout", 0)))

static func _state_is_playable(state: Dictionary) -> bool:
	return bool(state.get("active", false)) and not bool(state.get("finished", false))

static func _state_dice(state: Dictionary) -> Array[int]:
	var source: Variant = state.get("dice", state.get("values", []))
	return _faces_from_array(source as Array, false) if source is Array else []

static func _state_kept(state: Dictionary) -> Array[bool]:
	var source: Variant = state.get("kept", state.get("keep_mask", []))
	var result: Array[bool] = []
	if source is Array:
		for value: Variant in source as Array:
			result.append(bool(value))
	while result.size() < DIE_COUNT:
		result.append(false)
	if result.size() > DIE_COUNT:
		result.resize(DIE_COUNT)
	return result

static func _set_dice(state: Dictionary, faces: Array[int]) -> void:
	state["dice"] = faces.duplicate()
	state["values"] = faces.duplicate()

static func _set_kept(state: Dictionary, kept: Array[bool]) -> void:
	state["kept"] = kept.duplicate()
	state["keep_mask"] = kept.duplicate()

static func _faces_from_array(source: Array, require_five: bool = true) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in source:
		var face: int = int(value)
		if face < 1 or face > 6:
			return []
		result.append(face)
	if require_five and result.size() != DIE_COUNT:
		return []
	return result
