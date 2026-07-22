extends Control

## A presentation-only transition for entering the royal maze. Gameplay and
## save state are committed before this layer appears, so interruption can
## safely resume directly inside the maze without restoring a half-open page.

const APP_FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const DURATION_SECONDS := 1.08

var progress := 0.0
var skip_requested := false
var completed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	queue_redraw()


static func phase_receipt(value: float) -> Dictionary:
	var amount := clampf(value, 0.0, 1.0)
	return {
		"progress": amount,
		"pyramid_lift": _phase(amount, 0.0, 0.24),
		"door_open": _phase(amount, 0.10, 0.38),
		"page_fold": _phase(amount, 0.20, 0.62),
		"maze_rise": _phase(amount, 0.36, 0.80),
		"torch_light": _phase(amount, 0.56, 0.90),
		"tray_slide": _phase(amount, 0.72, 1.0),
	}


static func _phase(value: float, start: float, finish: float) -> float:
	return smoothstep(start, finish, value)


func play(duration_override: float = -1.0) -> void:
	var duration := DURATION_SECONDS if duration_override < 0.0 else maxf(0.01, duration_override)
	if OS.get_environment("DICE_REDUCED_MOTION") == "1":
		duration = 0.08
	var started_at := Time.get_ticks_usec()
	while progress < 1.0 and not skip_requested:
		var elapsed := float(Time.get_ticks_usec() - started_at) / 1000000.0
		set_preview_progress(elapsed / duration)
		await get_tree().process_frame
	set_preview_progress(1.0)
	completed = true
	# Keep the completed composition for one frame before handing control back.
	await get_tree().process_frame


func set_preview_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func request_skip() -> void:
	skip_requested = true


func receipt() -> Dictionary:
	var result := phase_receipt(progress)
	result["completed"] = completed
	result["skipped"] = skip_requested
	return result


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		request_skip()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		request_skip()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		request_skip()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var view := size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var phases := phase_receipt(progress)
	var center := Vector2(view.x * 0.5, view.y * 0.47)
	_draw_parchment(view)
	_draw_folding_ground(view, center, float(phases.page_fold))
	_draw_pyramid(center, float(phases.pyramid_lift), float(phases.door_open))
	_draw_maze(center + Vector2(0, 155), float(phases.maze_rise), float(phases.torch_light))
	_draw_dice_tray(view, float(phases.tray_slide))
	_draw_caption(view, float(phases.maze_rise))


func _draw_parchment(view: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color("#17130f"))
	draw_rect(Rect2(18, 20, view.x - 36, view.y - 40), Color("#d8bd83"))
	draw_rect(Rect2(30, 32, view.x - 60, view.y - 64), Color("#ecd7a7"))
	for index: int in range(7):
		var y := 80.0 + index * 154.0
		draw_line(Vector2(42, y), Vector2(view.x - 42, y + 16), Color(0.35, 0.22, 0.12, 0.09), 3.0)


func _draw_folding_ground(view: Vector2, center: Vector2, amount: float) -> void:
	var seam_y := center.y + 100.0
	var fold := amount * view.x * 0.34
	var shadow_alpha := lerpf(0.12, 0.62, amount)
	draw_rect(Rect2(30, seam_y - 12, view.x - 60, view.y - seam_y - 120), Color(0.07, 0.055, 0.045, shadow_alpha))
	var left := PackedVector2Array([
		Vector2(30, seam_y - 180), Vector2(center.x, seam_y - 100),
		Vector2(center.x - fold, seam_y + 220), Vector2(30, seam_y + 150)
	])
	var right := PackedVector2Array([
		Vector2(center.x, seam_y - 100), Vector2(view.x - 30, seam_y - 180),
		Vector2(view.x - 30, seam_y + 150), Vector2(center.x + fold, seam_y + 220)
	])
	draw_colored_polygon(left, Color("#b89459"))
	draw_colored_polygon(right, Color("#c4a66d"))
	draw_line(Vector2(center.x, seam_y - 100), Vector2(center.x, seam_y + 220), Color(0.22, 0.14, 0.08, 0.55), 4.0)


func _draw_pyramid(center: Vector2, lift: float, door_open: float) -> void:
	var base_y := center.y - 30.0 - lift * 34.0
	var half_width := 205.0 + lift * 16.0
	var peak := Vector2(center.x, base_y - 245.0 - lift * 22.0)
	var left_base := Vector2(center.x - half_width, base_y + 110.0)
	var right_base := Vector2(center.x + half_width, base_y + 110.0)
	draw_colored_polygon(PackedVector2Array([peak + Vector2(12, 18), left_base + Vector2(16, 18), right_base + Vector2(16, 18)]), Color(0.08, 0.05, 0.03, 0.34))
	draw_colored_polygon(PackedVector2Array([peak, left_base, right_base]), Color("#c89a4c"))
	draw_colored_polygon(PackedVector2Array([peak, Vector2(center.x, base_y + 110), right_base]), Color("#aa7535"))
	for row: int in range(5):
		var y := lerpf(peak.y + 44.0, base_y + 90.0, float(row) / 4.0)
		var width := lerpf(45.0, half_width - 18.0, float(row) / 4.0)
		draw_line(Vector2(center.x - width, y), Vector2(center.x + width, y), Color(0.30, 0.18, 0.08, 0.28), 3.0)
	var doorway := Rect2(center.x - 51, base_y + 18, 102, 92)
	draw_rect(doorway, Color("#211913"))
	var panel_width := doorway.size.x * 0.5
	var slide := door_open * 49.0
	draw_rect(Rect2(doorway.position.x - slide, doorway.position.y, panel_width, doorway.size.y), Color("#6d5133"))
	draw_rect(Rect2(center.x + slide, doorway.position.y, panel_width, doorway.size.y), Color("#5b422b"))
	draw_circle(Vector2(center.x, doorway.position.y + 45), 8.0 + door_open * 13.0, Color(0.95, 0.72, 0.28, 0.18 + door_open * 0.42))


