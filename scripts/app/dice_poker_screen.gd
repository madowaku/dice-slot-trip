class_name DicePokerScreen
extends Control

## DICE POKER on the shared casino table.
##
## Five large dice sit on the felt. Tap a die to keep it, re-roll the rest up
## to twice, then take the hand. The screen never shows the whole pay table
## during play: one line says which hand you hold now and what it returns.
##
## Rules live in DicePokerModel and chips in CasinoBank. Every roll is saved
## with its already-decided faces before any animation, so an interrupted
## round resumes on the same dice.

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const DicePokerScript = preload("res://scripts/game/dice_poker_model.gd")
const ShellScript = preload("res://scripts/ui/casino_table_shell.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const CasinoFeelFXScript = preload("res://scripts/ui/casino_feel_fx.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const FACILITY_ID: String = "dice_poker"
const TITLE: String = "DICE POKER"
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const ROLL_SECONDS: float = 0.8
const SETTLE_SECONDS: float = 0.3
const KEEP_LIFT: float = 0.45
const GOLD: Color = Color("#f2bf4c")
const GOLD_BRIGHT: Color = Color("#ffe6a0")
const CREAM: Color = Color("#fff4d6")
const RANK_NAMES: Dictionary = {
	DicePokerScript.RANK_FIVE: "ファイブ",
	DicePokerScript.RANK_FOUR: "フォー",
	DicePokerScript.RANK_FULL_HOUSE: "フルハウス",
	DicePokerScript.RANK_STRAIGHT: "ストレート",
	DicePokerScript.RANK_THREE: "スリー",
	DicePokerScript.RANK_TWO_PAIR: "ツーペア",
	DicePokerScript.RANK_ONE_PAIR: "ワンペア",
	DicePokerScript.RANK_NO_HAND: "役なし",
}

static var suppress_audio_for_tests: bool = false
## Tests skip every roll timer so a round resolves without waiting.
static var instant_for_tests: bool = false

var game: Dictionary = {}
var game_id: String = ""
var selected_bet: int = 20
var rolling: bool = false
var presentation_locked: bool = false
var exiting: bool = false
var settled: bool = false
var rng_seed: int = 0
var queued_roll_batch: Array = []
var queued_roll_values: Array = []
var queued_reroll_values: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var pending_roll: Dictionary = {}
## "setup" | "rolling" | "active" | "result"
var view_state: String = "setup"

var shell: Control
var dice_presentation: DicePresentation3D
var hint_label: Label
var keep_buttons: Dictionary = {}
var keep_tags: Dictionary = {}
var lock_button: Button
var casino_feel_fx: CasinoFeelFX

# Aliases onto the shell so the cross-facility QA tours can drive this table
# the same way they drive the others.
var deal_button: Button
var reroll_button: Button
var back_button: Button
var result_view: Control
var bet_buttons: Dictionary:
	get:
		return shell.bet_buttons if shell != null else {}


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
	casino_feel_fx = CasinoFeelFXScript.new()
	casino_feel_fx.name = "DicePokerFeelFX"
	casino_feel_fx.audio_enabled = not suppress_audio_for_tests
	add_child(casino_feel_fx)
	_build()
	_resume_or_show_setup()
	if view_state == "setup":
		shell.show_guide_if_first_time()


func _exit_tree() -> void:
	exiting = true


# ------------------------------------------------------------------ build

func _build() -> void:
	shell = ShellScript.new()
	add_child(shell)
	shell.configure(FACILITY_ID, TITLE)
	var steps: Array[String] = [
		"賭け金を選んで、5つのダイスを配る",
		"残したいダイスをタップしてキープ。残りは2回まで振り直せる",
		"そろえた役のぶんだけチップが戻る",
	]
	shell.set_guide("DICE POKER の遊び方", steps)
	shell.set_guide_reference(_reference_text(selected_bet))
	shell.back_requested.connect(_on_back_pressed)
	shell.primary_pressed.connect(_on_primary_pressed)
	shell.bet_selected.connect(_select_bet)
	deal_button = shell.primary_button
	reroll_button = shell.primary_button
	back_button = shell.back_button
	result_view = shell.result_panel

	lock_button = shell.add_action("lock", "この役で受け取る")
	lock_button.pressed.connect(_on_lock_pressed)
	lock_button.visible = false
	shell.choice_row.visible = false

	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "PokerDice3D"
	dice_presentation.overlay_compact = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	shell.table_root.add_child(dice_presentation)
	# Straight down, so each die shows exactly one number: the one that counts.
	dice_presentation.camera.fov = 30.0
	dice_presentation.camera.look_at_from_position(Vector3(0, 10.8, 1.6), Vector3(0, 0.7, 0.1))

	for index: int in range(DicePokerScript.DIE_COUNT):
		var button := Button.new()
		button.name = "KeepButton_%d" % index
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(UiTokensScript.TOUCH_MIN, UiTokensScript.TOUCH_MIN)
		button.tooltip_text = "ダイス%dをキープ" % (index + 1)
		_style_keep_button(button)
		button.pressed.connect(_on_keep_pressed.bind(index))
		shell.table_root.add_child(button)
		keep_buttons[index] = button
		var tag := Label.new()
		tag.text = "キープ"
		tag.add_theme_font_override("font", FONT)
		tag.add_theme_font_size_override("font_size", 24)
		tag.add_theme_color_override("font_color", Color("#2a1a0c"))
		tag.add_theme_stylebox_override("normal", ShellScript._box(GOLD, GOLD_BRIGHT, 12, 0, 4))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.visible = false
		shell.table_root.add_child(tag)
		keep_tags[index] = tag

	hint_label = Label.new()
	hint_label.name = "TableHint"
	hint_label.add_theme_font_override("font", FONT)
	hint_label.add_theme_font_size_override("font_size", UiTokensScript.FONT_CAPTION)
	hint_label.add_theme_color_override("font_color", CREAM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.table_root.add_child(hint_label)

	shell.table_root.move_child(shell.result_panel, -1)
	shell.table_root.resized.connect(_layout_table)
	_layout_table()


func _style_keep_button(button: Button) -> void:
	var clear := StyleBoxEmpty.new()
	var kept := ShellScript._box(Color(1.0, 0.84, 0.36, 0.10), GOLD, 26, 6, 0)
	button.add_theme_stylebox_override("normal", clear)
	button.add_theme_stylebox_override("hover", ShellScript._box(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.35), 26, 2, 0))
	button.add_theme_stylebox_override("pressed", kept)
	button.add_theme_stylebox_override("hover_pressed", kept)
	button.add_theme_stylebox_override("disabled", clear)
	button.add_theme_stylebox_override("focus", ShellScript._box(Color.TRANSPARENT, GOLD_BRIGHT, 26, 2, 0))


func _dice_box() -> Rect2:
	var area: Vector2 = shell.table_root.size
	var width := clampf(area.x - 16.0, 120.0, 660.0)
	var height := minf(width * 0.68, maxf(120.0, area.y - 150.0))
	return Rect2(Vector2((area.x - width) * 0.5, area.y * 0.52 - height * 0.5), Vector2(width, height))


func _layout_table() -> void:
	var area: Vector2 = shell.table_root.size
	if area.x < 8.0 or area.y < 8.0:
		return
	var box := _dice_box()
	dice_presentation.position = box.position
	dice_presentation.size = box.size
	hint_label.position = Vector2(0, minf(area.y - 56.0, box.end.y + 6.0))
	hint_label.size = Vector2(area.x, 44)
	_place_keep_buttons()


## Put each tap target over its die. Projection goes through the dice camera
## so the buttons stay aligned at every screen size.
func _place_keep_buttons() -> void:
	var box := _dice_box()
	var layout := DicePresentationScript.layout_for_count(DicePokerScript.DIE_COUNT)
	var viewport_size := Vector2(dice_presentation.viewport.size) if dice_presentation.viewport != null else box.size
	var side := maxf(float(UiTokensScript.TOUCH_MIN), box.size.x * 0.235)
	var kept: Array[bool] = _state_kept(game)
	for index: int in range(DicePokerScript.DIE_COUNT):
		var lifted := kept[index] and view_state == "active"
		var center := Vector2(box.size.x * (0.5 + layout[index].x / 7.2), box.size.y * (0.5 + layout[index].z / 4.9))
		if dice_presentation.is_inside_tree() and viewport_size.x > 8.0 and viewport_size.y > 8.0:
			var projected := dice_presentation.camera.unproject_position(Vector3(layout[index].x, 1.7 + (KEEP_LIFT if lifted else 0.0), layout[index].z))
			center = projected / viewport_size * box.size
		var button := keep_buttons[index] as Button
		button.position = box.position + center - Vector2(side, side) * 0.5
		button.size = Vector2(side, side)
		var tag := keep_tags[index] as Label
		tag.size = Vector2(112, 38)
		tag.position = button.position + Vector2((side - 112.0) * 0.5, -22.0)


func _reference_text(bet: int) -> String:
	var parts: Array[String] = []
	for rank_name: String in DicePokerScript.RANKS_HIGH_TO_LOW:
		if rank_name == DicePokerScript.RANK_NO_HAND:
			continue
		parts.append("%s +%d" % [RANK_NAMES[rank_name], DicePokerScript.payout_for(bet, rank_name)])
	return "賭け金 %d のとき戻るチップ\n%s" % [bet, " ・ ".join(parts)]


func rank_name_ja(rank_name: String) -> String:
	return str(RANK_NAMES.get(rank_name, rank_name))


# ------------------------------------------------------------------ resume

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
		_refresh_all()
		call_deferred("_resume_pending_roll")
	elif bool(game.get("finished", false)):
		_settle_finished_game()
	else:
		view_state = "active"
		rolling = false
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
	if pending_roll.is_empty() or exiting or not is_inside_tree():
		return
	presentation_locked = true
	var values: Array[int] = _pending_full_values(pending_roll)
	await _animate_roll(values, _pending_indices(pending_roll))
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)


