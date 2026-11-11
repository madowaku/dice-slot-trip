extends SceneTree

## Casino renewal hub: prize shelf, prize counter, featured games, and layout
## at the 720x1280 design size and the taller 360x800 phone canvas.

const Bank = preload("res://scripts/game/casino_bank.gd")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const ChohanScript = preload("res://scripts/app/chohan_screen.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")

var failures := 0
var assertions := 0
var test_save_path := ""


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)


func _run() -> void:
	test_save_path = "user://dice_slot_trip_casino_renewal_hub_%d.json" % OS.get_process_id()
	Bank.set_test_save_path(test_save_path)
	HubScript.suppress_audio_for_tests = true
	ChohanScript.suppress_audio_for_tests = true
	ChohanScript.instant_for_tests = true
	await _test_prize_shelf()
	await _test_prize_counter()
	await _test_facilities()
	await _test_layout(Vector2(720, 1280))
	await _test_layout(Vector2(720, 1600))
	HubScript.suppress_audio_for_tests = false
	ChohanScript.suppress_audio_for_tests = false
	ChohanScript.instant_for_tests = false
	_remove_save()
	Bank.clear_test_save_path()
	print("Casino renewal hub tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)


func _remove_save() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(test_save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path + suffix))


func _fresh_bank(chips: int, owned: Array = []) -> void:
	_remove_save()
	var data := Bank.default_data()
	data["chips"] = chips
	data["owned_cards"] = owned
	_expect(Bank.save_data(data), "fixture bank saves with %d chips" % chips)


func _open_hub() -> CasinoHubScreen:
	var hub := HUB_SCENE.instantiate() as CasinoHubScreen
	root.add_child(hub)
	await process_frame
	await process_frame
	return hub


func _test_prize_shelf() -> void:
	_fresh_bank(38)
	var hub := await _open_hub()
	_expect(hub.prize_shelf != null and hub.prize_kicker_label.text == "ねらっている景品", "the shelf names what the player is saving for")
	_expect("ウサギ" in hub.prize_name_label.text and hub.prize_remaining_label.text == "あと 12 チップ", "with 38 chips the first 50-chip prize needs 12 more")
	_expect(is_equal_approx(hub.prize_progress.value, 38.0) and is_equal_approx(hub.prize_progress.max_value, 50.0), "the progress bar shows 38 of 50")
	_expect(hub.prize_picture.texture != null, "the target prize has a picture")
	var shelf_index := hub.prize_shelf.get_index()
	var first_game := hub.facility_buttons.get("chohan") as Control
	_expect(hub.prize_shelf.get_parent() == first_game.get_parent() and shelf_index < first_game.get_index(), "the prize shelf sits above every game")
	hub.queue_free()
	await process_frame

	_fresh_bank(50)
	hub = await _open_hub()
	_expect(hub.prize_remaining_label.text == "交換できます！" and "交換" in hub.prize_counter_button.text, "an affordable target invites the trade")
	hub.queue_free()
	await process_frame

	var all_ids: Array = []
	for card: Dictionary in (JSON.parse_string(FileAccess.get_file_as_string("res://data/casino/prize_cards.json")) as Dictionary).get("cards", []):
		all_ids.append(str(card.get("id", "")))
	_fresh_bank(10, all_ids)
	hub = await _open_hub()
	_expect(hub.target_prize().is_empty() and hub.prize_name_label.text == "すべて交換済み", "with every prize owned the shelf says so")
	hub.queue_free()
	await process_frame


func _test_prize_counter() -> void:
	_fresh_bank(70)
	var hub := await _open_hub()
	_expect(not hub.is_prize_counter_open(), "the prize counter starts closed")
	hub.prize_counter_button.pressed.emit()
	await process_frame
	_expect(hub.is_prize_counter_open() and hub.find_children("PrizeRow_*", "PanelContainer", true, false).size() == 6, "the counter lists all six prizes")
	_expect(hub.find_children("*", "ScrollContainer", true, false).is_empty(), "the counter needs no scrolling")
	var aim_duck := hub.find_child("AimButton_dice_racer_duck", true, false) as Button
	_expect(aim_duck != null and not aim_duck.disabled, "another prize can be chosen as the target")
	aim_duck.pressed.emit()
	await process_frame
	_expect(Bank.target_prize_id() == "dice_racer_duck" and "アヒル" in hub.prize_name_label.text, "choosing a target updates the shelf and is saved")
	var buy_duck := hub.find_child("BuyButton_dice_racer_duck", true, false) as Button
	_expect(buy_duck != null and not buy_duck.disabled and "50" in buy_duck.text, "an affordable prize can be traded for its price")
	buy_duck.pressed.emit()
	await process_frame
	_expect(Bank.balance() == 20 and "dice_racer_duck" in Bank.owned_cards(), "trading spends the chips and adds the prize")
	_expect(hub.find_child("BuyButton_dice_racer_duck", true, false) == null, "an owned prize cannot be bought twice")
	_expect(Bank.target_prize_id() == "" and "ウサギ" in hub.prize_name_label.text and hub.prize_remaining_label.text == "あと 30 チップ", "after the trade the shelf moves to the next prize")
	var buy_rabbit := hub.find_child("BuyButton_dice_racer_rabbit", true, false) as Button
	_expect(buy_rabbit != null and buy_rabbit.disabled, "a prize the player cannot afford is not purchasable")
	(hub.find_child("PrizeCounterCloseButton", true, false) as Button).pressed.emit()
	await process_frame
	_expect(not hub.is_prize_counter_open() and "20" in hub.chip_label.text, "closing the counter returns to the hub with the new balance")
	hub.queue_free()
	await process_frame


