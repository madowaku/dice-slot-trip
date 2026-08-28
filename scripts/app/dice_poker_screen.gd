class_name DicePokerScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const DicePokerScript = preload("res://scripts/game/dice_poker_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const FACILITY_ID: String = "dice_poker"
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const ROLL_SECONDS: float = 0.28
const SETTLE_SECONDS: float = 0.12

const GOLD: Color = Color("#f2bf4c")
const GOLD_LIGHT: Color = Color("#ffe6a0")
const INK: Color = Color("#322315")
const CREAM: Color = Color("#fff0cf")
const NAVY: Color = Color("#171932")
const PLUM: Color = Color("#36213e")
const OXBLOOD: Color = Color("#7f282c")
const BRASS: Color = Color("#a67836")

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
var result_detail_label: Label
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
var effect_layer: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not suppress_audio_for_tests:
		var bgm: Node = get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_lasvegas_main")
		var ui_sfx: Node = get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	_build_ui()
	_resume_or_show_setup()

func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.name = "MidnightBackdrop"
	background.color = NAVY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var glow: ColorRect = ColorRect.new()
	glow.name = "PlumGlow"
	glow.color = PLUM
	glow.anchor_right = 1.0
	glow.anchor_bottom = 0.48
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var margins: MarginContainer = MarginContainer.new()
	margins.name = "SafeMargins"
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_right", 14)
	margins.add_theme_constant_override("margin_top", 12)
	margins.add_theme_constant_override("margin_bottom", 12)
	add_child(margins)

	var root: VBoxContainer = VBoxContainer.new()
	root.name = "DicePokerRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 7)
	margins.add_child(root)
	_build_header(root)
	_build_status(root)

	setup_view = VBoxContainer.new()
	setup_view.name = "DicePokerSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 8)
	root.add_child(setup_view)
	_build_setup(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "DicePokerActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 7)
	root.add_child(active_view)
	_build_active(active_view)

	result_view = VBoxContainer.new()
	result_view.name = "DicePokerResultView"
	result_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_view.add_theme_constant_override("separation", 8)
	root.add_child(result_view)
	_build_result(result_view)

	back_button = _button("EXIT", false)
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size.y = 96
	back_button.pressed.connect(_on_back_pressed)
	root.add_child(back_button)

	effect_layer = Control.new()
	effect_layer.name = "DicePokerEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 30
	add_child(effect_layer)

func _build_header(root: VBoxContainer) -> void:
	var header: PanelContainer = PanelContainer.new()
	header.name = "DicePokerHeader"
	header.custom_minimum_size.y = 64
	header.add_theme_stylebox_override("panel", _panel(OXBLOOD, GOLD, 20, 3))
	root.add_child(header)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	var title: Label = _label("DICE POKER", 34, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color("#4e1715"))
	title.add_theme_constant_override("outline_size", 5)
	row.add_child(title)
	var chip_panel: PanelContainer = PanelContainer.new()
	chip_panel.name = "ChipBalancePanel"
	chip_panel.custom_minimum_size.x = 138
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 14, 2))
	chip_label = _label("CHIP 0", 16, CREAM)
	chip_label.name = "ChipBalanceLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_status(root: VBoxContainer) -> void:
	status_label = _label("BETを選んで、5つのダイスをDEAL", 19, Color.WHITE)
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 40
	root.add_child(status_label)

