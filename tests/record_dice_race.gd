extends SceneTree

const RACE_SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const QA_ASSIGNMENTS := {
	"camel": 3, "rabbit": 6, "fox": 1,
	"duck": 2, "dinosaur": 5, "robot": 4,
}
const QA_POSITIONS := {
	"camel": 5, "rabbit": 6, "fox": 7,
	"duck": 7, "dinosaur": 8, "robot": 9,
}


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
	var mode := OS.get_environment("DICE_RACE_QA_MODE")
	if mode.is_empty():
		mode = "clustered"
	await _configure_mode(screen, mode)
	for _frame in 5:
		await process_frame
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	var result := image.save_png(output_path)
	var back_button := screen.find_child("CasinoBackButton", true, false) as Control
	var layout_fits := back_button != null and back_button.get_global_rect().end.y <= screen.size.y + 0.5
	print("DICE_RACE_CAPTURE size=%s layout_fits=%s result=%s" % [image.get_size(), layout_fits, result])
	quit(0 if result == OK and image.get_size() == Vector2i(360, 800) and layout_fits else 1)


func _configure_mode(screen: DiceRaceScreen, mode: String) -> void:
	if mode in ["setup", "setup_chip0"]:
		screen.chip_label.text = "CHIP  0" if mode == "setup_chip0" else screen.chip_label.text
		return
	if mode == "setup_ready":
		screen.call("_select_racer", "rabbit")
		screen.chip_label.text = "CHIP  100"
		screen.start_button.disabled = false
		screen.status_label.text = "ウサギを応援する"
		return
	_configure_active_race(screen)
	await process_frame
	match mode:
		"start_line":
			_set_positions(screen, {
				"camel": 0, "rabbit": 0, "fox": 0,
				"duck": 0, "dinosaur": 0, "robot": 0,
			})
			screen.call("_refresh_all", false)
			await process_frame
			for overtake: Node in screen.race_fx_layer.find_children("OvertakeBanner", "Label", true, false):
				overtake.queue_free()
		"rolling":
			screen.spinning = true
			screen.roll_button.text = "STOP!"
			screen.status_label.text = "ウサギの6を狙え！"
		"stopped":
			screen.call("_play_stop_assignment_feedback", QA_ASSIGNMENTS)
			screen.status_label.text = "ウサギ 6！"
		"final_stretch":
			_set_positions(screen, {
				"camel": 15, "rabbit": 20, "fox": 19,
				"duck": 17, "dinosaur": 18, "robot": 16,
			})
			screen.call("_refresh_all", false)
			await create_timer(0.42).timeout
			screen.call("_maybe_show_final_stretch")
		"win":
			_set_positions(screen, {
				"camel": 19, "rabbit": 24, "fox": 22,
				"duck": 20, "dinosaur": 21, "robot": 18,
			})
			screen.call("_refresh_all", false)
			await create_timer(0.42).timeout
			for overtake: Node in screen.race_fx_layer.find_children("OvertakeBanner", "Label", true, false):
				overtake.queue_free()
			screen.track_view.set_winner_presentation("rabbit")
			screen.call("_play_win_fx", screen.RACER_ART_PATHS["rabbit"], "ウサギ", 80)
			screen.status_label.text = "ウサギ WIN！ 80 CHIP獲得！"
		"cashout", "roll3":
			screen.race["roll_count"] = 3
			screen.race["cashout_offered"] = true
			screen.race["cashout_amount"] = 36
			screen.call("_after_roll_resolution")


func _configure_active_race(screen: DiceRaceScreen) -> void:
	screen.call("_select_racer", "rabbit")
	screen.race = RaceScript.new_race("rabbit", 20)
	_set_positions(screen, QA_POSITIONS)
	screen.wager_committed = true
	screen.setup_view.visible = false
	screen.race_view.visible = true
	screen.roll_button.disabled = false
	screen.current_assignments = QA_ASSIGNMENTS.duplicate()
	screen.call("_refresh_all", false)
	screen.status_label.text = "ウサギに20 CHIP。欲しい目を狙ってSTOP！"


func _set_positions(screen: DiceRaceScreen, positions: Dictionary) -> void:
	for racer_id: String in positions:
		(screen.race.racers.get(racer_id, {}) as Dictionary)["position"] = int(positions[racer_id])
