extends SceneTree

const ControllerScript = preload("res://boss/kyoto/fox_fire_six_routes/fox_fire_six_routes_controller.gd")
const DifficultyTableScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_difficulty_table.gd")
const DifficultyConfigScript = preload("res://boss/kyoto/fox_fire_six_routes/data/fox_fire_difficulty_config.gd")
const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")

var failures: int = 0


func _init() -> void:
	_test_move_01_exact_three_step_path()
	_test_move_01_four_step_path_counts_each_cell()
	_test_move_02_incomplete_path_cannot_confirm()
	_test_move_03_revisit_and_immediate_backtrack()
	_test_move_04_white_fire_blocks_entry()
	_test_move_05_prior_turn_reuse_is_legal()
	_test_move_06_exact_four_stop_seals()
	_test_move_07_torii_pass_through_does_not_seal()
	_test_move_08_visited_torii_does_not_reseal()
	_test_miss_resolution_reaches_fox_action()
	_test_seal_01_third_seal_wins_before_fox()
	_test_fox_01_preview_matches_placement_and_cadence()
	_test_fox_02_placed_fire_blocks_later_path()
	_test_fox_03_total_blockade_defeats()
	_test_slot_01_02_shared_roll_set_roles()
	_test_rng_01_seed_reproducibility()
	_test_snapshot_restore_and_blessing_hooks()
	_test_slice_4_to_7_features()
	print("FOX_FIRE_SIX_ROUTES_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_move_01_exact_three_step_path() -> void:
	var battle := _new_battle()
	var start: Vector2i = battle.state.cat_position
	_expect(bool(battle.set_move_steps_for_test(3).get("ok", false)), "MOVE-01 accepts a final move value of three")
	_expect(_trace(battle, [Vector2i(2, 4), Vector2i(1, 4), Vector2i(1, 3)]), "MOVE-01 accepts a legal orthogonal three-cell route")
	_expect(battle.state.cat_position == start and battle.can_confirm_path(), "MOVE-01 keeps the cat still until the full path is confirmed")
	_expect(bool(battle.confirm_path().get("ok", false)) and battle.state.cat_position == Vector2i(1, 3), "MOVE-01 moves the cat only on confirmation")
	_expect(battle.state.active_edges.size() == 3, "MOVE-01 records each traversed segment as one normalized edge")
	battle.free()


func _test_move_01_four_step_path_counts_each_cell() -> void:
	var battle := _new_battle()
	var route: Array[Vector2i] = [Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 4)]
	_expect(bool(battle.set_move_steps_for_test(4).get("ok", false)), "MOVE-01 accepts a four-cell roll")
	_expect(_trace(battle, route), "MOVE-01 traces four adjacent cells without skipping")
	_expect(battle.state.current_input_path.size() == 5 and battle.state.remaining_steps() == 0, "MOVE-01 treats出目4 as exactly four movement cells")
	_expect(battle.can_confirm_path(), "MOVE-01 enables confirmation only after all four cells")
	battle.free()


func _test_move_02_incomplete_path_cannot_confirm() -> void:
	var battle := _new_battle()
	var start: Vector2i = battle.state.cat_position
	battle.set_move_steps_for_test(3)
	_trace(battle, [Vector2i(2, 4), Vector2i(1, 4)])
	var confirmation: Dictionary = battle.confirm_path()
	_expect(not battle.can_confirm_path() and not bool(confirmation.get("ok", true)), "MOVE-02 rejects confirmation with only two of three steps")
	_expect(battle.state.cat_position == start and battle.state.phase == ControllerScript.BattlePhase.PATH_INPUT, "MOVE-02 leaves cat and input phase unchanged after rejection")
	battle.free()


func _test_move_03_revisit_and_immediate_backtrack() -> void:
	var battle := _new_battle()
	battle.set_move_steps_for_test(4)
	_trace(battle, [Vector2i(2, 4), Vector2i(1, 4), Vector2i(1, 5)])
	var revisit: Dictionary = battle.press_cell(Vector2i(2, 5))
	_expect(not bool(revisit.get("ok", true)) and str(revisit.get("error", "")) == "SAME_TURN_REVISIT", "MOVE-03 rejects a non-backtrack same-turn revisit")
	var undo: Dictionary = battle.press_cell(Vector2i(1, 4))
	_expect(bool(undo.get("ok", false)) and str(undo.get("status", "")) == "UNDO", "MOVE-03 treats tapping the immediately previous cell as undo")
	_expect(battle.state.current_input_path == [Vector2i(2, 5), Vector2i(2, 4), Vector2i(1, 4)], "MOVE-03 undo removes only the latest provisional step")
	battle.free()


