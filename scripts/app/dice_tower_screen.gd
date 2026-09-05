class_name DiceTowerScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const CasinoBackButton = preload("res://scripts/ui/casino_back_button.gd")
const CasinoHowTo3StepsScript = preload("res://scripts/ui/casino_how_to_3_steps.gd")
const TowerScript = preload("res://scripts/game/dice_tower_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const CASINO_BACKGROUND: Texture2D = preload("res://assets/casino/dice_roulette/ui/casino-table-bg-v1.png")
const TOWER_TEXTURE: Texture2D = preload("res://assets/casino/dice_tower/ui/dice-tower-ten-floor-v2.png")
const CHIP_TEXTURE: Texture2D = preload("res://assets/casino/vault_break/ui/chip-20-red-v1.png")

const BET_AMOUNTS := [10, 20, 50]
const FACILITY_ID := "dice_tower"
const ROLL_SECONDS := 0.75
const RESULT_SECONDS := 0.32
const RESULT_DIM_ALPHA := 0.68
const GOLD := Color("#f2bf4c")
const GOLD_LIGHT := Color("#ffe6a0")
const INK := Color("#322315")
const NAVY := Color("#181430")
const PLUM := Color("#2a1c40")
const RED := Color("#c83c32")
const GREEN := Color("#3f7d58")

var game: Dictionary = {}
var selected_bet: int = 20
var rolling: bool = false
var rng_seed: int = 0
var queued_roll_value: int = 0
var rng := RandomNumberGenerator.new()
var game_id: String = ""
var pending_roll: Dictionary = {}
var settled: bool = false

var chip_label: Label
var status_label: Label
var floor_label: Label
var payout_label: Label
var risk_label: Label
var cashout_button: Button
var roll_button: Button
var start_button: Button
var setup_view: VBoxContainer
var active_view: VBoxContainer
var tower_frame: PanelContainer
var tower_stack: VBoxContainer
var dice_presentation: DicePresentation3D
var face_label: Label
var tutorial_overlay: Control
var tutorial_page_label: Label
var tutorial_body: Label
var tutorial_next_button: Button
var effect_layer: Control
var balance_preview_label: Label
var last_roll_label: Label
var result_overlay: Control
var result_card: PanelContainer
var result_title_label: Label
var result_dice_label: Label
var result_floor_label: Label
var result_reward_label: Label
var result_bet_label: Label
var back_button: Button
var bet_buttons: Dictionary = {}
var floor_panels: Dictionary = {}
var tutorial_page: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_node("/root/BgmManager").call("play_dice_tower")
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	_build_ui()
	if CasinoBankScript.has_active_game(FACILITY_ID):
		tutorial_overlay.visible = false
		_resume_or_show_setup()
	else:
		_show_tutorial_page(0)
		_show_setup()

func _build_ui() -> void:
	var bg: TextureRect = TextureRect.new()
	bg.name = "CasinoBackground"
	bg.texture = CASINO_BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var tint: ColorRect = ColorRect.new()
	tint.name = "BackgroundTint"
	tint.color = Color("#030b12a8")
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tint)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.name = "ScreenVBox"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header: PanelContainer = PanelContainer.new()
	header.name = "Header"
	header.custom_minimum_size.y = 128
	header.add_theme_stylebox_override("panel", _panel(Color("#6b0d17f2"), GOLD_LIGHT, 34, 5, 18))
	root.add_child(header)
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 14)
	header.add_child(header_row)
	back_button = _button("カジノへ戻る")
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size = Vector2(168, 96)
	back_button.pressed.connect(_on_back_pressed)
	CasinoBackButton.configure(back_button)
	header_row.add_child(back_button)
	var title: Label = _label("DICE TOWER", 54, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#39121f"))
	title.add_theme_constant_override("outline_size", 9)
	header_row.add_child(title)
	var help: Button = _button("?")
	help.name = "HelpButton"
	help.custom_minimum_size = Vector2(96, 96)
	help.add_theme_font_size_override("font_size", 48)
	help.pressed.connect(_open_tutorial)
	header_row.add_child(help)

	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.name = "InfoBar"
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 12)
	root.add_child(info_row)
	var chip_panel: PanelContainer = PanelContainer.new()
	chip_panel.custom_minimum_size = Vector2(340, 70)
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#061b1aee"), GOLD, 30, 3, 14))
	var chip_row: HBoxContainer = HBoxContainer.new()
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip_row.add_theme_constant_override("separation", 10)
	chip_panel.add_child(chip_row)
	var chip_icon: TextureRect = TextureRect.new()
	chip_icon.texture = CHIP_TEXTURE
	chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip_icon.custom_minimum_size = Vector2(54, 54)
	chip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_child(chip_icon)
	chip_label = _label("CASINO CHIP\n0", 28, Color("#fff4cd"))
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_row.add_child(chip_label)
	info_row.add_child(chip_panel)

	status_label = _label("まずはBETを選ぼう", 30, Color.WHITE)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 70
	status_label.add_theme_stylebox_override("normal", _panel(Color("#061b1acc"), Color("#986f2d"), 28, 2, 10))
	info_row.add_child(status_label)

	setup_view = VBoxContainer.new()
	setup_view.name = "TowerSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 10)
	root.add_child(setup_view)
	_build_setup_view(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "TowerActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 10)
	active_view.visible = false
	root.add_child(active_view)
	_build_active_view(active_view)

	tutorial_overlay = _build_tutorial_overlay()
	add_child(tutorial_overlay)
	result_overlay = _build_result_overlay()
	add_child(result_overlay)

	effect_layer = Control.new()
	effect_layer.name = "TowerEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 30
	add_child(effect_layer)

func _build_setup_view(root: VBoxContainer) -> void:
	var content: HBoxContainer = HBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	root.add_child(content)

	var preview: PanelContainer = PanelContainer.new()
	preview.name = "TowerPreview"
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_stretch_ratio = 0.78
	preview.add_theme_stylebox_override("panel", _panel(Color("#081b1ad4"), GOLD, 28, 3, 12))
	content.add_child(preview)
	var preview_center: CenterContainer = CenterContainer.new()
	preview.add_child(preview_center)
	var preview_texture: TextureRect = TextureRect.new()
	preview_texture.name = "TowerTexture"
	preview_texture.texture = TOWER_TEXTURE
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Keep the tower art prominent while leaving room for the shared explainer and
	# the primary start action on the authored 720×1600 surface.
	preview_texture.custom_minimum_size = Vector2(218, 520)
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_center.add_child(preview_texture)

	var rules: PanelContainer = PanelContainer.new()
	rules.name = "RulePanel"
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.size_flags_stretch_ratio = 1.22
	# The rule copy itself keeps its large type; a slimmer frame margin recovers
	# the vertical space needed for the shared explainer and start CTA.
	rules.add_theme_stylebox_override("panel", _panel(Color("#062523f2"), GOLD_LIGHT, 30, 4, 8))
	content.add_child(rules)
	var rule_box: VBoxContainer = VBoxContainer.new()
	rule_box.alignment = BoxContainer.ALIGNMENT_CENTER
	# Keep the three rule rows readable while tightening the vertical rhythm for
	# the shared explainer and the primary start action below.
	rule_box.add_theme_constant_override("separation", 5)
	rules.add_child(rule_box)
	var rule_title: Label = _label("ルール", 42, GOLD_LIGHT)
	rule_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule_box.add_child(rule_title)
	var description: Label = _label("サイコロを振って\nタワーをのぼろう！", 31, Color.WHITE)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_box.add_child(description)
	_rule_row(rule_box, "[2–5]", "2〜5", "1階アップ", GREEN)
	_rule_row(rule_box, "[6]", "6", "2階アップ", Color("#2f70b7"))
	_rule_row(rule_box, "[1]", "1", "BUST", RED)
	var warning: Label = _label("1が出るとゲーム終了\nのぼった階数に応じて報酬GET！", 22, Color("#fff2d4"))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_box.add_child(warning)

	var how_to: PanelContainer = CasinoHowTo3StepsScript.build(root, FACILITY_ID, _how_to_steps())
	_compact_how_to_panel(how_to)

	var bet_caption: Label = _label("★  BETを選択してください  ★", 34, Color("#fff2d4"))
	bet_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_caption.custom_minimum_size.y = 56
	root.add_child(bet_caption)
	var bet_row: HBoxContainer = HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bet_row.add_theme_constant_override("separation", 14)
	root.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button: Button = _amount_button(amount)
		button.name = "Bet_%d" % amount
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	var balance_panel: PanelContainer = PanelContainer.new()
	balance_panel.custom_minimum_size.y = 70
	balance_panel.add_theme_stylebox_override("panel", _panel(Color("#061b1ae8"), Color("#986f2d"), 22, 2, 10))
	root.add_child(balance_panel)
	balance_preview_label = _label("BET後の所持チップ", 27, Color("#fff2d4"))
	balance_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_panel.add_child(balance_preview_label)

	start_button = _button("ゲーム開始", true)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.y = 144
	start_button.add_theme_font_size_override("font_size", 50)
	start_button.pressed.connect(_start_game)
	root.add_child(start_button)

func _how_to_steps() -> Array[Dictionary]:
	return [
		{"action": "ベットを決める", "copy": "挑戦するCHIPを選ぼう"},
		{"action": "サイコロを振る", "copy": "登るほど配当アップ"},
		{"action": "引き際を決める", "copy": "危なくなる前に受け取ろう"},
	]

func _compact_how_to_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	# The shared component keeps the same font sizes and three-step structure;
	# this screen only trims decorative padding so its setup CTA remains in view.
	panel.add_theme_stylebox_override("panel", _panel(Color("#130d20ee"), Color("#c9963d"), 18, 2, 4))
	var margin: MarginContainer = panel.find_child("HowToMargin", true, false) as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
	var stack: VBoxContainer = panel.find_child("HowToStack", true, false) as VBoxContainer
	if stack != null:
		stack.add_theme_constant_override("separation", 2)
	for index: int in range(1, 4):
		var row: PanelContainer = panel.find_child("HowToStep%d" % index, true, false) as PanelContainer
		if row == null:
			continue
		row.add_theme_stylebox_override("panel", _panel(Color("#261b34cc"), Color("#695176"), 10, 1, 2))
		var row_margin: MarginContainer = null
		if row.get_child_count() > 0:
			row_margin = row.get_child(0) as MarginContainer
		if row_margin != null:
			row_margin.add_theme_constant_override("margin_top", 0)
			row_margin.add_theme_constant_override("margin_bottom", 0)

func _rule_row(parent: VBoxContainer, dice_text: String, value_text: String, result_text: String, accent: Color) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.y = 80
	panel.add_theme_stylebox_override("panel", _panel(Color("#f7e4ae"), Color("#b87b28"), 18, 3, 12))
	parent.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var dice: Label = _label(dice_text, 42, INK)
	dice.custom_minimum_size.x = 76
	dice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(dice)
	var value: Label = _label(value_text, 44, accent)
	value.custom_minimum_size.x = 92
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	var result: Label = _label("→ " + result_text, 27, accent)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(result)

func _build_active_view(root: VBoxContainer) -> void:
	tower_frame = PanelContainer.new()
	tower_frame.name = "TowerFrame"
	tower_frame.custom_minimum_size.y = 540
	tower_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tower_frame.size_flags_stretch_ratio = 1.8
	tower_frame.add_theme_stylebox_override("panel", _panel(Color("#031416c0"), Color("#7a5a31"), 26, 3, 8))
	root.add_child(tower_frame)
	var tower_canvas: Control = Control.new()
	tower_canvas.name = "TowerCanvas"
	tower_canvas.custom_minimum_size = Vector2(0, 540)
	tower_frame.add_child(tower_canvas)
	var tower_texture: TextureRect = TextureRect.new()
	tower_texture.name = "TowerTexture"
	tower_texture.texture = TOWER_TEXTURE
	tower_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tower_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tower_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tower_canvas.add_child(tower_texture)
	tower_stack = VBoxContainer.new()
	tower_stack.name = "TowerStack"
	tower_stack.anchor_left = 0.25
	tower_stack.anchor_top = 0.205
	tower_stack.anchor_right = 0.75
	tower_stack.anchor_bottom = 0.885
	tower_stack.add_theme_constant_override("separation", 2)
	tower_canvas.add_child(tower_stack)
	for floor_number: int in range(TowerScript.MAX_FLOOR, 0, -1):
		var row: PanelContainer = PanelContainer.new()
		row.name = "Floor_%d" % floor_number
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 38
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_stylebox_override("panel", _panel(Color("#210b08b8"), Color("#c68a2e"), 8, 2, 2))
		tower_stack.add_child(row)
		var text: Label = _label("%dF    ×%.2f" % [floor_number, TowerScript.multiplier_for_floor(floor_number)], 25, Color("#fff2d4"))
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		floor_panels[floor_number] = {"panel": row, "label": text}

	var stats: HBoxContainer = HBoxContainer.new()
	stats.name = "PayoutStats"
	stats.custom_minimum_size.y = 176
	stats.add_theme_constant_override("separation", 10)
	root.add_child(stats)
	var floor_box: Dictionary = _stat_box("FLOOR")
	floor_label = floor_box.label
	stats.add_child(floor_box.panel)
	var payout_box: Dictionary = _stat_box("いま降りると")
	payout_label = payout_box.label
	stats.add_child(payout_box.panel)
	var risk_box: Dictionary = _stat_box("1でロスト")
	risk_label = risk_box.label
	stats.add_child(risk_box.panel)

	var console: CenterContainer = CenterContainer.new()
	console.name = "DiceConsole"
	console.custom_minimum_size.y = 144
	root.add_child(console)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "TowerDie3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(310, 140)
	console.add_child(dice_presentation)
	face_label = _label("", 1, Color.TRANSPARENT)
	face_label.name = "RolledFaceLabel"
	face_label.visible = false
	add_child(face_label)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "TowerActions"
	actions.add_theme_constant_override("separation", 16)
	root.add_child(actions)
	cashout_button = _button("ここで受け取る", false)
	cashout_button.name = "CashOutButton"
	cashout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cashout_button.custom_minimum_size.y = 176
	cashout_button.add_theme_font_size_override("font_size", 38)
	cashout_button.disabled = true
	cashout_button.pressed.connect(_on_cashout_pressed)
	actions.add_child(cashout_button)
	roll_button = _button("サイコロを振る\nもう1回振る", true)
	roll_button.name = "RollButton"
	roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_button.custom_minimum_size.y = 176
	roll_button.add_theme_font_size_override("font_size", 40)
	roll_button.pressed.connect(_on_roll_pressed)
	actions.add_child(roll_button)
	last_roll_label = _label("前回：—", 28, Color("#fff2d4"))
	last_roll_label.name = "LastRollInfo"
	last_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	last_roll_label.custom_minimum_size.y = 44
	last_roll_label.add_theme_stylebox_override("normal", _panel(Color("#061b1ae8"), GOLD, 20, 2, 8))
	root.add_child(last_roll_label)

func _build_tutorial_overlay() -> Control:
	var overlay: Control = Control.new()
	overlay.name = "TowerTutorial"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.name = "TutorialCard"
	card.custom_minimum_size.x = 600
	card.add_theme_stylebox_override("panel", _panel(Color("#061f1df8"), GOLD_LIGHT, 30, 4, 28))
	center.add_child(card)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	card.add_child(box)
	var title: Label = _label("遊び方", 48, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	tutorial_body = _label("", 38, Color.WHITE)
	tutorial_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.custom_minimum_size.y = 180
	box.add_child(tutorial_body)
	tutorial_page_label = _label("1 / 3", 26, Color("#cdbfd7"))
	tutorial_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tutorial_page_label)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	box.add_child(actions)
	var skip := _button("スキップ")
	skip.name = "TutorialSkipButton"
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip.pressed.connect(_close_tutorial)
	actions.add_child(skip)
	tutorial_next_button = _button("次へ", true)
	tutorial_next_button.name = "TutorialNextButton"
	tutorial_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_next_button.pressed.connect(_advance_tutorial)
	actions.add_child(tutorial_next_button)
	return overlay

func _build_result_overlay() -> Control:
	var overlay: Control = Control.new()
	overlay.name = "ResultOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 45
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.name = "ResultDim"
	dim.color = Color(0.0, 0.0, 0.0, RESULT_DIM_ALPHA)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	result_card = PanelContainer.new()
	var card: PanelContainer = result_card
	card.name = "ResultPanel"
	card.custom_minimum_size = Vector2(632, 720)
	card.add_theme_stylebox_override("panel", _panel(Color("#190908f8"), GOLD_LIGHT, 34, 5, 28))
	center.add_child(card)
	var body: VBoxContainer = VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 18)
	card.add_child(body)
	result_title_label = _label("残念… BUST!", 58, Color("#ffcf70"))
	result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(result_title_label)
	result_dice_label = _label("[1]    BUST", 46, Color("#ff765e"))
	result_dice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(result_dice_label)
	result_floor_label = _label("FLOOR 0", 34, Color("#fff2d4"))
	result_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(result_floor_label)
	var reward_panel: PanelContainer = PanelContainer.new()
	reward_panel.custom_minimum_size.y = 170
	reward_panel.add_theme_stylebox_override("panel", _panel(Color("#062523f2"), Color("#b87b28"), 24, 3, 18))
	body.add_child(reward_panel)
	result_reward_label = _label("獲得予定\n0 CHIP  →  0 CHIP", 42, Color("#fff2d4"))
	result_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_panel.add_child(result_reward_label)
	result_bet_label = _label("BET結果  -20 CHIP", 32, Color("#ff765e"))
	result_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(result_bet_label)
	var retry: Button = _button("もう一度遊ぶ\nBET 20 CHIP", true)
	retry.name = "RetryButton"
	retry.custom_minimum_size.y = 150
	retry.add_theme_font_size_override("font_size", 42)
	retry.pressed.connect(_play_again_same_bet)
	body.add_child(retry)
	var secondary: HBoxContainer = HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 16)
	body.add_child(secondary)
	var change_bet: Button = _button("ベットを変える")
	change_bet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change_bet.custom_minimum_size.y = 92
	change_bet.pressed.connect(_restart_after_result)
	secondary.add_child(change_bet)
	var exit: Button = _button("カジノへ戻る")
	exit.name = "ResultCasinoBackButton"
	exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit.custom_minimum_size.y = 92
	exit.pressed.connect(_on_back_pressed)
	CasinoBackButton.configure(exit)
	secondary.add_child(exit)
	return overlay

