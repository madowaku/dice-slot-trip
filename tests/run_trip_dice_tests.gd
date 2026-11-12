extends SceneTree

## Trip dice: catalog rules, the spinning-face order, per-lap uses, buying and
## equipping at the prize counter, and the Kyoto roll hook (with and without a
## trip die). All saves go to isolated test paths.

const TripDice = preload("res://scripts/game/trip_dice.gd")
const Bank = preload("res://scripts/game/casino_bank.gd")
const DicePresentation = preload("res://scripts/game/dice_presentation_3d.gd")
const JourneySaves = preload("res://scripts/game/journey_save_manager.gd")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const JOURNEY_SCENE: PackedScene = preload("res://scenes/app/JourneyStageScreen.tscn")

var failures := 0
var assertions := 0
var bank_path := ""
var journey_dir := ""


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)


func _run() -> void:
	bank_path = "user://dice_slot_trip_trip_dice_tests_%d.json" % OS.get_process_id()
	journey_dir = "user://trip_dice_tests_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(journey_dir))
	Bank.set_test_save_path(bank_path)
	JourneySaves._test_save_directory = journey_dir
	HubScript.suppress_audio_for_tests = true
	_test_catalog()
	_test_carousel()
	_test_uses_per_lap()
	_test_bank()
	await _test_prize_counter()
	await _test_kyoto_without_trip_die()
	await _test_kyoto_with_trip_die()
	HubScript.suppress_audio_for_tests = false
	_cleanup()
	print("Trip dice tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)


func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(bank_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bank_path + suffix))
	var dir := DirAccess.open(journey_dir)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(journey_dir))
	Bank.clear_test_save_path()
	JourneySaves._test_save_directory = ""
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")


func _fresh_bank(chips: int, owned: Array = [], equipped: String = "") -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(bank_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bank_path + suffix))
	var data := Bank.default_data()
	data["chips"] = chips
	data[Bank.OWNED_TRIP_DICE_KEY] = owned
	data[Bank.EQUIPPED_TRIP_DIE_KEY] = equipped
	_expect(Bank.save_data(data), "fixture bank saves")


func _test_catalog() -> void:
	var dice := TripDice.catalog()
	_expect(dice.size() == 4, "four trip dice are on offer")
	var names: Array[String] = []
	for die: Dictionary in dice:
		names.append(str(die.get("name", "")))
		var faces: Array[int] = die.get("faces", [])
		_expect(faces.size() == 6, "%s has six faces" % die.get("name"))
		_expect(int(die.get("price", 0)) >= 80 and int(die.get("price", 0)) <= 150, "%s is priced in the 80-150 band" % die.get("name"))
		_expect(not str(die.get("gain", "")).is_empty() and not str(die.get("cost_text", "")).is_empty(), "%s states what it gives and what it costs" % die.get("name"))
		# Never strictly better than the normal die: every trip die gives up
		# at least one distance the normal die can roll.
		var missing := 0
		for value: int in range(1, 7):
			if value not in faces:
				missing += 1
		_expect(missing >= 2, "%s cannot reach every distance" % die.get("name"))
	_expect(names == ["刻みダイス", "偶数ダイス", "一か八かダイス", "寄り道ダイス"], "the four authored dice keep their order")
	_expect(TripDice.find("trip_die_gamble").get("faces", []) == [1, 1, 1, 6, 6, 6], "一か八か rolls only 1 or 6")
	_expect(TripDice.find("nope").is_empty(), "unknown ids find nothing")
	_expect(TripDice.uses_per_lap() == 3, "three uses per lap")


func _test_carousel() -> void:
	for die: Dictionary in TripDice.catalog():
		var faces: Array[int] = die.get("faces", [])
		var order := TripDice.carousel_order(faces)
		var sorted_order := order.duplicate()
		sorted_order.sort()
		var sorted_faces := faces.duplicate()
		sorted_faces.sort()
		_expect(sorted_order == sorted_faces, "%s spin shows exactly its six faces" % die.get("name"))
		var repeats := false
		for index: int in range(order.size()):
			if order[index] == order[(index + 1) % order.size()]:
				repeats = true
		_expect(not repeats, "%s never shows the same value twice in a row" % die.get("name"))
	var gamble: Array[int] = [1, 1, 1, 6, 6, 6]
	_expect(TripDice.carousel_order(gamble) == [1, 6, 1, 6, 1, 6], "一か八か alternates 1 and 6")
	var steady: Array[int] = [1, 1, 2, 2, 3, 3]
	_expect(TripDice.carousel_order(steady) == [1, 2, 3, 1, 2, 3], "刻み cycles 1, 2, 3")
	var seen: Dictionary = {}
	for step: int in range(240):
		var elapsed := float(step) * 0.013
		var face := TripDice.face_for_elapsed(gamble, elapsed)
		seen[face] = true
		var normal := DicePresentation.rolling_face_for_elapsed(elapsed)
		_expect(face == TripDice.carousel_order(gamble)[normal - 1], "trip face follows the normal spin clock at %.3fs" % elapsed) if step % 40 == 0 else null
	_expect(seen.keys().size() == 2 and seen.has(1) and seen.has(6), "a 一か八か spin only ever shows 1 or 6")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rolled: Dictionary = {}
	for _i: int in range(300):
		rolled[TripDice.roll(gamble, rng)] = true
	_expect(rolled.keys().size() == 2, "a seeded random trip roll stays on the die's faces")


