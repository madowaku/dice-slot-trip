extends Control

signal close_requested

const Localization = preload("res://scripts/ui/v06_localization.gd")
const Topics: Array[StringName] = [&"RULES_MOVE", &"RULES_SLOT", &"RULES_HP"]
const TOPIC_ART_PATHS: Array[String] = [
	"res://assets/art/ui/travel_guide/guide-move-v1.png",
	"res://assets/art/ui/travel_guide/guide-slot-v1.png",
	"res://assets/art/ui/travel_guide/guide-rest-v1.png",
]
var topic_buttons: Array[Button] = []
var body: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
var active_topic: int = 0
var _topic_textures: Array[Texture2D] = [null, null, null]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 75
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.03, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "RulesPanel"
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.06
	panel.anchor_right = 0.94
	panel.anchor_top = 0.09
	panel.anchor_bottom = 0.91
	panel.add_theme_stylebox_override("panel", _style(Color("#142d2c"), Color("#b58d46"), 24))
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	var title: Label = _label(Localization.text(&"RULES_TITLE"), 38, Color("#f3d18c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	content.add_child(tabs)
	for index: int in range(Topics.size()):
		var button: Button = Button.new()
		button.name = "RulesTopic%d" % index
		button.text = Localization.text(Topics[index])
		button.toggle_mode = true
		button.custom_minimum_size.y = 96
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(show_topic.bind(index))
		tabs.add_child(button)
		topic_buttons.append(button)
	scroll = ScrollContainer.new()
	scroll.name = "RulesScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)
	close_button = Button.new()
	close_button.name = "RulesCloseButton"
	close_button.text = Localization.text(&"RULES_CLOSE")
	close_button.custom_minimum_size.y = 96
	close_button.add_theme_font_size_override("font_size", 28)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	content.add_child(close_button)
	hide()

func open() -> void:
	show_topic(0)
	scroll.scroll_vertical = 0
	show()
	topic_buttons[0].grab_focus()

func show_topic(index: int) -> void:
	var requested: int = clampi(index, 0, Topics.size() - 1)
	if requested == active_topic and body.get_child_count() > 0:
		topic_buttons[requested].set_pressed_no_signal(true)
		return
	active_topic = requested
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for button_index: int in range(topic_buttons.size()):
		var button: Button = topic_buttons[button_index]
		button.set_pressed_no_signal(button_index == active_topic)
		button.theme_type_variation = &"SelectedButton" if button_index == active_topic else &"SecondaryButton"
	var prefix: String = String(Topics[active_topic])
	var illustration: TextureRect = TextureRect.new()
	illustration.name = "TopicIllustration"
	if _topic_textures[active_topic] == null:
		_topic_textures[active_topic] = load(TOPIC_ART_PATHS[active_topic]) as Texture2D
	illustration.texture = _topic_textures[active_topic]
	illustration.custom_minimum_size.y = 140
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(illustration)
	var count: int = 4 if active_topic == 1 else 3
	for row: int in range(count):
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style(Color("#f1e2bd"), Color("#b59455"), 12))
		body.add_child(card)
		var column: VBoxContainer = VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		card.add_child(column)
		column.add_child(_label(Localization.text(StringName("%s_%d_TITLE" % [prefix, row])), 30, Color("#226c6c")))
		column.add_child(_label(Localization.text(StringName("%s_%d_BODY" % [prefix, row])), 28, Color("#493a28")))
	scroll.scroll_vertical = 0

func _label(copy: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = copy
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(fill: Color, border: Color, padding: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style
