extends SceneTree

const SCREEN_SCENE: PackedScene = preload("res://scenes/app/JourneyStageScreen.tscn")
const AquafallBattle := preload("res://scripts/game/aquafall_battle.gd")
const FOX_FIRE_CHASE_SCENE: PackedScene = preload("res://boss/kyoto/fox_fire_chase/FoxFireChaseBattle.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(720, 1280)
	await _check_kyoto_chase_scene_contract()
	await _exercise(StageCatalog.STAGE_AMAZON)
	await _exercise_aquafall_rules_mobile()
	await _exercise(StageCatalog.STAGE_KYOTO)
	print("JOURNEY_STAGE_UI_REGRESSION_TESTS failures=%d" % failures.size())
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _check_kyoto_chase_scene_contract() -> void:
	var battle := FOX_FIRE_CHASE_SCENE.instantiate() as Control
	_expect(battle != null, "Kyoto 狐火追陣 scene instantiates")
	if battle == null:
		return
	root.add_child(battle)
	for _ignored: int in range(2):
		await process_frame
	var configured := bool(battle.call("configure_battle", 5, 2, 12, 3, 3, 20260820, {}))
	_expect(configured, "Kyoto 狐火追陣 host contract accepts lap/goshuin/coins/hp/max_hp/seed/snapshot")
	var snapshot := battle.call("snapshot") as Dictionary
	_expect(str(snapshot.get("battle_id", "")) == "fox_fire_chase", "Kyoto 狐火追陣 scene exposes chase snapshot id")
	battle.queue_free()
	await process_frame


func _exercise(stage_id: StringName) -> void:
	var screen := SCREEN_SCENE.instantiate() as JourneyStageScreen
	_expect(screen != null, "%s screen scene instantiates" % String(stage_id))
	if screen == null:
		return
	screen.configure_start_context(stage_id)
	root.add_child(screen)
	for _ignored: int in range(12):
		await process_frame
	await _check_overview_and_event_choices(screen, stage_id)
	screen.call("_close_overview_map")
	for _ignored: int in range(12):
		await process_frame
	if stage_id == StageCatalog.STAGE_KYOTO:
		await _check_kyoto_goshuin_tutorial(screen)

	var journey := screen.get("journey") as StageJourneyBase
	_expect(journey != null, "%s journey exists" % String(stage_id))
	if journey == null:
		screen.queue_free()
		return
	_check_hud(screen, journey, stage_id)
	await _check_item_card(screen, journey, stage_id)
	await _check_skill_ready_discovery(screen, journey, stage_id)
	if stage_id == StageCatalog.STAGE_KYOTO:
		await _check_kyoto_goshuin_stamp(screen, journey)
	_check_normal_icon(screen, stage_id)
	_check_slot_roles(screen, stage_id)
	if stage_id == StageCatalog.STAGE_KYOTO:
		_check_fox_fire_role_charge(screen, journey)
	_check_three_roll_cycle(screen, journey, stage_id)
	if stage_id == StageCatalog.STAGE_AMAZON:
		await _check_amazon_branch_choices(screen, journey)
	else:
		await _check_kyoto_branch_choices(screen, journey)
	await _check_route_preview_and_player_anchor(screen, journey, stage_id)
	if stage_id == StageCatalog.STAGE_KYOTO:
		await _check_kyoto_detour_geometry(screen, journey as KyotoJourney)
		await _check_kyoto_boss_choice_copy(screen, journey as KyotoJourney)
	await _check_boss_marker(screen, journey, stage_id)
	if stage_id == StageCatalog.STAGE_AMAZON:
		await _check_aquafall_rules_modal(screen)
		await _check_aquafall_boss_roll_surface(screen, journey)
		await _check_aquafall_collision_feedback(screen, journey)
		await _check_aquafall_role_effects(screen, journey)
		await _check_aquafall_victory_modal(screen, journey)
		await _check_journey_heart_roulette(screen, journey)
		await _check_aquafall_late_lap_tutorial_skip(screen, journey)
	else:
		await _check_fox_fire_chase_chrome(screen, journey)

	screen.queue_free()
	await process_frame


func _check_amazon_branch_choices(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	var amazon := journey as AmazonJourney
	if amazon == null:
		return
	amazon.current_space_id = "main:20"
	amazon.phase = StageJourneyBase.PHASE_READY
	amazon.pending_event.clear()
	var arrival := amazon.roll(4)
	_expect(str(arrival.get("status", "")) == "CHOICE_REQUIRED" and amazon.phase == StageJourneyBase.PHASE_BRANCH,
		"Amazon branch test reaches the first route junction")
	screen.call("_show_branch_modal")
	await process_frame
	var modal := screen.get("active_modal") as Control
	var buttons := modal.find_children("*", "Button", true, false) if modal != null else []
	_expect(buttons.size() == 2, "Amazon route modal exposes two choices")
	var branch_copy := _all_label_text(modal)
	_expect(branch_copy.contains("本線") and branch_copy.contains("脇道"),
		"Amazon route modal labels the main route and detour distinctly")
	_expect(branch_copy.contains("回復") or branch_copy.contains("急流") or branch_copy.contains("通常"),
		"Amazon route modal names the projected tile type")
	_expect(not branch_copy.contains("canopy:") and not branch_copy.contains("stream:") and not branch_copy.contains("main:"),
		"Amazon route modal hides internal route IDs from player copy")
	for choice_index: int in range(mini(buttons.size(), 2)):
		var button := buttons[choice_index] as Button
		_expect(button != null and not button.disabled and button.get_global_rect().size.y >= 52.0,
			"Amazon route choice %d is enabled and touch-sized" % (choice_index + 1))
	if buttons.size() < 2:
		return
	(buttons[0] as Button).emit_signal("pressed")
	for _ignored: int in range(40):
		await process_frame
	_expect(amazon.phase != StageJourneyBase.PHASE_BRANCH and amazon.current_space_id != "main:20",
		"Amazon first route choice advances past the junction")
	screen.call("_close_modal")
	amazon.current_space_id = "main:20"
	amazon.phase = StageJourneyBase.PHASE_READY
	amazon.pending_event.clear()
	var second_arrival := amazon.roll(4)
	_expect(str(second_arrival.get("status", "")) == "CHOICE_REQUIRED" and amazon.phase == StageJourneyBase.PHASE_BRANCH,
		"Amazon route can be reopened for the second choice")
	screen.call("_show_branch_modal")
	await process_frame
	modal = screen.get("active_modal") as Control
	buttons = modal.find_children("*", "Button", true, false) if modal != null else []
	_expect(buttons.size() == 2, "Amazon route modal keeps both choices on reopen")
	if buttons.size() == 2:
		(buttons[1] as Button).emit_signal("pressed")
		for _ignored: int in range(40):
			await process_frame
		_expect(amazon.phase != StageJourneyBase.PHASE_BRANCH and amazon.current_space_id != "main:20",
			"Amazon second route choice advances past the junction")
	for choice_index: int in range(2):
		amazon.current_space_id = "main:19"
		amazon.phase = StageJourneyBase.PHASE_READY
		amazon.pending_event.clear()
		var exact_arrival := amazon.roll(3)
		_expect(str(exact_arrival.get("status", "")) == "CHOICE_REQUIRED" and amazon.pending_steps == 1,
			"Amazon exact junction landing keeps a selectable route entry")
		screen.call("_show_branch_modal")
		await process_frame
		modal = screen.get("active_modal") as Control
		buttons = modal.find_children("*", "Button", true, false) if modal != null else []
		_expect(buttons.size() == 2 and not (buttons[choice_index] as Button).disabled,
			"Amazon exact junction choice %d remains enabled" % (choice_index + 1))
		if buttons.size() == 2:
			(buttons[choice_index] as Button).emit_signal("pressed")
			for _ignored: int in range(40):
				await process_frame
			_expect(amazon.current_space_id != "main:22" and amazon.phase != StageJourneyBase.PHASE_BRANCH,
				"Amazon exact junction choice %d advances past the fork" % (choice_index + 1))


func _check_kyoto_branch_choices(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	var kyoto := journey as KyotoJourney
	if kyoto == null:
		return
	kyoto.current_space_id = "main:31"
	kyoto.phase = StageJourneyBase.PHASE_READY
	kyoto.pending_event.clear()
	var arrival := kyoto.roll(6)
	_expect(str(arrival.get("status", "")) == "CHOICE_REQUIRED" and kyoto.phase == StageJourneyBase.PHASE_BRANCH,
		"Kyoto branch test reaches the first shortcut junction")
	screen.call("_show_branch_modal")
	await process_frame
	var modal := screen.get("active_modal") as Control
	var buttons := modal.find_children("*", "Button", true, false) if modal != null else []
	var branch_copy := _all_label_text(modal)
	_expect(buttons.size() == 2 and branch_copy.contains("本線") and branch_copy.contains("近道"),
		"Kyoto route modal shows both route classes and projected stops")
	_expect(branch_copy.contains("通常") or branch_copy.contains("御朱印") or branch_copy.contains("ダメージ") or branch_copy.contains("回復"),
		"Kyoto route modal names the projected tile type")
	_expect(not branch_copy.contains("RISK") and not branch_copy.contains("REST"),
		"Kyoto route modal localizes projected landing kinds")
	for button_value: Variant in buttons:
		var route_button := button_value as Button
		_expect(route_button != null and route_button.icon != null,
			"Kyoto route choices pair landing labels with semantic icons")
	_expect(not branch_copy.contains("gion_shortcut:") and not branch_copy.contains("main:"),
		"Kyoto route modal hides internal route IDs from player copy")
	screen.call("_close_modal")
	kyoto.current_space_id = "main:1"
	kyoto.pending_steps = 0
	kyoto.pending_choices.clear()
	kyoto.pending_event.clear()
	kyoto.phase = StageJourneyBase.PHASE_READY


func _check_boss_marker(screen: JourneyStageScreen, journey: StageJourneyBase, stage_id: StringName) -> void:
	var boss_space := "main:120" if stage_id == StageCatalog.STAGE_AMAZON else "main:90"
	journey.current_space_id = boss_space
	screen.call("_render_map")
	for _ignored: int in range(8):
		await process_frame
	var layer := screen.get("map_node_layer") as Control
	var marker: Control = null
	if layer != null:
		marker = layer.get_node_or_null("space_%s" % boss_space.replace(":", "_")) as Control
	if stage_id == StageCatalog.STAGE_KYOTO:
		var row := screen.get("route_preview_row") as HBoxContainer
		var boss_card: Control = null
		if row != null:
			for child: Node in row.get_children():
				var candidate := child as Control
				if candidate != null and str(candidate.get_meta("space_id", "")) == boss_space:
					boss_card = candidate
					break
		var card_emblem_found := false
		if boss_card != null:
			for child: Node in boss_card.find_children("*", "Control", true, false):
				var child_script: Script = child.get_script() as Script
				if child_script != null and str(child_script.resource_path).ends_with("boss_map_emblem.gd"):
					card_emblem_found = true
					break
		_expect(boss_card != null and boss_card.get_global_rect().size.y >= 116.0,
			"Kyoto boss destination remains large in the current-to-+6 horizon")
		_expect(card_emblem_found, "Kyoto boss card uses the shared crown emblem")
		return
	_expect(marker != null and marker.size.x >= 64.0 and marker.size.y >= 64.0,
		"%s boss map marker is larger than ordinary route markers" % String(stage_id))
	var emblem_found := false
	if marker != null:
		for child: Node in marker.get_children():
			var child_script: Script = child.get_script() as Script
			if child_script != null and str(child_script.resource_path).ends_with("boss_map_emblem.gd"):
				emblem_found = true
				break
	_expect(emblem_found, "%s boss map marker uses the shared crown emblem" % String(stage_id))


func _check_kyoto_boss_choice_copy(screen: JourneyStageScreen, journey: KyotoJourney) -> void:
	if journey == null:
		return
	var saved := journey.snapshot()
	journey.current_space_id = "main:87"
	journey.phase = StageJourneyBase.PHASE_READY
	var choice_result := journey.roll(1)
	_expect(str(choice_result.get("status", "")) == "BOSS_CHOICE_REQUIRED",
		"Kyoto final fork reaches the boss-choice presentation")
	screen.call("_show_kyoto_boss_choice_modal")
	await process_frame
	var modal := screen.get("active_modal") as Control
	var copy := _all_label_text(modal)
	_expect(copy.contains("狐火追陣") and copy.contains("狐火六路陣") and not copy.contains("白狐決戦"),
		"Kyoto final fork clearly offers chase and puzzle routes")
	screen.call("_close_modal")
	journey.restore(saved)
	journey.stage_flags["kyoto_boss_route"] = "direct"
	screen.call("_refresh_all")
	var route_label := screen.get("stage_route_label") as Label
	_expect(route_label != null and route_label.text.contains("追陣") and route_label.text.contains("御朱印"),
		"Kyoto HUD names the selected direct route as 狐火追陣")
	_expect(str(screen.call("_kyoto_boss_restore_target", "direct", {"battle_id": "fox_fire_chase"})) == "chase",
		"Kyoto restore dispatches chase snapshots to 狐火追陣")
	_expect(str(screen.call("_kyoto_boss_restore_target", "direct", {"seals": []})) == "legacy_direct",
		"Kyoto restore keeps schema-v1 direct seal saves compatible")
	_expect(str(screen.call("_kyoto_boss_restore_target", "foxfire", {"battle_id": "fox_fire_six_routes"})) == "six_routes",
		"Kyoto restore preserves the 狐火六路陣 route")
	var coins_before := journey.coins
	journey.coins = 7
	screen.call("_on_fox_fire_chase_coins_spent", 3)
	_expect(journey.coins == 4, "Kyoto chase head-start spending immediately updates journey coins")
	journey.coins = coins_before
	journey.restore(saved)
	screen.call("_render_map")
	screen.call("_refresh_all")


func _exercise_aquafall_rules_mobile() -> void:
	root.size = Vector2i(360, 640)
	root.content_scale_size = Vector2i(360, 640)
	var screen := SCREEN_SCENE.instantiate() as JourneyStageScreen
	root.add_child(screen)
	for _ignored: int in range(12):
		await process_frame
	screen.call("_close_overview_map")
	for _ignored: int in range(8):
		await process_frame
	screen.call("_show_boss_intro")
	for _ignored: int in range(8):
		await process_frame
	var modal := screen.get("active_modal") as Control
	var panel := modal.get_node_or_null("AquafallRulesPanel") as Control if modal != null else null
	var next_button := modal.find_child("AquafallRulesNextButton", true, false) as Button if modal != null else null
	var prev_button := modal.find_child("AquafallRulesPrevButton", true, false) as Button if modal != null else null
	_expect(panel != null and next_button != null and prev_button != null, "amazon rules slide deck renders on a 360x640 viewport")
	if panel != null:
		var rect := panel.get_global_rect()
		_expect(rect.position.x >= 0.0 and rect.end.x <= 360.0 and rect.position.y >= 0.0 and rect.end.y <= 640.0,
			"amazon rules modal stays inside the mobile viewport")
	if next_button != null:
		var button_rect := next_button.get_global_rect()
		_expect(button_rect.position.x >= 0.0 and button_rect.end.x <= 360.0 and button_rect.end.y <= 640.0 and button_rect.size.y >= 52.0,
			"amazon rules modal mobile next action is visible and touch-sized")
	for _slide_step: int in range(3):
		if next_button != null:
			next_button.emit_signal("pressed")
		await process_frame
	var start_button := modal.find_child("AquafallRulesStartButton", true, false) as Button if modal != null else null
	_expect(start_button != null and start_button.visible, "amazon rules modal exposes the start action on the final slide")
	if start_button != null:
		var start_rect := start_button.get_global_rect()
		_expect(start_rect.position.x >= 0.0 and start_rect.end.x <= 360.0 and start_rect.end.y <= 640.0 and start_rect.size.y >= 52.0,
			"amazon rules modal mobile start action is visible and touch-sized")
	screen.call("_close_modal")
	var journey := screen.get("journey") as StageJourneyBase
	if journey != null:
		journey.phase = StageJourneyBase.PHASE_BOSS
		journey.hp = StageJourneyBase.MAX_HEARTS
		screen.call("_start_aquafall_boss")
		for _ignored: int in range(4):
			await process_frame
		screen.call("_show_boss_recovery_or_perfect")
		for _ignored: int in range(4):
			await process_frame
		var victory_modal := screen.get("active_modal") as Control
		var victory_panel := victory_modal.get_node_or_null("AquafallVictoryPanel") as Control if victory_modal != null else null
		var victory_button := victory_modal.find_child("AquafallVictoryContinueButton", true, false) as Button if victory_modal != null else null
		_expect(victory_panel != null and victory_button != null, "amazon victory modal renders on a 360x640 viewport")
		if victory_panel != null:
			var victory_rect := victory_panel.get_global_rect()
			_expect(victory_rect.position.x >= 0.0 and victory_rect.end.x <= 360.0 and victory_rect.position.y >= 0.0 and victory_rect.end.y <= 640.0,
				"amazon victory modal stays inside the mobile viewport")
		screen.call("_close_modal")
	screen.queue_free()
	await process_frame
	root.size = Vector2i(720, 1280)
	root.content_scale_size = Vector2i(720, 1280)


func _check_kyoto_goshuin_tutorial(screen: JourneyStageScreen) -> void:
	var modal := screen.get("active_modal") as Control
	_expect(modal != null, "Kyoto opens the goshuin explanation after the initial map sweep")
	if modal == null:
		return
	var tutorial_art_found := false
	for value: Node in modal.find_children("*", "TextureRect", true, false):
		var texture_rect := value as TextureRect
		if texture_rect != null and texture_rect.texture != null and texture_rect.texture.resource_path.ends_with("kyoto-goshuin-tutorial.png"):
			tutorial_art_found = true
			break
	_expect(tutorial_art_found, "Kyoto goshuin tutorial uses the generated explanation artwork")
	var buttons := modal.find_children("*", "Button", true, false)
	_expect(buttons.size() == 1, "Kyoto goshuin tutorial has one acknowledgement action")
	if buttons.size() == 1:
		(buttons[0] as Button).emit_signal("pressed")
	for _ignored: int in range(3):
		await process_frame
	var journey := screen.get("journey") as KyotoJourney
	_expect(journey != null and bool(journey.stage_flags.get("kyoto_goshuin_tutorial_seen", false)),
		"Kyoto goshuin tutorial acknowledgement is persisted in stage flags")
	_expect(screen.get("active_modal") == null, "Kyoto goshuin tutorial closes after acknowledgement")


func _check_overview_and_event_choices(screen: JourneyStageScreen, stage_id: StringName) -> void:
	var overview_layer := screen.get("overview_node_layer") as Control
	if stage_id == StageCatalog.STAGE_KYOTO:
		var route_nodes := 0
		if overview_layer != null:
			for child: Node in overview_layer.get_children():
				if child is PanelContainer:
					route_nodes += 1
		_expect(route_nodes == 99,
			"Kyoto overview includes 90 main spaces plus 9 shortcut spaces")
		var route_lines := 0
		var main_line_points := 0
		if overview_layer != null:
			for child: Node in overview_layer.get_children():
				if child is Line2D:
					route_lines += 1
					main_line_points = maxi(main_line_points, (child as Line2D).points.size())
		_expect(route_lines == 3 and main_line_points == 90,
			"Kyoto overview draws one main spine and two documented shortcut routes")
		var gion_centers: Array[Vector2] = []
		for route_id: String in ["gion_shortcut:S1", "gion_shortcut:S2", "gion_shortcut:S3", "gion_shortcut:S4", "arashiyama_shortcut:S1", "arashiyama_shortcut:S2", "arashiyama_shortcut:S3", "arashiyama_shortcut:S4", "arashiyama_shortcut:S5"]:
			var detour_marker := _find_overview_node(overview_layer, route_id)
			if detour_marker != null:
				gion_centers.append(detour_marker.position + detour_marker.size * 0.5)
		var detour_spacing_ok := true
		for left_index: int in range(gion_centers.size()):
			for right_index: int in range(left_index + 1, gion_centers.size()):
				# Different loops are allowed to pass nearby, but no two short-loop
				# checkpoints should be literally stacked on the same pixel.
				detour_spacing_ok = detour_spacing_ok and gion_centers[left_index].distance_to(gion_centers[right_index]) >= 8.0
		_expect(detour_spacing_ok, "Kyoto short detour checkpoints keep separate overview positions")
		var map_view := screen.get("overview_overlay") as Control
		var overview_map := map_view.find_child("OverviewMapView", true, false) if map_view != null else null
		var overview_control := overview_map as Control
		_expect(overview_control != null and overview_control.size.y > 0.0 and overview_control.size.x / overview_control.size.y < 0.7,
			"Kyoto overview preserves the portrait route aspect")
		_expect(overview_control != null and overview_control.size.y >= 700.0,
			"Kyoto overview uses a large readable map viewport")
		var boss_marker: Control = null
		if overview_layer != null:
			boss_marker = _find_overview_node(overview_layer, "90")
		_expect(boss_marker != null and boss_marker.size.x >= 64.0 and boss_marker.size.y >= 64.0,
			"Kyoto overview keeps a large boss crest marker")
	else:
		_expect(overview_layer != null, "Amazon overview layer exists")
		var journey := screen.get("journey") as AmazonJourney
		if journey == null:
			return
		var boss_marker: Control = null
		if overview_layer != null:
			boss_marker = _find_overview_node(overview_layer, "120")
		_expect(boss_marker != null and boss_marker.size.x >= 64.0 and boss_marker.size.y >= 64.0,
			"Amazon overview keeps a large boss crest marker")
		var map_view := screen.get("overview_overlay") as Control
		var overview_map := map_view.find_child("OverviewMapView", true, false) if map_view != null else null
		_expect(overview_map != null and (overview_map as Control).size.y >= 700.0,
			"Amazon overview uses a large readable map viewport")
		var amazon_overview_lines := overview_layer.find_children("OverviewRouteLine", "Line2D", true, false)
		_expect(amazon_overview_lines.size() > 0, "Amazon overview draws route connectors behind its markers")
		journey.current_space_id = "main:9"
		journey.phase = StageJourneyBase.PHASE_READY
		journey.pending_event.clear()
		journey.call("_resolve_landing", true)
		screen.call("_show_event_modal")
		for _ignored: int in range(3):
			await process_frame
		var modal := screen.get("active_modal") as Control
		var buttons := modal.find_children("*", "Button", true, false) if modal != null else []
		_expect(buttons.size() == 2, "Amazon forest spirit event presents both choices")
		screen.call("_close_modal")


func _check_aquafall_boss_roll_surface(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.phase = StageJourneyBase.PHASE_BOSS
	screen.call("_start_aquafall_boss")
	for _ignored: int in range(4):
		await process_frame
	var boss := screen.get("amazon_boss") as AquafallBattle
	var roll_button := screen.get("roll_button") as BaseButton
	var labels: Array = screen.get("roll_slot_labels")
	var dice := screen.get("map_dice") as Control
	_expect(boss != null and roll_button != null and labels.size() == 3 and dice != null,
		"amazon boss reuses the roll button, three-slot tray, and rotating die surface")
	var player := screen.find_child("AquafallPlayer", true, false) as Control
	var info := screen.find_child("AquafallInfo", true, false) as Control
	var gauge := screen.find_child("AquafallHeightGauge", true, false) as Control
	var step_counter := screen.find_child("AquafallStepCounter", true, false) as Label
	var height_ticks := screen.find_children("AquafallHeightTick_*", "ColorRect", true, false)
	var log_nodes := screen.find_children("AquafallLog_*", "Panel", true, false)
	_expect(player != null and dice.get_global_rect().size.x <= 124.0 and dice.get_global_rect().size.y <= 124.0,
		"amazon boss keeps the live die compact")
	if player != null:
		_expect(not dice.get_global_rect().intersects(player.get_global_rect()),
			"amazon boss die stays clear of the explorer hop rail")
	if info != null:
		_expect(dice.get_global_rect().position.y >= info.get_global_rect().end.y + 4.0,
			"amazon boss die dock stays below the waterfall status card")
		_expect((info as Label).text.contains("GOALまで あと") and (info as Label).text.contains("現在レーン"),
			"amazon boss field HUD groups goal distance, health, and current lane")
	_expect(player != null and player.size.x >= 76.0,
		"amazon boss explorer is large enough to read against the waterfall")
	_expect(gauge != null and gauge.get_global_rect().size.y >= 180.0 and height_ticks.size() >= 5,
		"amazon boss exposes a vertical goal scale and one-step height guides")
	_expect(gauge != null and gauge.get_node_or_null("AquafallGoalIcon") is TextureRect and gauge.get_node_or_null("AquafallHeightCurrent") is TextureRect,
		"amazon boss goal scale uses generated goal art and a cat current-position marker")
	_expect(step_counter != null and not step_counter.visible,
		"amazon boss reserves a transient per-step counter without covering idle play")
	_expect(log_nodes.size() > 0, "amazon boss renders visible log frames")
	var emphasized_log := false
	for value: Node in log_nodes:
		var frame := value as Panel
		var style := frame.get_theme_stylebox("panel") as StyleBoxFlat if frame != null else null
		if style != null and style.shadow_size >= 5 and style.border_width_left >= 2:
			emphasized_log = true
			break
	_expect(emphasized_log, "amazon boss logs use a shadowed high-contrast frame")
	# Mix small, large, and multi-lane logs so the timing check covers every
	# visual segment, not only whichever random obstacle spawned first.
	boss.obstacles = [
		{"type": "small_log", "lanes": [1], "relative_height": 4},
		{"type": "large_log", "lanes": [2, 3], "relative_height": 6},
		{"type": "small_log", "lanes": [5], "relative_height": 7},
	]
	screen.call("_render_aquafall_boss")
	for _ignored: int in range(4):
		await process_frame
	screen.call("_aquafall_roll")
	for _ignored: int in range(3):
		await process_frame
	_expect(bool(screen.get("amazon_boss_roll_active")), "amazon boss roll starts a visible rotating die state")
	screen.call("_aquafall_roll")
	for _ignored: int in range(6):
		await process_frame
	var direction_buttons: Array[Node] = []
	for button_name: String in ["AquafallLeftButton", "AquafallRightButton"]:
		var button := screen.find_child(button_name, true, false) as Button
		if button != null:
			direction_buttons.append(button)
	_expect(boss.phase == AquafallBattle.PHASE_WAIT_DIRECTION and direction_buttons.size() == 2,
		"amazon boss stop reveals exactly two left/right direction buttons")
	for value: Node in direction_buttons:
		var button := value as Button
		_expect((button.text.contains("左へ") or button.text.contains("右へ")) and button.text.contains("歩") and not button.text.contains("安全") and not button.text.contains("流木接触"),
			"amazon direction choice uses clear left/right copy without safety verdicts")
	# Stopping the die rebuilds the boss surface, so sample the live visual nodes
	# that will participate in the per-step animation.
	var lane_area := screen.get("aquafall_lane_layer") as Control
	player = screen.get("aquafall_player_sprite") as Control
	step_counter = lane_area.get_node_or_null("AquafallStepCounter") as Label if lane_area != null else null
	log_nodes = lane_area.find_children("AquafallLog_*", "Panel", true, false) if lane_area != null else []
	boss.pending_face = 3
	var side_margin := float(lane_area.get_meta("side_margin", 24.0)) if lane_area != null else 24.0
	var lane_width := float(lane_area.get_meta("lane_width", 80.0)) if lane_area != null else 80.0
	var row_step := float(lane_area.get_meta("row_step", 40.0)) if lane_area != null else 40.0
	var log_start_positions: Array[Vector2] = []
	for value: Node in log_nodes:
		log_start_positions.append((value as Control).position)
	_expect(log_nodes.size() == 4,
		"amazon timing fixture renders small and multi-lane large log segments")
	var small_log_frame: Control = null
	var large_log_frame: Control = null
	var distinct_log_art := true
	for value: Node in log_nodes:
		var frame := value as Control
		var art := frame.get_node_or_null("AquafallLogTexture") as TextureRect if frame != null else null
		var log_type := str(frame.get_meta("log_type", "")) if frame != null else ""
		if log_type == "large_log":
			large_log_frame = frame
			distinct_log_art = distinct_log_art and art != null and art.texture.resource_path.ends_with("aquafall-large-log-v2.png")
		else:
			small_log_frame = frame
			distinct_log_art = distinct_log_art and art != null and art.texture.resource_path.ends_with("aquafall-small-log-v2.png")
	_expect(distinct_log_art and small_log_frame != null and large_log_frame != null and large_log_frame.size.y >= small_log_frame.size.y * 1.3,
		"amazon small and large logs use distinct generated silhouettes and scale")
	var small_style := small_log_frame.get_theme_stylebox("panel") as StyleBoxFlat if small_log_frame != null else null
	var large_style := large_log_frame.get_theme_stylebox("panel") as StyleBoxFlat if large_log_frame != null else null
	_expect(large_log_frame != null and large_log_frame.size.x <= lane_width * 1.02,
		"amazon large-log segments stay inside their lane without overlap")
	_expect(small_style != null and large_style != null and small_style.bg_color.r > 0.8 and large_style.bg_color.r < 0.3,
		"amazon small logs use a light plate while large logs keep a dark warning plate")
	screen.call("_aquafall_direction", -1)
	await process_frame
	_expect(step_counter != null and step_counter.visible and step_counter.text == "LEFT ×3" and not (direction_buttons[0] as Button).visible and not (direction_buttons[1] as Button).visible,
		"amazon direction locks once, announces LEFT x3, and removes mid-hop choices")
	await create_timer(0.46).timeout
	var smallest_mid_delta := INF
	var largest_mid_delta := -INF
	for log_index: int in range(mini(log_nodes.size(), log_start_positions.size())):
		var moving_log := log_nodes[log_index] as Control
		var delta_y := moving_log.position.y - log_start_positions[log_index].y
		smallest_mid_delta = minf(smallest_mid_delta, delta_y)
		largest_mid_delta = maxf(largest_mid_delta, delta_y)
	_expect(smallest_mid_delta > 0.1 and largest_mid_delta - smallest_mid_delta <= 0.2,
		"all small and large log segments share the same in-flight progress")
	var reached_first_step := false
	for _ignored: int in range(100):
		await process_frame
		if int(screen.get("aquafall_animation_step")) >= 1:
			reached_first_step = true
			break
	var expected_lane_2_x := side_margin + lane_width + (lane_width - player.size.x) * 0.5 if player != null else 0.0
	_expect(reached_first_step and player != null and absf(player.position.x - expected_lane_2_x) <= 1.5,
		"amazon explorer completes and visibly holds the first one-lane hop")
	var all_logs_at_first_row := log_nodes.size() == log_start_positions.size()
	for log_index: int in range(mini(log_nodes.size(), log_start_positions.size())):
		all_logs_at_first_row = all_logs_at_first_row and absf((log_nodes[log_index] as Control).position.y - (log_start_positions[log_index].y + row_step)) <= 1.5
	_expect(all_logs_at_first_row,
		"all amazon logs visibly fall downward by exactly one row on the first hop")
	_expect(step_counter != null and step_counter.visible and step_counter.text.contains("1 / 3"),
		"amazon step counter exposes the first settled step")
	var moving_info := lane_area.get_node_or_null("AquafallInfo") as Label if lane_area != null else null
	_expect(moving_info != null and moving_info.text.contains("残り 2ジャンプ"),
		"amazon field HUD counts the remaining jumps down after each landing")
	var reached_second_step := false
	for _ignored: int in range(100):
		await process_frame
		if int(screen.get("aquafall_animation_step")) >= 2:
			reached_second_step = true
			break
	var expected_lane_1_x := side_margin + (lane_width - player.size.x) * 0.5 if player != null else 0.0
	_expect(reached_second_step and player != null and absf(player.position.x - expected_lane_1_x) <= 1.5,
		"amazon explorer lands on the next adjacent lane before the final result")
	var all_logs_at_second_row := log_nodes.size() == log_start_positions.size()
	for log_index: int in range(mini(log_nodes.size(), log_start_positions.size())):
		all_logs_at_second_row = all_logs_at_second_row and absf((log_nodes[log_index] as Control).position.y - (log_start_positions[log_index].y + row_step * 2.0)) <= 1.5
	_expect(all_logs_at_second_row,
		"all amazon logs fall one additional synchronized row for the second hop")
	for _ignored: int in range(180):
		await process_frame
		if not bool(screen.get("amazon_boss_move_active")):
			break
	_expect(not bool(screen.get("amazon_boss_move_active")) and boss.phase != AquafallBattle.PHASE_WAIT_DIRECTION,
		"amazon direction animates one hop at a time before resolving the turn")
	screen.call("_render_map")


func _check_aquafall_collision_feedback(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.phase = StageJourneyBase.PHASE_BOSS
	journey.hp = 3
	screen.call("_start_aquafall_boss")
	for _ignored: int in range(4):
		await process_frame
	var boss := screen.get("amazon_boss") as AquafallBattle
	if boss == null:
		_expect(false, "amazon collision feedback fixture creates a boss")
		return
	boss.lane = 3
	boss.obstacles = [{"type": "large_log", "lanes": [2], "relative_height": 1}]
	boss.request_roll(1)
	screen.call("_render_aquafall_boss")
	for _ignored: int in range(4):
		await process_frame
	screen.call("_aquafall_direction", -1)
	var saw_contact_feedback := false
	var last_status := ""
	for _ignored: int in range(180):
		await process_frame
		var status := screen.get("status_label") as Label
		last_status = status.text if status != null else ""
		if status != null and status.text.contains("大丸太に衝突") and status.text.contains("♥−1"):
			saw_contact_feedback = true
		if not bool(screen.get("amazon_boss_move_active")):
			break
	if bool(screen.get("amazon_boss_move_active")):
		await create_timer(0.7).timeout
		for _ignored: int in range(12):
			await process_frame
	_expect(saw_contact_feedback and journey.hp == 2 and boss.hp == 2,
		"amazon large-log contact visibly damages at the matching hop and persists to journey HP (saw=%s journey=%d boss=%d status=%s)" % [saw_contact_feedback, journey.hp, boss.hp, last_status])
	screen.call("_render_map")


func _check_aquafall_role_effects(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.phase = StageJourneyBase.PHASE_BOSS
	screen.call("_start_aquafall_boss")
	for _ignored: int in range(5):
		await process_frame
	var cases: Array[Dictionary] = [
		{"role": "PAIR", "skill": "水流ガード", "world": "AquafallGuardRing"},
		{"role": "STRAIGHT", "skill": "水走り", "world": "AquafallWaterRunLine_0"},
		{"role": "TRIPLE", "skill": "激流突破", "world": "AquafallTripleBurst"},
	]
	for role_case: Dictionary in cases:
		screen.call("_play_aquafall_role_effect", str(role_case.role), "")
		for _ignored: int in range(4):
			await process_frame
		var burst := screen.find_child("AquafallRoleBurst", true, false) as Control
		var skill := burst.find_child("AquafallRoleSkill", true, false) as Label if burst != null else null
		var world_effect := burst.find_child(str(role_case.world), true, false) if burst != null else null
		_expect(burst != null and str(burst.get_meta("role", "")) == str(role_case.role) and skill != null and skill.text == str(role_case.skill) and world_effect != null,
			"amazon %s role shows its named skill and world effect" % str(role_case.role))
		await create_timer(1.15).timeout
		for _ignored: int in range(4):
			await process_frame
		_expect(screen.find_child("AquafallRoleBurst", true, false) == null,
			"amazon %s role effect clears without blocking the next input" % str(role_case.role))

	# Exercise the real third-roll path as well as the isolated presentation.
	journey.phase = StageJourneyBase.PHASE_BOSS
	screen.call("_start_aquafall_boss")
	for _ignored: int in range(5):
		await process_frame
	var boss := screen.get("amazon_boss") as AquafallBattle
	if boss != null:
		boss.roll_faces = [1, 1]
		boss.obstacles.clear()
		boss.request_roll(2)
		screen.call("_render_aquafall_boss")
		for _ignored: int in range(4):
			await process_frame
		screen.call("_aquafall_direction", 1)
		var saw_real_pair := false
		for _sample: int in range(8):
			await create_timer(0.34).timeout
			var live_burst := screen.find_child("AquafallRoleBurst", true, false) as Control
			if live_burst != null and str(live_burst.get_meta("role", "")) == "PAIR":
				saw_real_pair = true
				break
		_expect(saw_real_pair and boss.water_guard_charges == 1,
			"amazon third roll automatically connects PAIR to the water-guard activation burst")
		await create_timer(1.2).timeout
	screen.call("_render_map")


func _check_aquafall_victory_modal(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.phase = StageJourneyBase.PHASE_BOSS
	journey.hp = StageJourneyBase.MAX_HEARTS
	screen.call("_start_aquafall_boss")
	for _ignored: int in range(4):
		await process_frame
	screen.call("_show_boss_recovery_or_perfect")
	for _ignored: int in range(4):
		await process_frame
	var modal := screen.get("active_modal") as Control
	var panel := modal.get_node_or_null("AquafallVictoryPanel") as Control if modal != null else null
	var art := modal.find_child("AquafallVictoryIllustration", true, false) as TextureRect if modal != null else null
	var button := modal.find_child("AquafallVictoryContinueButton", true, false) as Button if modal != null else null
	_expect(modal != null and modal.name == "AquafallVictoryModal", "amazon boss opens the victory illustration modal")
	_expect(panel != null and art != null and art.texture != null and button != null,
		"amazon victory modal wires the generated illustration and continue action")
	if panel != null:
		var panel_rect := panel.get_global_rect()
		_expect(panel_rect.position.x >= 0.0 and panel_rect.position.y >= 0.0 and panel_rect.end.x <= 720.0 and panel_rect.end.y <= 1280.0,
			"amazon victory modal stays inside the viewport")
	screen.call("_close_modal")
	screen.call("_render_map")


func _check_journey_heart_roulette(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.hp = 1
	screen.call("_show_heart_roulette")
	for _ignored: int in range(6):
		await process_frame
	var modal := screen.get("active_modal") as Control
	var labels: Array[String] = []
	if modal != null:
		for value: Node in modal.find_children("HeartRouletteSegmentLabel*", "Label", true, false):
			labels.append((value as Label).text)
	labels.sort_custom(func(left: String, right: String) -> bool: return left < right)
	_expect(modal != null and modal.find_child("HeartRouletteWheel", true, false) != null and labels.size() == 6 and ["+1", "+1", "+1", "+2", "0", "Full"] == labels,
		"journey heart roulette overlays all six +1,+2,+1,Full,+1,0 outcomes on the wheel")
	var action := modal.find_child("HeartRouletteActionButton", true, false) as Button if modal != null else null
	var lap_before := journey.lap
	_expect(action != null and action.text == "回転スタート", "journey roulette waits for a tap before spinning")
	if action != null:
		action.emit_signal("pressed")
		for _ignored: int in range(12):
			await process_frame
	_expect(action != null and action.text == "ストップ" and bool(screen.get("heart_roulette_spinning")) and journey.lap == lap_before,
		"journey roulette first tap starts visible cycling without advancing the lap")
	var selected_index := int(screen.get("heart_roulette_display_index"))
	if action != null:
		action.emit_signal("pressed")
		for _ignored: int in range(4):
			await process_frame
	var expected_hp := int(HeartRouletteModel.resolve(1, StageJourneyBase.MAX_HEARTS, selected_index).get("after_hp", 1))
	_expect(action != null and action.text == "通常マップへ" and not bool(screen.get("heart_roulette_spinning")) and journey.hp == expected_hp and journey.lap == lap_before,
		"journey roulette second tap stops on the highlighted result and applies it to map HP")
	if action != null:
		action.emit_signal("pressed")
		for _ignored: int in range(8):
			await process_frame
	_expect(journey.lap == lap_before + 1 and screen.get("active_modal") == null and journey.hp == expected_hp,
		"journey roulette returns to the normal map with the recovered hearts preserved")


func _check_aquafall_late_lap_tutorial_skip(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.lap = 3
	journey.phase = StageJourneyBase.PHASE_BOSS
	screen.call("_close_modal")
	screen.call("_after_journey_action")
	for _ignored: int in range(6):
		await process_frame
	_expect(screen.get("amazon_boss") != null and screen.get("active_modal") == null,
		"amazon boss skips the rules tutorial from lap three onward")


func _check_aquafall_rules_modal(screen: JourneyStageScreen) -> void:
	screen.call("_show_boss_intro")
	for _ignored: int in range(6):
		await process_frame
	var modal := screen.get("active_modal") as Control
	_expect(modal != null and modal.name == "AquafallRulesModal", "amazon boss opens a dedicated rules modal before the first roll")
	if modal == null:
		return
	var panel := modal.get_node_or_null("AquafallRulesPanel") as Control
	var next_button := modal.find_child("AquafallRulesNextButton", true, false) as Button
	var prev_button := modal.find_child("AquafallRulesPrevButton", true, false) as Button
	var slide_index := modal.find_child("AquafallRulesSlideIndex", true, false) as Label
	var first_copy := ""
	for value: Node in modal.find_children("*", "Label", true, false):
		var label := value as Label
		if label != null:
			first_copy += label.text + "\n"
	var first_title := modal.find_child("AquafallRulesTitle", true, false) as Label
	var goal_art := modal.find_child("RulesGoalArt", true, false) as TextureRect
	_expect(first_copy.contains("頂上まで登れば勝ち") and first_copy.contains("高さ24") and first_copy.contains("3回ぶつかる"),
		"amazon rules first slide establishes victory and defeat before movement details")
	_expect(first_title != null and first_title.get_theme_font_size("font_size") >= 21 and goal_art != null,
		"amazon rules first slide uses a large title and generated goal illustration")
	_expect(panel != null and next_button != null and prev_button != null and slide_index != null,
		"amazon rules modal has a bounded panel and slide navigation")
	_expect(prev_button != null and prev_button.disabled, "amazon rules first slide disables the previous action")
	for expected_slide: int in range(1, 4):
		if next_button != null:
			next_button.emit_signal("pressed")
		await process_frame
		_expect(slide_index != null and slide_index.text.contains("%d / 4" % (expected_slide + 1)),
			"amazon rules advances to slide %d" % (expected_slide + 1))
		if expected_slide == 1:
			var direction_copy := ""
			for value: Node in modal.find_children("*", "Label", true, false):
				direction_copy += (value as Label).text + "\n"
			_expect(modal.find_children("RulesDirectionLane_*", "PanelContainer", true, false).size() == 5 and direction_copy.contains("途中で方向は変えられない"),
				"amazon rules direction slide shows five lanes and makes direction locking explicit")
		elif expected_slide == 2:
			var reflection_copy := ""
			for value: Node in modal.find_children("*", "Label", true, false):
				reflection_copy += (value as Label).text + "\n"
			_expect(modal.find_children("AquafallRulesTurnStep_*", "PanelContainer", true, false).size() == 4 and reflection_copy.contains("4 → 5 → 4 → 3"),
				"amazon rules reflection slide visualizes the 4-5-4-3 bounce path")
		elif expected_slide == 3:
			var small_log_art := modal.find_child("RulesSmallLogArt", true, false) as TextureRect
			var large_log_art := modal.find_child("RulesLargeLogArt", true, false) as TextureRect
			_expect(small_log_art != null and large_log_art != null and modal.find_children("AquafallRulesMotionFrame_*", "PanelContainer", true, false).size() == 3,
				"amazon rules final slide pairs synchronized motion with both distinct log sizes")
	var final_copy := ""
	for value: Node in modal.find_children("*", "Label", true, false):
		var label := value as Label
		if label != null:
			final_copy += label.text + "\n"
	for required: String in ["小さい丸太", "大きい丸太", "ゲームオーバー"]:
		_expect(final_copy.contains(required), "amazon rules final slide explains %s" % required)
	var start_button := modal.find_child("AquafallRulesStartButton", true, false) as Button
	_expect(start_button != null and start_button.visible, "amazon rules final slide has the boss start action")
	_expect(start_button != null and start_button.text == "わかった！ 挑戦する", "amazon rules final action uses natural challenge copy")
	var rules_scroll := modal.find_child("AquafallRulesScroll", true, false) as ScrollContainer
	var rules_content := rules_scroll.get_node_or_null("AquafallRulesContent") as Control if rules_scroll != null else null
	_expect(rules_scroll != null and rules_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and (rules_scroll.get_v_scroll_bar() == null or not rules_scroll.get_v_scroll_bar().visible),
		"amazon rules final page is a fixed one-screen lesson without a scrollbar")
	_expect(rules_scroll != null and rules_content != null and rules_content.size.y <= rules_scroll.size.y + 1.0,
		"amazon rules final page content fits inside the modal viewport")
	if panel != null:
		var panel_rect := panel.get_global_rect()
		_expect(panel_rect.position.x >= 0.0 and panel_rect.position.y >= 0.0 and panel_rect.end.x <= 720.0 and panel_rect.end.y <= 1280.0,
			"amazon rules modal stays inside the 720x1280 viewport")
	if start_button != null:
		_expect(start_button.get_global_rect().size.y >= 52.0, "amazon rules modal start action is touch-sized")
	if prev_button != null:
		prev_button.emit_signal("pressed")
		await process_frame
		_expect(slide_index != null and slide_index.text.contains("3 / 4"), "amazon rules previous action returns to the prior slide")
		if next_button != null:
			next_button.emit_signal("pressed")
			await process_frame
	if start_button != null:
		start_button.emit_signal("pressed")
		for _ignored: int in range(3):
			await process_frame
	var practice_modal := screen.get("active_modal") as Control
	var practice_right := practice_modal.find_child("AquafallPracticeRightButton", true, false) as Button if practice_modal != null else null
	_expect(practice_modal != null and practice_modal.name == "AquafallPracticeModal" and practice_modal.find_children("AquafallPracticeLane_*", "ColorRect", true, false).size() == 5,
		"amazon first boss attempt opens a five-lane hands-on practice")
	_expect(practice_right != null and practice_right.text.contains("右へ3歩"),
		"amazon practice asks for one fixed three-step direction")
	if practice_right != null:
		practice_right.emit_signal("pressed")
		await create_timer(2.8).timeout
	var journey := screen.get("journey") as StageJourneyBase
	_expect(journey != null and bool(journey.stage_flags.get("aquafall_practice_seen", false)) and screen.get("active_modal") == null and screen.get("amazon_boss") != null,
		"amazon practice animates three hops then starts the real boss once")


func _check_hud(screen: JourneyStageScreen, journey: StageJourneyBase, stage_id: StringName) -> void:
	var coin_value := screen.get("coins_label") as Label
	var progress_value := screen.get("progress_label") as Label
	var coin_chip := screen.get("coin_info_chip") as Control
	var progress_chip := screen.get("progress_info_chip") as Control
	var item_button := screen.get("item_card_button") as Button
	var coin_button := screen.get("coin_tool_button") as Button
	var skill_button := screen.get("skill_tool_button") as Button
	var roll_caption := screen.get("roll_caption_label") as Label
	_expect(coin_value != null and coin_value.get_theme_font_size("font_size") >= 22,
		"%s coin value uses a large readable font" % String(stage_id))
	_expect(progress_value != null and progress_value.get_theme_font_size("font_size") >= 22,
		"%s progress value uses a large readable font" % String(stage_id))
	_expect(coin_value != null and not coin_value.text.contains("コイン"),
		"%s coin caption is separate from its large value" % String(stage_id))
	_expect(progress_value != null and not progress_value.text.contains("現在"),
		"%s progress caption is separate from its large value" % String(stage_id))
	_expect(coin_chip != null and coin_chip.custom_minimum_size.y >= 52.0,
		"%s coin chip has a large touch/readability surface" % String(stage_id))
	_expect(progress_chip != null and progress_chip.custom_minimum_size.y >= 52.0,
		"%s progress chip has a large touch/readability surface" % String(stage_id))
	_expect(roll_caption != null and roll_caption.text.is_empty() and not roll_caption.visible,
		"%s idle roll control relies on the antique die art without duplicate copy" % String(stage_id))
	var status := screen.get("status_label") as Label
	_expect(status != null and not status.text.contains("サイコロを振ろう"),
		"%s operation band omits the redundant idle roll sentence" % String(stage_id))
	journey.coins = 7
	journey.add_item(2)
	journey.stage_flags["skill_gauge"] = 2
	screen.call("_refresh_all")
	_expect(item_button != null and item_button.text == "アイテム\n2/3",
		"%s item dock reflects live inventory" % String(stage_id))
	_expect(coin_button != null and coin_button.text == "コイン\n7",
		"%s coin dock reflects live coins" % String(stage_id))
	_expect(skill_button != null and skill_button.text == "スキル\n2/3",
		"%s skill dock reflects the Cairo gauge" % String(stage_id))
	journey.coins = 0
	journey.stage_flags["item_count"] = 0
	journey.stage_flags["skill_gauge"] = 0
	screen.call("_refresh_all")
	var roll_button := screen.get("roll_button") as BaseButton
	_expect(roll_button != null and roll_button.tooltip_text.is_empty(),
		"%s roll die has no translucent hover instruction" % String(stage_id))
	if stage_id == StageCatalog.STAGE_AMAZON:
		journey.current_space_id = "stream:48"
		screen.call("_refresh_all")
		_expect(progress_value.text == "48/120",
			"%s route progress converts stream:48 into 48/120" % String(stage_id))
		journey.stage_flags["mission_event_count"] = 3
		screen.call("_refresh_all")
		var amazon_mission_labels := screen.get("mission_value_labels") as Dictionary
		var discovery_label := amazon_mission_labels.get("発見", null) as Label
		_expect(discovery_label != null and discovery_label.text == "3/5",
			"Amazon 発見 mission reflects EVENT landing count")
		journey.current_space_id = "main:1"
		screen.call("_refresh_all")
	else:
		screen.call("_refresh_all")
		var kyoto_mission_caption := screen.get("mission_caption_label") as Label
		var kyoto_mission_progress := screen.get("mission_progress_label") as Label
		var stage_goshuin := screen.get("goshuin_mission_label") as Label
		_expect(kyoto_mission_caption != null and not kyoto_mission_caption.text.contains("御朱印") and kyoto_mission_progress != null and kyoto_mission_progress.text.contains("報酬 COIN"),
			"Kyoto separates the shared random mission from goshuin collection")
		_expect(stage_goshuin != null and stage_goshuin.text.contains("御朱印 0/4"),
			"Kyoto keeps goshuin progress in the stage band")


func _check_normal_icon(screen: JourneyStageScreen, stage_id: StringName) -> void:
	var icon := screen.call("_icon_for_kind", "NORMAL") as Texture2D
	_expect(icon != null and icon.resource_path.ends_with("normal-footprints.png"),
		"%s NORMAL uses Cairo's footprints icon" % String(stage_id))
	var tint := screen.call("_icon_modulate_for_kind", "NORMAL") as Color
	_expect(tint.r < 0.5 and tint.g < 0.4 and tint.b < 0.3,
		"%s NORMAL footprints use a dark readable tint" % String(stage_id))
	var other_tint := screen.call("_icon_modulate_for_kind", "COIN") as Color
	_expect(other_tint == Color.WHITE,
		"%s stage-specific icon colors remain unchanged" % String(stage_id))


func _check_item_card(screen: JourneyStageScreen, journey: StageJourneyBase, stage_id: StringName) -> void:
	journey.phase = StageJourneyBase.PHASE_READY
	journey.hp = 2
	journey.stage_flags["item_inventory"] = {
		StageJourneyBase.ITEM_WATER_CANTEEN: 1,
		StageJourneyBase.ITEM_BRASS_COMPASS: 1,
		StageJourneyBase.ITEM_SCARAB_SEAL: 1,
	}
	screen.call("_refresh_all")
	screen.call("_show_item_card")
	await process_frame
	var modal := screen.get("active_modal") as Control
	var buttons := modal.find_children("*", "Button", true, false) if modal != null else []
	_expect(buttons.size() == 4, "%s ITEM card offers all three owned items plus close" % String(stage_id))
	if buttons.size() == 4:
		_expect((buttons[0] as Button).text.contains("旅人の水筒") and (buttons[1] as Button).text.contains("真鍮のコンパス") and (buttons[2] as Button).text.contains("スカラベの護符"),
			"%s ITEM card labels the Cairo catalog entries" % String(stage_id))
		(buttons[0] as Button).emit_signal("pressed")
		await process_frame
		_expect(journey.hp == 3 and journey.item_count() == 2,
			"%s ITEM card uses the selected item and refreshes inventory" % String(stage_id))
	screen.call("_close_modal")


func _check_skill_ready_discovery(screen: JourneyStageScreen, journey: StageJourneyBase, stage_id: StringName) -> void:
	journey.phase = StageJourneyBase.PHASE_READY
	journey.stage_flags["skill_gauge"] = StageJourneyBase.SKILL_GAUGE_MAX
	journey.stage_flags["skill_ready_seen"] = true
	screen.call("_refresh_all")
	screen.call("_show_skill_ready_discovery")
	await process_frame
	var modal := screen.get("active_modal") as Control
	var buttons := modal.find_children("*", "Button", true, false) if modal != null else []
	_expect(buttons.size() == 1, "%s SKILL READY explanation has one dismiss action" % String(stage_id))
	if buttons.size() != 1:
		screen.call("_close_modal")
		return
	_expect((buttons[0] as Button).text.contains("あとで使う"),
		"%s SKILL READY explanation explicitly leaves timing to the player" % String(stage_id))
	(buttons[0] as Button).emit_signal("pressed")
	await process_frame
	var skill_button := screen.get("skill_tool_button") as Button
	_expect(screen.get("active_modal") == null and journey.skill_ready() and journey.peek_skill_face() == 0,
		"%s dismissing SKILL READY leaves the skill armed for later without spending it" % String(stage_id))
	_expect(skill_button != null and not skill_button.disabled and skill_button.text == "スキル\nREADY",
		"%s READY skill button remains available after the explanation closes" % String(stage_id))
	screen.call("_show_skill_tool")
	await process_frame
	modal = screen.get("active_modal") as Control
	buttons = modal.find_children("*", "Button", true, false) if modal != null else []
	_expect(buttons.size() == 7, "%s READY skill picker exposes six faces plus a dismiss action" % String(stage_id))
	if buttons.size() >= 3:
		(buttons[2] as Button).emit_signal("pressed")
		await process_frame
	_expect(journey.skill_gauge() == 0 and journey.peek_skill_face() == 3,
			"%s player-selected skill face arms only when the picker is used" % String(stage_id))
	screen.call("_close_modal")


func _check_kyoto_goshuin_stamp(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	journey.current_space_id = "main:20"
	screen.call("_render_map")
	for _ignored: int in range(3):
		await process_frame
	var layer := screen.get("map_node_layer") as Control
	var checkpoint := layer.get_node_or_null("space_main_21") as Control if layer != null else null
	_expect(checkpoint != null and checkpoint.size.x >= 52.0 and checkpoint.size.y >= 52.0,
		"Kyoto goshuin checkpoint uses a larger shrine marker")
	screen.call("_play_goshuin_stamp", {"id": "fushimi", "space_id": "main:21", "title": "伏見稲荷"})
	await process_frame
	var popup := layer.get_node_or_null("GoshuinStampPopup") as Control if layer != null else null
	var popup_copy := ""
	if popup != null:
		for value: Node in popup.find_children("*", "Label", true, false):
			popup_copy += (value as Label).text + "\n"
	_expect(popup != null and popup_copy.contains("伏見稲荷") and popup_copy.contains("御朱印をいただいた！"),
		"Kyoto pass-through opens the shrine stamp popup with the authored copy")
	var popup_cleared := false
	for _ignored: int in range(120):
		await process_frame
		if layer == null or layer.get_node_or_null("GoshuinStampPopup") == null:
			popup_cleared = true
			break
	_expect(popup_cleared,
		"Kyoto shrine stamp popup clears after its short acknowledgement pause")
	journey.stage_flags["goshuin"] = {"fushimi": true, "yasaka": false, "kiyomizu": false, "tenryuji": false}
	screen.call("_refresh_all")
	var mission_label := screen.get("goshuin_mission_label") as Label
	_expect(mission_label != null and mission_label.text.contains("御朱印 1/4"),
		"Kyoto stage band updates the goshuin count after a checkpoint")
	journey.current_space_id = "main:1"
	screen.call("_render_map")


func _check_slot_roles(screen: JourneyStageScreen, stage_id: StringName) -> void:
	var ascending: Array[int] = [1, 2, 3]
	var descending: Array[int] = [3, 2, 1]
	var shuffled: Array[int] = [1, 3, 2]
	var pair: Array[int] = [2, 2, 5]
	_expect(screen.call("_completed_slot_role", ascending) == "STRAIGHT",
		"%s ascending ordered dice resolve STRAIGHT" % String(stage_id))
	_expect(screen.call("_completed_slot_role", descending) == "STRAIGHT",
		"%s descending ordered dice resolve STRAIGHT" % String(stage_id))
	_expect(str(screen.call("_completed_slot_role", shuffled)).is_empty(),
		"%s shuffled consecutive dice remain MIX like Cairo" % String(stage_id))
	_expect(screen.call("_completed_slot_role", pair) == "PAIR",
		"%s exactly two matching dice resolve PAIR" % String(stage_id))
	if stage_id == StageCatalog.STAGE_KYOTO:
		var journey := screen.get("journey") as StageJourneyBase
		var previous_mission: Dictionary = (journey.stage_flags.get("journey_mission", {}) as Dictionary).duplicate(true)
		var previous_gauge := journey.skill_gauge()
		journey.stage_flags["journey_mission"] = {
			"id": "journey_pair4", "kind": "slot", "short_text": "PAIRを4回作る",
			"target": 4, "target_role": "PAIR", "reward_coins": 12, "icon_kind": "slot",
			"progress": 0, "completed": false, "reward_claimed": false, "last_coins": journey.coins,
		}
		var pair_slots: Array[int] = [2, 2, 5]
		screen.set("roll_slots", pair_slots)
		screen.call("_show_slot_result_or_reach")
		var mission := journey.journey_mission_state()
		var mission_progress := screen.get("mission_progress_label") as Label
		_expect(int(mission.get("progress", 0)) == 1 and mission_progress != null and mission_progress.text.contains("進捗 1/4"),
			"Kyoto PAIR updates the visible journey MISSION immediately")
		journey.stage_flags["journey_mission"] = previous_mission
		journey.stage_flags["skill_gauge"] = previous_gauge
		screen.set("roll_slots", [])
		screen.call("_refresh_all")


func _check_fox_fire_role_charge(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	var previous_gauge := journey.skill_gauge()
	journey.stage_flags["skill_gauge"] = 0
	screen.call("_on_fox_fire_slot_role_completed", "PAIR")
	var pair_gauge := journey.skill_gauge()
	screen.call("_on_fox_fire_slot_role_completed", "STRAIGHT")
	var straight_gauge := journey.skill_gauge()
	screen.call("_on_fox_fire_slot_role_completed", "TRIPLE")
	var triple_gauge := journey.skill_gauge()
	_expect(pair_gauge == 0 and straight_gauge == 0 and triple_gauge == 0,
		"Kyoto SLOT roles no longer charge the REST-based skill gauge")
	journey.stage_flags["skill_gauge"] = previous_gauge


func _check_three_roll_cycle(screen: JourneyStageScreen, journey: StageJourneyBase, stage_id: StringName) -> void:
	var slots: Array[int] = [2, 3, 4]
	screen.set("roll_slots", slots)
	journey.phase = StageJourneyBase.PHASE_READY
	screen.set("map_roll_active", false)
	screen.set("map_movement_active", false)
	screen.set("roll_animation_active", false)
	screen.call("_begin_map_roll")
	var rolling_status := screen.get("status_label") as Label
	var rolling_button := screen.get("roll_button") as BaseButton
	_expect(rolling_status != null and rolling_status.text == "ダイス回転中" and rolling_button != null and not rolling_button.tooltip_text.contains("タップで止める"),
		"%s rolling state omits the unreadable tap-to-stop copy" % String(stage_id))
	var reset_slots: Array = screen.get("roll_slots")
	var labels: Array = screen.get("roll_slot_labels")
	var label_texts: Array[String] = []
	for value: Variant in labels:
		var label := value as Label
		label_texts.append(label.text if label != null else "")
	_expect(reset_slots.is_empty(), "%s fourth throw starts a fresh three-slot set" % String(stage_id))
	_expect(label_texts.size() == 3 and label_texts[0] == "1" and label_texts[1] == "—" and label_texts[2] == "—",
		"%s fourth rolling face previews in slot zero" % String(stage_id))
	# Do not leave the continuously rotating 3D die active for later geometry checks.
	screen.set("map_roll_active", false)
	screen.call("_refresh_roll_slots")


func _check_fox_fire_chase_chrome(screen: JourneyStageScreen, journey: StageJourneyBase) -> void:
	screen.call("_close_modal")
	journey.phase = StageJourneyBase.PHASE_BOSS
	screen.call("_start_fox_fire_chase_boss", true, {})
	for _ignored: int in range(4):
		await process_frame
	var chase := screen.get("kyoto_chase_scene") as Control
	var chrome: Array[Control] = [
		screen.get("top_hud") as Control,
		screen.get("stage_band") as Control,
		screen.get("mission_band") as Control,
		screen.get("content_host") as Control,
		screen.get("controls_box") as Control,
	]
	var all_hidden := chase != null and chase.visible
	for control: Control in chrome:
		all_hidden = all_hidden and control != null and not control.is_visible_in_tree()
	_expect(all_hidden, "狐火追陣 hides every normal-map HUD band while the boss screen is active")
	screen.call("_set_fox_fire_chase_chrome_visible", true)
	var all_restored := true
	for control: Control in chrome:
		all_restored = all_restored and control != null and control.is_visible_in_tree()
	_expect(all_restored, "狐火追陣 restores normal-map HUD bands when the boss screen closes")
	if is_instance_valid(chase):
		chase.queue_free()
	screen.set("kyoto_chase_scene", null)
	var lap_before := journey.lap
	journey.coins = 9
	journey.add_item(1)
	journey.stage_flags["skill_gauge"] = 2
	journey.current_space_id = "main:90"
	journey.phase = StageJourneyBase.PHASE_BOSS
	screen.call("_return_from_fox_fire_chase_defeat", "テスト敗北。")
	_expect(journey.lap == lap_before + 1 and journey.current_space_id == (journey as KyotoJourney).course.start_space_id() and journey.phase == StageJourneyBase.PHASE_READY,
		"狐火追陣 defeat advances LAP and returns to the first normal-map space")
	_expect(journey.coins == 0 and journey.item_count() == 0 and journey.skill_gauge() == 0,
		"狐火追陣 defeat resets COIN, ITEM, and SKILL charge")


func _check_route_preview_and_player_anchor(screen: JourneyStageScreen, journey: StageJourneyBase, stage_id: StringName) -> void:
	_expect(screen.has_method("_refresh_route_preview_for_space"),
		"%s exposes route preview refresh for camera/movement steps" % String(stage_id))
	if not screen.has_method("_refresh_route_preview_for_space"):
		return
	var test_space := _first_semantic_main_space(journey)
	journey.current_space_id = test_space
	screen.call("_update_local_view_window")
	screen.call("_apply_background_camera")
	screen.call("_populate_map_nodes")
	for _ignored: int in range(3):
		await process_frame
	screen.call("_refresh_route_preview_for_space", test_space)

	var row := screen.get("route_preview_row") as HBoxContainer
	_expect(row != null and row.get_child_count() == 7,
		"%s route preview always shows current through +6" % String(stage_id))
	var legend := screen.find_child("RouteLegend", true, false) as Control
	var layer_edges := screen.get("map_node_layer") as Control
	var main_edges := layer_edges.find_children("LocalRouteMain", "Line2D", true, false) if layer_edges != null else []
	var side_edges := layer_edges.find_children("LocalRouteSide", "Line2D", true, false) if layer_edges != null else []
	if stage_id == StageCatalog.STAGE_KYOTO:
		_expect(legend == null and main_edges.is_empty() and side_edges.is_empty(),
			"Kyoto normal play leaves full-route topology to 全体マップ")
		var horizon := row.get_parent() as Control if row != null else null
		var die := screen.get("map_dice") as Control
		var first_tile := row.get_child(0) as Control if row != null and row.get_child_count() > 0 else null
		var number_label := _first_label(row.get_child(1)) if row != null and row.get_child_count() > 1 else null
		_expect(horizon != null and horizon.get_global_rect().size.y >= 204.0 and first_tile != null and first_tile.get_global_rect().size.y >= 184.0,
			"Kyoto promotes current through +6 into tall Cairo-style cards")
		_expect(number_label != null and number_label.get_theme_font_size("font_size") >= 32,
			"Kyoto makes +1 through +6 the dominant card labels")
		_expect(die != null and die.size.x >= 152.0 and absf(die.get_global_rect().get_center().x - 360.0) <= 8.0 and die.get_global_rect().get_center().y > horizon.get_global_rect().get_center().y,
			"Kyoto centers an enlarged map die below the seven readable cards")
	else:
		_expect(legend != null and _all_label_text(legend).contains("本線") and _all_label_text(legend).contains("脇道"),
			"%s normal map shows a main/detour route legend" % String(stage_id))
		_expect(main_edges.size() > 0 and side_edges.size() > 0,
			"%s normal map draws separate main and detour connectors" % String(stage_id))
	if row != null and row.get_child_count() == 7:
		var current_icon := _first_texture_rect(row.get_child(0))
		var expected_kind := str(screen.call("_space_kind", test_space))
		var expected_icon := screen.call("_icon_for_kind", expected_kind) as Texture2D
		_expect(current_icon != null and current_icon.texture == expected_icon,
			"%s current route tile refreshes to the traveler's semantic space" % String(stage_id))
		var caption := _first_label(row.get_child(0))
		_expect(caption != null and caption.text == "現在地",
			"%s refreshed route preview keeps an explicit current marker" % String(stage_id))
		var next_space := str((row.get_child(1) as Control).get_meta("space_id", ""))
		var labels_before: Array[String] = []
		for child: Node in row.get_children():
			var child_caption := _first_label(child)
			labels_before.append(child_caption.text if child_caption != null else "")
		screen.call("_set_route_preview_motion_marker", next_space)
		var labels_after: Array[String] = []
		for child: Node in row.get_children():
			var child_caption := _first_label(child)
			labels_after.append(child_caption.text if child_caption != null else "")
		_expect(labels_before == labels_after and row.get_child_count() == 7,
			"%s moving marker changes color without relabeling the seven-space horizon" % String(stage_id))
		var moving_player := (row.get_child(1) as Control).get_meta("motion_player") as TextureRect
		_expect(moving_player != null and moving_player.visible,
			"%s moving route tile retains its explorer marker state" % String(stage_id))
		if stage_id == StageCatalog.STAGE_KYOTO:
			_expect(moving_player.modulate.a == 0.0,
				"Kyoto uses one large map-layer explorer instead of a duplicate mini cat")
			var current_badge := (row.get_child(0) as Control).find_child("CurrentKindBadge", true, false) as Control
			var current_badge_icon := current_badge.find_child("KindIcon", true, false) as TextureRect if current_badge != null else null
			var current_player := screen.get("map_player") as Control
			_expect(current_badge != null and current_badge_icon != null and current_badge_icon.texture == expected_icon and current_player != null and current_badge.get_global_rect().end.y <= current_player.get_global_rect().position.y + 1.0,
				"Kyoto keeps the current-space icon above and clear of the large explorer")
			_expect(current_badge.position.y <= 52.0,
				"Kyoto raises the current-space icon away from the explorer")
			var future_icon_center := (row.get_child(1) as Control).find_child("CompactKindIconCenter", true, false) as Control
			var future_icon_margin := (row.get_child(1) as Control).find_child("CompactKindIconMargin", true, false) as Control
			_expect(future_icon_center != null and future_icon_margin != null and future_icon_center.get_global_rect().get_center().y < future_icon_margin.get_global_rect().get_center().y,
				"Kyoto raises future landing icons within their tiles")

	var player := screen.get("map_player") as Control
	var layer := screen.get("map_node_layer") as Control
	_expect(player != null and layer != null, "%s map traveler and map layer exist" % String(stage_id))
	if player == null or layer == null:
		return
	var marker := layer.get_node_or_null("space_%s" % test_space.replace(":", "_")) as Control
	var unanchored := Vector2.ZERO
	if marker != null:
		unanchored = marker.position + marker.size * 0.5 - player.size * 0.5
	else:
		var normalized := screen.call("_map_normalized_for_space", test_space) as Vector2
		unanchored = Vector2(normalized.x * layer.size.x, normalized.y * layer.size.y) - player.size * 0.5
	var anchored := screen.call("_map_player_position_for_space", test_space) as Vector2
	if stage_id == StageCatalog.STAGE_KYOTO and marker != null and bool(marker.get_meta("kyoto_horizon_anchor", false)):
		var current_tile := row.get_child(0) as Control if row != null and row.get_child_count() > 0 else null
		var card_bottom_anchor := marker.position + Vector2(
			(marker.size.x - player.size.x) * 0.5,
			marker.size.y - player.size.y - 6.0
		)
		_expect(anchored.distance_to(card_bottom_anchor) < 0.75 and player.size.x >= 112.0,
			"Kyoto uses a larger explorer and bottom-anchors it over the current-card medal")
		_expect(current_tile != null and player.get_global_rect().get_center().y > current_tile.get_global_rect().get_center().y,
			"Kyoto keeps the explorer in the lower half of the current card")
	else:
		_expect(anchored.distance_to(unanchored + Vector2(0.0, -22.0)) < 0.75,
			"%s traveler uses a foot anchor instead of covering the map medal" % String(stage_id))


func _check_kyoto_detour_geometry(screen: JourneyStageScreen, journey: KyotoJourney) -> void:
	if journey == null:
		return
	var route_ids: Array[String] = ["gion_shortcut", "arashiyama_shortcut"]
	for route_id: String in route_ids:
		var route_spaces: Array[Dictionary] = []
		for value: Variant in journey.course.spaces.values():
			if value is Dictionary and str((value as Dictionary).get("route", "")) == route_id:
				route_spaces.append(value as Dictionary)
		route_spaces.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
			return int(left.get("route_order", 0)) < int(right.get("route_order", 0))
		)
		var route_points: Array[Vector2] = []
		for route_space: Dictionary in route_spaces:
			route_points.append(screen.call("_kyoto_overview_normalized_for_space", str(route_space.get("id", ""))) as Vector2)
		var direction_ok := true
		var spacing_ok := true
		for point_index: int in range(route_points.size() - 1):
			var delta_y := route_points[point_index + 1].y - route_points[point_index].y
			direction_ok = direction_ok and delta_y < -0.004
			spacing_ok = spacing_ok and absf(delta_y) >= 0.006
		_expect(route_points.size() == route_spaces.size() and route_points.size() >= 3,
			"Kyoto %s detour exposes every authored checkpoint" % route_id)
		_expect(direction_ok, "Kyoto %s detour follows the main route upward" % route_id)
		_expect(spacing_ok, "Kyoto %s detour keeps readable vertical marker spacing" % route_id)
	var original_space := journey.current_space_id
	for sample_space: String in ["gion_shortcut:S2", "arashiyama_shortcut:S3"]:
		journey.current_space_id = sample_space
		screen.call("_render_map")
		for _ignored: int in range(6):
			await process_frame
		var route_id := str(journey.course.space(sample_space).get("route", ""))
		var visible_route_nodes: Array[Control] = []
		var map_layer := screen.get("map_node_layer") as Control
		if map_layer != null:
			for value: Variant in journey.course.spaces.values():
				if not value is Dictionary or str((value as Dictionary).get("route", "")) != route_id:
					continue
				var marker_name := "space_%s" % str((value as Dictionary).get("id", "")).replace(":", "_")
				var marker := map_layer.get_node_or_null(marker_name) as Control
				if marker != null and marker.visible:
					visible_route_nodes.append(marker)
		var row := screen.get("route_preview_row") as HBoxContainer
		var card_ids: Dictionary = {}
		if row != null:
			for child: Node in row.get_children():
				card_ids[str((child as Control).get_meta("space_id", ""))] = true
		_expect(visible_route_nodes.is_empty() and row != null and row.get_child_count() == 7 and card_ids.size() == 7,
			"Kyoto %s shortcut stays readable as seven unique cards without background node clutter" % route_id)
	var movement_samples: Array[Dictionary] = [
		{"label": "main", "start": "main:33", "path": ["main:34", "main:35", "main:36", "main:37", "main:38", "main:39"]},
		{"label": "shortcut", "start": "main:33", "path": ["gion_shortcut:S1", "gion_shortcut:S2", "gion_shortcut:S3", "gion_shortcut:S4", "main:42", "main:43"]},
	]
	for sample: Dictionary in movement_samples:
		for remaining_steps: int in range(1, 7):
			var full_path: Array = sample.get("path", []) as Array
			var movement_path: Array[String] = []
			for path_index: int in range(remaining_steps):
				movement_path.append(str(full_path[path_index]))
			screen.call("_refresh_kyoto_horizon_for_movement", str(sample.get("start", "")), movement_path)
			await process_frame
			screen.call("_layout_kyoto_card_horizon")
			await process_frame
			screen.call("_sync_kyoto_horizon_anchors")
			var map_layer := screen.get("map_node_layer") as Control
			var cat := screen.get("map_player") as Control
			var all_card_anchored := map_layer != null and cat != null
			for path_space: String in movement_path:
				var anchor := map_layer.get_node_or_null("space_%s" % path_space.replace(":", "_")) as Control if map_layer != null else null
				var cat_position := screen.call("_map_player_position_for_space", path_space) as Vector2
				all_card_anchored = all_card_anchored and anchor != null and bool(anchor.get_meta("kyoto_horizon_anchor", false))
				all_card_anchored = all_card_anchored and cat_position.x >= -0.5 and cat_position.y >= -0.5 and cat_position.x + cat.size.x <= map_layer.size.x + 0.5 and cat_position.y + cat.size.y <= map_layer.size.y + 0.5
			_expect(all_card_anchored, "Kyoto %s branch remainder %d keeps every explorer hop on a visible card anchor" % [str(sample.get("label", "")), remaining_steps])
	journey.current_space_id = original_space
	screen.call("_render_map")
	for _ignored: int in range(4):
		await process_frame


func _first_semantic_main_space(journey: StageJourneyBase) -> String:
	var course: Variant = journey.get("course")
	if course != null:
		var spaces: Dictionary = course.get("spaces")
		for value: Variant in spaces.values():
			if value is Dictionary:
				var space := value as Dictionary
				var id := str(space.get("id", ""))
				if id.begins_with("main:") and str(space.get("kind", "NORMAL")) != "NORMAL":
					return id
	return "main:4"


func _first_label(node: Node) -> Label:
	if node is Label:
		return node as Label
	for child: Node in node.get_children():
		var found := _first_label(child)
		if found != null:
			return found
	return null


func _first_texture_rect(node: Node) -> TextureRect:
	if node is TextureRect:
		return node as TextureRect
	for child: Node in node.get_children():
		var found := _first_texture_rect(child)
		if found != null:
			return found
	return null


func _find_overview_node(layer: Control, number: String) -> Control:
	for child: Node in layer.get_children():
		if child is Control and str(child.name).begins_with("OverviewNode_%s" % number):
			return child as Control
	return null


func _all_label_text(root_node: Node) -> String:
	if root_node == null:
		return ""
	var result := ""
	for value: Node in root_node.find_children("*", "Label", true, false):
		var label := value as Label
		if label != null:
			result += label.text + "\n"
	for value: Node in root_node.find_children("*", "Button", true, false):
		var button := value as Button
		if button != null:
			result += button.text + "\n"
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
