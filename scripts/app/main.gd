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
const BossSystemScript = preload("res://scripts/game/boss_system.gd")
const EventSystemScript = preload("res://scripts/game/event_system.gd")
const RewardResolverScript = preload("res://scripts/game/reward_resolver.gd")
const LapSystemScript = preload("res://scripts/game/lap_system.gd")
const LandmarkSystemScript = preload("res://scripts/game/landmark_system.gd")
const DiceAudioControllerScript = preload("res://scripts/game/dice_audio_controller.gd")
const DicePresentation3DScript = preload("res://scripts/game/dice_presentation_3d.gd")
const CAIRO_BACKGROUND: Texture2D = preload("res://assets/art/backgrounds/cairo-board.png")
const SPHINX_TEXTURE: Texture2D = preload("res://assets/art/bosses/sleepy-sphinx.png")

const BG := Color("#efe2c6")
const INK := Color("#4c3c2e")
const TEAL := Color("#287b80")
const GOLD := Color("#c79c48")
const MUTED := Color("#8c7862")

var rng := RandomNumberGenerator.new()
var root_stack: VBoxContainer
var board_view: BoardView
var dice_row: HBoxContainer
var dice_presentation: SubViewportContainer
var dice_audio: Node
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

func _ready() -> void:
	rng.seed = 20260711
	tile_types = BoardModelScript.build_tile_types()
	boss_definitions = BossSystemScript.definitions()
	event_definitions = EventSystemScript.definitions()
	GameState.ensure_boss_data()
	_apply_theme()
	match OS.get_environment("DICE_QA_SCREEN"):
		"stage": show_stage_select()
		"character": show_character_select()
		"game": show_game()
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
	elif OS.get_environment("DICE_QA_SPICE_SCENIC") == "1":
		call_deferred("_qa_spice_scenic")
	elif OS.get_environment("DICE_QA_CAPTURE_SPICE_SCENIC") != "":
		call_deferred("_qa_spice_scenic_capture", OS.get_environment("DICE_QA_CAPTURE_SPICE_SCENIC"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif OS.get_environment("DICE_QA_CAPTURE_LAP_LANDMARK") != "":
		call_deferred("_qa_lap_landmark_capture", OS.get_environment("DICE_QA_CAPTURE_LAP_LANDMARK"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	elif GameState.pending_boss_handoff:
		call_deferred("_resume_pending_boss_handoff")
	elif not GameState.active_event_state.is_empty():
		call_deferred("_resume_active_event")
	elif OS.get_environment("DICE_QA_CAPTURE_M3") != "":
		call_deferred("_qa_m3_capture", OS.get_environment("DICE_QA_CAPTURE_M3"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	if OS.get_environment("DICE_QA_CAPTURE_M3").is_empty() and OS.get_environment("DICE_QA_CAPTURE_M4A").is_empty() and OS.get_environment("DICE_QA_CAPTURE_DICE").is_empty() and OS.get_environment("DICE_QA_CAPTURE_PROGRESSION").is_empty() and OS.get_environment("DICE_QA_CAPTURE_PREMIUM_BOARD").is_empty() and OS.get_environment("DICE_QA_CAPTURE_LAP_LANDMARK").is_empty() and OS.get_environment("DICE_QA_CAPTURE_SPICE_SCENIC").is_empty() and not OS.get_environment("DICE_QA_CAPTURE_PATH").is_empty():
		call_deferred("_qa_capture_viewport", OS.get_environment("DICE_QA_CAPTURE_PATH"))

func _apply_theme() -> void:
	var app_theme := Theme.new()
	app_theme.default_font_size = 24
	app_theme.set_color("font_color", "Label", INK)
	app_theme.set_color("font_color", "Button", INK)
	app_theme.set_color("font_hover_color", "Button", TEAL)
	app_theme.set_font_size("font_size", "Button", 24)
	theme = app_theme

func _clear() -> void:
	if is_instance_valid(dice_audio): dice_audio.stop_all()
	for child: Node in get_children():
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
		if GameState.pending_boss_handoff: call_deferred("_resume_pending_boss_handoff")
		elif not GameState.active_event_state.is_empty(): call_deferred("_resume_active_event"))
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
	var page := _make_page()
	page.add_child(_title("旅先を選ぶ", 46))
	page.add_child(_body("古い地図の上に、一枚だけ明るい切符がある。", 20))
	page.add_child(_spacer(35))
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 14)
	card.add_child(_title("砂時計のカイロ", 40))
	card.add_child(_body("市場、オアシス、遺跡をめぐる\nゆったり旅", 24))
	GameState.ensure_boss_data()
	card.add_child(_body("いま気になる相手　%s\nルート　90マスの一周" % str(GameState.current_boss.get("name", "眠そうなスフィンクス")), 21))
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(card)
	page.add_child(_body("月夜のパリ　　桜風の東京\n雨粒のシンガポール　Coming Soon", 19))
	page.add_child(_button("この旅へ", show_character_select, true))
	page.add_child(_button("もどる", show_title))

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

func show_game() -> void:
	var page := _make_page()
	dice_audio = DiceAudioControllerScript.new()
	dice_audio.name = "DiceAudioController"
	add_child(dice_audio)
	dice_audio.set_levels(GameState.master_volume, GameState.se_volume, GameState.dice_se_muted)
	page.add_theme_constant_override("separation", 6)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	var lap_pill := _pill(""); lap_label = lap_pill.label; (lap_pill.panel as PanelContainer).size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(lap_pill.panel)
	var stage_title := _title("砂時計のカイロ", 26); stage_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(stage_title)
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

	board_view = BoardViewScript.new()
	board_view.custom_minimum_size = Vector2(0, 390)
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.configure(tile_types, GameState.current_tile_index, GameState.landmark_levels)
	page.add_child(board_view)
	var memo_panel := PanelContainer.new(); memo_panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.97, 0.91, 0.79, 0.92), Color("#b28a52"), 14))
	memo_label = _body("風が砂の上に細い道を描いている。", 16); memo_label.custom_minimum_size.y = 30; memo_panel.add_child(memo_label); page.add_child(memo_panel)

	var tray_panel := PanelContainer.new(); tray_panel.add_theme_stylebox_override("panel", _premium_panel(Color("#765737"), Color("#d1a552"), 22))
	var tray_box := VBoxContainer.new(); tray_box.add_theme_constant_override("separation", 3); tray_panel.add_child(tray_box)
	var tray_header := HBoxContainer.new()
	var tray_title := _body("今回のダイス", 15); tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; tray_title.add_theme_color_override("font_color", Color("#f6dfad")); tray_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tray_header.add_child(tray_title)
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
	dice_values = await _animate_dice_roll(dice_mode)
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
	roll_button.text = "タップで左から止める"
	stop_all_button.visible = extra_controls_parent == null
	if extra_controls_parent != null:
		var controls := HBoxContainer.new(); controls.name = "extra_dice_stop_controls"; controls.add_theme_constant_override("separation", 10)
		active_extra_left_stop = _button("左から1個停止", func() -> void: _lock_next_die(false), true)
		active_extra_all_stop = _button("残りを一括停止", _stop_all_dice)
		active_extra_left_stop.name = "extra_left_stop"; active_extra_all_stop.name = "extra_all_stop"
		active_extra_left_stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL; active_extra_all_stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.add_child(active_extra_left_stop); controls.add_child(active_extra_all_stop); extra_controls_parent.add_child(controls)
	role_label.text = "目を追えば、少しだけ狙えるかも"
	# 0.8-1.3 seconds for an untouched roll across 1/2/3/5 dice. The final
	# presentation settle continues independently for another 0.18 seconds.
	for frame: int in range(26):
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
	moving = false
	if is_instance_valid(dice_audio): dice_audio.end_roll()
	roll_button.text = "サイコロを振る"
	stop_all_button.visible = false
	if is_instance_valid(active_extra_left_stop): active_extra_left_stop.disabled = true
	if is_instance_valid(active_extra_all_stop): active_extra_all_stop.disabled = true
	active_extra_left_stop = null; active_extra_all_stop = null
	return rolling_values.duplicate()

func _lock_next_die(automatic: bool) -> void:
	if not rolling_dice or locked_dice_count >= rolling_values.size():
		return
	var index := locked_dice_count
	if index < fixed_targets.size():
		rolling_values[index] = clampi(fixed_targets[index], 1, 6)
	locked_dice_count += 1
	_render_dice(rolling_values, false)
	if is_instance_valid(dice_audio): dice_audio.play_land(index, 0.76 if not automatic else 0.62)
	if not automatic:
		last_roll_early_stopped = true
		role_label.text = "%d個目を早止め" % locked_dice_count

func _stop_all_dice() -> void:
	if not rolling_dice or locked_dice_count >= rolling_values.size(): return
	var remaining := rolling_values.size() - locked_dice_count
	while locked_dice_count < rolling_values.size(): _lock_next_die(false)
	role_label.text = "残り%d個を現在の目で一括停止" % remaining

func _render_dice(values: Array[int], selectable: bool) -> void:
	if is_instance_valid(dice_presentation):
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
	var rolled_dice_count := dice_mode
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
	if roles.get("main", &"") == DiceLogicScript.TRIPLE:
		GameState.boss_presence = 5
	# Consume the rolled state before landing rewards. An item/event DICE_ADD_1
	# therefore builds on the post-roll base (for example 2 miss -> 1 -> +1 = 2).
	GameState.apply_dice_roll_transition(rolled_dice_count, roles)
	var distance: int = 0
	for value: int in values:
		distance += value
	if GameState.next_move_bonus > 0:
		distance += GameState.next_move_bonus
		GameState.next_move_bonus = 0
	var crossed_laps := 0
	for step: int in range(distance):
		var next_index := posmod(GameState.current_tile_index + 1, BoardModelScript.TILE_COUNT)
		if next_index == 0:
			crossed_laps += 1
		GameState.current_tile_index = next_index
		board_view.set_current_tile(next_index)
		minimap_view.set_current_tile(next_index)
		await get_tree().create_timer(0.035).timeout
	GameState.rolls_used += 1
	# Most destinations start in the fresh event loop. Tile 0 is also a
	# LANDMARK, so its STOP reward is resolved first and folded into that lap.
	if crossed_laps > 0 and GameState.current_tile_index != 0:
		await _commit_lap_crossings(crossed_laps, "NORMAL")
	await _resolve_landing(tile_types[GameState.current_tile_index], roles)
	if crossed_laps > 0 and GameState.current_tile_index == 0:
		await _commit_lap_crossings(crossed_laps, "NORMAL")
	dice_mode = clampi(GameState.current_dice_count, 1, 3)
	SaveManager.save_now()
	_refresh_hud()
	moving = false
	roll_button.disabled = false

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
	var memo := ""
	match tile_type:
		&"NORMAL":
			memo = ["日陰で猫があくびをした。", "砂の向こうで鐘が一度鳴った。", "冷たい風が市場から届いた。"][rng.randi_range(0, 2)]
		&"EVENT":
			var boss_handoff := await _show_event_modal(roles)
			memo = "短い旅の出来事を記録した。"
			if boss_handoff:
				GameState.travel_memos.append(memo)
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
			SaveManager.save_now()
			var landmark_result: Dictionary = landmark_resolution.get("result", {})
			memo = "%s Lv.%d　旅の記憶 +1" % [str(landmark_result.get("name", "カイロの名所")), int(landmark_result.get("new_level", 0))]
			if bool(landmark_applied.get("applied", false)):
				await _show_landmark_result_modal(landmark_result, landmark_applied.get("summary", []))
		&"BOSS_SCENT":
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 2)
			memo = ["砂の上に、大きな足跡が残っている。", "遠くから、低いあくびが聞こえた。", "誰かがここで、しばらく昼寝をしていたらしい。 "][rng.randi_range(0, 2)]
		&"STAGE_SPECIAL":
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
			memo = "砂時計の影が道を横切った。カイロの気配 +1"
		&"RISK":
			memo = await _show_risk_space_modal()
	if roles.get("main", &"") == DiceLogicScript.PAIR:
		GameState.souvenirs += 1
		memo += "　PAIRのおみやげ +1"
	if roles.get("main", &"") == DiceLogicScript.STRAIGHT:
		GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
		memo += "　STRAIGHTで気配が近づいた。"
	if roles.get("main", &"") == DiceLogicScript.DOUBLE:
		GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
		memo += "　DOUBLEでDICE SLOT READY。気配も近づいた。"
	GameState.travel_memos.append(memo)
	memo_label.text = memo
	await get_tree().create_timer(0.18).timeout
	# TRIPLE always invites one encounter after landing, even on a special space.
	# Normal-space chance rolls are never layered on top of that certain encounter.
	var triple_forced: bool = roles.get("main", &"") == DiceLogicScript.TRIPLE
	if triple_forced:
		await _show_encounter_modal(false)
	elif tile_type == &"NORMAL":
		var forced: bool = GameState.debug_force_encounter
		GameState.debug_force_encounter = false
		var appears := BossSystemScript.should_encounter(GameState.boss_presence, GameState.boss_relief, forced, rng.randf())
		if appears:
			var pair_bonus: bool = roles.get("main", &"") == DiceLogicScript.PAIR
			await _show_encounter_modal(pair_bonus, 2 if roles.get("main", &"") == DiceLogicScript.DOUBLE else 0)
		else:
			GameState.boss_relief = mini(BossSystemScript.RELIEF_FORCE_AFTER, GameState.boss_relief + 1)
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)

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
	content.add_child(_body("基本 %d　＋　ラップボーナス %d\nラップスコア %d　（%dロール）" % [int(result.get("base_points", 100)), int(result.get("lap_bonus", 0)), int(result.get("score", 0)), int(result.get("roll_count", 0))], 19))
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

