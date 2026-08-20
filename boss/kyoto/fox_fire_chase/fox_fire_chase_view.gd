class_name FoxFireChaseView
extends Control

## Presentation layer for the Kyoto "狐火追陣" battle.
##
## The game board is deliberately drawn as six-by-six square cells.  The
## source plate contains guide lines and points for atmosphere, but all
## gameplay markers and hit targets use the centre of a cell, never a line or
## an intersection.  The authored 720x1280 composition is scaled as one unit
## so the same UI remains readable at 360x640 and on tall phones.

signal roll_requested
signal tutorial_finished
signal head_start_requested
signal fire_choice_requested(choice: StringName)
signal result_continue_requested

const DESIGN_SIZE := Vector2(720.0, 1280.0)
const BOARD_TEXTURE: Texture2D = preload("res://assets/art/backgrounds/fox-fire-six-routes-board.png")
const CAT_STRIP: Texture2D = preload("res://assets/art/bosses/kyoto/explorer-cat-move-strip.png")
const FOX_RUN_FRAMES: Array[Texture2D] = [
	preload("res://assets/art/bosses/kyoto/fox_fire_chase/white_fox_run/01.png"),
	preload("res://assets/art/bosses/kyoto/fox_fire_chase/white_fox_run/02.png"),
	preload("res://assets/art/bosses/kyoto/fox_fire_chase/white_fox_run/03.png"),
	preload("res://assets/art/bosses/kyoto/fox_fire_chase/white_fox_run/04.png"),
]
const FIRE_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/white-foxfire.png")
const SLOT_TRAY_TEXTURE: Texture2D = preload("res://assets/art/ui/common/slot-tray-luxury-v1.png")
const ROLL_RING_TEXTURE: Texture2D = preload("res://assets/art/ui/common/roll-button-round-v1.png")
const DICE_UI_TEXTURE: Texture2D = preload("res://assets/art/ui/common/dice-ivory-brass.png")
const VICTORY_TEXTURE: Texture2D = preload("res://assets/art/bosses/kyoto/fox-fire-victory-key-art-explorer-cat.png")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const BOARD_SCRIPT = preload("res://boss/kyoto/fox_fire_chase/fox_fire_chase_board.gd")
const ROLL_DIE_CELL := Vector2i(2, 2)

const NAVY := Color("#080d1e")
const PANEL := Color(0.035, 0.045, 0.09, 0.95)
const INK := Color("#f8edcf")
const MUTED := Color("#c8b995")
const GOLD := Color("#f6d471")
const GOLD_DARK := Color("#a8772c")
const TEAL := Color("#38c9c2")
const TEAL_DARK := Color("#0d5f67")
const VERMILION := Color("#e9564d")
const VERMILION_DARK := Color("#742a2d")
const FIRE_BLUE := Color("#8feeff")

const PHASE_PRE_BATTLE := 0
const PHASE_ROLL_READY := 1
const PHASE_FIRE_CHOICE := 2
const PHASE_TURN_RESOLVED := 3
const PHASE_VICTORY := 4
const PHASE_DEFEAT := 5

# The live board is an enlarged crop of the authored Kyoto plate.  Geometry is
# measured in the original 720x1280 artwork and transformed into the crop, so
# pieces sit at the visual centre of a square cell rather than on a guide-line
# intersection.
const BOARD_CROP_SOURCE := Rect2(70.0, 420.0, 580.0, 590.0)
const BOARD_CROP_DISPLAY := Rect2(24.0, 246.0, 672.0, 700.0)
const TOUCH_SIZE := Vector2(104.0, 104.0)
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

class DieFace extends Control:
	var value: int = 0
	var emphasized: bool = false
	var active: bool = false
	var font: Font
	var ink := Color("#17131a")
	var paper := Color("#f8edcf")
	var gold := Color("#f6d471")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func set_value(next_value: int, next_emphasized: bool = false) -> void:
		value = clampi(next_value, 0, 6)
		emphasized = next_emphasized
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2(3, 3), size - Vector2(6, 6))
		draw_style_box(_face_style(), rect)
		if value <= 0:
			var hint := Label.new()
			# A native draw call keeps the slot light and avoids emoji/font drift.
			draw_string(font, Vector2(size.x * 0.5 - 8, size.y * 0.5 + 8), "·", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.35, 0.32, 0.26, 0.48))
			return
		for dot: Vector2 in _pip_positions(value):
			draw_circle(Vector2(dot.x * size.x, dot.y * size.y), minf(size.x, size.y) * 0.075, ink)

	func _face_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = paper
		style.border_color = gold if emphasized or active else Color("#c3a46c")
		style.set_border_width_all(4 if emphasized else 2)
		style.set_corner_radius_all(14)
		style.shadow_color = Color(0, 0, 0, 0.42)
		style.shadow_size = 7
		return style

	func _pip_positions(face: int) -> Array[Vector2]:
		var left := 0.28
		var centre := 0.50
		var right := 0.72
		var top := 0.28
		var middle := 0.50
		var bottom := 0.72
		match face:
			1: return [Vector2(centre, middle)]
			2: return [Vector2(left, top), Vector2(right, bottom)]
			3: return [Vector2(left, top), Vector2(centre, middle), Vector2(right, bottom)]
			4: return [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]
			5: return [Vector2(left, top), Vector2(right, top), Vector2(centre, middle), Vector2(left, bottom), Vector2(right, bottom)]
			6: return [Vector2(left, top), Vector2(right, top), Vector2(left, middle), Vector2(right, middle), Vector2(left, bottom), Vector2(right, bottom)]
		return []

