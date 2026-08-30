class_name Treasure21Screen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const Treasure21Script = preload("res://scripts/game/treasure_21_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const FACILITY_ID := "treasure_21"
const META_KEY := "treasure_21"
const BET_AMOUNTS := [5, 10, 20, 50]
const GOLDEN_NUMBERS := [18, 19, 20]
const ROLL_SECONDS := 0.30
const SETTLE_SECONDS := 0.14

const GOLD := Color("#f2bf4c")
const GOLD_LIGHT := Color("#ffe6a0")
const INK := Color("#322315")
const CREAM := Color("#fff0cf")
const NAVY := Color("#171932")
const NAVY_2 := Color("#25234a")
const PLUM := Color("#36213e")
const RED := Color("#9f322b")
const GREEN := Color("#3f7d58")
const TEAL := Color("#70b9ad")

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
			bgm.call("play_lasvegas_main")
		var ui_sfx := get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	_build_ui()
	_resume_or_show_setup()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "MidnightBackdrop"
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var glow := ColorRect.new()
	glow.name = "PlumGlow"
	glow.color = Color("#36213e")
	glow.anchor_right = 1.0
	glow.anchor_bottom = 0.47
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var margin := MarginContainer.new()
	margin.name = "SafeMargins"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Treasure21Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 7)
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
	back_button.custom_minimum_size.y = 96
	back_button.pressed.connect(_on_back_pressed)
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
	header.custom_minimum_size.y = 68
	header.add_theme_stylebox_override("panel", _panel(RED, GOLD, 20, 3))
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	var title := _label("TREASURE 21", 31, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color("#4e1715"))
	title.add_theme_constant_override("outline_size", 5)
	row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.name = "ChipBalancePanel"
	chip_panel.custom_minimum_size.x = 138
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 14, 2))
	chip_label = _label("CHIP 0", 16, CREAM)
	chip_label.name = "ChipBalanceLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_status(root: VBoxContainer) -> void:
	status_label = _label("BETを選んで、21を目指そう", 19, Color.WHITE)
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 40
	root.add_child(status_label)

