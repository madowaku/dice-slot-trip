class_name DiceRouletteScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const ModelScript = preload("res://scripts/game/dice_roulette_model.gd")
const WheelScript = preload("res://scripts/app/dice_roulette_wheel.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const GOLD := Color("#f2c65d")
const CREAM := Color("#fff1d1")
const NAVY := Color("#17172b")
const PANEL := Color("#25233d")
const RED := Color("#df5a5a")
const BLUE := Color("#5d91e5")
const MUTED := Color("#cbbfd5")
const MAX_TOTAL_BET := 50

const MAIN_LABELS := {
	"LOW": "LOW",
	"HIGH": "HIGH",
	"ODD": "ODD",
	"EVEN": "EVEN",
	"LUCKY_7": "LUCKY 7",
	"JACKPOT": "JACKPOT",
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
var main_bets: Dictionary = {}
var side_bet: Dictionary = {}
var undo_stack: Array[Dictionary] = []
var last_main_bets: Dictionary = {}
var last_side_bet: Dictionary = {}
var current_result: Dictionary = {}

var session_start_balance := 0
var session_rounds := 0
var session_total_bet := 0
var session_total_return := 0

var chip_label: Label
var total_bet_label: Label
var status_label: Label
var red_result_label: Label
var blue_result_label: Label
var payout_label: Label
var wheel: DiceRouletteWheel
var betting_panel: VBoxContainer
var round_actions: HBoxContainer
var spin_button: Button
var undo_button: Button
var clear_button: Button
var rebet_button: Button
var rebet_spin_button: Button
var new_bet_button: Button
var cashout_button: Button
var amount_buttons: Dictionary = {}
var main_bet_buttons: Dictionary = {}
var side_bet_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	session_start_balance = CasinoBankScript.balance()
	get_node("/root/BgmManager").call("play_lasvegas_main")
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_stage", &"las_vegas")
	_build_ui()
	phase = Phase.BETTING
	_refresh_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 10)
	margin.add_child(root_box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_box.add_child(header)
	var title := _label("DICE ROULETTE", 31, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	chip_label = _label("CASINO CHIP 0", 20, Color.WHITE)
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(chip_label)

	var help := _label("赤と青、2つのダイスがルーレットを走る。\n止まった WHERE × 出目 BOOST で配当決定！", 15, MUTED)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(help)

	var wheel_panel := PanelContainer.new()
	wheel_panel.add_theme_stylebox_override("panel", _panel(Color("#201d35"), Color("#65527a"), 20, 2))
	root_box.add_child(wheel_panel)
	var wheel_center := CenterContainer.new()
	wheel_panel.add_child(wheel_center)
	wheel = WheelScript.new()
	wheel_center.add_child(wheel)

	var result_row := HBoxContainer.new()
	result_row.add_theme_constant_override("separation", 10)
	root_box.add_child(result_row)
	red_result_label = _result_box("RED  READY", RED)
	blue_result_label = _result_box("BLUE  READY", BLUE)
	result_row.add_child(red_result_label)
	result_row.add_child(blue_result_label)

	status_label = _label("BETエリアを選ぼう", 18, CREAM)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(status_label)

	betting_panel = VBoxContainer.new()
	betting_panel.add_theme_constant_override("separation", 8)
	root_box.add_child(betting_panel)

	var amount_title := _label("BET CHIP", 14, MUTED)
	betting_panel.add_child(amount_title)
	var amount_row := HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 8)
	betting_panel.add_child(amount_row)
	for amount: int in ModelScript.BET_AMOUNTS:
		var caption := "%d" % amount
		if amount == 10:
			caption += "  LONG PLAY"
		elif amount == 20:
			caption += "  STANDARD"
		else:
			caption += "  HIGH ROLLER"
		var button := _button(caption, 14)
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_amount.bind(amount))
		amount_row.add_child(button)
		amount_buttons[amount] = button

	var main_title := _label("MAIN BET  最大3エリア", 14, MUTED)
	betting_panel.add_child(main_title)
	var main_grid := GridContainer.new()
	main_grid.columns = 3
	main_grid.add_theme_constant_override("h_separation", 7)
	main_grid.add_theme_constant_override("v_separation", 7)
	betting_panel.add_child(main_grid)
	for area: String in ModelScript.MAIN_AREAS:
		var button := _button("", 15)
		button.custom_minimum_size.y = 58
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_place_main_bet.bind(area))
		main_grid.add_child(button)
		main_bet_buttons[area] = button

	var side_title := _label("SIDE BET  どれか1つ", 14, MUTED)
	betting_panel.add_child(side_title)
	var side_row := HBoxContainer.new()
	side_row.add_theme_constant_override("separation", 7)
	betting_panel.add_child(side_row)
	for area: String in ModelScript.SIDE_AREAS:
		var button := _button("", 13)
		button.custom_minimum_size.y = 52
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_place_side_bet.bind(area))
		side_row.add_child(button)
		side_bet_buttons[area] = button

	total_bet_label = _label("TOTAL BET 0 / 50", 18, GOLD)
	total_bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	betting_panel.add_child(total_bet_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	betting_panel.add_child(controls)
	undo_button = _button("UNDO", 14)
	clear_button = _button("CLEAR", 14)
	rebet_button = _button("REBET", 14)
	spin_button = _button("SPIN!", 18)
	for button: Button in [undo_button, clear_button, rebet_button, spin_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 54
		controls.add_child(button)
	undo_button.pressed.connect(_undo)
	clear_button.pressed.connect(_clear_bets)
	rebet_button.pressed.connect(_rebet)
	spin_button.pressed.connect(_spin)

	payout_label = _label("", 20, Color.WHITE)
	payout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	payout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(payout_label)

	round_actions = HBoxContainer.new()
	round_actions.add_theme_constant_override("separation", 8)
	root_box.add_child(round_actions)
	rebet_spin_button = _button("REBET & SPIN", 14)
	new_bet_button = _button("NEW BET", 14)
	cashout_button = _button("CASH OUT", 14)
	for button: Button in [rebet_spin_button, new_bet_button, cashout_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 54
		round_actions.add_child(button)
	rebet_spin_button.pressed.connect(_rebet_and_spin)
	new_bet_button.pressed.connect(_new_bet)
	cashout_button.pressed.connect(_cash_out)

	var leave_button := _button("カジノホールへ戻る", 14)
	leave_button.pressed.connect(_cash_out)
	root_box.add_child(leave_button)

func _select_amount(amount: int) -> void:
	if phase != Phase.BETTING:
		return
	selected_bet_amount = amount
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
	current_result = ModelScript.resolve_round(int(red.slot), int(red.face), int(blue.slot), int(blue.face), main_bets, side_bet)
	var settlement: Dictionary = CasinoBankScript.settle_dice_roulette(wager, int(current_result.total_return))
	if not bool(settlement.get("ok", false)):
		phase = Phase.BETTING
		_set_status("BETを確定できませんでした")
		_refresh_ui()
		return

	session_rounds += 1
	session_total_bet += wager
	session_total_return += int(current_result.total_return)
	undo_stack.clear()
	betting_panel.visible = false
	round_actions.visible = false
	payout_label.text = ""
	red_result_label.text = "RED  SPINNING..."
	blue_result_label.text = "BLUE  SPINNING..."
	status_label.text = "WHEREを決める！"
	phase = Phase.SPINNING
	_play_world(&"start")
	wheel.reset_markers()
	await wheel.animate_results(int(current_result.red_slot), int(current_result.blue_slot), int(current_result.red_face), int(current_result.blue_face))

	phase = Phase.AREA_RESULT
	red_result_label.text = "RED  %s" % _display_area(str(current_result.red_area))
	blue_result_label.text = "BLUE  %s" % _display_area(str(current_result.blue_area))
	status_label.text = "WHERE確定！ 次は出目BOOST"
	_play_world(&"stop")
	await get_tree().create_timer(0.38).timeout

	phase = Phase.DICE_RESULT
	red_result_label.text = "RED  %s  🎲%d  ×%s" % [_display_area(str(current_result.red_area)), int(current_result.red_face), _fmt_multiplier(float(current_result.red_boost))]
	blue_result_label.text = "BLUE  %s  🎲%d  ×%s" % [_display_area(str(current_result.blue_area)), int(current_result.blue_face), _fmt_multiplier(float(current_result.blue_boost))]
	if int(current_result.red_face) == 6 or int(current_result.blue_face) == 6:
		status_label.text = "MAX BOOST ×3!"
		_play_world(&"bonus")
	else:
		status_label.text = "%s" % _display_side(str(current_result.side_result))
	await get_tree().create_timer(0.42).timeout

	phase = Phase.PAYOUT
	_show_payout()
	await get_tree().create_timer(0.25).timeout
	phase = Phase.ROUND_END
	betting_panel.visible = false
	round_actions.visible = true
	_refresh_ui()

func _show_payout() -> void:
	var wager := int(current_result.total_bet)
	var returned := int(current_result.total_return)
	var profit := int(current_result.profit)
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
		status_label.text = "NO HIT"
		_play_world(&"close")
	payout_label.text = "BET %d   RETURN %d   PROFIT %s%d" % [wager, returned, "+" if profit >= 0 else "", profit]

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
	red_result_label.text = "RED  READY"
	blue_result_label.text = "BLUE  READY"
	wheel.reset_markers()
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
	chip_label.text = "CASINO CHIP  %d" % CasinoBankScript.balance()
	var betting := phase == Phase.BETTING
	betting_panel.visible = betting
	round_actions.visible = phase == Phase.ROUND_END
	var total := _current_total_bet()
	total_bet_label.text = "TOTAL BET  %d / %d" % [total, MAX_TOTAL_BET]
	for amount: int in amount_buttons.keys():
		var button := amount_buttons[amount] as Button
		button.set_pressed_no_signal(amount == selected_bet_amount)
		button.disabled = not betting
	for area: String in main_bet_buttons.keys():
		var button := main_bet_buttons[area] as Button
		var amount := int(main_bets.get(area, 0))
		var multiplier := float(ModelScript.MAIN_MULTIPLIERS.get(area, 0.0))
		button.text = "%s  ×%s%s" % [MAIN_LABELS[area], _fmt_multiplier(multiplier), "\n%d CHIP" % amount if amount > 0 else ""]
		button.disabled = not betting
	for area: String in side_bet_buttons.keys():
		var button := side_bet_buttons[area] as Button
		var amount := int(side_bet.get("amount", 0)) if str(side_bet.get("area", "")) == area else 0
		var multiplier := float(ModelScript.SIDE_MULTIPLIERS.get(area, 0.0))
		button.text = "%s\n×%s%s" % [SIDE_LABELS[area], _fmt_multiplier(multiplier), "  %d CHIP" % amount if amount > 0 else ""]
		button.disabled = not betting
	undo_button.disabled = not betting or undo_stack.is_empty()
	clear_button.disabled = not betting or total <= 0
	var previous_total := ModelScript.total_bet(last_main_bets, last_side_bet)
	rebet_button.disabled = not betting or previous_total <= 0 or previous_total > CasinoBankScript.balance()
	spin_button.disabled = not betting or total <= 0 or total > CasinoBankScript.balance()
	rebet_spin_button.disabled = phase != Phase.ROUND_END or previous_total <= 0 or previous_total > CasinoBankScript.balance()

func _set_status(text: String) -> void:
	status_label.text = text

func _display_area(area: String) -> String:
	return str(MAIN_LABELS.get(area, area.replace("_", " ")))

func _display_side(area: String) -> String:
	return str(SIDE_LABELS.get(area, area.replace("_", " ")))

func _fmt_multiplier(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)
	return "%.2f" % value

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _result_box(text: String, color: Color) -> Label:
	var label := _label(text, 15, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = 54
	label.add_theme_stylebox_override("normal", _panel(Color("#201f34"), color, 12, 2))
	return label

func _button(text: String, size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", size)
	button.custom_minimum_size = Vector2(92, 44)
	return button

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

func _play_common(cue: StringName) -> void:
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_common_ui_sfx", cue)

func _play_world(cue: StringName) -> void:
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_world_sfx", cue)
