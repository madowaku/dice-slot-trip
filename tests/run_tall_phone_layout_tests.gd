extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "boss_ready")
	var host := Control.new()
	host.size = Vector2(720, 1600)
	root.add_child(host)
	var screen := ScreenScene.instantiate()
	host.add_child(screen)
	for ignored: int in range(3):
		await process_frame

	var die := screen.get_node("%BossDicePresentation") as Control
	var tray := screen.get_node("%TrayPanel") as Control
	var mirror := screen.get_node("%MirrorPanel") as Control
	var safe_margin := screen.get_node("SafeMargin") as Control
	var page := screen.get_node("%Page") as Control
	var die_rect := die.get_global_rect()
	var tray_rect := tray.get_global_rect()
	_expect(screen.size == Vector2(720, 1600), "play screen expands to a 9:20 phone viewport")
	_expect(safe_margin.position == Vector2(16, 16) and safe_margin.size == Vector2(688, 1568), "9:20 safe margin remains unchanged")
	_expect(page.position == Vector2.ZERO and page.size == Vector2(688, 1568), "9:20 page remains unchanged")
	_expect((page as VBoxContainer).get_theme_constant("separation") == 8 and is_equal_approx((screen.get_node("%MessageBand") as Control).custom_minimum_size.y, 72.0), "9:20 profile preserves authored page spacing and operation band")
	var hud_panel := screen.get_node("%HudPanel") as Control
	var survival_stack := screen.get_node("%SurvivalStack") as VBoxContainer
	var life_box := screen.get_node("%LifeBox") as Control
	var hp_label := screen.get_node("%HPLabel") as Control
	_expect(is_equal_approx(hud_panel.custom_minimum_size.y, 104.0) and survival_stack.get_parent().name == "HudRow2" and survival_stack.get_child(0) == life_box and survival_stack.get_child(1) == hp_label, "720-wide tall-phone structure keeps LIFE above HP inside the fixed104px row")
	_expect(is_equal_approx(die.position.y, float(screen.call("_boss_dice_rest_y"))), "boss die uses the tall-phone tray anchor")
	_expect(is_equal_approx(tray_rect.position.y - die_rect.end.y, 26.0), "boss die stays in the gap immediately above the bottom action tray")
	_expect(is_equal_approx(die.get_global_rect().get_center().x, (screen.get_node("%RaceStage") as Control).get_global_rect().get_center().x), "boss die stays centered between both lanes")
	_expect(is_equal_approx(die_rect.position.y - mirror.get_global_rect().end.y, 14.0), "mirror result panel stays above the live die without overlap")

	var main_source := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	_expect(main_source.contains("TitleArtHitLayer") and main_source.contains("title_source_rect"), "title touch targets share the fitted source-art coordinate system")
	_expect(main_source.contains("TitleBackingMatte") and main_source.contains("TITLE_BACKING_MATTE"), "extra-tall title space uses the generated travel-journal matte")
	_expect(FileAccess.file_exists("res://assets/art/ui/title/title-backing-matte-v2.png"), "generated title backing matte is stored in the project")
	_expect(main_source.contains("TextureRect.STRETCH_KEEP_ASPECT_CENTERED") and main_source.contains("title_art_rect_for_viewport"), "title centers the complete source poster so the wordmark, painted UI, and touch targets cannot crop or drift")

	host.queue_free()
	await process_frame
	await _test_half_scale_survival_stack()
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	print("TALL_PHONE_LAYOUT_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_half_scale_survival_stack() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	var original_size := root.size
	var original_content_scale := root.content_scale_size
	root.content_scale_size = Vector2i(720, 1280)
	root.size = Vector2i(360, 640)
	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen := ScreenScene.instantiate()
	host.add_child(screen)
	for ignored: int in range(3):
		await process_frame
	var hud_panel := screen.get_node("%HudPanel") as Control
	var hud_row2 := screen.get_node("%SurvivalStack").get_parent() as Control
	var survival_stack := screen.get_node("%SurvivalStack") as VBoxContainer
	var life_box := screen.get_node("%LifeBox") as Control
	var hp_label := screen.get_node("%HPLabel") as Control
	var atlas := screen.get_node("%AtlasView") as Control
	var map_button := screen.get_node("%MapButton") as Control
	_expect(screen.size == Vector2(720, 1280) and root.size == Vector2i(360, 640), "360 physical viewport preserves the720 logical HUD layout")
	_expect(hud_row2.get_global_rect().encloses(survival_stack.get_global_rect()) and hud_panel.get_global_rect().encloses(life_box.get_global_rect()) and hud_panel.get_global_rect().encloses(hp_label.get_global_rect()) and life_box.get_global_rect().end.y <= hp_label.get_global_rect().position.y + 1.0, "360-scale HUD contains LIFE above HP without clipping")
	_expect(is_equal_approx(hud_panel.custom_minimum_size.y, 104.0) and map_button.custom_minimum_size == Vector2(80, 96) and atlas.size.y >= 440.0, "360-scale survival stack preserves fixed104px contract, map action geometry, and playfield")
	host.queue_free()
	await process_frame
	root.size = original_size
	root.content_scale_size = original_content_scale


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
