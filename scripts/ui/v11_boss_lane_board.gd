class_name V11BossLaneBoard
extends Control

const PLAYER_COLOR := Color("#f0c76a")
const BOSS_COLOR := Color("#66d2c8")
const NORMAL_FILL := Color(0.055, 0.105, 0.12, 0.90)
const NORMAL_EDGE := Color(0.33, 0.43, 0.43, 1.0)
const WING_FILL := Color(0.27, 0.19, 0.065, 0.94)
const WING_EDGE := Color("#f4ca63")
const SAND_FILL := Color(0.24, 0.12, 0.055, 0.94)
const SAND_EDGE := Color("#e69352")
const GOAL_FILL := Color(0.34, 0.22, 0.05, 0.94)
const CELL_SIZE := Vector2(178.0, 66.0)
const CELL_STEP := 78.0
const VIEW_BOTTOM_MARGIN := 30.0
const CAMERA_SCROLL_SPACES := 2.0
const CAMERA_PLAYER_FOLLOW_TOP := 620.0
const CAMERA_PLAYER_FOLLOW_BOTTOM := 725.0
const EDGE_MARKER_HEIGHT := 42.0
const BOSS_MARKER_TEXTURE: Texture2D = preload("res://assets/art/v06/boss/sleepy-sphinx.png")

var course_length := 20
var player_course: Array = []
var boss_course: Array = []
var camera_position := 0.0
var player_position := 0.0
var boss_position := 0.0
var player_preview_position := -1
var boss_preview_position := -1
var player_preview_face := 0
var boss_preview_face := 0
@export var debug_absolute_numbers := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		queue_redraw()


func configure(goal: int, player_tiles: Array, boss_tiles: Array) -> void:
	course_length = maxi(goal, 1)
	player_course = player_tiles.duplicate()
	boss_course = boss_tiles.duplicate()
	queue_redraw()


func set_progress(progress: float, _animated: bool, _duration: float = 0.36) -> void:
	set_racers(progress, progress)


func set_racers(new_player_position: float, new_boss_position: float) -> void:
	player_position = clampf(new_player_position, 0.0, float(course_length))
	boss_position = clampf(new_boss_position, 0.0, float(course_length))
	queue_redraw()


func set_preview(preview: Dictionary) -> void:
	player_preview_position = int(preview.get("player_position", -1))
	boss_preview_position = int(preview.get("boss_position", -1))
	player_preview_face = int(preview.get("player_roll", 0))
	boss_preview_face = int(preview.get("boss_roll", 0))
	queue_redraw()


func clear_preview() -> void:
	player_preview_position = -1
	boss_preview_position = -1
	player_preview_face = 0
	boss_preview_face = 0
	queue_redraw()


func lane_point(position: float, is_player: bool) -> Vector2:
	var x := size.x * (0.29 if is_player else 0.71)
	var y := size.y - VIEW_BOTTOM_MARGIN - (position - camera_position) * CELL_STEP
	return Vector2(x, y)


func set_camera_position(value: float) -> void:
	camera_position = clampf(value, 0.0, maxf(float(course_length) - 4.0, 0.0))
	queue_redraw()


func snapped_camera_for(focus_position: float) -> float:
	var target := camera_position
	var focus := clampf(focus_position, 0.0, float(course_length))
	var projected_y := size.y - VIEW_BOTTOM_MARGIN - (focus - target) * CELL_STEP
	while projected_y < CAMERA_PLAYER_FOLLOW_TOP and target < float(course_length):
		target += CAMERA_SCROLL_SPACES
		projected_y = size.y - VIEW_BOTTOM_MARGIN - (focus - target) * CELL_STEP
	while projected_y > CAMERA_PLAYER_FOLLOW_BOTTOM and target > 0.0:
		target -= CAMERA_SCROLL_SPACES
		projected_y = size.y - VIEW_BOTTOM_MARGIN - (focus - target) * CELL_STEP
	return clampf(target, 0.0, maxf(float(course_length) - 4.0, 0.0))


