class_name DiceTowerScreen
extends Control

## DICE TOWER on the shared casino table.
##
## One die, ten floors. 2-5 climbs one floor, 6 climbs two, 1 loses the run.
## After every roll the player chooses: climb again, or step off and take the
## chips for the floor reached. Reaching the 10th floor pays out at once.
##
## The ladder on the felt always shows what each floor returns for the chosen
## wager, so the decision is read as chips, never as a multiplier.
##
## Rules live in DiceTowerModel and chips in CasinoBank. Every roll is saved
## with its already-decided face before the animation, so an interrupted run
## resumes on the same die.

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const TowerScript = preload("res://scripts/game/dice_tower_model.gd")
const ShellScript = preload("res://scripts/ui/casino_table_shell.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const CasinoFeelFXScript = preload("res://scripts/ui/casino_feel_fx.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const FACILITY_ID := "dice_tower"
const TITLE := "DICE TOWER"
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const ROLL_SECONDS := 0.75
const RESULT_SECONDS := 0.32
const DIE_BOX := Vector2(380, 380)
const GOLD := Color("#f2bf4c")
const GOLD_BRIGHT := Color("#ffe6a0")
const CREAM := Color("#fff4d6")
const MUTED := Color("#cdbfd7")
const INK := Color("#2a1a0c")
const DANGER := Color("#ff8f80")

static var suppress_audio_for_tests := false
## Tests skip every roll timer so a run resolves without waiting.
static var instant_for_tests := false

var game: Dictionary = {}
var game_id: String = ""
var selected_bet: int = 20
var rolling: bool = false
var settled: bool = false
var rng_seed: int = 0
var queued_roll_value: int = 0
var rng := RandomNumberGenerator.new()
var pending_roll: Dictionary = {}
## "setup" | "rolling" | "active" | "result"
var view_state: String = "setup"
var exiting := false

var shell: Control
var dice_presentation: DicePresentation3D
var ladder: VBoxContainer
var floor_rows: Dictionary = {}
var floor_amount_labels: Dictionary = {}
var rule_label: Label
var feel_fx: CasinoFeelFX

# Aliases onto the shell so the cross-facility QA tours can drive this table
# the same way they drive the others.
var start_button: Button
var roll_button: Button
var cashout_button: Button
var back_button: Button
var result_view: Control
var chip_label: Label
var bet_buttons: Dictionary:
	get:
		return shell.bet_buttons if shell != null else {}
## Same meaning as on the other tables: input is locked while a die rolls.
var presentation_locked: bool:
	get:
		return rolling


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_dice_tower")
		var ui_sfx := get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	feel_fx = CasinoFeelFXScript.new()
	feel_fx.name = "CasinoFeelFX"
	feel_fx.audio_enabled = not suppress_audio_for_tests
	add_child(feel_fx)
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
		"賭け金を選んで、サイコロを振る",
		"2〜5で1段、6で2段のぼる。1が出たら全部なくなる",
		"いつでも降りて、その段のチップを受け取れる",
	]
	shell.set_guide("DICE TOWER の遊び方", steps)
	shell.back_requested.connect(_on_back_pressed)
	shell.primary_pressed.connect(_on_primary_pressed)
	shell.bet_selected.connect(_select_bet)
	start_button = shell.primary_button
	roll_button = shell.primary_button
	back_button = shell.back_button
	result_view = shell.result_panel
	chip_label = shell.chip_label

	cashout_button = shell.add_action("cashout", "ここで降りる")
	cashout_button.pressed.connect(_on_cashout_pressed)
	shell.choice_row.visible = false

	ladder = VBoxContainer.new()
	ladder.name = "TowerLadder"
	ladder.add_theme_constant_override("separation", 4)
	ladder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.table_root.add_child(ladder)
	for floor_number: int in range(TowerScript.MAX_FLOOR, 0, -1):
		var row := PanelContainer.new()
		row.name = "Floor_%d" % floor_number
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ladder.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)
		var number := _label("%dF" % floor_number, 28, MUTED)
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.name = "FloorNumber"
		number.custom_minimum_size.x = 64
		line.add_child(number)
		var amount := _label("", 28, CREAM)
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount.name = "FloorAmount"
		amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(amount)
		floor_rows[floor_number] = row
		floor_amount_labels[floor_number] = amount

	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "TowerDie3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.size = DIE_BOX
	shell.table_root.add_child(dice_presentation)
	# Look straight down: only the top face counts.
	dice_presentation.camera.fov = 30.0
	dice_presentation.camera.look_at_from_position(Vector3(0, 9.0, 1.6), Vector3(0, 0.7, 0))

	rule_label = _label("2〜5：1段　6：2段\n1：ぜんぶなくなる", 26, MUTED)
	rule_label.name = "TowerRule"
	rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.table_root.add_child(rule_label)

	shell.table_root.move_child(shell.result_panel, -1)
	shell.table_root.resized.connect(_layout_table)
	_layout_table()