func _show_risk_space_modal() -> String:
	var base_dice_before := GameState.current_dice_count
	var modal := _make_modal()
	var content: VBoxContainer = modal.content
	content.add_child(_title("砂塵の抜け道", 32))
	content.add_child(_body("安全な足場を進むか、砂の向こうへ3ダイスを投げるか。\n挑戦しても今のダイスは失いません。", 20))
	var safe := _button("安全策　追加ダイス +1", func() -> void: return, true); safe.name = "risk_safe"; safe.toggle_mode = true
	var challenge := _button("挑戦　追加3ダイス", func() -> void: return); challenge.name = "risk_challenge"; challenge.toggle_mode = true
	content.add_child(safe); content.add_child(challenge)
	var chosen := await _wait_for_action([safe, challenge])
	safe.disabled = true; challenge.disabled = true
	var memo := ""
	if chosen == 0:
		var before := GameState.current_dice_count
		var before_coins := GameState.coins
		var after := GameState.add_dice()
		memo = "リスクマスの安全策。追加ダイス %d→%d" % [before, after] if after > before else "安全策の余剰ダイスを旅コイン +%dへ変換" % (GameState.coins - before_coins)
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
			GameState.coins += 5; memo = "砂の流れを読んだ。小さな旅コイン +5"
	# The risk branch may add dice, but never removes the state held on arrival.
	GameState.current_dice_count = maxi(base_dice_before, GameState.current_dice_count)
	content.add_child(_body(memo, 20))
	var close := _button("旅へ戻る", func() -> void: return, true); close.name = "risk_close"; close.toggle_mode = true; content.add_child(close)
	await close.pressed
	_close_modal(modal.layer)
	return memo

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
	await _show_encounter_modal(false)

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
		GameState.active_event_state.clear(); SaveManager.save_now(); _close_modal(modal.layer)
		return
	var arrival: Dictionary = saved.get("arrival", {})
	dice_values.assign(arrival.get("source_dice_values", [1, 2, 3]))
	GameState.debug_forced_event_id = str(saved.get("event_id", "CAI-E01"))
	var roles: Dictionary = arrival.get("source_roles", DiceLogicScript.evaluate(dice_values))
	await _show_event_modal(roles)

