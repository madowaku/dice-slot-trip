class_name TourismMapView
extends "res://scripts/game/board_view.gd"

const VIEW_MODE_CLASSIC := "classic"
const VIEW_MODE_TOURISM := "tourism"
const FIRST_OFFSET := -4
const LAST_OFFSET := 10
const SLOT_COUNT := 15
const REACHABLE_SPECIAL_TYPES: Array[StringName] = [
	&"EVENT", &"ITEM", &"COIN", &"WARP", &"SHOP", &"REST", &"LANDMARK",
	&"BOSS_SCENT", &"STAGE_SPECIAL", &"RISK",
]
const MARKET_PROP_TEXTURES: Dictionary = {
	"rocks_n": preload("res://assets/art/map_props/kenney_sketch_desert/rocks_N.png"),
	"rocks_s": preload("res://assets/art/map_props/kenney_sketch_desert/rocks_S.png"),
	"tree_n": preload("res://assets/art/map_props/kenney_sketch_desert/tree_N.png"),
	"tree_s": preload("res://assets/art/map_props/kenney_sketch_desert/tree_S.png"),
	"wall_n": preload("res://assets/art/map_props/kenney_sketch_desert/walls_broken_N.png"),
	"wall_s": preload("res://assets/art/map_props/kenney_sketch_desert/walls_broken_S.png"),
}
const MARKET_PROP_REGIONS: Dictionary = {
	"rocks_n": Rect2(69, 218, 127, 111),
	"rocks_s": Rect2(58, 242, 129, 87),
	"tree_n": Rect2(46, 181, 129, 124),
	"tree_s": Rect2(85, 172, 126, 133),
	"wall_n": Rect2(79, 253, 118, 73),
	"wall_s": Rect2(57, 213, 118, 104),
}

var dice_count: int = 1

static func normalized_view_mode(value: String) -> String:
	return VIEW_MODE_TOURISM if value.strip_edges().to_lower() == VIEW_MODE_TOURISM else VIEW_MODE_CLASSIC

static func neighborhood_offsets() -> Array[int]:
	var result: Array[int] = []
	for offset: int in range(FIRST_OFFSET, LAST_OFFSET + 1):
		result.append(offset)
	return result

static func neighborhood_indices(tile_index: int) -> Array[int]:
	var result: Array[int] = []
	for offset: int in neighborhood_offsets():
		result.append(posmod(tile_index + offset, TILE_COUNT))
	return result

static func tile_rects(view_size: Vector2) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var scale_factor: float = minf(view_size.x / 360.0, view_size.y / 250.0)
	var centers := route_centers(view_size)
	for slot: int in range(SLOT_COUNT):
		var offset := FIRST_OFFSET + slot
		var diameter := 34.0 if offset == 0 else (lerpf(30.0, 21.0, float(offset) / 10.0) if offset > 0 else 28.0)
		var slot_size := Vector2.ONE * diameter * clampf(scale_factor, 0.78, 1.35)
		result.append(Rect2(centers[slot] - slot_size * 0.5, slot_size))
	return result

static func route_centers(view_size: Vector2) -> Array[Vector2]:
	# History approaches from the lower-left. From the current tile the road
	# makes one broad S through the scenic field, sampled by travel distance so
	# markers remain separated even near the arc's turning point.
	var rear_dense: Array[Vector2] = []
	var forward_dense: Array[Vector2] = []
	for step: int in range(41):
		var t := float(step) / 40.0
		rear_dense.append(Vector2(lerpf(0.12, 0.50, t) * view_size.x, (0.84 + sin(t * PI) * 0.025) * view_size.y))
	for step: int in range(81):
		var t := float(step) / 80.0
		forward_dense.append(Vector2((0.50 + sin(t * TAU * 0.72) * 0.34) * view_size.x, lerpf(0.84, 0.16, t) * view_size.y))
	var result := _sample_polyline(rear_dense, 5)
	var forward := _sample_polyline(forward_dense, 11)
	for index: int in range(1, forward.size()):
		result.append(forward[index])
	return result