func _layout_table() -> void:
	var area: Vector2 = shell.table_root.size
	if area.x < 8.0 or area.y < 8.0:
		return
	var ladder_width := clampf(area.x * 0.42, 180.0, 300.0)
	ladder.position = Vector2(20, 20)
	ladder.size = Vector2(ladder_width, area.y - 40.0)
	var right_left := ladder_width + 32.0
	var right_width := area.x - right_left - 16.0
	var die_side := minf(DIE_BOX.x, right_width)
	dice_presentation.size = Vector2(die_side, die_side)
	dice_presentation.position = Vector2(right_left + (right_width - die_side) * 0.5, area.y * 0.5 - die_side * 0.62)
	rule_label.size = Vector2(right_width, 76)
	rule_label.position = Vector2(right_left, dice_presentation.position.y + die_side + 8.0)


# ------------------------------------------------------------------ resume

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
	if bool(game.get("finished", false)):
		view_state = "active"
		_refresh_all()
		call_deferred("_after_roll_resolution")
	elif not pending_roll.is_empty():
		rolling = true
		view_state = "rolling"
		_refresh_all()
		call_deferred("_resume_pending_roll")
	else:
		view_state = "active"
		_refresh_all()


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


# ------------------------------------------------------------------ inputs

func _select_bet(amount: int) -> void:
	if amount not in BET_AMOUNTS or rolling or view_state in ["active", "rolling"]:
		return
	selected_bet = amount
	if view_state == "result":
		_show_setup()
	else:
		_refresh_all()


func _on_primary_pressed() -> void:
	match view_state:
		"setup":
			_start_game()
		"active":
			_on_roll_pressed()
		"result":
			_play_again_same_bet()


func _on_back_pressed() -> void:
	if exiting:
		return
	if rolling:
		shell.set_status("サイコロが止まるまで少し待とう")
		return
	# A climb in progress is saved and resumes on the same floor next time.
	if not game.is_empty() and not game_id.is_empty() and not settled:
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	back_requested.emit()


func _toggle_help() -> void:
	if shell.is_guide_open():
		shell.close_guide()
	else:
		shell.open_guide()


func _next_face() -> int:
	var rolled: int = queued_roll_value if queued_roll_value in range(1, 7) else rng.randi_range(1, 6)
	queued_roll_value = 0
	return rolled


## Commit the wager and the first face in one save, then climb.
func _start_game() -> void:
	if rolling or shell.is_guide_open() or selected_bet not in BET_AMOUNTS:
		return
	if CasinoBankScript.balance() < selected_bet:
		shell.set_status("チップが足りない。賭け金を選び直そう")
		_refresh_all()
		return
	if rng_seed != 0:
		rng.seed = rng_seed
		rng_seed = 0
	var initial_game: Dictionary = TowerScript.new_game(selected_bet)
	var first := {"kind": "roll", "value": _next_face(), "from_floor": 0, "roll_index": 1}
	initial_game["pending_rolls"] = [first.duplicate(true)]
	var receipt: Dictionary = CasinoBankScript.begin_game(FACILITY_ID, selected_bet, initial_game)
	if not bool(receipt.get("ok", false)):
		if bool(receipt.get("already_active", false)):
			_resume_or_show_setup()
			return
		shell.set_status("いまは始められない。チップを確認しよう")
		_refresh_all()
		return
	game = initial_game
	game_id = str(receipt.get("game_id", ""))
	pending_roll = first
	settled = false
	rolling = true
	view_state = "rolling"
	shell.clear_result()
	feel_fx.press_button(shell.primary_button, true)
	shell.set_balance(int(receipt.get("balance_after", CasinoBankScript.balance())), not instant_for_tests)
	_refresh_all()
	await _animate_and_resolve_pending_roll(pending_roll)


