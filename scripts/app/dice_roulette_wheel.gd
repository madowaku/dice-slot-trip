class_name DiceRouletteWheel
extends Control

const ModelScript = preload("res://scripts/game/dice_roulette_model.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const DISPLAY_FONT: Font = preload("res://assets/fonts/cinzel/Cinzel-Variable.ttf")
const BEZEL: Texture2D = preload("res://assets/casino/dice_roulette/ui/roulette-bezel-v1.png")
const DieMarkerScript = preload("res://scripts/app/dice_roulette_die_marker.gd")

const AREA_COLORS := {
	"LOW": Color("#385a90"),
	"HIGH": Color("#a74545"),
	"ODD": Color("#65458f"),
	"EVEN": Color("#3e7d70"),
	"LUCKY_7": Color("#c18a2c"),
	"JACKPOT": Color("#d6b842"),
}

var red_marker: Control
var blue_marker: Control
var red_angle := -PI * 0.5
var blue_angle := -PI * 0.5
var result_red_slot := -1
var result_blue_slot := -1
var markers_spinning := false

func _ready() -> void:
	custom_minimum_size = Vector2(430, 430)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_marker = _make_marker("R", Color("#e15454"))
	blue_marker = _make_marker("B", Color("#3b78df"))
	add_child(red_marker)
	add_child(blue_marker)
	resized.connect(_refresh_markers)
	call_deferred("_refresh_markers")

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.395
	var inner_radius := radius * 0.45
	draw_circle(center, radius * 1.035, Color("#04140f"))
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
		draw_line(center + Vector2(cos(start_angle), sin(start_angle)) * inner_radius, center + Vector2(cos(start_angle), sin(start_angle)) * radius, Color("#f6df91"), 2.0, true)

	draw_circle(center, inner_radius, Color("#061d16"))
	draw_arc(center, radius, 0.0, TAU, 96, Color("#f5d76c"), 4.0, true)
	draw_arc(center, inner_radius, 0.0, TAU, 72, Color("#d6a93e"), 3.0, true)
	var title := "WHERE"
	var title_size := DISPLAY_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	draw_string(DISPLAY_FONT, center - Vector2(title_size.x * 0.5, -7), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#ffe493"))
	var sub := "DICE BOOST"
	var sub_size := FONT.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	draw_string(FONT, center + Vector2(-sub_size.x * 0.5, 34), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f4dab1"))

	_draw_area_caption(center, radius * 0.64, -62.0, "JACKPOT", Color("#fff0a7"))
	_draw_area_caption(center, radius * 0.64, -17.0, "HIGH", Color.WHITE)
	_draw_area_caption(center, radius * 0.64, 47.0, "EVEN", Color.WHITE)
	_draw_area_caption(center, radius * 0.64, 100.0, "LUCKY 7", Color("#fff0a7"))
	_draw_area_caption(center, radius * 0.64, 164.0, "LOW", Color.WHITE)
	_draw_area_caption(center, radius * 0.64, 222.0, "ODD", Color.WHITE)
	draw_texture_rect(BEZEL, Rect2(Vector2.ZERO, size), false)

func _draw_area_caption(center: Vector2, radius: float, degrees: float, text: String, color: Color) -> void:
	var angle := deg_to_rad(degrees)
	var pos := center + Vector2(cos(angle), sin(angle)) * radius
	var text_size := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(FONT, pos - Vector2(text_size.x * 0.5, -6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)

func _make_marker(text: String, fill: Color) -> Control:
	var marker := DieMarkerScript.new() as Control
	marker.custom_minimum_size = Vector2(68, 68)
	marker.size = Vector2(68, 68)
	marker.call("configure", fill, text)
	return marker

func reset_markers() -> void:
	result_red_slot = -1
	result_blue_slot = -1
	markers_spinning = false
	red_marker.call("set_face", 1)
	blue_marker.call("set_face", 1)
	_set_red_angle(-PI * 0.5)
	_set_blue_angle(-PI * 0.5 + 0.18)

func animate_results(red_slot: int, blue_slot: int, red_face: int, blue_face: int) -> void:
	result_red_slot = red_slot
	result_blue_slot = blue_slot
	markers_spinning = true
	var red_target := _slot_angle(red_slot) + TAU * 4.0
	var blue_target := _slot_angle(blue_slot) - TAU * 4.25
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_red_angle, red_angle, red_target, 1.18)
	tween.parallel().tween_method(_set_blue_angle, blue_angle, blue_target, 1.38)
	await tween.finished
	markers_spinning = false
	_set_red_angle(_slot_angle(red_slot))
	_set_blue_angle(_slot_angle(blue_slot))
	red_marker.call("set_face", red_face)
	blue_marker.call("set_face", blue_face)

func _slot_angle(slot: int) -> float:
	return -PI * 0.5 + TAU * (float(slot) + 0.5) / float(ModelScript.SLOT_COUNT)

func _set_red_angle(value: float) -> void:
	red_angle = value
	if markers_spinning:
		red_marker.call("set_face", posmod(int(floor(absf(value) * 4.0)), 6) + 1)
	_refresh_marker(red_marker, red_angle, 0.78)

func _set_blue_angle(value: float) -> void:
	blue_angle = value
	if markers_spinning:
		blue_marker.call("set_face", posmod(int(floor(absf(value) * 4.0)) + 2, 6) + 1)
	_refresh_marker(blue_marker, blue_angle, 0.61)

func _refresh_markers() -> void:
	if red_marker == null or blue_marker == null:
		return
	_refresh_marker(red_marker, red_angle, 0.78)
	_refresh_marker(blue_marker, blue_angle, 0.61)
	queue_redraw()

func _refresh_marker(marker: Control, angle: float, radius_ratio: float) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.395 * radius_ratio
	var marker_size := Vector2(68, 68)
	var tangent := Vector2(-sin(angle), cos(angle))
	var lane_offset: float = -30.0 if marker == red_marker else 30.0
	marker.position = center + Vector2(cos(angle), sin(angle)) * radius + tangent * lane_offset - marker_size * 0.5
	marker.size = marker_size
