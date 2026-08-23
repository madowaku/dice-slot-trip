class_name DiceRaceScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const OrientationScript = preload("res://scripts/game/dice_race_orientation.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const RACER_LABELS := {
	"camel": "ラクダ",
	"rabbit": "ウサギ",
	"fox": "キツネ",
	"duck": "アヒル",
	"dinosaur": "恐竜",
	"robot": "ロボット",
}
const RACER_SHORT := {
	"camel": "05",
	"rabbit": "01",
	"fox": "03",
	"duck": "04",
	"dinosaur": "02",
	"robot": "06",
}
const RACER_COLORS := {
	"camel": Color("#3979bf"),
	"rabbit": Color("#d65345"),
	"fox": Color("#d96f2b"),
	"duck": Color("#e0a918"),
	"dinosaur": Color("#6c9f45"),
	"robot": Color("#5d99a5"),
}
# The art is optional in CI. When these PNGs exist, the UI automatically uses
# them; otherwise the same layout falls back to numbered mascot badges.
const RACER_ART_PATHS := {
	"camel": "res://assets/casino/racers/camel.png",
	"rabbit": "res://assets/casino/racers/rabbit.png",
	"fox": "res://assets/casino/racers/fox.png",
	"duck": "res://assets/casino/racers/duck.png",
	"dinosaur": "res://assets/casino/racers/dinosaur.png",
	"robot": "res://assets/casino/racers/robot.png",
}
const BET_AMOUNTS := [10, 20, 50]
const SPIN_STEP_SECONDS := 0.085

const GOLD := Color("#f2bf4c")
const GOLD_LIGHT := Color("#ffe6a0")
const INK := Color("#322315")
const CREAM := Color("#fff0cf")
const NAVY := Color("#171932")
const NAVY_2 := Color("#25234a")
const RED := Color("#9f322b")
const TRACK := Color("#d7a960")
const TRACK_LIGHT := Color("#edca85")

var orientations: Array[Dictionary] = []
var race: Dictionary = {}
var selected_racer := "duck"
var selected_bet := 20
var spinning := false
var spin_elapsed := 0.0
var orientation_index := 0
var current_assignments: Dictionary = {}
var wager_committed := false
var result_recorded := false

var chip_label: Label
var bet_label: Label
var roll_count_label: Label
var win_label: Label
var status_label: Label
var ranking_label: Label
var assignment_label: Label
var target_value_label: Label
var die_face_label: Label
var track: Control
var racer_nodes := {}
var assignment_cards := {}
var ranking_cards: Array[Label] = []
var roll_button: Button
var start_button: Button
var cashout_row: HBoxContainer
var cashout_label: Label
var cashout_button: Button
var ride_on_button: Button
var bet_panel: VBoxContainer
var racer_buttons := {}
var amount_buttons := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientations = OrientationScript.all_orientations()
	_build_ui()
	_show_bet_select()

func _process(delta: float) -> void:
	if not spinning or orientations.is_empty():
		return
	spin_elapsed += delta
	var next_index := int(floor(spin_elapsed / SPIN_STEP_SECONDS)) % orientations.size()
	if next_index != orientation_index:
		orientation_index = next_index
		current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
		_refresh_assignment_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glow := ColorRect.new()
	glow.color = Color("#31406a")
	glow.anchor_right = 1.0
	glow.anchor_bottom = 0.46
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	scroll.add_child(root)

	_build_header(root)
	_build_status_row(root)
	_build_track(root)
	_build_ranking(root)
	_build_dice_console(root)

	status_label = _label("賭けるレーサーを選ぼう", 17, Color.WHITE)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 34
	root.add_child(status_label)

	_build_bet_panel(root)
	_build_cashout(root)

	roll_button = _button("ROLL", true)
	roll_button.name = "RollStopButton"
	roll_button.custom_minimum_size.y = 68
	roll_button.add_theme_font_size_override("font_size", 30)
	roll_button.pressed.connect(_on_roll_stop)
	root.add_child(roll_button)

	var back := _button("カジノへ戻る")
	back.custom_minimum_size.y = 44
	back.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back)

