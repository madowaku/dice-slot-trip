class_name BoardView
extends Control

const APP_FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")

const TILE_COUNT: int = 90
const LANDMARK_IDS_BY_TILE: Dictionary = {
	0: "CAI_LANDMARK_01",
	22: "CAI_LANDMARK_02",
	54: "CAI_LANDMARK_03",
}
const INK: Color = Color("#5c4938")
const SAND: Color = Color("#ead8b5")
const PLAYER_TEXTURE: Texture2D = preload("res://assets/art/characters/relaxed-traveler.png")
const BYPASS_ROCKS: Texture2D = preload("res://assets/art/map_props/kenney_sketch_desert/rocks_N.png")
const BYPASS_WALL: Texture2D = preload("res://assets/art/map_props/kenney_sketch_desert/walls_broken_N.png")
const BYPASS_TREE: Texture2D = preload("res://assets/art/map_props/kenney_sketch_desert/tree_S.png")
const LandmarkScenicViewScript = preload("res://scripts/game/landmark_scenic_view.gd")
const TILE_COLORS: Dictionary = {
	&"NORMAL": Color("#f2e5c9"),
	&"EVENT": Color("#d99572"),
	&"ITEM": Color("#a798c6"),
	&"COIN": Color("#d8b45b"),
	&"WARP": Color("#6aa9b2"),
	&"SHOP": Color("#b87f61"),
	&"REST": Color("#8fb39a"),
	&"LANDMARK": Color("#d4a446"),
	&"BOSS_SCENT": Color("#8b91b7"),
	&"STAGE_SPECIAL": Color("#4f9b98"),
	&"RISK": Color("#c76552"),
	&"STRONG_RISK": Color("#883b35"),
	&"GAMBLE": Color("#cf7b3f"),
	&"RETURN_GATE": Color("#d3aa50"),
	&"TREASURE": Color("#c99742"),
	&"ANCIENT_ITEM": Color("#5c9c91"),
	&"MURAL": Color("#9276a9"),
}

var tile_types: Array[StringName] = []
var current_tile: int = 0
var current_route_id: String = "main"
var current_route_tile_count: int = TILE_COUNT
var current_route_tiles: Array = []
var route_flow_level: int = 0
var route: Path2D
var positions: Array[Vector2] = []
var is_minimap: bool = false
var landmark_levels: Dictionary = {}
var scenic_texture: Texture2D
var scenic_level: int = -1
var movement_hop_offset_y: float = 0.0
var bypass_revealed_tiles: Array[int] = []
var bypass_reveal_tile: int = -1
var bypass_reveal_progress: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_rebuild_route)
	_rebuild_route()
	_refresh_scenic()

func configure(types: Array[StringName], tile_index: int, levels: Dictionary = {}) -> void:
	tile_types = types
	current_tile = tile_index
	landmark_levels = levels.duplicate(true)
	_refresh_scenic()
	queue_redraw()

func set_current_tile(value: int) -> void:
	current_tile = posmod(value, current_route_tile_count)
	_refresh_scenic()
	queue_redraw()

func set_route_context(route_id: String, tile_count: int, route_tiles: Array = []) -> void:
	current_route_id = route_id
	current_route_tile_count = maxi(1, tile_count)
	current_route_tiles = route_tiles.duplicate()
	current_tile = posmod(current_tile, current_route_tile_count)
	_refresh_scenic()
	queue_redraw()

func set_route_flow_level(level: int) -> void:
	route_flow_level = clampi(level, 0, 5)
	queue_redraw()

static func hop_offset_for_progress(progress: float, height: float = 14.0) -> float:
	return -sin(clampf(progress, 0.0, 1.0) * PI) * maxf(0.0, height)

func set_movement_hop_progress(progress: float) -> void:
	movement_hop_offset_y = hop_offset_for_progress(progress)
	queue_redraw()

func set_bypass_revealed_tiles(revealed_tiles: Array) -> void:
	bypass_revealed_tiles.clear()
	for value: Variant in revealed_tiles:
		var index := int(value)
		if index not in bypass_revealed_tiles:
			bypass_revealed_tiles.append(index)
	queue_redraw()

func set_bypass_reveal_progress(tile_index: int, progress: float) -> void:
	bypass_reveal_tile = tile_index
	bypass_reveal_progress = clampf(progress, 0.0, 1.0)
	if bypass_reveal_progress >= 1.0:
		bypass_reveal_tile = -1
	queue_redraw()

