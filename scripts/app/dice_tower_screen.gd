class_name DiceTowerScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const TowerScript = preload("res://scripts/game/dice_tower_model.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const BET_AMOUNTS := [10, 20, 50]
const ROLL_SECONDS := 0.75
const RESULT_SECONDS := 0.32
const GOLD := Color("#f2bf4c")
const GOLD_LIGHT := Color("#ffe6a0")
const INK := Color("#322315")
const NAVY := Color("#181430")
const PLUM := Color("#2a1c40")
const RED := Color("#c83c32")
const GREEN := Color("#3f7d58")

var game: Dictionary = {}
var selected_bet: int = 20
var rolling: bool = false
var rng_seed: int = 0
var queued_roll_value: int = 0
var rng := RandomNumberGenerator.new()

var chip_label: Label
var status_label: Label
var floor_label: Label
var payout_label: Label
var risk_label: Label
var cashout_button: Button
var roll_button: Button
var start_button: Button
var setup_view: VBoxContainer
var active_view: VBoxContainer
var tower_frame: PanelContainer
var tower_stack: VBoxContainer
var dice_presentation: DicePresentation3D
var face_label: Label
var tutorial_overlay: Control
var tutorial_page_label: Label
var tutorial_body: Label
var tutorial_next_button: Button
var effect_layer: Control
var bet_buttons := {}
var floor_panels := {}
var tutorial_page: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_node("/root/BgmManager").call("play_lasvegas_main")
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_stage", &"las_vegas")
	rng.randomize()
	_build_ui()
	_show_tutorial_page(0)
	_refresh_all()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glow := ColorRect.new()
	glow.color = Color("#36213e")
	glow.anchor_right = 1.0
	glow.anchor_bottom = 0.38
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 11)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 7)
	margin.add_child(root)

	var header := PanelContainer.new()
	header.custom_minimum_size.y = 60
	header.add_theme_stylebox_override("panel", _panel(Color("#5d2440"), GOLD, 20, 3))
	root.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	header.add_child(header_row)
	var title := _label("DICE TOWER", 33, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color("#39121f"))
	title.add_theme_constant_override("outline_size", 5)
	header_row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.custom_minimum_size.x = 112
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 14, 2))
	chip_label = _label("CHIP 0", 16, Color("#fff4cd"))
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	header_row.add_child(chip_panel)

	status_label = _label("まずはBETを選ぼう", 18, Color.WHITE)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 34
	root.add_child(status_label)

	setup_view = VBoxContainer.new()
	setup_view.name = "TowerSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 8)
	root.add_child(setup_view)
	_build_setup_view(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "TowerActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 6)
	active_view.visible = false
	root.add_child(active_view)
	_build_active_view(active_view)

	var back := _button("カジノへ戻る")
	back.name = "CasinoBackButton"
	back.custom_minimum_size.y = 46
	back.pressed.connect(_on_back_pressed)
	root.add_child(back)

	tutorial_overlay = _build_tutorial_overlay()
	add_child(tutorial_overlay)

	effect_layer = Control.new()
	effect_layer.name = "TowerEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 30
	add_child(effect_layer)

func _build_setup_view(root: VBoxContainer) -> void:
	var preview := PanelContainer.new()
	preview.name = "TowerPreview"
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_theme_stylebox_override("panel", _panel(Color("#20182ecc"), GOLD, 18, 3))
	root.add_child(preview)
	var preview_box := VBoxContainer.new()
	preview_box.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_box.add_theme_constant_override("separation", 8)
	preview.add_child(preview_box)
	var crown := _label("10F  x4.40", 28, GOLD_LIGHT)
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(crown)
	var copy := _label("1が出たらBUST。\n2から5で1階、6なら2階登る。", 20, Color.WHITE)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_box.add_child(copy)
	var ask := _label("CASH OUTするか、もう1回ROLLするか。", 18, Color("#f5cf78"))
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_box.add_child(ask)

	var bet_caption := _label("BET", 20, GOLD_LIGHT)
	root.add_child(bet_caption)
	var bet_row := HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bet_row.add_theme_constant_override("separation", 7)
	root.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button := _amount_button(amount)
		button.name = "Bet_%d" % amount
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)

	start_button = _button("GAME START", true)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.y = 76
	start_button.add_theme_font_size_override("font_size", 26)
	start_button.pressed.connect(_start_game)
	root.add_child(start_button)

