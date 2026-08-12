class_name V06TravelEncyclopediaView
extends Control

signal close_requested

const Catalog = preload("res://scripts/ui/v06_travel_card_catalog.gd")

const PANEL_BG := Color("#0b2022")
const CARD_BG := Color("#f0dfbd")
const CARD_LOCKED_BG := Color("#282d2b")
const GOLD := Color("#d2a44e")
const TEAL := Color("#2c8588")
const INK := Color("#3f3025")
const IVORY := Color("#f5ead1")
const MUTED := Color("#a99d86")

var _discovered: Dictionary = {}
var _legacy_entries: Array[Dictionary] = []
var _selected_category := Catalog.CATEGORY_ALL
var _selected_card_id := ""
var _panel: PanelContainer
var _progress_label: Label
var _tabs: Dictionary = {}
var _gallery_page: VBoxContainer
var _gallery: VBoxContainer
var _detail_page: VBoxContainer
var _detail_art: TextureRect
var _detail_category: Label
var _detail_title: Label
var _detail_effect: Label
var _detail_source: Label
var _detail_description: Label
var _detail_back_button: Button
var _close_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_view()
	hide()


func open(discovered_ids: Array, close_copy := "閉じる", legacy_entries: Array = []) -> void:
	_discovered.clear()
	for raw_id: Variant in discovered_ids:
		var card_id := str(raw_id)
		if not card_id.is_empty():
			_discovered[card_id] = true
	_legacy_entries.clear()
	for raw_entry: Variant in legacy_entries:
		if raw_entry is Dictionary:
			var entry := (raw_entry as Dictionary).duplicate(true)
			var legacy_id := "legacy:%s" % str(entry.get("individual_id", _legacy_entries.size()))
			entry["card_id"] = legacy_id
			_discovered[legacy_id] = true
			_legacy_entries.append(entry)
	_close_button.text = close_copy
	_selected_category = Catalog.CATEGORY_ALL
	_selected_card_id = ""
	_show_gallery()
	_refresh_progress()
	_refresh_tabs()
	_rebuild_gallery()
	show()
	_close_button.grab_focus()


func refresh_discoveries(discovered_ids: Array) -> void:
	_discovered.clear()
	for raw_id: Variant in discovered_ids:
		var card_id := str(raw_id)
		if not card_id.is_empty():
			_discovered[card_id] = true
	for entry: Dictionary in _legacy_entries:
		_discovered[str(entry.get("card_id", ""))] = true
	_refresh_progress()
	_rebuild_gallery()


func hide_view() -> void:
	hide()
	_selected_card_id = ""
	_show_gallery()


func visual_receipt() -> Dictionary:
	var total := Catalog.definitions().size()
	var unlocked := 0
	for entry: Dictionary in Catalog.definitions():
		if _discovered.has(str(entry.get("id", ""))):
			unlocked += 1
	return {
		"visible": visible,
		"total": total,
		"unlocked": unlocked,
		"category": _selected_category,
		"selected_card_id": _selected_card_id,
		"detail_visible": is_instance_valid(_detail_page) and _detail_page.visible,
		"rendered_cards": _gallery.get_child_count() if is_instance_valid(_gallery) else 0,
	}