class BoardOverlay extends Control:
	var owner_view: FoxFireChaseView

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if owner_view == null:
			return
		for row: int in range(6):
			for column: int in range(6):
				var position := Vector2i(column, row)
				var rect := owner_view.cell_rect(position)
				var is_outer := BOARD_SCRIPT.is_outer_position(position)
				var fill := Color(0.08, 0.62, 0.62, 0.06) if is_outer else Color(0.03, 0.04, 0.11, 0.10)
				draw_rect(rect, fill, true)
				if is_outer:
					draw_rect(rect, Color(0.98, 0.83, 0.37, 0.56), false, 3.0)

		var fires: Array = owner_view._fire_indices()
		for raw_index: Variant in fires:
			var cell := BOARD_SCRIPT.outer_position(int(raw_index))
			var rect := owner_view.cell_rect(cell).grow(-7.0)
			draw_rect(rect, Color(0.25, 0.80, 0.95, 0.11), true)
			draw_rect(rect, Color(0.49, 0.93, 1.0, 0.72), false, 2.0)

		for path: Array in [owner_view.last_cat_path, owner_view.last_fox_path]:
			if path.size() < 2:
				continue
			for index: int in range(1, path.size()):
				var a := owner_view.board_cell_center(owner_view._coerce_position(path[index - 1]))
				var b := owner_view.board_cell_center(owner_view._coerce_position(path[index]))
				draw_line(a, b, Color(1.0, 0.92, 0.57, 0.44), 4.0, true)

var controller: Node
var reduced_motion: bool = false
var context: Dictionary = {"lap": 1, "coins": 0, "hp": 3, "max_hp": 3}
var design_root: Control
var backdrop: TextureRect
var board_plate: TextureRect
var board_overlay: BoardOverlay
var top_hud: Panel
var preview_panel: Panel
var title_label: Label
var advantage_bar: Panel
var cat_advantage_fill: ColorRect
var fox_advantage_fill: ColorRect
var cat_portrait: TextureRect
var fox_portrait: TextureRect
var distance_label: Label
var advantage_label: Label
var fox_preview_label: Label
var goshuin_label: Label
var status_panel: Panel
var status_label: Label
var board_canvas: Control
var cat_sprite: TextureRect
var fox_sprite: TextureRect
var fire_sprites: Array[TextureRect] = []
var slot_panel: Panel
var slot_faces: Array[DieFace] = []
var slot_role_label: Label
var slot_explainer: Panel
var slot_explainer_label: Label
var roll_button: TextureButton
var roll_die_icon: TextureRect
var roll_button_copy: Label
var roll_button_hint: Label
var head_start_button: Button
var head_start_label: Label
var tutorial_overlay: Control
var tutorial_progress: Label
var tutorial_title: Label
var tutorial_body: Label
var tutorial_art: Control
var tutorial_button: Button
var fire_choice_overlay: Control
var fire_choice_sheet: Panel
var fire_choice_title: Label
var fire_choice_body: Label
var cleanse_button: Button
var detour_button: Button
var result_overlay: Control
var result_art: TextureRect
var result_title: Label
var result_body: Label
var result_button: Button
var last_event: Dictionary = {}
var last_cat_path: Array = []
var last_fox_path: Array = []
var _tutorial_page: int = 0
var _slot_explainer_timer: float = 0.0
var _roll_phase: bool = false
var _last_cat_position := Vector2i(2, 5)
var _last_fox_position := Vector2i(3, 0)
var _layout_viewport_size := Vector2.ZERO
var _layout_root_size := Vector2.ZERO


func _ready() -> void:
	set_process(true)
	_build_composition()
	resized.connect(_layout_composition)
	_layout_composition()


func bind_controller(next_controller: Node) -> void:
	controller = next_controller
	if is_node_ready():
		refresh()


func set_player_context(next_context: Dictionary) -> void:
	context = next_context.duplicate(true)
	_refresh_context_labels()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if reduced_motion:
		_roll_phase = false
		if roll_button_copy != null:
			roll_button_copy.text = "ROLL"
		if roll_button_hint != null:
			roll_button_hint.text = "狙って止める"
		if roll_die_icon != null:
			roll_die_icon.rotation = 0.0
			roll_die_icon.scale = Vector2.ONE
		if slot_explainer != null:
			slot_explainer.modulate = Color.WHITE
	queue_redraw()


func board_cell_center(position: Vector2i) -> Vector2:
	var safe_row := clampi(position.y, 0, 5)
	var safe_column := clampi(position.x, 0, 5)
	var lines := BOARD_VERTICAL_LINES[safe_row]
	var source_center := Vector2(
		(lines[safe_column] + lines[safe_column + 1]) * 0.5,
		BOARD_ROW_CENTERS[safe_row]
	)
	return _board_source_to_display(source_center)