static func smooth_route_points(view_size: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in range(31):
		var t := float(step) / 30.0
		points.append(Vector2(lerpf(0.12, 0.50, t) * view_size.x, (0.84 + sin(t * PI) * 0.025) * view_size.y))
	for step: int in range(1, 61):
		var t := float(step) / 60.0
		points.append(Vector2((0.50 + sin(t * TAU * 0.72) * 0.34) * view_size.x, lerpf(0.84, 0.16, t) * view_size.y))
	return points

static func _sample_polyline(points: Array[Vector2], count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if points.is_empty() or count <= 0:
		return result
	var cumulative: Array[float] = [0.0]
	for index: int in range(1, points.size()):
		cumulative.append(cumulative[-1] + points[index - 1].distance_to(points[index]))
	var total := cumulative[-1]
	for sample: int in range(count):
		var target := total * float(sample) / float(maxi(1, count - 1))
		var segment := 1
		while segment < cumulative.size() and cumulative[segment] < target:
			segment += 1
		if segment >= cumulative.size():
			result.append(points[-1])
			continue
		var segment_length := cumulative[segment] - cumulative[segment - 1]
		var weight := 0.0 if is_zero_approx(segment_length) else (target - cumulative[segment - 1]) / segment_length
		result.append(points[segment - 1].lerp(points[segment], weight))
	return result

static func player_rect(view_size: Vector2) -> Rect2:
	var rects := tile_rects(view_size)
	var current_rect: Rect2 = rects[-FIRST_OFFSET]
	var player_size := Vector2(70.0, 94.0) * clampf(minf(view_size.x / 360.0, view_size.y / 250.0), 0.78, 1.15)
	var player_center := current_rect.get_center() + Vector2(0.0, -current_rect.size.y * 0.35)
	return Rect2(player_center - player_size * Vector2(0.5, 0.78), player_size)

static func rects_fit_without_overlap(rects: Array[Rect2], bounds: Rect2, gap: float = 2.0) -> bool:
	for index: int in range(rects.size()):
		if not bounds.encloses(rects[index]):
			return false
		for other: int in range(index + 1, rects.size()):
			if rects[index].grow(gap * 0.5).intersects(rects[other].grow(gap * 0.5)):
				return false
	return true

static func is_offset_reachable(offset: int, active_dice_count: int, tile_type: StringName) -> bool:
	if offset <= 0:
		return false
	if active_dice_count <= 1:
		return offset <= 6
	var maximum := 12 if active_dice_count == 2 else 18
	return offset <= maximum and tile_type in REACHABLE_SPECIAL_TYPES

static func aspect_fit_rect(source_size: Vector2, bounds: Rect2) -> Rect2:
	if source_size.x <= 0.0 or source_size.y <= 0.0 or bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return bounds
	var fit_scale := minf(bounds.size.x / source_size.x, bounds.size.y / source_size.y)
	var fitted_size := source_size * fit_scale
	return Rect2(bounds.get_center() - fitted_size * 0.5, fitted_size)

static func map_dice_reserved_rect(view_size: Vector2) -> Rect2:
	return Rect2(view_size * Vector2(0.22, 0.43), view_size * Vector2(0.56, 0.28))

static func market_prop_specs(view_size: Vector2, tile_index: int, landmark_level: int) -> Array[Dictionary]:
	if tile_index < 0 or tile_index / 18 != 0 or landmark_level < 0:
		return []
	var scale_factor := clampf(minf(view_size.x / 360.0, view_size.y / 250.0), 0.78, 1.25)
	var specs: Array[Dictionary] = [
		{"id": "wall_n", "rect": Rect2(Vector2(1.0, view_size.y * 0.70), Vector2(30.0, 18.0) * scale_factor)},
		{"id": "wall_s", "rect": Rect2(Vector2(view_size.x - 29.0 * scale_factor, view_size.y * 0.70), Vector2(27.0, 24.0) * scale_factor)},
		{"id": "rocks_n", "rect": Rect2(Vector2(2.0, view_size.y * 0.47), Vector2(28.0, 24.0) * scale_factor)},
		{"id": "rocks_s", "rect": Rect2(Vector2(view_size.x - 32.0 * scale_factor, view_size.y * 0.47), Vector2(30.0, 20.0) * scale_factor)},
	]
	if landmark_level >= 1:
		specs.append({"id": "tree_n", "rect": Rect2(Vector2(2.0, view_size.y * 0.22), Vector2(31.0, 30.0) * scale_factor)})
		specs.append({"id": "tree_s", "rect": Rect2(Vector2(view_size.x - 32.0 * scale_factor, view_size.y * 0.22), Vector2(30.0, 32.0) * scale_factor)})
	return specs

static func prop_specs_are_clear(specs: Array[Dictionary], view_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, view_size)
	var reserved := map_dice_reserved_rect(view_size)
	var tiles := tile_rects(view_size)
	var player := player_rect(view_size)
	for spec: Dictionary in specs:
		var rect: Rect2 = spec.get("rect", Rect2())
		if not bounds.encloses(rect) or rect.intersects(reserved) or rect.intersects(player):
			return false
		for tile: Rect2 in tiles:
			if rect.intersects(tile):
				return false
	return true

func set_dice_count(value: int) -> void:
	dice_count = clampi(value, 1, 5)
	queue_redraw()

func _draw() -> void:
	if is_minimap:
		super._draw()
		return
	_draw_tourism_map()

func _draw_tourism_map() -> void:
	draw_style_box(_tourism_panel(), Rect2(Vector2.ZERO, size))
	_draw_district_wash()
	if scenic_texture != null:
		var scenic_bounds := Rect2(18.0, 42.0, maxf(1.0, size.x - 36.0), maxf(1.0, size.y * 0.50))
		var scenic_rect := aspect_fit_rect(scenic_texture.get_size(), scenic_bounds)
		draw_texture_rect(scenic_texture, scenic_rect, false, Color(1.0, 0.97, 0.88, 0.66))
	_draw_market_props()
	var district_names := ["市場", "ピラミッド", "オアシス", "遺跡", "砂丘"]
	draw_string(ThemeDB.fallback_font, Vector2(18, 29), "%s地区　観光ルート" % district_names[clampi(current_tile / 18, 0, 4)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 145, 29), "%02d / 90" % (current_tile + 1), HORIZONTAL_ALIGNMENT_RIGHT, 126, 17, Color("#795d3f"))
	if scenic_level >= 0:
		draw_string(ThemeDB.fallback_font, Vector2(18, 51), "香辛料市場通り  Lv.%d" % scenic_level, HORIZONTAL_ALIGNMENT_LEFT, 230, 14, Color("#704828"))

	var rects := tile_rects(size)
	var indices := neighborhood_indices(current_tile)
	var smooth_route := smooth_route_points(size)
	draw_polyline(smooth_route, Color(0.27, 0.17, 0.09, 0.34), 12.0, true)
	draw_polyline(smooth_route, Color("#d8bb83"), 7.0, true)

	for slot: int in range(SLOT_COUNT):
		var offset: int = FIRST_OFFSET + slot
		var tile_index: int = indices[slot]
		var tile_type: StringName = tile_types[tile_index] if tile_index < tile_types.size() else &"NORMAL"
		var rect: Rect2 = rects[slot]
		var reachable := is_offset_reachable(offset, dice_count, tile_type)
		var center := rect.get_center()
		var radius := rect.size.x * 0.5
		var fill := Color(TILE_COLORS.get(tile_type, SAND))
		if tile_type == &"NORMAL": fill = Color("#d9bd87")
		if tile_type == &"RISK": fill = Color("#b84f3f")
		if tile_type == &"LANDMARK": fill = Color("#d4a446")
		if offset == 0: fill = Color("#2f8588")
		draw_circle(center + Vector2(1.5, 2.5), radius + 1.0, Color(0.20, 0.12, 0.06, 0.30))
		draw_circle(center, radius, fill)
		var ring := Color("#f1c86a") if offset == 0 else (Color("#287b80") if reachable else Color("#755432"))
		draw_arc(center, radius - 1.0, 0, TAU, 24, ring, 4.0 if offset == 0 else (3.0 if reachable else 1.5), true)
		var text_color := Color("#fff4dc") if offset == 0 or tile_type == &"RISK" else INK
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.48), "%02d" % (tile_index + 1), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, text_color)
		var mark := _tile_mark(tile_type)
		if not mark.is_empty():
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.84), mark, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, text_color)
		if reachable and dice_count == 1:
			draw_circle(rect.position + Vector2(rect.size.x - 2.0, 2.0), 7.0, Color("#287b80"))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 8.5, 5.5), str(offset), HORIZONTAL_ALIGNMENT_CENTER, 13.0, 9, Color.WHITE)
		if tile_type == &"LANDMARK":
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(-3, rect.size.y + 10), "Lv.%d" % _landmark_level(tile_index), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 6, 9, Color("#684829"))

	var current_rect: Rect2 = rects[-FIRST_OFFSET]
	var token_rect := player_rect(size)
	draw_circle(current_rect.get_center() + Vector2(0, 8), current_rect.size.x * 0.42, Color("#287b80"))
	draw_arc(current_rect.get_center() + Vector2(0, 8), current_rect.size.x * 0.42, 0, TAU, 24, Color("#ffe5a4"), 3.0, true)
	draw_texture_rect(PLAYER_TEXTURE, token_rect, false)

