extends SceneTree

const FeedbackScript = preload("res://scripts/ui/v06_feedback_controller.gd")
const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const SessionScript = preload("res://scripts/game/v06_play_session.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var feedback: V06FeedbackController = FeedbackScript.new()
	root.add_child(feedback)
	await process_frame
	feedback.set_levels(2.0, -1.0, true)
	var clamped := feedback.feedback_receipt()
	_expect(clamped.master_volume == 1.0 and clamped.se_volume == 0.0 and clamped.dice_muted, "feedback settings clamp and retain dice mute")
	feedback.set_levels(1.0, 1.0, false)
	feedback.set_haptics_enabled(true)
	feedback.emit_feedback(FeedbackScript.EVENT_ROLL_STOP)
	feedback.emit_feedback(FeedbackScript.EVENT_MISSION_COMPLETE)
	feedback.emit_feedback(FeedbackScript.EVENT_VICTORY)
	var receipt := feedback.feedback_receipt()
	_expect(int(receipt.player_count) == 3, "feedback mixer remains bounded to three audio players")
	_expect(str(receipt.last_event) == "victory", "semantic feedback records the latest event")
	_expect(receipt.last_haptic_pattern == [34, 54, 34, 78], "victory uses the authored four-pulse haptic cadence")
	_expect(int(receipt.event_counts.get("roll_stop", 0)) == 1 and int(receipt.event_counts.get("mission_complete", 0)) == 1 and int(receipt.event_counts.get("victory", 0)) == 1, "feedback receipt counts each semantic event once")
	_expect(int(receipt.audio_play_count) == 6, "roll, mission, and victory layer only their bounded authored sounds")
	var global_state := root.get_node_or_null("GameState")
	if global_state != null:
		var original_haptics := bool(global_state.get("haptics_enabled"))
		global_state.set("haptics_enabled", false)
		var saved_settings: Dictionary = global_state.call("to_dictionary")
		global_state.set("haptics_enabled", true)
		global_state.call("apply_dictionary", saved_settings)
		_expect(not bool(global_state.get("haptics_enabled")), "haptic preference survives the existing settings save round-trip")
		global_state.set("haptics_enabled", original_haptics)

	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	await process_frame
	await process_frame
	var session: RefCounted = screen.session_for_test()
	_expect(session.enter_boss(0), "victory fixture enters the boss")
	for timestamp: int in [1, 2, 3, 4]:
		if session.phase() == SessionScript.PHASE_BOSS_FINISHED:
			break
		session.start_roll(6, timestamp)
		if session.phase() != SessionScript.PHASE_BOSS_FINISHED:
			session.acknowledge_boss_round()
	screen.call("_cancel_motion", session.position())
	screen.call("_refresh_ui")
	var score_copy := screen.get_node("%BossFinishScoreLabel") as Label
	var mission_copy := screen.get_node("%BossFinishMissionLabel") as Label
	var kicker := screen.get_node("%BossFinishKickerLabel") as Label
	_expect(session.phase() == SessionScript.PHASE_BOSS_FINISHED, "victory fixture reaches the dedicated finish phase")
	_expect(kicker.visible and kicker.text == "旅のゴール！", "victory presentation opens with a compact journey-complete kicker")
	_expect(score_copy.visible and score_copy.text.begins_with("旅したマス"), "victory presentation gives travelled distance the second visual tier")
	_expect(mission_copy.visible and mission_copy.text.begins_with("ミッション"), "victory presentation reports mission completion at a glance")
	var perfect_receipt: Dictionary = (screen.get_node("%HeartRoulettePanel") as Object).call("visual_receipt")
	_expect((screen.get_node("%NextLapButton") as Button).text == "次の旅へ" and bool(perfect_receipt.get("visible", false)) and not bool(perfect_receipt.get("wheel_visible", true)) and str(perfect_receipt.get("title", "")) == "PERFECT!" and str(perfect_receipt.get("hint", "")) == "HP FULL", "HP3 victory skips the wheel and keeps the existing next-journey action under PERFECT HP FULL")

	host.queue_free()
	feedback.queue_free()
	await process_frame
	print("V06_FEEDBACK_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
