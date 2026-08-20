extends SceneTree

## Deterministic core contract tests for 狐火追陣.  The view can animate a
## returned path, but it must not own any of the rules asserted here.

const ControllerScript = preload("res://boss/kyoto/fox_fire_chase/fox_fire_chase_controller.gd")
const BoardScript = preload("res://boss/kyoto/fox_fire_chase/fox_fire_chase_board.gd")
const DifficultyScript = preload("res://boss/kyoto/fox_fire_chase/data/fox_fire_chase_difficulty.gd")
const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")

var failures: int = 0


func _init() -> void:
	_test_board_geometry_and_cell_ids()
	_test_initial_distance_and_head_start()
	_test_face_pair_and_fox_first_order()
	_test_fire_generation_and_detour()
	_test_corner_fire_zero_loss()
	_test_adjacent_fire_is_one_detour()
	_test_goshuin_choice_and_cleanse()
	_test_mid_detour_pause_and_restore()
	_test_shared_slot_bonuses()
	_test_difficulty_bands()
	_test_snapshot_roundtrip_and_strict_ids()
	_test_victory_and_defeat_boundaries()
	_test_reference_balance_pacing()
	print("FOX_FIRE_CHASE_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_board_geometry_and_cell_ids() -> void:
	var ring := BoardScript.outer_ring()
	_expect(ring.size() == 20, "BOARD has exactly twenty outer cells")
	_expect(ring[0] == Vector2i(0, 0) and ring[5] == Vector2i(5, 0), "BOARD top edge follows clockwise order")
	_expect(ring[10] == Vector2i(5, 5) and ring[15] == Vector2i(0, 5), "BOARD corners retain clockwise order")
	_expect(ring[19] == Vector2i(0, 1), "BOARD final cell closes the ring")
	for position: Vector2i in ring:
		var id := BoardScript.cell_id(position)
		_expect(BoardScript.position_from_cell_id(id) == position, "BOARD cell id roundtrips %s" % position)
		_expect(BoardScript.outer_index_for_cell_id(id) >= 0, "BOARD outer cell id remains on ring")
	_expect(BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX) == Vector2i(2, 5), "BOARD cat starts in specification cell 14")
	_expect(BoardScript.outer_position(BoardScript.FOX_START_OUTER_INDEX) == Vector2i(3, 0), "BOARD fox starts in specification cell 4")


func _test_initial_distance_and_head_start() -> void:
	var battle: FoxFireChaseController = ControllerScript.new()
	_expect(battle.configure_battle(1, 3, 9, 909), "COIN battle configures before start")
	_expect(battle.distance_to_fox() == 10, "START distance is ten outer cells")
	_expect(battle.state.cat_position == Vector2i(2, 5) and battle.state.fox_position == Vector2i(3, 0), "START positions match the specification")
	var first := battle.buy_head_start()
	_expect(bool(first.get("ok", false)) and battle.distance_to_fox() == 9 and battle.state.cat_progress == 1, "COIN three buys one-cell head start")
	var second := battle.buy_head_start()
	_expect(bool(second.get("ok", false)) and battle.distance_to_fox() == 8 and battle.state.cat_progress == 2, "COIN head start can be purchased twice")
	_expect(not bool(battle.buy_head_start().get("ok", true)), "COIN head start is capped at two purchases")
	battle.free()


func _test_face_pair_and_fox_first_order() -> void:
	var battle := _new_battle(1, 0, 22)
	var event := battle.commit_face(2)
	_expect(str(event.get("status", "")) == "TURN_RESOLVED", "ROLL commits a legal face")
	_expect(int(event.get("fox_face", 0)) == 5 and int(event.get("face", 0)) == 2, "ROLL exposes standard die complement")
	_expect(battle.state.fox_progress == 15 and battle.state.cat_progress == 2, "FOX moves by the back face before PLAYER")
	_expect(battle.distance_to_fox() == 13, "ROLL keeps the displayed clockwise gap deterministic")
	_expect(battle.state.current_turn_fox_path.size() == 5 and battle.state.current_turn_cat_path.size() == 2, "ROLL returns one-cell paths for both pieces")
	battle.free()


