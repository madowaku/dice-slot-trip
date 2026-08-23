extends SceneTree

const RACE_SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")


func _init() -> void:
	call_deferred("_record")


func _record() -> void:
	var output_path := OS.get_environment("DICE_RACE_QA_OUTPUT")
	if output_path.is_empty():
		push_error("DICE_RACE_QA_OUTPUT is required")
		quit(2)
		return
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(360, 800)
	var screen: DiceRaceScreen = RACE_SCENE.instantiate()
	root.add_child(screen)
	for _frame in 12:
		await process_frame
	if OS.get_environment("DICE_RACE_QA_MODE") != "setup":
		screen.call("_select_racer", "rabbit")
		screen.race = RaceScript.new_race("rabbit", 20)
		var qa_positions := {"camel": 5, "rabbit": 6, "fox": 7, "duck": 7, "dinosaur": 8, "robot": 9}
		for racer_id: String in qa_positions:
			screen.race.racers[racer_id].position = qa_positions[racer_id]
		screen.wager_committed = true
		screen.setup_view.visible = false
		screen.race_view.visible = true
		screen.roll_button.disabled = false
		screen.current_assignments = {
			"camel": 3, "rabbit": 6, "fox": 1,
			"duck": 2, "dinosaur": 5, "robot": 4,
		}
		screen.call("_refresh_all", false)
		screen.status_label.text = "ウサギに20 CHIP。欲しい目を狙ってSTOP！"
	for _frame in 8:
		await process_frame
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	var result := image.save_png(output_path)
	var back_button := screen.find_child("CasinoBackButton", true, false) as Control
	var layout_fits := back_button != null and back_button.get_global_rect().end.y <= screen.size.y + 0.5
	print("DICE_RACE_CAPTURE size=%s layout_fits=%s result=%s" % [image.get_size(), layout_fits, result])
	quit(0 if result == OK and image.get_size() == Vector2i(360, 800) and layout_fits else 1)
