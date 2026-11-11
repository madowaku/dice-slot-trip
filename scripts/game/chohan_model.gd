extends RefCounted

## 丁半 (Cho-Han): two dice, even total = 丁, odd total = 半.
##
## Pure rules only. The screen owns presentation and CasinoBank owns chips;
## every roll goes through an injected RandomNumberGenerator so tests can pin
## the outcome with a seed.

const FACILITY_ID := "chohan"
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const CHOICE_CHO := "cho"
const CHOICE_HAN := "han"
## A correct call returns the wager doubled (stake + equal winnings).
const PAYOUT_MULTIPLIER := 2


static func make_rng(seed_value: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	return rng


static func roll_dice(rng: RandomNumberGenerator) -> Array[int]:
	var dice: Array[int] = [rng.randi_range(1, 6), rng.randi_range(1, 6)]
	return dice


static func is_valid_choice(choice: String) -> bool:
	return choice == CHOICE_CHO or choice == CHOICE_HAN


static func is_valid_bet(bet: int) -> bool:
	return bet in BET_AMOUNTS


static func is_valid_dice(dice: Variant) -> bool:
	if not dice is Array or (dice as Array).size() != 2:
		return false
	for value: Variant in dice as Array:
		if not (value is int or value is float) or int(value) < 1 or int(value) > 6:
			return false
	return true


static func total_of(dice: Array) -> int:
	return int(dice[0]) + int(dice[1])


static func parity_of(dice: Array) -> String:
	return CHOICE_CHO if total_of(dice) % 2 == 0 else CHOICE_HAN


static func win_payout(bet: int) -> int:
	return maxi(0, bet) * PAYOUT_MULTIPLIER


static func choice_name(choice: String) -> String:
	return "丁" if choice == CHOICE_CHO else "半"


static func choice_caption(choice: String) -> String:
	return "偶数" if choice == CHOICE_CHO else "奇数"


## Resolve one round. `payout` is the amount credited back to the bank
## (0 on a miss), so the caller can pass it straight to CasinoBank.settle_game.
static func resolve(choice: String, dice: Array, bet: int) -> Dictionary:
	if not is_valid_choice(choice) or not is_valid_dice(dice) or bet <= 0:
		return {"ok": false, "reason": "invalid_round"}
	var parity := parity_of(dice)
	var won := parity == choice
	return {
		"ok": true,
		"choice": choice,
		"dice": [int(dice[0]), int(dice[1])],
		"total": total_of(dice),
		"parity": parity,
		"won": won,
		"bet": bet,
		"payout": win_payout(bet) if won else 0,
	}