func _test_fire_generation_and_detour() -> void:
	var battle := _new_battle(1, 0, 33)
	# Put the player on the left edge before a central-edge fire.  The
	# fire at raw ring index 17 is directly ahead and the exit is index 19.
	battle.state.cat_progress = 3
	battle.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 3)
	battle.state.fox_progress = 10
	battle.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 10)
	battle.state.fox_fire_indices = {17: true}
	var event := battle.commit_face(4)
	_expect(str(event.get("status", "")) == "TURN_RESOLVED", "FIRE auto-detour resolves without a goshuin")
	_expect(int(event.get("fox_fire_created", -1)) == -1, "FIRE is only created by PLAYER six")
	_expect(battle.result().get("fox_fire_encounters", 0) == 1 and battle.result().get("fox_fire_detours", 0) == 1, "FIRE encounter increments once and groups one detour")
	_expect(battle.state.cat_progress == 5 and battle.state.cat_on_outer, "FIRE detour exits at the first clear outer cell")
	_expect(battle.state.current_turn_cat_path.size() == 4 and _contains_inner_cell(battle.state.current_turn_cat_path), "FIRE detour visibly traverses inner cells")
	_expect(_is_orthogonal_path(battle.state.current_turn_cat_path), "FIRE detour path is orthogonal one-cell movement")
	battle.free()

	var fire_battle := _new_battle(1, 0, 34)
	var fire_event := fire_battle.commit_face(6)
	_expect(int(fire_event.get("fox_fire_created", -1)) == 3, "FACE six places fire at fox pre-move cell")
	_expect(fire_battle.state.fox_progress == 11 and fire_battle.state.fox_fire_indices.has(3), "FACE six then advances fox by one")
	fire_battle.free()


func _test_corner_fire_zero_loss() -> void:
	var battle := _new_battle(1, 0, 44)
	battle.state.cat_progress = 1 # raw index 14, next raw index 15 is a corner.
	battle.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 1)
	battle.state.fox_progress = 10
	battle.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 10)
	battle.state.fox_fire_indices = {15: true}
	var event := battle.commit_face(2)
	_expect(str(event.get("status", "")) == "TURN_RESOLVED", "CORNER fire resolves through the local detour")
	_expect(battle.state.cat_progress == 3 and battle.state.current_turn_cat_path.size() == 2, "CORNER fire permits zero extra movement loss")
	battle.free()


func _test_adjacent_fire_is_one_detour() -> void:
	var battle := _new_battle(1, 0, 55)
	battle.state.cat_progress = 3
	battle.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 3)
	battle.state.fox_progress = 10
	battle.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 10)
	battle.state.fox_fire_indices = {17: true, 18: true}
	var event := battle.commit_face(5)
	_expect(str(event.get("status", "")) == "TURN_RESOLVED", "ADJACENT fires resolve in one turn")
	_expect(battle.result().get("fox_fire_detours", 0) == 1 and battle.result().get("fox_fire_encounters", 0) == 1, "ADJACENT fires count as one grouped detour")
	_expect(battle.state.cat_progress == 6 and battle.state.cat_on_outer, "ADJACENT fire detour exits after the run")
	battle.free()


func _test_goshuin_choice_and_cleanse() -> void:
	var battle := _new_battle(1, 1, 66)
	battle.state.cat_progress = 3
	battle.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 3)
	battle.state.fox_progress = 10
	battle.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 10)
	battle.state.fox_fire_indices = {17: true}
	var choice := battle.commit_face(1)
	_expect(str(choice.get("status", "")) == "FIRE_CHOICE" and battle.state.phase == ControllerScript.Phase.FIRE_CHOICE, "GOSHUIN presents a choice at a blocked outer cell")
	_expect(int(choice.get("pending_fire_index", -1)) == 17 and battle.state.goshuin_count == 1, "GOSHUIN choice targets the encountered fire")
	var cleanse := battle.resolve_fire_choice(ControllerScript.CHOICE_CLEANSE)
	_expect(str(cleanse.get("status", "")) == "TURN_RESOLVED", "GOSHUIN cleanse resumes movement")
	_expect(battle.state.goshuin_count == 0 and not battle.state.fox_fire_indices.has(17), "GOSHUIN removes exactly one fire")
	_expect(battle.state.cat_progress == 4 and battle.result().get("goshuin_used", 0) == 1, "GOSHUIN cleanse spends no more than one movement cell")
	battle.free()

	var detour_battle := _new_battle(1, 1, 67)
	detour_battle.state.cat_progress = 3
	detour_battle.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 3)
	detour_battle.state.fox_progress = 10
	detour_battle.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 10)
	detour_battle.state.fox_fire_indices = {17: true}
	detour_battle.commit_face(1)
	var detour := detour_battle.resolve_fire_choice(ControllerScript.CHOICE_DETOUR)
	_expect(str(detour.get("status", "")) == "TURN_RESOLVED" and not detour_battle.state.cat_on_outer, "GOSHUIN detour choice preserves the route")
	_expect(detour_battle.state.goshuin_count == 1 and detour_battle.state.fox_fire_indices.has(17), "GOSHUIN is retained when the player chooses detour")
	detour_battle.free()


