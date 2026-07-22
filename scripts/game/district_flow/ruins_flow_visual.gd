class_name RuinsFlowVisual
extends "res://scripts/game/district_flow/district_flow_visual_base.gd"

const DISTRICT_ID: StringName = &"RUINS"
const RESTRAINED_INTENSITY := 0.68

static func reaction_profile(level: int) -> Dictionary:
	var clamped := clampi(level, 0, 5)
	return {
		"level": clamped,
		"dust_threads": 2 if clamped >= 1 else 0,
		"hanging_accents": 2 if clamped >= 2 else 0,
		"floor_lights": 2 if clamped >= 3 else 0,
		"loose_fragments": 4 if clamped >= 4 else 0,
		"long_wind_lines": 1 if clamped >= 5 else 0,
		"intensity_scale": RESTRAINED_INTENSITY,
	}

func _allows_zero_flow_pulse(event_type: StringName) -> bool:
	return event_type == &"flow_broken"

func _pulse_duration(event_type: StringName) -> float:
	return 0.46 if event_type == &"flow_broken" else 0.36

func _draw_static_layer() -> void:
	# FLOW 0 is fully still. These faint edges only identify the ruins material.
	for side: float in [-1.0, 1.0]:
		var x := size.x * (0.07 if side < 0.0 else 0.93)
		draw_line(Vector2(x, size.y * 0.12), Vector2(x, size.y * 0.38), Color(0.30, 0.27, 0.22, 0.12), 2.0, true)
		draw_line(Vector2(x - 5.0, size.y * 0.13), Vector2(x + 5.0, size.y * 0.13), Color(0.34, 0.30, 0.23, 0.10), 1.3, true)
		draw_circle(Vector2(x - side * 2.0, size.y * 0.42), 2.2, Color(0.58, 0.43, 0.24, 0.13))

func _draw_flow_layer(intensity: float) -> void:
	var profile := reaction_profile(flow_level)
	var quiet_intensity := intensity * RESTRAINED_INTENSITY
	_draw_dust_threads(int(profile.get("dust_threads", 0)), quiet_intensity)
	_draw_hanging_accents(int(profile.get("hanging_accents", 0)), quiet_intensity)
	_draw_floor_lights(int(profile.get("floor_lights", 0)), quiet_intensity)
	_draw_loose_fragments(int(profile.get("loose_fragments", 0)), quiet_intensity)
	_draw_long_wind_lines(int(profile.get("long_wind_lines", 0)), quiet_intensity)

func _draw_dust_threads(count: int, intensity: float) -> void:
	for thread: int in range(count):
		var side := -1.0 if thread == 0 else 1.0
		var travel := fposmod(flow_phase * (13.0 + float(flow_level) * 1.8) + float(thread) * 49.0, size.x * 0.22)
		var start_x := size.x * (0.04 if side < 0.0 else 0.74) + travel
		var base_y := size.y * (0.27 + float(thread) * 0.16)
		var points := PackedVector2Array()
		for segment: int in range(6):
			var t := float(segment) / 5.0
			points.append(Vector2(start_x + t * 23.0, base_y - t * 4.0 + sin(flow_phase + t * PI) * 1.1))
		draw_polyline(points, Color(0.60, 0.52, 0.39, intensity * 0.72), 1.3, true)

func _draw_hanging_accents(count: int, intensity: float) -> void:
	if count <= 0:
		return
	var sway := sin(flow_phase * 0.88) * (0.8 + float(flow_level) * 0.25)
	var cloth_anchor := Vector2(size.x * 0.12, size.y * 0.18)
	draw_line(cloth_anchor, cloth_anchor + Vector2(0.0, 20.0), Color(0.31, 0.27, 0.22, intensity * 0.72), 1.3, true)
	draw_line(cloth_anchor + Vector2(0.0, 5.0), cloth_anchor + Vector2(8.0 + sway, 14.0), Color(0.48, 0.31, 0.24, intensity * 0.72), 2.0, true)
	var lamp := Vector2(size.x * 0.88, size.y * 0.31)
	draw_line(lamp + Vector2(0.0, -12.0), lamp + Vector2(sway * 0.25, -2.0), Color(0.29, 0.25, 0.20, intensity * 0.52), 1.1, true)
	draw_circle(lamp + Vector2(sway * 0.25, 0.0), 2.6, Color(0.78, 0.54, 0.25, intensity * 0.68))

