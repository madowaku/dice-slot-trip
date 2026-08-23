extends "res://scripts/app/main.gd"

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const CASINO_HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const CAIRO_CASINO_PLAY_SCENE: PackedScene = preload("res://scenes/casino/CairoCasinoPlayScreen.tscn")
const LAS_VEGAS_CITY_CARD: Texture2D = preload("res://assets/art/city_cards/lasvegas-city-card.png")
const LAS_VEGAS_DESTINATION: StringName = &"lasvegas_casino"

var casino_hub_overlay: Control
var selected_special_destination: StringName = &""

func _render_stage_select() -> void:
	super._render_stage_select()
	_hide_unreleased_city_postcards()
	_add_las_vegas_postcard()
	_apply_special_destination_details()

func _preview_stage(stage_id: StringName) -> void:
	selected_special_destination = &""
	super._preview_stage(stage_id)

func _hide_unreleased_city_postcards() -> void:
	for postcard_name: String in ["city_newyork", "city_venice", "city_singapore"]:
		var postcard := root_stack.find_child(postcard_name, true, false) as Control
		if postcard != null:
			postcard.visible = false
			postcard.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _add_las_vegas_postcard() -> void:
	if not is_instance_valid(root_stack):
		return
	var map_area := root_stack.find_child("WorldMapPostcards", true, false) as Control
	if not is_instance_valid(map_area):
		return
	if map_area.has_node("city_lasvegas"):
		return

	# North America has an open pocket between the New York and Amazon cards.
	# Keep Las Vegas inside the same authored postcard map instead of treating
	# the casino as an unrelated button below the normal stage-select flow.
	var entry := _add_city_postcard(
		map_area,
		"LASVEGAS",
		"きらめきのラスベガス",
		Vector2(24, 210),
		Vector2(206, 126),
		true,
		_select_las_vegas,
		LAS_VEGAS_CITY_CARD,
		selected_special_destination == LAS_VEGAS_DESTINATION,
		"DICE RACE",
		"CHIPを賭けて、目押しで推しレーサーを応援。"
	)
	entry.tooltip_text = "LAS VEGAS CASINO\nCHIP %d\nDICE RACE" % CasinoBankScript.balance()
	for node: Node in entry.find_children("*", "Label", true, false):
		var caption := node as Label
		if caption != null and "きらめきのラスベガス" in caption.text:
			caption.text = "きらめきのラスベガス\n● カジノへ"
			caption.autowrap_mode = TextServer.AUTOWRAP_OFF
			caption.add_theme_font_size_override("font_size", 16)

	var badge := Label.new()
	badge.name = "CasinoChipBadge"
	badge.text = "CHIP %d" % CasinoBankScript.balance()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color("#fff1b6"))
	badge.add_theme_color_override("font_outline_color", Color("#352033"))
	badge.add_theme_constant_override("outline_size", 5)
	badge.anchor_left = 0.53
	badge.anchor_right = 0.95
	badge.anchor_top = 0.06
	badge.anchor_bottom = 0.27
	badge.z_index = 8
	entry.add_child(badge)

func _select_las_vegas() -> void:
	selected_special_destination = LAS_VEGAS_DESTINATION
	get_node("/root/BgmManager").call("play_lasvegas_preview")
	_render_stage_select()

func _apply_special_destination_details() -> void:
	if selected_special_destination != LAS_VEGAS_DESTINATION:
		return
	var title := root_stack.find_child("StageSelectDetailTitle", true, false) as Label
	var description := root_stack.find_child("StageSelectDetailDescription", true, false) as Label
	var meta := root_stack.find_child("StageSelectDetailMeta", true, false) as Label
	var cta := root_stack.find_child("StageSelectPrimaryCta", true, false) as Button
	if cta == null:
		cta = root_stack.find_child("stage_locked_cta", true, false) as Button
	if title != null:
		title.text = "選択中：きらめきのラスベガス ｜ CASINO"
	if description != null:
		description.text = "CHIPを使ってミニゲームや景品交換を楽しむ夜の街。"
	if meta != null:
		meta.text = "CHIP残高：%d" % CasinoBankScript.balance()
	if cta != null:
		var cta_parent := cta.get_parent()
		var cta_index := cta.get_index()
		cta_parent.remove_child(cta)
		cta.queue_free()
		var casino_cta := _button("カジノへ", _open_casino_hub, true)
		casino_cta.name = "StageSelectPrimaryCta"
		cta_parent.add_child(casino_cta)
		cta_parent.move_child(casino_cta, cta_index)

func _open_casino_hub() -> void:
	if is_instance_valid(casino_hub_overlay):
		return
	casino_hub_overlay = CASINO_HUB_SCENE.instantiate() as Control
	casino_hub_overlay.z_index = 500
	casino_hub_overlay.back_requested.connect(_close_casino_hub)
	add_child(casino_hub_overlay)

func _close_casino_hub() -> void:
	if is_instance_valid(casino_hub_overlay):
		casino_hub_overlay.queue_free()
	casino_hub_overlay = null
	call_deferred("_restore_stage_select_from_casino")

func _restore_stage_select_from_casino() -> void:
	show_stage_select()
	if selected_special_destination == LAS_VEGAS_DESTINATION:
		get_node("/root/BgmManager").call("play_lasvegas_preview")

func show_v06_game(stage_id: StringName = &"", character_id: StringName = &"", resume_data: Dictionary = {}) -> void:
	# Mirror the parent host contract, changing only the Cairo PackedScene so the
	# established V06 UI/session remains authoritative while CHIP banking hooks
	# into its existing Next Lap boundary.
	_v06_exit_transition_pending = false
	var resolved_stage_id: StringName = stage_id
	if String(resolved_stage_id).is_empty():
		resolved_stage_id = GameState.selected_stage_id
	if String(resolved_stage_id).is_empty():
		resolved_stage_id = GameState.DEFAULT_STAGE
	var resolved_character_id: StringName = character_id
	if String(resolved_character_id).is_empty():
		resolved_character_id = GameState.selected_character_id
	if String(resolved_character_id).is_empty():
		resolved_character_id = GameState.DEFAULT_CHARACTER
	GameState.selected_stage_id = resolved_stage_id
	GameState.selected_character_id = resolved_character_id
	_clear()
	add_to_group("v06_session_screen")
	var screen := CAIRO_CASINO_PLAY_SCENE.instantiate() as V06PlayScreen
	screen.name = "V06PlayScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.configure_start_context(resolved_stage_id, resolved_character_id)
	screen.configure_save_manager(_v06_save_manager())
	screen.configure_resume_data(resume_data)
	screen.connect("back_requested", Callable(self, "_on_v06_back_requested"))
	screen.connect("resume_failed", Callable(self, "show_title"))
	screen.connect("postcard_unlocked", Callable(self, "_on_postcard_unlocked"))
	add_child(screen)
