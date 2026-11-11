class_name CasinoHubScreen
extends Control

## Las Vegas casino hub.
##
## The hub is built around the prize shelf: the first thing the player reads
## is what they are saving up for and how many chips are still missing. Games
## come second, each with a one-line pitch and a small picture of how it
## plays. The authored map art stays as a darkened backdrop so text wins.

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const ShellScript = preload("res://scripts/ui/casino_table_shell.gd")
const DiceGlyphScript = preload("res://scripts/ui/casino_dice_glyph.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const CARD_DATA_PATH := "res://data/casino/prize_cards.json"
const LAS_VEGAS_MAP_PATH := "res://assets/casino/las_vegas/las-vegas-ring-map-v1.png"
const RACER_ART_PATH := "res://assets/casino/dice_race/racers/%s.png"
const PRIZE_ID_PREFIX := "dice_racer_"
const GOLD := Color("#f2bf4c")
const GOLD_BRIGHT := Color("#ffe6a0")
const CREAM := Color("#fff4d6")
const MUTED := Color("#cdbfd7")
const CARD_FILL := Color("#241a31f2")
const CARD_EDGE := Color("#8c72a4")

## Order is the stable facility registry (saves, tests and tours rely on it);
## what the player sees is decided by MAIN_FACILITY_IDS / OTHER_FACILITY_IDS.
const FACILITY_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "dice_race",
		"name": "DICE RACE",
		"button_label": "推しレース",
		"subtitle": "推しを決めて応援する",
		"scene_path": "res://scenes/casino/DiceRace.tscn",
	},
	{
		"id": "dice_tower",
		"name": "DICE TOWER",
		"button_label": "欲張りタワー",
		"subtitle": "あと1段だけ欲張る",
		"scene_path": "res://scenes/casino/DiceTower.tscn",
	},
	{
		"id": "dice_roulette",
		"name": "DICE ROULETTE",
		"button_label": "一発ルーレット",
		"subtitle": "考え込まず一発に賭ける",
		"scene_path": "res://scenes/casino/DiceRoulette.tscn",
	},
	{
		"id": "treasure_21",
		"name": "TREASURE 21",
		"button_label": "宝箱21",
		"subtitle": "危険な止め時を読む",
		"scene_path": "res://scenes/casino/Treasure21.tscn",
	},
	{
		"id": "dice_poker",
		"name": "DICE POKER",
		"button_label": "役そろえ",
		"subtitle": "5つのダイスで役をつくる",
		"scene_path": "res://scenes/casino/DicePoker.tscn",
	},
	{
		"id": "vault_break",
		"name": "VAULT BREAK",
		"button_label": "金庫破り",
		"subtitle": "鍵穴の選択に悩む",
		"scene_path": "res://scenes/casino/VaultBreak.tscn",
	},
	{
		"id": "chohan",
		"name": "丁半",
		"button_label": "丁半",
		"subtitle": "丁か半か、当てるだけ",
		"scene_path": "res://scenes/casino/Chohan.tscn",
	},
]
## Featured games, in the order a first-time visitor should meet them.
const MAIN_FACILITY_IDS: Array[String] = ["chohan", "dice_race", "dice_poker"]
## Still reachable until the "push your luck" game is chosen (renewal phase 3).
const OTHER_FACILITY_IDS: Array[String] = ["dice_tower", "treasure_21", "vault_break", "dice_roulette"]

static var suppress_audio_for_tests := false

var hub_root: Control
var chip_label: Label
var race_host: Control
var tower_host: Control
var roulette_host: Control
var card_data: Array[Dictionary] = []
var facility_definitions: Array[Dictionary] = []
var facility_nodes: Dictionary = {}
var facility_buttons: Dictionary = {}
var facility_title_labels: Dictionary = {}
var facility_tagline_labels: Dictionary = {}
var facility_hosts: Dictionary = {}
var facility_availability: Dictionary = {}
var facility_status_label: Label
var active_facility_id := ""

