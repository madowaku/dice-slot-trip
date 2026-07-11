extends Control

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const BoardModelScript = preload("res://scripts/game/board_model.gd")
const BoardViewScript = preload("res://scripts/game/board_view.gd")
const BossSystemScript = preload("res://scripts/game/boss_system.gd")
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
var role_label: Label
var memo_label: Label
var roll_button: Button
var confirm_five_button: Button
var mode_label: Label
var boss_label: Label
var lap_label: Label
var rolls_label: Label
var coin_label: Label
var stamp_label: Label
var minimap_view: BoardView
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

func _ready() -> void:
	rng.seed = 20260711
	tile_types = BoardModelScript.build_tile_types()
	boss_definitions = BossSystemScript.definitions()
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
	elif OS.get_environment("DICE_QA_CAPTURE_M3") != "":
		call_deferred("_qa_m3_capture", OS.get_environment("DICE_QA_CAPTURE_M3"), OS.get_environment("DICE_QA_CAPTURE_PATH"))
	if OS.get_environment("DICE_QA_CAPTURE_M3").is_empty() and not OS.get_environment("DICE_QA_CAPTURE_PATH").is_empty():
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
	for child: Node in get_children():
		child.queue_free()
	root_stack = null

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
	artwork.modulate = Color(1.0, 1.0, 1.0, 0.48)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(artwork)
	var veil := ColorRect.new()
	veil.color = Color(0.96, 0.90, 0.78, 0.42)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 26)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	root_stack = VBoxContainer.new()
	root_stack.add_theme_constant_override("separation", 16)
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
		GameState.reset_run()
		show_stage_select(), true))
	var continue_button := _button("つづきから", func() -> void:
		SaveManager.load_now()
		show_game())
	continue_button.disabled = not SaveManager.has_save()
	page.add_child(continue_button)
	var utility := HBoxContainer.new()
	utility.add_theme_constant_override("separation", 16)
	var book := _button("図鑑", show_encyclopedia)
	var settings := _button("設定", func() -> void: _show_message("設定", "音量と演出速度はM3以降で調整できます。"))
	book.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility.add_child(book)
	utility.add_child(settings)
	page.add_child(utility)
	page.add_child(_body("オートセーブ対応", 18))

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
	page.add_theme_constant_override("separation", 7)
	var top_row := HBoxContainer.new()
	lap_label = _body("", 22)
	coin_label = _body("", 22)
	lap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(lap_label)
	top_row.add_child(_title("砂時計のカイロ", 29))
	minimap_view = BoardViewScript.new()
	minimap_view.is_minimap = true
	minimap_view.custom_minimum_size = Vector2(128, 84)
	minimap_view.configure(tile_types, GameState.current_tile_index)
	top_row.add_child(minimap_view)
	top_row.add_child(coin_label)
	page.add_child(top_row)
	var boss_row := HBoxContainer.new()
	boss_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var portrait := TextureRect.new()
	portrait.texture = SPHINX_TEXTURE
	portrait.custom_minimum_size = Vector2(76, 76)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_row.add_child(portrait)
	boss_label = _body("", 20)
	boss_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_row.add_child(boss_label)
	page.add_child(boss_row)
	stamp_label = _body("", 16)
	stamp_label.add_theme_color_override("font_color", MUTED)
	page.add_child(stamp_label)
	board_view = BoardViewScript.new()
	board_view.custom_minimum_size = Vector2(0, 520)
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.configure(tile_types, GameState.current_tile_index)
	page.add_child(board_view)
	memo_label = _body("風が砂の上に細い道を描いている。", 18)
	memo_label.custom_minimum_size.y = 42
	page.add_child(memo_label)
	dice_row = HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 8)
	page.add_child(dice_row)
	role_label = _title("READY", 24)
	role_label.add_theme_color_override("font_color", TEAL)
	page.add_child(role_label)
	var mode_row := HBoxContainer.new()
	for mode: int in [1, 3, 5]:
		var mode_button := _button("%dダイス" % mode, func() -> void: _set_mode(mode))
		mode_button.custom_minimum_size.y = 44
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_row.add_child(mode_button)
	page.add_child(mode_row)
	mode_label = _body("", 17)
	page.add_child(mode_label)
	roll_button = _button("サイコロを振る", _on_roll_pressed, true)
	page.add_child(roll_button)
	confirm_five_button = _button("選んだ3個で進む", _confirm_five)
	confirm_five_button.visible = false
	page.add_child(confirm_five_button)
	var status_row := HBoxContainer.new()
	rolls_label = _body("", 18)
	rolls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var debug_toggle := _button("DEBUG", _toggle_debug)
	debug_toggle.custom_minimum_size = Vector2(120, 42)
	status_row.add_child(rolls_label)
	status_row.add_child(debug_toggle)
	page.add_child(status_row)
	debug_box = _build_debug_box()
	debug_box.visible = false
	page.add_child(debug_box)
	_set_mode(3)
	_refresh_hud()
	_render_dice([1, 2, 3], false)

