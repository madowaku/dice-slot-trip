extends Control

## Shared screen frame for every Las Vegas casino game.
##
##   top    : 「カジノへ戻る」 / game title / 「？」 + chip balance
##   middle : the table — the game puts its dice here, they are the hero
##   bottom : one status line, optional game choices, wager row, ONE primary
##
## The shell owns presentation only. It never touches CasinoBank chips or game
## rules; the owning screen listens to the signals and tells the shell what to
## show. The first-play guide is at most three short steps and is remembered
## per facility through CasinoBank so it appears once, then lives behind 「？」.

signal back_requested
signal primary_pressed
signal bet_selected(amount: int)
signal guide_closed

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const BackButtonScript = preload("res://scripts/ui/casino_back_button.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const MAX_GUIDE_STEPS := 3
const BACKDROP := Color("#120d1a")
const FELT := Color("#0e3a2d")
const FELT_EDGE := Color("#c9963d")
const GOLD := Color("#f2bf4c")
const GOLD_BRIGHT := Color("#ffe6a0")
const CREAM := Color("#fff4d6")
const MUTED := Color("#cdbfd7")
const INK := Color("#2a1a0c")
const PANEL := Color("#241a31")
const PANEL_EDGE := Color("#6b5680")
const WIN := Color("#ffd66b")
const LOSE := Color("#b9aec4")

var facility_id := ""
var title_label: Label
var back_button: Button
var help_button: Button
var chip_label: Label
var table_panel: PanelContainer
## Games add their dice and table props here. Full-rect inside the felt.
var table_root: Control
var result_panel: PanelContainer
var result_headline: Label
var result_detail: Label
var status_label: Label
## Optional row for game-specific choices (e.g. 丁 / 半). Hidden while empty.
var choice_row: HBoxContainer
var bet_row: HBoxContainer
var bet_buttons: Dictionary = {}
var primary_button: Button
var guide_overlay: Control

var _balance_shown := 0
var _balance_tween: Tween
var _guide_steps: Array[String] = []
var _guide_title := ""
var _guide_reference := ""
var _selected_bet := 0


func _init() -> void:
	name = "CasinoTableShell"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func configure(new_facility_id: String, title: String) -> void:
	facility_id = new_facility_id
	title_label.text = title
	set_meta("facility_id", facility_id)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "ShellBackdrop"
	backdrop.color = BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.name = "ShellMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)

	var column := VBoxContainer.new()
	column.name = "ShellColumn"
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	# --- top -------------------------------------------------------------
	var header := HBoxContainer.new()
	header.name = "ShellHeader"
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	back_button = Button.new()
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size = Vector2(216, UiTokensScript.TOUCH_MIN)
	BackButtonScript.configure(back_button)
	VisualFeedback.bind_button(back_button)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back_button)

	title_label = _label("", UiTokensScript.FONT_TITLE, GOLD_BRIGHT)
	title_label.name = "ShellTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	header.add_child(title_label)

	help_button = Button.new()
	help_button.name = "HelpButton"
	help_button.text = "？"
	help_button.tooltip_text = "遊び方"
	help_button.custom_minimum_size = Vector2(UiTokensScript.TOUCH_MIN, UiTokensScript.TOUCH_MIN)
	help_button.add_theme_font_override("font", FONT)
	help_button.add_theme_font_size_override("font_size", UiTokensScript.FONT_BODY)
	_style_button(help_button, PANEL, PANEL_EDGE, CREAM, 48)
	VisualFeedback.bind_button(help_button)
	help_button.pressed.connect(open_guide)
	header.add_child(help_button)

	var chip_panel := PanelContainer.new()
	chip_panel.name = "ChipPanel"
	chip_panel.add_theme_stylebox_override("panel", _box(PANEL, PANEL_EDGE, 18, 2, 8))
	column.add_child(chip_panel)
	chip_label = _label("CASINO CHIP  0", UiTokensScript.FONT_CAPTION, CREAM)
	chip_label.name = "ChipLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)

	# --- middle ----------------------------------------------------------
	table_panel = PanelContainer.new()
	table_panel.name = "TablePanel"
	table_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_panel.add_theme_stylebox_override("panel", _box(FELT, FELT_EDGE, 28, 3, 0))
	column.add_child(table_panel)

	table_root = Control.new()
	table_root.name = "TableRoot"
	table_root.clip_contents = true
	table_root.custom_minimum_size = Vector2(0, 360)
	table_panel.add_child(table_root)

	# The result sits on the felt, above the dice, so the eye never leaves
	# the table to learn what happened.
	result_panel = PanelContainer.new()
	result_panel.name = "ResultPanel"
	result_panel.visible = false
	result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_panel.anchor_left = 0.0
	result_panel.anchor_right = 1.0
	result_panel.offset_left = 20
	result_panel.offset_right = -20
	result_panel.offset_top = 18
	result_panel.add_theme_stylebox_override("panel", _box(Color("#130d20f2"), GOLD, 20, 2, 14))
	table_root.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 2)
	result_panel.add_child(result_box)
	result_headline = _label("", UiTokensScript.FONT_TITLE, WIN)
	result_headline.name = "ResultHeadline"
	result_headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_box.add_child(result_headline)
	result_detail = _label("", UiTokensScript.FONT_CAPTION, CREAM)
	result_detail.name = "ResultDetail"
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(result_detail)

	# --- bottom ----------------------------------------------------------
	status_label = _label("", UiTokensScript.FONT_CAPTION, CREAM)
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 40
	column.add_child(status_label)

	choice_row = HBoxContainer.new()
	choice_row.name = "ChoiceRow"
	choice_row.visible = false
	choice_row.add_theme_constant_override("separation", 14)
	column.add_child(choice_row)

	bet_row = HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.visible = false
	bet_row.add_theme_constant_override("separation", 12)
	column.add_child(bet_row)

	primary_button = Button.new()
	primary_button.name = "PrimaryButton"
	primary_button.custom_minimum_size = Vector2(0, 116)
	primary_button.add_theme_font_override("font", FONT)
	primary_button.add_theme_font_size_override("font_size", UiTokensScript.FONT_TITLE)
	_style_primary(primary_button)
	VisualFeedback.bind_button(primary_button)
	primary_button.pressed.connect(func() -> void: primary_pressed.emit())
	column.add_child(primary_button)


