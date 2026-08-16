class_name FoxFireSixRoutesView
extends Control

## Product view for Fox Fire Six Routes.
##
## All board decoration uses the same trapezoid cell-center function as the
## interaction buttons. This keeps the 6x6 hit layer aligned with the painted
## board while preserving generous touch targets.

signal cell_pressed(position: Vector2i)
signal roll_requested
signal undo_requested
signal path_confirm_requested
signal miss_requested
signal tutorial_finished
signal start_torii_selected(torii_id: int)
signal result_continue_requested
signal mangan_requested
signal kiyomizu_requested
signal tenryuji_shift_requested(delta: int)
signal special_cell_selected(position: Vector2i)
signal special_skip_requested

const ControllerScript = preload("res://boss/kyoto/fox_fire_six_routes/fox_fire_six_routes_controller.gd")
const BOARD_TEXTURE: Texture2D = preload("res://assets/art/backgrounds/fox-fire-six-routes-board.png")
const FOX_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/white-fox-guardian.png")
const TORII_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/fox-fire-torii.png")
const WHITE_FIRE_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/white-foxfire.png")
const SPECIAL_TILE_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/fox-fire-special-tiles.png")
const CAT_STRIP: Texture2D = preload("res://assets/art/bosses/kyoto/explorer-cat-move-strip.png")
const SLOT_TRAY_TEXTURE: Texture2D = preload("res://assets/art/ui/common/slot-tray-luxury-v1.png")
const ROLL_RING_TEXTURE: Texture2D = preload("res://assets/art/ui/common/roll-button-round-v1.png")
const DICE_UI_TEXTURE: Texture2D = preload("res://assets/art/ui/common/dice-ivory-brass.png")
const TUTORIAL_MOVE_TEXTURE: Texture2D = preload("res://assets/art/tutorials/fox-fire-six-routes-tutorial-move-v2.png")
const TUTORIAL_TORII_TEXTURE: Texture2D = preload("res://assets/art/tutorials/fox-fire-six-routes-tutorial-torii.png")
const TUTORIAL_FIRE_TEXTURE: Texture2D = preload("res://assets/art/tutorials/fox-fire-six-routes-tutorial-foxfire.png")
const TUTORIAL_BLESSINGS_TEXTURE: Texture2D = preload("res://assets/art/tutorials/fox-fire-six-routes-tutorial-blessings.png")
const GOSHUIN_ICONS_TEXTURE: Texture2D = preload("res://assets/art/ui/kyoto-goshuin-icons.png")
const YASAKA_ICON_TEXTURE: Texture2D = preload("res://assets/art/v06/effects/lantern-glow.png")
const VICTORY_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/fox-fire-victory-key-art-explorer-cat.png")
const FONT: FontFile = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const MAX_HEARTS: int = 3
const BOARD_SIZE: int = 6
const TOUCH_SIZE := Vector2(78.0, 78.0)
# Measured from the authored 720x1280 board plate. The perspective makes the
# six rows progressively taller and pulls the vertical guides outward toward
# the bottom; a single linear rectangle visibly drifts the torii and cat.
var BOARD_ROW_BOUNDS := PackedFloat32Array([477.0, 543.0, 614.0, 688.0, 767.0, 851.0, 942.0])
var BOARD_ROW_CENTERS := PackedFloat32Array([510.0, 578.5, 651.0, 727.5, 809.0, 896.5])
var BOARD_VERTICAL_LINES: Array[PackedFloat32Array] = [
	PackedFloat32Array([116.0, 199.0, 280.0, 359.0, 439.0, 519.0, 603.0]),
	PackedFloat32Array([112.0, 196.0, 278.0, 359.0, 441.0, 522.0, 606.0]),
	PackedFloat32Array([105.0, 191.0, 277.0, 359.0, 443.0, 527.0, 614.0]),
	PackedFloat32Array([97.0, 186.0, 272.0, 359.0, 446.0, 532.0, 622.0]),
	PackedFloat32Array([88.0, 180.0, 269.0, 359.0, 449.0, 538.0, 631.0]),
	PackedFloat32Array([79.0, 174.0, 266.0, 359.0, 451.0, 543.0, 640.0]),
]
const TORII_POSITIONS: Array[Vector2i] = [
	Vector2i(2, 5),
	Vector2i(3, 0),
	Vector2i(0, 1),
	Vector2i(5, 3),
]
const TORII_LABELS: Array[String] = ["A", "B", "C", "D"]

const INK := Color("#f7e8c5")
const MUTED := Color("#c8b895")
const GOLD := Color("#f6d471")
const DEEP_GOLD := Color("#a8772c")
const VERMILION := Color("#ff663f")
const VERMILION_DARK := Color("#8e2f22")
const NAVY := Color("#0d1229")
const PANEL := Color(0.035, 0.045, 0.09, 0.94)
const TEAL := Color("#56cfc0")
const WHITE_FIRE := Color("#eafaff")

# The two board rules are intentionally taught at different moments. Keeping
# this as a small public state machine also lets the playtest harness assert
# that a warning is not shown before its matching board event exists.
const GUIDE_NONE: int = 0
const GUIDE_TORII: int = 1
const GUIDE_WHITE_FIRE: int = 2

var controller: FoxFireSixRoutesController
var reduced_motion: bool = false
var player_context: Dictionary = {"lap": 1, "coins": 0, "hp": MAX_HEARTS, "max_hp": MAX_HEARTS}

var backdrop_fill: TextureRect
var backdrop: TextureRect
var dimmer: ColorRect
var top_hud: PanelContainer
var title_label: Label
var seal_label: Label
var turn_label: Label
var difficulty_label: Label
var hp_label: Label
var coin_label: Label
var fox_bar: PanelContainer
var fox_preview_label: Label
var blessing_label: HBoxContainer
var mangan_button: Button
var board_canvas: BoardCanvas
var fox_sprite: TextureRect
var cat_sprite: TextureRect
var cell_buttons: Dictionary = {}
var status_panel: PanelContainer
var move_label: Label
var remaining_label: Label
var role_label: Label
var slot_panel: PanelContainer
var slot_faces: Array[DieFace] = []
var roll_button: Button
var roll_button_die_icon: TextureRect
var roll_button_copy: Label
var action_panel: PanelContainer
var undo_button: Button
var confirm_button: Button
var miss_button: Button
var blessing_row: HBoxContainer
var kiyomizu_button: Button
var minus_button: Button
var plus_button: Button
var message_label: Label
var activation_panel: PanelContainer
var activation_icon: TextureRect
var activation_role_badge: Label
var activation_title: Label
var activation_body: Label
var tutorial_overlay: Control
var tutorial_title: Label
var tutorial_body: Label
var tutorial_art: TextureRect
var tutorial_hint: Label
var tutorial_progress: Label
var tutorial_button: Button
var start_overlay: Control
var start_buttons: Array[Button] = []
var result_overlay: Control
var result_art: TextureRect
var result_title: Label
var result_body: Label
var result_button: Button
var special_overlay: Control
var special_title: Label
var special_body: Label
var special_action_container: GridContainer
var special_skip_button: Button
var rule_guide_dimmer: ColorRect
var rule_guide_panel: PanelContainer
var rule_guide_title: Label
var rule_guide_body: Label
var rule_guide_button: Button
var board_input_layer: Control

var _tutorial_page: int = 0
var _tutorial_anim_elapsed: float = 0.0
var _banner_serial: int = 0
var _activation_serial: int = 0
var _activation_playing: bool = false
var _activation_queue: Array[Dictionary] = []
var _cat_visual_position := Vector2i(2, 5)
var _cat_animation_frame: int = 0
var _cat_animating: bool = false
var _die_rolling: bool = false
var _die_roll_elapsed: float = 0.0
var _die_roll_preview_face: int = 1
var _drag_active: bool = false
var _drag_started_cell := Vector2i(-1, -1)
var _drag_last_cell := Vector2i(-1, -1)
var _drag_moved: bool = false
var _last_touch_time_usec: int = 0
var rule_guide_visible: bool = false
var rule_guide_kind: int = GUIDE_NONE
var _rule_fire_position := Vector2i(-1, -1)
var _last_white_fire_signature: String = ""
var _fire_rule_shown: bool = false
var _defer_white_fire_guide: bool = false


class DieFace extends Control:
	var face: int = 0
	var active: bool = false

	func set_face(value: int, is_active: bool = false) -> void:
		face = clampi(value, 0, 6)
		active = is_active
		queue_redraw()

	func _draw() -> void:
		var outer := Rect2(Vector2(3, 3), size - Vector2(6, 6))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#fff6df") if face > 0 else Color(0.09, 0.08, 0.075, 0.9)
		style.border_color = GOLD if active else Color("#8d6b37")
		style.set_border_width_all(4 if active else 2)
		style.set_corner_radius_all(15)
		draw_style_box(style, outer)
		if face <= 0:
			draw_string(FONT, Vector2(0, size.y * 0.62), "—", HORIZONTAL_ALIGNMENT_CENTER, size.x, 31, MUTED)
			return
		var center := outer.get_center()
		var gap := minf(size.x, size.y) * 0.20
		var pips: Array[Vector2] = []
		match face:
			1: pips = [center]
			2: pips = [center + Vector2(-gap, -gap), center + Vector2(gap, gap)]
			3: pips = [center + Vector2(-gap, -gap), center, center + Vector2(gap, gap)]
			4: pips = [center + Vector2(-gap, -gap), center + Vector2(gap, -gap), center + Vector2(-gap, gap), center + Vector2(gap, gap)]
			5: pips = [center + Vector2(-gap, -gap), center + Vector2(gap, -gap), center, center + Vector2(-gap, gap), center + Vector2(gap, gap)]
			6: pips = [center + Vector2(-gap, -gap), center + Vector2(gap, -gap), center + Vector2(-gap, 0), center + Vector2(gap, 0), center + Vector2(-gap, gap), center + Vector2(gap, gap)]
		for pip: Vector2 in pips:
			draw_circle(pip + Vector2(1.5, 2.0), 6.0, Color(0, 0, 0, 0.18))
			draw_circle(pip, 5.2, Color("#33251b"))