func _set_mode(mode: int) -> void:
	if moving or modal_open:
		return
	dice_mode = mode
	mode_label.text = "近くを狙う・役なし" if mode == 1 else ("5個から3個を選ぶ" if mode == 5 else "基本の3ダイス")
	confirm_five_button.visible = false
	roll_button.visible = true

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

func _animate_dice_roll(count: int) -> Array[int]:
	moving = true
	rolling_dice = true
	locked_dice_count = 0
	rolling_values.clear()
	for index: int in range(count):
		rolling_values.append(rng.randi_range(1, 6))
	roll_button.text = "タップで左から止める"
	role_label.text = "目を追えば、少しだけ狙えるかも"
	for frame: int in range(32):
		for index: int in range(locked_dice_count, count):
			rolling_values[index] = rng.randi_range(1, 6)
		_render_dice(rolling_values, false)
		if frame >= 13 and (frame - 13) % 6 == 0:
			_lock_next_die(true)
		if locked_dice_count >= count:
			break
		var delay := 0.045 + float(frame) * 0.0018
		await get_tree().create_timer(delay).timeout
	while locked_dice_count < count:
		_lock_next_die(true)
		await get_tree().create_timer(0.13).timeout
	rolling_dice = false
	moving = false
	roll_button.text = "サイコロを振る"
	return rolling_values.duplicate()

func _lock_next_die(automatic: bool) -> void:
	if not rolling_dice or locked_dice_count >= rolling_values.size():
		return
	var index := locked_dice_count
	if index < fixed_targets.size():
		rolling_values[index] = clampi(fixed_targets[index], 1, 6)
	locked_dice_count += 1
	_render_dice(rolling_values, false)
	if not automatic:
		role_label.text = "%d個目を早止め" % locked_dice_count

func _render_dice(values: Array[int], selectable: bool) -> void:
	for child: Node in dice_row.get_children():
		child.queue_free()
	for index: int in range(values.size()):
		var die := Button.new()
		die.text = str(values[index])
		die.custom_minimum_size = Vector2(88, 78)
		die.add_theme_font_size_override("font_size", 38)
		die.toggle_mode = selectable
		die.button_pressed = index in selected_indices
		die.disabled = not selectable
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
	var roles: Dictionary = DiceLogicScript.evaluate(values) if values.size() == 3 else {"main": &"", "support": &"", "labels": []}
	var labels: Array = roles.get("labels", [])
	role_label.text = " + ".join(labels) if not labels.is_empty() else "静かな一投"
	if roles.get("support", &"") == DiceLogicScript.ALL_EVEN:
		GameState.coins += 3
	if roles.get("main", &"") == DiceLogicScript.TRIPLE:
		GameState.boss_presence = 5
	var distance: int = 0
	for value: int in values:
		distance += value
	for step: int in range(distance):
		var next_index := posmod(GameState.current_tile_index + 1, BoardModelScript.TILE_COUNT)
		if next_index == 0:
			GameState.lap_count += 1
			GameState.lap_stamps.append("CAIRO-%02d" % GameState.lap_count)
			GameState.coins += 5
			GameState.travel_memos.append("カイロを一周。砂時計のスタンプを押した。")
		GameState.current_tile_index = next_index
		board_view.set_current_tile(next_index)
		minimap_view.set_current_tile(next_index)
		await get_tree().create_timer(0.035).timeout
	GameState.rolls_used += 1
	await _resolve_landing(tile_types[GameState.current_tile_index], roles)
	SaveManager.save_now()
	_refresh_hud()
	moving = false
	roll_button.disabled = false

