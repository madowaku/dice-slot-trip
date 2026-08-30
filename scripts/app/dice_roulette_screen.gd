class_name DiceRouletteScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const ModelScript = preload("res://scripts/game/dice_roulette_model.gd")
const WheelScript = preload("res://scripts/app/dice_roulette_wheel.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const DISPLAY_FONT: Font = preload("res://assets/fonts/cinzel/Cinzel-Variable.ttf")
const CASINO_BACKGROUND: Texture2D = preload("res://assets/casino/dice_roulette/ui/casino-table-bg-v1.png")
const DICE_ICON: Texture2D = preload("res://assets/art/ui/common/dice-ivory-brass.png")
const BUTTON_ORNAMENTS: Texture2D = preload("res://assets/art/ui/common/roll-button-ornaments.png")
const SPIN_RING: Texture2D = preload("res://assets/casino/dice_roulette/ui/spin-button-amber-v1.png")
const SPARKLE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/casino/dice_roulette/ui/sparkle_frames/01.png"),
	preload("res://assets/casino/dice_roulette/ui/sparkle_frames/02.png"),
	preload("res://assets/casino/dice_roulette/ui/sparkle_frames/03.png"),
	preload("res://assets/casino/dice_roulette/ui/sparkle_frames/04.png"),
]

const GOLD := Color("#f7c94b")
const BRIGHT_GOLD := Color("#ffe89a")
const CREAM := Color("#fff4d5")
const NAVY := Color("#07130f")
const PANEL := Color("#10251d")
const PANEL_DEEP := Color("#071713")
const EMERALD := Color("#0b5137")
const RED := Color("#d9413d")
const BLUE := Color("#2f73d9")
const MUTED := Color("#d4caa9")
const MAX_TOTAL_BET := 50
const FACILITY_ID := "dice_roulette"

## Test harnesses can silence audio while still exercising the full UI flow.
static var suppress_audio_for_tests := false

const MAIN_LABELS := {
	"LOW": "LOW",
	"HIGH": "HIGH",
	"ODD": "ODD",
	"EVEN": "EVEN",
	"LUCKY_7": "LUCKY 7",
	"JACKPOT": "JACKPOT",
}
const MAIN_TAGS := {
	"LOW": "基本",
	"HIGH": "おすすめ",
	"ODD": "基本",
	"EVEN": "基本",
	"LUCKY_7": "チャンス",
	"JACKPOT": "大穴",
}
const SIDE_LABELS := {
	"RED_LEADS": "RED LEADS",
	"DRAW": "DRAW",
	"BLUE_LEADS": "BLUE LEADS",
}

enum Phase {
	ENTER,
	BETTING,
	BET_LOCK,
	SPINNING,
	AREA_RESULT,
	DICE_RESULT,
	PAYOUT,
	ROUND_END,
	CASH_OUT,
}

var phase: Phase = Phase.ENTER
var rng := RandomNumberGenerator.new()
var selected_bet_amount := 10
var has_confirmed_amount := false
var main_bets: Dictionary = {}
var side_bet: Dictionary = {}
var undo_stack: Array[Dictionary] = []
var last_main_bets: Dictionary = {}
var last_side_bet: Dictionary = {}
var current_result: Dictionary = {}
var game_id := ""
var pending_roll: Dictionary = {}

var session_start_balance := 0
var session_rounds := 0
var session_total_bet := 0
var session_total_return := 0

var chip_label: Label
var total_bet_label: Label
var status_label: Label
var guide_label: Label
var red_result_label: Label
var blue_result_label: Label
var payout_label: Label
var wheel: Control
var wheel_stack: Control
var betting_shell: PanelContainer
var betting_panel: VBoxContainer
var wager_surface: PanelContainer
var action_dock: PanelContainer
var round_actions: HBoxContainer
var spin_button: Button
var undo_button: Button
var clear_button: Button
var rebet_button: Button
var rebet_spin_button: Button
var new_bet_button: Button
var cashout_button: Button
var leave_button: Button
var amount_buttons: Dictionary = {}
var main_bet_buttons: Dictionary = {}
var side_bet_buttons: Dictionary = {}
var sparkle_overlay: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	session_start_balance = CasinoBankScript.balance()
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_dice_roulette")
		var ui_sfx := get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	_build_ui()
	resized.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")
	_resume_or_show_setup()

func _resume_or_show_setup() -> void:
	var active := CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		phase = Phase.BETTING
		_refresh_ui()
		return
	game_id = str(active.get("game_id", ""))
	var session: Dictionary = active.get("session", {}) as Dictionary
	main_bets = (session.get("main_bets", {}) as Dictionary).duplicate(true)
	side_bet = (session.get("side_bet", {}) as Dictionary).duplicate(true)
	var pending: Array = active.get("pending_rolls", []) as Array
	if pending.size() >= 2 and pending[0] is Dictionary and pending[1] is Dictionary:
		pending_roll = {"red": (pending[0] as Dictionary).duplicate(true), "blue": (pending[1] as Dictionary).duplicate(true)}
		current_result = ModelScript.resolve_round(int((pending[0] as Dictionary).get("slot", 0)), int((pending[0] as Dictionary).get("face", 1)), int((pending[1] as Dictionary).get("slot", 0)), int((pending[1] as Dictionary).get("face", 1)), main_bets, side_bet)
		phase = Phase.BET_LOCK
		call_deferred("_resume_pending_roll")
	else:
		phase = Phase.BETTING
		_refresh_ui()

