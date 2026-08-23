class_name CasinoHubScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const DICE_RACE_SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const CARD_DATA_PATH := "res://data/casino/prize_cards.json"

var hub_root: Control
var chip_label: Label
var prize_list: VBoxContainer
var race_host: Control
var card_data: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_node("/root/BgmManager").call("play_lasvegas_main")
	card_data = _load_cards()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#17111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hub_root = Control.new()
	hub_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hub_root)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	hub_root.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := _label("LAS VEGAS CASINO", 34, Color("#ffd66b"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	chip_label = _label("CHIP 0", 24, Color.WHITE)
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(chip_label)
	var note := _label("旅で持ち帰ったCASINO CHIPで遊ぼう", 17, Color("#d9c7e8"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(note)

	var race_panel := PanelContainer.new()
	race_panel.add_theme_stylebox_override("panel", _panel(Color("#38264a"), Color("#d8ad4c"), 18, 2))
	root.add_child(race_panel)
	var race_box := VBoxContainer.new()
	race_box.add_theme_constant_override("separation", 8)
	race_panel.add_child(race_box)
	var race_title := _label("DICE RACE", 28, Color("#ffd66b"))
	race_box.add_child(race_title)
	var race_copy := _label("6体に1〜6を配るサイコロレース。\n推しにBETして、欲しい出目を目押ししよう。", 17, Color.WHITE)
	race_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	race_box.add_child(race_copy)
	var race_button := _button("DICE RACEへ")
	race_button.custom_minimum_size.y = 58
	race_button.pressed.connect(_open_dice_race)
	race_box.add_child(race_button)

	var prize_title := _label("PRIZE COUNTER", 26, Color("#ffd66b"))
	root.add_child(prize_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	prize_list = VBoxContainer.new()
	prize_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prize_list.add_theme_constant_override("separation", 8)
	scroll.add_child(prize_list)

	var back := _button("旅へ戻る")
	back.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back)

	race_host = Control.new()
	race_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	race_host.visible = false
	add_child(race_host)

func _refresh() -> void:
	chip_label.text = "CASINO CHIP  %d" % CasinoBankScript.balance()
	for child: Node in prize_list.get_children():
		child.queue_free()
	var owned: Array = CasinoBankScript.load_data().get("owned_cards", [])
	for card: Dictionary in card_data:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _panel(Color("#2b2235"), Color("#665270"), 12, 1))
		prize_list.add_child(row)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		row.add_child(box)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(copy)
		var name_label := _label("DICE RACER %s  %s" % [str(card.get("number", "")), str(card.get("name", ""))], 19, Color.WHITE)
		copy.add_child(name_label)
		var flavor := _label(str(card.get("flavor", "")), 14, Color("#cdbfd7"))
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(flavor)
		var card_id := str(card.get("id", ""))
		var cost := int(card.get("cost", 50))
		var button := _button("OWNED" if card_id in owned else "%d CHIP" % cost)
		button.disabled = card_id in owned or CasinoBankScript.balance() < cost
		if card_id not in owned:
			button.pressed.connect(_buy_card.bind(card_id, cost))
		box.add_child(button)

func _buy_card(card_id: String, cost: int) -> void:
	if CasinoBankScript.own_card(card_id, cost):
		_refresh()

func _open_dice_race() -> void:
	hub_root.visible = false
	race_host.visible = true
	for child: Node in race_host.get_children():
		child.queue_free()
	var screen := DICE_RACE_SCENE.instantiate()
	race_host.add_child(screen)
	if screen.has_signal("back_requested"):
		screen.connect("back_requested", _close_dice_race)

func _close_dice_race() -> void:
	for child: Node in race_host.get_children():
		child.queue_free()
	race_host.visible = false
	hub_root.visible = true
	get_node("/root/BgmManager").call("play_lasvegas_main")
	_refresh()

func _load_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(CARD_DATA_PATH):
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARD_DATA_PATH))
	if not parsed is Dictionary:
		return result
	for value: Variant in (parsed as Dictionary).get("cards", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result

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
	button.custom_minimum_size = Vector2(112, 44)
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
