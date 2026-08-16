class_name V06AtlasView
extends Control

const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const APP_FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const PARCHMENT_BASE: Texture2D = preload("res://assets/art/v06/atlas/parchment-base.png")
const CAIRO_CARTOGRAPHY_INK: Texture2D = preload("res://assets/art/v06/atlas/cairo-cartography-ink.png")
const RAISED_ROUTE_TILES: Texture2D = preload("res://assets/art/v06/atlas/raised-route-tiles.png")
const GOLD_BOSS_GATE: Texture2D = preload("res://assets/art/v06/boss/gold-boss-gate.png")
const CAT_IDLE_STRIP: Texture2D = preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-idle-strip.png")
const CAT_JUMP_STRIP: Texture2D = preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-jump-strip.png")
const CAT_LAND_STRIP: Texture2D = preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-land-strip.png")
const KIND_ICON_NORMAL: Texture2D = preload("res://assets/art/v06/tile_kind_icons/normal-footprints.png")
const KIND_ICON_COIN: Texture2D = preload("res://assets/art/v06/tile_kind_icons/coin-tokens-stack.png")
const KIND_ICON_REST: Texture2D = preload("res://assets/art/v06/tile_kind_icons/rest-campfire.png")
const KIND_ICON_RISK: Texture2D = preload("res://assets/art/v06/tile_kind_icons/risk-skull.png")
const KIND_ICON_ITEM: Texture2D = preload("res://assets/art/v06/tile_kind_icons/item-pouch.png")
const KIND_ICON_EVENT: Texture2D = preload("res://assets/art/v06/tile_kind_icons/event-book-open.png")
const DISTRICT_SCENERY_TEXTURES: Dictionary = {
	&"MARKET": preload("res://assets/art/v14/cairo_districts/market.png"),
	&"PYRAMID": preload("res://assets/art/v14/cairo_districts/pyramid.png"),
	&"OASIS": preload("res://assets/art/v14/cairo_districts/oasis.png"),
	&"RUINS": preload("res://assets/art/v14/cairo_districts/ruins.png"),
	&"DUNES": preload("res://assets/art/v14/cairo_districts/dunes.png"),
}
const DISTRICT_IDS: Array[StringName] = [&"MARKET", &"PYRAMID", &"OASIS", &"RUINS", &"DUNES"]
const DISTRICT_START_TILES: Array[int] = [0, 18, 36, 54, 72]
const DISTRICT_TRANSITION_TILES := 3.0

const ROUTE_STYLE_MAIN: StringName = &"main_teal_solid"
const ROUTE_STYLE_BYPASS: StringName = &"bypass_rust_dashed"
const ROUTE_STYLE_LOOP: StringName = &"loop_teal_ring_gold_exit"
const CAMERA_FOLLOW_SECONDS := 0.28
const HOP_SECONDS := 0.30
const STRAIGHT_TRAVEL_MAX_STEPS := 6
const STRAIGHT_TARGET_PREVIEW_SECONDS := 0.20
const STRAIGHT_CAMERA_FOLLOW_SECONDS := 0.42
const PORTAL_TRANSFER_HALF_SECONDS := 0.34
const BYPASS_ENTRY_SECONDS := 0.72
const STAGE_SWEEP_SECONDS := 4.20
const STAGE_OVERVIEW_HOLD_SECONDS := 0.80
const CONTEXT_PREVIEW_IN_SECONDS := 0.55
const CONTEXT_PREVIEW_HOLD_SECONDS := 2.80
const CONTEXT_PREVIEW_OUT_SECONDS := 0.55
const OVERVIEW_ZOOM := 0.28
const OVERVIEW_DETAIL_ZOOM := 0.52
const OVERVIEW_CENTER := Vector2(520.0, 60.0)
const OVERVIEW_TAP_DRAG_THRESHOLD := 18.0
const OVERVIEW_VISUAL_MARGIN_WORLD := 96.0
const OVERVIEW_EDGE_PADDING := 18.0
const LANDING_NORMAL_SECONDS := 0.48
const LANDING_SPECIAL_SECONDS := 0.78
const LANDING_HOLD_SECONDS := 0.08
const FORWARD_VISIBLE := 6
const PROMINENT_MIN := 6
const PROMINENT_MAX := 6
const CAT_TILE_SCALE := 1.42
const CAT_FRAME_SIZE := Vector2(192.0, 192.0)
const CAT_FEET_ANCHOR := Vector2(96.0, 179.0)
const CAT_DRAW_SCALE := 0.65
const ROUTE_TILE_CELL_SIZE := Vector2(128.0, 128.0)
const ROUTE_TILE_ANCHOR := Vector2(64.0, 118.0)
const BOSS_GATE_CELL_SIZE := Vector2(256.0, 256.0)
const BOSS_GATE_ANCHOR := Vector2(128.0, 246.0)
const LOCAL_TILE_DIAMETER_SCALE := 3.05
const LOCAL_KIND_BADGE_RADIUS_SCALE := 1.0
const CAROUSEL_TILE_RADIUS := 30.0
const CAROUSEL_CURRENT_RADIUS := 34.0
const CAROUSEL_CONTEXT_RADIUS := 26.0
const CAROUSEL_CONTEXT_SPACING := 96.0
const LOOP_ROUTE_RADIUS := 190.0
const CAROUSEL_SLOT_NORMALIZED := [
	Vector2(0.484375, 0.710744), Vector2(0.671875, 0.677686),
	Vector2(0.820313, 0.561983), Vector2(0.851563, 0.396694),
	Vector2(0.742188, 0.272727), Vector2(0.570313, 0.223140),
	Vector2(0.390625, 0.256198),
]

const PARCHMENT := Color("#e8d7b5")
const PARCHMENT_DARK := Color("#c9ad7d")
const INK := Color("#473b30")
const MUTED_INK := Color("#796b59")
const MAIN_TEAL := Color("#277c80")
const BYPASS_RUST := Color("#ad5f45")
const LOOP_TEAL := Color("#368d8b")
const LOOP_TOMB := Color("#73558f")
const EXIT_GOLD := Color("#c89a43")
const TILE_FACE := Color("#f1e2c2")
const TILE_EDGE := Color("#8f7755")
const KIND_NORMAL := Color("#d8c49c")
const KIND_COIN := Color("#dfb54d")
const KIND_REST := Color("#79a77d")
const KIND_RISK := Color("#ce684d")
const KIND_ITEM := Color("#6e9faf")
const KIND_EVENT := Color("#9274aa")
const KIND_WARP := Color("#657fb4")
const KIND_BOSS := Color("#b78a36")
const CURRENT_RING_COLOR := Color("#f8d48c")
const CURRENT_RING_ACCENT := Color("#2f9090")
const CURRENT_RING_WIDTH := 3.4
const BOSS_BADGE_WINE := Color("#341b24")
const BOSS_BADGE_WINE_LIGHT := Color("#6d2d3a")
const BOSS_BADGE_GOLD := Color("#f7d36c")
const BOSS_BADGE_GOLD_LIGHT := Color("#fff0b0")
const BOSS_BADGE_RED := Color("#be4c48")

