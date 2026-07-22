extends Control

class DiceFaceControl extends Control:
	var face_value: int = 1
	const PIP := Color("#3b3027")
	const PIP_SHADOW := Color(0.16, 0.11, 0.07, 0.20)

	func _init(value: int = 1) -> void:
		face_value = clampi(value, 1, 6)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var offset := minf(size.x, size.y) * 0.25
		var positions: Array[Vector2] = []
		match face_value:
			1: positions = [center]
			2: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, offset)]
			3: positions = [center + Vector2(-offset, -offset), center, center + Vector2(offset, offset)]
			4: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, -offset), center + Vector2(-offset, offset), center + Vector2(offset, offset)]
			5: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, -offset), center, center + Vector2(-offset, offset), center + Vector2(offset, offset)]
			6: positions = [center + Vector2(-offset, -offset), center + Vector2(offset, -offset), center + Vector2(-offset, 0), center + Vector2(offset, 0), center + Vector2(-offset, offset), center + Vector2(offset, offset)]
		var radius := minf(size.x, size.y) * 0.075
		for pip: Vector2 in positions:
			draw_circle(pip + Vector2(1.5, 2.0), radius + 0.8, PIP_SHADOW)
			draw_circle(pip, radius, PIP)

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const BoardModelScript = preload("res://scripts/game/board_model.gd")
const BoardViewScript = preload("res://scripts/game/board_view.gd")
const TourismMapViewScript = preload("res://scripts/game/tourism_map_view.gd")
const BossSystemScript = preload("res://scripts/game/boss_system.gd")
const EventSystemScript = preload("res://scripts/game/event_system.gd")
const RewardResolverScript = preload("res://scripts/game/reward_resolver.gd")
const LapSystemScript = preload("res://scripts/game/lap_system.gd")
const LandmarkSystemScript = preload("res://scripts/game/landmark_system.gd")
const DiceAudioControllerScript = preload("res://scripts/game/dice_audio_controller.gd")
const DicePresentation3DScript = preload("res://scripts/game/dice_presentation_3d.gd")
const MapDiceOverlayScript = preload("res://scripts/game/map_dice_overlay.gd")
const PopupBookTransitionScript = preload("res://scripts/game/popup_book_transition.gd")
const CAIRO_BACKGROUND: Texture2D = preload("res://assets/art/backgrounds/cairo-board.png")
const WORLD_MAP_BACKGROUND: Texture2D = preload("res://assets/art/backgrounds/world-travel-map.png")
const CAIRO_CITY_CARD: Texture2D = preload("res://assets/art/city_cards/cairo-city-card.png")
const SPHINX_TEXTURE: Texture2D = preload("res://assets/art/bosses/sleepy-sphinx.png")
const UI_CLICK_STREAM: AudioStream = preload("res://assets/audio/ui/click_003.ogg")
const UI_CONFIRM_STREAM: AudioStream = preload("res://assets/audio/ui/select_001.ogg")
const APP_FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const BG := Color("#efe2c6")
const INK := Color("#4c3c2e")
const TEAL := Color("#287b80")
const GOLD := Color("#c79c48")
const MUTED := Color("#8c7862")

var rng := RandomNumberGenerator.new()
var root_stack: VBoxContainer
var board_view: BoardView
var board_view_mode: String = "tourism"
var dice_row: HBoxContainer
var dice_presentation: SubViewportContainer
var map_dice_overlay: MapDiceOverlay
var dice_audio: Node
var ui_audio_player: AudioStreamPlayer
var role_label: Label
var memo_label: Label
var roll_button: Button
var confirm_five_button: Button
var stop_all_button: Button
var mode_label: Label
var boss_label: Label
var boss_gauge: ProgressBar
var boss_presence_label: Label
var lap_label: Label
var rolls_label: Label
var coin_label: Label
var stamp_label: Label
var minimap_view: BoardView
var landmark_level_label: Label
var debug_box: VBoxContainer
var dice_mode: int = 3
var dice_values: Array[int] = []
var selected_indices: Array[int] = []
var moving: bool = false
var rolling_dice: bool = false
var locked_dice_count: int = 0
var rolling_values: Array[int] = []
var fixed_targets: Array[int] = []
var tile_types: Array[StringName] = []
var boss_definitions: Array[Dictionary] = []
var modal_open: bool = false
var mode_buttons: Array[Label] = []
var event_definitions: Array[Dictionary] = []
var event_state: StringName = &"IDLE"
var last_roll_early_stopped: bool = false
var roll_visual_frame: int = 0
var active_extra_left_stop: Button
var active_extra_all_stop: Button
var qa_map_die_visible_stop_ok := false

