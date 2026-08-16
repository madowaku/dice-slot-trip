extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
var failures := 0

func _init() -> void:
	var s: RefCounted = Session.new()
	var catalog: Array = s.mission_catalog()
	_expect(catalog.size() >= 8, "catalog retains legacy entries and adds the supported one-mission pool")
	_expect(_find(catalog, "cairo_face").target == 10 and _find(catalog, "cairo_face").reward_coins == 12, "dice mission exposes a readable face target and coin reward")
	_expect(_find(catalog, "cairo_coin15").target == 12 and _find(catalog, "cairo_coin15").reward_coins == 12, "coin mission keeps its stable ID and target12")
	_expect(_find(catalog, "cairo_role").target == 5 and _find(catalog, "cairo_role").reward_coins == 12, "role mission targets five qualifying roles")
	_expect(_find(catalog, "cairo_face6").difficulty == "EASY" and _find(catalog, "cairo_face10").difficulty == "NORMAL" and _find(catalog, "cairo_small_faces").face_counters == [1, 2, 3], "canonical seeded face rows expose their parameter metadata")
	var active: Dictionary = s.mission_state().active_mission
	_expect(s.resolve_active_missions().size() == 1 and s.resolve_active_missions()[0] == active.id and not active.legacy_mode, "new lap selects exactly one persisted mission")
	s.call("_set_active_mission_for_test", "cairo_face6")
	_expect(s.mission_state().active_mission.target_face >= 1 and s.mission_state().active_mission.target_face <= 6, "selected face mission exposes its seeded target face")
	s.call("_set_active_mission_for_test", "cairo_coin15")
	s.call("_advance_coin_mission", 12)
	_expect(s.mission_state().active_mission.progress == 12 and s.mission_state().active_mission.completed and s.mission_state().active_mission.reward_claimed and s.coins() == 12 and s.score() == 0, "coin mission completes once and rewards TRIP COIN without hidden score")
	var wallet_after_clear: int = s.coins()
	s.call("_advance_coin_mission", 20)
	_expect(s.coins() == wallet_after_clear and s.mission_state().active_mission.progress == 12, "completed mission does not replay its reward")
	s.call("_set_active_mission_for_test", "cairo_role")
	_expect(s.mission_state().active_mission.target_role == "TRIPLE" and s.mission_state().active_mission.short_text == "TRIPLEを5回作る", "role mission exposes the exact role target in its short copy")
	s.call("_award_role_score", &"PAIR")
	_expect(s.mission_state().active_mission.progress == 0, "a non-target role does not advance a specific-role mission")
	s.call("_award_role_score", &"TRIPLE")
	_expect(s.mission_state().active_mission.progress == 1 and s.coins() == wallet_after_clear + 6, "target role advances while normal SLOT pays its coin reward")
	s.call("_set_active_mission_for_test", "cairo_face")
	for _i: int in range(10): s.call("_advance_face_mission", Session.MISSION_FACE)
	_expect(s.mission_state().active_mission.completed and s.mission_state().active_mission.reward_claimed, "fixed-face mission completes and claims exactly once")
	s.retry_run()
	_expect(s.resolve_active_missions().size() == 1 and s.mission_state().active_mission.progress == 0 and not s.mission_state().active_mission.completed, "retry resets the featured mission for the next lap")
	print("V06_CANDIDATE_MISSION_TESTS failures=%d" % failures)
	quit(failures)

func _find(catalog: Array, id: String) -> Dictionary:
	for entry: Dictionary in catalog:
		if str(entry.get("id", "")) == id:
			return entry
	return {}

func _expect(ok: bool, _label: String) -> void:
	if not ok: failures += 1