class BoardCanvas extends Control:
	var owner_view: FoxFireSixRoutesView
	var pulse: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		if owner_view != null and not owner_view.reduced_motion:
			pulse = fmod(pulse + delta * 2.2, TAU)
			queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if owner_view == null or owner_view.controller == null:
			return
		var state := owner_view.controller.state
		_draw_endpoints(state.reachable_endpoints, state.visited_torii)
		_draw_player_marker()
		_draw_path_preview(state.current_input_path)
		_draw_edges(state.active_edges, VERMILION, 10.0, true)
		_draw_edges(state.sealed_edges, GOLD, 13.0, false)
		_draw_line_cut_preview(state.fox_preview_line_cut_edge, state.active_edges)
		_draw_special_tiles()
		_draw_torii(state.current_torii_id, state.visited_torii)
		_draw_white_fire(state.white_fire_cells, 1.0)
		_draw_preview_fire(state.fox_preview_cells)
		if owner_view.rule_guide_visible:
			_draw_rule_guide(state)

	func _draw_rule_guide(state: FoxFireBattleState) -> void:
		# Keep each warning focused on one rule. Showing both at once made the
		# first-time board read feel like a puzzle before the player had rolled.
		var pulse_alpha := 0.88
		if not owner_view.reduced_motion:
			pulse_alpha = 0.70 + sin(pulse * 1.4) * 0.18
		if owner_view.rule_guide_kind == owner_view.GUIDE_TORII:
			# Highlight destinations, not the cat's current shrine. Seeing three
			# bright goal rings makes the “stop exactly” rule actionable before the
			# first roll and keeps the starting torii from looking like a target.
			var highlighted := 0
			for target_id: int in range(owner_view.TORII_POSITIONS.size()):
				if target_id == state.current_torii_id or state.visited_torii.has(target_id):
					continue
				var target := owner_view.board_cell_center(owner_view.TORII_POSITIONS[target_id])
				draw_circle(target, 72.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.12))
				draw_arc(target, 63.0, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, pulse_alpha), 8.0, true)
				draw_arc(target, 78.0, -PI * 0.22, PI * 0.22, 24, Color(1.0, 0.95, 0.72, pulse_alpha), 5.0, true)
				highlighted += 1
			if highlighted == 0:
				var fallback_id := clampi(state.current_torii_id, 0, owner_view.TORII_POSITIONS.size() - 1)
				var fallback := owner_view.board_cell_center(owner_view.TORII_POSITIONS[fallback_id])
				draw_circle(fallback, 72.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.12))
				draw_arc(fallback, 63.0, 0.0, TAU, 48, Color(GOLD.r, GOLD.g, GOLD.b, pulse_alpha), 8.0, true)
			return
		if owner_view.rule_guide_kind != owner_view.GUIDE_WHITE_FIRE:
			return
		var fire_position := owner_view.guide_fire_position(state)
		if fire_position == Vector2i(-1, -1):
			return
		var fire_center := owner_view.board_cell_center(fire_position)
		draw_circle(fire_center, 67.0, Color(0.52, 0.91, 1.0, 0.18))
		draw_arc(fire_center, 59.0, 0.0, TAU, 40, Color(0.72, 0.97, 1.0, pulse_alpha), 7.0, true)
		draw_texture_rect(owner_view.WHITE_FIRE_TEXTURE, Rect2(fire_center - Vector2(39, 47), Vector2(78, 78)), false, Color(1, 1, 1, 0.88))
		draw_line(fire_center + Vector2(-31, -31), fire_center + Vector2(31, 31), Color(1.0, 0.30, 0.28, pulse_alpha), 9.0, true)
		draw_line(fire_center + Vector2(31, -31), fire_center + Vector2(-31, 31), Color(1.0, 0.30, 0.28, pulse_alpha), 9.0, true)

	func _draw_endpoints(endpoints: Array[Vector2i], visited: Dictionary) -> void:
		for position: Vector2i in endpoints:
			var center := owner_view.board_cell_center(position)
			var torii_id := owner_view.controller.torii_id_at(position)
			var is_target := torii_id >= 0 and not visited.has(torii_id)
			var color := GOLD if is_target else Color(1.0, 0.86, 0.35, 0.62)
			# Exact-N destinations stay as a quiet route hint. The bright rings
			# below mark only the next one-cell choices, so a roll of 4 never
			# looks like it skips from the cat straight to a distant endpoint.
			var radius := 25.0 if is_target else 15.0
			draw_circle(center, radius + 8.0, Color(color.r, color.g, color.b, 0.12))
			draw_circle(center, radius, Color(color.r, color.g, color.b, 0.17))
			draw_arc(center, radius, 0, TAU, 36, color, 4.0 if is_target else 2.0, true)
		if owner_view.controller.state.phase == ControllerScript.BattlePhase.PATH_INPUT:
			for next_position: Vector2i in owner_view.controller.legal_next_cells():
				var next_center := owner_view.board_cell_center(next_position)
				var next_alpha := 0.78 + sin(pulse * 1.6) * 0.12 if not owner_view.reduced_motion else 0.82
				draw_circle(next_center, 36.0, Color(0.24, 0.92, 0.86, 0.10))
				draw_arc(next_center, 31.0, 0.0, TAU, 40, Color(0.35, 1.0, 0.91, next_alpha), 6.0, true)
				draw_arc(next_center, 40.0, -PI * 0.25, PI * 0.25, 18, Color(1.0, 0.90, 0.42, next_alpha), 4.0, true)

	func _draw_player_marker() -> void:
		var center := owner_view.board_cell_center(owner_view._cat_visual_position)
		var pulse_alpha := 0.78
		if not owner_view.reduced_motion:
			pulse_alpha = 0.68 + sin(pulse * 1.7) * 0.14
		# A strong teal/gold foot ring keeps the player's own cell readable even
		# when the fox sprite and several route glows occupy the same board area.
		draw_circle(center + Vector2(0, 28), 25.0, Color(0.05, 0.18, 0.20, 0.34))
		draw_circle(center, 47.0, Color(0.24, 0.92, 0.86, 0.10))
		draw_arc(center, 43.0, 0.0, TAU, 48, Color(0.35, 1.0, 0.91, pulse_alpha), 6.0, true)
		draw_arc(center, 51.0, -PI * 0.25, PI * 0.25, 20, Color(1.0, 0.90, 0.42, pulse_alpha), 4.0, true)

	func _draw_path_preview(path: Array[Vector2i]) -> void:
		if path.size() < 2:
			return
		for index: int in range(1, path.size()):
			var from := owner_view.board_cell_center(path[index - 1])
			var to := owner_view.board_cell_center(path[index])
			draw_line(from, to, Color(1.0, 0.88, 0.52, 0.32), 16.0, true)
			draw_line(from, to, Color(1.0, 0.96, 0.78, 0.9), 4.0, true)
		for position: Vector2i in path:
			draw_circle(owner_view.board_cell_center(position), 9.0, Color(1.0, 0.91, 0.58, 0.85))
		for index: int in range(1, path.size()):
			var step_center := owner_view.board_cell_center(path[index])
			draw_circle(step_center, 17.0, Color(1.0, 0.93, 0.58, 0.92))
			draw_string(owner_view.FONT, step_center + Vector2(-8, 7), str(index), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 18, owner_view.NAVY)

	func _draw_edges(edges: Dictionary, color: Color, width: float, flicker: bool) -> void:
		for edge_value: Variant in edges.values():
			if edge_value == null:
				continue
			var from := owner_view.board_cell_center(edge_value.a)
			var to := owner_view.board_cell_center(edge_value.b)
			var glow_alpha := 0.27
			if flicker and not owner_view.reduced_motion:
				glow_alpha += sin(pulse + from.x * 0.02) * 0.07
			draw_line(from, to, Color(color.r, color.g, color.b, glow_alpha), width + 13.0, true)
			draw_line(from, to, color, width, true)
			draw_line(from, to, Color(1.0, 0.92, 0.62, 0.74), 2.5, true)
			draw_circle(from, width * 0.55, color)
			draw_circle(to, width * 0.55, color)

	func _draw_torii(current_id: int, visited: Dictionary) -> void:
		for torii_id: int in range(TORII_POSITIONS.size()):
			var center := owner_view.board_cell_center(TORII_POSITIONS[torii_id])
			var is_current := torii_id == current_id
			var is_visited := visited.has(torii_id)
			var tint := GOLD if is_visited else Color.WHITE
			var alpha := 1.0 if is_current else 0.90
			var rect_size := Vector2(82, 82) if is_current else Vector2(72, 72)
			if is_current:
				draw_circle(center, 43.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.20))
				draw_arc(center, 39.0, 0, TAU, 38, GOLD, 4.0, true)
			draw_texture_rect(TORII_TEXTURE, Rect2(center - rect_size * 0.5, rect_size), false, Color(tint.r, tint.g, tint.b, alpha))
			var chip := Rect2(center + Vector2(20, -39), Vector2(24, 24))
			draw_circle(chip.get_center(), 12.0, Color("#1a1320"))
			draw_arc(chip.get_center(), 12.0, 0, TAU, 24, GOLD if is_visited else VERMILION, 2.0)
			draw_string(FONT, Vector2(chip.position.x, chip.position.y + 18), TORII_LABELS[torii_id], HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 15, INK)

	func _draw_white_fire(cells: Dictionary, alpha: float) -> void:
		for position: Vector2i in cells.keys():
			var center := owner_view.board_cell_center(position)
			draw_circle(center, 33.0, Color(0.7, 0.95, 1.0, 0.13 * alpha))
			draw_texture_rect(WHITE_FIRE_TEXTURE, Rect2(center - Vector2(29, 34), Vector2(58, 58)), false, Color(1, 1, 1, alpha))

	func _draw_preview_fire(cells: Array[Vector2i]) -> void:
		var preview_alpha := 0.44
		if not owner_view.reduced_motion:
			preview_alpha += sin(pulse * 1.35) * 0.09
		for index: int in range(cells.size()):
			var position := cells[index]
			var center := owner_view.board_cell_center(position)
			draw_circle(center, 39.0, Color(0.72, 0.96, 1.0, 0.10))
			draw_arc(center, 34.0, -PI * 0.5, TAU - PI * 0.5, 32, Color(0.82, 0.98, 1.0, 0.72), 3.0, true)
			draw_texture_rect(WHITE_FIRE_TEXTURE, Rect2(center - Vector2(26, 31), Vector2(52, 52)), false, Color(1, 1, 1, preview_alpha))
			if cells.size() >= 2:
				var badge_center := center + Vector2(24, -27)
				draw_circle(badge_center, 13.0, Color("#18233d"))
				draw_arc(badge_center, 13.0, 0.0, TAU, 24, Color(0.82, 0.98, 1.0, 0.92), 2.0, true)
				draw_string(FONT, badge_center + Vector2(-8, 6), "A" if index == 0 else "B", HORIZONTAL_ALIGNMENT_CENTER, 16, 15, INK)

	func _draw_line_cut_preview(edge_key: String, edges: Dictionary) -> void:
		if edge_key.is_empty():
			return
		var edge_value: Variant = edges.get(edge_key)
		var edge: FoxFireEdge = edge_value as FoxFireEdge
		if edge == null:
			return
		var from := owner_view.board_cell_center(edge.a)
		var to := owner_view.board_cell_center(edge.b)
		var preview_color := Color("#d08cff")
		draw_line(from, to, Color(preview_color.r, preview_color.g, preview_color.b, 0.22), 25.0, true)
		draw_line(from, to, Color(preview_color.r, preview_color.g, preview_color.b, 0.86), 7.0, true)
		var midpoint := from.lerp(to, 0.5)
		draw_circle(midpoint, 15.0, Color("#261b3b"))
		draw_arc(midpoint, 13.0, 0.0, TAU, 24, preview_color, 3.0, true)
		draw_line(midpoint + Vector2(-7, -7), midpoint + Vector2(7, 7), preview_color, 3.0, true)
		draw_line(midpoint + Vector2(7, -7), midpoint + Vector2(-7, 7), preview_color, 3.0, true)

	func _draw_special_tiles() -> void:
		if owner_view.controller.difficulty_config == null or not owner_view.controller.difficulty_config.enable_special_tiles:
			return
		var special_count := owner_view.controller.difficulty_config.special_tile_count
		if special_count <= 0:
			special_count = 2
		var sakura := owner_view.board_cell_center(Vector2i(2, 2))
		var sakura_color := Color("#f7a9c4")
		draw_circle(sakura, 25.0, Color(sakura_color.r, sakura_color.g, sakura_color.b, 0.14))
		draw_arc(sakura, 22.0, 0.0, TAU, 28, Color(sakura_color.r, sakura_color.g, sakura_color.b, 0.76), 2.0, true)
		draw_texture_rect_region(SPECIAL_TILE_TEXTURE, Rect2(sakura - Vector2(30, 30), Vector2(60, 60)), Rect2(0, 0, 128, 128), Color(1, 1, 1, 0.96))
		if special_count < 2:
			return
		var bamboo := owner_view.board_cell_center(Vector2i(2, 4))
		var bamboo_color := Color("#7dd29c")
		draw_texture_rect_region(SPECIAL_TILE_TEXTURE, Rect2(bamboo - Vector2(31, 31), Vector2(62, 62)), Rect2(128, 0, 128, 128), Color(1, 1, 1, 0.96))
		draw_arc(bamboo, 27.0, PI * 0.08, PI * 0.92, 18, Color(bamboo_color.r, bamboo_color.g, bamboo_color.b, 0.48), 2.0, true)


