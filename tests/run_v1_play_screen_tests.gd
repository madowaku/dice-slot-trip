extends SceneTree

const ScreenScene = preload("res://scenes/app/V1PlayScreen.tscn")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	_expect(screen.get_node("%PhaseLabel").text == "STAGE", "scene starts in stage phase")
	_expect(screen.get_node("%PositionLabel").text.contains("main_01"), "canonical start is shown")
	var first: Dictionary = screen.roll_for_test(3)
	_expect(first.effective_face == 3 and screen.session_for_test().slot.faces() == [3], "roll is delegated to session")
	_expect(screen.hop_for_test() == "main_02", "hop display consumes session movement path")
	screen.session_for_test().stage_position = "main_09"
	var branch: Dictionary = screen.roll_for_test(4)
	_expect(not screen.session_for_test().pending_stage_movement.is_empty() and screen.get_node("%MainlineButton").visible, "branch controls appear from session receipt")
	var chosen: Dictionary = screen.choose_branch_for_test("bypass")
	_expect(chosen.movement.position == "bazaar_02" and not screen.get_node("%BypassButton").visible, "branch choice settles through session")
	screen.session_for_test().stage_position = "main_56"
	var gate: Dictionary = screen.roll_for_test(6)
	_expect(gate.movement.position == "main_58" and screen.session_for_test().race != null and screen.get_node("%PhaseLabel").text == "BOSS RACE", "boss gate switches screen to race")
	var boss: Dictionary = screen.roll_for_test(6)
	_expect(boss.race_turn.player_roll == 6 and boss.race_turn.boss_roll == 1 and screen.get_node("%RaceLabel").text.contains("Turn 1"), "boss race receipt drives HUD")
	screen.session_for_test().race.player_position = 12
	screen.roll_for_test(1)
	_expect(not screen.session_for_test().result().is_empty() and screen.get_node("%ResultLabel").text.contains("Winner"), "terminal result is rendered")
	screen.reset_for_test()
	_expect(screen.session_for_test().stage_position == "main_01" and screen.get_node("%SlotLabel").text.contains("[-, -, -]"), "reset hook is deterministic")
	screen.queue_free()
	await process_frame
	print("V1_PLAY_SCREEN_TESTS failures=%d" % failures)
	quit(1 if failures else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
