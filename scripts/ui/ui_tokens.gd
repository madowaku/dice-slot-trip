class_name UiTokens
extends RefCounted

## DICE SLOT TRIP keeps a 720 x 1280 design viewport. Values in this file are
## therefore two design units per one logical mobile pixel at the 360 baseline.
const BASE_VIEWPORT := Vector2(720.0, 1280.0)

const FONT_DISPLAY := 52
const FONT_TITLE := 40
const FONT_BODY := 32
const FONT_CAPTION := 28

## Canvas-only labels may be smaller than UI copy, but remain centralized so
## map readability can be audited separately from buttons and paragraphs.
const FONT_MAP_HEADING := 28
const FONT_MAP_CAPTION := 24
const FONT_MAP_DETAIL := 20

const BUTTON_HEIGHT := 104
const TOUCH_MIN := 96

const EDGE := 32
const GAP_L := 32
const GAP_M := 24
const GAP_S := 16


## Returns the logical viewport exposed by canvas_items + aspect expand.
## Godot preserves the design scale uniformly, then grows whichever logical
## axis is needed to fill the physical display. The origin stays at (0, 0), so
## physical safe-area coordinates can be converted with the same uniform scale.
static func expanded_viewport_size_for(
		base_viewport_size: Vector2,
		display_size: Vector2i
	) -> Vector2:
	if base_viewport_size.x <= 0.0 or base_viewport_size.y <= 0.0:
		return Vector2.ZERO
	if display_size.x <= 0 or display_size.y <= 0:
		return Vector2.ZERO
	var display_scale := minf(
		float(display_size.x) / base_viewport_size.x,
		float(display_size.y) / base_viewport_size.y
	)
	if display_scale <= 0.0:
		return Vector2.ZERO
	return Vector2(display_size) / display_scale


static func safe_insets_for(
		base_viewport_size: Vector2,
		display_size: Vector2i,
		safe_area: Rect2i
	) -> Vector4:
	var viewport_size := expanded_viewport_size_for(base_viewport_size, display_size)
	if viewport_size == Vector2.ZERO:
		return Vector4.ZERO
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Vector4.ZERO
	var physical_to_viewport := viewport_size.x / float(display_size.x)
	var left := maxf(float(safe_area.position.x), 0.0) * physical_to_viewport
	var top := maxf(float(safe_area.position.y), 0.0) * physical_to_viewport
	var right := maxf(float(display_size.x - safe_area.end.x), 0.0) * physical_to_viewport
	var bottom := maxf(float(display_size.y - safe_area.end.y), 0.0) * physical_to_viewport
	return Vector4(left, top, right, bottom)


static func content_margins(base_viewport_size: Vector2) -> Vector4:
	var margins := Vector4(EDGE, EDGE, EDGE, EDGE)
	if OS.get_name() not in ["Android", "iOS"]:
		return margins
	var display_size := DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)
	var safe_area := DisplayServer.get_display_safe_area()
	var safe_insets := safe_insets_for(base_viewport_size, display_size, safe_area)
	return margins + safe_insets
