extends SceneTree

const BattleScene: PackedScene = preload("res://boss/kyoto/fox_fire_six_routes/FoxFireSixRoutesBattle.tscn")
const ControllerScript = preload("res://boss/kyoto/fox_fire_six_routes/fox_fire_six_routes_controller.gd")

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleScene.instantiate() as FoxFireSixRoutesBattle
	root.add_child(battle)
	root.size = Vector2i(720, 1280)
	for _frame: int in range(3):
		await process_frame
	_expect(battle.configure_battle(17, {"kiyomizu": true, "tenryuji": true}, 6060, 3, 3, 6060), "UI configures a Lv6 battle")
	battle.start_battle()
	for _frame: int in range(3):
		await process_frame
	var view := battle.get_node("View") as FoxFireSixRoutesView
	_expect(view != null and view.fox_preview_label != null, "UI builds the fox preview HUD")
	_expect(view.fox_preview_label.text.contains("次の狐火"), "UI presents the locked fox preview")
	_expect(not view.fox_preview_label.text.contains(",") and not view.fox_preview_label.text.contains("5,1"), "UI keeps development coordinates out of the fox preview")
	_expect(view.tutorial_overlay.visible and view.tutorial_progress.text == "1 / 4", "UI opens a four-page first-time boss tutorial")
	_expect(view.tutorial_body.text.contains("上下左右") and view.tutorial_body.text.contains("光るマス"), "Tutorial teaches orthogonal cell-by-cell movement")
	_expect(view.tutorial_art.texture != null and view.tutorial_art.texture.resource_path.ends_with("fox-fire-six-routes-tutorial-move-v2.png"), "Tutorial uses the explorer-cat movement illustration")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "2 / 4" and view.tutorial_title.text.contains("ぴったり"), "Tutorial explains exact torii stopping and three seals")
	_expect(view.tutorial_art.texture.resource_path.ends_with("fox-fire-six-routes-tutorial-torii.png"), "Tutorial uses the pass-through versus exact-stop illustration")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "3 / 4" and view.tutorial_body.text.contains("白い狐火") and view.tutorial_body.text.contains("予告"), "Tutorial explains white-fire preview timing")
	_expect(view.tutorial_art.texture.resource_path.ends_with("fox-fire-six-routes-tutorial-foxfire.png"), "Tutorial uses the blocked-versus-preview foxfire illustration")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "4 / 4" and view.tutorial_button.text == "白狐に挑む", "Tutorial ends with a boss-facing action")
	_expect(view.tutorial_hint.text.contains("清水寺") and view.tutorial_hint.text.contains("天龍寺"), "Tutorial lists only the blessings currently owned")
	_expect(view.tutorial_art.texture.resource_path.ends_with("fox-fire-six-routes-tutorial-blessings.png"), "Tutorial uses the goshuin-to-ability illustration")
	_expect(view.kiyomizu_button.text.contains("清水寺") and view.minus_button.text.contains("天龍寺") and view.mangan_button.text.contains("満願札"), "Goshuin action buttons name both the blessing and its action")
	view.play_slot_role_activation("TRIPLE")
	await process_frame
	_expect(view.activation_panel.visible and view.activation_title.text.contains("TRIPLE") and view.activation_body.text.contains("MAX"), "Slot-role activation explains the normal-map skill effect")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(battle.configure_battle(1, {"fushimi": true, "kiyomizu": true, "tenryuji": true}, 20, 3, 3, 7007), "UI configures a Fushimi start-choice pass")
	battle.set("_tutorial_seen", true)
	battle.start_battle()
	for _frame: int in range(3):
		await process_frame
	_expect(view.start_overlay.visible, "UI opens the Fushimi start-torii choice before the first roll")
	if view.start_buttons.size() > 1:
		view.start_buttons[1].emit_signal("pressed")
		await process_frame
	_expect(not view.start_overlay.visible, "UI closes the Fushimi start choice after selection")
	view.dismiss_rule_guide()
	view.dismiss_rule_guide()
	await process_frame
	_expect(view.activation_panel.visible and view.activation_title.text.contains("伏見稲荷") and view.activation_body.text.contains("Bの鳥居"), "UI reports the selected starting torii once")
	var fushimi_in_active_summary := false
	for child: Node in view.blessing_label.get_children():
		if child is Label and "伏見" in (child as Label).text:
			fushimi_in_active_summary = true
	_expect(not fushimi_in_active_summary, "UI removes the consumed Fushimi blessing from active abilities")
	view.dismiss_rule_guide()
	_expect(view.board_cell_center(Vector2i(2, 2)).x > 0.0, "UI board geometry exposes the Sakura cell")
	_expect(absf(view.board_cell_center(Vector2i(3, 0)).y - 510.0) < 0.1 and absf(view.board_cell_center(Vector2i(2, 5)).y - 896.5) < 0.1, "UI aligns top and bottom board markers to the authored perspective grid")
	battle.set("_tutorial_seen", true)
	_expect(battle.configure_battle(17, {"kiyomizu": true, "tenryuji": true}, 6060, 3, 3, 6060), "UI reconfigures a fresh battle for the live roll pass")
	battle.start_battle()
	for _frame: int in range(3):
		await process_frame
	_expect(view.rule_guide_visible and view.rule_guide_kind == view.GUIDE_TORII and view.rule_guide_body.text.contains("鳥居"), "UI explains the torii rule at battle start")
	_expect(view.rule_guide_panel.size.y >= 220.0 and view.rule_guide_dimmer.visible, "UI makes the first rule warning large and visually modal")
	_simulate_mouse(view, Vector2(700, 1200), true)
	_expect(view.rule_guide_visible and view.rule_guide_kind == view.GUIDE_WHITE_FIRE, "UI follows the start rule with the first live white-fire warning")
	_expect(view.rule_guide_body.text.contains("通れない") and view.rule_guide_body.text.contains("止まることもできない"), "UI states that white fire blocks both passing and stopping")
	_simulate_touch(view, Vector2(18, 18), true)
	_expect(not view.rule_guide_visible, "UI dismisses each start warning from a tap anywhere on screen")
	var controller := battle.get_node("Controller") as FoxFireSixRoutesController
	_expect(controller != null and controller.state.phase == ControllerScript.BattlePhase.ROLL_SLOT, "UI live roll pass starts in ROLL_SLOT")
	view.roll_button.emit_signal("pressed")
	await process_frame
	_expect(view.is_die_rolling() and view.roll_button_copy.text == "止める", "UI first roll tap starts the die animation")
	view.roll_button.emit_signal("pressed")
	for _frame: int in range(2):
		await process_frame
	_expect(not view.is_die_rolling() and controller.state.phase == ControllerScript.BattlePhase.PATH_INPUT, "UI second roll tap stops and commits the die")
	_expect(controller.slot_faces().size() == 1 and controller.state.move_steps >= 1, "UI commits the result into the first slot")
	var start_cell := controller.state.cat_position
	var legal_cells := controller.legal_next_cells()
	_expect(not legal_cells.is_empty(), "UI exposes a legal board step after the roll")
	if not legal_cells.is_empty():
		var next_cell: Vector2i = legal_cells[0]
		var start_screen := view.board_canvas.get_global_transform_with_canvas() * view.board_cell_center(start_cell)
		var next_screen := view.board_canvas.get_global_transform_with_canvas() * view.board_cell_center(next_cell)
		_simulate_touch(view, start_screen, true)
		_simulate_touch_drag(view, next_screen, next_screen - start_screen)
		_simulate_touch(view, next_screen, false)
		_expect(controller.state.current_input_path.size() == 2 and controller.state.current_input_path.back() == next_cell, "UI drag advances the cat path across adjacent cells")
	for _frame: int in range(2):
		await process_frame
	var slot_rect := view.slot_panel.get_global_rect()
	var status_rect := view.status_panel.get_global_rect()
	var blessing_rect := view.blessing_row.get_global_rect()
	var action_rect := view.action_panel.get_global_rect()
	var tray_art := view.slot_panel.get_node("SlotContent/SlotTrayArt") as TextureRect
	_expect(view.roll_button_die_icon != null and view.roll_button_die_icon.texture != null, "UI uses the normal-map ivory die on the roll control")
	_expect(view.roll_button.visible and view.roll_button.disabled and view.roll_button_copy.text == "出目済", "UI keeps the normal-map die action visible but locked after rolling")
	_expect(view.blessing_row.visible, "UI exposes blessing actions in their own row")
	_expect(not view.rule_guide_visible, "UI does not interrupt the turn for a fox-fire preview alone")
	_expect(not slot_rect.intersects(blessing_rect), "UI keeps blessing actions below the slot tray")
	_expect(not blessing_rect.intersects(action_rect), "UI keeps blessing actions above the path actions")
	_expect(action_rect.end.y <= 1280.0, "UI keeps the path actions inside the 720x1280 safe area")
	_expect(status_rect.position.y >= view.board_canvas.position.y + 950.0 and slot_rect.position.y >= view.board_canvas.position.y + 1000.0, "UI separates the board plate from the slot tray")
	_expect(view.backdrop.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "UI keeps the authored board texture aligned instead of cover-cropping it")
	var roll_rect := view.roll_button.get_global_rect()
	var slot_face_overlap := false
	var square_faces := true
	var faces_inside_tray := tray_art != null
	for face: FoxFireSixRoutesView.DieFace in view.slot_faces:
		slot_face_overlap = slot_face_overlap or roll_rect.intersects(face.get_global_rect())
		square_faces = square_faces and absf(face.size.x - face.size.y) < 0.1
		faces_inside_tray = faces_inside_tray and tray_art.get_global_rect().encloses(face.get_global_rect())
	_expect(slot_rect.encloses(roll_rect), "UI keeps the roll control inside the slot tray")
	_expect(not slot_face_overlap, "UI keeps the roll control clear of all slot faces")
	_expect(tray_art != null and tray_art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "UI preserves the slot tray proportions")
	_expect(square_faces and faces_inside_tray, "UI fits square dice inside all three authored slot windows")
	# The rule is taught once at the first live blocker and must not repeatedly
	# interrupt later turns as additional fire appears.
	controller.state.white_fire_cells[Vector2i(1, 2)] = true
	view.refresh()
	_expect(not view.rule_guide_visible and controller.state.phase == ControllerScript.BattlePhase.PATH_INPUT, "UI does not repeat the white-fire tutorial after it has been acknowledged")
	_expect(battle.configure_battle(21, {}, 6060, 3, 3, 6060), "UI configures Lv7 before creating a Sakura checkpoint")
	battle.start_battle()
	for _frame: int in range(2):
		await process_frame
	var special_snapshot: Dictionary = battle.snapshot()
	special_snapshot["phase"] = ControllerScript.BattlePhase.CAT_MOVING
	special_snapshot["cat_position"] = Vector2i(2, 2)
	special_snapshot["white_fire_cells"] = [Vector2i(1, 2)]
	special_snapshot["fox_preview_cells"] = []
	special_snapshot["fox_preview_due_turn"] = 0
	special_snapshot["fox_committed_cell"] = Vector2i(-1, -1)
	special_snapshot["fox_preview_line_cut_edge"] = ""
	special_snapshot["line_cut_preview_due_turn"] = 0
	_expect(battle.configure_battle(21, {}, 6060, 3, 3, 6060, special_snapshot), "UI restores a Lv7 Sakura special-resolution checkpoint")
	controller = battle.get_node("Controller") as FoxFireSixRoutesController
	controller.finish_cat_movement()
	for _frame: int in range(2):
		await process_frame
	var special_overlay := view.special_overlay
	_expect(special_overlay != null and special_overlay.visible, "UI opens the Sakura purification modal")

	# A complete first-time turn must visibly animate, resolve, and return input.
	_expect(battle.configure_battle(1, {}, 10, 3, 3, 404), "UI configures a Lv1 full-turn interaction pass")
	battle.set("_tutorial_seen", true)
	battle.start_battle()
	for _frame: int in range(2):
		await process_frame
	view.dismiss_rule_guide()
	view.dismiss_rule_guide()
	controller = battle.get_node("Controller") as FoxFireSixRoutesController
	var qa_roll: Dictionary = controller.set_move_steps_for_test(3)
	view.present_roll(qa_roll)
	view.refresh()
	var route_guard := 6
	while controller.state.remaining_steps() > 0 and route_guard > 0:
		var next_cells := controller.legal_next_cells()
		if next_cells.is_empty():
			break
		view.cell_pressed.emit(next_cells[0])
		await process_frame
		route_guard -= 1
	_expect(controller.can_confirm_path(), "UI completes an exact path before enabling confirmation")
	# Exercise the real viewport input route. Calling emit_signal("pressed") here
	# would hide regressions where the board's global _input handler consumes a
	# bottom-bar click before Control can receive it.
	await _tap_control(view.confirm_button)
	_expect(bool(battle.get("_resolving_turn")) and view.message_label.text.contains("進んでいます"), "UI gives immediate feedback after pressing the confirm button")
	_expect(view.board_input_layer.get_global_rect().grow(90.0).intersects(view.cat_sprite.get_global_rect()), "UI keeps the moving player sprite on the visible board")
	await create_timer(2.2).timeout
	_expect(not bool(battle.get("_resolving_turn")) and controller.state.phase == ControllerScript.BattlePhase.ROLL_SLOT, "UI returns control after cat movement and fox resolution")
	_expect(view.roll_button.visible and not view.roll_button.disabled, "UI makes the next roll immediately actionable instead of appearing frozen")
	root.size = Vector2i(720, 1600)
	for _frame: int in range(3):
		await process_frame
	var expected_cat_anchor := view.board_canvas.position + view.board_cell_center(controller.state.cat_position)
	var actual_cat_anchor := view.cat_sprite.position + Vector2(31, 63)
	_expect(view.board_canvas.position.y == 160.0 and actual_cat_anchor.distance_to(expected_cat_anchor) < 0.1, "UI keeps the player on the authored cell center in a tall viewport")
	_expect(view.slot_panel.position.y >= view.board_canvas.position.y + 1000.0, "UI preserves the board-to-slot separation in a tall viewport")
	view.show_result({"victory": true, "seal_count": 3, "turns_used": 8})
	_expect(view.result_overlay.visible and view.result_art.visible and view.result_art.texture != null, "UI shows the generated Kyoto victory illustration on a win")
	_expect(view.result_button.text == "旅へ戻る" and view.result_title.text == "結界、完成。", "UI keeps the victory action and copy readable over the illustration")
	print("FOX_FIRE_SIX_ROUTES_UI_TESTS failures=%d" % failures)
	battle.free()
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)


func _tap_control(control: Control) -> void:
	# Use the real viewport mouse route after the touch-synthesis suppression
	# window. This catches board/input-layer interception without relying on
	# headless touch-to-GUI emulation.
	await create_timer(0.14).timeout
	var tap_position := control.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.position = tap_position
	press.global_position = tap_position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = tap_position
	release.global_position = tap_position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release)
	await process_frame


func _simulate_mouse(view: FoxFireSixRoutesView, position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	view._input(event)


func _simulate_motion(view: FoxFireSixRoutesView, position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	view._input(event)


func _simulate_touch(view: FoxFireSixRoutesView, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	view._input(event)


func _simulate_touch_drag(view: FoxFireSixRoutesView, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = position
	event.relative = relative
	view._input(event)
