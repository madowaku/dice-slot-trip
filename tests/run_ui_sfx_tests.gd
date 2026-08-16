extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui_sfx := root.get_node_or_null("UiSfxManager")
	_expect(ui_sfx != null, "UI SFX manager is available as an autoload")
	if ui_sfx == null:
		quit(1)
		return
	ui_sfx.call("set_enabled", true)
	ui_sfx.call("set_volume", 1.0)

	ui_sfx.call("set_stage", &"cairo_hourglass")
	_expect(ui_sfx.call("current_stage_pack") == &"organic", "Cairo selects the organic world pack")
	_expect(bool(ui_sfx.call("play_ui_sfx", &"reward")), "semantic reward cue plays")
	var cairo_receipt: Dictionary = ui_sfx.call("receipt")
	_expect(str(cairo_receipt.get("last_cue", "")) == "reward" and str(cairo_receipt.get("last_pack", "")) == "organic", "world cue uses the active stage pack")

	_expect(bool(ui_sfx.call("play_common_ui_sfx", &"select")), "common select cue plays")
	var common_receipt: Dictionary = ui_sfx.call("receipt")
	_expect(str(common_receipt.get("last_pack", "")) == "soft", "common control cue stays on the soft pack")

	ui_sfx.call("set_stage", &"kyoto_thousand_year_grid")
	_expect(ui_sfx.call("current_stage_pack") == &"zen", "Kyoto selects the zen world pack")
	_expect(bool(ui_sfx.call("play_world_sfx", &"achievement")), "semantic achievement cue plays")
	var kyoto_receipt: Dictionary = ui_sfx.call("receipt")
	_expect(str(kyoto_receipt.get("last_pack", "")) == "zen", "Kyoto world cue uses zen")

	var common_packs := ["soft"]
	var world_packs := ["organic", "zen", "arcade", "scifi"]
	var common_cues := ["press", "release", "select", "open", "close", "back", "cancel", "blocked", "success", "start", "stop", "retry"]
	var world_cues := ["reward", "level-up", "achievement", "complete", "warning", "error", "progress-step", "bonus", "badge", "streak", "drop", "checkpoint"]
	var assets_ok := true
	for pack: String in common_packs:
		for cue: String in common_cues:
			assets_ok = assets_ok and ResourceLoader.exists("res://assets/audio/ui_sfx/%s/%s.mp3" % [pack, cue])
	for pack: String in world_packs:
		for cue: String in world_cues:
			assets_ok = assets_ok and ResourceLoader.exists("res://assets/audio/ui_sfx/%s/%s.mp3" % [pack, cue])
	_expect(assets_ok, "all mapped cues exist in every UI SFX pack")

	ui_sfx.call("set_volume", 0.0)
	_expect(not bool(ui_sfx.call("play_common_ui_sfx", &"press")), "SE volume zero suppresses UI SFX")
	ui_sfx.call("set_volume", 1.0)
	print("UI_SFX_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