func _draw_maze(center: Vector2, rise: float, torch_amount: float) -> void:
	if rise <= 0.001:
		return
	var vertical_scale := lerpf(0.06, 1.0, rise)
	var ring_x := 235.0
	var ring_y := 132.0 * vertical_scale
	draw_ellipse(center + Vector2(0, 15), ring_x + 26, ring_y + 20, Color(0.02, 0.015, 0.01, 0.48), false, 18.0, true)
	draw_ellipse(center, ring_x, ring_y, Color("#4b4035"), false, 30.0, true)
	draw_ellipse(center, ring_x - 62, maxf(12.0, ring_y - 42), Color("#191714"), false, 10.0, true)
	for index: int in range(8):
		var angle := -PI * 0.5 + TAU * float(index) / 8.0
		var point := center + Vector2(cos(angle) * ring_x, sin(angle) * ring_y)
		var gate := index == 0
		var tile_color := Color("#dfb85f") if gate else Color("#756653")
		draw_circle(point + Vector2(3, 5), 30.0, Color(0.02, 0.01, 0.0, 0.45))
		draw_circle(point, 27.0, tile_color)
		draw_circle(point, 21.0, Color("#3f372f") if not gate else Color("#f0cf78"))
		if gate:
			draw_rect(Rect2(point.x - 12, point.y - 17, 24, 31), Color("#382b20"))
			draw_arc(point + Vector2(0, -15), 12, PI, TAU, 12, Color("#f7df98"), 4.0)
	var lit_count := clampi(ceili(torch_amount * 4.0), 0, 4)
	for index: int in range(4):
		var x := center.x - 180.0 + index * 120.0
		var flame_y := center.y - 8.0
		draw_line(Vector2(x, flame_y + 12), Vector2(x, flame_y + 55), Color("#62482d"), 7.0)
		if index < lit_count:
			draw_circle(Vector2(x, flame_y), 23.0, Color(1.0, 0.50, 0.10, 0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(x, flame_y - 25), Vector2(x - 10, flame_y + 8), Vector2(x + 10, flame_y + 8)]), Color("#f5a623"))


func _draw_dice_tray(view: Vector2, amount: float) -> void:
	if amount <= 0.001:
		return
	var y := lerpf(view.y + 110.0, view.y - 238.0, amount)
	var tray := Rect2(82, y, view.x - 164, 154)
	draw_rect(Rect2(tray.position + Vector2(8, 10), tray.size), Color(0.02, 0.01, 0.0, 0.42))
	draw_rect(tray, Color("#312b28"))
	draw_rect(Rect2(tray.position + Vector2(12, 12), tray.size - Vector2(24, 24)), Color("#59483a"), false, 5.0)
	draw_string(APP_FONT, Vector2(tray.position.x + 25, tray.position.y + 48), "王墓のダイス", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#f1d28a"))
	for index: int in range(3):
		var die := Rect2(tray.position.x + 245 + index * 64, tray.position.y + 34, 48, 48)
		draw_rect(die, Color("#e6d4ae"))
		draw_circle(die.get_center(), 4.0, Color("#3b3027"))


func _draw_caption(view: Vector2, amount: float) -> void:
	var title_alpha := clampf(0.34 + amount * 1.5, 0.0, 1.0)
	var title_color := Color(0.24, 0.16, 0.09, title_alpha)
	var sub_color := Color(0.34, 0.23, 0.14, title_alpha * 0.92)
	draw_rect(Rect2(48, 47, view.x - 96, 92), Color(0.96, 0.88, 0.70, 0.54 * title_alpha))
	draw_string(APP_FONT, Vector2(0, 92), "王の迷い環", HORIZONTAL_ALIGNMENT_CENTER, view.x, 36, title_color)
	draw_string(APP_FONT, Vector2(0, 126), "ページの下に隠されていた石の回廊", HORIZONTAL_ALIGNMENT_CENTER, view.x, 18, sub_color)
	draw_string(APP_FONT, Vector2(0, view.y - 42), "タップでスキップ", HORIZONTAL_ALIGNMENT_CENTER, view.x, 15, Color(0.82, 0.73, 0.58, 0.72))
