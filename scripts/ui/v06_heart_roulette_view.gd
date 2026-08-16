class_name V06HeartRouletteView
extends Control

const NORMAL_FILL := Color(0.015, 0.085, 0.09, 0.78)
const NORMAL_BORDER := Color(0.88, 0.70, 0.34, 0.78)
const SELECTED_FILL := Color(0.58, 0.16, 0.22, 0.94)
const SELECTED_BORDER := Color("#ffe2a0")
const NORMAL_TEXT := Color("#fff0c5")
const SELECTED_TEXT := Color("#ffffff")

@onready var wheel_stage: Control = %HeartRouletteWheelStage
@onready var wheel: TextureRect = %HeartRouletteWheel
@onready var sparkle: TextureRect = %HeartRouletteSparkle
@onready var title_label: Label = %HeartRouletteLabel
@onready var hint_label: Label = %HeartRouletteHintLabel
@onready var current_label: Label = %HeartRouletteCurrentLabel
@onready var option_panels: Array[PanelContainer] = [
	%HeartOption0,
	%HeartOption1,
	%HeartOption2,
	%HeartOption3,
	%HeartOption4,
	%HeartOption5,
]
@onready var option_labels: Array[Label] = [
	%HeartOptionLabel0,
	%HeartOptionLabel1,
	%HeartOptionLabel2,
	%HeartOptionLabel3,
	%HeartOptionLabel4,
	%HeartOptionLabel5,
]

var _options: Array[int] = []
var _selected_index := -1
var _mode := "hidden"
var _selection_tween: Tween
var _reward_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	_set_options([1, 2, 1, 3, 1, 0])
	_apply_selection(-1, false)
	sparkle.hide()
	hide()


func show_pending(options: Array[int], selected_index: int) -> void:
	_set_options(options)
	_mode = "pending"
	wheel_stage.show()
	title_label.text = "HP RECOVERY"
	hint_label.text = "光る結果でHP回復"
	sparkle.hide()
	modulate = Color.WHITE
	show()
	_apply_selection(selected_index, selected_index != _selected_index)


func show_result(options: Array[int], selected_index: int, result_label: String, hearts_text: String) -> void:
	var should_reveal := _mode != "result" or _selected_index != selected_index
	_set_options(options)
	_mode = "result"
	wheel_stage.show()
	title_label.text = "HP RECOVERY"
	hint_label.text = "%s　%s" % [result_label, hearts_text]
	show()
	_apply_selection(selected_index, false)
	if should_reveal:
		_play_reward_reveal()


func show_perfect() -> void:
	_mode = "perfect"
	_selected_index = -1
	wheel_stage.hide()
	title_label.text = "PERFECT!"
	hint_label.text = "HP FULL"
	show()


func hide_view() -> void:
	_mode = "hidden"
	if _selection_tween != null:
		_selection_tween.kill()
		_selection_tween = null
	if _reward_tween != null:
		_reward_tween.kill()
		_reward_tween = null
	sparkle.hide()
	hide()


func _set_options(options: Array[int]) -> void:
	_options = options.duplicate()
	for index: int in range(option_labels.size()):
		option_labels[index].text = _value_text(_options[index]) if index < _options.size() else ""
		option_panels[index].visible = index < _options.size()


func _apply_selection(selected_index: int, animate: bool) -> void:
	var previous_index := _selected_index
	_selected_index = clampi(selected_index, 0, _options.size() - 1) if not _options.is_empty() and selected_index >= 0 else -1
	if _selection_tween != null:
		_selection_tween.kill()
		_selection_tween = null
	for index: int in range(option_panels.size()):
		var selected := index == _selected_index
		var panel := option_panels[index]
		var label := option_labels[index]
		panel.add_theme_stylebox_override("panel", _chip_style(selected))
		panel.scale = Vector2.ONE
		panel.pivot_offset = panel.size * 0.5
		panel.z_index = 4 if selected else 2
		label.add_theme_color_override("font_color", SELECTED_TEXT if selected else NORMAL_TEXT)
		label.add_theme_color_override("font_outline_color", Color("#37151b") if selected else Color("#071b1e"))
		label.add_theme_constant_override("outline_size", 7 if selected else 5)
	if _selected_index >= 0:
		current_label.text = _value_text(_options[_selected_index])
		current_label.add_theme_color_override("font_color", Color("#fff5dd"))
		if animate and previous_index != _selected_index:
			var selected_panel := option_panels[_selected_index]
			selected_panel.scale = Vector2.ONE * 1.22
			current_label.scale = Vector2.ONE * 1.12
			current_label.pivot_offset = current_label.size * 0.5
			_selection_tween = create_tween().set_parallel(true)
			_selection_tween.tween_property(selected_panel, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_selection_tween.tween_property(current_label, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		current_label.text = ""


func _play_reward_reveal() -> void:
	if _reward_tween != null:
		_reward_tween.kill()
	_reward_tween = create_tween().set_parallel(true)
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 0.96
	sparkle.pivot_offset = sparkle.size * 0.5
	sparkle.scale = Vector2.ONE * 0.72
	sparkle.modulate.a = 0.0
	sparkle.show()
	_reward_tween.tween_property(self, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reward_tween.tween_property(sparkle, "scale", Vector2.ONE * 1.05, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reward_tween.tween_property(sparkle, "modulate:a", 0.88, 0.14)
	_reward_tween.chain().tween_property(sparkle, "modulate:a", 0.34, 0.28)


func _chip_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SELECTED_FILL if selected else NORMAL_FILL
	style.border_color = SELECTED_BORDER if selected else NORMAL_BORDER
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


func _value_text(value: int) -> String:
	if value == 3:
		return "Full"
	if value > 0:
		return "+%d" % value
	if value < 0:
		return "−%d" % absi(value)
	return "0"


func visual_receipt() -> Dictionary:
	var selected_text := ""
	var option_texts: Array[String] = []
	for label: Label in option_labels:
		option_texts.append(label.text)
	if _selected_index >= 0 and _selected_index < option_labels.size():
		selected_text = option_labels[_selected_index].text
	return {
		"visible": visible,
		"wheel_visible": wheel_stage.visible,
		"wheel_texture": wheel.texture.resource_path if wheel.texture != null else "",
		"option_count": _options.size(),
		"option_texts": option_texts,
		"selected_index": _selected_index,
		"selected_text": selected_text,
		"title": title_label.text,
		"hint": hint_label.text,
		"current": current_label.text,
	}