var prize_shelf: PanelContainer
var prize_picture: TextureRect
var prize_kicker_label: Label
var prize_name_label: Label
var prize_progress: ProgressBar
var prize_remaining_label: Label
var prize_counter_button: Button
var prize_counter: Control


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
	bg.color = Color("#120d1a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hub_root = Control.new()
	hub_root.name = "CasinoHubRoot"
	hub_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hub_root)

	# The authored Las Vegas art sets the mood; the dim layer keeps every
	# label on top of it readable.
	var map_art := TextureRect.new()
	map_art.name = "RingMapBackground"
	map_art.texture = load(LAS_VEGAS_MAP_PATH) as Texture2D
	map_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_root.add_child(map_art)
	var dim := ColorRect.new()
	dim.name = "BackdropDim"
	dim.color = Color(0.07, 0.05, 0.10, 0.84)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	hub_root.add_child(margin)
	var root := VBoxContainer.new()
	root.name = "HubColumn"
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.name = "HubHeader"
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var title := _label("LAS VEGAS CASINO", 36, Color("#ffd66b"))
	title.name = "CasinoHubTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.name = "ChipPanel"
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#241a31"), Color("#6b5680"), 18, 2))
	header.add_child(chip_panel)
	chip_label = _label("CHIP 0", UiTokensScript.FONT_CAPTION, Color.WHITE)
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)

	_build_prize_shelf(root)

	var games_heading := _label("ゲームを選ぶ", 26, MUTED)
	games_heading.name = "GamesHeading"
	root.add_child(games_heading)
	root.add_child(_build_main_card(_facility_definition("chohan"), true))
	var pair := HBoxContainer.new()
	pair.name = "MainFacilityRow"
	pair.add_theme_constant_override("separation", 12)
	root.add_child(pair)
	pair.add_child(_build_main_card(_facility_definition("dice_race"), false))
	pair.add_child(_build_main_card(_facility_definition("dice_poker"), false))

	var other_heading := _label("そのほかのゲーム", 24, MUTED)
	other_heading.name = "OtherGamesHeading"
	root.add_child(other_heading)
	var other_grid := GridContainer.new()
	other_grid.name = "OtherFacilityGrid"
	other_grid.columns = 2
	other_grid.add_theme_constant_override("h_separation", 12)
	other_grid.add_theme_constant_override("v_separation", 12)
	root.add_child(other_grid)
	for id: String in OTHER_FACILITY_IDS:
		other_grid.add_child(_build_other_button(_facility_definition(id)))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(spacer)

	facility_status_label = _label("", UiTokensScript.FONT_CAPTION, Color("#d9c7e8"))
	facility_status_label.name = "FacilityStatus"
	facility_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	facility_status_label.visible = false
	root.add_child(facility_status_label)

	var back := _button("旅へ戻る")
	back.name = "BackToTripButton"
	back.custom_minimum_size.y = UiTokensScript.BUTTON_HEIGHT
	back.add_theme_font_size_override("font_size", UiTokensScript.FONT_BODY)
	ShellScript._style_button(back, Color("#352746"), CARD_EDGE, CREAM, 22)
	back.pressed.connect(func() -> void: back_requested.emit())
	root.add_child(back)

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
	race_host = facility_hosts["dice_race"]
	tower_host = facility_hosts["dice_tower"]
	roulette_host = facility_hosts["dice_roulette"]
	_refresh_facilities()


# ------------------------------------------------------------ prize shelf

