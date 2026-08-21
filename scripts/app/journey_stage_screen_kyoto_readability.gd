extends "res://scripts/app/journey_stage_screen.gd"

# Thin presentation override for Kyoto readability fixes.
# Keep the shared JourneyStageScreen implementation as the gameplay authority;
# this script only changes layering and the Kyoto branch/local-map presentation.


func _route_tile(text_value: String, kind: String, current: bool, space_id_value: String = "") -> PanelContainer:
	var tile := super._route_tile(text_value, kind, current, space_id_value)
	if stage_id == StageCatalog.STAGE_KYOTO and current:
		# The explorer is the visual identity of the current card. A second kind
		# badge competes for the same tiny phone-space and is easily covered by the
		# cat, so keep the current tile deliberately simple: label + explorer only.
		var tile_content := tile.get_node_or_null("TileContent") as Control
		if tile_content != null:
			var kind_badge := tile_content.get_node_or_null("CurrentKindBadge") as Control
			if kind_badge != null:
				kind_badge.visible = false
	return tile


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
		var destination := str(projection.get("destination", "次のマス"))
		# Two large lines only: route name, then the exact projected landing tile.
		choice["label"] = "%s　→　%s\n%s" % [route_label, destination_kind, destination]
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
