extends SceneTree

const AtlasScript = preload("res://scripts/game/v06_atlas_view.gd")

var failures := 0

func _init() -> void:
	_expect_state(0.0, &"MARKET", &"PYRAMID", 0.0)
	_expect_state(11.0, &"MARKET", &"PYRAMID", 1.0)
	_expect_state(12.0, &"PYRAMID", &"OASIS", 0.0)
	_expect_state(23.0, &"PYRAMID", &"OASIS", 1.0)
	_expect_state(24.0, &"OASIS", &"RUINS", 0.0)
	_expect_state(35.0, &"RUINS", &"DUNES", 0.0)
	_expect_state(46.0, &"DUNES", &"DUNES", 0.0)
	_expect_state(57.0, &"DUNES", &"DUNES", 0.0)
	for district_id: StringName in AtlasScript.DISTRICT_IDS:
		var texture := AtlasScript.DISTRICT_SCENERY_TEXTURES.get(district_id) as Texture2D
		_expect(texture != null and texture.get_size().x > texture.get_size().y, "%s atlas scenery is a loaded landscape texture" % district_id)
	_expect_loop_state(&"OASIS", true)
	_expect_loop_state(&"TOMB", true)
	print("V14_ATLAS_SCENERY failures=%d" % failures)
	quit(0 if failures == 0 else 1)

func _expect_state(tile_position: float, district_id: StringName, next_district_id: StringName, transition: float) -> void:
	var state := AtlasScript.district_scenery_state_for_main_position(tile_position)
	_expect(StringName(state.get("district_id", &"")) == district_id, "tile %.1f uses %s" % [tile_position, district_id])
	_expect(StringName(state.get("next_district_id", &"")) == next_district_id, "tile %.1f leads to %s" % [tile_position, next_district_id])
	_expect(is_equal_approx(float(state.get("transition", -1.0)), transition), "tile %.1f transition is %.2f" % [tile_position, transition])

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	failures += 1
	push_error("FAIL: %s" % message)

func _expect_loop_state(loop_name: StringName, expected_static: bool) -> void:
	var atlas := AtlasScript.new()
	var route_id := "loop_oasis_ring" if loop_name == &"OASIS" else "loop_tomb_ring"
	atlas._current_position = {"route_id": route_id, "tile_index": 1}
	var first := atlas._active_scenery_state()
	atlas._current_position = {"route_id": route_id, "tile_index": 6}
	var second := atlas._active_scenery_state()
	_expect(bool(first.get("background_static", false)) == expected_static, "%s loop marks scenery static" % loop_name)
	_expect(is_equal_approx(float(first.get("local_progress", -1.0)), float(second.get("local_progress", -2.0))), "%s loop keeps scenery position fixed" % loop_name)
	atlas.free()