func _ready() -> void:
	clip_contents = true
	_build_ui()
	set_process(true)
	set_process_input(true)
	call_deferred("_layout_ui")


func _process(delta: float) -> void:
	if tutorial_overlay != null and tutorial_overlay.visible:
		_tutorial_anim_elapsed += delta
		_refresh_tutorial_animation()
	if not _die_rolling:
		return
	_die_roll_elapsed += delta
	if _die_roll_elapsed >= 0.085:
		_die_roll_elapsed = 0.0
		_die_roll_preview_face = (int(Time.get_ticks_msec() / 85.0) % 6) + 1
		var faces: Array = controller.slot_faces() if controller != null else []
		faces.append(_die_roll_preview_face)
		_refresh_slot_faces(faces)
	if roll_button_die_icon != null:
		roll_button_die_icon.rotation = sin(Time.get_ticks_msec() * 0.012) * 0.18
		roll_button_die_icon.scale = Vector2.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.018) * 0.035)
	if roll_button_copy != null:
		roll_button_copy.text = "止める"
	if board_canvas != null:
		board_canvas.queue_redraw()


func is_die_rolling() -> bool:
	return _die_rolling


func begin_die_roll() -> bool:
	if controller == null or controller.state.phase != ControllerScript.BattlePhase.ROLL_SLOT or rule_guide_visible:
		return false
	_die_rolling = true
	_die_roll_elapsed = 0.0
	_die_roll_preview_face = 1
	roll_button.disabled = false
	roll_button_copy.text = "止める"
	return true


func finish_die_roll() -> void:
	_die_rolling = false
	_die_roll_elapsed = 0.0
	if roll_button_die_icon != null:
		roll_button_die_icon.rotation = 0.0
		roll_button_die_icon.scale = Vector2.ONE
	if controller != null:
		_refresh_slot_faces(controller.slot_faces())


func cancel_die_roll() -> void:
	if _die_rolling:
		finish_die_roll()


func show_rule_guide() -> void:
	# Backwards-compatible alias for integrations that used the original name.
	show_torii_rule_guide()


func show_torii_rule_guide() -> void:
	_show_rule_guide(GUIDE_TORII)
	refresh()


func show_white_fire_rule_guide(position: Vector2i = Vector2i(-1, -1)) -> void:
	if controller == null:
		return
	var target := position
	if target == Vector2i(-1, -1):
		target = guide_fire_position(controller.state)
	if target == Vector2i(-1, -1):
		return
	_rule_fire_position = target
	_fire_rule_shown = true
	_show_rule_guide(GUIDE_WHITE_FIRE)
	refresh()


func _show_rule_guide(kind: int) -> void:
	if rule_guide_panel == null:
		return
	rule_guide_kind = kind
	rule_guide_visible = kind != GUIDE_NONE
	rule_guide_panel.visible = rule_guide_visible
	if rule_guide_dimmer != null:
		rule_guide_dimmer.visible = rule_guide_visible
	# Draw the board callout above the dimmer so the highlighted cell remains
	# readable while every other surface recedes.
	if board_canvas != null:
		board_canvas.z_index = 41 if rule_guide_visible else 0
	if rule_guide_panel != null:
		rule_guide_panel.z_index = 43
	_refresh_rule_guide_copy()
	if board_canvas != null:
		board_canvas.queue_redraw()


func dismiss_rule_guide() -> void:
	rule_guide_visible = false
	rule_guide_kind = GUIDE_NONE
	_drag_active = false
	_drag_started_cell = Vector2i(-1, -1)
	_drag_last_cell = Vector2i(-1, -1)
	if rule_guide_panel != null:
		rule_guide_panel.visible = false
	if rule_guide_dimmer != null:
		rule_guide_dimmer.visible = false
	if board_canvas != null:
		board_canvas.z_index = 0
		board_canvas.queue_redraw()
	refresh()
	_try_play_next_activation()


func set_white_fire_guide_deferred(deferred: bool) -> void:
	# Battle start deliberately teaches exact torii stopping first. Controller
	# signals can refresh the view while initial fox fire is being seeded, so
	# keep that second lesson pending until the first modal is on screen.
	_defer_white_fire_guide = deferred


func guide_fire_position(state: FoxFireBattleState) -> Vector2i:
	# A warning is only valid once an actual white-fire cell exists. Preview
	# cells are intentionally excluded: they are a forecast, not a blocked tile.
	if _rule_fire_position != Vector2i(-1, -1) and state.white_fire_cells.has(_rule_fire_position):
		return _rule_fire_position
	if not state.white_fire_cells.is_empty():
		return state.white_fire_cells.keys()[0] as Vector2i
	return Vector2i(-1, -1)


func _white_fire_signature(cells: Dictionary) -> String:
	var tokens: Array[String] = []
	for position: Vector2i in cells.keys():
		tokens.append("%d:%d" % [position.x, position.y])
	tokens.sort()
	return ",".join(tokens)


func _maybe_show_white_fire_guide(state: FoxFireBattleState) -> void:
	var signature := _white_fire_signature(state.white_fire_cells)
	if signature.is_empty():
		_last_white_fire_signature = ""
		return
	if _defer_white_fire_guide:
		return
	if signature == _last_white_fire_signature:
		return
	# If another modal is already teaching a rule, leave the signature pending;
	# the fire warning will appear as soon as that modal is dismissed.
	if rule_guide_visible:
		return
	_last_white_fire_signature = signature
	if _fire_rule_shown:
		return
	var first_position: Vector2i = state.white_fire_cells.keys()[0] as Vector2i
	_rule_fire_position = first_position
	_fire_rule_shown = true
	_show_rule_guide(GUIDE_WHITE_FIRE)


func bind_controller(value: FoxFireSixRoutesController) -> void:
	controller = value
	_last_white_fire_signature = _white_fire_signature(controller.state.white_fire_cells) if controller != null else ""
	_fire_rule_shown = not _last_white_fire_signature.is_empty()
	_rule_fire_position = Vector2i(-1, -1)
	if board_canvas != null:
		board_canvas.owner_view = self
	refresh()


func set_player_context(value: Dictionary) -> void:
	player_context = value.duplicate(true)
	refresh()


func reset_presentation() -> void:
	_pending_banner_clear()
	_activation_serial += 1
	_activation_queue.clear()
	_activation_playing = false
	if activation_panel != null:
		activation_panel.visible = false
	cancel_die_roll()
	_drag_active = false
	_cat_animating = false
	_cat_animation_frame = 0
	if controller != null:
		_cat_visual_position = controller.state.cat_position
		_last_white_fire_signature = _white_fire_signature(controller.state.white_fire_cells)
		_fire_rule_shown = not _last_white_fire_signature.is_empty()
		_rule_fire_position = Vector2i(-1, -1)
	dismiss_all_modals()
	refresh()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if board_canvas != null:
		board_canvas.queue_redraw()


func resolution_delay() -> float:
	return 0.0 if reduced_motion else 0.34


func dismiss_all_modals() -> void:
	if tutorial_overlay != null:
		tutorial_overlay.visible = false
	if start_overlay != null:
		start_overlay.visible = false
	if result_overlay != null:
		result_overlay.visible = false
	if special_overlay != null:
		special_overlay.visible = false
	dismiss_rule_guide()


func show_tutorial() -> void:
	_tutorial_page = 0
	_tutorial_anim_elapsed = 0.0
	_refresh_tutorial()
	tutorial_overlay.visible = true


func show_start_choice() -> void:
	start_overlay.visible = true


func hide_start_choice() -> void:
	start_overlay.visible = false


func show_special_choice(options: Array[Vector2i]) -> void:
	if special_overlay == null:
		return
	for child: Node in special_action_container.get_children():
		child.queue_free()
	for index: int in range(options.size()):
		var position: Vector2i = options[index]
		var button := _button("狐火候補 %d" % (index + 1), 21, true)
		button.custom_minimum_size = Vector2(220, 76)
		button.tooltip_text = "盤面で光る狐火を浄化"
		button.pressed.connect(_emit_special_cell.bind(position))
		special_action_container.add_child(button)
	special_overlay.visible = true


func hide_special_choice() -> void:
	if special_overlay != null:
		special_overlay.visible = false


func _emit_special_cell(position: Vector2i) -> void:
	special_cell_selected.emit(position)


func show_result(result: Variant) -> void:
	var data: Dictionary = {}
	if result is Object and (result as Object).has_method("to_dictionary"):
		data = (result as Object).to_dictionary()
	elif result is Dictionary:
		data = result
	var won: bool = bool(data.get("victory", false))
	result_art.visible = won
	result_title.text = "結界、完成。" if won else "六路、封鎖。"
	result_title.add_theme_color_override("font_color", GOLD if won else Color("#ff8e76"))
	result_body.text = (
		"白狐「見事。道は、しかと繋がった。」\n\n封印 %d/3 ・ %dターン"
		if won else
		"白狐に道を閉ざされた……\n\n封印 %d/3 ・ %dターン"
	) % [int(data.get("seal_count", 0)), int(data.get("turns_used", 0))]
	result_button.text = "旅へ戻る" if won else "結果を受け取る"
	result_overlay.visible = true