# ------------------------------------------------------------------ inputs

func _select_bet(amount: int) -> void:
	if amount not in BET_AMOUNTS or rolling or presentation_locked:
		return
	if view_state == "active":
		return
	selected_bet = amount
	if view_state == "result":
		_show_setup(true)
	else:
		_refresh_all()


func _on_primary_pressed() -> void:
	match view_state:
		"setup":
			_start_game()
		"active":
			_on_reroll_pressed()
		"result":
			_on_again_pressed()


func _on_back_pressed() -> void:
	if exiting:
		return
	if rolling or presentation_locked:
		shell.set_status("ダイスが止まるまで少し待とう")
		return
	# A round in progress is saved and resumes on the same dice next time.
	back_requested.emit()


func _toggle_help() -> void:
	if shell.is_guide_open():
		shell.close_guide()
	else:
		shell.open_guide()


func _start_game() -> void:
	if rolling or presentation_locked or shell.is_guide_open() or selected_bet not in BET_AMOUNTS:
		return
	if CasinoBankScript.balance() < selected_bet:
		shell.set_status("チップが足りない。賭け金を選び直そう")
		_refresh_all()
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
			shell.set_status("いまは始められない。チップを確認しよう")
			_refresh_all()
		return
	game_id = str(receipt.get("game_id", ""))
	game = initial_game.duplicate(true)
	pending_roll = pending.duplicate(true)
	settled = false
	rolling = true
	presentation_locked = true
	view_state = "rolling"
	casino_feel_fx.press_button(shell.primary_button, true)
	_refresh_all()
	await _animate_roll(initial, indices)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)