func _build_setup(root: VBoxContainer) -> void:
	var rules_panel: PanelContainer = PanelContainer.new()
	rules_panel.name = "RulesPreview"
	rules_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_panel.custom_minimum_size.y = 256
	rules_panel.add_theme_stylebox_override("panel", _panel(Color("#21162be6"), GOLD, 18, 3))
	root.add_child(rules_panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	rules_panel.add_child(box)
	var title: Label = _label("MAKE YOUR HAND", 28, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var copy: Label = _label("DEALで5個を振り、KEEPを選択。最大2回REROLLできます。\n5個すべてKEEPしたらLOCK HANDで確定。", 18, CREAM)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(copy)
	var table: Label = _label("FIVE x2.8  ·  FOUR x1.7  ·  FULL HOUSE x1.0  ·  STRAIGHT x0.8", 15, GOLD_LIGHT)
	table.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(table)

	var caption: Label = _label("BET", 20, GOLD_LIGHT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(caption)
	var bet_row: HBoxContainer = HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bet_row.add_theme_constant_override("separation", 7)
	root.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button: Button = _button("%d CHIP" % amount)
		button.name = "Bet_%d" % amount
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	deal_button = _button("DEAL HAND", true)
	deal_button.name = "DealButton"
	deal_button.custom_minimum_size.y = 104
	deal_button.add_theme_font_size_override("font_size", 26)
	deal_button.pressed.connect(_start_game)
	start_button = deal_button
	root.add_child(deal_button)

func _build_active(root: VBoxContainer) -> void:
	var stats: HBoxContainer = HBoxContainer.new()
	stats.name = "DicePokerStats"
	stats.add_theme_constant_override("separation", 5)
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
	dice_panel.custom_minimum_size.y = 286
	dice_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dice_panel.add_theme_stylebox_override("panel", _panel(Color("#171126"), BRASS, 16, 2))
	root.add_child(dice_panel)
	var dice_box: VBoxContainer = VBoxContainer.new()
	dice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_box.add_theme_constant_override("separation", 2)
	dice_panel.add_child(dice_box)
	var dice_caption: Label = _label("FIVE DICE · TAP TO KEEP", 16, Color("#cfc4dc"))
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
	dice_presentation.custom_minimum_size = Vector2(0, 224)
	die_center.add_child(dice_presentation)

	var keep_grid: GridContainer = GridContainer.new()
	keep_grid.name = "KeepButtons"
	keep_grid.columns = DicePokerScript.DIE_COUNT
	keep_grid.add_theme_constant_override("h_separation", 5)
	keep_grid.add_theme_constant_override("v_separation", 5)
	root.add_child(keep_grid)
	for index: int in range(DicePokerScript.DIE_COUNT):
		var keep_button: Button = _button("DIE %d\nKEEP" % (index + 1))
		keep_button.name = "KeepDie_%d" % (index + 1)
		keep_button.custom_minimum_size = Vector2(0, 104)
		keep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		keep_button.add_theme_font_size_override("font_size", 15)
		keep_button.pressed.connect(_on_keep_pressed.bind(index))
		keep_buttons[index] = keep_button
		keep_grid.add_child(keep_button)
	dice_buttons = keep_buttons

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.add_theme_constant_override("separation", 7)
	root.add_child(action_row)
	reroll_button = _button("REROLL", true)
	reroll_button.name = "RerollButton"
	reroll_button.custom_minimum_size.y = 108
	reroll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll_button.add_theme_font_size_override("font_size", 21)
	reroll_button.pressed.connect(_on_reroll_pressed)
	action_row.add_child(reroll_button)
	lock_button = _button("LOCK HAND", true)
	lock_button.name = "LockHandButton"
	lock_button.custom_minimum_size.y = 108
	lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_button.add_theme_font_size_override("font_size", 21)
	lock_button.pressed.connect(_on_lock_pressed)
	action_row.add_child(lock_button)
	action_button = reroll_button

	var paytable: PanelContainer = PanelContainer.new()
	paytable.name = "CompactPaytable"
	paytable.custom_minimum_size.y = 76
	paytable.add_theme_stylebox_override("panel", _panel(Color("#21162b"), Color("#705e84"), 12, 1))
	var paytable_label: Label = _label("PAYTABLE  FIVE 2.8x  ·  FOUR 1.7x  ·  FULL HOUSE 1.0x  ·  STRAIGHT 0.8x  ·  THREE 0.6x  ·  TWO PAIR 0.4x  ·  ONE PAIR 0.2x", 13, CREAM)
	paytable_label.name = "PaytableLabel"
	paytable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paytable_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	paytable_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paytable.add_child(paytable_label)
	root.add_child(paytable)

func _build_result(root: VBoxContainer) -> void:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = 16
	root.add_child(spacer)
	var card: PanelContainer = PanelContainer.new()
	card.name = "ResultCard"
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color("#21162bf0"), GOLD, 18, 3))
	root.add_child(card)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	result_label = _label("RESULT", 34, GOLD_LIGHT)
	result_label.name = "ResultRankLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	result_payout_label = _label("0 CHIP", 42, CREAM)
	result_payout_label.name = "ResultPayoutLabel"
	result_payout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_payout_label)
	result_detail_label = _label("", 18, Color.WHITE)
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(result_detail_label)

	again_button = _button("AGAIN", true)
	again_button.name = "AgainButton"
	again_button.custom_minimum_size.y = 104
	again_button.add_theme_font_size_override("font_size", 23)
	again_button.pressed.connect(_on_again_pressed)
	root.add_child(again_button)
	change_bet_button = _button("CHANGE BET", false)
	change_bet_button.name = "ChangeBetButton"
	change_bet_button.custom_minimum_size.y = 96
	change_bet_button.pressed.connect(_on_change_bet_pressed)
	root.add_child(change_bet_button)
	exit_button = _button("EXIT", false)
	exit_button.name = "ResultExitButton"
	exit_button.custom_minimum_size.y = 96
	exit_button.pressed.connect(_on_back_pressed)
	root.add_child(exit_button)

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
	var rank_name: String = str(game.get("rank", game.get("result", DicePokerScript.RANK_NO_HAND)))
	result_label.text = rank_name
	result_payout_label.text = "%d CHIP" % int(game.get("payout", 0))
	result_detail_label.text = "%s · x%.1f return\nBET %d CHIP" % [rank_name, float(game.get("multiplier", DicePokerScript.multiplier_for(rank_name))), int(game.get("bet", selected_bet))]
	status_label.text = "RESULTを確認。AGAINで同じBETを続ける。"
	back_button.disabled = false
	_refresh_bet_buttons()

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
	status_label.text = "BETを選んで、5つのダイスをDEAL"
	back_button.disabled = false
	_refresh_all()