func play_slot_role_activation(role: String) -> void:
	var normalized := role.to_upper()
	var body := ""
	var accent := TEAL
	match normalized:
		"PAIR":
			body = "旅スキル +1"
			accent = Color("#76e0d0")
		"STRAIGHT":
			body = "旅スキル +2"
			accent = Color("#8fc9ff")
		"TRIPLE":
			body = "旅スキル MAX"
			accent = GOLD
		_:
			return
	_enqueue_activation({
		"kind": "role",
		"role": normalized,
		"title": "%s 成立！" % normalized,
		"body": body,
		"accent": accent,
	})
	_pulse_slot_faces(accent)


func play_blessing_activation(blessing_id: String, title: String, body: String) -> void:
	var accent := _blessing_accent(blessing_id)
	_enqueue_activation({
		"kind": "blessing",
		"blessing_id": blessing_id,
		"title": title,
		"body": body,
		"accent": accent,
	})
	var target := _blessing_button(blessing_id)
	if target != null and target.visible:
		_pulse_control(target, accent)


func _enqueue_activation(data: Dictionary) -> void:
	_activation_queue.append(data.duplicate(true))
	_try_play_next_activation()


func _try_play_next_activation() -> void:
	if _activation_playing or rule_guide_visible or activation_panel == null or _activation_queue.is_empty():
		return
	var data: Dictionary = _activation_queue.pop_front()
	_activation_playing = true
	_activation_serial += 1
	_run_activation(data, _activation_serial)


func _run_activation(data: Dictionary, serial: int) -> void:
	_pending_banner_clear()
	var accent: Color = data.get("accent", GOLD) as Color
	activation_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.04, 0.075, 0.97), accent, 18, 3))
	activation_title.text = str(data.get("title", "効果発動"))
	activation_title.add_theme_color_override("font_color", accent)
	activation_body.text = str(data.get("body", ""))
	var is_role := str(data.get("kind", "")) == "role"
	activation_role_badge.visible = is_role
	activation_icon.visible = not is_role
	if is_role:
		activation_role_badge.text = str(data.get("role", "ROLE"))
		activation_role_badge.add_theme_stylebox_override("normal", _panel_style(accent, Color.WHITE, 25, 2))
	else:
		activation_icon.texture = _blessing_activation_texture(str(data.get("blessing_id", "")))
	activation_panel.visible = true
	activation_panel.pivot_offset = activation_panel.size * 0.5
	if reduced_motion:
		activation_panel.modulate = Color.WHITE
		activation_panel.scale = Vector2.ONE
		await get_tree().create_timer(0.72).timeout
	else:
		activation_panel.modulate = Color(1, 1, 1, 0)
		activation_panel.scale = Vector2(0.92, 0.92)
		var enter := create_tween().set_parallel(true)
		enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		enter.tween_property(activation_panel, "modulate", Color.WHITE, 0.18)
		enter.tween_property(activation_panel, "scale", Vector2.ONE, 0.22)
		await enter.finished
		await get_tree().create_timer(0.70).timeout
		if not is_instance_valid(self) or serial != _activation_serial:
			return
		var exit_tween := create_tween().set_parallel(true)
		exit_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		exit_tween.tween_property(activation_panel, "modulate", Color(1, 1, 1, 0), 0.20)
		exit_tween.tween_property(activation_panel, "scale", Vector2(0.97, 0.97), 0.20)
		await exit_tween.finished
	if not is_instance_valid(self) or serial != _activation_serial:
		return
	activation_panel.visible = false
	activation_panel.modulate = Color.WHITE
	activation_panel.scale = Vector2.ONE
	_activation_playing = false
	_try_play_next_activation()


func _pulse_slot_faces(accent: Color) -> void:
	for face: DieFace in slot_faces:
		_pulse_control(face, accent)


func _pulse_control(control: Control, accent: Color) -> void:
	if control == null or reduced_motion:
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE
	control.modulate = Color.WHITE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(1.08, 1.08), 0.12)
	tween.parallel().tween_property(control, "modulate", Color(accent.r, accent.g, accent.b, 1.0), 0.12)
	tween.tween_property(control, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, 0.18)


func _blessing_button(blessing_id: String) -> Control:
	match blessing_id:
		"kiyomizu": return kiyomizu_button
		"tenryuji": return minus_button if minus_button != null and minus_button.visible else plus_button
		"mangan": return mangan_button
		_: return null


func _blessing_accent(blessing_id: String) -> Color:
	match blessing_id:
		"kiyomizu": return Color("#8fe8ff")
		"tenryuji": return Color("#9fdd8b")
		"mangan": return Color("#76e0d0")
		"fushimi": return Color("#ff795a")
		"yasaka": return GOLD
		_: return GOLD


func _blessing_activation_texture(blessing_id: String) -> Texture2D:
	match blessing_id:
		"kiyomizu": return _goshuin_icon(0)
		"tenryuji": return _goshuin_icon(1)
		"mangan": return _goshuin_icon(2)
		"fushimi": return _goshuin_icon(3)
		"yasaka": return YASAKA_ICON_TEXTURE
		_: return _goshuin_icon(3)


func show_banner(text_value: String, danger: bool = false) -> void:
	_banner_serial += 1
	var serial := _banner_serial
	message_label.text = text_value
	message_label.add_theme_color_override("font_color", Color("#ffb49e") if danger else GOLD)
	message_label.visible = true
	if reduced_motion:
		return
	_banner_lifetime(serial)


func _banner_lifetime(serial: int) -> void:
	await get_tree().create_timer(1.65).timeout
	if is_instance_valid(self) and serial == _banner_serial:
		message_label.visible = false


func _pending_banner_clear() -> void:
	_banner_serial += 1
	if message_label != null:
		message_label.visible = false


func present_roll(event: Dictionary) -> void:
	cancel_die_roll()
	var faces: Array = event.get("slot_faces", []) as Array
	var role := str(event.get("slot_role", ""))
	_refresh_slot_faces(faces)
	role_label.text = _role_text(role, faces)
	if not faces.is_empty() and not reduced_motion:
		var landing_index := mini(faces.size() - 1, slot_faces.size() - 1)
		if landing_index >= 0:
			var landing_face := slot_faces[landing_index]
			landing_face.scale = Vector2.ONE * 0.88
			landing_face.pivot_offset = landing_face.size * 0.5
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(landing_face, "scale", Vector2.ONE, 0.22)
	if faces.size() < 3:
		show_banner("出目 %d　道を%dマス引こう" % [int(event.get("move_steps", 0)), int(event.get("move_steps", 0))], false)
	else:
		show_banner("%s　今回は%dマス" % [_role_text(role, faces), int(event.get("move_steps", 0))], false)
		play_slot_role_activation(role)


func animate_cat_path(path: Array, finished: Callable) -> void:
	var typed_path: Array[Vector2i] = []
	for value: Variant in path:
		if value is Vector2i:
			typed_path.append(value)
	if typed_path.is_empty() or reduced_motion:
		if not typed_path.is_empty():
			_cat_visual_position = typed_path.back()
		_position_cat()
		finished.call()
		return
	_cat_animating = true
	_cat_visual_position = typed_path[0]
	_position_cat()
	for index: int in range(1, typed_path.size()):
		# Sprite positions live in the view's coordinate space. Include the
		# centered design origin so tall-phone layouts do not make the cat jump
		# away from the board while the path tween runs.
		var from := board_canvas.position + board_cell_center(typed_path[index - 1])
		var to := board_canvas.position + board_cell_center(typed_path[index])
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(_set_cat_center, from, to, 0.16)
		_cat_animation_frame = index % 4
		cat_sprite.texture = _cat_frame(_cat_animation_frame)
		await tween.finished
		_cat_visual_position = typed_path[index]
	_cat_animating = false
	cat_sprite.texture = _cat_frame(0)
	_position_cat()
	finished.call()


func _set_cat_center(center: Vector2) -> void:
	cat_sprite.position = center + Vector2(-31, -63)


