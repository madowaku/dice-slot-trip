extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const OrientationScript = preload("res://scripts/game/dice_race_orientation.gd")
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
	var ui_sfx := root.get_node_or_null("UiSfxManager")
	_expect(ui_sfx != null and ui_sfx.call("current_stage_pack") == &"arcade", "Dice Race selects the Las Vegas arcade SFX pack")
	var sfx_before_select: Dictionary = ui_sfx.call("receipt") if ui_sfx != null else {}
	race.call("_select_racer", race.selected_racer)
	var sfx_after_select: Dictionary = ui_sfx.call("receipt") if ui_sfx != null else {}
	_expect(int(sfx_after_select.get("play_count", 0)) == int(sfx_before_select.get("play_count", 0)) + 1 and str(sfx_after_select.get("last_cue", "")) == "select" and str(sfx_after_select.get("last_pack", "")) == "soft", "racer selection plays one restrained common select cue")
	_expect(race.orientations.size() == 24, "Dice Race UI receives all 24 physical orientations")
	_expect(race.roll_button != null and race.start_button != null, "Dice Race exposes start and roll controls")
	_expect(race.racer_nodes.size() == 6, "Dice Race creates six racer markers")
	_expect(race.racer_nodes.has("rabbit") and not race.racer_nodes.has("crocodile"), "Dice Race UI uses the final rabbit lineup")
	_expect(race.direction_plates.size() == 6 and race.die_face_label != null, "Dice Race builds six fixed direction plates around the die")
	_expect(race.opposite_pair_labels.size() == 3, "Dice Race shows the three opposite-face pairs")
	for racer_id: String in RaceScript.RACERS:
		var plate: Dictionary = race.direction_plates.get(racer_id, {})
		var portrait := plate.get("portrait") as TextureRect
		_expect(str(plate.get("direction", "")) == str(OrientationScript.RACER_DIRECTION[racer_id]), "%s keeps its physical die direction" % racer_id)
		if portrait != null:
			_expect(portrait.texture != null, "%s visible direction plate uses its official racer art" % racer_id)
		var marker := race.racer_nodes.get(racer_id) as Control
		_expect(marker != null and marker.find_child("RacerShadow", true, false) != null, "%s has a grounded course shadow" % racer_id)
		var course_portrait := marker.find_child("RacerPortrait", true, false) as TextureRect if marker != null else null
		_expect(course_portrait != null and course_portrait.texture != null, "%s runs directly on the course as official art" % racer_id)
		_expect(marker.find_children("*", "PanelContainer", true, false).is_empty(), "%s is not boxed inside a course card" % racer_id)
	var unselected_plate := (race.direction_plates.get("rabbit", {}) as Dictionary).panel as PanelContainer
	var plate_style := unselected_plate.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(plate_style != null and plate_style.border_width_left == 0, "non-BET die directions stay out of boxed-card chrome")
	_expect(race.opposite_pair_panels[0].get_theme_stylebox("panel").border_width_left == 0, "non-selected opposite-face pairs stay out of boxed-card chrome")
	_expect(race.ranking_cards.size() == 3, "Dice Race builds the compact top-three ranking strip")
	_expect(race.track_view != null and race.minimap != null, "Dice Race builds a vertical race viewport and full-course minimap")
	var setup_course_art := race.find_child("SetupCourseArt", true, false) as TextureRect
	var live_course_art := race.track_view.find_child("CourseArt", true, false) as TextureRect
	_expect(setup_course_art != null and setup_course_art.texture != null and live_course_art != null and live_course_art.texture != null, "setup and live race share the production desert course art")
	_expect(race.dice_presentation != null and race.dice_presentation.dice_race_face_layout, "Dice Race builds a dedicated three-face physical die")
	_expect(race.cashout_overlay != null and not race.cashout_overlay.visible, "Dice Race keeps the CASH OUT decision in a hidden modal overlay until offered")
	_expect(race.track_view.logical_y_for_test(0) > race.track_view.logical_y_for_test(9), "vertical course places progress toward GOAL upward")
	_expect(race.track_view.visible_range_for_test() == Vector2(0, 9), "course opens on a readable nine-space window")
	_expect(race.track_view.gimmick_markers.keys().all(func(space: int) -> bool: return space in [5, 10, 15, 20]) and race.track_view.gimmick_markers.size() == 4, "vertical course exposes all four fixed gimmick spaces")
	var start_gate := race.track_view.find_child("StartGate", true, false) as Control
	var goal_gate := race.track_view.find_child("GoalGate", true, false) as Control
	var start_art := start_gate.find_child("GateArt", true, false) as TextureRect if start_gate != null else null
	var goal_art := goal_gate.find_child("GateArt", true, false) as TextureRect if goal_gate != null else null
	_expect(start_art != null and start_art.texture != null, "course exposes the painted START gate art")
	_expect(goal_art != null and goal_art.texture != null, "course exposes the painted GOAL arch art")
	_expect(race.track_view.find_child("FinalStretch", true, false) != null, "course exposes a dedicated final-stretch light")
	for gimmick_space: int in [5, 10, 15, 20]:
		var object := race.track_view.gimmick_markers.get(gimmick_space) as Control
		var visual := object.find_child("GimmickVisual", true, false) as TextureRect if object != null else null
		_expect(visual != null and visual.texture != null, "space %d uses painted gimmick art rather than a text-only label" % gimmick_space)
	var known_assignments: Dictionary = OrientationScript.values_for_racers(OrientationScript.base_orientation())
	race.current_assignments = known_assignments.duplicate()
	race.call("_refresh_assignment_ui")
	race.call("_refresh_physical_die", 0.0)
	var expected_pose: Quaternion = OrientationScript.quaternion_for_orientation(OrientationScript.base_orientation())
	var rendered_pose: Quaternion = race.dice_presentation.physical_orientation_for_test()
	_expect(absf(expected_pose.dot(rendered_pose)) > 0.999, "three-face die renders the exact physical orientation behind the assignment labels")
	for pair: Array in race.OPPOSITE_RACER_PAIRS:
		_expect(int(known_assignments[pair[0]]) + int(known_assignments[pair[1]]) == 7, "%s and %s display an opposite-face total of seven" % [pair[0], pair[1]])
	_expect(str(race.RACER_LABELS.get(race.selected_racer, "")) in race.target_value_label.text and str(int(known_assignments[race.selected_racer])) in race.target_value_label.text, "BET racer exposes its live die value")
	_expect(race.opposite_pair_panels[1].modulate.a > race.opposite_pair_panels[0].modulate.a, "only the BET racer's opposite pair receives full emphasis")
	_expect(race.setup_view.visible and not race.race_view.visible, "Dice Race opens in the pre-race betting view")
	race.call("_start_race")
	await process_frame
	_expect(not race.setup_view.visible and race.race_view.visible, "RACE START replaces setup controls with the active race view")
	var bet_marker := race.racer_nodes.get(race.selected_racer) as Control
	var bet_ring := bet_marker.find_child("BetHighlight", true, false) as Panel
	_expect(bet_ring != null and bet_ring.visible, "RACE START highlights the supported racer with a gold ring")
	var bet_crown := bet_marker.find_child("BetCrown", true, false) as Label
	_expect(bet_crown != null and bet_crown.visible, "RACE START marks the supported racer with a small course badge")
	var start_centers: Array[float] = []
	for racer_id: String in RaceScript.RACERS:
		var start_marker := race.racer_nodes.get(racer_id) as Control
		start_centers.append(start_marker.position.x + start_marker.size.x * 0.5)
	_expect(start_centers.max() - start_centers.min() >= 150.0, "six racers spread across stable lanes when clustered at START")
	race.orientation_index = 0
	race.current_assignments = known_assignments.duplicate()
	race.call("_refresh_assignment_ui")
	race.call("_on_roll_stop")
	race.call("_on_roll_stop")
	await create_timer(0.4).timeout
	_expect(race.last_stop_feedback_assignments == known_assignments, "STOP feedback uses the exact stopped physical orientation")
	_expect((race.race.get("last_assignments", {}) as Dictionary) == known_assignments, "STOP applies the same assignments to race logic without a hidden redraw")
	_expect(race.stop_feedback_count_for_test == 1, "one STOP creates one six-direction feedback burst")
	var stop_sfx: Dictionary = ui_sfx.call("receipt") if ui_sfx != null else {}
	_expect(str(stop_sfx.get("last_cue", "")) == "progress-step" and str(stop_sfx.get("last_pack", "")) == "arcade", "ordinary STOP resolution plays one Las Vegas progress cue")
	var moved_positions := {}
	for racer_id: String in RaceScript.RACERS:
		moved_positions[racer_id] = 2
	moved_positions[race.selected_racer] = 23
	for racer_id: String in RaceScript.RACERS:
		(race.race.racers.get(racer_id, {}) as Dictionary)["position"] = moved_positions[racer_id]
	race.track_view.set_race_state(moved_positions, race.selected_racer, true)
	await create_timer(0.45).timeout
	_expect(race.track_view.camera_section_for_test() == 3 and race.track_view.visible_range_for_test().is_equal_approx(Vector2(15, 24)), "course follows the BET racer into the final nine-space window")
	_expect(race.minimap.camera_range.is_equal_approx(Vector2(15, 24)), "full-course minimap mirrors the visible race window")
	race.call("_maybe_show_final_stretch")
	await create_timer(0.08).timeout
	var banner := race.race_fx_layer.find_child("FinalStretchBanner", true, false) as Label
	_expect(banner != null and banner.text == "FINAL STRETCH!", "entering the final course section raises one race-air banner")
	race.call("_play_overtake_fx", 2, 1)
	await process_frame
	_expect(race.race_fx_layer.find_child("OvertakeSpark", true, false) != null, "BET racer overtake emits gold sparks")
	race.race.set("finished", true)
	race.race.set("winner", race.selected_racer)
	race.race.set("bet_active", true)
	race.call("_finish_race")
	await create_timer(0.08).timeout
	_expect(race.race_fx_layer.find_child("WinCard", true, false) != null, "selected-racer victory shows the reward card")
	_expect(race.race_fx_layer.find_child("ConfettiPiece", true, false) != null, "victory adds restrained gold confetti")
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
	_expect(chip_badge != null and str(CasinoBankScript.balance()) in chip_badge.text, "Las Vegas postcard shows the persistent CHIP balance")
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
