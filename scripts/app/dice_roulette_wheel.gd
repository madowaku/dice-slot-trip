class_name DiceRouletteWheel
extends Control

const ModelScript = preload("res://scripts/game/dice_roulette_model.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const AREA_COLORS := {
	"LOW": Color("#385a90"),
	"HIGH": Color("#a74545"),
	"ODD": Color("#65458f"),
	"EVEN": Color("#3e7d70"),
	"LUCKY_7": Color("#c18a2c"),
	"JACKPOT": Color("#d6b842"),
}

var red_marker: Label
var blue_marker: Label
var red_angle := -PI * 0.5
var blue_angle := -PI * 0.5
var result_red_slot := -1
var result_blue_slot := -1

func _ready() -> void:
	custom_minimum_size = Vector2(430, 430)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_marker = _make_marker("R", Color("#e15454"))
	blue_marker = _make_marker("B", Color("#4c83dd"))
	add_child(red_marker)
	add_child(blue_marker)
	resized.connect(_refresh_markers)
	call_deferred("_refresh_markers")

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46
	var inner_radius := radius * 0.46
	for slot: int in range(ModelScript.SLOT_COUNT):
		var start_angle := -PI * 0.5 + TAU * float(slot) / float(ModelScript.SLOT_COUNT)
		var end_angle := -PI * 0.5 + TAU * float(slot + 1) / float(ModelScript.SLOT_COUNT)
		var area := ModelScript.area_for_slot(slot)
		var color: Color = AREA_COLORS.get(area, Color.GRAY)
		if slot % 2 == 1:
			color = color.lightened(0.07)
		var points := PackedVector2Array([center])
		for step: int in range(5):
			var t := float(step) / 4.0
			var angle := lerpf(start_angle, end_angle, t)
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, color)
		draw_line(center + Vector2(cos(start_angle), sin(start_angle)) * inner_radius, center + Vector2(cos(start_angle), sin(start_angle)) * radius, Color("#e7d8a5"), 1.0, true)

	draw_circle(center, inner_radius, Color("#17172b"))
	draw_arc(center, radius, 0.0, TAU, 96, Color("#f5d76c"), 5.0, true)
	draw_arc(center, inner_radius, 0.0, TAU, 72, Color("#6d5b82"), 2.0, true)
	var title := "DICE ROULETTE"
	var title_size := FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(FONT, center - Vector2(title_size.x * 0.5, -8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#ffe493"))
	var sub := "WHERE  ×  BOOST"
	var sub_size := FONT.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(FONT, center + Vector2(-sub_size.x * 0.5, 36), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6c8df"))

	_draw_area_caption(center, radius * 0.72, -62.0, "JACKPOT", Color("#fff0a7"))
	_draw_area_caption(center, radius * 0.72, -17.0, "HIGH", Color.WHITE)
	_draw_area_caption(center, radius * 0.72, 47.0, "EVEN", Color.WHITE)
	_draw_area_caption(center, radius * 0.72, 100.0, "LUCKY 7", Color("#fff0a7"))
	_draw_area_caption(center, radius * 0.72, 164.0, "LOW", Color.WHITE)
	_draw_area_caption(center, radius * 0.72, 222.0, "ODD", Color.WHITE)

func _draw_area_caption(center: Vector2, radius: float, degrees: float, text: String, color: Color) -> void:
	var angle := deg_to_rad(degrees)
	var pos := center + Vector2(cos(angle), sin(angle)) * radius
	var text_size := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(FONT, pos - Vector2(text_size.x * 0.5, -5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)

func _make_marker(text: String, fill: Color) -> Label:
	var marker := Label.new()
	marker.text = text
	marker.custom_minimum_size = Vector2(56, 56)
	marker.size = Vector2(56, 56)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_theme_font_override("font", FONT)
	marker.add_theme_font_size_override("font_size", 26)
	marker.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#fff3bf")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	marker.add_theme_stylebox_override("normal", style)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return marker

func reset_markers() -> void:
	result_red_slot = -1
	result_blue_slot = -1
	red_marker.text = "R"
	blue_marker.text = "B"
	_set_red_angle(-PI * 0.5)
	_set_blue_angle(-PI * 0.5 + 0.18)

func animate_results(red_slot: int, blue_slot: int, red_face: int, blue_face: int) -> void:
	result_red_slot = red_slot
	result_blue_slot = blue_slot
	red_marker.text = "R"
	blue_marker.text = "B"
	var red_target := _slot_angle(red_slot) + TAU * 4.0
	var blue_target := _slot_angle(blue_slot) - TAU * 4.25
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_red_angle, red_angle, red_target, 2.15)
	tween.parallel().tween_method(_set_blue_angle, blue_angle, blue_target, 2.45)
	await tween.finished
	_set_red_angle(_slot_angle(red_slot))
	_set_blue_angle(_slot_angle(blue_slot))
	red_marker.text = str(red_face)
	blue_marker.text = str(blue_face)

func _slot_angle(slot: int) -> float:
	return -PI * 0.5 + TAU * (float(slot) + 0.5) / float(ModelScript.SLOT_COUNT)

func _set_red_angle(value: float) -> void:
	red_angle = value
	_refresh_marker(red_marker, red_angle, 0.78)

func _set_blue_angle(value: float) -> void:
	blue_angle = value
	_refresh_marker(blue_marker, blue_angle, 0.61)

func _refresh_markers() -> void:
	if red_marker == null or blue_marker == null:
		return
	_refresh_marker(red_marker, red_angle, 0.78)
	_refresh_marker(blue_marker, blue_angle, 0.61)
	queue_redraw()

func _refresh_marker(marker: Control, angle: float, radius_ratio: float) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46 * radius_ratio
	var marker_size := Vector2(56, 56)
	marker.position = center + Vector2(cos(angle), sin(angle)) * radius - marker_size * 0.5
	marker.size = marker_size
