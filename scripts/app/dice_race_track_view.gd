class_name DiceRaceTrackView
extends Control

signal visible_range_changed(value: Vector2)
signal rank_changed(racer_id: String, previous_rank: int, next_rank: int)

const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const GOAL := 24
const VISIBLE_SPAN := 9.0
const SECTION_MINIMUMS := [0.0, 5.0, 11.0, 15.0]
const RACERS: Array[String] = ["camel", "rabbit", "fox", "duck", "dinosaur", "robot"]
const RACER_LABELS := {
	"camel": "ラクダ", "rabbit": "ウサギ", "fox": "キツネ",
	"duck": "アヒル", "dinosaur": "恐竜", "robot": "ロボット",
}
const RACER_COLORS := {
	"camel": Color("#3979bf"), "rabbit": Color("#d65345"),
	"fox": Color("#d96f2b"), "duck": Color("#e0a918"),
	"dinosaur": Color("#6c9f45"), "robot": Color("#5d99a5"),
}
const RACER_ART_PATHS := {
	"camel": "res://assets/casino/dice_race/racers/camel.png",
	"rabbit": "res://assets/casino/dice_race/racers/rabbit.png",
	"fox": "res://assets/casino/dice_race/racers/fox.png",
	"duck": "res://assets/casino/dice_race/racers/duck.png",
	"dinosaur": "res://assets/casino/dice_race/racers/dinosaur.png",
	"robot": "res://assets/casino/dice_race/racers/robot.png",
}
const GIMMICKS := {
	5: {"kind": "foxfire", "text": "-2", "color": Color("#b93d32")},
	10: {"kind": "rapid", "text": "+3", "color": Color("#2e7ca7")},
	15: {"kind": "log", "text": "STOP", "color": Color("#765334")},
	20: {"kind": "foxfire", "text": "-2", "color": Color("#b93d32")},
}
const TRACK_BACKGROUND_PATH := "res://assets/casino/dice_race/ui/desert-track-bg-v1.png"
const GATE_ART_PATHS := {
	"StartGate": "res://assets/casino/dice_race/ui/start-gate.png",
	"GoalGate": "res://assets/casino/dice_race/ui/goal-arch.png",
}
const GIMMICK_ART_PATHS := {
	"foxfire": "res://assets/casino/dice_race/ui/foxfire-gimmick.png",
	"rapid": "res://assets/casino/dice_race/ui/rapid-gimmick.png",
	"log": "res://assets/casino/dice_race/ui/log-gimmick.png",
}
const RACER_LANE_SLOTS := {
	"camel": -0.38, "rabbit": 0.30, "fox": -0.22,
	"duck": 0.14, "dinosaur": -0.06, "robot": 0.42,
}
const GOLD := Color("#f2bf4c")
const FINAL_STRETCH_SPACE := 18

var racer_nodes: Dictionary = {}
var gimmick_markers: Dictionary = {}
var tick_labels: Dictionary = {}
var race_positions: Dictionary = {}
var selected_racer := "duck"
var wager_active := false
var camera_section := 0
var camera_basis_racer := "duck"
var camera_min_position := 0.0
var _camera_tween: Tween
var _idle_time := 0.0
var _previous_positions := {}
var _portraits: Dictionary = {}
var _last_ranks: Dictionary = {}
var _lane: Panel
var _course_background: TextureRect
var _arena_glow: Panel
var _spotlight: Panel
var _left_rail: Panel
var _right_rail: Panel
var _center_line: ColorRect
var _final_stretch: Panel
var _start_gate: Control
var _goal_gate: Control
var _start_label: Label
var _goal_label: Label
var _visuals: Dictionary = {}
var gimmick_tags: Dictionary = {}
var _base_positions: Dictionary = {}
var _goal_light_tween: Tween
var _winner_racer: String = ""


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_course()
	resized.connect(_layout_course)
	call_deferred("_layout_course")


func _process(delta: float) -> void:
	_idle_time += delta
	for index: int in RACERS.size():
		var racer_id := RACERS[index]
		var visual := _visuals.get(racer_id) as Control
		if visual != null:
			visual.position.y = sin(_idle_time * 2.1 + float(index) * 0.75) * 3.0