func _build_prize_shelf(parent: Control) -> void:
	prize_shelf = PanelContainer.new()
	prize_shelf.name = "PrizeShelf"
	prize_shelf.custom_minimum_size.y = 212
	prize_shelf.add_theme_stylebox_override("panel", _panel(Color("#1b1328f5"), GOLD, 26, 3))
	parent.add_child(prize_shelf)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	prize_shelf.add_child(row)

	prize_picture = TextureRect.new()
	prize_picture.name = "PrizePicture"
	prize_picture.custom_minimum_size = Vector2(150, 150)
	prize_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prize_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prize_picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prize_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(prize_picture)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 6)
	row.add_child(copy)
	prize_kicker_label = _label("ねらっている景品", 24, MUTED)
	prize_kicker_label.name = "PrizeKicker"
	copy.add_child(prize_kicker_label)
	prize_name_label = _label("", 34, CREAM)
	prize_name_label.name = "PrizeName"
	prize_name_label.clip_text = true
	copy.add_child(prize_name_label)
	prize_progress = ProgressBar.new()
	prize_progress.name = "PrizeProgress"
	prize_progress.show_percentage = false
	prize_progress.custom_minimum_size.y = 18
	prize_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prize_progress.add_theme_stylebox_override("background", _bar(Color("#0d0915")))
	prize_progress.add_theme_stylebox_override("fill", _bar(GOLD))
	copy.add_child(prize_progress)
	prize_remaining_label = _label("", 32, GOLD_BRIGHT)
	prize_remaining_label.name = "PrizeRemaining"
	copy.add_child(prize_remaining_label)

	prize_counter_button = _button("景品を\n見る")
	prize_counter_button.name = "PrizeCounterButton"
	prize_counter_button.custom_minimum_size = Vector2(150, 132)
	prize_counter_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prize_counter_button.add_theme_font_size_override("font_size", UiTokensScript.FONT_CAPTION)
	prize_counter_button.pressed.connect(open_prize_counter)
	row.add_child(prize_counter_button)


func _owned_cards() -> Array:
	return CasinoBankScript.owned_cards()


## The prize shown on the shelf: the player's pick while it is still unowned,
## otherwise the first prize they do not have yet. Empty when all are owned.
func target_prize() -> Dictionary:
	var owned := _owned_cards()
	var wanted := CasinoBankScript.target_prize_id()
	var fallback: Dictionary = {}
	for card: Dictionary in card_data:
		var id := str(card.get("id", ""))
		if id in owned:
			continue
		if id == wanted:
			return card
		if fallback.is_empty():
			fallback = card
	return fallback


func chips_missing_for(card: Dictionary) -> int:
	return maxi(0, int(card.get("cost", 0)) - CasinoBankScript.balance())


func _prize_texture(card: Dictionary) -> Texture2D:
	var id := str(card.get("id", ""))
	if not id.begins_with(PRIZE_ID_PREFIX):
		return null
	var path := RACER_ART_PATH % id.trim_prefix(PRIZE_ID_PREFIX)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _prize_title(card: Dictionary) -> String:
	return "レーサー「%s」" % str(card.get("name", ""))


func _refresh_prize_shelf() -> void:
	var card := target_prize()
	if card.is_empty():
		prize_picture.texture = null
		prize_kicker_label.text = "景品"
		prize_name_label.text = "すべて交換済み"
		prize_progress.max_value = 1
		prize_progress.value = 1
		prize_remaining_label.text = "新しい景品をお楽しみに"
		_style_counter_button(false)
		return
	var cost := maxi(1, int(card.get("cost", 0)))
	var missing := chips_missing_for(card)
	prize_picture.texture = _prize_texture(card)
	prize_kicker_label.text = "ねらっている景品"
	prize_name_label.text = _prize_title(card)
	prize_progress.max_value = cost
	prize_progress.value = cost - missing
	prize_remaining_label.text = "あと %d チップ" % missing if missing > 0 else "交換できます！"
	_style_counter_button(missing == 0)


func _style_counter_button(ready_to_trade: bool) -> void:
	prize_counter_button.text = "交換\nする" if ready_to_trade else "景品を\n見る"
	if ready_to_trade:
		ShellScript._style_primary(prize_counter_button)
	else:
		ShellScript._style_button(prize_counter_button, Color("#352746"), CARD_EDGE, CREAM, 22)


# ---------------------------------------------------------- prize counter

func is_prize_counter_open() -> bool:
	return prize_counter != null and is_instance_valid(prize_counter)


func open_prize_counter() -> void:
	if is_prize_counter_open():
		return
	prize_counter = Control.new()
	prize_counter.name = "PrizeCounter"
	prize_counter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hub_root.add_child(prize_counter)
	_rebuild_prize_counter()


func close_prize_counter() -> void:
	if not is_prize_counter_open():
		return
	prize_counter.queue_free()
	prize_counter = null
	_refresh()