static func bypass_tile_is_public(tile_index: int, tile_count: int, revealed_tiles: Array) -> bool:
	var count := maxi(2, tile_count)
	var normalized := posmod(tile_index, count)
	return normalized == 0 or normalized == count - 1 or normalized in revealed_tiles

static func bypass_display_type(tile_index: int, tile_count: int, tile_type: StringName, revealed_tiles: Array) -> StringName:
	return tile_type if bypass_tile_is_public(tile_index, tile_count, revealed_tiles) else &"SECRET"

func set_landmark_levels(levels: Dictionary) -> void:
	landmark_levels = levels.duplicate(true)
	_refresh_scenic()
	queue_redraw()

func _rebuild_route() -> void:
	if route == null:
		route = Path2D.new()
		route.name = "LoopRoute"
		add_child(route)
	var curve := Curve2D.new()
	var center := size * 0.5
	var radius := Vector2(maxf(120.0, size.x * 0.43), maxf(150.0, size.y * 0.40))
	if is_minimap:
		radius = Vector2(maxf(12.0, size.x * 0.39), maxf(10.0, size.y * 0.35))
	for segment: int in range(17):
		var angle := TAU * float(segment) / 16.0
		var ripple := 1.0 + sin(angle * 3.0) * 0.055
		curve.add_point(center + Vector2(cos(angle), sin(angle)) * radius * ripple)
	curve.bake_interval = 6.0
	route.curve = curve
	positions.clear()
	var length := curve.get_baked_length()
	for index: int in range(TILE_COUNT):
		positions.append(curve.sample_baked(length * float(index) / float(TILE_COUNT)))
	queue_redraw()

func _refresh_scenic() -> void:
	# T005 ships the MARKET district first. Other districts keep the original
	# parchment until their own landmark art is available.
	var distance_to_market := mini(absi(current_tile), TILE_COUNT - absi(current_tile))
	var shows_spice_market := not is_minimap and distance_to_market <= 5
	scenic_level = _landmark_level(0) if shows_spice_market else -1
	scenic_texture = LandmarkScenicViewScript.texture_for_level(scenic_level) if shows_spice_market else null
	queue_redraw()

func _draw() -> void:
	if positions.size() != TILE_COUNT:
		return
	if is_minimap:
		_draw_minimap()
		return
	if current_route_id == "bypass_caravan":
		_draw_bypass_neighborhood()
		return
	if current_route_id == "loop_royal_maze":
		_draw_royal_maze()
		return
	_draw_zoomed_neighborhood()