func _ready() -> void:
	rng.seed = 20260711
	tile_types = BoardModelScript.build_tile_types()
	boss_definitions = BossSystemScript.definitions()
	event_definitions = EventSystemScript.definitions()
	GameState.ensure_boss_data()
	_apply_theme()
	var debug_route := OS.get_environment("DICE_DEBUG_ROUTE").strip_edges()
	if debug_route in BoardModelScript.VALID_ROUTE_IDS:
		GameState.set_route_position(debug_route, OS.get_environment("DICE_DEBUG_ROUTE_TILE").to_int())
	if not OS.get_environment("DICE_DEBUG_FLOW").is_empty():
		GameState.flow_level = clampi(OS.get_environment("DICE_DEBUG_FLOW").to_int(), 0, 5)
	if not OS.get_environment("DICE_DEBUG_DICE_COUNT").is_empty():
		GameState.current_dice_count = clampi(OS.get_environment("DICE_DEBUG_DICE_COUNT").to_int(), 1, 3)
	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.name = "UIAudioPlayer"
	ui_audio_player.bus = &"Master"
	add_child(ui_audio_player)
	match OS.get_environment("DICE_QA_SCREEN"):
		"stage": show_stage_select()
		"character": show_character_select()
		"game": show_game()
		"font": show_font_qa()
		_: show_title()
	if OS.get_environment("DICE_QA_EARLY_STOP") == "1":
		call_deferred("_qa_early_stop")
	elif OS.get_environment("DICE_QA_ONE_DIE") == "1":
		call_deferred("_qa_one_die")
	elif OS.get_environment("DICE_QA_FIVE_DICE") == "1":
		call_deferred("_qa_five_dice")
	elif OS.get_environment("DICE_QA_SAVE_RELOAD") == "1":
		call_deferred("_qa_save_reload")
	elif OS.get_environment("DICE_QA_M3_SMOKE") == "1":
		call_deferred("_qa_m3_smoke")
	elif OS.get_environment("DICE_QA_M3_ROUTES") == "1":
		call_deferred("_qa_m3_routes")
	elif OS.get_environment("DICE_QA_M4A") == "1":
		call_deferred("_qa_m4a")
	elif OS.get_environment("DICE_QA_STOP_ALL") == "1":
		call_deferred("_qa_stop_all")
	elif OS.get_environment("DICE_QA_EXTRA_DICE_CONTROLS") == "1":
		call_deferred("_qa_extra_dice_controls")
	elif OS.get_environment("DICE_QA_CAPTURE_PROGRESSION") != "":
		call_deferred("_qa_progression_capture", OS.get_environment("DICE_QA_CAPTURE_PROGRESSION"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_M4A_HARDENING") == "1":
		call_deferred("_qa_m4a_hardening")
	elif OS.get_environment("DICE_QA_DICE_PROGRESSION") == "1":
		call_deferred("_qa_dice_progression")
	elif OS.get_environment("DICE_QA_AUDIO") == "1":
		call_deferred("_qa_dice_audio")
	elif OS.get_environment("DICE_QA_UI_AUDIO") == "1":
		call_deferred("_qa_ui_audio")
	elif OS.get_environment("DICE_QA_ANDROID_UI") == "1":
		call_deferred("_qa_android_ui")
	elif OS.get_environment("DICE_QA_ROUTE_01") == "1":
		call_deferred("_qa_route_01")
	elif OS.get_environment("DICE_QA_ROUTE_02") == "1":
		call_deferred("_qa_route_02")
	elif OS.get_environment("DICE_QA_ROUTE_03") == "1":
		call_deferred("_qa_route_03")
	elif OS.get_environment("DICE_QA_CARAVAN_SECRET") == "1":
		call_deferred("_qa_caravan_secret")
	elif OS.get_environment("DICE_QA_POPUP_BOOK") == "1":
		call_deferred("_qa_popup_book")
	elif OS.get_environment("DICE_QA_CAPTURE_CARAVAN_SECRET") != "":
		call_deferred("_qa_caravan_secret_capture", OS.get_environment("DICE_QA_CAPTURE_CARAVAN_SECRET"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_POPUP_BOOK") != "":
		call_deferred("_qa_popup_book_capture", OS.get_environment("DICE_QA_CAPTURE_POPUP_BOOK"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_DICE") != "":
		call_deferred("_qa_dice_capture", OS.get_environment("DICE_QA_CAPTURE_DICE"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_M4A") != "":
		call_deferred("_qa_m4a_capture", OS.get_environment("DICE_QA_CAPTURE_M4A"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_RISK") != "":
		call_deferred("_qa_risk_space", OS.get_environment("DICE_QA_RISK"))
	elif OS.get_environment("DICE_QA_CAPTURE_PREMIUM_BOARD") != "":
		call_deferred("_qa_premium_board_capture", OS.get_environment("DICE_QA_CAPTURE_PREMIUM_BOARD"))
	elif OS.get_environment("DICE_QA_LAP_LANDMARK") == "1":
		call_deferred("_qa_lap_landmark")
	elif OS.get_environment("DICE_QA_CLEAN_LAP") == "1":
		call_deferred("_qa_clean_lap")
	elif OS.get_environment("DICE_QA_TOURMAP") == "1":
		call_deferred("_qa_tourmap")
	elif OS.get_environment("DICE_QA_TOURMAP_DIE") == "1":
		call_deferred("_qa_tourmap_die")
	elif OS.get_environment("DICE_QA_TOURMAP_MULTI_DIE") == "1":
		call_deferred("_qa_tourmap_multi_die")
	elif OS.get_environment("DICE_QA_ROLL_TRANSACTION") == "1":
		call_deferred("_qa_roll_transaction")
	elif OS.get_environment("DICE_QA_SPICE_SCENIC") == "1":
		call_deferred("_qa_spice_scenic")
	elif OS.get_environment("DICE_QA_CAPTURE_SPICE_SCENIC") != "":
		call_deferred("_qa_spice_scenic_capture", OS.get_environment("DICE_QA_CAPTURE_SPICE_SCENIC"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_LAP_LANDMARK") != "":
		call_deferred("_qa_lap_landmark_capture", OS.get_environment("DICE_QA_CAPTURE_LAP_LANDMARK"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_CLEAN") != "":
		call_deferred("_qa_clean_capture", OS.get_environment("DICE_QA_CAPTURE_CLEAN"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_TOURMAP") != "":
		call_deferred("_qa_tourmap_capture", OS.get_environment("DICE_QA_CAPTURE_TOURMAP"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_TOURMAP_DIE") != "":
		call_deferred("_qa_tourmap_die_capture", OS.get_environment("DICE_QA_CAPTURE_TOURMAP_DIE"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif not GameState.active_event_state.is_empty():
		call_deferred("_resume_active_event")
	elif GameState.pending_boss_handoff:
		call_deferred("_resume_pending_boss_handoff")
	elif not GameState.roll_transaction.is_empty():
		call_deferred("_resume_roll_transaction")
	elif OS.get_environment("DICE_QA_CAPTURE_M3") != "":
		call_deferred("_qa_m3_capture", OS.get_environment("DICE_QA_CAPTURE_M3"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	if OS.get_environment("DICE_QA_CAPTURE_M3").is_empty() and OS.get_environment("DICE_QA_CAPTURE_M4A").is_empty() and OS.get_environment("DICE_QA_CAPTURE_DICE").is_empty() and OS.get_environment("DICE_QA_CAPTURE_PROGRESSION").is_empty() and OS.get_environment("DICE_QA_CAPTURE_PREMIUM_BOARD").is_empty() and OS.get_environment("DICE_QA_CAPTURE_LAP_LANDMARK").is_empty() and OS.get_environment("DICE_QA_CAPTURE_SPICE_SCENIC").is_empty() and OS.get_environment("DICE_QA_CAPTURE_CLEAN").is_empty() and OS.get_environment("DICE_QA_CAPTURE_TOURMAP").is_empty() and OS.get_environment("DICE_QA_CAPTURE_TOURMAP_DIE").is_empty() and OS.get_environment("DICE_QA_CAPTURE_CARAVAN_SECRET").is_empty() and OS.get_environment("DICE_QA_CAPTURE_POPUP_BOOK").is_empty() and not OS.get_environment("DICE_QA_CAPTURE_PATH").is_empty():
		call_deferred("_qa_capture_viewport", OS.get_environment("DICE_QA_CAPTURE_PATH"))

func _apply_theme() -> void:
	var app_theme := Theme.new()
	app_theme.default_font = APP_FONT
	app_theme.default_font_size = 24
	for control_type: String in ["Label", "Button", "CheckButton", "LineEdit", "ProgressBar"]:
		app_theme.set_font("font", control_type, APP_FONT)
		app_theme.set_constant("outline_size", control_type, 0)
	for rich_font_name: String in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
		app_theme.set_font(rich_font_name, "RichTextLabel", APP_FONT)
	app_theme.set_constant("outline_size", "RichTextLabel", 0)
	app_theme.set_color("font_color", "Label", INK)
	app_theme.set_color("font_color", "Button", INK)
	app_theme.set_color("font_hover_color", "Button", TEAL)
	app_theme.set_font_size("font_size", "Button", 24)
	theme = app_theme

func _clear() -> void:
	if is_instance_valid(dice_audio): dice_audio.stop_all()
	for child: Node in get_children():
		if child == ui_audio_player: continue
		child.queue_free()
	root_stack = null
	dice_audio = null

func _make_page() -> VBoxContainer:
	_clear()
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var artwork := TextureRect.new()
	artwork.texture = CAIRO_BACKGROUND
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.modulate = Color(1.0, 1.0, 1.0, 0.72)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(artwork)
	var veil := ColorRect.new()
	veil.color = Color(0.96, 0.90, 0.78, 0.20)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	root_stack = VBoxContainer.new()
	root_stack.add_theme_constant_override("separation", 16)
	root_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root_stack)
	return root_stack

func _make_world_page() -> VBoxContainer:
	_clear()
	var artwork := TextureRect.new()
	artwork.texture = WORLD_MAP_BACKGROUND
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(artwork)
	var veil := ColorRect.new()
	veil.color = Color(0.95, 0.88, 0.72, 0.08)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	root_stack = VBoxContainer.new()
	root_stack.add_theme_constant_override("separation", 8)
	root_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root_stack)
	return root_stack

func _postcard_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f8e8c5") if active else Color(0.22, 0.20, 0.18, 0.88)
	style.border_color = GOLD if active else Color("#766c61")
	style.set_border_width_all(3 if active else 2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	style.shadow_color = Color(0.10, 0.06, 0.03, 0.35)
	style.shadow_size = 8
	return style

func _add_city_postcard(parent: Control, city: String, journey: String, position: Vector2, card_size: Vector2, active: bool, action: Callable, card_texture: Texture2D = null) -> Button:
	var button := Button.new()
	button.name = "city_%s" % city.to_lower()
	button.text = "" if card_texture != null else "%s\n%s\n%s" % [city, journey, "● 旅に出る" if active else "◇ 準備中"]
	button.position = position
	button.size = card_size
	button.clip_contents = true
	button.add_theme_font_size_override("font_size", 18 if active else 15)
	button.add_theme_color_override("font_color", INK if active else Color("#d7c8b5"))
	button.add_theme_color_override("font_hover_color", TEAL if active else Color("#d7c8b5"))
	button.add_theme_color_override("font_disabled_color", Color("#d7c8b5"))
	button.add_theme_stylebox_override("normal", _postcard_style(active))
	button.add_theme_stylebox_override("hover", _postcard_style(active))
	button.add_theme_stylebox_override("pressed", _postcard_style(active))
	button.add_theme_stylebox_override("disabled", _postcard_style(false))
	button.disabled = not active
	button.tooltip_text = "%sは%s" % [journey, "選択できます" if active else "今後の旅で解禁予定です"]
	if active and action.is_valid():
		button.pressed.connect(func() -> void: _play_ui_click(true))
		button.pressed.connect(action)
	if card_texture != null:
		var art := TextureRect.new()
		art.texture = card_texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.position = Vector2(6, 6)
		art.size = Vector2(card_size.x - 12, card_size.y - 62)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		var caption_bg := ColorRect.new()
		caption_bg.color = Color(0.97, 0.89, 0.72, 0.96)
		caption_bg.position = Vector2(6, card_size.y - 60)
		caption_bg.size = Vector2(card_size.x - 12, 54)
		caption_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption_bg)
		var caption := _body("%s　%s\n● 旅に出る" % [city, journey], 15)
		caption.position = caption_bg.position
		caption.size = caption_bg.size
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
	parent.add_child(button)
	return button

func _title(text: String, size_px: int = 52) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", INK)
	return label

func _body(text: String, size_px: int = 22) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", INK)
	return label

func _button(text: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 68)
	button.pressed.connect(func() -> void: _play_ui_click(primary))
	button.pressed.connect(action)
	if primary:
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		var style := StyleBoxFlat.new()
		style.bg_color = TEAL
		style.corner_radius_top_left = 22
		style.corner_radius_top_right = 22
		style.corner_radius_bottom_left = 22
		style.corner_radius_bottom_right = 22
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = GOLD
		button.add_theme_stylebox_override("normal", style)
	return button

func _play_ui_click(primary: bool = false) -> void:
	if not is_instance_valid(ui_audio_player): return
	var level := clampf(GameState.master_volume * GameState.se_volume, 0.0, 1.0)
	if level <= 0.0: return
	ui_audio_player.stream = UI_CONFIRM_STREAM if primary else UI_CLICK_STREAM
	ui_audio_player.volume_db = -18.0 + linear_to_db(level)
	ui_audio_player.pitch_scale = 1.0
	ui_audio_player.play()

func _premium_panel(bg: Color = Color("#f5e6c6"), border: Color = Color("#9b743d"), radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.16, 0.10, 0.05, 0.22)
	style.shadow_size = 7
	return style

func _pill(text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.24, 0.18, 0.12, 0.86), GOLD, 20))
	var label := _body(text, 20)
	label.add_theme_color_override("font_color", Color("#fff0c7"))
	panel.add_child(label)
	return {"panel": panel, "label": label}

func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer

func show_title() -> void:
	var page := _make_page()
	page.add_child(_spacer(120))
	page.add_child(_title("DICE SLOT TRIP", 58))
	page.add_child(_body("サイコロをそろえて、世界をめぐる。", 25))
	var note := _body("遠い風の向こうで、今日の旅が待っている。", 20)
	note.add_theme_color_override("font_color", MUTED)
	page.add_child(note)
	page.add_child(_spacer(250))
	page.add_child(_button("はじめから", func() -> void:
		GameState.start_new_game()
		show_stage_select(), true))
	var continue_button := _button("つづきから", func() -> void:
		SaveManager.load_now()
		show_game()
		if not GameState.active_event_state.is_empty(): call_deferred("_resume_active_event")
		elif GameState.pending_boss_handoff: call_deferred("_resume_pending_boss_handoff")
		elif not GameState.roll_transaction.is_empty(): call_deferred("_resume_roll_transaction"))
	continue_button.disabled = not SaveManager.has_save()
	page.add_child(continue_button)
	var utility := HBoxContainer.new()
	utility.add_theme_constant_override("separation", 16)
	var book := _button("図鑑", show_encyclopedia)
	var settings := _button("設定", _show_settings_modal)
	book.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility.add_child(book)
	utility.add_child(settings)
	page.add_child(utility)
	page.add_child(_body("オートセーブ対応", 18))

func _show_settings_modal() -> void:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_title("音の設定", 34))
	var master_label := _body("全体音量 %d%%" % roundi(GameState.master_volume * 100.0), 19)
	var master_slider := HSlider.new(); master_slider.min_value = 0; master_slider.max_value = 100; master_slider.step = 1; master_slider.value = GameState.master_volume * 100.0; master_slider.custom_minimum_size.y = 42
	master_slider.value_changed.connect(func(value: float) -> void: GameState.master_volume = value / 100.0; master_label.text = "全体音量 %d%%" % roundi(value); if is_instance_valid(dice_audio): dice_audio.set_levels(GameState.master_volume, GameState.se_volume, GameState.dice_se_muted))
	content.add_child(master_label); content.add_child(master_slider)
	var se_label := _body("SE音量 %d%%" % roundi(GameState.se_volume * 100.0), 19)
	var se_slider := HSlider.new(); se_slider.min_value = 0; se_slider.max_value = 100; se_slider.step = 1; se_slider.value = GameState.se_volume * 100.0; se_slider.custom_minimum_size.y = 42
	se_slider.value_changed.connect(func(value: float) -> void: GameState.se_volume = value / 100.0; se_label.text = "SE音量 %d%%" % roundi(value); if is_instance_valid(dice_audio): dice_audio.set_levels(GameState.master_volume, GameState.se_volume, GameState.dice_se_muted))
	content.add_child(se_label); content.add_child(se_slider)
	var dice_mute := CheckButton.new(); dice_mute.text = "ダイスSEをミュート"; dice_mute.button_pressed = GameState.dice_se_muted; dice_mute.custom_minimum_size.y = 52
	dice_mute.toggled.connect(func(value: bool) -> void: GameState.dice_se_muted = value; if is_instance_valid(dice_audio): dice_audio.set_muted(value))
	content.add_child(dice_mute)
	content.add_child(_body("音量0でも出目・目押し・移動は変わりません。", 16))
	var close := _button("保存して閉じる", func() -> void: return, true); close.toggle_mode = true; content.add_child(close)
	await close.pressed
	SaveManager.save_now(); _close_modal(modal.layer)

func show_stage_select() -> void:
	var page := _make_world_page()
	var heading_panel := PanelContainer.new()
	heading_panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.96, 0.88, 0.70, 0.94), Color("#8d6335"), 18))
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 0)
	heading.add_child(_title("旅先を選ぶ", 40))
	var kicker := _body("WORLD TRAVEL MAP　・　鞄の中の旅程", 16)
	kicker.add_theme_color_override("font_color", MUTED)
	heading.add_child(kicker)
	heading_panel.add_child(heading)
	page.add_child(heading_panel)

	var map_area := Control.new()
	map_area.name = "WorldMapPostcards"
	map_area.custom_minimum_size.y = 780
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_area.clip_contents = true
	page.add_child(map_area)
	_add_city_postcard(map_area, "PARIS", "月夜のパリ", Vector2(86, 155), Vector2(170, 112), false, Callable())
	_add_city_postcard(map_area, "TOKYO", "桜風の東京", Vector2(492, 205), Vector2(165, 112), false, Callable())
	_add_city_postcard(map_area, "ROME", "遺跡のローマ", Vector2(70, 480), Vector2(170, 112), false, Callable())
	_add_city_postcard(map_area, "SINGAPORE", "雨粒のシンガポール", Vector2(455, 515), Vector2(200, 112), false, Callable())
	var cairo := _add_city_postcard(map_area, "CAIRO", "砂時計のカイロ", Vector2(245, 315), Vector2(240, 172), true, show_character_select, CAIRO_CITY_CARD)
	cairo.add_theme_font_size_override("font_size", 21)
	var stamp := _body("CAIRO 01　旅のスタンプ %02d" % GameState.total_laps, 15)
	stamp.position = Vector2(250, 495)
	stamp.size = Vector2(230, 34)
	stamp.add_theme_color_override("font_color", Color("#70451f"))
	map_area.add_child(stamp)

	GameState.ensure_boss_data()
	var route := _body("選択中：砂時計のカイロ　｜　90マス　｜　%s" % str(GameState.current_boss.get("name", "眠そうなスフィンクス")), 17)
	route.add_theme_color_override("font_color", Color("#fce7ba"))
	var route_panel := PanelContainer.new()
	route_panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.19, 0.14, 0.10, 0.88), GOLD, 18))
	route_panel.add_child(route)
	page.add_child(route_panel)
	page.add_child(_button("この旅へ", show_character_select, true))
	var back := _button("もどる", show_title)
	back.add_theme_stylebox_override("normal", _premium_panel(Color(0.94, 0.84, 0.65, 0.92), Color("#8d6335"), 16))
	back.add_theme_stylebox_override("hover", _premium_panel(Color(0.98, 0.90, 0.72, 0.98), GOLD, 16))
	page.add_child(back)

func show_character_select() -> void:
	var page := _make_page()
	page.add_child(_title("旅人を選ぶ", 46))
	page.add_child(_body("能力は小さく、旅の手触りだけを変えます。", 20))
	var characters: Array[Dictionary] = [
		{"id": &"relaxed", "name": "のんびり旅人", "tag": "おすすめ", "text": "一周ごとに旅のお守り。穏やかで安定。"},
		{"id": &"photographer", "name": "フォトグラファー", "tag": "発見上手", "text": "名所と最初の出会いで小さなボーナス。"},
		{"id": &"gambler", "name": "勝負師", "tag": "役好き", "text": "PAIRをきっかけにTRIPLEを夢見る旅人。"}
	]
	for character: Dictionary in characters:
		var button := _button("%s　%s\n%s" % [character.name, character.tag, character.text], func() -> void:
			GameState.selected_character_id = character.id
			show_game())
		button.custom_minimum_size.y = 115
		page.add_child(button)
	page.add_child(_button("もどる", show_stage_select))

func show_font_qa() -> void:
	var page := _make_page()
	page.add_child(_title("実機フォントQA", 40))
	page.add_child(_body("Noto Sans JP / MSDF OFF / outline 0", 16))
	for sample: String in [
		"砂時計のカイロ",
		"眠そうなスフィンクスがいる",
		"サイコロをそろえて、世界をめぐる。",
		"旅人を選ぶ",
		"香辛料市場通り",
		"PAIR／STRAIGHT／TRIPLE",
		"1234567890！？・◇●",
	]:
		var sample_label := _body(sample, 24)
		sample_label.custom_minimum_size.y = 56
		sample_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		page.add_child(sample_label)
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.custom_minimum_size.y = 72
	rich.text = "[center][b]日本語・English・123・◇●[/b][/center]"
	page.add_child(rich)
	page.add_child(_button("文字と記号を確認　！？・◇●", func() -> void: return, true))

func show_game() -> void:
	var page := _make_page()
	var inside_royal_maze := GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE
	dice_audio = DiceAudioControllerScript.new()
	dice_audio.name = "DiceAudioController"
	add_child(dice_audio)
	dice_audio.set_levels(GameState.master_volume, GameState.se_volume, GameState.dice_se_muted)
	page.add_theme_constant_override("separation", 6)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	var lap_pill := _pill(""); lap_label = lap_pill.label; (lap_pill.panel as PanelContainer).size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(lap_pill.panel)
	var stage_title := _title("王の迷い環" if inside_royal_maze else "砂時計のカイロ", 26); stage_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(stage_title)
	var coin_pill := _pill(""); coin_label = coin_pill.label; (coin_pill.panel as PanelContainer).size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(coin_pill.panel)
	page.add_child(top_row)

	var overview := HBoxContainer.new(); overview.add_theme_constant_override("separation", 8)
	var boss_card := PanelContainer.new(); boss_card.add_theme_stylebox_override("panel", _premium_panel(Color(0.96, 0.87, 0.70, 0.94), Color("#a47a3c"), 18)); boss_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; boss_card.size_flags_stretch_ratio = 1.75
	var boss_row := HBoxContainer.new(); boss_row.add_theme_constant_override("separation", 8)
	var portrait := TextureRect.new()
	portrait.texture = SPHINX_TEXTURE
	portrait.custom_minimum_size = Vector2(88, 88)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_row.add_child(portrait)
	var boss_info := VBoxContainer.new(); boss_info.add_theme_constant_override("separation", 2); boss_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var boss_kicker := _body("現在のボス", 14); boss_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; boss_kicker.add_theme_color_override("font_color", MUTED); boss_info.add_child(boss_kicker)
	boss_label = _body("", 20); boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; boss_info.add_child(boss_label)
	boss_gauge = ProgressBar.new(); boss_gauge.min_value = 0; boss_gauge.max_value = 100; boss_gauge.show_percentage = false; boss_gauge.custom_minimum_size.y = 17
	var gauge_bg := StyleBoxFlat.new(); gauge_bg.bg_color = Color("#d3c2a0"); gauge_bg.set_corner_radius_all(8)
	var gauge_fill := StyleBoxFlat.new(); gauge_fill.bg_color = Color("#2e8c8c"); gauge_fill.set_corner_radius_all(8); gauge_fill.border_color = Color("#e1b956"); gauge_fill.set_border_width_all(1)
	boss_gauge.add_theme_stylebox_override("background", gauge_bg); boss_gauge.add_theme_stylebox_override("fill", gauge_fill); boss_info.add_child(boss_gauge)
	boss_presence_label = _body("", 14); boss_presence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; boss_presence_label.add_theme_color_override("font_color", MUTED); boss_info.add_child(boss_presence_label)
	stamp_label = _body("", 12); stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; stamp_label.add_theme_color_override("font_color", MUTED); boss_info.add_child(stamp_label)
	boss_row.add_child(boss_info); boss_card.add_child(boss_row); overview.add_child(boss_card)

	var map_card := PanelContainer.new(); map_card.add_theme_stylebox_override("panel", _premium_panel(Color(0.96, 0.89, 0.75, 0.94), Color("#a47a3c"), 18)); map_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var map_box := VBoxContainer.new(); map_box.add_theme_constant_override("separation", 2)
	landmark_level_label = _body("", 14); landmark_level_label.add_theme_color_override("font_color", MUTED); map_box.add_child(landmark_level_label)
	minimap_view = BoardViewScript.new(); minimap_view.is_minimap = true; minimap_view.custom_minimum_size = Vector2(180, 82); minimap_view.size_flags_vertical = Control.SIZE_EXPAND_FILL; minimap_view.configure(tile_types, GameState.current_tile_index, GameState.landmark_levels); map_box.add_child(minimap_view)
	map_card.add_child(map_box); overview.add_child(map_card); page.add_child(overview)

	board_view_mode = _preferred_board_view_mode()
	board_view = _new_board_view(board_view_mode)
	board_view.custom_minimum_size = Vector2(0, 390)
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.configure(tile_types, GameState.current_tile_index, GameState.landmark_levels)
	_sync_board_route_context()
	if board_view is TourismMapView:
		(board_view as TourismMapView).set_dice_count(GameState.current_dice_count)
		(board_view as TourismMapView).set_flow_visual_level(GameState.flow_level)
	page.add_child(board_view)
	var memo_panel := PanelContainer.new(); memo_panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.97, 0.91, 0.79, 0.92), Color("#b28a52"), 14))
	memo_label = _body("風が砂の上に細い道を描いている。", 16); memo_label.custom_minimum_size.y = 30; memo_panel.add_child(memo_label); page.add_child(memo_panel)

	var tray_panel := PanelContainer.new(); tray_panel.add_theme_stylebox_override("panel", _premium_panel(Color("#272321") if inside_royal_maze else Color("#765737"), Color("#b98b3f") if inside_royal_maze else Color("#d1a552"), 22))
	var tray_box := VBoxContainer.new(); tray_box.add_theme_constant_override("separation", 3); tray_panel.add_child(tray_box)
	var tray_header := HBoxContainer.new()
	var tray_title := _body("王墓のダイス" if inside_royal_maze else "今回のダイス", 15); tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; tray_title.add_theme_color_override("font_color", Color("#f6dfad")); tray_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tray_header.add_child(tray_title)
	mode_label = _body("", 15); mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; mode_label.autowrap_mode = TextServer.AUTOWRAP_OFF; mode_label.custom_minimum_size.x = 210; mode_label.add_theme_color_override("font_color", Color("#f1c86a")); tray_header.add_child(mode_label); tray_box.add_child(tray_header)
	dice_presentation = DicePresentation3DScript.new()
	dice_presentation.name = "DicePresentation3D"
	tray_box.add_child(dice_presentation); dice_presentation.custom_minimum_size.y = 190
	dice_row = HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 8)
	tray_box.add_child(dice_row)
	role_label = _title("READY", 20); role_label.add_theme_color_override("font_color", Color("#78d4d1")); tray_box.add_child(role_label)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 5)
	mode_buttons.clear()
	for mode: int in [1, 2, 3]:
		var indicator := _body("", 13); indicator.custom_minimum_size.y = 42; indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL; indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; indicator.name = "base_dice_mode_%d" % mode
		mode_buttons.append(indicator); mode_row.add_child(indicator)
	tray_box.add_child(mode_row)
	var roll_controls := HBoxContainer.new(); roll_controls.add_theme_constant_override("separation", 10)
	roll_button = _button("サイコロを振る", _on_roll_pressed, true); roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; roll_button.custom_minimum_size.y = 62
	stop_all_button = _button("残りを一括停止", _stop_all_dice); stop_all_button.custom_minimum_size = Vector2(190, 62); stop_all_button.visible = false
	roll_controls.add_child(roll_button); roll_controls.add_child(stop_all_button); tray_box.add_child(roll_controls)
	confirm_five_button = _button("選んだ3個で進む", _confirm_five)
	confirm_five_button.visible = false
	tray_box.add_child(confirm_five_button)
	page.add_child(tray_panel)
	var status_row := HBoxContainer.new()
	rolls_label = _body("", 14); rolls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rolls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var debug_toggle := _button("DEBUG", _toggle_debug)
	debug_toggle.custom_minimum_size = Vector2(104, 38)
	status_row.add_child(rolls_label)
	status_row.add_child(debug_toggle)
	page.add_child(status_row)
	debug_box = _build_debug_box()
	debug_box.visible = false
	page.add_child(debug_box)
	map_dice_overlay = MapDiceOverlayScript.new()
	map_dice_overlay.name = "MapDiceOverlay"
	map_dice_overlay.early_stop_requested.connect(func() -> void: _lock_next_die(false))
	add_child(map_dice_overlay)
	_set_mode(clampi(GameState.current_dice_count, 1, 3))
	_refresh_dice_mode_buttons()
	_refresh_hud()
	var initial_values: Array[int] = []
	for index: int in range(clampi(GameState.current_dice_count, 1, 3)):
		initial_values.append(index + 1)
	_render_dice(initial_values, false)

func _set_mode(mode: int) -> void:
	if moving or modal_open:
		return
	if mode != 5 and mode != clampi(GameState.current_dice_count, 1, 3):
		return
	# Mode 5 remains an internal/special-event mode.  It is still supported by
	# existing QA and M4A extra-roll flows, but is not offered as base UI.
	dice_mode = mode
	mode_label.text = "通常旅行" if mode == 1 else ("DICE FESTIVAL" if mode == 5 else ("DICE SLOT" if mode == 3 else "DOUBLE CHANCE"))
	confirm_five_button.visible = false
	roll_button.visible = true
	_refresh_dice_mode_buttons()

func _refresh_dice_mode_buttons() -> void:
	for indicator: Label in mode_buttons:
		var mode := int(str(indicator.name).get_slice("_", 3))
		var is_current := mode == clampi(GameState.current_dice_count, 1, 3)
		indicator.text = ["", "NORMAL", "DOUBLE CHANCE", "DICE SLOT"][mode]
		indicator.add_theme_color_override("font_color", Color("#fff1cb") if is_current else Color("#8f806c"))
		indicator.add_theme_stylebox_override("normal", _premium_panel(Color(0.12, 0.42, 0.43, 0.96) if is_current else Color(0.18, 0.14, 0.11, 0.62), GOLD if is_current else Color("#5d5143"), 11))

func _on_roll_pressed() -> void:
	if rolling_dice:
		_lock_next_die(false)
		return
	if moving or modal_open:
		return
	if GameState.rolls_used >= 36:
		_show_message("今日の旅", "36回のロールを終えました。続きは次の旅へ保存されています。")
		return
	fixed_targets = GameState.fixed_rolls.duplicate()
	GameState.fixed_rolls.clear()
	last_roll_early_stopped = false
	GameState.begin_roll_transaction([], dice_mode, GameState.current_tile_index)
	SaveManager.save_now()
	dice_values = await _animate_dice_roll(dice_mode)
	if dice_values.is_empty():
		return
	if dice_mode == 5:
		selected_indices = DiceLogicScript.recommended_indices(dice_values)
		_render_dice(dice_values, true)
		role_label.text = "おすすめの3個を選択中"
		roll_button.visible = false
		confirm_five_button.visible = true
		return
	_render_dice(dice_values, false)
	await _resolve_roll(dice_values)

func _animate_dice_roll(count: int, extra_controls_parent: VBoxContainer = null) -> Array[int]:
	moving = true
	rolling_dice = true
	locked_dice_count = 0
	if is_instance_valid(dice_audio): dice_audio.begin_roll(count)
	rolling_values.clear()
	for index: int in range(count):
		rolling_values.append(rng.randi_range(1, 6))
	if not GameState.roll_transaction.is_empty() and str(GameState.roll_transaction.get("phase", "")) == "PRE_ROLL":
		GameState.mark_roll_started(rolling_values)
		SaveManager.save_now()
	var map_overlay_roll := _uses_map_dice_overlay(count)
	if map_overlay_roll:
		_sync_flow_visuals()
		map_dice_overlay.set_flow_visual_level(GameState.flow_level)
		var tray_rect := _map_dice_tray_anchor_rect()
		dice_presentation.visible = false
		var map_rect := board_view.get_global_rect()
		await map_dice_overlay.begin_launch(rolling_values, tray_rect, map_rect, TourismMapViewScript.map_dice_landing_rect(map_rect.size, count))
		if not map_dice_overlay.is_active():
			_abort_map_dice_roll()
			return []
	roll_button.text = "タップで左から止める"
	stop_all_button.visible = extra_controls_parent == null
	if map_overlay_roll and is_instance_valid(stop_all_button):
		map_dice_overlay.set_input_exempt_rect(stop_all_button.get_global_rect())
	if extra_controls_parent != null:
		var controls := HBoxContainer.new(); controls.name = "extra_dice_stop_controls"; controls.add_theme_constant_override("separation", 10)
		active_extra_left_stop = _button("左から1個停止", func() -> void: _lock_next_die(false), true)
		active_extra_all_stop = _button("残りを一括停止", _stop_all_dice)
		active_extra_left_stop.name = "extra_left_stop"; active_extra_all_stop.name = "extra_all_stop"
		active_extra_left_stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL; active_extra_all_stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.add_child(active_extra_left_stop); controls.add_child(active_extra_all_stop); extra_controls_parent.add_child(controls)
		if map_overlay_roll and is_instance_valid(active_extra_all_stop):
			map_dice_overlay.set_input_exempt_rect(active_extra_all_stop.get_global_rect())
	role_label.text = "目を追えば、少しだけ狙えるかも"
	# 0.8-1.3 seconds for an untouched roll across 1/2/3/5 dice. The final
	# presentation settle continues independently for another 0.18 seconds.
	for frame: int in range(26):
		if map_overlay_roll and not map_dice_overlay.is_active():
			_abort_map_dice_roll()
			return []
		roll_visual_frame = frame
		if is_instance_valid(dice_audio):
			dice_audio.play_roll(1.0 - float(frame) / 25.0)
			if frame in [4, 8, 12, 16]: dice_audio.play_contact(0.38 + float(frame) * 0.018)
		for index: int in range(locked_dice_count, count):
			rolling_values[index] = rng.randi_range(1, 6)
		_render_dice(rolling_values, false)
		if frame >= 14 and (frame - 14) % 2 == 0:
			_lock_next_die(true)
		if locked_dice_count >= count:
			break
		var delay := 0.043 + float(frame) * 0.0009
		await get_tree().create_timer(delay).timeout
	while locked_dice_count < count:
		_lock_next_die(true)
		await get_tree().create_timer(0.13).timeout
	rolling_dice = false
	_render_dice(rolling_values, false)
	if is_instance_valid(dice_audio): dice_audio.end_roll()
	if map_overlay_roll:
		if count == 3:
			var slot_roles: Dictionary = DiceLogicScript.evaluate_current(rolling_values, count)
			var slot_labels: Array = slot_roles.get("labels", [])
			map_dice_overlay.show_slot_result(" + ".join(slot_labels) if not slot_labels.is_empty() else "DICE SLOT", rolling_values, slot_labels)
			_play_flow_pulse(&"role_resolved")
		# 2/3 dice preview the summed destination. Five dice are a selection
		# screen, so no destination highlight appears before the player confirms
		# the recommended three.
		if count != 5:
			var preview_distance := maxi(0, _sum_dice_values(rolling_values) + GameState.next_move_bonus)
			var destination := posmod(GameState.current_tile_index + preview_distance, BoardModelScript.TILE_COUNT)
			(board_view as TourismMapView).highlight_destination(destination, preview_distance)
		await map_dice_overlay.hold_and_return(rolling_values)
		if count != 5:
			(board_view as TourismMapView).clear_destination_highlight()
		dice_presentation.visible = true
		_render_dice(rolling_values, false)
	moving = false
	roll_button.text = "サイコロを振る"
	stop_all_button.visible = false
	if is_instance_valid(active_extra_left_stop): active_extra_left_stop.disabled = true
	if is_instance_valid(active_extra_all_stop): active_extra_all_stop.disabled = true
	active_extra_left_stop = null; active_extra_all_stop = null
	if is_instance_valid(map_dice_overlay):
		map_dice_overlay.set_input_exempt_rect(Rect2())
	return rolling_values.duplicate()

func _uses_map_dice_overlay(count: int) -> bool:
	return is_instance_valid(map_dice_overlay) and MapDiceOverlayScript.uses_map_presentation(board_view is TourismMapView, count)

func _sync_flow_visuals() -> void:
	if is_instance_valid(board_view):
		board_view.set_route_flow_level(GameState.flow_level)
		if board_view is TourismMapView:
			(board_view as TourismMapView).set_flow_visual_level(GameState.flow_level)
	if is_instance_valid(map_dice_overlay):
		map_dice_overlay.set_flow_visual_level(GameState.flow_level)

func _play_flow_pulse(event_type: StringName) -> void:
	if is_instance_valid(board_view) and board_view is TourismMapView:
		(board_view as TourismMapView).play_flow_pulse(event_type)

func _map_dice_tray_anchor_rect() -> Rect2:
	var source := dice_presentation.get_global_rect()
	var center_x := roll_button.get_global_rect().get_center().x
	var center_y := source.get_center().y
	if source.size.y <= 1.0:
		center_y = roll_button.get_global_rect().position.y - 72.0
	return Rect2(Vector2(center_x, center_y) - MapDiceOverlayScript.PRESENTATION_SIZE * 0.5, MapDiceOverlayScript.PRESENTATION_SIZE)

func _abort_map_dice_roll() -> void:
	# The gameplay roll has not committed yet. Put any deterministic/debug
	# targets back so interruption cannot silently consume them.
	if not fixed_targets.is_empty():
		GameState.fixed_rolls = fixed_targets.duplicate()
		fixed_targets.clear()
	GameState.rollback_uncommitted_roll()
	SaveManager.save_now()
	rolling_dice = false
	moving = false
	locked_dice_count = 0
	rolling_values.clear()
	if is_instance_valid(dice_audio):
		dice_audio.stop_all_roll_sounds()
	if is_instance_valid(map_dice_overlay):
		map_dice_overlay.cancel_to_tray()
	if is_instance_valid(dice_presentation):
		dice_presentation.visible = true
	roll_button.text = "サイコロを振る"
	stop_all_button.visible = false

func _lock_next_die(automatic: bool) -> void:
	if not rolling_dice or locked_dice_count >= rolling_values.size():
		return
	var index := locked_dice_count
	if index < fixed_targets.size():
		rolling_values[index] = clampi(fixed_targets[index], 1, 6)
	locked_dice_count += 1
	_render_dice(rolling_values, false)
	if is_instance_valid(dice_audio): dice_audio.play_land(index, 0.76 if not automatic else 0.62)
	_play_flow_pulse(&"die_stopped")
	if not automatic:
		last_roll_early_stopped = true
		role_label.text = "%d個目を早止め" % locked_dice_count

func _stop_all_dice() -> void:
	if not rolling_dice or locked_dice_count >= rolling_values.size(): return
	var remaining := rolling_values.size() - locked_dice_count
	while locked_dice_count < rolling_values.size(): _lock_next_die(false)
	role_label.text = "残り%d個を現在の目で一括停止" % remaining

func _render_dice(values: Array[int], selectable: bool) -> void:
	if is_instance_valid(map_dice_overlay) and map_dice_overlay.is_active() and board_view is TourismMapView and MapDiceOverlayScript.uses_map_presentation(true, values.size()):
		map_dice_overlay.present(values, rolling_dice, locked_dice_count)
	elif is_instance_valid(dice_presentation):
		dice_presentation.present(values, rolling_dice, locked_dice_count)
	dice_row.visible = selectable or not is_instance_valid(dice_presentation)
	for child: Node in dice_row.get_children():
		child.queue_free()
	for index: int in range(values.size()):
		var die := Button.new()
		die.text = ""
		die.custom_minimum_size = Vector2(96, 88)
		die.tooltip_text = "出目 %d" % int(values[index])
		die.add_theme_color_override("font_color", INK)
		die.add_theme_color_override("font_disabled_color", INK)
		var die_style := StyleBoxFlat.new(); die_style.bg_color = Color("fffaf0"); die_style.border_color = GOLD; die_style.set_border_width_all(3); die_style.set_corner_radius_all(18); die_style.shadow_color = Color(0.18, 0.12, 0.07, 0.38); die_style.shadow_size = 9
		var is_spinning := rolling_dice and index >= locked_dice_count
		if is_spinning:
			die_style.bg_color = Color("f4e1b9") if (roll_visual_frame + index) % 2 == 0 else Color("fff7df")
			die.rotation = deg_to_rad(float(((roll_visual_frame * 5 + index * 13) % 17) - 8))
			var pulse := 0.96 + 0.06 * absf(sin(float(roll_visual_frame + index) * 0.9)); die.scale = Vector2(pulse, pulse)
		else:
			die.rotation = 0.0; die.scale = Vector2.ONE; die_style.shadow_size = 6
		die.pivot_offset = die.custom_minimum_size * 0.5; die.add_theme_stylebox_override("normal", die_style); die.add_theme_stylebox_override("disabled", die_style)
		die.toggle_mode = selectable
		die.button_pressed = index in selected_indices
		die.disabled = not selectable
		var face := DiceFaceControl.new(values[index])
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		die.add_child(face)
		if selectable:
			die.toggled.connect(func(on: bool) -> void: _toggle_die(index, on))
		dice_row.add_child(die)

func _toggle_die(index: int, on: bool) -> void:
	if on and index not in selected_indices:
		if selected_indices.size() >= 3:
			_render_dice(dice_values, true)
			return
		selected_indices.append(index)
	elif not on:
		selected_indices.erase(index)
	confirm_five_button.disabled = selected_indices.size() != 3

func _die_face(value: int) -> String:
	# Unicode die faces keep the displayed result tactile and readable without
	# exposing a slot-machine-style number label. The numeric value remains in
	# dice_values for role evaluation and deterministic QA.
	return ["", "⚀", "⚁", "⚂", "⚃", "⚄", "⚅"][clampi(value, 1, 6)]

func _confirm_five() -> void:
	if modal_open or selected_indices.size() != 3:
		return
	var chosen: Array[int] = []
	selected_indices.sort()
	for index: int in selected_indices:
		chosen.append(dice_values[index])
	confirm_five_button.visible = false
	roll_button.visible = true
	_render_dice(chosen, false)
	await _resolve_roll(chosen)

func _resolve_roll(values: Array[int]) -> void:
	moving = true
	roll_button.disabled = true
	# A committed transaction can be resumed without re-applying roles, dice
	# transitions, lap bonuses, or next-move bonuses.
	if not GameState.roll_transaction.is_empty():
		var existing_phase := str(GameState.roll_transaction.get("phase", GameState.roll_transaction.get("roll_phase", "")))
		if existing_phase in ["RESULT_COMMITTED", "MOVEMENT_COMMITTED", "SPACE_EFFECT_COMMITTED"]:
			dice_values = _transaction_values(GameState.roll_transaction)
			dice_mode = clampi(int(GameState.roll_transaction.get("dice_count", dice_mode)), 1, 5)
			last_roll_early_stopped = bool(GameState.roll_transaction.get("early_stopped", false))
			await _continue_roll_transaction()
			return
		elif existing_phase not in ["PRE_ROLL", "ROLLING"]:
			GameState.clear_roll_transaction()
	var rolled_dice_count := dice_mode
	var start_route := GameState.current_route_id
	var start_tile := GameState.current_tile_index
	var roles: Dictionary = DiceLogicScript.evaluate_current(values, rolled_dice_count)
	GameState.current_lap_roll_count += 1
	GameState.current_lap_bonus += LapSystemScript.role_bonus_for(roles, rolled_dice_count)
	var labels: Array = roles.get("labels", [])
	if not labels.is_empty():
		role_label.text = " + ".join(labels)
	elif rolled_dice_count < 3:
		role_label.text = "静かな一投　（3ダイスでスロット解禁）"
	else:
		role_label.text = "静かな一投"
	if roles.get("support", &"") == DiceLogicScript.ALL_EVEN:
		GameState.coins += 3
		GameState.even_guard_active = true
	if roles.get("main", &"") == DiceLogicScript.TRIPLE:
		GameState.boss_presence = 5
	# Consume the rolled state before landing rewards. An item/event DICE_ADD_1
	# therefore builds on the post-roll base (for example 2 miss -> 1 -> +1 = 2).
	GameState.apply_dice_roll_transition(rolled_dice_count, roles)
	var distance: int = 0
	for value: int in values:
		distance += value
	if GameState.next_move_bonus != 0:
		distance = maxi(0, distance + GameState.next_move_bonus)
		GameState.next_move_bonus = 0
	if start_route == BoardModelScript.ROUTE_BYPASS_CARAVAN:
		GameState.bypass_rolls_this_visit += 1
	var route_choice := BoardModelScript.route_choice_encounter(start_route, start_tile, distance)
	if not route_choice.is_empty():
		if GameState.roll_transaction.is_empty():
			GameState.begin_roll_transaction(values, rolled_dice_count, start_tile)
		GameState.reserve_route_choice(values, rolled_dice_count, roles, distance, route_choice, last_roll_early_stopped)
		SaveManager.save_now()
		await _continue_roll_transaction()
		return
	var route_move: Dictionary = BoardModelScript.advance_route(start_route, start_tile, distance)
	var crossed_laps := int(route_move.laps)
	var destination := int(route_move.tile_index)
	var destination_route := str(route_move.route_id)
	if GameState.roll_transaction.is_empty():
		GameState.begin_roll_transaction(values, rolled_dice_count, start_tile)
	GameState.commit_roll_result(values, rolled_dice_count, roles, distance, destination, crossed_laps, last_roll_early_stopped, destination_route, route_move.path, int(route_move.maze_loops))
	SaveManager.save_now()
	await _continue_roll_transaction()

func _animate_route_step_hop() -> void:
	if not is_instance_valid(board_view):
		await get_tree().create_timer(0.035).timeout
		return
	# Four short poses read as a deliberate hop while keeping long 3/5-die
	# moves brisk. Gameplay position remains committed one tile at a time.
	for progress: float in [0.18, 0.46, 0.74, 1.0]:
		board_view.set_movement_hop_progress(progress)
		await get_tree().create_timer(0.018).timeout
	board_view.set_movement_hop_progress(0.0)

func _animate_bypass_tile_reveal(tile_index: int) -> void:
	if not is_instance_valid(board_view) or tile_index < 0:
		return
	for progress: float in [0.0, 0.16, 0.34, 0.55, 0.76, 1.0]:
		board_view.set_bypass_reveal_progress(tile_index, progress)
		await get_tree().create_timer(0.075).timeout
	board_view.set_bypass_reveal_progress(-1, 1.0)

func _transaction_values(transaction: Dictionary) -> Array[int]:
	var values: Array[int] = []
	var source_values: Array = transaction.get("final_dice_values", transaction.get("values", []))
	if source_values.is_empty():
		source_values = transaction.get("values", [])
	for value: Variant in source_values:
		values.append(clampi(int(value), 1, 6))
	return values

func _continue_roll_transaction() -> void:
	var transaction: Dictionary = GameState.roll_transaction
	var phase := str(transaction.get("phase", transaction.get("roll_phase", "")))
	if phase == "ROUTE_CHOICE_PENDING":
		await _continue_route_choice_transaction()
		return
	if phase == "PRE_ROLL" or phase == "ROLLING":
		# No gameplay result was durable yet, so the interrupted roll is a safe
		# no-op. This also restores the pre-03B behavior for old saves.
		GameState.rollback_uncommitted_roll()
		SaveManager.save_now()
		moving = false
		roll_button.disabled = false
		return
	var values := _transaction_values(transaction)
	var roles: Dictionary = (transaction.get("role_result", transaction.get("roles", {})) as Dictionary).duplicate(true)
	var destination_route := BoardModelScript.normalized_route_id(str(transaction.get("target_route_id", GameState.current_route_id)))
	var destination := int(BoardModelScript.normalize_position(destination_route, int(transaction.get("target_tile_index", transaction.get("destination", GameState.current_tile_index)))).tile_index)
	var crossed_laps := maxi(0, int(transaction.get("crossed_laps", 0)))
	var crossed_maze_loops := maxi(0, int(transaction.get("crossed_maze_loops", 0)))
	dice_values = values.duplicate()
	last_roll_early_stopped = bool(transaction.get("early_stopped", false))
	var labels: Array = roles.get("labels", [])
	if not labels.is_empty():
		role_label.text = " + ".join(labels)
	var maze_exited_now := false
	if phase == "RESULT_COMMITTED":
		var start_route := BoardModelScript.normalized_route_id(str(transaction.get("start_route_id", GameState.current_route_id)))
		var start_tile := int(BoardModelScript.normalize_position(start_route, int(transaction.get("start_tile", GameState.current_tile_index))).tile_index)
		GameState.set_route_position(start_route, start_tile)
		board_view.set_current_tile(start_tile)
		minimap_view.set_current_tile(start_tile)
		var distance := maxi(0, int(transaction.get("distance", 0)))
		var movement_path: Array = transaction.get("movement_path", [])
		if movement_path.is_empty() and distance > 0:
			movement_path = BoardModelScript.advance_route(start_route, start_tile, distance).path
		for point: Variant in movement_path:
			if not point is Dictionary:
				continue
			GameState.set_route_position(str((point as Dictionary).get("route_id", start_route)), int((point as Dictionary).get("tile_index", start_tile)))
			_sync_board_route_context()
			await _animate_route_step_hop()
		GameState.set_route_position(destination_route, destination)
		_sync_board_route_context()
		GameState.maze_loop_count += crossed_maze_loops
		if not bool(transaction.get("roll_count_committed", false)):
			GameState.rolls_used += 1
			GameState.roll_transaction["roll_count_committed"] = true
		GameState.commit_roll_movement(destination, destination_route)
		var movement_start_route := str(transaction.get("start_route_id", BoardModelScript.ROUTE_MAIN))
		if movement_start_route == BoardModelScript.ROUTE_BYPASS_CARAVAN and destination_route == BoardModelScript.ROUTE_MAIN:
			_finalize_bypass_exit()
		if movement_start_route == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and destination_route == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and destination == int(BoardModelScript.route_definition(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE).return_gate_tile) and int(transaction.get("distance", 0)) > 0:
			maze_exited_now = _commit_royal_maze_exit()
		SaveManager.save_now()
	# Persist a bypass stop before presentation and before its space effect.
	# Resuming MOVEMENT_COMMITTED then observes the reveal and applies only the
	# still-pending landing effect.
	if str(GameState.roll_transaction.get("phase", "")) == "MOVEMENT_COMMITTED" and GameState.current_route_id == BoardModelScript.ROUTE_BYPASS_CARAVAN:
		var reveal_result := GameState.commit_bypass_tile_reveal(GameState.current_tile_index)
		if bool(reveal_result.get("committed", false)):
			SaveManager.save_now()
			_sync_board_route_context()
			if bool(reveal_result.get("newly_revealed", false)):
				await _animate_bypass_tile_reveal(int(reveal_result.get("tile_index", -1)))
	if maze_exited_now:
		await _show_maze_exit_modal()
	# Most destinations start in the fresh event loop. Tile 0 is also a
	# LANDMARK, so its STOP reward is resolved first and folded into that lap.
	if crossed_laps > 0 and GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index != 0:
		await _commit_lap_crossings(crossed_laps, "NORMAL")
	if phase != "SPACE_EFFECT_COMMITTED":
		# ROUTE-01 exposes topology and persistence only. Non-main effects are
		# activated by ROUTE-02/03, so debug traversal lands as NORMAL for now.
		var landing_type: StringName = tile_types[GameState.current_tile_index] if GameState.current_route_id == BoardModelScript.ROUTE_MAIN else BoardModelScript.tile_type_for_position(GameState.current_route_id, GameState.current_tile_index)
		if bool(transaction.get("route_choice_exact_stop", false)):
			landing_type = &"NORMAL"
		await _resolve_landing(landing_type, roles)
		_sync_flow_visuals()
		GameState.commit_roll_space_effect()
		SaveManager.save_now()
	if crossed_laps > 0 and GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == 0:
		await _commit_lap_crossings(crossed_laps, "NORMAL")
	dice_mode = clampi(GameState.current_dice_count, 1, 3)
	GameState.mark_roll_turn_resolved()
	SaveManager.save_now()
	GameState.clear_roll_transaction()
	SaveManager.save_now()
	_refresh_hud()
	moving = false
	roll_button.disabled = false

func _continue_route_choice_transaction() -> void:
	var transaction := GameState.roll_transaction
	if str(transaction.get("phase", "")) != "ROUTE_CHOICE_PENDING":
		return
	if not bool(transaction.get("route_choice_arrival_committed", false)):
		var start_route := str(transaction.get("start_route_id", BoardModelScript.ROUTE_MAIN))
		var start_tile := int(transaction.get("start_tile_index", GameState.current_tile_index))
		GameState.set_route_position(start_route, start_tile)
		for point: Variant in transaction.get("movement_path", []):
			if point is Dictionary:
				GameState.set_route_position(str((point as Dictionary).get("route_id", BoardModelScript.ROUTE_MAIN)), int((point as Dictionary).get("tile_index", start_tile)))
				_sync_board_route_context()
				await _animate_route_step_hop()
		GameState.commit_route_choice_arrival()
		SaveManager.save_now()
	_refresh_hud()
	await _show_route_choice_modal()
	await _continue_roll_transaction()

func _show_route_choice_modal() -> void:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_body("ROUTE CHOICE", 15))
	content.add_child(_title("この先に二つの道があります", 30))
	content.add_child(_body("本線\n残り26マス\n名所・アイテムあり", 20))
	var main_button := _button("本線を進む", func() -> void: return, true); main_button.name = "route_choice_main"; main_button.toggle_mode = true
	content.add_child(main_button)
	content.add_child(_body("砂嵐のキャラバン道\n残り10マス\n危険マス 7", 20))
	var bypass_button := _button("近道へ入る", func() -> void: return); bypass_button.name = "route_choice_bypass"; bypass_button.toggle_mode = true
	content.add_child(bypass_button)
	var chosen := await _wait_for_action([main_button, bypass_button])
	main_button.disabled = true; bypass_button.disabled = true
	var selected_route := BoardModelScript.ROUTE_MAIN if chosen == 0 else BoardModelScript.ROUTE_BYPASS_CARAVAN
	GameState.commit_route_choice(selected_route)
	SaveManager.save_now()
	_sync_board_route_context()
	_close_modal(modal.layer)

func _finalize_bypass_exit() -> void:
	if GameState.bypass_exit_committed:
		return
	GameState.bypass_exit_committed = true
	if not GameState.bypass_damaged_this_visit:
		GameState.bypass_no_damage_count += 1
		role_label.text = "NO DAMAGE SHORTCUT"
	var rolls := maxi(1, GameState.bypass_rolls_this_visit)
	if GameState.bypass_best_roll_count <= 0 or rolls < GameState.bypass_best_roll_count:
		GameState.bypass_best_roll_count = rolls

func _commit_royal_maze_exit() -> bool:
	if not GameState.commit_royal_maze_exit():
		return false
	GameState.roll_transaction["loop_exit_committed"] = true
	GameState.roll_transaction["target_route_id"] = GameState.current_route_id
	GameState.roll_transaction["target_tile_index"] = GameState.current_tile_index
	GameState.roll_transaction["destination"] = GameState.current_tile_index
	GameState.commit_roll_landing_core(&"LOOP_EXIT", "王の迷い環を脱出した")
	GameState.travel_memos.append("王の迷い環を脱出した")
	_sync_board_route_context()
	minimap_view.set_current_tile(GameState.current_tile_index)
	return true

func _show_maze_exit_modal() -> void:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_body("RETURN GATE", 15))
	content.add_child(_title("王の迷い環を脱出した", 31))
	content.add_child(_body("石扉が開き、砂埃が外の回廊へ流れていく。\n帰還地点のマス効果は発生しない。", 19))
	var close := _button("光の外へ", func() -> void: return, true); close.name = "maze_exit_close"; close.toggle_mode = true; content.add_child(close)
	modal["close"] = close
	await _wait_brief_result(modal, 0.75)

func _enter_royal_maze() -> String:
	var definition := BoardModelScript.route_definition(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE)
	if not GameState.commit_royal_maze_entry(BoardModelScript.ROUTE_MAIN, int(definition.return_tile)):
		return "転送床は静まっている。"
	var memo := "王の迷い環へ転送された"
	GameState.commit_roll_landing_core(&"STAGE_SPECIAL", memo)
	GameState.travel_memos.append(memo)
	_sync_board_route_context()
	SaveManager.save_now()
	await _play_royal_maze_entry_transition()
	return memo

func _play_royal_maze_entry_transition(duration_override: float = -1.0) -> Dictionary:
	# The route entry is already durable when this presentation begins. A killed
	# app therefore resumes in the maze and never replays or double-commits it.
	modal_open = true
	var layer := CanvasLayer.new()
	layer.name = "RoyalMazePopupBookLayer"
	layer.layer = 20
	add_child(layer)
	var transition: Control = PopupBookTransitionScript.new()
	transition.name = "RoyalMazePopupBookTransition"
	layer.add_child(transition)
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await transition.play(duration_override)
	var transition_receipt: Dictionary = transition.receipt()
	if is_instance_valid(layer):
		layer.queue_free()
	modal_open = false
	return transition_receipt

func _resume_roll_transaction() -> void:
	if GameState.roll_transaction.is_empty():
		return
	var phase := str(GameState.roll_transaction.get("phase", GameState.roll_transaction.get("roll_phase", "")))
	if phase in ["PRE_ROLL", "ROLLING", "TURN_RESOLVED"]:
		if phase == "TURN_RESOLVED":
			GameState.clear_roll_transaction()
		else:
			GameState.rollback_uncommitted_roll()
		SaveManager.save_now()
		_restore_roll_idle()
		return
	show_game()
	dice_values = _transaction_values(GameState.roll_transaction)
	dice_mode = clampi(int(GameState.roll_transaction.get("dice_count", 1)), 1, 5)
	last_roll_early_stopped = bool(GameState.roll_transaction.get("early_stopped", false))
	if phase == "RESULT_COMMITTED":
		await _present_resumed_roll_result()
	if phase == "MOVEMENT_COMMITTED" and str(GameState.roll_transaction.get("encounter_phase", "NONE")) != "NONE":
		await _resume_roll_encounter()
		return
	await _continue_roll_transaction()

func _restore_roll_idle() -> void:
	show_game()
	rolling_dice = false
	moving = false
	locked_dice_count = 0
	rolling_values.clear()
	if is_instance_valid(map_dice_overlay):
		map_dice_overlay.cancel_to_tray()
	if is_instance_valid(dice_presentation):
		dice_presentation.visible = true
	roll_button.text = "サイコロを振る"
	roll_button.disabled = false
	stop_all_button.visible = false

func _present_resumed_roll_result() -> void:
	var values := _transaction_values(GameState.roll_transaction)
	if values.is_empty():
		return
	moving = true
	roll_button.disabled = true
	if _uses_map_dice_overlay(values.size()):
		var tray_rect := _map_dice_tray_anchor_rect()
		var map_rect := board_view.get_global_rect()
		dice_presentation.visible = false
		await map_dice_overlay.begin_launch(values, tray_rect, map_rect, TourismMapViewScript.map_dice_landing_rect(map_rect.size, values.size()))
		map_dice_overlay.present(values, false, values.size())
		if values.size() != 5:
			var destination := int(GameState.roll_transaction.get("target_tile_index", GameState.current_tile_index))
			(board_view as TourismMapView).highlight_destination(destination, int(GameState.roll_transaction.get("distance", _sum_dice_values(values))))
		await map_dice_overlay.hold_and_return(values)
		if values.size() != 5:
			(board_view as TourismMapView).clear_destination_highlight()
		dice_presentation.visible = true
	else:
		_render_dice(values, false)
		await get_tree().create_timer(0.45).timeout
	moving = false

func _sum_dice_values(values: Array[int]) -> int:
	var total := 0
	for value: int in values:
		total += clampi(value, 1, 6)
	return total

func _resume_roll_encounter() -> void:
	var encounter_phase := str(GameState.roll_transaction.get("encounter_phase", "NONE"))
	var pair_bonus := bool(GameState.roll_transaction.get("encounter_pair_bonus", false))
	var double_bonus := int(GameState.roll_transaction.get("encounter_double_bonus", 0))
	var recovery_route := ""
	if encounter_phase in ["HANDOFF_PENDING", "MODAL_OPEN"]:
		await _show_encounter_modal(pair_bonus, double_bonus)
	elif encounter_phase == "INTERACTION_COMMITTED":
		if bool(GameState.roll_transaction.get("encounter_joined_now", false)):
			var definition := BossSystemScript.definition_by_id(str(GameState.roll_transaction.get("encounter_definition_id", "sleepy_sphinx")), boss_definitions)
			recovery_route = await _show_get_result(definition)
		else:
			GameState.complete_roll_encounter()
			SaveManager.save_now()
	elif encounter_phase == "REGISTRATION_COMMITTED":
		var definition := BossSystemScript.definition_by_id(str(GameState.roll_transaction.get("encounter_definition_id", "sleepy_sphinx")), boss_definitions)
		var obtained: Dictionary = (GameState.roll_transaction.get("encounter_obtained", {}) as Dictionary).duplicate(true)
		recovery_route = await _show_get_result(definition, obtained)
	if not recovery_route.is_empty():
		_finalize_recovered_roll_without_navigation()
		return
	if not GameState.roll_transaction.is_empty():
		GameState.complete_roll_encounter()
		SaveManager.save_now()
		await _finish_resumed_space_effect()

func _finalize_recovered_roll_without_navigation() -> void:
	if GameState.roll_transaction.is_empty():
		return
	if str(GameState.roll_transaction.get("phase", "")) == "MOVEMENT_COMMITTED":
		GameState.complete_roll_encounter()
		GameState.commit_roll_space_effect()
	if str(GameState.roll_transaction.get("phase", "")) == "SPACE_EFFECT_COMMITTED":
		GameState.mark_roll_turn_resolved()
	SaveManager.save_now()
	GameState.clear_roll_transaction()
	SaveManager.save_now()
	moving = false
	rolling_dice = false

func _commit_lap_crossings(count: int, source: String) -> void:
	for crossing_index: int in range(maxi(0, count)):
		var previous: Dictionary = GameState.last_lap_result
		if crossing_index == 0 and int(previous.get("journey_roll_index", -1)) == GameState.rolls_used and str(previous.get("source", "")) == source:
			continue
		var state := GameState.to_dictionary()
		var resolution_id := "lap:%08d:%s:%d:%d" % [GameState.total_laps + 1, source.to_lower(), GameState.rolls_used, crossing_index]
		var resolution := LapSystemScript.resolve(state, resolution_id, source)
		var applied := RewardResolverScript.apply(state, resolution, GameState.reward_apply_log)
		GameState.apply_dictionary(state)
		SaveManager.save_now()
		if bool(applied.get("applied", false)):
			await _show_lap_result_modal(resolution.get("result", {}))

func _resolve_landing(tile_type: StringName, roles: Dictionary) -> void:
	var transaction: Dictionary = GameState.roll_transaction
	var resolved_tile_type := StringName(str(transaction.get("landing_tile_type", String(tile_type))))
	var core_committed := bool(transaction.get("landing_core_committed", false))
	var memo := str(transaction.get("landing_memo", ""))
	if not bool(transaction.get("landing_roles_committed", false)):
		if roles.get("main", &"") == DiceLogicScript.PAIR:
			GameState.souvenirs += 1
		if roles.get("main", &"") == DiceLogicScript.STRAIGHT:
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
		if roles.get("main", &"") == DiceLogicScript.DOUBLE:
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
		GameState.commit_roll_landing_roles()
		SaveManager.save_now()
	var effective_tile_type := &"COMMITTED" if core_committed else resolved_tile_type
	match effective_tile_type:
		&"NORMAL":
			memo = ["日陰で猫があくびをした。", "砂の向こうで鐘が一度鳴った。", "冷たい風が市場から届いた。"][rng.randi_range(0, 2)]
		&"EVENT":
			var boss_handoff := await _show_event_modal(roles)
			memo = "短い旅の出来事を記録した。"
			_commit_landing_core(resolved_tile_type, memo + _landing_role_suffix(roles))
			if boss_handoff:
				memo_label.text = memo
				await _show_encounter_modal(roles.get("main", &"") == DiceLogicScript.PAIR, 2 if roles.get("main", &"") == DiceLogicScript.DOUBLE else 0)
				return
		&"ITEM":
			var item_rewards := BoardModelScript.item_space_rewards_for_roll(rng.randi_range(0, 99), roles.get("main", &"") == DiceLogicScript.DOUBLE)
			var item_notes: Array[String] = []
			for reward: StringName in item_rewards:
				match reward:
					&"DICE_ADD_1":
						# DOUBLE already moved the consumed 2-dice state to 3. Its
						# guaranteed item-space die is that progression, not overflow.
						if roles.get("main", &"") == DiceLogicScript.DOUBLE and GameState.current_dice_count == 3:
							item_notes.append("追加ダイスでスロット準備")
						else:
							var before_dice := GameState.current_dice_count
							var before_coins := GameState.coins
							var after_dice := GameState.add_dice()
							item_notes.append("追加ダイス %d→%d" % [before_dice, after_dice] if after_dice > before_dice else "余剰ダイスを旅コイン +%dへ変換" % (GameState.coins - before_coins))
					&"ITEM":
						GameState.inventory["pinpoint"] = int(GameState.inventory.get("pinpoint", 0)) + 1
						item_notes.append("ピンポイントチケット")
					&"ITEM_CHOICE":
						item_notes.append(await _show_item_space_choice())
			memo = "アイテムマス：" + "／".join(item_notes)
			_refresh_dice_mode_buttons()
		&"COIN":
			GameState.coins += 6
			memo = "古い旅コインを拾った。+6"
		&"WARP":
			memo = "風の道に乗って、6マス先へ。"
			GameState.current_lap_bonus += LapSystemScript.WARP_LAP_BONUS
			var warp: Dictionary = BoardModelScript.move(GameState.current_tile_index, 6)
			GameState.current_tile_index = int(warp.index)
			var warp_laps := int(warp.laps)
			board_view.set_current_tile(GameState.current_tile_index)
			minimap_view.set_current_tile(GameState.current_tile_index)
			_commit_landing_core(resolved_tile_type, memo + _landing_role_suffix(roles))
			if warp_laps > 0: await _commit_lap_crossings(warp_laps, "WARP")
		&"SHOP":
			if GameState.coins >= 3:
				GameState.coins -= 3
				GameState.inventory["fever"] = int(GameState.inventory.get("fever", 0)) + 1
				memo = "市場でフィーバーチケットを買った。"
			else:
				memo = "市場の香りだけ楽しんだ。"
		&"REST":
			GameState.boss_presence = mini(5, GameState.boss_presence + 1)
			memo = "オアシスでひと休み。足跡が少し近づいた。"
		&"LANDMARK":
			var landmark_state := GameState.to_dictionary()
			var landmark_resolution_id := "landmark:%08d:%d:%d" % [GameState.total_laps, GameState.rolls_used, GameState.current_tile_index]
			var landmark_resolution := LandmarkSystemScript.resolve_stop(landmark_state, GameState.current_tile_index, landmark_resolution_id)
			var landmark_applied := RewardResolverScript.apply(landmark_state, landmark_resolution, GameState.reward_apply_log)
			GameState.apply_dictionary(landmark_state)
			var landmark_result: Dictionary = landmark_resolution.get("result", {})
			memo = "%s Lv.%d　旅の記憶 +1" % [str(landmark_result.get("name", "カイロの名所")), int(landmark_result.get("new_level", 0))]
			_commit_landing_core(resolved_tile_type, memo + _landing_role_suffix(roles))
			if bool(landmark_applied.get("applied", false)):
				await _show_landmark_result_modal(landmark_result, landmark_applied.get("summary", []))
		&"BOSS_SCENT":
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 2)
			memo = ["砂の上に、大きな足跡が残っている。", "遠くから、低いあくびが聞こえた。", "誰かがここで、しばらく昼寝をしていたらしい。 "][rng.randi_range(0, 2)]
		&"STAGE_SPECIAL":
			if GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == BoardModelScript.ROYAL_MAZE_SOURCE_TILE:
				memo = await _enter_royal_maze()
			else:
				GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
				memo = "砂時計の影が道を横切った。カイロの気配 +1"
		&"RISK":
			if GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE:
				memo = _apply_maze_hazard(false)
			elif GameState.current_route_id == BoardModelScript.ROUTE_BYPASS_CARAVAN:
				memo = _apply_bypass_hazard(false)
			else:
				memo = await _show_risk_space_modal(roles)
		&"STRONG_RISK":
			memo = _apply_maze_hazard(true) if GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE else _apply_bypass_hazard(true)
		&"GAMBLE":
			memo = await _show_bypass_gamble()
		&"TREASURE":
			memo = _claim_maze_treasure()
		&"ANCIENT_ITEM":
			memo = _claim_maze_ancient_item()
		&"MURAL":
			memo = _claim_maze_mural()
		&"RETURN_GATE":
			memo = "帰還扉を通過した。ぴったり停止ではないため、回廊は続く。"
		&"LOOP_EXIT":
			memo = "王の迷い環を脱出した"
	if not bool(GameState.roll_transaction.get("landing_core_committed", false)):
		_commit_landing_core(resolved_tile_type, memo + _landing_role_suffix(roles))
	else:
		memo = str(GameState.roll_transaction.get("landing_memo", memo))
	memo_label.text = memo
	await get_tree().create_timer(0.18).timeout
	# TRIPLE always invites one encounter after landing, even on a special space.
	# Normal-space chance rolls are never layered on top of that certain encounter.
	var triple_forced: bool = roles.get("main", &"") == DiceLogicScript.TRIPLE
	if triple_forced:
		await _show_encounter_modal(false)
	elif resolved_tile_type == &"NORMAL" and GameState.current_route_id == BoardModelScript.ROUTE_MAIN:
		var forced: bool = GameState.debug_force_encounter
		GameState.debug_force_encounter = false
		var appears := BossSystemScript.should_encounter(GameState.boss_presence, GameState.boss_relief, forced, rng.randf())
		if appears:
			var pair_bonus: bool = roles.get("main", &"") == DiceLogicScript.PAIR
			await _show_encounter_modal(pair_bonus, 2 if roles.get("main", &"") == DiceLogicScript.DOUBLE else 0)
		else:
			GameState.boss_relief = mini(BossSystemScript.RELIEF_FORCE_AFTER, GameState.boss_relief + 1)
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)

func _apply_bypass_hazard(strong: bool = false, forced_load_collapse: bool = false) -> String:
	var tile_index := GameState.current_tile_index
	var hazard_name := ""
	var would_change := false
	if strong:
		if forced_load_collapse or tile_index == 2:
			hazard_name = "荷崩れ"
			would_change = GameState.current_dice_count != 1 or GameState.temporary_roll_dice_count != 0 or GameState.dice_keep_active or GameState.dice_double_retry_active or GameState.dice_slot_retry_active
		else:
			hazard_name = "砂嵐の袋小路"
			would_change = true
	else:
		match tile_index:
			0: hazard_name = "裂けた荷袋"; would_change = GameState.coins > 0
			1: hazard_name = "向かい風"; would_change = GameState.next_move_bonus > -2
			3: hazard_name = "砂に埋もれた標"; would_change = tile_index > 0
			_: hazard_name = "消える足跡"; would_change = GameState.boss_presence > 0
	if not would_change:
		return "%s：影響なし（CLEAN維持）" % hazard_name
	if GameState.even_guard_active:
		GameState.even_guard_active = false
		return "ALL EVENガードで%sを完全防御（CLEAN維持）" % hazard_name
	if strong:
		if forced_load_collapse or tile_index == 2:
			GameState.current_dice_count = 1
			GameState.temporary_roll_dice_count = 0
			GameState.dice_keep_active = false
			GameState.dice_double_retry_active = false
			GameState.dice_slot_retry_active = false
		else:
			GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, maxi(0, tile_index - 2))
	else:
		match tile_index:
			0: GameState.coins = maxi(0, GameState.coins - 8)
			1: GameState.next_move_bonus = mini(GameState.next_move_bonus, -2)
			3: GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, maxi(0, tile_index - 3))
			_: GameState.boss_presence = maxi(0, GameState.boss_presence - 1)
	GameState.current_lap_clean = false
	GameState.current_lap_penalty_count += 1
	GameState.bypass_clean_losses += 1
	GameState.bypass_damaged_this_visit = true
	GameState.flow_level = 0
	board_view.set_current_tile(GameState.current_tile_index)
	minimap_view.set_current_tile(GameState.current_tile_index)
	_sync_flow_visuals()
	return "%sの不利益が発生（CLEAN失敗）" % hazard_name

