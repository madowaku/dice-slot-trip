extends RefCounted

const LABEL: String = "カジノへ戻る"
const TOOLTIP: String = "Las Vegas Casinoロビーへ戻る"
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const TEXT: Color = Color("#f8eefc")
const TEXT_HOVER: Color = Color.WHITE
const TEXT_DISABLED: Color = Color("#8d8195")
const FILL: Color = Color("#352746")
const FILL_HOVER: Color = Color("#4a3760")
const FILL_PRESSED: Color = Color("#241a31")
const FILL_DISABLED: Color = Color("#211a2a")
const BORDER: Color = Color("#8c72a4")
const BORDER_HOVER: Color = Color("#b999d2")
const BORDER_FOCUS: Color = Color("#f2d27b")

static func configure(button: Button) -> void:
	button.text = LABEL
	button.tooltip_text = TOOLTIP
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT_HOVER)
	button.add_theme_color_override("font_pressed_color", TEXT_HOVER)
	button.add_theme_color_override("font_focus_color", TEXT_HOVER)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	button.add_theme_stylebox_override("normal", _style(FILL, BORDER, true))
	button.add_theme_stylebox_override("hover", _style(FILL_HOVER, BORDER_HOVER, true))
	button.add_theme_stylebox_override("pressed", _style(FILL_PRESSED, BORDER_FOCUS, true))
	button.add_theme_stylebox_override("disabled", _style(FILL_DISABLED, Color("#594a64"), true))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, BORDER_FOCUS, false, 3.0))

static func _style(fill: Color, border: Color, draw_center: bool, expand: float = 0.0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.draw_center = draw_center
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.expand_margin_left = expand
	style.expand_margin_top = expand
	style.expand_margin_right = expand
	style.expand_margin_bottom = expand
	return style