func _test_facilities() -> void:
	_fresh_bank(100)
	var hub := await _open_hub()
	_expect(hub.MAIN_FACILITY_IDS == ["chohan", "dice_race", "dice_poker"], "the featured games are 丁半, DICE RACE and DICE POKER")
	for id: String in hub.MAIN_FACILITY_IDS:
		var title := hub.facility_title_labels.get(id) as Label
		var tagline := hub.facility_tagline_labels.get(id) as Label
		_expect(title != null and not title.text.is_empty() and tagline != null and not tagline.text.is_empty(), "%s shows a name and a one-line pitch" % id)
		_expect(tagline != null and tagline.text.length() <= 14, "%s pitch is a single short line" % id)
		var button := hub.facility_buttons.get(id) as Button
		var has_art := false
		for node: Node in button.find_children("*", "", true, false):
			if node is TextureRect or node.get_script() == hub.DiceGlyphScript:
				has_art = true
		_expect(has_art, "%s shows a small picture of how it plays" % id)
	_expect((hub.facility_tagline_labels.get("chohan") as Label).text == "丁か半か、当てるだけ", "丁半 is pitched in one phrase")
	for id: String in hub.OTHER_FACILITY_IDS:
		_expect(hub.facility_buttons.has(id) and bool(hub.facility_availability.get(id, false)), "%s stays reachable until phase 3" % id)
	var play_texts: Array[String] = []
	for id: Variant in hub.facility_buttons.keys():
		play_texts.append((hub.facility_buttons[id] as Button).text)
	_expect(not play_texts.has("PLAY") and play_texts.count("") == 3, "no entry is a bare PLAY button")
	(hub.facility_buttons.get("chohan") as Button).pressed.emit()
	await process_frame
	await process_frame
	var host := hub.facility_hosts.get("chohan") as Control
	_expect(hub.active_facility_id == "chohan" and not hub.hub_root.visible and host.get_child_count() == 1, "丁半 opens from the hub")
	var screen := host.get_child(0)
	screen.shell.close_guide()
	screen.cho_button.pressed.emit()
	var dice: Array[int] = [4, 6]
	screen.queued_dice = dice
	screen.shell.primary_button.pressed.emit()
	await process_frame
	screen.shell.back_button.pressed.emit()
	await process_frame
	await process_frame
	_expect(hub.hub_root.visible and hub.active_facility_id.is_empty() and host.get_child_count() == 0, "returning from 丁半 restores the hub")
	_expect("120" in hub.chip_label.text and hub.prize_remaining_label.text == "交換できます！", "chips won at 丁半 show on the hub and its shelf")
	hub.queue_free()
	await process_frame


func _test_layout(design_size: Vector2) -> void:
	_fresh_bank(38)
	var frame := Control.new()
	frame.size = design_size
	root.add_child(frame)
	var hub := HUB_SCENE.instantiate() as CasinoHubScreen
	frame.add_child(hub)
	hub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	var label := "%dx%d" % [int(design_size.x), int(design_size.y)]
	var bounds := Rect2(frame.global_position, design_size).grow(1.0)
	var column := hub.find_child("HubColumn", true, false) as Control
	_expect(column != null and bounds.encloses(column.get_global_rect()), "%s hub content fits without scrolling" % label)
	_expect(bounds.encloses(hub.prize_shelf.get_global_rect()), "%s prize shelf is on-screen" % label)
	for id: Variant in hub.facility_buttons.keys():
		_expect(bounds.encloses((hub.facility_buttons[id] as Control).get_global_rect()), "%s %s entry is on-screen" % [label, str(id)])
	_expect(bounds.encloses((hub.find_child("BackToTripButton", true, false) as Control).get_global_rect()), "%s trip-return button is on-screen" % label)
	hub.open_prize_counter()
	await process_frame
	await process_frame
	var close := hub.find_child("PrizeCounterCloseButton", true, false) as Control
	_expect(close != null and bounds.encloses(close.get_global_rect()), "%s prize counter fits without scrolling" % label)
	frame.queue_free()
	await process_frame