func _test_uses_per_lap() -> void:
	var flags: Dictionary = {}
	_expect(TripDice.uses_left(flags, 1) == 3 and not TripDice.is_armed(flags, 1), "a lap starts with three uses, unarmed")
	TripDice.set_armed(flags, true)
	_expect(TripDice.is_armed(flags, 1), "the trip die can be armed")
	for use: int in range(3):
		_expect(TripDice.consume_use(flags, 1), "use %d is spent" % (use + 1))
	_expect(TripDice.uses_left(flags, 1) == 0 and not TripDice.consume_use(flags, 1), "a fourth use in the same lap is refused")
	_expect(not TripDice.is_armed(flags, 1), "spending the last use disarms the trip die")
	_expect(TripDice.uses_left(flags, 2) == 3, "the next lap gives three uses again")
	_expect(TripDice.consume_use(flags, 2) and TripDice.uses_left(flags, 2) == 2, "uses are counted per lap")


func _test_bank() -> void:
	_fresh_bank(300)
	_expect(Bank.owned_trip_dice().is_empty() and Bank.equipped_trip_die() == "", "a new bank owns and equips no trip die")
	_expect(not Bank.equip_trip_die("trip_die_even"), "an unowned die cannot be equipped")
	_expect(Bank.buy_trip_die("trip_die_even", 120) and Bank.balance() == 180, "buying spends the price")
	_expect(Bank.owned_trip_dice() == ["trip_die_even"] and Bank.equipped_trip_die() == "trip_die_even", "the first die bought is equipped at once")
	_expect(not Bank.buy_trip_die("trip_die_even", 120) and Bank.balance() == 180, "a die cannot be bought twice")
	_expect(Bank.buy_trip_die("trip_die_gamble", 100) and Bank.equipped_trip_die() == "trip_die_even", "a second purchase keeps the equipped die")
	_expect(not Bank.buy_trip_die("trip_die_steady", 81), "a die the player cannot afford is refused")
	_expect(Bank.equip_trip_die("trip_die_gamble") and Bank.equipped_trip_die() == "trip_die_gamble", "an owned die can be equipped")
	_expect(Bank.equip_trip_die("") and Bank.equipped_trip_die() == "", "the trip die can be put away")

	# A v2 save has neither trip dice field.
	for suffix: String in ["", ".bak"]:
		if FileAccess.file_exists(bank_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bank_path + suffix))
	var v2 := {"version": 2, "chips": 64, "owned_cards": ["dice_racer_duck"], "conversion_keys": [], "active_games": {}, "casino_settlements": {}, "casino_settlement_order": []}
	var file := FileAccess.open(bank_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(v2))
	file.close()
	var loaded := Bank.load_data()
	_expect(int(loaded.get("version", 0)) == 3 and int(loaded.get("chips", 0)) == 64 and loaded.get("owned_cards", []) == ["dice_racer_duck"], "a v2 save keeps chips and prizes")
	_expect(loaded.get(Bank.OWNED_TRIP_DICE_KEY, null) == [] and str(loaded.get(Bank.EQUIPPED_TRIP_DIE_KEY, "x")) == "", "a v2 save starts with no trip dice")
	var odd := loaded.duplicate(true)
	odd[Bank.OWNED_TRIP_DICE_KEY] = ["trip_die_steady", "trip_die_steady", ""]
	odd[Bank.EQUIPPED_TRIP_DIE_KEY] = "trip_die_even"
	_expect(Bank.save_data(odd) and Bank.owned_trip_dice() == ["trip_die_steady"] and Bank.equipped_trip_die() == "", "duplicates are dropped and an unowned equipped die is cleared")


