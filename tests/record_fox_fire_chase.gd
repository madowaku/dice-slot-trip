extends SceneTree

const BattleScene: PackedScene = preload("res://boss/kyoto/fox_fire_chase/FoxFireChaseBattle.tscn")
const CAPTURE_DIR := "res://artifacts/fox-fire-chase"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var battle := BattleScene.instantiate() as FoxFireChaseBattle
	var frame := SubViewport.new()
	frame.name = "FoxFireCaptureViewport"
	frame.size = Vector2i(720, 1280)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	frame.transparent_bg = false
	root.add_child(frame)
	frame.add_child(battle)
	root.size = Vector2i(720, 1280)
	battle.size = Vector2(720, 1280)
	battle.position = Vector2.ZERO
	for _frame: int in range(4):
		await process_frame
	if not battle.configure_battle(1, 2, 12, 3, 3, 0xF0CF1E):
		push_error("unable to configure chase capture")
		quit(1)
	var dir := DirAccess.open("res://artifacts")
	if dir != null:
		dir.make_dir_recursive("fox-fire-chase")
	for _frame: int in range(4):
		await process_frame
	var view := battle.get_node("View") as FoxFireChaseView
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("FOX_FIRE_CHASE_CAPTURE_SKIPPED renderer_has_no_viewport_texture")
		frame.free()
		quit()
		return
	battle.start_battle()
	for tutorial_page: int in range(3):
		for _frame: int in range(3):
			await process_frame
		_save_capture(frame, CAPTURE_DIR + "/tutorial-%d-720x1280.png" % (tutorial_page + 1))
		view.tutorial_button.emit_signal("pressed")
	if not battle.show_for_qa():
		push_error("unable to enter chase capture")
		quit(1)
		return
	for _frame: int in range(4):
		await process_frame
	view.begin_die_roll()
	for _frame: int in range(4):
		await process_frame
	if not _save_capture(frame, CAPTURE_DIR + "/fox-fire-chase-qa-720x1280.png"):
		print("FOX_FIRE_CHASE_CAPTURE_SKIPPED renderer_has_no_viewport_texture")
		frame.free()
		quit()
		return
	var controller := battle.get_node("Controller")
	var state := controller.get("state") as Object
	var six_event: Dictionary = controller.call("commit_face", 6)
	view.finish_die_roll(6)
	view.present_roll(six_event)
	view.action_banner.visible = false
	for _frame: int in range(3):
		await process_frame
	_save_capture(frame, CAPTURE_DIR + "/dice-six-sync-720x1280.png")
	state.set("slot_faces", [])
	view.finish_die_roll(4)
	view.present_roll({"face": 4, "fox_face": 3, "player_move": 7, "slot_role": "TRIPLE", "slot_bonus": 3, "completed_slot_faces": [4, 4, 4], "cat_path": [], "fox_path": []})
	for _frame: int in range(3):
		await process_frame
	_save_capture(frame, CAPTURE_DIR + "/slot-triple-720x1280.png")
	state.set("fox_fire_indices", {4: true})
	view.refresh()
	view.show_action_banner("狐火！ 外周が塞がれた", view.FIRE_BLUE, 2.0)
	for _frame: int in range(3):
		await process_frame
	_save_capture(frame, CAPTURE_DIR + "/fox-fire-warning-720x1280.png")
	state.set("fox_fire_indices", {})
	view.action_banner.visible = false
	view.refresh()
	battle.set_reduced_motion(true)
	frame.size = Vector2i(360, 640)
	battle.size = Vector2(360, 640)
	for _frame: int in range(4):
		await process_frame
	_save_capture(frame, CAPTURE_DIR + "/fox-fire-chase-qa-360x640.png")
	print("FOX_FIRE_CHASE_CAPTURED %s" % CAPTURE_DIR)
	frame.free()
	quit()


func _save_capture(frame: SubViewport, path: String) -> bool:
	var texture := frame.get_texture()
	if texture == null:
		return false
	var image: Image = texture.get_image()
	if image == null:
		return false
	return image.save_png(path) == OK
