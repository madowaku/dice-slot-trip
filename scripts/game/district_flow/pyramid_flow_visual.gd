class_name PyramidFlowVisual
extends "res://scripts/game/district_flow/district_flow_visual_base.gd"

const DISTRICT_ID: StringName = &"PYRAMID"
const EDGE_TRACE_DURATION := 1.05

var edge_trace_elapsed: float = -1.0
var edge_trace_count: int = 0

static func reaction_profile(level: int) -> Dictionary:
	var clamped := clampi(level, 0, 5)
	return {
		"level": clamped,
		"distant_sand": 2 if clamped >= 1 else 0,
		"guide_flags": 2 if clamped >= 2 else 0,
		"sky_wind_lines": 2 if clamped >= 3 else 0,
		"ground_ripples": 3 if clamped >= 4 else 0,
		"edge_trace": 1 if clamped >= 5 else 0,
	}

func set_district_active(active: bool) -> void:
	var was_active := district_active
	super.set_district_active(active)
	if active and not was_active and flow_level == 5:
		_start_edge_trace()
	elif not active:
		edge_trace_elapsed = -1.0

func set_flow_visual_level(level: int) -> void:
	var previous_level := flow_level
	super.set_flow_visual_level(level)
	if district_active and previous_level < 5 and flow_level == 5:
		_start_edge_trace()
	elif flow_level < 5:
		edge_trace_elapsed = -1.0

func receipt() -> Dictionary:
	var result := super.receipt()
	result["edge_trace_active"] = edge_trace_elapsed >= 0.0
	result["edge_trace_count"] = edge_trace_count
	return result

func _allows_zero_flow_pulse(event_type: StringName) -> bool:
	return event_type == &"flow_broken"

func _pulse_duration(event_type: StringName) -> float:
	return 0.48 if event_type == &"flow_broken" else 0.38

func _process(delta: float) -> void:
	super._process(delta)
	if edge_trace_elapsed < 0.0:
		return
	edge_trace_elapsed += delta
	if edge_trace_elapsed >= EDGE_TRACE_DURATION:
		edge_trace_elapsed = -1.0
	queue_redraw()

func _start_edge_trace() -> void:
	edge_trace_elapsed = 0.001
	edge_trace_count += 1
	queue_redraw()

func _draw_static_layer() -> void:
	# The landmark never moves. A faint fixed silhouette establishes distance.
	var apex := Vector2(size.x * 0.50, size.y * 0.07)
	var left_base := Vector2(size.x * 0.24, size.y * 0.34)
	var right_base := Vector2(size.x * 0.76, size.y * 0.34)
	draw_polyline(PackedVector2Array([left_base, apex, right_base]), Color(0.49, 0.40, 0.27, 0.10), 1.4, true)
	draw_line(left_base, right_base, Color(0.49, 0.40, 0.27, 0.07), 1.0, true)

func _draw_flow_layer(intensity: float) -> void:
	var profile := reaction_profile(flow_level)
	_draw_distant_sand(int(profile.get("distant_sand", 0)), intensity)
	_draw_guide_flags(int(profile.get("guide_flags", 0)), intensity)
	_draw_sky_wind_lines(int(profile.get("sky_wind_lines", 0)), intensity)
	_draw_ground_ripples(int(profile.get("ground_ripples", 0)), intensity)
	if int(profile.get("edge_trace", 0)) > 0 and edge_trace_elapsed >= 0.0:
		_draw_edge_trace(intensity)

func _draw_distant_sand(count: int, intensity: float) -> void:
	for band: int in range(count):
		var points := PackedVector2Array()
		var y := size.y * (0.31 + float(band) * 0.08)
		for segment: int in range(11):
			var t := float(segment) / 10.0
			var x := size.x * (0.08 + t * 0.84)
			points.append(Vector2(x, y + sin(t * TAU + flow_phase * 0.52 + float(band)) * 1.5))
		draw_polyline(points, Color(0.77, 0.63, 0.39, intensity * 0.30), 1.2, true)

