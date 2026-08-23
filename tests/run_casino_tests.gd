extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const OrientationScript = preload("res://scripts/game/dice_race_orientation.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")

var failures := 0
var assertions := 0

func _init() -> void:
	_test_orientation_contract()
	_test_chip_bank()
	_test_gimmicks()
	_test_goal_and_photo_finish()
	_test_bet_and_cashout()
	print("Casino tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _assign(target: String, value: int) -> Dictionary:
	var values := [1, 2, 3, 4, 5, 6]
	values.erase(value)
	var result := {target: value}
	for racer_id: String in RaceScript.RACERS:
		if racer_id == target:
			continue
		result[racer_id] = values.pop_front()
	return result

func _assign_two(a: String, a_value: int, b: String, b_value: int) -> Dictionary:
	var values := [1, 2, 3, 4, 5, 6]
	values.erase(a_value)
	values.erase(b_value)
	var result := {a: a_value, b: b_value}
	for racer_id: String in RaceScript.RACERS:
		if racer_id == a or racer_id == b:
			continue
		result[racer_id] = values.pop_front()
	return result

func _test_orientation_contract() -> void:
	var orientations: Array[Dictionary] = OrientationScript.all_orientations()
	_expect(orientations.size() == 24, "physical cube has exactly 24 orientations")
	var keys := {}
	for orientation: Dictionary in orientations:
		_expect(OrientationScript.is_valid_orientation(orientation), "every generated orientation is physically valid")
		keys[OrientationScript.orientation_key(orientation)] = true
	_expect(keys.size() == 24, "all 24 orientations are unique")
	var base: Dictionary = OrientationScript.values_for_racers(OrientationScript.base_orientation())
	_expect(int(base.fox) == 1 and int(base.rabbit) == 6, "fox and rabbit use opposite top/bottom faces")
	_expect(int(base.duck) == 2 and int(base.dinosaur) == 5, "duck and dinosaur use opposite front/back faces")
	_expect(int(base.camel) == 3 and int(base.robot) == 4, "camel and robot use opposite left/right faces")
	_expect(not base.has("crocodile"), "retired crocodile racer is not assigned a die face")

func _test_chip_bank() -> void:
	if FileAccess.file_exists(CasinoBankScript.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	_expect(CasinoBankScript.balance() == 0, "new Casino Bank starts at zero")
	var result: Dictionary = CasinoBankScript.stage_clear_conversion(24, true)
	_expect(int(result.converted_chip) == 12, "24 leftover trip coin converts to 12 chip")
	_expect(int(result.clear_bonus) == 5, "stage clear grants five chip bonus")
	_expect(CasinoBankScript.balance() == 17, "conversion plus clear bonus persists")
	_expect(CasinoBankScript.spend_chips(7), "chip can be spent when balance is sufficient")
	_expect(CasinoBankScript.balance() == 10, "chip spend is persisted")
	_expect(not CasinoBankScript.spend_chips(11), "chip cannot overspend")
	_expect(CasinoBankScript.own_card("dice_racer_duck", 5), "card can be exchanged for chip")
	var saved: Dictionary = CasinoBankScript.load_data()
	_expect(int(saved.chips) == 5 and "dice_racer_duck" in saved.owned_cards, "card ownership and remaining chip persist")
	_expect(not CasinoBankScript.own_card("dice_racer_duck", 0), "owned card cannot be bought twice")
	var legacy := CasinoBankScript.default_data()
	legacy["owned_cards"] = ["dice_racer_crocodile"]
	CasinoBankScript.save_data(legacy)
	var migrated := CasinoBankScript.load_data()
	_expect("dice_racer_rabbit" in migrated.owned_cards and "dice_racer_crocodile" not in migrated.owned_cards, "legacy crocodile prize ownership migrates to rabbit")
	CasinoBankScript.save_data(saved)
	var once: Dictionary = CasinoBankScript.stage_clear_conversion_once("test:lap:1", 24, true)
	_expect(int(once.gained_chip) == 17 and CasinoBankScript.balance() == 22, "one-shot clear conversion credits the first receipt")
	var replay: Dictionary = CasinoBankScript.stage_clear_conversion_once("test:lap:1", 24, true)
	_expect(bool(replay.already_converted) and int(replay.gained_chip) == 0 and CasinoBankScript.balance() == 22, "one-shot clear conversion rejects result-screen replay")
	var ledger: Dictionary = CasinoBankScript.load_data()
	_expect("test:lap:1" in ledger.conversion_keys, "conversion ledger persists with bank data")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))

