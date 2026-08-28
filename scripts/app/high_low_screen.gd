class_name HighLowScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const HighLowScript = preload("res://scripts/game/high_low_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const FACILITY_ID := "high_low"
const BET_AMOUNTS := [10, 20, 50]
const ROLL_SECONDS := 0.28
const SETTLE_SECONDS := 0.12

const GOLD := Color("#f2bf4c")
const GOLD_LIGHT := Color("#ffe6a0")
const INK := Color("#322315")
const CREAM := Color("#fff0cf")
const NAVY := Color("#171932")
const NAVY_2 := Color("#25234a")
const PLUM := Color("#36213e")
const RED := Color("#9f322b")
const GREEN := Color("#3f7d58")

## Set by the isolated rules harness to avoid starting audio playback while
## it checks persistence. Runtime builds leave this false and keep the
## Las Vegas music/SFX routing enabled.
static var suppress_audio_for_tests := false

var game: Dictionary = {}
var game_id := ""
var selected_bet := 20
var rolling := false
var settled := false
var rng_seed := 0
var queued_roll_value := 0
var rng := RandomNumberGenerator.new()
var pending_roll: Dictionary = {}
var view_state := "setup"

var chip_label: Label
var status_label: Label
var current_label: Label
var pot_label: Label
var streak_label: Label
var die_face_label: Label
var result_label: Label
var result_payout_label: Label
var result_detail_label: Label
var start_button: Button
var cashout_button: Button
var again_button: Button
var exit_button: Button
var back_button: Button
var setup_view: VBoxContainer
var active_view: VBoxContainer
var result_view: VBoxContainer
var choice_buttons: Dictionary = {}
var bet_buttons: Dictionary = {}
var dice_presentation: DicePresentation3D
var die_panel: PanelContainer
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
	glow.anchor_bottom = 0.42
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
	root.name = "HighLowRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 7)
	margin.add_child(root)
	_build_header(root)
	_build_status(root)

	setup_view = VBoxContainer.new()
	setup_view.name = "HighLowSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 8)
	root.add_child(setup_view)
	_build_setup(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "HighLowActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 7)
	root.add_child(active_view)
	_build_active(active_view)

	result_view = VBoxContainer.new()
	result_view.name = "HighLowResultView"
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
	effect_layer.name = "HighLowEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 30
	add_child(effect_layer)

func _build_header(root: VBoxContainer) -> void:
	var header := PanelContainer.new()
	header.name = "HighLowHeader"
	header.custom_minimum_size.y = 64
	header.add_theme_stylebox_override("panel", _panel(RED, GOLD, 20, 3))
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	var title := _label("HIGH / LOW", 34, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color("#4e1715"))
	title.add_theme_constant_override("outline_size", 5)
	row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.name = "ChipBalancePanel"
	chip_panel.custom_minimum_size.x = 126
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 14, 2))
	chip_label = _label("CHIP 0", 16, CREAM)
	chip_label.name = "ChipBalanceLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_status(root: VBoxContainer) -> void:
	status_label = _label("BETを選んで、次の目を読む", 19, Color.WHITE)
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
	box.add_theme_constant_override("separation", 10)
	preview.add_child(box)
	var title := _label("READ THE NEXT FACE", 28, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var copy := _label("CURRENTの目より LOW / SAME / HIGH を選択。\n的中するたびPOTが増え、5連勝で自動CASH OUT。", 19, CREAM)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(copy)
	var table := _label("SAME は常に x5.5  ·  失敗するとPOTは0", 18, Color("#f5cf78"))
	table.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(table)

	var caption := _label("BET", 20, GOLD_LIGHT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(caption)
	var bet_row := HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bet_row.add_theme_constant_override("separation", 7)
	root.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button := _button("%d CHIP" % amount)
		button.name = "Bet_%d" % amount
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	start_button = _button("GAME START", true)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.y = 104
	start_button.add_theme_font_size_override("font_size", 26)
	start_button.pressed.connect(_start_game)
	root.add_child(start_button)

func _build_active(root: VBoxContainer) -> void:
	var stats := HBoxContainer.new()
	stats.name = "HighLowStats"
	stats.add_theme_constant_override("separation", 5)
	root.add_child(stats)
	var current_box := _stat_box("CURRENT")
	current_label = current_box["label"] as Label
	current_label.name = "CurrentLabel"
	stats.add_child(current_box["panel"])
	var pot_box := _stat_box("POT")
	pot_label = pot_box["label"] as Label
	pot_label.name = "PotLabel"
	stats.add_child(pot_box["panel"])
	var streak_box := _stat_box("WIN STREAK")
	streak_label = streak_box["label"] as Label
	streak_label.name = "StreakLabel"
	stats.add_child(streak_box["panel"])

	die_panel = PanelContainer.new()
	die_panel.name = "CurrentDiePanel"
	die_panel.custom_minimum_size.y = 252
	die_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	die_panel.add_theme_stylebox_override("panel", _panel(Color("#171126"), Color("#7a5a31"), 16, 2))
	root.add_child(die_panel)
	var die_box := VBoxContainer.new()
	die_box.alignment = BoxContainer.ALIGNMENT_CENTER
	die_box.add_theme_constant_override("separation", 2)
	die_panel.add_child(die_box)
	var die_caption := _label("CURRENT FACE", 16, Color("#cfc4dc"))
	die_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	die_box.add_child(die_caption)
	var die_center := CenterContainer.new()
	die_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	die_box.add_child(die_center)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "HighLowDie3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(220, 190)
	die_center.add_child(dice_presentation)
	die_face_label = _label("?", 1, Color.TRANSPARENT)
	die_face_label.name = "DieFaceForTest"
	die_face_label.visible = false
	die_panel.add_child(die_face_label)

	var prompt := _label("次の目を選ぶ", 20, GOLD_LIGHT)
	prompt.name = "ChoicePrompt"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(prompt)
	var choices := HBoxContainer.new()
	choices.name = "ChoiceButtons"
	choices.add_theme_constant_override("separation", 6)
	root.add_child(choices)
	for choice: String in HighLowScript.CHOICES:
		var button := _button(choice.to_upper(), false)
		button.name = "%sChoiceButton" % choice.capitalize()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 110)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		choice_buttons[choice] = button
		choices.add_child(button)

	cashout_button = _button("CASH OUT", true)
	cashout_button.name = "CashOutButton"
	cashout_button.custom_minimum_size.y = 104
	cashout_button.add_theme_font_size_override("font_size", 22)
	cashout_button.pressed.connect(_on_cashout_pressed)
	root.add_child(cashout_button)

func _build_result(root: VBoxContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 26
	root.add_child(spacer)
	var card := PanelContainer.new()
	card.name = "ResultCard"
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color("#21162bf0"), GOLD, 18, 3))
	root.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	result_label = _label("RESULT", 32, GOLD_LIGHT)
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	result_payout_label = _label("0 CHIP", 42, CREAM)
	result_payout_label.name = "ResultPayoutLabel"
	result_payout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_payout_label)
	result_detail_label = _label("", 19, Color.WHITE)
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(result_detail_label)

	again_button = _button("もう一度 PLAY", true)
	again_button.name = "AgainButton"
	again_button.custom_minimum_size.y = 104
	again_button.add_theme_font_size_override("font_size", 23)
	again_button.pressed.connect(_show_setup)
	root.add_child(again_button)
	exit_button = _button("カジノへ戻る", false)
	exit_button.name = "ResultExitButton"
	exit_button.custom_minimum_size.y = 96
	exit_button.pressed.connect(_on_back_pressed)
	root.add_child(exit_button)

