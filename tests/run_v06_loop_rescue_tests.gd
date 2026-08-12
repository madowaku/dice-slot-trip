extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
const SaveData = preload("res://scripts/game/v06_session_save_data.gd")
const Atlas = preload("res://scripts/game/v06_atlas_view.gd")
const Localization = preload("res://scripts/ui/v06_localization.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_session_rescue_and_save()
	await _test_exit_emphasis_and_copy()
	print("V06_LOOP_RESCUE_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_session_rescue_and_save() -> void:
	var session: RefCounted = Session.new()
	for face: int in [6, 6, 6]:
		_roll_and_finish(session, face)
	_expect(session.position() == {"route_id":"main", "tile_index":18} and session.acknowledge_resolution(), "fixture clears its first slot set before W1")
	for face: int in [5, 1]:
		_roll_and_finish(session, face)
	_expect(session.position() == {"route_id":"loop_oasis_ring", "tile_index":3}, "fixture enters W1 at approved main index 24")
	_roll_and_finish(session, 6)
	_expect(session.position().tile_index == 1 and session.loop_wrap_count() == 1 and session.acknowledge_resolution(), "first EXIT pass remains in the ring, records one wrap, and clears the completed set")
	_roll_and_finish(session, 6)
	_roll_and_finish(session, 2)
	_expect(session.position().tile_index == 1 and session.loop_wrap_count() == 2, "second EXIT pass remains playable and records two wraps")
	var dto: Dictionary = SaveData.from_session(session)
	_expect(not dto.is_empty() and SaveData.validate(dto).ok, "two-wrap rescue progress is a valid stable save")
	var restored: RefCounted = Session.new()
	_expect(restored.restore_stable_snapshot(dto.session_state, 1000) and restored.loop_wrap_count() == 2, "rescue progress survives save restore")
	_roll_and_finish(restored, 6)
	_expect(restored.acknowledge_resolution(), "third rescue attempt clears its completed slot set before the final exact-stop roll")
	var rescue_result: Dictionary = _roll_and_finish(restored, 2)
	_expect(rescue_result.ok and restored.position() == {"route_id":"main", "tile_index":29}, "third EXIT pass returns to approved main index 29")
	_expect(restored.last_loop_rescue_triggered() and restored.active_warp_gate_id().is_empty() and restored.loop_wrap_count() == 0, "rescue is reported once and clears active loop state")
	_expect(int(restored.score_breakdown().get("discovery", 0)) == 0 and restored.score() == int(restored.score_breakdown().get("travel", 0)), "rescued exit adds no hidden bonus beyond travelled spaces")


func _test_exit_emphasis_and_copy() -> void:
	var original_locale := TranslationServer.get_locale()
	Localization.set_locale("ja")
	var atlas: Control = Atlas.new()
	atlas.size = Vector2(680, 700)
	root.add_child(atlas)
	await process_frame
	_expect(atlas.set_route_position({"route_id":"main", "tile_index":9}, true) and not bool(atlas.exit_emphasis_receipt().active), "main route does not reveal the detached-ring EXIT")
	atlas.set_route_position({"route_id":"loop_oasis_ring", "tile_index":3}, true)
	atlas.set_loop_rescue_progress(2, 3)
	var receipt: Dictionary = atlas.exit_emphasis_receipt()
	_expect(receipt.active and receipt.exit_index == 0 and receipt.steps == 5 and receipt.wrap_count == 2 and receipt.rescue_threshold == 3, "ring view exposes exact EXIT distance and rescue progress")
	_expect(Localization.text(&"LOOP_EXIT_DISTANCE") % 5 == "EXITまで 5" and Localization.text(&"LOOP_RESCUE_PROGRESS") % [2, 3] == "救済 2 / 3周", "Japanese ring guidance is concise and data-driven")
	Localization.set_locale("en")
	_expect(Localization.text(&"LOOP_EXIT_DISTANCE") % 5 == "5 to EXIT" and Localization.text(&"LOOP_RESCUE_TOAST").contains("third lap"), "ring guidance and rescue feedback are available in English")
	Localization.set_locale(original_locale)
	atlas.queue_free()
	await process_frame


func _roll_and_finish(session: RefCounted, face: int) -> Dictionary:
	var started: Dictionary = session.start_roll(face)
	if not bool(started.get("ok", false)):
		return started
	while session.has_pending_hops():
		session.next_hop()
	return session.finish_movement()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		push_error("FAIL: %s" % label)
