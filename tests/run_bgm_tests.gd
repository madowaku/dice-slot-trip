extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bgm := root.get_node_or_null("BgmManager")
	_expect(bgm != null, "BGM manager is available as an autoload")
	if bgm == null:
		quit(1)
		return
	bgm.play_home()
	_expect(bgm.current_track() == &"home", "title screen uses the supplied main theme")
	bgm.play_stage_select()
	_expect(bgm.current_track() == &"stage_select", "stage selection uses Sand Dune Wind")
	bgm.play_lasvegas_preview()
	_expect(bgm.current_track() == &"lasvegas_preview", "Las Vegas selection uses Casino")
	bgm.play_lasvegas_main()
	_expect(bgm.current_track() == &"lasvegas_main", "Las Vegas main map uses Jackpot")
	bgm.play_dice_race()
	_expect(bgm.current_track() == &"dice_race", "Dice Race uses Minimal Derby")
	bgm.play_normal_map()
	_expect(bgm.current_track() == &"normal_map", "normal travel uses A Walk in the Breeze")
	bgm.play_kyoto_fox_fire_chase()
	_expect(bgm.current_track() == &"kyoto_fox_fire_chase", "Kyoto Fox-Fire Chase uses Anone")
	bgm.set_master_volume(0.0)
	bgm.set_master_volume(1.0)

	OS.set_environment("DICE_QA_V06_SCENARIO", "boss_ready")
	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen := ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	_expect(bgm.current_track() == &"boss", "golden gate and boss phases use Beyond the Desert")
	host.queue_free()
	await process_frame
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	bgm.stop()
	print("BGM_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