func _test_move_04_white_fire_blocks_entry() -> void:
	var battle := _new_battle()
	var saved: Dictionary = battle.snapshot()
	saved["white_fire_cells"] = [Vector2i(1, 5)]
	_expect(battle.restore_snapshot(saved), "MOVE-04 white-fire setup restores")
	battle.set_move_steps_for_test(1)
	var blocked: Dictionary = battle.press_cell(Vector2i(1, 5))
	_expect(not bool(blocked.get("ok", true)) and str(blocked.get("error", "")) == "WHITE_FIRE_BLOCKED", "MOVE-04 forbids entry into a white-fire cell")
	_expect(not battle.legal_next_cells().has(Vector2i(1, 5)), "MOVE-04 omits white fire from legal next cells")
	battle.free()


func _test_move_05_prior_turn_reuse_is_legal() -> void:
	var battle := _new_battle()
	_expect(_play_turn(battle, 2, [Vector2i(1, 5), Vector2i(1, 4)]), "MOVE-05 first turn commits its route")
	battle.set_move_steps_for_test(2)
	_expect(_trace(battle, [Vector2i(1, 5), Vector2i(2, 5)]), "MOVE-05 accepts cells traversed on an earlier turn")
	_expect(bool(battle.confirm_path().get("ok", false)) and battle.state.cat_position == ControllerScript.TORII_POSITIONS[ControllerScript.TORII_A], "MOVE-05 confirms a prior-turn reused route")
	_expect(battle.state.active_edges.size() == 2, "MOVE-05 normalizes reused undirected edges without duplicates")
	battle.free()


func _test_move_06_exact_four_stop_seals() -> void:
	var battle := _new_battle()
	_expect(_play_turn(battle, 1, [Vector2i(3, 5)]), "MOVE-06 setup turn moves one cell from torii A")
	battle.set_move_steps_for_test(4)
	_trace(battle, [Vector2i(4, 5), Vector2i(5, 5), Vector2i(5, 4), Vector2i(5, 3)])
	battle.confirm_path()
	var resolution: Dictionary = battle.finish_cat_movement()
	_expect(bool(resolution.get("seal_completed", false)) and battle.state.seal_count == 1, "MOVE-06 seals on an exact four-step torii stop")
	_expect(battle.state.current_torii_id == ControllerScript.TORII_D and battle.state.active_edges.is_empty(), "MOVE-06 advances the current torii and clears active fire")
	_expect(battle.state.sealed_edges.size() == 5, "MOVE-06 converts the connected multi-turn route to sealed edges")
	battle.free()


func _test_move_07_torii_pass_through_does_not_seal() -> void:
	var battle := _new_battle()
	battle.set_move_steps_for_test(6)
	_trace(battle, [
		Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5),
		Vector2i(5, 4), Vector2i(5, 3), Vector2i(4, 3),
	])
	battle.confirm_path()
	battle.finish_cat_movement()
	_expect(battle.state.seal_count == 0 and not battle.state.has_visited_torii(ControllerScript.TORII_D), "MOVE-07 does not seal a torii passed before the final step")
	_expect(battle.state.active_edges.size() == 6, "MOVE-07 keeps pass-through trail edges active")
	battle.free()


func _test_move_08_visited_torii_does_not_reseal() -> void:
	var battle := _new_battle()
	_expect(_play_turn(battle, 1, [Vector2i(1, 5)]), "MOVE-08 setup leaves the current torii")
	battle.set_move_steps_for_test(1)
	_trace(battle, [Vector2i(2, 5)])
	battle.confirm_path()
	battle.finish_cat_movement()
	_expect(battle.state.cat_position == ControllerScript.TORII_POSITIONS[ControllerScript.TORII_A] and battle.state.seal_count == 0, "MOVE-08 stopping on an already visited torii creates no new seal")
	battle.free()


func _test_miss_resolution_reaches_fox_action() -> void:
	var battle := _new_battle()
	var saved: Dictionary = battle.snapshot()
	saved["cat_position"] = Vector2i(3, 3)
	saved["white_fire_cells"] = [Vector2i(3, 2), Vector2i(4, 3), Vector2i(3, 4), Vector2i(2, 3)]
	_expect(battle.restore_snapshot(saved), "MISS blockade setup restores")
	var move: Dictionary = battle.set_move_steps_for_test(1)
	_expect(str(move.get("status", "")) == "NO_ROUTE" and battle.can_resolve_miss(), "MISS is exposed only when exact-N DFS finds no route")
	_expect(bool(battle.resolve_miss().get("ok", false)) and battle.state.phase == ControllerScript.BattlePhase.FOX_ACTION, "MISS leaves the cat still and proceeds to fox action")
	battle.free()


