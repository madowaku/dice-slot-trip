class_name DiceRaceScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const OrientationScript = preload("res://scripts/game/dice_race_orientation.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const TrackViewScript = preload("res://scripts/app/dice_race_track_view.gd")
const MiniMapScript = preload("res://scripts/app/dice_race_mini_map.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const RACER_LABELS := {
	"camel": "ラクダ",
	"rabbit": "ウサギ",
	"fox": "キツネ",
	"duck": "アヒル",
	"dinosaur": "恐竜",
	"robot": "ロボット",
}
const RACER_COLORS := {
	"camel": Color("#3979bf"),
	"rabbit": Color("#d65345"),
	"fox": Color("#d96f2b"),
	"duck": Color("#e0a918"),
	"dinosaur": Color("#6c9f45"),
	"robot": Color("#5d99a5"),
}
# The art is optional in CI. When these PNGs exist, the UI automatically uses
# them; otherwise the same layout falls back to numbered mascot badges.
const RACER_ART_PATHS := {
	"camel": "res://assets/casino/dice_race/racers/camel.png",
	"rabbit": "res://assets/casino/dice_race/racers/rabbit.png",
	"fox": "res://assets/casino/dice_race/racers/fox.png",
	"duck": "res://assets/casino/dice_race/racers/duck.png",
	"dinosaur": "res://assets/casino/dice_race/racers/dinosaur.png",
	"robot": "res://assets/casino/dice_race/racers/robot.png",
}
const BET_AMOUNTS := [10, 20, 50]
const SPIN_STEP_SECONDS := 0.085
const DIRECTION_LABELS := {
	"top": "上", "bottom": "下", "front": "手前",
	"back": "奥", "left": "左", "right": "右",
}
const OPPOSITE_RACER_PAIRS := [
	["fox", "rabbit", "↕"],
	["duck", "dinosaur", "↔"],
	["camel", "robot", "↔"],
]

const GOLD := Color("#f2bf4c")
const GOLD_LIGHT := Color("#ffe6a0")
const INK := Color("#322315")
const CREAM := Color("#fff0cf")
const NAVY := Color("#171932")
const NAVY_2 := Color("#25234a")
const RED := Color("#9f322b")

var orientations: Array[Dictionary] = []
var race: Dictionary = {}
var selected_racer := "duck"
var selected_bet := 20
var spinning := false
var spin_elapsed := 0.0
var orientation_index := 0
var current_assignments: Dictionary = {}
var wager_committed := false
var result_recorded := false

var chip_label: Label
var bet_label: Label
var roll_count_label: Label
var win_label: Label
var status_label: Label
var ranking_label: Label
var assignment_label: Label
var target_value_label: Label
var die_face_label: Label
var die_panel: Control
var dice_presentation: DicePresentation3D
var dice_console: PanelContainer
var track: Control
var track_view: DiceRaceTrackView
var minimap: DiceRaceMiniMap
var racer_nodes := {}
var assignment_cards := {}
var direction_plates := {}
var opposite_pair_labels: Array[Label] = []
var opposite_pair_panels: Array[PanelContainer] = []
var last_stop_feedback_assignments := {}
var stop_feedback_count_for_test := 0
var ranking_cards: Array[Label] = []
var ranking_portraits: Array[TextureRect] = []
var roll_button: Button
var start_button: Button
var cashout_row: HBoxContainer
var cashout_label: Label
var cashout_button: Button
var ride_on_button: Button
var bet_panel: VBoxContainer
var setup_view: VBoxContainer
var race_view: VBoxContainer
var cashout_overlay: Control
var racer_buttons := {}
var amount_buttons := {}
var bet_portrait: TextureRect
var race_fx_layer: Control
var final_stretch_shown := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_node("/root/BgmManager").call("play_dice_race")
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_stage", &"las_vegas")
	orientations = OrientationScript.all_orientations()
	_build_ui()
	_show_bet_select()

func _process(delta: float) -> void:
	if not spinning or orientations.is_empty():
		return
	spin_elapsed += delta
	var next_index := int(floor(spin_elapsed / SPIN_STEP_SECONDS)) % orientations.size()
	if next_index != orientation_index:
		orientation_index = next_index
		current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
		_refresh_assignment_ui()
		_refresh_physical_die(0.0)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glow := ColorRect.new()
	glow.color = Color("#36213e")
	glow.anchor_right = 1.0
	glow.anchor_bottom = 0.46
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	_build_header(root)
	_build_status_row(root)

	status_label = _label("勝たせたいレーサーを選ぼう", 18, Color.WHITE)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 34
	root.add_child(status_label)

	setup_view = VBoxContainer.new()
	setup_view.name = "RaceSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 8)
	root.add_child(setup_view)
	_build_course_overview(setup_view)
	_build_bet_panel(setup_view)

	race_view = VBoxContainer.new()
	race_view.name = "RaceActiveView"
	race_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	race_view.add_theme_constant_override("separation", 7)
	root.add_child(race_view)
	_build_track(race_view)
	_build_ranking(race_view)
	_build_dice_console(race_view)

	roll_button = _button("ROLL", true)
	roll_button.name = "RollStopButton"
	roll_button.custom_minimum_size.y = 92
	roll_button.add_theme_font_size_override("font_size", 32)
	roll_button.pressed.connect(_on_roll_stop)
	race_view.add_child(roll_button)

	var effect_layer := Control.new()
	effect_layer.name = "RaceEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 24
	add_child(effect_layer)
	race_fx_layer = effect_layer

	var back := _button("カジノへ戻る")
	back.name = "CasinoBackButton"
	back.custom_minimum_size.y = 48
	back.pressed.connect(_on_back_pressed)
	root.add_child(back)

	_build_cashout()

func _build_header(root: VBoxContainer) -> void:
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 62
	header.add_theme_stylebox_override("panel", _panel(RED, GOLD, 22, 3))
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)
	var title := _label("DICE RACE", 34, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color("#4e1715"))
	title.add_theme_constant_override("outline_size", 5)
	row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.custom_minimum_size.x = 118
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 16, 2))
	chip_label = _label("CHIP 0", 16, Color("#fff4cd"))
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_status_row(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48
	row.add_theme_constant_override("separation", 7)
	root.add_child(row)
	var bet_box := _hud_box("BET", selected_racer)
	bet_label = bet_box.label
	bet_portrait = bet_box.portrait
	row.add_child(bet_box.panel)
	var roll_box := _hud_box("ROLL")
	roll_count_label = roll_box.label
	row.add_child(roll_box.panel)
	win_label = _label("", 1, Color.TRANSPARENT)
	win_label.visible = false
	row.add_child(win_label)

func _hud_box(caption: String, portrait_racer: String = "") -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6d995"), Color("#a96b2e"), 14, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var cap := _label(caption, 13, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value_row := HBoxContainer.new()
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.add_theme_constant_override("separation", 3)
	box.add_child(value_row)
	var portrait: TextureRect = null
	if not portrait_racer.is_empty():
		portrait = TextureRect.new()
		portrait.name = "BetPortrait"
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(24, 24)
		portrait.texture = _racer_art(portrait_racer)
		value_row.add_child(portrait)
	var value := _label("-", 18, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_row.add_child(value)
	return {"panel": panel, "label": value, "portrait": portrait}

func _build_course_overview(root: VBoxContainer) -> void:
	var overview := PanelContainer.new()
	overview.name = "CourseOverview"
	overview.custom_minimum_size.y = 330
	overview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overview.add_theme_stylebox_override("panel", _panel(Color("#21162bb0"), GOLD, 18, 3))
	root.add_child(overview)
	var course_art := TextureRect.new()
	course_art.name = "SetupCourseArt"
	course_art.texture = load("res://assets/casino/dice_race/ui/desert-track-bg-v1.png") as Texture2D
	course_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	course_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	course_art.modulate = Color(0.92, 0.86, 0.96, 1.0)
	course_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overview.add_child(course_art)
	var shade := ColorRect.new()
	shade.color = Color("#21162b42")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overview.add_child(shade)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	overview.add_child(box)
	var title := _label("PICK YOUR RACER", 32, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#2a1724"))
	title.add_theme_constant_override("outline_size", 5)
	box.add_child(title)
	var roster := HBoxContainer.new()
	roster.alignment = BoxContainer.ALIGNMENT_CENTER
	roster.add_theme_constant_override("separation", 5)
	box.add_child(roster)
	for racer_id: String in RaceScript.RACERS:
		var portrait := TextureRect.new()
		portrait.name = "SetupPortrait_%s" % racer_id
		portrait.texture = _racer_art(racer_id)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(100, 100)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		roster.add_child(portrait)
	var route := _label("24 GOAL · 狐火 -2 · 急流 +3 · 丸太 STOP", 20, Color("#fff2d2"))
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(route)
	var note := _label("推しを選んで、欲しい目を狙え", 19, Color("#f5cf78"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)


func _build_track(root: VBoxContainer) -> void:
	var track_frame := PanelContainer.new()
	track_frame.name = "VerticalRaceViewport"
	track_frame.custom_minimum_size.y = 560
	track_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_frame.size_flags_stretch_ratio = 1.6
	track_frame.add_theme_stylebox_override("panel", _panel(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	root.add_child(track_frame)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	track_frame.add_child(row)
	track_view = TrackViewScript.new()
	track_view.name = "RaceTrack"
	track_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(track_view)
	track = track_view
	racer_nodes = track_view.racer_nodes
	minimap = MiniMapScript.new()
	minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(minimap)
	track_view.visible_range_changed.connect(minimap.set_camera_range)
	minimap.set_camera_range(track_view.visible_range_for_test())
	track_view.rank_changed.connect(_on_track_rank_changed)

func _racer_art(racer_id: String) -> Texture2D:
	var path := str(RACER_ART_PATHS.get(racer_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _build_ranking(root: VBoxContainer) -> void:
	var ranking_panel := PanelContainer.new()
	ranking_panel.custom_minimum_size.y = 50
	ranking_panel.add_theme_stylebox_override("panel", _panel(Color("#17122100"), Color.TRANSPARENT, 0, 0))
	root.add_child(ranking_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	ranking_panel.add_child(row)
	for i in 3:
		var place := PanelContainer.new()
		place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var border: Color = [GOLD, Color("#c8cbd1"), Color("#c98754")][i]
		place.add_theme_stylebox_override("panel", _panel(Color("#30233e"), border, 8, 2))
		var place_row := HBoxContainer.new()
		place_row.alignment = BoxContainer.ALIGNMENT_CENTER
		place_row.add_theme_constant_override("separation", 3)
		place.add_child(place_row)
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(28, 28)
		place_row.add_child(portrait)
		ranking_portraits.append(portrait)
		var label := _label("%d位" % (i + 1), 16, Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		place_row.add_child(label)
		ranking_cards.append(label)
		row.add_child(place)
	ranking_label = _label("", 1, Color.TRANSPARENT)
	ranking_label.visible = false
	root.add_child(ranking_label)

func _build_dice_console(root: VBoxContainer) -> void:
	dice_console = PanelContainer.new()
	dice_console.name = "DiceDirectionConsole"
	dice_console.custom_minimum_size.y = 330
	dice_console.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_console.size_flags_stretch_ratio = 1.0
	dice_console.add_theme_stylebox_override("panel", _panel(Color("#171221"), Color("#7a5a31"), 12, 1))
	root.add_child(dice_console)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	dice_console.add_child(box)

	target_value_label = _label("BET・%s　現在の目 ?" % RACER_LABELS[selected_racer], 18, GOLD_LIGHT)
	target_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(target_value_label)

	var middle := HBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 6)
	box.add_child(middle)

	var compass := VBoxContainer.new()
	compass.name = "DieDirectionCompass"
	compass.custom_minimum_size.x = 430
	compass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compass.add_theme_constant_override("separation", 2)
	middle.add_child(compass)

	var top_center := CenterContainer.new()
	top_center.add_child(_make_direction_plate("fox", "top", Vector2(144, 44)))
	compass.add_child(top_center)

	var compass_middle := HBoxContainer.new()
	compass_middle.alignment = BoxContainer.ALIGNMENT_CENTER
	compass_middle.add_theme_constant_override("separation", 4)
	compass_middle.add_child(_make_direction_plate("camel", "left", Vector2(86, 142), true))
	die_panel = CenterContainer.new()
	die_panel.name = "PhysicalDie"
	die_panel.custom_minimum_size = Vector2(230, 170)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "RacePhysicalDie3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.dice_race_face_layout = true
	dice_presentation.custom_minimum_size = Vector2(230, 170)
	die_panel.add_child(dice_presentation)
	die_face_label = _label("?", 1, Color.TRANSPARENT)
	die_face_label.visible = false
	die_panel.add_child(die_face_label)
	compass_middle.add_child(die_panel)
	compass_middle.add_child(_make_direction_plate("robot", "right", Vector2(86, 142), true))
	compass.add_child(compass_middle)

	var bottom_center := CenterContainer.new()
	bottom_center.add_child(_make_direction_plate("duck", "front", Vector2(144, 44)))
	compass.add_child(bottom_center)

	var pairs := VBoxContainer.new()
	pairs.name = "OppositeFacePairs"
	pairs.custom_minimum_size.x = 190
	pairs.add_theme_constant_override("separation", 4)
	middle.add_child(pairs)
	var pairs_title := _label("↔ 7", 15, GOLD_LIGHT)
	pairs_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pairs.add_child(pairs_title)
	for pair: Array in OPPOSITE_RACER_PAIRS:
		pairs.add_child(_make_opposite_pair_row(str(pair[0]), str(pair[1]), str(pair[2])))
	_make_hidden_direction_target("rabbit", "bottom", pairs)
	_make_hidden_direction_target("dinosaur", "back", pairs)

	assignment_label = _label("止まった向きの数字で進む", 15, Color("#bdb4cb"))
	assignment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	assignment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(assignment_label)

func _make_direction_plate(racer_id: String, direction: String, minimum: Vector2, vertical := false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Direction_%s" % direction
	panel.custom_minimum_size = minimum
	panel.add_theme_stylebox_override("panel", _panel(Color.TRANSPARENT, Color.TRANSPARENT, 10, 0))
	var content: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 1 if vertical else 3)
	panel.add_child(content)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = _racer_art(racer_id)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(44, 44)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait)
	var caption := _label("%s %s" % [DIRECTION_LABELS[direction], RACER_LABELS[racer_id]], 14, Color("#fff2d2"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(caption)
	var value := _label("?", 28, Color("#fff2d2"))
	value.name = "DirectionValue"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(value)
	var entry := {"panel": panel, "label": value, "caption": caption, "portrait": portrait, "direction": direction}
	direction_plates[racer_id] = entry
	assignment_cards[racer_id] = entry
	return panel

func _make_opposite_pair_row(first_id: String, second_id: String, arrow: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 54
	panel.add_theme_stylebox_override("panel", _panel(Color.TRANSPARENT, Color.TRANSPARENT, 8, 0))
	var label := _label("%s ? %s ? %s" % [RACER_LABELS[first_id], arrow, RACER_LABELS[second_id]], 14, Color("#fff2d2"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	opposite_pair_labels.append(label)
	opposite_pair_panels.append(panel)
	return panel

func _make_hidden_direction_target(racer_id: String, direction: String, parent: Control) -> void:
	var target := Control.new()
	target.name = "Direction_%s_Target" % direction
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(target)
	direction_plates[racer_id] = {
		"panel": opposite_pair_panels[0 if racer_id == "rabbit" else 1],
		"label": opposite_pair_labels[0 if racer_id == "rabbit" else 1],
		"portrait": null,
		"direction": direction,
		"compact_pair": true,
	}
	assignment_cards[racer_id] = direction_plates[racer_id]

func _build_bet_panel(root: VBoxContainer) -> void:
	bet_panel = VBoxContainer.new()
	bet_panel.add_theme_constant_override("separation", 6)
	root.add_child(bet_panel)
	var racer_grid := GridContainer.new()
	racer_grid.columns = 3
	racer_grid.add_theme_constant_override("h_separation", 5)
	racer_grid.add_theme_constant_override("v_separation", 5)
	bet_panel.add_child(racer_grid)
	for racer_id: String in RaceScript.RACERS:
		var button := _button(RACER_LABELS[racer_id])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 50
		button.add_theme_font_size_override("font_size", 17)
		button.icon = _racer_art(racer_id)
		button.add_theme_constant_override("icon_max_width", 30)
		button.pressed.connect(_select_racer.bind(racer_id))
		racer_grid.add_child(button)
		racer_buttons[racer_id] = button
	var amount_row := HBoxContainer.new()
	amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_row.add_theme_constant_override("separation", 8)
	bet_panel.add_child(amount_row)
	for amount: int in BET_AMOUNTS:
		var button := _button("%d CHIP" % amount)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48
		button.pressed.connect(_select_bet.bind(amount))
		amount_row.add_child(button)
		amount_buttons[amount] = button
	start_button = _button("RACE START", true)
	start_button.name = "RaceStartButton"
	start_button.custom_minimum_size.y = 64
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.pressed.connect(_start_race)
	bet_panel.add_child(start_button)

func _build_cashout() -> void:
	cashout_overlay = ColorRect.new()
	cashout_overlay.name = "CashOutOverlay"
	cashout_overlay.color = Color(0.04, 0.035, 0.09, 0.86)
	cashout_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cashout_overlay.z_index = 30
	cashout_overlay.visible = false
	add_child(cashout_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cashout_overlay.add_child(center)
	var modal := PanelContainer.new()
	modal.custom_minimum_size = Vector2(324, 220)
	modal.add_theme_stylebox_override("panel", _panel(Color("#28223e"), GOLD, 18, 3))
	center.add_child(modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	modal.add_child(box)
	cashout_row = HBoxContainer.new()
	cashout_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cashout_row.add_theme_constant_override("separation", 8)
	var title := _label("CASH OUT?", 25, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	cashout_label = _label("", 16, GOLD_LIGHT)
	cashout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cashout_label)
	box.add_child(cashout_row)
	cashout_button = _button("CASH OUT")
	cashout_button.pressed.connect(_take_cashout)
	cashout_row.add_child(cashout_button)
	ride_on_button = _button("RIDE ON!", true)
	ride_on_button.pressed.connect(_ride_on)
	cashout_row.add_child(ride_on_button)

func _show_bet_select() -> void:
	race = RaceScript.new_race()
	spinning = false
	wager_committed = false
	result_recorded = false
	current_assignments.clear()
	setup_view.visible = true
	race_view.visible = false
	cashout_overlay.visible = false
	final_stretch_shown = false
	status_label.text = "勝たせたいレーサーを選ぼう"
	_refresh_bet_buttons()
	_refresh_all()

func _select_racer(racer_id: String) -> void:
	selected_racer = racer_id
	_play_ui_sfx(&"select", false)
	_refresh_bet_buttons()
	_refresh_assignment_ui()

func _select_bet(amount: int) -> void:
	selected_bet = amount
	_play_ui_sfx(&"select", false)
	_refresh_bet_buttons()

func _refresh_bet_buttons() -> void:
	var chips := CasinoBankScript.balance()
	for racer_id: String in racer_buttons:
		var button := racer_buttons[racer_id] as Button
		button.disabled = false
		button.text = ("● " if racer_id == selected_racer else "") + RACER_LABELS[racer_id]
		_apply_button_state(button, racer_id == selected_racer)
	if bet_portrait != null:
		bet_portrait.texture = _racer_art(selected_racer)
	for amount: int in amount_buttons:
		var button := amount_buttons[amount] as Button
		button.disabled = chips < amount
		button.text = ("● " if amount == selected_bet else "") + "%d CHIP" % amount
		_apply_button_state(button, amount == selected_bet)
	start_button.disabled = chips < selected_bet
	if start_button.disabled:
		status_label.text = "CHIPが足りない。通常ステージでCOINを持ち帰ろう。"

func _start_race() -> void:
	if not CasinoBankScript.spend_chips(selected_bet):
		_play_ui_sfx(&"blocked", false)
		_refresh_bet_buttons()
		return
	_play_ui_sfx(&"start", false)
	race = RaceScript.new_race(selected_racer, selected_bet)
	wager_committed = true
	result_recorded = false
	final_stretch_shown = false
	setup_view.visible = false
	race_view.visible = true
	track_view.reset_camera()
	roll_button.disabled = false
	cashout_row.visible = false
	status_label.text = "%sに%d CHIP。欲しい目を狙ってSTOP！" % [RACER_LABELS[selected_racer], selected_bet]
	spin_elapsed = randf() * SPIN_STEP_SECONDS * float(maxi(orientations.size(), 1))
	orientation_index = int(floor(spin_elapsed / SPIN_STEP_SECONDS)) % maxi(orientations.size(), 1)
	current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
	_refresh_all()

func _on_roll_stop() -> void:
	if not wager_committed or bool(race.get("finished", false)):
		return
	if not spinning:
		spinning = true
		_play_ui_sfx(&"start", false)
		roll_button.text = "STOP!"
		_apply_roll_button_style(true)
		status_label.text = "%sに欲しい数字を狙え！" % RACER_LABELS[selected_racer]
		return
	spinning = false
	_play_ui_sfx(&"stop", false)
	roll_button.text = "ROLL"
	roll_button.disabled = true
	_apply_roll_button_style(false)
	current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
	var stopped_assignments := current_assignments.duplicate()
	var was_photo_finish := not (race.get("photo_finish_candidates", []) as Array).is_empty()
	race = RaceScript.apply_roll(race, current_assignments)
	_play_roll_result_sfx()
	status_label.text = "PHOTO FINISH判定！" if was_photo_finish else _movement_summary()
	_refresh_all(true)
	_refresh_physical_die(0.18)
	_play_stop_assignment_feedback(stopped_assignments)
	_maybe_show_final_stretch()
	await get_tree().create_timer(0.34).timeout
	if not is_inside_tree():
		return
	_after_roll_resolution()
	if not bool(race.get("finished", false)) and not bool(race.get("cashout_offered", false)):
		roll_button.disabled = false

func _after_roll_resolution() -> void:
	if bool(race.get("finished", false)):
		_finish_race()
		return
	var photo: Array = race.get("photo_finish_candidates", [])
	if not photo.is_empty():
		status_label.text = "PHOTO FINISH！ 同着レーサーの数字で決着。"
		return
	if bool(race.get("cashout_offered", false)):
		cashout_overlay.visible = true
		roll_button.disabled = true
		cashout_label.text = "3投終了　今なら %d CHIP" % int(race.get("cashout_amount", 0))
		status_label.text = "降りる？ それとも優勝まで乗る？"

func _take_cashout() -> void:
	var amount := RaceScript.cashout_offer(race)
	race = RaceScript.take_cashout(race)
	CasinoBankScript.add_chips(amount)
	_play_ui_sfx(&"reward", true)
	cashout_overlay.visible = false
	roll_button.disabled = false
	status_label.text = "%d CHIPでCASH OUT。レースは最後まで見届けよう。" % amount
	_refresh_all()

func _ride_on() -> void:
	race = RaceScript.ride_on(race)
	_play_ui_sfx(&"streak", true)
	cashout_overlay.visible = false
	roll_button.disabled = false
	status_label.text = "RIDE ON！ 優勝なら%d CHIP。" % int(round(float(selected_bet) * RaceScript.WIN_MULTIPLIER))

func _finish_race():
	spinning = false
	roll_button.disabled = true
	var winner := str(race.get("winner", ""))
	var payout := RaceScript.winning_payout(race)
	_play_ui_sfx(&"complete" if winner == selected_racer else &"error", true)
	if payout > 0:
		CasinoBankScript.add_chips(payout)
		status_label.text = "%s WIN！ %d CHIP獲得！" % [RACER_LABELS.get(winner, winner), payout]
		_play_win_fx(RACER_ART_PATHS.get(winner, ""), RACER_LABELS.get(winner, winner), payout)
	elif bool(race.get("cashout_taken", false)):
		status_label.text = "%s WIN。CASH OUT済み。" % RACER_LABELS.get(winner, winner)
	else:
		status_label.text = "%s WIN。次は当てよう！" % RACER_LABELS.get(winner, winner)
	if not result_recorded:
		CasinoBankScript.record_dice_race(winner == selected_racer and payout > 0, payout)
		result_recorded = true
	roll_button.text = "もう一度"
	_apply_roll_button_style(false)
	roll_button.disabled = false
	if roll_button.pressed.is_connected(_on_roll_stop):
		roll_button.pressed.disconnect(_on_roll_stop)
	roll_button.pressed.connect(_restart_after_result, CONNECT_ONE_SHOT)
	_refresh_all()

func _restart_after_result() -> void:
	_play_ui_sfx(&"retry", false)
	if not roll_button.pressed.is_connected(_on_roll_stop):
		roll_button.pressed.connect(_on_roll_stop)
	roll_button.text = "ROLL"
	_apply_roll_button_style(false)
	_show_bet_select()

func _on_back_pressed() -> void:
	_play_ui_sfx(&"back", false)
	back_requested.emit()


func _on_track_rank_changed(racer_id: String, previous_rank: int, next_rank: int) -> void:
	if wager_committed and racer_id == selected_racer and next_rank < previous_rank:
		_play_ui_sfx(&"streak", true)
		_play_overtake_fx(previous_rank, next_rank)


func _maybe_show_final_stretch():
	if final_stretch_shown or not wager_committed:
		return
	var reached := false
	for racer_id: String in RaceScript.RACERS:
		var model_position := int((race.racers.get(racer_id, {}) as Dictionary).get("position", 0))
		var rendered_position := int(track_view.race_positions.get(racer_id, 0)) if track_view != null else 0
		reached = reached or maxi(model_position, rendered_position) >= 18
	if not reached:
		return
	final_stretch_shown = true
	_show_race_banner("FINAL STRETCH!", GOLD_LIGHT, Color("#3f2408"), 0.72, "FinalStretchBanner")


func _show_race_banner(text: String, color: Color, outline_color: Color, hold_seconds: float, node_name: String = "RaceBanner"):
	if race_fx_layer == null:
		return
	var banner := _label(text, 30, color)
	banner.name = node_name
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 28)
	banner.add_theme_color_override("font_outline_color", outline_color)
	banner.add_theme_constant_override("outline_size", 7)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	race_fx_layer.add_child(banner)
	banner.size = Vector2(minf(320.0, race_fx_layer.size.x - 24.0), 52)
	banner.position = Vector2(
		(race_fx_layer.size.x - banner.size.x) * 0.5,
		maxf(112.0, race_fx_layer.size.y * 0.24))
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.82, 0.82)
	banner.modulate.a = 0.0
	var intro := create_tween().set_parallel(true)
	intro.tween_property(banner, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(banner, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10)
	intro.chain().tween_interval(hold_seconds)
	intro.chain().tween_property(banner, "modulate:a", 0.0, 0.16)
	intro.chain().tween_callback(banner.queue_free)


func _play_overtake_fx(previous_rank: int, next_rank: int) -> void:
	if previous_rank <= next_rank:
		return
	_show_race_banner("%d → %d!" % [previous_rank, next_rank], GOLD_LIGHT, Color("#3f2408"), 0.42, "OvertakeBanner")
	for index: int in 6:
		_spawn_spark()

func _play_roll_result_sfx() -> void:
	var move: Dictionary = (race.get("last_movements", {}) as Dictionary).get(selected_racer, {})
	if bool(move.get("blocked_by_log", false)) or str(move.get("gimmick", "")) == "foxfire":
		_play_ui_sfx(&"warning", true)
	elif str(move.get("gimmick", "")) == "rapid":
		_play_ui_sfx(&"bonus", true)
	else:
		_play_ui_sfx(&"progress-step", true)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)


func _spawn_spark() -> void:
	if race_fx_layer == null:
		return
	var spark := Panel.new()
	spark.name = "OvertakeSpark"
	var diameter := randf_range(4.0, 8.0)
	spark.size = Vector2(diameter, diameter)
	spark.position = Vector2(randf_range(48.0, maxf(52.0, race_fx_layer.size.x - 56.0)), randf_range(180.0, 430.0))
	spark.pivot_offset = spark.size * 0.5
	spark.add_theme_stylebox_override("panel", _panel(GOLD_LIGHT, GOLD, int(maxi(2, int(diameter * 0.5))), 1))
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	race_fx_layer.add_child(spark)
	var flight := create_tween().set_parallel(true)
	flight.tween_property(spark, "position:y", spark.position.y - randf_range(18.0, 38.0), 0.36)
	flight.tween_property(spark, "modulate:a", 0.0, 0.24).set_delay(0.12)
	flight.chain().tween_callback(spark.queue_free)


func _play_win_fx(winner_art: Variant, winner_label: Variant, payout: int):
	if race_fx_layer == null:
		return
	var card := PanelContainer.new()
	card.name = "WinCard"
	card.add_theme_stylebox_override("panel", _panel(Color("#33203acc"), GOLD_LIGHT, 14, 2))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	race_fx_layer.add_child(card)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var art := TextureRect.new()
	art.texture = load(str(winner_art)) as Texture2D if str(winner_art) != "" else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(40, 40)
	row.add_child(art)
	row.add_child(_label("%s WIN!  +%d CHIP" % [str(winner_label), payout], 22, GOLD_LIGHT))
	card.reset_size()
	card.position = Vector2(
		(race_fx_layer.size.x - card.size.x) * 0.5,
		maxf(104.0, race_fx_layer.size.y * 0.20))
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.84, 0.84)
	var entrance := create_tween()
	entrance.tween_property(card, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for index: int in 26:
		var piece := ColorRect.new()
		piece.name = "ConfettiPiece"
		piece.size = Vector2(randf_range(4.0, 7.0), randf_range(7.0, 13.0))
		piece.color = [GOLD, GOLD_LIGHT, Color("#fff7df"), Color("#ffb46b")][index % 4]
		piece.rotation = randf_range(-PI, PI)
		piece.position = Vector2(randf_range(0.0, race_fx_layer.size.x), -18.0)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		race_fx_layer.add_child(piece)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(piece, "position:y", race_fx_layer.size.y + 24.0, randf_range(1.05, 1.65))
		fall.tween_property(piece, "rotation", piece.rotation + randf_range(-3.0, 3.0), 1.25)
		fall.tween_property(piece, "modulate:a", 0.0, 0.32).set_delay(0.95)
		fall.chain().tween_callback(piece.queue_free)

func _movement_summary() -> String:
	var move: Dictionary = (race.get("last_movements", {}) as Dictionary).get(selected_racer, {})
	var rolled := int(move.get("rolled", 0))
	var effective := int(move.get("effective", 0))
	var gimmick := str(move.get("gimmick", ""))
	var extra := ""
	match gimmick:
		"foxfire": extra = "　狐火 -2"
		"rapid": extra = "　急流 +3"
		"log": extra = "　丸太 4+"
	if bool(move.get("blocked_by_log", false)):
		extra = "　丸太でSTOP"
	return "%s：%d → %dマス%s" % [RACER_LABELS[selected_racer], rolled, effective, extra]

func _refresh_all(animate_track: bool = false) -> void:
	chip_label.text = "CHIP  %d" % CasinoBankScript.balance()
	bet_label.text = "%s  %d" % [RACER_LABELS.get(selected_racer, selected_racer), selected_bet] if wager_committed else "-"
	roll_count_label.text = "%d / 6" % int(race.get("roll_count", 0))
	var payout := RaceScript.winning_payout(race)
	win_label.text = "%d" % payout if payout > 0 else ("×4" if wager_committed else "-")
	_refresh_assignment_ui()
	_refresh_physical_die(0.0)
	_refresh_ranking()
	call_deferred("_refresh_track", animate_track)

func _refresh_assignment_ui() -> void:
	if current_assignments.is_empty():
		target_value_label.text = "BET・%s　現在の目 ?" % RACER_LABELS[selected_racer]
		die_face_label.text = "?"
		assignment_label.text = "6レーサーがサイコロの6方向を担当"
		for racer_id: String in assignment_cards:
			_update_assignment_card(racer_id, 0)
		_refresh_opposite_pairs()
		return
	var target_value := int(current_assignments.get(selected_racer, 0))
	target_value_label.text = "%s · %d" % [RACER_LABELS[selected_racer], target_value]
	die_face_label.text = str(target_value)
	for racer_id: String in RaceScript.RACERS:
		_update_assignment_card(racer_id, int(current_assignments.get(racer_id, 0)))
	_refresh_opposite_pairs()
	assignment_label.text = "↔7 · STOPした向きの数字で進む"

func _update_assignment_card(racer_id: String, value: int) -> void:
	if not assignment_cards.has(racer_id):
		return
	var entry: Dictionary = assignment_cards[racer_id]
	if bool(entry.get("compact_pair", false)):
		return
	var panel := entry.panel as PanelContainer
	var label := entry.label as Label
	label.text = "?" if value <= 0 else str(value)
	var selected := racer_id == selected_racer
	panel.add_theme_stylebox_override("panel", _panel(
		Color(1.0, 0.90, 0.60, 0.12) if selected else Color.TRANSPARENT,
		GOLD if selected else Color.TRANSPARENT, 10, 2 if selected else 0))
	label.add_theme_color_override("font_color", GOLD_LIGHT if selected else Color("#d8cfc4"))

func _refresh_opposite_pairs() -> void:
	for index: int in mini(OPPOSITE_RACER_PAIRS.size(), opposite_pair_labels.size()):
		var pair: Array = OPPOSITE_RACER_PAIRS[index]
		var first_id := str(pair[0])
		var second_id := str(pair[1])
		var first_value := int(current_assignments.get(first_id, 0))
		var second_value := int(current_assignments.get(second_id, 0))
		var first_text := "?" if first_value <= 0 else str(first_value)
		var second_text := "?" if second_value <= 0 else str(second_value)
		opposite_pair_labels[index].text = "%s%s %s %s%s" % [
			RACER_LABELS[first_id], first_text, str(pair[2]),
			second_text, RACER_LABELS[second_id],
		]
		var selected_pair := selected_racer in [first_id, second_id]
		var panel := opposite_pair_panels[index]
		panel.modulate = Color.WHITE if selected_pair else Color(0.62, 0.60, 0.68, 0.72)
		panel.add_theme_stylebox_override("panel", _panel(
			Color(1.0, 0.86, 0.45, 0.08) if selected_pair else Color.TRANSPARENT,
			Color(GOLD, 0.55) if selected_pair else Color.TRANSPARENT, 8, 2 if selected_pair else 0))
		opposite_pair_labels[index].add_theme_color_override("font_color", GOLD_LIGHT if selected_pair else Color("#c7bdcd"))

func _refresh_physical_die(duration: float) -> void:
	if not is_instance_valid(dice_presentation) or orientations.is_empty():
		return
	if dice_presentation.dice_roots.is_empty():
		call_deferred("_refresh_physical_die", duration)
		return
	var orientation: Dictionary = orientations[orientation_index]
	dice_presentation.set_single_physical_orientation(
		OrientationScript.quaternion_for_orientation(orientation), duration)

func _play_stop_assignment_feedback(assignments: Dictionary) -> void:
	last_stop_feedback_assignments = assignments.duplicate()
	stop_feedback_count_for_test += 1
	if not is_instance_valid(dice_console) or not is_instance_valid(die_panel):
		return
	var console_inverse := dice_console.get_global_transform().affine_inverse()
	var start: Vector2 = console_inverse * (die_panel.global_position + die_panel.size * 0.5)
	for racer_id: String in RaceScript.RACERS:
		if not direction_plates.has(racer_id):
			continue
		var target_panel := (direction_plates[racer_id] as Dictionary).panel as PanelContainer
		var target: Vector2 = console_inverse * (target_panel.global_position + target_panel.size * 0.5)
		var flying := _label(str(int(assignments.get(racer_id, 0))), 20, GOLD_LIGHT)
		flying.custom_minimum_size = Vector2(28, 28)
		flying.size = Vector2(28, 28)
		flying.position = start - flying.size * 0.5
		flying.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flying.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		flying.z_index = 30
		flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dice_console.add_child(flying)
		var flight := create_tween().set_parallel(true)
		flight.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		flight.tween_property(flying, "position", target - flying.size * 0.5, 0.30)
		flight.tween_property(flying, "scale", Vector2(1.25, 1.25), 0.20)
		flight.tween_property(flying, "modulate:a", 0.0, 0.18).set_delay(0.12)
		flight.chain().tween_callback(flying.queue_free)
	var selected_panel := (direction_plates[selected_racer] as Dictionary).panel as Control
	selected_panel.pivot_offset = selected_panel.size * 0.5
	var pulse := create_tween().set_parallel(true)
	pulse.tween_property(selected_panel, "scale", Vector2(1.16, 1.16), 0.10)
	pulse.tween_property(dice_presentation, "modulate", Color(1.45, 1.32, 0.95), 0.07)
	pulse.chain().tween_interval(0.05)
	pulse.chain().tween_property(selected_panel, "scale", Vector2.ONE, 0.18)
	pulse.parallel().tween_property(dice_presentation, "modulate", Color.WHITE, 0.20)

func _refresh_ranking() -> void:
	if race.is_empty():
		return
	var ordered: Array[String] = RaceScript.ranking(race)
	var plain_parts: Array[String] = []
	for i in 3:
		if i >= ordered.size():
			break
		var id := ordered[i]
		var pos := int((race.racers.get(id, {}) as Dictionary).get("position", 0))
		var text := "%d位 %s  %d" % [i + 1, RACER_LABELS[id], pos]
		plain_parts.append(text)
		if i < ranking_cards.size():
			ranking_cards[i].text = "%d位 %s" % [i + 1, RACER_LABELS[id]]
			if i < ranking_portraits.size():
				ranking_portraits[i].texture = _racer_art(id)
	ranking_label.text = " / ".join(plain_parts)

func _refresh_track(animate_track: bool = false) -> void:
	if not is_instance_valid(track_view):
		return
	var positions := {}
	for id: String in RaceScript.RACERS:
		positions[id] = int((race.get("racers", {}).get(id, {}) as Dictionary).get("position", 0))
	track_view.set_race_state(positions, selected_racer, wager_committed, animate_track)
	if is_instance_valid(minimap):
		minimap.set_race_state(positions, selected_racer, wager_committed)

func _apply_roll_button_style(stopping: bool) -> void:
	var fill := Color("#c83c32") if stopping else GOLD
	var border := Color("#ff9b7e") if stopping else Color("#a67836")
	roll_button.add_theme_stylebox_override("normal", _panel(fill, border, 12, 3))
	roll_button.add_theme_stylebox_override("hover", _panel(fill.lightened(0.10), GOLD_LIGHT, 12, 3))
	roll_button.add_theme_color_override("font_color", Color.WHITE if stopping else INK)

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.custom_minimum_size = Vector2(90, 42)
	button.add_theme_color_override("font_color", INK if primary else Color("#fff4dc"))
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#d8d0bf"))
	button.add_theme_stylebox_override("normal", _panel(GOLD if primary else Color("#403452"), Color("#a67836") if primary else Color("#705e84"), 12, 2))
	button.add_theme_stylebox_override("hover", _panel(GOLD_LIGHT if primary else Color("#51436a"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel(Color("#d99d2c") if primary else Color("#302641"), GOLD, 12, 2))
	button.add_theme_stylebox_override("disabled", _panel(Color("#514c45"), Color("#766d5f"), 12, 1))
	return button

func _apply_button_state(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_stylebox_override("normal", _panel(Color("#f7df9a"), GOLD, 12, 3))
		button.add_theme_color_override("font_color", INK)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#403452"), Color("#705e84"), 12, 2))
		button.add_theme_color_override("font_color", Color("#fff4dc"))

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