func _on_roll_pressed() -> void:
	if rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	feel_fx.press_button(shell.primary_button, true)
	if int(game.get("floor", 0)) >= 7:
		feel_fx.play_tower_tension()
	pending_roll = {
		"kind": "roll",
		"value": _next_face(),
		"from_floor": int(game.get("floor", 0)),
		"roll_index": int(game.get("roll_count", 0)) + 1,
	}
	game["pending_rolls"] = [pending_roll.duplicate(true)]
	var receipt: Dictionary = CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	if not bool(receipt.get("ok", false)):
		shell.set_status("保存できなかった。もう一度振ろう")
		return
	rolling = true
	view_state = "rolling"
	_refresh_all()
	await _animate_and_resolve_pending_roll(pending_roll)


func _on_cashout_pressed() -> void:
	if rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var payout: int = TowerScript.cashout_payout(game)
	if payout <= 0:
		return
	game = TowerScript.take_cashout(game)
	feel_fx.play_cashout_feedback(shell.chip_label)
	_finish_run()


func _play_again_same_bet() -> void:
	if rolling or view_state != "result":
		return
	_show_setup()
	_start_game()


# -------------------------------------------------------------------- run

func _animate_and_resolve_pending_roll(pending: Dictionary) -> void:
	var rolled: int = clampi(int(pending.get("value", 1)), 1, 6)
	dice_presentation.visible = true
	if not instant_for_tests:
		feel_fx.play_dice_roll()
		dice_presentation.present([rolled], true, 1)
		await get_tree().create_timer(ROLL_SECONDS).timeout
		if exiting or not is_inside_tree():
			return
	game = TowerScript.apply_roll(game, rolled)
	game["pending_rolls"] = []
	pending_roll = {}
	CasinoBankScript.update_game(FACILITY_ID, game, game_id)
	dice_presentation.present([rolled], false, 1)
	if not instant_for_tests:
		feel_fx.play_dice_land()
		await get_tree().create_timer(RESULT_SECONDS).timeout
		if exiting or not is_inside_tree():
			return
	rolling = false
	_after_roll_resolution()


func _after_roll_resolution() -> void:
	if bool(game.get("finished", false)):
		if bool(game.get("busted", false)):
			feel_fx.play_tower_bust()
		elif bool(game.get("completed", false)):
			feel_fx.play_tower_complete()
		_finish_run()
		return
	view_state = "active"
	feel_fx.play_tower_floor_up(int(game.get("floor", 0)))
	_refresh_all()


func _finish_run() -> void:
	var payout: int = maxi(0, int(game.get("payout", 0)))
	if not settled:
		CasinoBankScript.update_game(FACILITY_ID, game, game_id)
		var receipt: Dictionary = CasinoBankScript.settle_game(FACILITY_ID, payout, {
			"floor": int(game.get("floor", 0)),
			"highest_floor": int(game.get("highest_floor", 0)),
			"busted": bool(game.get("busted", false)),
			"completed": bool(game.get("completed", false)),
			"cashed_out": bool(game.get("cashed_out", false)),
			"payout": payout,
			"won": payout > int(game.get("bet", selected_bet)),
		}, game_id)
		if bool(receipt.get("already_settled", false)):
			payout = int(receipt.get("payout", payout))
			game["payout"] = payout
		settled = bool(receipt.get("ok", false)) or bool(receipt.get("already_settled", false))
	rolling = false
	view_state = "result"
	var bet: int = int(game.get("bet", selected_bet))
	if bool(game.get("busted", false)):
		var lost_floor: int = int(game.get("floor_before_bust", 0))
		var lost: int = int(game.get("lost_payout", 0))
		var detail := "%dF で落ちた。受け取り 0" % lost_floor if lost_floor > 0 else "最初の1投で落ちた。受け取り 0"
		if lost > 0:
			detail += "（降りていれば +%d）" % lost
		shell.show_result(false, "1が出た…", detail)
		feel_fx.play_lose_feedback()
	elif bool(game.get("completed", false)):
		shell.show_result(true, "頂上！ +%d" % payout, "10F まで登りきった")
	else:
		shell.show_result(payout > bet, "+%d 受け取り" % payout, "%dF で降りた ・ 賭け金 %d" % [int(game.get("floor", 0)), bet])
	_refresh_all()
	shell.set_balance(CasinoBankScript.balance(), not instant_for_tests)