# ---------------------------------------------------------------- balance

func set_balance(value: int, animate: bool = false) -> void:
	if _balance_tween != null:
		_balance_tween.kill()
		_balance_tween = null
	var target := maxi(0, value)
	if not animate or not is_inside_tree() or target == _balance_shown:
		_balance_shown = target
		_write_balance(float(target))
		return
	var from := _balance_shown
	_balance_shown = target
	_balance_tween = create_tween()
	_balance_tween.tween_method(_write_balance, float(from), float(target), 0.5)


func balance_shown() -> int:
	return _balance_shown


func _write_balance(value: float) -> void:
	chip_label.text = "CASINO CHIP  %d" % roundi(value)


# ------------------------------------------------------------------- bets

## Build the wager row. Amounts the player cannot afford are disabled.
func set_bets(amounts: Array[int], selected: int, balance: int) -> void:
	for child: Node in bet_row.get_children():
		bet_row.remove_child(child)
		child.queue_free()
	bet_buttons.clear()
	bet_row.visible = not amounts.is_empty()
	if amounts.is_empty():
		return
	var caption := _label("賭け金", UiTokensScript.FONT_CAPTION, MUTED)
	caption.name = "BetCaption"
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.custom_minimum_size.x = 104
	bet_row.add_child(caption)
	for amount: int in amounts:
		var button := Button.new()
		button.name = "BetButton_%d" % amount
		button.text = str(amount)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, UiTokensScript.TOUCH_MIN)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", UiTokensScript.FONT_BODY)
		_style_toggle(button)
		VisualFeedback.bind_button(button)
		button.pressed.connect(_on_bet_pressed.bind(amount))
		bet_row.add_child(button)
		bet_buttons[amount] = button
	_selected_bet = selected
	refresh_bets(balance)