func _build_view() -> void:
	var dim := ColorRect.new()
	dim.name = "TravelEncyclopediaDim"
	dim.color = Color(0.012, 0.027, 0.029, 0.92)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24.0
	center.offset_top = 24.0
	center.offset_right = -24.0
	center.offset_bottom = -24.0
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "TravelEncyclopediaPanel"
	_panel.custom_minimum_size = Vector2(640.0, 1180.0)
	_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, GOLD, 24, 4, 24))
	center.add_child(_panel)

	var content := VBoxContainer.new()
	content.name = "TravelEncyclopediaContent"
	content.add_theme_constant_override("separation", 14)
	_panel.add_child(content)

	var title := Label.new()
	title.text = "旅の図鑑"
	title.custom_minimum_size.y = 58.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", GOLD)
	content.add_child(title)

	_progress_label = Label.new()
	_progress_label.name = "TravelEncyclopediaProgress"
	_progress_label.custom_minimum_size.y = 36.0
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 20)
	_progress_label.add_theme_color_override("font_color", IVORY)
	content.add_child(_progress_label)

	var tabs := HBoxContainer.new()
	tabs.name = "TravelEncyclopediaTabs"
	tabs.add_theme_constant_override("separation", 6)
	content.add_child(tabs)
	for entry: Dictionary in [
		{"id": Catalog.CATEGORY_ALL, "label": "すべて"},
		{"id": Catalog.CATEGORY_ITEM, "label": "ITEM"},
		{"id": Catalog.CATEGORY_EVENT, "label": "EVENT"},
		{"id": Catalog.CATEGORY_BOSS, "label": "BOSS"},
		{"id": Catalog.CATEGORY_MEMORY, "label": "記念"},
	]:
		var tab := Button.new()
		tab.text = str(entry.label)
		tab.toggle_mode = true
		tab.custom_minimum_size.y = 96.0
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 17)
		tab.pressed.connect(_select_category.bind(str(entry.id)))
		tabs.add_child(tab)
		_tabs[str(entry.id)] = tab

	var body := Control.new()
	body.name = "TravelEncyclopediaBody"
	body.custom_minimum_size.y = 750.0
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)

	_gallery_page = VBoxContainer.new()
	_gallery_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gallery_page.add_theme_constant_override("separation", 8)
	body.add_child(_gallery_page)
	var help := Label.new()
	help.text = "旅で出会ったカードをタップすると、内容を大きく確認できます。"
	help.custom_minimum_size.y = 44.0
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", MUTED)
	_gallery_page.add_child(help)
	var scroll := ScrollContainer.new()
	scroll.name = "TravelEncyclopediaScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gallery_page.add_child(scroll)
	_gallery = VBoxContainer.new()
	_gallery.name = "PostcardGallery"
	_gallery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gallery.add_theme_constant_override("separation", 12)
	scroll.add_child(_gallery)

	_detail_page = VBoxContainer.new()
	_detail_page.name = "TravelCardDetail"
	_detail_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_page.add_theme_constant_override("separation", 10)
	body.add_child(_detail_page)
	_detail_page.hide()
	_detail_category = Label.new()
	_detail_category.name = "TravelCardDetailCategory"
	_detail_category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_category.add_theme_font_size_override("font_size", 18)
	_detail_category.add_theme_color_override("font_color", GOLD)
	_detail_page.add_child(_detail_category)
	_detail_title = Label.new()
	_detail_title.name = "TravelCardDetailTitle"
	_detail_title.custom_minimum_size.y = 56.0
	_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_title.add_theme_font_size_override("font_size", 32)
	_detail_title.add_theme_color_override("font_color", IVORY)
	_detail_page.add_child(_detail_title)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size.y = 330.0
	art_frame.add_theme_stylebox_override("panel", _panel_style(Color("#f0dfbd"), GOLD, 18, 3, 10))
	_detail_page.add_child(art_frame)
	_detail_art = TextureRect.new()
	_detail_art.name = "TravelCardDetailArt"
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_frame.add_child(_detail_art)
	_detail_effect = Label.new()
	_detail_effect.name = "TravelCardDetailEffect"
	_detail_effect.custom_minimum_size.y = 64.0
	_detail_effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_effect.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_effect.add_theme_font_size_override("font_size", 26)
	_detail_effect.add_theme_color_override("font_color", GOLD)
	_detail_page.add_child(_detail_effect)
	_detail_source = Label.new()
	_detail_source.name = "TravelCardDetailSource"
	_detail_source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_source.add_theme_font_size_override("font_size", 18)
	_detail_source.add_theme_color_override("font_color", MUTED)
	_detail_page.add_child(_detail_source)
	_detail_description = Label.new()
	_detail_description.name = "TravelCardDetailDescription"
	_detail_description.custom_minimum_size.y = 88.0
	_detail_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.add_theme_font_size_override("font_size", 21)
	_detail_description.add_theme_color_override("font_color", IVORY)
	_detail_page.add_child(_detail_description)
	_detail_back_button = Button.new()
	_detail_back_button.text = "一覧へ戻る"
	_detail_back_button.custom_minimum_size.y = 96.0
	_detail_back_button.add_theme_font_size_override("font_size", 22)
	_detail_back_button.pressed.connect(_show_gallery)
	_detail_page.add_child(_detail_back_button)

	_close_button = Button.new()
	_close_button.name = "TravelEncyclopediaCloseButton"
	_close_button.custom_minimum_size.y = 96.0
	_close_button.add_theme_font_size_override("font_size", 24)
	_close_button.pressed.connect(_on_close_pressed)
	content.add_child(_close_button)


func _select_category(category: String) -> void:
	_selected_category = category
	_selected_card_id = ""
	_show_gallery()
	_refresh_tabs()
	_rebuild_gallery()


func _refresh_tabs() -> void:
	for category: String in _tabs:
		(_tabs[category] as Button).set_pressed_no_signal(category == _selected_category)