func _test_prize_counter() -> void:
	_fresh_bank(38)
	var hub := HUB_SCENE.instantiate() as CasinoHubScreen
	root.add_child(hub)
	await process_frame
	await process_frame
	_expect(hub.target_prize().get("id") == "trip_die_steady" and "刻み" in hub.prize_name_label.text and hub.prize_remaining_label.text == "あと 42 チップ", "the shelf aims at the first trip die by default")
	_expect(hub.find_child("PrizeGlyph", true, false) != null, "a trip die target is pictured as its dice")
	hub.open_prize_counter()
	await process_frame
	_expect(hub.prize_counter_tab == "trip_die" and hub.find_children("PrizeRow_trip_die_*", "PanelContainer", true, false).size() == 4, "the counter opens on the four trip dice")
	_expect(hub.find_child("TripDieNote", true, false) != null, "the counter says where and how often a trip die works")
	(hub.find_child("PrizeTab_racer", true, false) as Button).pressed.emit()
	await process_frame
	_expect(hub.find_children("PrizeRow_dice_racer_*", "PanelContainer", true, false).size() == 6 and hub.find_children("PrizeRow_trip_die_*", "PanelContainer", true, false).is_empty(), "the racer tab lists the six racers")
	(hub.find_child("PrizeTab_trip_die", true, false) as Button).pressed.emit()
	await process_frame
	(hub.find_child("AimButton_trip_die_gamble", true, false) as Button).pressed.emit()
	await process_frame
	_expect(Bank.target_prize_id() == "trip_die_gamble" and "一か八か" in hub.prize_name_label.text and hub.prize_remaining_label.text == "あと 62 チップ", "aiming at another die updates the shelf")
	_expect((hub.find_child("BuyButton_trip_die_gamble", true, false) as Button).disabled, "an unaffordable die cannot be bought")
	hub.close_prize_counter()
	hub.queue_free()
	await process_frame

	_fresh_bank(250)
	hub = HUB_SCENE.instantiate() as CasinoHubScreen
	root.add_child(hub)
	await process_frame
	hub.open_prize_counter()
	await process_frame
	(hub.find_child("BuyButton_trip_die_detour", true, false) as Button).pressed.emit()
	await process_frame
	_expect(Bank.balance() == 170 and "trip_die_detour" in Bank.owned_trip_dice() and Bank.equipped_trip_die() == "trip_die_detour", "buying at the counter spends chips and equips the first die")
	var equipped_button := hub.find_child("EquipButton_trip_die_detour", true, false) as Button
	_expect(equipped_button != null and equipped_button.text == "装備中", "the equipped die says so")
	(hub.find_child("BuyButton_trip_die_steady", true, false) as Button).pressed.emit()
	await process_frame
	(hub.find_child("EquipButton_trip_die_steady", true, false) as Button).pressed.emit()
	await process_frame
	_expect(Bank.equipped_trip_die() == "trip_die_steady" and (hub.find_child("EquipButton_trip_die_detour", true, false) as Button).text == "装備する", "equipping another owned die switches it")
	(hub.find_child("EquipButton_trip_die_steady", true, false) as Button).pressed.emit()
	await process_frame
	_expect(Bank.equipped_trip_die() == "", "pressing 「装備中」 puts the die away")
	_expect(hub.find_children("*", "ScrollContainer", true, false).is_empty(), "the counter needs no scrolling")
	hub.queue_free()
	await process_frame


func _open_kyoto() -> JourneyStageScreen:
	var screen := JOURNEY_SCENE.instantiate() as JourneyStageScreen
	screen.configure_start_context(StageCatalog.STAGE_KYOTO)
	screen.show_stage_intro = false
	root.add_child(screen)
	for _i: int in range(8):
		await process_frame
	screen.call("_close_overview_map")
	screen.call("_close_modal")
	for _i: int in range(4):
		await process_frame
	return screen


func _roll_with_face_at(screen: JourneyStageScreen, elapsed: float) -> int:
	screen.call("_roll_map")
	screen.set("map_roll_elapsed", elapsed)
	var face := int(screen.call("_map_roll_face_for_elapsed", elapsed))
	screen.set("map_roll_face", face)
	screen.call("_roll_map")
	return face


func _wait_until_ready(screen: JourneyStageScreen) -> void:
	for _i: int in range(600):
		if not bool(screen.get("map_movement_active")) and not bool(screen.get("roll_animation_active")):
			break
		await create_timer(0.02).timeout
	screen.call("_close_modal")
	var journey := screen.get("journey") as StageJourneyBase
	if journey != null and journey.phase == StageJourneyBase.PHASE_BRANCH and not journey.pending_choices.is_empty():
		screen.call("_choose_branch", 0) if screen.has_method("_choose_branch") else null
	await process_frame


