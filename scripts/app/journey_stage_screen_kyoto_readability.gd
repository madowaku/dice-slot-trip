extends "res://scripts/app/journey_stage_screen.gd"

# Kyoto presentation override.
# Gameplay remains owned by JourneyStageScreen/KyotoJourney; this layer keeps
# the Kyoto map readable and deliberately reuses Cairo's icon + SE language.

const CAIRO_FEEDBACK_SCRIPT = preload("res://scripts/ui/v06_feedback_controller.gd")
const CASINO_BANK := preload("res://scripts/game/casino_bank.gd")
const CAIRO_STAGE_ID: StringName = &"cairo_hourglass"
const KYOTO_HORIZON_ICON_SIZE := 46.0
const KYOTO_CURRENT_ICON_SIZE := 38.0
const KYOTO_CURRENT_ICON_TOP := 50.0
const KYOTO_FUTURE_ICON_LIFT := 8.0

var _cairo_feedback: Node
var _kyoto_last_feedback_space := ""


func _ready() -> void:
	super._ready()
	if stage_id != StageCatalog.STAGE_KYOTO:
		return

	# Reuse the same semantic feedback mixer and world-specific SFX palette as
	# Cairo so a roll, reward, damage and button press mean the same thing in
	# both stages.
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_stage", CAIRO_STAGE_ID)

	_cairo_feedback = CAIRO_FEEDBACK_SCRIPT.new()
	_cairo_feedback.name = "CairoStyleFeedback"
	add_child(_cairo_feedback)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		_cairo_feedback.call(
			"set_levels",
			1.0,
			float(game_state.get("se_volume")),
			bool(game_state.get("dice_se_muted"))
		)
		_cairo_feedback.call("set_haptics_enabled", bool(game_state.get("haptics_enabled")))
	_kyoto_last_feedback_space = journey.current_space_id if journey != null else ""


func _button(text_value: String, callback: Callable, primary: bool = false) -> Button:
	var button := super._button(text_value, callback, primary)
	if stage_id == StageCatalog.STAGE_KYOTO:
		button.pressed.connect(func() -> void:
			_emit_cairo_feedback(CAIRO_FEEDBACK_SCRIPT.EVENT_BUTTON)
		)
	return button


func _play_dice_se(stream: AudioStream) -> void:
	if stage_id == StageCatalog.STAGE_KYOTO and is_instance_valid(_cairo_feedback):
		# Cairo uses a light press on roll start and the crisp lock_02 hit when
		# the die is stopped. Do not layer Kyoto's old roll_01/land_01 on top.
		if stream == DICE_LAND_SE:
			_emit_cairo_feedback(CAIRO_FEEDBACK_SCRIPT.EVENT_ROLL_STOP)
		else:
			_emit_cairo_feedback(CAIRO_FEEDBACK_SCRIPT.EVENT_BUTTON)
		return
	super._play_dice_se(stream)


func _after_journey_action() -> void:
	super._after_journey_action()
	if stage_id != StageCatalog.STAGE_KYOTO or journey == null:
		return
	var current_space := journey.current_space_id
	if current_space == _kyoto_last_feedback_space:
		return
	_kyoto_last_feedback_space = current_space
	match _current_space_kind():
		"COIN", "REST", "ITEM", "GOSHUIN":
			_emit_cairo_feedback(CAIRO_FEEDBACK_SCRIPT.EVENT_REWARD)
		"RISK":
			_emit_cairo_feedback(CAIRO_FEEDBACK_SCRIPT.EVENT_DAMAGE)
		"JUNCTION", "BYPASS_FORK", "BOSS_FORK":
			_emit_cairo_feedback(CAIRO_FEEDBACK_SCRIPT.EVENT_BUTTON)


func _emit_cairo_feedback(event: StringName) -> void:
	if is_instance_valid(_cairo_feedback):
		_cairo_feedback.call("emit_feedback", event)


