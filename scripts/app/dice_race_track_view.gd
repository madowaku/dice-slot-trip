class_name DiceRaceTrackView
extends Control

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
	5: {"text": "5  狐火  -2", "color": Color("#b93d32")},
	10: {"text": "10  急流  +3", "color": Color("#2e7ca7")},
	15: {"text": "15  丸太  4+", "color": Color("#765334")},
	20: {"text": "20  狐火  -2", "color": Color("#b93d32")},
}

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
var _lane: Panel
var _start_label: Label
var _goal_label: Label
var _visuals: Dictionary = {}
var _base_positions: Dictionary = {}


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


func reset_camera() -> void:
	if _camera_tween != null:
		_camera_tween.kill()
	camera_section = 0
	camera_min_position = SECTION_MINIMUMS[0]
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


func _build_course() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#e7c477")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_lane = Panel.new()
	_lane.add_theme_stylebox_override("panel", _panel(Color("#bd8748"), Color("#8e5e2f"), 30, 3))
	_lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lane)

	for position: int in range(GOAL + 1):
		var tick := Label.new()
		tick.text = str(position)
		tick.add_theme_font_override("font", FONT)
		tick.add_theme_font_size_override("font_size", 17)
		tick.add_theme_color_override("font_color", Color("#66431f"))
		tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tick.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tick)
		tick_labels[position] = tick

	_start_label = _milestone_label("START", Color("#397649"))
	_goal_label = _milestone_label("GOAL", Color("#9f322b"))
	add_child(_start_label)
	add_child(_goal_label)

	for position: int in GIMMICKS:
		var data: Dictionary = GIMMICKS[position]
		var marker := _milestone_label(str(data.text), data.color)
		marker.name = "Gimmick_%d" % position
		add_child(marker)
		gimmick_markers[position] = marker

	for racer_id: String in RACERS:
		var marker := _make_racer_marker(racer_id)
		add_child(marker)
		racer_nodes[racer_id] = marker
		race_positions[racer_id] = 0


func _make_racer_marker(racer_id: String) -> Control:
	var marker := Control.new()
	marker.name = "Racer_%s" % racer_id
	marker.custom_minimum_size = Vector2(100, 88)
	marker.size = Vector2(100, 88)
	marker.z_index = 8
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var visual := PanelContainer.new()
	visual.size = marker.size
	visual.pivot_offset = marker.size * 0.5
	visual.add_theme_stylebox_override("panel", _racer_style(racer_id, false))
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(visual)
	_visuals[racer_id] = visual

	var portrait := TextureRect.new()
	portrait.texture = load(str(RACER_ART_PATHS[racer_id])) as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(88, 78)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(portrait)

	var name := Label.new()
	name.text = RACER_LABELS[racer_id]
	name.add_theme_font_override("font", FONT)
	name.add_theme_font_size_override("font_size", 14)
	name.add_theme_color_override("font_color", Color("#2d2118"))
	name.add_theme_color_override("font_outline_color", Color("#fff5dc"))
	name.add_theme_constant_override("outline_size", 4)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.anchor_left = 0.05
	name.anchor_right = 0.95
	name.anchor_top = 0.72
	name.anchor_bottom = 1.0
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(name)
	return marker


func _refresh_racer_styles() -> void:
	for racer_id: String in RACERS:
		var visual := _visuals.get(racer_id) as PanelContainer
		if visual != null:
			visual.add_theme_stylebox_override("panel", _racer_style(racer_id, wager_active and racer_id == selected_racer))


func _layout_course(animate_racers: bool = false) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or _lane == null:
		return
	var center_x := size.x * 0.50
	var lane_width := minf(210.0, size.x * 0.46)
	_lane.position = Vector2(center_x - lane_width * 0.5, 24)
	_lane.size = Vector2(lane_width, size.y - 48)

	for position: int in tick_labels:
		var tick := tick_labels[position] as Label
		var visible_now := _position_is_visible(float(position))
		tick.visible = visible_now and position not in GIMMICKS and position not in [0, GOAL]
		if tick.visible:
			tick.position = Vector2(center_x - lane_width * 0.5 - 58, _position_to_y(float(position)) - 16)
			tick.size = Vector2(44, 32)

	_layout_milestone(_start_label, 0, center_x, lane_width)
	_layout_milestone(_goal_label, GOAL, center_x, lane_width)
	for position: int in gimmick_markers:
		_layout_milestone(gimmick_markers[position] as Label, position, center_x, lane_width)
	_layout_racers(center_x, animate_racers)


func _layout_milestone(label: Label, position: int, center_x: float, lane_width: float) -> void:
	label.visible = _position_is_visible(float(position))
	if not label.visible:
		return
	label.position = Vector2(center_x + lane_width * 0.5 + 12, _position_to_y(float(position)) - 27)
	label.size = Vector2(minf(160, size.x - label.position.x - 8), 54)


func _layout_racers(center_x: float, animate_racers: bool) -> void:
	var groups: Dictionary = {}
	for racer_id: String in RACERS:
		var position := int(race_positions.get(racer_id, 0))
		if not groups.has(position):
			groups[position] = []
		(groups[position] as Array).append(racer_id)

	for racer_id: String in RACERS:
		var marker := racer_nodes.get(racer_id) as Control
		var position := int(race_positions.get(racer_id, 0))
		marker.visible = _position_is_visible(float(position))
		if not marker.visible:
			continue
		var peers: Array = groups[position]
		var peer_index := peers.find(racer_id)
		var offset := (float(peer_index) - float(peers.size() - 1) * 0.5) * 42.0
		var target := Vector2(center_x + offset - marker.size.x * 0.5, _position_to_y(float(position)) - marker.size.y * 0.5)
		_base_positions[racer_id] = target
		if animate_racers and marker.position != target:
			var movement := create_tween().set_parallel(true)
			movement.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			movement.tween_property(marker, "position", target, 0.38)
			var visual := _visuals[racer_id] as Control
			visual.scale = Vector2.ONE
			var bounce := create_tween()
			bounce.tween_property(visual, "scale", Vector2(1.06, 0.94), 0.18)
			bounce.tween_property(visual, "scale", Vector2.ONE, 0.20)
		else:
			marker.position = target


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
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", _panel(color, Color("#fff0b8"), 13, 2))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _racer_style(racer_id: String, selected: bool) -> StyleBoxFlat:
	var color: Color = RACER_COLORS[racer_id]
	return _panel(Color("#fff0cf"), Color("#fff1a6") if selected else color, 18, 6 if selected else 3)


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