func set_race_state(positions: Dictionary, bet_racer: String, active: bool, animate: bool = false) -> void:
	_previous_positions = race_positions.duplicate()
	race_positions = positions.duplicate()
	selected_racer = bet_racer
	wager_active = active
	camera_basis_racer = bet_racer
	_refresh_racer_styles()
	var next_section := _section_for_position(int(race_positions.get(bet_racer, 0)))
	if next_section != camera_section:
		camera_section = next_section
		_tween_camera_to(SECTION_MINIMUMS[camera_section])
	else:
		_layout_course(animate)
	_detect_rank_changes()
	var stretch_active := int(race_positions.get(bet_racer, 0)) >= FINAL_STRETCH_SPACE or (
		not race_positions.is_empty() and int(race_positions.values().max()) >= FINAL_STRETCH_SPACE)
	_set_goal_light(stretch_active and active)


func reset_camera() -> void:
	if _camera_tween != null:
		_camera_tween.kill()
	_winner_racer = ""
	camera_section = 0
	camera_min_position = SECTION_MINIMUMS[0]
	_refresh_racer_styles()
	_layout_course()
	_set_goal_light(false)
	visible_range_changed.emit(visible_range_for_test())


func set_winner_presentation(racer_id: String) -> void:
	_winner_racer = racer_id if racer_id in RACERS else ""
	_refresh_racer_styles()
	_layout_course()


func camera_section_for_test() -> int:
	return camera_section


func visible_range_for_test() -> Vector2:
	return Vector2(camera_min_position, camera_min_position + VISIBLE_SPAN)


func logical_y_for_test(position: int) -> float:
	return _position_to_y(float(position))


func _section_for_position(position: int) -> int:
	if position >= 18:
		return 3
	if position >= 12:
		return 2
	if position >= 6:
		return 1
	return 0


func _tween_camera_to(value: float) -> void:
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_method(_set_camera_minimum, camera_min_position, value, 0.36)


func _set_camera_minimum(value: float) -> void:
	camera_min_position = value
	_layout_course()
	visible_range_changed.emit(visible_range_for_test())


func _build_course() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#181228")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_course_background = TextureRect.new()
	_course_background.name = "CourseArt"
	_course_background.texture = load(TRACK_BACKGROUND_PATH) as Texture2D
	_course_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_course_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_course_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_course_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_course_background)

	_arena_glow = Panel.new()
	_arena_glow.add_theme_stylebox_override("panel", _panel(Color("#43235538"), Color.TRANSPARENT, 0, 0))
	_arena_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arena_glow)

	_spotlight = Panel.new()
	_spotlight.add_theme_stylebox_override("panel", _panel(Color("#f7d38a2e"), Color.TRANSPARENT, 24, 0))
	_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spotlight)

	_lane = Panel.new()
	_lane.name = "RaceLane"
	_lane.add_theme_stylebox_override("panel", _panel(Color("#d9a55e18"), Color("#f6d68f88"), 20, 2))
	_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lane)

	_left_rail = Panel.new()
	_left_rail.add_theme_stylebox_override("panel", _panel(Color("#8c5c3170"), Color("#f2bf4ca0"), 3, 1))
	_right_rail = Panel.new()
	_right_rail.add_theme_stylebox_override("panel", _panel(Color("#8c5c3170"), Color("#f2bf4ca0"), 3, 1))
	_center_line = ColorRect.new()
	_center_line.color = Color(1.0, 0.94, 0.75, 0.16)
	for node: Control in [_left_rail, _right_rail, _center_line]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(node)

	_final_stretch = Panel.new()
	_final_stretch.name = "FinalStretch"
	_final_stretch.modulate = Color(0.78, 0.74, 0.82, 0.72)
	_final_stretch.add_theme_stylebox_override("panel", _panel(Color("#9f322b30"), GOLD, 8, 1))
	_final_stretch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_final_stretch)

	for position: int in range(GOAL + 1):
		var tick := Label.new()
		tick.text = str(position)
		tick.add_theme_font_override("font", FONT)
		tick.add_theme_font_size_override("font_size", 17)
		tick.add_theme_color_override("font_color", Color("#d8c9b1"))
		tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tick.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tick)
		tick_labels[position] = tick

	_start_label = _milestone_label("START", Color("#397649"))
	_goal_label = _milestone_label("GOAL", Color("#9f322b"))
	_start_gate = _make_race_gate("START", "StartGate", Color("#397649"))
	_goal_gate = _make_race_gate("GOAL", "GoalGate", Color("#9f322b"))
	add_child(_start_label)
	add_child(_goal_label)
	_start_label.visible = false
	_goal_label.visible = false
	add_child(_start_gate)
	add_child(_goal_gate)

	for position: int in GIMMICKS:
		var data: Dictionary = GIMMICKS[position]
		var marker := _make_gimmick_object(str(data.kind), str(data.text), data.color)
		marker.name = "Gimmick_%d" % position
		add_child(marker)
		gimmick_markers[position] = marker
		var tag := _milestone_label(str(data.text), data.color)
		tag.name = "GimmickTag_%d" % position
		add_child(tag)
		tag.visible = false
		gimmick_tags[position] = tag

	for racer_id: String in RACERS:
		var marker := _make_racer_marker(racer_id)
		add_child(marker)
		racer_nodes[racer_id] = marker
		race_positions[racer_id] = 0


