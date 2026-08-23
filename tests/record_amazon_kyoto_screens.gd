extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/JourneyStageScreen.tscn")
const Aquafall := preload("res://scripts/game/aquafall_battle.gd")


func _init() -> void:
	call_deferred("_record")


func _record() -> void:
	var output_path := OS.get_environment("DICE_QA_OUTPUT")
	var stage_text := OS.get_environment("DICE_QA_STAGE")
	var state_name := OS.get_environment("DICE_QA_STATE")
	var viewport_text := OS.get_environment("DICE_QA_VIEWPORT")
	var rule_slide := clampi(int(OS.get_environment("DICE_QA_RULE_SLIDE")), 1, 4)
	if output_path.is_empty() or not stage_text in ["amazon", "kyoto"] or not state_name in ["map", "branch", "overview", "boss", "chase", "boss_tutorial", "boss_input", "direction", "collision", "role_effect", "boss_rules", "boss_practice", "heart_roulette", "item", "coin", "event", "menu", "rolled", "risk", "revival", "perfect"]:
		push_error("DICE_QA_OUTPUT, DICE_QA_STAGE, and DICE_QA_STATE are required")
		quit(2)
		return
	root.content_scale_size = Vector2i(720, 1280)
	var capture_size := Vector2i(720, 1280)
	if viewport_text == "360x640":
		capture_size = Vector2i(360, 640)
	elif viewport_text == "360x800":
		capture_size = Vector2i(360, 800)
	root.size = capture_size
	var screen: Control = ScreenScene.instantiate()
	screen.configure_start_context(StageCatalog.STAGE_AMAZON if stage_text == "amazon" else StageCatalog.STAGE_KYOTO)
	root.add_child(screen)
	for _ignored: int in range(8):
		await process_frame
	if state_name == "map":
		screen.call("_close_overview_map")
		# The first Kyoto launch follows the overview with the one-time goshuin
		# tutorial. Normal-map visual QA needs the unobscured playable state.
		for _ignored: int in range(4):
			await process_frame
		screen.call("_close_modal")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "branch":
		screen.call("_close_overview_map")
		for _ignored: int in range(4):
			await process_frame
		screen.call("_close_modal")
		var branch_journey := screen.get("journey") as StageJourneyBase
		if stage_text == "kyoto" and branch_journey is KyotoJourney:
			branch_journey.current_space_id = "main:31"
			branch_journey.phase = StageJourneyBase.PHASE_READY
			branch_journey.pending_event.clear()
			branch_journey.roll(6)
		else:
			var amazon_journey := branch_journey as AmazonJourney
			amazon_journey.current_space_id = "main:20"
			amazon_journey.phase = StageJourneyBase.PHASE_READY
			amazon_journey.pending_event.clear()
			amazon_journey.roll(4)
		screen.call("_show_branch_modal")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "overview":
		pass
	elif state_name == "boss":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_boss_for_qa")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "chase":
		if stage_text != "kyoto":
			push_error("chase state is only supported for kyoto")
			quit(2)
			return
		screen.call("_close_overview_map")
		screen.call("_close_modal")
		var chase_journey := screen.get("journey") as KyotoJourney
		chase_journey.phase = StageJourneyBase.PHASE_BOSS
		screen.call("_start_fox_fire_chase_boss", true, {})
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "boss_tutorial":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("_start_white_fox_boss")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "boss_input":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		# The visual QA state uses the first Lv3 schedule so the white-fire
		# preview is visible alongside the legal endpoint rings.
		var qa_journey := screen.get("journey") as KyotoJourney
		if qa_journey != null:
			qa_journey.lap = 5
		screen.call("show_boss_for_qa")
		for _ignored: int in range(8):
			await process_frame
		var routes_boss := screen.get("kyoto_boss_scene") as FoxFireSixRoutesBattle
		if routes_boss == null or not routes_boss.show_for_qa(4):
			push_error("fox fire six routes QA battle did not enter input state")
			quit(1)
			return
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "direction":
		if stage_text != "amazon":
			push_error("direction state is only supported for amazon")
			quit(2)
			return
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_boss_for_qa")
		for _ignored: int in range(8):
			await process_frame
		# Freeze a readable, non-random decision state: LEFT crosses a large
		# log while RIGHT lands on a small log. The battle preview itself must
		# remain pure; this setup only mutates the QA instance before rendering.
		var boss := screen.get("amazon_boss") as Aquafall
		if boss == null:
			push_error("amazon boss was not created")
			quit(1)
			return
		boss.lane = 3
		var seeded_obstacles: Array[Dictionary] = [
			{"type": "large_log", "lanes": [2], "relative_height": 1},
			{"type": "small_log", "lanes": [4], "relative_height": 1},
		]
		boss.obstacles = seeded_obstacles
		boss.request_roll(1)
		print("AQUAFALL_DIRECTION_PREVIEW left=%s right=%s obstacles=%s" % [boss.preview_direction(-1), boss.preview_direction(1), boss.obstacles])
		screen.call("_render_aquafall_boss")
		for _ignored: int in range(8):
			await process_frame
		var direction_buttons: Array[Node] = []
		for value: Node in screen.find_children("*", "Button", true, false):
			var candidate := value as Button
			if "左へ" in candidate.text or "右へ" in candidate.text:
				direction_buttons.append(candidate)
		var direction_ok := direction_buttons.size() == 2
		for value: Node in direction_buttons:
			var button := value as Button
			var rect := button.get_global_rect()
			var inside := rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= 720.0 and rect.end.y <= 1280.0
			print("AQUAFALL_DIRECTION_BUTTON text=%s rect=%s inside=%s" % [button.text, rect, inside])
			direction_ok = direction_ok and inside and ("着地：レーン" in button.text) and ("歩" in button.text) and ("安全" not in button.text) and ("流木接触" not in button.text)
		if not direction_ok:
			push_error("direction buttons are missing, clipped, or incomplete")
			quit(1)
			return
	elif state_name == "collision":
		if stage_text != "amazon":
			push_error("collision state is only supported for amazon")
			quit(2)
			return
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_boss_for_qa")
		for _ignored: int in range(8):
			await process_frame
		var collision_boss := screen.get("amazon_boss") as Aquafall
		if collision_boss == null:
			push_error("amazon collision QA boss was not created")
			quit(1)
			return
		collision_boss.lane = 3
		collision_boss.obstacles = [{"type": "large_log", "lanes": [2], "relative_height": 1}]
		collision_boss.request_roll(1)
		screen.call("_render_aquafall_boss")
		for _ignored: int in range(8):
			await process_frame
		screen.call("_aquafall_direction", -1)
		var saw_collision := false
		for _ignored: int in range(300):
			await process_frame
			var collision_status := screen.get("status_label") as Label
			if collision_status != null and collision_status.text.contains("大丸太に衝突"):
				saw_collision = true
				break
		if not saw_collision:
			push_error("amazon collision feedback was not visible")
			quit(1)
			return
	elif state_name == "role_effect":
		if stage_text != "amazon":
			push_error("role_effect state is only supported for amazon")
			quit(2)
			return
		var qa_role := OS.get_environment("DICE_QA_ROLE").to_upper()
		if qa_role not in ["PAIR", "STRAIGHT", "TRIPLE"]:
			qa_role = "TRIPLE"
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_boss_for_qa")
		for _ignored: int in range(8):
			await process_frame
		var role_boss := screen.get("amazon_boss") as Aquafall
		if role_boss != null:
			role_boss.obstacles = [
				{"type": "small_log", "lanes": [1], "relative_height": 3},
				{"type": "large_log", "lanes": [2, 3], "relative_height": 2},
				{"type": "small_log", "lanes": [5], "relative_height": 4},
			]
			screen.call("_render_aquafall_boss")
			for _ignored: int in range(6):
				await process_frame
		screen.call("_play_aquafall_role_effect", qa_role, "")
		for _ignored: int in range(10):
			await process_frame
	elif state_name == "boss_rules":
		if stage_text != "amazon":
			push_error("boss_rules state is only supported for amazon")
			quit(2)
			return
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		var qa_dice := screen.get("map_dice") as DicePresentation3D
		if qa_dice != null and qa_dice.viewport != null:
			qa_dice.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			qa_dice.visible = false
		screen.call("_show_boss_intro")
		for _ignored: int in range(8):
			await process_frame
		var rules_modal := screen.get("active_modal") as Control
		if rules_modal == null or rules_modal.name != "AquafallRulesModal":
			push_error("amazon boss rules modal did not open")
			quit(1)
			return
		for _slide_index: int in range(rule_slide - 1):
			var next_button := rules_modal.find_child("AquafallRulesNextButton", true, false) as Button
			if next_button != null:
				next_button.emit_signal("pressed")
				await process_frame
	elif state_name == "boss_practice":
		if stage_text != "amazon":
			push_error("boss_practice state is only supported for amazon")
			quit(2)
			return
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("_show_aquafall_practice_modal")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "heart_roulette":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		var roulette_journey := screen.get("journey") as StageJourneyBase
		if roulette_journey != null:
			roulette_journey.hp = 1
		screen.call("_show_heart_roulette")
		for _ignored: int in range(8):
			await process_frame
		var roulette_button := screen.find_child("HeartRouletteActionButton", true, false) as Button
		if roulette_button != null:
			roulette_button.emit_signal("pressed")
			for _ignored: int in range(18):
				await process_frame
	elif state_name == "item":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("_show_item_card")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "coin":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		var coin_journey := screen.get("journey") as StageJourneyBase
		if coin_journey != null:
			coin_journey.coins = 20
		screen.call("_show_coin_tool")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "event":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("_show_event_card_preview")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "menu":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("_show_menu_tool")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "rolled":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "risk":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_survival_state_for_qa", 2, 3)
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "revival":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_survival_state_for_qa", 3, 2)
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_roll_result_for_qa", 4)
		for _ignored: int in range(8):
			await process_frame
	elif state_name == "perfect":
		screen.call("_close_overview_map")
		for _ignored: int in range(8):
			await process_frame
		screen.call("show_survival_state_for_qa", 3, 3)
		screen.call("_show_boss_recovery_or_perfect")
		for _ignored: int in range(8):
			await process_frame
	if OS.get_environment("DICE_QA_FORCE_DRAW") == "1":
		RenderingServer.force_draw(false, 0.0)
		RenderingServer.force_sync()
	var image := root.get_texture().get_image()
	var result := image.save_png(output_path)
	print("JOURNEY_CAPTURE stage=%s state=%s size=%s result=%s" % [stage_text, state_name, image.get_size(), result])
	quit(0 if result == OK and image.get_size() == capture_size else 1)