func cell_rect(position: Vector2i) -> Rect2:
	var safe_row := clampi(position.y, 0, 5)
	var safe_column := clampi(position.x, 0, 5)
	var lines := BOARD_VERTICAL_LINES[safe_row]
	var source_top_left := Vector2(lines[safe_column], BOARD_ROW_BOUNDS[safe_row])
	var source_bottom_right := Vector2(lines[safe_column + 1], BOARD_ROW_BOUNDS[safe_row + 1])
	var display_top_left := _board_source_to_display(source_top_left)
	var display_bottom_right := _board_source_to_display(source_bottom_right)
	return Rect2(display_top_left, display_bottom_right - display_top_left).grow(-4.0)


func cell_touch_rect(position: Vector2i) -> Rect2:
	return Rect2(board_cell_center(position) - TOUCH_SIZE * 0.5, TOUCH_SIZE)


func show_tutorial() -> void:
	_tutorial_page = 0
	_refresh_tutorial()
	if tutorial_overlay != null:
		tutorial_overlay.visible = true


func hide_tutorial() -> void:
	if tutorial_overlay != null:
		tutorial_overlay.visible = false


func show_fire_choice(outer_index: int, goshuin_count: int) -> void:
	if fire_choice_overlay == null:
		return
	fire_choice_title.text = "狐火に遭遇"
	fire_choice_body.text = "白狐が塞いだマスをどうする？\n御朱印 %d" % goshuin_count
	cleanse_button.visible = goshuin_count > 0
	cleanse_button.disabled = goshuin_count <= 0
	fire_choice_overlay.visible = true


func hide_fire_choice() -> void:
	if fire_choice_overlay != null:
		fire_choice_overlay.visible = false


func show_result(result: Dictionary) -> void:
	if result_overlay == null:
		return
	var victory := bool(result.get("victory", false))
	result_title.text = "追陣、完成。" if victory else "狐火に追いつかれた"
	result_body.text = (
		"白狐との距離を読み切った。\n御朱印の道が、次の旅を照らす。"
		if victory
		else "外周の火を越えられなかった。\n次はあと一手を早く。"
	)
	result_art.visible = victory
	result_overlay.visible = true


func present_roll(event: Dictionary) -> void:
	last_event = event.duplicate(true)
	last_cat_path = event.get("cat_path", []) as Array
	last_fox_path = event.get("fox_path", []) as Array
	refresh()
	var role := str(event.get("slot_role", ""))
	if not role.is_empty():
		slot_role_label.text = "%s  +%d" % [role, int(event.get("slot_bonus", 0))]
	else:
		slot_role_label.text = "SLOT %d / 3" % slot_faces.size()
	if slot_faces.size() >= 3:
		show_slot_explainer()


func animate_turn(event: Dictionary) -> void:
	if cat_sprite == null or fox_sprite == null:
		return
	var cat_path: Array = event.get("cat_path", []) as Array
	var fox_path: Array = event.get("fox_path", []) as Array
	if reduced_motion:
		refresh()
		return
	var cat_start := _coerce_position(event.get("cat_start", _last_cat_position))
	var fox_start := _coerce_position(event.get("fox_start", _last_fox_position))
	cat_sprite.position = board_cell_center(cat_start) - cat_sprite.size * 0.5
	fox_sprite.position = board_cell_center(fox_start) - fox_sprite.size * 0.5
	for raw_position: Variant in fox_path:
		await _tween_piece_to_cell(fox_sprite, _coerce_position(raw_position), 0.105)
	for raw_position: Variant in cat_path:
		await _tween_piece_to_cell(cat_sprite, _coerce_position(raw_position), 0.115)
	refresh()


func _tween_piece_to_cell(piece: Control, cell: Vector2i, duration: float) -> void:
	if not is_instance_valid(piece):
		return
	var target := board_cell_center(cell) - piece.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "position", target, duration)
	await tween.finished


func show_slot_explainer() -> void:
	if slot_explainer == null:
		return
	slot_explainer_label.text = "3投目でSLOT完成\nPAIR +1 / STRAIGHT +2 / TRIPLE +3"
	slot_explainer.visible = true
	_slot_explainer_timer = 3.0


func begin_die_roll() -> bool:
	if roll_button == null or roll_button.disabled:
		return false
	_roll_phase = true
	if roll_die_icon != null:
		roll_die_icon.visible = true
	roll_button_copy.text = "止める"
	roll_button_hint.text = "もう一度タップ"
	return true


func finish_die_roll() -> void:
	_roll_phase = false
	roll_button_copy.text = "ROLL"
	roll_button_hint.text = "狙って止める"


func is_die_rolling() -> bool:
	return _roll_phase


