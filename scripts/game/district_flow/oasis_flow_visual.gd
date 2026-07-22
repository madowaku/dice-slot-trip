class_name OasisFlowVisual
extends "res://scripts/game/district_flow/district_flow_visual_base.gd"

const DISTRICT_ID: StringName = &"OASIS"

static func reaction_profile(level: int) -> Dictionary:
	var clamped := clampi(level, 0, 5)
	return {
		"level": clamped,
		"surface_ripples": 3 if clamped >= 1 else 0,
		"palm_sway": 2 if clamped >= 2 else 0,
		"light_streaks": 2 if clamped >= 3 else 0,
		"scene_reactors": 3 if clamped >= 4 else 0,
		"tailwind_waves": 3 if clamped >= 5 else 0,
	}

func _allows_zero_flow_pulse(event_type: StringName) -> bool:
	return event_type == &"flow_broken"

func _pulse_duration(event_type: StringName) -> float:
	return 0.48 if event_type == &"flow_broken" else 0.38

func _draw_static_layer() -> void:
	# FLOW 0 keeps a recognizable but completely still water surface and palms.
	for line_index: int in range(3):
		var water_line := _water_line(0.46 + float(line_index) * 0.11, 0.7, float(line_index) * 0.8)
		draw_polyline(water_line, Color(0.20, 0.61, 0.65, 0.13), 1.1, true)
	_draw_palms(0.0, 0.16)

func _draw_flow_layer(intensity: float) -> void:
	var profile := reaction_profile(flow_level)
	_draw_surface_ripples(int(profile.get("surface_ripples", 0)), intensity)
	if int(profile.get("palm_sway", 0)) > 0:
		_draw_palms(
			sin(flow_phase * 1.15) * (1.4 + float(flow_level) * 0.45),
			maxf(0.30, intensity * 0.84)
		)
	_draw_light_streaks(int(profile.get("light_streaks", 0)), intensity)
	_draw_scene_reactors(int(profile.get("scene_reactors", 0)), intensity)
	_draw_tailwind_waves(int(profile.get("tailwind_waves", 0)), intensity)

func _water_line(y_factor: float, amplitude: float, phase_offset: float, x_start: float = 0.08, x_end: float = 0.92) -> PackedVector2Array:
	var points := PackedVector2Array()
	for segment: int in range(13):
		var t := float(segment) / 12.0
		var x := lerpf(size.x * x_start, size.x * x_end, t)
		var y := size.y * y_factor + sin(t * TAU * 1.15 + phase_offset) * amplitude
		points.append(Vector2(x, y))
	return points

func _draw_surface_ripples(count: int, intensity: float) -> void:
	for ripple: int in range(count):
		var center := Vector2(size.x * (0.18 + float(ripple) * 0.31), size.y * (0.43 + float(ripple % 2) * 0.15))
		var points := PackedVector2Array()
		for segment: int in range(9):
			var t := float(segment) / 8.0
			var x := center.x + lerpf(-15.0, 15.0 + float(flow_level) * 2.0, t)
			var y := center.y + sin(t * PI + flow_phase * 0.85 + float(ripple)) * 1.8
			points.append(Vector2(x, y))
		draw_polyline(points, Color(0.45, 0.84, 0.82, intensity * 0.74), 1.5, true)

func _draw_palms(sway: float, alpha: float) -> void:
	for side: float in [-1.0, 1.0]:
		var crown := Vector2(size.x * (0.08 if side < 0.0 else 0.92), size.y * 0.27)
		draw_line(crown + Vector2(0.0, 2.0), crown + Vector2(-side * 2.0, 27.0), Color(0.31, 0.38, 0.22, alpha * 0.82), 1.6, true)
		for leaf: int in range(5):
			var leaf_angle := lerpf(-2.65, -0.48, float(leaf) / 4.0)
			var leaf_length := 13.0 + float(leaf % 2) * 4.0
			var direction := Vector2(cos(leaf_angle) * side, sin(leaf_angle))
			var tip := crown + direction * leaf_length + Vector2(sway * (0.35 + float(leaf) * 0.12), 0.0)
			draw_line(crown, tip, Color(0.20, 0.48, 0.31, alpha), 1.5, true)

func _draw_light_streaks(count: int, intensity: float) -> void:
	for streak: int in range(count):
		var travel := fposmod(flow_phase * (34.0 + float(flow_level) * 5.0) + float(streak) * size.x * 0.48, size.x + 70.0) - 35.0
		var y := size.y * (0.50 + float(streak) * 0.13)
		var length := 38.0 + float(flow_level) * 5.0
		draw_line(Vector2(travel, y), Vector2(travel + length, y), Color(0.82, 0.96, 0.79, intensity * 0.62), 1.8, true)