func _resume_or_show_setup() -> void:
	var active := CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		_show_setup()
		return
	game_id = str(active.get("game_id", ""))
	var session: Dictionary = active.get("session", {}) as Dictionary
	game = _normalise_game(session)
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

func _normalise_game(source: Dictionary) -> Dictionary:
	var candidate := source.duplicate(true)
	if candidate.has("game") and candidate["game"] is Dictionary:
		candidate = (candidate["game"] as Dictionary).duplicate(true)
	var bet := int(candidate.get("bet", selected_bet))
	var fresh := HighLowScript.new_game(bet, int(candidate.get("current", 0)))
	for key: Variant in candidate.keys():
		fresh[str(key)] = candidate[key]
	fresh["bet"] = bet
	fresh["pot"] = maxi(0, int(fresh.get("pot", bet)))
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
	var initial := _next_roll_value()
	var initial_game := HighLowScript.new_game(selected_bet, 0)
	initial_game["pending_rolls"] = [{"kind": "initial", "value": initial}]
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
	pending_roll = {"kind": "initial", "value": initial}
	settled = false
	rolling = true
	view_state = "rolling"
	setup_view.visible = false
	active_view.visible = true
	result_view.visible = false
	_play_ui_sfx(&"start", false)
	status_label.text = "CURRENTを決める..."
	_refresh_all()
	await _animate_roll(initial)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _on_choice_pressed(choice: String) -> void:
	if rolling or game.is_empty() or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var current := int(game.get("current", 0))
	if not HighLowScript.is_choice_available(current, choice):
		_play_ui_sfx(&"blocked", false)
		return
	var roll := _next_roll_value()
	pending_roll = {
		"kind": "choice",
		"choice": choice.strip_edges().to_lower(),
		"value": roll,
		"from_current": current,
	}
	game["pending_rolls"] = [pending_roll.duplicate(true)]
	# This write is deliberately before animation. A suspend/resume will use
	# this exact face instead of consuming the RNG a second time.
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	rolling = true
	view_state = "rolling"
	status_label.text = "ROLL中..."
	_refresh_all()
	await _animate_roll(roll)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)