func _test_seal_01_third_seal_wins_before_fox() -> void:
	var battle := _new_battle(5, 20260813)
	var destinations: Array[Vector2i] = [
		ControllerScript.TORII_POSITIONS[ControllerScript.TORII_D],
		ControllerScript.TORII_POSITIONS[ControllerScript.TORII_B],
		ControllerScript.TORII_POSITIONS[ControllerScript.TORII_C],
	]
	var steps: Array[int] = [5, 5, 4]
	for index: int in range(destinations.size()):
		var route := _find_exact_path(battle, destinations[index], steps[index])
		_expect(route.size() == steps[index], "SEAL-01 route %d exists despite prior fox fire" % (index + 1))
		battle.set_move_steps_for_test(steps[index])
		_trace(battle, route)
		battle.confirm_path()
		var fox_actions_before: int = battle.fox_actions_resolved()
		battle.finish_cat_movement()
		if index < 2:
			_expect(battle.state.seal_count == index + 1 and battle.state.phase == ControllerScript.BattlePhase.FOX_ACTION, "SEAL-01 seal %d proceeds to the scheduled fox phase" % (index + 1))
			battle.resolve_fox_action()
			battle.finish_turn()
		else:
			_expect(battle.state.seal_count == 3 and battle.state.phase == ControllerScript.BattlePhase.VICTORY, "SEAL-01 third completed seal enters VICTORY immediately")
			_expect(battle.fox_actions_resolved() == fox_actions_before, "SEAL-01 third seal executes no fox action")
			_expect(bool(battle.result().get("victory", false)) and int(battle.result().get("turns_used", 0)) == 3, "SEAL-01 returns a three-turn victory result")
	battle.free()


func _test_fox_01_preview_matches_placement_and_cadence() -> void:
	var table = DifficultyTableScript.create_default()
	var lv1 := table.config_for_lap(1)
	_expect(lv1.level == 1 and lv1.attack_interval == 2 and lv1.initial_white_fire_count == 1 and is_equal_approx(lv1.smart_target_rate, 0.30), "FOX-01 LAP 1 is an easy live battle with one initial fire and 30% smart targeting")
	_expect(table.config_for_lap(2).level == 2 and table.config_for_lap(4).attack_interval == 2, "FOX-01 LAP 2-4 maps to Lv2 every two turns")
	_expect(table.config_for_lap(5).level == 3 and table.config_for_lap(8).first_attack_turn == 3, "FOX-01 LAP 5-8 starts its every-turn pressure on TURN 3")
	_expect(is_equal_approx(table.config_for_lap(4).smart_target_rate, 0.36) and table.config_for_lap(25).level == 8 and is_equal_approx(table.config_for_lap(25).smart_target_rate, 0.78), "FOX-01 fox intent sharpens by two percent per LAP without changing rules")
	var battle := _new_battle(1, 719)
	var preview: Array[Vector2i] = battle.state.fox_preview_cells.duplicate()
	var committed := battle.state.fox_committed_cell
	_expect(battle.state.white_fire_cells.size() == 1 and preview.size() == 1 and battle.state.fox_preview_due_turn == 2, "FOX-01 Lv1 opens with one blocker and a TURN 2 preview before rolling")
	_expect(committed in preview, "FOX-01 commits the future placement when the preview appears")
	var next_cell := _first_adjacent_not_in(battle.state.cat_position, preview, battle)
	_expect(_play_turn(battle, 1, [next_cell]), "FOX-01 TURN 1 gives the player time to read the preview")
	_expect(battle.state.turn_number == 2 and battle.state.fox_preview_cells == preview and not battle.state.white_fire_cells.has(committed), "FOX-01 TURN 1 preserves the locked preview without placing it early")
	var turn_two_cell := _first_adjacent_not_in(battle.state.cat_position, preview, battle)
	battle.set_move_steps_for_test(1)
	_trace(battle, [turn_two_cell])
	battle.confirm_path()
	battle.finish_cat_movement()
	var action: Dictionary = battle.resolve_fox_action()
	_expect(action.get("selected_cells", []) == [committed] and action.get("placed_cells", []) == [committed], "FOX-01 TURN 2 places exactly the cell committed before rolling")
	_expect(battle.state.white_fire_cells.has(committed), "FOX-01 records the previewed cell as white fire")
	var level_three := _new_battle(5, 719)
	_expect(level_three.state.fox_preview_cells.is_empty(), "FOX-01 Lv3 does not attack or preview too early on TURN 1")
	_expect(_play_turn(level_three, 1, [_first_adjacent_not_in(level_three.state.cat_position, [], level_three)]), "FOX-01 advances Lv3 to its warning turn")
	_expect(level_three.state.turn_number == 2 and level_three.state.fox_preview_due_turn == 3 and level_three.state.fox_preview_cells.size() == 1, "FOX-01 Lv3 warns on TURN 2 before its first TURN 3 action")
	battle.free()
	level_three.free()


