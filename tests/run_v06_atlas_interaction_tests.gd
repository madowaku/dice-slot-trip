extends SceneTree

const AtlasScript = preload("res://scripts/game/v06_atlas_view.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	root.add_child(host)
	var atlas: Control = AtlasScript.new()
	atlas.size = Vector2(590.0, 590.0)
	host.add_child(atlas)
	await process_frame

	_expect(atlas.mouse_filter == Control.MOUSE_FILTER_IGNORE, "local atlas leaves play-screen input untouched")
	_expect(atlas.set_route_position({"route_id": "main", "tile_index": 18}, true), "interaction test uses a canonical current position")
	atlas.set_overview_mode(true)
	var wide: Dictionary = atlas.overview_interaction_receipt()
	_expect(bool(wide.enabled) and not bool(wide.detail), "whole-map mode enables map-only interaction")
	_expect(is_equal_approx(float(wide.zoom), AtlasScript.OVERVIEW_ZOOM), "whole-map mode starts at the full-route zoom")
	_expect(atlas.mouse_filter == Control.MOUSE_FILTER_STOP, "open whole-map view owns gestures and stops backing controls")
	_test_two_axis_pan_and_bounds(atlas, Vector2(590.0, 590.0))

	atlas.call("_begin_overview_pointer", Vector2(120, 120))
	atlas.call("_finish_overview_pointer", Vector2(120, 120))
	var detail: Dictionary = atlas.overview_interaction_receipt()
	_expect(bool(detail.detail) and bool(detail.vertical_drag_enabled) and bool(detail.two_axis_drag_enabled), "tap opens detail with bounded two-axis dragging")
	_expect(is_equal_approx(float(detail.zoom), AtlasScript.OVERVIEW_DETAIL_ZOOM), "detail view uses the readable map zoom")
	_expect((detail.camera_world as Vector2).is_equal_approx(detail.current_world as Vector2), "detail view automatically focuses the current tile")

	_test_two_axis_pan_and_bounds(atlas, Vector2(590.0, 590.0))
	var detail_before_drag := bool(atlas.overview_interaction_receipt().detail)
	atlas.call("_begin_overview_pointer", Vector2(100, 100))
	atlas.call("_update_overview_pointer", Vector2(180, 160), Vector2(80, 60))
	atlas.call("_finish_overview_pointer", Vector2(180, 160))
	_expect(bool(atlas.overview_interaction_receipt().detail) == detail_before_drag, "drag above threshold never toggles overview zoom")
	_expect(atlas.set_route_position({"route_id": "main", "tile_index": 36}, true), "current position can update while detail view is open")
	var refocused: Dictionary = atlas.overview_interaction_receipt()
	_expect((refocused.camera_world as Vector2).is_equal_approx(refocused.current_world as Vector2), "position updates refocus the detail camera")

	_expect(atlas.toggle_overview_zoom(), "explicit second tap action returns to the whole-route view")
	_expect(not bool(atlas.overview_interaction_receipt().detail), "whole-route view clears detail state")
	_expect(atlas.pan_overview(Vector2(80.0, 40.0)), "wide overview also accepts direct two-axis panning")

	for route_position: Dictionary in [
		{"route_id":"main", "tile_index":0},
		{"route_id":"main", "tile_index":89},
		{"route_id":"loop_oasis_ring", "tile_index":0},
		{"route_id":"loop_tomb_ring", "tile_index":4},
	]:
		atlas.toggle_overview_zoom()
		_expect(atlas.set_route_position(route_position, true), "route extent fixture is canonical")
		var screen_point: Vector2 = atlas.overview_screen_position_for(route_position)
		_expect(Rect2(Vector2.ZERO, atlas.size).has_point(screen_point), "%s:%d is reachable inside the detail viewport" % [route_position.route_id, route_position.tile_index])
		atlas.toggle_overview_zoom()

	atlas.size = Vector2(360.0, 360.0)
	_test_two_axis_pan_and_bounds(atlas, atlas.size)
	atlas.toggle_overview_zoom()
	_test_two_axis_pan_and_bounds(atlas, atlas.size)
	atlas.toggle_overview_zoom()
	atlas.size = Vector2(20000.0, 20000.0)
	var fit_bounds: Rect2 = atlas.overview_interaction_receipt().camera_bounds
	_expect(is_zero_approx(fit_bounds.size.x) and is_zero_approx(fit_bounds.size.y), "axes lock to a centered camera whenever overview content fits")
	atlas.set_overview_mode(false)
	_expect(atlas.mouse_filter == Control.MOUSE_FILTER_IGNORE, "closing the map restores input passthrough")

	host.queue_free()
	await process_frame
	print("V06_ATLAS_INTERACTION_TESTS failures=%d" % failures)
	quit(0 if failures == 0 else 1)


func _test_two_axis_pan_and_bounds(atlas: Control, viewport_size: Vector2) -> void:
	atlas.size = viewport_size
	var before: Vector2 = atlas.overview_interaction_receipt().camera_world
	_expect(atlas.pan_overview(Vector2(120.0, 0.0)), "horizontal drag is handled in overview")
	var horizontal: Vector2 = atlas.overview_interaction_receipt().camera_world
	_expect(atlas.pan_overview(Vector2(0.0, -120.0)), "vertical drag is handled in overview")
	var vertical: Vector2 = atlas.overview_interaction_receipt().camera_world
	_expect(atlas.pan_overview(Vector2(-90.0, 70.0)), "diagonal drag updates both overview axes")
	var diagonal: Vector2 = atlas.overview_interaction_receipt().camera_world
	_expect(not before.is_equal_approx(horizontal) or not horizontal.is_equal_approx(vertical) or not vertical.is_equal_approx(diagonal), "overview camera responds to direct drag without changing zoom")
	atlas.pan_overview(Vector2(1000000.0, 1000000.0))
	var minimum: Vector2 = atlas.overview_interaction_receipt().camera_world
	var bounds: Rect2 = atlas.overview_interaction_receipt().camera_bounds
	_expect(minimum.is_equal_approx(bounds.position), "huge upper-left drag clamps both camera minima at %s" % viewport_size)
	atlas.pan_overview(Vector2(-1000000.0, -1000000.0))
	var maximum: Vector2 = atlas.overview_interaction_receipt().camera_world
	_expect(maximum.is_equal_approx(bounds.end), "huge lower-right drag clamps both camera maxima at %s" % viewport_size)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
