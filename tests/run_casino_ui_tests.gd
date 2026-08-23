extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const RACE_SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const CAIRO_SCENE: PackedScene = preload("res://scenes/casino/CairoCasinoPlayScreen.tscn")

var failures := 0
var assertions := 0

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	var bgm := root.get_node("BgmManager")
	if FileAccess.file_exists(CasinoBankScript.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	CasinoBankScript.add_chips(100)

	var hub := HUB_SCENE.instantiate()
	root.add_child(hub)
	await process_frame
	_expect(hub is CasinoHubScreen, "Casino Hub scene instantiates its screen script")
	_expect(bgm.current_track() == &"lasvegas_main", "Casino Hub starts the Las Vegas main-map BGM")
	_expect(hub.chip_label != null and "100" in hub.chip_label.text, "Casino Hub shows persistent chip balance")
	_expect(hub.card_data.size() == 6, "Prize Counter loads six initial racer cards")
	var prize_names: Array[String] = []
	for card: Dictionary in hub.card_data:
		prize_names.append(str(card.get("name", "")))
	_expect("ウサギ" in prize_names and "ワニ" not in prize_names, "Prize Counter exposes rabbit and retires crocodile")
	hub.call("_open_dice_race")
	await process_frame
	_expect(bgm.current_track() == &"dice_race", "opening Dice Race from Casino Hub switches to its race BGM")
	hub.call("_close_dice_race")
	await process_frame
	_expect(bgm.current_track() == &"lasvegas_main", "returning from Dice Race restores the Casino Hub BGM")
	hub.queue_free()
	await process_frame

	var race := RACE_SCENE.instantiate()
	root.add_child(race)
	await process_frame
	_expect(race is DiceRaceScreen, "Dice Race scene instantiates its screen script")
	_expect(bgm.current_track() == &"dice_race", "Dice Race starts its dedicated race BGM")
	_expect(race.orientations.size() == 24, "Dice Race UI receives all 24 physical orientations")
	_expect(race.roll_button != null and race.start_button != null, "Dice Race exposes start and roll controls")
	_expect(race.racer_nodes.size() == 6, "Dice Race creates six racer markers")
	_expect(race.racer_nodes.has("rabbit") and not race.racer_nodes.has("crocodile"), "Dice Race UI uses the final rabbit lineup")
	_expect(race.assignment_cards.size() == 6 and race.die_face_label != null, "Dice Race builds the six-card die assignment console")
	_expect(race.ranking_cards.size() == 3, "Dice Race builds the compact top-three ranking strip")
	_expect(race.track_view != null and race.minimap != null, "Dice Race builds a vertical race viewport and full-course minimap")
	_expect(race.cashout_overlay != null and not race.cashout_overlay.visible, "Dice Race keeps the CASH OUT decision in a hidden modal overlay until offered")
	_expect(race.track_view.logical_y_for_test(0) > race.track_view.logical_y_for_test(24), "vertical course places START below GOAL")
	_expect(race.track_view.gimmick_markers.keys().all(func(space: int) -> bool: return space in [5, 10, 15, 20]) and race.track_view.gimmick_markers.size() == 4, "vertical course exposes all four fixed gimmick spaces")
	_expect(race.setup_view.visible and not race.race_view.visible, "Dice Race opens in the pre-race betting view")
	race.call("_start_race")
	await process_frame
	_expect(not race.setup_view.visible and race.race_view.visible, "RACE START replaces setup controls with the active race view")
	var camera_positions := {}
	for racer_id: String in RaceScript.RACERS:
		camera_positions[racer_id] = 2
	camera_positions[race.selected_racer] = 13
	race.track_view.set_race_state(camera_positions, race.selected_racer, true)
	await create_timer(0.45).timeout
	_expect(race.track_view.camera_basis_racer == race.selected_racer and race.track_view.camera_section_for_test() == 2, "course camera follows the BET racer into the 12-18 section")
	race.call("_show_bet_select")
	_expect(race.setup_view.visible and not race.race_view.visible, "returning to setup restores the betting view")
	CasinoBankScript.add_chips(race.selected_bet)
	race.queue_free()
	await process_frame

	var cairo := CAIRO_SCENE.instantiate()
	root.add_child(cairo)
	await process_frame
	_expect(cairo is V06PlayScreen, "casino-aware Cairo scene preserves the V06PlayScreen contract")
	_expect(cairo.has_method("_bank_cairo_completed_lap"), "casino-aware Cairo scene exposes the lap banking hook")
	_expect(cairo.session_for_test() != null, "casino-aware Cairo scene initializes the established V06 session")
	cairo.queue_free()
	await process_frame

	var main_scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.call("show_stage_select")
	await process_frame
	var vegas := main.find_child("city_lasvegas", true, false) as Button
	_expect(vegas != null, "stage select places Las Vegas inside the world-map postcard layer")
	_expect(main.find_child("CasinoEntryButton", true, false) == null, "stage select no longer uses the detached casino footer button")
	var chip_badge := vegas.find_child("CasinoChipBadge", true, false) as Label if vegas != null else null
	_expect(chip_badge != null and "100" in chip_badge.text, "Las Vegas postcard shows the persistent CHIP balance")
	var vegas_art: TextureRect
	if vegas != null:
		var vegas_art_nodes := vegas.find_children("*", "TextureRect", true, false)
		if not vegas_art_nodes.is_empty():
			vegas_art = vegas_art_nodes[0] as TextureRect
	_expect(vegas_art != null and vegas_art.texture.resource_path == "res://assets/art/city_cards/lasvegas-city-card.png", "Las Vegas postcard uses its authored city art")
	for hidden_city: String in ["city_newyork", "city_venice", "city_singapore"]:
		var hidden_postcard := main.find_child(hidden_city, true, false) as Control
		_expect(hidden_postcard != null and not hidden_postcard.visible, "%s stays out of the current world-map lineup" % hidden_city)

	var game_state := root.get_node("GameState")
	var stage_before_vegas: StringName = game_state.selected_stage_id
	vegas.pressed.emit()
	await process_frame
	_expect(bgm.current_track() == &"lasvegas_preview", "Las Vegas selection starts its preview BGM")
	_expect(not is_instance_valid(main.get("casino_hub_overlay")), "selecting Las Vegas does not immediately open Casino Hub")
	_expect(StringName(main.get("selected_special_destination")) == &"lasvegas_casino", "Las Vegas selection stays in screen-local destination state")
	var detail_title := main.find_child("StageSelectDetailTitle", true, false) as Label
	var detail_description := main.find_child("StageSelectDetailDescription", true, false) as Label
	var casino_cta := main.find_child("StageSelectPrimaryCta", true, false) as Button
	_expect(detail_title != null and detail_title.text == "選択中：きらめきのラスベガス ｜ CASINO", "Las Vegas selection updates the detail title")
	_expect(detail_description != null and detail_description.text == "CHIPを使ってミニゲームや景品交換を楽しむ夜の街。", "Las Vegas selection updates the detail description")
	_expect(casino_cta != null and casino_cta.text == "カジノへ", "Las Vegas selection changes the primary CTA")
	_expect(game_state.selected_stage_id == stage_before_vegas, "Las Vegas selection does not change GameState.selected_stage_id")
	var capture_path := OS.get_environment("DICE_QA_CASINO_STAGE_CAPTURE_PATH")
	if not capture_path.is_empty():
		for ignored: int in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		_expect(capture.save_png(capture_path) == OK, "Las Vegas selection QA capture saves successfully")

	casino_cta.pressed.emit()
	await process_frame
	_expect(is_instance_valid(main.get("casino_hub_overlay")), "Las Vegas CTA opens Casino Hub")
	_expect(bgm.current_track() == &"lasvegas_main", "entering Casino Hub switches to its main-map BGM")
	main.call("_close_casino_hub")
	await process_frame
	await process_frame
	_expect(bgm.current_track() == &"lasvegas_preview", "returning from Casino Hub restores the Las Vegas preview BGM")
	var amazon := main.find_child("city_amazon", true, false) as Button
	amazon.pressed.emit()
	await process_frame
	var restored_title := main.find_child("StageSelectDetailTitle", true, false) as Label
	var restored_cta := main.find_child("StageSelectPrimaryCta", true, false) as Button
	_expect(StringName(main.get("selected_special_destination")).is_empty(), "normal stage selection clears the special destination")
	_expect(restored_title != null and "翠雨の大瀑布" in restored_title.text, "normal stage selection restores its existing detail title")
	_expect(restored_cta != null and restored_cta.text == "探検猫で出発", "normal stage selection restores the existing departure CTA")
	main.queue_free()
	await process_frame

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	print("Casino UI tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
