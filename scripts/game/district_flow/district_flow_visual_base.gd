class_name DistrictFlowVisualBase
extends Control

## Shared lifecycle for district-owned FLOW visuals.
##
## Subclasses own every drawn shape. This base only manages the shared level,
## active/hidden processing, and short presentation pulses.

const FLOW_INTENSITIES: Array[float] = [0.0, 0.22, 0.35, 0.52, 0.70, 0.86]
const DEFAULT_PULSE_DURATION := 0.34

var district_id: StringName = &""
var flow_level: int = 0
var flow_phase: float = 0.0
var pulse_elapsed: float = 0.0
var pulse_event_type: StringName = &""
var pulse_count: int = 0
var district_active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_processing()

static func flow_visual_strength(level: int) -> Dictionary:
	var clamped := clampi(level, 0, 5)
	return {
		"level": clamped,
		"intensity": FLOW_INTENSITIES[clamped],
		"map_motion": 0.0 if clamped < 5 else 0.35,
		"slot_glow": 0.0 if clamped < 3 else (0.18 if clamped < 5 else 0.30),
	}

func configure_district(value: StringName) -> void:
	district_id = value
	queue_redraw()

func set_district_active(active: bool) -> void:
	district_active = active
	visible = district_active
	if not district_active:
		_clear_pulse()
	_refresh_processing()
	queue_redraw()

func set_flow_visual_level(level: int) -> void:
	flow_level = clampi(level, 0, 5)
	if flow_level == 0:
		_clear_pulse()
	_refresh_processing()
	queue_redraw()

func play_flow_pulse(event_type: StringName) -> void:
	var next_event := StringName(str(event_type))
	if not district_active:
		return
	if not _accepts_pulse(next_event):
		if next_event == &"flow_broken":
			_clear_pulse()
			_refresh_processing()
			queue_redraw()
		return
	if flow_level <= 0 and not _allows_zero_flow_pulse(next_event):
		return
	pulse_event_type = next_event
	pulse_elapsed = 0.0
	pulse_count += 1
	_refresh_processing()
	queue_redraw()

func receipt() -> Dictionary:
	return {
		"district_id": district_id,
		"district_active": district_active,
		"visible": visible,
		"flow_level": flow_level,
		"processing": is_processing(),
		"pulse_count": pulse_count,
		"pulse_event_type": pulse_event_type,
	}

func _refresh_processing() -> void:
	set_process(district_active and (flow_level > 0 or pulse_event_type != &""))

func _clear_pulse() -> void:
	pulse_elapsed = 0.0
	pulse_event_type = &""

func _process(delta: float) -> void:
	if not district_active:
		return
	if flow_level > 0:
		flow_phase = fmod(flow_phase + delta * (0.48 + float(flow_level) * 0.18), TAU)
	if pulse_event_type != &"":
		pulse_elapsed += delta
		if pulse_elapsed >= _pulse_duration(pulse_event_type):
			_clear_pulse()
			_refresh_processing()
	queue_redraw()

func _draw() -> void:
	if not district_active:
		return
	_draw_static_layer()
	var intensity := float(flow_visual_strength(flow_level).get("intensity", 0.0))
	if flow_level > 0:
		_draw_flow_layer(intensity)
	if pulse_event_type != &"" and pulse_elapsed > 0.0:
		var duration := maxf(0.01, _pulse_duration(pulse_event_type))
		_draw_pulse_layer(pulse_event_type, clampf(pulse_elapsed / duration, 0.0, 1.0), intensity)

func _accepts_pulse(_event_type: StringName) -> bool:
	return true

func _allows_zero_flow_pulse(_event_type: StringName) -> bool:
	return false

func _pulse_duration(_event_type: StringName) -> float:
	return DEFAULT_PULSE_DURATION

func _draw_static_layer() -> void:
	pass

func _draw_flow_layer(_intensity: float) -> void:
	pass

func _draw_pulse_layer(_event_type: StringName, _progress: float, _intensity: float) -> void:
	pass