func _show_bypass_gamble() -> String:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_body("GAMBLE", 15))
	content.add_child(_title("砂嵐を突っ切りますか？", 30))
	var careful := _button("慎重に進む　次回移動 -1", func() -> void: return, true); careful.name = "bypass_gamble_careful"; careful.toggle_mode = true
	var dash := _button("一気に抜ける　追加3ダイス", func() -> void: return); dash.name = "bypass_gamble_dash"; dash.toggle_mode = true
	content.add_child(careful); content.add_child(dash)
	var chosen := await _wait_for_action([careful, dash])
	careful.disabled = true; dash.disabled = true
	if chosen == 0:
		GameState.next_move_bonus -= 1
		_close_modal(modal.layer)
		return "慎重に進む。次回移動 -1"
	fixed_targets = GameState.debug_fixed_extra_rolls.duplicate(); GameState.debug_fixed_extra_rolls.clear()
	var values := await _animate_dice_roll(3, content)
	var gamble_roles := DiceLogicScript.evaluate(values)
	var main_role: StringName = gamble_roles.get("main", &"")
	var support_role: StringName = gamble_roles.get("support", &"")
	var memo := ""
	if main_role == DiceLogicScript.TRIPLE:
		var exit_definition := BoardModelScript.route_definition(BoardModelScript.ROUTE_BYPASS_CARAVAN)
		GameState.set_route_position(str(exit_definition.exit_route), int(exit_definition.exit_tile))
		_finalize_bypass_exit()
		memo = "TRIPLE：バイパス出口へ即時移動"
	elif main_role in [DiceLogicScript.STRAIGHT, DiceLogicScript.PAIR]:
		var advance := 5 if main_role == DiceLogicScript.STRAIGHT else 3
		var movement := BoardModelScript.advance_route(GameState.current_route_id, GameState.current_tile_index, advance)
		GameState.set_route_position(str(movement.route_id), int(movement.tile_index))
		if GameState.current_route_id == BoardModelScript.ROUTE_MAIN:
			_finalize_bypass_exit()
		elif BoardModelScript.tile_type_for_position(GameState.current_route_id, GameState.current_tile_index) == &"COIN":
			GameState.coins += 6
		memo = "%s：%dマス前進" % [String(main_role), advance]
	elif support_role == DiceLogicScript.ALL_EVEN:
		GameState.even_guard_active = true
		memo = "ALL EVEN：危険ガード1回"
	elif support_role == DiceLogicScript.ALL_ODD:
		GameState.current_lap_bonus += 20
		memo = "ALL ODD：ラップボーナス +20"
	else:
		memo = _apply_bypass_hazard(true, true)
	_sync_board_route_context()
	minimap_view.set_current_tile(GameState.current_tile_index)
	_close_modal(modal.layer)
	return memo

func _landing_role_suffix(roles: Dictionary) -> String:
	if roles.get("main", &"") == DiceLogicScript.PAIR:
		return "　PAIRのおみやげ +1"
	if roles.get("main", &"") == DiceLogicScript.STRAIGHT:
		return "　STRAIGHTで気配が近づいた。"
	if roles.get("main", &"") == DiceLogicScript.DOUBLE:
		return "　DOUBLEでDICE SLOT READY。気配も近づいた。"
	return ""

func _apply_maze_hazard(strong: bool) -> String:
	var tile_index := GameState.current_tile_index
	var hazard_name: String = "逆さ砂時計" if strong else str({1: "落砂回廊", 3: "呪いの壁画", 7: "石棺の影"}.get(tile_index, "王墓の影"))
	var would_change := true
	if not strong:
		match tile_index:
			1: would_change = GameState.next_move_bonus > -2
			3: would_change = GameState.coins > 0
			7: would_change = GameState.flow_level > 0
	if not would_change:
		return "%s：影響なし（CLEAN維持）" % hazard_name
	if GameState.even_guard_active:
		GameState.even_guard_active = false
		return "ALL EVENガードで%sを完全防御（CLEAN維持）" % hazard_name
	if strong:
		GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, posmod(tile_index - 3, 8))
	else:
		match tile_index:
			1: GameState.next_move_bonus = mini(GameState.next_move_bonus, -2)
			3: GameState.coins = maxi(0, GameState.coins - 8)
			7: GameState.flow_level = 0
	GameState.current_lap_clean = false
	GameState.current_lap_penalty_count += 1
	GameState.flow_level = 0
	_sync_board_route_context()
	_sync_flow_visuals()
	return "%sの不利益が発生（CLEAN失敗）" % hazard_name

func _claim_maze_treasure() -> String:
	if GameState.maze_treasure_claimed:
		return "宝物庫は空になっている。"
	GameState.maze_treasure_claimed = true
	match rng.randi_range(0, 3):
		0:
			var amount := rng.randi_range(30, 50)
			GameState.coins += amount
			return "王の宝物庫：旅コイン +%d" % amount
		1:
			GameState.inventory["royal_scale"] = int(GameState.inventory.get("royal_scale", 0)) + 1
			return "王の宝物庫：王墓の目盛り"
		2:
			GameState.add_dice()
			return "王の宝物庫：追加ダイス +1"
		_:
			GameState.dice_keep_active = true
			return "王の宝物庫：DICE KEEP"

func _claim_maze_ancient_item() -> String:
	if bool(GameState.maze_collection_flags.get("ancient_item_this_visit", false)):
		return "古代の台座は空になっている。"
	GameState.maze_collection_flags["ancient_item_this_visit"] = true
	var item_ids := ["royal_scale", "sand_seal_ring", "stonemason_hammer"]
	var item_names := ["王墓の目盛り", "砂封じの輪", "石工の小槌"]
	var index := posmod(GameState.maze_loop_count + GameState.total_laps, item_ids.size())
	GameState.inventory[item_ids[index]] = int(GameState.inventory.get(item_ids[index], 0)) + 1
	return "古代アイテム：%s" % item_names[index]

func _claim_maze_mural() -> String:
	var fragment_id := "royal_mural_01"
	if bool(GameState.maze_collection_flags.get(fragment_id, false)):
		GameState.current_lap_bonus += 10
		return "王の壁画：登録済みの断片をラップボーナス +10へ変換"
	GameState.maze_collection_flags[fragment_id] = true
	var fragment_count := 0
	for key: Variant in GameState.maze_collection_flags.keys():
		if str(key).begins_with("royal_mural_") and bool(GameState.maze_collection_flags[key]): fragment_count += 1
	return "王の壁画 %d / 6：新しい断片を登録" % fragment_count

func _commit_landing_core(tile_type: StringName, memo: String) -> void:
	if not GameState.commit_roll_landing_core(tile_type, memo):
		return
	GameState.travel_memos.append(memo)
	SaveManager.save_now()

func _build_landmark_result_modal(result: Dictionary, summary: Array) -> Dictionary:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	var developed := bool(result.get("developed", false))
	content.add_child(_body("LANDMARK", 15))
	content.add_child(_title(str(result.get("name", "カイロの名所")), 32))
	content.add_child(_body("Lv.%d → Lv.%d" % [int(result.get("old_level", 0)), int(result.get("new_level", 0))] if developed else "Lv.3　完成した景色を再訪", 23))
	content.add_child(_body("　".join(summary) if not summary.is_empty() else "旅の記憶に残した。", 18))
	var close := _button("旅を続ける", func() -> void: return, true)
	close.name = "landmark_result_close"
	close.toggle_mode = true
	content.add_child(close)
	modal["close"] = close
	return modal

func _show_landmark_result_modal(result: Dictionary, summary: Array) -> void:
	var modal := _build_landmark_result_modal(result, summary)
	await _wait_brief_result(modal, 0.62)

