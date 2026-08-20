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
	_expect(view != null and view.backdrop.texture != null, "view uses the authored Kyoto board plate")
	_expect(view.board_cell_center(Vector2i(2, 5)).y > view.board_cell_center(Vector2i(2, 0)).y, "board exposes vertical cell centers")
	_expect(view.cell_touch_rect(Vector2i(2, 5)).size.x >= 52.0, "cell touch target meets physical minimum")
	_expect(view.slot_faces.size() == 3 and view.slot_panel != null, "view builds three SLOT faces")
	_expect(view.roll_button.size.x >= 100.0 and view.roll_button.size.y >= 80.0, "view builds a large round roll control")
	var die_target := view.board_canvas.get_global_transform_with_canvas() * view.board_cell_center(view.ROLL_DIE_CELL)
	var die_rect := view.roll_die_icon.get_global_rect()
	_expect(view.roll_die_icon.get_parent() == view.board_canvas, "rotating die lives in the board layer")
	_expect(die_rect.get_center().distance_to(die_target) < 1.0, "rotating die is centered on the safe board cell (2,2)")
	_expect(not die_rect.intersects(view.roll_button.get_global_rect()), "rotating die does not overlap the ROLL button")

	battle.start_battle()
	await process_frame
	_expect(view.tutorial_overlay.visible and view.tutorial_progress.text == "1 / 3", "first launch opens the three-page tutorial")
	_expect(view.tutorial_body.text.contains("3回") and view.tutorial_body.text.contains("PAIR +1"), "tutorial explains the first three-roll SLOT")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "2 / 3", "tutorial page two explains the outer ring")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(view.tutorial_progress.text == "3 / 3" and view.tutorial_button.text.contains("始める"), "tutorial page three explains fox-fire choices")
	view.tutorial_button.emit_signal("pressed")
	await process_frame
	_expect(not view.tutorial_overlay.visible, "tutorial closes before the first roll")

	# QA helper must skip the tutorial and enter the roll-ready state.
	_expect(battle.show_for_qa(), "QA helper enters the live battle")
	var state := battle.get_node("Controller").get("state") as Object
	_expect(state != null and int(state.get("phase")) == 1, "QA state is roll-ready")

	# Two taps are the reference interaction: start the roll, then stop it.
	var die_rotation_before := view.roll_die_icon.rotation
	view.roll_button.emit_signal("pressed")
	for _frame: int in range(3):
		await process_frame
	_expect(view.is_die_rolling() and view.roll_button_copy.text == "止める", "first roll tap starts the readable die roll")
	_expect(view.roll_die_icon.texture != null and not is_equal_approx(view.roll_die_icon.rotation, die_rotation_before), "ROLL animates the shared ivory-brass die")
	view.roll_button.emit_signal("pressed")
	await process_frame
	_expect(not view.is_die_rolling() and (battle.snapshot().get("slot_faces", []) as Array).size() == 1, "second roll tap commits one SLOT face")
	await create_timer(1.2).timeout

	# A fresh 3-roll checkpoint visibly presents the SLOT explanation.
	view.show_slot_explainer()
	_expect(view.slot_explainer.visible and view.slot_explainer_label.text.contains("PAIR +1"), "first three-roll SLOT explainer is visible")

	# Bottom sheet remains a bottom sheet and keeps both choices touchable.
	view.show_fire_choice(4, 2)
	_expect(view.fire_choice_overlay.visible and view.fire_choice_sheet.position.y >= 800.0, "fox-fire choice is a bottom sheet")
	_expect(view.cleanse_button.get_rect().size.y >= 52.0 and view.detour_button.get_rect().size.y >= 52.0, "fox-fire actions meet touch target height")
	view.hide_fire_choice()

	# Reduced motion is a public contract and must not hide the main controls.
	battle.set_reduced_motion(true)
	_expect(view.reduced_motion and view.roll_button.visible and view.slot_panel.visible, "reduced motion preserves actionable controls")
	_expect(is_zero_approx(view.roll_die_icon.rotation), "reduced motion resets the board die rotation")
	_expect(view.roll_button_copy.text == "ROLL" and view.roll_button_hint.text == "狙って止める", "reduced motion restores the ROLL button labels")

	root.size = Vector2i(360, 640)
	for _frame: int in range(3):
		await process_frame
	_expect(view.design_root.scale.x > 0.49 and view.design_root.scale.x < 0.51, "composition scales to 360x640")
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
