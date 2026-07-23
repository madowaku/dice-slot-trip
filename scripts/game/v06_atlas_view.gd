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

const ROUTE_STYLE_MAIN: StringName = &"main_teal_solid"
const ROUTE_STYLE_BYPASS: StringName = &"bypass_rust_dashed"
const ROUTE_STYLE_LOOP: StringName = &"loop_teal_ring_gold_exit"
const CAMERA_FOLLOW_SECONDS := 0.28
const HOP_SECONDS := 0.30
const FORWARD_VISIBLE := 6
const PROMINENT_MIN := 5
const PROMINENT_MAX := 7
const CAT_TILE_SCALE := 1.42
const CAT_FRAME_SIZE := Vector2(192.0, 192.0)
const CAT_FEET_ANCHOR := Vector2(96.0, 179.0)
const CAT_DRAW_SCALE := 0.72
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
var _overview_mode := false
var _kind_preview_overrides: Dictionary = {}
var _carousel_progress := 1.0
var _carousel_previous_position: Dictionary = {}
var _carousel_tile_is_current := false
var _carousel_tile_is_context := false


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
	var follow_weight := 1.0 - exp(-delta / CAMERA_FOLLOW_SECONDS)
	_camera_world = _camera_world.lerp(_camera_target_world, follow_weight)
	queue_redraw()


func set_route_position(route_position: Dictionary, immediate := false) -> bool:
	if not _is_known_position(route_position):
		return false
	_current_position = route_position.duplicate(true)
	_cat_world = world_position_for(_current_position)
	_camera_target_world = _camera_focus_for(_current_position)
	if immediate or _camera_world == Vector2.ZERO:
		_camera_world = _camera_target_world
	if str(_current_position.route_id) == V06CourseModelScript.ROUTE_LOOP:
		_exit_steps = _course.steps_to_exit(_current_position)
	else:
		_exit_steps = -1
	queue_redraw()
	return true


func set_overview_mode(enabled: bool) -> void:
	_overview_mode = enabled
	if enabled:
		_world_zoom = 0.28
		_camera_target_world = Vector2(520.0, 60.0)
		_camera_world = _camera_target_world
	else:
		_world_zoom = 0.72
		_camera_target_world = _camera_focus_for(_current_position)
		_camera_world = _camera_target_world
	queue_redraw()


func is_overview_mode() -> bool:
	return _overview_mode


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
	if str(_current_position.route_id) == V06CourseModelScript.ROUTE_LOOP:
		_exit_steps = _course.steps_to_exit(_current_position)
	else:
		_exit_steps = -1
	queue_redraw()


func animate_transfer_to(route_position: Dictionary) -> void:
	# Portal and exit transfers cost no die step, but a short, lower lift keeps the
	# graph transition legible instead of snapping the marker across routes.
	await animate_hop_to(route_position, HOP_SECONDS)


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
	return not _overview_mode and str(_current_position.get("route_id", "")) in [V06CourseModelScript.ROUTE_MAIN, V06CourseModelScript.ROUTE_BYPASS]


func uses_production_cat_strips() -> bool:
	return CAT_IDLE_STRIP != null and CAT_JUMP_STRIP != null and CAT_LAND_STRIP != null


func uses_production_environment_pack() -> bool:
	return PARCHMENT_BASE != null and CAIRO_CARTOGRAPHY_INK != null and RAISED_ROUTE_TILES != null and GOLD_BOSS_GATE != null