func refresh() -> void:
	if controller == null or not is_instance_valid(controller) or title_label == null:
		return
	var state := controller.state
	# White fire is taught at the moment it is placed, never from the preview
	# row. This call is side-effect free after the first new signature.
	_maybe_show_white_fire_guide(state)
	seal_label.text = "封印 %d/3" % state.seal_count
	turn_label.text = "ターン %d" % state.turn_number
	difficulty_label.text = "白狐 Lv.%d" % state.difficulty_level
	var hp := int(player_context.get("hp", 0))
	var max_hp := clampi(int(player_context.get("max_hp", MAX_HEARTS)), 1, MAX_HEARTS)
	hp = clampi(hp, 0, max_hp)
	hp_label.text = "%s %d/%d" % [_heart_string(hp, max_hp), hp, max_hp]
	coin_label.text = "COIN %d" % int(player_context.get("coins", 0))
	fox_preview_label.text = _fox_preview_text(
		state.fox_preview_cells,
		state.fox_preview_due_turn,
		state.fox_preview_line_cut_edge,
		state.line_cut_preview_due_turn
	)
	_refresh_blessing_summary(state)
	mangan_button.visible = state.mangan_available
	mangan_button.disabled = state.mangan_armed or state.phase not in [
		ControllerScript.BattlePhase.ROLL_SLOT,
		ControllerScript.BattlePhase.PATH_INPUT,
		ControllerScript.BattlePhase.CAT_MOVING,
		ControllerScript.BattlePhase.FOX_ACTION,
	]
	mangan_button.text = "満願札\n防御中" if state.mangan_armed else "満願札\n狐火を防ぐ"
	var remaining: int = state.remaining_steps()
	move_label.text = "出目 %d" % state.move_steps if state.move_steps > 0 else "出目 —"
	remaining_label.text = "残り %d" % remaining if state.phase == ControllerScript.BattlePhase.PATH_INPUT else _phase_prompt(state.phase)
	if rule_guide_visible:
		# Keep the status band legible underneath the large modal. The complete
		# acknowledgement is already printed on the panel and its button.
		move_label.text = "説明中"
		remaining_label.text = "タップで閉じる"
	var faces: Array[int] = controller.slot_faces()
	if faces.is_empty() and not controller.last_completed_slot_faces().is_empty():
		faces = controller.last_completed_slot_faces()
	_refresh_slot_faces(faces)
	var role: String = str(controller.last_slot_role())
	role_label.text = _role_text(role, faces)
	if rule_guide_visible:
		role_label.text = "どこでもOK"
	roll_button.visible = state.phase in [
		ControllerScript.BattlePhase.ROLL_SLOT,
		ControllerScript.BattlePhase.PATH_INPUT,
	]
	roll_button.disabled = state.phase != ControllerScript.BattlePhase.ROLL_SLOT or rule_guide_visible
	roll_button_copy.text = "止める" if _die_rolling else ("振る" if state.phase == ControllerScript.BattlePhase.ROLL_SLOT else "出目済")
	action_panel.visible = state.phase == ControllerScript.BattlePhase.PATH_INPUT
	undo_button.disabled = state.current_input_path.size() <= 1
	var can_confirm := controller.can_confirm_path()
	confirm_button.disabled = not can_confirm
	confirm_button.text = "この道で進む" if can_confirm else ("あと%dマス選ぶ" % remaining if remaining > 0 else "道をつなげよう")
	miss_button.visible = controller.can_resolve_miss()
	miss_button.disabled = not controller.can_resolve_miss()
	kiyomizu_button.visible = state.kiyomizu_available and state.phase in [
		ControllerScript.BattlePhase.ROLL_SLOT,
		ControllerScript.BattlePhase.PATH_INPUT,
	]
	minus_button.visible = state.tenryuji_available and state.phase == ControllerScript.BattlePhase.PATH_INPUT and state.current_input_path.size() == 1
	plus_button.visible = minus_button.visible
	minus_button.disabled = state.move_steps <= 1
	plus_button.disabled = state.move_steps >= 6
	blessing_row.visible = not rule_guide_visible and (kiyomizu_button.visible or minus_button.visible or plus_button.visible)
	for position: Vector2i in cell_buttons:
		var button: Button = cell_buttons[position]
		var legal: bool = state.phase == ControllerScript.BattlePhase.PATH_INPUT and position in controller.legal_next_cells()
		var undo_target: bool = (
			state.phase == ControllerScript.BattlePhase.PATH_INPUT
			and state.current_input_path.size() >= 2
			and position == state.current_input_path[-2]
		)
		button.disabled = not legal and not undo_target
		button.focus_mode = Control.FOCUS_ALL if legal or undo_target else Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if legal or undo_target else Control.CURSOR_ARROW
		button.tooltip_text = _cell_tooltip(position, legal, undo_target)
		var cell_style := _cell_button_style(legal, undo_target, false)
		button.add_theme_stylebox_override("normal", cell_style)
		button.add_theme_stylebox_override("hover", _cell_button_style(legal, undo_target, true))
		button.add_theme_stylebox_override("focus", _cell_button_style(legal, undo_target, true))
		button.add_theme_stylebox_override("pressed", _cell_button_style(legal, undo_target, true))
		# Disabled cells still form the transparent interaction layer over the
		# authored board. Do not let the global Button theme paint ivory tiles over
		# the six-route artwork while the slot is waiting for a roll.
		button.add_theme_stylebox_override("disabled", cell_style)
	if not _cat_animating:
		_cat_visual_position = state.cat_position
		_position_cat()
	if state.phase == ControllerScript.BattlePhase.SPECIAL_RESOLVE and state.special_kind == &"SAKURA_PURIFY":
		if special_overlay != null and not special_overlay.visible:
			show_special_choice(controller.special_options())
	elif special_overlay != null and state.phase != ControllerScript.BattlePhase.SPECIAL_RESOLVE:
		special_overlay.visible = false
	board_canvas.queue_redraw()
	_layout_ui()


func board_cell_center(position: Vector2i) -> Vector2:
	var row := clampi(position.y, 0, BOARD_SIZE - 1)
	var column := clampi(position.x, 0, BOARD_SIZE - 1)
	var vertical_lines: PackedFloat32Array = BOARD_VERTICAL_LINES[row]
	return Vector2(
		lerpf(vertical_lines[column], vertical_lines[column + 1], 0.5),
		BOARD_ROW_CENTERS[row]
	)


func cell_touch_rect(position: Vector2i) -> Rect2:
	var row := clampi(position.y, 0, BOARD_SIZE - 1)
	var column := clampi(position.x, 0, BOARD_SIZE - 1)
	var vertical_lines: PackedFloat32Array = BOARD_VERTICAL_LINES[row]
	var cell_width := vertical_lines[column + 1] - vertical_lines[column]
	var cell_height := BOARD_ROW_BOUNDS[row + 1] - BOARD_ROW_BOUNDS[row]
	var target_size := Vector2(minf(TOUCH_SIZE.x, cell_width * 0.86), minf(TOUCH_SIZE.y, cell_height * 0.82))
	return Rect2(board_cell_center(position) - target_size * 0.5, target_size)


func _input(event: InputEvent) -> void:
	# The guide is a full-screen, one-tap acknowledgement. Handle it before
	# phase routing so a warning can never leave the player looking at a locked
	# board or waiting for a tiny button hit target.
	if rule_guide_visible:
		if event is InputEventScreenTouch:
			var guide_touch := event as InputEventScreenTouch
			_last_touch_time_usec = Time.get_ticks_usec()
			if guide_touch.pressed:
				dismiss_rule_guide()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton:
			if Time.get_ticks_usec() - _last_touch_time_usec < 120000:
				return
			var guide_mouse := event as InputEventMouseButton
			if guide_mouse.button_index == MOUSE_BUTTON_LEFT and guide_mouse.pressed:
				dismiss_rule_guide()
				get_viewport().set_input_as_handled()
			return
		return
	if controller == null or controller.state.phase != ControllerScript.BattlePhase.PATH_INPUT:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_last_touch_time_usec = Time.get_ticks_usec()
		if _handle_pointer_point(touch.position, touch.pressed):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag and _drag_active:
		var touch_drag := event as InputEventScreenDrag
		_last_touch_time_usec = Time.get_ticks_usec()
		_handle_pointer_motion(touch_drag.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		# Godot can synthesize a mouse click after a touch. The touch path above
		# already owns the gesture, so ignore that duplicate pair.
		if Time.get_ticks_usec() - _last_touch_time_usec < 120000:
			return
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if _handle_pointer_point(mouse_button.position, mouse_button.pressed):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _drag_active:
		if Time.get_ticks_usec() - _last_touch_time_usec < 120000:
			return
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_handle_pointer_motion(mouse_motion.position)
			get_viewport().set_input_as_handled()


func _handle_pointer_point(screen_position: Vector2, pressed: bool) -> bool:
	if pressed:
		var cell := _cell_from_screen_position(screen_position)
		if cell == Vector2i(-1, -1):
			# PATH_INPUT is active while the action bar is usable. A tap outside
			# the board must remain unhandled so Godot can deliver it to the GUI
			# button underneath (confirm, undo, or a blessing action).
			return false
		_drag_active = true
		_drag_started_cell = cell
		_drag_last_cell = cell
		_drag_moved = false
		# A direct tap on a legal neighbour is the short form of the same drag
		# gesture. Starting on the cat lets a held pointer continue across cells.
		if cell != controller.state.current_input_path.back() and cell in controller.legal_next_cells():
			_emit_drag_toward(cell)
		return true
	if not _drag_active:
		return false
	var release_cell := _cell_from_screen_position(screen_position)
	if not _drag_moved and release_cell != Vector2i(-1, -1) and release_cell == _drag_started_cell:
		if release_cell != controller.state.current_input_path.back() and release_cell in controller.legal_next_cells():
			_emit_drag_cell(release_cell)
	_drag_active = false
	_drag_started_cell = Vector2i(-1, -1)
	_drag_last_cell = Vector2i(-1, -1)
	_drag_moved = false
	return true


func _handle_pointer_motion(screen_position: Vector2) -> void:
	var cell := _cell_from_screen_position(screen_position)
	if cell == Vector2i(-1, -1) or cell == _drag_last_cell:
		return
	_emit_drag_toward(cell)


func _emit_drag_cell(cell: Vector2i) -> void:
	if controller == null or controller.state.phase != ControllerScript.BattlePhase.PATH_INPUT:
		return
	var legal := cell in controller.legal_next_cells()
	var undo_target := controller.state.current_input_path.size() >= 2 and cell == controller.state.current_input_path[-2]
	if not legal and not undo_target:
		return
	_drag_last_cell = cell
	_drag_moved = true
	cell_pressed.emit(cell)


func _emit_drag_toward(target: Vector2i) -> void:
	# Pointer samples can jump over a cell on a fast swipe. Walk the shortest
	# orthogonal segment so a continuous drag still produces one legal step at
	# a time instead of silently dropping the gesture.
	var guard := BOARD_SIZE * BOARD_SIZE
	while guard > 0 and controller != null and controller.state.phase == ControllerScript.BattlePhase.PATH_INPUT:
		var current: Vector2i = controller.state.current_input_path.back()
		if current == target:
			break
		var delta := target - current
		var next := current
		if absi(delta.x) >= absi(delta.y) and delta.x != 0:
			next.x += signi(delta.x)
		elif delta.y != 0:
			next.y += signi(delta.y)
		else:
			break
		var legal := next in controller.legal_next_cells()
		var undo_target := controller.state.current_input_path.size() >= 2 and next == controller.state.current_input_path[-2]
		if not legal and not undo_target:
			break
		_emit_drag_cell(next)
		guard -= 1


func _cell_from_screen_position(screen_position: Vector2) -> Vector2i:
	if board_input_layer == null or not board_input_layer.get_global_rect().has_point(screen_position):
		return Vector2i(-1, -1)
	var local_point := get_global_transform_with_canvas().affine_inverse() * screen_position
	var design_point := local_point - board_canvas.position
	# Classify the touch by the authored trapezoid cell bounds first. Nearest-
	# center classification is tempting, but at a perspective row boundary it
	# can jump over the adjacent cell during a quick drag on a phone.
	for row: int in range(BOARD_SIZE):
		if design_point.y < BOARD_ROW_BOUNDS[row] or design_point.y > BOARD_ROW_BOUNDS[row + 1]:
			continue
		var vertical_lines: PackedFloat32Array = BOARD_VERTICAL_LINES[row]
		for column: int in range(BOARD_SIZE):
			if design_point.x >= vertical_lines[column] and design_point.x <= vertical_lines[column + 1]:
				return Vector2i(column, row)
	var closest := Vector2i(-1, -1)
	var closest_distance := 66.0 * 66.0
	for row: int in range(BOARD_SIZE):
		for column: int in range(BOARD_SIZE):
			var position := Vector2i(column, row)
			var distance := design_point.distance_squared_to(board_cell_center(position))
			if distance < closest_distance:
				closest_distance = distance
				closest = position
	return closest


func _build_ui() -> void:
	# Tall phones expose more vertical canvas than the authored 720x1280 board.
	# A dark cover copy fills that extra area while the crisp foreground copy
	# stays at its native aspect, aligned with all gameplay coordinates.
	backdrop_fill = TextureRect.new()
	backdrop_fill.name = "BoardBackdropFill"
	backdrop_fill.texture = BOARD_TEXTURE
	backdrop_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop_fill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop_fill.modulate = Color(0.34, 0.30, 0.27, 1.0)
	backdrop_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop_fill)

	backdrop = TextureRect.new()
	backdrop.name = "BoardBackdrop"
	backdrop.texture = BOARD_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	dimmer = ColorRect.new()
	dimmer.name = "TopBottomVignette"
	dimmer.color = Color(0.015, 0.012, 0.02, 0.14)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	board_canvas = BoardCanvas.new()
	board_canvas.name = "BoardCanvas"
	board_canvas.owner_view = self
	add_child(board_canvas)

	fox_sprite = TextureRect.new()
	fox_sprite.name = "FoxGuardian"
	fox_sprite.texture = FOX_TEXTURE
	fox_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fox_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fox_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fox_sprite)

	for y: int in range(BOARD_SIZE):
		for x: int in range(BOARD_SIZE):
			var position := Vector2i(x, y)
			var button := Button.new()
			button.name = "Cell_%d_%d" % [x, y]
			button.text = ""
			button.flat = false
			button.custom_minimum_size = TOUCH_SIZE
			# Board input is handled by the shared pointer layer below so a held
			# touch can travel across cells without a Button stealing the drag.
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.focus_neighbor_top = NodePath("../Cell_%d_%d" % [x, maxi(y - 1, 0)])
			button.focus_neighbor_bottom = NodePath("../Cell_%d_%d" % [x, mini(y + 1, BOARD_SIZE - 1)])
			button.focus_neighbor_left = NodePath("../Cell_%d_%d" % [maxi(x - 1, 0), y])
			button.focus_neighbor_right = NodePath("../Cell_%d_%d" % [mini(x + 1, BOARD_SIZE - 1), y])
			button.pressed.connect(func() -> void: cell_pressed.emit(position))
			add_child(button)
			cell_buttons[position] = button

	board_input_layer = Control.new()
	board_input_layer.name = "BoardInputLayer"
	board_input_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_input_layer.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(board_input_layer)

	cat_sprite = TextureRect.new()
	cat_sprite.name = "ExplorerCat"
	cat_sprite.texture = _cat_frame(0)
	cat_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cat_sprite)

	_build_top_hud()
	_build_fox_bar()
	_build_slot_and_actions()
	_build_message()
	_build_activation_panel()
	_build_tutorial()
	_build_start_choice()
	_build_result_overlay()
	_build_special_choice()
	_build_rule_guide()
	resized.connect(_layout_ui)