func next_camera_scroll_target(focus_position: float) -> float:
	var focus_y := lane_point(focus_position, true).y
	if focus_y < CAMERA_PLAYER_FOLLOW_TOP:
		return clampf(camera_position + CAMERA_SCROLL_SPACES, 0.0, maxf(float(course_length) - 4.0, 0.0))
	if focus_y > CAMERA_PLAYER_FOLLOW_BOTTOM:
		return clampf(camera_position - CAMERA_SCROLL_SPACES, 0.0, maxf(float(course_length) - 4.0, 0.0))
	return camera_position


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var first := maxi(int(floor(camera_position)) - 1, 0)
	var visible_rows := int(ceil((size.y + CELL_SIZE.y) / CELL_STEP)) + 2
	var last := mini(first + visible_rows, course_length)
	_draw_lane_bed(true)
	_draw_lane_bed(false)
	for position: int in range(first, last + 1):
		_draw_cell(position, true)
		_draw_cell(position, false)
	_draw_preview(player_preview_position, true, player_preview_face)
	_draw_preview(boss_preview_position, false, boss_preview_face)
	_draw_offscreen_marker(boss_position, false, player_position)


func _draw_lane_bed(is_player: bool) -> void:
	var center := size.x * (0.29 if is_player else 0.71)
	var rect := Rect2(center - CELL_SIZE.x * 0.56, 0.0, CELL_SIZE.x * 1.12, size.y)
	draw_rect(rect, Color(0.008, 0.024, 0.03, 0.62), true)
	draw_line(Vector2(rect.position.x, 0), Vector2(rect.position.x, size.y), Color(0.45, 0.34, 0.18, 0.8), 3.0)
	draw_line(Vector2(rect.end.x, 0), Vector2(rect.end.x, size.y), Color(0.45, 0.34, 0.18, 0.8), 3.0)


func _draw_cell(position: int, is_player: bool) -> void:
	var center := lane_point(float(position), is_player)
	if center.y < -CELL_SIZE.y or center.y > size.y + CELL_SIZE.y:
		return
	var tile := _tile_at(position, is_player)
	var colors := _tile_colors(tile)
	var rect := Rect2(center - CELL_SIZE * 0.5, CELL_SIZE)
	draw_style_box(_cell_style(colors[0], colors[1]), rect)
	if debug_absolute_numbers:
		var font := ThemeDB.fallback_font
		draw_string(font, rect.position + Vector2(10, 20), str(position), HORIZONTAL_ALIGNMENT_LEFT, 34.0, 15, Color(0.78, 0.82, 0.78, 0.9))
	if tile == "WING_GATE":
		_draw_wing_icon(center + Vector2(0, -10), colors[1])
		_draw_centered("翼 +3", center + Vector2(0, 23), 21, Color.WHITE)
	elif tile == "QUICKSAND":
		_draw_quicksand_icon(center + Vector2(-38, 0), colors[1])
		_draw_centered("流砂", center + Vector2(-2, 7), 18, Color("#ffe9cc"))
		var penalty_badge := Rect2(center + Vector2(36, -22), Vector2(48, 44))
		draw_style_box(_penalty_style(), penalty_badge)
		draw_string(ThemeDB.fallback_font, penalty_badge.position + Vector2(0, 32), "−2", HORIZONTAL_ALIGNMENT_CENTER, penalty_badge.size.x, 28, Color.WHITE)
	elif tile == "GOAL":
		_draw_centered("GOAL 20", center + Vector2(0, 7), 21, Color("#ffe08a"))
	elif tile == "START":
		_draw_centered("START", center + Vector2(0, 7), 18, Color(0.82, 0.88, 0.84, 1.0))