func _test_kyoto_without_trip_die() -> void:
	_fresh_bank(30)
	var screen := await _open_kyoto()
	var journey := screen.get("journey") as StageJourneyBase
	_expect(journey != null and journey.can_roll(), "Kyoto starts ready to roll")
	_expect(screen.trip_die_toggle == null or not screen.trip_die_toggle.visible, "without a trip die there is no toggle")
	_expect(not screen.trip_die_in_use(), "without a trip die the normal die is used")
	var same := true
	for step: int in range(60):
		var elapsed := float(step) * 0.031
		same = same and int(screen.call("_map_roll_face_for_elapsed", elapsed)) == DicePresentation.rolling_face_for_elapsed(elapsed)
	_expect(same, "without a trip die the spin is the normal 1-6 die")
	var before := journey.roll_count
	var face := _roll_with_face_at(screen, 0.12 * 4.0)
	_expect(face == 5 and journey.roll_count == before + 1 and int(journey.last_result.get("face", 0)) == 5, "a normal roll still takes the face under the tap")
	await _wait_until_ready(screen)
	_expect(journey.stage_flags.get("trip_die_used", 0) == 0, "a normal roll spends no trip die use")
	screen.queue_free()
	await process_frame


func _test_kyoto_with_trip_die() -> void:
	_fresh_bank(30, ["trip_die_gamble"], "trip_die_gamble")
	# Start a fresh Kyoto run in the isolated save directory.
	var dir := DirAccess.open(journey_dir)
	if dir != null:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
	var screen := await _open_kyoto()
	var journey := screen.get("journey") as StageJourneyBase
	await process_frame
	_expect(screen.trip_die_toggle != null and screen.trip_die_toggle.visible, "an equipped trip die shows its toggle in Kyoto")
	_expect("一か八か" in screen.trip_die_toggle.text and "あと3回" in screen.trip_die_toggle.text, "the toggle names the die and the uses left this lap")
	_expect(not screen.trip_die_in_use() and not screen.trip_die_toggle.button_pressed, "the trip die starts switched off")
	_expect(screen.trip_die_toggle.get_global_rect().size.x >= 96.0 and screen.trip_die_toggle.get_global_rect().size.y >= 96.0, "the toggle is a full-size touch target")
	screen.trip_die_toggle.toggled.emit(true)
	_expect(screen.trip_die_in_use() and screen.trip_die_toggle.button_pressed, "the toggle arms the trip die before the roll")
	var tinted := screen.get("map_dice").cube_materials[0].albedo_color as Color
	_expect(not tinted.is_equal_approx(Color("#fff6e4")), "an armed trip die tints the map die")
	var only_one_six := true
	for step: int in range(60):
		var face_now := int(screen.call("_map_roll_face_for_elapsed", float(step) * 0.031))
		only_one_six = only_one_six and face_now in [1, 6]
	_expect(only_one_six, "while armed the spin shows only 1 and 6")

	# Stop on the second carousel slot: the normal die would show 2, the trip die shows 6.
	var face := _roll_with_face_at(screen, 0.12 * 1.0)
	_expect(face == 6 and int(journey.last_result.get("face", 0)) == 6, "the tapped trip face goes to roll(face)")
	_expect(TripDice.uses_left(journey.stage_flags, journey.lap) == 2, "a trip roll spends one use")
	await _wait_until_ready(screen)
	_expect("あと2回" in screen.trip_die_toggle.text, "the toggle counts down")

	screen.trip_die_toggle.toggled.emit(false)
	_expect(not screen.trip_die_in_use(), "the trip die can be switched off before a roll")
	var normal_before := TripDice.uses_left(journey.stage_flags, journey.lap)
	face = _roll_with_face_at(screen, 0.12 * 2.0)
	_expect(face == 3 and TripDice.uses_left(journey.stage_flags, journey.lap) == normal_before, "a switched-off roll uses the normal die and spends nothing")
	await _wait_until_ready(screen)

	for _use: int in range(2):
		screen.trip_die_toggle.toggled.emit(true)
		_roll_with_face_at(screen, 0.0)
		await _wait_until_ready(screen)
	_expect(TripDice.uses_left(journey.stage_flags, journey.lap) == 0 and not screen.trip_die_in_use(), "after three uses this lap the trip die is spent")
	screen.trip_die_toggle.toggled.emit(true)
	_expect(not screen.trip_die_in_use() and screen.trip_die_toggle.disabled and "使い切った" in screen.trip_die_toggle.text, "a spent trip die cannot be armed again this lap")
	var tint_after := screen.get("map_dice").cube_materials[0].albedo_color as Color
	_expect(tint_after.is_equal_approx(Color("#fff6e4")), "the map die returns to ivory when the trip die is off")
	journey.start_next_lap()
	await process_frame
	_expect(TripDice.uses_left(journey.stage_flags, journey.lap) == 3 and "あと3回" in screen.trip_die_toggle.text, "the next lap brings three uses back")
	var saved := journey.snapshot()
	_expect((saved.get("stage_flags", {}) as Dictionary).has("trip_die_lap"), "trip die use is saved with the journey")
	screen.queue_free()
	await process_frame