func _rebuild_prize_counter() -> void:
	for child: Node in prize_counter.get_children():
		prize_counter.remove_child(child)
		child.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	prize_counter.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	prize_counter.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var heading := _label("景品カウンター", UiTokensScript.FONT_TITLE, GOLD_BRIGHT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var balance := CasinoBankScript.balance()
	var chips := _label("CASINO CHIP  %d" % balance, UiTokensScript.FONT_CAPTION, CREAM)
	chips.name = "PrizeCounterChips"
	chips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(chips)

	var owned := _owned_cards()
	var target_id := str(target_prize().get("id", ""))
	for card: Dictionary in card_data:
		var card_id := str(card.get("id", ""))
		var cost := int(card.get("cost", 0))
		var is_owned := card_id in owned
		var is_target := card_id == target_id
		var row_panel := PanelContainer.new()
		row_panel.name = "PrizeRow_%s" % card_id
		row_panel.add_theme_stylebox_override("panel", _panel(CARD_FILL, GOLD if is_target else Color("#4f4160"), 18, 3 if is_target else 1))
		box.add_child(row_panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row_panel.add_child(row)
		var picture := TextureRect.new()
		picture.texture = _prize_texture(card)
		picture.custom_minimum_size = Vector2(76, 76)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(picture)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(copy)
		copy.add_child(_label(str(card.get("name", "")), UiTokensScript.FONT_CAPTION, CREAM))
		var note := _label("交換済み" if is_owned else ("ねらい中" if is_target else "DICE RACE の応援レーサー"), 20, GOLD_BRIGHT if is_target and not is_owned else MUTED)
		note.clip_text = true
		copy.add_child(note)
		if not is_owned:
			var aim := _button("ねらう")
			aim.name = "AimButton_%s" % card_id
			aim.custom_minimum_size = Vector2(124, UiTokensScript.TOUCH_MIN)
			aim.add_theme_font_size_override("font_size", 24)
			ShellScript._style_button(aim, Color("#352746"), CARD_EDGE, CREAM, 18)
			aim.disabled = is_target
			aim.pressed.connect(_aim_for_card.bind(card_id))
			row.add_child(aim)
			var buy := _button("%d チップ" % cost)
			buy.name = "BuyButton_%s" % card_id
			buy.custom_minimum_size = Vector2(156, UiTokensScript.TOUCH_MIN)
			buy.add_theme_font_size_override("font_size", 26)
			ShellScript._style_primary(buy)
			buy.disabled = balance < cost
			buy.tooltip_text = "交換する" if balance >= cost else "あと %d チップ" % (cost - balance)
			buy.pressed.connect(_buy_card.bind(card_id, cost))
			row.add_child(buy)

	var close := _button("とじる")
	close.name = "PrizeCounterCloseButton"
	close.custom_minimum_size.y = UiTokensScript.BUTTON_HEIGHT
	ShellScript._style_button(close, Color("#352746"), CARD_EDGE, CREAM, 22)
	close.pressed.connect(close_prize_counter)
	box.add_child(close)


func _aim_for_card(card_id: String) -> void:
	CasinoBankScript.set_target_prize_id(card_id)
	_refresh()
	if is_prize_counter_open():
		_rebuild_prize_counter()


func _buy_card(card_id: String, cost: int) -> void:
	if not CasinoBankScript.own_card(card_id, cost):
		return
	if CasinoBankScript.target_prize_id() == card_id:
		CasinoBankScript.set_target_prize_id("")
	_refresh()
	if is_prize_counter_open():
		_rebuild_prize_counter()


# --------------------------------------------------------------- facilities

func _facility_art(id: String) -> Control:
	match id:
		"chohan":
			var pair: Control = DiceGlyphScript.new()
			var pair_faces: Array[int] = [3, 5]
			pair.faces = pair_faces
			pair.custom_minimum_size = Vector2(190, 110)
			return pair
		"dice_poker":
			var hand: Control = DiceGlyphScript.new()
			var hand_faces: Array[int] = [6, 6, 6, 2, 2]
			hand.faces = hand_faces
			hand.tilt_degrees = 0.0
			hand.custom_minimum_size = Vector2(260, 60)
			return hand
		"dice_race":
			var racers := HBoxContainer.new()
			racers.alignment = BoxContainer.ALIGNMENT_CENTER
			racers.add_theme_constant_override("separation", 4)
			racers.custom_minimum_size = Vector2(260, 60)
			racers.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for racer: String in ["fox", "rabbit", "duck"]:
				var picture := TextureRect.new()
				var path := RACER_ART_PATH % racer
				picture.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
				picture.custom_minimum_size = Vector2(64, 60)
				picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
				racers.add_child(picture)
			return racers
	return null


func _build_main_card(definition: Dictionary, wide: bool) -> Button:
	var id := str(definition.get("id", ""))
	var button := Button.new()
	button.name = "FacilityButton_%s" % _pascal_case(id)
	button.set_meta("facility_id", id)
	button.custom_minimum_size = Vector2(0, 156 if wide else 204)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _panel(CARD_FILL, GOLD if wide else CARD_EDGE, 24, 3 if wide else 2))
	button.add_theme_stylebox_override("hover", _panel(Color("#33254af2"), GOLD_BRIGHT, 24, 3))
	button.add_theme_stylebox_override("pressed", _panel(Color("#4a3410f2"), GOLD_BRIGHT, 24, 3))
	button.add_theme_stylebox_override("focus", _panel(Color.TRANSPARENT, GOLD_BRIGHT, 24, 3))
	button.add_theme_stylebox_override("disabled", _panel(Color("#1c1624f2"), Color("#3a3044"), 24, 2))
	VisualFeedback.bind_button(button)
	button.pressed.connect(_on_facility_pressed.bind(id))

	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inset.add_theme_constant_override(side, 14)
	button.add_child(inset)
	var layout: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16 if wide else 6)
	inset.add_child(layout)
	var art := _facility_art(id)
	if art != null:
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		layout.add_child(art)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	layout.add_child(copy)
	var align := HORIZONTAL_ALIGNMENT_LEFT if wide else HORIZONTAL_ALIGNMENT_CENTER
	if wide:
		var badge := _label("はじめての人はここから", 22, GOLD)
		badge.name = "FirstVisitBadge"
		copy.add_child(badge)
	var title := _label(str(definition.get("button_label", id)), 40 if wide else 32, GOLD_BRIGHT)
	title.name = "FacilityTitle"
	title.horizontal_alignment = align
	copy.add_child(title)
	var tagline := _label(str(definition.get("subtitle", "")), UiTokensScript.FONT_CAPTION if wide else 24, CREAM)
	tagline.name = "FacilityTagline"
	tagline.horizontal_alignment = align
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(tagline)
	facility_nodes[id] = button
	facility_buttons[id] = button
	facility_title_labels[id] = title
	facility_tagline_labels[id] = tagline
	return button


