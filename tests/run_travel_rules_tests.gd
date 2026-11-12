extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const Localization = preload("res://scripts/ui/v06_localization.gd")
var checks: int = 0
var failures: int = 0
var screen: Control

func _init() -> void:
	call_deferred("_run")

func _expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", description)

func _run() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "rules_quality")
	Localization.set_locale("en" if OS.get_environment("DICE_QA_LOCALE") == "en" else "ja")
	root.size = Vector2i(360, 800 if OS.get_environment("DICE_QA_TALL") == "1" else 640)
	root.content_scale_size = Vector2i(720, 1280)
	screen = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var menu_art: TextureRect = screen.find_child("TravelMenuIllustration", true, false)
	_expect(menu_art.texture == null, "menu art is not loaded until the menu opens")
	var session: RefCounted = screen.session_for_test()
	var started: Dictionary = session.start_roll(1, Time.get_ticks_msec())
	while session.has_pending_hops():
		session.next_hop()
	var finished: Dictionary = session.finish_movement()
	_expect(started.ok and finished.ok, "fixture completes one timed roll")
	screen.call("_refresh_ui")
	screen.get_node("%BackButton").pressed.emit()
	await _capture("menu")
	var menu_panel: Control = screen.get_node("%TravelMenuPanel")
	_expect(screen.get_global_rect().encloses(menu_panel.get_global_rect()), "expanded menu stays inside phone viewport")
	var open_button: Button = screen.find_child("TravelRulesButton", true, false)
	_expect(open_button != null and open_button.is_visible_in_tree(), "menu exposes readable guide entry")
	open_button.pressed.emit()
	var guide: Control = screen.get_node("TravelRulesView")
	_expect(guide.visible and not screen.get_node("%TravelMenuOverlay").visible, "guide replaces menu")
	var elapsed: int = session.elapsed_ms(Time.get_ticks_msec())
	_expect(session.snapshot().clock_paused, "guide retains paused run clock")
	var snapshot: Dictionary = session.stable_save_snapshot()
	for index: int in range(3):
		var load_started: int = Time.get_ticks_usec()
		guide.topic_buttons[index].pressed.emit()
		print("GUIDE_TOPIC index=%d switch_us=%d" % [index, Time.get_ticks_usec() - load_started])
		await _capture("topic%d" % index)
		_expect(guide.active_topic == index and guide.topic_buttons[index].button_pressed, "topic selection matches visible page")
		var panel: Control = guide.get_node("RulesPanel")
		_expect(screen.get_global_rect().encloses(panel.get_global_rect()), "guide panel fits viewport")
		_expect(panel.get_global_rect().encloses(guide.close_button.get_global_rect()), "guide close button remains reachable")
		_expect(guide.body.get_child_count() == (5 if index == 1 else 4), "topic contains illustration and all rule cards")
		var illustration: TextureRect = guide.body.get_node("TopicIllustration")
		_expect(illustration.texture != null and illustration.texture.resource_path == guide.TOPIC_ART_PATHS[index], "topic displays its own bundled illustration")
		_expect(illustration.texture.get_width() <= 768 and illustration.texture.get_height() <= 768, "runtime artwork has bounded dimensions")
		print("GUIDE_TEXTURE index=%d width=%d height=%d" % [index, illustration.texture.get_width(), illustration.texture.get_height()])
		guide.topic_buttons[index].pressed.emit()
		_expect(guide.body.get_node("TopicIllustration") == illustration and guide.topic_buttons[index].button_pressed, "reselecting a topic reuses controls and preserves selection")
		_expect(illustration.mouse_filter == Control.MOUSE_FILTER_IGNORE, "illustration does not intercept scrolling")
		guide.scroll.scroll_vertical = 10000
		await process_frame
		await process_frame
		var last_card: Control = guide.body.get_child(guide.body.get_child_count() - 1)
		_expect(last_card.get_global_rect().end.y <= guide.scroll.get_global_rect().end.y + 2, "final rule remains reachable after adding art")
		guide.scroll.scroll_vertical = 0
		_expect(session.elapsed_ms(Time.get_ticks_msec()) == elapsed and session.stable_save_snapshot() == snapshot, "reading does not advance clock or mutate progress")
	_expect(screen.get_node("%DieButton").disabled and screen.get_node("%ItemToolButton").disabled, "guide blocks background gameplay")
	screen.call("_request_back")
	_expect(not guide.visible and screen.get_node("%TravelMenuOverlay").visible and session.snapshot().clock_paused, "Back returns to paused menu without resuming")
	_expect(open_button.has_focus(), "focus returns to guide entry")
	open_button.pressed.emit()
	_expect(guide.visible and guide.active_topic == 0, "guide can be reopened")
	guide.close_button.pressed.emit()
	_expect(not guide.visible and screen.get_node("%TravelMenuOverlay").visible, "close CTA returns to menu")
	screen.get_node("%TravelMenuContinueButton").pressed.emit()
	_expect(not session.snapshot().clock_paused and not screen.get_node("%DieButton").disabled, "Continue resumes the original journey")
	screen.queue_free()
	await process_frame
	root.get_node("BgmManager").stop()
	root.get_node("UiSfxManager").stop_all()
	await create_timer(0.15).timeout
	print("TRAVEL_RULES checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func _capture(state: String) -> void:
	for ignored: int in range(6):
		await process_frame
	var directory: String = OS.get_environment("DICE_QA_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var capture: Image = root.get_texture().get_image()
	_expect(capture.save_png(directory.path_join(state + ".png")) == OK, "capture " + state)