func refresh() -> void:
	if controller == null:
		return
	var state := controller.get("state") as Object
	if state == null:
		return
	var cat_position := _coerce_position(state.get("cat_position"))
	var fox_position := _coerce_position(state.get("fox_position"))
	_last_cat_position = cat_position
	_last_fox_position = fox_position
	if cat_sprite != null:
		cat_sprite.texture = _cat_frame(int(Time.get_ticks_msec() / 170) % 4)
		cat_sprite.position = board_cell_center(cat_position) - cat_sprite.size * 0.5
	if fox_sprite != null:
		fox_sprite.texture = FOX_RUN_FRAMES[int(Time.get_ticks_msec() / 250) % FOX_RUN_FRAMES.size()]
		fox_sprite.position = board_cell_center(fox_position) - fox_sprite.size * 0.5
	_refresh_fire_sprites()
	_refresh_hud(state)
	_refresh_slots(state)
	if int(_state_get(state, "phase", PHASE_PRE_BATTLE)) == PHASE_FIRE_CHOICE:
		show_fire_choice(int(_state_get(state, "pending_fire_progress", -1)), int(_state_get(state, "goshuin_count", 0)))
	else:
		hide_fire_choice()
	queue_redraw()
	if board_overlay != null:
		board_overlay.queue_redraw()


func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	# Headless SceneTree harnesses can resize the root Window before the child
	# viewport is relaid out.  Trust the smaller root size in that brief window;
	# on a normal device both values are identical.
	var root_size := Vector2(get_tree().root.size)
	if root_size.x > 0.0 and root_size.y > 0.0 and (root_size.x < viewport_size.x or root_size.y < viewport_size.y):
		viewport_size = root_size
	if (viewport_size != _layout_viewport_size or root_size != _layout_root_size) and viewport_size.x > 0.0 and viewport_size.y > 0.0:
		_layout_composition()
	if _slot_explainer_timer > 0.0:
		_slot_explainer_timer -= delta
		if _slot_explainer_timer <= 0.0 and slot_explainer != null:
			slot_explainer.visible = false
	if not reduced_motion and cat_sprite != null and controller != null:
		cat_sprite.texture = _cat_frame(int(Time.get_ticks_msec() / 170) % 4)
		fox_sprite.texture = FOX_RUN_FRAMES[int(Time.get_ticks_msec() / 250) % FOX_RUN_FRAMES.size()]
	if roll_die_icon != null:
		if _roll_phase and not reduced_motion:
			roll_die_icon.rotation += delta * 7.4
			var pulse := 1.0 + sin(float(Time.get_ticks_msec()) * 0.018) * 0.06
			roll_die_icon.scale = Vector2.ONE * pulse
		else:
			roll_die_icon.rotation = lerp_angle(roll_die_icon.rotation, 0.0, minf(delta * 12.0, 1.0))
			roll_die_icon.scale = roll_die_icon.scale.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))


func _build_composition() -> void:
	design_root = Control.new()
	design_root.name = "Design"
	design_root.custom_minimum_size = DESIGN_SIZE
	design_root.size = DESIGN_SIZE
	design_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(design_root)

	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.texture = BOARD_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.position = Vector2.ZERO
	backdrop.size = DESIGN_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(backdrop)

	var board_atlas := AtlasTexture.new()
	board_atlas.atlas = BOARD_TEXTURE
	board_atlas.region = BOARD_CROP_SOURCE
	board_plate = TextureRect.new()
	board_plate.name = "BoardPlate"
	board_plate.texture = board_atlas
	board_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_plate.stretch_mode = TextureRect.STRETCH_SCALE
	board_plate.position = BOARD_CROP_DISPLAY.position
	board_plate.size = BOARD_CROP_DISPLAY.size
	board_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_plate.z_index = 1
	design_root.add_child(board_plate)

	board_overlay = BoardOverlay.new()
	board_overlay.name = "BoardOverlay"
	board_overlay.owner_view = self
	board_overlay.size = DESIGN_SIZE
	board_overlay.z_index = 5
	design_root.add_child(board_overlay)

	_build_top_hud()
	_build_board_pieces()
	_build_bottom_controls()
	_build_tutorial()
	_build_fire_choice()
	_build_result()