func _build_lap_result_modal(result: Dictionary) -> Dictionary:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_body("LAP %d COMPLETE" % int(result.get("lap_number", GameState.lap_count)), 18))
	content.add_child(_title("LAP POINT +%d" % int(result.get("points", 100)), 34))
	var clean_text := "CLEAN STREAK %d　×%.2f" % [int(result.get("clean_streak", 0)), float(result.get("multiplier", 1.0))] if bool(result.get("clean", true)) else "CLEAN失敗　×1.00"
	content.add_child(_body("基本 %d　＋　ラップボーナス %d\n%s　→　獲得 %d\nラップスコア %d　（%dロール）" % [int(result.get("base_points", 100)), int(result.get("lap_bonus", 0)), clean_text, int(result.get("points", 100)), int(result.get("score", 0)), int(result.get("roll_count", 0))], 19))
	var milestone := int(result.get("milestone", 0))
	if milestone in [2, 3, 5]:
		var reward_text: String = str({2: "旅コイン +12", 3: "追加ダイス +1", 5: "DICE KEEP"}.get(milestone, ""))
		content.add_child(_body("CLEAN %d 到達ボーナス　%s" % [milestone, reward_text], 18))
	content.add_child(_body(str(result.get("next_clean_goal", LapSystemScript.next_clean_goal_for(int(result.get("clean_streak", 0))))), 17))
	var close := _button("次の一周へ", func() -> void: return, true)
	close.name = "lap_result_close"
	close.toggle_mode = true
	content.add_child(close)
	modal["close"] = close
	return modal

func _show_lap_result_modal(result: Dictionary) -> void:
	var modal := _build_lap_result_modal(result)
	await _wait_brief_result(modal, 0.62)

func _wait_brief_result(modal: Dictionary, duration: float) -> void:
	var close: Button = modal.close
	var deadline := Time.get_ticks_msec() + roundi(duration * 1000.0)
	while not close.button_pressed and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_close_modal(modal.layer)

func _show_item_space_choice() -> String:
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_title("旅道具をひとつ", 30))
	content.add_child(_body("見つけた二つの包み。どちらを持っていこう？", 20))
	var pinpoint := _button("ピンポイントチケット", func() -> void: return, true); pinpoint.name = "item_space_choice_pinpoint"; pinpoint.toggle_mode = true
	var fever := _button("フィーバーチケット", func() -> void: return); fever.name = "item_space_choice_fever"; fever.toggle_mode = true
	content.add_child(pinpoint); content.add_child(fever)
	var chosen := await _wait_for_action([pinpoint, fever])
	var item_id := "pinpoint" if chosen == 0 else "fever"
	GameState.inventory[item_id] = int(GameState.inventory.get(item_id, 0)) + 1
	_close_modal(modal.layer)
	return "2候補から%s" % ("ピンポイントチケット" if chosen == 0 else "フィーバーチケット")

func _show_risk_space_modal(roles: Dictionary = {}) -> String:
	var base_dice_before := GameState.current_dice_count
	var risk_tile := GameState.current_tile_index
	var risk_name := RewardResolverScript.risk_name_for_tile(risk_tile)
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_title(risk_name, 32))
	content.add_child(_body("受け流すか、3ダイスの目押しで突破するか。\n役が成立すれば不利益を防ぎ、今のダイスも失いません。", 20))
	var safe := _button("受け流す", func() -> void: return, true); safe.name = "risk_safe"; safe.toggle_mode = true
	var challenge := _button("目押しで突破　追加3ダイス", func() -> void: return); challenge.name = "risk_challenge"; challenge.toggle_mode = true
	content.add_child(safe); content.add_child(challenge)
	var chosen := await _wait_for_action([safe, challenge])
	safe.disabled = true; challenge.disabled = true
	var memo := ""
	if chosen == 0:
		memo = _apply_risk_harm(risk_tile)
	else:
		fixed_targets = GameState.debug_fixed_extra_rolls.duplicate(); GameState.debug_fixed_extra_rolls.clear()
		var extra_values := await _animate_dice_roll(3, content)
		var extra_roles := DiceLogicScript.evaluate(extra_values)
		var main_role: StringName = extra_roles.get("main", DiceLogicScript.MAIN_NONE)
		var support_role: StringName = extra_roles.get("support", DiceLogicScript.MAIN_NONE)
		if main_role == DiceLogicScript.TRIPLE:
			GameState.current_dice_count = 3; GameState.coins += 30; memo = "挑戦成功：TRIPLE。DICE SLOT READY／旅コイン +30"
		elif main_role == DiceLogicScript.STRAIGHT:
			GameState.add_dice(); GameState.inventory["pinpoint"] = int(GameState.inventory.get("pinpoint", 0)) + 1; memo = "挑戦成功：STRAIGHT。追加ダイスと旅道具"
		elif main_role == DiceLogicScript.PAIR:
			GameState.add_dice(); GameState.coins += 30; memo = "挑戦成功：PAIR。追加ダイス／旅コイン +30"
		elif support_role == DiceLogicScript.ALL_EVEN:
			GameState.add_dice(); memo = "挑戦成功：ALL EVEN。追加ダイス +1"
		elif support_role == DiceLogicScript.ALL_ODD:
			GameState.coins += 30; memo = "挑戦成功：ALL ODD。旅コイン +30"
		else:
			memo = _apply_risk_harm(risk_tile)
	# The risk branch may add dice, but never removes the state held on arrival.
	GameState.current_dice_count = maxi(base_dice_before, GameState.current_dice_count)
	_commit_landing_core(&"RISK", memo + _landing_role_suffix(roles))
	content.add_child(_body(memo, 20))
	var close := _button("旅へ戻る", func() -> void: return, true); close.name = "risk_close"; close.toggle_mode = true; content.add_child(close)
	await close.pressed
	_close_modal(modal.layer)
	return memo

func _apply_risk_harm(tile_index: int) -> String:
	var flow_before := GameState.flow_level
	var state := GameState.to_dictionary()
	var resolution_id := "risk:%08d:%d:%d" % [GameState.total_laps, GameState.rolls_used, tile_index]
	var resolution := RewardResolverScript.resolve_risk(state, resolution_id, tile_index)
	var applied := RewardResolverScript.apply(state, resolution, GameState.reward_apply_log)
	GameState.apply_dictionary(state)
	board_view.set_current_tile(GameState.current_tile_index)
	minimap_view.set_current_tile(GameState.current_tile_index)
	_sync_flow_visuals()
	if flow_before > 0 and GameState.flow_level == 0:
		_play_flow_pulse(&"flow_broken")
	var summary: Array = applied.get("summary", [])
	return str(summary[0]) if not summary.is_empty() else "%s：処理済み" % RewardResolverScript.risk_name_for_tile(tile_index)

func _event_by_id(event_id: String) -> Dictionary:
	for event: Dictionary in event_definitions:
		if str(event.get("event_id", "")) == event_id: return event
	return {}

func _show_event_modal(source_roles: Dictionary) -> bool:
	var district := EventSystemScript.district_for_tile(GameState.current_tile_index)
	var state := GameState.to_dictionary()
	var event: Dictionary = {}
	if not GameState.debug_forced_event_id.is_empty():
		event = _event_by_id(GameState.debug_forced_event_id)
		GameState.debug_forced_event_id = ""
	if event.is_empty(): event = EventSystemScript.pick_event(district, event_definitions, state, rng.randf())
	if event.is_empty(): return false
	var event_district := str(event.get("district_id", district))
	var arrival := EventSystemScript.arrival_snapshot(dice_values, source_roles, last_roll_early_stopped, GameState.selected_character_id)
	event_state = &"EVENT_OPENING"
	GameState.active_event_state = {"phase": String(event_state), "event_id": event.event_id, "arrival": arrival.duplicate(true)}
	SaveManager.save_now()
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	var district_text := _body("◇ %s" % event_district, 18); district_text.add_theme_color_override("font_color", INK); content.add_child(district_text)
	content.add_child(_title(str(event.get("display_name", "旅の出来事")), 36))
	var opening_text := _body(str(event.get("first_text", "風景が少し変わった。")), 23); opening_text.add_theme_color_override("font_color", INK); content.add_child(opening_text)
	var arrival_text := _body("到着 %s　合計 %d" % [str(arrival.source_dice_values), int(arrival.source_total)], 18); arrival_text.add_theme_color_override("font_color", Color("66503b")); content.add_child(arrival_text)
	var choice_id := ""
	var choices: Array = event.get("choices", [])
	var extra_count := int(event.get("additional_dice_count", 0))
	if not choices.is_empty():
		event_state = &"WAITING_FOR_CHOICE"
		GameState.active_event_state["phase"] = String(event_state)
		var buttons: Array[Button] = []
		for choice: Dictionary in choices:
			var choice_button := _button(str(choice.get("label", "進む")), func() -> void: return, buttons.is_empty())
			choice_button.toggle_mode = true
			choice_button.name = "event_choice_%s" % str(choice.get("choice_id", buttons.size()))
			buttons.append(choice_button); content.add_child(choice_button)
		var chosen := await _wait_for_action(buttons)
		choice_id = str((choices[chosen] as Dictionary).get("choice_id", chosen))
		for button: Button in buttons: button.disabled = true
	elif extra_count == 0:
		var proceed := _button("様子を見る", func() -> void: return, true); proceed.toggle_mode = true; proceed.name = "event_proceed"; content.add_child(proceed)
		await proceed.pressed; proceed.disabled = true
	var extra: Dictionary = {}
	if extra_count > 0:
		event_state = &"WAITING_FOR_EXTRA_ROLL"
		GameState.active_event_state["phase"] = String(event_state)
		GameState.active_event_state["extra_dice_count"] = extra_count
		SaveManager.save_now()
		var extra_instruction := _body("追加%dダイス。移動せず、出目だけを使います。" % extra_count, 20); extra_instruction.add_theme_color_override("font_color", INK); content.add_child(extra_instruction)
		var roll_extra := _button("追加ダイスを振る", func() -> void: return, true)
		roll_extra.toggle_mode = true; roll_extra.name = "event_extra_roll"; content.add_child(roll_extra)
		await roll_extra.pressed
		roll_extra.disabled = true
		fixed_targets = GameState.debug_fixed_extra_rolls.duplicate()
		GameState.debug_fixed_extra_rolls.clear()
		var extra_values := await _animate_dice_roll(extra_count, content)
		var extra_total := 0
		for value: int in extra_values: extra_total += value
		var extra_roles := DiceLogicScript.evaluate(extra_values) if extra_count == 3 else (DiceLogicScript.evaluate_many(extra_values) if extra_count == 5 else {"labels": []})
		var effective := mini(6, extra_total + (1 if extra_count == 1 and source_roles.get("main", &"") == DiceLogicScript.PAIR else 0))
		extra = {"extra_dice_count": extra_count, "extra_dice_values": extra_values, "extra_total": extra_total, "effective_value": effective, "extra_roles": extra_roles, "role_type_count": int(extra_roles.get("type_count", extra_roles.get("labels", []).size()))}
		var extra_result_text := _body("追加結果 %s%s" % [str(extra_values), "（PAIR補正で%d）" % effective if effective != extra_total else ""], 22); extra_result_text.add_theme_color_override("font_color", INK); content.add_child(extra_result_text)
	event_state = &"RESOLVING_RESULT"
	var outcome := EventSystemScript.resolve(event, arrival, choice_id, extra)
	var resolution_id := "%s-%d-%d" % [str(event.event_id), Time.get_ticks_msec(), GameState.event_history.size()]
	outcome["resolution_id"] = resolution_id
	await _resolve_event_item_choices(outcome, content)
	state = GameState.to_dictionary()
	EventSystemScript.record_event(state, str(event.event_id))
	var applied := RewardResolverScript.apply(state, outcome, GameState.reward_apply_log)
	state["active_event_state"] = {"phase": "SHOWING_RESULT", "event_id": event.event_id, "arrival": arrival, "extra": extra, "outcome": outcome, "summary": applied.summary}
	GameState.apply_dictionary(state)
	event_state = &"SHOWING_RESULT"
	var event_result_text := _body(str(outcome.get("result_text", "旅の記憶になった。")), 23); event_result_text.add_theme_color_override("font_color", INK); content.add_child(event_result_text)
	var reward_summary := _body("　".join(applied.summary) if not applied.summary.is_empty() else "旅メモに残した。", 19); reward_summary.add_theme_color_override("font_color", Color("66503b")); content.add_child(reward_summary)
	var close_button := _button("旅を続ける", func() -> void: return, true)
	close_button.name = "event_close"; close_button.toggle_mode = true; content.add_child(close_button)
	await close_button.pressed
	event_state = &"CLOSING"
	var handoff := GameState.pending_boss_handoff and GameState.debug_boss_handoff_enabled
	if handoff and not GameState.roll_transaction.is_empty():
		GameState.mark_roll_encounter_handoff(source_roles.get("main", &"") == DiceLogicScript.PAIR, 2 if source_roles.get("main", &"") == DiceLogicScript.DOUBLE else 0)
	GameState.active_event_state.clear()
	GameState.pending_event_rewards.clear()
	if not GameState.debug_boss_handoff_enabled: GameState.pending_boss_handoff = false
	SaveManager.save_now()
	_close_modal(modal.layer)
	event_state = &"IDLE"
	return handoff

func _reset_event_loop_state() -> void:
	var state := GameState.to_dictionary(); EventSystemScript.reset_loop_state(state); GameState.apply_dictionary(state)

func _resume_pending_boss_handoff() -> void:
	if not GameState.pending_boss_handoff: return
	show_game()
	var pair_bonus := false
	var double_bonus := 0
	var encounter_phase := str(GameState.roll_transaction.get("encounter_phase", "NONE"))
	if encounter_phase in ["HANDOFF_PENDING", "MODAL_OPEN"]:
		pair_bonus = bool(GameState.roll_transaction.get("encounter_pair_bonus", false))
		double_bonus = maxi(0, int(GameState.roll_transaction.get("encounter_double_bonus", 0)))
	if not GameState.roll_transaction.is_empty() and str(GameState.roll_transaction.get("encounter_phase", "NONE")) == "NONE":
		GameState.mark_roll_encounter_handoff(pair_bonus, double_bonus)
		SaveManager.save_now()
	await _show_encounter_modal(pair_bonus, double_bonus)
	await _finish_resumed_space_effect()

func _resolve_event_item_choices(outcome: Dictionary, content: VBoxContainer) -> void:
	for reward: Variant in outcome.get("rewards", []):
		if not reward is Dictionary: continue
		var item_reward := reward as Dictionary
		if str(item_reward.get("type", "")) != "ITEM" or int(item_reward.get("choice_count", 1)) < 2: continue
		var item_choice_text := _body("ふたつの旅道具から、ひとつ選べます。", 19); item_choice_text.add_theme_color_override("font_color", INK); content.add_child(item_choice_text)
		var seed := posmod(hash(str(outcome.get("resolution_id", "choice"))), 100)
		var second_uncommon := seed < 25
		# At least one candidate is always COMMON; the second follows COMMON75/UNCOMMON25.
		var candidates := [
			{"id": "mint_tea", "label": "冷たいミントティー", "rarity": "COMMON"},
			{"id": "dates_pouch" if second_uncommon else "footprint_note", "label": "デーツの小袋" if second_uncommon else "足跡メモ", "rarity": "UNCOMMON" if second_uncommon else "COMMON"}
		]
		var buttons: Array[Button] = []
		for candidate: Dictionary in candidates:
			var button := _button(candidate.label, func() -> void: return, buttons.is_empty()); button.toggle_mode = true; buttons.append(button); content.add_child(button)
		var index := await _wait_for_action(buttons)
		for button: Button in buttons: button.disabled = true
		item_reward["item_id"] = candidates[index].id
		item_reward["rarity"] = candidates[index].rarity

func _resume_active_event() -> void:
	var saved := GameState.active_event_state.duplicate(true)
	if saved.is_empty(): return
	show_game()
	var phase := str(saved.get("phase", "EVENT_OPENING"))
	if phase in ["RESOLVING_RESULT", "SHOWING_RESULT"] and saved.has("outcome"):
		var state := GameState.to_dictionary()
		var applied := RewardResolverScript.apply(state, saved.outcome, GameState.reward_apply_log)
		GameState.apply_dictionary(state)
		var modal := _make_modal(); var content: VBoxContainer = modal.content
		content.add_child(_title("旅の出来事", 34))
		content.add_child(_body(str(saved.get("outcome", {}).get("result_text", "旅の記録を復元しました。")), 22))
		var restored_summary: Array = saved.get("summary", applied.get("summary", []))
		content.add_child(_body("　".join(restored_summary) if not restored_summary.is_empty() else "報酬は適用済みです。", 18))
		var close := _button("旅を続ける", func() -> void: return, true); close.toggle_mode = true; close.name = "event_resume_close"; content.add_child(close)
		await close.pressed
		var restored_pair: bool = false
		var restored_double: int = 0
		if GameState.pending_boss_handoff:
			var restored_roles: Dictionary = saved.get("arrival", {}).get("source_roles", {})
			restored_pair = restored_roles.get("main", &"") == DiceLogicScript.PAIR
			restored_double = 2 if restored_roles.get("main", &"") == DiceLogicScript.DOUBLE else 0
			if not GameState.roll_transaction.is_empty() and str(GameState.roll_transaction.get("encounter_phase", "NONE")) == "NONE":
				GameState.mark_roll_encounter_handoff(restored_pair, restored_double)
		GameState.active_event_state.clear(); SaveManager.save_now(); _close_modal(modal.layer)
		if GameState.pending_boss_handoff:
			await _show_encounter_modal(restored_pair, restored_double)
		await _finish_resumed_space_effect()
		return
	var arrival: Dictionary = saved.get("arrival", {})
	dice_values.assign(arrival.get("source_dice_values", [1, 2, 3]))
	GameState.debug_forced_event_id = str(saved.get("event_id", "CAI-E01"))
	var roles: Dictionary = arrival.get("source_roles", DiceLogicScript.evaluate(dice_values))
	var boss_handoff := await _show_event_modal(roles)
	if boss_handoff:
		await _show_encounter_modal(roles.get("main", &"") == DiceLogicScript.PAIR, 2 if roles.get("main", &"") == DiceLogicScript.DOUBLE else 0)
	await _finish_resumed_space_effect()

func _finish_resumed_space_effect() -> void:
	if GameState.roll_transaction.is_empty():
		return
	var phase := str(GameState.roll_transaction.get("phase", GameState.roll_transaction.get("roll_phase", "")))
	if phase == "MOVEMENT_COMMITTED":
		GameState.commit_roll_space_effect()
		SaveManager.save_now()
		phase = "SPACE_EFFECT_COMMITTED"
	if phase == "SPACE_EFFECT_COMMITTED":
		await _resume_roll_transaction()

func _compact_clean_hud(points: int, is_clean: bool, streak: int) -> String:
	var current := clampi(streak, 0, LapSystemScript.MAX_CLEAN_STREAK)
	if not is_clean:
		var recovery_target := maxi(1, current)
		return "LAP POINT %d\nCLEAN失敗　STREAK %d\nRECOVER %d（次周）" % [points, current, recovery_target]
	if current >= LapSystemScript.MAX_CLEAN_STREAK:
		return "LAP POINT %d\nCLEAN STREAK MAX\nCLEAN維持中" % points
	for target: int in [2, 3, 5]:
		if current < target:
			return "LAP POINT %d\nCLEAN STREAK %d\nNEXT %d（あと%d周）" % [points, current, target, target - current]
	return "LAP POINT %d\nCLEAN STREAK %d\nCLEAN維持中" % [points, current]

func _refresh_hud() -> void:
	if lap_label == null:
		return
	lap_label.text = _compact_clean_hud(GameState.total_lap_points, GameState.current_lap_clean, GameState.clean_streak)
	coin_label.text = "旅コイン %d" % GameState.coins
	var route_definition := BoardModelScript.route_definition(GameState.current_route_id)
	var route_status := "現在 %dマス" % (GameState.current_tile_index + 1)
	if GameState.current_route_id != BoardModelScript.ROUTE_MAIN:
		route_status = "%s %d / %d" % [str(route_definition.name), GameState.current_tile_index + 1, int(route_definition.tile_count)]
	rolls_label.text = "LAP %d　ターン %d / 36　%s　次回 %dダイス" % [GameState.lap_count, GameState.rolls_used, route_status, clampi(GameState.current_dice_count, 1, 3)]
	if is_instance_valid(landmark_level_label):
		if GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE:
			var gate_distance := posmod(int(route_definition.return_gate_tile) - GameState.current_tile_index, int(route_definition.tile_count))
			landmark_level_label.text = "内部見取り図　帰還扉まで %d" % gate_distance
		else:
			landmark_level_label.text = "全体マップ　名所 Lv.%d・%d・%d" % [int(GameState.landmark_levels.get("CAI_LANDMARK_01", 0)), int(GameState.landmark_levels.get("CAI_LANDMARK_02", 0)), int(GameState.landmark_levels.get("CAI_LANDMARK_03", 0))]
	if is_instance_valid(board_view): board_view.set_landmark_levels(GameState.landmark_levels)
	if board_view is TourismMapView: (board_view as TourismMapView).set_dice_count(GameState.current_dice_count)
	if is_instance_valid(minimap_view): minimap_view.set_landmark_levels(GameState.landmark_levels)
	GameState.ensure_boss_data()
	var footprints := "・".repeat(5 - GameState.boss_presence) + "●".repeat(GameState.boss_presence)
	boss_label.text = str(GameState.current_boss.get("name", "眠そうなスフィンクス"))
	if is_instance_valid(boss_gauge): boss_gauge.value = int(GameState.current_boss.get("gauge", 0))
	if is_instance_valid(boss_presence_label): boss_presence_label.text = "交流 %d%%　気配 %s" % [int(GameState.current_boss.get("gauge", 0)), footprints]
	stamp_label.text = "旅のスタンプ　" + ("なし" if GameState.lap_stamps.is_empty() else "  ".join(GameState.lap_stamps))
	_refresh_dice_mode_buttons()

func _make_modal() -> Dictionary:
	modal_open = true
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.12, 0.08, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f5ead2")
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	return {"layer": layer, "content": content}

