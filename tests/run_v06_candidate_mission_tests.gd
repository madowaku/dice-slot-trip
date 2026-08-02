extends SceneTree

const Session = preload("res://scripts/game/v06_play_session.gd")
var failures := 0

func _init() -> void:
	var s: RefCounted = Session.new()
	var catalog: Array = s.mission_catalog()
	_expect(catalog.size() == 6, "catalog has six candidates")
	_expect(s.mission_state().active_ids == ["cairo_coin15", "cairo_triple2", "cairo_no_damage"], "fixed three active")
	_expect(s.resolve_active_missions() == ["cairo_coin15", "cairo_triple2", "cairo_no_damage"], "one per pillar resolver")
	s.call("_advance_coin_mission", 20)
	var ranks: Dictionary = s.mission_state().ranks
	_expect(int(ranks.get("cairo_coin15", 0)) == 3 and s.score() == 3500, "coin jump awards bronze silver gold")
	s.call("_advance_coin_mission", 1)
	_expect(s.score() == 3500, "rank rewards idempotent")
	s.call("_award_role_score", &"MIX")
	_expect(int(s.mission_state().role_successes) == 0, "MIX excluded")
	s.call("_award_role_score", &"PAIR")
	_expect(s.mission_state().ranks.has("cairo_triple2"), "role bronze")
	s.call("_complete_no_damage_mission")
	_expect(s.mission_state().ranks.has("cairo_no_damage"), "all3 bronze")
	s.retry_run()
	_expect(s.mission_state().ranks.is_empty(), "lap reset")
	print("V06_CANDIDATE_MISSION_TESTS failures=%d" % failures)
	quit(failures)

func _expect(ok: bool, _label: String) -> void:
	if not ok: failures += 1