func _build_active_view(root: VBoxContainer) -> void:
	tower_frame = PanelContainer.new()
	tower_frame.name = "TowerFrame"
	tower_frame.custom_minimum_size.y = 250
	tower_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tower_frame.size_flags_stretch_ratio = 1.45
	tower_frame.add_theme_stylebox_override("panel", _panel(Color("#171126"), Color("#7a5a31"), 14, 2))
	root.add_child(tower_frame)
	tower_stack = VBoxContainer.new()
	tower_stack.name = "TowerStack"
	tower_stack.add_theme_constant_override("separation", 2)
	tower_frame.add_child(tower_stack)
	for floor_number: int in range(TowerScript.MAX_FLOOR, 0, -1):
		var row := PanelContainer.new()
		row.name = "Floor_%d" % floor_number
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 22
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_stylebox_override("panel", _panel(Color("#2b2338"), Color.TRANSPARENT, 5, 0))
		tower_stack.add_child(row)
		var text := _label("%dF  x%.2f" % [floor_number, TowerScript.multiplier_for_floor(floor_number)], 15, Color("#cfc4dc"))
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		floor_panels[floor_number] = {"panel": row, "label": text}
	var start_base := PanelContainer.new()
	start_base.name = "TowerStartBase"
	start_base.custom_minimum_size.y = 30
	start_base.add_theme_stylebox_override("panel", _panel(GOLD, GOLD_LIGHT, 5, 1))
	tower_stack.add_child(start_base)
	var start_text := _label("START", 15, INK)
	start_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_base.add_child(start_text)

	var stats := HBoxContainer.new()
	stats.name = "PayoutStats"
	stats.add_theme_constant_override("separation", 5)
	root.add_child(stats)
	var floor_box := _stat_box("FLOOR")
	floor_label = floor_box.label
	stats.add_child(floor_box.panel)
	var payout_box := _stat_box("CASH OUT")
	payout_label = payout_box.label
	stats.add_child(payout_box.panel)
	var risk_box := _stat_box("ROLL 1")
	risk_label = risk_box.label
	stats.add_child(risk_box.panel)

	var console := CenterContainer.new()
	console.name = "DiceConsole"
	console.custom_minimum_size.y = 158
	root.add_child(console)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "TowerDie3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(210, 152)
	console.add_child(dice_presentation)
	face_label = _label("", 1, Color.TRANSPARENT)
	face_label.name = "RolledFaceLabel"
	face_label.visible = false
	add_child(face_label)

	var actions := HBoxContainer.new()
	actions.name = "TowerActions"
	actions.add_theme_constant_override("separation", 7)
	root.add_child(actions)
	cashout_button = _button("CASH OUT", false)
	cashout_button.name = "CashOutButton"
	cashout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cashout_button.custom_minimum_size.y = 90
	cashout_button.add_theme_font_size_override("font_size", 21)
	cashout_button.disabled = true
	cashout_button.pressed.connect(_on_cashout_pressed)
	actions.add_child(cashout_button)
	roll_button = _button("ROLL\nCLIMB HIGHER", true)
	roll_button.name = "RollButton"
	roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_button.custom_minimum_size.y = 90
	roll_button.add_theme_font_size_override("font_size", 23)
	roll_button.pressed.connect(_on_roll_pressed)
	actions.add_child(roll_button)