func _refresh_hud() -> void:
	if lap_label == null:
		return
	lap_label.text = "LAP POINT\n%d" % GameState.total_lap_points
	coin_label.text = "旅コイン %d" % GameState.coins
	rolls_label.text = "LAP %d　ターン %d / 36　現在 %dマス　次回 %dダイス" % [GameState.lap_count, GameState.rolls_used, GameState.current_tile_index + 1, clampi(GameState.current_dice_count, 1, 3)]
	if is_instance_valid(landmark_level_label):
		landmark_level_label.text = "全体マップ　名所 Lv.%d・%d・%d" % [int(GameState.landmark_levels.get("CAI_LANDMARK_01", 0)), int(GameState.landmark_levels.get("CAI_LANDMARK_02", 0)), int(GameState.landmark_levels.get("CAI_LANDMARK_03", 0))]
	if is_instance_valid(board_view): board_view.set_landmark_levels(GameState.landmark_levels)
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

func _show_get_result(definition: Dictionary) -> void:
	# The portrait changes warmth very slightly; the feeling is an invitation, never a battle win.
	var obtained := _prepare_next_boss_after_join()
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
			return
		if stage_select.button_pressed:
			_close_modal(modal.layer)
			SaveManager.save_now()
			show_stage_select()
			return
		await get_tree().process_frame

