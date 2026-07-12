class_name BoardView
extends Control

const TILE_COUNT: int = 90
const LANDMARK_IDS_BY_TILE: Dictionary = {
	0: "CAI_LANDMARK_01",
	22: "CAI_LANDMARK_02",
	54: "CAI_LANDMARK_03",
}
const INK: Color = Color("#5c4938")
const SAND: Color = Color("#ead8b5")
const PLAYER_TEXTURE: Texture2D = preload("res://assets/art/characters/relaxed-traveler.png")
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
	&"RISK": Color("#c76552")
}

var tile_types: Array[StringName] = []
var current_tile: int = 0
var route: Path2D
var positions: Array[Vector2] = []
var is_minimap: bool = false
var landmark_levels: Dictionary = {}
var scenic_texture: Texture2D
var scenic_level: int = -1

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
	current_tile = posmod(value, TILE_COUNT)
	_refresh_scenic()
	queue_redraw()

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
	_draw_zoomed_neighborhood()

func _draw_zoomed_neighborhood() -> void:
	# The neighborhood is a legible board ribbon, not a magnified dotted map.
	# The full 90-tile topology remains in the independent minimap.
	draw_style_box(_board_panel(), Rect2(Vector2.ZERO, size))
	if scenic_texture != null:
		var slot_width := maxf(1.0, size.x - 44.0)
		var slot_height := minf(slot_width * 0.5, maxf(1.0, size.y * 0.72))
		draw_texture_rect(scenic_texture, Rect2(22.0, 42.0, slot_width, slot_height), false, Color(1.0, 0.98, 0.91, 0.94))
	draw_string(ThemeDB.fallback_font, Vector2(22, 34), "現在地周辺  %02d / 90" % (current_tile + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	var district_names := ["市場", "ピラミッド", "オアシス", "遺跡", "砂丘"]
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 150, 34), district_names[current_tile / 18], HORIZONTAL_ALIGNMENT_RIGHT, 128, 17, Color("#846c50"))
	if scenic_level >= 0:
		draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.5 - 130.0, 62.0), "香辛料市場通り　Lv.%d" % scenic_level, HORIZONTAL_ALIGNMENT_CENTER, 260.0, 16, Color("#6f5030"))
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
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 27), "%02d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 17, number_color)
		var mark := _tile_mark(tile_type)
		if not mark.is_empty(): draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 58), mark, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 23, number_color)
		if tile_type == &"LANDMARK":
			var landmark_level := _landmark_level(index)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 78), "Lv.%d" % landmark_level, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, number_color)
		if offset == 1: draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y - 10), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color("#fff4dc") if tile_type == &"RISK" else Color("#356b6d"))
	# Direction and token stay centered while the ribbon moves beneath them.
	var center_rect_x := size.x * 0.5 - tile_width * 0.5
	draw_circle(Vector2(size.x * 0.5, center_y + tile_height * 0.5 + 12), 23, Color("#277c80"))
	draw_arc(Vector2(size.x * 0.5, center_y + tile_height * 0.5 + 12), 23, 0, TAU, 24, Color("#ffe5a4"), 4, true)
	draw_texture_rect(PLAYER_TEXTURE, Rect2(Vector2(size.x * 0.5 - 40, center_y - tile_height * 0.5 - 94), Vector2(80, 108)), false)
	draw_string(ThemeDB.fallback_font, Vector2(center_rect_x + tile_width, center_y - tile_height * 0.5 - 12), "▶", HORIZONTAL_ALIGNMENT_CENTER, tile_width, 22, Color("#7d5f36"))

func _draw_minimap() -> void:
	draw_style_box(_mini_panel(), Rect2(Vector2.ZERO, size))
	_draw_route(false)

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
		draw_texture_rect(PLAYER_TEXTURE, Rect2(player_pos - Vector2(24, 55), Vector2(48, 64)), false)
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
	return ""

func _landmark_level(tile_index: int) -> int:
	var landmark_id := str(LANDMARK_IDS_BY_TILE.get(tile_index, ""))
	return clampi(int(landmark_levels.get(landmark_id, 0)), 0, 3)