func _make_racer_marker(racer_id: String) -> Control:
	var marker := Control.new()
	marker.name = "Racer_%s" % racer_id
	marker.custom_minimum_size = Vector2(118, 106)
	marker.size = Vector2(118, 106)
	marker.z_index = 8
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shadow := Panel.new()
	shadow.name = "RacerShadow"
	shadow.position = Vector2(23, 88)
	shadow.size = Vector2(72, 16)
	shadow.pivot_offset = shadow.size * 0.5
	shadow.add_theme_stylebox_override("panel", _panel(Color(0, 0, 0, 0.34), Color.TRANSPARENT, 8, 0))
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(shadow)

	var ring := Panel.new()
	ring.name = "BetHighlight"
	ring.position = Vector2(13, 6)
	ring.size = Vector2(92, 92)
	ring.pivot_offset = ring.size * 0.5
	ring.visible = false
	ring.add_theme_stylebox_override("panel", _panel(Color(1.0, 0.86, 0.45, 0.10), GOLD, 46, 3))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(ring)

	var crown := Label.new()
	crown.name = "BetCrown"
	crown.text = "★"
	crown.position = Vector2(49, -6)
	crown.size = Vector2(20, 22)
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crown.add_theme_font_override("font", FONT)
	crown.add_theme_font_size_override("font_size", 15)
	crown.add_theme_color_override("font_color", Color("#ffe6a0"))
	crown.add_theme_color_override("font_outline_color", Color("#3f2408"))
	crown.add_theme_constant_override("outline_size", 4)
	crown.visible = false
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(crown)

	var visual := TextureRect.new()
	visual.name = "RacerPortrait"
	visual.texture = load(str(RACER_ART_PATHS[racer_id])) as Texture2D
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.size = marker.size
	visual.pivot_offset = marker.size * 0.5
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visuals[racer_id] = visual
	_portraits[racer_id] = visual
	marker.add_child(visual)

	var name := Label.new()
	name.text = RACER_LABELS[racer_id]
	name.add_theme_font_override("font", FONT)
	name.add_theme_font_size_override("font_size", 10)
	name.add_theme_color_override("font_color", Color("#fff7df"))
	name.add_theme_color_override("font_outline_color", Color("#241526"))
	name.add_theme_constant_override("outline_size", 4)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.anchor_left = 0.05
	name.anchor_right = 0.95
	name.anchor_top = 0.82
	name.anchor_bottom = 1.0
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(name)
	return marker


func _refresh_racer_styles() -> void:
	for racer_id: String in RACERS:
		var selected := wager_active and racer_id == selected_racer
		var winner := racer_id == _winner_racer
		var marker := racer_nodes.get(racer_id) as Control
		if marker != null:
			var ring := marker.find_child("BetHighlight", true, false) as Panel
			if ring != null:
				ring.visible = selected or winner
			var crown := marker.find_child("BetCrown", true, false) as Label
			if crown != null:
				crown.visible = selected or winner
		var portrait := _portraits.get(racer_id) as TextureRect
		if portrait != null:
			portrait.pivot_offset = portrait.size * 0.5
			portrait.scale = Vector2.ONE * (1.18 if winner else (1.13 if selected else 1.0))


