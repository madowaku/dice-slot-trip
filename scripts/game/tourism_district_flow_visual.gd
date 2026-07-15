class_name TourismDistrictFlowVisual
extends Control

## Thin coordinator for district-owned FLOW visuals.
##
## It distributes shared FLOW state and presentation pulses. Every drawn shape
## lives in a district-specific class under res://scripts/game/district_flow/.

const BaseFlowVisualScript = preload("res://scripts/game/district_flow/district_flow_visual_base.gd")
const DunesFlowVisualScript = preload("res://scripts/game/district_flow/dunes_flow_visual.gd")
const OasisFlowVisualScript = preload("res://scripts/game/district_flow/oasis_flow_visual.gd")
const VISUAL_SCRIPTS: Dictionary = {
	&"DUNES": DunesFlowVisualScript,
	&"OASIS": OasisFlowVisualScript,
}

var district_id: StringName = &""
var flow_level: int = 0
var coordinator_active: bool = true
var visuals: Dictionary = {}
var active_visual: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	_ensure_visuals()
	_sync_active_visual()

static func flow_visual_strength(level: int) -> Dictionary:
	return BaseFlowVisualScript.flow_visual_strength(level)

static func dunes_reaction_profile(level: int) -> Dictionary:
	return DunesFlowVisualScript.reaction_profile(level)

static func oasis_reaction_profile(level: int) -> Dictionary:
	return OasisFlowVisualScript.reaction_profile(level)

func set_district(value: StringName) -> void:
	district_id = StringName(str(value).to_upper())
	_ensure_visuals()
	_sync_active_visual()

func set_district_active(active: bool) -> void:
	coordinator_active = active
	visible = coordinator_active
	_ensure_visuals()
	_sync_active_visual()

func set_flow_visual_level(level: int) -> void:
	flow_level = clampi(level, 0, 5)
	_ensure_visuals()
	for visual: Control in visuals.values():
		visual.set_flow_visual_level(flow_level)

func play_flow_pulse(event_type: StringName) -> void:
	if is_instance_valid(active_visual):
		active_visual.play_flow_pulse(event_type)

func receipt() -> Dictionary:
	_ensure_visuals()
	var active_receipt: Dictionary = active_visual.receipt() if is_instance_valid(active_visual) else {
		"district_id": district_id,
		"district_active": false,
		"visible": false,
		"flow_level": flow_level,
		"processing": false,
		"pulse_count": 0,
		"pulse_event_type": &"",
	}
	active_receipt["supported"] = visuals.has(district_id)
	active_receipt["visual_count"] = visuals.size()
	active_receipt["coordinator_child_count"] = get_child_count()
	return active_receipt

func district_receipt(value: StringName) -> Dictionary:
	_ensure_visuals()
	var visual: Control = visuals.get(StringName(str(value).to_upper()))
	return visual.receipt() if is_instance_valid(visual) else {}

func _ensure_visuals() -> void:
	if not visuals.is_empty():
		return
	for visual_id: StringName in VISUAL_SCRIPTS:
		var visual: Control = VISUAL_SCRIPTS[visual_id].new()
		visual.name = "%sFlowVisual" % String(visual_id).capitalize()
		add_child(visual)
		visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.configure_district(visual_id)
		visual.set_district_active(false)
		visual.set_flow_visual_level(flow_level)
		visuals[visual_id] = visual

func _sync_active_visual() -> void:
	active_visual = null
	for visual_id: StringName in visuals:
		var visual: Control = visuals[visual_id]
		var should_activate := coordinator_active and visual_id == district_id
		visual.set_district_active(should_activate)
		visual.set_flow_visual_level(flow_level)
		if should_activate:
			active_visual = visual