func _prepare_next_boss_after_join() -> Dictionary:
	GameState.register_current_boss()
	var obtained := GameState.current_boss.duplicate(true)
	# Advance and persist before offering either exit. Returning to stage select must never revive
	# an already registered individual on the next Cairo trip.
	GameState.begin_next_boss()
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
	return box

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
	GameState.fixed_rolls.assign([6, 6, 6, 1, 2])
	var before_rolls := GameState.rolls_used
	_on_roll_pressed()
	while rolling_dice:
		await get_tree().process_frame
	await get_tree().process_frame
	var selected_values: Array[int] = []
	for index: int in selected_indices:
		selected_values.append(dice_values[index])
	var selection_ok := selected_values == [6, 6, 6]
	_confirm_five()
	# TRIPLE now correctly opens the production encounter modal on any landing tile.
	# Drive that interaction so this M0-M2 regression can still finish under M3.
	while moving and not modal_open:
		await get_tree().process_frame
	if modal_open:
		while find_children("boss_action_0", "Button", true, false).is_empty():
			await get_tree().process_frame
		var action: Button = find_children("boss_action_0", "Button", true, false)[0]
		action.button_pressed = true
		while find_children("return_to_trip", "Button", true, false).is_empty():
			await get_tree().process_frame
		var return_button: Button = find_children("return_to_trip", "Button", true, false)[0]
		return_button.pressed.emit()
	while moving or rolling_dice:
		await get_tree().process_frame
	var passed := selection_ok and GameState.current_tile_index == 18 and GameState.rolls_used == before_rolls + 1
	print("QA_FIVE_DICE selected=%s tile=%d rolls_delta=%d passed=%s" % [selected_values, GameState.current_tile_index, GameState.rolls_used - before_rolls, passed])
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
	GameState.reset_run(); GameState.current_dice_count = 2; GameState.current_tile_index = 58; show_game()
	var before_count := GameState.current_dice_count
	var before_coins := GameState.coins
	if kind == "challenge": GameState.debug_fixed_extra_rolls.assign([1, 2, 6])
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
	if kind == "safe": passed = passed and count_before_close == 3
	else: passed = passed and count_before_close == 2 and coins_before_close == before_coins + 5
	print("QA_RISK kind=%s before=%d after=%d coins_delta=%d modal_closed=%s passed=%s" % [kind, before_count, count_before_close, coins_before_close - before_coins, not modal_open, passed])
	if not passed: push_error("Risk-space QA failed.")
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
	show_game()
	await _resolve_roll([1])
	var normal_once := GameState.lap_count == 1 and GameState.total_laps == 1 and GameState.total_lap_points == 108
	var tile_zero_once := int(GameState.landmark_levels.get("CAI_LANDMARK_01", 0)) == 1 and GameState.souvenirs == 1 and GameState.coins == 47
	var normal_loop_reset := not GameState.rare_event_used_this_loop and GameState.events_seen_this_loop.is_empty() and GameState.events_since_rare == 99
	var levels_after_normal := GameState.landmark_levels.duplicate(true)
	var points_before_warp := GameState.total_lap_points
	GameState.reset_run()
	GameState.current_tile_index = 87
	show_game()
	await _resolve_landing(&"WARP", {"main": &"", "support": &"", "labels": []})
	var warp_once := GameState.lap_count == 1 and GameState.current_tile_index == 3 and GameState.total_lap_points == points_before_warp + 108
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
	var source := get_viewport().get_texture().get_image()
	if source.get_size() != Vector2i(360, 640): source.resize(360, 640, Image.INTERPOLATE_LANCZOS)
	var opaque := Image.create(360, 640, false, Image.FORMAT_RGBA8)
	opaque.fill(BG)
	opaque.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i.ZERO)
	opaque.convert(Image.FORMAT_RGB8)
	return opaque.save_png(path)