func _route_tile(text_value: String, kind: String, current: bool, space_id_value: String = "") -> PanelContainer:
	var tile := super._route_tile(text_value, kind, current, space_id_value)
	# Amazon now uses the same local horizon card dimensions. Keep this compact
	# icon treatment scoped to the two horizon stages; Cairo/other stages retain
	# their existing route-tile semantics and feedback guards.
	if stage_id != StageCatalog.STAGE_KYOTO and stage_id != StageCatalog.STAGE_AMAZON:
		return tile

	var tile_content := tile.get_node_or_null("TileContent") as Control
	if tile_content == null:
		return tile
	var box := tile_content.get_child(0) as VBoxContainer if tile_content.get_child_count() > 0 else null
	var medal := box.get_child(1) as PanelContainer if box != null and box.get_child_count() > 1 else null

	if medal != null and kind != "BOSS":
		if current:
			# The cat owns the lower half of the current card. Keep that colored
			# landing area, but move the semantic icon into a small badge just above
			# the explorer's head instead of putting a large icon behind the sprite.
			var kind_badge := tile_content.get_node_or_null("CurrentKindBadge") as PanelContainer
			if kind_badge != null:
				_style_current_kind_badge(kind_badge, kind)
		else:
			# Cairo's v06 atlas uses these same tile_kind_icons. Center them at a
			# compact fixed size instead of stretching them to Kyoto's 112px medal.
			_fit_horizon_medal_icon(medal, kind)
	return tile


func _style_current_kind_badge(kind_badge: PanelContainer, kind: String) -> void:
	kind_badge.visible = true
	kind_badge.anchor_left = 0.5
	kind_badge.anchor_right = 0.5
	kind_badge.anchor_top = 0.0
	kind_badge.anchor_bottom = 0.0
	kind_badge.offset_left = -KYOTO_CURRENT_ICON_SIZE * 0.5
	kind_badge.offset_right = KYOTO_CURRENT_ICON_SIZE * 0.5
	# Amazon's portrait card reserves a slightly taller lower landing area for
	# the Explorer Cat after the first camera crop; lift its badge just enough to
	# keep the semantic icon clear of the sprite while retaining Cairo geometry.
	var badge_top := 30.0 if stage_id == StageCatalog.STAGE_AMAZON else KYOTO_CURRENT_ICON_TOP
	kind_badge.offset_top = badge_top
	kind_badge.offset_bottom = badge_top + KYOTO_CURRENT_ICON_SIZE
	kind_badge.z_index = 38
	kind_badge.add_theme_stylebox_override(
		"panel",
		_panel(_kyoto_kind_color(kind), Color("#6b5034"), 9, 2)
	)

	var old_icon := kind_badge.get_node_or_null("KindIcon") as TextureRect
	if old_icon != null:
		old_icon.visible = not _uses_text_semantic_icon(kind)
		old_icon.texture = _icon_for_kind(kind)
		old_icon.modulate = _icon_modulate_for_kind(kind)
	if _uses_text_semantic_icon(kind):
		var existing := kind_badge.get_node_or_null("SemanticGlyph") as Label
		if existing == null:
			existing = _semantic_glyph(kind, 27)
			existing.name = "SemanticGlyph"
			kind_badge.add_child(existing)
		else:
			existing.text = _semantic_glyph_text(kind)


func _fit_horizon_medal_icon(medal: PanelContainer, kind: String) -> void:
	medal.custom_minimum_size.y = 92.0
	medal.add_theme_stylebox_override(
		"panel",
		_panel(_kyoto_kind_color(kind), Color("#684c2f"), 10, 2)
	)
	if medal.get_child_count() <= 0:
		return
	var old_icon := medal.get_child(0) as TextureRect
	if old_icon == null:
		return
	medal.remove_child(old_icon)

	var icon_margin := MarginContainer.new()
	icon_margin.name = "CompactKindIconMargin"
	icon_margin.add_theme_constant_override("margin_bottom", int(KYOTO_FUTURE_ICON_LIFT * 2.0))
	icon_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.add_child(icon_margin)

	var center := CenterContainer.new()
	center.name = "CompactKindIconCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_margin.add_child(center)

	if _uses_text_semantic_icon(kind):
		old_icon.queue_free()
		var glyph := _semantic_glyph(kind, 39)
		glyph.custom_minimum_size = Vector2(KYOTO_HORIZON_ICON_SIZE, KYOTO_HORIZON_ICON_SIZE)
		glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		center.add_child(glyph)
		return

	old_icon.texture = _icon_for_kind(kind)
	old_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	old_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	old_icon.custom_minimum_size = Vector2(KYOTO_HORIZON_ICON_SIZE, KYOTO_HORIZON_ICON_SIZE)
	old_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	old_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	old_icon.modulate = _icon_modulate_for_kind(kind)
	old_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(old_icon)