func _test_fox_02_placed_fire_blocks_later_path() -> void:
	var battle := _new_battle(13, 1337)
	var preview: Vector2i = battle.state.fox_preview_cells[0]
	battle.set_move_steps_for_test(1)
	_trace(battle, [_first_adjacent_not_in(battle.state.cat_position, [preview], battle)])
	battle.confirm_path()
	battle.finish_cat_movement()
	battle.resolve_fox_action()
	var neighbor := _first_open_neighbor(preview, battle)
	var saved: Dictionary = battle.snapshot()
	saved["phase"] = ControllerScript.BattlePhase.ROLL_SLOT
	saved["cat_position"] = neighbor
	saved["move_steps"] = 0
	saved["current_input_path"] = []
	saved["reachable_endpoints"] = []
	saved["fox_preview_cells"] = []
	saved["fox_preview_due_turn"] = 0
	saved["fox_committed_cell"] = Vector2i(-1, -1)
	_expect(battle.restore_snapshot(saved), "FOX-02 adjacent path setup restores after placement")
	battle.set_move_steps_for_test(1)
	var blocked: Dictionary = battle.press_cell(preview)
	_expect(not bool(blocked.get("ok", true)) and str(blocked.get("error", "")) == "WHITE_FIRE_BLOCKED", "FOX-02 placed fox fire blocks the cat on a later turn")
	battle.free()


func _test_fox_03_total_blockade_defeats() -> void:
	var battle := _new_battle(5, 55)
	var saved: Dictionary = battle.snapshot()
	saved["phase"] = ControllerScript.BattlePhase.FOX_ACTION
	saved["cat_position"] = Vector2i(3, 3)
	saved["white_fire_cells"] = [Vector2i(3, 2), Vector2i(4, 3), Vector2i(3, 4)]
	saved["fox_preview_cells"] = [Vector2i(2, 3)]
	saved["fox_preview_due_turn"] = int(saved.get("turn_number", 1))
	saved["fox_committed_cell"] = Vector2i(2, 3)
	saved["move_steps"] = 0
	saved["current_input_path"] = []
	saved["reachable_endpoints"] = []
	_expect(battle.restore_snapshot(saved), "FOX-03 near-blockade setup restores")
	var action: Dictionary = battle.resolve_fox_action()
	_expect(action.get("placed_cells", []) == [Vector2i(2, 3)], "FOX-03 places the final previewed blocker")
	_expect(battle.state.phase == ControllerScript.BattlePhase.DEFEAT, "FOX-03 enters DEFEAT when every unvisited torii is unreachable")
	_expect(str(battle.result().get("defeat_reason", "")) == "ALL_UNVISITED_TORII_UNREACHABLE", "FOX-03 reports the blockade defeat reason without a turn limit")
	battle.free()


func _test_slot_01_02_shared_roll_set_roles() -> void:
	var battle := _new_battle()
	var shared_pair: RefCounted = V06RollSetScript.new()
	shared_pair.restore_faces([2, 2, 5])
	var shared_triple: RefCounted = V06RollSetScript.new()
	shared_triple.restore_faces([4, 4, 4])
	_expect(battle.evaluate_slot_faces([2, 2, 5]) == shared_pair.evaluate_role() and battle.evaluate_slot_faces([2, 2, 5]) == V06RollSetScript.ROLE_PAIR, "SLOT-01 PAIR behavior comes from the shared V06 roll set")
	_expect(battle.evaluate_slot_faces([4, 4, 4]) == shared_triple.evaluate_role() and battle.evaluate_slot_faces([4, 4, 4]) == V06RollSetScript.ROLE_TRIPLE, "SLOT-01 TRIPLE behavior comes from the shared V06 roll set")
	_expect(battle.uses_shared_roll_set() and ControllerScript.ROLL_SET_SCRIPT_PATH == "res://scripts/game/v06_roll_set.gd", "SLOT-02 boss controller owns no separate role model")
	for face: int in [4, 4, 4]:
		var event: Dictionary = battle.set_move_steps_for_test(face)
		if face == 4 and battle.last_completed_slot_faces().is_empty():
			var saved: Dictionary = battle.snapshot()
			saved["phase"] = ControllerScript.BattlePhase.ROLL_SLOT
			saved["move_steps"] = 0
			saved["current_input_path"] = []
			saved["reachable_endpoints"] = []
			battle.restore_snapshot(saved)
		else:
			var _unused: Dictionary = event
	_expect(battle.last_slot_role() == V06RollSetScript.ROLE_TRIPLE and battle.last_completed_slot_faces() == [4, 4, 4], "SLOT-01 controller exposes the shared role after the third committed face")
	battle.free()