func _draw_guide_flags(count: int, intensity: float) -> void:
	if count <= 0:
		return
	var sway := sin(flow_phase * 1.08) * (1.2 + float(flow_level) * 0.36)
	for side: float in [-1.0, 1.0]:
		var anchor := Vector2(size.x * (0.09 if side < 0.0 else 0.91), size.y * 0.45)
		draw_line(anchor, anchor + Vector2(0.0, 25.0), Color(0.35, 0.27, 0.18, intensity * 0.58), 1.3, true)
		var tip := anchor + Vector2(side * (12.0 + sway * side), 7.0)
		draw_colored_polygon(PackedVector2Array([anchor + Vector2(0.0, 3.0), tip, anchor + Vector2(0.0, 12.0)]), Color(0.66, 0.39, 0.23, intensity * 0.50))

func _draw_sky_wind_lines(count: int, intensity: float) -> void:
	for line_index: int in range(count):
		var travel := fposmod(flow_phase * (27.0 + float(line_index) * 4.0) + float(line_index) * size.x * 0.48, size.x + 100.0) - 50.0
		var y := size.y * (0.16 + float(line_index) * 0.12)
		var length := 58.0 + float(flow_level) * 7.0
		draw_line(Vector2(travel, y), Vector2(travel + length, y - 4.0), Color(0.78, 0.72, 0.57, intensity * 0.40), 1.6, true)

func _draw_ground_ripples(count: int, intensity: float) -> void:
	for ripple: int in range(count):
		var points := PackedVector2Array()
		var base_y := size.y * (0.67 + float(ripple) * 0.09)
		for segment: int in range(9):
			var t := float(segment) / 8.0
			var x := size.x * (0.06 + t * 0.88)
			if absf(x - size.x * 0.5) < size.x * 0.16:
				continue
			points.append(Vector2(x, base_y + sin(t * PI * 1.7 + flow_phase * 0.44 + float(ripple)) * 1.6))
		if points.size() >= 2:
			draw_polyline(points, Color(0.72, 0.57, 0.34, intensity * 0.32), 1.3, true)

func _draw_edge_trace(intensity: float) -> void:
	var progress := clampf(edge_trace_elapsed / EDGE_TRACE_DURATION, 0.0, 1.0)
	var alpha := sin(progress * PI) * intensity * 0.90
	var apex := Vector2(size.x * 0.50, size.y * 0.07)
	var left_base := Vector2(size.x * 0.24, size.y * 0.34)
	var right_base := Vector2(size.x * 0.76, size.y * 0.34)
	if progress < 0.5:
		var local_progress := progress * 2.0
		_draw_glow_segment(left_base, left_base.lerp(apex, local_progress), alpha)
	else:
		_draw_glow_segment(left_base, apex, alpha)
		_draw_glow_segment(apex, apex.lerp(right_base, (progress - 0.5) * 2.0), alpha)

func _draw_glow_segment(from: Vector2, to: Vector2, alpha: float) -> void:
	draw_line(from, to, Color(1.0, 0.72, 0.26, alpha * 0.24), 5.0, true)
	draw_line(from, to, Color(1.0, 0.93, 0.68, alpha), 2.2, true)

func _draw_pulse_layer(event_type: StringName, progress: float, intensity: float) -> void:
	var alpha := sin(progress * PI) * maxf(intensity, 0.46)
	if event_type == &"die_stopped":
		var anchor := Vector2(size.x * 0.18, size.y * 0.60)
		for ring: int in range(2):
			draw_arc(anchor, 5.0 + float(ring) * 4.0 + progress * 6.0, PI * 1.02, PI * 1.96, 13, Color(0.77, 0.61, 0.37, alpha * (0.62 - float(ring) * 0.16)), 1.4, true)
	elif event_type == &"role_resolved":
		var start := Vector2(size.x * 0.47, size.y * 0.24)
		var finish := Vector2(size.x * 0.82, size.y * 0.70)
		draw_line(start, start.lerp(finish, progress), Color(0.84, 0.78, 0.60, alpha * 0.68), 1.8, true)
	elif event_type == &"flow_broken":
		for side: float in [-1.0, 1.0]:
			var anchor := Vector2(size.x * (0.09 if side < 0.0 else 0.91), size.y * 0.45)
			draw_line(anchor + Vector2(0.0, 3.0), anchor + Vector2(side * 8.0, 9.0), Color(0.47, 0.35, 0.24, alpha * 0.48), 1.6, true)
		for grain: int in range(3):
			var y := size.y * (0.32 + float(grain) * 0.08 + progress * 0.05)
			draw_line(Vector2(size.x * 0.14, y), Vector2(size.x * 0.86, y), Color(0.69, 0.57, 0.39, alpha * (0.30 - float(grain) * 0.05)), 1.1, true)
