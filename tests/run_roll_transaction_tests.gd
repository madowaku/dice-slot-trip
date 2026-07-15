extends SceneTree

const GameStateScript = preload("res://autoload/game_state.gd")
const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")

var failures := 0

func _init() -> void:
	var state: Node = GameStateScript.new()
	state.reset_run()
	state.current_tile_index = 89
	state.begin_roll_transaction([], 1, 89)
	var transaction_id := str(state.roll_transaction.transaction_id)
	_expect(str(state.roll_transaction.phase) == "PRE_ROLL" and transaction_id != "" and int(state.roll_transaction.start_tile_index) == 89 and state.roll_transaction.final_dice_values.is_empty(), "PRE_ROLL canonical reservation")
	state.mark_roll_started([4])
	_expect(str(state.roll_transaction.phase) == "ROLLING" and state.roll_transaction.final_dice_values.is_empty(), "ROLLING has no final result")
	_expect(not state.mark_roll_started([5]), "duplicate ROLLING transition rejected")
	state.commit_roll_result([4], 1, DiceLogicScript.evaluate_current([4], 1), 4, 3, 1, true)
	_expect(not state.commit_roll_result([6], 1, {}, 6, 5, 0, false), "duplicate result commit rejected")
	var snapshot: Dictionary = state.to_dictionary().duplicate(true)
	state.clear_roll_transaction()
	state.apply_dictionary(snapshot)
	_expect(str(state.roll_transaction.phase) == "RESULT_COMMITTED" and str(state.roll_transaction.roll_transaction_id) == transaction_id and state.roll_transaction.final_dice_values == [4] and int(state.roll_transaction.target_tile_index) == 3, "RESULT_COMMITTED save round trip")
	state.commit_roll_movement(3)
	_expect(str(state.roll_transaction.phase) == "MOVEMENT_COMMITTED" and bool(state.roll_transaction.movement_committed), "MOVEMENT_COMMITTED")
	_expect(not state.commit_roll_movement(9) and int(state.roll_transaction.target_tile_index) == 3, "duplicate movement commit rejected")
	_expect(state.commit_roll_landing_roles() and not state.commit_roll_landing_roles(), "landing role effects receive one durable receipt")
	_expect(state.commit_roll_landing_core(&"COIN", "coin +6") and not state.commit_roll_landing_core(&"COIN", "coin +6 again"), "landing core effect receives one durable receipt")
	var landing_snapshot: Dictionary = state.to_dictionary().duplicate(true)
	state.apply_dictionary(landing_snapshot)
	_expect(bool(state.roll_transaction.landing_roles_committed) and bool(state.roll_transaction.landing_core_committed) and str(state.roll_transaction.landing_tile_type) == "COIN", "landing receipts survive save round trip")
	_expect(state.mark_roll_encounter_handoff(true, 2), "event boss handoff substate reserved")
	_expect(state.mark_roll_encounter_open(true, 2), "boss modal consumption persisted")
	_expect(bool(state.roll_transaction.encounter_pair_bonus) and int(state.roll_transaction.encounter_double_bonus) == 2, "saved encounter bonuses survive production resume decision")
	_expect(state.commit_roll_encounter_interaction(true, "sleepy_sphinx"), "boss interaction committed once")
	var obtained: Dictionary = state.current_boss.duplicate(true)
	obtained["gauge"] = 100
	_expect(state.commit_roll_encounter_registration(obtained), "registration and next-individual boundary committed")
	var encounter_snapshot: Dictionary = state.to_dictionary().duplicate(true)
	state.apply_dictionary(encounter_snapshot)
	_expect(str(state.roll_transaction.encounter_phase) == "REGISTRATION_COMMITTED" and int(state.roll_transaction.encounter_obtained.gauge) == 100, "registration recovery payload survives save")
	_expect(state.complete_roll_encounter() and not state.complete_roll_encounter(), "encounter completion is one-way")
	state.commit_roll_space_effect()
	_expect(str(state.roll_transaction.phase) == "SPACE_EFFECT_COMMITTED" and bool(state.roll_transaction.space_effect_committed), "SPACE_EFFECT_COMMITTED")
	state.mark_roll_turn_resolved()
	_expect(str(state.roll_transaction.phase) == "TURN_RESOLVED", "TURN_RESOLVED")
	_expect(not state.commit_roll_space_effect() and not state.commit_roll_movement(3), "reverse roll transitions rejected")
	state.clear_roll_transaction()
	_expect(state.roll_transaction.is_empty(), "transaction clears")
	var rollback_matrix_ok := true
	for count: int in [1, 2, 3, 5]:
		state.current_dice_count = mini(count, 3)
		state.temporary_roll_dice_count = count if count == 5 else 0
		var expected_base_count: int = state.current_dice_count
		var expected_temporary_count: int = state.temporary_roll_dice_count
		state.begin_roll_transaction([], count, 17)
		state.mark_roll_started(Array(range(1, count + 1)))
		state.current_dice_count = 1
		state.temporary_roll_dice_count = 0
		var interrupted: Dictionary = state.to_dictionary().duplicate(true)
		state.clear_roll_transaction()
		state.apply_dictionary(interrupted)
		rollback_matrix_ok = rollback_matrix_ok and state.rollback_uncommitted_roll() and state.current_dice_count == expected_base_count and state.temporary_roll_dice_count == expected_temporary_count and state.roll_transaction.is_empty()
	_expect(rollback_matrix_ok, "1/2/3/5-dice PRE_ROLL and ROLLING restore consumption inputs")
	var legacy: Dictionary = state.to_dictionary().duplicate(true)
	legacy.erase("roll_transaction")
	state.apply_dictionary(legacy)
	_expect(state.roll_transaction.is_empty(), "legacy save defaults empty")
	state.free()
	print("ROLL_TRANSACTION_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