func _resolve_pending_roll(pending: Dictionary) -> void:
	if pending.is_empty() or game.is_empty():
		return
	var kind := str(pending.get("kind", "choice"))
	var value := clampi(int(pending.get("value", 1)), 1, 6)
	if kind == "initial":
		game = HighLowScript.initialise_current(game, value)
		# CasinoBank merges session fields, so explicitly write an empty array
		# before removing the local helper key; otherwise a stale initial roll
		# would be replayed if the player later resumes the active run.
		game["pending_rolls"] = []
		pending_roll = {}
		rolling = false
		view_state = "active"
		status_label.text = "CURRENT %d。次の目を読む。" % int(game.get("current", 0))
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
		game.erase("pending_rolls")
		_refresh_all()
		return
	var choice := str(pending.get("choice", ""))
	game = HighLowScript.resolve_choice(game, choice, value)
	game["pending_rolls"] = []
	pending_roll = {}
	rolling = false
	if bool(game.get("finished", false)):
		_settle_finished_game()
	else:
		view_state = "active"
		status_label.text = "的中！ CURRENT %d。さらに続ける？" % int(game.get("current", 0))
		_play_ui_sfx(&"bonus", true)
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	game.erase("pending_rolls")
	_refresh_all()

func _on_cashout_pressed() -> void:
	if rolling or game.is_empty() or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var next := HighLowScript.cash_out(game)
	if next == game or int(next.get("payout", 0)) <= 0:
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
		"current": int(game.get("current", 0)),
		"streak": int(game.get("streak", 0)),
		"bet": int(game.get("bet", selected_bet)),
	}, game_id)
	if bool(receipt.get("already_settled", false)):
		payout = int(receipt.get("payout", payout))
		game["payout"] = payout
	settled = bool(receipt.get("ok", false)) or bool(receipt.get("already_settled", false))
	rolling = false
	view_state = "result"
	if str(game.get("result", "")) == "miss":
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
		"miss":
			result_label.text = "MISS"
			result_detail_label.text = "選んだレンジに入らなかった。POTは0 CHIP。"
		"auto_cash":
			result_label.text = "FIVE WIN STREAK!"
			result_detail_label.text = "5連勝達成。自動CASH OUTしました。"
		"cashout":
			result_label.text = "CASH OUT"
			result_detail_label.text = "勝ち分を確定して持ち帰った。"
		_:
			result_label.text = "RESULT"
			result_detail_label.text = "ゲーム終了。"
	result_payout_label.text = "%d CHIP" % int(game.get("payout", 0))
	status_label.text = "RESULTを確認。もう一度遊ぶ？"
	cashout_button.disabled = true
	_refresh_all()

func _show_setup() -> void:
	game = {}
	game_id = ""
	pending_roll = {}
	rolling = false
	settled = false
	view_state = "setup"
	setup_view.visible = true
	active_view.visible = false
	result_view.visible = false
	status_label.text = "BETを選んで、次の目を読む"
	_refresh_all()

