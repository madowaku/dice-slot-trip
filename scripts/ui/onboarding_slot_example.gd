extends Control

## The example follows the letterboxed 2:1 tray image at every phone size.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var width: float = minf(size.x, size.y * 2.0)
	var art_size: Vector2 = Vector2(width, width * 0.5)
	var origin: Vector2 = (size - art_size) * 0.5
	var font: Font = get_theme_default_font()
	var font_size: int = maxi(18, roundi(width * 0.115))
	var values: Array[String] = ["2", "2", "5"]
	for index: int in range(3):
		var value: String = values[index]
		var center: Vector2 = origin + art_size * Vector2(0.215 + index * 0.285, 0.52)
		var text_width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline: Vector2 = center + Vector2(-text_width * 0.5, (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
		draw_string(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#247477") if index < 2 else Color("#63503c"))
