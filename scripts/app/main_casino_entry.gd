extends "res://scripts/app/main.gd"

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const CASINO_HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const CAIRO_CASINO_PLAY_SCENE: PackedScene = preload("res://scenes/casino/CairoCasinoPlayScreen.tscn")

var casino_hub_overlay: Control

func _render_stage_select() -> void:
	super._render_stage_select()
	_add_casino_entry_button()

func _add_casino_entry_button() -> void:
	if not is_instance_valid(root_stack):
		return
	if root_stack.has_node("CasinoEntryButton"):
		return
	var entry := _button(
		"LAS VEGAS CASINO　　CHIP %d" % CasinoBankScript.balance(),
		_open_casino_hub,
		true
	)
	entry.name = "CasinoEntryButton"
	entry.custom_minimum_size.y = 58
	root_stack.add_child(entry)

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