func _on_back_pressed() -> void:
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

func _animate_roll(value: int) -> void:
	if not is_instance_valid(dice_presentation):
		await get_tree().create_timer(ROLL_SECONDS + SETTLE_SECONDS).timeout
		return
	var start := int(game.get("current", 1))
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
	chip_label.text = "CHIP  %d" % CasinoBankScript.balance()
	_refresh_bet_buttons()
	if game.is_empty():
		return
	current_label.text = str(int(game.get("current", 0))) if int(game.get("current", 0)) > 0 else "?"
	pot_label.text = "%d" % int(game.get("pot", 0))
	streak_label.text = "%d / %d" % [int(game.get("streak", 0)), HighLowScript.MAX_STREAK]
	_refresh_choice_buttons()
	var can_cash := bool(game.get("active", false)) and not bool(game.get("finished", false)) and int(game.get("streak", 0)) > 0 and not rolling
	cashout_button.disabled = not can_cash
	cashout_button.text = "CASH OUT\n%d CHIP" % int(game.get("pot", 0))

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

func _refresh_choice_buttons() -> void:
	var current := int(game.get("current", 0))
	var pot := int(game.get("pot", 0))
	for choice: String in HighLowScript.CHOICES:
		var button := choice_buttons[choice] as Button
		var faces := HighLowScript.winning_faces(current, choice)
		var range_text := _faces_text(faces)
		var multiplier := HighLowScript.multiplier_for(current, choice)
		var next_payout := HighLowScript.payout_for_pot(pot, current, choice)
		button.text = "%s\n%s  x%.1f\nNEXT %d CHIP" % [choice.to_upper(), range_text, multiplier, next_payout]
		button.disabled = rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)) or not HighLowScript.is_choice_available(current, choice)
		_apply_choice_style(button, choice, not button.disabled)

func _faces_text(faces: Array[int]) -> String:
	if faces.is_empty():
		return "—"
	if faces.size() == 1:
		return str(faces[0])
	return "%d–%d" % [faces[0], faces[faces.size() - 1]]

func _show_banner(text: String, color: Color, outline: Color) -> void:
	if effect_layer == null:
		return
	var banner := _label(text, 28, color)
	banner.name = "HighLowBanner"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_outline_color", outline)
	banner.add_theme_constant_override("outline_size", 7)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(banner)
	banner.size = Vector2(minf(340.0, effect_layer.size.x - 20.0), 58)
	banner.position = Vector2((effect_layer.size.x - banner.size.x) * 0.5, maxf(110.0, effect_layer.size.y * 0.24))
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.78, 0.78)
	banner.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.09)
	tween.chain().tween_interval(0.45)
	tween.chain().tween_property(banner, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(banner.queue_free)

func _spawn_confetti() -> void:
	if effect_layer == null:
		return
	for index: int in 18:
		var piece := ColorRect.new()
		piece.name = "ConfettiPiece"
		piece.size = Vector2(randf_range(4.0, 7.0), randf_range(7.0, 13.0))
		piece.color = [GOLD, GOLD_LIGHT, Color("#fff7df"), Color("#ffb46b")][index % 4]
		piece.rotation = randf_range(-PI, PI)
		piece.position = Vector2(randf_range(0.0, maxf(1.0, effect_layer.size.x)), -18.0)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(piece)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(piece, "position:y", effect_layer.size.y + 24.0, randf_range(0.9, 1.45))
		fall.tween_property(piece, "rotation", piece.rotation + randf_range(-3.0, 3.0), 1.1)
		fall.tween_property(piece, "modulate:a", 0.0, 0.30).set_delay(0.84)
		fall.chain().tween_callback(piece.queue_free)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
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

func _apply_choice_style(button: Button, choice: String, enabled: bool) -> void:
	var accent := GOLD if choice == "same" else (Color("#70b9ad") if choice == "low" else Color("#df7c6d"))
	if enabled:
		button.add_theme_stylebox_override("normal", _panel(Color("#33264d"), accent, 12, 3))
		button.add_theme_color_override("font_color", CREAM)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#3a3540"), Color("#6d6870"), 12, 1))
		button.add_theme_color_override("font_color", Color("#b8b1b4"))

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
