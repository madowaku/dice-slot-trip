class_name BoardView
extends Control

const TILE_COUNT: int = 90
const INK: Color = Color("#5c4938")
const SAND: Color = Color("#ead8b5")
const PLAYER_TEXTURE: Texture2D = preload("res://assets/art/characters/relaxed-traveler.png")
const TILE_COLORS: Dictionary = {
	&"NORMAL": Color("#f2e5c9"),
	&"EVENT": Color("#d99572"),
	&"ITEM": Color("#a798c6"),
	&"COIN": Color("#d8b45b"),
	&"WARP": Color("#6aa9b2"),
	&"SHOP": Color("#b87f61"),
	&"REST": Color("#8fb39a"),
	&"LANDMARK": Color("#d4a446"),
	&"BOSS_SCENT": Color("#8b91b7")
}

var tile_types: Array[StringName] = []
var current_tile: int = 0
var route: Path2D
var positions: Array[Vector2] = []
var is_minimap: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_rebuild_route)
	_rebuild_route()

func configure(types: Array[StringName], tile_index: int) -> void:
	tile_types = types
	current_tile = tile_index
	queue_redraw()

func set_current_tile(value: int) -> void:
	current_tile = posmod(value, TILE_COUNT)
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

func _draw() -> void:
	if positions.size() != TILE_COUNT:
		return
	if is_minimap:
		_draw_minimap()
		return
	_draw_zoomed_neighborhood()

func _draw_zoomed_neighborhood() -> void:
	var focus := positions[current_tile]
	var zoom := 2.45
	draw_set_transform(size * 0.5 - focus * zoom, 0.0, Vector2(zoom, zoom))
	_draw_route(true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var caption_position := Vector2(16.0, 26.0)
	draw_string(ThemeDB.fallback_font, caption_position, "現在地周辺", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#70563b"))

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
		if tile_type != &"NORMAL" and show_token_art:
			draw_arc(positions[index], tile_radius, 0.0, TAU, 14, INK, 1.2, true)
			if tile_type == &"BOSS_SCENT":
				# A tiny three-toe footprint makes the low-saturation scent tile recognizable without text.
				for offset: Vector2 in [Vector2(-2, -1), Vector2(0, -3), Vector2(2, -1)]:
					draw_circle(positions[index] + offset, 1.4, INK)
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