func refresh_bets(balance: int, locked: bool = false) -> void:
	for amount: Variant in bet_buttons.keys():
		var button := bet_buttons[amount] as Button
		# Locking keeps the chosen wager highlighted (a disabled toggle would
		# lose its selected look), so only unaffordable amounts are disabled.
		button.disabled = int(amount) > balance
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
		button.set_pressed_no_signal(int(amount) == _selected_bet)


func selected_bet() -> int:
	return _selected_bet


func _on_bet_pressed(amount: int) -> void:
	_selected_bet = amount
	for key: Variant in bet_buttons.keys():
		(bet_buttons[key] as Button).set_pressed_no_signal(int(key) == amount)
	bet_selected.emit(amount)


# ---------------------------------------------------------------- choices

## Add a quiet secondary action beside the choices. It must never compete
## with the primary button, so it keeps the muted panel look.
func add_action(id: String, text: String) -> Button:
	var button := Button.new()
	button.name = "Action_%s" % id
	button.text = text
	button.custom_minimum_size = Vector2(0, UiTokensScript.TOUCH_MIN)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", UiTokensScript.FONT_CAPTION)
	_style_button(button, PANEL, PANEL_EDGE, CREAM, 20)
	VisualFeedback.bind_button(button)
	choice_row.add_child(button)
	choice_row.visible = true
	return button


## Add a large game-choice toggle (the game decides what it means).
func add_choice(id: String, text: String) -> Button:
	var button := Button.new()
	button.name = "Choice_%s" % id
	button.text = text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, 132)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", UiTokensScript.FONT_BODY)
	_style_toggle(button)
	VisualFeedback.bind_button(button)
	choice_row.add_child(button)
	choice_row.visible = true
	return button


# ---------------------------------------------------------- status/primary

func set_status(text: String) -> void:
	status_label.text = text


func set_primary(text: String, enabled: bool = true) -> void:
	primary_button.text = text
	primary_button.disabled = not enabled


# ----------------------------------------------------------------- result

func show_result(won: bool, headline: String, detail: String) -> void:
	result_headline.text = headline
	result_headline.add_theme_color_override("font_color", WIN if won else LOSE)
	result_detail.text = detail
	result_panel.visible = true
	result_panel.set_meta("won", won)
	if is_inside_tree():
		VisualFeedback.reveal(result_panel)


func clear_result() -> void:
	result_panel.visible = false


# ------------------------------------------------------------------ guide

## Register the how-to (at most three short steps). Extra steps are dropped so
## no game can grow a wall of rules.
func set_guide(title: String, steps: Array[String]) -> void:
	_guide_title = title
	_guide_steps = steps.slice(0, MAX_GUIDE_STEPS)


## Optional small print under the steps (e.g. what each hand returns), so a
## table that needs a lookup keeps it out of the play screen.
func set_guide_reference(text: String) -> void:
	_guide_reference = text


func guide_step_count() -> int:
	return _guide_steps.size()


## Show the guide the first time this facility is opened. Returns true when
## it was shown.
func show_guide_if_first_time() -> bool:
	if facility_id.is_empty() or _guide_steps.is_empty():
		return false
	if CasinoBankScript.has_seen_guide(facility_id):
		return false
	open_guide()
	return true


func is_guide_open() -> bool:
	return guide_overlay != null and is_instance_valid(guide_overlay)


func open_guide() -> void:
	if is_guide_open() or _guide_steps.is_empty():
		return
	guide_overlay = build_guide_overlay(self, _guide_title, _guide_steps, _guide_reference, close_guide)


