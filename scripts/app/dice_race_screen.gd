class_name DiceRaceScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const CasinoFeelFXScript = preload("res://scripts/ui/casino_feel_fx.gd")
const CasinoBackButton = preload("res://scripts/ui/casino_back_button.gd")
const CasinoHowTo3StepsScript = preload("res://scripts/ui/casino_how_to_3_steps.gd")
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
const FACILITY_ID := "dice_race"
const MAX_COAST_STEPS := 9
const COAST_STEP_SECONDS := 0.04
# Resolve the persisted roll early enough that a resumed game is never stuck
# behind the visual dice sequence. TrackView owns the 300–450ms movement
# presentation that follows this model update, so the complete turn still
# lands in the intended ~1.2–1.5s window.
const MIN_ROLL_PRESENTATION_SECONDS: float = 0.86
const FINAL_ROLL_EXTRA_SECONDS: float = 0.14
const PHOTO_FINISH_HOLD_SECONDS: float = 0.48
const RESULT_CHIP_COUNT_SECONDS: float = 0.50
const RESULT_STAGE_PAUSE_SECONDS: float = 0.16
const DIRECTION_LABELS := {
	"top": "上", "bottom": "下", "front": "手前",
	"back": "奥", "left": "左", "right": "右",
}
const OPPOSITE_RACER_PAIRS := [
	["fox", "rabbit", "↕"],
	["duck", "dinosaur", "↔"],
	["camel", "robot", "↔"],
]

## Isolated deterministic harnesses set this before instantiation. Runtime
## leaves it false so the Las Vegas BGM/SFX continue to play normally.
static var suppress_audio_for_tests: bool = false

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
var game_id: String = ""
var pending_roll: Dictionary = {}
var settled: bool = false
var queued_coast_steps: int = -1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

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
var track_frame: PanelContainer
var spectator_strip: PanelContainer
var spectator_strip_label: Label
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
var bet_panel: VBoxContainer
var setup_view: VBoxContainer
var race_view: VBoxContainer
var racer_buttons := {}
var amount_buttons := {}
var bet_portrait: TextureRect
var race_fx_layer: Control
var result_view: VBoxContainer
var result_panel: PanelContainer
var result_rank_label: Label
var result_outcome_label: Label
var result_bet_value: Label
var result_return_value: Label
var result_net_value: Label
var result_chip_delta_label: Label
var result_detail_label: Label
var again_button: Button
var change_bet_button: Button
var result_exit_button: Button
var casino_back_button: Button
var casino_feel_fx: CasinoFeelFX
var final_stretch_shown := false
var spectator_layout_tween: Tween
var presentation_phase: String = "idle"
var stage_trace: Array[String] = []
var presentation_locked: bool = false
var exiting: bool = false
var result_balance_before: int = 0
var result_balance_after: int = 0
var result_presentation_started: bool = false
var tracked_tweens: Array[Tween] = []
var photo_overlay: PanelContainer

func _set_phase(phase: String) -> void:
	presentation_phase = phase
	stage_trace.append(phase)
	if stage_trace.size() > 24:
		stage_trace.pop_front()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_dice_race")
		var ui_sfx := get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	orientations = OrientationScript.all_orientations()
	rng.randomize()
	_build_ui()
	_resume_or_show_setup()

func _exit_tree() -> void:
	exiting = true
	presentation_locked = true
	if spectator_layout_tween != null:
		spectator_layout_tween.kill()
		spectator_layout_tween = null
	for tween: Tween in tracked_tweens:
		if is_instance_valid(tween):
			tween.kill()
	tracked_tweens.clear()
	for node: Node in get_children():
		if node is CanvasItem:
			(node as CanvasItem).visible = false
	if casino_feel_fx != null and is_instance_valid(casino_feel_fx):
		casino_feel_fx.queue_free()
	casino_feel_fx = null

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
	CasinoHowTo3StepsScript.build(setup_view, FACILITY_ID, _how_to_steps())
	_build_bet_panel(setup_view)

	race_view = VBoxContainer.new()
	race_view.name = "RaceActiveView"
	race_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	race_view.add_theme_constant_override("separation", 7)
	root.add_child(race_view)
	_build_track(race_view)
	_build_ranking(race_view)
	_build_spectator_strip(race_view)
	_build_dice_console(race_view)

	roll_button = _button("サイコロを振る", true)
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
	casino_feel_fx = CasinoFeelFXScript.new()
	casino_feel_fx.name = "CasinoFeelFX"
	casino_feel_fx.audio_enabled = not suppress_audio_for_tests
	add_child(casino_feel_fx)
	_build_result_view(effect_layer)

	var back := _button("カジノへ戻る")
	back.name = "CasinoBackButton"
	back.custom_minimum_size.y = 48
	back.pressed.connect(_on_back_pressed)
	CasinoBackButton.configure(back)
	casino_back_button = back
	root.add_child(back)


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
	chip_panel.custom_minimum_size.x = 146
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 16, 2))
	chip_label = _label("CASINO CHIP\n0", 14, Color("#fff4cd"))
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	var roll_box := _hud_box("サイコロ")
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