func _test_rng_01_seed_reproducibility() -> void:
	var first := _new_battle(5, 8675309)
	var second := _new_battle(5, 8675309)
	var first_preview: Array[Vector2i] = first.state.fox_preview_cells.duplicate()
	var second_preview: Array[Vector2i] = second.state.fox_preview_cells.duplicate()
	var first_roll: Dictionary = first.roll_move()
	var second_roll: Dictionary = second.roll_move()
	_expect(first_preview == second_preview, "RNG-01 equal seeds reproduce the fox preview candidate")
	_expect(int(first_roll.get("face", 0)) == int(second_roll.get("face", -1)), "RNG-01 equal seeds reproduce the controller-owned battle roll")
	var restored := ControllerScript.new()
	_expect(restored.restore_snapshot(first.snapshot()), "RNG-01 snapshot restores RNG state")
	_expect(restored.snapshot().get("rng_state") == first.snapshot().get("rng_state"), "RNG-01 restored RNG checkpoint is exact")
	first.free()
	second.free()
	restored.free()


func _test_snapshot_restore_and_blessing_hooks() -> void:
	var goshuin := {"fushimi": true, "yasaka": true, "kiyomizu": true, "tenryuji": true}
	var battle := ControllerScript.new()
	_expect(battle.configure(5, goshuin, 909), "snapshot blessing battle configures")
	_expect(battle.state.fushimi_start_choice_available and battle.choose_start_torii(ControllerScript.TORII_C), "Fushimi exposes and applies a pre-battle start choice")
	battle.start_battle()
	_expect(battle.state.fox_preview_cells.is_empty() and not battle.state.yasaka_delay_available, "Yasaka delays the first scheduled fox action")
	_expect(battle.state.kiyomizu_available and battle.use_kiyomizu_reroll(), "Kiyomizu exposes and consumes its one-battle reroll hook")
	battle.set_move_steps_for_test(3)
	_expect(bool(battle.apply_tenryuji_shift(1).get("ok", false)) and battle.state.move_steps == 4, "Tenryuji shifts the final move by plus one within 1-6")
	battle.press_cell(Vector2i(0, 0)) # Invalid input must not corrupt the checkpoint.
	var saved: Dictionary = battle.snapshot()
	var restored := ControllerScript.new()
	_expect(restored.restore_snapshot(saved), "battle snapshot restores a PATH_INPUT checkpoint")
	_expect(restored.snapshot() == saved and restored.state.mangan_available, "snapshot preserves board, role, RNG, and Mangan availability")
	_expect(restored.arm_mangan(), "Mangan can be armed before the next fox action")
	battle.free()
	restored.free()

	var reroll := ControllerScript.new()
	_expect(reroll.configure(5, {"kiyomizu": true}, 910), "Kiyomizu partial-roll battle configures")
	reroll.start_battle()
	reroll.roll_move()
	_expect(reroll.slot_faces().size() == 1 and reroll.use_kiyomizu_reroll() and reroll.slot_faces().is_empty(), "Kiyomizu clears an in-progress 3ROLL SLOT")
	reroll.free()