func _layout_course(animate_racers: bool = false) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or _lane == null:
		return
	var center_x := size.x * 0.50
	var lane_width := clampf(size.x * 0.64, 148.0, 232.0)
	var lane_left := center_x - lane_width * 0.5
	var lane_right := center_x + lane_width * 0.5
	_lane.position = Vector2(center_x - lane_width * 0.5, 24)
	_lane.size = Vector2(lane_width, size.y - 48)
	if _spotlight != null:
		_spotlight.position = Vector2(lane_left - 16.0, 8.0)
		_spotlight.size = Vector2(lane_width + 32.0, size.y - 16.0)
	if _left_rail != null:
		_left_rail.position = Vector2(lane_left - 3.0, 30.0)
		_left_rail.size = Vector2(4.0, size.y - 60.0)
	if _right_rail != null:
		_right_rail.position = Vector2(lane_right - 1.0, 30.0)
		_right_rail.size = Vector2(4.0, size.y - 60.0)
	if _center_line != null:
		_center_line.position = Vector2(center_x - 1.5, 34.0)
		_center_line.size = Vector2(3.0, size.y - 68.0)
	if _final_stretch != null:
		var stretch_visible := _position_is_visible(18.0) or _position_is_visible(float(GOAL))
		_final_stretch.visible = stretch_visible
		if stretch_visible:
			_final_stretch.position = Vector2(lane_left + 5.0, _position_to_y(24.0))
			_final_stretch.size = Vector2(lane_width - 10.0, maxf(0.0, _position_to_y(18.0) - _position_to_y(24.0)))

	for position: int in tick_labels:
		var tick := tick_labels[position] as Label
		var visible_now := _position_is_visible(float(position))
		tick.visible = visible_now and position not in GIMMICKS and position not in [0, GOAL]
		if tick.visible:
			tick.position = Vector2(center_x - lane_width * 0.5 - 58, _position_to_y(float(position)) - 16)
			tick.size = Vector2(44, 32)

	_layout_race_gate(_start_gate, 0, lane_left, lane_right)
	_layout_race_gate(_goal_gate, GOAL, lane_left, lane_right)
	for position: int in gimmick_markers:
		_layout_gimmick_object(gimmick_markers[position] as Control, position, center_x)
	_layout_racers(center_x, lane_width, animate_racers)


func _detect_rank_changes() -> void:
	var ordered: Array[String] = RACERS.duplicate()
	ordered.sort_custom(func(a: String, b: String) -> bool:
		return int(race_positions.get(a, 0)) > int(race_positions.get(b, 0)))
	for racer_id: String in RACERS:
		var next_rank := ordered.find(racer_id) + 1
		var previous_rank := int(_last_ranks.get(racer_id, next_rank))
		if next_rank != previous_rank:
			rank_changed.emit(racer_id, previous_rank, next_rank)
		_last_ranks[racer_id] = next_rank


func _layout_milestone(label: Label, position: int, center_x: float, lane_width: float) -> void:
	label.visible = _position_is_visible(float(position))
	if not label.visible:
		return
	label.position = Vector2(center_x + lane_width * 0.5 + 12, _position_to_y(float(position)) - 27)
	label.size = Vector2(minf(160, size.x - label.position.x - 8), 54)


func _set_goal_light(active: bool) -> void:
	if _final_stretch == null:
		return
	if _goal_light_tween != null:
		_goal_light_tween.kill()
		_goal_light_tween = null
	var target := Color.WHITE if active else Color(0.78, 0.74, 0.82, 0.72)
	_goal_light_tween = create_tween()
	_goal_light_tween.tween_property(_final_stretch, "modulate", target, 0.22)


func _make_race_gate(text: String, node_name: String, _color: Color) -> Control:
	var gate := Control.new()
	gate.name = node_name
	gate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gate.set_meta("gate_height", 90.0 if node_name == "GoalGate" else 72.0)
	var art := TextureRect.new()
	art.name = "GateArt"
	art.texture = load(str(GATE_ART_PATHS.get(node_name, ""))) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gate.add_child(art)
	var label := Label.new()
	label.name = "GateLabel"
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 20 if node_name == "GoalGate" else 16)
	label.add_theme_color_override("font_color", Color("#fff1c4"))
	label.add_theme_color_override("font_outline_color", Color("#3b1a14" if node_name == "GoalGate" else "#10284b"))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gate.add_child(label)
	return gate


