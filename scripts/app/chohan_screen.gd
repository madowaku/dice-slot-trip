extends Control

## 丁半 — the casino's front door. Pick a wager, call 丁 (even) or 半 (odd),
## shake the cup. Two dice decide it; a correct call returns the wager doubled.
##
## Rules live in ChohanModel, chips in CasinoBank, the frame in
## CasinoTableShell. This script only sequences one round and its reveal.

signal back_requested

const ModelScript = preload("res://scripts/game/chohan_model.gd")
const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const ShellScript = preload("res://scripts/ui/casino_table_shell.gd")
const CupViewScript = preload("res://scripts/ui/chohan_cup_view.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const CasinoFeelFXScript = preload("res://scripts/ui/casino_feel_fx.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const FACILITY_ID := ModelScript.FACILITY_ID
const TITLE := "丁半"
const DEFAULT_BET := 20
const DICE_BOX := Vector2(440, 440)
const CUP_SIZE := Vector2(470, 340)
const CUP_LIFT := 330.0

enum State { CHOOSING, ROLLING, RESULT }

## Tests skip every tween/timer so a round resolves in the same frame.
static var instant_for_tests := false
static var suppress_audio_for_tests := false

var shell: Control
var dice_presentation: DicePresentation3D
var cup: Control
var total_label: Label
var cho_button: Button
var han_button: Button
var feel_fx: CasinoFeelFX

var state: State = State.CHOOSING
var selected_bet := DEFAULT_BET
var choice := ""
var last_result: Dictionary = {}
var rng: RandomNumberGenerator
## Set before a round to pin its dice (tests and recorders only).
var queued_dice: Array[int] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng = ModelScript.make_rng()
	feel_fx = CasinoFeelFXScript.new()
	feel_fx.name = "CasinoFeelFX"
	feel_fx.audio_enabled = not suppress_audio_for_tests
	add_child(feel_fx)
	_build()
	shell.set_balance(CasinoBankScript.balance())
	if CasinoBankScript.has_active_game(FACILITY_ID):
		_resume_active_round()
	else:
		_enter_choosing()
		shell.show_guide_if_first_time()


func set_rng_seed(seed_value: int) -> void:
	rng = ModelScript.make_rng(seed_value)


func _build() -> void:
	shell = ShellScript.new()
	add_child(shell)
	shell.configure(FACILITY_ID, TITLE)
	var steps: Array[String] = [
		"賭け金を選ぶ",
		"丁（偶数）か半（奇数）を選ぶ",
		"壺を振る。2つの合計が当たれば賭け金が2倍で戻る",
	]
	shell.set_guide("丁半の遊び方", steps)
	shell.back_requested.connect(_on_back_pressed)
	shell.primary_pressed.connect(_on_primary_pressed)
	shell.bet_selected.connect(_on_bet_selected)

	cho_button = shell.add_choice(ModelScript.CHOICE_CHO, "丁\n合計が偶数")
	han_button = shell.add_choice(ModelScript.CHOICE_HAN, "半\n合計が奇数")
	cho_button.pressed.connect(_on_choice_pressed.bind(ModelScript.CHOICE_CHO))
	han_button.pressed.connect(_on_choice_pressed.bind(ModelScript.CHOICE_HAN))

	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "ChohanDice3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.size = DICE_BOX
	dice_presentation.visible = false
	shell.table_root.add_child(dice_presentation)

	cup = CupViewScript.new()
	cup.name = "ChohanCup"
	cup.size = CUP_SIZE
	shell.table_root.add_child(cup)

	total_label = Label.new()
	total_label.name = "TotalLabel"
	total_label.add_theme_font_override("font", FONT)
	total_label.add_theme_font_size_override("font_size", UiTokensScript.FONT_TITLE)
	total_label.add_theme_color_override("font_color", Color("#fff4d6"))
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.table_root.add_child(total_label)

	# Keep the result banner above the dice and cup.
	shell.table_root.move_child(shell.result_panel, -1)
	shell.table_root.resized.connect(_layout_table)
	_layout_table()


func _table_center() -> Vector2:
	var area: Vector2 = shell.table_root.size
	return Vector2(area.x * 0.5, area.y * 0.54)


func _cup_rest_position() -> Vector2:
	return _table_center() - Vector2(CUP_SIZE.x * 0.5, CUP_SIZE.y * 0.56)


func _layout_table() -> void:
	var area: Vector2 = shell.table_root.size
	if area.x < 8.0 or area.y < 8.0:
		return
	var center := _table_center()
	dice_presentation.position = center - DICE_BOX * 0.5
	dice_presentation.size = DICE_BOX
	cup.size = CUP_SIZE
	var rest := _cup_rest_position()
	cup.position = rest
	total_label.position = Vector2(0, minf(area.y - 76.0, center.y + 150.0))
	total_label.size = Vector2(area.x, 60)


# ------------------------------------------------------------------ state

func _enter_choosing() -> void:
	state = State.CHOOSING
	last_result = {}
	shell.clear_result()
	dice_presentation.visible = false
	total_label.text = ""
	cup.rotation = 0.0
	cup.modulate.a = 1.0
	cup.visible = true
	cup.position = _cup_rest_position()
	var balance := CasinoBankScript.balance()
	shell.set_balance(balance)
	selected_bet = _affordable_bet(selected_bet, balance)
	var amounts: Array[int] = ModelScript.BET_AMOUNTS.duplicate()
	shell.set_bets(amounts, selected_bet, balance)
	_set_inputs_locked(false)
	_refresh_choosing()


func _affordable_bet(preferred: int, balance: int) -> int:
	if preferred in ModelScript.BET_AMOUNTS and preferred <= balance:
		return preferred
	var best := 0
	for amount: int in ModelScript.BET_AMOUNTS:
		if amount <= balance:
			best = maxi(best, amount)
	return best


func _refresh_choosing() -> void:
	cho_button.set_pressed_no_signal(choice == ModelScript.CHOICE_CHO)
	han_button.set_pressed_no_signal(choice == ModelScript.CHOICE_HAN)
	if selected_bet <= 0:
		cho_button.disabled = true
		han_button.disabled = true
		shell.set_status("チップが足りない。旅でチップを集めよう")
		shell.set_primary("壺を振る", false)
		return
	cho_button.disabled = false
	han_button.disabled = false
	if not ModelScript.is_valid_choice(choice):
		shell.set_status("丁か半か、当てるだけ。どちらかを選ぼう")
		shell.set_primary("壺を振る", false)
		return
	shell.set_status("%s（%s）に %d チップ。当たると +%d" % [
		ModelScript.choice_name(choice),
		ModelScript.choice_caption(choice),
		selected_bet,
		ModelScript.win_payout(selected_bet),
	])
	shell.set_primary("壺を振る", true)


func _set_inputs_locked(locked: bool) -> void:
	shell.refresh_bets(CasinoBankScript.balance(), locked)
	var filter := Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
	cho_button.mouse_filter = filter
	han_button.mouse_filter = filter
	shell.back_button.disabled = locked
	shell.help_button.disabled = locked


# ----------------------------------------------------------------- inputs

func _on_back_pressed() -> void:
	if state == State.ROLLING:
		return
	back_requested.emit()


func _on_bet_selected(amount: int) -> void:
	if state == State.ROLLING:
		return
	selected_bet = amount
	if state == State.RESULT:
		_enter_choosing()
	else:
		_refresh_choosing()


func _on_choice_pressed(new_choice: String) -> void:
	if state == State.ROLLING:
		return
	choice = new_choice
	feel_fx.press_button()
	if state == State.RESULT:
		# Calling the next round straight from the result saves a tap.
		_enter_choosing()
	else:
		_refresh_choosing()


func _on_primary_pressed() -> void:
	match state:
		State.CHOOSING:
			_start_round()
		State.RESULT:
			choice = ""
			_enter_choosing()


# ------------------------------------------------------------------ round

func _start_round() -> void:
	if state != State.CHOOSING or shell.is_guide_open():
		return
	if not ModelScript.is_valid_choice(choice) or not ModelScript.is_valid_bet(selected_bet):
		return
	var dice: Array[int] = queued_dice.duplicate() if ModelScript.is_valid_dice(queued_dice) else ModelScript.roll_dice(rng)
	queued_dice = []
	# The wager and the already-decided dice are saved together before any
	# animation, so closing the app mid-shake can never lose or re-roll a bet.
	var receipt: Dictionary = CasinoBankScript.begin_game(FACILITY_ID, selected_bet, {
		"choice": choice,
		"dice": dice,
		"pending_rolls": dice,
	})
	if not bool(receipt.get("ok", false)):
		shell.set_status("チップが足りない。賭け金を選び直そう" if str(receipt.get("reason", "")) == "insufficient_chips" else "いまは始められない。もう一度ためそう")
		shell.refresh_bets(CasinoBankScript.balance())
		return
	state = State.ROLLING
	_set_inputs_locked(true)
	shell.set_balance(int(receipt.get("balance_after", CasinoBankScript.balance())), not instant_for_tests)
	shell.set_primary("壺を振っている…", false)
	shell.set_status("%s（%s）に %d チップ" % [ModelScript.choice_name(choice), ModelScript.choice_caption(choice), selected_bet])
	feel_fx.press_button(shell.primary_button, true)
	var round_choice := choice
	var round_bet := selected_bet
	var game_id := str(receipt.get("game_id", ""))
	await _play_shake()
	var result := _settle_round(round_choice, dice, round_bet, game_id)
	await _play_lift()
	_show_round_result(result)


func _resume_active_round() -> void:
	var active: Dictionary = CasinoBankScript.active_game(FACILITY_ID)
	var session: Dictionary = active.get("session", {}) as Dictionary
	var saved_choice := str(session.get("choice", ""))
	var saved_dice: Variant = session.get("dice", [])
	var bet := int(active.get("bet", 0))
	var game_id := str(active.get("game_id", ""))
	var balance := CasinoBankScript.balance()
	var amounts: Array[int] = ModelScript.BET_AMOUNTS.duplicate()
	shell.set_bets(amounts, bet if bet in ModelScript.BET_AMOUNTS else DEFAULT_BET, balance)
	if not ModelScript.is_valid_choice(saved_choice) or not ModelScript.is_valid_dice(saved_dice) or bet <= 0:
		# A round we cannot read is refunded rather than guessed.
		CasinoBankScript.settle_game(FACILITY_ID, bet, {"refunded": true}, game_id)
		_enter_choosing()
		return
	choice = saved_choice
	selected_bet = bet
	var dice: Array[int] = [int((saved_dice as Array)[0]), int((saved_dice as Array)[1])]
	var result := _settle_round(saved_choice, dice, bet, game_id)
	cup.visible = false
	_show_round_result(result)
	shell.set_status("前の勝負の結果")


## Pay out and put the decided dice under the cup. Chips are settled before
## the reveal so an interrupted lift can never leave a round unpaid.
func _settle_round(round_choice: String, dice: Array[int], bet: int, game_id: String) -> Dictionary:
	var result: Dictionary = ModelScript.resolve(round_choice, dice, bet)
	CasinoBankScript.settle_game(FACILITY_ID, int(result.get("payout", 0)), {
		"won": bool(result.get("won", false)),
		"choice": round_choice,
		"dice": dice,
		"total": int(result.get("total", 0)),
	}, game_id)
	last_result = result
	choice = round_choice
	selected_bet = bet
	dice_presentation.present(dice, false, 2)
	dice_presentation.visible = true
	return result


## Called once the cup is off the dice.
func _show_round_result(result: Dictionary) -> void:
	state = State.RESULT
	var dice: Array = result.get("dice", [1, 1])
	var total := int(result.get("total", 0))
	var payout := int(result.get("payout", 0))
	var won := bool(result.get("won", false))
	var parity := str(result.get("parity", ""))
	total_label.text = "%d ＋ %d ＝ %d" % [int(dice[0]), int(dice[1]), total]
	var detail := "合計 %d は %s（%s）" % [total, ModelScript.choice_name(parity), ModelScript.choice_caption(parity)]
	shell.show_result(won, "当たり！ +%d" % payout if won else "はずれ", detail)
	shell.set_balance(CasinoBankScript.balance(), not instant_for_tests)
	shell.set_status("もう一度なら、丁か半をそのまま選べる")
	shell.set_primary("もう一度", true)
	_set_inputs_locked(false)
	cho_button.set_pressed_no_signal(false)
	han_button.set_pressed_no_signal(false)
	if won:
		feel_fx.play_win_feedback()
	else:
		feel_fx.play_lose_feedback()


# -------------------------------------------------------------- animation

func _play_shake() -> void:
	if instant_for_tests or not is_inside_tree():
		return
	feel_fx.play_dice_roll()
	var rest := _cup_rest_position()
	var tween := create_tween()
	for index: int in range(6):
		var side := -1.0 if index % 2 == 0 else 1.0
		tween.tween_property(cup, "rotation", deg_to_rad(7.0) * side, 0.11).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(cup, "position", rest + Vector2(16.0 * side, -18.0), 0.11).set_trans(Tween.TRANS_SINE)
	tween.tween_property(cup, "rotation", 0.0, 0.08)
	tween.parallel().tween_property(cup, "position", rest + Vector2(0, 8), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(cup, "position", rest, 0.06)
	await tween.finished
	feel_fx.play_dice_land()
	# A held beat before the reveal is the whole game.
	await get_tree().create_timer(0.45).timeout


func _play_lift() -> void:
	var rest := _cup_rest_position()
	if instant_for_tests or not is_inside_tree():
		cup.position = rest - Vector2(0, CUP_LIFT)
		cup.modulate.a = 0.0
		cup.visible = false
		return
	var tween := create_tween()
	tween.tween_property(cup, "position", rest - Vector2(0, CUP_LIFT), 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cup, "modulate:a", 0.0, 0.42)
	await tween.finished
	cup.visible = false