func _test_mid_detour_pause_and_restore() -> void:
	var battle := _new_battle(1, 0, 77)
	battle.state.cat_progress = 3
	battle.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 3)
	battle.state.fox_progress = 10
	battle.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 10)
	battle.state.fox_fire_indices = {17: true}
	var first := battle.commit_face(1)
	_expect(str(first.get("status", "")) == "TURN_RESOLVED" and not battle.state.cat_on_outer, "MID-DETOUR stops inside when movement is exhausted")
	_expect(battle.state.detour_exit_progress == 5 and not battle.state.detour_path.is_empty(), "MID-DETOUR retains exit progress and remaining path")
	var saved := battle.snapshot()
	_expect(saved.has("cat_cell_id") and saved.has("detour_path_cell_ids"), "SNAPSHOT stores integer cell ids for positions and paths")
	var restored := ControllerScript.new()
	_expect(restored.restore_snapshot(saved), "SNAPSHOT restores a mid-detour state")
	_expect(restored.snapshot() == saved, "SNAPSHOT roundtrip is byte-structure stable")
	battle.free()
	restored.free()


func _test_shared_slot_bonuses() -> void:
	var shared := V06RollSetScript.new()
	for face: int in [4, 4, 4]:
		shared.append_face(face)
	_expect(shared.evaluate_role() == V06RollSetScript.ROLE_TRIPLE, "SLOT uses shared V06 triple role")
	shared.reset_after_resolution()
	_expect(_bonus_for([4, 4, 4]) == 3, "SLOT TRIPLE grants plus three player steps")
	_expect(_bonus_for([4, 4, 5]) == 1, "SLOT PAIR grants plus one player step")
	_expect(_bonus_for([2, 3, 4]) == 2, "SLOT STRAIGHT grants plus two player steps")
	_expect(_bonus_for([1, 3, 5]) == 0, "SLOT MIX grants no player steps")

	var battle := _new_battle(1, 0, 88)
	for face: int in [4, 4, 4]:
		var event := battle.commit_face(face)
		if face != 4 or battle.state.phase == ControllerScript.Phase.VICTORY or battle.state.phase == ControllerScript.Phase.DEFEAT:
			break
		if battle.state.phase == ControllerScript.Phase.TURN_RESOLVED:
			battle.acknowledge_turn()
	_expect(battle.result().get("triple_count", 0) == 1 and battle.result().get("slot_bonus_steps", 0) == 3, "SLOT TRIPLE is counted and applied to the current turn")
	battle.free()


func _test_difficulty_bands() -> void:
	var cases := [
		[1, 1, 1.00], [3, 1, 1.00], [4, 2, 1.06], [6, 2, 1.06],
		[7, 3, 1.12], [10, 3, 1.12], [11, 4, 1.18], [15, 4, 1.18],
		[16, 5, 1.24], [20, 5, 1.24], [21, 6, 1.30], [25, 6, 1.30],
		[26, 7, 1.36], [30, 7, 1.36], [31, 8, 1.42], [99, 8, 1.42],
	]
	for item: Array in cases:
		var difficulty := DifficultyScript.for_lap(int(item[0]))
		_expect(difficulty.level == int(item[1]) and is_equal_approx(difficulty.roll_speed_scale, float(item[2])), "DIFFICULTY lap %d maps to Lv%d" % [item[0], item[1]])


func _test_snapshot_roundtrip_and_strict_ids() -> void:
	var battle := _new_battle(4, 0, 111)
	var saved := battle.snapshot()
	var restored := ControllerScript.new()
	_expect(restored.restore_snapshot(saved), "SNAPSHOT restores a standard ready state")
	var json_restored := ControllerScript.new()
	var encoded := JSON.stringify(saved)
	var decoded: Variant = JSON.parse_string(encoded)
	_expect(decoded is Dictionary and json_restored.restore_snapshot(decoded as Dictionary), "SNAPSHOT JSON roundtrip restores integer cell ids")
	_expect(json_restored.snapshot() == saved, "SNAPSHOT JSON roundtrip preserves the exact state")
	var missing_id := saved.duplicate(true)
	missing_id.erase("cat_position")
	missing_id.erase("cat_cell_id")
	_expect(not restored.restore_snapshot(missing_id), "SNAPSHOT rejects v2 position without integer cell id")
	var float_id := saved.duplicate(true)
	float_id["cat_position"] = 14.5
	_expect(not restored.restore_snapshot(float_id), "SNAPSHOT rejects non-integer cell ids")
	var bad_path := saved.duplicate(true)
	bad_path["detour_path"] = ["18"]
	_expect(not restored.restore_snapshot(bad_path), "SNAPSHOT rejects non-integer path cell ids")
	var bad_fire := saved.duplicate(true)
	bad_fire["fox_fire_cell_ids"] = [7]
	_expect(not restored.restore_snapshot(bad_fire), "SNAPSHOT rejects inner cell as fox fire")
	battle.free()
	restored.free()
	json_restored.free()