func _test_gimmicks() -> void:
	var race: Dictionary = RaceScript.new_race()
	race.racers.fox.position = 4
	race = RaceScript.apply_roll(race, _assign("fox", 1))
	_expect(int(race.racers.fox.position) == 5 and bool(race.racers.fox.foxfire_pending), "foxfire arms on exact landing at 5")
	race = RaceScript.apply_roll(race, _assign("fox", 6))
	_expect(int(race.racers.fox.position) == 9 and not bool(race.racers.fox.foxfire_pending), "foxfire reduces next 6 to 4 then clears")

	race = RaceScript.new_race()
	race.racers.fox.position = 7
	race = RaceScript.apply_roll(race, _assign("fox", 3))
	_expect(int(race.racers.fox.position) == 13, "rapid current adds three after exact landing at 10")

	race = RaceScript.new_race()
	race.racers.fox.position = 14
	race = RaceScript.apply_roll(race, _assign("fox", 1))
	_expect(int(race.racers.fox.position) == 15 and bool(race.racers.fox.log_pending), "log arms on exact landing at 15")
	race = RaceScript.apply_roll(race, _assign("fox", 3))
	_expect(int(race.racers.fox.position) == 15 and not bool(race.racers.fox.log_pending), "log blocks 1 to 3 once then clears")

	race = RaceScript.new_race()
	race.racers.fox.position = 8
	race = RaceScript.apply_roll(race, _assign("fox", 4))
	_expect(int(race.racers.fox.position) == 12, "passing rapid-current space does not trigger it")

func _test_goal_and_photo_finish() -> void:
	var race: Dictionary = RaceScript.new_race()
	race.racers.fox.position = 22
	race.racers.duck.position = 21
	race = RaceScript.apply_roll(race, _assign_two("fox", 5, "duck", 3))
	_expect(bool(race.finished) and str(race.winner) == "fox", "greater goal overshoot wins when racers finish on same roll")

	race = RaceScript.new_race()
	race.racers.fox.position = 22
	race.racers.duck.position = 21
	race = RaceScript.apply_roll(race, _assign_two("fox", 2, "duck", 3))
	_expect(not bool(race.finished) and race.photo_finish_candidates.size() == 2, "equal final position opens photo finish")
	race = RaceScript.apply_roll(race, _assign_two("fox", 1, "duck", 6))
	_expect(bool(race.finished) and str(race.winner) == "duck", "photo finish uses the higher assigned face without moving racers")

func _test_bet_and_cashout() -> void:
	var race: Dictionary = RaceScript.new_race("duck", 20)
	race.racers.duck.position = 15
	race.racers.fox.position = 13
	_expect(RaceScript.rank_for_racer(race, "duck") == 1, "rank derives from race position")
	_expect(RaceScript.cashout_offer(race) == 36, "first-place 20 chip cashout is 36")
	race.racers.fox.position = 16
	_expect(RaceScript.cashout_offer(race) == 20, "second-place 20 chip cashout returns stake")
	race.cashout_offered = true
	race = RaceScript.take_cashout(race)
	_expect(bool(race.cashout_taken) and not bool(race.bet_active), "taking cashout closes the active bet")

	race = RaceScript.new_race("duck", 20)
	race.winner = "duck"
	race.finished = true
	_expect(RaceScript.winning_payout(race) == 80, "standard win pays bet times four including stake")
