extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const Localization = preload("res://scripts/ui/v06_localization.gd")
var failures: int = 0
var checks: int = 0
var screen: Control

func _init() -> void:
	call_deferred("_run")

func _expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", description)

func _run() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "onboarding_quality")
	Localization.set_locale("en" if OS.get_environment("DICE_QA_LOCALE") == "en" else "ja")
	root.size = Vector2i(360, 800 if OS.get_environment("DICE_QA_TALL") == "1" else 640)
	root.content_scale_size = Vector2i(720, 1280)
	screen = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var session: RefCounted = screen.session_for_test()
	_expect(screen.call("_open_start_onboarding_if_eligible"), "new journey opens goal briefing")
	_expect(screen.get("_onboarding_kind") == "survival" and session.elapsed_ms(Time.get_ticks_msec()) == 0, "briefing does not start the run clock")
	await _capture("goal")
	var prompt: Button = screen.get_node("%LandingArtPrompt")
	prompt.pressed.emit()
	_expect(session.has_seen_survival_onboarding() and not session.has_seen_three_roll_onboarding(), "first CTA records only the first page")
	_expect(screen.get("_onboarding_kind") == "slot" and session.elapsed_ms(Time.get_ticks_msec()) == 0, "next page does not consume run time")
	_expect(screen.get_node("%LandingArt").has_node("OnboardingSlotExample"), "slot example displayed")
	await _capture("slot")
	screen.call("_on_die_pressed")
	_expect(not bool(screen.get("_rolling")), "briefing blocks gameplay input")
	prompt.pressed.emit()
	_expect(session.has_seen_three_roll_onboarding() and not session.snapshot().clock_paused, "second CTA resumes play and records seen state")
	_expect(not (screen.get_node("%LandingArt/OnboardingSlotExample") as Control).visible, "example cannot bleed into other cards")
	_expect(not screen.call("_open_start_onboarding_if_eligible"), "completed briefing does not reopen")
	_expect(screen.get_node("%MessageLabel").text == Localization.text(&"FIRST_ROLL_START"), "first action shown beside the die")
	await _capture("ready")
	screen.call("_on_die_pressed")
	_expect(bool(screen.get("_rolling")) and screen.get_node("%MessageLabel").text == Localization.text(&"FIRST_ROLL_STOP"), "real roll input teaches second tap")
	await _capture("rolling")
	screen.call("_cancel_motion", session.position())
	screen.set("_rolling", false)
	for index: int in range(2):
		screen.call("_qa_resolve_roll", 1)
		screen.call("_refresh_default_operation_message", session.phase())
		_expect(screen.get_node("%MessageLabel").text == Localization.text(&"FIRST_ROLL_SECOND" if index == 0 else &"FIRST_ROLL_THIRD"), "guidance advances with completed rolls")
	screen.call("_qa_resolve_roll", 1)
	session.acknowledge_resolution()
	screen.call("_refresh_default_operation_message", session.phase())
	_expect(screen.get_node("%MessageLabel").text == "サイコロを振ろう", "first-set prompts end after three rolls")
	screen.queue_free()
	await process_frame
	root.get_node("BgmManager").stop()
	root.get_node("UiSfxManager").stop_all()
	await create_timer(0.15).timeout
	print("ONBOARDING_FLOW checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func _capture(state: String) -> void:
	for ignored: int in range(4):
		await process_frame
	if state in ["goal", "slot"]:
		var panel: Control = screen.get_node("%LandingArtPanel")
		var caption: Label = screen.get_node("%LandingArtCaption")
		var button: Control = screen.get_node("%LandingArtPrompt")
		_expect(screen.get_global_rect().encloses(panel.get_global_rect()), state + " card fits phone viewport")
		_expect(panel.get_global_rect().encloses(button.get_global_rect()) and caption.get_global_rect().end.y <= button.get_global_rect().position.y, state + " copy and CTA do not overlap")
		_expect(caption.get_theme_font_size("font_size") >= 28, state + " readable copy at half scale")
	var directory: String = OS.get_environment("DICE_QA_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var capture: Image = root.get_texture().get_image()
	_expect(capture.save_png(directory.path_join(state + ".png")) == OK, "capture " + state)
