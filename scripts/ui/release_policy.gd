class_name ReleasePolicy
extends RefCounted

const BOARD_VIEW_CLASSIC := "classic"
const BOARD_VIEW_TOURISM := "tourism"


static func debug_tools_enabled(debug_build: bool) -> bool:
	return debug_build


static func preferred_board_view_mode(
		saved_preference: String,
		debug_build: bool,
		debug_override: String = ""
	) -> String:
	if not debug_build:
		return BOARD_VIEW_TOURISM
	var override := debug_override.strip_edges().to_lower()
	if override in [BOARD_VIEW_CLASSIC, BOARD_VIEW_TOURISM]:
		return override
	return BOARD_VIEW_CLASSIC if saved_preference.strip_edges().to_lower() == BOARD_VIEW_CLASSIC else BOARD_VIEW_TOURISM


static func can_request_board_view(mode: String, debug_build: bool) -> bool:
	if debug_build:
		return mode.strip_edges().to_lower() in [BOARD_VIEW_CLASSIC, BOARD_VIEW_TOURISM]
	return mode.strip_edges().to_lower() == BOARD_VIEW_TOURISM
