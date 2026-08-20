extends SceneTree

const SCREEN_SCENE: PackedScene = preload("res://scenes/app/JourneyStageScreen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(720, 1280)
	var amazon_ok := await _exercise(StageCatalog.STAGE_AMAZON)
	var kyoto_ok := await _exercise(StageCatalog.STAGE_KYOTO)
	print("JOURNEY_STAGE_MOTION_TESTS amazon=%s kyoto=%s failures=%d" % [amazon_ok, kyoto_ok, int(not amazon_ok) + int(not kyoto_ok)])
	quit(0 if amazon_ok and kyoto_ok else 1)


func _exercise(stage_id: StringName) -> bool:
	var screen := SCREEN_SCENE.instantiate() as JourneyStageScreen
	if screen == null:
		return false
	screen.configure_start_context(stage_id)
	root.add_child(screen)
	for _ignored: int in range(12):
		await process_frame
	screen.call("_close_overview_map")
	for _ignored: int in range(12):
		await process_frame
	var journey := screen.get("journey") as StageJourneyBase
	if journey == null:
		screen.queue_free()
		return false
	var start_space := journey.current_space_id
	screen.call("_begin_map_roll")
	for _ignored: int in range(18):
		await process_frame
	var rolling := bool(screen.get("map_roll_active"))
	var caption := screen.get("roll_caption_label") as Label
	var die_control := screen.get("map_dice") as Control
	var stop_copy_visible := caption != null and caption.text == "止める"
	var minimum_die_size := 152.0 if stage_id == StageCatalog.STAGE_KYOTO else 150.0
	var map_die_enlarged := die_control != null and die_control.size.x >= minimum_die_size and die_control.size.y >= minimum_die_size
	var map_die_right_docked := die_control != null and die_control.get_global_rect().get_center().x >= 720.0 * 0.65
	var map_die_centered := die_control != null and absf(die_control.get_global_rect().get_center().x - 360.0) <= 8.0
	screen.call("_stop_map_roll")
	await create_timer(2.8).timeout
	# Camera recropping can schedule a deferred map-node rebuild. Give that final
	# traveler placement a few frames before checking the foot anchor.
	for _ignored: int in range(4):
		await process_frame
	var slots: Array = screen.get("roll_slots")
	var moved := journey.current_space_id != start_space
	var settled := not bool(screen.get("map_roll_active")) and not bool(screen.get("map_movement_active")) and not bool(screen.get("roll_animation_active"))
	var die := screen.get("map_dice") as DicePresentation3D
	var die_locked := die != null and die.state_name(0) in ["LOCKED", "SETTLING"]
	var map_layer := screen.get("map_node_layer") as Control
	var camera_follow_settled := map_layer != null and is_zero_approx(map_layer.position.y)
	var route_row := screen.get("route_preview_row") as HBoxContainer
	var route_refreshed := route_row != null and route_row.get_child_count() == 7
	var player := screen.get("map_player") as Control
	var expected_player_position := screen.call("_map_player_position_for_space", journey.current_space_id) as Vector2
	var player_settled := player != null and player.position.distance_to(expected_player_position) < 0.75
	var player_view_y := float((screen.call("_map_normalized_for_space", journey.current_space_id) as Vector2).y)
	var camera_bias_ok := player_view_y <= 0.30 if stage_id == StageCatalog.STAGE_AMAZON else player_view_y >= 0.60 and player_view_y <= 0.72
	var die_dock_ok := map_die_centered if stage_id == StageCatalog.STAGE_KYOTO else map_die_right_docked
	var ok := rolling and stop_copy_visible and map_die_enlarged and die_dock_ok and slots.size() == 1 and moved and settled and die_locked and camera_follow_settled and route_refreshed and player_settled and camera_bias_ok
	print("MOTION stage=%s rolling=%s stop_copy=%s die_size=%s die_dock=%s player_view_y=%.2f slots=%s start=%s end=%s settled=%s die=%s camera=%s route=%s player=%s player_pos=%s expected=%s" % [String(stage_id), rolling, stop_copy_visible, die_control.size if die_control != null else Vector2.ZERO, die_dock_ok, player_view_y, slots, start_space, journey.current_space_id, settled, die_locked, camera_follow_settled, route_refreshed, player_settled, player.position if player != null else Vector2.ZERO, expected_player_position])
	screen.queue_free()
	await process_frame
	return ok
