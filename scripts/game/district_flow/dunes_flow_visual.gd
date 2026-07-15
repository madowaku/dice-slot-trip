class_name DunesFlowVisual
extends "res://scripts/game/district_flow/district_flow_visual_base.gd"

const DISTRICT_ID: StringName = &"DUNES"

static func reaction_profile(level: int) -> Dictionary:
	var clamped := clampi(level, 0, 5)
	return {
		"level": clamped,
		"sand_streaks": 2 if clamped >= 1 else 0,
		"ground_particles": 8 if clamped >= 2 else 0,
		"sand_ripples": 3 if clamped >= 3 else 0,
		"swaying_flags": 2 if clamped >= 4 else 0,
		"distant_wind_bands": 2 if clamped >= 5 else 0,
	}

func _accepts_pulse(event_type: StringName) -> bool:
	return event_type != &"flow_broken"

func _draw_flow_layer(intensity: float) -> void:
	var profile := reaction_profile(flow_level)
	_draw_sand_streaks(int(profile.get("sand_streaks", 0)), intensity)
	_draw_ground_particles(int(profile.get("ground_particles", 0)), intensity)
	_draw_sand_ripples(int(profile.get("sand_ripples", 0)), intensity)
	_draw_flags(int(profile.get("swaying_flags", 0)), intensity)
	_draw_wind_bands(int(profile.get("distant_wind_bands", 0)), intensity)

func _draw_sand_streaks(count: int, intensity: float) -> void:
	for index: int in range(count):
		var travel := fposmod(flow_phase * (26.0 + float(flow_level) * 7.0) + float(index) * size.x * 0.37, size.x + 42.0) - 21.0
		var y := size.y * (0.28 + float(index) * 0.105)
		var length := 16.0 + float(flow_level) * 3.0
		draw_line(Vector2(travel, y), Vector2(travel + length, y - 3.0), Color(0.86, 0.68, 0.36, intensity * 0.52), 1.2, true)

func _draw_ground_particles(count: int, intensity: float) -> void:
	for index: int in range(count):
		var travel := fposmod(float(index) * 57.0 + flow_phase * (40.0 + float(flow_level) * 8.0), size.x + 24.0) - 12.0
		if absf(travel - size.x * 0.5) < size.x * 0.15:
			continue
		var y := size.y * (0.68 + fposmod(float(index) * 0.041, 0.19))
		draw_circle(Vector2(travel, y), 0.8 + float(flow_level) * 0.12, Color(0.76, 0.57, 0.28, intensity * 0.58))

func _draw_sand_ripples(count: int, intensity: float) -> void:
	for ripple: int in range(count):
		var points := PackedVector2Array()
		var base_y := size.y * (0.49 + float(ripple) * 0.105)
		for segment: int in range(9):
			var t := float(segment) / 8.0
			var x := lerpf(size.x * 0.08, size.x * 0.92, t)
			var y := base_y + sin(flow_phase * 0.62 + t * PI * 1.6 + float(ripple)) * (1.1 + float(flow_level) * 0.25)
			points.append(Vector2(x, y))
		draw_polyline(points, Color(0.92, 0.76, 0.43, intensity * 0.24), 1.1, true)

func _draw_flags(count: int, intensity: float) -> void:
	if count <= 0:
		return
	var sway := sin(flow_phase * 1.35) * (2.0 + float(flow_level - 3) * 1.4)
	for side: float in [-1.0, 1.0]:
		var anchor := Vector2(size.x * (0.09 if side < 0.0 else 0.91), size.y * 0.20)
		var pole_end := anchor + Vector2(0.0, 25.0)
		draw_line(anchor, pole_end, Color(0.41, 0.28, 0.15, intensity * 0.66), 1.3, true)
		var cloth_tip := anchor + Vector2(side * (17.0 + sway * side), 7.0)
		var cloth := PackedVector2Array([anchor + Vector2(0.0, 3.0), cloth_tip, anchor + Vector2(0.0, 13.0)])
		draw_colored_polygon(cloth, Color(0.82, 0.46, 0.22, intensity * 0.54))

func _draw_wind_bands(count: int, intensity: float) -> void:
	for band: int in range(count):
		var points := PackedVector2Array()
		var base_y := size.y * (0.12 + float(band) * 0.075)
		for segment: int in range(13):
			var x := size.x * (-0.04 + float(segment) * 0.09)
			var y := base_y + sin(flow_phase * 0.55 + float(segment) * 0.62 + float(band)) * (2.0 + float(flow_level) * 0.35)
			points.append(Vector2(x, y))
		draw_polyline(points, Color(0.96, 0.83, 0.55, intensity * 0.30), 2.0 + float(flow_level - 4) * 0.35, true)

func _draw_pulse_layer(event_type: StringName, progress: float, intensity: float) -> void:
	var alpha := sin(progress * PI) * intensity * 0.72
	if event_type == &"die_stopped":
		var anchor := Vector2(size.x * 0.16, size.y * 0.61)
		for ring: int in range(2):
			draw_arc(anchor, 5.0 + float(ring) * 4.0 + progress * 5.0, PI * 1.05, PI * 1.95, 12, Color(0.95, 0.76, 0.40, alpha * (0.9 - float(ring) * 0.25)), 1.5, true)
	elif event_type == &"role_resolved":
		var anchor := Vector2(size.x * 0.82, size.y * 0.26)
		draw_arc(anchor, 9.0 + progress * 10.0, 0.0, TAU, 20, Color(0.98, 0.80, 0.42, alpha), 2.0, true)