## Build the shared how-to overlay on any host. Screens that keep their own
## layout (DICE RACE) use this directly so every guide looks the same.
static func build_guide_overlay(host: Control, title: String, steps: Array[String], reference: String, on_close: Callable) -> Control:
	var shown_steps: Array[String] = steps.slice(0, MAX_GUIDE_STEPS)
	var overlay := Control.new()
	overlay.name = "GuideOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 60
	host.add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "GuideDim"
	dim.color = Color(0.03, 0.02, 0.06, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "GuidePanel"
	panel.custom_minimum_size = Vector2(600, 0)
	panel.add_theme_stylebox_override("panel", _box(Color("#1b1328"), GOLD, 26, 3, 28))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var heading := _make_label(title, UiTokensScript.FONT_TITLE, GOLD_BRIGHT)
	heading.name = "GuideTitle"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)

	for index: int in range(shown_steps.size()):
		var row := HBoxContainer.new()
		row.name = "GuideStep%d" % (index + 1)
		row.add_theme_constant_override("separation", 16)
		box.add_child(row)
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(64, 64)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_theme_stylebox_override("panel", _box(GOLD, GOLD_BRIGHT, 32, 0, 0))
		row.add_child(badge)
		var number := _make_label(str(index + 1), UiTokensScript.FONT_BODY, INK)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(number)
		var copy := _make_label(shown_steps[index], UiTokensScript.FONT_BODY, CREAM)
		copy.name = "GuideStepText%d" % (index + 1)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(copy)

	if not reference.is_empty():
		var note := _make_label(reference, 24, MUTED)
		note.name = "GuideReference"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(note)

	var ok := Button.new()
	ok.name = "GuideCloseButton"
	ok.text = "わかった"
	ok.custom_minimum_size = Vector2(0, UiTokensScript.BUTTON_HEIGHT)
	ok.add_theme_font_override("font", FONT)
	ok.add_theme_font_size_override("font_size", UiTokensScript.FONT_BODY)
	_style_primary(ok)
	VisualFeedback.bind_button(ok)
	ok.pressed.connect(on_close)
	box.add_child(ok)
	return overlay


func close_guide() -> void:
	if not is_guide_open():
		return
	guide_overlay.queue_free()
	guide_overlay = null
	if not facility_id.is_empty():
		CasinoBankScript.mark_guide_seen(facility_id)
	guide_closed.emit()


# ---------------------------------------------------------------- styling

func _label(text: String, size: int, color: Color) -> Label:
	return _make_label(text, size, color)


static func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func _box(fill: Color, border: Color, radius: int, width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


static func _style_button(button: Button, fill: Color, border: Color, text: Color, radius: int) -> void:
	button.add_theme_stylebox_override("normal", _box(fill, border, radius, 2, 8))
	button.add_theme_stylebox_override("hover", _box(fill.lightened(0.08), border.lightened(0.2), radius, 2, 8))
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.15), GOLD, radius, 2, 8))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, GOLD, radius, 2, 8))
	button.add_theme_stylebox_override("disabled", _box(Color("#211a2a"), Color("#473b52"), radius, 2, 8))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text)
	button.add_theme_color_override("font_disabled_color", Color("#7d7288"))


## The one button the player should press now: solid gold, dark ink.
static func _style_primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(GOLD, GOLD_BRIGHT, 26, 3, 10))
	button.add_theme_stylebox_override("hover", _box(GOLD.lightened(0.1), Color.WHITE, 26, 3, 10))
	button.add_theme_stylebox_override("pressed", _box(GOLD.darkened(0.12), GOLD_BRIGHT, 26, 3, 10))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, Color.WHITE, 26, 3, 10))
	button.add_theme_stylebox_override("disabled", _box(Color("#2b2335"), Color("#473b52"), 26, 2, 10))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	button.add_theme_color_override("font_disabled_color", Color("#8d8195"))


## Toggle used for wagers and game choices: quiet until selected, then gold.
static func _style_toggle(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(PANEL, PANEL_EDGE, 20, 2, 8))
	button.add_theme_stylebox_override("hover", _box(PANEL.lightened(0.08), PANEL_EDGE.lightened(0.2), 20, 2, 8))
	button.add_theme_stylebox_override("pressed", _box(Color("#4a3410"), GOLD, 20, 4, 8))
	button.add_theme_stylebox_override("hover_pressed", _box(Color("#4a3410"), GOLD_BRIGHT, 20, 4, 8))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, GOLD_BRIGHT, 20, 2, 8))
	button.add_theme_stylebox_override("disabled", _box(Color("#1c1624"), Color("#3a3044"), 20, 2, 8))
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_pressed_color", GOLD_BRIGHT)
	button.add_theme_color_override("font_focus_color", CREAM)
	button.add_theme_color_override("font_disabled_color", Color("#6f6579"))
