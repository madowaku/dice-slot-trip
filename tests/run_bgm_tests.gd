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
	var lasvegas_tracks: Array[String] = [
		"res://assets/audio/bgm/lasvegas/ドキドキ賭けごと.mp3",
		"res://assets/audio/bgm/lasvegas/ジャックポット.mp3",
		"res://assets/audio/bgm/lasvegas/ミニマルダービー.mp3",
		"res://assets/audio/bgm/lasvegas/ルーレット.mp3",
		"res://assets/audio/bgm/lasvegas/ShotGlass.mp3",
		"res://assets/audio/bgm/lasvegas/Dark blue night.mp3",
		"res://assets/audio/bgm/lasvegas/Rain Soaked Friday.mp3",
		"res://assets/audio/bgm/lasvegas/忍び足.mp3",
	]
	for track_path: String in lasvegas_tracks:
		_expect(FileAccess.file_exists(track_path), "Las Vegas BGM asset exists: %s" % track_path.get_file())
	bgm.play_home()
	_expect(bgm.current_track() == &"home", "title screen uses the supplied main theme")
	bgm.play_stage_select()
	_expect(bgm.current_track() == &"stage_select", "stage selection uses Doki Doki Kakegoto")
	bgm.play_lasvegas_preview()
	_expect(bgm.current_track() == &"lasvegas_preview", "Las Vegas selection uses Casino")
	bgm.play_lasvegas_main()
	_expect(bgm.current_track() == &"lasvegas_main", "Las Vegas main map uses Jackpot")
	bgm.play_vault_break()
	_expect(bgm.current_track() == &"vault_break", "VAULT BREAK uses Shinobi Ashi")
	bgm.play_dice_race()
	_expect(bgm.current_track() == &"dice_race", "Dice Race uses Minimal Derby")
	bgm.play_treasure_21()
	_expect(bgm.current_track() == &"treasure_21", "TREASURE 21 uses ShotGlass")
	bgm.play_dice_poker()
	_expect(bgm.current_track() == &"dice_poker", "DICE POKER uses Dark blue night")
	bgm.play_dice_tower()
	_expect(bgm.current_track() == &"dice_tower", "DICE TOWER uses Rain Soaked Friday")
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
