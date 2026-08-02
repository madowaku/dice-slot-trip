extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const SaveData = preload("res://scripts/game/v06_session_save_data.gd")
const Localization = preload("res://scripts/ui/v06_localization.gd")
const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_localization()
	_test_first_time_state_and_save()
	await _test_card_content_and_tap_gate()
	print("V06_TILE_HELP_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_localization() -> void:
	var original := TranslationServer.get_locale()
	_expect(Localization.set_locale("ja-JP") == "ja", "Japanese locale aliases normalize to ja")
	_expect(Localization.text(&"TILE_HELP_COIN_TITLE") == "コインを発見", "Japanese tile-help copy resolves through TranslationServer")
	_expect(Localization.set_locale("en-US") == "en", "English locale aliases normalize to en")
	_expect(Localization.text(&"TILE_HELP_COIN_TITLE") == "COINS FOUND", "English tile-help copy resolves through TranslationServer")
	Localization.set_locale(original)


func _test_first_time_state_and_save() -> void:
	var session: RefCounted = Session.new()
	_expect(session.tile_explanation_kind("warp_oasis") == "WARP" and session.tile_explanation_kind("boss") == "", "tile kinds normalize into the six supported explanations")
	_expect(not session.has_seen_tile_explanation("COIN") and session.mark_tile_explanation_seen("COIN") and session.has_seen_tile_explanation("COIN"), "a tile explanation becomes seen after its first presentation")
	_expect(session.seen_tile_explanation_kinds() == ["COIN"], "seen explanations are deterministic and unique")
	_expect(session.retry_run() and session.has_seen_tile_explanation("COIN"), "retry preserves first-time explanation history")
	var dto: Dictionary = SaveData.from_session(session)
	_expect(not dto.is_empty() and SaveData.validate(dto).ok, "seen explanation history validates in a stable save")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(dto.session_state, 1000) and restored.has_seen_tile_explanation("COIN"), "seen explanation history survives save restore")
	var invalid := dto.duplicate(true)
	invalid.session_state.player.stage_flags[Session.STAGE_FLAG_SEEN_TILE_EXPLANATIONS] = {"BOSS": true}
	_expect(not SaveData.validate(invalid).ok, "unknown explanation kinds are rejected without rejecting unrelated future flags")


func _test_card_content_and_tap_gate() -> void:
	Localization.set_locale("ja")
	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	_expect(bool(screen.call("_configure_tile_help_card", "WARP_GOLD", 0)), "WARP variants configure the shared explanation card")
	_expect(screen.get_node("%LandingArtTitle").text == "ワープ地点" and screen.get_node("%LandingArt").texture != null, "tile-help card uses translated copy and real discovery art")
	_expect(screen.get_node("%LandingArtPrompt").text == "画面をタップして旅を続ける", "card explicitly teaches tap-anywhere dismissal")
	screen.set("_tile_help_open", true)
	screen.set("_tile_help_pending_kind", "WARP")
	screen.get_node("%LandingArtOverlay").show()
	screen.call("_refresh_ui")
	_expect(screen.get_node("%DieButton").disabled and screen.get_node("%MapButton").disabled and screen.get_node("%BackButton").disabled, "roll, map, and back controls are gated while tile help is open")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(20, 20)
	screen.call("_on_landing_art_gui_input", tap)
	_expect(not bool(screen.get("_tile_help_open")) and not screen.get_node("%LandingArtOverlay").visible, "a tap anywhere ends and hides the explanation card")
	_expect(screen.session_for_test().has_seen_tile_explanation("WARP"), "the explanation becomes seen only after the dismissal tap")
	host.queue_free()
	await process_frame


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
