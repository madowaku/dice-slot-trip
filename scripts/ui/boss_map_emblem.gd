extends Control
class_name BossMapEmblem

const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const WINE := Color("#341b24")
const WINE_LIGHT := Color("#6d2d3a")
const GOLD := Color("#f7d36c")
const GOLD_LIGHT := Color("#fff0b0")
const RED := Color("#be4c48")

var compact := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var diameter := maxf(minf(size.x, size.y), 1.0)
	var center := size * 0.5
	var radius := diameter * 0.42
	# A dark wine medallion and two high-contrast rings keep the boss marker
	# readable over parchment, jungle foliage, and Kyoto night scenery alike.
	draw_circle(center, radius * 1.18, Color(0.16, 0.07, 0.08, 0.30))
	draw_circle(center, radius * 1.08, WINE)
	draw_arc(center, radius * 1.08, 0.0, TAU, 40, GOLD, maxf(2.0, diameter * 0.045), true)
	draw_arc(center, radius * 0.91, 0.0, TAU, 40, RED, maxf(1.5, diameter * 0.028), true)
	for angle: float in [-PI * 0.5, -PI * 0.25, 0.0, PI * 0.25, PI * 0.5]:
		var ray_from := center + Vector2(cos(angle), sin(angle)) * radius * 1.18
		var ray_to := center + Vector2(cos(angle), sin(angle)) * radius * 1.34
		draw_line(ray_from, ray_to, Color(GOLD, 0.82), maxf(1.5, diameter * 0.035), true)
	# Crown silhouette: three unmistakable points, a red jewel, and a bright
	# base band. This remains legible even when the map is zoomed out.
	var crown_top := center - Vector2(0.0, radius * 0.56)
	var crown := PackedVector2Array([
		crown_top + Vector2(-radius * 0.72, radius * 0.82),
		crown_top + Vector2(-radius * 0.57, -radius * 0.02),
		crown_top + Vector2(-radius * 0.12, radius * 0.42),
		crown_top + Vector2(0.0, -radius * 0.20),
		crown_top + Vector2(radius * 0.25, radius * 0.38),
		crown_top + Vector2(radius * 0.70, -radius * 0.08),
		crown_top + Vector2(radius * 0.57, radius * 0.82),
	])
	draw_colored_polygon(crown, GOLD)
	var crown_outline := crown.duplicate()
	crown_outline.append(crown_outline[0])
	draw_polyline(crown_outline, GOLD_LIGHT, maxf(1.5, diameter * 0.025), true)
	var band := Rect2(center + Vector2(-radius * 0.72, radius * 0.18), Vector2(radius * 1.44, radius * 0.26))
	draw_rect(band, GOLD_LIGHT)
	draw_rect(band, WINE_LIGHT, false, maxf(1.0, diameter * 0.018))
	draw_circle(center + Vector2(0.0, -radius * 0.03), radius * 0.13, RED)
	draw_circle(center + Vector2(-radius * 0.04, -radius * 0.07), radius * 0.045, GOLD_LIGHT)
	var label_size := 9 if compact or diameter < 58.0 else 12
	var label_y := center.y + radius * 0.86
	draw_string(FONT, Vector2(center.x - diameter * 0.40, label_y), "BOSS", HORIZONTAL_ALIGNMENT_CENTER, diameter * 0.80, label_size, GOLD_LIGHT)
