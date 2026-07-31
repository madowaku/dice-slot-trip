extends Control

const ScreenScene := preload("res://scenes/app/V06PlayScreen.tscn")
const Session := preload("res://scripts/game/v06_play_session.gd")
const QA_FACES: Array[int] = [1, 1, 6, 6, 6]

var screen: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	OS.set_environment("DICE_QA_V06_SCENARIO", "boss_ready")
	screen = ScreenScene.instantiate()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	call_deferred("_record_race")


func _record_race() -> void:
	await get_tree().create_timer(1.65).timeout
	screen.set("_boss_intro_active", false)
	screen.set("_boss_intro_complete", true)
	screen.call("_refresh_ui")
	await get_tree().create_timer(0.75).timeout
	for face: int in QA_FACES:
		if screen.session_for_test().phase() == Session.PHASE_BOSS_FINISHED:
			break
		await _play_intentional_face(face)
		if screen.session_for_test().phase() == Session.PHASE_BOSS_ROUND_RESULT:
			await get_tree().create_timer(0.95).timeout
			screen.call("_on_boss_round_acknowledged")
			await get_tree().create_timer(0.55).timeout
	await get_tree().create_timer(2.4).timeout
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	get_tree().quit()


func _play_intentional_face(face: int) -> void:
	screen.call("_start_roll")
	await get_tree().create_timer(0.32).timeout
	screen.set("_rolling_slot_face", face)
	screen.set("_rolling_slot_elapsed", float(face - 1) * 0.06)
	screen.call("_refresh_rolling_slot_preview")
	screen.call("_refresh_boss_landing_preview", face)
	for ignored: int in range(42):
		screen.set("_rolling_slot_face", face)
		screen.set("_rolling_slot_elapsed", float(face - 1) * 0.06)
		screen.call("_refresh_rolling_slot_preview")
		await get_tree().process_frame
	screen.set("_rolling", false)
	screen.set("_slot_settling", true)
	screen.set("_shown_face", face)
	var committed_face: Array[int] = [face]
	screen.get_node("%BossDicePresentation").call("present", committed_face, false, 1)
	screen.call("_refresh_ui")
	screen.call("_run_face", face)
	var started := false
	while true:
		await get_tree().process_frame
		var phase: StringName = screen.session_for_test().phase()
		started = started or phase != Session.PHASE_BOSS_ROLL_READY
		if started and not bool(screen.get("_boss_roll_animation_active")):
			break
