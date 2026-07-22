class_name V1PlayScreen
extends Control

const Session = preload("res://scripts/game/v1_play_session.gd")

var session = Session.new()
var _display_path: Array = []
var _display_path_index := 0
var _last_receipt: Dictionary = {}

@onready var phase_label: Label = %PhaseLabel
@onready var position_label: Label = %PositionLabel
@onready var slot_label: Label = %SlotLabel
@onready var economy_label: Label = %EconomyLabel
@onready var race_label: Label = %RaceLabel
@onready var result_label: Label = %ResultLabel
@onready var hop_button: Button = %HopButton
@onready var mainline_button: Button = %MainlineButton
@onready var bypass_button: Button = %BypassButton
@onready var footer_hint: Label = %FooterHint

const INK := Color("#f8edcf")
const MUTED_INK := Color("#b8d8d0")
const TEAL := Color("#123a42")
const TEAL_DARK := Color("#0a252d")
const SAND := Color("#d59f55")
const GOLD := Color("#f1c86b")

func _ready() -> void:
	for face in range(1, 7):
		get_node("%Roll" + str(face)).pressed.connect(func(): roll_for_test(face))
	hop_button.pressed.connect(hop_for_test)
	mainline_button.pressed.connect(func(): choose_branch_for_test("mainline"))
	bypass_button.pressed.connect(func(): choose_branch_for_test("bypass"))
	%SkillButton.pressed.connect(_toggle_skill)
	_apply_mobile_theme()
	_refresh()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _apply_mobile_theme() -> void:
	var labels := [
		get_node("Margin/Column/Title"), phase_label, position_label, slot_label,
		economy_label, race_label, result_label, get_node("Margin/Column/RollCaption")
	]
	for label in labels:
		label.add_theme_color_override("font_color", INK)
	phase_label.add_theme_color_override("font_color", GOLD)
	result_label.add_theme_color_override("font_color", GOLD)
	for button in [
		get_node("%Roll1"), get_node("%Roll2"), get_node("%Roll3"),
		get_node("%Roll4"), get_node("%Roll5"), get_node("%Roll6"),
		hop_button, mainline_button, bypass_button, %SkillButton
	]:
		_style_mobile_button(button)
	footer_hint.add_theme_color_override("font_color", MUTED_INK)

func _style_mobile_button(button: Button) -> void:
	button.add_theme_color_override("font_color", TEAL)
	button.add_theme_color_override("font_hover_color", TEAL)
	button.add_theme_color_override("font_pressed_color", TEAL_DARK)
	button.add_theme_color_override("font_disabled_color", Color("#75918d"))
	button.add_theme_font_size_override("font_size", 26 if button == hop_button or button == %SkillButton else 30)
	var is_face_button := button.name.begins_with("Roll")
	button.custom_minimum_size = Vector2(82 if is_face_button else 0, 74 if button == hop_button or button == %SkillButton else 68)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.corner_radius_top_left = 18
		box.corner_radius_top_right = 18
		box.corner_radius_bottom_left = 18
		box.corner_radius_bottom_right = 18
		box.border_width_left = 2
		box.border_width_top = 2
		box.border_width_right = 2
		box.border_width_bottom = 2
		box.border_color = GOLD if state != "disabled" else Color("#496b6b")
		box.bg_color = Color("#f6e5bd") if state == "normal" else (Color("#ffe9a8") if state == "hover" else (Color("#d8b36a") if state == "pressed" else Color("#29494d")))
		box.shadow_color = Color(0, 0, 0, 0.32)
		box.shadow_size = 6 if state == "normal" else 2
		button.add_theme_stylebox_override(state, box)