func _on_back_pressed() -> void:
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

func _animate_roll(full_values: Array[int], _indices: Array[int]) -> void:
	if dice_presentation == null or not dice_presentation.is_node_ready() or dice_presentation.dice_roots.size() < DicePokerScript.DIE_COUNT:
		await get_tree().create_timer(ROLL_SECONDS + SETTLE_SECONDS).timeout
		return
	var start_values: Array[int] = _state_dice(game)
	for index: int in range(start_values.size()):
		if start_values[index] < 1 or start_values[index] > 6:
			start_values[index] = 1
	dice_presentation.present(start_values, true, 0)
	await get_tree().create_timer(ROLL_SECONDS).timeout
	if not is_inside_tree():
		return
	dice_presentation.present(full_values, false, 0)
	await get_tree().create_timer(SETTLE_SECONDS).timeout

func _refresh_all() -> void:
	if chip_label != null:
		chip_label.text = "CHIP  %d" % CasinoBankScript.balance()
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
		var keep_text: String = "KEEP" if (index < kept.size() and kept[index]) else "OPEN"
		button.text = "DIE %d\n%s\n%s" % [index + 1, str(face) if face > 0 else "?", keep_text]
		button.disabled = rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)) or face <= 0
		_apply_keep_style(button, index < kept.size() and kept[index])
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
	reroll_button.text = "REROLL\n%d LEFT" % DicePokerScript.remaining_rerolls(game)
	lock_button.text = "LOCK HAND\nFINALIZE"
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
		button.text = ("● " if amount == selected_bet else "") + "%d CHIP" % amount
		_apply_button_state(button, amount == selected_bet)
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
	if selected:
		button.add_theme_stylebox_override("normal", _panel(Color("#f7df9a"), GOLD, 12, 3))
		button.add_theme_color_override("font_color", INK)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#403452"), Color("#705e84"), 12, 2))
		button.add_theme_color_override("font_color", CREAM)

func _apply_button_state(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_stylebox_override("normal", _panel(Color("#f7df9a"), GOLD, 12, 3))
		button.add_theme_color_override("font_color", INK)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#403452"), Color("#705e84"), 12, 2))
		button.add_theme_color_override("font_color", Color("#fff4dc"))

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx: Node = get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)

func _stat_box(caption: String) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6d995"), Color("#a96b2e"), 12, 2))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var cap: Label = _label(caption, 12, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value: Label = _label("-", 18, INK)
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

func _button(text: String, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.custom_minimum_size = Vector2(90, 96)
	button.add_theme_color_override("font_color", INK if primary else Color("#fff4dc"))
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#d8d0bf"))
	button.add_theme_stylebox_override("normal", _panel(GOLD if primary else Color("#403452"), BRASS if primary else Color("#705e84"), 12, 2))
	button.add_theme_stylebox_override("hover", _panel(GOLD_LIGHT if primary else Color("#51436a"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel(Color("#d99d2c") if primary else Color("#302641"), GOLD, 12, 2))
	button.add_theme_stylebox_override("disabled", _panel(Color("#514c45"), Color("#766d5f"), 12, 1))
	return button

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
