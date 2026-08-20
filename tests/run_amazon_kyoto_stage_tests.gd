extends SceneTree

const AmazonCourse := preload("res://scripts/game/amazon_course_model.gd")
const AmazonJourneyScript := preload("res://scripts/game/amazon_journey.gd")
const Aquafall := preload("res://scripts/game/aquafall_battle.gd")
const KyotoCourse := preload("res://scripts/game/kyoto_course_model.gd")
const KyotoJourneyScript := preload("res://scripts/game/kyoto_journey.gd")
const WhiteFox := preload("res://scripts/game/white_fox_battle.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_amazon_course()
	_test_amazon_journey()
	_test_full_rest_bonus()
	_test_shared_travel_resources()
	_test_shared_random_mission()
	_test_item_spaces_and_inventory()
	_test_amazon_events()
	_test_amazon_risk_life_contract()
	_test_aquafall_reflection()
	_test_aquafall_direction_preview()
	_test_aquafall_snapshot_determinism()
	_test_aquafall_generation_rules()
	_test_aquafall_roles_and_terminals()
	_test_aquafall_defeat_life_retry()
	_test_kyoto_course()
	_test_kyoto_pass_through_goshuin()
	_test_kyoto_risk_life_contract()
	_test_kyoto_luck_shift_and_restore()
	_test_aquafall_goal_collision_order()
	_test_white_fox_rules()
	_test_white_fox_defeat_life_boundaries()
	if failures.is_empty():
		print("AMAZON_KYOTO_TESTS passed=true")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("AMAZON_KYOTO_TESTS passed=false failures=%d" % failures.size())
		quit(1)


func _test_amazon_course() -> void:
	var course := AmazonCourse.new()
	_expect(course.load_file("res://data/stages/amazon_suiu_falls_course.json"), "amazon course loads")
	_expect(course.spaces.size() == 120, "amazon has 120 spaces")
	_expect(course.events.size() == 15, "amazon has 15 events")
	for item_space_id: String in ["main:2", "main:10", "canopy:27", "canopy:34", "stream:45", "main:51", "main:56", "main:59", "temple:78", "submerged:90", "secret:99", "main:110"]:
		_expect(str(course.space(item_space_id).get("kind", "")) == "ITEM", "amazon item space %s is data-driven" % item_space_id)
	var junction := course.advance("main:20", 4)
	_expect(str(junction.get("status", "")) == "CHOICE_REQUIRED", "amazon pauses at junction")
	_expect(int(junction.get("remaining_steps", 0)) == 2, "amazon preserves remaining junction steps")
	var branch := course.advance("main:22", 2, "canopy")
	_expect(bool(branch.get("ok", false)) and str(branch.get("position", "")) == "canopy:24", "amazon branch consumes movement")
	var journey := AmazonJourneyScript.new()
	journey.current_space_id = "main:20"
	var journey_junction := journey.roll(4)
	_expect(str(journey_junction.get("status", "")) == "CHOICE_REQUIRED" and journey_junction.get("path", []).size() == 2, "amazon journey keeps pre-choice path for animated hops")
	for choice_id: String in ["canopy", "stream"]:
		var exact_landing := AmazonJourneyScript.new()
		exact_landing.current_space_id = "main:19"
		var exact_roll := exact_landing.roll(3)
		_expect(str(exact_roll.get("status", "")) == "CHOICE_REQUIRED" and exact_landing.pending_steps == 1 and exact_landing.pending_choices.size() == 2,
			"amazon exact junction landing opens a one-hop route choice for %s" % choice_id)
		var selected := exact_landing.choose_branch(choice_id)
		_expect(bool(selected.get("ok", false)) and not exact_landing.current_space_id == "main:22" and exact_landing.phase != StageJourneyBase.PHASE_BRANCH,
			"amazon exact junction choice %s advances past the fork" % choice_id)


func _test_amazon_journey() -> void:
	var journey := AmazonJourneyScript.new()
	journey.current_space_id = "main:2"
	journey.coins = 0
	var result := journey.roll(1)
	_expect(bool(result.get("ok", false)) and journey.coins == 2, "amazon coin space applies once")
	journey.current_space_id = "main:53"
	journey.phase = StageJourneyBase.PHASE_READY
	journey.roll(1)
	_expect(journey.current_space_id == "main:58", "amazon FLOW moves to target")
	var event_mission := AmazonJourneyScript.new()
	event_mission.current_space_id = "main:20"
	var event_landing := event_mission.roll(1)
	_expect(bool(event_landing.get("ok", false)) and int(event_mission.stage_flags.get("mission_event_count", 0)) == 1 and event_mission.phase == StageJourneyBase.PHASE_EVENT,
		"amazon EVENT landing advances the 発見 mission counter")


func _test_full_rest_bonus() -> void:
	var amazon_heal := AmazonJourneyScript.new()
	amazon_heal.hp = 2
	amazon_heal.current_space_id = "main:4"
	var amazon_heal_result := amazon_heal.roll(1)
	_expect(bool(amazon_heal_result.get("ok", false)) and amazon_heal.hp == 3 and amazon_heal.coins == 0 and int(amazon_heal_result.get("coin_bonus", 0)) == 0,
		"amazon REST heals without a coin bonus when HP is not full")

	var amazon_full := AmazonJourneyScript.new()
	amazon_full.current_space_id = "main:4"
	var amazon_full_result := amazon_full.roll(1)
	_expect(bool(amazon_full_result.get("ok", false)) and amazon_full.hp == 3 and amazon_full.coins == 1 and int(amazon_full_result.get("coin_bonus", 0)) == 1 and str(amazon_full_result.get("text", "")) == "HP FULL  COIN +1",
		"amazon full REST grants one coin")

	var kyoto_heal := KyotoJourneyScript.new()
	kyoto_heal.hp = 2
	kyoto_heal.current_space_id = "main:7"
	var kyoto_heal_result := kyoto_heal.roll(1)
	_expect(bool(kyoto_heal_result.get("ok", false)) and kyoto_heal.hp == 3 and kyoto_heal.coins == 0 and int(kyoto_heal_result.get("coin_bonus", 0)) == 0,
		"kyoto REST heals without a coin bonus when HP is not full")

	var kyoto_full := KyotoJourneyScript.new()
	kyoto_full.current_space_id = "main:7"
	var kyoto_full_result := kyoto_full.roll(1)
	_expect(bool(kyoto_full_result.get("ok", false)) and kyoto_full.hp == 3 and kyoto_full.coins == 0 and kyoto_full.skill_gauge() == 1 and int(kyoto_full_result.get("skill_bonus", 0)) == 1,
		"kyoto full REST charges skill without adding coins")
	var rest_mission := KyotoJourneyScript.new()
	rest_mission.current_space_id = "main:7"
	var rest_landing := rest_mission.roll(1)
	_expect(bool(rest_landing.get("ok", false)) and int(rest_mission.stage_flags.get("mission_rest_count", 0)) == 1,
		"kyoto REST landing advances the 灯籠 mission counter")


func _test_shared_travel_resources() -> void:
	for journey_value: Variant in [AmazonJourneyScript.new(), KyotoJourneyScript.new()]:
		var journey := journey_value as StageJourneyBase
		_expect(journey.item_count() == 0 and journey.skill_gauge() == 0, "%s resources start empty" % String(journey.stage_id))
		journey.add_item(2)
		_expect(journey.item_count() == 2, "%s item count is live" % String(journey.stage_id))
		_expect(journey.consume_item() and journey.item_count() == 1, "%s item use decrements inventory" % String(journey.stage_id))
		var pair := journey.charge_skill_for_role("PAIR", 1)
		var straight := journey.charge_skill_for_role("STRAIGHT", 2)
		_expect(int(pair.get("after", 0)) == 1 and int(straight.get("after", 0)) == 3 and journey.skill_ready(), "%s role charges match Cairo" % String(journey.stage_id))
		var armed := journey.arm_skill_face(6)
		_expect(bool(armed.get("ok", false)) and journey.peek_skill_face() == 6 and journey.skill_gauge() == 0, "%s READY chooses the next face" % String(journey.stage_id))
		_expect(journey.consume_skill_face() == 6 and journey.peek_skill_face() == 0, "%s consumes the selected face once" % String(journey.stage_id))
		journey.start_next_lap()
		_expect(journey.item_count() == 0 and journey.skill_gauge() == 0, "%s resets lap-local resources" % String(journey.stage_id))


func _test_shared_random_mission() -> void:
	var journey := KyotoJourneyScript.new()
	var initial := journey.journey_mission_state()
	_expect(not initial.is_empty() and int(initial.get("target", 0)) > 0 and int(initial.get("reward_coins", 0)) == StageJourneyBase.MISSION_STANDARD_REWARD,
		"journey stages start with one Cairo-style random mission")
	journey.stage_flags["journey_mission"] = {
		"id": "journey_face4", "kind": "dice", "short_text": "4を10回出す", "target": 10,
		"target_face": 4, "reward_coins": 12, "icon_kind": "dice", "progress": 9,
		"completed": false, "reward_claimed": false, "selection_seed": 1234, "last_coins": 0,
	}
	var before_reward := journey.coins
	var completed := journey.record_journey_mission_roll(4, 4)
	_expect(bool(completed.get("completed", false)) and int(completed.get("progress", 0)) == 10 and journey.coins == before_reward + 12,
		"journey DICE mission completes and grants its reward")
	journey.record_journey_mission_roll(4, 4)
	_expect(journey.coins == before_reward + 12,
		"journey mission reward cannot be claimed twice")
	var json_roundtrip: Variant = JSON.parse_string(JSON.stringify(journey.snapshot()))
	var restored := KyotoJourneyScript.new()
	_expect(json_roundtrip is Dictionary and restored.restore(json_roundtrip as Dictionary),
		"journey random mission survives a JSON save roundtrip")
	var restored_mission := restored.journey_mission_state()
	var source_mission := journey.journey_mission_state()
	_expect(str(restored_mission.get("id", "")) == str(source_mission.get("id", ""))
		and int(restored_mission.get("progress", -1)) == int(source_mission.get("progress", -2))
		and bool(restored_mission.get("completed", false)) == bool(source_mission.get("completed", false))
		and bool(restored_mission.get("reward_claimed", false)) == bool(source_mission.get("reward_claimed", false)),
		"journey random mission restores its gameplay state exactly")
	var goshuin_before := restored.goshuin_state()
	restored.start_next_lap()
	_expect(restored.goshuin_state() == goshuin_before and not restored.journey_mission_state().is_empty(),
		"next lap rerolls the mission without mixing it into goshuin state")


func _test_item_spaces_and_inventory() -> void:
	var amazon := AmazonJourneyScript.new()
	amazon.current_space_id = "main:1"
	var amazon_item := amazon.roll(1)
	_expect(bool(amazon_item.get("item_acquired", false)) and str(amazon_item.get("item_id", "")) in StageJourneyBase.ITEM_IDS and amazon.item_count() == 1,
		"amazon ITEM landing grants one random Cairo item")
	var kyoto := KyotoJourneyScript.new()
	kyoto.current_space_id = "main:18"
	var kyoto_item := kyoto.roll(1)
	_expect(bool(kyoto_item.get("item_acquired", false)) and str(kyoto_item.get("item_id", "")) in StageJourneyBase.ITEM_IDS and kyoto.item_count() == 1,
		"kyoto ITEM landing grants one random Cairo item")

	var canteen := AmazonJourneyScript.new()
	canteen.hp = 2
	canteen.stage_flags["item_inventory"] = {StageJourneyBase.ITEM_WATER_CANTEEN: 1}
	var canteen_use := canteen.use_item(StageJourneyBase.ITEM_WATER_CANTEEN)
	_expect(bool(canteen_use.get("ok", false)) and canteen.hp == 3 and canteen.item_count() == 0, "water canteen restores one heart")
	var compass := AmazonJourneyScript.new()
	compass.stage_flags["item_inventory"] = {StageJourneyBase.ITEM_BRASS_COMPASS: 1}
	var compass_use := compass.use_item(StageJourneyBase.ITEM_BRASS_COMPASS)
	compass.current_space_id = "main:1"
	var compass_roll := compass.roll(1)
	_expect(bool(compass_use.get("ok", false)) and int(compass_roll.get("move_face", 0)) == 2 and compass.current_space_id == "main:3" and compass.next_move_bonus() == 0,
		"brass compass adds one movement space and is consumed")
	var scarab := KyotoJourneyScript.new()
	scarab.stage_flags["item_inventory"] = {StageJourneyBase.ITEM_SCARAB_SEAL: 1}
	var scarab_use := scarab.use_item(StageJourneyBase.ITEM_SCARAB_SEAL)
	scarab.current_space_id = "main:12"
	var guarded := scarab.roll(1)
	_expect(bool(scarab_use.get("ok", false)) and bool(guarded.get("item_guarded", false)) and scarab.hp == 3 and scarab.item_count() == 0,
		"scarab seal blocks one RISK landing")
	var full := AmazonJourneyScript.new()
	full.current_space_id = "main:1"
	full.coins = 0
	full.stage_flags["item_inventory"] = {
		StageJourneyBase.ITEM_WATER_CANTEEN: 1,
		StageJourneyBase.ITEM_BRASS_COMPASS: 1,
		StageJourneyBase.ITEM_SCARAB_SEAL: 1,
	}
	var full_result := full.roll(1)
	_expect(bool(full_result.get("full", false)) and int(full_result.get("converted_to_coins", 0)) == 2 and full.coins == 2 and full.item_count() == 3,
		"full ITEM bag converts the pickup into two coins")


func _test_amazon_events() -> void:
	var event_spaces := {
		"forest_spirit_choice": "main:9",
		"great_falls_discovery": "main:15",
		"jungle_whisper": "main:21",
		"vine_shortcut": "canopy:26",
		"forest_blessing": "canopy:33",
		"log_ride": "stream:43",
		"waterfall_edge": "main:52",
		"rainbow_wish": "main:58",
		"water_spirit_guide": "main:65",
		"plunge_pool_jump": "main:71",
		"temple_mural": "temple:79",
		"guardian_prayer": "temple:87",
		"sunken_inscription": "submerged:95",
		"ancient_treasure": "secret:102",
		"water_dragon_presence": "main:109",
	}
	var journey := AmazonJourneyScript.new()
	_expect(event_spaces.size() == journey.course.events.size(), "amazon event test covers all 15 definitions")
	var two_choice_count := 0
	for event_id: String in event_spaces:
		var space_id := str(event_spaces[event_id])
		var definition := journey.course.event(event_id)
		_expect(str(journey.course.space(space_id).get("event_id", "")) == event_id, "amazon event %s is connected to its map space" % event_id)
		_expect(not definition.is_empty(), "amazon event %s has a definition" % event_id)
		var choices: Array = definition.get("choices", [])
		_expect(choices.size() <= 2, "amazon event %s stays within the two-choice contract" % event_id)
		if choices.size() == 2:
			two_choice_count += 1
		if choices.is_empty():
			var automatic := AmazonJourneyScript.new()
			automatic.coins = 10
			automatic.hp = 2
			_prime_amazon_event(automatic, space_id)
			var automatic_result := automatic.resolve_event()
			_expect(bool(automatic_result.get("ok", false)) and str(automatic_result.get("event_id", "")) == event_id, "amazon automatic event %s resolves" % event_id)
		else:
			for choice_value: Variant in choices:
				var choice := choice_value as Dictionary
				var choice_journey := AmazonJourneyScript.new()
				choice_journey.coins = 10
				choice_journey.hp = 2
				_prime_amazon_event(choice_journey, space_id)
				var choice_result := choice_journey.resolve_event(str(choice.get("id", "")))
				_expect(bool(choice_result.get("ok", false)) and str(choice_result.get("choice_id", "")) == str(choice.get("id", "")), "amazon event %s choice %s resolves" % [event_id, str(choice.get("id", ""))])
	_expect(two_choice_count == 15, "amazon has all 15 events as two-choice cards")

	journey.hp = 1
	_prime_amazon_event(journey, "main:9")
	var heal := journey.resolve_event("heal")
	_expect(bool(heal.get("ok", false)) and journey.hp == 2 and str(heal.get("choice_id", "")) == "heal", "amazon forest spirit heal choice applies")
	_prime_amazon_event(journey, "main:21")
	var coin := journey.resolve_event("coin")
	_expect(bool(coin.get("ok", false)) and journey.coins == 2, "amazon jungle whisper coin choice applies")

	_prime_amazon_event(journey, "canopy:26")
	var vine := journey.resolve_event("use")
	_expect(journey.current_space_id == "canopy:30" and str(vine.get("start_position", "")) == "canopy:26" and str(vine.get("position", "")) == "canopy:30", "amazon vine shortcut moves and reports its route")
	journey.coins = 1
	_prime_amazon_event(journey, "stream:43")
	var denied := journey.resolve_event("ride")
	_expect(not bool(denied.get("ok", true)) and str(denied.get("error", "")) == "EVENT_REQUIREMENTS_NOT_MET" and journey.phase == StageJourneyBase.PHASE_EVENT, "amazon log ride keeps event pending when coins are insufficient")
	journey.coins = 2
	var ride := journey.resolve_event("ride")
	_expect(bool(ride.get("ok", false)) and journey.coins == 0 and journey.current_space_id == "stream:48", "amazon log ride spends exact cost and moves")

	_prime_amazon_event(journey, "main:52")
	var waterfall := journey.resolve_event("edge")
	_expect(bool(waterfall.get("ok", false)) and journey.current_space_id == "main:58" and waterfall.get("path", []).size() == 2 and int(waterfall.get("flow_chain", 0)) == 1 and journey.phase == StageJourneyBase.PHASE_EVENT and str(journey.pending_event.get("id", "")) == "rainbow_wish", "amazon waterfall choice keeps FLOW follow-up event pending")
	var rainbow := journey.resolve_event("heal")
	_expect(bool(rainbow.get("ok", false)) and journey.phase == StageJourneyBase.PHASE_READY and journey.pending_event.is_empty(), "amazon FLOW follow-up event resolves cleanly")

	journey.hp = 1
	journey.life = 3
	_prime_amazon_event(journey, "main:71")
	var jump := journey.resolve_event("jump")
	_expect(bool(jump.get("ok", false)) and journey.hp == 3 and journey.life == 2 and journey.current_space_id == "main:74" and jump.get("path", []).size() == 1 and bool(jump.get("revived", false)) and journey.phase == StageJourneyBase.PHASE_BRANCH and journey.pending_choices.size() == 2, "amazon plunge jump damage opens the two-choice temple branch")

	journey.coins = 0
	_prime_amazon_event(journey, "main:15")
	var discovery := journey.resolve_event("coin")
	_expect(journey.coins == 2 and str(journey.stage_flags.get("last_camera_cue", "")) == "first_falls_view" and str(discovery.get("event_id", "")) == "great_falls_discovery", "amazon falls discovery grants coins and exposes camera cue")
	_prime_amazon_event(journey, "main:15")
	_expect(journey.phase == StageJourneyBase.PHASE_READY and journey.pending_event.is_empty(), "amazon falls discovery is consumed once")

	journey.coins = 0
	_prime_amazon_event(journey, "secret:102")
	journey.resolve_event("coin")
	_expect(journey.coins == 4, "amazon ancient treasure grants four coins")
	_prime_amazon_event(journey, "secret:102")
	_expect(journey.phase == StageJourneyBase.PHASE_READY, "amazon ancient treasure is consumed once")

	journey.hp = 2
	_prime_amazon_event(journey, "main:109")
	journey.resolve_event("heal")
	_expect(journey.hp == 3 and str(journey.stage_flags.get("last_camera_cue", "")) == "boss_presence", "amazon water dragon presence heals and exposes camera cue")
	_prime_amazon_event(journey, "main:109")
	_expect(journey.phase == StageJourneyBase.PHASE_READY, "amazon water dragon presence is consumed once")


func _prime_amazon_event(journey: AmazonJourney, space_id: String) -> void:
	journey.current_space_id = space_id
	journey.phase = StageJourneyBase.PHASE_READY
	journey.pending_event.clear()
	journey.call("_resolve_landing", true)


func _test_amazon_risk_life_contract() -> void:
	var journey := AmazonJourneyScript.new()
	_assert_risk_life_contract(journey, "main:6", "main:7", "amazon")


func _test_aquafall_reflection() -> void:
	_expect(Aquafall.destination_lane(3, -1, 6) == 5, "aquafall LEFT6 reflection")
	_expect(Aquafall.destination_lane(3, 1, 6) == 1, "aquafall RIGHT6 reflection")
	_expect(Aquafall.difficulty_for_lap(1) == 1 and Aquafall.difficulty_for_lap(3) == 1 and Aquafall.difficulty_for_lap(4) == 2 and Aquafall.difficulty_for_lap(6) == 2 and Aquafall.difficulty_for_lap(7) == 3 and Aquafall.difficulty_for_lap(10) == 3 and Aquafall.difficulty_for_lap(11) == 4 and Aquafall.difficulty_for_lap(14) == 4 and Aquafall.difficulty_for_lap(15) == 5 and Aquafall.difficulty_for_lap(18) == 5 and Aquafall.difficulty_for_lap(19) == 6 and Aquafall.difficulty_for_lap(22) == 6 and Aquafall.difficulty_for_lap(23) == 7 and Aquafall.difficulty_for_lap(26) == 7 and Aquafall.difficulty_for_lap(27) == 8 and Aquafall.difficulty_for_lap(29) == 8, "aquafall waterfall level cadence")
	var boss := Aquafall.new()
	_expect(boss.configure(1, 3, 3, 1234), "aquafall configures")
	boss.obstacles = [{"type": "large_log", "lanes": [2], "relative_height": 1}]
	boss.request_roll(1)
	boss.choose_direction(-1)
	_expect(boss.hp == 2, "aquafall path collision damages once")


func _test_aquafall_direction_preview() -> void:
	var boss := Aquafall.new()
	boss.configure(1, 3, 3, 2468)
	boss.lane = 3
	boss.obstacles = [
		{"type": "large_log", "lanes": [2], "relative_height": 1},
		{"type": "small_log", "lanes": [4], "relative_height": 1},
	]
	boss.request_roll(1)
	var snapshot_before := boss.snapshot()
	var rng_before := boss.rng.state
	var left := boss.preview_direction(-1)
	var right := boss.preview_direction(1)
	_expect(int(left.get("destination_lane", 0)) == 2 and not bool(left.get("safe", true)) and "large_log" in left.get("contacts", []), "aquafall preview reports path large-log contact")
	_expect(int(right.get("destination_lane", 0)) == 4 and not bool(right.get("safe", true)) and "small_log" in right.get("contacts", []), "aquafall preview reports landing small-log contact")
	var all_dice := boss.simulate_all_directions()
	_expect(all_dice.size() == 6 and (all_dice.get("1", {}) as Dictionary).has("left") and (all_dice.get("6", {}) as Dictionary).has("right"), "aquafall simulates all dice and directions")
	_expect(boss.snapshot() == snapshot_before and boss.rng.state == rng_before, "aquafall preview is state and RNG free")
	boss.obstacles.clear()
	_expect(bool(boss.preview_direction(-1).get("safe", false)), "aquafall preview reports safe path")

	var small_pass := Aquafall.new()
	small_pass.configure(1, 3, 3, 2470)
	small_pass.lane = 3
	small_pass.obstacles = [{"type": "small_log", "lanes": [2], "relative_height": 1}]
	small_pass.request_roll(2)
	small_pass.choose_direction(-1)
	_expect(small_pass.hp == 3, "aquafall small log does not damage while passing mid-move")

	var small_land := Aquafall.new()
	small_land.configure(1, 3, 3, 2471)
	small_land.lane = 3
	small_land.obstacles = [{"type": "small_log", "lanes": [1], "relative_height": 2}]
	small_land.request_roll(2)
	small_land.choose_direction(-1)
	_expect(small_land.hp == 2, "aquafall small log damages exactly on the final landing")

	for fixture: Dictionary in [
		{"lane": 2, "steps": 1, "label": "mid-move"},
		{"lane": 1, "steps": 2, "label": "landing"},
	]:
		var large_hit := Aquafall.new()
		large_hit.configure(1, 3, 3, 2472 + int(fixture.steps))
		large_hit.lane = 3
		large_hit.obstacles = [{"type": "large_log", "lanes": [int(fixture.lane)], "relative_height": int(fixture.steps)}]
		large_hit.request_roll(2)
		large_hit.choose_direction(-1)
		_expect(large_hit.hp == 2, "aquafall large log damages on %s contact" % str(fixture.label))

	var multi_hit := Aquafall.new()
	multi_hit.configure(1, 3, 3, 2478)
	multi_hit.lane = 3
	multi_hit.obstacles = [
		{"type": "large_log", "lanes": [2], "relative_height": 1},
		{"type": "large_log", "lanes": [2], "relative_height": 1},
	]
	multi_hit.request_roll(1)
	multi_hit.choose_direction(-1)
	_expect(multi_hit.hp == 1 and multi_hit.damage_this_roll == 2,
		"aquafall applies one damage for each distinct log collision in the same roll")

	var guarded_multi_hit := Aquafall.new()
	guarded_multi_hit.configure(1, 3, 3, 2479)
	guarded_multi_hit.lane = 3
	guarded_multi_hit.water_guard_charges = 1
	guarded_multi_hit.obstacles = [
		{"type": "large_log", "lanes": [2], "relative_height": 1},
		{"type": "large_log", "lanes": [2], "relative_height": 1},
	]
	guarded_multi_hit.request_roll(1)
	guarded_multi_hit.choose_direction(-1)
	_expect(guarded_multi_hit.hp == 2 and guarded_multi_hit.water_guard_charges == 0,
		"aquafall water guard blocks one collision but does not erase later collisions")


func _test_aquafall_goal_collision_order() -> void:
	var boss := Aquafall.new()
	boss.configure(1, 1, 3, 54)
	boss.height = 23
	boss.lane = 3
	boss.obstacles = [{"type": "small_log", "lanes": [2], "relative_height": 1}]
	boss.request_roll(1)
	var result := boss.choose_direction(-1)
	_expect(str(result.get("status", "")) == "DEFEAT" and boss.phase == Aquafall.PHASE_DEFEAT, "aquafall resolves fatal goal-row landing before victory")
	var entries := boss.debug_log()
	_expect(entries.size() == 1 and entries[0].has_all(["lap", "waterfall_level", "pattern_id", "pattern_class", "player_lane", "dice", "left_result", "right_result", "selected_direction", "damage", "current_height", "remaining_hp"]), "aquafall debug log carries level and turn fields")


func _test_aquafall_snapshot_determinism() -> void:
	var source := Aquafall.new()
	_expect(source.configure(3, 3, 3, 991), "aquafall deterministic source configures")
	var saved := source.snapshot()
	_expect(saved.has("rng_state") and saved.has("generation_rules"), "aquafall snapshot carries RNG and generation state")
	var restored := Aquafall.new()
	_expect(restored.configure(1, 3, 3, 12) and restored.restore(saved), "aquafall deterministic snapshot restores")
	_expect(restored.snapshot() == saved, "aquafall restore reproduces exact snapshot")
	var encoded := JSON.stringify(saved)
	var decoded: Variant = JSON.parse_string(encoded)
	var json_restored := Aquafall.new()
	_expect(decoded is Dictionary and json_restored.configure(1, 3, 3, 12) and json_restored.restore(decoded as Dictionary), "aquafall JSON snapshot restores")
	_expect(json_restored.snapshot() == saved, "aquafall JSON restore preserves RNG state")
	source.obstacles.clear()
	source.phase = Aquafall.PHASE_WAIT_ROLL
	source.spawn_obstacles()
	restored.obstacles.clear()
	restored.phase = Aquafall.PHASE_WAIT_ROLL
	restored.spawn_obstacles()
	_expect(source.obstacles == restored.obstacles and source.rng.state == restored.rng.state, "aquafall post-restore spawn stays deterministic")
	var legacy := saved.duplicate(true)
	legacy.erase("rng_state")
	var legacy_restored := Aquafall.new()
	_expect(legacy_restored.configure(1, 3, 3, 12) and legacy_restored.restore(legacy), "aquafall legacy snapshot remains loadable")


func _test_aquafall_generation_rules() -> void:
	var level_laps := [1, 4, 7, 11, 15, 19, 23, 27]
	var expected_levels := [1, 2, 3, 4, 5, 6, 7, 8]
	var lv1_relief_patterns := 0
	for seed_value: int in range(40, 64):
		var lv1 := Aquafall.new()
		lv1.configure(1, 3, 3, seed_value)
		var lv1_metrics: Dictionary = lv1.pattern_data().get("metrics", {}) as Dictionary
		if int(lv1_metrics.get("large_log_count", -1)) == 0:
			lv1_relief_patterns += 1
	_expect(lv1_relief_patterns >= 8, "aquafall Lv1 regularly offers patterns without a large log")
	for index: int in range(level_laps.size()):
		var boss := Aquafall.new()
		_expect(boss.configure(int(level_laps[index]), 3, 3, 20260813 + index), "aquafall configures waterfall level %d" % expected_levels[index])
		_expect(boss.waterfall_level == expected_levels[index] and int(boss.level_data().get("level", 0)) == expected_levels[index], "aquafall loads Lv%d data" % expected_levels[index])
		var metrics: Dictionary = boss.pattern_data().get("metrics", {}) as Dictionary
		var config := boss.level_data()
		_expect(int(metrics.get("decision_pressure", -1)) >= int(config.get("decision_pressure_min", 0)) and int(metrics.get("decision_pressure", -1)) <= int(config.get("decision_pressure_max", 0)), "aquafall Lv%d decision pressure is in range" % expected_levels[index])
		_expect(int(metrics.get("double_danger_count", 99)) <= int(config.get("max_double_danger", 0)) and int(metrics.get("both_danger_count", 99)) < 6, "aquafall Lv%d double danger is bounded" % expected_levels[index])
		_expect(int(metrics.get("small_log_count", -1)) >= int(config.get("small_log_min", 0)) and int(metrics.get("small_log_count", -1)) <= int(config.get("small_log_max", 0)) and int(metrics.get("large_log_count", -1)) >= int(config.get("large_log_min", 0)) and int(metrics.get("large_log_count", -1)) <= int(config.get("large_log_max", 0)), "aquafall Lv%d log counts are in range" % expected_levels[index])
		_expect(not boss.current_pattern_id.is_empty() and not boss.current_pattern_class.is_empty(), "aquafall Lv%d records selected pattern" % expected_levels[index])
		for obstacle: Dictionary in boss.obstacles:
			_expect(obstacle.has("steps_until_contact") and int(obstacle.get("steps_until_contact", 0)) == int(obstacle.get("relative_height", 0)), "aquafall Lv%d logs use step distance" % expected_levels[index])

	var boss := Aquafall.new()
	_expect(boss.configure(27, 3, 3, 20260813), "aquafall generation configures at Lv8")
	var saw_large := false
	for _index: int in range(24):
		boss.obstacles.clear()
		boss.phase = Aquafall.PHASE_WAIT_ROLL
		boss.spawn_obstacles()
		var metrics: Dictionary = boss.current_pattern_metrics
		var config := boss.level_data()
		_expect(int(metrics.get("decision_pressure", -1)) >= int(config.get("decision_pressure_min", 0)) and int(metrics.get("decision_pressure", -1)) <= int(config.get("decision_pressure_max", 0)), "aquafall repeated Lv8 pressure stays in range")
		_expect(int(boss.hard_streak) <= int(config.get("max_hard_streak", 0)) and int(boss.deadly_streak) <= int(config.get("max_deadly_streak", 0)), "aquafall caps HARD/DEADLY streaks")
		var has_large := false
		for obstacle: Dictionary in boss.obstacles:
			if str(obstacle.get("type", "")) == "large_log":
				has_large = true
				saw_large = true
		_expect(has_large or int(metrics.get("large_log_count", 0)) == 0, "aquafall generated log metrics match board")
	_expect(saw_large, "aquafall generation exercises giant logs")
	var row_guard := Aquafall.new()
	row_guard.configure(12, 3, 3, 77)
	row_guard.obstacles = [
		{"type": "large_log", "lanes": [1, 2], "relative_height": 5},
		{"type": "large_log", "lanes": [3, 4], "relative_height": 5},
	]
	var blocked_candidate := {"type": "small_log", "lanes": [5], "relative_height": 5}
	_expect(bool(row_guard.call("_would_fully_block_row", blocked_candidate)), "aquafall rejects fully blocked candidate row")
	row_guard.phase = Aquafall.PHASE_WAIT_ROLL
	row_guard.spawn_obstacles()
	_expect(not bool(row_guard.call("_would_fully_block_row", row_guard.obstacles[-1])), "aquafall generated row remains traversable")


func _test_aquafall_roles_and_terminals() -> void:
	var pair := Aquafall.new()
	pair.configure(1, 3, 3, 301)
	pair.obstacles.clear()
	_take_aquafall_roll(pair, 1, 1)
	_take_aquafall_roll(pair, 1, 1)
	_take_aquafall_roll(pair, 2, 1)
	_expect(int(pair.stats.get("pair_count", 0)) == 1 and pair.water_guard_charges == 1 and pair.last_role == "PAIR" and "ガード" in pair.last_role_effect, "aquafall PAIR grants water guard")
	var straight := Aquafall.new()
	straight.configure(1, 3, 3, 302)
	straight.obstacles.clear()
	_take_aquafall_roll(straight, 1, 1)
	_take_aquafall_roll(straight, 2, 1)
	_take_aquafall_roll(straight, 3, 1)
	_expect(int(straight.stats.get("straight_count", 0)) == 1 and straight.water_run_rolls == 1 and straight.last_role == "STRAIGHT" and "無効" in straight.last_role_effect, "aquafall STRAIGHT grants water run")
	straight.obstacles = [
		{"type": "large_log", "lanes": [2], "relative_height": 1},
		{"type": "small_log", "lanes": [2], "relative_height": 1},
	]
	var straight_hp := straight.hp
	straight.request_roll(1)
	straight.choose_direction(-1)
	_expect(straight.hp == straight_hp and straight.stats.large_log_hits > 0 and straight.stats.small_log_hits > 0, "aquafall water run ignores path and landing damage")
	var triple := Aquafall.new()
	triple.configure(1, 3, 3, 303)
	triple.goal_height = 10
	triple.height = 5
	triple.obstacles = [{"type": "small_log", "lanes": [5], "relative_height": 10}]
	_take_aquafall_roll(triple, 1, 1)
	_take_aquafall_roll(triple, 1, 1)
	_take_aquafall_roll(triple, 1, 1)
	_expect(int(triple.stats.get("triple_count", 0)) == 1 and triple.height == 10 and triple.phase == Aquafall.PHASE_VICTORY and triple.last_role == "TRIPLE" and "一掃" in triple.last_role_effect, "aquafall TRIPLE clears and climbs to victory")
	var triple_relief := Aquafall.new()
	triple_relief.configure(1, 3, 3, 306)
	triple_relief.goal_height = 24
	for _roll_index: int in range(3):
		triple_relief.obstacles = [{"type": "small_log", "lanes": [5], "relative_height": 8}]
		_take_aquafall_roll(triple_relief, 1, 1)
	_expect(triple_relief.last_role == "TRIPLE" and triple_relief.obstacles.is_empty() and triple_relief.height == 5,
		"aquafall TRIPLE keeps the board visibly clear after its +2 climb")
	var victory := Aquafall.new()
	victory.configure(1, 3, 3, 304)
	victory.height = 23
	victory.obstacles.clear()
	victory.request_roll(1)
	var victory_result := victory.choose_direction(1)
	_expect(str(victory_result.get("status", "")) == "VICTORY" and victory.phase == Aquafall.PHASE_VICTORY, "aquafall reaches victory at goal")


func _test_aquafall_defeat_life_retry() -> void:
	var journey := AmazonJourneyScript.new()
	var boss := Aquafall.new()
	boss.configure(1, 1, 3, 305)
	boss.obstacles = [{"type": "large_log", "lanes": [2], "relative_height": 1}]
	boss.request_roll(1)
	var defeat := boss.choose_direction(-1)
	_expect(str(defeat.get("status", "")) == "DEFEAT" and boss.phase == Aquafall.PHASE_DEFEAT and boss.hp == 0, "aquafall ordinary defeat reaches terminal phase")
	journey.hp = boss.hp
	var life_result := journey.resolve_life_if_needed()
	_expect(bool(life_result.get("revived", false)) and journey.hp == 3 and journey.life == 2, "amazon boss defeat consumes LIFE and refills HP3")


func _take_aquafall_roll(boss: Aquafall, face: int, direction: int) -> Dictionary:
	var requested := boss.request_roll(face)
	if not bool(requested.get("ok", false)):
		return requested
	return boss.choose_direction(direction)


func _test_kyoto_course() -> void:
	var course := KyotoCourse.new()
	_expect(course.load_file(), "kyoto course loads")
	_expect(course.spaces.size() == 99, "kyoto includes 90 main and 9 shortcut spaces")
	_expect(course.branches.size() == 2, "kyoto has two meaningful shortcut junctions")
	var boss_choices := course.boss_choice().get("choices", []) as Array
	var direct_definition := boss_choices[0] as Dictionary if not boss_choices.is_empty() else {}
	_expect(str(direct_definition.get("id", "")) == "direct" and str(direct_definition.get("name", "")) == "狐火追陣",
		"kyoto keeps the save-compatible direct route id while presenting 狐火追陣")
	_expect(str(direct_definition.get("style", "")) == "chase" and str(direct_definition.get("boss_id", "")) == "fox_fire_chase",
		"kyoto direct route dispatch metadata identifies the chase boss")
	var kind_counts: Dictionary = {}
	for number: int in range(1, 91):
		var kind := str(course.space("main:%d" % number).get("kind", ""))
		kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
	for expected: Dictionary in [
		{"kind": "NORMAL", "count": 43}, {"kind": "COIN", "count": 10},
		{"kind": "REST", "count": 7}, {"kind": "RISK", "count": 9},
		{"kind": "ITEM", "count": 8}, {"kind": "EVENT", "count": 3},
		{"kind": "GOSHUIN", "count": 4}, {"kind": "BYPASS_FORK", "count": 2},
	]:
		_expect(int(kind_counts.get(str(expected.kind), 0)) == int(expected.count), "kyoto v2 %s count is %d" % [str(expected.kind), int(expected.count)])
	for item_number: int in [19, 26, 39, 50, 57, 66, 78, 84]:
		_expect(str(course.space("main:%d" % item_number).get("kind", "")) == "ITEM", "kyoto main item space %d is data-driven" % item_number)
	_expect(str(course.space("gion_shortcut:S3").get("kind", "")) == "REST" and str(course.space("arashiyama_shortcut:S5").get("kind", "")) == "RISK",
		"kyoto shortcuts expose their risk and recovery tradeoff")
	var junction := course.advance("main:31", 6)
	_expect(str(junction.get("status", "")) == "CHOICE_REQUIRED" and int(junction.get("remaining_steps", 0)) == 4, "kyoto junction preserves steps")
	var detour := course.advance("main:33", 5, "gion_shortcut:S1")
	_expect(str(detour.get("position", "")) == "main:42", "kyoto shortcut rejoins after five actual steps")
	var journey := KyotoJourneyScript.new()
	journey.current_space_id = "main:31"
	var journey_junction := journey.roll(6)
	_expect(str(journey_junction.get("status", "")) == "CHOICE_REQUIRED" and journey_junction.get("path", []).size() == 2, "kyoto journey keeps pre-choice path for animated hops")

	var auto_event := KyotoJourneyScript.new()
	auto_event.current_space_id = "main:30"
	var auto_result := auto_event.roll(1)
	_expect(str(auto_result.get("status", "")) == "AUTO_EVENT_RESOLVED" and auto_event.phase == StageJourneyBase.PHASE_READY and auto_event.coins == 2,
		"kyoto auto EVENT resolves without another modal")
	var choice_event := KyotoJourneyScript.new()
	choice_event.current_space_id = "main:46"
	var choice_arrival := choice_event.roll(1)
	var choice_result := choice_event.resolve_event("coin")
	_expect(str(choice_arrival.get("status", "")) == "EVENT_REQUIRED" and bool(choice_result.get("ok", false)) and choice_event.coins == 2,
		"kyoto keeps exactly one meaningful choice EVENT")

	var direct_boss := KyotoJourneyScript.new()
	direct_boss.current_space_id = "main:87"
	var boss_choice := direct_boss.roll(1)
	var direct_choice := direct_boss.choose_boss_route("direct")
	var approach := direct_boss.roll(1)
	var direct_ready := direct_boss.roll(1)
	_expect(str(boss_choice.get("status", "")) == "BOSS_CHOICE_REQUIRED" and bool(direct_choice.get("ok", false)) and str(direct_boss.stage_flags.get("kyoto_boss_route", "")) == "direct",
		"kyoto exact landing on main:88 requires and saves a boss choice")
	_expect(str(approach.get("status", "")) == "MOVED" and str(direct_ready.get("status", "")) == "BOSS_READY" and str(direct_ready.get("boss_route", "")) == "direct",
		"kyoto direct route persists through approach and dispatches at main:90")
	var foxfire_boss := KyotoJourneyScript.new()
	foxfire_boss.current_space_id = "main:87"
	foxfire_boss.roll(2)
	var restored_boss_choice := KyotoJourneyScript.new()
	var restored_pending := restored_boss_choice.restore(foxfire_boss.snapshot())
	var foxfire_choice := restored_boss_choice.choose_boss_route("foxfire")
	var foxfire_ready := restored_boss_choice.roll(1)
	_expect(restored_pending and bool(foxfire_choice.get("ok", false)) and str(foxfire_ready.get("status", "")) == "BOSS_READY" and str(foxfire_ready.get("boss_route", "")) == "foxfire",
		"kyoto boss-choice save resumes remaining steps and dispatches the puzzle boss")


func _test_kyoto_pass_through_goshuin() -> void:
	var journey := KyotoJourneyScript.new()
	journey.current_space_id = "main:20"
	var result := journey.roll(2)
	var passed := result.get("goshuin_passed", []) as Array
	_expect(bool(result.get("ok", false)) and bool(journey.goshuin_state().get("fushimi", false)) and passed.size() == 1 and str((passed[0] as Dictionary).get("title", "")) == "伏見稲荷", "goshuin acquired on pass-through")

	for route_case: Dictionary in [
		{"origin": "main:20", "expected": "fushimi", "after": "main:22"},
		{"origin": "main:43", "expected": "yasaka", "after": "main:45"},
		{"origin": "main:68", "expected": "kiyomizu", "after": "main:70"},
		{"origin": "main:84", "expected": "tenryuji", "after": "main:86"},
	]:
		var direct := KyotoJourneyScript.new()
		direct.current_space_id = str(route_case.get("origin", ""))
		var direct_result := direct.roll(2)
		var direct_passed := direct_result.get("goshuin_passed", []) as Array
		_expect(bool(direct_result.get("ok", false)) and direct.current_space_id == str(route_case.get("after", "")) and direct_passed.size() == 1 and str((direct_passed[0] as Dictionary).get("id", "")) == str(route_case.get("expected", "")),
			"%s goshuin checkpoint is awarded while passing on the main route" % str(route_case.get("expected", "")))


func _test_kyoto_risk_life_contract() -> void:
	var journey := KyotoJourneyScript.new()
	_assert_risk_life_contract(journey, "main:12", "main:13", "kyoto")


func _test_kyoto_luck_shift_and_restore() -> void:
	var boss := WhiteFox.new()
	boss.configure({}, 6, true, 987)
	boss.phase = WhiteFox.PHASE_ACTION
	boss.dice = [3, 2, 1]
	var shifted := boss.use_luck_shift(0, 1)
	_expect(bool(shifted.get("ok", false)) and boss.dice[0] == 4 and not boss.tenryuji_shift_available, "otowa luck shift applies once")
	boss.prayer_count = 1
	boss.prayer_used_this_turn = true
	var restored := WhiteFox.new()
	restored.configure({}, 0, false, 11)
	_expect(restored.restore(boss.snapshot()) and restored.prayer_used_this_turn, "white fox save restores per-turn prayer usage")


func _test_white_fox_rules() -> void:
	var boss := WhiteFox.new()
	var all_goshuin := {"fushimi": true, "yasaka": true, "kiyomizu": true, "tenryuji": true}
	_expect(boss.configure(all_goshuin, 9, false, 4321), "white fox configures")
	_expect(boss.phase == WhiteFox.PHASE_PRE_BONUS and boss.attack_start_turn == 4 and boss.prayer_count == 1 and boss.mangan_guard_available, "goshuin boss bonuses apply")
	boss.apply_fushimi_preplacement("S0")
	_expect(str(boss.seals[0].state) == "NORMAL", "fushimi preplacement")
	boss.phase = WhiteFox.PHASE_ACTION
	boss.dice = [6, 5, 5]
	_expect(boss.available_targets(0).size() == 7, "six is wild for empty seals")
	boss.seals[1]["state"] = WhiteFox.STATE_CRACKED
	boss.dice = [2, 5, 5]
	_expect("S1" in boss.available_targets(0), "matching die repairs cracked seal")
	boss.dice = [4, 4, 4]
	for seal: Dictionary in boss.seals:
		if int(seal.required) == 4:
			seal.state = WhiteFox.STATE_NORMAL
	_expect(boss.can_offer(0), "offer only when die has no target")
	boss.offering_count = 1
	boss.commit_die(0)
	_expect(boss.prayer_count == 2, "two offerings convert to prayer")


func _test_white_fox_defeat_life_boundaries() -> void:
	# White Fox owns only the seal-board result. The journey host applies the
	# boss's two-heart defeat penalty, then delegates zero-heart handling to the
	# same HP3/LIFE contract used by RISK spaces.
	var full_health := KyotoJourneyScript.new()
	full_health.hp = 3
	full_health.life = 3
	full_health.hp = maxi(full_health.hp - 2, 0)
	var full_health_result := full_health.resolve_life_if_needed()
	_expect(full_health.hp == 1 and full_health.life == 3, "white fox defeat at HP3 leaves HP1 without spending LIFE")
	_expect(not bool(full_health_result.get("revived", false)) and not bool(full_health_result.get("run_over", false)), "white fox nonfatal defeat does not revive or end the run")

	var last_heart := KyotoJourneyScript.new()
	last_heart.hp = 1
	last_heart.life = 3
	last_heart.hp = maxi(last_heart.hp - 2, 0)
	var revive_result := last_heart.resolve_life_if_needed()
	_expect(last_heart.hp == 3 and last_heart.life == 2, "white fox defeat at HP1 spends one LIFE and refills HP3")
	_expect(bool(revive_result.get("revived", false)) and not bool(revive_result.get("run_over", false)), "white fox fatal defeat reports revival while LIFE remains")

	var no_life := KyotoJourneyScript.new()
	no_life.hp = 1
	no_life.life = 0
	no_life.hp = maxi(no_life.hp - 2, 0)
	var run_over_result := no_life.resolve_life_if_needed()
	_expect(no_life.hp == 0 and no_life.life == 0 and no_life.phase == StageJourneyBase.PHASE_RUN_OVER, "white fox defeat at HP1/LIFE0 ends the run")
	_expect(bool(run_over_result.get("run_over", false)) and not bool(run_over_result.get("revived", false)), "white fox LIFE0 defeat reports run over without refilling hearts")


func _assert_risk_life_contract(journey: Variant, risk_origin: String, risk_space: String, label: String) -> void:
	_expect(journey.max_hp == 3 and journey.hp == 3 and journey.life == 3, "%s starts with HP3 and LIFE3" % label)
	var expected_hp := [2, 1, 3, 2]
	var expected_life := [3, 3, 2, 2]
	for landing: int in range(expected_hp.size()):
		journey.current_space_id = risk_origin
		journey.phase = StageJourneyBase.PHASE_READY
		var result: Dictionary = journey.roll(1)
		_expect(bool(result.get("ok", false)) and journey.current_space_id == risk_space, "%s RISK landing %d resolves" % [label, landing + 1])
		_expect(journey.hp == expected_hp[landing] and journey.life == expected_life[landing], "%s RISK landing %d keeps HP/LIFE contract" % [label, landing + 1])
		if landing == 2:
			_expect(bool(result.get("revived", false)), "%s third RISK consumes one life and refills HP3" % label)

	var legacy_save: Dictionary = journey.snapshot()
	legacy_save["max_hp"] = 6
	legacy_save["hp"] = 6
	_expect(journey.restore(legacy_save), "%s legacy HP6 save restores" % label)
	_expect(journey.max_hp == 3 and journey.hp == 3, "%s legacy HP6 save clamps to HP3" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