func _close_modal(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
	modal_open = false

func _show_encounter_modal(pair_bonus: bool, double_bonus: int = 0) -> void:
	GameState.ensure_boss_data()
	_play_encounter_chime()
	var definition := BossSystemScript.definition_by_id(str(GameState.current_boss.get("definition_id", "sleepy_sphinx")), boss_definitions)
	var modal := _make_modal()
	if not GameState.roll_transaction.is_empty() and str(GameState.roll_transaction.get("encounter_phase", "NONE")) != "MODAL_OPEN":
		GameState.mark_roll_encounter_open(pair_bonus, double_bonus)
	# Consume the durable handoff only after the production boss modal exists.
	if GameState.pending_boss_handoff:
		GameState.pending_boss_handoff = false
	SaveManager.save_now()
	var content: VBoxContainer = modal.content
	var portrait := TextureRect.new()
	portrait.texture = SPHINX_TEXTURE
	portrait.custom_minimum_size = Vector2(0, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(portrait)
	content.add_child(_title("%sがいる" % str(GameState.current_boss.get("name", "スフィンクス")), 34))
	var situation := _body(BossSystemScript.line_for(GameState.current_boss, definition, GameState.rolls_used), 22)
	content.add_child(situation)
	var role_bonus_text := "　PAIR +3" if pair_bonus else ("　DOUBLE +2" if double_bonus > 0 else "")
	var gauge := _body("交流 %d%%　出会い %d回%s" % [int(GameState.current_boss.get("gauge", 0)), int(GameState.current_boss.get("encounters", 0)), role_bonus_text], 19)
	gauge.add_theme_color_override("font_color", TEAL)
	content.add_child(gauge)
	var actions: Array = definition.get("actions", [])
	var buttons: Array[Button] = []
	for index: int in range(actions.size()):
		var action: Dictionary = actions[index]
		var button := _button(str(action.get("label", "そっと見守る")), func() -> void: return, index == 0)
		button.name = "boss_action_%d" % index
		button.toggle_mode = true
		buttons.append(button)
		content.add_child(button)
	var chosen := 0
	if buttons.size() > 1:
		var first_press := await _wait_for_action(buttons)
		chosen = first_press
	elif buttons.size() == 1:
		await buttons[0].pressed
	for button: Button in buttons:
		button.disabled = true
	var gauge_before := int(GameState.current_boss.get("gauge", 0))
	var outcome := BossSystemScript.resolve_interaction(GameState.current_boss, definition, chosen, pair_bonus)
	if double_bonus > 0:
		outcome.individual["gauge"] = clampi(int(outcome.individual.get("gauge", 0)) + double_bonus, 0, 100)
		outcome.individual["stage"] = BossSystemScript.stage_for_gauge(int(outcome.individual.gauge))
		outcome.gain = int(outcome.gain) + double_bonus
		outcome.joined_now = int(outcome.individual.gauge) >= 100 and not bool(GameState.current_boss.get("got", false))
	var event_bonus := GameState.next_interaction_bonus
	if event_bonus > 0:
		outcome.individual["gauge"] = clampi(int(outcome.individual.get("gauge", 0)) + event_bonus, 0, 100)
		outcome.individual["stage"] = BossSystemScript.stage_for_gauge(int(outcome.individual.gauge))
		outcome.gain = int(outcome.gain) + event_bonus
		outcome.joined_now = int(outcome.individual.gauge) >= 100 and not bool(GameState.current_boss.get("got", false))
		GameState.next_interaction_bonus = 0
	GameState.current_boss = outcome.individual
	GameState.boss_bond = float(GameState.current_boss.get("gauge", 0))
	GameState.boss_presence = maxi(0, GameState.boss_presence - 2)
	GameState.boss_relief = 0
	if not GameState.roll_transaction.is_empty():
		GameState.commit_roll_encounter_interaction(bool(outcome.joined_now), str(definition.get("id", "sleepy_sphinx")))
	SaveManager.save_now()
	var gauge_after := int(GameState.current_boss.get("gauge", 0))
	var filling_gauge := _body("交流 %d%%" % gauge_before, 21)
	filling_gauge.add_theme_color_override("font_color", TEAL)
	content.add_child(filling_gauge)
	# The last few percent are deliberately visible: becoming companions should feel gradual.
	for shown in range(gauge_before + 1, gauge_after + 1):
		filling_gauge.text = "交流 %d%%" % shown
		await get_tree().create_timer(0.025 if gauge_after >= 100 else 0.012).timeout
	var response := _body("%s\n交流 +%d　合計 %d%%" % [BossSystemScript.line_for(GameState.current_boss, definition, int(GameState.current_boss.get("encounters", 0))), int(outcome.gain), gauge_after], 22)
	response.add_theme_color_override("font_color", INK)
	content.add_child(response)
	var back := _button("旅へ戻る", func() -> void: return, true)
	back.name = "return_to_trip"
	back.toggle_mode = true
	content.add_child(back)
	await back.pressed
	_close_modal(modal.layer)
	_refresh_hud()
	if bool(outcome.joined_now):
		await _show_get_result(definition)
	if not GameState.roll_transaction.is_empty():
		GameState.complete_roll_encounter()
		SaveManager.save_now()

func _play_encounter_chime() -> void:
	# A short, low-volume two-tone cue. There is no BGM track in this slice, so the
	# encounter remains sonically quiet instead of replacing the ambience.
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var samples := PackedByteArray()
	var sample_count := int(stream.mix_rate * 0.18)
	for index: int in range(sample_count):
		var time := float(index) / float(stream.mix_rate)
		var frequency := 440.0 if time < 0.09 else 523.25
		var envelope := 1.0 - float(index) / float(sample_count)
		var value := 128 + roundi(sin(TAU * frequency * time) * 17.0 * envelope)
		samples.append(clampi(value, 0, 255))
	stream.data = samples
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -18.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _wait_for_action(buttons: Array[Button]) -> int:
	while true:
		for index: int in range(buttons.size()):
			if buttons[index].button_pressed:
				return index
		await get_tree().process_frame
	return 0

func _show_get_result(definition: Dictionary, restored_obtained: Dictionary = {}) -> String:
	# The portrait changes warmth very slightly; the feeling is an invitation, never a battle win.
	var obtained := restored_obtained.duplicate(true) if not restored_obtained.is_empty() else _prepare_next_boss_after_join()
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	var portrait := TextureRect.new()
	portrait.texture = SPHINX_TEXTURE
	portrait.modulate = Color(1.0, 0.96, 0.80)
	portrait.custom_minimum_size = Vector2(0, 170)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(portrait)
	content.add_child(_title("旅の図鑑に加わった", 36))
	content.add_child(_body("%s\n%s" % [str(obtained.get("name", "スフィンクス")), str(definition.get("lines", {}).get("joined", "旅の仲間になった。"))], 23))
	content.add_child(_body("図鑑 No.%d　%s" % [int(obtained.get("registration_order", GameState.encyclopedia.size())), str(obtained.get("memo", ""))], 18))
	content.add_child(_body("次の気配：%s" % str(GameState.current_boss.get("name", "？？？")), 18))
	var next_trip := _button("次の旅へ", func() -> void: return, true)
	var stage_select := _button("ステージ選択へ戻る", func() -> void: return)
	next_trip.toggle_mode = true
	stage_select.toggle_mode = true
	next_trip.name = "next_trip"
	stage_select.name = "stage_select"
	content.add_child(next_trip)
	content.add_child(stage_select)
	while true:
		if next_trip.button_pressed:
			_close_modal(modal.layer)
			GameState.reset_run()
			SaveManager.save_now()
			show_game()
			return "NEXT_TRIP"
		if stage_select.button_pressed:
			_close_modal(modal.layer)
			SaveManager.save_now()
			show_stage_select()
			return "STAGE_SELECT"
		await get_tree().process_frame
	return ""

func _prepare_next_boss_after_join() -> Dictionary:
	GameState.register_current_boss()
	var obtained := GameState.current_boss.duplicate(true)
	# Advance and persist before offering either exit. Returning to stage select must never revive
	# an already registered individual on the next Cairo trip.
	GameState.begin_next_boss()
	if not GameState.roll_transaction.is_empty():
		GameState.commit_roll_encounter_registration(obtained)
	SaveManager.save_now()
	return obtained

func show_encyclopedia() -> void:
	var page := _make_page()
	page.add_child(_title("スフィンクス図鑑", 44))
	page.add_child(_body("旅の途中で、少しずつ知り合った相手たち。", 20))
	var definitions := boss_definitions if not boss_definitions.is_empty() else BossSystemScript.definitions()
	var registered_definitions: Dictionary = {}
	# Every joined individual is its own card, including later individuals sharing a definition.
	for found: Dictionary in GameState.encyclopedia:
		registered_definitions[str(found.get("definition_id", ""))] = true
		var found_card := VBoxContainer.new()
		found_card.add_theme_constant_override("separation", 4)
		found_card.add_child(_body("%s　%s\n出会い %d回　図鑑 No.%d\n%s" % [str(found.get("name", "")), str(found.get("personality", "")), int(found.get("encounters", 0)), int(found.get("registration_order", 0)), str(found.get("memo", ""))], 21))
		page.add_child(found_card)
	# Definitions never joined yet remain discoverable as silhouettes.
	for definition: Dictionary in definitions:
		if registered_definitions.has(str(definition.get("id", ""))):
			continue
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 4)
		var silhouette := TextureRect.new()
		silhouette.texture = SPHINX_TEXTURE
		silhouette.custom_minimum_size = Vector2(0, 90)
		silhouette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		silhouette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		silhouette.modulate = Color(0.18, 0.14, 0.10, 0.88)
		card.add_child(silhouette)
		card.add_child(_body("？？？　未登録\n砂の向こうに、まだ知らない気配がある。", 21))
		page.add_child(card)
	page.add_child(_spacer(10))
	page.add_child(_button("もどる", show_title))

func _build_debug_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	var row := HBoxContainer.new()
	for entry: Dictionary in [
		{"name": "PAIR", "roll": [3, 3, 5]},
		{"name": "STRAIGHT", "roll": [2, 3, 4]},
		{"name": "TRIPLE", "roll": [6, 6, 6]},
		{"name": "ALL ODD", "roll": [1, 3, 5]},
		{"name": "ALL EVEN", "roll": [2, 4, 6]}
	]:
		var button := _button(entry.name, func() -> void:
			GameState.fixed_rolls.assign(entry.roll)
			_set_mode(3))
		button.custom_minimum_size.y = 42
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	box.add_child(row)
	var boss_debug := HBoxContainer.new()
	for entry: Dictionary in [
		{"name": "次で遭遇", "action": func() -> void: GameState.debug_force_encounter = true},
		{"name": "気配MAX", "action": func() -> void: GameState.boss_presence = 5},
		{"name": "交流99%", "action": func() -> void: _debug_set_boss_gauge(99)},
		{"name": "個体切替", "action": func() -> void: _debug_next_boss()},
		{"name": "図鑑リセット", "action": func() -> void: _debug_reset_encyclopedia()}
	]:
		var button := _button(entry.name, entry.action)
		button.custom_minimum_size.y = 42
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boss_debug.add_child(button)
	box.add_child(boss_debug)
	var gauge_debug := HBoxContainer.new()
	var gauge_input := LineEdit.new()
	gauge_input.placeholder_text = "交流ゲージ 0〜100"
	gauge_input.custom_minimum_size = Vector2(210, 42)
	gauge_input.max_length = 3
	var gauge_apply := _button("交流を設定", func() -> void:
		_debug_set_boss_gauge(clampi(gauge_input.text.to_int(), 0, 100)))
	gauge_apply.custom_minimum_size = Vector2(180, 42)
	gauge_debug.add_child(gauge_input)
	gauge_debug.add_child(gauge_apply)
	box.add_child(gauge_debug)
	var event_debug := HBoxContainer.new()
	var event_id_input := LineEdit.new()
	event_id_input.placeholder_text = "CAI-E01"
	event_id_input.custom_minimum_size = Vector2(150, 42)
	var force_event := _button("イベント指定", func() -> void: GameState.debug_forced_event_id = event_id_input.text.strip_edges().to_upper())
	var force_rare := _button("E30強制", func() -> void: GameState.debug_forced_event_id = "CAI-E30")
	var clear_history := _button("履歴初期化", func() -> void:
		GameState.event_history.clear(); GameState.seen_event_ids.clear(); GameState.recent_event_ids.clear(); GameState.events_seen_this_loop.clear())
	for control: Control in [event_id_input, force_event, force_rare, clear_history]:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL; event_debug.add_child(control)
	box.add_child(event_debug)
	var event_debug_2 := HBoxContainer.new()
	var extra_input := LineEdit.new(); extra_input.placeholder_text = "追加目 6,6,6"; extra_input.custom_minimum_size = Vector2(180, 42)
	var extra_apply := _button("追加目固定", func() -> void:
		GameState.debug_fixed_extra_rolls.clear()
		for part: String in extra_input.text.split(","): GameState.debug_fixed_extra_rolls.append(clampi(part.strip_edges().to_int(), 1, 6)))
	var rare_unlock := _button("E30制限解除", func() -> void: GameState.rare_event_used_this_loop = false; GameState.events_since_rare = 99)
	var boss_toggle := _button("ボス接続ON/OFF", func() -> void: GameState.debug_boss_handoff_enabled = not GameState.debug_boss_handoff_enabled)
	for control: Control in [extra_input, extra_apply, rare_unlock, boss_toggle]: control.size_flags_horizontal = Control.SIZE_EXPAND_FILL; event_debug_2.add_child(control)
	box.add_child(event_debug_2)
	var audio_debug := HBoxContainer.new()
	for entry: Dictionary in [
		{"name": "Launch SE", "category": "launch"}, {"name": "Roll SE", "category": "roll"},
		{"name": "Contact SE", "category": "contact"}, {"name": "Land SE", "category": "land"},
		{"name": "Lock SE", "category": "lock"}
	]:
		var audio_button := _button(entry.name, func() -> void: _debug_play_dice_audio(entry.category))
		audio_button.custom_minimum_size.y = 42; audio_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; audio_debug.add_child(audio_button)
	box.add_child(audio_debug)
	var fatigue_debug := HBoxContainer.new()
	for count: int in [1, 3, 5]:
		var fatigue_button := _button("%d Dice ×20" % count, func() -> void: _debug_audio_twenty(count))
		fatigue_button.custom_minimum_size.y = 42; fatigue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; fatigue_debug.add_child(fatigue_button)
	var mute_dice := _button("Mute Dice SE", _debug_toggle_dice_audio)
	mute_dice.custom_minimum_size.y = 42; mute_dice.size_flags_horizontal = Control.SIZE_EXPAND_FILL; fatigue_debug.add_child(mute_dice)
	var voices := _button("Active Voices", func() -> void:
		if is_instance_valid(dice_audio): _show_message("Dice Audio", "Active voices: %d / Pool: %d" % [dice_audio.active_voice_count(), int(dice_audio.receipt().pool_size)]))
	voices.custom_minimum_size.y = 42; voices.size_flags_horizontal = Control.SIZE_EXPAND_FILL; fatigue_debug.add_child(voices)
	box.add_child(fatigue_debug)
	var view_row := HBoxContainer.new()
	var classic_view := _button("BOARD CLASSIC", func() -> void: _debug_set_board_view_mode("classic"))
	var tourism_view := _button("BOARD TOURISM", func() -> void: _debug_set_board_view_mode("tourism"))
	for control: Control in [classic_view, tourism_view]:
		control.custom_minimum_size.y = 42
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		view_row.add_child(control)
	box.add_child(view_row)
	var route_row := HBoxContainer.new()
	for entry: Dictionary in [
		{"name": "MAIN 90", "route": BoardModelScript.ROUTE_MAIN, "tile": 89},
		{"name": "BYPASS IN", "route": BoardModelScript.ROUTE_BYPASS_CARAVAN, "tile": 0},
		{"name": "BYPASS OUT", "route": BoardModelScript.ROUTE_BYPASS_CARAVAN, "tile": 9},
		{"name": "MAZE", "route": BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, "tile": 4},
	]:
		var route_button := _button(entry.name, func() -> void: _debug_set_route(str(entry.route), int(entry.tile)))
		route_button.custom_minimum_size.y = 42; route_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; route_row.add_child(route_button)
	box.add_child(route_row)
	var secret_row := HBoxContainer.new()
	for entry: Dictionary in [
		{"name": "SECRET NONE", "mode": "none"},
		{"name": "SECRET HERE", "mode": "current"},
		{"name": "SECRET ALL", "mode": "all"},
	]:
		var secret_button := _button(entry.name, func() -> void: _debug_set_bypass_reveals(str(entry.mode)))
		secret_button.custom_minimum_size.y = 42; secret_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; secret_row.add_child(secret_button)
	box.add_child(secret_row)
	var route_resume_row := HBoxContainer.new()
	var interrupt_route := _button("ROUTE中断保存", _debug_create_route_interruption)
	var resume_route := _button("ROUTE復帰実行", func() -> void: call_deferred("_resume_roll_transaction"))
	for control: Control in [interrupt_route, resume_route]:
		control.custom_minimum_size.y = 42; control.size_flags_horizontal = Control.SIZE_EXPAND_FILL; route_resume_row.add_child(control)
	box.add_child(route_resume_row)
	return box

func _new_board_view(mode: String) -> BoardView:
	var normalized := TourismMapViewScript.normalized_view_mode(mode)
	if normalized == TourismMapViewScript.VIEW_MODE_TOURISM:
		return TourismMapViewScript.new() as BoardView
	return BoardViewScript.new() as BoardView

func _preferred_board_view_mode() -> String:
	var debug_override := OS.get_environment("DICE_BOARD_VIEW").strip_edges().to_lower()
	if debug_override in [TourismMapViewScript.VIEW_MODE_CLASSIC, TourismMapViewScript.VIEW_MODE_TOURISM]:
		return debug_override
	return GameState.normalized_board_view_mode(GameState.board_view_mode)

func _can_switch_board_view() -> bool:
	return is_instance_valid(board_view) and not moving and not rolling_dice and not modal_open and event_state == &"IDLE"

func _set_board_view_mode(mode: String) -> bool:
	if not _can_switch_board_view():
		return false
	var normalized := TourismMapViewScript.normalized_view_mode(mode)
	var wants_tourism := normalized == TourismMapViewScript.VIEW_MODE_TOURISM
	if (wants_tourism and board_view is TourismMapView) or (not wants_tourism and not (board_view is TourismMapView)):
		board_view_mode = normalized
		GameState.board_view_mode = normalized
		return true
	var parent := board_view.get_parent()
	if parent == null:
		return false
	var child_index := board_view.get_index()
	var previous := board_view
	var replacement := _new_board_view(normalized)
	replacement.custom_minimum_size = previous.custom_minimum_size
	replacement.size_flags_horizontal = previous.size_flags_horizontal
	replacement.size_flags_vertical = previous.size_flags_vertical
	replacement.configure(tile_types, GameState.current_tile_index, GameState.landmark_levels)
	if replacement is TourismMapView:
		(replacement as TourismMapView).set_dice_count(GameState.current_dice_count)
		(replacement as TourismMapView).set_flow_visual_level(GameState.flow_level)
	parent.add_child(replacement)
	parent.move_child(replacement, child_index)
	parent.remove_child(previous)
	previous.queue_free()
	board_view = replacement
	_sync_board_route_context()
	board_view_mode = normalized
	GameState.board_view_mode = normalized
	return true

func _sync_board_route_context() -> void:
	var definition := BoardModelScript.route_definition(GameState.current_route_id)
	for route_view: BoardView in [board_view, minimap_view]:
		if not is_instance_valid(route_view):
			continue
		route_view.set_route_context(GameState.current_route_id, int(definition.tile_count), definition.get("tiles", []))
		route_view.set_route_flow_level(GameState.flow_level)
		route_view.set_bypass_revealed_tiles(GameState.bypass_revealed_tiles)
		route_view.set_current_tile(GameState.current_tile_index)

func _debug_set_board_view_mode(mode: String) -> void:
	if _set_board_view_mode(mode):
		SaveManager.save_now()

func _debug_set_route(route_id: String, tile_index: int) -> void:
	GameState.clear_roll_transaction()
	GameState.set_route_position(route_id, tile_index)
	SaveManager.save_now()
	show_game()

func _debug_set_bypass_reveals(mode: String) -> void:
	match mode:
		"all": GameState.bypass_revealed_tiles.assign(range(1, BoardModelScript.route_tile_count(BoardModelScript.ROUTE_BYPASS_CARAVAN) - 1))
		"current":
			if GameState.current_route_id == BoardModelScript.ROUTE_BYPASS_CARAVAN and GameState.current_tile_index > 0 and GameState.current_tile_index < BoardModelScript.route_tile_count(BoardModelScript.ROUTE_BYPASS_CARAVAN) - 1 and GameState.current_tile_index not in GameState.bypass_revealed_tiles:
				GameState.bypass_revealed_tiles.append(GameState.current_tile_index)
				GameState.bypass_revealed_tiles.sort()
		_: GameState.bypass_revealed_tiles.clear()
	_sync_board_route_context()
	SaveManager.save_now()

func _debug_create_route_interruption() -> void:
	if not GameState.roll_transaction.is_empty():
		return
	var distance := 4
	var route_move := BoardModelScript.advance_route(GameState.current_route_id, GameState.current_tile_index, distance)
	GameState.begin_roll_transaction([], 1, GameState.current_tile_index)
	GameState.commit_roll_result([4], 1, DiceLogicScript.evaluate_current([4], 1), distance, int(route_move.tile_index), int(route_move.laps), false, str(route_move.route_id), route_move.path, int(route_move.maze_loops))
	SaveManager.save_now()
	_show_message("ROUTE-01", "RESULT_COMMITTEDを保存しました。再起動または『ROUTE復帰実行』で同じ移動を再開できます。")

func _qa_route_01() -> void:
	var backup := GameState.to_dictionary()
	var checks: Array[bool] = []
	# Simulate a process restart from a committed bypass movement. The first
	# step rejoins main at 58 and the remaining step must still reach 59.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 9); show_game()
	var bypass_move := BoardModelScript.advance_route(GameState.current_route_id, GameState.current_tile_index, 2)
	GameState.begin_roll_transaction([], 1, GameState.current_tile_index)
	GameState.commit_roll_result([2], 1, DiceLogicScript.evaluate_current([2], 1), 2, int(bypass_move.tile_index), int(bypass_move.laps), false, str(bypass_move.route_id), bypass_move.path, int(bypass_move.maze_loops))
	GameState.apply_dictionary(GameState.to_dictionary())
	await _continue_roll_transaction()
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == 59 and GameState.rolls_used == 1 and GameState.roll_transaction.is_empty())
	# A ten-step interrupted maze move crosses its gate twice, but creates no
	# main lap and never exits the closed topology.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 6); show_game()
	var maze_move := BoardModelScript.advance_route(GameState.current_route_id, GameState.current_tile_index, 10)
	GameState.begin_roll_transaction([], 2, GameState.current_tile_index)
	GameState.commit_roll_result([4, 6], 2, DiceLogicScript.evaluate_current([4, 6], 2), 10, int(maze_move.tile_index), int(maze_move.laps), false, str(maze_move.route_id), maze_move.path, int(maze_move.maze_loops))
	GameState.apply_dictionary(GameState.to_dictionary())
	await _continue_roll_transaction()
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and GameState.current_tile_index == 0 and GameState.maze_loop_count == 2 and GameState.lap_count == 0 and GameState.roll_transaction.is_empty())
	var boundary := BoardModelScript.advance_route(BoardModelScript.ROUTE_MAIN, 89, 2)
	checks.append(str(boundary.route_id) == BoardModelScript.ROUTE_MAIN and int(boundary.tile_index) == 1 and int(boundary.laps) == 1)
	checks.append(_set_board_view_mode("classic") and _set_board_view_mode("tourism"))
	GameState.apply_dictionary(backup); SaveManager.save_now()
	print("QA_ROUTE_01 bypass_resume=%s maze_resume=%s main_boundary=%s views=%s passed=%s" % [checks[0], checks[1], checks[2], checks[3], checks.all(func(value: bool) -> bool: return value)])

func _qa_press_toggle(button_name: String) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while find_children(button_name, "Button", true, false).is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var buttons := find_children(button_name, "Button", true, false)
	if not buttons.is_empty():
		(buttons[0] as Button).button_pressed = true

func _qa_route_02() -> void:
	var backup := GameState.to_dictionary().duplicate(true)
	var checks: Array[bool] = []
	# Interrupt at the fork with three steps left, then choose the bypass. Tile
	# four is a back-three hazard, so the effective harm should land at tile one.
	GameState.reset_run(); GameState.bypass_use_count = 0; GameState.bypass_no_damage_count = 0; GameState.bypass_best_roll_count = 0; GameState.bypass_clean_losses = 0; GameState.set_route_position(BoardModelScript.ROUTE_MAIN, 30); GameState.current_dice_count = 1; show_game()
	call_deferred("_qa_press_toggle", "route_choice_bypass")
	await _resolve_roll([5])
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_BYPASS_CARAVAN and GameState.current_tile_index == 0 and GameState.rolls_used == 1 and GameState.bypass_use_count == 1 and not GameState.current_lap_clean and GameState.bypass_clean_losses == 1 and GameState.roll_transaction.is_empty())
	# Exact-stop selection commits the next route without consuming another
	# step or firing bypass tile zero's hazard.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_MAIN, 31); GameState.coins = 12; show_game()
	call_deferred("_qa_press_toggle", "route_choice_bypass")
	await _resolve_roll([1])
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_BYPASS_CARAVAN and GameState.current_tile_index == 0 and GameState.coins == 12 and GameState.current_lap_clean and GameState.rolls_used == 1)
	# A saved result at the end of the bypass rejoins main and keeps all
	# remaining movement without creating a lap.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 8); GameState.bypass_entry_committed = true; GameState.bypass_rolls_this_visit = 1; show_game()
	var exit_move := BoardModelScript.advance_route(GameState.current_route_id, GameState.current_tile_index, 4)
	GameState.begin_roll_transaction([], 1, GameState.current_tile_index)
	GameState.commit_roll_result([4], 1, DiceLogicScript.evaluate_current([4], 1), 4, int(exit_move.tile_index), int(exit_move.laps), false, str(exit_move.route_id), exit_move.path, int(exit_move.maze_loops))
	GameState.apply_dictionary(GameState.to_dictionary())
	await _continue_roll_transaction()
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == 60 and GameState.lap_count == 0 and GameState.bypass_exit_committed and GameState.bypass_no_damage_count == 1)
	# Guards are consumed only by real harm. A zero-coin no-op keeps both CLEAN
	# and the guard; a real loss consumes the guard but still keeps CLEAN.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0); GameState.coins = 0; GameState.even_guard_active = true; show_game()
	var noop_memo := _apply_bypass_hazard(false)
	var noop_ok := GameState.current_lap_clean and GameState.even_guard_active and noop_memo.contains("影響なし")
	GameState.coins = 20
	var guard_memo := _apply_bypass_hazard(false)
	checks.append(noop_ok and GameState.coins == 20 and GameState.current_lap_clean and not GameState.even_guard_active and guard_memo.contains("完全防御"))
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 4); GameState.coins = 12; GameState.debug_fixed_extra_rolls.assign([2, 2, 5]); show_game()
	call_deferred("_qa_press_toggle", "bypass_gamble_dash")
	var gamble_memo := await _show_bypass_gamble()
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_BYPASS_CARAVAN and GameState.current_tile_index == 7 and GameState.coins == 18 and gamble_memo.begins_with("PAIR"))
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 2); GameState.current_dice_count = 3; GameState.dice_keep_active = true; show_game()
	var strong_memo := _apply_bypass_hazard(true)
	checks.append(GameState.current_dice_count == 1 and not GameState.dice_keep_active and not GameState.current_lap_clean and GameState.flow_level == 0 and strong_memo.contains("荷崩れ"))
	var passed := checks.all(func(value: bool) -> bool: return value)
	print("QA_ROUTE_02 branch=%s exact_stop=%s exit=%s clean_guard=%s gamble=%s strong=%s passed=%s" % [checks[0], checks[1], checks[2], checks[3], checks[4], checks[5], passed])
	GameState.apply_dictionary(backup); SaveManager.save_now()
	get_tree().quit(0 if passed else 1)

func _qa_route_03() -> void:
	var backup := GameState.to_dictionary().duplicate(true)
	var checks: Array[bool] = []
	var definition := BoardModelScript.route_definition(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE)

	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_MAIN, BoardModelScript.ROYAL_MAZE_SOURCE_TILE)
	var entered := GameState.commit_royal_maze_entry(BoardModelScript.ROUTE_MAIN, int(definition.return_tile))
	checks.append(entered and GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and GameState.current_tile_index == 4 and GameState.loop_return_tile_index == 26)

	var pass_gate := BoardModelScript.advance_route(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 7, 2)
	var ten_loops := BoardModelScript.advance_route(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 4, 80)
	checks.append(str(pass_gate.route_id) == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and int(pass_gate.tile_index) == 1 and int(pass_gate.maze_loops) == 1)
	checks.append(str(ten_loops.route_id) == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and int(ten_loops.tile_index) == 4 and int(ten_loops.maze_loops) == 10)

	GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 7)
	checks.append(not GameState.commit_royal_maze_exit())
	GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 0)
	var exited := GameState.commit_royal_maze_exit()
	checks.append(exited and not GameState.commit_royal_maze_exit() and GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == 26)

	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_MAIN, BoardModelScript.ROYAL_MAZE_SOURCE_TILE); GameState.commit_royal_maze_entry(BoardModelScript.ROUTE_MAIN, 26); GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 7); show_game()
	var exact_move := BoardModelScript.advance_route(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 7, 1)
	GameState.begin_roll_transaction([], 1, 7)
	GameState.commit_roll_result([1], 1, DiceLogicScript.evaluate_current([1], 1), 1, int(exact_move.tile_index), 0, false, BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, exact_move.path, int(exact_move.maze_loops))
	await _continue_roll_transaction()
	checks.append(GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == 26 and GameState.roll_transaction.is_empty() and GameState.rolls_used == 1)

	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_MAIN, BoardModelScript.ROYAL_MAZE_SOURCE_TILE); GameState.commit_royal_maze_entry(BoardModelScript.ROUTE_MAIN, 26)
	var first_treasure := _claim_maze_treasure()
	var second_treasure := _claim_maze_treasure()
	var first_mural := _claim_maze_mural()
	var bonus_before_repeat := GameState.current_lap_bonus
	var repeat_mural := _claim_maze_mural()
	checks.append(not first_treasure.contains("空") and second_treasure.contains("空") and first_mural.contains("新しい") and repeat_mural.contains("+10") and GameState.current_lap_bonus == bonus_before_repeat + 10)

	GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 5); GameState.current_lap_clean = true
	var strong_memo := _apply_maze_hazard(true)
	var strong_back_ok := GameState.current_tile_index == 2 and not GameState.current_lap_clean
	GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 1); GameState.current_lap_clean = true; GameState.even_guard_active = true; GameState.next_move_bonus = 0
	var guard_memo := _apply_maze_hazard(false)
	checks.append(strong_back_ok and GameState.current_tile_index == 1 and not GameState.even_guard_active and GameState.current_lap_clean and strong_memo.contains("逆さ砂時計") and guard_memo.contains("完全防御"))

	GameState.set_route_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 6); GameState.maze_loop_count = 12; GameState.maze_treasure_claimed = true
	var saved := SaveManager.save_now()
	GameState.set_route_position(BoardModelScript.ROUTE_MAIN, 0); GameState.maze_loop_count = 0; GameState.maze_treasure_claimed = false
	var restored := SaveManager.load_now()
	checks.append(saved and restored and GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and GameState.current_tile_index == 6 and GameState.maze_loop_count == 12 and GameState.maze_treasure_claimed)

	GameState.board_view_mode = "tourism"
	show_game()
	var tourism_ok := board_view is TourismMapView and _set_board_view_mode("classic") and board_view is BoardView and not (board_view is TourismMapView)
	var classic_ok := _set_board_view_mode("tourism") and board_view is TourismMapView
	checks.append(tourism_ok and classic_ok)

	var passed := checks.all(func(value: bool) -> bool: return value)
	print("QA_ROUTE_03 entry=%s pass_gate=%s ten_loops=%s non_gate=%s exact_exit=%s transaction_exit=%s rewards=%s hazards=%s save=%s views=%s passed=%s" % [checks[0], checks[1], checks[2], checks[3], checks[4], checks[5], checks[6], checks[7], checks[8], checks[9], passed])
	GameState.apply_dictionary(backup); SaveManager.save_now()
	get_tree().quit(0 if passed else 1)

func _qa_popup_book() -> void:
	var backup := GameState.to_dictionary().duplicate(true)
	var checks: Array[bool] = []
	GameState.reset_run()
	GameState.set_route_position(BoardModelScript.ROUTE_MAIN, BoardModelScript.ROYAL_MAZE_SOURCE_TILE)
	var definition := BoardModelScript.route_definition(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE)
	var entered := GameState.commit_royal_maze_entry(BoardModelScript.ROUTE_MAIN, int(definition.return_tile))
	SaveManager.save_now()
	show_game()
	checks.append(entered and GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and GameState.current_tile_index == int(definition.entry_tile))

	# Start without awaiting so QA can exercise the same tap-to-skip path as the
	# production overlay while the durable route state remains unchanged.
	_play_royal_maze_entry_transition()
	await get_tree().process_frame
	var transition := find_child("RoyalMazePopupBookTransition", true, false)
	checks.append(modal_open and is_instance_valid(transition))
	if is_instance_valid(transition):
		transition.request_skip()
	while modal_open:
		await get_tree().process_frame
	await get_tree().process_frame
	var skipped_final_state := {
		"route_id": GameState.current_route_id,
		"tile_index": GameState.current_tile_index,
		"overlay_removed": find_child("RoyalMazePopupBookTransition", true, false) == null,
		"input_unlocked": not modal_open,
	}
	checks.append(skipped_final_state.overlay_removed and skipped_final_state.input_unlocked)
	var completed_receipt := await _play_royal_maze_entry_transition(0.04)
	await get_tree().process_frame
	var completed_final_state := {
		"route_id": GameState.current_route_id,
		"tile_index": GameState.current_tile_index,
		"overlay_removed": find_child("RoyalMazePopupBookTransition", true, false) == null,
		"input_unlocked": not modal_open,
	}
	checks.append(bool(completed_receipt.get("completed", false)) and not bool(completed_receipt.get("skipped", true)) and completed_final_state == skipped_final_state)

	# Resume policy: a saved maze state opens the normal maze screen directly;
	# a presentation phase is intentionally not part of the save schema.
	var restored := SaveManager.load_now()
	show_game()
	checks.append(restored and GameState.current_route_id == BoardModelScript.ROUTE_LOOP_ROYAL_MAZE and find_child("RoyalMazePopupBookTransition", true, false) == null and not modal_open)
	var passed := checks.all(func(value: bool) -> bool: return value)
	print("QA_POPUP_BOOK durable=%s overlay=%s skip=%s complete_match=%s resume=%s passed=%s" % [checks[0], checks[1], checks[2], checks[3], checks[4], passed])
	GameState.apply_dictionary(backup); SaveManager.save_now()
	get_tree().quit(0 if passed else 1)

func _qa_popup_book_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.set_route_position(BoardModelScript.ROUTE_MAIN, BoardModelScript.ROYAL_MAZE_SOURCE_TILE)
	GameState.commit_royal_maze_entry(BoardModelScript.ROUTE_MAIN, int(BoardModelScript.route_definition(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE).return_tile))
	show_game()
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var transition := PopupBookTransitionScript.new()
	layer.add_child(transition)
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var preview_progress: float = float({"opening": 0.28, "rising": 0.62, "complete": 1.0}.get(kind, 0.62))
	transition.set_preview_progress(preview_progress)
	for ignored: int in range(10):
		await get_tree().process_frame
	var result := _save_opaque_capture(path)
	var image := Image.load_from_file(path)
	var correct_size := image != null and image.get_size() == Vector2i(360, 640)
	print("QA_POPUP_BOOK_CAPTURE kind=%s progress=%.2f size=%s path=%s result=%s" % [kind, preview_progress, correct_size, path, result])
	get_tree().quit(0 if result == OK and correct_size else 1)

