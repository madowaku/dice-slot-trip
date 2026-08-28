extends RefCounted
class_name DiceRouletteModel

const BET_AMOUNTS := [10, 20, 50]
const MAX_MAIN_BETS := 3
const SLOT_COUNT := 24

const MAIN_AREAS := ["LOW", "HIGH", "ODD", "EVEN", "LUCKY_7", "JACKPOT"]
const SIDE_AREAS := ["RED_LEADS", "DRAW", "BLUE_LEADS"]

# Clockwise from the top of the wheel. Keeping 24 equally likely slots lets the
# presentation animate freely without letting physics alter game odds.
const SLOT_AREAS := [
	"JACKPOT",
	"HIGH", "HIGH", "HIGH", "HIGH", "HIGH",
	"EVEN", "EVEN", "EVEN", "EVEN", "EVEN",
	"LUCKY_7", "LUCKY_7", "LUCKY_7",
	"LOW", "LOW", "LOW", "LOW", "LOW",
	"ODD", "ODD", "ODD", "ODD", "ODD",
]

const MAIN_MULTIPLIERS := {
	"LOW": 1.40,
	"HIGH": 1.40,
	"ODD": 1.40,
	"EVEN": 1.40,
	"LUCKY_7": 2.35,
	"JACKPOT": 7.00,
}

const SIDE_MULTIPLIERS := {
	"RED_LEADS": 2.30,
	"BLUE_LEADS": 2.30,
	"DRAW": 5.70,
}

const FACE_BOOSTS := {
	1: 1.0,
	2: 1.0,
	3: 1.2,
	4: 1.5,
	5: 2.0,
	6: 3.0,
}

static func area_for_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= SLOT_AREAS.size():
		return ""
	return str(SLOT_AREAS[slot_index])

static func face_boost(face: int) -> float:
	return float(FACE_BOOSTS.get(face, 0.0))

static func is_valid_bet_amount(amount: int) -> bool:
	return amount in BET_AMOUNTS

static func roll_die(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"slot": rng.randi_range(0, SLOT_COUNT - 1),
		"face": rng.randi_range(1, 6),
	}

static func main_hit_payout(bet_area: String, amount: int, die_area: String, face: int) -> int:
	if bet_area != die_area or not MAIN_MULTIPLIERS.has(bet_area):
		return 0
	if amount <= 0 or face < 1 or face > 6:
		return 0
	return roundi(float(amount) * float(MAIN_MULTIPLIERS[bet_area]) * face_boost(face))

static func side_result(red_face: int, blue_face: int) -> String:
	if red_face > blue_face:
		return "RED_LEADS"
	if blue_face > red_face:
		return "BLUE_LEADS"
	return "DRAW"

static func side_payout(bet_area: String, amount: int, red_face: int, blue_face: int) -> int:
	if amount <= 0 or not SIDE_MULTIPLIERS.has(bet_area):
		return 0
	if bet_area != side_result(red_face, blue_face):
		return 0
	return roundi(float(amount) * float(SIDE_MULTIPLIERS[bet_area]))

static func total_bet(main_bets: Dictionary, side_bet: Dictionary = {}) -> int:
	var total := 0
	for area: Variant in main_bets.keys():
		total += maxi(0, int(main_bets.get(area, 0)))
	if not side_bet.is_empty():
		total += maxi(0, int(side_bet.get("amount", 0)))
	return total

static func resolve_round(red_slot: int, red_face: int, blue_slot: int, blue_face: int, main_bets: Dictionary, side_bet: Dictionary = {}) -> Dictionary:
	var red_area := area_for_slot(red_slot)
	var blue_area := area_for_slot(blue_slot)
	var main_details: Array[Dictionary] = []
	var main_return := 0

	for area_value: Variant in main_bets.keys():
		var area := str(area_value)
		var amount := maxi(0, int(main_bets.get(area, 0)))
		if amount <= 0 or not MAIN_MULTIPLIERS.has(area):
			continue
		var red_payout := main_hit_payout(area, amount, red_area, red_face)
		var blue_payout := main_hit_payout(area, amount, blue_area, blue_face)
		if red_payout > 0:
			main_details.append({"die": "RED", "area": area, "face": red_face, "payout": red_payout})
		if blue_payout > 0:
			main_details.append({"die": "BLUE", "area": area, "face": blue_face, "payout": blue_payout})
		main_return += red_payout + blue_payout

	var side_return := 0
	var side_area := ""
	var side_amount := 0
	if not side_bet.is_empty():
		side_area = str(side_bet.get("area", ""))
		side_amount = maxi(0, int(side_bet.get("amount", 0)))
		side_return = side_payout(side_area, side_amount, red_face, blue_face)

	var wager := total_bet(main_bets, side_bet)
	var total_return := main_return + side_return
	return {
		"red_slot": red_slot,
		"red_area": red_area,
		"red_face": red_face,
		"red_boost": face_boost(red_face),
		"blue_slot": blue_slot,
		"blue_area": blue_area,
		"blue_face": blue_face,
		"blue_boost": face_boost(blue_face),
		"side_result": side_result(red_face, blue_face),
		"main_details": main_details,
		"main_return": main_return,
		"side_area": side_area,
		"side_amount": side_amount,
		"side_return": side_return,
		"total_bet": wager,
		"total_return": total_return,
		"profit": total_return - wager,
		"double_jackpot": red_area == "JACKPOT" and blue_area == "JACKPOT",
		"double_jackpot_max": red_area == "JACKPOT" and blue_area == "JACKPOT" and red_face == 6 and blue_face == 6,
	}

static func expected_main_rtp(area: String, amount: int = 1000) -> float:
	if amount <= 0 or not MAIN_MULTIPLIERS.has(area):
		return 0.0
	var total_return := 0
	for slot: int in range(SLOT_COUNT):
		for face: int in range(1, 7):
			total_return += main_hit_payout(area, amount, area_for_slot(slot), face)
	# A single main wager gets two independent chances, one from each die.
	return (2.0 * float(total_return) / float(SLOT_COUNT * 6)) / float(amount)

static func expected_side_rtp(area: String, amount: int = 1000) -> float:
	if amount <= 0 or not SIDE_MULTIPLIERS.has(area):
		return 0.0
	var total_return := 0
	for red_face: int in range(1, 7):
		for blue_face: int in range(1, 7):
			total_return += side_payout(area, amount, red_face, blue_face)
	return (float(total_return) / 36.0) / float(amount)
