extends SceneTree

const BattleScene: PackedScene = preload("res://boss/kyoto/fox_fire_six_routes/FoxFireSixRoutesBattle.tscn")


func _init() -> void:
	call_deferred("_record")


func _record() -> void:
	print("FOX_FIRE_EFFECT_CAPTURE begin")
	var output_path := OS.get_environment("DICE_QA_OUTPUT")
	var effect_kind := OS.get_environment("DICE_QA_EFFECT")
	if output_path.is_empty() or effect_kind not in ["role", "blessing"]:
		push_error("DICE_QA_OUTPUT and DICE_QA_EFFECT=role|blessing are required")
		quit(2)
		return
	root.content_scale_size = Vector2i(720, 1280)
	root.size = Vector2i(720, 1280)
	var battle := BattleScene.instantiate() as FoxFireSixRoutesBattle
	root.add_child(battle)
	print("FOX_FIRE_EFFECT_CAPTURE scene_added")
	for _frame: int in range(4):
		await process_frame
	if not battle.configure_battle(5, {"kiyomizu": true, "tenryuji": true, "mangan": true}, 18, 3, 3, 80815):
		push_error("Unable to configure fox-fire effect capture")
		quit(1)
		return
	battle.set("_tutorial_seen", true)
	print("FOX_FIRE_EFFECT_CAPTURE configured")
	if not battle.show_for_qa(4):
		push_error("Unable to enter fox-fire effect QA state")
		quit(1)
		return
	var view := battle.get_node("View") as FoxFireSixRoutesView
	print("FOX_FIRE_EFFECT_CAPTURE qa_ready")
	view.dismiss_all_modals()
	view.refresh()
	if effect_kind == "role":
		view.call("_refresh_slot_faces", [4, 4, 4])
		view.role_label.text = "TRIPLE　同じ出目が3つ"
		view.play_slot_role_activation("TRIPLE")
	else:
		view.play_blessing_activation("tenryuji", "天龍寺のご加護", "出目 5 → 4　鳥居へぴったり！")
	for _frame: int in range(3):
		await process_frame
	print("FOX_FIRE_EFFECT_CAPTURE before_draw")
	RenderingServer.force_draw(false, 0.0)
	print("FOX_FIRE_EFFECT_CAPTURE after_draw")
	RenderingServer.force_sync()
	print("FOX_FIRE_EFFECT_CAPTURE after_sync")
	var image := root.get_texture().get_image()
	var result := image.save_png(output_path)
	print("FOX_FIRE_EFFECT_CAPTURE kind=%s size=%s result=%s" % [effect_kind, image.get_size(), result])
	battle.free()
	quit(0 if result == OK else 1)
