extends SceneTree

const BattleScene: PackedScene = preload("res://boss/kyoto/fox_fire_chase/FoxFireChaseBattle.tscn")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleScene.instantiate() as FoxFireChaseBattle
	root.add_child(battle)
	root.size = Vector2i(720, 1280)
	for _frame: int in range(3):
		await process_frame
	_expect(battle.configure_battle(1, 2, 12, 3, 3, 404), "host contract configures chase battle")
	var view := battle.get_node("View") as FoxFireChaseView
	_expect(is_equal_approx(float(view.call("_roll_speed_multiplier")), 0.82), "lap one starts with a slow readable die rotation")
	_expect(view != null and view.backdrop.texture != null, "view uses the authored Kyoto board plate")
	_expect(view.board_cell_center(Vector2i(2, 5)).y > view.board_cell_center(Vector2i(2, 0)).y, "board exposes vertical cell centers")
	_expect(view.cell_touch_rect(Vector2i(2, 5)).size.x >= 52.0, "cell touch target meets physical minimum")
	_expect(view.slot_faces.size() == 3 and view.slot_panel != null, "view builds three SLOT faces")
	var six_pips: Array = view.slot_faces[0].call("_pip_positions", 6) as Array
	_expect(six_pips.size() == 6 and not six_pips.has(Vector2(0.5, 0.5)), "six uses exactly six pips with no center pip")
	_expect(str(view.slot_faces[0].call("empty_marker")) == "—", "an empty SLOT cannot be mistaken for the one face")
	_expect(view.get_node("Design/SlotPanel/SlotLabelChip").size.x <= 72.0 and view.get_node("Design/SlotPanel/SlotCountChip").size.x <= 100.0, "SLOT side labels stay light while the three faces lead")
	_expect(view.roll_button.size.x >= 100.0 and view.roll_button.size.y >= 80.0, "view builds a large round roll control")
	_expect(view.cat_sprite.size.x >= 110.0 and view.fox_sprite.size.x >= 115.0, "cat and white fox are large enough to read as the duel protagonists")
	_expect(not view.advantage_bar.visible and view.advantage_label.text == "追いつくまで" and not view.distance_label.text.contains("白狐リード"), "top HUD presents one unambiguous distance readout")
	_expect(not view.fox_preview_label.text.contains("Lv") and view.fox_preview_label.text.contains("狐火"), "secondary HUD keeps only actionable fire and seal counts")
	var die_target := view.board_canvas.get_global_transform_with_canvas() * view.board_cell_center(view.ROLL_DIE_CELL)
	var die_rect := view.roll_die_icon.get_global_rect()
	_expect(view.roll_die_icon.get_parent() == view.board_canvas and view.roll_die_icon.size.x >= 180.0, "large 3D die lives in the board layer")
	_expect(die_rect.get_center().distance_to(die_target) < 1.0, "rotating die is centered on the safe board cell (2,2)")
	_expect(not die_rect.intersects(view.roll_button.get_global_rect()), "rotating die does not overlap the ROLL button")

	battle.start_battle()
	await process_frame
	_expect(view.tutorial_overlay.visible and view.tutorial_progress.text == "1 / 3", "first launch opens the three-page tutorial")
	_expect(view.tutorial_title.text.contains("追いつけ") and view.tutorial_body.text.contains("3回") and view.tutorial_body.text.contains("PAIR +1"), "tutorial explains the first three-roll SLOT and objective")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "2 / 3" and view.tutorial_body.text.contains("外周20") and view.tutorial_body.text.contains("追いつけば勝ち"), "tutorial page two explains the outer-ring chase and win condition")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "3 / 3" and view.tutorial_body.text.contains("御朱印") and view.tutorial_body.text.contains("負け") and view.tutorial_button.text.contains("始める"), "tutorial page three explains fox-fire choices and loss condition")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(not view.tutorial_overlay.visible, "tutorial closes before the first roll")

	# QA helper must skip the tutorial and enter the roll-ready state.
	_expect(battle.show_for_qa(), "QA helper enters the live battle")
	var state := battle.get_node("Controller").get("state") as Object
	_expect(state != null and int(state.get("phase")) == 1, "QA state is roll-ready")

	# Two taps are the reference interaction: start the roll, then stop it.
	view.roll_button.emit_signal("pressed")
	for _frame: int in range(3):
		await process_frame
	_expect(view.is_die_rolling() and view.roll_button_copy.text == "止める", "first roll tap starts the readable die roll")
	_expect(view.roll_die_icon.state_name(0) == "ROLLING" and float(view.get("_roll_elapsed")) > 0.0, "ROLL animates the shared ivory-brass 3D die at the lap-scaled pace")
	var visible_face_on_stop := view.visible_die_face()
	view.roll_button.emit_signal("pressed")
	await process_frame
	var committed_faces := battle.snapshot().get("slot_faces", []) as Array
	var committed_face := int(committed_faces[0]) if not committed_faces.is_empty() else 0
	_expect(not view.is_die_rolling() and committed_faces.size() == 1, "second roll tap commits one SLOT face")
	_expect(committed_face == visible_face_on_stop, "STOP commits the face visible at the tap moment")
	_expect(view.settled_die_face() == committed_face and view.roll_button_hint.text == "出目 %d" % committed_face, "STOP locks the displayed result to the committed face")
	_expect(view.slot_faces[0].value == committed_face, "the same committed face is written into SLOT")
	await create_timer(0.25).timeout
	_expect(view.visible_die_face() == committed_face, "settled 3D top face matches the actual result")
	await create_timer(1.2).timeout
	state = battle.get_node("Controller").get("state") as Object
	_expect(state != null and int(state.get("phase")) == 1, "resolved movement automatically returns to roll-ready")
	view.roll_button.emit_signal("pressed")
	await process_frame
	_expect(view.is_die_rolling(), "the next single ROLL tap immediately starts rotation")
	view.roll_button.emit_signal("pressed")
	await create_timer(1.5).timeout

	# A fresh 3-roll checkpoint visibly presents the SLOT explanation.
	view.show_slot_explainer()
	_expect(view.slot_explainer.visible and view.slot_explainer_label.text.contains("PAIR +1"), "first three-roll SLOT explainer is visible")
	view.present_roll({"face": 4, "fox_face": 3, "player_move": 7, "slot_role": "TRIPLE", "slot_bonus": 3, "completed_slot_faces": [4, 4, 4], "cat_path": [], "fox_path": []})
	_expect(view.slot_role_label.text != "3/3", "completed SLOT role waits until movement and board effects finish")
	view.present_slot_resolution({"slot_role": "TRIPLE", "slot_bonus": 3, "completed_slot_faces": [4, 4, 4]})
	_expect(view.action_banner.visible and view.action_banner_label.text.contains("TRIPLE") and view.slot_explainer_label.text.contains("猫 +3"), "completed SLOT produces a large short role result")
	_expect(view.slot_role_label.text == "3/3", "completed SLOT count remains visible during the result hold")
	_expect(view.slot_faces[0].value == 4 and view.slot_faces[1].value == 4 and view.slot_faces[2].value == 4 and battle.SLOT_RESULT_HOLD_SECONDS >= 1.2,
		"completed SLOT keeps all three matching faces visible for a readable hold")

	# Turn presentation follows the fixed cat -> fox -> board-effects sequence.
	await view.animate_turn({
		"cat_start": Vector2i(2, 5), "cat_path": [Vector2i(1, 5)],
		"fox_start": Vector2i(1, 0), "fox_path": [Vector2i(0, 0)],
		"fox_move": -1, "reverse_card_used": true,
	})
	_expect(view.last_animation_sequence == ["cat", "fox", "effects"] and view.PIECE_STEP_SECONDS >= 0.12 and view.PIECE_STEP_SECONDS <= 0.18,
		"turn animation moves cat first, fox second, then resolves effects at the target cadence")
	_expect(view.action_banner_label.text == "反転札！ 白狐 −1", "reverse-card activation reports the signed fox movement")
	state.set("reverse_card_count", 1)
	view.refresh()
	_expect(view.reverse_card_label.visible and view.reverse_card_label.text == "反転札 ×1", "held reverse card appears as compact top sub-information")
	await view.animate_turn({"cat_path": [], "fox_path": [], "reverse_card_acquired": true})
	_expect(view.action_banner_label.text == "反転札GET！\n次のROLL、白狐が逆走", "face one reward explains the next-roll reversal")

	# Bottom sheet remains a bottom sheet and keeps both choices touchable.
	view.show_fire_choice(4, 2)
	_expect(view.fire_choice_overlay.visible and view.fire_choice_sheet.position.y >= 800.0, "fox-fire choice is a bottom sheet")
	_expect(view.cleanse_button.get_rect().size.y >= 52.0 and view.detour_button.get_rect().size.y >= 52.0, "fox-fire actions meet touch target height")
	view.hide_fire_choice()

	# Reduced motion is a public contract and must not hide the main controls.
	battle.set_reduced_motion(true)
	_expect(view.reduced_motion and view.roll_button.visible and view.slot_panel.visible, "reduced motion preserves actionable controls")
	_expect(view.roll_die_icon.state_name(0) != "ROLLING" and view.visible_die_face() == view.settled_die_face(), "reduced motion keeps the die on its real settled face")
	_expect(view.roll_button_copy.text == "ROLL" and view.roll_button_hint.text == "狙って止める", "reduced motion restores the ROLL button labels")

	root.size = Vector2i(360, 640)
	for _frame: int in range(3):
		await process_frame
	_expect(view.design_root.scale.x > 0.99 and view.design_root.scale.x < 1.01, "composition preserves logical scale in a 360x640 stretched viewport")
	_expect(view.roll_button.get_global_rect().size.x >= 52.0, "scaled roll control remains physically tappable")
	var small_die_target := view.board_canvas.get_global_transform_with_canvas() * view.board_cell_center(view.ROLL_DIE_CELL)
	_expect(view.roll_die_icon.get_global_rect().get_center().distance_to(small_die_target) < 1.0, "scaled board die remains centered on (2,2)")
	_expect(not view.roll_die_icon.get_global_rect().intersects(view.roll_button.get_global_rect()), "scaled board die stays clear of the ROLL button")

	# Terminal state stays visible until the explicit result action, and the
	# journey host receives the result exactly once.
	var finish_receipts: Array = []
	battle.battle_finished.connect(func(result: Variant) -> void: finish_receipts.append(result))
	battle.call("_on_controller_battle_finished", {"battle_id": "fox_fire_chase", "victory": true})
	_expect(view.result_overlay.visible and finish_receipts.is_empty(), "result remains on-screen before returning to the journey")
	view.result_button.emit_signal("pressed")
	view.result_button.emit_signal("pressed")
	_expect(finish_receipts.size() == 1, "result action hands off to the journey exactly once")

	print("FOX_FIRE_CHASE_UI_TESTS failures=%d" % failures)
	battle.free()
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