func _open_tutorial() -> void:
	tutorial_overlay.visible = true
	_show_tutorial_page(0)

func _build_stat_panel(caption: String) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6d995"), Color("#a96b2e"), 24, 3, 14))
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var cap: Label = _label(caption, 26, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value: Label = _label("-", 46, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _stat_box(caption: String) -> Dictionary:
	return _build_stat_panel(caption)

func _amount_button(amount: int) -> Button:
	var button: Button = _button("%d\nCHIP" % amount)
	button.custom_minimum_size = Vector2(208, 164)
	button.add_theme_font_size_override("font_size", 38)
	return button

func _show_tutorial_page(page: int) -> void:
	tutorial_page = clampi(page, 0, 2)
	match tutorial_page:
		0:
			tutorial_body.text = "2から5で\n1階UP！"
		1:
			tutorial_body.text = "6なら\n2階UP！"
		2:
			tutorial_body.text = "1が出たら\n全部BUST！"
	tutorial_page_label.text = "%d / 3" % (tutorial_page + 1)
	tutorial_next_button.text = "ゲームへ" if tutorial_page == 2 else "次へ"

func _advance_tutorial() -> void:
	if tutorial_page >= 2:
		_close_tutorial()
		return
	_play_ui_sfx(&"select", false)
	_show_tutorial_page(tutorial_page + 1)

func _close_tutorial() -> void:
	tutorial_overlay.visible = false
	_play_ui_sfx(&"back", false)
	_refresh_bet_buttons()

func _select_bet(amount: int) -> void:
	selected_bet = amount
	_play_ui_sfx(&"select", false)
	_refresh_bet_buttons()

func _refresh_bet_buttons() -> void:
	var chips: int = CasinoBankScript.balance()
	for amount: int in bet_buttons:
		var button: Button = bet_buttons[amount] as Button
		button.disabled = chips < amount
		button.text = ("◆\n" if amount == selected_bet else "") + "%d\nCHIP" % amount
		_apply_button_state(button, amount == selected_bet)
	start_button.disabled = chips < selected_bet
	if balance_preview_label != null:
		balance_preview_label.text = "BET後の所持チップ    %s  →  %s" % [_format_chips(chips), _format_chips(maxi(0, chips - selected_bet))]
	start_button.text = "ゲーム開始\nBET %d CHIP" % selected_bet
	if start_button.disabled:
		status_label.text = "CHIPが足りない。通常ステージでCOINを持ち帰ろう。"
	else:
		status_label.text = "%d CHIPで塔に挑む？" % selected_bet

func _resume_or_show_setup() -> void:
	var active: Dictionary = CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		_show_setup()
		return
	game_id = str(active.get("game_id", ""))
	var session: Dictionary = active.get("session", {}) as Dictionary
	game = _normalise_game(session, int(active.get("bet", selected_bet)))
	selected_bet = int(game.get("bet", active.get("bet", selected_bet)))
	pending_roll = _extract_pending_roll(game)
	if pending_roll.is_empty():
		pending_roll = _extract_pending_roll(active)
	settled = false
	rolling = not pending_roll.is_empty()
	setup_view.visible = false
	active_view.visible = true
	_set_result_overlay_visible(false)
	_set_retry_action(false)
	_reset_tower_visuals()
	_refresh_all()
	if bool(game.get("finished", false)):
		call_deferred("_after_roll_resolution")
	elif not pending_roll.is_empty():
		call_deferred("_resume_pending_roll")

func _normalise_game(source: Dictionary, fallback_bet: int) -> Dictionary:
	var candidate: Dictionary = source.duplicate(true)
	if candidate.has("game") and candidate["game"] is Dictionary:
		candidate = (candidate["game"] as Dictionary).duplicate(true)
	var bet_amount: int = maxi(0, int(candidate.get("bet", candidate.get("stake", fallback_bet))))
	var fresh: Dictionary = TowerScript.new_game(bet_amount)
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
	await _animate_and_resolve_pending_roll(pending_roll)

func _start_game() -> void:
	if rolling or CasinoBankScript.balance() < selected_bet:
		return
	var initial_game: Dictionary = TowerScript.new_game(selected_bet)
	initial_game["pending_rolls"] = []
	var receipt: Dictionary = CasinoBankScript.begin_game(FACILITY_ID, selected_bet, initial_game)
	if not bool(receipt.get("ok", false)):
		if bool(receipt.get("already_active", false)):
			_resume_or_show_setup()
			return
		_play_ui_sfx(&"blocked", false)
		_refresh_bet_buttons()
		return
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	queued_roll_value = 0
	game = initial_game
	game_id = str(receipt.get("game_id", ""))
	pending_roll = {}
	settled = false
	rolling = false
	_set_result_overlay_visible(false)
	_set_retry_action(false)
	setup_view.visible = false
	active_view.visible = true
	cashout_button.disabled = true
	roll_button.disabled = false
	_reset_tower_visuals()
	_play_ui_sfx(&"start", false)
	_show_banner("BET %d CHIP" % selected_bet, GOLD_LIGHT, Color("#3f2408"), 0.55, "BetBanner")
	_refresh_all()

func _on_roll_pressed() -> void:
	if rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var rolled: int = queued_roll_value if queued_roll_value in range(1, 7) else rng.randi_range(1, 6)
	queued_roll_value = 0
	pending_roll = {
		"kind": "roll",
		"value": rolled,
		"from_floor": int(game.get("floor", 0)),
		"roll_index": int(game.get("roll_count", 0)) + 1,
	}
	game["pending_rolls"] = [pending_roll.duplicate(true)]
	var receipt: Dictionary = CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	if not bool(receipt.get("ok", false)):
		status_label.text = "保存できませんでした。もう一度サイコロを振ってください。"
		return
	rolling = true
	cashout_button.disabled = true
	roll_button.disabled = true
	await _animate_and_resolve_pending_roll(pending_roll)

func _animate_and_resolve_pending_roll(pending: Dictionary) -> void:
	var rolled: int = clampi(int(pending.get("value", 1)), 1, 6)
	status_label.text = "サイコロが回る..."
	dice_presentation.present([rolled], true, 1)
	await get_tree().create_timer(ROLL_SECONDS).timeout
	if not is_inside_tree():
		return
	game = TowerScript.apply_roll(game, rolled)
	game["pending_rolls"] = []
	pending_roll = {}
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	dice_presentation.present([rolled], false, 1)
	await get_tree().create_timer(RESULT_SECONDS).timeout
	if not is_inside_tree():
		return
	rolling = false
	_after_roll_resolution()

func _after_roll_resolution() -> void:
	var kind: String = str(game.get("last_kind", ""))
	if bool(game.get("completed", false)):
		_play_ui_sfx(&"complete", true)
		_show_banner("TOWER COMPLETE!", GOLD_LIGHT, Color("#3f2408"), 0.85, "CompleteBanner")
		_finish_success(int(game.get("payout", 0)), "10F到達！ %d CHIP獲得！" % int(game.get("payout", 0)))
		_refresh_all()
		return
	if bool(game.get("busted", false)):
		_play_ui_sfx(&"error", true)
		status_label.text = "BUST！ 獲得予定CHIPは0。"
		_show_banner("BUST  0 CHIP", Color("#ffd9d4"), Color("#5b1210"), 0.85, "BustBanner")
		_play_bust_fx()
		_settle_finished_game(0)
		_refresh_all()
		_show_bust_result()
		return
	if kind == "leap":
		_play_ui_sfx(&"bonus", true)
		_show_banner("GOLDEN LEAP!", GOLD_LIGHT, Color("#3f2408"), 0.48, "LeapBanner")
		status_label.text = "GOLDEN LEAP！ %dFへ。" % int(game.get("floor", 0))
	else:
		_play_ui_sfx(&"progress-step", true)
		status_label.text = "CLIMB！ %dFへ。" % int(game.get("floor", 0))
	cashout_button.disabled = false
	roll_button.disabled = false
	_refresh_all()

func _on_cashout_pressed() -> void:
	if rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var payout: int = TowerScript.cashout_payout(game)
	if payout <= 0:
		_play_ui_sfx(&"blocked", false)
		return
	game = TowerScript.take_cashout(game)
	_play_ui_sfx(&"complete", true)
	_finish_success(payout, "受け取り完了！ +%d CHIP" % payout)

func _finish_success(payout: int, message: String) -> void:
	if not _settle_finished_game(payout):
		status_label.text = "精算を保存できませんでした。"
		return
	status_label.text = message
	_spawn_confetti()
	_refresh_all()
	_show_success_result(payout)

func _settle_finished_game(payout: int) -> bool:
	if settled:
		_set_result_finished()
		return true
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	var receipt: Dictionary = CasinoBankScript.settle_game(FACILITY_ID, maxi(0, payout), {
		"floor": int(game.get("floor", 0)),
		"highest_floor": int(game.get("highest_floor", 0)),
		"busted": bool(game.get("busted", false)),
		"completed": bool(game.get("completed", false)),
		"cashed_out": bool(game.get("cashed_out", false)),
		"payout": maxi(0, payout),
	}, game_id)
	settled = bool(receipt.get("ok", false)) or bool(receipt.get("already_settled", false))
	if settled:
		_set_result_finished()
	return settled

func _set_result_finished() -> void:
	cashout_button.disabled = true
	roll_button.disabled = false
	roll_button.text = "ベットを変える"
	_apply_roll_style(true)
	_set_retry_action(true)

func _set_retry_action(enabled: bool) -> void:
	if roll_button == null:
		return
	if roll_button.pressed.is_connected(_on_roll_pressed):
		roll_button.pressed.disconnect(_on_roll_pressed)
	if roll_button.pressed.is_connected(_restart_after_result):
		roll_button.pressed.disconnect(_restart_after_result)
	if enabled:
		roll_button.pressed.connect(_restart_after_result, CONNECT_ONE_SHOT)
	else:
		roll_button.pressed.connect(_on_roll_pressed)

func _restart_after_result() -> void:
	_set_result_overlay_visible(false)
	_play_ui_sfx(&"retry", false)
	_show_setup()

func _play_again_same_bet() -> void:
	_set_result_overlay_visible(false)
	_play_ui_sfx(&"retry", false)
	_show_setup()
	if CasinoBankScript.balance() < selected_bet:
		status_label.text = "CHIPが足りない。BETを変更してください。"
		return
	_start_game()

func _show_setup() -> void:
	game = {}
	game_id = ""
	pending_roll = {}
	settled = false
	rolling = false
	queued_roll_value = 0
	active_view.visible = false
	setup_view.visible = true
	_set_result_overlay_visible(false)
	roll_button.text = "サイコロを振る\nもう1回振る"
	_apply_roll_style(false)
	_set_retry_action(false)
	_reset_tower_visuals()
	_refresh_all()

func _reset_tower_visuals() -> void:
	tower_frame.modulate = Color.WHITE
	tower_frame.offset_transform_enabled = false
	tower_frame.offset_transform_position = Vector2.ZERO
	dice_presentation.present([1], false, 1)

func _refresh_all() -> void:
	chip_label.text = "CASINO CHIP\n%s" % _format_chips(CasinoBankScript.balance())
	if game.is_empty():
		_refresh_bet_buttons()
		return
	var floor_number: int = int(game.get("floor", 0))
	var payout: int = int(game.get("payout", 0))
	var planned_payout: int = payout if bool(game.get("finished", false)) else TowerScript.cashout_payout(game)
	floor_label.text = "%d / 10" % floor_number
	payout_label.text = "%d CHIP" % planned_payout
	risk_label.text = "%d CHIP" % planned_payout
	cashout_button.text = "ここで受け取る\n%d CHIP" % planned_payout
	cashout_button.disabled = not bool(game.get("active", false)) or floor_number < 1 or rolling
	var last_roll: int = int(game.get("last_roll", 0))
	if last_roll_label != null:
		last_roll_label.text = "前回：%s%s" % ["—" if last_roll <= 0 else str(last_roll), "    GOLDEN LEAP!" if str(game.get("last_kind", "")) == "leap" else ""]
	_refresh_tower(floor_number)

func _show_bust_result() -> void:
	var reached_floor: int = int(game.get("highest_floor", game.get("floor_before_bust", 0)))
	if reached_floor <= 0:
		reached_floor = int(game.get("previous_floor", 0))
	var lost_reward: int = int(game.get("lost_payout", 0))
	if lost_reward <= 0:
		lost_reward = TowerScript.payout_for_floor(selected_bet, maxi(1, reached_floor)) if reached_floor > 0 else 0
	result_title_label.text = "残念… BUST!"
	result_dice_label.text = "[1]    BUST"
	result_floor_label.text = "FLOOR %dまで登ったのに…" % reached_floor
	result_reward_label.text = "受け取り 0 CHIP（BET込み）\n獲得予定 %d CHIPを失った" % lost_reward
	result_bet_label.text = "収支  -%d CHIP" % selected_bet
	var retry: Button = result_overlay.find_child("RetryButton", true, false) as Button
	if retry != null:
		retry.text = "もう一度遊ぶ\nBET %d CHIP" % selected_bet
	_set_result_overlay_visible(true)
	call_deferred("_animate_result_reveal")

func _show_success_result(payout: int) -> void:
	var floor_number: int = int(game.get("floor", 0))
	var completed: bool = bool(game.get("completed", false))
	result_title_label.text = "タワー制覇！" if completed else "受け取り完了！"
	result_dice_label.text = "[10]  ゴール" if completed else "安全に受け取り"
	result_floor_label.text = "FLOOR %dで配当確定" % floor_number
	result_reward_label.text = "受け取り\n%d CHIP（BET込み）" % payout
	result_bet_label.text = "収支  %+d CHIP" % (payout - selected_bet)
	var retry: Button = result_overlay.find_child("RetryButton", true, false) as Button
	if retry != null:
		retry.text = "もう一度遊ぶ\nBET %d CHIP" % selected_bet
	_set_result_overlay_visible(true)
	call_deferred("_animate_result_reveal")

func _animate_result_reveal() -> void:
	if result_card == null or not result_card.visible or not result_overlay.visible:
		return
	VisualFeedback.reveal(result_card, 0.28)

func _set_result_overlay_visible(is_visible: bool) -> void:
	result_overlay.visible = is_visible
	if back_button != null:
		back_button.visible = not is_visible

func _format_chips(value: int) -> String:
	var raw: String = str(maxi(0, value))
	var result: String = ""
	while raw.length() > 3:
		result = "," + raw.right(3) + result
		raw = raw.left(raw.length() - 3)
	return raw + result

func _refresh_tower(current_floor: int) -> void:
	for floor_number: int in floor_panels:
		var entry: Dictionary = floor_panels[floor_number]
		var panel := entry.panel as PanelContainer
		var label := entry.label as Label
		var visited := floor_number <= current_floor
		var current := floor_number == current_floor
		label.text = ("%dF  x%.2f\nPLAYER" % [floor_number, TowerScript.multiplier_for_floor(floor_number)]) if current else ("%dF  x%.2f" % [floor_number, TowerScript.multiplier_for_floor(floor_number)])
		var border := Color.TRANSPARENT
		if current:
			border = GOLD_LIGHT
		elif bool(game.get("busted", false)):
			border = RED
		panel.add_theme_stylebox_override("panel", _panel(
			GOLD if current else (Color("#4b3559") if visited else Color("#2b2338")),
			border,
			5,
			2 if current or bool(game.get("busted", false)) else 0))
		label.add_theme_color_override("font_color", INK if current else (Color("#fff0cf") if visited else Color("#cfc4dc")))

func _show_banner(text: String, color: Color, outline_color: Color, hold_seconds: float, node_name: String) -> void:
	if effect_layer == null:
		return
	var banner := _label(text, 30, color)
	banner.name = node_name
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_outline_color", outline_color)
	banner.add_theme_constant_override("outline_size", 7)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(banner)
	banner.size = Vector2(minf(320.0, effect_layer.size.x - 20.0), 56)
	banner.position = Vector2(
		(effect_layer.size.x - banner.size.x) * 0.5,
		maxf(104.0, effect_layer.size.y * 0.22))
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.78, 0.78)
	banner.modulate.a = 0.0
	var intro := create_tween().set_parallel(true)
	intro.tween_property(banner, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(banner, "modulate:a", 1.0, 0.09)
	intro.chain().tween_interval(hold_seconds)
	intro.chain().tween_property(banner, "modulate:a", 0.0, 0.16)
	intro.chain().tween_callback(banner.queue_free)

func _spawn_confetti() -> void:
	if effect_layer == null:
		return
	for index: int in 24:
		var piece := ColorRect.new()
		piece.name = "ConfettiPiece"
		piece.size = Vector2(randf_range(4.0, 7.0), randf_range(7.0, 13.0))
		piece.color = [GOLD, GOLD_LIGHT, Color("#fff7df"), Color("#ffb46b")][index % 4]
		piece.rotation = randf_range(-PI, PI)
		piece.position = Vector2(randf_range(0.0, maxf(1.0, effect_layer.size.x)), -18.0)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(piece)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(piece, "position:y", effect_layer.size.y + 24.0, randf_range(1.0, 1.55))
		fall.tween_property(piece, "rotation", piece.rotation + randf_range(-3.0, 3.0), 1.2)
		fall.tween_property(piece, "modulate:a", 0.0, 0.32).set_delay(0.9)
		fall.chain().tween_callback(piece.queue_free)

func _play_bust_fx() -> void:
	if tower_frame == null or effect_layer == null:
		return
	tower_frame.modulate = Color(1.55, 0.68, 0.68)
	var collapse := create_tween()
	collapse.tween_interval(0.05)
	collapse.tween_property(tower_frame, "modulate", Color(0.52, 0.24, 0.24, 0.42), 0.42)
	for index: int in 14:
		var shard := ColorRect.new()
		shard.name = "BustShard"
		shard.size = Vector2(randf_range(5.0, 11.0), randf_range(4.0, 8.0))
		shard.color = [GOLD, Color("#8d7f9c"), RED][index % 3]
		shard.position = Vector2(randf_range(24.0, maxf(28.0, effect_layer.size.x - 28.0)), randf_range(180.0, maxf(184.0, effect_layer.size.y * 0.66)))
		shard.rotation = randf_range(-PI, PI)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(shard)
		var drop := create_tween().set_parallel(true)
		drop.tween_property(shard, "position:y", effect_layer.size.y + 30.0, randf_range(0.65, 1.0))
		drop.tween_property(shard, "rotation", shard.rotation + randf_range(-4.0, 4.0), 0.85)
		drop.chain().tween_callback(shard.queue_free)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)

func _apply_button_state(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_stylebox_override("normal", _panel(Color("#f7df9a"), GOLD, 12, 3))
		button.add_theme_color_override("font_color", INK)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#403452"), Color("#705e84"), 12, 2))
		button.add_theme_color_override("font_color", Color("#fff4dc"))

func _apply_roll_style(danger: bool) -> void:
	var fill := RED if danger else GOLD
	var border := Color("#ff9b7e") if danger else Color("#a67836")
	roll_button.add_theme_stylebox_override("normal", _panel(fill, border, 12, 3))
	roll_button.add_theme_stylebox_override("hover", _panel(fill.lightened(0.08), GOLD_LIGHT, 12, 3))

func _on_back_pressed() -> void:
	if not game.is_empty() and bool(game.get("active", false)):
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	_play_ui_sfx(&"back", false)
	back_requested.emit()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.custom_minimum_size = Vector2(88, 44)
	button.add_theme_color_override("font_color", INK if primary else Color("#fff4dc"))
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#d8d0bf"))
	button.add_theme_stylebox_override("normal", _panel(GOLD if primary else Color("#403452"), Color("#a67836") if primary else Color("#705e84"), 12, 2))
	button.add_theme_stylebox_override("hover", _panel(GOLD_LIGHT if primary else Color("#51436a"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel(Color("#d99d2c") if primary else Color("#302641"), GOLD, 12, 2))
	button.add_theme_stylebox_override("disabled", _panel(Color("#514c45"), Color("#766d5f"), 12, 1))
	var focus: StyleBoxFlat = _panel(Color.TRANSPARENT, GOLD_LIGHT, 14, 4)
	focus.draw_center = false
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	button.add_theme_stylebox_override("focus", focus)
	VisualFeedback.bind_button(button)
	return button

func _panel(fill: Color, border: Color, radius: int, width: int, padding: int = 7) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style
