extends Control

## Small flat picture of dice, drawn in code so every casino card can show
## "this is what you roll" without a new image asset.

const IVORY := Color("#fff6e4")
const EDGE := Color("#c99b43")
const PIP := Color("#2d241c")
const PIP_LAYOUT := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.28, 0.28), Vector2(0.72, 0.72)],
	3: [Vector2(0.26, 0.26), Vector2(0.5, 0.5), Vector2(0.74, 0.74)],
	4: [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.28, 0.72), Vector2(0.72, 0.72)],
	5: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.5, 0.5), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	6: [Vector2(0.28, 0.24), Vector2(0.72, 0.24), Vector2(0.28, 0.5), Vector2(0.72, 0.5), Vector2(0.28, 0.76), Vector2(0.72, 0.76)],
}

## Body colour; trip dice use their own tint so each reads as a different die.
var body_color := IVORY:
	set(value):
		body_color = value
		queue_redraw()
## Face values, left to right.
var faces: Array[int] = [3, 4]:
	set(value):
		faces = value
		queue_redraw()
## Gap between dice as a fraction of one die.
var gap_ratio := 0.16
## Alternate dice tilt a little so the row reads as thrown, not printed.
var tilt_degrees := 6.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func die_size() -> float:
	var count := maxi(1, faces.size())
	var by_width := size.x / (float(count) + gap_ratio * float(count - 1) + 0.2)
	return maxf(8.0, minf(by_width, size.y * 0.86))


func _draw() -> void:
	if faces.is_empty():
		return
	var side := die_size()
	var gap := side * gap_ratio
	var total := side * faces.size() + gap * (faces.size() - 1)
	var origin := Vector2((size.x - total) * 0.5, (size.y - side) * 0.5)
	for index: int in range(faces.size()):
		var center := origin + Vector2(side * 0.5 + (side + gap) * index, side * 0.5)
		var angle := deg_to_rad(tilt_degrees) * (-1.0 if index % 2 == 0 else 1.0)
		draw_set_transform(center, angle, Vector2.ONE)
		var rect := Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side))
		var body := StyleBoxFlat.new()
		body.bg_color = body_color
		body.border_color = EDGE
		body.set_border_width_all(maxi(2, roundi(side * 0.045)))
		body.set_corner_radius_all(roundi(side * 0.2))
		body.shadow_color = Color(0, 0, 0, 0.35)
		body.shadow_size = maxi(2, roundi(side * 0.06))
		body.shadow_offset = Vector2(0, side * 0.05)
		draw_style_box(body, rect)
		var face := clampi(faces[index], 1, 6)
		for pip: Vector2 in PIP_LAYOUT[face]:
			draw_circle(rect.position + pip * side, side * 0.085, PIP)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
