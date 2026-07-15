class_name MapDiceOverlay
extends Control

signal early_stop_requested

class MapDieBillboard extends Control:
	var face_value := 1
	var rolling := false
	var motion_time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = size * 0.5
		set_process(true)

	func show_face(value: int, is_rolling: bool) -> void:
		face_value = clampi(value, 1, 6)
		rolling = is_rolling
		if not rolling:
			rotation = 0.0
		queue_redraw()

	func _process(delta: float) -> void:
		if not rolling:
			return
		motion_time += delta
		rotation = sin(motion_time * 10.0) * 0.11
		queue_redraw()

	func _draw() -> void:
		var die_rect := Rect2(Vector2(28.0, 7.0), Vector2(68.0, 68.0))
		draw_style_box(_rounded_box(Color(0.18, 0.12, 0.07, 0.28), Color.TRANSPARENT, 13), Rect2(die_rect.position + Vector2(6.0, 9.0), die_rect.size))
		var side := PackedVector2Array([
			die_rect.position + Vector2(5.0, die_rect.size.y - 1.0),
			die_rect.end - Vector2(1.0, 1.0),
			die_rect.end + Vector2(7.0, 7.0),
			die_rect.position + Vector2(12.0, die_rect.size.y + 7.0),
		])
		draw_colored_polygon(side, Color("#bda978"))
		draw_style_box(_rounded_box(Color("#fff8e8"), Color("#d5c39b"), 13), die_rect)
		var center := die_rect.get_center()
		var offset := 17.0
		var positions: Array[Vector2] = []
		match face_value:
			1: positions = [center]
			2: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, offset)]
			3: positions = [center + Vector2(-offset, -offset), center, center + Vector2(offset, offset)]
			4: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, -offset), center + Vector2(-offset, offset), center + Vector2(offset, offset)]
			5: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, -offset), center, center + Vector2(-offset, offset), center + Vector2(offset, offset)]
			6: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, -offset), center + Vector2(-offset, 0.0), center + Vector2(offset, 0.0), center + Vector2(-offset, offset), center + Vector2(offset, offset)]
		for pip: Vector2 in positions:
			draw_circle(pip + Vector2(1.0, 1.5), 5.0, Color(0.16, 0.10, 0.06, 0.18))
			draw_circle(pip, 4.2, Color("#352b24"))

	func _rounded_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		box.border_color = border
		box.set_border_width_all(2 if border.a > 0.0 else 0)
		box.set_corner_radius_all(radius)
		return box

enum Phase { TRAY_IDLE, LAUNCHING_TO_MAP, ROLLING_ON_MAP, STOPPING, RESULT_HOLD, RETURNING_TO_TRAY, COMPLETE }

const PRESENTATION_SIZE := Vector2(128.0, 96.0)
const MAX_DICE := 5
const LAUNCH_DURATION := 0.24
const RESULT_HOLD_DURATION := 0.45
const RETURN_DURATION := 0.23

var phase: Phase = Phase.TRAY_IDLE
var presentation: DicePresentation3D
# The Canvas billboards form a reusable visual pool. Gameplay owns the values;
# this layer only mirrors values and stop state, so Classic remains untouched.
var display: MapDieBillboard
var billboards: Array[MapDieBillboard] = []
var tray_center := Vector2.ZERO
var landing_center := Vector2.ZERO
var active_count := 1
var locked_count := 0
var stop_sent := false
var stop_request_count := 0
var launch_count := 0
var completion_count := 0
var input_exempt_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2.ZERO
	visible = false
	set_process_input(false)
	presentation = DicePresentation3D.new()
	presentation.name = "MapDicePresentation3D"
	presentation.overlay_compact = true
	presentation.render_enabled = false
	presentation.set_tray_visible(false)
	presentation.custom_minimum_size = PRESENTATION_SIZE
	add_child(presentation)
	# Keep the 3D presenter as a pooled state/mesh reference while Canvas draws
	# the transparent 2.5D billboards.
	presentation.anchor_left = 0.0
	presentation.anchor_top = 0.0
	presentation.anchor_right = 0.0
	presentation.anchor_bottom = 0.0
	presentation.position = Vector2.ZERO
	presentation.size = PRESENTATION_SIZE
	presentation.set_tray_visible(false)
	presentation.visible = false
	for index: int in range(MAX_DICE):
		var billboard := MapDieBillboard.new()
		billboard.name = "MapDiceBillboard_%d" % index
		billboard.size = PRESENTATION_SIZE
		billboard.visible = index == 0
		billboards.append(billboard)
		add_child(billboard)
		if index == 0:
			display = billboard

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and phase in [Phase.LAUNCHING_TO_MAP, Phase.ROLLING_ON_MAP]:
		cancel_to_tray()

static func arc_position(start: Vector2, finish: Vector2, progress: float, height: float = 92.0) -> Vector2:
	var t := clampf(progress, 0.0, 1.0)
	return start.lerp(finish, t) + Vector2(0.0, -sin(t * PI) * height)