func _draw() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var width := viewport_size.x
	var height := viewport_size.y
	draw_rect(Rect2(Vector2.ZERO, viewport_size), TEAL_DARK)
	draw_rect(Rect2(0, height * 0.46, width, height * 0.54), Color("#17454a"))
	# Warm horizon and distant Cairo silhouettes make the lower screen feel like the board.
	draw_circle(Vector2(width * 0.82, height * 0.53), min(width, height) * 0.055, Color("#f0bd66", 0.8))
	for index in range(7):
		var skyline_x := width * (0.08 + index * 0.14)
		var skyline_height := height * (0.035 + (index % 3) * 0.018)
		draw_rect(Rect2(skyline_x, height * 0.59 - skyline_height, width * 0.1, skyline_height), Color("#102f37"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, height * 0.62), Vector2(width * 0.18, height * 0.55),
		Vector2(width * 0.34, height * 0.62), Vector2(width * 0.53, height * 0.54),
		Vector2(width * 0.72, height * 0.62), Vector2(width, height * 0.56),
		Vector2(width, height * 0.7), Vector2(0, height * 0.7)
	]), Color("#c9894f", 0.72))
	# A simple route board with marked hops and a central oasis.
	var board_rect := Rect2(width * 0.08, height * 0.72, width * 0.84, height * 0.13)
	var board := StyleBoxFlat.new()
	board.bg_color = Color("#0b3038", 0.92)
	board.border_color = Color("#e2b962", 0.7)
	board.set_border_width_all(2)
	board.set_corner_radius_all(22)
	draw_style_box(board, board_rect)
	draw_line(Vector2(board_rect.position.x + 28, board_rect.position.y + board_rect.size.y * 0.5), Vector2(board_rect.end.x - 28, board_rect.position.y + board_rect.size.y * 0.5), Color("#e2b962", 0.45), 5.0)
	for index in range(9):
		var point := Vector2(board_rect.position.x + 34 + index * (board_rect.size.x - 68) / 8.0, board_rect.position.y + board_rect.size.y * 0.5)
		draw_circle(point, 13.0, GOLD if index == 0 else Color("#76a99b"))
		draw_circle(point, 5.0, TEAL_DARK)
	draw_circle(Vector2(width * 0.5, height * 0.91), width * 0.075, Color("#58a89b", 0.3))
	draw_circle(Vector2(width * 0.5, height * 0.91), width * 0.04, Color("#8ed0ae", 0.55))

func session_for_test():
	return session

func roll_for_test(face: int) -> Dictionary:
	var receipt: Dictionary = session.play_boss_roll(face) if session.race != null else session.play_stage_roll(face)
	_present(receipt)
	return receipt

func choose_branch_for_test(choice: String) -> Dictionary:
	var receipt: Dictionary = session.choose_stage_branch(choice)
	_present(receipt)
	return receipt

func hop_for_test() -> String:
	if _display_path_index < _display_path.size():
		_display_path_index += 1
	_refresh()
	return _display_position()

func reset_for_test() -> void:
	session.reset_stage()
	_last_receipt = {}
	_display_path = []
	_display_path_index = 0
	_refresh()

func _present(receipt: Dictionary) -> void:
	_last_receipt = receipt
	_display_path = receipt.get("movement", {}).get("path", []).duplicate()
	_display_path_index = 0
	_refresh()

func _toggle_skill() -> void:
	session.skill.toggle_arm()
	_refresh()

func _display_position() -> String:
	if _display_path_index > 0 and _display_path_index <= _display_path.size():
		return str(_display_path[_display_path_index - 1])
	return session.stage_position

func _refresh() -> void:
	var in_boss := session.race != null
	var branch_pending: bool = not session.pending_stage_movement.is_empty()
	phase_label.text = "RESULT" if not session.result().is_empty() else ("BOSS RACE" if in_boss else ("BRANCH" if branch_pending else "STAGE"))
	position_label.text = "Position: %s" % _display_position()
	var faces: Array[int] = session.slot.faces()
	var shown: Array[String] = []
	for index in range(3):
		shown.append(str(faces[index]) if index < faces.size() else "-")
	slot_label.text = "3 ROLL SLOT: [%s]" % ", ".join(shown)
	economy_label.text = "Gauge: %d/3   Coins: %d   Skill: %s" % [session.skill.gauge, session.coins, session.skill.State.keys()[session.skill.state]]
	if in_boss:
		race_label.text = "Player %d/13   Boss %d/13   Turn %d" % [session.race.player_position, session.race.boss_position, session.race.turn_count]
	else:
		race_label.text = "Boss race starts at main_58"
	var result: Dictionary = session.result()
	result_label.text = "" if result.is_empty() else "Winner: %s (%s)" % [result.winner, result.win_reason]
	hop_button.disabled = _display_path_index >= _display_path.size()
	mainline_button.visible = branch_pending
	bypass_button.visible = branch_pending
	%SkillButton.text = "Explorer Skill: %s" % session.skill.State.keys()[session.skill.state]
	if not result.is_empty():
		footer_hint.text = "Trip complete · tap Reset in the next build"
	elif in_boss:
		footer_hint.text = "Boss race · choose a face to move"
	elif branch_pending:
		footer_hint.text = "Choose a route before the next hop"
	else:
		footer_hint.text = "Tap a die face · then reveal the next hop"
	queue_redraw()