func _refresh_progress() -> void:
	var definitions := Catalog.definitions()
	var unlocked := 0
	for entry: Dictionary in definitions:
		if _discovered.has(str(entry.get("id", ""))):
			unlocked += 1
	_progress_label.text = "見つけたカード  %d / %d" % [unlocked, definitions.size()]


func _rebuild_gallery() -> void:
	if not is_instance_valid(_gallery):
		return
	for child: Node in _gallery.get_children():
		_gallery.remove_child(child)
		child.queue_free()
	for definition: Dictionary in Catalog.definitions():
		if _selected_category != Catalog.CATEGORY_ALL and str(definition.get("category", "")) != _selected_category:
			continue
		_add_card_row(definition, _discovered.has(str(definition.get("id", ""))))
	if _selected_category in [Catalog.CATEGORY_ALL, Catalog.CATEGORY_BOSS]:
		for entry: Dictionary in _legacy_entries:
			_add_card_row(_legacy_definition(entry), true)


func _add_card_row(definition: Dictionary, unlocked: bool) -> void:
	var card_id := str(definition.get("id", ""))
	var card := PanelContainer.new()
	card.custom_minimum_size.y = 156.0
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if card_id.begins_with("memory:"):
		card.name = "Postcard_%s" % card_id.trim_prefix("memory:")
	else:
		card.name = "TravelCard_%s" % card_id.replace(":", "_").replace("-", "_")
	card.add_theme_stylebox_override("panel", _panel_style(CARD_BG if unlocked else CARD_LOCKED_BG, GOLD if unlocked else Color("#6d6659"), 16, 3, 12))
	_gallery.add_child(card)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var art := TextureRect.new()
	art.name = "PostcardArt" if card_id.begins_with("memory:") else "TravelCardArt"
	art.custom_minimum_size = Vector2(150.0, 124.0)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = definition.get("art") as Texture2D
	art.modulate = Color.WHITE if unlocked else Color(0.34, 0.34, 0.32, 0.94)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var category := Label.new()
	category.text = Catalog.category_label(str(definition.get("category", "")))
	category.add_theme_font_size_override("font_size", 15)
	category.add_theme_color_override("font_color", TEAL if unlocked else MUTED)
	category.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(category)
	var title := Label.new()
	title.text = str(definition.get("title", "旅のカード")) if unlocked else "？？？"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", INK if unlocked else IVORY)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var effect := Label.new()
	effect.text = str(definition.get("effect", "")) if unlocked else "旅で出会うと内容が開きます"
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_font_size_override("font_size", 18)
	effect.add_theme_color_override("font_color", Color("#8b5a22") if unlocked else MUTED)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(effect)

	var open_button := Button.new()
	open_button.name = "Open_%s" % card.name
	open_button.flat = true
	open_button.custom_minimum_size.y = 156.0
	open_button.disabled = not unlocked
	open_button.tooltip_text = "カードを開く" if unlocked else "まだ見つけていません"
	open_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	open_button.focus_mode = Control.FOCUS_ALL
	open_button.z_index = 3
	open_button.pressed.connect(_show_detail.bind(definition))
	card.add_child(open_button)


func _show_detail(definition: Dictionary) -> void:
	_selected_card_id = str(definition.get("id", ""))
	_detail_category.text = Catalog.category_label(str(definition.get("category", ""))).to_upper()
	_detail_title.text = str(definition.get("title", "旅のカード"))
	_detail_effect.text = str(definition.get("effect", ""))
	_detail_source.text = "見つけた場所：%s" % str(definition.get("source", "旅の途中"))
	_detail_description.text = str(definition.get("description", ""))
	_detail_art.texture = definition.get("art") as Texture2D
	_gallery_page.hide()
	_detail_page.show()
	_detail_back_button.grab_focus()


func _show_gallery() -> void:
	_selected_card_id = ""
	if is_instance_valid(_detail_page):
		_detail_page.hide()
	if is_instance_valid(_gallery_page):
		_gallery_page.show()


func _legacy_definition(entry: Dictionary) -> Dictionary:
	var base := Catalog.definition("boss:sleepy_sphinx")
	return {
		"id": str(entry.get("card_id", "legacy:boss")),
		"category": Catalog.CATEGORY_BOSS,
		"title": str(entry.get("name", "旅で出会ったスフィンクス")),
		"effect": str(entry.get("personality", "旅の友だち")),
		"source": "旅の途中で知り合った相手",
		"description": str(entry.get("memo", "砂漠で少しずつ仲良くなった。")),
		"art": base.get("art"),
	}


func _on_close_pressed() -> void:
	hide_view()
	close_requested.emit()


func _panel_style(background: Color, border: Color, radius: int, border_width: int, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 8
	return style