func _build_setup(root: VBoxContainer) -> void:
	var preview := PanelContainer.new()
	preview.name = "RulesPreview"
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_theme_stylebox_override("panel", _panel(Color("#21162be6"), GOLD, 18, 3))
	root.add_child(preview)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	preview.add_child(box)
	var title := _label("CHOOSE YOUR TREASURE", 27, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var copy := _label("サイコロの合計を21へ。17からCASH OUT可能。\n21を超えたらBUST、GOLDENにぴったり止まると即BONUS。", 18, CREAM)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(copy)
	var table := _label("17 ×0.4   18 ×0.55   19 ×0.8   20 ×1.0   21 ×1.7", 16, Color("#f5cf78"))
	table.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(table)
	var golden_copy := _label("GOLDEN TREASURE  18 ×1.25  ·  19 ×1.4  ·  20 ×1.6", 16, GOLD_LIGHT)
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
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	start_button = _button("GAME START", true)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.y = 104
	start_button.add_theme_font_size_override("font_size", 25)
	start_button.pressed.connect(_start_game)
	root.add_child(start_button)

func _build_active(root: VBoxContainer) -> void:
	var stats := HBoxContainer.new()
	stats.name = "Treasure21Stats"
	stats.add_theme_constant_override("separation", 5)
	root.add_child(stats)
	var total_box := _stat_box("TOTAL")
	total_label = total_box["label"] as Label
	total_label.name = "TotalLabel"
	stats.add_child(total_box["panel"])
	var bet_box := _stat_box("BET")
	bet_label = bet_box["label"] as Label
	bet_label.name = "BetLabel"
	stats.add_child(bet_box["panel"])
	var golden_box := _stat_box("GOLDEN")
	golden_label = golden_box["label"] as Label
	golden_label.name = "GoldenLabel"
	stats.add_child(golden_box["panel"])

	var meter_panel := PanelContainer.new()
	meter_panel.name = "TotalMeterPanel"
	meter_panel.custom_minimum_size.y = 46
	meter_panel.add_theme_stylebox_override("panel", _panel(Color("#21162b"), Color("#7a5a31"), 14, 2))
	root.add_child(meter_panel)
	var meter_box := VBoxContainer.new()
	meter_box.add_theme_constant_override("separation", 1)
	meter_panel.add_child(meter_box)
	total_caption = _label("SAFE PATH  ·  17からCASH OUT  ·  21 TREASURE", 13, Color("#e1d6e4"))
	total_caption.name = "TotalCaption"
	total_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter_box.add_child(total_caption)
	total_meter = ProgressBar.new()
	total_meter.name = "TotalProgress"
	total_meter.min_value = 0.0
	total_meter.max_value = 21.0
	total_meter.show_percentage = false
	total_meter.custom_minimum_size.y = 13
	total_meter.add_theme_stylebox_override("background", _panel(Color("#372d49"), Color("#604b75"), 6, 1))
	total_meter.add_theme_stylebox_override("fill", _panel(GOLD, GOLD_LIGHT, 6, 1))
	meter_box.add_child(total_meter)

	var die_panel := PanelContainer.new()
	die_panel.name = "Treasure21DiePanel"
	die_panel.custom_minimum_size.y = 205
	die_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	die_panel.add_theme_stylebox_override("panel", _panel(Color("#171126"), Color("#7a5a31"), 16, 2))
	root.add_child(die_panel)
	var die_box := VBoxContainer.new()
	die_box.alignment = BoxContainer.ALIGNMENT_CENTER
	die_box.add_theme_constant_override("separation", 1)
	die_panel.add_child(die_box)
	var die_caption := _label("ONE D6 · 未来の6本を読む", 15, Color("#cfc4dc"))
	die_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	die_box.add_child(die_caption)
	var die_center := CenterContainer.new()
	die_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	die_box.add_child(die_center)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "Treasure21Die3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(220, 166)
	die_center.add_child(dice_presentation)
	die_face_label = _label("?", 1, Color.TRANSPARENT)
	die_face_label.name = "DieFaceForTest"
	die_face_label.visible = false
	die_panel.add_child(die_face_label)

	danger_panel = PanelContainer.new()
	danger_panel.name = "DangerZonePanel"
	danger_panel.custom_minimum_size.y = 166
	danger_panel.add_theme_stylebox_override("panel", _panel(Color("#241b38e8"), Color("#bd7654"), 16, 2))
	root.add_child(danger_panel)
	var danger_box := VBoxContainer.new()
	danger_box.add_theme_constant_override("separation", 3)
	danger_panel.add_child(danger_box)
	var danger_title := _label("DANGER ZONE  ·  次の6通り", 16, GOLD_LIGHT)
	danger_title.name = "DangerZoneTitle"
	danger_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	danger_box.add_child(danger_title)
	danger_grid = GridContainer.new()
	danger_grid.name = "DangerPreviewGrid"
	danger_grid.columns = 3
	danger_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	danger_grid.add_theme_constant_override("h_separation", 5)
	danger_grid.add_theme_constant_override("v_separation", 4)
	danger_box.add_child(danger_grid)
	for face: int in range(1, 7):
		var cell := PanelContainer.new()
		cell.name = "Face_%d" % face
		cell.custom_minimum_size = Vector2(0, 58)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_stylebox_override("panel", _panel(Color("#33264d"), Color("#705e84"), 9, 1))
		var label := _label("%d\n—" % face, 14, CREAM)
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
	cashout_button.custom_minimum_size = Vector2(0, 104)
	cashout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cashout_button.add_theme_font_size_override("font_size", 20)
	cashout_button.pressed.connect(_on_cashout_pressed)
	actions.add_child(cashout_button)
	roll_button = _button("ROLL", false)
	roll_button.name = "RollButton"
	roll_button.custom_minimum_size = Vector2(0, 104)
	roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_button.add_theme_font_size_override("font_size", 22)
	roll_button.pressed.connect(_on_roll_pressed)
	actions.add_child(roll_button)

func _build_result(root: VBoxContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	root.add_child(spacer)
	var card := PanelContainer.new()
	card.name = "ResultCard"
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color("#21162bf0"), GOLD, 18, 3))
	root.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	result_label = _label("RESULT", 32, GOLD_LIGHT)
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	result_payout_label = _label("0 CHIP", 42, CREAM)
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
		_spawn_confetti() if payout > 0 else null
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
		"treasure":
			result_label.text = "TREASURE 21!"
			result_detail_label.text = "21に到達。最高配当を獲得しました。"
		"golden":
			result_label.text = "GOLDEN TREASURE!"
			result_detail_label.text = "GOLDEN %d にぴったり到達。自動CASH OUT。" % int(game.get("golden_number", 19))
		"cashout":
			result_label.text = "CASH OUT"
			result_detail_label.text = "TOTAL %d で持ち帰りました。" % int(game.get("total", 0))
		_:
			result_label.text = "RESULT"
			result_detail_label.text = "ゲーム終了。"
	var payout := int(game.get("payout", 0))
	var bet := int(game.get("bet", selected_bet))
	result_payout_label.text = "%d CHIP" % payout
	result_profit_label.text = "PROFIT  %+d CHIP" % (payout - bet)
	status_label.text = "もう一度、TREASUREを狙う？"
	roll_button.disabled = true
	cashout_button.disabled = true
	back_button.disabled = false
	_refresh_all()

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
		chip_label.text = "CHIP  %d" % CasinoBankScript.balance()
	_refresh_bet_buttons()
	if game.is_empty():
		if danger_panel != null:
			danger_panel.visible = false
		return
	var total := int(game.get("total", game.get("current_total", 0)))
	if total_label != null:
		total_label.text = str(total)
	if bet_label != null:
		bet_label.text = "%d" % int(game.get("bet", selected_bet))
	if golden_label != null:
		golden_label.text = str(int(game.get("golden_number", 19)))
	if total_meter != null:
		total_meter.value = clampf(float(total), 0.0, 21.0)
	if total_caption != null:
		if total >= 20:
			total_caption.text = "ONE AWAY  ·  21 TREASURE  ·  BUST IS CLOSE"
		elif total >= 17:
			total_caption.text = "DANGER ZONE  ·  CASH OUT AVAILABLE  ·  NEXT FACE MATTERS"
		else:
			total_caption.text = "SAFE PATH  ·  17からCASH OUT  ·  21 TREASURE"
	if danger_panel != null:
		danger_panel.visible = total >= 17 and bool(game.get("active", false)) and not bool(game.get("finished", false))
	if danger_panel.visible:
		_refresh_danger_preview()
	var can_cash := Treasure21Script.can_cash_out(game) and not rolling
	if cashout_button != null:
		cashout_button.disabled = not can_cash
		cashout_button.text = "CASH OUT\n%d CHIP" % Treasure21Script.payout_for_total(int(game.get("bet", selected_bet)), total)
	if roll_button != null:
		roll_button.disabled = rolling or not bool(game.get("active", false)) or bool(game.get("finished", false))
		roll_button.text = "ROLL\n次の1D6"
	back_button.disabled = rolling or (bool(game.get("active", false)) and not bool(game.get("finished", false)))

func _refresh_danger_preview() -> void:
	var total := int(game.get("total", 0))
	var golden := int(game.get("golden_number", 19))
	var bet := int(game.get("bet", selected_bet))
	danger_preview = Treasure21Script.danger_preview(total, golden)
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
				line += "BUST"
			"treasure":
				line += "TREASURE 21"
			"golden":
				line += "GOLDEN %d" % golden
			_:
				line += str(next_total)
		if payout > 0 and kind != "bust":
			line += "\n%d CHIP" % payout
		label.text = line
		var accent := Color("#8f4f52")
		var fill := Color("#382d43")
		var text_color := CREAM
		match kind:
			"bust":
				accent = RED
				fill = Color("#452536")
				text_color = Color("#ffc3b4")
			"treasure":
				accent = GOLD
				fill = Color("#4d3b25")
				text_color = GOLD_LIGHT
			"golden":
				accent = GOLD_LIGHT
				fill = Color("#514128")
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
	button.custom_minimum_size = Vector2(90, 96)
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
