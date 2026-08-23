extends SceneTree

const BoardModelScript = preload("res://scripts/game/board_model.gd")
const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")

const LEGACY_SAVE_PATH := "user://dice_slot_trip_save.json"

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Pure helper contract for the replayable reward draw.
	var seeded_roll := BoardModelScript.stable_reward_roll("stable-seed-A")
	_expect(seeded_roll >= 0 and seeded_roll < 100, "stable reward roll stays inside the 0..99 pool")
	_expect(BoardModelScript.stable_reward_roll("stable-seed-A") == seeded_roll, "same seed redraws the identical reward roll")
	var distinct_rolls := {}
	for index: int in range(64):
		distinct_rolls[BoardModelScript.stable_reward_roll("spread-%d" % index)] = true
	_expect(distinct_rolls.size() >= 8, "distinct seeds spread across the reward table")

	var legacy_save := _read_optional_file(LEGACY_SAVE_PATH)
	var interrupted_snapshot := _build_interrupted_item_snapshot()

	var first_resume := await _boot_and_settle(interrupted_snapshot)
	var second_resume := await _boot_and_settle(interrupted_snapshot)

	_expect(first_resume == second_resume, "two resumes of one crashed ITEM landing converge identically")
	_expect(int(first_resume.get("pin", -1)) == 3, "pinpoint ticket grants exactly once across the replay")
	_expect(int(first_resume.get("fever", -1)) == 2, "unpicked choice modal never grants fever silently")
	_expect(int(first_resume.get("dice", -1)) == 3, "DOUBLE progression applies exactly once")
	print("ITEM_RECEIPT_DEBUG first=%s second=%s" % [first_resume, second_resume])
	_expect(bool(first_resume.get("cleared", false)), "interrupted transaction fully resolves on resume")

	_restore_optional_file(LEGACY_SAVE_PATH, legacy_save)
	print("ITEM_RECEIPT_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _build_interrupted_item_snapshot() -> Dictionary:
	var gs := root.get_node("GameState")
	gs.start_new_game()
	gs.set_route_position("main", 0)
	var roles: Dictionary = DiceLogicScript.evaluate_current([1, 1], 2)
	gs.apply_dice_roll_transition(2, roles)
	gs.begin_roll_transaction([1, 1], 2, 0)
	gs.mark_roll_started([1, 1])
	var movement: Dictionary = BoardModelScript.advance_route("main", 0, 2)
	gs.commit_roll_result([1, 1], 2, roles, 2, int(movement.tile_index), int(movement.laps), false, str(movement.route_id), movement.path, 0)
	_expect(not gs.roll_transaction.is_empty(), "crashed snapshot keeps a resumable transaction")
	return gs.to_dictionary()


func _boot_and_settle(snapshot: Dictionary) -> Dictionary:
	var gs := root.get_node("GameState")
	gs.apply_dictionary(snapshot.duplicate(true))
	OS.set_environment("DICE_QA_RESUME_ROLL", "1")
	# Deterministic no-op landing: the debug route keeps the transaction on the
	# main loop while skipping board presentation, so the receipt contract is
	# exercised without animation or encounter randomness.
	gs.flow_level = 0
	var host := Control.new()
	root.add_child(host)
	var main_scene := load("res://scenes/app/Main.tscn") as PackedScene
	host.add_child(main_scene.instantiate())
	var cleared := false
	var saw_encounter_modal := false
	for _frame: int in range(7200):
		await process_frame
		var screen: Node = host.get_children()[0] if host.get_child_count() > 0 else null
		if screen != null:
			screen.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
			screen.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
			var map_overlay: Node = screen.find_child("MapDiceOverlay", true, false)
			if map_overlay != null and bool(map_overlay.get("visible")):
				map_overlay.set("result_hold_duration", 0.01)
			var presentation: Node = screen.find_child("MapDicePresentation3D", true, false)
			if presentation != null:
				presentation.set_process(false)
			var boss_buttons: Array = screen.find_children("boss_action_*", "Button", true, false)
			if not boss_buttons.is_empty():
				saw_encounter_modal = true
			if not boss_buttons.is_empty() and not (boss_buttons[0] as Button).disabled:
				(boss_buttons[0] as Button).emit_signal("pressed")
			for close_name: String in ["return_to_trip", "next_trip"]:
				for close_button: Node in screen.find_children(close_name, "Button", true, false):
					if not (close_button as Button).disabled:
						(close_button as Button).emit_signal("pressed")
		if gs.roll_transaction.is_empty():
			cleared = true
			break
	if not cleared:
		push_error("resume did not settle; phase=%s" % str(gs.roll_transaction.get("phase", "")))
	OS.set_environment("DICE_QA_RESUME_ROLL", "")
	var result := {
		"dice": int(gs.current_dice_count),
		"pin": int(gs.inventory.get("pinpoint", 0)),
		"fever": int(gs.inventory.get("fever", 0)),
		"cleared": cleared,
		"saw_boss": saw_encounter_modal,
	}
	host.queue_free()
	await process_frame
	await process_frame
	return result


func _read_optional_file(path: String) -> PackedByteArray:
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path).to_utf8_buffer()
	return PackedByteArray()


func _restore_optional_file(path: String, bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(bytes)
		file.close()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
