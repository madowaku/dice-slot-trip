class_name DiceRaceMiniMap
extends Control

const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const GOAL := 24
const RACERS: Array[String] = ["camel", "rabbit", "fox", "duck", "dinosaur", "robot"]
const RACER_COLORS := {
	"camel": Color("#3979bf"), "rabbit": Color("#d65345"),
	"fox": Color("#d96f2b"), "duck": Color("#e0a918"),
	"dinosaur": Color("#6c9f45"), "robot": Color("#5d99a5"),
}
const GIMMICKS := {5: "5 火", 10: "10 水", 15: "15 丸", 20: "20 火"}

var race_positions: Dictionary = {}
var selected_racer := "duck"
var wager_active := false
var camera_range := Vector2(0, 9)
var final_stretch_active := false
var _labels: Dictionary = {}


func _ready() -> void:
	name = "RaceMiniMap"
	custom_minimum_size.x = 82
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_labels()
	resized.connect(_layout_labels)
	queue_redraw()


func set_race_state(positions: Dictionary, bet_racer: String, active: bool) -> void:
	race_positions = positions.duplicate()
	selected_racer = bet_racer
	wager_active = active
	queue_redraw()


func set_camera_range(value: Vector2) -> void:
	camera_range = value
	queue_redraw()


func set_final_stretch(active: bool) -> void:
	final_stretch_active = active
	var goal_label := _labels.get(GOAL) as Label
	if goal_label != null:
		goal_label.add_theme_color_override("font_color", Color.WHITE if active else Color("#ffe59a"))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#171221"), true)
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("#bd9345"), false, 2)
	var x := 18.0
	if final_stretch_active:
		draw_circle(Vector2(x, 38), 14, Color(1.0, 0.76, 0.22, 0.22))
		draw_circle(Vector2(x, 38), 10, Color("#ffe59a"), false, 3)
	draw_line(Vector2(x, 38), Vector2(x, size.y - 38), Color("#e5c775"), 5)
	var camera_top := _position_to_y(int(camera_range.y))
	var camera_bottom := _position_to_y(int(camera_range.x))
	draw_rect(Rect2(5, camera_top, size.x - 10, camera_bottom - camera_top), Color(1.0, 0.82, 0.35, 0.12), true)
	draw_rect(Rect2(5, camera_top, size.x - 10, camera_bottom - camera_top), Color("#f2bf4c"), false, 2)
	for position: int in GIMMICKS:
		var y := _position_to_y(position)
		draw_circle(Vector2(x, y), 6, Color("#f3d07b"))
	for index: int in RACERS.size():
		var racer_id := RACERS[index]
		var position := int(race_positions.get(racer_id, 0))
		var x_offset := float((index % 3) - 1) * 8.0
		var y_offset := float(index / 3) * 5.0 - 2.5
		var center := Vector2(x + x_offset, _position_to_y(position) + y_offset)
		var radius := 8.0 if wager_active and racer_id == selected_racer else 5.5
		if wager_active and racer_id == selected_racer:
			draw_circle(center, radius + 4, Color("#fff0a0"))
		draw_circle(center, radius, RACER_COLORS[racer_id])


func _build_labels() -> void:
	_labels[GOAL] = _label("GOAL", 15, Color("#ffe59a"))
	_labels[0] = _label("START", 15, Color("#dff1d5"))
	for position: int in GIMMICKS:
		_labels[position] = _label(GIMMICKS[position], 14, Color("#f4dfb1"))
	for label: Label in _labels.values():
		add_child(label)


func _layout_labels() -> void:
	for position: int in _labels:
		var label := _labels[position] as Label
		label.position = Vector2(32, _position_to_y(position) - 15)
		label.size = Vector2(size.x - 35, 30)
	queue_redraw()


func _position_to_y(position: int) -> float:
	return lerpf(size.y - 38.0, 38.0, float(position) / float(GOAL))


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