func route_tile_cell_for(route_id: String, is_current: bool) -> int:
	if is_current:
		return 3
	if route_id == V06CourseModelScript.ROUTE_BYPASS:
		return 1
	if route_id == V06CourseModelScript.ROUTE_LOOP:
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
	return str(_kind_preview_overrides.get(_position_key(route_id, tile_index), tile_kind_for(route_id, tile_index)))


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
		"REST": return {"shape_id": &"leaf", "icon_id": &"kenney_campfire", "base_color": KIND_REST, "priority": 2}
		"RISK": return {"shape_id": &"triangle", "icon_id": &"kenney_skull", "base_color": KIND_RISK, "priority": 1}
		"ITEM": return {"shape_id": &"box", "icon_id": &"kenney_pouch", "base_color": KIND_ITEM, "priority": 5}
		"EVENT": return {"shape_id": &"hex", "icon_id": &"kenney_book_open", "base_color": KIND_EVENT, "priority": 5}
		"LOOP_PORTAL", "LOOP_ENTRY": return {"shape_id": &"ring", "icon_id": &"swirl", "base_color": KIND_WARP, "priority": 4}
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
	elif route_id == V06CourseModelScript.ROUTE_BYPASS:
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
		styles.append(String(ROUTE_STYLE_BYPASS if source_route == V06CourseModelScript.ROUTE_BYPASS else ROUTE_STYLE_MAIN))
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
	elif route_id == V06CourseModelScript.ROUTE_BYPASS:
		for tile_index: int in range(index + 1, _route_size(route_id)):
			if result.size() >= FORWARD_VISIBLE:
				break
			result.append({"route_id": route_id, "tile_index": tile_index})
		for tile_index: int in range(_rejoin_index(), _route_size(V06CourseModelScript.ROUTE_MAIN)):
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
	if str(_current_position.get("route_id", "")) == V06CourseModelScript.ROUTE_LOOP:
		return _exit_steps
	return -1


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
	var bypass: Array[Vector2] = [
		Vector2(520.0, 690.0),
		Vector2(650.0, 640.0),
		Vector2(650.0, 550.0),
		Vector2(610.0, 505.0),
	]
	var loop: Array[Vector2] = []
	var loop_center := Vector2(820.0, 340.0)
	for tile_index: int in range(8):
		var angle := PI * 0.5 + TAU * float(tile_index) / 8.0
		loop.append(loop_center + Vector2(cos(angle), sin(angle)) * 108.0)
	_route_points = {
		V06CourseModelScript.ROUTE_MAIN: main,
		V06CourseModelScript.ROUTE_BYPASS: bypass,
		V06CourseModelScript.ROUTE_LOOP: loop,
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
	if route_id == V06CourseModelScript.ROUTE_LOOP:
		# The ring is the one intentional framing change: keep all eight spaces
		# centered while the fixed tray/HUD remain untouched.
		return Vector2(820.0, 340.0)
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
	if uses_semicircle_carousel():
		_draw_semicircle_carousel()
	else:
		_draw_route_graph()
	_draw_route_legend()
	_draw_cat_marker()


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
	if route_id != V06CourseModelScript.ROUTE_BYPASS and not _branch_preview_keys().is_empty():
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
	draw_texture_rect(CAIRO_CARTOGRAPHY_INK, atlas_rect, false, Color(1.0, 1.0, 1.0, 0.24))
	draw_rect(atlas_rect, Color(PARCHMENT, 0.08))


func _draw_route_graph() -> void:
	var main: Array = _route_points[V06CourseModelScript.ROUTE_MAIN]
	var main_screen := PackedVector2Array()
	for point: Vector2 in main:
		main_screen.append(_to_screen(point))
	draw_polyline(main_screen, Color(MAIN_TEAL, 0.36), 8.0, true)

	var bypass: Array = _route_points[V06CourseModelScript.ROUTE_BYPASS]
	var bypass_graph: Array[Vector2] = [main[_fork_index()]]
	for point: Vector2 in bypass:
		bypass_graph.append(point)
	bypass_graph.append(main[_rejoin_index()])
	for index: int in range(bypass_graph.size() - 1):
		_draw_dashed_segment(_to_screen(bypass_graph[index]), _to_screen(bypass_graph[index + 1]), Color(BYPASS_RUST, 0.72), 7.0, 15.0)

	var loop: Array = _route_points[V06CourseModelScript.ROUTE_LOOP]
	var loop_screen := PackedVector2Array()
	for point: Vector2 in loop:
		loop_screen.append(_to_screen(point))
	loop_screen.append(_to_screen(loop[0]))
	draw_polyline(loop_screen, Color(LOOP_TEAL, 0.68), 7.0, true)
	draw_line(_to_screen(main[_portal_index()]), _to_screen(loop[0]), Color(EXIT_GOLD, 0.56), 5.0, true)
	draw_line(_to_screen(loop[4]), _to_screen(main[_loop_return_index()]), Color(EXIT_GOLD, 0.70), 5.0, true)

	var prominent_keys := _prominent_keys()
	var branch_keys := _branch_preview_keys()
	for route_id: String in [V06CourseModelScript.ROUTE_MAIN, V06CourseModelScript.ROUTE_BYPASS, V06CourseModelScript.ROUTE_LOOP]:
		var points: Array = _route_points[route_id]
		for tile_index: int in range(points.size()):
			var is_local := _overview_mode or prominent_keys.has(_position_key(route_id, tile_index)) or branch_keys.has(_position_key(route_id, tile_index))
			_draw_route_tile(route_id, tile_index, _to_screen(points[tile_index]), is_local)
	_draw_boss_gate(_to_screen(main[_boss_index()]))
	var shown_exit_steps := displayed_exit_steps()
	if shown_exit_steps > 0:
		_draw_exit_badge(_to_screen(Vector2(820.0, 340.0)), shown_exit_steps)


func _draw_route_tile(route_id: String, tile_index: int, screen_position: Vector2, prominent: bool) -> void:
	if screen_position.x < -80.0 or screen_position.x > size.x + 80.0 or screen_position.y < -80.0 or screen_position.y > size.y + 80.0:
		return
	var is_current := route_id == str(_current_position.route_id) and tile_index == int(_current_position.tile_index)
	var loop_preview_tile := route_id == V06CourseModelScript.ROUTE_LOOP and _loop_preview_active()
	if not prominent and not loop_preview_tile and not is_current:
		return
	var radius := (CAROUSEL_CONTEXT_RADIUS if _carousel_tile_is_context else carousel_tile_radius(_carousel_tile_is_current)) if uses_semicircle_carousel() else (16.0 if _overview_mode and is_current else (11.0 if _overview_mode else (31.0 if is_current else (15.0 if loop_preview_tile and not prominent else 25.0))))
	# Only the current vicinity rises above the printed atlas. Canonical labels
	# stay runtime-drawn, so the art never owns topology or UI text.
	draw_circle(screen_position + Vector2(0.0, 8.0), radius + (5.0 if is_current else 2.0), Color(0.20, 0.13, 0.07, 0.26 if is_current else 0.18))
	var accent := MAIN_TEAL if route_id == V06CourseModelScript.ROUTE_MAIN else (BYPASS_RUST if route_id == V06CourseModelScript.ROUTE_BYPASS else LOOP_TEAL)
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
	var label := _tile_label(route_id, tile_index)
	var text_color := Color("#fff3d5") if is_current else (Color("#a4947e") if _carousel_tile_is_context else MUTED_INK)
	var label_size := 10 if _overview_mode else (11 if _carousel_tile_is_context else (12 if loop_preview_tile and not prominent else 14))
	draw_string(APP_FONT, screen_position + Vector2(-radius, radius * 0.88), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, label_size, text_color)


func _draw_tile_kind_badge(center: Vector2, tile_radius: float, kind: String, is_current: bool) -> void:
	var spec := tile_visual_spec(kind)
	var badge_radius := kind_badge_radius_for_tile(tile_radius)
	var fill: Color = spec.base_color
	var outline := Color("#f8eccf") if is_current else Color("#514538")
	_draw_kind_shape(center, badge_radius, StringName(spec.shape_id), fill, outline)
	var icon_id := StringName(spec.icon_id)
	var icon_scale := 0.82 if kind == "RISK" else (0.70 if tile_kind_icon_texture(icon_id) != null else 0.58)
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
		if tile_kind_icon_texture(StringName(tile_visual_spec(kind).icon_id)) == null:
			return false
	return true


func tile_kind_glyph_opaque_bound_at_360(kind: String, tile_radius := CAROUSEL_TILE_RADIUS) -> float:
	var icon_id := StringName(tile_visual_spec(kind).icon_id)
	var texture := tile_kind_icon_texture(icon_id)
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
	var grounded_feet := carousel_cat_feet_anchor() if uses_semicircle_carousel() else _to_screen(_cat_world)
	var feet := grounded_feet - Vector2(0.0, _cat_lift)
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
	draw_arc(Vector2(266, 31), 12.0, 0.0, TAU, 20, LOOP_TEAL, 5.0, true)


func _draw_exit_badge(center: Vector2, steps: int) -> void:
	var rect := Rect2(center - Vector2(63, 25), Vector2(126, 50))
	draw_style_box(_panel_style(Color("#f3e4bf"), EXIT_GOLD, 10), rect)
	draw_string(APP_FONT, rect.position + Vector2(0, 33), "EXIT %d" % steps, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color("#3b6d6e"))


func _draw_boss_gate(center: Vector2) -> void:
	if center.x < -100.0 or center.x > size.x + 100.0 or center.y < -140.0 or center.y > size.y + 100.0:
		return
	var gate_scale := 0.48 if not _overview_mode else 0.24
	var gate_size := BOSS_GATE_CELL_SIZE * gate_scale
	var gate_anchor := BOSS_GATE_ANCHOR * gate_scale
	var gate_source := Rect2(Vector2(float(boss_gate_cell()) * BOSS_GATE_CELL_SIZE.x, 0.0), BOSS_GATE_CELL_SIZE)
	draw_texture_rect_region(GOLD_BOSS_GATE, Rect2(center - gate_anchor, gate_size), gate_source)


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
	var focus := Vector2(size.x * 0.43, size.y * 0.56)
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
	if route_id != V06CourseModelScript.ROUTE_MAIN or tile_index < _fork_index() - 2 or tile_index > _fork_index():
		return keys
	for branch_index: int in range(_route_size(V06CourseModelScript.ROUTE_BYPASS)):
		keys[_position_key(V06CourseModelScript.ROUTE_BYPASS, branch_index)] = true
	return keys


func _route_size(route_id: String) -> int:
	if _route_points.has(route_id):
		return (_route_points[route_id] as Array).size()
	var routes: Dictionary = _definition.get("routes", {})
	return routes[route_id].size() if routes.has(route_id) and routes[route_id] is Array else 0


func _fork_index() -> int:
	var bypass: Dictionary = _definition.get("bypass", {})
	var choice: Dictionary = bypass.get("choice", {}) if bypass.get("choice", {}) is Dictionary else {}
	return int(choice.get("tile_index", 12))


func _rejoin_index() -> int:
	var bypass: Dictionary = _definition.get("bypass", {})
	var rejoin: Dictionary = bypass.get("rejoin", {}) if bypass.get("rejoin", {}) is Dictionary else {}
	return int(rejoin.get("tile_index", 20))


func _portal_index() -> int:
	var loop: Dictionary = _definition.get("loop", {})
	var portal: Dictionary = loop.get("portal", {}) if loop.get("portal", {}) is Dictionary else {}
	return int(portal.get("tile_index", 22))


func _loop_return_index() -> int:
	var loop: Dictionary = _definition.get("loop", {})
	var returned: Dictionary = loop.get("return", {}) if loop.get("return", {}) is Dictionary else {}
	return int(returned.get("tile_index", 23))


func _boss_index() -> int:
	return _route_size(V06CourseModelScript.ROUTE_MAIN) - 1


func _position_key(route_id: String, tile_index: int) -> String:
	return "%s:%d" % [route_id, tile_index]


func _loop_preview_active() -> bool:
	return false


func _tile_label(route_id: String, tile_index: int) -> String:
	if route_id == V06CourseModelScript.ROUTE_MAIN:
		return str(tile_index + 1)
	if route_id == V06CourseModelScript.ROUTE_BYPASS:
		return "B%d" % (tile_index + 1)
	return str(tile_index + 1)


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