func _qa_caravan_secret() -> void:
	var backup := GameState.to_dictionary().duplicate(true)
	var checks: Array[bool] = []
	GameState.reset_run()
	checks.append(GameState.bypass_revealed_tiles.is_empty() and GameState.is_bypass_tile_revealed(0) and GameState.is_bypass_tile_revealed(9) and not GameState.is_bypass_tile_revealed(1))
	checks.append(BoardViewScript.bypass_display_type(1, 10, &"RISK", []) == &"SECRET" and BoardViewScript.bypass_display_type(1, 10, &"STRONG_RISK", []) == &"SECRET" and BoardViewScript.bypass_display_type(7, 10, &"COIN", []) == &"SECRET")

	# Three traversed spaces stay hidden; only the final stop is revealed before
	# tile three's back-three hazard resolves.
	GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0); show_game()
	var pass_move := BoardModelScript.advance_route(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0, 3)
	GameState.begin_roll_transaction([], 3, 0)
	GameState.commit_roll_result([1, 1, 1], 3, {}, 3, int(pass_move.tile_index), 0, false, str(pass_move.route_id), pass_move.path, 0)
	await _continue_roll_transaction()
	checks.append(GameState.bypass_revealed_tiles == [3] and not GameState.is_bypass_tile_revealed(1) and not GameState.is_bypass_tile_revealed(2) and GameState.current_tile_index == 0 and GameState.current_lap_penalty_count == 1)
	var persisted := SaveManager.save_now(); GameState.bypass_revealed_tiles.clear(); var restored := SaveManager.load_now()
	checks.append(persisted and restored and GameState.bypass_revealed_tiles == [3])
	GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0)
	checks.append(GameState.bypass_revealed_tiles == [3])

	# Simulate termination after reveal persistence but before the hazard. Resume
	# must apply one penalty and never reveal a passed tile.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0); GameState.next_move_bonus = 0
	var interrupted_move := BoardModelScript.advance_route(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0, 1)
	GameState.begin_roll_transaction([], 1, 0)
	GameState.commit_roll_result([1], 1, DiceLogicScript.evaluate_current([1], 1), 1, 1, 0, false, BoardModelScript.ROUTE_BYPASS_CARAVAN, interrupted_move.path, 0)
	GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 1); GameState.commit_roll_movement(1, BoardModelScript.ROUTE_BYPASS_CARAVAN)
	var interrupted_reveal := GameState.commit_bypass_tile_reveal(1); SaveManager.save_now(); GameState.apply_dictionary(GameState.to_dictionary()); show_game()
	await _resume_roll_transaction()
	checks.append(interrupted_reveal.newly_revealed and GameState.bypass_revealed_tiles == [1] and GameState.next_move_bonus == -2 and GameState.current_lap_penalty_count == 1 and GameState.roll_transaction.is_empty())

	# Coin landing is revealed and awarded once. Reloading the resolved turn does
	# not add another coin receipt.
	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 6); GameState.coins = 12; show_game()
	var coin_move := BoardModelScript.advance_route(BoardModelScript.ROUTE_BYPASS_CARAVAN, 6, 1)
	GameState.begin_roll_transaction([], 1, 6)
	GameState.commit_roll_result([1], 1, DiceLogicScript.evaluate_current([1], 1), 1, 7, 0, false, BoardModelScript.ROUTE_BYPASS_CARAVAN, coin_move.path, 0)
	await _continue_roll_transaction()
	var coin_saved := SaveManager.save_now(); var coins_after := GameState.coins; SaveManager.load_now()
	checks.append(coin_saved and GameState.bypass_revealed_tiles == [7] and coins_after == 18 and GameState.coins == 18)

	var dice_paths_ok := true
	for dice_count: int in [1, 2, 3, 5]:
		var distance := dice_count
		var move := BoardModelScript.advance_route(BoardModelScript.ROUTE_BYPASS_CARAVAN, 0, distance)
		dice_paths_ok = dice_paths_ok and (move.path as Array).size() == distance and int(move.tile_index) == distance
	checks.append(dice_paths_ok)

	GameState.reset_run(); GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 4); show_game()
	var views_ok := _set_board_view_mode("classic") and _set_board_view_mode("tourism")
	checks.append(views_ok and BoardModelScript.tile_type_for_position(BoardModelScript.ROUTE_LOOP_ROYAL_MAZE, 2) == &"TREASURE")
	var exit_move := BoardModelScript.advance_route(BoardModelScript.ROUTE_BYPASS_CARAVAN, 8, 2)
	checks.append(str(exit_move.route_id) == BoardModelScript.ROUTE_MAIN and int(exit_move.tile_index) == 58)

	var passed := checks.all(func(value: bool) -> bool: return value)
	print("QA_CARAVAN_SECRET new=%s hidden=%s stop_only=%s save=%s reentry=%s interrupt=%s coin=%s dice=%s views_maze=%s exit=%s passed=%s" % [checks[0], checks[1], checks[2], checks[3], checks[4], checks[5], checks[6], checks[7], checks[8], checks[9], passed])
	GameState.apply_dictionary(backup); SaveManager.save_now()
	get_tree().quit(0 if passed else 1)

func _qa_caravan_secret_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.board_view_mode = "tourism"
	GameState.set_route_position(BoardModelScript.ROUTE_BYPASS_CARAVAN, 4 if kind == "revealed" else 3)
	if kind == "revealing":
		GameState.bypass_revealed_tiles.assign([3])
	elif kind == "revealed":
		GameState.bypass_revealed_tiles.assign([3, 4])
	show_game()
	if kind == "revealing" and is_instance_valid(board_view):
		board_view.set_bypass_reveal_progress(3, 0.48)
	for ignored: int in range(12): await get_tree().process_frame
	await get_tree().create_timer(0.18).timeout
	var result := _save_opaque_capture(path)
	print("QA_CARAVAN_SECRET_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _debug_play_dice_audio(category: String) -> void:
	if not is_instance_valid(dice_audio): return
	match category:
		"launch": dice_audio.begin_roll(1)
		"roll": dice_audio.play_roll(1.0)
		"contact": dice_audio.play_contact(0.6)
		"land": dice_audio.play_land(Time.get_ticks_msec(), 0.72)
		"lock": dice_audio.play_lock()

func _debug_toggle_dice_audio() -> void:
	GameState.dice_se_muted = not GameState.dice_se_muted
	if is_instance_valid(dice_audio): dice_audio.set_muted(GameState.dice_se_muted)
	SaveManager.save_now()

func _debug_audio_twenty(count: int) -> void:
	if not is_instance_valid(dice_audio): return
	for roll_index: int in range(20):
		dice_audio.begin_roll(count)
		for pulse: int in range(3):
			dice_audio.play_roll(1.0 - float(pulse) * 0.3)
			if pulse == 1: dice_audio.play_contact(0.5)
			await get_tree().create_timer(0.055).timeout
		for die_index: int in range(count): dice_audio.play_land(die_index, 0.62)
		await get_tree().create_timer(0.16).timeout
		dice_audio.end_roll()

func _debug_set_boss_gauge(value: int) -> void:
	GameState.ensure_boss_data()
	GameState.current_boss["gauge"] = clampi(value, 0, 100)
	GameState.current_boss["stage"] = BossSystemScript.stage_for_gauge(int(GameState.current_boss["gauge"]))
	GameState.boss_bond = float(GameState.current_boss["gauge"])
	_refresh_hud()

func _debug_next_boss() -> void:
	GameState.begin_next_boss()
	_refresh_hud()

func _debug_reset_encyclopedia() -> void:
	GameState.encyclopedia.clear()
	_refresh_hud()

func _toggle_debug() -> void:
	debug_box.visible = not debug_box.visible

func _show_message(title_text: String, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title_text
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 320))

func _qa_early_stop() -> void:
	GameState.reset_run()
	GameState.current_dice_count = 3
	show_game()
	# Land on a deterministic NORMAL space so the input timing test never waits on event UI.
	GameState.fixed_rolls.assign([1, 2, 3])
	var before_rolls := GameState.rolls_used
	_on_roll_pressed()
	await get_tree().create_timer(0.12).timeout
	_on_roll_pressed()
	await get_tree().create_timer(0.12).timeout
	_on_roll_pressed()
	await get_tree().create_timer(0.12).timeout
	_on_roll_pressed()
	while moving or rolling_dice:
		await get_tree().process_frame
	var passed := locked_dice_count == 3 and GameState.rolls_used == before_rolls + 1
	print("QA_EARLY_STOP locked=%d rolls_delta=%d passed=%s" % [locked_dice_count, GameState.rolls_used - before_rolls, passed])
	if not passed:
		push_error("Early-stop interaction smoke test failed.")
	get_tree().quit(0 if passed else 1)

func _qa_one_die() -> void:
	GameState.reset_run()
	show_game()
	_set_mode(1)
	GameState.fixed_rolls.assign([1])
	var before_rolls := GameState.rolls_used
	_on_roll_pressed()
	while moving or rolling_dice:
		await get_tree().process_frame
	var passed := GameState.current_tile_index == 1 and GameState.rolls_used == before_rolls + 1 and role_label.text.begins_with("静かな一投")
	print("QA_ONE_DIE tile=%d rolls_delta=%d role=%s passed=%s" % [GameState.current_tile_index, GameState.rolls_used - before_rolls, role_label.text, passed])
	if not passed:
		push_error("One-die interaction smoke test failed.")
	get_tree().quit(0 if passed else 1)

func _qa_five_dice() -> void:
	GameState.reset_run()
	GameState.current_dice_count = 3
	GameState.current_boss = BossSystemScript.initial_individual(1)
	show_game()
	_set_mode(5)
	# Tourism's map-dice overlay needs one layout frame before its launch rect
	# is valid in the headless smoke test.
	await get_tree().process_frame
	GameState.fixed_rolls.assign([4, 5, 6, 1, 2])
	var before_rolls := GameState.rolls_used
	await _on_roll_pressed()
	var selected_values: Array[int] = []
	for index: int in selected_indices:
		selected_values.append(dice_values[index])
	var selection_ok := selected_values == [4, 5, 6]
	await _confirm_five()
	var passed := selection_ok and GameState.current_route_id == BoardModelScript.ROUTE_MAIN and GameState.current_tile_index == 15 and GameState.rolls_used == before_rolls + 1
	print("QA_FIVE_DICE selected=%s route=%s tile=%d rolls_delta=%d passed=%s" % [selected_values, GameState.current_route_id, GameState.current_tile_index, GameState.rolls_used - before_rolls, passed])
	if not passed:
		push_error("Five-dice interaction smoke test failed.")
	get_tree().quit(0 if passed else 1)

func _qa_save_reload() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.current_tile_index = 42
	GameState.coins = 77
	GameState.boss_presence = 4
	_debug_set_boss_gauge(44)
	var saved := SaveManager.save_now()
	GameState.current_tile_index = 0
	GameState.coins = 0
	GameState.boss_presence = 0
	_debug_set_boss_gauge(0)
	var loaded := SaveManager.load_now()
	var passed := saved and loaded and GameState.current_tile_index == 42 and GameState.coins == 77 and GameState.boss_presence == 4 and int(GameState.current_boss.get("gauge", 0)) == 44
	print("QA_SAVE_RELOAD tile=%d coins=%d presence=%d gauge=%d passed=%s" % [GameState.current_tile_index, GameState.coins, GameState.boss_presence, int(GameState.current_boss.get("gauge", 0)), passed])
	GameState.apply_dictionary(original)
	SaveManager.save_now()
	if not passed:
		push_error("Save/reload smoke test failed.")
	get_tree().quit(0 if passed else 1)

func _qa_m3_smoke() -> void:
	GameState.reset_run()
	show_game()
	GameState.boss_presence = 0
	await _resolve_landing(&"BOSS_SCENT", {"main": &"", "support": &""})
	var scent_space_ok := GameState.boss_presence == 2
	GameState.current_boss = BossSystemScript.initial_individual(1)
	GameState.boss_sequence = 2
	GameState.encyclopedia.clear()
	var definition := BossSystemScript.definition_by_id("sleepy_sphinx", boss_definitions)
	var chance_low := BossSystemScript.encounter_chance(0, 0)
	var chance_high := BossSystemScript.encounter_chance(5, 0)
	var forced := BossSystemScript.should_encounter(0, 0, true, 0.99)
	var mercy := BossSystemScript.should_encounter(0, 5, false, 0.99)
	var outcome := BossSystemScript.resolve_interaction(GameState.current_boss, definition, 0, true)
	GameState.current_boss = outcome.individual
	_debug_set_boss_gauge(99)
	var final_outcome := BossSystemScript.resolve_interaction(GameState.current_boss, definition, 1, false)
	GameState.current_boss = final_outcome.individual
	var registered_once := GameState.register_current_boss()
	var registered_twice := GameState.register_current_boss()
	var old_name := str(GameState.current_boss.get("name", ""))
	_prepare_next_boss_after_join()
	var switched := str(GameState.current_boss.get("name", "")) != old_name
	var next_is_fresh := not bool(GameState.current_boss.get("got", true)) and int(GameState.current_boss.get("gauge", 0)) == 0
	GameState.reset_run()
	var next_trip_ok := GameState.current_tile_index == 0 and str(GameState.current_boss.get("name", "")) != old_name
	show_stage_select()
	var stage_select_ok := root_stack != null and next_is_fresh
	GameState.current_boss = {}
	var stage_select_loads_next := SaveManager.load_now() and str(GameState.current_boss.get("name", "")) != old_name and not bool(GameState.current_boss.get("got", true))
	show_game()
	var blocked_rolls := GameState.rolls_used
	var blocked_mode := dice_mode
	modal_open = true
	_on_roll_pressed()
	_set_mode(1)
	var modal_blocks_input := GameState.rolls_used == blocked_rolls and dice_mode == blocked_mode
	modal_open = false
	GameState.current_boss["gauge"] = 47
	GameState.current_boss["encounters"] = 3
	var before_save := GameState.to_dictionary().duplicate(true)
	var saved := SaveManager.save_now()
	GameState.current_boss = {}
	var loaded := SaveManager.load_now()
	var save_restores_boss := saved and loaded and int(GameState.current_boss.get("gauge", 0)) == 47 and int(GameState.current_boss.get("encounters", 0)) == 3
	GameState.apply_dictionary(before_save)
	SaveManager.save_now()
	var original := GameState.to_dictionary()
	var migrated := GameState.to_dictionary()
	migrated.erase("current_boss")
	migrated.erase("encyclopedia")
	migrated.erase("boss_relief")
	migrated.erase("boss_sequence")
	migrated["version"] = 1
	migrated["bond"] = 31.0
	GameState.apply_dictionary(migrated)
	var migration_ok := not GameState.current_boss.is_empty() and int(GameState.current_boss.get("gauge", 0)) == 31
	GameState.apply_dictionary(original)
	var passed: bool = scent_space_ok and chance_high > chance_low and forced and mercy and int(outcome.gain) == 21 and final_outcome.joined_now and registered_once and not registered_twice and GameState.encyclopedia.size() == 1 and switched and next_trip_ok and stage_select_ok and stage_select_loads_next and modal_blocks_input and save_restores_boss and migration_ok
	print("QA_M3 scent_space=%s chance_low=%.2f chance_high=%.2f forced=%s mercy=%s pair_gain=%d joined=%s register_once=%s register_twice=%s book=%d next=%s next_trip=%s stage_select=%s stage_loads_next=%s modal_blocks=%s save_restore=%s migration=%s passed=%s" % [scent_space_ok, chance_low, chance_high, forced, mercy, int(outcome.gain), final_outcome.joined_now, registered_once, registered_twice, GameState.encyclopedia.size(), switched, next_trip_ok, stage_select_ok, stage_select_loads_next, modal_blocks_input, save_restores_boss, migration_ok, passed])
	if not passed:
		push_error("M3 smoke test failed.")
	get_tree().quit(0 if passed else 1)

func _qa_m3_routes() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run()
	GameState.current_boss = BossSystemScript.initial_individual(1)
	GameState.boss_sequence = 2
	GameState.encyclopedia.clear()
	show_game()
	# Acceptance #1: travel through the production NORMAL landing branch.
	GameState.debug_force_encounter = true
	_resolve_landing(&"NORMAL", {"main": &"", "support": &""})
	while not modal_open:
		await get_tree().process_frame
	var normal_modal_once := find_children("boss_action_0", "Button", true, false).size() == 1
	var action: Button = find_children("boss_action_0", "Button", true, false)[0]
	action.button_pressed = true
	while find_children("return_to_trip", "Button", true, false).is_empty():
		await get_tree().process_frame
	var return_button: Button = find_children("return_to_trip", "Button", true, false)[0]
	return_button.pressed.emit()
	while modal_open:
		await get_tree().process_frame
	var normal_encounter_ok := normal_modal_once and int(GameState.current_boss.get("encounters", 0)) == 1

	# Acceptance #14a: press the real Next Journey button and reload its saved next individual.
	var first_name := str(GameState.current_boss.get("name", ""))
	_debug_set_boss_gauge(100)
	var first_definition := BossSystemScript.definition_by_id(str(GameState.current_boss.get("definition_id", "sleepy_sphinx")), boss_definitions)
	_show_get_result(first_definition)
	while find_children("next_trip", "Button", true, false).is_empty():
		await get_tree().process_frame
	var next_trip_button: Button = find_children("next_trip", "Button", true, false)[0]
	next_trip_button.button_pressed = true
	while modal_open:
		await get_tree().process_frame
	await get_tree().process_frame
	var next_name := str(GameState.current_boss.get("name", ""))
	var next_trip_ui_ok := GameState.current_tile_index == 0 and next_name != first_name and _has_label_text("砂時計のカイロ")
	GameState.current_boss = {}
	var next_trip_save_ok := SaveManager.load_now() and str(GameState.current_boss.get("name", "")) == next_name and not bool(GameState.current_boss.get("got", true))

	# Acceptance #14b: press the real Stage Select button; the next individual is already durable.
	show_game()
	var second_name := str(GameState.current_boss.get("name", ""))
	_debug_set_boss_gauge(100)
	var second_definition := BossSystemScript.definition_by_id(str(GameState.current_boss.get("definition_id", "sleepy_sphinx")), boss_definitions)
	_show_get_result(second_definition)
	while find_children("stage_select", "Button", true, false).is_empty():
		await get_tree().process_frame
	var stage_select_button: Button = find_children("stage_select", "Button", true, false)[0]
	stage_select_button.button_pressed = true
	while modal_open:
		await get_tree().process_frame
	await get_tree().process_frame
	var stage_next_name := str(GameState.current_boss.get("name", ""))
	var stage_ui_ok := _has_label_text("旅先を選ぶ") and stage_next_name != second_name
	GameState.current_boss = {}
	var stage_save_ok := SaveManager.load_now() and str(GameState.current_boss.get("name", "")) == stage_next_name and not bool(GameState.current_boss.get("got", true))

	# Same-definition individuals must both remain visible as independent cards.
	var book_a := BossSystemScript.initial_individual(901)
	book_a["individual_id"] = "book-a"
	book_a["name"] = "同種個体A"
	book_a["registration_order"] = 1
	book_a["got"] = true
	var book_b := book_a.duplicate(true)
	book_b["individual_id"] = "book-b"
	book_b["name"] = "同種個体B"
	book_b["registration_order"] = 2
	GameState.encyclopedia.assign([book_a, book_b])
	show_encyclopedia()
	await get_tree().process_frame
	var all_cards_visible := _has_label_text("同種個体A") and _has_label_text("同種個体B")

	var passed := normal_encounter_ok and next_trip_ui_ok and next_trip_save_ok and stage_ui_ok and stage_save_ok and all_cards_visible
	print("QA_M3_ROUTES normal=%s next_ui=%s next_save=%s stage_ui=%s stage_save=%s all_cards=%s passed=%s" % [normal_encounter_ok, next_trip_ui_ok, next_trip_save_ok, stage_ui_ok, stage_save_ok, all_cards_visible, passed])
	GameState.apply_dictionary(original)
	SaveManager.save_now()
	if not passed:
		push_error("M3 route integration test failed.")
	get_tree().quit(0 if passed else 1)

func _has_label_text(fragment: String) -> bool:
	for node: Node in find_children("*", "Label", true, false):
		if fragment in str((node as Label).text):
			return true
	return false