func _how_to_steps() -> Array[Dictionary]:
	return [
		{"action": "レーサーを選ぶ", "copy": "進ませたい動物とベットを選ぼう"},
		{"action": "サイコロを振る", "copy": "出た目でレーサーが進む"},
		{"action": "ゴールを見届ける", "copy": "選んだレーサーが上位なら配当"},
	]

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
	var route := _label("24 ゴール · 狐火 -2 · 急流 +3 · 丸太でストップ", 20, Color("#fff2d2"))
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(route)
	var note := _label("推しを選んで、欲しい目を狙え\n「ここで止める」の後は惰性回転で確定", 19, Color("#f5cf78"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)


func _build_track(root: VBoxContainer) -> void:
	track_frame = PanelContainer.new()
	track_frame.name = "VerticalRaceViewport"
	# The 720×1280 target has only a little more vertical room than the
	# phone-safe 360×800 layout after logical scaling. Keep the course and die
	# console compact enough that the roll and casino-return CTAs never fall
	# below the fold; 360×800 still renders at the same logical 720-wide scale.
	track_frame.custom_minimum_size.y = 540
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


func _build_spectator_strip(root: VBoxContainer) -> void:
	spectator_strip = PanelContainer.new()
	spectator_strip.name = "SpectatorStrip"
	spectator_strip.custom_minimum_size.y = 72
	spectator_strip.add_theme_stylebox_override("panel", _panel(Color("#21162be8"), GOLD, 12, 2))
	spectator_strip.visible = false
	root.add_child(spectator_strip)
	spectator_strip_label = _label("", 24, GOLD_LIGHT)
	spectator_strip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectator_strip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	spectator_strip.add_child(spectator_strip_label)

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
	dice_console.custom_minimum_size.y = 300
	dice_console.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_console.size_flags_stretch_ratio = 1.0
	dice_console.add_theme_stylebox_override("panel", _panel(Color("#171221"), Color("#7a5a31"), 12, 1))
	root.add_child(dice_console)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	dice_console.add_child(box)

	target_value_label = _label("%s面  ?" % RACER_LABELS[selected_racer], 22, GOLD_LIGHT)
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

	assignment_label = _label("", 17, Color("#f7d58b"))
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
	var caption := _label(str(DIRECTION_LABELS[direction]), 15, Color("#fff2d2"))
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
	start_button = _button("ゲーム開始", true)
	start_button.name = "RaceStartButton"
	start_button.custom_minimum_size.y = 64
	start_button.add_theme_font_size_override("font_size", 30)
	start_button.pressed.connect(_start_race)
	bet_panel.add_child(start_button)


func _build_result_view(effect_layer: Control) -> void:
	var center := CenterContainer.new()
	center.name = "RaceResultCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep the staged result legible above the celebratory WinCard/confetti
	# layer. The card remains a lightweight compatibility cue, while this
	# panel is the authoritative result surface for the new flow.
	center.z_index = 32
	effect_layer.add_child(center)
	result_panel = PanelContainer.new()
	result_panel.name = "RaceResultPanel"
	result_panel.custom_minimum_size = Vector2(324, 0)
	result_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result_panel.add_theme_stylebox_override("panel", _panel(Color("#241735f7"), GOLD, 18, 3))
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	result_panel.visible = false
	center.add_child(result_panel)

	result_view = VBoxContainer.new()
	result_view.name = "RaceResultView"
	result_view.add_theme_constant_override("separation", 6)
	result_view.visible = false
	result_panel.add_child(result_view)
	var title := _label("レース結果", 30, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_view.add_child(title)
	result_rank_label = _label("最終順位  ?位", 36, Color.WHITE)
	result_rank_label.name = "ResultRankLabel"
	result_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_view.add_child(result_rank_label)
	result_outcome_label = _label("", 34, GOLD_LIGHT)
	result_outcome_label.name = "ResultOutcomeLabel"
	result_outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_view.add_child(result_outcome_label)
	result_detail_label = _label("", 18, Color("#e8d8c4"))
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_view.add_child(result_detail_label)
	var metrics := HBoxContainer.new()
	metrics.name = "ResultMetrics"
	metrics.add_theme_constant_override("separation", 4)
	result_view.add_child(metrics)
	var bet_stat := _result_stat_box("BET")
	result_bet_value = bet_stat.get("label") as Label
	metrics.add_child(bet_stat.get("panel") as PanelContainer)
	var return_stat := _result_stat_box("RETURN")
	result_return_value = return_stat.get("label") as Label
	metrics.add_child(return_stat.get("panel") as PanelContainer)
	var net_stat := _result_stat_box("NET")
	result_net_value = net_stat.get("label") as Label
	metrics.add_child(net_stat.get("panel") as PanelContainer)
	result_chip_delta_label = _label("残高  0 CHIP", 18, GOLD_LIGHT)
	result_chip_delta_label.name = "ResultChipDeltaLabel"
	result_chip_delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_chip_delta_label.visible = false
	result_view.add_child(result_chip_delta_label)

	again_button = _button("もう一度遊ぶ", true)
	again_button.name = "AgainButton"
	again_button.custom_minimum_size.y = 96
	again_button.add_theme_font_size_override("font_size", 30)
	again_button.pressed.connect(_on_again_result)
	result_view.add_child(again_button)
	change_bet_button = _button("ベットを変える")
	change_bet_button.name = "ChangeBetButton"
	change_bet_button.custom_minimum_size.y = 88
	change_bet_button.add_theme_font_size_override("font_size", 22)
	change_bet_button.pressed.connect(_on_change_bet_result)
	result_view.add_child(change_bet_button)
	result_exit_button = _button("カジノへ戻る")
	result_exit_button.name = "ResultExitButton"
	result_exit_button.custom_minimum_size.y = 88
	result_exit_button.add_theme_font_size_override("font_size", 22)
	CasinoBackButton.configure(result_exit_button)
	result_exit_button.pressed.connect(_on_result_exit)
	result_view.add_child(result_exit_button)

	_set_result_controls_enabled(false)


func _result_stat_box(caption: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 58
	panel.add_theme_stylebox_override("panel", _panel(Color("#30233e"), Color("#80643c"), 10, 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -3)
	panel.add_child(box)
	var cap := _label(caption, 14, Color("#cbbba8"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value := _label("-", 20, GOLD_LIGHT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}


func _set_result_controls_enabled(enabled: bool) -> void:
	if again_button != null:
		again_button.disabled = not enabled
	if change_bet_button != null:
		change_bet_button.disabled = not enabled
	if result_exit_button != null:
		result_exit_button.disabled = not enabled

func _resume_or_show_setup() -> void:
	var active: Dictionary = CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		_show_bet_select()
		return
	game_id = str(active.get("game_id", ""))
	var session: Dictionary = active.get("session", {}) as Dictionary
	race = _normalise_race(session, int(active.get("bet", selected_bet)))
	selected_racer = str(race.get("bet_racer", selected_racer))
	selected_bet = int(race.get("bet_amount", active.get("bet", selected_bet)))
	wager_committed = true
	settled = false
	result_recorded = false
	pending_roll = _extract_pending_roll(race)
	if pending_roll.is_empty():
		pending_roll = _extract_pending_roll(active)
	setup_view.visible = false
	race_view.visible = true
	final_stretch_shown = false
	track_view.reset_camera()
	_set_spectator_focus(false, true)
	roll_button.disabled = not pending_roll.is_empty()
	status_label.text = "%sのレースを再開" % RACER_LABELS.get(selected_racer, selected_racer)
	_refresh_all()
	if bool(race.get("finished", false)):
		call_deferred("_finish_race")
	elif not pending_roll.is_empty():
		call_deferred("_resume_pending_roll")

func _normalise_race(source: Dictionary, fallback_bet: int) -> Dictionary:
	var candidate: Dictionary = source.duplicate(true)
	if candidate.has("race") and candidate["race"] is Dictionary:
		candidate = (candidate["race"] as Dictionary).duplicate(true)
	var racer_id: String = str(candidate.get("bet_racer", selected_racer))
	var bet_amount: int = maxi(0, int(candidate.get("bet_amount", candidate.get("bet", fallback_bet))))
	var fresh: Dictionary = RaceScript.new_race(racer_id, bet_amount)
	for key: Variant in candidate.keys():
		fresh[str(key)] = candidate[key]
	return fresh

func _extract_pending_roll(source: Dictionary) -> Dictionary:
	var values: Variant = source.get("pending_rolls", [])
	if values is Array and not (values as Array).is_empty() and (values as Array)[0] is Dictionary:
		return ((values as Array)[0] as Dictionary).duplicate(true)
	return {}

func _resume_pending_roll() -> void:
	if pending_roll.is_empty() or not is_inside_tree():
		return
	await _play_persisted_roll(pending_roll)

func _show_bet_select() -> void:
	if exiting:
		return
	_clear_race_effects()
	if roll_button != null:
		if roll_button.pressed.is_connected(_restart_after_result):
			roll_button.pressed.disconnect(_restart_after_result)
		if not roll_button.pressed.is_connected(_on_roll_stop):
			roll_button.pressed.connect(_on_roll_stop)
		roll_button.visible = true
		roll_button.text = "サイコロを振る"
		roll_button.disabled = false
		_apply_roll_button_style(false)
	race = RaceScript.new_race()
	game_id = ""
	pending_roll = {}
	settled = false
	spinning = false
	presentation_locked = false
	wager_committed = false
	result_recorded = false
	current_assignments.clear()
	setup_view.visible = true
	race_view.visible = false
	if result_panel != null:
		result_panel.visible = false
	if result_view != null:
		result_view.visible = false
	_set_result_controls_enabled(false)
	if casino_back_button != null:
		casino_back_button.visible = true
	final_stretch_shown = false
	if minimap != null:
		minimap.set_final_stretch(false)
	status_label.text = "勝たせたいレーサーを選ぼう"
	_refresh_bet_buttons()
	_refresh_all()


func _clear_race_effects() -> void:
	if spectator_layout_tween != null:
		spectator_layout_tween.kill()
		spectator_layout_tween = null
	for tween: Tween in tracked_tweens:
		if is_instance_valid(tween):
			tween.kill()
	tracked_tweens.clear()
	if race_fx_layer == null or not is_instance_valid(race_fx_layer):
		photo_overlay = null
		return
	var result_center := result_panel.get_parent() if result_panel != null else null
	for child: Node in race_fx_layer.get_children():
		if child == result_center:
			continue
		child.queue_free()
	photo_overlay = null

func _select_racer(racer_id: String) -> void:
	if presentation_locked or exiting or wager_committed:
		return
	selected_racer = racer_id
	_play_ui_sfx(&"select", false)
	_refresh_bet_buttons()
	_refresh_assignment_ui()

func _select_bet(amount: int) -> void:
	if presentation_locked or exiting or wager_committed:
		return
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
	if presentation_locked:
		return
	_set_phase("start")
	presentation_locked = true
	if casino_feel_fx != null:
		casino_feel_fx.press_button(start_button, true)
	var initial_race: Dictionary = RaceScript.new_race(selected_racer, selected_bet)
	initial_race["pending_rolls"] = []
	var receipt: Dictionary = CasinoBankScript.begin_game(FACILITY_ID, selected_bet, initial_race)
	if not bool(receipt.get("ok", false)):
		if bool(receipt.get("already_active", false)):
			presentation_locked = false
			_resume_or_show_setup()
			return
		_play_ui_sfx(&"blocked", false)
		_refresh_bet_buttons()
		presentation_locked = false
		return
	_play_ui_sfx(&"start", false)
	race = initial_race
	game_id = str(receipt.get("game_id", ""))
	pending_roll = {}
	settled = false
	wager_committed = true
	result_recorded = false
	final_stretch_shown = false
	minimap.set_final_stretch(false)
	setup_view.visible = false
	race_view.visible = true
	track_view.reset_camera()
	_set_spectator_focus(false, true)
	roll_button.disabled = false
	status_label.text = "%sを応援！" % RACER_LABELS[selected_racer]
	spin_elapsed = randf() * SPIN_STEP_SECONDS * float(maxi(orientations.size(), 1))
	orientation_index = int(floor(spin_elapsed / SPIN_STEP_SECONDS)) % maxi(orientations.size(), 1)
	current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
	_refresh_all()
	# Keep the setup-to-race handoff responsive: lock through one frame so the
	# first CTA feels deliberate without delaying automated/resume callers.
	await get_tree().process_frame
	if exiting or not is_inside_tree():
		return
	presentation_locked = false
	_set_phase("ready")
	_show_race_banner("YOUR BET  %s  %d CHIP" % [RACER_LABELS[selected_racer], selected_bet], GOLD_LIGHT, Color("#3f2408"), 0.72, "YourBetBanner")

func _on_roll_stop() -> void:
	if presentation_locked or exiting:
		return
	if not wager_committed or bool(race.get("finished", false)):
		return
	if not spinning:
		_set_spectator_focus(false)
		spinning = true
		if casino_feel_fx != null:
			casino_feel_fx.play_dice_roll()
		_play_ui_sfx(&"start", false)
		roll_button.text = "ここで止める"
		_apply_roll_button_style(true)
		status_label.text = "%s面  %dを狙え！" % [RACER_LABELS[selected_racer], int(current_assignments.get(selected_racer, 0))]
		return
	spinning = false
	presentation_locked = true
	if casino_feel_fx != null:
		casino_feel_fx.play_dice_land(true)
	_play_ui_sfx(&"stop", false)
	roll_button.text = "サイコロを振る"
	roll_button.disabled = true
	_apply_roll_button_style(false)
	var start_index: int = orientation_index
	var coast_steps: int = queued_coast_steps if queued_coast_steps in range(0, MAX_COAST_STEPS + 1) else rng.randi_range(0, MAX_COAST_STEPS)
	queued_coast_steps = -1
	var final_index: int = (start_index + coast_steps) % orientations.size()
	var final_assignments: Dictionary = OrientationScript.values_for_racers(orientations[final_index])
	pending_roll = {
		"kind": "orientation",
		"start_index": start_index,
		"coast_steps": coast_steps,
		"orientation_index": final_index,
		"assignments": final_assignments.duplicate(true),
	}
	race["pending_rolls"] = [pending_roll.duplicate(true)]
	var update_receipt: Dictionary = CasinoBankScript.update_game(FACILITY_ID, race, game_id)
	if not bool(update_receipt.get("ok", false)):
		status_label.text = "保存できませんでした。もう一度「ここで止める」を押してください。"
		roll_button.disabled = false
		presentation_locked = false
		return
	await _play_persisted_roll(pending_roll)

func _play_persisted_roll(pending: Dictionary) -> void:
	if exiting:
		return
	presentation_locked = true
	roll_button.disabled = true
	_set_phase("roll")
	if pending.is_empty() or orientations.is_empty():
		return
	var start_index: int = posmod(int(pending.get("start_index", orientation_index)), orientations.size())
	var coast_steps: int = clampi(int(pending.get("coast_steps", 0)), 0, MAX_COAST_STEPS)
	status_label.text = "ここで止める！ 惰性回転を見届けよう"
	for step: int in range(1, coast_steps + 1):
		status_label.text = "惰性回転  %d / %d" % [step, coast_steps]
		orientation_index = (start_index + step) % orientations.size()
		current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
		_refresh_assignment_ui()
		_refresh_physical_die(COAST_STEP_SECONDS)
		await get_tree().create_timer(COAST_STEP_SECONDS).timeout
		if not is_inside_tree():
			return
	# Keep a readable dice-stop pause before the track resolves. The persisted
	# orientation is already chosen; this wait is presentation-only and resolves
	# the model before the longer track movement cue begins.
	var is_final_roll: bool = int(race.get("roll_count", 0)) >= 5
	var target_seconds: float = MIN_ROLL_PRESENTATION_SECONDS + (FINAL_ROLL_EXTRA_SECONDS if is_final_roll else 0.0)
	var coast_seconds: float = float(coast_steps) * COAST_STEP_SECONDS
	await get_tree().create_timer(maxf(0.10, target_seconds - coast_seconds)).timeout
	if exiting or not is_inside_tree():
		return
	_set_phase("movement")
	orientation_index = posmod(int(pending.get("orientation_index", start_index)), orientations.size())
	current_assignments = (pending.get("assignments", {}) as Dictionary).duplicate(true)
	if current_assignments.is_empty():
		current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
	await _resolve_persisted_roll(current_assignments)

func _resolve_persisted_roll(stopped_assignments: Dictionary) -> void:
	if exiting:
		return
	var was_photo_finish := not (race.get("photo_finish_candidates", []) as Array).is_empty()
	race = RaceScript.apply_roll(race, stopped_assignments)
	race["pending_rolls"] = []
	pending_roll = {}
	CasinoBankScript.update_game(FACILITY_ID, race, game_id)
	_play_roll_result_sfx()
	status_label.text = "PHOTO FINISH判定！" if was_photo_finish else "%s、行け！" % RACER_LABELS[selected_racer]
	_set_spectator_focus(true)
	_refresh_all(true)
	_refresh_physical_die(0.18)
	_play_stop_assignment_feedback(stopped_assignments)
	await track_view.motion_finished
	if not is_inside_tree():
		return
	_refresh_ranking()
	_set_phase("rank")
	_refresh_race_intel()
	_show_selected_movement_event()
	_maybe_show_final_stretch()
	if bool(race.get("finished", false)):
		_set_phase("final")
		_show_race_banner("GOAL!", GOLD_LIGHT, Color("#3f2408"), 0.22, "GoalMomentBanner")
		await get_tree().create_timer(0.28).timeout
		if is_inside_tree():
			_finish_race()
		return
	await _after_roll_resolution()
	if not bool(race.get("finished", false)):
		_set_spectator_focus(false)
		roll_button.disabled = false
		presentation_locked = false

func _after_roll_resolution() -> void:
	if bool(race.get("finished", false)):
		_finish_race()
		return
	var photo: Array = race.get("photo_finish_candidates", [])
	if not photo.is_empty():
		_set_phase("photo")
		status_label.text = "PHOTO FINISH！ 同着レーサーの数字で決着。"
		await _present_photo_finish(photo)
		if exiting or not is_inside_tree():
			return
		# The model intentionally keeps this tie unresolved. The next ROLL
		# compares the tied racers' next die values; never auto-resolve here.
		_set_phase("photo_wait")
		roll_button.text = "サイコロを振る"
		status_label.text = "同着決着。サイコロを振って数字を比べよう。"
		return
	if bool(race.get("cashout_offered", false)):
		race = RaceScript.ride_on(race)
		status_label.text = "3投目　まだ届く！"
		_refresh_all()


func _present_photo_finish(candidates: Array) -> void:
	if exiting or not is_inside_tree() or race_fx_layer == null:
		return
	if photo_overlay != null and is_instance_valid(photo_overlay):
		photo_overlay.queue_free()
	photo_overlay = PanelContainer.new()
	photo_overlay.name = "PhotoFinishOverlay"
	photo_overlay.custom_minimum_size = Vector2(300, 108)
	photo_overlay.size = Vector2(300, 108)
	photo_overlay.position = Vector2((race_fx_layer.size.x - 300.0) * 0.5, maxf(148.0, race_fx_layer.size.y * 0.26))
	photo_overlay.pivot_offset = photo_overlay.size * 0.5
	photo_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_overlay.add_theme_stylebox_override("panel", _panel(Color("#4a2038f2"), GOLD_LIGHT, 16, 3))
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 0)
	photo_overlay.add_child(body)
	var title := _label("PHOTO FINISH", 26, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var names: Array[String] = []
	for value: Variant in candidates:
		var id := str(value)
		if RACER_LABELS.has(id):
			names.append(RACER_LABELS[id])
	var copy := _label("同着：%s\n次のサイコロで決着" % "・".join(names), 16, Color("#fff1d6"))
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(copy)
	race_fx_layer.add_child(photo_overlay)
	photo_overlay.scale = Vector2(0.76, 0.76)
	photo_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_play_ui_sfx(&"stop", false)
	if casino_feel_fx != null:
		casino_feel_fx.press_button(null, true)
	var tween := create_tween()
	tracked_tweens.append(tween)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(photo_overlay, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(photo_overlay, "modulate", Color.WHITE, 0.12)
	tween.tween_interval(PHOTO_FINISH_HOLD_SECONDS)
	tween.tween_property(photo_overlay, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		if is_instance_valid(photo_overlay):
			photo_overlay.queue_free()
		photo_overlay = null
	)
	await tween.finished
	if exiting or not is_inside_tree():
		return

func _finish_race() -> void:
	if exiting:
		return
	if not bool(race.get("finished", false)):
		return
	if result_recorded:
		# Deferred goal callbacks and duplicate taps must not settle twice.
		if result_panel != null and not result_panel.visible:
			_show_result_view()
		return
	presentation_locked = true
	_set_phase("result")
	spinning = false
	roll_button.disabled = true
	var winner: String = str(race.get("winner", ""))
	var final_rank: int = RaceScript.final_rank_for_racer(race, selected_racer)
	var payout: int = RaceScript.final_payout(race)
	var balance_before: int = CasinoBankScript.balance()
	var receipt: Dictionary = CasinoBankScript.settle_game(FACILITY_ID, payout, {
		"winner": winner,
		"bet_racer": selected_racer,
		"rank": final_rank,
		"won": winner == selected_racer,
		"payout": payout,
	}, game_id)
	if bool(receipt.get("already_settled", false)):
		payout = int(receipt.get("payout", payout))
	settled = bool(receipt.get("ok", false)) or bool(receipt.get("already_settled", false))
	if not settled:
		status_label.text = "精算を保存できませんでした。"
		presentation_locked = false
		return
	result_balance_after = CasinoBankScript.balance()
	wager_committed = false
	result_recorded = true
	# Keep the legacy RollStopButton route alive for saved callers and older
	# harnesses that emit it to restart after a result. The visible result CTAs
	# remain the primary controls; _show_bet_select restores _on_roll_stop.
	if roll_button.pressed.is_connected(_on_roll_stop):
		roll_button.pressed.disconnect(_on_roll_stop)
	if not roll_button.pressed.is_connected(_restart_after_result):
		roll_button.pressed.connect(_restart_after_result)
	# Keep the legacy hidden RollStopButton route descriptive for saved callers
	# and older harnesses; the visible result panel exposes the three explicit
	# Japanese CTAs and hides this compatibility control.
	roll_button.text = "次のレースを選ぶ"
	_apply_roll_button_style(false)
	roll_button.disabled = false
	_play_ui_sfx(&"complete" if winner == selected_racer else &"error", true)
	var net: int = payout - selected_bet
	var outcome: String = _result_outcome_for_net(net)
	status_label.text = "%s · 最終%d位 · 受け取り %d CHIP（BET込み） · 収支 %+d CHIP" % [outcome, final_rank, payout, net]
	result_balance_before = balance_before
	if winner == selected_racer:
		_play_win_fx(RACER_ART_PATHS.get(winner, ""), RACER_LABELS.get(winner, winner), payout)
	_refresh_all()
	if is_instance_valid(track_view):
		track_view.set_winner_presentation(winner)
	_show_result_view()


func _show_result_view() -> void:
	if exiting or result_panel == null or not is_inside_tree():
		return
	if result_presentation_started:
		return
	result_presentation_started = true
	presentation_locked = true
	var winner := str(race.get("winner", ""))
	var final_rank: int = RaceScript.final_rank_for_racer(race, selected_racer)
	var payout: int = int(RaceScript.final_payout(race))
	var net: int = payout - selected_bet
	var outcome: String = _result_outcome_for_net(net)
	result_rank_label.text = "最終順位  %d位" % final_rank
	result_outcome_label.text = outcome
	var outcome_color := GOLD_LIGHT if outcome == "WIN" else (Color("#f7d58b") if outcome == "EVEN" else Color("#ff9a8e"))
	result_outcome_label.add_theme_color_override("font_color", outcome_color)
	result_detail_label.text = "%s  ·  %sのゴールを確認" % [RACER_LABELS.get(selected_racer, selected_racer), RACER_LABELS.get(winner, winner)]
	result_bet_value.text = "%d CHIP" % selected_bet
	result_return_value.text = "%d CHIP" % payout
	result_net_value.text = "%+d CHIP" % net
	result_chip_delta_label.text = "残高  %d CHIP" % result_balance_before
	result_rank_label.visible = false
	result_outcome_label.visible = false
	result_detail_label.visible = false
	result_bet_value.visible = false
	result_return_value.visible = false
	result_net_value.visible = false
	result_chip_delta_label.visible = false
	result_panel.visible = true
	result_view.visible = true
	# The staged result panel is the single source of truth after GOAL. Keep
	# the legacy WinCard node available for older callers, but hide its inline
	# copy so it cannot compete with the readable BET/RETURN/NET summary.
	var legacy_win_card := race_fx_layer.find_child("WinCard", true, false) as Control if race_fx_layer != null else null
	if legacy_win_card != null:
		legacy_win_card.visible = false
	_set_result_controls_enabled(false)
	roll_button.visible = false
	if casino_back_button != null:
		casino_back_button.visible = false
	_set_phase("result_rank")
	call_deferred("_present_result_stages")


func _present_result_stages() -> void:
	if exiting or not is_inside_tree() or result_panel == null:
		return
	result_rank_label.visible = true
	status_label.text = "最終順位を確認中..."
	if casino_feel_fx != null:
		casino_feel_fx.press_button(null, true)
	await get_tree().create_timer(0.22).timeout
	if exiting or not is_inside_tree():
		return
	_set_phase("result_outcome")
	result_outcome_label.visible = true
	status_label.text = "勝敗を確認中..."
	if casino_feel_fx != null:
		if result_outcome_label.text == "WIN":
			casino_feel_fx.play_win_feedback()
		elif result_outcome_label.text == "LOSS":
			casino_feel_fx.play_lose_feedback()
		else:
			casino_feel_fx.press_button(null, true)
	await get_tree().create_timer(RESULT_STAGE_PAUSE_SECONDS).timeout
	if exiting or not is_inside_tree():
		return
	_set_phase("result_metrics")
	result_detail_label.visible = true
	result_bet_value.visible = true
	result_return_value.visible = true
	result_net_value.visible = true
	status_label.text = "BET / RETURN / NET"
	await get_tree().create_timer(RESULT_STAGE_PAUSE_SECONDS).timeout
	if exiting or not is_inside_tree():
		return
	_set_phase("result_chip")
	result_chip_delta_label.visible = true
	await _animate_result_chip_count(RESULT_CHIP_COUNT_SECONDS)
	if exiting or not is_inside_tree():
		return
	_set_phase("result_cta")
	status_label.text = "結果を確認しました。次の遊び方を選ぼう。"
	_set_result_controls_enabled(true)
	presentation_locked = false
	_set_phase("idle")


func _animate_result_chip_count(duration: float) -> void:
	if chip_label == null:
		return
	if casino_feel_fx != null:
		casino_feel_fx.animate_chip_change(chip_label)
	var from_value: int = result_balance_before
	var to_value: int = result_balance_after
	var steps: int = 10
	for index: int in range(1, steps + 1):
		if exiting or not is_inside_tree():
			return
		var value: int = roundi(lerpf(float(from_value), float(to_value), float(index) / float(steps)))
		chip_label.text = "CASINO CHIP\n%d" % value
		result_chip_delta_label.text = "残高  %d CHIP" % value
		await get_tree().create_timer(duration / float(steps)).timeout


func _result_outcome_for_net(net: int) -> String:
	# Preserve the existing Race semantics: a positive return is WIN, a
	# break-even return is EVEN, and a negative return is LOSS. Feel polish must
	# never reinterpret a payout as a different game result.
	return "WIN" if net > 0 else ("EVEN" if net == 0 else "LOSS")


func _on_again_result() -> void:
	if exiting or presentation_locked or not result_recorded:
		return
	_play_ui_sfx(&"retry", false)
	_show_bet_select()
	result_presentation_started = false


func _on_change_bet_result() -> void:
	if exiting or presentation_locked or not result_recorded:
		return
	_play_ui_sfx(&"select", false)
	_show_bet_select()
	result_presentation_started = false


func _on_result_exit() -> void:
	if exiting or presentation_locked:
		return
	_play_ui_sfx(&"back", false)
	back_requested.emit()

func _restart_after_result() -> void:
	if presentation_locked or exiting:
		return
	_play_ui_sfx(&"retry", false)
	_show_bet_select()
	result_presentation_started = false

func _on_back_pressed() -> void:
	if presentation_locked or exiting:
		return
	if wager_committed and not race.is_empty():
		CasinoBankScript.update_game(FACILITY_ID, race, game_id)
	_play_ui_sfx(&"back", false)
	back_requested.emit()


func _on_track_rank_changed(racer_id: String, previous_rank: int, next_rank: int) -> void:
	if wager_committed and racer_id == selected_racer and next_rank < previous_rank:
		_play_ui_sfx(&"streak", true)
		_play_overtake_fx(previous_rank, next_rank)


func _set_spectator_focus(active: bool, immediate: bool = false) -> void:
	if exiting or not is_inside_tree() or track_frame == null or dice_console == null or spectator_strip == null or roll_button == null:
		return
	if spectator_layout_tween != null:
		spectator_layout_tween.kill()
		spectator_layout_tween = null
	track_view.set_spectator_focus(active)
	if active:
		var value := int(current_assignments.get(selected_racer, 0))
		spectator_strip_label.text = "%s  %d!!" % [RACER_LABELS[selected_racer], value]
		dice_console.visible = false
		roll_button.visible = false
		spectator_strip.visible = true
	else:
		dice_console.visible = true
		roll_button.visible = true
		spectator_strip.visible = false
	# At the 720×1280 target the full race stack must share the viewport with
	# the die console, roll CTA, and 96px shared casino-return CTA. Use a
	# compact track window there; the 360×800 phone target expands to the taller
	# logical 720×1600 canvas and keeps the cinematic track height.
	var compact_layout := size.y <= 1400.0
	var target_height := (480.0 if compact_layout else 720.0) if active else (400.0 if compact_layout else 560.0)
	if immediate or compact_layout:
		track_frame.custom_minimum_size.y = target_height
		spectator_layout_tween = null
		return
	spectator_layout_tween = create_tween()
	tracked_tweens.append(spectator_layout_tween)
	spectator_layout_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	spectator_layout_tween.tween_property(track_frame, "custom_minimum_size:y", target_height, 0.18)


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
	_play_ui_sfx(&"streak", true)
	minimap.set_final_stretch(true)
	_show_race_banner("FINAL STRETCH!", GOLD_LIGHT, Color("#3f2408"), 0.72, "FinalStretchBanner")


func _show_race_banner(text: String, color: Color, outline_color: Color, hold_seconds: float, node_name: String = "RaceBanner"):
	if exiting or not is_inside_tree() or race_fx_layer == null:
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
	tracked_tweens.append(intro)
	intro.tween_property(banner, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(banner, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10)
	intro.chain().tween_interval(hold_seconds)
	intro.chain().tween_property(banner, "modulate:a", 0.0, 0.16)
	intro.chain().tween_callback(banner.queue_free)


func _play_overtake_fx(previous_rank: int, next_rank: int) -> void:
	if previous_rank <= next_rank:
		return
	_show_race_banner("%d位 → %d位!" % [previous_rank, next_rank], GOLD_LIGHT, Color("#3f2408"), 0.42, "OvertakeBanner")
	for index: int in 6:
		_spawn_spark()

func _play_roll_result_sfx() -> void:
	var move: Dictionary = (race.get("last_movements", {}) as Dictionary).get(selected_racer, {})
	var rolled := int(move.get("rolled", 0))
	if bool(move.get("blocked_by_log", false)) or str(move.get("gimmick", "")) == "foxfire":
		_play_ui_sfx(&"warning", true)
	elif str(move.get("gimmick", "")) == "rapid" or rolled >= 5:
		_play_ui_sfx(&"bonus", true)
	else:
		_play_ui_sfx(&"progress-step", true)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)


func _spawn_spark() -> void:
	if exiting or not is_inside_tree() or race_fx_layer == null:
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
	tracked_tweens.append(flight)
	flight.tween_property(spark, "position:y", spark.position.y - randf_range(18.0, 38.0), 0.36)
	flight.tween_property(spark, "modulate:a", 0.0, 0.24).set_delay(0.12)
	flight.chain().tween_callback(spark.queue_free)


func _play_win_fx(winner_art: Variant, winner_label: Variant, payout: int) -> void:
	if exiting or not is_inside_tree() or race_fx_layer == null:
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
	row.add_child(_label("%s 勝ち！  受け取り %d · 収支 %+d" % [str(winner_label), payout, payout - selected_bet], 20, GOLD_LIGHT))
	card.reset_size()
	card.position = Vector2(
		(race_fx_layer.size.x - card.size.x) * 0.5,
		maxf(236.0, race_fx_layer.size.y * 0.33))
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.84, 0.84)
	var entrance := create_tween()
	tracked_tweens.append(entrance)
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
		tracked_tweens.append(fall)
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
		extra = "　丸太でストップ"
	return "%s：%d → %dマス%s" % [RACER_LABELS[selected_racer], rolled, effective, extra]


func _show_selected_movement_event() -> void:
	var move: Dictionary = (race.get("last_movements", {}) as Dictionary).get(selected_racer, {})
	var gimmick := str(move.get("gimmick", ""))
	var callout := ""
	match gimmick:
		"rapid": callout = "急流！ 一気に加速！"
		"foxfire": callout = "狐火！ -2マス"
		"log": callout = "丸太でストップ！" if bool(move.get("blocked_by_log", false)) else "丸太突破！"
	if callout.is_empty():
		return
	status_label.text = callout
	_show_race_banner(callout, GOLD_LIGHT, Color("#3f2408"), 0.38, "GimmickCallout")

func _refresh_all(animate_track: bool = false) -> void:
	chip_label.text = "CASINO CHIP\n%d" % CasinoBankScript.balance()
	bet_label.text = "★ %s  %d" % [RACER_LABELS.get(selected_racer, selected_racer), selected_bet] if wager_committed else "-"
	roll_count_label.text = "%d / 6" % int(race.get("roll_count", 0))
	var payout := RaceScript.winning_payout(race)
	win_label.text = "%d" % payout if payout > 0 else ("×4" if wager_committed else "-")
	_refresh_assignment_ui()
	_refresh_physical_die(0.0)
	if not animate_track:
		_refresh_ranking()
		_refresh_race_intel()
	call_deferred("_refresh_track", animate_track)

func _refresh_race_intel() -> void:
	if not wager_committed or race.is_empty():
		assignment_label.text = ""
		return
	var racers: Dictionary = race.get("racers", {})
	var bet_position := int((racers.get(selected_racer, {}) as Dictionary).get("position", 0))
	var leader_position := bet_position
	for racer_id: String in RaceScript.RACERS:
		leader_position = maxi(leader_position, int((racers.get(racer_id, {}) as Dictionary).get("position", 0)))
	var rank := RaceScript.rank_for_racer(race, selected_racer)
	var goal_distance := maxi(0, RaceScript.GOAL - bet_position)
	if goal_distance == 0:
		assignment_label.text = "GOAL!"
	elif goal_distance <= 6:
		assignment_label.text = "GOALまで %dマス！" % goal_distance
	elif rank == 1:
		assignment_label.text = "LEADER!"
	else:
		var leader_gap := leader_position - bet_position
		if leader_gap <= 1:
			assignment_label.text = "先頭まで1マス！"
		elif leader_gap <= _max_next_effective_move():
			assignment_label.text = "6なら先頭圏！"
		else:
			assignment_label.text = "先頭まで %dマス" % leader_gap


func _max_next_effective_move() -> int:
	var racer: Dictionary = (race.get("racers", {}) as Dictionary).get(selected_racer, {})
	return 4 if bool(racer.get("foxfire_pending", false)) else 6

func _refresh_assignment_ui() -> void:
	if current_assignments.is_empty():
		target_value_label.text = "%s面  ?" % RACER_LABELS[selected_racer]
		die_face_label.text = "?"
		for racer_id: String in assignment_cards:
			_update_assignment_card(racer_id, 0)
		_refresh_opposite_pairs()
		return
	var target_value := int(current_assignments.get(selected_racer, 0))
	target_value_label.text = "%s面  %d" % [RACER_LABELS[selected_racer], target_value]
	die_face_label.text = str(target_value)
	for racer_id: String in RaceScript.RACERS:
		_update_assignment_card(racer_id, int(current_assignments.get(racer_id, 0)))
	_refresh_opposite_pairs()

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
		if selected_pair:
			opposite_pair_labels[index].text = "%s%s %s %s%s" % [
				RACER_LABELS[first_id], first_text, str(pair[2]),
				second_text, RACER_LABELS[second_id],
			]
		else:
			opposite_pair_labels[index].text = "%s %s %s" % [first_text, str(pair[2]), second_text]
		var panel := opposite_pair_panels[index]
		panel.modulate = Color.WHITE if selected_pair else Color(0.62, 0.60, 0.68, 0.72)
		panel.add_theme_stylebox_override("panel", _panel(
			Color(1.0, 0.86, 0.45, 0.08) if selected_pair else Color.TRANSPARENT,
			Color(GOLD, 0.55) if selected_pair else Color.TRANSPARENT, 8, 2 if selected_pair else 0))
		opposite_pair_labels[index].add_theme_color_override("font_color", GOLD_LIGHT if selected_pair else Color("#c7bdcd"))

func _refresh_physical_die(duration: float) -> void:
	if exiting or not is_inside_tree() or not is_instance_valid(dice_presentation) or orientations.is_empty():
		return
	if dice_presentation.dice_roots.is_empty():
		call_deferred("_refresh_physical_die", duration)
		return
	var orientation: Dictionary = orientations[orientation_index]
	dice_presentation.set_single_physical_orientation(
		OrientationScript.quaternion_for_orientation(orientation), duration)

func _play_stop_assignment_feedback(assignments: Dictionary) -> void:
	if exiting or not is_inside_tree():
		return
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
		target.x = clampf(target.x, flying.size.x * 0.5 + 4.0, dice_console.size.x - flying.size.x * 0.5 - 4.0)
		target.y = clampf(target.y, flying.size.y * 0.5 + 4.0, dice_console.size.y - flying.size.y * 0.5 - 4.0)
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
		tracked_tweens.append(flight)
	var selected_panel := (direction_plates[selected_racer] as Dictionary).panel as Control
	selected_panel.pivot_offset = selected_panel.size * 0.5
	var pulse := create_tween().set_parallel(true)
	tracked_tweens.append(pulse)
	pulse.tween_property(selected_panel, "scale", Vector2(1.16, 1.16), 0.10)
	pulse.tween_property(dice_presentation, "modulate", Color(1.45, 1.32, 0.95), 0.07)
	pulse.chain().tween_interval(0.05)
	pulse.chain().tween_property(selected_panel, "scale", Vector2.ONE, 0.18)
	pulse.parallel().tween_property(dice_presentation, "modulate", Color.WHITE, 0.20)
	var selected_value := int(assignments.get(selected_racer, 0))
	if selected_value >= 5:
		_show_target_roll_burst(selected_value)

func _show_target_roll_burst(value: int) -> void:
	if exiting or not is_inside_tree() or race_fx_layer == null:
		return
	var burst := _label("%d!!" % value, 44, GOLD_LIGHT)
	burst.name = "SelectedRollBurst"
	burst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	burst.add_theme_color_override("font_outline_color", Color("#5b2512"))
	burst.add_theme_constant_override("outline_size", 9)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.size = Vector2(180, 72)
	burst.position = Vector2((race_fx_layer.size.x - burst.size.x) * 0.5, race_fx_layer.size.y * 0.60)
	burst.pivot_offset = burst.size * 0.5
	burst.scale = Vector2(0.62, 0.62)
	race_fx_layer.add_child(burst)
	var impact := create_tween().set_parallel(true)
	tracked_tweens.append(impact)
	impact.tween_property(burst, "scale", Vector2(1.20, 1.20), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact.tween_property(burst, "modulate", Color(1.35, 1.18, 0.78), 0.08)
	impact.chain().tween_interval(0.18)
	impact.chain().tween_property(burst, "modulate:a", 0.0, 0.16)
	impact.chain().tween_callback(burst.queue_free)

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
	if exiting or not is_inside_tree() or not is_instance_valid(track_view):
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
	VisualFeedback.bind_button(button)
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