func _build_tutorial_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "TowerTutorial"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 50
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.name = "TutorialCard"
	card.custom_minimum_size.x = 300
	card.add_theme_stylebox_override("panel", _panel(Color("#2b2038"), GOLD, 16, 3))
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var title := _label("HOW TO PLAY", 27, GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	tutorial_body = _label("", 20, Color.WHITE)
	tutorial_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.custom_minimum_size.y = 96
	box.add_child(tutorial_body)
	tutorial_page_label = _label("1 / 3", 16, Color("#cdbfd7"))
	tutorial_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tutorial_page_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var skip := _button("SKIP")
	skip.name = "TutorialSkipButton"
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip.pressed.connect(_close_tutorial)
	actions.add_child(skip)
	tutorial_next_button = _button("NEXT", true)
	tutorial_next_button.name = "TutorialNextButton"
	tutorial_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_next_button.pressed.connect(_advance_tutorial)
	actions.add_child(tutorial_next_button)
	return overlay

func _build_stat_panel(caption: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6d995"), Color("#a96b2e"), 12, 2))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var cap := _label(caption, 13, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value := _label("-", 19, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _stat_box(caption: String) -> Dictionary:
	return _build_stat_panel(caption)

func _amount_button(amount: int) -> Button:
	var button := _button("%d CHIP" % amount)
	button.custom_minimum_size = Vector2(100, 54)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _show_tutorial_page(page: int) -> void:
	tutorial_page = clampi(page, 0, 2)
	match tutorial_page:
		0:
			tutorial_body.text = "2から5で\n1階UP！"
		1:
			tutorial_body.text = "6なら\n2階UP！"
		2:
			tutorial_body.text = "1が出たら\n全部BUST！"
	tutorial_page_label.text = "%d / 3" % (tutorial_page + 1)
	tutorial_next_button.text = "PLAY" if tutorial_page == 2 else "NEXT"

func _advance_tutorial() -> void:
	if tutorial_page >= 2:
		_close_tutorial()
		return
	_play_ui_sfx(&"select", false)
	_show_tutorial_page(tutorial_page + 1)

func _close_tutorial() -> void:
	tutorial_overlay.visible = false
	_play_ui_sfx(&"back", false)
	_refresh_bet_buttons()

func _select_bet(amount: int) -> void:
	selected_bet = amount
	_play_ui_sfx(&"select", false)
	_refresh_bet_buttons()

func _refresh_bet_buttons() -> void:
	var chips := CasinoBankScript.balance()
	for amount: int in bet_buttons:
		var button := bet_buttons[amount] as Button
		button.disabled = chips < amount
		button.text = ("● " if amount == selected_bet else "") + "%d CHIP" % amount
		_apply_button_state(button, amount == selected_bet)
	start_button.disabled = chips < selected_bet
	if start_button.disabled:
		status_label.text = "CHIPが足りない。通常ステージでCOINを持ち帰ろう。"
	else:
		status_label.text = "%d CHIPで塔に挑む？" % selected_bet

func _start_game() -> void:
	if rolling or CasinoBankScript.balance() < selected_bet:
		return
	if not CasinoBankScript.spend_chips(selected_bet):
		_play_ui_sfx(&"blocked", false)
		_refresh_bet_buttons()
		return
	if rng_seed != 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	queued_roll_value = 0
	game = TowerScript.new_game(selected_bet)
	rolling = false
	_set_retry_action(false)
	setup_view.visible = false
	active_view.visible = true
	cashout_button.disabled = true
	roll_button.disabled = false
	_reset_tower_visuals()
	_play_ui_sfx(&"start", false)
	_show_banner("BET %d CHIP" % selected_bet, GOLD_LIGHT, Color("#3f2408"), 0.55, "BetBanner")
	_refresh_all()

func _on_roll_pressed() -> void:
	if rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	rolling = true
	cashout_button.disabled = true
	roll_button.disabled = true
	var rolled: int = queued_roll_value if queued_roll_value in range(1, 7) else rng.randi_range(1, 6)
	queued_roll_value = 0
	status_label.text = "サイコロが回る..."
	dice_presentation.present([rolled], true, 1)
	await get_tree().create_timer(ROLL_SECONDS).timeout
	if not is_inside_tree():
		return
	game = TowerScript.apply_roll(game, rolled)
	dice_presentation.present([rolled], false, 1)
	await get_tree().create_timer(RESULT_SECONDS).timeout
	if not is_inside_tree():
		return
	rolling = false
	_after_roll_resolution()

func _after_roll_resolution() -> void:
	var kind := str(game.get("last_kind", ""))
	if bool(game.get("completed", false)):
		_play_ui_sfx(&"complete", true)
		_show_banner("TOWER COMPLETE!", GOLD_LIGHT, Color("#3f2408"), 0.85, "CompleteBanner")
		_finish_success(int(game.get("payout", 0)), "10F到達！ %d CHIP獲得！" % int(game.get("payout", 0)))
		_refresh_all()
		return
	if bool(game.get("busted", false)):
		_play_ui_sfx(&"error", true)
		status_label.text = "BUST！ 獲得予定CHIPは0。"
		_show_banner("BUST  0 CHIP", Color("#ffd9d4"), Color("#5b1210"), 0.85, "BustBanner")
		_play_bust_fx()
		_set_result_finished()
		_refresh_all()
		return
	if kind == "leap":
		_play_ui_sfx(&"bonus", true)
		_show_banner("GOLDEN LEAP!", GOLD_LIGHT, Color("#3f2408"), 0.48, "LeapBanner")
		status_label.text = "GOLDEN LEAP！ %dFへ。" % int(game.get("floor", 0))
	else:
		_play_ui_sfx(&"progress-step", true)
		status_label.text = "CLIMB！ %dFへ。" % int(game.get("floor", 0))
	cashout_button.disabled = false
	roll_button.disabled = false
	_refresh_all()

func _on_cashout_pressed() -> void:
	if rolling or not bool(game.get("active", false)) or bool(game.get("finished", false)):
		return
	var payout := TowerScript.cashout_payout(game)
	if payout <= 0:
		_play_ui_sfx(&"blocked", false)
		return
	game = TowerScript.take_cashout(game)
	_play_ui_sfx(&"complete", true)
	_finish_success(payout, "CASH OUT！ +%d CHIP" % payout)

func _finish_success(payout: int, message: String) -> void:
	CasinoBankScript.add_chips(payout)
	status_label.text = message
	_spawn_confetti()
	_set_result_finished()
	_refresh_all()

func _set_result_finished() -> void:
	cashout_button.disabled = true
	roll_button.disabled = false
	roll_button.text = "もう一度"
	_apply_roll_style(true)
	_set_retry_action(true)

func _set_retry_action(enabled: bool) -> void:
	if roll_button == null:
		return
	if roll_button.pressed.is_connected(_on_roll_pressed):
		roll_button.pressed.disconnect(_on_roll_pressed)
	if roll_button.pressed.is_connected(_restart_after_result):
		roll_button.pressed.disconnect(_restart_after_result)
	if enabled:
		roll_button.pressed.connect(_restart_after_result, CONNECT_ONE_SHOT)
	else:
		roll_button.pressed.connect(_on_roll_pressed)

func _restart_after_result() -> void:
	_play_ui_sfx(&"retry", false)
	_show_setup()

func _show_setup() -> void:
	game = {}
	rolling = false
	queued_roll_value = 0
	active_view.visible = false
	setup_view.visible = true
	roll_button.text = "ROLL\nCLIMB HIGHER"
	_apply_roll_style(false)
	_set_retry_action(false)
	_reset_tower_visuals()
	_refresh_all()

func _reset_tower_visuals() -> void:
	tower_frame.modulate = Color.WHITE
	tower_frame.offset_transform_enabled = false
	tower_frame.offset_transform_position = Vector2.ZERO
	dice_presentation.present([1], false, 1)

func _refresh_all() -> void:
	chip_label.text = "CHIP  %d" % CasinoBankScript.balance()
	if game.is_empty():
		_refresh_bet_buttons()
		return
	var floor_number := int(game.get("floor", 0))
	var payout := int(game.get("payout", 0))
	var planned_payout: int = payout if bool(game.get("finished", false)) else TowerScript.cashout_payout(game)
	floor_label.text = str(floor_number)
	payout_label.text = "%d CHIP" % planned_payout
	risk_label.text = "-%d CHIP" % planned_payout
	cashout_button.text = "CASH OUT\n%d CHIP" % planned_payout
	cashout_button.disabled = not bool(game.get("active", false)) or floor_number < 1 or rolling
	_refresh_tower(floor_number)

func _refresh_tower(current_floor: int) -> void:
	for floor_number: int in floor_panels:
		var entry: Dictionary = floor_panels[floor_number]
		var panel := entry.panel as PanelContainer
		var label := entry.label as Label
		var visited := floor_number <= current_floor
		var current := floor_number == current_floor
		label.text = ("%dF  x%.2f\nPLAYER" % [floor_number, TowerScript.multiplier_for_floor(floor_number)]) if current else ("%dF  x%.2f" % [floor_number, TowerScript.multiplier_for_floor(floor_number)])
		var border := Color.TRANSPARENT
		if current:
			border = GOLD_LIGHT
		elif bool(game.get("busted", false)):
			border = RED
		panel.add_theme_stylebox_override("panel", _panel(
			GOLD if current else (Color("#4b3559") if visited else Color("#2b2338")),
			border,
			5,
			2 if current or bool(game.get("busted", false)) else 0))
		label.add_theme_color_override("font_color", INK if current else (Color("#fff0cf") if visited else Color("#cfc4dc")))

func _show_banner(text: String, color: Color, outline_color: Color, hold_seconds: float, node_name: String) -> void:
	if effect_layer == null:
		return
	var banner := _label(text, 30, color)
	banner.name = node_name
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_outline_color", outline_color)
	banner.add_theme_constant_override("outline_size", 7)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.add_child(banner)
	banner.size = Vector2(minf(320.0, effect_layer.size.x - 20.0), 56)
	banner.position = Vector2(
		(effect_layer.size.x - banner.size.x) * 0.5,
		maxf(104.0, effect_layer.size.y * 0.22))
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.78, 0.78)
	banner.modulate.a = 0.0
	var intro := create_tween().set_parallel(true)
	intro.tween_property(banner, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(banner, "modulate:a", 1.0, 0.09)
	intro.chain().tween_interval(hold_seconds)
	intro.chain().tween_property(banner, "modulate:a", 0.0, 0.16)
	intro.chain().tween_callback(banner.queue_free)

func _spawn_confetti() -> void:
	if effect_layer == null:
		return
	for index: int in 24:
		var piece := ColorRect.new()
		piece.name = "ConfettiPiece"
		piece.size = Vector2(randf_range(4.0, 7.0), randf_range(7.0, 13.0))
		piece.color = [GOLD, GOLD_LIGHT, Color("#fff7df"), Color("#ffb46b")][index % 4]
		piece.rotation = randf_range(-PI, PI)
		piece.position = Vector2(randf_range(0.0, maxf(1.0, effect_layer.size.x)), -18.0)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(piece)
		var fall := create_tween().set_parallel(true)
		fall.tween_property(piece, "position:y", effect_layer.size.y + 24.0, randf_range(1.0, 1.55))
		fall.tween_property(piece, "rotation", piece.rotation + randf_range(-3.0, 3.0), 1.2)
		fall.tween_property(piece, "modulate:a", 0.0, 0.32).set_delay(0.9)
		fall.chain().tween_callback(piece.queue_free)

func _play_bust_fx() -> void:
	if tower_frame == null or effect_layer == null:
		return
	tower_frame.modulate = Color(1.55, 0.68, 0.68)
	var collapse := create_tween()
	collapse.tween_interval(0.05)
	collapse.tween_property(tower_frame, "modulate", Color(0.52, 0.24, 0.24, 0.42), 0.42)
	for index: int in 14:
		var shard := ColorRect.new()
		shard.name = "BustShard"
		shard.size = Vector2(randf_range(5.0, 11.0), randf_range(4.0, 8.0))
		shard.color = [GOLD, Color("#8d7f9c"), RED][index % 3]
		shard.position = Vector2(randf_range(24.0, maxf(28.0, effect_layer.size.x - 28.0)), randf_range(180.0, maxf(184.0, effect_layer.size.y * 0.66)))
		shard.rotation = randf_range(-PI, PI)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(shard)
		var drop := create_tween().set_parallel(true)
		drop.tween_property(shard, "position:y", effect_layer.size.y + 30.0, randf_range(0.65, 1.0))
		drop.tween_property(shard, "rotation", shard.rotation + randf_range(-4.0, 4.0), 0.85)
		drop.chain().tween_callback(shard.queue_free)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)

func _apply_button_state(button: Button, selected: bool) -> void:
	if selected:
		button.add_theme_stylebox_override("normal", _panel(Color("#f7df9a"), GOLD, 12, 3))
		button.add_theme_color_override("font_color", INK)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#403452"), Color("#705e84"), 12, 2))
		button.add_theme_color_override("font_color", Color("#fff4dc"))

func _apply_roll_style(danger: bool) -> void:
	var fill := RED if danger else GOLD
	var border := Color("#ff9b7e") if danger else Color("#a67836")
	roll_button.add_theme_stylebox_override("normal", _panel(fill, border, 12, 3))
	roll_button.add_theme_stylebox_override("hover", _panel(fill.lightened(0.08), GOLD_LIGHT, 12, 3))

func _on_back_pressed() -> void:
	_play_ui_sfx(&"back", false)
	back_requested.emit()

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
	button.custom_minimum_size = Vector2(88, 44)
	button.add_theme_color_override("font_color", INK if primary else Color("#fff4dc"))
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#d8d0bf"))
	button.add_theme_stylebox_override("normal", _panel(GOLD if primary else Color("#403452"), Color("#a67836") if primary else Color("#705e84"), 12, 2))
	button.add_theme_stylebox_override("hover", _panel(GOLD_LIGHT if primary else Color("#51436a"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel(Color("#d99d2c") if primary else Color("#302641"), GOLD, 12, 2))
	button.add_theme_stylebox_override("disabled", _panel(Color("#514c45"), Color("#766d5f"), 12, 1))
	return button

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
