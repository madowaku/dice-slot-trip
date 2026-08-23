extends "res://scripts/app/main.gd"

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const CASINO_HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const CAIRO_CASINO_PLAY_SCENE: PackedScene = preload("res://scenes/casino/CairoCasinoPlayScreen.tscn")

var casino_hub_overlay: Control

func _render_stage_select() -> void:
	super._render_stage_select()
	_add_las_vegas_postcard()

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
		Vector2(18, 158),
		Vector2(178, 120),
		true,
		_open_casino_hub,
		_las_vegas_card_texture(),
		false,
		"DICE RACE",
		"CHIPを賭けて、目押しで推しレーサーを応援。"
	)
	entry.tooltip_text = "LAS VEGAS CASINO\nCHIP %d\nDICE RACE" % CasinoBankScript.balance()

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

func _las_vegas_card_texture() -> Texture2D:
	# Temporary production-safe art until a dedicated Las Vegas postcard is
	# authored. Keeping this procedural means the map never shows a blank card,
	# and swapping to a PNG later is a one-line preload change.
	var gradient := Gradient.new()
	gradient.set_color(0, Color("#24143c"))
	gradient.set_color(1, Color("#d89232"))
	gradient.add_point(0.48, Color("#6d285a"))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 160
	texture.fill_from = Vector2(0.08, 0.08)
	texture.fill_to = Vector2(0.92, 0.92)
	return texture

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
	call_deferred("show_stage_select")

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
