extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const Localization = preload("res://scripts/ui/v06_localization.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_locale := TranslationServer.get_locale()
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
	_expect(exit_signal.count == 1 and not bool(screen.get("_travel_menu_open")), "only the menu exit action requests stage selection")
	Localization.set_locale("en")
	_expect(Localization.text(&"TRAVEL_MENU_BUTTON") == "MENU" and Localization.text(&"TRAVEL_MENU_EXIT") == "Return to Stage Select", "travel-menu copy is available in English")
	Localization.set_locale(original_locale)
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	host.queue_free()
	await process_frame
	print("V06_TRAVEL_MENU_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