func _draw_bypass_neighborhood() -> void:
	draw_style_box(_board_panel(), Rect2(Vector2.ZERO, size))
	# Sand haze and sparse Kenney props turn the route into a place without
	# sacrificing the full ten-tile read at phone size.
	for band: int in range(5):
		var band_rect := Rect2(12.0, 48.0 + float(band) * (size.y - 64.0) / 5.0, size.x - 24.0, (size.y - 64.0) / 5.0 + 2.0)
		draw_rect(band_rect, Color(0.73, 0.46, 0.25, 0.025 + float(band) * 0.012))
	draw_texture_rect(BYPASS_ROCKS, Rect2(size.x * 0.08, size.y * 0.38, 42, 50), false, Color(0.88, 0.70, 0.52, 0.62))
	draw_texture_rect(BYPASS_WALL, Rect2(size.x * 0.67, size.y * 0.28, 54, 58), false, Color(0.88, 0.73, 0.55, 0.58))
	draw_texture_rect(BYPASS_TREE, Rect2(size.x * 0.43, size.y * 0.57, 42, 52), false, Color(0.82, 0.67, 0.48, 0.48))
	draw_string(APP_FONT, Vector2(18, 36), "砂嵐のキャラバン道", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTokensScript.FONT_MAP_HEADING, Color("#6b392d"))
	draw_string(APP_FONT, Vector2(size.x - 150, 35), "危険 7 / 10", HORIZONTAL_ALIGNMENT_RIGHT, 132, UiTokensScript.FONT_MAP_CAPTION, Color("#a23f34"))
	var distance_left := bypass_exit_distance(current_tile, current_route_tile_count)
	draw_string(APP_FONT, Vector2(18, 67), "現在 %d / %d　出口まで %d  →" % [current_tile + 1, current_route_tile_count, distance_left], HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, UiTokensScript.FONT_MAP_CAPTION, Color("#7a4a31"))
	var count := maxi(1, current_route_tile_count)
	var points := bypass_route_points(size, count)
	# A broad sand road, two ruts and a dark lee edge read as terrain rather
	# than a graph connection line.
	draw_polyline(points, Color(0.29, 0.16, 0.09, 0.32), 27.0, true)
	draw_polyline(points, Color("#d3a66a"), 22.0, true)
	draw_polyline(points, Color("#e7c78f"), 15.0, true)
	var upper_rut := PackedVector2Array(); var lower_rut := PackedVector2Array()
	for point: Vector2 in points:
		upper_rut.append(point + Vector2(0, -4)); lower_rut.append(point + Vector2(0, 4))
	draw_polyline(upper_rut, Color(0.46, 0.25, 0.13, 0.42), 1.6, true)
	draw_polyline(lower_rut, Color(0.46, 0.25, 0.13, 0.34), 1.4, true)
	# Embedded chevrons make left-to-right travel unambiguous even before the
	# player learns the numbering convention.
	for segment: int in range(1, count - 1, 2):
		_draw_direction_chevron(points[segment - 1].lerp(points[segment], 0.55), points[segment] - points[segment - 1], Color(0.55, 0.22, 0.13, 0.72), 7.0)
	_draw_bypass_flow_wind(points)
	for index: int in range(count):
		var tile_type := StringName(current_route_tiles[index]) if index < current_route_tiles.size() else &"NORMAL"
		var radius := 19.0 if index == current_tile else (18.0 if index == count - 1 else 16.0)
		var is_revealing := index == bypass_reveal_tile and bypass_reveal_progress < 1.0
		var reveal_amount := bypass_reveal_progress if is_revealing else (1.0 if bypass_tile_is_public(index, count, bypass_revealed_tiles) else 0.0)
		var true_fill := Color(TILE_COLORS.get(tile_type, SAND))
		var fill := Color("#967047").lerp(true_fill, reveal_amount)
		if tile_type == &"RISK" and reveal_amount > 0.0:
			draw_circle(points[index], radius + 8.0, Color(0.76, 0.16, 0.10, 0.24 * reveal_amount))
		if tile_type == &"STRONG_RISK" and reveal_amount > 0.0:
			draw_circle(points[index], radius + 10.0, Color(0.18, 0.07, 0.05, 0.32 * reveal_amount))
			draw_arc(points[index], radius + 6.0, 0, TAU, 20, Color(0.55, 0.12, 0.09, 0.68 * reveal_amount), 3.0, true)
		draw_circle(points[index], radius, Color("#2f8588") if index == current_tile else fill)
		draw_arc(points[index], radius, 0, TAU, 24, Color("#f1c86a") if index == current_tile else Color("#6a3b2c"), 3.0, true)
		var mark := _tile_mark(tile_type)
		if reveal_amount < 1.0:
			draw_string(APP_FONT, points[index] + Vector2(-radius, -radius - 3), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, UiTokensScript.FONT_MAP_DETAIL, Color(0.35, 0.20, 0.12, 0.78))
			draw_string(APP_FONT, points[index] + Vector2(-radius, 7), "?", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 21, Color(0.96, 0.87, 0.69, 0.90 * (1.0 - reveal_amount)))
			var veil_alpha := 0.30 * (1.0 - reveal_amount)
			draw_circle(points[index] + Vector2(-9.0 - reveal_amount * 12.0, -4), radius * 0.72, Color(0.90, 0.73, 0.49, veil_alpha))
			draw_circle(points[index] + Vector2(9.0 + reveal_amount * 12.0, 3), radius * 0.62, Color(0.76, 0.56, 0.34, veil_alpha))
		else:
			var number_y := -1.0 if not mark.is_empty() else 5.0
			draw_string(APP_FONT, points[index] + Vector2(-radius, number_y), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, UiTokensScript.FONT_MAP_DETAIL, Color.WHITE if index == current_tile or tile_type in [&"RISK", &"STRONG_RISK"] else INK)
		if not mark.is_empty() and reveal_amount > 0.0:
			draw_string(APP_FONT, points[index] + Vector2(-radius, 18), mark, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, UiTokensScript.FONT_MAP_CAPTION, Color(0.42, 0.22, 0.14, reveal_amount))
		if reveal_amount >= 1.0 and index > 0 and index < count - 1:
			draw_circle(points[index] + Vector2(-5, radius + 6), 2.0, Color(0.35, 0.20, 0.11, 0.34))
			draw_circle(points[index] + Vector2(4, radius + 9), 1.7, Color(0.35, 0.20, 0.11, 0.28))
		if index == count - 1:
			_draw_exit_gate(points[index], radius)
	var token := points[current_tile]
	draw_texture_rect(PLAYER_TEXTURE, Rect2(token - Vector2(30, 85) + Vector2(0, movement_hop_offset_y), Vector2(60, 80)), false)
	if current_tile < count - 1:
		_draw_direction_chevron(token.lerp(points[current_tile + 1], 0.55), points[current_tile + 1] - token, Color("#f5d06d"), 10.0)
	draw_string(APP_FONT, Vector2(12, size.y - 20), "入口　分岐", HORIZONTAL_ALIGNMENT_LEFT, 120, UiTokensScript.FONT_MAP_CAPTION, Color("#7c583c"))
	draw_string(APP_FONT, Vector2(size.x - 160, size.y - 20), "EXIT　本線へ合流", HORIZONTAL_ALIGNMENT_RIGHT, 148, UiTokensScript.FONT_MAP_CAPTION, Color("#8d392f"))

