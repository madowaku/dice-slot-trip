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
	if not battle.show_for_qa():
		push_error("unable to enter chase capture")
		quit(1)
	var dir := DirAccess.open("res://artifacts")
	if dir != null:
		dir.make_dir_recursive("fox-fire-chase")
	for _frame: int in range(4):
		await process_frame
	var view := battle.get_node("View") as FoxFireChaseView
	view.begin_die_roll()
	for _frame: int in range(4):
		await process_frame
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("FOX_FIRE_CHASE_CAPTURE_SKIPPED renderer_has_no_viewport_texture")
		frame.free()
		quit()
		return
	if not _save_capture(frame, CAPTURE_DIR + "/fox-fire-chase-qa-720x1280.png"):
		print("FOX_FIRE_CHASE_CAPTURE_SKIPPED renderer_has_no_viewport_texture")
		frame.free()
		quit()
		return
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
