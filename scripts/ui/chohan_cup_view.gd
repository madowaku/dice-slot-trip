extends Control

## The 壺 (dice cup) for 丁半, drawn in code: an upturned woven cup that hides
## the dice until it is lifted.

const WEAVE := Color("#8a5a2b")
const WEAVE_DARK := Color("#5f3a18")
const WEAVE_LIGHT := Color("#b98345")
const CORD := Color("#b3261e")
const RIM := Color("#3f260f")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = Vector2(size.x * 0.5, size.y * 0.9)
		queue_redraw()


func _edge_x(y_ratio: float, left: bool) -> float:
	# The cup widens toward its mouth, which rests on the table.
	var inset := lerpf(0.2, 0.03, clampf(y_ratio, 0.0, 1.0))
	return size.x * (inset if left else 1.0 - inset)


func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var top := size.y * 0.1
	var bottom := size.y * 0.9
	var height := bottom - top

	# Soft contact shadow under the mouth.
	var shadow := PackedVector2Array()
	for step: int in range(25):
		var angle := TAU * float(step) / 24.0
		shadow.append(Vector2(size.x * 0.5 + cos(angle) * size.x * 0.52, bottom + sin(angle) * size.y * 0.07))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.38))

	# Body with a domed top.
	var body := PackedVector2Array()
	for step: int in range(13):
		var t := float(step) / 12.0
		var x := lerpf(_edge_x(0.0, true), _edge_x(0.0, false), t)
		body.append(Vector2(x, top - sin(t * PI) * size.y * 0.07))
	body.append(Vector2(_edge_x(1.0, false), bottom))
	body.append(Vector2(_edge_x(1.0, true), bottom))
	draw_colored_polygon(body, WEAVE)

	# Left-side highlight band gives the cup some roundness.
	var shine := PackedVector2Array([
		Vector2(lerpf(_edge_x(0.0, true), _edge_x(0.0, false), 0.16), top),
		Vector2(lerpf(_edge_x(0.0, true), _edge_x(0.0, false), 0.34), top),
		Vector2(lerpf(_edge_x(1.0, true), _edge_x(1.0, false), 0.3), bottom),
		Vector2(lerpf(_edge_x(1.0, true), _edge_x(1.0, false), 0.1), bottom),
	])
	draw_colored_polygon(shine, Color(WEAVE_LIGHT.r, WEAVE_LIGHT.g, WEAVE_LIGHT.b, 0.45))

	# Woven bands.
	var bands := 9
	for index: int in range(1, bands):
		var ratio := float(index) / float(bands)
		var y := top + height * ratio
		draw_line(Vector2(_edge_x(ratio, true), y), Vector2(_edge_x(ratio, false), y), WEAVE_DARK, 3.0, true)
	var ribs := 11
	for index: int in range(1, ribs):
		var t := float(index) / float(ribs)
		draw_line(
			Vector2(lerpf(_edge_x(0.0, true), _edge_x(0.0, false), t), top - sin(t * PI) * size.y * 0.07),
			Vector2(lerpf(_edge_x(1.0, true), _edge_x(1.0, false), t), bottom),
			Color(WEAVE_DARK.r, WEAVE_DARK.g, WEAVE_DARK.b, 0.55), 2.0, true)

	# Red cord and dark rim at the mouth.
	var cord_y := top + height * 0.22
	draw_line(Vector2(_edge_x(0.22, true), cord_y), Vector2(_edge_x(0.22, false), cord_y), CORD, 12.0, true)
	draw_line(Vector2(_edge_x(1.0, true), bottom), Vector2(_edge_x(1.0, false), bottom), RIM, 12.0, true)
