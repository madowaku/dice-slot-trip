extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const Localization = preload("res://scripts/ui/v06_localization.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_locale := TranslationServer.get_locale()
	var game_state := root.get_node("GameState")
	var bgm_manager := root.get_node("BgmManager")
	var original_bgm_volume := float(game_state.get("master_volume"))
	var original_se_volume := float(game_state.get("se_volume"))
	var original_travel_cards: Array = game_state.get("travel_card_ids").duplicate()
	Localization.set_locale("ja")
	OS.set_environment("DICE_QA_V06_SCENARIO", "atlas_18")
	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	var session: RefCounted = screen.session_for_test()
	session.retry_run()
	var started: Dictionary = session.start_roll(1, 1000)
	while session.has_pending_hops():
		session.next_hop()
	var settled: Dictionary = session.finish_movement()
	screen.call("_cancel_motion", session.position())
	screen.call("_refresh_ui")
	_expect(bool(started.get("ok", false)) and bool(settled.get("ok", false)) and bool(screen.session_snapshot().get("clock_running", false)), "fixture reaches a clock-running READY state")
	_expect((screen.get_node("%BackButton") as Button).text == "メニュー", "persistent bottom action is MENU instead of direct stage exit")
	_expect(not (screen.get_node("%TravelMenuOverlay") as Control).visible, "travel menu starts closed")
	(screen.get_node("%BackButton") as Button).pressed.emit()
	await process_frame
	_expect(bool(screen.get("_travel_menu_open")) and (screen.get_node("%TravelMenuOverlay") as Control).visible, "MENU opens the centered travel menu")
	var paused_snapshot: Dictionary = screen.session_snapshot()
	_expect(bool(paused_snapshot.get("clock_paused", false)), "opening the travel menu pauses the run clock")
	_expect((screen.get_node("%DieButton") as Button).disabled and (screen.get_node("%MapButton") as Button).disabled and (screen.get_node("%ItemToolButton") as Button).disabled, "roll, map, and tools stay gated beneath the menu")
	_expect((screen.get_node("%TravelMenuContinueButton") as Button).text == "旅を続ける" and (screen.get_node("%TravelMenuExitButton") as Button).text == "ステージ選択へ戻る", "menu separates continue from stage exit with localized copy")
	game_state.call("register_travel_card", "item:water_canteen")
	var encyclopedia_button := screen.get_node("%TravelMenuEncyclopediaButton") as Button
	encyclopedia_button.pressed.emit()
	await process_frame
	var encyclopedia := screen.get_node("%TravelEncyclopediaOverlay") as Control
	var encyclopedia_receipt: Dictionary = encyclopedia.call("visual_receipt")
	_expect(encyclopedia.visible and not (screen.get_node("%TravelMenuOverlay") as Control).visible and bool(screen.get("_travel_menu_open")) and bool(screen.get("_travel_encyclopedia_open")), "settings opens the shared travel encyclopedia without resuming play")
	_expect(bool(screen.session_snapshot().get("clock_paused", false)) and int(encyclopedia_receipt.get("unlocked", 0)) >= 1, "encyclopedia keeps the run clock paused and reads persistent discoveries")
	var water_card_button := encyclopedia.find_child("Open_TravelCard_item_water_canteen", true, false) as Button
	water_card_button.pressed.emit()
	await process_frame
	_expect((encyclopedia.find_child("TravelCardDetail", true, false) as Control).visible and (encyclopedia.find_child("TravelCardDetailArt", true, false) as TextureRect).texture.resource_path.ends_with("cairo-item-water-canteen.png"), "an encountered item opens its full card detail from settings")
	(encyclopedia.find_child("TravelEncyclopediaCloseButton", true, false) as Button).pressed.emit()
	await process_frame
	_expect(not encyclopedia.visible and (screen.get_node("%TravelMenuOverlay") as Control).visible and bool(screen.session_snapshot().get("clock_paused", false)), "closing the encyclopedia returns to the still-paused travel menu")
	var bgm_slider := screen.get_node("%TravelBgmSlider") as HSlider
	var se_slider := screen.get_node("%TravelSeSlider") as HSlider
	bgm_slider.value = 42.0
	se_slider.value = 36.0
	var feedback_state: Dictionary = screen.get("_feedback").feedback_receipt()
	_expect(is_equal_approx(float(game_state.get("master_volume")), 0.42) and (screen.get_node("%TravelBgmLabel") as Label).text.contains("42%"), "travel menu changes BGM volume live")
	_expect(is_equal_approx(float(game_state.get("se_volume")), 0.36) and is_equal_approx(float(feedback_state.get("master_volume", 0.0)), 1.0) and is_equal_approx(float(feedback_state.get("se_volume", 0.0)), 0.36), "travel menu changes SE independently from BGM")
	_expect((screen.get_node("%BackButton") as Button).icon.resource_path == "res://assets/art/ui/common/menu-gear-v1.png" and (screen.get_node("%SkillToolButton") as Button).icon.resource_path == "res://assets/art/ui/common/skill-book-v1.png", "tool dock uses the generated gear and skill-book icons")
	(screen.get_node("%TravelMenuContinueButton") as Button).pressed.emit()
	await process_frame
	_expect(not bool(screen.get("_travel_menu_open")) and not bool(screen.session_snapshot().get("clock_paused", true)), "Continue closes the menu and resumes the run clock")
	var exit_signal := {"count": 0}
	screen.back_requested.connect(func() -> void: exit_signal.count += 1)
	(screen.get_node("%BackButton") as Button).pressed.emit()
	await process_frame
	_expect(exit_signal.count == 0, "opening MENU never emits the stage-exit signal")
	(screen.get_node("%TravelMenuExitButton") as Button).pressed.emit()
	await process_frame
	_expect(exit_signal.count == 1 and not bool(screen.get("_travel_menu_open")) and bool(screen.get("_exit_transition_requested")) and not screen.is_processing(), "only the menu exit action requests stage selection and freezes further play updates")
	Localization.set_locale("en")
	_expect(Localization.text(&"TRAVEL_MENU_BUTTON") == "MENU" and Localization.text(&"TRAVEL_MENU_EXIT") == "Return to Stage Select", "travel-menu copy is available in English")
	Localization.set_locale(original_locale)
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	host.queue_free()
	await process_frame
	var main_source := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	_expect(main_source.contains('screen.connect("back_requested", Callable(self, "_on_v06_back_requested"))') and main_source.contains('call_deferred("show_stage_select")'), "main defers the parent rebuild until the child button signal has returned")
	game_state.set("master_volume", original_bgm_volume)
	game_state.set("se_volume", original_se_volume)
	(game_state.get("travel_card_ids") as Array).assign(original_travel_cards)
	bgm_manager.call("set_master_volume", original_bgm_volume)
	root.get_node("SaveManager").call("save_now")
	print("V06_TRAVEL_MENU_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