func _build_top_hud() -> void:
	top_hud = PanelContainer.new()
	top_hud.name = "TopHUD"
	top_hud.add_theme_stylebox_override("panel", _panel_style(PANEL, DEEP_GOLD, 18, 3))
	add_child(top_hud)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 10)
	top_hud.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	margin.add_child(stack)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	stack.add_child(head)
	title_label = _label("狐火六路陣", 29, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	seal_label = _chip("封印 0/3", VERMILION)
	seal_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	head.add_child(seal_label)
	turn_label = _chip("ターン 1", GOLD)
	turn_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	head.add_child(turn_label)
	difficulty_label = _chip("白狐 Lv.1", TEAL)
	difficulty_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	head.add_child(difficulty_label)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	stack.add_child(stats)
	hp_label = _small_stat("♥♥♥ 3/3")
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(hp_label)
	coin_label = _small_stat("COIN 0")
	stats.add_child(coin_label)
	var objective := _label("鳥居へ止まり、3つの結界を完成", 15, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.clip_text = true
	stats.add_child(objective)


func _build_fox_bar() -> void:
	fox_bar = PanelContainer.new()
	fox_bar.name = "FoxActionBar"
	fox_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.055, 0.08, 0.94), Color("#825638"), 12, 2))
	add_child(fox_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	fox_bar.add_child(row)
	fox_preview_label = _label("次の狐火　なし", 21, INK, HORIZONTAL_ALIGNMENT_LEFT)
	fox_preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(fox_preview_label)
	blessing_label = HBoxContainer.new()
	blessing_label.name = "BlessingSummary"
	blessing_label.add_theme_constant_override("separation", 4)
	blessing_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(blessing_label)
	mangan_button = _button("満願札\n狐火を防ぐ", 13, false)
	mangan_button.custom_minimum_size = Vector2(154, 52)
	_attach_goshuin_icon(mangan_button, 2)
	mangan_button.pressed.connect(func() -> void: mangan_requested.emit())
	row.add_child(mangan_button)


func _build_slot_and_actions() -> void:
	status_panel = PanelContainer.new()
	status_panel.name = "MoveInfo"
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.045, 0.075, 0.94), Color("#775b31"), 13, 2))
	add_child(status_panel)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	status_panel.add_child(status_row)
	move_label = _label("出目 —", 27, INK, HORIZONTAL_ALIGNMENT_CENTER)
	move_label.custom_minimum_size = Vector2(120, 0)
	move_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	status_row.add_child(move_label)
	remaining_label = _label("右のサイコロを振ろう", 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	remaining_label.custom_minimum_size = Vector2(280, 0)
	remaining_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(remaining_label)
	role_label = _label("欲しい出目と役を見比べよう", 14, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	role_label.custom_minimum_size = Vector2(180, 0)
	role_label.clip_text = true
	role_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	status_row.add_child(role_label)

	slot_panel = PanelContainer.new()
	slot_panel.name = "SlotHost"
	slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.055, 0.96), DEEP_GOLD, 17, 3))
	add_child(slot_panel)
	var slot_content := Control.new()
	slot_content.name = "SlotContent"
	slot_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_content.mouse_filter = Control.MOUSE_FILTER_PASS
	slot_content.clip_contents = false
	slot_panel.add_child(slot_content)
	var slot_art := TextureRect.new()
	slot_art.name = "SlotTrayArt"
	slot_art.texture = SLOT_TRAY_TEXTURE
	slot_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Preserve the tray's authored proportions and crop only its ornamental top
	# and bottom. Stretching the whole 1576x747 source into a 448x116 strip made
	# the windows half-height while the dice stayed square.
	slot_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	slot_art.position = Vector2.ZERO
	slot_art.size = Vector2(480, 126)
	slot_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_content.add_child(slot_art)
	var slot_row := Control.new()
	slot_row.name = "SlotsRow"
	slot_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_content.add_child(slot_row)
	for index: int in range(3):
		var face := DieFace.new()
		face.name = "SlotFace%d" % index
		face.custom_minimum_size = Vector2(100, 100)
		face.position = Vector2(54.0 + float(index) * 139.0, 16.0)
		face.size = Vector2(100, 100)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.set_face(0, false)
		slot_row.add_child(face)
		slot_faces.append(face)
	var roll_ring := TextureRect.new()
	roll_ring.name = "RollRing"
	roll_ring.texture = ROLL_RING_TEXTURE
	roll_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	roll_ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	roll_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_ring.set_anchors_preset(Control.PRESET_TOP_LEFT)
	roll_ring.position = Vector2(520, 7)
	roll_ring.size = Vector2(108, 108)
	slot_content.add_child(roll_ring)
	roll_button = Button.new()
	roll_button.name = "RollButton"
	roll_button.text = ""
	roll_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	roll_button.position = Vector2(530, 10)
	roll_button.size = Vector2(88, 100)
	roll_button.add_theme_font_override("font", FONT)
	roll_button.add_theme_font_size_override("font_size", 20)
	roll_button.add_theme_color_override("font_color", GOLD)
	roll_button.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.12, 0.14, 0.80), Color(0, 0, 0, 0), 40, 0))
	roll_button.add_theme_stylebox_override("hover", _panel_style(Color(0.06, 0.25, 0.25, 0.95), GOLD, 40, 2))
	roll_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.03, 0.16, 0.17, 1), GOLD, 40, 3))
	roll_button.add_theme_stylebox_override("disabled", _panel_style(Color(0.025, 0.09, 0.10, 0.82), Color("#53605b"), 40, 1))
	roll_button.pressed.connect(func() -> void: roll_requested.emit())
	slot_content.add_child(roll_button)
	roll_button_die_icon = TextureRect.new()
	roll_button_die_icon.name = "RollButtonDieIcon"
	roll_button_die_icon.texture = DICE_UI_TEXTURE
	roll_button_die_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	roll_button_die_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	roll_button_die_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_button_die_icon.position = Vector2(14, 5)
	roll_button_die_icon.size = Vector2(60, 60)
	roll_button_die_icon.z_index = 1
	roll_button.add_child(roll_button_die_icon)
	roll_button_copy = _label("振る", 17, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	roll_button_copy.name = "RollButtonCopy"
	roll_button_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_button_copy.position = Vector2(0, 64)
	roll_button_copy.size = Vector2(88, 30)
	roll_button_copy.z_index = 2
	roll_button.add_child(roll_button_copy)

	action_panel = PanelContainer.new()
	action_panel.name = "ActionBar"
	action_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.035, 0.06, 0.96), Color("#75572f"), 16, 2))
	add_child(action_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	action_panel.add_child(row)
	undo_button = _button("1手戻す", 21, false)
	undo_button.custom_minimum_size = Vector2(166, 72)
	undo_button.pressed.connect(func() -> void: undo_requested.emit())
	row.add_child(undo_button)
	miss_button = _button("MISSで進む", 20, false, true)
	miss_button.custom_minimum_size = Vector2(176, 72)
	miss_button.pressed.connect(func() -> void: miss_requested.emit())
	row.add_child(miss_button)
	confirm_button = _button("この道で進む", 23, true)
	confirm_button.custom_minimum_size = Vector2(330, 72)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.pressed.connect(func() -> void: path_confirm_requested.emit())
	row.add_child(confirm_button)

	blessing_row = HBoxContainer.new()
	blessing_row.name = "BlessingActions"
	blessing_row.add_theme_constant_override("separation", 8)
	add_child(blessing_row)
	kiyomizu_button = _button("清水寺｜全振り直し ×1", 14, false)
	kiyomizu_button.custom_minimum_size = Vector2(220, 52)
	_attach_goshuin_icon(kiyomizu_button, 0)
	kiyomizu_button.pressed.connect(func() -> void: kiyomizu_requested.emit())
	blessing_row.add_child(kiyomizu_button)
	minus_button = _button("天龍寺｜出目 −1", 14, false)
	minus_button.custom_minimum_size = Vector2(168, 52)
	_attach_goshuin_icon(minus_button, 1)
	minus_button.pressed.connect(func() -> void: tenryuji_shift_requested.emit(-1))
	blessing_row.add_child(minus_button)
	plus_button = _button("天龍寺｜出目 +1", 14, false)
	plus_button.custom_minimum_size = Vector2(168, 52)
	_attach_goshuin_icon(plus_button, 1)
	plus_button.pressed.connect(func() -> void: tenryuji_shift_requested.emit(1))
	blessing_row.add_child(plus_button)
	blessing_row.visible = false


func _build_message() -> void:
	message_label = _label("", 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	message_label.name = "MessageBanner"
	message_label.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.025, 0.045, 0.96), DEEP_GOLD, 11, 2))
	message_label.visible = false
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message_label)