func _draw_floor_lights(count: int, intensity: float) -> void:
	for groove: int in range(count):
		var travel := fposmod(flow_phase * 19.0 + float(groove) * 82.0, size.x * 0.31)
		var y := size.y * (0.68 + float(groove) * 0.13)
		var x_start := size.x * (0.08 if groove == 0 else 0.61) + travel * 0.35
		var points := PackedVector2Array([
			Vector2(x_start, y),
			Vector2(x_start + 20.0, y - 2.0),
			Vector2(x_start + 35.0, y + 1.0),
		])
		draw_polyline(points, Color(0.63, 0.72, 0.58, intensity * 0.75), 1.6, true)

func _draw_loose_fragments(count: int, intensity: float) -> void:
	for fragment: int in range(count):
		var x := fposmod(flow_phase * 17.0 + float(fragment) * 79.0, size.x + 16.0) - 8.0
		var y := size.y * (0.24 + fposmod(float(fragment) * 0.17, 0.43)) + sin(flow_phase * 1.1 + float(fragment)) * 4.0
		if absf(x - size.x * 0.5) < size.x * 0.16:
			continue
		draw_line(Vector2(x, y), Vector2(x + 4.0, y - 2.0), Color(0.46, 0.39, 0.29, intensity * 0.82), 1.4, true)

func _draw_long_wind_lines(count: int, intensity: float) -> void:
	for line_index: int in range(count):
		var points := PackedVector2Array()
		for segment: int in range(15):
			var t := float(segment) / 14.0
			points.append(Vector2(size.x * (-0.04 + t * 1.08), size.y * 0.20 + sin(t * TAU + flow_phase * 0.42) * 2.0))
		draw_polyline(points, Color(0.67, 0.61, 0.48, intensity * 0.68), 1.8, true)

func _draw_pulse_layer(event_type: StringName, progress: float, intensity: float) -> void:
	var alpha := sin(progress * PI) * maxf(intensity * RESTRAINED_INTENSITY, 0.42)
	if event_type == &"die_stopped":
		var anchor := Vector2(size.x * 0.18, size.y * 0.61)
		for puff: int in range(3):
			var offset := Vector2(float(puff) * 5.0, -float(puff % 2) * 2.0 - progress * 4.0)
			draw_arc(anchor + offset, 3.0 + progress * 4.0, PI * 1.05, PI * 1.88, 9, Color(0.63, 0.54, 0.40, alpha * (0.58 - float(puff) * 0.10)), 1.2, true)
	elif event_type == &"role_resolved":
		var reach := lerpf(size.x * 0.17, size.x * 0.78, progress)
		var y := size.y * 0.76
		draw_polyline(PackedVector2Array([Vector2(size.x * 0.12, y), Vector2(reach * 0.72, y - 3.0), Vector2(reach, y)]), Color(0.70, 0.77, 0.58, alpha * 0.66), 1.7, true)
	elif event_type == &"flow_broken":
		for side: float in [-1.0, 1.0]:
			var lamp := Vector2(size.x * (0.12 if side < 0.0 else 0.88), size.y * 0.31)
			draw_circle(lamp, 3.2, Color(0.16, 0.14, 0.12, alpha * 0.42))
		for grain: int in range(4):
			var x := size.x * (0.18 + float(grain) * 0.21)
			var y := size.y * (0.38 + progress * 0.22) + float(grain % 2) * 4.0
			draw_line(Vector2(x, y), Vector2(x, y + 2.5), Color(0.50, 0.43, 0.34, alpha * 0.46), 1.0, true)
