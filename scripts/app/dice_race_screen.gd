class_name DiceRaceScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const OrientationScript = preload("res://scripts/game/dice_race_orientation.gd")
const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const RACER_LABELS := {
	"camel": "ラクダ",
	"crocodile": "ワニ",
	"fox": "キツネ",
	"duck": "アヒル",
	"dinosaur": "恐竜",
	"robot": "ロボット",
}
const RACER_MARKS := {
	"camel": "C",
	"crocodile": "W",
	"fox": "F",
	"duck": "A",
	"dinosaur": "D",
	"robot": "R",
}
const BET_AMOUNTS := [10, 20, 50]
const SPIN_STEP_SECONDS := 0.085

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
var status_label: Label
var ranking_label: Label
var assignment_label: Label
var target_value_label: Label
var track: Control
var racer_nodes := {}
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
	bg.color = Color("#24182f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := _label("DICE RACE", 34, Color("#ffd66b"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	chip_label = _label("", 21, Color.WHITE)
	header.add_child(chip_label)

	var sub := HBoxContainer.new()
	root.add_child(sub)
	bet_label = _label("BET -", 18, Color("#f4dfb0"))
	bet_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(bet_label)
	roll_count_label = _label("ROLL 0", 18, Color("#f4dfb0"))
	sub.add_child(roll_count_label)

	track = Control.new()
	track.name = "RaceTrack"
	track.custom_minimum_size.y = 360
	track.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track.clip_contents = true
	root.add_child(track)
	var track_bg := ColorRect.new()
	track_bg.color = Color("#d8b97a")
	track_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(track_bg)
	var track_line := ColorRect.new()
	track_line.color = Color("#5f412e")
	track_line.anchor_left = 0.06
	track_line.anchor_right = 0.94
	track_line.anchor_top = 0.52
	track_line.anchor_bottom = 0.52
	track_line.offset_top = -4
	track_line.offset_bottom = 4
	track.add_child(track_line)
	_add_track_marker(5, "狐火 -2", Color("#d45b4f"))
	_add_track_marker(10, "急流 +3", Color("#4e9ac7"))
	_add_track_marker(15, "丸太", Color("#79583c"))
	_add_track_marker(20, "狐火 -2", Color("#d45b4f"))
	_add_track_marker(24, "GOAL", Color("#e6b942"))
	for racer_id: String in RaceScript.RACERS:
		var marker := Label.new()
		marker.text = "%s %s" % [RACER_MARKS[racer_id], RACER_LABELS[racer_id]]
		marker.add_theme_font_override("font", FONT)
		marker.add_theme_font_size_override("font_size", 18)
		marker.add_theme_color_override("font_color", Color("#21180f"))
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.custom_minimum_size = Vector2(88, 34)
		marker.z_index = 4
		track.add_child(marker)
		racer_nodes[racer_id] = marker
	track.resized.connect(_refresh_track)

	ranking_label = _label("", 18, Color("#fff0c8"))
	ranking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(ranking_label)

	var dice_panel := PanelContainer.new()
	dice_panel.custom_minimum_size.y = 176
	dice_panel.add_theme_stylebox_override("panel", _panel(Color("#36234a"), Color("#8e6ab3"), 16, 2))
	root.add_child(dice_panel)
	var dice_box := VBoxContainer.new()
	dice_box.add_theme_constant_override("separation", 4)
	dice_panel.add_child(dice_box)
	target_value_label = _label("アヒル ← ?", 40, Color("#ffd66b"))
	target_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_box.add_child(target_value_label)
	assignment_label = _label("", 15, Color("#f5e8ff"))
	assignment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	assignment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dice_box.add_child(assignment_label)

	status_label = _label("賭けるレーサーを選ぼう", 18, Color.WHITE)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status_label)

	bet_panel = VBoxContainer.new()
	bet_panel.add_theme_constant_override("separation", 6)
	root.add_child(bet_panel)
	var racer_row := HBoxContainer.new()
	racer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	racer_row.add_theme_constant_override("separation", 4)
	bet_panel.add_child(racer_row)
	for racer_id: String in RaceScript.RACERS:
		var button := _button(RACER_LABELS[racer_id])
		button.pressed.connect(_select_racer.bind(racer_id))
		racer_row.add_child(button)
		racer_buttons[racer_id] = button
	var amount_row := HBoxContainer.new()
	amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amount_row.add_theme_constant_override("separation", 8)
	bet_panel.add_child(amount_row)
	for amount: int in BET_AMOUNTS:
		var button := _button("%d CHIP" % amount)
		button.pressed.connect(_select_bet.bind(amount))
		amount_row.add_child(button)
		amount_buttons[amount] = button
	start_button = _button("RACE START")
	start_button.custom_minimum_size.y = 54
	start_button.pressed.connect(_start_race)
	bet_panel.add_child(start_button)

	cashout_row = HBoxContainer.new()
	cashout_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cashout_row.add_theme_constant_override("separation", 8)
	cashout_row.visible = false
	root.add_child(cashout_row)
	cashout_label = _label("", 18, Color("#ffd66b"))
	cashout_row.add_child(cashout_label)
	cashout_button = _button("CASH OUT")
	cashout_button.pressed.connect(_take_cashout)
	cashout_row.add_child(cashout_button)
	ride_on_button = _button("RIDE ON!")
	ride_on_button.pressed.connect(_ride_on)
	cashout_row.add_child(ride_on_button)

	roll_button = _button("ROLL")
	roll_button.custom_minimum_size.y = 72
	roll_button.add_theme_font_size_override("font_size", 28)
	roll_button.pressed.connect(_on_roll_stop)
	root.add_child(roll_button)

	var back := _button("カジノへ戻る")
	back.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back)