func _build_activation_panel() -> void:
	# One shared non-modal card is used for both slot roles and goshuin. It sits
	# above the board, ignores input, and queues activations so feedback never
	# steals a tap or leaves the battle waiting on an animation.
	activation_panel = PanelContainer.new()
	activation_panel.name = "EffectActivationCard"
	activation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activation_panel.z_index = 35
	activation_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.04, 0.075, 0.97), GOLD, 18, 3))
	add_child(activation_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 10)
	activation_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	margin.add_child(row)
	var emblem_host := Control.new()
	emblem_host.custom_minimum_size = Vector2(76, 76)
	emblem_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(emblem_host)
	activation_icon = TextureRect.new()
	activation_icon.name = "ActivationIcon"
	activation_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	activation_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	activation_icon.position = Vector2.ZERO
	activation_icon.size = Vector2(76, 76)
	activation_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem_host.add_child(activation_icon)
	activation_role_badge = _label("PAIR", 18, NAVY, HORIZONTAL_ALIGNMENT_CENTER)
	activation_role_badge.name = "RoleBadge"
	activation_role_badge.position = Vector2(1, 13)
	activation_role_badge.size = Vector2(74, 50)
	activation_role_badge.add_theme_stylebox_override("normal", _panel_style(GOLD, Color.WHITE, 25, 2))
	activation_role_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem_host.add_child(activation_role_badge)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	activation_title = _label("", 25, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	activation_title.custom_minimum_size = Vector2(0, 42)
	copy.add_child(activation_title)
	activation_body = _label("", 17, INK, HORIZONTAL_ALIGNMENT_LEFT)
	activation_body.custom_minimum_size = Vector2(0, 34)
	activation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(activation_body)
	activation_panel.visible = false


func _build_tutorial() -> void:
	tutorial_overlay = _modal_overlay("TutorialOverlay")
	add_child(tutorial_overlay)
	var card := _modal_card(Vector2(640, 760))
	tutorial_overlay.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	card.add_child(stack)
	tutorial_progress = _label("1 / 4", 18, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	tutorial_progress.custom_minimum_size = Vector2(0, 30)
	stack.add_child(tutorial_progress)
	tutorial_title = _label("", 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_title.custom_minimum_size = Vector2(0, 58)
	stack.add_child(tutorial_title)
	tutorial_art = TextureRect.new()
	tutorial_art.name = "TutorialArt"
	tutorial_art.texture = TUTORIAL_MOVE_TEXTURE
	tutorial_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tutorial_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tutorial_art.custom_minimum_size = Vector2(0, 244)
	tutorial_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tutorial_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(tutorial_art)
	tutorial_body = _label("", 25, INK, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_body.custom_minimum_size = Vector2(0, 126)
	stack.add_child(tutorial_body)
	tutorial_hint = _label("", 19, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_hint.custom_minimum_size = Vector2(0, 92)
	tutorial_hint.add_theme_stylebox_override("normal", _panel_style(Color(0.08, 0.07, 0.12, 0.94), DEEP_GOLD, 12, 2))
	stack.add_child(tutorial_hint)
	tutorial_button = _button("次へ", 23, true)
	tutorial_button.custom_minimum_size = Vector2(0, 76)
	tutorial_button.pressed.connect(_advance_tutorial)
	stack.add_child(tutorial_button)
	tutorial_overlay.visible = false


func _build_start_choice() -> void:
	start_overlay = _modal_overlay("StartToriiOverlay")
	add_child(start_overlay)
	var card := _modal_card(Vector2(630, 390))
	start_overlay.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	card.add_child(stack)
	stack.add_child(_label("伏見稲荷のご加護", 29, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	stack.add_child(_label("最初の鳥居を選べます", 21, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	for torii_id: int in range(4):
		var button := _button("鳥居 %s" % TORII_LABELS[torii_id], 20, torii_id == 0)
		button.custom_minimum_size = Vector2(0, 92)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: start_torii_selected.emit(torii_id))
		row.add_child(button)
		start_buttons.append(button)
	start_overlay.visible = false


func _build_result_overlay() -> void:
	result_overlay = _modal_overlay("ResultOverlay")
	add_child(result_overlay)
	var card := _modal_card(Vector2(620, 700))
	result_overlay.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 22)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	card.add_child(stack)
	result_art = TextureRect.new()
	result_art.name = "VictoryIllustration"
	result_art.texture = VICTORY_TEXTURE
	result_art.custom_minimum_size = Vector2(560, 320)
	result_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	result_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(result_art)
	result_title = _label("結界、完成。", 38, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(result_title)
	result_body = _label("", 24, INK, HORIZONTAL_ALIGNMENT_CENTER)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(result_body)
	result_button = _button("旅へ戻る", 24, true)
	result_button.custom_minimum_size = Vector2(0, 88)
	result_button.pressed.connect(func() -> void: result_continue_requested.emit())
	stack.add_child(result_button)
	result_overlay.visible = false


func _build_special_choice() -> void:
	special_overlay = _modal_overlay("SpecialChoiceOverlay")
	add_child(special_overlay)
	var card := _modal_card(Vector2(620, 430))
	special_overlay.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 26)
	card.add_child(stack)
	special_title = _label("桜守の浄化", 31, Color("#f7a9c4"), HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(special_title)
	special_body = _label("浄化する狐火を選んでください", 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	special_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(special_body)
	special_action_container = GridContainer.new()
	special_action_container.columns = 2
	special_action_container.add_theme_constant_override("h_separation", 10)
	special_action_container.add_theme_constant_override("v_separation", 10)
	special_action_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(special_action_container)
	special_skip_button = _button("今回は見送る", 19, false)
	special_skip_button.custom_minimum_size = Vector2(0, 64)
	special_skip_button.pressed.connect(func() -> void: special_skip_requested.emit())
	stack.add_child(special_skip_button)
	special_overlay.visible = false


func _build_rule_guide() -> void:
	rule_guide_dimmer = ColorRect.new()
	rule_guide_dimmer.name = "BoardRuleGuideDimmer"
	rule_guide_dimmer.color = Color(0.006, 0.008, 0.022, 0.66)
	rule_guide_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	rule_guide_dimmer.z_index = 40
	rule_guide_dimmer.visible = false
	add_child(rule_guide_dimmer)
	rule_guide_panel = PanelContainer.new()
	rule_guide_panel.name = "BoardRuleGuide"
	rule_guide_panel.custom_minimum_size = Vector2(660, 270)
	rule_guide_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	rule_guide_panel.z_index = 43
	rule_guide_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.035, 0.07, 0.96), GOLD, 16, 3))
	add_child(rule_guide_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	rule_guide_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(row)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 8)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(copy)
	rule_guide_title = _label("まず覚えること", 31, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	rule_guide_title.custom_minimum_size = Vector2(0, 52)
	copy.add_child(rule_guide_title)
	rule_guide_body = _label("", 20, INK, HORIZONTAL_ALIGNMENT_LEFT)
	rule_guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_guide_body.clip_text = true
	rule_guide_body.custom_minimum_size = Vector2(0, 150)
	copy.add_child(rule_guide_body)
	rule_guide_button = _button("画面タップで閉じる", 18, true)
	rule_guide_button.custom_minimum_size = Vector2(160, 108)
	rule_guide_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule_guide_button.pressed.connect(dismiss_rule_guide)
	row.add_child(rule_guide_button)
	rule_guide_panel.visible = false


func _refresh_rule_guide_copy() -> void:
	if rule_guide_body == null or controller == null:
		return
	if rule_guide_kind == GUIDE_WHITE_FIRE:
		rule_guide_title.text = "危険マスが出現"
		rule_guide_body.text = "白い狐火は通れない。\n止まることもできない。\n安全なマスだけを選ぼう。"
	else:
		rule_guide_title.text = "最初の目標"
		rule_guide_body.text = "鳥居に、出目の数ぴったりで止まろう。\n1マスでもずれると封印できません。"


func _layout_ui() -> void:
	if backdrop == null:
		return
	# Keep the authored 720x1280 composition centered in expanded tall windows.
	# The backdrop covers the full expanded viewport; gameplay geometry remains
	# exactly aligned to the center 1280 design slice.
	var viewport_size := size
	var design_origin := Vector2((viewport_size.x - DESIGN_SIZE.x) * 0.5, (viewport_size.y - DESIGN_SIZE.y) * 0.5)
	backdrop_fill.position = Vector2.ZERO
	backdrop_fill.size = viewport_size
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	dimmer.position = Vector2.ZERO
	dimmer.size = viewport_size
	board_canvas.position = design_origin
	board_canvas.size = DESIGN_SIZE
	board_input_layer.position = design_origin + Vector2(54, 458)
	board_input_layer.size = Vector2(612, 504)
	fox_sprite.position = design_origin + Vector2(286, 330)
	fox_sprite.size = Vector2(150, 150)
	for position: Vector2i in cell_buttons:
		var button: Button = cell_buttons[position]
		var rect := cell_touch_rect(position)
		button.position = design_origin + rect.position
		button.size = rect.size
	cat_sprite.size = Vector2(62, 82)
	if not _cat_animating:
		_position_cat(design_origin)
	top_hud.position = design_origin + Vector2(24, 20)
	top_hud.size = Vector2(672, 108)
	fox_bar.position = design_origin + Vector2(24, 136)
	fox_bar.size = Vector2(672, 58)
	# Bottom controls follow the regular map's vertical bands. Blessings get
	# their own row below the tray instead of being painted over the slot faces.
	# The final action band ends at the 1280 design edge on the compact path
	# input state, so nothing can cover the board or fall below the safe area.
	status_panel.position = design_origin + Vector2(36, 950)
	status_panel.size = Vector2(648, 48)
	slot_panel.position = design_origin + Vector2(36, 1004)
	slot_panel.size = Vector2(648, 126)
	var blessing_visible := blessing_row.visible
	blessing_row.position = design_origin + Vector2(72, 1136)
	blessing_row.size = Vector2(576, 52)
	action_panel.position = design_origin + Vector2(36, 1192 if blessing_visible else 1140)
	action_panel.size = Vector2(648, 88)
	message_label.position = design_origin + Vector2(65, 205)
	message_label.size = Vector2(590, 52)
	if activation_panel != null:
		activation_panel.position = design_origin + Vector2(82, 210)
		activation_panel.size = Vector2(556, 104)
	if rule_guide_dimmer != null:
		rule_guide_dimmer.position = Vector2.ZERO
		rule_guide_dimmer.size = viewport_size
	if rule_guide_panel != null:
		rule_guide_panel.position = design_origin + Vector2(30, 220)
		rule_guide_panel.size = Vector2(660, 270)
	for overlay: Control in [tutorial_overlay, start_overlay, result_overlay, special_overlay]:
		overlay.position = Vector2.ZERO
		overlay.size = viewport_size


func _position_cat(origin: Vector2 = Vector2(INF, INF)) -> void:
	if origin.x == INF:
		origin = board_canvas.position
	var center := origin + board_cell_center(_cat_visual_position)
	cat_sprite.position = center + Vector2(-31, -63)


func _advance_tutorial() -> void:
	if _tutorial_page >= 3:
		tutorial_overlay.visible = false
		tutorial_finished.emit()
		return
	_tutorial_page += 1
	_tutorial_anim_elapsed = 0.0
	_refresh_tutorial()


func _refresh_tutorial() -> void:
	var pages := [
		["出目どおりにマスを進む", "3ROLL SLOTで出た数だけ、猫を上下左右へ進めよう。\n光るマスの中央を1つずつタップ。\n移動数はすべて使い切ろう！"],
		["鳥居にぴったり止まる", "別の鳥居へぴったり止まると封印+1！\n封印3/3で勝利。\n通り過ぎただけでは封印されない。"],
		["次の狐火を読む", "白い狐火があるマスは通れない。\n半透明の狐火は、次に塞がれる場所の予告。\n予告を見て、今ほしい出目を狙おう！"],
		["御朱印のご加護", "京都で集めた御朱印は、白狐戦で力を貸してくれる。\n持っているご加護を使って六路を切り開こう。"],
	]
	tutorial_progress.text = "%d / 4" % (_tutorial_page + 1)
	tutorial_title.text = pages[_tutorial_page][0]
	tutorial_body.text = pages[_tutorial_page][1]
	tutorial_art.texture = _tutorial_texture_for_page(_tutorial_page)
	tutorial_hint.text = _tutorial_hint_text()
	tutorial_button.text = "白狐に挑む" if _tutorial_page == 3 else "次へ"
	_refresh_tutorial_animation()


func _tutorial_hint_text() -> String:
	match _tutorial_page:
		0:
			return "出目 4　→　①マス　→　②マス　→　③マス　→　④マス"
		1:
			return "ぴったり停止　→　封印 +1　→　封印 3/3"
		2:
			return "鳥居まであと4マス　→　今は「4」が欲しい！"
		3:
			return _tutorial_blessing_hint()
		_:
			return ""


func _tutorial_blessing_hint() -> String:
	if controller == null:
		return "持っているご加護だけ、ここに表示されるよ。"
	var state := controller.state
	var blessings: Array[String] = []
	if state.fushimi_start_choice_available:
		blessings.append("伏見稲荷［開始時］鳥居を選ぶ")
	if state.yasaka_delay_available:
		blessings.append("八坂［自動発動］最初の狐火を遅らせる")
	if state.kiyomizu_available:
		blessings.append("清水寺［下のボタン］3個を全振り直し")
	if state.tenryuji_available:
		blessings.append("天龍寺［出目確定後］−1 / ＋1")
	if state.mangan_available:
		blessings.append("満願札［上のボタン］次の狐火を防ぐ")
	if blessings.is_empty():
		return "まだ御朱印がなくても大丈夫。出目と道だけで挑めるよ。"
	return "\n".join(blessings)


func _refresh_tutorial_animation() -> void:
	if tutorial_hint == null:
		return
	if _tutorial_page == 0:
		var sequence := [
			"出目 4　→　①マス",
			"出目 4　→　①マス　→　②マス",
			"出目 4　→　①マス　→　②マス　→　③マス",
			"出目 4　→　①マス　→　②マス　→　③マス　→　④マス",
		]
		var step_index := mini(int(_tutorial_anim_elapsed / 0.42), sequence.size() - 1)
		tutorial_hint.text = sequence[step_index]
	if tutorial_art != null and not reduced_motion:
		var glow := 0.97 + sin(_tutorial_anim_elapsed * 2.2) * 0.03
		tutorial_art.modulate = Color(glow, glow, glow, 1.0)


func _refresh_slot_faces(faces: Array) -> void:
	for index: int in range(slot_faces.size()):
		var value: int = int(faces[index]) if index < faces.size() else 0
		slot_faces[index].set_face(value, index == faces.size() - 1 and value > 0)


func _role_text(role: String, faces: Array) -> String:
	if faces.size() < 3:
		return "SLOT %d/3　PAIR / TRIPLE" % faces.size()
	match role:
		"TRIPLE": return "TRIPLE　同じ出目が3つ"
		"PAIR": return "PAIR　同じ出目が2つ"
		"STRAIGHT": return "STRAIGHT　連番完成"
		_: return "MIX　次は欲しい出目を狙おう"


func _fox_preview_text(cells: Array[Vector2i], due_turn: int = 0, line_cut_edge: String = "", line_cut_due_turn: int = 0) -> String:
	if cells.is_empty() and line_cut_edge.is_empty():
		return "次の狐火　なし（白狐は様子見）"
	var turn_text := "TURN %d" % due_turn if due_turn > 0 else "次回"
	var text := "△ 次の狐火：%s" % turn_text if not cells.is_empty() else ""
	if cells.size() >= 2:
		text += "（候補2つ）"
	if not line_cut_edge.is_empty():
		var cut_turn := "TURN %d" % line_cut_due_turn if line_cut_due_turn > 0 else "次回"
		text += ("　／ " if not text.is_empty() else "") + "✂ 線切断：%s" % cut_turn
	return text


func _tutorial_texture_for_page(page: int) -> Texture2D:
	match clampi(page, 0, 3):
		0: return TUTORIAL_MOVE_TEXTURE
		1: return TUTORIAL_TORII_TEXTURE
		2: return TUTORIAL_FIRE_TEXTURE
		_: return TUTORIAL_BLESSINGS_TEXTURE


func _refresh_blessing_summary(state: FoxFireBattleState) -> void:
	if blessing_label == null:
		return
	for child: Node in blessing_label.get_children():
		child.free()
	var title := _label("できること", 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size = Vector2(54, 32)
	blessing_label.add_child(title)
	_add_summary_icon(state.kiyomizu_available, 0, "清水寺　全振り直し ×1")
	_add_summary_icon(state.tenryuji_available, 1, "天龍寺　出目±1 ×1")
	_add_summary_icon(state.mangan_available, 2, "満願札　白狐行動無効 ×1")
	if blessing_label.get_child_count() == 1:
		blessing_label.add_child(_label("なし", 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT))


func _add_summary_icon(available: bool, icon_index: int, tooltip: String) -> void:
	if not available:
		return
	var icon := TextureRect.new()
	icon.texture = _goshuin_icon(icon_index)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(30, 30)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.tooltip_text = tooltip
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blessing_label.add_child(icon)


func _goshuin_icon(icon_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = GOSHUIN_ICONS_TEXTURE
	var column := icon_index % 2
	var row := icon_index / 2
	var cell_size := Vector2(float(GOSHUIN_ICONS_TEXTURE.get_width()) * 0.5, float(GOSHUIN_ICONS_TEXTURE.get_height()) * 0.5)
	atlas.region = Rect2(Vector2(float(column), float(row)) * cell_size, cell_size)
	atlas.filter_clip = true
	return atlas


func _attach_goshuin_icon(button: Button, icon_index: int) -> void:
	# Use a real texture instead of emoji glyphs so the blessing affordance is
	# stable across platforms and remains legible in the compact mobile HUD.
	var icon := TextureRect.new()
	icon.texture = _goshuin_icon(icon_index)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(8, 8)
	icon.size = Vector2(36, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 1
	button.add_child(icon)
	button.alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _phase_prompt(phase: int) -> String:
	match phase:
		ControllerScript.BattlePhase.ROLL_SLOT: return "右のサイコロを振ろう"
		ControllerScript.BattlePhase.CAT_MOVING: return "猫が狐火の道を進んでいる"
		ControllerScript.BattlePhase.FOX_ACTION: return "白狐の一手"
		ControllerScript.BattlePhase.VICTORY: return "3つの結界が完成"
		ControllerScript.BattlePhase.DEFEAT: return "白狐に道を閉ざされた"
		_: return "道を見極めよう"


func _heart_string(hp: int, max_hp: int) -> String:
	var hearts := ""
	var displayed := mini(max_hp, MAX_HEARTS)
	for index: int in range(displayed):
		hearts += "♥" if index < hp else "♡"
	return hearts


func _cell_tooltip(position: Vector2i, legal: bool, undo_target: bool) -> String:
	if undo_target:
		return "1手戻す"
	if legal:
		return "ここへ1マス進む"
	var torii_id := controller.torii_id_at(position) if controller != null else -1
	return "鳥居 %s" % TORII_LABELS[torii_id] if torii_id >= 0 else "街路"


func _cat_frame(frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CAT_STRIP
	atlas.region = Rect2(float(clampi(frame, 0, 3)) * 192.0, 0, 192, 192)
	return atlas


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _chip(text_value: String, accent: Color) -> Label:
	var label := _label(text_value, 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(94, 42)
	label.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.035, 0.07, 0.88), accent, 9, 2))
	return label


func _small_stat(text_value: String) -> Label:
	var label := _label(text_value, 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(105, 32)
	return label


func _button(text_value: String, font_size: int, primary: bool, danger: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_disabled_color", Color("#77746c"))
	var base := VERMILION_DARK if primary else Color("#17182a")
	var border := GOLD if primary else (VERMILION if danger else Color("#80643b"))
	button.add_theme_stylebox_override("normal", _panel_style(base, border, 13, 3 if primary else 2))
	button.add_theme_stylebox_override("hover", _panel_style(base.lightened(0.12), GOLD, 13, 3))
	button.add_theme_stylebox_override("focus", _panel_style(base.lightened(0.10), Color.WHITE, 13, 4))
	button.add_theme_stylebox_override("pressed", _panel_style(base.darkened(0.12), GOLD, 13, 3))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.12, 0.12, 0.13, 0.92), Color("#494743"), 13, 1))
	return button


func _panel_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 6
	return style


func _cell_button_style(legal: bool, undo_target: bool, emphasized: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.035 if legal else 0.0)
	style.border_color = (
		Color(1.0, 0.91, 0.56, 0.96)
		if legal else (Color(0.42, 0.85, 0.80, 0.88) if undo_target else Color(0, 0, 0, 0))
	)
	style.set_border_width_all(4 if emphasized else (3 if legal or undo_target else 0))
	style.set_corner_radius_all(38)
	return style


func _modal_overlay(node_name: String) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = node_name
	overlay.color = Color(0.008, 0.008, 0.018, 0.83)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return overlay


func _modal_card(minimum: Vector2) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = minimum
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = -minimum * 0.5
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.04, 0.08, 0.98), GOLD, 22, 3))
	return card