static func bypass_exit_distance(tile_index: int, tile_count: int = 10) -> int:
	return maxi(0, maxi(1, tile_count) - (posmod(tile_index, maxi(1, tile_count)) + 1))

static func bypass_route_points(view_size: Vector2, count: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_count := maxi(2, count)
	for index: int in range(safe_count):
		var t := float(index) / float(safe_count - 1)
		var x := lerpf(28.0, view_size.x - 30.0, t)
		var ridge := sin(t * PI) * -54.0 + sin(t * TAU * 2.0) * 13.0
		points.append(Vector2(x, view_size.y * 0.67 + ridge))
	return points

func _draw_direction_chevron(center: Vector2, direction: Vector2, color: Color, scale: float) -> void:
	var forward := direction.normalized()
	if forward == Vector2.ZERO: forward = Vector2.RIGHT
	var side := Vector2(-forward.y, forward.x)
	var triangle := PackedVector2Array([center + forward * scale, center - forward * scale * 0.75 + side * scale * 0.62, center - forward * scale * 0.75 - side * scale * 0.62])
	draw_colored_polygon(triangle, color)

func _draw_exit_gate(center: Vector2, radius: float) -> void:
	var gate_color := Color("#8e4934")
	draw_line(center + Vector2(-radius - 2, 5), center + Vector2(-radius - 2, -radius - 15), gate_color, 4.0, true)
	draw_line(center + Vector2(radius + 2, 5), center + Vector2(radius + 2, -radius - 15), gate_color, 4.0, true)
	draw_arc(center + Vector2(0, -radius - 13), radius + 4, PI, TAU, 18, Color("#d29c4b"), 5.0, true)
	var pole_top := center + Vector2(-radius - 2, -radius - 34)
	draw_line(center + Vector2(-radius - 2, -radius - 8), pole_top, Color("#72513a"), 2.5, true)
	draw_colored_polygon(PackedVector2Array([pole_top, pole_top + Vector2(18, 5), pole_top + Vector2(0, 12)]), Color("#c94f3e"))
	draw_string(APP_FONT, center + Vector2(-30, -radius - 25), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, 60, 14, Color("#8d392f"))

func _draw_bypass_flow_wind(points: PackedVector2Array) -> void:
	if route_flow_level <= 0 or points.size() < 2:
		return
	var streak_count := 2 + route_flow_level
	for index: int in range(streak_count):
		var t := fposmod(float(index) * 0.19 + float(route_flow_level) * 0.07, 0.88)
		var slot := mini(points.size() - 2, floori(t * float(points.size() - 1)))
		var local_t := fposmod(t * float(points.size() - 1), 1.0)
		var start := points[slot].lerp(points[slot + 1], local_t) + Vector2(0, -22.0 - float(index % 3) * 7.0)
		var direction := (points[slot + 1] - points[slot]).normalized()
		var length := 12.0 + float(route_flow_level) * 4.0
		draw_line(start, start + direction * length, Color(0.95, 0.78, 0.42, 0.20 + float(route_flow_level) * 0.07), 1.5 + float(route_flow_level) * 0.18, true)

func _draw_royal_maze() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#24201f")
	panel.border_color = Color("#9a7338")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(18)
	panel.shadow_color = Color(0.05, 0.03, 0.02, 0.65)
	panel.shadow_size = 10
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	# Stone courses and Kenney fragments keep the chamber tactile while the
	# eight-stop topology remains fully visible.
	for row: int in range(7):
		var y := 52.0 + float(row) * (size.y - 64.0) / 7.0
		draw_line(Vector2(12, y), Vector2(size.x - 12, y), Color(0.78, 0.62, 0.39, 0.07), 1.0, true)
	draw_texture_rect(BYPASS_WALL, Rect2(20, size.y * 0.54, 68, 72), false, Color(0.38, 0.34, 0.30, 0.72))
	draw_texture_rect(BYPASS_ROCKS, Rect2(size.x - 86, size.y * 0.46, 62, 72), false, Color(0.35, 0.31, 0.28, 0.70))
	draw_string(APP_FONT, Vector2(18, 36), "王の迷い環", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTokensScript.FONT_MAP_HEADING, Color("#f0d38a"))
	var gate_distance := posmod(-current_tile, maxi(1, current_route_tile_count))
	draw_string(APP_FONT, Vector2(18, 67), "帰還まで %d　時計回り →" % gate_distance, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, UiTokensScript.FONT_MAP_CAPTION, Color("#c9b48b"))
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	var radius := Vector2(size.x * 0.32, size.y * 0.30)
	var points := PackedVector2Array()
	for index: int in range(maxi(1, current_route_tile_count)):
		var angle := -PI * 0.5 + TAU * float(index) / float(maxi(1, current_route_tile_count))
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	var ring := points.duplicate(); ring.append(points[0])
	draw_polyline(ring, Color(0.04, 0.03, 0.03, 0.72), 28.0, true)
	draw_polyline(ring, Color("#55483b"), 21.0, true)
	draw_polyline(ring, Color("#746044"), 4.0, true)
	for direction_index: int in [1, 3, 5, 7]:
		_draw_direction_chevron(points[direction_index - 1].lerp(points[direction_index], 0.5), points[direction_index] - points[direction_index - 1], Color(0.84, 0.65, 0.28, 0.60), 6.0)
	for index: int in range(points.size()):
		var tile_type := StringName(current_route_tiles[index]) if index < current_route_tiles.size() else &"NORMAL"
		var tile_radius := 20.0 if index == current_tile else (25.0 if tile_type == &"RETURN_GATE" else 16.0)
		if tile_type == &"RISK": draw_circle(points[index], tile_radius + 7.0, Color(0.68, 0.13, 0.10, 0.20))
		if tile_type == &"STRONG_RISK":
			draw_circle(points[index], tile_radius + 12.0, Color(0.02, 0.01, 0.01, 0.78))
			draw_arc(points[index], tile_radius + 8.0, 0, TAU, 24, Color(0.48, 0.10, 0.10, 0.62), 3.0, true)
		if tile_type == &"TREASURE":
			draw_circle(points[index], tile_radius + 10.0, Color(0.96, 0.68, 0.18, 0.14))
			draw_circle(points[index], tile_radius + 5.0, Color(0.96, 0.78, 0.31, 0.12))
		if tile_type == &"MURAL":
			draw_circle(points[index], tile_radius + 9.0, Color(0.39, 0.28, 0.68, 0.20))
			draw_arc(points[index], tile_radius + 6.0, -PI * 0.75, PI * 0.25, 18, Color(0.55, 0.72, 0.91, 0.58), 2.0, true)
		if tile_type == &"RETURN_GATE":
			draw_circle(points[index], tile_radius + 15.0, Color(0.96, 0.73, 0.24, 0.10 + route_flow_level * 0.018))
			draw_circle(points[index], tile_radius + 8.0, Color(0.96, 0.80, 0.40, 0.10))
		var fill := Color("#287b80") if index == current_tile else Color(TILE_COLORS.get(tile_type, Color("#77634a")))
		draw_circle(points[index], tile_radius, fill)
		draw_arc(points[index], tile_radius, 0, TAU, 24, Color("#f1c86a") if index == current_tile or tile_type == &"RETURN_GATE" else Color("#b28b51"), 3.0, true)
		draw_string(APP_FONT, points[index] + Vector2(-tile_radius, 5), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, tile_radius * 2.0, UiTokensScript.FONT_MAP_DETAIL, Color.WHITE)
		var mark := _tile_mark(tile_type)
		if not mark.is_empty(): draw_string(APP_FONT, points[index] + Vector2(-tile_radius, 28), mark, HORIZONTAL_ALIGNMENT_CENTER, tile_radius * 2.0, UiTokensScript.FONT_MAP_CAPTION, Color("#e8cb84"))
		if tile_type == &"RETURN_GATE": _draw_return_gate_marker(points[index], tile_radius)
	if route_flow_level > 0:
		for flow_index: int in range(route_flow_level + 1):
			var angle := -PI * 0.5 + TAU * float(flow_index) / float(route_flow_level + 1)
			var start := center + Vector2(cos(angle) * radius.x * 0.72, sin(angle) * radius.y * 0.72)
			draw_line(start, start + Vector2(-sin(angle), cos(angle)) * (10.0 + route_flow_level * 4.0), Color(0.96, 0.73, 0.25, 0.16 + route_flow_level * 0.07), 2.0, true)
	var token := points[current_tile]
	draw_texture_rect(PLAYER_TEXTURE, Rect2(token - Vector2(31, 86) + Vector2(0, movement_hop_offset_y), Vector2(62, 82)), false, Color(0.92, 0.84, 0.67, 1.0))
	# Two fixed torch pairs frame the chamber; higher FLOW brightens their halo.
	for torch_x: float in [size.x * 0.14, size.x * 0.86]:
		var torch := Vector2(torch_x, size.y * 0.29)
		draw_circle(torch, 10.0 + route_flow_level * 1.4, Color(0.94, 0.50, 0.16, 0.10 + route_flow_level * 0.035))
		draw_circle(torch, 4.0, Color("#f3a83d"))

func _draw_return_gate_marker(center: Vector2, radius: float) -> void:
	var stone := Color("#3a3029")
	var light := Color("#f2cf70")
	var top := center + Vector2(0, -radius - 9.0)
	draw_line(top + Vector2(-10, 10), top + Vector2(-10, -1), stone, 4.0, true)
	draw_line(top + Vector2(10, 10), top + Vector2(10, -1), stone, 4.0, true)
	draw_arc(top, 10.0, PI, TAU, 16, light, 3.0, true)
	draw_string(APP_FONT, center + Vector2(-45, radius + 28), "帰還扉", HORIZONTAL_ALIGNMENT_CENTER, 90, UiTokensScript.FONT_MAP_CAPTION, light)


func _draw_zoomed_neighborhood() -> void:
	# The neighborhood is a legible board ribbon, not a magnified dotted map.
	# The full 90-tile topology remains in the independent minimap.
	draw_style_box(_board_panel(), Rect2(Vector2.ZERO, size))
	if scenic_texture != null:
		var slot_width := maxf(1.0, size.x - 44.0)
		var slot_height := minf(slot_width * 0.5, maxf(1.0, size.y * 0.72))
		draw_texture_rect(scenic_texture, Rect2(22.0, 42.0, slot_width, slot_height), false, Color(1.0, 0.98, 0.91, 0.94))
	draw_string(APP_FONT, Vector2(22, 40), "現在地周辺  %02d / 90" % (current_tile + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTokensScript.FONT_MAP_HEADING, INK)
	var district_names := ["市場", "ピラミッド", "オアシス", "遺跡", "砂丘"]
	draw_string(APP_FONT, Vector2(size.x - 170, 40), district_names[current_tile / 18], HORIZONTAL_ALIGNMENT_RIGHT, 148, UiTokensScript.FONT_MAP_CAPTION, Color("#846c50"))
	if scenic_level >= 0:
		draw_string(APP_FONT, Vector2(size.x * 0.5 - 150.0, 74.0), "香辛料市場通り　Lv.%d" % scenic_level, HORIZONTAL_ALIGNMENT_CENTER, 300.0, UiTokensScript.FONT_MAP_CAPTION, Color("#6f5030"))
	var shown_each_side := 5
	var tile_width := maxf(48.0, (size.x - 34.0) / 11.0)
	var tile_height := minf(106.0, maxf(78.0, size.y * 0.28))
	var center_y := size.y * 0.58
	for offset: int in range(-shown_each_side, shown_each_side + 1):
		var index := posmod(current_tile + offset, TILE_COUNT)
		var tile_type: StringName = tile_types[index] if index < tile_types.size() else &"NORMAL"
		var x := size.x * 0.5 + float(offset) * tile_width - tile_width * 0.5
		var y := center_y + absf(float(offset)) * 4.2 - tile_height * 0.5
		var rect := Rect2(x + 2, y, tile_width - 4, tile_height)
		var tile_style := _ribbon_tile_style(tile_type, offset == 0, offset == 1)
		draw_style_box(tile_style, rect)
		var number_color := Color.WHITE if offset == 0 or tile_type == &"RISK" else INK
		draw_string(APP_FONT, rect.position + Vector2(0, 30), "%02d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTokensScript.FONT_MAP_CAPTION, number_color)
		var mark := _tile_mark(tile_type)
		if not mark.is_empty(): draw_string(APP_FONT, rect.position + Vector2(0, 62), mark, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTokensScript.FONT_MAP_HEADING, number_color)
		if tile_type == &"LANDMARK":
			var landmark_level := _landmark_level(index)
			draw_string(APP_FONT, rect.position + Vector2(0, 82), "Lv.%d" % landmark_level, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTokensScript.FONT_MAP_DETAIL, number_color)
		if offset == 1: draw_string(APP_FONT, rect.position + Vector2(0, rect.size.y - 10), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTokensScript.FONT_MAP_DETAIL, Color("#fff4dc") if tile_type == &"RISK" else Color("#356b6d"))
	# Direction and token stay centered while the ribbon moves beneath them.
	var center_rect_x := size.x * 0.5 - tile_width * 0.5
	draw_circle(Vector2(size.x * 0.5, center_y + tile_height * 0.5 + 12), 23, Color("#277c80"))
	draw_arc(Vector2(size.x * 0.5, center_y + tile_height * 0.5 + 12), 23, 0, TAU, 24, Color("#ffe5a4"), 4, true)
	draw_texture_rect(PLAYER_TEXTURE, Rect2(Vector2(size.x * 0.5 - 40, center_y - tile_height * 0.5 - 94 + movement_hop_offset_y), Vector2(80, 108)), false)
	draw_string(APP_FONT, Vector2(center_rect_x + tile_width, center_y - tile_height * 0.5 - 12), "▶", HORIZONTAL_ALIGNMENT_CENTER, tile_width, 22, Color("#7d5f36"))

func _draw_minimap() -> void:
	if current_route_id == "loop_royal_maze":
		_draw_maze_minimap()
		return
	if current_route_id == "bypass_caravan":
		_draw_bypass_minimap()
		return
	draw_style_box(_mini_panel(), Rect2(Vector2.ZERO, size))
	_draw_route(false)

func _draw_bypass_minimap() -> void:
	draw_style_box(_mini_panel(), Rect2(Vector2.ZERO, size))
	var points := PackedVector2Array()
	var count := maxi(2, current_route_tile_count)
	for index: int in range(count):
		var t := float(index) / float(count - 1)
		points.append(Vector2(12.0 + t * (size.x - 24.0), size.y * 0.55 + sin(t * PI * 2.0) * 7.0))
	draw_polyline(points, Color("#6f3b2c"), 7.0, true)
	for index: int in range(points.size()):
		var tile_type := StringName(current_route_tiles[index]) if index < current_route_tiles.size() else &"NORMAL"
		var public := bypass_tile_is_public(index, current_route_tile_count, bypass_revealed_tiles)
		var fill := Color(TILE_COLORS.get(tile_type, SAND)) if public else Color("#967047")
		draw_circle(points[index], 4.5 if index != current_tile else 7.0, Color("#287b80") if index == current_tile else fill)

func _draw_maze_minimap() -> void:
	var panel := _mini_panel(); panel.bg_color = Color("#292421"); panel.border_color = Color("#9a7338")
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	var center := size * 0.5
	var radius := Vector2(size.x * 0.34, size.y * 0.32)
	var points := PackedVector2Array()
	for index: int in range(current_route_tile_count):
		var angle := -PI * 0.5 + TAU * float(index) / float(current_route_tile_count)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	var ring := points.duplicate(); ring.append(points[0])
	draw_polyline(ring, Color("#756044"), 4.0, true)
	for index: int in range(points.size()):
		var tile_type := StringName(current_route_tiles[index]) if index < current_route_tiles.size() else &"NORMAL"
		if tile_type == &"RETURN_GATE": draw_circle(points[index], 9.0, Color(0.95, 0.73, 0.27, 0.24))
		draw_circle(points[index], 6.0 if tile_type == &"RETURN_GATE" else (4.5 if index != current_tile else 7.0), Color("#287b80") if index == current_tile else Color(TILE_COLORS.get(tile_type, Color("#77634a"))))

func _draw_route(show_token_art: bool) -> void:
	var path := PackedVector2Array(positions)
	path.append(positions[0])
	var route_width := 9.0 if show_token_art else 3.0
	draw_polyline(path, Color("#8c7254"), route_width, true)
	draw_polyline(path, Color("#f3e6c7"), maxf(1.5, route_width * 0.56), true)
	for index: int in range(TILE_COUNT):
		var tile_type: StringName = tile_types[index] if index < tile_types.size() else &"NORMAL"
		var tile_radius := (6.0 if tile_type == &"NORMAL" else 8.0) if show_token_art else (2.3 if tile_type == &"NORMAL" else 3.4)
		draw_circle(positions[index], tile_radius, TILE_COLORS.get(tile_type, SAND))
		if tile_type == &"LANDMARK":
			var landmark_level := _landmark_level(index)
			var pip_y := 7.0 if not show_token_art else 13.0
			for pip: int in range(3):
				var pip_color := Color("#d6aa4d") if pip < landmark_level else Color(0.35, 0.29, 0.22, 0.34)
				draw_circle(positions[index] + Vector2(float(pip - 1) * 3.4, pip_y), 1.25 if not show_token_art else 2.0, pip_color)
		if tile_type != &"NORMAL" and show_token_art:
			draw_arc(positions[index], tile_radius, 0.0, TAU, 14, INK, 1.2, true)
			if tile_type == &"BOSS_SCENT":
				# A tiny three-toe footprint makes the low-saturation scent tile recognizable without text.
				for offset: Vector2 in [Vector2(-2, -1), Vector2(0, -3), Vector2(2, -1)]:
					draw_circle(positions[index] + offset, 1.4, INK)
			elif tile_type == &"RISK":
				# High-contrast warning mark remains legible in the zoom view while
				# the red tile itself carries the same warning on the minimap.
				draw_line(positions[index] + Vector2(0, -4), positions[index] + Vector2(0, 1), Color("#fff4dc"), 1.8, true)
				draw_circle(positions[index] + Vector2(0, 4), 1.2, Color("#fff4dc"))
			elif tile_type == &"STAGE_SPECIAL":
				for direction: Vector2 in [Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)]:
					draw_line(positions[index], positions[index] + direction, Color("#fff4dc"), 1.4, true)
	var player_pos := positions[current_tile]
	if show_token_art:
		draw_circle(player_pos + Vector2(0, 6), 16.0, Color("#3b8b91"))
		draw_arc(player_pos + Vector2(0, 6), 16.0, 0.0, TAU, 24, Color("#fff2ce"), 3.0, true)
		draw_texture_rect(PLAYER_TEXTURE, Rect2(player_pos - Vector2(24, 55) + Vector2(0, movement_hop_offset_y), Vector2(48, 64)), false)
	else:
		draw_circle(player_pos, 6.0, Color("#287b80"))
		draw_arc(player_pos, 6.0, 0.0, TAU, 18, Color("#fff2ce"), 1.5, true)

func _mini_panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.97, 0.92, 0.81, 0.88)
	panel.border_color = Color("#8c7254")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	return panel

func _board_panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.96, 0.88, 0.72, 0.76 if scenic_level >= 0 else 0.82)
	panel.border_color = Color("#a67d43")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(18)
	panel.shadow_color = Color(0.19, 0.12, 0.06, 0.24)
	panel.shadow_size = 8
	return panel