func _qa_m3_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.ensure_boss_data()
	match kind:
		"game": show_game()
		"encounter":
			show_game()
			# Use the same modal used during play, rather than a capture-only approximation.
			_show_encounter_modal(false)
		"get":
			show_game()
			_debug_set_boss_gauge(100)
			var definition := BossSystemScript.definition_by_id(str(GameState.current_boss.get("definition_id", "sleepy_sphinx")), boss_definitions)
			# This is the production registration/result modal, with the next individual already saved.
			_show_get_result(definition)
		"encyclopedia":
			GameState.register_current_boss()
			show_encyclopedia()
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(path)
	print("QA_M3_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_m4a() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run(); show_game()
	var checks: Array[bool] = []
	checks.append(EventSystemScript.district_for_tile(0) == "MARKET" and EventSystemScript.district_for_tile(89) == "DUNES")
	var selection_state := GameState.to_dictionary(); selection_state.recent_event_ids.assign(["CAI-E01"])
	checks.append(EventSystemScript.pool_for("MARKET", event_definitions, selection_state).all(func(event: Dictionary) -> bool: return event.event_id != "CAI-E01"))
	selection_state.seen_event_ids.assign(["CAI-E01", "CAI-E02"]); selection_state.recent_event_ids.assign(["CAI-E02", "CAI-E01"])
	checks.append(EventSystemScript.pick_event("MARKET", event_definitions, selection_state, 0.99).event_id == "CAI-E03")
	var source_roles := DiceLogicScript.evaluate([3, 3, 4]); var arrival := EventSystemScript.arrival_snapshot([3, 3, 4], source_roles, true, GameState.selected_character_id)
	checks.append(arrival.source_total == 10 and arrival.source_was_early_stopped)
	var snapshot_copy := arrival.duplicate(true); var extra_roles := DiceLogicScript.evaluate([6, 6, 6]); checks.append(snapshot_copy == arrival and extra_roles.main == DiceLogicScript.TRIPLE)
	var reward_state := GameState.to_dictionary(); var choice_outcome := EventSystemScript.resolve(_event_by_id("CAI-E02"), arrival, "take"); choice_outcome.resolution_id = "qa-choice"
	var choice_once := RewardResolverScript.apply(reward_state, choice_outcome); var choice_twice := RewardResolverScript.apply(reward_state, choice_outcome); checks.append(choice_once.applied and not choice_twice.applied)
	checks.append(EventSystemScript.resolve(_event_by_id("CAI-E11"), arrival, "", {"effective_value": 6, "extra_roles": {"labels": []}}).result_id == "cai_e11_rare")
	checks.append(EventSystemScript.resolve(_event_by_id("CAI-E29"), arrival, "", {"extra_roles": extra_roles}).result_id == "cai_e29_triple")
	var many := DiceLogicScript.evaluate_many([2, 2, 3, 4, 5]); checks.append(int(many.type_count) == 2)
	var five := DiceLogicScript.evaluate_many([5, 5, 5, 5, 5]); checks.append(five.five_of_a_kind)
	checks.append(choice_once.applied)
	checks.append(not choice_twice.applied)
	var boss_outcome := EventSystemScript.resolve(_event_by_id("CAI-E03"), EventSystemScript.arrival_snapshot([2, 2, 2], DiceLogicScript.evaluate([2, 2, 2]), false, GameState.selected_character_id)); boss_outcome.resolution_id = "qa-boss"
	var boss_state := GameState.to_dictionary(); RewardResolverScript.apply(boss_state, boss_outcome); checks.append(boss_state.pending_boss_handoff)
	checks.append(boss_outcome.follow_up == "START_BOSS_ENCOUNTER")
	var before_rolls := GameState.rolls_used; modal_open = true; _on_roll_pressed(); checks.append(GameState.rolls_used == before_rolls); modal_open = false
	GameState.active_event_state = {"phase": "WAITING_FOR_CHOICE", "event_id": "CAI-E02", "arrival": arrival}; var saved := SaveManager.save_now(); checks.append(saved)
	GameState.active_event_state.clear(); var loaded := SaveManager.load_now(); checks.append(loaded and GameState.active_event_state.event_id == "CAI-E02")
	var rare_state := GameState.to_dictionary(); EventSystemScript.record_event(rare_state, "CAI-E30"); checks.append(EventSystemScript.pool_for("DUNES", event_definitions, rare_state).all(func(event: Dictionary) -> bool: return event.event_id != "CAI-E30"))
	var v2 := original.duplicate(true); v2.version = 2
	for key: String in ["event_history", "seen_event_ids", "recent_event_ids", "events_seen_this_loop", "rare_event_used_this_loop", "active_event_state", "applied_resolution_ids"]: v2.erase(key)
	GameState.apply_dictionary(v2); checks.append(GameState.event_history.is_empty() and GameState.active_event_state.is_empty())
	checks.append(DiceLogicScript.evaluate([1, 2, 3]).main == DiceLogicScript.STRAIGHT and BossSystemScript.should_encounter(0, 0, true, 0.99))
	var forced_ok := true
	for id: String in ["CAI-E01", "CAI-E02", "CAI-E03", "CAI-E08", "CAI-E10", "CAI-E11", "CAI-E14", "CAI-E20", "CAI-E29", "CAI-E30"]:
		var forced_event := _event_by_id(id)
		var forced_choice := ""
		if not forced_event.get("choices", []).is_empty(): forced_choice = str(forced_event.choices[0].choice_id)
		var forced_extra: Dictionary = {}
		if id == "CAI-E11": forced_extra = {"effective_value": 6, "extra_roles": {"labels": []}}
		elif id == "CAI-E29": forced_extra = {"extra_roles": DiceLogicScript.evaluate([6, 6, 6])}
		elif id == "CAI-E30": forced_extra = {"extra_roles": five, "role_type_count": five.type_count}
		var forced_outcome := EventSystemScript.resolve(forced_event, arrival, forced_choice, forced_extra)
		forced_ok = forced_ok and not forced_event.is_empty() and not str(forced_outcome.get("result_id", "")).is_empty()
	var passed := checks.size() == 20 and checks.all(func(value: bool) -> bool: return value) and forced_ok
	print("QA_M4A checks=%d forced10=%s passed=%s" % [checks.count(true), forced_ok, passed])
	GameState.apply_dictionary(original); SaveManager.save_now()
	if not passed: push_error("M4A integration QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_m4a_capture(kind: String, path: String) -> void:
	GameState.reset_run(); show_game(); dice_values.assign([3, 3, 4])
	var roles := DiceLogicScript.evaluate(dice_values)
	match kind:
		"opening", "choice":
			GameState.debug_forced_event_id = "CAI-E01" if kind == "opening" else "CAI-E20"
			_show_event_modal(roles)
		"extra":
			GameState.debug_forced_event_id = "CAI-E29"; _show_event_modal(roles)
		"result":
			GameState.debug_forced_event_id = "CAI-E01"; _show_event_modal(roles)
		"boss_handoff":
			dice_values.assign([2, 2, 2]); roles = DiceLogicScript.evaluate(dice_values); GameState.debug_forced_event_id = "CAI-E03"; _resolve_landing(&"EVENT", roles)
	await get_tree().process_frame; await get_tree().process_frame
	if kind in ["result", "boss_handoff"]:
		while find_children("event_proceed", "Button", true, false).is_empty(): await get_tree().process_frame
		(find_children("event_proceed", "Button", true, false)[0] as Button).pressed.emit()
		while find_children("event_close", "Button", true, false).is_empty(): await get_tree().process_frame
	if kind == "boss_handoff":
		(find_children("event_close", "Button", true, false)[0] as Button).pressed.emit()
		while find_children("boss_action_0", "Button", true, false).is_empty(): await get_tree().process_frame
	await get_tree().process_frame; await get_tree().process_frame
	for ignored: int in range(8): await get_tree().process_frame
	var result := _save_opaque_capture(path)
	print("QA_M4A_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_stop_all() -> void:
	GameState.reset_run(); GameState.current_dice_count = 3; show_game(); _set_mode(3)
	_on_roll_pressed()
	while not rolling_dice: await get_tree().process_frame
	await get_tree().create_timer(0.16).timeout
	_lock_next_die(false)
	var first_value := rolling_values[0]
	await get_tree().create_timer(0.12).timeout
	var first_stayed := rolling_values[0] == first_value and locked_dice_count >= 1
	var values_before_all := rolling_values.duplicate()
	_stop_all_dice()
	var all_stayed := locked_dice_count == 3 and rolling_values == values_before_all
	var no_double := locked_dice_count; _stop_all_dice(); no_double = no_double == locked_dice_count
	var passed := first_stayed and all_stayed and no_double
	print("QA_DICE_STOP left_stable=%s all_current=%s no_double=%s passed=%s" % [first_stayed, all_stayed, no_double, passed])
	if not passed: push_error("Dice stop controls QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_extra_dice_controls() -> void:
	GameState.reset_run(); GameState.current_dice_count = 3; show_game()
	var passed := true
	for count: int in [1, 3, 5]:
		_animate_dice_roll(count, root_stack)
		while not rolling_dice or not is_instance_valid(active_extra_all_stop): await get_tree().process_frame
		var controls_exist := is_instance_valid(active_extra_left_stop) and is_instance_valid(active_extra_all_stop)
		if count > 1: active_extra_left_stop.pressed.emit(); await get_tree().process_frame
		var locked_before_all := locked_dice_count
		active_extra_all_stop.pressed.emit(); await get_tree().process_frame
		passed = passed and controls_exist and locked_dice_count == count and locked_before_all <= count
		while rolling_dice: await get_tree().process_frame
	print("QA_EXTRA_DICE_CONTROLS counts=1,3,5 passed=%s" % passed)
	if not passed: push_error("Extra dice stop controls QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_dice_audio() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run(); GameState.master_volume = 1.0; GameState.se_volume = 1.0; GameState.dice_se_muted = false; show_game()
	var pool_before := int(dice_audio.receipt().pool_size)
	dice_audio.begin_roll(5)
	dice_audio.play_launch() # Must not duplicate the begin-roll launch.
	for pulse: int in range(8):
		dice_audio.play_roll(1.0 - float(pulse) / 9.0)
		await get_tree().create_timer(0.082).timeout
	for contact_index: int in range(10): dice_audio.play_contact(0.5)
	for die_index: int in range(5): dice_audio.play_land(die_index, 0.64)
	for die_index: int in range(5): dice_audio.play_land(die_index, 0.64) # Duplicate locks are ignored.
	await get_tree().create_timer(0.28).timeout
	dice_audio.end_roll()
	var mixed: Dictionary = dice_audio.receipt()
	var counts: Dictionary = mixed.play_counts
	var physical_counts_ok := int(counts.launch) == 1 and int(counts.roll) > 0 and int(counts.roll) <= 8 and int(counts.contact) > 0 and int(counts.contact) <= 4 and int(mixed.contacts_this_roll) == 4 and int(counts.land) == 5 and int(counts.lock) > 0 and int(counts.lock) <= 5
	var bounded := int(mixed.pool_size) == DiceAudioControllerScript.PLAYER_POOL_SIZE and int(mixed.rolling_pool) == 2 and int(mixed.contact_pool) == 2 and int(mixed.landing_pool) == 3
	var before_mute := counts.duplicate(true)
	dice_audio.set_muted(true); dice_audio.begin_roll(3); dice_audio.play_roll(1.0); dice_audio.play_contact(); dice_audio.play_land(0); await get_tree().process_frame
	var mute_ok: bool = dice_audio.receipt().play_counts == before_mute and int(dice_audio.active_voice_count()) == 0
	dice_audio.set_muted(false)
	for roll_index: int in range(100): dice_audio.begin_roll(1); dice_audio.end_roll()
	var pool_stable := int(dice_audio.receipt().pool_size) == pool_before
	GameState.master_volume = 0.75; GameState.se_volume = 0.35; GameState.dice_se_muted = true
	var settings := GameState.to_dictionary(); GameState.master_volume = 1.0; GameState.se_volume = 1.0; GameState.dice_se_muted = false; GameState.apply_dictionary(settings)
	var settings_ok := is_equal_approx(GameState.master_volume, 0.75) and is_equal_approx(GameState.se_volume, 0.35) and GameState.dice_se_muted
	var passed: bool = physical_counts_ok and bounded and mute_ok and pool_stable and settings_ok
	print("QA_DICE_AUDIO launch=%d roll=%d contact=%d land=%d lock=%d pool=%d mute=%s stable=%s settings=%s passed=%s" % [int(counts.launch), int(counts.roll), int(counts.contact), int(counts.land), int(counts.lock), int(mixed.pool_size), mute_ok, pool_stable, settings_ok, passed])
	dice_audio.stop_all(); await get_tree().create_timer(0.08).timeout
	GameState.apply_dictionary(original); SaveManager.save_now()
	if not passed: push_error("Dice audio QA failed.")

func _qa_ui_audio() -> void:
	await get_tree().process_frame
	show_stage_select()
	await get_tree().process_frame
	var city_buttons := find_children("city_cairo", "Button", true, false)
	var city_connected := not city_buttons.is_empty() and (city_buttons[0] as Button).pressed.get_connections().size() >= 2
	_play_ui_click(true)
	var confirm_ok := is_instance_valid(ui_audio_player) and ui_audio_player.stream == UI_CONFIRM_STREAM
	_play_ui_click(false)
	var click_ok := is_instance_valid(ui_audio_player) and ui_audio_player.stream == UI_CLICK_STREAM
	var player_id := ui_audio_player.get_instance_id()
	show_character_select()
	await get_tree().process_frame
	var survives_transition := is_instance_valid(ui_audio_player) and ui_audio_player.get_instance_id() == player_id and get_node_or_null("UIAudioPlayer") == ui_audio_player
	var passed := city_connected and confirm_ok and click_ok and survives_transition
	print("QA_UI_AUDIO city_connected=%s confirm=%s click=%s survives=%s passed=%s" % [city_connected, confirm_ok, click_ok, survives_transition, passed])
	if not passed: push_error("UI audio QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_android_ui() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	var samples: Array[String] = [
		"砂時計のカイロ", "眠そうなスフィンクスがいる",
		"サイコロをそろえて、世界をめぐる。", "旅人を選ぶ",
		"香辛料市場通り", "PAIR／STRAIGHT／TRIPLE", "1234567890！？・◇●",
	]
	var coverage_ok := true
	for sample: String in samples:
		for index: int in range(sample.length()):
			coverage_ok = coverage_ok and APP_FONT.has_char(sample.unicode_at(index))
	var theme_ok := theme != null and theme.default_font == APP_FONT \
		and theme.get_font("font", "Label") == APP_FONT \
		and theme.get_font("font", "Button") == APP_FONT \
		and theme.get_font("normal_font", "RichTextLabel") == APP_FONT \
		and theme.get_constant("outline_size", "Label") == 0 \
		and theme.get_constant("outline_size", "Button") == 0
	show_font_qa()
	await get_tree().process_frame
	var controls_ok := true
	for control: Node in find_children("*", "Control", true, false):
		if control is Label or control is Button:
			controls_ok = controls_ok and (control as Control).get_theme_font("font") == APP_FONT
		elif control is RichTextLabel:
			controls_ok = controls_ok and (control as Control).get_theme_font("normal_font", "RichTextLabel") == APP_FONT
	var legacy := original.duplicate(true)
	legacy.erase("board_view_mode")
	GameState.apply_dictionary(legacy)
	show_game()
	var legacy_tourism := GameState.board_view_mode == "tourism" and board_view is TourismMapView
	var explicit_classic := original.duplicate(true)
	explicit_classic["board_view_mode"] = "classic"
	GameState.apply_dictionary(explicit_classic)
	show_game()
	var classic_loaded := GameState.board_view_mode == "classic" and not (board_view is TourismMapView)
	GameState.start_new_game()
	show_game()
	var classic_after_new_trip := GameState.board_view_mode == "classic" and not (board_view is TourismMapView)
	GameState.selected_character_id = &"photographer"
	show_game()
	var classic_after_character := GameState.board_view_mode == "classic" and not (board_view is TourismMapView)
	GameState.board_view_mode = "tourism"
	show_game()
	var tourism_restored := board_view is TourismMapView
	var passed := coverage_ok and theme_ok and controls_ok and legacy_tourism and classic_loaded and classic_after_new_trip and classic_after_character and tourism_restored
	print("QA_ANDROID_UI font=%s theme=%s controls=%s legacy_tourism=%s classic_load=%s new_trip=%s character=%s tourism=%s passed=%s" % [coverage_ok, theme_ok, controls_ok, legacy_tourism, classic_loaded, classic_after_new_trip, classic_after_character, tourism_restored, passed])
	GameState.apply_dictionary(original)
	SaveManager.save_now()
	if not passed: push_error("ANDROID-UI-01 QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_progression_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.current_dice_count = 1 if kind == "one" else (2 if kind == "two" else 3)
	show_game()
	for ignored: int in range(8): await get_tree().process_frame
	var result := _save_opaque_capture(path)
	print("QA_DICE_PROGRESSION_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_dice_progression() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.start_new_game()
	var fresh_one := GameState.current_dice_count == 1
	show_game()
	var one_visible := dice_row.get_child_count() == 1
	GameState.add_dice()
	show_game()
	var two_visible := dice_row.get_child_count() == 2
	GameState.add_dice()
	show_game()
	var three_visible := dice_row.get_child_count() == 3
	var role_locked: bool = DiceLogicScript.evaluate_unlocked([3, 3, 4], 2).main == DiceLogicScript.MAIN_NONE
	var role_unlocked: bool = DiceLogicScript.evaluate_unlocked([3, 3, 4], 3).main == DiceLogicScript.PAIR
	var saved := SaveManager.save_now()
	GameState.current_dice_count = 1
	var restored := SaveManager.load_now() and GameState.current_dice_count == 3
	var legacy := GameState.to_dictionary()
	legacy.erase("current_dice_count")
	legacy["unlocked_dice_count"] = 3
	legacy["version"] = 4
	GameState.apply_dictionary(legacy)
	var migrated := GameState.current_dice_count == 2
	GameState.apply_dictionary(original)
	SaveManager.save_now()
	var passed: bool = fresh_one and one_visible and two_visible and three_visible and role_locked and role_unlocked and saved and restored and migrated
	print("QA_DICE_PROGRESSION fresh_one=%s visible=1/2/3:%s/%s/%s roles=%s/%s save=%s restore=%s migration=%s passed=%s" % [fresh_one, one_visible, two_visible, three_visible, role_locked, role_unlocked, saved, restored, migrated, passed])
	if not passed: push_error("Dice progression QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_m4a_hardening() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run(); show_game()
	# Crossing tile 90 through normal movement starts a fresh rare-event loop.
	GameState.current_tile_index = 89; GameState.rare_event_used_this_loop = true; GameState.events_seen_this_loop.assign(["CAI-E30"]); GameState.events_since_rare = 0
	await _resolve_roll([1])
	var normal_loop_reset := not GameState.rare_event_used_this_loop and GameState.events_seen_this_loop.is_empty() and GameState.events_since_rare == 99
	# WARP can also cross tile 90 and must perform the identical reset.
	GameState.current_tile_index = 87; GameState.rare_event_used_this_loop = true; GameState.events_seen_this_loop.assign(["CAI-E30"]); GameState.events_since_rare = 0
	await _resolve_landing(&"WARP", {"main": &"", "support": &"", "labels": []})
	var warp_loop_reset := not GameState.rare_event_used_this_loop and GameState.events_seen_this_loop.is_empty() and GameState.events_since_rare == 99
	# Forced events display their definition's district, independent of debug launch location.
	dice_values.assign([3, 3, 4]); var roles := DiceLogicScript.evaluate(dice_values)
	GameState.debug_forced_event_id = "CAI-E20"; _show_event_modal(roles)
	while find_children("event_choice_entrance", "Button", true, false).is_empty(): await get_tree().process_frame
	var e20_district := _has_label_text("RUINS")
	(find_children("event_choice_entrance", "Button", true, false)[0] as Button).button_pressed = true
	while find_children("event_close", "Button", true, false).is_empty(): await get_tree().process_frame
	(find_children("event_close", "Button", true, false)[0] as Button).pressed.emit()
	while modal_open: await get_tree().process_frame
	GameState.debug_forced_event_id = "CAI-E29"; _show_event_modal(roles)
	while find_children("event_extra_roll", "Button", true, false).is_empty(): await get_tree().process_frame
	var e29_district := _has_label_text("DUNES")
	show_game(); modal_open = false; GameState.active_event_state.clear(); await get_tree().process_frame
	# A durable boss reservation survives load, is consumed only once the modal exists,
	# and the consumed state is saved so another restart does not repeat it.
	GameState.current_boss = BossSystemScript.initial_individual(700)
	GameState.pending_boss_handoff = true; var reservation_saved := SaveManager.save_now()
	GameState.pending_boss_handoff = false; var reservation_loaded := SaveManager.load_now() and GameState.pending_boss_handoff
	_resume_pending_boss_handoff()
	while find_children("boss_action_0", "Button", true, false).is_empty(): await get_tree().process_frame
	var opened_once := find_children("boss_action_0", "Button", true, false).size() == 1 and not GameState.pending_boss_handoff
	var action: Button = find_children("boss_action_0", "Button", true, false)[0]; action.button_pressed = true
	while find_children("return_to_trip", "Button", true, false).is_empty(): await get_tree().process_frame
	(find_children("return_to_trip", "Button", true, false)[0] as Button).pressed.emit()
	while modal_open: await get_tree().process_frame
	GameState.pending_boss_handoff = true
	var consumed_persisted := SaveManager.load_now() and not GameState.pending_boss_handoff
	_resume_pending_boss_handoff(); await get_tree().process_frame
	var no_second_open := find_children("boss_action_0", "Button", true, false).is_empty() and not modal_open
	var rare_boundary := RewardResolverScript.item_rarity_for_roll("RARE_EVENT", 54) == "UNCOMMON" and RewardResolverScript.item_rarity_for_roll("RARE_EVENT", 55) == "RARE"
	var passed := normal_loop_reset and warp_loop_reset and e20_district and e29_district and reservation_saved and reservation_loaded and opened_once and consumed_persisted and no_second_open and rare_boundary
	print("QA_M4A_HARDENING normal_loop=%s warp_loop=%s e20=%s e29=%s reservation_load=%s opened_once=%s consumed=%s no_repeat=%s rare55_45=%s passed=%s" % [normal_loop_reset, warp_loop_reset, e20_district, e29_district, reservation_loaded, opened_once, consumed_persisted, no_second_open, rare_boundary, passed])
	GameState.apply_dictionary(original); SaveManager.save_now()
	if not passed: push_error("M4A hardening QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_dice_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	var count := 1 if kind in ["one", "one-locked"] else (2 if kind == "two" else (5 if kind in ["five", "rolling-five"] else 3))
	GameState.current_dice_count = clampi(count, 1, 3); show_game()
	var should_roll := kind in ["rolling", "rolling-five", "one-locked"]
	if should_roll:
		_animate_dice_roll(count)
		while not rolling_dice: await get_tree().process_frame
		await get_tree().create_timer(0.16).timeout
		if kind == "one-locked": _lock_next_die(false)
	else:
		var shown: Array[int] = []
		for value: int in range(count): shown.append(value % 6 + 1)
		_render_dice(shown, false)
	await get_tree().process_frame; await get_tree().process_frame
	for ignored: int in range(8): await get_tree().process_frame
	# Compatibility renderer can expose an incompletely resolved transparent
	# SubViewport when a static frame is read back immediately after construction.
	await get_tree().create_timer(0.22).timeout
	var result := _save_opaque_capture(path)
	print("QA_DICE_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_risk_space(kind: String) -> void:
	GameState.reset_run(); GameState.applied_resolution_ids.clear(); GameState.current_dice_count = 2; GameState.current_tile_index = 58; GameState.flow_level = 3; show_game()
	var before_count := GameState.current_dice_count
	var before_coins := GameState.coins
	if kind == "challenge": GameState.debug_fixed_extra_rolls.assign([1, 3, 5])
	_show_risk_space_modal()
	var button_name := "risk_challenge" if kind == "challenge" else "risk_safe"
	while find_children(button_name, "Button", true, false).is_empty(): await get_tree().process_frame
	(find_children(button_name, "Button", true, false)[0] as Button).button_pressed = true
	while find_children("risk_close", "Button", true, false).is_empty(): await get_tree().process_frame
	var count_before_close := GameState.current_dice_count
	var coins_before_close := GameState.coins
	(find_children("risk_close", "Button", true, false)[0] as Button).pressed.emit()
	while modal_open: await get_tree().process_frame
	var passed := count_before_close >= before_count
	if kind == "safe": passed = passed and count_before_close == 2 and GameState.current_tile_index == 55 and not GameState.current_lap_clean and GameState.current_lap_penalty_count == 1
	else: passed = passed and count_before_close == 2 and coins_before_close == before_coins + 30 and GameState.current_lap_clean and GameState.flow_level == 3
	print("QA_RISK kind=%s before=%d after=%d coins_delta=%d clean=%s tile=%d modal_closed=%s passed=%s" % [kind, before_count, count_before_close, coins_before_close - before_coins, GameState.current_lap_clean, GameState.current_tile_index, not modal_open, passed])
	if not passed: push_error("Risk-space QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_tourmap() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run()
	GameState.current_tile_index = 89
	GameState.current_dice_count = 2
	GameState.landmark_levels = {"CAI_LANDMARK_01": 3, "CAI_LANDMARK_02": 2, "CAI_LANDMARK_03": 1}
	show_game()
	var classic_ok: bool = _set_board_view_mode("classic") and not (board_view is TourismMapView)
	var minimap_ok: bool = minimap_view.get_script() == BoardViewScript and minimap_view.is_minimap
	var tourism_ok: bool = _set_board_view_mode("tourism") and board_view is TourismMapView
	var wrapped_indices: Array[int] = TourismMapViewScript.neighborhood_indices(board_view.current_tile)
	var wrap_ok: bool = wrapped_indices == [86, 87, 88, 89, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
	var scenic_ok: bool = board_view.scenic_level == 3 and board_view.scenic_texture != null
	var input_ok: bool = board_view.mouse_filter == Control.MOUSE_FILTER_IGNORE
	var district_flow_repeat_ok := false
	if board_view is TourismMapView:
		var tourism_view := board_view as TourismMapView
		var child_count_before := tourism_view.get_child_count()
		var active_receipts_ok := true
		for district_tile: int in [84, 43, 61, 25]:
			tourism_view.set_current_tile(district_tile)
			for cycle: int in range(20):
				for level: int in [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0]:
					tourism_view.set_flow_visual_level(level)
			var active_receipt := tourism_view.district_flow_receipt()
			active_receipts_ok = active_receipts_ok and bool(active_receipt.get("supported", false)) and int(active_receipt.get("flow_level", -1)) == 0 and not bool(active_receipt.get("processing", true)) and int(active_receipt.get("visual_count", 0)) == 4 and int(active_receipt.get("coordinator_child_count", 0)) == 4
		tourism_view.set_current_tile(0)
		var hidden_receipt := tourism_view.district_flow_receipt()
		district_flow_repeat_ok = active_receipts_ok and child_count_before == tourism_view.get_child_count() and not bool(hidden_receipt.get("supported", true)) and not bool(hidden_receipt.get("processing", true)) and not bool(hidden_receipt.get("visible", true))
		tourism_view.set_current_tile(89)
	moving = true
	var blocked_while_moving: bool = not _set_board_view_mode("classic") and board_view is TourismMapView
	moving = false
	var fallback_ok: bool = _set_board_view_mode("not-a-mode") and not (board_view is TourismMapView) and board_view_mode == "classic"
	var passed: bool = classic_ok and minimap_ok and tourism_ok and wrap_ok and scenic_ok and input_ok and district_flow_repeat_ok and blocked_while_moving and fallback_ok
	print("QA_TOURMAP classic=%s tourism=%s minimap=%s wrap=%s scenic=%s input=%s district_flow_repeat=%s idle_guard=%s fallback=%s passed=%s" % [classic_ok, tourism_ok, minimap_ok, wrap_ok, scenic_ok, input_ok, district_flow_repeat_ok, blocked_while_moving, fallback_ok, passed])
	GameState.apply_dictionary(original)
	if not passed: push_error("TOURMAP deterministic QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_tourmap_die() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run()
	GameState.current_dice_count = 1
	GameState.current_tile_index = 89
	show_game()
	_set_board_view_mode("tourism")
	var start_tile := GameState.current_tile_index
	var values_valid := true
	var early_stop_ok := false
	qa_map_die_visible_stop_ok = false
	for roll_index: int in range(20):
		if roll_index == 0:
			call_deferred("_qa_request_map_die_stop")
		var values := await _animate_dice_roll(1)
		values_valid = values_valid and values.size() == 1 and int(values[0]) in range(1, 7)
		if roll_index == 0:
			early_stop_ok = last_roll_early_stopped
	var receipt: Dictionary = map_dice_overlay.receipt()
	var bounded := int(receipt.presentation_nodes) == 1 and int(receipt.dice_pool_size) == 5 and int(receipt.launch_count) == 20 and int(receipt.completion_count) == 20
	var idle := str(receipt.phase) == "TRAY_IDLE" and not map_dice_overlay.visible and dice_presentation.visible and not moving and not rolling_dice
	var no_commit := GameState.current_tile_index == start_tile and GameState.rolls_used == 0
	var audio_receipt: Dictionary = dice_audio.receipt()
	var audio_bounded := int(audio_receipt.pool_size) == DiceAudioControllerScript.PLAYER_POOL_SIZE and int(audio_receipt.active_voices) == 0
	var passed := values_valid and early_stop_ok and qa_map_die_visible_stop_ok and int(receipt.stop_request_count) == 1 and bounded and audio_bounded and idle and no_commit
	print("QA_TOURMAP_DIE values=%s early=%s visible_stop=%s bounded=%s audio=%s idle=%s no_commit=%s receipt=%s passed=%s" % [values_valid, early_stop_ok, qa_map_die_visible_stop_ok, bounded, audio_bounded, idle, no_commit, receipt, passed])
	GameState.apply_dictionary(original)
	if not passed: push_error("TOURMAP-03A overlay QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_tourmap_multi_die() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run()
	GameState.current_dice_count = 3
	GameState.current_tile_index = 58
	GameState.flow_level = 5
	show_game()
	_set_board_view_mode("tourism")
	_sync_flow_visuals()
	var counts: Array[int] = [2, 3, 5]
	var valid := true
	var idle := true
	var receipts: Array[Dictionary] = []
	for count: int in counts:
		if count == 3:
			fixed_targets = [6, 6, 6]
		var values := await _animate_dice_roll(count)
		var receipt: Dictionary = map_dice_overlay.receipt()
		receipts.append(receipt)
		valid = valid and values.size() == count and values.all(func(value: int) -> bool: return value >= 1 and value <= 6)
		idle = idle and str(receipt.get("phase", "")) == "TRAY_IDLE" and int(receipt.get("active_billboards", 0)) == count and not map_dice_overlay.visible and not rolling_dice and not moving
	var audio_receipt: Dictionary = dice_audio.receipt()
	var audio_ok := int(audio_receipt.get("active_voices", 0)) == 0
	var pooled := int(map_dice_overlay.receipt().get("billboard_pool_size", 0)) == MapDiceOverlayScript.MAX_DICE
	var slot_seen := int(map_dice_overlay.receipt().get("slot_open_count", 0)) >= 1 and int(map_dice_overlay.receipt().get("slot_result_count", 0)) >= 1 and int(map_dice_overlay.receipt().get("slot_frame_count", 0)) == 3
	var triple_seen := int(map_dice_overlay.receipt().get("triple_convergence_count", 0)) >= 1 and not bool(map_dice_overlay.receipt().get("triple_convergence_active", false))
	var flow_visual_ok := int(map_dice_overlay.receipt().get("flow_visual_level", 0)) == 5 and board_view is TourismMapView and (board_view as TourismMapView).flow_visual_level == 5
	var no_commit := GameState.rolls_used == 0 and GameState.current_tile_index == 58
	var passed := valid and idle and audio_ok and pooled and slot_seen and triple_seen and flow_visual_ok and no_commit
	print("QA_TOURMAP_MULTI_DIE values=%s idle=%s audio=%s pooled=%s slot=%s triple=%s flow=%s no_commit=%s receipts=%s passed=%s" % [valid, idle, audio_ok, pooled, slot_seen, triple_seen, flow_visual_ok, no_commit, receipts, passed])
	GameState.apply_dictionary(original)
	if not passed:
		push_error("TOURMAP multi-die overlay QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_request_map_die_stop() -> void:
	while is_instance_valid(map_dice_overlay) and map_dice_overlay.phase != MapDiceOverlay.Phase.ROLLING_ON_MAP:
		await get_tree().process_frame
	if is_instance_valid(map_dice_overlay):
		map_dice_overlay.request_early_stop()
		qa_map_die_visible_stop_ok = map_dice_overlay.phase == MapDiceOverlay.Phase.STOPPING and not map_dice_overlay.display.rolling
		map_dice_overlay.request_early_stop()

func _qa_tourmap_die_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.current_dice_count = 1
	GameState.current_tile_index = 0
	GameState.landmark_levels = {"CAI_LANDMARK_01": 3, "CAI_LANDMARK_02": 2, "CAI_LANDMARK_03": 1}
	show_game()
	_set_board_view_mode("tourism")
	for ignored: int in range(12):
		await get_tree().process_frame
	if kind in ["rolling", "result"]:
		var map_rect := board_view.get_global_rect()
		var tray_rect := _map_dice_tray_anchor_rect()
		dice_presentation.visible = false
		await map_dice_overlay.begin_launch([4], tray_rect, map_rect, TourismMapViewScript.map_dice_landing_rect(map_rect.size))
		map_dice_overlay.present([4], kind == "rolling", 0 if kind == "rolling" else 1)
		# Freeze only the QA readback frame. The Compatibility renderer can return
		# a partial backbuffer while a CanvasItem is changing during get_image().
		if kind == "rolling":
			map_dice_overlay.display.rolling = false
			map_dice_overlay.display.set_process(false)
			map_dice_overlay.presentation.set_process(false)
		if kind == "result":
			var destination := posmod(GameState.current_tile_index + 4, BoardModelScript.TILE_COUNT)
			(board_view as TourismMapView).highlight_destination(destination, 4)
			map_dice_overlay.begin_result_hold(4)
	for ignored: int in range(8):
		await get_tree().process_frame
	await get_tree().create_timer(0.22).timeout
	var result := ERR_CANT_CREATE
	var capture_attempts := 0
	for attempt: int in range(5):
		capture_attempts = attempt + 1
		result = _save_opaque_capture(path)
		if result == OK and _capture_has_full_ui(path):
			break
		for ignored: int in range(6):
			await get_tree().process_frame
		await get_tree().create_timer(0.12).timeout
	var capture_valid := result == OK and _capture_has_full_ui(path)
	print("QA_TOURMAP_DIE_CAPTURE kind=%s phase=%s receipt=%s attempts=%d valid=%s path=%s result=%s" % [kind, MapDiceOverlay.Phase.keys()[map_dice_overlay.phase], map_dice_overlay.receipt(), capture_attempts, capture_valid, path, result])
	get_tree().quit(0 if capture_valid else 1)

func _capture_has_full_ui(path: String) -> bool:
	var image := Image.load_from_file(path)
	if image == null or image.get_size() != Vector2i(360, 640):
		return false
	for point: Vector2i in [Vector2i(180, 20), Vector2i(20, 82), Vector2i(340, 82), Vector2i(20, 560), Vector2i(180, 620)]:
		if image.get_pixelv(point).get_luminance() < 0.08:
			return false
	return true

func _qa_tourmap_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.current_dice_count = 1
	var flow_capture_levels := {
		"dunes_flow5": 5,
		"oasis_flow0": 0,
		"oasis_flow1": 1,
		"oasis_flow2": 2,
		"oasis_flow3": 3,
		"oasis_flow4": 4,
		"oasis_flow5": 5,
		"ruins_flow0": 0,
		"ruins_flow1": 1,
		"ruins_flow2": 2,
		"ruins_flow3": 3,
		"ruins_flow4": 4,
		"ruins_flow5": 5,
		"pyramid_flow0": 0,
		"pyramid_flow1": 1,
		"pyramid_flow2": 2,
		"pyramid_flow3": 3,
		"pyramid_flow4": 4,
		"pyramid_flow5": 5,
	}
	GameState.flow_level = int(flow_capture_levels.get(kind, 0))
	var market_level := 0 if kind == "market_lv0" else 3
	GameState.landmark_levels = {"CAI_LANDMARK_01": market_level, "CAI_LANDMARK_02": 2, "CAI_LANDMARK_03": 1}
	GameState.current_tile_index = 25 if kind.begins_with("pyramid_flow") else (61 if kind.begins_with("ruins_flow") else (43 if kind == "classic" or kind.begins_with("oasis_flow") else (84 if kind in ["wrap", "dunes_flow5"] else 0)))
	show_game()
	_set_board_view_mode("classic" if kind == "classic" else "tourism")
	for ignored: int in range(12): await get_tree().process_frame
	var capture_delay := 0.24 if kind == "pyramid_flow5" else 0.50
	await get_tree().create_timer(capture_delay).timeout
	var result := _save_opaque_capture(path)
	print("QA_TOURMAP_CAPTURE kind=%s flow=%d market_level=%d path=%s result=%s" % [kind, GameState.flow_level, market_level, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_clean_lap() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	var state := original.duplicate(true)
	state["applied_resolution_ids"] = []
	state["total_lap_points"] = 0
	state["current_lap_bonus"] = 20
	state["current_lap_roll_count"] = 12
	state["current_lap_clean"] = true
	state["current_lap_penalty_count"] = 0
	state["clean_streak"] = 0
	state["best_clean_streak"] = 0
	state["coins"] = 0
	state["current_dice_count"] = 1
	var first := LapSystemScript.resolve(state, "qa-clean-1")
	RewardResolverScript.apply(state, first)
	state["current_lap_bonus"] = 0
	state["current_lap_roll_count"] = 12
	var second := LapSystemScript.resolve(state, "qa-clean-2")
	RewardResolverScript.apply(state, second)
	var milestone_snapshot := {"points": int(state.total_lap_points), "coins": int(state.coins), "streak": int(state.clean_streak)}
	var duplicate := RewardResolverScript.apply(state, second)
	var clean_ok := int(first.result.points) == 138 and int(second.result.points) == 130 and int(second.result.score) == 208 and int(second.result.milestone) == 2 and int(state.coins) == 42 and milestone_snapshot == {"points": int(state.total_lap_points), "coins": int(state.coins), "streak": int(state.clean_streak)} and not bool(duplicate.applied) and int(state.clean_streak) == 2
	state["current_lap_clean"] = false
	var dirty := LapSystemScript.resolve(state, "qa-clean-dirty")
	RewardResolverScript.apply(state, dirty)
	var dirty_ok := int(dirty.result.points) == 100 and is_equal_approx(float(dirty.result.multiplier), 1.0) and int(state.clean_streak) == 1
	var streak_3_state := original.duplicate(true); streak_3_state["applied_resolution_ids"] = []; streak_3_state["clean_streak"] = 2; streak_3_state["current_lap_clean"] = true; streak_3_state["current_dice_count"] = 1
	var streak_3 := LapSystemScript.resolve(streak_3_state, "qa-clean-3"); RewardResolverScript.apply(streak_3_state, streak_3)
	var streak_3_duplicate := RewardResolverScript.apply(streak_3_state, streak_3)
	var streak_3_ok := int(streak_3.result.milestone) == 3 and int(streak_3_state.current_dice_count) == 2 and not bool(streak_3_duplicate.applied)
	var streak_5_state := original.duplicate(true); streak_5_state["applied_resolution_ids"] = []; streak_5_state["clean_streak"] = 4; streak_5_state["current_lap_clean"] = true; streak_5_state["dice_keep_active"] = false
	var streak_5 := LapSystemScript.resolve(streak_5_state, "qa-clean-5"); RewardResolverScript.apply(streak_5_state, streak_5)
	var streak_5_duplicate := RewardResolverScript.apply(streak_5_state, streak_5)
	var streak_5_ok := int(streak_5.result.milestone) == 5 and bool(streak_5_state.dice_keep_active) and not bool(streak_5_duplicate.applied)
	var streak_max := LapSystemScript.resolve(streak_5_state, "qa-clean-max"); RewardResolverScript.apply(streak_5_state, streak_max)
	var streak_max_points := int(streak_5_state.total_lap_points)
	var streak_max_duplicate := RewardResolverScript.apply(streak_5_state, streak_max)
	var streak_max_ok := int(streak_max.result.clean_streak) == 5 and int(streak_max.result.milestone) == 0 and (streak_max.rewards as Array).is_empty() and not bool(streak_max_duplicate.applied) and int(streak_5_state.total_lap_points) == streak_max_points
	var reentry_state := original.duplicate(true); reentry_state["applied_resolution_ids"] = []; reentry_state["clean_streak"] = 5; reentry_state["current_lap_clean"] = false; reentry_state["dice_keep_active"] = false
	var streak_drop := LapSystemScript.resolve(reentry_state, "qa-clean-drop"); RewardResolverScript.apply(reentry_state, streak_drop)
	reentry_state["current_lap_clean"] = true
	var streak_reentry := LapSystemScript.resolve(reentry_state, "qa-clean-reentry"); RewardResolverScript.apply(reentry_state, streak_reentry)
	var streak_reentry_duplicate := RewardResolverScript.apply(reentry_state, streak_reentry)
	var reentry_ok := int(streak_drop.result.clean_streak) == 4 and int(streak_reentry.result.milestone) == 5 and bool(reentry_state.dice_keep_active) and not bool(streak_reentry_duplicate.applied)
	var boundaries_ok := streak_3_ok and streak_5_ok and streak_max_ok and reentry_ok
	var risk_ok := true
	var risk_state := {"coins": 20, "presence": 2, "tile": 58, "next_move_bonus": 0, "flow_level": 4, "current_lap_clean": true, "current_lap_penalty_count": 0, "even_guard_active": false, "applied_resolution_ids": []}
	for risk_tile: int in [27, 44, 58, 68, 80]:
		var penalties_before := int(risk_state.current_lap_penalty_count)
		RewardResolverScript.apply(risk_state, RewardResolverScript.resolve_risk(risk_state, "qa-risk-%d" % risk_tile, risk_tile))
		risk_ok = risk_ok and not bool(risk_state.current_lap_clean) and int(risk_state.current_lap_penalty_count) == penalties_before + 1
		risk_state["current_lap_clean"] = true
	risk_ok = risk_ok and int(risk_state.next_move_bonus) == -2 and int(risk_state.coins) == 12 and int(risk_state.tile) == 55 and int(risk_state.flow_level) == 0 and int(risk_state.presence) == 1
	var noop := risk_state.duplicate(true); noop["coins"] = 0; noop["even_guard_active"] = true; noop["current_lap_clean"] = true; noop["current_lap_penalty_count"] = 0; noop["applied_resolution_ids"] = []
	RewardResolverScript.apply(noop, RewardResolverScript.resolve_risk(noop, "qa-risk-noop", 44))
	var noop_ok := bool(noop.current_lap_clean) and bool(noop.even_guard_active) and int(noop.current_lap_penalty_count) == 0
	var guarded := noop.duplicate(true); guarded["coins"] = 20; guarded["applied_resolution_ids"] = []
	RewardResolverScript.apply(guarded, RewardResolverScript.resolve_risk(guarded, "qa-risk-guard", 44))
	var guard_ok := int(guarded.coins) == 20 and bool(guarded.current_lap_clean) and not bool(guarded.even_guard_active)
	GameState.apply_dictionary(original)
	GameState.current_lap_clean = false; GameState.current_lap_penalty_count = 3; GameState.clean_streak = 4; GameState.even_guard_active = true
	var saved := SaveManager.save_now()
	GameState.current_lap_clean = true; GameState.current_lap_penalty_count = 0; GameState.clean_streak = 0; GameState.even_guard_active = false
	var restored := SaveManager.load_now() and not GameState.current_lap_clean and GameState.current_lap_penalty_count == 3 and GameState.clean_streak == 4 and GameState.even_guard_active
	var v5_clean_missing := original.duplicate(true); v5_clean_missing["version"] = 5
	for clean_key: String in ["current_lap_clean", "current_lap_penalty_count", "clean_streak", "even_guard_active", "best_clean_streak"]: v5_clean_missing.erase(clean_key)
	GameState.apply_dictionary(v5_clean_missing)
	var migration_ok := GameState.current_lap_clean and GameState.current_lap_penalty_count == 0 and GameState.clean_streak == 0 and not GameState.even_guard_active and GameState.best_clean_streak == 0 and int(GameState.to_dictionary().version) == 10
	var passed := clean_ok and dirty_ok and boundaries_ok and risk_ok and noop_ok and guard_ok and saved and restored and migration_ok
	print("QA_CLEAN_LAP clean=%s dirty=%s boundaries=%s risks=%s noop=%s guard=%s save=%s migration=%s passed=%s" % [clean_ok, dirty_ok, boundaries_ok, risk_ok, noop_ok, guard_ok, restored, migration_ok, passed])
	GameState.apply_dictionary(original); SaveManager.save_now()
	if not passed: push_error("CLEAN deterministic QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_clean_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.total_lap_points = 12450
	GameState.lap_count = 3
	GameState.clean_streak = 2
	GameState.current_lap_clean = kind != "dirty"
	GameState.current_tile_index = 43
	show_game()
	if kind == "lap":
		_build_lap_result_modal({"lap_number": 4, "base_points": 100, "lap_bonus": 85, "clean": true, "clean_streak": 3, "multiplier": 1.5, "points": 277, "score": 337, "roll_count": 11, "next_clean_goal": "あと2回でCLEAN STREAK 5"})
	for ignored: int in range(12): await get_tree().process_frame
	await get_tree().create_timer(0.22).timeout
	var result := _save_opaque_capture(path)
	print("QA_CLEAN_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_roll_transaction() -> void:
	var original: Dictionary = GameState.to_dictionary().duplicate(true)
	var coin_tile := tile_types.find(&"COIN")
	var start_tile := posmod(coin_tile - 1, BoardModelScript.TILE_COUNT)
	var roles := DiceLogicScript.evaluate_current([1], 1)
	var checks: Array[bool] = []

	GameState.reset_run()
	GameState.current_tile_index = start_tile
	GameState.begin_roll_transaction([], 1, start_tile)
	GameState.mark_roll_started([1])
	SaveManager.save_now()
	var rolling_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(rolling_loaded and GameState.current_tile_index == start_tile and GameState.rolls_used == 0 and GameState.roll_transaction.is_empty())

	GameState.reset_run()
	GameState.current_tile_index = start_tile
	GameState.begin_roll_transaction([1], 1, start_tile)
	GameState.commit_roll_result([1], 1, roles, 1, coin_tile, 0, true)
	SaveManager.save_now()
	var result_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(result_loaded and dice_values == [1] and GameState.current_tile_index == coin_tile and GameState.rolls_used == 1 and GameState.coins == 18 and GameState.roll_transaction.is_empty())

	GameState.reset_run()
	GameState.current_tile_index = coin_tile
	GameState.rolls_used = 1
	GameState.begin_roll_transaction([1], 1, start_tile)
	GameState.commit_roll_result([1], 1, roles, 1, coin_tile, 0, false)
	GameState.commit_roll_movement(coin_tile)
	SaveManager.save_now()
	var movement_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(movement_loaded and GameState.current_tile_index == coin_tile and GameState.rolls_used == 1 and GameState.coins == 18 and GameState.roll_transaction.is_empty())

	GameState.reset_run()
	GameState.current_tile_index = coin_tile
	GameState.rolls_used = 1
	GameState.begin_roll_transaction([1], 1, start_tile)
	GameState.commit_roll_result([1], 1, roles, 1, coin_tile, 0, false)
	GameState.commit_roll_movement(coin_tile)
	GameState.commit_roll_space_effect()
	SaveManager.save_now()
	var effect_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(effect_loaded and GameState.current_tile_index == coin_tile and GameState.rolls_used == 1 and GameState.coins == 12 and GameState.roll_transaction.is_empty())

	# Interruption after the synchronous COIN mutation but before the result
	# hold finishes must observe the durable landing receipt and never add +6
	# a second time.
	GameState.reset_run()
	GameState.current_tile_index = coin_tile
	GameState.rolls_used = 1
	GameState.begin_roll_transaction([1], 1, start_tile)
	GameState.commit_roll_result([1], 1, roles, 1, coin_tile, 0, false)
	GameState.commit_roll_movement(coin_tile)
	GameState.commit_roll_landing_roles()
	GameState.coins += 6
	_commit_landing_core(&"COIN", "古い旅コインを拾った。+6")
	var coin_core_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(coin_core_loaded and GameState.coins == 18 and GameState.current_tile_index == coin_tile and GameState.roll_transaction.is_empty())

	# RISK harm is already resolution-idempotent; the landing receipt also
	# prevents reopening the branch after its result was saved.
	GameState.reset_run()
	GameState.current_tile_index = 58
	GameState.rolls_used = 1
	GameState.begin_roll_transaction([1], 1, 57)
	GameState.commit_roll_result([1], 1, roles, 1, 58, 0, false)
	GameState.commit_roll_movement(58)
	GameState.commit_roll_landing_roles()
	var risk_memo := _apply_risk_harm(58)
	_commit_landing_core(&"RISK", risk_memo)
	var risk_core_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(risk_core_loaded and GameState.current_lap_penalty_count == 1 and not GameState.current_lap_clean and GameState.current_tile_index == 55 and GameState.roll_transaction.is_empty())

	# LANDMARK reward and its receipt share one save boundary, so reopening
	# after reward application cannot develop the landmark twice.
	GameState.reset_run()
	GameState.current_tile_index = 0
	GameState.rolls_used = 1
	GameState.begin_roll_transaction([1], 1, 89)
	GameState.commit_roll_result([1], 1, roles, 1, 0, 0, false)
	GameState.commit_roll_movement(0)
	GameState.commit_roll_landing_roles()
	var landmark_state := GameState.to_dictionary()
	var landmark_resolution := LandmarkSystemScript.resolve_stop(landmark_state, 0, "qa-03b-landmark")
	RewardResolverScript.apply(landmark_state, landmark_resolution, GameState.reward_apply_log)
	GameState.apply_dictionary(landmark_state)
	_commit_landing_core(&"LANDMARK", "ギザの大スフィンクス Lv.1　旅の記憶 +1")
	var landmark_core_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(landmark_core_loaded and int(GameState.landmark_levels.get("CAI_LANDMARK_01", 0)) == 1 and GameState.roll_transaction.is_empty())

	# Crossing 90 -> 01 from a committed result applies the lap exactly once.
	GameState.reset_run()
	GameState.current_tile_index = 89
	GameState.begin_roll_transaction([2], 1, 89)
	GameState.commit_roll_result([2], 1, DiceLogicScript.evaluate_current([2], 1), 2, 1, 1, false)
	SaveManager.save_now()
	var lap_loaded := SaveManager.load_now()
	show_game()
	await _resume_roll_transaction()
	checks.append(lap_loaded and GameState.current_tile_index == 1 and GameState.rolls_used == 1 and GameState.total_laps == 1 and GameState.roll_transaction.is_empty())

	# EVENT -> boss: the pending boolean may already be consumed while the
	# durable encounter substate still knows exactly which window to resume.
	GameState.reset_run()
	GameState.current_tile_index = coin_tile
	GameState.begin_roll_transaction([1], 1, start_tile)
	GameState.commit_roll_result([1], 1, roles, 1, coin_tile, 0, false)
	GameState.commit_roll_movement(coin_tile)
	var handoff_reserved := GameState.mark_roll_encounter_handoff(true, 2)
	GameState.pending_boss_handoff = true
	var modal_opened := GameState.mark_roll_encounter_open(true, 2)
	GameState.pending_boss_handoff = false
	SaveManager.save_now()
	var consumed_loaded := SaveManager.load_now()
	checks.append(handoff_reserved and modal_opened and consumed_loaded and not GameState.pending_boss_handoff and str(GameState.roll_transaction.get("encounter_phase", "")) == "MODAL_OPEN" and bool(GameState.roll_transaction.get("encounter_pair_bonus", false)) and int(GameState.roll_transaction.get("encounter_double_bonus", 0)) == 2)

	# The companion and the next individual are one persisted boundary. A
	# restart here must display the saved card, never register or advance again.
	var interaction_committed := GameState.commit_roll_encounter_interaction(true, "sleepy_sphinx")
	GameState.current_boss["gauge"] = 100
	GameState.register_current_boss()
	var obtained := GameState.current_boss.duplicate(true)
	GameState.begin_next_boss()
	var registration_committed := GameState.commit_roll_encounter_registration(obtained)
	var next_id := str(GameState.current_boss.get("individual_id", ""))
	var encyclopedia_count := GameState.encyclopedia.size()
	SaveManager.save_now()
	var registration_loaded := SaveManager.load_now()
	checks.append(interaction_committed and registration_committed and registration_loaded and str(GameState.roll_transaction.get("encounter_phase", "")) == "REGISTRATION_COMMITTED" and str(GameState.current_boss.get("individual_id", "")) == next_id and GameState.encyclopedia.size() == encyclopedia_count and str(GameState.roll_transaction.get("encounter_obtained", {}).get("individual_id", "")) == str(obtained.get("individual_id", "")))

	# Finalizing a recovered get-result choice must not call show_game; it only
	# closes the durable transaction so the already selected route stays visible.
	_finalize_recovered_roll_without_navigation()
	checks.append(GameState.roll_transaction.is_empty() and GameState.encyclopedia.size() == encyclopedia_count and str(GameState.current_boss.get("individual_id", "")) == next_id)

	var passed := coin_tile >= 0 and checks.all(func(value: bool) -> bool: return value)
	print("QA_ROLL_TRANSACTION coin_tile=%d checks=%s passed=%s" % [coin_tile, checks, passed])
	GameState.apply_dictionary(original)
	SaveManager.save_now()
	if not passed:
		push_error("Roll transaction recovery QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_lap_landmark() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	GameState.reset_run()
	GameState.total_lap_points = 0
	GameState.total_laps = 0
	GameState.best_lap_score = 0
	GameState.landmark_levels = GameState.DEFAULT_LANDMARK_LEVELS.duplicate(true)
	GameState.stage_development = 0
	GameState.registered_postcards.clear()
	GameState.applied_resolution_ids.clear()
	GameState.reward_apply_log.clear()
	GameState.current_tile_index = 89
	GameState.current_dice_count = 1
	GameState.clean_streak = 0
	show_game()
	await _resolve_roll([1])
	var normal_once := GameState.lap_count == 1 and GameState.total_laps == 1 and GameState.total_lap_points == 124
	var tile_zero_once := int(GameState.landmark_levels.get("CAI_LANDMARK_01", 0)) == 1 and GameState.souvenirs == 1 and GameState.coins == 47
	var normal_loop_reset := not GameState.rare_event_used_this_loop and GameState.events_seen_this_loop.is_empty() and GameState.events_since_rare == 99
	var levels_after_normal := GameState.landmark_levels.duplicate(true)
	var points_before_warp := GameState.total_lap_points
	GameState.reset_run()
	GameState.current_tile_index = 87
	GameState.clean_streak = 0
	show_game()
	await _resolve_landing(&"WARP", {"main": &"", "support": &"", "labels": []})
	var warp_once := GameState.lap_count == 1 and GameState.current_tile_index == 3 and GameState.total_lap_points == points_before_warp + 124
	var warp_no_landmark := GameState.landmark_levels == levels_after_normal
	var warp_loop_reset := not GameState.rare_event_used_this_loop and GameState.events_seen_this_loop.is_empty() and GameState.events_since_rare == 99

	var idempotent_state := GameState.to_dictionary()
	idempotent_state["landmark_levels"] = GameState.DEFAULT_LANDMARK_LEVELS.duplicate(true)
	idempotent_state["current_dice_count"] = 1
	idempotent_state["coins"] = 0
	idempotent_state["registered_postcards"] = []
	idempotent_state["current_lap_bonus"] = 0
	idempotent_state["applied_resolution_ids"] = []
	var landmark_duplicate_stable: bool = true
	for level_index: int in range(3):
		var landmark_resolution := LandmarkSystemScript.resolve_stop(idempotent_state, 0, "qa-landmark-%d" % level_index)
		RewardResolverScript.apply(idempotent_state, landmark_resolution)
		var landmark_snapshot := {
			"coins": int(idempotent_state.coins),
			"dice": int(idempotent_state.current_dice_count),
			"postcards": (idempotent_state.registered_postcards as Array).duplicate(),
			"bonus": int(idempotent_state.current_lap_bonus),
		}
		RewardResolverScript.apply(idempotent_state, landmark_resolution)
		if landmark_snapshot != {"coins": int(idempotent_state.coins), "dice": int(idempotent_state.current_dice_count), "postcards": (idempotent_state.registered_postcards as Array).duplicate(), "bonus": int(idempotent_state.current_lap_bonus)}:
			landmark_duplicate_stable = false
			push_error("Landmark idempotency snapshot changed.")
	var landmark_idempotent: bool = landmark_duplicate_stable and int(idempotent_state.landmark_levels.CAI_LANDMARK_01) == 3 and idempotent_state.registered_postcards == ["cairo_spice_market_complete"]
	var lap_resolution := LapSystemScript.resolve(idempotent_state, "qa-lap-idempotent", "NORMAL")
	RewardResolverScript.apply(idempotent_state, lap_resolution)
	var lap_snapshot := {"points": int(idempotent_state.total_lap_points), "coins": int(idempotent_state.coins), "dice": int(idempotent_state.current_dice_count), "postcards": (idempotent_state.registered_postcards as Array).duplicate()}
	var lap_second := RewardResolverScript.apply(idempotent_state, lap_resolution)
	var lap_idempotent := not bool(lap_second.applied) and lap_snapshot == {"points": int(idempotent_state.total_lap_points), "coins": int(idempotent_state.coins), "dice": int(idempotent_state.current_dice_count), "postcards": (idempotent_state.registered_postcards as Array).duplicate()}

	GameState.total_lap_points = 432
	GameState.landmark_levels = {"CAI_LANDMARK_01": 3, "CAI_LANDMARK_02": 2, "CAI_LANDMARK_03": 1}
	GameState.current_lap_bonus = 28
	var saved := SaveManager.save_now()
	GameState.total_lap_points = 0; GameState.landmark_levels = GameState.DEFAULT_LANDMARK_LEVELS.duplicate(true); GameState.current_lap_bonus = 0
	var restored := SaveManager.load_now() and GameState.total_lap_points == 432 and int(GameState.landmark_levels.CAI_LANDMARK_01) == 3 and int(GameState.landmark_levels.CAI_LANDMARK_02) == 2 and GameState.current_lap_bonus == 28
	var legacy := GameState.to_dictionary().duplicate(true)
	legacy["version"] = 5
	for key: String in ["total_lap_points", "current_lap_bonus", "current_lap_roll_count", "current_lap_clean", "current_lap_penalty_count", "clean_streak", "flow_level", "flow_triggered_this_turn", "flow_reward_3_claimed_this_lap", "flow_reward_5_claimed_this_lap", "even_guard_active", "best_lap_score", "best_clean_streak", "best_flow_level", "total_laps", "highest_laps_in_one_journey", "pending_lap_rewards", "lap_resolution_id", "lap_reward_committed", "last_lap_result", "landmark_levels", "landmark_revisit_stamps", "landmark_collection_flags", "landmark_completion_flags", "stage_development", "stage_development_milestones_claimed", "stage_collection_count", "stage_collection_completed", "pending_landmark_rewards", "landmark_resolution_id", "landmark_reward_committed"]:
		legacy.erase(key)
	legacy["current_dice_count"] = 2
	legacy["master_volume"] = 0.37
	GameState.apply_dictionary(legacy)
	var migration := GameState.total_lap_points == 0 and GameState.landmark_levels == GameState.DEFAULT_LANDMARK_LEVELS and GameState.current_dice_count == 2 and is_equal_approx(GameState.master_volume, 0.37) and not GameState.current_boss.is_empty()
	var passed: bool = normal_once and tile_zero_once and normal_loop_reset and warp_once and warp_no_landmark and warp_loop_reset and landmark_idempotent and lap_idempotent and saved and restored and migration
	print("QA_LAP_LANDMARK normal=%s tile0=%s warp=%s warp_no_landmark=%s idempotent=%s/%s save=%s migration=%s passed=%s" % [normal_once and normal_loop_reset, tile_zero_once, warp_once and warp_loop_reset, warp_no_landmark, landmark_idempotent, lap_idempotent, restored, migration, passed])
	GameState.apply_dictionary(original); SaveManager.save_now()
	if not passed: push_error("LAP/LANDMARK deterministic QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_lap_landmark_capture(kind: String, path: String) -> void:
	GameState.reset_run()
	GameState.total_lap_points = 12450
	GameState.lap_count = 2
	GameState.landmark_levels = {"CAI_LANDMARK_01": 3, "CAI_LANDMARK_02": 2, "CAI_LANDMARK_03": 1}
	GameState.stage_development = 6
	GameState.current_tile_index = 22
	show_game()
	if kind == "landmark":
		_build_landmark_result_modal({"name": "夕映えの展望広場", "old_level": 1, "new_level": 2, "developed": true}, ["名所 Lv.2", "追加ダイス +1", "ラップボーナス +8"])
	elif kind == "lap":
		_build_lap_result_modal({"lap_number": 3, "base_points": 100, "lap_bonus": 46, "points": 146, "score": 206, "roll_count": 12})
	for ignored: int in range(12): await get_tree().process_frame
	await get_tree().create_timer(0.22).timeout
	var result := _save_opaque_capture(path)
	print("QA_LAP_LANDMARK_CAPTURE kind=%s path=%s result=%s" % [kind, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_spice_scenic() -> void:
	var original := GameState.to_dictionary().duplicate(true)
	var assets_ok := true
	for level: int in range(4):
		var asset_path := "res://assets/art/landmarks/cairo/spice_market_lv%d.png" % level
		var image := Image.load_from_file(ProjectSettings.globalize_path(asset_path))
		var valid := image != null and image.get_size() == Vector2i(1024, 512) and image.get_pixel(0, 0).a < 0.05 and image.get_pixel(1023, 0).a < 0.05
		assets_ok = assets_ok and valid
	GameState.reset_run()
	GameState.current_tile_index = 0
	show_game()
	var levels_ok := true
	for level: int in range(4):
		GameState.landmark_levels["CAI_LANDMARK_01"] = level
		board_view.set_landmark_levels(GameState.landmark_levels)
		await get_tree().process_frame
		var expected_path := "res://assets/art/landmarks/cairo/spice_market_lv%d.png" % level
		levels_ok = levels_ok and board_view.scenic_level == level and board_view.mouse_filter == Control.MOUSE_FILTER_IGNORE and board_view.scenic_texture != null and board_view.scenic_texture.resource_path == expected_path
	GameState.current_tile_index = 6
	board_view.set_current_tile(6)
	await get_tree().process_frame
	var hidden_outside_neighborhood := board_view.scenic_texture == null
	GameState.current_tile_index = 89
	board_view.set_current_tile(89)
	await get_tree().process_frame
	var visible_across_loop := board_view.scenic_texture != null
	var passed := assets_ok and levels_ok and hidden_outside_neighborhood and visible_across_loop
	print("QA_SPICE_SCENIC assets=%s levels=%s hidden=%s wrapped=%s passed=%s" % [assets_ok, levels_ok, hidden_outside_neighborhood, visible_across_loop, passed])
	GameState.apply_dictionary(original)
	if not passed: push_error("Spice scenic QA failed.")
	get_tree().quit(0 if passed else 1)

func _qa_spice_scenic_capture(level_text: String, path: String) -> void:
	GameState.reset_run()
	var level := clampi(int(level_text), 0, 3)
	GameState.total_lap_points = 12450
	GameState.lap_count = 2
	GameState.current_tile_index = 0
	GameState.landmark_levels = {"CAI_LANDMARK_01": level, "CAI_LANDMARK_02": 2, "CAI_LANDMARK_03": 1}
	GameState.stage_development = level + 3
	show_game()
	for ignored: int in range(12): await get_tree().process_frame
	await get_tree().create_timer(0.28).timeout
	var result := _save_opaque_capture(path)
	print("QA_SPICE_SCENIC_CAPTURE level=%d path=%s result=%s" % [level, path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_premium_board_capture(path: String) -> void:
	GameState.reset_run(); GameState.current_dice_count = 2; GameState.current_tile_index = 58; show_game()
	for ignored: int in range(10): await get_tree().process_frame
	var result := _save_opaque_capture(path)
	print("QA_PREMIUM_BOARD_CAPTURE path=%s result=%s" % [path, result])
	get_tree().quit(0 if result == OK else 1)

func _qa_capture_viewport(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(path)
	print("QA_CAPTURE path=%s result=%s size=%s" % [path, result, image.get_size()])
	get_tree().quit(0 if result == OK else 1)

func _save_opaque_capture(path: String) -> Error:
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		return ERR_CANT_CREATE
	var source := viewport_texture.get_image()
	if source == null:
		return ERR_CANT_CREATE
	if source.get_size() != Vector2i(360, 640): source.resize(360, 640, Image.INTERPOLATE_LANCZOS)
	var opaque := Image.create(360, 640, false, Image.FORMAT_RGBA8)
	opaque.fill(BG)
	opaque.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i.ZERO)
	opaque.convert(Image.FORMAT_RGB8)
	if path.get_extension().to_lower() in ["jpg", "jpeg"]:
		return opaque.save_jpg(path, 0.96)
	return opaque.save_png(path)