func _test_slice_4_to_7_features() -> void:
	var table := DifficultyTableScript.create_default()
	var lv4 := table.config_for_lap(9)
	var lv5 := table.config_for_lap(13)
	var lv6 := table.config_for_lap(17)
	var lv7 := table.config_for_lap(21)
	var lv8 := table.config_for_lap(25)
	_expect(lv4.level == 4 and lv4.smart_targeting and lv4.attack_interval == 1, "SLICE-05 Lv4 enables smart targeting on every turn")
	_expect(lv5.level == 5 and lv5.smart_targeting and lv5.enable_line_cut and lv5.maximum_line_cuts == 1, "SLICE-07 Lv5 enables one previewed line cut")
	_expect(lv6.level == 6 and lv6.candidate_count == 2 and not lv6.enable_special_tiles and lv6.maximum_line_cuts == 1, "SLICE-07 Lv6 previews two candidates without adding special tiles yet")
	_expect(lv7.level == 7 and lv7.special_tile_count == 1 and lv7.maximum_line_cuts == 2, "SLICE-07 Lv7 adds Sakura and a second line cut")
	_expect(lv8.level == 8 and lv8.special_tile_count == 2, "SLICE-07 Lv8 enables both special tiles")

	var smart := _new_battle_with_config(lv4, 4321)
	var smart_preview: Array[Vector2i] = smart.state.fox_preview_cells.duplicate()
	_expect(smart_preview.size() == 1, "SLICE-05 Lv4 locks one scored candidate before player input")
	smart.set_move_steps_for_test(1)
	_expect(smart.state.fox_preview_cells == smart_preview, "SLICE-05 Lv4 preview remains locked during the player turn")
	smart.free()

	var line_cut := _new_battle_with_config(lv5, 7654)
	var line_saved: Dictionary = line_cut.snapshot()
	line_saved["phase"] = ControllerScript.BattlePhase.TURN_END
	line_saved["turn_number"] = 1
	line_saved["move_steps"] = 0
	line_saved["current_input_path"] = []
	line_saved["reachable_endpoints"] = []
	line_saved["fox_preview_cells"] = []
	line_saved["fox_preview_due_turn"] = 0
	line_saved["fox_committed_cell"] = Vector2i(-1, -1)
	line_saved["fox_preview_line_cut_edge"] = ""
	line_saved["line_cut_preview_due_turn"] = 0
	line_saved["active_edges"] = [{"a": Vector2i(3, 5), "b": Vector2i(3, 4)}]
	_expect(line_cut.restore_snapshot(line_saved), "SLICE-07 line-cut setup restores with an eligible active edge")
	line_cut.finish_turn()
	var preview_edge := line_cut.state.fox_preview_line_cut_edge
	_expect(not preview_edge.is_empty() and line_cut.state.line_cut_preview_due_turn == 3 and line_cut.line_cut_candidate_edges().has(preview_edge), "SLICE-07 previews the TURN 3 line cut one turn early")
	var line_action_saved: Dictionary = line_cut.snapshot()
	line_action_saved["phase"] = ControllerScript.BattlePhase.FOX_ACTION
	line_action_saved["turn_number"] = 3
	_expect(line_cut.restore_snapshot(line_action_saved), "SLICE-07 line-cut action checkpoint restores")
	var line_action: Dictionary = line_cut.resolve_fox_action()
	_expect(str(line_action.get("line_cut_edge", "")) == preview_edge and not line_cut.state.active_edges.has(preview_edge), "SLICE-07 erases the previewed edge without creating white fire")
	line_cut.free()

	var two_choice := _new_battle_with_config(lv6, 2468)
	var two_preview: Array[Vector2i] = two_choice.state.fox_preview_cells.duplicate()
	var committed_before_roll: Vector2i = two_choice.state.fox_committed_cell
	_expect(two_preview.size() == 2 and two_preview[0] != two_preview[1] and committed_before_roll in two_preview, "SLICE-07 Lv6 exposes two candidates and secretly commits one before rolling")
	two_choice.set_move_steps_for_test(1)
	_expect(two_choice.state.fox_preview_cells == two_preview and two_choice.state.fox_committed_cell == committed_before_roll, "SLICE-07 A/B outcome cannot change after seeing the die")
	var two_saved: Dictionary = two_choice.snapshot()
	two_saved["phase"] = ControllerScript.BattlePhase.FOX_ACTION
	_expect(two_choice.restore_snapshot(two_saved), "SLICE-07 two-choice action checkpoint restores")
	var two_action: Dictionary = two_choice.resolve_fox_action()
	_expect(two_action.get("selected_cells", []) == [committed_before_roll] and two_action.get("placed_cells", []) == [committed_before_roll], "SLICE-07 action resolves the precommitted candidate without a post-move counterpick")
	two_choice.free()

	var special_config := DifficultyConfigScript.new(6, 0, 1, 0)
	special_config.enable_special_tiles = true
	var sakura := _new_battle_with_config(special_config, 111)
	var sakura_saved: Dictionary = sakura.snapshot()
	sakura_saved["phase"] = ControllerScript.BattlePhase.CAT_MOVING
	sakura_saved["cat_position"] = Vector2i(2, 2)
	sakura_saved["white_fire_cells"] = [Vector2i(1, 2)]
	sakura_saved["fox_preview_cells"] = []
	sakura_saved["fox_preview_line_cut_edge"] = ""
	_expect(sakura.restore_snapshot(sakura_saved), "SLICE-06 Sakura setup restores")
	var special_event: Dictionary = sakura.finish_cat_movement()
	_expect(str(special_event.get("status", "")) == "SPECIAL_RESOLVE" and sakura.special_options() == [Vector2i(1, 2)], "SLICE-06 Sakura requests one white-fire purification target")
	_expect(bool(sakura.purify_white_fire(Vector2i(1, 2)).get("ok", false)) and not sakura.state.white_fire_cells.has(Vector2i(1, 2)), "SLICE-06 Sakura removes the selected white fire")
	sakura.free()

	var bamboo := _new_battle_with_config(special_config, 222)
	bamboo.set_move_steps_for_test(2)
	_expect(bool(bamboo.press_cell(Vector2i(2, 4)).get("ok", false)), "SLICE-06 Bamboo accepts entry")
	var wrong_exit: Dictionary = bamboo.press_cell(Vector2i(1, 4))
	_expect(not bool(wrong_exit.get("ok", true)) and str(wrong_exit.get("error", "")) == "BAMBOO_DIRECTION_REQUIRED", "SLICE-06 Bamboo rejects a turn on exit")
	_expect(bool(bamboo.press_cell(Vector2i(2, 3)).get("ok", false)), "SLICE-06 Bamboo accepts straight exit")
	var bamboo_saved: Dictionary = bamboo.snapshot()
	bamboo_saved["phase"] = ControllerScript.BattlePhase.PATH_INPUT
	bamboo_saved["cat_position"] = Vector2i(2, 4)
	bamboo_saved["move_steps"] = 1
	bamboo_saved["current_input_path"] = [Vector2i(2, 4)]
	bamboo_saved["reachable_endpoints"] = [Vector2i(2, 3), Vector2i(2, 5), Vector2i(1, 4), Vector2i(3, 4)]
	bamboo_saved["forced_exit_direction"] = Vector2i(0, -1)
	_expect(bamboo.restore_snapshot(bamboo_saved), "SLICE-06 Bamboo forced-exit checkpoint restores")
	_expect(str(bamboo.press_cell(Vector2i(2, 3)).get("status", "")) == "PATH_STEP_ADDED", "SLICE-06 Bamboo keeps direction across turns when stopped on the tile")
	bamboo.free()

	var block_config := DifficultyConfigScript.new(6, 0, 1, 0)
	block_config.enable_block_seal_bonus = true
	block_config.attack_interval = 1
	block_config.first_attack_turn = 1
	var block := _new_battle_with_config(block_config, 333)
	var block_saved: Dictionary = block.snapshot()
	block_saved["phase"] = ControllerScript.BattlePhase.CAT_MOVING
	block_saved["cat_position"] = Vector2i(4, 4)
	block_saved["white_fire_cells"] = [Vector2i(0, 0)]
	block_saved["active_edges"] = [
		{"a": Vector2i(1, 1), "b": Vector2i(2, 1)},
		{"a": Vector2i(2, 1), "b": Vector2i(2, 2)},
		{"a": Vector2i(2, 2), "b": Vector2i(1, 2)},
		{"a": Vector2i(1, 2), "b": Vector2i(1, 1)},
	]
	block_saved["fox_preview_cells"] = []
	block_saved["fox_preview_due_turn"] = int(block_saved.get("turn_number", 1))
	block_saved["fox_committed_cell"] = Vector2i(-1, -1)
	block_saved["fox_preview_line_cut_edge"] = ""
	_expect(block.restore_snapshot(block_saved), "SLICE-09 block-seal setup restores")
	var block_event: Dictionary = block.finish_cat_movement()
	_expect(bool(block_event.get("block_seal_bonus", false)) and block.state.block_bonus_pending, "SLICE-09 closed loop grants a city-block bonus")
	_expect(block.state.white_fire_cells.is_empty() and int(block.result().get("city_blocks_sealed", 0)) == 1, "SLICE-09 bonus removes one white fire and increments the result")
	var block_action := block.resolve_fox_action()
	_expect(bool(block_action.get("block_seal_bonus", false)) and block.state.phase == ControllerScript.BattlePhase.TURN_END, "SLICE-09 city-block bonus skips the next fox action")
	block.free()

	var repair_config := DifficultyConfigScript.new(5, 0, 1, 0)
	repair_config.enable_line_cut = true
	var repair := _new_battle_with_config(repair_config, 444)
	var repair_saved: Dictionary = repair.snapshot()
	repair_saved["phase"] = ControllerScript.BattlePhase.FOX_ACTION
	repair_saved["active_edges"] = []
	repair_saved["severed_edges"] = [{"a": Vector2i(1, 1), "b": Vector2i(1, 2)}]
	repair_saved["cat_position"] = Vector2i(1, 1)
	repair_saved["move_steps"] = 1
	repair_saved["current_input_path"] = []
	repair_saved["reachable_endpoints"] = []
	repair_saved["fox_preview_cells"] = []
	repair_saved["fox_preview_line_cut_edge"] = ""
	_expect(repair.restore_snapshot(repair_saved), "SLICE-07 repaired-edge setup restores")
	repair_saved["phase"] = ControllerScript.BattlePhase.PATH_INPUT
	repair_saved["current_input_path"] = [Vector2i(1, 1)]
	_expect(repair.restore_snapshot(repair_saved), "SLICE-07 repaired-edge path checkpoint restores")
	_expect(bool(repair.press_cell(Vector2i(1, 2)).get("ok", false)) and bool(repair.confirm_path().get("ok", false)) and int(repair.result().get("line_cuts_repaired", 0)) == 1, "SLICE-07 traversing a cut edge repairs it")
	repair.free()


