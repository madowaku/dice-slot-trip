class_name CasinoHubScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const CARD_DATA_PATH := "res://data/casino/prize_cards.json"
const LAS_VEGAS_MAP_PATH := "res://assets/casino/las_vegas/las-vegas-ring-map-v1.png"
const LAS_VEGAS_SPARKLE_PATH := "res://assets/casino/las_vegas/las-vegas-selection-sparkle-strip.png"
const FACILITY_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "dice_race",
		"name": "DICE RACE",
		"subtitle": "狙って推しを追い上げる",
		"scene_path": "res://scenes/casino/DiceRace.tscn",
	},
	{
		"id": "dice_tower",
		"name": "DICE TOWER",
		"subtitle": "あと1段だけ欲張る",
		"scene_path": "res://scenes/casino/DiceTower.tscn",
	},
	{
		"id": "dice_roulette",
		"name": "DICE ROULETTE",
		"subtitle": "考え込まず一発に賭ける",
		"scene_path": "res://scenes/casino/DiceRoulette.tscn",
	},
	{
		"id": "treasure_21",
		"name": "TREASURE 21",
		"subtitle": "危険な止め時を読む",
		"scene_path": "res://scenes/casino/Treasure21.tscn",
	},
	{
		"id": "dice_poker",
		"name": "DICE POKER",
		"subtitle": "役の伸びしろを考える",
		"scene_path": "res://scenes/casino/DicePoker.tscn",
	},
	{
		"id": "vault_break",
		"name": "VAULT BREAK",
		"subtitle": "鍵穴の選択に悩む",
		"scene_path": "res://scenes/casino/VaultBreak.tscn",
	},
]

static var suppress_audio_for_tests := false