static func landing_rect_in_screen(map_global_rect: Rect2, reserved_local_rect: Rect2) -> Rect2:
	var clipped := reserved_local_rect.intersection(Rect2(Vector2.ZERO, map_global_rect.size))
	return Rect2(map_global_rect.position + clipped.position, clipped.size)

static func uses_map_presentation(is_tourism: bool, dice_count: int) -> bool:
	return is_tourism and clampi(dice_count, 1, MAX_DICE) in [1, 2, 3, 5]

static func formation_offsets(dice_count: int) -> Array[Vector2]:
	match clampi(dice_count, 1, MAX_DICE):
		1: return [Vector2.ZERO]
		2: return [Vector2(-34.0, 0.0), Vector2(34.0, 0.0)]
		3: return [Vector2(-34.0, 0.0), Vector2.ZERO, Vector2(34.0, 0.0)]
		4: return [Vector2(-48.0, -32.0), Vector2(48.0, -32.0), Vector2(-48.0, 38.0), Vector2(48.0, 38.0)]
		# Compact 3+2 arrangement. The small left pocket is intentional: it
		# keeps the five-die footprint clear of the enlarged player token on
		# 360x250 maps while still reading as a slot result cluster.
		5: return [Vector2(-28.0, -20.0), Vector2(0.0, -20.0), Vector2(28.0, -20.0), Vector2(-14.0, 24.0), Vector2(14.0, 24.0)]
	return [Vector2.ZERO]

static func formation_scale(dice_count: int) -> float:
	match clampi(dice_count, 1, MAX_DICE):
		1: return 1.0
		2: return 0.56
		3: return 0.58
		4: return 0.72
		# Keep the 3+2 cluster compact enough for the small tourism map
		# reference viewport while preserving readable pips.
		5: return 0.52
	return 1.0

static func formation_bounds(dice_count: int) -> Rect2:
	"""Return the actual pooled billboard footprint around its formation center."""
	var count := clampi(dice_count, 1, MAX_DICE)
	var offsets := formation_offsets(count)
	var half_size := PRESENTATION_SIZE * formation_scale(count) * 0.5
	var bounds := Rect2(offsets[0] - half_size, half_size * 2.0)
	for index: int in range(1, offsets.size()):
		var die_rect := Rect2(offsets[index] - half_size, half_size * 2.0)
		bounds = bounds.merge(die_rect)
	return bounds

static func can_request_stop(current_phase: Phase, already_sent: bool) -> bool:
	return current_phase == Phase.ROLLING_ON_MAP and not already_sent

static func is_visual_rolling(logic_rolling: bool, locked_count: int, value_count: int) -> bool:
	return logic_rolling and locked_count < value_count

func begin_launch(values: Array[int], tray_global_rect: Rect2, map_global_rect: Rect2, reserved_local_rect: Rect2) -> void:
	if phase != Phase.TRAY_IDLE and phase != Phase.COMPLETE:
		cancel_to_tray()
	phase = Phase.LAUNCHING_TO_MAP
	stop_sent = false
	locked_count = 0
	active_count = clampi(values.size(), 1, MAX_DICE)
	launch_count += 1
	visible = true
	set_process_input(true)
	tray_center = tray_global_rect.get_center()
	landing_center = landing_rect_in_screen(map_global_rect, reserved_local_rect).get_center()
	presentation.present(values, true, 0)
	for index: int in range(MAX_DICE):
		var billboard := billboards[index]
		billboard.visible = index < active_count
		if index < values.size():
			billboard.show_face(values[index], true)
	_set_presentation_center(tray_center, active_count)
	var elapsed := 0.0
	while elapsed < LAUNCH_DURATION:
		await get_tree().process_frame
		if phase != Phase.LAUNCHING_TO_MAP:
			return
		elapsed += get_process_delta_time()
		var t := minf(1.0, elapsed / LAUNCH_DURATION)
		_set_presentation_center(arc_position(tray_center, landing_center, t), active_count)
		_set_formation_scale(lerpf(0.78, 1.0, t))
	_set_presentation_center(landing_center, active_count)
	phase = Phase.ROLLING_ON_MAP

func present(values: Array[int], rolling: bool, locked_value_count: int) -> void:
	if not visible:
		return
	presentation.present(values, rolling, locked_value_count)
	active_count = clampi(values.size(), 1, MAX_DICE)
	var previous_locked := locked_count
	locked_count = clampi(locked_value_count, 0, active_count)
	var visual_rolling := is_visual_rolling(rolling, locked_count, active_count)
	for index: int in range(MAX_DICE):
		var billboard := billboards[index]
		billboard.visible = index < active_count
		if index < active_count:
			billboard.show_face(values[index], rolling and index >= locked_count)
	if locked_count > previous_locked and phase == Phase.ROLLING_ON_MAP:
		# The next tap can stop the next die. A one-die roll enters STOPPING and
		# therefore still rejects duplicate taps.
		stop_sent = false
	if not visual_rolling and phase == Phase.ROLLING_ON_MAP:
		phase = Phase.STOPPING

