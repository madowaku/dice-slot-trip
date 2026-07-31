extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(UiTokensScript.BASE_VIEWPORT)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var host := Control.new()
	host.size = UiTokensScript.BASE_VIEWPORT
	viewport.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	screen.call("_on_map_closed")
	await process_frame
	var tile_index := clampi(OS.get_environment("DICE_QA_V14_TILE").to_int(), 0, 57)
	var atlas := screen.get_node("%AtlasView")
	atlas.set_route_position({"route_id": "main", "tile_index": tile_index}, true)
	await create_timer(0.35).timeout
	for ignored: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.force_sync()
	var image := viewport.get_texture().get_image()
	var path := OS.get_environment("DICE_QA_CAPTURE_PATH")
	if path.is_empty():
		path = "res://docs/reference/v14-atlas-scenery.png"
	var result := image.save_png(path)
	var path_360 := OS.get_environment("DICE_QA_CAPTURE_360_PATH")
	if not path_360.is_empty():
		var image_360 := image.duplicate()
		image_360.resize(360, 640, Image.INTERPOLATE_LANCZOS)
		result = image_360.save_png(path_360) if result == OK else result
	print("V14_ATLAS_CAPTURE tile=%d path=%s result=%s" % [tile_index, path, result])
	quit(0 if result == OK else 1)