func _draw_scene_reactors(count: int, intensity: float) -> void:
	if count <= 0:
		return
	var bob := sin(flow_phase * 1.4) * 1.7
	var boat_center := Vector2(size.x * 0.18, size.y * 0.73 + bob)
	draw_polyline(PackedVector2Array([boat_center + Vector2(-12.0, 0.0), boat_center + Vector2(-7.0, 5.0), boat_center + Vector2(9.0, 5.0), boat_center + Vector2(13.0, 0.0)]), Color(0.42, 0.29, 0.18, intensity * 0.64), 1.6, true)
	draw_line(boat_center + Vector2(0.0, 1.0), boat_center + Vector2(0.0, -15.0), Color(0.42, 0.29, 0.18, intensity * 0.58), 1.2, true)
	var sail_tip := boat_center + Vector2(8.0 + sin(flow_phase) * 2.0, -8.0)
	draw_colored_polygon(PackedVector2Array([boat_center + Vector2(1.0, -14.0), boat_center + Vector2(1.0, -2.0), sail_tip]), Color(0.88, 0.68, 0.35, intensity * 0.44))
	var cloth_anchor := Vector2(size.x * 0.88, size.y * 0.42)
	draw_line(cloth_anchor, cloth_anchor + Vector2(0.0, 18.0), Color(0.38, 0.30, 0.20, intensity * 0.55), 1.2, true)
	draw_line(cloth_anchor + Vector2(0.0, 3.0), cloth_anchor + Vector2(-13.0 + sin(flow_phase * 1.3) * 3.0, 8.0), Color(0.80, 0.42, 0.27, intensity * 0.58), 2.0, true)
	var bird_x := fposmod(flow_phase * 21.0, size.x * 0.28)
	var bird_center := Vector2(size.x * 0.62 + bird_x, size.y * 0.18)
	draw_arc(bird_center + Vector2(-4.0, 0.0), 4.0, PI * 1.05, PI * 1.82, 7, Color(0.29, 0.42, 0.40, intensity * 0.55), 1.2, true)
	draw_arc(bird_center + Vector2(4.0, 0.0), 4.0, PI * 1.18, PI * 1.95, 7, Color(0.29, 0.42, 0.40, intensity * 0.55), 1.2, true)

func _draw_tailwind_waves(count: int, intensity: float) -> void:
	for wave: int in range(count):
		var points := PackedVector2Array()
		var y_factor := 0.42 + float(wave) * 0.13
		for segment: int in range(15):
			var t := float(segment) / 14.0
			var x := size.x * (-0.05 + t * 1.10)
			var y := size.y * y_factor + sin(t * TAU * 1.25 + flow_phase * 0.78 + float(wave)) * 2.8
			points.append(Vector2(x, y))
		draw_polyline(points, Color(0.48, 0.88, 0.84, intensity * 0.38), 1.8, true)

func _draw_pulse_layer(event_type: StringName, progress: float, intensity: float) -> void:
	var pulse_alpha := sin(progress * PI) * maxf(intensity, 0.62)
	if event_type == &"die_stopped":
		var anchor := Vector2(size.x * 0.20, size.y * 0.58)
		for ring: int in range(3):
			draw_arc(anchor, 5.0 + float(ring) * 4.5 + progress * 9.0, 0.0, TAU, 22, Color(0.52, 0.91, 0.87, pulse_alpha * (0.65 - float(ring) * 0.12)), 1.4, true)
	elif event_type == &"role_resolved":
		var spread := lerpf(size.x * 0.18, size.x * 0.82, progress)
		for line_index: int in range(2):
			var y := size.y * (0.49 + float(line_index) * 0.12)
			draw_line(Vector2(size.x * 0.14, y), Vector2(spread, y), Color(0.90, 0.98, 0.78, pulse_alpha * 0.72), 2.0, true)
	elif event_type == &"flow_broken":
		# One calm line briefly replaces the moving waves, then processing stops.
		for line_index: int in range(3):
			var y := size.y * (0.45 + float(line_index) * 0.11)
			draw_line(Vector2(size.x * 0.10, y), Vector2(size.x * 0.90, y), Color(0.57, 0.85, 0.82, pulse_alpha * 0.48), 1.4, true)