func hold_and_return(final_values: Variant) -> void:
	if not visible:
		return
	var values := _normalize_values(final_values)
	begin_result_hold(values)
	await get_tree().create_timer(RESULT_HOLD_DURATION).timeout
	phase = Phase.RETURNING_TO_TRAY
	var start := landing_center
	var elapsed := 0.0
	while elapsed < RETURN_DURATION:
		await get_tree().process_frame
		if phase != Phase.RETURNING_TO_TRAY:
			return
		elapsed += get_process_delta_time()
		var t := minf(1.0, elapsed / RETURN_DURATION)
		_set_presentation_center(arc_position(start, tray_center, t, 42.0), active_count)
		_set_formation_scale(lerpf(1.0, 0.78, t))
	# Land exactly on the tray anchor even when the final frame arrives just
	# before t=1 so repeated formations do not leave a visual residue.
	_set_presentation_center(tray_center, active_count)
	phase = Phase.COMPLETE
	completion_count += 1
	visible = false
	set_process_input(false)
	stop_sent = false
	locked_count = 0
	_set_formation_scale(1.0)
	for billboard: MapDieBillboard in billboards:
		billboard.visible = false
	phase = Phase.TRAY_IDLE

func begin_result_hold(final_values: Variant) -> void:
	if not visible:
		return
	var values := _normalize_values(final_values)
	phase = Phase.RESULT_HOLD
	active_count = clampi(values.size(), 1, MAX_DICE)
	locked_count = active_count
	presentation.present(values, false, active_count)
	for index: int in range(MAX_DICE):
		var billboard := billboards[index]
		billboard.visible = index < active_count
		if index < values.size():
			billboard.show_face(values[index], false)
	_set_presentation_center(landing_center, active_count)

func cancel_to_tray() -> void:
	stop_sent = false
	locked_count = 0
	visible = false
	set_process_input(false)
	input_exempt_rect = Rect2()
	phase = Phase.TRAY_IDLE
	if is_instance_valid(presentation):
		_set_formation_scale(1.0)
	for billboard: MapDieBillboard in billboards:
		billboard.visible = false

func is_active() -> bool:
	return phase != Phase.TRAY_IDLE and phase != Phase.COMPLETE

func receipt() -> Dictionary:
	var pool := presentation.pool_receipt() if is_instance_valid(presentation) else {}
	return {
		"phase": Phase.keys()[phase],
		"launch_count": launch_count,
		"completion_count": completion_count,
		"stop_sent": stop_sent,
		"stop_request_count": stop_request_count,
		"presentation_nodes": 1 if is_instance_valid(presentation) else 0,
		"dice_pool_size": int(pool.get("pool_size", 0)),
		"billboard_pool_size": billboards.size(),
		"active_billboards": active_count,
		"tray_visible": bool(pool.get("tray_visible", true)),
		"presentation_rect": display.get_global_rect() if is_instance_valid(display) else Rect2(),
	}

func _set_presentation_center(center: Vector2, count: int = -1) -> void:
	var formation_count := active_count if count <= 0 else clampi(count, 1, MAX_DICE)
	var offsets := formation_offsets(formation_count)
	var visual_scale := formation_scale(formation_count)
	for index: int in range(MAX_DICE):
		var billboard := billboards[index]
		billboard.size = PRESENTATION_SIZE
		billboard.pivot_offset = PRESENTATION_SIZE * 0.5
		var offset := offsets[index] if index < offsets.size() else Vector2.ZERO
		billboard.position = center + offset - PRESENTATION_SIZE * 0.5
		billboard.scale = Vector2.ONE * visual_scale

func _set_formation_scale(value: float) -> void:
	var scale_value := maxf(0.01, value) * formation_scale(active_count)
	for billboard: MapDieBillboard in billboards:
		billboard.scale = Vector2.ONE * scale_value

func _normalize_values(source: Variant) -> Array[int]:
	var values: Array[int] = []
	if source is Array:
		for value: Variant in source:
			values.append(clampi(int(value), 1, 6))
	else:
		values.append(clampi(int(source), 1, 6))
	return values if not values.is_empty() else [1]

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		event_position = event.position
	elif event is InputEventScreenTouch:
		event_position = event.position
	if input_exempt_rect.has_area() and input_exempt_rect.has_point(event_position):
		return
	get_viewport().set_input_as_handled()
	var pressed: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	pressed = pressed or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		request_early_stop()

func set_input_exempt_rect(rect: Rect2) -> void:
	input_exempt_rect = rect

func request_early_stop() -> bool:
	if not can_request_stop(phase, stop_sent):
		return false
	stop_sent = true
	stop_request_count += 1
	early_stop_requested.emit()
	return true
