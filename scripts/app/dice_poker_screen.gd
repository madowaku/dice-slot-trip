class_name DicePokerScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const CasinoBackButton = preload("res://scripts/ui/casino_back_button.gd")
const DicePokerScript = preload("res://scripts/game/dice_poker_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const DISPLAY_FONT: Font = preload("res://assets/fonts/cinzel/Cinzel-Variable.ttf")
const CASINO_BACKGROUND: Texture2D = preload("res://assets/casino/dice_roulette/ui/casino-table-bg-v1.png")
const DICE_ICON: Texture2D = preload("res://assets/art/ui/common/dice-ivory-brass.png")
const BUTTON_ORNAMENTS: Texture2D = preload("res://assets/art/ui/common/roll-button-ornaments.png")
const SELECTION_SPARKLE: Texture2D = preload("res://assets/art/ui/common/slot-snap-sparkle.png")
const CHIP_TEXTURES: Dictionary = {
	10: preload("res://assets/casino/vault_break/ui/chip-10-black-v1.png"),
	20: preload("res://assets/casino/vault_break/ui/chip-20-red-v1.png"),
	50: preload("res://assets/casino/vault_break/ui/chip-50-gold-v1.png"),
}

const FACILITY_ID: String = "dice_poker"
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const ROLL_SECONDS: float = 0.28
const SETTLE_SECONDS: float = 0.12

const GOLD: Color = Color("#e7b84b")
const GOLD_LIGHT: Color = Color("#ffe7a3")
const BRIGHT_GOLD: Color = Color("#ffd75b")
const INK: Color = Color("#28170a")
const CREAM: Color = Color("#fff1d1")
const NAVY: Color = Color("#071322")
const DEEP_GREEN: Color = Color("#041c16")
const FELT: Color = Color("#0a3a2a")
const PLUM: Color = Color("#2c173e")
const OXBLOOD: Color = Color("#7a181f")
const BRASS: Color = Color("#9b6b2f")
const MUTED: Color = Color("#c5b996")
const PAYTABLE: Array[Dictionary] = [
	{"symbol": "◆◆", "name": "ONE PAIR", "multiplier": 0.2},
	{"symbol": "◆◆  ◆◆", "name": "TWO PAIR", "multiplier": 0.4},
	{"symbol": "◆◆◆", "name": "THREE", "multiplier": 0.6},
	{"symbol": "1·2·3·4·5", "name": "STRAIGHT", "multiplier": 0.8},
	{"symbol": "◆◆◆  ◆◆", "name": "FULL HOUSE", "multiplier": 1.0},
	{"symbol": "◆◆◆◆", "name": "FOUR", "multiplier": 1.7},
	{"symbol": "◆◆◆◆◆", "name": "FIVE", "multiplier": 2.8},
]
const PIP_PATTERNS: Array = [
	[],
	[4],
	[0, 8],
	[0, 4, 8],
	[0, 2, 6, 8],
	[0, 2, 4, 6, 8],
	[0, 2, 3, 5, 6, 8],
]

## Isolated deterministic test harnesses set this before instantiation.  The
## runtime leaves it false so Las Vegas BGM/SFX continue to work.
static var suppress_audio_for_tests: bool = false

var game: Dictionary = {}
var game_id: String = ""
var selected_bet: int = 20
var rolling: bool = false
var settled: bool = false
var rng_seed: int = 0
## A batch is either a flat face queue, an Array of batches, or dictionaries
## containing `values`/`full_values`.  These hooks make tests deterministic
## without changing the pure model.
var queued_roll_batch: Array = []
var queued_roll_values: Array = []
var queued_reroll_values: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var pending_roll: Dictionary = {}
var view_state: String = "setup"

var chip_label: Label
var status_label: Label
var bet_label: Label
var rerolls_label: Label
var rank_label: Label
var hand_label: Label
var result_label: Label
var result_payout_label: Label
var result_net_label: Label
var result_detail_label: Label
var result_bet_value: Label
var result_return_value: Label
var deal_button: Button
var start_button: Button
var reroll_button: Button
var lock_button: Button
var action_button: Button
var again_button: Button
var change_bet_button: Button
var exit_button: Button
var back_button: Button
var setup_view: VBoxContainer
var active_view: VBoxContainer
var result_view: VBoxContainer
var keep_buttons: Dictionary = {}
var dice_buttons: Dictionary = {}
var bet_buttons: Dictionary = {}
var dice_presentation: DicePresentation3D
var result_dice_presentation: DicePresentation3D
var active_die_faces: Dictionary = {}
var result_die_faces: Dictionary = {}
var effect_layer: Control
var help_overlay: Control
var result_card: PanelContainer
var result_sparkle: TextureRect
var button_tweens: Dictionary = {}
var result_intro_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not suppress_audio_for_tests:
		var bgm: Node = get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_dice_poker")
		var ui_sfx: Node = get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	_build_ui()
	_resume_or_show_setup()

func _build_ui() -> void:
	var background: TextureRect = TextureRect.new()
	background.name = "CasinoTableBackdrop"
	background.texture = CASINO_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var veil: ColorRect = ColorRect.new()
	veil.name = "EmeraldVeil"
	veil.color = Color(0.005, 0.035, 0.027, 0.52)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var crown_glow: ColorRect = ColorRect.new()
	crown_glow.name = "CrownGlow"
	crown_glow.color = Color(0.035, 0.025, 0.13, 0.46)
	crown_glow.anchor_right = 1.0
	crown_glow.anchor_bottom = 0.24
	crown_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crown_glow)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "PokerScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)

	var margins: MarginContainer = MarginContainer.new()
	margins.name = "SafeMargins"
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_bottom", 22)
	scroll.add_child(margins)

	var root: VBoxContainer = VBoxContainer.new()
	root.name = "DicePokerRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 9)
	margins.add_child(root)
	_build_header(root)
	_build_status(root)

	setup_view = VBoxContainer.new()
	setup_view.name = "DicePokerSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 9)
	root.add_child(setup_view)
	_build_setup(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "DicePokerActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 8)
	root.add_child(active_view)
	_build_active(active_view)

	result_view = VBoxContainer.new()
	result_view.name = "DicePokerResultView"
	result_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_view.add_theme_constant_override("separation", 9)
	root.add_child(result_view)
	_build_result(result_view)

	effect_layer = Control.new()
	effect_layer.name = "DicePokerEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 30
	add_child(effect_layer)
	_build_help_overlay()

func _build_header(root: VBoxContainer) -> void:
	var header: PanelContainer = PanelContainer.new()
	header.name = "DicePokerHeader"
	header.add_theme_stylebox_override("panel", _ornate_panel(Color("#07152ae8"), GOLD, 24, 3, Color("#f7c64d44")))
	root.add_child(header)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	header.add_child(stack)
	var nav: HBoxContainer = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	stack.add_child(nav)
	back_button = _button("カジノへ戻る", false)
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size = Vector2(168, 96)
	_apply_utility_button_style(back_button)
	CasinoBackButton.configure(back_button)
	back_button.pressed.connect(_on_back_pressed)
	nav.add_child(back_button)
	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 0)
	nav.add_child(title_stack)
	var title: Label = _display_label("DICE POKER", 46, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#3a1700"))
	title.add_theme_constant_override("outline_size", 7)
	title_stack.add_child(title)
	var subtitle: Label = _label("FIVE DICE  ·  TWO REROLLS", 14, BRIGHT_GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	subtitle.add_theme_constant_override("outline_size", 3)
	title_stack.add_child(subtitle)
	var help_holder: CenterContainer = CenterContainer.new()
	help_holder.custom_minimum_size.x = 126
	nav.add_child(help_holder)
	var help_button: Button = _button("?", false)
	help_button.name = "HelpButton"
	help_button.custom_minimum_size = Vector2(96, 96)
	help_button.add_theme_font_override("font", DISPLAY_FONT)
	help_button.add_theme_font_size_override("font_size", 34)
	_apply_round_button_style(help_button)
	help_button.tooltip_text = "遊び方と配当表"
	help_button.pressed.connect(_toggle_help)
	help_holder.add_child(help_button)

	var chip_panel: PanelContainer = PanelContainer.new()
	chip_panel.name = "ChipBalancePanel"
	chip_panel.custom_minimum_size.y = 92
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#061b18eb"), GOLD, 20, 2, 16))
	stack.add_child(chip_panel)
	var chip_row: HBoxContainer = HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 12)
	chip_panel.add_child(chip_row)
	var chip_icon: TextureRect = TextureRect.new()
	chip_icon.texture = DICE_ICON
	chip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip_icon.custom_minimum_size = Vector2(72, 72)
	chip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_child(chip_icon)
	var balance_copy: VBoxContainer = VBoxContainer.new()
	balance_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	balance_copy.add_theme_constant_override("separation", -3)
	chip_row.add_child(balance_copy)
	var balance_caption: Label = _label("CASINO CHIP", 16, GOLD_LIGHT)
	balance_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_copy.add_child(balance_caption)
	chip_label = _display_label("0", 36, CREAM)
	chip_label.name = "ChipBalanceLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	chip_label.add_theme_constant_override("outline_size", 4)
	balance_copy.add_child(chip_label)
	var live_badge: Label = _label("ROYAL BANK", 13, MUTED)
	live_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	live_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	live_badge.custom_minimum_size = Vector2(112, 44)
	live_badge.add_theme_stylebox_override("normal", _panel(Color("#29123ddd"), Color("#8c63a7"), 18, 1, 8))
	chip_row.add_child(live_badge)

func _build_status(root: VBoxContainer) -> void:
	status_label = _label("BETを選んで、5つのダイスをDEAL", 19, Color.WHITE)
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 52
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.add_theme_stylebox_override("normal", _panel(Color("#073326e8"), Color("#c79735"), 18, 2, 10))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(status_label)

func _build_setup(root: VBoxContainer) -> void:
	var caption: Label = _display_label("1  ·  SELECT YOUR BET", 24, GOLD_LIGHT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(caption)
	var bet_row: HBoxContainer = HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bet_row.add_theme_constant_override("separation", 10)
	root.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button: Button = _create_bet_button(amount)
		button.name = "Bet_%d" % amount
		button.custom_minimum_size = Vector2(0, 174)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	_build_paytable(root, false, "PAY TABLE")

	deal_button = _button("DEAL HAND", true)
	deal_button.name = "DealButton"
	deal_button.custom_minimum_size.y = 128
	deal_button.add_theme_font_override("font", DISPLAY_FONT)
	deal_button.add_theme_font_size_override("font_size", 36)
	deal_button.icon = DICE_ICON
	deal_button.expand_icon = true
	deal_button.add_theme_constant_override("icon_max_width", 76)
	_apply_primary_button_style(deal_button, PLUM, Color("#4b2168"))
	_add_button_ornament(deal_button, 3)
	deal_button.pressed.connect(_start_game)
	start_button = deal_button
	root.add_child(deal_button)

	var hint: Label = _label("5つのダイスで役を作ろう  ·  好きなダイスを残して2回まで振り直せます", 16, CREAM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.y = 48
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 3)
	root.add_child(hint)

func _build_active(root: VBoxContainer) -> void:
	var stats: HBoxContainer = HBoxContainer.new()
	stats.name = "DicePokerStats"
	stats.add_theme_constant_override("separation", 8)
	root.add_child(stats)
	var bet_stat: Dictionary = _stat_box("BET")
	bet_label = bet_stat["label"] as Label
	bet_label.name = "BetLabel"
	stats.add_child(bet_stat["panel"] as PanelContainer)
	var reroll_stat: Dictionary = _stat_box("REROLLS")
	rerolls_label = reroll_stat["label"] as Label
	rerolls_label.name = "RerollsLabel"
	stats.add_child(reroll_stat["panel"] as PanelContainer)
	var rank_stat: Dictionary = _stat_box("CURRENT HAND")
	rank_label = rank_stat["label"] as Label
	rank_label.name = "RankLabel"
	stats.add_child(rank_stat["panel"] as PanelContainer)
	hand_label = rank_label

	var dice_panel: PanelContainer = PanelContainer.new()
	dice_panel.name = "DicePresentationPanel"
	dice_panel.custom_minimum_size.y = 350
	dice_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_panel.add_theme_stylebox_override("panel", _ornate_panel(Color("#051b16f0"), GOLD, 24, 3, Color("#e9bb4a44")))
	root.add_child(dice_panel)
	var dice_box: VBoxContainer = VBoxContainer.new()
	dice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_box.add_theme_constant_override("separation", 4)
	dice_panel.add_child(dice_box)
	var dice_caption: Label = _display_label("FIVE DICE  ·  TAP A CARD TO KEEP", 18, GOLD_LIGHT)
	dice_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_box.add_child(dice_caption)
	var die_center: CenterContainer = CenterContainer.new()
	die_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_box.add_child(die_center)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "DicePokerPresentation3D"
	dice_presentation.overlay_compact = false
	dice_presentation.compact_single = false
	dice_presentation.tray_surface_visible = true
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(0, 170)
	die_center.add_child(dice_presentation)
	var active_faces: HBoxContainer = _create_die_face_row("ActiveDiceFaces", active_die_faces)
	dice_box.add_child(active_faces)

	var keep_grid: GridContainer = GridContainer.new()
	keep_grid.name = "KeepButtons"
	keep_grid.columns = DicePokerScript.DIE_COUNT
	keep_grid.add_theme_constant_override("h_separation", 7)
	keep_grid.add_theme_constant_override("v_separation", 7)
	root.add_child(keep_grid)
	for index: int in range(DicePokerScript.DIE_COUNT):
		var keep_button: Button = _button("DIE %d\nOPEN" % (index + 1))
		keep_button.name = "KeepDie_%d" % (index + 1)
		keep_button.custom_minimum_size = Vector2(0, 106)
		keep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		keep_button.add_theme_font_size_override("font_size", 16)
		keep_button.pressed.connect(_on_keep_pressed.bind(index))
		keep_buttons[index] = keep_button
		keep_grid.add_child(keep_button)
	dice_buttons = keep_buttons

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.add_theme_constant_override("separation", 9)
	root.add_child(action_row)
	reroll_button = _button("REROLL", true)
	reroll_button.name = "RerollButton"
	reroll_button.custom_minimum_size.y = 116
	reroll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll_button.add_theme_font_override("font", DISPLAY_FONT)
	reroll_button.add_theme_font_size_override("font_size", 28)
	_apply_primary_button_style(reroll_button, Color("#123f2d"), Color("#176344"))
	_add_button_ornament(reroll_button, 3)
	reroll_button.pressed.connect(_on_reroll_pressed)
	action_row.add_child(reroll_button)
	lock_button = _button("LOCK HAND", true)
	lock_button.name = "LockHandButton"
	lock_button.custom_minimum_size.y = 116
	lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_button.add_theme_font_override("font", DISPLAY_FONT)
	lock_button.add_theme_font_size_override("font_size", 28)
	_apply_primary_button_style(lock_button, PLUM, Color("#542271"))
	_add_button_ornament(lock_button, 3)
	lock_button.pressed.connect(_on_lock_pressed)
	action_row.add_child(lock_button)
	action_button = reroll_button

	var compact_paytable: PanelContainer = _build_paytable(root, true, "PAY TABLE")
	compact_paytable.name = "CompactPaytable"

func _build_result(root: VBoxContainer) -> void:
	var banner: PanelContainer = PanelContainer.new()
	banner.name = "ResultBanner"
	banner.custom_minimum_size.y = 78
	banner.add_theme_stylebox_override("panel", _ornate_panel(Color("#72161df5"), GOLD_LIGHT, 24, 3, Color("#ffc94f66")))
	root.add_child(banner)
	var banner_label: Label = _display_label("RESULT", 38, GOLD_LIGHT)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_color_override("font_outline_color", Color("#260500"))
	banner_label.add_theme_constant_override("outline_size", 6)
	banner.add_child(banner_label)

	result_card = PanelContainer.new()
	result_card.name = "ResultCard"
	result_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_card.custom_minimum_size.y = 430
	result_card.add_theme_stylebox_override("panel", _ornate_panel(Color("#04251cef"), GOLD, 24, 3, Color("#ffd55a55")))
	root.add_child(result_card)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	result_card.add_child(box)
	result_label = _display_label("RESULT", 52, GOLD_LIGHT)
	result_label.name = "ResultRankLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_color_override("font_outline_color", Color("#3b1800"))
	result_label.add_theme_constant_override("outline_size", 7)
	box.add_child(result_label)
	var dice_center: CenterContainer = CenterContainer.new()
	dice_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(dice_center)
	var result_dice_stack: VBoxContainer = VBoxContainer.new()
	result_dice_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	result_dice_stack.add_theme_constant_override("separation", -6)
	dice_center.add_child(result_dice_stack)
	result_dice_presentation = DicePresentationScript.new()
	result_dice_presentation.name = "ResultDicePresentation3D"
	result_dice_presentation.overlay_compact = false
	result_dice_presentation.compact_single = false
	result_dice_presentation.tray_surface_visible = false
	result_dice_presentation.high_contrast_pips = true
	result_dice_presentation.custom_minimum_size = Vector2.ZERO
	result_dice_presentation.visible = false
	result_dice_stack.add_child(result_dice_presentation)
	var result_faces: HBoxContainer = _create_die_face_row("ResultDiceFaces", result_die_faces)
	result_dice_stack.add_child(result_faces)
	var summary: HBoxContainer = HBoxContainer.new()
	summary.add_theme_constant_override("separation", 10)
	box.add_child(summary)
	var bet_summary: Dictionary = _result_stat_box("BET")
	result_bet_value = bet_summary["label"] as Label
	summary.add_child(bet_summary["panel"] as PanelContainer)
	var return_summary: Dictionary = _result_stat_box("RETURN")
	result_return_value = return_summary["label"] as Label
	# Preserve the public payout label contract while presenting net profit separately.
	result_payout_label = result_return_value
	result_payout_label.name = "ResultPayoutLabel"
	summary.add_child(return_summary["panel"] as PanelContainer)
	var divider: HSeparator = HSeparator.new()
	divider.add_theme_stylebox_override("separator", _separator_style(GOLD))
	box.add_child(divider)
	var net_caption: Label = _display_label("NET RESULT", 18, MUTED)
	net_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(net_caption)
	result_net_label = _display_label("±0 CHIP", 48, CREAM)
	result_net_label.name = "ResultNetLabel"
	result_net_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_net_label)
	result_detail_label = _label("", 17, CREAM)
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(result_detail_label)

	again_button = _button("PLAY AGAIN", true)
	again_button.name = "AgainButton"
	again_button.custom_minimum_size.y = 112
	again_button.add_theme_font_override("font", DISPLAY_FONT)
	again_button.add_theme_font_size_override("font_size", 34)
	again_button.icon = DICE_ICON
	again_button.expand_icon = true
	again_button.add_theme_constant_override("icon_max_width", 70)
	_apply_primary_button_style(again_button, Color("#0a4b32"), Color("#117148"))
	_add_button_ornament(again_button, 3)
	again_button.pressed.connect(_on_again_pressed)
	root.add_child(again_button)
	change_bet_button = _button("CHANGE BET", false)
	change_bet_button.name = "ChangeBetButton"
	change_bet_button.custom_minimum_size.y = 88
	change_bet_button.add_theme_font_override("font", DISPLAY_FONT)
	change_bet_button.add_theme_font_size_override("font_size", 22)
	_apply_secondary_button_style(change_bet_button, PLUM)
	change_bet_button.pressed.connect(_on_change_bet_pressed)
	root.add_child(change_bet_button)
	exit_button = _button("カジノへ戻る", false)
	exit_button.name = "ResultExitButton"
	exit_button.custom_minimum_size.y = 88
	exit_button.add_theme_font_override("font", DISPLAY_FONT)
	exit_button.add_theme_font_size_override("font_size", 21)
	_apply_utility_button_style(exit_button)
	CasinoBackButton.configure(exit_button)
	exit_button.pressed.connect(_on_back_pressed)
	root.add_child(exit_button)

	result_sparkle = TextureRect.new()
	result_sparkle.name = "ResultSparkle"
	result_sparkle.texture = SELECTION_SPARKLE
	result_sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_sparkle.custom_minimum_size = Vector2(620, 132)
	result_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_sparkle.modulate = Color(1, 1, 1, 0.0)
	dice_center.add_child(result_sparkle)

func _build_paytable(parent: Container, compact: bool, title_copy: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Paytable"
	panel.custom_minimum_size.y = 76 if compact else 340
	panel.add_theme_stylebox_override("panel", _ornate_panel(Color("#061b18ed"), Color("#b78332"), 20, 2, Color("#d8a74233")))
	parent.add_child(panel)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	panel.add_child(stack)
	var title: Label = _display_label(title_copy, 27 if not compact else 18, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	if compact:
		var compact_copy: Label = _label("FIVE ×2.8  ·  FOUR ×1.7  ·  FULL HOUSE ×1.0  ·  STRAIGHT ×0.8\nTHREE ×0.6  ·  TWO PAIR ×0.4  ·  ONE PAIR ×0.2", 14, CREAM)
		compact_copy.name = "PaytableLabel"
		compact_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		compact_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(compact_copy)
		return panel
	for row_index: int in range(PAYTABLE.size()):
		var entry: Dictionary = PAYTABLE[row_index]
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size.y = 36
		row.add_theme_constant_override("separation", 9)
		stack.add_child(row)
		var symbol: Label = _label(str(entry.get("symbol", "◆")), 13, GOLD)
		symbol.custom_minimum_size.x = 112
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(symbol)
		var hand_name: Label = _display_label(str(entry.get("name", "")), 18, CREAM)
		hand_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hand_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(hand_name)
		var multiplier: Label = _display_label("×%.1f" % float(entry.get("multiplier", 0.0)), 20, GOLD_LIGHT)
		multiplier.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		multiplier.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		multiplier.custom_minimum_size.x = 82
		row.add_child(multiplier)
		if row_index < PAYTABLE.size() - 1:
			var separator: HSeparator = HSeparator.new()
			separator.add_theme_stylebox_override("separator", _separator_style(Color("#9c7435")))
			stack.add_child(separator)
	return panel

func _create_bet_button(amount: int) -> Button:
	var button: Button = _button("", false)
	button.toggle_mode = true
	button.tooltip_text = "%d CHIPを賭ける" % amount
	button.set_meta("bet_amount", amount)
	var sparkle: TextureRect = TextureRect.new()
	sparkle.name = "SelectionSparkle"
	sparkle.texture = SELECTION_SPARKLE
	sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sparkle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sparkle.visible = false
	button.add_child(sparkle)
	var chip: TextureRect = TextureRect.new()
	chip.name = "ChipArt"
	var texture_value: Variant = CHIP_TEXTURES.get(amount, null)
	chip.texture = texture_value as Texture2D
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip.offset_left = 12.0
	chip.offset_top = 6.0
	chip.offset_right = -12.0
	chip.offset_bottom = -6.0
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(chip)
	var amount_label: Label = _display_label(str(amount), 34, GOLD_LIGHT)
	amount_label.name = "AmountLabel"
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amount_label.add_theme_color_override("font_outline_color", Color.BLACK)
	amount_label.add_theme_constant_override("outline_size", 6)
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(amount_label)
	var selected_badge: Label = _label("SELECTED", 12, INK)
	selected_badge.name = "SelectedBadge"
	selected_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_badge.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	selected_badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	selected_badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	selected_badge.offset_left = -52.0
	selected_badge.offset_top = -32.0
	selected_badge.offset_right = 52.0
	selected_badge.offset_bottom = -6.0
	selected_badge.add_theme_stylebox_override("normal", _panel(GOLD_LIGHT, GOLD, 14, 2, 5))
	selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_badge.visible = false
	button.add_child(selected_badge)
	return button

func _create_die_face_row(node_name: String, store: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = node_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 9)
	for index: int in range(DicePokerScript.DIE_COUNT):
		var panel: PanelContainer = PanelContainer.new()
		panel.name = "DieFace_%d" % (index + 1)
		panel.custom_minimum_size = Vector2(102, 102)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _die_face_style(false))
		row.add_child(panel)
		var grid_center: CenterContainer = CenterContainer.new()
		panel.add_child(grid_center)
		var grid: GridContainer = GridContainer.new()
		grid.columns = 3
		grid.custom_minimum_size = Vector2(70, 70)
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 0)
		grid_center.add_child(grid)
		var pips: Array[Label] = []
		for pip_index: int in range(9):
			var pip: Label = _label("●", 18, Color("#17100a"))
			pip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pip.custom_minimum_size = Vector2(20, 20)
			pip.modulate.a = 0.0
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(pip)
			pips.append(pip)
		var question: Label = _display_label("?", 34, BRASS)
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(question)
		store[index] = {"panel": panel, "pips": pips, "question": question}
	return row

func _update_die_face_set(store: Dictionary, faces: Array[int], kept: Array[bool]) -> void:
	for index: int in range(DicePokerScript.DIE_COUNT):
		var entry_value: Variant = store.get(index, {})
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value as Dictionary
		var panel: PanelContainer = entry.get("panel", null) as PanelContainer
		var question: Label = entry.get("question", null) as Label
		var pips_value: Variant = entry.get("pips", [])
		var pips: Array = pips_value as Array if pips_value is Array else []
		var face: int = faces[index] if index < faces.size() else 0
		var is_kept: bool = index < kept.size() and kept[index]
		if panel != null:
			panel.add_theme_stylebox_override("panel", _die_face_style(is_kept))
		if question != null:
			question.visible = face < 1 or face > 6
		var pattern: Array = PIP_PATTERNS[face] as Array if face >= 1 and face <= 6 else []
		for pip_index: int in range(pips.size()):
			var pip: Label = pips[pip_index] as Label
			if pip != null:
				pip.modulate = Color("#17100a") if pip_index in pattern else Color(0, 0, 0, 0)

func _die_face_style(kept: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel(Color("#fff0c7"), BRIGHT_GOLD if kept else Color("#a67836"), 20, 4 if kept else 2, 8)
	style.shadow_color = Color("#ffdb6377") if kept else Color("#00000066")
	style.shadow_size = 7 if kept else 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _result_stat_box(caption: String) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 78
	panel.add_theme_stylebox_override("panel", _panel(Color("#071a19e8"), Color("#8e6a35"), 16, 2, 10))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	panel.add_child(box)
	var cap: Label = _display_label(caption, 14, MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value: Label = _display_label("0", 26, GOLD_LIGHT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _build_help_overlay() -> void:
	help_overlay = Control.new()
	help_overlay.name = "HelpOverlay"
	help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_overlay.z_index = 50
	help_overlay.visible = false
	add_child(help_overlay)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	help_overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_overlay.add_child(center)
	var dialog: PanelContainer = PanelContainer.new()
	dialog.custom_minimum_size = Vector2(640, 0)
	dialog.add_theme_stylebox_override("panel", _ornate_panel(Color("#061b18fa"), GOLD_LIGHT, 26, 3, Color("#ffd65a55")))
	center.add_child(dialog)
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	dialog.add_child(body)
	var title: Label = _display_label("HOW TO PLAY", 38, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var copy: Label = _label("DEALで5個のダイスを振り、残したいダイスをKEEP。\n最大2回REROLLできます。5個すべてKEEPするとLOCK HANDで即確定。", 18, CREAM)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(copy)
	_build_paytable(body, false, "PAYOUTS")
	var close_button: Button = _button("CLOSE", true)
	close_button.name = "HelpCloseButton"
	close_button.custom_minimum_size.y = 90
	close_button.add_theme_font_override("font", DISPLAY_FONT)
	close_button.add_theme_font_size_override("font_size", 23)
	_apply_primary_button_style(close_button, PLUM, Color("#51206e"))
	close_button.pressed.connect(_toggle_help)
	body.add_child(close_button)

func _toggle_help() -> void:
	if help_overlay == null:
		return
	help_overlay.visible = not help_overlay.visible
	_play_ui_sfx(&"select" if help_overlay.visible else &"back", false)
	if help_overlay.visible:
		var close_button: Button = help_overlay.find_child("HelpCloseButton", true, false) as Button
		if close_button != null:
			close_button.grab_focus()
	elif back_button != null:
		back_button.grab_focus()

func _resume_or_show_setup() -> void:
	var active: Dictionary = CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		_show_setup()
		return
	game_id = str(active.get("game_id", ""))
	var session_value: Variant = active.get("session", {})
	var session: Dictionary = session_value as Dictionary if session_value is Dictionary else {}
	game = _normalise_game(session if not session.is_empty() else active)
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
	elif bool(game.get("finished", false)):
		_settle_finished_game()
	else:
		view_state = "active"
		rolling = false
		setup_view.visible = false
		active_view.visible = true
		result_view.visible = false
		_refresh_all()

func _normalise_game(source: Dictionary) -> Dictionary:
	var candidate: Dictionary = source.duplicate(true)
	var nested: Variant = candidate.get("game", null)
	if nested is Dictionary:
		candidate = (nested as Dictionary).duplicate(true)
	var bet: int = maxi(0, int(candidate.get("bet", selected_bet)))
	var fresh: Dictionary = DicePokerScript.new_game(bet)
	for key: Variant in candidate.keys():
		fresh[str(key)] = candidate[key]
	fresh["bet"] = bet
	fresh["stake"] = bet
	if not fresh.get("dice", []) is Array and fresh.get("values", []) is Array:
		fresh["dice"] = (fresh.get("values", []) as Array).duplicate(true)
	if not fresh.get("values", []) is Array and fresh.get("dice", []) is Array:
		fresh["values"] = (fresh.get("dice", []) as Array).duplicate(true)
	return fresh

func _extract_pending(source: Dictionary) -> Dictionary:
	var value: Variant = source.get("pending_rolls", [])
	if value is Array and not (value as Array).is_empty():
		var first: Variant = (value as Array)[0]
		if first is Dictionary:
			return (first as Dictionary).duplicate(true)
	return {}

func _resume_pending_roll() -> void:
	if pending_roll.is_empty() or not is_inside_tree():
		return
	var values: Array[int] = _pending_full_values(pending_roll)
	await _animate_roll(values, _pending_indices(pending_roll))
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _select_bet(amount: int) -> void:
	if amount not in BET_AMOUNTS or rolling:
		return
	selected_bet = amount
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
	var indices: Array[int] = [0, 1, 2, 3, 4]
	var initial: Array[int] = _next_roll_batch(indices)
	var initial_game: Dictionary = DicePokerScript.new_game(selected_bet)
	var pending: Dictionary = {
		"kind": "initial",
		"indices": indices.duplicate(),
		"values": initial.duplicate(),
		"full_values": initial.duplicate(),
		"dice": initial.duplicate(),
	}
	initial_game["pending_rolls"] = [pending.duplicate(true)]
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
	pending_roll = pending.duplicate(true)
	settled = false
	rolling = true
	view_state = "rolling"
	setup_view.visible = false
	active_view.visible = true
	result_view.visible = false
	status_label.text = "DEAL中..."
	_play_ui_sfx(&"start", false)
	_refresh_all()
	await _animate_roll(initial, indices)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _on_keep_pressed(die_index: int) -> void:
	if rolling or game.is_empty() or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	game = DicePokerScript.toggle_keep(game, die_index)
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	status_label.text = "KEEPを選択。%d個KEEP中。" % DicePokerScript.kept_count(game)
	_play_ui_sfx(&"select", false)
	_refresh_all()

func _on_reroll_pressed() -> void:
	if DicePokerScript.all_kept(game):
		_on_lock_pressed()
		return
	if rolling or not DicePokerScript.can_reroll(game):
		_play_ui_sfx(&"blocked", false)
		return
	var indices: Array[int] = DicePokerScript.reroll_indices(game)
	var values: Array[int] = _next_roll_batch(indices)
	var full_values: Array[int] = _state_dice(game)
	for offset: int in range(indices.size()):
		full_values[indices[offset]] = values[offset]
	pending_roll = {
		"kind": "reroll",
		"indices": indices.duplicate(),
		"values": values.duplicate(),
		"full_values": full_values.duplicate(),
		"dice": full_values.duplicate(),
		"kept": _state_kept(game).duplicate(),
		"rerolls_used_before": int(game.get("rerolls_used", 0)),
	}
	game["pending_rolls"] = [pending_roll.duplicate(true)]
	# Persist the complete index/value mapping before the animation starts.
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	rolling = true
	view_state = "rolling"
	status_label.text = "REROLL中..."
	_play_ui_sfx(&"roll", false)
	_refresh_all()
	await _animate_roll(full_values, indices)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _on_lock_pressed() -> void:
	if rolling or game.is_empty() or not DicePokerScript.can_lock_hand(game):
		_play_ui_sfx(&"blocked", false)
		return
	game = DicePokerScript.finalize(game)
	_settle_finished_game()

func _resolve_pending_roll(pending: Dictionary) -> void:
	if pending.is_empty() or game.is_empty():
		return
	var kind: String = str(pending.get("kind", "reroll"))
	var full_values: Array[int] = _pending_full_values(pending)
	if kind == "initial":
		game = DicePokerScript.apply_initial(game, full_values)
		game["pending_rolls"] = []
		pending_roll = {}
		rolling = false
		view_state = "active"
		status_label.text = "DICEをKEEPして、REROLLまたはLOCK HAND。"
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
		game.erase("pending_rolls")
		_refresh_all()
		return
	var indices: Array[int] = _pending_indices(pending)
	var values: Array[int] = _pending_values(pending)
	game = DicePokerScript.apply_reroll(game, values, indices)
	game["pending_rolls"] = []
	pending_roll = {}
	rolling = false
	if bool(game.get("finished", false)):
		game.erase("pending_rolls")
		_settle_finished_game()
		return
	view_state = "active"
	status_label.text = "REROLL完了。さらにKEEPするDICEを選ぶ。"
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	game.erase("pending_rolls")
	_refresh_all()

func _on_again_pressed() -> void:
	if rolling:
		return
	_show_setup(false)
	_start_game()

func _on_change_bet_pressed() -> void:
	if rolling:
		return
	_show_setup(true)

func _settle_finished_game() -> void:
	if settled:
		_show_result()
		return
	var payout_value: int = maxi(0, int(game.get("payout", 0)))
	var receipt: Dictionary = CasinoBankScript.settle_game(FACILITY_ID, payout_value, {
		"result": str(game.get("result", game.get("rank", DicePokerScript.RANK_NO_HAND))),
		"rank": str(game.get("rank", DicePokerScript.RANK_NO_HAND)),
		"dice": _state_dice(game),
		"bet": int(game.get("bet", selected_bet)),
	}, game_id)
	if bool(receipt.get("already_settled", false)):
		payout_value = int(receipt.get("payout", payout_value))
		game["payout"] = payout_value
	settled = bool(receipt.get("ok", false)) or bool(receipt.get("already_settled", false))
	rolling = false
	view_state = "result"
	if payout_value > 0:
		_play_ui_sfx(&"complete", true)
	else:
		_play_ui_sfx(&"error", true)
	_show_result()

func _show_result() -> void:
	view_state = "result"
	setup_view.visible = false
	active_view.visible = false
	result_view.visible = true
	back_button.visible = false
	var rank_name: String = str(game.get("rank", game.get("result", DicePokerScript.RANK_NO_HAND)))
	var bet_amount: int = int(game.get("bet", selected_bet))
	var payout_amount: int = int(game.get("payout", 0))
	var profit_amount: int = int(game.get("profit", payout_amount - bet_amount))
	result_label.text = rank_name
	result_bet_value.text = "%d CHIP" % bet_amount
	result_payout_label.text = "%d CHIP" % payout_amount
	result_net_label.text = _signed_chip_text(profit_amount)
	result_net_label.add_theme_color_override("font_color", BRIGHT_GOLD if profit_amount > 0 else (CREAM if profit_amount == 0 else Color("#ff9a8e")))
	result_detail_label.text = "%s  ·  ×%.1f RETURN" % [rank_name, float(game.get("multiplier", DicePokerScript.multiplier_for(rank_name)))]
	status_label.text = "RESULT  ·  PLAY AGAINで同じBETを続けられます"
	if chip_label != null:
		chip_label.text = _format_chips(CasinoBankScript.balance())
	var final_faces: Array[int] = _state_dice(game)
	if result_dice_presentation != null and result_dice_presentation.is_node_ready() and final_faces.size() == DicePokerScript.DIE_COUNT and 0 not in final_faces:
		result_dice_presentation.present(final_faces, false, 0)
	_update_die_face_set(result_die_faces, final_faces, [false, false, false, false, false])
	back_button.disabled = false
	_refresh_bet_buttons()
	call_deferred("_animate_result_intro")

func _show_setup(reset_game: bool = true) -> void:
	if reset_game:
		game = {}
		game_id = ""
		pending_roll = {}
		rolling = false
		settled = false
	view_state = "setup"
	setup_view.visible = true
	active_view.visible = false
	result_view.visible = false
	back_button.visible = true
	if help_overlay != null:
		help_overlay.visible = false
	status_label.text = "1  BETを選ぶ   →   2  DEAL   →   3  KEEP & REROLL"
	back_button.disabled = false
	_refresh_all()

func _on_back_pressed() -> void:
	if help_overlay != null and help_overlay.visible:
		_toggle_help()
		return
	if rolling or (not game.is_empty() and bool(game.get("active", false)) and not bool(game.get("finished", false))):
		status_label.text = "HANDをLOCK HANDまたはREROLLで確定してからEXIT。"
		_play_ui_sfx(&"blocked", false)
		return
	_play_ui_sfx(&"back", false)
	back_requested.emit()

func _next_roll_batch(indices: Array[int]) -> Array[int]:
	var result: Array[int] = []
	var count: int = indices.size()
	var queued: Array[int] = _consume_queued_batch()
	for offset: int in range(count):
		var face: int = 0
		if not queued.is_empty():
			var source_index: int = indices[offset] if queued.size() >= DicePokerScript.DIE_COUNT else offset
			if source_index >= 0 and source_index < queued.size():
				face = queued[source_index]
		if face < 1 or face > 6:
			if rng_seed != 0:
				rng.seed = rng_seed
				rng_seed = 0
			face = rng.randi_range(1, 6)
		result.append(clampi(face, 1, 6))
	return result

func _consume_queued_batch() -> Array[int]:
	var source: Variant = null
	if not queued_roll_batch.is_empty():
		if queued_roll_batch[0] is int or queued_roll_batch[0] is float:
			source = queued_roll_batch.duplicate(true)
			queued_roll_batch.clear()
		else:
			source = queued_roll_batch.pop_front()
	elif not queued_roll_values.is_empty():
		source = queued_roll_values.duplicate(true)
		queued_roll_values.clear()
	elif not queued_reroll_values.is_empty():
		source = queued_reroll_values.duplicate(true)
		queued_reroll_values.clear()
	if source is Dictionary:
		var dictionary: Dictionary = source as Dictionary
		if dictionary.get("full_values", null) is Array:
			source = dictionary.get("full_values", [])
		elif dictionary.get("values", null) is Array:
			source = dictionary.get("values", [])
	if not source is Array:
		return []
	var result: Array[int] = []
	for value: Variant in source as Array:
		var face: int = int(value)
		if face >= 1 and face <= 6:
			result.append(face)
	return result

func _animate_roll(full_values: Array[int], indices: Array[int]) -> void:
	if dice_presentation == null or not dice_presentation.is_node_ready() or dice_presentation.dice_roots.size() < DicePokerScript.DIE_COUNT:
		await get_tree().create_timer(ROLL_SECONDS + SETTLE_SECONDS).timeout
		return
	var start_values: Array[int] = _state_dice(game)
	while start_values.size() < DicePokerScript.DIE_COUNT:
		start_values.append(1)
	for index: int in range(DicePokerScript.DIE_COUNT):
		if start_values[index] < 1 or start_values[index] > 6:
			start_values[index] = 1
	dice_presentation.present(start_values, true, 0)
	# DicePresentation3D's legacy API locks a prefix. Poker can KEEP any die, so
	# freeze every die outside this reroll's explicit index list after presenting.
	for index: int in range(DicePokerScript.DIE_COUNT):
		if index not in indices:
			dice_presentation.die_states[index] = DicePresentationScript.DieState.LOCKED
			dice_presentation.face_values[index] = start_values[index]
	await get_tree().create_timer(ROLL_SECONDS).timeout
	if not is_inside_tree():
		return
	dice_presentation.present(full_values, false, 0)
	await get_tree().create_timer(SETTLE_SECONDS).timeout

func _refresh_all() -> void:
	if chip_label != null:
		chip_label.text = _format_chips(CasinoBankScript.balance())
	_refresh_bet_buttons()
	if game.is_empty():
		return
	bet_label.text = "%d" % int(game.get("bet", selected_bet))
	rerolls_label.text = "%d / %d" % [int(game.get("rerolls_remaining", DicePokerScript.remaining_rerolls(game))), DicePokerScript.MAX_REROLLS]
	rank_label.text = str(game.get("rank", DicePokerScript.RANK_NO_HAND))
	_refresh_dice_and_keep()
	_refresh_actions()
	back_button.disabled = bool(game.get("active", false)) and not bool(game.get("finished", false))

func _refresh_dice_and_keep() -> void:
	var faces: Array[int] = _state_dice(game)
	var kept: Array[bool] = _state_kept(game)
	for index: int in range(DicePokerScript.DIE_COUNT):
		var face: int = faces[index] if index < faces.size() else 0
		var button: Button = keep_buttons.get(index) as Button
		if button == null:
			continue
		var keep_text: String = "◆ HELD" if (index < kept.size() and kept[index]) else "OPEN"
		button.text = "DIE %d  ·  %s\n%s" % [index + 1, str(face) if face > 0 else "?", keep_text]
		button.disabled = rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)) or face <= 0
		_apply_keep_style(button, index < kept.size() and kept[index])
	_update_die_face_set(active_die_faces, faces, kept)
	if dice_presentation != null and dice_presentation.is_node_ready() and dice_presentation.dice_roots.size() >= DicePokerScript.DIE_COUNT and faces.size() == DicePokerScript.DIE_COUNT and 0 not in faces:
		dice_presentation.present(faces, false, 0)

func _refresh_actions() -> void:
	if reroll_button == null or lock_button == null:
		return
	var playable: bool = bool(game.get("active", false)) and not bool(game.get("finished", false)) and not rolling
	var all_locked: bool = DicePokerScript.all_kept(game)
	reroll_button.visible = not all_locked
	lock_button.visible = all_locked
	reroll_button.disabled = not playable or not DicePokerScript.can_reroll(game)
	lock_button.disabled = not playable or not DicePokerScript.can_lock_hand(game)
	reroll_button.text = "REROLL  ·  %d LEFT" % DicePokerScript.remaining_rerolls(game)
	lock_button.text = "LOCK HAND  ·  FINAL"
	action_button = lock_button if all_locked else reroll_button

func _refresh_bet_buttons() -> void:
	if chip_label == null:
		return
	var chips: int = CasinoBankScript.balance()
	for amount: int in BET_AMOUNTS:
		var button: Button = bet_buttons.get(amount) as Button
		if button == null:
			continue
		button.disabled = chips < amount or rolling
		button.button_pressed = amount == selected_bet
		_apply_bet_style(button, amount == selected_bet)
	if deal_button != null:
		deal_button.disabled = chips < selected_bet or rolling

func _pending_full_values(pending: Dictionary) -> Array[int]:
	var source: Variant = pending.get("full_values", pending.get("dice", pending.get("values", [])))
	var result: Array[int] = []
	if source is Array:
		for value: Variant in source as Array:
			var face: int = int(value)
			if face >= 1 and face <= 6:
				result.append(face)
	if result.size() == DicePokerScript.DIE_COUNT:
		return result
	var current: Array[int] = _state_dice(game)
	var indices: Array[int] = _pending_indices(pending)
	var values: Array[int] = _pending_values(pending)
	for offset: int in range(mini(indices.size(), values.size())):
		if indices[offset] >= 0 and indices[offset] < current.size():
			current[indices[offset]] = values[offset]
	return current

func _pending_indices(pending: Dictionary) -> Array[int]:
	var source: Variant = pending.get("indices", [])
	var result: Array[int] = []
	if source is Array:
		for value: Variant in source as Array:
			var index: int = int(value)
			if index >= 0 and index < DicePokerScript.DIE_COUNT and index not in result:
				result.append(index)
	return result

func _pending_values(pending: Dictionary) -> Array[int]:
	var source: Variant = pending.get("values", [])
	var result: Array[int] = []
	if source is Array:
		for value: Variant in source as Array:
			var face: int = int(value)
			if face >= 1 and face <= 6:
				result.append(face)
	return result

func _state_dice(state: Dictionary) -> Array[int]:
	var source: Variant = state.get("dice", state.get("values", []))
	var result: Array[int] = []
	if source is Array:
		for value: Variant in source as Array:
			result.append(int(value))
	return result

func _state_kept(state: Dictionary) -> Array[bool]:
	var source: Variant = state.get("kept", state.get("keep_mask", []))
	var result: Array[bool] = []
	if source is Array:
		for value: Variant in source as Array:
			result.append(bool(value))
	while result.size() < DicePokerScript.DIE_COUNT:
		result.append(false)
	if result.size() > DicePokerScript.DIE_COUNT:
		result.resize(DicePokerScript.DIE_COUNT)
	return result

func _apply_keep_style(button: Button, selected: bool) -> void:
	var fill: Color = Color("#f7df9a") if selected else Color("#09281f")
	var border: Color = BRIGHT_GOLD if selected else Color("#6e5940")
	var hover_fill: Color = Color("#fff0b7") if selected else Color("#10412f")
	var normal: StyleBoxFlat = _panel(fill, border, 14, 3 if selected else 2, 8)
	if selected:
		normal.shadow_color = Color("#ffd85a77")
		normal.shadow_size = 6
	var hover: StyleBoxFlat = _panel(hover_fill, GOLD_LIGHT, 14, 3, 8)
	var pressed: StyleBoxFlat = _panel(fill.darkened(0.12), BRIGHT_GOLD, 14, 3, 8)
	var disabled: StyleBoxFlat = _panel(Color("#18231f"), Color("#4b493f"), 14, 1, 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", _focus_style(14))
	button.add_theme_stylebox_override("disabled", disabled)
	var font_color: Color = INK if selected else CREAM
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", INK if selected else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color("#8f8a7b"))

func _apply_button_state(button: Button, selected: bool) -> void:
	_apply_bet_style(button, selected)

func _apply_bet_style(button: Button, selected: bool) -> void:
	var normal: StyleBoxFlat = _panel(Color("#061713dd") if not selected else Color("#1b1408ee"), Color("#74572d") if not selected else BRIGHT_GOLD, 24, 2 if not selected else 4, 6)
	if selected:
		normal.shadow_color = Color("#ffd75b88")
		normal.shadow_size = 9
		normal.shadow_offset = Vector2.ZERO
	var hover: StyleBoxFlat = _panel(Color("#0d3024e8"), GOLD_LIGHT, 24, 3, 6)
	var pressed: StyleBoxFlat = _panel(Color("#211b0ee8"), BRIGHT_GOLD, 24, 4, 6)
	var disabled: StyleBoxFlat = _panel(Color("#131917cc"), Color("#49453c"), 24, 1, 6)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", _focus_style(24))
	button.add_theme_stylebox_override("disabled", disabled)
	var sparkle: TextureRect = button.get_node_or_null("SelectionSparkle") as TextureRect
	if sparkle != null:
		sparkle.visible = selected and not button.disabled
	var chip: TextureRect = button.get_node_or_null("ChipArt") as TextureRect
	if chip != null:
		chip.modulate = Color.WHITE if not button.disabled else Color(0.45, 0.45, 0.42, 0.78)
	var badge: Label = button.get_node_or_null("SelectedBadge") as Label
	if badge != null:
		badge.visible = selected and not button.disabled
	var amount_label: Label = button.get_node_or_null("AmountLabel") as Label
	if amount_label != null:
		amount_label.add_theme_color_override("font_color", Color.WHITE if selected else GOLD_LIGHT)

func _animate_result_intro() -> void:
	if result_card == null or not result_card.visible:
		return
	if result_intro_tween != null:
		result_intro_tween.kill()
	result_card.offset_transform_enabled = true
	result_card.offset_transform_scale = Vector2(0.965, 0.965)
	result_card.modulate.a = 0.0
	if result_sparkle != null:
		result_sparkle.modulate = Color(1, 1, 1, 0.0)
	result_intro_tween = create_tween()
	result_intro_tween.set_parallel(true)
	result_intro_tween.tween_property(result_card, "offset_transform_scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	result_intro_tween.tween_property(result_card, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if result_sparkle != null:
		result_intro_tween.tween_property(result_sparkle, "modulate:a", 0.42, 0.32).set_delay(0.08)

func _wire_button_motion(button: Button) -> void:
	button.offset_transform_enabled = true
	button.mouse_entered.connect(_animate_button.bind(button, Vector2(1.025, 1.025), 0.10))
	button.mouse_exited.connect(_animate_button.bind(button, Vector2.ONE, 0.13))
	button.focus_entered.connect(_animate_button.bind(button, Vector2(1.025, 1.025), 0.10))
	button.focus_exited.connect(_animate_button.bind(button, Vector2.ONE, 0.13))
	button.button_down.connect(_animate_button.bind(button, Vector2(0.975, 0.975), 0.06))
	button.button_up.connect(_animate_button.bind(button, Vector2.ONE, 0.12))

func _animate_button(button: Button, target: Vector2, duration: float) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	var key: int = button.get_instance_id()
	var previous: Variant = button_tweens.get(key, null)
	if previous is Tween:
		(previous as Tween).kill()
	var tween: Tween = create_tween()
	button_tweens[key] = tween
	tween.tween_property(button, "offset_transform_scale", target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx: Node = get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)

func _stat_box(caption: String) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 78
	panel.add_theme_stylebox_override("panel", _panel(Color("#f2d78f"), Color("#a96b2e"), 16, 2, 8))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	panel.add_child(box)
	var cap: Label = _display_label(caption, 12, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value: Label = _display_label("-", 20, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _display_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = _label(text, font_size, color)
	label.add_theme_font_override("font", DISPLAY_FONT)
	return label

func _button(text: String, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 18)
	button.custom_minimum_size = Vector2(90, 96)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.86))
	button.add_theme_constant_override("outline_size", 3)
	if primary:
		_apply_primary_button_style(button, Color("#8b5b1b"), GOLD)
	else:
		_apply_secondary_button_style(button, Color("#2d213f"))
	_wire_button_motion(button)
	return button

func _apply_primary_button_style(button: Button, fill: Color, hover_fill: Color) -> void:
	var normal: StyleBoxFlat = _panel(fill, GOLD, 24, 3, 12)
	normal.shadow_color = Color("#ffc84f55")
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _panel(hover_fill, GOLD_LIGHT, 24, 4, 12))
	button.add_theme_stylebox_override("pressed", _panel(fill.darkened(0.18), BRIGHT_GOLD, 24, 4, 12))
	button.add_theme_stylebox_override("focus", _focus_style(24))
	button.add_theme_stylebox_override("disabled", _panel(Color("#282a26"), Color("#5e594c"), 24, 1, 12))
	button.add_theme_color_override("font_color", GOLD_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#918a79"))

func _apply_secondary_button_style(button: Button, fill: Color) -> void:
	button.add_theme_stylebox_override("normal", _panel(fill, Color("#77548f"), 20, 2, 10))
	button.add_theme_stylebox_override("hover", _panel(fill.lightened(0.12), GOLD, 20, 3, 10))
	button.add_theme_stylebox_override("pressed", _panel(fill.darkened(0.15), BRIGHT_GOLD, 20, 3, 10))
	button.add_theme_stylebox_override("focus", _focus_style(20))
	button.add_theme_stylebox_override("disabled", _panel(Color("#252229"), Color("#4e4952"), 20, 1, 10))
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD_LIGHT)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#8d8791"))

func _apply_utility_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _panel(Color("#051d18e8"), Color("#7d6338"), 20, 2, 9))
	button.add_theme_stylebox_override("hover", _panel(Color("#0b3829ee"), GOLD, 20, 3, 9))
	button.add_theme_stylebox_override("pressed", _panel(Color("#03130f"), BRIGHT_GOLD, 20, 3, 9))
	button.add_theme_stylebox_override("focus", _focus_style(20))
	button.add_theme_stylebox_override("disabled", _panel(Color("#1d211f"), Color("#47483f"), 20, 1, 9))
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD_LIGHT)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#827d73"))

func _apply_round_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _panel(Color("#071629ee"), GOLD, 35, 3, 8))
	button.add_theme_stylebox_override("hover", _panel(Color("#15264a"), GOLD_LIGHT, 35, 4, 8))
	button.add_theme_stylebox_override("pressed", _panel(Color("#040d1d"), BRIGHT_GOLD, 35, 4, 8))
	button.add_theme_stylebox_override("focus", _focus_style(35))
	button.add_theme_stylebox_override("disabled", _panel(Color("#1d222a"), Color("#4d4c48"), 35, 1, 8))
	button.add_theme_color_override("font_color", GOLD_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#89857c"))

func _button_ornament_texture(frame: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = BUTTON_ORNAMENTS
	atlas.region = Rect2(0.0, float(clampi(frame, 0, 3) * 400), 960.0, 400.0)
	return atlas

func _add_button_ornament(button: Button, frame: int) -> void:
	var ornament: TextureRect = TextureRect.new()
	ornament.name = "ButtonOrnament"
	ornament.texture = _button_ornament_texture(frame)
	ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ornament.stretch_mode = TextureRect.STRETCH_SCALE
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep the filigree luxurious without letting it compete with the CTA copy.
	ornament.modulate = Color(1, 1, 1, 0.78)
	button.add_child(ornament)

func _focus_style(radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel(Color.TRANSPARENT, BRIGHT_GOLD, radius, 3, 0)
	style.draw_center = false
	style.expand_margin_left = 3.0
	style.expand_margin_right = 3.0
	style.expand_margin_top = 3.0
	style.expand_margin_bottom = 3.0
	return style

func _separator_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	return style

func _ornate_panel(fill: Color, border: Color, radius: int, width: int, shadow: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel(fill, border, radius, width, 12)
	style.shadow_color = shadow
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 2)
	style.corner_detail = 12
	return style

func _panel(fill: Color, border: Color, radius: int, width: int, content_margin: int = 8) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = content_margin
	style.content_margin_right = content_margin
	style.content_margin_top = content_margin
	style.content_margin_bottom = content_margin
	return style

func _format_chips(value: int) -> String:
	var text: String = str(value)
	var output: String = ""
	while text.length() > 3:
		output = ",%s%s" % [text.right(3), output]
		text = text.left(text.length() - 3)
	return text + output

func _signed_chip_text(value: int) -> String:
	if value == 0:
		return "±0 CHIP"
	if value > 0:
		return "+%d CHIP" % value
	return "%d CHIP" % value