var _course: RefCounted
var _definition: Dictionary = {}
var _route_points: Dictionary = {}
var _current_position: Dictionary = {"route_id": "main", "tile_index": 0}
var _cat_world := Vector2.ZERO
var _cat_lift := 0.0
var _cat_animation_state: StringName = &"idle"
var _cat_animation_frame := 0
var _camera_world := Vector2.ZERO
var _camera_target_world := Vector2.ZERO
var _world_zoom := 0.72
var _elapsed := 0.0
var _exit_steps := -1
var _loop_wrap_count := 0
var _loop_rescue_threshold := V06CourseModelScript.LOOP_RESCUE_WRAP_THRESHOLD
var _overview_mode := false
var _overview_detail_mode := false
var _overview_pointer_active := false
var _overview_pointer_origin := Vector2.ZERO
var _overview_pointer_travel := 0.0
var _kind_preview_overrides: Dictionary = {}
var _consumed_warp_gate_ids := {}
var _consumed_reward_node_keys := {}
var _carousel_progress := 1.0
var _carousel_previous_position: Dictionary = {}
var _carousel_tile_is_current := false
var _carousel_tile_is_context := false
var _card_roll_preview := -1
var _card_roll_preview_key := ""
var _card_roll_preview_alpha := 0.0
var _landing_kind := ""
var _landing_progress := 1.0
var _landing_result_text := ""
var _straight_travel_active := false
var _straight_travel_start_position: Dictionary = {}
var _straight_travel_distance := 0
var _straight_travel_player_step := 0
var _straight_step_from := 0
var _straight_step_progress := 1.0
var _straight_camera_follow_progress := 0.0
var _straight_camera_offset := 0.0
var _straight_travel_positions: Array[Dictionary] = []
var _straight_step_tween: Tween
var _straight_camera_tween: Tween
var _portal_transfer_tween: Tween
var _bypass_entry_tween: Tween
var _camera_presentation_tween: Tween
var _landing_tween: Tween
var _roll_preview_tween: Tween
var _visual_motion_generation := 0
var _portal_transfer_active := false
var _portal_transfer_progress := 0.0
var _portal_transfer_color := LOOP_TEAL
var _bypass_entry_active := false
var _bypass_entry_progress := 0.0
var _bypass_entry_name := ""
var _bypass_entry_saved_steps := 0
var _bypass_entry_play_count := 0
var _camera_presentation_active := false
var _camera_presentation_kind := ""
var _comparison_route_id := ""
var _comparison_targets: Dictionary = {}
var _camera_presentation_play_counts := {
	"stage_sweep": 0,
	"branch_context": 0,
	"loop_return_context": 0,
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_course = V06CourseModelScript.new()
	if _course.load_file("res://data/stages/v06_cairo_course.json"):
		_definition = _course.definition()
	_build_route_points()
	set_route_position(_current_position, true)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _cat_animation_state == &"idle":
		_cat_animation_frame = idle_animation_frame_for_elapsed(_elapsed)
	if not _camera_presentation_active:
		var follow_weight := 1.0 - exp(-delta / CAMERA_FOLLOW_SECONDS)
		_camera_world = _camera_world.lerp(_camera_target_world, follow_weight)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _overview_mode or _camera_presentation_active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_begin_overview_pointer(touch.position)
		else:
			_finish_overview_pointer(touch.position)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_update_overview_pointer(drag.position, drag.relative)
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var button := event as InputEventMouseButton
		if button.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if button.pressed:
			_begin_overview_pointer(button.position)
		else:
			_finish_overview_pointer(button.position)
		accept_event()
	elif event is InputEventMouseMotion and _overview_pointer_active:
		var motion := event as InputEventMouseMotion
		if motion.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_update_overview_pointer(motion.position, motion.relative)
			accept_event()


func set_route_position(route_position: Dictionary, immediate := false) -> bool:
	if not _is_known_position(route_position):
		return false
	_current_position = route_position.duplicate(true)
	_cat_world = world_position_for(_current_position)
	_camera_target_world = _clamp_overview_camera(world_position_for(_current_position)) if _overview_mode and _overview_detail_mode else _camera_focus_for(_current_position)
	if immediate or _camera_world == Vector2.ZERO:
		_camera_world = _camera_target_world
	if _course.is_loop_route(str(_current_position.route_id)):
		_exit_steps = _course.steps_to_exit(_current_position)
	else:
		_exit_steps = -1
	queue_redraw()
	return true


func set_overview_mode(enabled: bool) -> void:
	_overview_mode = enabled
	_overview_detail_mode = false
	_overview_pointer_active = false
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if enabled:
		_world_zoom = OVERVIEW_ZOOM
		_camera_target_world = _clamp_overview_camera(OVERVIEW_CENTER)
		_camera_world = _camera_target_world
	else:
		_world_zoom = 0.72
		_camera_target_world = _camera_focus_for(_current_position)
		_camera_world = _camera_target_world
	queue_redraw()


func is_overview_mode() -> bool:
	return _overview_mode


func toggle_overview_zoom() -> bool:
	if not _overview_mode or _camera_presentation_active:
		return false
	_overview_detail_mode = not _overview_detail_mode
	_world_zoom = OVERVIEW_DETAIL_ZOOM if _overview_detail_mode else OVERVIEW_ZOOM
	_camera_target_world = _clamp_overview_camera(world_position_for(_current_position) if _overview_detail_mode else OVERVIEW_CENTER)
	_camera_world = _camera_target_world
	queue_redraw()
	return true


func pan_overview_vertical(screen_delta_y: float) -> bool:
	return pan_overview(Vector2(0.0, screen_delta_y))


func pan_overview(screen_delta: Vector2) -> bool:
	if not _overview_mode or _camera_presentation_active:
		return false
	_camera_world = _clamp_overview_camera(_camera_world - screen_delta / maxf(_world_zoom, 0.01))
	_camera_target_world = _camera_world
	queue_redraw()
	return true


func overview_interaction_receipt() -> Dictionary:
	return {
		"enabled": _overview_mode and not _camera_presentation_active,
		"detail": _overview_detail_mode,
		"zoom": _world_zoom,
		"camera_world": _camera_world,
		"current_world": world_position_for(_current_position),
		"vertical_drag_enabled": _overview_mode,
		"two_axis_drag_enabled": _overview_mode,
		"camera_bounds": _overview_camera_bounds(),
		"content_bounds": _overview_content_bounds(),
	}


func overview_screen_position_for(route_position: Dictionary) -> Vector2:
	return _to_screen(world_position_for(route_position))


func _begin_overview_pointer(position: Vector2) -> void:
	_overview_pointer_active = true
	_overview_pointer_origin = position
	_overview_pointer_travel = 0.0


func _update_overview_pointer(position: Vector2, relative: Vector2) -> void:
	if not _overview_pointer_active:
		return
	_overview_pointer_travel = maxf(_overview_pointer_travel, _overview_pointer_origin.distance_to(position))
	if _overview_pointer_travel > OVERVIEW_TAP_DRAG_THRESHOLD:
		pan_overview(relative)


func _finish_overview_pointer(position: Vector2) -> void:
	if not _overview_pointer_active:
		return
	_overview_pointer_travel = maxf(_overview_pointer_travel, _overview_pointer_origin.distance_to(position))
	_overview_pointer_active = false
	if _overview_pointer_travel <= OVERVIEW_TAP_DRAG_THRESHOLD:
		toggle_overview_zoom()


func _overview_content_bounds() -> Rect2:
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for route_points: Array in _route_points.values():
		for point: Vector2 in route_points:
			minimum.x = minf(minimum.x, point.x)
			minimum.y = minf(minimum.y, point.y)
			maximum.x = maxf(maximum.x, point.x)
			maximum.y = maxf(maximum.y, point.y)
	if minimum.x > maximum.x or minimum.y > maximum.y:
		return Rect2()
	var margin := Vector2.ONE * OVERVIEW_VISUAL_MARGIN_WORLD
	return Rect2(minimum - margin, maximum - minimum + margin * 2.0)


func _overview_focus() -> Vector2:
	return Vector2(size.x * 0.43, size.y * 0.56)


func _overview_camera_bounds() -> Rect2:
	var content := _overview_content_bounds()
	if content.size == Vector2.ZERO:
		return Rect2(_camera_world, Vector2.ZERO)
	var zoom := maxf(_world_zoom, 0.01)
	var focus := _overview_focus()
	var viewport_extent := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	var padding := Vector2.ONE * OVERVIEW_EDGE_PADDING
	var minimum_camera := content.position + (focus - padding) / zoom
	var maximum_camera := content.end - (viewport_extent - padding - focus) / zoom
	for axis: int in range(2):
		if minimum_camera[axis] > maximum_camera[axis]:
			var centered := content.get_center()[axis] - (viewport_extent[axis] * 0.5 - focus[axis]) / zoom
			minimum_camera[axis] = centered
			maximum_camera[axis] = centered
	return Rect2(minimum_camera, maximum_camera - minimum_camera)


func _clamp_overview_camera(candidate: Vector2) -> Vector2:
	var bounds := _overview_camera_bounds()
	return Vector2(
		clampf(candidate.x, bounds.position.x, bounds.end.x),
		clampf(candidate.y, bounds.position.y, bounds.end.y)
	)


func play_stage_overview_sweep(keep_overview := false) -> void:
	_begin_camera_presentation("stage_sweep")
	var main_points: Array = _route_points.get(V06CourseModelScript.ROUTE_MAIN, [])
	if main_points.is_empty():
		_restore_local_camera()
		return
	_overview_mode = true
	_world_zoom = 0.42
	_camera_world = main_points[mini(3, main_points.size() - 1)]
	_camera_target_world = _camera_world
	queue_redraw()
	var generation := _visual_motion_generation
	_camera_presentation_tween = create_tween()
	_camera_presentation_tween.set_parallel(true)
	_camera_presentation_tween.tween_property(self, "_camera_world", main_points[maxi(main_points.size() - 5, 0)], STAGE_SWEEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_presentation_tween.tween_property(self, "_world_zoom", 0.34, STAGE_SWEEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_presentation_tween.set_parallel(false)
	_camera_presentation_tween.tween_method(_set_camera_frame.bind(Vector2(520.0, 60.0)), 0.34, 0.28, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_presentation_tween.tween_interval(STAGE_OVERVIEW_HOLD_SECONDS)
	await _wait_for_visual_tween(_camera_presentation_tween, generation)
	if generation != _visual_motion_generation:
		return
	if keep_overview:
		set_overview_mode(true)
		_camera_presentation_active = false
		_camera_presentation_kind = ""
	else:
		_restore_local_camera()


func play_branch_context(route_id: String) -> void:
	var definition := _bypass_definition(route_id)
	if definition.is_empty():
		return
	var fork := world_position_for({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": _fork_index(route_id)})
	var rejoin := world_position_for({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": _rejoin_index(route_id)})
	var branch_points: Array = _route_points.get(route_id, [])
	var center := (fork + rejoin) * 0.5
	for point: Vector2 in branch_points:
		center += point / float(maxi(branch_points.size(), 1)) * 0.30
	center = center / 1.30
	await _play_context_preview("branch_context", center, 0.50)


func show_branch_comparison(route_id: String, targets: Dictionary = {}) -> bool:
	var definition := _bypass_definition(route_id)
	if definition.is_empty():
		return false
	var fork_index := _fork_index(route_id)
	set_route_position({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": fork_index}, true)
	var fork := world_position_for({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": fork_index})
	var rejoin := world_position_for({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": _rejoin_index(route_id)})
	var branch_points: Array = _route_points.get(route_id, [])
	var center := (fork + rejoin) * 0.5
	for point: Vector2 in branch_points:
		center += point / float(maxi(branch_points.size(), 1)) * 0.30
	center /= 1.30
	_comparison_route_id = route_id
	_comparison_targets = targets.duplicate(true)
	_overview_mode = true
	_overview_detail_mode = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_world_zoom = 0.50
	_camera_world = center
	_camera_target_world = center
	queue_redraw()
	return true


func comparison_target_receipt() -> Dictionary:
	return _comparison_targets.duplicate(true)


func play_loop_return_context(route_position: Dictionary) -> void:
	if str(route_position.get("route_id", "")) != V06CourseModelScript.ROUTE_MAIN:
		return
	var tile_index := int(route_position.get("tile_index", 0))
	var main_points: Array = _route_points.get(V06CourseModelScript.ROUTE_MAIN, [])
	if main_points.is_empty():
		return
	var from_index := maxi(tile_index - 3, 0)
	var to_index := mini(tile_index + 4, main_points.size() - 1)
	var center := Vector2.ZERO
	for index: int in range(from_index, to_index + 1):
		center += main_points[index]
	center /= float(to_index - from_index + 1)
	await _play_context_preview("loop_return_context", center, 0.52)


func camera_presentation_receipt() -> Dictionary:
	return {
		"active": _camera_presentation_active,
		"kind": _camera_presentation_kind,
		"overview": _overview_mode,
		"zoom": _world_zoom,
		"play_counts": _camera_presentation_play_counts.duplicate(true),
	}


func _play_context_preview(kind: String, center: Vector2, zoom: float) -> void:
	_begin_camera_presentation(kind)
	_overview_mode = true
	var generation := _visual_motion_generation
	_camera_presentation_tween = create_tween()
	_camera_presentation_tween.set_parallel(true)
	_camera_presentation_tween.tween_property(self, "_camera_world", center, CONTEXT_PREVIEW_IN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_presentation_tween.tween_property(self, "_world_zoom", zoom, CONTEXT_PREVIEW_IN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_presentation_tween.set_parallel(false)
	_camera_presentation_tween.tween_interval(CONTEXT_PREVIEW_HOLD_SECONDS)
	_camera_presentation_tween.set_parallel(true)
	_camera_presentation_tween.tween_property(self, "_camera_world", _camera_focus_for(_current_position), CONTEXT_PREVIEW_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_camera_presentation_tween.tween_property(self, "_world_zoom", 0.72, CONTEXT_PREVIEW_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_camera_presentation_tween.set_parallel(false)
	await _wait_for_visual_tween(_camera_presentation_tween, generation)
	if generation != _visual_motion_generation:
		return
	_restore_local_camera()


func _begin_camera_presentation(kind: String) -> void:
	if is_instance_valid(_camera_presentation_tween):
		_camera_presentation_tween.kill()
	_camera_presentation_active = true
	_camera_presentation_kind = kind
	_camera_presentation_play_counts[kind] = int(_camera_presentation_play_counts.get(kind, 0)) + 1


func _set_camera_frame(zoom: float, center: Vector2) -> void:
	_world_zoom = zoom
	_camera_world = center
	queue_redraw()


func _restore_local_camera() -> void:
	_comparison_route_id = ""
	_comparison_targets.clear()
	_overview_mode = false
	_overview_detail_mode = false
	_overview_pointer_active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_zoom = 0.72
	_camera_target_world = _camera_focus_for(_current_position)
	_camera_world = _camera_target_world
	_camera_presentation_active = false
	_camera_presentation_kind = ""
	queue_redraw()


func animate_hop_to(route_position: Dictionary, duration := HOP_SECONDS) -> void:
	if not _is_known_position(route_position):
		return
	var start := _cat_world
	var target := world_position_for(route_position)
	_carousel_previous_position = _current_position.duplicate(true)
	_carousel_progress = 0.0
	_current_position = route_position.duplicate(true)
	_camera_target_world = _camera_focus_for(_current_position)
	var tween := create_tween()
	tween.tween_method(_set_hop_progress.bind(start, target), 0.0, 1.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_cat_world = target
	_cat_lift = 0.0
	_cat_animation_state = &"idle"
	_cat_animation_frame = 0
	_carousel_progress = 1.0
	_carousel_previous_position.clear()
	if _course.is_loop_route(str(_current_position.route_id)):
		_exit_steps = _course.steps_to_exit(_current_position)
	else:
		_exit_steps = -1
	queue_redraw()


func animate_transfer_to(route_position: Dictionary) -> void:
	# Portal and exit transfers cost no die step, but a short, lower lift keeps the
	# graph transition legible instead of snapping the marker across routes.
	await animate_hop_to(route_position, HOP_SECONDS)


func animate_portal_transfer_to(route_position: Dictionary) -> void:
	if not _is_known_position(route_position):
		return
	if is_instance_valid(_portal_transfer_tween):
		_portal_transfer_tween.kill()
	var source_route := str(_current_position.get("route_id", ""))
	_portal_transfer_color = LOOP_TOMB if source_route == V06CourseModelScript.ROUTE_LOOP_TOMB else LOOP_TEAL
	_portal_transfer_active = true
	_portal_transfer_progress = 0.0
	var generation := _visual_motion_generation
	_portal_transfer_tween = create_tween()
	_portal_transfer_tween.tween_method(_set_portal_transfer_progress, 0.0, 1.0, PORTAL_TRANSFER_HALF_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _wait_for_visual_tween(_portal_transfer_tween, generation)
	if generation != _visual_motion_generation:
		return
	set_route_position(route_position, true)
	_portal_transfer_tween = create_tween()
	_portal_transfer_tween.tween_method(_set_portal_transfer_progress, 1.0, 0.0, PORTAL_TRANSFER_HALF_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _wait_for_visual_tween(_portal_transfer_tween, generation)
	if generation != _visual_motion_generation:
		return
	_portal_transfer_active = false
	_portal_transfer_progress = 0.0
	queue_redraw()


func portal_transfer_active() -> bool:
	return _portal_transfer_active


func _set_portal_transfer_progress(value: float) -> void:
	_portal_transfer_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func play_bypass_entry_effect(route_id: String) -> void:
	var definition := _bypass_definition(route_id)
	if definition.is_empty():
		return
	if is_instance_valid(_bypass_entry_tween):
		_bypass_entry_tween.kill()
	_bypass_entry_name = str(definition.get("name_ja", "近道"))
	_bypass_entry_saved_steps = int(definition.get("saved_steps", 0))
	_bypass_entry_active = true
	_bypass_entry_progress = 0.0
	_bypass_entry_play_count += 1
	var generation := _visual_motion_generation
	_bypass_entry_tween = create_tween()
	_bypass_entry_tween.tween_method(_set_bypass_entry_progress, 0.0, 1.0, BYPASS_ENTRY_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait_for_visual_tween(_bypass_entry_tween, generation)
	if generation != _visual_motion_generation:
		return
	_bypass_entry_active = false
	_bypass_entry_progress = 1.0
	queue_redraw()


func bypass_entry_receipt() -> Dictionary:
	return {
		"active": _bypass_entry_active,
		"progress": _bypass_entry_progress,
		"name": _bypass_entry_name,
		"saved_steps": _bypass_entry_saved_steps,
		"play_count": _bypass_entry_play_count,
	}


func _set_bypass_entry_progress(value: float) -> void:
	_bypass_entry_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func current_route_position() -> Dictionary:
	return _current_position.duplicate(true)


func carousel_slot_normalized_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	result.assign(CAROUSEL_SLOT_NORMALIZED)
	return result


func carousel_slot_position(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= CAROUSEL_SLOT_NORMALIZED.size():
		return Vector2.ZERO
	return Vector2(size.x, size.y) * CAROUSEL_SLOT_NORMALIZED[slot_index]


func carousel_cat_feet_anchor() -> Vector2:
	return carousel_slot_position(0)


func carousel_tile_radius(is_current := false) -> float:
	return CAROUSEL_CURRENT_RADIUS if is_current else CAROUSEL_TILE_RADIUS


func carousel_moves_clockwise() -> bool:
	# From the upper arm the ordered slots travel right, down the outside edge,
	# and then left along the lower arm toward the fixed cat anchor.
	return CAROUSEL_SLOT_NORMALIZED[6].x < CAROUSEL_SLOT_NORMALIZED[5].x \
		and CAROUSEL_SLOT_NORMALIZED[3].y < CAROUSEL_SLOT_NORMALIZED[2].y \
		and CAROUSEL_SLOT_NORMALIZED[1].x > CAROUSEL_SLOT_NORMALIZED[0].x


func uses_semicircle_carousel() -> bool:
	var route_id := str(_current_position.get("route_id", ""))
	return not _overview_mode and (route_id == V06CourseModelScript.ROUTE_MAIN or _course.is_bypass_route(route_id))


func uses_card_route() -> bool:
	return uses_semicircle_carousel()


func set_roll_preview(distance: int) -> void:
	_card_roll_preview = maxi(distance, 0)
	_card_roll_preview_key = ""
	var forward := prominent_positions()
	if _card_roll_preview > 0 and _card_roll_preview <= forward.size():
		var target: Dictionary = forward[_card_roll_preview - 1]
		_card_roll_preview_key = _position_key(str(target.get("route_id", "")), int(target.get("tile_index", -1)))
	if is_instance_valid(_roll_preview_tween):
		_roll_preview_tween.kill()
	_card_roll_preview_alpha = 0.0
	_roll_preview_tween = create_tween()
	_roll_preview_tween.tween_method(_set_roll_preview_alpha, 0.0, 1.0, STRAIGHT_TARGET_PREVIEW_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()


func release_roll_preview() -> void:
	if _card_roll_preview <= 0:
		return
	if is_instance_valid(_roll_preview_tween):
		_roll_preview_tween.kill()
	_roll_preview_tween = create_tween()
	_roll_preview_tween.tween_method(_set_roll_preview_alpha, _card_roll_preview_alpha, 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_roll_preview_tween.tween_callback(_finish_roll_preview_release)


func clear_roll_preview() -> void:
	if is_instance_valid(_roll_preview_tween):
		_roll_preview_tween.kill()
	_card_roll_preview = -1
	_card_roll_preview_key = ""
	_card_roll_preview_alpha = 0.0
	queue_redraw()


func roll_preview_receipt() -> Dictionary:
	return {
		"active": _card_roll_preview > 0,
		"distance": _card_roll_preview,
		"target_key": _card_roll_preview_key,
		"alpha": _card_roll_preview_alpha,
	}


func _set_roll_preview_alpha(value: float) -> void:
	_card_roll_preview_alpha = clampf(value, 0.0, 1.0)
	queue_redraw()


func _finish_roll_preview_release() -> void:
	_card_roll_preview = -1
	_card_roll_preview_key = ""
	_card_roll_preview_alpha = 0.0
	queue_redraw()


func can_use_straight_travel(route_position: Dictionary, distance: int) -> bool:
	if str(route_position.get("route_id", "")) != V06CourseModelScript.ROUTE_MAIN:
		return false
	if distance <= 0 or distance > STRAIGHT_TRAVEL_MAX_STEPS:
		return false
	var start_tile := int(route_position.get("tile_index", -1))
	for step: int in range(1, distance + 1):
		var tile_index := start_tile + step
		if not _is_known_position({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": tile_index}):
			return false
		var kind := displayed_tile_kind_for(V06CourseModelScript.ROUTE_MAIN, tile_index)
		if kind in ["BYPASS_FORK", "WARP_OASIS", "WARP_TOMB", "WARP_GOLD", "LOOP_ENTRY", "LOOP_ENTRY_GOLD", "BOSS_GATE"]:
			return false
	return true


func begin_straight_travel(route_position: Dictionary, distance: int) -> bool:
	if not can_use_straight_travel(route_position, distance):
		return false
	var path: Array[Dictionary] = []
	var start_tile := int(route_position.get("tile_index", 0))
	for step: int in range(1, distance + 1):
		path.append({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": start_tile + step})
	return begin_step_travel(route_position, path)


func begin_step_travel(route_position: Dictionary, path: Array[Dictionary]) -> bool:
	if _straight_travel_active or path.is_empty() or not _is_known_position(route_position):
		return false
	var positions: Array[Dictionary] = [route_position.duplicate(true)]
	for route_position_in_path: Dictionary in path:
		if not _is_known_position(route_position_in_path):
			return false
		positions.append(route_position_in_path.duplicate(true))
	_straight_travel_active = true
	_straight_travel_start_position = route_position.duplicate(true)
	_straight_travel_distance = path.size()
	_straight_travel_player_step = 0
	_straight_step_from = 0
	_straight_step_progress = 1.0
	_straight_camera_follow_progress = 0.0
	_straight_camera_offset = 0.0
	_straight_travel_positions = _build_step_travel_window(positions)
	_cat_world = world_position_for(route_position)
	_cat_lift = 0.0
	_cat_animation_state = &"idle"
	_cat_animation_frame = 0
	_current_position = route_position.duplicate(true)
	_camera_target_world = _camera_focus_for(_current_position)
	queue_redraw()
	return true


func append_step_travel_position(route_position: Dictionary) -> bool:
	if not _straight_travel_active or _straight_travel_player_step != _straight_travel_distance \
			or _straight_camera_follow_progress > 0.0 or not _is_known_position(route_position):
		return false
	var positions: Array[Dictionary] = []
	var actual_count := mini(_straight_travel_distance + 1, _straight_travel_positions.size())
	for index: int in range(actual_count):
		positions.append(_straight_travel_positions[index].duplicate(true))
	positions.append(route_position.duplicate(true))
	_straight_travel_distance += 1
	_straight_travel_positions = _build_step_travel_window(positions)
	queue_redraw()
	return true


func straight_travel_active() -> bool:
	return _straight_travel_active


func straight_travel_receipt() -> Dictionary:
	return {
		"active": _straight_travel_active,
		"start_position": _straight_travel_start_position.duplicate(true),
		"distance": _straight_travel_distance,
		"player_step": _straight_travel_player_step,
		"step_progress": _straight_step_progress,
		"camera_follow_progress": _straight_camera_follow_progress,
		"camera_offset": _straight_camera_offset,
		"logical_position": _current_position.duplicate(true),
	}


func card_route_receipt() -> Dictionary:
	var relative_steps: Array[float] = []
	var position_labels: Array[Dictionary] = []
	if _straight_travel_active:
		var spacing := _straight_card_spacing()
		var camera_slots := _straight_camera_offset / spacing if spacing > 0.0 else 0.0
		for travel_offset: int in range(0, _straight_travel_distance + FORWARD_VISIBLE + 1):
			var route_offset := float(travel_offset) - camera_slots
			if route_offset < -0.55 or route_offset > float(FORWARD_VISIBLE) + 0.55:
				continue
			var route_position := _straight_window_position(travel_offset)
			relative_steps.append(float(travel_offset - _straight_travel_player_step))
			position_labels.append({
				"position_key": _position_key(str(route_position.get("route_id", "")), int(route_position.get("tile_index", -1))),
				"display_label": _straight_travel_card_label(route_position, travel_offset),
				"terminal_filler": bool(route_position.get("terminal_filler", false)),
			})
	else:
		var positions: Array[Dictionary] = [_current_position.duplicate(true)]
		positions.append_array(prominent_positions())
		for index: int in range(mini(positions.size(), CAROUSEL_SLOT_NORMALIZED.size())):
			relative_steps.append(float(index))
			position_labels.append({
				"position_key": _position_key(str(positions[index].get("route_id", "")), int(positions[index].get("tile_index", -1))),
				"display_label": _settled_card_label(positions[index], index == 0),
				"terminal_filler": false,
			})
	for entry: Dictionary in position_labels:
		var display_label := str(entry.get("display_label", ""))
		var font_size := _card_route_label_font_size(display_label, display_label == "現在地")
		entry["font_size"] = font_size
		entry["label_width"] = APP_FONT.get_string_size(display_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		entry["card_width"] = _card_route_card_size().x
	return {"card_count": relative_steps.size(), "relative_steps": relative_steps, "position_labels": position_labels}


func _settled_card_label(route_position: Dictionary, is_current: bool) -> String:
	if is_current:
		return "現在地"
	var successors := _forward_successors(str(_current_position.get("route_id", "")), int(_current_position.get("tile_index", 0)))
	for successor_index: int in range(successors.size()):
		if _same_route_position(route_position, successors[successor_index]):
			return "+%d" % (successor_index + 1)
	return "·"


func _straight_travel_card_label(route_position: Dictionary, travel_offset: int) -> String:
	if bool(route_position.get("terminal_filler", false)):
		return "·"
	if travel_offset == 0:
		return "現在地"
	if travel_offset <= _straight_travel_distance:
		return "+%d" % travel_offset
	var destination := _straight_travel_positions[mini(_straight_travel_distance, _straight_travel_positions.size() - 1)]
	var successors := _forward_successors(str(destination.get("route_id", "")), int(destination.get("tile_index", 0)))
	var successor_index := travel_offset - _straight_travel_distance - 1
	if successor_index >= 0 and successor_index < successors.size() \
			and _same_route_position(route_position, successors[successor_index]):
		return "+%d" % travel_offset
	return "·"


func animate_straight_step(step: int, duration := HOP_SECONDS) -> void:
	if not _straight_travel_active:
		return
	var requested_step := clampi(step, 0, _straight_travel_distance)
	var next_step := mini(requested_step, _straight_travel_player_step + 1)
	if next_step <= _straight_travel_player_step:
		return
	if is_instance_valid(_straight_step_tween):
		_straight_step_tween.kill()
	_straight_step_from = _straight_travel_player_step
	_straight_travel_player_step = next_step
	_straight_step_progress = 0.0
	var generation := _visual_motion_generation
	_straight_step_tween = create_tween()
	_straight_step_tween.tween_method(_set_straight_step_progress, 0.0, 1.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await _wait_for_visual_tween(_straight_step_tween, generation)
	if generation != _visual_motion_generation:
		return
	_straight_step_progress = 1.0
	_cat_lift = 0.0
	_cat_animation_state = &"land"
	_cat_animation_frame = 2
	queue_redraw()


func animate_straight_camera_follow() -> void:
	if not _straight_travel_active or _straight_travel_player_step != _straight_travel_distance:
		return
	if is_instance_valid(_straight_camera_tween):
		_straight_camera_tween.kill()
	_straight_camera_follow_progress = 0.0
	_straight_camera_offset = 0.0
	var generation := _visual_motion_generation
	_straight_camera_tween = create_tween()
	_straight_camera_tween.tween_method(_set_straight_camera_follow_progress, 0.0, 1.0, STRAIGHT_CAMERA_FOLLOW_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait_for_visual_tween(_straight_camera_tween, generation)
	if generation != _visual_motion_generation:
		return
	_straight_camera_follow_progress = 1.0
	_straight_camera_offset = _straight_card_spacing() * float(_straight_travel_distance)
	queue_redraw()


func finish_straight_travel(route_position: Dictionary) -> bool:
	if not _straight_travel_active or _straight_travel_player_step != _straight_travel_distance or _straight_camera_follow_progress < 1.0:
		return false
	_straight_travel_active = false
	_straight_travel_start_position.clear()
	_straight_travel_distance = 0
	_straight_travel_player_step = 0
	_straight_step_from = 0
	_straight_step_progress = 1.0
	_straight_camera_follow_progress = 0.0
	_straight_camera_offset = 0.0
	_straight_travel_positions.clear()
	_cat_lift = 0.0
	_cat_animation_state = &"idle"
	_cat_animation_frame = 0
	set_route_position(route_position, true)
	return true


func cancel_visual_motion(route_position := {}) -> void:
	_visual_motion_generation += 1
	if is_instance_valid(_camera_presentation_tween):
		_camera_presentation_tween.kill()
	if is_instance_valid(_straight_step_tween):
		_straight_step_tween.kill()
	if is_instance_valid(_straight_camera_tween):
		_straight_camera_tween.kill()
	if is_instance_valid(_portal_transfer_tween):
		_portal_transfer_tween.kill()
	if is_instance_valid(_bypass_entry_tween):
		_bypass_entry_tween.kill()
	if is_instance_valid(_landing_tween):
		_landing_tween.kill()
	_straight_travel_active = false
	_straight_travel_start_position.clear()
	_straight_travel_distance = 0
	_straight_travel_player_step = 0
	_straight_step_from = 0
	_straight_step_progress = 1.0
	_straight_camera_follow_progress = 0.0
	_straight_camera_offset = 0.0
	_straight_travel_positions.clear()
	_cat_lift = 0.0
	_cat_animation_state = &"idle"
	_cat_animation_frame = 0
	_landing_kind = ""
	_landing_progress = 1.0
	_landing_result_text = ""
	_portal_transfer_active = false
	_portal_transfer_progress = 0.0
	_bypass_entry_active = false
	_bypass_entry_progress = 0.0
	_camera_presentation_active = false
	_camera_presentation_kind = ""
	_comparison_route_id = ""
	_overview_mode = false
	_overview_detail_mode = false
	_overview_pointer_active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_zoom = 0.72
	if route_position is Dictionary and not (route_position as Dictionary).is_empty():
		set_route_position(route_position, true)
	else:
		queue_redraw()


func _wait_for_visual_tween(tween: Tween, generation: int) -> bool:
	while is_instance_valid(tween) and tween.is_running():
		await get_tree().process_frame
	return generation == _visual_motion_generation


func _set_straight_step_progress(value: float) -> void:
	_straight_step_progress = clampf(value, 0.0, 1.0)
	_cat_lift = sin(_straight_step_progress * PI) * 28.0
	var cell := animation_cell_for_hop_progress(_straight_step_progress)
	_cat_animation_state = cell.strip
	_cat_animation_frame = int(cell.frame)
	queue_redraw()


func _set_straight_camera_follow_progress(value: float) -> void:
	_straight_camera_follow_progress = clampf(value, 0.0, 1.0)
	_straight_camera_offset = _straight_card_spacing() * float(_straight_travel_distance) * _calm_camera_ease(_straight_camera_follow_progress)
	queue_redraw()


func _straight_card_spacing() -> float:
	return absf(_card_route_slot_position(1).x - _card_route_slot_position(0).x) if _card_route_card_size().x > 0.0 else 0.0


func _straight_window_position(travel_offset: int) -> Dictionary:
	if travel_offset >= 0 and travel_offset < _straight_travel_positions.size():
		return _straight_travel_positions[travel_offset].duplicate(true)
	var tile_index := int(_straight_travel_start_position.get("tile_index", 0)) + travel_offset
	var route_id := V06CourseModelScript.ROUTE_MAIN
	if _is_known_position({"route_id": route_id, "tile_index": tile_index}):
		return {"route_id": route_id, "tile_index": tile_index}
	# Keep the seven-card frame stable at the terminal edge instead of letting
	# the renderer remove cards when the route data runs out.
	return {"route_id": route_id, "tile_index": maxi(_route_size(route_id) - 1, 0), "terminal_filler": true}


func _build_step_travel_window(actual_positions: Array[Dictionary]) -> Array[Dictionary]:
	var window: Array[Dictionary] = []
	for route_position: Dictionary in actual_positions:
		window.append(route_position.duplicate(true))
	if window.is_empty():
		return window
	var destination: Dictionary = window.back().duplicate(true)
	var saved_position := _current_position.duplicate(true)
	_current_position = destination
	var future_positions := prominent_positions()
	_current_position = saved_position
	for future_position: Dictionary in future_positions:
		if _same_route_position(future_position, destination):
			continue
		window.append(future_position.duplicate(true))
	var required_size := (actual_positions.size() - 1) + FORWARD_VISIBLE + 1
	while window.size() < required_size:
		var filler := destination.duplicate(true)
		filler["terminal_filler"] = true
		window.append(filler)
	return window


func _same_route_position(first: Dictionary, second: Dictionary) -> bool:
	return str(first.get("route_id", "")) == str(second.get("route_id", "")) \
			and int(first.get("tile_index", -1)) == int(second.get("tile_index", -2))


static func _calm_camera_ease(progress: float) -> float:
	var t := clampf(progress, 0.0, 1.0)
	return t * t * (3.0 - t * 2.0)


func _straight_card_display_offset() -> Vector2:
	return Vector2(-_straight_camera_offset, 0.0) if _straight_travel_active else Vector2.ZERO


func play_landing_effect(route_position: Dictionary, result_text: String = "", kind_override: String = "") -> void:
	if not _is_known_position(route_position):
		return
	var route_id := str(route_position.get("route_id", ""))
	var tile_index := int(route_position.get("tile_index", 0))
	_landing_kind = kind_override if not kind_override.is_empty() else displayed_tile_kind_for(route_id, tile_index)
	_landing_progress = 0.0
	_landing_result_text = result_text if not result_text.is_empty() else _landing_result_for_kind(_landing_kind)
	queue_redraw()
	var duration := LANDING_SPECIAL_SECONDS if _landing_kind in ["COIN", "REST", "RISK", "ITEM", "EVENT", "WARP_OASIS", "WARP_TOMB", "WARP_GOLD", "LOOP_ENTRY", "LOOP_ENTRY_GOLD", "BOSS_GATE"] else LANDING_NORMAL_SECONDS
	if is_instance_valid(_landing_tween):
		_landing_tween.kill()
	var generation := _visual_motion_generation
	_landing_tween = create_tween()
	_landing_tween.tween_method(_set_landing_progress, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not await _wait_for_visual_tween(_landing_tween, generation):
		return
	await get_tree().create_timer(LANDING_HOLD_SECONDS).timeout
	if generation != _visual_motion_generation:
		return
	_landing_kind = ""
	_landing_progress = 1.0
	_landing_result_text = ""
	queue_redraw()


func landing_effect_active() -> bool:
	return not _landing_kind.is_empty()


func _set_landing_progress(value: float) -> void:
	_landing_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _landing_result_for_kind(kind: String) -> String:
	match kind:
		"COIN": return "+2"
		"REST": return "♥ +1"
		"RISK": return "-1"
		"ITEM": return "GET"
		"EVENT": return "?"
		"WARP_OASIS", "WARP_TOMB", "WARP_GOLD", "LOOP_ENTRY", "LOOP_ENTRY_GOLD": return "WARP"
		"BOSS_GATE": return "BOSS"
		_: return ""


func uses_production_cat_strips() -> bool:
	return CAT_IDLE_STRIP != null and CAT_JUMP_STRIP != null and CAT_LAND_STRIP != null


func uses_production_environment_pack() -> bool:
	return PARCHMENT_BASE != null and CAIRO_CARTOGRAPHY_INK != null and RAISED_ROUTE_TILES != null and GOLD_BOSS_GATE != null


func route_tile_cell_for(route_id: String, is_current: bool) -> int:
	if is_current:
		return 3
	if _course.is_bypass_route(route_id):
		return 1
	if _course.is_loop_route(route_id):
		return 2
	return 0


func tile_draw_diameter_for_radius(radius: float) -> float:
	return radius * LOCAL_TILE_DIAMETER_SCALE


func kind_badge_radius_for_tile(radius: float) -> float:
	return radius * (0.66 if _overview_mode else LOCAL_KIND_BADGE_RADIUS_SCALE)


func tile_kind_for(route_id: String, tile_index: int) -> String:
	var routes: Dictionary = _definition.get("routes", {})
	var tiles: Array = routes.get(route_id, []) if routes.get(route_id, []) is Array else []
	if tile_index < 0 or tile_index >= tiles.size() or not tiles[tile_index] is Dictionary:
		return "NORMAL"
	return str((tiles[tile_index] as Dictionary).get("kind", "NORMAL"))


func displayed_tile_kind_for(route_id: String, tile_index: int) -> String:
	var key := _position_key(route_id, tile_index)
	if _consumed_reward_node_keys.has(key):
		return "NORMAL"
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		var gate: Dictionary = _course.warp_gate_for_main_index(tile_index)
		if not gate.is_empty() and _consumed_warp_gate_ids.has(str(gate.id)):
			return "NORMAL"
	return str(_kind_preview_overrides.get(key, tile_kind_for(route_id, tile_index)))


func set_consumed_route_state(warp_gate_ids: PackedStringArray, reward_node_keys: PackedStringArray) -> void:
	_consumed_warp_gate_ids.clear()
	_consumed_reward_node_keys.clear()
	for gate_id: String in warp_gate_ids:
		_consumed_warp_gate_ids[gate_id] = true
	for node_key: String in reward_node_keys:
		_consumed_reward_node_keys[node_key] = true
	queue_redraw()


func overview_topology_receipt() -> Dictionary:
	return {
		"main_route": V06CourseModelScript.ROUTE_MAIN,
		"detached_loop_routes": PackedStringArray([
			V06CourseModelScript.ROUTE_LOOP_OASIS,
			V06CourseModelScript.ROUTE_LOOP_TOMB,
		]),
		"bypass_routes": PackedStringArray([
			V06CourseModelScript.ROUTE_BYPASS_BAZAAR,
			V06CourseModelScript.ROUTE_BYPASS_SIROCCO,
		]),
		"bypass_sides": PackedStringArray(["right", "left"]),
		"bypass_saved_steps": PackedInt32Array([4, 6]),
		"warp_gate_count": _course.warp_gates().size(),
		"permanent_loop_connectors": 0,
	}


func bypass_visual_receipt(route_id: String) -> Dictionary:
	var definition := _bypass_definition(route_id)
	if definition.is_empty():
		return {}
	var active := str(_current_position.get("route_id", "")) == route_id
	return {
		"active": active,
		"line_alpha": 0.94 if active else 0.34,
		"line_width": 10.0 if active else 8.0,
		"saved_steps": int(definition.get("saved_steps", 0)),
		"side": str(definition.get("side", "")),
		"has_entry_marker": true,
		"has_merge_marker": true,
	}


func set_kind_preview_override(kinds: PackedStringArray) -> void:
	# Visual-QA only: map a six-kind readability strip onto the canonical forward
	# positions without changing course data, movement, or shipping semantics.
	_kind_preview_overrides.clear()
	var positions := prominent_positions()
	for index: int in range(mini(kinds.size(), positions.size())):
		var position: Dictionary = positions[index]
		_kind_preview_overrides[_position_key(str(position.route_id), int(position.tile_index))] = kinds[index]
	queue_redraw()


func tile_visual_spec(kind: String) -> Dictionary:
	match kind:
		"NORMAL": return {"shape_id": &"rounded_square", "icon_id": &"imagegen_footprints", "base_color": KIND_NORMAL, "priority": 6}
		"COIN": return {"shape_id": &"circle", "icon_id": &"kenney_tokens_stack", "base_color": KIND_COIN, "priority": 3}
		"REST": return {"shape_id": &"leaf", "icon_id": &"heart", "base_color": KIND_REST, "priority": 2}
		"RISK": return {"shape_id": &"triangle", "icon_id": &"kenney_skull", "base_color": KIND_RISK, "priority": 1}
		"ITEM": return {"shape_id": &"box", "icon_id": &"kenney_pouch", "base_color": KIND_ITEM, "priority": 5}
		"EVENT": return {"shape_id": &"hex", "icon_id": &"kenney_book_open", "base_color": KIND_EVENT, "priority": 5}
		"WARP_OASIS": return {"shape_id": &"ring", "icon_id": &"swirl", "base_color": Color("#68b9cf"), "priority": 4}
		"WARP_TOMB": return {"shape_id": &"gate", "icon_id": &"swirl", "base_color": Color("#76539a"), "priority": 4}
		"WARP_GOLD": return {"shape_id": &"ring", "icon_id": &"swirl", "base_color": Color("#d4a83f"), "priority": 4}
		"LOOP_PORTAL": return {"shape_id": &"ring", "icon_id": &"swirl", "base_color": KIND_WARP, "priority": 4}
		"LOOP_ENTRY": return {"shape_id": &"ring", "icon_id": &"swirl", "base_color": KIND_WARP, "priority": 4}
		"LOOP_ENTRY_GOLD": return {"shape_id": &"ring", "icon_id": &"swirl", "base_color": Color("#d4a83f"), "priority": 4}
		"EXIT_GATE": return {"shape_id": &"gate", "icon_id": &"exit", "base_color": KIND_COIN, "priority": 3}
		"BOSS_GATE": return {"shape_id": &"gate", "icon_id": &"crown", "base_color": KIND_BOSS, "priority": 0}
		"BYPASS_FORK": return {"shape_id": &"diamond", "icon_id": &"fork", "base_color": BYPASS_RUST, "priority": 4}
		"START": return {"shape_id": &"rounded_square", "icon_id": &"flag", "base_color": MAIN_TEAL, "priority": 6}
		_: return {"shape_id": &"rounded_square", "icon_id": &"diamond", "base_color": KIND_NORMAL, "priority": 6}


func boss_gate_cell() -> int:
	return 1 if str(_current_position.get("route_id", "")) == V06CourseModelScript.ROUTE_MAIN and int(_current_position.get("tile_index", -1)) == _boss_index() else 0


func cat_animation_state() -> StringName:
	return _cat_animation_state


func cat_animation_frame() -> int:
	return _cat_animation_frame


func idle_animation_frame_for_elapsed(elapsed: float) -> int:
	# A six-second cycle gives one slow breath and one short blink. Most of the
	# time remains on the approved seed frame for low-stimulation play.
	var phase := fmod(maxf(elapsed, 0.0), 6.0)
	if phase < 3.2:
		return 0
	if phase < 3.8:
		return 1
	if phase < 4.4:
		return 3
	if phase < 4.55:
		return 2
	return 0


func animation_cell_for_hop_progress(progress: float) -> Dictionary:
	var value := clampf(progress, 0.0, 1.0)
	if value < 0.08:
		return {"strip": &"jump", "frame": 0}
	if value < 0.24:
		return {"strip": &"jump", "frame": 1}
	if value < 0.40:
		return {"strip": &"jump", "frame": 2}
	if value < 0.58:
		return {"strip": &"jump", "frame": 3}
	if value < 0.75:
		return {"strip": &"jump", "frame": 5}
	if value < 0.88:
		return {"strip": &"land", "frame": 0}
	if value < 0.96:
		return {"strip": &"land", "frame": 1}
	return {"strip": &"land", "frame": 2}


func prominent_positions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var route_id := str(_current_position.get("route_id", ""))
	var index := int(_current_position.get("tile_index", 0))
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		result = _forward_successors(route_id, index)
		# At the final approach keep a bounded local frame instead of showing an
		# empty map. The forward spaces remain first and the fill never includes
		# the current tile itself.
		var behind := 1
		while result.size() < PROMINENT_MIN and index - behind >= 0:
			result.append({"route_id": route_id, "tile_index": index - behind})
			behind += 1
		while result.size() > PROMINENT_MAX:
			result.pop_back()
	elif _course.is_bypass_route(route_id):
		result = _forward_successors(route_id, index)
		# Near a terminal, older tiles only preserve the five-space visual frame;
		# they are context and never promises of future traversal.
		var behind := 1
		while result.size() < PROMINENT_MIN and index - behind >= 0:
			result.append({"route_id": route_id, "tile_index": index - behind})
			behind += 1
	else:
		for offset: int in range(_route_size(route_id)):
			result.append({"route_id": route_id, "tile_index": posmod(index + offset, 8)})
	return result


func future_successor_count() -> int:
	return _forward_successors(str(_current_position.get("route_id", "")), int(_current_position.get("tile_index", 0))).size()


func carousel_segment_style_ids() -> PackedStringArray:
	var positions: Array[Dictionary] = [_current_position.duplicate(true)]
	positions.append_array(prominent_positions())
	var styles := PackedStringArray()
	for index: int in range(mini(positions.size() - 1, CAROUSEL_SLOT_NORMALIZED.size() - 1)):
		var source_route := str(positions[index].get("route_id", ""))
		styles.append(String(ROUTE_STYLE_BYPASS if _course.is_bypass_route(source_route) else ROUTE_STYLE_MAIN))
	return styles


func carousel_main_edge_segments() -> Array[Dictionary]:
	if not uses_semicircle_carousel() or str(_current_position.get("route_id", "")) != V06CourseModelScript.ROUTE_MAIN:
		return []
	var lower_endpoint := carousel_slot_position(0)
	var upper_endpoint := carousel_slot_position(CAROUSEL_SLOT_NORMALIZED.size() - 1)
	return [
		{"from": Vector2(-8.0, lower_endpoint.y), "to": lower_endpoint},
		{"from": Vector2(-8.0, upper_endpoint.y), "to": upper_endpoint},
	]


func carousel_context_positions() -> Array[Dictionary]:
	"""Return non-traversable context tiles that continue each open-left line.

	They are deliberately separate from prominent_positions(): the normal play
	contract still exposes only six forward successors, while these four tiles
	make the route continuation legible without changing movement semantics.
	"""
	if not uses_semicircle_carousel() or str(_current_position.get("route_id", "")) != V06CourseModelScript.ROUTE_MAIN:
		return []
	var index := int(_current_position.get("tile_index", 0))
	var result: Array[Dictionary] = []
	for offset: int in [2, 1]:
		if index - offset >= 0:
			result.append({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": index - offset, "context_side": &"lower", "context_rank": offset})
	var future_count := _forward_successors(V06CourseModelScript.ROUTE_MAIN, index).size()
	for offset: int in range(1, 3):
		var tile_index := index + future_count + offset
		if tile_index < _route_size(V06CourseModelScript.ROUTE_MAIN):
			result.append({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": tile_index, "context_side": &"upper", "context_rank": offset})
	return result


func carousel_context_slot_position(context: Dictionary) -> Vector2:
	var side := StringName(context.get("context_side", &""))
	var rank := int(context.get("context_rank", 1))
	var endpoint := carousel_slot_position(0 if side == &"lower" else CAROUSEL_SLOT_NORMALIZED.size() - 1)
	return endpoint - Vector2(CAROUSEL_CONTEXT_SPACING * float(rank), 0.0)


func _forward_successors(route_id: String, index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		for tile_index: int in range(index + 1, mini(_route_size(route_id), index + FORWARD_VISIBLE + 1)):
			result.append({"route_id": route_id, "tile_index": tile_index})
	elif _course.is_bypass_route(route_id):
		for tile_index: int in range(index + 1, _route_size(route_id)):
			if result.size() >= FORWARD_VISIBLE:
				break
			result.append({"route_id": route_id, "tile_index": tile_index})
		for tile_index: int in range(_rejoin_index(route_id), _route_size(V06CourseModelScript.ROUTE_MAIN)):
			if result.size() >= FORWARD_VISIBLE:
				break
			result.append({"route_id": V06CourseModelScript.ROUTE_MAIN, "tile_index": tile_index})
	return result


func prominent_space_count() -> int:
	return prominent_positions().size()


func prominent_visible_space_count() -> int:
	if uses_semicircle_carousel():
		return prominent_positions().size()
	var count := 0
	for route_position: Dictionary in prominent_positions():
		var screen_position := _to_screen(world_position_for(route_position))
		if screen_position.x >= 30.0 and screen_position.x <= size.x - 30.0 and screen_position.y >= 30.0 and screen_position.y <= size.y - 30.0:
			count += 1
	return count


func route_style_ids() -> PackedStringArray:
	return PackedStringArray([String(ROUTE_STYLE_MAIN), String(ROUTE_STYLE_BYPASS), String(ROUTE_STYLE_LOOP)])


func displayed_exit_steps() -> int:
	if _course.is_loop_route(str(_current_position.get("route_id", ""))):
		return _exit_steps
	return -1


func set_loop_rescue_progress(wrap_count: int, threshold: int = V06CourseModelScript.LOOP_RESCUE_WRAP_THRESHOLD) -> void:
	_loop_rescue_threshold = maxi(threshold, 1)
	_loop_wrap_count = clampi(wrap_count, 0, _loop_rescue_threshold)
	queue_redraw()


func exit_emphasis_receipt() -> Dictionary:
	var route_id := str(_current_position.get("route_id", ""))
	return {
		"active": _course.is_loop_route(route_id) and _exit_steps > 0,
		"route_id": route_id,
		"exit_index": _course.loop_exit_index(route_id) if _course.is_loop_route(route_id) else -1,
		"exit_indices": _course.loop_exit_indices(route_id) if _course.is_loop_route(route_id) else [],
		"steps": displayed_exit_steps(),
		"wrap_count": _loop_wrap_count,
		"rescue_threshold": _loop_rescue_threshold,
	}


func world_position_for(route_position: Dictionary) -> Vector2:
	var route_id := str(route_position.get("route_id", ""))
	var tile_index := int(route_position.get("tile_index", -1))
	if not _route_points.has(route_id):
		return Vector2.ZERO
	var points: Array = _route_points[route_id]
	return points[tile_index] if tile_index >= 0 and tile_index < points.size() else Vector2.ZERO


func _build_route_points() -> void:
	var main: Array[Vector2] = []
	for tile_index: int in range(_route_size(V06CourseModelScript.ROUTE_MAIN)):
		var row := tile_index / 8
		var column := tile_index % 8
		var visual_column := column if row % 2 == 0 else 7 - column
		main.append(Vector2(100.0 + visual_column * 120.0, 1040.0 - row * 280.0))
	var bazaar := _build_bypass_points(main[32], main[41], 4, 150.0)
	var sirocco := _build_bypass_points(main[71], main[83], 5, -170.0)
	var oasis: Array[Vector2] = []
	var oasis_center := Vector2(-180.0, 210.0)
	for tile_index: int in range(8):
		var angle := PI * 0.5 + TAU * float(tile_index) / 8.0
		oasis.append(oasis_center + Vector2(cos(angle), sin(angle)) * LOOP_ROUTE_RADIUS)
	var tomb: Array[Vector2] = []
	var tomb_center := Vector2(1180.0, -340.0)
	for tile_index: int in range(8):
		var angle := PI * 0.5 + TAU * float(tile_index) / 8.0
		tomb.append(tomb_center + Vector2(cos(angle), sin(angle)) * LOOP_ROUTE_RADIUS)
	_route_points = {
		V06CourseModelScript.ROUTE_MAIN: main,
		V06CourseModelScript.ROUTE_BYPASS_BAZAAR: bazaar,
		V06CourseModelScript.ROUTE_BYPASS_SIROCCO: sirocco,
		V06CourseModelScript.ROUTE_LOOP_OASIS: oasis,
		V06CourseModelScript.ROUTE_LOOP_TOMB: tomb,
	}


func _is_known_position(route_position: Dictionary) -> bool:
	var route_id := str(route_position.get("route_id", ""))
	var tile_index := int(route_position.get("tile_index", -1))
	if not _route_points.has(route_id):
		return false
	return tile_index >= 0 and tile_index < (_route_points[route_id] as Array).size()


func _camera_focus_for(route_position: Dictionary) -> Vector2:
	var current := world_position_for(route_position)
	var route_id := str(route_position.get("route_id", ""))
	if _course.is_loop_route(route_id):
		var points: Array = _route_points.get(route_id, [])
		var center := Vector2.ZERO
		for point: Vector2 in points:
			center += point
		return center / float(points.size()) if not points.is_empty() else current
	# Look a few spaces forward so the promised six-space horizon is actually
	# visible. The cat remains inside a stable central band and the camera still
	# eases softly instead of snapping at serpentine turns.
	var points: Array = _route_points.get(route_id, [])
	var tile_index := int(route_position.get("tile_index", 0))
	if not points.is_empty():
		var lookahead_index := mini(tile_index + 3, points.size() - 1)
		return current.lerp(points[lookahead_index], 0.75)
	return current


func _set_hop_progress(value: float, start: Vector2, target: Vector2) -> void:
	_carousel_progress = value
	_cat_world = start.lerp(target, value)
	_cat_lift = sin(value * PI) * 28.0
	var cell := animation_cell_for_hop_progress(value)
	_cat_animation_state = cell.strip
	_cat_animation_frame = int(cell.frame)
	queue_redraw()


func _draw() -> void:
	_draw_flat_atlas_texture()
	_draw_district_scenery()
	if uses_card_route():
		_draw_card_route()
	else:
		_draw_route_graph()
	if uses_card_route():
		_draw_map_dice_shadow()
	_draw_cat_marker()
	_draw_bypass_entry_effect()
	_draw_portal_transfer()


func _draw_bypass_entry_effect() -> void:
	if not _bypass_entry_active:
		return
	var strength := sin(clampf(_bypass_entry_progress, 0.0, 1.0) * PI)
	if strength <= 0.0:
		return
	var center := Vector2(size.x * 0.50, size.y * 0.20)
	var branch_start := center + Vector2(-150.0, 52.0)
	var branch_joint := center + Vector2(-78.0, 52.0)
	var branch_end := center + Vector2(8.0, 18.0)
	draw_line(branch_start, branch_joint, Color(MAIN_TEAL, 0.78 * strength), 9.0, true)
	draw_line(branch_joint, branch_end, Color(BYPASS_RUST, 0.96 * strength), 10.0, true)
	draw_circle(branch_joint, 8.0 + strength * 3.0, Color("#f4d58a"))
	var panel_size := Vector2(minf(size.x * 0.56, 390.0), 92.0)
	var panel_rect := Rect2(center - panel_size * 0.5, panel_size)
	var panel := _panel_style(Color(BYPASS_RUST, 0.90 * strength), Color("#f4d58a"), 18)
	draw_style_box(panel, panel_rect)
	draw_string(APP_FONT, panel_rect.position + Vector2(0.0, 38.0), "近道へ！", HORIZONTAL_ALIGNMENT_CENTER, panel_rect.size.x, 30, Color("#fff3d8"))
	var detail := "%s　%dマス短縮" % [_bypass_entry_name, _bypass_entry_saved_steps]
	draw_string(APP_FONT, panel_rect.position + Vector2(0.0, 70.0), detail, HORIZONTAL_ALIGNMENT_CENTER, panel_rect.size.x, 18, Color("#ffe9ba"))


func _draw_portal_transfer() -> void:
	if not _portal_transfer_active or _portal_transfer_progress <= 0.0:
		return
	var progress := _calm_camera_ease(_portal_transfer_progress)
	var veil := Color(_portal_transfer_color, 0.88 * progress)
	draw_rect(Rect2(Vector2.ZERO, size), veil)
	var center := Vector2(size.x * 0.50, size.y * 0.58)
	var ring_color := Color("#f6d88c")
	ring_color.a = 0.28 + progress * 0.62
	for index: int in range(3):
		var radius := 34.0 + float(index) * 34.0 + (1.0 - progress) * 46.0
		draw_arc(center, radius, -PI * 0.5, PI * 1.5, 48, ring_color, 5.0 - float(index) * 0.8, true)
	var core := Color("#fff0b0")
	core.a = 0.16 + progress * 0.52
	draw_circle(center, 18.0 + progress * 22.0, core)


func _draw_map_dice_shadow() -> void:
	var shadow_center := Vector2(size.x * 0.45, size.y * 0.80)
	draw_set_transform(shadow_center, 0.0, Vector2(1.75, 0.46))
	draw_circle(Vector2.ZERO, 32.0, Color(0.20, 0.13, 0.08, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_card_route() -> void:
	var positions: Array[Dictionary] = []
	var centers: Array[Vector2] = []
	var relative_steps: Array[float] = []
	var display_labels: Array[String] = []
	if _straight_travel_active:
		# Keep the whole visual travel window alive. The window contains the
		# starting card through destination + six cards, then the camera offset
		# reveals exactly seven cards at every point of the follow.
		var spacing := _straight_card_spacing()
		var camera_slots := _straight_camera_offset / spacing if spacing > 0.0 else 0.0
		for travel_offset: int in range(0, _straight_travel_distance + FORWARD_VISIBLE + 1):
			var route_position := _straight_window_position(travel_offset)
			var route_offset := float(travel_offset) - camera_slots
			if route_offset < -0.55 or route_offset > float(FORWARD_VISIBLE) + 0.55:
				continue
			positions.append(route_position)
			centers.append(_card_route_slot_position(route_offset))
			relative_steps.append(float(travel_offset - _straight_travel_player_step))
			display_labels.append(_straight_travel_card_label(route_position, travel_offset))
	else:
		positions = [_current_position.duplicate(true)]
		positions.append_array(prominent_positions())
		for index: int in range(mini(positions.size(), CAROUSEL_SLOT_NORMALIZED.size())):
			centers.append(_card_route_slot_position(float(index)))
			relative_steps.append(float(index))
			display_labels.append(_settled_card_label(positions[index], index == 0))
	if positions.is_empty():
		return
	if centers.size() >= 2:
		var path_y := centers[0].y + _card_route_card_size().y * 0.60
		draw_line(Vector2(centers[0].x - 36.0, path_y), Vector2(centers[-1].x + 36.0, path_y), Color(0.26, 0.16, 0.08, 0.28), 12.0, true)
		draw_line(Vector2(centers[0].x - 36.0, path_y), Vector2(centers[-1].x + 36.0, path_y), Color("#d5af70"), 6.0, true)
	for index: int in range(mini(positions.size(), centers.size())):
		var route_position: Dictionary = positions[index]
		var is_current := false
		if _straight_travel_active:
			is_current = is_zero_approx(relative_steps[index])
		else:
			is_current = index == 0
		_draw_card_tile(route_position, centers[index], is_current, display_labels[index])
		if index > 0:
			var chevron_center := centers[index - 1].lerp(centers[index], 0.52)
			_draw_direction_chevron(chevron_center, Vector2.RIGHT, Color(0.30, 0.48, 0.42, 0.62), 3.0)
	var preview_index := -1
	if _card_roll_preview > 0:
		for index: int in range(relative_steps.size()):
			var position_key := _position_key(str(positions[index].get("route_id", "")), int(positions[index].get("tile_index", -1)))
			if (not _card_roll_preview_key.is_empty() and position_key == _card_roll_preview_key) \
					or (_card_roll_preview_key.is_empty() and is_equal_approx(relative_steps[index], float(_card_roll_preview))):
				preview_index = index
				break
	if preview_index >= 0 and preview_index < centers.size():
		var landing := centers[preview_index]
		var landing_size := _card_route_card_size()
		var landing_rect := Rect2(landing - landing_size * 0.5, landing_size)
		var preview_fill := Color(1.0, 0.86, 0.45, 0.08 + _card_roll_preview_alpha * 0.10)
		var preview_ring := Color("#fff0a8")
		preview_ring.a = 0.20 + _card_roll_preview_alpha * 0.72
		draw_style_box(_card_style(preview_fill, preview_ring, 3.0), landing_rect.grow(6.0))
		draw_arc(landing, landing_size.x * 0.62, -PI * 0.5, PI * 1.5, 30, preview_ring, 2.0 + _card_roll_preview_alpha, true)
	if not _landing_kind.is_empty():
		var landing_index := 0
		if _straight_travel_active:
			for index: int in range(relative_steps.size()):
				if is_zero_approx(relative_steps[index]):
					landing_index = index
					break
		if landing_index >= 0 and landing_index < centers.size():
			_draw_landing_effect(centers[landing_index], _card_route_card_size(), _landing_kind)


func _card_route_card_size() -> Vector2:
	var width := clampf((size.x - 72.0) / 8.0, 42.0, 82.0)
	var height := clampf(size.y * 0.42, 168.0, 208.0)
	return Vector2(width, height)


func _card_route_slot_position(slot_index: float) -> Vector2:
	var card_size := _card_route_card_size()
	var margin := clampf(size.x * 0.05, 18.0, 34.0)
	var gap := (size.x - margin * 2.0 - card_size.x * 7.0) / 6.0
	return Vector2(margin + card_size.x * 0.5 + slot_index * (card_size.x + gap), size.y * 0.48)


func _card_route_label_font_size(label: String, is_current: bool) -> int:
	var font_size := 18 if label == "現在地" else (30 if is_current else 28)
	var available_width := _card_route_card_size().x - 4.0
	while font_size > 8 and APP_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > available_width:
		font_size -= 1
	return font_size


func _draw_card_tile(route_position: Dictionary, center: Vector2, is_current: bool, step_label: String) -> void:
	var route_id := str(route_position.get("route_id", ""))
	var tile_index := int(route_position.get("tile_index", 0))
	var kind := displayed_tile_kind_for(route_id, tile_index)
	var is_boss := kind == "BOSS_GATE"
	var spec := tile_visual_spec(kind)
	var fill: Color = spec.base_color
	if kind == "NORMAL":
		fill = Color("#f0dfbb")
	elif kind == "RISK":
		fill = Color("#f2c4aa")
	elif is_boss:
		fill = Color("#f4d788")
	if is_current:
		fill = Color("#3b8e8e")
	var card_size := _card_route_card_size()
	var sink := sin(_landing_progress * PI) * 5.0 if is_current and not _landing_kind.is_empty() else 0.0
	var card_rect := Rect2(center - card_size * 0.5 + Vector2(0.0, sink), card_size)
	var border := Color("#f5d37e") if is_current else Color("#9c7742")
	draw_style_box(_card_style(fill, border, 4.0 if is_current else 2.0), card_rect)
	var number_color := Color("#fff4dc") if is_current else Color("#56422e")
	var label_font_size := _card_route_label_font_size(step_label, is_current)
	draw_string(APP_FONT, card_rect.position + Vector2(0.0, 34.0), step_label, HORIZONTAL_ALIGNMENT_CENTER, card_rect.size.x, label_font_size, number_color)
	var badge_center := Vector2(card_rect.get_center().x, card_rect.position.y + card_rect.size.y * (0.42 if is_current else 0.49))
	var badge_radius := minf(card_rect.size.x * 0.34, 29.0)
	if is_boss:
		_draw_boss_emblem(badge_center, minf(badge_radius * 1.18, card_size.x * 0.40), true)
	else:
		_draw_kind_shape(badge_center, badge_radius, StringName(spec.shape_id), fill.darkened(0.16) if is_current else fill.darkened(0.06), Color("#fff0ca") if is_current else Color("#5c4933"))
		_draw_kind_icon(badge_center, badge_radius * (0.72 if kind == "RISK" else 0.62), StringName(spec.icon_id), Color("#fff0ca") if is_current else Color("#51402e"))


func _card_kind_hint(kind: String) -> String:
	return ""


func _draw_landing_effect(center: Vector2, card_size: Vector2, kind: String) -> void:
	var progress := clampf(_landing_progress, 0.0, 1.0)
	var pulse := sin(progress * PI)
	var effect_center := center + Vector2(0.0, sin(progress * PI) * 5.0)
	var ring_color := Color("#f5d37e")
	match kind:
		"COIN": ring_color = Color("#e4b83e")
		"REST": ring_color = Color("#4aa6a0")
		"RISK": ring_color = Color("#d85845")
		"ITEM": ring_color = Color("#8c65b0")
		"EVENT": ring_color = Color("#c36a4a")
		"WARP_OASIS", "LOOP_ENTRY": ring_color = Color("#68b9cf")
		"WARP_TOMB": ring_color = Color("#76539a")
		"WARP_GOLD", "LOOP_ENTRY_GOLD": ring_color = Color("#d4a83f")
		"BOSS_GATE": ring_color = Color("#d6a33a")
	var ring := ring_color
	ring.a = 0.30 + pulse * 0.55
	draw_arc(effect_center, maxf(card_size.x * 0.50, 28.0) + pulse * 10.0, 0.0, TAU, 40, ring, 4.0 + pulse * 2.0, true)
	match kind:
		"NORMAL":
			for index: int in range(5):
				var angle := TAU * float(index) / 5.0
				var puff_position := effect_center + Vector2(cos(angle), sin(angle)) * (18.0 + progress * 22.0)
				draw_circle(puff_position, 3.0 + (1.0 - progress) * 3.0, Color(0.63, 0.47, 0.28, 0.35 * (1.0 - progress)))
		"COIN":
			for index: int in range(3):
				var coin_position := effect_center + Vector2(float(index - 1) * 17.0, -card_size.y * 0.22 - progress * (32.0 + float(index) * 10.0))
				draw_circle(coin_position, 6.0 + pulse * 2.0, Color("#d8a63a"))
				draw_circle(coin_position, 3.0 + pulse, Color("#fff0a8"))
			_draw_landing_result(effect_center, card_size, Color("#8a6422"))
		"REST":
			_draw_kind_icon(effect_center + Vector2(0.0, -card_size.y * 0.22 - pulse * 18.0), 20.0 + pulse * 7.0, &"heart", Color("#d9f0c9"))
			_draw_landing_result(effect_center, card_size, Color("#2f7f78"))
		"RISK":
			var warning_center := effect_center + Vector2(0.0, -card_size.y * 0.22 - pulse * 18.0)
			_draw_kind_shape(warning_center, 18.0 + pulse * 5.0, &"triangle", Color("#d85845"), Color("#ffe6bd"))
			_draw_kind_icon(warning_center, 12.0 + pulse * 3.0, &"warning", Color("#fff0ca"))
			_draw_landing_result(effect_center, card_size, Color("#a13b2e"))
		"ITEM":
			var item_center := effect_center + Vector2(0.0, -card_size.y * 0.22 - pulse * 18.0)
			_draw_kind_shape(item_center, 19.0 + pulse * 5.0, &"box", Color("#76529b"), Color("#f0d8ff"))
			_draw_kind_icon(item_center, 14.0 + pulse * 3.0, &"kenney_pouch", Color("#fff0ca"))
			_draw_landing_result(effect_center, card_size, Color("#67478e"))
		"EVENT", "WARP_OASIS", "WARP_TOMB", "WARP_GOLD", "LOOP_ENTRY", "LOOP_ENTRY_GOLD", "BOSS_GATE":
			var spec := tile_visual_spec(kind)
			_draw_kind_icon(effect_center + Vector2(0.0, -card_size.y * 0.22 - pulse * 18.0), 20.0 + pulse * 6.0, StringName(spec.icon_id), Color("#fff0ca"))
			_draw_landing_result(effect_center, card_size, ring_color.darkened(0.24))


func _draw_landing_result(center: Vector2, card_size: Vector2, color: Color) -> void:
	if _landing_result_text.is_empty():
		return
	draw_string(APP_FONT, center + Vector2(-50.0, -card_size.y * 0.52 - 18.0), _landing_result_text, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 25, color)


func _card_style(background: Color, border: Color, border_width: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(int(border_width))
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.18, 0.10, 0.04, 0.30)
	style.shadow_size = 7
	style.shadow_offset = Vector2(2.0, 4.0)
	return style


func _draw_semicircle_carousel() -> void:
	var positions: Array[Dictionary] = [_current_position.duplicate(true)]
	positions.append_array(prominent_positions())
	var path := PackedVector2Array()
	for slot_index: int in range(CAROUSEL_SLOT_NORMALIZED.size()):
		path.append(carousel_slot_position(slot_index))
	var route_id := str(_current_position.get("route_id", ""))
	var segment_styles := carousel_segment_style_ids()
	for edge_segment: Dictionary in carousel_main_edge_segments():
		draw_line(edge_segment.from, edge_segment.to, Color(MAIN_TEAL, 0.55), 8.0, true)
	for index: int in range(segment_styles.size()):
		if segment_styles[index] == String(ROUTE_STYLE_BYPASS):
			_draw_dashed_segment(path[index], path[index + 1], Color(BYPASS_RUST, 0.9), 7.0, 10.0)
		else:
			draw_line(path[index], path[index + 1], Color(MAIN_TEAL, 0.55), 8.0, true)
	if not _course.is_bypass_route(route_id) and not _branch_preview_keys().is_empty():
		# Keep the approaching bypass choice visible without returning the local
		# main-route view to world/camera coordinates.
		var fork_from := path[2] + Vector2(0.0, -12.0)
		var fork_bend := path[3] + Vector2(34.0, -18.0)
		var fork_to := path[4] + Vector2(28.0, -8.0)
		_draw_dashed_segment(fork_from, fork_bend, Color(BYPASS_RUST, 0.92), 5.0, 10.0)
		_draw_dashed_segment(fork_bend, fork_to, Color(BYPASS_RUST, 0.92), 5.0, 10.0)
	for slot_index: int in range(mini(positions.size(), CAROUSEL_SLOT_NORMALIZED.size())):
		var draw_position := carousel_slot_position(slot_index)
		if _carousel_progress < 1.0:
			draw_position = carousel_slot_position(slot_index + 1).lerp(draw_position, _carousel_progress) if slot_index + 1 < CAROUSEL_SLOT_NORMALIZED.size() else draw_position
		var position: Dictionary = positions[slot_index]
		_draw_route_tile_at(position, draw_position, slot_index == 0)
	for context: Dictionary in carousel_context_positions():
		_draw_carousel_context_tile_at(context, carousel_context_slot_position(context))
	if _carousel_progress < 1.0 and not _carousel_previous_position.is_empty():
		var exit_target := Vector2(-CAROUSEL_CURRENT_RADIUS * 2.5, carousel_slot_position(0).y)
		_draw_route_tile_at(_carousel_previous_position, carousel_slot_position(0).lerp(exit_target, _carousel_progress), true)


func _draw_route_tile_at(route_position: Dictionary, screen_position: Vector2, is_current: bool) -> void:
	var route_id := str(route_position.get("route_id", ""))
	var tile_index := int(route_position.get("tile_index", 0))
	var saved_position := _current_position
	if is_current:
		_current_position = route_position
	_carousel_tile_is_current = is_current
	_carousel_tile_is_context = false
	_draw_route_tile(route_id, tile_index, screen_position, true)
	_carousel_tile_is_current = false
	_current_position = saved_position


func _draw_carousel_context_tile_at(route_position: Dictionary, screen_position: Vector2) -> void:
	var route_id := str(route_position.get("route_id", ""))
	var tile_index := int(route_position.get("tile_index", 0))
	_carousel_tile_is_context = true
	_draw_route_tile(route_id, tile_index, screen_position, true)
	_carousel_tile_is_context = false


func _draw_flat_atlas_texture() -> void:
	# B direction: calm paper and restrained cartographic ink remain flat while
	# only the current route vicinity rises into the miniature layer.
	var atlas_rect := Rect2(Vector2.ZERO, size)
	draw_texture_rect(PARCHMENT_BASE, atlas_rect, false, Color(1.0, 1.0, 1.0, 0.96))
	var parallax_offset := _straight_camera_offset * 0.12 if _straight_travel_active else 0.0
	draw_set_transform(Vector2(-parallax_offset, 0.0), 0.0, Vector2.ONE)
	draw_texture_rect(CAIRO_CARTOGRAPHY_INK, atlas_rect, false, Color(1.0, 1.0, 1.0, 0.24))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(atlas_rect, Color(PARCHMENT, 0.08))


static func district_scenery_state_for_main_position(tile_position: float) -> Dictionary:
	var position := clampf(tile_position, 0.0, 89.0)
	var district_index := 0
	for index: int in range(DISTRICT_START_TILES.size()):
		if position >= float(DISTRICT_START_TILES[index]):
			district_index = index
		else:
			break
	var start_tile := float(DISTRICT_START_TILES[district_index])
	var end_tile := 90.0 if district_index == DISTRICT_START_TILES.size() - 1 else float(DISTRICT_START_TILES[district_index + 1])
	var span := maxf(1.0, end_tile - start_tile - 1.0)
	var local_progress := clampf((position - start_tile) / span, 0.0, 1.0)
	var has_next := district_index < DISTRICT_IDS.size() - 1
	var transition := smoothstep(end_tile - DISTRICT_TRANSITION_TILES, end_tile - 1.0, position) if has_next else 0.0
	return {
		"district_id": DISTRICT_IDS[district_index],
		"next_district_id": DISTRICT_IDS[district_index + 1] if has_next else DISTRICT_IDS[district_index],
		"local_progress": local_progress,
		"transition": transition,
	}


func _build_bypass_points(from: Vector2, to: Vector2, point_count: int, side_offset: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var axis := to - from
	var normal := Vector2(-axis.y, axis.x).normalized()
	for index: int in range(point_count):
		var progress := float(index + 1) / float(point_count + 1)
		points.append(from.lerp(to, progress) + normal * sin(progress * PI) * side_offset)
	return points


func _visual_main_tile_position() -> float:
	if _straight_travel_active and str(_straight_travel_start_position.get("route_id", "")) == V06CourseModelScript.ROUTE_MAIN:
		var start_tile := float(_straight_travel_start_position.get("tile_index", 0))
		return start_tile + lerpf(float(_straight_step_from), float(_straight_travel_player_step), _straight_step_progress)
	if str(_current_position.get("route_id", "")) != V06CourseModelScript.ROUTE_MAIN:
		return float(_current_position.get("tile_index", 0))
	if not _carousel_previous_position.is_empty() \
			and str(_carousel_previous_position.get("route_id", "")) == V06CourseModelScript.ROUTE_MAIN:
		return lerpf(
			float(_carousel_previous_position.get("tile_index", 0)),
			float(_current_position.get("tile_index", 0)),
			_carousel_progress
		)
	return float(_current_position.get("tile_index", 0))


func _active_scenery_state() -> Dictionary:
	var route_id := str(_current_position.get("route_id", V06CourseModelScript.ROUTE_MAIN))
	if route_id == V06CourseModelScript.ROUTE_MAIN or (_straight_travel_active and str(_straight_travel_start_position.get("route_id", "")) == V06CourseModelScript.ROUTE_MAIN):
		return district_scenery_state_for_main_position(_visual_main_tile_position())
	var district_id: StringName = &"MARKET"
	match route_id:
		V06CourseModelScript.ROUTE_BYPASS_BAZAAR:
			district_id = &"MARKET"
		V06CourseModelScript.ROUTE_BYPASS_SIROCCO:
			district_id = &"DUNES"
		V06CourseModelScript.ROUTE_LOOP_OASIS:
			district_id = &"OASIS"
		V06CourseModelScript.ROUTE_LOOP_TOMB:
			district_id = &"RUINS"
	var route_size := maxi(1, _route_size(route_id) - 1)
	var loop_background_static := route_id in [V06CourseModelScript.ROUTE_LOOP_OASIS, V06CourseModelScript.ROUTE_LOOP_TOMB]
	return {
		"district_id": district_id,
		"next_district_id": district_id,
		"local_progress": 0.5 if loop_background_static else clampf(float(_current_position.get("tile_index", 0)) / float(route_size), 0.0, 1.0),
		"transition": 0.0,
		"background_static": loop_background_static,
	}


func _draw_district_scenery() -> void:
	if _overview_mode:
		return
	var state := _active_scenery_state()
	var transition := float(state.get("transition", 0.0))
	var local_progress := float(state.get("local_progress", 0.0))
	if bool(state.get("background_static", false)):
		local_progress = 0.5
	_draw_district_scenery_layer(
		StringName(state.get("district_id", &"MARKET")),
		local_progress,
		1.0 - transition,
		-transition * size.x * 0.08
	)
	if transition > 0.001:
		_draw_district_scenery_layer(
			StringName(state.get("next_district_id", &"PYRAMID")),
			0.0,
			transition,
			(1.0 - transition) * size.x * 0.24
		)


func _draw_district_scenery_layer(district_id: StringName, progress: float, alpha: float, transition_shift: float) -> void:
	var texture := DISTRICT_SCENERY_TEXTURES.get(district_id) as Texture2D
	if texture == null or alpha <= 0.001:
		return
	var source_size := texture.get_size()
	var target_height := maxf(230.0, size.y * 0.43)
	var target_width := target_height * source_size.x / maxf(source_size.y, 1.0)
	var minimum_width := size.x * 1.22
	if target_width < minimum_width:
		var scale_up := minimum_width / target_width
		target_width *= scale_up
		target_height *= scale_up
	var overflow := maxf(0.0, target_width - size.x)
	var travel := lerpf(overflow * 0.10, overflow * 0.90, clampf(progress, 0.0, 1.0))
	var destination := Rect2(
		Vector2(-travel + transition_shift, size.y * 0.09),
		Vector2(target_width, target_height)
	)
	draw_texture_rect(texture, destination, false, Color(1.0, 0.96, 0.84, alpha * 0.46))


func district_scenery_receipt() -> Dictionary:
	var state := _active_scenery_state()
	state["visual_main_tile_position"] = _visual_main_tile_position()
	state["overview_hidden"] = _overview_mode
	state["asset_count"] = DISTRICT_SCENERY_TEXTURES.size()
	state["background_static"] = bool(state.get("background_static", false))
	return state


func _draw_route_graph() -> void:
	var main: Array = _route_points[V06CourseModelScript.ROUTE_MAIN]
	var main_screen := PackedVector2Array()
	for point: Vector2 in main:
		main_screen.append(_to_screen(point))
	draw_polyline(main_screen, Color(MAIN_TEAL, 0.36), 8.0, true)

	for bypass_definition: Dictionary in _bypass_definitions():
		var bypass_route := str(bypass_definition.route_id)
		var bypass: Array = _route_points[bypass_route]
		var bypass_graph: Array[Vector2] = [main[_fork_index(bypass_route)]]
		for point: Vector2 in bypass:
			bypass_graph.append(point)
		bypass_graph.append(main[_rejoin_index(bypass_route)])
		var active := str(_current_position.get("route_id", "")) == bypass_route or _comparison_route_id == bypass_route
		var line_color := Color(BYPASS_RUST, 0.94 if active else 0.34)
		for index: int in range(bypass_graph.size() - 1):
			_draw_dashed_segment(_to_screen(bypass_graph[index]), _to_screen(bypass_graph[index + 1]), line_color, 10.0 if active else 8.0, 15.0)
		_draw_bypass_annotation(bypass_definition, bypass_graph, active, false)

	for loop_route: String in [V06CourseModelScript.ROUTE_LOOP_OASIS, V06CourseModelScript.ROUTE_LOOP_TOMB]:
		var loop: Array = _route_points[loop_route]
		var loop_screen := PackedVector2Array()
		for point: Vector2 in loop:
			loop_screen.append(_to_screen(point))
		loop_screen.append(_to_screen(loop[0]))
		var loop_color := LOOP_TEAL if loop_route == V06CourseModelScript.ROUTE_LOOP_OASIS else LOOP_TOMB
		draw_polyline(loop_screen, Color(loop_color, 0.72), 7.0, true)

	var prominent_keys := _prominent_keys()
	var branch_keys := _branch_preview_keys()
	for route_id: String in [V06CourseModelScript.ROUTE_MAIN, V06CourseModelScript.ROUTE_BYPASS_BAZAAR, V06CourseModelScript.ROUTE_BYPASS_SIROCCO, V06CourseModelScript.ROUTE_LOOP_OASIS, V06CourseModelScript.ROUTE_LOOP_TOMB]:
		var points: Array = _route_points[route_id]
		for tile_index: int in range(points.size()):
			var is_local := _overview_mode or prominent_keys.has(_position_key(route_id, tile_index)) or branch_keys.has(_position_key(route_id, tile_index))
			_draw_route_tile(route_id, tile_index, _to_screen(points[tile_index]), is_local)
	_draw_comparison_targets()
	if _overview_mode:
		for bypass_definition: Dictionary in _bypass_definitions():
			var route_id := str(bypass_definition.route_id)
			var graph: Array[Vector2] = [main[_fork_index(route_id)]]
			graph.append_array(_route_points[route_id])
			graph.append(main[_rejoin_index(route_id)])
			_draw_bypass_annotation(bypass_definition, graph, str(_current_position.get("route_id", "")) == route_id or _comparison_route_id == route_id, true)
	_draw_boss_gate(_to_screen(main[_boss_index()]))
	var shown_exit_steps := displayed_exit_steps()
	if shown_exit_steps > 0:
		var route_points: Array = _route_points.get(str(_current_position.route_id), [])
		var center := Vector2.ZERO
		for point: Vector2 in route_points:
			center += point
		if not route_points.is_empty():
			_draw_exit_badge(_to_screen(center / float(route_points.size())), shown_exit_steps)


func _draw_bypass_annotation(definition: Dictionary, graph: Array[Vector2], active: bool, label_only: bool) -> void:
	if graph.size() < 3:
		return
	var entrance := _to_screen(graph.front())
	var exit := _to_screen(graph.back())
	var marker_color := Color(BYPASS_RUST, 1.0 if active else 0.62)
	if not label_only:
		# Entrance: a small split chevron. Exit: two strokes visibly converge.
		draw_line(entrance + Vector2(-8.0, -7.0), entrance, marker_color, 3.0, true)
		draw_line(entrance + Vector2(-8.0, 7.0), entrance, marker_color, 3.0, true)
		draw_line(exit + Vector2(-9.0, -7.0), exit, marker_color, 3.0, true)
		draw_line(exit + Vector2(-9.0, 7.0), exit, marker_color, 3.0, true)
		draw_circle(exit, 4.5, marker_color)
	if not _overview_mode or not label_only:
		return
	var middle_world := graph[graph.size() / 2]
	var side := str(definition.get("side", "right"))
	var label_center := _to_screen(middle_world) + (Vector2(150.0, -65.0) if side == "right" else Vector2(0.0, 55.0))
	var short_name := "裏路地" if side == "right" else "砂嵐"
	var text_color := Color(INK, 0.96 if active else 0.70)
	if side == "right":
		var label := "%s　%dマス短縮" % [short_name, int(definition.get("saved_steps", 0))]
		draw_string(APP_FONT, label_center + Vector2(-92.0, 0.0), label, HORIZONTAL_ALIGNMENT_CENTER, 184.0, 15, text_color)
	else:
		draw_string(APP_FONT, label_center + Vector2(-65.0, 0.0), short_name, HORIZONTAL_ALIGNMENT_CENTER, 130.0, 15, text_color)
		draw_string(APP_FONT, label_center + Vector2(-65.0, 17.0), "%dマス短縮" % int(definition.get("saved_steps", 0)), HORIZONTAL_ALIGNMENT_CENTER, 130.0, 13, text_color)


func _draw_route_tile(route_id: String, tile_index: int, screen_position: Vector2, prominent: bool) -> void:
	if screen_position.x < -80.0 or screen_position.x > size.x + 80.0 or screen_position.y < -80.0 or screen_position.y > size.y + 80.0:
		return
	var is_current := route_id == str(_current_position.route_id) and tile_index == int(_current_position.tile_index)
	var is_active_exit: bool = _course.is_loop_route(str(_current_position.get("route_id", ""))) and route_id == str(_current_position.get("route_id", "")) and _course.is_loop_exit(route_id, tile_index)
	var loop_preview_tile: bool = _course.is_loop_route(route_id) and _loop_preview_active()
	if not prominent and not loop_preview_tile and not is_current:
		return
	var radius := (CAROUSEL_CONTEXT_RADIUS if _carousel_tile_is_context else carousel_tile_radius(_carousel_tile_is_current)) if uses_semicircle_carousel() else (16.0 if _overview_mode and is_current else (11.0 if _overview_mode else (31.0 if is_current else (29.0 if is_active_exit else (15.0 if loop_preview_tile and not prominent else 25.0)))))
	# Only the current vicinity rises above the printed atlas. Canonical labels
	# stay runtime-drawn, so the art never owns topology or UI text.
	draw_circle(screen_position + Vector2(0.0, 8.0), radius + (5.0 if is_current else 2.0), Color(0.20, 0.13, 0.07, 0.26 if is_current else 0.18))
	if is_active_exit:
		draw_circle(screen_position, radius + 13.0, Color(EXIT_GOLD, 0.16))
		draw_arc(screen_position, radius + 10.0, 0.0, TAU, 40, Color("#f6d477"), 4.0, true)
		draw_arc(screen_position, radius + 4.0, 0.0, TAU, 40, Color(EXIT_GOLD, 0.78), 2.0, true)
	var accent := MAIN_TEAL if route_id == V06CourseModelScript.ROUTE_MAIN else (BYPASS_RUST if _course.is_bypass_route(route_id) else (LOOP_TEAL if route_id == V06CourseModelScript.ROUTE_LOOP_OASIS else LOOP_TOMB))
	var tile_scale := tile_draw_diameter_for_radius(radius) / ROUTE_TILE_CELL_SIZE.x
	var tile_size := ROUTE_TILE_CELL_SIZE * tile_scale
	var tile_anchor := ROUTE_TILE_ANCHOR * tile_scale
	var tile_cell := route_tile_cell_for(route_id, is_current)
	var tile_source := Rect2(Vector2(float(tile_cell) * ROUTE_TILE_CELL_SIZE.x, 0.0), ROUTE_TILE_CELL_SIZE)
	draw_texture_rect_region(RAISED_ROUTE_TILES, Rect2(screen_position - tile_anchor, tile_size), tile_source)
	if is_current:
		var ring_center := screen_position - Vector2(0.0, radius * 0.10)
		draw_arc(ring_center, radius * 0.86, 0.0, TAU, 40, Color(CURRENT_RING_ACCENT, 0.42), 2.0, true)
		draw_arc(ring_center, radius * 0.72, 0.0, TAU, 40, CURRENT_RING_COLOR, CURRENT_RING_WIDTH, true)
	var kind := displayed_tile_kind_for(route_id, tile_index)
	if not _carousel_tile_is_context:
		_draw_tile_kind_badge(screen_position - Vector2(0.0, radius * 0.88), radius, kind, is_current)
	var label := "EXIT" if is_active_exit else _tile_label(route_id, tile_index)
	var text_color := Color("#8a5713") if is_active_exit else (Color("#fff3d5") if is_current else (Color("#a4947e") if _carousel_tile_is_context else MUTED_INK))
	var label_size := 10 if _overview_mode else (11 if _carousel_tile_is_context else (12 if loop_preview_tile and not prominent else 14))
	draw_string(APP_FONT, screen_position + Vector2(-radius, radius * 0.88), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, label_size, text_color)
	if is_active_exit:
		var destination_label: String = str(_course.loop_exit_label(route_id, tile_index))
		draw_string(APP_FONT, screen_position + Vector2(-radius * 1.35, radius * 1.46), destination_label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.7, 10 if _overview_mode else 12, Color("#f6d477"))


func _draw_comparison_targets() -> void:
	if _comparison_targets.is_empty():
		return
	for choice_id: String in _comparison_targets:
		var target: Variant = _comparison_targets.get(choice_id)
		if not target is Dictionary:
			continue
		var position: Variant = (target as Dictionary).get("position", {})
		if not position is Dictionary or not _is_known_position(position):
			continue
		var center: Vector2 = _to_screen(world_position_for(position))
		var is_main: bool = choice_id == V06CourseModelScript.ROUTE_MAIN
		var color: Color = Color(MAIN_TEAL if is_main else BYPASS_RUST, 0.98)
		draw_circle(center, 27.0, Color(color, 0.18))
		draw_arc(center, 23.0, 0.0, TAU, 40, color, 5.0, true)
		var route_label: String = "本線" if is_main else "近道"
		var kind_label: String = _kind_short_label(str((target as Dictionary).get("tile_kind", "NORMAL")))
		draw_string(APP_FONT, center + Vector2(-65.0, -34.0), "%s → %s" % [route_label, kind_label], HORIZONTAL_ALIGNMENT_CENTER, 130.0, 15, Color("#fff3d5"))


func _kind_short_label(kind: String) -> String:
	match kind:
		"REST": return "♥ 回復"
		"RISK": return "⚠ 危険"
		"COIN": return "コイン"
		"ITEM": return "道具"
		"EVENT": return "？"
		_: return "旅路"


func _draw_tile_kind_badge(center: Vector2, tile_radius: float, kind: String, is_current: bool) -> void:
	if kind == "BOSS_GATE":
		var boss_radius := maxf(kind_badge_radius_for_tile(tile_radius) * 1.42, 12.0 if _overview_mode else 28.0)
		_draw_boss_emblem(center, boss_radius, false)
		return
	var spec := tile_visual_spec(kind)
	var badge_radius := kind_badge_radius_for_tile(tile_radius)
	var fill: Color = spec.base_color
	var outline := Color("#f8eccf") if is_current else Color("#514538")
	_draw_kind_shape(center, badge_radius, StringName(spec.shape_id), fill, outline)
	var icon_id := StringName(spec.icon_id)
	var icon_scale := 0.82 if kind == "RISK" else (0.88 if icon_id == &"heart" else (0.70 if tile_kind_icon_texture(icon_id) != null else 0.58))
	_draw_kind_icon(center, badge_radius * icon_scale, icon_id, Color("#fff0ca") if kind in ["RISK", "START", "BOSS_GATE"] else Color("#41372e"))


func _draw_kind_shape(center: Vector2, radius: float, shape_id: StringName, fill: Color, outline: Color) -> void:
	match shape_id:
		&"circle":
			draw_circle(center, radius, fill)
			draw_arc(center, radius, 0.0, TAU, 28, outline, 2.2, true)
		&"leaf":
			_draw_filled_outline(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.78, -radius * 0.12), center + Vector2(0, radius), center + Vector2(-radius * 0.78, radius * 0.12)]), fill, outline)
		&"triangle":
			_draw_filled_outline(_regular_polygon(center, radius, 3, -PI * 0.5), fill, outline)
		&"box":
			var rect := Rect2(center - Vector2.ONE * radius * 0.88, Vector2.ONE * radius * 1.76)
			draw_rect(rect, fill)
			draw_rect(rect, outline, false, 2.2)
		&"hex":
			_draw_filled_outline(_regular_polygon(center, radius, 6, 0.0), fill, outline)
		&"ring":
			draw_circle(center, radius, fill)
			draw_arc(center, radius, 0.0, TAU, 28, outline, 2.2, true)
			draw_circle(center, radius * 0.63, Color(PARCHMENT, 0.92))
			draw_arc(center, radius * 0.63, 0.0, TAU, 24, outline, 1.6, true)
		&"gate":
			var rect := Rect2(center - Vector2(radius * 0.78, radius * 0.55), Vector2(radius * 1.56, radius * 1.35))
			draw_rect(rect, fill)
			draw_rect(rect, outline, false, 2.2)
			draw_arc(center + Vector2(0, -radius * 0.48), radius * 0.78, PI, TAU, 20, outline, 2.2, true)
		&"diamond":
			_draw_filled_outline(_regular_polygon(center, radius, 4, 0.0), fill, outline)
		_:
			var style := _panel_style(fill, outline, maxi(3, int(radius * 0.35)))
			draw_style_box(style, Rect2(center - Vector2.ONE * radius * 0.84, Vector2.ONE * radius * 1.68))


func _draw_kind_icon(center: Vector2, radius: float, icon_id: StringName, color: Color) -> void:
	var texture := tile_kind_icon_texture(icon_id)
	if texture != null:
		draw_texture_rect(texture, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)
		return
	var width := maxf(1.8, radius * 0.26)
	match icon_id:
		&"star":
			_draw_filled_outline(_star_polygon(center, radius, radius * 0.40, 4), color, color)
		&"heart":
			draw_circle(center + Vector2(-radius * 0.28, -radius * 0.18), radius * 0.34, color)
			draw_circle(center + Vector2(radius * 0.28, -radius * 0.18), radius * 0.34, color)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.60, -radius * 0.04), center + Vector2(radius * 0.60, -radius * 0.04), center + Vector2(0, radius * 0.78)]), color)
		&"warning":
			draw_line(center + Vector2(0, -radius * 0.58), center + Vector2(0, radius * 0.20), color, width, true)
			draw_circle(center + Vector2(0, radius * 0.56), width * 0.55, color)
		&"bag":
			var bag := Rect2(center + Vector2(-radius * 0.58, -radius * 0.12), Vector2(radius * 1.16, radius * 0.82))
			draw_rect(bag, color)
			draw_arc(center + Vector2(0, -radius * 0.10), radius * 0.38, PI, TAU, 12, color, width, true)
		&"scroll":
			var scroll := Rect2(center + Vector2(-radius * 0.50, -radius * 0.58), Vector2(radius, radius * 1.16))
			draw_rect(scroll, color, false, width)
			draw_line(center + Vector2(-radius * 0.28, -radius * 0.18), center + Vector2(radius * 0.28, -radius * 0.18), color, width, true)
			draw_line(center + Vector2(-radius * 0.28, radius * 0.20), center + Vector2(radius * 0.18, radius * 0.20), color, width, true)
		&"swirl":
			draw_arc(center, radius * 0.72, -PI * 0.10, PI * 1.45, 20, color, width, true)
			draw_arc(center + Vector2(radius * 0.12, radius * 0.08), radius * 0.35, PI * 0.55, PI * 2.0, 14, color, width, true)
		&"exit":
			draw_line(center + Vector2(-radius * 0.58, 0), center + Vector2(radius * 0.42, 0), color, width, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(radius * 0.12, -radius * 0.42), center + Vector2(radius * 0.70, 0), center + Vector2(radius * 0.12, radius * 0.42)]), color)
		&"crown":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.70, radius * 0.42), center + Vector2(-radius * 0.56, -radius * 0.50), center + Vector2(0, 0), center + Vector2(radius * 0.56, -radius * 0.50), center + Vector2(radius * 0.70, radius * 0.42)]), color)
		&"fork":
			draw_line(center + Vector2(0, radius * 0.65), center + Vector2(0, -radius * 0.10), color, width, true)
			draw_line(center + Vector2(0, -radius * 0.10), center + Vector2(-radius * 0.55, -radius * 0.62), color, width, true)
			draw_line(center + Vector2(0, -radius * 0.10), center + Vector2(radius * 0.55, -radius * 0.62), color, width, true)
		&"flag":
			draw_line(center + Vector2(-radius * 0.35, radius * 0.68), center + Vector2(-radius * 0.35, -radius * 0.68), color, width, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.28, -radius * 0.62), center + Vector2(radius * 0.60, -radius * 0.35), center + Vector2(-radius * 0.28, -radius * 0.05)]), color)
		_:
			_draw_filled_outline(_regular_polygon(center, radius * 0.62, 4, 0.0), color, color)


func _draw_direction_chevron(center: Vector2, direction: Vector2, color: Color, width: float) -> void:
	var axis := direction.normalized()
	var side := Vector2(-axis.y, axis.x)
	var tip := center + axis * 8.0
	var left := center - axis * 4.0 + side * 6.0
	var right := center - axis * 4.0 - side * 6.0
	draw_line(left, tip, color, width, true)
	draw_line(right, tip, color, width, true)


func tile_kind_icon_texture(icon_id: StringName) -> Texture2D:
	match icon_id:
		&"imagegen_footprints": return KIND_ICON_NORMAL
		&"kenney_tokens_stack": return KIND_ICON_COIN
		&"kenney_campfire": return KIND_ICON_REST
		&"kenney_skull": return KIND_ICON_RISK
		&"kenney_pouch": return KIND_ICON_ITEM
		&"kenney_book_open": return KIND_ICON_EVENT
		_: return null


func uses_production_tile_kind_icons() -> bool:
	for kind: String in ["NORMAL", "COIN", "REST", "RISK", "ITEM", "EVENT"]:
		var icon_id := StringName(tile_visual_spec(kind).icon_id)
		if tile_kind_icon_texture(icon_id) == null and icon_id != &"heart":
			return false
	return true


func tile_kind_glyph_opaque_bound_at_360(kind: String, tile_radius := CAROUSEL_TILE_RADIUS) -> float:
	var icon_id := StringName(tile_visual_spec(kind).icon_id)
	var texture := tile_kind_icon_texture(icon_id)
	if icon_id == &"heart":
		return kind_badge_radius_for_tile(tile_radius) * 0.88 * 0.78
	if texture == null:
		return 0.0
	var used := texture.get_image().get_used_rect()
	var source_extent := float(maxi(used.size.x, used.size.y))
	var icon_scale := 0.82 if kind == "RISK" else 0.70
	var destination_extent := kind_badge_radius_for_tile(tile_radius) * icon_scale * 2.0
	return source_extent / 128.0 * destination_extent * 0.5


func _regular_polygon(center: Vector2, radius: float, sides: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(sides):
		var angle := rotation + TAU * float(index) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _star_polygon(center: Vector2, outer_radius: float, inner_radius: float, points_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(points_count * 2):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / float(points_count * 2)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _draw_filled_outline(points: PackedVector2Array, fill: Color, outline: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
		draw_polyline(closed, outline, 2.2, true)


func _draw_cat_marker() -> void:
	if _overview_mode:
		var overview_cat := _to_screen(_cat_world) - Vector2(0.0, 18.0)
		draw_circle(overview_cat, 15.0, Color("#c98b55"))
		draw_colored_polygon(PackedVector2Array([overview_cat + Vector2(-14, -6), overview_cat + Vector2(-8, -22), overview_cat + Vector2(-2, -7)]), Color("#a96f43"))
		draw_colored_polygon(PackedVector2Array([overview_cat + Vector2(2, -7), overview_cat + Vector2(8, -22), overview_cat + Vector2(15, -6)]), Color("#a96f43"))
		draw_circle(overview_cat + Vector2(-5, -1), 2.0, Color("#263b36"))
		draw_circle(overview_cat + Vector2(5, -1), 2.0, Color("#263b36"))
		return
	var grounded_feet := _card_route_cat_feet_anchor() if uses_card_route() else (carousel_cat_feet_anchor() if uses_semicircle_carousel() else _to_screen(_cat_world))
	var landing_lift := sin(_landing_progress * PI) * 18.0 if not _landing_kind.is_empty() else 0.0
	var feet := grounded_feet - Vector2(0.0, _cat_lift + landing_lift)
	if feet.x < -100.0 or feet.x > size.x + 100.0 or feet.y < -120.0 or feet.y > size.y + 100.0:
		return
	# Keep the shadow tied to the route tile while the sprite follows the hop arc.
	draw_circle(grounded_feet + Vector2(0.0, 5.0), 34.0, Color(0.16, 0.10, 0.05, 0.18))
	var texture := _cat_texture_for_state(_cat_animation_state)
	var frame_count := _cat_frame_count_for_state(_cat_animation_state)
	var frame_index := clampi(_cat_animation_frame, 0, frame_count - 1)
	var draw_size := CAT_FRAME_SIZE * CAT_DRAW_SCALE
	var destination := Rect2(feet - CAT_FEET_ANCHOR * CAT_DRAW_SCALE, draw_size)
	var source := Rect2(Vector2(float(frame_index) * CAT_FRAME_SIZE.x, 0.0), CAT_FRAME_SIZE)
	draw_texture_rect_region(texture, destination, source)


func _card_route_cat_feet_anchor() -> Vector2:
	if _straight_travel_active:
		var display_offset := _straight_card_display_offset()
		var from_center := _card_route_slot_position(_straight_step_from) + display_offset
		var to_center := _card_route_slot_position(_straight_travel_player_step) + display_offset
		return from_center.lerp(to_center, _straight_step_progress) + Vector2(0.0, _card_route_card_size().y * 0.52)
	var target := _card_route_slot_position(0) + Vector2(0.0, _card_route_card_size().y * 0.52)
	if _carousel_progress < 1.0 and not _carousel_previous_position.is_empty():
		return _card_route_slot_position(0).lerp(target, _carousel_progress) + Vector2(0.0, _card_route_card_size().y * 0.52)
	return target


func _cat_texture_for_state(state: StringName) -> Texture2D:
	if state == &"jump":
		return CAT_JUMP_STRIP
	if state == &"land":
		return CAT_LAND_STRIP
	return CAT_IDLE_STRIP


func _cat_frame_count_for_state(state: StringName) -> int:
	if state == &"jump":
		return 6
	return 4


func _draw_route_legend() -> void:
	var panel := Rect2(Vector2(16, 14), Vector2(292, 54))
	draw_style_box(_panel_style(Color(PARCHMENT, 0.90), Color(PARCHMENT_DARK, 0.72), 12), panel)
	draw_line(Vector2(30, 31), Vector2(72, 31), MAIN_TEAL, 6.0, true)
	draw_string(APP_FONT, Vector2(80, 39), "本線", HORIZONTAL_ALIGNMENT_LEFT, 54, 18, INK)
	_draw_dashed_segment(Vector2(142, 31), Vector2(184, 31), BYPASS_RUST, 6.0, 9.0)
	draw_string(APP_FONT, Vector2(191, 39), "近道", HORIZONTAL_ALIGNMENT_LEFT, 54, 18, INK)
	draw_arc(Vector2(260, 31), 10.0, 0.0, TAU, 20, LOOP_TEAL, 4.0, true)
	draw_arc(Vector2(282, 31), 10.0, 0.0, TAU, 20, LOOP_TOMB, 4.0, true)


func _draw_exit_badge(center: Vector2, steps: int) -> void:
	var rect := Rect2(center - Vector2(78, 34), Vector2(156, 68))
	draw_style_box(_panel_style(Color("#123532"), Color("#f2c65d"), 13), rect)
	var distance_copy := str(TranslationServer.translate(&"LOOP_EXIT_DISTANCE")) % steps
	var rescue_copy := str(TranslationServer.translate(&"LOOP_RESCUE_PROGRESS")) % [_loop_wrap_count, _loop_rescue_threshold]
	draw_string(APP_FONT, rect.position + Vector2(0, 29), distance_copy, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 21, Color("#ffe4a0"))
	draw_string(APP_FONT, rect.position + Vector2(0, 53), rescue_copy, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 15, Color("#d7c9aa"))


func _draw_boss_gate(center: Vector2) -> void:
	if center.x < -100.0 or center.x > size.x + 100.0 or center.y < -140.0 or center.y > size.y + 100.0:
		return
	# The gate is the largest map landmark, while the wine-and-gold crown badge
	# above it provides a second, language-independent signal that this is the
	# boss destination rather than an ordinary structural tile.
	var gate_scale := 0.60 if not _overview_mode else 0.32
	var gate_size := BOSS_GATE_CELL_SIZE * gate_scale
	var gate_anchor := BOSS_GATE_ANCHOR * gate_scale
	var gate_source := Rect2(Vector2(float(boss_gate_cell()) * BOSS_GATE_CELL_SIZE.x, 0.0), BOSS_GATE_CELL_SIZE)
	var badge_center := center - Vector2(0.0, gate_size.y * 1.12)
	draw_circle(badge_center, gate_size.x * 0.29, Color(0.20, 0.07, 0.08, 0.26))
	_draw_boss_emblem(badge_center, gate_size.x * 0.19, true)
	draw_texture_rect_region(GOLD_BOSS_GATE, Rect2(center - gate_anchor, gate_size), gate_source)


func _draw_boss_emblem(center: Vector2, radius: float, show_label: bool) -> void:
	var safe_radius := maxf(radius, 1.0)
	draw_circle(center, safe_radius * 1.18, Color(0.16, 0.07, 0.08, 0.30))
	draw_circle(center, safe_radius * 1.08, BOSS_BADGE_WINE)
	draw_arc(center, safe_radius * 1.08, 0.0, TAU, 40, BOSS_BADGE_GOLD, maxf(1.8, safe_radius * 0.10), true)
	draw_arc(center, safe_radius * 0.91, 0.0, TAU, 40, BOSS_BADGE_RED, maxf(1.3, safe_radius * 0.06), true)
	for angle: float in [-PI * 0.5, -PI * 0.25, 0.0, PI * 0.25, PI * 0.5]:
		var ray_from := center + Vector2(cos(angle), sin(angle)) * safe_radius * 1.18
		var ray_to := center + Vector2(cos(angle), sin(angle)) * safe_radius * 1.34
		draw_line(ray_from, ray_to, Color(BOSS_BADGE_GOLD, 0.82), maxf(1.2, safe_radius * 0.08), true)
	var crown_top := center - Vector2(0.0, safe_radius * 0.56)
	var crown := PackedVector2Array([
		crown_top + Vector2(-safe_radius * 0.72, safe_radius * 0.82),
		crown_top + Vector2(-safe_radius * 0.57, -safe_radius * 0.02),
		crown_top + Vector2(-safe_radius * 0.12, safe_radius * 0.42),
		crown_top + Vector2(0.0, -safe_radius * 0.20),
		crown_top + Vector2(safe_radius * 0.25, safe_radius * 0.38),
		crown_top + Vector2(safe_radius * 0.70, -safe_radius * 0.08),
		crown_top + Vector2(safe_radius * 0.57, safe_radius * 0.82),
	])
	draw_colored_polygon(crown, BOSS_BADGE_GOLD)
	var crown_outline := crown.duplicate()
	crown_outline.append(crown_outline[0])
	draw_polyline(crown_outline, BOSS_BADGE_GOLD_LIGHT, maxf(1.2, safe_radius * 0.055), true)
	var band := Rect2(center + Vector2(-safe_radius * 0.72, safe_radius * 0.18), Vector2(safe_radius * 1.44, safe_radius * 0.26))
	draw_rect(band, BOSS_BADGE_GOLD_LIGHT)
	draw_rect(band, BOSS_BADGE_WINE_LIGHT, false, maxf(1.0, safe_radius * 0.04))
	draw_circle(center + Vector2(0.0, -safe_radius * 0.03), safe_radius * 0.13, BOSS_BADGE_RED)
	draw_circle(center + Vector2(-safe_radius * 0.04, -safe_radius * 0.07), safe_radius * 0.045, BOSS_BADGE_GOLD_LIGHT)
	if show_label:
		var font_size := 10 if safe_radius < 22.0 else 13
		draw_string(APP_FONT, center + Vector2(-safe_radius * 0.80, safe_radius * 1.47), "BOSS", HORIZONTAL_ALIGNMENT_CENTER, safe_radius * 1.60, font_size, BOSS_BADGE_GOLD_LIGHT)


func _draw_dashed_segment(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float) -> void:
	var length := from.distance_to(to)
	if length <= 0.0:
		return
	var direction := (to - from) / length
	var cursor := 0.0
	while cursor < length:
		var dash_end := minf(cursor + dash_length, length)
		draw_line(from + direction * cursor, from + direction * dash_end, color, width, true)
		cursor += dash_length * 1.75


func _to_screen(world: Vector2) -> Vector2:
	var route_id := str(_current_position.get("route_id", ""))
	var focus := Vector2(size.x * 0.50, size.y * 0.60) if not _overview_mode and _course.is_loop_route(route_id) else _overview_focus()
	return (world - _camera_world) * _world_zoom + focus


func _prominent_keys() -> Dictionary:
	var keys := {}
	for route_position: Dictionary in prominent_positions():
		keys[_position_key(str(route_position.route_id), int(route_position.tile_index))] = true
	return keys


func _branch_preview_keys() -> Dictionary:
	var keys := {}
	var route_id := str(_current_position.get("route_id", ""))
	var tile_index := int(_current_position.get("tile_index", -1))
	if route_id != V06CourseModelScript.ROUTE_MAIN:
		return keys
	var nearby := _bypass_near_main_index(tile_index)
	if nearby.is_empty():
		return keys
	var bypass_route := str(nearby.route_id)
	for branch_index: int in range(_route_size(bypass_route)):
		keys[_position_key(bypass_route, branch_index)] = true
	return keys


func _route_size(route_id: String) -> int:
	if _route_points.has(route_id):
		return (_route_points[route_id] as Array).size()
	var routes: Dictionary = _definition.get("routes", {})
	return routes[route_id].size() if routes.has(route_id) and routes[route_id] is Array else 0


func _bypass_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in _definition.get("bypasses", []):
		if value is Dictionary:
			result.append(value as Dictionary)
	return result


func _bypass_definition(route_id: String) -> Dictionary:
	for bypass: Dictionary in _bypass_definitions():
		if str(bypass.get("route_id", "")) == route_id:
			return bypass
	return {}


func _bypass_near_main_index(tile_index: int) -> Dictionary:
	for bypass: Dictionary in _bypass_definitions():
		var choice: Dictionary = bypass.get("choice", {})
		var fork_index := int(choice.get("tile_index", -99))
		if tile_index >= fork_index - 2 and tile_index <= fork_index:
			return bypass
	return {}


func _fork_index(route_id: String) -> int:
	var bypass := _bypass_definition(route_id)
	var choice: Dictionary = bypass.get("choice", {}) if bypass.get("choice", {}) is Dictionary else {}
	return int(choice.get("tile_index", -1))


func _rejoin_index(route_id: String) -> int:
	var bypass := _bypass_definition(route_id)
	var rejoin: Dictionary = bypass.get("rejoin", {}) if bypass.get("rejoin", {}) is Dictionary else {}
	return int(rejoin.get("tile_index", -1))


func _boss_index() -> int:
	return _route_size(V06CourseModelScript.ROUTE_MAIN) - 1


func _position_key(route_id: String, tile_index: int) -> String:
	return "%s:%d" % [route_id, tile_index]


func _loop_preview_active() -> bool:
	return false


func _tile_label(route_id: String, tile_index: int) -> String:
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		return str(tile_index + 1)
	if _course.is_bypass_route(route_id):
		return "B%d" % (tile_index + 1)
	return str(tile_index + 1)


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