func _resume_pending_roll() -> void:
	if phase != Phase.BET_LOCK or pending_roll.is_empty():
		_refresh_ui()
		return
	await _animate_and_finish_round()

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = CASINO_BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.035, 0.025, 0.48)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 22)
	scroll.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 9)
	margin.add_child(root_box)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	root_box.add_child(nav)
	var back_button := _button("CASINO", 20)
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size = Vector2(142, 54)
	back_button.pressed.connect(_cash_out)
	_apply_button_style(back_button, Color("#09261e"), Color("#164f3b"), GOLD, CREAM, 18, 2)
	nav.add_child(back_button)
	var nav_spacer := Control.new()
	nav_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)
	chip_label = _label("500 CHIP", 22, Color.WHITE)
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_label.custom_minimum_size = Vector2(180, 54)
	chip_label.add_theme_stylebox_override("normal", _panel(Color("#071c16dd"), GOLD, 24, 2))
	nav.add_child(chip_label)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 12)
	root_box.add_child(title_row)
	title_row.add_child(_dice_title_icon(Color("#f25a50")))
	var title := _display_label("DICE ROULETTE", 40, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#271400"))
	title.add_theme_constant_override("outline_size", 7)
	title_row.add_child(title)
	title_row.add_child(_dice_title_icon(Color("#4f8fff")))
	var title_rule := _label("WHERE  ×  DICE BOOST", 18, BRIGHT_GOLD)
	title_rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_rule.add_theme_color_override("font_outline_color", Color.BLACK)
	title_rule.add_theme_constant_override("outline_size", 4)
	root_box.add_child(title_rule)

	guide_label = _label("① チップを選ぼう", 24, CREAM)
	guide_label.name = "CurrentStepGuide"
	guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.custom_minimum_size.y = 50
	guide_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_label.add_theme_color_override("font_outline_color", Color.BLACK)
	guide_label.add_theme_constant_override("outline_size", 4)
	guide_label.add_theme_stylebox_override("normal", _panel(Color("#093122f2"), BRIGHT_GOLD, 18, 2))
	root_box.add_child(guide_label)

	var wheel_panel := PanelContainer.new()
	wheel_panel.add_theme_stylebox_override("panel", _panel(Color("#071a14e8"), GOLD, 28, 3))
	root_box.add_child(wheel_panel)
	var wheel_center := CenterContainer.new()
	wheel_panel.add_child(wheel_center)
	wheel_stack = Control.new()
	wheel_stack.custom_minimum_size = Vector2(450, 450)
	wheel_center.add_child(wheel_stack)
	wheel = WheelScript.new()
	wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wheel_stack.add_child(wheel)
	sparkle_overlay = TextureRect.new()
	sparkle_overlay.texture = _make_sparkle_animation()
	sparkle_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sparkle_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sparkle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sparkle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sparkle_overlay.modulate = Color(1, 1, 1, 0.58)
	sparkle_overlay.visible = false
	wheel_stack.add_child(sparkle_overlay)

	var result_row := HBoxContainer.new()
	result_row.add_theme_constant_override("separation", 10)
	root_box.add_child(result_row)
	red_result_label = _result_box("赤ダイス\n待機中", RED)
	blue_result_label = _result_box("青ダイス\n待機中", BLUE)
	result_row.add_child(red_result_label)
	result_row.add_child(blue_result_label)

	status_label = _label("BETエリアをタップして開始", 18, MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 30
	status_label.add_theme_color_override("font_outline_color", Color("#03140e"))
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_box.add_child(status_label)

	betting_shell = PanelContainer.new()
	betting_shell.name = "BettingTable"
	betting_shell.add_theme_stylebox_override("panel", _ornate_betting_panel())
	root_box.add_child(betting_shell)
	var betting_margin := MarginContainer.new()
	betting_margin.add_theme_constant_override("margin_left", 12)
	betting_margin.add_theme_constant_override("margin_right", 12)
	betting_margin.add_theme_constant_override("margin_top", 10)
	betting_margin.add_theme_constant_override("margin_bottom", 12)
	betting_shell.add_child(betting_margin)
	betting_panel = VBoxContainer.new()
	betting_panel.add_theme_constant_override("separation", 8)
	betting_margin.add_child(betting_panel)

	var amount_title := _section_label("① いくら賭ける？", "10・20・50 CHIP")
	betting_panel.add_child(amount_title)
	var amount_row := HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 8)
	betting_panel.add_child(amount_row)
	for amount: int in ModelScript.BET_AMOUNTS:
		var caption := "%d" % amount
		if amount == 10:
			caption += "  じっくり"
		elif amount == 20:
			caption += "  おすすめ"
		else:
			caption += "  大勝負"
		var button := _button(caption, 22)
		button.toggle_mode = true
		button.custom_minimum_size.y = 68
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_amount.bind(amount))
		_add_button_ornament(button)
		amount_row.add_child(button)
		amount_buttons[amount] = button

	wager_surface = PanelContainer.new()
	wager_surface.name = "WagerSurface"
	wager_surface.add_theme_stylebox_override("panel", _wager_surface_panel())
	betting_panel.add_child(wager_surface)
	var wager_margin := MarginContainer.new()
	wager_margin.add_theme_constant_override("margin_left", 10)
	wager_margin.add_theme_constant_override("margin_right", 10)
	wager_margin.add_theme_constant_override("margin_top", 8)
	wager_margin.add_theme_constant_override("margin_bottom", 10)
	wager_surface.add_child(wager_margin)
	var wager_content := VBoxContainer.new()
	wager_content.add_theme_constant_override("separation", 7)
	wager_margin.add_child(wager_content)

	var main_title := _section_label("② ベットテーブル", "最大3エリア")
	wager_content.add_child(main_title)
	var main_grid := GridContainer.new()
	main_grid.columns = 3
	main_grid.add_theme_constant_override("h_separation", 7)
	main_grid.add_theme_constant_override("v_separation", 7)
	wager_content.add_child(main_grid)
	for area: String in ModelScript.MAIN_AREAS:
		var button := _button("", 22)
		button.custom_minimum_size.y = 92
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_place_main_bet.bind(area))
		_add_chip_badge(button)
		main_grid.add_child(button)
		main_bet_buttons[area] = button

	var side_title := _section_label("色勝負もする？", "任意・1つ")
	wager_content.add_child(side_title)
	var side_row := HBoxContainer.new()
	side_row.add_theme_constant_override("separation", 7)
	wager_content.add_child(side_row)
	for area: String in ModelScript.SIDE_AREAS:
		var button := _button("", 21)
		button.custom_minimum_size.y = 82
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_place_side_bet.bind(area))
		_add_chip_badge(button)
		_add_side_dice_icon(button, area)
		side_row.add_child(button)
		side_bet_buttons[area] = button
	var dock_clearance := Control.new()
	dock_clearance.custom_minimum_size.y = 210
	dock_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	betting_panel.add_child(dock_clearance)

	action_dock = PanelContainer.new()
	action_dock.name = "BetActionDock"
	action_dock.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_dock.offset_left = 18.0
	action_dock.offset_top = -210.0
	action_dock.offset_right = -18.0
	action_dock.offset_bottom = -14.0
	action_dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	action_dock.add_theme_stylebox_override("panel", _panel(Color("#04150ff5"), BRIGHT_GOLD, 22, 3))
	add_child(action_dock)
	var dock_margin := MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 10)
	dock_margin.add_theme_constant_override("margin_right", 10)
	dock_margin.add_theme_constant_override("margin_top", 8)
	dock_margin.add_theme_constant_override("margin_bottom", 8)
	action_dock.add_child(dock_margin)
	var dock_body := VBoxContainer.new()
	dock_body.add_theme_constant_override("separation", 7)
	dock_margin.add_child(dock_body)

	total_bet_label = _label("合計ベット  0 / 50 CHIP", 25, GOLD)
	total_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_bet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_bet_label.custom_minimum_size.y = 50
	total_bet_label.add_theme_stylebox_override("normal", _panel(Color("#061813ee"), GOLD, 18, 2))
	dock_body.add_child(total_bet_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	dock_body.add_child(controls)
	var utility_grid := GridContainer.new()
	utility_grid.columns = 3
	utility_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	utility_grid.add_theme_constant_override("h_separation", 7)
	controls.add_child(utility_grid)
	undo_button = _button("もどす", 20)
	clear_button = _button("消す", 20)
	rebet_button = _button("前回BET", 19)
	spin_button = _display_button("", 32)
	spin_button.name = "SpinButton"
	for button: Button in [undo_button, clear_button, rebet_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 64
		_add_button_ornament(button, 2)
		utility_grid.add_child(button)
	spin_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin_button.custom_minimum_size = Vector2(192, 132)
	controls.add_child(spin_button)
	_add_spin_decoration(spin_button)
	# Keep the primary CTA touch-safe at the 360px reference width while
	# allowing the three utility actions to remain compact but readable.
	undo_button.custom_minimum_size.x = 58
	clear_button.custom_minimum_size.x = 58
	rebet_button.custom_minimum_size.x = 58
	# The project renders a 720px design canvas into the 360px reference
	# viewport, so 192 design pixels provide the required 96px physical hitbox.
	spin_button.custom_minimum_size.x = 192
	undo_button.pressed.connect(_undo)
	clear_button.pressed.connect(_clear_bets)
	rebet_button.pressed.connect(_rebet)
	spin_button.pressed.connect(_spin)

	payout_label = _label("", 23, Color.WHITE)
	payout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	payout_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	payout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	payout_label.custom_minimum_size.y = 52
	payout_label.add_theme_stylebox_override("normal", _panel(Color("#061813dd"), Color("#5f9d75"), 16, 2))
	root_box.add_child(payout_label)

	round_actions = HBoxContainer.new()
	round_actions.add_theme_constant_override("separation", 8)
	root_box.add_child(round_actions)
	rebet_spin_button = _button("同じBETでSPIN", 20)
	new_bet_button = _button("新しくBET", 20)
	cashout_button = _button("終了", 20)
	for button: Button in [rebet_spin_button, new_bet_button, cashout_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 64
		round_actions.add_child(button)
	rebet_spin_button.pressed.connect(_rebet_and_spin)
	new_bet_button.pressed.connect(_new_bet)
	cashout_button.pressed.connect(_cash_out)

	leave_button = _button("カジノホールへ戻る", 18)
	leave_button.custom_minimum_size.y = 56
	_apply_button_style(leave_button, Color("#071713dd"), Color("#11362a"), Color("#8d6b32"), MUTED, 16, 1)
	leave_button.pressed.connect(_cash_out)
	root_box.add_child(leave_button)

func _select_amount(amount: int) -> void:
	if phase != Phase.BETTING:
		return
	selected_bet_amount = amount
	has_confirmed_amount = true
	_set_status("%d CHIPを選択 • BETエリアをタップ" % amount)
	_play_common(&"select")
	_refresh_ui()

func _place_main_bet(area: String) -> void:
	if phase != Phase.BETTING or not ModelScript.MAIN_MULTIPLIERS.has(area):
		return
	if not main_bets.has(area) and main_bets.size() >= ModelScript.MAX_MAIN_BETS:
		_set_status("MAIN BETは最大3エリアまで")
		_play_common(&"blocked")
		return
	if _current_total_bet() + selected_bet_amount > MAX_TOTAL_BET:
		_set_status("TOTAL BETは50 CHIPまで")
		_play_common(&"blocked")
		return
	if _current_total_bet() + selected_bet_amount > CasinoBankScript.balance():
		_set_status("CASINO CHIPが足りない")
		_play_common(&"blocked")
		return
	_push_undo()
	main_bets[area] = int(main_bets.get(area, 0)) + selected_bet_amount
	_set_status("ベット配置 • 合計 %d CHIP" % _current_total_bet())
	_play_common(&"select")
	_refresh_ui()

func _place_side_bet(area: String) -> void:
	if phase != Phase.BETTING or not ModelScript.SIDE_MULTIPLIERS.has(area):
		return
	var old_side_amount := int(side_bet.get("amount", 0))
	var base_total := _current_total_bet() - old_side_amount
	var next_amount := selected_bet_amount
	if str(side_bet.get("area", "")) == area:
		next_amount = old_side_amount + selected_bet_amount
	if base_total + next_amount > MAX_TOTAL_BET:
		_set_status("TOTAL BETは50 CHIPまで")
		_play_common(&"blocked")
		return
	if base_total + next_amount > CasinoBankScript.balance():
		_set_status("CASINO CHIPが足りない")
		_play_common(&"blocked")
		return
	_push_undo()
	side_bet = {"area": area, "amount": next_amount}
	_set_status("色勝負を追加 • 合計 %d CHIP" % _current_total_bet())
	_play_common(&"select")
	_refresh_ui()

func _push_undo() -> void:
	undo_stack.append({"main": main_bets.duplicate(true), "side": side_bet.duplicate(true)})
	if undo_stack.size() > 20:
		undo_stack.pop_front()

func _undo() -> void:
	if phase != Phase.BETTING or undo_stack.is_empty():
		return
	var snapshot: Dictionary = undo_stack.pop_back()
	main_bets = (snapshot.get("main", {}) as Dictionary).duplicate(true)
	side_bet = (snapshot.get("side", {}) as Dictionary).duplicate(true)
	_play_common(&"cancel")
	_refresh_ui()

func _clear_bets() -> void:
	if phase != Phase.BETTING or _current_total_bet() <= 0:
		return
	_push_undo()
	main_bets.clear()
	side_bet.clear()
	_play_common(&"deselect")
	_refresh_ui()

func _rebet() -> void:
	if phase != Phase.BETTING or last_main_bets.is_empty() and last_side_bet.is_empty():
		return
	var amount := ModelScript.total_bet(last_main_bets, last_side_bet)
	if amount > MAX_TOTAL_BET or amount > CasinoBankScript.balance():
		_set_status("前回BETを置くCHIPが足りない")
		_play_common(&"blocked")
		return
	_push_undo()
	main_bets = last_main_bets.duplicate(true)
	side_bet = last_side_bet.duplicate(true)
	_play_common(&"select")
	_refresh_ui()

func _spin() -> void:
	if phase != Phase.BETTING:
		return
	var wager := _current_total_bet()
	if wager <= 0:
		_set_status("BETしてからSPINしよう")
		return
	if wager > CasinoBankScript.balance():
		_set_status("CASINO CHIPが足りない")
		_refresh_ui()
		return

	phase = Phase.BET_LOCK
	last_main_bets = main_bets.duplicate(true)
	last_side_bet = side_bet.duplicate(true)
	var red := ModelScript.roll_die(rng)
	var blue := ModelScript.roll_die(rng)
	pending_roll = {"red": red.duplicate(true), "blue": blue.duplicate(true)}
	var started := CasinoBankScript.begin_game(FACILITY_ID, wager, {
		"phase": "SPINNING",
		"main_bets": main_bets.duplicate(true),
		"side_bet": side_bet.duplicate(true),
		"pending_rolls": [red.duplicate(true), blue.duplicate(true)],
	})
	if not bool(started.get("ok", false)):
		phase = Phase.BETTING
		_set_status("BETを確定できませんでした")
		_refresh_ui()
		return
	game_id = str(started.get("game_id", ""))
	current_result = ModelScript.resolve_round(int(red.slot), int(red.face), int(blue.slot), int(blue.face), main_bets, side_bet)
	await _animate_and_finish_round()

func _animate_and_finish_round() -> void:
	if current_result.is_empty() or pending_roll.is_empty():
		phase = Phase.BETTING
		_refresh_ui()
		return
	var wager := int(current_result.total_bet)
	var red: Dictionary = pending_roll.get("red", {}) as Dictionary
	var blue: Dictionary = pending_roll.get("blue", {}) as Dictionary
	if not red.is_empty() and not blue.is_empty():
		current_result = ModelScript.resolve_round(int(red.get("slot", 0)), int(red.get("face", 1)), int(blue.get("slot", 0)), int(blue.get("face", 1)), main_bets, side_bet)
	undo_stack.clear()
	betting_shell.visible = false
	betting_panel.visible = false
	action_dock.visible = false
	round_actions.visible = false
	status_label.visible = true
	payout_label.text = ""
	red_result_label.text = "赤ダイス\n回転中…"
	blue_result_label.text = "青ダイス\n回転中…"
	guide_label.text = "SPIN中  •  ダイスを見よう"
	status_label.text = "回転中…"
	_set_wheel_focus(true)
	sparkle_overlay.visible = true
	phase = Phase.SPINNING
	_play_world(&"start")
	wheel.reset_markers()
	await wheel.animate_results(int(current_result.red_slot), int(current_result.blue_slot), int(current_result.red_face), int(current_result.blue_face))

	phase = Phase.AREA_RESULT
	red_result_label.text = "赤  %s" % _display_area(str(current_result.red_area))
	blue_result_label.text = "青  %s" % _display_area(str(current_result.blue_area))
	status_label.text = "賭け先が確定"
	_play_world(&"stop")
	await get_tree().create_timer(0.38).timeout

	phase = Phase.DICE_RESULT
	red_result_label.text = "%s\n出目%d  ×%s" % [_display_area(str(current_result.red_area)), int(current_result.red_face), _fmt_multiplier(float(current_result.red_boost))]
	blue_result_label.text = "%s\n出目%d  ×%s" % [_display_area(str(current_result.blue_area)), int(current_result.blue_face), _fmt_multiplier(float(current_result.blue_boost))]
	if int(current_result.red_face) == 6 or int(current_result.blue_face) == 6:
		status_label.text = "MAX BOOST ×3!"
		_play_world(&"bonus")
	else:
		status_label.text = "%s  •  BOOST確定" % _display_side(str(current_result.side_result))
	await get_tree().create_timer(0.42).timeout

	phase = Phase.PAYOUT
	var settlement := CasinoBankScript.settle_game(FACILITY_ID, int(current_result.total_return), current_result, game_id)
	if not bool(settlement.get("ok", false)) and not bool(settlement.get("already_settled", false)):
		_set_status("精算を完了できませんでした")
		phase = Phase.ROUND_END
		_refresh_ui()
		return
	session_rounds += 1
	session_total_bet += wager
	session_total_return += int(current_result.total_return)
	_show_payout()
	await get_tree().create_timer(0.25).timeout
	phase = Phase.ROUND_END
	pending_roll.clear()
	game_id = ""
	betting_panel.visible = false
	round_actions.visible = true
	_refresh_ui()

func _show_payout() -> void:
	var wager := int(current_result.total_bet)
	var returned := int(current_result.total_return)
	var profit := int(current_result.profit)
	sparkle_overlay.visible = profit > 0
	chip_label.text = "CASINO CHIP  %d" % CasinoBankScript.balance()
	if bool(current_result.double_jackpot_max):
		status_label.text = "DOUBLE JACKPOT  MAX BOOST!!"
		_play_world(&"achievement")
	elif bool(current_result.double_jackpot):
		status_label.text = "DOUBLE JACKPOT!!"
		_play_world(&"bonus")
	elif profit >= 100:
		status_label.text = "MEGA WIN!"
		_play_world(&"achievement")
	elif profit >= 50:
		status_label.text = "BIG WIN!"
		_play_world(&"reward")
	elif profit > 0:
		status_label.text = "WIN!"
		_play_world(&"success")
	elif returned > 0:
		status_label.text = "RETURN %d" % returned
	else:
		status_label.text = "今回はハズレ… 次こそ！"
		_play_world(&"close")
	guide_label.text = "結果  •  %s" % ("WIN!" if profit > 0 else "もう一度挑戦しよう")
	payout_label.text = "BET %d   RETURN %d   NET %s%d CHIP" % [wager, returned, "+" if profit >= 0 else "", profit]

func _rebet_and_spin() -> void:
	if phase != Phase.ROUND_END:
		return
	var amount := ModelScript.total_bet(last_main_bets, last_side_bet)
	if amount <= 0 or amount > CasinoBankScript.balance():
		_new_bet()
		_set_status("前回BET分のCHIPが足りない。新しくBETしよう")
		return
	main_bets = last_main_bets.duplicate(true)
	side_bet = last_side_bet.duplicate(true)
	phase = Phase.BETTING
	_refresh_ui()
	_spin()

func _new_bet() -> void:
	if phase != Phase.ROUND_END:
		return
	phase = Phase.BETTING
	main_bets.clear()
	side_bet.clear()
	undo_stack.clear()
	payout_label.text = ""
	red_result_label.text = "赤ダイス\n待機中"
	blue_result_label.text = "青ダイス\n待機中"
	wheel.reset_markers()
	_set_wheel_focus(false)
	sparkle_overlay.visible = false
	status_label.text = "次のBETを選ぼう"
	_refresh_ui()

func _cash_out() -> void:
	if phase in [Phase.BET_LOCK, Phase.SPINNING, Phase.AREA_RESULT, Phase.DICE_RESULT, Phase.PAYOUT]:
		return
	phase = Phase.CASH_OUT
	var profit := session_total_return - session_total_bet
	status_label.text = "CASH OUT  %d PLAY  PROFIT %s%d CHIP" % [session_rounds, "+" if profit >= 0 else "", profit]
	_play_common(&"back")
	back_requested.emit()

func _current_total_bet() -> int:
	return ModelScript.total_bet(main_bets, side_bet)

func _refresh_ui() -> void:
	chip_label.text = "%s  CHIP" % _format_chips(CasinoBankScript.balance())
	var betting := phase == Phase.BETTING
	status_label.visible = not betting
	betting_shell.visible = betting
	betting_panel.visible = betting
	action_dock.visible = betting
	round_actions.visible = phase == Phase.ROUND_END
	var total := _current_total_bet()
	total_bet_label.text = "合計ベット  %d / %d CHIP" % [total, MAX_TOTAL_BET]
	for amount: int in amount_buttons.keys():
		var button := amount_buttons[amount] as Button
		button.set_pressed_no_signal(amount == selected_bet_amount)
		button.disabled = not betting
		if amount == selected_bet_amount:
			_apply_button_style(button, Color("#f3d179"), Color("#ffeeb2"), BRIGHT_GOLD, Color("#241400"), 20, 3)
			_set_button_ornament(button, 3)
		else:
			_apply_button_style(button, Color("#0b2a20"), Color("#164b38"), Color("#9a7130"), CREAM, 20, 2)
			_set_button_ornament(button, 0)
	for area: String in main_bet_buttons.keys():
		var button := main_bet_buttons[area] as Button
		var amount := int(main_bets.get(area, 0))
		var multiplier := float(ModelScript.MAIN_MULTIPLIERS.get(area, 0.0))
		button.text = "%s\n%s  ×%s" % [MAIN_LABELS[area], MAIN_TAGS[area], _fmt_multiplier(multiplier)]
		button.disabled = not betting
		_set_chip_badge(button, amount)
		_style_bet_button(button, area, amount > 0)
	for area: String in side_bet_buttons.keys():
		var button := side_bet_buttons[area] as Button
		var amount := int(side_bet.get("amount", 0)) if str(side_bet.get("area", "")) == area else 0
		var multiplier := float(ModelScript.SIDE_MULTIPLIERS.get(area, 0.0))
		var side_caption := "赤が勝つ" if area == "RED_LEADS" else ("青が勝つ" if area == "BLUE_LEADS" else "同じ出目")
		button.text = "%s\n%s  ×%s" % ["RED" if area == "RED_LEADS" else ("BLUE" if area == "BLUE_LEADS" else "DRAW"), side_caption, _fmt_multiplier(multiplier)]
		button.disabled = not betting
		_set_chip_badge(button, amount)
		_style_side_button(button, area, amount > 0)
	undo_button.disabled = not betting or undo_stack.is_empty()
	clear_button.disabled = not betting or total <= 0
	var previous_total := ModelScript.total_bet(last_main_bets, last_side_bet)
	rebet_button.disabled = not betting or previous_total <= 0 or previous_total > CasinoBankScript.balance()
	spin_button.disabled = not betting or total <= 0 or total > CasinoBankScript.balance()
	rebet_spin_button.disabled = phase != Phase.ROUND_END or previous_total <= 0 or previous_total > CasinoBankScript.balance()
	_style_utility_button(undo_button)
	_style_utility_button(clear_button)
	_style_utility_button(rebet_button)
	_style_spin_button(spin_button, not spin_button.disabled)
	_refresh_guide(total)
	_apply_button_style(rebet_spin_button, Color("#87510f"), Color("#b06c13"), GOLD, Color.WHITE, 18, 2)
	_apply_button_style(new_bet_button, Color("#0b5137"), Color("#14714d"), GOLD, Color.WHITE, 18, 2)
	_apply_button_style(cashout_button, Color("#321a18"), Color("#5b2923"), Color("#bd805a"), CREAM, 18, 2)

func _set_status(text: String) -> void:
	status_label.text = text

func _refresh_guide(total: int) -> void:
	if phase != Phase.BETTING:
		return
	if total > 0:
		guide_label.text = "③ SPINでスタート  •  BET %d CHIP" % total
	elif has_confirmed_amount:
		guide_label.text = "② BETエリアをタップ"
	else:
		guide_label.text = "① チップを選ぼう  •  10 CHIP"

func _apply_responsive_layout() -> void:
	if wheel_stack == null:
		return
	var compact := size.y > 0.0 and size.y < 1450.0
	wheel_stack.custom_minimum_size = Vector2(390, 390) if compact else Vector2(450, 450)
	if leave_button != null:
		leave_button.visible = not compact
	for button: Button in amount_buttons.values():
		button.custom_minimum_size.y = 62 if compact else 68
	for button: Button in main_bet_buttons.values():
		button.custom_minimum_size.y = 82 if compact else 92
	for button: Button in side_bet_buttons.values():
		button.custom_minimum_size.y = 74 if compact else 82
	for button: Button in [undo_button, clear_button, rebet_button, spin_button]:
		if button != null:
			if button == spin_button:
				button.custom_minimum_size.y = 124 if compact else 132
			else:
				button.custom_minimum_size.y = 58 if compact else 64

func _set_wheel_focus(focused: bool) -> void:
	if wheel_stack == null:
		return
	var compact := size.y > 0.0 and size.y < 1450.0
	var wheel_size := 560 if compact else 620
	if not focused:
		wheel_size = 390 if compact else 450
	wheel_stack.custom_minimum_size = Vector2(wheel_size, wheel_size)

func _display_area(area: String) -> String:
	return str(MAIN_LABELS.get(area, area.replace("_", " ")))

func _display_side(area: String) -> String:
	return str(SIDE_LABELS.get(area, area.replace("_", " ")))

func _fmt_multiplier(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)
	return "%.2f" % value

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

func _dice_title_icon(tint: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = DICE_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	icon.modulate = tint
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _section_label(title: String, hint: String) -> Label:
	var label := _label("◆  %s    %s" % [title, hint], 21, BRIGHT_GOLD)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	return label

func _add_chip_badge(button: Button) -> void:
	var badge := _label("", 15, Color.WHITE)
	badge.name = "BetChipBadge"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	badge.offset_left = -62.0
	badge.offset_top = -33.0
	badge.offset_right = -7.0
	badge.offset_bottom = -7.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false
	badge.add_theme_color_override("font_outline_color", Color.BLACK)
	badge.add_theme_constant_override("outline_size", 3)
	badge.add_theme_stylebox_override("normal", _panel(Color("#173d8f"), BRIGHT_GOLD, 13, 2))
	button.add_child(badge)

func _button_ornament_texture(frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = BUTTON_ORNAMENTS
	atlas.region = Rect2(0.0, float(clampi(frame, 0, 3) * 400), 960.0, 400.0)
	return atlas

func _add_button_ornament(button: Button, frame: int = 0) -> void:
	var ornament := TextureRect.new()
	ornament.name = "ButtonOrnament"
	ornament.texture = _button_ornament_texture(frame)
	ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ornament.stretch_mode = TextureRect.STRETCH_SCALE
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ornament.modulate = Color(1.0, 1.0, 1.0, 0.94)
	button.add_child(ornament)
	var caption_size := maxi(16, button.get_theme_font_size("font_size") - 4)
	var caption := _label(button.text, caption_size, CREAM)
	caption.name = "ButtonCaption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.offset_top = 16.0
	caption.offset_bottom = -2.0
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.86))
	caption.add_theme_constant_override("outline_size", 3)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(caption)
	button.set_meta("ornament_caption", button.text)
	button.text = ""

func _set_button_ornament(button: Button, frame: int) -> void:
	var ornament := button.get_node_or_null("ButtonOrnament") as TextureRect
	if ornament != null:
		ornament.texture = _button_ornament_texture(frame)
	var caption := button.get_node_or_null("ButtonCaption") as Label
	if caption != null and not button.text.is_empty():
		caption.text = button.text
		button.set_meta("ornament_caption", button.text)
		button.text = ""

func _add_side_dice_icon(button: Button, area: String) -> void:
	var icon := TextureRect.new()
	icon.name = "SideDiceIcon"
	icon.texture = DICE_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	icon.offset_left = 9.0
	icon.offset_top = -23.0
	icon.offset_right = 55.0
	icon.offset_bottom = 23.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = RED.lightened(0.12) if area == "RED_LEADS" else (BLUE.lightened(0.18) if area == "BLUE_LEADS" else Color("#d7c9a3"))
	button.add_child(icon)
	var caption := button.get_node_or_null("ButtonCaption") as Label
	if caption != null:
		caption.offset_left = 30.0

func _add_spin_decoration(button: Button) -> void:
	var ring := TextureRect.new()
	ring.name = "SpinGoldRing"
	ring.texture = SPIN_RING
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(ring)

	var caption := _display_label("SPIN!", 35, Color.WHITE)
	caption.name = "SpinCaption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.add_theme_color_override("font_outline_color", Color("#421c00"))
	caption.add_theme_constant_override("outline_size", 6)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(caption)

func _set_chip_badge(button: Button, amount: int) -> void:
	var badge := button.get_node_or_null("BetChipBadge") as Label
	if badge == null:
		return
	badge.visible = amount > 0
	badge.text = "%d CHIP" % amount

func _result_box(text: String, color: Color) -> Label:
	var label := _label(text, 21, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = 64
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_stylebox_override("normal", _panel(color.darkened(0.62), color.lightened(0.16), 16, 3))
	return label

func _button(text: String, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size = Vector2(92, 44)
	button.focus_mode = Control.FOCUS_ALL
	VisualFeedback.bind_button(button)
	return button

func _display_button(text: String, font_size: int) -> Button:
	var button := _button(text, font_size)
	button.add_theme_font_override("font", DISPLAY_FONT)
	return button

func _make_sparkle_animation() -> AnimatedTexture:
	var texture := AnimatedTexture.new()
	texture.frames = SPARKLE_TEXTURES.size()
	texture.pause = false
	texture.one_shot = false
	texture.speed_scale = 1.15
	for index: int in range(SPARKLE_TEXTURES.size()):
		texture.set_frame_texture(index, SPARKLE_TEXTURES[index])
		texture.set_frame_duration(index, 0.16 if index != 2 else 0.28)
	return texture

func _format_chips(value: int) -> String:
	var text := str(value)
	var output := ""
	while text.length() > 3:
		output = ",%s%s" % [text.right(3), output]
		text = text.left(text.length() - 3)
	return text + output

func _style_bet_button(button: Button, area: String, selected: bool) -> void:
	var accent := Color("#3c9a6d")
	var fill := Color("#09271e")
	if area == "HIGH":
		accent = Color("#d85d4b")
	elif area == "ODD":
		accent = Color("#9b6bd1")
	elif area == "EVEN":
		accent = Color("#55a68d")
	elif area == "LUCKY_7":
		accent = Color("#ad68cf")
		fill = Color("#30163f")
	elif area == "JACKPOT":
		accent = Color("#e7a629")
		fill = Color("#4b1812")
	if selected:
		_apply_button_style(button, accent.darkened(0.32), accent.darkened(0.12), BRIGHT_GOLD, Color.WHITE, 18, 4)
	else:
		_apply_button_style(button, fill, fill.lightened(0.10), accent.darkened(0.12), CREAM, 18, 2)

func _style_side_button(button: Button, area: String, selected: bool) -> void:
	var accent := Color("#a3a3a3")
	var fill := Color("#202522")
	if area == "RED_LEADS":
		accent = RED.lightened(0.08)
		fill = Color("#461713")
	elif area == "BLUE_LEADS":
		accent = BLUE.lightened(0.10)
		fill = Color("#112d5c")
	if selected:
		_apply_button_style(button, fill.lightened(0.12), fill.lightened(0.20), BRIGHT_GOLD, Color.WHITE, 18, 4)
	else:
		_apply_button_style(button, fill, fill.lightened(0.08), accent, CREAM, 18, 2)

func _style_utility_button(button: Button) -> void:
	_apply_button_style(button, Color("#081b15"), Color("#12372a"), Color("#80622f"), MUTED, 16, 1)

func _style_spin_button(button: Button, enabled: bool) -> void:
	var clear_style := _panel(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 30, 0)
	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", clear_style)
	button.add_theme_stylebox_override("focus", clear_style)
	button.add_theme_stylebox_override("pressed", clear_style)
	button.add_theme_stylebox_override("disabled", clear_style)
	var ring := button.get_node_or_null("SpinGoldRing") as TextureRect
	if ring != null:
		ring.modulate = Color.WHITE if enabled else Color(0.62, 0.62, 0.58, 0.78)
	var caption := button.get_node_or_null("SpinCaption") as Label
	if caption != null:
		caption.add_theme_color_override("font_color", Color.WHITE if enabled else Color("#b7ad98"))

func _apply_button_style(button: Button, fill: Color, hover: Color, border: Color, font_color: Color, radius: int, border_width: int) -> void:
	var normal := _panel(fill, border, radius, border_width)
	var hover_style := _panel(hover, border.lightened(0.16), radius, border_width + 1)
	var pressed := _panel(hover.lightened(0.08), BRIGHT_GOLD, radius, border_width + 1)
	var disabled := _panel(fill.darkened(0.38), border.darkened(0.44), radius, max(1, border_width - 1))
	if button.get_node_or_null("BetChipBadge") != null:
		normal.content_margin_right = 18
		normal.content_margin_bottom = 18
		hover_style.content_margin_right = 18
		hover_style.content_margin_bottom = 18
		pressed.content_margin_right = 18
		pressed.content_margin_bottom = 18
		disabled.content_margin_right = 18
		disabled.content_margin_bottom = 18
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	var decorated_caption := button.get_node_or_null("ButtonCaption") as Label
	if decorated_caption != null:
		decorated_caption.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_focus_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	else:
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("font_focus_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color("#8f897b"))
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.82))
	button.add_theme_constant_override("outline_size", 3)

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _ornate_betting_panel() -> StyleBoxFlat:
	var style := _panel(Color("#061d16f2"), Color("#d8a93d"), 22, 3)
	style.shadow_color = Color("#f3c84b55")
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 2.0)
	style.corner_detail = 12
	return style

func _wager_surface_panel() -> StyleBoxFlat:
	var style := _panel(Color("#0a3425e8"), Color("#5f9d75"), 18, 2)
	style.shadow_color = Color("#020f0a99")
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 2.0)
	style.corner_detail = 10
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 8
	return style

func _play_common(cue: StringName) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_common_ui_sfx", cue)

func _play_world(cue: StringName) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_world_sfx", cue)