func _resolve_landing(tile_type: StringName, roles: Dictionary) -> void:
	var memo := ""
	match tile_type:
		&"NORMAL":
			memo = ["日陰で猫があくびをした。", "砂の向こうで鐘が一度鳴った。", "冷たい風が市場から届いた。"][rng.randi_range(0, 2)]
		&"EVENT":
			GameState.coins += 2
			memo = "光る砂を写真に残した。コイン +2"
		&"ITEM":
			GameState.inventory["pinpoint"] = int(GameState.inventory.get("pinpoint", 0)) + 1
			memo = "ピンポイントチケットを見つけた。"
		&"COIN":
			GameState.coins += 6
			memo = "古い旅コインを拾った。+6"
		&"WARP":
			memo = "風の道に乗って、6マス先へ。"
			var warp: Dictionary = BoardModelScript.move(GameState.current_tile_index, 6)
			GameState.current_tile_index = int(warp.index)
			GameState.lap_count += int(warp.laps)
			board_view.set_current_tile(GameState.current_tile_index)
			minimap_view.set_current_tile(GameState.current_tile_index)
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
			GameState.souvenirs += 1
			GameState.boss_presence = mini(5, GameState.boss_presence + 2)
			memo = "遺跡の影を見上げた。旅の記憶 +1"
		&"BOSS_SCENT":
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 2)
			memo = ["砂の上に、大きな足跡が残っている。", "遠くから、低いあくびが聞こえた。", "誰かがここで、しばらく昼寝をしていたらしい。 "][rng.randi_range(0, 2)]
	if roles.get("main", &"") == DiceLogicScript.PAIR:
		GameState.souvenirs += 1
		memo += "　PAIRのおみやげ +1"
	if roles.get("main", &"") == DiceLogicScript.STRAIGHT:
		GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)
		memo += "　STRAIGHTで気配が近づいた。"
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
			await _show_encounter_modal(pair_bonus)
		else:
			GameState.boss_relief = mini(BossSystemScript.RELIEF_FORCE_AFTER, GameState.boss_relief + 1)
			GameState.boss_presence = mini(BossSystemScript.PRESENCE_MAX, GameState.boss_presence + 1)

func _refresh_hud() -> void:
	if lap_label == null:
		return
	lap_label.text = "周回 %d" % GameState.lap_count
	coin_label.text = "旅コイン %d" % GameState.coins
	rolls_label.text = "ターン %d / 36　現在 %dマス" % [GameState.rolls_used, GameState.current_tile_index + 1]
	GameState.ensure_boss_data()
	var footprints := "・".repeat(5 - GameState.boss_presence) + "●".repeat(GameState.boss_presence)
	boss_label.text = "%s　交流 %d%%　気配 %s" % [str(GameState.current_boss.get("name", "眠そうなスフィンクス")), int(GameState.current_boss.get("gauge", 0)), footprints]
	stamp_label.text = "旅のスタンプ　" + ("なし" if GameState.lap_stamps.is_empty() else "  ".join(GameState.lap_stamps))

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

func _show_encounter_modal(pair_bonus: bool) -> void:
	GameState.ensure_boss_data()
	_play_encounter_chime()
	var definition := BossSystemScript.definition_by_id(str(GameState.current_boss.get("definition_id", "sleepy_sphinx")), boss_definitions)
	var modal := _make_modal()
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
	var gauge := _body("交流 %d%%　出会い %d回%s" % [int(GameState.current_boss.get("gauge", 0)), int(GameState.current_boss.get("encounters", 0)), "　PAIR +3" if pair_bonus else ""], 19)
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
	return box

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
	if root_stack == null or board_view == null:
		show_game()
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
	GameState.fixed_rolls.assign([4])
	var before_rolls := GameState.rolls_used
	_on_roll_pressed()
	while moving or rolling_dice:
		await get_tree().process_frame
	var passed := GameState.current_tile_index == 4 and GameState.rolls_used == before_rolls + 1 and role_label.text == "静かな一投"
	print("QA_ONE_DIE tile=%d rolls_delta=%d role=%s passed=%s" % [GameState.current_tile_index, GameState.rolls_used - before_rolls, role_label.text, passed])
	if not passed:
		push_error("One-die interaction smoke test failed.")
	get_tree().quit(0 if passed else 1)

func _qa_five_dice() -> void:
	GameState.reset_run()
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

func _qa_capture_viewport(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png(path)
	print("QA_CAPTURE path=%s result=%s size=%s" % [path, result, image.get_size()])
	get_tree().quit(0 if result == OK else 1)
