extends Control

const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

var die_color: Color = Color("#d9473f")
var edge_color: Color = Color("#7c1715")
var face: int = 1
var badge_text: String = "R"

func _ready() -> void:
	custom_minimum_size = Vector2(68, 68)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func configure(color: Color, badge: String) -> void:
	die_color = color
	edge_color = color.darkened(0.48)
	badge_text = badge
	queue_redraw()

func set_face(value: int) -> void:
	face = clampi(value, 1, 6)
	queue_redraw()

func _draw() -> void:
	var extent: float = minf(size.x, size.y)
	var origin := Vector2((size.x - extent) * 0.5, (size.y - extent) * 0.5)
	var body := Rect2(origin + Vector2(7.0, 4.0), Vector2(extent - 19.0, extent - 19.0))

	# Soft table shadow and two shaded side faces give the marker a readable die silhouette.
	draw_set_transform(origin + Vector2(extent * 0.52, extent * 0.82), 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, extent * 0.34, Color(0.0, 0.0, 0.0, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		body.position + Vector2(5.0, body.size.y),
		body.end,
		body.end + Vector2(-7.0, 9.0),
		body.position + Vector2(10.0, body.size.y + 9.0),
	]), edge_color.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([
		body.position + Vector2(body.size.x, 5.0),
		body.end,
		body.end + Vector2(7.0, 9.0),
		body.position + Vector2(body.size.x + 7.0, 14.0),
	]), edge_color)

	var front := StyleBoxFlat.new()
	front.bg_color = die_color
	front.border_color = Color("#fff1b8")
	front.set_border_width_all(2)
	front.set_corner_radius_all(11)
	front.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	front.shadow_size = 4
	front.shadow_offset = Vector2(2.0, 4.0)
	draw_style_box(front, body)

	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	gloss.set_corner_radius_all(8)
	draw_style_box(gloss, Rect2(body.position + Vector2(5.0, 4.0), Vector2(body.size.x - 10.0, body.size.y * 0.28)))
	_draw_pips(body)

	var badge_center := body.position + Vector2(body.size.x - 2.0, body.size.y - 1.0)
	draw_circle(badge_center, 10.0, Color("#071713"))
	draw_arc(badge_center, 10.0, 0.0, TAU, 24, Color("#ffe493"), 2.0, true)
	var badge_size := FONT.get_string_size(badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(FONT, badge_center - Vector2(badge_size.x * 0.5, -4.5), badge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_circle(body.position + Vector2(10.0, 9.0), 2.6, Color(1.0, 0.93, 0.66, 0.86))

func _draw_pips(body: Rect2) -> void:
	var x_left: float = body.position.x + body.size.x * 0.28
	var x_mid: float = body.position.x + body.size.x * 0.50
	var x_right: float = body.position.x + body.size.x * 0.72
	var y_top: float = body.position.y + body.size.y * 0.27
	var y_mid: float = body.position.y + body.size.y * 0.50
	var y_bottom: float = body.position.y + body.size.y * 0.73
	var positions: Array[Vector2] = []
	match face:
		1:
			positions = [Vector2(x_mid, y_mid)]
		2:
			positions = [Vector2(x_left, y_top), Vector2(x_right, y_bottom)]
		3:
			positions = [Vector2(x_left, y_top), Vector2(x_mid, y_mid), Vector2(x_right, y_bottom)]
		4:
			positions = [Vector2(x_left, y_top), Vector2(x_right, y_top), Vector2(x_left, y_bottom), Vector2(x_right, y_bottom)]
		5:
			positions = [Vector2(x_left, y_top), Vector2(x_right, y_top), Vector2(x_mid, y_mid), Vector2(x_left, y_bottom), Vector2(x_right, y_bottom)]
		6:
			positions = [Vector2(x_left, y_top), Vector2(x_right, y_top), Vector2(x_left, y_mid), Vector2(x_right, y_mid), Vector2(x_left, y_bottom), Vector2(x_right, y_bottom)]
	for pip_position: Vector2 in positions:
		draw_circle(pip_position + Vector2(1.0, 1.5), 5.0, Color(0.0, 0.0, 0.0, 0.48))
		draw_circle(pip_position, 4.6, Color("#fff8df"))
		draw_circle(pip_position - Vector2(1.2, 1.2), 1.3, Color.WHITE)