var hub_root: Control
var chip_label: Label
var prize_list: VBoxContainer
var race_host: Control
var tower_host: Control
var roulette_host: Control
var card_data: Array[Dictionary] = []
var facility_definitions: Array[Dictionary] = []
var facility_nodes: Dictionary = {}
var facility_buttons: Dictionary = {}
var facility_hosts: Dictionary = {}
var facility_availability: Dictionary = {}
var facility_status_label: Label
var active_facility_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_lasvegas_main")
	card_data = _load_cards()
	facility_definitions = FACILITY_DEFINITIONS.duplicate(true)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "CasinoBackdrop"
	bg.color = Color("#17111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hub_root = Control.new()
	hub_root.name = "CasinoHubRoot"
	hub_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hub_root)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	hub_root.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := _label("LAS VEGAS CASINO", 34, Color("#ffd66b"))
	title.name = "CasinoHubTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	chip_label = _label("CHIP 0", 24, Color.WHITE)
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(chip_label)
	var note := _label("旅で持ち帰ったCASINO CHIPで遊ぼう", 17, Color("#d9c7e8"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(note)

	var ring_panel := PanelContainer.new()
	ring_panel.name = "CasinoRingMap"
	ring_panel.custom_minimum_size = Vector2(0, 640)
	# The authored Las Vegas map is the visual anchor; keep a restrained frame so
	# the facility CTAs read as interactive overlays instead of fake map chrome.
	ring_panel.add_theme_stylebox_override("panel", _panel(Color("#17111f"), Color("#d8ad4c"), 24, 2))
	root.add_child(ring_panel)
	_build_ring_map(ring_panel)
	facility_status_label = _label("施設を選んでゲームへ", 17, Color("#d9c7e8"))
	facility_status_label.name = "FacilityStatus"
	facility_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(facility_status_label)

	var prize_title := _label("PRIZE COUNTER", 26, Color("#ffd66b"))
	root.add_child(prize_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	prize_list = VBoxContainer.new()
	prize_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prize_list.add_theme_constant_override("separation", 8)
	scroll.add_child(prize_list)

	var back := _button("旅へ戻る")
	back.name = "BackToTripButton"
	back.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back)

	race_host = Control.new()
	race_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	race_host.visible = false
	add_child(race_host)

	tower_host = Control.new()
	tower_host.name = "DiceTowerHost"
	tower_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tower_host.visible = false
	add_child(tower_host)
	facility_hosts["dice_race"] = race_host
	facility_hosts["dice_tower"] = tower_host
	roulette_host = Control.new()
	roulette_host.name = "DiceRouletteHost"
	roulette_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	roulette_host.visible = false
	add_child(roulette_host)
	facility_hosts["dice_roulette"] = roulette_host
	for definition: Dictionary in facility_definitions:
		var id := str(definition.get("id", ""))
		if id.is_empty() or facility_hosts.has(id):
			continue
		var host := Control.new()
		host.name = "%sHost" % _pascal_case(id)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.visible = false
		add_child(host)
		facility_hosts[id] = host
	_refresh_facilities()

func _build_ring_map(ring_panel: PanelContainer) -> void:
	var map := Control.new()
	map.name = "RingMapCanvas"
	map.custom_minimum_size = Vector2(0, 616)
	map.clip_contents = true
	ring_panel.add_child(map)
	var map_art := TextureRect.new()
	map_art.name = "RingMapBackground"
	map_art.texture = load(LAS_VEGAS_MAP_PATH) as Texture2D
	map_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	map.add_child(map_art)
	var vignette := ColorRect.new()
	vignette.name = "RingMapVignette"
	vignette.color = Color(0.035, 0.035, 0.10, 0.25)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(vignette)
	# Authored 4-frame sparkle atlas adds a quiet animated focal point without
	# intercepting the facility CTAs layered around the ring.
	var sparkle := AnimatedSprite2D.new()
	sparkle.name = "RingSelectionSparkle"
	var sparkle_texture := load(LAS_VEGAS_SPARKLE_PATH) as Texture2D
	if sparkle_texture != null:
		var sparkle_frames := SpriteFrames.new()
		sparkle_frames.remove_animation("default")
		sparkle_frames.add_animation("ambient")
		sparkle_frames.set_animation_speed("ambient", 5.0)
		sparkle_frames.set_animation_loop("ambient", true)
		for frame_index: int in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = sparkle_texture
			atlas.region = Rect2(frame_index * 256, 0, 256, 256)
			sparkle_frames.add_frame("ambient", atlas)
		sparkle.sprite_frames = sparkle_frames
		sparkle.animation = "ambient"
		sparkle.autoplay = "ambient"
		sparkle.position = Vector2(338, 170)
		sparkle.scale = Vector2(0.42, 0.42)
		sparkle.modulate = Color(1, 1, 1, 0.8)
		sparkle.z_index = 1
		sparkle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		map.add_child(sparkle)
	var center_panel := PanelContainer.new()
	center_panel.name = "RingCenter"
	center_panel.size = Vector2(236, 150)
	center_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_panel.add_theme_stylebox_override("panel", _panel(Color("#11152ad9"), Color("#f2bf4c"), 22, 2))
	map.add_child(center_panel)
	var center_box := VBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 4)
	center_panel.add_child(center_box)
	var center_kicker := _label("WELCOME TO", 16, Color("#d9c7e8"))
	center_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(center_kicker)
	var center_title := _label("LAS VEGAS", 28, Color("#ffe6a0"))
	center_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(center_title)
	var center_copy := _label("CHIPを賭けて\n夜を回ろう", 16, Color.WHITE)
	center_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(center_copy)
	var center_chip := _label("✦ 6 FACILITIES ✦", 14, Color("#f2bf4c"))
	center_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_box.add_child(center_chip)
	var button_size := Vector2(172, 96)
	for candidate: Variant in facility_nodes.values():
		var candidate_button := candidate as Button
		if candidate_button != null:
			button_size.x = maxf(button_size.x, candidate_button.size.x)
			button_size.y = maxf(button_size.y, candidate_button.size.y)
	for index: int in range(facility_definitions.size()):
		var definition := facility_definitions[index]
		var id := str(definition.get("id", ""))
		var button := _button(str(definition.get("name", id)))
		button.name = "FacilityButton_%s" % _pascal_case(id)
		button.custom_minimum_size = button_size
		button.size = button_size
		button.add_theme_font_size_override("font_size", 15)
		button.tooltip_text = str(definition.get("subtitle", ""))
		button.set_meta("facility_id", id)
		button.add_theme_stylebox_override("normal", _panel(Color("#38264a"), Color("#d8ad4c"), 18, 2))
		button.add_theme_stylebox_override("hover", _panel(Color("#4b2a4f"), Color("#ffe6a0"), 18, 3))
		button.add_theme_stylebox_override("pressed", _panel(Color("#9f322b"), Color("#ffe6a0"), 18, 3))
		# The authored CTA fills are intentionally dark jewel tones.  Keep every
		# Button state on a light text color so the facility names remain legible
		# while hovering, pressing, or (if a route is unavailable) disabled.
		button.add_theme_color_override("font_color", Color("#fff4d6"))
		button.add_theme_color_override("font_hover_color", Color("#fff9ec"))
		button.add_theme_color_override("font_pressed_color", Color("#fff4d6"))
		button.add_theme_color_override("font_disabled_color", Color("#c7bdd1"))
		map.add_child(button)
		facility_nodes[id] = button
		facility_buttons[id] = button
		if id == "dice_race":
			button.pressed.connect(_open_dice_race)
		elif id == "dice_tower":
			button.pressed.connect(_open_dice_tower)
		else:
			button.pressed.connect(_on_facility_pressed.bind(id))
	# Layout is deferred until the panel has received its actual viewport size.
	# Reflow on resize so narrow portrait windows keep every CTA inside the map.
	map.resized.connect(_layout_ring_map.bind(map))
	_layout_ring_map(map)
	call_deferred("_layout_ring_map", map)

func _layout_ring_map(map: Control) -> void:
	if map == null or not is_instance_valid(map):
		return
	var map_size := map.size
	if map_size.x <= 1.0 or map_size.y <= 1.0:
		return
	var center := map_size * 0.5
	var center_panel := map.get_node_or_null("RingCenter") as PanelContainer
	if center_panel != null:
		center_panel.position = center - center_panel.size * 0.5
	var sparkle := map.get_node_or_null("RingSelectionSparkle") as AnimatedSprite2D
	if sparkle != null:
		# Keep the animated focal point above the center card.  The atlas frame is
		# 256px square at 42% scale, so reserve its half-height plus an 8px gap
		# from the card's top edge at every responsive map size.
		var panel_half_height := center_panel.size.y * 0.5 if center_panel != null else 75.0
		var sparkle_half_height := 128.0 * sparkle.scale.y
		sparkle.position = center + Vector2(0.0, -panel_half_height - sparkle_half_height - 8.0)
	var button_size := Vector2(172, 96)
	# Reserve half the CTA dimensions plus a 12px safety margin on every edge.
	var radius := Vector2(
		maxf(0.0, map_size.x * 0.5 - button_size.x * 0.5 - 12.0),
		maxf(0.0, map_size.y * 0.5 - button_size.y * 0.5 - 12.0)
	)
	for index: int in range(facility_definitions.size()):
		var definition: Dictionary = facility_definitions[index]
		var id := str(definition.get("id", ""))
		var button := facility_nodes.get(id) as Button
		if button == null:
			continue
		var angle := -PI * 0.5 + TAU * float(index) / float(facility_definitions.size())
		var actual_size := button.size
		var target_center := center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		var min_center := Vector2(actual_size.x * 0.5 + 12.0, actual_size.y * 0.5 + 12.0)
		var max_center := map_size - min_center
		target_center.x = clampf(target_center.x, min_center.x, max_center.x)
		target_center.y = clampf(target_center.y, min_center.y, max_center.y)
		button.position = target_center - actual_size * 0.5

func _refresh() -> void:
	chip_label.text = "CASINO CHIP  %d" % CasinoBankScript.balance()
	_refresh_facilities()
	for child: Node in prize_list.get_children():
		child.queue_free()
	var owned: Array = CasinoBankScript.load_data().get("owned_cards", [])
	for card: Dictionary in card_data:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _panel(Color("#2b2235"), Color("#665270"), 12, 1))
		prize_list.add_child(row)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		row.add_child(box)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(copy)
		var name_label := _label("DICE RACER %s  %s" % [str(card.get("number", "")), str(card.get("name", ""))], 19, Color.WHITE)
		copy.add_child(name_label)
		var flavor := _label(str(card.get("flavor", "")), 14, Color("#cdbfd7"))
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(flavor)
		var card_id := str(card.get("id", ""))
		var cost := int(card.get("cost", 50))
		var button := _button("OWNED" if card_id in owned else "%d CHIP" % cost)
		button.disabled = card_id in owned or CasinoBankScript.balance() < cost
		if card_id not in owned:
			button.pressed.connect(_buy_card.bind(card_id, cost))
		box.add_child(button)