func _on_keep_pressed(die_index: int) -> void:
	if rolling or presentation_locked or game.is_empty() or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		_refresh_dice()
		return
	game = DicePokerScript.toggle_keep(game, die_index)
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	casino_feel_fx.press_button(null, true)
	_refresh_all()


func _on_reroll_pressed() -> void:
	if rolling or presentation_locked or game.is_empty():
		return
	if DicePokerScript.all_kept(game) or not DicePokerScript.can_reroll(game):
		_on_lock_pressed()
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
	presentation_locked = true
	view_state = "rolling"
	casino_feel_fx.press_button(shell.primary_button, true)
	_refresh_all()
	await _animate_roll(full_values, indices)
	if not is_inside_tree():
		return
	_resolve_pending_roll(pending_roll)


func _on_lock_pressed() -> void:
	# Taking the hand as it stands is the same as keeping every die.
	if rolling or presentation_locked or game.is_empty() or not DicePokerScript.can_finalize(game) or not bool(game.get("active", false)):
		return
	game = DicePokerScript.finalize(game)
	_settle_finished_game()


func _on_again_pressed() -> void:
	if exiting or rolling or presentation_locked or view_state != "result":
		return
	_show_setup(true)
	_start_game()


func _resolve_pending_roll(pending: Dictionary) -> void:
	if exiting or not is_inside_tree() or pending.is_empty() or game.is_empty():
		return
	var kind: String = str(pending.get("kind", "reroll"))
	var full_values: Array[int] = _pending_full_values(pending)
	if kind == "initial":
		game = DicePokerScript.apply_initial(game, full_values)
	else:
		game = DicePokerScript.apply_reroll(game, _pending_values(pending), _pending_indices(pending))
	game["pending_rolls"] = []
	pending_roll = {}
	rolling = false
	presentation_locked = false
	if bool(game.get("finished", false)):
		game.erase("pending_rolls")
		_settle_finished_game()
		return
	view_state = "active"
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	game.erase("pending_rolls")
	_refresh_all()


