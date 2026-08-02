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
	_expect(atlas.mouse_filter == Control.MOUSE_FILTER_PASS, "whole-map view accepts taps without stopping surrounding controls")

	_expect(atlas.toggle_overview_zoom(), "tap action opens the current-location detail view")
	var detail: Dictionary = atlas.overview_interaction_receipt()
	_expect(bool(detail.detail) and bool(detail.vertical_drag_enabled), "detail view enables bounded vertical dragging")
	_expect(is_equal_approx(float(detail.zoom), AtlasScript.OVERVIEW_DETAIL_ZOOM), "detail view uses the readable map zoom")
	_expect((detail.camera_world as Vector2).is_equal_approx(detail.current_world as Vector2), "detail view automatically focuses the current tile")

	var before_drag := (detail.camera_world as Vector2).y
	_expect(atlas.pan_overview_vertical(80.0), "vertical drag pans the zoomed whole map")
	var after_drag := (atlas.overview_interaction_receipt().camera_world as Vector2).y
	_expect(not is_equal_approx(before_drag, after_drag), "vertical drag changes the map camera")
	_expect(atlas.set_route_position({"route_id": "main", "tile_index": 36}, true), "current position can update while detail view is open")
	var refocused: Dictionary = atlas.overview_interaction_receipt()
	_expect((refocused.camera_world as Vector2).is_equal_approx(refocused.current_world as Vector2), "position updates refocus the detail camera")

	_expect(atlas.toggle_overview_zoom(), "second tap action returns to the whole-route view")
	_expect(not bool(atlas.overview_interaction_receipt().detail), "whole-route view clears detail state")
	_expect(not atlas.pan_overview_vertical(80.0), "wide overview ignores drag panning")
	atlas.set_overview_mode(false)
	_expect(atlas.mouse_filter == Control.MOUSE_FILTER_IGNORE, "closing the map restores input passthrough")

	host.queue_free()
	await process_frame
	print("V06_ATLAS_INTERACTION_TESTS failures=%d" % failures)
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	failures += 1
	push_error("FAIL: %s" % message)
