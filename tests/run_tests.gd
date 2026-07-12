extends SceneTree

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const BoardModelScript = preload("res://scripts/game/board_model.gd")
const BossSystemScript = preload("res://scripts/game/boss_system.gd")
const RewardResolverScript = preload("res://scripts/game/reward_resolver.gd")
const EventSystemScript = preload("res://scripts/game/event_system.gd")
const DicePresentation3DScript = preload("res://scripts/game/dice_presentation_3d.gd")
const DiceAudioControllerScript = preload("res://scripts/game/dice_audio_controller.gd")

var failures: int = 0

func _init() -> void:
	_expect(DiceLogicScript.evaluate([3, 3, 5]).main == &"PAIR", "PAIR")
	_expect(DiceLogicScript.evaluate([4, 2, 3]).main == &"STRAIGHT", "STRAIGHT unordered")
	_expect(DiceLogicScript.evaluate([5, 5, 5]).main == &"TRIPLE", "TRIPLE priority")
	_expect(DiceLogicScript.evaluate([5, 5, 5]).support == &"ALL ODD", "TRIPLE + ALL ODD")
	_expect(DiceLogicScript.evaluate([2, 4, 6]).support == &"ALL EVEN", "ALL EVEN")
	_expect(DiceLogicScript.recommended_indices([1, 6, 6, 2, 6]) == [1, 2, 4], "5 dice recommendation")
	var face_orientations: Array[Vector3] = []
	for face: int in range(1, 7): face_orientations.append(DicePresentation3DScript.orientation_for_face(face))
	_expect(face_orientations.duplicate().all(func(orientation: Vector3) -> bool: return face_orientations.count(orientation) == 1), "six deterministic face orientations are unique")
	_expect(face_orientations[0] == Vector3.ZERO and is_equal_approx(face_orientations[5].x, PI), "faces 1 and 6 are opposite")
	_expect(is_equal_approx(face_orientations[1].x, -PI * 0.5) and is_equal_approx(face_orientations[4].x, PI * 0.5), "faces 2 and 5 are opposite")
	_expect(is_equal_approx(face_orientations[2].z, PI * 0.5) and is_equal_approx(face_orientations[3].z, -PI * 0.5), "faces 3 and 4 are opposite")
	var five_layout: Array[Vector3] = DicePresentation3DScript.layout_for_count(5)
	_expect(five_layout.size() == 5 and five_layout.slice(0, 3).all(func(position: Vector3) -> bool: return position.z < 0) and five_layout.slice(3, 5).all(func(position: Vector3) -> bool: return position.z > 0), "five dice layout is three plus two")
	var throw_start: Vector3 = DicePresentation3DScript.throw_offset(0.0, 0); var throw_peak: Vector3 = DicePresentation3DScript.throw_offset(0.5, 0); var throw_end: Vector3 = DicePresentation3DScript.throw_offset(1.0, 0)
	_expect(throw_peak.y > throw_start.y and throw_peak.y > throw_end.y and throw_start.z > throw_end.z, "dice use a forward launch arc before settling")
	_expect(DiceAudioControllerScript.PLAYER_POOL_SIZE == 9 and DiceAudioControllerScript.MAX_ROLL_VOICES == 2, "dice audio uses bounded shared pools")
	_expect(DiceAudioControllerScript.next_variation_index(4, 2, 0) != 2 and DiceAudioControllerScript.next_variation_index(4, 2, 99) != 2, "dice audio avoids immediate variation repeats")
	var wrapped: Dictionary = BoardModelScript.move(89, 4)
	_expect(wrapped.index == 3 and wrapped.laps == 1, "89 to 0 lap")
	var long_move: Dictionary = BoardModelScript.move(0, 378)
	_expect(long_move.index == 18 and long_move.laps == 4, "multi lap")
	var simulated_index: int = 0
	var simulated_laps: int = 0
	for distance: int in [10, 11, 8, 14, 9, 12, 7, 15, 6, 13, 10, 11, 8, 14, 9, 12, 7, 15, 6, 13]:
		var simulated: Dictionary = BoardModelScript.move(simulated_index, distance)
		simulated_index = simulated.index
		simulated_laps += simulated.laps
	_expect(simulated_index >= 0 and simulated_index < 90 and simulated_laps == 2, "20 consecutive rolls stay valid")
	var tiles: Array[StringName] = BoardModelScript.build_tile_types()
	_expect(tiles.size() == 90, "90 tiles")
	var expected: Dictionary = {&"NORMAL": 39, &"EVENT": 11, &"ITEM": 10, &"COIN": 6, &"WARP": 3, &"SHOP": 3, &"REST": 4, &"LANDMARK": 3, &"BOSS_SCENT": 4, &"STAGE_SPECIAL": 2, &"RISK": 5}
	for tile_type: StringName in expected:
		_expect(tiles.count(tile_type) == expected[tile_type], "distribution " + tile_type)
	var districts := [tiles.slice(0, 18), tiles.slice(18, 36), tiles.slice(36, 54), tiles.slice(54, 72), tiles.slice(72, 90)]
	_expect(districts.all(func(district: Array) -> bool: return district.size() == 18), "five districts have 18 tiles")
	_expect(districts[0].count(&"ITEM") == 3 and districts[0].count(&"RISK") == 0, "market supply district")
	_expect(districts[1].count(&"RISK") == 1 and districts[1].count(&"STAGE_SPECIAL") == 1, "pyramid district")
	_expect(districts[2].count(&"REST") == 3 and districts[2].count(&"RISK") == 1, "oasis district")
	_expect(districts[3].count(&"RISK") == 2 and districts[3].count(&"BOSS_SCENT") == 2, "ruins district")
	_expect(districts[4].count(&"RISK") == 1 and districts[4].count(&"STAGE_SPECIAL") == 1, "dunes district")
	_expect(BoardModelScript.circular_gaps(tiles, &"RISK") == [17, 14, 10, 12, 37], "risk circular gaps")
	_expect(BoardModelScript.circular_gaps(tiles, &"ITEM").min() >= 4, "item circular spacing at least four")
	var heavy: Array[StringName] = [&"SHOP", &"LANDMARK", &"RISK", &"STAGE_SPECIAL", &"WARP"]
	_expect(BoardModelScript.minimum_circular_gap_for(tiles, heavy) >= 4, "heavy tile spacing at least four")
	_expect(BoardModelScript.item_space_rewards_for_roll(0) == [&"DICE_ADD_1"] and BoardModelScript.item_space_rewards_for_roll(34) == [&"DICE_ADD_1"], "item roll 0-34 adds die")
	_expect(BoardModelScript.item_space_rewards_for_roll(35) == [&"ITEM"] and BoardModelScript.item_space_rewards_for_roll(89) == [&"ITEM"], "item roll 35-89 gives item")
	_expect(BoardModelScript.item_space_rewards_for_roll(90) == [&"ITEM_CHOICE"] and BoardModelScript.item_space_rewards_for_roll(99) == [&"ITEM_CHOICE"], "item roll 90-99 gives choice")
	_expect(BoardModelScript.item_space_rewards_for_roll(50, true) == [&"DICE_ADD_1", &"ITEM"], "DOUBLE item guarantees die plus item")
	# M3: deterministic, UI-free travel-companion rules.
	var bosses := BossSystemScript.definitions()
	_expect(bosses.size() >= 3, "three Cairo individuals")
	var sleepy := BossSystemScript.definition_by_id("sleepy_sphinx", bosses)
	var individual := BossSystemScript.initial_individual(1)
	_expect(str(individual.get("name", "")) == "眠そうなスフィンクス", "initial sleepy individual")
	_expect(BossSystemScript.encounter_chance(5, 0) > BossSystemScript.encounter_chance(0, 0), "presence raises encounter chance")
	_expect(BossSystemScript.should_encounter(0, 0, true, 0.99), "TRIPLE forced encounter")
	_expect(BossSystemScript.should_encounter(0, BossSystemScript.RELIEF_FORCE_AFTER, false, 0.99), "relief prevents long absence")
	var relief := {"relief": 0}
	for ignored: int in range(5): relief = BossSystemScript.after_no_encounter(relief)
	_expect(int(relief.relief) == 5, "relief caps after failures")
	var pair_outcome := BossSystemScript.resolve_interaction(individual, sleepy, 0, true)
	_expect(int(pair_outcome.gain) == 21 and int(pair_outcome.individual.gauge) == 21, "PAIR bonus once")
	var regular_outcome := BossSystemScript.resolve_interaction(individual, sleepy, 0, false)
	_expect(int(regular_outcome.gain) == 18, "preferred action base gain")
	individual["gauge"] = 99
	individual["stage"] = "trusting"
	var joined_outcome := BossSystemScript.resolve_interaction(individual, sleepy, 1, false)
	_expect(int(joined_outcome.individual.gauge) == 100 and bool(joined_outcome.joined_now), "gauge clamps and joins once")
	_expect(BossSystemScript.stage_for_gauge(24) == "guarded" and BossSystemScript.stage_for_gauge(25) == "remembering" and BossSystemScript.stage_for_gauge(50) == "talking" and BossSystemScript.stage_for_gauge(75) == "trusting", "bond stages")
	var next := BossSystemScript.next_individual("眠そうなスフィンクス", 2, bosses)
	_expect(str(next.get("name", "")) != "眠そうなスフィンクス", "next individual differs")
	# Temporary dice state machine: 1 travel -> 2 DOUBLE CHANCE -> 3 DICE SLOT.
	var no_role := {"main": DiceLogicScript.MAIN_NONE, "support": DiceLogicScript.MAIN_NONE, "labels": []}
	var double_role := DiceLogicScript.evaluate_current([4, 4], 2)
	_expect(double_role.main == DiceLogicScript.DOUBLE, "two equal dice make DOUBLE")
	_expect(DiceLogicScript.evaluate_current([4, 5], 2).main == DiceLogicScript.MAIN_NONE, "two unequal dice have no role")
	_expect(int(DiceLogicScript.next_dice_state(1, no_role).count) == 1, "one die remains one")
	_expect(int(DiceLogicScript.next_dice_state(2, double_role).count) == 3, "DOUBLE opens slot")
	_expect(int(DiceLogicScript.next_dice_state(2, no_role).count) == 1, "missed DOUBLE returns to one")
	_expect(int(DiceLogicScript.next_dice_state(3, DiceLogicScript.evaluate([6, 6, 6])).count) == 3, "TRIPLE continues slot")
	_expect(int(DiceLogicScript.next_dice_state(3, DiceLogicScript.evaluate([3, 3, 5])).count) == 2, "PAIR returns to two")
	_expect(int(DiceLogicScript.next_dice_state(3, DiceLogicScript.evaluate([2, 3, 4])).count) == 2, "STRAIGHT returns to two")
	_expect(int(DiceLogicScript.next_dice_state(3, DiceLogicScript.evaluate([2, 4, 6])).count) == 2, "ALL EVEN only returns to two")
	_expect(int(DiceLogicScript.next_dice_state(3, DiceLogicScript.evaluate([1, 3, 5])).count) == 1, "ALL ODD only returns to one")
	var kept := DiceLogicScript.next_dice_state(3, no_role, true)
	_expect(int(kept.count) == 3 and bool(kept.consume_keep), "DICE KEEP prevents one decrease")
	var natural_hold := DiceLogicScript.next_dice_state(3, DiceLogicScript.evaluate([5, 5, 5]), true)
	_expect(int(natural_hold.count) == 3 and not bool(natural_hold.consume_keep), "natural TRIPLE does not consume KEEP")
	var progression_state := {"current_dice_count": 1, "applied_resolution_ids": [], "coins": 0, "inventory": {}}
	RewardResolverScript.apply(progression_state, {"resolution_id": "add-1", "state_changes": [{"type": "DICE_ADD_1"}], "rewards": []})
	RewardResolverScript.apply(progression_state, {"resolution_id": "legacy-alias", "state_changes": [{"type": "DICE_UNLOCK"}], "rewards": []})
	_expect(int(progression_state.current_dice_count) == 3, "DICE_ADD_1 and old DICE_UNLOCK alias advance in order")
	RewardResolverScript.apply(progression_state, {"resolution_id": "overflow", "state_changes": [{"type": "DICE_ADD_1"}], "rewards": []})
	_expect(int(progression_state.current_dice_count) == 3 and int(progression_state.coins) == 12, "excess die converts to COIN_S")
	var slot_ready_state := {"current_dice_count": 1, "applied_resolution_ids": [], "coins": 0, "inventory": {}}
	RewardResolverScript.apply(slot_ready_state, {"resolution_id": "slot-ready", "rewards": [{"type": "DICE_SLOT_READY"}], "state_changes": []})
	_expect(int(slot_ready_state.current_dice_count) == 3, "DICE SLOT READY jumps to three")
	RewardResolverScript.apply(slot_ready_state, {"resolution_id": "keep-1", "rewards": [{"type": "DICE_KEEP"}], "state_changes": []})
	RewardResolverScript.apply(slot_ready_state, {"resolution_id": "keep-2", "rewards": [{"type": "DICE_KEEP"}], "state_changes": []})
	_expect(bool(slot_ready_state.dice_keep_active) and int(slot_ready_state.coins) == 12, "duplicate KEEP converts to COIN_S")
	var state_node := get_root().get_node_or_null("GameState")
	if state_node != null:
		var state_original: Dictionary = state_node.to_dictionary().duplicate(true)
		state_node.start_new_game()
		_expect(int(state_node.current_dice_count) == 1, "new game starts with one die")
		state_node.add_dice(); state_node.add_dice()
		_expect(int(state_node.current_dice_count) == 3, "game state reaches slot")
		state_node.apply_dice_roll_transition(3, DiceLogicScript.evaluate([3, 3, 5]))
		_expect(int(state_node.current_dice_count) == 2 and int(state_node.last_roll_dice_count) == 3, "PAIR transition stored")
		var v5_round_trip: Dictionary = state_node.to_dictionary().duplicate(true)
		state_node.current_dice_count = 1
		state_node.apply_dictionary(v5_round_trip)
		_expect(int(state_node.current_dice_count) == 2 and int(state_node.to_dictionary().version) == 5, "v5 restores current dice")
		var before_extra := int(state_node.current_dice_count)
		state_node.apply_dice_roll_transition(5, DiceLogicScript.evaluate_many([1, 2, 3, 4, 5]))
		_expect(int(state_node.current_dice_count) == before_extra, "temporary five dice preserves current")
		state_node.reset_run()
		_expect(int(state_node.current_dice_count) == 1, "new trip reset returns to one die")
		var old_state := state_original.duplicate(true)
		old_state["version"] = 4
		old_state.erase("current_dice_count")
		old_state["unlocked_dice_count"] = 3
		state_node.apply_dictionary(old_state)
		_expect(int(state_node.current_dice_count) == 2, "v4 three-dice save migrates once to DOUBLE CHANCE")
		state_node.apply_dictionary(state_original)
	# M4A: data-driven event foundation.
	var events := EventSystemScript.definitions()
	_expect(events.size() == 10, "M4A representative ten events")
	_expect(EventSystemScript.district_for_tile(0) == "MARKET" and EventSystemScript.district_for_tile(18) == "PYRAMID" and EventSystemScript.district_for_tile(89) == "DUNES", "event districts")
	var event_state := _event_state()
	var market_pool := EventSystemScript.pool_for("MARKET", events, event_state)
	_expect(market_pool.size() == 3, "district pool implemented events only")
	event_state.recent_event_ids.assign(["CAI-E01"])
	_expect(EventSystemScript.pool_for("MARKET", events, event_state).all(func(event: Dictionary) -> bool: return event.event_id != "CAI-E01"), "last event excluded")
	event_state.recent_event_ids.assign(["CAI-E02", "CAI-E01"]); event_state.seen_event_ids.assign(["CAI-E01", "CAI-E02"])
	var weighted := EventSystemScript.pool_for("MARKET", events, event_state)
	var e01_weight := _weight_for(weighted, "CAI-E01"); var e03_weight := _weight_for(weighted, "CAI-E03")
	_expect(e03_weight > e01_weight, "unseen weighting exceeds recent")
	var arrival_pair := EventSystemScript.arrival_snapshot([3, 3, 4], DiceLogicScript.evaluate([3, 3, 4]), true, &"relaxed")
	_expect(arrival_pair.source_total == 10 and arrival_pair.source_was_early_stopped and arrival_pair.source_dice_values == [3, 3, 4], "arrival snapshot")
	var e03 := _event(events, "CAI-E03")
	var e03_low := EventSystemScript.resolve(e03, arrival_pair)
	_expect(str(e03_low.result_id) == "cai_e03_pair", "role priority before total")
	var e03_triple := EventSystemScript.resolve(e03, EventSystemScript.arrival_snapshot([2, 2, 2], DiceLogicScript.evaluate([2, 2, 2]), false, &"relaxed"))
	_expect(str(e03_triple.follow_up) == "START_BOSS_ENCOUNTER", "event boss handoff")
	var e02 := _event(events, "CAI-E02")
	var e02_take := EventSystemScript.resolve(e02, arrival_pair, "take")
	_expect(str(e02_take.result_id) == "cai_e02_take_pair", "choice outcome with source role")
	var e11 := _event(events, "CAI-E11")
	var e11_six := EventSystemScript.resolve(e11, arrival_pair, "", {"effective_value": 6, "extra_roles": {"labels": []}})
	_expect(str(e11_six.result_id) == "cai_e11_rare", "extra one die branch")
	var e29 := _event(events, "CAI-E29")
	var extra_triple_roles := DiceLogicScript.evaluate([4, 4, 4])
	var e29_triple := EventSystemScript.resolve(e29, arrival_pair, "", {"extra_roles": extra_triple_roles})
	_expect(str(e29_triple.result_id) == "cai_e29_triple", "extra three dice reuses roles")
	var many := DiceLogicScript.evaluate_many([2, 2, 3, 4, 5])
	_expect(&"PAIR" in many.labels and &"STRAIGHT" in many.labels and int(many.type_count) == 2, "five dice distinct role types")
	var five := DiceLogicScript.evaluate_many([6, 6, 6, 6, 6])
	_expect(bool(five.five_of_a_kind), "five of a kind")
	var e30 := _event(events, "CAI-E30")
	var e30_special := EventSystemScript.resolve(e30, arrival_pair, "", {"extra_roles": five, "role_type_count": five.type_count})
	_expect(str(e30_special.follow_up) == "START_BOSS_ENCOUNTER", "five of a kind handoff")
	var reward_state := _reward_state()
	var resolution := {"resolution_id": "unit-resolution", "state_changes": [{"type": "BOSS_SCENT", "value": 2}], "rewards": [{"type": "COIN", "amount_key": "COIN_M"}, {"type": "TRAVEL_NOTE", "note_id": "unit-note"}]}
	var applied := RewardResolverScript.apply(reward_state, resolution)
	var applied_twice := RewardResolverScript.apply(reward_state, resolution)
	_expect(applied.applied and not applied_twice.applied and reward_state.coins == 30 and reward_state.presence == 2, "reward resolver idempotent")
	_expect(reward_state.registered_travel_notes == ["unit-note"], "record reward unique")
	var capped_state := _reward_state(); capped_state.coins = 99995
	RewardResolverScript.apply(capped_state, {"resolution_id": "coin-cap", "rewards": [{"type": "COIN", "amount_key": "COIN_JACKPOT"}], "state_changes": []})
	_expect(capped_state.coins == 99999, "coin reward cap")
	_expect(RewardResolverScript.item_rarity_for_roll("RARE", 69) == "UNCOMMON" and RewardResolverScript.item_rarity_for_roll("RARE", 70) == "RARE", "ordinary high tier 70/30 boundary")
	_expect(RewardResolverScript.item_rarity_for_roll("RARE_EVENT", 54) == "UNCOMMON" and RewardResolverScript.item_rarity_for_roll("RARE_EVENT", 55) == "RARE", "rare event 55/45 boundary")
	var skill_state := _reward_state(); skill_state.character_skill_charge = 1
	RewardResolverScript.apply(skill_state, {"resolution_id": "skill-full", "rewards": [{"type": "SKILL_RECOVER"}], "state_changes": []})
	_expect(skill_state.character_skill_charge == 1 and skill_state.coins == 12, "skill recover full converts to COIN_S")
	EventSystemScript.record_event(event_state, "CAI-E30")
	_expect(event_state.rare_event_used_this_loop and EventSystemScript.pool_for("DUNES", events, event_state).all(func(event: Dictionary) -> bool: return event.event_id != "CAI-E30"), "rare once per loop")
	EventSystemScript.reset_loop_state(event_state)
	_expect(not event_state.rare_event_used_this_loop and event_state.events_seen_this_loop.is_empty() and int(event_state.events_since_rare) == 99, "rare state resets at new loop")
	print("DICE_SLOT_TRIP_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)

func _expect(value: bool, label: String) -> void:
	if value:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func _event(events: Array[Dictionary], id: String) -> Dictionary:
	for event: Dictionary in events:
		if str(event.event_id) == id: return event
	return {}

func _weight_for(events: Array[Dictionary], id: String) -> float:
	for event: Dictionary in events:
		if str(event.event_id) == id: return float(event.effective_weight)
	return 0.0

func _event_state() -> Dictionary:
	return {"event_history": [], "seen_event_ids": [], "recent_event_ids": [], "events_seen_this_loop": [], "rare_event_used_this_loop": false, "events_since_rare": 99}

func _reward_state() -> Dictionary:
	return {"coins": 0, "presence": 0, "inventory": {}, "registered_travel_notes": [], "registered_postcards": [], "applied_resolution_ids": [], "pending_boss_handoff": false, "character_skill_charge": 1}