func _settle_finished_game() -> void:
	var payout_value: int = maxi(0, int(game.get("payout", 0)))
	if not settled:
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
	presentation_locked = false
	view_state = "result"
	var bet: int = int(game.get("bet", selected_bet))
	var rank_name: String = str(game.get("rank", DicePokerScript.RANK_NO_HAND))
	var headline := rank_name_ja(rank_name) if payout_value <= 0 else "%s  +%d" % [rank_name_ja(rank_name), payout_value]
	shell.show_result(payout_value > bet, headline, "賭け金 %d ・ 受け取り %d" % [bet, payout_value])
	if payout_value > bet:
		casino_feel_fx.play_win_feedback()
	elif payout_value < bet:
		casino_feel_fx.play_lose_feedback()
	_refresh_all()
	shell.set_balance(CasinoBankScript.balance(), not instant_for_tests)


func _show_setup(reset_game: bool = true) -> void:
	if reset_game:
		game = {}
		game_id = ""
		pending_roll = {}
		rolling = false
		presentation_locked = false
		settled = false
	view_state = "setup"
	shell.clear_result()
	_refresh_all()


# ----------------------------------------------------------------- refresh

func _refresh_all() -> void:
	var balance := CasinoBankScript.balance()
	if view_state != "result":
		shell.set_balance(balance)
	var locked := rolling or presentation_locked
	shell.back_button.disabled = locked
	shell.help_button.disabled = locked
	_refresh_dice()
	match view_state:
		"setup":
			if selected_bet > balance:
				for amount: int in [50, 20, 10]:
					if amount <= balance:
						selected_bet = amount
						break
			var amounts: Array[int] = BET_AMOUNTS.duplicate()
			shell.set_bets(amounts, selected_bet, balance)
			shell.set_guide_reference(_reference_text(selected_bet if selected_bet in BET_AMOUNTS else 20))
			lock_button.visible = false
			shell.choice_row.visible = false
			var can_afford := balance >= selected_bet and selected_bet in BET_AMOUNTS
			shell.set_status("5つのダイスで役をつくる。賭け金を選ぼう" if can_afford else "チップが足りない。旅でチップを集めよう")
			shell.set_primary("ダイスを配る", can_afford)
			hint_label.text = ""
		"rolling":
			shell.bet_row.visible = false
			lock_button.visible = false
			shell.choice_row.visible = false
			shell.set_status("ダイスを振っている…")
			shell.set_primary("…", false)
			hint_label.text = ""
		"active":
			shell.bet_row.visible = false
			var rank_name: String = str(game.get("rank", DicePokerScript.RANK_NO_HAND))
			var payout_now: int = DicePokerScript.payout_for(int(game.get("bet", selected_bet)), rank_name)
			shell.set_status("いまの役：%s　受け取り +%d" % [rank_name_ja(rank_name), payout_now])
			var remaining: int = DicePokerScript.remaining_rerolls(game)
			var must_take := DicePokerScript.all_kept(game) or not DicePokerScript.can_reroll(game)
			if must_take:
				lock_button.visible = false
				shell.choice_row.visible = false
				shell.set_primary("この役で受け取る", true)
				hint_label.text = "全部キープ中。外すならダイスをタップ" if remaining > 0 else ""
			else:
				lock_button.visible = true
				shell.choice_row.visible = true
				shell.set_primary("振り直す（あと%d回）" % remaining, true)
				hint_label.text = "残したいダイスをタップ"
		"result":
			lock_button.visible = false
			shell.choice_row.visible = false
			var amounts: Array[int] = BET_AMOUNTS.duplicate()
			shell.set_bets(amounts, selected_bet, balance)
			shell.set_status("賭け金を変えるなら、下から選び直せる")
			shell.set_primary("もう一度（賭け金 %d）" % selected_bet, balance >= selected_bet)
			hint_label.text = ""