func _make_gimmick_object(kind: String, caption: String, _color: Color) -> Control:
	var object := Control.new()
	object.name = "GimmickObject"
	object.custom_minimum_size = Vector2(144, 104)
	object.size = Vector2(144, 104)
	object.pivot_offset = object.size * 0.5
	object.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var visual := TextureRect.new()
	visual.name = "GimmickVisual"
	visual.texture = load(str(GIMMICK_ART_PATHS.get(kind, ""))) as Texture2D
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	object.add_child(visual)
	var label := Label.new()
	label.name = "GimmickCaption"
	label.text = caption
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#fff3c8"))
	label.add_theme_color_override("font_outline_color", Color("#281620"))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	object.add_child(label)
	return object


func _layout_race_gate(gate: Control, position: int, lane_left: float, lane_right: float) -> void:
	if gate == null:
		return
	gate.visible = _position_is_visible(float(position))
	if not gate.visible:
		return
	var gate_height := float(gate.get_meta("gate_height", 48.0))
	var gate_y := _position_to_y(float(position))
	if position == 0:
		gate_y -= gate_height + 20.0
	elif position == GOAL:
		gate_y -= 8.0
	else:
		gate_y -= gate_height * 0.5
	gate.position = Vector2(lane_left - 12.0, gate_y)
	gate.size = Vector2(lane_right - lane_left + 24.0, gate_height)


func _layout_gimmick_object(marker: Control, position: int, center_x: float) -> void:
	marker.visible = _position_is_visible(float(position))
	if not marker.visible:
		return
	marker.position = Vector2(center_x - marker.size.x * 0.5, _position_to_y(float(position)) - marker.size.y * 0.5)


func _layout_racers(center_x: float, lane_width: float, animate_racers: bool) -> void:
	var groups: Dictionary = {}
	for racer_id: String in RACERS:
		var position := int(race_positions.get(racer_id, 0))
		if not groups.has(position):
			groups[position] = []
		(groups[position] as Array).append(racer_id)

	for racer_id: String in RACERS:
		var marker := racer_nodes.get(racer_id) as Control
		var position := int(race_positions.get(racer_id, 0))
		var previous_position := int(_previous_positions.get(racer_id, position))
		var distance := absi(position - previous_position)
		marker.visible = _position_is_visible(float(position))
		if not marker.visible:
			continue
		var peers: Array = groups[position]
		var peer_index := peers.find(racer_id)
		var selected := wager_active and racer_id == selected_racer
		var stable_offset := float(RACER_LANE_SLOTS.get(racer_id, 0.0)) * lane_width
		var cluster_nudge := (float(peer_index) - float(peers.size() - 1) * 0.5) * 8.0
		var offset := stable_offset + cluster_nudge
		var racer_top_limit := 118.0 if position >= GOAL else 2.0
		var target_y := clampf(
			_position_to_y(float(position)) - marker.size.y * 0.5,
			racer_top_limit,
			maxf(2.0, size.y - marker.size.y - 2.0))
		var target := Vector2(center_x + offset - marker.size.x * 0.5, target_y)
		_base_positions[racer_id] = target
		if animate_racers and marker.position != target:
			var movement := create_tween().set_parallel(true)
			movement.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			movement.tween_property(marker, "position", target, clampf(0.26 + float(distance) * 0.045, 0.30, 0.52))
			if selected or racer_id == _winner_racer:
				marker.z_index = 18 if racer_id == _winner_racer else 12
			var visual := _visuals[racer_id] as Control
			visual.scale = Vector2.ONE
			var bounce := create_tween()
			var squash := clampf(1.04 + float(distance) * 0.012, 1.05, 1.14)
			bounce.tween_property(visual, "scale", Vector2(squash, 2.0 - squash), 0.18)
			bounce.tween_property(visual, "scale", Vector2.ONE, 0.20)
		else:
			marker.position = target
			marker.z_index = 18 if racer_id == _winner_racer else (12 if selected else 8)


func _position_is_visible(position: float) -> bool:
	return position >= camera_min_position - 0.15 and position <= camera_min_position + VISIBLE_SPAN + 0.15


func _position_to_y(position: float) -> float:
	var top := 48.0
	var bottom := maxf(size.y, 326.0) - 48.0
	var progress := (position - camera_min_position) / VISIBLE_SPAN
	return lerpf(bottom, top, progress)


func _milestone_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", _panel(color, Color("#fff0b880"), 9, 1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _racer_style(racer_id: String, selected: bool) -> StyleBoxFlat:
	var color: Color = RACER_COLORS[racer_id]
	return _panel(Color("#3a2638e8"), GOLD if selected else color, 16, 6 if selected else 3)


func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