func _build_top_hud() -> void:
	title_label = _label("狐火追陣", 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.position = Vector2(24, 18)
	title_label.size = Vector2(672, 48)
	design_root.add_child(title_label)

	top_hud = Panel.new()
	top_hud.name = "AdvantageHUD"
	top_hud.position = Vector2(24, 68)
	top_hud.size = Vector2(672, 170)
	top_hud.add_theme_stylebox_override("panel", _panel_style(PANEL, GOLD_DARK, 24, 2))
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(top_hud)

	cat_portrait = TextureRect.new()
	cat_portrait.texture = _cat_frame(0)
	cat_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat_portrait.position = Vector2(34, 78)
	cat_portrait.size = Vector2(142, 142)
	cat_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(cat_portrait)
	fox_portrait = TextureRect.new()
	fox_portrait.texture = FOX_RUN_FRAMES[0]
	fox_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fox_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fox_portrait.position = Vector2(544, 78)
	fox_portrait.size = Vector2(142, 142)
	fox_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(fox_portrait)

	advantage_bar = Panel.new()
	advantage_bar.position = Vector2(150, 104)
	advantage_bar.size = Vector2(420, 58)
	advantage_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.08, 0.14, 0.96), GOLD_DARK, 24, 2))
	advantage_bar.clip_contents = true
	advantage_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(advantage_bar)
	cat_advantage_fill = ColorRect.new()
	cat_advantage_fill.color = Color(0.05, 0.66, 0.70, 0.82)
	cat_advantage_fill.position = Vector2(4, 4)
	cat_advantage_fill.size = Vector2(206, 50)
	cat_advantage_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advantage_bar.add_child(cat_advantage_fill)
	fox_advantage_fill = ColorRect.new()
	fox_advantage_fill.color = Color(0.82, 0.16, 0.16, 0.82)
	fox_advantage_fill.position = Vector2(210, 4)
	fox_advantage_fill.size = Vector2(206, 50)
	fox_advantage_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advantage_bar.add_child(fox_advantage_fill)

	advantage_label = _label("PLAYER　　　　　　　　　白狐", 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
	advantage_label.position = Vector2(158, 118)
	advantage_label.size = Vector2(404, 30)
	advantage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(advantage_label)

	distance_label = _label("あと 5", 46, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	distance_label.position = Vector2(250, 140)
	distance_label.size = Vector2(220, 52)
	distance_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	distance_label.add_theme_constant_override("shadow_offset_x", 2)
	distance_label.add_theme_constant_override("shadow_offset_y", 3)
	design_root.add_child(distance_label)

	preview_panel = Panel.new()
	preview_panel.name = "PreviewPanel"
	preview_panel.position = Vector2(182, 204)
	preview_panel.size = Vector2(356, 36)
	preview_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.035, 0.075, 0.94), TEAL_DARK, 14, 2))
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(preview_panel)
	fox_preview_label = _label("白狐 Lv1　狐火 0", 18, INK, HORIZONTAL_ALIGNMENT_LEFT)
	fox_preview_label.position = Vector2(194, 205)
	fox_preview_label.size = Vector2(180, 30)
	design_root.add_child(fox_preview_label)
	goshuin_label = _label("御朱印 0", 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	goshuin_label.position = Vector2(374, 205)
	goshuin_label.size = Vector2(152, 30)
	design_root.add_child(goshuin_label)


func _build_board_pieces() -> void:
	board_canvas = Control.new()
	board_canvas.name = "BoardCanvas"
	board_canvas.position = Vector2.ZERO
	board_canvas.size = DESIGN_SIZE
	board_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_canvas.z_index = 10
	design_root.add_child(board_canvas)

	cat_sprite = TextureRect.new()
	cat_sprite.name = "PlayerCat"
	cat_sprite.texture = _cat_frame(0)
	cat_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat_sprite.size = Vector2(66, 66)
	cat_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_canvas.add_child(cat_sprite)
	fox_sprite = TextureRect.new()
	fox_sprite.name = "WhiteFox"
	fox_sprite.texture = FOX_RUN_FRAMES[0]
	fox_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fox_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fox_sprite.size = Vector2(68, 68)
	fox_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_canvas.add_child(fox_sprite)


func _build_bottom_controls() -> void:
	status_panel = Panel.new()
	status_panel.name = "StatusPanel"
	status_panel.position = Vector2(36, 936)
	status_panel.size = Vector2(648, 52)
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.07, 0.92), TEAL_DARK, 14, 2))
	design_root.add_child(status_panel)
	status_label = _label("ROLLで白狐を追う", 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	status_label.position = Vector2(44, 942)
	status_label.size = Vector2(632, 40)
	design_root.add_child(status_label)

	slot_panel = Panel.new()
	slot_panel.name = "SlotPanel"
	slot_panel.position = Vector2(36, 994)
	slot_panel.size = Vector2(648, 130)
	slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.025, 0.055, 0.97), GOLD_DARK, 20, 2))
	design_root.add_child(slot_panel)
	var tray := TextureRect.new()
	tray.name = "SlotTrayArt"
	tray.texture = SLOT_TRAY_TEXTURE
	tray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tray.position = Vector2(6, 6)
	tray.size = Vector2(636, 118)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(tray)
	var slot_label := _label("SLOT", 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var slot_chip := Panel.new()
	slot_chip.position = Vector2(12, 34)
	slot_chip.size = Vector2(96, 62)
	slot_chip.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.06, 0.88), GOLD_DARK, 10, 1))
	slot_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(slot_chip)
	slot_label.position = Vector2(18, 42)
	slot_label.size = Vector2(84, 46)
	slot_panel.add_child(slot_label)
	for index: int in range(3):
		var die := DieFace.new()
		die.font = FONT
		die.name = "DieFace%d" % index
		die.position = Vector2(122 + index * 112, 20)
		die.size = Vector2(94, 94)
		die.set_value(0)
		slot_panel.add_child(die)
		slot_faces.append(die)
	var role_chip := Panel.new()
	role_chip.position = Vector2(454, 34)
	role_chip.size = Vector2(184, 62)
	role_chip.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.03, 0.06, 0.88), GOLD_DARK, 10, 1))
	role_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(role_chip)
	slot_role_label = _label("SLOT 0 / 3", 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	slot_role_label.position = Vector2(464, 42)
	slot_role_label.size = Vector2(164, 46)
	slot_panel.add_child(slot_role_label)

	slot_explainer = Panel.new()
	slot_explainer.name = "SlotExplainer"
	slot_explainer.position = Vector2(108, 875)
	slot_explainer.size = Vector2(504, 86)
	slot_explainer.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.08, 0.12, 0.98), TEAL, 15, 2))
	slot_explainer.z_index = 18
	slot_explainer.visible = false
	design_root.add_child(slot_explainer)
	slot_explainer_label = _label("", 18, INK, HORIZONTAL_ALIGNMENT_CENTER)
	slot_explainer_label.position = Vector2(14, 8)
	slot_explainer_label.size = Vector2(476, 70)
	slot_explainer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot_explainer.add_child(slot_explainer_label)

	roll_button = TextureButton.new()
	roll_button.name = "RollButton"
	roll_button.texture_normal = ROLL_RING_TEXTURE
	roll_button.texture_hover = ROLL_RING_TEXTURE
	roll_button.texture_pressed = ROLL_RING_TEXTURE
	roll_button.ignore_texture_size = true
	roll_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	roll_button.position = Vector2(272, 1104)
	roll_button.size = Vector2(176, 176)
	roll_button.tooltip_text = "出目を決める"
	roll_button.pressed.connect(func() -> void: roll_requested.emit())
	design_root.add_child(roll_button)
	roll_die_icon = TextureRect.new()
	roll_die_icon.name = "RollingDieIcon"
	roll_die_icon.texture = DICE_UI_TEXTURE
	roll_die_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	roll_die_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	roll_die_icon.position = Vector2(56, 10)
	roll_die_icon.size = Vector2(64, 64)
	roll_die_icon.pivot_offset = Vector2(32, 32)
	roll_die_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_die_icon.position = board_cell_center(ROLL_DIE_CELL) - roll_die_icon.size * 0.5
	roll_die_icon.z_index = 16
	board_canvas.add_child(roll_die_icon)
	roll_button_copy = _label("ROLL", 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	roll_button_copy.position = Vector2(272, 1170)
	roll_button_copy.size = Vector2(176, 42)
	roll_button_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(roll_button_copy)
	roll_button_hint = _label("狙って止める", 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
	roll_button_hint.position = Vector2(272, 1208)
	roll_button_hint.size = Vector2(176, 28)
	roll_button_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(roll_button_hint)

	head_start_button = _button("先行 +1　3 coin", 18, false)
	head_start_button.name = "HeadStartButton"
	head_start_button.position = Vector2(480, 1156)
	head_start_button.size = Vector2(204, 56)
	head_start_button.pressed.connect(func() -> void: head_start_requested.emit())
	design_root.add_child(head_start_button)
	head_start_label = _label("", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	head_start_label.position = Vector2(480, 1214)
	head_start_label.size = Vector2(204, 28)
	design_root.add_child(head_start_label)


func _build_tutorial() -> void:
	tutorial_overlay = _overlay("TutorialOverlay")
	design_root.add_child(tutorial_overlay)
	var card := Panel.new()
	card.name = "TutorialCard"
	card.position = Vector2(50, 300)
	card.size = Vector2(620, 610)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.04, 0.09, 0.99), GOLD, 24, 3))
	tutorial_overlay.add_child(card)
	tutorial_progress = _label("1 / 3", 18, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	tutorial_progress.position = Vector2(30, 20)
	tutorial_progress.size = Vector2(560, 34)
	card.add_child(tutorial_progress)
	tutorial_title = _label("3ROLL SLOTで追いつく", 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_title.position = Vector2(26, 70)
	tutorial_title.size = Vector2(568, 54)
	card.add_child(tutorial_title)
	tutorial_art = Control.new()
	tutorial_art.name = "TutorialArt"
	tutorial_art.position = Vector2(66, 138)
	tutorial_art.size = Vector2(488, 180)
	card.add_child(tutorial_art)
	tutorial_body = _label("", 21, INK, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_body.position = Vector2(30, 335)
	tutorial_body.size = Vector2(560, 150)
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(tutorial_body)
	tutorial_button = _button("次へ", 23, true)
	tutorial_button.position = Vector2(86, 520)
	tutorial_button.size = Vector2(448, 66)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	card.add_child(tutorial_button)


func _build_fire_choice() -> void:
	fire_choice_overlay = _overlay("FireChoiceOverlay")
	design_root.add_child(fire_choice_overlay)
	fire_choice_sheet = Panel.new()
	fire_choice_sheet.name = "FireChoiceBottomSheet"
	fire_choice_sheet.position = Vector2(24, 850)
	fire_choice_sheet.size = Vector2(672, 406)
	fire_choice_sheet.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.04, 0.09, 0.99), FIRE_BLUE, 24, 3))
	fire_choice_overlay.add_child(fire_choice_sheet)
	fire_choice_title = _label("狐火に遭遇", 29, FIRE_BLUE, HORIZONTAL_ALIGNMENT_CENTER)
	fire_choice_title.position = Vector2(30, 28)
	fire_choice_title.size = Vector2(612, 48)
	fire_choice_sheet.add_child(fire_choice_title)
	fire_choice_body = _label("白狐が塞いだマスをどうする？", 19, INK, HORIZONTAL_ALIGNMENT_CENTER)
	fire_choice_body.position = Vector2(30, 84)
	fire_choice_body.size = Vector2(612, 70)
	fire_choice_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fire_choice_sheet.add_child(fire_choice_body)
	cleanse_button = _button("浄化する\n御朱印を1つ使う", 19, true)
	cleanse_button.position = Vector2(46, 190)
	cleanse_button.size = Vector2(280, 132)
	cleanse_button.pressed.connect(func() -> void: fire_choice_requested.emit(&"CLEANSE"))
	fire_choice_sheet.add_child(cleanse_button)
	detour_button = _button("内側へ迂回", 19, false)
	detour_button.position = Vector2(364, 190)
	detour_button.size = Vector2(260, 132)
	detour_button.pressed.connect(func() -> void: fire_choice_requested.emit(&"DETOUR"))
	fire_choice_sheet.add_child(detour_button)