func _build_header(root: VBoxContainer) -> void:
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _panel(RED, GOLD, 22, 3))
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)
	var title := _label("DICE RACE", 34, GOLD_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", Color("#4e1715"))
	title.add_theme_constant_override("outline_size", 5)
	row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.custom_minimum_size.x = 148
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c19"), GOLD, 16, 2))
	chip_label = _label("CHIP 0", 19, Color("#fff4cd"))
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_status_row(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	root.add_child(row)
	var bet_box := _hud_box("BET")
	bet_label = bet_box.label
	row.add_child(bet_box.panel)
	var roll_box := _hud_box("ROLL")
	roll_count_label = roll_box.label
	row.add_child(roll_box.panel)
	var win_box := _hud_box("WIN")
	win_label = win_box.label
	row.add_child(win_box.panel)

func _hud_box(caption: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6d995"), Color("#a96b2e"), 14, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var cap := _label(caption, 13, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value := _label("-", 18, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _build_track(root: VBoxContainer) -> void:
	var track_frame := PanelContainer.new()
	track_frame.custom_minimum_size.y = 330
	track_frame.add_theme_stylebox_override("panel", _panel(Color("#8b633a"), GOLD, 20, 3))
	root.add_child(track_frame)

	track = Control.new()
	track.name = "RaceTrack"
	track.custom_minimum_size.y = 312
	track.clip_contents = true
	track_frame.add_child(track)

	var ground := ColorRect.new()
	ground.color = TRACK
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(ground)

	var inner := Panel.new()
	inner.anchor_left = 0.035
	inner.anchor_right = 0.965
	inner.anchor_top = 0.16
	inner.anchor_bottom = 0.86
	inner.add_theme_stylebox_override("panel", _panel(TRACK_LIGHT, Color("#b18145"), 18, 2))
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(inner)

	var course_band := ColorRect.new()
	course_band.color = Color("#c28f4e")
	course_band.anchor_left = 0.065
	course_band.anchor_right = 0.935
	course_band.anchor_top = 0.50
	course_band.anchor_bottom = 0.50
	course_band.offset_top = -18
	course_band.offset_bottom = 18
	course_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(course_band)

	_add_edge_flag("START", 0.018, Color("#4b8a4d"))
	_add_edge_flag("GOAL", 0.895, RED)
	_add_track_marker(5, "火\n-2", Color("#d75135"))
	_add_track_marker(10, "水\n+3", Color("#3e8db8"))
	_add_track_marker(15, "丸\n4+", Color("#765334"))
	_add_track_marker(20, "火\n-2", Color("#d75135"))

	for racer_id: String in RaceScript.RACERS:
		var marker := _make_racer_marker(racer_id)
		track.add_child(marker)
		racer_nodes[racer_id] = marker
	track.resized.connect(_refresh_track)

func _add_edge_flag(text: String, x_anchor: float, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = x_anchor
	panel.anchor_right = x_anchor
	panel.anchor_top = 0.035
	panel.offset_right = 74
	panel.offset_bottom = 40
	panel.add_theme_stylebox_override("panel", _panel(color, Color("#f7d06b"), 9, 2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := _label(text, 13, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	track.add_child(panel)

func _make_racer_marker(racer_id: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Racer_%s" % racer_id
	panel.custom_minimum_size = Vector2(86, 58)
	panel.size = Vector2(86, 58)
	panel.z_index = 5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel(Color(1, 0.94, 0.79, 0.97), RACER_COLORS[racer_id], 13, 3))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 2)
	panel.add_child(row)
	var art := _racer_art(racer_id)
	if art != null:
		var portrait := TextureRect.new()
		portrait.texture = art
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(52, 48)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
	else:
		var fallback := _label(RACER_SHORT[racer_id], 17, Color.WHITE)
		fallback.custom_minimum_size = Vector2(42, 42)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_stylebox_override("normal", _panel(RACER_COLORS[racer_id], RACER_COLORS[racer_id].lightened(0.25), 21, 1))
		row.add_child(fallback)
	var name := _label(RACER_LABELS[racer_id], 11, INK)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name)
	return panel

func _racer_art(racer_id: String) -> Texture2D:
	var path := str(RACER_ART_PATHS.get(racer_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _build_ranking(root: VBoxContainer) -> void:
	var ranking_panel := PanelContainer.new()
	ranking_panel.add_theme_stylebox_override("panel", _panel(Color("#28223e"), Color("#775d94"), 13, 2))
	root.add_child(ranking_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	ranking_panel.add_child(row)
	for i in 3:
		var place := PanelContainer.new()
		place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var border := [GOLD, Color("#c8cbd1"), Color("#c98754")][i]
		place.add_theme_stylebox_override("panel", _panel(Color("#3b3152"), border, 10, 2))
		var label := _label("%d位 -" % (i + 1), 14, Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		place.add_child(label)
		ranking_cards.append(label)
		row.add_child(place)
	ranking_label = _label("", 1, Color.TRANSPARENT)
	ranking_label.visible = false
	root.add_child(ranking_label)

func _build_dice_console(root: VBoxContainer) -> void:
	var console := PanelContainer.new()
	console.custom_minimum_size.y = 210
	console.add_theme_stylebox_override("panel", _panel(NAVY_2, Color("#695b9c"), 18, 2))
	root.add_child(console)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	console.add_child(box)

	target_value_label = _label("アヒルを狙え", 18, GOLD_LIGHT)
	target_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(target_value_label)

	var middle := HBoxContainer.new()
	middle.add_theme_constant_override("separation", 8)
	box.add_child(middle)

	var left_grid := GridContainer.new()
	left_grid.columns = 1
	left_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(left_grid)
	for racer_id: String in ["fox", "rabbit", "duck"]:
		left_grid.add_child(_make_assignment_card(racer_id))

	var die := PanelContainer.new()
	die.custom_minimum_size = Vector2(118, 118)
	die.add_theme_stylebox_override("panel", _panel(Color("#fff5df"), GOLD, 25, 4))
	die_face_label = _label("?", 60, Color("#2d211a"))
	die_face_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	die_face_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	die.add_child(die_face_label)
	middle.add_child(die)

	var right_grid := GridContainer.new()
	right_grid.columns = 1
	right_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(right_grid)
	for racer_id: String in ["dinosaur", "camel", "robot"]:
		right_grid.add_child(_make_assignment_card(racer_id))

	assignment_label = _label("ROLLすると6体へ1〜6が一度ずつ配られる", 13, Color("#d8d3ef"))
	assignment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	assignment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(assignment_label)

func _make_assignment_card(racer_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 42
	panel.add_theme_stylebox_override("panel", _panel(Color("#f6e9ce"), Color("#8b735d"), 10, 1))
	var label := _label("%s  ?" % RACER_LABELS[racer_id], 13, INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	assignment_cards[racer_id] = {"panel": panel, "label": label}
	return panel

func _build_bet_panel(root: VBoxContainer) -> void:
	bet_panel = VBoxContainer.new()
	bet_panel.add_theme_constant_override("separation", 6)
	root.add_child(bet_panel)
	var racer_grid := GridContainer.new()
	racer_grid.columns = 3
	racer_grid.add_theme_constant_override("h_separation", 5)
	racer_grid.add_theme_constant_override("v_separation", 5)
	bet_panel.add_child(racer_grid)
	for racer_id: String in RaceScript.RACERS:
		var button := _button(RACER_LABELS[racer_id])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_racer.bind(racer_id))
		racer_grid.add_child(button)
		racer_buttons[racer_id] = button
	var amount_row := HBoxContainer.new()
	amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_row.add_theme_constant_override("separation", 8)
	bet_panel.add_child(amount_row)
	for amount: int in BET_AMOUNTS:
		var button := _button("%d CHIP" % amount)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_bet.bind(amount))
		amount_row.add_child(button)
		amount_buttons[amount] = button
	start_button = _button("RACE START", true)
	start_button.name = "RaceStartButton"
	start_button.custom_minimum_size.y = 56
	start_button.pressed.connect(_start_race)
	bet_panel.add_child(start_button)

func _build_cashout(root: VBoxContainer) -> void:
	cashout_row = HBoxContainer.new()
	cashout_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cashout_row.add_theme_constant_override("separation", 8)
	cashout_row.visible = false
	root.add_child(cashout_row)
	cashout_label = _label("", 16, GOLD_LIGHT)
	cashout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cashout_row.add_child(cashout_label)
	cashout_button = _button("CASH OUT")
	cashout_button.pressed.connect(_take_cashout)
	cashout_row.add_child(cashout_button)
	ride_on_button = _button("RIDE ON!", true)
	ride_on_button.pressed.connect(_ride_on)
	cashout_row.add_child(ride_on_button)

func _show_bet_select() -> void:
	race = RaceScript.new_race()
	spinning = false
	wager_committed = false
	result_recorded = false
	current_assignments.clear()
	bet_panel.visible = true
	cashout_row.visible = false
	roll_button.visible = false
	status_label.text = "勝たせたいレーサーを選ぼう"
	_refresh_bet_buttons()
	_refresh_all()

func _select_racer(racer_id: String) -> void:
	selected_racer = racer_id
	_refresh_bet_buttons()
	_refresh_assignment_ui()

func _select_bet(amount: int) -> void:
	selected_bet = amount
	_refresh_bet_buttons()

func _refresh_bet_buttons() -> void:
	var chips := CasinoBankScript.balance()
	for racer_id: String in racer_buttons:
		var button := racer_buttons[racer_id] as Button
		button.disabled = false
		button.text = ("● " if racer_id == selected_racer else "") + RACER_LABELS[racer_id]
		_apply_button_state(button, racer_id == selected_racer)
	for amount: int in amount_buttons:
		var button := amount_buttons[amount] as Button
		button.disabled = chips < amount
		button.text = ("● " if amount == selected_bet else "") + "%d CHIP" % amount
		_apply_button_state(button, amount == selected_bet)
	start_button.disabled = chips < selected_bet
	if start_button.disabled:
		status_label.text = "CHIPが足りない。通常ステージでCOINを持ち帰ろう。"

func _start_race() -> void:
	if not CasinoBankScript.spend_chips(selected_bet):
		_refresh_bet_buttons()
		return
	race = RaceScript.new_race(selected_racer, selected_bet)
	wager_committed = true
	result_recorded = false
	bet_panel.visible = false
	roll_button.visible = true
	roll_button.disabled = false
	cashout_row.visible = false
	status_label.text = "%sに%d CHIP。欲しい目を狙ってSTOP！" % [RACER_LABELS[selected_racer], selected_bet]
	spin_elapsed = randf() * SPIN_STEP_SECONDS * float(maxi(orientations.size(), 1))
	orientation_index = int(floor(spin_elapsed / SPIN_STEP_SECONDS)) % maxi(orientations.size(), 1)
	current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
	_refresh_all()

func _on_roll_stop() -> void:
	if not wager_committed or bool(race.get("finished", false)):
		return
	if not spinning:
		spinning = true
		roll_button.text = "STOP!"
		status_label.text = "%sに欲しい数字を狙え！" % RACER_LABELS[selected_racer]
		return
	spinning = false
	roll_button.text = "ROLL"
	current_assignments = OrientationScript.values_for_racers(orientations[orientation_index])
	var was_photo_finish := not (race.get("photo_finish_candidates", []) as Array).is_empty()
	race = RaceScript.apply_roll(race, current_assignments)
	status_label.text = "PHOTO FINISH判定！" if was_photo_finish else _movement_summary()
	_refresh_all()
	_after_roll_resolution()

func _after_roll_resolution() -> void:
	if bool(race.get("finished", false)):
		_finish_race()
		return
	var photo: Array = race.get("photo_finish_candidates", [])
	if not photo.is_empty():
		status_label.text = "PHOTO FINISH！ 同着レーサーの数字で決着。"
		return
	if bool(race.get("cashout_offered", false)):
		cashout_row.visible = true
		roll_button.disabled = true
		cashout_label.text = "3投終了　今なら %d CHIP" % int(race.get("cashout_amount", 0))
		status_label.text = "降りる？ それとも優勝まで乗る？"

func _take_cashout() -> void:
	var amount := RaceScript.cashout_offer(race)
	race = RaceScript.take_cashout(race)
	CasinoBankScript.add_chips(amount)
	cashout_row.visible = false
	roll_button.disabled = false
	status_label.text = "%d CHIPでCASH OUT。レースは最後まで見届けよう。" % amount
	_refresh_all()

func _ride_on() -> void:
	race = RaceScript.ride_on(race)
	cashout_row.visible = false
	roll_button.disabled = false
	status_label.text = "RIDE ON！ 優勝なら%d CHIP。" % int(round(float(selected_bet) * RaceScript.WIN_MULTIPLIER))

func _finish_race() -> void:
	spinning = false
	roll_button.disabled = true
	var winner := str(race.get("winner", ""))
	var payout := RaceScript.winning_payout(race)
	if payout > 0:
		CasinoBankScript.add_chips(payout)
		status_label.text = "%s WIN！ %d CHIP獲得！" % [RACER_LABELS.get(winner, winner), payout]
	elif bool(race.get("cashout_taken", false)):
		status_label.text = "%s WIN。CASH OUT済み。" % RACER_LABELS.get(winner, winner)
	else:
		status_label.text = "%s WIN。次は当てよう！" % RACER_LABELS.get(winner, winner)
	if not result_recorded:
		CasinoBankScript.record_dice_race(winner == selected_racer and payout > 0, payout)
		result_recorded = true
	roll_button.text = "もう一度"
	roll_button.disabled = false
	if roll_button.pressed.is_connected(_on_roll_stop):
		roll_button.pressed.disconnect(_on_roll_stop)
	roll_button.pressed.connect(_restart_after_result, CONNECT_ONE_SHOT)
	_refresh_all()

func _restart_after_result() -> void:
	if not roll_button.pressed.is_connected(_on_roll_stop):
		roll_button.pressed.connect(_on_roll_stop)
	roll_button.text = "ROLL"
	_show_bet_select()

func _movement_summary() -> String:
	var move: Dictionary = (race.get("last_movements", {}) as Dictionary).get(selected_racer, {})
	var rolled := int(move.get("rolled", 0))
	var effective := int(move.get("effective", 0))
	var gimmick := str(move.get("gimmick", ""))
	var extra := ""
	match gimmick:
		"foxfire": extra = "　狐火！次は-2"
		"rapid": extra = "　急流で+3！"
		"log": extra = "　丸太！次は4以上で突破"
	if bool(move.get("blocked_by_log", false)):
		extra = "　丸太でSTOP"
	return "%s：%d → %dマス%s" % [RACER_LABELS[selected_racer], rolled, effective, extra]

func _refresh_all() -> void:
	chip_label.text = "CHIP  %d" % CasinoBankScript.balance()
	bet_label.text = "%s  %d" % [RACER_LABELS.get(selected_racer, selected_racer), selected_bet] if wager_committed else "-"
	roll_count_label.text = "%d / 6" % int(race.get("roll_count", 0))
	var payout := RaceScript.winning_payout(race)
	win_label.text = "%d" % payout if payout > 0 else ("×4" if wager_committed else "-")
	_refresh_assignment_ui()
	_refresh_ranking()
	call_deferred("_refresh_track")

func _refresh_assignment_ui() -> void:
	if current_assignments.is_empty():
		target_value_label.text = "%sを狙え" % RACER_LABELS[selected_racer]
		die_face_label.text = "?"
		assignment_label.text = "ROLLすると6体へ1〜6が一度ずつ配られる"
		for racer_id: String in assignment_cards:
			_update_assignment_card(racer_id, 0)
		return
	var target_value := int(current_assignments.get(selected_racer, 0))
	target_value_label.text = "%s ← %d" % [RACER_LABELS[selected_racer], target_value]
	die_face_label.text = str(target_value)
	for racer_id: String in RaceScript.RACERS:
		_update_assignment_card(racer_id, int(current_assignments.get(racer_id, 0)))
	assignment_label.text = "STOPした瞬間の向きで6体すべての出目が決まる"

func _update_assignment_card(racer_id: String, value: int) -> void:
	if not assignment_cards.has(racer_id):
		return
	var entry: Dictionary = assignment_cards[racer_id]
	var panel := entry.panel as PanelContainer
	var label := entry.label as Label
	label.text = "%s  %s" % [RACER_LABELS[racer_id], "?" if value <= 0 else str(value)]
	var selected := racer_id == selected_racer
	panel.add_theme_stylebox_override("panel", _panel(Color("#fff0cf") if selected else Color("#f1e4cf"), GOLD if selected else Color("#806d5d"), 10, 3 if selected else 1))

func _refresh_ranking() -> void:
	if race.is_empty():
		return
	var ordered: Array[String] = RaceScript.ranking(race)
	var plain_parts: Array[String] = []
	for i in 3:
		if i >= ordered.size():
			break
		var id := ordered[i]
		var pos := int((race.racers.get(id, {}) as Dictionary).get("position", 0))
		var text := "%d位 %s  %d" % [i + 1, RACER_LABELS[id], pos]
		plain_parts.append(text)
		if i < ranking_cards.size():
			ranking_cards[i].text = text
	ranking_label.text = " / ".join(plain_parts)

func _refresh_track() -> void:
	if not is_instance_valid(track) or track.size.x <= 0.0:
		return
	var left := track.size.x * 0.075
	var usable := track.size.x * 0.84
	var center_y := track.size.y * 0.52
	var y_offsets := [-112.0, -68.0, -24.0, 20.0, 64.0, 108.0]
	for i in RaceScript.RACERS.size():
		var id: String = RaceScript.RACERS[i]
		var marker := racer_nodes.get(id) as Control
		if not is_instance_valid(marker):
			continue
		var pos := 0
		if not race.is_empty():
			pos = int((race.racers.get(id, {}) as Dictionary).get("position", 0))
		var progress := clampf(float(pos) / float(RaceScript.GOAL), 0.0, 1.0)
		marker.position = Vector2(left + usable * progress - 43.0, center_y + y_offsets[i] - 29.0)
		marker.modulate = Color.WHITE if id != selected_racer or not wager_committed else Color("#fff7cf")

func _add_track_marker(space: int, text: String, color: Color) -> void:
	var panel := PanelContainer.new()
	var anchor := 0.075 + 0.84 * (float(space) / float(RaceScript.GOAL))
	panel.anchor_left = anchor
	panel.anchor_right = anchor
	panel.anchor_top = 0.04
	panel.offset_left = -26
	panel.offset_right = 26
	panel.offset_bottom = 54
	panel.z_index = 3
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel(color, Color("#fff0b8"), 12, 2))
	var label := _label(text, 12, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	track.add_child(panel)

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
	button.add_theme_font_size_override("font_size", 15)
	button.custom_minimum_size = Vector2(90, 42)
	button.add_theme_color_override("font_color", INK if primary else Color("#fff4dc"))
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel(GOLD if primary else Color("#403452"), Color("#a67836") if primary else Color("#705e84"), 12, 2))
	button.add_theme_stylebox_override("hover", _panel(GOLD_LIGHT if primary else Color("#51436a"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel(Color("#d99d2c") if primary else Color("#302641"), GOLD, 12, 2))
	button.add_theme_stylebox_override("disabled", _panel(Color("#777064"), Color("#5e584f"), 12, 1))
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