func _show_setup() -> void:
	game = {}
	game_id = ""
	pending_roll = {}
	settled = false
	rolling = false
	queued_roll_value = 0 if queued_roll_value not in range(1, 7) else queued_roll_value
	view_state = "setup"
	shell.clear_result()
	_refresh_all()


# ----------------------------------------------------------------- refresh

func _refresh_all() -> void:
	var balance := CasinoBankScript.balance()
	if view_state != "result" and view_state != "rolling":
		shell.set_balance(balance)
	shell.back_button.disabled = rolling
	shell.help_button.disabled = rolling
	var bet: int = int(game.get("bet", selected_bet)) if not game.is_empty() else selected_bet
	var current_floor: int = int(game.get("floor", 0)) if view_state != "result" else int(game.get("floor", 0))
	_refresh_ladder(bet, current_floor)
	match view_state:
		"setup":
			if selected_bet > balance:
				for amount: int in [50, 20, 10]:
					if amount <= balance:
						selected_bet = amount
						break
			shell.set_bets(BET_AMOUNTS.duplicate(), selected_bet, balance)
			shell.choice_row.visible = false
			var can_afford := balance >= selected_bet and selected_bet in BET_AMOUNTS
			shell.set_status("1が出る前に降りれば勝ち。頂上まで登れば +%d" % TowerScript.payout_for_floor(selected_bet, TowerScript.MAX_FLOOR) if can_afford else "チップが足りない。旅でチップを集めよう")
			shell.set_primary("サイコロを振る", can_afford)
			dice_presentation.visible = false
		"rolling":
			shell.bet_row.visible = false
			shell.choice_row.visible = false
			shell.set_status("サイコロを振っている…")
			shell.set_primary("…", false)
		"active":
			shell.bet_row.visible = false
			var take := TowerScript.cashout_payout(game)
			shell.choice_row.visible = take > 0
			cashout_button.text = "ここで降りる  +%d" % take
			cashout_button.disabled = take <= 0
			shell.set_status("いま %dF　降りれば +%d　1が出たら 0" % [current_floor, take])
			shell.set_primary("もう1段（振る）", true)
		"result":
			shell.choice_row.visible = false
			shell.set_bets(BET_AMOUNTS.duplicate(), selected_bet, balance)
			shell.set_status("賭け金を変えるなら、下から選び直せる")
			shell.set_primary("もう一度（賭け金 %d）" % selected_bet, balance >= selected_bet)


func _refresh_ladder(bet: int, current_floor: int) -> void:
	var busted := bool(game.get("busted", false))
	for floor_number: int in floor_rows.keys():
		var row := floor_rows[floor_number] as PanelContainer
		var amount := floor_amount_labels[floor_number] as Label
		amount.text = "+%d" % TowerScript.payout_for_floor(bet, floor_number)
		var reached := current_floor >= floor_number and not busted and view_state != "setup"
		var here := current_floor == floor_number and not busted and view_state in ["active", "result"]
		var fill := Color("#4a3410") if here else (Color("#1c3a2c") if reached else Color("#0b2a20"))
		var border := GOLD_BRIGHT if here else (Color("#6f8f5c") if reached else Color("#24493a"))
		row.add_theme_stylebox_override("panel", ShellScript._box(fill, border, 12, 3 if here else 1, 6))
		amount.add_theme_color_override("font_color", GOLD_BRIGHT if here else (CREAM if reached else MUTED))
		(row.find_child("FloorNumber", true, false) as Label).add_theme_color_override("font_color", GOLD_BRIGHT if here else (CREAM if reached else MUTED))


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
