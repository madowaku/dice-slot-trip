extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const OrientationScript = preload("res://scripts/game/dice_race_orientation.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const TowerScript = preload("res://scripts/game/dice_tower_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")

var failures := 0
var assertions := 0

func _init() -> void:
	_configure_test_save()
	_test_orientation_contract()
	_test_chip_bank()
	_test_dice_tower_rules()
	_test_gimmicks()
	_test_goal_and_photo_finish()
	_test_bet_and_cashout()
	_cleanup_test_save()
	print("Casino tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _configure_test_save() -> void:
	var path := "user://dice_slot_trip_casino_tests_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _cleanup_test_save() -> void:
	var path := CasinoBankScript.save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	CasinoBankScript.clear_test_save_path()

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
		var quaternion := OrientationScript.quaternion_for_orientation(orientation)
		_expect(is_equal_approx(Basis(quaternion).determinant(), 1.0), "every race die pose is a proper cube rotation")
		for direction: String in OrientationScript.DIRECTIONS:
			var value := int(orientation[direction])
			var rendered_direction: Vector3 = quaternion * DicePresentationScript.race_face_normal(value)
			_expect(rendered_direction.is_equal_approx(OrientationScript.DIRECTION_VECTORS[direction]), "3D face %d renders at %s" % [value, direction])
	_expect(keys.size() == 24, "all 24 orientations are unique")
	var base: Dictionary = OrientationScript.values_for_racers(OrientationScript.base_orientation())
	_expect(int(base.fox) == 1 and int(base.rabbit) == 6, "fox and rabbit use opposite top/bottom faces")
	_expect(int(base.duck) == 2 and int(base.dinosaur) == 5, "duck and dinosaur use opposite front/back faces")
	_expect(int(base.camel) == 3 and int(base.robot) == 4, "camel and robot use opposite left/right faces")
	_expect(not base.has("crocodile"), "retired crocodile racer is not assigned a die face")

func _test_chip_bank() -> void:
	var path := CasinoBankScript.save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
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

func _test_dice_tower_rules() -> void:
	var expected_payouts := [23, 26, 31, 36, 42, 48, 56, 65, 76, 88]
	for floor_number: int in range(1, 11):
		_expect(TowerScript.payout_for_floor(20, floor_number) == int(expected_payouts[floor_number - 1]), "bet 20 pays the authored DICE TOWER table at floor %d" % floor_number)

	var climb: Dictionary = TowerScript.new_game(20)
	climb = TowerScript.apply_roll(climb, 4)
	_expect(int(climb.floor) == 1 and int(climb.last_roll) == 4 and str(climb.last_kind) == "climb", "2 through 5 climbs exactly one floor")
	climb = TowerScript.apply_roll(climb, 6)
	_expect(int(climb.floor) == 3 and str(climb.last_kind) == "leap", "six performs a golden two-floor leap")
	climb = TowerScript.apply_roll(climb, 3)
	_expect(int(climb.floor) == 4 and int(climb.roll_count) == 3, "ordinary rolls accumulate floor and roll count")
	var cashed: Dictionary = TowerScript.take_cashout(climb)
	_expect(bool(cashed.finished) and bool(cashed.cashed_out) and not bool(cashed.active) and int(cashed.payout) == 36, "floor four CASH OUT returns the authored 36 chip payout")
	_expect(TowerScript.apply_roll(cashed, 5) == cashed, "a finished tower rejects further rolls")

	var bust: Dictionary = TowerScript.new_game(50)
	bust = TowerScript.apply_roll(bust, 6)
	bust = TowerScript.apply_roll(bust, 1)
	_expect(bool(bust.finished) and bool(bust.busted) and int(bust.floor) == 0 and int(bust.payout) == 0, "one is an immediate total BUST")

	var complete_from_nine: Dictionary = TowerScript.new_game(20)
	complete_from_nine.floor = 9
	complete_from_nine = TowerScript.apply_roll(complete_from_nine, 6)
	_expect(bool(complete_from_nine.completed) and int(complete_from_nine.floor) == 10 and int(complete_from_nine.payout) == 88, "golden leap from nine completes and auto-cashes at ten")
	var complete_from_eight: Dictionary = TowerScript.new_game(10)
	complete_from_eight.floor = 8
	complete_from_eight = TowerScript.apply_roll(complete_from_eight, 6)
	_expect(bool(complete_from_eight.completed) and int(complete_from_eight.payout) == 44, "climbing onto ten also completes the tower")

	var zero_floor: Dictionary = TowerScript.new_game(20)
	_expect(TowerScript.take_cashout(zero_floor) == zero_floor, "the player cannot cash out before leaving START")
	_expect(not bool(TowerScript.apply_roll(zero_floor, 9).get("finished", true)), "invalid out-of-range values are ignored")

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
	race.racers.duck.position = RaceScript.GOAL
	_expect(RaceScript.winning_payout(race) == 36, "first place returns the Phase A x1.8 rank payout")
	_expect(RaceScript.final_multiplier_for_rank(2) == 1.0 and RaceScript.final_multiplier_for_rank(6) == 0.3, "final rank payouts preserve a break-even second and partial lower-rank returns")
	race.winner = "fox"
	race.racers.fox.position = RaceScript.GOAL + 1
	race.racers.duck.position = RaceScript.GOAL - 1
	_expect(RaceScript.final_rank_for_racer(race, "duck") == 2 and RaceScript.final_payout(race) == 20, "second place returns the stake without a win")
