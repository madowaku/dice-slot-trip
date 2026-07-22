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

func _ready() -> void:
	for face in range(1, 7):
		get_node("%Roll" + str(face)).pressed.connect(func(): roll_for_test(face))
	hop_button.pressed.connect(hop_for_test)
	mainline_button.pressed.connect(func(): choose_branch_for_test("mainline"))
	bypass_button.pressed.connect(func(): choose_branch_for_test("bypass"))
	%SkillButton.pressed.connect(_toggle_skill)
	_refresh()

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