func _refresh_dice() -> void:
	var faces: Array[int] = _state_dice(game)
	var has_hand: bool = faces.size() == DicePokerScript.DIE_COUNT and int(faces.min()) >= 1
	var kept: Array[bool] = _state_kept(game)
	var can_keep := view_state == "active" and not rolling and not presentation_locked
	dice_presentation.visible = has_hand or view_state == "rolling"
	if has_hand and not rolling:
		dice_presentation.present(faces, false, DicePokerScript.DIE_COUNT)
		# Kept dice rise off the felt toward the camera.
		for index: int in range(DicePokerScript.DIE_COUNT):
			if kept[index] and view_state == "active":
				dice_presentation.base_positions[index].y += KEEP_LIFT
	for index: int in range(DicePokerScript.DIE_COUNT):
		var button := keep_buttons[index] as Button
		var is_kept: bool = has_hand and kept[index] and view_state in ["active", "rolling"]
		button.set_pressed_no_signal(is_kept)
		button.visible = has_hand and view_state in ["active", "rolling"]
		button.mouse_filter = Control.MOUSE_FILTER_STOP if can_keep else Control.MOUSE_FILTER_IGNORE
		(keep_tags[index] as Label).visible = is_kept
	_place_keep_buttons()


# -------------------------------------------------------------- animation

func _animate_roll(full_values: Array[int], indices: Array[int]) -> void:
	if exiting or not is_inside_tree():
		return
	var start_values: Array[int] = _state_dice(game)
	while start_values.size() < DicePokerScript.DIE_COUNT:
		start_values.append(1)
	for index: int in range(DicePokerScript.DIE_COUNT):
		if start_values[index] < 1 or start_values[index] > 6:
			start_values[index] = 1
	dice_presentation.visible = true
	if instant_for_tests:
		dice_presentation.present(full_values, false, DicePokerScript.DIE_COUNT)
		return
	casino_feel_fx.play_dice_roll()
	# Roll only the dice that were not kept; the others hold their face.
	dice_presentation.present(start_values, true, 0)
	for index: int in range(DicePokerScript.DIE_COUNT):
		if index not in indices:
			dice_presentation.die_states[index] = DicePresentationScript.DieState.LOCKED
			dice_presentation.face_values[index] = start_values[index]
	await get_tree().create_timer(ROLL_SECONDS).timeout
	if exiting or not is_inside_tree():
		return
	dice_presentation.present(full_values, false, DicePokerScript.DIE_COUNT)
	casino_feel_fx.play_dice_land()
	await get_tree().create_timer(SETTLE_SECONDS).timeout


# ------------------------------------------------------------ roll source

func _next_roll_batch(indices: Array[int]) -> Array[int]:
	var result: Array[int] = []
	var queued: Array[int] = _consume_queued_batch()
	for offset: int in range(indices.size()):
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