func _build_result() -> void:
	result_overlay = _overlay("ResultOverlay")
	design_root.add_child(result_overlay)
	var card := Panel.new()
	card.position = Vector2(42, 220)
	card.size = Vector2(636, 760)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.035, 0.08, 0.99), GOLD, 24, 3))
	result_overlay.add_child(card)
	result_art = TextureRect.new()
	result_art.name = "VictoryArt"
	result_art.texture = VICTORY_TEXTURE
	result_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_art.position = Vector2(74, 42)
	result_art.size = Vector2(488, 320)
	result_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(result_art)
	result_title = _label("追陣、完成。", 34, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	result_title.position = Vector2(28, 390)
	result_title.size = Vector2(580, 58)
	card.add_child(result_title)
	result_body = _label("", 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	result_body.position = Vector2(36, 468)
	result_body.size = Vector2(564, 120)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(result_body)
	result_button = _button("旅へ戻る", 22, true)
	result_button.position = Vector2(84, 650)
	result_button.size = Vector2(468, 70)
	result_button.pressed.connect(func() -> void: result_continue_requested.emit())
	card.add_child(result_button)
	result_overlay.visible = false
	fire_choice_overlay.visible = false
	tutorial_overlay.visible = false


func _refresh_hud(state: Object) -> void:
	var distance := maxi(int(state.get("fox_progress")) - int(state.get("cat_progress")), 0)
	distance_label.text = "あと %d" % distance
	var cat_share := clampf((20.0 - float(distance)) / 20.0, 0.08, 0.92)
	var usable_width := 412.0
	cat_advantage_fill.size.x = usable_width * cat_share
	fox_advantage_fill.position.x = 4.0 + cat_advantage_fill.size.x
	fox_advantage_fill.size.x = usable_width - cat_advantage_fill.size.x
	advantage_label.text = (
		"PLAYER 優勢　　　　　　　　　白狐" if distance < 10
		else ("PLAYER　　　　　　　　　白狐 優勢" if distance > 10 else "PLAYER　　　　　　互角　　　　　　白狐")
	)
	var level := int(_state_get(state, "difficulty_level", 1))
	fox_preview_label.text = "白狐 Lv%d　狐火 %d" % [level, _fire_indices().size()]
	goshuin_label.text = "御朱印 %d" % int(_state_get(state, "goshuin_count", context.get("goshuin", 0)))
	_refresh_context_labels()
	match int(_state_get(state, "phase", PHASE_PRE_BATTLE)):
		PHASE_PRE_BATTLE: status_label.text = "先行を買って、追陣を始めよう"
		PHASE_ROLL_READY: status_label.text = "ROLLで出目を決める"
		PHASE_FIRE_CHOICE: status_label.text = "狐火を越える方法を選ぶ"
		PHASE_TURN_RESOLVED: status_label.text = "次のROLLで追陣を続ける"
		PHASE_VICTORY: status_label.text = "白狐に追いついた"
		PHASE_DEFEAT: status_label.text = "白狐に追いつかれた"
		_: status_label.text = "狐火の気配を読む"


func _refresh_context_labels() -> void:
	if head_start_label == null:
		return
	var coins := int(context.get("coins", 0))
	var state := controller.get("state") as Object if controller != null else null
	var count := int(_state_get(state, "head_start_count", 0)) if state != null else 0
	var pre_battle := state == null or int(_state_get(state, "phase", 0)) == PHASE_PRE_BATTLE
	head_start_button.visible = pre_battle
	head_start_label.visible = pre_battle
	head_start_button.disabled = coins < 3 or count >= 2 or not pre_battle
	head_start_label.text = "%d coin　残り%d回" % [coins, maxi(0, 2 - count)]


func _board_source_to_display(source_position: Vector2) -> Vector2:
	var scale_value := BOARD_CROP_DISPLAY.size / BOARD_CROP_SOURCE.size
	return BOARD_CROP_DISPLAY.position + (source_position - BOARD_CROP_SOURCE.position) * scale_value


func _refresh_slots(state: Object) -> void:
	var faces: Array = _state_get(state, "slot_faces", []) as Array
	for index: int in range(slot_faces.size()):
		slot_faces[index].set_value(int(faces[index]) if index < faces.size() else 0, index == faces.size() - 1 and faces.size() > 0)
	if faces.size() >= 3:
		slot_role_label.text = "%s  +%d" % [str(_state_get(state, "last_slot_role", "MIX")), int(_state_get(state, "last_slot_bonus", 0))]
	else:
		slot_role_label.text = "SLOT %d / 3" % faces.size()


func _refresh_fire_sprites() -> void:
	for sprite: TextureRect in fire_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	fire_sprites.clear()
	for raw_index: Variant in _fire_indices():
		var sprite := TextureRect.new()
		sprite.name = "FoxFire_%d" % int(raw_index)
		sprite.texture = FIRE_TEXTURE
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.size = Vector2(52, 58)
		sprite.position = board_cell_center(BOARD_SCRIPT.outer_position(int(raw_index))) - sprite.size * 0.5
		sprite.modulate = Color(0.78, 0.98, 1.0, 0.96)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.z_index = 12
		board_canvas.add_child(sprite)
		fire_sprites.append(sprite)


func _fire_indices() -> Array:
	if controller == null or not controller.has_method("fox_fire_outer_indices"):
		return []
	return controller.call("fox_fire_outer_indices") as Array


func _on_tutorial_button_pressed() -> void:
	if _tutorial_page < 2:
		_tutorial_page += 1
		_refresh_tutorial()
	else:
		hide_tutorial()
		tutorial_finished.emit()


func _refresh_tutorial() -> void:
	var pages := [
		["3ROLL SLOTで追いつく", "3回の出目をためてSLOTを完成。\nPAIR +1 / STRAIGHT +2 / TRIPLE +3\n猫と白狐は、マスの中央を1つずつ進む。"],
		["外周20マスを読む", "白狐は外周を先に進む。\n黄色く光る外周のマスが、追陣の舞台。\n大きな「あとN」が優勢を知らせる。"],
		["狐火は選べる", "狐火で外周が塞がったら、御朱印で浄化するか、内側へ迂回。\nROLLで追陣を始めよう。"],
	]
	tutorial_progress.text = "%d / 3" % (_tutorial_page + 1)
	tutorial_title.text = pages[_tutorial_page][0]
	tutorial_body.text = pages[_tutorial_page][1]
	tutorial_button.text = "狐火追陣を始める" if _tutorial_page == 2 else "次へ"
	_refresh_tutorial_art()


func _refresh_tutorial_art() -> void:
	for child: Node in tutorial_art.get_children():
		child.queue_free()
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(132, 132)
	icon.position = Vector2(178, 10)
	icon.texture = _cat_frame(_tutorial_page)
	tutorial_art.add_child(icon)
	var fox_icon := TextureRect.new()
	fox_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fox_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fox_icon.size = Vector2(132, 132)
	fox_icon.position = Vector2(278, 10)
	fox_icon.texture = FOX_RUN_FRAMES[(_tutorial_page + 1) % 4]
	tutorial_art.add_child(fox_icon)
	var caption := _label("□　□　□　□　□　□", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	caption.position = Vector2(12, 138)
	caption.size = Vector2(464, 36)
	tutorial_art.add_child(caption)


func _cat_frame(frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CAT_STRIP
	atlas.region = Rect2(float(clampi(frame, 0, 3)) * 192.0, 0, 192, 192)
	return atlas


func _coerce_position(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value as Vector2i
	if value is Vector2:
		return Vector2i(roundi((value as Vector2).x), roundi((value as Vector2).y))
	if value is Array and (value as Array).size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(0, 0)


func _state_get(state: Object, key: String, fallback: Variant) -> Variant:
	var value: Variant = state.get(key)
	return fallback if value == null else value


func _overlay(node_name: String) -> Control:
	var overlay := Control.new()
	overlay.name = node_name
	overlay.position = Vector2.ZERO
	overlay.size = DESIGN_SIZE
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 40
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.005, 0.008, 0.02, 0.78)
	dimmer.size = DESIGN_SIZE
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)
	return overlay


func _layout_composition() -> void:
	if design_root == null:
		return
	var viewport_size := get_viewport_rect().size
	var root_size := Vector2(get_tree().root.size)
	if root_size.x > 0.0 and root_size.y > 0.0 and (root_size.x < viewport_size.x or root_size.y < viewport_size.y):
		viewport_size = root_size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = size
	_layout_viewport_size = viewport_size
	_layout_root_size = root_size
	var scale_value := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	if scale_value <= 0.0:
		scale_value = 1.0
	design_root.scale = Vector2(scale_value, scale_value)
	design_root.position = Vector2((viewport_size.x - DESIGN_SIZE.x * scale_value) * 0.5, (viewport_size.y - DESIGN_SIZE.y * scale_value) * 0.5)


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _button(text_value: String, font_size: int, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var fill := TEAL_DARK if primary else Color("#17182a")
	button.add_theme_stylebox_override("normal", _panel_style(fill, GOLD if primary else GOLD_DARK, 16, 2))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.12), GOLD, 16, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.12), GOLD, 16, 3))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.12, 0.12, 0.14, 0.9), Color("#4e4c48"), 16, 1))
	return button


func _panel_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 7
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