func _draw_preview(position: int, is_player: bool, face: int) -> void:
	if position < 0 or position > course_length:
		return
	var center := lane_point(float(position), is_player)
	if center.y < -CELL_SIZE.y or center.y > size.y + CELL_SIZE.y:
		return
	var color := PLAYER_COLOR if is_player else BOSS_COLOR
	var rect := Rect2(center - CELL_SIZE * 0.5 - Vector2(5, 5), CELL_SIZE + Vector2(10, 10))
	draw_style_box(_ring_style(color), rect)
	var chip := Rect2(center.x - 62.0, rect.position.y - 30.0, 124.0, 30.0)
	draw_style_box(_chip_style(color), chip)
	_draw_centered(("YOU %d" if is_player else "SPHINX %d") % face, Vector2(center.x, chip.position.y + 21.0), 16, color)


func _draw_offscreen_marker(position: float, is_player: bool, other_position: float) -> void:
	var point := lane_point(position, is_player)
	var label := offscreen_marker_text(position, is_player, other_position)
	if label.is_empty():
		return
	var color := PLAYER_COLOR if is_player else BOSS_COLOR
	var center_x := size.x * (0.29 if is_player else 0.71)
	var marker_y := 6.0 if point.y < 0.0 else size.y - EDGE_MARKER_HEIGHT - 6.0
	var marker := Rect2(center_x - 94.0, marker_y, 188.0, EDGE_MARKER_HEIGHT)
	draw_style_box(_edge_marker_style(color), marker)
	var text_left := marker.position.x
	var text_width := marker.size.x
	if not is_player:
		var portrait := Rect2(marker.position + Vector2(7, 5), Vector2(32, 32))
		draw_texture_rect(BOSS_MARKER_TEXTURE, portrait, false)
		text_left += 34.0
		text_width -= 34.0
	draw_string(ThemeDB.fallback_font, Vector2(text_left, marker.position.y + 29), label, HORIZONTAL_ALIGNMENT_CENTER, text_width, 17, color)


func offscreen_marker_text(position: float, is_player: bool, other_position: float) -> String:
	var point := lane_point(position, is_player)
	if point.y >= 0.0 and point.y <= size.y:
		return ""
	var is_ahead := position > other_position
	var arrow := "↑" if point.y < 0.0 else "↓"
	var relation := "先" if is_ahead else "後ろ"
	var distance := maxi(int(round(absf(position - other_position))), 1)
	return "%s %s %dマス%s" % ["YOU" if is_player else "SPHINX", arrow, distance, relation]


func _tile_at(position: int, is_player: bool) -> String:
	var course := player_course if is_player else boss_course
	if position < 0 or position >= course.size():
		return "NORMAL"
	return str(course[position])


func _tile_colors(tile: String) -> Array[Color]:
	match tile:
		"WING_GATE": return [WING_FILL, WING_EDGE]
		"QUICKSAND": return [SAND_FILL, SAND_EDGE]
		"GOAL": return [GOAL_FILL, WING_EDGE]
		_: return [NORMAL_FILL, NORMAL_EDGE]


func _cell_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	return style


func _ring_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.08)
	style.border_color = color
	style.set_border_width_all(6)
	style.set_corner_radius_all(14)
	return style


func _chip_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.04, 0.045, 0.96)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style


func _edge_marker_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.035, 0.04, 0.97)
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(13)
	return style


func _penalty_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.025, 0.012, 0.98)
	style.border_color = Color("#ffb45f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(11)
	return style


func _draw_centered(text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(baseline.x - 89.0, baseline.y), text, HORIZONTAL_ALIGNMENT_CENTER, 178.0, font_size, color)


func _draw_wing_icon(center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-6, 9), center + Vector2(-34, -8), center + Vector2(-22, 12)]), color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(6, 9), center + Vector2(34, -8), center + Vector2(22, 12)]), color)
	draw_rect(Rect2(center + Vector2(-5, -12), Vector2(10, 24)), color, true)


func _draw_quicksand_icon(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(-7, -4), 8.0, color)
	draw_circle(center + Vector2(6, 4), 6.0, color)
	draw_arc(center + Vector2(0, 9), 27.0, 0.15, PI - 0.15, 18, color, 4.0)