func _draw_market_props() -> void:
	var props := market_prop_specs(size, current_tile, scenic_level)
	for spec: Dictionary in props:
		var texture: Texture2D = MARKET_PROP_TEXTURES.get(str(spec.get("id", "")))
		if texture == null:
			continue
		var region: Rect2 = MARKET_PROP_REGIONS.get(str(spec.get("id", "")), Rect2(Vector2.ZERO, texture.get_size()))
		var rect: Rect2 = spec.get("rect", Rect2())
		draw_texture_rect_region(texture, Rect2(rect.position + Vector2(2.0, 3.0), rect.size), region, Color(0.20, 0.12, 0.06, 0.18))
		draw_texture_rect_region(texture, rect, region, Color(0.93, 0.82, 0.67, 0.68))

func _draw_district_wash() -> void:
	var district_index := current_tile / 18
	var colors := [Color("#bc754f"), Color("#d6ae68"), Color("#4f9d91"), Color("#766c8e"), Color("#c77a48")]
	var tint: Color = colors[clampi(district_index, 0, colors.size() - 1)]
	draw_rect(Rect2(8.0, 36.0, size.x - 16.0, size.y - 44.0), Color(tint, 0.14), true)
	for stripe: int in range(5):
		var y := size.y * (0.40 + float(stripe) * 0.105)
		draw_line(Vector2(12, y), Vector2(size.x - 12, y - 8), Color(0.45, 0.28, 0.12, 0.08), 2.0, true)

func _tourism_panel() -> StyleBoxFlat:
	var panel := _board_panel()
	panel.bg_color = Color(0.94, 0.82, 0.61, 0.91)
	panel.border_color = Color("#9e7138")
	return panel