func _build_other_button(definition: Dictionary) -> Button:
	var id := str(definition.get("id", ""))
	var button := _button(str(definition.get("button_label", id)))
	button.name = "FacilityButton_%s" % _pascal_case(id)
	button.set_meta("facility_id", id)
	button.custom_minimum_size = Vector2(0, UiTokensScript.BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", UiTokensScript.FONT_CAPTION)
	ShellScript._style_button(button, Color("#241a31e6"), Color("#5a4a6b"), CREAM, 18)
	# Keep the name legible on the dark fill even if a route is unavailable.
	button.add_theme_color_override("font_disabled_color", Color("#c7bdd1"))
	button.pressed.connect(_on_facility_pressed.bind(id))
	facility_nodes[id] = button
	facility_buttons[id] = button
	return button


func _refresh() -> void:
	chip_label.text = "CASINO CHIP  %d" % CasinoBankScript.balance()
	_refresh_facilities()
	_refresh_prize_shelf()


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
	facility_status_label.text = ""
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
		button.tooltip_text = "%s｜%s" % [
			str(definition.get("name", id)),
			str(definition.get("subtitle", "")),
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
	button.add_theme_font_size_override("font_size", UiTokensScript.FONT_BODY)
	button.custom_minimum_size = Vector2(220, UiTokensScript.TOUCH_MIN)
	VisualFeedback.bind_button(button)
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

func _bar(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(9)
	return style