func _new_battle(battle_lap: int = 1, seed_value: int = 101) -> FoxFireSixRoutesController:
	var battle: FoxFireSixRoutesController = ControllerScript.new()
	_expect(battle.configure(battle_lap, {}, seed_value), "battle LAP %d configures" % battle_lap)
	_expect(bool(battle.start_battle().get("ok", false)), "battle LAP %d starts" % battle_lap)
	return battle


func _new_battle_with_config(config: FoxFireDifficultyConfig, seed_value: int) -> FoxFireSixRoutesController:
	var battle: FoxFireSixRoutesController = ControllerScript.new()
	_expect(battle.configure(1, {}, seed_value, config), "custom difficulty configures")
	_expect(bool(battle.start_battle().get("ok", false)), "custom difficulty starts")
	return battle


func _trace(battle: FoxFireSixRoutesController, destinations: Array[Vector2i]) -> bool:
	for destination: Vector2i in destinations:
		if not bool(battle.press_cell(destination).get("ok", false)):
			return false
	return true


func _play_turn(battle: FoxFireSixRoutesController, steps: int, destinations: Array[Vector2i]) -> bool:
	if not bool(battle.set_move_steps_for_test(steps).get("ok", false)):
		return false
	if not _trace(battle, destinations):
		return false
	if not bool(battle.confirm_path().get("ok", false)):
		return false
	if not bool(battle.finish_cat_movement().get("ok", false)):
		return false
	if battle.state.phase == ControllerScript.BattlePhase.VICTORY:
		return true
	if not bool(battle.resolve_fox_action().get("ok", false)):
		return false
	if battle.state.phase == ControllerScript.BattlePhase.DEFEAT:
		return true
	return bool(battle.finish_turn().get("ok", false))