func _buy_card(card_id: String, cost: int) -> void:
	if CasinoBankScript.own_card(card_id, cost):
		_refresh()

func _open_dice_race() -> void:
	_open_facility("dice_race")

func _open_dice_tower() -> void:
	_open_facility("dice_tower")

func _open_dice_roulette() -> void:
	_open_facility("dice_roulette")

func _open_treasure_21() -> void:
	_open_facility("treasure_21")

func _open_dice_poker() -> void:
	_open_facility("dice_poker")

func _open_vault_break() -> void:
	_open_facility("vault_break")

func _close_dice_roulette() -> void:
	_close_facility("dice_roulette")

func _on_facility_pressed(facility_id: String) -> void:
	_open_facility(facility_id)

func _open_facility(facility_id: String) -> bool:
	var id := _facility_key(facility_id)
	var definition := _facility_definition(id)
	if definition.is_empty():
		return false
	var path := str(definition.get("scene_path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		facility_status_label.text = "%s は準備中です" % str(definition.get("name", id))
		return false
	var loaded: Resource = ResourceLoader.load(path)
	if loaded == null or not loaded is PackedScene:
		facility_status_label.text = "%s を読み込めません" % str(definition.get("name", id))
		push_warning("CasinoHub could not load facility scene: %s" % path)
		return false
	var host := _host_for(id)
	if host == null:
		return false
	hub_root.visible = false
	for other_id: Variant in facility_hosts.keys():
		var other_host := facility_hosts[other_id] as Control
		if other_host != null and other_host != host:
			other_host.visible = false
	for child: Node in host.get_children():
		child.queue_free()
	host.visible = true
	var screen := (loaded as PackedScene).instantiate()
	host.add_child(screen)
	active_facility_id = id
	facility_status_label.text = "%s をプレイ中" % str(definition.get("name", id))
	if screen.has_signal("back_requested"):
		screen.connect("back_requested", _on_facility_back.bind(id))
	return true

func _on_facility_back(facility_id: String) -> void:
	_close_facility(facility_id)

func _close_facility(facility_id: String) -> void:
	var id := _facility_key(facility_id)
	var host := _host_for(id)
	if host != null:
		for child: Node in host.get_children():
			child.queue_free()
		host.visible = false
	active_facility_id = ""
	hub_root.visible = true
	facility_status_label.text = "施設を選んでゲームへ"
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_lasvegas_main")
	_refresh()

func _close_dice_tower() -> void:
	_close_facility("dice_tower")

func _close_dice_race() -> void:
	_close_facility("dice_race")

func _host_for(facility_id: String) -> Control:
	var value: Variant = facility_hosts.get(_facility_key(facility_id), null)
	return value as Control if value is Control else null

func _facility_definition(facility_id: String) -> Dictionary:
	var id := _facility_key(facility_id)
	for definition: Dictionary in facility_definitions:
		if str(definition.get("id", "")) == id:
			return definition
	return {}

func _refresh_facilities() -> void:
	if facility_buttons.is_empty():
		return
	for definition: Dictionary in facility_definitions:
		var id := str(definition.get("id", ""))
		var button := facility_buttons.get(id) as Button
		if button == null:
			continue
		var available := _facility_available(id)
		facility_availability[id] = available
		button.disabled = not available
		button.text = "%s\n%s\n%s" % [
			str(definition.get("name", id)),
			str(definition.get("subtitle", "")),
			"PLAY" if available else "COMING SOON",
		]

func _facility_available(facility_id: String) -> bool:
	var definition := _facility_definition(facility_id)
	var path := str(definition.get("scene_path", ""))
	return not path.is_empty() and ResourceLoader.exists(path)

func _facility_key(facility_id: String) -> String:
	return facility_id.strip_edges().to_lower()

func _pascal_case(value: String) -> String:
	var result := ""
	for part: String in value.split("_"):
		if part.is_empty():
			continue
		result += part.left(1).to_upper() + part.substr(1)
	return result

func _load_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(CARD_DATA_PATH):
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CARD_DATA_PATH))
	if not parsed is Dictionary:
		return result
	for value: Variant in (parsed as Dictionary).get("cards", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size = Vector2(220, 96)
	return button

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