func _show_bet_select() -> void:
	race = RaceScript.new_race()
	spinning = false
	wager_committed = false
	result_recorded = false
	bet_panel.visible = true
	cashout_row.visible = false
	roll_button.visible = false
	status_label.text = "賭けるレーサーを選ぼう"
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
		(racer_buttons[racer_id] as Button).disabled = false
		(racer_buttons[racer_id] as Button).text = ("● " if racer_id == selected_racer else "") + RACER_LABELS[racer_id]
	for amount: int in amount_buttons:
		var button := amount_buttons[amount] as Button
		button.disabled = chips < amount
		button.text = ("● " if amount == selected_bet else "") + "%d CHIP" % amount
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
	if was_photo_finish:
		status_label.text = "PHOTO FINISH判定！"
	else:
		status_label.text = _movement_summary()
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
		cashout_label.text = "今なら %d CHIP" % int(race.get("cashout_amount", 0))
		status_label.text = "3投終了。降りる？ それとも優勝まで乗る？"

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
		"foxfire": extra = " 狐火！次は-2"
		"rapid": extra = " 急流で+3！"
		"log": extra = " 丸太！次は4以上で突破"
	if bool(move.get("blocked_by_log", false)):
		extra = " 丸太でSTOP"
	return "%s：%d → %dマス%s" % [RACER_LABELS[selected_racer], rolled, effective, extra]

func _refresh_all() -> void:
	chip_label.text = "CHIP %d" % CasinoBankScript.balance()
	bet_label.text = "BET %s %d" % [RACER_LABELS.get(selected_racer, selected_racer), selected_bet] if wager_committed else "BET -"
	roll_count_label.text = "ROLL %d" % int(race.get("roll_count", 0))
	_refresh_assignment_ui()
	_refresh_ranking()
	call_deferred("_refresh_track")

func _refresh_assignment_ui() -> void:
	if current_assignments.is_empty():
		target_value_label.text = "%s ← ?" % RACER_LABELS[selected_racer]
		assignment_label.text = "ROLLすると6体へ1〜6が一度ずつ配られる"
		return
	target_value_label.text = "%s ← %d" % [RACER_LABELS[selected_racer], int(current_assignments.get(selected_racer, 0))]
	var parts: Array[String] = []
	for racer_id: String in RaceScript.RACERS:
		parts.append("%s:%d" % [RACER_LABELS[racer_id], int(current_assignments.get(racer_id, 0))])
	assignment_label.text = "  /  ".join(parts)

func _refresh_ranking() -> void:
	if race.is_empty():
		ranking_label.text = ""
		return
	var ordered: Array[String] = RaceScript.ranking(race)
	var parts: Array[String] = []
	for i in mini(3, ordered.size()):
		var id := ordered[i]
		var pos := int((race.racers.get(id, {}) as Dictionary).get("position", 0))
		parts.append("%d位 %s %d" % [i + 1, RACER_LABELS[id], pos])
	ranking_label.text = "　　".join(parts)

func _refresh_track() -> void:
	if not is_instance_valid(track) or track.size.x <= 0.0:
		return
	var left := track.size.x * 0.06
	var usable := track.size.x * 0.88
	var center_y := track.size.y * 0.52
	for i in RaceScript.RACERS.size():
		var id: String = RaceScript.RACERS[i]
		var marker := racer_nodes.get(id) as Label
		if not is_instance_valid(marker):
			continue
		var pos := 0
		if not race.is_empty():
			pos = int((race.racers.get(id, {}) as Dictionary).get("position", 0))
		var progress := clampf(float(pos) / float(RaceScript.GOAL), 0.0, 1.0)
		var y_offset := float(i - 2) * 34.0
		marker.position = Vector2(left + usable * progress - 44.0, center_y + y_offset - 17.0)

func _add_track_marker(space: int, text: String, color: Color) -> void:
	var marker := Label.new()
	marker.text = text
	marker.add_theme_font_override("font", FONT)
	marker.add_theme_font_size_override("font_size", 14)
	marker.add_theme_color_override("font_color", color)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.anchor_left = 0.06 + 0.88 * (float(space) / float(RaceScript.GOAL))
	marker.anchor_right = marker.anchor_left
	marker.anchor_top = 0.16
	marker.offset_left = -42
	marker.offset_right = 42
	marker.offset_bottom = 26
	marker.z_index = 2
	track.add_child(marker)

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size = Vector2(88, 42)
	return button

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