func _ribbon_tile_style(tile_type: StringName, is_current: bool, is_next: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(TILE_COLORS.get(tile_type, SAND))
	if tile_type == &"NORMAL": style.bg_color = Color("#f8ebcd")
	style.border_color = Color("#5c4938") if not is_next else Color("#287b80")
	style.set_border_width_all(4 if is_current else (3 if is_next else 2))
	style.set_corner_radius_all(11)
	if is_current:
		style.bg_color = Color("#2f8588")
		style.border_color = Color("#f1c86a")
		style.shadow_color = Color(0.12, 0.08, 0.04, 0.3)
		style.shadow_size = 7
	return style

func _tile_mark(tile_type: StringName) -> String:
	match tile_type:
		&"EVENT": return "?"
		&"ITEM": return "◆"
		&"COIN": return "●"
		&"WARP": return "↻"
		&"SHOP": return "店"
		&"REST": return "☕"
		&"LANDMARK": return "★"
		&"BOSS_SCENT": return "足"
		&"STAGE_SPECIAL": return "✦"
		&"RISK": return "!"
		&"STRONG_RISK": return "!!"
		&"GAMBLE": return "?"
		&"RETURN_GATE": return "扉"
		&"TREASURE": return "宝"
		&"ANCIENT_ITEM": return "王"
		&"MURAL": return "画"
	return ""

func _landmark_level(tile_index: int) -> int:
	var landmark_id := str(LANDMARK_IDS_BY_TILE.get(tile_index, ""))
	return clampi(int(landmark_levels.get(landmark_id, 0)), 0, 3)