func _test_victory_and_defeat_boundaries() -> void:
	var victory := _new_battle(1, 0, 120)
	victory.state.cat_progress = 8
	victory.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 8)
	victory.state.fox_progress = 9
	victory.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 9)
	var win_event := victory.commit_face(6)
	_expect(str(win_event.get("status", "")) == "VICTORY" and victory.state.phase == ControllerScript.Phase.VICTORY, "VICTORY triggers when PLAYER reaches the fox")
	_expect(bool(victory.result().get("victory", false)) and victory.result().get("final_distance", -1) == 0, "VICTORY result clears distance")
	victory.free()

	var defeat := _new_battle(1, 0, 121)
	defeat.state.cat_progress = 0
	defeat.state.cat_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX)
	defeat.state.fox_progress = 14
	defeat.state.fox_position = BoardScript.outer_position(BoardScript.CAT_BASE_OUTER_INDEX + 14)
	var lose_event := defeat.commit_face(1) # fox +6 reaches cat +20 before cat moves.
	_expect(str(lose_event.get("status", "")) == "DEFEAT" and defeat.state.phase == ControllerScript.Phase.DEFEAT, "DEFEAT triggers when fox laps the outer progress")
	_expect(str(defeat.result().get("defeat_reason", "")) == "FOX_LAPPED_PLAYER", "DEFEAT reason identifies fox lap")
	defeat.free()


func _test_reference_balance_pacing() -> void:
	# Face 4 is the readable baseline described by the design: it gains one cell
	# per ordinary turn and receives the shared TRIPLE bonus every third stop.
	var battle := _new_battle(1, 0, 40404)
	var guard := 12
	while battle.state.phase not in [ControllerScript.Phase.VICTORY, ControllerScript.Phase.DEFEAT] and guard > 0:
		if battle.state.phase == ControllerScript.Phase.TURN_RESOLVED:
			battle.acknowledge_turn()
		elif battle.state.phase == ControllerScript.Phase.ROLL_READY:
			battle.commit_face(4)
		else:
			break
		guard -= 1
	var rolls := int(battle.result().get("rolls_used", 0))
	_expect(battle.state.phase == ControllerScript.Phase.VICTORY, "BALANCE fixed face 4 produces a player victory")
	_expect(rolls >= 5 and rolls <= 8, "BALANCE readable face-4 play settles within the 5-8 ROLL target")
	battle.free()


func _new_battle(lap: int, goshuin: int, seed_value: int) -> FoxFireChaseController:
	return _new_battle_with_coins(lap, goshuin, seed_value, 0)


func _new_battle_with_coins(lap: int, goshuin: int, seed_value: int, coins: int) -> FoxFireChaseController:
	var battle: FoxFireChaseController = ControllerScript.new()
	_expect(battle.configure_battle(lap, goshuin, coins, seed_value), "battle lap %d configures" % lap)
	_expect(str(battle.start_battle().get("status", "")) == "ROLL_READY", "battle lap %d starts" % lap)
	return battle


func _bonus_for(values: Array[int]) -> int:
	var roll_set := V06RollSetScript.new()
	if not roll_set.restore_faces(values):
		return -1
	match roll_set.evaluate_role():
		V06RollSetScript.ROLE_PAIR:
			return 1
		V06RollSetScript.ROLE_STRAIGHT:
			return 2
		V06RollSetScript.ROLE_TRIPLE:
			return 3
	return 0


func _contains_inner_cell(path: Array[Vector2i]) -> bool:
	for position: Vector2i in path:
		if not BoardScript.is_outer_position(position):
			return true
	return false


func _is_orthogonal_path(path: Array[Vector2i]) -> bool:
	if path.is_empty():
		return true
	for index: int in range(1, path.size()):
		var previous := path[index - 1]
		var current := path[index]
		if absi(current.x - previous.x) + absi(current.y - previous.y) != 1:
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