func _find_exact_path(
	battle: FoxFireSixRoutesController,
	target: Vector2i,
	steps: int
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [battle.state.cat_position]
	var visited: Dictionary = {battle.state.cat_position: true}
	if _find_path_dfs(battle, battle.state.cat_position, target, steps, visited, path):
		path.pop_front()
		return path
	return []


func _find_path_dfs(
	battle: FoxFireSixRoutesController,
	current: Vector2i,
	target: Vector2i,
	remaining: int,
	visited: Dictionary,
	path: Array[Vector2i]
) -> bool:
	if remaining == 0:
		return current == target
	var distance := absi(target.x - current.x) + absi(target.y - current.y)
	if distance > remaining or (remaining - distance) % 2 != 0:
		return false
	for direction: Vector2i in ControllerScript.ORTHOGONAL_DIRECTIONS:
		var neighbor := current + direction
		if not battle.is_in_bounds(neighbor) or visited.has(neighbor) or battle.state.white_fire_cells.has(neighbor):
			continue
		visited[neighbor] = true
		path.append(neighbor)
		if _find_path_dfs(battle, neighbor, target, remaining - 1, visited, path):
			return true
		path.pop_back()
		visited.erase(neighbor)
	return false


func _first_adjacent_not_in(
	position: Vector2i,
	blocked: Array,
	battle: FoxFireSixRoutesController
) -> Vector2i:
	for direction: Vector2i in ControllerScript.ORTHOGONAL_DIRECTIONS:
		var candidate := position + direction
		if battle.is_in_bounds(candidate) and not blocked.has(candidate) and not battle.state.white_fire_cells.has(candidate):
			return candidate
	return Vector2i(-1, -1)


func _first_open_neighbor(position: Vector2i, battle: FoxFireSixRoutesController) -> Vector2i:
	for direction: Vector2i in ControllerScript.ORTHOGONAL_DIRECTIONS:
		var candidate := position + direction
		if battle.is_in_bounds(candidate) and not battle.state.white_fire_cells.has(candidate) and battle.torii_id_at(candidate) < 0:
			return candidate
	return Vector2i(-1, -1)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
