extends RefCounted
class_name CasinoHowTo3Steps

## Shared first-play explainer used by all six Las Vegas facilities.
##
## The helper owns presentation only.  Facility screens supply three small
## dictionaries with `action` and `copy` values; game state and controls stay
## in the owning screen.  Keeping the headings here guarantees that a player
## sees the same mental model wherever they enter the casino.

const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const TITLE_COLOR: Color = Color("#ffe6a0")
const HEADING_COLOR: Color = Color("#fff2d2")
const ACTION_COLOR: Color = Color("#f6cf73")
const COPY_COLOR: Color = Color("#eadfc7")
const PANEL_FILL: Color = Color("#130d20ee")
const PANEL_BORDER: Color = Color("#c9963d")
const ROW_FILL: Color = Color("#261b34cc")
const ROW_BORDER: Color = Color("#695176")

const HEADINGS: Array[String] = [
	"① 最初に何をする？",
	"② プレイ中に何をする？",
	"③ どうなれば勝ち？",
]

static func build(parent: Control, facility_id: String, steps: Array[Dictionary]) -> PanelContainer:
	assert(parent != null)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "CasinoHowTo3Steps"
	panel.set_meta("facility_id", facility_id)
	panel.set_meta("step_count", 3)
	panel.custom_minimum_size.y = 174.0
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_FILL, PANEL_BORDER, 18, 2, 10))
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "HowToMargin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.name = "HowToStack"
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)

	var title: Label = _label("3ステップで遊び方", 24, TITLE_COLOR)
	title.name = "HowToTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 28.0
	stack.add_child(title)

	for index: int in range(3):
		var data: Dictionary = steps[index] if index < steps.size() else {}
		var row: PanelContainer = PanelContainer.new()
		row.name = "HowToStep%d" % (index + 1)
		row.custom_minimum_size.y = 38.0
		row.add_theme_stylebox_override("panel", _panel_style(ROW_FILL, ROW_BORDER, 10, 1, 4))
		stack.add_child(row)

		var row_margin: MarginContainer = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 10)
		row_margin.add_theme_constant_override("margin_right", 10)
		row_margin.add_theme_constant_override("margin_top", 3)
		row_margin.add_theme_constant_override("margin_bottom", 3)
		row.add_child(row_margin)

		var row_box: VBoxContainer = VBoxContainer.new()
		row_box.name = "Step%dContent" % (index + 1)
		row_box.add_theme_constant_override("separation", 0)
		row_margin.add_child(row_box)

		var heading: Label = _label(HEADINGS[index], 16, HEADING_COLOR)
		heading.name = "Step%dHeading" % (index + 1)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_box.add_child(heading)

		var action: String = str(data.get("action", "")).strip_edges()
		var copy: String = str(data.get("copy", "")).strip_edges()
		var detail_text: String = action
		if not copy.is_empty():
			detail_text = "%s  ·  %s" % [action, copy] if not action.is_empty() else copy
		var detail: Label = _label(detail_text, 15, ACTION_COLOR)
		detail.name = "Step%dDetail" % (index + 1)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_box.add_child(detail)

	return panel

static func create(parent: Control, facility_id: String, steps: Array[Dictionary]) -> PanelContainer:
	return build(parent, facility_id, steps)

static func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

static func _panel_style(fill: Color, border: Color, radius: int, border_width: int, margin: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
