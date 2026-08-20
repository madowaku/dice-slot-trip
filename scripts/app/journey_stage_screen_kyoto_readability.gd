extends "res://scripts/app/journey_stage_screen.gd"

# Thin presentation override for Kyoto readability fixes.
# Keep the shared JourneyStageScreen implementation as the gameplay authority;
# this script only changes layering and the Kyoto branch copy/layout.


func _show_overview_map(initial: bool = false) -> void:
	# Kyoto's local horizon, explorer and die use elevated z-indices so they stay
	# crisp during normal play. The full-map overlay must own the top layer while
	# it is open, otherwise those normal-play elements cover the route overview.
	super._show_overview_map(initial)
	if is_instance_valid(overview_overlay):
		overview_overlay.z_index = 200


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
