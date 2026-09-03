class_name Treasure21Screen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const CasinoBackButton = preload("res://scripts/ui/casino_back_button.gd")
const Treasure21Script = preload("res://scripts/game/treasure_21_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const DISPLAY_FONT: Font = preload("res://assets/fonts/cinzel/Cinzel-Variable.ttf")
const CASINO_BACKGROUND: Texture2D = preload("res://assets/casino/dice_roulette/ui/casino-table-bg-v1.png")
const CHEST_CLOSED: Texture2D = preload("res://assets/casino/treasure_21/chest_frames/01.png")
const CHEST_CHARGED: Texture2D = preload("res://assets/casino/treasure_21/chest_frames/02.png")
const CHEST_OPENING: Texture2D = preload("res://assets/casino/treasure_21/chest_frames/03.png")
const CHEST_TREASURE: Texture2D = preload("res://assets/casino/treasure_21/chest_frames/04.png")

const FACILITY_ID := "treasure_21"
const META_KEY := "treasure_21"
const BET_AMOUNTS := [5, 10, 20, 50]
const GOLDEN_NUMBERS := [18, 19, 20]
const ROLL_SECONDS := 0.30
const SETTLE_SECONDS := 0.14

const GOLD := Color("#d7a93c")
const GOLD_LIGHT := Color("#ffe6a1")
const INK := Color("#211508")
const CREAM := Color("#fff2cf")
const NAVY := Color("#031714")
const NAVY_2 := Color("#082b25")
const PLUM := Color("#0b3a32")
const RED := Color("#a92924")
const GREEN := Color("#0b5a42")
const TEAL := Color("#39b68f")

## Isolated rules/UI harnesses set this before instancing the scene. Runtime
## builds leave it false so the Las Vegas music and SFX routing remain active.
static var suppress_audio_for_tests := false

var game: Dictionary = {}
var game_id := ""
var selected_bet := 20
var rolling := false
var settled := false
var rng_seed := 0
var queued_roll_value := 0
var queued_golden_number := 0
var rng := RandomNumberGenerator.new()
var pending_roll: Dictionary = {}
var view_state := "setup"

var chip_label: Label
var status_label: Label
var total_label: Label
var bet_label: Label
var golden_label: Label
var total_meter: ProgressBar
var total_caption: Label
var die_face_label: Label
var status_banner: PanelContainer
var status_banner_label: Label
var treasure_track_panel: PanelContainer
var play_panel: PanelContainer
var track_chest: TextureRect
var track_steps: Dictionary = {}
var preview_title: Label
var preview_hint: Label
var result_chest: TextureRect
var result_label: Label
var result_payout_label: Label
var result_profit_label: Label
var result_detail_label: Label
var start_button: Button
var roll_button: Button
var cashout_button: Button
var again_button: Button
var change_bet_button: Button
var back_button: Button
var setup_view: VBoxContainer
var active_view: VBoxContainer
var result_view: VBoxContainer
var danger_panel: PanelContainer
var danger_grid: GridContainer
var danger_cells: Dictionary = {}
var danger_preview: Array[Dictionary] = []
var bet_buttons: Dictionary = {}
var dice_presentation: DicePresentation3D
var effect_layer: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_treasure_21")
		var ui_sfx := get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	_build_ui()
	resized.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")
	_resume_or_show_setup()

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.name = "CasinoBackdrop"
	bg.texture = CASINO_BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.name = "EmeraldShade"
	shade.color = Color("#001713b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.name = "SafeMargins"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Treasure21Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_build_header(root)
	_build_status(root)

	setup_view = VBoxContainer.new()
	setup_view.name = "Treasure21SetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 8)
	root.add_child(setup_view)
	_build_setup(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "Treasure21ActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 6)
	root.add_child(active_view)
	_build_active(active_view)

	result_view = VBoxContainer.new()
	result_view.name = "Treasure21ResultView"
	result_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_view.add_theme_constant_override("separation", 8)
	root.add_child(result_view)
	_build_result(result_view)

	back_button = _button("カジノへ戻る", false)
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size.y = 68
	back_button.pressed.connect(_on_back_pressed)
	CasinoBackButton.configure(back_button)
	root.add_child(back_button)

	effect_layer = Control.new()
	effect_layer.name = "Treasure21EffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 30
	add_child(effect_layer)

func _build_header(root: VBoxContainer) -> void:
	var header := PanelContainer.new()
	header.name = "Treasure21Header"
	header.custom_minimum_size.y = 80
	header.add_theme_stylebox_override("panel", _ornate_panel(Color("#052b25f2"), GOLD, 18, 3))
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	header.add_child(row)
	var emblem := _label("◆", 28, GOLD)
	emblem.custom_minimum_size.x = 34
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(emblem)
	var title := _display_label("TREASURE 21", 34, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#2c1704"))
	title.add_theme_constant_override("outline_size", 4)
	row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.name = "ChipBalancePanel"
	chip_panel.custom_minimum_size.x = 180
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#061d18e8"), Color("#8d6a28"), 12, 2))
	chip_label = _label("CASINO CHIP\n0", 16, CREAM)
	chip_label.name = "ChipBalanceLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_status(root: VBoxContainer) -> void:
	status_label = _label("BETを選んで、21を目指そう", 24, Color.WHITE)
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 36
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	root.add_child(status_label)

func _build_setup(root: VBoxContainer) -> void:
	var preview := PanelContainer.new()
	preview.name = "RulesPreview"
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_theme_stylebox_override("panel", _ornate_panel(Color("#05251ff0"), GOLD, 20, 3))
	root.add_child(preview)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	preview.add_child(box)
	var setup_chest := _chest_texture(CHEST_TREASURE, Vector2(220, 220))
	setup_chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(setup_chest)
	var title := _display_label("CHOOSE YOUR TREASURE", 29, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var copy := _label("合計21でTREASURE。17から持ち帰れます。\nGOLDENにぴったり止まると即ボーナス！", 25, CREAM)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(copy)
	var table := _label("17 ×0.4   18 ×0.55   19 ×0.8   20 ×1.0   21 ×1.7", 21, Color("#f5cf78"))
	table.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(table)
	var golden_copy := _label("GOLDEN TREASURE  18 ×1.25  ·  19 ×1.4  ·  20 ×1.6", 20, GOLD_LIGHT)
	golden_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	golden_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(golden_copy)

	var caption := _label("BET", 20, GOLD_LIGHT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(caption)
	var bet_row := HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bet_row.add_theme_constant_override("separation", 6)
	root.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button := _button("%d CHIP" % amount)
		button.name = "Bet_%d" % amount
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	start_button = _button("GAME START", true)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.y = 96
	start_button.add_theme_font_size_override("font_size", 25)
	start_button.pressed.connect(_start_game)
	root.add_child(start_button)

func _build_active(root: VBoxContainer) -> void:
	_build_treasure_track(root)

	play_panel = PanelContainer.new()
	play_panel.name = "Treasure21DiePanel"
	play_panel.custom_minimum_size.y = 286
	play_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_panel.add_theme_stylebox_override("panel", _ornate_panel(Color("#04231ef2"), Color("#8b6728"), 18, 2))
	root.add_child(play_panel)
	var die_box := VBoxContainer.new()
	die_box.alignment = BoxContainer.ALIGNMENT_CENTER
	die_box.add_theme_constant_override("separation", 2)
	play_panel.add_child(die_box)
	status_banner = PanelContainer.new()
	status_banner.name = "StatusBanner"
	status_banner.custom_minimum_size.y = 46
	status_banner.add_theme_stylebox_override("panel", _panel(Color("#7c281f"), GOLD, 10, 2))
	status_banner_label = _display_label("DANGER ZONE", 27, GOLD_LIGHT)
	status_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_banner.add_child(status_banner_label)
	die_box.add_child(status_banner)
	var total_word := _display_label("TOTAL", 30, GOLD_LIGHT)
	total_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	die_box.add_child(total_word)
	total_label = _display_label("0", 122, GOLD_LIGHT)
	total_label.name = "TotalLabel"
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.custom_minimum_size.y = 132
	total_label.add_theme_color_override("font_outline_color", Color("#301900"))
	total_label.add_theme_constant_override("outline_size", 5)
	die_box.add_child(total_label)
	var die_center := CenterContainer.new()
	die_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	die_box.add_child(die_center)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "Treasure21Die3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(380, 270)
	die_center.add_child(dice_presentation)
	total_caption = _label("まだまだ安全", 27, CREAM)
	total_caption.name = "TotalCaption"
	total_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_caption.custom_minimum_size.y = 34
	die_box.add_child(total_caption)
	die_face_label = _label("?", 1, Color.TRANSPARENT)
	die_face_label.name = "DieFaceForTest"
	die_face_label.visible = false
	play_panel.add_child(die_face_label)

	danger_panel = PanelContainer.new()
	danger_panel.name = "FuturePreviewPanel"
	danger_panel.custom_minimum_size.y = 178
	danger_panel.add_theme_stylebox_override("panel", _panel(Color("#031b17f2"), Color("#80632c"), 16, 2))
	root.add_child(danger_panel)
	var danger_box := VBoxContainer.new()
	danger_box.add_theme_constant_override("separation", 3)
	danger_panel.add_child(danger_box)
	var preview_header := HBoxContainer.new()
	preview_header.add_theme_constant_override("separation", 8)
	danger_box.add_child(preview_header)
	preview_title = _label("ⓘ 17から次の出目を公開", 24, GOLD_LIGHT)
	preview_title.name = "DangerZoneTitle"
	preview_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_header.add_child(preview_title)
	preview_hint = _label("16までは安全", 20, Color("#b9c9bf"))
	preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_header.add_child(preview_hint)
	danger_grid = GridContainer.new()
	danger_grid.name = "DangerPreviewGrid"
	danger_grid.columns = 6
	danger_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	danger_grid.add_theme_constant_override("h_separation", 5)
	danger_grid.add_theme_constant_override("v_separation", 4)
	danger_box.add_child(danger_grid)
	for face: int in range(1, 7):
		var cell := PanelContainer.new()
		cell.name = "Face_%d" % face
		cell.custom_minimum_size = Vector2(0, 116)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", _panel(Color("#33264d"), Color("#705e84"), 9, 1))
		var label := _label("%d\n?" % face, 21, CREAM)
		label.name = "OutcomeLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.add_child(label)
		danger_grid.add_child(cell)
		danger_cells[face] = {"panel": cell, "label": label}

	var actions := HBoxContainer.new()
	actions.name = "Treasure21Actions"
	actions.add_theme_constant_override("separation", 7)
	root.add_child(actions)
	cashout_button = _button("CASH OUT", true)
	cashout_button.name = "CashOutButton"
	cashout_button.custom_minimum_size = Vector2(0, 102)
	cashout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cashout_button.add_theme_font_size_override("font_size", 25)
	cashout_button.pressed.connect(_on_cashout_pressed)
	actions.add_child(cashout_button)
	roll_button = _button("ROLL", false)
	roll_button.name = "RollButton"
	roll_button.custom_minimum_size = Vector2(0, 102)
	roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_button.add_theme_font_size_override("font_size", 28)
	roll_button.pressed.connect(_on_roll_pressed)
	actions.add_child(roll_button)
	_style_action_buttons()

func _build_treasure_track(root: VBoxContainer) -> void:
	treasure_track_panel = PanelContainer.new()
	treasure_track_panel.name = "TreasureTrackPanel"
	treasure_track_panel.custom_minimum_size.y = 164
	treasure_track_panel.add_theme_stylebox_override("panel", _ornate_panel(Color("#031e1af2"), GOLD, 18, 2))
	root.add_child(treasure_track_panel)
	var track_row := HBoxContainer.new()
	track_row.add_theme_constant_override("separation", 8)
	treasure_track_panel.add_child(track_row)

	var golden_box := VBoxContainer.new()
	golden_box.custom_minimum_size.x = 144
	golden_box.add_theme_constant_override("separation", 0)
	track_row.add_child(golden_box)
	var golden_title := _display_label("GOLDEN", 21, GOLD_LIGHT)
	golden_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	golden_box.add_child(golden_title)
	track_chest = _chest_texture(CHEST_CLOSED, Vector2(92, 76))
	track_chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	golden_box.add_child(track_chest)
	var golden_caption := _label("現在の目標", 18, Color("#d2c6a7"))
	golden_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	golden_box.add_child(golden_caption)
	golden_label = _display_label("19", 34, GOLD_LIGHT)
	golden_label.name = "GoldenLabel"
	golden_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	golden_box.add_child(golden_label)

	var divider := VSeparator.new()
	divider.add_theme_constant_override("separation", 8)
	track_row.add_child(divider)
	var progress_box := VBoxContainer.new()
	progress_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_box.add_theme_constant_override("separation", 2)
	track_row.add_child(progress_box)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 4)
	progress_box.add_child(steps)
	for value: int in range(17, 22):
		var step := VBoxContainer.new()
		step.name = "Step%d" % value
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.add_theme_constant_override("separation", 0)
		var number := _display_label(str(value), 27, CREAM)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step.add_child(number)
		var chest := _chest_texture(CHEST_CLOSED if value < 21 else CHEST_TREASURE, Vector2(76, 68))
		chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chest.modulate = Color("#87a69d") if value < 21 else Color.WHITE
		step.add_child(chest)
		var marker := _label("●", 23, Color("#4f776a"))
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step.add_child(marker)
		steps.add_child(step)
		track_steps[value] = {"number": number, "chest": chest, "marker": marker}
	total_meter = ProgressBar.new()
	total_meter.name = "TotalProgress"
	total_meter.min_value = 16.0
	total_meter.max_value = 21.0
	total_meter.show_percentage = false
	total_meter.custom_minimum_size.y = 12
	total_meter.add_theme_stylebox_override("background", _panel(Color("#08251f"), Color("#725725"), 6, 1))
	total_meter.add_theme_stylebox_override("fill", _panel(GOLD, GOLD_LIGHT, 6, 1))
	progress_box.add_child(total_meter)
	bet_label = _label("BET 20", 19, Color("#d6c9a7"))
	bet_label.name = "BetLabel"
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_box.add_child(bet_label)

func _style_action_buttons() -> void:
	if cashout_button != null:
		cashout_button.add_theme_stylebox_override("normal", _ornate_panel(Color("#07523c"), GOLD, 15, 3))
		cashout_button.add_theme_stylebox_override("hover", _ornate_panel(Color("#0b6d4f"), GOLD_LIGHT, 15, 3))
		cashout_button.add_theme_stylebox_override("pressed", _ornate_panel(Color("#064130"), GOLD, 15, 3))
	if roll_button != null:
		roll_button.add_theme_stylebox_override("normal", _ornate_panel(Color("#0a6448"), GOLD, 15, 3))
		roll_button.add_theme_stylebox_override("hover", _ornate_panel(Color("#0e805d"), GOLD_LIGHT, 15, 3))
		roll_button.add_theme_stylebox_override("pressed", _ornate_panel(Color("#064630"), GOLD, 15, 3))
		roll_button.add_theme_color_override("font_color", GOLD_LIGHT)

func _apply_responsive_layout() -> void:
	if play_panel == null or dice_presentation == null:
		return
	var compact: bool = size.y > 0.0 and size.y < 1450.0
	play_panel.custom_minimum_size.y = 240.0 if compact else 286.0
	dice_presentation.custom_minimum_size = Vector2(300, 190) if compact else Vector2(380, 270)
	if total_label != null:
		total_label.custom_minimum_size.y = 108.0 if compact else 132.0
		total_label.add_theme_font_size_override("font_size", 104 if compact else 122)
	if status_banner != null:
		status_banner.custom_minimum_size.y = 40.0 if compact else 46.0
	if danger_panel != null:
		danger_panel.custom_minimum_size.y = 150.0 if compact else 178.0
	for cell_data: Dictionary in danger_cells.values():
		var cell := cell_data.get("panel") as PanelContainer
		if cell != null:
			cell.custom_minimum_size.y = 92.0 if compact else 116.0
	if cashout_button != null:
		cashout_button.custom_minimum_size.y = 88.0 if compact else 102.0
	if roll_button != null:
		roll_button.custom_minimum_size.y = 88.0 if compact else 102.0
	if back_button != null:
		back_button.custom_minimum_size.y = 56.0 if compact else 68.0

func _build_result(root: VBoxContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	root.add_child(spacer)
	var card := PanelContainer.new()
	card.name = "ResultCard"
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _ornate_panel(Color("#04251ff4"), GOLD, 20, 3))
	root.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	result_chest = _chest_texture(CHEST_TREASURE, Vector2(250, 250))
	result_chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(result_chest)
	result_label = _display_label("RESULT", 38, GOLD_LIGHT)
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	result_payout_label = _display_label("0 CHIP", 44, CREAM)
	result_payout_label.name = "ResultPayoutLabel"
	result_payout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_payout_label)
	result_profit_label = _label("PROFIT 0", 19, GOLD_LIGHT)
	result_profit_label.name = "ResultProfitLabel"
	result_profit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_profit_label)
	result_detail_label = _label("", 18, Color.WHITE)
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(result_detail_label)

	again_button = _button("PLAY AGAIN", true)
	again_button.name = "AgainButton"
	again_button.custom_minimum_size.y = 104
	again_button.add_theme_font_size_override("font_size", 23)
	again_button.pressed.connect(_on_again_pressed)
	root.add_child(again_button)
	change_bet_button = _button("CHANGE BET", false)
	change_bet_button.name = "ChangeBetButton"
	change_bet_button.custom_minimum_size.y = 96
	change_bet_button.pressed.connect(_show_setup)
	root.add_child(change_bet_button)
func _resume_or_show_setup() -> void:
	var active := CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		_show_setup()
		return
	game_id = str(active.get("game_id", ""))
	var session: Dictionary = active.get("session", {}) as Dictionary
	game = _normalise_game(session, int(active.get("bet", selected_bet)))
	selected_bet = int(game.get("bet", active.get("bet", 20)))
	settled = false
	pending_roll = _extract_pending(session)
	if pending_roll.is_empty():
		pending_roll = _extract_pending(active)
	if not pending_roll.is_empty():
		view_state = "rolling"
		rolling = true
		setup_view.visible = false
		active_view.visible = true
		result_view.visible = false
		call_deferred("_resume_pending_roll")
	else:
		view_state = "active"
		rolling = false
		setup_view.visible = false
		active_view.visible = true
		result_view.visible = false
		_refresh_all()

func _normalise_game(source: Dictionary, fallback_bet: int = 20) -> Dictionary:
	var candidate := source.duplicate(true)
	if candidate.has("game") and candidate["game"] is Dictionary:
		candidate = (candidate["game"] as Dictionary).duplicate(true)
	var bet := maxi(0, int(candidate.get("bet", candidate.get("stake", fallback_bet))))
	var golden := int(candidate.get("golden_number", candidate.get("golden", 19)))
	var fresh := Treasure21Script.new_game(bet, golden)
	for key: Variant in candidate.keys():
		fresh[str(key)] = candidate[key]
	fresh["bet"] = bet
	fresh["stake"] = bet
	fresh["total"] = int(fresh.get("total", fresh.get("current_total", 0)))
	fresh["current_total"] = int(fresh.get("current_total", fresh.get("total", 0)))
	fresh["golden_number"] = golden if golden in GOLDEN_NUMBERS else 19
	fresh["golden"] = int(fresh["golden_number"])
	return fresh

func _extract_pending(source: Dictionary) -> Dictionary:
	var values: Variant = source.get("pending_rolls", [])
	if values is Array and not (values as Array).is_empty() and (values as Array)[0] is Dictionary:
		return ((values as Array)[0] as Dictionary).duplicate(true)
	return {}

func _resume_pending_roll() -> void:
	if pending_roll.is_empty() or not is_inside_tree():
		return
	await _animate_roll(int(pending_roll.get("value", 1)))
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _select_bet(amount: int) -> void:
	if amount not in BET_AMOUNTS or rolling:
		return
	selected_bet = amount
	_save_meta_last_bet(amount)
	_play_ui_sfx(&"select", false)
	_refresh_bet_buttons()

func _start_game() -> void:
	if rolling or selected_bet not in BET_AMOUNTS:
		return
	if CasinoBankScript.balance() < selected_bet:
		status_label.text = "CHIPが足りない。"
		_play_ui_sfx(&"blocked", false)
		_refresh_bet_buttons()
		return
	var golden := _next_golden_number()
	var initial := _next_roll_value()
	var initial_game := Treasure21Script.new_game(selected_bet, golden)
	var initial_pending := {"kind": "roll", "value": initial, "from_total": 0, "roll_index": 1}
	initial_game["pending_rolls"] = [initial_pending]
	var receipt: Dictionary = CasinoBankScript.begin_game(FACILITY_ID, selected_bet, initial_game)
	if not bool(receipt.get("ok", false)):
		if bool(receipt.get("already_active", false)):
			_resume_or_show_setup()
		else:
			status_label.text = "開始できません。CHIP残高を確認して。"
			_refresh_bet_buttons()
		return
	game_id = str(receipt.get("game_id", ""))
	game = initial_game.duplicate(true)
	pending_roll = initial_pending.duplicate(true)
	settled = false
	rolling = true
	view_state = "rolling"
	_save_meta_on_start(selected_bet)
	setup_view.visible = false
	active_view.visible = true
	result_view.visible = false
	_play_ui_sfx(&"start", false)
	status_label.text = "GOLDENを決めて、最初の目を振る..."
	_refresh_all()
	await _animate_roll(initial)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _on_roll_pressed() -> void:
	if rolling or game.is_empty() or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var total := int(game.get("total", 0))
	var roll := _next_roll_value()
	pending_roll = {
		"kind": "roll",
		"value": roll,
		"from_total": total,
		"roll_index": int(game.get("rolled_count", 0)) + 1,
	}
	game["pending_rolls"] = [pending_roll.duplicate(true)]
	# The queue is persisted before animation so a process death cannot reroll.
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	rolling = true
	view_state = "rolling"
	status_label.text = "ROLL中..."
	_refresh_all()
	_play_ui_sfx(&"roll", false)
	await _animate_roll(roll)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _resolve_pending_roll(pending: Dictionary) -> void:
	if pending.is_empty() or game.is_empty():
		return
	var value := clampi(int(pending.get("value", 1)), 1, 6)
	game = Treasure21Script.apply_roll(game, value)
	game["pending_rolls"] = []
	pending_roll = {}
	rolling = false
	if bool(game.get("finished", false)):
		# Clear the queue before settlement as a belt-and-suspenders guard for
		# devices that briefly suspend between two save writes.
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
		_settle_finished_game()
	else:
		view_state = "active"
		status_label.text = "TOTAL %d。次の一手を選ぶ。" % int(game.get("total", 0))
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
		game.erase("pending_rolls")
		_play_ui_sfx(&"progress-step", true)
	_refresh_all()

func _on_cashout_pressed() -> void:
	if rolling or game.is_empty() or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var next := Treasure21Script.cash_out(game)
	if next == game or int(next.get("payout", 0)) <= 0:
		status_label.text = "TOTAL 17以上でCASH OUTできます。"
		_play_ui_sfx(&"blocked", false)
		return
	game = next
	_settle_finished_game()

func _settle_finished_game() -> void:
	if settled:
		_show_result()
		return
	var payout := maxi(0, int(game.get("payout", 0)))
	var receipt: Dictionary = CasinoBankScript.settle_game(FACILITY_ID, payout, {
		"result": str(game.get("result", "")),
		"total": int(game.get("total", 0)),
		"golden_number": int(game.get("golden_number", 19)),
		"bet": int(game.get("bet", selected_bet)),
	}, game_id)
	if bool(receipt.get("already_settled", false)):
		payout = int(receipt.get("payout", payout))
		game["payout"] = payout
	settled = bool(receipt.get("ok", false)) or bool(receipt.get("already_settled", false))
	rolling = false
	view_state = "result"
	if settled:
		_mark_meta_completed()
	if str(game.get("result", "")) == "bust":
		_play_ui_sfx(&"error", true)
	else:
		_play_ui_sfx(&"complete", true)
		if payout > 0:
			_spawn_confetti()
	_show_result()

func _show_result() -> void:
	view_state = "result"
	setup_view.visible = false
	active_view.visible = false
	result_view.visible = true
	var result_kind := str(game.get("result", ""))
	match result_kind:
		"bust":
			result_label.text = "BUST"
			result_detail_label.text = "TOTAL %d。21を超えたためBETを失いました。" % int(game.get("total", 0))
			if result_chest != null:
				result_chest.texture = CHEST_CLOSED
				result_chest.modulate = Color("#7d756b")
		"treasure":
			result_label.text = "TREASURE 21!"
			result_detail_label.text = "21に到達。最高配当を獲得しました。"
			if result_chest != null:
				result_chest.texture = CHEST_TREASURE
				result_chest.modulate = Color.WHITE
		"golden":
			result_label.text = "GOLDEN TREASURE!"
			result_detail_label.text = "GOLDEN %d にぴったり到達。自動CASH OUT。" % int(game.get("golden_number", 19))
			if result_chest != null:
				result_chest.texture = CHEST_OPENING
				result_chest.modulate = Color.WHITE
		"cashout":
			result_label.text = "CASH OUT"
			result_detail_label.text = "TOTAL %d で持ち帰りました。" % int(game.get("total", 0))
			if result_chest != null:
				result_chest.texture = CHEST_CHARGED
				result_chest.modulate = Color.WHITE
		_:
			result_label.text = "RESULT"
			result_detail_label.text = "ゲーム終了。"
	var payout := int(game.get("payout", 0))
	var bet := int(game.get("bet", selected_bet))
	result_payout_label.text = "RETURN %d CHIP（BET込み）" % payout
	result_profit_label.text = "NET  %+d CHIP" % (payout - bet)
	status_label.text = "もう一度、TREASUREを狙う？"
	roll_button.disabled = true
	cashout_button.disabled = true
	back_button.disabled = false
	_refresh_all()
	call_deferred("_animate_result_reveal")

func _animate_result_reveal() -> void:
	if result_view == null or not result_view.visible:
		return
	VisualFeedback.reveal(result_view, 0.26)

func _on_again_pressed() -> void:
	if rolling:
		return
	_start_game()

func _show_setup() -> void:
	if rolling:
		return
	game = {}
	game_id = ""
	pending_roll = {}
	rolling = false
	settled = false
	view_state = "setup"
	setup_view.visible = true
	active_view.visible = false
	result_view.visible = false
	_restore_affordable_bet()
	status_label.text = "BETを選んで、21を目指そう"
	_refresh_all()

func _on_back_pressed() -> void:
	if rolling or (not game.is_empty() and bool(game.get("active", false)) and not bool(game.get("finished", false))):
		status_label.text = "ゲーム終了までEXITできません。"
		_play_ui_sfx(&"blocked", false)
		return
	_play_ui_sfx(&"back", false)
	back_requested.emit()

func _next_roll_value() -> int:
	if queued_roll_value in range(1, 7):
		var forced := queued_roll_value
		queued_roll_value = 0
		return forced
	if rng_seed != 0:
		rng.seed = rng_seed
		rng_seed = 0
	return rng.randi_range(1, 6)

func _next_golden_number() -> int:
	if queued_golden_number in GOLDEN_NUMBERS:
		var forced := queued_golden_number
		queued_golden_number = 0
		return forced
	var meta := _load_meta()
	if int(meta.get("completed_count", 0)) <= 0 and not bool(meta.get("first_game_complete", false)):
		return 19
	if rng_seed != 0:
		rng.seed = rng_seed
		rng_seed = 0
	return rng.randi_range(18, 20)

func _animate_roll(value: int) -> void:
	if not is_instance_valid(dice_presentation):
		await get_tree().create_timer(ROLL_SECONDS + SETTLE_SECONDS).timeout
		return
	var start := int(game.get("last_roll", 1))
	if start < 1 or start > 6:
		start = 1
	dice_presentation.present([start], true, 1)
	await get_tree().create_timer(ROLL_SECONDS).timeout
	if not is_inside_tree():
		return
	dice_presentation.flip_to_face(value)
	die_face_label.text = str(value)
	await get_tree().create_timer(SETTLE_SECONDS).timeout

func _refresh_all() -> void:
	if chip_label != null:
		chip_label.text = "CASINO CHIP\n%d" % CasinoBankScript.balance()
	_refresh_bet_buttons()
	if game.is_empty():
		if danger_panel != null:
			danger_panel.visible = false
		return
	var total := int(game.get("total", game.get("current_total", 0)))
	if total_label != null:
		total_label.text = str(total)
	if bet_label != null:
		bet_label.text = "BET  %d" % int(game.get("bet", selected_bet))
	if golden_label != null:
		golden_label.text = str(int(game.get("golden_number", 19)))
	if total_meter != null:
		total_meter.value = clampf(float(total), 16.0, 21.0)
	if total_caption != null:
		if total >= 20:
			total_caption.text = "1だけでTREASURE"
		elif total >= 17:
			var safe_faces: int = clampi(21 - total, 0, 6)
			total_caption.text = "%d / 6 がセーフ" % safe_faces
		else:
			total_caption.text = "まだまだ安全"
	if status_banner != null and status_banner_label != null:
		status_banner.visible = total >= 17
		if total >= 20:
			status_banner_label.text = "ONE AWAY"
			status_banner.add_theme_stylebox_override("panel", _ornate_panel(Color("#7b1c16"), GOLD_LIGHT, 10, 3))
		elif total >= 17:
			status_banner_label.text = "CASH OUT AVAILABLE"
			status_banner.add_theme_stylebox_override("panel", _panel(Color("#79441d"), GOLD, 10, 2))
	_refresh_track(total)
	if danger_panel != null:
		danger_panel.visible = bool(game.get("active", false)) and not bool(game.get("finished", false))
	if danger_panel.visible:
		_refresh_danger_preview()
	var can_cash := Treasure21Script.can_cash_out(game) and not rolling
	if cashout_button != null:
		cashout_button.disabled = not can_cash
		var cash_value: int = Treasure21Script.payout_for_total(int(game.get("bet", selected_bet)), total)
		cashout_button.text = "CASH OUT\n%s" % ("%d CHIP" % cash_value if can_cash else "まだ不可")
	if roll_button != null:
		roll_button.disabled = rolling or not bool(game.get("active", false)) or bool(game.get("finished", false))
		roll_button.text = "ROLL\n%s" % ("1 / 6でTREASURE" if total == 20 else "次の1D6")
	back_button.disabled = rolling or (bool(game.get("active", false)) and not bool(game.get("finished", false)))

func _refresh_track(total: int) -> void:
	var golden: int = int(game.get("golden_number", 19))
	if track_chest != null:
		if total >= 20:
			track_chest.texture = CHEST_OPENING
		elif total >= 17:
			track_chest.texture = CHEST_CHARGED
		else:
			track_chest.texture = CHEST_CLOSED
	for value: int in track_steps:
		var step: Dictionary = track_steps[value] as Dictionary
		var number := step.get("number") as Label
		var chest := step.get("chest") as TextureRect
		var marker := step.get("marker") as Label
		if number == null or chest == null or marker == null:
			continue
		var reached: bool = total >= value
		var current: bool = total == value
		var is_golden: bool = value == golden
		number.add_theme_color_override("font_color", GOLD_LIGHT if current or is_golden else CREAM)
		marker.text = "◆" if current else ("●" if reached else "○")
		marker.add_theme_color_override("font_color", GOLD_LIGHT if current else (TEAL if reached else Color("#557168")))
		if value == 21:
			chest.texture = CHEST_TREASURE
		elif current:
			chest.texture = CHEST_CHARGED
		else:
			chest.texture = CHEST_CLOSED
		chest.modulate = Color.WHITE if current or is_golden or value == 21 else Color("#78988e")

func _refresh_danger_preview() -> void:
	var total := int(game.get("total", 0))
	var golden := int(game.get("golden_number", 19))
	var bet := int(game.get("bet", selected_bet))
	danger_preview = Treasure21Script.danger_preview(total, golden)
	if total < 17:
		if preview_title != null:
			preview_title.text = "ⓘ 17から次の出目を公開"
		if preview_hint != null:
			preview_hint.text = "16までは安全"
		for face: int in range(1, 7):
			var hidden_cell: Dictionary = danger_cells.get(face, {})
			var hidden_panel := hidden_cell.get("panel") as PanelContainer
			var hidden_label := hidden_cell.get("label") as Label
			if hidden_panel == null or hidden_label == null:
				continue
			hidden_label.text = "%d\n?" % face
			hidden_label.add_theme_color_override("font_color", Color("#8c948b"))
			hidden_panel.add_theme_stylebox_override("panel", _panel(Color("#071c18"), Color("#5c4a27"), 9, 1))
		return
	if preview_title != null:
		preview_title.text = "ⓘ 次の出目でどうなる？"
	if preview_hint != null:
		var bust_from: int = maxi(1, 22 - total)
		preview_hint.text = "%d以上でBUST" % bust_from if bust_from <= 6 else "BUSTなし"
	for outcome: Dictionary in danger_preview:
		var face := int(outcome.get("face", 0))
		var cell: Dictionary = danger_cells.get(face, {})
		var panel := cell.get("panel") as PanelContainer
		var label := cell.get("label") as Label
		if panel == null or label == null:
			continue
		var kind := str(outcome.get("kind", "progress"))
		var next_total := int(outcome.get("next_total", total + face))
		var payout := 0
		if kind == "golden":
			payout = Treasure21Script.golden_payout_for(bet, golden)
		elif kind == "treasure":
			payout = Treasure21Script.payout_for_total(bet, 21)
		elif next_total >= 17 and next_total <= 20:
			payout = Treasure21Script.payout_for_total(bet, next_total)
		var line := "%d\n" % face
		match kind:
			"bust":
				line += "×\nBUST"
			"treasure":
				line += "◆\n21"
			"golden":
				line += "★\nGOLDEN"
			_:
				line += "↓\n%d" % next_total
		if payout > 0 and kind != "bust":
			line += "\n%d CHIP" % payout
		label.text = line
		var accent := Color("#5f765f")
		var fill := Color("#082820")
		var text_color := CREAM
		match kind:
			"bust":
				accent = Color("#e34b37")
				fill = Color("#3d0e0b")
				text_color = Color("#ffc3b4")
			"treasure":
				accent = GOLD_LIGHT
				fill = Color("#4a3408")
				text_color = GOLD_LIGHT
			"golden":
				accent = GOLD_LIGHT
				fill = Color("#50400f")
				text_color = GOLD_LIGHT
			"cashout":
				accent = TEAL
				fill = Color("#254044")
		label.add_theme_color_override("font_color", text_color)
		panel.add_theme_stylebox_override("panel", _panel(fill, accent, 9, 2))

func _refresh_bet_buttons() -> void:
	if chip_label == null:
		return
	var chips := CasinoBankScript.balance()
	for amount: int in bet_buttons:
		var button := bet_buttons[amount] as Button
		button.disabled = chips < amount or rolling
		button.text = ("● " if amount == selected_bet else "") + "%d CHIP" % amount
		_apply_button_state(button, amount == selected_bet)
	if start_button != null:
		start_button.disabled = chips < selected_bet or rolling

func _restore_affordable_bet() -> void:
	var meta := _load_meta()
	var remembered := int(meta.get("last_bet", selected_bet))
	if remembered not in BET_AMOUNTS:
		remembered = 20
	var chips := CasinoBankScript.balance()
	selected_bet = remembered
	for amount: int in BET_AMOUNTS:
		if amount <= chips and amount <= remembered:
			selected_bet = amount
	for index: int in range(BET_AMOUNTS.size() - 1, -1, -1):
		var amount := int(BET_AMOUNTS[index])
		if amount <= chips and (remembered > chips or selected_bet > chips):
			selected_bet = amount
			break
	if chips < 5:
		selected_bet = 5

func _load_meta() -> Dictionary:
	var data := CasinoBankScript.load_data()
	var value: Variant = data.get(META_KEY, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

func _save_meta(meta: Dictionary) -> void:
	var data := CasinoBankScript.load_data()
	var existing: Variant = data.get(META_KEY, {})
	var merged := (existing as Dictionary).duplicate(true) if existing is Dictionary else {}
	for key: Variant in meta.keys():
		merged[str(key)] = meta[key]
	data[META_KEY] = merged
	CasinoBankScript.save_data(data)

func _save_meta_last_bet(amount: int) -> void:
	_save_meta({"last_bet": amount})

func _save_meta_on_start(amount: int) -> void:
	var meta := _load_meta()
	_save_meta({
		"last_bet": amount,
		"play_count": int(meta.get("play_count", 0)) + 1,
	})

func _mark_meta_completed() -> void:
	var meta := _load_meta()
	if bool(meta.get("last_settlement_recorded", false)) and int(meta.get("last_completed_game_count", -1)) == int(meta.get("play_count", 0)):
		return
	var completed := int(meta.get("completed_count", 0)) + 1
	_save_meta({
		"completed_count": completed,
		"first_game_complete": true,
		"last_completed_game_count": int(meta.get("play_count", 0)),
		"last_settlement_recorded": true,
	})

func _spawn_confetti() -> void:
	if effect_layer == null:
		return
	for index: int in 16:
		var piece := ColorRect.new()
		piece.name = "ConfettiPiece"
		piece.size = Vector2(randf_range(4.0, 7.0), randf_range(7.0, 13.0))
		piece.color = [GOLD, GOLD_LIGHT, Color("#fff7df"), Color("#ffb46b")][index % 4]
		piece.rotation = randf_range(-PI, PI)
		piece.position = Vector2(randf_range(0.0, maxf(1.0, effect_layer.size.x)), -18.0)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(piece)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(piece, "position:y", effect_layer.size.y + 24.0, randf_range(0.9, 1.35))
		fall.tween_property(piece, "rotation", piece.rotation + randf_range(-3.0, 3.0), 1.05)
		fall.tween_property(piece, "modulate:a", 0.0, 0.30).set_delay(0.78)
		fall.chain().tween_callback(piece.queue_free)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)

func _stat_box(caption: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6d995"), Color("#a96b2e"), 12, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var cap := _label(caption, 13, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value := _label("-", 20, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _display_label(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.add_theme_font_override("font", DISPLAY_FONT)
	return label

func _chest_texture(texture: Texture2D, minimum_size: Vector2) -> TextureRect:
	var chest := TextureRect.new()
	chest.texture = texture
	chest.custom_minimum_size = minimum_size
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return chest

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.custom_minimum_size = Vector2(90, 96)
	button.add_theme_color_override("font_color", INK if primary else Color("#fff4dc"))
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#d8d0bf"))
	button.add_theme_stylebox_override("normal", _panel(GOLD if primary else Color("#403452"), Color("#a67836") if primary else Color("#705e84"), 12, 2))
	button.add_theme_stylebox_override("hover", _panel(GOLD_LIGHT if primary else Color("#51436a"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel(Color("#d99d2c") if primary else Color("#302641"), GOLD, 12, 2))
	button.add_theme_stylebox_override("disabled", _panel(Color("#514c45"), Color("#766d5f"), 12, 1))
	var focus_style := _panel(Color.TRANSPARENT, GOLD_LIGHT, 14, 3)
	focus_style.draw_center = false
	focus_style.expand_margin_left = 3.0
	focus_style.expand_margin_top = 3.0
	focus_style.expand_margin_right = 3.0
	focus_style.expand_margin_bottom = 3.0
	button.add_theme_stylebox_override("focus", focus_style)
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

func _ornate_panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := _panel(fill, border, radius, width)
	style.shadow_color = Color("#000000a8")
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)
	style.corner_detail = 12
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