func _uses_text_semantic_icon(kind: String) -> bool:
	return kind in ["REST", "FLOW", "JUNCTION", "BYPASS_FORK", "BOSS_FORK"]


func _semantic_glyph_text(kind: String) -> String:
	if kind == "REST":
		return "♥"
	if kind == "FLOW":
		return "≈"
	if kind in ["JUNCTION", "BYPASS_FORK", "BOSS_FORK"]:
		return "Y"
	return ""


func _semantic_glyph(kind: String, font_size: int) -> Label:
	var glyph := _label(_semantic_glyph_text(kind), font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glyph


func _kyoto_kind_color(kind: String) -> Color:
	if kind in ["JUNCTION", "BYPASS_FORK", "BOSS_FORK"]:
		return TYPE_COLORS.get("JUNCTION", Color("#a96bc7"))
	return TYPE_COLORS.get(kind, TYPE_COLORS.NORMAL)


func _show_overview_map(initial: bool = false) -> void:
	# Kyoto's local horizon, explorer and die use elevated z-indices so they stay
	# crisp during normal play. The full-map overlay must own the top layer while
	# it is open, otherwise those normal-play elements cover the route overview.
	super._show_overview_map(initial)
	if is_instance_valid(overview_overlay):
		overview_overlay.z_index = 200


func _show_menu_tool() -> void:
	# The shared menu overlay used to sit at z=0 while Kyoto's local tiles/die
	# live at z=12..20. That made the normal-play horizon paint over the pause
	# menu and hide its controls. Give the menu the same modal priority as the
	# other journey dialogs.
	super._show_menu_tool()
	if is_instance_valid(active_modal):
		active_modal.z_index = 200


func _show_branch_modal() -> void:
	# Amazon keeps its existing route explanation. Kyoto only needs the outcome
	# of the current roll: which tile each route will land on.
	if stage_id != StageCatalog.STAGE_KYOTO:
		super._show_branch_modal()
		return

	var choices: Array = []
	for value: Variant in journey.pending_choices:
		if not value is Dictionary:
			continue
		var choice := (value as Dictionary).duplicate(true)
		var projection := _project_branch_choice(choice)
		var route_label := "本線" if str(projection.get("route", "main")) == "main" else "近道"
		var destination_kind := str(projection.get("kind_label", "通常"))
		var destination_kind_id := str(projection.get("kind", "NORMAL"))
		var destination := str(projection.get("destination", "次のマス"))
		# Two large lines only: route name, then the exact projected landing tile.
		choice["label"] = "%s　→　%s\n%s" % [route_label, destination_kind, destination]
		choice["icon"] = _icon_for_kind(destination_kind_id)
		choices.append(choice)

	var remaining_steps := maxi(int(journey.pending_steps), 1)
	_open_choice_modal(
		"どちらへ進む？",
		"残り%dマス。着地先を見て選ぼう。" % remaining_steps,
		choices,
		func(choice_id: String) -> void:
			var start_space := journey.current_space_id
			var result: Dictionary = journey.choose_branch(choice_id)
			if bool(result.get("ok", false)):
				map_movement_active = true
				roll_animation_active = true
				if is_instance_valid(roll_button):
					roll_button.disabled = true
				await _animate_journey_movement(start_space, result)
				map_movement_active = false
				roll_animation_active = false
			status_label.text = _journey_result_text(result)
			_after_journey_action()
	)


func _show_boss_recovery_or_perfect() -> void:
	_bank_casino_chips_for_completed_lap()
	super._show_boss_recovery_or_perfect()


func _bank_casino_chips_for_completed_lap() -> Dictionary:
	if journey == null:
		return {}
	var already_banked_lap := int(journey.stage_flags.get("casino_chip_banked_lap", 0))
	if already_banked_lap == journey.lap:
		return (journey.stage_flags.get("last_casino_chip_result", {}) as Dictionary).duplicate(true)
	var result: Dictionary = CASINO_BANK.stage_clear_conversion(journey.coins, true)
	journey.coins = 0
	journey.stage_flags["casino_chip_banked_lap"] = journey.lap
	journey.stage_flags["last_casino_chip_result"] = result.duplicate(true)
	# Save the zeroed run wallet and one-shot marker immediately. This prevents
	# an app restart on the recovery screen from converting the same lap twice.
	save_manager.save(stage_id, journey.snapshot())
	return result


# ---- trip dice (casino prizes) ---------------------------------------------
#
# Kyoto only. The equipped trip die is used for at most three rolls per lap,
# chosen before the roll with the toggle beside the map die. While armed the
# spinning die cycles the trip die's own faces on the normal timing clock, so
# the tap still picks the face; roll(face) and everything after it is the
# same code path as a normal roll.

const TRIP_DICE := preload("res://scripts/game/trip_dice.gd")
const TRIP_TOGGLE_SIZE := Vector2(232, 96)
const TRIP_IVORY := Color("#fff6e4")

var trip_die_toggle: Button
var _trip_die_cache_id := ""
var _trip_die_cache: Dictionary = {}


## The equipped, owned trip die, or {} when the player travels without one.
func equipped_trip_die() -> Dictionary:
	if stage_id != StageCatalog.STAGE_KYOTO:
		return {}
	var die_id := CASINO_BANK.equipped_trip_die()
	if die_id != _trip_die_cache_id:
		_trip_die_cache_id = die_id
		_trip_die_cache = TRIP_DICE.find(die_id) if not die_id.is_empty() else {}
	return _trip_die_cache


func trip_die_uses_left() -> int:
	if journey == null:
		return 0
	return TRIP_DICE.uses_left(journey.stage_flags, journey.lap)


## True when the next roll will use the trip die's faces.
func trip_die_in_use() -> bool:
	if journey == null or equipped_trip_die().is_empty():
		return false
	# A skill-fixed face always wins; the trip die then sits this roll out.
	if journey.peek_skill_face() > 0:
		return false
	return TRIP_DICE.is_armed(journey.stage_flags, journey.lap)


func set_trip_die_armed(armed: bool) -> void:
	if journey == null or map_roll_active or map_movement_active or roll_animation_active:
		return
	if armed and (equipped_trip_die().is_empty() or trip_die_uses_left() <= 0):
		armed = false
	TRIP_DICE.set_armed(journey.stage_flags, armed)
	_apply_trip_die_tint()
	_refresh_trip_die_toggle()


func _map_roll_face_for_elapsed(elapsed: float) -> int:
	if trip_die_in_use():
		return TRIP_DICE.face_for_elapsed(TRIP_DICE.normalize_faces(equipped_trip_die().get("faces", [])), elapsed)
	return super._map_roll_face_for_elapsed(elapsed)


func _present_rolling_map_die() -> void:
	if not trip_die_in_use():
		super._present_rolling_map_die()
		return
	# Show the face that would be taken right now. The normal tumble shows the
	# standard 1-6 pips, which would not match a trip die.
	if is_instance_valid(map_dice):
		map_dice.present([map_roll_face], false, 1)


func _stop_map_roll() -> void:
	if map_roll_active and trip_die_in_use():
		TRIP_DICE.consume_use(journey.stage_flags, journey.lap)
		journey.stage_flags["trip_die_last_roll"] = journey.roll_count + 1
	await super._stop_map_roll()
	_apply_trip_die_tint()
	_refresh_trip_die_toggle()


func _process(delta: float) -> void:
	super._process(delta)
	if stage_id != StageCatalog.STAGE_KYOTO:
		return
	if not is_instance_valid(trip_die_toggle):
		_build_trip_die_toggle()
	_refresh_trip_die_toggle()


func _build_trip_die_toggle() -> void:
	if not is_instance_valid(map_dice) or map_dice.get_parent() == null:
		return
	trip_die_toggle = Button.new()
	trip_die_toggle.name = "TripDieToggle"
	trip_die_toggle.toggle_mode = true
	trip_die_toggle.focus_mode = Control.FOCUS_NONE
	trip_die_toggle.size = TRIP_TOGGLE_SIZE
	trip_die_toggle.custom_minimum_size = TRIP_TOGGLE_SIZE
	trip_die_toggle.z_index = 18
	trip_die_toggle.add_theme_font_size_override("font_size", 22)
	trip_die_toggle.add_theme_stylebox_override("normal", _panel(Color("#2f2238e6"), Color("#a58bc0"), 18, 2))
	trip_die_toggle.add_theme_stylebox_override("hover", _panel(Color("#3d2c49e6"), Color("#d0b5ea"), 18, 2))
	trip_die_toggle.add_theme_stylebox_override("pressed", _panel(Color("#f2bf4c"), Color("#fff2c2"), 18, 3))
	trip_die_toggle.add_theme_stylebox_override("hover_pressed", _panel(Color("#f6cb66"), Color("#fff2c2"), 18, 3))
	trip_die_toggle.add_theme_stylebox_override("disabled", _panel(Color("#2a2330cc"), Color("#5c5066"), 18, 1))
	trip_die_toggle.add_theme_color_override("font_color", Color("#fff4d6"))
	trip_die_toggle.add_theme_color_override("font_pressed_color", Color("#2a1a0c"))
	trip_die_toggle.add_theme_color_override("font_hover_pressed_color", Color("#2a1a0c"))
	trip_die_toggle.add_theme_color_override("font_disabled_color", Color("#9d92a6"))
	trip_die_toggle.toggled.connect(set_trip_die_armed)
	map_dice.get_parent().add_child(trip_die_toggle)
	_apply_trip_die_tint()


func _refresh_trip_die_toggle() -> void:
	if not is_instance_valid(trip_die_toggle):
		return
	var die := equipped_trip_die()
	trip_die_toggle.visible = not die.is_empty() and is_instance_valid(map_dice) and map_dice.is_visible_in_tree()
	if not trip_die_toggle.visible:
		return
	var left := trip_die_uses_left()
	var armed := TRIP_DICE.is_armed(journey.stage_flags, journey.lap)
	var busy := map_roll_active or map_movement_active or roll_animation_active or not journey.can_roll()
	var short_name := str(die.get("name", "")).trim_suffix("ダイス")
	var text := "旅ダイス：%s\nこの周あと%d回" % [short_name, left] if left > 0 else "旅ダイス：%s\nこの周は使い切った" % short_name
	if trip_die_toggle.text != text:
		trip_die_toggle.text = text
	trip_die_toggle.set_pressed_no_signal(armed)
	trip_die_toggle.disabled = left <= 0 or (busy and not map_roll_active) or journey.peek_skill_face() > 0
	trip_die_toggle.mouse_filter = Control.MOUSE_FILTER_IGNORE if busy else Control.MOUSE_FILTER_STOP
	# Beside the die, but always fully inside the map panel: on short layouts
	# the die itself runs past the panel edge.
	var host := trip_die_toggle.get_parent() as Control
	var limit_y := host.size.y - TRIP_TOGGLE_SIZE.y - 8.0 if host != null else INF
	trip_die_toggle.position = Vector2(
		maxf(8.0, map_dice.position.x - TRIP_TOGGLE_SIZE.x - 16.0),
		maxf(8.0, minf(map_dice.position.y + (map_dice.size.y - TRIP_TOGGLE_SIZE.y) * 0.5, limit_y))
	)


## Tint the map die with the trip die's colour while it is armed, so a trip
## roll is recognisable at a glance; otherwise the normal ivory.
func _apply_trip_die_tint() -> void:
	if not is_instance_valid(map_dice) or map_dice.cube_materials.is_empty():
		return
	var color := TRIP_IVORY
	if trip_die_in_use():
		color = Color(str(equipped_trip_die().get("color", "#fff6e4")))
	for material: StandardMaterial3D in map_dice.cube_materials:
		material.albedo_color = color
